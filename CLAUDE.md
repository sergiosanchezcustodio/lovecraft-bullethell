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

*Actualizado: 05-11-2026.* El resumen largo de cada fase está en **`docs/RESUMEN_ESTADO.md`** y el detalle de cada hito (sistemas, archivos, opciones de prueba, equilibrio, capturas) en **`docs/ESTADO.md`**: búscalo ahí antes de tocar un sistema. Al terminar un cambio, apunta el detalle en `docs/ESTADO.md` y, si cambia el panorama, actualiza `docs/RESUMEN_ESTADO.md` y estas líneas.

- Fases 0 a 7 y 9 a 14 hechas; casi todas esperan la partida, la prueba o la revisión del autor (fases 11 a 14, la prueba online por internet con `docs/PRUEBA_ONLINE.md` y el cooperativo con varios mandos).
- Fase 8 (pulido y distribución): falta subir a itch.io (necesita la cuenta del autor). Nube (fase 10): falta el `client_id` de la OAuth App del autor en `data/cloud.json`.
- Dificultad del 1 al 10 por características (D-42), temporal, pendiente de la calibración del autor.
- **Fase 15 (30-10-2026), hecha, pendiente de revisión** (hitos 15.1-15.4 en `docs/ROADMAP.md`): repetición de la caída (`DeathReplay`), modo desafío (`Challenge`, `data/challenges.json`), un enemigo nuevo por parte (expedicionario, nadador y tamborilero, `tools/gen_enemigos_fase15.py`) y bestiario vivo (`ModelIcon.make_live`, bajas por criatura). Mejoras del 02-11-2026 (destello de los jefes, faldón al caer, desafíos con el bot). **Fase 16** (`docs/ROADMAP.md`): bloque A (rendimiento) aprobado y en curso: hechos 16.1 en parte (`SpikeLog`, `LevelWarmup`, `ModelPool`), 16.2 (pose por ritmo, `anim_crowd_hz`), 16.3 (hordas con instancias: `HordeMesh`, `HordeDraw`, `horde=false`), 16.5 y 16.6 (`LevelPreload`: la partida se carga durante el relato); 16.4, fuera. Elegidos por el autor (D-46): de B, 16.8, 16.9, 16.12, 16.14 y 16.15; C, D, E y F enteros; G, no. Bloque B (03-11-2026), hechos y pendientes de revisión: 16.8 (dos ramas de evolución), 16.15 (aviso de evolución), 16.9 (Signos Mayores, D-47), 16.12 (buhonero, D-48) y 16.14 (grados de locura, D-49). Bloque C (enemigos y jefes): hechos el 16.16 (excavador y sembrador) , el 16.17 (guardián con escudo e hija de los Marsh) , el 16.18 (sonámbulo e ídolo vivo) , el 16.19 (jefes intermedios: Gedney, Obed Marsh y Castro) y el 16.20 (élites con rasgos, `EliteTraits`); bloque D: hechos el 16.23 (velocidad del juego y pausa automática) , el 16.22 (desfile de jefes, `BossRush`) , el 16.21 (expedición, `Expedition`) el 16.24 (pesca en el muelle, `Fishing`) y el 16.25 (personajes secretos, `Secrets`: Carter y Whateley); bloque E: hechos el 16.27 (daño por arma en la pausa, `DamageTable`) el 16.26 (archivo de expediciones, `RunArchive`, con semilla por partida) el 16.29 (comparar antes de elegir, `StatCompare`) el 16.30 (vibración regulable, `Rumble`) y el 16.28 (sala de trofeos, `TrophyRoom`); bloque E completo. Bloque F: hechos el 16.31 (reflejos en el agua, `WaterReflection`, Alta y Ultra) el 16.32 (haces de luna, `MoonShafts`) el 16.33 (la noche avanza, `NightCycle`) el 16.34 (decorado que se rompe, `DecorBreak`) y el 16.35 (cielos en los relatos y la portada); bloque F completo. **Fase 17** (05-11-2026, animación y vida de los escenarios, `docs/ROADMAP.md`; 20 hitos, sin empeorar apreciablemente el rendimiento): hecho el 17.1 (gesto al atacar según el arma, `WeaponData.gesture`, `Player.gesture`; hojas de poses con `tools/hoja_poses.gd`) el 17.2 (frenada al pararse tras correr) el 17.3 (la cabeza mira al peligro) el 17.4 (celebraciones), el 17.5 (pose de victoria), el 17.6 (andar según el suelo) y el 17.7 (gestos de reposo del shoggoth y la serpiente).

### Reglas que no hay que olvidar

- **Imágenes:** primero ComfyUI en local (`tools/comfyui.cmd`, `python tools/generar_local.py`). Replicate solo con permiso del autor y el coste estimado; tope de 5 predicciones por ejecución (`REPLICATE_MAX`, gasto en `tools/replicate/gasto.log`).
- **Regenerar tras cambios:** si cambia una arena, `gen_arena_<nombre>.py` y `tools/render_mapa.gd`; si cambia un personaje, su generador y después `gen_vestuario.py` (y `gen_caras_juego.py` si cambia la cara); si cambia un arma, `tools/reglas_dano.gd -- aplicar` y `tools/gen_evoluciones.gd`; si cambia la construcción de mallas, sube `VoxelBuilder.BUILDER_VERSION`; si cambian las ilustraciones de la portada, la tienda o el libro, sus scripts de máscaras o de enderezado; si cambian los adornos de los menús, `python tools/gen_adornos_menu.py --semillas N` y `--usar SEMILLA` (ComfyUI arrancado).
- **Simulaciones:** `--ts 2` y como mucho `--par 2` (con 3 a la vez se acaba la memoria).
- **Rendimiento:** el 1 % peor varía mucho entre ejecuciones y la primera tras regenerar un modelo construye su malla: repite siempre la medición. Desde el 03-11-2026 el escritorio aparte quita el «ahorro de energía» de Windows, que falseaba los picos: no compares con mediciones anteriores (`LOVECRAFT_ECO=1` lo deja como antes). Para comparar configuraciones, `python tools/comparar.py "<A>" "<B>" --niveles … --veces 3`.
- **Shaders:** nada de `fract(sin(x) * 43758)` con argumentos grandes; usa el hash de `night_sky.gdshaderinc`.
- **Bots y capturas:** `mute=true`; las ejecuciones de prueba van en ventana.
- **Pruebas sin robar el mando ni el foco (28 y 29-10-2026):** el autor juega a otras cosas con el mando en este PC mientras pruebo. Desde Claude Code (`CLAUDECODE=1`), `~/bin/godot` pasa por `tools/godot_sin_foco.sh`, que abre la ventana **en otro escritorio de Windows, invisible** (`tools/escritorio_aparte.py`; con `no_focus` solo, Windows le daba el foco 90 ms al crearla y el juego del autor perdía el mando). Ahí se dibuja, se captura, se graba y se juega en red igual; si la prueba se corta, se cierra sola. El rendimiento sale algo mejor que en el escritorio normal (sin composición): compara solo mediciones hechas en el mismo sitio. Además ( `override.cfg` pasajero con `no_focus`; de 3×3 px y sin bordes, y `main.gd` la lleva a su tamaño fuera de las pantallas, donde se captura igual; arranca en bajo consumo para que Godot no suba su prioridad ni se apunte como «Games» en Windows, y se dibuja a 30 fps salvo al medir o grabar) y la partida no hace caso a los mandos (`JoypadInput.disabled`, «Mandos desactivados» en la consola). Para probar con mando de verdad, `mando=true`; para ver la ventana, `ver=true` (las dos, en el escritorio de siempre). Lanza Godot siempre con el comando `godot` de Git Bash, no con el ejecutable directamente.
- **Autoloads en código de partida:** usa `Auto.sfx_at`, `Auto.sfx`, `Auto.setting` y `Auto.node` (`scripts/core/auto.gd`), no `Sfx.`/`Settings.` directamente: si no, las herramientas con `-s` (mapas de la Biblioteca) no compilan esos scripts.
- **Pantalla completa** exclusiva por defecto; la interfaz escala desde 1920×1080.
- **Calidad gráfica** (`Quality`, `data/quality.json`): Alta es la de siempre y la que se usa en las mediciones; un efecto nuevo con coste apreciable debe poder bajarse en Baja o Media.
- **Luz de las arenas:** las noches se aclaran con `"gamma"` en el `light` de la arena (curva tras el tono, `Atmosphere.set_lift`), no subiendo ambiente o exposición, que el tono ACES aplasta. Apunta a una mediana de brillo de 0,16-0,22 en las noches (detalle en `docs/ESTADO.md`).

## Decisiones cerradas

- **Motor:** Godot 4.4.
- **Género:** bullet hell con disparo automático y progresión tipo "survivors", cooperativo local de 1 a 4 jugadores. Diseño completo en `docs/GDD.md`.
- **Ambientación:** mitos de H. P. Lovecraft. Son de dominio público en España y la UE; solo hay que evitar el nombre comercial "Call of Cthulhu" (marca de Chaosium).
- **Licencia (D-40, 23-10-2026):** mixta. El código, bajo GPLv3 (`LICENSE`). El arte, la música del autor, los textos del juego y el nombre tienen todos los derechos reservados (`LICENCIA.md`, `data/credits.json`).
- **Cámara:** ortográfica isométrica fija (rotación -30° en X, 45° en Y).
- **Estilo gráfico:** voxel 3D detallado, "Minecraft mejorado", a 32 voxels por metro de juego (`VOXEL = 0.03125`).
- **Diseño de personajes (humanos: jugables, cultistas, híbridos):** a bloques limpios, con detalles pintados y casi sin relieve (decidido el 25-09-2026 tras rechazar un Dyer esculpido). Las criaturas pueden seguir siendo orgánicas, como el Acechador.
- **Diseño de los profundos:** clásicos, oscuros, sin ropa ni adornos externos (nada de tiaras ni joyas). Solo anatomía: escamas, púas, aletas, agallas, garras. La regla solo afecta a las criaturas: híbridos, cultistas y sacerdotes sí pueden llevar tiaras, joyas y amuletos (confirmado el 21-10-2026).
- **Atmósfera:** oscuridad, luz de luna fría, luz cálida puntual, contraluz verdosa, niebla ligera.

### Estilos probados y descartados
- 3D chibi liso (modelado SDF + marching cubes), tanto en versión simpática como oscura: descartado en favor del voxel.
- Three.js / HTML5: descartado en favor de Godot.

## Dónde está el resto

Para no cargarlo en cada sesión, el detalle vive en archivos aparte:
- **`tools/CLAUDE.md`**: pipeline de arte (generadores con `voxlib.py`, formato JSON de los modelos, `VoxelBuilder`, caché de mallas, animación por partes), personajes jugables y bestiario. Se carga al trabajar en `tools/`.
- **`scripts/CLAUDE.md`**: arquitectura del juego (entrada, interpolación de física, combate, enemigos, niveles, guardado, nube, red, menús, interfaz, arena). Se carga al trabajar en `scripts/`.
- **`scripts/title/CLAUDE.md`**: pantalla de título (máscaras, capas, configuración por efecto).
- **`docs/OPCIONES.md`**: comandos de uso y todas las opciones de lanzamiento (`bot=`, `shots=`, `level=`, `cfg_quality=`…).

Lo esencial del pipeline: los modelos son voxels a 32 por metro (`VOXEL = 0.03125`) generados en Python (`tools/gen_*.py`, `tools/voxlib.py`) a `models/*.json`; la animación rota nodos-parte desde código, así que el giro y la posición de un modelo van siempre en un nodo contenedor, nunca en la raíz.

## Entorno

Entorno de desarrollo (Windows 11 + Git Bash):
- **Godot 4.4.1** en `C:\Tools\Godot\`. El comando `godot` ejecuta `Godot_v4.4.1-stable_win64_console.exe`, para que la salida aparezca en la terminal. En Git Bash lo resuelve el lanzador `~/bin/godot` (desde Claude Code, a través de `tools/godot_sin_foco.sh`); en PowerShell y cmd, `C:\Tools\Godot\godot.cmd` (la carpeta está en el PATH de usuario).
- **Python 3.12** como `python`. En Windows, `python3` abre la Microsoft Store en lugar de ejecutar el script.
- No hace falta xvfb: las capturas abren una ventana un momento y se cierran solas.

Uso básico desde la raíz, en Git Bash (lista completa en `docs/OPCIONES.md`):
```
godot --path .                                   # portada
godot --path . -- bot=circle demo=14 shots=1,3 tag=prueba mute=true   # partida con bot y capturas
godot --headless --path . -s addons/gut/gut_cmdln.gd                   # tests (GUT)
godot --headless --path . --import               # reconstruye la caché de .godot/ (al crear un class_name)
```
- **Encadenar comandos:** un `godot ... | grep error` devuelve 1 cuando no hay errores, así que no lo encadenes con `&&`.

## Lecciones técnicas aprendidas

En `docs/LECCIONES.md` (orden de vértices, caché de clases, colores sRGB, interpolación de física, packed arrays, shaders, partículas, foco del mando, referencias circulares…). Léelas antes de tocar esos temas y añade allí las nuevas.

## Por definir

Las decisiones abiertas están en `docs/GDD.md` (sección 12), con la fase a la que bloquea cada una. Música y sonido solo tienen pautas sueltas (el susurro de los ataques mentales); el audio llega en la fase 8.
