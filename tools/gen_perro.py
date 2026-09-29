"""Perro de trineo de la expedición de Lake ("En las montañas de la locura"). Compañero.

Tipo husky: lomo, cabeza y rabo gris, vientre, patas, pecho y cara blancos, el antifaz
gris sobre los ojos claros, orejas de punta y el rabo enroscado sobre el lomo. Lleva el
arnés rojo de tiro, que lo distingue sobre la nieve. Estilo 4 (tramos de caras planas,
detalles pintados), a 48 voxels por metro; mira hacia +Z.
Partes: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail (animación en anim_cuadrupedo.gd).
Uso: python tools/gen_perro.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import slab, new
import materiales

GREY = (0.44, 0.46, 0.50); GREY_SH = (0.34, 0.36, 0.40)
WHITE = (0.90, 0.90, 0.91)
HARNESS = (0.70, 0.16, 0.12); BUCKLE = (0.78, 0.66, 0.35)
NOSE = (0.08, 0.07, 0.07); EYE = (0.62, 0.80, 0.95); PUPIL = (0.06, 0.06, 0.08)
PAW = (0.80, 0.78, 0.76)

M = new(1931)
B = 'body'

# patas: pata blanca con almohadilla, y los muslos traseros más gruesos
for part, x, z, back in (('leg_fl', -4.5, 12, False), ('leg_fr', 4.5, 12, False),
                         ('leg_bl', -4.5, -12, True), ('leg_br', 4.5, -12, True)):
    slab(M, part, PAW, 0, 2, x, z + 0.5, 5.5, 5.5, 7, 7, ch=1)
    slab(M, part, WHITE, 2, 9, x, z, 5, 5.5, 5.5, 6, ch=1)
    slab(M, part, WHITE, 9, 15, x, z - (1 if back else 0), 5.5, 7 if back else 6, 6, 8.5 if back else 6.5, ch=1)

# cuerpo: tronco, pecho que baja delante, lomo gris y vientre blanco
slab(M, B, GREY, 12, 25, 0, 0, 13, 14, 36, 36, ch=3)
slab(M, B, GREY, 10, 24, 0, 13, 12, 13.5, 12, 13, ch=3)                    # pecho hondo
slab(M, B, GREY, 13, 24, 0, -14, 13.5, 13.5, 10, 10, ch=3)                 # grupa
for (x, y, z), v in M.V.items():
    if v[0] != B: continue
    if y < 16 or (z > 12 and y < 21): v[1] = WHITE                            # vientre y pecho
# arnés: cincha alrededor del pecho, tirante por el lomo y collar
for (x, y, z), v in M.V.items():
    if v[0] != B: continue
    if 7 <= z <= 9: v[1] = HARNESS
    if abs(x + 0.5) <= 1.5 and y >= 23 and -12 <= z <= 9: v[1] = HARNESS
    if 16 <= z <= 18 and y >= 18: v[1] = HARNESS
for y in (20, 21): M.put(0, y, 20, B, BUCKLE); M.put(-1, y, 20, B, BUCKLE)

# cabeza: cráneo, hocico, trufa, orejas de punta, antifaz y ojos claros
H = 'head'
slab(M, H, GREY, 22, 34, 0, 23, 12, 11, 11, 11, ch=2)
slab(M, H, WHITE, 22, 28, 0, 32, 7, 6.5, 7.5, 7.5, ch=1)                   # hocico
slab(M, H, NOSE, 26, 29, 0, 36, 3, 3, 1.5, 1.5, ch=0)                      # trufa
for s in (-1, 1):
    slab(M, H, GREY_SH, 34, 40, 3.5 * s, 22, 4.5, 1, 4, 1.5, ch=0)          # orejas
for (x, y, z), v in M.V.items():
    if v[0] != H or v[1] != GREY: continue
    if y < 29 or (abs(x + 0.5) <= 1.5 and y < 33): v[1] = WHITE              # cara blanca con la raya
def face(x, y, c):
    z = M.front(x, y)
    if z is not None: M.put(x, y, z, H, c)
for x in (-5, -4, -3, 2, 3, 4):                                           # ojos claros, grandes
    for y in (29, 30): face(x, y, EYE)
for y in (29, 30): face(-4, y, PUPIL); face(3, y, PUPIL)
for x in (-5, -4, -3, 2, 3, 4): face(x, 31, GREY_SH)                         # antifaz sobre los ojos

# rabo enroscado sobre el lomo, con la punta blanca
T = 'tail'
slab(M, T, GREY, 22, 31, 0, -20, 4.5, 5, 4.5, 5, ch=1)
slab(M, T, GREY, 30, 34, 0, -16.5, 5, 5, 8, 8, ch=1)
slab(M, T, WHITE, 30, 33, 0, -12.5, 4.5, 4.5, 2, 2, ch=1)

materiales.texturize(M, {GREY: 'pelo', GREY_SH: 'pelo', WHITE: 'pelo', HARNESS: 'cuero'})
piv = {'body': [0, 15, 0], 'head': [0, 26, 18], 'tail': [0, 24, -19],
       'leg_fl': [-4.5, 15, 12], 'leg_fr': [4.5, 15, 12], 'leg_bl': [-4.5, 15, -12], 'leg_br': [4.5, 15, -12]}
n = M.export('models/perro.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25)
print('perro', n, 'voxels')
