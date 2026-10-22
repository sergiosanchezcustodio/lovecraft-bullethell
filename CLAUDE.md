# Lovecraft Library: Surviving Cthulhu — documento de arranque

Documento de contexto del proyecto. Recoge las decisiones tomadas en la fase de exploración y el pipeline de arte que ya funciona. Es el punto de partida para cualquier sesión de trabajo (claude.ai o Claude Code).

## Documentación del juego

Léela al empezar cada sesión:
- `docs/PROMPT_juego_lovecraft.md`: especificación original del juego y reglas de trabajo por hitos (plan antes de programar, verificación visual, datos antes que código). No se modifica.
- `docs/GDD.md`: documento de diseño vivo. Recoge la especificación más las decisiones tomadas después (`D-xx`, sección 12). Si discrepa de la especificación, prevalece el GDD.
- `docs/ROADMAP.md`: fases, criterios de aceptación, estado y decisiones que bloquean cada fase.

Consúltalos cuando haga falta (son largos):
- `docs/ESTADO.md`: diario detallado de cada hito y cambio (sistemas, archivos, opciones de prueba, equilibrio, capturas).
- `docs/LECCIONES.md`: lecciones técnicas aprendidas.

## Estado actual (resumen)

*Actualizado: 22-10-2026.* El detalle de cada fase e hito (qué se hizo, archivos, opciones de prueba, equilibrio, rendimiento y capturas) está en **`docs/ESTADO.md`**: búscalo ahí antes de tocar un sistema. Al terminar un cambio, apunta el detalle en `docs/ESTADO.md` y, si cambia el panorama, actualiza este resumen. Las lecciones técnicas están en **`docs/LECCIONES.md`**.

- **Fases 0 y 1:** hechas (falta la partida de 5 minutos del autor).
- **Fase 2 (menús, guardado y cooperativo local, hitos 2.1 a 2.17):** hecha. Falta la prueba del autor con varios mandos para cerrarla.
- **Fase 3 (pipeline de contenido):** hecha (20-10-2026). Evoluciones de las 50 armas, contenido por datos (cómo añadir un enemigo sin tocar código: ver `docs/ESTADO.md`) y generador de escenarios (`tools/arena_kit.py`).
- **Fase 4 (parte 1, Antártida, niveles 1-5 y el shoggoth primigenio):** hecha, falta la partida del autor.
- **Fase 5 (intro, relatos, tienda, Armitage y West):** hecha, pendiente de revisión. 13 personajes, 15 compañeros.
- **Fase 6 (parte 2, Innsmouth, hasta Padre Dagon):** hecha, falta la partida del autor.
- **Fase 7 (parte 3, La llamada de Cthulhu, hasta Cthulhu):** hecha, falta la partida del autor.
- **Fase 8 (pulido y distribución):** en curso. Sonido, música provisional, accesibilidad y builds de Windows y macOS hechas; falta subir a itch.io (necesita la cuenta del autor). 50 armas y 50 objetos (D-38).
- **Trabajo reciente (09-10 a 17-10-2026), pendiente de revisión:** dificultad (Investigador, Normal, Pesadilla) y equilibrio con `SmartBot` y `tools/simular.py`; efectos de armas en cubitos (`VoxelFx`); escenarios rehechos con más resolución (`arte=v1` enseña la versión anterior); ambiente vivo en los 15 escenarios (`data/ambient.json`, `Ambient`); tienda con 15 objetos más; revisión de arte dentro del juego (`review/peticiones.json`, `tools/vigilar_revision.py`).
- **Subidas de nivel por turnos en cooperativo (D-39, 20-10-2026), pendiente de prueba con varios mandos:** experiencia común, sube un jugador cada vez (`TeamXp.turn`), ventana centrada con su color; los bots eligen sin pausar.
- **Sigue aquí (sesión del 20-10-2026):**
  - Equilibrio de D-39 comprobado con 2 y con 4 jugadores (8 partidas por versión): la dificultad no cambia de forma apreciable; el orden de turno deja al último jugador entre medio y un nivel por detrás del J1. Detalle en `docs/ESTADO.md`.
  - Fase 9 (online): D-10 resuelta el 21-10-2026 (GDD, sección 12): anfitrión con autoridad y clientes con ENet, conexión por UPnP, IP o código, mezcla de locales y remotos, una cámara por PC, cada uno con su guardado, pausas como en local, bot si alguien se desconecta. Plan aprobado (hitos 9.1-9.6 en `docs/ROADMAP.md`). **Hitos 9.1 (base de red), 9.2 (sala y selección de personaje en red), 9.3 (partida en red: 9.3a mundo espejo, 9.3b combate, 9.3c efectos, jefes y objetos; 22-10-2026) hechos**, pendientes de la prueba del autor: cada PC manda en sus jugadores y el anfitrión en el mundo (D-10). **Hitos 9.4 (subidas y pausa para todos, flechas, cámara de los eliminados, HUD con el PC y el ping, aviso de conexión) y 9.5 (vuelta al siguiente nivel de un PC que se fue, pantalla final en el invitado si se va el anfitrión, guardado del invitado; 22-10-2026) hechos**, pendientes de la prueba del autor. Lo siguiente es plantear el 9.6 (cierre de la fase).
  - `docs/ROADMAP.md` al día (21-10-2026): fases 6 y 8, hitos 8.10 a 8.16 con el trabajo posterior al plan y criterio de aceptación de la fase 8 (aprobado).

### Reglas que no hay que olvidar

- **Imágenes:** primero ComfyUI en local (`tools/comfyui.cmd`, `python tools/generar_local.py`). Replicate solo con permiso del autor y el coste estimado; tope de 5 predicciones por ejecución (`REPLICATE_MAX`, gasto en `tools/replicate/gasto.log`).
- **Regenerar tras cambios:** si cambia una arena, `gen_arena_<nombre>.py` y `tools/render_mapa.gd`; si cambia un personaje, su generador y después `gen_vestuario.py`; si cambia un arma, `tools/reglas_dano.gd -- aplicar` y `tools/gen_evoluciones.gd`; si cambia la construcción de mallas, sube `VoxelBuilder.BUILDER_VERSION`; si cambian las ilustraciones de la portada, la tienda o el libro, sus scripts de máscaras o de enderezado.
- **Simulaciones:** `--ts 2` y como mucho `--par 2` (con 3 a la vez se acaba la memoria).
- **Rendimiento:** el 1 % peor varía mucho entre ejecuciones y la primera tras regenerar un modelo construye su malla: repite siempre la medición.
- **Shaders:** nada de `fract(sin(x) * 43758)` con argumentos grandes; usa el hash de `night_sky.gdshaderinc`.
- **Bots y capturas:** `mute=true`; las ejecuciones de prueba van en ventana.
- **Autoloads en código de partida:** usa `Auto.sfx_at`, `Auto.sfx`, `Auto.setting` y `Auto.node` (`scripts/core/auto.gd`), no `Sfx.`/`Settings.` directamente: si no, las herramientas con `-s` (mapas de la Biblioteca) no compilan esos scripts.
- **Pantalla completa** exclusiva por defecto; la interfaz escala desde 1920×1080.
- **Luz de las arenas:** las noches se aclaran con `"gamma"` en el `light` de la arena (curva tras el tono, `Atmosphere.set_lift`), no subiendo ambiente o exposición, que el tono ACES aplasta. Apunta a una mediana de brillo de 0,16-0,22 en las noches (detalle en `docs/ESTADO.md`).

## Decisiones cerradas

- **Motor:** Godot 4.4.
- **Género:** bullet hell con disparo automático y progresión tipo "survivors", cooperativo local de 1 a 4 jugadores. Diseño completo en `docs/GDD.md`.
- **Ambientación:** mitos de H. P. Lovecraft. Son de dominio público en España y la UE; solo hay que evitar el nombre comercial "Call of Cthulhu" (marca de Chaosium).
- **Cámara:** ortográfica isométrica fija (rotación -30° en X, 45° en Y).
- **Estilo gráfico:** voxel 3D detallado, "Minecraft mejorado", a 32 voxels por metro de juego (`VOXEL = 0.03125`).
- **Diseño de personajes (humanos: jugables, cultistas, híbridos):** a bloques limpios, con detalles pintados y casi sin relieve (decidido el 25-09-2026 tras rechazar un Dyer esculpido). Las criaturas pueden seguir siendo orgánicas, como el Acechador.
- **Diseño de los profundos:** clásicos, oscuros, sin ropa ni adornos externos (nada de tiaras ni joyas). Solo anatomía: escamas, púas, aletas, agallas, garras. La regla solo afecta a las criaturas: híbridos, cultistas y sacerdotes sí pueden llevar tiaras, joyas y amuletos (confirmado el 21-10-2026).
- **Atmósfera:** oscuridad, luz de luna fría, luz cálida puntual, contraluz verdosa, niebla ligera.

### Estilos probados y descartados
- 3D chibi liso (modelado SDF + marching cubes), tanto en versión simpática como oscura: descartado en favor del voxel.
- Three.js / HTML5: descartado en favor de Godot.

## Pipeline de arte

1. **Generador en Python** (`tools/`): construye el personaje como un conjunto de voxels a partir de primitivas (elipsoides, cápsulas, conos), luego colorea (degradado dorsal/flanco/vientre, escamas, manchas por ruido) y talla detalles sobre la superficie real (boca, dientes, ojos, agallas, cresta). Los generadores nuevos usan **`tools/voxlib.py`**:
   - Clase `Model` con las primitivas (`ell`, `sell`, `capsule`, `cone`, `box`, `line`), búsqueda de superficie por columna (`front`, `top`, `exposed`), ruido y `export`.
   - Se modela en unidades base (1 ub = 1/16 m) y la resolución es el parámetro `S`: 2 voxels por ub = 32 voxels/m.
   - El superelipsoide `sell` (p≈2,5–3) da caras planas para ropa, madera y piedra.
   - `vbox` y `bevel` sirven para diseñar a bloques en coordenadas voxel, como los personajes humanos. Con `export(..., pivots_in_voxels=True)` los pivotes también van en voxels.
   - `export(..., roughness=, specular=)` fija el material del modelo. Sin indicarlos queda piel húmeda (0,38 / 0,6); la ropa, las plumas y el atrezo van mates (~0,9 / 0,25).
2. **Salida JSON** (`models/*.json`): `voxels` = lista de `[x, y, z, parte, r, g, b, glow]`, `pivots` = pivote por parte, en coordenadas voxel, y `voxel_size` (metros por voxel, opcional; por defecto 1/32). Un pivote sin voxels, como `light` en el farol, sirve para marcar puntos.
3. **`scripts/voxel_builder.gd`**: convierte el JSON en mallas con eliminación de caras ocultas y oclusión ambiental por vértice. Crea un nodo por parte con su pivote (`torso`, `head`, `arm_l`, `arm_r`, `leg_l`, `leg_r`) y separa los voxels `glow=1` en una capa sin sombreado (ojos, bioluminiscencia, brillos). Las mallas se construyen una vez por modelo y todas las instancias las comparten; la primera construcción del Acechador tarda unos 200 ms.
   - **Caras ocultas:** solo se quitan las que tapa un voxel de la misma parte. Entre partes distintas se conservan todas: al girar un brazo, una pierna o la cabeza queda al aire lo que tapaban. Antes se quitaban las "enterradas" (dos voxels de otra parte delante), y con el brazo de 5 voxels pegado al tronco el costado se veía hueco al andar.
   - **Material:** sale del `roughness` y el `specular` del JSON.
   - **Caché en disco:** las mallas construidas se guardan en `user://voxcache/` (`VoxelMeshCache`). La clave depende de la fecha y el tamaño del JSON y de `VoxelBuilder.BUILDER_VERSION`. Una cabaña de 100.000 voxels tarda 1,7 s en construirse y unos milisegundos en cargarse de la caché. **Sube `BUILDER_VERSION` si cambias cómo se construyen las mallas.** La partida precarga los modelos de todos los enemigos del nivel al empezar.
4. **Animación:** rotando los nodos-parte desde código (sin rigging).
   - Cada tipo de modelo tiene su script en `scripts/anim/` (`anim_profundo`, `anim_humano`, `anim_pinguino`, `anim_fragmento`), con funciones estáticas por animación y la constante `DURATION`.
   - Se aplican con `Anims.pose(modelo, animación, nodo, t)`, con t de 0 a 1. `Anims.reset()` devuelve todas las partes al reposo, incluida la raíz del modelo.
   - Por eso el giro y la posición de un modelo van siempre en un nodo contenedor, nunca en la raíz.

Entorno de desarrollo (Windows 11 + Git Bash):
- **Godot 4.4.1** en `C:\Tools\Godot\`. El comando `godot` ejecuta `Godot_v4.4.1-stable_win64_console.exe`, para que la salida aparezca en la terminal. En Git Bash lo resuelve el lanzador `~/bin/godot`; en PowerShell y cmd, `C:\Tools\Godot\godot.cmd` (la carpeta está en el PATH de usuario).
- **Python 3.12** como `python`. En Windows, `python3` abre la Microsoft Store en lugar de ejecutar el script.
- No hace falta xvfb: las capturas abren una ventana un momento y se cierran solas.

Uso desde la raíz del proyecto, en Git Bash:
```
./jugar.cmd                         # o doble clic en jugar.cmd: partida sin consola
godot --path .                      # portada (escena principal: scenes/main.tscn, que elige la escena según el primer argumento)
godot --path . -- select saves=demo_saves slot=2 join=2   # selección de personaje con dos jugadores de prueba
godot --path . -- bot=circle dodge_every=2 demo=14 shots=1,3 tag=prueba   # partida con bot, criaturas de muestra y capturas
godot --path . --write-movie shots/videos/mov/f.png --fixed-fps 30 --quit-after 240 -- bot=circle   # vídeo en fotogramas PNG
godot --path . --disable-vsync -- bot=circle demo=14 perf=8                 # rendimiento de la partida
python tools/gen_acechador.py       # regenera models/acechador.json
python tools/gen_variantes.py       # regenera clasico, bruto, acechador (versión simple) y abisal
python tools/gen_dyer.py            # Dyer (personaje jugable); igual gen_pinguino.py y gen_fragmento.py
python tools/gen_olmstead.py        # Olmstead; igual gen_legrasse.py, gen_johansen.py, gen_peaslee.py, gen_varga.py, gen_whipple.py y gen_blake.py (base común en tools/cuerpo.py; tools/humano.py ya no se usa)
python tools/gen_atrezo_campamento.py   # models/atrezo_{tienda,caja,bidon,farol,roca,hielo}.json
godot --headless --path . --import                # reconstruye la caché de .godot/ (primera vez, tras borrarla o al crear un class_name)
godot --path . -- still <yaw> <modelo>            # captura en shots/<modelo>_<yaw>.png (encuadre automático)
godot --path . -- anim <yaw> <modelo> <animación>  # fotogramas en shots/<modelo>_<animación>_NNN.png
godot --path . -- still 0 lineup                  # los cuatro profundos juntos
godot --path . -- still 0 dyer,pinguino,fragmento,acechador   # cualquier grupo, separado por comas
godot --path . -- still 0 lineup fog_density=0.03 moon.light_energy=0.6 tag=prueba   # ajustes de entorno y luces al vuelo
python tools/gen_mascaras_portada.py              # máscaras de la portada y niebla del título
godot --headless --path . -s addons/gut/gut_cmdln.gd                                 # tests (GUT 9.4.0, configuración en .gutconfig.json)
godot --path . scenes/bench.tscn --disable-vsync --resolution 1920x1080 -- count=150 model=acechador   # rendimiento (docs/RENDIMIENTO.md)
```
- **Capturas:** van a `shots/`, que Godot ignora (`.gdignore`) y git también. Caen en la raíz; `python tools/ordenar_shots.py` las reparte en `partida/` y `revision/` por fecha, `modelos/` por grupo, `menus/`, `videos/` y `referencias/` (y corrige las rutas de CLAUDE.md y docs/). Detalle en `shots/LEEME.md`. Añade `--rendering-method gl_compatibility` a cualquier comando para usar el renderizador de reserva.
- **Argumentos:** las escenas leen lo que va detrás de `--` con `LaunchArgs` (`scripts/core/launch_args.gd`): posicionales, `clave=valor` y banderas `--clave`.
- **Opciones de la partida** (`scripts/core/game.gd`):
  - `bot=circle|zigzag|idle` y `dodge_every=` (s): jugador automático.
  - `shots=` y `tag=`: capturas.
  - `cam=`: altura visible en m (por defecto 15).
  - `demo=N`: criaturas de muestra quietas.
  - `pos=x,z`: posición inicial del jugador.
  - `perf=N`: mide el rendimiento N segundos.
  - `fogvol=false`: quita los halos de niebla.
  - `--debug`: imprime la posición del jugador.
  - `dodge=deslizar|rodar|plancha|salto|destello`: estilo de esquive (F1 los recorre en partida).
  - `dummies=N`: muñecos de práctica que reciben daño.
  - `emitters=true`: tres emisores de prueba, uno por tipo de daño.
  - `weapons=dinamita,revolver` y `wlevel=N`: armas iniciales y su nivel.
  - `god=true`: el jugador no recibe daño.
  - `bullet_rain=N`: mantiene N balas enemigas vivas (prueba de carga).
  - `level=p1_n1`: nivel a jugar (por defecto). `nolevel=true` deja el campo de pruebas sin oleadas.
  - `timescale=N`: acelera el juego. Las capturas de `shots=` usan tiempo de juego.
  - `final_at=s`: adelanta el evento final.
  - `max_alive=N` y `spawn_rate=N`: tope de vivos y ritmo de aparición fijo (pruebas de carga).
  - `autopick=true`: elige sola la primera mejora (para bots y capturas).
  - `xp=`, `hp=` y `san=`: experiencia, vida y cordura iniciales.
  - `autorestart=N`: en la pantalla final, reintenta sola tras N s.
  - `log=true`: cada 30 s de juego imprime vivos, abatidos, nivel, vida, cordura y balas; si el enemigo final tarda en morir (más de 30 s), cada 10 s su posición, vida y estado (`final=`).
  - `prof=true` (junto con `perf=`): reparto del tiempo de CPU por sistema (`Prof`).
  - `mute=true`: sin música (también en la portada).
  - `test_save=N`: crea la partida de pruebas (todo desbloqueado) en el hueco N y sale.
  - `saves=carpeta`: otra carpeta de partidas dentro de `user://` (capturas y pruebas sin tocar las tuyas). `slot=N`: juega con ese hueco.
  - `window=true` / `fullscreen=true`: fuerza ventana o pantalla completa.
  - `debug_menu=N`: abre la pausa y el menú de depuración a los N s (capturas).
- **Encadenar comandos:** un `godot ... | grep error` devuelve 1 cuando no hay errores, así que no lo encadenes con `&&`.

Nota: `gen_variantes.py` también escribe un `acechador.json` genérico que sobrescribiría el detallado. Ejecuta `gen_acechador.py` después, o renombra la salida.

## Pantalla de título (`scenes/title.tscn`, `scripts/title/`)

Tus imágenes en `resources/PantallasMenus/`: `fondo_titulo_sin_texto_1080p_definitivo.png` (en realidad a 4K, con mipmaps activados en su `.import`) y `Texto_titulo.png`. `fondo_con_titulo_completo.png` es solo la referencia de composición.

- **Máscaras** (`tools/gen_mascaras_portada.py`: analiza la ilustración en 4K y escribe a 1920×1080; revisión en `shots/revision/2026-09-26/mascaras_revision.png`):
  - `mascara_velas.png`: R, llama de cada vela, cortada en el cuello de la mecha (sin cera); G, fase propia de cada vela, extendida a la zona que ilumina; B, cuánto baila cada punto (0 en la base, 1 en la punta, escalado por el tamaño de la llama; las lejanas y los reflejos no bailan).
  - `mascara_luces.png`: R, cristal de los farolillos; G, su halo; B, luz proyectada por las velas.
  - `mascara_zonas.png`: R, cielo claro del ventanal; G, niebla del suelo; B, cristal del ventanal.
  - `Texto_titulo_niebla.png`: el alfa del título difuminado, con el margen `TITLE_PAD` (0,14, el mismo que en `title_screen.gd`).
  - Los farolillos son una lista de posiciones revisada a mano (`LANTERNS` en el script).
  - **Si cambia la ilustración, vuelve a ejecutar el script y revisa esa lista.** Las posiciones de la luna y los ojos están en la configuración.
- **Capas** (todas en un "escenario" de 1920×1080 que cubre la pantalla conservando la proporción):
  - `background.gdshader`: velas que parpadean con fase propia, llama que baila desde la mecha y luz proyectada que oscila con ella; farolillos que respiran despacio (cristal y halo).
  - `floor_fog.gdshader`: bancos de niebla suaves que aclaran y oscurecen la niebla pintada (mezcla premultiplicada).
  - `window_sky.gdshader`: halo de la luna, relámpago y ojos.
  - Ceniza con tres `GPUParticles2D`: copos lejanos pequeños, medianos y unos pocos cercanos, grandes y desenfocados. Pasa **por delante del título**: va en su propio escenario (`ash_stage`), con el mismo encaje y acercamiento que la ilustración, pero dibujado después del título.
  - El título (`title_halo.gdshader`: niebla con su silueta, letras que se condensan, niebla que se deshace y halo fino) y el aviso van fuera del escenario, así que el acercamiento no les afecta.
- **Configuración por efecto** (`data/title/portada.tres`, `TitleScreenConfig`): cada efecto tiene su interruptor y sus parámetros. Son velas, farolillos, niebla, luna, relámpago, ojos, acercamiento, ceniza, título, halo, niebla del título, aviso y música.
  - Para compararlos sin tocar la configuración: `godot --path . -- title off=niebla,ceniza`. Nombres: velas, farolillos, niebla, luna, relampago, ojos, acercamiento, ceniza, titulo, halo, niebla_titulo, aviso y musica.
  - Otras opciones: `shots=`, `tag=`, `t=` (empezar en ese segundo), `strike=` (relámpago), `eyes=` (brillo de ojos) y `perf=`.
  - Para capturas de los menús, `open=` abre una ventana al terminar la presentación: `slots` (huecos), `slots_borrar` (con la confirmación de borrado), `menu` (menú principal), `menu_jugar` o `menu_config` con `tab=0..3`. Úsalo con `saves=demo_saves`, que tiene una partida de ejemplo en el hueco 2.
- **Controles:** cualquier botón principal (A, B, X, Y, Start, Select; Intro, Espacio o Esc) salta la presentación y, con "Pulsa Start" visible, abre la ventana de huecos. Al elegir hueco se abre el menú principal; "Jugar en local" entra en la partida hasta que exista la selección de personaje (hito 2.3).
- **Variación medida** (desviación típica en % del brillo): llamas 6,4 %, paredes iluminadas 4,4 %, cielo 2,3 %, niebla del suelo 20 % y resto por debajo del 1 %. Sutil a propósito. Coste: 0,42 ms por fotograma.

## Arquitectura del juego

- **Entrada** (`scripts/input/`): los personajes nunca leen `Input`. Cada jugador tiene un `PlayerInput`:
  - `KeyboardInput`, `JoypadInput(dispositivo)` o `BotInput(patrón)`, y `CombinedInput` para unir varias fuentes (J1 = teclado + mando 0).
  - Se leen los dispositivos directamente, sin las acciones globales de Godot, que mezclarían los mandos en local.
  - Las teclas y botones son datos: `InputBindings`, en `data/input/bindings_default.tres`.
- **Interpolación de física** (activada en `project.godot`): la física va a 60 Hz y el dibujo, a la frecuencia del monitor. Reglas:
  - Lo que se mueve en `_physics_process` (jugador, enemigos, dinamita) se interpola solo.
  - Lo que se mueve o se anima en `_process` lleva `physics_interpolation_mode = OFF`. Es el caso de los nodos `Visual` del jugador y de los enemigos, de la cámara, de los muñecos de práctica y del `SubViewport` del retrato.
  - **Un nodo sin interpolación dentro de un cuerpo que se mueve en la física se dibuja en la posición del último paso de física, no en la interpolada.** Por eso el `Visual` del jugador y de los enemigos va con `top_level = true` y en cada `_process` se coloca en `get_global_transform_interpolated()`. Dentro del cuerpo, el modelo avanzaba a saltos de 3 px adelante y atrás a 120 Hz: una vibración que no sale en las capturas.
  - La cámara sigue `get_global_transform_interpolated()`.
  - Balas y gemas (MultiMesh) interpolan a mano entre la posición anterior y la actual con `Engine.get_physics_interpolation_fraction()`.
  - Al aparecer, `reset_physics_interpolation()`.
  - **Todo lo visual debe avanzar con el reloj de fotograma, no con contadores de física:** el esquive usaba `motor.dodge_time` y la pose avanzaba a saltos.
  - Métrica de suavidad: `jitter=true` con `bot=right` o `bot=up`. Sin interpolación daba 1,00; con ella, 0,03. **Ojo: mide la posición interpolada del cuerpo, no lo que se dibuja**, y por eso no detectó la vibración del modelo.
  - Para medir lo que ve el ojo: graba a la frecuencia del monitor (`--write-movie ... --fixed-fps 120 -- bot=right god=true nolevel=true mute=true`) y sigue un color del modelo fotograma a fotograma. Si el desplazamiento alterna de signo (+3, −3…), algo se dibuja a saltos.
- **Animación del jugador:** capas. Una base (reposo, andar o esquive) con fundido de 0,06 a 0,22 s al cambiar (`Anims.snapshot` y `blend_from`), y encima el gesto de lanzar solo en brazos y torso (`Anims.overlay`). La cadencia de andar es proporcional a la velocidad real, para que los pies no patinen. El esquive (su animación sale del `DodgeStyle` del personaje: `slide`, `roll`, `dive`, `jump` o `flash`) es una acción que dura lo que su animación, que puede ser más que el impulso: la voltereta termina de rodar ya a velocidad de andar. El impulso frena progresivamente hasta la velocidad de andar. Para comprobar la fluidez se comparan posiciones reales de puntos del cuerpo, no ángulos, que en una voltereta pasan de +180° a −180°. `tests/test_player_anim.gd` comprueba que ninguna parte salte entre fotogramas.
- **Atributos** (`Attributes`): nombres, fórmulas (`FORMULAS`), escala (`mult`) y subida ponderada (`roll_point`). El jugador guarda `attrs_level1` (fijos) y `attrs` (actuales). Las estadísticas de `Player.data` nunca se tocan a mano: se cambian los atributos, las pasivas o el esquive y se llama a `rebuild_stats()`.
- **Jugador** (`scripts/player/`):
  - `CharacterData` (`.tres` en `data/characters/`) guarda el perfil del personaje.
  - `PlayerMotor` es la lógica pura de movimiento relativo a la cámara y del esquive (impulso, invulnerabilidad y recarga), con tests.
  - `Player` (un `CharacterBody3D`) aplica esa lógica, orienta y anima el modelo, dibuja el anillo de color, lleva un farol propio (`CarryLight`) y muestra su silueta cuando lo tapa el decorado (`occluded_silhouette.gdshader`).
- **Cámara** (`GameCamera`): ortográfica isométrica que sigue a sus objetivos, con 15 m de altura visible por defecto.
- **Combate** (`scripts/core/`, `scripts/bullets/`, `scripts/weapons/`, `scripts/fx/`):
  - `CombatWorld` registra jugadores y enemigos, reconstruye la rejilla espacial (`SpatialGrid`) en cada paso de física y contiene las balas y los efectos.
  - Un objetivo es cualquier nodo con `hit_radius`, `take_damage(Damage)` e `is_alive()`.
  - `Damage` tiene una parte física (resta vida) y otra mental (resta cordura); su tipo se deduce de esas partes.
  - `BulletManager` guarda todas las balas en arrays compactos y las dibuja con dos MultiMesh: las trazadoras del jugador (cuadrados con `bullet.gdshader`) y las enemigas en voxel (`BulletMeshes.orb()`, un núcleo de 19 cubos y un anillo de 14, con `bullet_voxel.gdshader`). El shader enseña unos grupos de cubos u otros según el tipo de daño. Las tapadas se dibujan con la segunda pasada (`bullet_voxel_hidden.gdshader`). Las balas del jugador chocan contra la rejilla de enemigos; las enemigas, contra los jugadores. Cada bala lleva su empuje y los rasgos de daño de quien la dispara.
  - Las armas son datos (`WeaponData`, en `data/weapons/`): cadencia, alcance, apuntado (D-05), entrega y mejoras por nivel (`"damage*": 1.25`, `"count+": 1`). `WeaponSystem`, dentro del jugador, las dispara solas.
    - Entregas: `BULLET` (balas; con `split_count` se abren en chispas y con `jitter_deg` son erráticas), `THROWN` (lanzados en arco, `ThrownExplosive`: explosión, zona o bengala al caer), `MELEE` (tajo del machete, `Slash`), `ORBIT` (páginas que giran alrededor, `OrbitRing`), `BEAM` (rayo recto, `Beam`), `WAVE` (onda que empuja y aturde, `Shockwave`) y `FLAME` (chorro del lanzallamas, `FlameJet`).
    - Zonas en el suelo (`DamageZone`, `WeaponData.zone`): fuego o ácido, con daño por tics. Estados de los enemigos: aturdido (`stun`), vulnerable (`make_vulnerable`, +25 % de daño) y atraído (`lure`, las élites no).
    - Las arcanas cuestan cordura (`sanity_cost`, multiplicado por `CharacterData.arcane_cost_mult`).
  - Los patrones enemigos también son datos (`BulletPattern`, en `data/patterns/`): radial o en abanico, ráfagas, giro y aviso previo. `PatternRunner` los ejecuta.
  - Efectos: `Telegraph` (aviso en el suelo) y `Explosion`.
  - Para pruebas: `TrainingDummy` (objetivo de práctica) y `TestEmitter` (dispara un patrón).
- **Enemigos** (`scripts/enemies/`):
  - `EnemyData` (`.tres` en `data/enemies/`) define cuerpo, contacto, comportamiento con sus parámetros, patrón de ataque y escalón.
  - `Enemy` lo aplica: separación de los demás, rodeo del decorado con `ObstacleMap` (sin cuerpo físico), daño por contacto, disparo, destello, retroceso y muerte con `DeathBurst`.
  - Los comportamientos son clases de `EnemyBehavior`:
    - `CrawlBehavior` (fragmento): persigue a tirones.
    - `BlindBehavior` (pingüino): va hacia donde oyó al jugador y embiste.
    - `StalkBehavior` (Acechador): ronda, salta con aviso y croa.
- **Nivel** (`scripts/level/`):
  - `LevelData` (`.tres` en `data/levels/`) define arena, grupo de enemigos, ritmo de aparición por tiempo, topes y evento final. Pesos 2^(N−t).
  - `WaveDirector` hace aparecer enemigos fuera de cámara, lanza el evento final y emite `level_completed` al morir su enemigo.
- **Progresión** (`scripts/progression/`):
  - `ProgressionData` (`data/progression/default.tres`) define la curva de experiencia y los parámetros de cordura y crisis.
  - `PlayerProgress` lleva nivel, experiencia, subidas pendientes, las tres opciones al azar y su aplicación.
  - Las mejoras pasivas son `UpgradeData` (`data/upgrades/`) y cambian una estadística de la copia del `CharacterData` de cada jugador (`Player.setup` la duplica).
  - `GemManager` gestiona las gemas con arrays y un MultiMesh, como las balas.
- **Cordura** (`SanityState`): recuperación pasiva lejos de enemigos y sin daño mental reciente; crisis a cero; parálisis intermitente que bloquea el `PlayerMotor`; al terminar, recupera el 30 %.
- **Guardado** (`scripts/save/`):
  - `Saves` (autoload) lleva tres huecos en `user://saves/slot_N.json` y la partida en uso (`Saves.current`, un `SaveData`).
  - Guarda en un fichero temporal y lo renombra, para no dejar una partida a medias si el juego se cierra a mitad.
  - `SaveData` tiene número de versión y `migrate()`: si cambias el formato, sube `VERSION` y añade el paso de migración.
  - La partida guarda al caer, al superar el nivel, al reiniciar y al salir. Sin hueco elegido (arrancando la partida directamente) no se guarda nada.
- **Dispositivos y sesión:**
  - `Devices` (autoload en `scripts/input/device_manager.gd`) guarda el último dispositivo usado (`KEYBOARD` = −1, o el número del mando), avisa al conectar o desconectar un mando, crea la entrada de partida de un dispositivo (`make_input`) y define los colores de los jugadores (`COLORS`).
  - `GameSession` (estático, en `scripts/core/game_session.gd`) lleva de los menús a la partida quién juega (dispositivo, GUID, personaje y compañero) y en qué nivel. Vacía, la partida usa sus opciones de siempre.
- **Selección de personaje** (`scenes/select.tscn`, `scripts/menus/character_select.gd`):
  - La lógica está en `SelectState` (sin dibujo, con tests).
  - La entrada se lee por dispositivo en `_input`, sin el foco de Godot, que es uno para toda la pantalla.
  - El mapa de niveles es `LevelMap`, sobre `Campaign` (`data/campaign.json`).
  - Cada jugador gira su modelo con LB/RB (Q/E con el teclado) mientras los mantiene, para verlo de lado y de espaldas; al cambiar de personaje vuelve a mirar al frente. Los compañeros girarán igual cuando tengan modelo.
  - Opciones para capturas: `join=N` (jugadores de prueba), `ready=N`, `turn=grados`, `map=true` y `auto_start=true`.
- **Configuración** (`Settings`, autoload en `scripts/save/settings.gd`): común a los tres huecos, en `user://settings.json`.
  - Aplica vídeo y audio (crea los buses `Musica` y `Efectos`).
  - `Settings.bindings()` da los controles de fábrica más los reasignados; la partida los usa para el teclado y los mandos.
  - `dev_window` (ejecuciones de prueba en ventana) y `force_fullscreen` los pone `main.gd` y no se guardan.
- **Menús de fuera de la partida** (`scripts/menus/`):
  - `MenuKit`: fuente de la portada, ventanas centradas y `Confirm`, para confirmar con el foco en "no".
  - `SlotMenu` (huecos), `MainMenu` (menú principal y ventana de Jugar) y `SettingsMenu` (pestañas).
  - `OptionRow` (`scripts/ui/`): fila con valor que se cambia con izquierda/derecha. La usan la configuración y la depuración.
  - La portada (`TitleScreen`) lleva el flujo: presentación, huecos y menú principal. `TitleScreen.skip_to_menu` hace que, al volver de la partida, entre directamente en el menú.
- **Red** (`scripts/net/`, fase 9): `NetSession` (autoload `Net`) lleva la sala con ENet: anfitrión con autoridad, hasta 3 clientes, mensajes de bytes propios (`Net.send`, tipos desde `NetSession.USER`; sube `PROTOCOL` al cambiar cualquiera), lista de conectados con ping. `RoomCode` pasa IP y puerto a un código de 8 letras; `UpnpHelper` abre el puerto en el router. Menú en `scripts/menus/online_menu.gd` (con `RoomCodePicker` para el mando). La sala es la selección de personaje: `NetSelect` reparte el `SelectState` del anfitrión (perfil de desbloqueos por PC, `Seat.peer`) y START llena `GameSession` en cada PC (`peer`, `name`, `worn`, `my_peer`). En partida, `NetGame`: cada PC manda en sus jugadores (`Player.remote` para los de otros PC) y el anfitrión manda fotos del mundo a 20 Hz; en los invitados los enemigos son marionetas (`Enemy.puppet`) y el director es un espejo (`WaveDirector.mirror`); lo que llega se interpola 100 ms en el pasado (`NetInterp`). Las balas enemigas viajan al nacer y cada PC decide los golpes a sus jugadores (también el contacto de las marionetas); las gemas llevan id y semilla, y la experiencia y el progreso los reparte el anfitrión (`NetGame.apply_progress`); cada jugador usa la tienda de su PC (`Profile.shop`). Lo que hacen los enemigos (golpes en un círculo, sonidos, salpicaduras, temblores, gritos) pasa por `CombatWorld.strike`/`sfx`/`splash`… y sus avisos se crean con `Telegraph.enemy`: así se repiten en los invitados. Rompibles, recompensas, baúles y peligros también viajan (`mirror` en el invitado). `start_level=` empieza otro nivel desde la selección. Un PC que se va puede volver con la partida empezada (`NetSession.admit`, `GameSession.claim`): espera en la selección y entra al pasar de nivel con su progreso; si el anfitrión se va, el invitado ve la pantalla final (`game.net_closed`). Las subidas por turnos y la pausa paran la partida en todos los PC (`NetGame.halt_all`/`resume_all`): quien sube elige en su PC (PICK, `PlayerProgress.option_for`) y la pausa la pide cualquiera; si quien sube tarda, el anfitrión puede elegir por él; pruebas con `bots_pause=true`, `pick_after=`, `pause_at=t,dur`, `halt_shots=true`, `afk_pick=` y `afk_press=true`. Flechas hacia los de otros PC que no se ven (`OffscreenArrows`), PC y ping en sus paneles (`Hud.net_info`) y «Sin noticias del anfitrión…» tras 2 s sin fotos (y a los 10 s, botón de salir); pruebas con `snap_gap=t,dur` y `down_at=t`. Pruebas con dos ventanas: `select net_host=true net_upnp=false net_name=A` y `select net_join=127.0.0.1 net_name=B` (con `acts=`, `auto_start=true`, `net_wait=1`, `skip_relato=true`, `bot=smart`, `log=true` y `game_shots=`); `net_lag=` y `net_loss=` simulan latencia y pérdida.
- **Música** (`Music`, autoload en `scripts/core/music.gd`): sobrevive a los cambios de escena, funde una pista con la siguiente y no corta la que ya suena si se vuelve a pedir (al reiniciar). `mute=true` la silencia; úsalo en bots y capturas.
- **Depuración** (`DebugOptions` en `scripts/core/debug_options.gd`, `DebugMenu` en `scripts/ui/debug_menu.gd`): los ajustes van en una variable estática, así que sobreviven a `reload_current_scene`; `game.gd` los aplica al montar la partida (`DebugOptions.apply_all`).
  - Las pasivas se rehacen desde el personaje original (`rebuild_stats`), así que también se pueden bajar.
  - El director tiene `target_alive`, `spawning_paused`, `pool_override` y `trigger_final()`.
  - Las listas (personajes, esquives, armas, enemigos) se leen de sus carpetas en `data/`: lo nuevo aparece solo.
- **Interfaz** (`scripts/ui/`):
  - `UiKit`: estilo común y barras con estela.
  - `Hud`: panel del J1 y cabecera. El retrato sale de un `SubViewport` que renderiza la cabeza del modelo.
  - `Menus`: subida de nivel, pausa y pantalla final.
  - `pause_watch.gd` atiende Esc o Start también con la partida en pausa.
- **Arena** (`scripts/level/arena_builder.gd`):
  - Borde de la arena: nunca vacío. En el campamento, la Barrera de Ross al norte y al oeste (`tools/gen_barrera_hielo.py`: tres tramos de acantilado de hielo repetidos y solapados, con una meseta nevada detrás) y el mar al sur y al este (`sea.gdshader`: agua en baldosas de 0,5 m con oleaje, destellos de luna y espuma). Lo que queda más allá de la orilla flota a la altura del agua. Cada nivel usará bordes de su temática (muros, acantilados, agua).
  - Monta un JSON de `data/arenas/` (generado por `tools/gen_arena_campamento.py`) con el suelo de nieve, el mar, las piezas con su colisión, una luz y un halo de niebla por farol, y los límites invisibles.
  - Capa 1: mundo. Capa 2: jugadores.

## Personajes jugables modelados

| Personaje | Estado | Concepto |
|---|---|---|
| **Robert Olmstead** | Hito 2.4 (`gen_olmstead.py`), 7.100 voxels | Joven viajero: gorra de plato de tweed, chaqueta de tweed gris verdoso, chaleco, camisa blanca y corbata azul, pantalón pardo y un revólver en la cadera. Revólver, voltereta larga, resistencia a las criaturas marinas. |
| **John R. Legrasse** | Hito 2.4 (`gen_legrasse.py`), 7.600 voxels | Inspector: fedora gris marengo de ala ancha, gabardina corta gris piedra abierta sobre traje azul marino, placa dorada y bigote. Escopeta, salto, más daño a los humanos. |
| **Gustaf Johansen** | Hito 2.4 (`gen_johansen.py`), 7.800 voxels | Marinero corpulento (torso más ancho): gorro de lana gris, barba dorada, chaquetón cruzado azul marino con botones de latón y jersey crema de cuello vuelto. Machete, plancha, mucha vida. |
| **Amelia Peaslee** | Hito 2.4b (`gen_peaslee.py`), 6.500 voxels | Arqueóloga: salacot claro, coleta cobriza, camisa caqui remangada, correa cruzada con cartera de cuero, pantalón de montar y botas altas. Rifle de caza, voltereta, suerte y recogida. |
| **Madame Ludmila Varga** | Hito 2.4b (`gen_varga.py`), 9.300 voxels | Médium de salón: vestido largo de terciopelo negro, estola ciruela con flecos, collar de perlas, media melena negra y diadema con pluma violeta. Necronomicón, destello, arcanas a mitad de cordura. |
| **Dra. Marian Whipple** | Hito 2.4b (`gen_whipple.py`), 8.000 voxels | Bata blanca larga abierta sobre vestido gris, estetoscopio, gafas de montura clara y moño castaño. Bisturís, salto, curación al subir de nivel. |
| **Henrietta Blake** | Hito 2.4b (`gen_blake.py`), 8.100 voxels | Escritora: cloché verde azulado, media melena rubia, abrigo burdeos con bufanda crema y pluma en el bolsillo. Trapezoedro, deslizamiento, más experiencia. |
| **Padre Iwanicki** | Hito 2.4b (`gen_iwanicki.py`), 9.200 voxels | Sotana negra hasta los tobillos con botonadura, alzacuellos, crucifijo de plata, fajín morado y pelo gris. Fórmula de expulsión, voltereta, aura que calma. |
| **Sargento Frank Elwood** | Hito 2.4b (`gen_elwood.py`), 7.500 voxels | Veterano corpulento: casco Brodie, guerrera oliva con correajes y cartucheras, polainas y bigote de cepillo. Colt .45, plancha, aguante físico. |
| **Vera Malone** | Hito 2.4b (`gen_malone.py`), 6.800 voxels | Traje cruzado gris a rayas diplomáticas, corbata granate, clavel, fedora granate y media melena negra. Thompson, deslizamiento, daño a quemarropa. |
| **William Dyer** | Hito 1.2, segunda versión (`gen_dyer.py`), 7.600 voxels, 1,72 m | Diseño a bloques limpios con los detalles pintados. Gorro de trampero de cuero con banda de borreguillo, cara plana con ojos, cejas, barba y bigote, pelo en la nuca, bufanda roja, parka de lona con bolsillos, botones y ribete de borreguillo, cinturón con tres cartuchos de dinamita (único relieve), manoplas, pantalón de lana y botas. Material mate. Animaciones: reposo, andar, esquive y lanzar. |

## Bestiario actual

| Enemigo | Estado | Concepto |
|---|---|---|
| **Pingüino albino ciego** | Hito 1.2, segunda versión (`gen_pinguino.py`), 8.100 voxels | Silueta de pingüino emperador de 1,5 m: cuerpo de torpedo con sección casi plana, cabeza adelantada y pico largo. Dibujo de frac en tonos de albino: gris frío pálido en espalda, cabeza y aletas, pecho blanco, manchas de las orejas amarillo claro y ojos lechosos. Patas rosadas. Material mate. Animaciones: reposo (escucha), andar bamboleándose y carga con picotazo. |
| **Fragmento protoplásmico** | Hito 1.2 (`gen_fragmento.py`), 9.500 voxels | Masa negra iridiscente con brillos verdes y violetas, seis ojos verdosos brillantes, boca que silba y dos pseudópodos. Partes: `body`, `top`, `pod_l`, `pod_r`. Animaciones: reposo, reptar y ráfaga. |
| **Acechador** | Elegido y detallado (`gen_acechador.py`) | Agazapado como rana, manos apoyadas delante, ojos enormes arriba con pupila de rendija, colmillos entrelazados, cresta de púas color hueso con membrana, agallas en volante. Animaciones de acecho y salto. |
| Clásico | Prototipo | Hombre-pez escuálido y encorvado, ojos amarillentos laterales, púas dorsales. |
| Bruto | Prototipo | Masivo, mandíbula enorme con boca caída, ojos pequeños bajo el ceño, verrugas. Candidato a tanque o mini-jefe. |
| Abisal | Prototipo | Negro azulado, ojos cian brillantes, líneas bioluminiscentes, dientes largos. |

## Lecciones técnicas aprendidas

En `docs/LECCIONES.md` (orden de vértices, caché de clases, colores sRGB, interpolación de física, packed arrays, shaders, partículas, foco del mando, referencias circulares…). Léelas antes de tocar esos temas y añade allí las nuevas.

## Por definir

Las decisiones abiertas están en `docs/GDD.md` (sección 12), con la fase a la que bloquea cada una. Música y sonido solo tienen pautas sueltas (el susurro de los ataques mentales); el audio llega en la fase 8.
