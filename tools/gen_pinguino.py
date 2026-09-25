"""Pingüino albino ciego gigante (En las montañas de la locura). Enemigo de horda, escalón 1.

Silueta de pingüino emperador (1,5 m): cuerpo de torpedo, cuello estrecho, cabeza
adelantada, pico largo y fino, aletas planas pegadas a los costados. Conserva el
dibujo de "frac" que hace reconocible a un pingüino, pero en tonos de albino:
gris pardo pálido en espalda, cabeza y aletas, pecho blanco, manchas de las orejas
amarillo claro y ojos lechosos, sin pupila.
Coordenadas en voxels (32 por metro), mira hacia +Z.
Uso: python tools/gen_pinguino.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

M = Model(S=2, seed=1931)

DARK = (0.54, 0.57, 0.62); DARK_SH = (0.49, 0.52, 0.57)        # "negro" del frac, despigmentado
WHITE = (0.93, 0.93, 0.91); WHITE_SH = (0.87, 0.87, 0.85)
EAR = (0.95, 0.86, 0.60)                                        # manchas de las orejas
BEAK = (0.74, 0.70, 0.68); BEAK_STRIPE = (0.88, 0.64, 0.60)
PINK = (0.86, 0.62, 0.60); PINK_SH = (0.72, 0.50, 0.49)
MILK = (0.82, 0.84, 0.88); MILK_SH = (0.66, 0.68, 0.74)

# Perfil del cuerpo: (altura, semiancho x, semifondo z, centro z), en voxels
PROFILE = [(2, 6.0, 5.5, 0.5), (8, 8.5, 7.5, 1.0), (15, 9.2, 8.2, 1.2), (24, 8.4, 7.6, 1.0),
           (31, 6.8, 6.4, 0.8), (35, 5.4, 5.4, 0.8), (37, 5.0, 5.2, 1.2), (40, 5.4, 5.6, 1.6),
           (43, 5.1, 5.3, 1.6), (45.5, 3.9, 4.3, 1.4), (47.5, 2.0, 2.4, 1.2)]

def profile(y):
    for (y0, *a), (y1, *b) in zip(PROFILE, PROFILE[1:]):
        if y0 <= y <= y1:
            t = (y - y0) / (y1 - y0)
            t = t * t * (3 - 2 * t)
            return [a[i] + (b[i] - a[i]) * t for i in range(3)]
    return None

# ---------------- CUERPO Y CABEZA ----------------
BAND = 1                                                        # perfil continuo (con bandas de 3 el pecho queda en escalera)
for y in range(2, 48):
    yb = 2 + ((y - 2) // BAND) * BAND + BAND / 2 if y < 44 else y + 0.5
    pr = profile(min(yb, 47.4))
    if pr is None: continue
    rx, rz, cz = pr
    part = 'head' if y >= 35 else 'torso'
    for x in range(-10, 10):
        for z in range(-10, 12):
            nx = (x + 0.5) / rx; nz = (z + 0.5 - cz) / rz
            if abs(nx) ** 2.8 + abs(nz) ** 2.8 > 1: continue          # sección casi plana: sin estrías
            # dibujo del frac
            if y < 35:
                col = WHITE if nz > 0.05 else DARK
            else:
                col = DARK
                if y < 38 and nz > 0.35: col = WHITE                      # garganta
                if 36 <= y <= 40 and abs(nx) > 0.55 and -0.1 < nz < 0.6: col = EAR   # orejas
            M.put(x, y, z, part, col)
# cola
M.vbox(-2, 3, -9, 2, 6, -7, 'torso', DARK)

# ---------------- PICO ----------------
# Sección decreciente: 4x3 en la base, 2x2 en medio, 2x1 en la punta, un poco caído
for i in range(10):
    z = 6 + i
    ytop = 42 - (i // 3)
    rows = 3 if i < 3 else (2 if i < 7 else 1)
    cols = (-2, -1, 0, 1) if i < 3 else (-1, 0)
    for x in cols:
        for r in range(rows):
            y = ytop - r
            lower = (r == rows - 1 and rows >= 2)
            M.put(x, y, z, 'head', BEAK_STRIPE if lower else BEAK)

# ---------------- OJOS LECHOSOS ----------------
for s in (-1, 1):
    for y in (41, 42):
        for z in (3, 4):
            x = 0
            while (x + s, y, z) in M.V: x += s                        # superficie lateral de la cabeza
            if (x, y, z) in M.V: M.V[(x, y, z)][1] = MILK if (y, z) != (41, 3) else MILK_SH

# ---------------- ALETAS ----------------
for s, p in ((-1, 'arm_l'), (1, 'arm_r')):
    for y in range(13, 32):
        rx, rz, cz = profile(y + 0.5)
        t = (31 - y) / 18                                             # 0 arriba, 1 en la punta
        width = int(round(5 - 3 * t))
        z0 = int(round(cz - 2))
        x = int(math.floor(s * (rx + 0.6 + 1.2 * t)))
        for z in range(z0, z0 + width):
            M.put(x, y, z, p, DARK if y > 15 else DARK_SH)

# ---------------- PATAS ----------------
for s, p in ((-1, 'leg_l'), (1, 'leg_r')):
    x0, x1 = (-5, -1) if s < 0 else (1, 5)
    M.vbox(x0, 0, 1, x1, 2, 8, p, PINK)
    M.vbox(x0, 0, 7, x1, 1, 8, p, PINK_SH)                            # uñas
    M.vbox(x0 + 1, 2, 1, x1 - 1, 4, 5, p, PINK_SH)                    # tobillo

# ---------------- COLOR: plumaje con variación mínima ----------------
def paint(k, part, c):
    h = M.hsh(*k)
    if c == WHITE and h < 0.18: return WHITE_SH
    if c == DARK and h < 0.2: return DARK_SH
    return None
M.paint(paint)

pivots = {'torso': [0, 2, 0], 'head': [0, 35, 1],
          'arm_l': [-7.5, 31, 1], 'arm_r': [7.5, 31, 1],
          'leg_l': [-3, 2, 3], 'leg_r': [3, 2, 3]}
n = M.export('models/pinguino.json', pivots, jitter=0.006, pivots_in_voxels=True, roughness=0.8, specular=0.3)
print(n, 'voxels')
