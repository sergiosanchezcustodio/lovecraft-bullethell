"""Vestuario (D-34, hito 2.16): prendas que se ponen encima de cualquier personaje.

Cada prenda se genera para cada personaje con sus medidas (la clave "body" de su JSON, que
escribe cuerpo.finish: ancho del tronco b, cuerpo de mujer, separación y grosor de los brazos
y tamaño de la cabeza) y con sus mismos pivotes, así que sus partes cuelgan de las del
personaje y se animan con él (VoxelBuilder.dress). Cada prenda es algo más grande que lo que
tapa (1-1,5 voxels por lado) para que no se vea la ropa de debajo ni haya caras que se pisen.
Las de cabeza ocultan el sombrero del personaje (parte `hat`): cubren desde la altura 76.

Salida: models/vest_<prenda>_<personaje>.json.
Uso: python tools/gen_vestuario.py [prenda ...]
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, rslab, T, H
import materiales

CHARS = ['dyer', 'olmstead', 'legrasse', 'johansen', 'peaslee', 'varga', 'whipple', 'blake',
         'iwanicki', 'elwood', 'malone']


def body_of(c):
    with open('models/%s.json' % c) as f:
        return json.load(f)['body']


# ------------------------------------------------------------------ cabeza

def _head_box(bd):
    return float(bd['head_w']), float(bd['head_d'])


def bombin(M, bd):
    """Bombín negro con cinta: copa redonda y ala corta que se curva."""
    BLACK = (0.10, 0.10, 0.11); BAND = (0.22, 0.12, 0.10)
    w, d = _head_box(bd)
    slab(M, H, BLACK, 77, 78, 0, 0.5, w + 6, w + 6, d + 4.5, d + 4.5, ch=3)
    rslab(M, H, BLACK, 78, 88, 0, 0.3, w + 1.5, d + 1.5, r=4, rt=4.5, rb=0)
    slab(M, H, BAND, 78, 80, 0, 0.3, w + 2, w + 2, d + 2, d + 2, ch=3)
    return {BLACK: 'lana'}


def casco_minero(M, bd):
    """Casco de minero de cuero endurecido, con ala y lámpara de carburo delante."""
    SHELL = (0.55, 0.42, 0.20); SHELL_SH = (0.42, 0.31, 0.14); BRASS = (0.78, 0.62, 0.26); LAMP = (1.0, 0.92, 0.6)
    w, d = _head_box(bd)
    slab(M, H, SHELL_SH, 76, 77, 0, 0.5, w + 5, w + 5, d + 4.5, d + 4.5, ch=3)
    rslab(M, H, SHELL, 77, 87, 0, 0.3, w + 2.5, d + 2.5, r=4.5, rt=5, rb=0)
    slab(M, H, BRASS, 79, 84, 0, 0.5 + (d + 2.5) / 2 + 0.5, 4, 4, 2, 2, ch=0)  # lámpara
    for x in (-1, 0):
        for y in (81, 82):
            z = M.front(x, y)
            if z is not None: M.put(x, y, z + 1, H, LAMP, 1)
    return {SHELL: 'cuero', SHELL_SH: 'cuero'}


def gorro_nieve(M, bd):
    """Gorro de lana de rayas con vuelta y borla."""
    KNIT = (0.20, 0.36, 0.58); STRIPE = (0.88, 0.86, 0.80); POM = (0.92, 0.90, 0.84)
    w, d = _head_box(bd)
    rslab(M, H, KNIT, 76, 89, 0, 0.3, w + 2, d + 2, r=4.5, rt=5.5, rb=0)
    slab(M, H, KNIT, 76, 80, 0, 0.3, w + 3, w + 3, d + 3, d + 3, ch=3)          # vuelta
    for (x, y, z), v in M.V.items():
        if v[0] == H and y in (82, 83) and v[1] == KNIT: v[1] = STRIPE
    rslab(M, H, POM, 89, 94, 0, -0.5, 6, 6, r=2.5, rt=2.5, rb=2)
    return {KNIT: 'punto', STRIPE: 'punto', POM: 'borreguillo'}


def chistera(M, bd):
    """Sombrero de copa: ala plana y copa alta con cinta gris."""
    BLACK = (0.09, 0.09, 0.10); BAND = (0.36, 0.36, 0.40)
    w, d = _head_box(bd)
    slab(M, H, BLACK, 77, 78, 0, 0.5, w + 6, w + 6, d + 4.5, d + 4.5, ch=3)
    slab(M, H, BLACK, 78, 95, 0, 0.3, w + 0.5, w + 1.5, d + 0.5, d + 1.5, ch=3)
    slab(M, H, BAND, 78, 81, 0, 0.3, w + 1.2, w + 1.2, d + 1.2, d + 1.2, ch=3)
    return {BLACK: 'lana', BAND: 'lana'}


# ------------------------------------------------------------------ cuerpo

def _torso_cover(M, bd, col, bottom, pad=2.5):
    """Tronco algo mayor que el del personaje (de hombre o de mujer) desde `bottom`."""
    b = bd['b']
    if bd['fem']:
        rows = [(bottom, 45, 22, 19, 13, 12), (45, 50, 18.5, 18, 11.5, 11.5), (50, 57, 18.5, 20.5, 12.5, 14),
                (57, 62, 20.5, 17, 13, 11)]
    else:
        rows = [(bottom, 45, 24, 23, 13, 13), (45, 50, 22, 21, 12.5, 12.5), (50, 58, 21, 25, 12.5, 14),
                (58, 62, 25, 20, 14, 12)]
    for y0, y1, w0, w1, d0, d1 in rows:
        slab(M, T, col, y0, y1, 0, 0.3, w0 + b + pad, w1 + b + pad, d0 + pad, d1 + pad, ch=2)


def _sleeves(M, bd, col, cuff_col=None, pad=2.5, bottom=36):
    k = 0.85 if bd['slim'] else 1.0
    for s, _, _, arm, fa in cu.sides():
        cx = (bd['ax'] + bd.get('arm_b', bd['b']) / 2) * s
        slab(M, arm, col, 46, 62, cx, 0, 7 * k + pad, 8.5 * k + pad, 7.5 * k + pad, 8.5 * k + pad, ch=1)
        slab(M, fa, col, bottom, 46, cx * 1.02, 0.5, 8.5 + pad - 1, 7 * k + pad, 9 + pad - 1, 7.5 * k + pad, ch=1)
        if cuff_col is not None:
            slab(M, fa, cuff_col, bottom - 1, bottom + 2, cx * 1.02, 0.5, 9.5 + pad - 1, 9.5 + pad - 1,
                 10 + pad - 1, 10 + pad - 1, ch=1)


def chaqueta_aviador(M, bd):
    """Chaqueta de aviador de cuero marrón con cuello de borreguillo, cintura y puños de punto
    y cremallera."""
    LEATHER = (0.40, 0.24, 0.13); LEATHER_SH = (0.30, 0.17, 0.09); FUR = (0.86, 0.80, 0.68)
    KNIT = (0.30, 0.20, 0.13); ZIP = (0.70, 0.66, 0.56)
    _torso_cover(M, bd, LEATHER, 38)
    b = bd['b'] + (0 if not bd['fem'] else -3)
    slab(M, T, KNIT, 37, 40, 0, 0.3, 27 + b, 27 + b, 16, 16, ch=2)                   # cintura de punto
    slab(M, T, FUR, 59, 64, 0, 0.3, 18 + b * 0.5, 16 + b * 0.5, 16.5, 14, ch=2)      # cuello de borreguillo
    for y in range(40, 59):                                                        # cremallera
        z = M.front(0, y)
        if z is not None: M.put(0, y, z, T, ZIP)
    for s in (-1, 1):                                                              # bolsillos
        for y in range(43, 49):
            z = M.front(int(6 * s), y)
            if z is not None: M.put(int(6 * s), y, z, T, LEATHER_SH)
    _sleeves(M, bd, LEATHER, KNIT)
    return {LEATHER: 'cuero', LEATHER_SH: 'cuero', FUR: 'borreguillo', KNIT: 'punto'}


def abrigo_piel(M, bd):
    """Abrigo largo de piel, pardo claro, hasta las rodillas, con cuello y puños de pelo
    más oscuro y botones de hueso."""
    FUR = (0.62, 0.48, 0.32); FUR_D = (0.40, 0.29, 0.18); BONE = (0.88, 0.84, 0.72)
    _torso_cover(M, bd, FUR, 38, pad=2.5)
    b = bd['b'] + (0 if not bd['fem'] else -2)
    slab(M, T, FUR, 23, 38, 0, 0.3, 29 + b, 26.5 + b, 18, 15.5, ch=3)                # faldón (las piernas, debajo)
    slab(M, T, FUR_D, 21, 23, 0, 0.3, 29.5 + b, 29.5 + b, 18.5, 18.5, ch=3)
    slab(M, T, FUR_D, 58, 65, 0, 0.3, 21 + b * 0.5, 18 + b * 0.5, 18, 15, ch=3)     # cuello
    for y in (30, 37, 44, 51):
        z = M.front(0, y)
        if z is not None: M.put(0, y, z + 1, T, BONE); M.put(-1, y, z + 1, T, BONE)
    _sleeves(M, bd, FUR, FUR_D, pad=2.5)
    return {FUR: 'borreguillo', FUR_D: 'pelo'}


# ------------------------------------------------------------------ pies

def _boot(M, bd, col, sole, top, cuff=None, pad=1.5):
    for s, _, shin, _, _ in cu.sides():
        cx = (4.5 if bd['fem'] else 5) * s
        slab(M, shin, sole, 0, 2, cx, 1.2, 9 + pad, 9 + pad, 15 + pad, 15 + pad, ch=1)
        slab(M, shin, col, 2, 5, cx, 1.2, 9 + pad, 9 + pad, 15 + pad - 0.5, 14 + pad, ch=1)
        slab(M, shin, col, 5, top, cx, -0.3, 9 + pad, 9.5 + pad, 10 + pad, 10 + pad, ch=1)
        if cuff is not None:
            slab(M, shin, cuff, top, top + 3, cx, -0.3, 10.5 + pad, 10.5 + pad, 11.5 + pad, 11.5 + pad, ch=1)


def botas_militares(M, bd):
    """Botas militares altas de cuero, con cordones cruzados."""
    LEATHER = (0.24, 0.17, 0.11); SOLE = (0.10, 0.08, 0.07); LACE = (0.62, 0.55, 0.42)
    _boot(M, bd, LEATHER, SOLE, 18)
    for s, _, shin, _, _ in cu.sides():
        cx = int(round((4.5 if bd['fem'] else 5) * s))
        for y in range(6, 18, 2):
            for x in (cx - 1, cx):
                z = M.front(x, y)
                if z is not None and M.V[(x, y, z)][0] == shin: M.put(x, y, z, shin, LACE)
    return {LEATHER: 'cuero', SOLE: 'cuero'}


def botas_nieve(M, bd):
    """Botas de nieve grises de lona encerada, con vuelta de borreguillo."""
    CANVAS = (0.46, 0.48, 0.50); SOLE = (0.14, 0.12, 0.10); FUR = (0.90, 0.88, 0.82)
    _boot(M, bd, CANVAS, SOLE, 13, cuff=FUR, pad=1.5)
    return {CANVAS: 'lona', SOLE: 'cuero', FUR: 'borreguillo'}


GARMENTS = {'bombin': bombin, 'casco_minero': casco_minero, 'gorro_nieve': gorro_nieve, 'chistera': chistera,
            'chaqueta_aviador': chaqueta_aviador, 'abrigo_piel': abrigo_piel,
            'botas_militares': botas_militares, 'botas_nieve': botas_nieve}


def build(name, c):
    bd = body_of(c)
    M = cu.new(9100 + CHARS.index(c))
    mats = GARMENTS[name](M, bd)
    materiales.texturize(M, mats)
    piv, parents = cu.pivots(bd['finish_b'], bd['finish_ax'])
    out = 'models/vest_%s_%s.json' % (name, c)
    return M.export(out, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25, parents=parents)


if __name__ == '__main__':
    for name in (sys.argv[1:] or GARMENTS):
        total = sum(build(name, c) for c in CHARS)
        print(name, total, 'voxels en', len(CHARS), 'personajes')
