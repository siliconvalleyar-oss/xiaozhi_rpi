# Guía de Instalación de Xiaozhi en Raspberry Pi

Esta guía explica cómo instalar el asistente de voz **Xiaozhi** en una Raspberry Pi, configurando INMP441 para captura y MAX98357A para reproducción.

## Requisitos Previos

- Raspberry Pi 3B+, 4B o Zero 2W
- Sistema operativo: Raspberry Pi OS (64-bit recomendado) — Bookworm o posterior
- Micrófono digital INMP441 conectado vía I2S (opcional, ver [INMP441 wiring](inmp441-wiring.md))
- Amplificador MAX98357A conectado vía I2S (para salida de audio)
- Cámara USB o CSI (opcional)
- Acceso SSH sin contraseña configurado (`ssh joy@raspberry.local`)
- Acceso a internet

## Importante: Conflicto I2S entre INMP441 y MAX98357A

INMP441 (captura) y MAX98357A (reproducción) **no pueden estar activos simultáneamente** — ambos usan el mismo DAI I2S (`bcm2835-i2s`) y el driver ASoC del kernel impide compartirlo entre dos tarjetas de sonido.

**Por defecto** se activa MAX98357A para reproducción. Use `scripts/toggle-inmp441.sh` para alternar:

```bash
# Activar captura (INMP441) — desactiva MAX98357A
bash scripts/toggle-inmp441.sh --enable-capture
sudo reboot

# Volver a reproducción (MAX98357A)
bash scripts/toggle-inmp441.sh --enable-playback
sudo reboot
```

Ver la [guía completa de INMP441](inmp441-wiring.md) para detalles de hardware y conflictos.

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
```

Miniconda se instala en `~/miniconda3`. Tras la instalación:

```bash
source ~/.bashrc
```

## Paso 4: Configurar pines I2S

```bash
sudo ./scripts/setup-pins.sh
```

Este script:
- Habilita I2S en `/boot/firmware/config.txt` (Raspberry Pi OS Bookworm)
- Carga el overlay `max98357a,no-sdmode` para reproducción
- Comenta el overlay `inmp441-bare` (conflicto con MAX98357A)
- Añade módulos del kernel al arranque
- Muestra el pinout de ambos dispositivos

> **Reinicie** (`sudo reboot`) después de este script.

## Paso 5: Configurar py-xiaozhi

```bash
# Clonar e instalar py-xiaozhi (gestión separada)
cd /home/joy/src
git clone https://github.com/virtao/py-xiaozhi.git
cd py-xiaozhi
pip install -r requirements.txt  # o usar Miniconda

# Copiar configuración desde xiaozhi_rpi
cp /home/joy/src/xiaozhi_rpi/config/config.json /home/joy/src/py-xiaozhi/config/
cp /home/joy/src/xiaozhi_rpi/config/efuse.json /home/joy/src/py-xiaozhi/config/
```

## Paso 6: Descargar modelo de activación

```bash
cd /home/joy/src/xiaozhi_rpi
./scripts/download-wake-word-model.sh
```

Instala el modelo Vosk en `/home/joy/src/py-xiaozhi/models/`.

## Paso 7: Iniciar Xiaozhi

```bash
cd /home/joy/src/py-xiaozhi
python3 main.py --mode cli
```

## Verificación

```bash
# Reproducción (MAX98357A)
aplay -l | grep MAX98357A
speaker-test -D hw:2,0 -c 2 -t sine -f 440 -l 1

# Captura (INMP441 — activar con toggle primero)
arecord -l | grep inmp441
arecord -D plughw:1,0 -f S32_LE -r 48000 -c 2 -d 5 test.wav
aplay test.wav
```

## Despliegue Remoto (Deploy)

Todo el proceso anterior se puede automatizar:

```bash
LINK_PROJECT_GIT=https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git \
./scripts/deploy-rpi.sh
```

Ver [deploy-rpi.sh](../scripts/deploy-rpi.sh) para detalles.

## Solución de Problemas

| Problema | Causa posible | Solución |
|----------|---------------|----------|
| `max98357a` no en `aplay -l` | Overlay no cargado | `bash scripts/toggle-inmp441.sh --enable-playback`; reinicie |
| `inmp441` no en `arecord -l` | Overlay no cargado | `bash scripts/toggle-inmp441.sh --enable-capture`; reinicie |
| Grabación silenciosa | Micrófono no conectado | Verifique wiring en [inmp441-wiring.md](inmp441-wiring.md) |
| `config.txt` no funciona | Path incorrecto | Usar `/boot/firmware/config.txt` (no `/boot/config.txt`) |
| Sin audio de salida | Tarjeta equivocada | Usar `-D hw:2,0` (MAX98357A) |
| `set_params: invalid argument` | Formato incorrecto | Usar `-f S32_LE -c 2` para INMP441, `-c 2` para playback |
