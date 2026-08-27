#!/bin/bash
set -e

# Script: setup-pins.sh
# Configura los pines GPIO/I2S para el micrófono INMP441 en Raspberry Pi

echo "=== Configurando pines para micrófono INMP441 ==="

# Habilitar interfaz I2S en /boot/config.txt
CONFIG_FILE="/boot/config.txt"

# Función para verificar y añadir línea
add_config() {
    local key="$1"
    local value="$2"
    if ! grep -q "^${key}=" "${CONFIG_FILE}" 2>/dev/null; then
        echo "${key}=${value}" | sudo tee -a "${CONFIG_FILE}"
    else
        echo "Ya configurado: ${key}=${value}"
    fi
}

# Configuración I2S para INMP441
add_config "dtoverlay" "i2s-mmap"
add_config "dtoverlay" "snd-soc-dapm"
add_config "dtoverlay" "snd-soc-dai"

# Habilitar audio I2S (bit 1 del puerto 2)
# dtoverlay=i2s-mmap habilita el acceso I2S con memoria asignada

# Pinout INMP441 (conexión típica)
# INMP441 usa 4 pines: VDD, GND, SD, SCK (o WS/CLK)
# Para Raspberry Pi 4B:
#
#   INMP441   ->   Raspberry Pi
#   ----------------------------
#   VDD (3.3V) ->  Pin 1  (3.3V)
#   GND        ->  Pin 6  (GND)
#   SD (Datos) ->  Pin 40 (GPIO 18 / I2S_DIN)
#   SCK/CLK    ->  Pin 35 (GPIO 19 / I2S_BCLK)
#                  Pin 31 (GPIO 6 / I2S_WS / LRCK)
#                  Pin 35 (GPIO 19 / I2S_BCLK)
#                  Pin 40 (GPIO 18 / I2S_DIN)

echo ""
echo "Pinout INMP441 -> Raspberry Pi (GPIO):"
echo "  INMP441 VDD  -> 3.3V (Pin 1)"
echo "  INMP441 GND  -> GND  (Pin 6)"
echo "  INMP441 SD   -> GPIO18 (Pin 40, I2S_DIN)"
echo "  INMP441 SCK  -> GPIO19 (Pin 35, I2S_BCLK)"
echo "  INMP441 WS   -> GPIO6  (Pin 31, I2S_LRCK)"
echo "  INMP441 L/R  -> GND    (Pin...)"
echo ""

# Cargar módulos del kernel I2S
echo "Cargando módulos I2S del kernel..."
sudo modprobe snd-bcm2835
sudo modprobe snd-soc-bcm2835-i2s
sudo modprobe snd-soc-wm8960

# Añadir módulos al arranque
MODULES_FILE="/etc/modules"
for mod in snd-bcm2835 snd-soc-bcm2835-i2s snd-soc-wm8960; do
    if ! grep -q "^${mod}$" "${MODULES_FILE}" 2>/dev/null; then
        echo "${mod}" | sudo tee -a "${MODULES_FILE}"
    fi
done

echo "=== Configuración de pines completada ==="
echo "Reinicie la Raspberry Pi para aplicar los cambios I2S"
