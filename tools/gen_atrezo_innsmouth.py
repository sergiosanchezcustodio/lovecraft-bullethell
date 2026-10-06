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
Hito 6.2 (las calles y el templo de la Orden):
  fachada    casa georgiana de ladrillo en ruinas, tejado hundido y ventanas rotas (16/m)
  templo     el antiguo templo masónico de la Orden de Dagon: piedra, columnas, frontón con el
             símbolo de la Orden y la puerta entreabierta (16/m)
  escombros  montón de ladrillos y vigas (32/m)
  fuente     fuente seca de la plaza con un pez de bronce (32/m)
  carretilla carretilla de pescado (32/m)
  cajas      cajas de pescado apiladas (32/m)
  nasa       nasa de langostas (32/m)
  pilote     pilote de muelle con cabo (32/m)
  coche      coche abandonado de los años 20 (32/m)

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



# ---------------- hito 6.2 ----------------

STONE = (0.52, 0.51, 0.48); STONE_D = (0.40, 0.39, 0.37); STONE_L = (0.62, 0.61, 0.58)
GREEN = (0.20, 0.34, 0.30)
GOLD_OLD = (0.62, 0.52, 0.28)


def fachada():
    """Casa georgiana de ladrillo, de dos plantas, en ruinas: hueca, con un rincón del tejado
    hundido (falta la pared de arriba), ventanas de guillotina rotas y cornisa clara."""
    M = Model(S=1, seed=71)
    HX, HZ, H = 56, 40, 96                                  # 7 x 5 m, 6 m de alto
    for y in range(0, H):
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                if min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) > 1: continue
                if x > 10 and y > H - 30 + (x - 10) * 0.4 + 8 * M.noise(x, y, z, 6.0): continue   # derrumbe
                c = BRICK if (y // 2 + (x + z) // 4 + (y // 2) % 2 * 2) % 5 else BRICK_D
                if M.noise(x, y, z, 12.0) > 0.7: c = lerp(c, MOSS, 0.4)
                M.put(x, y, z, P, c)
    for x in range(-HX - 1, HX + 1):                        # cornisa e imposta
        for z in (HZ, HZ + 1):
            M.put(x, H - 4, z, P, STONE_L); M.put(x, 48, z, P, STONE_L)
    for cx in (-38, -14, 14, 38):                           # ventanas de guillotina, rotas
        for cy in (26, 70):
            if cy == 70 and cx > 14: continue
            for a in range(-6, 6):
                for b in range(-10, 10):
                    edge = a in (-6, 5) or b in (-10, 9) or b == 0
                    c = TRIM if edge else (DARK if M.hsh(a, b, cx) > 0.25 else GLASS)
                    M.put(cx + a, cy + b, HZ, P, c)
    for x in range(-6, 6):                                  # puerta con montante
        for y in range(0, 36):
            M.put(x, y, HZ, P, DARK if abs(x + 0.5) < 5 and y < 34 else STONE_L)
    for x in range(-HX - 2, 11):                            # lo que queda del tejado
        for z in range(-HZ - 2, HZ + 2):
            y = H + int((HZ - abs(z)) * 0.5)
            if x > 0 and M.hsh(x // 3, z // 3, 1) > 0.6: continue
            M.put(x, y, z, P, ROOF if (x // 4 + z // 3) % 2 else ROOF_D)
    return M, {P: [0, 0, 0]}


def templo():
    """Antiguo templo masónico de la Orden de Dagon: fachada clásica de piedra (14 m de ancho)
    con escalinata, cuatro columnas, frontón con el símbolo de la Orden (un pez en un círculo
    de olas, en oro deslustrado) y la puerta negra entreabierta. Verdín del salitre."""
    M = Model(S=1, seed=72)
    HX, D, H = 112, 28, 128
    for y in range(0, 8):                                   # escalinata
        for x in range(-HX + 20, HX - 20):
            zt = D + 8 + (8 - y) * 3
            for z in range(max(D, zt - 4), zt):                       # solo la huella de cada peldaño
                M.put(x, y, z, P, STONE if (y + z) % 3 else STONE_D)
    for y in range(8, H):                                   # muro de sillares
        for x in range(-HX, HX):
            for z in range(-D, D):
                if min(x + HX, HX - 1 - x, D - 1 - z) > 0 or z == -D: continue   # muro de 1, sin la trasera (no se ve)
                off = (y // 6 % 2) * 6
                c = STONE if (y // 6 + (x + off) // 12) % 2 else lerp(STONE, STONE_D, 0.4)
                if y % 6 == 0 or (x + off) % 12 == 0: c = STONE_D
                if M.noise(x, y, z, 10.0) > 0.66: c = lerp(c, GREEN, 0.45)
                M.put(x, y, z, P, c)
    for cx in (-66, -26, 26, 66):                           # columnas estriadas
        for y in range(8, H - 6):
            for x in range(cx - 5, cx + 5):
                for z in range(D, D + 10):
                    if not 3.5 < math.hypot(x - cx + 0.5, z - D - 5 + 0.5) <= 5: continue
                    c = STONE_L if int(math.atan2(z - D - 5, x - cx) * 4) % 2 else STONE
                    M.put(x, y, z, P, c)
        for y in range(H - 8, H - 4):                       # capiteles
            for x in range(cx - 7, cx + 7):
                for z in range(D - 1, D + 12): M.put(x, y, z, P, STONE_L)
    for y in range(H - 4, H + 4):                           # entablamento
        for x in range(-HX - 2, HX + 2):
            for z in range(D + 9, D + 13): M.put(x, y, z, P, STONE_L if y < H else STONE)
    for y in range(H + 4, H + 44):                          # frontón
        w = HX + 2 - (y - H - 4) * 3
        if w <= 0: break
        for x in range(-w, w):
            for z in range(D + 9, D + 12):
                M.put(x, y, z, P, STONE_L if abs(abs(x) - w) < 2 or y == H + 4 else STONE)
    cy = H + 18
    for a in range(0, 360, 3):                              # símbolo: círculo de olas
        t = math.radians(a)
        r = 11 + 1.5 * math.sin(t * 8)
        M.put(round(r * math.cos(t)), round(cy + r * math.sin(t)), D + 12, P, GOLD_OLD)
    for x in range(-6, 7):                                  # y el pez dentro
        h = int(3 * math.sqrt(max(0.0, 1 - (x / 7) ** 2)))
        for y in range(-h, h + 1): M.put(x, cy + y, D + 12, P, GOLD_OLD)
    for y in range(-3, 4): M.put(-8 - abs(y) // 2, cy + y, D + 12, P, GOLD_OLD)   # cola
    for x in range(-14, 14):                                # puerta en arco, una hoja entreabierta
        for y in range(8, 64):
            if y > 56 and abs(x + 0.5) > 14 - (y - 56) * 2: continue
            M.put(x, y, D, P, DARK if x > -6 else WOOD_D)
    return M, {P: [0, 0, 0]}


def escombros():
    M = Model(S=2, seed=73)
    for i in range(160):
        a = M.rng.uniform(0, math.tau); r = abs(M.rng.gauss(0, 14))
        x, z = r * math.cos(a), r * math.sin(a)
        y = int(max(0, 18 - r * 1.1 + M.rng.uniform(-3, 3)))
        c = BRICK if M.rng.random() < 0.7 else BRICK_D
        for dx in range(3):
            for dz in range(2):
                for yy in range(max(0, y - 2), y + 1): M.put(x + dx, yy, z + dz, P, c)
    for k in range(2):                                      # vigas
        ang = M.rng.uniform(0, math.pi)
        for t in range(-30, 30):
            for w in range(-1, 2):
                M.put(t * math.cos(ang) - w * math.sin(ang), 16 + t * 0.25 * (1 if k else -1),
                      t * math.sin(ang) + w * math.cos(ang), P, WOOD_D)
    return M, {P: [0, 0, 0]}


def fuente():
    """Fuente seca: pilón octogonal de piedra con verdín y un pez de bronce que salta."""
    M = Model(S=2, seed=74)
    for y in range(0, 14):
        for x in range(-40, 40):
            for z in range(-40, 40):
                d = max(abs(x + 0.5), abs(z + 0.5), (abs(x + 0.5) + abs(z + 0.5)) / 1.414)
                if d > 38 or (d < 34 and y > 2): continue
                c = STONE if (y // 3) % 2 else STONE_D
                if y > 10 and M.noise(x, y, z, 6.0) > 0.55: c = GREEN
                M.put(x, y, z, P, c)
    for y in range(0, 30):
        for x in range(-5, 5):
            for z in range(-5, 5): M.put(x, y, z, P, STONE_L)
    BRONZE = (0.30, 0.42, 0.36)
    for x in range(-12, 13):
        h = int(5 * math.sqrt(max(0.0, 1 - (x / 12) ** 2)))
        for y in range(-h, h + 1):
            for z in range(-2, 2): M.put(x, 40 + y + x // 3, z, P, BRONZE)
    for y in range(-6, 7):
        for z in range(-1, 1): M.put(-13 - abs(y) // 2, 36 + y, z, P, BRONZE)
    return M, {P: [0, 0, 0]}


def carretilla():
    M = Model(S=2, seed=75)
    for x in range(-22, 22):
        for z in range(-14, 14):
            for y in range(12, 26):
                if min(x + 22, 21 - x, z + 14, 13 - z) > 1 and y > 13: continue
                M.put(x, y, z, P, WOOD if y % 4 else WOOD_D)
    for x in range(-20, 18, 3):                             # pescado plateado
        for z in range(-12, 12, 4):
            for t in range(5): M.put(x + t // 2, 24, z + t % 2, P, (0.66, 0.70, 0.72) if t else (0.40, 0.44, 0.46))
    for a in range(0, 360, 6):                              # rueda delantera
        t = math.radians(a)
        for r in (9, 10):
            for z in (-1, 0): M.put(24 + r * math.cos(t), 10 + r * math.sin(t), z, P, IRON)
    for z in (-12, 11):                                     # varales y patas
        for x in range(-40, -22): M.put(x, 22 + (x + 22) // 6, z, P, WOOD_D)
        for y in range(0, 12): M.put(-18, y, z, P, WOOD_D)
    return M, {P: [0, 0, 0]}


def cajas():
    M = Model(S=2, seed=76)
    for x0, z0, y0 in ((-14, -10, 0), (12, -8, 0), (-2, 12, 0), (-4, -6, 14)):
        for x in range(x0 - 12, x0 + 12):
            for z in range(z0 - 9, z0 + 9):
                for y in range(y0, y0 + 14):
                    if min(x - x0 + 12, x0 + 11 - x, z - z0 + 9, z0 + 8 - z) > 0 and y < y0 + 13: continue
                    c = PLANK if (y // 3) % 2 else PLANK_D
                    if y == y0 + 13 and (x + z) % 5 == 0: c = (0.60, 0.64, 0.66)
                    M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def nasa():
    M = Model(S=2, seed=77)
    for x in range(-18, 18):
        for z in range(-12, 12):
            for y in range(0, 14):
                if y < 2: M.put(x, y, z, P, WOOD); continue
                r = math.hypot(z, y - 2)
                if abs(r - 11) < 1 and (x % 4 == 0 or (z + y) % 3 == 0): M.put(x, y, z, P, NET)
    return M, {P: [0, 0, 0]}


def pilote():
    M = Model(S=2, seed=78)
    for y in range(0, 40):
        for x in range(-5, 5):
            for z in range(-5, 5):
                if math.hypot(x + 0.5, z + 0.5) > 5: continue
                c = lerp(WOOD_D, (0.18, 0.20, 0.16), 0.5) if y < 12 else (WOOD if (x + y) % 5 else WOOD_D)
                M.put(x, y, z, P, c)
    for i in range(30):                                     # cabo enrollado
        a = i / 30 * math.tau * 2
        M.put(6 * math.cos(a), 30 - i // 3, 6 * math.sin(a), P, (0.58, 0.52, 0.38))
    return M, {P: [0, 0, 0]}


def coche():
    """Coche cerrado de los años 20, abandonado: carrocería negra desconchada con óxido, capó
    largo, ruedas de radios y lunas rotas."""
    M = Model(S=2, seed=79)
    BODY = (0.12, 0.13, 0.14); BODY_L = (0.22, 0.23, 0.24)
    for x in range(-60, 60):
        for z in range(-26, 26):
            for y in range(14, 60):
                hood = x > 10
                if hood and y > 36: continue
                top = 35 if hood else 59
                if min(x + 60, 59 - x, z + 26, 25 - z) > 1 and y < top: continue
                win = 38 < y < 56 and -54 < x < 6 and z in (-26, 25) and (x + 54) % 20 > 2
                if win: c = DARK if M.hsh(x // 6, y // 6, 3) > 0.4 else GLASS
                else: c = RUST if M.noise(x, y, z, 5.0) > 0.8 else (BODY if y % 5 else BODY_L)
                M.put(x, y, z, P, c)
    for cx in (-40, 40):
        for s in (-1, 1):
            for a in range(-13, 14):
                for b in range(0, 26):
                    r = math.hypot(a, b - 13)
                    if r > 13: continue
                    c = TIRE if r > 9 else (IRON_L if abs(a) < 1 or abs(b - 13) < 1 else IRON)
                    for dz in range(3): M.put(cx + a, b, s * (26 + dz), P, c)
    for z in (-14, 13):
        for y in (30, 31): M.put(60, y, z, P, (0.68, 0.64, 0.50))
    return M, {P: [0, 0, 0]}


PIECES = {'casa': casa, 'autobus': autobus, 'poste': poste, 'valla': valla, 'barril': barril,
          'redes': redes, 'barca': barca, 'farola': farola, 'juncos': juncos,
          'fachada': fachada, 'templo': templo, 'escombros': escombros, 'fuente': fuente,
          'carretilla': carretilla, 'cajas': cajas, 'nasa': nasa, 'pilote': pilote, 'coche': coche}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/inn_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('inn_%s: %d voxels' % (name, n))
