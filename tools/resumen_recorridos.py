# Resumen de los recorridos de las ventanas (06-11-2026): junta los informe.txt de
# shots/ui_recorrido*/ (tools/recorrido_ui.py, uno por tamaño de interfaz o de pantalla) en una
# tabla, con una fila por ventana y una columna por recorrido, para ver de un vistazo qué ventana
# falla en cuál. En cada casilla, los avisos UICHK (· si no hay, «E» si hubo errores de script,
# «–» si no se pasó, «?» si no salió captura).
# Uso, desde la raíz:  python tools/resumen_recorridos.py [--detalle]
#   -> en la consola y en shots/ui_recorrido_resumen.txt. Con --detalle, debajo, los avisos.
import glob, os, re, sys, time
if hasattr(sys.stdout, 'reconfigure'): sys.stdout.reconfigure(encoding='utf-8')   # la consola de Windows
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace(os.sep, '/')
NAMES = {'': 'normal', 'pequena': 'pequeña', 'grande115': 'grande', 'grande': 'muy grande',
         'deck': '1280×800', 'panoramica': '2560×1080'}
ORDER = ['', 'pequena', 'grande115', 'grande', 'deck', 'panoramica']


def read(path):
    """{ventana: [capturas, [avisos], [errores]]} de un informe.txt (la última vez que se pasó)."""
    out, cur = {}, None
    for line in open(path, encoding='utf-8'):
        m = re.match(r'== (\S+) \(\d+ s, (\d+) capturas\)', line)
        if m:
            cur = m.group(1)
            out[cur] = [int(m.group(2)), [], []]
        elif cur and 'UICHK' in line:
            out[cur][1].append(line.strip())
        elif cur and 'SCRIPT ERROR' in line:
            out[cur][2].append(line.strip())
    return out


def main():
    runs, when = {}, {}
    for d in glob.glob(ROOT + '/shots/ui_recorrido*/'):
        suf = os.path.basename(d.rstrip('/\\'))[len('ui_recorrido'):].lstrip('_')
        # el <ventana>.txt de cada una (recorrido_ui.py), en el orden de informe.txt; si no los hay, informe.txt
        order = list(read(d + 'informe.txt')) if os.path.exists(d + 'informe.txt') else []
        ones = {os.path.basename(f)[:-4]: f for f in glob.glob(d + '*.txt') if os.path.basename(f) != 'informe.txt'}
        if ones:
            runs[suf], dates = {}, []
            for w in order + sorted(w for w in ones if w not in order):
                if w not in ones: continue
                runs[suf].update(read(ones[w]))
                dates.append(os.path.getmtime(ones[w]))
            fmt = lambda t: time.strftime('%d-%m %H:%M', time.localtime(t))
            when[suf] = fmt(min(dates)) + ('' if fmt(min(dates)) == fmt(max(dates)) else ' a ' + fmt(max(dates)))
        elif order:
            runs[suf] = read(d + 'informe.txt')
            when[suf] = time.strftime('%d-%m %H:%M', time.localtime(os.path.getmtime(d + 'informe.txt')))
    if not runs:
        print('No hay recorridos: python tools/recorrido_ui.py')
        return
    cols = [s for s in ORDER if s in runs] + sorted(s for s in runs if s not in ORDER)
    heads = [NAMES.get(s, s) for s in cols]
    wins = []                                   # en el orden del recorrido más completo
    for s in sorted(cols, key=lambda s: -len(runs[s])):
        for w in runs[s]:
            if w not in wins: wins.append(w)
    width = max(len(w) for w in wins) + 2
    cw = [max(len(h), 4) + 2 for h in heads]

    def cell(s, w):
        if w not in runs[s]: return '–'
        shots, warns, errs = runs[s][w]
        if errs: return 'E%s' % (len(warns) or '')
        if shots == 0: return '?'
        return str(len(warns)) if warns else '·'

    lines = ['Recorridos de las ventanas: avisos UICHK por ventana y tamaño (· ninguno, E errores, – sin pasar, ? sin captura)', '']
    lines.append(''.ljust(width) + ''.join(h.center(c) for h, c in zip(heads, cw)))
    bad = 0
    for w in wins:
        cells = [cell(s, w) for s in cols]
        if any(c not in '·–' for c in cells): bad += 1
        lines.append(w.ljust(width) + ''.join(c.center(n) for c, n in zip(cells, cw)))
    lines += ['', 'Ventanas con algo: %d de %d.' % (bad, len(wins)), 'Cada recorrido (ventanas pasadas, de cuándo):']
    lines += ['  %-11s %2d  %s' % (NAMES.get(s, s), len(runs[s]), when[s]) for s in cols]
    if '--detalle' in sys.argv:
        for s in cols:
            for w, (_, warns, errs) in runs[s].items():
                for l in errs + warns: lines.append('[%s] %s: %s' % (NAMES.get(s, s), w, l))
    text = '\n'.join(lines)
    print(text)
    open(ROOT + '/shots/ui_recorrido_resumen.txt', 'w', encoding='utf-8').write(text + '\n')


if __name__ == '__main__':
    main()
