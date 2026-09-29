"""Tienda de antigüedades del anciano (D-31, hito 2.13d): el decorado detrás del menú de la
tienda. Un rincón (suelo de tablas, pared del fondo y la izquierda con zócalo de madera y
papel pintado verde oscuro), dos estanterías llenas de libros y curiosidades (calaveras,
frascos que brillan, un ídolo verde, velas), un cuadro de un mar tormentoso, un reloj de
pie, una alfombra y el mostrador con el quinqué, la bola de cristal, el libro de cuentas,
la campanilla y un montón de monedas. El anciano va aparte (gen_anciano.py).
A bloques, a 32 voxels por metro; solo las cáscaras visibles. Origen: la esquina del fondo
a la izquierda, x hacia la derecha, z hacia delante.
Uso: python tools/gen_tienda_antiguedades.py
"""
import sys, os, random
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model

M = Model(S=2, seed=1926)
R = random.Random(7)
P = 'room'
W, D, HGT = 160, 100, 100                   # 5 × 3,1 × 3,1 m

PLANK = [(0.36, 0.23, 0.14), (0.32, 0.20, 0.12), (0.39, 0.25, 0.15)]
SEAM = (0.20, 0.12, 0.07)
WAINSCOT = (0.30, 0.17, 0.10); WAINSCOT_SH = (0.23, 0.13, 0.08)
PAPER = (0.15, 0.22, 0.19); PAPER_MOTIF = (0.24, 0.28, 0.18)       # rombos tenues: más claros distraían
WOOD = (0.34, 0.20, 0.11); WOOD_SH = (0.26, 0.15, 0.08); WOOD_HI = (0.44, 0.28, 0.16)
BRASS = (0.84, 0.66, 0.30); GLASS = (1.0, 0.82, 0.45); BONE = (0.86, 0.82, 0.70)
BOOKS = [(0.46, 0.12, 0.12), (0.14, 0.24, 0.38), (0.20, 0.32, 0.18), (0.50, 0.36, 0.16), (0.30, 0.16, 0.30),
         (0.60, 0.52, 0.36), (0.18, 0.16, 0.14)]
RUG = (0.42, 0.10, 0.12); RUG_B = (0.70, 0.52, 0.24); RUG_IN = (0.18, 0.12, 0.22)


def box(x0, y0, z0, x1, y1, z1, col, glow=0):
    M.vbox(x0, y0, z0, x1, y1, z1, P, col, glow=glow)


def shell(x0, y0, z0, x1, y1, z1, col):
    """Caja hueca: solo las caras que se ven (delante, arriba y los lados)."""
    box(x0, y0, z1 - 1, x1, y1, z1, col)
    box(x0, y1 - 1, z0, x1, y1, z1, col)
    box(x0, y0, z0, x0 + 1, y1, z1, col)
    box(x1 - 1, y0, z0, x1, y1, z1, col)


# ---- suelo de tablas
for z in range(0, D):
    plank = z // 7
    col = PLANK[plank % 3]
    for x in range(0, W):
        c = SEAM if z % 7 == 0 or (x + plank * 23) % 53 == 0 else col
        M.put(x, 0, z, P, c); M.put(x, 1, z, P, c)

# ---- paredes: fondo (z 0..2) e izquierda (x 0..2); zócalo y papel pintado con rombos
def wall_col(u, y):
    if y < 30: return WAINSCOT_SH if y in (29, 28) or u % 20 == 0 else WAINSCOT
    return PAPER_MOTIF if (u + y) % 16 == 0 or (u - y) % 16 == 0 else PAPER
for y in range(2, HGT):
    for x in range(0, W):
        c = wall_col(x, y)
        M.put(x, y, 0, P, c); M.put(x, y, 1, P, c)
    for z in range(2, D):
        c = wall_col(z, y)
        M.put(0, y, z, P, c); M.put(1, y, z, P, c)

# ---- estanterías con libros y curiosidades
def bookcase(x0, x1):
    z0, z1, top = 2, 16, 86
    box(x0, 2, z0, x0 + 3, top, z1, WOOD)                           # laterales
    box(x1 - 3, 2, z0, x1, top, z1, WOOD)
    box(x0, top, z0, x1, top + 4, z1 + 1, WOOD_HI)                   # cornisa
    for sy in (2, 22, 43, 64):                                      # baldas
        box(x0, sy, z0, x1, sy + 2, z1, WOOD_SH if sy == 2 else WOOD)
        x = x0 + 3
        while x < x1 - 4:
            r = R.random()
            if r < 0.72:                                           # libro
                w = R.choice((2, 2, 3))
                h = R.randint(12, 17)
                col = R.choice(BOOKS)
                box(x, sy + 2, z0 + 3, x + w, sy + 2 + h, z1 - 2, col)
                if h > 13: box(x, sy + 2 + h - 4, z1 - 3, x + w, sy + 2 + h - 3, z1 - 2, BRASS)   # rótulo
                x += w
            elif r < 0.80:                                         # calavera
                box(x + 1, sy + 2, z0 + 6, x + 6, sy + 7, z1 - 3, BONE)
                box(x + 2, sy + 4, z1 - 3, x + 3, sy + 5, z1 - 2, (0.1, 0.1, 0.1))
                box(x + 4, sy + 4, z1 - 3, x + 5, sy + 5, z1 - 2, (0.1, 0.1, 0.1))
                x += 7
            elif r < 0.88:                                         # frasco con algo que brilla
                col = R.choice(((0.45, 0.95, 0.5), (0.7, 0.45, 1.0), (0.4, 0.8, 1.0)))
                box(x + 1, sy + 2, z0 + 6, x + 5, sy + 11, z1 - 3, col, glow=1)
                box(x + 1, sy + 11, z0 + 6, x + 5, sy + 13, z1 - 3, (0.3, 0.22, 0.14))
                x += 6
            elif r < 0.93:                                         # ídolo verde
                box(x + 1, sy + 2, z0 + 6, x + 7, sy + 4, z1 - 3, (0.18, 0.16, 0.14))
                box(x + 2, sy + 4, z0 + 7, x + 6, sy + 12, z1 - 4, (0.20, 0.42, 0.28))
                box(x + 2, sy + 8, z1 - 4, x + 6, sy + 10, z1 - 3, (0.14, 0.32, 0.20))   # tentáculos de la cara
                x += 8
            else:                                                  # vela
                box(x + 1, sy + 2, z0 + 7, x + 3, sy + 9, z0 + 9, (0.90, 0.86, 0.72))
                box(x + 1, sy + 9, z0 + 7, x + 3, sy + 11, z0 + 9, GLASS, glow=1)
                x += 4
bookcase(6, 62)
bookcase(100, 156)

# ---- cuadro de un mar tormentoso, entre las estanterías
box(66, 46, 2, 96, 74, 3, BRASS)
for y in range(48, 72):
    for x in range(68, 94):
        sea = y < 58
        c = (0.10, 0.18, 0.24) if sea else (0.20, 0.22, 0.28)
        if sea and (x + y * 2) % 7 == 0: c = (0.40, 0.50, 0.55)      # espuma
        if not sea and y > 64 and 76 <= x <= 84: c = (0.55, 0.58, 0.45)   # luna tras las nubes
        M.put(x, y, 3, P, c)

# ---- reloj de pie contra la pared izquierda
shell(2, 2, 34, 13, 78, 46, WOOD_SH)
box(2, 78, 33, 14, 82, 47, WOOD_HI)
box(13, 58, 36, 14, 72, 44, (0.92, 0.88, 0.74))                     # esfera
box(13, 64, 39, 14, 65, 44, (0.1, 0.1, 0.1)); box(13, 64, 40, 14, 70, 41, (0.1, 0.1, 0.1))   # agujas
box(13, 20, 38, 14, 50, 42, (0.10, 0.08, 0.06))                     # ventana del péndulo
box(13, 26, 39, 14, 30, 41, BRASS)

# ---- alfombra delante del mostrador
for z in range(70, 96):
    for x in range(30, 130):
        edge = x < 33 or x > 126 or z < 73 or z > 92
        c = RUG_B if edge else (RUG_IN if (abs(x - 80) + abs(z - 82)) % 10 < 2 else RUG)
        M.put(x, 2, z, P, c)

# ---- mostrador (hueco) con su tapa, paneles y lo que hay encima
shell(28, 2, 50, 132, 34, 64, WOOD)
box(26, 34, 48, 134, 37, 66, WOOD_HI)                               # tapa
for x0 in range(32, 128, 24):                                      # paneles del frente
    for y in range(8, 30):
        for x in range(x0, x0 + 20):
            if x in (x0, x0 + 19) or y in (8, 29): M.put(x, y, 64, P, WOOD_SH)
# quinqué: pie de latón, depósito, tubo de cristal encendido
box(112, 37, 55, 118, 39, 61, BRASS)
box(113, 39, 56, 117, 44, 60, BRASS)
box(113, 44, 56, 117, 53, 60, GLASS, glow=1)
box(112, 53, 55, 118, 54, 61, BRASS)
# bola de cristal violeta sobre su peana
box(42, 37, 55, 48, 39, 61, BRASS)
for y in range(39, 47):
    for z in range(54, 62):
        for x in range(41, 49):
            if (x - 44.5) ** 2 + (y - 43) ** 2 + (z - 57.5) ** 2 <= 16: M.put(x, y, z, P, (0.62, 0.36, 0.95), 1)
# libro de cuentas abierto, campanilla y montón de monedas
box(70, 37, 54, 90, 38, 62, (0.88, 0.84, 0.70)); box(79, 37, 54, 81, 38, 62, (0.40, 0.26, 0.14))
for y in (38,):
    for x in range(72, 78, 2): box(x, y - 1, 56, x + 1, y, 60, (0.30, 0.26, 0.22))
box(98, 37, 58, 102, 41, 62, BRASS); box(99, 41, 59, 101, 42, 61, BRASS)
for i in range(4):
    box(124 - i % 2, 37 + i, 56, 128 - i % 2, 38 + i, 60, BRASS if i % 2 else (0.95, 0.76, 0.3))

n = M.export('models/tienda_antiguedades.json', {P: [0, 0, 0]}, jitter=0.0, pivots_in_voxels=True,
             roughness=0.85, specular=0.25)
print('tienda_antiguedades', n, 'voxels')
