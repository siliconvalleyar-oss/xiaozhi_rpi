# Conexionado de Pines: INMP441 + MAX98357A en Raspberry Pi

## Resumen

El **INMP441** (micrófono digital I2S) y el **MAX98357A** (amplificador I2S) comparten los pines de reloj I2S (BCLK y LRCK) pero usan pines de datos diferentes. El **overlay combinado** `inmp441-max98357a-combined` permite que ambos funcionen simultáneamente en una sola tarjeta de sonido.

| Función | Device | GPIO | Pin |
|---|---|---|---|
| BCLK (reloj compartido) | Ambos | GPIO18 | Pin 12 |
| LRCK (word select compartido) | Ambos | GPIO19 | Pin 35 |
| Datos captura (INMP441 → Pi) | INMP441 | GPIO20 | Pin 38 |
| Datos salida (Pi → MAX98357A) | MAX98357A | GPIO21 | Pin 40 |
| L/R select (canal INMP441) | INMP441 | GPIO21 | Pin 40 |
| Shutdown (MAX98357A) | MAX98357A | GND | Pin 6/9 |

> **Nota sobre GPIO21/Pin 40:** Este pin sirve doble función:
> - **INMP441 L/R**: entrada digital DC que selecciona canal (LOW=izq, HIGH=der)
> - **MAX98357A DIN**: entrada de datos I2S (recibe audio del Pi)
>
> Funciona porque durante captura el Pi no transmite datos I2S en GPIO21 (permanece en 0V/LOW = canal izquierdo), y durante reproducción el INMP441 no está activo.

## Diagrama de Conexión INMP441

```
INMP441 (6 pines)
┌─────────────────────────┐
│ VDD    WS     L/R  SCK   │ ← mirando la cara con el orificio
│ GND    SD               │ ← cara inferior
└─────────────────────────┘

  VDD  → Pin 17 (3.3V)        — Alimentación
  GND  → Pin 6/9/14/20/...    — Tierra
  SD   → Pin 38 (GPIO20)      — Datos captura (serial data out)
  SCK  → Pin 12 (GPIO18)      — Reloj I2S (BCLK)
  WS   → Pin 35 (GPIO19)      — Word select (LRCK)
  L/R  → Pin 40 (GPIO21)      — Selección canal (LOW=izq, HIGH=der)
```

## Diagrama de Conexión MAX98357A

```
MAX98357A (6 pines)
┌─────────────────────────┐
│ VDD   LCLK   DIN   BCLK  │ ← mirando la cara con la etiqueta
│ GND   SD                 │ ← cara inferior
└─────────────────────────┘

  VDD  → Pin 1/17 (3.3V)     — Alimentación
  GND  → Pin 6/9/14/20/...   — Tierra
  DIN  → Pin 40 (GPIO21)     — Datos reproducción (serial data in)
  BCLK → Pin 12 (GPIO18)     — Reloj I2S (compartido con INMP441)
  LCLK → Pin 35 (GPIO19)     — Word select (compartido con INMP441)
  SD   → Pin 6/9 (GND)       — Shutdown (GND = activo)
```

## Tabla de Conexiones Completa

| RPi Pin | GPIO | Función | INMP441 | MAX98357A |
|---------|------|---------|---------|-----------|
| 1 | — | 3.3V | VDD | VDD |
| 6 | — | GND | GND | GND |
| 9 | — | GND | GND | GND |
| 12 | GPIO18 | BCLK | SCK | BCLK |
| 14 | — | GND | GND | GND |
| 17 | — | 3.3V | VDD | — |
| 20 | — | GND | — | GND |
| 25 | — | GND | GND | GND |
| 30 | — | GND | GND | GND |
| 34 | — | GND | GND | GND |
| 35 | GPIO19 | LRCK | WS | LCLK |
| 38 | GPIO20 | DIN | SD | — |
| 39 | — | GND | GND | GND |
| 40 | GPIO21 | DOUT | L/R | DIN |

## Errores Comunes

| Error | Síntoma | Corrección |
|-------|---------|------------|
| INMP441 SD en GPIO21 | Captura silenciosa | SD → Pin 38 (GPIO20) |
| MAX98357A DIN en GPIO20 | No reproduce | DIN → Pin 40 (GPIO21) |
| INMP441 L/R a 3.3V | Siempre canal derecho | L/R → Pin 40 (GPIO21) |
| MAX98357A SD a 3.3V | Sin audio | SD → GND |
| Sin GND común | Ruido, distorsión | Unir todos los GND |
| VDD en 5V | Daño del micrófono | VDD → 3.3V (Pin 1/17) |

## Consideraciones de Alimentación

- **3.3V**: Ambos funcionan a 3.3V. Usar pines 1 o 17.
- **GND común**: Unir todos los GND (Pi + ambos dispositivos) para evitar ruido.
- **Corriente**: MAX98357A consume hasta 250mA a pleno volumen. INMP441: ~150µA.
- **Fuente de poder**: 2.5A+ para la Raspberry Pi para evitar caídas de voltaje.

## Verificación

Ver [inmp441-wiring.md](inmp441-wiring.md) para verificación de audio y el overlay combinado.
