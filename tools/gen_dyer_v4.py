"""Prototipo 4 de William Dyer (28-09-2026): anatomía realista con caras planas.

La referencia no usa formas redondas: son bloques de caras planas que se estrechan poco a
poco (muslo -> rodilla -> pantorrilla -> tobillo; pecho -> cintura -> cadera; brazo ->
antebrazo -> muñeca), con las aristas verticales achaflanadas. Así sale la anatomía sin
los escalones sueltos de una esfera en voxel. Cabeza algo grande (1/4 de la altura con el
gorro), manos y botas macizas.

48 voxels por metro (1,72 m = 83 voxels). Coordenadas en voxels; mira hacia +Z.
Escribe models/dyer_v4.json.
Uso: python tools/gen_dyer_v4.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model

PARKA = (0.56, 0.44, 0.29); PARKA_SH = (0.46, 0.35, 0.22)
FUR = (0.84, 0.82, 0.77)
TROUSER = (0.29, 0.30, 0.34)
BOOT = (0.37, 0.25, 0.15); SOLE = (0.13, 0.10, 0.08)
MITT = (0.33, 0.22, 0.14); MITT_SH = (0.26, 0.17, 0.11)
CAP = (0.39, 0.25, 0.15)
SKIN = (0.89, 0.69, 0.55); SKIN_SH = (0.79, 0.59, 0.46); LIP = (0.60, 0.36, 0.30); CHEEK = (0.88, 0.58, 0.48)
HAIR = (0.40, 0.30, 0.22); BEARD = (0.50, 0.40, 0.31); BEARD_SH = (0.42, 0.33, 0.25)
BROW = (0.30, 0.22, 0.16); EYE = (0.08, 0.06, 0.05); EYE_W = (0.93, 0.91, 0.87)
SCARF = (0.66, 0.19, 0.14); SCARF_SH = (0.54, 0.14, 0.11)
BELT = (0.22, 0.15, 0.10); BUCKLE = (0.84, 0.70, 0.38); TOGGLE = (0.30, 0.20, 0.12)
GREN = (0.28, 0.32, 0.24); HANDLE = (0.76, 0.62, 0.40)

M = Model(S=3, seed=1930)                    # voxel_size = 1/48 m


def slab(part, col, y0, y1, cx, cz, w0, w1, d0, d1, ch=2, over=True, zoff0=0.0, zoff1=0.0):
    """Tramo que se estrecha: en cada altura, un rectángulo de ancho w y fondo d (de w0/d0
    abajo a w1/d1 arriba) con las cuatro aristas verticales achaflanadas `ch` voxels.
    zoff desplaza el tramo adelante o atrás con la altura (pantorrilla, pecho)."""
    for y in range(y0, y1):
        t = (y - y0 + 0.5) / max(y1 - y0, 1)
        w = w0 + (w1 - w0) * t
        d = d0 + (d1 - d0) * t
        zc = cz + zoff0 + (zoff1 - zoff0) * t
        xa, xb = int(round(cx - w / 2)), int(round(cx + w / 2))
        za, zb = int(round(zc - d / 2)), int(round(zc + d / 2))
        for x in range(xa, xb):
            for z in range(za, zb):
                ex = min(x - xa, xb - 1 - x)
                ez = min(z - za, zb - 1 - z)
                if ex + ez < ch: continue                 # chaflán
                M.put(x, y, z, part, col, 0, over)


# ---------------- piernas ----------------
for s in (-1, 1):
    leg, shin = ('leg_l', 'shin_l') if s < 0 else ('leg_r', 'shin_r')
    cx = 5 * s
    slab(shin, SOLE, 0, 2, cx, 1, 9, 9, 15, 15, ch=1)                     # suela
    slab(shin, BOOT, 2, 5, cx, 1, 9, 9, 15, 14, ch=1)                      # pie con puntera
    slab(shin, BOOT, 5, 11, cx, -0.5, 9, 9, 10, 10, ch=1)                  # caña
    slab(shin, FUR, 11, 13, cx, -0.5, 10.5, 10.5, 11.5, 11.5, ch=1)        # vuelta de borreguillo
    slab(shin, TROUSER, 13, 20, cx, 0, 7, 8.5, 7.5, 8.5, ch=1, zoff0=0, zoff1=-0.5)    # tobillo -> gemelo
    slab(shin, TROUSER, 20, 27, cx, 0, 8.5, 8, 8.5, 8, ch=1, zoff0=-0.5, zoff1=0)      # gemelo -> rodilla
    slab(leg, TROUSER, 27, 41, cx * 1.04, 0, 8.5, 10.5, 8.5, 10, ch=1)                 # muslo

# ---------------- tronco ----------------
T = 'torso'
slab(T, PARKA, 38, 45, 0, 0, 24, 23, 13, 13, ch=1)                           # cadera (faldón de la parka)
slab(T, FUR, 36, 39, 0, 0, 25.5, 25.5, 14.5, 14.5, ch=1)                     # bajo de borreguillo
slab(T, PARKA, 45, 50, 0, 0, 22, 21, 12.5, 12.5, ch=1)                       # cintura
slab(T, PARKA, 50, 58, 0, 0.3, 21, 25, 12.5, 14, ch=1)                       # pecho que se abre
slab(T, PARKA, 58, 61, 0, 0.3, 25, 20, 14, 12, ch=1)                         # hombros que caen
slab(T, BELT, 44, 46, 0, 0, 22.8, 22.2, 13.2, 13.2, ch=1)                    # cinturón
slab(T, SCARF, 59, 64, 0, 0.5, 15, 13, 12, 11, ch=1)                         # bufanda al cuello
slab(T, SKIN, 62, 65, 0, 0, 8, 8, 8, 8, ch=1, over=False)                    # cuello
for x in (-8, -5):                                                           # granadas de palo
    slab(T, GREN, 45, 49, x + 1, 7.5, 3, 3, 3, 3, ch=1)
    slab(T, HANDLE, 40, 45, x + 1, 7.3, 1.5, 1.5, 1.5, 1.5, ch=0)
for y in range(46, 58):                                                      # tapeta con alamares
    M.put(0, y, M.front(0, y) or 7, T, PARKA_SH)
for y in (48, 52, 56):
    z = M.front(-1, y)
    if z is not None: M.put(-1, y, z + 1, T, TOGGLE); M.put(0, y, z + 1, T, TOGGLE)
# cola de la bufanda por la espalda (pieza propia, se balancea)
slab('scarf', SCARF, 47, 61, 3, -7.5, 5, 5, 1.5, 1.5, ch=0)
slab('scarf', SCARF_SH, 46, 47, 3, -7.5, 5, 5, 1.5, 1.5, ch=0)

# ---------------- brazos ----------------
for s in (-1, 1):
    arm, fore = ('arm_l', 'fore_l') if s < 0 else ('arm_r', 'fore_r')
    cx = 15 * s
    slab(arm, PARKA, 46, 61, cx, 0, 7, 8.5, 7.5, 8.5, ch=1)                  # brazo (hombro más ancho)
    slab(fore, PARKA, 37, 46, cx * 1.02, 0.5, 6.5, 7, 7, 7.5, ch=1)          # antebrazo
    slab(fore, FUR, 35, 38, cx * 1.02, 0.5, 8.5, 8.5, 9, 9, ch=1)            # puño de borreguillo
    # manopla en pinza, estilo LEGO: un bloque redondeado con una ranura en C abierta hacia
    # delante (se lee a cualquier giro); el interior de la ranura, más oscuro
    hx = int(round(cx * 1.02))
    slab(fore, MITT, 27, 36, hx, 0.5, 7, 7.5, 8, 8, ch=1)
    for y in range(29, 34):
        for x in range(hx - 1, hx + 2):
            for z in range(1, 6):
                M.V.pop((x, y, z), None)
        for x in (hx - 2, hx + 2):                                             # pared interior en sombra
            for z in range(1, 5):
                if (x, y, z) in M.V: M.V[(x, y, z)][1] = MITT_SH
        for x in range(hx - 1, hx + 2):
            if (x, y, 0) in M.V: M.V[(x, y, 0)][1] = MITT_SH

# ---------------- cabeza ----------------
H = 'head'
slab(H, SKIN, 64, 80, 0, 0.5, 13.5, 14.5, 14, 14.5, ch=2)                   # cabeza (mandíbula algo más estrecha)
slab(H, BEARD, 63, 65, 0, 3.5, 9, 11, 7, 8, ch=2)                            # mentón redondeado
slab(H, BEARD, 65, 70, 0, 3.5, 12, 13.5, 8, 8.5, ch=2)                        # barba (capa delante y a los lados)
slab(H, SKIN_SH, 69, 72, 0, 8, 2.5, 2.5, 2, 2, ch=0)                         # nariz
for s in (-1, 1):
    slab(H, SKIN_SH, 70, 75, 7.5 * s, 0, 1.5, 1.5, 3.5, 3.5, ch=0)           # orejas
slab(H, CAP, 77, 85, 0, 0.3, 16, 15, 16, 15, ch=1)                           # copa del gorro
slab(H, FUR, 76, 79, 0, 0.5, 17, 17, 17, 17, ch=1)                           # banda de borreguillo
for s in (-1, 1):
    slab(H, CAP, 68, 77, 7.8 * s, 0, 2, 2, 8, 9, ch=1)                       # orejeras
    slab(H, FUR, 67, 69, 7.8 * s, 0, 2.3, 2.3, 8, 8, ch=1)


def face(x, y, col, dz=0):
    z = M.front(x, y)
    if z is not None:
        M.put(x, y, z + dz, H, col)


for x, c in ((-5, EYE_W), (-4, EYE), (-3, EYE), (2, EYE), (3, EYE), (4, EYE_W)):   # ojos
    for y in (73, 74, 75): face(x, y, c)
face(-3, 75, EYE_W); face(2, 75, EYE_W)                                       # brillo
for x, y in ((-5, 76), (-4, 77), (-3, 77), (-2, 77), (1, 77), (2, 77), (3, 77), (4, 76)):   # cejas finas, caídas por fuera
    face(x, y, BROW, dz=1)
for x in (-6, -5, 4, 5):                                                      # mejillas
    face(x, 71, CHEEK)
for x in range(-3, 3): face(x, 69, BEARD_SH, dz=1)                            # bigote
for x in (-1, 0): face(x, 67, LIP)
for (x, y, z), v in M.V.items():                                              # pelo en la nuca
    if v[0] == H and v[1] == SKIN and z < -3 and y >= 66:
        v[1] = HAIR


# ---------------- color: luz arriba, algo más oscuro abajo y en la espalda ----------------
FLAT = {EYE, EYE_W, LIP, BROW, BUCKLE, TOGGLE, CHEEK}
for k, v in M.V.items():
    x, y, z = k
    if v[1] in FLAT: continue
    shade = 0.9 + 0.12 * y / 85.0
    shade *= 0.95 if z < -4 else 1.0
    n = 0.0                                                                   # sin grano: hacía rayas
    v[1] = tuple(max(0.0, min(1.0, ch * shade + n)) for ch in v[1])

piv = {'torso': [0, 40, 0], 'head': [0, 64, 0],
       'arm_l': [-15, 59, 0], 'arm_r': [15, 59, 0], 'fore_l': [-15.3, 46, 0.5], 'fore_r': [15.3, 46, 0.5],
       'leg_l': [-5, 40, 0], 'leg_r': [5, 40, 0], 'shin_l': [-5, 27, 0], 'shin_r': [5, 27, 0],
       'scarf': [3, 61, -7.5]}
parents = {'shin_l': 'leg_l', 'shin_r': 'leg_r', 'fore_l': 'arm_l', 'fore_r': 'arm_r', 'scarf': 'torso'}
n = M.export('models/dyer_v4.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25, parents=parents)
print('dyer_v4', n, 'voxels')
