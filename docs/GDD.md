# Documento de diseño (GDD)

**Título:** *Lovecraft Library: Surviving Cthulhu* (D-01, decidido el 25-09-2026).
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

El relato apenas describe criaturas aparte de Cthulhu. *Decidido (08-10-2026):* los Ángulos devoradores (la geometría imposible que engulle a un marinero) son un **peligro del escenario**: zonas que se abren en el suelo con aviso, atraen hacia su centro y engullen (mucho daño y cordura) a quien se queda dentro, y se cierran solas; no se matan. **Cthulhu** se combate como Dagon: colosal, solo la parte visible, asomando por la puerta de R'lyeh, anclado y con fases; al "morir" se deshace en una nube verde y se recompone una vez, más furioso, como en el relato.

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

  - Esquive de cada personaje (26-09-2026): Dyer, deslizamiento; Olmstead, voltereta con el impulso un 30 % más largo (su "esquive más largo"); Legrasse, salto; Johansen, plancha. El destello queda para un personaje arcano (Armitage). En partida, F1 recorre los cinco.
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
- **Lenguaje visual implementado** (hito 1.4, rehecho el 26-09-2026): las balas enemigas son cúmulos de cubos en voxel 3D, iluminados como el resto del mundo y con un brillo propio suave. Van en colores **apagados** (con muchas balas, los tonos vivos marean; puede haber excepciones más adelante), y son más pequeñas en las criaturas de nivel bajo. Si el decorado tapa una bala, se ve su silueta. Los avisos en el suelo usan el color del tipo de daño.
  - *Físico* (resta vida): bola maciza de cubos en **rojos, naranjas y amarillos**, con el núcleo más claro.
  - *Mental* (resta cordura): anillo de cubos **morados, púrpuras, lilas y violetas** que gira y ondula alrededor de un núcleo violeta oscuro.
  - *Mixto:* el núcleo físico dentro del anillo mental.
  - *Jugador:* trazadoras doradas alargadas y translúcidas, que no se confunden con las enemigas.
- **Pocos enemigos a distancia:** la horda es sobre todo de cuerpo a cuerpo, y los que disparan son pocos. Cada enemigo tiene un peso de aparición propio (`spawn_weight`) que multiplica al de su escalón: en el nivel 1, tres pingüinos por cada fragmento.
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

### 5.3 Arsenal II (29-09-2026, completa D-29)
Las 17 armas que faltaban de las 29 de D-29, propuestas para equilibrar los tres grupos (quedan 12 de fuego, 11 físicas y 11 mágicas) y con una mecánica nueva cada una. Se hacen en dos hitos: 2.7 (las mágicas) y 2.7b (las de fuego y las físicas).

**Mágicas (cuestan cordura)**
| Arma | Qué hace | Mecánica |
|---|---|---|
| Signo Arcano | Signo en el suelo, bajo el personaje, que daña y empuja hacia fuera; las balas enemigas que lo cruzan van a la mitad de velocidad | Zona que repele y frena balas (1 de las 2 que tocan balas) |
| Resonador de Tillinghast (*Del más allá*) | Pulso periódico que deshace las balas enemigas cercanas y hace poco daño | Borra balas (la 2.ª de las 2) |
| Báculo del Farolero | Fuegos fatuos que zigzaguean y buscan solos a los enemigos | Proyectiles teledirigidos |
| Lente del Éter | Rayo sostenido cuyo daño crece mientras sigue sobre el mismo enemigo, hasta el triple | Daño que va en aumento |
| Polvo de Ibn-Ghazi (*El horror de Dunwich*) | Nube que se queda donde cae: dentro, los enemigos van un 40 % más lentos y hacen un 30 % menos de daño | Ralentiza y debilita |
| Orbe Mi-Go (*El que susurra en la oscuridad*) | Orbe que vuela solo alrededor del personaje y dispara al enemigo más cercano | Aliado volador |
| Rayo de Yith (*La sombra fuera del tiempo*) | Congela al enemigo en el tiempo 1,5 s; el daño que recibe se guarda y se aplica al final, un 50 % mayor | Estasis con daño aplazado |
| Daga ritual | Apuñala al más cercano y lo maldice (daño continuo); si muere maldito, la maldición salta a los de al lado | Maldición que se contagia |

**De fuego**
| Arma | Qué hace | Mecánica |
|---|---|---|
| Bobina Tesla portátil | Rayo que salta de enemigo en enemigo, hasta 4 (tecnología humana: crece con CON+INT) | Encadena objetivos |
| Springfield M1903 con mira | Disparo lento y fuerte a la élite o al de más vida, con crítico triple | Prioriza élites y crítico |
| Ametralladora Lewis en trípode | La deja en el suelo y dispara sola 8 s | Torreta fija |
| Lugers P08 a dos manos | Disparan a la vez hacia donde anda el personaje y hacia atrás | Apunta con el movimiento |

**Físicas**
| Arma | Qué hace | Mecánica |
|---|---|---|
| Inyector de Herbert West (*Herbert West, reanimador*) | Dardo de suero: el que muere inyectado se levanta 6 s como aliado (sustituye al Reactivo de 5.2) | Reanima aliados |
| Bumerán | Va hasta su alcance y vuelve, golpeando a la ida y a la vuelta | Ida y vuelta |
| Red de pesca | Deja inmóvil 2 s al grupo donde cae (las élites solo se frenan) | Inmoviliza en área |
| Martillo de geólogo | Golpe al suelo que abre una grieta en línea recta hacia delante | Grieta que avanza |
| Bastón estoque | Estocada larga hacia delante que atraviesa todo lo que hay en la línea | Cuerpo a cuerpo frontal |


### 5.4 Arsenal III (propuesta del 09-10-2026, D-38)
Dieciséis armas más, hasta 50 (16 físicas, 17 de fuego y 17 mágicas). Cada una con una mecánica que aún no hay y repartidas por papel: distancia, área, cuerpo a cuerpo, control y cordura.

**De fuego**
| Arma | Qué hace | Papel / mecánica |
|---|---|---|
| Recortada | Dos disparos seguidos en cono corto y ancho con mucho empuje | Quemarropa |
| Antitanque Mauser | Disparo muy lento que atraviesa a todos los de la línea, de borde a borde | Distancia, perforación total |
| Mortero Stokes | Proyectil en arco alto al grupo más lejano; explosión grande | Área a distancia |
| BAR M1918 | Ráfagas cuyas balas rebotan hacia otro enemigo cercano | Rebote |
| Nagant de Danforth | Cadencia que se acelera mientras tiene a quién disparar (hasta ×2,5) y se enfría al parar | Cadencia creciente |

**Físicas**
| Arma | Qué hace | Papel / mecánica |
|---|---|---|
| Ancla del *Alert* | Ancla con cadena que gira alrededor a mucha distancia, lenta y pesada | Órbita amplia, empuje |
| Gas de cloro | Nube verde que deriva con el viento y envenena | Área que se mueve |
| Látigo | Latigazo largo en arco por delante, golpea a todos los del arco | Cuerpo a cuerpo largo |
| Cepos | Deja cepos en el suelo; el que los pisa queda atrapado y herido | Minas |
| Ballesta | Virotes que atraviesan y clavan al suelo un instante | Distancia, inmoviliza |

**Mágicas (cuestan cordura)**
| Arma | Qué hace | Papel / mecánica |
|---|---|---|
| Llama de Cthugha | Bolas de fuego vivo que dejan un rastro ardiendo | Proyectil con rastro |
| Aliento de Ithaqua | Viento helado en cono: frena y, si sigue, congela | Control en cono |
| Esfera de Yog-Sothoth | Orbe lento que atrae a los enemigos a su centro y los tritura | Agujero negro |
| Tentáculos de Shub | Tentáculos que brotan del suelo bajo enemigos al azar | Área aleatoria |
| Signo Amarillo | Los enemigos que lo miran enloquecen y atacan a los suyos unos segundos | Enemigos contra enemigos |
| Lámpara de Alhazred | Haz de luz que barre en círculo alrededor del personaje | Rayo giratorio |

### 5.5 Objetos (propuesta del 09-10-2026, D-38)
De 5 a 50 objetos de subida de nivel. Nombres cortos, de una a tres palabras. Siguen los 4 huecos (5 y 6 con la tienda) y cinco niveles por objeto (salvo los que tienen tope). Son modificadores generales del jugador que afectan a todas sus armas. Los 5 de siempre no cambian: Abrigo de reno (vida), Diario de campo (cordura), Brújula de Lake (recogida), Botas de nieve (velocidad) y Reflejos (recarga del esquive).

**Ataque (15)**
| Objeto | Por nivel |
|---|---|
| Bandolera | +1 proyectil a las armas de balas y lanzados (tope 3) |
| Catalejo | +10 % de alcance |
| Pólvora de Ponape | +12 % de velocidad de los proyectiles |
| Mapa de Leng | +10 % de área (explosiones, zonas, ondas, tajos) |
| Reloj de Tillinghast | −6 % de recarga de todas las armas |
| Clepsidra de Yith | +15 % de duración (zonas, órbitas, rayos, torretas) |
| Piedra de afilar | +1 enemigo atravesado por las balas (tope 3) |
| Ojo de Pickman | +5 % de probabilidad de crítico (×1,5) |
| Collar de colmillos | +15 % de daño de los críticos |
| Petaca de ron | +8 % de daño |
| Manual de tiro | +12 % de daño de las armas de fuego |
| Guantes de estibador | +12 % de daño físico y +10 % de empuje |
| Manuscritos pnakóticos | +12 % de daño de las armas mágicas |
| Medallón del cazador | +20 % de daño a élites y jefes |
| Plomada | +25 % de empuje |

**Protección y recuperación (11)**
| Objeto | Por nivel |
|---|---|
| Coraza de foca | −2 al daño físico de cada golpe |
| Signo Primigenio | −10 % de daño mental (también auras) |
| Botiquín | Regenera 0,3 de vida por segundo |
| Pipa de espuma | Regenera 0,4 de cordura por segundo |
| Colmillo de *ghoul* | Cada abatido cura 0,5 de vida |
| Salterio | Cada abatido devuelve 0,3 de cordura |
| Escapulario | +25 % de invulnerabilidad tras recibir un golpe |
| Escamas de Profundo | Devuelve el 30 % del daño de contacto al que golpea |
| Escudo de Nodens | Cada 25 s (−3 por nivel) absorbe un golpe entero (se ve una burbuja) |
| *Ankh* de Nephren | Una vez por nivel, al caer se levanta con el 30 % de vida (tope 1) |
| Láudano | Crisis de locura un 20 % más cortas |

**Esquive y movimiento (6)**
| Objeto | Por nivel |
|---|---|
| Crampones | +15 % de distancia del esquive |
| Esquís de Pabodie | +1 esquive seguido (tope 2) |
| Gafas de aviador | +0,08 s de invulnerabilidad al esquivar |
| Capa del Hombre Negro | Al esquivar deja un señuelo que atrae a los enemigos 1,5 s (+0,5 s) |
| Petardos | Al esquivar, explosión donde empezó |
| Elixir de Curwen | Tras esquivar, +15 % de daño durante 2 s |

**Utilidad (8)**
| Objeto | Por nivel |
|---|---|
| Lupa | +10 % de experiencia |
| Dado de hueso | +15 % de suerte |
| Oro de Obed | +15 % de dólares |
| Llave de plata | Una vez por nivel, cambiar las opciones de la subida (tope 3) |
| Vara de zahorí | Baúles arcanos un 15 % más a menudo |
| *Pemmican* | La comida y las pociones curan un 30 % más |
| Silbato de Lake | +20 % de daño y velocidad del compañero |
| Talismán esotérico | −12 % de cordura de las armas mágicas |

**Disparadores y riesgo (5)**
| Objeto | Por nivel |
|---|---|
| Tablilla de Eltdown | 8 % de que el abatido estalle y dañe alrededor |
| Cristal de Ithaqua | 6 % de que el impacto frene al enemigo 1,5 s |
| Fósforos de Cthugha | 6 % de que el impacto lo prenda (quemadura 3 s) |
| Diente de *shoggoth* | Con menos del 30 % de vida, +20 % de daño |
| Ídolo de Cthulhu | +12 % de enemigos y +12 % de experiencia y dólares (riesgo) |

---

## 6. Personajes jugables

Todos proceden de relatos de Lovecraft y cada parte tiene al menos un personaje nativo. Armitage y West vienen de relatos que no forman parte del juego (licencia aceptada). Cada uno tiene arma inicial, un único rasgo pasivo (D-35) y un perfil de estadísticas: vida, cordura, velocidad, recarga del esquive y suerte en las mejoras. Los valores exactos, por datos.

| Personaje | Relato | Arma inicial | Rasgo pasivo | Perfil |
|---|---|---|---|---|
| William Dyer, geólogo | *En las montañas de la locura* (parte 1) | Cartuchos de dinamita (en la fase 1, además, el revólver) | Explosiones un 25 % más grandes (D-35) | Mucha cordura |
| Robert Olmstead, narrador de Innsmouth | *La sombra sobre Innsmouth* (parte 2) | Revólver .38 | Esquive un 30 % más largo (D-35) | Equilibrado |
| Inspector John R. Legrasse | *La llamada de Cthulhu* (parte 3) | Escopeta de dos cañones | Más daño contra cultistas y enemigos humanos (D-19) | Equilibrado |
| Gustaf Johansen, marinero | *La llamada de Cthulhu* (parte 3) | Machete | Un 25 % más de daño cuerpo a cuerpo (D-35) | Mucha vida |
| Profesor Henry Armitage | *El horror de Dunwich* | Polvo de Ibn-Ghazi | Las armas arcanas recargan antes | Cordura alta, vida baja |
| Herbert West | *Herbert West, reanimador* | Reactivo de West | Reanima a compañeros más rápido; curación en área al subir de nivel | Poca cordura, gran resistencia física |
| Amelia Peaslee, arqueóloga joven y aventurera, sobrina del profesor Peaslee | *La sombra fuera del tiempo* | Rifle de caza | Más suerte en las mejoras (D-35) | Rápida, vida media |
| Madame Ludmila Varga, espiritista experta en artes oscuras | Médium de Arkham (propia) | Páginas del Necronomicón | Las armas arcanas le cuestan la mitad de cordura | Mucha cordura, poca vida |
| Padre Iwanicki, sacerdote católico | *Los sueños en la casa de la bruja* | Fórmula de expulsión | Aura que calma: él y los compañeros cercanos recuperan cordura (D-35) | Equilibrado |
| Dra. Marian Whipple, doctora, sobrina del Dr. Elihu Whipple | *La casa maldita* | Bisturís (arma nueva: abanico que atraviesa) | Reanima a los compañeros un 50 % más rápido (D-35) | Vida y cordura medias |
| Henrietta Blake, escritora, hermana de Robert Blake | *El morador de las tinieblas* | Trapezoedro Resplandeciente | Más experiencia por gema | Cordura alta, vida baja |
| Sargento Frank Elwood, ex-soldado de la Gran Guerra | Pariente de Elwood, *Los sueños en la casa de la bruja* | Pistola automática Colt .45 | Recibe un 15 % menos de daño físico (D-35) | Mucha vida |
| Vera Malone, delincuente de la mafia | *El horror de Red Hook* | Subfusil Thompson | Más daño cuanto más cerca está el enemigo | Rápida, vida media |

---

### 6.1 Atributos de cada personaje (D-27)

Todos empiezan con los siete atributos a 10 y reparten 20 puntos entre tres. La base de vida, cordura y velocidad es la misma para todos (100, 100 y 4,5 m/s); los atributos la escalan: con 20 puntos en la pareja de una estadística, vale la base, y cada punto por encima suma un 2,5 % (la velocidad, un 1,25 %).

| Personaje | Reparto | De inicio |
|---|---|---|
| William Dyer | CUL +8 · POD +7 · CON +5 | Sí |
| Robert Olmstead | DES +8 · CON +6 · INT +6 | Sí |
| Amelia Peaslee | DES +8 · CUL +7 · INT +5 | Sí |
| Dra. Marian Whipple | CUL +9 · INT +7 · CON +4 | Sí |
| John R. Legrasse | INT +7 · CON +7 · TEN +6 | Tienda |
| Gustaf Johansen | FUE +8 · CON +8 · TEN +4 | Tienda |
| Madame Ludmila Varga | POD +12 · INT +4 · CUL +4 | Tienda |
| Henrietta Blake | INT +8 · POD +7 · CUL +5 | Tienda |
| Padre Iwanicki | POD +10 · CUL +6 · TEN +4 | Tienda |
| Sargento Frank Elwood | CON +8 · TEN +7 · FUE +5 | Tienda |
| Vera Malone | DES +9 · TEN +6 · FUE +5 | Tienda |

Cada arma declara su tipo (`WeaponData.category`): **física** (cuerpo a cuerpo y lanzadas con el brazo: machete, bisturís, dinamita, granadas, molotov, arpón), **de fuego** (pistolas, fusiles, escopetas, lanzallamas y bengalas) o **mágica** (arcanas y tecnología de los Mitos).

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
### 7.1 Pantalla de título (D-21)

Ilustración de la biblioteca (tuya, en `resources/PantallasMenus/`) con animaciones sutiles hechas en Godot:
- **Ambiente:** velas y faroles que parpadean, cada uno a su ritmo, y su luz en paredes y suelo mojado; niebla que deriva sobre el suelo.
- **Ventanal:** nubes pasando por detrás de la tracería y de la silueta de Cthulhu, halo de la luna que respira, relámpago tenue y espaciado, y los ojos de Cthulhu encendiéndose despacio.
- **Detalles:** motas de polvo en la luz de las velas y un acercamiento lento del 3 % durante la presentación.
- **Secuencia:** fundido desde negro; unos segundos de biblioteca viva; entrada del título (primero su halo fino de niebla y después las letras); aviso de pulsar. Se puede saltar.
- Cada efecto se ajusta o se quita por separado (`data/title/portada.tres`).
- **Accesibilidad:** sin destellos estroboscópicos; el relámpago es tenue y regulable.

- **Regla de contenido** (modelos, textos y diálogos): nada racista, sexista ni homófobo. Los cultistas son de géneros y edades variados, sin rasgos étnicos marcados que asocien un grupo real al mal; los identifica su culto. Los relatos originales contienen estereotipos de su época que no se reproducen.

---

## 8. Guardado y progresión permanente

- **Local:** archivo en `user://` con versión de formato. Guarda la configuración (controles, audio, vídeo), las estadísticas históricas y la partida en curso al terminar cada nivel, para poder salir y retomarla desde el nivel siguiente.
- **Nube (fase 10, D-11):** el formato local debe ser serializable y versionado desde el principio, para poder subirlo más adelante sin cambios.

### 8.1 Estructura de menús y progresión permanente (D-09, D-20)

Tomada de Extremadura Survivors (`github.com/sergiosanchezcustodio/extremadura-survivors`), con el estilo de este juego. Se adopta la estructura de menús y de progreso, **no** sus sistemas de partida (corazones, cofres con ruleta): aquí siguen la caída, la reanimación y el vial de West.

- **Arranque:** ficha del proyecto (con qué está hecho, licencia y aviso del uso de IA), intro que presenta el juego y portada animada (sección 7.1), que muestra "Pulsa Start" y acepta cualquier botón principal (D-22). Después, la ventana de huecos de partida. Los relatos se saltan manteniendo pulsado.
- **Menú principal:** quieto a propósito. El fondo se mueve poco, porque lo importante es qué opción está señalada.
- **Selección de personaje:** tarjetas al estilo de Extremadura Survivors, con los modelos voxel. Los bloqueados se ven en penumbra con su precio. Los jugadores se unen aquí pulsando Start y eligen a la vez; un personaje elegido no puede repetirse (D-23). Debajo de cada tarjeta, su compañero.
- **Compañeros** (D-20): se elige uno antes de empezar, acompaña toda la partida y sube de nivel contigo. Unos dan una estadística y otros actúan. Sacados de los relatos: quince en total (D-36).
- **Mapa de niveles:** las 3 partes × 5 niveles a la vista, con los bloqueados apagados; cada nivel se abre al ganar el anterior. Al elegir uno se cuenta su relato antes de jugarlo.
- **Tienda:** la moneda sobrevive a la muerte (propuesta: fondos de la Fundación Pickman, que financia la expedición del relato; por decidir). Tres secciones:
  - Potenciadores permanentes de valores pequeños, cinco niveles cada uno.
  - Compañeros.
  - Personajes.
- **Guardado:** tres huecos de partida, configuración y ficha del jugador.

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
| D-01 | Título del juego | Publicación (fase 8) | **Resuelta**: *Lovecraft Library: Surviving Cthulhu* |
| D-02 | Objetivo y duración de cada nivel | Fase 1 | **Resuelta** |
| D-03 | Tamaño y forma de los escenarios | Fases 1 y 2 | **Resuelta** |
| D-04 | Escalones 4 y 5 y seres únicos | Fases 4 y 6 | **Resuelta** |
| D-05 | Apuntado | Fase 1 | **Resuelta** |
| D-06 | Evoluciones de armas | Fase 3 (modelo de datos de armas) | **Resuelta** |
| D-07 | Experiencia en cooperativo | Fase 2 | **Resuelta** |
| D-08 | Cordura | — | Resuelta: se incluye. Valores numéricos por ajustar en pruebas |
| D-09 | Desbloqueos y acceso al modo *Por partes* | Fase 5 | **Resuelta** (progresión permanente con tienda) |
| D-10 | Modelo online | Fase 9 | Pendiente |
| D-11 | Guardado en la nube | Fase 10 | Pendiente |
| D-12 | Plataforma de distribución | Fase 8; condiciona D-10 y D-11 | **Resuelta**: itch.io primero |
| D-13 | Reto al empezar cada parte en la campaña | Fase 6 | **Resuelta** |
| D-14 | Parálisis frente a la duración de las crisis | Fase 1 | **Resuelta** |
| D-15 | Renderizador | Fase 1 | **Resuelta** |
| D-16 | Pausas y menús personales | Fases 1 y 2 | **Resuelta** |
| D-17 | Paranoia frente a "sin fuego amigo" | Fase 2 | **Resuelta** |
| D-18 | Personajes disponibles en la fase 2 | Fase 2 | **Resuelta** |
| D-19 | Pasivos que dependen de mecánicas sin definir | Fase 4 | **Resuelta** |
| D-20 | Compañeros (equivalente a las mascotas de Extremadura Survivors) | Fase 5 | **Resuelta**: sí, sacados de los relatos |
| D-21 | Portada | Fase 5 | **Resuelta**: escena animada en Godot |
| D-22 | Flujo de menús y guardado adelantados a la fase 2 | Fase 2 | **Resuelta** |
| D-23 | Personajes únicos y cuatro jugables en la fase 2 | Fase 2 | **Resuelta** |
| D-24 | Botón de juego online antes de la fase 9 | Fase 2 | **Resuelta**: visible y desactivado |
| D-25 | Mapa de niveles con un solo nivel | Fase 2 | **Resuelta**: el mapa completo, con el nivel 1 abierto |
| D-26 | Siete personajes más en la fase 2 | Fase 2 | **Resuelta** |
| D-27 | Atributos de los personajes | Fase 2 | **Resuelta** |
| D-28 | Armas y objetos por personaje | Fase 2 | **Resuelta** |
| D-29 | Arsenal ampliado (29 armas nuevas) | Fase 2 | **Resuelta** |
| D-30 | Personajes de inicio y desbloqueos | Fase 2 | **Resuelta** |
| D-31 | Dinero, tienda de antigüedades y baúles arcanos | Fase 2 | **Resuelta** |
| D-32 | Logros y desbloqueos | Fase 2 | **Resuelta** |
| D-33 | Clima estético | Fase 2 | **Resuelta** |
| D-34 | Vestuario | Fase 2 | **Resuelta** |
| D-35 | Un rasgo por personaje | Fase 2 | **Resuelta** |
| D-36 | Quince compañeros | Fase 2 | **Resuelta** |
| D-37 | Reglas de daño de las armas | Fase 2 | **Resuelta** |

D-01 a D-13 proceden de la especificación. D-14 a D-19 salen de las incoherencias y huecos detectados al redactar este documento (sección 13). Las decisiones bloqueantes de las fases 1 y 2 se resolvieron el 24-09-2026.

- **D-01 — Título del juego.** *Resuelta:* **Lovecraft Library: Surviving Cthulhu**. En la portada, "Lovecraft Library:" en letra pequeña, centrado, y justo debajo, mucho más grande y rodeado de tentáculos, "Surviving Cthulhu". Letras voxel 3D integradas en la escena.
- **D-02 — Objetivo de cada nivel.** ¿Sobrevivir un tiempo, eliminar un número de enemigos o llegar a un punto del mapa? ¿Cuánto dura un nivel?
  *Resuelta:* supervivencia por oleadas de 8–10 minutos. Solo el último nivel de cada parte (el 5) termina con jefe; los niveles 1 a 4 terminan con un evento final sin jefe. El tipo de objetivo es un dato del nivel. En la fase 1, versión de 5 minutos con el Acechador como élite en el evento final.
- **D-03 — Tamaño y forma de los escenarios.** El botón de mapa implica escenarios mayores que la pantalla. ¿Arena abierta o recorrido?
  *Resuelta:* arena finita de unas 3×3 pantallas, cerrada por el decorado, con fuentes de luz y obstáculos. Tamaño por datos.
- **D-04 — Escalones 4 y 5.** Incluyen seres únicos (Barnabas Marsh, Madre Hydra, Pth'thya-l'yi) que no pueden aparecer en número. *Recomendación de la especificación:* élites con tope de 1–2 simultáneos; los seres únicos, como minijefes con una única aparición en su nivel. *Resuelta (03-10-2026):* se adopta la recomendación. `LevelData.elite_cap` (1-2) limita las élites de escalón 4 y 5; los seres únicos son minijefes con `EnemyData.unique`: aparecen una sola vez en su nivel, con aviso, y no entran en las oleadas.
- **D-05 — Apuntado.** Automático al más cercano, en dirección de movimiento o elegible.
  *Resuelta:* lo decide cada arma en sus datos, con "al más cercano" por defecto. Sin opción de jugador de momento.
- **D-06 — Evoluciones de armas.** ¿Combinaciones de arma y pasiva al estilo "survivors"?
- **D-07 — Experiencia en cooperativo.** ¿Individual o compartida?
  *Resuelta:* compartida. Todos suben de nivel a la vez y cada uno elige su mejora. Curva escalada por número de jugadores.
- **D-08 — Cordura.** Resuelta: se incluye. Quedan por ajustar los valores numéricos.
- **D-09 — Desbloqueos.** ¿Hay desbloqueos permanentes (personajes, armas)? ¿El modo *Por partes* exige haber llegado antes a esa parte en la campaña?
  *Resuelta (25-09-2026):* progresión permanente con tienda, como en Extremadura Survivors (sección 8.1). La subida de nivel dentro de la partida sigue empezando de cero en cada partida. Queda por concretar si *Por partes* exige haber llegado a esa parte.
- **D-10 — Modelo online.** Anfitrión y clientes con ENet, red de Steam o WebRTC; cómo se conectan los jugadores; si se mezclan jugadores locales y remotos; cámara propia por jugador remoto.
- **D-11 — Guardado en la nube.** Gist privado del jugador mediante el flujo de autorización por dispositivo de GitHub, servidor propio o guardado en la nube de la plataforma de distribución.
- **D-12 — Plataforma de distribución.** itch.io, Steam u otra. *Resuelta (08-10-2026):* **itch.io primero** (versión temprana, subida con butler); Steam se puede añadir más adelante. Efectos de sonido de bancos libres CC0, citados en la ficha del proyecto.
- **D-13 — Reto al empezar cada parte.** El personaje conserva sus mejoras, pero la parte siguiente arranca con enemigos de escalón 1. *Recomendación de la especificación:* estadísticas base de los enemigos más altas en cada parte.
  *Resuelta (06-10-2026):* cada parte es más difícil que la anterior aunque los personajes vuelvan a empezar desde el nivel 1, porque entre partes se mejoran de forma permanente con la tienda (potenciadores, personajes, compañeros y huecos). Las estadísticas base de los enemigos suben por parte (`LevelData.health_mult` desde 1,2 en el primer nivel de la parte 2, más daño y ritmo de aparición). El equilibrio se mide con bots en dos casos: sin compras y con las compras esperables tras la parte anterior. Objetivo del autor: que no sea fácil, pero nunca exasperante. Jefes colosales (06-10-2026): modelo propio a 16 voxels/m (`voxel_size` en el JSON) y solo la parte que asoma del agua. La regla de "sin tiaras ni joyas" solo afecta a los Profundos: los sacerdotes humanos de la Orden llevan su tiara.
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
- **D-20 — Compañeros.** *Resuelta:* sí, sacados de los relatos (sección 8.1).
- **D-21 — Portada.** *Resuelta:* escena 3D animada en Godot (sección 7.1). De ella sale también la imagen fija para las tiendas. Necesita el título del juego (D-01), que pasa a ser necesario para la fase 5.
- **D-22 — Flujo de menús (26-09-2026).** *Resuelta:* se adelantan a la fase 2 el guardado, el menú principal, la configuración, la selección de personaje, el mapa de niveles, la tienda y los compañeros. El flujo es:
  1. Portada con "Pulsa Start". Vale cualquier botón principal del mando (A, B, X, Y, Start, Select) o del teclado; sustituye a lo que decía la sección 8.1 ("un botón concreto, no cualquiera").
  2. Ventana de huecos de partida: tres huecos locales, cada uno con tiempo total jugado, objetos comprados, compañeros desbloqueados y dinero actual, y un botón de borrar con confirmación. Al borrar, el hueco queda como nuevo.
  3. Menú principal: Jugar, Tienda, Configuración (vídeo, audio, controles y juego) y Salir.
  4. Jugar abre una ventana con "Jugar en local" y "Jugar online".
  5. Selección de personaje, al estilo de Extremadura Survivors: los demás jugadores se unen pulsando Start en su mando y todos eligen a la vez. Debajo de cada tarjeta, el compañero, entre los desbloqueados en la tienda.
  6. Mapa de niveles y partida.
- **D-23 — Personajes únicos (26-09-2026).** *Resuelta:* un personaje elegido por un jugador no puede elegirlo otro en esa partida. Para que puedan jugar cuatro, la fase 2 trae cuatro personajes: Dyer, Olmstead, Legrasse y Johansen, con sus armas iniciales (revólver, escopeta y machete). Amplía D-18.
- **D-24 — Online antes de tiempo.** *Resuelta:* "Jugar online" aparece atenuado con "Próximamente" hasta la fase 9 (D-10).
- **D-25 — Mapa de niveles.** *Resuelta:* se hace ya el mapa de las 3 partes × 5 niveles, con solo el nivel 1 abierto.
- **D-26 — Siete personajes más (27-09-2026).** *Resuelta:* además de Dyer, Olmstead, Legrasse y Johansen, la fase 2 trae siete personajes que se compran en la tienda (mientras no exista, se pueden elegir para probarlos). Cada uno se ata a un relato de Lovecraft: es personaje suyo o pariente o allegado inventado de uno. Se hacen en dos tandas (hito 2.4b), con revisión tras cada una:
  - *Primera tanda:* Amelia Peaslee (arqueóloga, rifle de caza), Madame Ludmila Varga (espiritista, páginas del Necronomicón), Dra. Marian Whipple (doctora, bisturís) y Henrietta Blake (escritora, Trapezoedro Resplandeciente).
  - *Segunda tanda:* padre Iwanicki (sacerdote, fórmula de expulsión), sargento Frank Elwood (ex-soldado, Colt .45) y Vera Malone (delincuente de la mafia, subfusil Thompson).
- **D-27 — Atributos (27-09-2026).** *Resuelta:* siete atributos, todos a 10 en el nivel 1: **POD** (poder: voluntad, resistencia mental, afinidad mágica), **INT** (inteligencia), **FUE** (fuerza), **CON** (constitución), **TEN** (tenacidad: negarse a caer, que se traduce en golpes letales), **DES** (destreza) y **CUL** (cultura: estudios, lecturas, viajes y saber de leyendas; antes EDU, educación). Cada personaje reparte además **20 puntos entre tres atributos** según su historia (reparto en la sección 6). Las estadísticas salen de la suma de dos atributos: vida = CON+TEN; cordura = POD+INT; esquive = DES+CON; velocidad = DES+TEN; ataques físicos = FUE+TEN; ataques mágicos = POD+CUL; armas de fuego = CON+INT. Al subir de nivel, además de elegir 1 de 3 mejoras de armas u objetos, el personaje gana **+1 en un atributo**, elegido al azar con una probabilidad proporcional a sus atributos del nivel 1 (con INT 20 y DES 10, el doble de probabilidad para INT). Esa proporción no cambia nunca. Se descartó un octavo atributo.
- **D-28 — Armas y objetos por personaje (27-09-2026).** *Resuelta:* cada personaje **empieza con un solo arma**. Puede llevar **4 armas y 4 objetos** (los objetos son las mejoras pasivas); un artículo de la tienda amplía cada uno a **5**.
- **D-29 — Arsenal ampliado (27-09-2026).** *Resuelta:* 29 armas nuevas propuestas por el autor. Donde se solapaban con las existentes:
  - El **Subfusil Thompson M1928** sustituye al Thompson actual.
  - Las nuevas **sustituyen** a sus equivalentes: escopeta de corredera → escopeta de dos cañones; rifle de palanca → rifle de caza; Mauser C96 → Colt .45; Webly Mk VI → revólver .38; Stielhandgranate → cartuchos de dinamita. Los personajes que empezaban con ellas cambian de arma inicial.
  - Arcane Sign, Báculo del Farolero, Resonador y Lente del Éter se mantienen **diferenciadas** del Necronomicón, la Fórmula de expulsión y el Trapezoedro.
  - El **Inyector de Suero de Herbert West** es el arma de Herbert West y sustituye al "Reactivo de West" de la sección 5.2.
  - Correcciones por coherencia con el juego (sección 5.3): nada puede "distraer" balas; no hay armadura; y solo dos armas interactúan con las balas enemigas, para no romper el pilar "esquivar es la habilidad".
- **D-30 — Personajes de inicio y desbloqueos (27-09-2026).** *Resuelta:* se empieza con **2 hombres y 2 mujeres**: Dyer, Olmstead, Peaslee y Whipple. El resto se compra en la tienda o se desbloquea en las fases jugando. La tienda muestra a **todos**, también los de inicio (ya desbloqueados). Sustituye a D-23 y D-26 en lo que toca a quién está disponible desde el principio.
- **D-31 — Dinero y tienda (27-09-2026).** *Resuelta:* la moneda son **dólares** (sustituye a la "Fundación Pickman" de la sección 8.1) y se consiguen matando enemigos. Precios calibrados para que comprar toda la tienda lleve **unas 10 horas de juego**. La tienda es una **tienda de antigüedades atendida por un anciano**. En los niveles aparecen **baúles arcanos** como tesoro. Algunos compañeros se compran y otros se desbloquean haciendo algo especial en una fase.
- **D-32 — Logros (27-09-2026).** *Resuelta:* el menú principal tiene una sección nueva de **logros y desbloqueos**.
- **D-33 — Clima (27-09-2026).** *Resuelta:* inclemencias del tiempo **solo estéticas**, sin efecto en personajes ni enemigos: nieve o ceniza, lluvia, niebla, viento, nubes y rayos de fondo, según el nivel.
- **D-34 — Vestuario (27-09-2026).** *Resuelta:* prendas solo estéticas en la tienda. Cabeza: casco de la Primera Guerra Mundial, gorro de nieve, cinta del pelo, bufanda, sombrero de aventurero, boina, sombrero de copa, sombrero vaquero, bombín, casco de minero, sombrero de mujer, turbante, sombrero de paja, gafas de ver y gafas de nieve. Cuerpo: chaqueta de aviador, abrigo de piel, abrigo de nieve, chubasquero, chaleco, vestido y bata. Pies: botas militares, botas de nieve, botas esquimales y zapatos de tacón. *Ampliado el 03-10-2026:* las gafas y la bufanda van en un cuarto hueco, Accesorio, compatible con cualquier sombrero; las prendas se compran una vez para todos los personajes y se eligen en la selección.
- **D-35 — Un rasgo por personaje (29-09-2026).** *Resuelta:* cada personaje tiene un único rasgo, acorde con su oficio. Dyer, explosiones un 25 % más grandes; Olmstead, esquive más largo; Peaslee, suerte; Whipple, reanima más rápido; Elwood, 15 % menos de daño físico; Johansen, 25 % más de daño cuerpo a cuerpo; Iwanicki, aura de cordura que también le afecta a él. Los demás no cambian. Se quitan la resistencia marina de Olmstead, la recogida de Peaslee, la curación de Whipple, la recarga de Elwood y la inmunidad al empuje de Johansen.
- **D-36 — Quince compañeros (30-09-2026).** *Resuelta:* se añaden trece compañeros y el gato de Ulthar cambia (negro, araña a los enemigos cercanos y se enfada al recibir su jugador un golpe; pierde la protección mental). Rata de las Paredes (más baúles y dólares de los muertos), sapo de Innsmouth (escupe baba venenosa: charco), Mini-Byakhee (picado desde el aire), araña de Tíndalos (se teletransporta detrás de un enemigo y lo aturde), serpiente de Yig (veneno), pez de Innsmouth (embiste y empuja), Mini-Dhole (sale bajo un grupo), cuervo de Arkham (trae gemas y dólares lejanos), shoggoth bebé (se come balas enemigas), Mini-Mi-Go (rayos), búho de los sueños (más experiencia), cabra de los bosques (embestida que aturde), polilla de Leng (polvo que confunde) y gaviota de Innsmouth (trae pescado: cura vida y cordura, y chilla ante los élites). Todos en la tienda (hito 2.15).
- **D-06 — Evoluciones de armas (03-10-2026).** *Resuelta:* al estilo de Vampire Survivors, un arma al nivel máximo más un objeto concreto en el inventario evoluciona al abrir el siguiente baúl arcano. Las evoluciones no salen al subir de nivel ni siguen las reglas de daño (D-37): rinden alrededor de 1,4 veces su nivel 5. Primera tanda, las armas de los personajes de inicio: Stielhandgranate + Reflejos de alpinista → Carga concentrada; Webly + Brújula de Lake → Revólver del vigía; rifle de palanca + Diario de campo → Rifle de la expedición Miskatonic; bisturís + Abrigo de piel de reno → Instrumental de cirujano. Las demás, en fases posteriores.
- **D-37 — Reglas de daño de las armas (03-10-2026).** *Resuelta:* cada arma parte de un mismo daño por segundo a un solo objetivo (nivel 1, si todo acierta; 14, la mediana del arsenal) multiplicado por sus rasgos: corto alcance ×1,3 y largo ×0,85; un objetivo ×1,15 y área ×0,8; un proyectil ×1,15 y varios ×0,85; cadencia baja ×1,2 y alta ×0,85; cuesta cordura ×1,2 (vida o esquive ×1,3); teledirigida ×0,8 y al azar ×1,15; control (aturde, inmoviliza, atrae, congela, frena, debilita, hace vulnerable o levanta aliados) ×0,6. Las de puro apoyo (bengalas, red, resonador, polvo) quedan fuera. `DamageRules` lo calcula, `tools/reglas_dano.gd` lo aplica y un test admite ±15 %.
- **D-38 — Arsenal III y 50 objetos (09-10-2026).** *Aprobada:* 16 armas nuevas (5.4) y 45 objetos nuevos (5.5), hasta 50 y 50. Los objetos pasan de cambiar una estadística a ser modificadores generales que leen todas las armas, con disparadores (al abatir, al impactar, al esquivar). Iconos con Replicate en el estilo de los actuales.
- **D-19 — Pasivos sin mecánica.** El pasivo de Dyer (frío y ralentización) y el de Johansen (inmunidad al empuje) dependen de efectos sobre el jugador que no están definidos, y el de Legrasse necesita saber si los híbridos de Innsmouth cuentan como "enemigos humanos". *Resuelta (03-10-2026):* D-35 quitó los de Dyer y Johansen. Para Legrasse llevan la etiqueta `humana` los cultistas, los habitantes de Innsmouth, los acólitos de la Orden de Dagon y los híbridos que aún andan entre los hombres (hasta los híbridos avanzados); los Profundos completos y las criaturas, no.

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
