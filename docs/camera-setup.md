# Configuración de la Cámara en Raspberry Pi

Este documento explica cómo configurar y verificar la cámara para Xiaozhi en Raspberry Pi.

## Detectar cámaras disponibles

Use `v4l2-ctl` para listar los dispositivos de video disponibles:

```bash
v4l2-ctl --list-devices
```

### Ejemplo de salida:

```
bcm2835-codec-decode (platform:bcm2835-codec):
    /dev/video10
    /dev/video11
    /dev/video12
    /dev/video18
    /dev/video31

bcm2835-isp (platform:bcm2835-isp):
    /dev/video13
    /dev/video14
    /dev/video15
    /dev/video16
    /dev/video20
    /dev/video21
    /dev/video22
    /dev/video23
    /dev/media3
    /dev/media4

unicam (platform:fe801000.csi):
    /dev/media0
```

## Configurar el índice de cámara

### Cámara USB

Si solo tiene una cámara USB conectada, configure `camera_index` en `config/config.json`:

```json
"CAMERA": {
    "camera_index": 0,
    "backend": "auto",
    ...
}
```

Use `camera_index: 0` para la primera cámara USB detectada.

### Cámara CSI (Raspberry Pi Camera)

Si usa la cámara CSI oficial de Raspberry Pi:

1. Habilite la interfaz CSI en `/boot/config.txt`:

```bash
sudo raspi-config
# Interfacing Options → Camera → Enable
```

O añada manualmente:

```
start_x=1
```

2. Configure el backend en `config/config.json`:

```json
"CAMERA": {
    "camera_index": 0,
    "backend": "picamera2",
    ...
}
```

El modo `auto` intentará primero OpenCV, y si falla, usará `picamera2` para la cámara CSI.

## Verificación

Para probar la cámara:

```bash
# Ver dispositivos de video
ls /dev/video*

# Probar con ffmpeg
ffmpeg -f v4l2 -list_formats all -i /dev/video0

# Capturar un frame de prueba
ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames:v 1 test.jpg
```

## Solución de Problemas

| Síntoma | Causa posible | Verificación |
|---------|---------------|--------------|
| `camera_index` no funciona | Índice incorrecto | `v4l2-ctl --list-devices` |
| Cámara CSI no detectada | CSI no habilitada | `sudo raspi-config` → Camera |
| Imagen oscura o ruidosa | Baja luz | Ajustar exposición o agregar iluminación |
| `picamera2` no funciona | Paquete no instalado | `pip install picamera2` o `sudo apt install python3-picamera2` |
| Resolución incorrecta | Formato no soportado | `ffmpeg -f v4l2 -list_formats all -i /dev/video0` |
