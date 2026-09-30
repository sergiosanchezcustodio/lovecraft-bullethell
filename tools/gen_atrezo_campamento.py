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

def bloques_hielo():
    """Bloques de hielo cortados y apilados (tres abajo, dos encima y uno arriba), de
    0,7 x 0,5 x 0,5 m, con las aristas claras, cara superior más luminosa, alguna grieta
    interior y un poco de nieve encima."""
    M = Model(S=S, seed=41)
    W, D, H = 22, 16, 16
    placed = [(-23, 0, -2), (0, 0, 1), (23, 0, -1), (-11, H, 0), (12, H, -1), (0, 2 * H, 0)]
    for i, (bx, by, bz) in enumerate(placed):
        jx = M.rng.randint(-2, 2); jz = M.rng.randint(-2, 2)
        x0, x1 = bx - W // 2 + jx, bx + W // 2 + jx
        z0, z1 = bz - D // 2 + jz, bz + D // 2 + jz
        M.vbox(x0, by, z0, x1, by + H, z1, 'body', ('ice', i, x0, x1, by, z0, z1))
        M.bevel('body', x0, x1, z0, z1, by, by + H)
    ICE_A = (0.64, 0.80, 0.88); ICE_B = (0.52, 0.68, 0.80); EDGE = (0.86, 0.95, 0.99); CRACK = (0.40, 0.56, 0.70)
    def paint(k, part, c):
        if not tag(c): return None
        x, y, z = k
        _, i, x0, x1, y0, z0, z1 = c
        top = y == y0 + H - 1
        edges = (x in (x0, x0 + 1, x1 - 2, x1 - 1)) + (y in (y0, y0 + H - 1)) + (z in (z0, z0 + 1, z1 - 2, z1 - 1))
        base = lerp(ICE_B, ICE_A, (y - y0) / H)
        if top: base = lerp(ICE_A, EDGE, 0.45)
        if edges >= 2: base = EDGE
        elif (x - x0 + (y - y0) * 2 + i * 5) % 19 == 0 and not top: base = CRACK
        return base
    M.paint(paint)
    snow_cap(M, thresh=(2 * H + 8) / S, depth=2)
    return M, {'body': [0, 0, 0]}

# tienda, caja, bidón, farol, iglú y cabaña: ahora en gen_atrezo_expedicion.py
PIECES = (('roca', roca), ('hielo', hielo),
          ('bloques_hielo', bloques_hielo))
VOXEL_PIVOTS = {'tienda', 'iglu', 'cabana', 'bloques_hielo'}          # diseñadas en voxels, no en ub
SHINY = {'hielo', 'bloques_hielo'}                                     # hielo brillante, lo demás mate

if __name__ == '__main__':
    only = set(sys.argv[2:])
    for name, fn in PIECES:
        if only and name not in only: continue
        M, pv = fn()
        mat = (0.45, 0.6) if name in SHINY else (0.9, 0.25)
        n = M.export('models/atrezo_%s.json' % name, pv, jitter=0.012, roughness=mat[0], specular=mat[1],
                     pivots_in_voxels=name in VOXEL_PIVOTS, no_bottom=True)
        print('atrezo_%s: %d voxels' % (name, n))
