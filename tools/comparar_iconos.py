"""Hoja para comparar el icono actual de un arma con las variantes locales de tools/local/.

  python tools/comparar_iconos.py bengalas bisturis flammenwerfer   -> shots/cmp_iconos_local.png
Cada fila: el icono actual del juego y después cada <arma>_<semilla>_icono.png, con su semilla.
Para quedarse con una: python tools/generar_local.py arma <id> --semilla <N> --usar
"""
import glob, os, re, sys
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CELL, PAD, LABEL = 256, 16, 34

def font(n):
    try: return ImageFont.truetype('arial.ttf', n)
    except OSError: return ImageFont.load_default()

def main():
    ids = sys.argv[1:] or sys.exit(__doc__)
    rows = []
    for w in ids:
        cur = os.path.join(ROOT, 'resources', 'weapons', 'icons', w + '.png')
        new = sorted(glob.glob(os.path.join(ROOT, 'tools', 'local', w + '_*_icono.png')))
        rows.append([(cur, 'actual (Replicate)')] + [(p, 'local · semilla ' + re.search(r'_(\d+)_icono', p).group(1)) for p in new])
    cols = max(len(r) for r in rows)
    W = 180 + cols * (CELL + PAD) + PAD
    H = rows and len(rows) * (CELL + LABEL + PAD) + PAD
    sheet = Image.new('RGB', (W, H), (34, 30, 38))
    d = ImageDraw.Draw(sheet)
    for j, (w, r) in enumerate(zip(ids, rows)):
        y = PAD + j * (CELL + LABEL + PAD)
        d.text((PAD, y + CELL // 2), w, fill=(230, 220, 200), font=font(22))
        for i, (p, txt) in enumerate(r):
            x = 180 + PAD + i * (CELL + PAD)
            bg = (70, 52, 40) if i == 0 else (52, 50, 60)       # el actual, con fondo distinto
            d.rectangle([x, y, x + CELL, y + CELL], fill=bg)
            if os.path.exists(p):
                im = Image.open(p).convert('RGBA').resize((CELL, CELL), Image.LANCZOS)
                sheet.paste(im, (x, y), im)
            else:
                d.text((x + 80, y + 120), 'sin icono', fill=(200, 120, 120), font=font(18))
            d.text((x + 4, y + CELL + 6), txt, fill=(200, 200, 210), font=font(17))
    out = os.path.join(ROOT, 'shots', 'cmp_iconos_local.png')
    sheet.save(out)
    print(out)

if __name__ == '__main__': main()
