"""Atrezo de la noche suelta «La música de Erich Zann» (hito 22.6): la rue d'Auseil, en París. Una parte
"body", origen en el centro de la base, la cara principal hacia +Z, a 16 voxels/m salvo lo pequeño
(como gen_atrezo_puerto.py, del que usa la casa hueca con tejado, `House`).

«Era una calle muy estrecha y empinada, en parte con escalones, y las casas, altas, de tejados en pico,
se inclinaban de un modo absurdo, hacia atrás, hacia delante y de lado, hasta casi tocarse por arriba.»

  casa_1/2/3   casa alta y estrecha de cuatro plantas, de revoco viejo con manchas, entramado en las de
               arriba, contraventanas, tejado de pizarra muy empinado con buhardilla y chimenea; ladeada
               (cada una hacia un sitio). Las ventanas, casi todas a oscuras (16/m)
  casa_zann    la casa de Zann, la última de la calle y la más alta: cinco plantas, la buhardilla con la
               ventana encendida (de ahí sale la música, punto "viola") y contraventanas abiertas (16/m)
  muro         el muro alto cubierto de hiedra con que acaba la calle, arriba (16/m)
  escalones    tramo de tres escalones de piedra gastada, para cruzar la calle (se pisa, 16/m)
  pretil       pretil de piedra con barandilla de hierro, al borde del río (16/m)
  farol        farol de gas de pared, con su ménsula (32/m)

Escribe models/aus_<pieza>.json. Uso: python tools/gen_atrezo_auseil.py [piezas...]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import gen_atrezo_puerto as pu
from gen_atrezo_puerto import House

P = 'body'
PLAST = (0.58, 0.53, 0.44); PLAST_D = (0.44, 0.40, 0.33); PLAST_L = (0.66, 0.61, 0.51)
STAIN = (0.30, 0.28, 0.24)
BEAM = (0.24, 0.17, 0.11); BEAM_D = (0.16, 0.11, 0.07)
STONE = (0.42, 0.41, 0.39); STONE_D = (0.30, 0.29, 0.28); STONE_L = (0.52, 0.51, 0.48)
SHUT = [(0.20, 0.26, 0.24), (0.30, 0.20, 0.16), (0.24, 0.24, 0.28)]
IVY = (0.12, 0.20, 0.10); IVY_D = (0.07, 0.12, 0.06); IVY_L = (0.20, 0.30, 0.14)
IRON = (0.10, 0.10, 0.11); IRON_L = (0.24, 0.24, 0.26)
GLASS = (0.07, 0.08, 0.11)
LAMP = (1.0, 0.82, 0.50)
CANDLE = (1.0, 0.86, 0.56); CANDLE_D = (0.92, 0.62, 0.30)


def plaster_wall(M, ground=26, frame=True, seed=0):
    """Revoco viejo con manchas de humedad que bajan, zócalo de piedra y la planta baja de sillares;
    arriba, entramado de madera."""
    def f(x, y, z, u, side):
        if y < 6: return lerp(STONE_D, STONE, 0.6 * M.noise(x, y, z, 3.0))
        if y < ground:                                                  # planta baja: sillares
            row = y // 6
            if y % 6 == 0 or (u + (row % 2) * 7) % 14 == 0: return STONE_D
            return lerp(STONE, STONE_L, 0.5 * M.noise(x, y, z, 4.0))
        if frame and not side:
            if (u + 400) % 22 in (0, 1) or (y - ground) % 30 in (0, 1, 2):
                return BEAM if M.hsh(u, y // 3, 4) > 0.15 else BEAM_D
            k = (u + 400) % 22
            if (y - ground) % 30 > 2 and abs(k - ((y - ground) % 30) * 22 / 30) < 1.3 and ((u + 400) // 22) % 2 == 0:
                return BEAM                                            # la cruz de San Andrés
        c = lerp(PLAST, PLAST_D, 0.6 * M.noise(x, y, z, 9.0))
        if M.noise(x, y, z, 5.0) > 0.7: c = lerp(c, PLAST_L, 0.5)
        drip = M.noise(x * 0.4, y * 0.05, z * 0.4 + seed, 3.0)          # chorreones de humedad
        if drip > 0.68: c = lerp(c, STAIN, 0.45)
        if M.hsh(x // 3, y // 3, z // 3) < 0.02: c = lerp(c, STONE_D, 0.5)   # desconchado
        return c
    return f


def dormer(M, B, cx, w, lit=False, face_z=None, light_pivot=None):
    """Buhardilla en el faldón de delante: caja con tejadillo a dos aguas y su ventana. Si `lit`, la
    ventana encendida (glow 1) y el punto de la luz."""
    fz = B.front() if face_z is None else face_z
    z0 = fz - 6                                                         # metida en el tejado
    y0 = B.roof_y(z0) - 2
    h = 22
    for x in range(cx - w, cx + w):
        for y in range(y0 - 6, y0 + h):
            for z in range(z0 - 14, z0 + 1):
                if B.roof_y(z) > y + 2 and y < y0: continue
                edge = x in (cx - w, cx + w - 1) or z == z0
                if not edge: continue
                M.put(x, y, z, P, lerp(PLAST, PLAST_D, 0.5 * M.noise(x, y, z, 6.0)))
        top = y0 + h + (w - abs(x - cx + 0.5))                           # tejadillo
        for z in range(z0 - 16, z0 + 3):
            M.put(x, int(top), z, P, pu.SLATE if (x + z) % 4 else pu.SLATE_D)
            M.put(x, int(top) - 1, z, P, pu.SLATE_D)
        for y in range(y0 + h, int(top)):                                # el hastial
            M.put(x, y, z0, P, PLAST_D)
    # la ventana: marco, cristales a cuarterones y, si está encendida, la vela dentro
    wx0, wx1, wy0, wy1 = cx - w + 4, cx + w - 4, y0 + 2, y0 + h - 3
    for x in range(wx0 - 1, wx1 + 1):
        for y in range(wy0 - 1, wy1 + 1):
            if x in (wx0 - 1, wx1) or y in (wy0 - 1, wy1):
                M.put(x, y, z0 + 1, P, BEAM); continue
            bar = (x - wx0) % 5 == 4 or (y - wy0) % 6 == 5
            if bar:
                M.put(x, y, z0, P, BEAM_D); continue
            if lit:
                c = CANDLE if M.hsh(x // 2, y // 2, 3) > 0.3 else CANDLE_D
                M.V.pop((x, y, z0), None)
                M.put(x, y, z0 - 1, P, c, 1)
            else:
                M.put(x, y, z0, P, GLASS)
    for x in range(wx0 - 2, wx1 + 2): M.put(x, wy0 - 2, z0 + 1, P, STONE); M.put(x, wy0 - 2, z0 + 2, P, STONE_D)
    if lit:                                                              # contraventanas abiertas de par en par
        for s in (-1, 1):
            ux = wx0 - 1 - 5 if s < 0 else wx1 + 1
            for u in range(ux, ux + 5):
                for y in range(wy0, wy1):
                    M.put(u, y, z0 + 2, P, SHUT[1] if (y - wy0) % 3 else lerp(SHUT[1], pu.DARK, 0.4))
    if light_pivot is not None:
        light_pivot['viola'] = [cx, (wy0 + wy1) // 2, z0 + 3]
    return y0 + h


def lean(M, kx, kz):
    """Ladea toda la casa: cada voxel se corre `kx` y `kz` voxels por voxel de altura (cizalla)."""
    V = {}
    for (x, y, z), v in M.V.items():
        V[(x + int(round(y * kx)), y, z + int(round(y * kz)))] = v
    M.V = V


def casa(variant=1, zann=False):
    M = Model(S=1, seed=1922 + variant * 7 + (50 if zann else 0))
    floors = 5 if zann else 4
    FH = 30
    G = 26
    H = G + FH * (floors - 1) + 4
    HX = 30 if zann else (28, 34, 26)[(variant - 1) % 3]
    HZ = 28
    B = House(M, HX, HZ, H, 52 if zann else 46, plaster_wall(M, G, frame=(variant != 2 or zann), seed=variant))
    B.build()
    fz = B.front()
    shut = SHUT[(variant - 1) % 3]
    # la puerta y el escalón; la planta baja con una ventana enrejada
    door_x = -HX + 6 if variant % 2 else HX - 20
    B.door(door_x, 12, 22, (0.20, 0.14, 0.10), steps=1)
    wx = HX - 18 if variant % 2 else -HX + 6
    B.window(wx, 8, 10, 13, lit=False, shutters=None, panes=(2, 2))
    for y in range(8, 21, 3):                                            # la reja
        for x in range(wx - 1, wx + 11): M.put(x, y, fz + 2, P, IRON)
    # las plantas: ventanas altas y estrechas con contraventanas, casi todas a oscuras
    cols = 2 if HX < 30 else 3
    xs = [-HX + 8 + i * ((2 * HX - 22) // max(cols - 1, 1)) for i in range(cols)]
    for f in range(1, floors):
        y0 = G + (f - 1) * FH + 6
        for i, x0 in enumerate(xs):
            lit = (not zann) and M.hsh(f, i, variant) > 0.86
            closed = M.hsh(f, i, variant + 30) < 0.35
            if closed:                                                   # contraventanas cerradas
                for x in range(x0 - 1, x0 + 11):
                    for y in range(y0 - 1, y0 + 19):
                        c = shut if (y - y0) % 3 else lerp(shut, pu.DARK, 0.5)
                        if x in (x0 - 1, x0 + 10) or x == x0 + 4: c = lerp(shut, pu.DARK, 0.3)
                        if M.noise(x, y, f, 4.0) > 0.7: c = lerp(c, PLAST_D, 0.5)      # pintura pelada
                        M.put(x, y, fz + 1, P, c)
            else:
                B.window(x0, y0, 10, 18, lit=lit, shutters=shut, panes=(2, 4))
        # la viga de cada planta, que sobresale un poco (las plantas voladas)
        for x in range(-HX - 1, HX + 1):
            M.put(x, G + (f - 1) * FH, fz + 1, P, BEAM_D)
            M.put(x, G + (f - 1) * FH + 1, fz + 1, P, BEAM)
    piv = {P: [0, 0, 0]}
    if zann:                                                             # la buhardilla de Zann, encendida
        dormer(M, B, -4, 10, lit=True, light_pivot=piv)
        B.chimney(HX - 8, -10, w=4, d=3, extra=18, pots=2, smoke=False)
    else:
        dormer(M, B, (-6, 8, 0)[(variant - 1) % 3], 8, lit=False)
        B.chimney((HX - 8) * (1 if variant % 2 else -1), -8, w=4, d=3, extra=12 + variant * 3, pots=1 + variant % 2,
                  smoke=variant == 3)
    # ladeadas, cada una a su manera; la de Zann, hacia delante, sobre la calle
    k = {1: (0.035, 0.0), 2: (-0.03, 0.02), 3: (0.02, 0.03)}[(variant - 1) % 3 + 1]
    if zann: k = (-0.015, 0.035)
    if 'viola' in piv:
        vx, vy, vz = piv['viola']
        piv['viola'] = [vx + int(round(vy * k[0])), vy, vz + int(round(vy * k[1]))]
    lean(M, k[0], k[1])
    return M, piv, B.smokes


def muro():
    """Muro alto de piedra con la hiedra que lo cubre casi entero, como el del final de la calle."""
    M = Model(S=1, seed=1923)
    HX, HZ, H = 80, 6, 70
    for x in range(-HX, HX):
        for z in range(-HZ, HZ):
            for y in range(H + int(3 * M.noise(x, 0, 0, 8.0))):
                if min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) > 1 and y < H - 2: continue
                row = y // 6
                c = STONE_D if y % 6 == 0 or (x + (row % 2) * 8) % 16 == 0 else lerp(STONE, STONE_L, 0.5 * M.noise(x, y, z, 4.0))
                M.put(x, y, z, P, c)
    for x in range(-HX - 1, HX + 1):                                    # la albardilla
        for z in range(-HZ - 1, HZ + 1): M.put(x, H + 2, z, P, STONE_L if (x + z) % 5 else STONE)
    for x in range(-HX - 2, HX + 2):                                    # la hiedra, en la cara de delante y arriba
        for y in range(0, H + 6):
            n = M.noise(x, y, 0, 7.0)
            reach = 0.32 + 0.4 * (y / H)                                 # más espesa arriba, colgando
            if n < reach: continue
            depth = 1 + int(2 * M.noise(x + 50, y, 0, 3.0))
            for d in range(depth):
                c = IVY if M.hsh(x, y, d) > 0.3 else (IVY_L if M.hsh(x, y, d + 9) > 0.5 else IVY_D)
                M.put(x, y, HZ + d, P, c, 0, False)
            if y > H - 4:
                for z in range(-HZ, HZ + depth):
                    if M.hsh(x, z, y) > 0.35: M.put(x, H + 3 + (y - H + 4) // 3, z, P, IVY_D, 0, False)
    return M, {P: [0, 0, 0]}, []


def escalones():
    """Tres escalones bajos de piedra gastada, de lado a lado (4 m de ancho, 1,2 de fondo)."""
    M = Model(S=1, seed=1924)
    HX = 32
    for k in range(3):
        for x in range(-HX, HX):
            for z in range(-10 + k * 7, 10):
                y = 2 - k
                worn = M.noise(x, 0, z, 6.0) > 0.62 and z > -10 + k * 7 + 4
                c = lerp(STONE, STONE_L, 0.6 * M.noise(x, k, z, 3.0))
                if z == -10 + k * 7: c = STONE_D                                # la arista, oscura
                if worn: c = lerp(c, STONE_L, 0.4)
                for yy in range(y + 1): M.put(x, yy, z, P, c)
    return M, {P: [0, 0, 0]}, []


def pretil():
    """Pretil de piedra a la altura de la cintura, con barandilla de hierro, al borde del río (4 m)."""
    M = Model(S=1, seed=1925)
    HX, H = 32, 10
    for x in range(-HX, HX):
        for z in range(-4, 4):
            for y in range(H):
                c = STONE_D if y % 5 == 0 or (x + (y // 5) * 6) % 12 == 0 else lerp(STONE, STONE_L, 0.4 * M.noise(x, y, z, 3.0))
                if M.noise(x, y, z, 6.0) > 0.74: c = lerp(c, (0.24, 0.30, 0.20), 0.4)   # verdín
                M.put(x, y, z, P, c)
        for z in range(-5, 5): M.put(x, H, z, P, STONE_L)
    for x in range(-HX, HX, 4):                                         # los barrotes
        for y in range(H + 1, H + 14): M.put(x, y, 0, P, IRON)
    for x in range(-HX, HX):
        M.put(x, H + 14, 0, P, IRON_L); M.put(x, H + 8, 0, P, IRON)
    return M, {P: [0, 0, 0]}, []


def farol():
    """Farol de gas en un poste de hierro, con cuatro cristales y la luz dentro (32/m)."""
    M = Model(S=2, seed=1926)
    for y in range(0, 88):                                              # el poste, con su base
        r = 3 if y < 6 else (2 if y < 80 else 1)
        for x in range(-r, r):
            for z in range(-r, r): M.put(x, y, z, P, IRON if (x + z + y) % 5 else IRON_L)
    for y in range(88, 104):                                            # la linterna
        w = 6 if y < 100 else 6 - (y - 100)
        for x in range(-w, w):
            for z in range(-w, w):
                edge = x in (-w, w - 1) or z in (-w, w - 1)
                if not edge: continue
                corner = x in (-w, w - 1) and z in (-w, w - 1)
                if corner or y in (88, 99) or y >= 100: M.put(x, y, z, P, IRON)
                else: M.put(x, y, z, P, LAMP, 1)
    for y in range(90, 98):
        for x in (-1, 0):
            for z in (-1, 0): M.put(x, y, z, P, (1.0, 0.95, 0.75), 1)
    return M, {P: [0, 0, 0], 'light': [0, 94, 0]}, []


PIECES = {'casa_1': lambda: casa(1), 'casa_2': lambda: casa(2), 'casa_3': lambda: casa(3),
          'casa_zann': lambda: casa(1, zann=True), 'muro': muro, 'escalones': escalones, 'pretil': pretil, 'farol': farol}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv, smokes = fn()
        for i, s in enumerate(smokes): piv['smoke' + ('' if i == 0 else '_%d' % (i + 1))] = s
        if name.startswith('casa') or name == 'muro':                   # huecas: fuera lo de dentro
            nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
            for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
        n = M.export('models/aus_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('aus_%s: %d voxels' % (name, n))
