# Xiaozhi para Raspberry Pi (xiaozhi_rpi)

Asistente de voz inteligente basado en xiaozhi-esp32 adaptado para Raspberry Pi.

## Descripción

Este proyecto contiene la configuración, scripts e documentación necesarios para instalar y operar el asistente de voz **Xiaozhi** en una Raspberry Pi con micrófono INMP441 conectado vía I2S.

## Características

- Asistente de voz con detección de palabra de activación
- Micrófono digital INMP441 vía I2S
- Comunicación vía WebSocket y MQTT
- Soporte para cámara y visión por IA
- Integración con Home Assistant

## Estructura del Proyecto

```
xiaozhi_rpi/
├── LICENSE
├── README.md
├── PROMPT.md
├── config.json.example          # Configuración de ejemplo
├── docs/
│   ├── install.md               # Guía de instalación
│   ├── configuration.md         # Configuración de Xiaozhi
│   └── inmp441-wiring.md        # Conexión del micrófono INMP441
├── scripts/
│   ├── install-dependencies.sh  # Instalar dependencias del sistema
│   ├── install-miniconda.sh     # Instalar Miniconda
│   ├── setup-pins.sh            # Configurar pines GPIO/I2S
│   └── deploy-rpi.sh            # Desplegar en Raspberry Pi
└── PROMPT.md
```

## Requisitos

- Raspberry Pi (modelo 3B+, 4B o superior recomendado)
- Micrófono INMP441
- Raspbian / Raspberry Pi OS

## Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/siliconvalleyar-oss/xiaozhi_rpi.git
cd xiaozhi_rpi
```

2. Ejecuta los scripts de instalación:
```bash
sudo ./scripts/install-dependencies.sh
sudo ./scripts/install-miniconda.sh
sudo ./scripts/setup-pins.sh
```

3. Configura `config.json` a partir del ejemplo.

4. Inicia el asistente:
```bash
python3 main.py
```

## Licencia

[MIT](LICENSE)
