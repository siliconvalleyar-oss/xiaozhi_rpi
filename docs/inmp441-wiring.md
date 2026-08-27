# Conexión del Micrófono INMP441 a Raspberry Pi

Este documento describe cómo conectar físicamente el micrófono digital **INMP441** a una Raspberry Pi usando el bus I2S, y cómo resolver el conflicto con el amplificador MAX98357A (ambos compiten por el mismo DAI I2S).

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

## Configuración y Conflictos I2S

### Conflicto INMP441 + MAX98357A

El INMP441 (captura) y el MAX98357A (reproducción) **no pueden estar activos simultáneamente** en la misma Raspberry Pi. Ambos usan el driver `simple-audio-card` que enlaza el DAI I2S (`bcm2835-i2s`, nodo `fe203000.i2s`) a la tarjeta de sonido. El framework ASoC del kernel impide que el mismo DAI se enlaze a dos tarjetas diferentes:

```
bcm2835-i2s fe203000.i2s: Trying to bind component "fe203000.i2s" to card "MAX98357A" but is already bound to card "inmp441-mic"
asoc-simple-card soc:sound: ASoC: failed to instantiate card -19
```

### Solución: Overlay combinado (opcional)

El archivo `overlays/inmp441-max98357a-combined.dts` define una sola `simple-audio-card` con dos enlaces DAI (uno para cada codec). Si funciona en tu kernel, instálalo:

```bash
dtc -@ -I dts -O dtb -o inmp441-max98357a-combined.dtbo overlays/inmp441-max98357a-combined.dts
sudo cp inmp441-max98357a-combined.dtbo /boot/firmware/overlays/
sed -i 's/^dtoverlay=max98357a.*/dtoverlay=inmp441-max98357a-combined/' /boot/firmware/config.txt
sudo reboot
```

### Solución recomendada: Cambio de overlay con toggle

Usa el script `scripts/toggle-inmp441.sh` para alternar entre modos:

```bash
# Modo captura (INMP441) — desactiva MAX98357A
bash scripts/toggle-inmp441.sh --enable-capture

# Modo reproducción (MAX98357A) — desactiva INMP441
bash scripts/toggle-inmp441.sh --enable-playback

# Ver estado
bash scripts/toggle-inmp441.sh --status
```

## Configuración del Software (I2S y Overlay)

### 1. Configuración actual en la Raspberry Pi

La Pi (`raspberry.local`) tiene:
- **Overlay `max98357a`**: activado (reproducción de audio vía amplificador I2S)
- **Overlay `inmp441-bare`**: comentado en config.txt (conflicto con max98357a)
- **Archivo config.txt**: `/boot/firmware/config.txt` (Raspberry Pi OS Bookworm)

### 2. Activar INMP441 (desactiva reproducción MAX98357A)

```bash
# Opción A: usar el script de toggle
bash /home/joy/src/xiaozhi_rpi/scripts/toggle-inmp441.sh --enable-capture
sudo reboot

# Opción B: manualmente
sudo sed -i 's/^dtoverlay=max98357a.*/#\0/' /boot/firmware/config.txt
sudo sed -i 's/^#dtoverlay=inmp441-bare.*/dtoverlay=inmp441-bare/' /boot/firmware/config.txt
sudo reboot
```

### 3. Cargar módulos del kernel

```bash
sudo modprobe snd-soc-bcm2835-i2s
sudo modprobe snd-soc-dmic
sudo modprobe snd-soc-max98357a
```

Añadir al arranque en `/etc/modules`:
```
snd-soc-bcm2835-i2s
snd-soc-dmic
snd-soc-max98357a
```

### 4. Verificar

```bash
# Reproducción (con MAX98357A activo)
aplay -l | grep MAX98357A → debe mostrar la tarjeta

# Captura (con INMP441 activo)
arecord -l | grep inmp441 → debe mostrar la tarjeta de captura
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
# Diagnóstico completo del micrófono
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
| `arecord -l` no muestra `inmp441` | Overlay no cargado | `bash scripts/toggle-inmp441.sh --enable-capture`; reinicie |
| `aplay -l` no muestra `MAX98357A` | Overlay no cargado | `bash scripts/toggle-inmp441.sh --enable-playback`; reinicie |
| Ambos overlays fallan | Conflicto I2S | Usar un overlay a la vez (ver toggle-inmp441.sh) |
| Grabación silenciosa | Micrófono no conectado | Verifique wiring: SD→GPIO20, SCK→GPIO18, WS→GPIO19, L/R→GPIO21 |
| BCLK/WS incorrectos | GPIO mal configurados | El overlay `inmp441-bare` configura los pines I2S automáticamente |
| `Permission denied` | Usuario no en grupo `audio` | `sudo usermod -a -G audio $USER && newgrp audio` |
| Ruido estático | Condensador faltante | Añadir 0.1 µF entre VDD y GND del INMP441 |
| Alineación de bits incorrecta | Formato de muestra | Usar `-f S32_LE`; los 24 bits están en bits 31–8 |
| Canales intercambiados | L/R en estado incorrecto | Verifique GPIO 21 o use `--no-lr-gpio` con L/R a GND |
