"""Banco de objetos (15-10-2026): cada objeto a nivel 5 con las mismas armas (Webly y
Stielhandgranate a nivel 3), contra la misma horda durante N s, con el bot que juega (SmartBot)
inmortal (recibe el daño, pero no cae) y sin subidas de nivel. Compara con la partida sin objeto
(media de varias): daño hecho y abatidos (ataque), vida y cordura recibidas y crisis (defensa).

  python tools/banco_objetos.py [objetos...] [--t 60] [--par 3] [--base 4]
Salida: tabla con el cambio frente a la base y tools/banco_objetos.json.
"""
import subprocess, sys, os, re, json, threading, time, glob
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
args = sys.argv[1:]
def opt(k, d): return args[args.index(k) + 1] if k in args else d
names = [a for i, a in enumerate(args) if not a.startswith('--') and (i == 0 or not args[i - 1].startswith('--'))]
if not names: names = [os.path.splitext(os.path.basename(f))[0] for f in sorted(glob.glob(os.path.join(ROOT, 'data', 'upgrades', '*.tres')))]
T = opt('--t', '60'); PAR = int(opt('--par', '3')); NB = int(opt('--base', '4'))
res = {}
lock = threading.Lock()
def run(key, item):
    cmd = ('godot --path . --resolution 640x360 -- level=' + opt('--nivel', 'p1_n2') + ' fresh=true bot=smart immortal=true mute=true weather=no '
           'weapons=webly,granada wlevel=' + opt('--wlevel', '3') + ' nolevelup=true sim_time=%s timescale=4 final_at=99999 max_alive=70 spawn_rate=14 '
           'cfg_difficulty=1 neutral=true character=olmstead %s') % (T, ('items=%s ilevel=5' % item) if item else '')
    p = subprocess.run(cmd, shell=True, cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=900)
    m = re.search(r'BANCO abatidos=(\d+) .*"total": \[([\d.e+]+), \d+\].*RECIBIDO (\d+) (\d+) crisis=(\d+)', p.stdout)
    out = None
    if m: out = {'abatidos': int(m.group(1)), 'dano': float(m.group(2)), 'vida': int(m.group(3)), 'cordura': int(m.group(4)), 'crisis': int(m.group(5))}
    with lock:
        res[key] = out
        print('%-18s %s' % (key, out), flush=True)
jobs = [('_base%d' % i, '') for i in range(NB)] + [(n, n) for n in names]
ths = []
for key, item in jobs:
    while sum(t.is_alive() for t in ths) >= PAR: time.sleep(0.5)
    th = threading.Thread(target=run, args=(key, item)); th.start(); ths.append(th); time.sleep(1.5)
for th in ths: th.join()
bases = [v for k, v in res.items() if k.startswith('_base') and v]
base = {k: sum(b[k] for b in bases) / len(bases) for k in bases[0]}
print('\nbase: %s' % {k: round(v) for k, v in base.items()})
print('objeto             daño   abatidos  vida   cordura  crisis')
rows = []
for k, v in res.items():
    if k.startswith('_base') or not v: continue
    pct = lambda f: (v[f] / base[f] - 1) * 100 if base[f] else 0
    rows.append((k, pct('dano'), pct('abatidos'), pct('vida'), pct('cordura'), v['crisis']))
for r in sorted(rows, key=lambda r: -r[1]):
    print('%-18s %+5.0f%%  %+5.0f%%   %+5.0f%%  %+5.0f%%   %d' % r)
json.dump({'base': base, 'objetos': res}, open(os.path.join(ROOT, 'tools', 'banco_objetos.json'), 'w'), indent=1)
