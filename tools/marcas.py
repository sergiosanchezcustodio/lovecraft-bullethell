"""Marcas de los registros de red (F9 o LB+RB en partida), con las líneas de alrededor.

Para revisar una prueba online: cada marca sale con unas líneas de antes (estado de la partida
cada 5 s, paradas, quién entra o se va) y de después, fichero a fichero.

Uso (desde la raíz):
    python tools/marcas.py                      # los registros de este PC (user://logs/red)
    python tools/marcas.py red_2026-10-23_*.log # los que te pasen (los de otro PC, por ejemplo)
    python tools/marcas.py --antes 12 --despues 6
"""
import argparse
import glob
import os
import sys

APP = "Lovecraft Bullet Hell"


def default_dir() -> str:
    if sys.platform == "win32":
        base = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata")
    elif sys.platform == "darwin":
        base = os.path.expanduser("~/Library/Application Support/Godot/app_userdata")
    else:
        base = os.path.expanduser("~/.local/share/godot/app_userdata")
    return os.path.join(base, APP, "logs", "red")


def is_mark(line: str) -> bool:
    # "[hh:mm:ss] marca 3 del jugador · p1_n2 1:05" o "[...] marca 1 de Ana · ..."
    text = line.split("] ", 1)[-1]
    return text.startswith("marca ")


def show(path: str, before: int, after: int) -> int:
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()
    marks = [i for i, l in enumerate(lines) if is_mark(l)]
    if not marks:
        return 0
    print(f"=== {os.path.basename(path)}  ({lines[0] if lines else ''})")
    shown = -1
    for i in marks:
        lo = max(i - before, shown + 1)
        if lo > shown + 1 and shown >= 0:
            print("   ...")
        for k in range(lo, min(i + after + 1, len(lines))):
            if k <= shown:
                continue
            print((">> " if is_mark(lines[k]) else "   ") + lines[k])
            shown = k
    print()
    return len(marks)


def main() -> None:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")       # la consola de Windows no siempre lo es
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="*", help="registros (por defecto, todos los de este PC)")
    ap.add_argument("--antes", type=int, default=8, help="líneas antes de cada marca (8)")
    ap.add_argument("--despues", type=int, default=3, help="líneas después de cada marca (3)")
    a = ap.parse_args()
    files = []
    for f in a.files:
        files.extend(sorted(glob.glob(f)) or [f])
    if not files:
        d = default_dir()
        files = sorted(glob.glob(os.path.join(d, "red_*.log")))
        if not files:
            print(f"No hay registros en {d}")
            return
    total = 0
    with_marks = 0
    for f in files:
        n = show(f, a.antes, a.despues)
        total += n
        with_marks += n > 0
    print(f"{total} marcas en {with_marks} de {len(files)} registros")


if __name__ == "__main__":
    main()
