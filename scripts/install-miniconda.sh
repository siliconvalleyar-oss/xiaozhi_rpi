#!/bin/bash
set -e

# Script: install-miniconda.sh
# Descarga e instala Miniconda para Python 3 en Raspberry Pi (aarch64)

echo "=== Instalando Miniconda3 para Raspberry Pi ==="

CONDA_INSTALL_DIR="${HOME}/miniconda3"

# Verificar arquitectura
ARCH=$(uname -m)
echo "Arquitectura detectada: ${ARCH}"

if [ "${ARCH}" = "aarch64" ]; then
    CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
elif [ "${ARCH}" = "armv7l" ]; then
    CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
else
    CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
fi

echo "URL de descarga: ${CONDA_URL}"

# Descargar Miniconda
echo "Descargando Miniconda..."
wget -O /tmp/Miniconda3-latest.sh "${CONDA_URL}"

# Dar permisos de ejecución
chmod +x /tmp/Miniconda3-latest.sh

# Instalar (asumiendo ruta predeterminada ${HOME}/miniconda3)
echo "Ejecutando instalador..."
bash /tmp/Miniconda3-latest.sh -b -p "${CONDA_INSTALL_DIR}"

# Configurar PATH en ~/.bashrc
if ! grep -q "miniconda3/bin" "${HOME}/.bashrc"; then
    echo "" >> ~/.bashrc
    echo "# Miniconda3" >> ~/.bashrc
    echo "export PATH=\"${CONDA_INSTALL_DIR}/bin:\$PATH\"" >> ~/.bashrc
fi

# Activar en la sesión actual
export PATH="${CONDA_INSTALL_DIR}/bin:$PATH"

# Inicializar conda
conda init bash

echo "=== Miniconda instalado en ${CONDA_INSTALL_DIR} ==="
echo "Ejecute 'source ~/.bashrc' o abra una nueva terminal para activar"
