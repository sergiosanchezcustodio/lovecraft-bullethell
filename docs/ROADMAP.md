# Hoja de ruta

Fases del proyecto, criterios de aceptación y estado. El diseño está en [`GDD.md`](GDD.md); las decisiones `D-xx` se detallan en su sección 12.

## Cómo se trabaja cada hito

1. **Plan antes de programar:** archivos que se crearán o modificarán y riesgos. No se empieza sin aprobación.
2. **Decisiones:** si el hito depende de una `D-xx` abierta, se pregunta antes, con una recomendación.
3. **Verificación visual:** todo cambio visible se comprueba renderizando capturas desde la terminal y revisándolas antes de dar el hito por terminado.
4. **Cierre:** tests en verde, capturas revisadas, `CLAUDE.md` actualizado (apartado "Estado actual") y commit con mensaje descriptivo en español.
5. **Datos antes que código:** enemigos, armas, personajes, niveles y oleadas se definen como datos.
6. **Sin avanzar de fase** hasta tener la aprobación.

## Resumen

| Fase | Nombre | Estado | Decisiones que la bloquean |
|---|---|---|---|
| 0 | Documentación y decisiones | **Hecha** (24-09-2026) | — |
| 1 | Prototipo jugable (*vertical slice*) | **Hecha** (26-09-2026; queda tu partida de 5 minutos como comprobación) | Ninguna (D-02, D-03, D-05, D-14, D-15 y D-16, resueltas) |
| 2 | Menús, guardado y cooperativo local | **Hecha** salvo tu prueba con varios mandos (2.17) | Ninguna (D-07, D-16 a D-18 y D-22 a D-25, resueltas) |
| 3 | Pipeline de contenido | **Hecha** (20-10-2026): enemigos, armas, evoluciones (D-06), niveles, patrones, animaciones y escenarios por datos | Ninguna |
| 4 | Parte 1 completa | **Hecha** salvo tu partida (04-10-2026) | Ninguna (D-04 y D-19, resueltas) |
| 5 | Arranque, relatos y ampliación de la tienda | **Hecha** salvo tu revisión (08-10-2026) | Ninguna |
| 6 | Parte 2 completa | **Hecha** salvo tu partida (08-10-2026) | Ninguna (D-13 y jefes colosales, resueltas) |
| 7 | Parte 3 completa | **Hecha** salvo tu partida (08-10-2026) | Ninguna (Ángulos devoradores y Cthulhu, resueltos) |
| 8 | Pulido y distribución | **En curso:** hitos 8.1 a 8.3 y 8.6 a 8.16 hechos, pendientes de tu revisión; 8.4 espera tus partidas y 8.5, tu cuenta de itch.io | Ninguna (D-01 y D-12, resueltas) |
| 9 | Online | **Plan aprobado** (21-10-2026) | Ninguna (D-10, resuelta) |
| 10 | Guardado en la nube con GitHub | **Hecha** (26-10-2026) salvo el `client_id` de tu OAuth App y tu prueba con dos PC | Ninguna (D-11, resuelta) |
| 11 | Calidad gráfica, animación y efectos | **Hecha** (28-10-2026) salvo tu revisión | Ninguna |
| 12 | Detalles de personajes, enemigos, compañeros y escenarios | **Hecha** (29-10-2026) salvo tu revisión | Ninguna (D-41, resuelta) |
| 13 | Calibración, modos de juego, narrativa, sonido, herramientas y distribución | **En curso:** plan aprobado (29-10-2026); 13.1 a 13.13 hechos | Las de cada hito (al final de la fase) |

---

## Fase 0: Documentación y decisiones

Crear `docs/GDD.md` y `docs/ROADMAP.md` a partir de la especificación, enlazarlos desde `CLAUDE.md` y resolver las decisiones que bloquean las fases 1 y 2.

**Aceptación:** documentos en el repositorio y decisiones bloqueantes respondidas.

**Resultado:** GDD y hoja de ruta creados. Nueve decisiones resueltas: D-02, D-03, D-05, D-07 y D-14 a D-18.

## Fase 1: Prototipo jugable (*vertical slice*)

- Un jugador (William Dyer) con teclado o mando: movimiento, esquive, su arma inicial (cartuchos de dinamita) y el revólver. Cada arma define en sus datos cómo apunta (D-05).
- Escenario provisional inspirado en el nivel 1 de la parte 1 (campamento base en la costa del mar de Ross): arena de unas 3×3 pantallas con luces y obstáculos (D-03).
- Nivel de 5 minutos por oleadas, con el Acechador como élite en el evento final (D-02).
- Enemigos: pingüinos albinos ciegos y fragmentos protoplásmicos (modelos nuevos), más el Acechador como élite de prueba. Cada uno con al menos un patrón de ataque.
- Experiencia y subida de nivel con elección entre 3 mejoras; la elección pausa la partida (D-16).
- Vida y cordura con los tres tipos de daño y su diferenciación visual. Una sola crisis de locura: la parálisis, como congelaciones intermitentes (D-14).
- HUD del J1 con ambas barras.
- Muerte y reinicio.
- Cambio del renderizador a Forward+ y revisión del aspecto de los modelos existentes (D-15).

**Aceptación:** una partida de 5 minutos jugable de principio a fin; prueba de carga con 150 enemigos y 1.000 balas medida y documentada, en Forward+ y en Compatibility como referencia.

### Hitos de la fase 1

Cada hito cierra con tests en verde, capturas revisadas y commit. ⏸ = parada para revisión.

| Hito | Contenido | Estado |
|---|---|---|
| 1.1 ⏸ | Base técnica: Forward+ y entorno recalibrado, GUT, caché de mallas, capturas por tiempo, primera medición de rendimiento | **Hecho y aprobado** |
| 1.2 ⏸ | Modelos nuevos: `voxlib.py`, Dyer, pingüino, fragmento, atrezo del campamento y sus animaciones | **Hecho y aprobado** (Dyer y pingüino rehechos tras la revisión) |
| 1.3 | Jugador, entrada y cámara: capa de entrada (teclado, mando, bot), movimiento, esquive, arena provisional | **Hecho** |
| 1.4 | Balas, daño y armas: gestor de balas, rejilla espacial, lenguaje visual de los daños, revólver y dinamita | **Hecho** |
| 1.5 | Enemigos y nivel: datos, comportamientos, oleadas por pesos, evento final del Acechador | **Hecho** |
| 1.6 | Progresión, cordura y HUD: experiencia, mejoras, parálisis, HUD del J1, muerte y reinicio, pausa | **Hecho** |
| 1.7 ⏸ | Rendimiento y cierre: prueba de carga, optimizaciones si hacen falta, partida de 5 minutos jugada por ti | Prueba de carga hecha; **pendiente de tu partida** |

## Fase 2: Menús, guardado y cooperativo local

Ampliada el 26-09-2026: adelanta de la fase 5 el guardado, el menú principal, la configuración, la selección de personaje, el mapa de niveles, la tienda y los compañeros, porque la selección de personaje es donde se unen los jugadores (D-22 a D-25).

- **Portada y guardado:** "Pulsa Start" (vale cualquier botón principal). Tres huecos de partida locales con tiempo jugado, objetos comprados, compañeros desbloqueados y dinero, y la opción de borrar cada uno con confirmación.
- **Menú principal:** Jugar (local u online; online visible pero desactivado hasta la fase 9), Tienda, Configuración (vídeo, audio, controles y juego) y Salir.
- **Selección de personaje:** los jugadores se unen pulsando Start en su mando y eligen a la vez. Un personaje elegido no puede elegirlo otro. Debajo, cada uno elige compañero entre los desbloqueados.
- **Mapa de niveles:** las 3 partes × 5 niveles, con solo el nivel 1 abierto por ahora.
- **Cuatro personajes jugables:** Dyer, Olmstead, Legrasse y Johansen, con sus armas iniciales (revólver, escopeta y machete, nuevas) y pasivos.
- **Partida de 1 a 4 jugadores:** asignación de dispositivos y conexión en caliente, HUD en las cuatro esquinas y cámara compartida con zoom.
- **Pausas (D-16):** Start y la subida de nivel pausan a todos; en la subida, cada jugador elige en su cuadrante. Ficha y mapa se abren por cuadrante sin pausar.
- **Experiencia compartida (D-07)**, dificultad escalada por jugadores y reanimación.
- **Sistema de cordura completo:** las cinco crisis (la paranoia resta cordura a los compañeros, D-17), calmar a un compañero, recuperación cerca de compañeros y de luces, auras de presencia y locura acumulada.
- **Tienda y compañeros:** dinero ganado en cada partida, tres secciones (potenciadores, compañeros y personajes) y un catálogo corto: cinco potenciadores de cinco niveles y dos compañeros funcionales.

**Aceptación:** 4 mandos (o 3 mandos y teclado) jugando simultáneamente sin conflictos de entrada, desde la portada hasta el final del nivel, con el progreso guardado en su hueco.

### Hitos de la fase 2

| Hito | Contenido | Estado |
|---|---|---|
| 2.1 | Guardado y portada: huecos de partida versionados, "Pulsa Start", ventana de huecos con borrado y confirmación | **Hecho** |
| 2.2 | Menú principal y configuración: Jugar (local / online desactivado), Tienda, Configuración (vídeo, audio, controles, juego), Salir | **Hecho** |
| 2.3 | Selección de personaje y mapa de niveles: gestor de dispositivos, unirse con Start, cursores simultáneos, personajes únicos, compañero bajo la tarjeta, mapa 3×5 | **Hecho** |
| 2.4 ⏸ | Personajes nuevos: Olmstead, Legrasse y Johansen (modelos, datos, pasivos), escopeta y machete | Hecho; **pendiente de tu revisión** |
| 2.4b ⏸ | Siete personajes más (D-26), en dos tandas con revisión: Peaslee, Varga, Whipple y Blake (rifle, Necronomicón, bisturís, Trapezoedro); después Iwanicki, Elwood y Malone (fórmula de expulsión, Colt .45, Thompson) | Las dos tandas hechas, **pendientes de tu revisión** |
| 2.5 | Atributos (D-27): los siete, repartos por personaje, +1 ponderado al subir de nivel, un arma al empezar, 4 armas y 4 objetos (D-28), personajes de inicio 2+2 (D-30) | **Hecho** |
| 2.6 | Arsenal I (D-29): armas de fuego y lanzadas, fusiones con las antiguas, zonas de daño y estados de los enemigos; granadas de palo en el cinturón de Dyer | **Hecho** |
| 2.7 ⏸ | Arsenal II (D-29, GDD 5.3): las 8 mágicas (Signo Arcano, Resonador, Báculo del Farolero, Lente del Éter, Polvo de Ibn-Ghazi, Orbe Mi-Go, Rayo de Yith, Daga ritual) | Hecho; **pendiente de tu revisión** |
| 2.7b ⏸ | Arsenal II (GDD 5.3): las 4 de fuego (Tesla, Springfield, Lewis, Lugers) y las 5 físicas (inyector de West, bumerán, red, martillo, bastón estoque) | Hecho; **pendiente de tu revisión** |
| 2.8 ⏸ | Clima estético (D-33): nieve, ceniza, lluvia, ventisca, niebla, sombras de nubes y rayos; seis climas de muestra y la nevada en el nivel 1 | Hecho; **pendiente de tu revisión** |
| 2.9 ⏸ | Partida de 1 a 4 jugadores: cámara compartida con zoom, HUD en las cuatro esquinas, bots como jugadores extra | Hecho; **pendiente de tu prueba con varios mandos** |
| 2.10 ⏸ | Reglas del cooperativo: experiencia compartida, subida de nivel por cuadrante, pausa común, escalado, reanimación | Hecho; **pendiente de tu prueba con varios mandos** |
| 2.11 ⏸ | Cordura completa: cinco crisis, calmar, recuperación, auras, locura acumulada | Hecho; **pendiente de tu revisión** |
| 2.12 ⏸ | Ficha (con atributos) y mapa por cuadrante, sin pausa | Hecho; **pendiente de tu revisión** |
| 2.13a ⏸ | Economía (D-31): dólares por enemigo, bono por nivel, baúles arcanos, resumen con lo ganado | Hecho; **pendiente de tu revisión** |
| 2.13b ⏸ | Tienda: catálogo por datos para ~10 h (potenciadores 5×5, personajes, compañeros, 5.º hueco de arma y de objeto), compra con confirmación, efectos en partida | Hecho; **pendiente de tu revisión** |
| 2.13c ⏸ | Compañeros: perro de trineo de Lake (muerde) y gato de Ulthar (−20 % de daño mental), con modelo | Hecho; **pendiente de tu revisión** |
| 2.13d ⏸ | Tienda de antigüedades en voxel con el anciano (diorama detrás del menú) | Hecho; **pendiente de tu revisión** |
| 2.14 ⏸ | Logros y desbloqueos (D-32): 18 logros por datos con recompensa (dólares, Legrasse, Johansen, el gato), aviso en partida y sección en el menú principal | Hecho; **pendiente de tu revisión** |
| 2.15 ⏸ | Bestiario de compañeros (D-36) en tres tandas: 2.15a sistema de comportamientos, gato negro, sapo, búho, rata y shoggoth bebé; 2.15b byakhee, cuervo, polilla, gaviota y Mi-Go; 2.15c Tíndalos, Yig, pez, dhole y cabra | Hecho; **pendiente de tu revisión** |
| 2.16 ✅ | Vestuario (D-34) en dos tandas: sistema y 8 prendas; después el resto | Hecho (03-10-2026), pendiente de revisión |
| 2.17 ⏸ | Cierre: prueba de carga con 4 jugadores y tu prueba con varios mandos | Pendiente |

## Fase 3: Pipeline de contenido

Sistema de datos para enemigos, armas, oleadas y niveles. Generador de escenarios voxel. Patrones de balas reutilizables. Comando para previsualizar cualquier enemigo con sus animaciones.

**Aceptación:** añadir un enemigo nuevo solo requiere su generador y su archivo de datos, sin tocar el código de los sistemas.

Hecha el 20-10-2026. Se cumple la aceptación: el Profundo se añadió solo con datos (03-10-2026) y las fases 4, 6 y 7 sumaron sus enemigos igual (50 en `data/enemies/`), validados por `tests/test_content.gd`. Las evoluciones de las 50 armas salen de `tools/gen_evoluciones.gd`; el generador de escenarios general (`tools/arena_kit.py`) llegó en el hito 4.1; `still` y `anim` previsualizan cualquier modelo con sus animaciones.

## Fase 4: Parte 1 completa (*En las montañas de la locura*)

Cinco niveles, sus diez criaturas y el shoggoth primigenio.

**Aceptación:** la parte 1 se puede completar en cooperativo.

### Hitos de la fase 4 (plan propuesto el 03-10-2026)

Cada hito con su revisión de arte (modelos de frente, de perfil y de espaldas, y en partida) antes de pasar al siguiente. D-04 y D-19, resueltas.

| Hito | Contenido | Estado |
|---|---|---|
| 4.1 | Generador de escenarios general: una receta por nivel (suelo, bordes, luz, clima, atrezo repartido, zonas libres) que produce el JSON de la arena y su mapa de obstáculos; el campamento pasa a ser una receta más. Arena del nivel 2: el campamento destruido de Lake (tiendas rasgadas, el avión, cajas reventadas, mesas de disección, ventisca) | Hecho (03-10-2026), pendiente de revisión |
| 4.2 | Los Antiguos: modelo base (cuerpo de barril, cabeza de estrella, alas plegadas) y sus animaciones. Antiguo revivido (anda y golpea) y Antiguo alado (vuela en picado, comportamiento nuevo). Seres únicos (D-04: `EnemyData.unique`). Nivel 2 jugable con su evento final | Hecho (03-10-2026), pendiente de revisión |
| 4.3 | Nivel 3, el paso de la cordillera y sus cavernas: arena, shoggoth esclavo (masa grande que embiste) y shoggoth mimético (se disfraza de Antiguo y se transforma al acercarse) | Hecho (03-10-2026), pendiente de revisión |
| 4.4 | Nivel 4, la ciudad ciclópea: arena de piedra con relieves, Antiguo guerrero (élite con lanza) y Antiguo mutilado (lento, deja limo) | Hecho (03-10-2026), pendiente de revisión |
| 4.5 | Nivel 5, los túneles y el mar subterráneo: arena, shoggoth de ojos luminosos y Antiguo del mar abisal. Jefe: el shoggoth primigenio (fases, persecución por el túnel, "¡Tekeli-li!") | Hecho (04-10-2026), pendiente de revisión |
| 4.6 | Cierre: los cinco niveles seguidos en cooperativo con bots, equilibrio de ritmo y dificultad, y tu partida | Equilibrio hecho (04-10-2026); **falta tu partida** |

## Fase 5: Arranque, relatos y ampliación de la tienda

El guardado, los menús, la selección de personaje, el mapa de niveles y la tienda se adelantaron a la fase 2 (D-22). Queda:
- **Arranque:** ficha del proyecto (con qué está hecho, licencia y aviso del uso de IA) e intro que presenta el juego, antes de la portada.
- **Relatos:** al elegir un nivel en el mapa se cuenta su relato antes de jugarlo; se saltan manteniendo pulsado.
- **Tienda:** ampliar el catálogo de potenciadores y compañeros.
- Armitage y West, modelados en esta fase (hito 5.5).

Hecha el 08-10-2026: 5.1 ficha del proyecto, 5.2 intro, 5.3 relatos de los 15 niveles, 5.4 tienda ampliada (cuatro potenciadores, sexta funda y sexto bolsillo) y 5.5 Armitage y West.

## Fase 6: Parte 2 completa (*La sombra sobre Innsmouth*)

Cinco niveles, sus diez criaturas y Padre Dagon.

**Aceptación:** la parte 2 se puede completar en cooperativo.

### Hitos de la fase 6 (plan aprobado el 06-10-2026)

Se adelanta a la fase 5 (relatos y arranque), que no bloquea el contenido. Cada hito pasa la misma revisión de arte que en la fase 4 (modelos de frente, de perfil y de espaldas, y en partida). Primer escenario fuera de la Antártida: tierra, madera, piedra y agua de puerto, con luz de atardecer nublado y niebla marina.

| Hito | Contenido | Estado |
|---|---|---|
| 6.0 | **Base común** (D-13, jefes colosales y tiaras, resueltas en el GDD: la parte 2 es más difícil que la 1, contando con las mejoras permanentes de la tienda). En `cuerpo.py`, el "aspecto de Innsmouth" por grados (0 humano, 1 ojos saltones y piel grisácea, 2 cuello con agallas y calva, 3 casi Profundo), sobre los cuerpos del estilo 4. Profundo definitivo en estilo 4, que sustituye al prototipo `clasico`. Suelo nuevo en el shader (tierra mojada, adoquín, tablas) y clima de lluvia y niebla marina | Hecho (06-10-2026), pendiente de revisión |
| 6.1 | **Nivel 1, Newburyport y la carretera a Innsmouth.** Arena: carretera de tierra entre marismas, la parada del autobús de Joe Sargent, casas de madera cerradas y postes de telégrafo. Habitantes de Innsmouth (grado 1, etiqueta `humana`, cuerpo a cuerpo torpe, en grupo) y acólitos de la Orden de Dagon (túnica sencilla y amuleto, disparo mental). Evento final: un acólito mayor (único) | Hecho (06-10-2026), pendiente de revisión |
| 6.2 | **Nivel 2, las calles y el templo de la Orden.** Arena: calles de casas georgianas en ruinas y la fachada del antiguo templo masónico. Híbridos avanzados (grado 3, rápidos, a saltos, `humana`) y sacerdotes de la tiara (élite, cánticos mentales en abanico, vestiduras y tiara de oro). Evento final: el sumo sacerdote | Hecho (06-10-2026), pendiente de revisión |
| 6.3 | **Nivel 3, el hotel Gilman House y la huida por los tejados.** Arena de tejados (bordes: caída a la calle, chimeneas y claraboyas como obstáculos). Profundos (estilo 4) y el Acechador, ya hecho, como élite. Evento final: la horda del Arrecife del Diablo (oleada masiva durante un tiempo, no un único enemigo: objetivo "sobrevive") | Hecho (06-10-2026), pendiente de revisión |
| 6.4 | **Nivel 4, los pantanos y la vía muerta a Rowley.** Arena: terraplén del tren con traviesas y agua estancada a los lados (frena a los jugadores). Profundos ancianos de Y'ha-nthlei (sobre el prototipo `abisal`, bioluminiscentes, aura). Minijefe: Barnabas Marsh transformado (único, ropa de patriarca rota) | Hecho, pendiente de revisión (07-10-2026) |
| 6.5 | **Nivel 5, el Arrecife del Diablo y Y'ha-nthlei.** Arena de arrecife negro con pozas y columnas ciclópeas sumergidas, luz verde desde abajo. Pth'thya-l'yi (única, invoca Profundos) y Madre Hydra (única, minijefa previa al jefe) | Hecho, pendiente de revisión (07-10-2026) |
| 6.6 | **Jefe: Padre Dagon.** Colosal: emerge del agua en el borde de la arena, golpea con las manos (avisos grandes en el suelo), lanza oleadas de agua y llama a Profundos; varias fases como el shoggoth primigenio (`BossBehavior`). Sobre el prototipo `bruto` | Hecho, pendiente de revisión (08-10-2026): sale de simas en la mitad norte del arrecife, no de la orilla (`DagonBehavior`) |
| 6.7 | **Cierre:** la parte entera en cooperativo con bots, equilibrio (como en el 4.6, medido sin compras y con las compras esperables tras la parte 1: difícil, nunca exasperante), la Biblioteca con las entradas nuevas (textos y mapas) y tu partida | Hecho salvo tu partida (08-10-2026) |

## Fase 7: Parte 3 completa (*La llamada de Cthulhu*)

Cinco niveles, sus diez criaturas y Cthulhu. Decidido el 08-10-2026: los Ángulos devoradores son un **peligro del escenario** (zonas de geometría imposible que se abren con aviso, atraen hacia su centro y engullen a quien se queda dentro; no se matan, se esquivan) y **Cthulhu se combate como Dagon** (colosal a 16 voxels/m, solo la parte visible, asomando por la puerta de R'lyeh, anclado y con fases) y, como en el relato, al "morir" se deshace en una nube verde y **se recompone una vez**, más furioso. Más difícil que la parte 2 (D-13).

### Hitos de la fase 7 (plan aprobado el 08-10-2026)

| Hito | Contenido | Estado |
|---|---|---|
| 7.0 | **Base común:** cultistas del culto de Cthulhu en estilo 4 (túnicas oscuras, amuletos del ídolo, máscaras con tentáculos, antorchas que dan luz), el ídolo de piedra verdinegra como atrezo y el suelo de R'lyeh (piedra verdinegra con ángulos que no cuadran). Paleta: negro verdoso, hueso, resplandor de hogueras | Hecho, pendiente de revisión (08-10-2026) |
| 7.1 | **Nivel 1, Providence: el estudio de Wilcox.** Primera arena de interior (estudio con esculturas, caballetes y el bajorrelieve de arcilla) y la calle. Pesadillas de la oleada de sueños (etéreas, atraviesan el decorado, daño mental) y cultistas. Evento final: la pesadilla del bajorrelieve | Hecho, pendiente de revisión (08-10-2026) |
| 7.2 | **Nivel 2, los pantanos de Luisiana: el ritual.** Claro con hogueras, el monolito del ídolo y el corro, con agua que frena. Diablos con alas de murciélago (picados) y cultistas armados del *Alert* (balas físicas). Evento final: el sacerdote del ritual | Hecho, pendiente de revisión (08-10-2026) |
| 7.3 | **Nivel 3, los muelles y la cubierta del *Alert*.** Engendros de Cthulhu (minijefe) y Profundos servidores (de la parte 2) | Hecho, pendiente de revisión (08-10-2026) |
| 7.4 | **Nivel 4, la tormenta en el Pacífico.** Cubierta del *Emma* en la tormenta (lluvia, rayos, olas que barren la cubierta). La cosa blanca polipoide y los Ángulos devoradores como peligro | Hecho, pendiente de revisión (08-10-2026) |
| 7.5 | **Nivel 5, R'lyeh emergida.** Arquitectura imposible y la puerta colosal. Primigenios menores (minijefes) y emanaciones de la puerta (masas gelatinosas verdes) | Hecho, pendiente de revisión (08-10-2026) |
| 7.6 | **Jefe: Cthulhu.** Asoma por la puerta, fases (zarpazos con aviso, tentáculos que barren, alas, llamada de criaturas); al caer se deshace en nube verde y se recompone una vez | Hecho, pendiente de revisión (08-10-2026) |
| 7.7 | **Cierre:** la parte encadenada con bots, con y sin compras, la Biblioteca y tu partida | Hecho salvo tu partida (08-10-2026) |

## Fase 8: Pulido y distribución

Audio, equilibrado, accesibilidad, rendimiento final y distribución. Decidido el 08-10-2026: publicar primero en **itch.io** (D-12) y efectos de sonido de **bancos libres CC0**.

**Aceptación** (aprobada el 21-10-2026):
- Las tres partes se completan en Normal en solitario y en cooperativo, con bots y con tus partidas como referencia: difíciles, nunca exasperantes (D-13).
- Sonido y música en todos los niveles y menús, y las opciones de accesibilidad (8.3) funcionan.
- Rendimiento: la prueba de carga de la fase 1 (150 enemigos y 1.000 balas) y el peor momento de cada parte mantienen 60 fps en el equipo de desarrollo, medidos dos veces.
- Una partida completa con bots termina sin errores en la consola y con los tests en verde.
- Builds de Windows y macOS publicadas en itch.io, descargadas y arrancadas en un equipo limpio, con la página terminada (capturas, texto y portada).

| Hito | Contenido | Estado |
|---|---|---|
| 8.1 | **Sistema de sonido y efectos:** gestor de efectos con buses, variaciones de tono y límite de voces; efectos CC0 de disparos, impactos, golpes, esquive, recoger gemas, subida de nivel, menús, criaturas por familia y jefes; citados en la ficha | Hecho, pendiente de que lo escuches (08-10-2026) |
| 8.2 | **Música por nivel:** una pista por parte (o por nivel) y la del jefe, con fundidos (a falta de pistas, CC0 o las tuyas) | Hecho con pistas CC0 provisionales (08-10-2026) |
| 8.3 | **Accesibilidad:** tamaño del texto, balas para daltónicos (formas además de colores), reducir destellos, temblor de cámara y distorsiones | Hecho, pendiente de revisión (08-10-2026) |
| 8.4 | **Equilibrio final** con tus partidas de las tres partes como referencia | Pendiente (necesita tus partidas) |
| 8.5 | **Exportación y página de itch.io:** builds de Windows y macOS, subida con butler, capturas, texto y portada de la página | Builds y página listas (08-10-2026); falta subir (tu cuenta de itch.io) |
| 8.6 | **Objetos I (D-38, GDD 5.5):** modificadores generales del jugador que lee `Weapon.stat` (proyectiles, alcance, velocidad, área, recarga, duración, perforación, crítico, daño por grupo, élites, empuje); `UpgradeData` con varios efectos y tope; los objetos de estadísticas (~33); ficha, tarjetas y Biblioteca; tests | Hecho, pendiente de revisión (09-10-2026): 32 objetos nuevos, 37 en total |
| 8.7 | **Objetos II:** los que necesitan sistemas: escudo de Nodens, *ankh*, escamas, señuelo y petardos al esquivar, esquive doble, llave de plata (cambiar opciones), disparadores al abatir e impactar, diente de *shoggoth* e ídolo de Cthulhu (~12) | Hecho, pendiente de revisión (09-10-2026): 13 objetos; 50 en total |
| 8.8 | **Arsenal III (GDD 5.4):** las 16 armas, con entregas nuevas (cepos, rebote, cadencia creciente, agujero negro, rayo giratorio, nube que deriva, enemigos contra enemigos), reglas de daño (D-37), sonidos y textos | Hecho, pendiente de revisión (09-10-2026): 50 armas (16 físicas, 17 de fuego, 17 mágicas), con icono |
| 8.9 | **Iconos y cierre:** 61 iconos con Replicate (~3 $), textos de la Biblioteca, peso de armas y objetos en la subida de nivel (con 100 opciones deben seguir saliendo mejoras de lo que se lleva) y prueba con bots | Hecho, pendiente de revisión (09-10-2026) |
| 8.10 | **Atrezo y escenarios rehechos** con referencias de FLUX: más detalle y resolución en los 15 escenarios (`arte=v1` enseña la versión anterior) | Hecho, pendiente de revisión (09 a 14-10-2026) |
| 8.11 | **Efectos de armas en cubitos** (`VoxelFx`): llamas, humo, brasas, burbujas, vapor y explosiones | Hecho, pendiente de revisión (11-10-2026) |
| 8.12 | **Dificultad** (Investigador, Normal y Pesadilla) y **equilibrio con simulaciones** (`SmartBot`, `tools/simular.py`) | Hecho, pendiente de revisión (12 a 15-10-2026) |
| 8.13 | **Revisión de arte dentro del juego** (temporal, solo en desarrollo: `review/peticiones.json`, `tools/vigilar_revision.py`) | Hecho (12-10-2026) |
| 8.14 | **Ambiente vivo** en los 15 escenarios (`data/ambient.json`, `Ambient`), noches más legibles (`"gamma"` de la arena), bordes y mapas de la Biblioteca | Hecho, pendiente de revisión (16 y 17-10-2026) |
| 8.15 | **Tienda ampliada** con 15 objetos, y cuervo y tres animaciones más en la portada | Hecho, pendiente de revisión (17 y 18-10-2026) |
| 8.16 | **Subidas de nivel por turnos en cooperativo** (D-39): experiencia común, sube un jugador cada vez; equilibrio comprobado con 2 y 4 jugadores | Hecho, pendiente de tu prueba con varios mandos (20 y 21-10-2026) |
| 8.17 | **Dificultad del 1 al 10 por características** (D-42, temporal, para calibrar): nueve características en la pausa, el 3 es la Normal de antes; tabla del bot del 1 al 10 | Hecho (29-10-2026), pendiente de tu calibración |

## Fase 9: Online

Según D-10 (resuelta el 21-10-2026 en el GDD): anfitrión con autoridad y clientes con ENet, conexión directa por UPnP, IP o código, mezcla de jugadores locales y remotos (hasta 4), una cámara por PC y cada uno con su guardado.

**Aceptación:** una parte completa jugada entre dos PCs por internet, mezclando jugadores locales y remotos, sin desincronizaciones visibles con 150 ms de latencia; desconexión y vuelta de un invitado entre niveles; tests en verde.

### Hitos de la fase 9 (plan aprobado el 21-10-2026)

| Hito | Contenido | Estado |
|---|---|---|
| 9.1 | **Base de red:** sesión de red (ENet, anfitrión y clientes), UPnP, código de sala que codifica IP y puerto, menú "Jugar online" con Crear y Unirse, y pruebas con dos instancias en el mismo PC (latencia y pérdida simuladas) | Hecho, pendiente de tu prueba (21-10-2026); el selector del código con el mando pasa al 9.2 |
| 9.2 | **Sala y selección de personaje en red:** `SelectState` sincronizado, cada invitado con sus desbloqueos, listos y nivel elegido por el anfitrión; selector del código con el mando (plan aprobado el 22-10-2026: la sala es la propia selección; hasta el 9.3 el anfitrión juega con bots en lugar de los invitados) | Hecho, pendiente de tu prueba (22-10-2026) |
| 9.3 | **Partida en red** (plan aprobado el 22-10-2026; cambia el reparto de autoridad, ver D-10): cada PC manda en sus jugadores (movimiento, esquive, golpes recibidos, vida y cordura) y el anfitrión en el mundo (enemigos, daño a enemigos, balas enemigas, gemas, experiencia, fin de nivel); los invitados juegan una partida espejo con enemigos marioneta por fotos interpoladas, balas enemigas por eventos y armas de los jugadores solo visuales. Hasta el 9.4, las subidas de los invitados las elige el anfitrión (primera opción) y cada PC tiene una cámara básica | Hecho en tres partes, pendiente de tu prueba (22-10-2026) |
| 9.3a | **Mundo espejo:** partida en modo espejo en los invitados; jugadores dueños de su movimiento (estado a 30 Hz); enemigos marioneta por fotos (20 Hz) con interpolación; cámara por PC; reloj, evento final y fin de nivel para todos. *Aceptación:* dos ventanas con un bot cada una y `net_lag=150`, sin tirones, el nivel acaba a la vez | Hecho, pendiente de tu prueba (22-10-2026): tres niveles seguidos a dos ventanas con `net_lag=150` |
| 9.3b | **Combate:** balas enemigas por eventos con los impactos decididos en el PC del dueño; contacto; armas visuales con el daño en el anfitrión; vida, cordura, derribos y reanimación; gemas, experiencia común y subidas provisionales. *Aceptación:* el invitado esquiva y recibe daño según lo que ve; vida, experiencia y abatidos coinciden | Hecho, pendiente de tu prueba (22-10-2026): dos ventanas con `net_lag=150`, daño, derribo y reanimación vistos igual en las dos |
| 9.3c | **Efectos y jefes:** eventos de efectos y sonidos; ataques avisados con daño a los invitados; cofres, objetos y rompibles; jefes y enemigos especiales; ancho de banda. *Aceptación:* la parte 1 entera a dos ventanas con bots y `net_lag=150` sin desincronizaciones visibles | Hecho, pendiente de tu prueba (22-10-2026): la parte 1 entera a dos ventanas, cada nivel acaba a la vez con las mismas bajas |
| 9.4 | **Cámara por PC e interfaz:** cámara de los jugadores locales, flechas de los que quedan fuera, HUD por PC, y pausa y subidas por turnos para todos | Hecho en dos partes, pendiente de tu prueba (22-10-2026): 9.4a (subidas y pausa para todos) y 9.4b (flechas, cámara de los eliminados, HUD con el PC y el ping, aviso de conexión) |
| 9.5 | **Desconexiones y guardado:** bot al caer la conexión y vuelta al siguiente nivel, fin de partida si se va el anfitrión, dinero y logros en la partida de cada invitado | Hecho en dos partes, pendiente de tu prueba (22-10-2026): 9.5a (vuelta al siguiente nivel con su progreso; bot desde el principio si no vuelve) y 9.5b (pantalla final en el invitado al cerrar el anfitrión o perder la conexión; bajas y logros en su partida) |
| 9.6 | **Cierre:** ancho de banda y rendimiento con 4 jugadores en 2 a 4 PCs, partidas con bots en red, documentación y tu prueba real por internet (plan aprobado el 22-10-2026: 9.6a carga, 9.6b partidas con bots, 9.6c documentación, registro y builds) | Hecho (23-10-2026), pendiente de tu prueba por internet (`docs/PRUEBA_ONLINE.md`): 9.6a (con 4 PC y 75 vivos, unos 19 kB/s por invitado comprimido y 0,46 ms de red por fotograma en el anfitrión), 9.6b (partes 2 y 3 enteras con `net_lag=150` y 2 % de pérdida, la 3 mezclando locales y remotos) y 9.6c (guía `docs/JUGAR_ONLINE.md`, registro de red en `user://logs/red/` y builds). Después, ayudas para la prueba: versión del juego en menú, pausa, sala y guardado; marcas F9 o LB+RB en los registros de todos (`tools/marcas.py`) |

## Fase 10: Guardado en la nube con GitHub

Según D-11 (resuelta el 26-10-2026): copia de los tres huecos y de los controles en un gist secreto del jugador, conectado con el flujo de autorización por dispositivo de GitHub. La partida local sigue mandando; sin conexión se juega igual.

**Aceptación:** con dos PC y la misma cuenta, lo jugado en uno aparece en el otro al abrir la ventana de huecos; si se ha jugado en los dos sin conexión, el juego pregunta cuál quedarse; sin conexión o con la cuenta desconectada, todo funciona como antes.

| Hito | Contenido | Estado |
|---|---|---|
| 10.1 | **Cliente de GitHub:** flujo por dispositivo, buscar, crear, leer, escribir y borrar el gist (encontrado por su fichero marcador), autoload `Cloud` con el token en `user://cloud.json`; tests con transporte falso y prueba de verdad (`cloud_check`) | Hecho (26-10-2026). Falta el `client_id` de la OAuth App del autor (`data/cloud.json`) |
| 10.2 | **Sincronización:** `SaveData` versión 2 (revisión, base y PC), subida tras cada guardado y bajada al abrir los huecos, conflicto con elección del jugador, controles | Hecho (26-10-2026) |
| 10.3 | **Interfaz:** pestaña Nube en Configuración, ventana con el código, estado en cada hueco y avisos | Hecho (26-10-2026) |
| 10.4 | **Cierre:** documentación, guía para jugadores, builds (TLS) y prueba del autor con dos PC | Hecho (26-10-2026): guía `docs/GUARDADO_NUBE.md`, README y build de Windows probada contra GitHub. Falta el `client_id` (pasos en la guía) y tu prueba con dos PC |

## Fase 11: Calidad gráfica, animación y efectos

Pedida por el autor el 27-10-2026 («quiero hacer todo lo que sugieres, comienza por el primer bloque»): más calidad gráfica, animaciones mejores y más fluidas, y más efectos visuales. Todo se comprueba con capturas, vídeo a la frecuencia del monitor y medición de rendimiento antes y después (las arenas grandes van a 4-6 ms: lo que cueste se queda en las calidades altas). En red, lo visual se hace en cada PC; nada de esto cambia la simulación.

**Aceptación:** el autor ve en partida (solo y en cooperativo) que golpes, muertes y movimiento pesan más y se leen mejor; el rendimiento en Media no empeora más de 0,3 ms en las arenas más caras; con «Bajo» se juega en un portátil modesto.

*Estado (28-10-2026):* los ocho hitos hechos (11.6-11.8, lo que faltaba de la lista de sugerencias). El rendimiento en Media, comprobado contra la versión anterior a la fase en R'lyeh, las calles de Innsmouth y el pantano: no empeora (detalle en `docs/ESTADO.md`). Faltan la partida del autor (solo y en cooperativo) y probar «Baja» en un portátil modesto.

| Hito | Contenido | Estado |
|---|---|---|
| 11.1 | **Impacto y cuerpo:** micro-pausa al impactar (solo los golpes fuertes, las muertes de élites y únicos, y nunca en red ni con bots acelerados), temblor del enemigo golpeado; andar con peso (paso asimétrico, cadera y hombros, cabeza estable, brazos y cabeza con retraso), inclinación al acelerar y rebote al frenar; el modelo del enemigo se desmorona en cubos al morir; manchas de icor y de quemado que duran más (con tope) | Hecho (27-10-2026), pendiente de tu revisión: `HitStop`, `Crumble`, `GroundMarks`, andar con peso e inclinación (`Player._lean_step`); sin coste medible en juego normal |
| 11.2 | **Sensación de combate:** números de daño opcionales (críticos más grandes), destello y empujón del modelo más legibles, temblor de cámara con ruido suave y caída exponencial, gemas que se aspiran en curva con destello | Hecho (28-10-2026), pendiente de tu revisión: `DamageNumbers` (opción en Accesibilidad), aplastado e inclinación del enemigo golpeado, ruido suave en `GameCamera`, gemas que aceleran y anillo que late |
| 11.3 | **Luz y postproceso:** fogonazo de luz en las armas de fuego y en las explosiones (con tope de luces), gradación de color por parte (fría en la Antártida, verde sucia en Innsmouth, violeta en R'lyeh), efectos de cordura baja más visibles (viñeta y aberración) | Hecho (28-10-2026), pendiente de tu revisión: `data/grades.json` y `Atmosphere.set_grade`, `Player.muzzle_flash`, `Explosion.MAX_LIT`, viñeta y aberración en `sanity_fx.gdshader` |
| 11.4 | **Mundo vivo:** ondas en el agua al pasar y al caer cuerpos, espuma de los que salen del mar, cuerdas, telas y llamas que se mueven con el esquive y las explosiones, partículas de primer plano desenfocadas (nieve, ceniza, esporas) | Hecho (28-10-2026), pendiente de tu revisión: `Ripples`, `Gusts` (globales `gust_a`/`gust_b`), primer plano en `Weather` (`near_amount`). Sin espuma del mar (ningún enemigo sale de él) ni llamas |
| 11.5 | **Calidad configurable:** preajustes Bajo, Media, Alta y Ultra (suavizado, SSAO, sombras, niebla volumétrica, partículas, tope de luces y de manchas), con medición en cada arena | Hecho (28-10-2026), pendiente de tu revisión: `Quality` y `data/quality.json`; Alta como antes; medido en tres arenas (Ultra +0,7-1,3 ms, Baja −0,3-0,6 ms) |
| 11.6 | **Aparición:** los enemigos salen del suelo (polvo), del agua (salpicadura, ondas y espuma), del cielo o de la niebla (voxel a voxel) en vez de crecer de golpe; quietos y sin hacer daño mientras | Hecho (28-10-2026), pendiente de tu revisión: `Enemy._rise_start`, `EnemyData.rise`, `Crumble.dress`; el polvo, el agua y el sonido (`rise_*` en `data/sfx.json`), solo a la vista |
| 11.7 | **Estirar y aplastar** con los saltos y caídas (cualquier enemigo, el doble los blandos) y en el sapo compañero | Hecho (28-10-2026), pendiente de tu revisión: `Enemy._air_step`, `EnemyData.soft` |
| 11.8 | **Huellas** de jugadores y enemigos en nieve y barro, y mojadas al salir del agua, en un solo MultiMesh | Hecho (28-10-2026), pendiente de tu revisión: `Footprints`, `Ambient._print_kind`; en Baja, solo las de los jugadores (`enemy_prints`) |
| 11.9 | **Gestos de reposo:** quieto un rato, el personaje mira alrededor, se estira, revisa el arma o cambia el peso | Hecho (28-10-2026), pendiente de tu revisión: `anim_humano.FIDGETS`, `Player._fidget_step`; también los compañeros (`Pet._fidget_step`, `Anims.fidgets`) |
| 11.10 | **Reacción al golpe por familia:** los humanos se doblan, los pingüinos se tambalean, las masas (fragmentos y shoggoths) tiemblan en ondas y los Profundos dan un respingo | Hecho (28-10-2026), pendiente de tu revisión: `hit` y `HIT_TIME` en su script de animación (`Anims.hit`); los demás y los colosales, aplastados como antes |
| 11.11 | **Paso entre niveles:** la partida sale de negro con un rótulo del nivel y funde a negro al ir al relato | Hecho (28-10-2026), pendiente de tu revisión: `LevelCard` |
| 11.12 | **Retrato vivo:** el retrato del HUD parpadea, pone la mueca al recibir un golpe y la de pánico en las crisis | Hecho (28-10-2026), pendiente de tu revisión: `Hud.PortraitFace` |
| 11.13 | **Entrada de los jefes:** franjas de cine, la cámara encuadra a los jugadores y al jefe, cámara lenta un momento y rótulo con la frase del nivel y su nombre | Hecho (28-10-2026), pendiente de tu revisión: `BossIntro`, `GameCamera.focus`; `boss_intro=false` para comparar |

## Fase 12: Detalles de personajes, enemigos, compañeros y escenarios

Elegida por el autor el 28-10-2026 de una lista de sugerencias (19 de 22). Como en la fase 11: lo visual se hace en cada PC a partir de lo que ya viaja por la red (vida, abatido, cordura, muertes, ataques), nada cambia la simulación salvo donde se dice; cada hito se comprueba con hojas de posturas o capturas, vídeo y medición antes y después, y lo que cueste se puede bajar en Baja o Media (`data/quality.json`).

**Aceptación:** el autor ve en partida (solo y en cooperativo) cada detalle de la lista y no echa en falta nada; el rendimiento en Media no empeora más de 0,3 ms en las arenas más caras.

*Estado (29-10-2026):* plan aprobado por el autor. **Hechos los 14 hitos** (el 12.5, el 12.7, el 12.1, el 12.6, el 12.8 y el 12.2 revisados; el 12.3, el 12.4 y del 12.9 al 12.14, pendientes de su revisión). Decisiones del final de la tabla, resueltas (D-41).

| Hito | Contenido | Cómo |
|---|---|---|
| 12.1 | **Abatido y de pie** (sugerencia 3): al caer en cooperativo se arrodilla y se desploma de lado (no tendido de bruces de golpe); mientras espera, se apoya en un codo y alarga la mano hacia el compañero más cercano; al levantarlo, se incorpora apoyándose en una mano. Eliminado, se hunde como ahora | Hecho (28-10-2026), pendiente de tu revisión: `down`, `down_wait` y `get_up` en `anim_humano`; `Player._downed_visual`, `_reach` y `_get_up_step`; en red, igual (probado con dos ventanas) |
| 12.2 | **Cordura baja** (6): por debajo de un umbral, encorvado, temblor de manos y mirada que va de un lado a otro, más cuanto más baja; en la crisis (a cero), las manos a la cabeza mientras dura la parálisis | Hecho (28-10-2026), pendiente de tu revisión: `unease` y `crisis` en `anim_humano`, `Player._mind_step` con la cordura (también la de los de otros PC) |
| 12.3 | **Ropa y pelo que siguen el movimiento** (5): faldones de levita y gabardina, batas, sotana, vestidos, estola de Varga, bufanda de Dyer y trenza de Peaslee, con retraso al girar, acelerar y frenar | Hecho (28-10-2026), pendiente de tu revisión: pieza `skirt` en los personajes con faldón y en las prendas, puntas de la estola de Varga (`stole`), muelle en `Player._cloth_step` encima de la oscilación de bufanda y trenza |
| 12.4 | **Ropa que se ensucia por nivel** (7): nieve en botas y bajos en la Antártida, barro y agua en Innsmouth, verdín en R'lyeh; crece poco a poco durante el nivel y se va al empezar el siguiente | Hecho (28-10-2026), pendiente de tu revisión: `dirt.gdshader` como `next_pass`, por parte en `data/dirt.json` (y por arena si hace falta) |
| 12.5 | **Aviso con el cuerpo** (9): antes de cada ataque con aviso en el suelo, el enemigo se prepara a su manera (el pingüino baja la cabeza y escarba, el Acechador se encoge, los cultistas alzan los brazos, los Profundos echan el brazo atrás, los gigantes se agachan) | Hecho (28-10-2026), pendiente de tu revisión: `Enemy.windup`, `windup` en los scripts de animación (`Anims.windup`), desde `PatternRunner` y `GiantMoves`; en red, suceso `windup` |
| 12.6 | **Daño visible y élites** (8, 10): grietas, heridas o manchas que crecen con la vida perdida (más en élites y jefes); las élites, algo mayores, con un aura del color de su parte y los ojos encendidos | Hecho (28-10-2026), pendiente de tu revisión: grietas en una segunda pasada compartida (`wounds.gdshader`, parámetros de instancia) en élites, únicos y grandes; élites ×1,1, ojos más vivos y marca del color de la parte a sus pies (sin brillo de contorno); en Baja, sin grietas |
| 12.7 | **Muertes por familia** (11): los Profundos se derrumban y se deshacen en un charco, los fragmentos y shoggoths se derriten, los cultistas y humanos caen de rodillas y se desploman, los pingüinos caen de lado; los demás, como ahora (`Crumble`) | Hecho (28-10-2026), pendiente de tu revisión: `death` en los scripts de animación (`kneel`, `puddle`, `melt`, `fall`), caída en `Crumble` antes de deshacerse, charco en `DeathBurst`; `EnemyData.death = &"crumble"` la quita; en todas las calidades |
| 12.8 | **Jefes vivos** (12): Padre Dagon, Madre Hydra y Cthulhu respiran (pecho y branquias que laten), parpadean despacio y la cabeza y la mirada siguen al jugador más cercano | Hecho (28-10-2026), pendiente de tu revisión: capa común `Anims.alive` (por datos, `EnemyData.alive`), párpado del color de la cabeza sobre la capa de luz; sin branquias aparte (no son piezas) |
| 12.9 | **Compañeros que reaccionan** (13, 14): se esconden detrás de su jugador con un jefe cerca, celebran la subida de nivel, gimen y se quedan junto a él si cae; en cooperativo, cuando hay varios cerca se olfatean, el gato bufa al perro y el cuervo se posa en el hombro de su jugador | Hecho (28-10-2026), pendiente de tu revisión: `Pet._react`, `_react_pose` y `_perch_step`, gestos en `anim_cuadrupedo` y `anim_volador`; el hombro sale de la pieza `arm_r`, sin pivote nuevo |
| 12.10 | **Rastro de los compañeros** (15): plumas que caen de los voladores, chispas del Mi-Go, niebla del sabueso de Tíndalos, huellas del perro en la nieve | Hecho (28-10-2026), pendiente de tu revisión: `PetData.trail` (recetas `pet_*` en `VoxelFx`; en Baja, no) y huellas con `Footprints` (`PetData.prints`: patas o rastro; `Ambient._pet_prints`) |
| 12.11 | **Luz que reacciona y destrucción que se queda** (16, 17): los faroles se mecen y parpadean con las explosiones cercanas; las velas del ritual se apagan con las ondas de choque y se vuelven a encender; las cajas rotas dejan astillas en el suelo, las explosiones apartan la nieve y dejan marcas de quemado en las paredes | Hecho (29-10-2026), pendiente de tu revisión: empujón de las ráfagas a los faroles (`Ambient._blast_push`) y velas que se apagan (`Ambient._candle_step`); astillas con tope (`Debris`); nieve apartada (`snow_blast.gdshader`); hollín con una calca solo sobre el decorado (`WallScorch`, capa `ArenaBuilder.VIS_DECOR`) |
| 12.12 | **Vida al fondo y agua más viva** (18, 20): siluetas de Profundos que asoman en el agua del muelle y del arrecife, luces de barcos a lo lejos en la tormenta, el monolito de R'lyeh que palpita; en la Antártida, la aurora que ya se refleja en el mar y el hielo, más viva y con su luz en la nieve; espuma en la orilla al paso y salpicaduras al cruzar charcos | Hecho (29-10-2026), pendiente de tu revisión: Profundos que asoman (`lurkers`), luces de barcos (`ship_lights`), monolitos que laten con aro de luz y sonido (brillo `heart`), aurora más viva y con su luz en la nieve (`aurora_light`), gotas al vadear y en los charcos (mapa de charcos dibujado una vez, `Ambient.puddle_at`) y espuma en la orilla (`Ambient.is_shore`) |
| 12.13 | **El escenario cambia durante el nivel** (19): en el arrecife sube la marea, en el paso la ventisca se cierra (más niebla y nieve, menos vista), en R'lyeh el suelo se inclina poco a poco al acercarse Cthulhu | Hecho (29-10-2026), pendiente de tu revisión: curvas por tiempo de nivel (`changes`); marea que crece las pozas y frena (`tools/gen_marea.py`, `ObstacleMap.tide_level`), ventisca que se cierra con un velo alrededor de los jugadores (`Weather.set_intensity`, `whiteout.gdshader`) y cámara que se inclina (`GameCamera.tilt`, solo se ve) |
| 12.14 | **Transición del libro y retratos con estado** (21, 22): de la portada a la selección de personaje se abre un libro de la Biblioteca; el retrato del HUD lleva sangre con poca vida, la mirada perdida con poca cordura y escarcha en la Antártida | Hecho (29-10-2026), pendiente de tu revisión: la ilustración de la Biblioteca animada (`BookTransition`: aparece, pasan dos páginas, se acerca y funde; la selección llega desde negro); sombreador encima del retrato (`portrait_state.gdshader`, `Hud.portrait_state`) |

**Decisiones abiertas** (las pregunto antes del hito que las necesita):
- 12.13 (resuelta el 29-10-2026, D-41): la marea y la ventisca también cambian el juego (agua somera que frena, menos vista); la inclinación de R'lyeh solo se ve.
- 12.14 (resuelta el 29-10-2026, D-41): la ilustración de la Biblioteca (`libro.png`), animada en 2D.
- 12.3: muchas prendas (26) más los 13 cuerpos: propongo empezar por los cinco más visibles (gabardina de Legrasse, levita de Armitage, bata de Whipple, sotana de Iwanicki y vestido con estola de Varga) y enseñártelos antes de seguir.

Orden propuesto: 12.5, 12.7 y 12.1 primero (las que más se notan al jugar), luego 12.6, 12.8, 12.2, 12.3, 12.4, compañeros (12.9-12.10), escenarios (12.11-12.13) y por último 12.14.

---

## Fase 13: Calibración, modos de juego, narrativa, sonido, herramientas y distribución

Pedida por el autor el 29-10-2026 («me gustan todas, establece un plan para hacerlas»): las 22 sugerencias que le ofrecí tras la dificultad del 1 al 10 (D-42). Normas de la fase:
- **Todo lo que cambia la partida funciona también en red** (D-10): lo decide el anfitrión y viaja en GO, RESUME o en fotos y sucesos (sube `PROTOCOL` en cada hito que añada mensajes) y se prueba con dos ventanas.
- **Lo que se guarda** (pactos superados, récords, fragmentos, entradas del diario) va en `SaveData` (sube `VERSION`, con su paso en `migrate()`) y viaja a la nube con el resto del hueco.
- **Los textos son propios**, escritos al estilo de los relatos (Lovecraft es de dominio público, pero sus traducciones al español no lo son).
- **Coste:** lo que cueste se puede bajar en Baja o Media; se mide antes y después en las arenas más caras.
- **Datos antes que código:** pactos, objetivos, combinaciones, alucinaciones, fragmentos y plantillas del diario se definen en `data/`.

**Aceptación:** el autor juega cada modo y cada sistema nuevo (solo y en cooperativo), encuentra su dificultad con el informe y el historial, y tiene en la mano una build de demo y un tráiler listos para itch.io.

*Estado (29-10-2026):* plan aprobado por el autor («si, adelante»). **Hechos del 13.1 al 13.13**, pendientes de su revisión (la tabla nueva del 4 al 6, aprobada por él).

### Bloque A: calibrar (lo primero, porque ayuda a probar todo lo demás)

| Hito | Contenido | Cómo |
|---|---|---|
| 13.1 | **Informe al caer** (sugerencia 1): en la pantalla final, quién hizo más daño (enemigo y ataque), reparto por tipo (balas, contacto, cordura), vida y cordura de los últimos 60 s en una línea pequeña, vivos a la vez y características de dificultad en uso. En cooperativo, uno por jugador | Registro de golpes recibidos por jugador (quién y con qué ataque, junto al `Damage`), muestreo de vida y cordura cada segundo; panel nuevo en la pantalla final (`Menus`). En red, cada PC lo hace de sus jugadores. Se apunta también en `user://logs/dificultad.txt`. **Hecho (29-10-2026), pendiente de tu revisión:** `FallReport`, `Damage.via`/`who`, `Player.received_via`; en red, el nid del tirador en cada bala (`PROTOCOL` 12) |
| 13.2 | **Historial de dificultades** (3) y **reparto del 4 al 6** (2): cada partida apunta su resultado (superado o caída, minuto, nivel) junto a sus características; en el menú de dificultad, las últimas 10 combinaciones con su resultado, para volver a una con A. Para el salto del 4 al 5, una tabla nueva simulada con el bot que tú apruebas o descartas | Resultado al final de cada partida en el registro; lista en `DifficultyMenu`. Tablas candidatas en `Difficulty.CATS` comparadas con `tools/simular.py --dif 3..7` (8 partidas por nivel). *Nota:* la dificultad elegida ya se conserva entre sesiones (`dif_levels`); por eso la idea 3 pasa a ser un historial con resultados. **Hecho (29-10-2026), pendiente de tu revisión:** «Partidas jugadas» en el menú; niveles 5 a 10 repartidos (bot: 4 → 6/8, 5 → 2/8, 6 → 1/8; aprobado) |

### Bloque B: primeros pasos

| Hito | Contenido | Cómo |
|---|---|---|
| 13.3 | **Primer nivel guiado** (13) y **leyenda de los avisos** (14): en la primera partida de un hueco, carteles breves y saltables en el momento justo (moverse y esquivar, la primera gema, la primera subida, la cordura al bajar del 70 %, el primer baúl, compañero abatido en cooperativo). La primera vez que aparece cada tipo de aviso en el suelo, una etiqueta corta junto a él («Círculo: va a caer algo») | Guion por datos (`data/tutorial.json`: suceso que lo dispara y texto), lo visto en `SaveData`; opción «Consejos» en Configuración > Juego para volver a verlos. La etiqueta, en `Telegraph`, una sola vez por tipo y hueco. **Hecho (29-10-2026), pendiente de tu revisión:** `Tips`, `data/tutorial.json`, `Telegraph.on_shown`; «Consejos en la partida» en Configuración > Juego |

### Bloque C: jugabilidad

| Hito | Contenido | Cómo |
|---|---|---|
| 13.4 | **Alucinaciones con poca cordura** (6): por debajo del 30 %, enemigos falsos que se deshacen en niebla al tocarlos o dispararlos, gemas que no se pueden recoger y, por momentos, la barra de vida o el contador marcando lo que no es. Más frecuentes cuanto más baja la cordura | `Hallucinations` (por PC, solo visual: los falsos no entran en `CombatWorld`), tipos y frecuencias en `data/hallucinations.json`. Opción para quitarlas en Accesibilidad, junto a «Distorsión». **Hecho (29-10-2026), pendiente de tu revisión:** `Hallucinations`, `Player.hud_lie`; D-43 resuelta |
| 13.5 | **Objetivos a mitad de nivel** (5): de vez en cuando aparece uno opcional con su recompensa (oro, un baúl o experiencia): rescatar a un superviviente (llegar hasta él y escoltarlo a un punto), cortar un ritual (quedarse dentro del círculo N segundos mientras te atacan) o llevar una reliquia (cogerla frena al que la lleva). Uno o dos por nivel | Por datos (`data/objectives.json`: tipo, partes, recompensa y duración), `ObjectiveDirector` junto a `WaveDirector`, flecha en pantalla y aviso en el HUD. En red, los lleva el anfitrión (como los baúles). **Hecho (29-10-2026), pendiente de tu revisión:** `Objective`, `ObjectiveDirector`, `data/objectives.json` |
| 13.6 | **Pactos del Necronomicón** (4): antes de cada nivel, en el mapa, hasta tres maldiciones a elegir, cada una con su premio (más oro, más experiencia o mejores baúles). Ejemplos: las balas enemigas dejan un rastro que hace daño; sin curación al subir de nivel; la noche más cerrada; las élites se dividen al morir; el compañero no ayuda. Logros por superar niveles con pactos | Por datos (`data/pacts.json`), aplicados con las mismas palancas que la dificultad y los peligros; los superados, en `SaveData`. En cooperativo los elige el J1 (en red, el anfitrión) y se ven en la sala. **Hecho (29-10-2026), pendiente de tu revisión:** ocho pactos, `Pacts`, `PactMenu`, `data/pacts.json`; D-44 |
| 13.7 | **Combinaciones en cooperativo** (7): cuando el ataque de un jugador toca lo que dejó el de otro, pasa algo nuevo: fuego sobre ácido da una nube tóxica; la onda empuja las llamas; un rayo que cruza una zona arcana se divide; una explosión sobre hielo o agua levanta metralla. Unas 8 combinaciones, con un rótulo pequeño la primera vez | Tabla por rasgos de daño (`data/combos.json`), comprobada en `DamageZone`, `Beam`, `Shockwave` y `Explosion`; no cuentan como armas (no suben ni evolucionan). En red, las decide el anfitrión. **Hecho (29-10-2026), pendiente de tu revisión:** las ocho, `Combos` y `data/combos.json` |
| 13.8 | **Modo sin fin «La noche eterna»** (8): se abre al vencer a Cthulhu. Eliges arena entre las 15 y aguantas oleadas que mezclan enemigos de las tres partes, con jefes cada 5 minutos y una dificultad que sube sola. Récord de tiempo por personaje y arena | `LevelData` sin evento final y con escalada por tiempo (`data/levels/sin_fin.tres`), entrada en el menú de Jugar; récords en `SaveData`. En red, también. **Hecho (29-10-2026), pendiente de tu revisión:** `Endless`, `EndlessMenu` y `data/endless.json` |
| 13.9 | **Partida del día** (9): cada día, la misma arena, el mismo personaje, el mismo compañero y los mismos pactos para todos (salen de la fecha), y un intento que cuenta. Récord propio por día, con racha | Semilla de la fecha que elige todo y fija el azar de la partida (oleadas, baúles y subidas); récords en `SaveData` y en la nube. Sin clasificación con otros jugadores, que necesitaría un servidor (ver decisiones). **Hecho (30-10-2026), pendiente de tu revisión:** `Daily`, `DailyMenu` |

### Bloque D: ambientación y narrativa

| Hito | Contenido | Cómo |
|---|---|---|
| 13.10 | **Diario del investigador** (10): al terminar cada nivel (superado o no), una entrada en el estilo de los años veinte con lo que pasó: el peor minuto, la criatura que más le hirió, si alguien cayó y quién lo levantó, el arma que más hizo, la cordura al final. Se lee en la pantalla final y queda en la Biblioteca, por personaje | Plantillas con huecos y variantes (`data/diary.json`), rellenas con los datos del 13.1; página nueva en `LibraryMenu` con la letra de los relatos. **Hecho (30-10-2026), pendiente de tu revisión:** `Diary`, `DiaryPage`, `data/diary.json` y el tomo VII |
| 13.11 | **Fragmentos** (11) y **final según la cordura** (12): en cada nivel se puede encontrar una página suelta (brilla en el suelo; una por nivel, en un sitio al azar entre varios posibles); juntas completan relatos nuevos en la Biblioteca. Si se llega al final de Cthulhu con la cordura por debajo del 25 %, el epílogo es otro: el investigador no vuelve del todo | Páginas por datos (`data/fragments.json`), recogida como un objeto del suelo, guardadas en `SaveData`; epílogo alternativo como un relato más, elegido al cerrar la parte 3. **Hecho (30-10-2026), pendiente de tu revisión:** `Fragments`, `data/fragments.json`, epílogos en `relatos.json` y el tomo VIII |

### Bloque E: interfaz, sonido y música

| Hito | Contenido | Cómo |
|---|---|---|
| 13.12 | **Modo foto** (15): desde la pausa, cámara libre (mover, girar, acercar), sin HUD, con la partida congelada, profundidad de campo y gradación a elegir; la foto va a `Imágenes/Lovecraft Library` | `PhotoMode` (capa y cámara aparte sobre la escena en pausa), captura del viewport. En red, solo en el PC que lo abre y si la pausa es de todos. **Hecho (30-10-2026), pendiente de tu revisión:** `PhotoMode`; también viñeta, perspectiva y ocultar anillos o investigadores |
| 13.13 | **Música por capas** (16) y **avisos sonoros de lo que no se ve** (17): la pista del nivel suma una capa de percusión y otra de coros según los enemigos vivos y deja solo los coros con el jefe; las élites y los ataques fuertes que llegan desde fuera de cámara suenan por su lado (izquierda o derecha) | Capas sincronizadas en `Music` (`AudioStreamSynchronized`), volumen de cada una por intensidad; capas en `data/musica.json`. Avisos en el borde de la pantalla del lado del origen, con tope. Ver decisiones (de dónde salen las capas). **Hecho (30-10-2026), pendiente de tu revisión:** capas sintetizadas y provisionales (decisión: la recomendada), `tools/gen_capas_musica.py`, `Music.set_intensity`, `OffscreenCues` |

### Bloque F: herramientas

| Hito | Contenido | Cómo |
|---|---|---|
| 13.14 | **Capturas de comparación** (18) y **medición de los 15 niveles** (19): un comando que fotografía las 15 arenas desde los mismos puntos en Baja y en Alta y las compara con las de referencia (hoja con las diferencias marcadas); otro que mide el rendimiento de las 15 en Media y Alta y escribe una tabla con la anterior al lado | `tools/comparar_arenas.py` (capturas con `shots=`, `pos=`, `cfg_quality=`; diferencia por bloques con PIL) y `tools/medir_niveles.py` (`perf=`, dos ejecuciones por nivel, se queda con la mejor); `tools/exportar.sh` ofrece ejecutarlos antes de una build |
| 13.15 | **Builds automáticas** (20): al subir una etiqueta de versión (`v0.9.1`), GitHub Actions ejecuta los tests, genera las builds de Windows y macOS y las deja en una Release de borrador | `.github/workflows/build.yml` con Godot 4.4.1 y sus plantillas de exportación; tests con GUT sin ventana. Sin firma de macOS (como hoy). Ver decisiones (minutos de Actions) |

### Bloque G: distribución

| Hito | Contenido | Cómo |
|---|---|---|
| 13.16 | **Tráiler** (21): unos 60-75 s con escenas preparadas (portada y libro, cooperativo en la Antártida, marea del arrecife, ventisca, entrada de Padre Dagon y de Cthulhu, el diario), rótulos y música; en 1080p | Escenas con bot y opciones de prueba grabadas con `--write-movie` a 60 fps, montaje con `ffmpeg` desde un guion (`tools/trailer.py`) |
| 13.17 | **Demo de la parte 1** (22): build aparte con la Antártida y el shoggoth, el resto bloqueado con un cartel («En el juego completo»), y la página de itch.io con el tráiler | Etiqueta de exportación `demo` que limita `Campaign`; preset en `export_presets.cfg`. La subida, con tu cuenta de itch.io (hito 8.5) |

**Decisiones abiertas** (las pregunto antes del hito que las necesita, con una recomendación):
- 13.4 (resuelta el 29-10-2026, D-43: la recomendada): en cooperativo local hay una sola pantalla para todos. Propongo que los enemigos falsos los vean todos, pero que salgan junto al jugador con la cordura baja y lleven un tinte de su color, y que el HUD que miente sea solo el de su panel.
- 13.6 (resuelta el 29-10-2026, D-44: la recomendada): cuántos pactos y si se eligen también en el sin fin y en la partida del día. Propongo hasta tres, también en el sin fin, y fijos en la partida del día.
- 13.9 (resuelta el 30-10-2026, D-45: la recomendada): sin servidor no hay clasificación con otros jugadores. Propongo récords propios (en el gist de la nube) y, para comparar con amigos, un código del resultado que se pueda compartir.
- 13.11 (resuelta el 30-10-2026: la recomendada): quién escribe los fragmentos y el epílogo. Propongo escribirlos yo, al estilo de los relatos, y que tú los revises.
- 13.13 (resuelta el 30-10-2026: sintetizadas y provisionales): la música actual son pistas CC0 sin capas. Propongo sintetizar las capas de percusión y coros con `tools/gen_sfx.py` encima de cada pista (provisionales) y cambiarlas por las tuyas cuando las tengas.
- 13.15: el repositorio es público, así que Actions no cuesta nada; aun así propongo construir solo al subir una etiqueta (no en cada `push`), para no llenar la lista de ejecuciones.
- 13.17: qué entra en la demo además de la parte 1 (personajes, tienda, cooperativo, online). Propongo los cuatro personajes de inicio, la tienda y el cooperativo local, sin online.

Orden propuesto: A (13.1 y 13.2) primero, porque te sirve ya para calibrar; luego B (13.3); C, de 13.4 a 13.9; D (13.10 y 13.11); E (13.12 y 13.13); F (13.14 y 13.15), y G al final (13.16 y 13.17), cuando todo lo demás esté hecho.
