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
| 2 | Menús, guardado y cooperativo local | **En curso** (plan del 26-09-2026) | Ninguna (D-07, D-16 a D-18 y D-22 a D-25, resueltas) |
| 3 | Pipeline de contenido | Pendiente | D-06 |
| 4 | Parte 1 completa | Pendiente | D-04, D-19 |
| 5 | Arranque, relatos y ampliación de la tienda | Pendiente | Ninguna |
| 6 | Parte 2 completa | Pendiente | D-04, D-13, enfoque de jefes colosales |
| 7 | Parte 3 completa | Pendiente | Ángulos devoradores, enfoque de jefes colosales |
| 8 | Pulido y distribución | Pendiente | D-01, D-12 |
| 9 | Online | Pendiente | D-10 |
| 10 | Guardado en la nube con GitHub | Pendiente | D-11 |

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
| 2.4 ⏸ | Personajes nuevos: Olmstead, Legrasse y Johansen (modelos, datos, pasivos), escopeta y machete | Pendiente |
| 2.5 | Partida de 1 a 4 jugadores: cámara compartida con zoom, HUD en las cuatro esquinas, bots como jugadores extra | Pendiente |
| 2.6 | Reglas del cooperativo: experiencia compartida, subida de nivel por cuadrante, pausa común, escalado, reanimación | Pendiente |
| 2.7 | Cordura completa: cinco crisis, calmar, recuperación, auras, locura acumulada | Pendiente |
| 2.8 | Ficha y mapa por cuadrante, sin pausa | Pendiente |
| 2.9 | Tienda y compañeros: dinero, tres secciones, catálogo corto, dos compañeros funcionales | Pendiente |
| 2.10 ⏸ | Cierre: prueba de carga con 4 jugadores y tu prueba con varios mandos | Pendiente |

## Fase 3: Pipeline de contenido

Sistema de datos para enemigos, armas, oleadas y niveles. Generador de escenarios voxel. Patrones de balas reutilizables. Comando para previsualizar cualquier enemigo con sus animaciones.

**Aceptación:** añadir un enemigo nuevo solo requiere su generador y su archivo de datos, sin tocar el código de los sistemas.

## Fase 4: Parte 1 completa (*En las montañas de la locura*)

Cinco niveles, sus diez criaturas y el shoggoth primigenio.

**Aceptación:** la parte 1 se puede completar en cooperativo.

## Fase 5: Arranque, relatos y ampliación de la tienda

El guardado, los menús, la selección de personaje, el mapa de niveles y la tienda se adelantaron a la fase 2 (D-22). Queda:
- **Arranque:** ficha del proyecto (con qué está hecho, licencia y aviso del uso de IA) e intro que presenta el juego, antes de la portada.
- **Relatos:** al elegir un nivel en el mapa se cuenta su relato antes de jugarlo; se saltan manteniendo pulsado.
- **Tienda:** ampliar el catálogo de potenciadores y compañeros.
- Queda por asignar en qué fase se modelan Armitage y West (GDD, sección 13).

## Fase 6: Parte 2 completa (*La sombra sobre Innsmouth*)

Cinco niveles, sus diez criaturas y Padre Dagon.

## Fase 7: Parte 3 completa (*La llamada de Cthulhu*)

Cinco niveles, sus diez criaturas y Cthulhu. Decidir si los Ángulos devoradores son enemigo o peligro del escenario.

## Fase 8: Pulido y distribución

Audio, equilibrado, accesibilidad, rendimiento final y distribución.

## Fase 9: Online

Según D-10.

## Fase 10: Guardado en la nube con GitHub

Según D-11.
