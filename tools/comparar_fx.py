"""Hoja de antes y después de los efectos (fx_demo de la partida).

Captura cada versión con
  godot --path . -- nolevel=true fx_demo=<explosion|fire|acid> god=true mute=true cam=8 shots=2.03,2.08,2.15,2.3,2.6,3.5 tag=fx_<antes|despues>_<efecto>
y después: python tools/comparar_fx.py [efectos…] [--salida nombre]  -> shots/cmp_fx.png
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CW, CH = 480, 340

def shot(tag, k, i):
    import glob
    files = sorted(glob.glob(os.path.join(ROOT, 'shots', 'game_fx_%s_%s_*.png' % (tag, k))))
    return files[i] if i < len(files) else None

def main():
    f = ImageFont.truetype('arial.ttf', 26)
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    name = sys.argv[sys.argv.index('--salida') + 1] if '--salida' in sys.argv else 'cmp_fx'
    if '--salida' in sys.argv: args.remove(name)
    rows = [(k, t) for k in (args or ['explosion', 'fire', 'acid']) for t in ['antes', 'despues']]
    n = 6
    S = Image.new('RGB', (190 + n * CW, len(rows) * (CH + 8)), (25, 22, 28))
    d = ImageDraw.Draw(S)
    for j, (k, tag) in enumerate(rows):
        y = j * (CH + 8)
        d.text((10, y + CH // 2 - 30), k, fill=(235, 225, 200), font=f)
        d.text((10, y + CH // 2 + 4), tag, fill=(255, 170, 90) if tag == 'despues' else (170, 170, 180), font=f)
        for i in range(n):
            p = shot(tag, k, i)
            if not p: continue
            im = Image.open(p); W, H = im.size
            cx, cy = int(W * 0.6), int(H * 0.52)          # el efecto sale a la derecha del jugador
            box = (cx - int(W * 0.17), cy - int(H * 0.21), cx + int(W * 0.17), cy + int(H * 0.21))
            S.paste(im.crop(box).resize((CW, CH)), (190 + i * CW, y))
    out = os.path.join(ROOT, 'shots', name + '.png')
    S.save(out); print(out)

if __name__ == '__main__': main()
