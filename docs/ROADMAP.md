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
| 1 | Prototipo jugable (*vertical slice*) | **En curso** (plan aprobado) | Ninguna (D-02, D-03, D-05, D-14, D-15 y D-16, resueltas) |
| 2 | Cooperativo local | Pendiente | Ninguna (D-03, D-07, D-16, D-17 y D-18, resueltas) |
| 3 | Pipeline de contenido | Pendiente | D-06 |
| 4 | Parte 1 completa | Pendiente | D-04, D-19 |
| 5 | Guardado local y menús | Pendiente | D-09 |
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
| 1.2 ⏸ | Modelos nuevos: `voxlib.py`, Dyer, pingüino, fragmento, atrezo del campamento y sus animaciones | Hecho, pendiente de revisión |
| 1.3 | Jugador, entrada y cámara: capa de entrada (teclado, mando, bot), movimiento, esquive, arena provisional | Pendiente |
| 1.4 | Balas, daño y armas: gestor de balas, rejilla espacial, lenguaje visual de los daños, revólver y dinamita | Pendiente |
| 1.5 | Enemigos y nivel: datos, comportamientos, oleadas por pesos, evento final del Acechador | Pendiente |
| 1.6 | Progresión, cordura y HUD: experiencia, mejoras, parálisis, HUD del J1, muerte y reinicio, pausa | Pendiente |
| 1.7 ⏸ | Rendimiento y cierre: prueba de carga, optimizaciones si hacen falta, partida de 5 minutos jugada por ti | Pendiente |

## Fase 2: Cooperativo local

- De 1 a 4 jugadores, asignación de dispositivos y conexión en caliente.
- Segundo personaje jugable, Robert Olmstead: modelo, revólver y pasivos. Cada jugador lleva a Dyer o a Olmstead y se distingue además por su color (D-18). Cómo se asigna cada personaje se concretará en el plan de la fase.
- HUD en las cuatro esquinas y cámara compartida con zoom.
- Pausas (D-16): Start y la subida de nivel pausan a todos, y en la subida cada jugador elige en su cuadrante. Ficha y mapa se abren por cuadrante sin pausar.
- Experiencia compartida (D-07).
- Reanimación.
- Sistema de cordura completo: las cinco crisis (la paranoia resta cordura a los compañeros, D-17), calmar a un compañero, recuperación cerca de compañeros y de luces, auras de presencia y locura acumulada.

**Aceptación:** 4 mandos (o 3 mandos y teclado) jugando simultáneamente sin conflictos de entrada.

## Fase 3: Pipeline de contenido

Sistema de datos para enemigos, armas, oleadas y niveles. Generador de escenarios voxel. Patrones de balas reutilizables. Comando para previsualizar cualquier enemigo con sus animaciones.

**Aceptación:** añadir un enemigo nuevo solo requiere su generador y su archivo de datos, sin tocar el código de los sistemas.

## Fase 4: Parte 1 completa (*En las montañas de la locura*)

Cinco niveles, sus diez criaturas y el shoggoth primigenio.

**Aceptación:** la parte 1 se puede completar en cooperativo.

## Fase 5: Guardado local y menús

Menú principal, selección de personaje, opciones, guardado y carga. Queda por asignar en qué fase se modelan Legrasse, Johansen, Armitage y West (GDD, sección 13).

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
