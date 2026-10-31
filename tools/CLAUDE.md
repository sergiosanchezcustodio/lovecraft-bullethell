# Pipeline de arte, personajes y bestiario

Se carga al trabajar en `tools/`. Movido desde el `CLAUDE.md` de la raíz el 30-10-2026.

### Pipeline de arte

1. **Generador en Python** (`tools/`): construye el personaje como un conjunto de voxels a partir de primitivas (elipsoides, cápsulas, conos), luego colorea (degradado dorsal/flanco/vientre, escamas, manchas por ruido) y talla detalles sobre la superficie real (boca, dientes, ojos, agallas, cresta). Los generadores nuevos usan **`tools/voxlib.py`**:
   - Clase `Model` con las primitivas (`ell`, `sell`, `capsule`, `cone`, `box`, `line`), búsqueda de superficie por columna (`front`, `top`, `exposed`), ruido y `export`.
   - Se modela en unidades base (1 ub = 1/16 m) y la resolución es el parámetro `S`: 2 voxels por ub = 32 voxels/m.
   - El superelipsoide `sell` (p≈2,5–3) da caras planas para ropa, madera y piedra.
   - `vbox` y `bevel` sirven para diseñar a bloques en coordenadas voxel, como los personajes humanos. Con `export(..., pivots_in_voxels=True)` los pivotes también van en voxels.
   - `export(..., roughness=, specular=)` fija el material del modelo. Sin indicarlos queda piel húmeda (0,38 / 0,6); la ropa, las plumas y el atrezo van mates (~0,9 / 0,25).
   - `inner_faces(M, partes)` y `export(..., skip=)`: en un modelo vaciado, marcan las caras que dan al hueco cerrado de cada parte para que no se construyan (en Dagon, la mitad de la malla). El hueco de cada parte tiene que cerrarlo esa misma parte: ver `docs/LECCIONES.md`. Sin `skip`, `export` las calcula solo (`inner=False` para no hacerlo); `python tools/caras_dentro.py modelos…` las añade a un JSON ya generado sin regenerarlo.
2. **Salida JSON** (`models/*.json`): `voxels` = lista de `[x, y, z, parte, r, g, b, glow]` (con un noveno valor opcional: bits de las caras que dan al hueco y no se construyen; el bit 64 marca un voxel tapado por otra parte en el mismo sitio, `Model.keep_under`, que se construye con las caras un poco hundidas), `pivots` = pivote por parte, en coordenadas voxel, y `voxel_size` (metros por voxel, opcional; por defecto 1/32). Un pivote sin voxels, como `light` en el farol, sirve para marcar puntos.
3. **`scripts/voxel_builder.gd`**: convierte el JSON en mallas con eliminación de caras ocultas y oclusión ambiental por vértice. Crea un nodo por parte con su pivote (`torso`, `head`, `arm_l`, `arm_r`, `leg_l`, `leg_r`) y separa los voxels `glow=1` en una capa sin sombreado (ojos, bioluminiscencia, brillos). Las mallas se construyen una vez por modelo y todas las instancias las comparten; la primera construcción del Acechador tarda unos 200 ms.
   - **Caras ocultas:** solo se quitan las que tapa un voxel de la misma parte. Entre partes distintas se conservan todas: al girar un brazo, una pierna o la cabeza queda al aire lo que tapaban. Tampoco se construyen las que el JSON marca como del hueco (noveno valor). Antes se quitaban las "enterradas" (dos voxels de otra parte delante), y con el brazo de 5 voxels pegado al tronco el costado se veía hueco al andar.
   - **Material:** sale del `roughness` y el `specular` del JSON.
   - **Caché en disco:** las mallas construidas se guardan en `user://voxcache/` (`VoxelMeshCache`). La clave depende de la fecha y el tamaño del JSON y de `VoxelBuilder.BUILDER_VERSION`. Una cabaña de 100.000 voxels tarda 1,7 s en construirse y unos milisegundos en cargarse de la caché. **Sube `BUILDER_VERSION` si cambias cómo se construyen las mallas.** La partida precarga los modelos de todos los enemigos del nivel al empezar.
4. **Animación:** rotando los nodos-parte desde código (sin rigging).
   - Cada tipo de modelo tiene su script en `scripts/anim/` (`anim_profundo`, `anim_humano`, `anim_pinguino`, `anim_fragmento`), con funciones estáticas por animación y la constante `DURATION`.
   - Se aplican con `Anims.pose(modelo, animación, nodo, t)`, con t de 0 a 1. `Anims.reset()` devuelve todas las partes al reposo, incluida la raíz del modelo.
   - Por eso el giro y la posición de un modelo van siempre en un nodo contenedor, nunca en la raíz.


Nota: `gen_variantes.py` también escribe un `acechador.json` genérico que sobrescribiría el detallado. Ejecuta `gen_acechador.py` después, o renombra la salida.

### Personajes jugables modelados

| Personaje | Estado | Concepto |
|---|---|---|
| **Robert Olmstead** | Hito 2.4 (`gen_olmstead.py`), cabeza rehecha el 23-10-2026 | Joven viajero: gorra de plato de tweed con visera fina, chaqueta de tweed gris verdoso, chaleco, camisa blanca y corbata azul, pantalón pardo y un revólver en la cadera. Revólver, voltereta larga, resistencia a las criaturas marinas. |
| **John R. Legrasse** | Hito 2.4 (`gen_legrasse.py`), cabeza rehecha el 23-10-2026 (la primera con `cuerpo.face_art`) | Inspector: fedora gris marengo de ala ancha con la copa pellizcada, gabardina corta gris piedra abierta sobre traje azul marino, placa dorada, cejas de ceño y bigote de manillar. Escopeta, salto, más daño a los humanos. |
| **Gustaf Johansen** | Hito 2.4 (`gen_johansen.py`), cabeza rehecha el 23-10-2026 | Marinero corpulento (torso más ancho): gorro de lana gris con canalé en la vuelta, ojos azules, barba dorada, chaquetón cruzado azul marino con botones de latón y jersey crema de cuello vuelto. Machete, plancha, mucha vida. |
| **Amelia Peaslee** | Hito 2.4b (`gen_peaslee.py`), cabeza rehecha el 23-10-2026 | Arqueóloga: fedora de fieltro pardo, ojos verdes y pecas, trenza cobriza, camisa caqui remangada, correa cruzada con cartera de cuero, pantalón de montar y botas altas. Rifle de caza, voltereta, suerte y recogida. |
| **Madame Ludmila Varga** | Hito 2.4b (`gen_varga.py`), cabeza rehecha el 23-10-2026 | Médium de salón: vestido largo de terciopelo negro, estola ciruela con flecos, collar de perlas, media melena negra, diadema con pluma violeta, ojos ahumados y labios granate. Necronomicón, destello, arcanas a mitad de cordura. |
| **Dra. Marian Whipple** | Hito 2.4b (`gen_whipple.py`), cabeza rehecha el 23-10-2026 | Bata blanca larga abierta sobre vestido gris, estetoscopio, gafas redondas de bronce y moño castaño. Bisturís, salto, curación al subir de nivel. |
| **Henrietta Blake** | Hito 2.4b (`gen_blake.py`), cabeza rehecha el 23-10-2026 | Escritora: cloché verde azulado, ojos azules, media melena rubia, abrigo burdeos con bufanda crema y pluma en el bolsillo. Trapezoedro, deslizamiento, más experiencia. |
| **Padre Iwanicki** | Hito 2.4b (`gen_iwanicki.py`), cabeza rehecha el 23-10-2026 | Sotana negra hasta los tobillos con botonadura, alzacuellos, crucifijo de plata, fajín morado, pelo gris con entradas, cejas pobladas y arrugas amables. Fórmula de expulsión, voltereta, aura que calma. |
| **Sargento Frank Elwood** | Hito 2.4b (`gen_elwood.py`), cabeza rehecha el 23-10-2026 | Veterano corpulento: casco Brodie con barboquejo, ceño, guerrera oliva con correajes y cartucheras, polainas y bigote de morsa (30-10-2026). Colt .45, plancha, aguante físico. |
| **Vera Malone** | Hito 2.4b (`gen_malone.py`), cabeza rehecha el 23-10-2026 | Traje cruzado gris a rayas diplomáticas, corbata granate, clavel, fedora granate, media melena negra, una ceja levantada y media sonrisa. Thompson, deslizamiento, daño a quemarropa. |
| **William Dyer** | Hito 1.2, segunda versión (`gen_dyer.py`), cabeza rehecha el 23-10-2026, 1,72 m | Diseño a bloques limpios con los detalles pintados. Gorro de trampero de cuero con banda de borreguillo y botón, cara con cejas caídas, mejillas y nariz rojas del frío, barba y bigote, pelo en la nuca, bufanda roja, parka de lona con bolsillos, botones y ribete de borreguillo, cinturón con tres cartuchos de dinamita (único relieve), manoplas, pantalón de lana y botas. Material mate. Animaciones: reposo, andar, esquive y lanzar. |
| **Henry Armitage** | Fase 5 (`gen_armitage_west.py`), cabeza rehecha el 23-10-2026 | Bibliotecario anciano: calvo con pelo blanco a los lados, cejas blancas pobladas, gafas redondas de oro, barba y bigote blancos, levita gris marengo, pajarita negra y un libro bajo el brazo. |
| **Herbert West** | Fase 5 (`gen_armitage_west.py`), cabeza rehecha el 23-10-2026 | Científico joven y pálido: pelo rubio peinado hacia atrás, gafas redondas negras, ojos claros y fríos, bata blanca sobre traje oscuro. |

### Bestiario actual

| Enemigo | Estado | Concepto |
|---|---|---|
| **Pingüino albino ciego** | Hito 1.2, segunda versión (`gen_pinguino.py`), 8.100 voxels | Silueta de pingüino emperador de 1,5 m: cuerpo de torpedo con sección casi plana, cabeza adelantada y pico largo. Dibujo de frac en tonos de albino: gris frío pálido en espalda, cabeza y aletas, pecho blanco, manchas de las orejas amarillo claro y ojos lechosos. Patas rosadas. Material mate. Animaciones: reposo (escucha), andar bamboleándose y carga con picotazo. |
| **Fragmento protoplásmico** | Hito 1.2 (`gen_fragmento.py`), 9.500 voxels | Masa negra iridiscente con brillos verdes y violetas, seis ojos verdosos brillantes, boca que silba y dos pseudópodos. Partes: `body`, `top`, `pod_l`, `pod_r`. Animaciones: reposo, reptar y ráfaga. |
| **Acechador** | Elegido y detallado (`gen_acechador.py`) | Agazapado como rana, manos apoyadas delante, ojos enormes arriba con pupila de rendija, colmillos entrelazados, cresta de púas color hueso con membrana, agallas en volante. Animaciones de acecho y salto. |
| Clásico | Prototipo | Hombre-pez escuálido y encorvado, ojos amarillentos laterales, púas dorsales. |
| Bruto | Prototipo | Masivo, mandíbula enorme con boca caída, ojos pequeños bajo el ceño, verrugas. Candidato a tanque o mini-jefe. |
| **Expedicionario de Lake** | Hito 15.3 (`gen_enemigos_fase15.py`) | Hombre de la expedición de Lake congelado y vuelto a levantar: parka hecha jirones con escarcha, piel azulada, ojos con brillo frío, antebrazo descarnado. Humano (`anim_humano`). |
| **Nadador de la marea** | Hito 15.3 (`gen_enemigos_fase15.py`, con `gen_variantes.build`) | Profundo joven y esbelto, plateado y azul, aletas largas y franjas que brillan. `anim_profundo`. |
| **Tamborilero del pantano** | Hito 15.3 (`gen_enemigos_fase15.py`) | Cultista de Luisiana: torso desnudo pintado de costillas, cara de calavera, tambor de piel delante y baquetas. Humano (`anim_humano`). |
| Abisal | Prototipo | Negro azulado, ojos cian brillantes, líneas bioluminiscentes, dientes largos. |
