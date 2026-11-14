"""Atrezo de la granja de los Gardner (hito 21.13, «El color que cayó del cielo»). Una parte "body",
origen en el centro de la base, la cara principal hacia +Z (como gen_atrezo_innsmouth.py). Todo se ha
vuelto gris y quebradizo: la pintura roja del granero, la corteza, el heno; lo único con color es el
del pozo y los frutos de los manzanos, que brillan de un color que no tiene nombre.

  granero      granero de tablas verticales, rojo desvaído que se vuelve gris desde abajo, hastial con
               el portón de dos hojas en aspa y la puerta del pajar, tejado de tablillas (16/m)
  pozo         brocal de piedra, dos postes, tejadillo, torno con su cuerda y el cubo; dentro, el agua
               y el color que brilla (32/m)
  manzano_1/2  manzano muerto, retorcido y gris, sin hojas, con unos frutos que brillan (32/m)
  cerca        tramo de cerca de troncos partidos, 3 m a lo largo de x (32/m)
  muro         tramo de muro de piedra seca de Nueva Inglaterra, 3 m a lo largo de x (32/m)
  heno         almiar gris, con la vara en el centro (32/m)
  abrevadero   abrevadero de tablas con flejes y agua turbia con un brillo (32/m)

Escribe models/granja_<pieza>.json. Uso: python tools/gen_atrezo_granja.py [piezas...]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
RED = (0.42, 0.18, 0.14); RED_D = (0.30, 0.12, 0.10)
GREY = (0.47, 0.46, 0.44); GREY_D = (0.33, 0.32, 0.31); GREY_L = (0.60, 0.59, 0.56)
TRIM = (0.66, 0.65, 0.61)
DARK = (0.05, 0.05, 0.06)
SHINGLE = (0.22, 0.22, 0.24); SHINGLE_D = (0.15, 0.15, 0.17)
WOOD = (0.40, 0.37, 0.33); WOOD_D = (0.28, 0.26, 0.23)
STONE = (0.44, 0.42, 0.39); STONE_D = (0.30, 0.29, 0.27); STONE_W = (0.52, 0.49, 0.44)
MORTAR = (0.18, 0.17, 0.16)
LICHEN = (0.50, 0.52, 0.44)
IRON = (0.17, 0.17, 0.18)
HAY = (0.58, 0.54, 0.40); HAY_D = (0.42, 0.40, 0.32)
# el color: nunca uno solo (rosa violáceo, lila y un verde de cristal)
COLORS = ((0.95, 0.42, 0.88), (0.70, 0.48, 1.0), (0.58, 1.0, 0.86))


def sphere_line(M, a, b, r, col, glow=0):
    """Cilindro de a a b (voxels) de radio r, con color fijo o función (x, y, z)."""
    n = int(max(abs(b[i] - a[i]) for i in range(3))) + 1
    ri = int(math.ceil(r))
    for k in range(n + 1):
        t = k / max(n, 1)
        cx, cy, cz = (a[i] + (b[i] - a[i]) * t for i in range(3))
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    if x * x + y * y + z * z > r * r + 0.3: continue
                    q = (int(round(cx + x)), int(round(cy + y)), int(round(cz + z)))
                    M.put(*q, P, col(*q) if callable(col) else col, glow)


def the_color(M, x, y, z):
    k = M.noise(x, y, z, 3.0)
    return lerp(COLORS[0], COLORS[1], k) if M.hsh(x // 3, y // 3, z // 3) < 0.7 else COLORS[2]


# ---------------- granero ----------------

def granero():
    """9 x 6,5 m, 4 m de pared y 7 de cumbrera, a 16/m y hueco. La cumbrera va a lo largo de z: el
    hastial con el portón mira a +Z."""
    M = Model(S=1, seed=2113)
    HX, HZ, WALL, RIDGE, OVER = 52, 72, 64, 112, 4
    slope = (RIDGE - WALL) / (HX + OVER)

    def siding(x, y, z):
        u = x if abs(z) >= HZ - 1 else z
        col = u // 6
        if (u % 6) == 0: return lerp(RED_D, DARK, 0.5)                       # junta entre tablas
        if M.hsh(col, 7, 5) < 0.04 and y > 8: return DARK                      # tabla que falta
        c = lerp(RED, RED_D, 0.6 * M.hsh(col, 3, 1))
        g = M.noise(x, y, z, 12.0) * 1.2 - 0.2 + (1.0 - y / RIDGE) * 0.55   # lo gris sube desde abajo
        c = lerp(c, lerp(GREY_D, GREY, M.hsh(col, 1, 9)), max(0.0, min(1.0, g)))
        if M.noise(x, y, z, 4.0) > 0.7: c = lerp(c, GREY_L, 0.4)               # pintura que se pela
        return c

    def roof_y(x): return WALL + (HX + OVER - abs(x + 0.5)) * slope
    for y in range(0, WALL):                                                 # paredes (una tabla de grueso)
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                if min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) > 0: continue
                M.put(x, y, z, P, siding(x, y, z))
    for z in (-HZ, HZ - 1):                                                  # hastiales
        for x in range(-HX, HX):
            for y in range(WALL, int(roof_y(x)) - 1):
                M.put(x, y, z, P, siding(x, y, z))
    for x in range(-HX - OVER, HX + OVER):                                   # tejado de tablillas, con alero
        y0 = roof_y(x)
        for z in range(-HZ - OVER, HZ + OVER):
            row = int((HX + OVER - abs(x + 0.5)) / 3)
            seg = (z + 5 * row) // 5
            miss = M.hsh(row, seg, 21) < 0.025
            c = lerp(SHINGLE, SHINGLE_D, M.hsh(row, seg, 4))
            if row % 2 == 0 and (z + 5 * row) % 5 == 0: c = SHINGLE_D
            if M.noise(x, y0, z, 9.0) > 0.68: c = lerp(c, GREY, 0.35)
            for dy in (0, 1):
                if miss and dy == 1: continue
                M.put(x, int(y0) + dy, z, P, DARK if miss else c)
    for x in range(-2, 2):                                                   # cumbrera
        for z in range(-HZ - OVER, HZ + OVER):
            M.put(x, RIDGE + 2, z, P, SHINGLE_D)
    for y in range(0, WALL):                                                 # esquineras
        for (x, z) in ((-HX, -HZ), (HX - 1, -HZ), (-HX, HZ - 1), (HX - 1, HZ - 1)):
            for dx in (0, 1 if x < 0 else -1):
                M.put(x + dx, y, z, P, TRIM)
                M.put(x, y, z + (1 if z < 0 else -1) * 0 + dx * (1 if z < 0 else -1), P, TRIM)
    # el portón: dos hojas en aspa, marco blanco
    zf = HZ - 1
    DW, DH = 24, 54
    for x in range(-DW - 2, DW + 2):
        for y in range(0, DH + 2):
            edge = abs(x + 0.5) > DW - 0.5 or y >= DH or abs(x + 0.5) < 1
            if edge: M.put(x, y, zf + 1, P, TRIM); continue
            lx = (abs(x + 0.5) - 1) / (DW - 1)                               # 0..1 en la hoja
            ly = y / DH
            brace = abs(lx - ly) < 0.05 or abs(lx - (1 - ly)) < 0.05 or y < 2 or abs(y - DH / 2) < 1.2
            c = TRIM if brace else lerp(lerp(RED_D, GREY_D, 0.55), DARK, 0.25 if (x % 6) == 0 else 0.0)
            M.put(x, y, zf + 1, P, lerp(c, GREY, 0.4 * M.noise(x, y, 0, 6.0)) if not brace else c)
    for x in range(-12, 12):                                                 # la puerta del pajar, abierta
        for y in range(DH + 14, DH + 36):
            if abs(x + 0.5) > 10.5 or y in (DH + 14, DH + 35):
                M.put(x, y, zf + 1, P, TRIM)
            else:
                M.put(x, y, zf, P, HAY_D if y < DH + 22 and M.hsh(x, y, 2) < 0.6 else DARK)
                if y < DH + 20: M.put(x, y, zf + 1, P, lerp(HAY, GREY, 0.5) if M.hsh(x, y, 3) < 0.5 else HAY_D)
    xs = HX - 1                                                              # costado: puerta y ventanas
    for z in range(10, 30):
        for y in range(0, 40):
            M.put(xs + 1, y, z, P, TRIM if z in (10, 29) or y == 39 else lerp(GREY_D, DARK, 0.3))
    for z0 in (-50, -18):
        for z in range(z0, z0 + 12):
            for y in range(30, 42):
                M.put(xs + 1, y, z, P, TRIM if z in (z0, z0 + 11) or y in (30, 41) else DARK)
    return M, {P: [0, 0, 0]}


# ---------------- pozo ----------------

def pozo():
    """Brocal de 1,6 m de diámetro y 0,8 de alto; postes y tejadillo hasta 2,6 m; el torno con la
    cuerda y el cubo. Dentro, a media altura, el agua negra con el color que brilla."""
    M = Model(S=2, seed=2114)
    RO, RI, H = 26, 19, 26
    for y in range(0, H):
        row = y // 5
        for x in range(-RO, RO + 1):
            for z in range(-RO, RO + 1):
                d = math.hypot(x, z)
                if d > RO or d < RI: continue
                a = math.atan2(z, x)
                seg = int((a / math.tau * 18 + row * 0.5) % 18)
                mortar = (y % 5 == 4) or abs(((a / math.tau * 18 + row * 0.5) % 1) - 0.5) > 0.46
                c = MORTAR if mortar and d > RO - 1.5 else lerp(STONE_D, STONE_W, M.hsh(seg, row, 3))
                if not mortar and M.noise(x, y, z, 4.0) > 0.72: c = lerp(c, LICHEN, 0.5)
                M.put(x, y, z, P, c)
    for x in range(-RO - 1, RO + 2):                                         # remate del brocal
        for z in range(-RO - 1, RO + 2):
            d = math.hypot(x, z)
            if RI - 1 <= d <= RO + 1: M.put(x, H, z, P, lerp(STONE, STONE_W, M.noise(x, 0, z, 3.0)))
    for x in range(-RI, RI + 1):                                             # el agua, y el color dentro
        for z in range(-RI, RI + 1):
            d = math.hypot(x, z)
            if d >= RI: continue
            glow = M.noise(x, 0, z, 4.0) > 0.42
            M.put(x, 12, z, P, the_color(M, x, 0, z) if glow else (0.04, 0.04, 0.07), 1 if glow else 0)
    for px in (-23, 22):                                                     # postes
        for y in range(H, 80):
            for dx in range(3):
                for dz in range(-1, 2):
                    M.put(px + dx, y, dz, P, lerp(WOOD_D, WOOD, M.noise(px, y, dz, 6.0)))
    for x in range(-30, 31):                                                 # tejadillo a dos aguas (cumbrera en x)
        for z in range(-18, 19):
            y = 80 + int((18 - abs(z)) * 0.7)
            c = lerp(SHINGLE, SHINGLE_D, M.hsh(x // 4, z // 3, 2))
            M.put(x, y, z, P, c)
            M.put(x, y + 1, z, P, c)
    for z in range(-18, 19):                                                 # viga
        M.put(-22, 79, z, P, WOOD_D); M.put(23, 79, z, P, WOOD_D)
    for x in range(-20, 22):                                                 # el torno
        for a in range(12):
            t = a / 12 * math.tau
            M.put(x, 60 + round(math.sin(t) * 2), round(math.cos(t) * 2), P, WOOD if x % 7 else WOOD_D)
    for x in range(-2, 2):                                                   # cuerda enrollada
        for a in range(12):
            t = a / 12 * math.tau
            M.put(x, 60 + round(math.sin(t) * 3), round(math.cos(t) * 3), P, HAY_D)
    for y in range(40, 58): M.put(0, y, 3, P, HAY_D)                         # la cuerda baja al cubo
    for y in range(32, 40):                                                  # el cubo
        for x in range(-4, 5):
            for z in range(-1, 8):
                if math.hypot(x, z - 3) <= 4.2 and (math.hypot(x, z - 3) > 3 or y == 32):
                    M.put(x, y, z, P, IRON if y in (33, 38) else WOOD)
    for y in range(52, 64): M.put(26, y, 0, P, IRON)                         # manivela
    for z in range(0, 6): M.put(26, 52, z, P, IRON)
    return M, {P: [0, 0, 0]}


# ---------------- manzano ----------------

def manzano(seed, H, spread):
    """Manzano muerto de 32/m: tronco corto y retorcido, ramas que se abren y se doblan, corteza gris
    con grietas y escamas blancas, sin una hoja. Unos frutos demasiado grandes, del color."""
    M = Model(S=2, seed=seed)
    rng = M.rng

    def bark(x, y, z):
        c = lerp(GREY_D, GREY, 0.3 + 0.6 * M.noise(x, y * 0.5, z, 5.0))
        if M.noise(x + 50, y * 0.3, z, 2.5) > 0.7: c = lerp(c, DARK, 0.55)           # grietas
        elif M.hsh(x, y, z) < 0.05: c = GREY_L                                        # escamas
        return c
    for k in range(5):                                                               # raíces
        a = k / 5 * math.tau + rng.uniform(-0.3, 0.3)
        sphere_line(M, (0, 6, 0), (math.cos(a) * 14, -1, math.sin(a) * 14), 2.6, bark)
    pts = [(0.0, 0.0, 0.0)]
    x = z = 0.0
    for y in range(8, H + 1, 8):
        x += rng.uniform(-3.0, 3.0); z += rng.uniform(-3.0, 3.0)
        pts.append((x, y, z))
    for i in range(1, len(pts)):
        sphere_line(M, pts[i - 1], pts[i], 5.5 - 2.0 * i / len(pts), bark)
    tips = []

    def branch(p, ang, up, length, r, depth):
        q = (p[0] + math.cos(ang) * length, p[1] + up * length, p[2] + math.sin(ang) * length)
        mid = ((p[0] + q[0]) / 2 + rng.uniform(-3, 3), (p[1] + q[1]) / 2 + rng.uniform(-2, 3), (p[2] + q[2]) / 2 + rng.uniform(-3, 3))
        sphere_line(M, p, mid, r, bark)
        sphere_line(M, mid, q, r * 0.8, bark)
        if depth == 0 or r < 1.1:
            tips.append(q); return
        for _ in range(2 if rng.random() > 0.2 else 1):
            branch(q, ang + rng.uniform(-0.8, 0.8), max(0.05, up + rng.uniform(-0.3, 0.25)), length * 0.62, r * 0.6, depth - 1)
        if rng.random() < 0.5: tips.append(mid)
    top = pts[-1]
    n = 5
    for k in range(n):
        branch(top, k / n * math.tau + rng.uniform(-0.3, 0.3), rng.uniform(0.25, 0.6), spread * rng.uniform(0.8, 1.1), 3.2, 2)
    rng.shuffle(tips)
    for t in tips[:9]:                                                               # frutos del color
        cx, cy, cz = int(t[0]), int(t[1]) - 4, int(t[2])
        for dx in range(-2, 2):
            for dy in range(-2, 2):
                for dz in range(-2, 2):
                    if dx * dx + dy * dy + dz * dz <= 4:
                        M.put(cx + dx, cy + dy, cz + dz, P, the_color(M, cx + dx, cy + dy, cz + dz), 1)
        for dy in range(0, 3): M.put(cx, cy + 2 + dy, cz, P, GREY_D)                 # rabito
    return M, {P: [0, 0, 0]}


def manzano_1(): return manzano(2115, 44, 34)
def manzano_2(): return manzano(2116, 36, 28)


# ---------------- cerca y muro ----------------

def cerca():
    """3 m de cerca: tres postes y dos troncos partidos que se combean; uno se ha caído de un lado."""
    M = Model(S=2, seed=2117)

    def wood(x, y, z):
        c = lerp(GREY_D, GREY, M.noise(x, y, z, 5.0))
        return lerp(c, DARK, 0.4) if (x * 3 + y) % 11 == 0 else c
    for px in (-47, -1, 45):
        for y in range(0, 38):
            for dx in range(3):
                for dz in range(-1, 2):
                    M.put(px + dx, y, dz, P, wood(px + dx, y, dz))
    for i, y0 in enumerate((14, 28)):
        for x in range(-48, 48):
            sag = int(round(2.0 * math.sin((x + 48) / 46 * math.pi % math.pi)))
            yy = y0 - sag
            if i == 1 and x > 2: yy = int(y0 - (x - 2) * 0.55) if x < 40 else 7      # el de arriba, caído
            for dy in range(3):
                for dz in (2, 3):
                    M.put(x, yy + dy, dz, P, wood(x, yy + dy, dz))
    return M, {P: [0, 0, 0]}


def muro():
    """3 m de muro de piedra seca, 0,9 m de alto y 0,6 de fondo, a hiladas de piedras irregulares con
    huecos oscuros, líquenes y una hilada de remate."""
    M = Model(S=2, seed=2118)
    H, D = 28, 10
    import bisect
    rows = [0]                                       # hiladas de alto desigual (5 a 8)
    while rows[-1] < H + 3: rows.append(rows[-1] + M.rng.randint(5, 8))
    cuts = []                                        # piedras de largo desigual (6 a 17) en cada hilada
    for r in range(len(rows)):
        c = [-48 - M.rng.randint(0, 10)]
        while c[-1] < 48: c.append(c[-1] + M.rng.randint(6, 17))
        cuts.append(c)
    for y in range(0, H + 3):
        row = bisect.bisect_right(rows, y) - 1
        for x in range(-48, 48):
            cell = bisect.bisect_right(cuts[row], x)
            off = 0
            if x in cuts[row]: off = 12
            for z in range(-D, D):
                taper = 2 if y > H - 6 else 0
                if abs(z + 0.5) > D - taper: continue
                if y >= H and (abs(z + 0.5) > D - 3 or M.hsh(x // 8, 3, 4) < 0.15): continue
                gap = (x + off) % 12 == 0 or y == rows[row + 1] - 1
                inner = min(z + D, D - 1 - z) > 1
                if min(z + D, D - 1 - z) > 3 and 2 < y < H - 3 and abs(x + 0.5) < 46: continue   # hueco por dentro
                if gap and not inner: c = MORTAR
                else:
                    c = lerp(STONE_D, STONE_W, M.hsh(cell, row, 1))
                    if M.noise(x, y, z, 3.0) > 0.73: c = lerp(c, LICHEN, 0.55)
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


# ---------------- heno y abrevadero ----------------

def heno():
    """Almiar de 1,7 m, gris como todo, con la vara que asoma."""
    M = Model(S=2, seed=2119)
    R, H = 26, 50
    for y in range(0, H):
        r = R * math.sqrt(max(0.0, 1 - (max(0, y - 10) / (H - 10)) ** 1.8)) if y > 10 else R + 1 - y * 0.1
        ri = int(r) + 1
        for x in range(-ri, ri + 1):
            for z in range(-ri, ri + 1):
                d = math.hypot(x, z)
                if d > r or (d < r - 2.5 and y < H - 3): continue
                a = math.atan2(z, x)
                streak = M.hsh(int(a * 40), y // 6, 3)
                c = lerp(HAY_D, HAY, streak)
                c = lerp(c, GREY, 0.45 + 0.4 * M.noise(x, y, z, 7.0))
                M.put(x, y, z, P, c)
    for y in range(H - 4, H + 14): M.put(0, y, 0, P, WOOD_D); M.put(1, y, 0, P, WOOD_D)
    return M, {P: [0, 0, 0]}


def abrevadero():
    """1,6 m de abrevadero de tablas con dos flejes; el agua, turbia y con un brillo del color."""
    M = Model(S=2, seed=2120)
    HX, HZ, H = 26, 9, 16
    for x in range(-HX, HX):
        for z in range(-HZ, HZ):
            for y in range(0, H):
                wall = min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) < 2 or y < 2
                if not wall: continue
                band = abs(x + 0.5) in (14.5, 15.5) and min(z + HZ, HZ - 1 - z) < 2
                c = IRON if band else lerp(WOOD_D, WOOD, M.noise(x, y, z, 4.0))
                if y % 5 == 0 and not band: c = lerp(c, DARK, 0.4)
                M.put(x, y, z, P, lerp(c, GREY, 0.35))
    for x in range(-HX + 2, HX - 2):
        for z in range(-HZ + 2, HZ - 2):
            shine = M.noise(x, 0, z, 3.0) > 0.66
            M.put(x, H - 4, z, P, the_color(M, x, 0, z) if shine else (0.18, 0.2, 0.19), 1 if shine else 0)
    for x in (-HX - 1, HX):                                                  # patas
        for y in range(0, 4):
            for z in range(-HZ, HZ): M.put(x, y, z, P, WOOD_D)
    return M, {P: [0, 0, 0]}


# ---------------- farol ----------------

def farol():
    """Poste de 2,1 m con un brazo, la tornapunta y el farol de aceite colgado (pivote "light", donde
    ArenaBuilder pone su luz); al pie, unas piedras."""
    M = Model(S=2, seed=2121)
    FLAME = (1.0, 0.78, 0.42)
    for y in range(0, 68):
        for x in range(-1, 2):
            for z in range(-1, 2):
                M.put(x, y, z, P, lerp(WOOD_D, WOOD, M.noise(x, y, z, 4.0) * 0.8 + (0.2 if (y // 10) % 2 else 0)))
    for x in range(-1, 12): M.put(x, 65, 0, P, WOOD_D); M.put(x, 66, 0, P, WOOD_D)
    for k in range(9): M.put(1 + k, 56 + k, 0, P, WOOD_D)
    for y in range(60, 65): M.put(11, y, 0, P, IRON)
    LX, LY = 11, 54
    for x in range(LX - 3, LX + 4):
        for z in range(-3, 4):
            M.put(x, LY - 5, z, P, IRON)
            if abs(x - LX) < 3 and abs(z) < 3: M.put(x, LY + 4, z, P, IRON)
    for y in range(LY - 4, LY + 4):
        for x in range(LX - 2, LX + 3):
            for z in range(-2, 3):
                edge = abs(x - LX) == 2 and abs(z) == 2
                M.put(x, y, z, P, IRON if edge else FLAME, 0 if edge else 1)
    for y in range(LY + 5, LY + 7): M.put(LX, y, 0, P, IRON)
    for k in range(6):                                                       # piedras al pie
        a = k / 6 * math.tau + 0.3
        cx, cz = round(math.cos(a) * 5), round(math.sin(a) * 5)
        for dx in range(-2, 2):
            for dz in range(-2, 2):
                for y in range(0, 3 if k % 2 else 2):
                    M.put(cx + dx, y, cz + dz, P, lerp(STONE_D, STONE_W, M.hsh(k, 1, 2)))
    return M, {P: [0, 0, 0], 'light': [LX, LY, 0]}


PIECES = {'granero': granero, 'farol': farol, 'pozo': pozo, 'manzano_1': manzano_1, 'manzano_2': manzano_2,
          'cerca': cerca, 'muro': muro, 'heno': heno, 'abrevadero': abrevadero}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    here = os.path.join(os.path.dirname(__file__), '..')
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export(os.path.join(here, 'models', 'granja_%s.json' % name), piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('granja_%s: %d voxels' % (name, n))
