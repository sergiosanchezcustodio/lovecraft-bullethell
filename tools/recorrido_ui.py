# Recorrido de las ventanas con ui_check=true (05-11-2026): una ejecución por ventana (portada,
# selección, partida, expedición y pesca), con su captura y los avisos «UICHK» de cada una.
# Uso, desde la raíz:  python tools/recorrido_ui.py [tag,tag,...]
#   -> shots/ui_recorrido/<tag>.png e informe.txt (los avisos, por ventana). Unos 25 minutos entero.
# Necesita la partida de prueba demo_saves (godot --path . -- test_save=N saves=demo_saves).
import subprocess, sys, os, glob, shutil, time
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))).replace(os.sep, '/')
OUT = ROOT + '/shots/ui_recorrido'
os.makedirs(OUT, exist_ok=True)
T = 'title saves=demo_saves t=20 shots=23'
G = 'level=p2_n2 character=olmstead god=true spawn_rate=2'
RUNS = [
    ('huecos', T + ' open=slots'),
    ('huecos_borrar', T + ' open=slots_borrar'),
    ('menu', T + ' open=menu'),
    ('jugar', T + ' open=menu_jugar'),
    ('online', T + ' open=menu_online net_upnp=false'),
    ('logros', T + ' open=menu_logros'),
    ('libro', T + ' open=menu_libro shots=26'),
    ('revision', T + ' open=menu_revision tab=0'),
] + [('config_%d' % i, T + ' open=menu_config tab=%d' % i) for i in range(5)] \
  + [('nube_' + d, T + ' open=menu_config tab=4 cloud_demo=' + d) for d in ['conectado', 'codigo', 'conflicto', 'bajadas']] \
  + [('tienda_%d' % i, T + ' open=menu_tienda tab=%d' % i) for i in range(5)] \
  + [('biblioteca_%d' % i, T + ' open=menu_biblioteca tome=%d' % i) for i in range(11)] + [
    ('seleccion', 'select saves=demo_saves slot=2 join=2 shots=3'),
    ('seleccion_mapa', 'select saves=demo_saves slot=2 map=true shots=3'),
    ('seleccion_desafios', 'select saves=demo_saves slot=2 map=true challenge_open=true shots=3.5'),
    ('seleccion_locura', 'select saves=demo_saves slot=2 map=true madness_open=true shots=3.5'),
    ('pausa', G + ' pause_at=2.5,30 shots=4'),
    ('pausa_rotulo', G + ' card=true pause_at=1.6,30 shots=2.6'),
    ('depuracion', G + ' debug_menu=2.5 shots=4'),
    ('dificultad', G + ' dif_menu=true debug_menu=2.5 shots=4'),
    ('dano', 'level=p2_n2 character=olmstead god=true spawn_rate=10 bot=circle dmg_table=9 shots=10.5'),   # con daño hecho
    ('ficha', G + ' sheet_at=2.5 shots=4'),
    ('mapa', G + ' map_at=2.5 shots=4'),
    ('subida', G + ' bot=circle xp=400 shots=4,6'),
    ('evolucion', G + ' evolve_at=2.5 weapons=thompson wlevel=5 items=oro_obed shots=4'),
    ('final', G + ' down_at=2.5 halt_shots=true quit_on_end=true'),
    ('repeticion', G + ' down_at=2.5 halt_shots=true quit_on_end=true replay_open=true'),
    ('expedicion', 'scenes/expedition_map.tscn -- exp_part=0 exp_seed=7 shots=3'),
    ('pesca', 'scenes/fishing.tscn -- pj=dyer fish_auto=true fish_force=arenque card_shot=true tag=uichk'),
]
filt = sys.argv[1].split(',') if len(sys.argv) > 1 else []
report = open(OUT + '/informe.txt', 'w' if not filt else 'a', encoding='utf-8')
for tag, a in RUNS:
    if filt and tag not in filt: continue
    if a.startswith('scenes/'):
        scene, rest = a.split(' -- ', 1)
        cmd = 'godot --path . %s -- %s ui_check=true mute=true' % (scene, rest)
    else:
        cmd = 'godot --path . -- %s tag=uichk ui_check=true mute=true' % a
    t0 = time.time()
    for f in glob.glob(ROOT + '/shots/*uichk*'): os.remove(f)
    try:
        r = subprocess.run(['bash', '-lc', 'cd %s && timeout 90 %s' % (ROOT, cmd)], capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=120)
        out = r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        out = 'TIEMPO AGOTADO'
    lines = [l for l in out.splitlines() if 'UICHK' in l or 'SCRIPT ERROR' in l]
    shots = sorted(f for f in glob.glob(ROOT + '/shots/*.png') if os.path.getmtime(f) >= t0)
    for k, f in enumerate(shots):
        shutil.copy(f, '%s/%s%s.png' % (OUT, tag, '' if k == 0 else '_%d' % k))
    report.write('== %s (%d s, %d capturas)\n' % (tag, time.time() - t0, len(shots)))
    for l in lines: report.write('   ' + l.strip() + '\n')
    report.flush()
    print(tag, len(lines), len(shots), flush=True)
