# Lovecraft Bullet Hell: documento de arranque

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
  - **Hito 1.1 (base técnica): hecho**, pendiente de tu revisión visual. El proyecto ya usa Forward+ con el entorno recalibrado; GUT 9.4.0 instalado con los primeros tests; caché de mallas en `VoxelBuilder`; capturas por tiempo (`ShotTaker`) y escena de rendimiento (`scenes/bench.tscn`). Primera medición en `docs/RENDIMIENTO.md`.
  - **Siguiente: hito 1.2**, los modelos nuevos (Dyer, pingüino, fragmento y atrezo del campamento).
- **Todavía no hay código de juego:** solo el visor, la escena de rendimiento y los generadores de modelos.
- **Pendiente de confirmar:** si la regla "sin tiaras ni joyas" de los Profundos se limita a las criaturas (GDD, sección 13, punto 5).

## Decisiones cerradas

- **Motor:** Godot 4.4.
- **Género:** bullet hell con disparo automático y progresión tipo "survivors", cooperativo local de 1 a 4 jugadores. Diseño completo en `docs/GDD.md`.
- **Ambientación:** mitos de H. P. Lovecraft. Son de dominio público en España y la UE; solo hay que evitar el nombre comercial "Call of Cthulhu" (marca de Chaosium).
- **Cámara:** ortográfica isométrica fija (rotación -30° en X, 45° en Y).
- **Estilo gráfico:** voxel 3D detallado, "Minecraft mejorado", a 32 voxels por metro de juego (`VOXEL = 0.03125`).
- **Diseño de los profundos:** clásicos, oscuros, sin ropa ni adornos externos (nada de tiaras ni joyas). Solo anatomía: escamas, púas, aletas, agallas, garras.
- **Atmósfera:** oscuridad, luz de luna fría, luz cálida puntual, contraluz verdosa, niebla ligera.

### Estilos probados y descartados
- 3D chibi liso (modelado SDF + marching cubes), tanto en versión simpática como oscura: descartado en favor del voxel.
- Three.js / HTML5: descartado en favor de Godot.

## Pipeline de arte

1. **Generador en Python** (`tools/`): construye el personaje como un conjunto de voxels a partir de primitivas (elipsoides, cápsulas, conos), luego colorea (degradado dorsal/flanco/vientre, escamas, manchas por ruido) y talla detalles sobre la superficie real (boca, dientes, ojos, agallas, cresta).
2. **Salida JSON** (`models/*.json`): `voxels` = lista de `[x, y, z, parte, r, g, b, glow]` y `pivots` = pivote por parte, en coordenadas voxel.
3. **`scripts/voxel_builder.gd`**: convierte el JSON en mallas con eliminación de caras ocultas y oclusión ambiental por vértice. Crea un nodo por parte con su pivote (`torso`, `head`, `arm_l`, `arm_r`, `leg_l`, `leg_r`) y separa los voxels `glow=1` en una capa sin sombreado (ojos, bioluminiscencia, brillos). Las mallas se construyen una vez por modelo y todas las instancias las comparten; la primera construcción del Acechador tarda unos 200 ms.
4. **Animación:** rotando los nodos-parte desde código (sin rigging). Ejemplos en `scripts/preview.gd`: `_animate` (andar), `_idle` (acecho) y `_pounce` (salto de ataque).

Entorno de desarrollo (Windows 11 + Git Bash):
- **Godot 4.4.1** en `C:\Tools\Godot\`. El comando `godot` ejecuta `Godot_v4.4.1-stable_win64_console.exe`, para que la salida aparezca en la terminal. En Git Bash lo resuelve el lanzador `~/bin/godot`; en PowerShell y cmd, `C:\Tools\Godot\godot.cmd` (la carpeta está en el PATH de usuario).
- **Python 3.12** como `python`. En Windows, `python3` abre la Microsoft Store en lugar de ejecutar el script.
- No hace falta xvfb: las capturas abren una ventana un momento y se cierran solas.

Uso desde la raíz del proyecto, en Git Bash:
```
python tools/gen_acechador.py       # regenera models/acechador.json
python tools/gen_variantes.py       # regenera clasico, bruto, acechador (versión simple) y abisal
godot --headless --path . --import                # reconstruye la caché de .godot/ (primera vez, tras borrarla o al crear un class_name)
godot --path . -- still <yaw> <modelo>            # captura en shots/<modelo>_<yaw>.png
godot --path . -- anim <yaw> <modelo> <idle|pounce|walk>
godot --path . -- still 0 lineup                  # los cuatro juntos
godot --path . -- still 0 lineup fog_density=0.03 moon.light_energy=0.6 tag=prueba   # ajustes de entorno y luces al vuelo
godot --headless --path . -s addons/gut/gut_cmdln.gd                                 # tests (GUT 9.4.0, configuración en .gutconfig.json)
godot --path . scenes/bench.tscn --disable-vsync --resolution 1920x1080 -- count=150 model=acechador   # rendimiento (docs/RENDIMIENTO.md)
```
- **Capturas:** van a `shots/`, que Godot ignora (`.gdignore`) y git también. Añade `--rendering-method gl_compatibility` a cualquier comando para usar el renderizador de reserva.
- **Argumentos:** las escenas leen lo que va detrás de `--` con `LaunchArgs` (`scripts/core/launch_args.gd`): posicionales, `clave=valor` y banderas `--clave`.
- **Encadenar comandos:** un `godot ... | grep error` devuelve 1 cuando no hay errores, así que no lo encadenes con `&&`.

Nota: `gen_variantes.py` también escribe un `acechador.json` genérico que sobrescribiría el detallado. Ejecuta `gen_acechador.py` después, o renombra la salida.

## Bestiario actual

| Enemigo | Estado | Concepto |
|---|---|---|
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
- **Niebla volumétrica y cámara ortográfica:** la niebla volumétrica global no sirve con nuestra cámara. Solo oscurece la escena y no dispersa la luz de los faroles, una limitación conocida de Godot con cámaras cenitales u ortográficas. Queda por probar con volúmenes de niebla locales (`FogVolume`) en el hito 1.3.

## Por definir

Las decisiones abiertas están en `docs/GDD.md` (sección 12), con la fase a la que bloquea cada una. Música y sonido solo tienen pautas sueltas (el susurro de los ataques mentales); el audio llega en la fase 8.
