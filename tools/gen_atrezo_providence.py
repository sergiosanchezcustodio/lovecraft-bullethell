"""Atrezo del estudio de Wilcox en el edificio Fleur-de-Lys de Providence (hito 7.1). Una
parte "body", origen en el centro de la base.

  muro        pared del estudio: ladrillo con ventanales altos de noche, cornisa y tuberías
              (12 m de largo y 4 de alto; 16/m: pieza de borde)
  muro_bajo   el arranque de la pared por el lado de la cámara: zócalo de ladrillo (32/m)
  escultura_1 figura de escayola sobre un plinto, a medio desbastar (32/m)
  escultura_2 busto de arcilla oscura, inquietante, sobre una peana (32/m)
  caballete   caballete con un lienzo de un mar negro y una ciudad de ángulos (32/m)
  mesa        mesa de trabajo con barro, herramientas, un cubo y trapos (32/m)
  relieve     el bajorrelieve de arcilla de Wilcox sobre su soporte: la figura con cabeza de
              pulpo y los jeroglíficos (32/m)
  sacos       sacos de barro y un barril (32/m)
  lampara     lámpara de pie de latón con pantalla; luz en el pivote "light" (32/m)
  pilar       pilar de hierro fundido del edificio (32/m)

Escribe models/prv_<pieza>.json. Uso: python tools/gen_atrezo_providence.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
BRICK = (0.42, 0.24, 0.18); BRICK_D = (0.30, 0.17, 0.13); MORTAR = (0.50, 0.46, 0.40)
TRIM = (0.36, 0.30, 0.24); GLASS = (0.10, 0.14, 0.20); GLASS_L = (0.24, 0.30, 0.40); FRAME = (0.20, 0.16, 0.12)
PLASTER = (0.82, 0.80, 0.74); PLASTER_D = (0.66, 0.64, 0.58)
CLAY = (0.40, 0.30, 0.22); CLAY_D = (0.28, 0.20, 0.15); CLAY_L = (0.50, 0.40, 0.30)
WOOD = (0.38, 0.27, 0.17); WOOD_D = (0.26, 0.18, 0.12)
CANVAS = (0.70, 0.66, 0.56); SEA = (0.08, 0.12, 0.12); SEA_L = (0.18, 0.26, 0.24); CITY = (0.22, 0.30, 0.24)
IRON = (0.14, 0.14, 0.15); IRON_L = (0.26, 0.26, 0.28)
BRASS = (0.62, 0.48, 0.24); SHADE = (0.86, 0.70, 0.44); LIGHT = (1.0, 0.82, 0.55)
SACK = (0.56, 0.48, 0.34); SACK_D = (0.44, 0.37, 0.26)


def box(M, x0, x1, y0, y1, z0, z1, col):
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                M.put(x, y, z, P, col(x, y, z) if callable(col) else col)


def brick(M):
    def f(x, y, z):
        if y % 4 == 0: return MORTAR
        if (x + (y // 4) * 4) % 8 == 0: return MORTAR
        return lerp(BRICK, BRICK_D, M.noise(x, y, z, 6.0))
    return f


# ---------------- paredes ----------------

def muro():
    M = Model(S=1, seed=71)
    L, H, T = 96, 64, 4                                         # 12 x 4 m, 25 cm de grosor
    b = brick(M)
    for x in range(-L, L):
        for y in range(0, H):
            win = 10 < y < 54 and (x + L) % 32 >= 8 and (x + L) % 32 < 24
            for z in range(-T, 0):
                if win and z > -T:
                    continue
                if win:                                         # ventanal: cristal de noche con parteluz
                    u = (x + L) % 32
                    c = FRAME if u in (8, 15, 16, 23) or y in (11, 32, 53) else (GLASS_L if (u + y) % 9 == 0 else GLASS)
                    M.put(x, y, z, P, c)
                    continue
                M.put(x, y, z, P, b(x, y, z))
    for x in range(-L, L):                                      # cornisa y zócalo
        for z in range(-T - 1, 1):
            M.put(x, H, z, P, TRIM); M.put(x, H + 1, z, P, TRIM)
            M.put(x, 0, z, P, TRIM); M.put(x, 1, z, P, TRIM)
    for y in range(0, H):                                       # bajante de hierro
        M.put(L - 6, y, 1, P, IRON); M.put(-L + 6, y, 1, P, IRON)
    return M, {P: [0, 0, 0]}


def muro_bajo():
    """Arranque de la pared del estudio por el lado de la cámara (rehecho el 09-10-2026), 4 m,
    32/m: la cara de dentro (-z, hacia el estudio) enlucida con desconchones que dejan ver el
    ladrillo y un rodapié de madera; la de fuera, ladrillo. El corte, escalonado por ladrillos,
    con alguno suelto encima; en medio, el alféizar del ventanal con los arranques del marco
    (como los de la pared alta); y cascotes y polvo de yeso al pie por dentro."""
    M = Model(S=2, seed=72)
    b = brick(M)
    T = 5                                                       # medio grosor
    def top_at(x):                                              # altura del corte, escalonada por ladrillos
        k = (x + 64) // 8
        return 14 + int(10 * M.noise(k * 8, 0, 0, 28.0)) + int(3 * M.hsh(k, 0, 4))
    win0, win1 = -20, 20                                        # el ventanal cortado
    for x in range(-64, 64):
        h = top_at(x)
        if win0 <= x < win1: h = min(h, 12)
        for y in range(0, h):
            for z in range(-T, T):
                if min(z + T, T - 1 - z) > 0 and y < h - 1: continue          # hueco
                inner = z == -T
                if inner and y >= 4:                                         # enlucido con desconchones
                    peel = M.noise(x, y, 0, 5.0) > 0.66
                    c = b(x, y, z) if peel else lerp(PLASTER_D, PLASTER, M.noise(x, y, 1, 4.0))
                    if not peel and y < 8: c = lerp(c, (0.48, 0.44, 0.38), 0.4)  # sucio abajo
                elif inner: c = WOOD_D if y in (0, 3) else WOOD                 # rodapié
                else: c = b(x, y, z)
                M.put(x, y, z, P, c)
        if M.hsh(x // 8, 1, 7) < 0.25 and not (win0 <= x < win1):           # ladrillo suelto encima
            for z in range(-T + 1, T - 1): M.put(x, h, z, P, b(x, h, z))
    for x in range(win0 - 2, win1 + 2):                         # alféizar de piedra
        for z in range(-T - 2, T + 1):
            M.put(x, 12, z, P, TRIM); M.put(x, 13, z, P, TRIM)
    for x in (win0, win0 + 1, -1, 0, win1 - 2, win1 - 1):       # arranques del marco y del parteluz
        for y in range(14, 14 + (8 if x in (-1, 0) else 5)):
            for z in (-1, 0): M.put(x, y, z, P, FRAME)
    for x in range(win0 + 2, win1 - 2):                         # cristales rotos en el alféizar
        if M.hsh(x, 2, 3) < 0.3: M.put(x, 14, -2, P, GLASS_L)
    for k in range(10):                                         # cascotes y yeso al pie, dentro
        cx, cz = M.rng.randint(-60, 56), M.rng.randint(-T - 10, -T - 2)
        for x in range(cx, cx + M.rng.randint(2, 5)):
            for z in range(cz, cz + M.rng.randint(2, 4)):
                M.put(x, 0, z, P, PLASTER_D if (x + z) % 2 else BRICK_D)
                if M.hsh(x, 0, z) < 0.3: M.put(x, 1, z, P, BRICK)
    return M, {P: [0, 0, 0]}


# ---------------- esculturas ----------------

def plinth(M, w, h, col):
    box(M, -w, w, 0, h, -w, w, col)
    box(M, -w - 1, w + 1, h, h + 2, -w - 1, w + 1, col)


def escultura_1():
    """Figura de escayola de pie, a medio desbastar: arriba acabada, abajo un bloque."""
    M = Model(S=2, seed=73)
    plinth(M, 9, 16, WOOD_D)
    box(M, -7, 7, 18, 34, -6, 6, lambda x, y, z: PLASTER_D if M.noise(x, y, z, 3.0) > 0.5 else PLASTER)  # bloque sin tallar
    M.sell(0, 40 / 2, 0, 5 / 2, 8 / 2, 4 / 2, P, PLASTER, p=2.5)   # torso
    M.ell(0, 52 / 2, 1 / 2, 3.2 / 2, 3.8 / 2, 3.2 / 2, P, PLASTER)  # cabeza
    for s in (-1, 1):
        M.capsule((s * 5 / 2, 46 / 2, 0), (s * 8 / 2, 36 / 2, 3 / 2), 1.4 / 2, 1.2 / 2, P, PLASTER)
    return M, {P: [0, 0, 0]}


def escultura_2():
    """Busto de arcilla oscura sobre una peana: cabeza calva, ojos hundidos y algo que le
    crece de la barbilla."""
    M = Model(S=2, seed=74)
    plinth(M, 6, 28, WOOD)
    M.sell(0, 34 / 2, 0, 7 / 2, 5 / 2, 5 / 2, P, CLAY, p=2.5)       # hombros
    M.ell(0, 44 / 2, 0, 4.5 / 2, 6 / 2, 5 / 2, P, CLAY)             # cabeza
    for x in (-2, 1):
        for y in (45, 46): M.put(x, y, 5, P, CLAY_D)               # ojos hundidos
    for i in range(5):                                          # tentáculos de barro de la barbilla
        for k in range(7): M.put(-2 + i, 40 - k, 4 + k // 3, P, CLAY_D if k % 2 else CLAY)
    for k, v in list(M.V.items()):
        if v[1] == CLAY and M.noise(*k, 2.0) > 0.7: M.V[k] = [P, CLAY_L, 0]
    return M, {P: [0, 0, 0]}


def caballete():
    M = Model(S=2, seed=75)
    for s in (-1, 1):                                           # patas
        for y in range(0, 60):
            M.put(s * (10 - y // 8), y, -y // 10, P, WOOD); M.put(s * (10 - y // 8), y, -y // 10 + 1, P, WOOD)
    for y in range(0, 52): M.put(0, y, -6 + y // 6, P, WOOD_D)  # pata trasera
    for x in range(-12, 12):                                    # lienzo: mar negro y una ciudad de ángulos
        for y in range(22, 50):
            c = CANVAS if x in (-12, 11) or y in (22, 49) else (SEA if y < 32 else (SEA_L if (x + y) % 5 == 0 else SEA))
            if 32 <= y < 44 and abs(x - 2) < 6 and (y - 32) < 12 - abs(x - 2) * 1.6: c = CITY
            M.put(x, y, -y // 10 + 2, P, c)
    for x in range(-13, 13): M.put(x, 21, -1, P, WOOD_D)        # repisa
    return M, {P: [0, 0, 0]}


def mesa():
    M = Model(S=2, seed=76)
    box(M, -30, 30, 26, 29, -14, 14, lambda x, y, z: WOOD if (x // 6) % 2 else WOOD_D)
    for x in (-27, 26):
        for z in (-11, 10): box(M, x, x + 2, 0, 26, z, z + 2, WOOD_D)
    M.sell(-10 / 2, 32 / 2, 0, 7 / 2, 3 / 2, 6 / 2, P, CLAY, p=2.2)  # montón de barro
    for i in range(4):                                          # herramientas de modelar
        for k in range(8): M.put(8 + i * 3, 29, -4 + k, P, IRON_L if k < 2 else WOOD)
    box(M, 18, 25, 29, 37, -4, 3, IRON)                         # cubo
    box(M, -24, -16, 29, 30, 4, 12, (0.70, 0.66, 0.60))         # trapos
    return M, {P: [0, 0, 0]}


def relieve():
    """El bajorrelieve: tablilla de arcilla de unos 60 x 50 cm en un soporte inclinado, con
    la figura (cabeza de pulpo, alas, cuerpo escamoso) ante una arquitectura ciclópea y
    jeroglíficos alrededor."""
    M = Model(S=2, seed=77)
    for s in (-1, 1):                                           # soporte
        for y in range(0, 44): M.put(s * 10, y, -y // 8, P, WOOD_D); M.put(s * 10 + s, y, -y // 8, P, WOOD_D)
    for x in range(-10, 11): M.put(x, 24, -2, P, WOOD_D)
    for x in range(-9, 10):                                     # tablilla
        for y in range(26, 46):
            z = -y // 8
            c = CLAY
            if x in (-9, 9) or y in (26, 45): c = CLAY_D
            elif (x * 5 + y * 3) % 7 == 0 and (abs(x) > 6 or y > 41): c = CLAY_D   # jeroglíficos
            M.put(x, y, z, P, c)
            if c == CLAY and abs(x) < 6 and 28 < y < 41: M.put(x, y, z + 1, P, CLAY_L if (x + y) % 3 else CLAY)   # figura en relieve
    for x in range(-2, 3):                                      # cabeza de pulpo de la figura
        for y in range(36, 40): M.put(x, y, -y // 8 + 2, P, CLAY_L)
    for x in (-2, 0, 2):
        for y in range(31, 36): M.put(x, y, -y // 8 + 2, P, CLAY_D)
    return M, {P: [0, 0, 0]}


def sacos():
    M = Model(S=2, seed=78)
    for i, (cx, cz) in enumerate(((-8, 0), (2, -4), (-2, 8))):
        M.sell(cx / 2, 8 / 2, cz / 2, 7 / 2, 8 / 2, 6 / 2, P, SACK, p=2.2)
    for y in range(0, 30):                                      # barril
        r = 8 + (2 if 8 < y < 22 else 0)
        for x in range(-r, r):
            for z in range(-r, r):
                if x * x + z * z <= r * r and (x * x + z * z >= (r - 2) ** 2 or y in (0, 29)):
                    M.put(14 + x, y, 4 + z, P, IRON if y in (4, 25) else WOOD)
    for k, v in list(M.V.items()):
        if v[1] == SACK and M.noise(*k, 3.0) > 0.6: M.V[k] = [P, SACK_D, 0]
    return M, {P: [0, 0, 0]}


def lampara():
    M = Model(S=2, seed=79)
    box(M, -6, 6, 0, 2, -6, 6, BRASS)
    for y in range(2, 52): M.put(0, y, 0, P, BRASS); M.put(-1, y, 0, P, BRASS)
    for y in range(52, 62):                                     # pantalla
        r = 4 + (62 - y) // 2
        for x in range(-r, r):
            for z in range(-r, r):
                if r - 1.5 <= math.hypot(x, z) <= r: M.put(x, y, z, P, SHADE, glow=1)
    for y in range(52, 56): M.put(0, y, 0, P, LIGHT, glow=1)
    return M, {P: [0, 0, 0], 'light': [0, 52, 0]}


def pilar():
    M = Model(S=2, seed=80)
    for y in range(0, 128):
        r = 4 if 8 < y < 118 else 7
        for x in range(-r, r):
            for z in range(-r, r):
                if abs(x + 0.5) + abs(z + 0.5) <= r * 1.3: M.put(x, y, z, P, IRON_L if (x + z + y // 3) % 7 == 0 else IRON)
    return M, {P: [0, 0, 0]}


PIECES = {'muro': muro, 'muro_bajo': muro_bajo, 'escultura_1_mano': escultura_1,   # la del juego es de Replicate
           'escultura_2': escultura_2,
          'caballete': caballete, 'mesa': mesa, 'relieve': relieve, 'sacos': sacos, 'lampara': lampara,
          'pilar': pilar}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/prv_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.85, specular=0.3, no_bottom=True)
        print('prv_%s: %d voxels' % (name, n))
