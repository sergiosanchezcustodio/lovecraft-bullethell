"""Pingüino albino ciego gigante (En las montañas de la locura). Enemigo de horda, escalón 1.

Unos 1,5 m, plumaje blanco hueso sin pigmento, cuencas vacías y hundidas donde
tendría los ojos, pico largo y pesado, patas rosadas. Se guía por el oído.
Uso: python tools/gen_pinguino.py [S]
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale

S = int(sys.argv[1]) if len(sys.argv) > 1 else 2
M = Model(S=S, seed=1931)

WHITE = (0.88, 0.88, 0.86); WHITE_D = (0.66, 0.67, 0.68); CREAM = (0.90, 0.86, 0.72)
BACK = (0.72, 0.74, 0.76); PINK = (0.78, 0.56, 0.54); PINK_D = (0.55, 0.36, 0.36)
BEAK = (0.82, 0.60, 0.46); BEAK_T = (0.90, 0.80, 0.62); BEAK_D = (0.45, 0.28, 0.24)
SOCKET = (0.66, 0.50, 0.50); SOCKET_D = (0.54, 0.40, 0.41); CLAW = (0.30, 0.25, 0.22)

# ================= VOLÚMENES =================
M.ell(0, 10.2, -0.2, 5.0, 8.4, 4.4, 'torso', 'body')                 # cuerpo en forma de huevo
M.ell(0, 8.6, 0.7, 4.7, 6.4, 4.1, 'torso', 'body')                   # vientre
M.ell(0, 17.6, 0.1, 3.6, 2.8, 3.4, 'head', 'body')                   # cuello
M.ell(0, 20.2, 0.5, 3.1, 2.9, 3.1, 'head', 'body')                   # cabeza
for i in range(0, 25):                                                 # pico grueso, curvado hacia abajo
    t = i / 24
    r = 1.45 * (1 - t) + 0.55
    M.ell(0, 20.0 - 0.9 * t * t, 2.6 + 6.2 * t, r * 0.95, r, r, 'head', lerp(BEAK, BEAK_T, t))
# Aletas: láminas planas colgando de los hombros
for s in (-1, 1):
    p = 'arm_l' if s < 0 else 'arm_r'
    for i in range(0, 21):
        t = i / 20
        cx = s * (4.4 + 1.4 * t); cy = 15.0 - 8.0 * t; cz = 0.2 + 0.5 * t
        w = 1.5 * (1 - t) + 0.6
        M.ell(cx, cy, cz, 0.6, w, w, p, 'flipper')
# Patas cortas y pies palmeados
for s in (-1, 1):
    p = 'leg_l' if s < 0 else 'leg_r'
    M.capsule((s * 2.0, 3.6, 0.2), (s * 2.1, 1.2, 0.8), 1.1, 0.9, p, 'leg')
    M.ell(s * 2.1, 0.7, 1.9, 1.6, 0.7, 2.4, p, 'foot')
    for tx in (-0.9, 0.0, 0.9):
        M.put((s * 2.1 + tx) * S, 0, 4.4 * S, p, CLAW)

# ================= CUENCAS VACÍAS =================
# Un hueco esférico a cada lado de la cabeza; el fondo, oscuro, y alrededor piel rosada.
SOCKETS = [(s * 2.95, 20.9, 1.7) for s in (-1, 1)]
for (ex, ey, ez) in SOCKETS:
    for x in range(int((ex - 2) * S), int((ex + 2) * S) + 1):
        for y in range(int((ey - 2) * S), int((ey + 2) * S) + 1):
            for z in range(int((ez - 2) * S), int((ez + 2) * S) + 1):
                d = (((x + .5) / S - ex) ** 2 + ((y + .5) / S - ey) ** 2 + ((z + .5) / S - ez) ** 2) ** 0.5
                if d < 0.7 and (x, y, z) in M.V: del M.V[(x, y, z)]
for (ex, ey, ez) in SOCKETS:
    for x in range(int((ex - 2) * S), int((ex + 2) * S) + 1):
        for y in range(int((ey - 2) * S), int((ey + 2) * S) + 1):
            for z in range(int((ez - 2) * S), int((ez + 2) * S) + 1):
                k = (x, y, z)
                if k not in M.V or not M.exposed(k): continue
                d = (((x + .5) / S - ex) ** 2 + ((y + .5) / S - ey) ** 2 + ((z + .5) / S - ez) ** 2) ** 0.5
                if d < 1.3: M.V[k][1] = SOCKET_D if d < 1.05 else SOCKET
                elif d < 1.9: M.V[k][1] = PINK

# ================= PINTURA =================
def paint(k, part, c):
    if not isinstance(c, str): return None
    x, y, z = k
    n = M.noise(x, y, z, 3.0)
    if c == 'body':
        base = lerp(BACK, WHITE, max(0.0, min(1.0, (z + 1.5 * S) / (4.0 * S))))   # lomo algo más gris
        if part == 'head' and 16.5 * S < y < 18.2 * S and z > 0: base = lerp(base, CREAM, 0.6)   # collar pálido
        if (x + 2 * y) % 5 == 0 or (y - x + z) % 7 == 0: base = scale(base, 0.9)   # plumas
        return lerp(base, WHITE_D, n * 0.35)
    if c == 'flipper':
        if y < 8.2 * S: return lerp(PINK, PINK_D, n)                       # punta rosada
        return lerp(WHITE_D, BACK, n)
    if c == 'leg': return lerp(PINK_D, PINK, n)
    if c == 'foot': return lerp(PINK, PINK_D, 0.3 + n * 0.5)
    return None
M.paint(paint)
# Comisura del pico
for x in range(int(-1.0 * S), int(1.0 * S)):
    for zz in range(int(3.2 * S), int(7.0 * S)):
        y = int((19.6 - (zz / S - 3.2) * 0.2) * S)
        if (x, y, zz) in M.V and M.exposed((x, y, zz)): M.V[(x, y, zz)][1] = BEAK_D

pivots = {'torso': [0, 4.0, 0], 'head': [0, 16.8, 0],
          'arm_l': [-4.4, 15.0, 0.2], 'arm_r': [4.4, 15.0, 0.2],
          'leg_l': [-2.0, 3.6, 0.2], 'leg_r': [2.0, 3.6, 0.2]}
n = M.export('models/pinguino.json', pivots, jitter=0.012)
print(n, 'voxels')
