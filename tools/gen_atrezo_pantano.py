"""Atrezo de los pantanos y la vía muerta a Rowley (hito 6.4). Una parte "body", origen en el
centro de la base, como gen_atrezo_innsmouth.py.

  via        tramo de vía de 4 m a lo largo de x: traviesas podridas (alguna falta) y dos raíles
             oxidados. Todo por debajo de 0,15 m: se anda por encima (32/m)
  vagoneta   vagón de mercancías volcado de lado, tablas, ruedas al aire y la puerta caída (32/m)
  senal      poste de señales con su brazo de semáforo y el farol rojo (pivote "light") (48/m)
  apeadero   la caseta del apeadero de Rowley: tablas, tejadillo, andén y el letrero (16/m)
  arbol_1/2  árbol muerto del pantano, retorcido y sin hojas, con musgo colgando (32/m)
  tocon      tocón podrido con raíces (32/m)
  caballete  tramo del puente de caballetes roto: pies, riostras y vigas caídas (32/m)

Escribe models/pan_<pieza>.json. Uso: python tools/gen_atrezo_pantano.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
SLEEPER = (0.30, 0.24, 0.18); SLEEPER_D = (0.20, 0.16, 0.12); ROT = (0.24, 0.28, 0.18)
RAIL = (0.30, 0.20, 0.13); RAIL_L = (0.46, 0.30, 0.18); IRON = (0.15, 0.15, 0.16); IRON_L = (0.28, 0.28, 0.29)
WAGON = (0.40, 0.20, 0.15); WAGON_D = (0.29, 0.14, 0.11); WAGON_L = (0.50, 0.30, 0.22)
BOARD = (0.46, 0.43, 0.38); BOARD_D = (0.34, 0.32, 0.28); BOARD_G = (0.30, 0.34, 0.28)
ROOF = (0.19, 0.20, 0.21); ROOF_D = (0.14, 0.15, 0.16)
BARK = (0.24, 0.22, 0.20); BARK_D = (0.16, 0.15, 0.14); BARK_L = (0.36, 0.34, 0.31)
MOSS = (0.36, 0.40, 0.28); MOSS_D = (0.26, 0.30, 0.20)
SIGN = (0.80, 0.78, 0.70); RED = (0.62, 0.12, 0.10); WHITE = (0.80, 0.78, 0.72)
DARK = (0.05, 0.05, 0.06)
LAMP = (1.0, 0.36, 0.20)


def box(M, x0, x1, y0, y1, z0, z1, col):
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                M.put(x, y, z, P, col(x, y, z) if callable(col) else col)


def line(M, a, b, r, col):
    """Cilindro de a a b (voxels) de radio r, con color fijo o función."""
    n = int(max(abs(b[i] - a[i]) for i in range(3))) + 1
    for k in range(n + 1):
        t = k / max(n, 1)
        cx, cy, cz = (a[i] + (b[i] - a[i]) * t for i in range(3))
        ri = int(math.ceil(r))
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    if x * x + y * y + z * z > r * r + 0.3: continue
                    q = (int(round(cx + x)), int(round(cy + y)), int(round(cz + z)))
                    M.put(*q, P, col(*q) if callable(col) else col)


# ---------------- vía ----------------

def via():
    """4 m de vía (x de -64 a 64 a 32/m). Traviesas de 2,4 x 0,22 m cada 0,6 m (2 voxels de
    alto); raíles de 2 voxels encima a 1,44 m entre sí. Alguna traviesa falta o está partida."""
    M = Model(S=2, seed=81)
    for i, x0 in enumerate(range(-62, 62, 19)):
        h = M.hsh(i, 0, 1)
        if h < 0.12: continue                                     # falta la traviesa
        broken = h > 0.85
        for x in range(x0, x0 + 7):
            for z in range(-38, 38):
                if broken and -6 < z < 4: continue                # partida en dos
                c = lerp(SLEEPER, SLEEPER_D, M.noise(x, 0, z, 6.0))
                if M.noise(x, 3, z, 4.0) > 0.72: c = ROT
                for y in range(2): M.put(x, y, z, P, c)
    for zr in (-24, 23):                                          # raíles: patín, alma y cabeza
        for x in range(-64, 64):
            if zr > 0 and 30 < x < 44: continue                   # un tramo de raíl arrancado
            rust = lerp(RAIL, RAIL_L, M.noise(x, 2, zr, 5.0))
            for z in (zr - 1, zr, zr + 1): M.put(x, 2, z, P, rust)
            M.put(x, 3, zr, P, RAIL_L if M.hsh(x, 3, zr) > 0.6 else rust)
    return M, {P: [0, 0, 0]}


# ---------------- vagoneta ----------------

def vagoneta():
    """Vagón de mercancías de caja roja volcado sobre su costado: la caja tumbada (3,6 m de
    largo, 1,5 de alto tumbada), el bastidor y las ruedas hacia +z, la puerta corredera caída
    al suelo. Hueco."""
    M = Model(S=2, seed=82)
    L, H, W = 58, 48, 34                                          # medio largo, alto tumbado, ancho
    def plank(x, y, z):
        if (y + z) % 5 == 0: return WAGON_D
        return lerp(WAGON, WAGON_L, 0.6 * M.noise(x, y, z, 8.0)) if M.noise(x, y, z, 3.0) < 0.82 else (0.30, 0.24, 0.18)
    for x in range(-L, L):
        for y in range(0, H):
            for z in range(-W, W):
                edge = min(x + L, L - 1 - x, y, H - 1 - y, z + W, W - 1 - z)
                if edge > 1: continue
                if y == H - 1 or y == H - 2:                       # el techo (ahora un lado) con una tabla rota
                    if -10 < x < 6 and -8 < z < 14: continue
                c = plank(x, y, z)
                if abs(x) in (L - 1, L - 2) or x in (-L // 3, L // 3): c = WAGON_D   # montantes
                M.put(x, y, z, P, c)
    for x in range(-L + 4, L - 4):                                 # bastidor de hierro hacia +z
        for y in (8, 9, H - 10, H - 9):
            M.put(x, y, W, P, IRON); M.put(x, y, W + 1, P, IRON)
    for cx in (-L + 12, -L + 26, L - 26, L - 12):                  # ruedas al aire
        for a in range(-9, 10):
            for b in range(-9, 10):
                r = math.hypot(a, b)
                if r > 9: continue
                c = IRON_L if r > 7.5 else (RAIL if r > 2 else IRON)
                for dz in range(W + 2, W + 5):
                    for yy in (12, H - 12): M.put(cx + a, yy + b, dz, P, c)
    for x in range(-14, 14):                                       # puerta corredera caída
        for z in range(-W - 22, -W - 2):
            M.put(x + int(0.2 * (z + W)), 0, z, P, plank(x, 0, z))
            if (x + 14) % 9 == 0: M.put(x + int(0.2 * (z + W)), 1, z, P, WAGON_D)
    return M, {P: [0, 0, 0]}


# ---------------- señal ----------------

def senal():
    """Semáforo ferroviario: poste de celosía de hierro, escalerilla, brazo rojo con franja
    blanca caído a 45° y el farol de aceite que aún arde en rojo (pivote "light")."""
    M = Model(S=3, seed=83)
    H = 190                                                        # 4 m
    box(M, -8, 8, 0, 8, -8, 8, (0.40, 0.39, 0.37))                 # zapata de hormigón
    for y in range(8, H):
        for x in (-3, 2):
            for z in (-3, 2): M.put(x, y, z, P, IRON)
        if y % 12 < 2:
            for k in range(-3, 3): M.put(k, y, -3, P, IRON_L); M.put(k, y, 2, P, IRON_L)
    for y in range(20, H - 20, 6):                                 # escalerilla
        for z in (-6, -5): M.put(-4, y, z, P, RUST if False else IRON_L)
    for k in range(0, 46):                                         # brazo caído
        x = 4 + k
        y = H - 16 - int(k * 0.9)
        for t in range(-3, 4):
            c = WHITE if 30 < k < 36 else RED
            M.put(x, y + t, -1, P, c); M.put(x, y + t, 0, P, c)
    LY = H - 26
    box(M, -10, -3, LY - 6, LY + 6, -4, 3, IRON)                   # farol
    for y in range(LY - 3, LY + 3):
        for z in range(-2, 1): M.put(-11, y, z, P, LAMP, glow=1)
    box(M, -11, -2, LY + 6, LY + 8, -5, 4, IRON)
    box(M, -4, 4, H, H + 4, -4, 4, IRON)
    return M, {P: [0, 0, 0], 'light': [-13, LY, -1]}


RUST = (0.42, 0.24, 0.13)


# ---------------- apeadero ----------------

def apeadero():
    """Apeadero de Rowley: andén de tablas de 9 x 3 m, caseta de 4 x 2,5 m de tablas
    verticales con puerta y ventana tapiada, tejadillo a un agua que vuela sobre el andén con
    dos pies derechos, letrero blanco en el alero y un banco. Hueco, 16/m."""
    M = Model(S=1, seed=84)
    for x in range(-72, 72):                                       # andén
        for z in range(-24, 24):
            for y in range(0, 6):
                if y < 5 and min(x + 72, 71 - x, z + 24, 23 - z) > 0 and y > 0: continue
                c = BOARD_D if x % 6 == 0 else lerp(BOARD, BOARD_G, M.noise(x, y, z, 6.0))
                if y == 5 and M.hsh(x // 6, 0, z) < 0.04: continue  # tabla que falta
                M.put(x, y, z, P, c)
    WX, WZ, WH = 32, 20, 46
    for y in range(6, WH):                                         # caseta
        for x in range(-WX, WX):
            for z in range(-24, -24 + 2 * WZ):
                if min(x + WX, WX - 1 - x, z + 24, 2 * WZ - 25 - z) > 0: continue
                c = BOARD_D if x % 4 == 0 or z % 4 == 0 else lerp(BOARD, BOARD_G, M.noise(x, y, z, 9.0) + 0.3 * (y < 14))
                if z == 15 and -8 < x < 4 and y < 38: c = DARK         # puerta abierta
                if z == 15 and 12 < x < 24 and 20 < y < 34: c = (0.36, 0.28, 0.20) if (x + y) % 5 else DARK   # ventana tapiada
                M.put(x, y, z, P, c)
    for x in range(-WX - 4, WX + 4):                               # tejadillo a un agua hacia el andén
        for z in range(-28, 26):
            y = WH + 8 - (z + 28) // 4
            M.put(x, y, z, P, ROOF_D if x % 5 == 0 else ROOF)
    for x in (-WX - 2, WX + 1):                                    # pies derechos
        for y in range(6, WH - 4): M.put(x, y, 23, P, BOARD_D)
    for x in range(-16, 16):                                       # letrero ROWLEY (sin texto legible: franjas)
        for y in range(WH - 2, WH + 4):
            c = SIGN
            if y in (WH, WH + 1) and x % 4 in (1, 2) and -12 < x < 12: c = DARK
            M.put(x, y, 24, P, c)
    for x in range(-60, -44):                                      # banco
        for z in (10, 11, 12): M.put(x, 12, z, P, BOARD_D)
        if x in (-59, -46):
            for y in range(6, 12): M.put(x, y, 11, P, IRON)
    return M, {P: [0, 0, 0]}


# ---------------- árboles ----------------

def arbol(seed, H):
    """Árbol muerto del pantano: tronco retorcido que se estrecha, raíces que salen del agua,
    ramas desnudas que suben y se doblan, y barbas de musgo colgando."""
    M = Model(S=2, seed=seed)
    rng = M.rng
    def bark(x, y, z):
        if M.noise(x, y, z, 3.0) > 0.7: return BARK_L
        return lerp(BARK, BARK_D, M.noise(x, y, z, 7.0))
    for k in range(6):                                             # raíces
        a = k / 6 * math.tau + rng.uniform(-0.3, 0.3)
        line(M, (0, 10, 0), (math.cos(a) * 20, 0, math.sin(a) * 20), 2.2, bark)
    pts = [(0, 0, 0)]
    x = z = 0.0
    for y in range(0, H, 10):                                      # tronco retorcido
        x += rng.uniform(-2.5, 2.5); z += rng.uniform(-2.5, 2.5)
        pts.append((x, y, z))
    for i in range(1, len(pts)):
        r = 6.0 * (1 - i / len(pts)) + 1.5
        line(M, pts[i - 1], pts[i], r, bark)
    tips = []
    def branch(p, ang, up, length, r, depth):
        dx, dz = math.cos(ang), math.sin(ang)
        q = (p[0] + dx * length, p[1] + up * length, p[2] + dz * length)
        line(M, p, q, r, bark)
        if depth == 0 or r < 1.1:
            tips.append(q); return
        for _ in range(2):
            branch(q, ang + rng.uniform(-0.9, 0.9), max(up + rng.uniform(-0.3, 0.2), 0.1), length * 0.7, r * 0.6, depth - 1)
    for i in range(4):
        base = pts[int(len(pts) * rng.uniform(0.45, 0.85))]
        branch(base, rng.uniform(0, math.tau), rng.uniform(0.4, 0.9), rng.uniform(22, 34), 2.6, 2)
    branch(pts[-1], rng.uniform(0, math.tau), 0.8, 18, 2.0, 2)
    for t in tips + [p for p in tips[::2]]:                        # musgo colgando de las ramas
        n = rng.randint(10, 26)
        for k in range(n):
            for j in range(rng.randint(0, 2)):
                M.put(int(t[0]) + j, int(t[1]) - k, int(t[2]), P, MOSS if k % 3 else MOSS_D, over=False)
    return M, {P: [0, 0, 0]}


def arbol_1(): return arbol(85, 150)
def arbol_2(): return arbol(86, 110)


def tocon():
    M = Model(S=2, seed=87)
    def bark(x, y, z): return lerp(BARK, BARK_D, M.noise(x, y, z, 5.0))
    for k in range(5):
        a = k / 5 * math.tau + 0.4
        line(M, (0, 8, 0), (math.cos(a) * 14, 0, math.sin(a) * 14), 2.0, bark)
    for y in range(0, 22):
        r = 7 - y * 0.08
        for x in range(-8, 9):
            for z in range(-8, 9):
                d = math.hypot(x, z)
                if d > r: continue
                top = y == 21 - int(M.hsh(x // 2, 0, z // 2) * 5)
                if y > 21 - M.hsh(x // 2, 0, z // 2) * 5: continue      # corte astillado
                M.put(x, y, z, P, (0.40, 0.33, 0.24) if top and d < r - 1.5 else bark(x, y, z))
    return M, {P: [0, 0, 0]}


# ---------------- caballete ----------------

def caballete():
    """Tramo de puente de caballetes: tres pórticos de pies inclinados con riostras en aspa
    (a lo largo de z), la viga de arriba partida y dos traviesas caídas al agua."""
    M = Model(S=2, seed=88)
    def wood(x, y, z): return lerp(SLEEPER, SLEEPER_D, M.noise(x, y, z, 6.0)) if M.noise(x, y, z, 3.0) < 0.78 else ROT
    TOP = 70
    for i, x in enumerate((-40, 0, 40)):
        lean = 0 if i < 2 else 8                                    # el último pórtico se vence
        for z in (-26, -10, 9, 25):
            sx = 1 if z > 0 else -1
            line(M, (x, 0, z + sx * 6), (x + lean, TOP, z), 1.6, wood)
        line(M, (x, 12, -30), (x + lean, TOP - 10, 28), 1.0, wood)  # riostras en aspa
        line(M, (x, 12, 28), (x + lean, TOP - 10, -30), 1.0, wood)
        line(M, (x + lean, TOP, -32), (x + lean, TOP, 32), 1.8, wood)
    line(M, (-44, TOP + 3, -12), (10, TOP + 3, -12), 2.2, wood)      # vigas: una entera, otra partida
    line(M, (-44, TOP + 3, 12), (6, TOP + 3, 12), 2.2, wood)
    line(M, (8, TOP + 3, 12), (40, 6, 18), 2.2, wood)                # el trozo caído
    for x0, z0, a in ((22, -36, 0.3), (-20, 36, -0.5)):              # traviesas caídas
        for k in range(-20, 20):
            for w in range(-3, 4):
                M.put(int(x0 + k * math.cos(a) - w * math.sin(a)), 0, int(z0 + k * math.sin(a) + w * math.cos(a)), P, wood(k, 0, w))
    return M, {P: [0, 0, 0]}


PIECES = {'via': via, 'vagoneta': vagoneta, 'senal': senal, 'apeadero': apeadero,
          'arbol_1': arbol_1, 'arbol_2': arbol_2, 'tocon': tocon, 'caballete': caballete}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/pan_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('pan_%s: %d voxels' % (name, n))
