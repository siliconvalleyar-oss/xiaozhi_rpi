#!/bin/bash
set -e

# Script: toggle-inmp441.sh
#
# NOTA: Con el overlay combinado (inmp441-max98357a-combined), INMP441 y
# MAX98357A funcionan SIMULTÁNEAMENTE en una sola tarjeta de sonido.
# Este script es un RECURSO DE RESPALDO para cuando el overlay combinado
# no funciona (ej: kernel que no soporta simple-audio-card,dai-link@N).
#
# En la configuración actual, el overlay combinado está activado y ambos
# dispositivos funcionan. No necesita usarse.
#
# Si necesita alternar entre overlays separados (modos mutuamente excluyentes):
#   --enable-capture    # Activar inmp441-bare (captura), desactiva max98357a
#   --enable-playback   # Activar max98357a (playback), desactiva inmp441-bare
#   --status            # Mostrar estado actual

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

show_status() {
    echo "=== Estado actual de audio I2S ==="
    echo "Config: ${CONFIG_FILE}"
    echo ""
    if grep -q "^[^#]*dtoverlay=inmp441-max98357a-combined" "${CONFIG_FILE}" 2>/dev/null; then
        echo "  [COMBINED] Overlay inmp441-max98357a-combined ACTIVADO"
        echo "    → INMP441 (captura) + MAX98357A (reproducción) simultáneos"
        echo "    → aplay -l   : card N, device 0"
        echo "    → arecord -l : card N, device 1"
    fi
    if grep -q "^[^#]*dtoverlay=max98357a" "${CONFIG_FILE}" 2>/dev/null; then
        echo "  [MAX98357A] ACTIVADO (solo reproducción)"
    fi
    if grep -q "^[^#]*dtoverlay=inmp441-bare" "${CONFIG_FILE}" 2>/dev/null; then
        echo "  [INMP441] ACTIVADO (solo captura)"
    fi
    echo ""
    echo "Hardware verificación:"
    aplay -l 2>&1 | grep -E 'card' | head -5 || true
    arecord -l 2>&1 | grep -E 'card' | head -5 || true
}

case "${1:-}" in
    --enable-capture)
        echo "=== Activando INMP441 (captura únicamente) ==="
        echo "NOTA: Desactiva MAX98357A (solo se puede usar un overlay I2S a la vez"
        echo "      a menos que use el overlay combinado)."
        if grep -q "^dtoverlay=max98357a" "${CONFIG_FILE}" 2>/dev/null; then
            sudo sed -i 's|^dtoverlay=max98357a.*|#dtoverlay=max98357a  # desactivado: exclusividad I2S|' "${CONFIG_FILE}"
            echo "  max98357a desactivado"
        fi
        sudo sed -i 's|^#dtoverlay=inmp441-bare|dtoverlay=inmp441-bare|' "${CONFIG_FILE}" 2>/dev/null || true
        if ! grep -q "^dtoverlay=inmp441-bare" "${CONFIG_FILE}" 2>/dev/null; then
            echo "dtoverlay=inmp441-bare" | sudo tee -a "${CONFIG_FILE}" >/dev/null
            echo "  inmp441-bare activado"
        fi
        echo ""
        echo "¡Reinicie: sudo reboot"
        ;;

    --enable-playback)
        echo "=== Activando MAX98357A (reproducción únicamente) ==="
        echo "NOTA: Desactiva INMP441 (solo se puede usar un overlay I2S a la vez"
        echo "      a menos que use el overlay combinado)."
        if grep -q "^dtoverlay=inmp441-bare" "${CONFIG_FILE}" 2>/dev/null; then
            sudo sed -i 's|^dtoverlay=inmp441-bare.*|#dtoverlay=inmp441-bare  # desactivado: exclusividad I2S|' "${CONFIG_FILE}"
            echo "  inmp441-bare desactivado"
        fi
        sudo sed -i 's|^#dtoverlay=max98357a,*|dtoverlay=max98357a,no-sdmode|' "${CONFIG_FILE}" 2>/dev/null || true
        if ! grep -q "^dtoverlay=max98357a" "${CONFIG_FILE}" 2>/dev/null; then
            echo "dtoverlay=max98357a,no-sdmode" | sudo tee -a "${CONFIG_FILE}" >/dev/null
            echo "  max98357a activado"
        fi
        echo ""
        echo "¡Reinicie: sudo reboot"
        ;;

    --status)
        show_status
        ;;

    *)
        echo "Uso: bash $0 --enable-capture|--enable-playback|--status"
        echo ""
        echo "Modo combinado (recomendado):"
        echo "  El overlay inmp441-max98357a-combined ya está activado."
        echo "  INMP441 y MAX98357A funcionan simultáneamente."
        echo ""
        echo "Modo individual (alternar):"
        echo "  --enable-capture  : inmp441-bare (captura) — desactiva max98357a"
        echo "  --enable-playback : max98357a (reproducción) — desactiva inmp441-bare"
        echo "  --status          : mostra estado actual"
        exit 1
        ;;
esac
