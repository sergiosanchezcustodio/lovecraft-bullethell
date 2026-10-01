"""Imágenes del README (docs/img/) a partir de las capturas de shots/ y de los iconos del juego.

Capturas reducidas a 960 px de ancho (la columna de un README en GitHub mide unos 900 px),
láminas de modelos recortadas a su contenido y una lámina con los iconos de las armas y los
objetos, leídos de las mismas carpetas que usa el juego.
Uso: python tools/montar_readme.py   (después de sacar las capturas; ver README, "Imágenes")
"""
import glob, os
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'docs', 'img')
SHOTS = os.path.join(ROOT, 'shots')
BG = (14, 16, 22)


def shot(src, dst, w=960):
    im = Image.open(os.path.join(SHOTS, src)).convert('RGB')
    im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    im.save(os.path.join(OUT, dst), quality=86, optimize=True)


def _content_box(im):
    """Caja de lo que no es el suelo del visor (verde oscuro) ni la luz verdosa del foco."""
    px = im.load()
    xs, ys = [], []
    for y in range(0, im.height, 3):
        for x in range(0, im.width, 3):
            r, g, b = px[x, y][:3]
            greenish = g > r + 12 and g >= b - 10
            if not greenish and max(r, g, b) > 40: xs.append(x); ys.append(y)
    return min(xs), min(ys), max(xs), max(ys)


def lineup(srcs, dst, w=960, pad=24):
    """Lámina de modelos: cada captura recortada a su contenido, puestas una al lado de otra
    a la misma altura, sobre el fondo de las láminas."""
    parts = []
    for src in srcs:
        im = Image.open(os.path.join(SHOTS, src)).convert('RGB')
        x0, y0, x1, y1 = _content_box(im)
        parts.append(im.crop((max(x0 - pad, 0), max(y0 - pad, 0), min(x1 + pad, im.width), min(y1 + pad, im.height))))
    h = max(p.height for p in parts)
    total = sum(p.width for p in parts)
    sheet = Image.new('RGB', (total, h), BG)
    x = 0
    for p in parts:
        sheet.paste(p, (x, (h - p.height) // 2))
        x += p.width
    sheet = sheet.resize((w, round(h * w / total)), Image.LANCZOS)
    sheet.save(os.path.join(OUT, dst), quality=88, optimize=True)


def icons(pattern, dst, cols, size=80):
    files = sorted(glob.glob(os.path.join(ROOT, pattern)))
    rows = -(-len(files) // cols)
    sheet = Image.new('RGB', (cols * size, rows * size), BG)
    for k, f in enumerate(files):
        im = Image.open(f).convert('RGBA').resize((size - 8, size - 8), Image.LANCZOS)
        sheet.paste(im, ((k % cols) * size + 4, (k // cols) * size + 4), im)
    sheet.save(os.path.join(OUT, dst), quality=90, optimize=True)


os.makedirs(OUT, exist_ok=True)
for f in glob.glob(os.path.join(OUT, '*.jpg')) + glob.glob(os.path.join(OUT, '*.import')): os.remove(f)   # el GIF se queda
shot('titulo_readme_011.0s.png', 'portada.jpg')
shot('game_readme_horda_022.0s.png', 'horda.jpg')
shot('game_readme_final_014.0s.png', 'evento_final.jpg')
shot('game_readme_clima_020.0s.png', 'clima.jpg')
shot('game_readme_ficha_007.0s.png', 'ficha.jpg')
shot('seleccion_readme_001.5s.png', 'seleccion.jpg')
shot('titulo_readme_tienda_014.0s.png', 'tienda.jpg')
shot('titulo_readme_logros_014.0s.png', 'logros.jpg')
lineup(['dyer-olmstead-legrasse-johansen-peaslee-varga_0_readme_a.png'], 'personajes_1.jpg')
lineup(['whipple-blake-iwanicki-elwood-malone_0_readme_b.png'], 'personajes_2.jpg')
lineup(['perro-gato-rata-sapo_0_readme_c1.png', 'buho-shoggoth-byakhee-cuervo_0_readme_c2.png'], 'companeros_1.jpg')
lineup(['polilla-gaviota-migo-tindalos_0_readme_c3.png', 'yig-pez-dhole-cabra_0_readme_c4.png'], 'companeros_2.jpg')
lineup(['pinguino-fragmento-acechador_0_readme_e.png'], 'bestiario.jpg')
icons('resources/weapons/icons/*.png', 'armas.jpg', 12)
icons('resources/items/icons/*.png', 'objetos.jpg', 12)
print(sorted(os.listdir(OUT)))
