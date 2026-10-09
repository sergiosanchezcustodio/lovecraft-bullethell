"""Atrezo de la expedición, más detallado (30-09-2026, referencias del autor), a 48 voxels
por metro como los personajes: tienda de lona, caja, barril, trineo, trípode con teodolito y
bandera. Sustituye a la tienda, la caja y el bidón de gen_atrezo_campamento.py.

Coordenadas en voxels (1/48 m), una sola parte "body", origen en el centro de la base.
Escribe models/atrezo_{tienda,caja,bidon,trineo,tripode,bandera}.json.
Uso: python tools/gen_atrezo_expedicion.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale

P = 'body'
SNOW = (0.90, 0.93, 0.97); SNOW_SH = (0.80, 0.85, 0.92)
CANVAS = (0.72, 0.67, 0.55); CANVAS_D = (0.60, 0.55, 0.44); CANVAS_DIRT = (0.50, 0.45, 0.36)
SEAM = (0.52, 0.47, 0.37)
DOOR = (0.10, 0.08, 0.07)
ROPE = (0.60, 0.53, 0.40)
WOOD = (0.47, 0.34, 0.21); WOOD_D = (0.28, 0.19, 0.11); WOOD_L = (0.58, 0.44, 0.28); GROOVE = (0.20, 0.13, 0.08)
IRON = (0.22, 0.22, 0.24); IRON_L = (0.40, 0.40, 0.42)
BRASS = (0.72, 0.56, 0.26)
STENCIL = (0.13, 0.10, 0.08)
RED = (0.66, 0.16, 0.16); WHITE = (0.90, 0.88, 0.84); BLUE = (0.16, 0.22, 0.44)


def snow_on_top(M, prob=0.9, depth=1, min_y=0, patch=None):
    """Una capa de nieve sobre lo más alto de cada columna."""
    cols = {}
    for (x, y, z) in M.V:
        if y > cols.get((x, z), -99): cols[(x, z)] = y
    for (x, z), y in cols.items():
        if y < min_y: continue
        if patch is not None and not patch(x, y, z): continue
        if M.hsh(x, y, z) > prob: continue
        for d in range(depth):
            M.put(x, y + 1 + d, z, P, SNOW if M.hsh(x, 5, z) > 0.3 else SNOW_SH, over=False)


def drift(M, inside, reach, height):
    """Nieve amontonada al pie: para cada punto del suelo cerca de la pieza (inside(x, z) da
    la distancia al borde en voxels, <= 0 dentro), un montoncito que baja con la distancia."""
    for x in range(-150, 150):
        for z in range(-150, 150):
            d = inside(x, z)
            if d is None or d <= 0 or d >= reach: continue
            h = height * (1 - d / reach) * (0.7 + 0.6 * M.noise(x * 0.15, 0, z * 0.15, 2.0))
            for y in range(0, max(0, int(round(h)))):
                M.put(x, y, z, P, SNOW if M.hsh(x, y, z) > 0.25 else SNOW_SH, over=False)


# ---------------- tienda ----------------

def tienda():
    """Tienda de expedición de lona cruda: cumbrera a lo largo de X (3 m), paredes bajas,
    faldones que ceden entre los postes, costuras, faldón en el suelo, puerta en el extremo
    +X con las solapas recogidas, vientos con estacas y nieve en el tejado y al pie."""
    M = Model(S=3, seed=21)
    HX, HZ, WALL, RIDGE = 72, 56, 22, 96
    POLES = (-72, -24, 24, 72)                            # la lona cede entre los postes
    def sag(x):
        for a, b in zip(POLES, POLES[1:]):
            if a <= x <= b: return 3.0 * math.sin(math.pi * (x - a) / (b - a))
        return 0.0
    def canvas(x, y, z):
        n = M.noise(x * 0.08, y * 0.08, z * 0.08, 1.0)
        c = lerp(CANVAS_D, CANVAS, 0.55 + 0.45 * n)
        if (x + HX) % 16 in (0,): c = SEAM                  # costuras de los paños
        if y < 8: c = lerp(c, CANVAS_DIRT, 0.5 * (1 - y / 8))
        return c
    for x in range(-HX, HX):
        s = sag(x)
        # paredes
        for y in range(0, WALL):
            for zs in (-1, 1):
                for t in range(2):
                    z = zs * (HZ - t) - (1 if zs > 0 else 0)
                    M.put(x, y, z, P, canvas(x, y, z))
        # faldones: de la pared a la cumbrera, algo hundidos en medio de cada paño
        for y in range(WALL, RIDGE + 1):
            f = (y - WALL) / (RIDGE - WALL)
            ze = HZ * (1 - f) - s * math.sin(math.pi * f)
            for zs in (-1, 1):
                for t in range(2):
                    z = int(round(zs * (ze - t))) - (1 if zs > 0 else 0)
                    c = canvas(x, y, z)
                    if y == WALL: c = SEAM
                    M.put(x, y, z, P, c)
    # extremos: pentágono (pared + triángulo), 2 de grosor
    for xe in (-HX - 1, -HX, HX - 1, HX):
        for y in range(0, RIDGE):
            ze = HZ if y < WALL else HZ * (1 - (y - WALL) / (RIDGE - WALL))
            for z in range(-int(ze), int(ze)):
                M.put(xe, y, z, P, canvas(xe, y, z), over=False)
    # puerta en el extremo +X: vano oscuro y solapas recogidas a los lados
    for y in range(0, 70):
        half = 16 * (1 - y / 76)
        for z in range(-int(half) - 1, int(half) + 1):
            if abs(z + 0.5) > half: continue
            for xe in (HX - 1, HX):
                if (xe, y, z) in M.V: M.V[(xe, y, z)][1] = DOOR
        for zs in (-1, 1):                                  # solapas enrolladas
            z = int(zs * (half + 2)) - (1 if zs > 0 else 0)
            if y < 60:
                for dz in range(3):
                    M.put(HX + 1, y, z + zs * dz, P, CANVAS_D if (y // 6) % 2 else CANVAS)
    for y in (30, 46):                                     # cintas de las solapas
        for zs in (-1, 1):
            z = int(zs * (16 * (1 - y / 76) + 3))
            for dz in range(-1, 3): M.put(HX + 2, y, z + dz, P, ROPE)
    # cumbrera que asoma por los dos extremos
    for x in range(-HX - 6, HX + 6):
        for y in (RIDGE, RIDGE + 1):
            for z in (-1, 0):
                if x < -HX or x >= HX or y == RIDGE + 1: M.put(x, y, z, P, WOOD_D)
    # vientos: de los postes al suelo, con estaca
    def rope(a, b):
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]), abs(b[2] - a[2])))
        for i in range(n + 1):
            t = i / n
            p = [a[k] + (b[k] - a[k]) * t for k in range(3)]
            p[1] -= 3 * math.sin(math.pi * t)               # la cuerda cae un poco
            M.put(int(round(p[0])), int(round(p[1])), int(round(p[2])), P, ROPE)
    for x in POLES:
        xx = max(-HX + 2, min(HX - 3, x))
        for zs in (-1, 1):
            a = (xx, WALL + 14, zs * (HZ - 10))
            b = (xx + (6 if x > 0 else -6), 1, zs * (HZ + 44))
            rope(a, b)
            for y in range(0, 6):
                for dx in (0, 1):
                    for dz in (0, 1): M.put(int(b[0]) + dx, y, int(b[2]) + dz, P, WOOD_D)
    for xs in (-1, 1):                                      # vientos de la cumbrera
        a = (xs * (HX + 5), RIDGE, 0)
        b = (xs * (HX + 48), 1, 0)
        rope(a, b)
        for y in range(0, 6):
            for dx in (0, 1):
                for dz in (0, 1): M.put(int(b[0]) + dx, y, dz, P, WOOD_D)
    # faldón en el suelo alrededor de la base
    for x in range(-HX - 3, HX + 3):
        for z in range(-HZ - 4, HZ + 4):
            if abs(x + 0.5) < HX and abs(z + 0.5) < HZ: continue
            if x >= HX - 1 and abs(z + 0.5) < 18: continue      # delante de la puerta
            M.put(x, 0, z, P, CANVAS_DIRT, over=False)
    # nieve: en el tejado a manchas (más cerca de la cumbrera) y al pie
    snow_on_top(M, prob=0.97, depth=2, min_y=WALL + 6,
                patch=lambda x, y, z: M.noise(x * 0.05, 0, z * 0.08, 4.0) > 0.12 + 0.45 * (1 - (y - WALL) / (RIDGE - WALL)))
    def inside(x, z):
        if x >= HX and abs(z + 0.5) < 20: return None       # la entrada, pisada
        return max(abs(x + 0.5) - HX - 3, abs(z + 0.5) - HZ - 4)
    drift(M, inside, 14, 7)
    return M


# ---------------- caja ----------------

LETTERS = {'M': ["1...1", "11.11", "1.1.1", "1...1", "1...1"], 'U': ["1...1", "1...1", "1...1", "1...1", ".111."],
           '.': [".....", ".....", ".....", ".....", "..1.."]}

def caja():
    """Caja de madera de la Universidad de Miskatonic: tablas con juntas hundidas, listones en
    las aristas, clavos, asas de cuerda, estarcido "M.U." y nieve encima."""
    M = Model(S=3, seed=22)
    HX, HY, HZ = 18, 27, 14
    for x in range(-HX, HX):
        for y in range(0, HY):
            for z in range(-HZ, HZ):
                ex = min(x + HX, HX - 1 - x); ez = min(z + HZ, HZ - 1 - z); ey = min(y, HY - 1 - y)
                if min(ex, ez, ey) > 1: continue                  # solo la cáscara
                plank = y // 6
                c = lerp(WOOD_D, WOOD_L, 0.25 + 0.6 * M.hsh(plank, x // 40, z // 40))
                c = lerp(c, WOOD_D, 0.25 * M.noise(x * 0.3, y * 1.5, z * 0.3, 1.0) + 0.1)
                groove = y % 6 == 0 and y > 0
                frame = (ex <= 2) + (ez <= 2) + (ey <= 2) >= 2
                if groove and not frame:
                    if min(ex, ez) == 0: continue                 # junta hundida 1 voxel
                    c = GROOVE
                if frame: c = lerp(WOOD_L, WOOD, 0.5 + 0.3 * M.hsh(x, y, z))
                M.put(x, y, z, P, c)
    # listones de las aristas que sobresalen 1 voxel
    for x in range(-HX - 1, HX + 1):
        for y in range(-0, HY + 1):
            for z in range(-HZ - 1, HZ + 1):
                ex = min(x + HX + 1, HX - x); ez = min(z + HZ + 1, HZ - z); ey = min(y, HY - y)
                if (x, y, z) in M.V: continue
                if (ex == 0) + (ez == 0) + (ey == 0) >= 1 and (ex <= 3) + (ez <= 3) + (ey <= 3) >= 2:
                    M.put(x, y, z, P, lerp(WOOD_L, WOOD, 0.4))
    for x in (-HX + 2, HX - 3):                                  # clavos
        for y in (3, 13, 23):
            M.put(x, y, HZ, P, IRON_L)
    zf = HZ
    for li, ch in enumerate("M.U."):                              # estarcido
        for row, line in enumerate(LETTERS[ch]):
            for col, px in enumerate(line):
                if px == '1':
                    x = -11 + li * 6 + col; y = 18 - row
                    M.put(x, y, zf - 0, P, STENCIL)
    for xs in (-1, 1):                                            # asas de cuerda
        x = xs * (HX + 1) - (1 if xs > 0 else 0) + (0 if xs > 0 else 0)
        for z in range(-5, 5):
            M.put(x + xs, 17 if abs(z + 0.5) < 4 else 18, z, P, ROPE)
    snow_on_top(M, prob=1.0, depth=2, min_y=HY - 1, patch=lambda x, y, z: M.noise(x * 0.12, 0, z * 0.12, 5.0) > -0.35)
    return M


# ---------------- barril ----------------

def bidon():
    """Barril de duelas con tres aros de hierro, tapa y nieve."""
    M = Model(S=3, seed=23)
    H, R = 44, 12.5
    for y in range(0, H):
        t = (y + 0.5) / H
        r = R + 1.6 * math.sin(math.pi * t)                        # panza
        for x in range(-16, 16):
            for z in range(-16, 16):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r or (d < r - 2.2 and 1 < y < H - 2): continue
                a = math.atan2(z + 0.5, x + 0.5)
                stave = int((a + math.pi) / (2 * math.pi) * 18)
                c = lerp(WOOD_D, WOOD_L, 0.25 + 0.55 * M.hsh(stave, 0, 0))
                if ((a + math.pi) / (2 * math.pi) * 18) % 1 < 0.08: c = GROOVE
                if y >= H - 2 and d < r - 2: c = lerp(WOOD, WOOD_D, 0.4 + 0.3 * M.hsh(x // 3, 0, 0))
                M.put(x, y, z, P, c)
    for yh in (4, 21, 38):                                         # aros
        t = (yh + 1.5) / H
        r = R + 1.6 * math.sin(math.pi * t) + 1
        for y in range(yh, yh + 3):
            for x in range(-17, 17):
                for z in range(-17, 17):
                    d = math.hypot(x + 0.5, z + 0.5)
                    if r - 1.5 < d <= r: M.put(x, y, z, P, IRON if y != yh + 1 else IRON_L)
    snow_on_top(M, prob=0.9, depth=2, min_y=H - 3)
    return M


# ---------------- trineo ----------------

def trineo():
    """Trineo de expedición (tipo Nansen): patines que se curvan delante, montantes, plataforma
    de listones, y encima una caja y un fardo de lona atados con cuerdas."""
    M = Model(S=3, seed=24)
    L, W = 58, 16                                                  # medio largo (1,2 m) y medio ancho
    for zs in (-1, 1):
        z0 = zs * W - (1 if zs > 0 else 0)
        for x in range(-L, L + 10):
            y = 0 if x < L - 6 else int(((x - (L - 6)) / 16) ** 2 * 14)   # punta curvada
            for dy in range(3):
                for dz in (0, -zs):
                    M.put(x, y + dy, z0 + dz, P, WOOD_D if dy == 0 else WOOD)
        for x in range(-L + 4, L - 2, 16):                          # montantes
            for y in range(3, 12):
                M.put(x, y, z0, P, WOOD); M.put(x + 1, y, z0, P, WOOD)
    for x in range(-L + 2, L - 2):                                 # plataforma de listones
        if x % 6 == 5: continue
        for z in range(-W - 1, W + 1):
            M.put(x, 12, z, P, lerp(WOOD, WOOD_L, M.hsh(x // 6, 0, 0)))
            M.put(x, 13, z, P, lerp(WOOD, WOOD_L, M.hsh(x // 6, 0, 0)))
    for zs in (-1, 1):                                             # barandillas
        for x in range(-L + 2, L - 2):
            M.put(x, 16, zs * W - (1 if zs > 0 else 0), P, WOOD_D)
    # carga: caja y fardo de lona
    for x in range(-44, -6):
        for y in range(14, 38):
            for z in range(-13, 13):
                if min(x + 44, -7 - x, y - 14, 37 - y, z + 13, 12 - z) > 1: continue
                c = lerp(WOOD_D, WOOD_L, 0.3 + 0.5 * M.hsh((y - 14) // 6, 1, 0))
                if (y - 14) % 6 == 0: c = GROOVE
                M.put(x, y, z, P, c)
    for x in range(-2, 46):
        for y in range(14, 34):
            for z in range(-14, 14):
                if ((y - 23) / 10) ** 2 + (z / 14) ** 2 > 1: continue
                if ((y - 23) / 8.5) ** 2 + (z / 12.5) ** 2 < 1 and 0 < x < 45: continue
                M.put(x, y, z, P, lerp(CANVAS_D, CANVAS, 0.5 + 0.5 * M.noise(x * 0.1, y * 0.1, z * 0.1, 1.0)))
    for x in (-36, -16, 8, 24, 38):                                 # cuerdas por encima de la carga
        for z in range(-15, 15):
            top = max((y for y in range(12, 42) if (x, y, z) in M.V), default=12)
            M.put(x, top + 1, z, P, ROPE)
        for y in range(12, 40):
            for zs in (-1, 1):
                z = zs * 15 - (1 if zs > 0 else 0)
                if any((x, y, zz) in M.V for zz in range(-14, 14)) and y < 38:
                    M.put(x, y, z, P, ROPE, over=False)
    snow_on_top(M, prob=0.85, depth=1, min_y=20)
    return M


# ---------------- trípode ----------------

def tripode():
    """Trípode de madera con un teodolito de latón encima."""
    M = Model(S=3, seed=25)
    top = 62
    for a in (0, 2.1, 4.2):
        fx, fz = math.cos(a) * 22, math.sin(a) * 22
        for i in range(top + 1):
            t = i / top
            x = fx * (1 - t); z = fz * (1 - t)
            for dx in (0, 1):
                for dz in (0, 1):
                    M.put(int(round(x)) + dx, i, int(round(z)) + dz, P, WOOD if t > 0.12 else IRON)
    for x in range(-4, 6):
        for z in range(-4, 6):
            for y in range(top, top + 3): M.put(x, y, z, P, BRASS if y == top + 2 else WOOD_D)
    for x in range(-2, 4):                                         # cuerpo y anteojo
        for z in range(-2, 4):
            for y in range(top + 3, top + 12): M.put(x, y, z, P, BRASS if abs(x - 0.5) + abs(z - 0.5) < 4 else IRON)
    for x in range(-6, 8):
        for y in range(top + 12, top + 16):
            for z in (0, 1): M.put(x, y, z, P, IRON if x not in (-6, 7) else BRASS)
    return M


# ---------------- bandera ----------------

def bandera():
    """Mástil con la bandera de Estados Unidos (48 estrellas, 1930) ondeando hacia +X."""
    M = Model(S=3, seed=26)
    H = 170
    for y in range(0, H):
        for x in (0, 1):
            for z in (0, 1): M.put(x, y, z, P, WOOD_D if y < H - 2 else BRASS)
    FW, FH = 62, 34
    for x in range(2, 2 + FW):
        wave = int(round(2.5 * math.sin((x - 2) * 0.16)))
        for y in range(H - 4 - FH, H - 4):
            fy = H - 5 - y                                        # fila desde arriba
            c = RED if (fy * 13 // FH) % 2 == 0 else WHITE
            if fy < FH * 7 // 13 and x - 2 < FW * 2 // 5:
                c = BLUE
                if (x % 3 == 0) and (fy % 3 == 1): c = WHITE
            M.put(x, y, wave, P, c)
    # nieve al pie
    drift(M, lambda x, z: max(abs(x + 0.5), abs(z + 0.5)) - 1, 10, 5)
    return M


# ---------------- farol ----------------

def farol():
    """Farol de poste: poste de madera con vetas, brazo con tornapunta y voluta de hierro,
    farol de cuatro cristales con marco, tejadillo y asa, nieve encima y al pie, y cuña de
    piedras. Pivote "light" en la llama."""
    M = Model(S=3, seed=27)
    H = 104                                                        # 2,15 m
    for y in range(0, H):
        for x in range(-2, 2):
            for z in range(-2, 2):
                if abs(x + 0.5) + abs(z + 0.5) > 3: continue          # aristas achaflanadas
                c = lerp(WOOD_D, WOOD, 0.45 + 0.4 * M.noise(x * 0.8, y * 0.08, z * 0.8, 1.0))
                if (y + x * 7) % 23 == 0: c = GROOVE                  # vetas
                M.put(x, y, z, P, c)
    for y in range(H, H + 3):                                       # remate
        for x in range(-3, 3):
            for z in range(-3, 3): M.put(x, y, z, P, WOOD_D)
    for x in range(-2, 30):                                         # brazo
        for y in (H - 6, H - 5, H - 4):
            for z in (-1, 0): M.put(x, y, z, P, WOOD if y != H - 6 else WOOD_D)
    for i in range(22):                                              # tornapunta
        for z in (-1, 0):
            M.put(2 + i, H - 28 + i, z, P, WOOD_D); M.put(2 + i, H - 27 + i, z, P, WOOD)
    for a in range(0, 300, 12):                                      # voluta de hierro
        t = math.radians(a); r = 2 + a / 60
        M.put(int(round(10 + r * math.cos(t))), int(round(H - 12 + r * math.sin(t))), 0, P, IRON)
    LX, LY = 26, H - 26                                              # farol colgado
    for y in range(LY + 12, H - 6): M.put(LX, y, 0, P, IRON); M.put(LX, y, -1, P, IRON)   # gancho
    for x in range(LX - 6, LX + 6):
        for z in range(-6, 6):
            M.put(x, LY - 10, z, P, IRON)                            # base
            M.put(x, LY - 9, z, P, IRON_L if min(x - LX + 6, LX + 5 - x, z + 6, 5 - z) == 0 else IRON)
    for y in range(LY - 8, LY + 7):                                  # cristales y montantes
        for x in range(LX - 5, LX + 5):
            for z in range(-5, 5):
                ex = x in (LX - 5, LX + 4); ez = z in (-5, 4)
                if not (ex or ez): continue
                if (ex and ez) or y in (LY - 8, LY + 6): M.put(x, y, z, P, IRON)
                else: M.put(x, y, z, P, (1.0, 0.82, 0.50), glow=1)
    for y in range(LY - 7, LY + 4):                                  # llama
        w = 2 if y < LY + 1 else 1
        for x in range(LX - w, LX + w):
            for z in range(-w, w): M.put(x, y, z, P, (1.0, 0.72, 0.30), glow=1)
    for i, y in enumerate(range(LY + 7, LY + 12)):                  # tejadillo
        w = 7 - i
        for x in range(LX - w, LX + w):
            for z in range(-w, w): M.put(x, y, z, P, IRON if i < 4 else IRON_L)
    for x in range(LX - 3, LX + 3): M.put(x, LY + 14, 0, P, IRON)   # asa
    for y in range(LY + 11, LY + 14): M.put(LX - 3, y, 0, P, IRON); M.put(LX + 2, y, 0, P, IRON)
    snow_on_top(M, prob=0.95, depth=1, min_y=H - 5)
    for x in range(-4, 5):                                           # cuña de piedras al pie
        for z in range(-4, 5):
            for y in range(0, 5):
                if max(abs(x), abs(z)) in (3, 4) and M.hsh(x, y, z) > 0.45:
                    M.put(x, y, z, P, (0.35, 0.34, 0.33) if M.hsh(z, x, y) > 0.5 else (0.26, 0.25, 0.25))
    drift(M, lambda x, z: math.hypot(x + 0.5, z + 0.5) - 4, 14, 7)
    return M, {P: [0, 0, 0], 'light': [LX, LY, 0]}


# ---------------- iglú ----------------

def iglu():
    """Iglú de bloques de nieve (radio 1,7 m, 32 voxels/m): hileras que se estrechan hacia
    arriba, cada bloque con su tono y algo abombado, juntas hundidas, túnel de bloques hacia
    +Z con resplandor cálido dentro, ventana de hielo y nieve amontonada al pie."""
    M = Model(S=2, seed=28)
    R, SHELL = 54, 3
    TR, T0, T1 = 19, R - 16, R + 16
    BLOCK_A, BLOCK_B = (0.92, 0.94, 0.98), (0.80, 0.86, 0.93)
    JOINT = (0.56, 0.64, 0.77)
    def block_of(x, y, z):
        row_h = 9 - min(4, y // 14)                                # hileras más bajas arriba
        row = int(y / row_h)
        rr = math.sqrt(max(1.0, R * R - (y + 0.5) ** 2))
        per = max(3, int(round(2 * math.pi * rr / 18)))
        f = math.atan2(z + 0.5, x + 0.5) / (2 * math.pi) * per + (0.5 if row % 2 else 0.0)
        return row, int(math.floor(f)) % per, f - math.floor(f), 2 * math.pi * rr / per, (y % row_h) / row_h
    for y in range(0, R + 2):
        for x in range(-R - 2, R + 2):
            for z in range(-R - 2, R + 2):
                d = math.sqrt((x + 0.5) ** 2 + (y + 0.5) ** 2 + (z + 0.5) ** 2)
                if d > R + 1 or d < R - SHELL: continue
                row, idx, f, length, fy = block_of(x, y, z)
                joint = fy < 0.12 or f * length < 1.2
                bulge = 0.9 * math.sin(math.pi * f) * math.sin(math.pi * min(1.0, fy + 0.05))
                if d > R - 0.2 + bulge: continue                        # bloque abombado
                if joint and d > R - 1.3: continue                      # junta hundida
                c = JOINT if joint else lerp(BLOCK_B, BLOCK_A, 0.3 + 0.6 * M.hsh(row, idx, 0))
                if not joint and y > R * 0.6: c = lerp(c, SNOW, 0.5)     # nieve en lo alto
                M.put(x, y, z, P, c)
    for z in range(T0, T1):                                          # túnel de bloques
        for x in range(-TR - 1, TR + 1):
            for y in range(0, TR + 1):
                d = math.hypot(x + 0.5, y + 0.5)
                if d < TR - SHELL:
                    M.V.pop((x, y, z), None); continue
                if d > TR: continue
                joint = (z - T0) % 10 == 0 or y % 7 == 0
                if joint and d > TR - 1: continue
                M.put(x, y, z, P, JOINT if joint else lerp(BLOCK_B, BLOCK_A, 0.3 + 0.6 * M.hsh((z - T0) // 10, y // 7, 5)))
    for x in range(-TR + SHELL, TR - SHELL):                        # dentro: oscuro con luz cálida
        for y in range(0, TR - SHELL):
            if math.hypot(x + 0.5, y + 0.5) < TR - SHELL:
                warm = max(0.0, 1 - math.hypot(x + 0.5, y - 3) / 14)
                M.put(x, y, T0, P, lerp((0.08, 0.07, 0.08), (0.80, 0.45, 0.18), warm), glow=1 if warm > 0.45 else 0)
        for z in range(T0, T1):
            if abs(x + 0.5) < TR - SHELL:
                M.put(x, 0, z, P, lerp((0.14, 0.13, 0.15), (0.55, 0.58, 0.65), (z - T0) / (T1 - T0)))
    a = math.radians(-40)                                            # ventana de hielo translúcido
    for (x, y, z), v in M.V.items():
        if 24 <= y < 33 and v[1] != JOINT:
            ang = math.atan2(z + 0.5, x + 0.5)
            if abs(ang - a) < 0.13 and math.sqrt(x * x + y * y + z * z) > R - 2:
                v[1] = (0.98, 0.80, 0.52); v[2] = 1
    drift(M, lambda x, z: None if (z > 0 and abs(x + 0.5) < TR + 2) else math.hypot(x + 0.5, z + 0.5) - R + 1, 10, 14)
    return M, {P: [0, 0, 0]}


# ---------------- cabaña ----------------

def cabana():
    """Cabaña de troncos (3,1 x 2,4 m, 32 voxels/m): troncos redondeados (canto claro arriba,
    sombra abajo) con nudos y cabezas cruzadas con anillos, zócalo de piedra, tejado de tablas
    con un manto de nieve grueso y carámbanos en el alero, puerta de tablas en Z con bisagras,
    ventana con contraventanas y luz cálida, chimenea de piedra con mortero, leña apilada y
    nieve amontonada."""
    M = Model(S=2, seed=29)
    HX, HZ, WALL, LOG, TH = 50, 38, 58, 7, 3
    LOGC = [(0.45, 0.31, 0.18), (0.40, 0.27, 0.15), (0.48, 0.33, 0.19), (0.37, 0.25, 0.14)]
    SHAPE = [0.62, 0.85, 1.0, 1.08, 1.12, 1.05, 0.9]                # sección redonda del tronco
    def log_col(course, yy, x, z):
        c = scale(LOGC[(course * 3 + (x + z) // 40) % 4], SHAPE[yy])
        if M.hsh(x // 3, course, z // 3) > 0.985: c = scale(c, 0.6)  # nudos
        return c
    def ring(x, z, pad):
        return min(x + HX + pad, HX - 1 + pad - x, z + HZ + pad, HZ - 1 + pad - z)
    for y in range(0, 6):                                            # zócalo de piedra
        for x in range(-HX - 1, HX + 1):
            for z in range(-HZ - 1, HZ + 1):
                if ring(x, z, 1) >= 3: continue
                off = (y // 3) * 2
                mortar = y % 3 == 0 or (x + z + off) % 5 == 0
                M.put(x, y, z, P, (0.22, 0.21, 0.21) if mortar else lerp((0.34, 0.33, 0.32), (0.48, 0.47, 0.45), M.hsh((x + off) // 5, y // 3, z // 5)))
    for y in range(6, WALL):
        course, yy = (y - 6) // LOG, (y - 6) % LOG
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                r = ring(x, z, 0)
                if r >= TH or (r == 0 and yy == 0): continue          # junta hundida
                M.put(x, y, z, P, log_col(course, yy, x, z))
        if yy == 0: continue
        for sx in (-1, 1):                                            # cabezas cruzadas
            for sz in (-1, 1):
                for e in range(1, 7):
                    for t in range(TH):
                        if course % 2 == 0:
                            x = HX - 1 + e if sx > 0 else -HX - e
                            z = HZ - 1 - t if sz > 0 else -HZ + t
                        else:
                            x = HX - 1 - t if sx > 0 else -HX + t
                            z = HZ - 1 + e if sz > 0 else -HZ - e
                        c = log_col(course, yy, x, z)
                        if e == 6:                                    # la testa, con anillos
                            rr = abs(yy - 3.5) + t * 0.7
                            c = (0.64, 0.50, 0.31) if rr < 1.5 else ((0.50, 0.37, 0.22) if rr < 2.6 else (0.34, 0.23, 0.13))
                        M.put(x, y, z, P, c)
    RISE, EAVE = 36, 12
    for i in range(0, HZ + EAVE):                                     # tejado de tablas y nieve
        yb = WALL + RISE - int(i * RISE / (HZ + 8))
        for z in (i, -i - 1):
            for x in range(-HX - 10, HX + 10):
                M.put(x, yb, z, P, (0.24, 0.17, 0.11) if (x // 6) % 2 else (0.29, 0.21, 0.13))
                depth = 3 + int(round(1.5 * M.noise(x * 0.07, 0, z * 0.07, 3.0)))
                if i > HZ + EAVE - 3 and M.hsh(x, 0, z) < 0.3: depth = 1
                for d in range(1, depth + 1):
                    M.put(x, yb + d, z, P, SNOW if M.hsh(x, yb + d, z) > 0.15 else SNOW_SH)
    yb = WALL + RISE - int((HZ + EAVE - 1) * RISE / (HZ + 8))
    for x in range(-HX - 10, HX + 10):                                # frontal del alero y carámbanos
        for zs in (-1, 1):
            z = zs * (HZ + EAVE) - (1 if zs > 0 else 0)
            for y in (yb - 1, yb - 2): M.put(x, y, z, P, WOOD_D)
            if M.hsh(x, 9, zs) > 0.72:
                for k in range(int(2 + 6 * M.hsh(x, 4, zs))):
                    M.put(x, yb - 3 - k, z, P, (0.80, 0.90, 0.97))
    for x in list(range(-HX, -HX + TH)) + list(range(HX - TH, HX)):  # hastiales de tablas
        for y in range(WALL, WALL + RISE):
            w = (HZ + 8) * (1 - (y - WALL) / RISE) - 1
            for z in range(-int(w), int(w)):
                M.put(x, y, z, P, (0.38, 0.26, 0.15) if (z // 5) % 2 else (0.32, 0.22, 0.13), over=False)
    DX0, DX1, DH = -30, -12, 46                                        # puerta
    BRACE = (0.36, 0.25, 0.14)
    for x in range(DX0, DX1):
        for y in range(6, DH):
            frame = x in (DX0, DX1 - 1) or y == DH - 1
            c = WOOD_D if frame else ((0.33, 0.22, 0.12) if ((x - DX0) // 4) % 2 else (0.28, 0.18, 0.10))
            if (x - DX0) % 4 == 0 and not frame: c = GROOVE
            for z in (HZ - 1, HZ): M.put(x, y, z, P, c)
            if y in (14, 15, 36, 37) and not frame: M.put(x, y, HZ + 1, P, BRACE)
    for i in range(20):                                               # diagonal de la Z
        x = DX0 + 1 + int(i * (DX1 - DX0 - 3) / 20); y = 16 + i
        M.put(x, y, HZ + 1, P, BRACE); M.put(x + 1, y, HZ + 1, P, BRACE)
    for y in (14, 36):
        for x in range(DX0, DX0 + 6): M.put(x, y, HZ + 2, P, IRON)     # bisagras
    for y in (26, 27): M.put(DX1 - 4, y, HZ + 2, P, IRON_L)            # tirador
    WX0, WX1, WY0, WY1 = 10, 32, 24, 42                                # ventana
    for x in range(WX0, WX1):
        for y in range(WY0, WY1):
            frame = x in (WX0, WX1 - 1) or y in (WY0, WY1 - 1) or x == (WX0 + WX1) // 2 or y == (WY0 + WY1) // 2
            for z in (HZ - 1, HZ):
                if frame: M.put(x, y, z, P, WOOD_D)
                else: M.put(x, y, z, P, (1.0, 0.76, 0.42) if (x + y) % 7 else (1.0, 0.86, 0.6), glow=1)
    for x0 in (WX0 - 10, WX1):                                        # contraventanas abiertas
        for x in range(x0, x0 + 10):
            for y in range(WY0, WY1):
                M.put(x, y, HZ + 1, P, (0.27, 0.35, 0.30) if (x - x0) % 4 else (0.20, 0.26, 0.22))
    for x in range(WX0 - 2, WX1 + 2):                                 # alféizar con nieve
        for z in (HZ + 1, HZ + 2):
            M.put(x, WY0 - 1, z, P, WOOD_D); M.put(x, WY0, z, P, SNOW)
    CX0, CX1, CZ0, CZ1 = 26, 38, -22, -10                             # chimenea
    top = WALL + RISE + 14
    for y in range(40, top):
        for x in range(CX0, CX1):
            for z in range(CZ0, CZ1):
                inner = min(x - CX0, CX1 - 1 - x, z - CZ0, CZ1 - 1 - z) >= 2
                if inner and y < top - 2: continue
                off = 2 if (y // 4) % 2 else 0
                mortar = y % 4 == 0 or (x + z + off) % 6 == 0
                c = (0.55, 0.54, 0.52) if mortar else lerp((0.30, 0.30, 0.31), (0.46, 0.45, 0.44), M.hsh((x + off) // 6, y // 4, (z + off) // 6))
                if inner: c = (0.06, 0.05, 0.05)
                M.put(x, y, z, P, c)
    for x in range(CX0, CX1):
        for z in range(CZ0, CZ1):
            if min(x - CX0, CX1 - 1 - x, z - CZ0, CZ1 - 1 - z) < 2: M.put(x, top, z, P, SNOW)
    for row in range(5):                                              # leña apilada (+X)
        for k in range(6 - (row % 2)):
            zc = -24 + k * 8 + (4 if row % 2 else 0); yc = 7 + row * 7
            for x in range(HX + 1, HX + 16):
                for y in range(yc - 3, yc + 4):
                    for z in range(zc - 3, zc + 4):
                        r = math.hypot(y - yc, z - zc)
                        if r > 3.6: continue
                        c = (0.38, 0.26, 0.15)
                        if x == HX + 15: c = (0.66, 0.52, 0.32) if r < 2.2 else (0.30, 0.20, 0.11)
                        M.put(x, y, z, P, c)
    snow_on_top(M, prob=1.0, depth=1, min_y=40, patch=lambda x, y, z: x > HX and y < 50)
    def inside(x, z):
        if z > 0 and DX0 - 4 < x < DX1 + 4: return None               # la entrada, despejada
        return max(abs(x + 0.5) - HX - 1, abs(z + 0.5) - HZ - 1)
    drift(M, inside, 12, 7)
    return M, {P: [0, 0, 0]}


PIECES = {'farol': farol, 'iglu': iglu, 'cabana': cabana, 'tienda': tienda, 'caja_mano': caja, 'bidon': bidon,
          'trineo': trineo, 'tripode': tripode, 'bandera': bandera}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        r = fn()
        M, piv = r if isinstance(r, tuple) else (r, {P: [0, 0, 0]})
        n = M.export('models/atrezo_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('atrezo_%s: %d voxels' % (name, n))
