#!/bin/sh
# Capturas para las imágenes del README (23-10-2026; ampliadas el 18-11-2026, hito 23.3, con la parte 4,
# las noches sueltas, Nyarlathotep, los personajes de las fases 16 y 20 y las criaturas nuevas).
# Después: python tools/montar_readme.py
# Uso (Git Bash, desde la raíz): sh tools/capturas_readme.sh   (algo más de una hora, todo en ventana)
# - En calidad Alta (cfg_quality=3), sin tintes de estado ni consejos ni diálogos que tapen la acción.
# - Partidas con cuatro bots invulnerables (god=true) a velocidad doble y con los destellos de
#   los golpes reducidos (cfg_flashes=0): con los normales, los enemigos golpeados salen en blanco.
# - Menús con la partida de pruebas con todo desbloqueado (user://readme_saves, hueco 1).
# - Modelos en capturas cuadradas: el visor encuadra el grupo como si la ventana fuera cuadrada.
cd "$(dirname "$0")/.."
G="godot --path . --"
C="mute=true window=true cfg_quality=3"
P="bot=smart autopick=true god=true timescale=2 cfg_flashes=0 tints=false tips=false bond_talk=false night_events=false peddler=false"
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
# Parte 4 y noches sueltas (hito 23.3), con los personajes de las fases 16 y 20
run $G level=p4_n1 character=carter bots=3 bot_chars=kuranes,pickman,gilman cats_here=60 $P shots=80,110,150 tag=readme_p4n1 quit_at=152 $C
run $G level=p4_n3 character=tillinghast bots=3 bot_chars=derby,ward,whateley $P shots=80,110,150 tag=readme_p4n3 quit_at=152 $C
run $G level=noche_color character=tillinghast bots=1 bot_chars=ward $P shots=80,110,150 tag=readme_color quit_at=152 $C
run $G level=noche_zann character=derby bots=1 bot_chars=pickman $P final_at=60 shots=80,100,110 tag=readme_zann quit_at=112 $C
# Jefes: un jugador solo y sin armas (los bots disparan siempre, y con las armas al nivel de la
# parte el jefe cae en segundos y sale siempre con el destello del golpe), con más cámara.
# boss=true salta al jefe en el nivel 5 de la parte 2; en el de la parte 3 daría a Cthulhu recompuesto.
B="bot=smart autopick=true god=true timescale=2 noweapons=true cam=20 cfg_flashes=0 final_at=3 shots=8,12,16,20,25,30,36,44,52 quit_at=53"
run $G level=p1_n5 character=dyer $B tag=readme_jefe1 $C
run $G level=p2_n5 character=olmstead $B boss=true tag=readme_jefe2 $C
run $G level=p3_n5 character=legrasse $B tag=readme_jefe3 $C
run $G level=p4_n5 character=carter $B tag=readme_jefe4 $C
# Vídeo para el GIF y el MP4: partida a cuatro en las calles de Innsmouth (30 s de juego, 900 fotogramas).
# Sin mute=true, que en la grabación silencia también los efectos: el MP4 lleva el sonido del juego.
mkdir -p shots/videos
run godot --path . --write-movie shots/videos/readme_partida.avi --fixed-fps 30 --quit-after 900 -- \
	level=p2_n2 character=legrasse bots=3 bot_chars=varga,elwood,malone bot=smart autopick=true god=true \
	cfg_flashes=0 xp=2500 max_alive=110 spawn_rate=12 window=true
# Portada y menús
godot --headless --path . -- test_save=1 saves=readme_saves > /dev/null 2>&1
run $G title shots=11 tag=readme $C
run $G title saves=demo_saves open=menu_tienda shots=14 tag=readme_tienda $C            # con logros a medias y poco dinero
run $G title saves=readme_saves slot=1 open=menu_biblioteca shots=14 tag=readme_biblio $C
run $G title saves=demo_saves open=menu_logros shots=14 tag=readme_logros $C
run $G title saves=demo_saves open=menu_online shots=14 tag=readme_online $C
run $G select saves=readme_saves slot=1 join=4 pick=pickman,kuranes,derby,gilman pets=4 shots=3 tag=readme_sel $C
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
	cultista,cultista_alert,pesadilla,diablo engendro,polipo,emanacion,primigenio_menor 	carter,whateley,pickman,ward gilman,tillinghast,derby,asenath,kuranes 	pinguino,fragmento,acechador,antiguo antiguo_alado,expedicionario,antiguo_despierto,gedney 	shoggoth_grande,shoggoth_excavador,shoggoth_caverna,shoggoth_ojos antiguo_guerrero,antiguo_mutilado,antiguo_sembrador,antiguo_abisal 	habitante_pescador,habitante_mujer,habitante_viejo,acolito,diacono hibrido_h,hibrido_m,sacerdote,guardian_orden,sumo_sacerdote 	profundo,profundo_lanzador,hija_marsh,obed_marsh,nadador profundo_anciano,barnabas,pththya,acechador 	pesadilla,cultista,sonambulo,pesadilla_relieve cultista_alert,diablo,tamborilero,idolo_vivo,castro 	sacerdote_culto,engendro,polipo,polipo_madre emanacion,primigenio_menor 	zoog,zoog_copas,zoog_anciano,mercader_leng remero_lunar,bestia_lunar_mayor,shantak 	arana_leng,sacerdote_leng,arana_madre ghast,gug,gug_koth larva_otros,descarnado 	res_gris,granjero_gris,chotacabras,devota_colinas poseido_yith,polipo_volador,vecino_auseil,jiron_noche; do
	run $G still 0 $grp size=2000x2000 tag=readme $C
done
for pj in dyer olmstead legrasse johansen peaslee varga whipple blake iwanicki elwood malone armitage west 	carter whateley pickman ward gilman tillinghast derby kuranes; do
	run $G still 20 $pj size=1600x1600 tag=readme $C
done
