# Lovecraft Bullet Hell: documento de arranque

Documento de contexto del proyecto. Recoge las decisiones tomadas en la fase de exploración y el pipeline de arte que ya funciona. Es el punto de partida para cualquier sesión de trabajo (claude.ai o Claude Code).

## Decisiones cerradas

- **Motor:** Godot 4.4.
- **Género:** bullet hell. El resto del diseño de juego está por concretar.
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
3. **`scripts/voxel_builder.gd`**: convierte el JSON en mallas con eliminación de caras ocultas y oclusión ambiental por vértice. Crea un nodo por parte con su pivote (`torso`, `head`, `arm_l`, `arm_r`, `leg_l`, `leg_r`) y separa los voxels `glow=1` en una capa sin sombreado (ojos, bioluminiscencia, brillos).
4. **Animación:** rotando los nodos-parte desde código (sin rigging). Ejemplos en `scripts/preview.gd`: `_animate` (andar), `_idle` (acecho) y `_pounce` (salto de ataque).

Entorno de desarrollo (Windows 11 + Git Bash):
- **Godot 4.4.1** en `C:\Tools\Godot\`. El comando `godot` ejecuta `Godot_v4.4.1-stable_win64_console.exe`, para que la salida aparezca en la terminal. En Git Bash lo resuelve el lanzador `~/bin/godot`; en PowerShell y cmd, `C:\Tools\Godot\godot.cmd` (la carpeta está en el PATH de usuario).
- **Python 3.12** como `python`. En Windows, `python3` abre la Microsoft Store en lugar de ejecutar el script.
- No hace falta xvfb: las capturas abren una ventana un momento y se cierran solas.

Uso desde la raíz del proyecto, en Git Bash:
```
python tools/gen_acechador.py       # regenera models/acechador.json
python tools/gen_variantes.py       # regenera clasico, bruto, acechador (versión simple) y abisal
godot --headless --path . --import                # reconstruye la caché de .godot/ (primera vez o tras borrarla)
godot --path . -- still <yaw> <modelo>            # captura en shots/<modelo>_<yaw>.png
godot --path . -- anim <yaw> <modelo> <idle|pounce|walk>
godot --path . -- still 0 lineup                  # los cuatro juntos
```
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
- **Colores de vértice:** en estilos no voxel hubo que marcar `vertex_color_is_srgb`. En voxel los valores actuales ya están calibrados.
- **Renderizado:** las capturas se generan con el renderizador Compatibility (OpenGL 3.3), elegido en su día para poder capturar sin GPU. En este PC corre sobre la RTX 3070 Ti. Forward+ daría niebla volumétrica y mejores sombras sobre los mismos modelos.

## Por definir

Mecánicas del bullet hell, personaje del jugador, escenarios, resto del bestiario (incluidos jefes), armas, progresión, música y sonido, plataforma de distribución.
