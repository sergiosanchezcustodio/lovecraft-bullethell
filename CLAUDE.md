# Lovecraft Library: Surviving Cthulhu — documento de arranque

Documento de contexto del proyecto. Recoge las decisiones tomadas en la fase de exploración y el pipeline de arte que ya funciona. Es el punto de partida para cualquier sesión de trabajo (claude.ai o Claude Code).

## Documentación del juego

Léela al empezar cada sesión:
- `docs/PROMPT_juego_lovecraft.md`: especificación original del juego y reglas de trabajo por hitos (plan antes de programar, verificación visual, datos antes que código). No se modifica.
- `docs/GDD.md`: documento de diseño vivo. Recoge la especificación más las decisiones tomadas después (`D-xx`, sección 12). Si discrepa de la especificación, prevalece el GDD.
- `docs/ROADMAP.md`: fases, criterios de aceptación, estado y decisiones que bloquean cada fase.

## Estado actual

*Actualizado: 30-09-2026.*

- **Fase 2: en curso** (plan del 26-09-2026 en `docs/ROADMAP.md`). Ampliada a "Menús, guardado y cooperativo local": adelanta de la fase 5 el guardado, los menús, la selección de personaje, el mapa de niveles, la tienda y los compañeros (D-22 a D-25 en el GDD). Cuatro personajes jugables: Dyer, Olmstead, Legrasse y Johansen.
  - **Hito 2.1 (guardado y portada): hecho.**
    - La portada dice "Pulsa Start" y acepta cualquier botón principal.
    - Después, la ventana de tres huecos de partida, con tiempo jugado, objetos comprados, compañeros y dinero, y un botón de borrar con confirmación.
    - La partida suma al hueco el tiempo jugado, las partidas, las caídas, los enemigos abatidos y los niveles superados.
  - **Hito 2.2 (menú principal y configuración): hecho.**
    - Tras elegir hueco, el menú principal bajo el título: Jugar (local; online atenuado con "Próximamente"), Tienda (aviso hasta el hito 2.9), Configuración y Salir.
    - Configuración en cuatro pestañas:
      - Vídeo: pantalla completa, tamaño de la ventana, sincronización vertical, límite de FPS y resolución del 3D.
      - Audio: volumen general, de música y de efectos.
      - Controles: reasignar teclado y mando, con intercambio si la tecla estaba ocupada.
      - Juego: distorsiones, vibración y contador de FPS.
    - En la partida, "Salir" pasa a ser "Menú principal": guarda y vuelve al menú.
  - **Hito 2.3 (selección de personaje y mapa de niveles): hecho.**
    - "Jugar en local" abre la selección: cuatro marcos, uno por jugador, con el personaje en 3D, su arma, su rasgo y sus estadísticas.
    - El J1 entra con el dispositivo que usó en los menús; los demás se unen con Start (el teclado, con Intro).
    - Cada uno maneja su marco con su propio mando: personaje, compañero debajo del marco y "¡Listo!". Un personaje confirmado no lo puede coger otro ("Lo lleva J1"). B deshace un paso y, desde el primero, deja el puesto libre.
    - Con todos listos, el mapa de los 15 niveles: solo el 1 abierto, el siguiente se abre al superar el anterior y los que aún no existen salen como "Próximamente".
    - La partida usa el dispositivo, el personaje y el nivel del J1. Los demás jugadores entran en la partida en el hito 2.5.
  - **Hito 2.4 (personajes nuevos): hecho, pendiente de tu revisión.**
    - Olmstead, Legrasse y Johansen, a bloques limpios como Dyer, con su esquive, arma y rasgo.
    - Esquives: Dyer desliza, Olmstead rueda (impulso un 30 % más largo), Legrasse salta y Johansen se tira en plancha.
    - Armas nuevas: la escopeta (abanico de 5 perdigones que empuja) y el machete (tajo circular que solo golpea si hay alguien cerca).
    - Rasgos como datos (`resist_tags`, `bonus_tags` y `knockback_immune` en `CharacterData`; `tags` en `EnemyData`). Se notarán cuando lleguen criaturas marinas y humanas; en el nivel 1 no hay.
    - Hojas de revisión: `shots/revision_2_4_personajes.png` (cuatro giros) y `shots/revision_2_4_seleccion.png`.
  - **Cambios pedidos tras el hito 2.4 (26-09-2026):**
    - Balas enemigas en voxel 3D, con colores apagados por tipo de daño (físico en rojos, naranjas y amarillos; mental en morados y lilas) y más pequeñas en las criaturas de nivel bajo.
    - Horda sobre todo de cuerpo a cuerpo: tres pingüinos por cada fragmento, y los fragmentos disparan cada 9 s.
    - Arena sin vacío: barrera de hielo al norte y al oeste, meseta nevada detrás, mar visible al sur y al este, y los témpanos flotando a la altura del agua.
  - **Hito 2.4b, primera tanda (siete personajes más, D-26): hecha, pendiente de tu revisión.**
    - Amelia Peaslee (arqueóloga, rifle de caza que atraviesa), Madame Ludmila Varga (espiritista, páginas del Necronomicón que orbitan), Dra. Marian Whipple (doctora, abanico de bisturís) y Henrietta Blake (escritora, rayo del Trapezoedro).
    - Son de la tienda (`in_shop`); mientras no exista la tienda se pueden elegir. En la selección salen después de los cuatro de siempre (`order`).
    - Rasgos que ya funcionan: suerte (a veces una cuarta opción de mejora) y radio de recogida de Peaslee, cordura de las armas arcanas a la mitad (Varga), curación al subir de nivel (Whipple) y más experiencia por gema (Blake). La reanimación rápida de Whipple llegará con la reanimación (hito 2.6).
    - Hojas de revisión: `shots/revision_2_4b_personajes.png` y `shots/revision_2_4b_seleccion.png`.
  - **Hito 2.4b, segunda tanda: hecha, pendiente de tu revisión.**
    - Padre Iwanicki (fórmula de expulsión: onda dorada que empuja y aturde), sargento Frank Elwood (Colt .45 en ráfagas de tres) y Vera Malone (Thompson que barre en arco).
    - Rasgos: Elwood recibe un 15 % menos de daño físico y recarga el esquive un 20 % antes; Malone hace hasta un 50 % más de daño a quemarropa. El aura del padre (cordura a los compañeros cercanos) llegará con la cordura completa (hito 2.7).
    - Hojas de revisión: `shots/revision_2_4b_tanda2.png` y `shots/revision_2_4b_tanda2_seleccion.png`.
  - **Partida de pruebas:** el hueco 3 tiene todo desbloqueado (`SaveData.unlock_all`: personajes, compañeros, niveles y lo que se añada) y 999.999 de dinero. Se rehace con `godot --path . -- test_save=3` (sustituye lo que haya en ese hueco).
  - **Plan ampliado (27-09-2026, D-27 a D-34):** atributos, 29 armas nuevas, 4 armas y 4 objetos por personaje, personajes de inicio 2+2, dólares y tienda de antigüedades con baúles arcanos, logros, clima estético y vestuario. Hitos 2.5 a 2.16 en `docs/ROADMAP.md`.
  - **Hito 2.5 (atributos): hecho.**
    - Siete atributos (`Attributes`, `scripts/player/attributes.gd`): POD, INT, FUE, CON, TEN, DES y CUL (cultura), a 10 más un reparto de 20 puntos por personaje (`CharacterData.attr_bonus`, tabla en el GDD, 6.1).
    - La vida, la cordura, el esquive, la velocidad y el daño por tipo de arma salen de sumas de dos atributos. `Player.rebuild_stats()` lo rehace todo desde la base (atributos, estilo de esquive, pasivas y depuración).
    - Al subir de nivel, +1 en un atributo con la probabilidad del nivel 1; se anuncia en el menú de mejoras ("Nivel 3 · +1 Cultura").
    - Un arma al empezar; como mucho 4 armas y 4 objetos distintos (`PlayerProgress.weapon_slots` e `item_slots`).
    - De inicio: Dyer, Olmstead, Peaslee y Whipple. Legrasse y Johansen pasan a la tienda.
    - La selección de personaje muestra las estadísticas derivadas y los atributos.
  - **Hito 2.6 (arsenal I): hecho.**
    - Armas fusionadas (D-29), que sustituyen a las antiguas: Webly Mk VI (Olmstead), Stielhandgranate (Dyer, explota al impacto; ya lleva dos en el cinturón), escopeta de corredera (Legrasse, perdigones en anillo), rifle de palanca (Peaslee), Mauser C96 (Elwood) y Thompson M1928 (Malone).
    - Armas nuevas: Flammenwerfer (chorro en cono que deja fuego), Cóctel Molotov (charco ardiente), arpón ballenero (atraviesa y arrastra), pistola de bengalas (atrae a los enemigos; las élites no), lanzaquímicos (ácido que deja vulnerables con +25 % de daño) y cañón de fuegos artificiales (errático, se abre en chispas).
    - Sistemas nuevos: `DamageZone` (fuego y ácido), `Flare`, `FlameJet`, estados de los enemigos (`make_vulnerable`, `lure`, `stun`), balas que se dividen (`split`) y lanzados configurables (`ThrownExplosive.configure`: aspecto, arco, zona, bengala; con mecha 0 explotan al impactar).
  - **Estilo 4 de personajes (aprobado el 28-09-2026), en curso:**
    - Base común en `tools/cuerpo.py`, a 48 voxels por metro: anatomía realista de caras planas (tramos que se estrechan con chaflanes de 1 voxel, sin formas redondas ni grano por bloques, que hacían escalones y rayas), cabeza algo grande, manoplas en pinza estilo LEGO, codos y rodillas, y texturas por material (`tools/materiales.py`). `b` ensancha el tronco (0 Dyer, −2 trajes, +3 corpulentos).
    - Manos (`cuerpo.hand_`, referencia del autor del 28-09-2026): mano de voxel en reposo con el brazo caído. La palma mira al muslo; cuatro dedos de 2 voxels (el corazón más largo) separados por un borde más oscuro, que se curvan hacia la palma en la punta; pulgar delante, hacia abajo. Gruesa y tan ancha como la manga, a lo muñeco. Pegada al puño: solo asoma 1 fila de muñeca (con 3, los brazos parecían largos y la ropa pequeña). `mitten=True` junta los dedos (manoplas de Dyer). Cada personaje le da su color (piel o guante). Descartadas: la pinza LEGO en C (hacia delante, postura forzada; hacia dentro, seguía sin convencer) y dedos de 1 voxel (palillos).
    - **Cabezas redondeadas (30-09-2026, referencia del autor), aprobadas:** `cuerpo.rslab` (bloque de esquinas redondas que se encoge arriba y abajo en cuarto de círculo). `cuerpo.head` redondeada (15 de ancho; Dyer 16), nariz que asoma 1 (`fem=True`, más pequeña), ojos de 2 filas, cejas con relieve (una fila fina con pestañas), mejillas de 2×2 y barba poblada redonda. `slab` en la pieza `head` usa esquinas redondas de radio `ch + 1,5`: sombreros y pelo se redondean solos. Hoja `shots/rev_cabezas_r2.png`. Por retocar: boca de Elwood (parece abierta bajo el bigote), gesto ceñudo de Varga y Malone y gafas de Whipple poco visibles.
    - **Mujeres más femeninas (30-09-2026), aprobado:** cara de 14 y mandíbula más suave (`head(fem=True)`), labios (`lips`) y peinados distintos con `long_hair` (melena por la espalda, ondas opcionales y mechones): Peaslee con fedora estilo aventurero (sustituye al salacot) y trenza larga, Whipple con moño alto, Blake con melena ondulada, Varga con melena lisa larga y Malone con moño bajo. Hoja `shots/rev_mujeres_f1.png`.
    - Alas de sombrero: como mucho 2,5 voxels por delante y con el borde a la altura 78 o más; los ojos van en 72-75. A los lados pueden asomar más (casco Brodie).
    - **Primera tanda (hombres) hecha, pendiente de tu revisión:** Dyer, Olmstead, Legrasse, Johansen, Elwood e Iwanicki. Hojas `shots/revision_estilo4_tanda1a.png` y `tanda1b.png`.
    - **Segunda tanda (mujeres) hecha, pendiente de tu revisión (29-09-2026):** cuerpo de mujer en `cuerpo.py` (`torso_f`, `legs_f`, `shoes_f`, `boots(slim=True)`, `arms(ax=ARM_X_F, slim=True)`, `bob`; mismas alturas y articulaciones que el hombre). Peaslee, Whipple, Blake, Varga y Malone rehechos. Hojas `shots/rev_tanda2_v2.png`, `rev_whipple_v2.png` y `rev_peaslee_v2.png`. `tools/humano.py` ya no lo usa nadie.
    - Comprobadas al andar, en sus esquives, en la selección y en la partida. Arreglado de paso: bajo una falda o una sotana el muslo se queda sin voxels y el modelo perdía la pieza `leg_l`/`leg_r`, así que la animación fallaba (Varga, Whipple, Blake e Iwanicki no andaban). `VoxelBuilder.load_model` crea vacío el padre sin voxels para que la espinilla siga colgando de él.
    - **Esquive de deslizamiento rehecho como entrada en plancha de fútbol** (`slide` en `anim_humano.gd`): gira sobre la cadera y queda casi tumbado, con la pierna delantera estirada a ras de suelo, la otra doblada debajo, la mano atrás en la nieve y el brazo alto. Pendiente de tu revisión (`shots/revision_esquive_plancha.png`).
    - Descartados: `gen_dyer_chibi.py` (demasiado a bloques) y `gen_dyer_v3.py` (formas redondas: escalones sueltos).
    - Ya en el juego: codos y rodillas en los 11, bufanda de Dyer y coleta de Peaslee; manos en pinza en los 5 que faltan por pasar; los personajes no se hunden en el suelo al esquivar (`Player._keep_above_ground`).
    - El autor tenía más cambios que quería hacer antes del hito 2.7: preguntárselos.
  - **Un rasgo por personaje (D-35, 29-09-2026): hecho.** Dyer, explosiones +25 % de radio (`explosion_radius_mult`); Olmstead, esquive largo; Peaslee, suerte; Whipple, reanima antes (llega con la reanimación); Elwood, −15 % de daño físico; Johansen, +25 % cuerpo a cuerpo (`melee_mult`); Iwanicki, aura de cordura a sí mismo y a los cercanos (`calm_aura`, radio `Player.CALM_RADIUS`). Un test comprueba que nadie tenga más de uno.
  - **Selección de personaje rehecha como ficha, pendiente de tu revisión** (`shots/seleccion_ficha2_001.5s.png`): modelo al doble de la escala de la partida (144 px/m, `MODEL_ZOOM`), arma arriba a la derecha, rol y rasgo, y dos columnas con iconos (diseño del autor, `resources/PantallasMenus/seleccion_jugador_info_personaje.png`, marco de 420×750): los siete atributos con su abreviatura y puntos de vida, de cordura, acción de esquiva, velocidad y ataques mágicos, físicos y balísticos con su nombre. Cada texto va en una casilla fija (`_slot`): el nombre y la descripción reducen la letra para caber en una línea (`_fit_line`) y el rasgo tiene sitio para dos, así que las tablas no se mueven al cambiar de personaje. Vida y cordura en valor absoluto; esquive, velocidad y daños como potenciador (+20 %). El recuadro del arma enseña `WeaponData.icon` (hueco "Arma" mientras no haya imagen; nombre y `description` en la descripción emergente). Descripciones emergentes con `TipIcon` (`scripts/ui/tip_icon.gd`): aparecen a los 0,45 s con el ratón encima, con el foco o marcadas con arriba/abajo en la selección (`cursor=N` para capturas); úsalo en todo icono de armas, objetos, atributos y estadísticas. Iconos recortados de tus dos láminas en `resources/PantallasMenus/iconos/ficha_*.png` (con prefijo: `CON` es un nombre reservado en Windows y Godot no lo abre).
  - **Compañero en la selección (30-09-2026), pendiente de tu revisión:** recuadro bajo cada marco según el boceto del autor: "Elige compañero", `◀ nombre ▶` y el modelo en 3D con su animación de reposo, balanceándose. LB/RB (Q/E) giran el compañero mientras se elige y el personaje en su paso. Visor común `CharacterSelect._Preview`; los compañeros, todos a la misma escala (`PET_PX_PER_M`, 160 px/m: proporcionados entre sí). Recuadro "J1" arriba a la izquierda, simétrico al del arma (sin el nombre del mando). El estado ("A: elegir", "Lo lleva J2") va al pie del recuadro del compañero; marcos de 420×684. Capturas: `select ... join=N pets=N` (los N primeros eligiendo compañero, uno distinto cada uno). Tienda: lo comprado ya no se atenúa, solo dice "Comprado" en verde.
  - **Hito 2.7 (arsenal II, mágicas): hecho, pendiente de tu revisión (29-09-2026).** Las 17 armas que faltaban de D-29 las propuse yo y están en el GDD, 5.3 (12 de fuego, 11 físicas y 11 mágicas en total). Las 8 mágicas:
    - Signo Arcano (`Sigil`): signo en el suelo que daña, empuja y frena las balas enemigas (`BulletManager.slow_enemy_bullets`). Resonador de Tillinghast: onda (`Shockwave.clears`) que deshace balas (`clear_enemy_bullets`). Son las dos únicas que tocan balas (D-29).
    - Báculo del Farolero: balas teledirigidas (`WeaponData.homing`, estilo `WISP`). Rayo de Yith: estasis al impactar (`Effect.STASIS`, estilo `YITH`): el enemigo congelado guarda el daño y lo recibe ×1,5 al final.
    - Lente del Éter (`TetherBeam`): rayo sostenido cuyo daño crece sobre el mismo enemigo (`ramp`, `ramp_max`). Polvo de Ibn-Ghazi: zona `DUST` que ralentiza (`Enemy.slow`) y debilita (`Enemy.weaken`, también sus balas con `PatternRunner.damage_mult`).
    - Orbe Mi-Go (`MiGoDrones`): orbes que vuelan y disparan solos. Daga ritual: puñalada (`Stab`) que maldice (`Enemy.curse`); al morir maldito, la maldición salta (`CurseJump`).
    - Todas cuestan cordura, también las de balas. Tests en `tests/test_arsenal2.gd`. Hoja `shots/revision_2_7_magicas.png`.
  - **Hito 2.7b (arsenal II, fuego y físicas): hecho, pendiente de tu revisión (29-09-2026).** Quedan 34 armas: 11 físicas, 12 de fuego y 11 mágicas (lo comprueba un test).
    - Bobina Tesla (`CHAIN`, `ChainBolt`): salta hasta `count` enemigos, un 15 % menos cada salto. Springfield: apunta con `STRONGEST` (`CombatWorld.strongest_enemy`: élite o más vida) y hace críticos (`crit_chance`, `crit_mult`).
    - Ametralladora Lewis (`TURRET`, `Turret`): torreta en trípode que dispara sola. Lugers (`FRONT_BACK`): delante y detrás a la vez.
    - Inyector de West: bala con `Effect.INJECT`; el que muere inyectado se levanta como aliado (`Reanimated`, tinte verde) y ataca a los suyos.
    - Bumerán (`BOOMERANG`, `Boomerang`): ida y vuelta. Red de pesca: lanzado con `ThrownExplosive.net`, inmoviliza (`Enemy.root`; las élites solo se frenan) y deja la red en el suelo (`NetFx`).
    - Martillo de geólogo (`FISSURE`, `Fissure`): grieta que avanza con esquirlas de hielo y aturde. Bastón estoque (`THRUST`): estocada en línea; cuenta como cuerpo a cuerpo para el rasgo de Johansen.
    - Tests en `tests/test_arsenal3.gd`. Hoja `shots/revision_2_7b_fuego_fisicas.png`.
  - **Hito 2.8 (clima estético, D-33): hecho, pendiente de tu revisión (29-09-2026).**
    - `WeatherData` (`data/weather/*.tres`): viento con rachas sin azar (`wind_at`), precipitación (nieve, ceniza con brasas o lluvia con salpicaduras), ventisca a ras de suelo, niebla baja, sombras de nubes y rayos. Cada nivel elige el suyo (`LevelData.weather`); el nivel 1 tiene la nevada.
    - `Weather` (`scripts/fx/weather.gd`) lo monta y lo lleva con la cámara: partículas en coordenadas del mundo, dos capas de niebla (`weather_mist.gdshader`, fundida con la profundidad) y sombras de nubes (`weather_clouds.gdshader`, mezcla multiplicativa). El rayo es un destello contenido de una luz direccional y de la ambiental (`FLASH_LIGHT`, `FLASH_AMBIENT`): con más, sobre la nieve la noche parecía de día.
    - Climas de muestra: nevada, ventisca, ceniza, lluvia, tormenta y niebla densa. `weather=<id>` o `weather=no` al arrancar; el menú de depuración lo cambia en partida. Configuración > Juego > Clima: apagado, reducido (mitad de partículas) o completo.
    - Sin coste medible: 120 FPS (el tope) con y sin ventisca o tormenta. Tests en `tests/test_weather.gd`. Hoja `shots/revision_2_8_clima.png`.
  - **Hito 2.9 (partida de 1 a 4 jugadores): hecho, pendiente de tu prueba con varios mandos (29-09-2026).**
    - `game.gd` crea un jugador por puesto de la selección (`GameSession.seats`), cada uno con su entrada, su personaje, sus armas y su progreso. `player` sigue siendo el J1 (depuración y opciones de prueba); `players` los lleva a todos. Lanzando la partida directa, `bots=N` añade jugadores de compañía (`bot_chars=` elige sus personajes).
    - Bots: `BotInput` con el patrón `follow` (va hacia el J1 y lo rodea a su aire, esquiva de vez en cuando) y eligen sus mejoras solos.
    - Cámara compartida (`GameCamera`): abre el zoom para que quepan todos (`needed_size`, de `view_size` a `max_view_size` = 24 m) y sigue a los que están en pie. La correa (`Player.leash` → `GameCamera.leash`) no deja que nadie se salga del encuadre máximo.
    - HUD: un `Hud.PlayerPanel` por jugador en su esquina (J1 arriba a la izquierda, J2 arriba a la derecha, J3 abajo a la izquierda, J4 abajo a la derecha), con "J1…J4" en su color. Si cae, el panel se apaga y dice "Caído".
    - Si cae un jugador, la partida sigue ("J2 ha caído"); se acaba cuando caen todos ("Habéis caído", con el nivel de cada uno). Las subidas de nivel se atienden por orden; el menú por cuadrante sin pausar a los demás, la experiencia compartida y la reanimación son del hito 2.10.
    - Tests en `tests/test_coop.gd`. Prueba: `godot --path . -- bots=3`.
  - **Hito 2.10 (reglas del cooperativo): hecho, pendiente de tu prueba con varios mandos (29-09-2026).**
    - Experiencia compartida (D-07, `TeamXp`): la gema que recoge cualquiera cuenta para todos, suben a la vez y la curva se alarga (`ProgressionData.coop_xp_scale`: ×1,5, ×1,9, ×2,3 con 2, 3 y 4).
    - Subida de nivel por cuadrante (D-16, `CoopLevelUp`): pausa para todos y cada uno elige a la vez en su cuadrante con su mando (arriba/abajo y A o Intro); los bots eligen solos. En solitario, el menú de siempre.
    - Dificultad según los jugadores (`LevelData.coop_health` y `coop_spawn`, `LevelData.coop()`): vida de los enemigos y ritmo y tope de aparición.
    - Reanimación (GDD 4.6): en cooperativo, con la vida a cero queda derribado 30 s (`Player.revivable`, `down_left`); un compañero a menos de 1,5 m lo levanta en 3 s (Whipple, 1,5 veces más rápido) con el 35 % de la vida. Si nadie llega, queda eliminado hasta el siguiente nivel. Tendido de bruces con un anillo en el suelo (`revive_ring.gdshader`: rojo, el tiempo que le queda; verde, la reanimación) y su estado en el panel del HUD. Los bots acuden a reanimar. La partida se acaba cuando no queda nadie en pie.
    - Tests en `tests/test_coop_rules.gd`. Prueba: `godot --path . -- bots=3` (con el J1 a mano, el menú por cuadrantes espera a que elijas).
  - **Hito 2.11 (cordura completa): hecho, pendiente de tu revisión (29-09-2026).**
    - Cinco crisis (`SanityState`), al azar con pesos (`ProgressionData.crisis_weights`; un personaje puede tener los suyos, `CharacterData.crisis_weights`): parálisis, huida histérica (corre lejos del horror, sin esquive), vagar sin rumbo (errático y lento, obedece un 35 %), delirio (controles invertidos) y paranoia, solo en cooperativo: sus armas de balas apuntan al compañero más cercano y le quitan 2 de cordura por bala, nunca vida (`Effect.PARANOIA`, D-17).
    - Calmar: un compañero a menos de 1,5 m que no esté en crisis la acorta (`calm_rate`, con su `revive_speed`). Recuperación ×2 junto a un farol (`Player.lights`, de la arena) y ×1,5 junto a un compañero.
    - Presencia: `EnemyData.aura_radius` y `aura_drain`; el Acechador drena 2,5 de cordura por segundo a 4,5 m, con un disco violeta que late.
    - Locura acumulada (configuración > Juego, activada por defecto): cada crisis quita un 10 % de cordura máxima, sin bajar del 50 %.
    - Distorsiones de cordura baja (`SanityFx`): borde violeta que palpita desde el 35 % de cordura y, en solitario, hasta un 40 % de desaturación; en cooperativo, el borde sale de la esquina de cada jugador. La opción "Distorsiones" de la configuración ya las regula (antes no hacía nada).
    - Arreglada una fuga del hito 2.10: el equipo y el progreso se referenciaban mutuamente y no se liberaban ni al reiniciar (ahora `PlayerProgress.team` es una referencia débil).
    - Tests en `tests/test_sanity2.gd`.
  - **Hito 2.12 (ficha y mapa por cuadrante): hecho, pendiente de tu revisión (29-09-2026).**
    - `PlayerMenus` (`scripts/ui/player_menus.gd`): Select/Tab abre la ficha, cruceta abajo/M el mapa, B/Esc los cierra. En solitario, centrados y con la partida en pausa (Esc cierra antes de abrir la pausa); en cooperativo, en el cuadrante del jugador, semitransparentes y sin pausar: el personaje sigue controlable (D-16). Se ocultan mientras la partida está en pausa por otra cosa.
    - Ficha (`PlayerMenus.Sheet`), tres páginas con LB/RB o Q/E (acciones nuevas `page_prev` y `page_next`, reasignables): personaje (rasgo, atributos con lo ganado desde el nivel 1, vida y cordura actuales y potenciadores, crisis sufridas), armas (nivel, grupo, descripción y siguiente mejora, huecos ocupados) y objetos.
    - Mapa (`PlayerMenus.ArenaMap`): la arena en rombo, orientada como la cámara, con obstáculos, faroles, jugadores (el propio con un aro), enemigos (élites en violeta) y el enemigo del evento final.
    - Las 17 armas del arsenal I tenían la descripción vacía; ahora la llevan (un test lo comprueba).
    - Capturas: `panel=sheet|map panel_player=N panel_page=N panel_at=s`. Tests en `tests/test_player_menus.gd`.
  - **Hito 2.13 partido en cuatro (plan aprobado el 29-09-2026):** 2.13a economía, 2.13b tienda, 2.13c compañeros y 2.13d tienda de antigüedades con el anciano. Detalle en `docs/ROADMAP.md`.
  - **Hito 2.13a (economía): hecho, pendiente de tu revisión.**
    - Dólares por enemigo (`EnemyData.money`: pingüino 1, fragmento 2, Acechador 25), bono por nivel (`LevelData.money_bonus`, 100) y baúles arcanos (`ArcaneChest`, `WaveDirector._chest_step`): uno cada ~90 s a 6-12 m de un jugador, como mucho dos cerrados; al tocarlo da 20-60 $ y un 15 % de vida y cordura a quien lo abre. Sin ruletas.
    - `game.earn()` suma al momento a la partida guardada (se conserva aunque se caiga) y a `stats["money"]`; el HUD muestra los dólares de la partida bajo el objetivo, el resumen final los ganados y el mapa los baúles.
    - Calibración: una partida del nivel 1 con bot da unos 500 $ en ~270 s (290 abatidos); a ~5.500 $/h, la tienda planeada (~55.000 $) son unas 10 horas. `log=true` imprime "NIVEL SUPERADO t=… abatidos=… dólares=…".
    - `chest_every=N` saca baúles más a menudo (capturas). Tests en `tests/test_economy.gd`.
  - **Hito 2.13b (tienda): hecho, pendiente de tu revisión.**
    - `Shop` (`scripts/save/shop.gd`, sin interfaz y con tests) reúne el catálogo: potenciadores y mejoras en `data/shop/*.tres` (`ShopItem`), personajes con `in_shop` y su `price`, y compañeros en `data/pets/*.tres` (`PetData`). Compra, niveles y efectos (`Shop.bonuses`).
    - Catálogo (~58.000 $, unas 10 h): Vitalidad (+4 % de vida), Temple (+4 % de cordura), Puntería (+3 % de daño), Agilidad (+2 % de velocidad) y Codicia (+5 % de dólares), a 150/300/600/1.000/1.500 $ por nivel; Legrasse y Johansen 1.500 $, Varga y Blake 3.000 $, Elwood e Iwanicki 4.500 $, Malone 6.000 $; perro de trineo de Lake 2.500 $ y gato de Ulthar 4.000 $ (sin modelo ni comportamiento hasta el 2.13c); quinta funda y quinto bolsillo 5.000 $.
    - `ShopMenu` desde el menú principal: pestañas Potenciadores, Personajes, Compañeros y Mejoras (LB/RB o Q/E), nivel en puntos, precio del siguiente (atenuado si no llega) y compra con confirmación; guarda al momento. Fondo provisional hasta el 2.13d. Capturas: `title saves=… open=menu_tienda tab=N shots=14`.
    - En partida: `Player.shop` multiplica vida, cordura, velocidad y daño; los huecos suman a `weapon_slots` e `item_slots`; Codicia, a `game.money_mult`.
    - El dinero se muestra en dólares en todos los menús.
  - **Hito 2.13c (compañeros): hecho, pendiente de tu revisión.**
    - Modelos estilo 4 a 48 voxels/m: `tools/gen_perro.py` (husky gris y blanco con antifaz, ojos claros, arnés rojo y rabo enroscado) y `tools/gen_gato.py` (atigrado naranja con "M" en la frente, ojos verdes, calcetines blancos y rabo anillado). Animaciones en `anim_cuadrupedo.gd` (idle, walk, run, bite). Hoja `shots/rev_mascotas_v2.png`.
    - `Pet` (`scripts/pets/pet.gd`): sigue a su jugador (se da prisa si se aleja; si se queda muy atrás, aparece a su lado) con un anillo fino de su color. Perro (`PetData.Kind.BITE`): corre a morder a los enemigos a menos de 5,5 m de su jugador, 9 + 2 por nivel del jugador. Gato (`WARD`): `Player.mental_resist` quita un 20 % del daño mental (+1 % por nivel, hasta 35 %), también el de las auras.
    - En partida sale el compañero de cada puesto de la selección (`GameSession.Seat.pet`); lanzando directo, `pet=perro|gato` para el J1.
    - Tests en `tests/test_pets.gd`.
  - **Arreglos de mando en los menús e imágenes en la tienda (29-09-2026):**
    - Las ventanas encima (confirmación, tienda, configuración) dejaban que el foco saltara a los botones de detrás: la cruceta no pasaba de "Cancelar" a "Comprar" y en la tienda, al bajar del último artículo, se iba al menú principal. `MenuKit.trap_focus(ventana)` deja sin foco lo de detrás mientras está abierta (lo usan `Confirm` y `MainMenu._push`); `MenuKit.chain_focus(filas)` encadena una lista para que no salga por los extremos. Tests en `tests/test_menu_focus.gd` (con eventos de mando simulados).
    - Cada artículo de la tienda lleva su imagen: los iconos de la ficha para Vitalidad, Temple, Puntería y Agilidad (`ShopItem.icon`); el retrato del modelo para los personajes y el modelo entero para los compañeros (`ModelIcon`, `scripts/ui/model_icon.gd`); y tres iconos en voxel nuevos para Codicia, la quinta funda y el quinto bolsillo (`tools/gen_iconos_tienda.py`, `ShopItem.icon_model`).
  - **Hito 2.13d (tienda de antigüedades): hecho, pendiente de tu revisión.**
    - El anciano (`tools/gen_anciano.py`, estilo 4): gorro de fumar de terciopelo con borla dorada, gafas redondas de montura dorada, barba larga y blanca, camisa azul pálido con ligas, pajarita y chaleco granate con leontina. Sin el gorro, la calva salía gris con la luz fría de arriba. Hoja `shots/rev_anciano_v3.png`.
    - La tienda (`tools/gen_tienda_antiguedades.py`, 32 voxels/m, ~166.000 voxels): suelo de tablas, zócalo y papel pintado verde con rombos tenues, dos estanterías con libros, calaveras, frascos que brillan, un ídolo verde y velas, cuadro de un mar tormentoso, reloj de pie, alfombra y mostrador con quinqué, bola de cristal, libro de cuentas, campanilla y monedas. Con la caché de mallas carga en ~10 ms.
    - **Fondo de la tienda: tu ilustración** (`resources/PantallasMenus/tienda.png`, reescalada ×2 a 3344 × 1882 con un reescalador, fiel a la original, que se guarda como `tienda_original.png`; con mipmaps). ChatGPT no reescala: vuelve a generar la imagen y como mucho a 1536 × 1024. `ShopBackdrop` la muestra cubriendo la pantalla y la anima como la portada (`shop_art.gdshader` con `mascara_tienda.png`, de `tools/gen_mascaras_tienda.py`): el quinqué y las velas titilan con su luz (lista `FLAMES` revisada a mano: la detección sola marcaba el libro abierto y el borde del mostrador), la bola de cristal y los frascos laten, y flota polvo en la luz del quinqué. **Si cambia la ilustración, vuelve a ejecutar el script y revisa `FLAMES`.**
    - El diorama en voxel (tienda y anciano) queda en el proyecto sin usar (`ShopBackdrop.voxel_scene()`). La ventana de la tienda va a la derecha (`anchor_left` 0,47) sin oscurecer el fondo.
  - **Hito 2.14 (logros y desbloqueos, D-32): hecho, pendiente de tu revisión (29-09-2026).**
    - Logros como datos (`AchievementData`, `data/achievements/*.tres`): estadística que miran, objetivo, recompensa (dólares, personaje o compañero) e imagen (icono de la ficha o modelo renderizado). `Achievements` (`scripts/save/achievements.gd`, sin interfaz) calcula el progreso, apunta los cumplidos en `SaveData.achievements` (id -> fecha) y paga una sola vez.
    - 18 logros: primera partida; 100, 1.000 y 10.000 abatidos; superar el nivel 1 (desbloquea a Legrasse); 1 y 25 élites; 1 y 50 baúles; 10 crisis; 10 reanimaciones (desbloquea a Johansen); partida en cooperativo; nivel 20; aguantar 5 minutos; un arma al nivel 5; 10.000 $ ganados; 7 investigadores; y superar un nivel sin que nadie caiga (el gato de Ulthar te adopta). Los personajes y el gato siguen también en la tienda (D-30, D-31).
    - Estadísticas nuevas en `SaveData.stats`: elites, chests, crises, revives, coop_runs, best_level, best_time, maxed_weapons, flawless, money. La partida las suma (`Achievements.add` y `record`) y comprueba cada segundo y al acabar; los nuevos se anuncian ("Logro: … · recompensa"; con `log=true`, "LOGRO id").
    - Menú principal: Jugar, Tienda, **Logros**, Configuración y Salir. `AchievementsMenu`: lista con imagen, recompensa y progreso (o "Conseguido" y la fecha). Capturas: `title saves=… open=menu_logros`. Tests en `tests/test_achievements.gd`.
  - **Iconos de las armas con Replicate (29-09-2026):** `tools/generar_iconos_armas.py` (sin dependencias) genera cada icono con FLUX 1.1 Pro (~0,04 $), quita el fondo con `851-labs/background-remover` y lo deja en `resources/weapons/icons/<id>.png` a 256 × 256 (en bruto, en `raw/`). `WeaponData.get_icon()` lo usa si el arma no tiene `icon`; salen en la selección, en la ficha (página de armas) y en el HUD (icono con el nivel; sin icono, el nombre). Las 34 armas tienen icono, en estilo voxel 3D (render tipo MagicaVoxel). Aprobados en general (30-09-2026); más adelante se afinarán algunos (candidatos: bengalas, bisturís y lanzallamas) con `python tools/generar_iconos_armas.py <arma> --rehacer`.
    - El token está en `.env` (ignorado por git), copiado del de Extremadura Survivors. Cloudflare rechaza el User-Agent por defecto de urllib (403, "error code 1010"): el script manda uno propio. Con menos de 5 $ de crédito, la cuenta admite 6 predicciones por minuto: el script espera y reintenta.
    - No usar el icono del revólver como `image_prompt`: el modelo copiaba el revólver en todas las armas.
  - **Panel del jugador rehecho (30-09-2026, diseño del autor), pendiente de tu revisión:** `Hud.PlayerPanel` en posiciones fijas, al 60 % del primer tamaño (272×132; la experiencia, centrada entre la cabeza y el borde): "J1" y "Nv. 24" arriba a la izquierda, la cabeza (`portrait_texture`) y debajo la experiencia en 10 casillas en relieve (`Hud.LevelCells`); a la derecha el nombre, las barras de vida, cordura y esquive con los iconos de la ficha (16 px), la fila de armas y la de objetos (casillas de 36×32: caben 5), con su nivel en la esquina. Ya no muestra "Vida 113". Hoja `shots/revision_hud_panel.png`.
  - **Límites y obstáculos por voxels reales (30-09-2026), pendiente de tu revisión:** `tools/gen_mapa_transitable.py` (lo llama `gen_arena_campamento.py`) marca en una rejilla de 25 cm lo que ocupa cada pieza a la altura de un cuerpo y a la de las balas, el suelo (llano y lo alto de la costa) y lo que se alcanza andando; las huellas de cada pieza se cierran y rellenan (nadie se mete en el iglú). Sale `data/arenas/campamento_mapa.bin` (andar, balas y distancia a lo bloqueado) y la clave `mask` del JSON; también los tramos de la barrera (`barrier.placements`). `ObstacleMap.load_mask`: `is_blocked`, `push_out` (sube por la distancia; si está dentro, busca la celda libre más cercana) y `stops_bullet`. Lo usan enemigos, jugadores (tras `move_and_slide`), mascotas de suelo y balas de los dos bandos (`CombatWorld.obstacles`). Con mapa ya no hay muros invisibles ni cuerpos físicos del decorado. Se llega al frente de los acantilados y al borde de la costa dibujada. **Si cambia la arena, vuelve a ejecutar `gen_arena_campamento.py`.** Vista previa: `shots/campamento_mapa.png`.
  - **Suelo del nivel 1 a la resolución de los modelos (30-09-2026), pendiente de tu revisión:** `snow_ground.gdshader` con celdas de 1/32 m (antes 12,5 cm), escalones sombreados como los voxels (canto claro arriba a la izquierda, oscuro abajo a la derecha), grano fino, algún destello y manchas calculadas por celda. Mismo rendimiento (~100 FPS de media con 150 enemigos y 1.200 balas). Comparativa `shots/revision_suelo_antes_despues.png`.
  - **Esquive de deslizamiento más tumbado:** unos 76° y más cerca del suelo, con fase de levantarse; dura 0,5 s. `Player._keep_above_ground` usa vértices reales de cada pieza (`Player._extremes`, 98 direcciones) en vez de las esquinas de su caja, que lo levantaban de más.
  - **Icono y ejecutable de Windows (30-09-2026):** `icono_juego.png` (icono de la ventana) e `icono_windows.ico` (16 a 256 px, para el `.exe`), hechos a partir de `winbdows_icon_big.png`. `export_presets.cfg` ("Windows Desktop", un solo `.exe` con todo dentro, ~206 MB). Plantillas 4.4.1 de Windows x86_64 en `%APPDATA%/Godot/export_templates/4.4.1.stable` y `rcedit` en `C:/Tools/Godot/rcedit.exe` (configurado en el editor). Exportar: `godot --headless --path . --export-release "Windows Desktop" builds/windows/LovecraftLibrary.exe` (`builds/` no va a git). La primera partida del `.exe` construye la caché de mallas (unos segundos).
  - **Proyectiles que heredan la velocidad del jugador (30-09-2026), pendiente de tu prueba:** `WeaponSystem.inherited_speed(dir)`: la parte del movimiento del jugador en la dirección del disparo (nunca hacia atrás; como mucho su velocidad al andar, para que el esquive no dispare las balas). La suman las balas (mismo alcance: solo salen más rápido), el bumerán y la grieta del martillo; los lanzados acortan el vuelo si corre hacia donde lanza (`flight = distancia / (1,8 × heredada)`, mínimo 0,25 s). Tests en `tests/test_weapon_inherit.gd`.
  - **Exportación a macOS (30-09-2026), sin probar en un Mac:** perfil "macOS" en `export_presets.cfg`: `.zip` con la `.app` universal (Apple Silicon e Intel, macOS 11+ en ARM), firma ad-hoc de Godot (sin cuenta de Apple Developer ni notarización: la primera vez hay que abrirla con clic derecho → Abrir, o `xattr -cr` en el Terminal) y texturas ETC2/ASTC (`rendering/textures/vram_compression/import_etc2_astc`). Exportar: `godot --headless --path . --export-release "macOS" builds/macos/LovecraftLibrary.zip` (~117 MB). La `.app` se llama como `config/name` ("Lovecraft Bullet Hell"): cambiarlo movería la carpeta de partidas guardadas.
  - **Iconos de los objetos con Replicate (30-09-2026), pendientes de tu revisión:** `tools/generar_iconos_objetos.py` (usa las funciones y el estilo de `generar_iconos_armas.py`) genera los 12: potenciadores y mejoras de la tienda (vitalidad, temple, puntería, agilidad, codicia, quinta funda, quinto bolsillo) y objetos de la subida de nivel (diario, brújula, piolet, botas, abrigo), en `resources/items/icons/<id>.png`. Sustituyen a los iconos de la ficha y a los modelos `icono_*` que se reutilizaban. Hoja `shots/revision_iconos_objetos.png`. Codicia: el filtro rechazó "billetes" (falso positivo); ahora es un monedero con monedas.
  - **Escenario del nivel 1 rehecho (30-09-2026), aprobado:**
    - Luz propia de la arena (JSON "light", `ArenaBuilder.apply_light`): crepúsculo polar, sol bajo y cálido. El clima parte de esa luz (`game._base_fog`, `_base_ambient`); antes la niebla antigua lo lavaba todo. Niebla general a 0: con la cámara isométrica lejos, tapaba la mitad del color.
    - Suelo `snow_ground.gdshader`: celdas de 12,5 cm con relieve en escalones (ventisqueros y sastrugi), placas de hielo y nieve pisada. Mar `sea.gdshader`: celdas de 12,5 cm, olas en escalones, rizos, hielo menudo que deriva y espuma. El mar está a −1 m.
    - Costa (`tools/gen_costa_hielo.py`): frente de la plataforma, témpanos de cinco tamaños, icebergs y montículos de hielo en tierra (sustituyen a las rocas).
    - Atrezo a 48 voxels/m (`tools/gen_atrezo_expedicion.py`): tienda de lona, caja, barril, trineo, trípode y bandera. `gen_atrezo_campamento.py` ya no genera tienda, caja ni bidón.
    - `"no_bottom": true` en el JSON del atrezo fijo: `VoxelBuilder` no construye las caras hacia abajo (`BUILDER_VERSION` 4). Mantiene el rendimiento (115 FPS con 150 enemigos).
    - Cabaña, iglú y farol rehechos en `gen_atrezo_expedicion.py`; barrera en seracs con bloques caídos (`gen_barrera_hielo.py`). `"no_shadow"` en el JSON de la arena: la costa, los témpanos y los icebergs no proyectan sombra (caería sobre el agua).
    - Rendimiento con 150 enemigos y 1.200 balas: 88 FPS de media (102 antes del escenario nuevo); el 1 % peor igual (~60). Sobra geometría (8 M de primitivas): si hace falta, bajar la resolución de la tienda y la cabaña o unir caras en `VoxelBuilder`.
  - **Subida de nivel con mando arreglada (30-09-2026):** la misma ventana (`CoopLevelUp`) en solitario (centrada, `solo=true`) y en cooperativo. La cruceta abajo es también `MAP` y `JoypadInput` no la da como movimiento: `CoopLevelUp.nav_dir` la lee aparte. Repite al mantener; solo confirmar espera 0,35 s. Tarjetas con la imagen del arma (`get_icon()`) o del objeto (`UpgradeData.icon`, generados con Replicate). `Menus.LevelUpMenu` ya no se usa. Tests en `tests/test_level_up_input.gd`.
  - **Hito 2.15 (bestiario de compañeros, D-36), en tres tandas.** El vestuario pasa a 2.16 y el cierre a 2.17.
    - **2.15a hecha, pendiente de tu revisión (30-09-2026):** comportamientos intercambiables (`PetBehavior.make(kind)`, `scripts/pets/behaviors/`); `Pet` solo sigue, vuela (`PetData.fly_height`), anima y saca avisos flotantes (`popup`). Datos genéricos en `PetData`: `attack_*` y `bonus*` (`attack_at`, `bonus_at` por nivel).
      - Gato de Ulthar rehecho en negro (`CLAW`, `PetHunt`): zarpazo en área; si hieren a su jugador se eriza 5 s (doble de rápido, +50 %). Ya no quita daño mental.
      - Sapo de Innsmouth (`SPIT`): escupe baba (`ThrownExplosive`, aspecto `baba`) que deja un charco de ácido. Búho de los sueños (`INSIGHT`, vuela): +12 % de experiencia, hasta +30 % (`Player.pet_xp_mult`). Rata de las Paredes (`FORAGE`): cada 20 s escarba y encuentra dólares, a veces un baúl (`game.director.spawn_chest`). Shoggoth bebé (`DEVOUR`): se traga 2 balas enemigas por segundo, hasta 5 (`BulletManager.devour_enemy_bullets`).
      - Modelos `gen_gato.py`, `gen_rata.py`, `gen_sapo.py`, `gen_buho.py` y `gen_shoggoth.py`; animaciones `anim_sapo.gd`, `anim_volador.gd` y `anim_blob.gd` (la rata usa `anim_cuadrupedo.gd`). Precios: rata 2.000 $, sapo 3.000 $, búho 3.500 $, shoggoth 5.000 $.
      - Tests en `tests/test_pets.gd`. Hojas `shots/revision_2_15a_modelos.png`, `revision_2_15a_gato.png` y `revision_2_15a_sapo.png`. Prueba: `godot --path . -- pet=shoggoth`.
    - **2.15b y 2.15c hechas, pendientes de tu revisión (30-09-2026):** las diez restantes. Comportamientos nuevos en `scripts/pets/behaviors/` y datos nuevos en `PetData` (`radius`, `stun`, `knockback`, `effect_time`); `Pet` añade `lift` (altura del vuelo: picados), `hidden` (bajo tierra), `rush` (embestidas), `teleport()` y `strike()` (golpe con daño, empuje y aturdimiento).
      - Mini-Byakhee (`DIVE`, 4.500 $): vuela alto, marca el suelo y cae en picado (área y empuje). Cuervo de Arkham (`FETCH`, 3.000 $): va a por gemas sueltas lejanas y las hace volar hacia su jugador (`GemManager.free_gem_near`, `attract`); si no hay, picotea a un enemigo; siempre roba 2-6 $. Polilla de Leng (`CONFUSE`, 4.000 $): polvo sobre el grupo más denso, los confunde 3 s (`Enemy.confuse`: vagan y no disparan). Gaviota de Innsmouth (`HEAL`, 3.500 $): cada 18 s trae pescado que cura un 8 % de vida y cordura (hasta 15 %) al de menos vida cerca; chilla y marca las élites que ve.
      - Mini-Mi-Go (`ZAP`, 5.000 $): rayos violetas (`Beam` admite colores). Araña de Tíndalos (`BLINK`, 6.000 $): aparece detrás del enemigo, muerde fuerte y aturde 1,2 s. Serpiente de Yig (`POISON`, 4.000 $, dentro de `PetHunt`): muerde y envenena 4 s (`Enemy.poison`, tinte verde). Pez de Innsmouth y cabra de los bosques (`CHARGE`, 2.500 $ y 3.000 $): carrerilla y embestida en línea; la cabra además aturde. Mini-Dhole (`BURROW`, 6.000 $): se hunde, sale bajo el grupo más denso (área, empuje y aturdimiento).
      - Modelos: `tools/gen_voladores.py` (byakhee, cuervo, polilla, gaviota: `anim_volador.gd`) y `tools/gen_rastreros.py` (cabra, Tíndalos y Mi-Go con `anim_cuadrupedo.gd`; Yig y dhole con `anim_serpiente.gd`; pez con `anim_pez.gd`). Hojas `shots/revision_2_15bc_voladores.png` y `revision_2_15bc_suelo.png`.
      - Arreglado (03-10-2026), pendiente de tu revisión: pez aplanado de lado, con boca de pez en anillo, ojos redondos saltones, agallas y cresta; aletas y cola cuelgan del cuerpo (`parents`). Araña: abdomen en rombo (cubo girado), aristas apagadas y solo brillan a trazos las verticales del abdomen. Voladores a 32 voxels/m (1,5× más grandes, alas más cortas en voxels: misma envergadura). Hojas `shots/fix_pez_tind.png` y `buho-byakhee-cuervo-polilla-gaviota_30_fix.png`.
      - Tests en `tests/test_pets.gd` (18).
  - **Reglas de daño (D-37, 03-10-2026), pendiente de tu prueba:** `DamageRules` (`scripts/weapons/damage_rules.gd`) estima el daño por segundo de cada arma a un solo objetivo y el que le toca por sus rasgos; `godot --headless --path . -s tools/reglas_dano.gd` imprime la tabla y `-- aplicar` ajusta `damage`, `zone_dps` y `curse_dps`. `WeaponData.support` deja fuera las de puro apoyo. Test en `tests/test_damage_rules.gd`. **Si cambias un arma, vuelve a ejecutarlo.**
  - **Subida de nivel con tragaperras (03-10-2026), pendiente de tu revisión:** en `CoopLevelUp`, un rodillo bajo el título recorre los atributos y se para en el que sube (0,5 s; entrada `attr`) y cada tarjeta gira con armas y objetos al azar hasta su opción (0,7 / 0,95 / 1,2 s, `REEL_STOPS`), con un pequeño salto. A o Intro durante el giro lo para todo; solo se elige con todo parado. Hoja `shots/revision_tragaperras.png`.
  - **Biblioteca Lovecraft (03-10-2026), pendiente de tu revisión:** sustituye a "Logros" en el menú principal. Un libro abierto (`LibraryMenu`, `scripts/menus/library_menu.gd`) con seis tomos: I Bestiario, II Arsenal, III Objetos (de la partida y de la tienda), IV Lugares (los 15 niveles), V Investigadores y compañeros y VI Logros (abre la lista de siempre). Índice a la izquierda y ficha a la derecha: modelo o icono, datos y una nota de diario de los años 20 (`data/library/textos.json`). Lo no descubierto sale como "???" con la imagen en silueta.
    - Lógica sin interfaz en `Library` (`scripts/save/library.gd`). La partida apunta cada segundo en `SaveData.seen` el lugar, las armas y objetos que llevan los jugadores y los enemigos que están en pantalla (`game._record_seen`). Personajes y compañeros: los desbloqueados; objetos de la tienda: los comprados.
    - Imágenes: los modelos se encajan por lo que ocupan vistos desde la cámara (`ModelIcon._projected`, margen 1,12); el bestiario va a escala, con el encuadre del enemigo más grande y los pies abajo (`ModelIcon.make(..., fixed)`). Lugares: mapa de la arena en isométrica, de `godot --path . -s tools/render_mapa.gd -- p1_n1` (`resources/maps/<nivel>.png`; **si cambia la arena, vuelve a ejecutarlo**).
    - Capturas: `title saves=test_bib open=menu_biblioteca tome=N cursor=N shots=14` (crea antes `saves=test_bib test_save=1`, con todo descubierto). Tests en `tests/test_library.gd` (también que toda entrada tenga texto).
  - **Hito 2.16 (vestuario, D-34), primera tanda: hecha, pendiente de tu revisión (03-10-2026).** Prendas solo estéticas, compradas una vez para todos los personajes.
    - 8 prendas (`data/outfits/*.tres`, `OutfitData`): bombín, casco de minero, gorro de nieve y sombrero de copa (cabeza), chaqueta de aviador y abrigo de piel (cuerpo), botas militares y botas de nieve (pies).
    - Modelos por personaje: `tools/gen_vestuario.py` → `models/vest_<prenda>_<personaje>.json`, con las medidas de cada uno (clave `body` del JSON del personaje, que ahora escribe `cuerpo.finish`) y sus mismos pivotes (`cuerpo.pivots`). **Si cambia un personaje, vuelve a ejecutar su generador y después `gen_vestuario.py`.**
    - El sombrero de cada personaje va en su propia parte `hat` (`finish(..., hat=(colores))`); una prenda de cabeza la oculta. `VoxelBuilder.dress` cuelga las mallas de la prenda de las partes del personaje (se anima con él). `OutfitData.apply` viste: partida, retrato del HUD, selección y visor (`still 0 dyer+bombin+botas_nieve`).
    - Tienda: pestaña Vestuario. Selección: paso nuevo tras el personaje (arriba/abajo cabeza, cuerpo o pies; izquierda/derecha la prenda o "Lo suyo"); se salta si no hay prendas. Lo elegido se guarda por personaje (`SaveData.outfits`, `worn`, `worn_by`).
    - Pruebas: `outfit=bombin,botas_nieve` en la partida; capturas `select saves=test_bib slot=0 vest=2 shots=3`. Tests en `tests/test_outfits.gd` y `test_select_state.gd`. Hojas `shots/revision_vestuario_giros.png` y `vest_sel_crop.png`.
  - **Hito 2.16, segunda tanda: hecha, pendiente de tu revisión (03-10-2026).** Las 18 restantes; en total 26 prendas en cuatro huecos:
    - Cabeza: casco Brodie, cinta del pelo (con una capa de pelo del color del personaje, `hair_of`, porque bajo el sombrero original no hay coronilla), sombrero de aventurero, boina (burdeos: negra no se veía sobre el pelo negro), sombrero vaquero, pamela, turbante y canotier de paja.
    - **Hueco nuevo, Accesorio** (`OutfitData.Slot.ACCESSORY`, no oculta el sombrero): gafas de ver, gafas de nieve inuit y bufanda.
    - Cuerpo: abrigo de nieve, chubasquero, chaleco, vestido y bata (más holgada, para tapar el estetoscopio de Whipple). Pies: botas esquimales y zapatos de tacón.
    - El vestuario entero cuesta ~49.000 $ (unas 9 h); el test de la tienda lo cuenta aparte de las ~20 h del resto.
    - Hojas `shots/*_v2a.png` a `*_v2e.png` (prendas puestas) y `shots/vest_sel_crop.png` (selección con las cuatro filas).
  - **Hito 2.17 (cierre), prueba de carga con 4 jugadores hecha (03-10-2026):** 65-69 FPS de media y 37-41 en el 1 % peor con 150 enemigos y 1.000 balas (con 1 jugador, 90 y 53); partida normal con 4 jugadores, 114 y 82. Detalle en `docs/RENDIMIENTO.md`. **Falta tu prueba con varios mandos** para cerrar la fase 2.
- **Fase 3 (pipeline de contenido): en curso.**
  - **Evoluciones de armas (D-06), primera tanda: hecha, pendiente de tu revisión (03-10-2026).** `WeaponData.evolves_with` (objeto), `evolution` (arma) y `evolved`; `WeaponSystem.evolvable` y `evolve`; al abrir un baúl, `game._try_evolve` convierte la primera arma lista y lo anuncia. Las evoluciones no salen al subir de nivel y quedan fuera de las reglas de daño. Cuatro: Carga concentrada, Revólver del vigía, Rifle de la expedición Miskatonic e Instrumental de cirujano (de momento con el icono del arma base). La Biblioteca dice con qué objeto evoluciona cada arma.
  - Prueba: `bot=circle god=true weapons=webly wlevel=5 items=iman chest_every=4 log=true` (`items=` da objetos al J1). Tests en `tests/test_evolutions.gd`.
  - **Contenido por datos (03-10-2026):** la partida carga la arena del nivel (`LevelData.arena`; `arena=ruta` para probar otra); los comportamientos se eligen por nombre (`EnemyData.movement = "blind"` → `scripts/enemies/blind_behavior.gd`; "chase" persigue); qué script anima cada modelo está en `data/anim_sets.json` (antes `Anims.BY_MODEL` en el código). `enemies=id,id` hace aparecer solo esos enemigos. `tests/test_content.gd` valida que todo lo de `data/` apunte a cosas que existen.
  - **Cómo añadir un enemigo (sin tocar código):** 1) generador en `tools/` → `models/<modelo>.json`; 2) su línea en `data/anim_sets.json` (o un `anim_<tipo>.gd` nuevo si se mueve distinto); 3) `data/enemies/<id>.tres` (vida, velocidad, `movement`, `attack` con un patrón de `data/patterns/`); 4) su nota en `data/library/textos.json`; 5) añadirlo a `pool` de su nivel. Probar con `enemies=<id>` y `still 0 <modelo>` / `anim 0 <modelo> walk`. Prueba hecha con el Profundo (`data/enemies/clasico.tres`, modelo prototipo; aún en ningún nivel).
  - Queda de la fase 3: generalizar el generador de escenarios (hoy `gen_arena_campamento.py`) cuando haya arenas nuevas (fase 4).
- **Fase 4 (parte 1 completa): en curso** (plan del 03-10-2026 en `docs/ROADMAP.md`, hitos 4.1 a 4.6). D-04 (élites con tope y seres únicos como minijefes) y D-19 (etiqueta `humana`: cultistas, habitantes de Innsmouth, acólitos e híbridos no completos) resueltas en el GDD.
  - **Hito 4.1 (generador de escenarios y arena del nivel 2): hecho, pendiente de tu revisión (03-10-2026).**
    - `tools/arena_kit.py`: clase `Arena` (`add`, `free`, `scatter`, `edge` para bordes de ventisqueros, `coast`, `floes`, `write` con el mapa de obstáculos) y valores comunes (`COLLIDERS`, `POLAR_DUSK`, `ICE_BARRIER`, `LAMP`). `gen_arena_campamento.py` es ya una receta (sale idéntico). Una arena nueva es un `tools/gen_arena_<nombre>.py`.
    - Arenas sin mar: `"sea"` opcional en el JSON; `ground.margin_front` alarga el suelo por delante; `ground.camp_radius`, la nieve pisada.
    - Arena del nivel 2, `tools/gen_arena_lake.py` → `data/arenas/lake.json`: Barrera al norte y al oeste, ventisqueros al sur y al este, tiendas rasgadas, el avión, la perforadora volcada, mesas de disección vacías, cajas reventadas, tres faroles y el corral de los perros con un tramo derribado; día gris y frío. 100 FPS con 150 enemigos y 1.000 balas.
    - Atrezo nuevo en `tools/gen_atrezo_lake.py` (tienda rasgada, caja reventada, mesa de disección, avión a 32 voxels/m y perforadora). La violencia se sugiere: lona rota, manchas verdinegras, nada de cuerpos. Hoja `shots/revision_4_1_atrezo.png`; arena en `shots/game_lake2_003.0s.png`. Probar: `godot --path . -- nolevel=true arena=res://data/arenas/lake.json`.
    - Ojo con `voxlib.noise(x, y, z, s)`: ya divide entre `s` (tamaño de la mancha) y da [0, 1]; escalar además las coordenadas hace manchas gigantes.
  - **Hito 4.2 (los Antiguos y el nivel 2): hecho, pendiente de tu revisión (03-10-2026).**
    - Modelo `tools/gen_antiguo.py` (orgánico, 32 voxels/m): barril con cinco crestas, cabeza en estrella con cinco ojos rojos y cilios, tentáculos en la cintura, cinco patas de estrella de mar y alas membranosas (plegadas en `antiguo`, abiertas en `antiguo_alado`). Animaciones `anim_antiguo.gd`: idle, walk (patas por turnos), lash, fly y dive.
    - Antiguo revivido (`chase`, abanico de espinas `antiguo_espinas`) y Antiguo alado (`DiveBehavior`, `scripts/enemies/dive_behavior.gd`: vuela en círculo a 2,6 m, marca el suelo y cae en picado). `EnemyBehavior.touches()`: los voladores solo dañan por contacto cuando están abajo.
    - D-04: `EnemyData.unique` (nunca en las oleadas) y `model_scale`. Evento final del nivel 2: "El primero en despertar", Antiguo único a 1,5× con el acecho y salto del Acechador, onda de espinas con huecos (`antiguo_onda`) y canto mental (`antiguo_canto`), y un aura que drena cordura.
    - `data/levels/p1_n2.tres`: arena de Lake, ventisca, pingüinos, fragmentos y los dos Antiguos; se abre al superar el nivel 1. Mapa de la Biblioteca en `resources/maps/p1_n2.png`. Con bot y evento final adelantado se supera; a ritmo normal, el bot cae hacia los 210 s (más difícil que el nivel 1: el equilibrio va en el 4.6).
    - Captura en partida: `shots/game_ant_020.0s.png`. Probar: `godot --path . -- level=p1_n2` o `enemies=antiguo_revivido,antiguo_alado`.
  - **Hito 4.3 (nivel 3, el paso de la cordillera): hecho, pendiente de tu revisión (03-10-2026).**
    - Shoggoth esclavo (`ChargeBehavior`: se encoge con un aviso alargado y embiste en línea; ×1,6 de daño durante la embestida) y shoggoth mimético (`MimicBehavior`: anda como un Antiguo sin atacar; a 5 m o si le dañan, chilla "¡Tekeli-li!" y se transforma con `Enemy.swap_model`). `Enemy.model_name` y `model_scale` (el modelo actual). Modelo `shoggoth_grande` (el fragmento a S=3 y otra semilla: `python tools/gen_fragmento.py 3 shoggoth_grande 1938`), a escala 2.
    - Evento final: "El shoggoth de la caverna", único, a 3,2× con embestida, glóbulos y aura.
    - Arena `tools/gen_arena_paso.py` → `data/arenas/paso.json`: barrera de roca (`tools/gen_barrera_roca.py` recolorea la de hielo), suelo de roca (`ground.colors` da colores al shader del suelo), rocas grandes en el borde sur y este, avenida de columnas talladas por los Antiguos, estalagmitas, cristales de hielo que brillan y dos faroles. Penumbra azulada; clima niebla. Atrezo en `tools/gen_atrezo_paso.py`. La primera roca parecía una calavera (redonda con dos huecos oscuros): ahora es de caras planas.
    - Con bot a ritmo normal cae hacia los 105 s (nivel 2: 210 s): la dificultad sube rápido; se ajusta en el 4.6. Tests en `tests/test_behaviors_4.gd`. Captura `shots/game_n3_050.0s.png`.
  - **Hito 4.4 (nivel 4, la ciudad ciclópea): hecho, pendiente de tu revisión (03-10-2026).**
    - Variantes en `gen_antiguo.py`: Antiguo guerrero (placas de pizarra, cresta y lanza de piedra con punta de cristal; élite de escalón 4 con estocada rápida: `ChargeBehavior` con `anim_windup`/`anim_move`/`anim_rest` configurables) y Antiguo mutilado (sin dos puntas de la estrella ni medio manojo de tentáculos, alas rotas, limo negro; `OozeBehavior` deja charcos `EnemyZone` que dañan a los jugadores).
    - Evento final: "El guardián de la ciudad" (guerrero único a 1,7×, embestidas, onda de espinas y aura).
    - Atrezo `tools/gen_atrezo_ciudad.py` (muros rotos de sillares con estrellas en relieve, arcos, murales de Antiguos, bloques y el muro ciclópeo de fondo a 8 voxels/m) y arena `tools/gen_arena_ciudad.py`: dos anillos de calles en ruinas alrededor de una plaza, suelo de losas grises con escarcha, ceniza. La piedra parda salía marrón con el sol cálido: ahora gris fría.
    - Ojo en los generadores: en una lista por comprensión, `x, y, z` del bucle de fuera no son los de `k`. El mutilado perdía las alas enteras por eso.
    - Captura `shots/game_n4_036.0s.png`; arena `shots/game_ciu_003.0s.png`.
  - **Hito 4.5 (nivel 5 y el jefe de la parte 1): hecho, pendiente de tu revisión (04-10-2026).**
    - Shoggoth de ojos luminosos (`shoggoth_ojos`: el shoggoth grande con ojos verdes que brillan; repta y escupe ráfagas) y Antiguo del mar abisal (`antiguo_abisal`: azul casi negro con líneas bioluminiscentes; canto mental y aura). Los dos modelos se recolorean de los existentes (script en línea; si cambian `shoggoth_grande` o `antiguo`, hay que rehacerlos).
    - **Jefe: el shoggoth primigenio** (`BossBehavior`, `scripts/enemies/boss_behavior.gd`), a 4,2×, 1.600 de vida, en tres fases por vida: embestidas por el túnel; parado, ráfagas de ojos (`primigenio_ojos`) y fragmentos que brotan cada 4,5 s; furia sin descanso con la espiral (`primigenio_espiral`). Al cambiar de fase chilla "¡TEKELI-LI!" y es invulnerable 1,2 s. `Enemy.health_scale` (vida máxima en cooperativo) y `Enemy.shield_t`. Con `log=true` imprime "JEFE fase N".
    - Arena `tools/gen_arena_tuneles.py`: gruta bajo la ciudad, mar sin luz al sur y al este con rocas en la orilla, estalagmitas, columnas, arcos como bocas de túnel, cristales y un solo farol. Clima niebla (aclara mucho la gruta: revisar en el 4.6).
    - Con bot invulnerable y tres armas al nivel 5, el jefe pasa las tres fases y el nivel se supera. Captura `shots/game_n5_030.0s.png`. Probar: `godot --path . -- level=p1_n5 final_at=20`.
  - **Hito 4.6 (equilibrio de la parte 1): hecho, falta tu partida (04-10-2026).**
    - Medido con el bot `circle` (solo da vueltas: no esquiva balas ni embestidas). En solitario aguanta 120-240 s en los cinco niveles (antes, 66-78 s en el 4 y el 5). En cooperativo con 3 bots, el equipo llega al evento final en todos. Con el equipo invulnerable, los cinco se superan matando al ser único en 12-35 s.
    - Ajustes: pingüinos, menos ritmo inicial y una sola élite en los niveles 4 y 5; shoggoth esclavo más flojo (9 de contacto, embestida ×1,4) y esclavo, de ojos luminosos y abisal, menos frecuentes; `coop_spawn` [1; 1,25; 1,5; 1,75]; los seres únicos solo suben la mitad de vida en cooperativo (`WaveDirector.spawn`); horda del final 12 en los niveles 3 a 5; guardián de la ciudad 550 de vida y embestida más corta (tardaba 6 min en morir).
    - `log=true` imprime "FIN DERROTA t=… abatidos=…" al caer todo el equipo. Ojo: el registro de cada 30 s (`fmod(director.time, 30)`) se salta líneas con `timescale` alto; no sirve para saber hasta dónde se llega.
- **Cambios del 04-10-2026 (encargo del autor):**
  - Nivel 2 con `data/weather/ventisca_ligera.tres` (bruma 0,08 y niebla 0,005: la ventisca tapaba demasiado).
  - Pausa: B en el mando vuelve al juego (`Menus.PauseMenu._unhandled_input`).
  - Gemas por escalón del enemigo: amarilla, verde, azul, roja y morada (`GemManager.TIER_COLORS`), color por instancia del MultiMesh y `gem.gdshader`; algo mayores cuanto más alto. `gem_test=true` las enseña.
  - Avión del nivel 2 con Replicate: `tools/generar_modelo_replicate.py avion` (FLUX genera la imagen en estilo voxel, `firtoz/trellis` la pasa a malla y se voxeliza con los colores de la textura; necesita `trimesh` y `scipy`). Imagen y malla en `tools/replicate/`. Sirve para otras piezas: añadirlas a `PIECES`.
  - Ficha del jugador rehecha con el formato de la selección (`PlayerMenus.Sheet`): personaje, compañero (imagen y datos), atributos y estadísticas ya actualizadas, armas con imagen, daño y abatidos, objetos con imagen. En cooperativo, a lo alto de su lado y una columna por página (LB/RB).
  - Estadísticas por arma: `Damage.ctx`/`Damage.tag` ("J1:webly"); `WeaponSystem` lo pone al disparar, cada efecto lo guarda al crearse (`_wtag`) y cada bala en `BulletManager._tag`; `Enemy.take_damage` suma en `CombatWorld.stats` (`stats_of(i)`). El compañero cuenta como "mascota". Con `log=true`, "ESTADISTICAS J1 …" al superar el nivel.
  - Balas del jugador con aspecto por arma (`WeaponData.bullet_look`: pellet, rifle, smg, blade, spark, harpoon, dart; sin él, trazadora pesada con halo) y destellos de impacto (estilo 13, depósito de 256 en el mismo MultiMesh). Sin coste medible (buffer 0,71 ms). Hoja `shots/rev_balas.png`.
  - **Campaña por partes:** al superar un nivel, "Siguiente nivel" lleva al siguiente de la misma parte conservando el progreso de los jugadores (`GameSession.carry`). `Campaign.next_in_part`, `first_of` y `part_unlocked`: una parte se abre al superar el último nivel de la anterior. El mapa se muestra por partes, recortado y con zoom, y los niveles sueltos siguen abiertos mientras estemos en desarrollo. `LevelData.health_mult` sube la vida de los enemigos en los niveles avanzados (1,15 en el nivel 2), porque se llega con el personaje ya mejorado.
  - **Objetos rompibles** (`Breakable`, `BreakableSpawner`, `Pickup`):
    - Hay vasijas y cofres de suministros por la arena: 8 al empezar y uno nuevo cada 20 s, siempre a más de 5 m de los jugadores.
    - Al romperlos dan comida, poción, dólares, un lanzallamas potente durante 5 s o tiempo congelado durante 5 s.
    - Modelos en `tools/gen_recompensas.py`. Tests en `tests/test_breakables.gd`.
  - **Movimiento de los enemigos:**
    - Rodean el decorado con un mapa de flujo (`FlowField`, `scripts/level/flow_field.gd`) cuando no tienen línea libre hacia el jugador. Esa comprobación se hace cada 0,3 s por enemigo.
    - Trayectorias por datos (`EnemyData.path`, aplicadas en `EnemyBehavior.shape_path`): `zigzag`, `hop` (a saltos), `flutter` (revoloteando) y `circle` (en espiral).
    - El mimético se revela solo.
    - Tests en `tests/test_flow_field.gd`.
  - **Choque de balas:** las balas del jugador anulan las enemigas que tocan; las pesadas siguen su camino. Lo resuelve una rejilla plana en `BulletManager`. Las armas de área (lanzallamas, páginas que orbitan, onda, explosiones) también deshacen balas enemigas. Tests en `tests/test_bullet_clash.gd`.
- **Fase 6 (parte 2, *La sombra sobre Innsmouth*): plan aprobado el 06-10-2026** (hitos 6.0 a 6.7 en `docs/ROADMAP.md`). D-13: más difícil que la parte 1, contando con las mejoras permanentes de la tienda; equilibrio medido sin compras y con las esperables; difícil, nunca exasperante. Dagon a 16 voxels/m, asomando del agua; las tiaras, solo prohibidas a los Profundos.
  - **Hito 6.0 (base común de Innsmouth): hecho, pendiente de tu revisión (06-10-2026).**
    - **"Aspecto de Innsmouth" por grados** (`cuerpo.innsmouth(M, grado, piel, sombra)`): se llama tras `head()` y `arms()` en lugar de `eyes()` y `mouth()`.
      - Grado 1: piel grisácea, sin orejas, ojos saltones de 3×3 que asoman también por los lados y boca ancha.
      - Grado 2: además calva con manchas, agallas rojizas a los lados de la cabeza y labio grueso.
      - Grado 3: además cráneo aplastado, escamas y joroba con púas.
      - Muestra: `tools/gen_innsmouth_muestra.py` (un pescador en los cuatro grados, `models/innsmouth_g0..g3`). Hoja `shots/revision_6_0_innsmouth.png`.
    - **Profundo definitivo** (`tools/gen_profundo.py`, estilo 4 a 48 voxels/m): sin ropa, cabeza chata de pez, ojos saltones, boca con dientes, agallas, cresta de púas, aletas y manos palmeadas con garras. `cuerpo.hunch()` lo encorva (tronco inclinado, brazos y cabeza adelantados con sus pivotes). `cuerpo.finish` admite `roughness` y `specular` (piel húmeda: 0,45 / 0,5).
      - El enemigo `clasico` pasa a llamarse `profundo` (`data/enemies/profundo.tres`, Biblioteca, visor). Anima con `anim_profundo.gd`; aún sin zarpazo propio (no le hace falta: daña por contacto).
      - Hoja `shots/revision_6_0_profundo.png`; andando, `shots/rev_profundo_walk.png`.
    - **Suelos de la parte 2** (`scripts/level/town_ground.gdshader`), elegidos con `ground.kind` en el JSON de la arena: `mud` (tierra con baches, matas y charcos), `cobble` (adoquín en hileras con juntas, verdín y charcos) y `planks` (tablas de muelle con vetas, clavos y huecos). `ground.wet` (0..1) oscurece y abrillanta; los colores, con `ground.colors` (`base_hi`, `base_lo`, `joint`, `moss`, `puddle`).
      - La nieve no se ha tocado (`snow_ground.gdshader`, por defecto sin `kind`): los niveles de la parte 1 se ven igual. Test en `tests/test_ground_kinds.gd`.
      - Campos de prueba: `tools/gen_arena_prueba_suelos.py` → `godot --path . -- nolevel=true arena=res://data/arenas/prueba_cobble.json weather=niebla_marina`. Hoja `shots/revision_6_0_suelos.png`.
      - Sin coste: con 150 enemigos y 1.000 balas, 75-79 FPS, igual que el campamento (74); el límite es la física.
    - **Clima `niebla_marina`:** niebla baja a rachas desde el mar con llovizna fina. Al principio tapaba demasiado; ahora tiene bruma 0,28 y niebla 0,004.
  - **Hito 6.1 (nivel 1 de la parte 2, Newburyport y la carretera a Innsmouth): hecho, pendiente de tu revisión (06-10-2026).**
    - **Gente de Innsmouth** (`tools/gen_vecinos_innsmouth.py`, estilo 4 con `cuerpo.innsmouth`, animados con `anim_humano.gd`). Todos con la etiqueta `humana` (rasgo de Legrasse):
      - Tres vecinos que persiguen en grupo: pescador (grado 1), mujer con chal (grado 1) y viejo con abrigo raído (grado 2).
      - Acólito de la Orden de Dagon: túnica parda, capucha echada atrás, cordón y amuleto de oro con un pez. Canto mental en abanico (`acolito_canto`).
      - El diácono de la Orden, evento final (único, a 1,4×): túnica casi negra, estola verde marino y tiara baja de oro. Canto en abanico (`diacono_canto`), espiral mixta con huecos (`diacono_espiral`), llama a 3 pescadores cada 10 s ("¡Ïa! ¡Ïa! ¡Dagon!") y un aura que drena cordura.
      - La piel del grado 1 a 3 es ahora más verde (`cuerpo.FISH`): con la luz cálida parecía bronceada.
      - Hoja `shots/revision_6_1_enemigos.png`.
    - **Comportamiento nuevo `keep`** (`KeepBehavior`, `scripts/enemies/keep_behavior.gd`): se acerca hasta `keep` m, retrocede si se le echan encima y rodea de lado. Admite un segundo patrón propio (`extra_pattern`, `extra_every`) y llamar a otros enemigos (`minion`, `minion_every`, `minion_count`, `minion_text`).
    - **Atrezo** (`tools/gen_atrezo_innsmouth.py` → `models/inn_*.json`):
      - Casa de tablas tapiada con porche y chimenea, a 16 voxels/m porque es pieza de borde (69.000 voxels).
      - El autobús de Joe Sargent, postes de telégrafo, valla de estacas, barril de arenques, redes tendidas, barca volcada, farola de gas (con luz) y juncos.
      - Hoja `shots/revision_6_1_atrezo.png`.
    - **Arena** (`tools/gen_arena_carretera.py` → `data/arenas/carretera.json`, mapa en `resources/maps/p2_n1.png`):
      - Casas y vallas al norte y al oeste. La carretera cruza en diagonal: es una banda del suelo `mud` con dos rodadas encharcadas (`ground.road`: punto, dirección y ancho).
      - Marisma al sur y al este (`ground.marsh`): la tierra se encharca y hay juncos. El mar habría salido con hielo y espuma.
      - Atardecer nublado y niebla marina.
    - **Nivel `data/levels/p2_n1.tres`:** se abre al superar el nivel 5 de la parte 1. Enemigos con `health_mult` 1,2. Música provisional: la del nivel 1. Textos de la Biblioteca para las cinco criaturas y el lugar.
    - **Equilibrio con bot (`circle`, sin compras):**
      - Parte 1, nivel 1: lo supera 2 de 2 veces.
      - Este nivel: lo supera 1 de 3; en las otras cae a los 195-229 s.
      - Cooperativo con 3 bots: lo superan.
      - Más difícil que la parte 1, como pide D-13. Antes de ajustarlo caía hacia los 2 minutos: los vecinos persiguen en línea recta (los pingüinos van a ciegas). Ahora tienen menos vida y daño por contacto, y van algo más lentos.
    - **Rendimiento** con 150 enemigos y 1.000 balas: 67 FPS de media (el campamento, 74). Los vecinos tienen más voxels que los pingüinos.
    - **Probar:**
      - `godot --path . -- level=p2_n1`.
      - El evento final, adelantado: `level=p2_n1 final_at=10`.
      - Solo la arena: `nolevel=true arena=res://data/arenas/carretera.json`.
    - Captura del evento final: `shots/game_diac_018.0s.png`.
  - **Hito 6.2 (nivel 2 de la parte 2, las calles de Innsmouth y el templo de la Orden): hecho, pendiente de tu revisión (06-10-2026).**
    - **Enemigos nuevos** (en `tools/gen_vecinos_innsmouth.py`):
      - Híbridos avanzados, hombre y mujer (grado 3, ropa empapada y hecha jirones, descalzos y con garras). Van a saltos (`path = hop`) y llevan las etiquetas `humana` y `marina`.
      - Sacerdote de la tiara (élite de escalón 3): vestiduras verde marino con galones de oro, capa y tiara alta en corona (`tiara()`). Comportamiento `keep`: canto en abanico y anillo mental con huecos y aviso.
      - El sumo sacerdote de la Orden, evento final (único, a 1,5×): negro bordado en oro y la tiara más alta. Canto, espiral, llama a híbridos ("¡Ph'nglui mglw'nafh!") y aura.
      - El oro de las tiaras es ahora deslustrado (`GOLD`): antes salía naranja.
      - Hoja `shots/revision_6_2_enemigos.png`.
    - **Escudo de protectores** (`KeepBehavior`, `shield_at`, `shield_minion`, `shield_count`): al bajar del 50 % de vida, el sumo sacerdote llama a 4 acólitos guardianes (`acolito_guardia`: poca vida, van a por el jugador) y es invulnerable, con un aro dorado, mientras viva alguno. Con `log=true` imprime "ESCUDO" y "ESCUDO roto".
    - **Atrezo nuevo** (en `tools/gen_atrezo_innsmouth.py`):
      - El templo de la Orden: fachada clásica de piedra con columnas, frontón con el símbolo de oro, escalinata y la puerta entreabierta. Va a 16/m, hueco y sin muro trasero, con 92.000 voxels (macizo eran 311.000).
      - Casa georgiana de ladrillo en ruinas (`fachada`).
      - Escombros, fuente seca con un pez de bronce, carretilla y cajas de pescado, nasa, pilote y coche abandonado.
      - Hoja `shots/revision_6_2_atrezo.png`.
    - **Arena** (`tools/gen_arena_calles.py` → `data/arenas/calles.json`, mapa en `resources/maps/p2_n2.png`):
      - Plaza de adoquín con la fuente, el templo al norte entre casas en ruinas y más casas al oeste.
      - Muelle de tablas al sur y al este: `ground.dock` hace que el adoquín pase a tablas cerca del agua (colores `dock_hi`, `dock_lo`).
      - Agua del puerto verde oscura y sin hielo: `sea.colors` y `sea.brash`, que ahora se leen del JSON.
      - La salida está en `[3.5, 6]`: en el centro está el pilón y salían 0 m² transitables.
      - Clima nuevo `lluvia_ligera`.
    - **Nivel `data/levels/p2_n2.tres`:** `health_mult` 1,3 y algo más de ritmo que el nivel 1.
    - **Equilibrio con bot (`circle`, sin compras):** lo supera 1 de 3; en las otras cae a los 186-208 s (el nivel 1 de la parte 2, a los 195-229 s). En cooperativo con 3 bots lo superan.
    - **Rendimiento:**
      - Con el tope real del nivel (75 enemigos y 500 balas): 118 FPS de media, igual que el nivel 1 de la parte 1 (119).
      - En la prueba extrema (150 enemigos y 1.000 balas): 57 FPS, porque los humanos de estilo 4 (20.000-34.000 voxels) suman unos 10 millones de primitivas; la arena sola va a 119 FPS. Si hiciera falta, la solución sería unir caras en `VoxelBuilder` o exportar los enemigos humanos a 32 voxels/m.
    - **Arreglado de paso:** la maldición de la daga ritual intentaba saltar a los objetos rompibles (`Breakable` no tiene `is_cursed`).
    - **Probar:** `godot --path . -- level=p2_n2` (o `final_at=10`). Capturas: `shots/game_cal_003.0s.png` (la plaza), `game_cal15_003.0s.png` (el muelle) y `game_sumo_030.0s.png`.
  - **Hito 6.3 (nivel 3 de la parte 2, el hotel Gilman House y la huida por los tejados): hecho, pendiente de tu revisión (06-10-2026).**
    - **Evento de supervivencia** (el primero), en `LevelData`:
      - Datos nuevos: `final_survive` (s), `final_rate`, `final_cap`, `final_pool`, `final_name` e `is_survival()`.
      - `WaveDirector._survival_step`: de `final_time` a `final_time + final_survive` llega la horda, sustituyendo a las oleadas normales, y al acabar el nivel está superado. Al empezar la horda aparece un baúl arcano.
      - HUD: "Resiste a la horda · 0:42" (`survive_left()`).
      - Test en `tests/test_survival.gd`.
      - Aquí: 60 s de horda del Arrecife del Diablo (Profundos y escupidores, hasta 70 vivos).
    - **Enemigos:**
      - Profundo (del 6.0) como horda principal.
      - Profundo escupidor (`profundo_lanzador`): azul pizarra con aletas turquesa. Comportamiento `keep`; escupe un abanico de agua salada física (`agua_salada`).
      - `acechador_tejados`: el Acechador como élite de las oleadas, con menos vida y menos aura que en la parte 1.
      - Vuelven los híbridos avanzados.
      - `tools/gen_profundo.py` hace las dos variantes (`build(nombre)`).
    - **Piezas a otra altura:** clave `y` en las piezas de la arena (`Arena.add(..., y=)`, `ArenaBuilder`, `gen_mapa_transitable.py`). Aquí, los tejados y las farolas de la calle, más abajo que el tejado.
    - **Atrezo** (`tools/gen_atrezo_tejados.py` → `models/tej_*.json`):
      - La trasera del Gilman House (16/m), con ventanas encendidas que brillan y la escalera de incendios.
      - Tejado abuhardillado, chimenea, claraboya, depósito de agua sobre patas, tendedero, pretil de ladrillo y trampilla.
    - **Arena** (`tools/gen_arena_tejados.py` → `data/arenas/tejados.json`, mapa en `resources/maps/p2_n3.png`):
      - Tablas mojadas (`planks`). El hotel y las buhardillas al norte y al oeste.
      - Pretil al sur y al este, y abajo dos filas de tejados de la calle con farolas.
      - Chimeneas, claraboyas, depósitos, tendederos y medianeras bajas hacen pasillos.
      - Clima nuevo `niebla_marina_noche`: la niebla clara se veía como un suelo gris.
      - Primera versión: los tejados de abajo estaban a 9 m del borde y entre medias solo se veía el fondo. Ahora están a 4 m y el fondo es más oscuro.
    - **Nivel `data/levels/p2_n3.tres`:** `health_mult` 1,3.
    - **Equilibrio con bot (`circle`, sin compras):**
      - Cae entre los 155 y los 271 s; una vez superó el nivel, horda incluida. El nivel 2 de la parte 2, entre 186 y 208.
      - En cooperativo con 3 bots lo superan, horda incluida.
      - Ajustes: el aura del Acechador hundía la cordura del bot (37 a los 90 s); escupidores con menos daño y más pausa; Profundo con menos daño por contacto.
    - **Rendimiento:** 113 FPS con 75 enemigos y 500 balas; 48 en la prueba extrema (150 y 1.000), por los modelos humanos y los Profundos de estilo 4.
    - **Probar:**
      - `godot --path . -- level=p2_n3`.
      - La horda, adelantada: `final_at=15`.
      - Hoja `shots/revision_6_3_atrezo_y_profundos.png`; capturas `shots/game_tej4_003.0s.png` y `shots/game_horda_040.0s.png`.
  - **Hito 6.4 (nivel 4 de la parte 2, los pantanos y la vía muerta a Rowley): hecho, pendiente de tu revisión (07-10-2026).**
    - **Agua somera que frena** (sistema nuevo):
      - La arena declara `"water"` en su JSON (`embank`: eje y medio ancho del terraplén seco; `islands`: parte seca en islotes; `scale`; `clear`: salida). `gen_mapa_transitable.py` escribe `data/arenas/<arena>_agua.bin` (N×N bytes) y la clave `mask.water`.
      - `ObstacleMap.water_at`, `has_water`, `random_water` y `water_texture`. El suelo dibuja el agua con esa misma capa (`town_ground.gdshader`, `water_tex`): lo que se ve es lo que frena.
      - `WadeSplash` (`scripts/fx/wade_splash.gd`): ×0,6 de velocidad al vadear (`SLOW`), el modelo se hunde 16 cm y salpica. El esquive no se frena: sirve para salir del agua.
      - Enemigos: vadean todos menos los que nadan (`EnemyData.swims`: Profundos, escupidores, anciano y Barnabas). Los híbridos sí se frenan.
      - `ground.walk_back`: lo transitable acaba antes que el suelo dibujado (el bosque del fondo no se pisa).
      - `ground.road_kind` 1: terraplén de balasto en vez de carretera con rodadas.
      - Tests en `tests/test_wading.gd`.
    - **Los que salen del agua** (`EnemyData.emerge`, `WaveDirector._emerge`): aparecen en una poza a 5-9 m de un jugador, tras un aro de aviso de 0,9 s y con un estallido de agua (`WadeSplash.burst`). Sin agua cerca, aparecen como siempre. `profundo_emergente` (Profundo de la ciénaga) y el anciano.
    - **Enemigos:**
      - Profundo anciano de Y'ha-nthlei (`gen_profundo.py profundo_anciano`, a escala 1,3): azul casi negro, bandas bioluminiscentes, ojos cian. Élite de escalón 3 con aura y canto mental en abanico (`anciano_canto`).
      - **Barnabas Marsh, transformado** (evento final, único, a 1,6×; `gen_vecinos_innsmouth.py`): levita negra y chaleco granate hechos jirones, leontina de oro, grado 3, descalzo con garras y aletas. `keep` a 4 m, canto, ola de agua en anillo con huecos (`barnabas_ola`), llama a Profundos ancianos ("¡Y'ha-nthlei!") y aura.
      - **Zambullida** (`KeepBehavior`, `dive_at`, `dive_time`, `dive_pattern`): al bajar del 66 % y del 33 % de vida se hunde, invulnerable 2,6 s, y sale en otra poza a 6-10 m de su objetivo con un aro de aviso y la ola. Con `log=true`, "ZAMBULLIDA N".
      - Ojo en los generadores: `slab` comparte la misma lista para todos sus voxels; para cambiar uno, asigna una lista nueva (`M.V[k] = [...]`), o cambias toda la pieza.
    - **Atrezo** (`tools/gen_atrezo_pantano.py` → `models/pan_*.json`): vía en tramos de 4 m (por debajo de 0,15 m: se anda encima), vagón de mercancías volcado, poste de señales con el farol rojo (luz), apeadero de Rowley (16/m), dos árboles muertos con musgo, tocón y puente de caballetes roto.
    - **Arena** (`tools/gen_arena_pantano.py` → `data/arenas/pantano.json`, mapa en `resources/maps/p2_n4.png`): el terraplén en diagonal con la vía; ciénaga con islotes a los lados (49 % de lo transitable es agua); bosque muerto al norte y al oeste; agua abierta al sur y al este. Noche de luna; clima nuevo `niebla_pantano`.
    - **Nivel `data/levels/p2_n4.tres`:** `health_mult` 1,35.
    - **Equilibrio con bot (`circle`, sin compras):** cae entre los 157 y los 258 s; una vez de seis lo superó (Barnabas cae en unos 20 s con las armas que lleva a esas alturas). El nivel 3 de la parte 2, entre 155 y 271. En cooperativo con 3 bots lo superan.
    - **Rendimiento** con el tope del nivel (75 enemigos y 500 balas): 119 FPS de media y 79 en el 1 % peor.
    - **Probar:** `godot --path . -- level=p2_n4` (o `final_at=10`); solo la arena: `nolevel=true arena=res://data/arenas/pantano.json`. Capturas `shots/game_pan4_040.0s.png` y `shots/game_barn_014.0s.png`.
  - **Hito 6.5 (nivel 5 de la parte 2, el Arrecife del Diablo y Y'ha-nthlei): hecho, pendiente de tu revisión (07-10-2026).**
    - **Eventos intermedios** (sistema nuevo): `LevelData.mid_enemies`, `mid_times` y `mid_texts` (listas paralelas). `WaveDirector._mid_step` lanza cada minijefe una vez a su segundo, con aviso (`mid_event`); las oleadas siguen y matarlo no supera el nivel. El HUD pone "Acaba con …" mientras vive (`director.mid_alive`). `mid_at=s` adelanta el primero (y los demás en proporción); con `log=true`, "MINIJEFE id t=…". Test en `tests/test_mid_events.gd`.
    - **El nivel:** a los 120 s, Pth'thya-l'yi; a los 240 s, Madre Hydra (evento final: al matarla se supera). En el 6.6, Padre Dagon irá detrás de Hydra.
    - **Pth'thya-l'yi, la antepasada** (`gen_profundo.py pththya`, a 1,5×): Profunda erguida, verde azulado viejo con el vientre nacarado, manto de aletas de los hombros a las corvas, abanicos de aletas a los lados de la cabeza con puntas que brillan y ojos dorados. Sin joyas. `keep`: canto en abanico, espiral mental (`pththya_espiral`), llama a Profundos que salen de las pozas (`_summon` usa `emerge`) y, al 50 %, un coro de 5 Profundos que la protegen (escudo del 6.2).
    - **Madre Hydra** (`gen_profundo.py hydra`, a escala 3): Profunda colosal, muy encorvada, verde negruzco, dos velas de aletas en la espalda, ojos y agallas de luz verde. `keep` con **golpe de zarpa** nuevo (`slam_every`, `slam_radius`, `slam_damage`, `slam_warn`, `slam_count`: avisos grandes donde está el jugador y alrededor), ola en anillo con huecos (`hydra_ola`), llama a Profundos ancianos y se zambulle al 66, 40 y 20 % para salir en otra poza con una espiral (`hydra_espiral`).
    - **Suelo `reef`** (`town_ground.gdshader`, kind 3): roca negra mojada en escalones, algas en lo hondo, percebes en lo alto y alguna grieta con luz verde (`crack_glow`). El agua somera admite `water_glow` (luz que sube de las pozas). `lamp.fog` en el JSON: densidad del halo de cada luz (corales: 0,1).
    - **Atrezo** (`tools/gen_atrezo_arrecife.py` → `models/arr_*.json`): columnas ciclópeas octogonales partidas con relieves de peces, arco caído (16/m), bloque tallado con un ojo de pez, rocas negras huecas con percebes y algas, coral negro con puntas que brillan (pivote `light`: es la luz de la arena) y el muro sumergido de Y'ha-nthlei (8/m).
    - **Arena** (`tools/gen_arena_arrecife.py` → `data/arenas/arrecife.json`, mapa en `resources/maps/p2_n5.png`): pozas (37 % de lo transitable; `water` sin `embank`), avenida de columnas en diagonal, arcos, bloques, rocas y corales; el muro al norte y al oeste; mar abierto al sur y al este. Noche cerrada; clima nuevo `niebla_arrecife`. Las primeras versiones tenían demasiado verde (grietas por todo el suelo y pozas que deslumbraban) y luego quedaron casi negras.
    - **Nivel `data/levels/p2_n5.tres`:** `health_mult` 1,4.
    - **Equilibrio con bot (`circle`, sin compras):** en solitario lo supera 3 de 6; en las otras cae a los 237-251 s, ya ante Hydra. En cooperativo con 3 bots lo superan. Antes de ajustar caía a los 170-200 s, al poco de salir Pth'thya (vida 520 → 440, aura 1,8 → 1,2, coro 5 → 4), y el equipo de 3 bots caía ante Hydra (zarpa 22 → 17 y 2 avisos en vez de 3, aura 2 → 1,2, invoca cada 20 s).
    - **Rendimiento** con el tope del nivel (75 enemigos y 500 balas): 118 FPS de media y 61 en el 1 % peor.
    - **Probar:** `godot --path . -- level=p2_n5`; los minijefes adelantados: `mid_at=10 final_at=60`. Capturas `shots/game_n5_012.0s.png` (Pth'thya) y `shots/game_hyd_013.0s.png` (Hydra).
  - **Hito 6.6 (jefe de la parte 2, Padre Dagon): hecho, pendiente de tu revisión (08-10-2026).**
    - **Jefe tras el final** (`LevelData.final_next`, `final_next_text`): al morir Madre Hydra sale Dagon (`WaveDirector.boss_event`) y el nivel se supera al matarlo. `director.final_target()` da el que toca (el HUD dice "Acaba con Padre Dagon"). `boss=true` lo lanza directamente como evento final; con `log=true`, "JEFE id", "DAGON fase N" y "DAGON se hunde". Test en `tests/test_mid_events.gd`.
    - **Modelo** (`tools/gen_dagon.py`, 16 voxels/m, ~55.000 voxels huecos; en el juego a 1,25×): Profundo colosal de cintura para arriba (lo de abajo queda bajo el suelo), escamas verdinegras, vientre pálido, cabeza de pez con mandíbula colgante y dientes, ojos que brillan, agallas, cresta de púas, aletas en los antebrazos y manos palmeadas con garras. Partes torso, head, arm_l y arm_r. Animaciones `scripts/anim/anim_dagon.gd`: idle, slam_l, slam_r, slam_both, roar, sink y emerge.
    - **`DagonBehavior`** (`movement = "dagon"`): anclado (`Enemy.anchored`: ni se mueve ni lo empujan) en una **sima** de la arena (`"boss_spots"` en el JSON; `water.holes` las dibuja como agua y no se pisan). Las simas van en la mitad norte: en la orilla sur o este se le veía de espaldas y tapaba media pantalla. Fases por vida:
      1. Golpe de una mano donde está el jugador (aviso de 3 m, 1 s) y olas en abanico (`dagon_ola`).
      2. Golpes con las dos manos (2 avisos), Profundos que salen de las pozas y espiral mixta (`dagon_espiral`).
      3. Tres avisos por golpe, más seguidos, anillos con huecos (`dagon_anillo`), aura que drena cordura a 9 m y, cada 14 s, se hunde y sale en otra sima con aviso.
      - Al cambiar de fase ruge (1,5 s invulnerable). Mientras vive, la cámara se abre a 20 m (`CAMERA_SIZE`).
    - **Temblor de cámara** (`GameCamera.shake(m)`): golpes y rugidos.
    - **Objetivo prioritario** (`CombatWorld.focus`): Dagon se pone como foco; `nearest_enemy` lo elige si está a tiro y no hay ningún enemigo a menos de 3 m. Sin eso, las armas siempre disparaban a los Profundos de alrededor y Dagon tardaba minutos en pasar de fase.
    - Las simas están a unos 13 m del centro (a 21 m quedaban fuera del alcance de casi todas las armas). Con el jefe vivo, el ritmo de aparición baja a la mitad del de después del evento final (`BOSS_SPAWN_SCALE`).
    - **Equilibrio con bot (`circle`, sin compras), nivel 5 entero:** Dagon con 3.600 de vida y el nivel con `health_mult` 1,3 (antes 1,4). En cooperativo con 3 bots lo superan (Dagon cae a los 342 s). En solitario, el bot llega a Dagon en 4 de 6 partidas pero no lo vence (cae entre 252 y 423 s). Queda para el 6.7 (equilibrio de la parte con y sin compras).
    - **Probar:** `godot --path . -- level=p2_n5 boss=true final_at=5` (Dagon directo).
  - **Hito 6.7 (cierre de la parte 2): hecho, falta tu partida (08-10-2026).**
    - **Medir la parte entera:** `level=p2_n1 bot=circle autopick=true autonext=true autorestart=1 chain=true log=true timescale=5`. `autonext` pasa al siguiente nivel conservando el progreso; `chain=true` hace que, al caer, se vuelva a empezar en el nivel de `level=` desde cero. `shop=N` simula N niveles comprados en cada potenciador (vida, cordura, daño y velocidad) sin tocar la partida guardada. Los registros "NIVEL SUPERADO" y "FIN DERROTA" llevan el nivel y el del J1.
    - Ojo: lanzando un nivel suelto de mitad de parte (`level=p2_n4`), el jugador recibe 7 subidas por cada nivel anterior (`DEV_LEVELS_PER_STAGE`): por eso las capturas salen con "Nv. 22" o "Nv. 29". Encadenado, se llega al nivel 5 hacia el nivel 22-25.
    - **Ajustes:** `health_mult` 1,0 / 1,1 / 1,15 / 1,2 / 1,2 (antes 1,2 / 1,3 / 1,3 / 1,35 / 1,3); el nivel 1 con el ritmo del nivel 1 de la parte 1; nivel 3 con un 10 % menos de ritmo y la horda a 2,4 por segundo con tope 55; Dagon con 3.000 de vida y zarpa 17. Antes, el bot recién empezado superaba el nivel 1 solo 2 de 37 veces y el nivel 3 paraba al equipo de 3 bots 8 de 9.
    - **Resultado** (bot `circle`, que no esquiva; superados / intentos):

      | | N1 | N2 | N3 | N4 | N5 |
      |---|---|---|---|---|---|
      | Solitario, sin compras | 5/17 | 4/5 | 1/4 | 1/1 | 0/1 |
      | Solitario, `shop=2` | 4/18 | 3/4 | 2/3 | 2/2 | 0/2 |
      | Cooperativo, 3 bots | 7/8 | 6/7 | 3/5 | 3/3 | 3/3 |

      En solitario el bot llega a Dagon pero no lo vence; en cooperativo la parte entera se supera.
    - **Rendimiento** con el tope de cada nivel (75 enemigos y 500 balas): 118-119 FPS de media en los cinco; el 1 % peor, 51 (nivel 1), 70, 60, 57 y 74.
    - **Biblioteca:** las criaturas y los cinco lugares de la parte 2 tienen texto y mapa.
    - **Falta tu partida** de la parte 2 para cerrarla.
- **Fase 5 (arranque, relatos y tienda): hecha, pendiente de tu revisión (08-10-2026).** Decidido: licencia "todos los derechos reservados", aviso de IA detallado y Armitage y West en esta fase.
  - **Hito 5.1 (ficha del proyecto) y 5.2 (intro): hechos, pendientes de tu revisión.** `scenes/intro.tscn` (`IntroScreen`, `scripts/title/intro_screen.gd`): la ficha (`data/credits.json`: título, autor, con qué está hecho, aviso del uso de IA y licencia; **edítala ahí**, sobre todo tu nombre) y después la intro (`data/library/intro.json`: una frase por pantalla sobre la ilustración de la biblioteca, oscurecida y acercándose). Pulsar pasa de pantalla; mantener 0,6 s lo salta todo. Arranca sin argumentos antes de la portada según Configuración > Juego > "Ficha e intro al arrancar" (siempre o solo la primera vez, `intro_seen`). `godot --path . -- intro` la abre siempre; `title` va directo a la portada.
  - **Hito 5.3 (relatos): hecho, pendiente de tu revisión.** `scenes/relato.tscn` (`RelatoScreen`): entre la selección (o "Siguiente nivel") y la partida, el título del nivel y sus frases (`data/library/relatos.json`, 15 relatos de 4 frases en tono de diario) apareciendo una a una sobre el mapa del lugar oscurecido. Pulsar muestra todo o empieza; mantener 0,8 s lo salta (aro que se llena). Con `autonext` (pruebas) no sale. Capturas: `godot --path . -- relato level=p2_n4 shots=10`. Test `tests/test_relatos.gd`.
  - **Hito 5.4 (tienda): hecho, pendiente de tu revisión.** Cuatro potenciadores (Presteza: esquive −4 %/nivel; Magnetismo: radio de recogida +8 %; Erudición: experiencia +4 %; Fortuna: suerte +5 %; stats de tienda `reflex`, `magnet`, `insight`, `fortune` que aplica `Player.rebuild_stats`) y sexta funda y sexto bolsillo (9.000 $). Iconos con Replicate (`generar_iconos_objetos.py`). El catálogo sin vestuario pasa de ~20 a ~27 h (~150.000 $). Los 15 compañeros ya estaban.
  - **Hito 5.5 (Armitage y West): hecho, pendiente de tu revisión.** `tools/gen_armitage_west.py` (estilo 4): **Profesor Henry Armitage** (anciano calvo con pelo y barba blancos, gafas doradas, levita gris marengo, chaleco con leontina, pajarita y un libro bajo el brazo; Polvo de Ibn-Ghazi, destello; rasgo `arcane_cooldown_mult` 0,8: armas mágicas un 20 % más rápidas) y **Herbert West** (rubio, pálido, gafas redondas, bata manchada sobre traje negro, guantes y la jeringa del reactivo verde que brilla en el bolsillo; Inyector de West, voltereta; rasgo `team_heal_on_level` 0,15: al subir de nivel cura a los compañeros a menos de 6 m). En la tienda a 6.000 $ cada uno; vestuario generado para los dos (`gen_vestuario.py`, `CHARS`). Ahora son 13 personajes.
- **Fase 8 (pulido y distribución): en curso** (plan del 08-10-2026 en `docs/ROADMAP.md`, hitos 8.1 a 8.5). D-12 resuelta: itch.io primero.
  - **Hito 8.1 (efectos de sonido): hecho, pendiente de que lo escuches.** Autoload `Sfx` (`scripts/core/sfx.gd`): `Sfx.play(evento)` con la tabla `data/sfx.json` (archivos al azar, dB, tono al azar, voces a la vez y separación mínima: con 150 enemigos no se apilan impactos). Bus "Efectos". Los botones de los menús suenan solos (foco y pulsación, por `node_added`). `log=true` imprime "SONIDOS {...}" al salir.
    - Archivos en `resources/sfx/` (`tools/gen_sfx.py <carpeta de los packs>`): sintetizados con numpy (disparos de revólver, rifle, escopeta y subfusil, tajo, rugido, gruñido, chillido, chapoteo, ola, el zumbido de los Ángulos y un cántico grave para el daño mental) y copiados de los packs CC0 de Kenney (Impact, Interface, RPG Audio, Sci-Fi): impactos, muertes, explosiones, golpes de zarpa, magia, rayo, fuego, esquive, gemas, subida de nivel, baúl, recompensas, cristal, menús.
    - Suenan: cada disparo (`WeaponSystem.sound_of`: por `WeaponData.sfx` o según categoría, entrega y `bullet_look`), explosiones, impactos y muertes de enemigos, golpes al jugador (o el cántico si es daño mental) y su caída, esquive, gemas, subida de nivel, baúles, recompensas, rompibles, chapoteos, golpes de zarpa con aviso, rugidos de los jefes y de los eventos, llamadas de los minijefes, picados de los voladores, Ángulos y olas. La nube verde de Cthulhu ruge.
    - Rendimiento: 82 FPS con sonido y 83 sin él (150 enemigos y 1.000 balas).
    - Cita en la ficha del proyecto (`data/credits.json`).
  - **Hito 8.2 (música por nivel): hecho, provisional.** 17 pistas CC0 de OpenGameArt en `resources/Music/cc0/` (OGG, volumen igualado a −16 LUFS con ffmpeg `loudnorm`): una por nivel (salvo el nivel 1 de la parte 1, que sigue con la tuya) y una de jefe por parte (`LevelData.boss_music`: suena al empezar el evento final). Elegidas por título y carácter, sin escucharlas (Storm Chasers en la tormenta, Pirate Indenture en los muelles, Dark Cavern Ambient en las cavernas…). Autores, títulos y enlaces en `data/musica.json`; cita en la ficha. **Para poner la tuya**, cambia `music` o `boss_music` en `data/levels/<nivel>.tres`. Con `log=true`, "MUSICA ruta".
  - **Hito 8.3 (accesibilidad): hecho, pendiente de tu revisión.** Configuración > Juego > Accesibilidad:
    - **Tamaño de la interfaz** (Pequeño, Normal, Grande, Muy grande: ×0,85 a ×1,3; `ui_scale`, `Settings.apply_ui` con `content_scale_factor`): menús y HUD.
    - **Colores de las balas:** Normales o Alto contraste (`bullet_palette`; `BulletManager.HIGH_CONTRAST`: físicas amarillo y blanco, mentales cian). Las formas ya se distinguían (bola maciza o anillo). Hoja `shots/revision_8_3_balas.png`.
    - **Destellos** (`flashes`): reducidos bajan el destello blanco de los golpes a los enemigos (0,75 → 0,2) y los rayos del clima a la cuarta parte.
    - **Temblor de la cámara** (`shake`, de 0 a 100 %): multiplica `GameCamera.shake`.
    - Las distorsiones de cordura baja ya se regulaban.
    - Para probar un ajuste sin guardarlo: `cfg_<clave>=valor` al lanzar (p. ej. `cfg_bullet_palette=1`, `cfg_ui_scale=3`; `Settings._overrides`).
  - **Hito 8.5 (exportación e itch.io): builds y página listas; falta subirlo (necesita tu cuenta).**
    - `sh tools/exportar.sh`: comprime los modelos (`tools/empaquetar_modelos.gd`: `models/*.json` → `models/*.json.z`, formato comprimido de Godot con ZSTD, de 278 a 46 MB; los `.json.z` no van a git) y exporta Windows (`builds/windows/LovecraftLibrary.exe`, 248 MB; antes 494) y macOS (`builds/macos/LovecraftLibrary.zip`, 197 MB). La build no lleva los JSON de modelos, `tools/` ni `docs/` (`exclude_filter`). `VoxelBuilder.read_text` lee el `.json` o, si no está, el `.json.z`.
    - **Arreglado:** la fuente de los títulos (`IMFeENsc28P.ttf`) no se cargaba en las builds (se leía como archivo suelto con `load_dynamic_font`); ahora se carga como recurso importado (`MenuKit.font`, portada).
    - Probado el `.exe`: arranca, carga los modelos comprimidos, la música y los sonidos.
    - Página: `docs/itchio/pagina.md` (título, URL, etiquetas, descripción, créditos, requisitos y pasos con butler), `portada_630x500.png`, `cabecera_1920x1080.png` y siete capturas en `docs/itchio/capturas/`.
- **Arsenal III y 50 objetos (D-38, 09-10-2026), hitos 8.6 a 8.9 en `docs/ROADMAP.md`; lista en el GDD, 5.4 y 5.5.** Nombres cortos (de una a tres palabras); también se acortaron los de 12 armas y 2 objetos que ya había.
  - **Hito 8.6 (objetos I): hecho, pendiente de tu revisión.** Los objetos son modificadores generales del jugador: campos nuevos en `CharacterData` (grupo "Objetos": `proj_count_add`, `range_mult`, `area_mult`, `weapon_cooldown_mult`, `duration_mult`, `pierce_add`, `crit_chance`, `crit_bonus`, daño general y por grupo, `elite_mult`, `armor`, `mental_mult`, regeneración, curación al abatir, `crisis_mult`, `money_mult`, `chest_mult`, `pickup_heal_mult`, `pet_mult`…), que `Player.rebuild_stats` rehace desde la base (`Player.ITEM_STATS`).
    - Las armas los leen en `WeaponSystem.Weapon.stat` (`WeaponSystem.with_items`): proyectiles solo en balas, lanzados y bumerán; perforación solo en balas; crítico ×1,5 (`BASE_CRIT`) también en las armas sin crítico propio (`dmg(w, crit)`). Contra élites, el rasgo `Player.ELITE_TAG` en `bonus_tags`. La armadura nunca quita más del 80 % del golpe (`ARMOR_FLOOR`). Al abatir, `CombatWorld.record_kill` avisa al jugador (`Player.on_kill`). Dólares y baúles usan el mayor del equipo (`WaveDirector.team_item`).
    - `UpgradeData`: `also` (más efectos, sintaxis de `level_mods`), `group` (ataque, protección, esquive, utilidad, disparador) y `apply_levels`. La partida carga todos los de `data/upgrades/`.
  - **Hito 8.7 (objetos II): hecho, pendiente de tu revisión.** Ya son 50 objetos. Los 13 con mecánica propia:
    - Escudo de Nodens: burbuja con borde azul (`nodens_shield.gdshader`) que para un golpe entero cada `Player.nodens_every()`.
    - *Ankh* de Nephren: te levanta una vez por nivel. Escamas de Profundo: devuelven parte del daño de contacto.
    - Esquís de Pabodie: esquives seguidos (`PlayerMotor.spare`). Capa del Hombre Negro: señuelo (`Flare`). Petardos: estallido. Elixir de Curwen: daño extra tras esquivar. Se lanzan en `Player._on_dodge`.
    - Llave de plata: RB o E en la subida de nivel cambia las opciones (`CoopLevelUp.Picker.reroll`, `Player.rerolls_left`).
    - Tablilla de Eltdown (`Player.on_kill`, `blast`), Cristal de Ithaqua y Fósforos de Cthugha: los dos se aplican al impactar (`CombatWorld.player_hit`, `Player.on_hit`). La quemadura es un estado nuevo del enemigo (`Enemy.ignite`, tinte naranja).
    - Diente de *shoggoth*: más daño con poca vida. Ídolo de Cthulhu: más enemigos (`WaveDirector._idol`), más experiencia y más dólares.
    - Los daños de los objetos salen en la ficha como "J1:tablilla", "J1:fosforos"… (`Player.item_tag`). `Damage.dot`: el daño continuo no dispara los efectos al impactar.
  - **Hito 8.8 (arsenal III): hecho, pendiente de tu revisión.** 16 armas (`python tools/gen_armas_arsenal3.py` escribe los `.tres` y las notas; después `tools/reglas_dano.gd -- aplicar`). Ya son 50.
    - Entregas nuevas: `WHIP` (`WhipFx`), `TRAP` (`BearTrap`, modelos `proj_cepo` de `tools/gen_proyectiles.py`), `FIREBALL` (`Fireball`), `VORTEX` (`Vortex`, `Enemy.nudge`), `SPIKES` (`TentacleSpike`), `MADDEN` (`Enemy.madden`: atacan a los suyos, tinte amarillo) y `SWEEP` (`SweepBeam`).
    - Datos nuevos en `WeaponData` (grupo "Arsenal III"): `volleys` (Recortada), `bounces` (BAR, `BulletManager.Effect.BOUNCE`), `spinup` (Nagant, `Weapon.heat`), `drift` (zona `GAS`), `frost` (`FlameJet` helado), `pull` y `orbit_look` (el ancla del *Alert* en `OrbitRing`). La ballesta clava con `root` en las balas (`Effect.ROOT`).
    - Iconos con Replicate (prompts en `generar_iconos_armas.py`); hoja `shots/rev_iconos_arsenal3.png` y en partida `shots/rev_arsenal3_juego.png`.
  - **Hito 8.9 (iconos y reparto): hecho, pendiente de tu revisión.** Iconos de los 45 objetos nuevos con Replicate (`generar_iconos_objetos.py`; hoja `shots/rev_iconos_objetos2.png`, rehechos en `rev_iconos_objetos3.png`). Subida de nivel: si hay, una opción es siempre mejorar algo que ya llevas, y lo propio pesa `PlayerProgress.OWNED_WEIGHT` (8) veces más que lo nuevo.
    - **Objetos y notas de la Biblioteca se generan con `python tools/gen_objetos.py`** (edita la lista ahí). Sin icono hasta el 8.9: el HUD pone el nombre abreviado. Tests en `tests/test_items.gd`.
- **Fase 7 (parte 3, *La llamada de Cthulhu*): hecha salvo tu partida (08-10-2026)** (hitos 7.0 a 7.7 en `docs/ROADMAP.md`). Los Ángulos devoradores son un peligro del escenario (zonas que se abren con aviso, atraen y engullen; no se matan). Cthulhu se combate como Dagon (colosal, anclado, asomando por la puerta de R'lyeh) y al caer se deshace en nube verde y se recompone una vez.
  - **Hito 7.0 (base común): hecho, pendiente de tu revisión (08-10-2026).**
    - **El culto** (`tools/gen_culto_cthulhu.py`, estilo 4, `anim_humano`):
      - `cultista`: túnica casi negra con la capucha puesta, máscara de hueso con borde oscuro y tentáculos verdinegros que caen sobre el pecho, amuleto del ídolo y una antorcha encendida en la mano derecha (llama `glow`, sin luz real: con muchos cultistas costaría demasiado). Datos en `data/enemies/cultista.tres` (persigue; `humana`) y texto en la Biblioteca.
      - `cultista_alert` (tripulante del *Alert*: jersey a rayas, gorra de lana roja, pañuelo con el símbolo, tatuaje y revólver) y `sacerdote_culto` (máscara mayor con más tentáculos, brazos desnudos pintados con franjas de hueso, el ídolo grande al cuello): modelos listos; sus datos llegan en el 7.2.
      - La primera máscara (hueso liso y tentáculos claros) se leía como una cara pálida con barba.
    - **El ídolo** (`models/cth_idolo.json`, 32/m): figura sentada de piedra verdinegra con cabeza de pulpo, tentáculos, alas rudimentarias y ojos que apenas brillan, sobre un pedestal con jeroglíficos.
    - **Suelo `rlyeh`** (`town_ground.gdshader`, kind 4): losas ciclópeas verdinegras cuya rejilla gira (hasta ±30°) y se tuerce por zonas de ~7 m, así que en las fronteras los ángulos no cuadran; juntas con limo que apenas brilla (`crack_glow`), verdín y charcos.
    - Campo de prueba: `godot --path . -- nolevel=true arena=res://data/arenas/prueba_rlyeh.json`. Capturas `shots/game_rly2_003.0s.png` y `shots/cultista-cultista_alert-sacerdote_culto_30_cul2.png`.
  - **Hito 7.1 (nivel 1 de la parte 3, Providence: el estudio de Wilcox): hecho, pendiente de tu revisión (08-10-2026).**
    - **Enemigos etéreos** (`EnemyData.ethereal`): atraviesan el decorado (sin `push_out`; solo se quedan dentro de los límites de la arena), no vadean y se dibujan semitransparentes y sin sombra (`Enemy._make_ethereal`: copia el material de cada malla con alfa 0,7).
    - **Pesadillas de la oleada de sueños** (`tools/gen_pesadilla.py`, 32/m, `anim_pesadilla.gd`: flotan, se deslizan inclinadas y alargan las garras): figura encorvada de sombra violeta que se deshilacha en jirones, brazos largos con garras y una cara hueca con cinco ojos verdes. Persiguen revoloteando (`path = flutter`), sobre todo daño mental.
    - **La pesadilla del bajorrelieve** (evento final, única, a 1,8×): la figura del bajorrelieve de Wilcox hecha sueño (cabeza de pulpo con tentáculos, alas, cuerpo escamoso). `keep`: canto en abanico, espiral mental, llama a pesadillas ("Cthulhu fhtagn…") y aura.
    - **Atrezo** (`tools/gen_atrezo_providence.py` → `models/prv_*.json`): pared de ladrillo con ventanales (16/m), el arranque de la pared por el lado de la cámara, esculturas de escayola a medio desbastar, bustos de arcilla con tentáculos, caballetes con mares negros, mesas de trabajo, el bajorrelieve sobre su soporte, sacos de barro, lámparas de pie (luz) y pilares de hierro.
    - **Arena** (`tools/gen_arena_estudio.py` → `data/arenas/estudio.json`, mapa en `resources/maps/p3_n1.png`): primera de interior, 48 x 48 m de tablas; paredes altas al norte y al oeste, cortadas al sur y al este; pilares en cuadrícula, unas 30 esculturas, caballetes y mesas con lámparas; el bajorrelieve en el rincón del fondo. Noche: luna fría por los ventanales. `ground.walk_back` 0: no se pisa más allá de las paredes.
    - **Nivel `data/levels/p3_n1.tres`:** `health_mult` 1,1, ritmo un 15 % mayor que el del nivel 1 de la parte 2 y `coop_spawn` más suave [1; 1,15; 1,3; 1,45] (con el de siempre, el cooperativo salía más difícil que el solitario: las pesadillas atraviesan paredes y se acumulan).
    - **Equilibrio con bot (`circle`, nivel suelto, personaje nuevo):** en solitario 5 de 11; en cooperativo con 3 bots 6 de 11. La primera versión se superaba 12 de 12 (las pesadillas solo quitaban cordura) y la segunda, 0 de 17.
    - **Rendimiento** con 75 enemigos y 500 balas: 119 FPS de media y 117 en el 1 % peor.
    - **Probar:** `godot --path . -- level=p3_n1` (o `final_at=15`). Captura `shots/game_p31_022.0s.png`.
  - **Hito 7.2 (nivel 2 de la parte 3, los pantanos de Luisiana: el ritual): hecho, pendiente de tu revisión (08-10-2026).**
    - **Diablo con alas de murciélago** (`tools/gen_diablo.py`, 32/m, `anim_diablo.gd`: fly, dive): criatura menuda y encorvada, piel correosa casi negra, cuernos, orejas de murciélago, ojos amarillos, cola con punta de flecha y alas de 2,6 m de envergadura con dedos huesudos y membrana rojiza. Vuela en círculo y cae en picado (`DiveBehavior`, como el Antiguo alado).
    - **Cultista armado del *Alert*** (`cultista_alert`, modelo del 7.0): `keep` a 6,5 m, ráfagas de tres tiros de revólver (`revolver_culto`).
    - **El sacerdote del ritual** (evento final, único, a 1,4×; `sacerdote_culto`): canto mixto en abanico, anillo mental con huecos, llama a diablos ("Ph'nglui mglw'nafh…") y, al 50 %, un corro de 5 cultistas que lo protegen (escudo del 6.2).
    - **Atrezo** (`tools/gen_atrezo_luisiana.py` → `models/lui_*.json`): hoguera de troncos cruzados (luz), monolito con jeroglíficos (el ídolo va encima como otra pieza, con `y`), ciprés calvo con rodillas y musgo español, choza de tablas sobre pilotes con tejado de chapa (16/m), poste con antorcha (luz) y calavera de vaca, y piragua.
    - **Arena** (`tools/gen_arena_ritual.py` → `data/arenas/ritual.json`, mapa en `resources/maps/p3_n2.png`): claro seco con el monolito y el ídolo, corro de ocho antorchas y cuatro hogueras; ciénaga de agua somera (48 % de lo transitable) con islotes alrededor; bosque cerrado de cipreses al norte y al oeste; bayou al sur y al este. Noche sin luna; la luz es la del fuego.
    - **Nivel `data/levels/p3_n2.tres`:** `health_mult` 1,12 (con 1,2, en solitario 2 de 12), `coop_spawn` suave como el nivel 1.
    - **Equilibrio con bot (`circle`, nivel suelto):** en solitario 3 de 11; en cooperativo con 3 bots 7 de 9.
    - **Rendimiento** con 75 enemigos y 500 balas: 119 FPS de media y 76 en el 1 % peor.
    - **Probar:** `godot --path . -- level=p3_n2` (o `final_at=12`). Capturas `shots/game_rit1_003.0s.png` (el claro) y `shots/game_p32_024.0s.png`.
  - **Hito 7.3 (nivel 3 de la parte 3, los muelles y la cubierta del *Alert*): hecho, pendiente de tu revisión (08-10-2026).**
    - **Engendro de Cthulhu** (`tools/gen_engendro.py`, 32/m, partes de los Profundos: `anim_profundo`): la progenie estelar, ~2,6 m; cabeza de pulpo con el manto echado atrás y una mata de tentáculos gruesos hasta la cintura, ojos amarillo verdoso, cuerpo escamoso hinchado, garras y alas de murciélago plegadas que asoman por encima. La primera versión tenía la cabeza pequeña y redonda (parecía un gorila) y garras claras que parecían manos.
      - `engendro` (a 1,2×): minijefe intermedio a los 120 s (evento intermedio del 6.5). `keep` a 4,5 m, canto mental, onda con huecos, golpe de zarpa con aviso (del 6.5) y llama a Profundos.
      - `engendro_mayor` (a 1,7×): el evento final, "lo que viajaba en la bodega del Alert"; dos avisos por golpe y más vida.
    - **Atrezo** (`tools/gen_atrezo_alert.py` → `models/alr_*.json`): el costado del *Alert* (casco negro con franja roja, borda, superestructura blanca con portillos, chimenea, palo y jarcia; 24 m de eslora, modelado a 16/m y exportado a 8/m: de 137.000 a 20.000 voxels), bolardos con cabo, grúa de carga, fardos con lona, rollos de cabo, faroles de puerto (luz) y bote volcado.
    - **Arena** (`tools/gen_arena_muelle.py` → `data/arenas/muelle.json`, mapa en `resources/maps/p3_n3.png`): muelle de tablas mojadas de Auckland; el *Alert* y otro vapor atracados al norte, almacenes de ladrillo al oeste (`inn_fachada`), pilotes en el borde del agua al sur y al este. Noche con llovizna (`niebla_marina_noche`).
    - **Nivel `data/levels/p3_n3.tres`:** Profundos, escupidores, cultistas y cultistas del *Alert*; `health_mult` 1,08, ritmo del nivel 1 de la parte 1. Los dos tiradores van con peso 0,3 en este nivel (`profundo_lanzador_muelle`, `cultista_alert_muelle`): con tres tipos de tirador más el engendro, el bot (que no esquiva) no lo superaba ninguna vez de 13.
    - **Equilibrio con bot (`circle`, nivel suelto):** en solitario 3 de 13; en cooperativo con 3 bots 8 de 9.
    - **Rendimiento** con 75 enemigos y 500 balas: 118 FPS de media y 60 en el 1 % peor.
    - **Probar:** `godot --path . -- level=p3_n3` (o `mid_at=6 final_at=30`). Capturas `shots/game_mue1_003.0s.png`, `shots/game_p33_012.0s.png` y `shots/engendro-profundo_30_eng2.png`.
  - **Hito 7.4 (nivel 4 de la parte 3, la tormenta en el Pacífico): hecho, pendiente de tu revisión (08-10-2026).**
    - **Peligros del escenario** (sistema nuevo, `Hazards`, `scripts/level/hazards.gd`; datos en `LevelData`, grupo "Peligros del escenario"; la partida lo crea si el nivel tiene alguno):
      - **Ángulos devoradores** (`angle_every`, `angle_radius`, `angle_warn`, `angle_time`, `angle_pull`, `angle_damage`): cada ~11 s se abre cerca de un jugador en pie, con aviso verde, una grieta de esquirlas negras y verdes en ángulos que no cuadran; atrae hacia su centro y engulle (vida y cordura por segundo) a quien queda dentro. No se matan; se cierran solos. Con `log=true`, "ANGULOS abiertos".
      - **Olas que barren la cubierta** (`wave_every`, `wave_width`, `wave_warn`, `wave_damage`, `wave_push`): franja azul de lado a lado que parpadea; al romper, daña y empuja medio segundo hacia el sur.
      - `Player.push`: velocidad externa de un paso (la suman los peligros; se consume en `_physics_process`).
      - Tests en `tests/test_hazards.gd`.
    - **La cosa blanca polipoide** (`tools/gen_polipo.py`, 32/m, partes del fragmento: `anim_fragmento`): racimo de bulbos blancos azulados translúcidos con alguna vena rosada, bocas redondas de pólipo con anillo de tentáculos y una pizca de luz, tentáculos largos y una corona arriba. Se arrastra a tirones (`crawl`) y suelta esporas. **La cosa blanca del lago oculto** (`polipo_madre`, a 2,4×) es el evento final: anillo con huecos, espiral de esporas, se divide en polipoides y aura.
    - **Atrezo nuevo** en `tools/gen_atrezo_alert.py`: `alr_borda` (borda baja con imbornales, del lado de la cámara) y `alr_puente` (superestructura del Emma con el puente encendido, chimenea y palo, 16/m).
    - **Arena** (`tools/gen_arena_tormenta.py` → `data/arenas/tormenta.json`, 56 x 40 m, mapa en `resources/maps/p3_n4.png`): cubierta de la goleta *Emma* muy mojada, el puente al norte, la borda al sur y al este, el mar embravecido más allá; faroles, botes, bolardos, cabos, fardos y barriles. Clima `tormenta`.
    - **Nivel `data/levels/p3_n4.tres`:** polipoides, Profundos, cultistas del *Alert* y diablos; `health_mult` 1,1; Ángulos cada 11 s y olas cada 16 s.
    - **Equilibrio con bot (`circle`, nivel suelto):** en solitario 4 de 10; en cooperativo con 3 bots 9 de 9 (también con el escalado de aparición normal). Se revisa en el 7.7.
    - **Rendimiento** con 75 enemigos y 500 balas: 119 FPS de media y 114 en el 1 % peor.
    - **Probar:** `godot --path . -- level=p3_n4` (o `final_at=15`). Capturas `shots/game_p34_008.2s.png` (un Ángulo abierto) y `shots/game_p34_013.0s.png` (una ola).
  - **Hito 7.5 (nivel 5 de la parte 3, R'lyeh emergida): hecho, pendiente de tu revisión (08-10-2026).**
    - **Criaturas** recoloreadas de modelos existentes (`tools/gen_rlyeh_criaturas.py`; si cambian `fragmento` o `engendro`, vuelve a ejecutarlo):
      - **Emanación de la puerta** (`emanacion`): el fragmento protoplásmico en verde gelatinoso con burbujas que brillan; repta a tirones.
      - **Primigenio menor** (`primigenio_menor`, a 1,5×): el engendro en piedra verdinegra con grietas de luz verde, como una estatua que despierta. `keep` con golpe de zarpa (2 avisos), anillo mixto con huecos y llamada de emanaciones. Sale dos veces como evento intermedio (100 y 180 s).
    - **Final: supervivencia** (el sistema del 6.3): 60 s de emanaciones que brotan de la puerta abierta. En el 7.6, Cthulhu.
    - **Atrezo** (`tools/gen_atrezo_rlyeh.py` → `models/rly_*.json`): la **puerta colosal** (18 x 14 m, jambas que no son paralelas, dintel torcido, losa negra entreabierta con una rendija de luz verde; 16/m exportada a 8/m), muros ciclópeos inclinados (8/m), monolitos torcidos en dos ejes, escaleras de escalones desiguales que suben a ninguna parte y bloques de caras torcidas.
    - **Arena** (`tools/gen_arena_rlyeh.py` → `data/arenas/rlyeh.json`, mapa en `resources/maps/p3_n5.png`): suelo `rlyeh` (del 7.0), la puerta al norte, muros al norte y al oeste, corales de luz verde, rocas en la orilla y el mar al sur y al este. Ángulos devoradores cada 14 s.
    - **Arreglado:** los golpes de zarpa, zambullidas y avisos retrasados guardaban al enemigo en la lambda; si moría antes, Godot avisaba "Lambda capture at index 0 was freed". Ahora guardan su `instance_id`.
    - **Equilibrio con bot (`circle`, nivel suelto):** en solitario 4 de 10; en cooperativo con 3 bots 8 de 8.
    - **Rendimiento** con 75 enemigos y 500 balas: 117 FPS de media y 60 en el 1 % peor.
    - **Probar:** `godot --path . -- level=p3_n5` (o `mid_at=5 final_at=30`).
  - **Hito 7.6 (jefe de la parte 3, Cthulhu): hecho, pendiente de tu revisión (08-10-2026).**
    - **Modelo** (`tools/gen_cthulhu.py`, 16/m, ~79.000 voxels huecos; en el juego a 1,15×, `anim_dagon`): de cintura para arriba, cabeza de pulpo con el manto echado atrás, mata de trece tentáculos sobre el pecho, ojos pequeños que brillan, cuerpo escamoso, brazos enormes con garras y alas estrechas de murciélago abiertas a la espalda.
    - **Combate:** `DagonBehavior` (del 6.6) con sus propios patrones (`cthulhu_llamada`, `cthulhu_espiral`, `cthulhu_anillo`) y emanaciones que salen como esbirros. Asoma por tres puntos delante de la puerta (`boss_spots` en `rlyeh.json`, a ~13 m del centro: a 22 m quedaba fuera del alcance de las armas y se atascaba en la fase 3).
    - **Se recompone:** es el evento final del nivel 5 (sustituye a la horda del 7.5) y `final_next` es `cthulhu_recompuesto` (menos vida, golpes y zambullidas más seguidos); al salir, la nube verde (`param cloud`: estallidos de `WadeSplash.burst` con color, nuevo parámetro `tint`) y la cámara tiembla. El nivel se supera al matar la segunda forma.
    - **Equilibrio con bot (`circle`, nivel suelto):** en solitario llega a Cthulhu pero no lo vence; en cooperativo con 3 bots, 3 de 5 (uno de los combates se alargó a 1.125 s). Vida 2.600 + 1.500. Se ajusta en el 7.7.
    - **Probar:** `godot --path . -- level=p3_n5 final_at=5`. Capturas `shots/game_cth3_010.0s.png` y `shots/cthulhu_30_cth1.png`.
  - **Hito 7.7 (cierre de la parte 3): hecho, falta tu partida (08-10-2026).**
    - **Medido encadenado** (`level=p3_n1 ... autonext=true autorestart=1 chain=true`, como el 6.7), sin compras, con `shop=3` (lo esperable tras dos partes) y en cooperativo con 3 bots.
    - **Ajustes:** el nivel 1 era un muro (3 de 20 en solitario) y los niveles 2 a 4 salían al 100 % llegando con el progreso. `health_mult` 1,0 / 1,25 / 1,25 / 1,25 / 1,15 (antes 1,1 / 1,12 / 1,08 / 1,1 / 1,15) y el nivel 1 con algo menos de ritmo.
    - **Resultado** (bot `circle`, que no esquiva; superados / intentos):

      | | N1 | N2 | N3 | N4 | N5 (Cthulhu) |
      |---|---|---|---|---|---|
      | Solitario, sin compras | 5/27 | 2/5 | 1/2 | 1/1 | 0/1 |
      | Solitario, `shop=3` | 6/14 | 5/6 | 4/5 | 3/3 | 0/3 (1/3 en la primera ronda) |
      | Cooperativo, 3 bots | 7/9 | 6/7 | 5/6 | 4/4 | 2/4 |

    - **Rendimiento** con 75 enemigos y 500 balas: 117-119 FPS de media en los cinco; el 1 % peor, 118, 60, 60, 68 y 114.
    - **Biblioteca:** todas las criaturas y los cinco lugares de la parte 3 tienen texto y mapa (lo comprueba `test_content`).
    - **Falta tu partida** de la parte 3 para cerrarla. Capturas `shots/game_p35_045.0s.png` (la horda) y `shots/rly_puerta-rly_monolito-rly_escalera-rly_bloque_30_rlp1.png`. Capturas `shots/game_dag6_008.0s.png` y `shots/dagon_30_dg1.png`.
- **Fase 0: hecha.** GDD, hoja de ruta y las nueve decisiones que bloqueaban las fases 1 y 2.
- **Fase 1: hecha** (queda tu partida de 5 minutos como comprobación). Subhitos en `docs/ROADMAP.md`.
  - **Hito 1.1 (base técnica): hecho y aprobado.** Forward+ con el entorno recalibrado, GUT 9.4.0, caché de mallas, capturas por tiempo (`ShotTaker`) y escena de rendimiento (`scenes/bench.tscn`, medición en `docs/RENDIMIENTO.md`).
  - **Hito 1.2 (modelos nuevos): segunda versión, pendiente de revisión.** Dyer, pingüino albino ciego, fragmento protoplásmico y atrezo del campamento, con sus animaciones en `scripts/anim/`.
    - Rechazados en la primera revisión: Dyer ("ni siquiera parece una persona": demasiado relieve y cara horrible) y el pingüino ("no parece un pingüino"). Rehechos con el enfoque de las lecciones "Personajes humanos" e "Identidad de un animal".
    - Hojas de revisión en `shots/revision_1_2_modelos_v2.png` y `shots/revision_1_2_animaciones_v2.png`, y GIF en `shots/anim_*_v2.gif` (se regeneran; `shots/` no va a git).
  - **Hito 1.3 (jugador, entrada, cámara y arena): hecho.** Ya se puede jugar a moverse y esquivar por el campamento con `godot --path .`: teclado (WASD o flechas, espacio para esquivar) o mando (stick izquierdo o cruceta, A para esquivar). Todavía no hay enemigos activos, disparos ni menús; para salir, cierra la ventana.
  - **Hito 1.4 (balas, daño y armas): hecho.** Balas en arrays con un único MultiMesh, lenguaje visual de los tres tipos de daño, revólver y dinamita con apuntado por datos, patrones de disparo enemigos como datos, avisos en el suelo, explosiones y muñecos de práctica. Clip en `shots/combate_1_4.gif`.
  - **Hito 1.5 (enemigos y nivel): hecho.** `godot --path .` ya juega el nivel 1 de la parte 1:
    - Oleadas de pingüinos y fragmentos que aparecen fuera de cámara, persiguen y disparan.
    - En el minuto 4, el Acechador como evento final: ronda, salta con aviso y croa.
    - El nivel se supera al matarlo.
    - Clip en `shots/evento_final_1_5.gif`.
  - **Hito 1.6 (progresión, cordura y HUD): hecho.** La partida ya es completa:
    - Gemas de experiencia que se recogen al acercarse, subida de nivel con elección de 1 entre 3 mejoras (la partida se pausa) y cinco pasivas.
    - Cordura con recuperación pasiva y crisis de parálisis intermitente.
    - HUD del J1 con retrato, vida, cordura, experiencia, armas y recarga del esquive, más reloj y objetivo arriba.
    - Pausa con Esc o Start, pantalla de caída y de nivel superado, y reinicio.
  - **Hito 1.7 (rendimiento y cierre): prueba de carga hecha, pendiente de que juegues tú.**
    - 150 enemigos y más de 1.000 balas a 129 FPS de media en Forward+ (86 en el 1 % peor) y a 108 en Compatibility (`docs/RENDIMIENTO.md`).
    - Ritmo ajustado con un bot: el nivel se supera en unos 5,5 minutos.
    - **Falta el criterio de aceptación de la fase 1:** que juegues tú una partida de 5 minutos, con doble clic en `jugar.cmd` o con `godot --path .`.
    - **Primera partida de prueba (25-09-2026), cambios aplicados:**
      - Silueta sin brazos vistos a través del cuerpo.
      - Suelo de nieve blanca.
      - Pingüinos un 20 % más pequeños y solo cuerpo a cuerpo.
      - Menús con A en el mando.
      - Muchos menos enemigos al principio.
      - Disparo continuo, con el revólver desde el inicio.
    - **Segunda partida de prueba, cambios aplicados:**
      - Sin vibración al moverse (interpolación de física).
      - Lanzar dinamita ya no congela las piernas (animación por capas).
      - Esquive nuevo: deslizamiento sobre la nieve, con fundidos y frenado suave.
      - Gemas doradas talladas.
      - Tiendas verdes grisáceas de cumbrera.
      - Iglú, cabaña de troncos y bloques de hielo en el campamento.
      - Carga de la partida en 0,17 s gracias a la caché de mallas.
    - **Cinco estilos de esquive**, uno por personaje: deslizamiento, voltereta, plancha de pingüino, salto y destello, con datos en `data/dodges/` (`DodgeStyle`). F1 los recorre en partida y `dodge=<id>` elige uno al arrancar. Pendiente de decidir cuál lleva cada personaje.
- **Todavía no hay código de juego:** solo el visor, la escena de rendimiento y los generadores de modelos.
- **Decidido el 25-09-2026 para la fase 5:**
  - Estructura de menús, tienda con progresión permanente y compañeros al estilo de Extremadura Survivors (D-09, D-20; GDD 8.1).
  - Portada animada en Godot (D-21; GDD 7.1).
  - Orden: cerrar la fase 1 con tu partida, después el cooperativo (fase 2) y luego la fase 5.
- **Pantalla de título (adelantada de la fase 5): segunda versión, pendiente de tu revisión.**
  - Es tu ilustración de la biblioteca, animada en 2D, con tu imagen del título encima.
  - Se abre con `godot --path .` sin argumentos o con `-- title`; hay vídeo con música en `shots/portada_2d_v3.mp4`.
  - Cambios de la primera revisión (26-09-2026):
    - Velas y farolillos separados. En las velas solo baila la llama, anclada en la mecha; los farolillos no se mueven, solo respiran su cristal y su halo.
    - Niebla del suelo rehecha: bancos grandes y suaves en perspectiva, sin grano.
    - Sin nubes en el ventanal.
    - Entrada del título desde una niebla con su silueta que se deshace a jirones.
    - Ceniza que cae por toda la sala.
  - Segunda revisión: niebla del suelo con movimiento bien visible (antes variaba un 1,8 % y no se percibía; ahora, un 20 %) y ceniza en tres tamaños y más abundante.
  - La portada 3D anterior (montañas y título voxel) se quitó; queda en el historial de git (commit `4809adb`).
- **Pantalla completa por defecto** (exclusiva, a la resolución del monitor). Las ejecuciones de prueba (`shots=`, `perf=`, `bot=`, visor, banco de pruebas y `--write-movie`) van en ventana; `window=true` y `fullscreen=true` lo fuerzan. La interfaz escala desde 1920×1080 (`stretch` en modo `canvas_items`). A 4K con 150 enemigos y 1.400 balas: 130 FPS de media.
- **Menú de depuración:** en la pausa, botón "Depuración". Permite cambiar:
  - Personaje, esquive, invulnerabilidad y velocidad al andar; vida, cordura y subida de nivel.
  - Nivel de cada arma (o quitarla) y de cada pasiva.
  - Enemigos en pantalla (los del nivel, 10, 50, 100 o 300), tipo, pausa de oleadas, matar a todos y lanzar el evento final.
  - Velocidad del juego, altura de la cámara, información en pantalla y música.
  - Los ajustes se conservan al reiniciar hasta "Restablecer todo".
- **Música:** en `resources/Music/`. La intro suena en la portada y `Musica_nivel1.mp3` en el nivel 1; los niveles sin música propia usan esa (`LevelData.music`).
- **Pendiente de confirmar:** si la regla "sin tiaras ni joyas" de los Profundos se limita a las criaturas (GDD, sección 13, punto 5).

## Decisiones cerradas

- **Motor:** Godot 4.4.
- **Género:** bullet hell con disparo automático y progresión tipo "survivors", cooperativo local de 1 a 4 jugadores. Diseño completo en `docs/GDD.md`.
- **Ambientación:** mitos de H. P. Lovecraft. Son de dominio público en España y la UE; solo hay que evitar el nombre comercial "Call of Cthulhu" (marca de Chaosium).
- **Cámara:** ortográfica isométrica fija (rotación -30° en X, 45° en Y).
- **Estilo gráfico:** voxel 3D detallado, "Minecraft mejorado", a 32 voxels por metro de juego (`VOXEL = 0.03125`).
- **Diseño de personajes (humanos: jugables, cultistas, híbridos):** a bloques limpios, con detalles pintados y casi sin relieve (decidido el 25-09-2026 tras rechazar un Dyer esculpido). Las criaturas pueden seguir siendo orgánicas, como el Acechador.
- **Diseño de los profundos:** clásicos, oscuros, sin ropa ni adornos externos (nada de tiaras ni joyas). Solo anatomía: escamas, púas, aletas, agallas, garras.
- **Atmósfera:** oscuridad, luz de luna fría, luz cálida puntual, contraluz verdosa, niebla ligera.

### Estilos probados y descartados
- 3D chibi liso (modelado SDF + marching cubes), tanto en versión simpática como oscura: descartado en favor del voxel.
- Three.js / HTML5: descartado en favor de Godot.

## Pipeline de arte

1. **Generador en Python** (`tools/`): construye el personaje como un conjunto de voxels a partir de primitivas (elipsoides, cápsulas, conos), luego colorea (degradado dorsal/flanco/vientre, escamas, manchas por ruido) y talla detalles sobre la superficie real (boca, dientes, ojos, agallas, cresta). Los generadores nuevos usan **`tools/voxlib.py`**:
   - Clase `Model` con las primitivas (`ell`, `sell`, `capsule`, `cone`, `box`, `line`), búsqueda de superficie por columna (`front`, `top`, `exposed`), ruido y `export`.
   - Se modela en unidades base (1 ub = 1/16 m) y la resolución es el parámetro `S`: 2 voxels por ub = 32 voxels/m.
   - El superelipsoide `sell` (p≈2,5–3) da caras planas para ropa, madera y piedra.
   - `vbox` y `bevel` sirven para diseñar a bloques en coordenadas voxel, como los personajes humanos. Con `export(..., pivots_in_voxels=True)` los pivotes también van en voxels.
   - `export(..., roughness=, specular=)` fija el material del modelo. Sin indicarlos queda piel húmeda (0,38 / 0,6); la ropa, las plumas y el atrezo van mates (~0,9 / 0,25).
2. **Salida JSON** (`models/*.json`): `voxels` = lista de `[x, y, z, parte, r, g, b, glow]`, `pivots` = pivote por parte, en coordenadas voxel, y `voxel_size` (metros por voxel, opcional; por defecto 1/32). Un pivote sin voxels, como `light` en el farol, sirve para marcar puntos.
3. **`scripts/voxel_builder.gd`**: convierte el JSON en mallas con eliminación de caras ocultas y oclusión ambiental por vértice. Crea un nodo por parte con su pivote (`torso`, `head`, `arm_l`, `arm_r`, `leg_l`, `leg_r`) y separa los voxels `glow=1` en una capa sin sombreado (ojos, bioluminiscencia, brillos). Las mallas se construyen una vez por modelo y todas las instancias las comparten; la primera construcción del Acechador tarda unos 200 ms.
   - **Caras ocultas:** solo se quitan las que tapa un voxel de la misma parte. Entre partes distintas se conservan todas: al girar un brazo, una pierna o la cabeza queda al aire lo que tapaban. Antes se quitaban las "enterradas" (dos voxels de otra parte delante), y con el brazo de 5 voxels pegado al tronco el costado se veía hueco al andar.
   - **Material:** sale del `roughness` y el `specular` del JSON.
   - **Caché en disco:** las mallas construidas se guardan en `user://voxcache/` (`VoxelMeshCache`). La clave depende de la fecha y el tamaño del JSON y de `VoxelBuilder.BUILDER_VERSION`. Una cabaña de 100.000 voxels tarda 1,7 s en construirse y unos milisegundos en cargarse de la caché. **Sube `BUILDER_VERSION` si cambias cómo se construyen las mallas.** La partida precarga los modelos de todos los enemigos del nivel al empezar.
4. **Animación:** rotando los nodos-parte desde código (sin rigging).
   - Cada tipo de modelo tiene su script en `scripts/anim/` (`anim_profundo`, `anim_humano`, `anim_pinguino`, `anim_fragmento`), con funciones estáticas por animación y la constante `DURATION`.
   - Se aplican con `Anims.pose(modelo, animación, nodo, t)`, con t de 0 a 1. `Anims.reset()` devuelve todas las partes al reposo, incluida la raíz del modelo.
   - Por eso el giro y la posición de un modelo van siempre en un nodo contenedor, nunca en la raíz.

Entorno de desarrollo (Windows 11 + Git Bash):
- **Godot 4.4.1** en `C:\Tools\Godot\`. El comando `godot` ejecuta `Godot_v4.4.1-stable_win64_console.exe`, para que la salida aparezca en la terminal. En Git Bash lo resuelve el lanzador `~/bin/godot`; en PowerShell y cmd, `C:\Tools\Godot\godot.cmd` (la carpeta está en el PATH de usuario).
- **Python 3.12** como `python`. En Windows, `python3` abre la Microsoft Store en lugar de ejecutar el script.
- No hace falta xvfb: las capturas abren una ventana un momento y se cierran solas.

Uso desde la raíz del proyecto, en Git Bash:
```
./jugar.cmd                         # o doble clic en jugar.cmd: partida sin consola
godot --path .                      # portada (escena principal: scenes/main.tscn, que elige la escena según el primer argumento)
godot --path . -- select saves=demo_saves slot=2 join=2   # selección de personaje con dos jugadores de prueba
godot --path . -- bot=circle dodge_every=2 demo=14 shots=1,3 tag=prueba   # partida con bot, criaturas de muestra y capturas
godot --path . --write-movie shots/mov/f.png --fixed-fps 30 --quit-after 240 -- bot=circle   # vídeo en fotogramas PNG
godot --path . --disable-vsync -- bot=circle demo=14 perf=8                 # rendimiento de la partida
python tools/gen_acechador.py       # regenera models/acechador.json
python tools/gen_variantes.py       # regenera clasico, bruto, acechador (versión simple) y abisal
python tools/gen_dyer.py            # Dyer (personaje jugable); igual gen_pinguino.py y gen_fragmento.py
python tools/gen_olmstead.py        # Olmstead; igual gen_legrasse.py, gen_johansen.py, gen_peaslee.py, gen_varga.py, gen_whipple.py y gen_blake.py (base común en tools/cuerpo.py; tools/humano.py ya no se usa)
python tools/gen_atrezo_campamento.py   # models/atrezo_{tienda,caja,bidon,farol,roca,hielo}.json
godot --headless --path . --import                # reconstruye la caché de .godot/ (primera vez, tras borrarla o al crear un class_name)
godot --path . -- still <yaw> <modelo>            # captura en shots/<modelo>_<yaw>.png (encuadre automático)
godot --path . -- anim <yaw> <modelo> <animación>  # fotogramas en shots/<modelo>_<animación>_NNN.png
godot --path . -- still 0 lineup                  # los cuatro profundos juntos
godot --path . -- still 0 dyer,pinguino,fragmento,acechador   # cualquier grupo, separado por comas
godot --path . -- still 0 lineup fog_density=0.03 moon.light_energy=0.6 tag=prueba   # ajustes de entorno y luces al vuelo
python tools/gen_mascaras_portada.py              # máscaras de la portada y niebla del título
godot --headless --path . -s addons/gut/gut_cmdln.gd                                 # tests (GUT 9.4.0, configuración en .gutconfig.json)
godot --path . scenes/bench.tscn --disable-vsync --resolution 1920x1080 -- count=150 model=acechador   # rendimiento (docs/RENDIMIENTO.md)
```
- **Capturas:** van a `shots/`, que Godot ignora (`.gdignore`) y git también. Añade `--rendering-method gl_compatibility` a cualquier comando para usar el renderizador de reserva.
- **Argumentos:** las escenas leen lo que va detrás de `--` con `LaunchArgs` (`scripts/core/launch_args.gd`): posicionales, `clave=valor` y banderas `--clave`.
- **Opciones de la partida** (`scripts/core/game.gd`):
  - `bot=circle|zigzag|idle` y `dodge_every=` (s): jugador automático.
  - `shots=` y `tag=`: capturas.
  - `cam=`: altura visible en m (por defecto 15).
  - `demo=N`: criaturas de muestra quietas.
  - `pos=x,z`: posición inicial del jugador.
  - `perf=N`: mide el rendimiento N segundos.
  - `fogvol=false`: quita los halos de niebla.
  - `--debug`: imprime la posición del jugador.
  - `dodge=deslizar|rodar|plancha|salto|destello`: estilo de esquive (F1 los recorre en partida).
  - `dummies=N`: muñecos de práctica que reciben daño.
  - `emitters=true`: tres emisores de prueba, uno por tipo de daño.
  - `weapons=dinamita,revolver` y `wlevel=N`: armas iniciales y su nivel.
  - `god=true`: el jugador no recibe daño.
  - `bullet_rain=N`: mantiene N balas enemigas vivas (prueba de carga).
  - `level=p1_n1`: nivel a jugar (por defecto). `nolevel=true` deja el campo de pruebas sin oleadas.
  - `timescale=N`: acelera el juego. Las capturas de `shots=` usan tiempo de juego.
  - `final_at=s`: adelanta el evento final.
  - `max_alive=N` y `spawn_rate=N`: tope de vivos y ritmo de aparición fijo (pruebas de carga).
  - `autopick=true`: elige sola la primera mejora (para bots y capturas).
  - `xp=`, `hp=` y `san=`: experiencia, vida y cordura iniciales.
  - `autorestart=N`: en la pantalla final, reintenta sola tras N s.
  - `log=true`: cada 30 s de juego imprime vivos, abatidos, nivel, vida, cordura y balas.
  - `prof=true` (junto con `perf=`): reparto del tiempo de CPU por sistema (`Prof`).
  - `mute=true`: sin música (también en la portada).
  - `test_save=N`: crea la partida de pruebas (todo desbloqueado) en el hueco N y sale.
  - `saves=carpeta`: otra carpeta de partidas dentro de `user://` (capturas y pruebas sin tocar las tuyas). `slot=N`: juega con ese hueco.
  - `window=true` / `fullscreen=true`: fuerza ventana o pantalla completa.
  - `debug_menu=N`: abre la pausa y el menú de depuración a los N s (capturas).
- **Encadenar comandos:** un `godot ... | grep error` devuelve 1 cuando no hay errores, así que no lo encadenes con `&&`.

Nota: `gen_variantes.py` también escribe un `acechador.json` genérico que sobrescribiría el detallado. Ejecuta `gen_acechador.py` después, o renombra la salida.

## Pantalla de título (`scenes/title.tscn`, `scripts/title/`)

Tus imágenes en `resources/PantallasMenus/`: `fondo_titulo_sin_texto_1080p_definitivo.png` (en realidad a 4K, con mipmaps activados en su `.import`) y `Texto_titulo.png`. `fondo_con_titulo_completo.png` es solo la referencia de composición.

- **Máscaras** (`tools/gen_mascaras_portada.py`: analiza la ilustración en 4K y escribe a 1920×1080; revisión en `shots/mascaras_revision.png`):
  - `mascara_velas.png`: R, llama de cada vela, cortada en el cuello de la mecha (sin cera); G, fase propia de cada vela, extendida a la zona que ilumina; B, cuánto baila cada punto (0 en la base, 1 en la punta, escalado por el tamaño de la llama; las lejanas y los reflejos no bailan).
  - `mascara_luces.png`: R, cristal de los farolillos; G, su halo; B, luz proyectada por las velas.
  - `mascara_zonas.png`: R, cielo claro del ventanal; G, niebla del suelo; B, cristal del ventanal.
  - `Texto_titulo_niebla.png`: el alfa del título difuminado, con el margen `TITLE_PAD` (0,14, el mismo que en `title_screen.gd`).
  - Los farolillos son una lista de posiciones revisada a mano (`LANTERNS` en el script).
  - **Si cambia la ilustración, vuelve a ejecutar el script y revisa esa lista.** Las posiciones de la luna y los ojos están en la configuración.
- **Capas** (todas en un "escenario" de 1920×1080 que cubre la pantalla conservando la proporción):
  - `background.gdshader`: velas que parpadean con fase propia, llama que baila desde la mecha y luz proyectada que oscila con ella; farolillos que respiran despacio (cristal y halo).
  - `floor_fog.gdshader`: bancos de niebla suaves que aclaran y oscurecen la niebla pintada (mezcla premultiplicada).
  - `window_sky.gdshader`: halo de la luna, relámpago y ojos.
  - Ceniza con tres `GPUParticles2D`: copos lejanos pequeños, medianos y unos pocos cercanos, grandes y desenfocados. Pasa **por delante del título**: va en su propio escenario (`ash_stage`), con el mismo encaje y acercamiento que la ilustración, pero dibujado después del título.
  - El título (`title_halo.gdshader`: niebla con su silueta, letras que se condensan, niebla que se deshace y halo fino) y el aviso van fuera del escenario, así que el acercamiento no les afecta.
- **Configuración por efecto** (`data/title/portada.tres`, `TitleScreenConfig`): cada efecto tiene su interruptor y sus parámetros. Son velas, farolillos, niebla, luna, relámpago, ojos, acercamiento, ceniza, título, halo, niebla del título, aviso y música.
  - Para compararlos sin tocar la configuración: `godot --path . -- title off=niebla,ceniza`. Nombres: velas, farolillos, niebla, luna, relampago, ojos, acercamiento, ceniza, titulo, halo, niebla_titulo, aviso y musica.
  - Otras opciones: `shots=`, `tag=`, `t=` (empezar en ese segundo), `strike=` (relámpago), `eyes=` (brillo de ojos) y `perf=`.
  - Para capturas de los menús, `open=` abre una ventana al terminar la presentación: `slots` (huecos), `slots_borrar` (con la confirmación de borrado), `menu` (menú principal), `menu_jugar` o `menu_config` con `tab=0..3`. Úsalo con `saves=demo_saves`, que tiene una partida de ejemplo en el hueco 2.
- **Controles:** cualquier botón principal (A, B, X, Y, Start, Select; Intro, Espacio o Esc) salta la presentación y, con "Pulsa Start" visible, abre la ventana de huecos. Al elegir hueco se abre el menú principal; "Jugar en local" entra en la partida hasta que exista la selección de personaje (hito 2.3).
- **Variación medida** (desviación típica en % del brillo): llamas 6,4 %, paredes iluminadas 4,4 %, cielo 2,3 %, niebla del suelo 20 % y resto por debajo del 1 %. Sutil a propósito. Coste: 0,42 ms por fotograma.

## Arquitectura del juego

- **Entrada** (`scripts/input/`): los personajes nunca leen `Input`. Cada jugador tiene un `PlayerInput`:
  - `KeyboardInput`, `JoypadInput(dispositivo)` o `BotInput(patrón)`, y `CombinedInput` para unir varias fuentes (J1 = teclado + mando 0).
  - Se leen los dispositivos directamente, sin las acciones globales de Godot, que mezclarían los mandos en local.
  - Las teclas y botones son datos: `InputBindings`, en `data/input/bindings_default.tres`.
- **Interpolación de física** (activada en `project.godot`): la física va a 60 Hz y el dibujo, a la frecuencia del monitor. Reglas:
  - Lo que se mueve en `_physics_process` (jugador, enemigos, dinamita) se interpola solo.
  - Lo que se mueve o se anima en `_process` lleva `physics_interpolation_mode = OFF`. Es el caso de los nodos `Visual` del jugador y de los enemigos, de la cámara, de los muñecos de práctica y del `SubViewport` del retrato.
  - **Un nodo sin interpolación dentro de un cuerpo que se mueve en la física se dibuja en la posición del último paso de física, no en la interpolada.** Por eso el `Visual` del jugador y de los enemigos va con `top_level = true` y en cada `_process` se coloca en `get_global_transform_interpolated()`. Dentro del cuerpo, el modelo avanzaba a saltos de 3 px adelante y atrás a 120 Hz: una vibración que no sale en las capturas.
  - La cámara sigue `get_global_transform_interpolated()`.
  - Balas y gemas (MultiMesh) interpolan a mano entre la posición anterior y la actual con `Engine.get_physics_interpolation_fraction()`.
  - Al aparecer, `reset_physics_interpolation()`.
  - **Todo lo visual debe avanzar con el reloj de fotograma, no con contadores de física:** el esquive usaba `motor.dodge_time` y la pose avanzaba a saltos.
  - Métrica de suavidad: `jitter=true` con `bot=right` o `bot=up`. Sin interpolación daba 1,00; con ella, 0,03. **Ojo: mide la posición interpolada del cuerpo, no lo que se dibuja**, y por eso no detectó la vibración del modelo.
  - Para medir lo que ve el ojo: graba a la frecuencia del monitor (`--write-movie ... --fixed-fps 120 -- bot=right god=true nolevel=true mute=true`) y sigue un color del modelo fotograma a fotograma. Si el desplazamiento alterna de signo (+3, −3…), algo se dibuja a saltos.
- **Animación del jugador:** capas. Una base (reposo, andar o esquive) con fundido de 0,06 a 0,22 s al cambiar (`Anims.snapshot` y `blend_from`), y encima el gesto de lanzar solo en brazos y torso (`Anims.overlay`). La cadencia de andar es proporcional a la velocidad real, para que los pies no patinen. El esquive (su animación sale del `DodgeStyle` del personaje: `slide`, `roll`, `dive`, `jump` o `flash`) es una acción que dura lo que su animación, que puede ser más que el impulso: la voltereta termina de rodar ya a velocidad de andar. El impulso frena progresivamente hasta la velocidad de andar. Para comprobar la fluidez se comparan posiciones reales de puntos del cuerpo, no ángulos, que en una voltereta pasan de +180° a −180°. `tests/test_player_anim.gd` comprueba que ninguna parte salte entre fotogramas.
- **Atributos** (`Attributes`): nombres, fórmulas (`FORMULAS`), escala (`mult`) y subida ponderada (`roll_point`). El jugador guarda `attrs_level1` (fijos) y `attrs` (actuales). Las estadísticas de `Player.data` nunca se tocan a mano: se cambian los atributos, las pasivas o el esquive y se llama a `rebuild_stats()`.
- **Jugador** (`scripts/player/`):
  - `CharacterData` (`.tres` en `data/characters/`) guarda el perfil del personaje.
  - `PlayerMotor` es la lógica pura de movimiento relativo a la cámara y del esquive (impulso, invulnerabilidad y recarga), con tests.
  - `Player` (un `CharacterBody3D`) aplica esa lógica, orienta y anima el modelo, dibuja el anillo de color, lleva un farol propio (`CarryLight`) y muestra su silueta cuando lo tapa el decorado (`occluded_silhouette.gdshader`).
- **Cámara** (`GameCamera`): ortográfica isométrica que sigue a sus objetivos, con 15 m de altura visible por defecto.
- **Combate** (`scripts/core/`, `scripts/bullets/`, `scripts/weapons/`, `scripts/fx/`):
  - `CombatWorld` registra jugadores y enemigos, reconstruye la rejilla espacial (`SpatialGrid`) en cada paso de física y contiene las balas y los efectos.
  - Un objetivo es cualquier nodo con `hit_radius`, `take_damage(Damage)` e `is_alive()`.
  - `Damage` tiene una parte física (resta vida) y otra mental (resta cordura); su tipo se deduce de esas partes.
  - `BulletManager` guarda todas las balas en arrays compactos y las dibuja con dos MultiMesh: las trazadoras del jugador (cuadrados con `bullet.gdshader`) y las enemigas en voxel (`BulletMeshes.orb()`, un núcleo de 19 cubos y un anillo de 14, con `bullet_voxel.gdshader`). El shader enseña unos grupos de cubos u otros según el tipo de daño. Las tapadas se dibujan con la segunda pasada (`bullet_voxel_hidden.gdshader`). Las balas del jugador chocan contra la rejilla de enemigos; las enemigas, contra los jugadores. Cada bala lleva su empuje y los rasgos de daño de quien la dispara.
  - Las armas son datos (`WeaponData`, en `data/weapons/`): cadencia, alcance, apuntado (D-05), entrega y mejoras por nivel (`"damage*": 1.25`, `"count+": 1`). `WeaponSystem`, dentro del jugador, las dispara solas.
    - Entregas: `BULLET` (balas; con `split_count` se abren en chispas y con `jitter_deg` son erráticas), `THROWN` (lanzados en arco, `ThrownExplosive`: explosión, zona o bengala al caer), `MELEE` (tajo del machete, `Slash`), `ORBIT` (páginas que giran alrededor, `OrbitRing`), `BEAM` (rayo recto, `Beam`), `WAVE` (onda que empuja y aturde, `Shockwave`) y `FLAME` (chorro del lanzallamas, `FlameJet`).
    - Zonas en el suelo (`DamageZone`, `WeaponData.zone`): fuego o ácido, con daño por tics. Estados de los enemigos: aturdido (`stun`), vulnerable (`make_vulnerable`, +25 % de daño) y atraído (`lure`, las élites no).
    - Las arcanas cuestan cordura (`sanity_cost`, multiplicado por `CharacterData.arcane_cost_mult`).
  - Los patrones enemigos también son datos (`BulletPattern`, en `data/patterns/`): radial o en abanico, ráfagas, giro y aviso previo. `PatternRunner` los ejecuta.
  - Efectos: `Telegraph` (aviso en el suelo) y `Explosion`.
  - Para pruebas: `TrainingDummy` (objetivo de práctica) y `TestEmitter` (dispara un patrón).
- **Enemigos** (`scripts/enemies/`):
  - `EnemyData` (`.tres` en `data/enemies/`) define cuerpo, contacto, comportamiento con sus parámetros, patrón de ataque y escalón.
  - `Enemy` lo aplica: separación de los demás, rodeo del decorado con `ObstacleMap` (sin cuerpo físico), daño por contacto, disparo, destello, retroceso y muerte con `DeathBurst`.
  - Los comportamientos son clases de `EnemyBehavior`:
    - `CrawlBehavior` (fragmento): persigue a tirones.
    - `BlindBehavior` (pingüino): va hacia donde oyó al jugador y embiste.
    - `StalkBehavior` (Acechador): ronda, salta con aviso y croa.
- **Nivel** (`scripts/level/`):
  - `LevelData` (`.tres` en `data/levels/`) define arena, grupo de enemigos, ritmo de aparición por tiempo, topes y evento final. Pesos 2^(N−t).
  - `WaveDirector` hace aparecer enemigos fuera de cámara, lanza el evento final y emite `level_completed` al morir su enemigo.
- **Progresión** (`scripts/progression/`):
  - `ProgressionData` (`data/progression/default.tres`) define la curva de experiencia y los parámetros de cordura y crisis.
  - `PlayerProgress` lleva nivel, experiencia, subidas pendientes, las tres opciones al azar y su aplicación.
  - Las mejoras pasivas son `UpgradeData` (`data/upgrades/`) y cambian una estadística de la copia del `CharacterData` de cada jugador (`Player.setup` la duplica).
  - `GemManager` gestiona las gemas con arrays y un MultiMesh, como las balas.
- **Cordura** (`SanityState`): recuperación pasiva lejos de enemigos y sin daño mental reciente; crisis a cero; parálisis intermitente que bloquea el `PlayerMotor`; al terminar, recupera el 30 %.
- **Guardado** (`scripts/save/`):
  - `Saves` (autoload) lleva tres huecos en `user://saves/slot_N.json` y la partida en uso (`Saves.current`, un `SaveData`).
  - Guarda en un fichero temporal y lo renombra, para no dejar una partida a medias si el juego se cierra a mitad.
  - `SaveData` tiene número de versión y `migrate()`: si cambias el formato, sube `VERSION` y añade el paso de migración.
  - La partida guarda al caer, al superar el nivel, al reiniciar y al salir. Sin hueco elegido (arrancando la partida directamente) no se guarda nada.
- **Dispositivos y sesión:**
  - `Devices` (autoload en `scripts/input/device_manager.gd`) guarda el último dispositivo usado (`KEYBOARD` = −1, o el número del mando), avisa al conectar o desconectar un mando, crea la entrada de partida de un dispositivo (`make_input`) y define los colores de los jugadores (`COLORS`).
  - `GameSession` (estático, en `scripts/core/game_session.gd`) lleva de los menús a la partida quién juega (dispositivo, GUID, personaje y compañero) y en qué nivel. Vacía, la partida usa sus opciones de siempre.
- **Selección de personaje** (`scenes/select.tscn`, `scripts/menus/character_select.gd`):
  - La lógica está en `SelectState` (sin dibujo, con tests).
  - La entrada se lee por dispositivo en `_input`, sin el foco de Godot, que es uno para toda la pantalla.
  - El mapa de niveles es `LevelMap`, sobre `Campaign` (`data/campaign.json`).
  - Cada jugador gira su modelo con LB/RB (Q/E con el teclado) mientras los mantiene, para verlo de lado y de espaldas; al cambiar de personaje vuelve a mirar al frente. Los compañeros girarán igual cuando tengan modelo.
  - Opciones para capturas: `join=N` (jugadores de prueba), `ready=N`, `turn=grados`, `map=true` y `auto_start=true`.
- **Configuración** (`Settings`, autoload en `scripts/save/settings.gd`): común a los tres huecos, en `user://settings.json`.
  - Aplica vídeo y audio (crea los buses `Musica` y `Efectos`).
  - `Settings.bindings()` da los controles de fábrica más los reasignados; la partida los usa para el teclado y los mandos.
  - `dev_window` (ejecuciones de prueba en ventana) y `force_fullscreen` los pone `main.gd` y no se guardan.
- **Menús de fuera de la partida** (`scripts/menus/`):
  - `MenuKit`: fuente de la portada, ventanas centradas y `Confirm`, para confirmar con el foco en "no".
  - `SlotMenu` (huecos), `MainMenu` (menú principal y ventana de Jugar) y `SettingsMenu` (pestañas).
  - `OptionRow` (`scripts/ui/`): fila con valor que se cambia con izquierda/derecha. La usan la configuración y la depuración.
  - La portada (`TitleScreen`) lleva el flujo: presentación, huecos y menú principal. `TitleScreen.skip_to_menu` hace que, al volver de la partida, entre directamente en el menú.
- **Música** (`Music`, autoload en `scripts/core/music.gd`): sobrevive a los cambios de escena, funde una pista con la siguiente y no corta la que ya suena si se vuelve a pedir (al reiniciar). `mute=true` la silencia; úsalo en bots y capturas.
- **Depuración** (`DebugOptions` en `scripts/core/debug_options.gd`, `DebugMenu` en `scripts/ui/debug_menu.gd`): los ajustes van en una variable estática, así que sobreviven a `reload_current_scene`; `game.gd` los aplica al montar la partida (`DebugOptions.apply_all`).
  - Las pasivas se rehacen desde el personaje original (`rebuild_stats`), así que también se pueden bajar.
  - El director tiene `target_alive`, `spawning_paused`, `pool_override` y `trigger_final()`.
  - Las listas (personajes, esquives, armas, enemigos) se leen de sus carpetas en `data/`: lo nuevo aparece solo.
- **Interfaz** (`scripts/ui/`):
  - `UiKit`: estilo común y barras con estela.
  - `Hud`: panel del J1 y cabecera. El retrato sale de un `SubViewport` que renderiza la cabeza del modelo.
  - `Menus`: subida de nivel, pausa y pantalla final.
  - `pause_watch.gd` atiende Esc o Start también con la partida en pausa.
- **Arena** (`scripts/level/arena_builder.gd`):
  - Borde de la arena: nunca vacío. En el campamento, la Barrera de Ross al norte y al oeste (`tools/gen_barrera_hielo.py`: tres tramos de acantilado de hielo repetidos y solapados, con una meseta nevada detrás) y el mar al sur y al este (`sea.gdshader`: agua en baldosas de 0,5 m con oleaje, destellos de luna y espuma). Lo que queda más allá de la orilla flota a la altura del agua. Cada nivel usará bordes de su temática (muros, acantilados, agua).
  - Monta un JSON de `data/arenas/` (generado por `tools/gen_arena_campamento.py`) con el suelo de nieve, el mar, las piezas con su colisión, una luz y un halo de niebla por farol, y los límites invisibles.
  - Capa 1: mundo. Capa 2: jugadores.

## Personajes jugables modelados

| Personaje | Estado | Concepto |
|---|---|---|
| **Robert Olmstead** | Hito 2.4 (`gen_olmstead.py`), 7.100 voxels | Joven viajero: gorra de plato de tweed, chaqueta de tweed gris verdoso, chaleco, camisa blanca y corbata azul, pantalón pardo y un revólver en la cadera. Revólver, voltereta larga, resistencia a las criaturas marinas. |
| **John R. Legrasse** | Hito 2.4 (`gen_legrasse.py`), 7.600 voxels | Inspector: fedora gris marengo de ala ancha, gabardina corta gris piedra abierta sobre traje azul marino, placa dorada y bigote. Escopeta, salto, más daño a los humanos. |
| **Gustaf Johansen** | Hito 2.4 (`gen_johansen.py`), 7.800 voxels | Marinero corpulento (torso más ancho): gorro de lana gris, barba dorada, chaquetón cruzado azul marino con botones de latón y jersey crema de cuello vuelto. Machete, plancha, mucha vida. |
| **Amelia Peaslee** | Hito 2.4b (`gen_peaslee.py`), 6.500 voxels | Arqueóloga: salacot claro, coleta cobriza, camisa caqui remangada, correa cruzada con cartera de cuero, pantalón de montar y botas altas. Rifle de caza, voltereta, suerte y recogida. |
| **Madame Ludmila Varga** | Hito 2.4b (`gen_varga.py`), 9.300 voxels | Médium de salón: vestido largo de terciopelo negro, estola ciruela con flecos, collar de perlas, media melena negra y diadema con pluma violeta. Necronomicón, destello, arcanas a mitad de cordura. |
| **Dra. Marian Whipple** | Hito 2.4b (`gen_whipple.py`), 8.000 voxels | Bata blanca larga abierta sobre vestido gris, estetoscopio, gafas de montura clara y moño castaño. Bisturís, salto, curación al subir de nivel. |
| **Henrietta Blake** | Hito 2.4b (`gen_blake.py`), 8.100 voxels | Escritora: cloché verde azulado, media melena rubia, abrigo burdeos con bufanda crema y pluma en el bolsillo. Trapezoedro, deslizamiento, más experiencia. |
| **Padre Iwanicki** | Hito 2.4b (`gen_iwanicki.py`), 9.200 voxels | Sotana negra hasta los tobillos con botonadura, alzacuellos, crucifijo de plata, fajín morado y pelo gris. Fórmula de expulsión, voltereta, aura que calma. |
| **Sargento Frank Elwood** | Hito 2.4b (`gen_elwood.py`), 7.500 voxels | Veterano corpulento: casco Brodie, guerrera oliva con correajes y cartucheras, polainas y bigote de cepillo. Colt .45, plancha, aguante físico. |
| **Vera Malone** | Hito 2.4b (`gen_malone.py`), 6.800 voxels | Traje cruzado gris a rayas diplomáticas, corbata granate, clavel, fedora granate y media melena negra. Thompson, deslizamiento, daño a quemarropa. |
| **William Dyer** | Hito 1.2, segunda versión (`gen_dyer.py`), 7.600 voxels, 1,72 m | Diseño a bloques limpios con los detalles pintados. Gorro de trampero de cuero con banda de borreguillo, cara plana con ojos, cejas, barba y bigote, pelo en la nuca, bufanda roja, parka de lona con bolsillos, botones y ribete de borreguillo, cinturón con tres cartuchos de dinamita (único relieve), manoplas, pantalón de lana y botas. Material mate. Animaciones: reposo, andar, esquive y lanzar. |

## Bestiario actual

| Enemigo | Estado | Concepto |
|---|---|---|
| **Pingüino albino ciego** | Hito 1.2, segunda versión (`gen_pinguino.py`), 8.100 voxels | Silueta de pingüino emperador de 1,5 m: cuerpo de torpedo con sección casi plana, cabeza adelantada y pico largo. Dibujo de frac en tonos de albino: gris frío pálido en espalda, cabeza y aletas, pecho blanco, manchas de las orejas amarillo claro y ojos lechosos. Patas rosadas. Material mate. Animaciones: reposo (escucha), andar bamboleándose y carga con picotazo. |
| **Fragmento protoplásmico** | Hito 1.2 (`gen_fragmento.py`), 9.500 voxels | Masa negra iridiscente con brillos verdes y violetas, seis ojos verdosos brillantes, boca que silba y dos pseudópodos. Partes: `body`, `top`, `pod_l`, `pod_r`. Animaciones: reposo, reptar y ráfaga. |
| **Acechador** | Elegido y detallado (`gen_acechador.py`) | Agazapado como rana, manos apoyadas delante, ojos enormes arriba con pupila de rendija, colmillos entrelazados, cresta de púas color hueso con membrana, agallas en volante. Animaciones de acecho y salto. |
| Clásico | Prototipo | Hombre-pez escuálido y encorvado, ojos amarillentos laterales, púas dorsales. |
| Bruto | Prototipo | Masivo, mandíbula enorme con boca caída, ojos pequeños bajo el ceño, verrugas. Candidato a tanque o mini-jefe. |
| Abisal | Prototipo | Negro azulado, ojos cian brillantes, líneas bioluminiscentes, dientes largos. |

## Lecciones técnicas aprendidas

- **Orden de vértices:** Godot considera cara frontal el sentido horario. Con el orden al revés se ven huecos negros y desaparece el suelo.
- **Caché de clases:** si se borra `.godot/`, hay que ejecutar `godot --headless --path . --import` antes de lanzar; si no, `VoxelBuilder` aparece como no declarado.
- **Rendimiento de los generadores:** nunca buscar superficies recorriendo todo el diccionario de voxels. Hay que recorrer la columna directamente (`front()` / `top()` en `gen_acechador.py`); la versión ingenua superó los 5 minutos.
- **Púas finas:** por debajo de ~0,5 unidades base de radio en la punta se fragmentan en puntos sueltos a esta resolución.
- **Colores de vértice:** los colores de los modelos se calibraron en Compatibility, que no convierte sRGB a lineal. En Forward+ hay que marcar `vertex_color_is_srgb`, o todo sale el doble de claro y lavado. `VoxelBuilder.colors_are_srgb()` lo decide según el renderizador; úsalo en cualquier material con colores de vértice.
- **Renderizado:** el juego usa Forward+ (D-15). Compatibility queda como reserva con `--rendering-method gl_compatibility`. El entorno sale de `Atmosphere.make_environment()`, que tiene valores distintos por renderizador:
  - En Forward+, Filmic levanta los negros y lava los colores. ACES con exposición 1,6, sin bloom y con niebla de 0,02 reproduce el aspecto aprobado.
  - Con 150 modelos, Forward+ rinde el doble que Compatibility (`docs/RENDIMIENTO.md`).
- **Personajes humanos:** el primer Dyer se rechazó. Estaba esculpido con elipsoides y relieves de un voxel (nariz, ribetes, gafas, correa, botones), y a esta escala cada relieve se convertía en un bulto deforme; la capucha, además, ocultaba la forma de la cabeza. Los humanos se hacen a bloques limpios (`vbox` y `bevel`), con los detalles pintados sobre superficies planas. La cara se dibuja en el plano frontal de la cabeza con píxeles de 1 voxel y sin relieve, y se usa muy poco ruido de color. Los tonos de piel, pelo y prendas deben distinguirse bien, porque bajo luz cálida el crema de la piel y el gris claro se confunden. Revisa siempre también la espalda y el perfil.
- **Identidad de un animal:** lo que hace reconocible a una especie es su silueta y su patrón de color, no el detalle. El pingüino todo blanco parecía un huevo; con la silueta de emperador y el frac en tonos pálidos se reconoce al instante.
- **Material por modelo:** con el material húmedo de las criaturas, las caras planas de la ropa reflejan los faroles casi en blanco. Ropa, plumas y atrezo van mates.
- **Superficies escalonadas:** los elipsoides grandes dejan un escalón en cada capa de voxels, y la luz cenital los convierte en motas. Para ropa, madera y piedra usa `sell` (superelipsoide), que da caras planas.
- **Efectos breves en capturas:** un rayo de 0,35 s cada 2,2 s casi nunca cae en una captura a segundos redondos. Para comprobarlo, imprime cuándo se dispara y captura cada pocas centésimas alrededor de ese instante.
- **Pelo claro bajo la luz cálida:** un rubio platino se confundía con la piel, de frente y de espaldas. Pelo muy claro solo si el tono es claramente distinto de la piel; si no, oscuro.
- **Colores claros sobre la nieve:** un rayo aditivo o atenuado se pierde sobre el suelo blanco iluminado. Hace falta un núcleo opaco y saturado (naranja dorado) y dejar lo aditivo para el halo.
- **Includes de shaders:** un `varying` no se puede asignar dentro de una función auxiliar, ni siquiera en un `.gdshaderinc`. Se asigna en `vertex()`.
- **Fondo grande en voxel:** a 32 voxels por metro, una pared de 80 m tendría millones de voxels. La barrera se modela a 16 y se exporta a 8 por metro (`half_res`). A 16, el peor 1 % de fotogramas bajaba de 71 a 60 FPS; a 8, con el zoom de juego se ve igual.
- **Colores oscuros bajo la luna:** un agua con albedo de 0,05 sale negra del todo con la luz de luna. Para que un fondo oscuro se lea como agua hace falta un albedo de 0,15 a 0,3.
- **Alas y viseras en isométrica:** la cámara mira desde arriba, así que un ala o una visera que sobresale 3 voxels tapa las dos filas de la cara que quedan debajo, y desaparecen los ojos. Como mucho 2 voxels de ala, y los ojos una fila más abajo (`face(..., eye_y=47)` en `tools/humano.py`).
- **Colores de personajes bajo luz cálida:** un rubio claro se confunde con la piel, y dos tonos oliva distintos se ven iguales. Hay que separar los personajes por valor (claro, medio y oscuro) además de por tono.
- **Detalles que apuntan a la cámara:** en vista isométrica, lo que apunta justo hacia la cámara desaparece en la proyección (el pico del pingüino de frente). Comprueba cada modelo a varios giros.
- **Ojos brillantes:** una esfera `glow` dentro de un párpado oscuro tiene que asomar lo suficiente (desplazada ~0,75 ub hacia fuera), o solo se ven motas sueltas.
- **Capturas abiertas en el visor de fotos:** Windows bloquea el fichero y Python no puede sobrescribirlo (`OSError: Invalid argument`). Guarda con otro nombre.
- **Rutas en Python desde Git Bash:** las rutas `/c/...` solo se traducen cuando van como argumento. Dentro del código Python usa `C:/...`.
- **Niebla volumétrica y cámara ortográfica:** la niebla volumétrica global no sirve con nuestra cámara: solo oscurece la escena y no dispersa la luz de los faroles (limitación conocida con cámaras cenitales u ortográficas).
  - **Lo que sí funciona:** volúmenes locales (`FogVolume` elipsoidal, densidad 0,35) alrededor de cada farol, con la niebla volumétrica activada y la densidad global a 0. Dan halos cálidos y cuestan unos 0,13 ms por fotograma.
- **Legibilidad del jugador:** con luz de luna, la parka marrón de Dyer se funde con el suelo oscuro. Se resuelve con tres cosas:
  - Un farol propio (luz cálida de 4,5 m de alcance que también ilumina a las criaturas cercanas).
  - Un anillo de color grueso.
  - Una silueta cuando lo tapa el decorado. La oclusión se mide contra el **centro** del personaje: solo cuenta lo que está más de 1,05 m por delante de él. Medirla fragmento a fragmento hacía que el brazo lejano se viera a través del torso (en isométrica queda más de medio metro por detrás), y con 0,75 m la cara se marcaba al inclinarse en el esquive.
- **Suelo sin juntas:** unos huecos de 1 cm entre losas dibujaban una cuadrícula y dejaban ver el mar que pasa por debajo, con destellos de los faroles. Las losas van contiguas.
- **Colisión al aparecer:** si un `CharacterBody3D` aparece dentro de una colisión, `move_and_slide` lo expulsa.
- **Bot con esquive:** el bot no debe esquivar en el primer fotograma. Si lo hace, sale disparado hacia delante y parece que no respeta la posición inicial.
- **Packed arrays en GDScript:** un `PackedInt32Array` sacado de un diccionario o metido en otro array es una copia. `(dic[k] as PackedInt32Array).append(x)` y `for a in [arr1, arr2]: a.resize(n)` no cambian el original. Hay que volver a guardarlo, o trabajar con la variable miembro directamente. Pasó dos veces en el hito 1.4.
- **`POSITION` en un shader de vértices:** si una rama lo escribe, hay que escribirlo en todas. En las que no, el vértice queda sin posición y la malla desaparece sin ningún error.
- **Colores sin iluminar y tonemapper:** ACES con exposición 1,6 también procesa los materiales `unshaded` y quema los colores saturados, de modo que el violeta sale blanco. Balas y avisos multiplican su color por un factor menor que 1 (`exposure_comp`).
- **Clases internas de GDScript:** no son nombres globales. Un `class X extends Y:` dentro de otro fichero solo se alcanza como `Fichero.X`. Si otras clases las crean por nombre, cada una va en su fichero con `class_name`.
- **Arrays tipados en `.tres`:** un `Array[EnemyData]` se escribe `Array[ExtResource("id_del_script")]([...])`, no `Array[Resource]`.
- **Coste por fotograma en GDScript:** con 150 enemigos, llamar a `find_children` y reasignar materiales en cada fotograma, y recalcular las posiciones de reposo leyendo metadatos, bajaba la partida de 170 a 81 FPS. `VoxelBuilder` guarda en metadatos las partes, las posiciones de reposo y las mallas de cada modelo (`parts`, `rest`, `rest_by_name`, `meshes`), y los materiales solo se tocan cuando cambia el estado.
- **Referencias a objetos liberados:** copiar un objeto ya liberado dentro de un array tipado (`Array[Object]`) da error. Para recordar un objetivo que puede morir en cualquier momento, guarda su `get_instance_id()`.
- **Aviso `ObjectDB instances leaked` al salir:** aparece si se fuerza la salida (`--quit-after`) mientras una corrutina espera un temporizador. No pasa al jugar normalmente.
- **Vibración con monitores de más de 60 Hz:** es el efecto de mover en `_physics_process` sin interpolación. En isométrica se nota sobre todo de lado y en diagonal, porque hacia arriba y hacia abajo el personaje recorre la mitad de píxeles.
- **Gemas y materiales sin iluminar:** un color dorado sin iluminar, tras el tonemapper (ACES 1,6), sale casi blanco o naranja rojizo según se trate como sRGB o no. Para objetos pequeños que deben verse bonitos, mejor material iluminado, algo metálico y con una emisión suave. Ojo con los reflejos puntuales muy nítidos: en una gema parecían ojos (rugosidad 0,5).
- **Mallas hechas con SurfaceTool:** el orden de los vértices decide qué cara se ve. Si una malla pequeña se ve rara o del color de su cara interior, prueba `cull_mode = CULL_DISABLED` o invierte el orden.
- **Edificios en voxel:** a 32 voxels por metro, un edificio macizo tendría cientos de miles de voxels. Se hacen huecos (paredes de 2-3 voxels, tejado de 1 más 2 de nieve), y el iglú como cáscara esférica de grosor uniforme; medirla en horizontal dejaba un agujero en la cúspide. Aun así, la cabaña tiene unos 100.000 voxels: la caché de mallas es imprescindible.
- **Rampas a 45° en voxel:** la tienda piramidal (escalones de un voxel) se veía rayada. Se rehízo como tienda de cumbrera, con faldones más empinados y color uniforme por paños.
- **Scripts largos en la herramienta de Bash:** un heredoc muy largo se corta ("unexpected EOF while looking for matching"). Para ediciones grandes, escribe el script en el scratchpad y ejecútalo.
- **Partículas con billboard:** `BILLBOARD_PARTICLES` descarta la escala de cada partícula si no se activa `billboard_keep_scale`. Todos los copos de nieve medían 1 m.
- **Bloom general y partículas pequeñas:** con `glow_bloom` > 0 cada punto claro se convierte en una bola borrosa. En la portada, el bloom es 0 y el brillo sale solo del umbral HDR.
- **Rayos del clima sobre nieve:** un destello de luz direccional de 2,2 más 0,9 de ambiente convierte la noche en día sobre el suelo blanco. Con 0,45 y 0,18 se lee como un fogonazo frío.
- **Propiedades antes de `script` en un `.tres`:** Godot las ignora (aún no sabe de qué clase es el recurso). Van siempre después de la línea `script = ExtResource(...)`.
- **Colores en `.tres`:** `Color(r, g, b)` con tres componentes no se carga; hacen falta los cuatro.
- **Referencias circulares entre RefCounted:** dos objetos que se guardan el uno al otro (el equipo y el progreso de cada jugador) no se liberan nunca, ni al reiniciar la escena; aparece como "N resources still in use at exit". Uno de los dos debe guardar al otro con `weakref()`. Para localizarlo: `godot --verbose ... --quit-after N` y mirar qué scripts siguen en uso.
- **Foco del mando con ventanas encima:** Godot busca el control más cercano en la dirección pulsada entre todos los visibles, también los que están detrás de una ventana. Toda ventana modal debe encerrar el foco (`MenuKit.trap_focus`).
- **Relámpagos y luz ambiental:** si el ambiente sale del cielo, cada relámpago ilumina el valle como si fuera de día. Usa ambiente de color fijo y deja el destello al cielo, a un contraluz rasante y a una luz puntual.
- **Montañas voxel:** un cono con pendiente uniforme o bloques aplanados se ven como pirámides escalonadas. Hacen falta cárcavas, un contorno quebrado de agujas (ruido de crestas de celda pequeña) y pocas mesetas.
- **NumPy y JSON:** los enteros de NumPy (`int64`) no se pueden serializar; conviértelos con `int()` o `float()` antes de `json.dump`.
- **Animar una ilustración:** se genera un mapa de máscaras y se modula la imagen con él en un shader, sin pintar nada nuevo encima. Una llama es un blob cálido y brillante; su luz, ese blob difuminado; y el cielo son los píxeles azules y claros dentro del ventanal. Las formas oscuras (tracería, silueta) quedan fuera solas. Mide la variación por zonas antes de darla por buena: a ojo se sobrestima lo sutil que es.
- **Shaders de canvas:** `TEXTURE` solo existe dentro de `fragment()`; para usarla en una función auxiliar hay que pasarla como `sampler2D`. Para superponer un halo bajo un texto que aparece, usa la composición "encima" con los colores ponderados por su alfa; una mezcla simple tiñe el texto con el color del halo mientras es transparente.
- **Texturas 4K mostradas a 1080p:** activa `mipmaps/generate=true` en su `.import` y usa `TEXTURE_FILTER_LINEAR_WITH_MIPMAPS`, o saldrán dientes de sierra y brillos que bailan al hacer zoom.
- **Tests y datos de equilibrio:** los tests no deben comprobar valores que se retocan al equilibrar (ritmos, experiencia, vida). Cuando haga falta, que construyan sus propios datos. Si un test falla tras un ajuste de equilibrio, el que está mal es el test.
- **Controles de los menús:** el `ui_accept` de Godot no trae ningún botón del mando y sí trae Espacio, que es la tecla de esquivar. `UiInput.configure()` añade A (aceptar) y B (volver) y quita Espacio. El menú de mejoras ignora las pulsaciones durante su primer medio segundo.
- **Élites ahogadas en la horda:** las armas apuntan al más cercano o a la zona más densa, así que una élite rodeada de la oleada casi no recibe disparos. `LevelData.final_spawn_scale` (0,3) reduce las apariciones durante el evento final.
- **Turbulencia en `ParticleProcessMaterial`:** arrastra la velocidad de cada partícula hacia la del campo de ruido en cada paso. Con influencias normales (0,05-0,1), las partículas lentas se quedan paradas donde nacen; por eso no se veían las motas de la primera portada. Para caídas lentas, influencia de 0,002-0,006.
- **`preprocess` en partículas de vida larga:** no llegaba a repartir la ceniza por la pantalla. Es más fiable emitir en una caja que cubra toda la zona, con fundido de entrada y salida en la rampa de color.
- **Niebla en shader:** el ruido de valores con umbrales (`smoothstep` estrecho) da grano y formas en cuadrícula que se ven artificiales. Funciona mejor:
  - Ruido de gradiente con octavas giradas, y pocas octavas.
  - Formas grandes y alargadas, con perspectiva.
  - Modular la niebla pintada (aclararla y oscurecerla) en vez de añadir otra capa encima.
- **Llamas animadas sobre una ilustración:** la cera junto a la llama también es clara y cálida.
  - La llama se separa cortando cada mancha por el cuello de la mecha: donde la anchura se estrecha o salta al borde de la vela.
  - El desplazamiento crece de 0 en la base a 1 en la punta, con margen a los lados y por encima, pero nunca por debajo.
- **Aviso de recursos sin liberar con música:** al forzar la salida con `--quit-after` con música sonando, a veces sale `1 resources still in use at exit`. Es intermitente y no aparece con `mute=true`.
- **Sutil no es invisible:** una variación del 1,8 % de brillo no se percibe en movimiento. Para que una animación de ambiente se note hace falta del orden del 10-20 % en su zona.
- **Movimientos lentos de un `Control`:** Godot redondea su posición a píxeles enteros (`gui/common/snap_controls_to_pixels`), así que un zoom o un desplazamiento lento avanza a saltos y parece que la imagen vibra; en la portada eran saltos de 2 px a 4K. Anímalos en un `Node2D` padre, que no se redondea. Para comprobarlo, mide el desplazamiento entre fotogramas con correlación de fase.
- **Grabar en pantalla completa exclusiva:** si la ventana pierde el foco, Godot deja de dibujar y `--write-movie` repite el último fotograma. Graba en ventana.
- **Pantalla completa en Windows:** `WINDOW_MODE_FULLSCREEN` deja la ventana 1-2 píxeles más pequeña que el monitor; usa `WINDOW_MODE_EXCLUSIVE_FULLSCREEN`.
- **Grabar vídeo en pantalla completa:** con `--write-movie` a 4K cada fotograma tarda 2,5 s. `Engine.get_write_movie_path()` sirve para detectar la grabación y quedarse en ventana. Buscar `--write-movie` en `OS.get_cmdline_args()` no funciona.
- **`cat` sin entrada:** un `cat > fichero` sin heredoc se queda esperando la entrada estándar para siempre.

## Por definir

Las decisiones abiertas están en `docs/GDD.md` (sección 12), con la fase a la que bloquea cada una. Música y sonido solo tienen pautas sueltas (el susurro de los ataques mentales); el audio llega en la fase 8.
