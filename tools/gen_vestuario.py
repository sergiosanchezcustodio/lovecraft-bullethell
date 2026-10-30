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
import sys, os, json, math, inspect
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, rslab, T, H
import materiales

CHARS = ['dyer', 'olmstead', 'legrasse', 'johansen', 'peaslee', 'varga', 'whipple', 'blake',
         'iwanicki', 'elwood', 'malone', 'armitage', 'west']


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
    de las orejas y en la mitad de atrás (delante, las cejas, de un solo tono, ganaban al pelo
    con textura), que no sea la piel de la cara."""
    with open('models/%s.json' % c) as f:
        vox = [v for v in json.load(f)['voxels'] if not (len(v) > 8 and v[8] & 64)]   # sin lo tapado por otra parte
    skin, zs = None, -999                  # la piel: el voxel de delante entre las cejas (el último
    for v in vox:                          # de la columna podía ser la melena de la espalda)
        if v[3] == 'head' and v[0] == -1 and v[1] == 76 and v[2] > zs: skin, zs = tuple(v[4:7]), v[2]
    for parts in (('head',), ('head', 'hat')):   # Malone lleva el pelo con el sombrero (moño)
        count = {}
        for v in vox:
            if v[3] not in parts or v[1] < 74 or v[2] >= 0: continue
            col = tuple(v[4:7])
            if skin and sum(abs(a - b) for a, b in zip(col, skin)) < 0.25: continue
            count[col] = count.get(col, 0) + 1
        if count: return max(count, key=count.get)
    return (0.25, 0.18, 0.12)


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


def face_of(c):
    """Dónde tiene los ojos el personaje: la fila de abajo de sus blancos (las caras dibujadas a
    mano del 23-10-2026 no los tienen todas a la misma altura), y los voxels de su cabeza."""
    with open('models/%s.json' % c) as f:
        vox = [v for v in json.load(f)['voxels'] if v[3] == 'head' and not (len(v) > 8 and v[8] & 64)]
    rows = {}
    for v in vox:
        if v[2] >= 3 and sum(abs(a - b) for a, b in zip(v[4:7], cu.EYE_W)) < 0.05: rows[v[1]] = rows.get(v[1], 0) + 1
    # los ojos son filas de pocos blancos (2 a 6): la barba blanca de Armitage, de 8 o más por fila
    # y por debajo, pasaba por ellos y le ponía las gafas en la boca (corregido el 30-10-2026)
    whites = [y for y, n in rows.items() if 2 <= n <= 6 and y >= 66]
    return (min(whites) if whites else 73), {(v[0], v[1], v[2]) for v in vox}


def _front_z(head, x, y):
    zs = [z for (hx, hy, z) in head if hx == x and hy == y]
    return max(zs) if zs else 7


def gafas_ver(M, bd, face):
    """Gafas redondas de montura dorada: dos aros alrededor de los ojos (de 4×2), puente y
    patillas pegadas a los lados de la cabeza. Siguen la cara: cada voxel va justo delante."""
    GOLD = (0.80, 0.64, 0.26)
    y0, head = face
    put = lambda x, y: M.put(x, y, _front_z(head, x, y) + 1, H, GOLD)
    for x0 in (-7, 1):                                                 # aros: 6 de ancho, 4 de alto
        for x in range(x0 + 1, x0 + 5): put(x, y0 - 1); put(x, y0 + 2)
        for y in (y0, y0 + 1): put(x0, y); put(x0 + 5, y)
    put(-1, y0 + 1); put(0, y0 + 1)                                    # puente
    y = y0 + 1
    for s in (-1, 1):                                                  # patillas, por fuera de la cabeza
        ring = _front_z(head, -7 if s < 0 else 6, y) + 1
        for z in range(-2, ring):
            xs = [x for (x, hy, hz) in head if hy == y and hz == z]
            if xs: M.put(min(xs) - 1 if s < 0 else max(xs) + 1, y, z, H, GOLD)
    return {}


def gafas_nieve(M, bd, face):
    """Gafas de nieve inuit: placa de hueso con dos rendijas (a la altura de los ojos) y correa."""
    BONE = (0.84, 0.78, 0.64); SLIT = (0.04, 0.04, 0.05); STRAP = (0.30, 0.20, 0.12)
    w, d = _head_box(bd)
    z = _face_z(bd)
    dy = face[0] - 73                                                  # la placa se hizo para ojos en 73-74
    for x in range(-7, 7):
        for y in range(72, 77):
            if y in (72, 76) and x in (-7, 6): continue
            M.put(x, y + dy, z, H, BONE)
    for x in (-5, -4, -3, 2, 3, 4):
        M.put(x, 74 + dy, z, H, SLIT)
    slab(M, H, STRAP, 73 + dy, 76 + dy, 0, 0.0, w + 1.2, w + 1.2, d + 1.2, d + 1.2, ch=3)
    for x in range(-7, 7):                                             # la correa no tapa la placa
        for y in range(73, 76):
            M.put(x, y + dy, z, H, BONE if x not in (-5, -4, -3, 2, 3, 4) or y != 74 else SLIT)
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

# ------------------------------------------------------------------ fase 14: cabeza (30-10-2026)

def _speck(x, y, z, n):
    """Ruido fijo para manchas sueltas (verdín, lunares): verdadero en 1 de cada n voxels."""
    return ((x * 73856093) ^ (y * 19349663) ^ (z * 83492791)) % n == 0


def _hair_cap(M, bd, hair):
    """Coronilla del color del pelo, para lo que no cubre la cabeza entera (como cinta_pelo): bajo
    un sombrero del personaje oculto no siempre hay pelo."""
    w, d = _head_box(bd)
    rslab(M, H, hair, 76, 84, 0, 0.0, w + 1, d + 1, r=4, rt=4, rb=0)


def _front_at(M, x, y, part=H):
    zs = [z for (vx, vy, z), v in M.V.items() if vx == x and vy == y and v[0] == part]
    return max(zs) if zs else None


def gorra_marinero(M, bd):
    """Gorra de lana azul marino de los pescadores de Innsmouth, ceñida, con visera corta de hule
    y manchas de verdín del salitre."""
    WOOL = (0.14, 0.18, 0.30); WOOL_SH = (0.10, 0.13, 0.22); PEAK = (0.06, 0.06, 0.07); MOSS = (0.32, 0.42, 0.24)
    w, d = _head_box(bd)
    slab(M, H, WOOL_SH, 76, 79, 0, 0.3, w + 1.6, w + 1.6, d + 1.6, d + 1.6, ch=3)
    rslab(M, H, WOOL, 79, 85, 0, 0.0, w + 2.5, d + 2.5, r=4.5, rt=3, rb=0)
    zf = int(round(0.3 + (d + 1.6) / 2))
    slab(M, H, PEAK, 76, 78, 0, zf + 2, w - 2, w - 3, 4, 4, ch=1)
    for (x, y, z), v in M.V.items():
        if v[1] in (WOOL, WOOL_SH) and _speck(x, y, z, 9 if y < 80 else 17): v[1] = MOSS
    return {WOOL: 'lana', WOOL_SH: 'lana'}


def fez(M, bd):
    """Fez granate de la Orden Esotérica de Dagon, con el signo dorado delante y borla negra."""
    RED = (0.50, 0.08, 0.10); RED_SH = (0.40, 0.06, 0.08); BLACK = (0.06, 0.05, 0.05); GOLD = (0.88, 0.70, 0.28)
    w, d = _head_box(bd)
    slab(M, H, RED, 77, 89, 0, 0.0, w + 1, w - 3, d + 1, d - 3, ch=3)
    slab(M, H, RED_SH, 77, 79, 0, 0.0, w + 1.4, w + 1.4, d + 1.4, d + 1.4, ch=3)
    for x in range(0, int(w / 2) - 1):                                   # cordón por arriba...
        M.put(x, 89, 0, H, BLACK)
    xs = int(w / 2) - 1
    for y in range(83, 89):                                              # ...que cae por el lado
        M.put(xs, y, 0, H, BLACK)
    for y in range(80, 84):                                              # borla
        for x in (xs - 1, xs, xs + 1):
            for z in (-1, 0, 1):
                if y == 80 and abs(z) + abs(x - xs) > 1: continue
                M.put(x, y, z, H, BLACK)
    for x, y in ((-1, 84), (0, 84), (-2, 83), (1, 83), (-1, 82), (0, 82), (-1, 81), (0, 81)):   # el signo de la Orden
        z = _front_at(M, x, y)
        if z is not None: M.put(x, y, z + 1, H, GOLD)
    return {RED: 'lana', RED_SH: 'lana'}


def capucha_cultista(M, bd, face):
    """Capucha negra de cultista con la cara en sombra: solo se ven dos ojos que brillan.
    Cae sobre los hombros como una esclavina corta."""
    CLOTH = (0.13, 0.11, 0.13); CLOTH_SH = (0.08, 0.07, 0.08); SHADOW = (0.012, 0.010, 0.012)
    EYE = (0.95, 0.72, 0.28)
    w, d = _head_box(bd)
    rslab(M, H, CLOTH, 62, 90, 0, -1.0, w + 5, d + 5, r=6, rt=8, rb=0)
    rslab(M, H, CLOTH, 84, 94, 0, -6.0, 6, 6, r=2.5, rt=3, rb=0)           # pico de la capucha, atrás
    y0 = face[0]
    zf = max(z for (x, y, z), v in M.V.items() if v[0] == H and y == y0)
    for (x, y, z) in list(M.V):                                          # abertura de la cara
        if M.V[(x, y, z)][0] == H and -6 <= x <= 5 and 65 <= y <= 80 and z >= zf - 1:
            if (x in (-6, 5) or y in (65, 80)) and (x, y) not in ((-6, 65), (5, 65), (-6, 80), (5, 80)): continue
            M.V.pop((x, y, z))
    head = face[1]
    hole = lambda x, y, z: -6 <= x <= 5 and 65 <= y <= 80 and z >= zf - 1
    for (x, y, z) in head:                                               # lo que asoma (melena, lazos):
        if y < 56: continue                                              # una capa de tela por encima
        for n in ((x + 1, y, z), (x - 1, y, z), (x, y + 1, z), (x, y, z + 1), (x, y, z - 1)):
            if n not in head and n not in M.V and not hole(*n): M.put(n[0], n[1], n[2], H, CLOTH)
    zt = max(_front_z(head, x, y) for x in range(-6, 6) for y in range(65, 81)) + 1
    for x in range(-6, 6):                                               # la sombra de dentro, delante de la cara:
        for y in range(65, 81):                                          # maciza, o el flequillo asomaba por
            for z in range(_front_z(head, x, y) + 1, zt + 1):            # los escalones
                M.put(x, y, z, H, SHADOW)
    for x in (-5, -4, 3, 4):
        M.put(x, y0, zt + 1, H, EYE, 1)
    b = bd['b'] + (-4 if bd['fem'] else 0)
    slab(M, T, CLOTH_SH, 55, 63, 0, -0.5, 24 + b, 18 + b * 0.5, 17, 15, ch=3)   # esclavina sobre los hombros
    for (x, y, z), v in M.V.items():
        if v[1] == CLOTH and (x + 2 * y) % 7 == 0: v[1] = CLOTH_SH
    return {CLOTH: 'lana', CLOTH_SH: 'lana'}


def tiara(M, bd, hair):
    """Tiara de oro de Innsmouth, la de las joyas raras de los Marsh: un aro con una placa alta
    delante, de picos y volutas como olas, con perlas y una piedra verde que brilla."""
    GOLD = (0.86, 0.68, 0.26); GOLD_SH = (0.62, 0.46, 0.14); PEARL = (0.93, 0.91, 0.85); GEM = (0.30, 0.78, 0.66)
    w, d = _head_box(bd)
    _hair_cap(M, bd, hair)
    slab(M, H, GOLD_SH, 77, 79, 0, 0.3, w + 1.6, w + 1.6, d + 1.6, d + 1.6, ch=3)
    for x in range(-7, 7):
        z = _front_at(M, x, 78)
        if z is None: continue
        top = 80 + max(0, 6 - int(abs(x + 0.5) * 0.9)) + (1 if x % 3 == 0 else 0)
        for y in range(79, top):
            M.put(x, y, z, H, GOLD if (x + y) % 4 else GOLD_SH)
            if y < top - 1: M.put(x, y, z - 1, H, GOLD_SH)
    for x in (-5, 4):                                                     # perlas
        z = _front_at(M, x, 80)
        if z is not None: M.put(x, 80, z + 1, H, PEARL)
    for x, y in ((-1, 82), (0, 82), (-1, 83), (0, 83)):
        z = _front_at(M, x, y)
        if z is not None: M.put(x, y, z + 1, H, GEM, 1)
    return {hair: 'pelo'}


def gorra_chofer(M, bd):
    """Gorra de chófer negra, de plato, con visera de charol y una insignia dorada."""
    BLACK = (0.13, 0.14, 0.20); BAND = (0.06, 0.06, 0.07); PEAK = (0.03, 0.03, 0.035); BADGE = (0.86, 0.70, 0.32)
    w, d = _head_box(bd)
    slab(M, H, BAND, 77, 80, 0, 0.3, w + 1.6, w + 1.6, d + 1.6, d + 1.6, ch=3)
    slab(M, H, BLACK, 80, 84, 0, 0.0, w + 2, w + 4, d + 2, d + 4, ch=4)
    slab(M, H, BLACK, 84, 85, 0, 0.0, w + 4, w + 3, d + 4, d + 3, ch=4)
    zf = int(round(0.3 + (d + 1.6) / 2))
    slab(M, H, PEAK, 77, 78, 0, zf + 2.5, w - 1, w - 1, 5, 5, ch=2)
    for x, y in ((-1, 81), (0, 81), (-1, 82), (0, 82)):
        z = _front_at(M, x, y)
        if z is not None: M.put(x, y, z + 1, H, BADGE)
    return {BLACK: 'lana'}


def sombrero_hule(M, bd):
    """Sombrero de hule amarillo de pescador (sueste): copa redonda y ala que cae, larga detrás."""
    YEL = (0.90, 0.72, 0.16); YEL_SH = (0.74, 0.56, 0.10); STRAP = (0.20, 0.14, 0.08)
    w, d = _head_box(bd)
    rslab(M, H, YEL, 77, 85, 0, -0.5, w + 2, d + 2, r=6, rt=6, rb=0)       # copa baja y redonda
    for i, y in enumerate((77, 76, 75)):                                 # ala que cae, corta delante
        slab(M, H, YEL_SH, y, y + 1, 0, -1.5 - i * 0.5, w + 6 + i * 1.5, w + 6 + i * 1.5, d + 6 + i * 2, d + 6 + i * 2, ch=4)
    for (x, y, z) in list(M.V):
        if y < 77 and z > 4: M.V.pop((x, y, z))                          # delante no tapa los ojos
    slab(M, H, YEL_SH, 70, 75, 0, -(d / 2 + 4.5), w + 6, w + 7, 2, 2, ch=1)   # el faldón de atrás
    for (x, y, z), v in M.V.items():
        if v[1] == YEL and y == 80: v[1] = YEL_SH                          # pespunte
    for s in (-1, 1):                                                    # barboquejo
        for y in range(66, 76):
            M.put(int(s * (w / 2 + 1.5)) - (1 if s < 0 else 0), y, 1, H, STRAP)
    return {}


def casco_aviador(M, bd):
    """Casco de aviador de cuero con orejeras y las gafas subidas a la frente, como los pilotos
    de la expedición de la Miskatonic."""
    LEATHER = (0.36, 0.22, 0.12); LEATHER_SH = (0.27, 0.16, 0.08); FUR = (0.84, 0.78, 0.64)
    BRASS = (0.76, 0.60, 0.26); GLASS = (0.34, 0.54, 0.62); STRAP = (0.14, 0.10, 0.07)
    w, d = _head_box(bd)
    rslab(M, H, LEATHER, 77, 87, 0, -0.3, w + 2, d + 2, r=5, rt=5, rb=0)
    slab(M, H, LEATHER, 69, 77, 0, -(d / 2 + 0.2), w + 2, w + 2, 3, 3, ch=1)   # nuca
    for s in (-1, 1):                                                     # orejeras con borreguillo
        slab(M, H, FUR, 67, 78, s * (w / 2 + 0.7), 0.2, 2, 2, 8, 8, ch=1)
        slab(M, H, LEATHER, 66, 78, s * (w / 2 + 1.7), 0.2, 1.5, 1.5, 8, 8, ch=1)
    for (x, y, z), v in M.V.items():
        if v[1] == LEATHER and x in (-1, 0) and y > 80: v[1] = LEATHER_SH   # costura del centro
    slab(M, H, STRAP, 80, 82, 0, -0.3, w + 2.6, w + 2.6, d + 2.6, d + 2.6, ch=3)   # correa de las gafas
    for x0 in (-7, 1):
        for x in range(x0, x0 + 6):
            for y in range(79, 84):
                z = _front_at(M, x, y)
                if z is None: continue
                edge = x in (x0, x0 + 5) or y in (79, 83)
                M.put(x, y, z + 1, H, BRASS if edge else GLASS, 0 if edge else 0)
    return {LEATHER: 'cuero', LEATHER_SH: 'cuero', FUR: 'borreguillo'}


def birrete(M, bd):
    """Birrete negro de catedrático de la Miskatonic: casquete, tabla cuadrada y borla dorada."""
    BLACK = (0.07, 0.07, 0.08); BOARD = (0.10, 0.10, 0.11); GOLD = (0.86, 0.70, 0.26)
    w, d = _head_box(bd)
    slab(M, H, BLACK, 77, 82, 0, 0.3, w + 1.5, w + 1.5, d + 1.5, d + 1.5, ch=3)
    slab(M, H, BOARD, 82, 83, 0, 0.3, w + 9, w + 9, w + 9, w + 9, ch=0)
    M.put(-1, 83, 0, H, GOLD); M.put(0, 83, 0, H, GOLD)
    e = int((w + 9) / 2)
    for i in range(1, e):                                                 # cordón hasta la esquina
        M.put(i, 83, int(i * 0.9), H, GOLD)
    for y in range(76, 83):                                               # borla que cuelga
        M.put(e, y, e - 1, H, GOLD)
        if y < 79: M.put(e, y, e - 2, H, GOLD); M.put(e - 1, y, e - 1, H, GOLD)
    return {BLACK: 'lana', BOARD: 'lana'}


def panuelo_gitana(M, bd):
    """Pañuelo de gitana rojo con lunares, anudado en la nuca con las puntas sueltas, y aros de oro."""
    RED = (0.66, 0.12, 0.12); RED_SH = (0.52, 0.08, 0.08); DOT = (0.94, 0.80, 0.34); GOLD = (0.86, 0.70, 0.28)
    w, d = _head_box(bd)
    rslab(M, H, RED, 72, 87, 0, -0.8, w + 2, d + 2.5, r=5, rt=5, rb=0)
    for (x, y, z) in list(M.V):                                          # la cara, al aire
        if y < 79 and z >= 1: M.V.pop((x, y, z))
    zb = -int(round(0.8 + (d + 2.5) / 2))
    rslab(M, H, RED_SH, 73, 78, 0, zb - 0.5, 6, 3, r=1.5, rt=1.5, rb=1.5)   # el nudo
    for s in (-1, 1):                                                    # las puntas
        for i, y in enumerate(range(73, 63, -1)):
            for k in (0, 1):
                M.put(s * (1 + k + i // 4), y, zb - 1, H, RED)
    for (x, y, z), v in M.V.items():
        if v[1] == RED and (x * 7 + y * 3 + z * 5) % 11 == 0: v[1] = DOT
    for s in (-1, 1):                                                    # aros
        xo = int(w / 2) + 1 if s > 0 else -int(w / 2) - 2
        for y, dz in ((70, 0), (69, -1), (69, 1), (68, 0)):
            M.put(xo, y, dz, H, GOLD)
    return {RED: 'lana', RED_SH: 'lana'}


def corona_algas(M, bd, hair):
    """Corona de algas y conchas, como la de los que vuelven del mar: un aro de algas con
    conchas y una estrella de mar delante, y tiras que cuelgan por los lados y la nuca."""
    KELP = (0.26, 0.32, 0.12); KELP_D = (0.17, 0.23, 0.08); SHELL = (0.93, 0.86, 0.78)
    SHELL_P = (0.88, 0.62, 0.58); STAR = (0.88, 0.42, 0.20)
    w, d = _head_box(bd)
    _hair_cap(M, bd, hair)
    slab(M, H, KELP, 77, 80, 0, 0.3, w + 1.8, w + 1.8, d + 1.8, d + 1.8, ch=3)
    ring = [(x, z) for (x, y, z), v in M.V.items() if y == 77 and v[1] == KELP]
    rs = set(ring)
    zf = max(z for x, z in ring)
    for x, z in ring:
        outer = any((x + dx, z + dz) not in rs for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if not outer or z > zf - 4: continue                             # no tapa la cara
        n = 3 + ((x * 31 + z * 17) % 7)
        for y in range(77 - n, 77): M.put(x, y, z, H, KELP if y % 2 else KELP_D)
    for x, z in ring:                                                   # frondas hacia arriba
        if (x * 13 + z * 7) % 9 == 0:
            for y in range(80, 83 + (x + z) % 3): M.put(x, y, z, H, KELP_D)
    for x0, col in ((-6, SHELL), (-2, SHELL_P), (3, SHELL)):
        for x in (x0, x0 + 1):
            for y in (79, 80):
                z = _front_at(M, x, y)
                if z is not None: M.put(x, y, z + 1, H, col)
    xs = int(w / 2)
    for y, z in ((79, 2), (80, 1), (80, 3), (81, 2), (78, 2)):           # estrella de mar, al lado
        M.put(xs + 1, y, z, H, STAR)
    return {hair: 'pelo'}


def fedora_ganster(M, bd):
    """Fedora gris perla de gánster de Chicago, con cinta negra ancha y la copa pellizcada."""
    GREY = (0.70, 0.70, 0.68); GREY_SH = (0.58, 0.58, 0.56); BAND = (0.06, 0.06, 0.07)
    w, d = _head_box(bd)
    slab(M, H, GREY_SH, 77, 78, 0, 0.5, w + 8, w + 8, d + 6, d + 6, ch=4)
    slab(M, H, BAND, 78, 81, 0, 0.3, w + 1.4, w + 1.4, d + 1.4, d + 1.4, ch=3)
    slab(M, H, GREY, 81, 87, 0, 0.3, w + 1, w - 1.5, d + 1, d - 1.5, ch=3)
    for z in range(-4, 5):                                              # hundido de la copa
        for x in (-1, 0):
            M.V.pop((x, 86, z), None)
    for x in (-3, 2):                                                   # pellizco delante
        for y in (84, 85, 86):
            z = _front_at(M, x, y)
            if z is not None: M.V.pop((x, y, z), None)
    return {GREY: 'lana', GREY_SH: 'lana'}


def gorro_dormir(M, bd):
    """Gorro de dormir de rayas blancas y azules, largo, con la punta caída y una borla."""
    WHITE = (0.90, 0.88, 0.82); STRIPE = (0.30, 0.40, 0.66); POM = (0.95, 0.93, 0.88)
    w, d = _head_box(bd)
    slab(M, H, WHITE, 76, 79, 0, 0.3, w + 1.6, w + 1.6, d + 1.6, d + 1.6, ch=3)
    top = 0
    for i, y in enumerate(range(79, 91)):                               # cono que se tuerce
        k = w + 1 - i * 1.15
        if k < 3: break
        cx = i * i * 0.05
        slab(M, H, WHITE, y, y + 1, cx, 0.0, k, k, k - 1, k - 1, ch=2 if k > 6 else 0)
        top = y
    xt = int(round((top - 79) ** 2 * 0.05)) + 2
    for y in range(top - 6, top + 1):                                   # la punta cae por el lado
        for x in (xt, xt + 1):
            for z in (-1, 0):
                M.put(x, y, z, H, WHITE)
    for (x, y, z), v in M.V.items():
        if v[1] == WHITE and y % 4 == 0: v[1] = STRIPE
    rslab(M, H, POM, top - 10, top - 6, xt + 0.5, -0.5, 4, 4, r=1.5, rt=1.5, rb=1.5)
    return {WHITE: 'punto', STRIPE: 'punto', POM: 'borreguillo'}


def casco_buzo(M, bd):
    """Casco de buzo de cobre y latón: cúpula que tapa la cabeza entera, ventana redonda
    delante y dos pequeñas a los lados, válvula arriba y peto atornillado sobre los hombros."""
    COPPER = (0.68, 0.40, 0.20); COPPER_SH = (0.54, 0.30, 0.14); BRASS = (0.80, 0.62, 0.28)
    GLASS = (0.14, 0.26, 0.30); GLINT = (0.70, 0.86, 0.90); BOLT = (0.34, 0.28, 0.20)
    w, d = _head_box(bd)
    rslab(M, H, COPPER, 61, 91, 0, -0.5, w + 9, d + 9, r=8, rt=9, rb=3)
    def window(cx, cy, r, axis):
        for a in range(-int(r) - 2, int(r) + 3):
            for b in range(-int(r) - 2, int(r) + 3):
                q = math.hypot(a + 0.5, b + 0.5)
                if q > r + 1.6: continue
                if axis == 'z':
                    x, y = cx + a, cy + b
                    z = _front_at(M, x, y)
                    if z is None: continue
                    if q <= r: M.put(x, y, z, 'glass', GLINT if (a, b) in ((-3, 2), (-2, 3), (-3, 3)) else GLASS)
                    else: M.put(x, y, z + 1, H, BRASS)
                else:
                    y, z = cy + a, b
                    xs = [vx for (vx, vy, vz), v in M.V.items() if vy == y and vz == z and v[0] == H]
                    if not xs: continue
                    x = max(xs) if axis > 0 else min(xs)
                    if q <= r: M.put(x, y, z, 'glass', GLASS)
                    else: M.put(x + (1 if axis > 0 else -1), y, z, H, BRASS)
    window(-1, 75, 5.2, 'z')
    window(None, 75, 2.6, 1)
    window(None, 75, 2.6, -1)
    rslab(M, H, BRASS, 91, 94, 0, -1, 4, 4, r=1.5, rt=1, rb=0)          # válvula
    b = bd['b'] + (-3 if bd['fem'] else 0)
    slab(M, T, BRASS, 53, 63, 0, 0.0, 31 + b, 27 + b, 20, 18, ch=4)       # peto
    for (x, y, z), v in M.V.items():
        if v[0] == T and v[1] == BRASS and y == 55 and x % 4 == 0: v[1] = BOLT
        if v[0] == H and v[1] == COPPER and (y + x) % 9 == 0: v[1] = COPPER_SH
    M.marks = {'bubbles': [0, 95, -1]}                                  # de la válvula salen burbujas al vadear
    M.extra_parents = {'glass': 'head'}                                 # el cristal, aparte: se empaña (Player)
    return {}


# ------------------------------------------------------------------ fase 14: cuerpo (30-10-2026)

def _bb(bd, fem_off=-3):
    """Ancho extra del tronco de este personaje para faldones (como en el abrigo de piel)."""
    return bd['b'] + (fem_off if bd['fem'] else 0)


def _skirt(M, bd, col, y0, flare=4.0, pad=0.0):
    """Faldón que cae de la cadera (y 38) hasta y0, abriéndose `flare` hacia abajo; por debajo de
    la cadera build() lo pasa a la parte `skirt` (se mueve con retraso)."""
    b = _bb(bd)
    slab(M, T, col, y0, 38, 0, 0.3, 27 + b + flare + pad, 26 + b + pad, 16 + flare * 0.8 + pad, 15 + pad, ch=3)


def _leg_cover(M, bd, col, bottom=5, pad=2.0, top=41):
    """Perneras encima de las del personaje, desde `bottom` hasta la cadera. Con manga larga en
    la misma prenda, `top=40`: la manga pisa la pernera en la fila de la cadera y, como un voxel
    solo guarda una pieza debajo, el tronco de esa fila se perdía (hueco en el costado)."""
    for s, leg, shin, _, _ in cu.sides():
        cx = (4.5 if bd['fem'] else 5) * s
        slab(M, shin, col, bottom, 27, cx, 0, 9 + pad, 9 + pad, 10 + pad, 9.5 + pad, ch=1)
        slab(M, leg, col, 27, top, cx * 1.04, 0, 9 + pad, 11 + pad, 9 + pad, 10.5 + pad, ch=1)


def _front_line(M, x, y0, y1, col, part=T, dz=0):
    for y in range(y0, y1):
        z = M.front(x, y)
        if z is not None and M.V[(x, y, z)][0] == part: M.put(x, y, z + dz, part, col)


def gabardina(M, bd):
    """Gabardina beis de detective hasta la rodilla: cruzada, con cinturón anudado, charreteras,
    solapas anchas y trabillas en los puños."""
    TAN = (0.70, 0.58, 0.40); TAN_SH = (0.56, 0.45, 0.30); BTN = (0.24, 0.17, 0.10)
    _torso_cover(M, bd, TAN, 38, pad=3)
    _skirt(M, bd, TAN, 20, flare=4, pad=1)
    b = _bb(bd)
    slab(M, T, TAN_SH, 42, 45, 0, 0.3, 27 + b, 27 + b, 17.5, 17.5, ch=3)     # cinturón
    for y in (43, 44):
        z = M.front(3, y)
        if z is not None: M.put(3, y, z + 1, T, BTN); M.put(4, y, z + 1, T, BTN)
    for y in range(26, 42): _front_line(M, 1, y, y + 1, TAN_SH)            # cruce
    for y in (48, 53, 58):
        for x in (-4, 4):
            z = M.front(x, y)
            if z is not None: M.put(x, y, z + 1, T, BTN)
    for s in (-1, 1):                                                     # solapas
        for y in range(52, 62):
            x = int(s * (2 + (61 - y) * 0.35))
            z = M.front(x, y)
            if z is not None: M.put(x, y, z, T, TAN_SH); M.put(x + s, y, z, T, TAN_SH)
    _sleeves(M, bd, TAN, TAN_SH, pad=3)
    k = 0.85 if bd['slim'] else 1.0
    for s, _, _, arm, _ in cu.sides():                                   # charreteras
        cx = (bd['ax'] + bd.get('arm_b', bd['b']) / 2) * s
        slab(M, arm, TAN_SH, 61, 63, cx, 0, 7 * k + 3, 7 * k + 3, 4, 4, ch=0)
    return {TAN: 'lona', TAN_SH: 'lona'}


def tunica_cultista(M, bd):
    """Túnica negra de cultista hasta los pies, con ribete rojo, mangas anchas y el signo bordado
    en el pecho."""
    BLACK = (0.10, 0.09, 0.10); BLACK_SH = (0.07, 0.06, 0.07); RED = (0.55, 0.08, 0.08); GOLD = (0.80, 0.62, 0.26)
    _torso_cover(M, bd, BLACK, 38, pad=3)
    _skirt(M, bd, BLACK, 2, flare=6, pad=1)
    for (x, y, z), v in M.V.items():
        if v[1] == BLACK and y in (2, 3): v[1] = RED                       # ribete del bajo
    for y in range(3, 62): _front_line(M, 0, y, y + 1, RED); _front_line(M, -1, y, y + 1, RED)
    _sleeves(M, bd, BLACK, RED, pad=4.5, bottom=34)
    for x, y in ((-4, 54), (-3, 55), (-3, 53), (-2, 54), (2, 54), (3, 55), (3, 53), (4, 54), (-1, 56), (0, 56),
                 (-1, 52), (0, 52)):                                     # el signo
        z = M.front(x, y)
        if z is not None: M.put(x, y, z + 1, T, GOLD)
    for (x, y, z), v in M.V.items():
        if v[1] == BLACK and (x + y * 2) % 9 == 0: v[1] = BLACK_SH
    return {BLACK: 'lana', BLACK_SH: 'lana'}


def traje_buzo(M, bd):
    """Traje de buzo de lona engomada, entero, con puños de goma y el cinturón de plomos."""
    CANVAS = (0.56, 0.50, 0.40); CANVAS_SH = (0.44, 0.39, 0.30); RUBBER = (0.10, 0.09, 0.08)
    LEAD = (0.36, 0.37, 0.39); LEATHER = (0.30, 0.20, 0.12)
    _torso_cover(M, bd, CANVAS, 36, pad=3.5)
    _leg_cover(M, bd, CANVAS, bottom=6, pad=2.5)
    _sleeves(M, bd, CANVAS, RUBBER, pad=3.5)
    b = _bb(bd)
    slab(M, T, LEATHER, 39, 42, 0, 0.3, 29 + b, 29 + b, 18.5, 18.5, ch=3)
    for x0 in (-11, -6, 3, 8):                                           # plomos
        for x in (x0, x0 + 1, x0 + 2):
            for y in range(38, 44):
                z = M.front(x, y)
                if z is not None: M.put(x, y, z + 1, T, LEAD)
    for (x, y, z), v in M.V.items():
        if v[1] == CANVAS and _speck(x, y, z, 7): v[1] = CANVAS_SH
    return {CANVAS: 'lona', CANVAS_SH: 'lona', LEATHER: 'cuero'}


def uniforme_enfermera(M, bd):
    """Uniforme de enfermera del hospital de Arkham: vestido azul claro hasta media pierna,
    delantal blanco con peto y la cruz roja, y puños blancos."""
    BLUE = (0.52, 0.64, 0.78); BLUE_SH = (0.42, 0.53, 0.66); WHITE = (0.94, 0.93, 0.90); RED = (0.72, 0.10, 0.10)
    _torso_cover(M, bd, BLUE, 38, pad=2.5)
    _skirt(M, bd, BLUE, 12, flare=4)
    k = 0.85 if bd['slim'] else 1.0
    for s, _, _, arm, _ in cu.sides():                                   # mangas cortas con puño blanco
        cx = (bd['ax'] + bd.get('arm_b', bd['b']) / 2) * s
        slab(M, arm, BLUE, 52, 62, cx, 0, 8.5 * k + 2.5, 9 * k + 2.5, 9 * k + 2.5, 9 * k + 2.5, ch=1)
        slab(M, arm, WHITE, 51, 53, cx, 0, 9 * k + 3, 9 * k + 3, 9.5 * k + 3, 9.5 * k + 3, ch=1)
    for x in range(-6, 6):                                               # delantal y peto
        for y in range(14, 58):
            if y > 44 and abs(x + 0.5) > 4.5: continue
            z = M.front(x, y)
            if z is not None and M.V[(x, y, z)][0] == T: M.put(x, y, z + 1, T, WHITE)
    for x, y in ((-1, 50), (0, 50), (-1, 51), (0, 51), (-1, 49), (0, 49), (-2, 50), (1, 50), (-1, 52), (0, 52)):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z, T, RED)
    for (x, y, z), v in M.V.items():
        if v[1] == BLUE and y % 6 == 0: v[1] = BLUE_SH
    return {BLUE: 'lona', BLUE_SH: 'lona', WHITE: 'lona'}


def mono_mecanico(M, bd):
    """Mono de mecánico azul, entero, con cremallera, bolsillos y manchas de grasa."""
    BLUE = (0.20, 0.30, 0.48); BLUE_SH = (0.15, 0.23, 0.38); GREASE = (0.07, 0.07, 0.06); ZIP = (0.62, 0.60, 0.54)
    _torso_cover(M, bd, BLUE, 36, pad=2.5)
    _leg_cover(M, bd, BLUE, bottom=7, pad=2, top=40)
    _sleeves(M, bd, BLUE, BLUE_SH, pad=2.5)
    for y in range(38, 61): _front_line(M, 0, y, y + 1, ZIP)
    for s in (-1, 1):                                                    # bolsillos del pecho
        for x in range(int(3 * s), int(7 * s), s):
            for y in (52, 53, 54, 55):
                z = M.front(x, y)
                if z is not None: M.put(x, y, z, T, BLUE_SH)
    for (x, y, z), v in M.V.items():
        if v[1] in (BLUE, BLUE_SH) and (_speck(x // 2, y // 2, z // 2, 41) or (y < 24 and _speck(x // 2, y // 2, z // 2, 13))): v[1] = GREASE
    return {BLUE: 'lona', BLUE_SH: 'lona'}


def esmoquin(M, bd):
    """Esmoquin negro con solapas de raso, camisa blanca de pechera y pajarita."""
    BLACK = (0.07, 0.07, 0.08); SATIN = (0.16, 0.16, 0.18); WHITE = (0.94, 0.93, 0.90); STUD = (0.20, 0.20, 0.22)
    _torso_cover(M, bd, BLACK, 34, pad=2.5)
    for y in range(46, 62):                                              # pechera en uve
        half = max(0, int((y - 46) * 0.42))
        for x in range(-half - 1, half + 1):
            z = M.front(x, y)
            if z is not None: M.put(x, y, z, T, WHITE)
        for s in (-1, 1):                                                # solapas
            x = (half + 1) * s if s > 0 else -half - 2
            for dx in (0, s):
                z = M.front(x + dx, y)
                if z is not None and y > 47: M.put(x + dx, y, z, T, SATIN)
    for y in (50, 54):
        z = M.front(-1, y)
        if z is not None: M.put(-1, y, z + 1, T, STUD)
    for x in range(-4, 4):                                               # pajarita
        for y in (60, 61):
            if x in (-1, 0) or abs(x + 0.5) > 1.2:
                z = M.front(x, y)
                if z is not None: M.put(x, y, z + 1, T, BLACK)
    _sleeves(M, bd, BLACK, WHITE, pad=2.5)
    return {}


def vestido_charleston(M, bd):
    """Vestido de charlestón dorado de talle bajo hasta la rodilla, con flecos en filas,
    lentejuelas que brillan y un collar largo de perlas."""
    GOLD = (0.80, 0.66, 0.36); GOLD_SH = (0.62, 0.48, 0.24); SEQ = (1.0, 0.92, 0.66); PEARL = (0.94, 0.92, 0.86)
    _torso_cover(M, bd, GOLD, 38, pad=2.5)
    _skirt(M, bd, GOLD, 21, flare=3)
    for (x, y, z), v in M.V.items():
        if v[1] != GOLD: continue
        if y < 38 and (y - 21) % 5 in (0, 1) and (x + z) % 2 == 0: v[1] = GOLD_SH   # filas de flecos
        elif _speck(x, y, z, 13): v[1] = SEQ
    for y in range(21, 25):                                              # flecos sueltos del bajo
        for (x, yy, z) in list(M.V):
            if yy == 25 and (x + z) % 2 == 0: M.put(x, y, z, T, GOLD_SH)
    k = 0.85 if bd['slim'] else 1.0
    for s, _, _, arm, _ in cu.sides():
        cx = (bd['ax'] + bd.get('arm_b', bd['b']) / 2) * s
        slab(M, arm, GOLD, 55, 62, cx, 0, 8.5 * k + 2.5, 9 * k + 2.5, 9 * k + 2.5, 9 * k + 2.5, ch=1)
    for y in range(44, 61):                                              # collar de perlas en uve
        x = int((y - 44) * 0.35)
        for xx in (x, -x - 1):
            z = M.front(xx, y)
            if z is not None and y % 2 == 0: M.put(xx, y, z + 1, T, PEARL)
    return {GOLD: 'lana', GOLD_SH: 'lana'}


def jersey_marinero(M, bd):
    """Jersey de marinero de rayas azul marino y crudo, de cuello alto."""
    NAVY = (0.14, 0.18, 0.34); CREAM = (0.86, 0.82, 0.70)
    _torso_cover(M, bd, CREAM, 38, pad=2)
    b = _bb(bd)
    slab(M, T, CREAM, 59, 66, 0, 0.3, 16 + b * 0.5, 15 + b * 0.5, 15, 14, ch=2)   # cuello vuelto
    _sleeves(M, bd, CREAM, NAVY, pad=2)
    for (x, y, z), v in M.V.items():
        if v[1] == CREAM and y < 59 and y % 4 in (0, 1): v[1] = NAVY
    return {NAVY: 'punto', CREAM: 'punto'}


def parka_inuit(M, bd):
    """Parka inuit de piel de caribú hasta medio muslo, con bandas bordadas, ribete de piel y
    la capucha caída a la espalda."""
    HIDE = (0.58, 0.44, 0.28); HIDE_SH = (0.46, 0.34, 0.20); FUR = (0.90, 0.86, 0.78)
    RED = (0.70, 0.16, 0.12); BLUE = (0.18, 0.32, 0.58)
    _torso_cover(M, bd, HIDE, 38, pad=3.5)
    _skirt(M, bd, HIDE, 28, flare=3, pad=1.5)
    b = _bb(bd)
    slab(M, T, FUR, 26, 29, 0, 0.3, 32 + b, 32 + b, 21, 21, ch=3)          # ribete del bajo
    for (x, y, z), v in M.V.items():
        if v[1] == HIDE and y in (50, 51, 52): v[1] = RED if (x + z) % 4 < 2 else BLUE   # banda bordada
        if v[1] == HIDE and y in (31, 32): v[1] = BLUE if (x + z) % 4 < 2 else RED
    slab(M, T, FUR, 59, 64, 0, -4.0, 20 + b * 0.5, 18 + b * 0.5, 9, 9, ch=3)   # capucha caída
    slab(M, T, HIDE_SH, 52, 60, 0, -9.5, 16 + b * 0.5, 18 + b * 0.5, 4, 5, ch=2)
    _sleeves(M, bd, HIDE, FUR, pad=3.5)
    return {HIDE: 'cuero', HIDE_SH: 'cuero', FUR: 'borreguillo'}


def sotana_exorcista(M, bd):
    """Sotana negra hasta los pies con roquete blanco de encaje encima y la estola morada con
    cruces doradas, la del exorcista."""
    BLACK = (0.08, 0.08, 0.09); WHITE = (0.92, 0.91, 0.88); LACE = (0.80, 0.79, 0.76)
    PURPLE = (0.40, 0.14, 0.46); GOLD = (0.84, 0.68, 0.28)
    _torso_cover(M, bd, WHITE, 38, pad=3)
    _skirt(M, bd, BLACK, 2, flare=4, pad=0.5)
    _skirt(M, bd, WHITE, 30, flare=6, pad=2)                             # roquete hasta medio muslo
    for (x, y, z), v in M.V.items():
        if v[1] == WHITE and y in (30, 31) and (x + z) % 2 == 0: v[1] = LACE
    for s in (-1, 1):                                                    # estola
        for y in range(24, 63):
            for x in (int(s * 3), int(s * 4)):
                z = M.front(x, y)
                if z is not None: M.put(x, y, z + 1, T, PURPLE)
        for x, y in ((int(s * 3), 28), (int(s * 4), 28), (int(s * 3), 29), (int(s * 4), 29), (int(s * 3), 27), (int(s * 4), 27)):
            z = M.front(x, y)
            if z is not None: M.put(x, y, z, T, GOLD)
    _sleeves(M, bd, WHITE, LACE, pad=4, bottom=36)
    return {WHITE: 'lona', BLACK: 'lana'}


def capa_terciopelo(M, bd):
    """Capa larga de terciopelo carmesí, forrada de morado, con cuello alto y broche dorado:
    cubre los hombros y cae por la espalda (lo de abajo se mece al andar)."""
    RED = (0.46, 0.06, 0.10); RED_SH = (0.34, 0.04, 0.07); LINING = (0.24, 0.10, 0.30); GOLD = (0.86, 0.70, 0.30)
    b = _bb(bd, 0)
    slab(M, T, RED, 53, 63, 0, -0.5, 30 + b, 26 + b, 19, 17, ch=4)          # esclavina sobre los hombros
    for (x, y, z) in list(M.V):                                          # abierta delante
        if z > 5 and abs(x + 0.5) < 3: M.V.pop((x, y, z))
    slab(M, T, RED, 60, 67, 0, -2.5, 20 + b * 0.5, 22 + b * 0.5, 13, 14, ch=3)   # cuello alto
    for (x, y, z) in list(M.V):
        if y >= 63 and z > -3: M.V.pop((x, y, z))
    for y in range(10, 54):                                              # caída por la espalda
        t = (54 - y) / 44.0
        w = 30 + b + 6 * t
        slab(M, T, RED, y, y + 1, 0, -9.5 - 2 * t, w, w, 3, 3, ch=1)
        for x in (-int(w / 2), int(w / 2) - 1):
            M.put(x, y, int(-8 - 2 * t), T, LINING)
    for x in (-3, 2):                                                    # broche
        for y in (60, 61):
            M.put(x, y, 6, T, GOLD); M.put(x + 1, y, 6, T, GOLD)
    for (x, y, z), v in M.V.items():
        if v[1] == RED and (x + y) % 5 == 0: v[1] = RED_SH
    return {RED: 'lana', RED_SH: 'lana'}


def uniforme_lake(M, bd):
    """Uniforme caqui de la expedición Lake de la Miskatonic: guerrera con bolsillos de parche,
    cinturón, pantalón a juego y el escudo de la universidad en el hombro."""
    KHAKI = (0.62, 0.56, 0.40); KHAKI_SH = (0.50, 0.45, 0.31); BELT = (0.34, 0.22, 0.12)
    PATCH = (0.16, 0.30, 0.20); GOLD = (0.86, 0.70, 0.30); BTN = (0.30, 0.24, 0.14)
    _torso_cover(M, bd, KHAKI, 34, pad=2.5)
    _leg_cover(M, bd, KHAKI, bottom=12, pad=1.5, top=40)
    b = _bb(bd)
    slab(M, T, BELT, 41, 44, 0, 0.3, 27 + b, 27 + b, 16.5, 16.5, ch=3)
    for s in (-1, 1):                                                    # bolsillos de parche
        for x in range(int(3 * s), int(8 * s), s):
            for y in range(50, 56):
                z = M.front(x, y)
                if z is not None: M.put(x, y, z + (1 if y == 55 else 0), T, KHAKI_SH)
    for y in (46, 50, 54, 58):
        z = M.front(-1, y)
        if z is not None: M.put(-1, y, z + 1, T, BTN)
    _sleeves(M, bd, KHAKI, KHAKI_SH, pad=2.5)
    for s, _, _, arm, _ in cu.sides():                                   # escudo en el hombro izquierdo
        if s > 0: continue
        cx = int((bd['ax'] + bd.get('arm_b', bd['b']) / 2) * s)
        for y in range(54, 59):
            for z in range(-1, 2):
                xs = [vx for (vx, vy, vz), v in M.V.items() if vy == y and vz == z and v[0] == arm]
                if xs: M.put(min(xs), y, z, arm, GOLD if (y in (54, 58) or z in (-1, 1)) else PATCH)
    return {KHAKI: 'lona', KHAKI_SH: 'lona', BELT: 'cuero'}


def harapos(M, bd):
    """Harapos de superviviente: camisa gris rota y quemada, con el bajo a jirones, mangas de
    largos distintos y manchas de hollín."""
    RAG = (0.50, 0.46, 0.40); RAG_SH = (0.38, 0.35, 0.30); SOOT = (0.10, 0.09, 0.08); BLOOD = (0.36, 0.08, 0.06)
    _torso_cover(M, bd, RAG, 30, pad=2)
    for (x, y, z) in list(M.V):                                          # bajo a jirones y agujeros
        if y < 30 + ((x * 7 + z * 3) % 6): M.V.pop((x, y, z))
        elif _speck(x, y, z, 29) and M.exposed((x, y, z)): M.V.pop((x, y, z))
    k = 0.85 if bd['slim'] else 1.0
    for s, _, _, arm, fa in cu.sides():
        cx = (bd['ax'] + bd.get('arm_b', bd['b']) / 2) * s
        slab(M, arm, RAG, 46 if s < 0 else 52, 62, cx, 0, 7 * k + 2, 8.5 * k + 2, 7.5 * k + 2, 8.5 * k + 2, ch=1)
        if s < 0: slab(M, fa, RAG, 40, 46, cx * 1.02, 0.5, 7 * k + 2, 7 * k + 2, 7.5 * k + 2, 7.5 * k + 2, ch=1)
    for (x, y, z), v in M.V.items():
        if v[1] != RAG: continue
        if (x // 4 + (y // 5) * 3 + z // 4) % 7 == 0: v[1] = RAG_SH         # remiendos
        if _speck(x // 2, y // 2, z // 2, 29) or (y < 34 and _speck(x // 2, y // 2, z // 2, 7)): v[1] = SOOT
        if _speck(x // 2, (y + 7) // 2, z // 2, 113): v[1] = BLOOD
    return {RAG: 'lona', RAG_SH: 'lona'}


# ------------------------------------------------------------------ fase 14: pies (30-10-2026)

def _foot_cx(bd, s):
    return (4.5 if bd['fem'] else 5) * s


def botas_agua(M, bd):
    """Botas de agua de goma verde oscuro hasta media pierna, con la suela gruesa y una franja."""
    GREEN = (0.16, 0.24, 0.16); SOLE = (0.08, 0.07, 0.06); BAND = (0.26, 0.36, 0.22)
    _boot(M, bd, GREEN, SOLE, 20, pad=2)
    for (x, y, z), v in M.V.items():
        if v[1] == GREEN and y in (18, 19): v[1] = BAND
    return {}


def zapatos_bicolor(M, bd):
    """Zapatos bicolores de gánster: blancos con puntera y talón marrones, y calcetín negro."""
    WHITE = (0.92, 0.90, 0.84); BROWN = (0.36, 0.20, 0.10); SOLE = (0.10, 0.08, 0.06); SOCK = (0.06, 0.06, 0.07)
    for s, _, shin, _, _ in cu.sides():
        cx = _foot_cx(bd, s)
        slab(M, shin, SOLE, 0, 1, cx, 1.5, 10, 10, 16, 16, ch=1)
        slab(M, shin, WHITE, 1, 4, cx, 1.5, 10, 9.5, 16, 14, ch=1)
        slab(M, shin, SOCK, 4, 9, cx, -0.3, 9.5, 9.5, 10, 10, ch=1)
    for (x, y, z), v in M.V.items():
        if v[1] == WHITE and (z >= 6 or z <= -5): v[1] = BROWN
    return {WHITE: 'cuero', BROWN: 'cuero'}


def sandalias_calcetines(M, bd):
    """Sandalias de cuero con calcetines blancos hasta media pierna: el turista de Arkham."""
    SOCK = (0.92, 0.91, 0.86); STRIPE = (0.40, 0.52, 0.72); LEATHER = (0.48, 0.30, 0.16); SOLE = (0.22, 0.14, 0.08)
    for s, _, shin, _, _ in cu.sides():
        cx = _foot_cx(bd, s)
        slab(M, shin, SOLE, 0, 1, cx, 1.5, 10.5, 10.5, 16.5, 16.5, ch=1)
        slab(M, shin, SOCK, 1, 4, cx, 1.5, 10, 9.5, 16, 14, ch=1)
        slab(M, shin, SOCK, 4, 18, cx, -0.3, 10, 10, 10.5, 10.5, ch=1)
        for y in (16, 17):
            slab(M, shin, STRIPE, y, y + 1, cx, -0.3, 10.2, 10.2, 10.7, 10.7, ch=1)
    for (x, y, z), v in M.V.items():                                       # tiras de la sandalia
        if v[1] == SOCK and y <= 4 and (z % 4 == 0 or y == 4) and M.exposed((x, y, z)): v[1] = LEATHER
    return {SOCK: 'punto', STRIPE: 'punto', LEATHER: 'cuero'}


def botas_montar(M, bd):
    """Botas de montar negras de caña alta hasta la rodilla, con espuela de latón."""
    BLACK = (0.19, 0.11, 0.07); SOLE = (0.05, 0.04, 0.03); BRASS = (0.80, 0.62, 0.28); CUFF = (0.36, 0.22, 0.12)
    _boot(M, bd, BLACK, SOLE, 27, cuff=CUFF, pad=1.5)
    for s, _, shin, _, _ in cu.sides():
        cx = int(round(_foot_cx(bd, s)))
        zs = [z for (x, y, z), v in M.V.items() if v[0] == shin and y == 4 and x == cx]
        if zs:
            M.put(cx, 4, min(zs) - 1, shin, BRASS); M.put(cx, 4, min(zs) - 2, shin, BRASS)
            M.put(cx - 1, 4, min(zs) - 1, shin, BRASS)
    return {BLACK: 'cuero'}


def raquetas_nieve(M, bd):
    """Raquetas de nieve de madera y tripa trenzada bajo unas botas de piel."""
    WOOD = (0.52, 0.36, 0.18); GUT = (0.76, 0.66, 0.46); HIDE = (0.40, 0.30, 0.20); FUR = (0.86, 0.82, 0.74)
    _boot(M, bd, HIDE, HIDE, 12, cuff=FUR, pad=1.5)
    for s, _, shin, _, _ in cu.sides():
        cx = _foot_cx(bd, s) * 1.25
        for x in range(int(cx - 7), int(cx + 7)):
            for z in range(-13, 15):
                q = ((x + 0.5 - cx) / 6.5) ** 2 + ((z + 0.5 - 0.5) / (13.5 if z > 0 else 12.5)) ** 2
                if q > 1 or (x, 0, z) in M.V: continue
                rim = q > 0.72
                if not rim and (x + z) % 3 != 0: continue                   # trenzado
                M.put(x, 0, z, shin, WOOD if rim else GUT)
    return {HIDE: 'cuero', FUR: 'borreguillo'}


def zapatillas(M, bd):
    """Zapatillas de casa de cuadros escoceses con borla de lana."""
    RED = (0.56, 0.14, 0.14); GREEN = (0.16, 0.30, 0.20); YEL = (0.86, 0.72, 0.32); POM = (0.92, 0.88, 0.80)
    for s, _, shin, _, _ in cu.sides():
        cx = _foot_cx(bd, s)
        slab(M, shin, GREEN, 0, 1, cx, 1.5, 11, 11, 17, 17, ch=2)
        slab(M, shin, RED, 1, 5, cx, 1.5, 11, 10.5, 17, 15, ch=2)
    for (x, y, z), v in M.V.items():
        if v[1] == RED and (x % 4 == 0 or y == 3): v[1] = GREEN if (x + y) % 2 else YEL
    for s, _, shin, _, _ in cu.sides():                                    # borla encima de la puntera
        x = int(round(_foot_cx(bd, s)))
        for dx in (-1, 0):
            z = max(vz for (vx, vy, vz), v in M.V.items() if vx == x + dx and vy == 4 and v[0] == shin)
            for dy in (5, 6):
                M.put(x + dx, dy, z - 1, shin, POM); M.put(x + dx, dy, z - 2, shin, POM)
    return {RED: 'punto', GREEN: 'punto', POM: 'borreguillo'}


def botas_buzo(M, bd):
    """Botas de buzo de plomo con puntera de latón y correas de cuero, pesadísimas."""
    LEAD = (0.30, 0.31, 0.33); BRASS = (0.78, 0.60, 0.26); STRAP = (0.30, 0.20, 0.12)
    for s, _, shin, _, _ in cu.sides():
        cx = _foot_cx(bd, s)
        slab(M, shin, LEAD, 0, 4, cx, 1.5, 12, 12, 18, 18, ch=1)
        slab(M, shin, LEAD, 4, 13, cx, -0.3, 11.5, 11, 12.5, 12, ch=1)
        for y in (6, 7, 10, 11):
            slab(M, shin, STRAP, y, y + 1, cx, -0.3, 12, 12, 13, 13, ch=1)
        slab(M, shin, BRASS, 12, 13, cx, -0.3, 12, 12, 13, 13, ch=1)          # aro de arriba
    for (x, y, z), v in M.V.items():                                       # puntera de latón
        if v[1] == LEAD and y < 4 and z >= 8: v[1] = BRASS
    return {STRAP: 'cuero'}


def pies_membrana(M, bd):
    """Pies descalzos grises y verdosos de los de Innsmouth: dedos largos unidos por membrana y
    uñas negras, con la piel escamosa hasta media pierna."""
    SKIN = (0.46, 0.52, 0.44); SKIN_D = (0.34, 0.40, 0.33); WEB = (0.56, 0.64, 0.50); NAIL = (0.08, 0.08, 0.06)
    SCALE = (0.38, 0.46, 0.40)
    for s, _, shin, _, _ in cu.sides():
        cx = _foot_cx(bd, s)
        slab(M, shin, SKIN, 0, 3, cx, 0.8, 11.5, 11.5, 16, 15, ch=1)          # planta
        slab(M, shin, SKIN, 3, 14, cx, -0.3, 10, 9.5, 10.5, 10, ch=1)          # tobillo y pierna
        x0 = int(round(cx)) - 5
        for i in range(4):                                                  # cuatro dedos largos
            x = x0 + i * 3
            for z in range(8, 13):
                M.put(x, 0, z, shin, SKIN_D); M.put(x, 1, z, shin, SKIN_D)
            M.put(x, 0, 13, shin, NAIL); M.put(x, 1, 13, shin, NAIL)
            if i < 3:
                for z in range(8, 11): M.put(x + 1, 0, z, shin, WEB); M.put(x + 2, 0, z, shin, WEB)
    for (x, y, z), v in M.V.items():
        if v[1] == SKIN and y > 3 and _speck(x, y // 2, z, 5): v[1] = SCALE
    return {SKIN: 'piel', SKIN_D: 'piel', WEB: 'piel'}


# ------------------------------------------------------------------ fase 14: complementos (30-10-2026)

def torso_of(c):
    """Voxels del tronco del personaje (con faldones, estola y bufanda): para que lo que va
    encima del pecho quede por fuera de su ropa."""
    with open('models/%s.json' % c) as f:
        return {(v[0], v[1], v[2]) for v in json.load(f)['voxels']
                if v[3] in ('torso', 'skirt', 'stole', 'scarf', 'gear', 'shawl') and not (len(v) > 8 and v[8] & 64)}


class _Chest:
    """Superficie de delante y de detrás del pecho: la del personaje o, si es mayor, la del abrigo
    más grueso del vestuario (así un collar no queda dentro de una gabardina)."""
    def __init__(self, bd, torso, pad=3.2):
        E = cu.new(1)
        _torso_cover(E, bd, (0, 0, 0), 30, pad=pad)
        self.shell = set(E.V) | set(torso)
        self.front, self.back = {}, {}
        for (x, y, z) in self.shell:
            if z > self.front.get((x, y), -99): self.front[(x, y)] = z
            if z < self.back.get((x, y), 99): self.back[(x, y)] = z
        self.surface = [k for k in self.shell if any((k[0] + dx, k[1] + dy, k[2] + dz) not in self.shell
                        for dx, dy, dz in ((1, 0, 0), (-1, 0, 0), (0, 0, 1), (0, 0, -1)))]

    def z(self, x, y):
        return self.front.get((x, y), 6)

    def put(self, M, x, y, col, dz=1, glow=0):
        if (x, y) in self.front: M.put(x, y, self.front[(x, y)] + dz, T, col, glow)

    def band(self, M, col, fn, w=1.6, ymin=36, ymax=62):
        """Correa por fuera del tronco: los voxels de la superficie donde |fn(x, y)| < w, uno más afuera."""
        out = []
        for (x, y, z) in self.surface:
            if ymin <= y <= ymax and abs(fn(x, y)) < w:
                zo = z + 1 if z >= 0 else z - 1
                M.put(x, y, zo, T, col)
                out.append((x, y, zo))
        return out

    def half_w(self, y):
        xs = [x for (x, yy) in self.front if yy == y]
        return (max(xs) - min(xs) + 1) / 2 if xs else 14


def _neck_ring(M, bd, ch, col, y=62, step=1):
    """Cordón alrededor del cuello, por encima de los hombros (de cualquier cuello de abrigo)."""
    b = bd['b'] + (-4 if bd['fem'] else 0)
    a, c = 9.5 + b * 0.25, 8.5
    for i in range(0, 64, step):
        t = i / 64 * math.tau
        x, z = int(round(math.cos(t) * a - 0.5)), int(round(math.sin(t) * c + 0.5))
        M.put(x, y, z, T, col)


def _hang(M, ch, col, x_top, x_bot, y_top, y_bot, every=1, alt=None):
    """Cadena que baja por delante del pecho de (x_top, y_top) a (x_bot, y_bot)."""
    n = y_top - y_bot
    for i in range(n + 1):
        y = y_top - i
        x = int(round(x_top + (x_bot - x_top) * i / max(n, 1)))
        if i % every: continue
        ch.put(M, x, y, alt if (alt is not None and (i // every) % 2) else col)


def _fput(M, head, x, y, col, dz=1, glow=0):
    M.put(x, y, _front_z(head, x, y) + dz, H, col, glow)


def monoculo(M, bd, face):
    """Monóculo de oro en el ojo derecho con cadenita que cae por el lado de la cara."""
    GOLD = (0.84, 0.68, 0.28); GLASS = (0.74, 0.86, 0.90)
    y0, head = face
    x0 = 1
    for x in range(x0 + 1, x0 + 5): _fput(M, head, x, y0 - 1, GOLD); _fput(M, head, x, y0 + 2, GOLD)
    for y in (y0, y0 + 1): _fput(M, head, x0, y, GOLD); _fput(M, head, x0 + 5, y, GOLD)
    _fput(M, head, x0 + 4, y0 + 1, GLASS)
    xs = max(x for (x, y, z) in head if y == y0) + 1
    for y in range(64, y0 + 1):                                           # cadenita por el lado
        M.put(xs, y, 3 if y > 66 else 2, H, GOLD)
    return {}


def pipa(M, bd, face):
    """Pipa de brezo en la comisura, con la brasa encendida: echa humo (VoxelBuilder.dress)."""
    WOOD = (0.30, 0.16, 0.08); STEM = (0.08, 0.07, 0.06); EMBER = (1.0, 0.45, 0.12); ASH = (0.32, 0.30, 0.28)
    y0, head = face
    ym = y0 - 5
    zf = _front_z(head, 2, ym)
    for i, x in enumerate(range(1, 6)):                                   # boquilla que sale de la boca
        M.put(x, ym, zf + 1 + i // 2, H, STEM)
    zb = zf + 3
    for x in (5, 6, 7):                                                   # cazoleta
        for z in (zb, zb + 1, zb + 2):
            for y in range(ym - 1, ym + 3):
                if y == ym - 1 and (x in (5, 7) or z in (zb, zb + 2)): continue
                M.put(x, y, z, H, WOOD)
    M.put(6, ym + 2, zb + 1, H, EMBER, 1)
    M.put(6, ym + 3, zb + 1, H, ASH)
    M.marks = {'smoke_pipe': [6.5, ym + 3.5, zb + 1.5]}
    return {WOOD: 'cuero'}


def collar_signo(M, bd, torso):
    """Colgante del Signo Primigenio: una estrella de piedra gris con el ojo verde que brilla,
    de una cadena de plata."""
    SILVER = (0.70, 0.72, 0.74); STONE = (0.46, 0.46, 0.42); STONE_D = (0.32, 0.32, 0.30); EYE = (0.30, 0.95, 0.50)
    ch = _Chest(bd, torso)
    _neck_ring(M, bd, ch, SILVER)
    for s in (-1, 1): _hang(M, ch, SILVER, s * 6, s * 1, 61, 55)
    star = ['...#...', '..###..', '#######', '.#####.', '.##.##.', '#.....#']
    for r, row in enumerate(star):
        for i, cch in enumerate(row):
            if cch == '#': ch.put(M, i - 3, 54 - r, STONE if (i + r) % 3 else STONE_D)
    ch.put(M, 0, 51, EYE, dz=2, glow=1)
    return {}


def bolsa_cartero(M, bd, torso):
    """Bolsa de cartero de lona con solapa de cuero, cruzada del hombro derecho a la cadera."""
    CANVAS = (0.44, 0.40, 0.28); LEATHER = (0.34, 0.20, 0.10); BUCKLE = (0.72, 0.60, 0.30)
    ch = _Chest(bd, torso)
    ch.band(M, LEATHER, lambda x, y: (y - 40) - (x + 9) * 1.05, w=1.7)
    hw = ch.half_w(42)
    x1 = -int(hw) - 1
    for x in range(x1 - 4, x1 + 1):                                        # la bolsa, en el costado
        for y in range(32, 43):
            for z in range(-5, 6):
                flap = y >= 38 and x == x1 - 4
                M.put(x, y, z, T, LEATHER if flap or y >= 41 else CANVAS)
    M.put(x1 - 5, 38, 0, T, BUCKLE); M.put(x1 - 5, 37, 0, T, BUCKLE)
    return {CANVAS: 'lona', LEATHER: 'cuero'}


def canana(M, bd, torso):
    """Dos cananas cruzadas sobre el pecho, de cuero, cargadas de cartuchos de latón."""
    LEATHER = (0.36, 0.22, 0.12); BRASS = (0.82, 0.64, 0.28)
    ch = _Chest(bd, torso)
    for k in (1.0, -1.0):
        vox = ch.band(M, LEATHER, lambda x, y, k=k: (y - 48) - x * 1.1 * k, w=1.8, ymin=34)
        for (x, y, z) in vox:
            if z > 0 and y % 2 == 0 and abs((y - 48) - x * 1.1 * k) < 0.7: M.put(x, y, z + 1, T, BRASS)
    return {LEATHER: 'cuero'}


def antifaz(M, bd, face):
    """Antifaz negro de seda con los ojos al aire, anudado detrás con las puntas sueltas."""
    SILK = (0.06, 0.05, 0.07); SILK_SH = (0.12, 0.10, 0.14)
    y0, head = face
    w, d = _head_box(bd)
    holes = {(x, y) for x in (-5, -4, 3, 4) for y in (y0, y0 + 1)}
    slab(M, H, SILK, y0 - 1, y0 + 3, 0, 0.0, w + 1.2, w + 1.2, d + 1.2, d + 1.2, ch=3)
    for (x, y, z) in list(M.V):
        if (x, y) in holes and z > 0: M.V.pop((x, y, z))
    for x in range(-8, 8):
        for y in range(y0 - 1, y0 + 3):
            if (x, y) not in holes and not (y in (y0 - 1, y0 + 2) and x in (-8, 7)): _fput(M, head, x, y, SILK)
    zb = -int(round((d + 1.2) / 2)) - 1
    for i, y in enumerate(range(y0, y0 - 7, -1)):                        # puntas del nudo
        M.put(-1 - i // 3, y, zb, H, SILK_SH); M.put(i // 3, y, zb, H, SILK_SH)
    return {}


def mascara_gas(M, bd, face):
    """Máscara de gas de la Gran Guerra: goma verde gris, dos cristales redondos y el filtro."""
    RUBBER = (0.26, 0.30, 0.24); RUBBER_D = (0.18, 0.21, 0.17); GLASS = (0.30, 0.44, 0.46)
    RIM = (0.56, 0.52, 0.42); CAN = (0.40, 0.42, 0.36)
    y0, head = face
    w, d = _head_box(bd)
    rslab(M, H, RUBBER_D, 63, y0 + 6, 0, 0.3, w + 2, d + 2, r=4, rt=3, rb=2)
    for (x, y, z) in list(M.V):
        if z < -1 and y > 66: M.V.pop((x, y, z))                          # detrás, solo las correas
    slab(M, H, RUBBER_D, y0 + 4, y0 + 6, 0, 0.3, w + 2.6, w + 2.6, d + 2.6, d + 2.6, ch=3)
    for x in range(-8, 8):
        for y in range(63, y0 + 6):
            _fput(M, head, x, y, RUBBER)
    for cx in (-5, 3):                                                    # cristales
        for a in range(-3, 3):
            for b in range(-3, 3):
                q = math.hypot(a + 0.5, b + 0.5)
                x, y = cx + a + 1, y0 + 1 + b
                if q < 2.0: _fput(M, head, x, y, GLASS, dz=2)
                elif q < 3.0: _fput(M, head, x, y, RIM, dz=2)
    zf = max(_front_z(head, x, y0 - 4) for x in (-1, 0)) + 2
    for x in range(-2, 2):                                                # filtro
        for y in range(y0 - 7, y0 - 3):
            for z in range(zf, zf + 5):
                M.put(x, y, z, H, CAN if z < zf + 4 else RIM)
    return {RUBBER: 'cuero', RUBBER_D: 'cuero'}


def medico_peste(M, bd, face):
    """Máscara de médico de la peste: capucha de cuero negro, ojos de cristal rojo y el pico largo."""
    LEATHER = (0.12, 0.10, 0.09); LEATHER_SH = (0.20, 0.16, 0.12); GLASS = (0.70, 0.12, 0.08); RIM = (0.66, 0.54, 0.30)
    BEAK = (0.30, 0.22, 0.15); BEAK_SH = (0.22, 0.16, 0.11)
    y0, head = face
    w, d = _head_box(bd)
    rslab(M, H, LEATHER, 63, y0 + 9, 0, 0.0, w + 2, d + 2, r=5, rt=5, rb=1)
    for x in range(-8, 8):
        for y in range(63, y0 + 8):
            _fput(M, head, x, y, LEATHER)
    for cx in (-5, 3):
        for a in range(-2, 2):
            for b in range(-2, 2):
                x, y = cx + a + 1, y0 + 1 + b
                rim = a in (-2, 1) or b in (-2, 1)
                _fput(M, head, x, y, RIM if rim else GLASS, dz=2, glow=0 if rim else 1)
    zf = max(_front_z(head, x, y0 - 2) for x in (-1, 0)) + 1
    for i in range(17):                                                   # pico largo que cae al final
        r = 3.2 - i * 0.16
        cy = y0 - 2 - i * 0.12 - max(0, i - 10) * 0.35
        for x in range(-4, 4):
            for y in range(int(cy - 4), int(cy + 4)):
                if abs(x + 0.5) <= r and abs(y + 0.5 - cy) <= r * 0.9:
                    M.put(x, y, zf + i, H, BEAK_SH if i % 4 == 3 else BEAK)
    return {LEATHER: 'cuero', LEATHER_SH: 'cuero', BEAK: 'cuero'}


def vendas_parche(M, bd, face):
    """Vendas sucias alrededor de la frente con una mancha de sangre, parche negro en un ojo y
    una tirita en la mejilla."""
    GAUZE = (0.86, 0.84, 0.76); GAUZE_D = (0.70, 0.66, 0.56); BLOOD = (0.50, 0.08, 0.06); PATCH = (0.05, 0.05, 0.05)
    PLASTER = (0.88, 0.74, 0.60)
    y0, head = face
    w, d = _head_box(bd)
    slab(M, H, GAUZE, y0 + 4, y0 + 8, 0, 0.0, w + 1.2, w + 1.2, d + 1.2, d + 1.2, ch=3)
    for (x, y, z), v in M.V.items():
        if (x + y * 2) % 5 == 0: v[1] = GAUZE_D
        if 1 <= x <= 3 and y >= y0 + 5 and z > 2: v[1] = BLOOD
    for x in range(-7, -1):                                               # parche en el ojo izquierdo
        for y in range(y0 - 1, y0 + 3):
            if (x, y) in ((-7, y0 - 1), (-2, y0 - 1)): continue
            _fput(M, head, x, y, PATCH)
    for i in range(6):                                                    # cinta del parche hacia la venda
        _fput(M, head, -2 + i, y0 + 3 + i // 2, PATCH)
    for x in (3, 4, 5):
        for y in (y0 - 3, y0 - 2): _fput(M, head, x, y, PLASTER)
    return {GAUZE: 'lana', GAUZE_D: 'lana'}


def clavel(M, bd, torso):
    """Clavel rojo en el ojal de la solapa."""
    RED = (0.78, 0.10, 0.12); RED_D = (0.56, 0.06, 0.08); GREEN = (0.20, 0.40, 0.16)
    ch = _Chest(bd, torso, pad=2.6)
    for x, y, c, dz in ((-7, 57, RED, 1), (-6, 57, RED, 1), (-8, 56, RED, 1), (-7, 56, RED_D, 2), (-6, 56, RED, 1),
                        (-5, 56, RED, 1), (-7, 55, RED, 1), (-6, 55, RED, 1), (-6, 54, GREEN, 1), (-6, 53, GREEN, 1),
                        (-5, 54, GREEN, 1), (-7, 58, RED_D, 1)):
        ch.put(M, x, y, c, dz=dz)
    return {}


def panuelo_vaquero(M, bd, face):
    """Pañuelo de vaquero rojo con dibujo blanco, tapando nariz y boca y anudado detrás."""
    RED = (0.64, 0.12, 0.10); RED_D = (0.48, 0.08, 0.07); DOT = (0.90, 0.88, 0.82)
    y0, head = face
    w, d = _head_box(bd)
    slab(M, H, RED_D, y0 - 3, y0 - 1, 0, 0.0, w + 1.2, w + 1.2, d + 1.2, d + 1.2, ch=3)
    for (x, y, z) in list(M.V):
        if z > 0: M.V.pop((x, y, z))
    for x in range(-8, 8):
        for y in range(62, y0 - 1):
            if y < 66 and abs(x + 0.5) > (y - 61) * 1.6: continue           # pico que cae bajo la barbilla
            _fput(M, head, x, y, RED)
    for (x, y, z), v in M.V.items():
        if v[1] == RED and (x * 3 + y * 5) % 9 == 0: v[1] = DOT
    zb = -int(round((d + 1.2) / 2)) - 1
    for i, y in enumerate(range(y0 - 2, y0 - 8, -1)):                    # nudo
        M.put(-1, y, zb, H, RED_D); M.put(0 + i // 3, y, zb, H, RED_D)
    return {RED: 'lana', RED_D: 'lana'}


def estetoscopio(M, bd, torso):
    """Estetoscopio colgado del cuello: el tubo negro, la campana de plata y las olivas."""
    TUBE = (0.08, 0.08, 0.09); SILVER = (0.80, 0.82, 0.84)
    ch = _Chest(bd, torso)
    _neck_ring(M, bd, ch, TUBE)
    _hang(M, ch, TUBE, 6, 5, 61, 49)
    _hang(M, ch, TUBE, -6, -4, 61, 52)
    for x in (4, 5, 6):
        for y in (46, 47, 48): ch.put(M, x, y, SILVER, dz=1 if (x, y) != (5, 47) else 2)
    for x in (-5, -3):                                                     # olivas
        for y in (50, 51): ch.put(M, x, y, SILVER)
    return {}


def camara_fuelle(M, bd, torso):
    """Cámara de fuelle colgada al pecho: caja negra, fuelle rojo, objetivo de latón."""
    BLACK = (0.08, 0.08, 0.09); BELLOWS = (0.40, 0.10, 0.08); BELLOWS_D = (0.26, 0.06, 0.05)
    BRASS = (0.80, 0.62, 0.28); GLASS = (0.20, 0.30, 0.36); STRAP = (0.30, 0.20, 0.12)
    ch = _Chest(bd, torso)
    _neck_ring(M, bd, ch, STRAP)
    for s in (-1, 1): _hang(M, ch, STRAP, s * 7, s * 5, 61, 51)
    z0 = max(ch.z(x, y) for x in range(-5, 5) for y in range(43, 51)) + 1
    for x in range(-5, 5):
        for y in range(43, 51):
            for z in range(z0, z0 + 7):
                if z < z0 + 2: c = BLACK
                elif z < z0 + 6: c = BELLOWS if (z - z0) % 2 else BELLOWS_D
                else: c = BLACK
                if z >= z0 + 2 and (abs(x + 0.5) > 4 - (z - z0 - 2) * 0.3 or y in (43, 50)): continue
                M.put(x, y, z, T, c)
    for a in range(-2, 2):
        for b in range(-2, 2):
            M.put(a, 46 + b + 1, z0 + 7, T, GLASS if a in (-1, 0) and b in (-1, 0) else BRASS)
    return {STRAP: 'cuero'}


def rosario(M, bd, torso):
    """Rosario de cuentas de madera con la cruz de plata, colgado largo sobre el pecho."""
    BEAD = (0.38, 0.22, 0.12); BEAD_L = (0.52, 0.34, 0.18); SILVER = (0.80, 0.82, 0.84)
    ch = _Chest(bd, torso)
    _neck_ring(M, bd, ch, BEAD, step=2)
    for s in (-1, 1): _hang(M, ch, BEAD, s * 6, 0, 61, 45, alt=BEAD_L)
    for x, y in ((0, 44), (0, 43), (0, 42), (0, 41), (0, 40), (-1, 42), (1, 42)):
        ch.put(M, x, y, SILVER)
    return {}


def ojos_innsmouth(M, bd, face):
    """Los ojos saltones y sin párpados de la cara de Innsmouth: grandes, pálidos, con la pupila
    en rendija, y dos agallas en el cuello."""
    LID = (0.50, 0.56, 0.48); WHITE = (0.70, 0.74, 0.62); IRIS = (0.78, 0.74, 0.30); PUPIL = (0.03, 0.03, 0.03)
    GILL = (0.36, 0.20, 0.20)
    y0, head = face
    for cx in (-7, 2):                                                    # globos de 5x5, separados
        for a in range(5):
            for b in range(5):
                if (a in (0, 4)) and (b in (0, 4)): continue
                x, y = cx + a, y0 - 2 + b
                _fput(M, head, x, y, LID, dz=1)
                inner = 0 < a < 4 and 0 < b < 4
                _fput(M, head, x, y, IRIS if inner else WHITE, dz=2, glow=1 if inner else 0)
        for a in (1, 2, 3):                                               # pupila en rendija horizontal
            _fput(M, head, cx + a, y0, PUPIL, dz=3)
    for s in (-1, 1):                                                     # agallas
        for y in (65, 67):
            xs = [x for (x, yy, z) in head if yy == y and z == 1]
            if xs:
                x = (max(xs) + 1) if s > 0 else (min(xs) - 1)
                for z in (-1, 0, 1, 2): M.put(x, y, z, H, GILL)
    return {}


# ------------------------------------------------------------------ fase 14: manos y espalda (30-10-2026)

HAND_TOP = 33                            # por debajo, la mano (y el puño de la manga)
# giro total del antebrazo (brazo + antebrazo) en cada postura de OutfitData.HOLDS: el objeto se
# construye ya girado para que, con el brazo en esa postura, quede como debe (derecho, delante)
HOLD_ANGLES = {'umbrella': -0.35 - 1.45, 'lantern': -0.35 - 0.85, 'cane': -0.1 - 0.45}


def hands_of(c):
    """Voxels de las manos del personaje (antebrazos por debajo de HAND_TOP), por parte."""
    with open('models/%s.json' % c) as f:
        vox = json.load(f)['voxels']
    out = {'fore_l': set(), 'fore_r': set()}
    for v in vox:
        if v[3] in out and v[1] <= HAND_TOP and not (len(v) > 8 and v[8] & 64): out[v[3]].add((v[0], v[1], v[2]))
    return out


def _grip(hands):
    """Dónde agarra la mano derecha: centro de la mano, algo por debajo de la muñeca."""
    vs = hands['fore_r']
    xs = [x for x, y, z in vs]; zs = [z for x, y, z in vs]
    return (round(sum(xs) / len(xs)), 27, round(sum(zs) / len(zs)) + 1)


def _glove(M, hands, col, cuff=None, grow=1):
    """Guante: la mano engordada `grow` voxels; con `cuff`, vuelta encima de la muñeca."""
    for part, vs in hands.items():
        r = range(-grow, grow + 1)
        for (x, y, z) in vs:
            for dx in r:
                for dy in r:
                    for dz in r:
                        k = (x + dx, y + dy, z + dz)
                        if k not in vs and k[1] <= HAND_TOP + 1: M.put(k[0], k[1], k[2], part, col)
        if cuff is not None:
            ys = {}
            for (x, y, z) in vs:
                if y >= HAND_TOP - 2: ys.setdefault(y, []).append((x, z))
            pts = [p for y in ys for p in ys[y]]
            if not pts: continue
            x0 = min(p[0] for p in pts) - grow - 1; x1 = max(p[0] for p in pts) + grow + 1
            z0 = min(p[1] for p in pts) - grow - 1; z1 = max(p[1] for p in pts) + grow + 1
            for y in range(HAND_TOP - 1, HAND_TOP + 3):
                for x in range(x0, x1 + 1):
                    for z in range(z0, z1 + 1):
                        if x in (x0, x1) or z in (z0, z1): M.put(x, y, z, part, cuff)


def _held(M, hands, hold, shape, reach=60):
    """Objeto en la mano derecha. shape(px, py, pz) -> color (o (color, glow)) o None, en
    coordenadas de mundo con el brazo en la postura `hold` y el origen en el agarre. Se recorre
    la rejilla del modelo en reposo y se gira cada punto a la postura, así no quedan huecos."""
    gx, gy, gz = _grip(hands)
    t = HOLD_ANGLES[hold]
    c, s = math.cos(t), math.sin(t)
    for qx in range(-reach, reach + 1):
        for qy in range(-reach, reach + 1):
            for qz in range(-reach, reach + 1):
                py = qy * c - qz * s
                pz = qy * s + qz * c
                r = shape(qx, py, pz)
                if r is None: continue
                col, glow = r if isinstance(r[0], tuple) else (r, 0)
                M.put(gx + qx, gy + qy, gz + qz, 'fore_r', col, glow)
    return (gx, gy, gz), t


def _to_rest(grip, t, p):
    """Punto de mundo (relativo al agarre, con la postura) a coordenadas del modelo en reposo."""
    gx, gy, gz = grip
    c, s = math.cos(-t), math.sin(-t)
    x, y, z = p
    return [gx + x, gy + (y * c - z * s), gz + (y * s + z * c)]


def guantes_cuero(M, bd, hands):
    """Guantes de conducir de cuero marrón, con una vuelta a la muñeca."""
    LEATHER = (0.34, 0.20, 0.10); CUFF = (0.24, 0.14, 0.07)
    _glove(M, hands, LEATHER, CUFF)
    return {LEATHER: 'cuero', CUFF: 'cuero'}


def guantes_boxeo(M, bd, hands):
    """Guantes de boxeo rojos, grandes y redondos, con el puño blanco."""
    RED = (0.70, 0.10, 0.10); RED_SH = (0.54, 0.07, 0.07); WHITE = (0.92, 0.90, 0.86)
    for part, vs in hands.items():
        if not vs: continue
        cx = sum(x for x, y, z in vs) / len(vs); cz = sum(z for x, y, z in vs) / len(vs) + 1
        for x in range(int(cx) - 8, int(cx) + 9):
            for y in range(19, 36):
                for z in range(int(cz) - 9, int(cz) + 10):
                    q = ((x + 0.5 - cx) / 6.0) ** 2 + ((y + 0.5 - 27.0) / 6.5) ** 2 + ((z + 0.5 - cz) / 7.0) ** 2
                    if q <= 1.0: M.put(x, y, z, part, RED if y < 30 or (x + y) % 6 else RED_SH)
                    elif y >= 31 and q <= 1.25: M.put(x, y, z, part, WHITE)
    return {WHITE: 'cuero'}


def manoplas(M, bd, hands):
    """Manoplas de lana roja con un copo bordado y la vuelta blanca."""
    RED = (0.62, 0.12, 0.12); WHITE = (0.92, 0.90, 0.84)
    _glove(M, hands, RED, WHITE, grow=2)
    for (x, y, z), v in M.V.items():
        if v[1] == RED and y in (27, 28) and (x + z) % 3 == 0: v[1] = WHITE
    return {RED: 'punto', WHITE: 'punto'}


def baston(M, bd, hands):
    """Bastón de ébano con puño de plata curvado: va apoyado en el suelo, por delante."""
    EBONY = (0.20, 0.12, 0.08); SILVER = (0.86, 0.88, 0.90); TIP = (0.70, 0.56, 0.26)
    def shape(x, y, z):
        if -30.5 <= y <= 1.5 and math.hypot(x, z) <= 1.15:
            return TIP if y < -29 else EBONY
        if 0.5 <= y <= 4.5 and -1.2 <= x <= 1.2 and -1.2 <= z <= 6.0:   # puño curvado hacia delante
            return SILVER
        return None
    _held(M, hands, 'cane', shape, reach=34)
    return {}


def paraguas(M, bd, hands):
    """Paraguas negro abierto, en alto sobre la cabeza, con varillas y puño de madera."""
    BLACK = (0.16, 0.17, 0.22); PANEL = (0.23, 0.24, 0.30); RIB = (0.62, 0.63, 0.66); WOOD = (0.46, 0.28, 0.14)
    lean = (0.0, 1.0, -0.36)
    n = math.sqrt(sum(a * a for a in lean)); ax = [a / n for a in lean]
    L, R, DROP = 50.0, 27.0, 9.0
    def shape(x, y, z):
        u = x * ax[0] + y * ax[1] + z * ax[2]                             # a lo largo del mango
        px, py, pz = x - u * ax[0], y - u * ax[1], z - u * ax[2]
        r = math.sqrt(px * px + py * py + pz * pz)
        if -3.5 <= u <= L + 2 and r <= 0.9:
            return WOOD if u < 4 else BLACK
        if -4.5 <= u <= -2.5 and r <= 2.6 and pz > -0.5:                 # puño curvo
            return WOOD
        if r <= R:
            h = L - DROP * (r / R) ** 2                                  # tela: cúpula que cae
            if abs(u - h) <= 0.9:
                ang = math.atan2(px, pz)
                k = (ang / (math.tau / 8)) % 1.0
                if k < 0.07 or k > 0.93: return RIB
                return PANEL if int(ang / (math.tau / 8) + 8) % 2 else BLACK
        return None
    _held(M, hands, 'umbrella', shape, reach=58)
    return {}


def linterna(M, bd, hands):
    """Linterna eléctrica de latón y baquelita, encendida: alumbra hacia delante."""
    BODY = (0.12, 0.10, 0.08); BRASS = (0.80, 0.62, 0.26); LENS = (1.0, 0.95, 0.76)
    d = (0.0, -0.25, 1.0)
    n = math.sqrt(sum(a * a for a in d)); ax = [a / n for a in d]
    def shape(x, y, z):
        u = x * ax[0] + y * ax[1] + z * ax[2]
        px, py, pz = x - u * ax[0], y - u * ax[1], z - u * ax[2]
        r = math.sqrt(px * px + py * py + pz * pz)
        if -3 <= u <= 6 and r <= 1.9: return BRASS if u < -2 or 2 <= u < 3 else BODY
        if 6 <= u <= 10 and r <= 1.9 + (u - 6) * 0.45:
            if u >= 9.3: return (LENS, 1)
            return BRASS
        return None
    grip, t = _held(M, hands, 'lantern', shape, reach=16)
    M.marks = {'beam': _to_rest(grip, t, [ax[0] * 11, ax[1] * 11, ax[2] * 11]),
               'beam_to': _to_rest(grip, t, [ax[0] * 21, ax[1] * 21, ax[2] * 21])}
    return {}


def mochila(M, bd, torso):
    """Mochila de expedición de lona con el saco de dormir enrollado encima, un cazo colgado y
    las correas por los hombros."""
    CANVAS = (0.36, 0.38, 0.26); CANVAS_SH = (0.28, 0.30, 0.20); LEATHER = (0.32, 0.20, 0.10)
    ROLL = (0.50, 0.22, 0.16); TIN = (0.62, 0.62, 0.60); BUCKLE = (0.70, 0.60, 0.32)
    ch = _Chest(bd, torso)
    zb = min(ch.back.get((x, y), 0) for x in range(-7, 7) for y in range(42, 60)) - 1
    for x in range(-9, 9):                                                # cuerpo de la mochila
        for y in range(38, 60):
            for z in range(zb - 9, zb + 1):
                if (x in (-9, 8) and y in (38, 59)) or (z == zb - 9 and x in (-9, 8)): continue
                M.put(x, y, z, T, CANVAS if y < 56 else CANVAS_SH)
    for x in range(-6, 6):                                                # bolsillo
        for y in range(40, 49):
            M.put(x, y, zb - 10, T, CANVAS_SH if y != 48 else LEATHER)
    M.put(-1, 46, zb - 11, T, BUCKLE); M.put(0, 46, zb - 11, T, BUCKLE)
    for x in range(-12, 12):                                              # saco de dormir enrollado
        for y in range(59, 66):
            for z in range(zb - 8, zb):
                if (y - 62.5) ** 2 + (z - (zb - 4)) ** 2 <= 13: M.put(x, y, z, T, ROLL if x % 5 else LEATHER)
    for y in range(41, 47):                                               # cazo en el costado
        for z in range(zb - 7, zb - 2):
            M.put(9, y, z, T, TIN); M.put(10, y, z, T, TIN)
    for s in (-1, 1):                                                     # correas por delante
        _hang(M, ch, LEATHER, s * 6, s * 7, 61, 44)
        _hang(M, ch, LEATHER, s * 5, s * 6, 61, 44)
    return {CANVAS: 'lona', CANVAS_SH: 'lona', LEATHER: 'cuero', ROLL: 'lana'}


def tentaculo(M, bd, torso):
    """Un tentáculo que sale de la espalda, sube por detrás de la cabeza y cae por delante del
    hombro derecho, con ventosas por debajo. Ya no lo esconde. Pieza propia, `tail`, que cuelga
    del tronco por la raíz: en la partida se mece al andar y se retuerce solo (Player._cloth_step)."""
    SKIN = (0.30, 0.42, 0.38); SKIN_D = (0.22, 0.31, 0.29); BELLY = (0.66, 0.52, 0.56); SUCKER = (0.82, 0.66, 0.70)
    ch = _Chest(bd, torso)
    zb = min(ch.back.get((x, y), 0) for x in range(-4, 4) for y in range(44, 52)) - 1
    zf = ch.z(14, 58) + 2
    steps = 90
    for i in range(steps):
        t = i / (steps - 1)
        x = 2 + 13 * t
        y = 48 + 31 * math.sin(math.pi * t * 0.92)
        z = (zb - 3) + (zf - (zb - 3)) * t * t - 6 * math.sin(math.pi * t) * (1 - t)
        r = 4.0 * (1 - t) + 1.0
        band = int(t * 14) % 2
        for dx in range(-5, 6):
            for dy in range(-5, 6):
                for dz in range(-5, 6):
                    if dx * dx + dy * dy + dz * dz > r * r: continue
                    k = (int(round(x + dx)), int(round(y + dy)), int(round(z + dz)))
                    under = dy < -r * 0.35
                    if under: col = SUCKER if (k[0] + k[2] + k[1]) % 3 == 0 and r > 1.6 else BELLY
                    else: col = SKIN_D if band else SKIN
                    M.put(k[0], k[1], k[2], 'tail', col)
    for (x, y, z) in list(M.V):                                           # no entra en el cuerpo
        if (x, y, z) in ch.shell: M.V.pop((x, y, z))
    M.marks = {'tail': [2, 48, zb - 3]}
    M.extra_parents = {'tail': 'torso'}
    return {}


GARMENTS = {'bombin': bombin, 'casco_minero': casco_minero, 'gorro_nieve': gorro_nieve, 'chistera': chistera,
            'chaqueta_aviador': chaqueta_aviador, 'abrigo_piel': abrigo_piel,
            'botas_militares': botas_militares, 'botas_nieve': botas_nieve,
            'casco_brodie': casco_brodie, 'cinta_pelo': cinta_pelo, 'sombrero_aventurero': sombrero_aventurero,
            'boina': boina, 'sombrero_vaquero': sombrero_vaquero, 'sombrero_mujer': sombrero_mujer,
            'turbante': turbante, 'sombrero_paja': sombrero_paja,
            'gafas_ver': gafas_ver, 'gafas_nieve': gafas_nieve, 'bufanda': bufanda,
            'abrigo_nieve': abrigo_nieve, 'chubasquero': chubasquero, 'chaleco': chaleco, 'vestido': vestido,
            'bata': bata, 'botas_esquimales': botas_esquimales, 'zapatos_tacon': zapatos_tacon,
            # fase 14 (30-10-2026): cabeza
            'gorra_marinero': gorra_marinero, 'fez': fez, 'capucha_cultista': capucha_cultista, 'tiara': tiara,
            'gorra_chofer': gorra_chofer, 'sombrero_hule': sombrero_hule, 'casco_aviador': casco_aviador,
            'birrete': birrete, 'panuelo_gitana': panuelo_gitana, 'corona_algas': corona_algas,
            'fedora_ganster': fedora_ganster, 'gorro_dormir': gorro_dormir, 'casco_buzo': casco_buzo,
            # cuerpo
            'gabardina': gabardina, 'tunica_cultista': tunica_cultista, 'traje_buzo': traje_buzo,
            'uniforme_enfermera': uniforme_enfermera, 'mono_mecanico': mono_mecanico, 'esmoquin': esmoquin,
            'vestido_charleston': vestido_charleston, 'jersey_marinero': jersey_marinero, 'parka_inuit': parka_inuit,
            'sotana_exorcista': sotana_exorcista, 'capa_terciopelo': capa_terciopelo, 'uniforme_lake': uniforme_lake,
            'harapos': harapos,
            # pies
            'botas_agua': botas_agua, 'zapatos_bicolor': zapatos_bicolor, 'sandalias_calcetines': sandalias_calcetines,
            'botas_montar': botas_montar, 'raquetas_nieve': raquetas_nieve, 'zapatillas': zapatillas,
            'botas_buzo': botas_buzo, 'pies_membrana': pies_membrana,
            # complementos
            'monoculo': monoculo, 'pipa': pipa, 'collar_signo': collar_signo, 'bolsa_cartero': bolsa_cartero,
            'canana': canana, 'antifaz': antifaz, 'mascara_gas': mascara_gas, 'medico_peste': medico_peste,
            'vendas_parche': vendas_parche, 'clavel': clavel, 'panuelo_vaquero': panuelo_vaquero,
            'estetoscopio': estetoscopio, 'camara_fuelle': camara_fuelle, 'rosario': rosario,
            'ojos_innsmouth': ojos_innsmouth,
            # manos y espalda
            'guantes_cuero': guantes_cuero, 'guantes_boxeo': guantes_boxeo, 'manoplas': manoplas, 'baston': baston,
            'paraguas': paraguas, 'linterna': linterna, 'mochila': mochila, 'tentaculo': tentaculo}


def build(name, c):
    bd = body_of(c)
    M = cu.new(9100 + CHARS.index(c))
    M.keep_under = True                      # manga y tronco se solapan: los dos enteros (28-10-2026)
    fn = GARMENTS[name]
    params = inspect.signature(fn).parameters        # lo que pide cada prenda: el pelo o los ojos
    kw = {}
    if 'hair' in params: kw['hair'] = hair_of(c)
    if 'face' in params: kw['face'] = face_of(c)
    if 'torso' in params: kw['torso'] = torso_of(c)
    if 'hands' in params: kw['hands'] = hands_of(c)
    mats = fn(M, bd, **kw)
    for V in (M.V, M.under_kept()):          # faldones (hito 12.3): lo de por debajo de la cadera
        for k, v in V.items():               # cuelga de la cadera y se mueve con retraso
            if v[0] == cu.T and k[1] < cu.HIP: v[0] = 'skirt'
    materiales.texturize(M, mats)
    under = cu.new(9100 + CHARS.index(c))   # lo que tapó otra parte, con la misma textura
    under.V = {k: list(v) for k, v in M.under_kept().items()}
    materiales.texturize(under, mats)
    piv, parents = cu.pivots(bd['finish_b'], bd['finish_ax'])
    piv.update(getattr(M, 'marks', {}))      # puntos sin voxels: de dónde sale el humo de la pipa
    parents.update(getattr(M, 'extra_parents', {}))   # piezas propias de la prenda (el tentáculo)
    for part, par in getattr(M, 'extra_parents', {}).items():
        if part not in piv: piv[part] = piv[par]      # sin pivote propio: el de la parte de la que cuelga
    out = 'models/vest_%s_%s.json' % (name, c)
    return M.export(out, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25, parents=parents,
                    extra=under.V)


if __name__ == '__main__':
    for name in (sys.argv[1:] or GARMENTS):
        total = sum(build(name, c) for c in CHARS)
        print(name, total, 'voxels en', len(CHARS), 'personajes')
