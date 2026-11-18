#!/bin/bash
# Prueba de la demo exportada (hito 23.2): que no le falta nada de lo que enseña.
# La demo va sin lo que solo usan las partes 2 a 4 y las noches (tools/demo_fuera.py). Aquí se
# juega la parte 1 entera con el bot (hasta su evento final) y se abren los menús que enseñan
# modelos e imágenes con una partida del juego completo (saves=demo_completa, de
# tools/partida_completa.py: todo visto, ganado y comprado), que es lo que pasa si alguien con el
# juego completo abre la demo. Con la build del juego completo como `exe`, prueba lo mismo en ella. Cada ejecución escribe su registro y
# se cuentan los errores: un modelo que no está («Modelo que no está»), un recurso que no se
# carga… Las fugas al salir con --quit-after («resources still in use», «RID allocations») no
# cuentan. Cada ejecución deja una captura en user://shots (demo_<n>_…png) para mirarla.
#
# Uso: sh tools/probar_demo.sh [exe]   (por defecto builds/demo/windows/LovecraftLibraryDemo.exe)
cd "$(dirname "$0")/.."
python tools/partida_completa.py demo_completa
EXE="$(cygpath -w "${1:-builds/demo/windows/LovecraftLibraryDemo.exe}")"
DIR="${TMP:-/tmp}/probar_demo"
mkdir -p "$DIR"
OUT="$DIR/resumen.txt"
: > "$OUT"
BAD='ERROR|SCRIPT ERROR|No se pudo|not found|Modelo que no|Failed loading|Cannot open'
IGNORE='still in use at exit|leaked at exit|Unreferenced static string|Pages in use exist at exit|were never freed'
fails=0
i=0
run() {
	i=$((i + 1))
	log="$DIR/run_$i.log"
	rm -f "$log"
	timeout 200 python tools/escritorio_aparte.py "$EXE" --resolution 1280x720 --log-file "$(cygpath -w "$log")" -- mute=true window=true tag=demo_$i "$@" > /dev/null 2>&1
	n=$(grep -E "$BAD" "$log" 2>/dev/null | grep -v -E "$IGNORE" | wc -l)
	[ -f "$log" ] || n="sin registro"
	echo "$* -> $n" | tee -a "$OUT"
	if [ "$n" != "0" ]; then
		fails=$((fails + 1))
		grep -E "$BAD" "$log" 2>/dev/null | grep -v -E "$IGNORE" | sort | uniq -c | head -8 | tee -a "$OUT"
	fi
}
# La parte 1, nivel a nivel, con el evento final a los 20 s (el jefe en el 1.5)
for lv in p1_n1 p1_n2 p1_n3 p1_n4 p1_n5; do
	run level=$lv bot=smart god=true autopick=true final_at=20 bots=3 timescale=2 shots=40 quit_at=45
done
# Con una partida del juego completo (la portada abre el menú al acabar su entrada, a los 11 s): portada, selección, mapa, tienda, vestuario y la Biblioteca
S=saves=demo_completa
run title $S shots=12 quit_at=14
run select $S join=4 vest=3 shots=6 quit_at=8
run select $S map=true shots=6 quit_at=8
run title $S open=menu_tienda tab=0 shots=16 quit_at=18
run title $S open=menu_tienda tab=1 shots=16 quit_at=18
run title $S open=menu_tienda tab=2 shots=16 quit_at=18
run title $S open=menu_tienda tab=3 shots=16 quit_at=18
run title $S open=menu_tienda tab=4 shots=16 quit_at=18
for t in 0 1 2 3 4 5 6 7 8 9 10 11 12; do
	run title $S open=menu_biblioteca tome=$t shots=16 quit_at=18
done
for c in 5 15 25 40 60; do                       # más abajo en el bestiario, los lugares y los relatos
	run title $S open=menu_biblioteca tome=0 cursor=$c shots=16 quit_at=18
done
for c in 5 12 22; do
	run title $S open=menu_biblioteca tome=3 cursor=$c shots=16 quit_at=18
	run title $S open=menu_biblioteca tome=7 cursor=$c shots=16 quit_at=18
	run title $S open=menu_biblioteca tome=4 cursor=$c shots=16 quit_at=18
	run title $S open=menu_biblioteca tome=8 cursor=$c shots=16 quit_at=18
done
run relato level=p1_n1 shots=6 quit_at=8
echo "$fails con errores (registros en $DIR)" | tee -a "$OUT"
[ "$fails" = "0" ]
