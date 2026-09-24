"""William Dyer, geólogo de la expedición Miskatonic (1930). Personaje jugable.

Parka de lona con capucha forrada de piel, gafas de nieve sobre la frente, bufanda,
cinturón con martillo de geólogo y cartuchos de dinamita, zurrón de muestras y
botas de piel. Paleta cálida para distinguirlo de las criaturas.
Uso: python tools/gen_dyer.py [S]   (S = voxels por ub; 2 = 32 voxels/m)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale

S = int(sys.argv[1]) if len(sys.argv) > 1 else 2
M = Model(S=S, seed=1930)

PARKA = (0.50, 0.40, 0.27); PARKA_D = (0.36, 0.28, 0.18); PARKA_L = (0.60, 0.50, 0.35)
FUR = (0.58, 0.47, 0.34); FUR_D = (0.36, 0.28, 0.19); FUR_L = (0.78, 0.69, 0.55)
TROUSER = (0.22, 0.21, 0.20); TROUSER_L = (0.30, 0.28, 0.26)
BOOT = (0.40, 0.30, 0.20); BOOT_D = (0.22, 0.16, 0.11); SOLE = (0.10, 0.08, 0.07)
MITT = (0.28, 0.21, 0.15)
SKIN = (0.88, 0.68, 0.54); SKIN_R = (0.82, 0.50, 0.42); SKIN_D = (0.60, 0.42, 0.33)
BEARD = (0.46, 0.40, 0.34); BEARD_D = (0.32, 0.27, 0.23)
EYE = (0.06, 0.05, 0.05); BROW = (0.34, 0.29, 0.24); MOUTH = (0.25, 0.10, 0.09)
SCARF = (0.50, 0.14, 0.11); SCARF_D = (0.36, 0.09, 0.08)
BELT = (0.20, 0.13, 0.08); BUCKLE = (0.70, 0.62, 0.40)
LEATHER = (0.36, 0.22, 0.12); LEATHER_D = (0.24, 0.14, 0.08)
IRON = (0.42, 0.43, 0.45); WOOD = (0.52, 0.37, 0.20)
DYN = (0.62, 0.14, 0.10); FUSE = (0.15, 0.12, 0.10)
GOG_FRAME = (0.16, 0.13, 0.10); GOG_LENS = (0.30, 0.20, 0.10); GOG_GLINT = (0.90, 0.80, 0.55)

# ================= VOLÚMENES =================
# Piernas y botas
for s in (-1, 1):
    p = 'leg_l' if s < 0 else 'leg_r'
    hip = (s * 1.6, 14.5, 0.0); knee = (s * 1.75, 8.2, 0.35); ank = (s * 1.85, 3.0, 0.0)
    M.capsule(hip, knee, 1.55, 1.35, p, 'trouser')
    M.capsule(knee, ank, 1.35, 1.2, p, 'trouser')
    M.capsule((s * 1.85, 5.0, 0.0), (s * 1.85, 1.6, 0.25), 1.5, 1.55, p, 'boot')
    M.ell(s * 1.85, 1.0, 1.1, 1.55, 1.0, 2.4, p, 'boot')           # pie
    M.ell(s * 1.85, 5.2, 0.0, 1.75, 0.55, 1.75, p, 'fur')           # vuelta de piel
# Torso: parka larga hasta medio muslo
M.sell(0, 18.4, 0.0, 3.2, 5.0, 2.3, 'torso', 'parka', p=2.6)
M.sell(0, 21.4, 0.0, 3.7, 2.1, 2.4, 'torso', 'parka', p=2.8)         # hombros
M.sell(0, 13.4, 0.1, 3.25, 2.9, 2.55, 'torso', 'parka', p=2.6)       # faldón
M.ell(0, 23.4, 0.15, 2.2, 0.95, 2.05, 'torso', 'scarf')              # bufanda
M.ell(0.9, 22.6, 1.9, 0.9, 1.4, 0.55, 'torso', 'scarf')              # caída de la bufanda
# Brazos
for s in (-1, 1):
    p = 'arm_l' if s < 0 else 'arm_r'
    sh = (s * 3.9, 22.0, 0.0); el = (s * 4.6, 17.6, 0.25); wr = (s * 4.85, 13.9, 0.9)
    M.ell(*sh, 1.65, 1.65, 1.65, p, 'parka')
    M.capsule(sh, el, 1.4, 1.25, p, 'parka')
    M.capsule(el, wr, 1.25, 1.15, p, 'parka')
    M.ell(s * 4.85, 14.3, 0.85, 1.4, 0.65, 1.4, p, 'fur')           # puño de piel
    M.ell(s * 4.95, 12.7, 1.05, 1.0, 1.35, 0.95, p, 'mitt')          # manopla
    M.ell(s * 4.45, 13.1, 1.75, 0.5, 0.65, 0.5, p, 'mitt')           # pulgar
# Cabeza: capucha con la cara dentro
M.sell(0, 25.9, 0.0, 2.6, 2.8, 2.7, 'head', 'parka', p=2.5)
M.sell(0, 25.3, 0.7, 1.75, 2.0, 1.7, 'head', 'skin', p=2.6)

# ================= CARA =================
FX, FY, FRX, FRY = 0.0, 25.25, 1.6, 1.85           # abertura de la capucha (ub)
def in_ell(x, y, rx, ry):
    return ((x + .5) / S - FX) ** 2 / rx ** 2 + ((y + .5) / S - FY) ** 2 / ry ** 2 <= 1
ys = range(int((FY - 2.6) * S), int((FY + 2.6) * S) + 1)
xs = range(int(-2.6 * S), int(2.6 * S) + 1)
for x in xs:
    for y in ys:
        if in_ell(x, y, FRX, FRY):
            # quitar la capucha delante de la cara
            z = M.front(x, y)
            while z is not None and M.V[(x, y, z)][1] != 'skin':
                del M.V[(x, y, z)]
                z = M.front(x, y)
        elif in_ell(x, y, FRX + 0.75, FRY + 0.75):
            z = M.front(x, y)
            if z is not None and M.V[(x, y, z)][0] == 'head':
                M.V[(x, y, z)][1] = 'fur'
                M.put(x, y, z + 1, 'head', 'fur')                  # ribete de piel en relieve
def face(x, y, col, dz=0):
    z = M.front(x, y)
    if z is None: return
    if dz: M.put(x, y, z + dz, 'head', col)
    else: M.V[(x, y, z)][1] = col
EY = int(25.75 * S)
for x in (1, -2): face(x, EY, EYE)                                  # ojos
for x in (1, 2, -2, -3): face(x, EY + 1, BROW)                      # cejas
for y in (EY - 1, EY - 2): face(-1, y, SKIN_D, 1); face(0, y, SKIN_D, 1)   # nariz
for x in (-3, 2): face(x, EY - 2, SKIN_R)                           # mejillas curtidas
for x in range(-3, 3): face(x, EY - 3, BEARD)                       # bigote
for y in (EY - 4, EY - 5):
    for x in range(-3, 3): face(x, y, BEARD if (x + y) % 3 else BEARD_D)
face(-1, EY - 4, MOUTH); face(0, EY - 4, MOUTH)
# Gafas de nieve sobre la capucha
GY = 27.3
for x in range(int(-2.6 * S), int(2.6 * S) + 1):
    for y in (int(GY * S), int(GY * S) + 1):
        z = M.front(x, y)
        if z is not None and z > 0: M.V[(x, y, z)][1] = GOG_FRAME
for gx in (-0.85, 0.85):
    cx, cy = int(gx * S) - (1 if gx < 0 else 0), int(GY * S)
    for dx in (0, 1):
        for dy in (0, 1):
            z = M.front(cx + dx, cy + dy)
            M.put(cx + dx, cy + dy, z + 1, 'head', GOG_GLINT if (dx, dy) == (1, 1) else GOG_LENS)

# ================= EQUIPO =================
def ring(y0, y1, part, col, zmin=None):
    """Colorea la superficie del torso entre dos alturas (ub): cinturones y ribetes."""
    for y in range(int(y0 * S), int(y1 * S)):
        for x in range(int(-4.2 * S), int(4.2 * S) + 1):
            for z in range(int(-3.2 * S), int(3.2 * S) + 1):
                v = M.V.get((x, y, z))
                if v and v[0] == part and M.exposed((x, y, z)) and (zmin is None or z >= zmin):
                    v[1] = col
ring(15.2, 15.9, 'torso', BELT)
ring(10.5, 11.2, 'torso', 'fur')
M.box(-0.5, 15.1, 2.2, 0.5, 16.0, 2.8, 'torso', BUCKLE)
# Martillo de geólogo colgado a la derecha
M.line((3.3, 15.4, 1.3), (3.5, 11.6, 1.9), 'torso', WOOD, thick=2)
M.box(2.6, 11.2, 1.5, 4.6, 12.0, 2.4, 'torso', IRON)
# Cartuchos de dinamita en el cinturón, a la izquierda
for i, x in enumerate((-2.4, -1.7, -1.0)):
    M.box(x, 14.3, 2.3, x + 0.55, 16.4, 2.85, 'torso', DYN)
    M.put(x * S, 16.4 * S, 2.4 * S, 'torso', FUSE)
# Zurrón de muestras con correa en bandolera
M.box(-4.0, 11.8, -0.9, -2.9, 14.6, 1.6, 'torso', LEATHER)
M.box(-4.1, 13.9, -1.0, -2.8, 14.7, 1.7, 'torso', LEATHER_D)
for t in range(0, 41):
    u = t / 40
    x = 2.9 - 5.4 * u; y = 22.4 - 8.2 * u
    for zz in (M.front(int(x * S), int(y * S)),):
        if zz is not None:
            M.V[(int(x * S), int(y * S), zz)][1] = LEATHER
            if (int(x * S) + 1, int(y * S), zz) in M.V: M.V[(int(x * S) + 1, int(y * S), zz)][1] = LEATHER
# Botonadura de madera de la parka
for y in range(int(17.0 * S), int(22.0 * S), 3):
    z = M.front(0, y)
    if z is not None: M.put(0, y, z + 1, 'torso', WOOD)

# ================= PINTURA =================
def paint(k, part, c):
    if not isinstance(c, str): return None
    x, y, z = k
    n = M.noise(x, y, z, 5.0)
    if c == 'parka':
        base = lerp(PARKA_D, PARKA_L, n)
        if y < 12.0 * S: base = lerp(base, PARKA_D, 0.45)            # bajo sucio
        if part == 'torso' and x in (-1, 0) and z > 0 and y > 11 * S: base = PARKA_D   # tapeta
        if (y + x // 3) % 7 == 0: base = scale(base, 0.88)             # arrugas de la lona
        return base
    if c == 'fur':
        r = M.rng.random()
        return FUR_D if r < 0.25 else (FUR_L if r > 0.8 else FUR)
    if c == 'trouser':
        base = lerp(TROUSER, TROUSER_L, n)
        if abs(y - 8.2 * S) < 1.5 and z > 0: base = TROUSER_L         # rodilla gastada
        return base
    if c == 'boot':
        if y <= 0: return SOLE
        if z > 0 and (y % 2 == 0) and 2 * S < y < 5 * S and abs(abs(x) - 1.85 * S) < 1.2: return BOOT_D   # cordones
        return lerp(BOOT_D, BOOT, 0.4 + n * 0.6)
    if c == 'mitt': return lerp(MITT, scale(MITT, 1.3), n)
    if c == 'scarf': return SCARF_D if (x + y) % 4 == 0 else SCARF
    if c == 'skin': return SKIN
    return None
M.paint(paint)

pivots = {'torso': [0, 14.5, 0], 'head': [0, 23.4, 0],
          'arm_l': [-3.9, 22.0, 0], 'arm_r': [3.9, 22.0, 0],
          'leg_l': [-1.6, 14.5, 0], 'leg_r': [1.6, 14.5, 0]}
n = M.export('models/dyer.json', pivots)
print(n, 'voxels')
