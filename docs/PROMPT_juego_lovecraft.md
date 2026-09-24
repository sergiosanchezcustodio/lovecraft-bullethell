# Prompt de desarrollo — Bullet hell isométrico en los Mitos de Lovecraft

> Instrucciones para Claude Code. Léelas completas antes de escribir código. Este documento es la especificación de partida; `CLAUDE.md` contiene el pipeline de arte ya probado y las lecciones técnicas. Si algo de aquí contradice a `CLAUDE.md`, pregúntame antes de actuar.

---

## 0. Tu papel y forma de trabajar

Actúas como desarrollador principal del proyecto. Trabajarás **por hitos**, nunca construyendo todo de golpe.

Reglas de trabajo:

1. **Antes de programar un hito**, presenta un plan breve (archivos que crearás o modificarás, riesgos) y espera mi aprobación.
2. **Decisiones pendientes** (sección 13, identificadas como `D-xx`): cuando un hito dependa de una, pregúntame. No inventes la respuesta. Puedes proponer una recomendación.
3. **Verificación visual**: todo cambio que afecte a lo que se ve debe comprobarse renderizando capturas con Godot desde la terminal (como documenta `CLAUDE.md`) y revisándolas tú mismo antes de darme el hito por terminado.
4. **Al cerrar cada hito**: tests en verde, capturas revisadas, `CLAUDE.md` actualizado con el estado del proyecto y commit con mensaje descriptivo en español.
5. **Datos antes que código**: enemigos, armas, personajes, niveles y oleadas se definen como datos (recursos `.tres` o JSON), no incrustados en la lógica.
6. Si detectas una incoherencia en esta especificación, avísame en lugar de resolverla por tu cuenta.

---

## 1. Visión del juego

- **Título**: provisional, pendiente (`D-01`).
- **Género**: bullet hell con disparo automático. Híbrido entre bullet hell (los enemigos llenan la pantalla de proyectiles con patrones que hay que esquivar) y el género "survivors" (hordas, disparo automático, subida de nivel dentro de la partida).
- **Fantasía del jugador**: un grupo de investigadores de los relatos de Lovecraft que atraviesa los escenarios de tres historias, enfrentándose a horrores cada vez más antiguos, hasta despertar a Cthulhu.
- **Tono**: horror cósmico, oscuro y opresivo. Luz escasa, niebla, colores fríos con acentos cálidos (farolillos, fuego) y enfermizos (verdes, cian bioluminiscente).
- **Pilares de diseño**:
  1. *Esquivar es la habilidad*: el disparo es automático; la pericia del jugador está en el movimiento y en el esquive.
  2. *Escalada del horror*: cada nivel añade un escalón de criaturas más poderosas sin retirar las anteriores.
  3. *Cooperativo primero*: todo sistema se diseña pensando en 1–4 jugadores.
  4. *Legibilidad*: con decenas de enemigos y cientos de balas, el jugador siempre debe distinguir su personaje, las balas peligrosas (y si dañan la vida o la cordura) y a sus compañeros.
  5. *Inspiración en los relatos*: escenarios, criaturas y personajes salen de los textos de Lovecraft, pero **la jugabilidad prima sobre la fidelidad**: se aceptan licencias (por ejemplo, criaturas que aparecen en un escenario distinto al del relato) cuando mejoran el juego.

---

## 2. Decisiones técnicas cerradas

| Aspecto | Decisión |
|---|---|
| Motor | Godot 4.4, GDScript con tipado estático |
| Gráficos | Voxel 3D detallado ("Minecraft mejorado"), 32 voxels por metro de juego como punto de partida (ajustable por rendimiento, ver sección 11) |
| Pipeline de arte | Generadores Python → JSON → `voxel_builder.gd` (ver `CLAUDE.md`) |
| Animación | Por partes con pivote (torso, cabeza, brazos, piernas…) rotadas por código, sin rigging |
| Cámara | Ortográfica isométrica fija (rotación X −30°, Y 45°) |
| Enemigo de referencia | Acechador (variante de Profundo): modelo, animaciones de acecho y salto |
| Jugadores | 1–4 en cooperativo local. El online se implementa al final (fase 9) |
| Controles | Teclado o mando; en local, el teclado solo lo puede usar un jugador |
| Progresión | Subida de nivel dentro de la partida; cada partida nueva empieza de cero |
| Guardado | Local. El guardado en la nube con cuenta de GitHub se implementa al final (fase 10) |

---

## 3. Controles

### Mando
| Botón | Acción |
|---|---|
| Stick izquierdo | Movimiento |
| A | Esquivar (impulso corto con invulnerabilidad breve) |
| Start | Menú de opciones dentro de la partida |
| Select | Ficha del jugador (estadísticas, armas, mejoras) |
| Cruceta abajo | Mapa del nivel |
| Disparo | Automático (sin botón) |

### Teclado (propuesta)
| Tecla | Acción |
|---|---|
| WASD o flechas | Movimiento |
| Espacio | Esquivar |
| Esc | Menú de opciones |
| Tab | Ficha del jugador |
| M | Mapa |
| Enter / Esc | Confirmar / volver en menús |

Requisitos:
- Todas las acciones deben ser reasignables desde el menú de opciones.
- Asignación de dispositivos al entrar en la partida: pantalla de "pulsa un botón para unirte", cada dispositivo reclama un hueco de jugador (1–4). El teclado solo puede reclamar un hueco.
- Conexión y desconexión de mandos en caliente: si un mando se desconecta, su personaje queda en pausa protegido hasta que se reconecte o el jugador abandone.
- En local, **Start pausa la partida para todos**.
- **Select y el mapa** en cooperativo se muestran en el cuadrante del jugador que los abre, sin bloquear la pantalla de los demás.

---

## 4. HUD

- Siempre visible, un panel por jugador en su esquina: **J1 arriba-izquierda, J2 arriba-derecha, J3 abajo-izquierda, J4 abajo-derecha**.
- Contenido de cada panel: retrato del personaje, **barra de vida y barra de cordura** (colores claramente distintos), barra de experiencia y nivel, armas equipadas con su nivel, indicador de recarga del esquive y color identificativo del jugador (que también se usa en un anillo bajo su personaje).
- Los huecos sin jugador no muestran panel.
- Información global en el borde superior central: parte y nivel actuales, progreso u objetivo del nivel y tiempo.
- Los paneles deben ser compactos y semitransparentes para no tapar balas; el área de juego se ajusta para que ningún jugador quede detrás de un panel.

---

## 5. Estructura del juego

- **3 partes × 5 niveles = 15 niveles.** Cada parte está ambientada en un relato de Lovecraft, y cada nivel es un escenario distinto de ese relato.
- **Criaturas basadas en los relatos**: cada enemigo aparece en su relato, se menciona en él o es una variante directa de algo que aparece. Leyenda de las tablas: **(C)** aparece en el relato · **(M)** se menciona en él · **(V)** variante directa de algo que aparece.
- **Escalada acumulativa**: en el nivel N aparecen enemigos de dificultad 1 a N. Cada nivel introduce las dos criaturas nuevas de su escalón.
- **Proporción**: los enemigos de menor dificultad aparecen en mayor número. Propuesta de pesos de aparición configurable por datos: para un enemigo de escalón *t* en el nivel *N*, peso ∝ 2^(N − t). Los escalones 4 y 5 se tratan como élites con un tope de enemigos simultáneos (ver `D-04`).
- **Orden de aparición**: el escalón de cada criatura lo decide la jugabilidad, no el momento en que aparece en el relato. Que una criatura salga en un escenario distinto al suyo es una licencia aceptada.
- **Sin fechas exactas**: el juego no muestra años. Las partes siguen el orden fijado aunque los relatos originales ocurran en otro orden cronológico; la ambientación general es la de los años 20 y 30.
- **Jefes en escalada**: shoggoth primigenio < Padre Dagon < Cthulhu. Los jefes de las partes 1 y 2 nunca son entidades superiores a Cthulhu en la jerarquía de los Mitos.

### Parte 1 — *En las montañas de la locura* (Antártida)
La expedición de la Universidad de Miskatonic descubre, tras una cordillera imposible, la ciudad muerta de los Antiguos y lo que aún vive bajo ella. Es la parte de la naturaleza hostil y los horrores prehumanos: **no hay enemigos humanos**. Todas sus criaturas son Antiguos, shoggoths o pingüinos del abismo y sus variantes; los Engendros de Cthulhu quedan reservados para la parte 3.

| Nivel | Escenario | Criaturas nuevas |
|---|---|---|
| 1 | Campamento base en la costa del mar de Ross | Pingüinos albinos ciegos gigantes (C) · Fragmentos protoplásmicos de shoggoth (V) |
| 2 | El campamento destruido de Lake | Antiguos revividos, los especímenes que despertaron (C) · Antiguos alados (V) |
| 3 | El paso de la cordillera y sus cavernas | Shoggoths esclavos (C) · Shoggoths miméticos, que imitan la forma y la voz de sus amos (C) |
| 4 | La ciudad ciclópea de los Antiguos | Antiguos guerreros (V) · Antiguos mutilados, cubiertos del limo de los shoggoths que los atacaron (V) |
| 5 | Los túneles y el abismo del mar subterráneo | Shoggoths de ojos luminosos, con ojos que se forman y deshacen en su masa (C) · Antiguos del mar abisal, los que se retiraron a las aguas subterráneas (V) |
| **Jefe** | | **El shoggoth primigenio de los túneles**, que persigue a los supervivientes gritando "¡Tekeli-li!" (C) |

### Parte 2 — *La sombra sobre Innsmouth* (Nueva Inglaterra)
El narrador llega a un puerto decadente de Nueva Inglaterra cuyos habitantes se están convirtiendo en algo que pertenece al mar. Enlaza con la parte 3: los Profundos adoran a Cthulhu.

| Nivel | Escenario | Criaturas nuevas |
|---|---|---|
| 1 | Newburyport y la carretera a Innsmouth | Habitantes con "el aspecto de Innsmouth" (C) · Acólitos de la Orden Esotérica de Dagon (C) |
| 2 | Las calles de Innsmouth y el templo de la Orden | Híbridos avanzados a punto de volver al mar (C) · Sacerdotes de la tiara (C) |
| 3 | El hotel Gilman House y la huida por los tejados | Profundos, incluido el **Acechador** (C) · La horda del Arrecife del Diablo (C) |
| 4 | Los pantanos y la vía muerta del tren a Rowley | Barnabas Marsh transformado (M) · Profundos ancianos de Y'ha-nthlei (C) |
| 5 | El Arrecife del Diablo y la ciudad sumergida de Y'ha-nthlei | Pth'thya-l'yi, la antepasada milenaria del narrador (M) · Madre Hydra (M) |
| **Jefe** | | **Padre Dagon** (M) |

Las variantes de Profundo ya prototipadas en `tools/gen_variantes.py` (Clásico, Bruto, Abisal) sirven como base: el Clásico para los híbridos y Profundos comunes, el Bruto como base de Dagon y el Abisal para los Profundos ancianos de Y'ha-nthlei.

### Parte 3 — *La llamada de Cthulhu* (Providence, Luisiana y el Pacífico)
El rastro del culto a Cthulhu lleva de Providence a los pantanos de Luisiana y al Pacífico, donde R'lyeh emerge de las aguas.

| Nivel | Escenario | Criaturas nuevas |
|---|---|---|
| 1 | Providence: el estudio del escultor Wilcox | Pesadillas de la oleada de sueños (V) · Cultistas (C) |
| 2 | Los pantanos de Luisiana: el ritual del culto | Diablos con alas de murciélago de la leyenda del pantano (C) · Cultistas armados del *Alert* (C) |
| 3 | Los muelles y la cubierta del *Alert* | Engendros de Cthulhu (M) · Profundos servidores de Cthulhu (vínculo con la parte 2) |
| 4 | La tormenta en el Pacífico | La cosa blanca polipoide del lago oculto (C) · Ángulos devoradores de R'lyeh (C) |
| 5 | R'lyeh emergida: la puerta colosal | Primigenios menores que yacen con Cthulhu (M) · Emanaciones de la puerta: masas gelatinosas verdes que brotan de la puerta negra al abrirse, anticipo de Cthulhu (V) |
| **Jefe** | | **Cthulhu** (C) |

Nota: el relato apenas describe criaturas aparte de Cthulhu. Los "Ángulos devoradores" (la geometría imposible que engulle a un marinero) pueden funcionar como enemigo o como peligro del escenario; decídelo conmigo al diseñar ese nivel.

---

## 6. Dirección de arte de criaturas y cultos

- **Criaturas**: clásicas y oscuras, sin ropa ni adornos externos. Solo anatomía: escamas, púas, aletas, agallas, garras, tentáculos.
- **Híbridos de Innsmouth**: cuentan como humanos en cuanto a vestuario. Llevan ropa de pueblo pesquero de los años 20, más deteriorada, rota y empapada cuanto más avanzada está su transformación; lo inquietante es la mezcla de ropa normal y rasgos de pez.
- **Cultistas y humanos**: pueden llevar túnicas, adornos y símbolos, **siempre ligados a la criatura que adora su culto**, de modo que cada culto se reconozca por su silueta y su paleta.

| Culto | Motivos | Paleta |
|---|---|---|
| Orden Esotérica de Dagon (parte 2) | Joyas de oro extraño con relieves de peces, criaturas batracias y olas. Acólitos con túnicas sencillas y amuletos; sacerdotes con vestiduras ceremoniales y la tiara alta de oro | Oro deslustrado, verde marino, algas, coral |
| Culto de Cthulhu (parte 3) | La figura del ídolo (cabeza de pulpo con tentáculos, cuerpo escamoso, alas rudimentarias) en piedra verdinegra, jeroglíficos desconocidos, la invocación "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn". Cultistas del pantano con túnicas oscuras, amuletos del ídolo, máscaras con tentáculos y antorchas; tripulación del *Alert* con ropa de marinero y símbolos del culto | Negro verdoso, hueso, resplandor de hogueras |

- **Personajes jugables**: proporciones humanas, ropa de época, paleta más cálida que la de los enemigos y siempre con el anillo de color del jugador.
- **Regla de contenido** (aplica a modelos, textos y diálogos): nada racista, sexista ni homófobo. Los cultistas son de géneros y edades variados, sin rasgos étnicos marcados que asocien un grupo real al mal; los identifica su culto. Los relatos originales contienen pasajes con estereotipos de su época que no deben reproducirse.

---

## 7. Mecánicas

### Núcleo
- **Disparo automático**: cada arma dispara sola según su cadencia y patrón. Apuntado automático al enemigo más cercano por defecto; opcionalmente, en la dirección de movimiento (`D-05`).
- **Esquive**: impulso corto en la dirección de movimiento con fotogramas de invulnerabilidad y tiempo de recarga. Es la herramienta principal para atravesar cortinas de balas.
- **Enemigos**: cada tipo tiene dos elementos de diseño separados: movimiento (perseguir, acechar y saltar, orbitar, cargar, emerger del suelo o del agua, volar, imitar…) y patrones de disparo (ráfagas radiales, espirales, abanicos dirigidos, balas que persiguen, zonas de peligro en el suelo, rayos con aviso previo). Los patrones deben ser datos reutilizables entre enemigos.
- **Telegrafía**: todo ataque fuerte se anuncia con un aviso visual (marca en el suelo, brillo, animación de carga) proporcional a su daño.

### Progresión dentro de la partida
- Los enemigos sueltan experiencia. Al subir de nivel, cada jugador elige **1 de 3 mejoras** al azar: arma nueva, subir de nivel un arma o mejora pasiva.
- Cada arma tiene niveles del 1 al 5 (propuesta; `D-06` para evoluciones o combinaciones).
- La progresión se conserva entre niveles de la misma partida y **se pierde al empezar una partida nueva**.

### Cooperativo
- Sin fuego amigo.
- **Reanimación**: un jugador caído queda derribado un tiempo; un compañero puede reanimarlo quedándose junto a él. Si nadie lo hace, queda eliminado hasta el siguiente nivel.
- La dificultad escala con el número de jugadores (vida de enemigos y densidad de aparición). Los valores exactos, por datos.
- Experiencia: individual o compartida (`D-07`).

### Vida y cordura
Cada personaje tiene dos recursos: **vida** y **cordura**, con valores base distintos según el personaje (sección 9).

**Tipos de daño.** Cada ataque enemigo se define por datos con un tipo:
- **Físico**: resta vida (garras, mordiscos, proyectiles materiales). Ejemplos: Profundos, pingüinos del abismo.
- **Mental**: resta cordura (cánticos, susurros, visiones). Ejemplos: sacerdotes de la tiara, pesadillas de Providence.
- **Mixto**: resta ambas. Ejemplos: el grito "¡Tekeli-li!" del shoggoth, Cthulhu.
Pauta general: los escalones bajos hacen sobre todo daño físico; cuanto más alto el escalón, más daño mental. Los jefes combinan ambos.

**Legibilidad obligatoria.** Los proyectiles y ataques mentales deben distinguirse de los físicos al instante, por forma, color y sonido (por ejemplo, violeta y ondulante con un susurro frente a proyectiles sólidos). Los mixtos combinan ambos lenguajes. El jugador debe poder decidir en décimas de segundo qué esquivar primero según el estado de sus barras.

**Pérdida de cordura**, además de los ataques mentales:
- **Presencia**: élites y jefes emiten un aura que drena cordura mientras el jugador está dentro de su radio.
- **Armas arcanas**: cada uso cuesta cordura (riesgo-recompensa frente a las armas convencionales, que no cuestan nada).

**Recuperación de cordura**: lenta y pasiva lejos de los horrores; más rápida cerca de fuentes de luz del escenario (hogueras, farolas, lámparas) y **cerca de compañeros**, lo que premia jugar agrupados en cooperativo.

**Efectos progresivos** con la cordura baja: susurros, bordes de pantalla que palpitan, desaturación, sombras fugaces. Son solo ambientación: **nunca ocultan ni falsean las balas reales** (nada de balas o enemigos falsos que puedan confundirse con los reales).

**Crisis de locura (cordura a cero).** Estado temporal de 4–6 segundos; al terminar, el personaje recupera una parte de la cordura (por ejemplo, el 30%). El tipo de crisis se elige al azar con pesos por datos (cada personaje puede tener pesos propios):
1. **Parálisis catatónica**: no se mueve durante un instante muy breve; sigue disparando.
2. **Huida histérica**: corre sin control en dirección contraria al horror más cercano.
3. **Vagar sin rumbo**: movimiento errático y lento; los controles solo obedecen parcialmente.
4. **Paranoia**: sus armas apuntan a los compañeros, con daño muy reducido. Solo en cooperativo; en solitario se sustituye por otra crisis.
5. **Delirio**: controles invertidos durante la crisis.

**Calmar a un compañero**: permanecer junto a un jugador en crisis la acorta progresivamente, con la misma interacción que la reanimación.

**Locura acumulada** (configurable, activada por defecto y a validar en pruebas): cada crisis reduce la cordura máxima un porcentaje hasta el final del nivel.

### Muerte y recuperación
- Con la vida a cero, el personaje queda **derribado** (ver reanimación en "Cooperativo"). Si nadie lo reanima a tiempo, queda eliminado hasta el siguiente nivel.
- **Vial de reactivo de West**: objeto raro de un solo uso que resucita automáticamente al portador. Es la segunda oportunidad en solitario.
- El pasivo de Herbert West acelera las reanimaciones (sección 9).
- Si todos los jugadores están eliminados, el nivel se pierde y se reintenta desde el último guardado.

### Accesibilidad
- Deslizador en opciones para la intensidad de las distorsiones de pantalla (hasta desactivarlas), por mareos y fotosensibilidad.
- Prohibidos los destellos estroboscópicos.

---

## 8. Armas

Todas disparan solas. Cada personaje empieza con una y consigue las demás al subir de nivel.

### Armas convencionales (años 20)
| Arma | Patrón |
|---|---|
| Revólver .38 | Disparo único al enemigo más cercano, cadencia media. Arma de referencia |
| Pistola automática Colt .45 | Ráfagas cortas, más daño y menos alcance |
| Escopeta de dos cañones | Abanico corto de perdigones, retroceso que empuja a los enemigos |
| Subfusil Thompson | Chorro continuo que barre en arco |
| Rifle de caza | Disparo lento que atraviesa varios enemigos en línea |
| Cartuchos de dinamita | Lanzamiento en arco a zonas densas; explosión de área con retardo |
| Machete | Tajo circular alrededor del personaje, para cuando las hordas se acercan |
| Linterna de arco | Cono de luz que daña a las criaturas de la oscuridad |

### Artefactos y saber arcano (de los relatos de Lovecraft)
Más potentes que las convencionales, pero **cada uso cuesta cordura**.

| Arma | Patrón | Origen |
|---|---|---|
| Polvo de Ibn-Ghazi | Nube que debilita a los enemigos y los vuelve vulnerables | *El horror de Dunwich* |
| Signo Arcano | Símbolo que se deja en el suelo; crea una zona que repele o daña a los enemigos | Los Mitos |
| Fórmula de expulsión | Onda expansiva periódica que empuja y aturde | *El horror de Dunwich* |
| Páginas del Necronomicón | Proyectiles orbitales de energía alrededor del personaje | Los Mitos |
| Trapezoedro Resplandeciente | Rayo de luz concentrada a través de la gema | *El morador de las tinieblas* |
| Reactivo de Herbert West | Frasco que al romperse reanima brevemente a enemigos caídos como aliados | *Herbert West, reanimador* |

---

## 9. Personajes jugables

Todos proceden de relatos de Lovecraft. Cada parte tiene al menos un personaje nativo; Armitage y West vienen de relatos que no forman parte del juego, licencia aceptada. Cada uno tiene un arma inicial, un rasgo pasivo y un perfil de estadísticas (vida, cordura, velocidad, recarga del esquive, suerte en las mejoras); los valores exactos se ajustarán por datos. Orientación de perfiles: Dyer, mucha cordura; Johansen, mucha vida; West, poca cordura pero gran resistencia física; Armitage, cordura alta y vida baja; Olmstead y Legrasse, equilibrados.

| Personaje | Relato | Arma inicial | Rasgo pasivo |
|---|---|---|---|
| William Dyer, geólogo | *En las montañas de la locura* (parte 1) | Cartuchos de dinamita | Resistencia al frío y a los efectos de ralentización |
| Robert Olmstead, el narrador de Innsmouth | *La sombra sobre Innsmouth* (parte 2) | Revólver .38 | Esquive más largo; "sangre de Innsmouth": resistencia al daño de criaturas marinas |
| Inspector John R. Legrasse | *La llamada de Cthulhu* (parte 3) | Escopeta de dos cañones | Más daño contra cultistas y enemigos humanos |
| Gustaf Johansen, marinero | *La llamada de Cthulhu* (parte 3) | Machete | Más vida; inmunidad al empuje |
| Profesor Henry Armitage | *El horror de Dunwich* | Polvo de Ibn-Ghazi | Las armas arcanas recargan antes |
| Herbert West | *Herbert West, reanimador* | Reactivo de West | Reanima a compañeros más rápido; curación en área al subir de nivel |

---

## 10. Guardado

- **Local**: archivo en `user://` con versión de formato. Guarda la configuración (controles, audio, vídeo), estadísticas históricas y **la partida en curso al terminar cada nivel**, de modo que se pueda salir y retomarla desde el nivel siguiente.
- **Modos de partida**: *Campaña* (las 3 partes seguidas, 15 niveles) y *Por partes* (una sola parte de 5 niveles). En ambos, la progresión del personaje empieza de cero al iniciar la partida.
- **Nube con GitHub**: se implementa al final (fase 10). Solo como previsión: el formato del guardado local debe ser serializable y versionado para poder subirlo más adelante sin cambios.

---

## 11. Requisitos técnicos y de rendimiento

- **Objetivo**: 60 FPS estables en un PC de gama media con 4 jugadores, en torno a 150 enemigos y 1.000 balas en pantalla (cifras orientativas, a validar en la fase 1).
- **Optimización progresiva**, de menos a más invasiva, aplicando cada paso solo si la medición lo exige:
  1. Fusión de caras contiguas del mismo color ("greedy meshing") en `voxel_builder.gd`: reduce vértices sin cambiar el aspecto.
  2. `MultiMeshInstance3D` por parte del cuerpo para las criaturas numerosas, con transformaciones por instancia para la animación.
  3. Reducción de la resolución voxel de enemigos y personajes (los generadores tienen la escala como parámetro). Consúltame antes de aplicarla.
  4. Niveles de detalle (LOD) para modelos grandes.
- **Balas**: sin nodos individuales por bala; gestión en arrays con dibujado por `MultiMesh` y colisiones mediante rejilla espacial propia o `PhysicsServer` directo.
- **Jefes colosales**: el formato JSON debe admitir una escala voxel propia por modelo, o representar solo la parte visible del jefe (Cthulhu emergiendo, Dagon desde el agua). Consúltame el enfoque antes de modelarlos.
- **Cámara en cooperativo local**: pantalla compartida. La cámara encuadra a todos los jugadores ajustando el zoom ortográfico entre un mínimo y un máximo; al llegar al máximo, los jugadores no pueden alejarse más entre sí.
- **Capa de entrada**: los personajes nunca leen `Input` directamente; reciben acciones de una capa de abstracción por jugador. Es imprescindible para el cooperativo local y deja preparado el online.
- **Escenarios**: también generados con el pipeline voxel (piezas de suelo, muros y decorado combinables), con iluminación que respete la atmósfera definida en `CLAUDE.md`.
- **Estructura sugerida**: `scenes/`, `scripts/` (por sistema: `player/`, `enemies/`, `weapons/`, `bullets/`, `ui/`, `save/`), `data/` (recursos de enemigos, armas, personajes, niveles y oleadas), `models/`, `tools/`, `tests/`, `docs/`.
- **Tests**: framework GUT para la lógica (daño, experiencia, pesos de aparición, guardado y carga). Capturas automáticas para lo visual.

---

## 12. Fases de desarrollo

Cada fase termina con criterios de aceptación verificables. No avances a la siguiente sin mi aprobación.

**Fase 0 — Documentación y decisiones**
Crea `docs/GDD.md` a partir de este documento y `docs/ROADMAP.md` con las fases. Repasa conmigo las decisiones pendientes que bloquean las fases 1 y 2.
*Aceptación*: documentos en el repositorio y decisiones bloqueantes respondidas.

**Fase 1 — Prototipo jugable ("vertical slice")**
Un jugador (William Dyer) con teclado o mando, movimiento, esquive y su arma inicial más el revólver. Escenario provisional inspirado en el nivel 1 de la parte 1. Pingüinos albinos ciegos y fragmentos protoplásmicos (modelos nuevos), más el Acechador como enemigo élite de prueba, cada uno con al menos un patrón de ataque. Experiencia, subida de nivel con elección entre 3 mejoras. **Vida y cordura** con los tres tipos de daño y su diferenciación visual, y una sola crisis de locura (parálisis). HUD del J1 con ambas barras. Muerte y reinicio.
*Aceptación*: una partida de 5 minutos jugable de principio a fin; prueba de carga con 150 enemigos y 1.000 balas medida y documentada.

**Fase 2 — Cooperativo local**
De 1 a 4 jugadores, asignación de dispositivos, HUD en las cuatro esquinas, cámara compartida, reanimación, pausa local, ficha y mapa por cuadrante. Sistema de cordura completo: las cinco crisis, calmar a un compañero, recuperación cerca de compañeros y luces, auras de presencia y locura acumulada.
*Aceptación*: 4 mandos (o 3 mandos y teclado) jugando simultáneamente sin conflictos de entrada.

**Fase 3 — Pipeline de contenido**
Sistema de datos para enemigos, armas, oleadas y niveles. Generador de escenarios voxel. Patrones de balas reutilizables. Comando para previsualizar cualquier enemigo con sus animaciones.
*Aceptación*: añadir un enemigo nuevo solo requiere su generador y su archivo de datos, sin tocar el código de los sistemas.

**Fase 4 — Parte 1 completa** (*En las montañas de la locura*)
Cinco niveles, sus diez criaturas y el shoggoth primigenio.
*Aceptación*: la parte 1 se puede completar en cooperativo.

**Fase 5 — Guardado local y menús**
Menú principal, selección de personaje, opciones, guardado y carga.

**Fase 6 — Parte 2 completa** (*La sombra sobre Innsmouth*), con Padre Dagon.

**Fase 7 — Parte 3 completa** (*La llamada de Cthulhu*), con Cthulhu.

**Fase 8 — Pulido**
Audio, equilibrado, accesibilidad, rendimiento final y distribución.

**Fase 9 — Online**
Según `D-10`.

**Fase 10 — Guardado en la nube con GitHub**
Según `D-11`.

---

## 13. Decisiones pendientes

Pregúntame cada una cuando un hito dependa de ella. Entre paréntesis, tu recomendación de partida.

- **D-01 — Título del juego.**
- **D-02 — Objetivo de cada nivel.** ¿Sobrevivir un tiempo, eliminar un número de enemigos o llegar a un punto del mapa? ¿Cuánto dura un nivel? (Recomendación: supervivencia por oleadas de 8–10 minutos con un evento final.)
- **D-03 — Tamaño y forma de los escenarios.** El botón de mapa implica escenarios mayores que la pantalla. ¿Arena abierta o recorrido?
- **D-04 — Escalones 4 y 5.** Incluyen seres únicos (Barnabas Marsh, Madre Hydra, Pth'thya-l'yi) que no pueden aparecer en número. (Recomendación: élites con tope de 1–2 simultáneos; los seres únicos, como minijefes con una única aparición en su nivel.)
- **D-05 — Apuntado.** Automático al más cercano, en dirección de movimiento o elegible.
- **D-06 — Evoluciones de armas.** ¿Combinaciones de arma más pasiva al estilo "survivors"?
- **D-07 — Experiencia en cooperativo.** ¿Individual o compartida?
- **D-08 — Cordura.** Resuelta: se incluye (sección 7). Quedan por ajustar con pruebas los valores numéricos.
- **D-09 — Desbloqueos.** ¿Hay desbloqueos permanentes (personajes, armas)? ¿El modo *Por partes* exige haber llegado antes a esa parte en la campaña?
- **D-13 — Reto al empezar cada parte en la campaña.** El personaje conserva sus mejoras, pero la parte siguiente arranca con enemigos de dificultad 1. (Recomendación: estadísticas base de los enemigos más altas en cada parte, de modo que la dificultad 1 de la parte 2 sea más fuerte que la de la parte 1.)
- **D-10 — Modelo online** (fase 9). Anfitrión y clientes con ENet, red de Steam o WebRTC; cómo se conectan los jugadores; si se mezclan jugadores locales y remotos; cámara propia por jugador remoto.
- **D-11 — Guardado en la nube** (fase 10). Gist privado del jugador mediante el flujo de autorización por dispositivo de GitHub, servidor propio o guardado en la nube de la plataforma de distribución.
- **D-12 — Plataforma de distribución.** itch.io, Steam u otra. Condiciona D-10 y D-11.

---

## 14. Nota sobre derechos

Los relatos de H. P. Lovecraft y sus creaciones son de dominio público en España y la UE, y todas las criaturas, escenarios y personajes de este documento proceden de ellos. Aun así: no uses la marca "Call of Cthulhu" (Chaosium), no reproduzcas reglas, textos ni ilustraciones del juego de rol ni de adaptaciones modernas, y si más adelante se añade contenido de otros autores de los Mitos, consúltamelo antes. Esto no es asesoramiento legal; antes de una publicación comercial conviene revisarlo.
