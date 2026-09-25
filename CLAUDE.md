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
  - **Hito 1.1 (base técnica): hecho y aprobado.** Forward+ con el entorno recalibrado, GUT 9.4.0, caché de mallas, capturas por tiempo (`ShotTaker`) y escena de rendimiento (`scenes/bench.tscn`, medición en `docs/RENDIMIENTO.md`).
  - **Hito 1.2 (modelos nuevos): segunda versión, pendiente de revisión.** Dyer, pingüino albino ciego, fragmento protoplásmico y atrezo del campamento, con sus animaciones en `scripts/anim/`.
    - Rechazados en la primera revisión: Dyer ("ni siquiera parece una persona": demasiado relieve y cara horrible) y el pingüino ("no parece un pingüino"). Rehechos con el enfoque de las lecciones "Personajes humanos" e "Identidad de un animal".
    - Hojas de revisión en `shots/revision_1_2_modelos_v2.png` y `shots/revision_1_2_animaciones_v2.png`, y GIF en `shots/anim_*_v2.gif` (se regeneran; `shots/` no va a git).
  - **Siguiente: hito 1.3**, jugador, entrada, cámara y arena provisional.
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
- **Encadenar comandos:** un `godot ... | grep error` devuelve 1 cuando no hay errores, así que no lo encadenes con `&&`.

Nota: `gen_variantes.py` también escribe un `acechador.json` genérico que sobrescribiría el detallado. Ejecuta `gen_acechador.py` después, o renombra la salida.

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
- **Niebla volumétrica y cámara ortográfica:** la niebla volumétrica global no sirve con nuestra cámara. Solo oscurece la escena y no dispersa la luz de los faroles, una limitación conocida de Godot con cámaras cenitales u ortográficas. Queda por probar con volúmenes de niebla locales (`FogVolume`) en el hito 1.3.

## Por definir

Las decisiones abiertas están en `docs/GDD.md` (sección 12), con la fase a la que bloquea cada una. Música y sonido solo tienen pautas sueltas (el susurro de los ataques mentales); el audio llega en la fase 8.
