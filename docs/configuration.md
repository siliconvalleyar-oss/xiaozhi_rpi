# Guía de Configuración de Xiaozhi

Esta guía explica los archivos de configuración en `config/` y cómo desplegarlos en `py-xiaozhi`.

## Archivos de Configuración

Este repositorio contiene dos archivos de configuración en `config/`:

| Archivo | Propósito |
|---------|-----------|
| `config.json` | Configuración de py-xiaozhi (red, wake word, cámara, audio, logs) |
| `efuse.json` | Identidad del dispositivo (MAC, serial, HMAC key, estado de activación) |

### Despliegue

```bash
# Copiar a py-xiaozhi
cp config/config.json  /home/joy/src/py-xiaozhi/config/
cp config/efuse.json   /home/joy/src/py-xiaozhi/config/
```

El script `deploy-rpi.sh` hace esto automáticamente.

## config.json — Referencia de Secciones

El `config.json` usa las claves en inglés de py-xiaozhi v2.1.1:

```json
{
  "CONFIG_VERSION": 1,
  "SYSTEM_OPTIONS": {        // Información del sistema y red
    "CLIENT_ID": null,        // UUID del cliente (asignado al activar)
    "DEVICE_ID": null,        // ID del dispositivo
    "NETWORK": {
      "WEBSOCKET_URL": "wss://api.tenclass.net/xiaozhi/v1/",
      "WEBSOCKET_ACCESS_TOKEN": "test-token",
      "OTA_VERSION_URL": "https://api.tenclass.net/xiaozhi/ota/"
    }
  },
  "WAKE_WORD_OPTIONS": {     // Detección de palabra de activación
    "USE_WAKE_WORD": true,
    "MODEL_PATH": "models/zh",
    "NUM_THREADS": 5,
    "WAKE_WORD": "你好小智",
    "WAKE_WORD_LANG": "zh"
  },
  "CAMERA": {
    "camera_index": 0,
    "backend": "auto",
    "frame_width": 640,
    "frame_height": 480
  },
  "AUDIO_DEVICES": {         // Dispositivos de audio ALSA
    "output_device_id": null, // Reproducción: MAX98357A (card N, device 0)
    "input_device_id": null,  // Captura: INMP441 (card N, device 1)
    "output_sample_rate": null,
    "opus_output_sample_rate": 24000
  },
  "LOGGING": { ... }
}
```

### AUDIO_DEVICES — Configuración de Audio

Por defecto (`null`), py-xiaozhi detecta dispositivos automáticamente. Si necesita especificar manualmente:

```json
"AUDIO_DEVICES": {
    "output_device_id": 2,    // MAX98357A (aplay -l) — device 0
    "input_device_id": 2,     // INMP441 (arecord -l) — device 1 (misma card)
    "output_sample_rate": 48000,
    "input_sample_rate": 48000
}
```

Verifique los números de tarjeta con:
```bash
aplay -l    # números de card para reproducción
arecord -l  # números de card para captura
```

## efuse.json — Identidad del Dispositivo

Contiene la identidad única del dispositivo para activación:

```json
{
    "serial_number": "SN-...",
    "mac": "2c:cf:67:34:9c:91",
    "hmac_key": "...",
    "activation_status": false
}
```

Estos valores son específicos de esta Raspberry Pi. No modifique estos valores si usa el mismo hardware.

## Identificar su dispositivo

```bash
# MAC address (ethernet o wifi)
cat /sys/class/net/eth0/address
cat /sys/class/net/wlan0/address

# Serial de la Pi
cat /proc/cpuinfo | grep Serial
```

## Activación del dispositivo

1. Inicie `python3 main.py --mode cli` en `py-xiaozhi/`
2. Escanee el código QR desde la app móvil Xiaozhi
3. El servidor asignará `CLIENT_ID` y `ACCESS_TOKEN`

Ver [install.md](install.md) para el flujo completo de instalación.
