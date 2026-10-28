#!/usr/bin/env bash
# Godot para las pruebas lanzadas desde Claude Code (CLAUDECODE=1, ver ~/bin/godot), para que el
# autor pueda jugar a otra cosa en el mismo PC mientras. Pone un override.cfg pasajero, que Godot
# lee al arrancar y se borra a los 4 s (si otra prueba lo ha vuelto a escribir entre medias, lo
# borra la última; uno que no sea de aquí no se toca), con:
# - display/window/size/no_focus: la ventana se abre sin quitar el foco (ShowWindow con SW_SHOWNA,
#   sin SetForegroundWindow). Godot no tiene opción para eso en la línea de órdenes.
# - display/window/size/borderless y --resolution 3x3: Godot no deja crear la ventana fuera de la
#   pantalla (deja a la vista un tercio), así que se crea de 3×3 px sin bordes: un píxel a la
#   vista. La partida (main.gd, con LOVECRAFT_FUERA=1) le devuelve su tamaño y la saca a la
#   derecha de todas las pantallas, donde se dibuja y se captura igual. ver=true la deja a la
#   vista, centrada y con bordes. Con --resolution, --position o pantalla completa no se toca el
#   tamaño ni el sitio; grabando vídeo (--write-movie toma el tamaño al arrancar), solo el sitio.
# - application/run/low_processor_mode: al arrancar, Godot sube la prioridad del proceso y se
#   apunta en Windows como «Games» (MMCSS), y eso le quita tiempo de CPU a tu juego; en modo de
#   bajo consumo no lo hace. Devices lo quita enseguida: la prueba va igual, con prioridad normal.
# Los mandos los ignora la propia partida (JoypadInput.disabled).
# Sin ventana (--headless, -s, --import), arranca tal cual.
GODOT="/c/Tools/Godot/Godot_v4.4.1-stable_win64_console.exe"
dir="."
prev=""
own=0
movie=0
for a in "$@"; do
	[ "$prev" = "--path" ] && dir="$a"
	case "$a" in
		--headless|-s|--script|--import|--export-*) exec "$GODOT" "$@" ;;
		--resolution|--position|-f|--fullscreen|-m|--maximized) own=1 ;;
		--write-movie) movie=1 ;;
	esac
	prev="$a"
done
pre=()
if [ $own = 0 ]; then
	if [ $movie = 0 ]; then pre=(--resolution 3x3 --position 100000,100000)
	else pre=(--position 100000,100000); fi
fi
export LOVECRAFT_FUERA=1
ov="$dir/override.cfg"
MARK="; pasajero de tools/godot_sin_foco.sh"
if [ -f "$ov" ] && ! grep -q "$MARK" "$ov"; then exec "$GODOT" "${pre[@]}" "$@"; fi
{
	echo "$MARK"
	echo "[application]"
	echo "run/low_processor_mode=true"
	echo "[display]"
	echo "window/size/no_focus=true"
	echo "window/size/borderless=true"
} > "$ov"
( sleep 4
  [ -f "$ov" ] && [ $(( $(date +%s) - $(stat -c %Y "$ov") )) -ge 4 ] && grep -q "$MARK" "$ov" && rm -f "$ov" ) >/dev/null 2>&1 &
exec "$GODOT" "${pre[@]}" "$@"
