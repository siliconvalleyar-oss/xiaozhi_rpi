#!/bin/bash
set -e

# Script: setup-pins.sh
# Configura los pines GPIO/I2S para micrófono INMP441 y amplificador MAX98357A
# en Raspberry Pi usando un overlay combinado.
#
# INMP441 (captura) y MAX98357A (reproducción) comparten el mismo DAI I2S
# (bcm2835-i2s). El overlay "inmp441-max98357a-combined" crea una sola
# simple-audio-card con dos enlaces DAI (dai-link@0 captura, dai-link@1
# reproducción), permitiendo que ambos funcionen simultáneamente.
#
# Pinout I2S (compartido por INMP441 y MAX98357A):
#   BCLK → GPIO18 (Pin 12) — reloj compartido
#   LRCK → GPIO19 (Pin 35) — word select compartido
#   DIN  → GPIO20 (Pin 38) — datos del INMP441 (captura)
#   DOUT → GPIO21 (Pin 40) — datos al MAX98357A (reproducción)
#   L/R  → GPIO21 (Pin 40) — selección de canal INMP441
#                        (LOW=izq, HIGH=der; también usado como DOUT en playback)

echo "=== Configurando pines I2S para INMP441 + MAX98357A ==="

# Detectar el archivo config.txt (Raspberry Pi OS Bookworm usa /boot/firmware/config.txt)
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

# Función para remover overlays conflictivos
remove_dtoverlay() {
    local overlay="$1"
    local removed=0
    if grep -q "^dtoverlay=${overlay}" "${CONFIG_FILE}" 2>/dev/null; then
        sudo sed -i "/^dtoverlay=${overlay}/d" "${CONFIG_FILE}"
        echo "  Removido overlay: ${overlay}"
        removed=1
    fi
    if grep -q "^#dtoverlay=${overlay}" "${CONFIG_FILE}" 2>/dev/null; then
        sudo sed -i "/^#dtoverlay=${overlay}/d" "${CONFIG_FILE}"
        echo "  Removido overlay comentado: ${overlay}"
        removed=1
    fi
    [ ${removed} -eq 0 ] && echo "  Overlay no presente: ${overlay}"
}

# Función para instalar y habilitar un overlay
install_and_enable_overlay() {
    local overlay_name="$1"
    local dtso_file="${BASH_SOURCE[0]%/*}/../overlays/${overlay_name}.dts"
    local dtbo_file="/boot/firmware/overlays/${overlay_name}.dtbo"

    echo "  Instalando overlay ${overlay_name}..."
    if [ -f "${dtso_file}" ]; then
        if command -v dtc &>/dev/null; then
            dtc -@ -I dts -O dtb -o "${dtbo_file}" "${dtso_file}" 2>&1
            echo "    Compilado desde ${dtso_file}"
        else
            echo "    WARNING: dtc no encontrado. El .dtbo debe existir en ${dtbo_file}"
        fi
    fi

    if [ -f "${dtbo_file}" ]; then
        echo "  Habilitando en config.txt: dtoverlay=${overlay_name}"
        if grep -q "^dtoverlay=${overlay_name}" "${CONFIG_FILE}" 2>/dev/null; then
            echo "  Ya activo"
        elif grep -q "^#dtoverlay=${overlay_name}" "${CONFIG_FILE}" 2>/dev/null; then
            sudo sed -i "s|^#dtoverlay=${overlay_name}|dtoverlay=${overlay_name}|" "${CONFIG_FILE}"
            echo "  Activado (descomentado)"
        else
            echo "dtoverlay=${overlay_name}" | sudo tee -a "${CONFIG_FILE}" >/dev/null
            echo "  Añadido"
        fi
    else
        echo "  ERROR: No se encontró ni pudo compilar ${dtbo_file}"
        return 1
    fi
}

# Remover overlays conflictivos
remove_dtoverlay "googlevoicehat-soundcard"
remove_dtoverlay "i2s-mems-mic"
remove_dtoverlay "i2s-mmap"

# Instalar y habilitar el overlay combinado (INMP441 + MAX98357A)
install_and_enable_overlay "inmp441-max98357a-combined"

# Remover overlays separados que causan conflicto
remove_dtoverlay "max98357a"
remove_dtoverlay "inmp441-bare"

# Asegurar que i2s esté habilitado
if ! grep -q "^dtparam=i2s=on" "${CONFIG_FILE}" 2>/dev/null; then
    echo "dtparam=i2s=on" | sudo tee -a "${CONFIG_FILE}" >/dev/null
    echo "Añadido: dtparam=i2s=on"
else
    echo "i2s ya habilitado: dtparam=i2s=on"
fi

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

# Mostrar pinout
echo ""
echo "Pinout I2S (compartido por INMP441 y MAX98357A):"
echo "  BCLK  → GPIO18 (Pin 12, PCM_CLK) — clock compartido"
echo "  LRCK  → GPIO19 (Pin 35, PCM_FS) — word select compartido"
echo "  DIN   → GPIO20 (Pin 38, PCM_DIN) — datos captura INMP441"
echo "  DOUT  → GPIO21 (Pin 40, PCM_DOUT) — datos salida MAX98357A"
echo "  L/R   → GPIO21 (Pin 40) — selección canal INMP441 (LOW=izq)"
echo ""
echo "  INMP441: VDD→3.3V(P1,17)  GND→GND(P6,9,14)  SD→GPIO20(P38)  SCK→GPIO18(P12)  WS→GPIO19(P35)  L/R→GPIO21(P40)"
echo "  MAX98357A: VDD→3.3V(P1,17)  GND→GND(P6,9,14)  DIN→GPIO21(P40)  BCLK→GPIO18(P12)  LCLK→GPIO19(P35)  SD→GND"
echo ""

echo "=== Configuración completada ==="
echo ""
echo "Verificación después de reiniciar:"
echo "  aplay -l   # Debe mostrar 'INMP441-MAX98357A' (card N, device 0)"
echo "  arecord -l # Debe mostrar 'INMP441-MAX98357A' (card N, device 1)"
echo ""
echo "Reinicie la Raspberry Pi para aplicar los cambios I2S:"
echo "  sudo reboot"
