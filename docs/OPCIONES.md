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
  - `weapons=granada,webly` y `wlevel=N`: armas iniciales (ids de `data/weapons/`) y su nivel.
  - `god=true`: el jugador no recibe daño.
  - `bullet_rain=N`: mantiene N balas enemigas vivas (prueba de carga).
  - `level=p1_n1`: nivel a jugar (por defecto). `nolevel=true` deja el campo de pruebas sin oleadas.
  - `timescale=N`: acelera el juego. Las capturas de `shots=` usan tiempo de juego.
  - `final_at=s`: adelanta el evento final.
  - `max_alive=N` y `spawn_rate=N`: tope de vivos y ritmo de aparición fijo (pruebas de carga).
  - `autopick=true`: elige sola la primera mejora (para bots y capturas).
  - `xp=`, `hp=` y `san=`: experiencia, vida y cordura iniciales.
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
  - `ui_check=true` (en cualquier escena): apunta con «UICHK» los textos que pisan el filete de una ventana (20 px del borde), su filigrana o el borde de un recuadro (`scripts/ui/ui_overlap_check.gd`).
  - `level=desafio:p1_n4`: juega el desafío de ese nivel (hito 15.2). `challenge_open=true` (selección con `map=true`): abre la ventana de los desafíos.
  - `replay=false`: sin grabar la repetición de la caída (hito 15.1). `replay_open=true`: la abre en la pantalla final (capturas, con `halt_shots=true quit_on_end=true`).
  - `boss_intro=false`: sin la entrada de los jefes (`BossIntro`), solo el aviso de texto, como antes.
  - `hp=` y `san=` también sirven para ver los retratos con estado (hito 12.14: sangre desde la mitad de la vida, mirada perdida desde el 40 % de la cordura).
  - `cfg_difficulty=N`: todas las características de la dificultad a N (1..10; D-42) en esta ejecución. `dif_<característica>=N` (p. ej. `dif_vida=6`) cambia una; `dif_<valor>=x` (p. ej. `dif_rate=4`), un multiplicador suelto. `dif_menu=true` con `debug_menu=N`: abre la dificultad en vez de la depuración. `python tools/simular.py … --dif N` (3 por defecto).
  - `halt_shots=true quit_on_end=true`: captura la pantalla final (con el informe al caer, hito 13.1) y sale. `no_report=true`: sin el informe. `report_log=true`: apunta también las partidas de bots en el registro de dificultad (sin él, solo las de personas).
  - `card=true`: con `shots=`, enseña también el rótulo del nivel al empezar (`LevelCard`; sin él, las capturas no lo llevan).
  - `mando=true`: en las pruebas lanzadas desde Claude Code, deja usar los mandos (sin él, la partida no les hace caso). `ver=true`: deja su ventana a la vista, centrada (sin él, va fuera de las pantallas).
  - `blast=x,z,t;…` y `crate=x,z,t;…`: explosiones ahí a esos s y rompibles que se rompen a esos s (capturas del hito 12.11).
  - `rise=false`: los enemigos aparecen creciendo, como antes. `rise_demo=pinguino,pesadilla,…` y `rise_at=t`: hacen aparecer esos enemigos alrededor del J1 a los t s (capturas de la aparición).
