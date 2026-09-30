"""Shoggoth bebé ("En las montañas de la locura"). Compañero (D-36).

Una bolita negra llena de ojos: masa redondeada de protoplasma negro con brillo verdoso y
violeta (como el fragmento, pero pequeña y achatada como una gota), un bulto arriba y una
docena de ojos de distintos tamaños por todas partes, verdes, amarillos y alguno blanco, que
brillan. Una boquita. Estilo 4, a 48 voxels por metro; mira hacia +Z.
Partes: body, top (anim_blob.gd).
Uso: python tools/gen_shoggoth.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import rslab, new

BLACK = (0.09, 0.09, 0.11); SHEEN_G = (0.14, 0.24, 0.18); SHEEN_V = (0.22, 0.14, 0.28)
EYE_COLS = [(0.55, 0.95, 0.45), (0.95, 0.85, 0.30), (0.92, 0.95, 0.90)]
PUPIL = (0.02, 0.02, 0.02); MOUTH = (0.30, 0.08, 0.12)

M = new(5120)
B, T = 'body', 'top'
rslab(M, B, BLACK, 0, 11, 0, 0, 20, 18, r=7, rt=5, rb=2)
rslab(M, T, BLACK, 9, 17, -1, -1, 13, 12, r=5, rt=4.5, rb=2)

# brillo iridiscente: vetas verdes y violetas por ruido
for (x, y, z), v in M.V.items():
    n = M.noise(x, y, z, 4.0)
    if n > 0.68: v[1] = SHEEN_G
    elif n < 0.28: v[1] = SHEEN_V

# ojos por la superficie: en la cara delantera, los lados y arriba
def surface_eye(part, x, y, r, col, dz=1):
    z = M.front(x, y) if dz > 0 else None
    if z is None: return
    for dx in range(-r + 1, r):
        for dy in range(-r + 1, r):
            if dx * dx + dy * dy > (r - 0.5) ** 2: continue
            zz = M.front(x + dx, y + dy)
            if zz is None: continue
            c = PUPIL if (dx == 0 and dy == 0 and r > 1) else col
            M.put(x + dx, y + dy, zz, M.V[(x + dx, y + dy, zz)][0], c, 0 if c is PUPIL else 1)

EYES = [(-5, 6, 2, 0), (3, 7, 2, 1), (-1, 12, 2, 0), (6, 4, 1, 2), (-8, 3, 1, 1),
        (1, 3, 1, 2), (-3, 14, 1, 1), (4, 13, 1, 0), (7, 9, 1, 0), (-7, 9, 1, 2)]
for x, y, r, k in EYES:
    surface_eye(B, x, y, r, EYE_COLS[k])
# ojos en los lados y detrás (se ven al girar): unos pocos de 2x2, no motas sueltas
for x, y, z, col in ((9, 6, 0, 0), (-10, 5, -2, 1), (3, 5, -8, 2), (-4, 8, -8, 0), (-6, 14, -4, 1)):
    for dy in (0, 1):
        for d in (0, 1):
            xx, zz = (x, z + d) if abs(x) > 8 else (x + d, z)
            # sobre la superficie: el voxel ocupado más hacia fuera en esa dirección
            if abs(x) > 8:
                sx = 1 if x > 0 else -1
                xs = [k for k in range(-15, 16) if (k, y + dy, zz) in M.V]
                if not xs: continue
                xx = max(xs) if sx > 0 else min(xs)
            else:
                zs = [k for k in range(-15, 16) if (xx, y + dy, k) in M.V]
                if not zs: continue
                zz = min(zs)
            M.put(xx, y + dy, zz, M.V[(xx, y + dy, zz)][0], EYE_COLS[col], 1)
for x in (-1, 0):
    z = M.front(x, 2)
    if z is not None: M.put(x, 2, z, B, MOUTH)

piv = {'body': [0, 0, 0], 'top': [-1, 10, -1]}
n = M.export('models/shoggoth.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.3, specular=0.6)
print('shoggoth', n, 'voxels')
