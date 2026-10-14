"""Atrezo del campamento base (parte 1, nivel 1): tienda, caja, bidón, farol, roca, hielo,
iglú, cabaña de troncos y bloques de hielo cortados.

Cada pieza sale en su propio models/atrezo_<pieza>.json con una sola parte, "body".
El farol incluye además el pivote "light", donde la partida coloca su luz.
Uso: python tools/gen_atrezo_campamento.py [S] [piezas...]
     python tools/gen_atrezo_campamento.py 2 iglu cabana      # solo esas piezas
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale

S = int(sys.argv[1]) if len(sys.argv) > 1 else 2
SNOW = (0.80, 0.84, 0.88); SNOW_D = (0.62, 0.68, 0.74)
WOOD = (0.46, 0.33, 0.19); WOOD_D = (0.30, 0.21, 0.12); WOOD_L = (0.56, 0.42, 0.26)
CANVAS = (0.47, 0.51, 0.42); CANVAS_D = (0.35, 0.39, 0.32)            # lona verde grisácea
DOOR = (0.12, 0.10, 0.08)
ROPE = (0.55, 0.50, 0.38); IRON = (0.20, 0.20, 0.21); IRON_L = (0.38, 0.38, 0.40)
RUST = (0.46, 0.18, 0.10); RUST_D = (0.30, 0.12, 0.07); PAINT = (0.62, 0.20, 0.12)
FLAME = (1.0, 0.80, 0.42); ROCK = (0.26, 0.25, 0.24); ROCK_D = (0.16, 0.15, 0.15); ROCK_L = (0.36, 0.34, 0.32)
ICE = (0.62, 0.78, 0.84); ICE_L = (0.82, 0.92, 0.95); ICE_D = (0.40, 0.56, 0.64)
STENCIL = (0.12, 0.10, 0.08)

def tag(c):
    """Etiqueta de pintura: tupla que empieza por un texto, p. ej. ('log', hilera, fila)."""
    return isinstance(c, tuple) and len(c) > 0 and isinstance(c[0], str)

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

def snow_drift(M, hx, hz, reach, height, keep_clear=None):
    """Nieve amontonada contra la base de un rectángulo de medio lado (hx, hz), en voxels."""
    for x in range(-hx - reach, hx + reach):
        for z in range(-hz - reach, hz + reach):
            d = max(max(0, abs(x + 0.5) - hx), max(0, abs(z + 0.5) - hz))
            if d <= 0 or d >= reach: continue
            if keep_clear and keep_clear(x, z): continue
            for y in range(0, max(1, int(height * (1 - d / reach)))):
                M.put(x, y, z, 'body', SNOW if M.rng.random() < 0.85 else SNOW_D, over=False)

def tienda():
    """Tienda canadiense de expedición: cumbrera a lo largo de X, faldones de lona verde
    grisácea, extremos triangulares, puerta en el faldón delantero (+Z), vientos con
    estacas y nieve acumulada al pie. Coordenadas en voxels (1,9 x 2,3 x 1,6 m)."""
    M = Model(S=S, seed=11)
    HX, HZ, H = 36, 30, 52
    for y in range(0, H):
        w = HZ * (1 - y / H)                                    # medio ancho a esta altura
        for z in range(-int(w) - 1, int(w) + 1):
            if abs(z + 0.5) > w: continue
            slope = abs(z + 0.5) > w - 2.5
            for x in range(-HX, HX):
                end_wall = x in (-HX, -HX + 1, HX - 2, HX - 1)
                if slope: M.put(x, y, z, 'body', ('canvas',))
                elif end_wall: M.put(x, y, z, 'body', ('canvas_end',))
    M.vbox(-HX - 3, H - 1, -1, HX + 3, H + 1, 1, 'body', WOOD_D)              # cumbrera
    # puerta en el faldón delantero: vano oscuro con los bordes de la lona recogidos
    for y in range(0, 32):
        half = int((32 - y) * 0.4) + 3
        for x in range(-half, half):
            z = M.front(x, y, zmax=HZ + 2)
            if z is not None and M.V[(x, y, z)][1] == ('canvas',):
                M.V[(x, y, z)][1] = ('flap',) if abs(x + 0.5) > half - 2 else DOOR
    # vientos
    for sx in (-1, 1):
        for sz in (-1, 1):
            a = (sx * (HX - 6) / S, 24 / S, sz * 14 / S)
            b = (sx * (HX + 14) / S, 0.5, sz * (HZ + 22) / S)
            M.line(a, b, 'body', ROPE)
            M.box(b[0] - 0.5, 0, b[2] - 0.5, b[0] + 0.5, 1.5, b[2] + 0.5, 'body', WOOD_D)
    snow_drift(M, HX, HZ, 7, 4)
    def paint(k, part, c):
        if not tag(c): return None
        x, y, z = k
        n = M.hsh(x // 8, y // 8, z // 8)
        if c[0] == 'canvas':
            base = lerp(CANVAS_D, CANVAS, 0.55 + n * 0.35)
            if (x + HX) % 24 == 0: base = scale(CANVAS_D, 0.92)            # costuras entre paños
            if y < 4: base = lerp(base, SNOW_D, 0.4)                         # bajo manchado de nieve
            if y > H - 5: base = lerp(base, SNOW, 0.45)                      # escarcha en la cumbrera
            return base
        if c[0] == 'canvas_end': return lerp(CANVAS_D, CANVAS, 0.3 + n * 0.3)
        if c[0] == 'flap': return scale(CANVAS_D, 0.85)
        return None
    M.paint(paint)
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
    """Bloque de hielo de presión (revisión de arte del 14-10-2026; la versión de antes queda en
    models/atrezo_hielo_v1.json): tres esquirlas facetadas soldadas, a 64 voxels/m, con el
    hielo azul profundo abajo y pálido arriba, vetas verticales, burbujas, aristas escarchadas,
    nieve en las caras de arriba y un ventisquero al pie."""
    V = 4                                                    # voxels por ub (64/m)
    M = Model(S=V, seed=16)
    rng = M.rng
    shards = [((0, 0), 18.0, 7.0, 0.12), ((7.0, 3.5), 12.0, 5.0, -0.3), ((-6.5, 3.0), 8.0, 4.2, 0.45)]
    owner = {}
    for i, ((sx, sz), hgt, rad, lean) in enumerate(shards):
        planes = []
        for j in range(11):
            a = rng.uniform(0, math.tau); e = rng.uniform(-0.25, 0.55)
            planes.append(((math.cos(a) * math.cos(e), math.sin(e), math.sin(a) * math.cos(e)), rad * rng.uniform(0.8, 1.1)))
        for j in range(2):                                   # punta inclinada
            a = rng.uniform(0, math.tau)
            planes.append(((math.cos(a) * 0.6, 0.8, math.sin(a) * 0.6), hgt * 0.62))
        R = int((rad * 1.3 + 2) * V)
        for x in range(int((sx - rad * 1.3) * V), int((sx + rad * 1.3) * V)):
            for y in range(0, int(hgt * V)):
                for z in range(int((sz - rad * 1.3) * V), int((sz + rad * 1.3) * V)):
                    px = (x + .5) / V - sx - lean * (y / V); py = (y + .5) / V - hgt * 0.35; pz = (z + .5) / V - sz
                    if all(px * n[0] + py * n[1] + pz * n[2] <= d for n, d in planes):
                        if (x, y, z) not in owner:
                            owner[(x, y, z)] = i
                            M.put(x, y, z, 'body', ICE)
    top = max(y for (_, y, _) in M.V)
    def paint(k, part, c):
        x, y, z = k
        f = y / top
        base = lerp(ICE_DEEP, ICE_PALE, min(1.0, f * 1.05))
        base = lerp(base, ICE_MID, 0.35 * M.noise(x, y * 0.3, z, 6))
        if M.hsh(x // 3, 1, z // 3) < 0.09: base = lerp(base, ICE_DEEP, 0.5)          # vetas verticales
        if M.hsh(x, y, z) < 0.012: base = ICE_BUBBLE                                    # burbujas
        nb = [(x + 1, y, z), (x - 1, y, z), (x, y + 1, z), (x, y - 1, z), (x, y, z + 1), (x, y, z - 1)]
        if any(owner.get(q, owner[k]) != owner[k] for q in nb): return lerp(base, ICE_DEEP, 0.55)   # junta
        exp = sum(q not in M.V for q in nb)
        if exp >= 2: base = lerp(base, ICE_EDGE, 0.6)                                   # arista escarchada
        if y < 6: base = lerp(base, ICE_DIRT, 0.25)
        return base
    M.paint(paint)
    hollow = [k for k in M.V if all(q in M.V for q in ((k[0] + 1, k[1], k[2]), (k[0] - 1, k[1], k[2]), (k[0], k[1] + 1, k[2]),
                                                      (k[0], k[1] - 1, k[2]), (k[0], k[1], k[2] + 1), (k[0], k[1], k[2] - 1)))]
    for k in hollow: del M.V[k]
    # nieve en lo que mira arriba (columna cuyo tope tiene vecinos a menos de un voxel)
    tops = {}
    for (x, y, z) in M.V:
        if y > tops.get((x, z), -1): tops[(x, z)] = y
    for (x, z), h in tops.items():
        if h < 8: continue
        if all(abs(tops.get((x + dx, z + dz), -99) - h) <= 1 for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1))) and M.noise(x, 0, z, 5) > 0.5:
            for y in range(h + 1, h + 2 + int(M.noise(x, 1, z, 3) * 2.5)):
                M.put(x, y, z, 'body', SNOW if M.hsh(x, y, z) < 0.85 else SNOW_D)
    # ventisquero al pie
    occ = set(tops)
    for x in range(min(k[0] for k in occ) - 14, max(k[0] for k in occ) + 15):
        for z in range(min(k[1] for k in occ) - 14, max(k[1] for k in occ) + 15):
            if (x, z) in occ: continue
            d = next((r for r in range(2, 9, 2) if any((x + dx * r, z + dz * r) in occ for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))), None)
            if d is None: continue
            h = int((9 - d) * 0.6 * M.noise(x, 2, z, 7) + 0.5)
            for y in range(0, h): M.put(x, y, z, 'body', SNOW if M.hsh(x, y, z) < 0.85 else SNOW_D)
    return M, {'body': [0, 0, 0]}

def roca_nevada():
    """Peña de basalto medio enterrada en la nieve (revisión de arte del 14-10-2026, referencia
    tools/local/ref_roca_nevada_1000.png). DESCARTADA: la de Replicate (models/atrezo_roca_nevada.json)
    se lee mejor con la luz de los niveles 2 y 3; esta queda fuera de PIECES. A 48 voxels/m, 1,2 x 0,9 m: caras planas de fractura,
    diaclasas oscuras, una veta de cuarzo, líquenes, escarcha en las grietas, una capa gruesa
    de nieve en lo alto que cae por los lados y un ventisquero a barlovento."""
    V = 3
    M = Model(S=V, seed=71)
    rng = M.rng
    BAS = (0.44, 0.46, 0.52); BAS_L = (0.64, 0.66, 0.72); BAS_D = (0.26, 0.28, 0.33)
    LICHEN = ((0.62, 0.50, 0.18), (0.40, 0.46, 0.22)); QUARTZ = (0.80, 0.80, 0.76)
    planes = []
    for j in range(10):
        a = j * math.tau / 10 + rng.uniform(-0.3, 0.3); e = rng.uniform(-0.05, 0.5)
        planes.append(((math.cos(a) * math.cos(e), math.sin(e), math.sin(a) * math.cos(e)), rng.uniform(8.5, 10.5)))
    planes.append(((0.2, 1.0, -0.15), 9.0))
    planes.append(((-0.5, 1.0, 0.4), 9.5))
    for x in range(-14 * V, 14 * V):
        for y in range(0, 17 * V):
            for z in range(-14 * V, 14 * V):
                p = ((x + .5) / V, (y + .5) / V - 3.5, (z + .5) / V * 1.1)
                if all(p[0] * n[0] + p[1] * n[1] + p[2] * n[2] <= d for n, d in planes):
                    j = max(range(len(planes)), key=lambda j: p[0] * planes[j][0][0] + p[1] * planes[j][0][1] + p[2] * planes[j][0][2] - planes[j][1])
                    M.put(x, y, z, 'body', ('f', j))
    joints = [(rng.uniform(0, math.tau), rng.uniform(-12, 12)) for _ in range(3)]
    def paint(k, part, c):
        x, y, z = k
        tone = M.hsh(c[1], 7, 7) if isinstance(c, tuple) and c and c[0] == 'f' else 0.5
        base = lerp(BAS_D, BAS_L, 0.15 + 0.5 * tone + 0.3 * M.noise(x, y, z, 5))
        base = lerp(base, BAS, 0.3 * M.noise(x, y, z, 2))
        for a, o in joints:                                                  # diaclasas
            if abs(x * math.cos(a) + z * math.sin(a) - o * V) < 1.0: return lerp(BAS_D, (0.70, 0.78, 0.86), 0.25 if y > 20 else 0.0)
        if abs(y - 0.4 * x - 16) < 1.2 and M.noise(x, y, z, 3) > 0.35: return QUARTZ           # veta de cuarzo
        if M.noise(x, y, z, 2.5) > 0.74: return LICHEN[M.hsh(x // 3, y // 3, z // 3) > 0.5]    # líquenes
        nb = ((x + 1, y, z), (x - 1, y, z), (x, y + 1, z), (x, y - 1, z), (x, y, z + 1), (x, y, z - 1))
        if sum(q not in M.V for q in nb) >= 2: base = lerp(base, BAS_L, 0.4)                 # aristas
        return base
    M.paint(paint)
    for k in [k for k in M.V if all(q in M.V for q in ((k[0] + 1, k[1], k[2]), (k[0] - 1, k[1], k[2]), (k[0], k[1] + 1, k[2]),
                                                        (k[0], k[1] - 1, k[2]), (k[0], k[1], k[2] + 1), (k[0], k[1], k[2] - 1)))]:
        del M.V[k]
    tops = {}
    for (x, y, z) in M.V:
        if y > tops.get((x, z), -1): tops[(x, z)] = y
    for (x, z), h in tops.items():                                           # nieve en lo alto
        slope = max(abs(tops.get((x + dx, z + dz), h - 9) - h) for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if slope > 1 or M.noise(x, 0, z, 8) < 0.3: continue
        d = 1 + int(4 * (M.noise(x, 0, z, 8) - 0.42)) if h > 20 else int(2 * M.noise(x, 0, z, 6))
        for y in range(h + 1, h + 1 + d): M.put(x, y, z, 'body', SNOW if M.hsh(x, y, z) < 0.85 else SNOW_D)
    occ = set(tops)                                                          # ventisquero a barlovento (-X)
    for x in range(-16 * V, 16 * V):
        for z in range(-16 * V, 16 * V):
            if (x, z) in occ: continue
            dd = next((r for r in range(1, 16) if (x + r, z) in occ or (x + r // 2, z + r // 2) in occ), None)
            if dd is None:
                dd = next((r for r in range(1, 7) if any((x + a * r, z + b * r) in occ for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1)))), None)
                if dd is None: continue
                h = int((7 - dd) * 0.8 * M.noise(x, 2, z, 5))
            else:
                h = int((16 - dd) * 0.9 * (0.5 + 0.5 * M.noise(x, 2, z, 6)))
            for y in range(0, h): M.put(x, y, z, 'body', SNOW if M.hsh(x, y, z) < 0.85 else SNOW_D)
    return M, {'body': [0, 0, 0]}

def iglu():
    """Iglú de bloques de nieve (radio 1,7 m): cúpula hueca en hileras de 0,28 m con juntas
    verticales alternas, hundidas un voxel para que el despiece se lea; túnel de entrada
    hacia +Z con la boca oscura y un leve resplandor cálido al fondo."""
    M = Model(S=S, seed=21)
    R, SHELL, ROW = 54, 3, 9
    TR, T0, T1 = 19, R - 16, R + 14                 # túnel: radio, inicio y fin en Z
    for y in range(0, R):                    # cáscara esférica de grosor uniforme (también arriba)
        rr = math.sqrt(max(0.0, R * R - (y + 0.5) ** 2))
        for x in range(-int(rr) - 1, int(rr) + 1):
            for z in range(-int(rr) - 1, int(rr) + 1):
                d = math.sqrt((x + 0.5) ** 2 + (y + 0.5) ** 2 + (z + 0.5) ** 2)
                if R - SHELL <= d <= R: M.put(x, y, z, 'body', ('dome',))
    for z in range(T0, T1):
        for x in range(-TR, TR):
            for y in range(0, TR):
                d = math.hypot(x + 0.5, y + 0.5)
                if TR - SHELL <= d <= TR: M.put(x, y, z, 'body', ('tunnel',))
                elif d < TR - SHELL and (x, y, z) in M.V: del M.V[(x, y, z)]   # hueco del túnel
    for x in range(-TR + SHELL, TR - SHELL):                             # interior del túnel: oscuro
        for y in range(0, TR - SHELL):
            if math.hypot(x + 0.5, y + 0.5) < TR - SHELL:
                M.put(x, y, T0, 'body', (0.30, 0.17, 0.07) if y < 7 else (0.09, 0.08, 0.08))
        for z in range(T0, T1):                                           # suelo en sombra
            if abs(x + 0.5) < TR - SHELL:
                M.put(x, 0, z, 'body', lerp((0.10, 0.10, 0.12), (0.30, 0.34, 0.40), (z - T0) / (T1 - T0)))
    JOINT = (0.60, 0.68, 0.80)
    def block(x, y, z):
        """(hilera, índice del bloque en la hilera, posición dentro del bloque 0..1, largo en voxels)"""
        row = y // ROW
        rr = math.sqrt(max(1.0, R * R - (row * ROW + ROW / 2) ** 2))     # radio a media hilera
        per = max(4, int(round(2 * math.pi * rr / 17)))                   # bloques de ~0,5 m
        f = math.atan2(z + 0.5, x + 0.5) / (2 * math.pi) * per + (0.5 if row % 2 else 0.0)
        return row, int(math.floor(f)), f - math.floor(f), 2 * math.pi * rr / per
    def paint(k, part, c):
        if not tag(c): return None
        x, y, z = k
        if c[0] == 'tunnel':
            if y % ROW == 0 or (z - T0) % 14 == 0: return JOINT
            return lerp((0.84, 0.88, 0.94), (0.93, 0.96, 0.99), M.hsh(y // ROW, (z - T0) // 14, 1))
        row, idx, f, length = block(x, y, z)
        if y % ROW == 0 or f * length < 1.3: return JOINT
        return lerp((0.84, 0.88, 0.94), (0.93, 0.96, 0.99), M.hsh(row, idx, 0))
    M.paint(paint)
    for k in [k for k, v in M.V.items() if v[1] == JOINT and M.exposed(k) and k[1] > 1]:
        del M.V[k]                                                        # juntas hundidas
    return M, {'body': [0, 0, 0]}

def cabana():
    """Cabaña de troncos (3,1 x 2,4 m de planta): troncos horizontales con las cabezas
    cruzadas en las esquinas, tejado a dos aguas de tablas con un manto de nieve, puerta,
    ventana con luz cálida y chimenea de piedra. Frente en +Z. Coordenadas en voxels."""
    M = Model(S=S, seed=31)
    HX, HZ, WALL, LOG, TH = 50, 38, 58, 6, 2
    for y in range(0, WALL):
        course = y // LOG
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                if min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) < TH:
                    M.put(x, y, z, 'body', ('log', course, y % LOG))
        for sx in (-1, 1):                                                # cabezas cruzadas
            for sz in (-1, 1):
                if course % 2 == 0:
                    xs = range(HX, HX + 6) if sx > 0 else range(-HX - 6, -HX)
                    zs = range(HZ - TH, HZ) if sz > 0 else range(-HZ, -HZ + TH)
                else:
                    xs = range(HX - TH, HX) if sx > 0 else range(-HX, -HX + TH)
                    zs = range(HZ, HZ + 6) if sz > 0 else range(-HZ - 6, -HZ)
                for x in xs:
                    for z in zs:
                        M.put(x, y, z, 'body', ('logend', course, y % LOG))
    RISE, EAVE = 34, 12
    run = HZ + EAVE
    for i in range(0, run):
        yb = WALL + RISE - int(i * RISE / (HZ + 8))
        for z in (i, -i - 1):
            for x in range(-HX - 10, HX + 10):
                M.put(x, yb, z, 'body', ('plank',))
                M.put(x, yb + 1, z, 'body', ('roofsnow',)); M.put(x, yb + 2, z, 'body', ('roofsnow',))
    for x in list(range(-HX, -HX + TH)) + list(range(HX - TH, HX)):      # hastiales
        for y in range(WALL, WALL + RISE):
            w = (HZ + 8) * (1 - (y - WALL) / RISE) - 1
            for z in range(-int(w), int(w)):
                M.put(x, y, z, 'body', ('gable',), over=False)
    for x in range(-30, -12):                                             # puerta
        for y in range(0, 44):
            frame = x in (-30, -13) or y == 43
            for z in (HZ - 1, HZ):
                M.put(x, y, z, 'body', WOOD_D if frame else ('door', x))
    M.vbox(-17, 20, HZ + 1, -15, 23, HZ + 2, 'body', IRON)               # tirador
    for x in range(10, 32):                                               # ventana iluminada
        for y in range(22, 40):
            frame = x in (10, 31) or y in (22, 39) or x == 20 or y == 30
            for z in (HZ - 1, HZ):
                if frame: M.put(x, y, z, 'body', WOOD_D)
                else: M.put(x, y, z, 'body', (1.0, 0.74, 0.38), glow=1)
    M.vbox(8, 20, HZ, 34, 22, HZ + 3, 'body', ('roofsnow',))            # nieve en el alféizar
    for y in range(40, WALL + RISE + 12):                                 # chimenea
        for x in range(26, 38):
            for z in range(-22, -10):
                if min(x - 26, 37 - x, z + 22, -11 - z) < 3 or y > WALL + RISE + 9:
                    M.put(x, y, z, 'body', ('stone', x, y, z))
    M.vbox(25, WALL + RISE + 12, -23, 39, WALL + RISE + 14, -9, 'body', ('roofsnow',))
    snow_drift(M, HX, HZ, 8, 4, keep_clear=lambda x, z: z > 0 and -32 < x < -10)
    LOG_A = (0.42, 0.28, 0.16); LOG_B = (0.36, 0.24, 0.13); GROOVE = (0.20, 0.13, 0.08)
    def paint(k, part, c):
        if not tag(c): return None
        x, y, z = k
        kind = c[0]
        if kind in ('log', 'logend'):
            course, yy = c[1], c[2]
            if yy == 0: return GROOVE                                     # junta entre troncos
            if kind == 'logend':
                return (0.55, 0.40, 0.24) if (abs(x) + abs(z) + yy) % 3 else (0.45, 0.32, 0.19)
            base = LOG_A if course % 2 else LOG_B
            if yy == LOG - 1: base = scale(base, 1.15)                    # canto superior
            return lerp(base, scale(base, 0.86), M.hsh(x // 10, course, z // 10))
        if kind == 'plank': return (0.24, 0.17, 0.11) if (x // 5) % 2 else (0.28, 0.20, 0.13)
        if kind == 'roofsnow': return SNOW if M.hsh(x, y, z) > 0.12 else SNOW_D
        if kind == 'gable': return (0.38, 0.26, 0.15) if (y // 5) % 2 else (0.33, 0.22, 0.13)
        if kind == 'door': return (0.30, 0.20, 0.11) if (c[1] // 4) % 2 else (0.25, 0.16, 0.09)
        if kind == 'stone':
            return lerp((0.30, 0.30, 0.31), (0.46, 0.45, 0.44), M.hsh(c[1] // 4, c[2] // 3, c[3] // 4))
        return None
    M.paint(paint)
    return M, {'body': [0, 0, 0]}

ICE_DEEP = (0.30, 0.48, 0.62); ICE_MID = (0.50, 0.68, 0.80); ICE_PALE = (0.70, 0.84, 0.90)
ICE_EDGE = (0.86, 0.94, 0.98); ICE_BUBBLE = (0.92, 0.97, 1.0); ICE_CRACK = (0.94, 0.98, 1.0)
ICE_DIRT = (0.42, 0.46, 0.48); SAW = (0.60, 0.74, 0.84)

PILES = {
    # (x, y, z, ancho, alto, fondo, giro en voxels por lado) de cada bloque; y = 0 es el suelo
    'bloques_hielo': [(-23, 0, -2, 22, 16, 16), (0, 0, 1, 21, 15, 17), (23, 0, -1, 22, 17, 15),
                      (-11, 'top', 0, 21, 15, 16), (12, 'top', -1, 22, 16, 16), (0, 'top', 0, 19, 14, 15)],
    'bloques_hielo_2': [(-14, 0, -6, 24, 17, 18), (12, 0, -4, 20, 15, 16), (-2, 0, 14, 18, 14, 15),
                        (-6, 'top', -5, 22, 16, 17), (24, 0, 12, 14, 9, 12)],         # uno caído delante
    'bloques_hielo_3': [(-16, 0, 0, 21, 16, 16), (8, 0, -2, 22, 17, 17), (-5, 'top', -1, 22, 15, 16),
                        (22, 0, 14, 16, 11, 13), (-26, 0, 16, 12, 8, 11)],              # dos sueltos y uno roto
}


def bloques_hielo(name='bloques_hielo', seed=41):
    """Bloques de hielo cortados a sierra y apilados, cada uno distinto (revisión de arte del
    13-10-2026): tamaños y desplazamientos propios, aristas desconchadas y alguna esquina rota,
    marcas de sierra en las caras, capas del hielo, burbujas atrapadas, grietas blancas que
    cruzan el bloque, algo de tierra en la base, escarcha en las aristas y nieve amontonada
    encima y al pie de la pila."""
    M = Model(S=3, seed=seed)                                        # 48/m (revisión de arte del 14-10-2026; antes 32/m: *_v1)
    rng = M.rng
    hmap = {}                                                        # altura ocupada por columna
    blocks = []
    K = 1.5                                                          # PILES está medido a 32/m
    owner = {}
    for i, (bx, by, bz, W, H, D) in enumerate(PILES[name]):
        bx, bz, W, H, D = (int(round(v * K)) for v in (bx, bz, W, H, D))
        if by != 'top': by = int(round(by * K))
        jx, jz = rng.randint(-2, 2), rng.randint(-2, 2)
        x0, z0 = bx - W // 2 + jx, bz - D // 2 + jz
        x1, z1 = x0 + W, z0 + D
        if by == 'top':
            by = max(hmap.get((x, z), 0) for x in range(x0 + 3, x1 - 3) for z in range(z0 + 3, z1 - 3))
        tilt = rng.uniform(-0.12, 0.12) if i % 2 else 0.0           # alguno asentado algo torcido
        chip = rng.randint(0, 3)                                     # esquina rota
        for x in range(x0, x1):
            for z in range(z0, z1):
                dy = int(round(tilt * (x - (x0 + x1) / 2)))
                for y in range(by + max(0, dy), by + H + dy):
                    u, v, w = x - x0, y - by - dy, z - z0
                    # aristas desconchadas: muescas al azar en los cantos
                    edge = (u in (0, W - 1)) + (v in (0, H - 1)) + (w in (0, D - 1))
                    if edge >= 2 and M.hsh(x, y, z) < 0.22: continue
                    # esquina rota (arriba)
                    cu = u if chip in (0, 2) else W - 1 - u
                    cw = w if chip in (0, 1) else D - 1 - w
                    if cu + cw + (H - 1 - v) < 10: continue
                    M.put(x, y, z, 'body', ('ice', i, u, v, w, W, H, D))
                    owner[(x, y, z)] = i
                    hmap[(x, z)] = max(hmap.get((x, z), 0), y + 1)
        blocks.append((i, W, H, D))
    # grietas: planos inclinados por bloque
    cracks = {}
    for (i, W, H, D) in blocks:
        cracks[i] = [(rng.uniform(-1, 1), rng.uniform(-0.6, 0.6), rng.uniform(0.3, 0.7), rng.random() < 0.5) for _ in range(rng.randint(1, 2))]
    def paint(k, part, c):
        if not tag(c): return None
        x, y, z = k
        _, i, u, v, w, W, H, D = c
        f = v / max(1, H - 1)
        base = lerp(ICE_DEEP, ICE_MID, 0.35 + 0.65 * f)                # más profundo abajo
        layer = M.noise(0, v + i * 7, 0, 3.0)                           # capas del hielo
        base = lerp(base, ICE_PALE, 0.35 * layer)
        cloud = M.noise(x, y, z, 4.0)                                   # hielo lechoso a manchas
        if cloud > 0.62: base = lerp(base, ICE_PALE, (cloud - 0.62) * 1.6)
        if M.hsh(x * 3, y, z * 5) > 0.975: base = ICE_BUBBLE            # burbujas
        for (a, b, off, along_x) in cracks[i]:                         # grietas blancas
            p = (u / W if along_x else w / D)
            if abs(f - (off + a * (p - 0.5) + b * ((w / D if along_x else u / W) - 0.5))) < 0.045:
                base = ICE_CRACK
        if v < 2: base = lerp(base, ICE_DIRT, 0.45 if v == 0 else 0.2)  # tierra en la base
        if (u in (0, W - 1)) or (w in (0, D - 1)):                      # caras: marcas de sierra
            if v % 3 == 0 and M.hsh(u + w, v, i) > 0.4: base = lerp(base, SAW, 0.6)
        edges = (u in (0, W - 1)) + (v in (0, H - 1)) + (w in (0, D - 1))
        if edges >= 2: base = lerp(base, ICE_EDGE, 0.75)                # escarcha en las aristas
        if edges >= 1 and any(isinstance(owner.get(q), int) and owner[q] != i for q in ((x + 1, y, z), (x - 1, y, z), (x, y + 1, z), (x, y - 1, z), (x, y, z + 1), (x, y, z - 1))):
            base = SNOW if M.hsh(x, y, z) < 0.8 else SNOW_D             # nieve prensada en las juntas
        if v == H - 1: base = lerp(base, ICE_EDGE, 0.35)
        return base
    M.paint(paint)
    # nieve: encima de cada bloque, en montoncitos, y amontonada al pie del lado del viento
    cols = {}
    for (x, y, z) in M.V:
        if y > cols.get((x, z), -1): cols[(x, z)] = y
    for (x, z), top in cols.items():
        n = M.noise(x, 0, z, 5.0)
        if n > 0.45:
            for d in range(1 + int((n - 0.45) * 6)):
                M.put(x, top + 1 + d, z, 'body', SNOW if M.hsh(x, d, z) < 0.8 else SNOW_D)
    xs = [k[0] for k in M.V]; zs = [k[2] for k in M.V]
    for x in range(min(xs) - 6, max(xs) + 7):
        for z in range(min(zs) - 6, max(zs) + 7):
            if (x, 0, z) in M.V: continue
            d = min(abs(x - q[0]) + abs(z - q[2]) for q in [(x2, 0, z2) for (x2, z2) in cols if abs(x2 - x) < 7 and abs(z2 - z) < 7] or [(999, 0, 999)])
            if d >= 7 or z > max(zs) - 4: continue                       # el pie del lado norte y los lados
            h = int((7 - d) * 0.8 * M.noise(x, 3, z, 4.0) + 0.5)
            for y in range(0, h): M.put(x, y, z, 'body', SNOW if M.hsh(x, y, z) < 0.85 else SNOW_D, over=False)
    return M, {'body': [0, 0, 0]}

# tienda, caja, bidón, farol, iglú y cabaña: ahora en gen_atrezo_expedicion.py
PIECES = (('roca', roca), ('hielo', hielo),
          ('bloques_hielo', bloques_hielo),
          ('bloques_hielo_2', lambda: bloques_hielo('bloques_hielo_2', 42)),
          ('bloques_hielo_3', lambda: bloques_hielo('bloques_hielo_3', 43)))
VOXEL_PIVOTS = {'hielo', 'roca_nevada', 'tienda', 'iglu', 'cabana', 'bloques_hielo', 'bloques_hielo_2', 'bloques_hielo_3'}   # diseñadas en voxels, no en ub
SHINY = {'hielo', 'bloques_hielo', 'bloques_hielo_2', 'bloques_hielo_3'}                     # hielo brillante, lo demás mate

if __name__ == '__main__':
    only = set(sys.argv[2:])
    for name, fn in PIECES:
        if only and name not in only: continue
        M, pv = fn()
        mat = (0.45, 0.6) if name in SHINY else (0.9, 0.25)
        n = M.export('models/atrezo_%s.json' % name, pv, jitter=0.012, roughness=mat[0], specular=mat[1],
                     pivots_in_voxels=name in VOXEL_PIVOTS, no_bottom=True)
        print('atrezo_%s: %d voxels' % (name, n))
