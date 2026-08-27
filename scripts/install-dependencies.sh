#!/bin/bash
set -e

# Script: install-dependencies.sh
# Instala las dependencias del sistema necesarias para Xiaozhi en Raspberry Pi

echo "=== Instalando dependencias del sistema para Xiaozhi ==="

# Actualizar repositorios
sudo apt-get update

# Herramientas de audio
sudo apt-get install -y \
    pulseaudio-utils \
    portaudio19-dev \
    libportaudio2

# Soporte de audio para Python
sudo apt-get install -y \
    python3-pyaudio \
    python3-venv \
    python3-pip \
    python3-dev

# Codificación y decodificación de audio
sudo apt-get install -y \
    ffmpeg \
    libopus0 \
    libopus-dev

# Herramientas de compilación
sudo apt-get install -y \
    build-essential \
    git \
    wget \
    curl

echo "=== Dependencias instaladas correctamente ==="
