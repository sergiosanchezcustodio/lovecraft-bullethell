"""Atrezo de Sentinel Hill (hito 21.14, «El horror de Dunwich»). Una parte "body", origen en el centro de
la base, la cara principal hacia +Z (como gen_atrezo_granja.py). Las colinas de Dunwich: bosque oscuro
de abetos y robles retorcidos, piedra gris con líquenes, y en la cima el círculo de menhires con su
altar, donde el viejo Whateley encendía sus hogueras.

  abeto_1/2        abeto del Canadá, oscuro, en pisos de ramas que se doblan (16/m)
  roble            roble retorcido, tronco grueso y unas matas de hojas oscuras (16/m)
  menhir_1/2/3     menhir de granito gris con líquenes y musgo al pie (32/m)
  altar            la piedra del altar: una losa sobre dos piedras, con manchas viejas y ceniza (32/m)
  roca             peña de granito con musgo, sin nieve (32/m)
  arbol_partido    tocón astillado y el tronco caído al lado: por aquí ha pasado algo enorme (32/m)
  arbusto          mata baja y oscura (32/m; se rompe)
  pulverizador     el pulverizador de latón con el polvo de Ibn Ghazi, como el de Armitage (32/m)

Escribe models/dun_<pieza>.json. Uso: python tools/gen_atrezo_dunwich.py [piezas...]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
BARK = (0.24, 0.21, 0.18); BARK_D = (0.14, 0.12, 0.11); BARK_L = (0.34, 0.31, 0.27)
NEEDLE_D = (0.07, 0.12, 0.10); NEEDLE = (0.11, 0.18, 0.14); NEEDLE_L = (0.19, 0.27, 0.20)
LEAF_D = (0.10, 0.12, 0.07); LEAF = (0.17, 0.20, 0.10); LEAF_L = (0.26, 0.28, 0.14)
GRANITE = (0.40, 0.40, 0.40); GRANITE_D = (0.27, 0.27, 0.28); GRANITE_L = (0.52, 0.51, 0.50)
LICHEN_O = (0.50, 0.42, 0.25); LICHEN_G = (0.46, 0.50, 0.42)
MOSS = (0.20, 0.27, 0.13); MOSS_D = (0.13, 0.18, 0.09)
STAIN = (0.20, 0.10, 0.08); ASH = (0.16, 0.15, 0.15)
SPLINTER = (0.68, 0.58, 0.40); SPLINTER_D = (0.50, 0.42, 0.29)
BRASS = (0.58, 0.45, 0.22); BRASS_D = (0.34, 0.26, 0.13); BRASS_L = (0.76, 0.62, 0.36)
VERDIGRIS = (0.30, 0.46, 0.40)
WOOD = (0.36, 0.25, 0.15)
POWDER = (0.86, 0.83, 0.70)


def ball(M, c, r, col, shell=0.0, glow=0):
    """Bola de centro c y radio r; con `shell`, solo la corteza de ese grosor."""
    ri = int(math.ceil(r))
    for x in range(-ri, ri + 1):
        for y in range(-ri, ri + 1):
            for z in range(-ri, ri + 1):
                d = math.sqrt(x * x + y * y + z * z)
                if d > r or (shell and d < r - shell): continue
                q = (int(c[0] + x), int(c[1] + y), int(c[2] + z))
                M.put(*q, P, col(*q) if callable(col) else col, glow)


def tube(M, a, b, r, col, shell=0.0):
    """Cilindro de a a b (voxels) de radio r, entero o solo su corteza."""
    n = int(max(abs(b[i] - a[i]) for i in range(3))) + 1
    ri = int(math.ceil(r(0.0) if callable(r) else r))
    for k in range(n + 1):
        t = k / max(n, 1)
        cx, cy, cz = (a[i] + (b[i] - a[i]) * t for i in range(3))
        rr = r(t) if callable(r) else r
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    d2 = x * x + y * y + z * z
                    if d2 > rr * rr + 0.3 or (shell and d2 < (rr - shell) ** 2): continue
                    q = (int(round(cx + x)), int(round(cy + y)), int(round(cz + z)))
                    M.put(*q, P, col(*q) if callable(col) else col)


def bark_of(M):
    def f(x, y, z):
        c = lerp(BARK_D, BARK, 0.35 + 0.6 * M.noise(x, y * 0.4, z, 3.0))
        if M.noise(x + 40, y * 0.25, z, 2.0) > 0.72: c = lerp(c, BARK_D, 0.7)          # surcos
        elif M.hsh(x, y, z) < 0.04: c = BARK_L
        return c
    return f


# ---------------- árboles ----------------

def abeto(seed, H, R):
    """Abeto del Canadá de 16/m: tronco recto y oscuro y pisos de ramas que caen, cada uno más
    estrecho que el de abajo, con el borde desigual y las puntas más claras; solo la corteza de
    cada piso (por dentro no se ve)."""
    M = Model(S=1, seed=seed)
    rng = M.rng
    bark = bark_of(M)
    for y in range(0, H - 6):
        r = 2.6 if y > 10 else 2.6 + (10 - y) * 0.25
        for x in range(-4, 5):
            for z in range(-4, 5):
                if x * x + z * z <= r * r: M.put(x, y, z, P, bark(x, y, z))
    base = 16
    tiers = []
    y = base
    while y < H:
        h = rng.randint(10, 13)
        tiers.append((y, h))
        y += h - 3
    for i, (y0, h) in enumerate(tiers):
        k = i / max(len(tiers) - 1, 1)
        rt = R * (1.0 - k) ** 0.85 + 3.0
        for dy in range(h):
            yy = y0 + dy
            if yy > H: break
            t = dy / h
            r = rt * (1.0 - 0.55 * t) + (1.5 if dy == 0 else 0.0)
            ri = int(r) + 3
            for x in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    a = math.atan2(z, x)
                    edge = r * (0.82 + 0.28 * M.noise(math.cos(a) * 3 + i * 7, yy * 0.2, math.sin(a) * 3, 1.0))
                    d = math.sqrt(x * x + z * z)
                    if d > edge or d < edge - 3.5: continue
                    if dy == 0 and M.hsh(x, yy, z) < 0.35: continue                          # flecos por debajo
                    c = lerp(NEEDLE_D, NEEDLE, M.noise(x, yy, z, 2.5))
                    if d > edge - 1.2 and t < 0.5: c = lerp(c, NEEDLE_L, 0.6 * (1 - t * 2))   # puntas claras
                    if M.hsh(x // 2, yy, z // 2) < 0.06: c = NEEDLE_D
                    M.put(x, yy, z, P, c)
    for yy in range(H, H + 6):                                                           # la guía
        M.put(0, yy, 0, P, NEEDLE)
    return M, {P: [0, 0, 0]}


def abeto_1(): return abeto(2141, 104, 30)
def abeto_2(): return abeto(2142, 84, 25)


def roble():
    """Roble retorcido de 16/m: tronco grueso que se tuerce, tres ramas gruesas que se abren y unas
    matas de hojas oscuras con huecos por donde se ve el ramaje."""
    M = Model(S=1, seed=2143)
    rng = M.rng
    bark = bark_of(M)
    for k in range(5):                                                               # raíces
        a = k / 5 * math.tau + rng.uniform(-0.3, 0.3)
        tube(M, (0, 4, 0), (math.cos(a) * 9, -1, math.sin(a) * 9), 2.2, bark)
    pts = [(0.0, 0.0, 0.0)]
    x = z = 0.0
    for y in range(7, 30, 7):
        x += rng.uniform(-3.0, 3.0); z += rng.uniform(-3.0, 3.0)
        pts.append((x, y, z))
    for i in range(1, len(pts)):
        tube(M, pts[i - 1], pts[i], 6.5 - 2.0 * i / len(pts), bark)
    top = pts[-1]
    tips = []
    for k in range(5):
        a = k / 5 * math.tau + rng.uniform(-0.4, 0.4)
        L = rng.uniform(28, 36)
        mid = (top[0] + math.cos(a) * L * 0.5, top[1] + L * 0.25, top[2] + math.sin(a) * L * 0.5)
        end = (top[0] + math.cos(a) * L, top[1] + L * 0.35 + rng.uniform(-3, 4), top[2] + math.sin(a) * L)
        tube(M, top, mid, 3.4, bark)
        tube(M, mid, end, 2.2, bark)
        tips.append(end); tips.append(mid)
    tips.append((top[0], top[1] + 16, top[2]))
    for k in range(9):                                                               # que la copa no quede a bolas
        a = rng.uniform(0, math.tau); d = rng.uniform(8, 26)
        tips.append((top[0] + math.cos(a) * d, top[1] + rng.uniform(8, 15), top[2] + math.sin(a) * d))
    for t in tips:
        r = rng.uniform(10, 14)
        def leaf(x, y, z):
            c = lerp(LEAF_D, LEAF, M.noise(x, y, z, 3.0))
            if y > t[1] + r * 0.4 and M.hsh(x, y, z) < 0.3: c = LEAF_L
            return c
        ri = int(r)
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    d = math.sqrt(x * x + (y * 1.35) ** 2 + z * z)
                    if d > r or d < r - 3: continue
                    q = (int(t[0] + x), int(t[1] + y), int(t[2] + z))
                    if M.noise(q[0], q[1], q[2], 2.0) < 0.3: continue                    # huecos
                    M.put(*q, P, leaf(*q))
    return M, {P: [0, 0, 0]}


# ---------------- piedra ----------------

def menhir(seed, H, W, D, lean):
    """Menhir de 32/m: una losa de granito que se estrecha hacia arriba, con la cabeza desigual, un
    poco inclinada, con líquenes naranjas y verdes y musgo al pie. Hueco por dentro."""
    M = Model(S=2, seed=seed)
    top = [H - int(12 * (abs(i) / W) ** 2) - int(5 * M.noise(i // 5, 0, 0, 1.0)) for i in range(-W, W + 1)]
    for y in range(0, H + 1):
        k = y / H
        w = W * (1.0 - 0.28 * k) * (1.0 + 0.06 * math.sin(y * 0.15))
        d = D * (1.0 - 0.2 * k)
        ox = lean * y
        for x in range(-W - 4, W + 5):
            if y > top[min(max(x + W, 0), 2 * W)]: continue
            for z in range(-D - 2, D + 3):
                u = (x - ox) / w
                v = z / d
                s = abs(u) ** 3 + abs(v) ** 3
                if s > 1.0: continue
                inner = abs(u) ** 3 + abs(v) ** 3 < 0.55 and 3 < y < top[min(max(x + W, 0), 2 * W)] - 3
                if inner: continue
                c = lerp(GRANITE_D, GRANITE, 0.3 + 0.6 * M.noise(x, y * 0.6, z, 4.0))
                if M.hsh(x, y, z) < 0.05: c = GRANITE_L
                n = M.noise(x + 30, y, z, 3.0)
                if n > 0.82: c = lerp(c, LICHEN_O, 0.5)
                elif n < 0.16 and y > 20: c = lerp(c, LICHEN_G, 0.45)
                if y < 6 and M.noise(x, y, z + 9, 2.5) > 0.55 - y * 0.03: c = lerp(MOSS_D, MOSS, M.hsh(x, y, z))
                M.put(x, y, z, P, c)
    for x in range(-W - 8, W + 9):                                                   # musgo plano al pie
        for z in range(-D - 8, D + 9):
            if abs(x) <= W and abs(z) <= D: continue
            if M.noise(x, 0, z, 2.0) > 0.5 and (x / (W + 8)) ** 2 + (z / (D + 8)) ** 2 < 1.0:
                M.put(x, 0, z, P, lerp(MOSS_D, MOSS, M.hsh(x, 0, z)))
    return M, {P: [0, 0, 0]}


def menhir_1(): return menhir(2144, 92, 16, 9, 0.04)
def menhir_2(): return menhir(2145, 76, 19, 10, -0.06)
def menhir_3(): return menhir(2146, 64, 14, 11, 0.09)


def altar():
    """La piedra del altar: una losa de 2,4 × 1,4 m sobre dos piedras, con la mancha vieja en medio,
    ceniza alrededor y unos restos de cera."""
    M = Model(S=2, seed=2147)
    TOPY = 28
    for sx in (-24, 24):                                                             # las dos piedras
        for y in range(0, TOPY - 10):
            for x in range(sx - 9, sx + 10):
                for z in range(-16, 17):
                    if abs(x - sx) ** 3 / 9 ** 3 + abs(z) ** 3 / 16 ** 3 > 1.0: continue
                    if abs(x - sx) < 6 and abs(z) < 12 and 2 < y < TOPY - 13: continue
                    c = lerp(GRANITE_D, GRANITE, M.noise(x, y, z, 3.0))
                    if y < 6 and M.noise(x, y, z, 2.0) > 0.5: c = MOSS
                    M.put(x, y, z, P, c)
    for y in range(TOPY - 10, TOPY):                                                 # la losa
        for x in range(-38, 39):
            for z in range(-22, 23):
                if abs(x) ** 4 / 38 ** 4 + abs(z) ** 4 / 22 ** 4 > 1.0: continue
                if y < TOPY - 2 and abs(x) < 34 and abs(z) < 18 and y > TOPY - 8: continue
                if y == TOPY - 1 and M.noise(x, 0, z, 1.5) > 0.8: continue                 # desconchones
                c = lerp(GRANITE_D, GRANITE, 0.3 + 0.6 * M.noise(x, y, z, 4.0))
                if y >= TOPY - 2:
                    d = math.sqrt((x * 0.8) ** 2 + z * z)
                    if d < 12 + 5 * M.noise(x, 0, z, 2.0): c = lerp(STAIN, c, 0.25 * d / 17)
                    elif M.noise(x + 20, 0, z, 3.0) > 0.8: c = lerp(c, LICHEN_O, 0.45)
                M.put(x, y, z, P, c)
    for k, (x, z) in enumerate(((-30, 15), (31, -14), (28, 16))):                  # cabos de vela
        for y in range(TOPY, TOPY + 3 + k % 2):
            M.put(x, y, z, P, (0.70, 0.66, 0.55)); M.put(x + 1, y, z, P, (0.66, 0.62, 0.52))
    for k in range(90):                                                              # ceniza y carbón alrededor
        a = M.rng.uniform(0, math.tau); r = M.rng.uniform(42, 60)
        x, z = int(math.cos(a) * r), int(math.sin(a) * r * 0.75)
        M.put(x, 0, z, P, ASH if k % 3 else (0.08, 0.07, 0.07))
    return M, {P: [0, 0, 0]}


def roca():
    """Peña de granito de 1,6 m con grietas, líquenes y musgo por arriba."""
    M = Model(S=2, seed=2148)
    for x in range(-28, 29):
        for z in range(-22, 23):
            for y in range(0, 36):
                u, v, w = x / 26, (y - 4) / 30, z / 21
                d = u * u + max(v, 0) ** 2 * 1.2 + w * w + 0.25 * (M.noise(x, y, z, 6.0) - 0.5)
                if d > 1.0 or (d < 0.72 and y > 2): continue
                c = lerp(GRANITE_D, GRANITE, 0.3 + 0.6 * M.noise(x, y, z, 5.0))
                if M.noise(x + 11, y * 2, z, 2.0) > 0.78: c = lerp(c, GRANITE_D, 0.8)
                if y > 18 and M.noise(x, y, z + 5, 3.0) > 0.45: c = lerp(MOSS_D, MOSS, M.hsh(x, y, z))
                elif M.noise(x + 50, y, z, 3.0) > 0.84: c = lerp(c, LICHEN_O, 0.45)
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


# ---------------- el paso del horror ----------------

def arbol_partido():
    """Un árbol grueso partido a 1,5 m: el tocón con astillas claras que apuntan arriba y, tendido a
    lo largo de +x, el tronco con dos ramas rotas. Por aquí ha pasado algo enorme."""
    M = Model(S=2, seed=2149)
    bark = bark_of(M)
    R = 10
    for y in range(0, 62):
        for x in range(-R - 1, R + 2):
            for z in range(-R - 1, R + 2):
                d = math.sqrt(x * x + z * z)
                r = R + (3 - y) * 0.8 if y < 4 else R
                if d > r: continue
                a = math.atan2(z, x)
                cut = 40 + 18 * abs(math.sin(a * 3.0 + 1.0)) + 6 * M.noise(x, 0, z, 1.0)
                if y > cut: continue
                inner = d < R - 2.5
                if inner and y < cut - 4: continue
                c = bark(x, y, z) if not inner and d > R - 2.5 else lerp(SPLINTER_D, SPLINTER, M.hsh(x, y, z))
                if y > cut - 4: c = lerp(SPLINTER_D, SPLINTER, M.hsh(x, y, z))
                M.put(x, y, z, P, c)
    tube(M, (16, 9, 4), (120, 7, 18), lambda t: 9.0 - 3.5 * t, bark, shell=3.0)     # el tronco caído
    for x in range(10, 18):                                                          # astillas del extremo
        for k in range(6):
            M.put(x, 5 + k * 2, 2 + k % 3, P, SPLINTER)
    tube(M, (60, 12, 12), (74, 34, -6), 2.5, bark)                                  # ramas rotas
    tube(M, (95, 10, 15), (108, 4, 40), 2.0, bark)
    for x in range(-6, 8):                                                           # terrones levantados
        for z in range(10, 18):
            if M.hsh(x, 0, z) < 0.6: M.put(x, 0, z, P, (0.22, 0.18, 0.13))
    return M, {P: [0, 0, 0]}


def arbusto():
    """Mata baja de 0,8 m: unas bolas de hojas oscuras con ramitas que asoman."""
    M = Model(S=2, seed=2150)
    rng = M.rng
    for k in range(6):
        a = k / 6 * math.tau + rng.uniform(-0.4, 0.4)
        c = (math.cos(a) * rng.uniform(5, 12), rng.uniform(9, 16), math.sin(a) * rng.uniform(5, 12))
        r = rng.uniform(8, 11)
        ball(M, c, r, lambda x, y, z: lerp(LEAF_D, LEAF, M.noise(x, y, z, 3.0)) if M.hsh(x, y, z) > 0.08 else LEAF_L, shell=3)
    for k in range(5):
        a = rng.uniform(0, math.tau)
        tube(M, (0, 0, 0), (math.cos(a) * 16, rng.uniform(18, 26), math.sin(a) * 16), 0.8, BARK)
    return M, {P: [0, 0, 0]}


def pulverizador():
    """El pulverizador de latón (de los de fumigar árboles) con el polvo de Ibn Ghazi: depósito con
    remaches y aros, la bomba con su mango de madera, la manguera hasta la boquilla en el suelo y un
    poco de polvo derramado que brilla apenas."""
    M = Model(S=2, seed=2151)
    for y in range(2, 22):
        for x in range(-7, 8):
            for z in range(-7, 8):
                d = math.sqrt(x * x + z * z)
                if d > 6.5 or (d < 4.5 and 3 < y < 20): continue
                c = lerp(BRASS_D, BRASS, 0.5 + 0.5 * math.cos(math.atan2(z, x) - 0.8))
                if y in (5, 16): c = BRASS_D                                          # aros
                elif (y in (7, 14)) and M.hsh(x, y, z) < 0.25: c = BRASS_L                 # remaches
                elif M.noise(x, y, z, 2.5) > 0.7: c = lerp(c, VERDIGRIS, 0.6)              # verdín
                M.put(x, y, z, P, c)
    for x in range(-5, 6):                                                           # la tapa
        for z in range(-5, 6):
            if x * x + z * z <= 25: M.put(x, 22, z, P, BRASS_L if x * x + z * z < 9 else BRASS)
    for y in range(23, 33): M.put(0, y, 0, P, (0.25, 0.24, 0.23))                     # la bomba
    for x in range(-6, 7):
        M.put(x, 33, 0, P, WOOD); M.put(x, 34, 0, P, WOOD)
    for y in range(0, 2):                                                            # las patas
        for x, z in ((-5, -5), (5, -5), (-5, 5), (5, 5)): M.put(x, y, z, P, BRASS_D)
    pts = [(6, 4, 0), (11, 2, 3), (14, 1, 8), (13, 1, 13), (9, 1, 16)]               # la manguera
    for a, b in zip(pts, pts[1:]): tube(M, a, b, 0.9, (0.16, 0.14, 0.12))
    for k in range(4): M.put(9 - k, 1, 17 + k, P, BRASS_L)                            # la boquilla
    for k in range(70):                                                              # el polvo derramado
        a = M.rng.uniform(0, math.tau); r = M.rng.uniform(0, 8)
        x, z = int(4 + math.cos(a) * r), int(19 + math.sin(a) * r * 0.7)
        M.put(x, 0, z, P, POWDER, 1 if k % 6 == 0 else 0)
    return M, {P: [0, 0, 0]}


PIECES = {'abeto_1': abeto_1, 'abeto_2': abeto_2, 'roble': roble, 'menhir_1': menhir_1, 'menhir_2': menhir_2,
          'menhir_3': menhir_3, 'altar': altar, 'roca': roca, 'arbol_partido': arbol_partido, 'arbusto': arbusto,
          'pulverizador': pulverizador}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    here = os.path.join(os.path.dirname(__file__), '..')
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export(os.path.join(here, 'models', 'dun_%s.json' % name), piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('dun_%s: %d voxels' % (name, n))
