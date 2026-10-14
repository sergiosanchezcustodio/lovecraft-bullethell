"""Edificios del puerto de Auckland (nivel 3 de la parte 3, revisión de arte del 14-10-2026). Una
parte "body", origen en el centro de la base, frente hacia +z, a 16 voxels/m (piezas de borde,
huecas). Cada chimenea marca un punto "smoke" ("smoke_2"...) del que sale humo en la partida
(ArenaBuilder._smoke); la taberna marca además "light", el farol de la puerta.

  taberna   taberna de dos plantas: bajo pintado de verde oscuro con ventanales encendidos,
            puerta con farol, barriles, banco y pizarra; arriba, revoco con entramado; cartel
            colgado de una ménsula de hierro con un ancla y una jarra pintadas
  tienda    efectos navales: escaparate encendido con rollos de cabo, faroles y un timón, toldo a
            rayas, rótulo sobre el escaparate con un timón pintado, cajas y cabos en la acera
  almacen   almacén de ladrillo de tres plantas: portones de carga apilados, viga con polea y
            cabo, portón grande abajo, rótulo pintado en la pared y ventanas pequeñas
  casa      casa de tablas de dos plantas, crema, con contraventanas verdes y porche
  casa_2    la misma en azul pálido con contraventanas rojas, mirador y otra chimenea

Escribe models/prt_<pieza>.json. Uso: python tools/gen_atrezo_puerto.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
BRICK = (0.44, 0.22, 0.16); BRICK_D = (0.32, 0.16, 0.12); MORTAR = (0.50, 0.46, 0.41)
STONE = (0.46, 0.45, 0.42); STONE_D = (0.34, 0.33, 0.31)
SLATE = (0.20, 0.22, 0.25); SLATE_D = (0.14, 0.15, 0.17); SLATE_L = (0.28, 0.30, 0.33)
TRIM = (0.74, 0.72, 0.64); TRIM_D = (0.52, 0.50, 0.44)
WOOD = (0.36, 0.26, 0.17); WOOD_D = (0.22, 0.16, 0.10)
IRON = (0.12, 0.12, 0.13); IRON_L = (0.28, 0.28, 0.30)
GLASS = (0.10, 0.13, 0.17); GLASS_L = (0.22, 0.27, 0.32)
LIT = (1.0, 0.70, 0.36); LIT_D = (0.86, 0.50, 0.22)
GOLD = (0.78, 0.60, 0.24); MOSS = (0.24, 0.30, 0.18); DARK = (0.05, 0.05, 0.06)
ROPE = (0.56, 0.48, 0.32); ROPE_D = (0.42, 0.36, 0.24)


class House:
    """Caja hueca de HX x HZ (medias, en voxels) y H de alto con tejado a dos aguas (cumbrera
    paralela a la fachada). Los hastiales suben hasta la cara de abajo del tejado: no quedan
    huecos entre pared y tejado."""

    def __init__(self, M, HX, HZ, H, pitch, wall):
        self.M, self.HX, self.HZ, self.H, self.pitch, self.wall = M, HX, HZ, H, pitch, wall
        self.ov = 4                                                 # vuelo del alero
        self.smokes = []

    def roof_y(self, z):
        return self.H + int(self.pitch * (1 - abs(z + 0.5) / (self.HZ + self.ov)))

    def front(self):
        return self.HZ - 1

    def build(self, roof=None):
        M, HX, HZ, H = self.M, self.HX, self.HZ, self.H
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                edge = min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z)
                if edge > 1: continue
                side = min(x + HX, HX - 1 - x) <= 1
                top = self.roof_y(z) - 1 if side else H - 1
                for y in range(0, top + 1):
                    u = z if side else x
                    M.put(x, y, z, P, self.wall(x, y, z, u, side))
        for x in range(-HX - self.ov, HX + self.ov):                   # tejado de pizarra en hileras
            for z in range(-HZ - self.ov, HZ + self.ov):
                y = self.roof_y(z)
                c = roof(x, y, z) if roof else self.slate(x, y, z)
                M.put(x, y, z, P, c)
                M.put(x, y - 1, z, P, SLATE_D)
        for x in range(-HX - self.ov, HX + self.ov):                   # cumbrera y canalón
            M.put(x, self.roof_y(0) + 1, 0, P, SLATE_L); M.put(x, self.roof_y(-1) + 1, -1, P, SLATE_L)
            for s in (-1, 1):
                z = s * (HZ + self.ov) - (1 if s > 0 else 0)
                M.put(x, self.roof_y(z) - 1, z + s, P, IRON_L if M.hsh(x, 0, s) > 0.2 else (0.30, 0.42, 0.36))
        for s in (-1, 1):                                              # tablas de los hastiales
            for z in range(-HZ - self.ov, HZ + self.ov):
                for d in range(2): M.put(s * (HX + self.ov) - (1 if s > 0 else 0), self.roof_y(z) - d, z, P, TRIM_D)

    def slate(self, x, y, z):
        M = self.M
        row = (abs(z) // 2)
        c = SLATE if M.hsh((x + (row % 2) * 2) // 4, row, 1) < 0.6 else lerp(SLATE, SLATE_L, 0.5)
        if (x + (row % 2) * 2) % 4 == 0: c = SLATE_D
        if M.noise(x, y, z, 8.0) > 0.68: c = lerp(c, MOSS, 0.5)
        return c

    def chimney(self, x, z, w=4, d=3, extra=14, pots=2, smoke=True):
        """Chimenea de ladrillo que nace en la pared y sale por el tejado, con su remate y sus
        cañones; apunta el punto del humo."""
        M = self.M
        top = self.roof_y(z) + extra
        for y in range(self.H - 6, top):
            for xx in range(x - w, x + w):
                for zz in range(z - d, z + d):
                    if min(xx - x + w, x + w - 1 - xx, zz - z + d, z + d - 1 - zz) > 0 and y < top - 1: continue
                    c = MORTAR if y % 3 == 0 or (xx + zz + (y // 3) % 2 * 2) % 4 == 0 else (BRICK if M.hsh(xx, y // 3, zz) < 0.7 else BRICK_D)
                    if y > top - 4: c = lerp(c, DARK, 0.5)                  # hollín
                    M.put(xx, y, zz, P, c)
        for xx in range(x - w - 1, x + w + 1):                        # remate
            for zz in range(z - d - 1, z + d + 1): M.put(xx, top, zz, P, STONE)
        for k in range(pots):                                          # cañones
            px = x - w + 2 + k * (2 * w - 4) // max(pots - 1, 1) if pots > 1 else x
            for y in range(top + 1, top + 5):
                for dx in (-1, 0):
                    for dz in (-1, 0): M.put(px + dx, y, z + dz, P, (0.56, 0.36, 0.24) if y < top + 4 else DARK)
            if smoke: self.smokes.append([px, top + 6, z])

    def window(self, x0, y0, w, h, lit=False, shutters=None, face='front', panes=(2, 3), sill=True, boarded=False):
        M = self.M
        fz = self.front()
        def put(u, y, depth, c):
            if face == 'front': M.put(u, y, fz + depth, P, c)
            elif face == 'back': M.put(u, y, -self.HZ - depth, P, c)
            else:
                s = 1 if face == 'east' else -1
                M.put(s * (self.HX - 1) + s * depth, y, u, P, c)
        for u in range(x0 - 1, x0 + w + 1):
            for y in range(y0 - 1, y0 + h + 1):
                if u in (x0 - 1, x0 + w) or y in (y0 - 1, y0 + h):
                    put(u, y, 1, TRIM if M.hsh(u, y, 3) > 0.15 else TRIM_D); continue
                pu, pv = (u - x0) * panes[0] // w, (y - y0) * panes[1] // h
                bar = (u - x0) * panes[0] % w < panes[0] and u > x0 or (y - y0) * panes[1] % h < panes[1] and y > y0
                if boarded:                                           # cegada con tablas clavadas
                    c = WOOD if ((y - y0) // 4) % 2 else lerp(WOOD, WOOD_D, 0.6)
                    if abs((u - x0) - (y - y0) * w / h) < 1.2: c = WOOD_D
                    if ((y - y0) // 4) % 5 == 3 and M.hsh(u // 3, y0, 9) > 0.5: c = DARK      # tabla que falta
                    put(u, y, 1, c)
                    continue
                if bar: c = TRIM_D
                elif lit: c = LIT if M.hsh(pu, pv, 7) > 0.25 else LIT_D
                else: c = GLASS if M.hsh(pu, pv + u, 8) > 0.2 else GLASS_L
                put(u, y, 0, c)
                if lit and not bar: M.V[self._key(u, y, 0, face)][2] = 1
        if sill:
            for u in range(x0 - 2, x0 + w + 2): put(u, y0 - 2, 1, TRIM); put(u, y0 - 2, 2, TRIM_D)
        for u in range(x0 - 2, x0 + w + 2): put(u, y0 + h + 1, 1, TRIM_D)
        if shutters:
            for s in (-1, 1):
                ux = x0 - 1 - w // 2 if s < 0 else x0 + w + 1
                for u in range(ux, ux + w // 2):
                    for y in range(y0, y0 + h):
                        put(u, y, 1, shutters if (y - y0) % 3 else lerp(shutters, DARK, 0.4))

    def _key(self, u, y, depth, face):
        if face == 'front': return (u, y, self.front() + depth)
        if face == 'back': return (u, y, -self.HZ - depth)
        s = 1 if face == 'east' else -1
        return (s * (self.HX - 1) + s * depth, y, u)

    def door(self, x0, w, h, col, lit_fan=False, steps=2):
        M = self.M
        fz = self.front()
        for u in range(x0 - 2, x0 + w + 2):
            for y in range(steps, h + 3):
                inside = x0 <= u < x0 + w and y < h
                if not inside:
                    M.put(u, y, fz + 1, P, TRIM if (u in (x0 - 2, x0 - 1, x0 + w, x0 + w + 1) or y >= h) else TRIM_D)
                    continue
                c = col if (u - x0) % 5 and (y - steps) % 9 else lerp(col, DARK, 0.4)   # cuarterones
                if lit_fan and y > h - 5: c = LIT
                M.V.pop((u, y, fz + 1), None)
                M.put(u, y, fz, P, c)
                if lit_fan and y > h - 5: M.V[(u, y, fz)][2] = 1
        M.put(x0 + w - 2, h // 2, fz + 1, P, GOLD)                    # pomo
        for k in range(steps):                                         # escalones de piedra
            for u in range(x0 - 3 + k, x0 + w + 3 - k):
                for d in range(1, 4 + 3 * (steps - k)):
                    M.put(u, k, fz + d, P, STONE if M.hsh(u, k, d) > 0.2 else STONE_D)


def brick_wall(M, plinth=8):
    def f(x, y, z, u, side):
        if y < plinth: return lerp(STONE_D, STONE, 0.6 * M.noise(x, y, z, 3.0))
        course = y // 2
        if y % 2 == 0: return MORTAR
        if (u + (course % 2) * 2) % 4 == 0: return MORTAR
        c = BRICK if M.hsh(course, (u + (course % 2) * 2) // 4, 2) < 0.7 else BRICK_D
        if M.noise(x, y, z, 10.0) > 0.72: c = lerp(c, MOSS, 0.35)
        if M.noise(x, y, z, 6.0) > 0.8: c = lerp(c, (0.10, 0.08, 0.07), 0.4)        # hollín y mugre
        return c
    return f


def board_wall(M, paint, plinth=6, peel=0.8):
    def f(x, y, z, u, side):
        if y < plinth: return lerp(STONE_D, STONE, 0.6 * M.noise(x, y, z, 3.0))
        c = paint
        if (y - plinth) % 3 == 0: c = lerp(paint, DARK, 0.45)                       # sombra de la tabla de encima
        elif (y - plinth) % 3 == 2: c = lerp(paint, (1, 1, 1), 0.08)
        if M.noise(x, y, z, 4.0) > peel: c = lerp(lerp(WOOD, WOOD_D, M.noise(x, y, z, 2.0)), paint, 0.3)   # pintura saltada
        if y < plinth + 6: c = lerp(c, MOSS, 0.25 * M.noise(x, y, z, 3.0))
        return c
    return f


def _icon(M, cx, cy, x, s, art, cols):
    """Pinta un dibujo de píxeles (lista de cadenas) en el plano x = constante, centrado en
    (cy, cx) en coordenadas (y, z). s: escala."""
    h = len(art)
    for j, row in enumerate(art):
        for i, ch in enumerate(row):
            if ch == '.': continue
            for a in range(s):
                for b in range(s):
                    M.put(x, cy + (h - 1 - j) * s + a, cx + (i - len(row) // 2) * s + b, P, cols[ch])


ANCHOR = ["...ooo...",
          "...o.o...",
          "...ooo...",
          ".ooooooo.",
          "....o....",
          "....o....",
          "....o....",
          "o...o...o",
          "oo..o..oo",
          ".oo.o.oo.",
          "..ooooo..",
          "...ooo..."]
TANKARD = ["wwwww.",
           "aaaaa.",
           "aaaaaaa",
           "aaaaa.a",
           "aaaaa.a",
           "aaaaaaa",
           "aaaaa.",
           "aaaaa."]
WHEEL = ["....o....",
         ".o..o..o.",
         "..ooooo..",
         "..o.o.o..",
         "ooooxoooo",
         "..o.o.o..",
         "..ooooo..",
         ".o..o..o.",
         "....o...."]


FISH = ["...oo.....",
        "..oooo..o.",
        ".oooooooo.",
        "ooxoooooo.",
        ".oooooooo.",
        "..oooo..o.",
        "...oo....."]


def taberna(inn=False):
    """inn: la de Innsmouth, granate desconchado, arriba casi toda tapiada y un pez en el cartel."""
    M = Model(S=1, seed=301 + (20 if inn else 0))
    GREEN = (0.12, 0.24, 0.18); GREEN_D = (0.08, 0.16, 0.12); PLAST = (0.70, 0.66, 0.56); BEAM = (0.20, 0.14, 0.09)
    if inn: GREEN, GREEN_D, PLAST = (0.30, 0.11, 0.09), (0.20, 0.07, 0.06), (0.56, 0.54, 0.48)
    HX, HZ, H, G = 60, 40, 104, 50
    def wall(x, y, z, u, side):
        if y < 6: return lerp(STONE_D, STONE, 0.6 * M.noise(x, y, z, 3.0))
        if y < G:                                                     # bajo pintado
            c = GREEN if (u // 6) % 2 or side else lerp(GREEN, GREEN_D, 0.5)
            if not side and u % 6 == 0: c = GREEN_D
            if M.noise(x, y, z, 6.0) > (0.66 if inn else 0.76): c = lerp(c, WOOD, 0.5)
            return c
        if G <= y < G + 3: return BEAM                                # viga de la planta
        if (u + 200) % 20 in (0, 1) or y in (H - 2, H - 1) or ((u + 200) % 20 + y) % 20 in (0, 1) and (u + 200) % 40 < 20:
            return BEAM                                               # entramado
        return lerp(PLAST, (0.56, 0.52, 0.44), 0.5 * M.noise(x, y, z, 7.0))
    B = House(M, HX, HZ, H, 40, wall)
    B.build()
    fz = B.front()
    for x0 in (-54, 14):                                              # ventanales encendidos del bajo
        B.window(x0, 12, 34, 30, lit=True, panes=(6, 4))
    B.door(-12, 18, 40, GREEN_D, lit_fan=True, steps=2)
    for x0 in (-52, -20, 12, 40):                                     # ventanas de arriba, una encendida
        B.window(x0, G + 14, 12, 22, lit=(x0 == 12), panes=(2, 3), boarded=inn and x0 in (-52, 40))
    for x in range(-HX, HX):                                          # imposta pintada sobre el bajo
        for y in (G - 4, G - 3):
            M.put(x, y, fz + 1, P, GOLD if y == G - 3 and (x // 4) % 2 else GREEN_D)
    # ménsula de hierro con el cartel colgado (perpendicular a la fachada)
    SX = 44
    for z in range(fz + 1, fz + 24):
        M.put(SX, G + 6, z, P, IRON); M.put(SX, G + 7, z, P, IRON)
        if z < fz + 12: M.put(SX, G + 6 - (z - fz - 1), z, P, IRON)    # tornapunta
    for zz in (fz + 8, fz + 21):
        for y in range(G - 2, G + 6): M.put(SX, y, zz, P, IRON_L)
    for z in range(fz + 6, fz + 24):                                  # tabla del cartel
        for y in range(G - 26, G - 1):
            border = z in (fz + 6, fz + 23) or y in (G - 26, G - 2)
            for x in (SX - 1, SX, SX + 1):
                c = GOLD if border else (GREEN if x == SX else GREEN_D)
                if x == SX: c = WOOD_D
                M.put(x, y, z, P, c)
    for xs in (SX - 2, SX + 2):                                       # ancla (o pez) y jarra pintadas, por las dos caras
        if inn: _icon(M, fz + 15, G - 22, xs, 1, FISH, {'o': (0.56, 0.62, 0.58), 'x': DARK})
        else: _icon(M, fz + 15, G - 24, xs, 1, ANCHOR, {'o': GOLD})
    for xs in (SX - 2, SX + 2):
        for j, row in enumerate(TANKARD):
            for i, ch in enumerate(row):
                if ch == '.': continue
                M.put(xs, G - 10 - j, fz + 9 + i, P, (0.92, 0.90, 0.84) if ch == 'w' else (0.70, 0.52, 0.26))
    # farol de la puerta
    for y in range(32, 46):
        for x in range(10, 15):
            for z in range(fz + 2, fz + 7):
                edge = x in (10, 14) or z in (fz + 2, fz + 6) or y in (32, 45)
                M.put(x, y, z, P, IRON if edge or y > 42 else LIT, glow=0 if edge or y > 42 else 1)
    # barriles, banco y pizarra
    for bx, bz in ((-62, fz + 6), (-56, fz + 13), (32, fz + 7)):
        for y in range(0, 15):
            r = 4 + (1 if 3 < y < 11 else 0)
            for x in range(bx - r, bx + r + 1):
                for z in range(bz - r, bz + r + 1):
                    if (x - bx) ** 2 + (z - bz) ** 2 <= r * r:
                        M.put(x, y, z, P, IRON if y in (2, 12) else (WOOD if (x + z) % 3 else WOOD_D))
    for x in range(-40, -18):
        for z in range(fz + 2, fz + 6): M.put(x, 8, z, P, WOOD)
        if x in (-39, -20):
            for y in range(0, 8): M.put(x, y, fz + 3, P, WOOD_D)
    for y in range(4, 22):                                            # pizarra de pie
        for z in range(fz + 3, fz + 14):
            if y > 20 or z in (fz + 3, fz + 13): M.put(38, y, z, P, WOOD); continue
            M.put(38, y, z, P, (0.12, 0.13, 0.12) if M.hsh(y // 2, z, 4) > 0.3 or y % 3 else (0.70, 0.70, 0.66))
    B.chimney(-46, -6, extra=16, pots=2)
    B.chimney(40, -6, extra=12, pots=1, smoke=not inn)
    piv = {P: [0, 0, 0], 'light': [12, 40, fz + 5]}
    return M, piv, B.smokes


CANS = [(0.62, 0.16, 0.12), (0.80, 0.70, 0.30), (0.84, 0.82, 0.76), (0.30, 0.44, 0.30), (0.50, 0.32, 0.18)]


def tienda(inn=False):
    """inn: el ultramarinos de Innsmouth (la tienda de la cadena First National del relato): frente
    verde, toldo verde y crema, estantes de latas y tarros y un saco de harina en el escaparate."""
    M = Model(S=1, seed=302 + (20 if inn else 0))
    BLUE = (0.14, 0.20, 0.30); BLUE_D = (0.09, 0.13, 0.20)
    if inn: BLUE, BLUE_D = (0.16, 0.26, 0.18), (0.10, 0.17, 0.12)
    HX, HZ, H, G = 52, 38, 98, 52
    brick = brick_wall(M)
    def wall(x, y, z, u, side):
        if y < G and not side and 6 <= y:                             # frente de tienda de madera
            c = BLUE if u % 8 else BLUE_D
            return c
        return brick(x, y, z, u, side)
    B = House(M, HX, HZ, H, 36, wall)
    B.build()
    fz = B.front()
    B.window(-46, 12, 50, 30, lit=True, panes=(5, 3))                  # escaparate
    B.door(12, 16, 42, BLUE_D, lit_fan=True, steps=1)
    B.window(32, 16, 14, 22, lit=True, panes=(2, 3))
    if inn:                                                           # estantes de latas y tarros
        for y0 in (16, 26, 36):
            for x in range(-45, 4):
                M.put(x, y0 - 1, fz - 2, P, WOOD_D)
                if (x + 45) % 4 < 3 and M.hsh(x // 4, y0, 5) > 0.15:
                    for y in range(y0, y0 + 5): M.put(x, y, fz - 2, P, CANS[int(M.hsh(x // 4, y0, 6) * 5)] if y < y0 + 4 else IRON_L)
        for x in range(-12, 0):                                       # saco de harina
            for y in range(12, 22):
                if ((x + 6) / 6) ** 2 + ((y - 16) / 6) ** 2 < 1: M.put(x, y, fz - 1, P, (0.84, 0.80, 0.70) if (x + y) % 5 else (0.66, 0.62, 0.52))
    # lo del escaparate: rollos de cabo, faroles y un timón a contraluz
    for cx in (() if inn else (-38, -26)):
        for a in range(0, 360, 10):
            for r in (3, 4, 5):
                M.put(cx + int(r * math.cos(math.radians(a))), 18 + int(r * math.sin(math.radians(a))), fz - 1, P, ROPE if r != 4 else ROPE_D)
    for k, cx in enumerate(() if inn else (-14, -8)):
        for y in range(26, 34):
            for x in (cx, cx + 1, cx + 2): M.put(x, y, fz - 1, P, IRON if y in (26, 33) or x != cx + 1 else (1.0, 0.82, 0.40), glow=0 if y in (26, 33) or x != cx + 1 else 1)
    for j, row in enumerate([] if inn else WHEEL):
        for i, ch in enumerate(row):
            if ch != '.': M.put(-2 + i - 4, 34 - j, fz - 1, P, WOOD_D)
    # rótulo sobre el escaparate con un timón pintado
    for x in range(-HX + 2, HX - 2):
        for y in range(G - 8, G + 2):
            border = y in (G - 8, G + 1) or x in (-HX + 2, HX - 3)
            c = GOLD if border else BLUE_D
            if not border and abs(x) > 10 and G - 6 <= y <= G - 2 and (x + 60) % 6 < 4 and M.hsh((x + 60) // 6, 0, y % 2) > 0.2: c = (0.84, 0.80, 0.66)
            M.put(x, y, fz + 2, P, c)
    for j, row in enumerate(WHEEL):
        for i, ch in enumerate(row):
            if ch != '.' and not inn: M.put(i - 4, G - j, fz + 3, P, GOLD)
    # toldo a rayas, inclinado sobre la acera
    for x in range(-HX + 2, 10):
        for k in range(16):
            y = G - 10 - k // 2
            M.put(x, y, fz + 3 + k, P, ((0.20, 0.34, 0.22) if inn else (0.62, 0.14, 0.12)) if (x // 4) % 2 else (0.84, 0.80, 0.70))
        if x % 4 == 0:
            M.put(x, G - 18, fz + 18, P, (0.62, 0.14, 0.12)); M.put(x, G - 19, fz + 18, P, (0.62, 0.14, 0.12))   # festón
    for x in (-HX + 3, 8):                                            # brazos del toldo
        for k in range(16): M.put(x, G - 10 - k // 2 - 1, fz + 3 + k, P, IRON)
    for x0 in (-44, -14, 16):                                         # ventanas de arriba
        B.window(x0, G + 12, 12, 22, lit=(x0 == -14), panes=(2, 3), shutters=None, boarded=inn and x0 == 16)
    # cajas y cabos en la acera
    for bx, bz in ((30, fz + 8), (40, fz + 10)):
        for x in range(bx - 5, bx + 5):
            for z in range(bz - 4, bz + 4):
                for y in range(0, 9):
                    edge = x in (bx - 5, bx + 4) or z in (bz - 4, bz + 3) or y in (0, 8)
                    if edge: M.put(x, y, z, P, WOOD_D if y in (0, 8) or (x + y) % 4 == 0 else WOOD)
    for a in range(0, 360, 8):
        for r in range(2, 7):
            M.put(-30 + int(r * math.cos(math.radians(a))), 1 + (r % 2), fz + 10 + int(r * math.sin(math.radians(a))), P, ROPE if r % 2 else ROPE_D)
    B.chimney(-30, -10, extra=14, pots=2)
    return M, {P: [0, 0, 0]}, B.smokes


def almacen():
    M = Model(S=1, seed=303)
    HX, HZ, H = 60, 40, 140
    brick = brick_wall(M, plinth=10)
    B = House(M, HX, HZ, H, 30, brick)
    B.build()
    fz = B.front()
    for y0 in (8, 52, 96):                                            # portones de carga apilados
        w, h = (28, 40) if y0 == 8 else (18, 32)
        x0 = -w // 2
        for u in range(x0 - 2, x0 + w + 2):
            for y in range(y0 - 2, y0 + h + 3):
                frame = u < x0 or u >= x0 + w or y < y0 or y >= y0 + h
                if frame:
                    M.put(u, y, fz + 1, P, STONE if y >= y0 + h else TRIM_D); continue
                c = (0.26, 0.30, 0.24) if (u - x0) % 4 else (0.18, 0.21, 0.17)
                if abs((u - x0) - (y - y0) * w / h) < 1.4 or abs((u - x0) - (h - (y - y0)) * w / h) < 1.4: c = (0.20, 0.23, 0.18)   # aspa
                if M.noise(u, y, 0, 5.0) > 0.72: c = lerp(c, WOOD, 0.5)
                M.put(u, y, fz, P, c); M.V.pop((u, y, fz + 1), None)
        if y0 == 52:                                                   # uno abierto, con un fardo asomando
            for u in range(x0, x0 + w):
                for y in range(y0, y0 + h): M.V[(u, y, fz)] = [P, DARK, 0]
            for u in range(x0 + 3, x0 + 14):
                for y in range(y0, y0 + 10):
                    for z in range(fz - 6, fz + 3): M.put(u, y, z, P, (0.60, 0.52, 0.36) if (u + y) % 5 else ROPE_D)
    for z in range(fz + 1, fz + 18):                                  # viga con polea y cabo
        for y in (H - 6, H - 5): M.put(-1, y, z, P, WOOD_D); M.put(0, y, z, P, WOOD_D)
    for y in range(H - 12, H - 6):
        for dz in range(-2, 3): M.put(0, y, fz + 15 + dz, P, IRON_L if abs(dz) < 2 else IRON)
    for y in range(60, H - 12): M.put(1, y, fz + 13, P, ROPE); M.put(-1, y, fz + 17, P, ROPE_D)
    for y in range(52, 60):                                            # gancho
        M.put(1, y, fz + 13, P, IRON)
    M.put(2, 52, fz + 13, P, IRON); M.put(2, 53, fz + 13, P, IRON)
    for x0 in (-52, -36, 26, 40):                                      # ventanas pequeñas
        for y0 in (20, 64, 108):
            B.window(x0, y0, 10, 16, lit=(x0 == 26 and y0 == 64), panes=(2, 2))
    for x in range(-50, 50):                                           # rótulo pintado en el ladrillo
        for y in range(H - 22, H - 12):
            if y in (H - 22, H - 13): M.put(x, y, fz + 1, P, (0.70, 0.66, 0.54)); continue
            if abs(x) > 18 and (x + 60) % 7 < 5 and M.hsh((x + 60) // 7, y % 3, 9) > 0.25 and H - 20 <= y <= H - 15:
                M.put(x, y, fz + 1, P, (0.80, 0.76, 0.62))
    B.chimney(44, -10, w=3, d=3, extra=10, pots=1)
    return M, {P: [0, 0, 0]}, B.smokes


CASAS = {   # pintura, contraventanas, alto, porche, ventanas encendidas, tapiadas, chimeneas con humo
    1: ((0.70, 0.66, 0.54), (0.18, 0.30, 0.22), 92, True, {(20, 14)}, set(), (True, True)),
    2: ((0.48, 0.56, 0.60), (0.46, 0.14, 0.12), 96, False, {(-40, 56)}, set(), (True,)),
    3: ((0.50, 0.50, 0.47), (0.22, 0.25, 0.23), 92, True, {(-40, 56)}, {(20, 14), (20, 56)}, (True, False)),
    4: ((0.56, 0.48, 0.30), (0.20, 0.24, 0.30), 96, False, {(20, 14)}, {(-40, 14)}, (True,)),
}


def casa(variant=1):
    """Casa de tablas de dos plantas. 1 y 2, del puerto de Auckland; 3 (gris) y 4 (ocre), de
    Innsmouth: pintura más pelada, alguna ventana tapiada, una luz y una chimenea que humea."""
    M = Model(S=1, seed=304 + variant)
    PAINT, SHUT, H, porch, LITW, BOARD, SMOKE = CASAS[variant]
    HX, HZ = 50, 36
    B = House(M, HX, HZ, H, 38, board_wall(M, PAINT, peel=0.8 if variant < 3 else 0.72))
    B.build()
    fz = B.front()
    for x in range(-HX, HX):                                           # esquineras y alero pintados
        for y in range(6, H):
            if x in (-HX, HX - 1):
                for z in (fz, fz + 1): M.put(x, y, z, P, TRIM)
    B.door(-8, 16, 40, (0.30, 0.18, 0.12) if porch else (0.14, 0.18, 0.26), lit_fan=(variant == 2), steps=3)
    for x0 in (-40, 20):
        B.window(x0, 14, 14, 24, lit=(x0, 14) in LITW, shutters=SHUT, boarded=(x0, 14) in BOARD)
    for x0 in (-40, -8, 20):
        B.window(x0 + (2 if x0 == -8 else 0), 56, 14 if x0 != -8 else 12, 24, lit=(x0, 56) in LITW,
                 shutters=SHUT if x0 != -8 else None, boarded=(x0, 56) in BOARD)
    if porch:                                                          # porche con tejadillo y dos pies
        for x in range(-18, 18):
            for k in range(14):
                M.put(x, 46 - k // 3, fz + 2 + k, P, SLATE if (x // 3) % 2 else SLATE_L)
        for x in (-17, 16):
            for y in range(3, 42): M.put(x, y, fz + 14, P, TRIM)
        B.chimney(-36, 0, extra=12, pots=2, smoke=SMOKE[0])
        B.chimney(34, 0, extra=12, pots=1, smoke=SMOKE[1])
    else:                                                              # mirador en la planta de arriba
        for x in range(-12, 14):
            for y in range(50, 84):
                for z in range(fz + 1, fz + 9):
                    edge = x in (-12, 13) or z == fz + 8 or y in (50, 83)
                    if not edge: continue
                    c = TRIM if y in (50, 83) or x in (-12, 13) else PAINT
                    if z == fz + 8 and 54 <= y < 80 and -9 < x < 11:
                        c = GLASS if (x % 6) else TRIM_D
                    M.put(x, y, z, P, c)
        for x in range(-13, 15):
            for z in range(fz + 1, fz + 10): M.put(x, 84, z, P, SLATE_D)
        B.chimney(0, -14, w=5, extra=14, pots=3, smoke=SMOKE[0])
    return M, {P: [0, 0, 0]}, B.smokes


def banco():
    """Banco de plaza de hierro colado y listones de madera, con respaldo curvo (32/m, 1,8 m)."""
    M = Model(S=2, seed=330)
    L = 29
    SLAT = (0.36, 0.26, 0.16); SLAT_D = (0.24, 0.17, 0.11); CAST = (0.10, 0.11, 0.10)
    for x in (-L, L - 1):                                              # costados de hierro colado
        for y in range(0, 26):
            for z in range(-9, 10):
                leg = y < 14 and (abs(z + 7) < 2 or abs(z - 6) < 2)
                arm = 14 <= y <= 15 and -8 <= z <= 6 or (y == 22 and -9 <= z <= -6)
                back = z <= -7 and y >= 14 and abs(z + 7 + (y - 14) // 4) < 2
                curl = y in (12, 13) and (z + 7) % 4 == 0
                if leg or arm or back or curl: M.put(x, y, z, P, CAST)
                if leg or arm or back:
                    M.put(x - 1 if x > 0 else x + 1, y, z, P, CAST)
    for x in range(-L, L):                                             # listones del asiento y del respaldo
        for k in range(4):
            for z in range(-7 + k * 4, -5 + k * 4): M.put(x, 15, z, P, SLAT if (x + 40) % 20 else SLAT_D)
        for k in range(3):
            for y in range(17 + k * 4, 19 + k * 4): M.put(x, y, -8 - (y - 14) // 4, P, SLAT if (x + 40) % 20 else SLAT_D)
    return M, {P: [0, 0, 0]}, []


LEAF = [(0.16, 0.24, 0.12), (0.20, 0.30, 0.14), (0.26, 0.36, 0.16), (0.12, 0.18, 0.10)]
BARK = (0.24, 0.20, 0.16); BARK_D = (0.16, 0.13, 0.10)


def arbol(variant=1):
    """Olmo de la plaza (32/m, ~5,5 m): tronco con corteza en surcos que se abre en ramas, copa de
    racimos de hojas en cuatro verdes (más claros arriba) con huecos por donde asoman las ramas;
    en la 2, una rama seca y la copa más rala (es Innsmouth). Alcorque de piedra al pie."""
    M = Model(S=2, seed=340 + variant)
    rng = M.rng
    H = 46 + 6 * variant                                               # la cruz, a ~1,5 m
    def bark(x, y, z): return BARK_D if (int(math.atan2(z, x) * 6) + y // 9) % 3 == 0 else BARK
    for y in range(0, H):                                              # tronco
        r = 5.2 - y * 0.025 + (2.5 if y < 6 else 0) * (1 - y / 6)
        cx = 1.5 * math.sin(y / 30.0)
        for x in range(-8, 9):
            for z in range(-8, 9):
                d = math.hypot(x - cx, z)
                if r - 1.6 <= d <= r: M.put(int(x), y, z, P, bark(x, y, z))
    tips = []
    def branch(p, ang, up, L, r, depth):
        x, y, z = p
        for i in range(L):
            x += math.cos(ang) * (1 - up); z += math.sin(ang) * (1 - up); y += up + 0.2
            rr = r * (1 - i / L * 0.5)
            for dx in range(-int(rr), int(rr) + 1):
                for dz in range(-int(rr), int(rr) + 1):
                    if dx * dx + dz * dz <= rr * rr + 0.3: M.put(int(x) + dx, int(y), int(z) + dz, P, BARK)
        if depth > 0:
            for k in range(2):
                branch((x, y, z), ang + rng.uniform(-0.9, 0.9), max(0.15, up - 0.1), int(L * 0.7), max(1.0, r * 0.65), depth - 1)
        else: tips.append((x, y, z))
    for k in range(5):
        branch((1.5 * math.sin(H / 30.0), H - 4 - k * 3, 0), k * 1.26 + rng.uniform(-0.3, 0.3), 0.42, 30, 3.2, 1)
    dead = variant == 2
    for i, (x, y, z) in enumerate(tips):                               # racimos de hojas
        if dead and i % 3 == 0: continue                               # rama seca
        R = rng.uniform(17, 23) * (0.8 if dead else 1.0)
        for dx in range(-int(R), int(R) + 1):
            for dy in range(-int(R * 0.7), int(R * 0.7) + 1):
                for dz in range(-int(R), int(R) + 1):
                    q = (dx / R) ** 2 + (dy / (R * 0.7)) ** 2 + (dz / R) ** 2
                    if q > 1 or q < 0.62: continue
                    if M.hsh(int(x + dx) // 2, int(y + dy) // 2, int(z + dz) // 2) < (0.35 if dead else 0.18): continue   # huecos
                    up = (dy / (R * 0.7) + 1) / 2
                    c = LEAF[min(3, int(up * 3 + M.hsh(int(x + dx), int(y + dy), 1) * 1.2))] if up > 0.25 else LEAF[3]
                    M.put(int(x + dx), int(y + dy), int(z + dz), P, c, 0, False)
    for x in range(-14, 15):                                           # alcorque
        for z in range(-14, 15):
            if max(abs(x), abs(z)) >= 12: M.put(x, 0, z, P, STONE if (x + z) % 7 else STONE_D); M.put(x, 1, z, P, STONE)
            else: M.put(x, 0, z, P, (0.22, 0.18, 0.13) if M.hsh(x, z, 2) > 0.2 else MOSS)
    return M, {P: [0, 0, 0]}, []


PIECES = {'taberna': taberna, 'tienda': tienda, 'almacen': almacen, 'casa': casa, 'casa_2': lambda: casa(2),
          'taberna_inn': lambda: taberna(True), 'tienda_inn': lambda: tienda(True), 'casa_3': lambda: casa(3),
          'casa_4': lambda: casa(4), 'banco': banco, 'arbol': arbol, 'arbol_2': lambda: arbol(2)}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv, smokes = fn()
        for i, s in enumerate(smokes): piv['smoke' + ('' if i == 0 else '_%d' % (i + 1))] = s
        nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
        for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
        n = M.export('models/prt_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('prt_%s: %d voxels, humo %d' % (name, n, len(smokes)))
