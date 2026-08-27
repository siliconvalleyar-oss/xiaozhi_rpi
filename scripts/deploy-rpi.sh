#!/bin/bash
set -e

# Script: deploy-rpi.sh
# Despliega Xiaozhi en la Raspberry Pi de forma remota vía SSH

# Configuración
RPI_HOST="${RPI_HOST:-joy@raspberry.local}"
RPI_SRC_DIR="${RPI_SRC_DIR:-/home/joy/src}"
PROJECT_GIT_URL="${LINK_PROJECT_GIT:-}"

echo "=== Desplegando Xiaozhi en Raspberry Pi ==="

# Verificar que se proporcionó la URL del repositorio git
if [ -z "${PROJECT_GIT_URL}" ]; then
    echo "Error: Debe definir LINK_PROJECT_GIT (URL del repositorio git)"
    echo "Uso: LINK_PROJECT_GIT=https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git ./deploy-rpi.sh"
    exit 1
fi

echo "Host destino: ${RPI_HOST}"
echo "Directorio origen en RPi: ${RPI_SRC_DIR}"
echo "URL del repositorio: ${PROJECT_GIT_URL}"

# Comando remoto: clonar/actualizar y ejecutar
ssh "${RPI_HOST}" "cd ${RPI_SRC_DIR} && \
    if [ -d xiaozhi_rpi ]; then \
        cd xiaozhi_rpi && git pull; \
    else \
        git clone ${PROJECT_GIT_URL} && cd xiaozhi_rpi; \
    fi && \
    python3 main.py"

echo "=== Despliegue completado ==="
