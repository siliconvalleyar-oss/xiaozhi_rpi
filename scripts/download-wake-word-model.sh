#!/bin/bash
set -e

# Script: download-wake-word-model.sh
# Descarga el modelo de palabra de activación (Vosk) para py-xiaozhi

echo "=== Descargando modelo de palabra de activación ==="

MODEL_DIR="/home/joy/src/py-xiaozhi/models"
MODEL_ZIP="vosk-model-small-cn-0.22.zip"
MODEL_URL="https://alphacephei.com/vosk/models/vosk-model-small-cn-0.22.zip"

# Crear directorio de modelos si no existe
mkdir -p "${MODEL_DIR}"

# Descargar si no existe
if [ -f "${MODEL_DIR}/${MODEL_ZIP}" ]; then
    echo "El modelo ya está descargado en ${MODEL_DIR}/${MODEL_ZIP}"
else
    echo "Descargando ${MODEL_URL}..."
    wget -O "${MODEL_DIR}/${MODEL_ZIP}" "${MODEL_URL}"
fi

# Descomprimir
echo "Descomprimiendo modelo..."
cd "${MODEL_DIR}"
if [ ! -d "vosk-model-small-cn-0.22" ]; then
    unzip -o "${MODEL_ZIP}"
else
    echo "El modelo ya está descomprimido."
fi

# Nota: py-xiaozhi v2.1.1 usa sherpa-onnx (models/zh/ con encoder.onnx, decoder.onnx)
# Este modelo Vosk es para compatibilidad con config.json de PROMPT.md.
# Si usa sherpa-onnx, este script no es necesario.

echo "=== Modelo descargado en ${MODEL_DIR}/vosk-model-small-cn-0.22 ==="
