"""Fragmento protoplásmico de shoggoth (variante). Enemigo de horda, escalón 1.

Masa negra iridiscente y burbujeante de algo menos de 1 m, con ojos verdosos que
brotan en su superficie, pústulas y una boca que silba "¡Tekeli-li!". Dos
pseudópodos delante. Partes: body, top, pod_l, pod_r.
Uso: python tools/gen_fragmento.py [S]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale

S = int(sys.argv[1]) if len(sys.argv) > 1 else 2
NAME = sys.argv[2] if len(sys.argv) > 2 else 'fragmento'      # shoggoth_grande: S=5, otra semilla
M = Model(S=S, seed=int(sys.argv[3]) if len(sys.argv) > 3 else 1936)

BLACK = (0.02, 0.03, 0.03); DEEP_G = (0.04, 0.12, 0.09); DEEP_P = (0.10, 0.05, 0.13)
SHEEN = (0.14, 0.30, 0.26); SHEEN_P = (0.26, 0.16, 0.32)
PUST = (0.30, 0.38, 0.22); PUST_L = (0.52, 0.60, 0.34)
EYE = (0.72, 0.96, 0.40); EYE_R = (0.05, 0.09, 0.05); PUPIL = (0.01, 0.02, 0.01)
MAW = (0.06, 0.01, 0.03); GUM = (0.26, 0.07, 0.13); TOOTH = (0.70, 0.72, 0.60)

# ================= VOLÚMENES =================
M.ell(0, 4.2, 0, 7.0, 4.6, 6.4, 'body', 'proto')                     # masa principal, apoyada
M.ell(-2.4, 3.2, -1.5, 4.8, 3.4, 4.6, 'body', 'proto')
M.ell(2.8, 3.0, 1.2, 4.2, 3.0, 4.0, 'body', 'proto')
M.ell(0.6, 8.6, 0.4, 4.4, 3.4, 4.2, 'top', 'proto')                   # cresta donde brotan los ojos
M.ell(-1.8, 10.4, -0.6, 2.4, 2.2, 2.4, 'top', 'proto')
# Burbujas en la superficie
for i in range(16):
    a = M.rng.uniform(0, math.tau); h = M.rng.uniform(0.2, 1.0)
    r = M.rng.uniform(0.9, 1.9)
    x = math.cos(a) * 6.0 * (1.1 - h * 0.5); z = math.sin(a) * 5.6 * (1.1 - h * 0.5); y = 1.5 + h * 7.5
    M.ell(x, y, z, r, r, r, 'top' if y > 7.5 else 'body', 'proto')
# Pseudópodos hacia delante
for s in (-1, 1):
    p = 'pod_l' if s < 0 else 'pod_r'
    M.capsule((s * 3.0, 2.2, 4.0), (s * 4.6, 1.2, 9.0), 1.7, 0.9, p, 'proto')
    M.ell(s * 4.8, 1.0, 9.4, 1.3, 0.9, 1.3, p, 'proto')
# Aplanar la base (nada por debajo del suelo)
for k in [k for k in M.V if k[1] < 0]:
    del M.V[k]

# ================= PINTURA =================
def paint(k, part, c):
    if c != 'proto': return None
    x, y, z = k
    n = M.noise(x, y, z, 6.0); m = M.noise(x + 40, y, z, 2.5)
    base = lerp(BLACK, DEEP_G, n) if n < 0.55 else lerp(DEEP_G, DEEP_P, (n - 0.55) / 0.45)
    if m > 0.78: base = lerp(base, SHEEN if n < 0.6 else SHEEN_P, 0.8)     # brillos iridiscentes
    return base
M.paint(paint)

# Pústulas: manchas claras de 2x2 sobre la superficie
for i in range(12):
    a = M.rng.uniform(0, math.tau); y = int(M.rng.uniform(2.0, 9.0) * S)
    dx, dz = math.cos(a), math.sin(a)
    for t in range(int(9 * S), 0, -1):
        x0, z0 = int(dx * t), int(dz * t)
        if (x0, y, z0) in M.V:
            for ox in (0, 1):
                for oy in (0, 1):
                    k = (x0 + ox, y + oy, z0)
                    if k in M.V and M.exposed(k): M.V[k][1] = PUST_L if (ox, oy) == (0, 1) else PUST
            break

# Ojos que brotan: esferas brillantes (glow) con párpado oscuro y pupila mirando arriba-delante
EYES = [(0.2, 11.0, 2.6, 1.35), (-2.6, 9.6, 3.0, 1.0), (2.9, 8.2, 3.6, 1.15),
        (-1.0, 12.4, -0.2, 0.8), (4.6, 5.4, 4.4, 0.75), (-4.8, 6.0, 3.2, 0.7)]
D = (0.0, 0.55, 0.835)
for (ex, ey, ez, r) in EYES:
    part = 'top' if ey > 7.5 else 'body'
    M.ell(ex, ey, ez, r + 0.4, r + 0.4, r + 0.4, part, EYE_R)
    M.ell(ex + D[0] * 0.75, ey + D[1] * 0.75, ez + D[2] * 0.75, r, r, r, part, EYE, glow=1)
    cx, cy, cz = [(q + d * 0.75) * S for q, d in zip((ex, ey, ez), D)]
    for k, v in M.V.items():
        if v[2] != 1 or v[0] != part: continue
        rel = (k[0] + .5 - cx, k[1] + .5 - cy, k[2] + .5 - cz)
        dist = math.sqrt(sum(q * q for q in rel)) or 1
        dot = sum(rel[i] * D[i] for i in range(3)) / dist
        if dist < (r + 0.6) * S and dot > 0.9: v[1] = PUPIL; v[2] = 0

# Boca que silba: hendidura con encías y dientecillos
MY = 4.6
for x in range(int(-2.6 * S), int(2.6 * S)):
    xr = abs((x + .5) / S) / 2.6
    for y in (int(MY * S), int(MY * S) + 1):
        z = M.front(x, y)
        if z is None or M.V[(x, y, z)][0] != 'body': continue
        del M.V[(x, y, z)]
        M.V[(x, y, z - 1)] = ['body', MAW, 0]
    for y, off in ((int(MY * S) + 2, -1), (int(MY * S) - 1, -1)):
        z = M.front(x, y)
        if z is not None: M.V[(x, y, z)][1] = GUM
    if x % 2 == 0 and xr < 0.85:
        z = M.front(x, int(MY * S) + 2)
        if z is not None: M.put(x, int(MY * S) + 1, z, 'body', TOOTH)

pivots = {'body': [0, 0, 0], 'top': [0.4, 6.0, 0.2],
          'pod_l': [-3.0, 2.2, 4.0], 'pod_r': [3.0, 2.2, 4.0]}
n = M.export('models/%s.json' % NAME, pivots, jitter=0.01)
print(n, 'voxels')
