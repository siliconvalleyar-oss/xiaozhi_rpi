#!/bin/bash
set -e

# Script: deploy-rpi.sh
# Despliega Xiaozhi en la Raspberry Pi de forma remota vía SSH
#
# Workflow:
#   1. Clona o actualiza el repo xiaozhi_rpi en /home/joy/src
#   2. Instala dependencias del sistema (si es necesario)
#   3. Configura pines I2S para MAX98357A (reproducción)
#   4. Instala el overlay INMP441 si se desea captura
#   5. Copia config/ al proyecto py-xiaozhi
#   6. Descarga el modelo de voz (Vosk)
#   7. Reinicia si es necesario
#
# Configuración:
#   RPI_HOST     - Host SSH (default: joy@raspberry.local)
#   RPI_SRC_DIR  - Directorio de código fuente
#   PY_XIAOZHI   - Si "true", también instala py-xiaozhi

RPI_HOST="${RPI_HOST:-joy@raspberry.local}"
RPI_SRC_DIR="${RPI_SRC_DIR:-/home/joy/src}"
PROJECT_GIT_URL="${LINK_PROJECT_GIT:-https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git}"
PY_XIAOZHI_DIR="${PY_XIAOZHI_DIR:-/home/joy/src/py-xiaozhi}"
CAPTURE_MODE="${CAPTURE_MODE:-false}"  # true = usar INMP441 en vez de MAX98357A

echo "=== Desplegando Xiaozhi en Raspberry Pi ==="
echo "Host:        ${RPI_HOST}"
echo "Src dir:     ${RPI_SRC_DIR}"
echo "Repo:        ${PROJECT_GIT_URL}"
echo "py-xiaozhi:  ${PY_XIAOZHI_DIR}"
echo "Capture:     ${CAPTURE_MODE}"
echo ""

if ! ssh -q -o ConnectTimeout=5 "${RPI_HOST}" "true" 2>/dev/null; then
    echo "Error: No se puede conectar a ${RPI_HOST} vía SSH"
    echo "Verifique que SSH sin contraseña está configurado."
    exit 1
fi

ssh "${RPI_HOST}" "cd ${RPI_SRC_DIR} && \
    if [ -d xiaozhi_rpi ]; then \
        echo '>> Actualizando xiaozhi_rpi...' && \
        cd xiaozhi_rpi && git pull; \
    else \
        echo '>> Clonando xiaozhi_rpi...' && \
        git clone ${PROJECT_GIT_URL} && cd xiaozhi_rpi; \
    fi && \
    echo '>> Instalando dependencias del sistema...' && \
    sudo -E bash ./scripts/install-dependencies.sh && \
    echo '>> Configurando pines I2S...' && \
    sudo -E bash ./scripts/setup-pins.sh && \
    if [ '${CAPTURE_MODE}' = 'true' ]; then \
        echo '>> Activando modo captura (INMP441)...' && \
        sudo -E bash ./scripts/toggle-inmp441.sh --enable-capture; \
    else \
        echo '>> Activando modo reproducción (MAX98357A)...' && \
        sudo -E bash ./scripts/toggle-inmp441.sh --enable-playback; \
    fi && \
    echo '>> Descargando modelo de voz...' && \
    bash ./scripts/download-wake-word-model.sh && \
    echo '>> Copiando configuración a py-xiaozhi...' && \
    if [ -d '${PY_XIAOZHI_DIR}' ]; then \
        mkdir -p ${PY_XIAOZHI_DIR}/config && \
        cp -v ./config/config.json ${PY_XIAOZHI_DIR}/config/ && \
        cp -v ./config/efuse.json ${PY_XIAOZHI_DIR}/config/; \
    else \
        echo '>> Clonando py-xiaozhi...' && \
        cd .. && git clone https://github.com/virtao/py-xiaozhi.git && cd xiaozhi_rpi && \
        mkdir -p ${PY_XIAOZHI_DIR}/config && \
        cp -v ./config/config.json ${PY_XIAOZHI_DIR}/config/ && \
        cp -v ./config/efuse.json ${PY_XIAOZHI_DIR}/config/; \
    fi && \
    echo '>> Verificación de hardware...' && \
    echo '--- aplay -l ---' && aplay -l && \
    echo '--- arecord -l ---' && arecord -l"

echo ""
echo "=== Para iniciar Xiaozhi después del despliegue ==="
echo "  ssh ${RPI_HOST}"
echo "  cd ${PY_XIAOZHI_DIR}"
if [ "${CAPTURE_MODE}" = "true" ]; then
    echo "  python3 main.py --mode cli   # Con captura INMP441"
else
    echo "  python3 main.py --mode cli   # Con reproducción MAX98357A"
fi
echo ""
echo "=== Despliegue completado ==="
