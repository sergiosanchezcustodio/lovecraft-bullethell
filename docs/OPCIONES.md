# Comandos y opciones de lanzamiento

Movido desde `CLAUDE.md` el 30-10-2026. Las opciones se leen en `scripts/core/game.gd` (y en cada escena con `LaunchArgs`).

Uso desde la raíz del proyecto, en Git Bash:
```
./jugar.cmd                         # o doble clic en jugar.cmd: partida sin consola
godot --path .                      # portada (escena principal: scenes/main.tscn, que elige la escena según el primer argumento)
godot --path . -- select saves=demo_saves slot=2 join=2   # selección de personaje con dos jugadores de prueba
godot --path . -- bot=circle dodge_every=2 demo=14 shots=1,3 tag=prueba   # partida con bot, criaturas de muestra y capturas
godot --path . --write-movie shots/videos/mov/f.png --fixed-fps 30 --quit-after 240 -- bot=circle   # vídeo en fotogramas PNG
godot --path . --disable-vsync -- bot=circle demo=14 perf=8                 # rendimiento de la partida
python tools/gen_acechador.py       # regenera models/acechador.json
python tools/gen_variantes.py       # regenera clasico, bruto, acechador (versión simple) y abisal
python tools/gen_dyer.py            # Dyer (personaje jugable); igual gen_pinguino.py y gen_fragmento.py
python tools/gen_olmstead.py        # Olmstead; igual gen_legrasse.py, gen_johansen.py, gen_peaslee.py, gen_varga.py, gen_whipple.py y gen_blake.py (base común en tools/cuerpo.py; tools/humano.py ya no se usa)
python tools/gen_atrezo_campamento.py   # models/atrezo_{tienda,caja,bidon,farol,roca,hielo}.json
python tools/referencias_personajes.py legrasse   # referencias de FLUX en local para la cabeza (ComfyUI arrancado)
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
- **Capturas:** van a `shots/`, que Godot ignora (`.gdignore`) y git también. Caen en la raíz; `python tools/ordenar_shots.py` las reparte en `partida/` y `revision/` por fecha, `modelos/` por grupo, `menus/`, `videos/` y `referencias/` (y corrige las rutas de CLAUDE.md y docs/). Detalle en `shots/LEEME.md`. Añade `--rendering-method gl_compatibility` a cualquier comando para usar el renderizador de reserva.
- **Argumentos:** las escenas leen lo que va detrás de `--` con `LaunchArgs` (`scripts/core/launch_args.gd`): posicionales, `clave=valor` y banderas `--clave`.
- **Opciones de la partida** (`scripts/core/game.gd`):
  - `bot=circle|zigzag|idle` y `dodge_every=` (s): jugador automático. `bot=stop` corre a la derecha y se para, por turnos (la frenada, hito 17.2); `bot=right`, `up` y `diag`, en línea recta.
  - `shots=` y `tag=`: capturas.
  - `cam=`: altura visible en m (por defecto 15).
  - `demo=N`: criaturas de muestra quietas.
  - `pos=x,z`: posición inicial del jugador.
  - `perf=N`: mide el rendimiento N segundos. Si antes se supera el nivel o se cae, da el informe de lo medido («RENDIMIENTO cortada a los … s») y sale (07-11-2026: antes se quedaba parada en la pantalla final).
  - `fogvol=false`: quita los halos de niebla.
  - `--debug`: imprime la posición del jugador.
  - `dodge=deslizar|rodar|plancha|salto|destello`: estilo de esquive (F1 los recorre en partida).
  - `dummies=N`: muñecos de práctica que reciben daño.
  - `emitters=true`: tres emisores de prueba, uno por tipo de daño.
  - `character=<id>`: personaje del J1 (`dyer`, `west`…; también los secretos `carter` y `whateley`, hito 16.25, aunque estén cerrados).
  - `weapons=granada,webly` y `wlevel=N`: armas iniciales (ids de `data/weapons/`) y su nivel.
  - `god=true`: el jugador no recibe daño.
  - `bullet_rain=N`: mantiene N balas enemigas vivas (prueba de carga).
  - `level=p1_n1`: nivel a jugar (por defecto). `nolevel=true` deja el campo de pruebas sin oleadas.
  - `timescale=N`: acelera el juego. Las capturas de `shots=` usan tiempo de juego.
  - `final_at=s`: adelanta el evento final.
  - `seed=N`: semilla de la partida (hito 16.26; sin ella, una nueva). `archive_save=true`: apunta la partida en el archivo de expediciones aunque juegue un bot. `log_ups=true`: escribe la semilla y las opciones de cada subida.
  - `reflections=true|false`: fuerza o quita los reflejos en el agua (hito 16.31; por defecto, los de la calidad: Alta y Ultra). `refl_debug=true` enseña la imagen del reflejo en una esquina y la pone en todo el suelo.
  - `moon_shafts=true|false`: fuerza o quita los haces de luna (hito 16.32; por defecto, los de la calidad: Alta y Ultra). Con `log=true`, cuántos y lo que tardan en montarse.
  - `night=0..1`: fija la hora de la noche (hito 16.33; 0 crepúsculo, 1 noche cerrada, la luz de siempre); `night=false` quita el ciclo y `dawn=true` amanece al empezar.
  - `decor_break=false`: el decorado no se rompe (hito 16.34). `decor_blast=t`: desde t s, explosiones en las cuatro piezas rompibles más cercanas al J1, para capturas; con `log=true`, cuántas piezas hay y lo que cuesta cada una al romperse.
  - `sky=luna|luna_baja|luna_verde|aurora|tormenta|rlyeh` (en el relato): cambia su cielo (hito 16.35). En la portada, `off=nubes` quita las nubes del ventanal.
  - `LOVECRAFT_ECO=1` (variable de entorno, no opción): las pruebas en el escritorio aparte con el «ahorro de energía» de Windows, como antes del 03-11-2026 (ver `docs/ESTADO.md`, 16.1).
  - `log_rumble=true`: escribe cada pulso de vibración del mando, haya mando o no (hito 16.30).
  - `dmg_table=T`: abre la pausa y la tabla «Daño de la partida» a los T s (`dmg_player=N`: la del J N; hito 16.27).
  - `max_alive=N` y `spawn_rate=N`: tope de vivos y ritmo de aparición fijo (pruebas de carga).
  - `autopick=true`: elige sola la primera mejora (para bots y capturas).
  - `xp=`, `hp=` y `san=`: experiencia, vida y cordura iniciales.
  - `madness=N`: grado de locura (16.14, de 0 a 5) para los niveles de la campaña; en el mapa, `madness_open=true` pone el foco en el selector (sale aunque no se haya vencido a Cthulhu, en desarrollo).
  - `pause_at=t,dur` con `halt_shots=true`: captura la pausa (hito 20.10, con el desenfoque).
  - `autopause_at=T`: simula perder el foco a los T s (pausa automática, hito 16.23). `cfg_game_speed=0.8`: velocidad del juego de esta ejecución.
  - `traits=N` o `traits=vampira,estalla,icor,rapida,escudo`: todas las élites salen con esos rasgos (hito 16.20; `N`, la máscara de `EliteTraits`).
  - `peddler=true`: el buhonero sale en este nivel (a los `peddler_at=` s, 5 por defecto; con bots también); `peddler=false`, nunca. `objective_near=true` lo pone cerca y `peddler_stall=N` deja la mercancía N (0 remedio, 1 baratija, 2 libro) a los pies del J1. `purse=N`: el nivel empieza con N dólares ganados. `log=true` escribe `BUHONERO` y `COMPRA`.
  - `signs=cthugha,yog`: Signos Mayores del J1 para esta ejecución (hito 16.9; `signs=false`, ninguno y sin elegir). Sin hueco elegido no se ofrece ninguno (salen de los logros del hueco).
  - `chest_every=S` y `chest_here=true`: baúles arcanos cada S s de media y a los pies del jugador, que los abre al salir (07-11-2026: para probar lo que hace el baúl al abrirse; el bot casi nunca va a por ellos).
  - `evolve_at=T`: el J1 abre un baúl arcano a los T s (evoluciona el arma que esté lista; con dos ramas, abre la ventana de elegir; hito 16.8). Junto con `weapons=thompson wlevel=5 items=oro_obed`. `evo_branch=N`: con bot o `autopick`, elige la rama N (0 o 1).
  - `autorestart=N`: en la pantalla final, reintenta sola tras N s.
  - `log=true`: cada 30 s de juego imprime vivos, abatidos, nivel, vida, cordura y balas; si el enemigo final tarda en morir (más de 30 s), cada 10 s su posición, vida y estado (`final=`).
  - `prof=true` (junto con `perf=`): reparto del tiempo de CPU por sistema (`Prof`).
  - `mute=true`: sin música (también en la portada).
  - `test_save=N`: crea la partida de pruebas (todo desbloqueado) en el hueco N y sale.
  - `saves=carpeta`: otra carpeta de partidas dentro de `user://` (capturas y pruebas sin tocar las tuyas). `slot=N`: juega con ese hueco.
  - `window=true` / `fullscreen=true`: fuerza ventana o pantalla completa.
  - `debug_menu=N`: abre la pausa y el menú de depuración a los N s (capturas).
  - `sheet_at=t` / `map_at=t`: abre la ficha o el mapa del J1 a los t s. `demo_kill=t`: mata a todos los enemigos a los t s (capturas de las muertes).
  - `grade=off|p1|p2|p3`: sin gradación de color o la de otra parte (comparar).
  - `hitstop=false`, `crumble=false` y `marks=N`: sin micro-pausa al impactar, sin desmoronarse y tope de manchas en el suelo (por defecto, el de la calidad gráfica). `falls=false`: sin la caída de cada familia al morir (hito 12.7). `wounds=false|0.7`: sin las grietas de herida o fijas a ese nivel (hito 12.6, medir su coste).
  - `cfg_quality=0..3` (Baja…Ultra) y `cfg_damage_numbers=0|1|2`: calidad gráfica y números de daño para esta ejecución.
  - `ui_check=true` (en cualquier escena): apunta con «UICHK» los textos que pisan el filete de una ventana (20 px del borde), su filigrana o el borde de un recuadro (`scripts/ui/ui_overlap_check.gd`). Desde el 05-11-2026 avisa también del contenido descentrado en su ventana (más de 22 px de diferencia entre el hueco de la izquierda y el de la derecha, o 40 entre arriba y abajo) y de las filas anchas que no dejan el mismo hueco a cada lado (6 px), y de las ventanas que se salen de la pantalla (si sigue así en dos revisiones seguidas, una por segundo). Desde el 06-11-2026, también de los textos que se ven a menos de 10 px de pantalla (para la interfaz Pequeña: `--con "cfg_ui_scale=0"`; desde el 06-11-2026 solo vale con 1080 de alto o más).
  - `python tools/recorrido_ui.py [tag,tag…]`: abre una a una 56 ventanas (portada, configuración, tienda, biblioteca, selección, pausa, depuración, ficha, mapa, evolución, pantalla final, expedición, pesca…) con `ui_check=true`, guarda su captura en `shots/ui_recorrido/<tag>.png`, sus avisos en `<tag>.txt` e `informe.txt` con los de todas (se rehace con los `<tag>.txt`: pasar solo unas no borra las demás). Unos 25 minutos entero; con tags, solo esas. `--con "<opciones>" --sufijo <nombre>` repite el recorrido con esas opciones en `shots/ui_recorrido_<nombre>/`: `--con "cfg_ui_scale=3" --sufijo grande` (interfaz Muy grande, ×1,3), `--con "res=1280x800" --sufijo deck` (16:10) o `--con "res=2560x1080" --sufijo panoramica` (21:9).
  - `python tools/resumen_recorridos.py [--detalle]`: tabla de todos los recorridos (los `<tag>.txt` de `shots/ui_recorrido*/`), una fila por ventana y una columna por tamaño, con sus avisos y de cuándo es cada recorrido; en `shots/ui_recorrido_resumen.txt`.
  - `python tools/caza_errores.py [tag,tag…] [--par 2] [--t 110]`: juega con el bot los 15 niveles (final adelantado), tres noches eternas, tres desfiles, tres desafíos y dos cooperativos, y junta los errores y avisos de la consola sin repetir, con dónde salieron, en `shots/caza_errores/informe.txt` (y la última captura de cada partida). Unos 15 minutos.
  - `sheet_row=N` (con `sheet_at=`): la ficha se abre con el arma u objeto N marcado y entero.
  - `res=1280x800`: la ventana de pruebas a ese tamaño (la interfaz escala desde 1920×1080: con 16:10 la pantalla mide 1920×1200 unidades y con 21:9, 2560×1080).
  - `crash_report=true`: arma el informe de errores (hito 19.9) en una ejecución de prueba; sin opciones, siempre. `crash_demo=true`: hace como si la vez anterior se hubiera cerrado de golpe, para ver la pregunta del menú principal (`title … open=menu crash_demo=true`).
  - `levelup_at=t`: el J1 sube un nivel a los t s (la ventana de subida). `expedition_open=true` (con `select … map=true`): abre la elección de la expedición, como `endless_open`, `daily_open`, `pact_open` y `challenge_open`.
  - `level=desfile:N`: el desfile de jefes desde el jefe N (hito 16.22; con 22 subidas al empezar). Con `autonext=true` pasa solo al siguiente.
  - `level=expedicion:<tipo>:<nivel>:<fila>`: un nodo suelto de la expedición (hito 16.21; tipos `combate`, `elite`, `buhonero` y `jefe`; p. ej. `expedicion:buhonero:p2_n2:3`). Sin expedición en curso, sin bolsa ni subidas.
  - Mapa de la expedición suelto: `godot --path . scenes/expedition_map.tscn -- exp_part=0 exp_seed=7` (`exp_row=N`: con N filas ya andadas, para capturas; `exp_auto=true`: elige solo cada segundo, y con `bot=smart autonext=true skip_relato=true` recorre la expedición entera).
  - Pesca en el muelle (hito 16.24): `godot --path . scenes/fishing.tscn -- pj=<personaje>` suelta (al acabar, se cierra; `next=<nivel>` para seguir a ese). `fish_auto=true` pesca sola (carga hasta el 70 %, clava y recoge soltando en los tirones), `fish_force=<captura>` hace que pique esa (`arenque`, `rape`, `cria`, `mano`…), `fish_pick=N` elige la opción N de su ficha, `card_shot=true` captura la ficha (`shots/pesca_<tag>_ficha_<captura>.png`), `seed=N`. En la partida, `go_fishing=true` pulsa «Pescar en el muelle…» al superar un nivel de la parte 2.
  - `level=desafio:p1_n4`: juega el desafío de ese nivel (hito 15.2). `challenge_open=true` (selección con `map=true`): abre la ventana de los desafíos.
  - `library_live=false`: el bestiario con las imágenes quietas, sin girar (hito 15.4).
  - Sala de trofeos (hito 16.28): `title saves=<carpeta> open=menu_biblioteca tome=10 cursor=N` (N: el hueco, contando las tres vitrinas; sin él, el primer jefe). Partida de prueba: `python tools/partida_trofeos.py "%APPDATA%/Godot/app_userdata/Lovecraft Bullet Hell"` y `saves=trofeos_saves`. `log=true` da lo que tarda en montarse.
  - Hoja de poses (hito 17.1): `godot --path . -s tools/hoja_poses.gd -- model=dyer anim=swing n=6` (un modelo en N fases de una animación, con la cámara de la partida y de lado, en `shots/poses_<modelo>_<anim>.png`). `base=walk` lo pone encima de andar; `over=false`, pose entera; `anim=aim1`, `aim2` o `aim_look`, apuntar con una o dos manos o hacia los lados; `anim=wade`, `mud` o `slip`, andar vadeando, por el barro o la frenada en la nieve (17.6); `side=false`, sin la vista de lado; `zoom=`, `cy=` y `gap=` para los compañeros (`zoom=1 cy=0.2 gap=0.7`); `anim=die_burn`, `die_blast`, `die_shock` o `die`, muertes (17.9, `dur=` s que cubren las columnas); `bg=0.45`, fondo claro.
  - Hoja de entradas (hito 17.11): `godot --path . -s tools/hoja_entradas.gd -- enemy=profundo rise=water n=8` (un enemigo apareciendo en N momentos, en `shots/entrada_<enemigo>_<rise>.png`). `rise=` water, fog, ground o air (sin él, la que le toca); `dur=` s que cubren las columnas (1,2); `variety=false`, todos iguales (con `rise=none dur=0`, una fila para comparar).
  - Hoja de modelos: `godot --path . -s tools/hoja_modelos.gd -- modelos=a,b,c px=320 out=shots/hoja.png` (varios modelos en una imagen, para revisarlos de cerca; con ventana).
  - Archivo de expediciones (hito 16.26): `title saves=<carpeta> open=menu_biblioteca tome=9 cursor=N`; `lib_replay=N` repite la partida N (pulsa «Repetir» solo).
  - Configuración (hito 20.12): `title saves=<carpeta> open=menu_config tab=N focus_row=M` (abre la pestaña N con su fila M elegida; cuenta solo las filas con valor o botón).
  - Tienda: `title saves=<carpeta> open=menu_tienda tab=N shop_focus=<id>` (abre la pestaña N con la fila de ese artículo, personaje o compañero elegida; hito 20.17). `shop_sub=N` y `shop_char=N` eligen la subpestaña y el personaje del vestuario.
  - `replay=false`: sin grabar la repetición de la caída (hito 15.1). `replay_open=true`: la abre en la pantalla final (capturas, con `halt_shots=true quit_on_end=true`). `replay_gif=true`: además la guarda como GIF (en `photo_dir=` si se da).
  - `spikes=true` (con `perf=N`): registro de picos (hito 16.1, `SpikeLog`; desde el 03-11-2026 también cuánto de cada pico es proceso, física y «otro», y desde el 06-11-2026 «otro» en tramos —tras el proceso, dibujo, tras la física, arranque y resto— con cada fila cerrada al acabar el dibujo, así que todo es del mismo fotograma, y de qué tipo es cada compilación y qué entró en escena ese fotograma): cuántos fotogramas pasan de 16,7 ms y de 25 ms (tirones), el peor, compilaciones de shaders (cuándo y de qué tipo), pasos de física, nodos que entran en la escena por tipo, los sistemas de `Prof` que suben en los picos, los peores fotogramas uno a uno y cuántos nodos se ejecutan en cada fotograma. Activa `prof`. Al medir, sin límite de fotogramas (`--disable-vsync`): con `cfg_fps_limit=60` el temporizador de Windows hace oscilar cada fotograma alrededor de 16,7 ms y la cuenta no sirve. Desde el 07-11-2026 también los tirones por medio minuto y las compilaciones a mitad de partida (tras los 10 primeros s medidos), que `tools/comparar.py` promedia como «a_mitad»; con tope de 120 000 fotogramas.
  - `loadtime=true`: reparte la carga de la partida por tramos de `_ready` («CARGA   arena…») y dice si la arena venía montada del relato y cuánto se esperó por ella (hito 16.6); sin relato delante, sale al acabar de cargar. Con `relato level=pN_nM relato_go=T` (el relato pasa solo a los T s) mide también la pantalla en negro desde el relato («CARGA desde el relato hasta aquí»). `preload=false`: sin cargar la partida durante el relato (para comparar).
  - `horde=false`: los enemigos corrientes con su modelo de nodos, sin las hordas con instancias (hito 16.3; también `"horde"` en `data/quality.json`).
  - `warmup=false`, `model_pool=false` y `anim_lod=false`: sin el calentamiento del nivel, sin la reserva de modelos de enemigos y con la pose de los enemigos en cada fotograma (como antes de los hitos 16.1 y 16.2; para comparar).
  - `flash_hold=true`: el destello del golpe de los enemigos, siempre encendido (capturas: dura 0,07 s y no sale en las normales). `tints=false`: sin destello ni tintes de estado.
  - `boss_intro=false`: sin la entrada de los jefes (`BossIntro`), solo el aviso de texto, como antes.
  - `hp=` y `san=` también sirven para ver los retratos con estado (hito 12.14: sangre desde la mitad de la vida, mirada perdida desde el 40 % de la cordura).
  - `cfg_difficulty=N`: todas las características de la dificultad a N (1..10; D-42) en esta ejecución. `dif_<característica>=N` (p. ej. `dif_vida=6`) cambia una; `dif_<valor>=x` (p. ej. `dif_rate=4`), un multiplicador suelto. `dif_menu=true` con `debug_menu=N`: abre la dificultad en vez de la depuración. `python tools/simular.py … --dif N` (3 por defecto).
  - `halt_shots=true quit_on_end=true`: captura la pantalla final (con el informe al caer, hito 13.1) y sale. `no_report=true`: sin el informe. `report_log=true`: apunta también las partidas de bots en el registro de dificultad (sin él, solo las de personas).
  - `card=true`: con `shots=`, enseña también el rótulo del nivel al empezar (`LevelCard`; sin él, las capturas no lo llevan).
  - `mando=true`: en las pruebas lanzadas desde Claude Code, deja usar los mandos (sin él, la partida no les hace caso). `ver=true`: deja su ventana a la vista, centrada (sin él, va fuera de las pantallas).
  - `blast=x,z,t;…` y `crate=x,z,t;…`: explosiones ahí a esos s y rompibles que se rompen a esos s (capturas del hito 12.11).
  - `hit_sparks=false`: sin las chispas de los impactos según el daño (hito 18.3, `HitSparks`). `casings=false`: sin casquillos (hito 18.4, `Casings`). En Baja no salen ninguno de los dos.
  - `trails=false`: sin las estelas de las armas (hito 18.1, `FxTrails`); en Baja no salen (`weapon_fx` 0, `qset=weapon_fx:2` para verlas).
  - `qset=clave:valor,…`: cambia claves sueltas del preajuste de calidad para esta ejecución (`qset=traces:false,vents:false,shot_light:true`), para comparar con `tools/comparar.py`.
  - `distant_soon=true`: el primer suceso lejano de la arena sale en cuanto se vea (hito 17.18, capturas).
  - `variety=false`: todos los enemigos de un tipo iguales en tamaño, ritmo y paso (hito 17.12).
  - `rise=false`: los enemigos aparecen creciendo, como antes. `rise_demo=pinguino,pesadilla,…` y `rise_at=t`: hacen aparecer esos enemigos alrededor del J1 a los t s (capturas de la aparición).
