"""Sala de trofeos de la Biblioteca (hito 16.28): vitrinas, peanas, la pared y el suelo de la sala,
y los trofeos de los logros grandes.

- vitrina_<cols>x<filas>: armario de madera oscura con fondo de terciopelo verde, baldas, una
  placa de latón bajo cada hueco, cornisa con el Signo Arcano y zócalo. Huecos de 20 x 23 voxels
  (0,625 x 0,72 m), a 32 voxels por metro.
- trofeo_peana: peana redonda de madera con aro de latón, para cada hueco (48 por metro).
- sala_pared y sala_suelo: friso de madera y papel pintado; tarima con alfombra.
- trofeo_copa, trofeo_copa_negra, trofeo_garra, trofeo_cofre, trofeo_retrato, trofeo_sellos,
  trofeo_candelabro, trofeo_atril, trofeo_maniqui, trofeo_medalla (48 por metro, unos 0,4 m).
Estilo 4 (tramos de caras planas, detalles pintados).
Uso: python tools/gen_trofeos.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
from cuerpo import slab, new

P = 'body'
WOOD = (0.25, 0.14, 0.08); WOOD_DK = (0.16, 0.09, 0.05); WOOD_HI = (0.36, 0.21, 0.12)
VELVET = (0.07, 0.16, 0.11); VELVET_DK = (0.045, 0.11, 0.075)
BRASS = (0.80, 0.62, 0.30); BRASS_DK = (0.56, 0.40, 0.18); BRASS_HI = (0.98, 0.84, 0.50)
GOLD = (0.95, 0.74, 0.28); GOLD_SH = (0.74, 0.52, 0.16); GOLD_HI = (1.0, 0.9, 0.55)
SILVER = (0.72, 0.74, 0.78)
OBSID = (0.09, 0.10, 0.11); OBSID_HI = (0.22, 0.25, 0.26); EERIE = (0.35, 0.95, 0.55)
PAPER = (0.86, 0.79, 0.62); PAPER_SH = (0.72, 0.64, 0.48); INK = (0.22, 0.15, 0.10)
WAX = (0.62, 0.08, 0.07); WAX_HI = (0.80, 0.18, 0.12)
CANDLE = (0.92, 0.88, 0.76); FLAME = (1.0, 0.78, 0.35)
CLOTH = (0.10, 0.10, 0.12); SHIRT = (0.90, 0.89, 0.85)
CLAW = (0.18, 0.26, 0.20); CLAW_HI = (0.30, 0.40, 0.30); BONE = (0.85, 0.80, 0.66)
VIOLET = (0.70, 0.35, 1.0)
LEATHER = (0.36, 0.14, 0.09)
SLOT_W, SLOT_H = 20, 23


def grain(M, x, y, z, base, k=0.12):
    """Veta de madera: franjas horizontales onduladas, sin bloques alineados."""
    n = M.noise(x * 0.25, y * 1.6 + math.sin(x * 0.21) * 1.2, z * 0.25, 1)
    f = 1.0 + (n - 0.5) * 2 * k
    return tuple(max(0.0, min(1.0, c * f)) for c in base)


def wood_box(M, x0, y0, z0, x1, y1, z1, base=WOOD, k=0.12):
    """Solo la cáscara: por dentro no se ve y construir la malla tardaba (hito 16.28)."""
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                if x in (x0, x1 - 1) or y in (y0, y1 - 1) or z in (z0, z1 - 1):
                    M.put(x, y, z, P, grain(M, x, y, z, base, k))


def export(M, name, rough=0.8, spec=0.3, no_bottom=True):
    n = M.export('models/%s.json' % name, {P: [0, 0, 0]}, jitter=0.0, pivots_in_voxels=True,
                 roughness=rough, specular=spec, no_bottom=no_bottom)
    print(name, n, 'voxels')


# ------------------------------------------------------------------ vitrina
def vitrina(cols, rows):
    """Frente en z = 0 (los huecos miran a +z), fondo en z = -16. Origen: centro del zócalo, en el suelo."""
    M = Model(S=2, seed=cols * 10 + rows)
    W = cols * SLOT_W
    x0, x1 = -W // 2 - 3, W // 2 + 3                 # con los costados
    D0, D1 = -16, 1
    base = 10
    top = base + rows * SLOT_H
    wood_box(M, x0 - 2, 0, D0 - 1, x1 + 2, base - 2, D1 + 2, WOOD_DK)            # zócalo
    wood_box(M, x0 - 1, base - 2, D0, x1 + 1, base, D1 + 1, WOOD)
    for x in range(x0 - 1, x1 + 1):                                             # moldura de latón
        M.put(x, base - 3, D1 + 2, P, BRASS_DK)
    for x in range(x0 - 2, x1 + 2, 6):                                          # sombras del zócalo
        for y in range(1, base - 3):
            M.put(x, y, D1 + 2, P, scale3(WOOD_DK, 0.8))
    wood_box(M, x0, base, D0, x0 + 3, top, D1, WOOD)                             # costados
    wood_box(M, x1 - 3, base, D0, x1, top, D1, WOOD)
    for x in range(x0 + 3, x1 - 3):                                             # fondo de terciopelo
        for y in range(base, top):
            n = M.noise(x, y, 0, 3)                                             # pelo del terciopelo, suave
            c = lerp3(VELVET_DK, VELVET, 0.55 + (n - 0.5) * 0.5)
            M.put(x, y, D0 + 1, P, c)
    for r in range(rows + 1):                                                   # baldas
        y = base + r * SLOT_H
        wood_box(M, x0 + 3, y - (0 if r == 0 else 1), D0 + 2, x1 - 3, y + 1, D1, WOOD_HI if r else WOOD)
        if r < rows:
            for c in range(cols):                                               # placa bajo cada hueco
                cx = -W // 2 + c * SLOT_W + SLOT_W // 2
                for x in range(cx - 4, cx + 4):
                    M.put(x, y, D1, P, BRASS if x not in (cx - 4, cx + 3) else BRASS_DK)
                    M.put(x, y - 1, D1, P, BRASS_DK) if r else None
    # marco delantero (las puertas: el cristal lo pone el juego)
    wood_box(M, x0, top, D0, x1, top + 2, D1 + 1, WOOD_DK)
    for x in (x0 + 3, x1 - 4):
        for y in range(base, top):
            M.put(x, y, D1, P, WOOD_DK)
    # cornisa con dentículos y el Signo Arcano en latón
    wood_box(M, x0 - 1, top + 2, D0 - 1, x1 + 1, top + 5, D1 + 2, WOOD)
    for x in range(x0 - 1, x1 + 1, 3):
        M.put(x, top + 2, D1 + 2, P, WOOD_DK)
    wood_box(M, x0 - 3, top + 5, D0 - 2, x1 + 3, top + 7, D1 + 3, WOOD_DK)
    for x in range(x0 - 3, x1 + 3):
        M.put(x, top + 6, D1 + 3, P, BRASS_DK)
    cr = top + 7
    for y in range(0, 9):                                                       # frontón bajo
        hw = 14 - y * 1.4
        for x in range(int(-hw), int(hw) + 1):
            M.put(x, cr + y, D1 - 1, P, grain(M, x, cr + y, 0, WOOD))
            M.put(x, cr + y, D1 - 2, P, WOOD_DK)
    for i in range(5):                                                          # Signo Arcano: estrella y ojo
        a = math.pi / 2 + i * 2 * math.pi / 5
        b = math.pi / 2 + (i + 2) * 2 * math.pi / 5
        for t in range(9):
            u = t / 8
            x = round(math.cos(a) * 3.5 * (1 - u) + math.cos(b) * 3.5 * u)
            y = round(math.sin(a) * 3.5 * (1 - u) + math.sin(b) * 3.5 * u)
            M.put(x, cr + 4 + y, D1, P, BRASS_HI if y >= 0 else BRASS)
    M.put(0, cr + 4, D1, P, (0.35, 0.95, 0.55), 1)
    export(M, 'vitrina_%dx%d' % (cols, rows), 0.7, 0.35)
    return M


def lerp3(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def scale3(c, k):
    return tuple(max(0.0, min(1.0, v * k)) for v in c)


# ------------------------------------------------------------------ peana
M = new(1)
slab(M, P, WOOD_DK, 0, 2, 0, 0, 18, 18, 18, 18, ch=5)
slab(M, P, WOOD, 2, 4, 0, 0, 15, 15, 15, 15, ch=4)
slab(M, P, BRASS_DK, 4, 5, 0, 0, 15, 15, 15, 15, ch=4)
slab(M, P, WOOD_HI, 4, 5, 0, 0, 13, 13, 13, 13, ch=4)
export(M, 'trofeo_peana', 0.7, 0.3)

# ------------------------------------------------------------------ sala
M = Model(S=1, seed=5)                          # 16 por metro: es el fondo y la cámara no se acerca
WALL_W, WALL_H = 240, 75
PAPERW = (0.12, 0.10, 0.09); PAPERW2 = (0.14, 0.115, 0.10); DAMASK = (0.21, 0.16, 0.10)
for x in range(-WALL_W // 2, WALL_W // 2):
    for y in range(0, WALL_H):
        if y < 17:                                                              # friso de madera
            c = grain(M, x * 2, y * 2, 0, WOOD_DK if (x % 20) == 0 or y in (0, 16) else WOOD, 0.1)
            if y == 15: c = BRASS_DK
        else:                                                                   # papel pintado de rombos
            u, v = (x % 10) - 5, ((y - 17) % 14) - 7
            c = DAMASK if abs(abs(u) * 7 / 5 + abs(v) - 5.5) < 0.75 else (PAPERW2 if (x // 10 + (y - 17) // 14) % 2 else PAPERW)
            if y > WALL_H - 3: c = grain(M, x * 2, y * 2, 0, WOOD_DK, 0.1)
        M.put(x, y, 0, P, c)
export(M, 'sala_pared', 0.9, 0.2)

M = Model(S=1, seed=6)
RUG = (0.30, 0.07, 0.06); RUG_DK = (0.18, 0.05, 0.04); RUG_GOLD = (0.62, 0.44, 0.18)
for x in range(-WALL_W // 2, WALL_W // 2):
    for z in range(0, 55):
        c = grain(M, z * 6, x * 0.4 + (z // 4) * 13, 0, WOOD if (z // 4) % 2 else WOOD_DK, 0.15)
        if (x + (z // 4) * 19) % 30 == 0: c = WOOD_DK
        if abs(x) < 100 and 4 < z < 35:                                         # alfombra
            e = min(100 - abs(x), z - 4, 35 - z)
            c = RUG_GOLD if e == 2 else (RUG_DK if e < 2 or (x + z) % 7 == 0 else RUG)
        M.put(x, 0, z, P, c)
export(M, 'sala_suelo', 0.95, 0.15)

for cols, rows in ((7, 3), (6, 3), (4, 3)):
    vitrina(cols, rows)


# ------------------------------------------------------------------ trofeos
def copa(name, body, sh, hi, glow_col=None):
    M = new(10)
    slab(M, P, WOOD_DK, 0, 3, 0, 0, 14, 14, 14, 14, ch=3)
    slab(M, P, sh, 3, 5, 0, 0, 10, 9, 10, 9, ch=2)
    slab(M, P, body, 5, 11, 0, 0, 4, 4, 4, 4, ch=1)
    slab(M, P, hi, 8, 9, 0, 0, 6, 6, 6, 6, ch=1)
    slab(M, P, body, 11, 21, 0, 0, 8, 16, 8, 16, ch=3)
    slab(M, P, hi, 20, 21, 0, 0, 16, 16, 16, 16, ch=3)
    slab(M, P, sh, 20, 21, 0, 0, 12, 12, 12, 12, ch=2)                          # el hueco de dentro
    for s in (-1, 1):                                                           # asas
        for t in range(12):
            a = math.pi * t / 11
            x = s * (8 + round(math.sin(a) * 4))
            y = 13 + round(-math.cos(a) * 4 + 4)
            M.put(x, y, 0, P, body); M.put(x, y, -1, P, body)
    for y in range(13, 19):                                                     # escudo grabado
        for x in range(-3, 3):
            if abs(x + 0.5) + max(0, y - 17) * 1.5 < 3.2:
                z = M.front(x, y)
                if z is not None: M.put(x, y, z, P, sh if not glow_col else glow_col, 1 if glow_col else 0)
    for x in range(-6, 6):                                                      # placa del pie
        M.put(x, 1, M.front(x, 1) or 7, P, BRASS)
    export(M, name, 0.35, 0.8)


copa('trofeo_copa', GOLD, GOLD_SH, GOLD_HI)
copa('trofeo_copa_negra', OBSID, scale3(OBSID, 0.6), OBSID_HI, EERIE)

# frasco de formol con un tentáculo (cazador de pesadillas)
M = new(11)
JAR = (0.46, 0.58, 0.42); JAR_DK = (0.32, 0.44, 0.31); JAR_HI = (0.70, 0.80, 0.62)
TENT = (0.20, 0.17, 0.22); SUCK = (0.62, 0.48, 0.55)
slab(M, P, WOOD_DK, 0, 2, 0, 0, 16, 16, 16, 16, ch=4)
slab(M, P, JAR, 2, 19, 0, 0, 13, 13, 13, 13, ch=4)
slab(M, P, JAR_DK, 19, 20, 0, 0, 10, 10, 10, 10, ch=3)                         # cuello
slab(M, P, BRASS_DK, 20, 23, 0, 0, 12, 12, 12, 12, ch=3)                       # tapa
slab(M, P, BRASS, 22, 23, 0, 0, 10, 10, 10, 10, ch=3)
for y in range(2, 19):                                                         # el tentáculo que se enrosca, visto a través del cristal
    for x in range(-7, 7):
        z = M.front(x, y, 20, -20)
        if z is None: continue
        cx = math.sin(y * 0.42) * 3.2
        w = 3.0 - (y - 2) * 0.09
        if abs(x + 0.5 - cx) < w:
            M.put(x, y, z, P, SUCK if (y % 3 == 0 and abs(x + 0.5 - cx) > w - 1.1) else TENT)
for y in range(4, 17, 4):                                                      # reflejo del cristal
    z = M.front(-5, y, 20, -20)
    if z is not None: M.put(-5, y, z, P, JAR_HI)
    z = M.front(-5, y + 1, 20, -20)
    if z is not None: M.put(-5, y + 1, z, P, JAR_HI)
for x in range(-3, 3):                                                         # etiqueta
    for y in (5, 6):
        z = M.front(x, y, 20, -20)
        if z is not None: M.put(x, y, z, P, PAPER if y == 6 or x % 2 else INK)
export(M, 'trofeo_frasco', 0.25, 0.8)

# cofre arcano
M = new(12)
slab(M, P, WOOD, 0, 9, 0, 0, 18, 18, 12, 12, ch=1)
for y in range(9, 14):
    t = (y - 9) / 4
    slab(M, P, WOOD_HI, y, y + 1, 0, 0, 18, 18, 12 * math.sqrt(max(0.0, 1 - t * t * 0.7)), 12 * math.sqrt(max(0.0, 1 - t * t * 0.7)), ch=1)
for bx in (-6, 5):                                                             # flejes de latón
    for y in range(0, 14):
        for z in range(-7, 8):
            if M.has((bx, y, z)) and M.exposed((bx, y, z)):
                M.put(bx, y, z, P, BRASS_DK)
for x in range(-9, 9):                                                         # junta que brilla
    z = M.front(x, 9)
    if z is not None: M.put(x, 9, z, P, VIOLET, 1)
for z in range(-6, 6):
    for xs in (-9, 8):
        if M.has((xs, 9, z)): M.put(xs, 9, z, P, VIOLET, 1)
slab(M, P, BRASS, 6, 11, 0, 6, 4, 4, 1, 1, ch=0)                               # cerradura
M.put(0, 8, 7, P, OBSID)
export(M, 'trofeo_cofre', 0.6, 0.4)

# retrato de la expedición en su caballete
M = new(13)
slab(M, P, GOLD_SH, 2, 24, 0, 0, 18, 18, 2, 2, ch=0)
slab(M, P, GOLD, 3, 23, 0, 1, 16, 16, 1, 1, ch=0)
for x in range(-6, 6):
    for y in range(5, 21):
        c = (0.55, 0.45, 0.32) if y > 12 else (0.42, 0.33, 0.22)
        M.put(x, y, 1, P, c)
for i, fx in enumerate((-5, -3, -1, 1, 3, 5)):                                 # seis de pie y uno sentado delante
    yb = 7
    h = 6 + (i * 5) % 3
    for y in range(yb, yb + h):
        M.put(fx, y, 1, P, (0.16, 0.12, 0.08))
        if y < yb + h - 2: M.put(fx + (1 if fx < 0 else -1), y, 1, P, (0.24, 0.18, 0.12)) if i in (1, 4) else None
    M.put(fx, yb + h, 1, P, (0.85, 0.72, 0.55))                                 # caras claras
for y in range(5, 9): M.put(0, y, 1, P, (0.16, 0.12, 0.08))
M.put(0, 9, 1, P, (0.85, 0.72, 0.55))
for x in (-6, 5):                                                              # patas del caballete
    for y in range(0, 6): M.put(x, y, -2 + (y // 3), P, WOOD_DK)
for y in range(0, 14): M.put(0, y, -2 - (13 - y) // 3, P, WOOD_DK)
export(M, 'trofeo_retrato', 0.5, 0.6)

# los tres sellos sobre el pergamino
M = new(14)
slab(M, P, WOOD_DK, 0, 2, 0, 0, 20, 20, 10, 10, ch=2)
slab(M, P, PAPER, 2, 22, 0, -1, 15, 15, 1, 1, ch=0, zoff0=1, zoff1=-3)
for y in range(8, 20, 2):
    for x in range(-5, 6):
        if (x * 7 + y * 3) % 5:
            z = M.front(x, y)
            if z is not None: M.put(x, y, z, P, INK if (x + y) % 3 else PAPER_SH)
for sx in (-5, 0, 5):
    for y in range(2, 7):
        for x in range(sx - 2, sx + 3):
            if (x - sx) ** 2 + (y - 4.5) ** 2 <= 5.5:
                M.put(x, y, 2, P, WAX if (x - sx) ** 2 + (y - 4.5) ** 2 > 1.5 else WAX_HI)
                M.put(x, y, 1, P, WAX)
export(M, 'trofeo_sellos', 0.7, 0.3)

# candelabro de siete velas
M = new(15)
slab(M, P, BRASS_DK, 0, 2, 0, 0, 12, 12, 12, 12, ch=3)
slab(M, P, BRASS, 2, 12, 0, 0, 3, 3, 3, 3, ch=0)
for k, dx in enumerate((-9, -6, -3, 0, 3, 6, 9)):
    h = 12 + (0 if dx == 0 else round(abs(dx) * 0.3))
    if dx:
        for t in range(abs(dx) + 1):                                           # brazos en arco
            x = int(math.copysign(t, dx))
            y = 9 + round((t / abs(dx)) ** 2 * (h - 9))
            M.put(x, y, 0, P, BRASS)
        for y in range(9 + 0, h): M.put(dx, y, 0, P, BRASS) if y > h - 3 else None
    M.put(dx, h, 0, P, BRASS_HI)
    for y in range(h + 1, h + 6): M.put(dx, y, 0, P, CANDLE)
    M.put(dx, h + 6, 0, P, FLAME, 1)
    M.put(dx, h + 7, 0, P, (1.0, 0.92, 0.6), 1)
export(M, 'trofeo_candelabro', 0.4, 0.7)

# atril con el libro abierto
M = new(16)
slab(M, P, WOOD_DK, 0, 2, 0, 0, 12, 12, 10, 10, ch=2)
slab(M, P, WOOD, 2, 14, 0, 0, 4, 4, 4, 4, ch=1)
for y in range(14, 21):                                                        # tablero inclinado
    zc = 1 - (y - 14)
    for x in range(-9, 9):
        M.put(x, y, zc, P, grain(M, x, y, 0, WOOD))
        M.put(x, y, zc - 1, P, WOOD_DK)
for y in range(15, 22):                                                        # libro abierto: dos páginas lisas
    zc = 2 - (y - 15)
    for x in range(-8, 8):
        edge = x in (-8, 7) or y == 15
        gutter = x in (-1, 0)
        c = LEATHER if edge else (PAPER_SH if gutter else PAPER)
        if not edge and not gutter and y % 2 == 0 and 1 <= abs(x + 0.5) <= 6 and (x * 3 + y) % 7: c = INK
        M.put(x, y, zc, P, c)
for y in range(10, 16): M.put(0, y, 3, P, WAX)                                 # cinta
export(M, 'trofeo_atril', 0.7, 0.3)

# maniquí de punta en blanco: frac, pechera estrecha, pajarita y pañuelo
M = new(17)
slab(M, P, WOOD_DK, 0, 2, 0, 0, 10, 10, 10, 10, ch=3)
slab(M, P, WOOD, 2, 8, 0, 0, 2, 2, 2, 2, ch=0)
slab(M, P, CLOTH, 8, 22, 0, 0, 9, 13, 6, 8, ch=3)
slab(M, P, CLOTH, 20, 22, 0, 0, 15, 15, 8, 8, ch=3)                            # hombros
slab(M, P, WOOD, 22, 25, 0, 0, 3, 3, 3, 3, ch=0)                               # cuello del maniquí
for y in range(13, 22):                                                        # pechera blanca estrecha
    hw = 0.5 + (y - 13) * 0.22
    for x in range(-int(hw + 0.5), int(hw + 0.5) + 1):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z, P, SHIRT)
for y in range(12, 22):                                                        # solapas de raso, más claras
    for x in (-3, 2):
        xx = x - (1 if x < 0 else -1) * (21 - y) // 4
        z = M.front(xx, y)
        if z is not None and M.V[(xx, y, z)][1] == CLOTH: M.put(xx, y, z, P, (0.2, 0.2, 0.23))
zt = M.front(0, 21)
for x in (-2, -1, 0, 1):                                                       # pajarita: una pieza
    M.put(x, 21, (zt or 4) + 1, P, (0.05, 0.05, 0.06))
z = M.front(4, 18)                                                             # pañuelo en el bolsillo
if z is not None:
    for x in (3, 4): M.put(x, 18, z, P, SHIRT)
    M.put(4, 19, z, P, SHIRT)
export(M, 'trofeo_maniqui', 0.8, 0.3)

# medalla sobre un cojín de terciopelo
M = new(18)
slab(M, P, WOOD_DK, 0, 2, 0, 0, 16, 16, 10, 10, ch=2)
slab(M, P, (0.42, 0.06, 0.08), 2, 22, 0, -2, 14, 14, 3, 3, ch=2, zoff0=1, zoff1=-2)
for y in range(12, 20):                                                        # cinta de dos colores
    for x in (-2, -1, 0, 1):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z + 1, P, (0.1, 0.2, 0.5) if x < 0 else (0.85, 0.85, 0.8))
for y in range(5, 13):
    for x in range(-4, 4):
        d = (x + 0.5) ** 2 + (y - 8.5) ** 2
        if d <= 14:
            z = M.front(x, y)
            if z is not None: M.put(x, y, z + 1, P, GOLD_HI if d < 3 else (GOLD if d < 9 else GOLD_SH))
export(M, 'trofeo_medalla', 0.4, 0.7)
