# Guía de Instalación de Xiaozhi en Raspberry Pi

Esta guía explica cómo instalar el asistente de voz **Xiaozhi** en una Raspberry Pi, configurando INMP441 para captura y MAX98357A para reproducción.

## Requisitos Previos

- Raspberry Pi 3B+, 4B o Zero 2W
- Sistema operativo: Raspberry Pi OS (64-bit recomendado) — Bookworm o posterior
- Micrófono digital INMP441 conectado vía I2S (ver [INMP441 wiring](inmp441-wiring.md))
- Amplificador MAX98357A conectado vía I2S (para salida de audio)
- Cámara USB o CSI (opcional)
- Acceso SSH sin contraseña configurado (`ssh joy@raspberry.local`)
- Acceso a internet

## I2S Combinado: INMP441 + MAX98357A

INMP441 (captura) y MAX98357A (reproducción) comparten el mismo DAI I2S (`bcm2835-i2s`). El overlay combinado `inmp441-max98357a-combined` crea una **solita tarjeta de sonido** con captura y reproducción simultáneas:

- **Device 0**: reproducción (MAX98357A)
- **Device 1**: captura (INMP441)

No es necesario alternar overlays. Ver [INMP441 wiring](inmp441-wiring.md) para detalles de hardware y conflictos.

## Paso 1: Clonar el repositorio

```bash
cd /home/joy/src
git clone https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git
cd xiaozhi_rpi
```

## Paso 2: Instalar dependencias del sistema

```bash
sudo ./scripts/install-dependencies.sh
```

Instala:
- `portaudio19-dev`, `python3-pyaudio` — captura/reproducción de audio
- `ffmpeg`, `libopus0`, `libopus-dev` — codificación de audio
- `build-essential`, `python3-venv`, `python3-pip` — compilación y Python
- `pulseaudio-utils` — gestión de audio

## Paso 3: Instalar Miniconda (opcional)

```bash
sudo ./scripts/install-miniconda.sh
source ~/.bashrc
```

## Paso 4: Configurar pines I2S

```bash
sudo ./scripts/setup-pins.sh
```

Este script:
- Habilita I2S en `/boot/firmware/config.txt` (Raspberry Pi OS Bookworm)
- Instala y activa el overlay combinado `inmp441-max98357a-combined`
- Añade módulos del kernel: `snd-soc-dmic`, `snd-soc-max98357a`
- Muestra el pinout de ambos dispositivos

> **Reinicie** (`sudo reboot`) después de este script.

## Paso 5: Configurar py-xiaozhi

```bash
cd /home/joy/src
git clone https://github.com/virtao/py-xiaozhi.git
cd py-xiaozhi
pip install -r requirements.txt

cp /home/joy/src/xiaozhi_rpi/config/config.json /home/joy/src/py-xiaozhi/config/
cp /home/joy/src/xiaozhi_rpi/config/efuse.json /home/joy/src/py-xiaozhi/config/
```

## Paso 6: Descargar modelo de activación

```bash
cd /home/joy/src/xiaozhi_rpi
./scripts/download-wake-word-model.sh
```

## Paso 7: Iniciar Xiaozhi

```bash
cd /home/joy/src/py-xiaozhi
python3 main.py --mode cli
```

## Verificación

```bash
# Verificar tarjetas de sonido
aplay -l     # Buscar "INMP441-MAX98357A" (card N, device 0)
arecord -l   # Buscar "INMP441-MAX98357A" (card N, device 1)

# Probar reproducción (MAX98357A)
speaker-test -D hw:N,0 -c 2 -t sine -f 440 -l 1

# Probar captura (INMP441 — device 1)
arecord -D hw:N,1 -f S32_LE -r 48000 -c 2 -d 5 test.wav
```

## Despliegue Remoto (Deploy)

```bash
LINK_PROJECT_GIT=https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git \
./scripts/deploy-rpi.sh
```

## Solución de Problemas

| Problema | Causa posible | Solución |
|----------|---------------|----------|
| Sin "INMP441-MAX98357A" en `aplay -l` | Overlay no cargado | `bash scripts/toggle-inmp441.sh --enable-playback`; reinicie |
| Sin "INMP441-MAX98357A" en `arecord -l` | Overlay no cargado | `bash scripts/toggle-inmp441.sh --enable-capture`; reinicie |
| Grabación silenciosa | Micrófono no conectado | Verificar wiring en [inmp441-wiring.md](inmp441-wiring.md) |
| `config.txt` no funciona | Path incorrecto | Usar `/boot/firmware/config.txt` (Bookworm) |
| Sin audio de salida | Device incorrecto | Usar `-D hw:N,0` (playback = device 0) |
| `set_params: invalid argument` | Formato incorrecto | Usar `-f S32_LE -c 2` para captura, `-c 2` para playback |
