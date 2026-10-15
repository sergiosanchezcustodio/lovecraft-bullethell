"""Banco de armas (15-10-2026): cada arma sola, a nivel 5, contra la misma horda durante N s de
juego, con el bot que juega (SmartBot) invulnerable y sin subidas de nivel. Mide lo que rinde de
verdad en partida (daño y abatidos), no la cuenta teórica de DamageRules.

  python tools/banco_armas.py [armas...] [--t 45] [--par 3] [--nivel p1_n3] [--wlevel 5]
Salida: tabla ordenada por daño y tools/banco_armas.json.
"""
import subprocess, sys, os, re, json, threading, time, glob
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
args = sys.argv[1:]
def opt(k, d): return args[args.index(k) + 1] if k in args else d
names = [a for a in args if not a.startswith('--') and (args.index(a) == 0 or not args[args.index(a) - 1].startswith('--'))]
if not names:
    names = []
    for f in sorted(glob.glob(os.path.join(ROOT, 'data', 'weapons', '*.tres'))):
        t = open(f, encoding='utf-8').read()
        if re.search(r'^evolved = true', t, re.M): continue
        names.append(os.path.splitext(os.path.basename(f))[0])
T = opt('--t', '45'); PAR = int(opt('--par', '3'))
res = {}
lock = threading.Lock()
def run(w):
    cmd = ('godot --path . --resolution 640x360 -- level=%s fresh=true bot=smart god=true mute=true weather=no '
           'weapons=%s wlevel=%s nolevelup=true sim_time=%s timescale=4 final_at=99999 max_alive=70 spawn_rate=14 '
           'cfg_difficulty=1 neutral=true character=%s') % (opt('--nivel', 'p1_n3'), w, opt('--wlevel', '5'), T, opt('--char', 'olmstead'))
    p = subprocess.run(cmd, shell=True, cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=900)
    m = re.search(r'BANCO abatidos=(\d+) (\{.*\})', p.stdout)
    out = None
    if m:
        st = json.loads(m.group(2))
        d = st.get('weapons', {}).get(w, [0, 0])
        out = {'dano': round(d[0]), 'abatidos': d[1], 'total_abatidos': int(m.group(1))}
    with lock:
        res[w] = out
        print('%-28s %s' % (w, out), flush=True)
ths = []
for w in names:
    while sum(t.is_alive() for t in ths) >= PAR: time.sleep(0.5)
    th = threading.Thread(target=run, args=(w,)); th.start(); ths.append(th); time.sleep(1.5)
for th in ths: th.join()
ok = {k: v for k, v in res.items() if v}
print('\narma                          daño  abatidos')
for k, v in sorted(ok.items(), key=lambda kv: -kv[1]['dano']):
    print('%-28s %6d  %4d' % (k, v['dano'], v['abatidos']))
json.dump(res, open(os.path.join(ROOT, 'tools', 'banco_armas.json'), 'w'), indent=1)

# --ajustar: actualiza data/weapons/banco.json para acercar cada arma a la mediana (con
# compresión: exponente 0,7) y después hay que aplicar las reglas:
#   godot --headless --path . -s tools/reglas_dano.gd -- aplicar
#   godot --headless --path . -s tools/gen_evoluciones.gd
if '--ajustar' in args:
    SUPPORT = set()
    for f in glob.glob(os.path.join(ROOT, 'data', 'weapons', '*.tres')):
        if re.search(r'^support = true', open(f, encoding='utf-8').read(), re.M):
            SUPPORT.add(os.path.splitext(os.path.basename(f))[0])
    vals = sorted(v['dano'] for k, v in ok.items() if k not in SUPPORT)
    med = vals[len(vals) // 2]
    path = os.path.join(ROOT, 'data', 'weapons', 'banco.json')
    bench = json.load(open(path)) if os.path.exists(path) else {}
    for k, v in ok.items():
        if k in SUPPORT or v['dano'] <= 0: continue
        f = bench.get(k, 1.0) * (med / v['dano']) ** float(opt('--exp', '0.7'))
        bench[k] = round(min(4.0, max(0.4, f)), 3)
    json.dump(dict(sorted(bench.items())), open(path, 'w'), indent=1)
    print('mediana %d; factores en data/weapons/banco.json' % med)
