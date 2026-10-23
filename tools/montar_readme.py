"""Imágenes del README (docs/img/) a partir de las capturas de shots/ y de los datos del juego.

1. Capturas: sh tools/capturas_readme.sh (unos 45 minutos; deja los PNG y el vídeo en shots/).
2. Montaje: python tools/montar_readme.py
   - Capturas reducidas a 960 px de ancho (la columna de un README en GitHub mide unos 900 px).
   - Láminas de modelos recortadas a su contenido, puestas una al lado de otra a la misma altura;
     las de dos filas, una debajo de otra.
   - Las trece caras de cerca, en dos filas.
   - Iconos de las armas, de sus evoluciones y de los objetos, leídos de data/ en el orden de las
     tablas del README (armas por tipo y nombre; objetos por nombre).
   - El GIF de la partida, del vídeo shots/videos/readme_partida.avi, con ffmpeg.
Si cambia qué captura se usa, cambia la lista del final.
"""
import glob, os, re, subprocess
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'docs', 'img')
SHOTS = os.path.join(ROOT, 'shots')
BG = (14, 16, 22)
W = 960


def find(src):
    """Ruta de una captura: en la raíz de shots/ o, si ya se ordenó (tools/ordenar_shots.py), en sus carpetas."""
    p = os.path.join(SHOTS, src)
    if os.path.exists(p): return p
    for d, _, files in os.walk(SHOTS):
        if os.path.basename(src) in files: return os.path.join(d, os.path.basename(src))
    raise FileNotFoundError(src)


def save(im, dst, quality=86):
    im.convert('RGB').save(os.path.join(OUT, dst), quality=quality, optimize=True, progressive=True)


def shot(src, dst, w=W, crop=None):
    """Captura reducida a w px de ancho; crop=(x0, y0, x1, y1) en fracciones recorta antes (jefes)."""
    im = Image.open(find(src)).convert('RGB')
    if crop:
        im = im.crop((round(crop[0] * im.width), round(crop[1] * im.height),
                      round(crop[2] * im.width), round(crop[3] * im.height)))
    save(im.resize((w, round(im.height * w / im.width)), Image.LANCZOS), dst)


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


def _row(srcs, w, pad=24):
    """Una fila: cada captura recortada a su contenido, una al lado de otra a la misma altura."""
    parts = []
    for src in srcs:
        im = Image.open(find(src)).convert('RGB')
        x0, y0, x1, y1 = _content_box(im)
        parts.append(im.crop((max(x0 - pad, 0), max(y0 - pad, 0), min(x1 + pad, im.width), min(y1 + pad, im.height))))
    h = max(p.height for p in parts)
    parts = [p.resize((round(p.width * h / p.height), h), Image.LANCZOS) for p in parts]
    total = sum(p.width for p in parts)
    row = Image.new('RGB', (total, h), BG)
    x = 0
    for p in parts:
        row.paste(p, (x, 0))
        x += p.width
    return row.resize((w, round(h * w / total)), Image.LANCZOS)


def lineup(rows, dst, w=W):
    """Lámina de modelos: una fila por lista de capturas, una debajo de otra."""
    ims = [_row(r, w) for r in rows]
    sheet = Image.new('RGB', (w, sum(i.height for i in ims)), BG)
    y = 0
    for im in ims:
        sheet.paste(im, (0, y))
        y += im.height
    save(sheet, dst, 88)


def faces(models, tag, dst, cols=7, w=W, top=0.05, bottom=0.40, width=0.32):
    """Caras de cerca: de cada captura (still 20 <pj> size=1600x1600, el visor encuadra el cuerpo
    entero) se recorta la cabeza, arriba y en el centro. Todas a la misma escala: en una fila con
    menos caras, cada recorte es más ancho para llenar la fila con el fondo de la propia captura."""
    rows = [models[i:i + cols] for i in range(0, len(models), cols)]
    scale = (w / cols) / width                          # px de la lámina por unidad de la captura
    cell_h = round((bottom - top) * scale)
    sheet = Image.new('RGB', (w, cell_h * len(rows)), BG)
    for r, row in enumerate(rows):
        x = 0
        for c, m in enumerate(row):
            cell_w = w * (c + 1) // len(row) - x
            im = Image.open(find('%s_20_%s.png' % (m, tag))).convert('RGB')
            half = cell_w / scale / 2
            im = im.crop((round((0.5 - half) * im.width), round(top * im.height),
                          round((0.5 + half) * im.width), round(bottom * im.height)))
            sheet.paste(im.resize((cell_w, cell_h), Image.LANCZOS), (x, r * cell_h))
            x += cell_w
    save(sheet, dst, 90)


def _tres(path):
    return open(path, encoding='utf-8').read()


def _field(text, key):
    m = re.search(r'^%s = (.*)$' % key, text, re.M)
    return m.group(1).strip().lstrip('&').strip('"') if m else ''


def weapon_icons():
    """Iconos de las armas base y de sus evoluciones, por tipo (físicas, de fuego, mágicas) y nombre."""
    base = []
    for f in glob.glob(os.path.join(ROOT, 'data', 'weapons', '*.tres')):
        t = _tres(f)
        if _field(t, 'evolution'): base.append((_field(t, 'category'), _field(t, 'display_name'), _field(t, 'id'), _field(t, 'evolution')))
    base.sort()
    icon = lambda wid: os.path.join(ROOT, 'resources', 'weapons', 'icons', wid + '.png')
    return [icon(b[2]) for b in base], [icon(b[3]) for b in base]


def item_icons():
    """Iconos de los 50 objetos de la subida de nivel, por nombre."""
    items = []
    for f in glob.glob(os.path.join(ROOT, 'data', 'upgrades', '*.tres')):
        t = _tres(f)
        m = re.search(r'path="res://(resources/items/icons/[^"]+)"', t)
        items.append((_field(t, 'display_name'), os.path.join(ROOT, m.group(1))))
    items.sort()
    return [p for _, p in items]


def icons(files, dst, cols=10, w=W):
    size = w // cols
    rows = -(-len(files) // cols)
    sheet = Image.new('RGB', (cols * size, rows * size), BG)
    for k, f in enumerate(files):
        im = Image.open(f).convert('RGBA').resize((size - 8, size - 8), Image.LANCZOS)
        sheet.paste(im, ((k % cols) * size + 4, (k // cols) * size + 4), im)
    save(sheet, dst, 90)


def gif(src, dst, start, secs, w=640, fps=10, colors=128):
    """GIF de un trozo del vídeo, con paleta propia (palettegen) y sin difuminado: con la horda,
    la lluvia y las gemas cada fotograma cambia mucho, y el difuminado lo subía de 10 a 23 MB."""
    vf = 'fps=%d,scale=%d:-1:flags=lanczos' % (fps, w)
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-ss', str(start), '-t', str(secs), '-i', find(src),
                    '-filter_complex', '[0:v]%s,split[a][b];[a]palettegen=max_colors=%d:stats_mode=full[p];'
                    '[b][p]paletteuse=dither=none:diff_mode=rectangle' % (vf, colors),
                    os.path.join(OUT, dst)], check=True)


JEFES = ['game_readme_jefe1_008.0s.png', 'game_readme_jefe2_016.0s.png', 'game_readme_jefe3_030.0s.png']
JEFES_CROP = [(0.0, 0.2, 0.6, 1.0), (0.4, 0.02, 1.0, 0.82), (0.4, 0.02, 1.0, 0.82)]   # el jefe y el jugador, en 4:3

os.makedirs(OUT, exist_ok=True)
for f in glob.glob(os.path.join(OUT, '*.jpg')): os.remove(f)
shot('titulo_readme_011.0s.png', 'portada.jpg')
# Partida: dos por parte, y dos más de la tercera
shot('game_readme_p1n1_110.0s.png', 'p1_campamento.jpg')
shot('game_readme_p1n3_110.0s.png', 'p1_paso.jpg')
shot('game_readme_p2n3_100.0s.png', 'p2_tejados.jpg')
shot('game_readme_p2n4_110.0s.png', 'p2_pantano.jpg')
shot('game_readme_p3n1_110.0s.png', 'p3_estudio.jpg')
shot('game_readme_p3n2_110.0s.png', 'p3_ritual.jpg')
shot('game_readme_p3n4_110.0s.png', 'p3_tormenta.jpg')
shot('game_readme_p3n5_150.0s.png', 'p3_rlyeh.jpg')
# Jefes: recortados al centro, en tres columnas
shot(JEFES[0], 'jefe_shoggoth.jpg', 640, JEFES_CROP[0])
shot(JEFES[1], 'jefe_dagon.jpg', 640, JEFES_CROP[1])
shot(JEFES[2], 'jefe_cthulhu.jpg', 640, JEFES_CROP[2])
# Menús
shot('seleccion_readme_sel_003.0s.png', 'seleccion.jpg')
shot('seleccion_readme_mapa_002.0s.png', 'mapa.jpg')
shot('readme_relato_12.0s.png', 'relato.jpg')
shot('game_readme_ficha_013.0s.png', 'ficha.jpg')
shot('titulo_readme_tienda_014.0s.png', 'tienda.jpg')
shot('titulo_readme_biblio_014.0s.png', 'biblioteca.jpg')
shot('titulo_readme_logros_014.0s.png', 'logros.jpg')
shot('titulo_readme_online_014.0s.png', 'online.jpg')
# Modelos
lineup([['dyer-olmstead-legrasse-johansen-peaslee-varga-whipple_0_readme.png']], 'personajes_1.jpg')
lineup([['blake-iwanicki-elwood-malone-armitage-west_0_readme.png']], 'personajes_2.jpg')
faces(['dyer', 'olmstead', 'legrasse', 'johansen', 'peaslee', 'varga', 'whipple',
       'blake', 'iwanicki', 'elwood', 'malone', 'armitage', 'west'], 'readme', 'cabezas.jpg')
lineup([['perro-gato-rata-sapo_0_readme.png', 'buho-shoggoth-byakhee-cuervo_0_readme.png']], 'companeros_1.jpg')
lineup([['polilla-gaviota-migo-tindalos_0_readme.png', 'yig-pez-dhole-cabra_0_readme.png']], 'companeros_2.jpg')
lineup([['pinguino-fragmento-antiguo-antiguo_alado-shoggoth_grande_0_readme.png'],
        ['antiguo_guerrero-antiguo_mutilado-shoggoth_ojos-antiguo_abisal_0_readme.png']], 'bestiario_1.jpg')
lineup([['habitante_viejo-habitante_mujer-acolito-hibrido_h-hibrido_m_0_readme.png'],
        ['sacerdote-profundo-profundo_lanzador-profundo_anciano-acechador_0_readme.png']], 'bestiario_2.jpg')
lineup([['cultista-cultista_alert-pesadilla-diablo_0_readme.png'],
        ['engendro-polipo-emanacion-primigenio_menor_0_readme.png']], 'bestiario_3.jpg')
# Iconos
weapons, evolutions = weapon_icons()
icons(weapons, 'armas.jpg')
icons(evolutions, 'evoluciones.jpg')
icons(item_icons(), 'objetos.jpg')
# GIF de la partida
gif('readme_partida.avi', 'partida.gif', 20, 6)
print(sorted(os.listdir(OUT)))
