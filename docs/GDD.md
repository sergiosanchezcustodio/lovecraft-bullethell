# Documento de diseño (GDD)

**Título:** provisional, *Lovecraft Bullet Hell* (pendiente, D-01).
**Versión:** 0.2 · fase 0 cerrada · 24-09-2026.

Documento vivo de diseño. Parte de la especificación original, [`PROMPT_juego_lovecraft.md`](PROMPT_juego_lovecraft.md), que se conserva sin cambios, e incorpora las decisiones tomadas después (sección 12). Si una decisión cambia algo de la especificación, prevalece lo que diga este documento.

Documentos relacionados: [`ROADMAP.md`](ROADMAP.md) (fases y estado) y [`../CLAUDE.md`](../CLAUDE.md) (pipeline de arte, entorno y lecciones técnicas).

---

## 1. Visión

Bullet hell isométrico con disparo automático, para 1–4 jugadores en cooperativo local. Un grupo de investigadores de los relatos de Lovecraft atraviesa los escenarios de tres historias, enfrentándose a horrores cada vez más antiguos, hasta despertar a Cthulhu.

**Género.** Híbrido entre bullet hell (los enemigos llenan la pantalla de proyectiles con patrones que hay que esquivar) y "survivors" (hordas, disparo automático y subida de nivel dentro de la partida).

**Tono.** Horror cósmico, oscuro y opresivo. Luz escasa, niebla, colores fríos con acentos cálidos (farolillos, fuego) y enfermizos (verdes, cian bioluminiscente).

### Pilares de diseño
1. **Esquivar es la habilidad.** El disparo es automático; la pericia del jugador está en el movimiento y el esquive.
2. **Escalada del horror.** Cada nivel añade un escalón de criaturas más poderosas sin retirar las anteriores.
3. **Cooperativo primero.** Todo sistema se diseña para 1–4 jugadores.
4. **Legibilidad.** Con decenas de enemigos y cientos de balas, el jugador siempre distingue su personaje, a sus compañeros y las balas peligrosas, y sabe si dañan la vida o la cordura.
5. **Los relatos inspiran; la jugabilidad manda.** Escenarios, criaturas y personajes salen de los textos de Lovecraft, pero se aceptan licencias (por ejemplo, una criatura en un escenario distinto al de su relato) cuando mejoran el juego.

---

## 2. Estructura

- **15 niveles:** 3 partes × 5 niveles, con un jefe al final de cada parte. Cada parte se ambienta en un relato y cada nivel es un escenario distinto de ese relato.
- **Modos de partida:** *Campaña* (las 3 partes seguidas) y *Por partes* (una sola parte de 5 niveles). En ambos, la progresión del personaje empieza de cero.
- **Objetivo y duración de un nivel (D-02):** supervivencia por oleadas de 8–10 minutos. Los niveles 1 a 4 de cada parte terminan con un evento final sin jefe, por ejemplo una última oleada con las élites del nivel. Solo el nivel 5 termina con el jefe de la parte. El tipo de objetivo y la duración son datos del nivel, para poder variar niveles concretos. Campaña de unas 2–2,5 horas sin contar reintentos.
- **Escenarios (D-03):** arena finita de unas 3×3 pantallas (con el zoom normal de un jugador), cerrada por el propio decorado: acantilados, agua, muros. Tiene puntos de interés, como fuentes de luz que recuperan cordura y obstáculos que sirven de cobertura o de trampa. Los enemigos aparecen fuera de cámara. El tamaño es un dato del nivel.
- **Época:** años 20 y 30, sin fechas exactas en pantalla. Las partes siguen el orden fijado aunque los relatos originales ocurran en otro orden.

### 2.1 Escalones de enemigos
- Cada criatura tiene un **escalón** del 1 al 5, que decide la jugabilidad y no el momento en que aparece en el relato. Las dos criaturas nuevas de cada nivel son de su escalón: las del nivel 3 son de escalón 3.
- **Escalada acumulativa:** en el nivel N aparecen criaturas de los escalones 1 a N.
- **Proporción:** los escalones bajos aparecen en mayor número. Peso de aparición configurable por datos: para una criatura de escalón *t* en el nivel *N*, peso ∝ 2^(N − t).
- **Élites:** los escalones 4 y 5 son élites, con un tope de enemigos simultáneos. Los seres únicos (Barnabas Marsh, Madre Hydra, Pth'thya-l'yi) necesitan un tratamiento propio (D-04).
- **Dificultad entre partes:** en la campaña, cada parte vuelve a empezar por el escalón 1 con el personaje ya mejorado (D-13).
- **Jefes en escalada:** shoggoth primigenio < Padre Dagon < Cthulhu. Los jefes de las partes 1 y 2 nunca son entidades superiores a Cthulhu en la jerarquía de los Mitos.

Leyenda de las tablas: **(C)** aparece en el relato · **(M)** se menciona en él · **(V)** variante directa de algo que aparece.

### 2.2 Parte 1: *En las montañas de la locura* (Antártida)
La expedición de la Universidad de Miskatonic descubre, tras una cordillera imposible, la ciudad muerta de los Antiguos y lo que aún vive bajo ella. Naturaleza hostil y horrores prehumanos: **no hay enemigos humanos**. Todas las criaturas son Antiguos, shoggoths o pingüinos del abismo y sus variantes; los Engendros de Cthulhu se reservan para la parte 3.

| Nivel | Escenario | Criaturas nuevas |
|---|---|---|
| 1 | Campamento base en la costa del mar de Ross | Pingüinos albinos ciegos gigantes (C) · Fragmentos protoplásmicos de shoggoth (V) |
| 2 | El campamento destruido de Lake | Antiguos revividos, los especímenes que despertaron (C) · Antiguos alados (V) |
| 3 | El paso de la cordillera y sus cavernas | Shoggoths esclavos (C) · Shoggoths miméticos, que imitan la forma y la voz de sus amos (C) |
| 4 | La ciudad ciclópea de los Antiguos | Antiguos guerreros (V) · Antiguos mutilados, cubiertos del limo de los shoggoths que los atacaron (V) |
| 5 | Los túneles y el abismo del mar subterráneo | Shoggoths de ojos luminosos, con ojos que se forman y deshacen en su masa (C) · Antiguos del mar abisal, los que se retiraron a las aguas subterráneas (V) |
| **Jefe** | | **El shoggoth primigenio de los túneles**, que persigue a los supervivientes gritando "¡Tekeli-li!" (C) |

### 2.3 Parte 2: *La sombra sobre Innsmouth* (Nueva Inglaterra)
El narrador llega a un puerto decadente cuyos habitantes se están convirtiendo en algo que pertenece al mar. Enlaza con la parte 3: los Profundos adoran a Cthulhu.

| Nivel | Escenario | Criaturas nuevas |
|---|---|---|
| 1 | Newburyport y la carretera a Innsmouth | Habitantes con "el aspecto de Innsmouth" (C) · Acólitos de la Orden Esotérica de Dagon (C) |
| 2 | Las calles de Innsmouth y el templo de la Orden | Híbridos avanzados a punto de volver al mar (C) · Sacerdotes de la tiara (C) |
| 3 | El hotel Gilman House y la huida por los tejados | Profundos, incluido el **Acechador** (C) · La horda del Arrecife del Diablo (C) |
| 4 | Los pantanos y la vía muerta del tren a Rowley | Barnabas Marsh transformado (M) · Profundos ancianos de Y'ha-nthlei (C) |
| 5 | El Arrecife del Diablo y la ciudad sumergida de Y'ha-nthlei | Pth'thya-l'yi, la antepasada milenaria del narrador (M) · Madre Hydra (M) |
| **Jefe** | | **Padre Dagon** (M) |

Modelos ya prototipados (`tools/gen_variantes.py`) que sirven de base: el Clásico para los híbridos y los Profundos comunes, el Bruto para Dagon y el Abisal para los Profundos ancianos de Y'ha-nthlei.

### 2.4 Parte 3: *La llamada de Cthulhu* (Providence, Luisiana y el Pacífico)
El rastro del culto a Cthulhu lleva de Providence a los pantanos de Luisiana y al Pacífico, donde R'lyeh emerge de las aguas.

| Nivel | Escenario | Criaturas nuevas |
|---|---|---|
| 1 | Providence: el estudio del escultor Wilcox | Pesadillas de la oleada de sueños (V) · Cultistas (C) |
| 2 | Los pantanos de Luisiana: el ritual del culto | Diablos con alas de murciélago de la leyenda del pantano (C) · Cultistas armados del *Alert* (C) |
| 3 | Los muelles y la cubierta del *Alert* | Engendros de Cthulhu (M) · Profundos servidores de Cthulhu (vínculo con la parte 2) |
| 4 | La tormenta en el Pacífico | La cosa blanca polipoide del lago oculto (C) · Ángulos devoradores de R'lyeh (C) |
| 5 | R'lyeh emergida: la puerta colosal | Primigenios menores que yacen con Cthulhu (M) · Emanaciones de la puerta: masas gelatinosas verdes que brotan de la puerta negra al abrirse, anticipo de Cthulhu (V) |
| **Jefe** | | **Cthulhu** (C) |

El relato apenas describe criaturas aparte de Cthulhu. Los Ángulos devoradores (la geometría imposible que engulle a un marinero) pueden ser enemigo o peligro del escenario; se decidirá al diseñar ese nivel.

---

## 3. Controles, interfaz y cámara

### 3.1 Controles
| Acción | Mando | Teclado (propuesta) |
|---|---|---|
| Movimiento | Stick izquierdo | WASD o flechas |
| Esquivar (impulso corto con invulnerabilidad breve) | A | Espacio |
| Menú de opciones en partida | Start | Esc |
| Ficha del jugador (estadísticas, armas, mejoras) | Select | Tab |
| Mapa del nivel | Cruceta abajo | M |
| Confirmar / volver en menús | A / B | Enter / Esc |
| Disparo | Automático, sin botón | Automático, sin botón |

Todas las acciones se pueden reasignar desde el menú de opciones.

### 3.2 Entrada y dispositivos
- **Unirse a la partida:** pantalla de "pulsa un botón para unirte"; cada dispositivo reclama un hueco de jugador (1–4). El teclado solo puede reclamar un hueco.
- **Conexión en caliente:** si un mando se desconecta, su personaje queda en pausa y protegido hasta que se reconecte o el jugador abandone.
- **Pausas y menús personales (D-16):** en solitario, cualquier menú pausa. En cooperativo solo pausan dos cosas:
  - *Start:* pausa la partida para todos.
  - *Subida de nivel:* pausa para todos. Cada jugador elige su mejora a la vez en su cuadrante y la partida se reanuda cuando todos han elegido.
  - *Ficha y mapa en cooperativo:* se abren y se cierran con su botón (no se mantienen pulsados) en el cuadrante del jugador, semitransparentes y sin pausar ni bloquear a los demás. El personaje sigue controlable mientras están abiertos. Si la ficha tiene páginas, se pasan con los gatillos superiores.
- **Capa de entrada:** los personajes nunca leen `Input` directamente; reciben acciones de una capa de abstracción por jugador. Imprescindible para el cooperativo local y deja preparado el online.

### 3.3 HUD
- Un panel por jugador en su esquina, siempre visible: **J1 arriba a la izquierda, J2 arriba a la derecha, J3 abajo a la izquierda, J4 abajo a la derecha**. Los huecos sin jugador no muestran panel.
- Cada panel: retrato, **barra de vida y barra de cordura** (colores claramente distintos), barra de experiencia y nivel, armas equipadas con su nivel, indicador de recarga del esquive y color del jugador (el mismo del anillo bajo su personaje).
- Información global en el borde superior central: parte y nivel actuales, progreso u objetivo del nivel y tiempo.
- Paneles compactos y semitransparentes para no tapar balas; el área de juego se ajusta para que ningún jugador quede detrás de un panel.

### 3.4 Cámara
- Ortográfica isométrica fija (rotación −30° en X, 45° en Y). Altura visible por defecto: 15 m (ajustable por datos).
- **Legibilidad del jugador:** anillo de color bajo los pies, un pequeño farol propio que lo ilumina a él y a lo que tiene cerca, y su silueta en el color del jugador cuando lo tapa el decorado.
- **Cooperativo local:** pantalla compartida. La cámara encuadra a todos los jugadores ajustando el zoom ortográfico entre un mínimo y un máximo; al llegar al máximo, los jugadores no pueden separarse más.

---

## 4. Mecánicas

### 4.1 Núcleo
- **Disparo continuo:** el personaje siempre está disparando. Sin ningún enemigo a tiro, cada arma dispara hacia donde mira el personaje.
- **Disparo automático (D-05):** cada arma dispara sola según su cadencia y patrón, y define en sus datos cómo elige objetivo: el enemigo más cercano, la zona más densa, alrededor del personaje, en arco… Por defecto, el más cercano. De momento el jugador no tiene opción de apuntado; como es un dato, podría añadirse más adelante.
- **Esquive:** impulso corto en la dirección de movimiento, con fotogramas de invulnerabilidad y tiempo de recarga. Es la herramienta principal para atravesar cortinas de balas.
  - En los personajes de la parte 1 es un **deslizamiento sobre la nieve**: pies por delante, cuerpo echado atrás y nieve que salta. Frena progresivamente hasta la velocidad de andar y se funde con el paso al incorporarse.
  - Valores de Dyer: 0,32 s, de 11,5 a 4,5 m/s, 0,36 s de invulnerabilidad y 1,2 s de recarga.
  - **Cada personaje tiene su propio esquive** (`CharacterData.dodge_style`, datos en `data/dodges/`). Cada estilo define su animación y también su movimiento:

| Estilo | Qué hace | Impulso | Invulnerable | Recarga |
|---|---|---|---|---|
| Deslizamiento | Sentado sobre la nieve, pies por delante | 11,5 m/s, 0,32 s | 0,36 s | 1,2 s |
| Voltereta | Se encoge y rueda 360° pegado a la nieve | 10,5 m/s, 0,34 s | 0,38 s | 1,2 s |
| Plancha de pingüino | Se tira de barriga con los brazos atrás y resbala | 12,5 m/s, 0,36 s | 0,38 s | 1,3 s |
| Salto | Salto en arco de unos 70 cm con los brazos arriba | 9,5 m/s, 0,42 s | 0,42 s | 1,3 s |
| Destello | Desaparece, cruza muy rápido con una estela breve y reaparece | 26 m/s, 0,13 s | 0,22 s | 1,1 s |

  - Por decidir qué esquive lleva cada personaje. De momento, Dyer usa el deslizamiento; en partida, F1 recorre los cinco.
  - Principio general: **toda acción del personaje enlaza con fluidez con el movimiento normal**. Los gestos de ataque se suman a la animación de andar, nunca la interrumpen.
- **Telegrafía:** todo ataque fuerte se anuncia con un aviso visual (marca en el suelo, brillo, animación de carga) proporcional a su daño.

### 4.2 Enemigos
Cada tipo combina dos elementos de diseño independientes, definidos por datos y reutilizables entre enemigos:
- **Movimiento:** perseguir, acechar y saltar, orbitar, cargar, emerger del suelo o del agua, volar, imitar…
- **Patrones de disparo:** ráfagas radiales, espirales, abanicos dirigidos, balas que persiguen, zonas de peligro en el suelo, rayos con aviso previo…

Cada ataque tiene además un tipo de daño (sección 4.4).

**Enemigos de la fase 1 (implementados en el hito 1.5):**

| Enemigo | Escalón | Movimiento | Ataques | Daño |
|---|---|---|---|---|
| Pingüino albino ciego (1,2 m) | 1 | Va hacia donde oyó al jugador por última vez y corrige cada ~1 s, así que esquivar de lado funciona. De cerca se echa atrás y embiste | Solo cuerpo a cuerpo: picotazo en la carga (contacto ×1,6) | Físico |
| Fragmento protoplásmico | 1 | Repta a tirones, al ritmo de su animación; se para al escupir | Glóbulos que silban "¡Tekeli-li!": dos ráfagas radiales lentas de 8, cada ~7 s | Mixto (y contacto mixto) |

Tras la primera partida de prueba (25-09-2026), no todos los enemigos disparan: los de horda más sencillos atacan solo cuerpo a cuerpo, y los del escalón 1 aparecen en poco número al principio.
| Acechador (élite de prueba, evento final) | 3 | Ronda al jugador a unos 6 m | Salto: marca roja en el suelo, 0,9 s de aviso, impacto en 1,7 m y anillo de 14 balas. Croar: aviso violeta y onda mental de 30 balas con tres huecos para atravesarla | Físico y mental |

### 4.3 Progresión dentro de la partida
- Los enemigos sueltan experiencia. Al subir de nivel, el jugador elige **1 de 3 mejoras** al azar: arma nueva, subir de nivel un arma o mejora pasiva. La elección pausa la partida (D-16).
- Cada arma tiene niveles del 1 al 5 (propuesta). Evoluciones o combinaciones: D-06.
- La progresión se conserva entre los niveles de la misma partida y se pierde al empezar una partida nueva.
- **Implementado en la fase 1:**
  - Las gemas de experiencia son **doradas y talladas**: corona clara, pabellón ámbar oscuro, material metálico con un leve brillo propio y sombra en el suelo. Cuanto más valen, mayores son, y vuelan hacia el jugador dentro de su radio de recogida.
  - La curva de experiencia es 5 × 1,22^(n−1) + 2(n−1) por nivel.
  - Hay cinco pasivas: velocidad, vida máxima, cordura máxima, recarga del esquive y radio de recogida. Cada una llega hasta nivel 5, y las de vida y cordura rellenan lo ganado.
  - Cada subida de nivel ofrece tres opciones distintas entre armas nuevas, subidas de arma y pasivas que no estén al máximo.
- **Crisis en la fase 1:** solo la parálisis. Mientras dura, el anillo del jugador late en violeta; cada congelación se avisa con un temblor y tiñe al personaje de violeta.

### 4.4 Vida y cordura
Cada personaje tiene dos recursos, **vida** y **cordura**, con valores base propios (sección 6). Los valores numéricos se ajustarán en pruebas (D-08).

| Tipo de daño | Resta | Ejemplos | Lenguaje visual (orientativo) |
|---|---|---|---|
| **Físico** | Vida | Garras, mordiscos, proyectiles materiales (Profundos, pingüinos del abismo) | Proyectiles sólidos |
| **Mental** | Cordura | Cánticos, susurros, visiones (sacerdotes de la tiara, pesadillas de Providence) | Violeta y ondulante, con un susurro |
| **Mixto** | Ambas | El grito "¡Tekeli-li!" del shoggoth, Cthulhu | Combina los dos lenguajes |

- **Pauta:** los escalones bajos hacen sobre todo daño físico; cuanto más alto el escalón, más daño mental. Los jefes combinan ambos.
- **Lenguaje visual implementado (hito 1.4):** todas las balas enemigas son redondas y tienen contorno oscuro para destacar sobre la nieve y en la oscuridad. Las balas se dibujan siempre por encima del decorado. Los avisos en el suelo usan el color del tipo de daño.
  - *Físico:* núcleo color hueso con borde rojo anaranjado, sólido y quieto.
  - *Mental:* anillo violeta que ondula y gira, con el centro oscuro.
  - *Mixto:* núcleo físico dentro de un anillo mental.
  - *Jugador:* trazadoras doradas alargadas y translúcidas, que no se confunden con las enemigas.
- **Radio de impacto del jugador:** 0,25 m, mucho menor que su silueta, como es habitual en el género. El radio de colisión de las balas es algo menor que el visual.
- **Legibilidad obligatoria:** los ataques mentales se distinguen de los físicos al instante, por forma, color y sonido. El jugador debe poder decidir en décimas de segundo qué esquivar primero según el estado de sus barras.
- **Otras pérdidas de cordura:**
  - *Presencia:* élites y jefes emiten un aura que drena cordura mientras el jugador está dentro de su radio.
  - *Armas arcanas:* cada uso cuesta cordura.
- **Recuperación de cordura:** lenta y pasiva lejos de los horrores; más rápida cerca de fuentes de luz del escenario (hogueras, farolas, lámparas) y cerca de compañeros.
- **Efectos de cordura baja:** susurros, bordes de pantalla que palpitan, desaturación, sombras fugaces. Son solo ambientación: **nunca ocultan ni falsean las balas reales**, y no hay balas ni enemigos falsos que puedan confundirse con los reales.

### 4.5 Crisis de locura
Cuando la cordura llega a cero, el personaje sufre una crisis temporal de 4–6 segundos. Al terminar, recupera una parte de la cordura (por ejemplo, el 30 %). El tipo se elige al azar con pesos por datos, que cada personaje puede tener propios.

| Crisis | Efecto |
|---|---|
| Parálisis catatónica | Congelaciones intermitentes (D-14): se queda clavado en instantes breves, unos 0,4 s cada 1–1,5 s, cada uno avisado con un temblor de unos 0,2 s. Sigue disparando, pero no puede moverse ni esquivar. Tiempos por datos |
| Huida histérica | Corre sin control en dirección contraria al horror más cercano |
| Vagar sin rumbo | Movimiento errático y lento; los controles solo obedecen parcialmente |
| Paranoia | Sus armas apuntan a los compañeros; sus disparos les restan **cordura, no vida**, con daño muy reducido (dato). Es la única excepción a "sin fuego amigo" (D-17). Solo en cooperativo; en solitario se sustituye por otra |
| Delirio | Controles invertidos |

- **Calmar a un compañero:** permanecer junto a un jugador en crisis la acorta progresivamente, con la misma interacción que la reanimación.
- **Locura acumulada** (configurable, activada por defecto, a validar en pruebas): cada crisis reduce la cordura máxima un porcentaje hasta el final del nivel.

### 4.6 Cooperativo
- Sin fuego amigo. Única excepción: la paranoia, cuyos disparos restan cordura a los compañeros (D-17).
- **Reanimación:** un jugador con la vida a cero queda derribado un tiempo; un compañero lo reanima quedándose junto a él. Si nadie lo hace, queda eliminado hasta el siguiente nivel.
- La dificultad escala con el número de jugadores (vida de los enemigos y densidad de aparición), con valores por datos.
- **Experiencia compartida (D-07):** la que recoge cualquier jugador cuenta para todos. Todos suben de nivel a la vez y cada uno elige su propia mejora. La curva de experiencia escala con el número de jugadores, por datos.

### 4.7 Muerte y recuperación
- Con la vida a cero, el personaje queda **derribado** (sección 4.6).
- **Vial de reactivo de West:** objeto raro de un solo uso que resucita automáticamente a su portador. Es la segunda oportunidad en solitario.
- El pasivo de Herbert West acelera las reanimaciones.
- Si todos los jugadores quedan eliminados, el nivel se pierde y se reintenta desde el último guardado.

### 4.8 Accesibilidad
- Deslizador en opciones para la intensidad de las distorsiones de pantalla, hasta desactivarlas (mareos y fotosensibilidad).
- Prohibidos los destellos estroboscópicos.

---

## 5. Armas

Todas disparan solas. Cada personaje empieza con una y consigue las demás al subir de nivel.

### 5.1 Convencionales (años 20)
| Arma | Patrón |
|---|---|
| Revólver .38 | Disparo único al enemigo más cercano, cadencia media. Arma de referencia |
| Pistola automática Colt .45 | Ráfagas cortas, más daño y menos alcance |
| Escopeta de dos cañones | Abanico corto de perdigones; el retroceso empuja a los enemigos |
| Subfusil Thompson | Chorro continuo que barre en arco |
| Rifle de caza | Disparo lento que atraviesa varios enemigos en línea |
| Cartuchos de dinamita | Lanzamiento en arco a zonas densas; explosión de área con retardo |
| Machete | Tajo circular alrededor del personaje, para cuando las hordas se acercan |
| Linterna de arco | Cono de luz que daña a las criaturas de la oscuridad |

### 5.2 Artefactos y saber arcano
Más potentes que las convencionales, pero **cada uso cuesta cordura**.

| Arma | Patrón | Origen |
|---|---|---|
| Polvo de Ibn-Ghazi | Nube que debilita a los enemigos y los vuelve vulnerables | *El horror de Dunwich* |
| Signo Arcano | Símbolo en el suelo que crea una zona que repele o daña a los enemigos | Los Mitos |
| Fórmula de expulsión | Onda expansiva periódica que empuja y aturde | *El horror de Dunwich* |
| Páginas del Necronomicón | Proyectiles orbitales de energía alrededor del personaje | Los Mitos |
| Trapezoedro Resplandeciente | Rayo de luz concentrada a través de la gema | *El morador de las tinieblas* |
| Reactivo de Herbert West | Frasco que al romperse reanima brevemente a enemigos caídos como aliados | *Herbert West, reanimador* |

---

## 6. Personajes jugables

Todos proceden de relatos de Lovecraft y cada parte tiene al menos un personaje nativo. Armitage y West vienen de relatos que no forman parte del juego (licencia aceptada). Cada uno tiene arma inicial, rasgo pasivo y un perfil de estadísticas: vida, cordura, velocidad, recarga del esquive y suerte en las mejoras. Los valores exactos, por datos.

| Personaje | Relato | Arma inicial | Rasgo pasivo | Perfil |
|---|---|---|---|---|
| William Dyer, geólogo | *En las montañas de la locura* (parte 1) | Cartuchos de dinamita (en la fase 1, además, el revólver) | Resistencia al frío y a los efectos de ralentización (D-19) | Mucha cordura |
| Robert Olmstead, narrador de Innsmouth | *La sombra sobre Innsmouth* (parte 2) | Revólver .38 | Esquive más largo; "sangre de Innsmouth": resistencia al daño de criaturas marinas | Equilibrado |
| Inspector John R. Legrasse | *La llamada de Cthulhu* (parte 3) | Escopeta de dos cañones | Más daño contra cultistas y enemigos humanos (D-19) | Equilibrado |
| Gustaf Johansen, marinero | *La llamada de Cthulhu* (parte 3) | Machete | Más vida; inmunidad al empuje (D-19) | Mucha vida |
| Profesor Henry Armitage | *El horror de Dunwich* | Polvo de Ibn-Ghazi | Las armas arcanas recargan antes | Cordura alta, vida baja |
| Herbert West | *Herbert West, reanimador* | Reactivo de West | Reanima a compañeros más rápido; curación en área al subir de nivel | Poca cordura, gran resistencia física |

---

## 7. Dirección de arte

El estilo general (voxel detallado a 32 voxels por metro, atmósfera y pipeline) está en `CLAUDE.md`.

- **Criaturas:** clásicas y oscuras, sin ropa ni adornos externos. Solo anatomía: escamas, púas, aletas, agallas, garras, tentáculos.
- **Híbridos de Innsmouth:** cuentan como humanos en cuanto a vestuario. Ropa de pueblo pesquero de los años 20, más deteriorada, rota y empapada cuanto más avanzada está la transformación. Lo inquietante es la mezcla de ropa normal y rasgos de pez.
- **Cultistas y humanos:** pueden llevar túnicas, adornos y símbolos, siempre ligados a la criatura que adora su culto, de modo que cada culto se reconozca por su silueta y su paleta.

| Culto | Motivos | Paleta |
|---|---|---|
| Orden Esotérica de Dagon (parte 2) | Joyas de oro extraño con relieves de peces, criaturas batracias y olas. Acólitos con túnicas sencillas y amuletos; sacerdotes con vestiduras ceremoniales y la tiara alta de oro | Oro deslustrado, verde marino, algas, coral |
| Culto de Cthulhu (parte 3) | El ídolo (cabeza de pulpo con tentáculos, cuerpo escamoso, alas rudimentarias) en piedra verdinegra, jeroglíficos desconocidos, la invocación "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn". Cultistas del pantano con túnicas oscuras, amuletos del ídolo, máscaras con tentáculos y antorchas; tripulación del *Alert* con ropa de marinero y símbolos del culto | Negro verdoso, hueso, resplandor de hogueras |

- **Personajes jugables:** proporciones humanas, ropa de época, paleta más cálida que la de los enemigos y siempre con el anillo de color del jugador.
- **Estilo de los personajes humanos** (jugables, cultistas e híbridos): voxel a bloques limpios, con volúmenes rectos de aristas suavizadas, detalles pintados sobre superficies planas, cara dibujada sin relieve y poco ruido de color. Decidido el 25-09-2026, a partir del rediseño de Dyer. Las criaturas pueden ser orgánicas y con más relieve.
- **Regla de contenido** (modelos, textos y diálogos): nada racista, sexista ni homófobo. Los cultistas son de géneros y edades variados, sin rasgos étnicos marcados que asocien un grupo real al mal; los identifica su culto. Los relatos originales contienen estereotipos de su época que no se reproducen.

---

## 8. Guardado

- **Local:** archivo en `user://` con versión de formato. Guarda la configuración (controles, audio, vídeo), las estadísticas históricas y la partida en curso al terminar cada nivel, para poder salir y retomarla desde el nivel siguiente.
- **Nube (fase 10, D-11):** el formato local debe ser serializable y versionado desde el principio, para poder subirlo más adelante sin cambios.

---

## 9. Requisitos técnicos

| Aspecto | Decisión |
|---|---|
| Motor | Godot 4.4 (instalada la 4.4.1), GDScript con tipado estático |
| Renderizador | Forward+ (D-15). Compatibility queda como reserva por línea de comandos (`--rendering-method gl_compatibility`) para capturar sin GPU, sin niebla volumétrica. Sin versión web |
| Gráficos | Voxel 3D a 32 voxels por metro como punto de partida |
| Animación | Por partes con pivote, rotadas por código, sin rigging |
| Datos | Enemigos, armas, personajes, niveles y oleadas como datos (`.tres` o JSON), nunca incrustados en la lógica |
| Tests | GUT para la lógica (daño, experiencia, pesos de aparición, guardado y carga); capturas automáticas para lo visual |

- **Rendimiento objetivo:** 60 FPS estables en un PC de gama media con 4 jugadores, unos 150 enemigos y 1.000 balas en pantalla. Cifras orientativas, a validar en la fase 1.
- **Optimización progresiva**, de menos a más invasiva y solo si la medición lo exige:
  1. Fusión de caras contiguas del mismo color (*greedy meshing*) en `voxel_builder.gd`.
  2. `MultiMeshInstance3D` por parte del cuerpo para las criaturas numerosas, con transformaciones por instancia para la animación.
  3. Menor resolución voxel en enemigos y personajes (los generadores tienen la escala como parámetro). **Requiere consulta previa.**
  4. Niveles de detalle (LOD) para modelos grandes.
- **Balas:** sin un nodo por bala. Se gestionan en arrays, se dibujan con `MultiMesh` y colisionan mediante una rejilla espacial propia o `PhysicsServer` directo.
- **Jefes colosales:** el JSON debe admitir una escala voxel propia por modelo, o representar solo la parte visible del jefe (Cthulhu emergiendo, Dagon desde el agua). **Enfoque a consultar antes de modelarlos.**
- **Escenarios:** generados con el mismo pipeline voxel (piezas combinables de suelo, muros y decorado), con la iluminación de la atmósfera definida.
- **Estructura de carpetas:** `scenes/`, `scripts/` por sistema (`player/`, `enemies/`, `weapons/`, `bullets/`, `ui/`, `save/`), `data/`, `models/`, `tools/`, `tests/`, `docs/`.

---

## 10. Derechos

Los relatos de H. P. Lovecraft son de dominio público en España y la UE, y todo el contenido de este documento procede de ellos. No se usa la marca "Call of Cthulhu" (Chaosium) ni se reproducen reglas, textos o ilustraciones del juego de rol ni de adaptaciones modernas. Cualquier contenido de otros autores de los Mitos se consulta antes. Antes de una publicación comercial conviene una revisión legal.

---

## 11. Glosario

- **Escalón:** nivel de dificultad de una criatura (1–5). Los escalones 4 y 5 son élites.
- **Élite:** enemigo de escalón 4 o 5, con tope de ejemplares simultáneos y aura de presencia.
- **Derribado:** jugador con la vida a cero, a la espera de reanimación.
- **Eliminado:** jugador derribado al que nadie reanimó a tiempo; vuelve en el siguiente nivel.
- **Crisis:** estado temporal que se desencadena con la cordura a cero.

---

## 12. Decisiones

| ID | Tema | Bloquea | Estado |
|---|---|---|---|
| D-01 | Título del juego | Publicación (fase 8) | Pendiente |
| D-02 | Objetivo y duración de cada nivel | Fase 1 | **Resuelta** |
| D-03 | Tamaño y forma de los escenarios | Fases 1 y 2 | **Resuelta** |
| D-04 | Escalones 4 y 5 y seres únicos | Fases 4 y 6 | Pendiente (la fase 1 usa un tope de élites configurable) |
| D-05 | Apuntado | Fase 1 | **Resuelta** |
| D-06 | Evoluciones de armas | Fase 3 (modelo de datos de armas) | Pendiente |
| D-07 | Experiencia en cooperativo | Fase 2 | **Resuelta** |
| D-08 | Cordura | — | Resuelta: se incluye. Valores numéricos por ajustar en pruebas |
| D-09 | Desbloqueos y acceso al modo *Por partes* | Fase 5 | Pendiente |
| D-10 | Modelo online | Fase 9 | Pendiente |
| D-11 | Guardado en la nube | Fase 10 | Pendiente |
| D-12 | Plataforma de distribución | Fase 8; condiciona D-10 y D-11 | Pendiente |
| D-13 | Reto al empezar cada parte en la campaña | Fase 6 | Pendiente |
| D-14 | Parálisis frente a la duración de las crisis | Fase 1 | **Resuelta** |
| D-15 | Renderizador | Fase 1 | **Resuelta** |
| D-16 | Pausas y menús personales | Fases 1 y 2 | **Resuelta** |
| D-17 | Paranoia frente a "sin fuego amigo" | Fase 2 | **Resuelta** |
| D-18 | Personajes disponibles en la fase 2 | Fase 2 | **Resuelta** |
| D-19 | Pasivos que dependen de mecánicas sin definir | Fase 4 | Pendiente |

D-01 a D-13 proceden de la especificación. D-14 a D-19 salen de las incoherencias y huecos detectados al redactar este documento (sección 13). Las decisiones bloqueantes de las fases 1 y 2 se resolvieron el 24-09-2026.

- **D-01 — Título del juego.**
- **D-02 — Objetivo de cada nivel.** ¿Sobrevivir un tiempo, eliminar un número de enemigos o llegar a un punto del mapa? ¿Cuánto dura un nivel?
  *Resuelta:* supervivencia por oleadas de 8–10 minutos. Solo el último nivel de cada parte (el 5) termina con jefe; los niveles 1 a 4 terminan con un evento final sin jefe. El tipo de objetivo es un dato del nivel. En la fase 1, versión de 5 minutos con el Acechador como élite en el evento final.
- **D-03 — Tamaño y forma de los escenarios.** El botón de mapa implica escenarios mayores que la pantalla. ¿Arena abierta o recorrido?
  *Resuelta:* arena finita de unas 3×3 pantallas, cerrada por el decorado, con fuentes de luz y obstáculos. Tamaño por datos.
- **D-04 — Escalones 4 y 5.** Incluyen seres únicos (Barnabas Marsh, Madre Hydra, Pth'thya-l'yi) que no pueden aparecer en número. *Recomendación de la especificación:* élites con tope de 1–2 simultáneos; los seres únicos, como minijefes con una única aparición en su nivel.
- **D-05 — Apuntado.** Automático al más cercano, en dirección de movimiento o elegible.
  *Resuelta:* lo decide cada arma en sus datos, con "al más cercano" por defecto. Sin opción de jugador de momento.
- **D-06 — Evoluciones de armas.** ¿Combinaciones de arma y pasiva al estilo "survivors"?
- **D-07 — Experiencia en cooperativo.** ¿Individual o compartida?
  *Resuelta:* compartida. Todos suben de nivel a la vez y cada uno elige su mejora. Curva escalada por número de jugadores.
- **D-08 — Cordura.** Resuelta: se incluye. Quedan por ajustar los valores numéricos.
- **D-09 — Desbloqueos.** ¿Hay desbloqueos permanentes (personajes, armas)? ¿El modo *Por partes* exige haber llegado antes a esa parte en la campaña?
- **D-10 — Modelo online.** Anfitrión y clientes con ENet, red de Steam o WebRTC; cómo se conectan los jugadores; si se mezclan jugadores locales y remotos; cámara propia por jugador remoto.
- **D-11 — Guardado en la nube.** Gist privado del jugador mediante el flujo de autorización por dispositivo de GitHub, servidor propio o guardado en la nube de la plataforma de distribución.
- **D-12 — Plataforma de distribución.** itch.io, Steam u otra.
- **D-13 — Reto al empezar cada parte.** El personaje conserva sus mejoras, pero la parte siguiente arranca con enemigos de escalón 1. *Recomendación de la especificación:* estadísticas base de los enemigos más altas en cada parte.
- **D-14 — Parálisis y duración de las crisis.** Las crisis duran 4–6 s, pero la parálisis es "un instante muy breve". ¿Qué pasa el resto de la crisis?
  *Resuelta:* congelaciones intermitentes durante toda la crisis (unos 0,4 s cada 1–1,5 s), avisadas con un temblor. Sigue disparando. Tiempos por datos.
- **D-15 — Renderizador.** El proyecto usa Compatibility, elegido para capturar sin GPU. ¿Se mantiene o se pasa a Forward+?
  *Resuelta:* Forward+. El cambio se hace en la fase 1, revisando el aspecto de los modelos. Compatibility queda como reserva por línea de comandos, y la prueba de carga mide los dos.
- **D-16 — Pausas y menús personales.** ¿Se pausa la partida al elegir mejora, abrir la ficha o el mapa, en solitario y en cooperativo? ¿Qué pasa con el personaje de quien tiene el menú abierto?
  *Resuelta:* en solitario, todo menú pausa. En cooperativo solo pausan Start y la subida de nivel, en la que todos eligen a la vez. Ficha y mapa se abren y cierran sin pausa y con el personaje controlable (sección 3.2).
- **D-17 — Paranoia.** La especificación dice "sin fuego amigo", pero la paranoia hace que las armas apunten a los compañeros con daño reducido.
  *Resuelta:* los disparos del paranoico restan cordura, no vida, con daño muy reducido (dato). Es la única excepción a "sin fuego amigo". *A vigilar en las pruebas de la fase 2:* el riesgo de crisis en cadena entre jugadores.
- **D-18 — Personajes en la fase 2.** El cooperativo llega en la fase 2, pero la selección de personaje llega en la fase 5 y la fase 1 solo modela a Dyer. ¿Con qué juegan los jugadores 2 a 4?
  *Resuelta:* en la fase 2 hay dos personajes, William Dyer y Robert Olmstead (revólver, esquive más largo y "sangre de Innsmouth"), distinguidos además por el color de cada jugador. Cómo se asigna cada uno y cómo se marcan las criaturas marinas para su pasivo se concretará en el plan de la fase 2. El resto de personajes y la selección completa, en la fase 5.
- **D-19 — Pasivos sin mecánica.** El pasivo de Dyer (frío y ralentización) y el de Johansen (inmunidad al empuje) dependen de efectos sobre el jugador que no están definidos, y el de Legrasse necesita saber si los híbridos de Innsmouth cuentan como "enemigos humanos".

---

## 13. Incoherencias y huecos detectados

Detectados al redactar este documento. Se avisan en lugar de resolverlos (regla 6 de la especificación).

1. **Crisis y parálisis:** duración de 4–6 s frente a "un instante muy breve" → D-14, resuelta.
2. **Fuego amigo:** "sin fuego amigo" frente a la paranoia → D-17, resuelta.
3. **Personajes del cooperativo:** fase 2 con cuatro jugadores antes de tener más personajes y su selección → D-18, resuelta.
4. **Pasivos de Dyer, Johansen y Legrasse** → D-19, pendiente (fase 4).
5. **Tiaras y joyas:** `CLAUDE.md` dice que los Profundos no llevan "tiaras ni joyas", y la especificación incluye sacerdotes de la tiara y joyas de la Orden de Dagon. No es una contradicción real si la regla de `CLAUDE.md` se limita a las criaturas, porque los sacerdotes son humanos (sección 7). Conviene aclararlo en `CLAUDE.md`. *Pendiente de confirmar.*
6. **Vial de reactivo de West:** es un "objeto raro", pero no hay sistema de objetos o botín aparte de la experiencia. Hay que definir cómo se obtiene antes de implementarlo. No bloquea las fases 1 y 2.
7. **Modelos de los demás personajes:** la fase 5 trae la selección de personaje, pero ninguna fase asigna el modelado de Legrasse, Johansen, Armitage y West. No bloquea las fases 1 y 2.
