# Lovecraft Library: Surviving Cthulhu — documento de arranque

Documento de contexto del proyecto. Recoge las decisiones tomadas en la fase de exploración y el pipeline de arte que ya funciona. Es el punto de partida para cualquier sesión de trabajo (claude.ai o Claude Code).

## Documentación del juego

Léela al empezar cada sesión:
- `docs/PROMPT_juego_lovecraft.md`: especificación original del juego y reglas de trabajo por hitos (plan antes de programar, verificación visual, datos antes que código). No se modifica.
- `docs/GDD.md`: documento de diseño vivo. Recoge la especificación más las decisiones tomadas después (`D-xx`, sección 12). Si discrepa de la especificación, prevalece el GDD.
- `docs/ROADMAP.md`: fases, criterios de aceptación, estado y decisiones que bloquean cada fase.

## Estado actual

*Actualizado: 26-09-2026.*

- **Fase 2: en curso** (plan del 26-09-2026 en `docs/ROADMAP.md`). Ampliada a "Menús, guardado y cooperativo local": adelanta de la fase 5 el guardado, los menús, la selección de personaje, el mapa de niveles, la tienda y los compañeros (D-22 a D-25 en el GDD). Cuatro personajes jugables: Dyer, Olmstead, Legrasse y Johansen.
  - **Hito 2.1 (guardado y portada): hecho.**
    - La portada dice "Pulsa Start" y acepta cualquier botón principal.
    - Después, la ventana de tres huecos de partida, con tiempo jugado, objetos comprados, compañeros y dinero, y un botón de borrar con confirmación.
    - La partida suma al hueco el tiempo jugado, las partidas, las caídas, los enemigos abatidos y los niveles superados.
  - **Hito 2.2 (menú principal y configuración): hecho.**
    - Tras elegir hueco, el menú principal bajo el título: Jugar (local; online atenuado con "Próximamente"), Tienda (aviso hasta el hito 2.9), Configuración y Salir.
    - Configuración en cuatro pestañas:
      - Vídeo: pantalla completa, tamaño de la ventana, sincronización vertical, límite de FPS y resolución del 3D.
      - Audio: volumen general, de música y de efectos.
      - Controles: reasignar teclado y mando, con intercambio si la tecla estaba ocupada.
      - Juego: distorsiones, vibración y contador de FPS.
    - En la partida, "Salir" pasa a ser "Menú principal": guarda y vuelve al menú.
  - **Hito 2.3 (selección de personaje y mapa de niveles): hecho.**
    - "Jugar en local" abre la selección: cuatro marcos, uno por jugador, con el personaje en 3D, su arma, su rasgo y sus estadísticas.
    - El J1 entra con el dispositivo que usó en los menús; los demás se unen con Start (el teclado, con Intro).
    - Cada uno maneja su marco con su propio mando: personaje, compañero debajo del marco y "¡Listo!". Un personaje confirmado no lo puede coger otro ("Lo lleva J1"). B deshace un paso y, desde el primero, deja el puesto libre.
    - Con todos listos, el mapa de los 15 niveles: solo el 1 abierto, el siguiente se abre al superar el anterior y los que aún no existen salen como "Próximamente".
    - La partida usa el dispositivo, el personaje y el nivel del J1. Los demás jugadores entran en la partida en el hito 2.5.
  - **Hito 2.4 (personajes nuevos): hecho, pendiente de tu revisión.**
    - Olmstead, Legrasse y Johansen, a bloques limpios como Dyer, con su esquive, arma y rasgo.
    - Esquives: Dyer desliza, Olmstead rueda (impulso un 30 % más largo), Legrasse salta y Johansen se tira en plancha.
    - Armas nuevas: la escopeta (abanico de 5 perdigones que empuja) y el machete (tajo circular que solo golpea si hay alguien cerca).
    - Rasgos como datos (`resist_tags`, `bonus_tags` y `knockback_immune` en `CharacterData`; `tags` en `EnemyData`). Se notarán cuando lleguen criaturas marinas y humanas; en el nivel 1 no hay.
    - Hojas de revisión: `shots/revision_2_4_personajes.png` (cuatro giros) y `shots/revision_2_4_seleccion.png`.
  - **Cambios pedidos tras el hito 2.4 (26-09-2026):**
    - Balas enemigas en voxel 3D, con colores apagados por tipo de daño (físico en rojos, naranjas y amarillos; mental en morados y lilas) y más pequeñas en las criaturas de nivel bajo.
    - Horda sobre todo de cuerpo a cuerpo: tres pingüinos por cada fragmento, y los fragmentos disparan cada 9 s.
    - Arena sin vacío: barrera de hielo al norte y al oeste, meseta nevada detrás, mar visible al sur y al este, y los témpanos flotando a la altura del agua.
  - **Hito 2.4b, primera tanda (siete personajes más, D-26): hecha, pendiente de tu revisión.**
    - Amelia Peaslee (arqueóloga, rifle de caza que atraviesa), Madame Ludmila Varga (espiritista, páginas del Necronomicón que orbitan), Dra. Marian Whipple (doctora, abanico de bisturís) y Henrietta Blake (escritora, rayo del Trapezoedro).
    - Son de la tienda (`in_shop`); mientras no exista la tienda se pueden elegir. En la selección salen después de los cuatro de siempre (`order`).
    - Rasgos que ya funcionan: suerte (a veces una cuarta opción de mejora) y radio de recogida de Peaslee, cordura de las armas arcanas a la mitad (Varga), curación al subir de nivel (Whipple) y más experiencia por gema (Blake). La reanimación rápida de Whipple llegará con la reanimación (hito 2.6).
    - Hojas de revisión: `shots/revision_2_4b_personajes.png` y `shots/revision_2_4b_seleccion.png`.
  - **Hito 2.4b, segunda tanda: hecha, pendiente de tu revisión.**
    - Padre Iwanicki (fórmula de expulsión: onda dorada que empuja y aturde), sargento Frank Elwood (Colt .45 en ráfagas de tres) y Vera Malone (Thompson que barre en arco).
    - Rasgos: Elwood recibe un 15 % menos de daño físico y recarga el esquive un 20 % antes; Malone hace hasta un 50 % más de daño a quemarropa. El aura del padre (cordura a los compañeros cercanos) llegará con la cordura completa (hito 2.7).
    - Hojas de revisión: `shots/revision_2_4b_tanda2.png` y `shots/revision_2_4b_tanda2_seleccion.png`.
  - **Partida de pruebas:** el hueco 3 tiene todo desbloqueado (`SaveData.unlock_all`: personajes, compañeros, niveles y lo que se añada) y 999.999 de dinero. Se rehace con `godot --path . -- test_save=3` (sustituye lo que haya en ese hueco).
  - **Plan ampliado (27-09-2026, D-27 a D-34):** atributos, 29 armas nuevas, 4 armas y 4 objetos por personaje, personajes de inicio 2+2, dólares y tienda de antigüedades con baúles arcanos, logros, clima estético y vestuario. Hitos 2.5 a 2.16 en `docs/ROADMAP.md`.
  - **Hito 2.5 (atributos): hecho.**
    - Siete atributos (`Attributes`, `scripts/player/attributes.gd`): POD, INT, FUE, CON, TEN, DES y CUL (cultura), a 10 más un reparto de 20 puntos por personaje (`CharacterData.attr_bonus`, tabla en el GDD, 6.1).
    - La vida, la cordura, el esquive, la velocidad y el daño por tipo de arma salen de sumas de dos atributos. `Player.rebuild_stats()` lo rehace todo desde la base (atributos, estilo de esquive, pasivas y depuración).
    - Al subir de nivel, +1 en un atributo con la probabilidad del nivel 1; se anuncia en el menú de mejoras ("Nivel 3 · +1 Cultura").
    - Un arma al empezar; como mucho 4 armas y 4 objetos distintos (`PlayerProgress.weapon_slots` e `item_slots`).
    - De inicio: Dyer, Olmstead, Peaslee y Whipple. Legrasse y Johansen pasan a la tienda.
    - La selección de personaje muestra las estadísticas derivadas y los atributos.
  - **Hito 2.6 (arsenal I): hecho.**
    - Armas fusionadas (D-29), que sustituyen a las antiguas: Webly Mk VI (Olmstead), Stielhandgranate (Dyer, explota al impacto; ya lleva dos en el cinturón), escopeta de corredera (Legrasse, perdigones en anillo), rifle de palanca (Peaslee), Mauser C96 (Elwood) y Thompson M1928 (Malone).
    - Armas nuevas: Flammenwerfer (chorro en cono que deja fuego), Cóctel Molotov (charco ardiente), arpón ballenero (atraviesa y arrastra), pistola de bengalas (atrae a los enemigos; las élites no), lanzaquímicos (ácido que deja vulnerables con +25 % de daño) y cañón de fuegos artificiales (errático, se abre en chispas).
    - Sistemas nuevos: `DamageZone` (fuego y ácido), `Flare`, `FlameJet`, estados de los enemigos (`make_vulnerable`, `lure`, `stun`), balas que se dividen (`split`) y lanzados configurables (`ThrownExplosive.configure`: aspecto, arco, zona, bengala; con mecha 0 explotan al impactar).
  - **Estilo 4 de personajes (aprobado el 28-09-2026), en curso:**
    - Base común en `tools/cuerpo.py`, a 48 voxels por metro: anatomía realista de caras planas (tramos que se estrechan con chaflanes de 1 voxel, sin formas redondas ni grano por bloques, que hacían escalones y rayas), cabeza algo grande, manoplas en pinza estilo LEGO, codos y rodillas, y texturas por material (`tools/materiales.py`). `b` ensancha el tronco (0 Dyer, −2 trajes, +3 corpulentos).
    - Manos (`cuerpo.hand_`, referencia del autor del 28-09-2026): mano de voxel en reposo con el brazo caído. La palma mira al muslo; cuatro dedos de 2 voxels (el corazón más largo) separados por un borde más oscuro, que se curvan hacia la palma en la punta; pulgar delante, hacia abajo. Gruesa y tan ancha como la manga, a lo muñeco. Pegada al puño: solo asoma 1 fila de muñeca (con 3, los brazos parecían largos y la ropa pequeña). `mitten=True` junta los dedos (manoplas de Dyer). Cada personaje le da su color (piel o guante). Descartadas: la pinza LEGO en C (hacia delante, postura forzada; hacia dentro, seguía sin convencer) y dedos de 1 voxel (palillos).
    - Alas de sombrero: como mucho 2,5 voxels por delante y con el borde a la altura 78 o más; los ojos van en 72-75. A los lados pueden asomar más (casco Brodie).
    - **Primera tanda (hombres) hecha, pendiente de tu revisión:** Dyer, Olmstead, Legrasse, Johansen, Elwood e Iwanicki. Hojas `shots/revision_estilo4_tanda1a.png` y `tanda1b.png`.
    - **Segunda tanda (mujeres) pendiente:** añadir a `cuerpo.py` el cuerpo de mujer y pasar a Peaslee, Varga, Whipple, Blake y Malone. `tools/humano.py` (estilo anterior) sigue en uso hasta entonces.
    - **Esquive de deslizamiento rehecho como entrada en plancha de fútbol** (`slide` en `anim_humano.gd`): gira sobre la cadera y queda casi tumbado, con la pierna delantera estirada a ras de suelo, la otra doblada debajo, la mano atrás en la nieve y el brazo alto. Pendiente de tu revisión (`shots/revision_esquive_plancha.png`).
    - Descartados: `gen_dyer_chibi.py` (demasiado a bloques) y `gen_dyer_v3.py` (formas redondas: escalones sueltos).
    - Ya en el juego: codos y rodillas en los 11, bufanda de Dyer y coleta de Peaslee; manos en pinza en los 5 que faltan por pasar; los personajes no se hunden en el suelo al esquivar (`Player._keep_above_ground`).
    - El autor tenía más cambios que quería hacer antes del hito 2.7: preguntárselos.
  - **Un rasgo por personaje (D-35, 29-09-2026): hecho.** Dyer, explosiones +25 % de radio (`explosion_radius_mult`); Olmstead, esquive largo; Peaslee, suerte; Whipple, reanima antes (llega con la reanimación); Elwood, −15 % de daño físico; Johansen, +25 % cuerpo a cuerpo (`melee_mult`); Iwanicki, aura de cordura a sí mismo y a los cercanos (`calm_aura`, radio `Player.CALM_RADIUS`). Un test comprueba que nadie tenga más de uno.
  - **Selección de personaje rehecha como ficha, pendiente de tu revisión** (`shots/seleccion_ficha2_001.5s.png`): modelo al doble de la escala de la partida (144 px/m, `MODEL_ZOOM`), arma arriba a la derecha, rol y rasgo, y dos columnas con iconos (diseño del autor, `resources/PantallasMenus/seleccion_jugador_info_personaje.png`, marco de 420×750): los siete atributos con su abreviatura y puntos de vida, de cordura, acción de esquiva, velocidad y ataques mágicos, físicos y balísticos con su nombre. Cada texto va en una casilla fija (`_slot`): el nombre y la descripción reducen la letra para caber en una línea (`_fit_line`) y el rasgo tiene sitio para dos, así que las tablas no se mueven al cambiar de personaje. Vida y cordura en valor absoluto; esquive, velocidad y daños como potenciador (+20 %). El recuadro del arma enseña `WeaponData.icon` (hueco "Arma" mientras no haya imagen; nombre y `description` en la descripción emergente). Descripciones emergentes con `TipIcon` (`scripts/ui/tip_icon.gd`): aparecen a los 0,45 s con el ratón encima, con el foco o marcadas con arriba/abajo en la selección (`cursor=N` para capturas); úsalo en todo icono de armas, objetos, atributos y estadísticas. Iconos recortados de tus dos láminas en `resources/PantallasMenus/iconos/ficha_*.png` (con prefijo: `CON` es un nombre reservado en Windows y Godot no lo abre).
  - Después: hito 2.7, arsenal II (arcanas y tecnología de los Mitos).
- **Fase 0: hecha.** GDD, hoja de ruta y las nueve decisiones que bloqueaban las fases 1 y 2.
- **Fase 1: hecha** (queda tu partida de 5 minutos como comprobación). Subhitos en `docs/ROADMAP.md`.
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
- **Pantalla de título (adelantada de la fase 5): segunda versión, pendiente de tu revisión.**
  - Es tu ilustración de la biblioteca, animada en 2D, con tu imagen del título encima.
  - Se abre con `godot --path .` sin argumentos o con `-- title`; hay vídeo con música en `shots/portada_2d_v3.mp4`.
  - Cambios de la primera revisión (26-09-2026):
    - Velas y farolillos separados. En las velas solo baila la llama, anclada en la mecha; los farolillos no se mueven, solo respiran su cristal y su halo.
    - Niebla del suelo rehecha: bancos grandes y suaves en perspectiva, sin grano.
    - Sin nubes en el ventanal.
    - Entrada del título desde una niebla con su silueta que se deshace a jirones.
    - Ceniza que cae por toda la sala.
  - Segunda revisión: niebla del suelo con movimiento bien visible (antes variaba un 1,8 % y no se percibía; ahora, un 20 %) y ceniza en tres tamaños y más abundante.
  - La portada 3D anterior (montañas y título voxel) se quitó; queda en el historial de git (commit `4809adb`).
- **Pantalla completa por defecto** (exclusiva, a la resolución del monitor). Las ejecuciones de prueba (`shots=`, `perf=`, `bot=`, visor, banco de pruebas y `--write-movie`) van en ventana; `window=true` y `fullscreen=true` lo fuerzan. La interfaz escala desde 1920×1080 (`stretch` en modo `canvas_items`). A 4K con 150 enemigos y 1.400 balas: 130 FPS de media.
- **Menú de depuración:** en la pausa, botón "Depuración". Permite cambiar:
  - Personaje, esquive, invulnerabilidad y velocidad al andar; vida, cordura y subida de nivel.
  - Nivel de cada arma (o quitarla) y de cada pasiva.
  - Enemigos en pantalla (los del nivel, 10, 50, 100 o 300), tipo, pausa de oleadas, matar a todos y lanzar el evento final.
  - Velocidad del juego, altura de la cámara, información en pantalla y música.
  - Los ajustes se conservan al reiniciar hasta "Restablecer todo".
- **Música:** en `resources/Music/`. La intro suena en la portada y `Musica_nivel1.mp3` en el nivel 1; los niveles sin música propia usan esa (`LevelData.music`).
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
godot --path . --write-movie shots/mov/f.png --fixed-fps 30 --quit-after 240 -- bot=circle   # vídeo en fotogramas PNG
godot --path . --disable-vsync -- bot=circle demo=14 perf=8                 # rendimiento de la partida
python tools/gen_acechador.py       # regenera models/acechador.json
python tools/gen_variantes.py       # regenera clasico, bruto, acechador (versión simple) y abisal
python tools/gen_dyer.py            # Dyer (personaje jugable); igual gen_pinguino.py y gen_fragmento.py
python tools/gen_olmstead.py        # Olmstead; igual gen_legrasse.py, gen_johansen.py, gen_peaslee.py, gen_varga.py, gen_whipple.py y gen_blake.py (base común en tools/humano.py)
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
  - `mute=true`: sin música (también en la portada).
  - `test_save=N`: crea la partida de pruebas (todo desbloqueado) en el hueco N y sale.
  - `saves=carpeta`: otra carpeta de partidas dentro de `user://` (capturas y pruebas sin tocar las tuyas). `slot=N`: juega con ese hueco.
  - `window=true` / `fullscreen=true`: fuerza ventana o pantalla completa.
  - `debug_menu=N`: abre la pausa y el menú de depuración a los N s (capturas).
- **Encadenar comandos:** un `godot ... | grep error` devuelve 1 cuando no hay errores, así que no lo encadenes con `&&`.

Nota: `gen_variantes.py` también escribe un `acechador.json` genérico que sobrescribiría el detallado. Ejecuta `gen_acechador.py` después, o renombra la salida.

## Pantalla de título (`scenes/title.tscn`, `scripts/title/`)

Tus imágenes en `resources/PantallasMenus/`: `fondo_titulo_sin_texto_1080p_definitivo.png` (en realidad a 4K, con mipmaps activados en su `.import`) y `Texto_titulo.png`. `fondo_con_titulo_completo.png` es solo la referencia de composición.

- **Máscaras** (`tools/gen_mascaras_portada.py`: analiza la ilustración en 4K y escribe a 1920×1080; revisión en `shots/mascaras_revision.png`):
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
- **Efectos breves en capturas:** un rayo de 0,35 s cada 2,2 s casi nunca cae en una captura a segundos redondos. Para comprobarlo, imprime cuándo se dispara y captura cada pocas centésimas alrededor de ese instante.
- **Pelo claro bajo la luz cálida:** un rubio platino se confundía con la piel, de frente y de espaldas. Pelo muy claro solo si el tono es claramente distinto de la piel; si no, oscuro.
- **Colores claros sobre la nieve:** un rayo aditivo o atenuado se pierde sobre el suelo blanco iluminado. Hace falta un núcleo opaco y saturado (naranja dorado) y dejar lo aditivo para el halo.
- **Includes de shaders:** un `varying` no se puede asignar dentro de una función auxiliar, ni siquiera en un `.gdshaderinc`. Se asigna en `vertex()`.
- **Fondo grande en voxel:** a 32 voxels por metro, una pared de 80 m tendría millones de voxels. La barrera se modela a 16 y se exporta a 8 por metro (`half_res`). A 16, el peor 1 % de fotogramas bajaba de 71 a 60 FPS; a 8, con el zoom de juego se ve igual.
- **Colores oscuros bajo la luna:** un agua con albedo de 0,05 sale negra del todo con la luz de luna. Para que un fondo oscuro se lea como agua hace falta un albedo de 0,15 a 0,3.
- **Alas y viseras en isométrica:** la cámara mira desde arriba, así que un ala o una visera que sobresale 3 voxels tapa las dos filas de la cara que quedan debajo, y desaparecen los ojos. Como mucho 2 voxels de ala, y los ojos una fila más abajo (`face(..., eye_y=47)` en `tools/humano.py`).
- **Colores de personajes bajo luz cálida:** un rubio claro se confunde con la piel, y dos tonos oliva distintos se ven iguales. Hay que separar los personajes por valor (claro, medio y oscuro) además de por tono.
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
- **Turbulencia en `ParticleProcessMaterial`:** arrastra la velocidad de cada partícula hacia la del campo de ruido en cada paso. Con influencias normales (0,05-0,1), las partículas lentas se quedan paradas donde nacen; por eso no se veían las motas de la primera portada. Para caídas lentas, influencia de 0,002-0,006.
- **`preprocess` en partículas de vida larga:** no llegaba a repartir la ceniza por la pantalla. Es más fiable emitir en una caja que cubra toda la zona, con fundido de entrada y salida en la rampa de color.
- **Niebla en shader:** el ruido de valores con umbrales (`smoothstep` estrecho) da grano y formas en cuadrícula que se ven artificiales. Funciona mejor:
  - Ruido de gradiente con octavas giradas, y pocas octavas.
  - Formas grandes y alargadas, con perspectiva.
  - Modular la niebla pintada (aclararla y oscurecerla) en vez de añadir otra capa encima.
- **Llamas animadas sobre una ilustración:** la cera junto a la llama también es clara y cálida.
  - La llama se separa cortando cada mancha por el cuello de la mecha: donde la anchura se estrecha o salta al borde de la vela.
  - El desplazamiento crece de 0 en la base a 1 en la punta, con margen a los lados y por encima, pero nunca por debajo.
- **Aviso de recursos sin liberar con música:** al forzar la salida con `--quit-after` con música sonando, a veces sale `1 resources still in use at exit`. Es intermitente y no aparece con `mute=true`.
- **Sutil no es invisible:** una variación del 1,8 % de brillo no se percibe en movimiento. Para que una animación de ambiente se note hace falta del orden del 10-20 % en su zona.
- **Movimientos lentos de un `Control`:** Godot redondea su posición a píxeles enteros (`gui/common/snap_controls_to_pixels`), así que un zoom o un desplazamiento lento avanza a saltos y parece que la imagen vibra; en la portada eran saltos de 2 px a 4K. Anímalos en un `Node2D` padre, que no se redondea. Para comprobarlo, mide el desplazamiento entre fotogramas con correlación de fase.
- **Grabar en pantalla completa exclusiva:** si la ventana pierde el foco, Godot deja de dibujar y `--write-movie` repite el último fotograma. Graba en ventana.
- **Pantalla completa en Windows:** `WINDOW_MODE_FULLSCREEN` deja la ventana 1-2 píxeles más pequeña que el monitor; usa `WINDOW_MODE_EXCLUSIVE_FULLSCREEN`.
- **Grabar vídeo en pantalla completa:** con `--write-movie` a 4K cada fotograma tarda 2,5 s. `Engine.get_write_movie_path()` sirve para detectar la grabación y quedarse en ventana. Buscar `--write-movie` en `OS.get_cmdline_args()` no funciona.
- **`cat` sin entrada:** un `cat > fichero` sin heredoc se queda esperando la entrada estándar para siempre.

## Por definir

Las decisiones abiertas están en `docs/GDD.md` (sección 12), con la fase a la que bloquea cada una. Música y sonido solo tienen pautas sueltas (el susurro de los ataques mentales); el audio llega en la fase 8.
