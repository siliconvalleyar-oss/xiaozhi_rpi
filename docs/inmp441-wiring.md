# Conexión del Micrófono INMP441 a Raspberry Pi

Este documento describe cómo conectar físicamente el micrófono digital **INMP441** a una Raspberry Pi usando el bus I2S.

## Acerca del INMP441

El INMP441 es un micrófono MEMS digital de doble vía con salida PDM (Pulse Density Modulation). Es compatible con la interfaz I2S de la Raspberry Pi.

## Pinout del INMP441

```
    _________________________
   /                         \
  |    INMP441               |
  |                           |
  |  VDD    GND    SD    SCK  |
  |   |      |     |     |   |
   \_________________________/
```

| Pin INMP441 | Función | Raspberry Pi | Pin físico (40-pines) | GPIO |
|-------------|---------|--------------|----------------------|------|
| VDD | 3.3V de alimentación | 3.3V | Pin 1 | - |
| GND | Tierra | GND | Pin 6 | - |
| SD | Datos (I2S_DIN) | GPIO18 | Pin 40 | GPIO18 |
| SCK | Reloj (I2S_BCLK) | GPIO19 | Pin 35 | GPIO19 |
| WS/LR | Word Select (I2S_LRCK) | GPIO6* | Pin 31 | GPIO6 |
| L/R* | Selección de canal | GND | Pin... | - |

> \* Nota: El pin "WS" (Word Select / LRCK) del INMP441 se conecta a GPIO6 (Pin 31) en la configuración estándar. El pin "L/R" (Left/Right) se conecta a GND para seleccionar canal izquierdo (o puede dejarse sin conexión para ambos canales).

## Diagrama de Conexión

```
Raspberry Pi 40-pines (vista superior)

         +----------------+
    3.3V |  1  o o  2 | 5V
         |  3  o o  4 | 5V
    SDA1 |  3  o o  5 | 5V
    SCL1 |  5  o o  6 | GND
    GPIO6|  31 o o 32| GPIO12
         |        ...
    GPIO19| 35 o o 36| GND
         |        ...
         |        ...
    GPIO18| 40 o      |

Conexiones INMP441:
  VDD (INMP441)  ---->  3.3V  (Pin 1)
  GND (INMP441)  ---->  GND   (Pin 6)
  SD  (INMP441)  ---->  GPIO18 (Pin 40)
  SCK (INMP441)  ---->  GPIO19 (Pin 35)
  WS  (INMP441)  ---->  GPIO6  (Pin 31)
  L/R (INMP441)  ---->  GND    (Pin 6)
```

## Configuración del Software (I2S)

1. Habilite I2S en `/boot/config.txt`:

```bash
sudo dtoverlay i2s-mmap
```

O añada manualmente al final de `/boot/config.txt`:

```
dtoverlay=i2s-mmap
```

2. Cargue los módulos del kernel:

```bash
sudo modprobe snd-bcm2835
sudo modprobe snd-soc-bcm2835-i2s
sudo modprobe snd-soc-wm8960
```

3. Verifique que el dispositivo de captura esté disponible:

```bash
arecord -l
```

Debería ver algo como:

```
**** List of CAPTURE Hardware Devices ****
card 1: Device [USB Audio Device], device 0: USB Audio [USB Audio]
  ...
card 2: RaspberryPi [Raspberry Pi], device 0: HifiBerry DAC+ Pro HiFi pcm512x-hifi-00
  ...
```

## Prueba del Micrófono

```bash
# Capturar 5 segundos de audio
arecord -D hw:1,0 -f S16_LE -r 16000 -c 1 -d 5 test.wav

# Reproducir la grabación
aplay test.wav
```

## Solución de Problemas

- **No aparece el dispositivo en `arecord -l`:** Verifique que I2S está habilitado y el cableado es correcto.
- **Ruido estático:** Asegúrese de que `L/R` está conectado a GND correctamente.
- **Sin sonido:** Verifique la configuración del volumen con `alsamixer` (pulse `F6` para seleccionar la tarjeta de audio).
