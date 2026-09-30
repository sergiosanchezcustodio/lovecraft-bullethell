"""Búho de los sueños ("La búsqueda en sueños de la ignota Kadath"). Compañero (D-36).

Parece sabio: cuerpo de huevo con plumaje gris azulado de sueño, pecho más claro con motas
en V, disco facial lila pálido con el borde oscuro, cejas en punta (orejas de plumas), ojos
grandes y dorados que brillan, pico corto de hueso y alas con las primarias más oscuras y
barras claras. Garras amarillentas. Estilo 4, a 48 voxels por metro; mira hacia +Z.
Partes: body, head, wing_l, wing_r (anim_volador.gd). Vuela: la altura la pone Pet.
Uso: python tools/gen_buho.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import rslab, slab, new
import materiales

PLUME = (0.42, 0.44, 0.56); PLUME_D = (0.28, 0.29, 0.40); CHEST = (0.72, 0.70, 0.78)
SPOT = (0.36, 0.34, 0.46); DISC = (0.80, 0.74, 0.88); RIM = (0.24, 0.22, 0.32)
EYE = (1.0, 0.76, 0.20); PUPIL = (0.04, 0.03, 0.05); BEAK = (0.82, 0.78, 0.66)
CLAW = (0.80, 0.70, 0.36); BAR = (0.62, 0.62, 0.74)

M = new(4411)
B, H = 'body', 'head'

# garras bajo el cuerpo
for s in (-1, 1):
    slab(M, B, CLAW, 0, 2, 2.5 * s, 2, 3, 3, 4, 4, ch=1)
# cuerpo de huevo, pecho claro con motas en V
rslab(M, B, PLUME, 2, 17, 0, 0, 13, 12, r=4, rt=3, rb=4)
for (x, y, z), v in M.V.items():
    if v[0] != B or v[1] != PLUME: continue
    if z >= 2 and abs(x + 0.5) < 5 and y < 15:
        v[1] = SPOT if (y % 3 == 0 and abs(x + 0.5) % 3 < 1.2) else CHEST

# cabeza grande y redonda, disco facial, orejas de plumas, ojos brillantes y pico
rslab(M, H, PLUME, 15, 27, 0, 0.5, 14, 12, r=4.5, rt=4, rb=2)
for s in (-1, 1):
    slab(M, H, PLUME_D, 27, 31, 5 * s, 0, 3, 1.5, 3, 1.5, ch=0)              # orejas de plumas
def face(x, y, c, glow=0):
    z = M.front(x, y)
    if z is not None: M.put(x, y, z, H, c, glow)
for x in range(-6, 6):                                                      # disco facial con su borde
    for y in range(16, 26):
        dx = min(abs(x + 3.5), abs(x - 2.5))
        dy = abs(y - 21)
        if dx * dx / 16 + dy * dy / 25 <= 1.0: face(x, y, DISC)
        elif dx * dx / 22 + dy * dy / 32 <= 1.0: face(x, y, RIM)
for s in (-1, 1):
    cx = -4 if s < 0 else 2
    for x in (cx, cx + 1, cx + 2):
        for y in (20, 21, 22): face(x, y, EYE, 1)
    face(cx + 1, 21, PUPIL)
for y in (17, 18, 19): face(-1, y, BEAK); face(0, y, BEAK)
for y in (17,): M.put(-1, y, (M.front(-1, y) or 0) + 1, H, BEAK); M.put(0, y, (M.front(0, y) or 0) + 1, H, BEAK)

# alas pegadas a los costados, primarias oscuras con barras claras
for part, s in (('wing_l', -1), ('wing_r', 1)):
    slab(M, part, PLUME, 5, 16, 7 * s, -1, 2, 2, 9, 10, ch=0)
    for (x, y, z), v in M.V.items():
        if v[0] != part: continue
        if y < 9: v[1] = BAR if y % 3 == 0 else PLUME_D

materiales.texturize(M, {PLUME: 'pelo', PLUME_D: 'pelo', CHEST: 'pelo', DISC: 'pelo'})
piv = {'body': [0, 2, 0], 'head': [0, 16, 0], 'wing_l': [-7, 15, -1], 'wing_r': [7, 15, -1]}
n = M.export('models/buho.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25)
print('buho', n, 'voxels')
