"""Rata de las Paredes ("Las ratas en las paredes"). Compañero (D-36).

Una rata enorme y maleducada: cuerpo largo y bajo de pera, pardo grisáceo con el vientre más
claro, hocico puntiagudo con bigotes, dos incisivos amarillos que asoman, orejas redondas y
rosadas, ojillos rojos que brillan y un rabo largo, rosado y anillado. Estilo 4 (tramos de
caras planas, detalles pintados), a 48 voxels por metro; mira hacia +Z.
Partes: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail (anim_cuadrupedo.gd).
Uso: python tools/gen_rata.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import slab, new
import materiales

FUR = (0.40, 0.34, 0.28); FUR_D = (0.30, 0.25, 0.21); BELLY = (0.62, 0.56, 0.48)
PINK = (0.86, 0.58, 0.58); PINK_D = (0.72, 0.46, 0.46)
TOOTH = (0.92, 0.80, 0.42); EYE = (0.95, 0.18, 0.12); NOSE = (0.80, 0.42, 0.45)
WHISK = (0.85, 0.82, 0.76)

M = new(2104)
B = 'body'

# patitas cortas y rosadas, con los dedos
for part, x, z, back in (('leg_fl', -4, 9, False), ('leg_fr', 4, 9, False),
                         ('leg_bl', -4.5, -8, True), ('leg_br', 4.5, -8, True)):
    slab(M, part, PINK, 0, 2, x, z + 1, 3.5, 3.5, 5, 5, ch=1)
    slab(M, part, FUR, 2, 7 if back else 6, x, z, 4, 5.5 if back else 4, 4, 6 if back else 4, ch=1)

# cuerpo de pera: grupa gorda detrás, más estrecho hacia el cuello; lomo más oscuro
slab(M, B, FUR, 5, 16, 0, -4, 14, 12, 20, 18, ch=3)
slab(M, B, FUR, 6, 14, 0, 7, 11, 9, 9, 8, ch=3)
for (x, y, z), v in M.V.items():
    if v[0] != B: continue
    if y < 8: v[1] = BELLY
    elif y >= 13: v[1] = FUR_D

# cabeza: cráneo, hocico en punta, nariz rosa, incisivos, orejas redondas y ojillos rojos
H = 'head'
slab(M, H, FUR, 7, 15, 0, 13, 9, 8, 7, 7, ch=2)
slab(M, H, FUR, 7, 12, 0, 18.5, 6, 4, 5, 5, ch=1)                          # hocico
slab(M, H, NOSE, 10, 12, 0, 21.5, 2, 2, 1, 1, ch=0)                         # nariz
slab(M, H, TOOTH, 6, 8, 0, 19.5, 2, 2, 1, 1, ch=0)                          # incisivos
for s in (-1, 1):
    slab(M, H, PINK, 14, 19, 4 * s, 11.5, 4.5, 4, 1.5, 1.5, ch=1)           # orejas
def face(x, y, c, glow=0):
    z = M.front(x, y)
    if z is not None: M.put(x, y, z, H, c, glow)
for x in (-3, 2):
    face(x, 13, EYE, 1)
for x in (-4, 3):
    face(x, 17, PINK_D)                                                     # hueco de la oreja
M.put(0, 7, 20, H, FUR_D)                                                    # raya entre los dientes
for s in (-1, 1):                                                           # bigotes
    for i in range(3):
        M.put(2 + i if s > 0 else -3 - i, 10 + (i % 2), 19, H, WHISK)

# rabo largo, anillado, que baja al suelo y se curva
T = 'tail'
for i in range(22):
    z = -13 - i
    y = max(1, 9 - i // 2)
    x = int(round((i / 22) ** 2 * 5))
    w = 3 if i < 8 else 2
    c = PINK if i % 3 else PINK_D
    for dx in range(w):
        for dy in range(2 if i < 14 else 1):
            M.put(x + dx - 1, y + dy, z, T, c)

materiales.texturize(M, {FUR: 'pelo', FUR_D: 'pelo', BELLY: 'pelo'})
piv = {'body': [0, 6, 0], 'head': [0, 11, 11], 'tail': [0, 9, -13],
       'leg_fl': [-4, 6, 9], 'leg_fr': [4, 6, 9], 'leg_bl': [-4.5, 7, -8], 'leg_br': [4.5, 7, -8]}
n = M.export('models/rata.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25)
print('rata', n, 'voxels')
