# Página de itch.io (hito 8.5)

Material para la página del juego en itch.io. Las imágenes están en esta carpeta:
- `portada_630x500.png`: imagen de portada (Cover image, 630 × 500).
- `cabecera_1920x1080.png`: imagen de fondo o cabecera de la página.
- `capturas/01.png` a `07.png`: capturas de juego (1920 × 1080).

## Datos del proyecto

- **Título:** Lovecraft Library: Surviving Cthulhu
- **URL propuesta:** `lovecraft-library-surviving-cthulhu`
- **Tipo:** juego descargable. **Estado:** en desarrollo (versión temprana).
- **Plataformas:** Windows y macOS.
- **Género:** Shooter (bullet hell). **Etiquetas:** bullet-hell, roguelite, survivors-like, lovecraft, cthulhu, horror, voxel, local-co-op, isometric, cosmic-horror.
- **Multijugador:** cooperativo local de 1 a 4 jugadores (mando o teclado).
- **Idioma:** español.
- **Precio:** sin decidir (gratis o "paga lo que quieras" para la versión temprana).

## Descripción corta (una línea)

Bullet hell cooperativo de horror cósmico: sobrevive a las criaturas de Lovecraft de la Antártida a Innsmouth y hasta R'lyeh.

## Descripción

> «Lo más misericordioso del mundo es la incapacidad de la mente humana para relacionar todo lo que contiene.»

En la Biblioteca de la Universidad de Miskatonic, unos cuantos investigadores han empezado a relacionarlo.

**Lovecraft Library: Surviving Cthulhu** es un bullet hell isométrico en voxel, con disparo automático y progresión al estilo *survivors*, para 1 a 4 jugadores en cooperativo local. Elige investigador, sobrevive a las oleadas, sube de nivel, combina armas y objetos… y no pierdas la cordura.

**Tres relatos, quince niveles y tres jefes**
- *En las montañas de la locura*: de la costa del mar de Ross a la ciudad ciclópea de los Antiguos y el shoggoth primigenio.
- *La sombra sobre Innsmouth*: la carretera de Newburyport, el templo de la Orden de Dagon, la huida por los tejados, los pantanos y el Arrecife del Diablo, donde aguarda Padre Dagon.
- *La llamada de Cthulhu*: el estudio de Wilcox, el ritual en los pantanos de Luisiana, los muelles del *Alert*, la tormenta en el Pacífico… y R'lyeh.

**Características**
- 13 investigadores con su propia arma, esquive y rasgo: Dyer, Olmstead, Legrasse, Johansen, Armitage, Herbert West…
- Más de 30 armas de fuego, físicas y mágicas que evolucionan; las arcanas cuestan cordura.
- Vida y cordura: las crisis de locura te paralizan, te hacen huir o invierten los controles.
- Cooperativo local con experiencia compartida, reanimación de compañeros y menús por jugador.
- 15 compañeros animales (el gato de Ulthar, un shoggoth bebé, la araña de Tíndalos…).
- Tienda de antigüedades con mejoras permanentes, vestuario y la Biblioteca: el bestiario, el arsenal y los lugares, con notas de diario de los años 20.
- Peligros del escenario: agua que frena, olas que barren la cubierta y los Ángulos devoradores de R'lyeh.
- Opciones de accesibilidad: tamaño de la interfaz, balas de alto contraste, menos destellos y temblores.

**Controles:** mando (recomendado) o teclado. Muévete y esquiva; el disparo es automático.

## Créditos (para el pie de la página)

- Un juego de Sergio Sánchez Custodio. Hecho con Godot 4.4.
- Basado en los relatos de H. P. Lovecraft (dominio público en la Unión Europea). Sin relación con «Call of Cthulhu», marca de Chaosium.
- Desarrollado con ayuda de inteligencia artificial: código, modelos voxel generados por programas y textos con Claude (Anthropic), bajo la dirección del autor; iconos con FLUX (Black Forest Labs). Ilustraciones de portada y tienda, del autor.
- Efectos de sonido: Kenney (kenney.nl, CC0) y sintetizados. Música: del autor y pistas CC0 de OpenGameArt (lista completa en el juego).
- © 2026 Sergio Sánchez Custodio. Todos los derechos reservados.

## Requisitos

- **Windows:** Windows 10 u 11 de 64 bits, gráfica compatible con Vulkan. Un solo `.exe` (~250 MB).
- **macOS:** macOS 11 o posterior (Apple Silicon o Intel). Sin firma de Apple: la primera vez, clic derecho → Abrir.
- La primera partida tarda unos segundos más en arrancar (prepara los modelos).

## Subida con butler

1. Crea el proyecto en itch.io con la URL de arriba (como borrador).
2. Instala butler (https://itch.io/docs/butler/) y haz `butler login` una vez, o guarda la clave de API en `.env` como `BUTLER_API_KEY` (no va a git).
3. Genera las builds: `sh tools/exportar.sh`.
4. Sube cada canal:
   - `butler push builds/windows <usuario>/lovecraft-library-surviving-cthulhu:windows`
   - `butler push builds/macos <usuario>/lovecraft-library-surviving-cthulhu:mac`
