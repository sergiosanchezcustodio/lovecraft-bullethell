"""Medición de los 15 niveles (hito 13.14): rendimiento de cada nivel de la campaña en calidad Media
y Alta, con la tabla de la medición anterior al lado.

Cada medición es una partida con el bot, sin daño y con carga fija (`max_alive=80 spawn_rate=20`:
el tope se llena enseguida y todos los niveles se miden con la misma gente), `perf=8` (8 s tras
2 s de calentamiento) y sin sonido. Dos ejecuciones por nivel y calidad, y se queda con la mejor
(el 1 % peor varía mucho entre ejecuciones; la primera tras regenerar un modelo construye su
malla). Una sola ejecución a la vez: medir dos a la vez falsea las dos.

Guarda los resultados en docs/medidas_niveles.json (la de antes pasa a `anterior`) y reescribe
la sección «Medición de los 15 niveles» de docs/RENDIMIENTO.md.
Uso: python tools/medir_niveles.py [--niveles p1_n1,p2_n3] [--calidades 1,2] [--veces 2]
     python tools/medir_niveles.py --solo-tabla   (reescribe la tabla con lo guardado, sin medir)
Tarda unos 15 minutos con todo. Compara solo mediciones hechas en el mismo sitio (las pruebas
desde Claude Code van en un escritorio aparte, algo más rápido que el normal).
"""
import datetime, json, os, re, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, 'docs', 'medidas_niveles.json')
DOC = os.path.join(ROOT, 'docs', 'RENDIMIENTO.md')
SECTION = '## Medición de los 15 niveles'
QUALITY_NAMES = {0: 'Baja', 1: 'Media', 2: 'Alta', 3: 'Ultra'}
LINE = re.compile(r'RENDIMIENTO fotogramas=(\d+) media=([\d.]+) ms .*?1% peor=([\d.]+) ms .*?enemigos=(\d+) balas=(\d+) '
                  r'draw calls=(\d+) primitivas=(\d+)')


def levels():
    d = json.load(open(os.path.join(ROOT, 'data', 'campaign.json'), encoding='utf-8'))
    return [(lv['id'], lv['name']) for p in d['parts'] for lv in p['levels']]


def measure(level, q):
    cmd = ['bash', '-lc', 'godot --path . --disable-vsync --audio-driver Dummy -- level=%s bot=smart god=true mute=true autopick=true '
           'cfg_quality=%d max_alive=80 spawn_rate=20 perf=8' % (level, q)]
    out = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=240).stdout
    m = LINE.search(out)
    if not m: return None
    return {'media': float(m.group(2)), 'peor': float(m.group(3)), 'enemigos': int(m.group(4)), 'balas': int(m.group(5)),
            'llamadas': int(m.group(6)), 'primitivas': int(m.group(7))}


def version():
    for line in open(os.path.join(ROOT, 'project.godot'), encoding='utf-8'):
        if line.startswith('config/version='): return line.split('"')[1]
    return '?'


def cell(cur, old, key):
    if cur is None: return '—'
    s = '%.2f' % cur[key]
    if old is not None and key in old:
        d = cur[key] - old[key]
        s += ' (%.2f, %s%.0f %%)' % (old[key], '+' if d >= 0 else '−', abs(100 * d / max(old[key], 0.01)))
    return s.replace('.', ',')


def table(res, prev, names, quals):
    head = '| Nivel | ' + ' | '.join('%s: media (antes) | %s: 1 %% peor' % (QUALITY_NAMES[q], QUALITY_NAMES[q]) for q in quals) + ' | Primitivas (Alta) |'
    rows = [head, '|' + '---|' * (2 + 2 * len(quals))]
    for lid, name in names:
        r = res.get(lid, {})
        p = prev.get(lid, {}) if prev else {}
        cols = []
        for q in quals:
            cur, old = r.get(str(q)), p.get(str(q))
            cols += [cell(cur, old, 'media'), cell(cur, old, 'peor')]
        alta = r.get('2')
        prim = ('%.1f M' % (alta['primitivas'] / 1e6)).replace('.', ',') if alta else '—'
        rows.append('| %s · %s | %s | %s |' % (lid, name, ' | '.join(cols), prim))
    return '\n'.join(rows)


def write_doc(data, names, quals):
    txt = open(DOC, encoding='utf-8').read()
    body = ('%s\n\n*Última: %s, versión %s (`python tools/medir_niveles.py`).* Bot sin daño, 80 enemigos como tope y 8 s '
            'medidos; la mejor de %d ejecuciones. Entre paréntesis, la medición anterior (%s) y la diferencia. '
            'Milisegundos por fotograma: menos es mejor. Con 80 enemigos manda la CPU (la lógica de la partida), así que '
            'Media y Alta salen parecidas; entre ejecuciones, la media varía en torno a ±1 ms y el 1 %% peor bastante más: '
            'fíate de las diferencias grandes o de las que se repiten.\n\n%s\n') % (
        SECTION, data['fecha'], data['version'], data['veces'], data.get('anterior', {}).get('fecha', 'ninguna'),
        table(data['resultados'], data.get('anterior', {}).get('resultados'), names, quals))
    if SECTION in txt:
        i = txt.index(SECTION)
        j = txt.find('\n## ', i + len(SECTION))
        txt = txt[:i] + body + (txt[j:] if j >= 0 else '')
    else:
        txt = txt.rstrip('\n') + '\n\n' + body
    open(DOC, 'w', encoding='utf-8', newline='\n').write(txt)


def main():
    a = sys.argv[1:]
    names = levels()
    if '--niveles' in a:
        want = a[a.index('--niveles') + 1].split(',')
        names = [n for n in names if n[0] in want]
    quals = [int(x) for x in a[a.index('--calidades') + 1].split(',')] if '--calidades' in a else [1, 2]
    veces = int(a[a.index('--veces') + 1]) if '--veces' in a else 2
    old = json.load(open(DATA, encoding='utf-8')) if os.path.exists(DATA) else {}
    if '--solo-tabla' in a:                   # reescribe la tabla con lo guardado, sin medir
        write_doc(old, levels(), quals)
        return
    res ={k: dict(v) for k, v in old.get('resultados', {}).items()}       # lo que no se mide ahora se queda
    t0 = time.time()
    for lid, _ in names:
        for q in quals:
            best = None
            for _ in range(veces):
                m = measure(lid, q)
                if m and (best is None or m['media'] < best['media']): best = m
            if best:
                res.setdefault(lid, {})[str(q)] = best
                print('%-6s %-5s media %.2f ms · 1 %% peor %.2f ms · %d enemigos · %.1f M primitivas' % (
                    lid, QUALITY_NAMES[q], best['media'], best['peor'], best['enemigos'], best['primitivas'] / 1e6), flush=True)
            else:
                print('%-6s %-5s sin medición (¿no arrancó?)' % (lid, QUALITY_NAMES[q]), flush=True)
    data = {'fecha': datetime.date.today().strftime('%d-%m-%Y'), 'version': version(), 'veces': veces, 'resultados': res}
    if old.get('resultados'): data['anterior'] = {'fecha': old.get('fecha'), 'version': old.get('version'), 'resultados': old['resultados']}
    json.dump(data, open(DATA, 'w', encoding='utf-8', newline='\n'), ensure_ascii=False, indent='\t')
    write_doc(data, levels(), quals)
    print('hecho en %.0f s; tabla en docs/RENDIMIENTO.md' % (time.time() - t0))


if __name__ == '__main__':
    main()
