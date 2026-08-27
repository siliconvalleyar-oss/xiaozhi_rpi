#!/bin/bash
set -e

# Script: deploy-rpi.sh
# Despliega Xiaozhi en la Raspberry Pi de forma remota vía SSH
#
# Workflow:
#   1. Clona o actualiza el repo xiaozhi_rpi en /home/joy/src
#   2. Instala dependencias del sistema (si es necesario)
#   3. Configura pines I2S para INMP441
#   4. Copia config/ al proyecto py-xiaozhi
#   5. Descarga el modelo de voz (Vosk)
#   6. Reinicia y ejecuta py-xiaozhi

# Configuración
RPI_HOST="${RPI_HOST:-joy@raspberry.local}"
RPI_SRC_DIR="${RPI_SRC_DIR:-/home/joy/src}"
PROJECT_GIT_URL="${LINK_PROJECT_GIT:-https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git}"
PY_XIAOZHI_DIR="${PY_XIAOZHI_DIR:-/home/joy/src/py-xiaozhi}"

echo "=== Desplegando Xiaozhi en Raspberry Pi ==="
echo "Host:        ${RPI_HOST}"
echo "Src dir:     ${RPI_SRC_DIR}"
echo "Repo:        ${PROJECT_GIT_URL}"
echo "py-xiaozhi:  ${PY_XIAOZHI_DIR}"
echo ""

# Verificar conectividad SSH
if ! ssh -q -o ConnectTimeout=5 "${RPI_HOST}" "true" 2>/dev/null; then
    echo "Error: No se puede conectar a ${RPI_HOST} vía SSH"
    echo "Verifique que SSH sin contraseña está configurado."
    exit 1
fi

# Comando remoto: clonar/actualizar xiaozhi_rpi y configurar
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
    echo '>> Configurando pines INMP441...' && \
    sudo -E bash ./scripts/setup-pins.sh && \
    echo '>> Descargando modelo de voz...' && \
    bash ./scripts/download-wake-word-model.sh && \
    echo '>> Copiando configuración a py-xiaozhi...' && \
    if [ -d '${PY_XIAOZHI_DIR}' ]; then \
        mkdir -p ${PY_XIAOZHI_DIR}/config && \
        cp -v ./config/config.json ${PY_XIAOZHI_DIR}/config/ && \
        cp -v ./config/efuse.json ${PY_XIAOZHI_DIR}/config/ && \
    else \
        echo 'WARNING: py-xiaozhi no encontrado en ${PY_XIAOZHI_DIR}' && \
        echo 'Configure py-xiaozhi manualmente antes de ejecutar.' && \
        echo '>> Clonando py-xiaozhi...' && \
        cd .. && git clone https://github.com/virtao/py-xiaozhi.git && cd xiaozhi_rpi && \
        cp -v ./config/config.json ${PY_XIAOZHI_DIR}/config/ && \
        cp -v ./config/efuse.json ${PY_XIAOZHI_DIR}/config/; \
    fi && \
    echo '>> Iniciando Xiaozhi...' && \
    cd ${PY_XIAOZHI_DIR} && \
    python3 main.py --mode cli"

echo ""
echo "=== Despliegue completado ==="
