"""Gato de Ulthar ("Los gatos de Ulthar"). Compañero.

Atigrado anaranjado, con pecho, hocico y patas blancos, rayas oscuras en el lomo y anillos
en el rabo, la "M" en la frente, orejas de punta con el interior rosado y ojos verdes.
Cabeza algo grande, a lo muñeco, para que se lea a su tamaño. Rabo alto y curvado. Estilo
4 (tramos de caras planas, detalles pintados), a 48 voxels por metro; mira hacia +Z.
Partes: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail (anim_cuadrupedo.gd).
Uso: python tools/gen_gato.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import slab, new
import materiales

ORANGE = (0.86, 0.50, 0.20); STRIPE = (0.56, 0.28, 0.10)
WHITE = (0.92, 0.90, 0.86)
PINK = (0.90, 0.58, 0.58); EYE = (0.45, 0.85, 0.35); PUPIL = (0.05, 0.06, 0.05)

M = new(1920)
B = 'body'

for part, x, z in (('leg_fl', -3.5, 8), ('leg_fr', 3.5, 8), ('leg_bl', -3.5, -8), ('leg_br', 3.5, -8)):
    slab(M, part, WHITE, 0, 2, x, z + 0.5, 4, 4, 5, 5, ch=1)
    slab(M, part, ORANGE, 2, 8, x, z, 3.5, 4, 4, 4.5, ch=1)
    for (xx, y, zz), v in M.V.items():
        if v[0] == part and y < 5: v[1] = WHITE                               # calcetines

slab(M, B, ORANGE, 7, 15, 0, 0, 8.5, 9, 22, 22, ch=2)
slab(M, B, ORANGE, 6, 14, 0, 8, 8, 8.5, 7, 7, ch=2)                        # pecho
for (x, y, z), v in M.V.items():
    if v[0] != B: continue
    if y < 9 or (z > 8 and y < 13): v[1] = WHITE
    elif y >= 10 and (z % 5) in (0, 1): v[1] = STRIPE                       # rayas del lomo

H = 'head'
slab(M, H, ORANGE, 12, 22, 0, 14, 11, 10.5, 9, 9, ch=2)
slab(M, H, WHITE, 12, 16, 0, 18.5, 5, 5, 2, 2, ch=1)                       # hocico
for s in (-1, 1):
    slab(M, H, ORANGE, 22, 27, 3.5 * s, 13.5, 3.5, 0.8, 3, 1, ch=0)         # orejas
def face(x, y, c):
    z = M.front(x, y)
    if z is not None: M.put(x, y, z, H, c)
for x in (-3, 2):                                                          # interior de las orejas
    for y in (22, 23): face(x, y, PINK)
for x in (-4, -3, 2, 3):
    for y in (17, 18): face(x, y, EYE)
for y in (17, 18): face(-3, y, PUPIL); face(2, y, PUPIL)                     # pupila de rendija
face(-1, 15, PINK); face(0, 15, PINK)                                        # nariz
for x, y in ((-2, 21), (-1, 20), (0, 20), (1, 21), (-1, 21), (0, 21)):        # la "M" de la frente
    face(x, y, STRIPE)

T = 'tail'
slab(M, T, ORANGE, 12, 20, 0, -12, 3, 3, 3, 3, ch=0)
slab(M, T, ORANGE, 20, 26, 0, -10.5, 3, 2.5, 3, 2.5, ch=0)
for (x, y, z), v in M.V.items():
    if v[0] == T and y % 4 == 0: v[1] = STRIPE                               # anillos

materiales.texturize(M, {ORANGE: 'pelo', WHITE: 'pelo', STRIPE: 'pelo'})
piv = {'body': [0, 8, 0], 'head': [0, 14, 10], 'tail': [0, 13, -11],
       'leg_fl': [-3.5, 8, 8], 'leg_fr': [3.5, 8, 8], 'leg_bl': [-3.5, 8, -8], 'leg_br': [3.5, 8, -8]}
n = M.export('models/gato.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25)
print('gato', n, 'voxels')
