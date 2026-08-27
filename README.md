# Xiaozhi para Raspberry Pi (xiaozhi_rpi)

Asistente de voz inteligente basado en **py-xiaozhi** adaptado para Raspberry Pi con micrófono INMP441 vía I2S y amplificador MAX98357A.

## Descripción

Este proyecto es un **repositorio de configuración y despliegue** para el asistente de voz Xiaozhi en Raspberry Pi. Contiene:

- Configuración del sistema (`config/config.json`, `config/efuse.json`)
- Scripts de instalación de dependencias, Miniconda, pines I2S y modelo de voz
- Documentación completa de instalación, configuración y hardware
- Script de despliegue remoto vía SSH

El código fuente de py-xiaozhi se gestiona por separado en [`py-xiaozhi`](https://github.com/virtao/py-xiaozhi) y se clona/instala en `/home/joy/src/py-xiaozhi/`.

## Arquitectura

```
                    Raspberry Pi (joy@raspberry.local)
                    ┌──────────────────────────────────┐
                    │  xiaozhi_rpi/  (este repo)       │
                    │  ├── config/                     │
                    │  │   ├── config.json  (Xiaozhi)  │
                    │  │   └── efuse.json   (identidad)│
                    │  ├── docs/                      │
                    │  └── scripts/                    │
                    │      ├── install-dependencies.sh │
                    │      ├── install-miniconda.sh    │
                    │      ├── setup-pins.sh           │
                    │      ├── download-wake-word-model.sh│
                    │      └── deploy-rpi.sh           │
                    │                                │
                    │  py-xiaozhi/  (repo externo)   │
                    │  ├── main.py  ← entry point     │
                    │  ├── config/ ← recibe config de │
                    │  │             xiaozhi_rpi       │
                    │  ├── models/zh/ (sherpa-onnx)  │
                    │  └── src/                       │
                    └──────────────────────────────────┘
                          │
                    INMP441 (I2S) + MAX98357A (I2S)
```

## Hardware Requerido

| Componente | Conexión |
|------------|----------|
| Micrófono INMP441 | I2S: SD→GPIO20, SCK→GPIO18, WS→GPIO19, L/R→GPIO21 |
| Amplificador MAX98357A | I2S: SD→GPIO... (configurado en max98357a_rpi) |
| Raspberry Pi | 3B+, 4B, o Zero 2W |
| Cámara (opcional) | USB (índice 0) o CSI |

Ver la [guía completa del INMP441](docs/inmp441-wiring.md).

## Instalación Local (en la Raspberry Pi)

```bash
# 1. Clonar este repositorio
cd /home/joy/src
git clone https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git
cd xiaozhi_rpi

# 2. Instalar dependencias del sistema
sudo ./scripts/install-dependencies.sh

# 3. Instalar Miniconda (opcional, para entornos virtuales)
sudo ./scripts/install-miniconda.sh

# 4. Configurar pines I2S para INMP441
sudo ./scripts/setup-pins.sh

# 5. Descargar modelo de palabra de activación (Vosk)
./scripts/download-wake-word-model.sh

# 6. Configurar py-xiaozhi
if [ -d /home/joy/src/py-xiaozhi ]; then
    cp config/config.json /home/joy/src/py-xiaozhi/config/
    cp config/efuse.json /home/joy/src/py-xiaozhi/config/
fi

# 7. Reiniciar para aplicar cambios I2S
sudo reboot
```

## Instalación Remota (Deploy)

El script `deploy-rpi.sh` automatiza todo el proceso anterior vía SSH:

```bash
# Con SSH sin contraseña previamente configurado
LINK_PROJECT_GIT=https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git \
./scripts/deploy-rpi.sh
```

El deploy:
1. Clona/actualiza `xiaozhi_rpi` en `/home/joy/src`
2. Instala dependencias del sistema
3. Configura pines I2S (INMP441)
4. Descarga el modelo de voz
5. Copia `config/` a `py-xiaozhi/config/`
6. Si `py-xiaozhi` no existe, lo clona
7. Ejecuta `python3 main.py --mode cli`

Comando manual equivalente (del PROMPT.md):
```bash
ssh joy@raspberry.local "cd /home/joy/src && \
    git clone https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git && \
    cd xiaozhi_rpi && \
    sudo ./scripts/install-dependencies.sh && \
    sudo ./scripts/setup-pins.sh && \
    python3 /home/joy/src/py-xiaozhi/main.py --mode cli"
```

## Estructura del Proyecto

```
xiaozhi_rpi/
├── LICENSE              # MIT para siliconvalleyar-oss
├── README.md            # Este archivo
├── PROMPT.md            # Tareas originales (preservado)
├── .gitignore
├── config/
│   ├── config.json      # Configuración Xiaozhi (sistema, red, MQTT, cámara)
│   └── efuse.json       # Identidad del dispositivo (MAC, serial, HMAC)
├── docs/
│   ├── install.md              # Guía de instalación paso a paso
│   ├── configuration.md        # Referencia de config.json
│   ├── inmp441-wiring.md       # Pinout y configuración I2S INMP441
│   └── camera-setup.md         # Configuración de cámara (v4l2-ctl)
└── scripts/
    ├── install-dependencies.sh  # PulseAudio, FFmpeg, Opus, build tools
    ├── install-miniconda.sh     # Miniconda (aarch64)
    ├── setup-pins.sh            # Overlay I2S inmp441-bare + módulos kernel
    ├── download-wake-word-model.sh  # Modelo Vosk para wake word
    └── deploy-rpi.sh            # Despliegue remoto vía SSH
```

## Verificación

Después de la instalación, verifique el hardware:

```bash
# Micrófono INMP441
ssh joy@raspberry.local "arecord -l"
# Debe mostrar: card N: inmp441bare [inmp441-bare]

# Cámara
ssh joy@raspberry.local "v4l2-ctl --list-devices"

# Audio (MAX98357A)
ssh joy@raspberry.local "aplay -l"
# Debe mostrar: card N: max98357a [MAX98357A]
```

## Licencia

[MIT](LICENSE)
