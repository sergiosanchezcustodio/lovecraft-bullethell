#!/bin/sh
# Capturas para la página de itch.io (hito 22.8). Después: python tools/montar_itch.py
# Uso (Git Bash, desde la raíz): sh tools/capturas_itch.sh [es|en]   (unos 15 minutos por idioma)
# - 1920x1080 en calidad Alta (cfg_quality=3), con la interfaz de partida (es lo que se verá al jugar).
# - Bots invulnerables a velocidad doble, destellos reducidos (cfg_flashes=0: con los normales los
#   enemigos golpeados salen en blanco), sin tintes de estado (tints=false: con la quemadura, un jefe
#   sale naranja entero) y sin consejos ni diálogos que tapen la acción.
# - Varias capturas por partida; cuál se usa, en tools/montar_itch.py.
# - En inglés (en), lo mismo con cfg_language=en: la interfaz y los avisos salen traducidos.
cd "$(dirname "$0")/.."
L="${1:-es}"
T="itch_$L"
G="godot --path . --resolution 1920x1080 --"
C="mute=true window=true cfg_quality=3 cfg_language=$L"
P="bot=smart autopick=true god=true timescale=2 cfg_flashes=0 tints=false tips=false bond_talk=false night_events=false peddler=false"
run() { echo ">> $*"; "$@" 2>&1 | grep -E "captura|ERROR" | head -20; }

# 1. La Antártida a cuatro, con compañeros
run $G level=p1_n2 character=olmstead bots=3 bot_chars=peaslee,johansen,varga pets=gato,perro,cuervo,gato \
	$P wlevel=5 max_alive=80 spawn_rate=14 shots=40,60,80,100 tag=${T}_1 quit_at=101 $C
# 2. Las calles de Innsmouth, con la horda
run $G level=p2_n2 character=legrasse bots=3 bot_chars=varga,elwood,malone \
	$P wlevel=6 max_alive=110 spawn_rate=16 shots=40,60,80,100 tag=${T}_2 quit_at=101 $C
# 3. Cthulhu en R'lyeh
run $G level=p3_n5 character=legrasse bots=1 bot_chars=elwood $P final_at=3 dif_jefes=10 max_alive=20 spawn_rate=6 \
	shots=10,14,18,24,30 tag=${T}_3 quit_at=31 $C
# 4. Las Tierras del Sueño: Nyarlathotep en Kadath
run $G level=p4_n5 character=carter bots=1 bot_chars=kuranes $P final_at=3 dif_jefes=10 max_alive=20 spawn_rate=6 \
	shots=10,14,18,24,30 tag=${T}_4 quit_at=31 $C
# 4b. Ulthar con los gatos (alternativa)
run $G level=p4_n1 character=carter bots=1 bot_chars=kuranes cats_here=20 $P wlevel=5 max_alive=70 spawn_rate=14 \
	shots=30,40,50,60 tag=${T}_4b quit_at=61 $C
# 5. Noche suelta: la música de Erich Zann
run $G level=noche_zann character=derby bots=1 bot_chars=tillinghast $P final_at=3 dif_jefes=10 max_alive=40 spawn_rate=10 \
	shots=10,16,24,32,40 tag=${T}_5 quit_at=41 $C
# Portada (630x500, se recorta en montar_itch.py): la de la pantalla de título, sin el aviso; una
# vez con el progreso de ahora y otra con el juego acabado (más velas y el cielo de la parte 4).
if [ "$L" = "es" ]; then
	run $G title off=aviso,musica shots=6,8,10 tag=itch_portada $C
	run $G title off=aviso,musica progress=1 sky_part=4 shots=6,8,10 tag=itch_portada_fin $C
fi
