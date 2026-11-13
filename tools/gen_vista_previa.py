"""Vista previa de la pestaña Vídeo (hito 20.12): la misma escena de partida (el muelle de la
plaza de Innsmouth, p2_n2, con cuatro investigadores y la misma semilla; `bot=idle`: el J1 no se
mueve y los otros lo siguen, para que el encuadre sea siempre el mismo) capturada con cada calidad
gráfica y cada nivel de efectos de las armas que de verdad se distinguen (la calidad pone tope a
los efectos: Baja, solo mínimos; Media, hasta rebajados). Escribe resources/vista_previa/
vp_q<calidad>_w<efectos>.jpg a 480×270, y para la fila del clima (pestaña Juego) vp_clima0 y
vp_clima1 (apagado y reducido, con la calidad Alta y los efectos enteros; el completo es vp_q2_w2).
El brillo no hace falta: lo aplica el menú encima (VideoPreview).

Uso (desde la raíz, en Git Bash, con el comando `godot`):
    python tools/gen_vista_previa.py [--t 20] [--solo q,w]
Tarda ~1 min por captura (11 en total). `--solo clima0` para una del clima.
"""
import os, subprocess, sys, glob
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
OUT = os.path.join(ROOT, 'resources', 'vista_previa')
SIZE = (480, 270)                    # lo que mide en el menú (VideoPreview.SIZE): sin reescalar, sin muaré
COMBOS = [(0, 0), (1, 0), (1, 1), (2, 0), (2, 1), (2, 2), (3, 0), (3, 1), (3, 2)]


def capture(q, w, t, weather=2):
    name = 'vp_q%d_w%d' % (q, w) if weather == 2 else 'vp_clima%d' % weather
    tag = '_' + name
    for f in glob.glob(os.path.join(ROOT, 'shots', 'game_%s_*.png' % tag)):
        os.remove(f)
    # con el `godot` de Git Bash (escritorio aparte, sin robar el foco); autopick: sin la ventana de subida
    cmd = ('godot --path . -- level=p2_n2 seed=500 bot=idle god=true bots=3 autopick=true mute=true hud=false '
           'card=false cfg_quality=%d cfg_weapon_fx=%d cfg_weather=%d cfg_brightness=3 shots=%g tag=%s') % (q, w, weather, t, tag)
    subprocess.run(['bash', '-lc', cmd], cwd=ROOT, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=600)
    shots = glob.glob(os.path.join(ROOT, 'shots', 'game_%s_*.png' % tag))
    if not shots:
        print('  sin captura', name)
        return False
    im = Image.open(shots[0]).convert('RGB').resize(SIZE, Image.LANCZOS)
    im.save(os.path.join(OUT, name + '.jpg'), quality=88)
    print('  %s.jpg' % name)
    return True


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    t = 20.0
    combos = [(q, w, 2) for q, w in COMBOS] + [(2, 2, 0), (2, 2, 1)]
    if '--t' in sys.argv:
        t = float(sys.argv[sys.argv.index('--t') + 1])
    if '--solo' in sys.argv:
        a = sys.argv[sys.argv.index('--solo') + 1]
        if a.startswith('clima'):
            combos = [(2, 2, int(a[5:]))]
        else:
            q, w = a.split(',')
            combos = [(int(q), int(w), 2)]
    ok = all([capture(q, w, t, c) for q, w, c in combos])
    print('listo' if ok else 'faltan capturas', OUT)
