"""Atrezo de la noche suelta «El que acecha en la oscuridad» (hito 23.8): Federal Hill, en Providence
(1935). Una parte "body" (y "globe" en la farola), origen en el centro de la base, la cara principal hacia
+Z. Las casas de tablas son las del puerto (prt_casa_*).

«Una iglesia enorme y negra, de piedra, con un campanario cuadrado y una aguja afilada, en lo alto de la
colina, sobre un mar de tejados…» Abandonada desde 1877, cuando la secta de la Sabiduría Estrellada se fue.

  iglesia    la iglesia de la Sabiduría Estrellada: nave de piedra ennegrecida con ventanas ojivales
             cegadas o rotas, tejado de pizarra con huecos, el campanario cuadrado delante con la puerta
             cegada con tablas, el cuerpo de campanas con persianas y, dentro, el resplandor rojo del
             Trapezoedro (punto "steeple"), y la aguja de pizarra con la cruz torcida (16/m)
  farola     farola eléctrica de hierro colado de los años treinta: fuste estriado, brazo corto y un
             globo de cristal (parte "globe", lo que se apaga; punto "light") (32/m)
  verja      tramo de verja de hierro con puntas de lanza sobre un bordillo de piedra (4 m, 16/m)

Escribe models/fed_<pieza>.json. Uso: python tools/gen_atrezo_federal.py [piezas...]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
STONE = (0.27, 0.26, 0.26); STONE_D = (0.17, 0.165, 0.17); STONE_L = (0.36, 0.35, 0.34)
SOOT = (0.10, 0.10, 0.11)
SLATE = (0.15, 0.16, 0.19); SLATE_D = (0.09, 0.10, 0.12); SLATE_L = (0.22, 0.23, 0.27)
WOOD = (0.28, 0.20, 0.13); WOOD_D = (0.17, 0.12, 0.08)
IRON = (0.08, 0.08, 0.09); IRON_L = (0.20, 0.20, 0.22)
GLASS = (0.05, 0.06, 0.08); GLASS_L = (0.14, 0.16, 0.20)
GLOW = (0.86, 0.12, 0.08); GLOW_D = (0.46, 0.04, 0.04)
MOSS = (0.16, 0.20, 0.12)
LAMP = (0.92, 0.95, 1.0); LAMP_D = (0.70, 0.78, 0.92); BULB = (0.30, 0.30, 0.28)


def stone(M, x, y, z, u):
    """Sillares de piedra ennegrecida por el hollín, con chorreones y algo de musgo abajo."""
    row = y // 8
    if y % 8 == 0 or (u + (row % 2) * 10) % 20 == 0: c = STONE_D
    else: c = lerp(STONE, STONE_L, 0.5 * M.noise(x, y, z, 5.0))
    if M.noise(x * 0.5, y * 0.08, z * 0.5, 3.0) > 0.7: c = lerp(c, SOOT, 0.4)      # hollín que baja
    if y < 10: c = lerp(c, MOSS, 0.35 * M.noise(x, y, z, 3.0))
    return c


def lancet(M, put, u0, y0, w, h, broken=0.3, boarded=False, seed=0):
    """Ventana ojival en una pared (put(u, y, depth, color)): arco apuntado, parteluz, vidrios oscuros,
    algunos rotos, o cegada con tablas."""
    cx = u0 + w / 2.0
    for u in range(u0 - 1, u0 + w + 1):
        for y in range(y0 - 1, y0 + h + w // 2 + 2):
            dx = abs(u + 0.5 - cx)
            # el arco: dos círculos de radio w centrados en los arranques opuestos
            top = y0 + h + math.sqrt(max(0.0, w * w - (dx + w / 2.0) ** 2)) - w * 0.87
            inside = u0 <= u < u0 + w and y < y0 + h + max(0.0, top - y0 - h) and y >= y0
            edge = not inside and (u0 - 1 <= u <= u0 + w) and y <= y0 + h + max(0.0, top - y0 - h) + 1 and y >= y0 - 1
            if edge:
                put(u, y, 1, STONE_L if M.hsh(u, y, 4) > 0.3 else STONE)
                continue
            if not inside: continue
            if boarded:
                c = WOOD if ((y - y0) // 4) % 2 else WOOD_D
                put(u, y, 1, c)
                continue
            if abs(u + 0.5 - cx) < 0.8:                                   # el parteluz
                put(u, y, 1, STONE); continue
            if (y - y0) % 7 == 0: put(u, y, 0, IRON); continue           # el plomo
            if M.hsh(u // 2, y // 3, seed + 7) < broken: put(u, y, -1, SOOT); continue   # roto: dentro, oscuro
            put(u, y, 0, GLASS if M.hsh(u, y, seed) > 0.25 else GLASS_L)


def iglesia():
    M = Model(S=1, seed=1935)
    HX, HZ, H = 60, 92, 100                          # nave de 7,5 x 11,5 m y 6,25 de pared
    PITCH = 78
    TX, TZ0, TZ1 = 26, HZ - 12, HZ + 40              # el campanario: 3,25 m de lado, delante
    TH, BH, SH = 290, 60, 150                        # hasta el cuerpo de campanas, su alto y la aguja
    # la nave: paredes de una capa, el tejado a dos aguas (cumbrera a lo largo, en z)
    def roof_y(x): return H + int(PITCH * (1 - abs(x + 0.5) / (HX + 4)))
    for x in range(-HX, HX):
        for z in range(-HZ, HZ):
            side = x in (-HX, HX - 1)
            end = z in (-HZ, HZ - 1)
            if not (side or end): continue
            top = roof_y(x) - 1 if end else H - 1
            for y in range(0, top + 1): M.put(x, y, z, P, stone(M, x, y, z, z if side else x))
    for x in range(-HX - 4, HX + 4):                  # pizarra en hileras, con huecos
        for z in range(-HZ - 3, HZ + 3):
            y = roof_y(x)
            row = abs(x) // 2
            hole = M.noise(x, 0, z, 9.0) > 0.78 and abs(x) < HX - 6 and abs(z) < HZ - 8
            if hole: M.put(x, y - 3, z, P, SOOT); continue
            c = SLATE if M.hsh((z + (row % 2) * 2) // 4, row, 1) < 0.6 else lerp(SLATE, SLATE_L, 0.5)
            if M.noise(x, y, z, 6.0) > 0.7: c = lerp(c, MOSS, 0.4)
            M.put(x, y, z, P, c); M.put(x, y - 1, z, P, SLATE_D)
        M.put(x, roof_y(0) + 1, 0, P, SLATE_L)
    for z in range(-HZ - 3, HZ + 3): M.put(0, roof_y(0) + 1, z, P, SLATE_L); M.put(-1, roof_y(-1) + 1, z, P, SLATE_L)
    # contrafuertes en los costados, y las ventanas ojivales entre ellos
    for s in (-1, 1):
        xw = HX - 1 if s > 0 else -HX
        for zc in range(-HZ + 14, HZ - 20, 30):
            for y in range(0, 74):
                d = 6 if y < 40 else (4 if y < 60 else 2)
                for z in range(zc - 3, zc + 3):
                    for k in range(1, d + 1): M.put(xw + s * k, y, z, P, stone(M, xw + s * k, y, z, y))
        def put(u, y, depth, c, s=s, xw=xw):
            M.V.pop((xw, y, u), None)
            M.put(xw + s * depth, y, u, P, c)
        for i, zc in enumerate(range(-HZ + 29, HZ - 20, 30)):
            lancet(M, put, zc - 7, 22, 14, 40, broken=0.35, boarded=(i + (s > 0)) % 3 == 0, seed=i * 5 + s)
    # la fachada de atrás: una ojiva grande cegada
    def put_back(u, y, depth, c):
        M.V.pop((u, y, -HZ), None)
        M.put(u, y, -HZ - depth, P, c)
    lancet(M, put_back, -12, 30, 24, 46, boarded=True)
    # el campanario: torre cuadrada delante, que pisa la nave
    for x in range(-TX, TX):
        for z in range(TZ0, TZ1):
            ring = x in (-TX, TX - 1) or z in (TZ0, TZ1 - 1)
            if not ring: continue
            for y in range(0, TH):
                M.put(x, y, z, P, stone(M, x, y, z, x if z == TZ1 - 1 else z))
    # cornisas de la torre
    for yc in (TH // 3, 2 * TH // 3, TH):
        for x in range(-TX - 2, TX + 2):
            for z in range(TZ0 - 2, TZ1 + 2):
                if -TX < x < TX - 1 and TZ0 < z < TZ1 - 1: continue
                for d in range(3): M.put(x, yc + d, z, P, STONE_L if d == 2 else STONE)
    # la puerta: ojiva cegada con tablas, con escalones
    fz = TZ1 - 1
    def put_front(u, y, depth, c):
        M.V.pop((u, y, fz), None)
        M.put(u, y, fz + depth, P, c)
    lancet(M, put_front, -10, 4, 20, 40, boarded=True)
    for k in range(3):
        for x in range(-16 + k, 16 - k):
            for d in range(1, 10 - 3 * k): M.put(x, k, fz + d, P, STONE if M.hsh(x, k, d) > 0.2 else STONE_D)
    # ventanas estrechas de la torre (delante y al este) y el rosetón ciego
    lancet(M, put_front, -5, 120, 10, 34, broken=0.5, seed=31)
    def put_east(u, y, depth, c):
        M.V.pop((TX - 1, y, u), None)
        M.put(TX - 1 + depth, y, u, P, c)
    lancet(M, put_east, TZ0 + 18, 120, 10, 34, broken=0.5, seed=33)
    for x in range(-12, 13):                           # el rosetón, de piedra y hueco
        for y in range(190, 216):
            r = math.hypot(x, y - 203)
            if r > 12.5: continue
            spoke = abs(math.sin(math.atan2(y - 203, x) * 4)) < 0.25 or r < 3 or r > 11
            M.V.pop((x, y, fz), None)
            M.put(x, y, fz + (1 if spoke else -1), P, STONE_L if spoke else SOOT)
    # el cuerpo de campanas: cuatro aberturas con persianas, y dentro, el Trapezoedro que brilla rojo
    yb0, yb1 = TH + 3, TH + BH
    for x in range(-TX, TX):
        for z in range(TZ0, TZ1):
            ring = x in (-TX, TX - 1) or z in (TZ0, TZ1 - 1)
            if not ring: continue
            for y in range(yb0, yb1):
                u = x if z in (TZ0, TZ1 - 1) else z - (TZ0 + TZ1) // 2
                opening = abs(u + 0.5) < TX - 7 and yb0 + 8 <= y < yb1 - 10
                if opening:
                    if (y - yb0) % 5 < 2: M.put(x, y, z, P, WOOD if M.hsh(x, y, z) > 0.3 else WOOD_D)   # persianas
                    continue
                M.put(x, y, z, P, stone(M, x, y, z, u))
    cy = (yb0 + yb1) // 2 - 4
    cz = (TZ0 + TZ1) // 2
    for x in range(-3, 4):                             # el Trapezoedro en su caja, y su resplandor
        for y in range(-3, 4):
            for z in range(-3, 4):
                if abs(x) + abs(y) + abs(z) > 4: continue
                M.put(x, cy + y, cz + z, P, GLOW if abs(x) + abs(y) + abs(z) < 3 else GLOW_D, 1)
    for x in range(-6, 7):
        for z in range(-6, 7): M.put(x, cy - 5, cz + z, P, IRON)
    for x in range(-TX - 2, TX + 2):                   # la cornisa de arriba
        for z in range(TZ0 - 2, TZ1 + 2):
            if -TX < x < TX - 1 and TZ0 < z < TZ1 - 1: continue
            for d in range(3): M.put(x, yb1 + d, z, P, STONE_L if d == 2 else STONE)
    # la aguja de pizarra: pirámide de cuatro caras, hueca
    y0 = yb1 + 3
    for y in range(y0, y0 + SH):
        t = (y - y0) / SH
        r = (TX + 1) * (1 - t)
        ri = int(r)
        for x in range(-ri - 1, ri + 1):
            for z in range(-ri - 1, ri + 1):
                if max(abs(x + 0.5), abs(z + 0.5)) < r - 2: continue
                if max(abs(x + 0.5), abs(z + 0.5)) > r + 0.5: continue
                c = SLATE if (y // 3 + (x + z) // 4) % 3 else SLATE_L
                if M.noise(x, y, z, 6.0) > 0.76: c = SLATE_D
                M.put(x, y, cz + z, P, c)
    # la cruz torcida de hierro, arriba
    top = y0 + SH
    for y in range(top, top + 22): M.put(int((y - top) * 0.18), y, cz, P, IRON)
    for x in range(-6, 7): M.put(x + 3, top + 15 + x // 4, cz, P, IRON)
    piv = {P: [0, 0, 0], 'steeple': [0, cy, cz + TX + 2]}
    return M, piv


def farola():
    """Farola de hierro colado de 3,3 m: base, fuste estriado, capitel y el globo (32/m)."""
    M = Model(S=2, seed=1936)
    for y in range(0, 96):
        r = 4 if y < 10 else (3 if y < 14 else (2.4 if y < 88 else 3))
        ri = int(math.ceil(r))
        for x in range(-ri, ri):
            for z in range(-ri, ri):
                if (x + 0.5) ** 2 + (z + 0.5) ** 2 > r * r + 0.5: continue
                flute = y >= 14 and y < 88 and (math.atan2(z + 0.5, x + 0.5) * 8 / math.pi) % 2 < 0.7
                M.put(x, y, z, P, IRON_L if flute or y in (9, 13, 87) else IRON)
    for y in range(96, 100):                           # el portalámparas
        for x in range(-3, 3):
            for z in range(-3, 3): M.put(x, y, z, P, IRON)
    for y in range(101, 107):                          # la bombilla, oscura (con el globo apagado se ve)
        for x in (-1, 0):
            for z in (-1, 0): M.put(x, y, z, P, BULB)
    for y in range(99, 117):                           # el globo de cristal (parte globe: lo que se apaga)
        t = (y - 99) / 18.0
        r = 6.5 * math.sin(math.pi * min(1.0, t * 1.05 + 0.08))
        ri = int(math.ceil(r))
        for x in range(-ri, ri):
            for z in range(-ri, ri):
                q = math.sqrt((x + 0.5) ** 2 + (z + 0.5) ** 2)
                if q > r or q < r - 1.6: continue
                M.put(x, y, z, 'globe', LAMP if M.hsh(x, y, z) > 0.3 else LAMP_D, 1)
    for x in range(-2, 2):                             # el remate
        for z in range(-2, 2): M.put(x, 117, z, P, IRON); M.put(x // 2, 118, z // 2, P, IRON)
    return M, {P: [0, 0, 0], 'globe': [0, 99, 0], 'light': [0, 106, 0]}


def verja():
    """Verja de hierro de 4 m con puntas de lanza sobre un bordillo de piedra, y un pilar en un extremo."""
    M = Model(S=1, seed=1937)
    HX = 32
    for x in range(-HX, HX):
        for z in range(-2, 2):
            for y in range(4): M.put(x, y, z, P, lerp(STONE, STONE_L, 0.5 * M.noise(x, y, z, 3.0)) if y < 3 else STONE_L)
    for x in range(-HX + 2, HX - 4, 3):
        lean = (M.hsh(x, 0, 1) - 0.5) * 0.08          # alguna torcida
        for y in range(4, 26): M.put(x + int(round((y - 4) * lean)), y, 0, P, IRON if y % 7 else IRON_L)
        M.put(x + int(round(22 * lean)), 26, 0, P, IRON_L)
    for x in range(-HX, HX - 4):
        for y in (8, 22): M.put(x, y, 0, P, IRON)
    for x in range(HX - 5, HX):                        # el pilar de piedra
        for z in range(-3, 3):
            for y in range(32): M.put(x, y, z, P, STONE_L if y >= 30 else lerp(STONE, STONE_L, 0.5 * M.noise(x, y, z, 3.0)))
    return M, {P: [0, 0, 0]}


PIECES = {'iglesia': iglesia, 'farola': farola, 'verja': verja}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/fed_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('fed_%s: %d voxels' % (name, n))
