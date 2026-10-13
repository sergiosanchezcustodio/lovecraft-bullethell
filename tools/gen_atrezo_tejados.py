"""Atrezo de los tejados de Innsmouth (hito 6.3, la huida del hotel Gilman House). Una parte
"body", origen en el centro de la base, como gen_atrezo_innsmouth.py.

  gilman      la trasera del hotel Gilman House: cuatro plantas de ladrillo oscuro, ventanas
              con alguna luz encendida y la escalera de incendios de hierro (16/m)
  buhardilla  tejado abuhardillado de la casa de al lado, con ventana y chimenea (16/m)
  chimenea    chimenea de ladrillo con tres sombreretes de barro (64/m)
  claraboya   claraboya de cristal con marco de hierro (32/m)
  deposito    depósito de agua de duelas sobre patas, con escalera (64/m)
  tendedero   dos palos en T con cuerdas y ropa tendida (64/m)
  pretil      tramo de pretil de ladrillo con albardilla de piedra, el borde del tejado (64/m)
  trampilla   trampilla de acceso al tejado con la tapa abierta (64/m)
Las cinco de 64/m, rehechas en la revisión de arte del 13-10-2026.

Escribe models/tej_<pieza>.json. Uso: python tools/gen_atrezo_tejados.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
from gen_atrezo_innsmouth import (P, BRICK, BRICK_D, DARK, WOOD, WOOD_D, IRON, IRON_L, ROOF, ROOF_D, MOSS, RUST,
                                  TRIM, GLASS, PLANK, PLANK_D)

BRICK_N = (0.30, 0.20, 0.17); BRICK_ND = (0.23, 0.15, 0.13)          # ladrillo del hotel, más oscuro
STONE = (0.55, 0.54, 0.50)
LIT = (1.0, 0.78, 0.46)
SHEET = (0.78, 0.76, 0.70); SHEET_D = (0.62, 0.60, 0.56)
MORTAR = (0.46, 0.42, 0.37); SOOT = (0.08, 0.07, 0.07); POT = (0.52, 0.32, 0.22); POT_D = (0.38, 0.22, 0.16)
LEAD = (0.36, 0.38, 0.40); STONE_D = (0.42, 0.41, 0.38); WET = (0.22, 0.24, 0.22)
STAVE = (0.42, 0.31, 0.20); STAVE_D = (0.30, 0.22, 0.14); STAVE_L = (0.52, 0.40, 0.27)
PEG = (0.50, 0.42, 0.30); CLOTH_R = (0.56, 0.24, 0.20); CLOTH_B = (0.30, 0.36, 0.46); CLOTH_S = (0.70, 0.66, 0.56)



def _brick(M, x, y, z, u, seed=0):
    """Aparejo de ladrillo a 64/m: hiladas de 4, ladrillos de 14, llaga de 1; tono por pieza,
    algún ladrillo más oscuro o quemado, mortero que falta."""
    course = y // 4
    k = (u + (course % 2) * 7) // 14
    if y % 4 == 0 or (u + (course % 2) * 7) % 14 == 0:
        return MORTAR if M.hsh(u // 3, y, 5) > 0.15 else lerp(MORTAR, SOOT, 0.5)
    h = M.hsh(course, k, seed)
    c = lerp(BRICK, BRICK_D, h * 0.8)
    if h > 0.9: c = lerp(BRICK_D, SOOT, 0.4)
    return lerp(c, BRICK_D, 0.25 * M.noise(x, y, z, 3.0))


def _hollow(M):
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]




def gilman():
    """Trasera del Gilman House (rehecha el 09-10-2026 siguiendo tools/replicate/ref_gilman.png),
    14 m de ancho y cuatro plantas (11 m), 16/m, hueca. Ladrillo con llagas claras, zócalo y
    impostas de piedra, ventanas de guillotina con dintel y alféizar en distintos estados (unas
    pocas encendidas, rotas, oscuras y tapiadas abajo), puerta trasera con escalones, cornisa con
    dentellones y ménsulas, bajante, manchas de humedad, carteles despegados y la escalera de
    incendios en hierro claro (plataformas con baranda, tramos en zigzag y escalera colgante)."""
    M = Model(S=1, seed=81)
    HX, D, H = 112, 24, 176
    MORTAR = (0.46, 0.42, 0.38); FE = (0.34, 0.33, 0.31); FE_D = (0.20, 0.20, 0.20)
    POSTER = [(0.70, 0.64, 0.48), (0.58, 0.30, 0.24), (0.62, 0.60, 0.54)]
    FLOORS = [8 + k * 42 for k in range(4)]                  # suelo de cada planta

    def brick(x, y, z):
        if y < 8: return lerp(STONE, (0.40, 0.39, 0.36), M.noise(x, y, z, 3.0))           # zócalo
        if any(f - 2 <= y < f for f in FLOORS[1:]): return STONE                             # imposta
        course = y // 3
        if y % 3 == 0: return MORTAR                                                         # tendel
        u = x if abs(z - D + 1) < 1 else z
        if (u + (course % 2) * 4) % 8 == 0: return MORTAR                                    # llaga
        c = BRICK_N if M.hsh(course, (u + (course % 2) * 4) // 8, 1) < 0.7 else BRICK_ND
        if M.noise(x, y, z, 14.0) > 0.68: c = lerp(c, (0.16, 0.20, 0.16), 0.45)             # humedad
        return c

    for y in range(0, H):
        for x in range(-HX, HX):
            for z in range(-D, D):
                if min(x + HX, HX - 1 - x, D - 1 - z) > 0 or z == -D: continue
                M.put(x, y, z, P, brick(x, y, z))
    for x in range(-HX - 3, HX + 3):                          # cornisa con dentellones
        for y in range(H, H + 6):
            for z in range(D - 3, D + (3 if y >= H + 3 else 1)):
                M.put(x, y, z, P, STONE if y != H + 2 else (0.46, 0.45, 0.42))
        if x % 4 < 2:
            for z in (D + 1, D + 2): M.put(x, H + 2, z, P, STONE)
        if x % 24 == 0:                                       # ménsulas
            for k in range(4):
                for z in range(D, D + 1 + k): M.put(x, H - 4 + k, z, P, STONE)
    rng = M.rng
    for fi, f in enumerate(FLOORS):
        cy = f + 16
        for cx in range(-96, 100, 24):
            if fi == 0 and abs(cx - 0) < 14: continue          # puerta trasera
            r = rng.random()
            state = 'tapiada' if fi == 0 and r < 0.5 else ('luz' if r < 0.2 else ('rota' if r < 0.38 else 'oscura'))
            for a in range(-6, 6):
                for b in range(-11, 11):
                    edge = a in (-6, 5) or b in (-11, 10) or b == 0
                    if edge: c, g = TRIM, 0
                    elif state == 'luz': c, g = LIT, 1
                    elif state == 'tapiada': c, g = (PLANK if (b + 11) % 5 else PLANK_D), 0
                    elif state == 'rota': c, g = (GLASS if M.hsh(a, b, cx + fi) < 0.25 else DARK), 0
                    else: c, g = (GLASS if (a + b) % 7 == 0 else DARK), 0
                    M.put(cx + a, cy + b, D, P, c, glow=g)
            for a in range(-8, 8):                             # dintel y alféizar de piedra
                for b in (11, 12, 13): M.put(cx + a, cy + b, D, P, STONE)
                M.put(cx + a, cy - 12, D, P, STONE); M.put(cx + a, cy - 12, D + 1, P, STONE)
            if state != 'luz' and rng.random() < 0.5:          # chorretón de humedad bajo la ventana
                for b in range(0, rng.randint(8, 20)):
                    M.put(cx + rng.choice((-2, 1)), cy - 13 - b, D, P, (0.18, 0.15, 0.13))
    for x in range(-8, 8):                                    # puerta trasera con escalones
        for y in range(8, 40):
            M.put(x, y, D, P, TRIM if x in (-8, 7) or y == 39 else (WOOD if (x + 8) % 5 else WOOD_D))
    for i in range(3):
        for x in range(-11, 11):
            for z in range(D, D + 8 - i * 2): M.put(x, 6 - i * 2, z, P, STONE)
            for z in range(D, D + 8 - i * 2): M.put(x, 7 - i * 2, z, P, STONE)
    for y in range(0, H):                                     # bajante con abrazaderas
        M.put(HX - 6, y, D + 1, P, IRON_L if y % 24 else IRON)
        M.put(HX - 5, y, D + 1, P, IRON_L if y % 24 else IRON)
    for k, (px, py) in enumerate(((-70, 20), (-58, 26), (60, 18))):   # carteles despegados
        col = POSTER[k % 3]
        for a in range(0, 10):
            for b in range(0, 14):
                if b > 11 and a > 6: continue                 # esquina despegada
                M.put(px + a, py + b, D, P, lerp(col, (0.30, 0.26, 0.20), 0.3 * M.noise(a, b, k, 3.0)))
    # escalera de incendios (hierro claro para que se lea sobre el ladrillo)
    FX0, FX1, FZ = -44, 44, D + 14
    for fi, f in enumerate(FLOORS[1:], start=1):
        py = f
        for x in range(FX0, FX1):
            for z in range(D + 1, FZ):
                if (x + z) % 3 == 0 or z in (D + 1, FZ - 1) or x in (FX0, FX1 - 1): M.put(x, py, z, P, FE)
            M.put(x, py + 12, FZ - 1, P, FE)                 # barandilla delantera
            M.put(x, py + 6, FZ - 1, P, FE_D)
        for z in range(D + 1, FZ):
            for x in (FX0, FX1 - 1): M.put(x, py + 12, z, P, FE)
        for x in range(FX0, FX1, 6):
            for y in range(py, py + 12): M.put(x, y, FZ - 1, P, FE)
        for z in range(D + 1, FZ, 6):
            for y in range(py, py + 12):
                M.put(FX0, y, z, P, FE); M.put(FX1 - 1, y, z, P, FE)
        d = 1 if fi % 2 else -1                               # tramo en zigzag hasta la de abajo
        top_x = -d * 36
        for i in range(0, 42 if fi > 1 else 0):
            x = int(top_x + d * i * 1.5)
            y = py - i
            for z in range(D + 3, D + 10):
                if z in (D + 3, D + 9) or i % 2 == 0: M.put(x, y, z, P, FE if z in (D + 3, D + 9) else FE_D)
            M.put(x, y + 10, D + 9, P, FE)                    # pasamanos
    for y in range(14, FLOORS[1]):                            # escalera colgante bajo la primera plataforma
        for x in (30, 36): M.put(x, y, FZ - 3, P, FE)
        if y % 4 == 0:
            for x in range(30, 37): M.put(x, y, FZ - 3, P, FE)
    return M, {P: [0, 0, 0]}


def buhardilla():
    """Tejado abuhardillado (rehecho el 09-10-2026 siguiendo tools/replicate/ref_buhardilla.png),
    7 x 5 m, 16/m: faldones empinados de pizarra en hileras con verdín, cornisa blanca con canalón
    de cobre verdoso, dos buhardillas con su tejadillo a dos aguas, marco blanco y ventana (una
    con luz), y una chimenea de ladrillo con dos sombreretes. Pieza de borde (oeste)."""
    M = Model(S=1, seed=82)
    HX, HZ, H = 56, 40, 56
    SLATE = (0.24, 0.26, 0.29); SLATE_D = (0.17, 0.18, 0.21); SLATE_L = (0.32, 0.34, 0.37)
    GUTTER = (0.30, 0.42, 0.36); POT = (0.52, 0.36, 0.26)

    def slate(x, y, z):
        row = y // 3
        u = x + z
        c = SLATE if M.hsh(row, (u + 3 * (row % 2)) // 5, 2) < 0.55 else (SLATE_D if M.hsh(row, u // 5, 4) < 0.6 else SLATE_L)
        if y % 3 == 0: c = lerp(c, SLATE_D, 0.6)                    # sombra de la hilera
        if M.noise(x, y, z, 8.0) > 0.7: c = lerp(c, MOSS, 0.8)
        return c

    def inset(y):
        return int(y * 0.35)

    for y in range(0, H):
        i = inset(y)
        for x in range(-HX + i, HX - i):
            for z in range(-HZ + i, HZ - i):
                if min(x + HX - i, HX - i - 1 - x, z + HZ - i, HZ - i - 1 - z) > 1 and y < H - 1: continue
                M.put(x, y, z, P, slate(x, y, z))
    for x in range(-HX - 1, HX + 1):                                # cornisa blanca y canalón
        for z in range(-HZ - 1, HZ + 1):
            if min(x + HX + 1, HX - x, z + HZ + 1, HZ - z) > 0: continue
            M.put(x, 0, z, P, TRIM); M.put(x, 1, z, P, TRIM)
    for x in range(-HX - 2, HX + 2):
        for z in (HZ + 1, -HZ - 2):
            M.put(x, 1, z, P, GUTTER); M.put(x, 2, z, P, GUTTER)
    for z in range(-HZ - 2, HZ + 2):
        for x in (HX + 1, -HX - 2):
            M.put(x, 1, z, P, GUTTER); M.put(x, 2, z, P, GUTTER)
    for y in range(-14, 2): M.put(HX + 1, y, HZ + 1, P, GUTTER)        # bajante
    for i, cx in enumerate((-24, 20)):                              # buhardillas en el faldón este (+x)
        lit = i == 1
        y0, y1 = 8, 34
        for y in range(y0, y1):
            xf = HX - inset(y)
            for z in range(cx - 10, cx + 10):
                for x in range(xf - 12, xf + 1):
                    side = z in (cx - 10, cx + 9)
                    front = x == xf
                    if not (side or front): continue
                    if front:
                        if z in (cx - 10, cx - 9, cx + 8, cx + 9) or y in (y0, y0 + 1, y1 - 1, y1 - 2): c = TRIM
                        elif z in (cx - 1, cx) or y == (y0 + y1) // 2: c = TRIM                          # parteluz
                        else: c = LIT if lit else (0.06, 0.07, 0.08)
                        M.put(x, y, z, P, c, glow=1 if c == LIT else 0)
                    else:
                        M.put(x, y, z, P, slate(x, y, z))
            M.put(HX - inset(y0) + 1, y0, cx, P, TRIM)
        for k in range(0, 12):                                      # tejadillo a dos aguas con alero
            for z in range(cx - 12 + k, cx + 12 - k):
                for x in range(HX - inset(y1) - 16, HX - inset(y1) + 3):
                    rake = z in (cx - 12 + k, cx + 11 - k) and x >= HX - inset(y1) + 1   # tabla de remate, solo delante
                    M.put(x, y1 + k, z, P, TRIM if rake else slate(x, y1 + k, z))
        for k in range(0, 10):                                      # frontón del tejadillo
            for z in range(cx - 10 + k, cx + 10 - k):
                M.put(HX - inset(y1) + 2, y1 + k, z, P, TRIM if k == 0 else (0.60, 0.58, 0.54))
    for y in range(36, 78):                                         # chimenea con dos sombreretes
        for x in range(-32, -20):
            for z in range(-6, 4):
                cap = y >= 72
                if min(x + 32, -21 - x, z + 6, 3 - z) > 0 and y < 77: continue
                M.put(x, y, z, P, (0.46, 0.42, 0.38) if cap else (BRICK if (y // 2 + x) % 4 else BRICK_D))
    for px in (-29, -24):
        for y in range(78, 84):
            for x in range(px - 1, px + 2):
                for z in range(-2, 1): M.put(x, y, z, P, POT)
    return M, {P: [0, 0, 0]}


def chimenea():
    """Chimenea de ladrillo (64/m, revisión de arte del 13-10-2026): aparejo con llagas, base con
    tapajuntas de plomo sobre el tejado, cornisa de dos hiladas que vuelan, albardilla de piedra,
    hollín que baja desde arriba, verdín abajo, una grieta, una abrazadera de hierro con su
    tirante, y tres sombreretes de barro de alturas distintas, uno roto, con el interior negro."""
    M = Model(S=4, seed=83)
    HX, HZ, H = 26, 18, 100
    for y in range(0, H):
        ex = 2 if H - 14 <= y < H - 6 else 0                         # cornisa que vuela
        for x in range(-HX - ex, HX + ex):
            for z in range(-HZ - ex, HZ + ex):
                if min(x + HX + ex, HX + ex - 1 - x, z + HZ + ex, HZ + ex - 1 - z) > 1 and y < H - 1: continue
                u = x if abs(z) >= HZ - 1 else z + 100
                c = _brick(M, x, y, z, u, 83)
                if y >= H - 4: c = lerp(STONE, STONE_D, M.hsh(x // 10, 1, z // 10))       # albardilla
                elif y > H - 30: c = lerp(c, SOOT, min(1.0, (y - H + 30) / 30) * (0.4 + 0.5 * M.noise(x, y, z, 6.0)))
                if y < 12: c = lerp(c, MOSS, 0.5 * M.noise(x, y, z, 5.0))
                if y < 6 and min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) <= 1: c = LEAD          # tapajuntas
                M.put(x, y, z, P, c)
    for x in range(-HX - 1, HX + 1):                                 # tapajuntas que asoma
        for z in range(-HZ - 1, HZ + 1):
            if min(x + HX + 1, HX - x, z + HZ + 1, HZ - z) == 0:
                for y in range(0, 3): M.put(x, y, z, P, LEAD)
    x, y = 8, 70                                                     # grieta
    for _ in range(40):
        v = M.V.get((x, y, HZ - 1))
        if v: v[1] = SOOT
        y -= 1; x += M.rng.choice((-1, 0, 1))
    for xx in range(-HX - 1, HX + 1):                                # abrazadera y tirante
        M.put(xx, 60, HZ, P, IRON); M.put(xx, 61, HZ, P, IRON)
    for i in range(60): M.put(HX + i // 2, 60 - i, HZ - 2, P, IRON)
    for cx, h, broken in ((-13, 26, False), (0, 34, True), (13, 22, False)):    # sombreretes
        for y in range(H, H + h):
            r = 6.5 - 1.5 * math.sin((y - H) / h * math.pi) + (1.5 if y > H + h - 4 else 0)
            if broken and y > H + h - 10 and M.hsh(y, 1, 1) > 0.3: r -= 1.5
            for x in range(cx - 9, cx + 10):
                for z in range(-9, 10):
                    d = math.hypot(x - cx + 0.5, z + 0.5)
                    if d > r: continue
                    if d < r - 2 and y < H + h - 1: continue
                    c = POT if (y - H) % 8 else POT_D
                    if broken and y > H + h - 10 and M.hsh(x, y, z) > 0.75: continue
                    M.put(x, y, z, P, lerp(c, SOOT, 0.6 * max(0, (y - H - h + 10) / 10)))
            if y == H + h - 1:
                for x in range(cx - 4, cx + 5):
                    for z in range(-4, 5):
                        if math.hypot(x - cx, z) < r - 2: M.put(x, y, z, P, SOOT)
    _hollow(M)
    return M, {P: [0, 0, 0]}


def claraboya():
    """Claraboya del tejado (rehecha a 64/m en la revisión de arte del 13-10-2026): brocal de
    tablas con tapajuntas de plomo, pirámide de cristal en paños con montantes de hierro y
    junquillos, los cristales sucios de hollín y verdín por abajo, dos rotos (uno con el hueco
    oscuro y esquirlas), un paño entreabierto sujeto con una varilla, y por dentro la luz tenue
    de la escalera."""
    M = Model(S=4, seed=84)
    W, BH = 52, 14
    GLASS_C = (0.30, 0.40, 0.42); GLASS_D = (0.20, 0.26, 0.26); GRIME = (0.18, 0.18, 0.16)
    for x in range(-W - 2, W + 2):                                                    # tapajuntas
        for z in range(-W - 2, W + 2):
            if max(abs(x + 0.5), abs(z + 0.5)) > W - 2: M.put(x, 0, z, P, LEAD); M.put(x, 1, z, P, LEAD)
    for y in range(0, BH):                                                           # brocal
        for x in range(-W, W):
            for z in range(-W, W):
                if max(abs(x + 0.5), abs(z + 0.5)) < W - 3: continue
                c = lerp(PLANK, PLANK_D, M.hsh(y // 4, (x + z) // 12, 1))
                if y % 4 == 0: c = lerp(c, (0.08, 0.07, 0.06), 0.5)
                M.put(x, y, z, P, c)
    TOP = BH + 34
    broken = {(0, 1), (2, 0)}
    for y in range(BH, TOP):
        w = (W - 2) * (1 - (y - BH) / (TOP - BH))
        if w < 2: break
        for x in range(-int(w) - 1, int(w) + 1):
            for z in range(-int(w) - 1, int(w) + 1):
                m = max(abs(x + 0.5), abs(z + 0.5))
                if m > w or m < w - 2.2: continue
                rib = abs(abs(x + 0.5) - abs(z + 0.5)) < 1.2                         # aristas
                face = 0 if abs(x) > abs(z) and x > 0 else 1 if abs(x) > abs(z) else 2 if z > 0 else 3
                u = (z if face < 2 else x) / max(w, 1)
                mull = abs(u) < 0.04 or abs(abs(u) - 0.5) < 0.03                    # montantes
                pane = (face, int((u + 1) * 2))
                if rib or mull or (y - BH) % 11 == 0: M.put(x, y, z, P, IRON); continue
                if pane in broken and M.noise(x, y, z, 5.0) > 0.35: continue          # roto
                if face == 0 and pane[1] == 2 and y > BH + 6: continue                 # paño entreabierto (se pone aparte)
                c = lerp(GLASS_C, GLASS_D, M.noise(x, y, z, 6.0))
                if y < BH + 6: c = lerp(c, (0.22, 0.30, 0.18), 0.5)                    # verdín abajo
                if M.noise(x, y, z, 4.0) > 0.66: c = lerp(c, GRIME, 0.6)                # hollín
                if (x + 2 * y + z) % 13 == 0: c = lerp(c, (0.62, 0.70, 0.72), 0.5)      # reflejos
                M.put(x, y, z, P, c)
    for k in range(18):                                                              # paño entreabierto y varilla
        for j in range(18):
            M.put(W - 10 - k // 2 + 6, BH + 8 + k, -2 + j, P, lerp(GLASS_C, GRIME, 0.3) if j % 9 else IRON)
    for k in range(12): M.put(W - 12, BH + 4 + k, 4, P, IRON_L)
    for x in range(-W + 4, W - 3):                                                   # fondo: luz tenue de la escalera
        for z in range(-W + 4, W - 3):
            M.put(x, BH - 6, z, P, (0.40, 0.30, 0.18) if M.hsh(x // 8, z // 8, 2) > 0.6 else (0.06, 0.05, 0.05))
    for _ in range(14):                                                              # esquirlas
        M.put(M.rng.randint(-W, W), BH, M.rng.randint(-W, W), P, (0.56, 0.66, 0.68))
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


def deposito():
    """Depósito de agua de duelas sobre patas (64/m, revisión de arte del 13-10-2026): 2 m de
    diámetro y 4 de alto. Cuba de duelas de tono propio que se ensancha un poco abajo, cinco aros de
    hierro oxidado con sus tensores, manchas de humedad y verdín donde gotea, tejadillo cónico de
    tablas con remate y trampilla, escalera de mano, patas con tirantes en aspa y pernos, tablero
    con vigas, y un caño de desagüe que baja con una gotera."""
    M = Model(S=4, seed=85)
    K = 2
    for cx, cz in ((-44, -44), (42, -44), (-44, 42), (42, 42)):      # patas
        for y in range(0, 112):
            for x in range(cx, cx + 4):
                for z in range(cz, cz + 4):
                    c = lerp(WOOD, WOOD_D, 0.4 + 0.3 * M.noise(x, y, z, 3.0))
                    if y < 8: c = lerp(c, MOSS, 0.4)
                    M.put(x, y, z, P, c)
        for y in (20, 60, 100):
            M.put(cx + 4, y, cz + 1, P, IRON_L); M.put(cx + 1, y, cz + 4, P, IRON_L)
    for i in range(88):                                              # tirantes en aspa
        for a, b in ((-44, -44), (-44, 46)):
            M.put(-44 + i, 20 + i, b, P, IRON); M.put(-44 + i, 108 - i, b, P, IRON)
            M.put(a if a == -44 else 46, 20 + i, -44 + i, P, IRON); M.put(46, 108 - i, -44 + i, P, IRON)
        M.put(-46, 20 + i, -44 + i, P, IRON); M.put(-46, 108 - i, -44 + i, P, IRON)
    for y in range(112, 120):                                        # tablero con vigas
        for x in range(-54, 54):
            for z in range(-54, 54):
                if y < 116 and (x // 8) % 3: continue
                M.put(x, y, z, P, lerp(PLANK, PLANK_D, M.hsh(x // 8, 2, 2)) if y >= 116 else WOOD_D)
    R0 = 64
    for y in range(120, 232):                                        # cuba de duelas
        r = R0 + 2 * (1 - (y - 120) / 112)
        for x in range(-68, 69):
            for z in range(-68, 69):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r or (d < r - 2.5 and y < 231): continue
                a = math.atan2(z, x)
                st = int((a + math.pi) / math.tau * 40)
                c = [STAVE, STAVE_D, STAVE_L][int(M.hsh(st, 1, 1) * 3)]
                if (a + math.pi) / math.tau * 40 % 1 < 0.08: c = lerp(STAVE_D, SOOT, 0.4)    # junta
                c = lerp(c, STAVE_D, 0.3 * M.noise(x * 0.2, y, z * 0.2, 1.0))
                if y < 160 and M.noise(x, y, z, 7.0) > 0.6: c = lerp(c, WET, 0.6)           # humedad
                if y < 132 and M.noise(x, y, z, 4.0) > 0.55: c = lerp(c, MOSS, 0.6)
                if y in (126, 127, 128, 152, 153, 154, 178, 179, 180, 204, 205, 206, 224, 225) and d > r - 1.5:
                    c = IRON if M.hsh(x, y, z) > 0.3 else RUST
                M.put(x, y, z, P, c)
    for y in (127, 153, 179, 205):                                   # tensores de los aros
        for x in range(-2, 3):
            for k in range(3): M.put(x, y - 1 + k, 66, P, IRON_L)
    for y in range(232, 266):                                        # tejadillo cónico de tablas
        r = 70 - (y - 232) * 2.0
        for x in range(-70, 71):
            for z in range(-70, 71):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r or d < r - 3: continue
                a = math.atan2(z, x)
                c = ROOF if int((a + math.pi) / math.tau * 48) % 2 else ROOF_D
                if M.noise(x, y, z, 5.0) > 0.65: c = lerp(c, MOSS, 0.6)
                M.put(x, y, z, P, c)
    for y in range(266, 276):                                        # remate
        for x in range(-3, 4):
            for z in range(-3, 4):
                if x * x + z * z <= 9 - (y - 266): M.put(x, y, z, P, IRON)
    for x in range(-10, 10):                                         # trampilla del tejadillo
        for y in range(244, 256):
            d = math.hypot(x, 0)
            M.put(x, y, int(70 - (y - 232) * 2.0) - 1, P, PLANK_D if x in (-10, 9) or y in (244, 255) else PLANK)
    for y in range(0, 240):                                          # escalera de mano
        for zz in (-6, 6):
            M.put(68 + (240 - y) // 40, y, zz, P, WOOD_D)
        if y % 10 == 0:
            for zz in range(-6, 7): M.put(68 + (240 - y) // 40, y, zz, P, WOOD)
    for y in range(20, 122):                                         # caño de desagüe y gotera
        M.put(-30, y, 0, P, LEAD); M.put(-31, y, 0, P, LEAD)
    for y in range(4, 18, 3): M.put(-30, y, 0, P, (0.40, 0.50, 0.56))
    for x in range(-36, -24):
        for z in range(-6, 6):
            if (x + 30) ** 2 + z * z < 30: M.put(x, 0, z, P, WET)
    _hollow(M)
    return M, {P: [0, 0, 0]}


def tendedero():
    """Tendedero (64/m, revisión de arte del 13-10-2026): dos palos en T con tornapuntas, clavados
    en bases de ladrillo; dos cuerdas que se comban; sábanas, camisas, un pantalón, calcetines y una
    toalla con pinzas, que ondean y se pliegan, alguna remendada o deshilachada en el bajo."""
    M = Model(S=4, seed=86)
    for x0 in (-112, 112):
        for y in range(0, 136):
            for x in range(x0 - 2, x0 + 2):
                for z in range(-2, 2): M.put(x, y, z, P, lerp(WOOD_D, WOOD, M.noise(x, y, z, 4.0) * 0.6))
        for z in range(-16, 16):                                     # travesaño en T
            for y in (128, 129, 130):
                for x in (x0 - 1, x0): M.put(x, y, z, P, WOOD_D)
        for i in range(14):                                          # tornapuntas
            M.put(x0, 114 + i, -2 - i, P, WOOD_D); M.put(x0, 114 + i, 1 + i, P, WOOD_D)
        for x in range(x0 - 8, x0 + 8):                              # base de ladrillo
            for z in range(-8, 8):
                for y in range(0, 10):
                    if min(abs(x - x0 + 0.5), abs(z + 0.5)) < 6 and y < 9 and abs(x - x0 + 0.5) < 6.5 and abs(z + 0.5) < 6.5: continue
                    M.put(x, y, z, P, _brick(M, x, y, z, x + z))
    def rope_y(x): return 126 - int(10 * math.cos(x / 110 * math.pi / 2))
    for zc in (-12, 12):
        for x in range(-110, 111): M.put(x, rope_y(x), zc, P, (0.62, 0.58, 0.50))
    items = [(-104, 44, 60, CLOTH_S, -12, 'sheet'), (-54, 22, 30, (0.66, 0.68, 0.72), -12, 'shirt'), (-26, 20, 40, (0.30, 0.30, 0.34), -12, 'trousers'),
             (2, 50, 64, (0.74, 0.70, 0.60), -12, 'sheet'), (60, 10, 14, CLOTH_R, -12, 'sock'), (76, 10, 14, CLOTH_B, -12, 'sock'),
             (-96, 34, 26, CLOTH_B, 12, 'towel'), (-50, 46, 56, (0.80, 0.78, 0.72), 12, 'sheet'), (8, 22, 30, (0.60, 0.42, 0.36), 12, 'shirt'),
             (40, 40, 50, CLOTH_S, 12, 'sheet')]
    for i, (x0, w, h, col, zc, kind) in enumerate(items):
        for x in range(x0, x0 + w):
            top = rope_y(x)
            hh = h
            if kind == 'shirt': hh = h if abs(x - x0 - w / 2) < w * 0.3 else int(h * 0.45)        # mangas
            if kind == 'trousers': hh = h if (x - x0) < w * 0.45 or (x - x0) > w * 0.55 else int(h * 0.3)
            ragged = int(3 * M.noise(x, i, 0, 3.0))
            for y in range(top - hh + ragged, top):
                t = (top - y) / max(1, hh)
                dz = int(round(3 * math.sin(x / 9 + i) * t + 2 * math.sin(y / 7 + x / 13) * t))
                c = col
                if (x - x0) % 12 in (0, 1) and kind == 'sheet': c = lerp(col, (0, 0, 0), 0.12)     # pliegues
                if kind == 'towel' and (top - y) in range(6, 10): c = CLOTH_R
                if kind == 'sheet' and M.hsh(i, 3, 3) > 0.5 and abs(x - x0 - w * 0.6) < 6 and abs(y - top + hh * 0.5) < 6: c = lerp(col, (0.6, 0.5, 0.4), 0.4)  # remiendo
                c = lerp(c, (0.5, 0.5, 0.48), 0.12 * M.noise(x, y, i, 6.0))
                M.put(x, y, zc + dz, P, c)
        for px in (x0 + 1, x0 + w - 2):                              # pinzas
            for k in range(4): M.put(px, rope_y(px) + 1 - k, zc + 1, P, PEG)
    return M, {P: [0, 0, 0]}


def pretil():
    """4 m de pretil de ladrillo (64/m, revisión de arte del 13-10-2026): aparejo con llagas y
    ladrillos de tono propio, algunos que faltan o rotos, mortero que se cae, verdín y humedad
    abajo, eflorescencias de sal, albardilla de piedra en piezas con goterón, una que falta y otra
    movida; gárgola de hierro con óxido que chorrea y un hierbajo en una junta."""
    M = Model(S=4, seed=87)
    L, Z, H = 128, 9, 32
    for x in range(-L, L):
        for z in range(-Z, Z):
            for y in range(0, H):
                if min(z + Z, Z - 1 - z) > 1 and y < H - 1: continue
                u = x
                course = y // 4
                k = (u + (course % 2) * 7) // 14
                if M.hsh(course, k, 9) < 0.04 and z >= Z - 2 and 3 < y < H - 4:
                    if z == Z - 1: continue                                   # ladrillo que falta
                    M.put(x, y, z, P, SOOT); continue
                c = _brick(M, x, y, z, u, 87)
                if y < 10: c = lerp(c, MOSS, 0.6 * M.noise(x, y, z, 5.0))
                elif y < 18 and M.noise(x, y, z, 6.0) > 0.7: c = lerp(c, (0.78, 0.76, 0.70), 0.45)   # sal
                M.put(x, y, z, P, c)
    for x in range(-L, L):                                          # albardilla
        piece = (x + L) // 32
        if M.hsh(piece, 0, 9) > 0.9: continue                        # una que falta
        lift = 1 if M.hsh(piece, 1, 9) > 0.85 else 0                 # otra movida
        for z in range(-Z - 2, Z + 2):
            for y in (H, H + 1, H + 2):
                c = lerp(STONE, STONE_D, M.hsh(piece, 2, 9) * 0.6 + 0.2 * M.noise(x, y, z, 4.0))
                if (x + L) % 32 == 0: c = MORTAR
                if M.noise(x, y, z, 5.0) > 0.72: c = lerp(c, MOSS, 0.5)
                M.put(x, y + lift, z + (lift if x % 2 else 0) * 0, P, c)
            if z in (-Z - 2, Z + 1): M.put(x, H - 1, z, P, STONE_D)     # goterón
    for x in range(-6, 6):                                          # gárgola
        for z in range(Z, Z + 20):
            for y in (6, 7):
                c = IRON if abs(x) < 5 else RUST
                if y == 7 and abs(x) < 4: continue
                M.put(x, y, z, P, c)
    for y in range(0, 6):
        for x in range(-4, 4):
            M.put(x, y, Z, P, lerp(RUST, BRICK_D, y / 8))
    for k in range(10):                                              # hierbajo en una junta
        M.put(60 + (k % 3) - 1, 20 + k // 2, Z, P, (0.30, 0.42, 0.20))
    _hollow(M)
    return M, {P: [0, 0, 0]}


def trampilla():
    """Trampilla de acceso al tejado (64/m, revisión de arte del 13-10-2026): brocal de tablas con
    tapajuntas de plomo, la tapa abierta apoyada con bisagras y un asa de hierro, refuerzos en aspa
    y clavos, y abajo el hueco oscuro con el arranque de la escalera."""
    M = Model(S=4, seed=88)
    X, Z, H = 36, 28, 16
    for x in range(-X - 2, X + 2):                                  # tapajuntas
        for z in range(-Z - 2, Z + 2):
            if min(x + X + 2, X + 1 - x, z + Z + 2, Z + 1 - z) < 3: M.put(x, 0, z, P, LEAD); M.put(x, 1, z, P, LEAD)
    for x in range(-X, X):                                          # brocal
        for z in range(-Z, Z):
            for y in range(0, H):
                if min(x + X, X - 1 - x, z + Z, Z - 1 - z) > 2 and y < H - 1: continue
                if min(x + X, X - 1 - x, z + Z, Z - 1 - z) > 3: continue
                c = lerp(PLANK, PLANK_D, M.hsh(y // 4, (x + z) // 9, 1))
                if y % 4 == 0: c = lerp(c, SOOT, 0.5)
                M.put(x, y, z, P, c)
    for x in range(-X + 4, X - 4):                                  # hueco y escalera
        for z in range(-Z + 4, Z - 4):
            M.put(x, H - 3, z, P, DARK)
    for zz in range(-Z + 6, Z - 6, 8):
        for x in range(-12, 12): M.put(x, H - 2, zz, P, WOOD_D)
    T = 2 * Z - 2
    ang = math.radians(68)
    for i in range(T):                                              # tapa abierta
        for x in range(-X + 2, X - 2):
            for t in range(4):
                y = H + int(i * math.sin(ang)) + int(t * math.cos(ang))
                z = -Z - int(i * math.cos(ang)) + t
                c = lerp(PLANK, PLANK_D, M.hsh((x + X) // 9, 3, 3))
                if (x + X) % 9 == 0: c = lerp(c, SOOT, 0.5)
                if t == 3 and (abs(x - (i - T / 2) * 2 * X / T) < 2 or abs(x + (i - T / 2) * 2 * X / T) < 2): c = WOOD_D  # aspa
                if t == 3 and (x + X) % 9 == 4 and i % 10 == 2: c = IRON_L                                              # clavos
                M.put(x, y, z, P, c)
    for x in (-X + 8, X - 9):                                       # bisagras
        for k in range(8): M.put(x, H + 1, -Z - 2 + k, P, IRON)
    for k in range(10):                                             # asa
        M.put(-5 + k, H + int((T - 4) * math.sin(ang)) + 5, -Z - int((T - 4) * math.cos(ang)) + 5, P, IRON)
    _hollow(M)
    return M, {P: [0, 0, 0]}


PIECES = {'gilman': gilman, 'buhardilla': buhardilla, 'chimenea': chimenea, 'claraboya': claraboya,
          'deposito': deposito, 'tendedero': tendedero, 'pretil': pretil, 'trampilla': trampilla}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/tej_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('tej_%s: %d voxels' % (name, n))
