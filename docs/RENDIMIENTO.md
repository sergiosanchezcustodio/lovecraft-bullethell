# Rendimiento

Mediciones del proyecto. La prueba de carga completa (150 enemigos y 1.000 balas) llega en el hito 1.7; aquí se van registrando también las mediciones intermedias.

**Equipo de medición:** Windows 11, NVIDIA GeForce RTX 3070 Ti, Godot 4.4.1. Es un equipo por encima de la "gama media" del objetivo, así que los márgenes cuentan más que las cifras absolutas.

**Comando:**
```
godot --path . scenes/bench.tscn --disable-vsync --resolution 1920x1080 -- count=150 model=acechador secs=8
```
Opciones: `count`, `model` (lista separada por comas), `secs`, `warmup`, `anim=false` y `shot=true` (captura en `shots/bench_<renderizador>.png`). Añade `--rendering-method gl_compatibility` para medir con Compatibility.

## Hito 1.1: 150 Acechadores (24-09-2026)

150 copias del Acechador (18.991 voxels cada una), animadas por partes, a 1920×1080, con luna con sombras y 6 faroles (2 con sombras). Todas en pantalla. Aún no hay balas, escenario ni lógica de juego.

| Renderizador | Media | 1 % peor | GPU | CPU de render | Llamadas de dibujo | Primitivas |
|---|---|---|---|---|---|---|
| Forward+ | 4,47 ms (224 FPS) | 5,32 ms (188 FPS) | 4,37 ms | 1,35 ms | 510 | 10,6 M |
| Forward+ sin animación | 3,79 ms (264 FPS) | 4,34 ms (231 FPS) | 3,73 ms | 0,53 ms | 67 | 8,0 M |
| Compatibility | 8,38 ms (119 FPS) | 12,66 ms (79 FPS) | 6,06 ms | 6,93 ms | 4.379 | 11,6 M |

- **Construcción de la malla del Acechador en GDScript:** unos 200 ms la primera vez. Después queda en caché y las instancias la comparten.
- **Forward+ rinde el doble que Compatibility** con el mismo contenido. Agrupa automáticamente las instancias que comparten malla, y por eso hace muchas menos llamadas de dibujo.
- **El cuello de botella es la GPU, por la cantidad de triángulos:** unos 70.000 por Acechador contando las pasadas de sombra. En una GPU de gama media, varias veces más lenta que esta, los 4,4 ms podrían acercarse al límite de 16,7 ms de los 60 FPS cuando se sumen balas y escenario.
- **La fusión de caras (optimización 1) servirá poco con los modelos actuales:** los generadores añaden un ruido de color distinto a cada voxel, y dos caras vecinas casi nunca comparten color.

## Hito 1.2: horda de pingüinos y fragmentos (24-09-2026)

Misma escena, ahora animada con `Anims.pose(..., "walk", ...)`: 75 pingüinos (8.600 voxels) y 75 fragmentos (9.500 voxels), mezclados.

| Contenido | Media | 1 % peor | GPU | CPU de render | Llamadas de dibujo | Primitivas |
|---|---|---|---|---|---|---|
| 150 pingüinos y fragmentos | 4,43 ms (226 FPS) | 5,57 ms (180 FPS) | 2,26 ms | 1,12 ms | 564 | 4,2 M |
| 150 Acechadores (referencia, con `Anims`) | 4,97 ms (201 FPS) | 7,43 ms (135 FPS) | 4,21 ms | 1,36 ms | 551 | 10,9 M |

- **Las criaturas de horda cuestan la mitad de GPU** que el Acechador: unos 28.000 triángulos cada una contando sombras, frente a 70.000.
- **Con la horda, el límite pasa a la CPU.** La GPU tarda 2,3 ms, pero el fotograma completo tarda 4,4 ms: pesa más animar 150 modelos en GDScript (`Anims.reset` más `pose` en cada fotograma) que dibujarlos. Primer candidato a optimizar en el hito 1.7: guardar en caché las posiciones de reposo y no reponer las partes que la animación no toca.
- **Construcción de mallas:** 83 ms el pingüino y 86 ms el fragmento, una vez por modelo.

## Hito 1.2, segunda versión: caras entre partes y modelos rehechos (25-09-2026)

Cambios que afectan a la medición:
- **Caras entre partes:** `VoxelBuilder` ya no quita todas las caras entre partes distintas, solo las enterradas, para que no queden huecos al girar las extremidades.
  - Quitando **ninguna**, el Acechador subía a 15,6 M de primitivas.
  - Quitando **solo las enterradas**, se queda en 11,0 M.
- **Modelos rehechos:** Dyer y el pingüino son nuevos.

| Contenido | Media | 1 % peor | GPU | Primitivas |
|---|---|---|---|---|
| 150 Acechadores | 5,06 ms (198 FPS) | 7,30 ms (137 FPS) | 4,41 ms | 11,0 M |
| 150 pingüinos y fragmentos | 4,34 ms (231 FPS) | 5,59 ms (179 FPS) | 2,07 ms | 3,6 M |

### Potencial de la fusión de caras según el estilo (25-09-2026)

Estimación con fusión voraz 2D por planos, sin tener en cuenta la oclusión ambiental. Es una cota optimista.

| Modelo | Caras | Con los colores actuales | Sin ruido de color por voxel |
|---|---|---|---|
| Dyer (a bloques) | 4.114 | 3.747 (−9 %) | 1.113 (−73 %) |
| Pingüino | 3.668 | 3.463 (−6 %) | 2.287 (−38 %) |
| Acechador (orgánico) | 10.739 | 10.662 (−1 %) | 8.867 (−17 %) |

- **El estilo a bloques no reduce los triángulos por sí solo:** el primer Dyer y el actual tienen los mismos, unas 4.100 caras.
- **Lo que cambia es que la fusión de caras pasa a merecer la pena.** Dyer usa 248 colores frente a 3.445. Si se suprime el ruido de color por voxel, la fusión quitaría hasta el 73 % de sus caras.
- **En las criaturas orgánicas apenas sirve.**
- **Tiempo de generación:** despreciable en todos los casos. Dyer tarda 0,17 s, el pingüino 0,18 s, el fragmento 0,32 s y el Acechador 0,62 s.

## Hito 1.3: la partida (25-09-2026)

Arena del campamento completa (119 piezas, 8 faroles con luz), Dyer con el bot en círculos y esquivando, y 14 criaturas de muestra animadas. 1920×1080, sin vsync.

| Configuración | Media | 1 % peor | Llamadas de dibujo | Primitivas |
|---|---|---|---|---|
| Con halos de niebla (por defecto) | 1,76 ms (568 FPS) | 2,08 ms (480 FPS) | 193 | 1,7 M |
| Sin halos (`fogvol=false`) | 1,63 ms (612 FPS) | 1,85 ms (540 FPS) | 193 | 1,7 M |
