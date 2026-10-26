<div align="center">

<img src="docs/img/portada.jpg" alt="La portada del juego: la biblioteca de la Universidad de Miskatonic a la luz de las velas, con el ventanal y la silueta de Cthulhu en la tormenta" width="100%">

# Lovecraft Library: Surviving Cthulhu

**Bullet hell isométrico en voxel 3D, con disparo automático y progresión *survivors*, para 1 a 4 jugadores en cooperativo local y online, ambientado en los mitos de H. P. Lovecraft.**

[![Godot 4.4](https://img.shields.io/badge/Godot-4.4.1-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
![GDScript](https://img.shields.io/badge/GDScript-tipado%20est%C3%A1tico-355570)
![Windows](https://img.shields.io/badge/Windows-x86__64-0078D6?logo=windows&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-universal-000000?logo=apple&logoColor=white)
![Jugadores](https://img.shields.io/badge/jugadores-1%E2%80%934%20local%20y%20online-8e44ad)
![Tests](https://img.shields.io/badge/tests-GUT%20%C2%B7%20393%20en%20verde-2e7d32)
![Versión](https://img.shields.io/badge/versi%C3%B3n-0.9.0-e0a100)
[![Licencia: código GPLv3, recursos reservados](https://img.shields.io/badge/licencia-c%C3%B3digo%20GPLv3%20%C2%B7%20recursos%20reservados-blue)](LICENCIA.md)

**Español** · [English](README.en.md)

[Características](#características) · [Capturas](#capturas) · [Campaña](#la-campaña) · [Personajes](#personajes) · [Armas](#armas-y-objetos) · [Bestiario](#bestiario) · [Instalación](#instalación-y-ejecución) · [Desarrollo](#para-desarrolladores) · [Hoja de ruta](#hoja-de-ruta)

</div>

> *«Lo más misericordioso del mundo es la incapacidad de la mente humana para relacionar todo lo que contiene.»*
> — H. P. Lovecraft, *La llamada de Cthulhu*

En la Biblioteca de la Universidad de Miskatonic, unos cuantos investigadores han empezado a relacionarlo. De la Antártida a Innsmouth, y de Innsmouth a R'lyeh, algo muy antiguo ha empezado a despertar.

**Lovecraft Library** recorre tres relatos de Lovecraft (*En las montañas de la locura*, *La sombra sobre Innsmouth* y *La llamada de Cthulhu*) en quince niveles y tres jefes colosales. Las armas disparan solas: la habilidad está en **moverse y esquivar** entre hordas y cortinas de balas que dañan la **vida** o la **cordura**. Si la cordura llega a cero, llega la locura.

<div align="center">

<img src="docs/img/partida.gif" alt="Partida a cuatro jugadores en las calles de Innsmouth, bajo la lluvia, entre híbridos, acólitos y sacerdotes de la tiara" width="100%">

| 15 | 3 | 13 | 50 + 50 | 50 | 16 | 47 | 1–4 |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| niveles | jefes colosales | investigadores | armas y sus evoluciones | objetos | compañeros | criaturas | jugadores, en local o por red |

</div>

> [!NOTE]
> **Versión 0.9.0, en desarrollo.** La campaña completa se juega de principio a fin: las tres partes, solo, en cooperativo local o por red. Quedan la prueba por internet entre casas distintas, el equilibrio final con partidas de jugadores reales, la publicación en itch.io y activar el guardado en la nube, ya programado. El estado detallado está en la [hoja de ruta](#hoja-de-ruta).

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

- **Bullet hell con progresión *survivors*:** hordas que llegan desde fuera de la pantalla, patrones de balas con aviso en el suelo y armas que disparan solas. Cada nivel dura unos cinco minutos y termina con un evento final: un ser único, una horda a la que sobrevivir o uno de los tres jefes.
- **Vida y cordura:** los ataques físicos (rojos, naranjas y amarillos) quitan vida; los mentales (morados y lilas), cordura; los mixtos, las dos. La cercanía de los horrores también desgasta la mente.
- **Crisis de locura:** con la cordura a cero, el investigador sufre una de cinco crisis (parálisis, huida histérica, vagar sin rumbo, delirio con los controles invertidos o paranoia), con un aura morada y cara de pánico.
- **50 armas con evolución:** de fuego, físicas y mágicas, cuatro a la vez (seis con las fundas de la tienda). Cada una sube del nivel 1 al 5 y, al máximo y con su objeto pareja, evoluciona en un arma nueva al abrir un baúl arcano. Las mágicas cuestan cordura.
- **50 objetos** que cambian las reglas: proyectiles, alcance, críticos, esquives dobles, escudos, señuelos, resurrección…
- **13 investigadores** con siete atributos, arma inicial, un rasgo propio y su estilo de esquive: deslizamiento, voltereta, plancha, salto o destello.
- **16 compañeros** que muerden, curan, roban, se tragan balas o se teletransportan.
- **Escenarios vivos:** nevada, ventisca, niebla, lluvia y tormenta con rayos; agua que frena, olas que barren la cubierta, Ángulos devoradores que engullen a quien se queda dentro, baúles arcanos y decorado que se rompe; pájaros, murciélagos y bichos que reaccionan a la batalla.
- **Tres dificultades:** Investigador, Normal y Pesadilla.

### Cooperativo, local y online

- **De 1 a 4 jugadores** con mando o teclado en el mismo PC, por red entre varios PC, o mezclando las dos cosas (por ejemplo, dos en el sofá y otros dos, cada uno en su casa).
- Cámara compartida, **experiencia común** y subidas de nivel **por turnos**: sube un jugador cada vez, con una ventana de su color.
- Los caídos quedan derribados unos segundos y un compañero puede **reanimarlos**; quedarse junto a un compañero en crisis la acorta.
- **Online** con anfitrión y hasta tres PC invitados (ENet): sala por **código de 8 letras**, IP o apertura automática del puerto (UPnP), cada PC con su cámara y su guardado, y un bot que ocupa el sitio de quien se desconecta hasta que vuelve.

### Progreso y menús

- **Tres huecos de guardado**, con dinero, desbloqueos y logros por hueco, y **copia en la nube** con tu cuenta de GitHub (un gist secreto) para seguir en otro PC; si una partida ha cambiado en dos PC, el juego pregunta con cuál quedarse ([guía](docs/GUARDADO_NUBE.md)).
- **Tienda de antigüedades:** potenciadores permanentes, personajes, compañeros y **vestuario** (26 prendas que se ven sobre el modelo).
- **La Biblioteca:** bestiario, arsenal y lugares, con notas de diario de los años 20 y los mapas de cada escenario.
- **18 logros** con recompensa, intro y **relatos** que cuentan cada nivel antes de jugarlo.
- **Selección para cuatro a la vez:** cada uno se une con Start, elige personaje y compañero y los gira para verlos por todos lados.
- **Accesibilidad:** tamaño de la interfaz, balas de alto contraste, menos destellos y temblor de cámara regulable. Controles reasignables en mando y teclado.

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

### Los jefes

| El shoggoth primigenio | Padre Dagon | Cthulhu |
|:---:|:---:|:---:|
| ![El shoggoth primigenio](docs/img/jefe_shoggoth.jpg) | ![Padre Dagon](docs/img/jefe_dagon.jpg) | ![Cthulhu](docs/img/jefe_cthulhu.jpg) |
| Persigue por los túneles del mar subterráneo gritando «¡Tekeli-li!». | Emerge de las simas del Arrecife del Diablo, golpea con las manos y llama a los Profundos. | Asoma por la puerta de R'lyeh, barre con los tentáculos y, al caer, se recompone una vez. |

### Menús

| | |
|:---:|:---:|
| ![Selección de personaje a cuatro](docs/img/seleccion.jpg) | ![Mapa de la campaña](docs/img/mapa.jpg) |
| **Selección.** Hasta cuatro jugadores eligen a la vez personaje, vestuario y compañero, cada uno con su mando. | **El mapa.** Tres partes de cinco niveles que se abren al superar el anterior. |
| ![Relato del nivel](docs/img/relato.jpg) | ![Ficha del personaje](docs/img/ficha.jpg) |
| **Relatos.** Cada nivel se cuenta antes de jugarlo, sobre el mapa del lugar. | **La ficha** del personaje en partida: atributos, armas y objetos. |
| ![Tienda de antigüedades](docs/img/tienda.jpg) | ![La Biblioteca](docs/img/biblioteca.jpg) |
| **La tienda de antigüedades,** con el anciano tras el mostrador. | **La Biblioteca:** bestiario, arsenal y lugares, con notas de diario. |
| ![Logros](docs/img/logros.jpg) | ![Jugar online](docs/img/online.jpg) |
| **Logros,** con su recompensa y su progreso. | **Jugar online:** crear una sala o unirse con su código. |

## La campaña

Tres partes de cinco niveles. Cada nivel se abre al superar el anterior, y cada parte, al superar la anterior. Cada parte vuelve a empezar por las criaturas más débiles, pero es más difícil que la anterior contando con lo comprado en la tienda.

### Parte 1 · *En las montañas de la locura* (la Antártida)

| Nivel | Criaturas | Evento final |
|---|---|---|
| 1. Campamento base en la costa del mar de Ross | Pingüinos albinos ciegos, fragmentos protoplásmicos | El Acechador |
| 2. El campamento destruido de Lake | Antiguos revividos, Antiguos alados | El primero en despertar |
| 3. El paso de la cordillera y sus cavernas | Shoggoths esclavos, shoggoths miméticos | El shoggoth de la caverna |
| 4. La ciudad ciclópea de los Antiguos | Antiguos guerreros, Antiguos mutilados | El guardián de la ciudad |
| 5. Los túneles y el abismo del mar subterráneo | Shoggoths de ojos luminosos, Antiguos del mar abisal | **Jefe: el shoggoth primigenio** |

### Parte 2 · *La sombra sobre Innsmouth* (Nueva Inglaterra)

| Nivel | Criaturas | Evento final |
|---|---|---|
| 1. Newburyport y la carretera a Innsmouth | Habitantes de Innsmouth, acólitos de la Orden de Dagon | El diácono de la Orden |
| 2. Las calles de Innsmouth y el templo de la Orden | Híbridos avanzados, sacerdotes de la tiara | El sumo sacerdote de la Orden |
| 3. El hotel Gilman House y la huida por los tejados | Profundos, Profundos escupidores, el Acechador | Sobrevivir a la horda del Arrecife del Diablo |
| 4. Los pantanos y la vía muerta del tren a Rowley | Profundos ancianos de Y'ha-nthlei, Profundos de la ciénaga | Barnabas Marsh, transformado |
| 5. El Arrecife del Diablo y Y'ha-nthlei | Pth'thya-l'yi, Madre Hydra | **Jefe: Padre Dagon** |

### Parte 3 · *La llamada de Cthulhu* (Providence, Luisiana y el Pacífico)

| Nivel | Criaturas | Evento final |
|---|---|---|
| 1. Providence: el estudio del escultor Wilcox | Pesadillas de la oleada de sueños, cultistas | La pesadilla del bajorrelieve |
| 2. Los pantanos de Luisiana: el ritual del culto | Diablos con alas de murciélago, cultistas armados del *Alert* | El sacerdote del ritual |
| 3. Los muelles y la cubierta del *Alert* | Engendros de Cthulhu, Profundos servidores | El engendro mayor |
| 4. La tormenta en el Pacífico | La cosa blanca polipoide, Ángulos devoradores | La cosa blanca del lago oculto |
| 5. R'lyeh emergida: la puerta colosal | Primigenios menores, emanaciones de la puerta | **Jefe: Cthulhu** |

## Personajes

Todos proceden de los relatos de Lovecraft o son parientes y allegados inventados de sus personajes. Se empieza con cuatro (Dyer, Olmstead, Peaslee y Whipple); el resto se compra en la tienda.

Cada investigador tiene **siete atributos** (Poder, Inteligencia, Fuerza, Constitución, Tenacidad, Destreza y Cultura), a 10 más un reparto de 20 puntos según su historia. De ellos salen la vida, la cordura, el esquive, la velocidad y el daño de cada tipo de arma, y al subir de nivel ganan un punto más.

![Dyer, Olmstead, Legrasse, Johansen, Peaslee, Varga y Whipple](docs/img/personajes_1.jpg)
![Blake, Iwanicki, Elwood, Malone, Armitage y West](docs/img/personajes_2.jpg)

Las caras están dibujadas a mano, voxel a voxel, en la propia cabeza del modelo: cejas, ojos con iris, nariz en relieve, bigotes, gafas, pecas y labios.

![Las trece caras de cerca](docs/img/cabezas.jpg)

| Personaje | Arma inicial | Rasgo | Esquive | Relato de origen |
|---|---|---|---|---|
| **William Dyer**, geólogo de la Miskatonic | Stielhandgranate | Explosiones un 25 % más grandes | Deslizamiento | *En las montañas de la locura* |
| **Robert Olmstead**, viajero y narrador de Innsmouth | Webly Mk VI | Esquive un 30 % más largo | Voltereta | *La sombra sobre Innsmouth* |
| **Amelia Peaslee**, arqueóloga | Rifle de palanca | Más suerte: a veces, una cuarta mejora para elegir | Voltereta | *La sombra fuera del tiempo* |
| **Dra. Marian Whipple**, doctora | Bisturís | Reanima a los compañeros un 50 % más rápido | Salto | *La casa maldita* |
| **John R. Legrasse**, inspector de Nueva Orleans | Escopeta de corredera | 25 % más de daño contra cultistas y humanos | Salto | *La llamada de Cthulhu* |
| **Gustaf Johansen**, segundo oficial del *Emma* | Machete | 25 % más de daño cuerpo a cuerpo | Plancha | *La llamada de Cthulhu* |
| **Madame Ludmila Varga**, médium de Arkham | Necronomicón | Las armas arcanas le cuestan la mitad de cordura | Destello | Médium de Arkham |
| **Henrietta Blake**, escritora | Trapezoedro | 15 % más de experiencia por gema | Deslizamiento | *El morador de las tinieblas* |
| **Padre Iwanicki**, sacerdote de San Estanislao | Fórmula de expulsión | Aura que calma: él y los compañeros cercanos recuperan cordura | Voltereta | *Los sueños en la casa de la bruja* |
| **Sargento Frank Elwood**, veterano de la Gran Guerra | Pistola Mauser C96 | 15 % menos de daño físico | Plancha | *Los sueños en la casa de la bruja* |
| **Vera Malone**, contrabandista de Red Hook | Thompson M1928 | Hasta un 50 % más de daño cuanto más cerca está el enemigo | Deslizamiento | *El horror de Red Hook* |
| **Profesor Henry Armitage**, bibliotecario de la Miskatonic | Polvo de Ibn-Ghazi | Las armas mágicas se recargan un 20 % antes | Destello | *El horror de Dunwich* |
| **Herbert West**, médico reanimador | Inyector de West | Al subir de nivel cura un 15 % de vida a los compañeros cercanos | Voltereta | *Herbert West, reanimador* |

## Compañeros

Cada jugador puede llevar uno. Suben de nivel con él y se compran en la tienda.

![Perro, gato, rata, sapo, búho, shoggoth bebé, Mini-Byakhee y cuervo](docs/img/companeros_1.jpg)
![Polilla, gaviota, Mini-Mi-Go, araña de Tíndalos, serpiente de Yig, pez de Innsmouth, Mini-Dhole y cabra](docs/img/companeros_2.jpg)

<details>
<summary><b>Los 16 compañeros</b></summary>

| Compañero | Qué hace |
|---|---|
| Perro de trineo de Lake | Corre hacia los enemigos cercanos y los muerde, más fuerte cuanto más nivel tienes. |
| Gato de Ulthar | Araña a los que se acercan; si te hieren, se eriza y ataca el doble de rápido. |
| Rata de las Paredes | Escarba y encuentra dólares; a veces, un baúl arcano. |
| Sapo de Innsmouth | Escupe baba venenosa que deja un charco que daña y debilita. |
| Búho de los sueños | Un 12 % más de experiencia, hasta un 30 % con el nivel. |
| Shoggoth bebé | Va pegado a ti y se traga las balas enemigas que pasan cerca. |
| Mini-Byakhee | Vuela alto y cae en picado: golpe en área que empuja. |
| Cuervo de Arkham | Te trae las gemas lejanas y, de paso, roba unas monedas. |
| Polilla de Leng | Su polvo confunde a los grupos: vagan sin rumbo y no disparan. |
| Gaviota de Innsmouth | Trae pescado que cura vida y cordura a quien más lo necesita; chilla al ver una élite. |
| Mini-Mi-Go | Dispara rayos al enemigo más cercano. |
| Araña de Tíndalos | Se teletransporta detrás de un enemigo, muerde fuerte y aturde. |
| Serpiente de Yig | Muerde y envenena. |
| Pez de Innsmouth | Toma carrerilla y embiste a los que encuentra en el camino. |
| Mini-Dhole | Excava y sale bajo los grupos de enemigos: los golpea, los empuja y los aturde. |
| Cabra de los bosques | Embestida que empuja y aturde. |

</details>

## Armas y objetos

**50 armas** (16 físicas, 17 de fuego y 17 mágicas), cada una con su evolución:

![Iconos de las 50 armas](docs/img/armas.jpg)

Todas disparan solas y cada una decide en sus datos cómo apunta: al más cercano, a la zona más densa, a la élite, alrededor del personaje… Suben de nivel del 1 al 5 y su daño crece con los atributos de su tipo. Con el arma al nivel 5 y su objeto pareja, un baúl arcano la convierte en su **evolución**:

![Iconos de las 50 evoluciones](docs/img/evoluciones.jpg)

<details>
<summary><b>Las 50 armas y sus evoluciones</b></summary>

| Arma | Tipo | Cómo funciona | Evolución (con) |
|---|---|---|---|
| Ancla del *Alert* | Física | Un ancla con cadena que gira alrededor del personaje a mucha distancia, lenta y pesada. | Ancla de Johansen (Coraza de foca) |
| Arpón ballenero | Física | Atraviesa y arrastra a los enemigos menores. | Arpón de Nantucket (Plomada) |
| Ballesta | Física | Virotes que atraviesan y dejan clavado al enemigo un instante. | Ballesta de la fortuna (Dado de hueso) |
| Bastón estoque | Física | Estocada larga que atraviesa todo lo que hay en la línea. | Estoque del duelista (Piedra de afilar) |
| Bisturís | Física | Abanico de hojas que atraviesan. | Instrumental (Abrigo de reno) |
| Bumerán | Física | Va hasta su alcance y vuelve, golpeando a la ida y a la vuelta. | Bumerán de hueso (Esquís de Pabodie) |
| Cepos | Física | Cepos en el suelo: el primero que los pisa queda atrapado y herido. | Cepos del cazador (Collar de colmillos) |
| Cóctel Molotov | Física | Botella en arco que deja un charco en llamas. | Cóctel del *Emma* (Petaca de ron) |
| Gas de cloro | Física | Nube tóxica que deriva hacia los enemigos y los envenena. | Gas mostaza (Elixir de Curwen) |
| Inyector de West | Física | El enemigo que muere con el suero se levanta 6 s como aliado. | Reactivo perfeccionado (Botiquín) |
| Lanzaquímicos | Física | Frasco de ácido: los del charco reciben un 25 % más de daño. | Botica de Arkham (Láudano) |
| Látigo | Física | Latigazo largo en arco por delante. | Látigo del domador (Silbato de Lake) |
| Machete | Física | Tajo circular alrededor del personaje. | Machete del cañaveral (Guantes de estibador) |
| Martillo de geólogo | Física | Grieta en línea recta que daña y aturde. | Martillo de la Barrera (Crampones) |
| Red de pesca | Física | Inmoviliza al grupo más denso 2 s; las élites solo se frenan. | Red de Innsmouth (Escamas de Profundo) |
| Stielhandgranate | Física | Granada de palo a la zona más densa; gran explosión. | Carga concentrada (Reflejos) |
| Ametralladora Lewis | De fuego | Torreta en trípode que dispara sola al más cercano durante 8 s. | Nido de ametralladoras (Manual de tiro) |
| Antitanque Mauser | De fuego | Disparo muy lento que atraviesa a todos los de la línea. | Cañón antitanque (Medallón del cazador) |
| BAR M1918 | De fuego | Ráfagas cuyas balas rebotan hacia otro enemigo. | BAR de asalto (Botas de nieve) |
| Bobina Tesla | De fuego | Rayo que salta de un enemigo a otro, hasta cuatro. | Bobina de Nikola (Vara de zahorí) |
| Escopeta de corredera | De fuego | Perdigones que se abren en anillo alrededor del personaje. | Escopeta de trinchera (Bandolera) |
| Flammenwerfer | De fuego | Chorro de fuego en cono que deja el suelo ardiendo. | Aliento de Moloch (Fósforos de Cthugha) |
| Fuegos artificiales | De fuego | Cohetes erráticos que estallan en chispas. | Gran castillo de fuegos (Petardos) |
| Lugers a dos manos | De fuego | Disparan a la vez hacia donde andas y hacia atrás. | Lugers del as (Gafas de aviador) |
| Mortero Stokes | De fuego | Proyectil en arco alto al grupo más denso; explosión grande. | Batería de morteros (Pólvora de Ponape) |
| Nagant de Danforth | De fuego | Su cadencia se acelera mientras tiene a quién disparar. | Nagant del vigía (Lupa) |
| Pistola Mauser C96 | De fuego | Ráfagas cortas de tres trazadoras. | Mauser de Tillinghast (Reloj de Tillinghast) |
| Pistola de bengalas | De fuego | Bengala que atrae a los enemigos cercanos. | Bengala del faro (Capa del Hombre Negro) |
| Recortada | De fuego | Dos disparos de perdigones en un cono corto que empuja mucho. | Recortada del contrabandista (Diente de shoggoth) |
| Rifle de palanca | De fuego | Disparos rápidos que atraviesan a varios enemigos. | Rifle Miskatonic (Diario de campo) |
| Springfield M1903 | De fuego | Disparo lento que busca a la élite; a veces, crítico triple. | Springfield del francotirador (Ojo de Pickman) |
| Thompson M1928 | De fuego | Ráfagas cerradas de proyectiles pequeños. | Thompson de Chicago (Oro de Obed) |
| Webly Mk VI | De fuego | Proyectiles pesados que hacen retroceder. | Revólver del vigía (Brújula de Lake) |
| Aliento de Ithaqua | Mágica | Viento helado en cono que frena y congela. | Aliento del Wendigo (Pemmican) |
| Báculo del Farolero | Mágica | Fuegos fatuos que buscan solos a los enemigos. | Linterna de los fatuos (Pipa de espuma) |
| Daga ritual | Mágica | Maldición que salta a los de al lado si el enemigo muere maldito. | Daga del sacrificio (Colmillo de ghoul) |
| Esfera de Yog-Sothoth | Mágica | Orbe lento que atrae a los enemigos a su centro y los tritura. | La Puerta y la Llave (Llave de plata) |
| Fórmula de expulsión | Mágica | Onda que empuja y aturde. | Exorcismo mayor (Signo Primigenio) |
| Lente del Éter | Mágica | Rayo sostenido cuyo daño crece hasta el triple. | Ojo del Éter (Catalejo) |
| Llama de Cthugha | Mágica | Bola de fuego vivo que atraviesa y deja un rastro ardiendo. | Llama del culto (Talismán esotérico) |
| Lámpara de Alhazred | Mágica | Haz de luz que barre en círculo alrededor del personaje. | Lámpara del Árabe Loco (Ankh de Nephren) |
| Necronomicón | Mágica | Páginas que orbitan alrededor del personaje. | Necronomicón completo (Manuscritos pnakóticos) |
| Orbe Mi-Go | Mágica | Orbe de Yuggoth que vuela a tu alrededor y dispara solo. | Enjambre de Yuggoth (Cristal de Ithaqua) |
| Polvo de Ibn-Ghazi | Mágica | Nube que ralentiza y debilita a los de dentro. | Polvo de los Antiguos (Mapa de Leng) |
| Rayo de Yith | Mágica | Congela en el tiempo; el daño se aplica al final, un 50 % mayor. | Rayo de la Gran Raza (Clepsidra de Yith) |
| Resonador | Mágica | Su pulso deshace las balas enemigas cercanas. | Gran resonador (Escudo de Nodens) |
| Signo Amarillo | Mágica | Los que lo miran enloquecen y atacan a los suyos. | El Rey de Amarillo (Salterio) |
| Signo Arcano | Mágica | Signo en el suelo que daña, empuja y frena las balas enemigas. | Signo Mayor (Escapulario) |
| Tentáculos de Shub | Mágica | Tentáculos que brotan del suelo bajo enemigos al azar. | Las Mil Crías (Tablilla de Eltdown) |
| Trapezoedro | Mágica | Rayo de luz concentrada que daña todo lo que atraviesa. | Trapezoedro despierto (Ídolo de Cthulhu) |

</details>

**50 objetos**, de la subida de nivel (los potenciadores permanentes se compran en la tienda):

![Iconos de los 50 objetos](docs/img/objetos.jpg)

<details>
<summary><b>Los 50 objetos</b></summary>

| Objeto | Efecto |
|---|---|
| Abrigo de reno | +20 de vida máxima |
| Ankh de Nephren | Una vez por nivel, al caer te levantas con el 30 % de vida |
| Bandolera | +1 proyectil en las armas de balas y lanzados |
| Botas de nieve | +8 % de velocidad al andar |
| Botiquín | Recupera 0,5 de vida por segundo |
| Brújula de Lake | +30 % de radio para recoger experiencia |
| Capa del Hombre Negro | Al esquivar dejas un señuelo que atrae a los enemigos |
| Catalejo | +10 % de alcance de las armas |
| Clepsidra de Yith | +15 % de duración de zonas, órbitas, rayos y torretas |
| Collar de colmillos | +25 % de daño de los críticos |
| Colmillo de ghoul | Cada enemigo abatido cura 0,15 de vida |
| Coraza de foca | −2 al daño físico de cada golpe |
| Crampones | +15 % de distancia del esquive |
| Cristal de Ithaqua | 6 % de que el impacto frene al enemigo 1,5 s |
| Dado de hueso | +15 % de suerte: a veces una opción más al subir de nivel |
| Diario de campo | +20 de cordura máxima |
| Diente de shoggoth | +20 % de daño con menos del 30 % de vida |
| Elixir de Curwen | +15 % de daño durante 2 s tras esquivar |
| Escamas de Profundo | Devuelve el 30 % del daño de contacto |
| Escapulario | +25 % de invulnerabilidad tras recibir un golpe |
| Escudo de Nodens | Cada 25 s absorbe un golpe entero |
| Esquís de Pabodie | +1 esquive seguido antes de recargar |
| Fósforos de Cthugha | 6 % de que el impacto prenda al enemigo 3 s |
| Gafas de aviador | +0,08 s de invulnerabilidad al esquivar |
| Guantes de estibador | +12 % de daño físico y +10 % de empuje |
| Llave de plata | Otras opciones en la subida de nivel, una vez por nivel |
| Lupa | +10 % de experiencia |
| Láudano | Las crisis de locura duran un 20 % menos |
| Manual de tiro | +12 % de daño de las armas de fuego |
| Manuscritos pnakóticos | +12 % de daño de las armas mágicas |
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
| Ídolo de Cthulhu | +12 % de enemigos, de experiencia y de dólares |

</details>

## Bestiario

47 criaturas, entre ellas 18 seres únicos (minijefes y jefes). Cada una tiene su escalón (del 1 al 5), su comportamiento y su patrón de ataque, todo en datos. Las de escalón bajo forman la masa de la horda; los escalones 4 y 5 son élites.

**Parte 1:** pingüino albino ciego, fragmento protoplásmico, Antiguo revivido, Antiguo alado, shoggoth esclavo, Antiguo guerrero, Antiguo mutilado, shoggoth de ojos luminosos y Antiguo del mar abisal.

![Criaturas de la parte 1](docs/img/bestiario_1.jpg)

**Parte 2:** viejo y vecina de Innsmouth, acólito de la Orden de Dagon, híbridos avanzados, sacerdote de la tiara, Profundo, Profundo escupidor, Profundo anciano de Y'ha-nthlei y el Acechador.

![Criaturas de la parte 2](docs/img/bestiario_2.jpg)

**Parte 3:** cultista de Cthulhu, cultista armado del *Alert*, pesadilla de la oleada de sueños, diablo con alas de murciélago, engendro de Cthulhu, la cosa blanca polipoide, emanación de la puerta y primigenio menor.

![Criaturas de la parte 3](docs/img/bestiario_3.jpg)

Algunas tienen comportamientos propios: el pingüino ciego va hacia donde oyó al jugador, el shoggoth mimético se disfraza de Antiguo y se transforma al acercarse, las pesadillas atraviesan el decorado, los diablos caen en picado y los Profundos de la ciénaga salen del agua. Los Ángulos devoradores de R'lyeh no se matan: se esquivan.

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

Salen de capturas automáticas del juego: `sh tools/capturas_readme.sh` juega las partidas con bots y fotografía menús y modelos, y `python tools/montar_readme.py` las reduce a 960 px, monta las láminas de modelos, caras e iconos (leyendo los mismos datos que usa el juego) y hace con ffmpeg el GIF y un vídeo MP4 con sonido. También deja `docs/img/vista_previa.jpg` (1280 × 640), la imagen que enseña GitHub al compartir el enlace del repositorio.

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

## Derechos y créditos

- **Ambientación:** los relatos de H. P. Lovecraft son de **dominio público** en España y la Unión Europea, y todo el contenido del juego procede de ellos. El juego no tiene relación con *Call of Cthulhu* (marca de Chaosium) ni reproduce reglas, textos o ilustraciones del juego de rol ni de adaptaciones modernas.
- **Motor:** [Godot Engine](https://godotengine.org/) (licencia MIT).
- **Tests:** [GUT](https://github.com/bitwes/Gut) (licencia MIT), en `addons/gut/`.
- **Fuente de la portada:** *IM FELL English SC*, de Igino Marini, con licencia [SIL Open Font License 1.1](resources/fonts/OFL_IMFellEnglishSC.txt).
- **Efectos de sonido:** [Kenney](https://kenney.nl/) (CC0) y sintetizados para el juego.
- **Música:** del autor (portada y primer nivel) y pistas CC0 de [OpenGameArt](https://opengameart.org/) de Eldritch Grim, Juhani Junkala, isaiah658 y otros; la lista completa, con autor y enlace, está en [`data/musica.json`](data/musica.json).
- **Diseño, ilustraciones de la portada y la tienda:** Sergio Sánchez Custodio.
- **Uso de IA:** el código, los modelos voxel (generados por programas) y los textos se desarrollan con [Claude Code](https://claude.com/claude-code) (Anthropic), bajo la dirección del autor. Los iconos de armas y objetos y las referencias de diseño se generaron con FLUX (Black Forest Labs), en [Replicate](https://replicate.com/) y en local con ComfyUI.

## Licencia

Licencia mixta; el detalle está en [`LICENCIA.md`](LICENCIA.md).

- **El código** (scripts, *shaders*, escenas, herramientas, tests, datos de juego y documentación) se publica bajo la **GNU General Public License v3.0**, con el texto completo en [`LICENSE`](LICENSE). Puedes copiarlo, modificarlo y redistribuirlo, incluso con fines comerciales, siempre que lo que redistribuyas basado en él se publique también bajo GPL-3.0 y con su código fuente.
- **Los recursos del juego** (el arte, la música del autor, los textos del juego y el nombre *Lovecraft Library: Surviving Cthulhu*) tienen **todos los derechos reservados**. Se pueden usar para jugar, compilar o probar el proyecto, pero no para reutilizarlos en otros.
- Las piezas de terceros conservan su propia licencia (ver [Derechos y créditos](#derechos-y-créditos)).
