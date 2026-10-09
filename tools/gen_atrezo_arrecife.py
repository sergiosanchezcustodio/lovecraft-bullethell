"""Atrezo del Arrecife del Diablo y de Y'ha-nthlei (hito 6.5). Una parte "body", origen en el
centro de la base, como gen_atrezo_pantano.py.

  columna_1/2  columna ciclópea de piedra verdinegra, partida y medio hundida, con relieves de
               peces y olas y algas en la base (32/m)
  arco         arco caído de sillares enormes (16/m: pieza grande)
  bloque       bloque tallado volcado con un ojo de pez en relieve (32/m)
  roca_1/2     roca negra del arrecife, de caras planas, con percebes y algas (32/m)
  coral        coral negro ramificado con las puntas que brillan en verde (32/m)
  muro         tramo de muro sumergido de Y'ha-nthlei para el borde norte y oeste (8/m: pieza de borde)

Escribe models/arr_<pieza>.json. Uso: python tools/gen_atrezo_arrecife.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
STONE = (0.20, 0.25, 0.23); STONE_D = (0.13, 0.17, 0.16); STONE_L = (0.28, 0.33, 0.30)
CARVE = (0.09, 0.12, 0.11)
ROCK = (0.11, 0.12, 0.13); ROCK_L = (0.19, 0.20, 0.21); ROCK_D = (0.06, 0.07, 0.08)
WEED = (0.17, 0.28, 0.14); WEED_D = (0.11, 0.19, 0.09)
BARN = (0.55, 0.55, 0.50)
CORAL = (0.08, 0.08, 0.09); CORAL_L = (0.16, 0.15, 0.17)
GLOW = (0.35, 1.0, 0.55)


def stone(M, x, y, z):
    c = lerp(STONE, STONE_D, M.noise(x, y, z, 8.0))
    if M.noise(x, y, z, 3.0) > 0.78: c = STONE_L
    if y < 10 and M.noise(x, y + 40, z, 5.0) > 0.45: c = lerp(WEED, WEED_D, M.noise(x, y, z, 2.0))
    return c


# ---------------- columnas ----------------

def columna(seed, H, lean):
    """Fuste octogonal de 1,6 m de ancho, partido arriba en bisel, con bandas de relieves: peces
    (rombos con cola) y olas (zigzag) en surco oscuro. Algo inclinada y hundida en el arrecife."""
    M = Model(S=2, seed=seed)
    R = 26
    top = lambda x, z: H - int((x + z) * 0.35) - int(M.hsh(x // 4, 0, z // 4) * 4)   # rotura en bisel
    for y in range(0, H + 20):
        off = int(y * lean)
        for x in range(-R, R):
            for z in range(-R, R):
                if abs(x + 0.5) + abs(z + 0.5) > R * 1.42: continue    # octógono
                if y > top(x, z): continue
                edge = abs(x + 0.5) > R - 2.5 or abs(z + 0.5) > R - 2.5 or abs(x + 0.5) + abs(z + 0.5) > R * 1.42 - 2.5
                if not edge and y < top(x, z) - 2: continue             # hueca
                c = stone(M, x, y, z)
                band = y % 36
                if edge and 12 <= band <= 22:                           # banda de relieves
                    u = (math.atan2(z, x) / math.tau * 48) % 12
                    v = band - 12
                    fish = abs(u - 6) + abs(v - 5) * 1.6 < 4 or (u < 2.5 and abs(v - 5) < u + 0.5)
                    if fish: c = CARVE
                if edge and band in (8, 26) and (int(math.atan2(z, x) * 20) + y) % 4 < 2: c = CARVE   # olas
                M.put(x + off, y, z, P, c)
    return M, {P: [0, 0, 0]}


def columna_1(): return columna(91, 104, 0.04)
def columna_2(): return columna(92, 66, -0.08)


# ---------------- arco ----------------

def arco():
    """Arco de medio punto de sillares de 1 m, con un lado caído: un pilar en pie, la mitad
    del arco y los sillares del otro lado tirados en el suelo. 16/m."""
    M = Model(S=1, seed=93)
    W, Hp, T = 40, 56, 14                                              # medio vano, alto del pilar, grosor
    def blk(x, y, z, k):
        c = stone(M, x, y, z)
        if (x % 16 == 0) or (y % 16 == 0): c = CARVE                    # juntas de sillares
        return c
    for x in range(-W - 14, -W):                                        # pilar izquierdo entero
        for y in range(0, Hp):
            for z in range(-T // 2, T // 2): M.put(x, y, z, P, blk(x, y, z, 0))
    for a in range(0, 70):                                              # media rosca del arco (se corta)
        t = math.radians(180 - a * 1.3)
        if a * 1.3 > 95: break
        for r in range(W, W + 14):
            x = int(r * math.cos(t)); y = Hp + int(r * math.sin(t))
            for z in range(-T // 2, T // 2): M.put(x, y, z, P, blk(x, y, z, 1))
    for x in range(W, W + 14):                                          # pilar derecho roto
        for y in range(0, 22 - (x - W)):
            for z in range(-T // 2, T // 2): M.put(x, y, z, P, blk(x, y, z, 0))
    for i, (cx, cz, a) in enumerate(((W + 26, 10, 0.4), (W + 10, -22, 1.1), (W + 40, -8, 2.0))):   # sillares caídos
        for u in range(-8, 8):
            for v in range(-7, 7):
                for y in range(0, 14):
                    x = int(cx + u * math.cos(a) - v * math.sin(a)); z = int(cz + u * math.sin(a) + v * math.cos(a))
                    M.put(x, y, z, P, stone(M, x, y, z))
    return M, {P: [0, 0, 0]}


# ---------------- bloque ----------------

def bloque():
    M = Model(S=2, seed=94)
    for x in range(-28, 28):
        for y in range(0, 30):
            for z in range(-20, 20):
                if min(x + 28, 27 - x, y, 29 - y, z + 20, 19 - z) > 1: continue
                c = stone(M, x, y, z)
                if z == 19:                                             # cara tallada: un ojo de pez
                    d = math.hypot(x / 1.6, y - 15)
                    if 6 < d < 8.5 or d < 3: c = CARVE
                    if abs(y - 15) < 1 and 8.5 < abs(x) < 24: c = CARVE
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


# ---------------- rocas ----------------

def roca(seed, rx, ry, rz):
    """Roca negra de caras planas (sell), con percebes arriba y algas abajo."""
    M = Model(S=2, seed=seed)
    M.sell(0, ry * 0.45, 0, rx, ry, rz, P, ROCK, p=2.6)
    M.sell(rx * 0.4, ry * 0.7, rz * 0.2, rx * 0.6, ry * 0.7, rz * 0.6, P, ROCK, p=2.6)
    inside = [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in
              ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1), (2, 0, 0), (-2, 0, 0), (0, 2, 0), (0, 0, 2), (0, 0, -2)))]
    for k in inside: del M.V[k]                                        # hueca: solo la cáscara
    for k, v in list(M.V.items()):
        x, y, z = k
        c = lerp(ROCK, ROCK_L, M.noise(x, y, z, 6.0) * 0.8)
        if M.noise(x, y, z, 2.5) > 0.75: c = ROCK_D
        if y < 6 and M.noise(x, y + 9, z, 4.0) > 0.4: c = WEED
        exposed = (x, y + 1, z) not in M.V
        if exposed and M.hsh(x // 2, y, z // 2) > 0.975: c = BARN
        M.V[k] = [P, c, 0]
    return M, {P: [0, 0, 0]}


def roca_1(): return roca(95, 18, 10, 14)
def roca_2(): return roca(96, 12, 16, 11)


# ---------------- coral ----------------

def coral():
    """Coral negro del arrecife (rehecho el 09-10-2026), 32/m, ~1,2 m: sobre una roca de basalto
    con percebes, ramas gruesas que se afinan al bifurcarse (pólipos más claros), puntas con un
    núcleo que brilla en verde, un abanico de mar rojizo y esponjas de tubo. Es la luz del
    arrecife (pivote "light")."""
    M = Model(S=2, seed=97)
    rng = M.rng
    POLYP = (0.30, 0.27, 0.30); FAN = (0.34, 0.12, 0.16); FAN_D = (0.22, 0.07, 0.10)
    SPONGE = (0.27, 0.26, 0.22); SPONGE_D = (0.17, 0.16, 0.14); GLOW_C = (0.75, 1.0, 0.80)
    # roca base
    for x in range(-14, 15):
        for z in range(-14, 15):
            d = math.hypot(x, z) * (1 + 0.3 * M.noise(x, 0, z, 6.0))
            if d > 13: continue
            h = int(8 * (1 - d / 13) ** 0.7)
            for y in range(0, h + 1):
                c = lerp(ROCK_D, ROCK_L, M.noise(x, y, z, 3.0))
                if y == h and M.hsh(x, y, z) < 0.12: c = BARN
                if y == h and M.noise(x + 9, y, z, 4.0) > 0.66: c = WEED
                M.put(x, y, z, P, c)

    def ball(cx, cy, cz, r, col, glow=0):
        for x in range(int(cx - r) - 1, int(cx + r) + 2):
            for y in range(int(cy - r) - 1, int(cy + r) + 2):
                for z in range(int(cz - r) - 1, int(cz + r) + 2):
                    if (x - cx) ** 2 + (y - cy) ** 2 + (z - cz) ** 2 <= r * r:
                        M.put(x, y, z, P, col, glow=glow)

    def grow(x, y, z, ang, up, n, r, depth):
        for i in range(n):
            x += math.cos(ang) * 0.9; z += math.sin(ang) * 0.9; y += up
            ang += rng.uniform(-0.15, 0.15)
            col = CORAL if (i + depth) % 4 else (POLYP if M.hsh(int(x), int(y), int(z)) < 0.5 else CORAL_L)
            ball(x, y, z, r, col)
        if depth == 0 or r < 0.9:
            ball(x, y + 1, z, 1.4, GLOW, glow=1)                 # punta que brilla, con núcleo claro
            M.put(int(x), int(y + 1), int(z), P, GLOW_C, glow=1)
            return
        for k in range(2 if depth > 1 else rng.choice((2, 3))):
            grow(x, y, z, ang + rng.uniform(-1.1, 1.1), max(up + rng.uniform(-0.15, 0.3), 0.5),
                 int(n * 0.72), r * 0.72, depth - 1)
    for k in range(3):
        grow(0, 6, 0, k * 2.1 + rng.uniform(0, 0.6), 1.0, 12, 2.4, 3)
    # abanico de mar: celosía plana rojiza a un lado
    fx, fz = 9, -6
    for u in range(-9, 10):
        for v in range(0, 22):
            if (u / 9.5) ** 2 + ((v - 11) / 11.5) ** 2 > 1: continue
            if (u + v) % 3 and (u - v) % 3 and abs(u) > 0 and v % 4: continue   # celosía
            M.put(fx + u, 6 + v, fz + u // 3, P, FAN if (u * 3 + v) % 5 else FAN_D)
    # esponjas de tubo
    for tx, tz, th in ((-8, 7, 14), (-10, 3, 10), (-5, 10, 8)):
        for y in range(4, 4 + th):
            for x in range(tx - 2, tx + 3):
                for z in range(tz - 2, tz + 3):
                    d = math.hypot(x - tx, z - tz)
                    if 1.2 <= d <= 2.3: M.put(x, y, z, P, SPONGE if y % 3 else SPONGE_D)
    return M, {P: [0, 0, 0], 'light': [0, 30, 0]}                     # el fulgor verde del arrecife


# ---------------- muro ----------------

def muro():
    """Muro ciclópeo de Y'ha-nthlei: 24 m de largo y 8 de alto, sillares enormes desiguales,
    algunos caídos, con algas en la base y un friso de peces. Hecho a 16/m y exportado a 8/m."""
    M = Model(S=1, seed=98)
    L, H, T = 192, 128, 24
    for x in range(-L, L):
        h = H - int(M.noise(x, 0, 0, 30.0) * 40) - (30 if M.hsh(x // 40, 1, 0) > 0.75 else 0)
        for y in range(0, h):
            for z in range(-T, 0):
                if z > -T + 2 and y < h - 2 and -T + 2 < z: continue       # hueco
                c = stone(M, x, y, z)
                if (x + (y // 32) * 13) % 37 == 0 or y % 32 == 0: c = CARVE
                if 70 <= y <= 80 and z == -1 and (x // 6) % 3 == 0: c = CARVE
                M.put(x, y, z, P, c)
    half = Model(S=1, seed=0)                                          # a 8/m: uno de cada 2x2x2
    for (x, y, z), v in M.V.items():
        if x % 2 == 0 and y % 2 == 0 and z % 2 == 0: half.V[(x // 2, y // 2, z // 2)] = v
    half.S = 0.5
    return half, {P: [0, 0, 0]}


PIECES = {'columna_1': columna_1, 'columna_2': columna_2, 'arco': arco, 'bloque': bloque,
          'roca_1_mano': roca_1,   # la del juego es de Replicate
           'roca_2_mano': roca_2,   # la del juego es de Replicate
           'coral': coral, 'muro': muro}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/arr_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.7, specular=0.35, no_bottom=True)
        print('arr_%s: %d voxels' % (name, n))
