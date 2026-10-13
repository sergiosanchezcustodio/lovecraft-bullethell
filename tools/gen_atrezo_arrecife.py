"""Atrezo del Arrecife del Diablo y de Y'ha-nthlei (hito 6.5). Una parte "body", origen en el
centro de la base, como gen_atrezo_pantano.py.

  columna_1/2  columna ciclópea de piedra verdinegra, partida y medio hundida, con relieves de
               peces y olas y algas en la base (32/m)
  arco         arco caído de sillares enormes (16/m: pieza grande)
  bloque       bloque tallado volcado con un ojo de pez en relieve (32/m)
  roca_1/2     roca negra del arrecife, de caras planas, con percebes y algas (32/m)
  coral        coral negro ramificado con las puntas que brillan en verde (32/m)
  muro         tramo de muro de Y'ha-nthlei, semiderruido y mohoso, para el borde norte y oeste
               (16/m exportado a 8/m: pieza de borde)

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
    """Bloque tallado volcado del arrecife (rehecho a 64/m en la revisión de arte del 13-10-2026):
    sillar de basalto verdinegro medio hundido y algo girado, con las aristas comidas por el mar;
    en la cara, un ojo de pez enorme en relieve con su párpado, pupila y escamas alrededor, y una
    franja de olas; percebes y mejillones, algas que cuelgan, verdín y caracolas en la base, y un
    trozo que se partió al caer."""
    M = Model(S=4, seed=94)
    rng = M.rng
    X, Y, Z = 56, 58, 40
    BAS = (0.17, 0.21, 0.20); BAS_D = (0.10, 0.13, 0.12); BAS_L = (0.26, 0.30, 0.28)
    MUSSEL = (0.10, 0.10, 0.16); SHELL = (0.66, 0.60, 0.50)
    def eaten(x, y, z):
        e = min(x + X, X - 1 - x) + min(y, Y - 1 - y) + min(z + Z, Z - 1 - z)
        return e < 5 + 6 * M.noise(x, y, z, 6.0)
    for x in range(-X, X):
        for y in range(0, Y):
            tilt = int((x + X) * 0.12)
            for z in range(-Z, Z):
                if min(x + X, X - 1 - x, y, Y - 1 - y, z + Z, Z - 1 - z) > 1: continue
                if eaten(x, y, z) and min(x + X, X - 1 - x, Y - 1 - y, z + Z, Z - 1 - z) < 4: continue
                c = lerp(BAS, BAS_D, M.noise(x, y, z, 6.0))
                if M.noise(x, y, z, 2.0) > 0.82: c = BAS_L
                if (x + 2 * y + z) % 17 == 0: c = lerp(c, BAS_D, 0.5)              # picaduras
                if y < 14 and M.noise(x, y + 30, z, 5.0) > 0.4: c = lerp((0.17, 0.28, 0.14), (0.11, 0.19, 0.09), M.noise(x, y, z, 2.0))
                M.put(x, y + tilt // 4, z, P, c)
    # cara tallada (z = Z - 1): ojo de pez en relieve
    fz = Z
    cx, cy = 0, 30
    for x in range(-X + 4, X - 4):
        for y in range(4, Y - 4):
            yy = y + int((x + X) * 0.12) // 4
            dx, dy = x - cx, y - cy
            e = (dx / 30.0) ** 2 + (dy / 16.0) ** 2
            c = None
            if 0.82 < e < 1.0: c = BAS_L                                                  # párpado
            elif e <= 0.82:
                r = math.hypot(dx / 1.4, dy)
                if r < 7: c = (0.03, 0.04, 0.04)                                           # pupila
                elif r < 12: c = lerp(BAS, (0.22, 0.32, 0.26), 0.6)                         # iris
                elif r < 13: c = BAS_D
                else: c = BAS
            elif e < 2.2 and ((dx // 5 + dy // 4) % 2 == 0) and (dx % 5) and (dy % 4): c = lerp(BAS, BAS_L, 0.4)   # escamas
            if y < 10 and abs(math.sin(x / 6.0) * 3 - (y - 6)) < 1.2: c = BAS_L            # franja de olas
            if c is None: continue
            M.put(x, yy, fz, P, c)
            if e <= 1.0 and 0.82 < e: M.put(x, yy, fz + 1, P, c)
    for _ in range(140):                                             # percebes y mejillones
        x, z = rng.randint(-X, X - 1), rng.choice((Z, -Z - 1, rng.randint(-Z, Z - 1)))
        y = rng.randint(0, 20)
        M.put(x, y, z, P, BARN if rng.random() < 0.6 else MUSSEL)
    for _ in range(14):                                              # algas que cuelgan del canto
        x = rng.randint(-X, X - 1)
        for k in range(rng.randint(4, 14)): M.put(x, Y - 3 - k + int((x + X) * 0.12) // 4, Z, P, WEED if k % 3 else WEED_D)
    for _ in range(12):                                              # caracolas al pie
        x, z = rng.randint(-X - 10, X + 10), rng.randint(Z, Z + 14)
        M.put(x, 0, z, P, SHELL); M.put(x + 1, 0, z, P, SHELL)
    for x in range(X - 2, X + 22):                                   # trozo partido al lado
        for z in range(-10, 14):
            for y in range(0, 16):
                if ((x - X - 10) / 12) ** 2 + (y / 16) ** 2 + ((z - 2) / 12) ** 2 > 1: continue
                M.put(x, y, z, P, lerp(BAS, BAS_D, M.noise(x, y, z, 3.0)))
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
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

M_STONE_D = (0.13, 0.16, 0.15); M_STONE_L = (0.36, 0.40, 0.37); M_JOINT = (0.05, 0.07, 0.06)
MOSS = (0.24, 0.38, 0.16); MOSS_D = (0.14, 0.25, 0.10); MOSS_L = (0.36, 0.50, 0.22)
SLIME = (0.10, 0.17, 0.12); SALT = (0.50, 0.54, 0.50); M_BARN = (0.66, 0.64, 0.56); M_BARN_D = (0.40, 0.38, 0.33)
M_GLOW = (0.30, 0.85, 0.50)


def _halve(M):
    """De 16/m a 8/m: cada bloque de 2x2x2 queda si tiene algún voxel, con el color del de más
    arriba (para que el musgo de los rellanos no se pierda)."""
    half = Model(S=1, seed=0)
    best = {}
    for (x, y, z), v in M.V.items():
        k = (x // 2, y // 2, z // 2)
        if k not in best or y > best[k][0] or (y == best[k][0] and v[2] > best[k][1][2]):
            best[k] = (y, v)
    for k, (_, v) in best.items(): half.V[k] = v
    half.S = 0.5
    return half


def muro():
    """Muro ciclópeo de Y'ha-nthlei, semiderruido (rehecho en la revisión de arte del 13-10-2026):
    24 m de largo y hasta 8 de alto. Hiladas de sillares enormes de tamaños distintos, cada uno con
    su tono y algunos salidos o hundidos; juntas hondas; dos brechas donde se han caído los bloques
    de arriba, que están volcados al pie con cascotes; musgo en los rellanos y colgando de las
    juntas, chorretones verdinegros, una franja de algas y una línea de sal en la base, percebes,
    picaduras, grietas (alguna con el fulgor verde del arrecife) y un friso de peces en relieve.
    Hecho a 16/m y exportado a 8/m."""
    M = Model(S=1, seed=98)
    rng = M.rng
    L, H, T = 192, 128, 24
    # hiladas y bloques (cortes en números pares para que las juntas sobrevivan a 8/m)
    courses, y = [], 0
    while y < H:
        h = 2 * rng.randint(10, 18)
        if y + h > H - 12: h = H - y
        courses.append((y, y + h)); y += h
    blocks = []                                                       # (ci, x0, x1, y0, y1, salida)
    for ci, (ya, yb) in enumerate(courses):
        x = -L - 2 * rng.randint(0, 14)
        while x < L:
            w = 2 * rng.randint(14, 34)
            blocks.append((ci, x, min(L, x + w), ya, yb, 2 * rng.randint(-1, 1) if ci > 0 else 0))
            x += w
    # brechas: los bloques que quedan por encima de la línea de rotura se han caído
    breaches = [(-90, 70, 52), (110, 50, 40)]                         # (centro, profundidad, ancho)
    def broken(xc, ya):
        line = H - 4
        for bx, dp, wd in breaches: line -= dp * math.exp(-((xc - bx) / wd) ** 2)
        line -= 26 * M.noise(xc, 0, 0, 40.0)
        return ya >= line
    keep, fallen = [], []
    for b in blocks:
        ci, x0, x1, ya, yb, off = b
        if broken((x0 + x1) / 2, ya) or (ci == len(courses) - 1 and M.hsh(x0, ci, 1) > 0.6): fallen.append(b)
        else: keep.append(b)
    def block_at(x, y):
        for b in keep:
            if b[1] <= x < b[2] and b[3] <= y < b[4]: return b
        return None
    grid = {}                                                          # (x, y) -> bloque, por columnas
    for b in keep:
        for x in range(b[1], b[2]):
            for y in range(b[3], b[4]): grid[(x, y)] = b
    def occ(x, y, z):
        b = grid.get((x, y))
        if b is None: return False
        ci, x0, x1, ya, yb, off = b
        front = -1 + off
        if z > front or z < -T: return False
        # junta honda: dos voxels de ancho y dos de fondo en la cara delantera
        if z >= front - 1 and (x - x0 < 2 or y - ya < 2) and x0 > -L and ya > 0: return False
        # esquinas gastadas del bloque
        cu = min(x - x0, x1 - 1 - x); cv = min(y - ya, yb - 1 - y)
        if z >= front - 3 and cu + cv < 3: return False
        # picaduras
        if z == front and M.hsh(x // 2, y // 2, 5) > 0.97: return False
        return True
    for (x, y), b in grid.items():
        for z in range(-T, 1 + b[5]):
            if not occ(x, y, z): continue
            if all(occ(x + a, y + c, z + d) for a, c, d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))):
                continue
            M.put(x, y, z, P, ('w', b))
    # bloques caídos al pie, delante, algo volcados, y cascotes
    for i, b in enumerate(fallen[:9]):
        ci, x0, x1, ya, yb, off = b
        w, h = min(x1 - x0, 50), yb - ya
        cx = (x0 + x1) // 2 + rng.randint(-10, 10)
        cz = rng.randint(6, 30)
        tilt = rng.uniform(-0.25, 0.25)
        d = rng.randint(16, 24)
        for x in range(cx - w // 2, cx + w // 2):
            for z in range(cz - d // 2, cz + d // 2):
                lift = int(abs(tilt) * (x - cx + w // 2)) if tilt > 0 else int(abs(tilt) * (cx + w // 2 - x))
                for y in range(lift // 2, lift // 2 + h - 2):
                    u, v, wz = x - cx + w // 2, y - lift // 2, z - cz + d // 2
                    if min(u, w - 1 - u) + min(v, h - 3 - v) + min(wz, d - 1 - wz) < 3: continue   # cantos rotos
                    if 0 < u < w - 1 and 0 < v < h - 3 and 0 < wz < d - 1: continue
                    M.put(x, y, z, P, ('f', i))
    for _ in range(70):                                                # cascotes
        cx, cz = rng.randint(-L, L), rng.randint(0, 36)
        if not any(abs(cx - (b[1] + b[2]) / 2) < 80 for b in fallen): continue
        s = rng.randint(3, 7)
        for x in range(cx, cx + s):
            for z in range(cz, cz + s):
                for y in range(0, rng.randint(2, s)): M.put(x, y, z, P, ('f', 99))
    # color
    tops = {}
    for (x, y, z) in M.V:
        if y > tops.get((x, z), -1): tops[(x, z)] = y
    crack_cells = set()
    for _ in range(14):                                                # grietas que bajan por la cara
        x, y = rng.randint(-L + 10, L - 10), rng.randint(40, H)
        for _ in range(rng.randint(14, 40)):
            crack_cells.add((x, y)); crack_cells.add((x + 1, y))
            y -= 1; x += rng.choice((-1, 0, 0, 1))
            if y < 4: break
    streak = {x: M.hsh(x // 2, 3, 3) for x in range(-L - 40, L + 40)}
    def paint(k, part, c):
        if not (isinstance(c, tuple) and c and isinstance(c[0], str)): return None
        x, y, z = k
        if c[0] == 'w':
            ci, x0, x1, ya, yb, off = c[1]
            front = -1 + off
            col = lerp(M_STONE_D, M_STONE_L, 0.15 + 0.6 * M.hsh(ci, x0, 7))
            col = lerp(col, M_STONE_D, 0.35 * M.noise(x, y, z, 6.0))
            if M.noise(x, y, z, 2.5) > 0.80: col = lerp(col, M_STONE_L, 0.4)     # moteado
            if z < front - 1 and z > -T: col = lerp(col, M_JOINT, 0.6)           # dentro de las juntas
            if (x, y) in crack_cells and z >= front - 1:
                col = M_JOINT
                if M.hsh(x, y, 9) > 0.93 and y < 60: return M_GLOW
            if streak[x] > 0.82 and z >= front - 1:                              # chorretones
                col = lerp(col, SLIME, 0.55 * M.noise(x, y, 1, 10.0) + 0.2)
        else:
            col = lerp(M_STONE_D, M_STONE_L, 0.25 + 0.5 * M.hsh(c[1], 2, 2))
            col = lerp(col, M_STONE_D, 0.4 * M.noise(x, y, z, 5.0))
        # musgo en lo alto y colgando unos voxels
        t = tops.get((x, z), -1)
        if y >= t - 1: col = lerp(MOSS_D, MOSS_L, M.noise(x, y, z, 3.0)) if M.noise(x, 7, z, 5.0) > 0.3 else col
        elif t - y < 2 + 6 * M.noise(x, t, z, 4.0) and M.noise(x, 9, z, 6.0) > 0.45: col = lerp(MOSS_D, MOSS, M.noise(x, y, z, 2.0))
        # algas en la base, línea de sal y percebes
        wl = 18 + 8 * M.noise(x, 0, z, 12.0)
        if y < wl: col = lerp(SLIME, MOSS_D, M.noise(x, y, z, 3.0))
        elif y < wl + 3: col = lerp(col, SALT, 0.55)
        elif y < 54 and M.noise(x, y, z, 6.0) > 0.62 and M.hsh(x, y, z) > 0.55:
            col = M_BARN if M.hsh(x, y, z + 1) > 0.4 else M_BARN_D
        return col
    M.paint(paint)
    for v in M.V.values():
        if v[1] == M_GLOW: v[2] = 1
    # friso de peces en relieve en la hilada que cae hacia 4,5-6 m (sobre bloques que siguen en pie)
    fy = 80
    for fx in range(-L + 20, L - 20, 44):
        b = grid.get((fx, fy))
        if b is None or grid.get((fx + 18, fy + 6)) is not b: continue
        front = -1 + b[5]
        for dx in range(0, 18):
            for dy in range(-5, 6):
                body = (dx / 13 - 0.5) ** 2 * 4 + (dy / 5) ** 2 < 1 and dx < 13
                tail = 13 <= dx < 18 and abs(dy) <= (dx - 12)
                if not (body or tail): continue
                c = M_STONE_L if body else lerp(M_STONE_L, M_STONE_D, 0.3)
                if (dx, dy) in ((3, 1), (3, 2), (4, 1), (4, 2)): c = M_JOINT              # ojo
                if body and dx in (6, 9) and abs(dy) < 4: c = lerp(c, M_JOINT, 0.5)        # escamas/agallas
                for zz in (front + 1, front + 2): M.put(fx + dx, fy + dy, zz, P, c)
    return _halve(M), {P: [0, 0, 0]}


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
