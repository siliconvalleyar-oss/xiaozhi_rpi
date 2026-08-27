#!/bin/bash
set -e

# Script: setup-pins.sh
# Configura los pines GPIO/I2S para el micrófono INMP441 en Raspberry Pi
# Usa el device tree overlay "inmp441-bare" (driver dmic-codec)

echo "=== Configurando pines para micrófono INMP441 ==="

CONFIG_FILE="/boot/config.txt"
MODULES_FILE="/etc/modules"

# Función para verificar y añadir overlay a config.txt
add_dtoverlay() {
    local overlay="$1"
    if grep -q "^dtoverlay=${overlay}" "${CONFIG_FILE}" 2>/dev/null; then
        echo "Ya configurado: dtoverlay=${overlay}"
    else
        echo "dtoverlay=${overlay}" | sudo tee -a "${CONFIG_FILE}" >/dev/null
        echo "Añadido: dtoverlay=${overlay}"
    fi
}

# Remover overlays conflictivos
remove_dtoverlay() {
    local overlay="$1"
    if grep -q "^dtoverlay=${overlay}" "${CONFIG_FILE}" 2>/dev/null; then
        sudo sed -i "/^dtoverlay=${overlay}/d" "${CONFIG_FILE}"
        echo "Removido overlay conflictivo: ${overlay}"
    fi
}

# Remover overlays que pueden conflictuar con INMP441
remove_dtoverlay "googlevoicehat-soundcard"
remove_dtoverlay "i2s-mems-mic"
remove_dtoverlay "i2s-mmap"

# Añadir overlay correcto para INMP441
add_dtoverlay "inmp441-bare,alsaname=mems-mic"

# Habilitar I2S (requerido por el overlay)
add_dtoverlay "i2s-mmap"

# Pinout INMP441 (basado en inmp441_rpi/hardware_setup.md)
#
#   INMP441   ->   Raspberry Pi
#   ----------------------------
#   VDD       ->  3.3V          (Pin 1 o 17)
#   GND       ->  GND           (Pin 6, 9, 14, 20, 25, 30, 34, 39)
#   SD        ->  GPIO20        (Pin 38, PCM_DIN)
#   SCK/BCLK  ->  GPIO18        (Pin 12, PCM_CLK)
#   WS/LRCK   ->  GPIO19        (Pin 35, PCM_FS)
#   L/R       ->  GPIO21        (Pin 40, selección de canal)

echo ""
echo "Pinout INMP441 -> Raspberry Pi (GPIO):"
echo "  INMP441 VDD  -> 3.3V  (Pin 1, 17)"
echo "  INMP441 GND  -> GND   (Pin 6, 9, 14)"
echo "  INMP441 SD   -> GPIO20 (Pin 38, PCM_DIN)"
echo "  INMP441 SCK  -> GPIO18 (Pin 12, PCM_CLK)"
echo "  INMP441 WS   -> GPIO19 (Pin 35, PCM_FS)"
echo "  INMP441 L/R  -> GPIO21 (Pin 40, channel select)"
echo ""

# Cargar módulos del kernel I2S
echo "Cargando módulos I2S del kernel..."
sudo modprobe snd-bcm2835
sudo modprobe snd-soc-bcm2835-i2s
sudo modprobe snd-soc-dmic

# Añadir módulos al arranque
for mod in snd-bcm2835 snd-soc-bcm2835-i2s snd-soc-dmic; do
    if ! grep -q "^${mod}$" "${MODULES_FILE}" 2>/dev/null; then
        echo "${mod}" | sudo tee -a "${MODULES_FILE}" >/dev/null
        echo "Añadido al arranque: ${mod}"
    fi
done

echo ""
echo "=== Configuración de pines completada ==="
echo ""
echo "Verificación después de reiniciar:"
echo "  arecord -l   # Debe mostrar 'inmp441-bare' o 'mems-mic'"
echo ""
echo "Reinicie la Raspberry Pi para aplicar los cambios I2S:"
echo "  sudo reboot"
