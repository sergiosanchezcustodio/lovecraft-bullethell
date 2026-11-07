"""Compara configuraciones de la partida: varias ejecuciones por nivel, media de las medidas.
Uso: python tools/comparar.py "<extra A>" "<extra B>" --niveles p1_n2,p3_n2 --veces 3 [--perf 20] [--calidad 2] [--dir otra_copia]
Cuenta también las compilaciones de shaders a mitad de partida («a_mitad», tras los 10 primeros s medidos: las que se notan).
(se alternan las configuraciones para que el ruido del PC les toque a todas; --dir mide otra copia del proyecto, p. ej. un git worktree de un commit anterior)"""
import re, subprocess, sys, statistics as st
args = sys.argv[1:]
def opt(k, d):
    return args[args.index(k) + 1] if k in args else d
confs = [a for a in args if not a.startswith('--') and args[args.index(a) - 1] not in ('--niveles', '--veces', '--perf', '--calidad', '--dir')]
lv = opt('--niveles', 'p1_n2').split(','); n = int(opt('--veces', '3')); perf = opt('--perf', '20'); q = opt('--calidad', '2'); wd = opt('--dir', 'C:/ClaudeProjects/lovecraft-bullethell')
R = re.compile(r'RENDIMIENTO fotogramas=(\d+) media=([\d.]+) ms .*?1% peor=([\d.]+) ms')
P = re.compile(r'PICOS (\d+) de (\d+) fotogramas.*?total: (\d+)')
H = re.compile(r'tirones \(m.s de 25 ms\): (\d+)  peor: ([\d.]+)')
C = re.compile(r'compilaciones a mitad de partida: (\d+) en (\d+) fotogramas  peor: ([\d.]+)')   # (07-11-2026)
res = {}
for k in range(n):                       # alternando configuraciones: el ruido del PC les toca a todas
    for L in lv:
        for c in confs:
            cmd = 'godot --path . --disable-vsync --audio-driver Dummy -- level=%s bot=smart god=true mute=true autopick=true cfg_quality=%s max_alive=80 spawn_rate=20 perf=%s spikes=true seed=%d %s' % (L, q, perf, 500 + k, c)
            out = subprocess.run(['bash', '-lc', cmd], cwd=wd, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=400).stdout
            m = R.search(out); p = P.search(out); h = H.search(out); cm = C.search(out)
            if not m: print('sin medida', L, c, flush=True); continue
            spk = int(p.group(1)) * 1000.0 / int(p.group(2)) if p else 0.0
            res.setdefault((L, c), []).append((float(m.group(2)), float(m.group(3)), spk, int(p.group(3)) if p else 0, int(h.group(1)) if h else -1, float(h.group(2)) if h else -1,
                int(cm.group(1)) if cm else -1, float(cm.group(3)) if cm else -1))
            print(L, repr(c), 'media=%s peor=%s picos/1000=%.1f shaders=%s a_mitad=%s' % (m.group(2), m.group(3), spk, p.group(3) if p else '?', cm.group(1) if cm else '?'), flush=True)
print()
for L in lv:
    for c in confs:
        r = res.get((L, c), [])
        if not r: continue
        print('%-6s %-52s media=%.2f  1%%peor=%.2f (%.2f-%.2f)  picos/1000=%.1f  tirones>25=%.1f  peor=%.0f  shaders=%.0f  a_mitad=%.1f (peor %.0f ms)  [%d]' % (L, repr(c), st.mean(x[0] for x in r), st.mean(x[1] for x in r),
              min(x[1] for x in r), max(x[1] for x in r), st.mean(x[2] for x in r), st.mean(x[4] for x in r), max(x[5] for x in r), st.mean(x[3] for x in r),
              st.mean(x[6] for x in r), max(x[7] for x in r), len(r)))
