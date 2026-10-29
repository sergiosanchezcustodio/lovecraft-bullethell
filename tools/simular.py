"""Simula partidas completas con el bot que juega como una persona (SmartBot) y resume el
resultado (15-10-2026). Lanza varias partidas a la vez, cada una en su ventana pequeña.

  python tools/simular.py p1 --n 6                 # parte 1 encadenada, en solitario, 6 partidas
  python tools/simular.py p2 --n 6 --bots 3        # cooperativo de 4 (J1 y 3 compañeros bot)
  python tools/simular.py p1_n3 --n 4              # un nivel suelto
  opciones: --par N (a la vez, 3), --ts N (timescale, 2: a 4 el bot reacciona tarde y cae el doble de pronto), --skill 0.8, --shop N, --dif N (1..10, 3 por defecto),
            --char dyer, --extra "clave=valor ..."

Imprime cada final ("SUPERADO p1_n2 t=…" / "DERROTA p1_n3 t=…") y un resumen por nivel:
intentos, superados y en qué segundo se cae. En cooperativo, también cada jugador por nivel
(20-10-2026): nivel medio, vida más baja media y caídas (línea "JUGADORES" de la partida).
Con `--json salida.json` guarda los datos.
"""
import subprocess, sys, re, json, time, threading, os, collections

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
args = sys.argv[1:]
def opt(k, d):
    return args[args.index(k) + 1] if k in args else d
target = args[0]
N = int(opt('--n', '4')); PAR = int(opt('--par', '3')); TS = opt('--ts', '2')
chain = re.fullmatch(r'p\d', target) is not None
level = target + '_n1' if chain else target
cmd = ['godot', '--path', '.', '--resolution', '640x360', '--',
       'level=' + level, 'bot=smart', 'mute=true', 'log=true', 'quit_on_end=true', 'timescale=' + TS,
       'skill=' + opt('--skill', '0.8'), 'cfg_difficulty=' + opt('--dif', '3'), 'weather=no']
if chain: cmd += ['autonext=true']
if '--bots' in args: cmd += ['bots=' + opt('--bots', '3')]
if '--shop' in args: cmd += ['shop=' + opt('--shop', '0')]
if '--char' in args: cmd += ['character=' + opt('--char', 'dyer')]
cmd += opt('--extra', '').split()

results = []
players = collections.defaultdict(list)   # (nivel, 'J2') -> [(nv, vida_min, caídas)]
lock = threading.Lock()

def run(k):
    t0 = time.time()
    p = subprocess.run(' '.join(cmd + ['seed=%d' % (1000 + k)]), shell=True, cwd=ROOT, capture_output=True,
                       text=True, encoding='utf-8', errors='replace', timeout=3600)
    ev = []
    for line in p.stdout.splitlines():
        m = re.match(r'NIVEL SUPERADO (\S+) t=(\d+).*nivel_j1=(\d+)(?:  vida_min=(\d+))?', line)
        if m: ev.append(('SUPERADO', m.group(1), int(m.group(2)), int(m.group(3)), int(m.group(4) or -1)))
        m = re.match(r'FIN DERROTA (\S+) t=(\d+) abatidos=(\d+) nivel_j1=(\d+)', line)
        if m: ev.append(('DERROTA', m.group(1), int(m.group(2)), int(m.group(4))))
        m = re.match(r'JUGADORES (\S+)  (.*)', line)
        if m:
            with lock:
                for part in m.group(2).split(' | '):
                    pm = re.match(r'(J\d) nv=(\d+) vida_min=(-?\d+) caidas=(\d+)', part)
                    if pm: players[(m.group(1), pm.group(1))].append((int(pm.group(2)), int(pm.group(3)), int(pm.group(4))))
        m = re.match(r'RECIBIDO J1 (.*)', line)
        if m: print('   recibido:', m.group(1), flush=True)
        m = re.match(r'ESTADISTICAS J1 (.*)', line)
        if m and ev: ev[-1] = ev[-1] + (m.group(1),)
    with lock:
        results.append(ev)
        print('partida %d (%.0f s): %s' % (k, time.time() - t0,
              '  '.join(('%s %s t=%d nv=%d' % e[:4]) + (' vida_min=%d%%' % e[4] if e[0] == 'SUPERADO' else '') for e in ev) or 'sin datos'), flush=True)

threads = []
for k in range(N):
    while sum(t.is_alive() for t in threads) >= PAR: time.sleep(1)
    th = threading.Thread(target=run, args=(k,)); th.start(); threads.append(th)
    time.sleep(2)
for th in threads: th.join()

tries = collections.Counter(); wins = collections.Counter(); falls = collections.defaultdict(list)
for ev in results:
    for e in ev:
        tries[e[1]] += 1
        if e[0] == 'SUPERADO': wins[e[1]] += 1
        else: falls[e[1]].append(e[2])
print('\nnivel     superados  caídas (s)')
for lv in sorted(tries):
    print('%-9s %2d / %-4d %s' % (lv, wins[lv], tries[lv], ' '.join(str(x) for x in sorted(falls[lv]))))
if len({j for _, j in players}) > 1:
    print('\nnivel     jugador  nivel medio  vida mín. media  caídas  (n)')
    for lv, j in sorted(players):
        rows = players[(lv, j)]
        print('%-9s %-8s %11.1f  %14.0f %%  %6d  (%d)' % (lv, j, sum(r[0] for r in rows) / len(rows),
              sum(r[1] for r in rows) / len(rows), sum(r[2] for r in rows), len(rows)))
    print('\njugador  vida mín. media  caídas (todos los niveles)')
    for j in sorted({j for _, j in players}):
        rows = [r for (lv, jj), rr in players.items() if jj == j for r in rr]
        print('%-8s %14.0f %%  %6d' % (j, sum(r[1] for r in rows) / len(rows), sum(r[2] for r in rows)))
if '--json' in args:
    json.dump({'results': results, 'players': {'%s %s' % k: v for k, v in players.items()}},
              open(opt('--json', 'sim.json'), 'w'), ensure_ascii=False, indent=1)
