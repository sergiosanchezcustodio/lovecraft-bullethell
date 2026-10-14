"""Atrezo del estudio de Wilcox en el edificio Fleur-de-Lys de Providence (hito 7.1). Una
parte "body", origen en el centro de la base.

  muro        pared del estudio: ladrillo con ventanales altos de noche, cornisa y tuberías
              (12 m de largo y 4 de alto; 16/m: pieza de borde)
  muro_bajo   el arranque de la pared por el lado de la cámara: zócalo de ladrillo (32/m)
  escultura_1 figura de escayola sobre un plinto, a medio desbastar (32/m)
  escultura_2 busto de mármol con tentáculos por barba sobre una columna gris (80/m)
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
    """Busto de mármol sobre una columna de piedra gris (rehecho a 80/m en la revisión de arte del
    14-10-2026). Peana: basa con molduras, fuste acanalado, capitel y una placa de latón. Busto
    clásico de mármol blanco con vetas grises: hombros con el manto en pliegues y una fíbula,
    cuello, cabeza con rizos tallados, cejas, nariz, ojos vacíos de estatua, orejas y, en vez de
    barba, un manojo de tentáculos que cae sobre el pecho: lo inquietante del estudio de Wilcox."""
    M = Model(S=5, seed=74)                                          # 80/m: 1,9 m en total
    STN = (0.42, 0.44, 0.48); STN_D = (0.32, 0.34, 0.37); STN_L = (0.54, 0.56, 0.60)   # gris frío: la luz es cálida
    MAR = (0.84, 0.86, 0.90); MAR_S = (0.68, 0.70, 0.75); VEIN = (0.50, 0.52, 0.58)
    def stone(x, y, z):
        c = lerp(STN, STN_D, 0.6 * M.noise(x, y, z, 3.0))
        if M.hsh(x, y, z) > 0.8: c = lerp(c, STN_L, 0.5)
        return c
    def marble(x, y, z):
        c = lerp(MAR, MAR_S, 0.35 * M.noise(x, y, z, 6.0))
        n = M.noise(x + 0.6 * y, y, z - 0.4 * y, 5.0)
        if abs(n - 0.5) < 0.018: c = lerp(c, VEIN, 0.6)                               # vetas
        return c
    def sq(x0, x1, y0, y1, col):                                                     # bloque cuadrado centrado
        for y in range(y0, y1):
            for x in range(-x0, x0):
                for z in range(-x0, x0):
                    if max(abs(x + 0.5), abs(z + 0.5)) > x1: continue
                    M.put(x, y, z, P, col(x, y, z))
    # peana
    sq(26, 26, 0, 5, stone)
    sq(24, 24, 5, 8, lambda x, y, z: STN_L)
    for y in range(8, 12):                                                           # toro redondeado
        r = 22 - abs(y - 10) // 2
        sq(r, r, y, y + 1, stone)
    for y in range(12, 64):                                                          # fuste acanalado
        for x in range(-18, 18):
            for z in range(-18, 18):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > 17: continue
                a = math.atan2(z + 0.5, x + 0.5)
                if d > 15.5 and math.cos(a * 16) > 0.55: continue                      # estrías
                c = stone(x, y, z)
                if d > 15.5 and math.cos(a * 16) > 0.2: c = lerp(c, STN_D, 0.5)
                M.put(x, y, z, P, c)
    for y in range(64, 70):                                                          # capitel
        r = 18 + (y - 64)
        sq(r, r, y, y + 1, lambda x, y, z: STN_L if y == 69 else stone(x, y, z))
    sq(25, 25, 70, 74, stone)
    for x in range(-8, 8):                                                           # placa de latón
        for y in range(40, 48):
            c = (0.62, 0.50, 0.26) if x not in (-8, 7) and y not in (40, 47) else (0.40, 0.30, 0.14)
            if 42 <= y <= 45 and x % 3 != 0 and -6 < x < 6 and y != 44: c = (0.34, 0.26, 0.12)
            M.put(x, y, 17, P, c)
    # busto
    B = 74
    TENT = (0.64, 0.66, 0.71); TENT_D = (0.50, 0.52, 0.58); PUPIL = (0.30, 0.32, 0.38)
    for y in range(B, B + 9):                                                        # pie redondo del busto
        r = 10 - (y - B) // 3 + (1 if y == B else 0)
        for x in range(-r, r + 1):
            for z in range(-r, r + 1):
                if x * x + z * z <= r * r: M.put(x, y, z, P, MAR_S if y in (B, B + 1) else marble(x, y, z))
    for x in range(-33, 34):                                                         # hombros y pecho, corte en arco
        for y in range(B + 7, B + 42):
            for z in range(-16, 17):
                if abs(x / 32) ** 2.6 + abs((y - B - 25) / 16) ** 2.6 + abs(z / 15) ** 2.6 > 1: continue
                if y < B + 8 + 16 * (x / 32) ** 2: continue
                c = marble(x, y, z)
                k = (x + 1.1 * (y - B)) % 10                                            # manto en pliegues, del hombro izquierdo
                if x > -10 and z > 0 and (k < 1.5 or (x > 12 and k < 3)): c = MAR_S
                if x <= -10 and z > 4 and (y - B) % 7 == 0: c = lerp(c, MAR_S, 0.6)     # túnica
                M.put(x, y, z, P, c)
    for x in range(-25, -14):                                                        # fíbula en el hombro
        for y in range(B + 28, B + 39):
            d = (x + 20) ** 2 + (y - B - 33) ** 2
            if d > 25: continue
            for z in range(20, -1, -1):
                if (x, y, z) in M.V:
                    M.put(x, y, z + 1, P, MAR_S if d > 12 else MAR)
                    if d < 5: M.put(x, y, z + 2, P, MAR)
                    break
    for y in range(B + 36, B + 52):                                                  # cuello
        for x in range(-9, 10):
            for z in range(-9, 10):
                if x * x + (z - 1) ** 2 <= 76: M.put(x, y, z, P, marble(x, y, z))
    HY = B + 64
    for x in range(-14, 15):                                                         # cabeza
        for y in range(HY - 18, HY + 18):
            for z in range(-16, 17):
                yy = y - HY
                rx = 12.5 if yy > -6 else 12.5 - 4 * ((-6 - yy) / 12) ** 1.4           # mandíbula que se estrecha
                ry = 16.5 if yy > 0 else 17.5
                if abs(x / rx) ** 2.3 + abs(yy / ry) ** 2.3 + abs((z - 1) / 14) ** 2.3 > 1: continue
                M.put(x, y, z, P, marble(x, y, z))
    def front(x, y):
        for z in range(30, -24, -1):
            if (x, y, z) in M.V: return z
        return None
    for y in range(HY + 6, HY + 19):                                                 # pelo en rizos: casco tallado
        for x in range(-15, 16):
            for z in range(-17, 18):
                yy = y - HY
                if abs(x / 13.5) ** 2.3 + abs(yy / 18) ** 2.3 + abs((z - 0.5) / 15.5) ** 2.3 > 1: continue
                if (x, y, z) in M.V: continue
                M.put(x, y, z, P, MAR)
    for y in range(HY - 6, HY + 6):                                                  # pelo por detrás y los lados
        for x in range(-15, 16):
            for z in range(-17, 3):
                if abs(x / 13.5) ** 2.3 + abs((y - HY) / 18) ** 2.3 + abs((z - 0.5) / 15.5) ** 2.3 > 1: continue
                if (x, y, z) not in M.V: M.put(x, y, z, P, MAR)
    bumps = []
    for (x, y, z), v in M.V.items():                                                 # rizos: un bucle en relieve por celda
        if y < HY - 6 or (y < HY + 7 and z > 3): continue
        if abs(x / 13.5) ** 2.3 + abs((y - HY) / 18) ** 2.3 + abs((z - 0.5) / 15.5) ** 2.3 < 0.8: continue
        a = math.atan2(z, x); cu, cv = a * 4.2 + (0.5 if int((y - HY) / 3.4) % 2 else 0), (y - HY) / 3.4
        if y >= HY + 13: cu, cv = x / 3.4 + (0.5 if int(z / 3.4 + 20) % 2 else 0), z / 3.4         # coronilla
        fu, fv = cu - math.floor(cu) - 0.5, cv - math.floor(cv) - 0.5
        r = math.hypot(fu, fv)
        v[1] = MAR_S if r > 0.36 else MAR
        if r < 0.24:
            n = math.sqrt(x * x + (y - HY) ** 2 + z * z) or 1
            bumps.append((int(round(x + x / n)), int(round(y + (y - HY) / n)), int(round(z + z / n))))
    for q in bumps: M.put(*q, P, MAR, over=False)
    for x in range(-11, 12):                                                         # cejas en relieve y su sombra
        if abs(x) < 2: continue
        f = front(x, HY + 5)
        if f is None: continue
        for y in (HY + 4, HY + 5): M.put(x, y, f + 1, P, MAR)
        g = front(x, HY + 3)
        if g is not None: M.V[(x, HY + 3, g)] = [P, MAR_S, 0]
    for s in (-1, 1):                                                                # ojos: cuenca en sombra y pupila taladrada
        for x in range(s * 2, s * 10, s):
            for y in range(HY - 1, HY + 3):
                f = front(x, y)
                if f is None: continue
                ex = (x - s * 5.5) ** 2 / 10 + (y - HY - 1) ** 2 / 3
                if ex < 1: M.V[(x, y, f)] = [P, MAR if ex < 0.6 else MAR_S, 0]
                if abs(x - s * 5.5) < 1.1 and y in (HY, HY + 1): M.V[(x, y, f)] = [P, PUPIL, 0]
    for y in range(HY - 8, HY + 4):                                                  # nariz
        w = 1 if y > HY - 5 else 2
        for x in range(-w, w + 1):
            f = front(x, y)
            if f is None: continue
            M.put(x, y, f + 1, P, MAR)
            if y < HY - 3 and abs(x) < 2: M.put(x, y, f + 2, P, MAR)
    for x in (-2, 2): M.V[(x, HY - 8, front(x, HY - 8))] = [P, PUPIL, 0]           # aletas de la nariz
    for s in (-1, 1):                                                                # orejas
        for y in range(HY - 7, HY + 4):
            for z in range(-3, 3):
                M.put(s * 13, y, z, P, MAR_S if (z in (-1, 0) and HY - 5 < y < HY + 2) else MAR)
    surf = {}
    for x in range(-24, 25):
        for y in range(B + 8, HY):
            f = front(x, y)
            if f is not None: surf[(x, y)] = f
    for k in range(6):                                                               # tentáculos donde iría la barba
        x0 = -7.0 + 2.8 * k
        y0 = HY - 9 - (2 if k in (0, 5) else 0)
        L = 30 + 8 * ((k * 5) % 3) - int(abs(k - 2.5)) * 3
        zp = None
        side = 1 if x0 > 0 else -1
        for i in range(L):
            u = i / L
            x = x0 * (1 + 0.6 * u) + 2.2 * math.sin(u * 6 + k * 1.7) * u
            y = y0 - i
            if i > L - 7: x += (i - L + 7) * 0.9 * side; y += (i - L + 7) * 0.5          # la punta se enrosca hacia fuera
            r = 2.2 * (1 - u) + 0.9
            xi, yi = int(round(x)), int(round(y))
            zc = surf.get((xi, yi), 10) + r * 0.7
            if zp is not None: zc = max(zc, zp - 0.5)                                  # cuelga: no se mete hacia el cuello
            zp = zc
            for dx in range(-4, 5):
                for dz in range(-4, 5):
                    if dx * dx + dz * dz > r * r: continue
                    c = TENT if dx * side <= 0 or dx * dx + dz * dz < (r - 1) ** 2 else TENT_D
                    if dz > r - 1.2 and i % 4 == 0 and abs(dx) < 1: c = MAR                  # ventosas
                    M.put(xi + dx, yi, int(round(zc)) + dz, P, c)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


def caballete():
    """Caballete de Wilcox con un lienzo (rehecho a 64/m en la revisión de arte del 13-10-2026):
    tres patas de listón con tornillo de ajuste y travesaños, repisa con una paleta llena de
    manchas de color, pinceles y un trapo; el lienzo sobre su bastidor, con el borde sin pintar y
    las chinchetas, muestra la silueta negra de Cthulhu (cabeza de pulpo, tentáculos y alas)
    alzándose de un mar negro entre torres de ángulos imposibles, bajo un cielo verde enfermo; salpicaduras de pintura en el suelo."""
    M = Model(S=4, seed=75)
    rng = M.rng
    LEAN = 0.18
    H = 132
    def zl(y): return -int(y * LEAN)
    for s in (-1, 1):                                                                # patas delanteras
        for y in range(0, H):
            x = s * (24 - y // 10)
            for dx in range(-1, 2):
                for dz in (0, 1): M.put(x + dx, y, zl(y) + dz, P, WOOD if dx else WOOD_D)
    YT = int(H * 0.85)                                                               # pata trasera, siempre detrás del lienzo
    for y in range(0, YT):
        z = -int(0.55 * (YT - y)) + zl(YT) - 2
        for dx in (-1, 0, 1):
            for dz in (0, -1): M.put(dx, y, z + dz, P, WOOD_D)
    for x in range(-22, 23):                                                         # travesaño y tornillo
        M.put(x, 30, zl(30), P, WOOD_D); M.put(x, 31, zl(31), P, WOOD_D)
    for k in range(5): M.put(-2 + k, 70, zl(70) + 2, P, IRON)
    TY = 54                                                                          # repisa
    for x in range(-30, 31):
        for z in range(zl(TY) - 2, zl(TY) + 8):
            M.put(x, TY, z, P, WOOD); M.put(x, TY - 1, z, P, WOOD_D)
        M.put(x, TY + 1, zl(TY) + 7, P, WOOD_D)
    PAL = [(0.62, 0.12, 0.10), (0.16, 0.24, 0.40), (0.86, 0.80, 0.62), (0.20, 0.36, 0.20), (0.08, 0.08, 0.08), (0.70, 0.56, 0.20)]
    for x in range(8, 28):                                                           # paleta
        for z in range(zl(TY), zl(TY) + 7):
            if ((x - 18) / 10) ** 2 + ((z - zl(TY) - 3) / 3.5) ** 2 < 1:
                c = (0.60, 0.46, 0.28)
                if M.hsh(x // 3, z // 2, 3) > 0.55: c = PAL[int(M.hsh(x // 3, z, 4) * 6)]
                M.put(x, TY + 1, z, P, c)
    for k, xb in enumerate((-24, -20, -16)):                                          # pinceles
        for j in range(14): M.put(xb + j // 7, TY + 1, zl(TY) + 1 + j // 3, P, (0.56, 0.44, 0.30) if j < 11 else PAL[k])
    for x in range(-12, -2):                                                         # trapo
        for z in range(zl(TY), zl(TY) + 6): M.put(x, TY + 1 + (x + z) % 2, z, P, lerp(CANVAS, PAL[(x * z) % 6], 0.3))
    def monster(a, b):
        """Silueta de Cthulhu que se alza del mar: cabeza de pulpo, barba de tentáculos,
        hombros encorvados y alas de murciélago abiertas. Devuelve 0 (fuera), 1 (silueta) o 2 (ojo)."""
        for k in range(-3, 4):                                                       # tentáculos de la cara, con brillo húmedo
            tx = k * 0.04 + 0.025 * math.sin(b * 22 + k)
            if 0.36 < b < 0.60 and abs(a - tx) < 0.012: return 3
        hx, hy = a / 0.17, (b - 0.68) / 0.17                                         # cabeza
        if hx * hx + hy * hy < 1:
            if abs(abs(a) - 0.06) < 0.025 and abs(b - 0.64) < 0.012: return 2
            return 1
        if ((a / 0.36) ** 2 + ((b - 0.40) / 0.16) ** 2) < 1 and b < 0.52: return 1    # hombros y cuerpo
        if b < 0.30: return 0
        for k in range(-3, 4):                                                       # tentáculos de la cara
            tx = k * 0.045 + 0.03 * math.sin(b * 22 + k)
            if 0.40 < b < 0.58 and abs(a - tx) < 0.018 + 0.02 * (b - 0.40): return 1
        for s in (-1, 1):                                                            # alas
            u = s * a
            if u < 0.2 or u > 0.92: continue
            top = 0.50 + 0.50 * (u - 0.2) / 0.72                                     # borde de ataque hacia arriba
            bot = 0.46 + 0.06 * abs(math.sin((u - 0.2) * 13))                         # festón de la membrana
            if bot < b < top and b < 0.98: return 1
            if abs(b - top) < 0.012 and u < 0.94: return 1
        return 0
    def paint(a, b, x, y):
        if b < 0.30:                                                                 # mar negro con oleaje
            c = SEA if (x + int(6 * math.sin(y * 0.7 + x * 0.1))) % 9 else SEA_L
            if b > 0.27 and abs(a) < 0.4: c = lerp(c, (0.30, 0.40, 0.24), 0.4)      # reflejo bajo la figura
            return c
        m = monster(a, b)
        if m == 2: return (0.86, 0.70, 0.20)
        if m == 1: return lerp((0.03, 0.04, 0.03), (0.08, 0.10, 0.07), M.noise(x, y, 0, 3.0))
        if m == 3: return (0.16, 0.22, 0.13)
        if b < 0.38 and abs(a) > 0.45 and (int(a * 30 - b * 12) % 4) and abs(a) < 0.9:   # torres de R'lyeh a los lados
            if b < 0.30 + 0.08 * M.hsh(int(a * 12), 0, 5): return lerp(CITY, (0.06, 0.08, 0.06), 0.4)
        g = 1 - b                                                                    # cielo verde enfermo, más claro al horizonte
        return lerp((0.12, 0.18, 0.10), (0.52, 0.58, 0.30), max(0.0, g - 0.15 + 0.15 * M.noise(x, y, 0, 4.0)))
    CW, CB, CT = 30, TY + 2, TY + 74                                                 # lienzo
    for y in range(CB, CT):
        b = (y - CB) / (CT - CB)
        for x in range(-CW, CW):
            a = x / CW
            edge = abs(x) >= CW - 2 or y < CB + 2 or y >= CT - 2
            if edge: c = CANVAS
            else: c = paint(a, b, x, y)
            if not edge and M.hsh(x // 2, y // 1, 7) > 0.92: c = lerp(c, (0, 0, 0), 0.2)         # pinceladas
            M.put(x, y, zl(y) + 3, P, c)
            M.put(x, y, zl(y) + 2, P, WOOD_D if edge else CANVAS)
    for (x, y) in ((-CW + 1, CB + 1), (CW - 2, CB + 1), (-CW + 1, CT - 2), (CW - 2, CT - 2)):
        M.put(x, y, zl(y) + 4, P, IRON)
    for _ in range(40):                                                              # salpicaduras en el suelo
        M.put(rng.randint(-30, 30), 0, rng.randint(-10, 30), P, PAL[rng.randrange(6)])
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


def mesa():
    """Mesa de trabajo del escultor (revisión de arte del 14-10-2026; la de antes queda en
    models/prv_mesa_v1.json). A 64 voxels/m, 1,8 x 1,1 x 0,8 m: tablero de tablones con juntas,
    canto y manchas de barro y escayola, patas torneadas con travesaños y una balda abajo con
    sacos y un balde; encima, una maqueta de barro a medio modelar (un busto con tentáculos), los
    palillos y vaciadores de modelar en fila, un compás, un trapo húmedo, un tarro con pinceles
    y un cuaderno abierto con un boceto."""
    V = 4
    M = Model(S=V, seed=76)
    rng = M.rng
    TOP = 52
    def plank(x, y, z):
        c = lerp(WOOD_D, (0.48, 0.35, 0.22), 0.3 + 0.5 * M.hsh(z // 8, 1, 1))
        c = lerp(c, WOOD_D, 0.3 * M.noise(x * 0.2, y, z * 2, 3.0))
        if z % 8 == 0: c = lerp(c, (0.10, 0.07, 0.05), 0.6)
        if M.noise(x, y, z, 5.0) > 0.72: c = lerp(c, PLASTER_D, 0.6)              # escayola
        elif M.noise(x + 50, y, z, 4.0) > 0.76: c = lerp(c, CLAY_D, 0.7)           # barro
        return c
    box(M, -58, 58, TOP, TOP + 5, -26, 26, plank)                                  # tablero
    box(M, -58, 58, TOP - 4, TOP, -24, 24, lambda x, y, z: WOOD_D)                  # faldón
    for sx in (-52, 50):                                                           # patas torneadas
        for sz in (-21, 19):
            for y in range(0, TOP - 4):
                r = 2.6 + (1.0 if y % 16 < 3 else 0) - (0.6 if y < 8 else 0)
                for x in range(-4, 5):
                    for z in range(-4, 5):
                        if math.hypot(x, z) <= r: M.put(sx + x + 1, y, sz + z + 1, P, WOOD if (y // 16) % 2 else WOOD_D)
    for y in (10, 11, 12):                                                         # travesaños y balda
        box(M, -52, 52, y, y + 1, -21, 22, lambda x, y, z: WOOD_D if (x // 10) % 2 else WOOD)
    for i, (cx, cz) in enumerate(((-30, 0), (-12, 4))):                            # sacos en la balda
        for x in range(cx - 9, cx + 9):
            for z in range(cz - 10, cz + 10):
                for y in range(13, 26):
                    if ((x - cx) / 9) ** 2 + ((z - cz) / 10) ** 2 + ((y - 13) / 13) ** 2 <= 1:
                        M.put(x, y, z, P, SACK if M.hsh(x, y, z) > 0.3 else SACK_D)
    for y in range(13, 28):                                                        # balde
        for a in range(0, 360, 10):
            r = 7 + (y - 13) * 0.15
            M.put(24 + r * math.cos(math.radians(a)), y, r * math.sin(math.radians(a)), P, IRON_L if y in (14, 27) else IRON)
    # maqueta de barro: peana, busto en bruto con cabeza de pulpo y tentáculos
    box(M, -44, -24, TOP + 5, TOP + 8, -10, 10, lambda x, y, z: WOOD_D)
    for y in range(TOP + 8, TOP + 40):
        for x in range(-46, -22):
            for z in range(-12, 12):
                u = y - TOP - 8
                if u < 14: rx, rz = 9 - u * 0.2, 7                                  # hombros
                else: rx, rz = 7 - (u - 14) * 0.18, 7 - (u - 14) * 0.15             # cabeza
                if ((x + 34) / max(rx, 1)) ** 2 + (z / max(rz, 1)) ** 2 <= 1:
                    c = lerp(CLAY, CLAY_L, M.noise(x, y, z, 2.0))
                    if M.hsh(x, y, z) < 0.04: c = CLAY_D                            # marcas de los dedos
                    M.put(x, y, z, P, c)
    for k in range(5):                                                             # tentáculos de la cara
        for i in range(10):
            M.put(-37 + k * 2 + int(math.sin(i * 0.6 + k) * 1.5), TOP + 26 - i, 7 + (i // 4), P, CLAY_D)
    for i in range(6):                                                             # palillos y vaciadores
        for k in range(22):
            c = WOOD if k > 4 else (IRON_L if i % 2 else WOOD_D)
            M.put(4 + i * 4, TOP + 5, -18 + k, P, c)
            if k < 3 and i % 2: M.put(4 + i * 4 + 1, TOP + 5, -18 + k, P, IRON_L)
    for k in range(18):                                                            # compás
        M.put(30 + k // 2, TOP + 5, 8 + k, P, BRASS); M.put(30 + k, TOP + 5, 8 + k // 3, P, BRASS)
    box(M, 38, 52, TOP + 5, TOP + 7, -22, -8, lambda x, y, z: (0.62, 0.60, 0.54) if M.hsh(x, y, z) > 0.3 else (0.52, 0.50, 0.46))   # trapo
    for y in range(TOP + 5, TOP + 16):                                             # tarro con pinceles
        for a in range(0, 360, 20):
            M.put(48 + 4 * math.cos(math.radians(a)), y, 14 + 4 * math.sin(math.radians(a)), P, GLASS_L)
    for k in range(4):
        for y in range(TOP + 10, TOP + 26):
            M.put(47 + k, y, 13 + (k % 2), P, WOOD if y < TOP + 23 else (0.15, 0.12, 0.10))
    for x in range(10, 34):                                                        # cuaderno con boceto
        for z in range(4, 20):
            c = (0.84, 0.80, 0.70)
            if x == 22: c = (0.40, 0.36, 0.30)
            elif ((x - 16) ** 2 + (z - 12) ** 2 < 16 and (x - 16) ** 2 + (z - 12) ** 2 > 8) or (x > 25 and (z + x) % 5 == 0): c = (0.20, 0.18, 0.16)
            M.put(x, TOP + 5, z, P, c)
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a2, k[1] + b2, k[2] + c2) in M.V for a2, b2, c2 in NB)]: del M.V[k]
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
    """Lámpara de pie (revisión de arte del 14-10-2026; la de antes queda en
    models/prv_lampara_v1.json). A 64 voxels/m, 1,9 m: pie de trípode de latón con garras, fuste
    con anillos y nudos, pantalla de tela plisada con flecos y ribete, la bombilla que brilla
    dentro y el cable que baja al suelo."""
    V = 4
    M = Model(S=V, seed=79)
    BRASS_D = (0.42, 0.30, 0.14); BRASS_L = (0.80, 0.66, 0.36)
    for k in range(3):                                                             # trípode con garras
        a = k * math.tau / 3
        for i in range(20):
            M.put(int(i * math.cos(a)), int(10 - i * 0.45), int(i * math.sin(a)), P, BRASS_D)
            M.put(int(i * math.cos(a)), int(11 - i * 0.45), int(i * math.sin(a)), P, BRASS)
        for d in range(3): M.put(int(20 * math.cos(a)) + d - 1, 0, int(20 * math.sin(a)), P, BRASS_D)
    for y in range(6, 104):                                                        # fuste
        r = 1.6 + (1.6 if y % 24 < 3 else 0) + (2.4 if 40 < y < 46 else 0)
        for x in range(-5, 6):
            for z in range(-5, 6):
                d = math.hypot(x, z)
                if d <= r: M.put(x, y, z, P, BRASS_L if x < 0 and d > r - 1 else (BRASS if d > r - 1 else BRASS_D))
    for y in range(104, 124):                                                      # pantalla plisada
        u = (y - 104) / 20
        r = 20 - 10 * u
        for a in range(0, 360, 3):
            ra = math.radians(a)
            pl = 0.8 * (a // 6 % 2)
            for d in (r - 1, r - 0.3 + pl):
                c = SHADE if a // 6 % 2 else lerp(SHADE, (0.70, 0.52, 0.30), 0.4)
                if y in (104, 123): c = (0.50, 0.20, 0.14)                           # ribete
                M.put(d * math.cos(ra), y, d * math.sin(ra), P, c, glow=1)
    for a in range(0, 360, 8):                                                      # flecos
        for k in range(1, 4 if (a // 8) % 2 else 2):
            M.put(20.5 * math.cos(math.radians(a)), 104 - k, 20.5 * math.sin(math.radians(a)), P, (0.56, 0.24, 0.16))
    for y in range(106, 113):                                                       # bombilla
        for x in range(-3, 4):
            for z in range(-3, 4):
                if x * x + z * z + (y - 109) ** 2 <= 10: M.put(x, y, z, P, LIGHT, glow=1)
    for i in range(60):                                                             # cable al suelo
        M.put(-2 - int(i * 0.5), max(0, 30 - i), int(math.sin(i * 0.3) * 2), P, (0.12, 0.10, 0.09))
    return M, {P: [0, 0, 0], 'light': [0, 106, 0]}


def pilar():
    """Pilar de fundición de la nave (revisión de arte del 14-10-2026; el de antes queda en
    models/prv_pilar_v1.json). A 48 voxels/m, 4 m: basa moldurada sobre un dado de piedra, fuste
    cilíndrico con acanaladuras y un collarino, capitel con hojas y volutas sencillas, ábaco y
    zapata con los pernos, pintura verde oscura que se pela al hierro y óxido abajo."""
    V = 3
    M = Model(S=V, seed=80)
    H = 190
    GREEN = (0.20, 0.27, 0.22); GREEN_L = (0.30, 0.38, 0.32); GREEN_D = (0.12, 0.16, 0.13)
    STONE_P = (0.52, 0.50, 0.46)
    box(M, -14, 14, 0, 10, -14, 14, lambda x, y, z: lerp(STONE_P, (0.40, 0.38, 0.35), M.hsh(x // 4, y, z // 4)))   # dado
    def prof(y):
        if y < 14: return 11
        if y < 18: return 9.5
        if y < 22: return 10.5
        if y < 26: return 8.5
        if y < H - 34: return 6.5
        if y < H - 30: return 8
        if y < H - 10: return 7 + (y - (H - 30)) * 0.45                            # campana del capitel
        return 13
    for y in range(10, H):
        r = prof(y)
        for x in range(-14, 15):
            for z in range(-14, 15):
                d = math.hypot(x + 0.5, z + 0.5)
                ang = math.atan2(z, x)
                rr = r
                if 26 <= y < H - 34 and (ang / math.tau * 16) % 1 < 0.3: rr -= 1     # acanaladuras
                if H - 30 <= y < H - 10 and abs(math.sin(4 * ang)) > 0.7 and (y - (H - 30)) % 10 < 7: rr += 1.5   # hojas
                if y >= H - 10 and (abs(x) > 12 or abs(z) > 12): continue
                if y >= H - 10: rr = 99 if max(abs(x), abs(z)) <= 12 else 0           # ábaco cuadrado
                if d > rr: continue
                if d < rr - 2 and y < H - 2: continue
                c = lerp(GREEN_D, GREEN_L, 0.4 + 0.5 * (0.5 + 0.5 * math.cos(ang - 2.4)))
                if 26 <= y < H - 34 and (ang / math.tau * 16) % 1 < 0.3: c = lerp(c, GREEN_D, 0.4)
                if M.noise(x, y, z, 4.0) > 0.74: c = lerp(IRON, (0.40, 0.24, 0.14), M.noise(x, y, z, 1.5))   # pelado y óxido
                if y < 30 and M.noise(x, y, z, 3.0) > 0.55: c = lerp(c, (0.38, 0.22, 0.12), 0.5)
                M.put(x, y, z, P, c)
    for sx in (-10, 10):                                                           # pernos de la zapata
        for sz in (-10, 10):
            M.put(sx, H, sz, P, IRON_L); M.put(sx, 10, sz + (1 if sz > 0 else -1) * 3, P, IRON_L)
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
