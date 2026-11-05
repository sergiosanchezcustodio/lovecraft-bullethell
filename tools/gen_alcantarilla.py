"""Alcantarilla (hito 17.14): tapa redonda de hierro fundido a ras de la calle, con el reborde de
piedra, un dibujo de rejilla en cruz y cuatro ranuras por las que sale el vapor. Muy baja (dos
voxels): se pisa. A 32 voxels por metro, 0,8 m de lado; mira hacia +Z (da igual: es redonda).
Parte: body. Pivote `steam` en el centro, encima: de ahí sale el vapor (Ambient, `vents`).
Uso: python tools/gen_alcantarilla.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model

IRON = (0.16, 0.16, 0.17); IRON_L = (0.25, 0.25, 0.26); RUST = (0.30, 0.18, 0.12)
STONE = (0.38, 0.37, 0.35); STONE_D = (0.28, 0.27, 0.26); SLOT = (0.03, 0.03, 0.03)

M = Model(S=2, seed=1714)
R_COVER, R_RIM = 10.5, 13.0
for x in range(-13, 14):
    for z in range(-13, 14):
        r = math.hypot(x + 0.5, z + 0.5)
        if r > R_RIM: continue
        if r > R_COVER:                                         # reborde de piedra
            M.put(x, 0, z, 'body', STONE if M.noise(x, 0, z, 3.0) > 0.4 else STONE_D)
            continue
        c = IRON
        if abs(x + 0.5) < 1.2 or abs(z + 0.5) < 1.2: c = IRON_L     # la cruz de la rejilla
        elif abs(r - 6.0) < 0.8: c = IRON_L                          # el anillo de en medio
        if M.noise(x, 1, z, 2.5) > 0.78: c = RUST
        # cuatro ranuras curvas entre los brazos de la cruz
        a = math.degrees(math.atan2(z + 0.5, x + 0.5)) % 90.0
        if 3.0 < r < 5.0 and 20.0 < a < 70.0: c = SLOT
        if 7.5 < r < 9.0 and 15.0 < a < 75.0: c = SLOT
        M.put(x, 0, z, 'body', c)
n = M.export('models/alcantarilla.json', {'body': [0, 0, 0], 'steam': [0, 2, 0]}, jitter=0.01,
             pivots_in_voxels=True, roughness=0.7, specular=0.35, no_bottom=True)
print('alcantarilla', n, 'voxels')
