"""Atrezo de los pantanos de Luisiana y el ritual del culto (hito 7.2). Una parte "body",
origen en el centro de la base.

  hoguera     hoguera grande de troncos cruzados con llamas que brillan (pivote "light") (32/m)
  monolito    el monolito de piedra en medio del claro, de 2,6 m, con jeroglíficos; el ídolo
              va encima como otra pieza (cth_idolo con "y") (32/m)
  cipres      ciprés calvo del pantano: tronco ensanchado en la base, "rodillas" que salen del
              agua y barbas de musgo español colgando de las ramas (32/m)
  choza       choza de tablas sobre pilotes con tejado de chapa (16/m)
  poste       poste con una antorcha y una calavera de vaca (32/m)
  piragua     piragua de un tronco varada (32/m)

Escribe models/lui_<pieza>.json. Uso: python tools/gen_atrezo_luisiana.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
LOG = (0.30, 0.22, 0.15); LOG_D = (0.18, 0.13, 0.09); ASH = (0.20, 0.19, 0.18); EMBER = (1.0, 0.45, 0.15)
FLAME = (1.0, 0.62, 0.22); FLAME_C = (1.0, 0.88, 0.50)
STONE = (0.20, 0.23, 0.21); STONE_D = (0.12, 0.14, 0.13); CARVE = (0.06, 0.08, 0.07)
BARK = (0.32, 0.26, 0.20); BARK_D = (0.20, 0.16, 0.12)
MOSS = (0.50, 0.54, 0.44); MOSS_D = (0.36, 0.40, 0.32)
PLANK = (0.40, 0.34, 0.26); PLANK_D = (0.28, 0.23, 0.17); TIN = (0.36, 0.30, 0.26); RUST = (0.44, 0.26, 0.14)
BONE = (0.80, 0.76, 0.64); BONE_D = (0.55, 0.52, 0.44)


def line(M, a, b, r, col):
    n = int(max(abs(b[i] - a[i]) for i in range(3))) + 1
    for k in range(n + 1):
        t = k / max(n, 1)
        c = [a[i] + (b[i] - a[i]) * t for i in range(3)]
        ri = int(math.ceil(r))
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    if x * x + y * y + z * z <= r * r + 0.3:
                        q = (int(round(c[0] + x)), int(round(c[1] + y)), int(round(c[2] + z)))
                        M.put(*q, P, col(*q) if callable(col) else col)


def flames(M, cx, cz, y0, h, r0):
    for y in range(y0, y0 + h):
        r = r0 * (1 - (y - y0) / h) + 0.5
        for x in range(-int(r) - 1, int(r) + 2):
            for z in range(-int(r) - 1, int(r) + 2):
                d = math.hypot(x, z)
                if d > r or M.hsh(x + cx, y, z + cz) < 0.25 * (y - y0) / h: continue
                M.put(cx + x, y, cz + z, P, FLAME_C if d < r * 0.4 and y < y0 + h * 0.6 else FLAME, glow=1)


CHAR = (0.07, 0.06, 0.05); CHAR_L = (0.14, 0.11, 0.09); EMBER_D = (0.70, 0.18, 0.06); RING_C = (0.48, 0.40, 0.30)
FLAME_R = (0.92, 0.30, 0.08); SOOT = (0.10, 0.10, 0.10); SPARK = (1.0, 0.75, 0.35)
ROCK_A = (0.30, 0.29, 0.27); ROCK_B = (0.22, 0.21, 0.20); ROCK_C = (0.38, 0.36, 0.33)


def _log(M, a, b, r, seed, charred=0.0):
    """Tronco: corteza con surcos, extremos cortados con anillos y la parte quemada negra con
    grietas de brasa. charred: fracción del tronco (desde b) quemada."""
    ax, ay, az = a; bx, by, bz = b
    L = math.dist(a, b)
    tx, ty, tz = (bx - ax) / L, (by - ay) / L, (bz - az) / L
    n = int(L * 1.5) + 1
    ri = int(math.ceil(r)) + 1
    for k in range(n + 1):
        t = k / n
        cx, cy, cz = ax + (bx - ax) * t, ay + (by - ay) * t, az + (bz - az) * t
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    if x * x + y * y + z * z > r * r + 0.3: continue
                    q = (int(round(cx + x)), int(round(cy + y)), int(round(cz + z)))
                    along = (q[0] - ax) * tx + (q[1] - ay) * ty + (q[2] - az) * tz
                    f = along / L
                    if f < 0 or f > 1.0: continue
                    rad = math.sqrt(max(0.0, (q[0] - ax) ** 2 + (q[1] - ay) ** 2 + (q[2] - az) ** 2 - along ** 2))
                    end = f < 0.03 or f > 0.97
                    if end and rad < r - 0.8:                                    # testa con anillos
                        c = LOG_D if int(rad) % 2 else (0.46, 0.34, 0.22)
                    else:
                        ang = math.atan2(q[1] - cy, q[0] - cx) + math.atan2(q[2] - cz, q[0] - cx)
                        c = LOG if (int(ang * 3 + seed) % 3) else LOG_D               # surcos de la corteza
                        c = lerp(c, BARK_D, 0.4 * M.noise(q[0], q[1], q[2], 3.0))
                    if f > 1 - charred:                                             # quemado
                        burn = (f - (1 - charred)) / max(charred, 1e-6)
                        c = lerp(c, CHAR, min(1.0, burn * 1.6))
                        if burn > 0.4 and M.hsh(*q) > 0.82:
                            M.put(*q, P, EMBER if M.hsh(q[0], 1, q[2]) > 0.5 else EMBER_D, glow=1); continue
                    M.put(*q, P, c)


def hoguera():
    """Hoguera del ritual (rehecha a 64/m en la revisión de arte del 13-10-2026): cerco de piedras
    redondeadas de tamaños distintos, tiznadas por dentro; lecho de ceniza con brasas que brillan,
    carbones y restos; troncos de corteza con surcos, testas con anillos y las puntas quemadas con
    grietas de brasa, en cono y dos cruzados por debajo; llamas en varias lenguas, blanco
    amarillento en el centro, naranja y con puntas rojas; chispas que suben."""
    M = Model(S=4, seed=91)
    rng = M.rng
    # cerco de piedras
    a = 0.0
    while a < math.tau - 0.15:
        rs = rng.uniform(2.6, 4.6)
        cx, cz = math.cos(a) * 26, math.sin(a) * 26
        h = rs * rng.uniform(0.7, 1.0)
        for x in range(int(cx - rs) - 1, int(cx + rs) + 2):
            for z in range(int(cz - rs) - 1, int(cz + rs) + 2):
                for y in range(0, int(h * 1.6) + 1):
                    d = ((x - cx) / rs) ** 2 + ((z - cz) / rs) ** 2 + ((y - h * 0.4) / (h * 1.1)) ** 2
                    if d > 1: continue
                    c = lerp(ROCK_B, ROCK_A, M.noise(x, y, z, 2.0))
                    if M.hsh(x, y, z) > 0.9: c = ROCK_C
                    if math.hypot(x, z) < 26 - rs * 0.3: c = lerp(c, SOOT, 0.7)        # tiznada por dentro
                    M.put(x, y, z, P, c)
        a += (2 * rs + rng.uniform(0.2, 1.2)) / 26
    # lecho de ceniza con brasas, carbones y restos
    for x in range(-24, 25):
        for z in range(-24, 25):
            d = math.hypot(x, z)
            if d > 23: continue
            hgt = 1 + int(2 * (1 - d / 23) + M.noise(x, 0, z, 4.0) * 1.5)
            for y in range(0, hgt):
                c = lerp(ASH, (0.32, 0.31, 0.29), M.noise(x, y, z, 2.5))
                gl = 0
                if y == hgt - 1:
                    e = M.noise(x, 3, z, 3.0) * (1.3 - d / 23)
                    if e > 0.62: c, gl = (EMBER if e > 0.75 else EMBER_D), 1
                    elif M.hsh(x, y, z) > 0.86: c = CHAR_L
                M.put(x, y, z, P, c, glow=gl)
    for _ in range(14):                                                        # carbones
        cx, cz = rng.uniform(-18, 18), rng.uniform(-18, 18)
        if math.hypot(cx, cz) > 19: continue
        for x in range(int(cx), int(cx) + rng.randint(2, 4)):
            for z in range(int(cz), int(cz) + rng.randint(2, 3)):
                for y in (3, 4):
                    M.put(x, y, z, P, CHAR if M.hsh(x, y, z) > 0.3 else EMBER_D, glow=0 if M.hsh(x, y, z) > 0.3 else 1)
    # troncos: dos cruzados por debajo y seis en cono
    _log(M, (-22, 4, -6), (20, 5, 8), 3.4, 1, charred=0.0)
    _log(M, (-8, 7, 21), (6, 6, -21), 3.2, 2, charred=0.0)
    for k in range(5):
        aa = k / 5 * math.tau + rng.uniform(-0.15, 0.15)
        R = rng.uniform(19, 23)
        _log(M, (math.cos(aa) * R, 3, math.sin(aa) * R), (math.cos(aa) * 3.5, rng.uniform(32, 40), math.sin(aa) * 3.5),
             rng.uniform(2.4, 2.8), k + 3, charred=0.55)
    # llamas: varias lenguas que se retuercen
    tongues = [(0, 0, 78, 9)] + [(math.cos(i * 0.9 + 0.3) * rng.uniform(5, 9), math.sin(i * 0.9 + 0.3) * rng.uniform(5, 9), rng.randint(40, 62), rng.uniform(4.5, 6.5)) for i in range(7)]
    for (tx, tz, h, r0) in tongues:
        ph = rng.uniform(0, 6)
        for y in range(6, 6 + h):
            f = (y - 6) / h
            r = r0 * (1 - f) ** 1.2 * (0.8 + 0.3 * math.sin(ph + f * 9)) + 0.5
            ox = tx * (1 - f * 0.6) + 2.2 * math.sin(ph + f * 5) * f
            oz = tz * (1 - f * 0.6) + 2.2 * math.cos(ph + f * 4) * f
            for x in range(int(ox - r) - 1, int(ox + r) + 2):
                for z in range(int(oz - r) - 1, int(oz + r) + 2):
                    d = math.hypot(x - ox, z - oz)
                    if d > r or M.hsh(x, y, z) < 0.08 + 0.4 * f * f: continue
                    if d < r * 0.35 and f < 0.4: c = FLAME_C
                    elif f > 0.65 or d > r * 0.8: c = FLAME_R if f > 0.5 else FLAME
                    else: c = FLAME
                    M.put(x, y, z, P, c, glow=1)
    for _ in range(26):                                                        # chispas
        M.put(int(rng.uniform(-14, 14)), int(rng.uniform(70, 110)), int(rng.uniform(-14, 14)), P, SPARK, glow=1)
    return M, {P: [0, 0, 0], 'light': [0, 40, 0]}


def monolito():
    M = Model(S=2, seed=92)
    for y in range(0, 84):
        w = 14 - y // 14
        for x in range(-w, w):
            for z in range(-w + 3, w - 3):
                if min(x + w, w - 1 - x, z + w - 3, w - 4 - z) > 1 and y < 82: continue
                c = lerp(STONE, STONE_D, M.noise(x, y, z, 6.0))
                if z == w - 4 and 8 < y < 76 and (x * 3 + y * 5) % 7 == 0: c = CARVE
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


FOL = (0.19, 0.26, 0.13); FOL_D = (0.11, 0.16, 0.09); FOL_L = (0.29, 0.35, 0.17); FOL_R = (0.42, 0.30, 0.15)


def cipres(variant=1):
    """Ciprés calvo de la ciénaga (rehecho el 09-10-2026), 32/m, ~4,7 m: tronco con la base
    acanalada en contrafuertes que se estrecha hacia arriba, "rodillas" alrededor, ramas que salen
    casi horizontales y acaban en masas de follaje planas y escalonadas (verde oscuro con toques
    rojizos, como el ciprés en otoño) y cortinas largas de musgo español colgando por debajo.
    Visto desde arriba se lee por la copa. Dos variantes de forma (semilla)."""
    M = Model(S=2, seed=93 + variant * 17)
    rng = M.rng
    H = 132 + 12 * variant
    lean = (rng.uniform(-0.06, 0.06), rng.uniform(-0.06, 0.06))

    def bark(x, y, z):
        c = BARK_D if M.noise(x, y * 0.4, z, 3.0) > 0.58 else BARK
        if y < 14 and M.noise(x, y, z, 5.0) > 0.5: c = lerp(c, MOSS_D, 0.5)          # verdín de la crecida
        return c

    for y in range(0, H):                                        # tronco acanalado, hueco
        r = 4.0 + max(0, 26 - y) * 0.42                          # se ensancha mucho abajo
        cx, cz = lean[0] * y, lean[1] * y
        flute = 0.22 * max(0.0, 1 - y / 30.0)
        for x in range(-int(r) - 3, int(r) + 4):
            for z in range(-int(r) - 3, int(r) + 4):
                ang = math.atan2(z, x)
                d = math.hypot(x, z) / (1 + flute * math.sin(ang * 6 + variant))
                if r - 2.0 <= d <= r: M.put(int(x + cx), y, int(z + cz), P, bark(x, y, z))
    for k in range(6 + variant):                                 # rodillas
        ang = rng.uniform(0, math.tau); dd = rng.uniform(14, 24)
        kx, kz = math.cos(ang) * dd, math.sin(ang) * dd
        hk = rng.randint(6, 13)
        for y in range(0, hk):
            rr = 2.2 * (1 - y / (hk + 2))
            for x in range(-3, 4):
                for z in range(-3, 4):
                    if math.hypot(x, z) <= rr + 0.3: M.put(int(kx + x), y, int(kz + z), P, bark(x, y, z))

    def branch(a, b, thick):
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]), abs(b[2] - a[2]))) + 1
        for i in range(n + 1):
            t = i / n
            px, py, pz = (a[k] + (b[k] - a[k]) * t for k in range(3))
            w = thick * (1 - 0.5 * t)
            for x in range(-int(w), int(w) + 1):
                for z in range(-int(w), int(w) + 1):
                    for y in range(-int(w), int(w) + 1):
                        if x * x + y * y + z * z <= w * w + 0.5: M.put(int(px + x), int(py + y), int(pz + z), P, bark(px, py, pz))

    def foliage(cx, cy, cz, rx, ry, rz):
        """Masa de follaje plana: cáscara de elipsoide con el borde deshilachado."""
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            for z in range(int(cz - rz) - 1, int(cz + rz) + 2):
                for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
                    q = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 + ((z - cz) / rz) ** 2
                    q += 0.35 * (M.noise(x, y, z, 3.0) - 0.5)
                    if not (0.62 < q <= 1.0): continue
                    n = M.noise(x, y, z, 4.0)
                    c = FOL_L if y > cy + ry * 0.4 and n > 0.45 else (FOL_D if n < 0.35 else FOL)
                    if M.noise(x + 50, y, z, 6.0) > 0.74: c = FOL_R                    # toques rojizos
                    M.put(x, y, z, P, c)

    pads = []
    nb = 6 + variant
    for i in range(nb):                                          # ramas y masas en pisos
        ang = i / nb * math.tau + rng.uniform(-0.35, 0.35)
        y0 = int(H * 0.52) + int(i * (H * 0.42) / nb)
        reach = rng.uniform(16, 30) * (1.15 - 0.4 * i / nb)    # las de abajo, más largas
        base = (lean[0] * y0, y0, lean[1] * y0)
        tip = (base[0] + math.cos(ang) * reach, y0 + rng.uniform(4, 10), base[2] + math.sin(ang) * reach)
        branch(base, tip, 1.6)
        pads.append((tip, rng.uniform(11, 16), rng.uniform(4, 6)))
    top = (lean[0] * H, H + 4, lean[1] * H)                      # copa: un piso plano arriba
    pads.append((top, 14, 5))
    for (px, py, pz), rxz, ry in pads:
        foliage(px, py, pz, rxz, ry, rxz * rng.uniform(0.8, 1.1))
    for (px, py, pz), rxz, ry in pads:                           # musgo español bajo cada masa
        for j in range(int(rxz * 1.4)):
            ang = rng.uniform(0, math.tau); r = rng.uniform(0.2, 0.85) * rxz
            mx, mz = px + math.cos(ang) * r, pz + math.sin(ang) * r
            length = rng.randint(14, 36)
            for k in range(length):
                sway = math.sin(k * 0.35 + j) * 0.9
                col = MOSS if (k + j) % 4 else MOSS_D
                if k > length - 4: col = lerp(MOSS, (0.62, 0.64, 0.56), 0.5)
                M.put(int(mx + sway), int(py - ry * 0.6 - k), int(mz), P, col, over=False)
    return M, {P: [0, 0, 0]}


IRON = (0.16, 0.16, 0.17); ROPE = (0.52, 0.46, 0.32)
WALL = (0.40, 0.36, 0.30); WALL_D = (0.26, 0.23, 0.19); WALL_L = (0.50, 0.46, 0.38); BATTEN = (0.30, 0.26, 0.21)
ROT = (0.18, 0.20, 0.13); WIN_L = (1.0, 0.70, 0.36); SHUT = (0.30, 0.34, 0.30); TIN_L = (0.48, 0.42, 0.38)
SKIN = (0.50, 0.38, 0.26); NET = (0.36, 0.32, 0.24); JUG = (0.62, 0.50, 0.34)


def choza():
    """Choza del bayou sobre pilotes (rehecha a 32/m en la revisión de arte del 13-10-2026):
    pilotes de tronco con la línea de agua y riostras en aspa, vigas a la vista, porche delantero
    con baranda y escalera; paredes de tablas verticales con tapajuntas, gastadas y podridas
    abajo, con huecos; puerta de tablas con su travesaño en zeta, entreabierta; ventana encendida
    con contraventanas (una descolgada) y otra cegada con tablas; tejado de chapa ondulada en
    láminas solapadas con óxido, caballete y alero; tejadillo del porche sobre postes; chimenea de
    tubo con sombrerete; un farol junto a la puerta, una red tendida, una piel clavada, una garrafa
    y un amuleto de huesos colgado."""
    M = Model(S=2, seed=94)
    X0, X1, Z0, Z1 = -48, 48, -36, 34                    # cuerpo de la casa (frente en z = Z1)
    FY = 28                                              # altura del suelo (pilotes de 0,9 m)
    WH = 50                                              # altura de las paredes
    # pilotes con la línea de agua y riostras
    piles = [(x, z) for x in (X0 - 2, 0, X1 + 1) for z in (Z0 - 2, Z1 + 1)] + [(X0 + 8, Z1 + 16), (X1 - 9, Z1 + 16)]
    for (px, pz) in piles:
        for y in range(0, FY):
            for dx in range(-2, 3):
                for dz in range(-2, 3):
                    if dx * dx + dz * dz > 5: continue
                    c = LOG if (dx + y // 3) % 3 else LOG_D
                    if y < 8: c = lerp(c, ROT, 0.6)                              # mojado y verdín abajo
                    M.put(px + dx, y, pz + dz, P, c)
    for (pa, pb) in (((X0 - 2, Z1 + 1), (0, Z1 + 1)), ((0, Z1 + 1), (X1 + 1, Z1 + 1))):
        for k in range(0, 49):
            t = k / 48
            x = int(pa[0] + (pb[0] - pa[0]) * t)
            for y in (int(4 + t * 20), int(24 - t * 20)):
                M.put(x, y, pa[1] + 2, P, LOG_D); M.put(x, y + 1, pa[1] + 2, P, LOG_D)
    # suelo de tablas y porche
    for x in range(X0 - 4, X1 + 4):
        for z in range(Z0 - 4, Z1 + 18):
            if z >= Z1 and not (X0 + 6 <= x < X1 - 6): continue                # el porche es algo más estrecho
            b = (x // 5)
            c = lerp(PLANK, PLANK_D, M.hsh(b, 2, 2) * 0.7)
            if x % 5 == 0: c = lerp(c, (0.08, 0.07, 0.06), 0.6)
            M.put(x, FY, z, P, c); M.put(x, FY - 1, z, P, PLANK_D)
        for z in (Z0 - 4, Z1, Z1 + 17):                                       # vigas a la vista
            M.put(x, FY - 2, z, P, LOG_D); M.put(x, FY - 3, z, P, LOG_D)
    # paredes de tablas verticales con tapajuntas
    def wall_col(u, y, side):
        b = u // 6
        c = lerp(WALL, WALL_D, 0.6 * M.hsh(b, side, 1))
        if M.hsh(b, side, 4) > 0.85: c = lerp(c, WALL_L, 0.5)
        c = lerp(c, WALL_D, 0.3 * M.noise(u, y * 0.3, side, 3.0))
        if y - FY < 8 + 6 * M.noise(u, 0, side, 6.0): c = lerp(c, ROT, 0.55)  # podrido y verdín abajo
        return c
    gaps = set()
    for _ in range(10): gaps.add((M.rng.randint(X0, X1), M.rng.randint(FY + 6, FY + WH - 6)))
    for y in range(FY + 1, FY + WH):
        for x in range(X0, X1):
            for z, side in ((Z1 - 1, 0), (Z0, 1)):
                if (x - X0) % 6 == 0 and any(abs(y - gy) < 4 and abs(x - gx) < 1 for gx, gy in gaps): continue   # rendija
                M.put(x, y, z, P, wall_col(x, y, side))
                if (x - X0) % 6 == 0: M.put(x, y, z + (1 if side == 0 else -1), P, BATTEN)
        for z in range(Z0, Z1):
            for x, side in ((X0, 2), (X1 - 1, 3)):
                M.put(x, y, z, P, wall_col(z, y, side))
                if (z - Z0) % 6 == 0: M.put(x + (-1 if side == 2 else 1), y, z, P, BATTEN)
    fz = Z1                                                                    # cara delantera (fuera)
    # puerta entreabierta (hacia fuera) con travesaño en zeta
    for x in range(-8, 8):
        for y in range(FY + 1, FY + 38): M.put(x, y, Z1 - 1, P, (0.03, 0.03, 0.03))
    for k in range(15):
        x, z = -8 + int(k * 0.6), Z1 + 1 + int(k * 0.8)
        for y in range(FY + 1, FY + 38):
            c = lerp(PLANK, PLANK_D, M.hsh(k // 4, 7, 7) * 0.6)
            if k % 4 == 0: c = PLANK_D
            if y in (FY + 6, FY + 7, FY + 30, FY + 31) or abs((y - FY - 7) - k * 23 / 14) < 1.2: c = BATTEN
            M.put(x, y, z, P, c)
    for y in range(FY + 1, FY + 40):                                          # marco
        for x in (-10, -9, 8, 9): M.put(x, y, fz, P, BATTEN)
    for x in range(-10, 10): M.put(x, FY + 38, fz, P, BATTEN); M.put(x, FY + 39, fz, P, BATTEN)
    # ventana encendida con contraventanas, y otra cegada con tablas
    wx, wy = 26, FY + 22
    for x in range(wx - 8, wx + 8):
        for y in range(wy - 7, wy + 8):
            fr = x in (wx - 8, wx + 7) or y in (wy - 7, wy + 7)
            mull = x in (wx - 1, wx) or y == wy
            if fr: M.put(x, y, fz, P, BATTEN)
            elif mull: M.put(x, y, Z1 - 1, P, BATTEN)
            else: M.put(x, y, Z1 - 1, P, WIN_L, glow=1)
    for y in range(wy - 7, wy + 8):                                           # contraventana abierta y otra descolgada
        for k in range(8):
            M.put(wx - 9 - k, y, fz, P, SHUT if (k % 4) else lerp(SHUT, (0.1, 0.1, 0.1), 0.5))
        for k in range(8):
            yy = y - (k // 2)
            M.put(wx + 8 + k, yy, fz + 1, P, SHUT if k % 4 else lerp(SHUT, (0.1, 0.1, 0.1), 0.5))
    bx = -30
    for x in range(bx - 7, bx + 7):
        for y in range(FY + 15, FY + 30):
            M.put(x, y, Z1 - 1, P, (0.05, 0.05, 0.05))
    for i, yy in enumerate((FY + 17, FY + 22, FY + 27)):                     # tablas clavadas en la ventana cegada
        for x in range(bx - 9, bx + 9):
            dy = int((x - bx) * (0.15 if i % 2 else -0.12))
            for y in (yy + dy, yy + dy + 1, yy + dy + 2):
                M.put(x, y, fz, P, lerp(PLANK, PLANK_D, M.hsh(i, x // 6, 3) * 0.6))
    # tejado de chapa ondulada en láminas solapadas
    RY = FY + WH
    for x in range(X0 - 6, X1 + 6):
        for z in range(Z0 - 8, Z1 + 8):
            y = RY + 22 - abs(z - (Z0 + Z1) // 2) * 22 // ((Z1 - Z0) // 2 + 8)
            sheet = (x - X0 + 6) // 18
            lap = (x - X0 + 6) % 18 == 0
            c = TIN if (x % 3) else TIN_L                                       # ondas
            if M.noise(x, y, z, 7.0) > 0.58: c = lerp(c, RUST, 0.6 + 0.4 * M.noise(x, y, z, 2.0))
            if M.hsh(sheet, 3, 3) > 0.7: c = lerp(c, RUST, 0.3)
            M.put(x, y, z, P, c)
            M.put(x, y + (1 if x % 3 == 0 else 0), z, P, c)
            if lap: M.put(x, y + 1, z, P, lerp(c, (0.1, 0.1, 0.1), 0.3))
            if z in (Z0 - 8, Z1 + 7): M.put(x, y - 1, z, P, RUST)             # borde oxidado del alero
        M.put(x, RY + 23, (Z0 + Z1) // 2, P, TIN_L); M.put(x, RY + 23, (Z0 + Z1) // 2 + 1, P, TIN_L)   # caballete
    for z in range(Z0, Z1):
        top = RY + 22 - abs(z - (Z0 + Z1) // 2) * 22 // ((Z1 - Z0) // 2 + 8)
        for y in range(RY, top):
            for x in (X0, X1 - 1): M.put(x, y, z, P, wall_col(z, y, 4))
    # tejadillo del porche sobre postes
    for x in range(X0 + 4, X1 - 4):
        for z in range(Z1 + 1, Z1 + 21):
            y = RY - 2 - (z - Z1) // 4
            c = TIN if x % 3 else TIN_L
            if M.noise(x, 9, z, 6.0) > 0.55: c = lerp(c, RUST, 0.7)
            M.put(x, y, z, P, c)
    for px in (X0 + 8, 0, X1 - 9):
        for y in range(FY, RY - 9):
            for dx in (0, 1):
                for dz in (0, 1): M.put(px + dx, y, Z1 + 15 + dz, P, LOG if y % 7 else LOG_D)
    # baranda del porche (con un tramo roto) y escalera
    for x in range(X0 + 6, X1 - 6):
        if -10 <= x <= 10: continue
        if 24 < x < 34: continue                                                # roto
        M.put(x, FY + 14, Z1 + 16, P, PLANK); M.put(x, FY + 15, Z1 + 16, P, PLANK_D)
        if x % 8 == 0:
            for y in range(FY + 1, FY + 14): M.put(x, y, Z1 + 16, P, PLANK_D)
    for k in range(7):
        y = FY - 4 - k * 4
        for x in range(-9, 9):
            for dz in range(0, 3): M.put(x, y, Z1 + 18 + k * 3 + dz, P, lerp(PLANK, PLANK_D, M.hsh(k, 1, 1)))
        for x in (-10, 9):
            for yy in range(y - 1, y + 4): M.put(x, yy, Z1 + 18 + k * 3, P, LOG_D)
    # chimenea de tubo con sombrerete
    for y in range(RY + 8, RY + 40):
        for x in range(30, 35):
            for z in range(-16, -11):
                if (x - 32) ** 2 + (z + 13.5) ** 2 > 6: continue
                M.put(x, y, z, P, IRON if y % 9 else RUST)
    for x in range(28, 37):
        for z in range(-18, -9): M.put(x, RY + 41, z, P, IRON)
    # farol junto a la puerta, red tendida, piel clavada, garrafa y amuleto de huesos
    for y in range(FY + 26, FY + 33):
        for x in (12, 13, 14):
            cage = y in (FY + 26, FY + 32) or x != 13
            M.put(x, y, fz + 1, P, IRON if cage else WIN_L, glow=0 if cage else 1)
    for x in range(-44, -16):                                                 # red en el porche (en la pared)
        for y in range(FY + 2, FY + 14):
            if (x + y) % 3 == 0 or (x - y) % 3 == 0: M.put(x, y + (abs(x + 30) // 6), fz, P, NET)
    for x in range(34, 44):                                                   # piel clavada
        for y in range(FY + 30, FY + 44):
            if abs(x - 39) + abs(y - FY - 37) * 0.6 < 6: M.put(x, y, fz, P, SKIN if M.hsh(x, y, 2) > 0.2 else lerp(SKIN, PLANK_D, 0.5))
    for y in range(FY + 1, FY + 8):                                           # garrafa
        for x in range(-16, -11):
            for z in range(Z1 + 6, Z1 + 11):
                if (x + 13.5) ** 2 + (z - Z1 - 8.5) ** 2 < 5.5 - (y - FY - 4) ** 2 * 0.15: M.put(x, y, z, P, JUG)
    M.put(-14, FY + 8, Z1 + 8, P, PLANK_D)
    for y in range(RY - 12, RY - 3): M.put(-4, y, Z1 + 12, P, ROPE)          # amuleto de huesos bajo el tejadillo
    for (dx, dy) in ((-1, -1), (1, -1), (0, -2), (-2, -3), (2, -3), (0, -4)):
        M.put(-4 + dx, RY - 12 + dy, Z1 + 12, P, BONE if dy % 2 else BONE_D)
    return M, {P: [0, 0, 0]}


def poste():
    """Poste con antorcha del ritual (rehecho más grande y grueso a 64/m en la revisión de arte
    del 13-10-2026): un tronco de ciprés de 3,4 m y unos 30 cm, con la corteza en tiras, muescas
    talladas con símbolos del culto, la calavera de vaca clavada con sus cuernos, tiras de tela y
    plumas negras atadas, un collar de huesos colgando, la antorcha arriba con los trapos
    empapados y una llama grande, hollín, y un círculo de piedras y ceniza al pie."""
    M = Model(S=4, seed=95)
    rng = M.rng
    H, R = 196, 9.5
    for y in range(0, H):
        r = R - 1.5 * y / H + (2.5 if y < 8 else 0)
        for x in range(-13, 14):
            for z in range(-13, 14):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r or d < r - 2.5: continue
                a = math.atan2(z, x)
                c = LOG if int((a + math.pi) * 6 + y * 0.03) % 3 else LOG_D                 # tiras de corteza
                c = lerp(c, BARK_D, 0.3 * M.noise(x, y, z, 4.0))
                if y > H - 30: c = lerp(c, (0.06, 0.05, 0.04), (y - H + 30) / 40)           # hollín
                M.put(x, y, z, P, c)
        if y == H - 1:
            for x in range(-10, 11):
                for z in range(-10, 11):
                    if math.hypot(x, z) < r: M.put(x, y, z, P, LOG_D)
    for k, y0 in enumerate((40, 62, 84)):                                          # muescas con símbolos
        for dy in range(10):
            for dx in range(-4, 5):
                if (abs(dx) == 4 or dy in (0, 9)) or (k == 0 and abs(dx) == abs(dy - 5)) or (k == 1 and dx == 0) or (k == 2 and abs(dy - 5) + abs(dx) == 4):
                    M.put(dx, y0 + dy, 9, P, (0.10, 0.07, 0.05))
    for x in range(-12, 13):                                                        # calavera de vaca
        for y in range(108, 136):
            fy = (y - 108) / 28
            w = 7 + 5 * fy if fy > 0.4 else 7 - 3 * (0.4 - fy) * 2
            if abs(x) > w: continue
            c = BONE if M.noise(x, y, 0, 3.0) < 0.7 else BONE_D
            if fy > 0.55 and abs(abs(x) - 5) < 2.2 and abs(y - 126) < 3: c = (0.04, 0.04, 0.04)   # cuencas
            if fy < 0.2 and abs(x) in (1, 2) and y in (111, 112): c = (0.05, 0.05, 0.05)            # fosas
            M.put(x, y, 11 + int(3 * math.cos(x / 9)), P, c)
            M.put(x, y, 10, P, BONE_D)
    for s in (-1, 1):                                                               # cuernos
        for k in range(26):
            x = s * (12 + k); y = 134 + int(8 * math.sin(k / 26 * math.pi)) + k // 4
            r = 2.5 - k / 14
            for dx in range(-2, 3):
                for dy in range(-2, 3):
                    if dx * dx + dy * dy <= r * r: M.put(x + dx, y + dy, 11, P, BONE if k < 20 else (0.30, 0.26, 0.20))
    for k in range(9):                                                              # tiras de tela y plumas
        a = k / 9 * math.tau
        x0, z0 = int(10 * math.cos(a)), int(10 * math.sin(a))
        col = [(0.46, 0.10, 0.08), (0.10, 0.10, 0.10), (0.56, 0.50, 0.36)][k % 3]
        for j in range(rng.randint(10, 22)):
            M.put(x0 + int(j * 0.15 * math.cos(a)), 150 - j, z0 + int(j * 0.15 * math.sin(a)), P, col)
    for k in range(24):                                                             # collar de huesos
        a = k / 24 * math.pi + math.pi * 0.1
        x = int(12 * math.cos(a)); y = 100 - int(14 * math.sin(a)); z = 12
        M.put(x, y, z, P, ROPE if k % 3 else BONE)
        if k % 3 == 0:
            for j in range(3): M.put(x, y - j, z + 1, P, BONE)
    for y in range(H, H + 18):                                                      # trapos de la antorcha
        for x in range(-12, 13):
            for z in range(-12, 13):
                d = math.hypot(x, z)
                if d > 11 - abs(y - H - 9) * 0.3: continue
                c = (0.18, 0.14, 0.10) if (y + int(math.atan2(z, x) * 4)) % 3 else (0.10, 0.08, 0.06)
                if M.hsh(x, y, z) > 0.9: c = (1.0, 0.45, 0.15)
                M.put(x, y, z, P, c, glow=1 if c == (1.0, 0.45, 0.15) else 0)
    flames(M, 0, 0, H + 14, 48, 10)
    for k in range(16):                                                             # chispas
        M.put(rng.randint(-10, 10), H + 64 + rng.randint(0, 30), rng.randint(-10, 10), P, (1.0, 0.75, 0.35), glow=1)
    for k in range(12):                                                             # círculo de piedras y ceniza
        a = k / 12 * math.tau
        cx, cz = 30 * math.cos(a), 30 * math.sin(a)
        for x in range(int(cx) - 5, int(cx) + 6):
            for z in range(int(cz) - 5, int(cz) + 6):
                for y in range(0, 6):
                    if (x - cx) ** 2 + (z - cz) ** 2 + ((y - 1) * 1.6) ** 2 < 26: M.put(x, y, z, P, (0.30, 0.29, 0.27) if M.hsh(x, y, z) > 0.3 else (0.20, 0.19, 0.18))
    for x in range(-26, 27):
        for z in range(-26, 27):
            if 12 < math.hypot(x, z) < 25 and M.noise(x, 0, z, 4.0) > 0.4: M.put(x, 0, z, P, (0.22, 0.21, 0.20), over=False)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0], 'light': [0, H + 30, 0]}


def piragua():
    """Piragua del bayou (rehecha a 64/m en la revisión de arte del 13-10-2026): canoa vaciada en
    un tronco de ciprés, de 3 m, con la proa y la popa afiladas y levantadas, borda gastada, dos
    bancadas, agua sucia y hojas en el fondo, un remo de pala ancha cruzado, una nasa y un rollo
    de cuerda dentro, musgo y barro en el casco, y medio varada en el barro con un cabo a una
    estaca."""
    M = Model(S=4, seed=96)
    L, W, H = 96, 18, 22
    for x in range(-L, L):
        f = abs(x) / L
        w = W * math.sqrt(max(0.0, 1 - f ** 2.4))
        lift = int(10 * max(0.0, f - 0.7) / 0.3 * max(0.0, f - 0.7) / 0.3)
        if w < 1.5: continue
        for z in range(-int(w) - 1, int(w) + 2):
            for y in range(0, H + lift + 1):
                u = z / max(w, 1)
                bottom = int((1 - math.sqrt(max(0.0, 1 - u * u))) * H * 0.9) + lift // 2
                if y < bottom or abs(u) > 1: continue
                inner = abs(u) < 1 - 3.0 / max(w, 1) and y > bottom + 2
                if inner and y < H + lift: continue
                c = LOG if int(y + abs(z) * 0.3 + x * 0.05) % 4 else LOG_D
                c = lerp(c, BARK_D, 0.3 * M.noise(x, y, z, 5.0))
                if y >= H + lift - 1: c = lerp(c, (0.56, 0.44, 0.30), 0.4)                 # borda gastada
                if y < bottom + 4 and abs(u) > 0.8: c = lerp(c, (0.24, 0.30, 0.16), 0.5)   # musgo y barro
                M.put(x, y, z, P, c)
    for x in range(-L + 24, L - 24):                                                 # agua sucia en el fondo
        for z in range(-12, 13):
            w = W * math.sqrt(max(0.0, 1 - (abs(x) / L) ** 2.4))
            if abs(z) < w - 5: M.put(x, 6, z, P, (0.16, 0.20, 0.14) if M.hsh(x, z, 1) > 0.04 else (0.40, 0.30, 0.16))
    for bx in (-40, 34):                                                             # bancadas
        for x in range(bx - 4, bx + 4):
            for z in range(-W + 2, W - 1): M.put(x, H - 4, z, P, PLANK if (x + z) % 7 else PLANK_D)
    for k in range(120):                                                             # remo de pala ancha cruzado
        x = -60 + k; z = -8 + k // 10; y = H - 2 + (1 if k > 80 else 0)
        M.put(x, y, z, P, PLANK); M.put(x, y, z + 1, P, PLANK)
        if k > 92:
            for dz in range(-4, 6): M.put(x, y, z + dz, P, PLANK if dz % 3 else PLANK_D)
    for a in range(0, 540, 6):                                                       # rollo de cuerda
        r = 4 + a / 180
        M.put(int(56 + r * math.cos(math.radians(a))), 8 + a // 360, int(r * math.sin(math.radians(a))), P, (0.56, 0.48, 0.32))
    for x in range(-74, -54):                                                        # nasa pequeña
        for y in range(7, 19):
            for z in range(-9, 10):
                if abs(math.hypot(y - 7, z) - 9) < 0.8 and (x % 4 == 0 or (y + z) % 3 == 0): M.put(x, y, z, P, (0.50, 0.46, 0.34))
    for x in range(-150, 150):                                                       # barro donde está varada
        for z in range(-40, 40):
            if (x / 140) ** 2 + (z / 36) ** 2 < 1 and M.noise(x, 0, z, 12.0) > 0.35: M.put(x, 0, z, P, (0.22, 0.18, 0.12), over=False)
    for k in range(70):                                                              # cabo a una estaca
        M.put(L + k, max(1, 18 - k // 3), k // 6, P, (0.56, 0.48, 0.32))
    for y in range(0, 26):
        for dx in (0, 1):
            for dz in (0, 1): M.put(L + 70 + dx, y, 11 + dz, P, LOG_D)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


PIECES = {'hoguera': hoguera, 'monolito': monolito, 'cipres': cipres, 'cipres_2': lambda: cipres(2), 'choza': choza, 'poste': poste,
          'piragua': piragua}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/lui_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.85, specular=0.3, no_bottom=True)
        print('lui_%s: %d voxels' % (name, n))
