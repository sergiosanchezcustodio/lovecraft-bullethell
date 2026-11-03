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

## Hito 1.4: 1.000 balas (25-09-2026)

Partida con 1.000 balas enemigas vivas (`bullet_rain=1000`, de los tres tipos), 12 muñecos de práctica, Dyer con dinamita y revólver disparando, y el bot moviéndose. 1920×1080, sin vsync.

| Contenido | Media | 1 % peor | Llamadas de dibujo | Primitivas |
|---|---|---|---|---|
| 1.000 balas + 12 muñecos + armas | 2,07 ms (483 FPS) | 2,78 ms (360 FPS) | 191 | 1,8 M |

- **Coste de las balas:** respecto a la partida sin balas del hito 1.3, cuestan en torno a 0,3 ms. El MultiMesh es una sola llamada de dibujo.
- **Dónde está el coste:** en la simulación en GDScript (integración y colisiones), no en el dibujo.

## Hito 1.5: 150 enemigos reales (25-09-2026)

150 enemigos vivos (pingüinos y fragmentos) con su comportamiento completo: separación, rodeo del decorado, contacto y disparos. Dinamita y revólver a nivel 3, bot en círculos. Opciones: `spawn_rate=40 max_alive=150`. 1920×1080, sin vsync.

| Versión | Media | 1 % peor | Llamadas de dibujo | Primitivas |
|---|---|---|---|---|
| Primera versión | 12,36 ms (81 FPS) | 16,82 ms (59 FPS) | 349 | 4,6 M |
| Con partes, reposo y mallas en caché | 5,89 ms (170 FPS) | 8,33 ms (120 FPS) | 359 | 4,7 M |

- **Qué se optimizó:** buscar las mallas con `find_children` y reasignar el material de destello en cada fotograma, y recalcular las posiciones de reposo, costaban más que todo lo demás. Ahora se guardan al crear el modelo y el material solo se toca cuando cambia.
- **Dónde está el límite:** en la CPU (GDScript), no en la GPU. La prueba de carga completa del hito 1.7 sumará las 1.000 balas.

## Hito 1.6: partida completa (25-09-2026)

Misma prueba que en el hito 1.5 (150 enemigos, dinamita y revólver a nivel 3), ahora con gemas de experiencia, HUD, cordura y subidas de nivel automáticas (`autopick=true`).

| Contenido | Media | 1 % peor | Llamadas de dibujo | Primitivas |
|---|---|---|---|---|
| 150 enemigos + gemas + HUD | 6,08 ms (164 FPS) | 9,09 ms (110 FPS) | 366 | 4,5 M |

Los sistemas nuevos apenas se notan: unos 0,2 ms más que en el hito 1.5.

## Hito 1.7: prueba de carga de la fase 1 (25-09-2026)

Criterio de aceptación de la fase 1: 150 enemigos y 1.000 balas a la vez.

**Comando:**
```
godot --path . --disable-vsync -- bot=circle god=true autopick=true weapons=granada,webly wlevel=3 spawn_rate=40 max_alive=150 final_at=9999 bullet_rain=1000 perf=15 prof=true
```
Añade `--rendering-method gl_compatibility` para medir Compatibility.

**Escena:** 150 enemigos vivos con su comportamiento completo, entre 1.000 y 1.700 balas (la lluvia de prueba mantiene 1.000 y los enemigos disparan las suyas), dinamita y revólver a nivel 3, gemas, HUD y arena completa. 1920×1080.

| Renderizador | Media | 1 % peor | Llamadas de dibujo | Primitivas |
|---|---|---|---|---|
| Forward+ | 7,77 ms (129 FPS) | 11,58 ms (86 FPS) | 328 | 4,7 M |
| Compatibility | 9,26 ms (108 FPS) | 13,33 ms (75 FPS) | 2.339 | 4,2 M |

**Partida normal** (sin trucos de carga, final del nivel: ritmo 3/s, entre 45 y 55 enemigos vivos y unas 300 balas):

| Configuración | Media | 1 % peor |
|---|---|---|
| Con vsync (monitor de 120 Hz) | 8,39 ms (119 FPS, estable) | 9,09 ms (110 FPS) |
| Sin vsync | 2,14 ms (468 FPS) | 2,78 ms (360 FPS) |

**Reparto del tiempo de CPU** en la prueba de carga (`prof=true`, ms por fotograma):

| Sistema | ms |
|---|---|
| Animación de enemigos | 2,1 |
| Lógica de enemigos | 1,2 |
| Balas: buffer del MultiMesh | 0,65 |
| Balas: simulación | 0,4 |
| Rejilla | 0,25 |
| Gemas | 0,01 |

El resto es trabajo del motor: dibujo, transformaciones de unos 1.000 nodos y física de los cuerpos.

**Conclusiones:**
- **Criterio cumplido en este equipo**, con margen: 129 FPS de media y 86 en el 1 % peor en Forward+.
- **El límite es la CPU (GDScript), no la GPU.** Si un procesador de gama media es entre 1,5 y 2 veces más lento, la prueba de carga rondaría entre 65 y 85 FPS de media, con bajadas por debajo de 60 en los picos. La partida normal tiene mucho más margen.
- **Optimizaciones para cuando haga falta**, de menos a más invasiva:
  1. Animar a los enemigos lejanos o fuera de cámara a menor frecuencia.
  2. Animar por MultiMesh por parte del cuerpo (optimización 2 del plan), que ahorra los nodos por enemigo.
  3. Llevar balas y enemigos a C# o GDExtension. **Consultar antes.**
- **Probado y sin efecto:** sustituir `get_node("parte")` por un diccionario de partes (se mantiene porque es más limpio), y quitar el diccionario de repetidos en las consultas de la rejilla.
- **Aún no aplicado:** la optimización 1 del plan, la fusión de caras. Ahorraría triángulos (GPU), y la GPU no es el límite.

## Tras la segunda partida de prueba (25-09-2026)

**Carga de la partida**, desde que empieza la escena hasta el primer fotograma, con iglú, cabaña, tiendas nuevas y precarga de los enemigos del nivel:

| Situación | Carga de la escena | Desde el arranque del motor |
|---|---|---|
| Sin caché de mallas | 4,3-4,5 s | 5,7-6,4 s |
| Con caché (a partir de la segunda vez) | 0,17 s | 1,45 s |

**Prueba de carga** (150 enemigos, unas 1.400 balas) con interpolación de física, gemas con sombra y las piezas nuevas. Tres pasadas:

| Pasada | Media | 1 % peor |
|---|---|---|
| 1 | 8,08 ms (124 FPS) | 14,67 ms (68 FPS) |
| 2 | 7,70 ms (130 FPS) | 13,29 ms (75 FPS) |
| 3 | 8,12 ms (123 FPS) | 14,93 ms (67 FPS) |

- **Media:** igual que antes.
- **1 % peor:** empeora (antes, 86 FPS) por el coste de interpolar unos 150 enemigos, pero sigue por encima de 60 en esta prueba extrema.
- **Suavidad** (`jitter=true`): la variación de la velocidad en pantalla pasa de 1,00 (vibración) a 0,03.

## Cooperativo con 4 jugadores (hito 2.17, 03-10-2026)

Mismo equipo, Forward+, 1920×1080 sin vsync. J1 y 3 bots (`bot=circle bots=3 god=true autopick=true`), con `prof=true`.

| Prueba | Media | 1 % peor | Llamadas de dibujo | Primitivas |
|---|---|---|---|---|
| Carga, 1 jugador (150 enemigos, 1.000 balas) | 11,1 ms (90 FPS) | 18,8 ms (53 FPS) | 606 | 8,1 M |
| Carga, 4 jugadores (150 enemigos, 1.000 balas) | 14,5-15,5 ms (65-69 FPS) | 24-27 ms (37-41 FPS) | 813-863 | 8,6-9,0 M |
| Partida normal del nivel 1, 4 jugadores, 45 s | 8,8 ms (114 FPS) | 12,2 ms (82 FPS) | 539 | 5,6 M |

- Con 4 jugadores, la prueba de carga cuesta unos 4 ms más por fotograma. No hay un sistema culpable: la física de los enemigos sube de 2,0 a 3,2 ms (cada enemigo recorre los jugadores para elegir objetivo y comprobar el contacto) y las balas de 1,1 a 1,9 ms (cuatro jugadores disparando). Jugadores, armas y HUD suman menos de 1 ms. El resto es dibujo: la cámara se abre para que quepan todos y se ven más escenario y más enemigos a la vez.
- La prueba de carga es extrema (150 enemigos y 1.000 balas a la vez). En la partida normal sobra margen. Si en un equipo de gama media la carga con 4 jugadores baja de 60, lo primero sería unir caras en `VoxelBuilder` (8-9 M de primitivas) y rebajar la resolución de la tienda y la cabaña del campamento.
- Nuevas secciones del perfil: `jugadores_fisica`, `jugadores_anim`, `armas`, `hud` y `partida`.

## Fase 16, bloque A: picos y animación (02-11-2026)

*Hitos 16.1, 16.2 y 16.5.* Alta, bot sin daño, 80 enemigos (`max_alive=80 spawn_rate=20`), 20 s medidos tras 2 de calentamiento, sin límite de fotogramas, en el escritorio aparte de Claude Code; tres ejecuciones por nivel y configuración, alternándolas (`spikes=true`). «Antes»: `warmup=false model_pool=false anim_lod=false`.

| Nivel | Media antes → ahora | 1 % peor antes → ahora | Fotogramas de más de 16,7 ms (por 1.000) | Tirones de más de 25 ms (por ejecución) |
|---|---|---|---|---|
| p1_n2 · Campamento de Lake | 8,99 → 8,33 ms | 18,60 → 18,55 ms | 20,6 → 16,1 | 6,7 → 4,7 |
| p2_n4 · Pantanos | 12,32 → 10,29 ms | 23,02 → 19,09 ms | 95,0 → 29,8 | 12,3 → 8,0 |
| p3_n2 · Luisiana | 11,85 → 10,01 ms | 21,71 → 18,69 ms | 53,8 → 20,6 | 10,3 → 6,3 |

- **De dónde salían los picos** (`spikes=true`): (1) la primera aparición de cada enemigo cargaba su malla, compilaba sus shaders (9-11 de una vez) y, al morir el primero, leía su malla de vuelta de la GPU para la paleta de los trozos: tirones de 50-80 ms en la primera oleada; (2) cada aparición costaba ~0,3 ms y cada muerte ~0,6 ms (la mitad, la paleta); (3) un fotograma lento hace que el siguiente lleve dos pasos de física, y la física de los enemigos (~30 µs por enemigo y paso) se duplica.
- **Con 1 enemigo en Luisiana**, 6,96 ms de media y 8,95 de 1 % peor; con 80, 11,6 y 24: los enemigos explican casi toda la diferencia (pose 1,3 ms, resto de su `_process` ~1 ms, física 1,75 ms, y lo que el motor tarda en mover las mallas de sus partes).
- **El 1 % peor sin límite de fotogramas exagera:** a 85-100 fps unos fotogramas llevan 0 pasos de física, otros 1 y otros 2. Con el juego a 60 fps cada uno lleva uno. Medido con `cfg_fps_limit=60` no sirve (el temporizador de Windows hace oscilar los fotogramas alrededor de 16,7 ms); los tirones de más de 25 ms son la mejor señal de lo que se nota jugando.
- **Pose de los enemigos** (Luisiana, `prof=true`): 1,31 → 0,38 ms por fotograma.
- **Coste por llamada** (`Prof` dice ahora llamadas y µs por llamada): aparición 0,32 → 0,21 ms; muerte 0,58-1,26 → 0,26 ms.

## Fase 16: tiempos de carga (hito 16.6, 02-11-2026)

Primera partida tras arrancar el juego, en Alta, desde el relato (`relato level=… relato_go=2 loadtime=true`); «en negro» es desde que el relato pasa hasta que acaba el `_ready` de la partida.

| Nivel | En negro antes → ahora | `_ready` de la partida antes → ahora | Arena (hilo, durante el relato) |
|---|---|---|---|
| p2_n4 · Pantanos | 2.450 → 658 ms | 1.170 → 608 ms | 450-530 ms |
| p3_n2 · Luisiana | 2.147 → 500 ms | 891 → 450 ms | 450-650 ms |

- Antes, en negro: escena de la partida y sus scripts ~1,3 s; arena 0,3-0,45 s (suelo 0,1, costa 0,13, decorado 0,1-0,14); armas, objetos y personajes ~0,15 s; resto ~0,45 s.
- Saltando el relato en seguida (`relato_go=0.05`), la partida espera lo que falte: 0,7-1,6 s en negro, según lo que haya avanzado la carga.

## Fase 16: hordas con instancias (hito 16.3, 02-11-2026)

80 enemigos, calidad Baja, tres ejecuciones (`comparar.py "horde=false" "horde=true" --niveles p1_n2,p2_n4,p3_n2 --veces 3 --perf 20`):

| Nivel | Media (ms) | 1 % peor (ms) | Tirones > 25 ms |
|---|---|---|---|
| p1_n2 · Campamento de Lake | 8,66 → 7,58 | 18,3 → 16,7 | 4,0 → 4,0 |
| p2_n4 · Pantanos | 10,4 → 9,4-9,8 | 18,5-19,2 → 19,2-21,4 | 4 → 7-10 |
| p3_n2 · Luisiana | 11,62 → 9,13 | 22,0 → 18,3 | 11,7 → 6,7 |

- En los pantanos varía mucho entre ejecuciones (una de cinco con la horda dio 14,5 ms de media por un tirón de física de 70 ms en una matanza; otra suelta, 20,3 → 19,2 de 1 % peor).
- Lo que se gana es CPU: `enemigos_anim` de 1,4-1,5 a 0,8-1,1 ms por fotograma, el dibujo en CPU de 1,3 a 1,0-1,1 ms y unos 15 nodos menos por enemigo; la GPU sube 0,1-0,3 ms (las celdas recortan peor en las sombras que cada parte por separado).

## Medición de los 15 niveles

*Última: 03-11-2026, versión 0.9.0 (`python tools/medir_niveles.py`).* Bot sin daño, 80 enemigos como tope y 8 s medidos; la mejor de 2 ejecuciones. Entre paréntesis, la medición anterior (03-11-2026) y la diferencia. Milisegundos por fotograma: menos es mejor. Con 80 enemigos manda la CPU (la lógica de la partida), así que Media y Alta salen parecidas; entre ejecuciones, la media varía en torno a ±1 ms y el 1 % peor bastante más: fíate de las diferencias grandes o de las que se repiten.

| Nivel | Alta: media (antes) | Alta: 1 % peor | Primitivas (Alta) |
|---|---|---|---|
| p1_n1 · Campamento base en la costa del mar de Ross | 7,69 (7,72, −0 %) | 13,41 (14,68, −9 %) | 8,7 M |
| p1_n2 · El campamento destruido de Lake | 7,09 (7,45, −5 %) | 14,32 (18,00, −20 %) | 11,5 M |
| p1_n3 · El paso de la cordillera y sus cavernas | 7,09 (7,79, −9 %) | 15,28 (16,99, −10 %) | 4,9 M |
| p1_n4 · La ciudad ciclópea de los Antiguos | 7,04 (7,70, −9 %) | 14,10 (15,67, −10 %) | 11,9 M |
| p1_n5 · Los túneles y el abismo del mar subterráneo | 7,72 (7,73, −0 %) | 16,50 (17,75, −7 %) | 8,0 M |
| p2_n1 · Newburyport y la carretera a Innsmouth | 7,07 (7,20, −2 %) | 13,74 (18,41, −25 %) | 10,7 M |
| p2_n2 · Las calles de Innsmouth y el templo de la Orden | 7,53 (8,45, −11 %) | 13,04 (16,24, −20 %) | 14,1 M |
| p2_n3 · El hotel Gilman House y la huida por los tejados | 7,86 (7,72, +2 %) | 16,16 (17,43, −7 %) | 9,9 M |
| p2_n4 · Los pantanos y la vía muerta del tren a Rowley | 9,08 (10,86, −16 %) | 15,10 (19,52, −23 %) | 16,5 M |
| p2_n5 · El Arrecife del Diablo y Y'ha-nthlei | 8,09 (9,23, −12 %) | 17,35 (16,89, +3 %) | 14,4 M |
| p3_n1 · Providence: el estudio del escultor Wilcox | 7,03 (7,10, −1 %) | 13,25 (14,31, −7 %) | 13,0 M |
| p3_n2 · Los pantanos de Luisiana: el ritual del culto | 8,02 (10,04, −20 %) | 14,42 (22,97, −37 %) | 15,9 M |
| p3_n3 · Los muelles y la cubierta del Alert | 7,10 (8,39, −15 %) | 12,47 (17,08, −27 %) | 7,8 M |
| p3_n4 · La tormenta en el Pacífico | 7,43 (8,06, −8 %) | 14,32 (18,44, −22 %) | 10,2 M |
| p3_n5 · R'lyeh emergida: la puerta colosal | 7,22 (8,02, −10 %) | 13,85 (17,65, −22 %) | 14,9 M |
