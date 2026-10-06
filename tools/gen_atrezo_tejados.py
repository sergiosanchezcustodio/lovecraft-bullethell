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
from gen_atrezo_innsmouth import (P, BRICK, BRICK_D, DARK, WOOD, WOOD_D, IRON, IRON_L, ROOF, ROOF_D, MOSS,
                                  TRIM, GLASS, PLANK, PLANK_D)

BRICK_N = (0.30, 0.20, 0.17); BRICK_ND = (0.23, 0.15, 0.13)          # ladrillo del hotel, más oscuro
STONE = (0.55, 0.54, 0.50)
LIT = (1.0, 0.78, 0.46)
SHEET = (0.78, 0.76, 0.70); SHEET_D = (0.62, 0.60, 0.56)


def gilman():
    """Trasera del Gilman House: 14 m de ancho y cuatro plantas (11 m). Hueca (muro de 1 voxel,
    sin trasera). Ventanas de guillotina, unas pocas encendidas (luz que brilla), cornisa, y la
    escalera de incendios en zigzag delante."""
    M = Model(S=1, seed=81)
    HX, D, H = 112, 24, 176
    for y in range(0, H):
        for x in range(-HX, HX):
            for z in range(-D, D):
                if min(x + HX, HX - 1 - x, D - 1 - z) > 0 or z == -D: continue
                c = BRICK_N if (y // 2 + (x + (y // 2 % 2) * 2) // 4) % 4 else BRICK_ND
                if M.noise(x, y, z, 14.0) > 0.7: c = lerp(c, (0.18, 0.22, 0.18), 0.4)   # humedad
                M.put(x, y, z, P, c)
    for x in range(-HX - 2, HX + 2):                         # cornisa
        for y in (H, H + 1, H + 2):
            for z in range(D - 2, D + 2): M.put(x, y, z, P, STONE)
    rng = M.rng
    for floor_ in range(4):
        cy = 22 + floor_ * 42
        for cx in range(-96, 100, 24):
            lit = rng.random() < 0.22
            for a in range(-6, 6):
                for b in range(-11, 11):
                    edge = a in (-6, 5) or b in (-11, 10) or b == 0
                    if edge: M.put(cx + a, cy + b, D, P, TRIM)
                    else: M.put(cx + a, cy + b, D, P, LIT if lit else DARK, glow=1 if lit else 0)
    # escalera de incendios: plataformas en cada planta y tramos en zigzag
    for floor_ in range(1, 4):
        py = floor_ * 42
        for x in range(-40, 40):
            for z in range(D, D + 14):
                if (x + z) % 3 == 0 or z in (D, D + 13): M.put(x, py, z, P, IRON)
            M.put(x, py + 10, D + 13, P, IRON)               # barandilla
        for x in range(-40, 40, 8):
            for y in range(py, py + 10): M.put(x, y, D + 13, P, IRON)
        d = 1 if floor_ % 2 else -1
        for i in range(42):                                  # tramo hacia la planta de abajo
            x = int(-d * 30 + d * i * 1.4)
            for z in range(D + 4, D + 10): M.put(x, py - i, z, P, IRON_L if i % 3 == 0 else IRON)
    return M, {P: [0, 0, 0]}


def buhardilla():
    """Tejado abuhardillado (mansarda) de 7 x 5 m: faldón empinado de pizarra, ventana de
    buhardilla con su tejadillo y una chimenea. Pieza de borde (oeste)."""
    M = Model(S=1, seed=82)
    HX, HZ = 56, 40
    for y in range(0, 56):
        inset = int(y * 0.35)
        for x in range(-HX + inset, HX - inset):
            for z in range(-HZ + inset, HZ - inset):
                if min(x + HX - inset, HX - inset - 1 - x, z + HZ - inset, HZ - inset - 1 - z) > 1 and y < 55: continue
                c = ROOF if (y // 3 + x // 5) % 2 else ROOF_D
                if M.noise(x, y, z, 10.0) > 0.72: c = MOSS
                M.put(x, y, z, P, c)
    for cx in (-24, 20):                                     # ventanas de buhardilla (al este, +x)
        for y in range(10, 34):
            for z in range(cx - 8, cx + 8):
                xf = HX - int(y * 0.35)
                for x in range(xf - 8, xf + 1):
                    if x == xf: M.put(x, y, z, P, TRIM if z in (cx - 8, cx + 7) or y in (10, 33) else (DARK if y < 30 else TRIM))
                    elif z in (cx - 8, cx + 7): M.put(x, y, z, P, ROOF_D)
        for i in range(8):
            for z in range(cx - 9 + i, cx + 9 - i):
                for x in range(HX - 18, HX - 2): M.put(x, 34 + i, z, P, ROOF_D)
    for y in range(40, 76):                                  # chimenea
        for x in range(-30, -22):
            for z in range(-6, 2):
                if min(x + 30, -23 - x, z + 6, 1 - z) > 0 and y < 75: continue
                M.put(x, y, z, P, BRICK if (y // 2 + x) % 4 else BRICK_D)
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
    """4 m de pretil de ladrillo (50 cm) con albardilla de piedra: el borde de los tejados."""
    M = Model(S=2, seed=87)
    for x in range(-64, 64):
        for z in range(-4, 4):
            for y in range(0, 16):
                if M.hsh(x // 8, 0, 9) > 0.92 and y > 6: continue   # algún hueco desmoronado
                c = BRICK if (y // 2 + (x + (y // 2 % 2) * 2) // 4) % 4 else BRICK_D
                M.put(x, y, z, P, c)
            if M.hsh(x // 8, 0, 9) <= 0.92:
                for y in (16, 17): M.put(x, y, z + (1 if z == 3 else 0), P, STONE)
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
