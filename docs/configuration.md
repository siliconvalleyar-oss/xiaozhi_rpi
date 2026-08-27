# Guía de Configuración de Xiaozhi

Esta guía explica cómo configurar el asistente de voz Xiaozhi para Raspberry Pi editando el archivo `config.json`.

## Archivo config.json

Copie el archivo de ejemplo y configure los valores:

```bash
cp config.json.example config.json
```

### Estructura general

```json
{
  "OPCIONES_DEL_SISTEMA": {
    "ID_CLIENTE": "...",
    "ID_DEL_DISPOSITIVO": "...",
    "RED": { ... }
  },
  "OPCIONES_DE_PALABRA_DE_DESPERTAR": { ... },
  "TEMPERATURE_SENSOR_MQTT_INFO": { ... },
  "ASISTENTE_DOMÉSTICO": { ... },
  "CÁMARA": { ... }
}
```

## Sección: OPCIONES_DEL_SISTEMA

| Campo | Descripción |
|-------|-------------|
| `ID_CLIENTE` | UUID único del cliente (generado en la plataforma) |
| `ID_DEL_DISPOSITIVO` | Dirección MAC de la Raspberry Pi |
| `RED.OTA_VERSION_URL` | URL para comprobaciones de actualización OTA |
| `RED.WEBSOCKET_URL` | Endpoint WebSocket para la conexión con el servidor |
| `RED.WEBSOCKET_ACCESS_TOKEN` | Token de acceso WebSocket |
| `RED.MQTT_INFO` | Configuración de conexión MQTT (endpoint, credenciales, topics) |
| `RED.VERSIÓN_DE_ACTIVACIÓN` | Versión del protocolo de activación (`v2`) |
| `RED.URL_DE_AUTORIZACIÓN` | URL para la autorización del dispositivo |

### Obtener el ID_DEL_DISPOSITIVO (MAC)

```bash
cat /sys/class/net/eth0/address
# o
cat /sys/class/net/wlan0/address
```

## Sección: OPCIONES_DE_PALABRA_DE_DESPERTAR

| Campo | Descripción |
|-------|-------------|
| `USE_WAKE_WORD` | Habilitar/deshabilitar la detección de palabra de activación (`true`/`false`) |
| `MODEL_PATH` | Ruta al modelo Vosk para la detección de palabras de activación |
| `PALABRAS_DE_DESPERTAR` | Lista de palabras/frases que activan al asistente |

## Sección: TEMPERATURE_SENSOR_MQTT_INFO (Opcional)

Configuración de un sensor de temperatura que publica a un broker MQTT.

| Campo | Descripción |
|-------|-------------|
| `endpoint` | Dirección del broker MQTT |
| `port` | Puerto del broker (por defecto 1883) |
| `username` / `password` | Credenciales MQTT |
| `publish_topic` | Topic para publicar comandos |
| `subscribe_topic` | Topic para suscribirse a estados |

## Sección: ASISTENTE_DOMÉSTICO (Home Assistant)

| Campo | Descripción |
|-------|-------------|
| `URL` | URL de Home Assistant (ej: `http://localhost:8123`) |
| `TOKEN` | Token de acceso de larga duración (Long-Lived Access Token) |
| `DISPOSITIVOS` | Lista de dispositivos a exponer |

### Generar un token de Home Assistant

1. Inicie sesión en Home Assistant
2. Perfil de usuario → "Tokens de acceso de larga duración"
3. Cree un nuevo token y péguelo en `config.json`

## Sección: CÁMARA (Opcional)

| Campo | Descripción |
|-------|-------------|
| `índice_de_cámara` | Índice de la cámara en `/dev/video*` |
| `frame_width` / `frame_height` | Resolución del frame |
| `fps` | FPS de captura |
| `Loacl_VL_url` | Endpoint de la API de visión por IA |
| `VLapi_key` | Clave API de la función de visión |
| `modelos` | Modelo de visión a utilizar |

## Activación del dispositivo

El dispositivo debe estar activado (emparejado) con una cuenta Xiaozhi válida. Este proceso suele requerir:

1. Iniciar `python3 main.py`
2. Escanear el código QR que aparece en la consola con la app móvil Xiaozhi
3. El servidor asignará un `ID_CLIENTE` y `ACCESS_TOKEN` válidos
