"""Prototipo 3 de William Dyer (28-09-2026): menos cuadrado, anatomía más real.

Pedido: voxel 3D de calidad, cabeza algo grande, pero cuerpo con estructura realista y no
a bloques "tipo Minecraft". Se modela con volúmenes redondeados (superelipsoides de
p≈2,5, que dan caras casi planas sin escalones sueltos, y cápsulas que se estrechan):
hombros y pecho redondeados, cintura, cadera, muslos y pantorrillas que se afinan, codos y
rodillas, manoplas y botas redondeadas. Los detalles (cara, botones, bolsillos, cinturón)
se pintan sobre la superficie; solo son relieve las capas grandes (bufanda, borreguillo,
nariz, barba, orejeras).

A 48 voxels por metro (S=3): a 32, un brazo redondeado de 3-4 voxels de ancho sale en
escalones sueltos. Solo hay hasta cuatro jugadores en pantalla, así que el coste es bajo. Piezas articuladas como los humanos del
juego (torso, cabeza, brazos, antebrazos, muslos, espinillas y bufanda).
Escribe models/dyer_v3.json.
Uso: python tools/gen_dyer_v3.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

PARKA = (0.56, 0.44, 0.29); PARKA_SH = (0.46, 0.35, 0.22)
FUR = (0.84, 0.82, 0.77)
TROUSER = (0.29, 0.30, 0.34)
BOOT = (0.37, 0.25, 0.15); SOLE = (0.13, 0.10, 0.08)
MITT = (0.33, 0.22, 0.14)
CAP = (0.39, 0.25, 0.15)
SKIN = (0.89, 0.69, 0.55); SKIN_SH = (0.80, 0.60, 0.47); LIP = (0.62, 0.38, 0.32)
HAIR = (0.42, 0.32, 0.24); BEARD = (0.50, 0.40, 0.31)
BROW = (0.30, 0.22, 0.16); EYE = (0.08, 0.06, 0.05); EYE_W = (0.93, 0.91, 0.87)
SCARF = (0.66, 0.19, 0.14); SCARF_SH = (0.54, 0.14, 0.11)
BELT = (0.22, 0.15, 0.10); BUCKLE = (0.84, 0.70, 0.38); TOGGLE = (0.30, 0.20, 0.12)
GREN = (0.28, 0.32, 0.24); HANDLE = (0.76, 0.62, 0.40)

M = Model(S=3, seed=1930)
G = 27.5 / 26.1                             # escala para que mida 1,72 m (27,5 ub)
W = 1.22                                    # grosor de brazos y piernas


def gs(*v):
    return [x * G for x in v]


_sell, _ell, _capsule = M.sell, M.ell, M.capsule
M.sell = lambda cx, cy, cz, rx, ry, rz, part, col, p=3.0, over=True, glow=0: _sell(*gs(cx, cy, cz, rx, ry, rz), part, col, p=p, over=over, glow=glow)
M.ell = lambda cx, cy, cz, rx, ry, rz, part, col, over=True, glow=0: _ell(*gs(cx, cy, cz, rx, ry, rz), part, col, over=over, glow=glow)
M.capsule = lambda a, b, r0, r1, part, col, over=True: _capsule(tuple(gs(*a)), tuple(gs(*b)), r0 * G * W, r1 * G * W, part, col, over=over)
P = 2.5                                     # superelipsoide: redondeado, sin escalones sueltos

# ---------------- piernas (en ub: 1 ub = 1/16 m) ----------------
for s in (-1, 1):
    leg, shin = ('leg_l', 'shin_l') if s < 0 else ('leg_r', 'shin_r')
    x = 1.45 * s
    M.sell(x, 0.55, 0.45, 0.95, 0.6, 1.55, shin, BOOT, p=P)               # pie de la bota, puntera adelante
    M.sell(x, 0.18, 0.45, 1.0, 0.2, 1.6, shin, SOLE, p=3.0)               # suela
    M.capsule((x, 1.0, 0.0), (x, 2.6, 0.0), 0.9, 0.85, shin, BOOT)       # caña
    M.sell(x, 2.9, 0.0, 1.05, 0.35, 1.05, shin, FUR, p=P)                 # vuelta de borreguillo
    M.capsule((x, 3.2, 0.0), (x, 7.2, 0.05), 0.72, 0.92, shin, TROUSER)  # pantorrilla (más gruesa arriba)
    M.capsule((x, 7.4, 0.05), (x * 0.96, 12.2, 0.0), 0.95, 1.2, leg, TROUSER)   # muslo

# ---------------- tronco: cadera, cintura, pecho y hombros, con la parka ----------------
T = 'torso'
M.sell(0, 12.3, 0.0, 2.55, 1.35, 1.65, T, PARKA, p=P)                    # cadera
M.sell(0, 14.4, 0.0, 2.35, 1.6, 1.55, T, PARKA, p=P)                     # cintura (más estrecha)
M.sell(0, 17.4, 0.12, 2.85, 2.3, 1.8, T, PARKA, p=P)                     # pecho
for s in (-1, 1):
    M.ell(2.75 * s, 19.1, 0.0, 1.05, 0.95, 1.1, T, PARKA)               # hombros redondeados
M.sell(0, 11.5, 0.0, 2.75, 0.55, 1.85, T, FUR, p=P)                      # bajo de borreguillo
M.capsule((0, 19.6, -0.2), (0, 20.6, 0.0), 0.72, 0.72, T, SKIN)         # cuello
M.sell(0, 20.1, 0.1, 1.65, 0.75, 1.55, T, SCARF, p=P)                    # bufanda al cuello
# granadas de palo en el cinturón (capas)
for x in (-1.9, -1.2):
    M.sell(x, 13.9, 1.72, 0.3, 0.42, 0.3, T, GREN, p=P)
    M.capsule((x, 12.6, 1.72), (x, 13.5, 1.72), 0.12, 0.12, T, HANDLE)

# cola de la bufanda por la espalda (pieza propia, se balancea)
M.sell(0.75, 17.3, -1.95, 0.55, 2.1, 0.22, 'scarf', SCARF, p=3.0)

# ---------------- brazos ----------------
for s in (-1, 1):
    arm, fore = ('arm_l', 'fore_l') if s < 0 else ('arm_r', 'fore_r')
    M.capsule((3.3 * s, 19.0, 0.0), (3.55 * s, 15.3, 0.05), 0.95, 0.82, arm, PARKA)     # brazo
    M.capsule((3.55 * s, 15.1, 0.05), (3.7 * s, 12.0, 0.25), 0.8, 0.74, fore, PARKA)    # antebrazo
    M.sell(3.7 * s, 11.8, 0.25, 0.95, 0.35, 0.95, fore, FUR, p=P)                       # puño de borreguillo
    M.sell(3.72 * s, 10.75, 0.35, 0.62, 0.85, 0.72, fore, MITT, p=P)                   # manopla
    M.ell(3.35 * s, 11.0, 0.95, 0.28, 0.45, 0.3, fore, MITT)                            # pulgar

# ---------------- cabeza algo grande, redondeada ----------------
H = 'head'
M.sell(0, 22.9, 0.15, 2.0, 2.3, 2.05, H, SKIN, p=2.4)
M.sell(0, 21.6, 0.95, 1.7, 1.15, 1.35, H, BEARD, p=2.4)                  # barba (capa)
M.ell(0, 22.55, 2.15, 0.36, 0.5, 0.4, H, SKIN_SH)                        # nariz
for s in (-1, 1):
    M.ell(2.0 * s, 22.8, 0.1, 0.3, 0.55, 0.42, H, SKIN_SH)             # orejas
# gorro de trampero: copa, banda de borreguillo y orejeras
M.sell(0, 24.6, 0.05, 2.3, 1.35, 2.35, H, CAP, p=P)
M.sell(0, 23.95, 0.1, 2.45, 0.42, 2.5, H, FUR, p=3.0)
for s in (-1, 1):
    M.sell(2.25 * s, 22.4, 0.15, 0.3, 1.2, 1.1, H, CAP, p=P)
    M.sell(2.25 * s, 21.3, 0.15, 0.34, 0.25, 1.1, H, FUR, p=3.0)


# ---------------- detalles pintados sobre la superficie ----------------
def V(u):
    """De unidades base (ub, sin escalar) a voxels."""
    return int(math.floor(u * G * M.S))


def paint_front(xu, yu, col, zmin=-90, parts=None):
    """Pinta el voxel más adelantado de la columna en (xu, yu) ub."""
    x, y = V(xu), V(yu)
    z = M.front(x, y, zmax=90, zmin=zmin)
    if z is not None and (parts is None or M.V[(x, y, z)][0] in parts):
        M.V[(x, y, z)][1] = col


def area(xu0, xu1, yu0, yu1, col, parts):
    for x in range(V(xu0), V(xu1)):
        for y in range(V(yu0), V(yu1)):
            paint_front(x / (G * M.S) + 1e-6, y / (G * M.S) + 1e-6, col, parts=parts)


# cara: ojos con brillo, cejas pobladas, boca (dos ojos simétricos a los lados de la nariz)
area(-1.45, -1.0, 22.95, 23.55, EYE_W, (H,)); area(-1.0, -0.55, 22.95, 23.55, EYE, (H,))
area(0.55, 1.0, 22.95, 23.55, EYE, (H,)); area(1.0, 1.45, 22.95, 23.55, EYE_W, (H,))
area(-1.6, -0.45, 23.7, 24.05, BROW, (H,)); area(0.45, 1.6, 23.7, 24.05, BROW, (H,))
area(-0.55, 0.55, 21.35, 21.65, LIP, (H,))
# pelo en la nuca bajo el gorro
for (x, y, z), v in M.V.items():
    if v[0] == H and v[1] == SKIN and z < -V(0.4) and V(21.0) <= y <= V(24.0):
        v[1] = HAIR
# parka: cinturón, hebilla, tapeta con alamares y bolsillos del pecho
for (x, y, z), v in M.V.items():
    if v[0] == T and v[1] == PARKA and V(13.0) <= y < V(13.7):
        v[1] = BELT
area(-0.45, 0.45, 13.0, 13.7, BUCKLE, (T,))
area(-0.15, 0.2, 13.7, 19.0, PARKA_SH, (T,))
for yu in (15.0, 16.6, 18.1):
    area(-0.6, -0.15, yu, yu + 0.35, TOGGLE, (T,))
for xu0 in (-2.2, 0.9):
    area(xu0, xu0 + 1.3, 16.5, 17.8, PARKA_SH, (T,))


# ---------------- color: luz arriba, sombra abajo y en la espalda, variación suave ----------------
FLAT = {EYE, EYE_W, LIP, BROW, BUCKLE, TOGGLE}


def paint(k, part, c):
    x, y, z = k
    if c in FLAT: return None
    shade = 0.9 + 0.12 * min(1.0, y / (27.5 * G * M.S))
    shade *= 0.95 if z < -V(0.5) else 1.0
    n = (M.noise(x, y, z, 5.0) - 0.5) * 0.035
    return tuple(max(0.0, min(1.0, ch * shade + n)) for ch in c)
M.paint(paint)

piv0 = {'torso': [0, 12.2, 0], 'head': [0, 20.6, 0],
       'arm_l': [-3.3, 19.0, 0], 'arm_r': [3.3, 19.0, 0], 'fore_l': [-3.55, 15.2, 0.05], 'fore_r': [3.55, 15.2, 0.05],
       'leg_l': [-1.45, 12.2, 0], 'leg_r': [1.45, 12.2, 0], 'shin_l': [-1.45, 7.3, 0.05], 'shin_r': [1.45, 7.3, 0.05],
       'scarf': [0.75, 19.4, -1.95]}
piv = {k: gs(*v) for k, v in piv0.items()}
parents = {'shin_l': 'leg_l', 'shin_r': 'leg_r', 'fore_l': 'arm_l', 'fore_r': 'arm_r', 'scarf': 'torso'}
n = M.export('models/dyer_v3.json', piv, jitter=0.0, roughness=0.9, specular=0.25, parents=parents)
print('dyer_v3', n, 'voxels')
