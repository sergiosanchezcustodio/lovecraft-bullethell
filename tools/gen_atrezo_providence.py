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


CLAY_X = (0.58, 0.47, 0.36); CLAY_W = (0.34, 0.25, 0.18)


def relieve():
    """El bajorrelieve de Wilcox (rehecho a 128/m en la revisión de arte del 13-10-2026): tablilla
    de arcilla de unos 60 x 50 cm en un caballete de tres patas. En relieve, la figura del sueño
    (cabeza de pulpo con ojos hundidos, tentáculos que le caen sobre el pecho, cuerpo escamoso,
    brazos con garras y alas membranosas) ante una arquitectura ciclópea de ángulos que no
    cuadran, y un marco con jeroglíficos. Arcilla con marcas de los dedos, más clara en lo alto y
    oscura en los huecos; migas de barro y un palillo de modelar en la repisa."""
    M = Model(S=8, seed=77)
    V = 128
    TW, TH, T0 = int(0.31 * V), int(0.52 * V), int(0.72 * V)        # semiancho, alto, altura de la base
    lean = 0.22                                                      # se inclina hacia atrás
    def zb(y): return -int((y - T0) * lean)
    def height(a, b):
        """Altura del relieve (voxels) en el punto (a, b) de la tablilla: a en [-1, 1], b en [0, 1]."""
        if abs(a) > 0.9 or b < 0.07 or b > 0.93:                     # marco con jeroglíficos
            fr = 4
            u = (a + 1) * 22 if (b < 0.07 or b > 0.93) else b * 30
            cell = int(u) % 3
            if (abs(a) > 0.9 and 0.08 < (abs(a) - 0.9) < 0.07 + 0.02 * cell) or ((b < 0.07 or b > 0.93) and int(u * 3) % 4 == 1 and 0.02 < (b if b < 0.07 else 1 - b) < 0.055):
                fr = 2                                               # trazos hundidos
            return fr
        h = 1.0
        # arquitectura de fondo: bloques en rejilla torcida y dos monolitos que se inclinan
        gu = a * 6 + b * 2.2; gv = b * 7 - a * 1.3
        if (gu % 1) < 0.08 or (gv % 1) < 0.08: h = 0.4
        else: h = 1.4 + 0.6 * ((int(gu) * 7 + int(gv) * 3) % 3) / 2
        for mx, tilt in ((-0.68, 0.18), (0.66, -0.22)):
            if abs(a - mx - tilt * (b - 0.5)) < 0.09 and b < 0.85 - 0.1 * abs(tilt) * (a - mx) * 10: h = 3.2
        # alas membranosas: desde los hombros, con nervios en abanico y el borde festoneado
        for s in (-1, 1):
            wa = s * a
            if 0.18 < wa < 0.88:
                lo = 0.30 + 0.32 * (wa - 0.18) + 0.04 * abs(math.sin((wa - 0.18) * 13))
                hi = 0.92 - 0.10 * (wa - 0.18)
                if lo < b < hi:
                    ang = math.atan2(b - 0.62, wa - 0.18)
                    rib = any(abs(ang - r) < 0.035 for r in (-0.55, -0.15, 0.25, 0.65))
                    h = max(h, 3.5 + (1.5 if rib else 0.0) - 1.5 * (wa - 0.18))
        # cuerpo escamoso y brazos
        if abs(a) < 0.26 - 0.1 * (0.55 - b) and 0.12 < b < 0.55:
            sc = ((int(a * 40) + int(b * 34)) % 2)
            h = max(h, 5.0 - sc * 0.8)
        for s in (-1, 1):
            if abs(a - s * (0.3 - 0.25 * (0.5 - b))) < 0.05 and 0.18 < b < 0.5: h = max(h, 5.5)
            if abs(a - s * 0.18) < 0.05 and 0.12 < b < 0.2: h = max(h, 6.0 - 3 * abs(a - s * 0.18) * 10)   # garras
        # cabeza de pulpo
        hd = (a / 0.21) ** 2 + ((b - 0.71) / 0.19) ** 2
        if hd < 1: h = max(h, 7.0 + 4.0 * math.sqrt(1 - hd))
        for s in (-1, 1):                                            # ojos hundidos
            if (a - s * 0.07) ** 2 / 0.0015 + (b - 0.66) ** 2 / 0.0009 < 1: h -= 3.5
        # tentáculos que caen sobre el pecho
        for k in range(7):
            tx = (k - 3) * 0.055
            cx = tx + 0.03 * math.sin(b * 20 + k) + tx * (0.6 - b) * 0.8
            if 0.3 < b < 0.6 and abs(a - cx) < 0.022 * (0.4 + (b - 0.3) * 3): h = max(h, 7.0)
        return h
    for y in range(T0, T0 + TH):                                    # tablilla
        b = (y - T0) / TH
        for x in range(-TW, TW):
            a = x / TW
            h = height(a, b)
            z0 = zb(y)
            for zz in range(-4, int(round(h)) + 1):
                c = CLAY
                if zz == int(round(h)):
                    c = lerp(CLAY_W, CLAY_X, min(1.0, (h - 0.5) / 8.0) ** 0.8)   # más clara en lo alto
                    if M.noise(x, y, zz, 3.0) > 0.7: c = lerp(c, CLAY_D, 0.3)   # marcas de los dedos
                    if h < 1.2: c = CLAY_W                           # huecos oscuros
                elif zz < 0: c = CLAY_D
                M.put(x, y, z0 + zz, P, c)
    # caballete de tres patas con repisa
    for s in (-1, 1):
        for y in range(0, T0 + TH + 10):
            x = s * (TW - 4) + int(s * (T0 - y) * 0.08) if y < T0 else s * (TW - 4)
            z = zb(y) - 6
            for dx in range(-2, 3):
                for dz in range(-2, 2): M.put(x + dx, y, z + dz, P, WOOD if abs(dx) < 2 else WOOD_D)
    for y in range(0, T0 + int(TH * 0.6)):                         # pata de atrás
        z = -int((T0 + TH * 0.6 - y) * 0.45) - 10
        for dx in range(-2, 3):
            for dz in range(-2, 2): M.put(dx, y, z + dz, P, WOOD_D)
    for x in range(-TW - 6, TW + 6):                                 # repisa y travesaño
        for z in range(zb(T0) - 8, zb(T0) + 12):
            for y in (T0 - 4, T0 - 3, T0 - 2):
                M.put(x, y, z, P, WOOD if y > T0 - 4 else WOOD_D)
        M.put(x, T0 - 1, zb(T0) + 11, P, WOOD_D); M.put(x, T0, zb(T0) + 11, P, WOOD_D)
        for y in (int(T0 * 0.35), int(T0 * 0.35) + 1, int(T0 * 0.35) + 2):
            M.put(x, y, zb(T0) - 6, P, WOOD_D)
    for k in range(40):                                               # palillo de modelar y migas
        M.put(10 + k, T0 - 1, zb(T0) + 6 + k // 14, P, (0.60, 0.48, 0.32))
    for _ in range(30):
        x = M.rng.randint(-TW, TW); z = M.rng.randint(zb(T0) - 6, zb(T0) + 10)
        M.put(x, T0 - 1, z, P, CLAY_D)
    for _ in range(40):
        x = M.rng.randint(-TW - 20, TW + 20); z = M.rng.randint(-40, 40)
        M.put(x, 0, z, P, CLAY_D if M.rng.random() < 0.6 else CLAY)
    return M, {P: [0, 0, 0]}


BURLAP = (0.56, 0.47, 0.32); BURLAP_D = (0.42, 0.34, 0.22); BURLAP_L = (0.66, 0.58, 0.42)
TWINE = (0.36, 0.28, 0.18); STENCIL = (0.20, 0.16, 0.12)


def _sack(M, cx, cz, rx, ry, rz, yaw, seed, open_top=False, fallen=False):
    """Saco de arpillera lleno de barro: cuerpo blando que se aplasta abajo, trama de la tela,
    pliegues, costura, cuello atado con bramante (o abierto con el barro asomando) y una franja
    estarcida (las letras parecían una cara)."""
    ca, sa = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    R = int(max(rx, rz) * (1.6 if fallen else 1.2)) + 4
    top_y = int(ry * 2.1)
    for x in range(-R, R + 1):
        for z in range(-R, R + 1):
            u = x * ca + z * sa; w = -x * sa + z * ca
            for y in range(0, top_y + 8):
                if fallen:
                    uu, yy = u / (rx * 1.5), (y - ry * 0.8) / (ry * 0.8)
                    d = uu * uu + yy * yy + (w / rz) ** 2
                else:
                    f = y / (ry * 2)
                    bulge = 1.0 + 0.15 * math.sin(f * math.pi) - 0.25 * max(0.0, f - 0.75) * 4
                    d = (u / (rx * bulge)) ** 2 + (w / (rz * bulge)) ** 2 + max(0.0, (y - ry * 1.6) / (ry * 0.5)) ** 2
                    if y > ry * 1.95:                                    # cuello
                        d = (u / (rx * 0.32)) ** 2 + (w / (rz * 0.32)) ** 2
                        if y > top_y + 4: d = 9
                if d > 1: continue
                if d < 0.75 and y > 0: continue
                weave = (int(u) + int(y)) % 2
                c = BURLAP if weave else BURLAP_D
                if M.noise(cx + x, y, cz + z, 4.0) > 0.68: c = lerp(c, BURLAP_D, 0.5)          # pliegues y sombra
                if M.noise(cx + x, y, cz + z, 2.0) > 0.86: c = BURLAP_L
                if abs(w) < 1 and not fallen and y < ry * 1.9: c = lerp(c, TWINE, 0.4)          # costura
                if not fallen and ry * 1.95 < y < ry * 2.05: c = TWINE                         # atado
                if not fallen and abs(u) < rx * 0.55 and abs(y - ry * 0.85) < 1.2 and w > 0: c = STENCIL   # franja estarcida
                if y < 3: c = lerp(c, CLAY_D, 0.5)
                M.put(cx + x, y, cz + z, P, c)
    if open_top or fallen:                                                # barro que asoma
        ox = int(rx * 1.5 * ca) if fallen else 0; oz = int(rx * 1.5 * sa) if fallen else 0
        for x in range(-6, 7):
            for z in range(-6, 7):
                if x * x + z * z > 30: continue
                y = (int(ry * 0.8) if fallen else top_y) + 1 + (1 if M.hsh(x, z, 1) > 0.6 else 0)
                M.put(cx + ox + x, y, cz + oz + z, P, CLAY if M.hsh(x, z, 2) > 0.3 else CLAY_D)


def sacos():
    """Sacos de barro del escultor (rehechos a 64/m en la revisión de arte del 13-10-2026): tres
    de arpillera de tamaños distintos, uno abierto con el barro asomando y otro caído, una tina de
    duelas con el barro húmedo y una paleta clavada, y pellas y salpicaduras por el suelo."""
    M = Model(S=4, seed=78)
    _sack(M, -16, 0, 13, 15, 11, 15, 1)
    _sack(M, 6, -10, 11, 13, 10, -20, 2, open_top=True)
    _sack(M, -4, 18, 11, 9, 9, 70, 3, fallen=True)
    for y in range(0, 50):                                           # tina
        r = 16 + (2 if 12 < y < 38 else 0)
        for x in range(-r, r + 1):
            for z in range(-r, r + 1):
                d = x * x + z * z
                if d > r * r or (d < (r - 2) ** 2 and y > 0): continue
                a = math.atan2(z, x)
                c = WOOD if int((a + math.pi) / math.tau * 20) % 2 else WOOD_D
                if y in (6, 7, 42, 43): c = IRON_L
                M.put(30 + x, y, 8 + z, P, c)
    for x in range(-14, 15):                                         # barro húmedo dentro
        for z in range(-14, 15):
            if x * x + z * z < 196:
                for y in range(40, 46 + (1 if M.noise(x, 0, z, 3.0) > 0.6 else 0)):
                    M.put(30 + x, y, 8 + z, P, CLAY_D if M.hsh(x, z, 3) > 0.3 else CLAY)
    for k in range(40):                                              # paleta clavada
        M.put(34 + k // 6, 46 + k, 6, P, WOOD); M.put(35 + k // 6, 46 + k, 6, P, WOOD)
    for _ in range(26):                                              # pellas y salpicaduras
        x, z = M.rng.randint(-40, 52), M.rng.randint(-30, 40)
        s = M.rng.randint(1, 4)
        for dx in range(s):
            for dz in range(s): M.put(x + dx, 0, z + dz, P, CLAY_D if M.rng.random() < 0.5 else CLAY)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
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
