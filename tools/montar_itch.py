"""Monta el material de la página de itch.io (hito 22.8) a partir de tools/capturas_itch.sh.

  python tools/montar_itch.py --hoja [es|en]   # hoja con todas las candidatas, para elegir
  python tools/montar_itch.py                  # copia las elegidas (ELEGIDAS) a docs/itchio/capturas
                                               # y capturas_en, la portada y el GIF del tráiler

Las candidatas están en shots/game_itch_<idioma>_<n>_<segundo>s.png; la portada, en
shots/titulo_itch_portada_<segundo>s.png.
"""
import glob
import os
import shutil
import sys

from PIL import Image, ImageDraw

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..'))
SHOTS = os.path.join(ROOT, 'shots')
DEST = os.path.join(ROOT, 'docs', 'itchio')

# Las cinco elegidas por idioma: (partida de capturas_itch.sh, segundo de la captura). Los bots no
# juegan igual cada vez, así que en inglés no siempre vale el mismo segundo que en español.
ELEGIDAS = {'es': [('1', '080.0'), ('2', '060.0'), ('3', '010.0'), ('4', '010.0'), ('5', '024.0')],
            'en': [('1', '080.0'), ('2', '060.0'), ('3', '010.0'), ('4', '010.0'), ('5', '040.0')]}
# Portada: (segundo de la captura, recorte 630:500 como (izquierda, arriba, ancho) en 1920x1080)
PORTADA = ('008.0', (280, 0, 1361))


def shot(lang, n, t):
    return os.path.join(SHOTS, 'game_itch_%s_%s_%ss.png' % (lang, n, t))


def sheet(lang):
    files = sorted(glob.glob(os.path.join(SHOTS, 'game_itch_%s_*.png' % lang)))
    files += sorted(glob.glob(os.path.join(SHOTS, 'titulo_itch_portada_*.png')))
    w, h, cols = 480, 270, 5
    rows = (len(files) + cols - 1) // cols
    out = Image.new('RGB', (w * cols, h * rows), 'black')
    d = ImageDraw.Draw(out)
    for i, f in enumerate(files):
        im = Image.open(f).convert('RGB').resize((w, h), Image.LANCZOS)
        x, y = (i % cols) * w, (i // cols) * h
        out.paste(im, (x, y))
        name = os.path.basename(f).replace('game_itch_%s_' % lang, '').replace('.png', '')
        d.rectangle((x, y, x + 150, y + 20), fill='black')
        d.text((x + 4, y + 4), name, fill='white')
    path = os.path.join(SHOTS, 'itch_hoja_%s.png' % lang)
    out.save(path)
    print('hoja:', path)


def main():
    if '--hoja' in sys.argv:
        i = sys.argv.index('--hoja')
        sheet(sys.argv[i + 1] if len(sys.argv) > i + 1 else 'es')
        return
    for lang, sub in (('es', 'capturas'), ('en', 'capturas_en')):
        d = os.path.join(DEST, sub)
        os.makedirs(d, exist_ok=True)
        for k, (n, t) in enumerate(ELEGIDAS[lang], 1):
            src = shot(lang, n, t)
            if not os.path.exists(src):
                print('falta', src)
                continue
            shutil.copyfile(src, os.path.join(d, '%02d.png' % k))
        print(sub, 'listas')
    gif = os.path.join(SHOTS, 'videos', 'trailer.gif')
    if os.path.exists(gif):
        shutil.copyfile(gif, os.path.join(DEST, 'capturas', 'trailer.gif'))
    t, (x, y, w) = PORTADA
    src = os.path.join(SHOTS, 'titulo_itch_portada_%ss.png' % t)
    if os.path.exists(src):
        h = round(w * 500 / 630)
        Image.open(src).convert('RGB').crop((x, y, x + w, y + h)).resize((630, 500), Image.LANCZOS) \
            .save(os.path.join(DEST, 'portada_630x500.png'))
        print('portada lista')


if __name__ == '__main__':
    main()
