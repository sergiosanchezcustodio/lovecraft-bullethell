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



# ------------------------------------------------------------------ segunda tanda (03-10-2026)

def hair_of(c):
    """Color del pelo del personaje: el más repetido en la cabeza (sin sombrero) por encima
    de las orejas, que no sea la piel de la cara."""
    with open('models/%s.json' % c) as f:
        vox = json.load(f)['voxels']
    skin = None
    for v in vox:
        if v[3] == 'head' and v[0] == 0 and v[1] == 70: skin = tuple(v[4:7])
    count = {}
    for v in vox:
        if v[3] != 'head' or v[1] < 74: continue
        col = tuple(v[4:7])
        if skin and sum(abs(a - b) for a, b in zip(col, skin)) < 0.25: continue
        count[col] = count.get(col, 0) + 1
    if not count: return (0.25, 0.18, 0.12)
    return max(count, key=count.get)


def casco_brodie(M, bd):
    """Casco Brodie de la Gran Guerra: plato muy ancho a los lados y copa baja."""
    STEEL = (0.38, 0.40, 0.32); STEEL_SH = (0.28, 0.30, 0.24)
    w, d = _head_box(bd)
    slab(M, H, STEEL_SH, 77, 78, 0, 0.5, w + 10, w + 10, d + 4.5, d + 4.5, ch=6)
    slab(M, H, STEEL_SH, 78, 79, 0, 0.5, w + 7, w + 7, d + 4, d + 4, ch=5)
    rslab(M, H, STEEL, 78, 85, 0, 0.3, w + 1.5, d + 1.5, r=4, rt=3, rb=0)
    return {STEEL: 'lona', STEEL_SH: 'lona'}


def cinta_pelo(M, bd, hair=(0.25, 0.18, 0.12)):
    """Cinta del pelo roja sobre el pelo del personaje (cubre la coronilla del sombrero)."""
    BAND = (0.70, 0.14, 0.14)
    w, d = _head_box(bd)
    rslab(M, H, hair, 76, 84, 0, 0.0, w + 1, d + 1, r=4, rt=4, rb=0)
    slab(M, H, BAND, 78, 80, 0, 0.2, w + 1.6, w + 1.6, d + 1.6, d + 1.6, ch=3)
    slab(M, H, BAND, 77, 81, -(w / 2 - 2), -d / 2 - 0.5, 3, 3, 1.5, 1.5, ch=0)      # lazo atrás
    return {hair: 'pelo'}


def sombrero_aventurero(M, bd):
    """Sombrero de aventurero de fieltro pardo: ala ancha, cinta y copa con hendidura."""
    FELT = (0.42, 0.30, 0.18); FELT_SH = (0.33, 0.23, 0.13); BAND = (0.16, 0.11, 0.08)
    w, d = _head_box(bd)
    slab(M, H, FELT_SH, 77, 78, 0, 0.5, w + 8, w + 8, d + 5, d + 5, ch=4)
    slab(M, H, BAND, 78, 80, 0, 0.3, w + 1, w + 1, d + 1, d + 1, ch=3)
    slab(M, H, FELT, 80, 87, 0, 0.3, w + 1, w - 1, d + 1, d - 2, ch=3)
    for z in range(-4, 5):                                             # hendidura
        for x in (-1, 0):
            if (x, 86, z) in M.V: M.V.pop((x, 86, z))
    return {FELT: 'lana', FELT_SH: 'lana'}


def boina(M, bd):
    """Boina burdeos de lana, ladeada, con el rabillo arriba (negra no se veía sobre el pelo
    negro de Varga y Malone)."""
    WOOL = (0.42, 0.10, 0.14); WOOL_SH = (0.32, 0.07, 0.10)
    w, d = _head_box(bd)
    slab(M, H, WOOL_SH, 76, 79, 0, 0.3, w + 1.2, w + 1.2, d + 1.2, d + 1.2, ch=3)
    rslab(M, H, WOOL, 79, 85, 1.5, -0.5, w + 4, d + 3, r=5, rt=2.5, rb=1)
    slab(M, H, WOOL, 85, 87, 1.5, -0.5, 1, 1, 1, 1, ch=0)
    return {WOOL: 'lana', WOOL_SH: 'lana'}


def sombrero_vaquero(M, bd):
    """Sombrero vaquero de ala ancha con los lados levantados, copa con hundido y cinta."""
    HIDE = (0.62, 0.48, 0.30); HIDE_SH = (0.50, 0.37, 0.22); BAND = (0.30, 0.18, 0.10)
    w, d = _head_box(bd)
    slab(M, H, HIDE_SH, 77, 78, 0, 0.5, w + 10, w + 10, d + 5, d + 5, ch=4)
    for s in (-1, 1):                                                  # lados levantados
        slab(M, H, HIDE_SH, 78, 80, s * (w / 2 + 4), 0.5, 2, 2, d + 3, d + 3, ch=1)
    slab(M, H, BAND, 78, 80, 0, 0.3, w + 1.2, w + 1.2, d + 1.2, d + 1.2, ch=3)
    slab(M, H, HIDE, 80, 89, 0, 0.3, w + 1, w - 1, d + 1, d - 1, ch=3)
    for z in range(-5, 6):                                             # hundido de la copa
        for x in (-2, -1, 0, 1):
            if (x, 88, z) in M.V: M.V.pop((x, 88, z))
    return {HIDE: 'cuero', HIDE_SH: 'cuero'}


def sombrero_mujer(M, bd):
    """Pamela de los años 20: ala ancha que cae, copa baja, cinta y una flor al lado."""
    STRAW = (0.62, 0.30, 0.38); STRAW_SH = (0.50, 0.22, 0.30); RIBBON = (0.20, 0.12, 0.18)
    FLOWER = (0.95, 0.85, 0.70); LEAF = (0.30, 0.45, 0.25)
    w, d = _head_box(bd)
    slab(M, H, STRAW_SH, 77, 78, 0, 0.5, w + 9, w + 9, d + 5, d + 5, ch=5)
    for s in (-1, 1):                                                  # ala que cae a los lados
        slab(M, H, STRAW_SH, 75, 77, s * (w / 2 + 4), 0.5, 1.5, 1.5, d - 2, d - 2, ch=1)
    slab(M, H, STRAW, 78, 85, 0, 0.3, w + 1, w, d + 1, d, ch=3)
    slab(M, H, RIBBON, 78, 80, 0, 0.3, w + 1.6, w + 1.6, d + 1.6, d + 1.6, ch=3)
    rslab(M, H, FLOWER, 79, 83, w / 2 + 0.5, 3, 3, 3, r=1, rt=1, rb=1)
    slab(M, H, LEAF, 79, 80, w / 2 + 0.5, 0.5, 2, 2, 2, 2, ch=0)
    return {STRAW: 'lana', STRAW_SH: 'lana', RIBBON: 'lana'}


def turbante(M, bd):
    """Turbante de tela azafrán con vueltas y una joya verde delante."""
    CLOTH = (0.86, 0.58, 0.20); CLOTH_SH = (0.72, 0.44, 0.14); GEM = (0.30, 0.85, 0.45); GOLD = (0.88, 0.72, 0.30)
    w, d = _head_box(bd)
    rslab(M, H, CLOTH, 76, 89, 0, 0.0, w + 3, d + 3, r=5.5, rt=5, rb=0)
    for (x, y, z), v in M.V.items():                                   # vueltas en diagonal
        if v[0] == H and v[1] == CLOTH and (y + (x // 3)) % 4 == 0: v[1] = CLOTH_SH
    zf = int(0.5 + (d + 3) / 2)
    slab(M, H, GOLD, 79, 83, 0, zf + 0.5, 3, 3, 1, 1, ch=0)
    M.put(-1, 80, zf + 1, H, GEM, 1); M.put(0, 80, zf + 1, H, GEM, 1)
    M.put(-1, 81, zf + 1, H, GEM, 1); M.put(0, 81, zf + 1, H, GEM, 1)
    return {CLOTH: 'lana', CLOTH_SH: 'lana'}


def sombrero_paja(M, bd):
    """Canotier de paja: ala plana, copa recta de tapa plana y cinta negra."""
    STRAW = (0.86, 0.74, 0.42); STRAW_SH = (0.74, 0.62, 0.32); BAND = (0.10, 0.10, 0.12)
    w, d = _head_box(bd)
    slab(M, H, STRAW_SH, 77, 78, 0, 0.5, w + 7, w + 7, d + 5, d + 5, ch=4)
    slab(M, H, STRAW, 78, 84, 0, 0.3, w + 1, w + 1, d + 1, d + 1, ch=3)
    slab(M, H, BAND, 78, 80, 0, 0.3, w + 1.5, w + 1.5, d + 1.5, d + 1.5, ch=3)
    for (x, y, z), v in M.V.items():                                   # trenzado de la paja
        if v[0] == H and v[1] == STRAW and (x + y + z) % 3 == 0: v[1] = STRAW_SH
    return {STRAW: 'lona', STRAW_SH: 'lona'}


# accesorios (cara y cuello): no ocultan el sombrero

def _face_z(bd):
    return int(round(0.5 + bd['head_d'] / 2)) + 1


def gafas_ver(M, bd):
    """Gafas redondas de montura dorada: dos aros alrededor de los ojos, puente y patillas."""
    GOLD = (0.80, 0.64, 0.26)
    w, d = _head_box(bd)
    z = _face_z(bd)
    for x0 in (-6, 1):                                                 # aros: 5 de ancho, 4 de alto
        for x in range(x0, x0 + 5):
            for y in (72, 75):
                if x in (x0, x0 + 4): continue
                M.put(x, y, z, H, GOLD)
        for y in (73, 74):
            M.put(x0, y, z, H, GOLD); M.put(x0 + 4, y, z, H, GOLD)
    M.put(-1, 74, z, H, GOLD); M.put(0, 74, z, H, GOLD)               # puente
    hx = int(w / 2) + 1
    for zz in range(-2, z + 1):                                        # patillas
        M.put(-hx, 74, zz, H, GOLD); M.put(hx - 1, 74, zz, H, GOLD)
    return {}


def gafas_nieve(M, bd):
    """Gafas de nieve inuit: placa de hueso con dos rendijas y correa de cuero."""
    BONE = (0.84, 0.78, 0.64); SLIT = (0.04, 0.04, 0.05); STRAP = (0.30, 0.20, 0.12)
    w, d = _head_box(bd)
    z = _face_z(bd)
    for x in range(-7, 7):
        for y in range(72, 77):
            if y in (72, 76) and x in (-7, 6): continue
            M.put(x, y, z, H, BONE)
    for x in (-5, -4, -3, 2, 3, 4):
        M.put(x, 74, z, H, SLIT)
    slab(M, H, STRAP, 73, 76, 0, 0.0, w + 1.2, w + 1.2, d + 1.2, d + 1.2, ch=3)
    for x in range(-7, 7):                                             # la correa no tapa la placa
        for y in range(73, 76):
            M.put(x, y, z, H, BONE if x not in (-5, -4, -3, 2, 3, 4) or y != 74 else SLIT)
    return {STRAP: 'cuero'}


def bufanda(M, bd):
    """Bufanda larga de punto a rayas, dada una vuelta al cuello y con una punta delante."""
    KNIT = (0.20, 0.42, 0.30); STRIPE = (0.86, 0.82, 0.70)
    b = bd['b'] + (-4 if bd['fem'] else 0)
    slab(M, T, KNIT, 59, 65, 0, 0.5, 17 + b * 0.5, 15 + b * 0.5, 15, 14, ch=2)
    zf = max(z for (x, y, z), v in M.V.items() if v[0] == T and y == 60) + 1
    slab(M, T, KNIT, 40, 59, 3.5, zf - 0.5, 5, 5, 2, 2, ch=0)                        # punta delante
    for (x, y, z), v in M.V.items():
        if v[0] == T and y % 4 == 0: v[1] = STRIPE
    return {KNIT: 'punto', STRIPE: 'punto'}


# cuerpo

def abrigo_nieve(M, bd):
    """Abrigo de nieve acolchado rojo hasta medio muslo, con franjas cosidas y cuello alto."""
    RED = (0.72, 0.18, 0.14); RED_SH = (0.56, 0.12, 0.10); ZIP = (0.20, 0.20, 0.22)
    _torso_cover(M, bd, RED, 38, pad=3.5)
    b = bd['b'] + (0 if not bd['fem'] else -3)
    slab(M, T, RED, 31, 38, 0, 0.3, 29 + b, 28 + b, 18, 17.5, ch=3)
    slab(M, T, RED, 59, 66, 0, 0.3, 17 + b * 0.5, 16 + b * 0.5, 16, 15, ch=3)        # cuello alto
    for (x, y, z), v in M.V.items():
        if v[0] in (T, 'arm_l', 'arm_r', 'fore_l', 'fore_r') and v[1] == RED and y % 5 == 0: v[1] = RED_SH
    for y in range(32, 66):
        z = M.front(0, y)
        if z is not None: M.put(0, y, z, T, ZIP)
    _sleeves(M, bd, RED, RED_SH, pad=3.5)
    for (x, y, z), v in M.V.items():
        if v[0] in ('arm_l', 'arm_r', 'fore_l', 'fore_r') and v[1] == RED and y % 5 == 0: v[1] = RED_SH
    return {RED: 'lona', RED_SH: 'lona'}


def chubasquero(M, bd):
    """Chubasquero amarillo de pescador, largo hasta la rodilla, con botones de asta."""
    YEL = (0.92, 0.74, 0.16); YEL_SH = (0.78, 0.60, 0.10); HORN = (0.24, 0.18, 0.12)
    _torso_cover(M, bd, YEL, 38)
    b = bd['b'] + (0 if not bd['fem'] else -3)
    slab(M, T, YEL, 25, 38, 0, 0.3, 30 + b, 26.5 + b, 18, 15.5, ch=2)
    slab(M, T, YEL_SH, 58, 63, 0, 0.3, 19 + b * 0.5, 17 + b * 0.5, 16.5, 14.5, ch=2)
    for y in (30, 36, 42, 48, 54):
        z = M.front(-1, y)
        if z is not None: M.put(-1, y, z + 1, T, HORN); M.put(0, y, z + 1, T, HORN)
    _sleeves(M, bd, YEL, YEL_SH)
    return {}


def chaleco(M, bd):
    """Chaleco de tweed sin mangas con botones dorados y leontina."""
    TWEED = (0.36, 0.30, 0.24); TWEED_SH = (0.28, 0.23, 0.18); GOLD = (0.86, 0.70, 0.30)
    _torso_cover(M, bd, TWEED, 40, pad=2)
    for (x, y, z), v in M.V.items():
        if v[0] == T and (x + y) % 2 == 0 and v[1] == TWEED: v[1] = TWEED_SH
    for y in (44, 48, 52, 56):
        z = M.front(-1, y)
        if z is not None: M.put(-1, y, z + 1, T, GOLD)
    for x in range(1, 6):                                              # leontina
        z = M.front(x, 47 - abs(x - 3) // 2)
        if z is not None: M.put(x, 47 - abs(x - 3) // 2, z, T, GOLD)
    return {TWEED: 'lana', TWEED_SH: 'lana'}


def vestido(M, bd):
    """Vestido largo de los años 20, verde botella, de talle bajo, con mangas cortas y un
    cinturón de raso; la falda llega a los tobillos."""
    SILK = (0.14, 0.34, 0.26); SILK_SH = (0.10, 0.26, 0.20); SASH = (0.80, 0.70, 0.50)
    _torso_cover(M, bd, SILK, 38, pad=2.5)
    b = bd['b'] + (0 if not bd['fem'] else -3)
    slab(M, T, SILK, 5, 38, 0, 0.3, 33 + b, 26 + b, 22, 15.5, ch=4)
    slab(M, T, SILK_SH, 4, 6, 0, 0.3, 34 + b, 34 + b, 23, 23, ch=4)
    slab(M, T, SASH, 38, 41, 0, 0.3, 27 + b, 27 + b, 16.5, 16.5, ch=2)
    k = 0.85 if bd['slim'] else 1.0
    for s, _, _, arm, _ in cu.sides():                                  # mangas cortas
        cx = (bd['ax'] + bd.get('arm_b', bd['b']) / 2) * s
        slab(M, arm, SILK, 52, 62, cx, 0, 8.5 * k + 2.5, 9 * k + 2.5, 9 * k + 2.5, 9 * k + 2.5, ch=1)
    return {SILK: 'lana', SILK_SH: 'lana'}


def bata(M, bd):
    """Bata blanca de laboratorio hasta la rodilla, abierta, con solapas y bolsillos."""
    WHITE = (0.90, 0.90, 0.88); WHITE_SH = (0.78, 0.78, 0.76)
    _torso_cover(M, bd, WHITE, 38, pad=4)                               # tapa el estetoscopio de Whipple
    b = bd['b'] + (0 if not bd['fem'] else -3)
    slab(M, T, WHITE, 24, 38, 0, 0.3, 30 + b, 26.5 + b, 17.5, 15.5, ch=2)
    for y in range(24, 62):                                            # abertura y solapas
        z = M.front(0, y)
        if z is not None: M.put(-1, y, z, T, WHITE_SH); M.put(0, y, z, T, WHITE_SH)
    for s in (-1, 1):
        for y in range(30, 35):
            z = M.front(int(7 * s), y)
            if z is not None: M.put(int(7 * s), y, z, T, WHITE_SH)
    _sleeves(M, bd, WHITE, WHITE_SH)
    return {WHITE: 'lona', WHITE_SH: 'lona'}


# pies

def botas_esquimales(M, bd):
    """Mukluks de piel de foca con vuelta de pelo y una franja bordada."""
    HIDE = (0.46, 0.36, 0.26); FUR = (0.88, 0.84, 0.76); BEAD_R = (0.72, 0.18, 0.14); BEAD_B = (0.20, 0.36, 0.62)
    _boot(M, bd, HIDE, HIDE, 19, cuff=FUR, pad=2)
    for (x, y, z), v in M.V.items():
        if v[1] == HIDE and y in (8, 9): v[1] = BEAD_R if (x + z) % 2 == 0 else BEAD_B
    return {HIDE: 'cuero', FUR: 'borreguillo'}


def zapatos_tacon(M, bd):
    """Zapatos de tacón de charol rojo con tira y tacón fino atrás."""
    RED = (0.62, 0.08, 0.10); SOLE = (0.08, 0.06, 0.06)
    for s, _, shin, _, _ in cu.sides():
        cx = (4.5 if bd['fem'] else 5) * s
        slab(M, shin, SOLE, 0, 1, cx, 2.5, 9.5, 9.5, 8, 8, ch=1)                     # puntera
        slab(M, shin, RED, 1, 4, cx, 2.0, 9.5, 9, 10, 9, ch=1)
        slab(M, shin, RED, 2, 5, cx, -3.5, 9.5, 9.5, 5, 5, ch=1)                     # talón alzado
        slab(M, shin, SOLE, 0, 2, cx, -5, 2, 2, 2, 2, ch=0)                          # tacón
        slab(M, shin, RED, 5, 6, cx, 0, 10, 10, 11, 11, ch=1)                        # tira
    return {}

GARMENTS = {'bombin': bombin, 'casco_minero': casco_minero, 'gorro_nieve': gorro_nieve, 'chistera': chistera,
            'chaqueta_aviador': chaqueta_aviador, 'abrigo_piel': abrigo_piel,
            'botas_militares': botas_militares, 'botas_nieve': botas_nieve,
            'casco_brodie': casco_brodie, 'cinta_pelo': cinta_pelo, 'sombrero_aventurero': sombrero_aventurero,
            'boina': boina, 'sombrero_vaquero': sombrero_vaquero, 'sombrero_mujer': sombrero_mujer,
            'turbante': turbante, 'sombrero_paja': sombrero_paja,
            'gafas_ver': gafas_ver, 'gafas_nieve': gafas_nieve, 'bufanda': bufanda,
            'abrigo_nieve': abrigo_nieve, 'chubasquero': chubasquero, 'chaleco': chaleco, 'vestido': vestido,
            'bata': bata, 'botas_esquimales': botas_esquimales, 'zapatos_tacon': zapatos_tacon}


def build(name, c):
    bd = body_of(c)
    M = cu.new(9100 + CHARS.index(c))
    fn = GARMENTS[name]
    mats = fn(M, bd, hair_of(c)) if fn is cinta_pelo else fn(M, bd)
    materiales.texturize(M, mats)
    piv, parents = cu.pivots(bd['finish_b'], bd['finish_ax'])
    out = 'models/vest_%s_%s.json' % (name, c)
    return M.export(out, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25, parents=parents)


if __name__ == '__main__':
    for name in (sys.argv[1:] or GARMENTS):
        total = sum(build(name, c) for c in CHARS)
        print(name, total, 'voxels en', len(CHARS), 'personajes')
