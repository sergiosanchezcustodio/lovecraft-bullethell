# Caza de errores en partida (06-11-2026): juega con el bot cada nivel de la campaña y una muestra
# de los modos (noche eterna, desfile de jefes, desafíos, cooperativo), con el final adelantado para
# que salgan los jefes, y junta los errores y avisos de la consola sin repetir, con dónde salieron.
# Uso, desde la raíz:  python tools/caza_errores.py [tag,tag,...] [--par 2] [--t 110]
#   -> shots/caza_errores/<tag>.png (captura al final) e informe.txt. Unos 20 minutos entero.
import subprocess, sys, os, re, glob, shutil, time, threading, collections
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace(os.sep, '/')
OUT = ROOT + '/shots/caza_errores'
os.makedirs(OUT, exist_ok=True)
args = sys.argv[1:]
def opt(k, d):
    if k in args:
        i = args.index(k); v = args[i + 1]; del args[i:i + 2]; return v
    return d
PAR = int(opt('--par', '2'))
T = float(opt('--t', '110'))
LEVELS = ['p%d_n%d' % (p, n) for p in (1, 2, 3) for n in range(1, 6)]
RUNS = [(l, 'level=%s final_at=50' % l) for l in LEVELS] + [
    ('noche_p1', 'level=sin_fin:p1_n1'), ('noche_p2', 'level=sin_fin:p2_n2'), ('noche_p3', 'level=sin_fin:p3_n4'),
    ('desfile_1', 'level=desfile:1 final_at=5'), ('desfile_4', 'level=desfile:4 final_at=5'), ('desfile_7', 'level=desfile:7 final_at=5'),
    ('desafio_p1', 'level=desafio:p1_n1 final_at=50'), ('desafio_p2', 'level=desafio:p2_n3 final_at=50'),
    ('desafio_p3', 'level=desafio:p3_n5 final_at=50'),
    ('coop_p1', 'level=p1_n4 bots=3 final_at=50'), ('coop_p3', 'level=p3_n3 bots=3 final_at=50'),
]
filt = args[0].split(',') if args else []
BASE = 'bot=smart god=true mute=true log=true timescale=2 cfg_difficulty=3 skill=0.8'
NOISE = re.compile(r'^\s*(at:|GDScript backtrace|\[\d+\])')
found = collections.OrderedDict()      # mensaje -> {tags}
lock = threading.Lock()


def run(tag, a, k):
    for f in glob.glob('%s/shots/*caza_%s_*' % (ROOT, tag)): os.remove(f)
    cmd = 'godot --path . -- %s %s seed=%d shots=%g tag=caza_%s' % (a, BASE, 2000 + k, T, tag)
    t0 = time.time()
    try:
        r = subprocess.run(['bash', '-lc', 'cd %s && timeout %d %s' % (ROOT, int(T / 2 + 150), cmd)],
                           capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=T / 2 + 200)
        out = (r.stdout + r.stderr).splitlines()
    except subprocess.TimeoutExpired:
        out = ['ERROR: TIEMPO AGOTADO']
    msgs = []
    for i, l in enumerate(out):
        if not re.match(r'^\s*(SCRIPT ERROR|ERROR|WARNING|USER ERROR|USER WARNING)\b', l): continue
        where = ''
        for nxt in out[i + 1:i + 3]:
            m = re.search(r'at: .*?\((res://[^)]+)\)', nxt) or re.search(r'at: (\S+ \([^)]*\))', nxt)
            if m: where = m.group(1); break
        msgs.append(re.sub(r'\s+', ' ', l.strip()) + ('  [' + where + ']' if where else ''))
    shots = sorted(f for f in glob.glob('%s/shots/*caza_%s_*.png' % (ROOT, tag)) if os.path.getmtime(f) >= t0)
    if shots: shutil.copy(shots[-1], '%s/%s.png' % (OUT, tag))
    with lock:
        for m in msgs: found.setdefault(m, set()).add(tag)
        print('%-12s %3d s  %d avisos%s' % (tag, time.time() - t0, len(msgs), '' if shots else '  (sin captura)'), flush=True)


todo = [(t, a) for t, a in RUNS if not filt or t in filt]
threads, k = [], 0
while todo or threads:
    threads = [th for th in threads if th.is_alive()]
    while todo and len(threads) < PAR:
        t, a = todo.pop(0); k += 1
        th = threading.Thread(target=run, args=(t, a, k)); th.start(); threads.append(th)
        time.sleep(3)                       # que no arranquen a la vez (memoria al cargar)
    time.sleep(1)
with open(OUT + '/informe.txt', 'w', encoding='utf-8') as rep:
    rep.write('Caza de errores: %d mensajes distintos\n\n' % len(found))
    for m, tags in found.items():
        rep.write('%s\n    en: %s\n' % (m, ', '.join(sorted(tags))))
print('%d mensajes distintos -> %s/informe.txt' % (len(found), OUT))
