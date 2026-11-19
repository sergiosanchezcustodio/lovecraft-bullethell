<div align="center">

<img src="docs/img/portada.jpg" alt="La portada del juego: la biblioteca de la Universidad de Miskatonic a la luz de las velas, con el ventanal y la silueta de Cthulhu en la tormenta" width="100%">

# Lovecraft Library: Surviving Cthulhu

**Bullet hell isométrico en voxel 3D, con disparo automático y progresión *survivors*, para 1 a 4 jugadores en cooperativo local y online, ambientado en los mitos de H. P. Lovecraft.**

[![Godot 4.4](https://img.shields.io/badge/Godot-4.4.1-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
![GDScript](https://img.shields.io/badge/GDScript-tipado%20est%C3%A1tico-355570)
![Windows](https://img.shields.io/badge/Windows-x86__64-0078D6?logo=windows&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-universal-000000?logo=apple&logoColor=white)
![Jugadores](https://img.shields.io/badge/jugadores-1%E2%80%934%20local%20y%20online-8e44ad)
![Idiomas](https://img.shields.io/badge/idiomas-espa%C3%B1ol%20%C2%B7%20ingl%C3%A9s-c0392b)
![Tests](https://img.shields.io/badge/tests-GUT%20%C2%B7%201095%20en%20verde-2e7d32)
![Versión](https://img.shields.io/badge/versi%C3%B3n-0.9.0-e0a100)
[![Licencia: código GPLv3, recursos reservados](https://img.shields.io/badge/licencia-c%C3%B3digo%20GPLv3%20%C2%B7%20recursos%20reservados-blue)](LICENCIA.md)

**Español** · [English](README.en.md)

[Características](#características) · [Capturas](#capturas) · [Campaña](#la-campaña) · [Personajes](#personajes) · [Armas](#armas-y-objetos) · [Bestiario](#bestiario) · [Instalación](#instalación-y-ejecución) · [Desarrollo](#para-desarrolladores) · [Hoja de ruta](#hoja-de-ruta)

</div>

> *«Lo más misericordioso del mundo es la incapacidad de la mente humana para relacionar todo lo que contiene.»*
> — H. P. Lovecraft, *La llamada de Cthulhu*

En la Biblioteca de la Universidad de Miskatonic, unos cuantos investigadores han empezado a relacionarlo. De la Antártida a Innsmouth, de Innsmouth a R'lyeh y de R'lyeh a las Tierras del Sueño, algo muy antiguo ha empezado a despertar.

**Lovecraft Library** recorre cuatro relatos de Lovecraft (*En las montañas de la locura*, *La sombra sobre Innsmouth*, *La llamada de Cthulhu* y *La búsqueda onírica de la desconocida Kadath*) en veinte niveles y cuatro jefes colosales, y cuatro relatos más en noches sueltas. Las armas disparan solas: la habilidad está en **moverse y esquivar** entre hordas y cortinas de balas que dañan la **vida** o la **cordura**. Si la cordura llega a cero, llega la locura.

<div align="center">

<img src="docs/img/partida.gif" alt="Partida a cuatro jugadores en las calles de Innsmouth, bajo la lluvia, entre híbridos, acólitos y sacerdotes de la tiara" width="100%">

| 20 + 4 | 4 + 4 | 21 | 58 + 116 | 58 | 16 | 90+ | 1–4 |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| niveles y noches sueltas | jefes de la campaña y de las noches | investigadores | armas y sus evoluciones | objetos | compañeros | criaturas | jugadores, en local o por red |

</div>

> [!NOTE]
> **Versión 0.9.0, en desarrollo.** La campaña completa se juega de principio a fin: las cuatro partes y las cuatro noches sueltas, solo, en cooperativo local o por red, en español o en inglés. Quedan la música propia de la parte 4, la prueba por internet entre casas distintas, el equilibrio final con partidas de jugadores reales, la publicación en itch.io y activar el guardado en la nube, ya programado. El estado detallado está en la [hoja de ruta](#hoja-de-ruta).

## Índice

- [Características](#características)
- [Capturas](#capturas)
- [La campaña](#la-campaña)
- [Personajes](#personajes)
- [Compañeros](#compañeros)
- [Armas y objetos](#armas-y-objetos)
- [Bestiario](#bestiario)
- [Cómo se juega](#cómo-se-juega)
- [Instalación y ejecución](#instalación-y-ejecución)
- [Jugar online](#jugar-online)
- [Para desarrolladores](#para-desarrolladores)
- [Hoja de ruta](#hoja-de-ruta)
- [Derechos y créditos](#derechos-y-créditos)
- [Licencia](#licencia)

## Características

### Jugabilidad

- **Bullet hell con progresión *survivors*:** hordas que llegan desde fuera de la pantalla, patrones de balas con aviso en el suelo y armas que disparan solas. Cada nivel dura unos cinco minutos y termina con un evento final: un ser único, una horda a la que sobrevivir o uno de los cuatro jefes.
- **Vida y cordura:** los ataques físicos (rojos, naranjas y amarillos) quitan vida; los mentales (morados y lilas), cordura; los mixtos, las dos. La cercanía de los horrores también desgasta la mente.
- **Crisis de locura:** con la cordura a cero, el investigador sufre una de cinco crisis (parálisis, huida histérica, vagar sin rumbo, delirio con los controles invertidos o paranoia), con un aura morada y cara de pánico. Al salir de una crisis se elige una **revelación**, que dura lo que queda del nivel.
- **58 armas con dos evoluciones cada una:** de fuego, físicas y mágicas, cuatro a la vez (seis con las fundas de la tienda). Cada una sube del nivel 1 al 5 y, al máximo y con su objeto pareja, el siguiente baúl arcano deja elegir entre sus dos evoluciones. Las mágicas cuestan cordura, y las armas de distintos jugadores (o las tuyas entre sí) se **combinan** cuando coinciden.
- **58 objetos** que cambian las reglas: proyectiles, alcance, críticos, esquives dobles, escudos, señuelos, resurrección…
- **21 investigadores** con siete atributos, arma inicial, un rasgo propio y su estilo de esquive (deslizamiento, voltereta, plancha, salto, destello, el cuadro de Pickman, los ángulos de Gilman…), retrato al óleo y pose de victoria. Dos son secretos. Las parejas que se conocen en los relatos tienen **vínculos**: una pequeña ventaja mientras están cerca.
- **16 compañeros** que muerden, curan, roban, se tragan balas o se teletransportan, y aprenden dos trucos al nivel 5.
- **Escenarios vivos:** nevada, ventisca, niebla, lluvia y tormenta con rayos; agua que frena, olas que barren la cubierta, Ángulos devoradores que engullen a quien se queda dentro, baúles arcanos y decorado que se rompe; pájaros, murciélagos y bichos que reaccionan a la batalla.
- **Más que sobrevivir:** élites con rasgos, jefes a mitad de nivel, pactos del Necronomicón, Signos Mayores, objetivos a mitad de nivel, sucesos de la noche (luna de sangre, niebla, marea…), un buhonero y páginas sueltas del diario.
- **Dificultad del 1 al 10**, velocidad del juego regulable y, al vencer a Cthulhu, cinco **grados de locura** que endurecen la campaña uno tras otro.

### Cooperativo, local y online

- **De 1 a 4 jugadores** con mando o teclado en el mismo PC, por red entre varios PC, o mezclando las dos cosas (por ejemplo, dos en el sofá y otros dos, cada uno en su casa).
- Cámara compartida, **experiencia común** y subidas de nivel **por turnos**: sube un jugador cada vez, con una ventana de su color.
- Los caídos quedan derribados unos segundos y un compañero puede **reanimarlos**; quedarse junto a un compañero en crisis la acorta.
- **Online** con anfitrión y hasta tres PC invitados (ENet): sala por **código de 8 letras**, IP o apertura automática del puerto (UPnP), cada PC con su cámara y su guardado, y un bot que ocupa el sitio de quien se desconecta hasta que vuelve.

### Progreso y menús

- **Tres huecos de guardado**, con dinero, desbloqueos y logros por hueco, y **copia en la nube** con tu cuenta de GitHub (un gist secreto) para seguir en otro PC; si una partida ha cambiado en dos PC, el juego pregunta con cuál quedarse ([guía](docs/GUARDADO_NUBE.md)).
- **Tienda de antigüedades:** potenciadores permanentes, personajes, compañeros y **vestuario** (83 prendas que se ven sobre el modelo).
- **La Biblioteca:** bestiario vivo, arsenal, lugares, la sala de trofeos, el archivo de expediciones, el manual del investigador (con clips del juego) y las estadísticas de la cuenta, con notas de diario de los años 20.
- **39 logros** con recompensa, intro, **relatos** que cuentan cada nivel antes de jugarlo y un final ilustrado al acabar cada parte.
- **Más modos:** la noche eterna (sin fin), la partida del día, el desfile de jefes, las expediciones, 21 desafíos y la pesca en el muelle de Innsmouth.
- **Selección para cuatro a la vez:** cada uno se une con Start, elige personaje y compañero y los gira para verlos por todos lados.
- **Accesibilidad:** tamaño de la interfaz, balas de alto contraste, menos destellos, temblor de cámara y vibración regulables. Controles reasignables en mando y teclado.
- **En español y en inglés**, con selector en Configuración.

### Técnica

- **Todo el arte 3D se genera por código:** cada personaje, criatura, pieza de atrezo y escenario sale de un script de Python que coloca los voxels (48 por metro en personajes y compañeros). Nada se modela a mano en un editor.
- **Mallas voxel** con eliminación de caras ocultas, oclusión ambiental por vértice, capa emisiva y caché en disco. Animación por partes, sin *rigging*, con capas y fundidos.
- **Miles de balas sin un nodo por bala:** arrays compactos, rejilla espacial y `MultiMesh`. Efectos de armas en cubitos (llamas, humo, ácido, explosiones) con partículas compartidas.
- **Interpolación de física** para pantallas de más de 60 Hz, con la física a 60 Hz.
- **Datos antes que código:** personajes, armas, enemigos, patrones, niveles, escenarios, compañeros, objetos, logros, tienda y textos son recursos `.tres` o JSON. Un enemigo nuevo se añade sin tocar código.
- **Red con anfitrión con autoridad:** cada PC decide los golpes que reciben sus jugadores (lo que se esquiva en pantalla es lo que cuenta) y el anfitrión manda en el mundo, con fotos a 20 Hz interpoladas y unos 19 kB/s por invitado.
- **Equilibrio con simulaciones:** un bot que esquiva y elige mejoras (`SmartBot`) juega cientos de partidas en paralelo para medir cada nivel y cada dificultad.

## Capturas

| | |
|:---:|:---:|
| ![El campamento base en la costa del mar de Ross](docs/img/p1_campamento.jpg) | ![El paso de la cordillera](docs/img/p1_paso.jpg) |
| **Parte 1 · El campamento base.** Pingüinos albinos ciegos y fragmentos protoplásmicos entre la cabaña y las tiendas, en la costa del mar de Ross. | **Parte 1 · El paso de la cordillera.** Cristales, agujas de roca y shoggoths en la niebla de las cavernas. |
| ![La huida por los tejados](docs/img/p2_tejados.jpg) | ![Los pantanos y la vía muerta a Rowley](docs/img/p2_pantano.jpg) |
| **Parte 2 · La huida por los tejados.** La horda del Arrecife del Diablo sube al tejado del hotel Gilman House: hay que resistir un minuto. | **Parte 2 · La vía muerta a Rowley.** El terraplén del tren entre aguas que frenan y Profundos que salen de la ciénaga. |
| ![El estudio del escultor Wilcox](docs/img/p3_estudio.jpg) | ![El ritual en los pantanos de Luisiana](docs/img/p3_ritual.jpg) |
| **Parte 3 · El estudio de Wilcox.** Esculturas, caballetes y pesadillas de la oleada de sueños, en Providence. | **Parte 3 · El ritual del pantano.** Hogueras, cultistas armados del *Alert* y diablos con alas de murciélago. |
| ![La tormenta en el Pacífico](docs/img/p3_tormenta.jpg) | ![R'lyeh emergida](docs/img/p3_rlyeh.jpg) |
| **Parte 3 · La tormenta en el Pacífico.** Una ola barre la cubierta mientras sube la cosa blanca polipoide. | **Parte 3 · R'lyeh emergida.** Losas que no cuadran, primigenios menores y emanaciones de la puerta colosal. |
| ![El bosque encantado y las afueras de Ulthar](docs/img/p4_bosque.jpg) | ![La meseta de Leng](docs/img/p4_leng.jpg) |
| **Parte 4 · El bosque encantado.** Zoogs entre los robles y los hongos, y los gatos de Ulthar que bajan a ayudar. | **Parte 4 · La meseta de Leng.** Shantaks, arañas púrpura y sus redes, y el viento helado de Leng. |
| ![La granja de los Gardner](docs/img/noche_color.jpg) | ![La rue d'Auseil](docs/img/noche_zann.jpg) |
| **Noche suelta · El color que cayó del cielo.** La granja de los Gardner se agosta alrededor del pozo. | **Noche suelta · La música de Erich Zann.** La viola aparta a lo de fuera mientras suene; detrás de la ventana no está París. |

### Los jefes

| El shoggoth primigenio | Padre Dagon | Cthulhu | Nyarlathotep |
|:---:|:---:|:---:|:---:|
| ![El shoggoth primigenio](docs/img/jefe_shoggoth.jpg) | ![Padre Dagon](docs/img/jefe_dagon.jpg) | ![Cthulhu](docs/img/jefe_cthulhu.jpg) | ![Nyarlathotep](docs/img/jefe_nyarla.jpg) |
| Persigue por los túneles del mar subterráneo gritando «¡Tekeli-li!». | Emerge de las simas del Arrecife del Diablo, golpea con las manos y llama a los Profundos. | Asoma por la puerta de R'lyeh, barre con los tentáculos y, al caer, se recompone una vez. | Espera en lo alto de Kadath con tres formas: el faraón negro, el enjambre y el ser sin rostro. |

### Menús

| | |
|:---:|:---:|
| ![Selección de personaje a cuatro](docs/img/seleccion.jpg) | ![Mapa de la campaña](docs/img/mapa.jpg) |
| **Selección.** Hasta cuatro jugadores eligen a la vez personaje, vestuario y compañero, cada uno con su mando. | **El mapa.** Cuatro partes de cinco niveles unidas por un camino de tinta, y las noches sueltas aparte. |
| ![Relato del nivel](docs/img/relato.jpg) | ![Ficha del personaje](docs/img/ficha.jpg) |
| **Relatos.** Cada nivel se cuenta antes de jugarlo, sobre el mapa del lugar. | **La ficha** del personaje en partida: atributos, armas y objetos. |
| ![Tienda de antigüedades](docs/img/tienda.jpg) | ![La Biblioteca](docs/img/biblioteca.jpg) |
| **La tienda de antigüedades,** con el anciano tras el mostrador. | **La Biblioteca:** bestiario vivo, arsenal, lugares, trofeos, manual y estadísticas. |
| ![Logros](docs/img/logros.jpg) | ![Jugar online](docs/img/online.jpg) |
| **Logros,** con su recompensa y su progreso. | **Jugar online:** crear una sala o unirse con su código. |

## La campaña

Cuatro partes de cinco niveles. Cada nivel se abre al superar el anterior, y cada parte, al superar la anterior. Cada parte vuelve a empezar por las criaturas más débiles, pero es más difícil que la anterior contando con lo comprado en la tienda.

### Parte 1 · *En las montañas de la locura* (la Antártida)

<!-- tabla:parte1 -->
| Nivel | Criaturas | A mitad del nivel | Evento final |
|---|---|---|---|
| 1. Campamento base en la costa del mar de Ross | Pingüino albino ciego, Fragmento protoplásmico | — | Acechador |
| 2. El campamento destruido de Lake | Pingüino albino ciego, Fragmento protoplásmico, Antiguo revivido, Antiguo alado, Expedicionario de Lake | — | El primero en despertar |
| 3. El paso de la cordillera y sus cavernas | Pingüino albino ciego, Fragmento protoplásmico, Antiguo revivido, Antiguo alado, Shoggoth esclavo, Shoggoth mimético, Shoggoth excavador | Gedney, lo que queda de él | El shoggoth de la caverna |
| 4. La ciudad ciclópea de los Antiguos | Pingüino albino ciego, Fragmento protoplásmico, Antiguo revivido, Antiguo alado, Shoggoth esclavo, Antiguo guerrero, Antiguo mutilado, Antiguo sembrador | — | El guardián de la ciudad |
| 5. Los túneles y el abismo del mar subterráneo | Pingüino albino ciego, Fragmento protoplásmico, Shoggoth esclavo, Antiguo mutilado, Shoggoth de ojos luminosos, Antiguo del mar abisal, Shoggoth excavador, Antiguo sembrador | — | **Jefe: El shoggoth primigenio** |
<!-- /tabla -->

### Parte 2 · *La sombra sobre Innsmouth* (Nueva Inglaterra)

<!-- tabla:parte2 -->
| Nivel | Criaturas | A mitad del nivel | Evento final |
|---|---|---|---|
| 1. Newburyport y la carretera a Innsmouth | Pescador de Innsmouth, Vecina de Innsmouth, Viejo de Innsmouth, Acólito de la Orden de Dagon | — | El diácono de la Orden |
| 2. Las calles de Innsmouth y el templo de la Orden | Pescador de Innsmouth, Vecina de Innsmouth, Viejo de Innsmouth, Acólito de la Orden de Dagon, Híbrido avanzado, Híbrida avanzada, Sacerdote de la tiara, Guardián de la Orden de Dagon | — | El sumo sacerdote de la Orden |
| 3. El hotel Gilman House y la huida por los tejados | Profundo, Profundo escupidor, Híbrido avanzado, Híbrida avanzada, Acechador de los tejados, Guardián de la Orden de Dagon, Hija de los Marsh | El capitán Obed Marsh | Resistir 60 s a la horda |
| 4. Los pantanos y la vía muerta del tren a Rowley | Profundo, Profundo de la ciénaga, Profundo escupidor, Híbrido avanzado, Híbrida avanzada, Profundo anciano de Y'ha-nthlei, Nadador de la marea, Hija de los Marsh | — | Barnabas Marsh, transformado |
| 5. El Arrecife del Diablo y Y'ha-nthlei | Profundo, Profundo de la ciénaga, Profundo escupidor, Profundo anciano de Y'ha-nthlei, Híbrido avanzado, Nadador de la marea | Pth'thya-l'yi, la antepasada | **Jefe: Madre Hydra → Padre Dagon** |
<!-- /tabla -->

### Parte 3 · *La llamada de Cthulhu* (Providence, Luisiana y el Pacífico)

<!-- tabla:parte3 -->
| Nivel | Criaturas | A mitad del nivel | Evento final |
|---|---|---|---|
| 1. Providence: el estudio del escultor Wilcox | Pesadilla de la oleada de sueños, Cultista de Cthulhu, Sonámbulo de Providence | — | La pesadilla del bajorrelieve |
| 2. Los pantanos de Luisiana: el ritual del culto | Cultista de Cthulhu, Cultista armado del Alert, Diablo con alas de murciélago, Tamborilero del pantano, Ídolo vivo | El viejo Castro | El sacerdote del ritual |
| 3. Los muelles y la cubierta del Alert | Profundo, Profundo escupidor, Cultista de Cthulhu, Cultista armado del Alert, Ídolo vivo | Engendro de Cthulhu | El engendro mayor |
| 4. La tormenta en el Pacífico | La cosa blanca polipoide, Profundo, Cultista armado del Alert, Diablo con alas de murciélago, Sonámbulo de Providence | — | La cosa blanca del lago oculto |
| 5. R'lyeh emergida: la puerta colosal | Emanación de la puerta, Profundo, Cultista de Cthulhu | Primigenio menor | **Jefe: Cthulhu → Cthulhu, recompuesto** |
<!-- /tabla -->

### Parte 4 · *La búsqueda onírica de la desconocida Kadath* (las Tierras del Sueño)

Se abre al vencer a Cthulhu. Más color que las partes anteriores, sin dejar la noche, y cada nivel con lo suyo: los gatos de Ulthar, la galera negra que desembarca, las redes de las arañas, los ghasts que odian la luz, los descarnados que te llevan por el aire y las flautas de los Otros Dioses.

<!-- tabla:parte4 -->
| Nivel | Criaturas | A mitad del nivel | Evento final |
|---|---|---|---|
| 1. El bosque encantado y las afueras de Ulthar | Zoog, Zoog de las copas, Pesadilla de la oleada de sueños | — | El anciano del consejo de los zoogs |
| 2. El puerto de Dylath-Leen y la galera negra | Mercader de Leng, Remero lunar, Pesadilla de la oleada de sueños | — | El amo de la galera negra |
| 3. La meseta de Leng y el monasterio sin ventanas | Shantak, Araña púrpura de Leng, Mercader de Leng | El sumo sacerdote que no debe describirse | La madre de las arañas de Leng |
| 4. Las bóvedas de Zin y la torre de los gugs | Ghast, Gug | — | El gran gug de la torre de Koth |
| 5. La cima de Kadath y el castillo de ónice | Larva de los Otros Dioses, Descarnado nocturno | — | **Jefe: Nyarlathotep, el Caos reptante** |
<!-- /tabla -->

### Noches sueltas

Cuatro relatos más, fuera de la campaña, desde el botón «Noches sueltas» del mapa: un nivel con sus dos criaturas, su jefe, su relato y sus propias reglas.

<!-- tabla:noches -->
| Nivel | Criaturas | A mitad del nivel | Evento final |
|---|---|---|---|
| La granja de los Gardner | Res gris, Granjero consumido | — | **Jefe: El color que sube del pozo** |
| Sentinel Hill | Chotacabras de Dunwich, Devota de las colinas | — | **Jefe: El hermano de Wilbur** |
| Las ruinas de Pnakotus | Poseído de la Gran Raza, Pólipo volador | — | **Jefe: El pólipo antiguo** |
| La rue d'Auseil | Vecino de la rue d'Auseil, Jirón de la noche | — | **Jefe: Lo que hay tras la ventana** |
<!-- /tabla -->

- ***El color que cayó del cielo*:** la granja de los Gardner se agosta alrededor del pozo, y lo tocado por el color quita vida.
- ***El horror de Dunwich*:** lo que no se ve en Sentinel Hill solo deja huellas; el polvo de Ibn Ghazi lo descubre un momento.
- ***La sombra fuera del tiempo*:** los pólipos casi invisibles salen de las trampillas de Pnakotus, que se sellan de pie encima.
- ***La música de Erich Zann*:** la viola de la ventana más alta aparta y quema a lo de fuera, y se acelera hasta el frenesí.

## Personajes

Todos proceden de los relatos de Lovecraft o son parientes y allegados inventados de sus personajes. Se empieza con cuatro (Dyer, Olmstead, Peaslee y Whipple); el resto se compra en la tienda, salvo dos secretos que hay que descubrir.

Cada investigador tiene **siete atributos** (Poder, Inteligencia, Fuerza, Constitución, Tenacidad, Destreza y Cultura), a 10 más un reparto de 20 puntos según su historia. De ellos salen la vida, la cordura, el esquive, la velocidad y el daño de cada tipo de arma, y al subir de nivel ganan un punto más.

![Dyer, Olmstead, Legrasse, Johansen, Peaslee, Varga y Whipple](docs/img/personajes_1.jpg)
![Blake, Iwanicki, Elwood, Malone, Armitage y West](docs/img/personajes_2.jpg)
![Carter, Whateley, Pickman, Ward, Gilman, Tillinghast, Derby, Asenath y Kuranes](docs/img/personajes_3.jpg)

Las caras están dibujadas a mano, voxel a voxel, en la propia cabeza del modelo: cejas, ojos con iris, nariz en relieve, bigotes, gafas, pecas y labios.

![Las caras de cerca](docs/img/cabezas.jpg)

<!-- tabla:personajes -->
| Personaje | Arma inicial | Rasgo | Esquive | Relato de origen |
|---|---|---|---|---|
| **William Dyer**, geólogo de la Universidad de Miskatonic *(de inicio)* | Stielhandgranate | Explosiones un 25 % más grandes | Deslizamiento | *En las montañas de la locura* |
| **Robert Olmstead**, viajero y narrador de Innsmouth *(de inicio)* | Webly Mk VI | Esquive un 30 % más largo | Voltereta | *La sombra sobre Innsmouth* |
| **Amelia Peaslee**, arqueóloga, sobrina del profesor Peaslee *(de inicio)* | Rifle de palanca | Más suerte: a veces, una cuarta mejora para elegir | Voltereta | *La sombra fuera del tiempo* |
| **Dra. Marian Whipple**, doctora, sobrina del Dr. Elihu Whipple *(de inicio)* | Bisturís | Reanima a los compañeros un 50 % más rápido | Salto | *La casa maldita* |
| **John R. Legrasse**, inspector de la policía de Nueva Orleans | Escopeta de corredera | 25 % más daño contra cultistas y enemigos humanos | Salto | *La llamada de Cthulhu* |
| **Gustaf Johansen**, segundo oficial del Emma | Machete | Un 25 % más de daño cuerpo a cuerpo | Plancha de pingüino | *La llamada de Cthulhu* |
| **Madame Ludmila Varga**, espiritista y médium de Arkham | Necronomicón | Las armas arcanas le cuestan la mitad de cordura | Destello | *Médium de Arkham* |
| **Henrietta Blake**, escritora, hermana de Robert Blake | Trapezoedro | Un 15 % más de experiencia por gema | Deslizamiento | *El morador de las tinieblas* |
| **Padre Iwanicki**, sacerdote de la iglesia de San Estanislao | Fórmula de expulsión | Aura que calma: él y los compañeros cercanos recuperan cordura | Voltereta | *Los sueños en la casa de la bruja* |
| **Sargento Frank Elwood**, veterano de la Gran Guerra | Pistola Mauser C96 | Recibe un 15 % menos de daño físico | Plancha de pingüino | *Los sueños en la casa de la bruja* |
| **Vera Malone**, contrabandista de Red Hook | Thompson M1928 | Hasta un 50 % más de daño cuanto más cerca está el enemigo | Deslizamiento | *El horror de Red Hook* |
| **Profesor Henry Armitage**, bibliotecario de la Universidad de Miskatonic | Polvo de Ibn-Ghazi | Las armas mágicas se recargan un 20 % antes | Destello | *El horror de Dunwich* |
| **Herbert West**, médico, reanimador | Inyector de West | Al subir de nivel cura un 15 % de la vida a los compañeros cercanos | Voltereta | *Herbert West, reanimador* |
| **Randolph Carter**, soñador de Boston *(secreto)* | Llave de los sueños | Las crisis de locura le duran la mitad: sabe despertar | Destello | *La llave de plata* |
| **Wilbur Whateley**, hijo de Lavinia, de Dunwich *(secreto)* | Pisadas de lo invisible | Medio de otro mundo: el daño mental le hace un 40 % menos | Salto | *El horror de Dunwich* |
| **Richard Upton Pickman**, pintor de Boston | Lienzos de Pickman | Ha pintado cosas peores: pierde un 30 % menos de cordura | Cuadro | *El modelo de Pickman* |
| **Charles Dexter Ward**, anticuario de Providence | Sales esenciales | La sombra de Curwen: hasta un 40 % más de daño cuanto menos cordura le queda | Polvo | *El caso de Charles Dexter Ward* |
| **Walter Gilman**, estudiante de matemáticas de Miskatonic | Ángulos imposibles | Entre los ángulos: las balas le alcanzan menos (su blanco es un 30 % más pequeño) | Ángulo | *Los sueños en la casa de la bruja* |
| **Crawford Tillinghast**, físico y filósofo de Providence | Máquina del más allá | Ve más allá: sus armas llegan un 15 % más lejos | Más allá | *Desde el más allá* |
| **Edward Derby**, poeta de Arkham (y Asenath Waite) | El umbral | Dos almas en dos cuerpos: cada esquive los cambia. Edward golpea de cerca; Asenath mira de lejos. Cada cambio le devuelve 3 de vida y de cordura | Cambio de cuerpo | *El ser en el umbral* |
| **Kuranes**, soñador de Londres, rey de Celephaïs | Ensueño de Celephaïs | Medio dormido: recupera 0,4 de cordura por segundo, también entre los horrores | Sueño | *Celephaïs* |
<!-- /tabla -->

## Compañeros

Cada jugador puede llevar uno. Suben de nivel con él y se compran en la tienda.

![Perro, gato, rata, sapo, búho, shoggoth bebé, Mini-Byakhee y cuervo](docs/img/companeros_1.jpg)
![Polilla, gaviota, Mini-Mi-Go, araña de Tíndalos, serpiente de Yig, pez de Innsmouth, Mini-Dhole y cabra](docs/img/companeros_2.jpg)

<details>
<summary><b>Los 16 compañeros</b></summary>

<!-- tabla:companeros -->
| Compañero | Qué hace |
|---|---|
| Rata de las Paredes | Una rata enorme y maleducada. Escarba cada poco y encuentra dólares; a veces, un baúl arcano |
| Perro de trineo de Lake | Corre hacia los enemigos cercanos y los muerde; muerde más fuerte cuanto más nivel tienes |
| Pez de Innsmouth | Pez con patas que se cree humano. Toma carrerilla y embiste a los enemigos que encuentra en el camino |
| Cabra de los bosques | Cabrita aparentemente inocente. Embiste a los enemigos: los empuja y los aturde |
| Cuervo de Arkham | Cuervo ladrón. Vuela a por las gemas lejanas y te las trae; de paso roba unas monedas, a quien sea |
| Sapo de Innsmouth | Feísimo pero adorable. Escupe baba venenosa: deja un charco que daña y debilita a los enemigos |
| Búho de los sueños | Parece sabio. Vuela a tu lado y te da un 12 % más de experiencia, hasta un 30 % con el nivel |
| Gaviota de Innsmouth | Carroñera y chillona. Se va a por pescado y te lo trae: cura un 8 % de vida y cordura (hasta un 15 %) a quien más lo necesite. Chilla cuando ve una élite |
| Gato de Ulthar | Gato negro aparentemente normal... hasta que se enfada. Araña a los enemigos que se acercan; si te hieren, se eriza y ataca el doble de rápido |
| Polilla de Leng | Bonita... hasta que abre las alas. Sacude su polvo sobre los grupos de enemigos: vagan confundidos y no disparan |
| Serpiente de Yig | Serpiente que mira demasiado fijamente. Muerde y envenena: el veneno sigue dañando unos segundos |
| Mini-Byakhee | Murciélago alienígena con cara de pocos amigos. Vuela alto y cae en picado sobre los enemigos: golpe en área que los empuja |
| Mini-Mi-Go | Crustáceo espacial diminuto. Dispara rayos al enemigo más cercano |
| Shoggoth bebé | Una bolita negra llena de ojos. Va pegado a ti y se traga las balas enemigas que pasan cerca |
| Araña de Tíndalos | Una araña que no respeta las leyes de la geometría. Se teletransporta detrás de un enemigo, le muerde fuerte y lo aturde |
| Mini-Dhole | Gusano gigantesco reducido a mascota. Excava y sale bajo los grupos de enemigos: los golpea, los empuja y los aturde |
<!-- /tabla -->

</details>

## Armas y objetos

**58 armas** (16 físicas, 17 de fuego y 25 mágicas), cada una con dos evoluciones:

![Iconos de las 58 armas](docs/img/armas.jpg)

Todas disparan solas y cada una decide en sus datos cómo apunta: al más cercano, a la zona más densa, a la élite, alrededor del personaje… Suben de nivel del 1 al 5 y su daño crece con los atributos de su tipo. Con el arma al nivel 5 y su objeto pareja, un baúl arcano la convierte en una de sus dos **evoluciones**, a elegir:

![Iconos de las 116 evoluciones](docs/img/evoluciones.jpg)

<details>
<summary><b>Las 58 armas y sus evoluciones</b></summary>

<!-- tabla:armas -->
| Arma | Tipo | Cómo funciona | Evoluciones (con) |
|---|---|---|---|
| Ancla del Alert | Física | Un ancla con cadena que gira alrededor del personaje a mucha distancia, lenta y pesada | Ancla de Johansen / Molinete del Alert (Coraza de foca) |
| Arpón ballenero | Física | Proyectil pesado que atraviesa y arrastra a los enemigos menores | Arpón de Nantucket / Lanza bomba (Plomada) |
| Ballesta | Física | Virotes que atraviesan y dejan clavado al enemigo un instante | Ballesta de la fortuna / Ballesta de cranequín (Dado de hueso) |
| Bastón estoque | Física | Estocada larga y rápida hacia el enemigo más cercano que atraviesa todo lo que hay en la línea. Espera a tener a alguien a su alcance | Estoque del duelista / Sable del húsar (Piedra de afilar) |
| Bisturís | Física | Abanico de hojas que atraviesan | Instrumental / Bisturí del anatomista (Abrigo de reno) |
| Bumerán | Física | Va hasta su alcance y vuelve a tus manos, golpeando a la ida y a la vuelta | Bumerán de hueso / Bumerán de guerra (Esquís de Pabodie) |
| Cepos | Física | Deja cepos en el suelo: el primero que los pisa queda atrapado y herido | Cepos del cazador / Cepo de oso (Collar de colmillos) |
| Cóctel Molotov | Física | Botella en arco que crea un charco en llamas | Cóctel del Emma / Bomba de queroseno (Petaca de ron) |
| Gas de cloro | Física | Nube tóxica que deriva lentamente hacia los enemigos y los envenena | Gas mostaza / Fosgeno (Elixir de Curwen) |
| Inyector de West | Física | Dispara dardos de suero: el enemigo que muere con el suero dentro se levanta 6 segundos como aliado y ataca a los suyos | Reactivo perfeccionado / Suero de Halsey (Botiquín) |
| Lanzaquímicos | Física | Frasco de ácido: los enemigos del charco reciben un 25 % más de daño | Botica de Arkham / Agua regia (Láudano) |
| Látigo | Física | Latigazo largo en arco por delante que golpea a todos los del arco | Látigo del domador / Látigo del mayoral (Silbato de Lake) |
| Machete | Física | Tajo circular alrededor del personaje; solo golpea si hay alguien cerca | Machete del cañaveral / Machetes de zafra (Guantes de estibador) |
| Martillo de geólogo | Física | Golpea el suelo y abre una grieta que avanza en línea recta, daña y aturde un momento a todo lo que encuentra | Martillo de la Barrera / Piolet de Pabodie (Crampones) |
| Red de pesca | Física | Lanza una red sobre el grupo más denso: los de debajo se quedan inmóviles 2 segundos. Las élites solo se frenan | Red de Innsmouth / Redes de arrastre (Escamas de Profundo) |
| Stielhandgranate | Física | Granada de palo lanzada a la zona más densa; gran explosión al impactar | Carga concentrada / Racimo de granadas (Reflejos) |
| Ametralladora Lewis | De fuego | Monta la ametralladora en su trípode, en el suelo; dispara sola al más cercano durante 8 segundos | Nido de ametralladoras / Puestos de tiro (Manual de tiro) |
| Antitanque Mauser | De fuego | Disparo muy lento que atraviesa a todos los enemigos de la línea | Cañón antitanque / Fusil del cazacarros (Medallón del cazador) |
| BAR M1918 | De fuego | Ráfagas cuyas balas rebotan hacia otro enemigo cercano | BAR de asalto / BAR del tirador (Botas de nieve) |
| Bobina Tesla | De fuego | Descarga un rayo al enemigo más cercano que salta a los siguientes, hasta cuatro; cada salto hace un poco menos | Bobina de Nikola / Rayo de Wardenclyffe (Vara de zahorí) |
| Escopeta de corredera | De fuego | Perdigones que se abren en anillo alrededor del personaje | Escopeta de trinchera / Escopeta de postas (Bandolera) |
| Flammenwerfer | De fuego | Chorro de fuego en cono que deja el suelo ardiendo | Aliento de Moloch / Lanza térmica (Fósforos de Cthugha) |
| Fuegos artificiales | De fuego | Cohetes erráticos que estallan en chispas | Gran castillo de fuegos / Cohete de la feria (Petardos) |
| Lugers a dos manos | De fuego | Una pistola en cada mano: disparan a la vez hacia donde andas y hacia atrás, sin buscar objetivo | Lugers del as / Lugers de feria (Gafas de aviador) |
| Mortero Stokes | De fuego | Proyectil en arco alto al grupo más denso a distancia; explosión grande | Batería de morteros / Mortero incendiario (Pólvora de Ponape) |
| Nagant de Danforth | De fuego | Revólver cuya cadencia se acelera mientras tiene a quién disparar, hasta dos veces y media | Nagant del vigía / Nagant de siete tiros (Lupa) |
| Pistola de bengalas | De fuego | Bengala que ilumina y atrae a los enemigos cercanos (las élites no caen) | Bengala del faro / Bengala de magnesio (Capa del Hombre Negro) |
| Pistola Mauser C96 | De fuego | Ráfagas cortas de tres trazadoras | Mauser de Tillinghast / Carabina Mauser (Reloj de Tillinghast) |
| Recortada | De fuego | Dos disparos seguidos de perdigones en un cono corto y ancho que empuja mucho | Recortada del contrabandista / Recortada del matadero (Diente de shoggoth) |
| Rifle de palanca | De fuego | Disparos rápidos que atraviesan a varios enemigos | Rifle Miskatonic / Rifle de caza mayor (Diario de campo) |
| Springfield M1903 | De fuego | Disparo lento y fuerte que busca primero a la élite o al enemigo con más vida; a veces es un crítico triple. Atraviesa a uno | Springfield del francotirador / Springfield de Belleau (Ojo de Pickman) |
| Thompson M1928 | De fuego | Ráfagas cerradas de proyectiles pequeños | Thompson de Chicago / Thompson del agente federal (Oro de Obed) |
| Webly Mk VI | De fuego | Proyectiles pesados que hacen retroceder a los enemigos | Revólver del vigía / Webly de seis tiros (Brújula de Lake) |
| Aliento de Ithaqua | Mágica | Viento helado en cono que frena a los enemigos y congela a los que siguen dentro | Aliento del Wendigo / El que camina con el viento (Pemmican) |
| Báculo del Farolero | Mágica | Suelta fuegos fatuos que zigzaguean y buscan solos a los enemigos. Cuesta cordura | Linterna de los fatuos / Fuego de San Telmo (Pipa de espuma) |
| Daga ritual | Mágica | Apuñala al enemigo más cercano y lo maldice: pierde vida poco a poco y, si muere maldito, la maldición salta a los de al lado. Cuesta cordura | Daga del sacrificio / Daga de obsidiana (Colmillo de ghoul) |
| El umbral | Mágica | Depende de quién esté en el cuerpo. Edward da un golpe alrededor, de cerca y fuerte (físico); Asenath lanza dos miradas verdes que buscan al enemigo (mágicas, cuestan cordura). Cada esquive los cambia | Lo que llamó a la puerta / Los ojos de Ephraim (Aldaba de la casa Derby) |
| Ensueño de Celephaïs | Mágica | Un trozo del cielo de Celephaïs donde más enemigos hay: dentro sueñan y van cada vez más despacio, sus balas se frenan y los investigadores recuperan cordura | Valle de Ooth-Nargai / Serannian (Adormidera de Ooth-Nargai) |
| Esfera de Yog-Sothoth | Mágica | Orbe lento que atrae a los enemigos hacia su centro y los tritura | La Puerta y la Llave / Umr at-Tawil (Llave de plata) |
| Fórmula de expulsión | Mágica | Onda que se expande desde el personaje, empuja y aturde. Cuesta cordura | Exorcismo mayor / Letanía de expulsión (Signo Primigenio) |
| Lente del Éter | Mágica | Rayo sostenido sobre un enemigo: su daño crece mientras sigue sobre él, hasta el triple. Si el enemigo cae, salta a otro. Cuesta cordura | Ojo del Éter / Prisma del Éter (Catalejo) |
| Lienzos de Pickman | Mágica | Planta un cuadro entre los enemigos que los atrae y los deja vulnerables. Cuando lo rompen, revienta y sale de él un necrófago que caza un rato | Galería de North End / El modelo del natural (Fotografía del modelo) |
| Llama de Cthugha | Mágica | Bola de fuego vivo que atraviesa a los enemigos y deja un rastro ardiendo | Llama del culto / Chispas de Fomalhaut (Talismán esotérico) |
| Llave de los sueños | Mágica | La llave de plata de Randolph Carter va hasta su alcance y vuelve, y deja adormilado un momento a todo lo que toca | Llave de la ignota Kadath / Llaves de Ulthar (Mapa de las Tierras del Sueño) |
| Lámpara de Alhazred | Mágica | Haz de luz que barre en círculo alrededor del personaje | Lámpara del Árabe Loco / Faro de Irem (Ankh de Nephren) |
| Máquina del más allá | Mágica | Una onda violeta que revela lo que nos rodea: los alcanzados reciben un 30 % más de daño de todo durante unos segundos, y los ocultos salen. Cada pulso seguido calienta la máquina y quita más cordura a todo el grupo cercano | Lo que nos rodea / Medusas del más allá (Válvula de la máquina) |
| Necronomicón | Mágica | Páginas que orbitan alrededor del personaje. Cuesta cordura | Necronomicón completo / Al Azif (Manuscritos pnakóticos) |
| Orbe Mi-Go | Mágica | Un orbe de los hongos de Yuggoth vuela solo a tu alrededor y dispara al enemigo más cercano. Cuesta cordura | Enjambre de Yuggoth / Cilindro de los Mi-Go (Cristal de Ithaqua) |
| Pisadas de lo invisible | Mágica | El hermano de Wilbur, que nadie ve, avanza en línea recta hacia el grupo más denso: aplasta y aturde lo que pisa | Lo que bajó de Sentinel Hill / El gemelo de Wilbur (Diario cifrado de Wilbur) |
| Polvo de Ibn-Ghazi | Mágica | Esparce una nube sobre el grupo más denso: dentro, los enemigos van un 40 % más lentos y hacen un 30 % menos de daño. Cuesta cordura | Polvo de los Antiguos / Polvo de Ibn Schacabao (Mapa de Leng) |
| Rayo de Yith | Mágica | Congela al enemigo en el tiempo 1,5 s; el daño que recibe mientras tanto se aplica al final, un 50 % mayor. Cuesta cordura | Rayo de la Gran Raza / Rayo de Pnakotus (Clepsidra de Yith) |
| Resonador | Mágica | Vibra cada poco y su pulso deshace las balas enemigas cercanas; hace poco daño. Solo vibra si hay balas o enemigos cerca. Cuesta cordura | Gran resonador / Resonador de Crawford (Escudo de Nodens) |
| Sales esenciales | Mágica | Esparce las sales donde más enemigos han caído y recita la fórmula: daña a los de alrededor y levanta a dos de los caídos, que luchan por él un rato. Cuesta cordura | Cabeza del Dragón / Cola del Dragón (Frasco de los Custodes) |
| Signo Amarillo | Mágica | Los enemigos que lo miran enloquecen y atacan a los suyos unos segundos | El Rey de Amarillo / Carcosa (Salterio) |
| Signo Arcano | Mágica | Traza bajo sus pies un signo que daña y empuja hacia fuera a los enemigos; las balas enemigas que lo cruzan van a la mitad de velocidad. Cuesta cordura | Signo Mayor / Signo de Koth (Escapulario) |
| Tentáculos de Shub | Mágica | Tentáculos que brotan del suelo, tras un aviso, bajo enemigos al azar | Las Mil Crías / La Cabra Negra (Tablilla de Eltdown) |
| Trapezoedro | Mágica | Rayo de luz concentrada que daña todo lo que atraviesa. Cuesta cordura | Trapezoedro despierto / Trapezoedro de Blake (Ídolo de Cthulhu) |
| Ángulos imposibles | Mágica | Lanza ángulos que salen torcidos y doblan esquinas en ángulo recto hasta dar con el enemigo. Atraviesan paredes, árboles y a varios enemigos | La geometría de la bruja / El trono de Azathoth (Estatuilla de la balaustrada) |
<!-- /tabla -->

</details>

**58 objetos**, de la subida de nivel (los potenciadores permanentes se compran en la tienda):

![Iconos de los 58 objetos](docs/img/objetos.jpg)

<details>
<summary><b>Los 58 objetos</b></summary>

<!-- tabla:objetos -->
| Objeto | Efecto |
|---|---|
| Abrigo de reno | +20 de vida máxima |
| Adormidera de Ooth-Nargai | Los enemigos que frenan tus armas van un 6 % más lentos |
| Aldaba de la casa Derby | Tres golpes y luego dos: el primer daño a un enemigo ileso es un 12 % mayor |
| Ankh de Nephren | Una vez por nivel, al caer te levantas con el 30 % de vida |
| Bandolera | +1 proyectil en las armas de balas y lanzados |
| Botas de nieve | +8 % de velocidad al andar |
| Botiquín | Recupera 0,5 de vida por segundo |
| Brújula de Lake | +30 % de radio para recoger experiencia |
| Capa del Hombre Negro | Al esquivar dejas un señuelo que atrae a los enemigos 1 s por nivel |
| Catalejo | +10 % de alcance de las armas |
| Clepsidra de Yith | +15 % de duración de zonas, órbitas, rayos y torretas |
| Collar de colmillos | +25 % de daño de los críticos |
| Colmillo de ghoul | Cada enemigo abatido cura 0,15 de vida |
| Coraza de foca | −2 al daño físico de cada golpe |
| Crampones | +15 % de distancia del esquive |
| Cristal de Ithaqua | 6 % de que el impacto frene al enemigo 1,5 s |
| Dado de hueso | +15 % de suerte: a veces una opción más al subir de nivel |
| Diario cifrado de Wilbur | Recuperas 0,25 de cordura por segundo, y los compañeros a menos de 4 m también |
| Diario de campo | +20 de cordura máxima |
| Diente de shoggoth | +20 % de daño con menos del 30 % de vida |
| Elixir de Curwen | +15 % de daño durante 2 s tras esquivar |
| Escamas de Profundo | Devuelve el 30 % del daño de contacto al que te golpea |
| Escapulario | +25 % de invulnerabilidad tras recibir un golpe |
| Escudo de Nodens | Cada 25 s absorbe un golpe entero (3 s antes por nivel) |
| Esquís de Pabodie | +1 esquive seguido antes de recargar |
| Estatuilla de la balaustrada | Las balas de tus armas son un 12 % más grandes: tocan antes y se ven mejor |
| Fotografía del modelo | Los aliados que levantan tus armas (necrófagos, reanimados) duran un 12 % más |
| Frasco de los Custodes | Los aliados que levantan tus armas (levantados, necrófagos, reanimados) golpean un 15 % más fuerte |
| Fósforos de Cthugha | 6 % de que el impacto prenda al enemigo 3 s |
| Gafas de aviador | +0,08 s de invulnerabilidad al esquivar |
| Guantes de estibador | +12 % de daño de las armas físicas y +10 % de empuje |
| Llave de plata | RB o E en la subida de nivel: otras opciones, una vez por nivel |
| Lupa | +10 % de experiencia |
| Láudano | Las crisis de locura duran un 20 % menos |
| Manual de tiro | +12 % de daño de las armas de fuego |
| Manuscritos pnakóticos | +12 % de daño de las armas mágicas |
| Mapa de las Tierras del Sueño | Las armas mágicas se recargan un 7 % antes |
| Mapa de Leng | +10 % de área de explosiones, zonas, ondas y tajos |
| Medallón del cazador | +30 % de daño a élites y seres únicos |
| Ojo de Pickman | +8 % de probabilidad de crítico (daño ×1,5) |
| Oro de Obed | +15 % de dólares para el equipo |
| Pemmican | La comida y las pociones curan un 30 % más |
| Petaca de ron | +8 % de daño |
| Petardos | Al esquivar estalla una carga donde estabas |
| Piedra de afilar | Las balas atraviesan 1 enemigo más |
| Pipa de espuma | Recupera 0,6 de cordura por segundo |
| Plomada | +25 % de empuje |
| Pólvora de Ponape | +12 % de velocidad de los proyectiles |
| Reflejos | El esquive se recarga un 10 % antes |
| Reloj de Tillinghast | Las armas se recargan un 6 % antes |
| Salterio | Cada enemigo abatido devuelve 0,12 de cordura |
| Signo Primigenio | −10 % de daño mental, también de las auras |
| Silbato de Lake | +20 % de daño y velocidad del compañero |
| Tablilla de Eltdown | 8 % de que el enemigo abatido estalle y dañe alrededor |
| Talismán esotérico | Las armas mágicas cuestan un 12 % menos de cordura |
| Vara de zahorí | Los baúles arcanos aparecen un 15 % más a menudo |
| Válvula de la máquina | Los enemigos revelados reciben un 8 % más de daño |
| Ídolo de Cthulhu | +12 % de enemigos, de experiencia y de dólares |
<!-- /tabla -->

</details>

## Bestiario

Más de 90 criaturas, entre ellas los seres únicos del final de cada nivel, los jefes intermedios y los ocho jefes. Cada una tiene su escalón (del 1 al 5), su comportamiento y su patrón de ataque, todo en datos. Las de escalón bajo forman la masa de la horda; los escalones 4 y 5 son élites.

<!-- tabla:bestiario_p1 -->
**Parte 1:** Pingüino albino ciego · Fragmento protoplásmico · Acechador · Antiguo revivido · Antiguo alado · Expedicionario de Lake · El primero en despertar · Shoggoth esclavo · Shoggoth mimético · Shoggoth excavador · Gedney, lo que queda de él · El shoggoth de la caverna · Antiguo guerrero · Antiguo mutilado · Antiguo sembrador · El guardián de la ciudad · Shoggoth de ojos luminosos · Antiguo del mar abisal · El shoggoth primigenio.
<!-- /tabla -->

![Criaturas de la parte 1](docs/img/bestiario_1.jpg)

<!-- tabla:bestiario_p2 -->
**Parte 2:** Pescador de Innsmouth · Vecina de Innsmouth · Viejo de Innsmouth · Acólito de la Orden de Dagon · El diácono de la Orden · Híbrido avanzado · Híbrida avanzada · Sacerdote de la tiara · Guardián de la Orden de Dagon · El sumo sacerdote de la Orden · Profundo · Profundo escupidor · Acechador de los tejados · Hija de los Marsh · El capitán Obed Marsh · Profundo de la ciénaga · Profundo anciano de Y'ha-nthlei · Nadador de la marea · Barnabas Marsh, transformado · Pth'thya-l'yi, la antepasada · Madre Hydra · Padre Dagon.
<!-- /tabla -->

![Criaturas de la parte 2](docs/img/bestiario_2.jpg)

<!-- tabla:bestiario_p3 -->
**Parte 3:** Pesadilla de la oleada de sueños · Cultista de Cthulhu · Sonámbulo de Providence · La pesadilla del bajorrelieve · Cultista armado del Alert · Diablo con alas de murciélago · Tamborilero del pantano · Ídolo vivo · El viejo Castro · El sacerdote del ritual · Engendro de Cthulhu · El engendro mayor · La cosa blanca polipoide · La cosa blanca del lago oculto · Emanación de la puerta · Primigenio menor · Cthulhu · Cthulhu, recompuesto.
<!-- /tabla -->

![Criaturas de la parte 3](docs/img/bestiario_3.jpg)

<!-- tabla:bestiario_p4 -->
**Parte 4:** Zoog · Zoog de las copas · El anciano del consejo de los zoogs · Mercader de Leng · Remero lunar · El amo de la galera negra · Shantak · Araña púrpura de Leng · El sumo sacerdote que no debe describirse · La madre de las arañas de Leng · Ghast · Gug · El gran gug de la torre de Koth · Larva de los Otros Dioses · Descarnado nocturno · Nyarlathotep, el Caos reptante.
<!-- /tabla -->

![Criaturas de la parte 4](docs/img/bestiario_4.jpg)

<!-- tabla:bestiario_noche -->
**Noches sueltas:** Res gris · Granjero consumido · El color que sube del pozo · Chotacabras de Dunwich · Devota de las colinas · El hermano de Wilbur · Poseído de la Gran Raza · Pólipo volador · El pólipo antiguo · Vecino de la rue d'Auseil · Jirón de la noche · Lo que hay tras la ventana.
<!-- /tabla -->

![Criaturas de las noches sueltas](docs/img/bestiario_noches.jpg)

Algunas tienen comportamientos propios: el pingüino ciego va hacia donde oyó al jugador, el shoggoth mimético se disfraza de Antiguo y se transforma al acercarse, las pesadillas atraviesan el decorado, los diablos caen en picado y los Profundos de la ciénaga salen del agua. Los Ángulos devoradores de R'lyeh no se matan: se esquivan. En las Tierras del Sueño, los ghasts huyen de la luz, las arañas de Leng tienden redes que atrapan y los descarnados se llevan por el aire a quien atrapan. Las élites sacan uno o dos rasgos al azar (vampírica, estalla al morir, rastro de icor, rápida o con escudo), con su icono sobre la cabeza.

## Cómo se juega

### Controles

| Acción | Mando | Teclado |
|---|---|---|
| Moverse | Stick izquierdo o cruceta | WASD o flechas |
| Esquivar | A | Espacio |
| Disparar | Automático | Automático |
| Ficha del personaje | Select | Tab |
| Mapa de la arena | Cruceta abajo | M |
| Páginas de la ficha / girar en la selección | LB / RB | Q / E |
| Pausa | Start | Esc |
| Menús: confirmar / volver | A / B | Intro / Esc |
| Selección: unirse | Start | Intro |

Todo se puede reasignar, en teclado y en mando, desde **Configuración → Controles**.

### Vida, cordura y locura

- **Vida:** baja con el daño físico. En cooperativo, a cero quedas derribado unos segundos y un compañero puede reanimarte.
- **Cordura:** baja con los ataques mentales, con la presencia de los horrores cercanos y con las armas arcanas. Se recupera lejos de los enemigos.
- **Crisis de locura** (de 4 a 6 segundos, con la cordura a cero):

| Crisis | Efecto |
|---|---|
| Parálisis catatónica | Se queda clavado en instantes breves, avisados con un temblor. Sigue disparando. |
| Huida histérica | Corre sin control lejos del horror más cercano. |
| Vagar sin rumbo | Movimiento errático y lento; los controles solo obedecen a medias. |
| Delirio | Controles invertidos. |
| Paranoia | Sus armas apuntan a los compañeros y les restan cordura (solo en cooperativo). |

- **Legibilidad:** los efectos de cordura baja nunca ocultan ni falsean las balas de verdad.

### Subir de nivel

Las gemas de experiencia son comunes al equipo. Al subir, el jugador de turno elige entre tres opciones (cuatro con suerte): un arma nueva, subir una que ya lleva o un objeto. Por los niveles aparecen baúles arcanos con tesoro; un arma al nivel 5 que lleve su objeto pareja evoluciona al abrir el siguiente.

## Instalación y ejecución

### Desde el código

Requisitos: [Godot 4.4.1](https://godotengine.org/download/archive/4.4.1-stable/) (versión estándar, no .NET) y una tarjeta gráfica con Vulkan (en Mac, Metal). Opcional, para regenerar modelos, escenarios e imágenes: Python 3.12 con `numpy`, `scipy` y `Pillow`.

```bash
git clone https://github.com/sergiosanchezcustodio/lovecraft-bullethell.git
cd lovecraft-bullethell
godot --headless --path . --import   # la primera vez: importa los recursos
godot --path .                       # ficha, intro, portada, huecos, menú principal
```

En Windows también basta con hacer doble clic en `jugar.cmd`. El juego arranca a pantalla completa; para jugar en ventana, `godot --path . -- window=true`. La primera partida tarda unos segundos más en arrancar porque construye las mallas de los modelos, que después quedan en caché.

### Ejecutables

Con las plantillas de exportación de Godot 4.4.1 instaladas:

```bash
sh tools/exportar.sh          # comprime los modelos y exporta Windows y macOS en builds/
```

Salen un `.exe` único para Windows 10/11 de 64 bits y un `.app` universal para macOS 11 o posterior (Apple Silicon e Intel). La versión de Mac no está firmada con una cuenta de desarrollador de Apple: la primera vez hay que abrirla con **clic derecho → Abrir**.

También las hace GitHub Actions (`.github/workflows/build.yml`): al subir una etiqueta de versión pasa los tests, exporta las dos y las deja en una Release en borrador, que se revisa y se publica a mano. Para publicar una versión:

```bash
sh tools/publicar.sh 0.9.1    # sube la versión, hace el commit y la etiqueta v0.9.1 y, si confirmas, lo sube
```

Sin etiqueta, desde la pestaña Actions de GitHub (*Builds → Run workflow*): las builds quedan 30 días en la ejecución, sin Release.

## Jugar online

Hasta cuatro jugadores repartidos entre uno y cuatro PC. Un PC crea la sala (**Jugar → Jugar online → Crear sala**) y pasa su **código de 8 letras** a los demás, que se unen con él. Si el router abre el puerto solo (UPnP), el código sirve desde cualquier sitio; si no, hay que abrir el puerto 24680 a mano o usar una red privada virtual.

- Todos deben tener la **misma versión** del juego (sale abajo a la derecha del menú principal).
- La sala es la propia selección de personaje: cada PC elige con sus desbloqueos y el anfitrión elige el nivel.
- Cada PC tiene su cámara, su HUD con el ping y su guardado (dinero y logros).
- Si alguien se desconecta, un bot ocupa su sitio y puede volver al pasar de nivel.
- **F9** o **LB+RB** mantenidos dejan una marca en el registro de red de todos los PC, para comentar después qué pasó.

Guía completa para jugadores en [`docs/JUGAR_ONLINE.md`](docs/JUGAR_ONLINE.md).

## Para desarrolladores

### Estructura

```
addons/      GUT (tests)
data/        Datos del juego: personajes, armas, enemigos, patrones, niveles, escenarios,
             compañeros, objetos, vestuario, tienda, logros, clima, ambiente, campaña y textos
docs/        Diseño (GDD), hoja de ruta, diario, lecciones, rendimiento, guías e imágenes
models/      Modelos voxel en JSON (los generan los scripts de tools/)
resources/   Ilustraciones, máscaras, iconos, música, sonidos y fuentes
scenes/      main (enrutador), title, select, relato, game, preview y bench
scripts/     Código por sistema: anim, bullets, core, enemies, fx, input, level, menus, net,
             pets, player, progression, save, title, ui, weapons
tests/       Tests de GUT
tools/       Generadores de modelos, escenarios, efectos, iconos e imágenes; simulaciones
```

### Pipeline de arte voxel

1. **Generador en Python** (`tools/gen_*.py`, sobre `tools/voxlib.py`, y `tools/cuerpo.py` para los humanos): construye el modelo con primitivas y tramos de caras planas, lo colorea por materiales y pinta los detalles. Las caras se dibujan fila a fila, como un *sprite*, sobre la cabeza.
2. **JSON** (`models/*.json`): lista de voxels `[x, y, z, parte, r, g, b, glow]` y un pivote por parte.
3. **`VoxelBuilder`** convierte el JSON en mallas: quita las caras ocultas, calcula la oclusión ambiental por vértice, separa la capa emisiva y guarda el resultado en caché.
4. **Animación por código:** cada familia de modelos tiene su script en `scripts/anim/`, que gira las partes según la fase de la animación.
5. **Escenarios** por receta (`tools/arena_kit.py`): suelo, bordes, luz, clima, atrezo repartido y mapa de lo transitable a partir de los voxels reales de cada pieza.
6. **Referencias e iconos** con FLUX: en local con ComfyUI (`tools/generar_local.py`) o, con permiso, en Replicate. Las referencias guían el diseño; los modelos siempre salen del generador.

```bash
python tools/gen_dyer.py                              # regenera un personaje
python tools/gen_vestuario.py                         # y después su vestuario
python tools/gen_arena_campamento.py                  # escenario del nivel 1 y su mapa
godot --path . -- still 0 dyer,olmstead,legrasse      # captura de uno o varios modelos
godot --path . -- anim 45 dyer walk                   # fotogramas de una animación
```

### Opciones de ejecución

Las escenas leen lo que va detrás de `--`. Algunas útiles:

```bash
godot --path . -- title                                         # portada
godot --path . -- select join=3                                 # selección con tres jugadores de prueba
godot --path . -- level=p2_n2 bot=smart bots=3 autopick=true    # partida con cuatro bots
godot --path . -- level=p3_n5 boss=true final_at=5 god=true     # directo a Cthulhu
godot --path . -- character=legrasse nolevel=true cam=3.5       # campo de pruebas, de cerca
godot --path . -- select net_host=true net_upnp=false           # sala online de prueba (y otra ventana con net_join=127.0.0.1)
godot --path . --disable-vsync -- bot=circle god=true max_alive=150 spawn_rate=40 bullet_rain=1000 perf=10
                                                                # prueba de carga
python tools/simular.py --ts 2 --par 2                          # simulaciones de equilibrio con SmartBot
```

La lista completa está en [`CLAUDE.md`](CLAUDE.md). En partida, **Pausa → Depuración** permite cambiar casi todo sin reiniciar.

### Tests

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

419 tests con [GUT 9.4](https://github.com/bitwes/Gut): movimiento, combate, balas, armas y evoluciones, oleadas, progresión, cordura, cooperativo, red, compañeros, economía, tienda, logros, guardado, nube, configuración, menús, contenido y animaciones. Lo visual se comprueba con capturas automáticas desde la terminal.

### Rendimiento

Windows 11, RTX 3070 Ti, 1920 × 1080, Forward+, sin vsync:

| Prueba | Media | 1 % peor |
|---|---|---|
| Partida normal: 75 enemigos y 500 balas, en cualquiera de los 15 escenarios | 107-119 FPS | 60-118 FPS |
| Prueba de carga: 150 enemigos y 1.000 balas, un jugador | 82-90 FPS | 53 FPS |
| Prueba de carga: 150 enemigos y 1.000 balas, cuatro jugadores | 65-69 FPS | 37-41 FPS |
| Red: cuatro PC con 75 enemigos vivos | ~19 kB/s por invitado | 0,46 ms de red por fotograma |

El detalle está en [`docs/RENDIMIENTO.md`](docs/RENDIMIENTO.md) y en el diario.

### Documentación

- [`docs/GDD.md`](docs/GDD.md): documento de diseño vivo, con todas las decisiones.
- [`docs/ROADMAP.md`](docs/ROADMAP.md): fases, hitos, criterios de aceptación y estado.
- [`docs/ESTADO.md`](docs/ESTADO.md): diario detallado de cada hito y cambio.
- [`docs/LECCIONES.md`](docs/LECCIONES.md): lecciones técnicas aprendidas.
- [`docs/JUGAR_ONLINE.md`](docs/JUGAR_ONLINE.md) y [`docs/PRUEBA_ONLINE.md`](docs/PRUEBA_ONLINE.md): guía para jugar por red y lista de la prueba por internet.
- [`docs/GUARDADO_NUBE.md`](docs/GUARDADO_NUBE.md): guía de la copia de las partidas en la nube.
- [`CLAUDE.md`](CLAUDE.md): estado actual, arquitectura, pipeline y comandos.
- [`docs/PROMPT_juego_lovecraft.md`](docs/PROMPT_juego_lovecraft.md): la especificación original, sin cambios.

### Imágenes de este README

Salen de capturas automáticas del juego: `sh tools/capturas_readme.sh` juega las partidas con bots y fotografía menús y modelos, y `python tools/montar_readme.py` las reduce a 960 px, monta las láminas de modelos, caras e iconos (leyendo los mismos datos que usa el juego) y hace con ffmpeg el GIF y un vídeo MP4 con sonido. También deja `docs/img/vista_previa.jpg` (1280 × 640), la imagen que enseña GitHub al compartir el enlace del repositorio. Las tablas de personajes, compañeros, armas, objetos, niveles y criaturas salen de los datos del juego: `python tools/tablas_readme.py` las rehace en los dos README (entre las marcas `<!-- tabla:… -->`), el inglés con la misma traducción que usa el juego.

## Hoja de ruta

| Fase | Contenido | Estado |
|---|---|---|
| 0 | Documentación y decisiones | ✅ Hecha |
| 1 | Prototipo jugable: un nivel, armas, enemigos, progresión, cordura y HUD | ✅ Hecha |
| 2 | Menús, guardado y cooperativo local: huecos, configuración, selección a cuatro, reanimación, economía, tienda, compañeros, logros, clima y vestuario | ✅ Hecha |
| 3 | Pipeline de contenido: enemigos, armas, evoluciones, niveles y escenarios por datos | ✅ Hecha |
| 4 | Parte 1: la Antártida, cinco niveles y el shoggoth primigenio | ✅ Hecha |
| 5 | Ficha del proyecto, intro, relatos de los 15 niveles, tienda ampliada, Armitage y West | ✅ Hecha |
| 6 | Parte 2: Innsmouth, cinco niveles y Padre Dagon | ✅ Hecha |
| 7 | Parte 3: Providence, Luisiana, el Pacífico, R'lyeh y Cthulhu | ✅ Hecha |
| 8 | Pulido y distribución: sonido, música, accesibilidad, 50 armas y 50 objetos, escenarios rehechos, efectos en cubitos, dificultades, ambiente vivo, subidas por turnos, caras nuevas | 🔨 En curso: falta el equilibrio final con partidas reales y subir a itch.io |
| 9 | Juego online: sala, selección y partida en red, pausa y subidas para todos, desconexiones y vuelta | ✅ Hecha, pendiente de la prueba por internet |
| 10 | Guardado en la nube: copia de las partidas y los controles en un gist de GitHub, conflictos entre PC | ✅ Hecha, pendiente de activarla (aplicación de GitHub) y de la prueba con dos PC |
| 11-14 | Sensación de impacto, informe al caer, modo sin fin, partida del día, modo foto, tráiler y demo de la parte 1 | ✅ Hecha |
| 15 | Repetición de la caída, desafíos, un enemigo nuevo por parte y bestiario vivo | ✅ Hecha |
| 16 | Rendimiento (hordas con instancias, carga durante el relato), dos ramas de evolución, Signos Mayores, buhonero, grados de locura, enemigos y jefes intermedios, élites con rasgos, velocidad del juego, desfile de jefes, expediciones, pesca, personajes secretos, sala de trofeos y escenarios más vivos | ✅ Hecha |
| 17 | Animación y vida de los escenarios: gestos, celebraciones, poses de victoria, muertes según el daño, decorado que reacciona y sucesos lejanos | ✅ Hecha |
| 18 | Efectos de las armas en voxel con degradados: estelas, impactos, casquillos, arcos, zonas y acentos de las evoluciones | ✅ Hecha |
| 19 | Rendimiento, accesibilidad de los efectos, build de Linux e informe de errores | ✅ Hecha |
| 20 | Menús, transiciones y configuración; seis personajes nuevos: Pickman, Ward, Gilman, Tillinghast, Derby y Kuranes | ✅ Hecha |
| 21 | Vínculos, sucesos de la noche, trucos de los compañeros, combinaciones y revelaciones; la parte 4 (*Kadath*) y tres noches sueltas; finales ilustrados, camino de tinta, retratos al óleo, manual y estadísticas | ✅ Hecha, falta la música de la parte 4 |
| 22 | Equilibrio y rendimiento de la parte 4, logros nuevos, el juego en inglés, la cuarta noche (*La música de Erich Zann*), tráiler y página de itch.io | ✅ Hecha |
| 23 | Build más ligera, demo pequeña, créditos al día; propuestos la primera hora, el procesador, una quinta noche y códigos de partida | 🔨 En curso |

## Derechos y créditos

- **Ambientación:** los relatos de H. P. Lovecraft son de **dominio público** en España y la Unión Europea, y todo el contenido del juego procede de ellos. El juego no tiene relación con *Call of Cthulhu* (marca de Chaosium) ni reproduce reglas, textos o ilustraciones del juego de rol ni de adaptaciones modernas.
- **Motor:** [Godot Engine](https://godotengine.org/) (licencia MIT).
- **Tests:** [GUT](https://github.com/bitwes/Gut) (licencia MIT), en `addons/gut/`.
- **Fuente de la portada:** *IM FELL English SC*, de Igino Marini, con licencia [SIL Open Font License 1.1](resources/fonts/OFL_IMFellEnglishSC.txt).
- **Fuente de los menús:** *EB Garamond*, de Georg Duffner y Octavio Pardo, con licencia [SIL Open Font License 1.1](resources/fonts/OFL_EBGaramond.txt).
- **Efectos de sonido:** [Kenney](https://kenney.nl/) (CC0) y sintetizados para el juego.
- **Música:** del autor (portada y primer nivel) y pistas CC0 de [OpenGameArt](https://opengameart.org/) de Eldritch Grim, Juhani Junkala, isaiah658 y otros; la lista completa, con autor y enlace, está en [`data/musica.json`](data/musica.json).
- **Diseño, ilustraciones de la portada y la tienda:** Sergio Sánchez Custodio.
- **Uso de IA:** el código, los modelos voxel (generados por programas) y los textos se desarrollan con [Claude Code](https://claude.com/claude-code) (Anthropic), bajo la dirección del autor. Los iconos de armas y objetos, los adornos de los menús, los retratos de los investigadores, los finales ilustrados de cada parte y las referencias de diseño se generaron con FLUX (Black Forest Labs), en [Replicate](https://replicate.com/) y en local con ComfyUI.

## Licencia

Licencia mixta; el detalle está en [`LICENCIA.md`](LICENCIA.md).

- **El código** (scripts, *shaders*, escenas, herramientas, tests, datos de juego y documentación) se publica bajo la **GNU General Public License v3.0**, con el texto completo en [`LICENSE`](LICENSE). Puedes copiarlo, modificarlo y redistribuirlo, incluso con fines comerciales, siempre que lo que redistribuyas basado en él se publique también bajo GPL-3.0 y con su código fuente.
- **Los recursos del juego** (el arte, la música del autor, los textos del juego y el nombre *Lovecraft Library: Surviving Cthulhu*) tienen **todos los derechos reservados**. Se pueden usar para jugar, compilar o probar el proyecto, pero no para reutilizarlos en otros.
- Las piezas de terceros conservan su propia licencia (ver [Derechos y créditos](#derechos-y-créditos)).
