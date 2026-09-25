"""Atrezo del campamento base (parte 1, nivel 1): tienda, caja, bidón, farol, roca y hielo.

Cada pieza sale en su propio models/atrezo_<pieza>.json con una sola parte, "body".
El farol incluye además el pivote "light", donde la partida coloca su luz.
Uso: python tools/gen_atrezo_campamento.py [S]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale

S = int(sys.argv[1]) if len(sys.argv) > 1 else 2
SNOW = (0.80, 0.84, 0.88); SNOW_D = (0.62, 0.68, 0.74)
WOOD = (0.46, 0.33, 0.19); WOOD_D = (0.30, 0.21, 0.12); WOOD_L = (0.56, 0.42, 0.26)
CANVAS = (0.62, 0.57, 0.45); CANVAS_D = (0.44, 0.40, 0.31); DOOR = (0.12, 0.10, 0.08)
ROPE = (0.55, 0.50, 0.38); IRON = (0.20, 0.20, 0.21); IRON_L = (0.38, 0.38, 0.40)
RUST = (0.46, 0.18, 0.10); RUST_D = (0.30, 0.12, 0.07); PAINT = (0.62, 0.20, 0.12)
FLAME = (1.0, 0.80, 0.42); ROCK = (0.26, 0.25, 0.24); ROCK_D = (0.16, 0.15, 0.15); ROCK_L = (0.36, 0.34, 0.32)
ICE = (0.62, 0.78, 0.84); ICE_L = (0.82, 0.92, 0.95); ICE_D = (0.40, 0.56, 0.64)
STENCIL = (0.12, 0.10, 0.08)

def snow_cap(M, thresh=0.0, depth=2):
    """Nieve en lo alto de cada columna, por encima de una altura (ub)."""
    cols = {}
    for (x, y, z) in M.V:
        if y > cols.get((x, z), -1): cols[(x, z)] = y
    for (x, z), top in cols.items():
        if top <= thresh * S: continue
        for d in range(depth):
            v = M.V.get((x, top - d, z))
            if v is not None and M.rng.random() < 0.92:
                v[1] = SNOW if M.rng.random() < 0.8 else SNOW_D

def tienda():
    M = Model(S=S, seed=11)
    H, B = 34.0, 17.0                   # 2,1 m de alto, base de 2,1 m
    for y in range(0, int(H * S)):
        h = B * (1 - y / (H * S)) + 0.6
        for x in range(int(-h * S), int(h * S) + 1):
            for z in range(int(-h * S), int(h * S) + 1):
                edge = max(abs(x), abs(z)) >= h * S - 2
                if edge: M.put(x, y, z, 'body', 'canvas')
    # faldón de nieve alrededor de la base
    for x in range(int(-(B + 2.5) * S), int((B + 2.5) * S) + 1):
        for z in range(int(-(B + 2.5) * S), int((B + 2.5) * S) + 1):
            d = max(abs(x), abs(z)) / S
            if B + 0.3 < d < B + 2.5:
                for y in range(0, max(1, int((B + 2.5 - d) * 0.8))):
                    M.put(x, y, z, 'body', SNOW if M.rng.random() < 0.85 else SNOW_D)
    # mástil
    M.box(-0.5, H - 0.5, -0.5, 0.5, H + 3.0, 0.5, 'body', WOOD_D)
    # puerta triangular en la cara delantera
    for y in range(0, int(15 * S)):
        w = (15 * S - y) * 0.45
        for x in range(int(-w), int(w) + 1):
            z = M.front(x, y, zmax=int((B + 1) * S))
            if z is not None and M.V[(x, y, z)][1] == 'canvas': M.V[(x, y, z)][1] = DOOR
    # vientos: cuerdas desde media altura hasta estacas
    for sx, sz in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        a = (sx * B * 0.55, H * 0.45, sz * B * 0.55); b = (sx * (B + 7), 0.5, sz * (B + 7))
        M.line(a, b, 'body', ROPE)
        M.box(b[0] - 0.5, 0, b[2] - 0.5, b[0] + 0.5, 1.5, b[2] + 0.5, 'body', WOOD_D)
    def paint(k, part, c):
        if c != 'canvas': return None
        x, y, z = k
        n = M.noise(x, y, z, 7.0)
        base = lerp(CANVAS_D, CANVAS, 0.4 + n * 0.6)
        if abs(abs(x) - abs(z)) <= 1: base = CANVAS_D                   # costuras de las aristas
        if y % 12 == 0: base = scale(base, 0.9)                         # paños
        if y < 3 * S: base = lerp(base, SNOW_D, 0.5)                    # bajo salpicado de nieve
        return base
    M.paint(paint)
    for k, v in M.V.items():                                            # escarcha en lo alto
        if k[1] > H * S * 0.55 and (k[0], k[1] + 1, k[2]) not in M.V and M.rng.random() < 0.35: v[1] = SNOW_D
    return M, {'body': [0, 0, 0]}

LETTERS = {'M': ["1...1", "11.11", "1.1.1", "1...1", "1...1"], 'U': ["1...1", "1...1", "1...1", "1...1", ".111."]}

def caja():
    M = Model(S=S, seed=12)
    W, Hh, D = 6.5, 8.5, 6.5
    M.box(-W, 0, -D, W, Hh, D, 'body', 'wood')
    def paint(k, part, c):
        x, y, z = k
        plank = y // 4
        base = lerp(WOOD_D, WOOD_L, M.hsh(plank, 0, 0) * 0.7 + 0.15)
        if y % 4 == 0: base = WOOD_D                                    # juntas entre tablas
        edge = (abs(x + .5) > (W - 1) * S) + (abs(z + .5) > (D - 1) * S) + (y >= (Hh - 1) * S or y < S)
        if edge >= 2: base = WOOD_D                                     # listones de las esquinas
        return lerp(base, WOOD_D, M.noise(x, y, z, 3) * 0.3)
    M.paint(paint)
    # estarcido "MU" (Miskatonic University) en la cara delantera
    zf = int(D * S) - 1
    for li, ch in enumerate("MU"):
        for row, line in enumerate(LETTERS[ch]):
            for col, px in enumerate(line):
                if px == '1':
                    x = -7 + li * 7 + col; y = int(Hh * S * 0.62) - row
                    if (x, y, zf) in M.V: M.V[(x, y, zf)][1] = STENCIL
    snow_cap(M, thresh=Hh - 0.6)
    return M, {'body': [0, 0, 0]}

def bidon():
    M = Model(S=S, seed=13)
    R, Hh = 4.6, 14.0
    for y in range(0, int(Hh * S)):
        for x in range(int(-R * S) - 1, int(R * S) + 2):
            for z in range(int(-R * S) - 1, int(R * S) + 2):
                r = math.hypot(x + .5, z + .5) / S
                hoop = y in (int(Hh * S * 0.3), int(Hh * S * 0.3) + 1, int(Hh * S * 0.7), int(Hh * S * 0.7) + 1)
                if r <= R + (0.5 if hoop else 0): M.put(x, y, z, 'body', 'hoop' if hoop else 'drum')
    M.box(1.5, Hh, 1.5, 2.5, Hh + 0.6, 2.5, 'body', IRON)               # tapón
    def paint(k, part, c):
        if not isinstance(c, str): return None
        x, y, z = k
        n = M.noise(x, y, z, 3.5)
        if c == 'hoop': return RUST_D
        base = lerp(PAINT, RUST, n * 1.3 if n < 0.75 else 1.0)          # pintura roja comida por el óxido
        if y >= Hh * S - 1: base = lerp(RUST_D, RUST, n)
        return base
    M.paint(paint)
    return M, {'body': [0, 0, 0]}

def farol():
    M = Model(S=S, seed=14)
    M.box(-0.75, 0, -0.75, 0.75, 34, 0.75, 'body', 'pole')              # poste de 2,1 m
    M.box(-0.5, 32.5, -0.5, 6.0, 33.5, 0.5, 'body', WOOD_D)             # brazo
    M.line((0.6, 28.0, 0), (5.0, 32.6, 0), 'body', WOOD_D)              # tornapunta
    M.line((5.5, 32.5, 0), (5.5, 30.0, 0), 'body', IRON)                # gancho
    LX, LY = 5.5, 27.0                                                  # farol colgado
    M.box(LX - 1.6, LY - 2.6, -1.6, LX + 1.6, LY - 2.0, 1.6, 'body', IRON)
    M.box(LX - 1.2, LY + 2.0, -1.2, LX + 1.2, LY + 2.6, 1.2, 'body', IRON)
    M.box(LX - 0.6, LY + 2.6, -0.6, LX + 0.6, LY + 3.2, 0.6, 'body', IRON_L)
    M.box(LX - 1.2, LY - 2.0, -1.2, LX + 1.2, LY + 2.0, 1.2, 'body', FLAME, glow=1)
    for sx in (-1, 1):
        for sz in (-1, 1):
            M.box(LX + sx * 1.2 - 0.5, LY - 2.0, sz * 1.2 - 0.5, LX + sx * 1.2 + 0.5, LY + 2.0, sz * 1.2 + 0.5, 'body', IRON)
    # montón de nieve al pie
    M.ell(0, 0, 0, 3.5, 1.6, 3.5, 'body', SNOW, over=False)
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    def paint(k, part, c):
        if c != 'pole': return None
        x, y, z = k
        return lerp(WOOD_D, WOOD, M.noise(x, y, z, 4) * 0.8 + (0.2 if (y // 5) % 2 else 0))
    M.paint(paint)
    return M, {'body': [0, 0, 0], 'light': [LX, LY, 0]}

def roca():
    M = Model(S=S, seed=15)
    for (x, y, z, rx, ry, rz) in ((0, 4.5, 0, 8.5, 5.5, 7.0), (4.0, 3.0, 2.0, 5.5, 4.0, 5.0),
                                  (-4.5, 2.5, -1.5, 5.0, 3.5, 5.5), (1.0, 8.0, -1.0, 4.5, 3.5, 4.0)):
        M.sell(x, y, z, rx, ry, rz, 'body', 'rock', p=2.3)
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    def paint(k, part, c):
        x, y, z = k
        n = M.noise(x, y, z, 5); m = M.noise(x + 17, y, z, 2)
        base = lerp(ROCK_D, ROCK_L, n)
        if m > 0.75: base = ROCK_D                                      # grietas
        return base
    M.paint(paint)
    snow_cap(M, thresh=6.5)
    return M, {'body': [0, 0, 0]}

def hielo():
    M = Model(S=S, seed=16)
    # bloque facetado: intersección de semiespacios con normales aleatorias
    planes = []
    for i in range(14):
        a = M.rng.uniform(0, math.tau); e = M.rng.uniform(-0.4, 1.0)
        n = (math.cos(a) * math.cos(e), math.sin(e), math.sin(a) * math.cos(e))
        planes.append((n, M.rng.uniform(5.0, 7.5)))
    for x in range(-9 * S, 9 * S):
        for y in range(0, 16 * S):
            for z in range(-9 * S, 9 * S):
                p = ((x + .5) / S, (y + .5) / S - 5.5, (z + .5) / S)
                if all(p[0] * n[0] + p[1] * n[1] + p[2] * n[2] <= d for n, d in planes):
                    M.put(x, y, z, 'body', 'ice')
    def paint(k, part, c):
        x, y, z = k
        n = M.noise(x, y, z, 4)
        base = lerp(ICE_D, ICE, n)
        if (x + y + z) % 9 == 0: base = ICE_L                           # vetas brillantes
        if not M.exposed(k): return base
        return lerp(base, ICE_L, 0.25)
    M.paint(paint)
    return M, {'body': [0, 0, 0]}

if __name__ == '__main__':
    for name, fn in (('tienda', tienda), ('caja', caja), ('bidon', bidon), ('farol', farol), ('roca', roca), ('hielo', hielo)):
        M, pv = fn()
        mat = (0.45, 0.6) if name == 'hielo' else (0.9, 0.25)          # hielo brillante, lo demás mate
        n = M.export('models/atrezo_%s.json' % name, pv, jitter=0.012, roughness=mat[0], specular=mat[1])
        print('atrezo_%s: %d voxels' % (name, n))
