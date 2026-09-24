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
