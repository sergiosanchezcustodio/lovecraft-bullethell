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


def halve(M):
    """De 16/m a 8/m: cada bloque de 2x2x2 queda si tiene algún voxel, con el color del de más
    arriba (antes se tomaba solo el voxel par y se perdían los detalles finos)."""
    half = Model(S=1, seed=0)
    best = {}
    for (x, y, z), v in M.V.items():
        k = (x // 2, y // 2, z // 2)
        if k not in best or y > best[k][0] or (y == best[k][0] and v[2] > best[k][1][2]):
            best[k] = (y, v)
    for k, (_, v) in best.items(): half.V[k] = v
    half.S = 0.5
    return half


def casco():
    """El Alert atracado (rehecho el 09-10-2026 siguiendo tools/replicate/ref_alert.png): casco
    negro remachado con fondo rojo, franja roja bajo la borda, portillos, chorretones de óxido y
    el ancla en la proa; arrufo (la cubierta sube hacia proa y popa), borda con pasamanos y
    candeleros, escotillas con lona, cabos adujados y ventiladores, caseta blanca con ventanas
    encendidas y salvavidas, chimenea negra con banda roja, dos palos con botavaras y jarcia.
    Eslora 24 m a lo largo de x (proa en +x), modelado a 16/m y exportado a 8/m."""
    M = Model(S=1, seed=101)
    L = 192                                             # media eslora
    BEAM = 36                                           # media manga
    WL = 12                                             # hasta aquí, fondo rojo
    BRASS = (0.62, 0.48, 0.22); GLASS = (0.10, 0.12, 0.14); RING_R = (0.70, 0.16, 0.12)
    WHITE_D = (0.58, 0.56, 0.50); RIVET = (0.20, 0.21, 0.22)

    def deck_y(x):                                      # arrufo: más alto a proa que a popa
        t = x / L
        return int(56 + (22 * t ** 3 if t > 0 else 8 * t * t))

    def half_at(x):                                     # media manga en cada punto de la eslora
        if x > L - 64:                                  # proa afilada
            t = (x - (L - 64)) / 64.0
            return max(1, int(BEAM * (1 - t) ** 0.8))
        if x < -(L - 30):                               # popa redonda
            t = (-x - (L - 30)) / 30.0
            return max(1, int(BEAM * (1 - t * t) ** 0.5))
        return BEAM

    rust_x = [x for x in range(-L + 30, L - 40, 46)]    # imbornales: chorretones debajo
    for x in range(-L, L):
        h = half_at(x)
        dy = deck_y(x)
        for y in range(0, dy):
            hz = h if y > 20 else max(1, h - (20 - y) // 6)   # el pantoque se recoge abajo
            for z in (-hz, -hz + 1, hz - 1, hz):
                c = RED if y < WL else HULL
                if dy - 6 <= y <= dy - 5: c = RED                         # franja roja bajo la borda
                elif y >= WL and (y - WL) % 14 == 0: c = HULL_L           # juntas de las planchas
                elif y >= WL and x % 12 == 0 and y % 3 == 0: c = RIVET   # remaches
                if dy - 26 < y < dy - 7 and any(0 <= rx - x <= 1 for rx in rust_x): c = RUST   # chorretón
                if y < WL + 4 and M.noise(x, y, z, 6.0) > 0.8: c = RUST
                M.put(x, y, z, P, c)
            if y == 0:
                for z in range(-hz, hz + 1): M.put(x, 0, z, P, RED)
        for z in range(-h + 1, h):                                         # cubierta de tablas
            M.put(x, dy, z, P, DECK if (z // 3) % 2 else lerp(DECK, WOOD_D, 0.3))
        for z in (-h, h):                                                  # borda con pasamanos
            for y in range(dy, dy + 7):
                post = x % 12 == 0
                if y == dy + 6: M.put(x, y, z, P, WHITE)                 # pasamanos pintado de blanco
                elif y < dy + 3 or post: M.put(x, y, z, P, HULL if y < dy + 3 else WHITE_D)
    # portillos con aro de latón a lo largo de los dos costados
    for i, x in enumerate(range(-L + 44, L - 70, 20)):
        h = half_at(x)
        py = deck_y(x) - 16
        lit = i % 3 == 1                                                # uno de cada tres, encendido
        for s in (-1, 1):
            for dx in range(-3, 3):
                for dy2 in range(-3, 3):
                    d = abs(dx + 0.5) + abs(dy2 + 0.5)
                    if d > 4.2: continue                                  # redondo
                    if d > 2.6: M.put(x + dx, py + dy2, s * h, P, BRASS)
                    else: M.put(x + dx, py + dy2, s * h, P, LIGHT if lit else GLASS, glow=1 if lit else 0)
    # ancla en la amura (a los dos lados) y escobén
    for s in (-1, 1):
        ax = L - 40
        az = s * half_at(ax)
        ay = deck_y(ax) - 10
        for k in range(-3, 4): M.put(ax + k, ay, az + s, P, IRON_L)                # cepo
        for k in range(0, 14): M.put(ax, ay - k, az + s, P, IRON)                  # caña
        for k in range(-6, 7):
            M.put(ax + k, ay - 14 + abs(k) // 2, az + s, P, IRON)                    # brazos
        for k in range(-2, 2):
            for kk in range(-2, 2): M.put(ax + k, ay + 6 + kk, az, P, IRON_L)       # escobén
    # escotillas con lona y brazola
    for hx in (-120, 70, 120):
        dy = deck_y(hx)
        for x in range(hx - 16, hx + 16):
            for z in range(-14, 14):
                edge = x in (hx - 16, hx + 15) or z in (-14, 13)
                for y in range(dy + 1, dy + 4):
                    M.put(x, y, z, P, WOOD_D if edge else CANVAS)
                if not edge and (x - hx) % 8 == 0: M.put(x, dy + 4, z, P, ROPE_D)   # cinchas
    # cabos adujados y ventiladores de manguera
    for cx, cz in ((100, 22), (-150, -20), (40, -24), (150, -18)):
        dy = deck_y(cx)
        for a in range(0, 360, 10):
            for r in (3, 4, 5):
                x = cx + int(r * math.cos(math.radians(a))); z = cz + int(r * math.sin(math.radians(a)))
                M.put(x, dy + 1, z, P, ROPE if r != 4 else ROPE_D)
    for vx, vz in ((-80, 20), (-80, -20), (40, 18)):
        dy = deck_y(vx)
        for y in range(dy + 1, dy + 14):
            for x in range(vx - 2, vx + 2):
                for z in range(vz - 2, vz + 2): M.put(x, y, z, P, WHITE)
        for x in range(vx - 4, vx + 4):                                      # boca acampanada
            for y in range(dy + 13, dy + 19):
                for z in range(vz - 4, vz + 4):
                    if max(abs(x - vx + 0.5), abs(z - vz + 0.5)) > 3.2 and y < dy + 18: continue
                    M.put(x, y, z, P, RED if z < vz - 2 or y == dy + 18 else WHITE)
    # caseta blanca (gobierno) a popa de la mitad, con ventanas encendidas y salvavidas
    cx0, cx1, cz = -78, -18, 24
    dy = deck_y(-48)
    for x in range(cx0 - 14, cx1 + 10):                                       # cubierta elevada (toldilla)
        for z in range(-BEAM + 2, BEAM - 1):
            for y in range(dy + 1, dy + 13):
                edge = x in (cx0 - 14, cx1 + 9) or z in (-BEAM + 2, BEAM - 2)
                if edge or y == dy + 12:
                    M.put(x, y, z, P, WHITE_D if y < dy + 12 else DECK)
        for z in (-BEAM + 2, BEAM - 2):                                         # su baranda
            for y in range(dy + 13, dy + 18):
                if y == dy + 17 or x % 8 == 0: M.put(x, y, z, P, WHITE)
    dy += 12
    top = dy + 30
    for x in range(cx0, cx1):
        for y in range(dy + 1, top):
            for z in range(-cz, cz):
                if min(x - cx0, cx1 - 1 - x, z + cz, cz - 1 - z) > 1 and y < top - 1: continue
                c = WHITE if (y - dy) % 6 else WHITE_D                       # tablas
                wall_x = x in (cx0, cx1 - 1); wall_z = z in (-cz, cz - 1)
                if top - 14 <= y <= top - 6 and wall_z and (x - cx0) % 12 in range(3, 9):
                    c = LIGHT if (x - cx0) // 12 in (1, 3) else GLASS          # ventanas: dos encendidas
                    if c == LIGHT: M.put(x, y, z, P, c, glow=1); continue
                if top - 14 <= y <= top - 6 and wall_x and abs(z) < 16 and (z + 16) % 10 in range(2, 8):
                    c = LIGHT if x == cx1 - 1 else GLASS                       # frente del puente
                    if c == LIGHT: M.put(x, y, z, P, c, glow=1); continue
                M.put(x, y, z, P, c)
        for z in (-cz, cz - 1):                                               # baranda en el techo
            for y in range(top, top + 5):
                if y == top + 4 or x % 8 == 0: M.put(x, y, z, P, WOOD)
    for x in (cx0, cx1 - 1):
        for z in range(-cz, cz):
            for y in range(top, top + 5):
                if y == top + 4 or z % 8 == 0: M.put(x, y, z, P, WOOD)
    for rx in (cx0 + 8, cx1 - 10):                                            # salvavidas rojos y blancos
        for s in (-1, 1):
            for a in range(0, 360, 15):
                for r in (4, 5):
                    x = rx + int(r * math.cos(math.radians(a))); y = dy + 14 + int(r * math.sin(math.radians(a)))
                    M.put(x, y, s * (cz + (1 if s > 0 else 0)), P, RING_R if (a // 45) % 2 else WHITE)
    # chimenea negra con banda roja
    for y in range(top, top + 44):
        for x in range(-40, -24):
            for z in range(-8, 8):
                if (x + 32.5) ** 2 + (z + 0.5) ** 2 > 64 or (x + 32.5) ** 2 + (z + 0.5) ** 2 < 36 and y < top + 43: continue
                M.put(x, y, z, P, RED if top + 30 <= y < top + 36 else HULL)
    # dos palos con cofa, botavara y jarcia
    for mx, mh in ((60, 190), (-130, 160)):
        base = deck_y(mx)
        for y in range(base, base + mh):
            for x in (mx, mx + 1):
                for z in (0, 1): M.put(x, y, z, P, WOOD)
        for z in range(-14, 16): M.put(mx, base + mh - 30, z, P, WOOD)          # verga
        for k in range(0, 70):                                                  # botavara de carga
            M.put(mx - k, base + 40 - k // 6, 0, P, WOOD_D)
            M.put(mx - k, base + 40 - k // 6, 1, P, WOOD_D)
        for s in (-1, 1):                                                       # obenques a la borda
            for k in range(0, 120):
                t = k / 119
                y = int(base + mh - 30 - t * (mh - 32))
                M.put(mx + int(t * 6), y, s * int(t * (BEAM - 2)), P, ROPE_D)
        for k in range(0, 160):                                                 # estay hacia proa/popa
            t = k / 159
            tx = (L - 20) if mx > 0 else (-L + 20)
            M.put(int(mx + (tx - mx) * t), int(base + mh - (mh - 10) * t), 0, P, ROPE_D)
    for bx, bz, kind in ((95, -24, 'b'), (102, -24, 'b'), (95, -17, 'b'), (-150, 16, 'c'), (-140, 16, 'c'),
                         (-145, 16, 'c'), (150, 12, 'c'), (20, 0, 'w'), (-100, 0, 'w')):
        by = deck_y(bx)
        if kind == 'b':                                                         # barril
            for y in range(by + 1, by + 10):
                for x in range(bx - 3, bx + 3):
                    for z in range(bz - 3, bz + 3):
                        if (x - bx + 0.5) ** 2 + (z - bz + 0.5) ** 2 > 10: continue
                        M.put(x, y, z, P, IRON if y in (by + 2, by + 8) else WOOD)
        elif kind == 'c':                                                       # caja de carga
            for y in range(by + 1, by + 9):
                for x in range(bx - 4, bx + 4):
                    for z in range(bz - 4, bz + 4):
                        edge = x in (bx - 4, bx + 3) or z in (bz - 4, bz + 3) or y == by + 8
                        M.put(x, y, z, P, WOOD_D if (x - bx) % 4 == 0 and not edge else CRATE)
        else:                                                                   # chigre (torno de carga)
            for y in range(by + 1, by + 8):
                for x in range(bx - 5, bx + 5):
                    for z in range(bz - 6, bz + 6):
                        if abs(z - bz) < 4 and y > by + 2 and (x - bx) ** 2 + (y - by - 5) ** 2 > 9: continue
                        M.put(x, y, z, P, IRON if abs(z - bz) >= 4 else ROPE_D)
    # bote salvavidas en pescantes junto a la caseta
    bx, bz = -48, -cz - 8
    by = top - 4
    for x in range(bx - 20, bx + 20):
        hw = int(6 * (1 - (abs(x - bx) / 20.0) ** 2) ** 0.5) + 1
        for z in range(bz - hw, bz + hw):
            for y in range(by, by + 6):
                if min(z - (bz - hw), bz + hw - 1 - z) > 0 and y > by: continue
                M.put(x, y, z, P, WHITE if y > by + 3 else WOOD)
    for dx in (bx - 16, bx + 16):
        for y in range(dy, by + 12): M.put(dx, y, bz + 6, P, IRON_L)
        for k in range(0, 8): M.put(dx, by + 12, bz + 6 - k, P, IRON_L)
    return halve(M), {P: [0, 0, 0]}


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


# Superestructura del Emma (rehecha el 09-10-2026 siguiendo tools/replicate/ref_emma.png), 16/m.
# Piezas de 12 m a lo largo de x que se ponen seguidas en el borde norte de la cubierta: el
# puente en medio (alr_puente) y casetas a los lados (alr_caseta). Frente hacia +z (z = -1).
WIDTH = 96                                   # media anchura (12 m)
DEPTH = 34                                   # fondo (2,1 m)
WALL_H = 46                                  # altura de la caseta
BRASS = (0.62, 0.48, 0.22); GLASS = (0.10, 0.12, 0.14); WHITE_D = (0.56, 0.54, 0.48); RING_R = (0.70, 0.16, 0.12)
DOOR = (0.34, 0.24, 0.15)


def _caseta(M, x0, x1, z0, h, lit_every=3, doors=()):
    """Caseta de tablas blancas con zócalo, cornisa, puertas, portillos y salvavidas."""
    for x in range(x0, x1):
        for y in range(0, h):
            for z in range(z0, 0):
                if min(x - x0, x1 - 1 - x, z - z0, -1 - z) > 0 and y < h - 1: continue   # paredes de un voxel
                c = WHITE if (y // 4) % 2 else lerp(WHITE, WHITE_D, 0.35)          # tablas
                if y < 3: c = HULL_L                                                # zócalo
                if y >= h - 3: c = WHITE_D                                          # cornisa
                M.put(x, y, z, P, c)
    front = -1
    for i, px in enumerate(range(x0 + 12, x1 - 8, 16)):
        if any(abs(px - d) < 12 for d in doors): continue
        lit = i % lit_every == 1
        py = h - 18
        for dx in range(-3, 3):
            for dy in range(-3, 3):
                d = abs(dx + 0.5) + abs(dy + 0.5)
                if d > 4.2: continue
                if d > 2.6: M.put(px + dx, py + dy, front, P, BRASS)
                else: M.put(px + dx, py + dy, front, P, LIGHT if lit else GLASS, glow=1 if lit else 0)
    for d in doors:                                                                # puertas con pomo
        for x in range(d - 6, d + 6):
            for y in range(3, 30):
                edge = x in (d - 6, d + 5) or y == 29
                M.put(x, y, front, P, WOOD_D if edge else DOOR)
        M.put(d + 3, 16, front + 1, P, BRASS)
        for x in range(d - 8, d + 8): M.put(x, 31, front + 1, P, WHITE_D)            # tejadillo
    for rx in (x0 + 26, x1 - 26):                                                   # salvavidas
        if any(abs(rx - d) < 14 for d in doors): continue
        for a in range(0, 360, 12):
            for r in (4, 5):
                x = rx + int(round(r * math.cos(math.radians(a)))); y = h - 30 + int(round(r * math.sin(math.radians(a))))
                M.put(x, y, front + 1, P, RING_R if (a // 45) % 2 else WHITE)
    for x in range(x0, x1):                                                         # baranda en el techo
        for y in range(h, h + 6):
            if y == h + 5 or x % 8 == 0: M.put(x, y, front, P, WHITE)
    for vx in (x0 + 20, x1 - 30):                                                   # ventiladores del techo
        for y in range(h, h + 10):
            for x in range(vx - 2, vx + 2):
                for z in range(-12, -8): M.put(x, y, z, P, WHITE)
        for x in range(vx - 3, vx + 3):
            for z in range(-14, -7):
                for y in range(h + 9, h + 13): M.put(x, y, z, P, RED if z < -11 else WHITE)


def _escalerilla(M, x, y0, y1, z):
    for y in range(y0, y1):
        for dx in (-3, 3): M.put(x + dx, y, z, P, WOOD_D)
        if y % 4 == 0:
            for dx in range(-3, 4): M.put(x + dx, y, z, P, WOOD)


def caseta():
    """Tramo de superestructura sin puente: caseta con puerta, portillos y escalerilla."""
    M = Model(S=1, seed=110)
    _caseta(M, -WIDTH, WIDTH, -DEPTH, WALL_H, lit_every=4, doors=(-40,))
    _escalerilla(M, 40, 0, WALL_H + 2, 0)
    return M, {P: [0, 0, 0]}


def puente():
    """El puente del Emma: caseta abajo y, encima, la timonera con ventanales encendidos y la
    rueda del timón a contraluz, alerones con baranda, chimenea con banda roja y palo."""
    M = Model(S=1, seed=109)
    _caseta(M, -WIDTH, WIDTH, -DEPTH, WALL_H, lit_every=3, doors=(-56, 56))
    _escalerilla(M, -76, 0, WALL_H + 2, 0)
    # timonera: más estrecha y retranqueada, con ventanales en el frente
    tx0, tx1, tz0, tz1, h0, h1 = -44, 44, -30, -6, WALL_H, WALL_H + 34
    for x in range(tx0, tx1):
        for y in range(h0, h1):
            for z in range(tz0, tz1):
                if min(x - tx0, tx1 - 1 - x, z - tz0, tz1 - 1 - z) > 0 and y < h1 - 1: continue
                c = WHITE if (y // 4) % 2 else lerp(WHITE, WHITE_D, 0.35)
                if y >= h1 - 3: c = WHITE_D
                win = z == tz1 - 1 and h0 + 10 <= y <= h0 + 24 and (x - tx0) % 14 in range(2, 12)
                if win:
                    M.put(x, y, z, P, LIGHT, glow=1)
                    continue
                M.put(x, y, z, P, c)
    for a in range(0, 360, 6):                                                  # rueda del timón a contraluz
        for r in (6, 7):
            x = int(round(r * math.cos(math.radians(a)))); y = h0 + 14 + int(round(r * math.sin(math.radians(a))))
            M.put(x, y, tz1 - 3, P, WOOD_D)
        if a % 45 == 0:
            for r in range(0, 10):
                M.put(int(round(r * math.cos(math.radians(a)))), h0 + 14 + int(round(r * math.sin(math.radians(a)))), tz1 - 3, P, WOOD_D)
    for x in range(tx0, tx1):                                                   # visera sobre los ventanales
        for z in range(tz1, tz1 + 4): M.put(x, h0 + 26, z, P, WHITE_D)
    for x in range(-WIDTH + 8, WIDTH - 8):                                      # alerones (el techo de abajo) con baranda
        for z in (-DEPTH + 2, -2):
            if tx0 <= x < tx1 and z == -DEPTH + 2: continue
    for x in range(tx0, tx1):                                                   # baranda en el techo de la timonera
        for z in (tz0, tz1 - 1):
            for y in range(h1, h1 + 5):
                if y == h1 + 4 or x % 8 == 0: M.put(x, y, z, P, WHITE)
    for x in range(-4, 4):                                                      # nombre: tablilla de latón (sin letras)
        for k in range(-14, 14): M.put(k, h1 - 7, tz1, P, BRASS)
    # chimenea corta, negra con banda roja, detrás de la timonera
    cx, cz = 0, -24
    for y in range(h1, h1 + 34):
        for x in range(cx - 9, cx + 9):
            for z in range(cz - 9, cz + 9):
                d = (x - cx + 0.5) ** 2 + (z - cz + 0.5) ** 2
                if d > 72 or (d < 42 and y < h1 + 33): continue
                M.put(x, y, z, P, RED if h1 + 20 <= y < h1 + 26 else HULL)
    # palo con verga y jarcia, y el reflector en lo alto
    for y in range(h1, h1 + 110):
        for x in (60, 61):
            for z in (-20, -19): M.put(x, y, z, P, WOOD)
    for x in range(40, 82): M.put(x, h1 + 86, -20, P, WOOD)
    for s in (-1, 1):
        for k in range(0, 90):
            t = k / 89
            M.put(60 + s * int(t * 30), int(h1 + 86 - t * 86), -20 + int(t * 14), P, ROPE_D)
    for x in range(56, 66):                                                      # fanal encendido en el palo
        for y in range(h1 + 60, h1 + 66):
            for z in (-17, -16): M.put(x, y, z, P, LIGHT if 58 <= x < 64 else IRON, glow=1 if 58 <= x < 64 else 0)
    return M, {P: [0, 0, 0]}


PIECES = {'borda': borda, 'puente': puente, 'caseta': caseta, 'casco': casco, 'bolardo': bolardo, 'grua': grua, 'fardos': fardos, 'rollo': rollo,
          'linterna': linterna, 'bote': bote}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/alr_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.8, specular=0.3, no_bottom=True)
        print('alr_%s: %d voxels' % (name, n))
