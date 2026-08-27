#!/bin/bash
set -e

# Script: toggle-inmp441.sh
# Activa o desactiva el micrófono INMP441 en la Raspberry Pi.
#
# El INMP441 y el MAX98357A compiten por el mismo DAI I2S (bcm2835-i2s).
# Solo uno puede estar activo a la vez. Este script intercambia los overlays
# en /boot/firmware/config.txt y solicita un reinicio.
#
# Uso:
#   bash scripts/toggle-inmp441.sh --enable-capture    # Activar INMP441 (desactiva MAX98357A)
#   bash scripts/toggle-inmp441.sh --enable-playback    # Activar MAX98357A (desactiva INMP441)
#   bash scripts/toggle-inmp441.sh --status             # Mostrar estado actual

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
    if grep -q "^[^#]*dtoverlay=max98357a" "${CONFIG_FILE}" 2>/dev/null; then
        echo "  [MAX98357A] ACTIVADO (reproducción)"
    else
        echo "  [MAX98357A] Desactivado"
    fi
    if grep -q "^[^#]*dtoverlay=inmp441-bare" "${CONFIG_FILE}" 2>/dev/null; then
        echo "  [INMP441]   ACTIVADO (captura)"
    else
        echo "  [INMP441]   Desactivado"
    fi
    echo ""
    echo "Verificación de hardware:"
    aplay -l 2>&1 | grep -E 'card|^[0-9]' | head -5 || true
    arecord -l 2>&1 | grep -E 'card|^[0-9]' | head -5 || true
}

case "${1:-}" in
    --enable-capture)
        echo "=== Activando INMP441 (captura) ==="
        echo "NOTA: Esto desactiva MAX98357A (reproducción) por conflicto I2S."
        # Desactivar max98357a
        if grep -q "^dtoverlay=max98357a" "${CONFIG_FILE}" 2>/dev/null; then
            sudo sed -i 's|^dtoverlay=max98357a.*|#dtoverlay=max98357a,no-sdmode  # desactivado: conflicto I2S con inmp441-bare|' "${CONFIG_FILE}"
            echo "  MAX98357A desactivado"
        fi
        # Activar inmp441-bare
        if grep -q "^#dtoverlay=inmp441-bare" "${CONFIG_FILE}" 2>/dev/null; then
            sudo sed -i 's|^#dtoverlay=inmp441-bare.*|dtoverlay=inmp441-bare|' "${CONFIG_FILE}"
            echo "  INMP441 activado"
        elif grep -q "^dtoverlay=inmp441-bare" "${CONFIG_FILE}" 2>/dev/null; then
            echo "  INMP441 ya estaba activado"
        else
            echo "dtoverlay=inmp441-bare" | sudo tee -a "${CONFIG_FILE}" >/dev/null
            echo "  INMP441 añadido"
        fi
        echo ""
        echo "¡Reinicie para aplicar cambios: sudo reboot"
        ;;

    --enable-playback)
        echo "=== Activando MAX98357A (reproducción) ==="
        echo "NOTA: Esto desactiva INMP441 (captura) por conflicto I2S."
        # Desactivar inmp441-bare
        if grep -q "^dtoverlay=inmp441-bare" "${CONFIG_FILE}" 2>/dev/null; then
            sudo sed -i 's|^dtoverlay=inmp441-bare.*|#dtoverlay=inmp441-bare  # desactivado: conflicto I2S con max98357a|' "${CONFIG_FILE}"
            echo "  INMP441 desactivado"
        fi
        # Activar max98357a
        if grep -q "^#dtoverlay=max98357a" "${CONFIG_FILE}" 2>/dev/null; then
            sudo sed -i 's|^#dtoverlay=max98357a.*|dtoverlay=max98357a,no-sdmode|' "${CONFIG_FILE}"
            echo "  MAX98357A activado"
        elif grep -q "^dtoverlay=max98357a" "${CONFIG_FILE}" 2>/dev/null; then
            echo "  MAX98357A ya estaba activado"
        else
            echo "dtoverlay=max98357a,no-sdmode" | sudo tee -a "${CONFIG_FILE}" >/dev/null
            echo "  MAX98357A añadido"
        fi
        echo ""
        echo "¡Reinicie para aplicar cambios: sudo reboot"
        ;;

    --status)
        show_status
        ;;

    *)
        echo "Uso: bash $0 --enable-capture|--enable-playback|--status"
        echo ""
        echo "Modo captura (INMP441): desactiva MAX98357A"
        echo "Modo reproducción (MAX98357A): desactiva INMP441"
        exit 1
        ;;
esac
