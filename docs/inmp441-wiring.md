# Conexión del Micrófono INMP441 a Raspberry Pi

Este documento describe cómo conectar físicamente el micrófono digital **INMP441** a una Raspberry Pi usando el bus I2S, basado en la configuración validada en el proyecto `inmp441_rpi`.

## Acerca del INMP441

El INMP441 es un micrófono MEMS digital de doble vía con salida PDM (Pulse Density Modulation). El Raspberry Pi actúa como maestro I2S, generando los relojes (BCLK y WS) y recibiendo los datos del micrófono.

## Pinout del INMP441 → Raspberry Pi

| Pin INMP441 | Función | Raspberry Pi GPIO | Pin físico (40-pines) |
|-------------|---------|-------------------|----------------------|
| VDD | 3.3V de alimentación | 3.3V | Pin 1 o 17 |
| GND | Tierra | GND | Pin 6, 9, 14, 20, 25, 30, 34, 39 |
| SD | Datos (PCM_DIN) | **GPIO 20** | Pin 38 |
| SCK | Reloj (PCM_CLK / BCLK) | **GPIO 18** | Pin 12 |
| WS | Word Select (PCM_FS / LRCK) | **GPIO 19** | Pin 35 |
| L/R | Selección de canal | **GPIO 21** | Pin 40 |

> **Importante:** El pin **L/R** se conecta a **GPIO 21 (Pin 40)**. El software lo controla con `libgpiod`:
> - `LOW` (0V) → transmite en el canal izquierdo (default)
> - `HIGH` (3.3V) → transmite en el canal derecho
> 
> Alternativamente, puede conectar L/R directamente a GND (canal izquierdo) o a 3.3V (canal derecho) y usar `--no-lr-gpio`.

## Diagrama de Conexión

```
              Raspberry Pi 40-pines (vista superior)
              ┌─────────────────┐
  3.3V ──────┤  Pin 1      Pin 2  │────── 5V
  3.3V ──────┤  Pin 17     Pin 18 │────── GPIO 24
  GND  ──────┤  Pin 6      Pin 5  │────── GPIO 3 (SDA1)
  GND  ──────┤  Pin 9      Pin 10 │────── GPIO 2 (SCL1)
  GPIO 20 ───┤  Pin 38     Pin 39 │────── GND
  GPIO 21 ───┤  Pin 40     Pin 37 │────── GPIO 26
  GPIO 18 ───┤  Pin 12     Pin 13 │────── GPIO 27
  GPIO 19 ───┤  Pin 35     Pin 36 │────── GND
              └─────────────────┘

Conexiones INMP441 → Raspberry Pi:
  VDD  (INMP441) ────→ 3.3V  (Pin 1 o Pin 17)
  GND  (INMP441) ────→ GND   (Pin 6, 9, o 14)
  SD   (INMP441) ────→ GPIO20 (Pin 38, PCM_DIN)
  SCK  (INMP441) ────→ GPIO18 (Pin 12, PCM_CLK/BCLK)
  WS   (INMP441) ────→ GPIO19 (Pin 35, PCM_FS/LRCK)
  L/R  (INMP441) ────→ GPIO21 (Pin 40, selección de canal)

Recomendado: Añadir un condensador cerámico de 100 nF (0.1 µF) entre VDD y GND
muy cerca del INMP441 para reducir ruido de alimentación.
```

## Configuración del Software (I2S y Overlay)

### 1. Instalar el device tree overlay

El overlay `inmp441-bare` ya está instalado en la Raspberry Pi (`raspberry.local`) en:
```
/boot/firmware/overlays/inmp441-bare.dtbo
```

El overlay usa el driver genérico `dmic-codec` (`snd-soc-dmic`) en lugar del "dummy" `google,voicehat`. No requiere GPIO de sdmode.

Si necesita recompilar el overlay desde el DTS fuente:
```bash
# En la Raspberry Pi o con toolchain de cross-compilation:
cd /home/joy/src/inmp441_rpi/
dtc -@ -I dts -O dtb -o inmp441-bare.dtbo overlays/inmp441-bare.dts
sudo cp inmp441-bare.dtbo /boot/firmware/overlays/
```

### 2. Habilitar el overlay en `/boot/config.txt`

```bash
sudo bash -c 'echo "dtoverlay=inmp441-bare,alsaname=mems-mic" >> /boot/config.txt'
```

> **Nota:** El `setup-pins.sh` en `scripts/` hace esto automáticamente.

### 3. Cargar módulos del kernel

```bash
sudo modprobe snd-bcm2835
sudo modprobe snd-soc-bcm2835-i2s
sudo modprobe snd-soc-dmic
```

Añadir al arranque en `/etc/modules`:
```
snd-bcm2835
snd-soc-bcm2835-i2s
snd-soc-dmic
```

### 4. Reiniciar

```bash
sudo reboot
```

### 5. Verificar

Después del reinicio:
```bash
# El micrófono debe aparecer como tarjeta de captura
arecord -l
```

Salida esperada:
```
**** List of CAPTURE Hardware Devices ****
card 1: inmp441bare [inmp441-bare], device 0: ...
  ...
```

## Prueba del Micrófono

```bash
# Capturar 5 segundos de audio (formato S32_LE, 48kHz, estéreo I2S)
arecord -D plughw:1,0 -f S32_LE -r 48000 -c 2 -d 5 test.wav

# Reproducir
aplay test.wav
```

> El INMP441 transmite en formato S32_LE con 24 bits útiles alineados al MSB. Asegúrese de usar `-f S32_LE`.

## Alternativa: Usar el proyecto `inmp441_rpi`

En la Raspberry Pi ya existe el proyecto `inmp441_rpi` en `/home/joy/src/inmp441_rpi/` con utilidades avanzadas de captura y diagnóstico:

```bash
# Diagnostico completo del micrófono
cd /home/joy/src/inmp441_rpi/
sudo ./scripts/diag_mic.sh

# Grabación básica
sudo ./bin/recorder --wav -d 5 out.wav

# Ver niveles de audio en tiempo real
sudo ./bin/recorder --level
```

## Solución de Problemas

| Síntoma | Causa posible | Solución |
|----------|---------------|----------|
| `arecord -l` no muestra `inmp441-bare` | Overlay no cargado | Verifique `/boot/config.txt` tiene `dtoverlay=inmp441-bare`; reinicie |
| Grabación silenciosa o muy corta | BCLK/WS incorrectos | Verifique GPIO 18 (SCK) → Pin 12, GPIO 19 (WS) → Pin 35 |
| `Permission denied` en `snd_pcm_open` | Usuario no en grupo `audio` | `sudo usermod -a -G audio $USER && newgrp audio` |
| Ruido estático | Condensador de acoplamiento faltante | Añadir 0.1 µF entre VDD y GND del INMP441 |
| Amplitud muy baja | Alineación de bits | Usar `-f S32_LE`; los 24 bits están en bits 31–8 |
| Canales izquierdo/derecho intercambiados | L/R en estado incorrecto | Verifique GPIO 21 o use `--no-lr-gpio` con L/R a GND |
