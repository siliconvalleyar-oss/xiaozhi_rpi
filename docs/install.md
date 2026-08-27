# Guía de Instalación de Xiaozhi en Raspberry Pi

Esta guía explica paso a paso cómo instalar el asistente de voz **Xiaozhi** en una Raspberry Pi.

## Requisitos Previos

- Raspberry Pi 3B+, 4B o superior
- Sistema operativo: Raspberry Pi OS (64-bit recomendado) o Raspbian
- Micrófono digital INMP441 conectado vía I2S
- Acceso a internet

## Paso 1: Actualizar el sistema

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

## Paso 2: Instalar dependencias del sistema

```bash
cd xiaozhi_rpi
sudo chmod +x scripts/install-dependencies.sh
sudo ./scripts/install-dependencies.sh
```

Este script instala:
- `pulseaudio-utils` y `portaudio19-dev` para soporte de audio
- `python3-pyaudio`, `python3-venv`, `python3-pip` para Python
- `ffmpeg` y `libopus0`/`libopus-dev` para codificación de audio
- `build-essential` para compilación

## Paso 3: Instalar Miniconda

```bash
sudo chmod +x scripts/install-miniconda.sh
sudo ./scripts/install-miniconda.sh
```

Miniconda se instala en `~/miniconda3`. Tras la instalación, reinicie la terminal o ejecute:

```bash
source ~/.bashrc
```

## Paso 4: Configurar los pines del INMP441

```bash
sudo chmod +x scripts/setup-pins.sh
sudo ./scripts/setup-pins.sh
```

Este script:
- Habilita la interfaz I2S en `/boot/config.txt`
- Carga los módulos del kernel necesarios
- Muestra el pinout del micrófono INMP441

> **Importante:** Reinicie la Raspberry Pi tras ejecutar este script.

## Paso 5: Configurar Xiaozhi

Copie el archivo de configuración de ejemplo y edítelo:

```bash
cp config.json.example config.json
nano config.json
```

Consulte la [guía de configuración](configuration.md) para más detalles.

## Paso 6: Iniciar el asistente

```bash
python3 main.py
```

## Verificación

Para verificar que el micrófono INMP441 funciona:

```bash
arecord -l
```

Debería aparecer un dispositivo I2S listado.

Para probar la captura de audio:

```bash
arecord -D hw:1,0 -f S16_LE -r 16000 -c 1 test.wav
aplay test.wav
```

## Solución de Problemas

| Problema | Causa posible |
|----------|---------------|
| No aparece el micrófono | I2S no habilitado en `config.txt` |
| Error de permisos GPIO | Ejecutar con `sudo` o añadir usuario al grupo `gpio` |
| Sin audio de salida | Verificar configuración de `pulseaudio` |

Consulte también la [guía de conexión del INMP441](inmp441-wiring.md).
