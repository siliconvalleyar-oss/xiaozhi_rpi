# Xiaozhi para Raspberry Pi (xiaozhi_rpi)

Asistente de voz inteligente basado en **py-xiaozhi** adaptado para Raspberry Pi con micrófono INMP441 vía I2S y amplificador MAX98357A.

## Descripción

Este proyecto contiene configuración y scripts de despliegue para el asistente de voz Xiaozhi en Raspberry Pi. Incluye:

- Configuración del sistema (`config/config.json`, `config/efuse.json`)
- Scripts de instalación de dependencias, pines I2S y modelo de voz
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
                    │  ├── overlays/                   │
                    │  │   └── inmp441-max98357a-comb..│
                    │  ├── docs/                       │
                    │  └── scripts/                    │
                    │      ├── install-dependencies.sh │
                    │      ├── install-miniconda.sh    │
                    │      ├── setup-pins.sh           │
                    │      ├── toggle-inmp441.sh       │
                    │      ├── download-wake-word-model.sh│
                    │      └── deploy-rpi.sh           │
                    └──────────────────────────────────┘
                          │
                      INMP441 (I2S) + MAX98357A (I2S)
```

## Hardware Requerido

| Componente | Conexión |
|------------|----------|
| Micrófono INMP441 | I2S: SD→GPIO20, SCK→GPIO18, WS→GPIO19, L/R→GPIO21 |
| Amplificador MAX98357A | I2S: DIN→GPIO21, BCLK→GPIO18, LCLK→GPIO19, SD→GND |
| Raspberry Pi | 3B+, 4B, o Zero 2W |
| Cámara (opcional) | USB (índice 0) o CSI |

> **INMP441 + MAX98357A combinados:** Comparten el mismo DAI I2S (`bcm2835-i2s`). El overlay combinado `inmp441-max98357a-combined` crea una **solita tarjeta de sonido** con captura (device 1) y reproducción (device 0) simultáneas. No se necesita alternar overlays. Ver [INMP441 wiring](docs/inmp441-wiring.md).

## Instalación Local

```bash
# 1. Clonar este repositorio
cd /home/joy/src
git clone https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git
cd xiaozhi_rpi

# 2. Instalar dependencias del sistema
sudo ./scripts/install-dependencies.sh

# 3. Configurar pines I2S (overlay combinado INMP441 + MAX98357A)
sudo ./scripts/setup-pins.sh

# 4. Descargar modelo de palabra de activación
./scripts/download-wake-word-model.sh

# 5. Configurar py-xiaozhi
if [ -d /home/joy/src/py-xiaozhi ]; then
    cp config/config.json /home/joy/src/py-xiaozhi/config/
    cp config/efuse.json /home/joy/src/py-xiaozhi/config/
fi

# 6. Reiniciar para aplicar cambios I2S
sudo reboot
```

## Instalación Remota (Deploy)

```bash
LINK_PROJECT_GIT=https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git \
./scripts/deploy-rpi.sh
```

El deploy:
1. Clona/actualiza `xiaozhi_rpi` en `/home/joy/src`
2. Instala dependencias del sistema
3. Configura pines I2S (overlay combinado)
4. Descarga el modelo de voz
5. Copia `config/` a `py-xiaozhi/config/`
6. Si `py-xiaozhi` no existe, lo clona
7. Ejecuta `python3 main.py --mode cli`

## Estructura del Proyecto

```
xiaozhi_rpi/
├── LICENSE
├── README.md
├── PROMPT.md
├── .gitignore
├── config/
│   ├── config.json       # Configuración Xiaozhi (red, MQTT, cámara, etc.)
│   └── efuse.json        # Identidad del dispositivo (MAC, serial, HMAC)
├── overlays/
│   └── inmp441-max98357a-combined.dts  # Overlay I2S combinado
├── docs/
│   ├── install.md        # Guía de instalación paso a paso
│   ├── configuration.md  # Referencia de config.json
│   ├── inmp441-wiring.md # Pinout y configuración I2S
│   └── camera-setup.md   # Configuración de cámara (v4l2-ctl)
└── scripts/
    ├── install-dependencies.sh
    ├── install-miniconda.sh
    ├── setup-pins.sh        # Overlay I2S + módulos kernel
    ├── toggle-inmp441.sh    # Alternar overlays (respaldo)
    ├── download-wake-word-model.sh
    └── deploy-rpi.sh
```

## Verificación

```bash
# Listar tarjetas de sonido (debería mostrar INMP441-MAX98357A)
ssh joy@raspberry.local "aplay -l"
ssh joy@raspberry.local "arecord -l"

# MAX98357A (reproducción — card N, device 0)
ssh joy@raspberry.local "speaker-test -D hw:N,0 -c 2 -t sine -f 440"

# INMP441 (captura — card N, device 1)
ssh joy@raspberry.local "arecord -D hw:N,1 -f S32_LE -r 48000 -c 2 -d 5 grab.wav"
```

Ver [inmp441-wiring.md](docs/inmp441-wiring.md) para la guía completa de hardware y resolución de conflictos.

## Licencia

[MIT](LICENSE)
