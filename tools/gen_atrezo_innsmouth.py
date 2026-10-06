"""Atrezo de Newburyport y la carretera a Innsmouth (hito 6.1). Una parte "body", origen en el
centro de la base, como gen_atrezo_expedicion.py.

  casa       casa de tablas de dos aguas, ventanas tapiadas, porche y chimenea (16 voxels/m:
             es pieza de borde y grande; a 32 tendría ~200.000 voxels)
  autobus    el autobús viejo de Joe Sargent, verde grisáceo desvaído y con óxido (32/m)
  poste      poste de telégrafo con travesaño y aisladores de vidrio (32/m)
  valla      tramo de valla de estacas con alguna rota o caída (32/m)
  barril     barril de arenques (32/m)
  redes      redes de pesca tendidas entre dos palos (32/m)
  barca      bote de remos volcado (32/m)
  farola     farola de gas de hierro con la luz en el pivote "light" (48/m)
  juncos     mata de juncos de la marisma (32/m)

Escribe models/inn_<pieza>.json. Uso: python tools/gen_atrezo_innsmouth.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
BOARD = (0.50, 0.49, 0.45); BOARD_D = (0.38, 0.37, 0.34); BOARD_G = (0.30, 0.34, 0.30)   # tablas grises, verdín
TRIM = (0.62, 0.60, 0.55)
ROOF = (0.20, 0.21, 0.22); ROOF_D = (0.15, 0.16, 0.17); MOSS = (0.24, 0.30, 0.18)
PLANK = (0.42, 0.33, 0.24); PLANK_D = (0.30, 0.23, 0.17)                       # tablones de tapiar
BRICK = (0.42, 0.24, 0.19); BRICK_D = (0.32, 0.18, 0.14)
DARK = (0.06, 0.06, 0.07)
WOOD = (0.36, 0.28, 0.20); WOOD_D = (0.26, 0.20, 0.15)
IRON = (0.16, 0.17, 0.18); IRON_L = (0.30, 0.31, 0.32)
RUST = (0.42, 0.24, 0.13)
BUS = (0.38, 0.44, 0.38); BUS_D = (0.28, 0.33, 0.28)
GLASS = (0.22, 0.28, 0.30); TIRE = (0.08, 0.08, 0.08)
NET = (0.45, 0.42, 0.34); FLOAT = (0.62, 0.34, 0.22)
REED = (0.42, 0.42, 0.24); REED_D = (0.30, 0.32, 0.18)
LIGHT = (1.0, 0.80, 0.52)


def box(M, x0, x1, y0, y1, z0, z1, col):
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                M.put(x, y, z, P, col(x, y, z) if callable(col) else col)


# ---------------- casa ----------------

def casa():
    """Casa de Nueva Inglaterra de tablas solapadas (líneas oscuras cada 3 voxels), tejado de
    dos aguas a lo largo de x con tejas y verdín, ventanas tapiadas con tablones en aspa,
    puerta, porche con dos pies derechos y chimenea de ladrillo. Hueca."""
    M = Model(S=1, seed=61)
    HX, HZ, WALL, RIDGE = 56, 44, 52, 84                     # 7 x 5,5 m; aleros a 3,25 m; cumbrera a 5,25
    def siding(x, y, z):
        if y % 3 == 0: return BOARD_D
        c = lerp(BOARD, BOARD_G, 0.6 * M.noise(x, y, z, 10.0) + 0.3 * (y < 10))
        return c
    for y in range(0, WALL):                                 # paredes de 2 voxels
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                if min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) > 1: continue
                M.put(x, y, z, P, siding(x, y, z))
    for y in range(0, WALL):                                 # esquineras claras
        for x in (-HX, HX - 1):
            for z in (-HZ, HZ - 1): M.put(x, y, z, P, TRIM)
    for x in range(-HX, HX):                                 # hastiales (los dos extremos)
        pass
    for z in range(-HZ - 4, HZ + 4):                         # tejado: dos faldones a lo largo de x
        dz = abs(z + 0.5)
        y = int(RIDGE - (dz / (HZ + 4)) * (RIDGE - WALL + 4))
        for x in range(-HX - 3, HX + 3):
            c = ROOF if (x // 4 + y) % 2 else ROOF_D
            if M.noise(x, y, z, 9.0) > 0.68: c = MOSS
            M.put(x, y, z, P, c); M.put(x, y - 1, z, P, ROOF_D)
    for x in (-HX, HX - 1):                                  # hastiales rellenos bajo el tejado
        for z in range(-HZ, HZ):
            top = int(RIDGE - (abs(z + 0.5) / (HZ + 4)) * (RIDGE - WALL + 4)) - 1
            for y in range(WALL, top): M.put(x, y, z, P, siding(x, y, z))
    def window(cx, cy, face):                                # ventana tapiada en la fachada sur (+z) o este (+x)
        for a in range(-6, 6):
            for b in range(-8, 8):
                edge = a in (-6, 5) or b in (-8, 7)
                col = TRIM if edge else DARK
                if not edge and (abs(a * 1.4 - b) < 1.2 or abs(a * 1.4 + b) < 1.2): col = PLANK if (a + b) % 3 else PLANK_D
                if not edge and b in (-3, 3): col = PLANK_D
                if face == 'z': M.put(cx + a, cy + b, HZ, P, col)
                else: M.put(HX, cy + b, cx + a, P, col)
    for cx in (-38, -14, 26):
        window(cx, 26, 'z')
    for cz in (-22, 18): window(cz, 26, 'x')
    for x in range(2, 16):                                   # puerta
        for y in range(0, 36):
            M.put(x, y, HZ, P, WOOD_D if x in (2, 15) or y == 35 else WOOD)
    M.put(13, 17, HZ + 1, P, IRON_L)
    for x in range(-4, 24):                                  # porche: tarima, pies derechos y tejadillo
        for z in range(HZ, HZ + 14):
            M.put(x, 2, z, P, PLANK if x % 3 else PLANK_D)
            M.put(x, 1, z, P, PLANK_D)
    for x in (-3, 22):
        for y in range(3, 40): M.put(x, y, HZ + 12, P, TRIM)
    for x in range(-6, 26):
        for z in range(HZ, HZ + 15):
            M.put(x, 40 + (HZ + 15 - z) // 5, z, P, ROOF_D)
    for y in range(RIDGE - 20, RIDGE + 10):                  # chimenea
        for x in range(-34, -27):
            for z in range(-8, -1):
                if min(x + 34, -28 - x, z + 8, -2 - z) > 0 and y < RIDGE + 9: continue
                M.put(x, y, z, P, BRICK if (y // 2 + x) % 4 else BRICK_D)
    return M, {P: [0, 0, 0]}


# ---------------- autobús de Joe Sargent ----------------

def autobus():
    """Autobús de los años 20: caja larga sobre chasis, capó delante (+x) con rejilla,
    ventanillas oscuras, techo combado, ruedas de radios, óxido y pintura desvaída."""
    M = Model(S=2, seed=62)
    L, W = 84, 34                                           # 5,25 x 2,1 m (mitad)
    def paint(x, y, z):
        c = BUS if y % 6 else BUS_D
        if M.noise(x, y, z, 6.0) > 0.7: c = RUST
        return c
    for x in range(-L, L - 26):                             # caja
        for y in range(16, 74):
            for z in range(-W // 2, W // 2):
                if min(x + L, L - 27 - x, z + W // 2, W // 2 - 1 - z) > 1 and y < 72: continue
                win = 44 <= y < 64 and (x + L) % 18 > 3 and z in (-W // 2, W // 2 - 1) and x < L - 32
                M.put(x, y, z, P, GLASS if win else paint(x, y, z))
    for x in range(-L - 1, L - 25):                         # techo combado
        for z in range(-W // 2 - 1, W // 2 + 1):
            M.put(x, 74 + (abs(z) < 10), z, P, BUS_D)
    for x in range(L - 26, L):                              # capó y rejilla
        for y in range(18, 46):
            for z in range(-12, 12):
                if x == L - 1: M.put(x, y, z, P, IRON if (y + z) % 2 else IRON_L)
                elif min(z + 12, 11 - z) == 0 or y == 45: M.put(x, y, z, P, paint(x, y, z))
    for z in (-9, 8):                                       # faros
        for y in (40, 41):
            M.put(L, y, z, P, (0.70, 0.66, 0.52)); M.put(L, y, z + 1, P, (0.70, 0.66, 0.52))
    for y in range(46, 66):                                 # parabrisas
        for z in range(-15, 15): M.put(L - 27, y, z, P, GLASS if y < 64 else BUS_D)
    for x in range(-L, L):                                  # chasis y estribo
        for z in range(-W // 2, W // 2): M.put(x, 14, z, P, IRON)
    for cx in (-L + 22, L - 20):                            # ruedas
        for s in (-1, 1):
            z0 = s * (W // 2) - (1 if s > 0 else 0)
            for a in range(-13, 14):
                for b in range(0, 26):
                    r = math.hypot(a, b - 13)
                    if r > 13: continue
                    c = TIRE if r > 9 else (IRON_L if r < 3 or abs(a) < 1 or abs(b - 13) < 1 else IRON)
                    for dz in range(0, 4): M.put(cx + a, b, z0 + s * dz, P, c)
    return M, {P: [0, 0, 0]}


# ---------------- poste, valla, barril, redes, barca ----------------

def poste():
    M = Model(S=2, seed=63)
    for y in range(0, 192):                                 # 6 m
        for x in range(-2, 2):
            for z in range(-2, 2):
                if abs(x + 0.5) + abs(z + 0.5) > 3: continue
                M.put(x, y, z, P, WOOD_D if (y + x * 5) % 17 == 0 else lerp(WOOD_D, WOOD, M.noise(x, y, z, 8.0)))
    for x in range(-28, 28):                                # travesaño
        for y in (176, 177, 178):
            M.put(x, y, 0, P, WOOD); M.put(x, y, -1, P, WOOD_D)
    for x in (-25, -13, 12, 24):                            # aisladores de vidrio verdoso
        for y in range(179, 184):
            M.put(x, y, 0, P, (0.40, 0.58, 0.52)); M.put(x, y, -1, P, (0.40, 0.58, 0.52))
    return M, {P: [0, 0, 0]}


def valla():
    """3 m de valla de estacas: dos travesaños, estacas puntiagudas, alguna rota y una caída."""
    M = Model(S=2, seed=64)
    for x in range(-48, 48):
        for y in (12, 13, 30, 31): M.put(x, y, 0, P, WOOD_D)
    for i, x0 in enumerate(range(-46, 46, 7)):
        h = 40 if M.hsh(i, 0, 1) > 0.25 else int(14 + 14 * M.hsh(i, 1, 1))   # rotas
        if M.hsh(i, 2, 2) > 0.85:                            # caída al suelo
            for t in range(0, 40):
                for w in range(0, 4): M.put(x0 + w, 0, 2 + t // 2 + (t % 2), P, WOOD)
            continue
        for y in range(0, h):
            for w in range(0, 4):
                if y >= h - 2 and w in (0, 3) and h == 40: continue
                M.put(x0 + w, y, 1, P, lerp(BOARD_D, BOARD, M.noise(x0, y, 0, 6.0)))
    return M, {P: [0, 0, 0]}


def barril():
    M = Model(S=2, seed=65)
    for y in range(0, 30):
        r = 9 + 1.4 * math.sin(y / 29 * math.pi)
        for x in range(-11, 11):
            for z in range(-11, 11):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r or (d < r - 2 and 1 < y < 29): continue
                c = IRON if y in (3, 4, 25, 26) else (WOOD if int(math.atan2(z, x) * 5) % 2 else WOOD_D)
                if y == 29: c = WOOD_D
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def redes():
    """Red de pesca tendida entre dos palos, con agujeros y corchos."""
    M = Model(S=2, seed=66)
    for x0 in (-44, 44):
        for y in range(0, 64):
            for x in (x0 - 1, x0):
                for z in (-1, 0): M.put(x, y, z, P, WOOD_D if y % 9 else WOOD)
    for x in range(-43, 44):
        sag = int(6 * math.cos(x / 44 * math.pi / 2))
        for y in range(10, 60 - sag):
            if (x % 4 == 0 or y % 4 == 0) and M.noise(x, y, 0, 7.0) < 0.7:
                M.put(x, y, 0, P, NET)
        if x % 8 == 0: M.put(x, 59 - sag, 1, P, FLOAT); M.put(x, 58 - sag, 1, P, FLOAT)
    return M, {P: [0, 0, 0]}


def barca():
    """Bote de remos volcado sobre la tierra: casco a lo largo de x, quilla arriba."""
    M = Model(S=2, seed=67)
    for x in range(-56, 56):
        t = abs(x) / 56
        half = 22 * math.sqrt(max(0.0, 1 - t ** 2.2))
        hgt = 20 - 4 * t
        for z in range(-int(half) - 1, int(half) + 1):
            u = abs(z + 0.5) / max(half, 1)
            if u > 1: continue
            y = int(hgt * math.sqrt(max(0.0, 1 - u * u)))
            c = (0.30, 0.38, 0.42) if (y // 3) % 2 else (0.24, 0.30, 0.34)   # pintura azul desconchada
            if M.noise(x, y, z, 5.0) > 0.66: c = WOOD
            for yy in range(max(0, y - 2), y + 1): M.put(x, yy, z, P, c)
        M.put(x, int(hgt) + 1, 0, P, WOOD_D)              # quilla
    for x in range(-10, 30):                              # un remo en el suelo
        M.put(x, 0, 28 + x // 12, P, WOOD); M.put(x, 0, 29 + x // 12, P, WOOD)
    return M, {P: [0, 0, 0]}


def farola():
    """Farola de gas: pie de hierro con basa, fuste estriado, cruceta y linterna de cuatro
    cristales con tejadillo. Pivote "light" en la llama."""
    M = Model(S=3, seed=68)
    H = 140                                               # 2,9 m
    for y in range(0, 10):
        w = 6 - y // 3
        for x in range(-w, w):
            for z in range(-w, w): M.put(x, y, z, P, IRON)
    for y in range(10, H):
        for x in range(-2, 2):
            for z in range(-2, 2):
                if abs(x + 0.5) + abs(z + 0.5) > 3: continue
                M.put(x, y, z, P, IRON_L if (x + z) % 2 and y % 2 else IRON)
    for x in range(-8, 8): M.put(x, H - 22, 0, P, IRON); M.put(x, H - 22, -1, P, IRON)   # cruceta
    LY = H + 10
    for y in range(H, H + 2):
        for x in range(-6, 6):
            for z in range(-6, 6): M.put(x, y, z, P, IRON)
    for y in range(H + 2, H + 20):
        w = 5 + (y - H - 2) // 6
        for x in range(-w, w):
            for z in range(-w, w):
                ex = x in (-w, w - 1); ez = z in (-w, w - 1)
                if not (ex or ez): continue
                M.put(x, y, z, P, IRON if (ex and ez) else LIGHT, glow=0 if (ex and ez) else 1)
    for y in range(H + 4, H + 14):
        for x in (-1, 0):
            for z in (-1, 0): M.put(x, y, z, P, (1.0, 0.70, 0.30), glow=1)
    for i, y in enumerate(range(H + 20, H + 27)):
        w = 9 - i
        for x in range(-w, w):
            for z in range(-w, w): M.put(x, y, z, P, IRON)
    return M, {P: [0, 0, 0], 'light': [0, LY, 0]}


def juncos():
    M = Model(S=2, seed=69)
    for i in range(46):
        a = M.rng.uniform(0, math.tau); r = M.rng.uniform(0, 14)
        x0, z0 = r * math.cos(a), r * math.sin(a)
        h = M.rng.randint(24, 52)
        lean = M.rng.uniform(-0.25, 0.25)
        for y in range(h):
            c = REED if y > h * 0.4 else REED_D
            if y > h - 6 and M.rng.random() < 0.5 and i % 4 == 0: c = (0.32, 0.22, 0.14)   # espadañas
            M.put(x0 + lean * y, y, z0, P, c)
    return M, {P: [0, 0, 0]}


PIECES = {'casa': casa, 'autobus': autobus, 'poste': poste, 'valla': valla, 'barril': barril,
          'redes': redes, 'barca': barca, 'farola': farola, 'juncos': juncos}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/inn_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('inn_%s: %d voxels' % (name, n))
