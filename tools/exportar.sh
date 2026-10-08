#!/bin/sh
# Builds de Windows y macOS (hito 8.5). Comprime los modelos (models/*.json.z: la build no
# lleva los .json) y exporta con los perfiles de export_presets.cfg.
# Uso (Git Bash, desde la raíz): sh tools/exportar.sh
set -e
godot --headless --path . -s tools/empaquetar_modelos.gd
mkdir -p builds/windows builds/macos
godot --headless --path . --export-release "Windows Desktop" builds/windows/LovecraftLibrary.exe
godot --headless --path . --export-release "macOS" builds/macos/LovecraftLibrary.zip
ls -la builds/windows builds/macos
