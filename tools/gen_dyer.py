"""William Dyer, geólogo de la expedición Miskatonic (1930). Personaje jugable.

Diseño a bloques limpios ("Minecraft mejorado"): volúmenes rectos con las aristas
suavizadas, casi sin relieve, y los detalles pintados sobre superficies planas.
La cara se dibuja sobre el plano frontal de la cabeza, sin volumen.
Coordenadas en voxels (32 por metro), el modelo mira hacia +Z y mide 1,72 m.

Parka de lona con ribete de piel, gorro de piel con orejeras, bufanda roja,
cinturón con dos granadas de palo, pantalón de lana, manoplas y botas.
Uso: python tools/gen_dyer.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale
import humano as hu

M = Model(S=2, seed=1930)

PARKA = (0.56, 0.44, 0.29); PARKA_SH = (0.49, 0.38, 0.25)
FUR = (0.80, 0.79, 0.75); FUR_SH = (0.71, 0.70, 0.67)      # borreguillo gris claro
TROUSER = (0.27, 0.28, 0.31); TROUSER_SH = (0.23, 0.24, 0.27)
BOOT = (0.33, 0.23, 0.15); SOLE = (0.14, 0.10, 0.08)
MITT = (0.30, 0.21, 0.14)
CAP = (0.36, 0.23, 0.15)
SKIN = (0.88, 0.68, 0.54); SKIN_SH = (0.79, 0.59, 0.47); CHEEK = (0.87, 0.58, 0.49)
HAIR = (0.44, 0.37, 0.31)
BEARD = (0.54, 0.47, 0.40); BROW = (0.36, 0.29, 0.23); EYE = (0.10, 0.08, 0.07); MOUTH = (0.32, 0.22, 0.18)
SCARF = (0.64, 0.18, 0.14); SCARF_SH = (0.54, 0.14, 0.11)
BELT = (0.22, 0.15, 0.10); BUCKLE = (0.80, 0.68, 0.40); TOGGLE = (0.30, 0.20, 0.12)
GREN = (0.28, 0.32, 0.24); GREN_SH = (0.20, 0.23, 0.17); HANDLE = (0.76, 0.62, 0.40)      # madera clara: sobre la parka parda no se leía

box = M.vbox

# ---------------- PIERNAS Y BOTAS ----------------
for s, p in ((-1, 'leg_l'), (1, 'leg_r')):
    x0, x1 = (-7, -1) if s < 0 else (1, 7)
    box(x0, 6, -3, x1, 25, 3, p, TROUSER)                 # pernera
    box(x0, 2, -3, x1, 6, 3, p, BOOT)                     # caña de la bota
    box(x0, 0, -3, x1, 2, 5, p, BOOT)                     # pie
    box(x0, 0, -3, x1, 1, 5, p, SOLE)                     # suela
    box(x0, 5, -3, x1, 7, 3, p, FUR)                      # vuelta de piel
    M.bevel(p, x0, x1, -3, 3, 2, 25)

# ---------------- TORSO: PARKA ----------------
T = 'torso'
box(-9, 22, -5, 9, 42, 5, T, PARKA)
M.bevel(T, -9, 9, -5, 5, 22, 42)
for y, cut in ((40, 1), (41, 2)):                         # hombros caídos
    for x in list(range(-9, -9 + cut)) + list(range(9 - cut, 9)):
        for z in range(-5, 5):
            M.V.pop((x, y, z), None)
box(-9, 22, -5, 9, 24, 5, T, FUR, over=True)             # ribete del bajo
M.bevel(T, -9, 9, -5, 5, 22, 24)
box(-9, 29, -5, 9, 31, 5, T, BELT)                        # cinturón
M.bevel(T, -9, 9, -5, 5, 29, 31)
box(-1, 29, 4, 1, 31, 5, T, BUCKLE)                       # hebilla
for y in range(24, 29): box(-1, y, 4, 1, y + 1, 5, T, PARKA_SH)        # tapeta
for y in range(31, 41): box(-1, y, 4, 1, y + 1, 5, T, PARKA_SH)
for y in (33, 36, 39): box(-1, y, 4, 1, y + 1, 5, T, TOGGLE)           # botones de madera
for x0 in (-7, 3):                                        # bolsillos del pecho, pintados
    box(x0, 33, 4, x0 + 4, 37, 5, T, PARKA_SH)
    box(x0, 36, 4, x0 + 4, 37, 5, T, scale(PARKA_SH, 0.85))
box(-6, 41, -4, 6, 44, 4, T, SCARF)                       # bufanda
box(-6, 41, 3, 6, 42, 4, T, SCARF_SH)
# Granadas de palo (Stielhandgranate) colgadas del cinturón (único relieve: un voxel):
# cabeza de lata verde oscura arriba y mango de madera hacia abajo
for x in (-8, -5):
    box(x, 31, 5, x + 2, 34, 6, T, GREN)
    box(x, 34, 5, x + 2, 35, 6, T, GREN_SH)
    box(x, 25, 5, x + 1, 31, 6, T, HANDLE)

# ---------------- BRAZOS ----------------
for s, p in ((-1, 'arm_l'), (1, 'arm_r')):
    x0, x1 = (-14, -9) if s < 0 else (9, 14)
    box(x0, 27, -3, x1, 41, 3, p, PARKA)                  # manga
    box(x0, 25, -3, x1, 27, 3, p, FUR)                    # puño de piel
    M.bevel(p, x0, x1, -3, 3, 25, 41)
    hu.lego_hand(M, p, x0 + 1 if s < 0 else x0, MITT)     # manopla en pinza, estilo Lego
    for z in range(-3, 3):                                # hombro redondeado
        M.V.pop((x1 - 1 if s > 0 else x0, 40, z), None)

# ---------------- CABEZA ----------------
H = 'head'
box(-5, 43, -5, 5, 51, 5, H, SKIN)
M.bevel(H, -5, 5, -5, 5, 43, 51)
box(-6, 50, -6, 6, 55, 6, H, CAP)                         # gorro de piel
M.bevel(H, -6, 6, -6, 6, 50, 55)
box(-6, 50, 5, 6, 52, 6, H, FUR)                          # banda de piel delantera
box(-6, 45, -3, -5, 50, 4, H, CAP)                        # orejeras de cuero
box(5, 45, -3, 6, 50, 4, H, CAP)
box(-5, 47, -6, 5, 50, -5, H, CAP)                        # cogotera

def face(x, y, col):
    M.V[(x, y, 4)] = [H, col, 0]                          # plano frontal de la cabeza (z = 4)
# La cara ocupa las columnas -4..3 (las aristas están biseladas), simétricas respecto a -0,5.
# Patrón de ojos: piel piel OJO piel piel OJO piel piel
for x in (-3, -2, 1, 2): face(x, 49, BROW)                # cejas
for x in (-2, 1): face(x, 48, EYE)                        # ojos
for x in (-1, 0): face(x, 47, SKIN_SH)                    # sombra de la nariz
for x in range(-3, 3): face(x, 46, BEARD)                 # bigote
for x in (-4, -3, -2, 1, 2, 3): face(x, 45, BEARD)
for x in (-1, 0): face(x, 45, MOUTH)                      # boca
for x in range(-4, 4): face(x, 44, BEARD)                 # barba
for x in range(-3, 3): face(x, 43, BEARD)
for y in range(43, 47):                                   # patillas en los laterales
    for x in (-5, 4):
        if (x, y, 3) in M.V: M.V[(x, y, 3)][1] = BEARD

# Pelo en la nuca y detrás de las orejas, bajo el gorro
for (x, y, z), v in M.V.items():
    if v[0] == H and v[1] == SKIN and y < 50 and (z <= -3 or (abs(x + 0.5) >= 4.5 and z < 1)):
        v[1] = HAIR

# ---------------- COLOR: variación mínima ----------------
def paint(k, part, c):
    x, y, z = k
    h = M.hsh(x, y, z)
    if c in (FUR, FUR_SH): return FUR if h > 0.2 else FUR_SH            # piel: dos tonos
    if c == PARKA and y < 30: return lerp(PARKA, PARKA_SH, 0.35)         # bajo de la parka algo más oscuro
    return None
M.paint(paint)

# Cola de la bufanda que cae por la espalda (pieza propia: se balancea al andar)
for y in range(31, 42):
    box(1, y, -6, 5, y + 1, -5, 'scarf', SCARF if y % 4 else SCARF_SH)
for x in (1, 3):                                          # flecos
    box(x, 30, -6, x + 1, 31, -5, 'scarf', SCARF_SH)
hu.split_limbs(M)                                         # codos y rodillas
hu.export(M, 'dyer', extra_pivots={'scarf': [3, 42, -5.5]}, extra_parents={'scarf': 'torso'})
