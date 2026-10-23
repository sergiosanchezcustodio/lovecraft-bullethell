#!/bin/sh
# Builds de Windows y macOS (hito 8.5). Comprime los modelos (models/*.json.z: la build no
# lleva los .json) y exporta con los perfiles de export_presets.cfg.
# Uso (Git Bash, desde la raíz): sh tools/exportar.sh [versión]
# Antes pregunta si subir la versión del juego (application/config/version en project.godot):
# en red, la sala no deja empezar a PCs con versiones distintas, así que cada build que se
# reparte debe llevar la suya. Con la versión como argumento no pregunta; sin terminal
# (ejecuciones automáticas) deja la que hay.
set -e
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
godot --headless --path . -s tools/empaquetar_modelos.gd
mkdir -p builds/windows builds/macos
godot --headless --path . --export-release "Windows Desktop" builds/windows/LovecraftLibrary.exe
godot --headless --path . --export-release "macOS" builds/macos/LovecraftLibrary.zip
ls -la builds/windows builds/macos
