"""Pingüino albino ciego gigante (En las montañas de la locura). Enemigo de horda, escalón 1.

Silueta de pingüino emperador (1,2 m): cuerpo de torpedo, cuello estrecho, cabeza
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

# Tamaño: K = 0,8 da unos 1,2 m (se redujo un 20 % tras la primera partida de prueba).
# Todas las medidas se escalan por K y se redondean al voxel: el tamaño del voxel no
# cambia, así que el pingüino sigue casando con el resto de modelos.
K = 0.8
def k(v): return v * K

# Perfil del cuerpo: (altura, semiancho x, semifondo z, centro z), en voxels (antes de K)
PROFILE = [(k(y), k(rx), k(rz), k(cz)) for (y, rx, rz, cz) in
           [(2, 6.0, 5.5, 0.5), (8, 8.5, 7.5, 1.0), (15, 9.2, 8.2, 1.2), (24, 8.4, 7.6, 1.0),
            (31, 6.8, 6.4, 0.8), (35, 5.4, 5.4, 0.8), (37, 5.0, 5.2, 1.2), (40, 5.4, 5.6, 1.6),
            (43, 5.1, 5.3, 1.6), (45.5, 3.9, 4.3, 1.4), (47.5, 2.0, 2.4, 1.2)]]
TOP = PROFILE[-1][0]
NECK = round(k(35))                    # a partir de aquí, cabeza

def profile(y):
    for (y0, *a), (y1, *b) in zip(PROFILE, PROFILE[1:]):
        if y0 <= y <= y1:
            t = (y - y0) / (y1 - y0)
            t = t * t * (3 - 2 * t)
            return [a[i] + (b[i] - a[i]) * t for i in range(3)]
    return None

# ---------------- CUERPO Y CABEZA ----------------
for y in range(2, int(TOP) + 1):
    pr = profile(min(y + 0.5, TOP - 0.1))
    if pr is None: continue
    rx, rz, cz = pr
    part = 'head' if y >= NECK else 'torso'
    for x in range(-10, 10):
        for z in range(-10, 12):
            nx = (x + 0.5) / rx; nz = (z + 0.5 - cz) / rz
            if abs(nx) ** 2.8 + abs(nz) ** 2.8 > 1: continue          # sección casi plana: sin estrías
            # dibujo del frac
            if y < NECK:
                col = WHITE if nz > 0.05 else DARK
            else:
                col = DARK
                if y < NECK + 2 and nz > 0.35: col = WHITE                # garganta
                if NECK + 1 <= y <= NECK + 4 and abs(nx) > 0.55 and -0.1 < nz < 0.6: col = EAR   # orejas
            M.put(x, y, z, part, col)
# cola
M.vbox(-2, 2, -7, 2, 5, -5, 'torso', DARK)

# ---------------- PICO ----------------
# Sección decreciente: 4x3 en la base, 2x2 en medio, 2x1 en la punta, un poco caído
BEAK_Y = NECK + 6
for i in range(8):
    z = 5 + i
    ytop = BEAK_Y - (i // 3)
    rows = 3 if i < 2 else (2 if i < 6 else 1)
    cols = (-2, -1, 0, 1) if i < 2 else (-1, 0)
    for x in cols:
        for r in range(rows):
            y = ytop - r
            lower = (r == rows - 1 and rows >= 2)
            M.put(x, y, z, 'head', BEAK_STRIPE if lower else BEAK)

# ---------------- OJOS LECHOSOS ----------------
for s in (-1, 1):
    for y in (BEAK_Y - 1, BEAK_Y):
        for z in (2, 3):
            x = 0
            while (x + s, y, z) in M.V: x += s                        # superficie lateral de la cabeza
            if (x, y, z) in M.V: M.V[(x, y, z)][1] = MILK if (y, z) != (BEAK_Y - 1, 2) else MILK_SH

# ---------------- ALETAS ----------------
FLIP_TOP = round(k(31)); FLIP_LEN = round(k(18))
for s, p in ((-1, 'arm_l'), (1, 'arm_r')):
    for y in range(FLIP_TOP - FLIP_LEN, FLIP_TOP + 1):
        rx, rz, cz = profile(y + 0.5)
        t = (FLIP_TOP - y) / FLIP_LEN                                 # 0 arriba, 1 en la punta
        width = int(round(4 - 2 * t))
        z0 = int(round(cz - 2))
        x = int(math.floor(s * (rx + 0.6 + 1.0 * t)))
        for z in range(z0, z0 + width):
            M.put(x, y, z, p, DARK if y > FLIP_TOP - FLIP_LEN + 2 else DARK_SH)

# ---------------- PATAS ----------------
for s, p in ((-1, 'leg_l'), (1, 'leg_r')):
    x0, x1 = (-4, -1) if s < 0 else (1, 4)
    M.vbox(x0, 0, 1, x1, 2, 7, p, PINK)
    M.vbox(x0, 0, 6, x1, 1, 7, p, PINK_SH)                            # uñas
    M.vbox(x0, 2, 1, x1, 3, 4, p, PINK_SH)                            # tobillo

# ---------------- COLOR: plumaje con variación mínima ----------------
def paint(k, part, c):
    h = M.hsh(*k)
    if c == WHITE and h < 0.18: return WHITE_SH
    if c == DARK and h < 0.2: return DARK_SH
    return None
M.paint(paint)

pivots = {'torso': [0, 2, 0], 'head': [0, NECK, 1],
          'arm_l': [-k(7.5), FLIP_TOP, 1], 'arm_r': [k(7.5), FLIP_TOP, 1],
          'leg_l': [-2.5, 2, 3], 'leg_r': [2.5, 2, 3]}
n = M.export('models/pinguino.json', pivots, jitter=0.006, pivots_in_voxels=True, roughness=0.8, specular=0.3)
print(n, 'voxels')
