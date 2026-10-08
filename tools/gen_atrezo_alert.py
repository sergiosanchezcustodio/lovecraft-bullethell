"""Atrezo de los muelles y la cubierta del Alert (hito 7.3). Una parte "body", origen en el
centro de la base.

  casco       el costado del Alert atracado: casco negro con franja roja, borda, palo con
              jarcia y la chimenea (16/m: pieza de borde, 24 m de eslora)
  bolardo     bolardo de hierro con un cabo enrollado (32/m)
  grua        grúa de carga de madera con su gancho (32/m)
  fardos      fardos de carga apilados con lona (32/m)
  rollo       rollo de cabo grueso (32/m)
  linterna    farol de puerto sobre un poste (luz) (32/m)
  bote        bote salvavidas del Alert, volcado en el muelle (32/m)

Escribe models/alr_<pieza>.json. Uso: python tools/gen_atrezo_alert.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
HULL = (0.08, 0.09, 0.10); HULL_L = (0.16, 0.17, 0.18); RED = (0.42, 0.12, 0.10); RAIL = (0.40, 0.32, 0.22)
DECK = (0.44, 0.36, 0.26); IRON = (0.14, 0.14, 0.15); IRON_L = (0.30, 0.30, 0.32); RUST = (0.42, 0.24, 0.13)
ROPE = (0.56, 0.48, 0.32); ROPE_D = (0.42, 0.36, 0.24); WOOD = (0.36, 0.27, 0.18); WOOD_D = (0.24, 0.18, 0.12)
CANVAS = (0.52, 0.50, 0.40); CANVAS_D = (0.40, 0.38, 0.30); CRATE = (0.46, 0.38, 0.26)
LIGHT = (1.0, 0.80, 0.50); WHITE = (0.72, 0.70, 0.64)


def box(M, x0, x1, y0, y1, z0, z1, col):
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                M.put(x, y, z, P, col(x, y, z) if callable(col) else col)


def casco():
    """Costado de babor del Alert: el casco a lo largo de x (eslora 24 m), con la borda a
    3,5 m sobre el muelle, la superestructura blanca, un palo con jarcia y la chimenea."""
    M = Model(S=1, seed=101)
    L = 192
    for x in range(-L, L):
        bow = max(0.0, (abs(x) - (L - 40)) / 40.0)                  # proa y popa que se estrechan
        half = int(36 * (1 - bow ** 2))
        for y in range(0, 56):
            for z in (-half, -half + 1, half - 1, half):
                c = RED if y < 10 else (HULL_L if y % 12 == 0 else HULL)
                if y < 22 and M.noise(x, y, z, 8.0) > 0.78: c = RUST
                M.put(x, y, z, P, c)
        for z in range(-half, half):
            M.put(x, 56, z, P, DECK if (z // 3) % 2 else lerp(DECK, WOOD_D, 0.3))
        for z in (-half, half):                                     # borda
            for y in range(57, 62): M.put(x, y, z, P, RAIL if y == 61 or x % 16 == 0 else HULL)
    for x in range(-60, 30):                                        # superestructura blanca
        for y in range(57, 84):
            for z in range(-22, 22):
                if min(x + 60, 29 - x, z + 22, 21 - z) > 1 and y < 83: continue
                c = WHITE
                if 66 < y < 76 and (x % 10) < 5 and abs(z) == 22: c = (0.10, 0.12, 0.14)   # portillos
                M.put(x, y, z, P, c)
    for y in range(84, 120):                                        # chimenea
        for x in range(-30, -14):
            for z in range(-8, 8):
                if min(x + 30, -15 - x, z + 8, 7 - z) > 1: continue
                M.put(x, y, z, P, HULL if y > 112 else RED)
    for y in range(57, 200):                                        # palo (2x2: sobrevive a la mitad de resolución)
        for x in (60, 61):
            for z in (0, 1): M.put(x, y, z, P, WOOD)
    for k in range(140):                                            # jarcia
        t = k / 139
        for s in (-1, 1):
            for d in (0, 1): M.put(60 + int(t * 70) + d, 200 - int(t * 140), s * int(t * 30), P, ROPE_D)
    half = Model(S=1, seed=0)                                       # a 8/m: uno de cada 2x2x2
    for (x, y, z), v in M.V.items():
        if x % 2 == 0 and y % 2 == 0 and z % 2 == 0: half.V[(x // 2, y // 2, z // 2)] = v
    half.S = 0.5
    return half, {P: [0, 0, 0]}


def bolardo():
    M = Model(S=2, seed=102)
    for y in range(0, 22):
        r = 7 if y < 4 or y > 18 else 5
        for x in range(-r, r):
            for z in range(-r, r):
                if x * x + z * z <= r * r: M.put(x, y, z, P, IRON_L if y > 19 else IRON)
    for k in range(60):                                             # cabo enrollado y que se va
        a = k * 0.5
        M.put(int(math.cos(a) * 7), 8 + k // 12, int(math.sin(a) * 7), P, ROPE)
    for k in range(30): M.put(7 + k, 4 - k // 8, 0, P, ROPE_D)
    return M, {P: [0, 0, 0]}


def grua():
    M = Model(S=2, seed=103)
    box(M, -10, 10, 0, 6, -10, 10, WOOD_D)
    for y in range(6, 120):
        for x in (-2, 1):
            for z in (-2, 1): M.put(x, y, z, P, WOOD)
    for k in range(80):                                             # pluma inclinada
        M.put(k, 110 - k // 3, 0, P, WOOD); M.put(k, 111 - k // 3, 0, P, WOOD)
    for y in range(40, 84): M.put(79, y, 0, P, ROPE_D)              # cable y gancho
    for k in range(6): M.put(79 + (k > 2), 39 - k, 0, P, IRON_L)
    return M, {P: [0, 0, 0]}


def fardos():
    M = Model(S=2, seed=104)
    for i, (cx, cz, h) in enumerate(((-12, -6, 0), (10, -4, 0), (-2, 10, 0), (0, -2, 24))):
        box(M, cx - 11, cx + 11, h, h + 24, cz - 10, cz + 10,
            lambda x, y, z: WOOD_D if (x % 11 == 0 or y % 12 == 0) else CRATE)
    for x in range(-24, 22):                                        # lona por encima
        for z in range(-17, 20):
            top = max([y for (xx, y, zz) in [(x, yy, z) for yy in range(0, 50)] if (x, y, z) in M.V] or [-1])
            if top >= 0: M.put(x, top + 1, z, P, CANVAS if (x + z) % 7 else CANVAS_D)
    return M, {P: [0, 0, 0]}


def rollo():
    M = Model(S=2, seed=105)
    for y in range(0, 10):
        for a in range(0, 360, 4):
            for r in (6, 9, 12):
                M.put(int(math.cos(math.radians(a)) * r), y, int(math.sin(math.radians(a)) * r), P, ROPE if (a // 20 + y) % 2 else ROPE_D)
    return M, {P: [0, 0, 0]}


def linterna():
    M = Model(S=2, seed=106)
    for y in range(0, 90): M.put(0, y, 0, P, WOOD_D); M.put(1, y, 0, P, WOOD_D)
    for x in range(0, 12): M.put(x, 88, 0, P, IRON)
    for y in range(76, 87):
        for x in range(8, 15):
            for z in range(-3, 4):
                edge = x in (8, 14) or z in (-3, 3)
                M.put(x, y, z, P, IRON if (edge and y in (76, 86)) else (LIGHT if not edge else (0.9, 0.7, 0.4)), glow=0 if (edge and y in (76, 86)) else 1)
    return M, {P: [0, 0, 0], 'light': [11, 80, 0]}


def bote():
    M = Model(S=2, seed=107)
    for x in range(-40, 40):
        w = 12 * math.sqrt(max(0.0, 1 - (x / 40) ** 2))
        for z in range(-int(w), int(w) + 1):
            h = 14 - int(abs(z) * 0.5)
            for y in range(max(0, h - 2), h):
                M.put(x, y, z, P, WHITE if y > h - 2 and abs(z) > w - 2 else (WOOD if (x // 4) % 2 else WOOD_D))
    return M, {P: [0, 0, 0]}


def borda():
    """Tramo de borda de la cubierta del Emma (4 m): regala baja de tablas y pasamanos, con
    imbornales por donde escapa el agua. Baja (1 m) porque va del lado de la cámara (32/m)."""
    M = Model(S=2, seed=108)
    for x in range(-64, 64):
        for y in range(0, 30):
            for z in (-1, 0):
                if y < 4 and (x + 64) % 24 < 4: continue          # imbornal
                M.put(x, y, z, P, RAIL if y >= 28 else (HULL if y < 26 else HULL_L))
        if x % 20 == 0:
            for y in range(0, 32): M.put(x, y, 1, P, RAIL)
    return M, {P: [0, 0, 0]}


def puente():
    """El puente y la superestructura del Emma (16/m, pieza de borde): caseta blanca con las
    ventanas del puente encendidas, chimenea y palo con jarcia."""
    M = Model(S=1, seed=109)
    for x in range(-48, 48):
        for y in range(0, 44):
            for z in range(-24, 0):
                if min(x + 48, 47 - x, z + 24, -1 - z) > 1 and y < 43: continue
                c = WHITE
                if 28 < y < 38 and (x % 10) < 6 and z == -1: c = LIGHT
                M.put(x, y, z, P, c, glow=1 if c == LIGHT else 0)
    for y in range(44, 80):
        for x in range(-12, 4):
            for z in range(-16, -6):
                if min(x + 12, 3 - x, z + 16, -7 - z) > 1: continue
                M.put(x, y, z, P, HULL if y > 72 else RED)
    for y in range(44, 160):
        for x in (30, 31):
            for z in (-12, -11): M.put(x, y, z, P, WOOD)
    return M, {P: [0, 0, 0]}


PIECES = {'borda': borda, 'puente': puente, 'casco': casco, 'bolardo': bolardo, 'grua': grua, 'fardos': fardos, 'rollo': rollo,
          'linterna': linterna, 'bote': bote}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/alr_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.8, specular=0.3, no_bottom=True)
        print('alr_%s: %d voxels' % (name, n))
