# Lovecraft Library: Surviving Cthulhu — documento de arranque

Documento de contexto del proyecto. Recoge las decisiones tomadas en la fase de exploración y el pipeline de arte que ya funciona. Es el punto de partida para cualquier sesión de trabajo (claude.ai o Claude Code).

## Documentación del juego

Léela al empezar cada sesión:
- `docs/PROMPT_juego_lovecraft.md`: especificación original del juego y reglas de trabajo por hitos (plan antes de programar, verificación visual, datos antes que código). No se modifica.
- `docs/GDD.md`: documento de diseño vivo. Recoge la especificación más las decisiones tomadas después (`D-xx`, sección 12). Si discrepa de la especificación, prevalece el GDD.
- `docs/ROADMAP.md`: fases, criterios de aceptación, estado y decisiones que bloquean cada fase.

## Estado actual

*Actualizado: 24-09-2026.*

- **Fase 0: hecha.** GDD, hoja de ruta y las nueve decisiones que bloqueaban las fases 1 y 2.
- **Fase 1: en curso**, con el plan aprobado (subhitos en `docs/ROADMAP.md`).
  - **Hito 1.1 (base técnica): hecho y aprobado.** Forward+ con el entorno recalibrado, GUT 9.4.0, caché de mallas, capturas por tiempo (`ShotTaker`) y escena de rendimiento (`scenes/bench.tscn`, medición en `docs/RENDIMIENTO.md`).
  - **Hito 1.2 (modelos nuevos): segunda versión, pendiente de revisión.** Dyer, pingüino albino ciego, fragmento protoplásmico y atrezo del campamento, con sus animaciones en `scripts/anim/`.
    - Rechazados en la primera revisión: Dyer ("ni siquiera parece una persona": demasiado relieve y cara horrible) y el pingüino ("no parece un pingüino"). Rehechos con el enfoque de las lecciones "Personajes humanos" e "Identidad de un animal".
    - Hojas de revisión en `shots/revision_1_2_modelos_v2.png` y `shots/revision_1_2_animaciones_v2.png`, y GIF en `shots/anim_*_v2.gif` (se regeneran; `shots/` no va a git).
  - **Hito 1.3 (jugador, entrada, cámara y arena): hecho.** Ya se puede jugar a moverse y esquivar por el campamento con `godot --path .`: teclado (WASD o flechas, espacio para esquivar) o mando (stick izquierdo o cruceta, A para esquivar). Todavía no hay enemigos activos, disparos ni menús; para salir, cierra la ventana.
  - **Hito 1.4 (balas, daño y armas): hecho.** Balas en arrays con un único MultiMesh, lenguaje visual de los tres tipos de daño, revólver y dinamita con apuntado por datos, patrones de disparo enemigos como datos, avisos en el suelo, explosiones y muñecos de práctica. Clip en `shots/combate_1_4.gif`.
  - **Hito 1.5 (enemigos y nivel): hecho.** `godot --path .` ya juega el nivel 1 de la parte 1:
    - Oleadas de pingüinos y fragmentos que aparecen fuera de cámara, persiguen y disparan.
    - En el minuto 4, el Acechador como evento final: ronda, salta con aviso y croa.
    - El nivel se supera al matarlo.
    - Clip en `shots/evento_final_1_5.gif`.
  - **Hito 1.6 (progresión, cordura y HUD): hecho.** La partida ya es completa:
    - Gemas de experiencia que se recogen al acercarse, subida de nivel con elección de 1 entre 3 mejoras (la partida se pausa) y cinco pasivas.
    - Cordura con recuperación pasiva y crisis de parálisis intermitente.
    - HUD del J1 con retrato, vida, cordura, experiencia, armas y recarga del esquive, más reloj y objetivo arriba.
    - Pausa con Esc o Start, pantalla de caída y de nivel superado, y reinicio.
  - **Hito 1.7 (rendimiento y cierre): prueba de carga hecha, pendiente de que juegues tú.**
    - 150 enemigos y más de 1.000 balas a 129 FPS de media en Forward+ (86 en el 1 % peor) y a 108 en Compatibility (`docs/RENDIMIENTO.md`).
    - Ritmo ajustado con un bot: el nivel se supera en unos 5,5 minutos.
    - **Falta el criterio de aceptación de la fase 1:** que juegues tú una partida de 5 minutos, con doble clic en `jugar.cmd` o con `godot --path .`.
    - **Primera partida de prueba (25-09-2026), cambios aplicados:**
      - Silueta sin brazos vistos a través del cuerpo.
      - Suelo de nieve blanca.
      - Pingüinos un 20 % más pequeños y solo cuerpo a cuerpo.
      - Menús con A en el mando.
      - Muchos menos enemigos al principio.
      - Disparo continuo, con el revólver desde el inicio.
    - **Segunda partida de prueba, cambios aplicados:**
      - Sin vibración al moverse (interpolación de física).
      - Lanzar dinamita ya no congela las piernas (animación por capas).
      - Esquive nuevo: deslizamiento sobre la nieve, con fundidos y frenado suave.
      - Gemas doradas talladas.
      - Tiendas verdes grisáceas de cumbrera.
      - Iglú, cabaña de troncos y bloques de hielo en el campamento.
      - Carga de la partida en 0,17 s gracias a la caché de mallas.
    - **Cinco estilos de esquive**, uno por personaje: deslizamiento, voltereta, plancha de pingüino, salto y destello, con datos en `data/dodges/` (`DodgeStyle`). F1 los recorre en partida y `dodge=<id>` elige uno al arrancar. Pendiente de decidir cuál lleva cada personaje.
- **Todavía no hay código de juego:** solo el visor, la escena de rendimiento y los generadores de modelos.
- **Decidido el 25-09-2026 para la fase 5:**
  - Estructura de menús, tienda con progresión permanente y compañeros al estilo de Extremadura Survivors (D-09, D-20; GDD 8.1).
  - Portada animada en Godot (D-21; GDD 7.1).
  - Orden: cerrar la fase 1 con tu partida, después el cooperativo (fase 2) y luego la fase 5.
- **Pantalla de título (adelantada de la fase 5): hecha, pendiente de tu revisión.**
  - Es tu ilustración de la biblioteca, animada en 2D, con tu imagen del título encima.
  - Se abre con `godot --path .` sin argumentos o con `-- title`; hay vídeo en `shots/portada_2d.mp4`.
  - La portada 3D anterior (montañas y título voxel) se quitó; queda en el historial de git (commit `4809adb`).
- **Pendiente de confirmar:** si la regla "sin tiaras ni joyas" de los Profundos se limita a las criaturas (GDD, sección 13, punto 5).

## Decisiones cerradas

- **Motor:** Godot 4.4.
- **Género:** bullet hell con disparo automático y progresión tipo "survivors", cooperativo local de 1 a 4 jugadores. Diseño completo en `docs/GDD.md`.
- **Ambientación:** mitos de H. P. Lovecraft. Son de dominio público en España y la UE; solo hay que evitar el nombre comercial "Call of Cthulhu" (marca de Chaosium).
- **Cámara:** ortográfica isométrica fija (rotación -30° en X, 45° en Y).
- **Estilo gráfico:** voxel 3D detallado, "Minecraft mejorado", a 32 voxels por metro de juego (`VOXEL = 0.03125`).
- **Diseño de personajes (humanos: jugables, cultistas, híbridos):** a bloques limpios, con detalles pintados y casi sin relieve (decidido el 25-09-2026 tras rechazar un Dyer esculpido). Las criaturas pueden seguir siendo orgánicas, como el Acechador.
- **Diseño de los profundos:** clásicos, oscuros, sin ropa ni adornos externos (nada de tiaras ni joyas). Solo anatomía: escamas, púas, aletas, agallas, garras.
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
   - **Caras ocultas:** dentro de una misma parte se quitan todas. Entre partes distintas, solo las enterradas, con dos voxels ocupados por delante. Así las costuras de brazos y piernas no dejan huecos al girar.
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
godot --path .                      # partida (escena principal: scenes/main.tscn, que elige la escena según el primer argumento)
godot --path . -- bot=circle dodge_every=2 demo=14 shots=1,3 tag=prueba   # partida con bot, criaturas de muestra y capturas
godot --path . --write-movie shots/mov/f.png --fixed-fps 30 --quit-after 240 -- bot=circle   # vídeo en fotogramas PNG
godot --path . --disable-vsync -- bot=circle demo=14 perf=8                 # rendimiento de la partida
python tools/gen_acechador.py       # regenera models/acechador.json
python tools/gen_variantes.py       # regenera clasico, bruto, acechador (versión simple) y abisal
python tools/gen_dyer.py            # Dyer (personaje jugable); igual gen_pinguino.py y gen_fragmento.py
python tools/gen_atrezo_campamento.py   # models/atrezo_{tienda,caja,bidon,farol,roca,hielo}.json
godot --headless --path . --import                # reconstruye la caché de .godot/ (primera vez, tras borrarla o al crear un class_name)
godot --path . -- still <yaw> <modelo>            # captura en shots/<modelo>_<yaw>.png (encuadre automático)
godot --path . -- anim <yaw> <modelo> <animación>  # fotogramas en shots/<modelo>_<animación>_NNN.png
godot --path . -- still 0 lineup                  # los cuatro profundos juntos
godot --path . -- still 0 dyer,pinguino,fragmento,acechador   # cualquier grupo, separado por comas
godot --path . -- still 0 lineup fog_density=0.03 moon.light_energy=0.6 tag=prueba   # ajustes de entorno y luces al vuelo
godot --headless --path . -s addons/gut/gut_cmdln.gd                                 # tests (GUT 9.4.0, configuración en .gutconfig.json)
godot --path . scenes/bench.tscn --disable-vsync --resolution 1920x1080 -- count=150 model=acechador   # rendimiento (docs/RENDIMIENTO.md)
```
- **Capturas:** van a `shots/`, que Godot ignora (`.gdignore`) y git también. Añade `--rendering-method gl_compatibility` a cualquier comando para usar el renderizador de reserva.
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
  - `log=true`: cada 30 s de juego imprime vivos, abatidos, nivel, vida, cordura y balas.
  - `prof=true` (junto con `perf=`): reparto del tiempo de CPU por sistema (`Prof`).
- **Encadenar comandos:** un `godot ... | grep error` devuelve 1 cuando no hay errores, así que no lo encadenes con `&&`.

Nota: `gen_variantes.py` también escribe un `acechador.json` genérico que sobrescribiría el detallado. Ejecuta `gen_acechador.py` después, o renombra la salida.

## Pantalla de título (`scenes/title.tscn`, `scripts/title/`)

Tus imágenes en `resources/PantallasMenus/`: `fondo_titulo_sin_texto_1080p_definitivo.png` (en realidad a 4K, con mipmaps activados en su `.import`) y `Texto_titulo.png`. `fondo_con_titulo_completo.png` es solo la referencia de composición.

- **Máscaras** (`tools/gen_mascaras_portada.py`, a 1920×1080; revisión en `shots/mascaras_revision.png`):
  - `mascara_luces.png`: R, núcleo de cada llama (207 detectadas; los reflejos del suelo, a media intensidad); G, fase propia de cada llama, extendida a la zona que ilumina; B, luz proyectada.
  - `mascara_zonas.png`: R, cielo con nubes (sin la tracería ni Cthulhu); G, niebla del suelo; B, cristal del ventanal.
  - **Si cambia la ilustración, vuelve a ejecutar el script.** Las posiciones de la luna y los ojos están en la configuración.
- **Capas** (todas en un "escenario" de 1920×1080 que cubre la pantalla conservando la proporción):
  - `background.gdshader`: velas que parpadean con fase propia, bailoteo de la llama y luz proyectada que oscila con ella.
  - `floor_fog.gdshader`: jirones de niebla.
  - `window_sky.gdshader`: nubes, halo de la luna, relámpago y ojos.
  - Motas de polvo con `GPUParticles2D`.
  - El título (`title_halo.gdshader`, con halo de niebla y entrada en dos tiempos) y el aviso van fuera del escenario, así que el acercamiento no les afecta.
- **Configuración por efecto** (`data/title/portada.tres`, `TitleScreenConfig`): cada efecto tiene su interruptor y sus parámetros. Son velas, niebla, nubes, luna, relámpago, ojos, acercamiento, motas, título, halo y aviso.
  - Para compararlos sin tocar la configuración: `godot --path . -- title off=niebla,motas`.
  - Otras opciones: `shots=`, `tag=`, `t=` (empezar en ese segundo), `strike=` (relámpago), `eyes=` (brillo de ojos) y `perf=`.
- **Controles:** Intro, Espacio, A o Start saltan la presentación. Con el aviso visible, entran en la partida hasta que existan los menús.
- **Variación medida** (desviación típica en % del brillo): llamas 6,4 %, paredes iluminadas 4,4 %, cielo 2,3 %, niebla 1-2 % y resto por debajo del 1 %. Sutil a propósito. Coste: menos de 1 ms por fotograma.

## Arquitectura del juego

- **Entrada** (`scripts/input/`): los personajes nunca leen `Input`. Cada jugador tiene un `PlayerInput`:
  - `KeyboardInput`, `JoypadInput(dispositivo)` o `BotInput(patrón)`, y `CombinedInput` para unir varias fuentes (J1 = teclado + mando 0).
  - Se leen los dispositivos directamente, sin las acciones globales de Godot, que mezclarían los mandos en local.
  - Las teclas y botones son datos: `InputBindings`, en `data/input/bindings_default.tres`.
- **Interpolación de física** (activada en `project.godot`): la física va a 60 Hz y el dibujo, a la frecuencia del monitor. Reglas:
  - Lo que se mueve en `_physics_process` (jugador, enemigos, dinamita) se interpola solo.
  - Lo que se mueve o se anima en `_process` lleva `physics_interpolation_mode = OFF`. Es el caso de los nodos `Visual` del jugador y de los enemigos, de la cámara, de los muñecos de práctica y del `SubViewport` del retrato.
  - La cámara sigue `get_global_transform_interpolated()`.
  - Balas y gemas (MultiMesh) interpolan a mano entre la posición anterior y la actual con `Engine.get_physics_interpolation_fraction()`.
  - Al aparecer, `reset_physics_interpolation()`.
  - **Todo lo visual debe avanzar con el reloj de fotograma, no con contadores de física:** el esquive usaba `motor.dodge_time` y la pose avanzaba a saltos.
  - Métrica de suavidad: `jitter=true` con `bot=right` o `bot=up`. Sin interpolación daba 1,00; con ella, 0,03.
- **Animación del jugador:** capas. Una base (reposo, andar o esquive) con fundido de 0,06 a 0,22 s al cambiar (`Anims.snapshot` y `blend_from`), y encima el gesto de lanzar solo en brazos y torso (`Anims.overlay`). La cadencia de andar es proporcional a la velocidad real, para que los pies no patinen. El esquive (su animación sale del `DodgeStyle` del personaje: `slide`, `roll`, `dive`, `jump` o `flash`) es una acción que dura lo que su animación, que puede ser más que el impulso: la voltereta termina de rodar ya a velocidad de andar. El impulso frena progresivamente hasta la velocidad de andar. Para comprobar la fluidez se comparan posiciones reales de puntos del cuerpo, no ángulos, que en una voltereta pasan de +180° a −180°. `tests/test_player_anim.gd` comprueba que ninguna parte salte entre fotogramas.
- **Jugador** (`scripts/player/`):
  - `CharacterData` (`.tres` en `data/characters/`) guarda el perfil del personaje.
  - `PlayerMotor` es la lógica pura de movimiento relativo a la cámara y del esquive (impulso, invulnerabilidad y recarga), con tests.
  - `Player` (un `CharacterBody3D`) aplica esa lógica, orienta y anima el modelo, dibuja el anillo de color, lleva un farol propio (`CarryLight`) y muestra su silueta cuando lo tapa el decorado (`occluded_silhouette.gdshader`).
- **Cámara** (`GameCamera`): ortográfica isométrica que sigue a sus objetivos, con 15 m de altura visible por defecto.
- **Combate** (`scripts/core/`, `scripts/bullets/`, `scripts/weapons/`, `scripts/fx/`):
  - `CombatWorld` registra jugadores y enemigos, reconstruye la rejilla espacial (`SpatialGrid`) en cada paso de física y contiene las balas y los efectos.
  - Un objetivo es cualquier nodo con `hit_radius`, `take_damage(Damage)` e `is_alive()`.
  - `Damage` tiene una parte física (resta vida) y otra mental (resta cordura); su tipo se deduce de esas partes.
  - `BulletManager` guarda todas las balas en arrays compactos y las dibuja con un único MultiMesh. Las balas del jugador chocan contra la rejilla de enemigos; las enemigas, contra los jugadores. El estilo visual sale del tipo de daño (`bullet.gdshader`).
  - Las armas son datos (`WeaponData`, en `data/weapons/`): cadencia, alcance, apuntado (D-05), entrega (bala o lanzado) y mejoras por nivel (`"damage*": 1.25`, `"count+": 1`). `WeaponSystem`, dentro del jugador, las dispara solas. La dinamita es un `ThrownExplosive`.
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
- **Interfaz** (`scripts/ui/`):
  - `UiKit`: estilo común y barras con estela.
  - `Hud`: panel del J1 y cabecera. El retrato sale de un `SubViewport` que renderiza la cabeza del modelo.
  - `Menus`: subida de nivel, pausa y pantalla final.
  - `pause_watch.gd` atiende Esc o Start también con la partida en pausa.
- **Arena** (`scripts/level/arena_builder.gd`):
  - Monta un JSON de `data/arenas/` (generado por `tools/gen_arena_campamento.py`) con el suelo de nieve, el mar, las piezas con su colisión, una luz y un halo de niebla por farol, y los límites invisibles.
  - Capa 1: mundo. Capa 2: jugadores.

## Personajes jugables modelados

| Personaje | Estado | Concepto |
|---|---|---|
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

- **Orden de vértices:** Godot considera cara frontal el sentido horario. Con el orden al revés se ven huecos negros y desaparece el suelo.
- **Caché de clases:** si se borra `.godot/`, hay que ejecutar `godot --headless --path . --import` antes de lanzar; si no, `VoxelBuilder` aparece como no declarado.
- **Rendimiento de los generadores:** nunca buscar superficies recorriendo todo el diccionario de voxels. Hay que recorrer la columna directamente (`front()` / `top()` en `gen_acechador.py`); la versión ingenua superó los 5 minutos.
- **Púas finas:** por debajo de ~0,5 unidades base de radio en la punta se fragmentan en puntos sueltos a esta resolución.
- **Colores de vértice:** los colores de los modelos se calibraron en Compatibility, que no convierte sRGB a lineal. En Forward+ hay que marcar `vertex_color_is_srgb`, o todo sale el doble de claro y lavado. `VoxelBuilder.colors_are_srgb()` lo decide según el renderizador; úsalo en cualquier material con colores de vértice.
- **Renderizado:** el juego usa Forward+ (D-15). Compatibility queda como reserva con `--rendering-method gl_compatibility`. El entorno sale de `Atmosphere.make_environment()`, que tiene valores distintos por renderizador:
  - En Forward+, Filmic levanta los negros y lava los colores. ACES con exposición 1,6, sin bloom y con niebla de 0,02 reproduce el aspecto aprobado.
  - Con 150 modelos, Forward+ rinde el doble que Compatibility (`docs/RENDIMIENTO.md`).
- **Personajes humanos:** el primer Dyer se rechazó. Estaba esculpido con elipsoides y relieves de un voxel (nariz, ribetes, gafas, correa, botones), y a esta escala cada relieve se convertía en un bulto deforme; la capucha, además, ocultaba la forma de la cabeza. Los humanos se hacen a bloques limpios (`vbox` y `bevel`), con los detalles pintados sobre superficies planas. La cara se dibuja en el plano frontal de la cabeza con píxeles de 1 voxel y sin relieve, y se usa muy poco ruido de color. Los tonos de piel, pelo y prendas deben distinguirse bien, porque bajo luz cálida el crema de la piel y el gris claro se confunden. Revisa siempre también la espalda y el perfil.
- **Identidad de un animal:** lo que hace reconocible a una especie es su silueta y su patrón de color, no el detalle. El pingüino todo blanco parecía un huevo; con la silueta de emperador y el frac en tonos pálidos se reconoce al instante.
- **Material por modelo:** con el material húmedo de las criaturas, las caras planas de la ropa reflejan los faroles casi en blanco. Ropa, plumas y atrezo van mates.
- **Superficies escalonadas:** los elipsoides grandes dejan un escalón en cada capa de voxels, y la luz cenital los convierte en motas. Para ropa, madera y piedra usa `sell` (superelipsoide), que da caras planas.
- **Detalles que apuntan a la cámara:** en vista isométrica, lo que apunta justo hacia la cámara desaparece en la proyección (el pico del pingüino de frente). Comprueba cada modelo a varios giros.
- **Ojos brillantes:** una esfera `glow` dentro de un párpado oscuro tiene que asomar lo suficiente (desplazada ~0,75 ub hacia fuera), o solo se ven motas sueltas.
- **Capturas abiertas en el visor de fotos:** Windows bloquea el fichero y Python no puede sobrescribirlo (`OSError: Invalid argument`). Guarda con otro nombre.
- **Rutas en Python desde Git Bash:** las rutas `/c/...` solo se traducen cuando van como argumento. Dentro del código Python usa `C:/...`.
- **Niebla volumétrica y cámara ortográfica:** la niebla volumétrica global no sirve con nuestra cámara: solo oscurece la escena y no dispersa la luz de los faroles (limitación conocida con cámaras cenitales u ortográficas).
  - **Lo que sí funciona:** volúmenes locales (`FogVolume` elipsoidal, densidad 0,35) alrededor de cada farol, con la niebla volumétrica activada y la densidad global a 0. Dan halos cálidos y cuestan unos 0,13 ms por fotograma.
- **Legibilidad del jugador:** con luz de luna, la parka marrón de Dyer se funde con el suelo oscuro. Se resuelve con tres cosas:
  - Un farol propio (luz cálida de 4,5 m de alcance que también ilumina a las criaturas cercanas).
  - Un anillo de color grueso.
  - Una silueta cuando lo tapa el decorado. La oclusión se mide contra el **centro** del personaje: solo cuenta lo que está más de 1,05 m por delante de él. Medirla fragmento a fragmento hacía que el brazo lejano se viera a través del torso (en isométrica queda más de medio metro por detrás), y con 0,75 m la cara se marcaba al inclinarse en el esquive.
- **Suelo sin juntas:** unos huecos de 1 cm entre losas dibujaban una cuadrícula y dejaban ver el mar que pasa por debajo, con destellos de los faroles. Las losas van contiguas.
- **Colisión al aparecer:** si un `CharacterBody3D` aparece dentro de una colisión, `move_and_slide` lo expulsa.
- **Bot con esquive:** el bot no debe esquivar en el primer fotograma. Si lo hace, sale disparado hacia delante y parece que no respeta la posición inicial.
- **Packed arrays en GDScript:** un `PackedInt32Array` sacado de un diccionario o metido en otro array es una copia. `(dic[k] as PackedInt32Array).append(x)` y `for a in [arr1, arr2]: a.resize(n)` no cambian el original. Hay que volver a guardarlo, o trabajar con la variable miembro directamente. Pasó dos veces en el hito 1.4.
- **`POSITION` en un shader de vértices:** si una rama lo escribe, hay que escribirlo en todas. En las que no, el vértice queda sin posición y la malla desaparece sin ningún error.
- **Colores sin iluminar y tonemapper:** ACES con exposición 1,6 también procesa los materiales `unshaded` y quema los colores saturados, de modo que el violeta sale blanco. Balas y avisos multiplican su color por un factor menor que 1 (`exposure_comp`).
- **Clases internas de GDScript:** no son nombres globales. Un `class X extends Y:` dentro de otro fichero solo se alcanza como `Fichero.X`. Si otras clases las crean por nombre, cada una va en su fichero con `class_name`.
- **Arrays tipados en `.tres`:** un `Array[EnemyData]` se escribe `Array[ExtResource("id_del_script")]([...])`, no `Array[Resource]`.
- **Coste por fotograma en GDScript:** con 150 enemigos, llamar a `find_children` y reasignar materiales en cada fotograma, y recalcular las posiciones de reposo leyendo metadatos, bajaba la partida de 170 a 81 FPS. `VoxelBuilder` guarda en metadatos las partes, las posiciones de reposo y las mallas de cada modelo (`parts`, `rest`, `rest_by_name`, `meshes`), y los materiales solo se tocan cuando cambia el estado.
- **Referencias a objetos liberados:** copiar un objeto ya liberado dentro de un array tipado (`Array[Object]`) da error. Para recordar un objetivo que puede morir en cualquier momento, guarda su `get_instance_id()`.
- **Aviso `ObjectDB instances leaked` al salir:** aparece si se fuerza la salida (`--quit-after`) mientras una corrutina espera un temporizador. No pasa al jugar normalmente.
- **Vibración con monitores de más de 60 Hz:** es el efecto de mover en `_physics_process` sin interpolación. En isométrica se nota sobre todo de lado y en diagonal, porque hacia arriba y hacia abajo el personaje recorre la mitad de píxeles.
- **Gemas y materiales sin iluminar:** un color dorado sin iluminar, tras el tonemapper (ACES 1,6), sale casi blanco o naranja rojizo según se trate como sRGB o no. Para objetos pequeños que deben verse bonitos, mejor material iluminado, algo metálico y con una emisión suave. Ojo con los reflejos puntuales muy nítidos: en una gema parecían ojos (rugosidad 0,5).
- **Mallas hechas con SurfaceTool:** el orden de los vértices decide qué cara se ve. Si una malla pequeña se ve rara o del color de su cara interior, prueba `cull_mode = CULL_DISABLED` o invierte el orden.
- **Edificios en voxel:** a 32 voxels por metro, un edificio macizo tendría cientos de miles de voxels. Se hacen huecos (paredes de 2-3 voxels, tejado de 1 más 2 de nieve), y el iglú como cáscara esférica de grosor uniforme; medirla en horizontal dejaba un agujero en la cúspide. Aun así, la cabaña tiene unos 100.000 voxels: la caché de mallas es imprescindible.
- **Rampas a 45° en voxel:** la tienda piramidal (escalones de un voxel) se veía rayada. Se rehízo como tienda de cumbrera, con faldones más empinados y color uniforme por paños.
- **Scripts largos en la herramienta de Bash:** un heredoc muy largo se corta ("unexpected EOF while looking for matching"). Para ediciones grandes, escribe el script en el scratchpad y ejecútalo.
- **Partículas con billboard:** `BILLBOARD_PARTICLES` descarta la escala de cada partícula si no se activa `billboard_keep_scale`. Todos los copos de nieve medían 1 m.
- **Bloom general y partículas pequeñas:** con `glow_bloom` > 0 cada punto claro se convierte en una bola borrosa. En la portada, el bloom es 0 y el brillo sale solo del umbral HDR.
- **Relámpagos y luz ambiental:** si el ambiente sale del cielo, cada relámpago ilumina el valle como si fuera de día. Usa ambiente de color fijo y deja el destello al cielo, a un contraluz rasante y a una luz puntual.
- **Montañas voxel:** un cono con pendiente uniforme o bloques aplanados se ven como pirámides escalonadas. Hacen falta cárcavas, un contorno quebrado de agujas (ruido de crestas de celda pequeña) y pocas mesetas.
- **NumPy y JSON:** los enteros de NumPy (`int64`) no se pueden serializar; conviértelos con `int()` o `float()` antes de `json.dump`.
- **Animar una ilustración:** se genera un mapa de máscaras y se modula la imagen con él en un shader, sin pintar nada nuevo encima. Una llama es un blob cálido y brillante; su luz, ese blob difuminado; y el cielo son los píxeles azules y claros dentro del ventanal. Las formas oscuras (tracería, silueta) quedan fuera solas. Mide la variación por zonas antes de darla por buena: a ojo se sobrestima lo sutil que es.
- **Shaders de canvas:** `TEXTURE` solo existe dentro de `fragment()`; para usarla en una función auxiliar hay que pasarla como `sampler2D`. Para superponer un halo bajo un texto que aparece, usa la composición "encima" con los colores ponderados por su alfa; una mezcla simple tiñe el texto con el color del halo mientras es transparente.
- **Texturas 4K mostradas a 1080p:** activa `mipmaps/generate=true` en su `.import` y usa `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`, o saldrán dientes de sierra y brillos que bailan al hacer zoom.
- **Tests y datos de equilibrio:** los tests no deben comprobar valores que se retocan al equilibrar (ritmos, experiencia, vida). Cuando haga falta, que construyan sus propios datos. Si un test falla tras un ajuste de equilibrio, el que está mal es el test.
- **Controles de los menús:** el `ui_accept` de Godot no trae ningún botón del mando y sí trae Espacio, que es la tecla de esquivar. `UiInput.configure()` añade A (aceptar) y B (volver) y quita Espacio. El menú de mejoras ignora las pulsaciones durante su primer medio segundo.
- **Élites ahogadas en la horda:** las armas apuntan al más cercano o a la zona más densa, así que una élite rodeada de la oleada casi no recibe disparos. `LevelData.final_spawn_scale` (0,3) reduce las apariciones durante el evento final.
- **`cat` sin entrada:** un `cat > fichero` sin heredoc se queda esperando la entrada estándar para siempre.

## Por definir

Las decisiones abiertas están en `docs/GDD.md` (sección 12), con la fase a la que bloquea cada una. Música y sonido solo tienen pautas sueltas (el susurro de los ataques mentales); el audio llega en la fase 8.
