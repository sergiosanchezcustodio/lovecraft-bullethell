#!/usr/bin/env bash
# Godot para las pruebas lanzadas desde Claude Code (CLAUDECODE=1, ver ~/bin/godot): la ventana
# se abre sin quitar el foco a lo que tengas delante (otro juego, por ejemplo). Godot no tiene
# opción para eso en la línea de órdenes, así que se pone un override.cfg pasajero con
# display/window/size/no_focus=true, que Godot lee al arrancar y se borra a los 4 s (si otra
# prueba lo ha vuelto a escribir entre medias, lo borra la última). Sin ventana (--headless,
# -s), arranca tal cual. Los mandos los ignora la propia partida (Devices.no_pads).
GODOT="/c/Tools/Godot/Godot_v4.4.1-stable_win64_console.exe"
dir="."
prev=""
for a in "$@"; do
	[ "$prev" = "--path" ] && dir="$a"
	case "$a" in --headless|-s|--script|--import|--export-*) exec "$GODOT" "$@" ;; esac
	prev="$a"
done
ov="$dir/override.cfg"
MARK="; pasajero de tools/godot_sin_foco.sh"
if [ -f "$ov" ] && ! grep -q "$MARK" "$ov"; then exec "$GODOT" "$@"; fi   # uno tuyo: no se toca
printf '%s\n[display]\n\nwindow/size/no_focus=true\n' "$MARK" > "$ov"
( sleep 4
  [ -f "$ov" ] && [ $(( $(date +%s) - $(stat -c %Y "$ov") )) -ge 4 ] && grep -q "$MARK" "$ov" && rm -f "$ov" ) >/dev/null 2>&1 &
exec "$GODOT" "$@"
