"""Atrezo de los tejados de Innsmouth (hito 6.3, la huida del hotel Gilman House). Una parte
"body", origen en el centro de la base, como gen_atrezo_innsmouth.py.

  gilman      la trasera del hotel Gilman House: cuatro plantas de ladrillo oscuro, ventanas
              con alguna luz encendida y la escalera de incendios de hierro (16/m)
  buhardilla  tejado abuhardillado de la casa de al lado, con ventana y chimenea (16/m)
  chimenea    chimenea de ladrillo con dos sombreretes (32/m)
  claraboya   claraboya de cristal con marco de hierro (32/m)
  deposito    depósito de agua de madera sobre patas (32/m)
  tendedero   dos palos con cuerda y sábanas tendidas (32/m)
  pretil      tramo de pretil de ladrillo con albardilla de piedra, el borde del tejado (32/m)
  trampilla   trampilla de acceso al tejado (32/m)

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
    M = Model(S=2, seed=83)
    for y in range(0, 52):
        for x in range(-13, 13):
            for z in range(-9, 9):
                if min(x + 13, 12 - x, z + 9, 8 - z) > 0 and y < 47: continue
                c = BRICK if (y // 2 + (x + (y // 2 % 2) * 2) // 4) % 4 else BRICK_D
                if y >= 47: c = STONE
                M.put(x, y, z, P, c)
    for cx in (-6, 6):                                       # sombreretes de barro
        for y in range(52, 62):
            for x in range(cx - 3, cx + 3):
                for z in range(-3, 3):
                    if math.hypot(x - cx + 0.5, z + 0.5) > 3: continue
                    M.put(x, y, z, P, (0.48, 0.30, 0.22) if y < 60 else (0.36, 0.22, 0.16))
    return M, {P: [0, 0, 0]}


def claraboya():
    M = Model(S=2, seed=84)
    for y in range(0, 8):                                    # bastidor
        for x in range(-26, 26):
            for z in range(-26, 26):
                if min(x + 26, 25 - x, z + 26, 25 - z) > 1: continue
                M.put(x, y, z, P, WOOD_D)
    for y in range(8, 24):                                   # pirámide de cristal con nervios
        w = 26 - (y - 8) * 1.6
        if w < 2: break
        for x in range(-int(w), int(w)):
            for z in range(-int(w), int(w)):
                if min(x + w, w - 1 - x, z + w, w - 1 - z) > 1: continue
                rib = abs(abs(x) - abs(z)) < 1.2 or x in (0, -1) or z in (0, -1)
                M.put(x, y, z, P, IRON if rib else (0.30, 0.40, 0.42))
    return M, {P: [0, 0, 0]}


def deposito():
    """Depósito de agua de duelas sobre cuatro patas con tirantes: 2 m de diámetro y 4 de alto."""
    M = Model(S=2, seed=85)
    for y in range(0, 56):                                   # patas y tirantes
        for cx, cz in ((-22, -22), (21, -22), (-22, 21), (21, 21)):
            for x in range(cx, cx + 2):
                for z in range(cz, cz + 2): M.put(x, y, z, P, WOOD_D)
    for i in range(44):
        M.put(-22 + i, 10 + i, -22, P, IRON); M.put(-22 + i, 10 + i, 22, P, IRON)
        M.put(-22, 10 + i, -22 + i, P, IRON); M.put(22, 10 + i, -22 + i, P, IRON)
    for y in range(56, 60):                                  # tablero
        for x in range(-26, 26):
            for z in range(-26, 26): M.put(x, y, z, P, PLANK_D)
    for y in range(60, 116):                                 # cuba
        for x in range(-32, 32):
            for z in range(-32, 32):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > 32 or (d < 30.5 and y < 115): continue
                c = WOOD if int(math.atan2(z, x) * 16) % 2 else WOOD_D
                if y in (66, 67, 88, 89, 108, 109) and d > 30: c = IRON
                M.put(x, y, z, P, c)
    for y in range(116, 132):                                # tejadillo cónico
        r = 34 - (y - 116) * 2.1
        for x in range(-34, 34):
            for z in range(-34, 34):
                if math.hypot(x + 0.5, z + 0.5) <= r: M.put(x, y, z, P, ROOF if y % 2 else ROOF_D)
    return M, {P: [0, 0, 0]}


def tendedero():
    M = Model(S=2, seed=86)
    for x0 in (-56, 56):
        for y in range(0, 64):
            for x in (x0 - 1, x0):
                for z in (-1, 0): M.put(x, y, z, P, WOOD_D)
    for x in range(-55, 56):                                 # cuerda que cuelga un poco
        y = 60 - int(4 * math.cos(x / 56 * math.pi / 2))
        M.put(x, y, 0, P, (0.55, 0.52, 0.45))
    for x0, w, col in ((-44, 22, SHEET), (-14, 18, (0.60, 0.42, 0.36)), (14, 26, SHEET), (46, 8, SHEET_D)):
        for x in range(x0, x0 + w):                          # sábanas y ropa tendida, combadas por el viento
            top = 59 - int(4 * math.cos(x / 56 * math.pi / 2))
            for y in range(top - 30 if w > 10 else top - 14, top):
                M.put(x, y, int(2 * math.sin(y / 8 + x / 10)), P, col if (y // 6) % 3 else lerp(col, (0, 0, 0), 0.12))
    return M, {P: [0, 0, 0]}


def pretil():
    """4 m de pretil de ladrillo (50 cm) con albardilla de piedra en piezas: llagas claras,
    ladrillos que faltan, verdín abajo y una gárgola de hierro oxidado (desagüe)."""
    M = Model(S=2, seed=87)
    MORTAR = (0.44, 0.40, 0.36)
    for x in range(-64, 64):
        for z in range(-4, 4):
            for y in range(0, 16):
                course = y // 2
                if y % 2 == 0 and y > 0: c = MORTAR
                elif (x + (course % 2) * 4) % 8 == 0: c = MORTAR
                else:
                    k = (x + (course % 2) * 4) // 8
                    if M.hsh(course, k, 9) < 0.05 and abs(z) == 3 and 2 < y < 14: continue   # ladrillo que falta
                    c = BRICK if M.hsh(course, k, 3) < 0.65 else BRICK_D
                    if y < 5 and M.noise(x, y, z, 6.0) > 0.5: c = lerp(c, MOSS, 0.6)
                M.put(x, y, z, P, c)
            if M.hsh(x // 16, 0, 9) > 0.93: continue          # tramo de albardilla caído
            for y in (16, 17):
                cz = z if z < 3 else 4
                M.put(x, y, cz, P, STONE if (x + 64) % 16 else (0.42, 0.41, 0.38))
                if z == -4: M.put(x, y, -5, P, STONE)
    for x in range(-3, 3):                                    # gárgola: canalón de hierro que asoma
        for z in range(4, 12):
            M.put(x, 3, z, P, RUST if x in (-3, 2) else IRON)
        M.put(x, 2, 4, P, IRON)
    for y in range(0, 3):                                     # mancha de óxido bajo la gárgola
        for x in range(-2, 2): M.put(x, y, 4, P, RUST)
    return M, {P: [0, 0, 0]}



def trampilla():
    M = Model(S=2, seed=88)
    for x in range(-18, 18):
        for z in range(-14, 14):
            for y in range(0, 8):
                if min(x + 18, 17 - x, z + 14, 13 - z) > 1 and y < 7: continue
                M.put(x, y, z, P, PLANK if (x // 4) % 2 else PLANK_D)
    for i in range(30):                                      # la tapa, abierta y apoyada
        for x in range(-16, 16):
            M.put(x, 8 + int(i * 0.9), -14 - int(i * 0.45), P, PLANK if (x // 4) % 2 else PLANK_D)
    for z in range(-10, 10): M.put(0, 8, z, P, DARK)
    for x in range(-14, 14):
        for z in range(-10, 10): M.put(x, 7, z, P, DARK)
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
