#!/usr/bin/env bash
# Godot para las pruebas lanzadas desde Claude Code (CLAUDECODE=1, ver ~/bin/godot), para que el
# autor pueda jugar a otra cosa en el mismo PC mientras:
# - La ventana se abre sin quitar el foco. Godot no tiene opción para eso en la línea de órdenes,
#   así que se pone un override.cfg pasajero con display/window/size/no_focus=true, que Godot lee
#   al arrancar y se borra a los 4 s (si otra prueba lo ha vuelto a escribir entre medias, lo
#   borra la última). Uno que no sea de aquí no se toca.
# - No tapa nada: se abre diminuta y la partida (main.gd, con LOVECRAFT_FUERA=1) le devuelve su
#   tamaño y la saca a la derecha de todas las pantallas, donde se dibuja y se captura igual.
#   ver=true la deja a la vista. Con --resolution, --position o pantalla completa no se toca el
#   tamaño ni el sitio; grabando vídeo (--write-movie toma el tamaño al arrancar), solo el sitio.
# - Los mandos los ignora la propia partida (JoypadInput.disabled).
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
	if [ $movie = 0 ]; then pre=(--resolution 192x108 --position 100000,100000)
	else pre=(--position 100000,100000); fi
fi
export LOVECRAFT_FUERA=1
ov="$dir/override.cfg"
MARK="; pasajero de tools/godot_sin_foco.sh"
if [ -f "$ov" ] && ! grep -q "$MARK" "$ov"; then exec "$GODOT" "${pre[@]}" "$@"; fi
printf '%s\n[display]\n\nwindow/size/no_focus=true\n' "$MARK" > "$ov"
( sleep 4
  [ -f "$ov" ] && [ $(( $(date +%s) - $(stat -c %Y "$ov") )) -ge 4 ] && grep -q "$MARK" "$ov" && rm -f "$ov" ) >/dev/null 2>&1 &
exec "$GODOT" "${pre[@]}" "$@"
