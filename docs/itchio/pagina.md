# Página de itch.io (hitos 8.5, 13.17 y 22.8)

Material para la página del juego en itch.io. Las imágenes están en esta carpeta:
- `portada_630x500.png`: imagen de portada (Cover image, 630 × 500). `portada_630x500_ilustracion.png`, la de antes (la ilustración sola, sin los efectos de la portada del juego), por si la prefieres.
- `cabecera_1920x1080.png`: imagen de fondo o cabecera de la página.
- `capturas/01.png` a `05.png`: capturas de juego (1920 × 1080, calidad Alta, con la interfaz en español); `capturas_en/`, las mismas con el juego en inglés. Se rehacen con `sh tools/capturas_itch.sh es` (o `en`) y `python tools/montar_itch.py`.
- `capturas/trailer.gif`: el GIF del tráiler (7 s, sin rótulos), para subirlo como una captura más.
- Tráiler: `shots/videos/trailer.mp4` y `trailer_en.mp4` (84,6 s, 1080p, hito 22.7). itch.io no aloja vídeo: súbelo a YouTube (o Vimeo) y pega el enlace en «Gameplay video or trailer» al editar la página.

La página lleva el texto en los dos idiomas: primero el inglés (lo lee más gente en itch.io) y debajo el español. Si prefieres dos páginas, una por idioma, cada mitad vale sola.

## Datos del proyecto

- **Título:** Lovecraft Library: Surviving Cthulhu
- **URL propuesta:** `lovecraft-library-surviving-cthulhu`
- **Tipo:** juego descargable. **Estado:** en desarrollo (versión temprana).
- **Plataformas:** Windows y macOS (Linux, sin probar aún en un equipo con pantalla: mejor no marcarlo hasta entonces).
- **Género:** Shooter. **Etiquetas** (itch.io deja diez): bullet-hell, roguelite, survivors-like, lovecraft, cosmic-horror, voxel, local-co-op, online-co-op, isometric, horror.
- **Multijugador:** cooperativo de 1 a 4 jugadores, en local (mando o teclado) o en línea.
- **Idiomas:** español e inglés.
- **Precio:** sin decidir (gratis o «paga lo que quieras» para la versión temprana).

## In English

### Short description (one line)

Co-op cosmic-horror bullet hell: survive Lovecraft's creatures from Antarctica to Innsmouth, R'lyeh and the Dreamlands.

### Description

> "The most merciful thing in the world, I think, is the inability of the human mind to correlate all its contents."

In the Library of Miskatonic University, a handful of investigators have begun to correlate them.

**Lovecraft Library: Surviving Cthulhu** is an isometric voxel bullet hell with automatic fire and *survivors*-style progression, for 1 to 4 players in local or online co-op. Pick an investigator, survive the waves, level up, combine weapons and items… and try not to lose your mind.

**Four tales, twenty levels, four great bosses**
- *At the Mountains of Madness*: from the coast of the Ross Sea to the cyclopean city of the Elder Things and the primordial shoggoth.
- *The Shadow over Innsmouth*: the Newburyport road, the temple of the Esoteric Order of Dagon, the escape across the rooftops, the marshes and Devil Reef, where Father Dagon waits.
- *The Call of Cthulhu*: Wilcox's studio, the ritual in the Louisiana swamps, the docks of the *Alert*, the storm on the Pacific… and R'lyeh.
- *The Dream-Quest of Unknown Kadath*: the enchanted wood and the cats of Ulthar, the black galleys of Dylath-Leen, the plateau of Leng, the vaults of Zin and the onyx castle of Kadath, where Nyarlathotep takes three shapes.

**And five standalone nights**, outside the campaign: *The Colour Out of Space*, *The Dunwich Horror*, *The Shadow Out of Time*, *The Music of Erich Zann* and *The Haunter of the Dark*, each with its own rules.

**Features**
- 21 investigators, each with their own weapon, dodge and trait: Dyer, Armitage, Herbert West, Pickman, Kuranes, Edward Derby (and Asenath)… and two secret ones.
- 58 firearms, physical and magical weapons with 116 evolutions, and 58 items; the arcane ones cost sanity.
- Health and sanity: madness crises freeze you, make you flee or invert your controls, and coming out of one can bring a revelation.
- Local or online co-op with shared experience, reviving your partners, bonds between investigators and combos between everyone's weapons.
- More than 90 creatures, elites with traits and mid-level bosses; 16 animal companions that learn tricks.
- Necronomicon pacts, Elder Signs, mid-level objectives, events in the night, hallucinations at low sanity, the investigator's diary and loose pages to find.
- Endless night, daily run, boss rush, expeditions and 21 challenges.
- Antique shop with permanent upgrades and outfits; the Library, with the bestiary, the arsenal, the places, the investigator's manual and your account's statistics.
- Accessibility: interface size, high-contrast bullets, fewer flashes and screen shake, adjustable game speed and difficulty from 1 to 10.

**Controls:** gamepad (recommended) or keyboard. Move and dodge; firing is automatic.

### System requirements

- **OS:** Windows 10 or 11 (64-bit), or macOS 11 or later (Apple Silicon or Intel). The macOS build is not signed by Apple: the first time, right-click → Open.
- **Graphics:** a Vulkan-capable card with 2 GB of video memory on Low (4 GB on High).
- **Memory:** 4 GB of RAM (8 GB recommended). The game itself uses about 1.1 GB at its busiest.
- **Processor:** a 4-core CPU from the last ten years. With 80 or more creatures on screen the game leans on the processor more than on the graphics card.
- **Storage:** 1 GB (the download is about 410 MB).
- **Controls:** gamepad recommended (Xbox, PlayStation or similar); keyboard works too. Local co-op needs one gamepad per extra player.
- The first launch takes a few seconds longer while the game prepares its models.

### Credits

- A game by Sergio Sánchez Custodio. Made with Godot 4.4.
- Based on the stories of H. P. Lovecraft (public domain in the European Union). Not affiliated with "Call of Cthulhu", a trademark of Chaosium.
- Developed with the help of artificial intelligence: code, voxel models (generated by programs) and texts with Claude (Anthropic), under the author's direction; icons, menu ornaments, portraits and the illustrated endings with FLUX (Black Forest Labs). Title and shop illustrations by the author.
- Sound effects: Kenney (kenney.nl, CC0) and synthesised. Music: by the author and CC0 tracks from OpenGameArt (full list in the game). Fonts: IM FELL English SC and EB Garamond (SIL Open Font License 1.1).
- © 2026 Sergio Sánchez Custodio. Code under the GPLv3; art, original music, texts and the game's name: all rights reserved.

## En español

### Descripción corta (una línea)

Bullet hell cooperativo de horror cósmico: sobrevive a las criaturas de Lovecraft de la Antártida a Innsmouth, R'lyeh y las Tierras del Sueño.

### Descripción

> «Lo más misericordioso del mundo es la incapacidad de la mente humana para relacionar todo lo que contiene.»

En la Biblioteca de la Universidad de Miskatonic, unos cuantos investigadores han empezado a relacionarlo.

**Lovecraft Library: Surviving Cthulhu** es un bullet hell isométrico en voxel, con disparo automático y progresión al estilo *survivors*, para 1 a 4 jugadores en cooperativo local o en línea. Elige investigador, sobrevive a las oleadas, sube de nivel, combina armas y objetos… y no pierdas la cordura.

**Cuatro relatos, veinte niveles y cuatro grandes jefes**
- *En las montañas de la locura*: de la costa del mar de Ross a la ciudad ciclópea de los Antiguos y el shoggoth primigenio.
- *La sombra sobre Innsmouth*: la carretera de Newburyport, el templo de la Orden de Dagon, la huida por los tejados, los pantanos y el Arrecife del Diablo, donde aguarda Padre Dagon.
- *La llamada de Cthulhu*: el estudio de Wilcox, el ritual en los pantanos de Luisiana, los muelles del *Alert*, la tormenta en el Pacífico… y R'lyeh.
- *La búsqueda onírica de la desconocida Kadath*: el bosque encantado y los gatos de Ulthar, las galeras negras de Dylath-Leen, la meseta de Leng, las bóvedas de Zin y el castillo de ónice de Kadath, donde Nyarlathotep toma tres formas.

**Y cinco noches sueltas**, fuera de la campaña: *El color que cayó del cielo*, *El horror de Dunwich*, *La sombra fuera del tiempo*, *La música de Erich Zann* y *El que acecha en la oscuridad*, cada una con sus propias reglas.

**Características**
- 21 investigadores, cada uno con su arma, su esquive y su rasgo: Dyer, Armitage, Herbert West, Pickman, Kuranes, Edward Derby (y Asenath)… y dos secretos.
- 58 armas de fuego, físicas y mágicas con 116 evoluciones, y 58 objetos; las arcanas cuestan cordura.
- Vida y cordura: las crisis de locura te paralizan, te hacen huir o invierten los controles, y al salir de una puede llegar una revelación.
- Cooperativo local o en línea con experiencia compartida, reanimación de compañeros, vínculos entre investigadores y combinaciones entre las armas de unos y otros.
- Más de 90 criaturas, élites con rasgos y jefes a mitad de nivel; 16 compañeros animales que aprenden trucos.
- Pactos del Necronomicón, Signos Mayores, objetivos a mitad de nivel, sucesos de la noche, alucinaciones con poca cordura, el diario del investigador y páginas sueltas por encontrar.
- La noche eterna (sin fin), la partida del día, el desfile de jefes, las expediciones y 21 desafíos.
- Tienda de antigüedades con mejoras permanentes y vestuario; la Biblioteca, con el bestiario, el arsenal, los lugares, el manual del investigador y las estadísticas de tu cuenta.
- Accesibilidad: tamaño de la interfaz, balas de alto contraste, menos destellos y temblores, velocidad del juego y dificultad del 1 al 10.

**Controles:** mando (recomendado) o teclado. Muévete y esquiva; el disparo es automático.

### Requisitos

- **Sistema:** Windows 10 u 11 de 64 bits, o macOS 11 o posterior (Apple Silicon o Intel). La build de macOS no lleva la firma de Apple: la primera vez, clic derecho → Abrir.
- **Gráfica:** compatible con Vulkan, con 2 GB de memoria de vídeo en calidad Baja (4 GB en Alta).
- **Memoria:** 4 GB de RAM (8 GB recomendados). El juego usa como mucho 1,1 GB.
- **Procesador:** de 4 núcleos y de los últimos diez años. Con 80 criaturas o más en pantalla, el juego tira más del procesador que de la gráfica, y más de la velocidad de cada núcleo que de cuántos tenga.
- **Espacio:** 1 GB (la descarga, unos 410 MB).
- **Controles:** mando recomendado (de Xbox, PlayStation o parecido); también teclado. En cooperativo local, un mando por cada jugador de más.
- La primera vez tarda unos segundos más en arrancar, mientras prepara los modelos.

### Créditos (para el pie de la página)

- Un juego de Sergio Sánchez Custodio. Hecho con Godot 4.4.
- Basado en los relatos de H. P. Lovecraft (dominio público en la Unión Europea). Sin relación con «Call of Cthulhu», marca de Chaosium.
- Desarrollado con ayuda de inteligencia artificial: código, modelos voxel generados por programas y textos con Claude (Anthropic), bajo la dirección del autor; iconos, adornos de los menús, retratos y finales ilustrados con FLUX (Black Forest Labs). Ilustraciones de la portada y la tienda, del autor.
- Efectos de sonido: Kenney (kenney.nl, CC0) y sintetizados. Música: del autor y pistas CC0 de OpenGameArt (lista completa en el juego). Fuentes: IM FELL English SC y EB Garamond (SIL Open Font License 1.1).
- © 2026 Sergio Sánchez Custodio. Código con licencia GPLv3; arte, música propia, textos y nombre del juego: todos los derechos reservados.

## Demo (hito 13.17)

Build aparte, en la misma página (otro canal de descarga) o en una página propia.

- **Qué entra:** la parte 1 entera (*En las montañas de la locura*, cinco niveles hasta el shoggoth primigenio), los cuatro investigadores de inicio (Dyer, Olmstead, Peaslee y Whipple), la tienda (sin los demás personajes) y el cooperativo local de 1 a 4. No entran el juego en línea, la partida del día ni la noche eterna. Lo demás se ve con el cartel «En el juego completo», y al vencer al shoggoth, el relato del fin de la demo.
- **La partida se conserva:** demo y juego completo guardan en el mismo sitio, así que al pasar al juego completo se sigue donde se dejó.
- **Texto para el archivo de la demo:** «Demo: la Antártida entera, cuatro investigadores y cooperativo local de 1 a 4» · «Demo: all of Antarctica, four investigators and local co-op for 1 to 4».
- **Builds:** `sh tools/exportar.sh` las hace en `builds/demo/` (perfiles «Windows Demo» y «macOS Demo», con la etiqueta `demo`); las de GitHub Actions las dejan en la Release como `LovecraftLibrary-<versión>-demo-windows.zip` y `-demo-macos.zip`.

## Cómo se midieron los requisitos (hito 22.8, 18-11-2026)

Build de Windows de la versión 0.9.0 (`sh tools/exportar.sh`), en 1920 × 1080, en este PC (i7-10700K de 8 núcleos, RTX 3070 Ti, 32 GB), con la partida más pesada: cuatro jugadores en Kadath contra Nyarlathotep, hasta 120 enemigos, 110 s (`tools/medir_memoria.ps1`, con el proceso en el escritorio aparte).

| Calidad | RAM máxima | Memoria de vídeo dedicada | Compartida |
|---|---|---|---|
| Alta | 983 MB | 869 MB | 205 MB |
| Baja | 1105 MB | 614 MB | 333 MB |

- En Baja, la RAM sale algo más alta: la gráfica tira de memoria compartida. Lo mismo en una gráfica con poca memoria propia o integrada.
- **Tamaño:** el `.exe` ocupa 520 MB (en octubre, 248; desde entonces han entrado la parte 4, las noches, los retratos, los finales y la música). Comprimido, unos 410 MB, que es lo que bajará quien lo descargue con la app de itch.io o desde la página. La demo pesa lo mismo: lleva todo y el resto se cierra por la etiqueta `demo`.
- **Rendimiento** (hito 22.2, Alta, PC libre, 80 enemigos): de 8,5 a 9,7 ms por fotograma de media (más de 100 fps) y unos 20 ms en el 1 % peor. El dibujo se queda en 3-7 ms y el resto es la lógica (CPU); de ahí, el procesador de 4 núcleos y la gráfica modesta.
- **Con 4 núcleos (hito 23.7, 19-11-2026):** en Baja a 1280 × 800, limitando el juego a cuatro núcleos (`tools/afinidad.py`), el 1 % peor queda en 19-23 ms (también en cooperativo de cuatro), igual que con los 16: el número de núcleos no es lo que limita. Detalle en `docs/ESTADO.md`.
- **Lo que no se ha medido:** el juego no se ha probado en una gráfica más débil que esta ni en un Mac. Los mínimos de gráfica y procesador son una estimación a partir de esas cifras. Si alguien juega con menos, sus datos (Opciones → Vídeo → rendimiento detallado) dirán si hay que cambiarlos.

## Subida con butler

1. Crea el proyecto en itch.io con la URL de arriba (como borrador).
2. Instala butler (https://itch.io/docs/butler/) y haz `butler login` una vez, o guarda la clave de API en `.env` como `BUTLER_API_KEY` (no va a git).
3. Genera las builds: `sh tools/exportar.sh`.
4. Sube cada canal:
   - `butler push builds/windows <usuario>/lovecraft-library-surviving-cthulhu:windows`
   - `butler push builds/macos <usuario>/lovecraft-library-surviving-cthulhu:mac`
   - Demo: `butler push builds/demo/windows <usuario>/lovecraft-library-surviving-cthulhu:demo-windows` y `butler push builds/demo/macos <usuario>/lovecraft-library-surviving-cthulhu:demo-mac`. En la página, marca esos dos archivos como «Demo».
5. Con `--userversion 0.9.0` butler pone la versión del juego a cada subida (la de `project.godot`).
