#!/bin/bash
set -e

# Script: setup-pins.sh
# Configura los pines GPIO/I2S para micrófono INMP441 y amplificador MAX98357A
# en Raspberry Pi.
#
# IMPORTANTE: El INMP441 (captura) y MAX98357A (reproducción) NO pueden estar
# activos simultáneamente. Ambos usan el mismo DAI I2S (bcm2835-i2s) y el
# driver ASoC del kernel impide que un DAI se enlaz a dos tarjetas de sonido.
#
# Este script configura MAX98357A para reproducción (por defecto).
# Para activar el INMP441, use scripts/toggle-inmp441.sh que intercambia
# los overlays y reinicia.
#
# Pinout INMP441 → Raspberry Pi (GPIO):
#   VDD  -> 3.3V  (Pin 1, 17)
#   GND  -> GND   (Pin 6, 9, 14, 20, 25, 30, 34, 39)
#   SD   -> GPIO20 (Pin 38, PCM_DIN)
#   SCK  -> GPIO18 (Pin 12, PCM_CLK)
#   WS   -> GPIO19 (Pin 35, PCM_FS)
#   L/R  -> GPIO21 (Pin 40, channel select)
#
# Pinout MAX98357A → Raspberry Pi (GPIO):
#   VDD  -> 3.3V  (Pin 1, 17)
#   GND  -> GND   (Pin 6, 9, 14)
#   DIN  -> GPIO21 (Pin 40, PCM_DOUT)
#   BCLK -> GPIO18 (Pin 12, PCM_CLK)
#   LCLK -> GPIO19 (Pin 35, PCM_FS)
#   SD   -> GND   (activa el amplificador)

echo "=== Configurando pines I2S para INMP441 y MAX98357A ==="

# Detectar el archivo config.txt (Raspberry Pi OS Bookworm usa /boot/firmware)
CONFIG_FILE=""
for cfg in /boot/firmware/config.txt /boot/config.txt; do
    if [ -f "${cfg}" ]; then
        CONFIG_FILE="${cfg}"
        break
    fi
done

if [ -z "${CONFIG_FILE:-}" ]; then
    echo "ERROR: No se encontró config.txt"
    exit 1
fi

MODULES_FILE="/etc/modules"

echo "Usando config.txt: ${CONFIG_FILE}"

# Función para remover overlays conflictivos (activos y comentados)
remove_dtoverlay() {
    local overlay="$1"
    local removed=0
    if grep -q "^dtoverlay=${overlay}" "${CONFIG_FILE}" 2>/dev/null; then
        sudo sed -i "/^dtoverlay=${overlay}/d" "${CONFIG_FILE}"
        echo "  Removido overlay activo: ${overlay}"
        removed=1
    fi
    if grep -q "^#dtoverlay=${overlay}" "${CONFIG_FILE}" 2>/dev/null; then
        sudo sed -i "/^#dtoverlay=${overlay}/d" "${CONFIG_FILE}"
        echo "  Removido overlay comentado: ${overlay}"
        removed=1
    fi
    [ ${removed} -eq 0 ] && echo "  Overlay no presente: ${overlay}"
}

# Función para activar un overlay (descomentar o añadir)
enable_dtoverlay() {
    local overlay="$1"
    if grep -q "^#dtoverlay=${overlay}" "${CONFIG_FILE}" 2>/dev/null; then
        sudo sed -i "s|^#dtoverlay=${overlay}|dtoverlay=${overlay}|" "${CONFIG_FILE}"
        echo "  Activado: dtoverlay=${overlay}"
    elif grep -q "^dtoverlay=${overlay%%,*}" "${CONFIG_FILE}" 2>/dev/null; then
        echo "  Ya activo: dtoverlay=${overlay}"
    else
        echo "dtoverlay=${overlay}" | sudo tee -a "${CONFIG_FILE}" >/dev/null
        echo "  Añadido: dtoverlay=${overlay}"
    fi
}

# Asegurar que i2s esté habilitado
if ! grep -q "^dtparam=i2s=on" "${CONFIG_FILE}" 2>/dev/null; then
    echo "dtparam=i2s=on" | sudo tee -a "${CONFIG_FILE}" >/dev/null
    echo "Añadido: dtparam=i2s=on"
else
    echo "i2s ya habilitado: dtparam=i2s=on"
fi

# Remover overlays conflictivos
remove_dtoverlay "googlevoicehat-soundcard"
remove_dtoverlay "i2s-mems-mic"
remove_dtoverlay "i2s-mmap"

# Activar MAX98357A para reproducción
enable_dtoverlay "max98357a,no-sdmode"

# El INMP441 no se activa aquí para evitar conflicto con MAX98357A.
# Ver: scripts/toggle-inmp441.sh
# Comentar temporalmente el inmp441-bare en config.txt:
if grep -q "^dtoverlay=inmp441-bare" "${CONFIG_FILE}" 2>/dev/null; then
    sudo sed -i "s|^dtoverlay=inmp441-bare.*|#dtoverlay=inmp441-bare  # desactivado: conflicto I2S con max98357a|" "${CONFIG_FILE}"
    echo "  Comentado inmp441-bare (conflicto con max98357a)"
fi

# Mostrar pinout
echo ""
echo "Pinout INMP441 -> Raspberry Pi (GPIO):"
echo "  INMP441 VDD  -> 3.3V  (Pin 1, 17)"
echo "  INMP441 GND  -> GND   (Pin 6, 9, 14)"
echo "  INMP441 SD   -> GPIO20 (Pin 38, PCM_DIN)"
echo "  INMP441 SCK  -> GPIO18 (Pin 12, PCM_CLK)"
echo "  INMP441 WS   -> GPIO19 (Pin 35, PCM_FS)"
echo "  INMP441 L/R  -> GPIO21 (Pin 40, channel select)"
echo ""
echo "Pinout MAX98357A -> Raspberry Pi (GPIO):"
echo "  MAX98357A VDD  -> 3.3V  (Pin 1, 17)"
echo "  MAX98357A GND  -> GND   (Pin 6, 9, 14)"
echo "  MAX98357A DIN  -> GPIO21 (Pin 40, PCM_DOUT)"
echo "  MAX98357A BCLK -> GPIO18 (Pin 12, PCM_CLK)"
echo "  MAX98357A LCLK -> GPIO19 (Pin 35, PCM_FS)"
echo "  MAX98357A SD   -> GND   (activa el amplificador)"
echo ""

# Cargar módulos del kernel I2S
echo "Cargando módulos I2S del kernel..."
sudo modprobe snd-bcm2835 2>/dev/null || true
sudo modprobe snd-soc-bcm2835-i2s 2>/dev/null || true
sudo modprobe snd-soc-dmic 2>/dev/null || true
sudo modprobe snd-soc-max98357a 2>/dev/null || true

# Añadir módulos al arranque
for mod in snd-bcm2835 snd-soc-bcm2835-i2s snd-soc-dmic snd-soc-max98357a; do
    if ! grep -q "^${mod}$" "${MODULES_FILE}" 2>/dev/null; then
        echo "${mod}" | sudo tee -a "${MODULES_FILE}" >/dev/null
        echo "  Añadido al arranque: ${mod}"
    fi
done

echo ""
echo "=== Configuración completada ==="
echo ""
echo "Verificación después de reiniciar:"
echo "  aplay -l   # Debe mostrar 'MAX98357A'"
echo "  arecord -l # Vacío (INMP441 no activado por el conflicto)"
echo ""
echo "Para activar el INMP441 (requiere intercambiar con MAX98357A):"
echo "  bash scripts/toggle-inmp441.sh --enable-capture"
echo ""
echo "Reinicie la Raspberry Pi para aplicar los cambios I2S:"
echo "  sudo reboot"
