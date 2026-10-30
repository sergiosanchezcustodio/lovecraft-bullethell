#!/bin/sh
# Publica una versión (hito 13.15): sube la versión del juego en project.godot, hace el commit y la
# etiqueta v<versión> y, tras confirmar, lo sube a GitHub. La etiqueta lanza las builds de Windows y
# macOS en GitHub Actions (.github/workflows/build.yml), que acaban en una Release en borrador:
# revísala en GitHub (Releases) y publícala a mano.
# Uso (Git Bash, desde la raíz): sh tools/publicar.sh 0.9.1
set -e
nueva="$1"
if [ -z "$nueva" ]; then
	echo "Uso: sh tools/publicar.sh <versión>   (p. ej. 0.9.1)"
	exit 1
fi
if [ -n "$(git status --porcelain)" ]; then
	echo "Hay cambios sin guardar en git: haz el commit antes de publicar."
	exit 1
fi
if git rev-parse -q --verify "refs/tags/v$nueva" > /dev/null; then
	echo "La etiqueta v$nueva ya existe."
	exit 1
fi
actual=$(sed -n 's/^config\/version="\(.*\)"$/\1/p' project.godot)
if [ "$nueva" != "$actual" ]; then
	sed -i "s/^config\/version=\".*\"$/config\/version=\"$nueva\"/" project.godot
	git add project.godot
	git commit -q -m "Versión $nueva"
	echo "Versión: $actual -> $nueva"
fi
git tag -a "v$nueva" -m "Lovecraft Library $nueva"
printf '¿Subir la versión %s a GitHub? Se harán las builds y una Release en borrador (s/N): ' "$nueva"
read -r r
if [ "$r" = "s" ]; then
	git push -q
	git push -q origin "v$nueva"
	echo "Subida. Sigue las builds en GitHub (Actions); en unos 15 minutos estará la Release en borrador."
else
	echo "No se ha subido nada. Para subirla luego: git push && git push origin v$nueva"
	echo "Para deshacerlo: git tag -d v$nueva  (y, si subió la versión, git reset --hard HEAD~1)"
fi
