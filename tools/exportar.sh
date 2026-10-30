#!/bin/sh
# Builds de Windows y macOS (hito 8.5) y de la demo de la parte 1 (hito 13.17, en builds/demo/).
# Comprime los modelos (models/*.json.z: la build no lleva los .json) y exporta con los perfiles
# de export_presets.cfg.
# Uso (Git Bash, desde la raíz): sh tools/exportar.sh [versión]
# Antes pregunta si subir la versión del juego (application/config/version en project.godot):
# en red, la sala no deja empezar a PCs con versiones distintas, así que cada build que se
# reparte debe llevar la suya. Con la versión como argumento no pregunta; sin terminal
# (ejecuciones automáticas) deja la que hay. Antes de exportar, tools/revisar_costados.py
# comprueba los costados de todos los personajes y prendas y, si falla, no sigue. Con terminal,
# ofrece además comparar las 15 arenas con su referencia y medir los 15 niveles (hito 13.14).
set -e
# los costados de personajes y prendas, enteros (si una manga borra el tronco, se ve al andar)
python tools/revisar_costados.py
actual=$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)
nueva="$1"
if [ -z "$nueva" ] && [ -t 0 ]; then
	printf 'Versión actual: %s. ¿Nueva versión? (Intro para dejarla): ' "$actual"
	read -r nueva
fi
if [ -n "$nueva" ] && [ "$nueva" != "$actual" ]; then
	sed -i "s/^config\/version=\".*\"$/config\/version=\"$nueva\"/" project.godot
	echo "Versión: $actual -> $nueva"
else
	echo "Versión: $actual"
fi
if [ -t 0 ]; then
	printf '¿Comparar las 15 arenas con su referencia antes? (s/N): '
	read -r r
	if [ "$r" = "s" ]; then python tools/comparar_arenas.py; fi
	printf '¿Medir el rendimiento de los 15 niveles (unos 15 minutos)? (s/N): '
	read -r r
	if [ "$r" = "s" ]; then python tools/medir_niveles.py; fi
fi
godot --headless --path . -s tools/empaquetar_modelos.gd
mkdir -p builds/windows builds/macos builds/demo/windows builds/demo/macos
godot --headless --path . --export-release "Windows Desktop" builds/windows/LovecraftLibrary.exe
godot --headless --path . --export-release "macOS" builds/macos/LovecraftLibrary.zip
godot --headless --path . --export-release "Windows Demo" builds/demo/windows/LovecraftLibraryDemo.exe
godot --headless --path . --export-release "macOS Demo" builds/demo/macos/LovecraftLibraryDemo.zip
ls -la builds/windows builds/macos builds/demo/windows builds/demo/macos
