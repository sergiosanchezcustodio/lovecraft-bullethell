"""Recorrido de un jugador nuevo (hito 23.4): la parte 1 desde una partida vacía, con el bot.

Cada intento juega el primer nivel de la parte que aún no está superado, en su propio hueco
(user://primera_hora_<k>/slot_1.json), y antes de jugar compra en la tienda como alguien que
empieza (`autobuy=true`, Shop.autobuy: el potenciador más barato que alcance, sin Pacto). El
dinero se queda en el hueco aunque se caiga. Resume, por recorrido, cada intento (nivel, superado
o caída y en qué segundo, dinero antes y después, compras) y al final cuántos intentos y cuánto
tiempo de juego hace falta para superar la parte 1.

Uso: python tools/primera_hora.py [--n 2] [--par 2] [--max 15] [--dif 3] [--skill 0.8] [--ts 2]
     [--parte p1] [--json salida.json]
"""
import json
import os
import re
import shutil
import subprocess
import sys
import threading
import time

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
USER = os.path.join(os.environ.get('APPDATA', ''), 'Godot', 'app_userdata', 'Lovecraft Bullet Hell')
args = sys.argv[1:]
sys.stdout.reconfigure(encoding='utf-8')


def opt(k, d):
    return args[args.index(k) + 1] if k in args else d


N = int(opt('--n', '2')); PAR = min(int(opt('--par', '2')), 2); MAX = int(opt('--max', '15'))
PART = opt('--parte', 'p1')
LEVELS = ['%s_n%d' % (PART, i) for i in range(1, 6)]
LIMIT = 900
lock = threading.Lock()
report = {}


def slot(k):
    return os.path.join(USER, 'primera_hora_%d' % k, 'slot_1.json')


def load(k):
    try:
        return json.load(open(slot(k), encoding='utf-8'))
    except (OSError, ValueError):
        return {}


def journey(k):
    d = os.path.dirname(slot(k))
    shutil.rmtree(d, ignore_errors=True)
    tries = []
    for t in range(MAX):
        s = load(k)
        won = s.get('levels_won', [])
        todo = [lv for lv in LEVELS if lv not in won]
        if not todo: break
        lv = todo[0]
        before = int(s.get('money', 0))
        cmd = ['godot', '--path', '.', '--resolution', '640x360', '--', 'level=' + lv, 'saves=primera_hora_%d' % k,
               'slot=1', 'autobuy=true', 'bot=smart', 'mute=true', 'log=true', 'quit_on_end=true', 'skip_relato=true',
               'timescale=' + opt('--ts', '2'), 'skill=' + opt('--skill', '0.8'), 'cfg_difficulty=' + opt('--dif', '3'),
               'weather=no', 'seed=%d' % (2000 + k * 100 + t)]
        p = subprocess.Popen(' '.join(cmd), shell=True, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                             text=True, encoding='utf-8', errors='replace')
        try:
            out, _ = p.communicate(timeout=LIMIT)
        except subprocess.TimeoutExpired:
            subprocess.run('taskkill /T /F /PID %d' % p.pid, shell=True, capture_output=True)
            out, _ = p.communicate()
        buys = re.findall(r'^COMPRA (\S+) nv=(\d+)', out, re.M)
        res, secs, nv = 'cortada', 0, 0
        m = re.search(r'NIVEL SUPERADO (\S+) t=(\d+).*nivel_j1=(\d+)', out)
        if m: res, secs, nv = 'SUPERADO', int(m.group(2)), int(m.group(3))
        m = re.search(r'FIN DERROTA (\S+) t=(\d+) abatidos=(\d+) nivel_j1=(\d+)', out)
        if m and res != 'SUPERADO': res, secs, nv = 'caída', int(m.group(2)), int(m.group(4))
        after = int(load(k).get('money', 0))
        row = {'level': lv, 'result': res, 't': secs, 'nv': nv, 'money_before': before, 'money_after': after,
               'buys': ['%s %s' % b for b in buys]}
        tries.append(row)
        with lock:
            print('recorrido %d, intento %d: %s %s t=%d nv=%d  $%d -> $%d  compras: %s' % (
                k, t + 1, lv, res, secs, nv, before, after, ', '.join(row['buys']) or '-'), flush=True)
    with lock:
        report[k] = tries


threads = []
for k in range(N):
    while sum(th.is_alive() for th in threads) >= PAR: time.sleep(2)
    th = threading.Thread(target=journey, args=(k,)); th.start(); threads.append(th)
    time.sleep(3)
for th in threads: th.join()

print('\nrecorrido  intentos  caídas  tiempo de juego  superada')
for k in sorted(report):
    tr = report[k]
    done = sum(1 for r in tr if r['result'] == 'SUPERADO')
    print('%9d  %8d  %6d  %12.1f min  %s' % (k, len(tr), sum(1 for r in tr if r['result'] == 'caída'),
          sum(r['t'] for r in tr) / 60.0, 'sí' if done == len(LEVELS) else 'no (%d de %d)' % (done, len(LEVELS))))
if '--json' in args:
    json.dump(report, open(opt('--json', 'primera_hora.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
