"""Atrezo de las ruinas de Pnakotus (hito 21.15, «La sombra fuera del tiempo»). Una parte "body", origen en
el centro de la base, la cara principal hacia +Z (como gen_atrezo_dunwich.py). El Gran Desierto Arenoso de
Australia Occidental, de noche: arena rojiza en ondas, matas de spinifex, y asomando de la arena los
bloques ciclópeos de basalto de la ciudad de la Gran Raza, convexos y cubiertos de jeroglíficos curvos;
las torres sin ventanas donde los Yith encerraron a los pólipos, y las trampillas selladas.

  bloque_1/2/3     bloque de basalto convexo y gastado, medio enterrado, con jeroglíficos curvos (16/m)
  muro             tramo de muro de bloques convexos, con la cabeza rota y la arena amontonada (16/m)
  torre            torre sin ventanas de basalto, redonda, rota arriba (16/m)
  trampilla        el marco de piedra de una trampilla, a ras de suelo, con el hueco negro (32/m)
  tapa             la tapa de la trampilla: una losa con el sello curvo y bandas de metal viejo (32/m)
  duna_1/2         duna de arena para los bordes (16/m)
  matorral         mata de spinifex, de púas doradas (32/m; se rompe)
  roca             peña de arenisca roja (16/m)
  tienda           tienda de lona caqui de la expedición de 1935, con sus vientos y estacas (32/m)

Escribe models/pna_<pieza>.json. Uso: python tools/gen_atrezo_pnakotus.py [piezas...]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
BASALT = (0.34, 0.33, 0.34); BASALT_D = (0.22, 0.21, 0.23); BASALT_L = (0.46, 0.45, 0.46)
GLYPH = (0.12, 0.12, 0.15)
SAND = (0.74, 0.56, 0.38); SAND_D = (0.58, 0.42, 0.28); SAND_L = (0.84, 0.68, 0.48)
SPINI = (0.70, 0.62, 0.36); SPINI_D = (0.48, 0.44, 0.24); SPINI_L = (0.86, 0.78, 0.50)
ROCK = (0.56, 0.32, 0.22); ROCK_D = (0.40, 0.22, 0.15); ROCK_L = (0.68, 0.42, 0.28)
METAL = (0.30, 0.27, 0.22); METAL_D = (0.18, 0.16, 0.13); RUST = (0.42, 0.26, 0.16)
HOLE = (0.01, 0.01, 0.015)


def glyph(u, v, seed):
    """¿Cae (u, v) en un trazo de los jeroglíficos curvos? Espirales y arcos que se enlazan, por celdas."""
    cu, cv = math.floor(u / 9.0), math.floor(v / 9.0)
    fu, fv = u - cu * 9.0 - 4.5, v - cv * 9.0 - 4.5
    h = (cu * 73856093 ^ cv * 19349663 ^ seed * 83492791) & 0xffff
    kind = h % 4
    r = math.hypot(fu, fv)
    a = math.atan2(fv, fu)
    if kind == 0: return abs(r - (2.0 + (a + math.pi) / math.tau * 2.0)) < 0.55 and r < 4.2   # espiral
    if kind == 1: return abs(r - 3.2) < 0.55 and fv > -1.0                                    # arco
    if kind == 2: return (abs(r - 1.6) < 0.55) or (abs(fu) < 0.5 and fv > 1.5)              # anillo con trazo
    return abs(fv - 1.8 * math.sin(fu * 0.7)) < 0.6 and abs(fu) < 4.0                         # onda


def basalt(M, x, y, z):
    c = lerp(BASALT_D, BASALT, 0.35 + 0.6 * M.noise(x, y * 0.7, z, 3.0))
    if M.hsh(x, y, z) < 0.02: c = lerp(c, BASALT_L, 0.6)
    return c


def convex_block(M, cx, cz, w, h, d, base=0, seed=0, glyphs=True, p=2.6, broken=0.0):
    """Bloque convexo de basalto (superelipsoide de exponente p), hueco, con la cara de delante y la de
    atrás talladas. `broken`: cuánto se le ha comido de la cabeza."""
    for x in range(int(cx - w) - 1, int(cx + w) + 2):
        for y in range(base, base + int(h * 2) + 1):
            for z in range(int(cz - d) - 1, int(cz + d) + 2):
                u, v, s = (x - cx) / w, (y - base - h) / h, (z - cz) / d
                f = abs(u) ** p + abs(v) ** p + abs(s) ** p
                if f > 1.0: continue
                if f < 0.6 and abs(v) < 0.85: continue                                   # hueco
                if broken and y > base + h * 2 * (1.0 - broken * M.noise(x, 0, z, 2.0)): continue
                c = basalt(M, x, y, z)
                if glyphs and abs(s) > 0.75 and abs(v) < 0.7 and glyph(x * 1.0, y * 1.0, seed): c = GLYPH
                M.put(x, y, z, P, c)


def sand_drift(M, cx, cz, rx, rz, h, seed=0):
    """Arena amontonada: un montículo bajo con ondas (solo la corteza)."""
    for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
        for z in range(int(cz - rz) - 1, int(cz + rz) + 2):
            u, v = (x - cx) / rx, (z - cz) / rz
            q = 1.0 - (u * u + v * v)
            if q <= 0.0: continue
            top = int(h * q ** 0.8 + 0.6 * math.sin(x * 0.55 + z * 0.2 + seed))
            for y in range(max(0, top - 2), top + 1):
                c = lerp(SAND_D, SAND, 0.4 + 0.5 * M.noise(x, y, z, 3.0))
                if (x + int(z * 0.4)) % 7 == 0 and y == top and M.hsh(x, y, z) < 0.6: c = lerp(c, SAND_L, 0.45)                     # las ondas del viento
                M.put(x, y, z, P, c)


def bloque(seed, w, h, d, drift):
    M = Model(S=1, seed=seed)
    convex_block(M, 0, 0, w, h, d, base=-2, seed=seed, broken=0.15)
    dx = drift
    sand_drift(M, dx, 0, w * 0.9, d * 1.3, h * 0.9, seed)
    return M, {P: [0, 0, 0]}


def bloque_1(): return bloque(2151, 18, 10, 13, 10)
def bloque_2(): return bloque(2152, 24, 8, 15, -12)
def bloque_3(): return bloque(2153, 14, 13, 12, 6)


def muro():
    """Tramo de muro de 4,5 m: dos hileras de bloques convexos que no casan del todo, la de arriba rota,
    con arena contra la base."""
    M = Model(S=1, seed=2154)
    x = -34
    while x < 34:
        w = M.rng.uniform(7, 11)
        convex_block(M, x + w, 0, w, 7, 9, base=0, seed=int(x) + 99)
        x += w * 2 - 1
    x = -30
    while x < 28:
        w = M.rng.uniform(6, 10)
        if M.rng.random() < 0.75:
            convex_block(M, x + w, M.rng.uniform(-1, 1), w, 6, 8, base=13, seed=int(x) + 7, broken=0.5)
        x += w * 2 - 1
    sand_drift(M, -6, 9, 30, 9, 7, 3)
    sand_drift(M, 14, -8, 22, 7, 5, 5)
    return M, {P: [0, 0, 0]}


def torre():
    """Torre sin ventanas de 7 m y 4,5 de ancho: basalto en hiladas de bloques convexos, lisa y ciega,
    con la cabeza rota y la arena subiendo por la base."""
    M = Model(S=1, seed=2155)
    R, H = 36, 112
    for y in range(0, H + 1):
        row = y // 12
        for x in range(-R - 2, R + 3):
            for z in range(-R - 2, R + 3):
                d = math.hypot(x, z)
                a = math.atan2(z, x)
                cell = int((a + math.pi) / math.tau * 14 + row * 0.5)
                bulge = 1.4 * math.sin(((a + math.pi) / math.tau * 14 + row * 0.5 - cell) * math.pi) * math.sin(((y % 12) / 12) * math.pi)
                r = R - 0.04 * y + bulge
                if d > r or d < r - 3.0: continue
                top = H - int(26 * M.noise(math.cos(a) * 3, 0, math.sin(a) * 3, 1.2))
                if y > top: continue
                c = basalt(M, x, y, z)
                if y % 12 == 0 or (((a + math.pi) / math.tau * 14 + row * 0.5) % 1.0) < 0.05: c = BASALT_D   # juntas
                if abs(y - 40) < 9 and (a > 0.6 and a < 1.9) and glyph(a * 20.0, y, 7): c = GLYPH
                M.put(x, y, z, P, c)
    for x in range(-R + 2, R - 1):                                                    # lo de arriba, roto: un suelo
        for z in range(-R + 2, R - 1):
            if math.hypot(x, z) < R - 4: M.put(x, H - 30, z, P, BASALT_D)
    sand_drift(M, 10, 26, 30, 18, 14, 1)
    sand_drift(M, -24, -10, 20, 22, 10, 2)
    return M, {P: [0, 0, 0]}


def trampilla():
    """El marco de una trampilla de 1,7 m, a ras de suelo: un anillo de piedra con el canto tallado y el
    hueco negro en medio (la tapa va aparte: el juego la abre y la cierra)."""
    M = Model(S=2, seed=2156)
    RO, RI = 30, 21
    for x in range(-RO - 1, RO + 2):
        for z in range(-RO - 1, RO + 2):
            d = math.hypot(x, z)
            if d > RO: continue
            if d < RI:                                     # el hueco: negro, sobre el suelo (no se puede cavar)
                M.put(x, 0, z, P, HOLE if d < RI - 2 else lerp(HOLE, BASALT_D, 0.5))
                continue
            top = 4 if d < RO - 3 else 2
            for y in range(0, top + 1):
                c = basalt(M, x, y, z)
                a = math.atan2(z, x)
                if y == top and glyph(a * 28.0, d * 2.0, 3): c = GLYPH
                if d < RI + 1.2: c = BASALT_D                                          # el canto de dentro
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def tapa():
    """La tapa: losa redonda de 1,4 m y 12 cm, con el sello en espiral y tres bandas de metal viejo."""
    M = Model(S=2, seed=2157)
    R = 22
    for x in range(-R - 1, R + 2):
        for z in range(-R - 1, R + 2):
            d = math.hypot(x, z)
            if d > R: continue
            for y in range(0, 4):
                c = basalt(M, x, y, z)
                if y == 3:
                    a = math.atan2(z, x)
                    if abs(d - (3 + (a + math.pi) / math.tau * 5) % 16) < 0.8 and d < 17: c = GLYPH   # el sello
                    if abs(d - 19) < 0.7: c = GLYPH
                if abs(x) in (13, 14) or abs(z) in (1, 0) and d > 17:
                    c = lerp(METAL_D, METAL, M.hsh(x, y, z))
                    if M.noise(x, y, z, 2.0) > 0.62: c = RUST
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def duna(seed, L, W, H):
    M = Model(S=1, seed=seed)
    for x in range(-L, L + 1):
        for z in range(-W, W + 1):
            u, v = x / L, z / W
            q = 1.0 - (u * u + v * v)
            if q <= 0.0: continue
            crest = 0.25 * math.sin(x * 0.07 + seed)                                  # la cresta, desplazada
            top = int(H * q ** 0.7 * (1.0 + crest * math.tanh(z / 6.0)))
            for y in range(max(0, top - 2), top + 1):
                c = lerp(SAND_D, SAND, 0.35 + 0.55 * M.noise(x, y, z, 5.0))
                if (x + int(z * 0.3)) % 8 == 0 and y == top and M.hsh(x, y, z) < 0.6: c = lerp(c, SAND_L, 0.4)
                if z < -W * 0.4 and y == top and M.hsh(x, y, z) < 0.3: c = SAND_D      # la ladera de sotavento
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def duna_1(): return duna(2158, 64, 30, 26)
def duna_2(): return duna(2159, 48, 26, 20)


def matorral():
    """Mata de spinifex de 0,7 m: un cojín de púas finas que salen hacia fuera y arriba, doradas."""
    M = Model(S=2, seed=2160)
    rng = M.rng
    for k in range(70):
        a = rng.uniform(0, math.tau)
        up = rng.uniform(0.35, 1.2)
        L = rng.uniform(9, 18)
        x0, z0 = math.cos(a) * rng.uniform(0, 5), math.sin(a) * rng.uniform(0, 5)
        for j in range(int(L)):
            t = j / L
            x = x0 + math.cos(a) * j * (1.0 - up * 0.4)
            z = z0 + math.sin(a) * j * (1.0 - up * 0.4)
            y = j * up * 0.9
            c = lerp(SPINI_D, SPINI, t) if t < 0.85 else SPINI_L
            M.put(int(round(x)), int(y), int(round(z)), P, c)
    for x in range(-6, 7):                                                            # la base, apretada
        for z in range(-6, 7):
            if x * x + z * z < 36:
                for y in range(0, 3): M.put(x, y, z, P, lerp(SPINI_D, SPINI, M.hsh(x, y, z) * 0.5))
    return M, {P: [0, 0, 0]}


def roca():
    """Peña de arenisca roja de 1,6 m, gastada por el viento en capas."""
    M = Model(S=1, seed=2161)
    for x in range(-14, 15):
        for y in range(-1, 20):
            for z in range(-11, 12):
                r = 1.0 + 0.18 * math.sin(y * 0.9) + 0.12 * M.noise(x, y, z, 2.5)           # capas
                f = (abs(x) / 13.0) ** 2.2 + (abs(y - 8) / 11.0) ** 2.2 + (abs(z) / 10.0) ** 2.2
                if f > r or (f < r * 0.55): continue
                c = lerp(ROCK_D, ROCK, 0.4 + 0.5 * M.noise(x, y * 0.5, z, 3.0))
                if y % 3 == 0: c = lerp(c, ROCK_L, 0.4)
                M.put(x, y, z, P, c)
    sand_drift(M, 6, 6, 14, 9, 4, 4)
    return M, {P: [0, 0, 0]}


def tienda():
    """Tienda de lona de caballete de 2,4 × 2 m: dos faldones caqui con costuras, la puerta abierta delante
    con la sombra de dentro, los mástiles, los vientos tensos y sus estacas, y arena contra la base."""
    M = Model(S=2, seed=2162)
    CAN = (0.62, 0.55, 0.40); CAN_D = (0.48, 0.42, 0.30); CAN_L = (0.72, 0.65, 0.48)
    POLE = (0.36, 0.26, 0.16); ROPE = (0.70, 0.64, 0.50); IN = (0.10, 0.08, 0.06)
    L, W, H = 38, 30, 44
    for z in range(-L, L + 1):
        for x in range(-W, W + 1):
            y = int(H * (1.0 - abs(x) / W))
            for yy in (y, y - 1):
                if yy < 0: continue
                c = CAN if (abs(x) // 6) % 2 else CAN_L
                if abs(z) % 19 == 0 or abs(x) < 1: c = CAN_D                          # costuras y caballete
                if M.noise(x, yy, z, 3.0) > 0.78: c = lerp(c, CAN_D, 0.5)              # manchas
                M.put(x, yy, z, P, c)
    for x in range(-W, W + 1):                                                        # las dos testeras
        top = int(H * (1.0 - abs(x) / W))
        for y in range(0, top + 1):
            M.put(x, y, -L, P, CAN_D)
            door = abs(x) < (top - y) * 0.0 + (1.0 - y / H) * 12
            if door and y < H - 8:
                M.put(x, y, L, P, IN)                                                  # la puerta abierta
            else:
                M.put(x, y, L, P, CAN)
    for k in range(H + 6):                                                             # los mástiles
        M.put(0, k, L + 1, P, POLE); M.put(0, k, -L - 1, P, POLE)
    for sz in (-1, 1):                                                                 # los vientos y las estacas
        for sx in (-1, 1):
            a = (sx * 4, H - 4, sz * (L - 6)); b = (sx * (W + 18), 0, sz * (L + 4))
            n = 30
            for i in range(n + 1):
                t = i / n
                M.put(round(a[0] + (b[0] - a[0]) * t), round(a[1] + (b[1] - a[1]) * t), round(a[2] + (b[2] - a[2]) * t), P, ROPE)
            for y in range(0, 3): M.put(b[0], y, b[2], P, POLE)
    sand_drift(M, -10, 0, W + 8, L + 6, 4, 6)
    return M, {P: [0, 0, 0]}


PIECES = {'bloque_1': bloque_1, 'bloque_2': bloque_2, 'bloque_3': bloque_3, 'muro': muro, 'torre': torre,
          'trampilla': trampilla, 'tapa': tapa, 'duna_1': duna_1, 'duna_2': duna_2, 'matorral': matorral, 'roca': roca, 'tienda': tienda}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    here = os.path.join(os.path.dirname(__file__), '..')
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export(os.path.join(here, 'models', 'pna_%s.json' % name), piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('pna_%s: %d voxels' % (name, n))
