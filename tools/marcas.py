"""Marcas de los registros de red (F9 o LB+RB en partida), con las líneas de alrededor.

Para revisar una prueba online: cada marca sale con unas líneas de antes (estado de la partida
cada 5 s, paradas, quién entra o se va) y de después, fichero a fichero. Avisa de los registros
que no acaban en «Fin de la sesión» (el juego se cerró de golpe o sigue abierto) y dice dónde
está la captura de cada marca, si la hay.

Con --juntar, los registros de varios PC salen en una sola lista ordenada por hora, cada línea
con la letra de su fichero. Los relojes de dos PC no van iguales: la diferencia se saca de las
marcas, que se apuntan en todos («marca 3 del jugador · p1_n2 1:05» en uno y «marca 3 de Ana ·
p1_n2 1:05» en el otro), y se corrige.

Uso (desde la raíz):
    python tools/marcas.py                      # los registros de este PC (user://logs/red)
    python tools/marcas.py red_2026-10-23_*.log # los que te pasen (los de otro PC, por ejemplo)
    python tools/marcas.py --antes 12 --despues 6
    python tools/marcas.py --juntar mio.log suyo.log          # los dos PC en una lista
    python tools/marcas.py --juntar --todo mio.log suyo.log   # entera, no solo alrededor de las marcas
"""
import argparse
import datetime as dt
import glob
import os
import re
import statistics
import sys

APP = "Lovecraft Bullet Hell"
END = "Fin de la sesión"
LINE = re.compile(r"^\[(\d\d):(\d\d):(\d\d)\] (.*)$")
STAMP = re.compile(r"red_(\d{4})-(\d\d)-(\d\d)_(\d\d)-(\d\d)-(\d\d)")
# "marca 3 del jugador · p1_n2 1:05" (en su PC) o "marca 3 de Ana · p1_n2 1:05 (aquí: …)" (en los demás)
MARK = re.compile(r"^marca (\d+) (?:del jugador|de .+?) · (.+?)(?: \(aquí: .*\))?$")


def default_dir() -> str:
    if sys.platform == "win32":
        base = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata")
    elif sys.platform == "darwin":
        base = os.path.expanduser("~/Library/Application Support/Godot/app_userdata")
    else:
        base = os.path.expanduser("~/.local/share/godot/app_userdata")
    return os.path.join(base, APP, "logs", "red")


def is_mark(line: str) -> bool:
    text = line.split("] ", 1)[-1]
    return text.startswith("marca ")


def shot_of(path: str, line: str) -> str:
    """Captura de una marca (la guarda el juego junto al registro: <registro>_marca_N.png)."""
    m = MARK.match(line.split("] ", 1)[-1])
    if not m or "del jugador" not in line:
        return ""
    p = "%s_marca_%s.png" % (os.path.splitext(path)[0], m.group(1))
    return os.path.normpath(p) if os.path.exists(p) else ""


def ended(lines: list) -> bool:
    return any(END in l for l in lines[-3:])


def parse(path: str) -> list:
    """[(hora, texto, línea entera)]: la fecha sale del nombre del fichero y pasa de día si la hora vuelve atrás."""
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()
    m = STAMP.search(os.path.basename(path))
    day = dt.datetime(*map(int, m.groups())) if m else dt.datetime(2000, 1, 1)
    day = day.replace(hour=0, minute=0, second=0)
    out = []
    prev = None
    for l in lines:
        lm = LINE.match(l)
        if not lm:
            continue
        t = day + dt.timedelta(hours=int(lm.group(1)), minutes=int(lm.group(2)), seconds=int(lm.group(3)))
        if prev is not None and t < prev - dt.timedelta(hours=1):     # medianoche
            day += dt.timedelta(days=1)
            t += dt.timedelta(days=1)
        prev = t
        out.append((t, lm.group(4), l))
    return out


def context(rows: list, before: int, after: int, mark_of) -> None:
    marks = [i for i, r in enumerate(rows) if mark_of(r)]
    shown = -1
    for i in marks:
        lo = max(i - before, shown + 1)
        if lo > shown + 1 and shown >= 0:
            print("   ...")
        for k in range(lo, min(i + after + 1, len(rows))):
            if k <= shown:
                continue
            yield_line(rows[k], mark_of(rows[k]))
            shown = k


def yield_line(row, marked: bool) -> None:
    print((">> " if marked else "   ") + row[0])
    if marked and row[1]:
        print("      captura: " + row[1])


def show(path: str, before: int, after: int) -> int:
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = f.read().splitlines()
    marks = [i for i, l in enumerate(lines) if is_mark(l)]
    if not marks:
        return 0
    print(f"=== {os.path.basename(path)}  ({lines[0] if lines else ''})")
    rows = [(l, shot_of(path, l)) for l in lines]
    context(rows, before, after, lambda r: is_mark(r[0]))
    print()
    return len(marks)


def offset(base: list, other: list) -> tuple:
    """Cuánto hay que sumar a la hora de `other` para que vaya con `base`, y con cuántas marcas."""
    def keys(rows):
        d = {}
        for t, text, _ in rows:
            m = MARK.match(text)
            if m:
                d.setdefault((m.group(1), m.group(2)[:24]), t)
        return d
    a, b = keys(base), keys(other)
    diffs = [(a[k] - b[k]).total_seconds() for k in a if k in b]
    if not diffs:
        return 0.0, 0
    return statistics.median(diffs), len(diffs)


def merge(files: list, before: int, after: int, everything: bool) -> None:
    parsed = [parse(f) for f in files]
    letters = [chr(ord("A") + i) for i in range(len(files))]
    for i, f in enumerate(files):
        head = parsed[i][0][1] if parsed[i] else ""
        line = f"{letters[i]}: {os.path.basename(f)}  ({head})"
        if i > 0:
            off, n = offset(parsed[0], parsed[i])
            if n:
                parsed[i] = [(t + dt.timedelta(seconds=off), x, l) for t, x, l in parsed[i]]
                line += f"  · reloj corregido {off:+.0f} s (por {n} marca{'s' if n != 1 else ''})"
            else:
                line += "  · sin marcas en común: horas tal cual (los relojes pueden no coincidir)"
        print(line)
    print()
    rows = []
    for i, p in enumerate(parsed):
        for t, text, l in p:
            rows.append((t, i, f"{letters[i]} {t:%H:%M:%S} {text}", shot_of(files[i], l)))
    rows.sort(key=lambda r: (r[0], r[1]))
    flat = [(r[2], r[3]) for r in rows]
    if everything:
        for r in flat:
            yield_line(r, " marca " in r[0][:16])
    else:
        context(flat, before, after, lambda r: r[0].split(" ", 2)[2].startswith("marca "))


def main() -> None:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")       # la consola de Windows no siempre lo es
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("files", nargs="*", help="registros (por defecto, todos los de este PC)")
    ap.add_argument("--antes", type=int, default=8, help="líneas antes de cada marca (8)")
    ap.add_argument("--despues", type=int, default=3, help="líneas después de cada marca (3)")
    ap.add_argument("--juntar", action="store_true", help="los registros de varios PC en una lista por hora")
    ap.add_argument("--todo", action="store_true", help="con --juntar, la lista entera")
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
    unfinished = []
    for f in files:
        with open(f, encoding="utf-8", errors="replace") as fh:
            if not ended(fh.read().splitlines()):
                unfinished.append(os.path.basename(f))
    if a.juntar:
        merge(files, a.antes, a.despues, a.todo)
    else:
        total = 0
        with_marks = 0
        for f in files:
            n = show(f, a.antes, a.despues)
            total += n
            with_marks += n > 0
        print(f"{total} marcas en {with_marks} de {len(files)} registros")
    for f in unfinished:
        print(f"Aviso: {f} no acaba en «{END}»: el juego se cerró de golpe (o sigue abierto).")


if __name__ == "__main__":
    main()
