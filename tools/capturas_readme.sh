#!/bin/sh
# Capturas para las imágenes del README (23-10-2026). Después: python tools/montar_readme.py
# Uso (Git Bash, desde la raíz): sh tools/capturas_readme.sh   (unos 45 minutos, todo en ventana)
# - Partidas con cuatro bots invulnerables (god=true) a velocidad doble y con los destellos de
#   los golpes reducidos (cfg_flashes=0): con los normales, los enemigos golpeados salen en blanco.
# - Menús con la partida de pruebas con todo desbloqueado (user://readme_saves, hueco 1).
# - Modelos en capturas cuadradas: el visor encuadra el grupo como si la ventana fuera cuadrada.
cd "$(dirname "$0")/.."
G="godot --path . --"
C="mute=true window=true"
P="bot=smart autopick=true god=true timescale=2 cfg_flashes=0"
run() { echo ">> $*"; "$@" 2>&1 | grep -E "captura|ERROR" | head -20; }

# Partidas (se usa una captura de cada una; cuál, en tools/montar_readme.py)
run $G level=p1_n1 character=dyer bots=3 bot_chars=olmstead,peaslee,whipple $P shots=110,150 tag=readme_p1n1 quit_at=152 $C
run $G level=p1_n3 character=peaslee bots=3 bot_chars=armitage,legrasse,blake $P shots=110,150 tag=readme_p1n3 quit_at=152 $C
run $G level=p2_n3 character=olmstead bots=3 bot_chars=malone,johansen,peaslee $P final_at=60 shots=80,100 tag=readme_p2n3 quit_at=102 $C
run $G level=p2_n4 character=whipple bots=3 bot_chars=west,dyer,iwanicki $P shots=110,150 tag=readme_p2n4 quit_at=152 $C
run $G level=p3_n1 character=blake bots=3 bot_chars=armitage,varga,west $P shots=110,150 tag=readme_p3n1 quit_at=152 $C
run $G level=p3_n2 character=legrasse bots=3 bot_chars=armitage,varga,elwood $P shots=110,150 tag=readme_p3n2 quit_at=152 $C
run $G level=p3_n4 character=johansen bots=2 bot_chars=whipple,west $P shots=110,150 tag=readme_p3n4 quit_at=152 $C
run $G level=p3_n5 character=peaslee bots=3 bot_chars=dyer,iwanicki,blake $P shots=110,150 tag=readme_p3n5 quit_at=152 $C
# Jefes: un jugador solo y sin armas (los bots disparan siempre, y con las armas al nivel de la
# parte el jefe cae en segundos y sale siempre con el destello del golpe), con más cámara.
# boss=true salta al jefe en el nivel 5 de la parte 2; en el de la parte 3 daría a Cthulhu recompuesto.
B="bot=smart autopick=true god=true timescale=2 noweapons=true cam=20 cfg_flashes=0 final_at=3 shots=8,12,16,20,25,30,36,44,52 quit_at=53"
run $G level=p1_n5 character=dyer $B tag=readme_jefe1 $C
run $G level=p2_n5 character=olmstead $B boss=true tag=readme_jefe2 $C
run $G level=p3_n5 character=legrasse $B tag=readme_jefe3 $C
# Vídeo para el GIF: partida a cuatro en las calles de Innsmouth (30 s de juego, 900 fotogramas)
mkdir -p shots/videos
run godot --path . --write-movie shots/videos/readme_partida.avi --fixed-fps 30 --quit-after 900 -- \
	level=p2_n2 character=legrasse bots=3 bot_chars=varga,elwood,malone bot=smart autopick=true god=true \
	cfg_flashes=0 xp=2500 max_alive=110 spawn_rate=12 $C
# Portada y menús
godot --headless --path . -- test_save=1 saves=readme_saves > /dev/null 2>&1
run $G title shots=11 tag=readme $C
run $G title saves=demo_saves open=menu_tienda shots=14 tag=readme_tienda $C            # con logros a medias y poco dinero
run $G title saves=readme_saves slot=1 open=menu_biblioteca shots=14 tag=readme_biblio $C
run $G title saves=demo_saves open=menu_logros shots=14 tag=readme_logros $C
run $G title saves=demo_saves open=menu_online shots=14 tag=readme_online $C
run $G select saves=readme_saves slot=1 join=4 pick=dyer,varga,elwood,malone pets=4 shots=3 tag=readme_sel $C
run $G select saves=readme_saves slot=1 join=1 map=true shots=2 tag=readme_mapa $C
run $G relato level=p3_n5 shots=12 tag=readme_relato $C
run $G level=p2_n1 character=peaslee pet=gato bot=smart god=true autopick=true xp=1500 \
	weapons=palanca,bumeran,tesla,necronomicon wlevel=4 items=lupa,botiquin,crampones,ojo_pickman ilevel=3 \
	panel=sheet panel_at=12 shots=13 tag=readme_ficha quit_at=14 cfg_flashes=0 $C
# Modelos
for grp in dyer,olmstead,legrasse,johansen,peaslee,varga,whipple blake,iwanicki,elwood,malone,armitage,west \
	perro,gato,rata,sapo buho,shoggoth,byakhee,cuervo polilla,gaviota,migo,tindalos yig,pez,dhole,cabra \
	pinguino,fragmento,antiguo,antiguo_alado,shoggoth_grande antiguo_guerrero,antiguo_mutilado,shoggoth_ojos,antiguo_abisal \
	habitante_viejo,habitante_mujer,acolito,hibrido_h,hibrido_m sacerdote,profundo,profundo_lanzador,profundo_anciano,acechador \
	cultista,cultista_alert,pesadilla,diablo engendro,polipo,emanacion,primigenio_menor; do
	run $G still 0 $grp size=2000x2000 tag=readme $C
done
for pj in dyer olmstead legrasse johansen peaslee varga whipple blake iwanicki elwood malone armitage west; do
	run $G still 20 $pj size=1600x1600 tag=readme $C
done
