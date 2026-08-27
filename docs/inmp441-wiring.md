# Configuración del Micrófono INMP441 para Raspberry Pi

## Resumen

El **INMP441** es un micrófono digital I2S de dos canales. En Raspberry Pi, puede configurarse junto con el amplificador **MAX98357A** usando un **overlay device tree combinado** que crea una sola tarjeta de sonido con captura (INMP441) y reproducción (MAX98357A) simultáneas.

## Pinout I2S Compartido

INMP441 (captura) y MAX98357A (reproducción) comparten los pines de reloj I2S:

| Señal  | INMP441 | MAX98357A | GPIO | Pin físico |
|--------|---------|-----------|------|------------|
| BCLK   | SCK     | BCLK      | GPIO18 | Pin 12 (PCM_CLK) |
| LRCK   | WS      | LCLK      | GPIO19 | Pin 35 (PCM_FS)  |
| Datos  | SD (entrada) | DIN (salida) | GPIO20/GPIO21 | Pin 38 (DIN→GPIO20), Pin 40 (GPIO21) |
| L/R    | L/R     | —         | GPIO21 | Pin 40 (LOW=izq, HIGH=der) |

### Conexiones INMP441 → Raspberry Pi 4

| INMP441 Pin | Descripción | RPi Pin (físico) |
|-------------|-------------|-----------------|
| VDD         | Alimentación 3.3V | Pin 17 (3.3V)  |
| GND         | Tierra        | Pin 6, 9, 14, 20, 25, 30, 34, 39 (GND) |
| SD          | Datos serial (DIN) | Pin 38 (GPIO20) |
| SCK         | Reloj I2S (BCLK)   | Pin 12 (GPIO18) |
| WS          | Word select (LRCK) | Pin 35 (GPIO19) |
| L/R         | Selección canal    | Pin 40 (GPIO21) |

### Conexiones MAX98357A → Raspberry Pi 4

| MAX98357A Pin | Descripción | RPi Pin (físico) |
|---------------|-------------|-----------------|
| VDD          | Alimentación 3.3V | Pin 1, 17 (3.3V) |
| GND          | Tierra        | Pin 6, 9, 14, 20, 25, 30, 34, 39 (GND) |
| DIN          | Datos I2S (DOUT) | Pin 40 (GPIO21)   |
| BCLK         | Reloj I2S     | Pin 12 (GPIO18)   |
| LCLK         | Word select   | Pin 35 (GPIO19)   |
| SD           | Shutdown (GND=activo) | Conectar a GND |

## Configuración del Overlay Combinado

### Fuente

El overlay combinado se basa en el proyecto [`Virgil-Zu/snd-soc-inmp441`](https://github.com/Virgil-Zu/snd-soc-inmp441/blob/main/inmp441-max98357a-overlay.dts). Usa el formato `simple-audio-card,dai-link@N` (subnodes) que permite múltiples enlaces DAI en una sola tarjeta de sonido.

### Archivo del Overlay

El archivo `overlays/inmp441-max98357a-combined.dts` define:
- **fragment@0**: Habilita `&i2s_clk_producer` (DAI I2S del bcm2835)
- **fragment@1**: Define códecs `max98357a` (reproducción) y `dmic-codec` (captura)
- **fragment@2**: Configura `&sound` como `simple-audio-card` con dos dai-links:
  - `dai-link@0` (captura): INMP441/dmic-codec → cpu = i2s_clk_producer
  - `dai-link@1` (reproducción): MAX98357A → cpu = i2s_clk_producer

### Instalación

```bash
# Desde el directorio del proyecto
sudo bash scripts/setup-pins.sh

# Luego reiniciar
sudo reboot
```

El script `setup-pins.sh`:
1. Compila el overlay `.dts` → `.dtbo` y lo instala en `/boot/firmware/overlays/`
2. Añade `dtoverlay=inmp441-max98357a-combined` a `/boot/firmware/config.txt`
3. Activa `dtparam=i2s=on`
4. Carga módulos: `snd-soc-dmic`, `snd-soc-max98357a`

## Verificación

Después de reiniciar:

```bash
# Listar dispositivos de reproducción
aplay -l
# Card N: INMP441-MAX98357A, Device 0: bcm2835-i2s-HiFi HiFi-0

# Listar dispositivos de captura
arecord -l
# Card N: INMP441-MAX98357A, Device 1: bcm2835-i2s-dmic-hifi dmic-hifi-1

# Probar reproducción (MAX98357A)
speaker-test -D hw:N,0 -c 2 -t sine -f 440

# Probar captura (INMP441)
arecord -D hw:N,1 -f S32_LE -r 48000 -c 2 -d 5 grab.wav
```

## Conflictos I2S y Solución

### Problema del conflicto de DAI

INMP441 y MAX98357A comparten el mismo DAI I2S (`bcm2835-i2s`). Si se activan como overlays separados (`inmp441-bare` + `max98357a`), el kernel rechaza el segundo:

```
ASoC: Failed to bind card: INMP441-MAX98357A
Trying to bind component to card MAX98357A but is already bound to card INMP441
```

### Solución: Overlay combinado (recomendado)

Usar `dtoverlay=inmp441-max98357a-combined` con el formato `dai-link@N`. El kernel acepta múltiples dai-links en la misma `simple-audio-card` porque cada uno define su propio códec virtual (`dmic-codec` y `max98357a`) conectado al mismo DAI físico.

### Alternativa: Modo alternado

Si el overlay combinado no funciona (kernel incompatible), usar `scripts/toggle-inmp441.sh`:

```bash
# Activar solo captura (INMP441)
bash scripts/toggle-inmp441.sh --enable-capture

# Activar solo reproducción (MAX98357A)
bash scripts/toggle-inmp441.sh --enable-playback
```

⚠️ **Nota:** El modo alternado requiere reiniciar entre cambios. El overlay combinado no necesita reiniciar (excepto por el cambio de config.txt).
