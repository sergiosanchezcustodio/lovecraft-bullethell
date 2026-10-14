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
    """El Alert atracado (rehecho en la revisión de arte del 13-10-2026: 33 m de eslora, tres
    chimeneas y a 16/m, sin reducir). Casco de planchas remachadas en tracas, cada plancha de su
    tono, con chorretones de óxido bajo portillos, imbornales y escobenes; fondo rojo, verduguillo
    y franja roja bajo la borda; castillo de proa con molinete y cadenas, anclas en los escobenes;
    cubierta de tablas calafateadas con escotillas de lona trincada, chigres, plumas de carga y
    ventiladores de manguera; superestructura de dos alturas en el centro con puertas, ventanas
    encendidas, salvavidas, puente con la timonera encendida, alerones y luces de situación (roja
    y verde); cuatro botes en pescantes; tres chimeneas negras con banda roja, tubo de vapor y
    vientos; dos palos con crucetas, plumas y jarcia; toldilla a popa con el asta y la bandera
    (parte "flag": ondea). Eslora a lo largo de x (proa en +x)."""
    M = Model(S=1, seed=101)
    rng = M.rng
    L = 264                                             # media eslora (16/m)
    BEAM = 44                                           # media manga
    WL = 16                                             # hasta aquí, fondo rojo
    BRASS = (0.62, 0.48, 0.22); GLASS = (0.10, 0.12, 0.14); RING_R = (0.70, 0.16, 0.12)
    WHITE_D = (0.58, 0.56, 0.50); RIVET = (0.24, 0.25, 0.26); PLATE_A = (0.07, 0.08, 0.09); PLATE_B = (0.13, 0.14, 0.15)
    NAV_R = (1.0, 0.20, 0.15); NAV_G = (0.20, 1.0, 0.40); CHAIN = (0.26, 0.24, 0.22)

    def deck_y(x):                                      # arrufo: más alto a proa que a popa
        t = x / L
        return int(70 + (26 * t ** 3 if t > 0 else 10 * t * t))

    def half_at(x):
        if x > L - 84:                                  # proa afilada
            t = (x - (L - 84)) / 84.0
            return max(1, int(BEAM * (1 - t) ** 0.8))
        if x < -(L - 40):                               # popa redonda
            t = (-x - (L - 40)) / 40.0
            return max(1, int(BEAM * (1 - t * t) ** 0.5))
        return BEAM

    def plate(x, y):
        """Color de una plancha del casco: tracas de 12 de alto, planchas de 40 de largo."""
        row = (y - WL) // 12
        off = 20 if row % 2 else 0
        pi = (x + off) // 40
        c = lerp(PLATE_A, PLATE_B, M.hsh(pi, row, 3))
        if (y - WL) % 12 == 0: c = HULL_L                                  # junta de las tracas
        elif (x + off) % 40 == 0: c = lerp(HULL_L, PLATE_A, 0.4)          # junta de las planchas
        elif (y - WL) % 12 in (1, 11) and x % 4 == 0: c = RIVET            # remaches de la costura
        elif (x + off) % 40 in (1, 39) and y % 4 == 0: c = RIVET
        return c

    streaks = set(range(-L + 40, L - 60, 37))
    for x in range(-L, L):
        h = half_at(x)
        dy = deck_y(x)
        for y in range(0, dy):
            hz = h if y > 24 else max(1, h - (24 - y) // 5)    # el pantoque se recoge abajo
            for z in (-hz, hz):
                if y < WL: c = lerp(RED, (0.30, 0.10, 0.08), 0.35 * M.noise(x, y, z, 5.0))
                else: c = plate(x, y)
                if y in (WL, WL + 1): c = (0.10, 0.10, 0.10)                     # línea de flotación
                if dy - 8 <= y <= dy - 6: c = RED                                  # franja roja bajo la borda
                if y == dy - 10: c = WHITE_D                                       # verduguillo
                if y < dy - 10 and any(0 <= sx - x <= 1 for sx in streaks) and y > dy - 10 - 30 * M.hsh(x // 37, 1, 1):
                    c = lerp(c, RUST, 0.7)                                         # chorretón de un imbornal
                if WL <= y < WL + 6 and M.noise(x, y, z, 6.0) > 0.7: c = lerp(c, RUST, 0.6)
                M.put(x, y, z, P, c)
            if y == 0:
                for z in range(-hz, hz + 1): M.put(x, 0, z, P, RED)
        for z in range(-h + 1, h):                                         # cubierta calafateada
            c = lerp(DECK, WOOD_D, 0.25 * M.hsh(z // 4, (x + (z // 4) * 13) // 50, 4))
            if z % 4 == 0: c = (0.12, 0.10, 0.08)
            M.put(x, dy, z, P, c)
        for z in (-h, h):                                                  # borda con pasamanos
            for y in range(dy, dy + 8):
                post = x % 14 == 0
                if y == dy + 7: M.put(x, y, z, P, WHITE)
                elif y < dy + 3: M.put(x, y, z, P, HULL)
                elif post: M.put(x, y, z, P, WHITE_D)
                elif y == dy + 5: M.put(x, y, z, P, WHITE_D)                  # pasamanos intermedio
    # portillos de latón con cristal, alguno encendido, con chorretón debajo
    for i, x in enumerate(range(-L + 60, L - 100, 18)):
        h = half_at(x); py = deck_y(x) - 22
        lit = M.hsh(i, 2, 2) > 0.6
        for s in (-1, 1):
            for dx in range(-3, 4):
                for dy2 in range(-3, 4):
                    d = math.hypot(dx, dy2)
                    if d > 3.4: continue
                    if d > 2.2: M.put(x + dx, py + dy2, s * (h + 1), P, BRASS)
                    else: M.put(x + dx, py + dy2, s * h, P, LIGHT if lit else (GLASS if d > 0.8 else (0.25, 0.28, 0.30)), glow=1 if lit else 0)
            for k in range(4, 4 + int(8 + 10 * M.hsh(x, s, 3))):
                v = M.V.get((x, py - k, s * h))
                if v: v[1] = lerp(v[1], RUST, 0.55 * (1 - k / 22))
    # castillo de proa (cubierta elevada) con molinete, cadenas y escobenes; anclas
    fx0 = L - 70
    for x in range(fx0, L):
        h = half_at(x)
        if h < 3: continue
        dy = deck_y(x)
        for z in range(-h + 1, h):
            M.put(x, dy + 12, z, P, DECK if z % 4 else (0.12, 0.10, 0.08))
        for z in range(-h + 1, h):
            for y in range(dy + 1, dy + 12): M.put(fx0, y, z, P, WHITE if (y - dy) % 4 else WHITE_D)
        for z in (-h, h):
            for y in range(dy + 8, dy + 20):
                if y == dy + 19 or x % 14 == 0: M.put(x, y, z, P, WHITE)
                elif y < dy + 13: M.put(x, y, z, P, plate(x, y))
    wx, wy = L - 46, deck_y(L - 46) + 13
    for x in range(wx - 6, wx + 6):                                     # molinete
        for z in range(-18, 18):
            for y in range(wy, wy + 9):
                drum = abs(z) > 6 and (x - wx) ** 2 + (y - wy - 5) ** 2 <= 20
                frame = abs(z) <= 6 and y < wy + 7
                if drum: M.put(x, y, z, P, IRON if abs(z) % 3 else IRON_L)
                elif frame: M.put(x, y, z, P, (0.28, 0.32, 0.30))
    for s in (-1, 1):
        for k in range(0, 40):                                           # cadenas al escobén
            x = wx + k; z = s * (12 + k * 0.6)
            M.put(x, wy + 2 - k // 12, z, P, CHAIN if k % 2 else IRON_L)
        ax = L - 54; az = s * (half_at(ax) + 1); ay = deck_y(ax) - 14
        for dx in range(-3, 4):
            for dy2 in range(-3, 4):
                if dx * dx + dy2 * dy2 <= 9: M.put(ax + dx + 8, ay + 8 + dy2, az, P, IRON)       # escobén
        for k in range(-5, 6): M.put(ax + k, ay, az + s, P, IRON_L)                               # cepo
        for k in range(0, 22): M.put(ax, ay - k, az + s, P, IRON); M.put(ax + 1, ay - k, az + s, P, IRON)   # caña
        for k in range(-9, 10):
            M.put(ax + k, ay - 22 + abs(k) * 2 // 3, az + s, P, IRON); M.put(ax + k, ay - 21 + abs(k) * 2 // 3, az + s, P, IRON)
        for k in range(0, 18):
            v = M.V.get((ax + 8, ay - 4 - k, az - s))
            if v: v[1] = lerp(v[1], RUST, 0.7 * (1 - k / 18))
    # toldilla de popa con su baranda, la rueda de respeto y el asta con la bandera
    px1 = -L + 64
    for x in range(-L, px1):
        h = half_at(x)
        if h < 3: continue
        dy = deck_y(x)
        for z in range(-h + 1, h): M.put(x, dy + 12, z, P, DECK if z % 4 else (0.12, 0.10, 0.08))
        for z in (-h, h):
            for y in range(dy + 8, dy + 20):
                if y == dy + 19 or x % 14 == 0: M.put(x, y, z, P, WHITE)
                elif y < dy + 13: M.put(x, y, z, P, plate(x, y))
    for z in range(-BEAM + 1, BEAM):
        for y in range(deck_y(px1) + 1, deck_y(px1) + 12): M.put(px1, y, z, P, WHITE if (y % 4) else WHITE_D)
    sy = deck_y(-L + 30) + 13
    for a in range(0, 360, 8):                                            # rueda de respeto
        for r in (5, 6):
            M.put(-L + 50, sy + 8 + int(round(r * math.sin(math.radians(a)))), int(round(r * math.cos(math.radians(a)))), P, WOOD_D)
    for y in range(sy, sy + 70): M.put(-L + 12, y, 0, P, WOOD_D); M.put(-L + 13, y, 0, P, WOOD_D)    # asta
    FW, FH = 30, 18
    ftop = sy + 66
    for x in range(FW):                                                   # bandera (roja con el cantón)
        for fy in range(FH):
            if x > FW - 3 - 4 * M.noise(0, fy, 0, 4.0): continue
            c = (0.58, 0.12, 0.10)
            if x < 13 and fy < 9:
                c = (0.14, 0.18, 0.40)
                if x in (5, 6) or fy in (4,): c = (0.80, 0.78, 0.74)
            M.put(-L + 14 + x, ftop - fy, 0, 'flag', c)
    # escotillas con lona, cuñas y cinchas; chigres y plumas de carga
    hatches = (150, 95, -110, -165)
    for hx in hatches:
        dy = deck_y(hx)
        for x in range(hx - 20, hx + 20):
            for z in range(-18, 18):
                edge = x in (hx - 20, hx + 19) or z in (-18, 17)
                for y in range(dy + 1, dy + 6):
                    if edge: M.put(x, y, z, P, WOOD_D if y < dy + 5 else IRON)
                    elif y == dy + 5:
                        c = lerp(CANVAS, CANVAS_D, 0.4 * M.noise(x, y, z, 5.0))
                        if (x - hx) % 10 == 0: c = ROPE_D
                        if (z + 18) % 12 == 0: c = lerp(CANVAS_D, (0.2, 0.2, 0.18), 0.4)
                        M.put(x, y + (1 if (x - hx) % 10 == 5 else 0), z, P, c)
        wxx = hx + (26 if hx > 0 else -26)                                 # chigre
        for x in range(wxx - 5, wxx + 6):
            for z in range(-9, 10):
                for y in range(dy + 1, dy + 11):
                    drum = abs(z) < 6 and (x - wxx) ** 2 + (y - dy - 6) ** 2 <= 16
                    side = abs(z) in (6, 7, 8, 9) and y < dy + 10 and abs(x - wxx) < 5
                    if drum: M.put(x, y, z, P, ROPE if (y + z) % 2 else ROPE_D)
                    elif side: M.put(x, y, z, P, (0.24, 0.28, 0.26))
    # superestructura central: dos alturas
    cx0, cx1 = -74, 34
    dy0 = deck_y(-20)
    h1 = dy0 + 30; h2 = h1 + 28
    def house(x0, x1, z0, z1, yb, yt, lit_every, door_xs=()):
        for x in range(x0, x1):
            for y in range(yb, yt):
                for z in range(z0, z1):
                    if min(x - x0, x1 - 1 - x, z - z0, z1 - 1 - z) > 0 and y < yt - 1: continue
                    c = WHITE if (y - yb) % 5 else WHITE_D
                    if y < yb + 2: c = (0.30, 0.30, 0.28)
                    if y >= yt - 2: c = WOOD
                    side = z in (z0, z1 - 1)
                    if side and yb + 12 <= y < yb + 22 and (x - x0) % 14 in range(4, 10) and not any(abs(x - d) < 8 for d in door_xs):
                        lit = M.hsh((x - x0) // 14, yb, z) > lit_every
                        c = LIGHT if lit else GLASS
                        if (x - x0) % 14 == 7 or y == yb + 17: c = WHITE_D                    # parteluz
                        M.put(x, y, z, P, c, glow=1 if c == LIGHT else 0)
                        continue
                    if side and any(abs(x - d) < 5 for d in door_xs) and y < yb + 24:
                        c = DOOR if any(abs(x - d) < 4 for d in door_xs) else WHITE_D
                    M.put(x, y, z, P, c)
    house(cx0, cx1, -36, 36, dy0 + 1, h1, 0.45, door_xs=(-60, 20))
    for x in range(cx0 - 8, cx1 + 8):                                     # cubierta de botes, con baranda
        for z in range(-BEAM + 2, BEAM - 1):
            M.put(x, h1, z, P, DECK if z % 4 else (0.12, 0.10, 0.08))
        for z in (-BEAM + 2, BEAM - 2):
            for y in range(h1 + 1, h1 + 7):
                if y == h1 + 6 or x % 10 == 0: M.put(x, y, z, P, WHITE)
    for x in (cx0 - 8, cx1 + 7):
        for z in range(-BEAM + 2, BEAM - 1):
            for y in range(h1 + 1, h1 + 7):
                if y == h1 + 6 or z % 10 == 0: M.put(x, y, z, P, WHITE)
    house(cx0 + 40, cx1 - 6, -26, 26, h1 + 1, h2, 0.3)                  # puente y timonera
    for x in range(cx1 - 6, cx1 + 4):                                     # alerones del puente
        for z in range(-BEAM + 2, BEAM - 1):
            M.put(x, h2 - 10, z, P, DECK)
        for z in (-BEAM + 2, BEAM - 2):
            for y in range(h2 - 9, h2 - 3): M.put(x, y, z, P, WHITE if y == h2 - 4 or x % 5 == 0 else WHITE_D)
    for s, col in ((-1, NAV_R), (1, NAV_G)):                               # luces de situación
        for y in range(h2 - 9, h2 - 5):
            for x in range(cx1 - 2, cx1 + 2): M.put(x, y, s * (BEAM - 1), P, col, glow=1)
    for rx in (cx0 + 10, cx0 + 50):                                       # salvavidas
        for s in (-1, 1):
            for a in range(0, 360, 12):
                for r in (4, 5):
                    M.put(rx + int(round(r * math.cos(math.radians(a)))), dy0 + 18 + int(round(r * math.sin(math.radians(a)))), s * 37, P, RING_R if (a // 45) % 2 else WHITE)
    # botes en pescantes (dos por banda)
    for bxc in (cx0 + 6, cx0 + 66):
        for s in (-1, 1):
            bz = s * (BEAM - 8); by = h1 + 10
            for x in range(bxc - 18, bxc + 18):
                hw = int(6 * (1 - (abs(x - bxc) / 18.0) ** 2) ** 0.5) + 1
                for z in range(bz - hw, bz + hw):
                    for y in range(by, by + 7):
                        if min(z - (bz - hw), bz + hw - 1 - z) > 0 and y > by and y < by + 6: continue
                        c = WHITE if y > by + 3 else WOOD
                        if y == by + 6: c = CANVAS if abs(z - bz) < hw - 1 else WHITE
                        M.put(x, y, z, P, c)
            for dx in (bxc - 15, bxc + 15):
                for y in range(h1, by + 16): M.put(dx, y, s * (BEAM - 2), P, IRON_L)
                for k in range(0, 8): M.put(dx, by + 16 - k // 3, s * (BEAM - 2) - s * k, P, IRON_L)
                for y in range(by + 7, by + 13): M.put(dx, y, bz, P, ROPE_D)
    # tres chimeneas negras con banda roja, tubo de vapor y vientos
    smokes = []
    for fxc in (-56, -26, 4):
        fz = 0; fb = h1
        if fxc > cx0 + 40 and fxc < cx1 - 6: fb = h2
        ft = h1 + 74
        smokes.append([fxc - (ft - 1 - fb) // 9, ft + 2, 0])                 # boca: de ahí sale el humo
        for y in range(fb, ft):
            rake = (y - fb) // 9
            for x in range(fxc - 10, fxc + 10):
                for z in range(-10, 10):
                    d = ((x - fxc + rake + 0.5) / 9.5) ** 2 + ((z + 0.5) / 8.0) ** 2
                    if d > 1 or (d < 0.72 and y < ft - 1): continue
                    c = HULL if (ft - 22 > y or y >= ft - 14) else RED
                    if y >= ft - 3: c = (0.04, 0.04, 0.04)
                    if c == HULL and M.noise(x, y, z, 6.0) > 0.75: c = lerp(HULL, RUST, 0.35)
                    M.put(x, y, z, P, c)
        for y in range(fb, ft + 4):                                       # tubo de vapor
            M.put(fxc + 9 - (y - fb) // 9, y, 2, P, IRON_L)
        for s in (-1, 1):                                                 # vientos
            for k in range(0, 60):
                t = k / 59
                M.put(int(fxc + t * 4), int(ft - 18 - t * (ft - 18 - h1)), int(s * (6 + t * (BEAM - 8))), P, ROPE_D)
    # ventiladores de manguera (boca hacia proa)
    for vx, vz in ((-100, 24), (-100, -24), (60, 26), (60, -26), (120, 20), (-140, -22)):
        dy = deck_y(vx)
        for y in range(dy + 1, dy + 20):
            for x in range(vx - 3, vx + 3):
                for z in range(vz - 3, vz + 3):
                    if (x - vx + 0.5) ** 2 + (z - vz + 0.5) ** 2 <= 8: M.put(x, y, z, P, WHITE)
        for x in range(vx - 5, vx + 6):
            for y in range(dy + 18, dy + 28):
                for z in range(vz - 5, vz + 6):
                    d = (x - vx) ** 2 + (y - dy - 23) ** 2 + (z - vz) ** 2
                    if d > 26: continue
                    inner = x > vx + 2 and d < 14
                    M.put(x, y, z, P, RED if inner else WHITE)
    # dos palos con crucetas, plumas de carga y jarcia
    for mx, mh in ((122, 230), (-138, 200)):
        base = deck_y(mx)
        for y in range(base, base + mh):
            r = 2.6 - 1.2 * (y - base) / mh
            for x in range(mx - 3, mx + 4):
                for z in range(-3, 4):
                    if (x - mx) ** 2 + z * z <= r * r + 0.3: M.put(x, y, z, P, WOOD if y % 40 else IRON)
        for k in (0, 1):
            cy = base + mh - 40 - k * 50
            for z in range(-22 + k * 6, 23 - k * 6): M.put(mx, cy, z, P, WOOD_D); M.put(mx, cy + 1, z, P, WOOD_D)
        for sgn in (-1, 1):                                               # plumas hacia las escotillas
            tgt = (mx + sgn * 50, base + 26)
            for k in range(0, 60):
                t = k / 59
                M.put(int(mx + (tgt[0] - mx) * t), int(base + 20 + (tgt[1] - base - 20) * t + (1 - t) * 30), 0, P, WOOD_D)
            for k in range(0, 80):                                         # amantillo
                t = k / 79
                M.put(int(mx + (tgt[0] - mx) * t), int(base + mh - 60 + (tgt[1] + 2 - base - mh + 60) * t), 0, P, ROPE_D)
        for s in (-1, 1):                                                 # obenques
            for j in range(3):
                for k in range(0, 160):
                    t = k / 159
                    M.put(mx + int((j - 1) * 8 * t), int(base + mh - 40 - t * (mh - 42)), s * int(2 + t * (BEAM - 3)), P, ROPE_D)
        for k in range(0, 220):                                           # estay
            t = k / 219
            tx = (L - 10) if mx > 0 else (-L + 10)
            M.put(int(mx + (tx - mx) * t), int(base + mh - (mh - 24) * t), 0, P, ROPE_D)
    # carga en cubierta: barriles y cajas con flejes
    for bx, bz, kind in ((70, -30, 'b'), (78, -30, 'b'), (70, -22, 'b'), (-190, 24, 'c'), (-180, 24, 'c'), (-185, 14, 'c'), (180, 26, 'c')):
        by = deck_y(bx)
        if kind == 'b':
            for y in range(by + 1, by + 12):
                for x in range(bx - 4, bx + 4):
                    for z in range(bz - 4, bz + 4):
                        if (x - bx + 0.5) ** 2 + (z - bz + 0.5) ** 2 > 13: continue
                        M.put(x, y, z, P, IRON if y in (by + 2, by + 10) else lerp(WOOD, WOOD_D, 0.4 * M.hsh(x, z, 1)))
        else:
            for y in range(by + 1, by + 10):
                for x in range(bx - 5, bx + 5):
                    for z in range(bz - 5, bz + 5):
                        edge = x in (bx - 5, bx + 4) or z in (bz - 5, bz + 4) or y in (by + 1, by + 9)
                        if not edge: continue
                        c = CRATE if (y - by) % 3 else WOOD_D
                        if x in (bx - 5, bx + 4) and z in (bz - 5, bz + 4): c = IRON
                        M.put(x, y, z, P, c)
    piv = {P: [0, 0, 0], 'flag': [-L + 14, ftop, 0]}
    piv.update({'smoke' + ('' if i == 0 else '_%d' % (i + 1)): s for i, s in enumerate(smokes)})
    return M, piv


def bolardo():
    """Bolardo de amarre (rehecho a 64/m en la revisión de arte del 13-10-2026): hierro fundido en
    forma de seta, con el sombrerete que vuela, collarín, base con pernos sobre una placa, pintura
    negra gastada que deja ver el óxido, y un cabo grueso dado de vueltas en ocho con el chicote que
    se va por el muelle."""
    M = Model(S=4, seed=102)
    for y in range(0, 48):
        if y < 4: r = 18
        elif y < 8: r = 14
        elif y < 36: r = 10 - 1.5 * math.sin((y - 8) / 28 * math.pi)
        elif y < 40: r = 12
        else: r = 15 - (y - 40) * 0.5
        for x in range(-19, 20):
            for z in range(-19, 20):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r or (d < r - 2 and y < 47 and y > 3): continue
                c = (0.10, 0.10, 0.11) if M.noise(x, y, z, 4.0) < 0.64 else lerp(RUST, (0.26, 0.12, 0.06), M.noise(x, y, z, 1.5))
                if y < 4: c = IRON
                if y >= 46: c = lerp(c, IRON_L, 0.6)                    # el canto gastado por los cabos
                M.put(x, y, z, P, c)
    for a in range(0, 360, 60):                                    # pernos de la placa
        M.put(int(15 * math.cos(math.radians(a))), 4, int(15 * math.sin(math.radians(a))), P, IRON_L)
    def rope(pts):
        s = 0.0
        for i in range(1, len(pts)):
            p0, p1 = pts[i - 1], pts[i]
            s += math.dist(p0, p1)
            for x in range(int(p1[0]) - 3, int(p1[0]) + 4):
                for y in range(int(p1[1]) - 3, int(p1[1]) + 4):
                    for z in range(int(p1[2]) - 3, int(p1[2]) + 4):
                        if (x - p1[0]) ** 2 + (y - p1[1]) ** 2 + (z - p1[2]) ** 2 > 7.5: continue
                        w = math.sin(3 * math.atan2(y - p1[1], z - p1[2]) + s * 0.9)
                        M.put(x, y, z, P, ROPE if w > -0.3 else ROPE_D)
    pts = []
    for k in range(0, 361 * 3, 4):                                 # vueltas alrededor del cuello
        a = math.radians(k)
        pts.append((13 * math.cos(a), 14 + k / 360 * 7, 13 * math.sin(a)))
    rope(pts)
    pts = [(13, 30, 0)] + [(13 + k, max(3, 30 - k * 0.8), k * 0.25) for k in range(1, 80)]   # chicote al muelle
    rope(pts)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for kk in [kk for kk in M.V if all((kk[0] + a, kk[1] + b, kk[2] + c) in M.V for a, b, c in nb)]: del M.V[kk]
    return M, {P: [0, 0, 0]}


def grua():
    """Grúa de puerto de mano (rehecha más grande, 6,5 m, a 32/m en la revisión de arte del
    13-10-2026): base de hierro remachada con pernos sobre el muelle, poste de vigas con
    celosía, cabina de chapa con el torno de manivela y su engranaje, pluma de celosía que sale
    inclinada con tirantes al poste, poleas en la punta y en el poste, cable que baja hasta un
    gancho con su pastecas y una red de carga con fardos colgando, contrapeso de piedra, y
    chorretones de óxido."""
    M = Model(S=2, seed=103)
    H = 150
    STEEL = (0.20, 0.22, 0.22); STEEL_L = (0.32, 0.34, 0.34)
    def iron(x, y, z):
        c = STEEL if (x + y + z) % 7 else STEEL_L
        if M.noise(x, y, z, 5.0) > 0.7: c = lerp(c, RUST, 0.6)
        return c
    for x in range(-22, 22):                                         # base
        for z in range(-22, 22):
            for y in range(0, 10):
                if min(x + 22, 21 - x, z + 22, 21 - z) > 1 and 0 < y < 9: continue
                c = iron(x, y, z)
                if y == 9 and (x % 6 == 0 or z % 6 == 0): c = IRON_L
                M.put(x, y, z, P, c)
    for (x, z) in ((-19, -19), (-19, 18), (18, -19), (18, 18)):
        M.put(x, 10, z, P, IRON_L); M.put(x, 11, z, P, IRON_L)
    for y in range(10, H):                                           # poste de cuatro vigas con celosía
        for cx in (-6, 5):
            for cz in (-6, 5):
                for dx in (0, 1):
                    for dz in (0, 1): M.put(cx + dx, y, cz + dz, P, iron(cx, y, cz))
        k = (y - 10) % 24
        for i in range(12):
            if k == i * 2:
                for s in (-6, 6): M.put(-6 + i, y, s, P, iron(i, y, s)); M.put(s, y, -6 + i, P, iron(s, y, i))
    for x in range(-12, 14):                                         # cabina del torno
        for z in range(-12, 12):
            for y in range(18, 52):
                if min(x + 12, 13 - x, z + 12, 11 - z) > 0 and y < 51: continue
                c = (0.30, 0.34, 0.32) if (x // 6 + y // 8) % 2 else (0.26, 0.30, 0.28)
                if z == 11 and 26 < y < 44 and -6 < x < 8: continue    # hueco delantero
                if y >= 50: c = (0.22, 0.24, 0.24)
                if M.noise(x, y, z, 4.0) > 0.72: c = lerp(c, RUST, 0.6)
                M.put(x, y, z, P, c)
    for a in range(0, 360, 8):                                       # tambor del torno y engranaje
        for r in range(0, 8):
            for z in range(-6, 7):
                if r > 6 or (r > 4 and z % 3): M.put(int(r * math.cos(math.radians(a))), 34 + int(r * math.sin(math.radians(a))), z, P, ROPE_D if r <= 6 else IRON)
        M.put(int(9 * math.cos(math.radians(a))), 34 + int(9 * math.sin(math.radians(a))), 10, P, IRON_L if a % 24 else IRON)
    for k in range(10): M.put(0, 34 + k, 13, P, IRON); M.put(k, 44, 13, P, IRON)  # manivela
    for x in range(-40, -18):                                        # contrapeso de piedra
        for z in range(-10, 10):
            for y in range(10, 30): M.put(x, y, z, P, (0.44, 0.43, 0.40) if (x + y) % 5 else (0.36, 0.35, 0.32))
    for x in range(-18, 0):
        M.put(x, 26, -2, P, IRON); M.put(x, 26, 1, P, IRON)
    tipx, tipy = 120, H + 26                                         # pluma de celosía
    for k in range(0, 130):
        t = k / 129
        x = int(4 + (tipx - 4) * t); y = int(H - 30 + (tipy - H + 30) * t)
        for dz in (-4, 3):
            M.put(x, y, dz, P, iron(x, y, dz)); M.put(x, y + 6, dz, P, iron(x, y + 6, dz))
        if k % 10 < 2:
            for dy in range(0, 7):
                for dz in (-4, 3): M.put(x, y + dy, dz, P, iron(x, y, dz))
        if k % 10 == 0:
            for dz in range(-4, 4): M.put(x, y, dz, P, iron(x, y, dz)); M.put(x, y + 6, dz, P, iron(x, y, dz))
    for k in range(0, 130):                                          # tirantes al poste
        t = k / 129
        M.put(int(0 + tipx * t), int(H + 8 + (tipy + 6 - H - 8) * t), 0, P, IRON)
    for (px, py) in ((tipx, tipy), (0, H + 8)):                     # poleas
        for a in range(0, 360, 20):
            for r in (3, 4):
                M.put(px + int(r * math.cos(math.radians(a))), py + int(r * math.sin(math.radians(a))), 0, P, IRON_L)
    for y in range(66, tipy): M.put(tipx + 3, y, 0, P, ROPE_D)       # cable
    for k in range(0, tipx): M.put(k, H + 10 + int(k * (tipy - H - 10) / tipx), 1, P, ROPE_D)
    for y in range(58, 66):                                          # pasteca y gancho
        for x in range(tipx, tipx + 7): M.put(x, y, 0, P, IRON)
    for k in range(10):
        a = math.radians(180 + k * 20)
        M.put(int(tipx + 3 + 4 * math.cos(a)), int(52 + 4 * math.sin(a)), 0, P, IRON_L)
    for s in (-1, 1):                                                # red de carga con fardos
        for k in range(20): M.put(tipx + 3 + s * k // 2, 50 - k, s * k // 3, P, ROPE)
    for x in range(tipx - 10, tipx + 17):
        for y in range(18, 32):
            for z in range(-10, 10):
                d = ((x - tipx - 3) / 13) ** 2 + ((y - 25) / 7) ** 2 + (z / 9) ** 2
                if d > 1: continue
                net = (x + y) % 4 == 0 or (x - y) % 4 == 0
                M.put(x, y, z, P, ROPE_D if net else ((0.52, 0.48, 0.38) if (x + z) % 3 else (0.44, 0.38, 0.28)))
    return M, {P: [0, 0, 0]}


BROWNS = [(0.46, 0.32, 0.20), (0.40, 0.27, 0.16), (0.53, 0.38, 0.24), (0.34, 0.23, 0.14), (0.57, 0.43, 0.28),
          (0.44, 0.34, 0.24), (0.30, 0.20, 0.12)]
BATTEN = (0.28, 0.19, 0.11); GRAIN = (0.22, 0.14, 0.08); SILVER = (0.50, 0.47, 0.42); STENCIL = (0.12, 0.10, 0.08)
BURLAP = (0.58, 0.48, 0.32); BURLAP_D = (0.46, 0.37, 0.24)


def _crate(M, x0, x1, y0, y1, z0, z1, seed, brace='x', stencil=True):
    """Caja de carga de tablas: cada tabla con su marrón, veta alargada, algún nudo y clavos en
    las testas; listones de refuerzo en relieve en los cantos, tornapuntas en diagonal, cantoneras
    de hierro, marcas pintadas y la madera agrisada por arriba."""
    W, H, D = x1 - x0, y1 - y0, z1 - z0
    def face_col(u, v, L, Hh, fid):
        plank = v // 4
        c = BROWNS[int(M.hsh(seed, fid, plank) * len(BROWNS))]
        if v % 4 == 0: c = lerp(c, GRAIN, 0.6)                              # junta entre tablas
        g = M.noise(u * 0.22 + fid * 40, v * 1.4, plank * 3 + seed, 1.0)    # veta alargada
        c = lerp(c, GRAIN, 0.45 * max(0.0, g - 0.45) / 0.55)
        kx = int(M.hsh(seed, fid, plank + 50) * (L - 8)) + 4                # nudo
        if M.hsh(seed, fid, plank + 90) > 0.6 and abs(u - kx) <= 1 and v % 4 == 2: c = lerp(c, GRAIN, 0.8 if u == kx else 0.4)
        if v % 4 == 2 and u in (3, L - 4): c = IRON_L                         # clavos
        return c
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                sx = x in (x0, x1 - 1); sz = z in (z0, z1 - 1); top = y == y1 - 1
                if not (sx or sz or top or y == y0): continue
                if top: c = face_col(x - x0, z - z0 + 1, W, D, 5)
                elif sz: c = face_col(x - x0, y - y0 + 1, W, H, 1 if z == z0 else 2)
                else: c = face_col(z - z0, y - y0 + 1, D, H, 3 if x == x0 else 4)
                if top: c = lerp(c, SILVER, 0.25 + 0.3 * M.noise(x, y, z, 5.0))   # agrisada por el sol y la sal
                M.put(x, y, z, P, c)
    # listones en los cantos y tornapuntas, en relieve (un voxel hacia fuera)
    def relief(u, v, L, Hh):
        edge = u < 2 or u >= L - 2 or v < 2 or v >= Hh - 2
        if brace == 'x': diag = abs(u * (Hh - 1) / (L - 1) - v) < 1.1 or abs((L - 1 - u) * (Hh - 1) / (L - 1) - v) < 1.1
        elif brace == 'z': diag = abs(u * (Hh - 1) / (L - 1) - v) < 1.1
        else: diag = abs(v - Hh // 2) < 1
        return edge or diag
    for x in range(x0, x1):                                                 # caras z
        for y in range(y0, y1):
            if relief(x - x0, y - y0, W, H):
                for z, dz in ((z0, -1), (z1 - 1, 1)):
                    c = lerp(BATTEN, BROWNS[3], M.hsh(x, y, z) * 0.4)
                    M.put(x, y, z + dz, P, c)
    for z in range(z0, z1):                                                 # caras x
        for y in range(y0, y1):
            if relief(z - z0, y - y0, D, H):
                for x, dx in ((x0, -1), (x1 - 1, 1)):
                    M.put(x + dx, y, z, P, lerp(BATTEN, BROWNS[3], M.hsh(x, y, z) * 0.4))
    for (cx, dx) in ((x0, -1), (x1 - 1, 1)):                                # cantoneras de hierro
        for (cz, dz) in ((z0, -1), (z1 - 1, 1)):
            for y in (y0, y0 + 1, y1 - 2, y1 - 1):
                M.put(cx + dx, y, cz + dz, P, IRON)
                M.put(cx + dx, y, cz, P, IRON); M.put(cx, y, cz + dz, P, IRON)
    if stencil:                                                             # marca pintada (rombo y barras)
        mx, my = (x0 + x1) // 2, y0 + H // 2
        for dx in range(-4, 5):
            for dy in range(-4, 5):
                if abs(dx) + abs(dy) in (3, 4) and M.hsh(dx, dy, seed) > 0.15:
                    M.put(mx + dx, my + dy, z1, P, STENCIL)
        for dx in range(-3, 4):
            if M.hsh(dx, 0, seed + 1) > 0.2: M.put(mx + dx, my - 6, z1, P, STENCIL)


def fardos():
    """Carga apilada en el muelle y la cubierta: cajas de tablas de varios marrones con listones,
    tornapuntas y cantoneras, una lona trincada con cabo sobre la de arriba, un saco de arpillera
    y un barrilete (rehecho con más detalle en la revisión de arte del 13-10-2026)."""
    M = Model(S=2, seed=104)
    _crate(M, -23, -1, 0, 24, -16, 4, 1, 'x', stencil=False)
    _crate(M, 0, 21, 0, 22, -14, 6, 2, 'z', stencil=False)
    _crate(M, -10, 7, 0, 15, 8, 20, 3, 'h', stencil=False)
    _crate(M, -12, 9, 24, 42, -12, 4, 4, 'z', stencil=False)
    _crate(M, 10, 19, 22, 30, -10, -1, 5, 'h', stencil=False)             # cajita encima
    # lona sobre la caja de arriba: cubre el techo con pliegues y cae por delante con el bajo ondulado
    for x in range(-13, 10):
        for z in range(-13, 5):
            band = (x + 13) % 6 in (0, 1)
            M.put(x, 42, z, P, lerp(CANVAS, CANVAS_D, (0.55 if band else 0.0) + 0.25 * M.noise(x, 42, z, 4.0)))
        hem = 33 + int(round(1.6 * math.sin(x * 0.45)))
        for y in range(hem, 42):
            M.put(x, y, 5, P, CANVAS_D if y == hem else lerp(CANVAS, CANVAS_D, 0.6 if (x + 13) % 6 in (0, 1) else 0.15))
    # cabo de trinca: cruza por encima y baja por los lados
    for x in range(-14, 11):
        for zc in (-9, -2):
            M.put(x, 43, zc, P, ROPE if (x // 2) % 2 else ROPE_D)
    for zc in (-9, -2):
        for y in range(24, 43):
            c = ROPE if (y // 2) % 2 else ROPE_D
            M.put(-13, y, zc, P, c); M.put(9, y, zc, P, c)
    # saco de arpillera apoyado
    for x in range(-25, -13):
        for y in range(0, 12):
            for z in range(6, 18):
                if ((x + 19) / 5.2) ** 2 + ((y - 5) / 6.5) ** 2 + ((z - 12) / 6.0) ** 2 > 1: continue
                c = BURLAP if (x + y + z) % 2 else BURLAP_D
                if y in (9, 10) and abs(x + 19) < 3: c = ROPE_D                     # atado
                M.put(x, y, z, P, c)
    # barrilete de duelas con aros
    for y in range(0, 16):
        r = 5.0 + 1.2 * math.sin(math.pi * y / 15)
        for x in range(8, 23):
            for z in range(7, 22):
                d = math.hypot(x - 15.0, z - 14.0)
                if d > r or (d < r - 1.2 and 0 < y < 15): continue
                a = math.atan2(z - 14.0, x - 15.0)
                c = BROWNS[int((a + math.pi) / math.tau * 14) % len(BROWNS)]       # duelas
                if y in (2, 3, 12, 13): c = IRON
                if y == 15: c = lerp(BROWNS[0], SILVER, 0.3)
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


ROPE_L = (0.68, 0.60, 0.42); TWINE = (0.20, 0.16, 0.12)


def _rope(M, pts, rr, s0=0.0):
    """Cabo a lo largo de una polilínea densa: tubo de radio rr (voxels) con el colchado de tres
    cordones (franjas en hélice) y la mugre en la parte de abajo."""
    s = s0
    for i in range(1, len(pts)):
        p0, p1 = pts[i - 1], pts[i]
        tx, ty, tz = (p1[k] - p0[k] for k in range(3))
        L = math.sqrt(tx * tx + ty * ty + tz * tz) or 1e-6
        tx, ty, tz = tx / L, ty / L, tz / L
        s += L
        # base perpendicular: n (horizontal, perpendicular a t) y b = t x n
        nx, nz = -tz, tx; nl = math.hypot(nx, nz) or 1.0; nx, nz = nx / nl, nz / nl
        bx, by, bz = ty * nz, tz * nx - tx * nz, -ty * nx
        for x in range(int(p1[0] - rr) - 1, int(p1[0] + rr) + 2):
            for y in range(int(p1[1] - rr) - 1, int(p1[1] + rr) + 2):
                for z in range(int(p1[2] - rr) - 1, int(p1[2] + rr) + 2):
                    o = (x + 0.5 - p1[0], y + 0.5 - p1[1], z + 0.5 - p1[2])
                    along = o[0] * tx + o[1] * ty + o[2] * tz
                    if abs(along) > 0.8: continue
                    q = (o[0] - along * tx, o[1] - along * ty, o[2] - along * tz)
                    if q[0] ** 2 + q[1] ** 2 + q[2] ** 2 > rr * rr: continue
                    phi = math.atan2(q[0] * bx + q[1] * by + q[2] * bz, q[0] * nx + q[2] * nz)
                    w = math.sin(3 * phi + s * 0.75)                        # tres cordones en hélice
                    c = ROPE_L if w > 0.6 else (ROPE if w > -0.55 else ROPE_D)           # la junta entre cordones, oscura
                    if q[1] < -0.6 * rr: c = lerp(c, ROPE_D, 0.5)          # mugre abajo
                    M.put(x, y, z, P, c)
    return s


def rollo():
    """Cabo adujado: cuatro capas en espiral, unas sobre otras, con el colchado de los cordones
    a la vista, y el chicote que sale de arriba, baja al suelo y acaba en una ligada y deshilachado
    (rehecho en la revisión de arte del 13-10-2026)."""
    M = Model(S=4, seed=105)                                                # a 64/m: a 32 no se ve el colchado
    K = 2.0
    rr = 1.7 * K
    s = 0.0
    end = None
    for layer in range(4):
        y = rr + layer * (2 * rr - 0.5)
        r0, r1 = (4.5 * K, 12.0 * K) if layer % 2 == 0 else (12.0 * K, 4.5 * K)
        if layer == 3: r0, r1 = 4.5 * K, 9.5 * K                                    # la de arriba no llega al borde
        turns = abs(r1 - r0) / (2 * rr - 0.3)
        n = int(turns * 140)
        pts = []
        for k in range(n + 1):
            f = k / n
            a = f * turns * math.tau + layer * 1.1
            R = r0 + (r1 - r0) * f
            pts.append((math.cos(a) * R, y, math.sin(a) * R))
        s = _rope(M, pts, rr, s)
        end = pts[-1]
    # chicote: sale de arriba, cae por fuera del rollo y se arrastra por el suelo
    a = math.atan2(end[2], end[0])
    pts = []
    for k in range(0, 121):
        f = k / 120
        R = (9.5 + 14 * f) * K
        drop = min(1.0, f * 3.5)
        aa = a + 0.35 * f + 0.25 * math.sin(f * 7)
        y = end[1] * (1 - drop) + rr * drop + (1 - drop) ** 2 * 1.5
        pts.append((math.cos(aa) * R, y, math.sin(aa) * R))
    _rope(M, pts, rr * 0.9, s)
    tip = pts[-1]; d = (pts[-1][0] - pts[-6][0], pts[-1][2] - pts[-6][2]); dl = math.hypot(*d) or 1
    d = (d[0] / dl, d[1] / dl)
    for k in range(-6, 0):                                                  # ligada de piola oscura
        for x in range(-4, 5):
            for z in range(-4, 5):
                px = tip[0] + d[0] * k + x * 0.6 * -d[1]; pz = tip[2] + d[1] * k + x * 0.6 * d[0]
                M.put(int(px), int(tip[1] + z * 0.5), int(pz), P, TWINE)
    for i in range(14):                                                     # deshilachado
        ang = M.hsh(i, 1, 2) * 1.6 - 0.8
        off = (M.hsh(i, 5, 5) - 0.5) * 2 * rr
        L = 4 + int(M.hsh(i, 2, 3) * 6)
        for k in range(L):
            px = tip[0] - d[1] * off + (d[0] * math.cos(ang) - d[1] * math.sin(ang)) * (k + 1)
            pz = tip[2] + d[0] * off + (d[1] * math.cos(ang) + d[0] * math.sin(ang)) * (k + 1)
            M.put(int(px), int(max(0, tip[1] - 2 + M.hsh(i, k, 4) * 4)), int(pz), P, ROPE_L if k % 2 else ROPE)
    return M, {P: [0, 0, 0]}


LIGHT_C = (1.0, 0.93, 0.72); GLASS_L = (1.0, 0.82, 0.50); IRON_D = (0.08, 0.08, 0.09)
PAINT_W = (0.74, 0.72, 0.66); PAINT_R = (0.46, 0.14, 0.11); BARN_W = (0.70, 0.68, 0.60); WEED_D = (0.14, 0.22, 0.12)


def linterna():
    """Farol de puerto (rehecho a 64/m en la revisión de arte del 13-10-2026, más alto: 3,6 m):
    poste de hierro fundido con basa escalonada y pernos, fuste estriado con anillos, brazo con
    voluta y tornapunta, y un farol de barco colgado: jaula de cuatro barrotes, cristales que
    brillan con la llama clara dentro, sombrerete cónico con chimenea y aro, y bandeja abajo."""
    M = Model(S=4, seed=106)
    H = 220
    for y in range(0, H):                                          # poste
        if y < 14: r = 7 - y // 5                                   # basa escalonada
        elif y < 18: r = 4
        else: r = 3.2 - 0.6 * (y / H)
        for x in range(-8, 9):
            for z in range(-8, 9):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r: continue
                a = math.atan2(z + 0.5, x + 0.5)
                c = IRON if (int((a + math.pi) / math.tau * 8) % 2 or y < 18) else IRON_D       # estrías
                if y in (18, 19, 90, 91, 150, 151): c = IRON_L                                      # anillos
                if y < 14 and M.noise(x, y, z, 3.0) > 0.6: c = lerp(c, RUST, 0.6)
                M.put(x, y, z, P, c)
    for (bx, bz) in ((-5, -5), (4, -5), (-5, 4), (4, 4)): M.put(bx, 14, bz, P, IRON_L)   # pernos
    for y in range(H, H + 6):                                       # remate
        for x in range(-4, 5):
            for z in range(-4, 5):
                if math.hypot(x + 0.5, z + 0.5) < 4 - (y - H) * 0.5: M.put(x, y, z, P, IRON)
    AY = H - 10
    for x in range(0, 36):                                          # brazo
        for y in (AY, AY + 1, AY + 2):
            for z in (-1, 0): M.put(x, y, z, P, IRON)
    for i in range(24):                                             # tornapunta
        for z in (-1, 0): M.put(2 + i, AY - 26 + i, z, P, IRON)
    for a in range(0, 330, 8):                                      # voluta
        t = math.radians(a); r = 2 + a / 50
        for z in (-1, 0): M.put(int(round(14 + r * math.cos(t))), int(round(AY - 10 + r * math.sin(t))), z, P, IRON)
    LX, LY = 32, AY - 30                                            # farol colgado
    for y in range(LY + 26, AY): M.put(LX, y, 0, P, IRON_L if y % 2 else IRON)          # cadena
    for x in range(LX - 7, LX + 8):                                 # bandeja
        for z in range(-7, 8):
            if max(abs(x - LX), abs(z)) <= 7: M.put(x, LY, z, P, IRON); M.put(x, LY + 1, z, P, IRON if max(abs(x - LX), abs(z)) == 7 else IRON_D)
    for y in range(LY + 2, LY + 20):                                # jaula y cristales
        for x in range(LX - 6, LX + 7):
            for z in range(-6, 7):
                m = max(abs(x - LX), abs(z))
                if m > 6: continue
                bar = m == 6 and (abs(x - LX) == 6 and abs(z) == 6)
                rib = m == 6 and (y in (LY + 2, LY + 10, LY + 19) or x == LX or z == 0)
                if bar or rib: M.put(x, y, z, P, IRON); continue
                if m == 6: M.put(x, y, z, P, GLASS_L, glow=1); continue
                if m <= 2 and LY + 6 < y < LY + 14: M.put(x, y, z, P, LIGHT_C, glow=1)      # llama
    for y in range(LY + 20, LY + 28):                               # sombrerete y chimenea
        w = 7 - (y - LY - 20)
        for x in range(LX - w, LX + w + 1):
            for z in range(-w, w + 1):
                if max(abs(x - LX), abs(z)) == w or y == LY + 27: M.put(x, y, z, P, IRON)
    for a in range(0, 360, 20):                                     # aro
        M.put(LX + int(round(3 * math.cos(math.radians(a)))), LY + 29 + int(round(3 * math.sin(math.radians(a)) * 0.6)), 0, P, IRON_L)
    return M, {P: [0, 0, 0], 'light': [LX, LY + 10, 0]}


def bote():
    """Bote volcado sobre el muelle (rehecho a 64/m en la revisión de arte del 13-10-2026): casco
    de tingladillo (tracas solapadas) pintado de blanco que se pelotea, con la franja roja de la
    flotación, quilla y roda de madera, desconchones que dejan ver la madera, percebes y verdín
    en la borda, un tablón roto, y dos remos y un achicador al lado."""
    M = Model(S=4, seed=107)
    L, W, HH = 80, 26, 30
    def top_at(x, z):
        f = abs(x) / L
        w = W * math.sqrt(max(0.0, 1 - f ** 2.2))
        if w < 1 or abs(z) > w: return -1
        u = abs(z) / w
        return int(HH * (1 - 0.15 * f ** 2) * math.sqrt(max(0.0, 1 - u ** 2.4)))  # el fondo arriba (volcado)
    for x in range(-L, L):
        f = abs(x) / L
        w = W * math.sqrt(max(0.0, 1 - f ** 2.2))
        if w < 1: continue
        for z in range(-int(w) - 1, int(w) + 2):
            ystr = top_at(x, z)
            if ystr < 0: continue
            u = abs(z) / max(w, 1)
            low = min([top_at(x + a, z + b) for a, b in ((1, 0), (-1, 0), (0, 1), (0, -1))] + [ystr - 3])
            strake = int(u * 7)                                                       # tracas
            for y in range(max(0, low), ystr + 1):
                c = PAINT_W
                if y < 6: c = PAINT_R                                                 # franja de la flotación (junto al suelo)
                if (u * 7) % 1 < 0.14: c = lerp(c, (0.20, 0.18, 0.15), 0.6)           # solape de la traca
                c = lerp(c, (0.46, 0.44, 0.40), 0.25 * M.noise(x, y, z, 8.0))      # mugre
                if M.noise(x, y, z, 3.0) > 0.80: c = lerp(WOOD, WOOD_D, M.noise(x, y, z, 1.5))   # desconchón
                if y < 4 and M.hsh(x, y, z) > 0.85: c = BARN_W if M.hsh(x, 1, z) > 0.4 else WEED_D
                if 20 < x < 34 and 2 <= strake <= 3 and z > 0: continue               # tablón roto (hueco)
                M.put(x, y, z, P, c)
    for x in range(-L + 2, L - 1):                                                    # quilla
        f = abs(x) / L
        y = int(HH * (1 - 0.15 * f ** 2))
        for dy in range(0, 3):
            for z in (-1, 0): M.put(x, y + dy, z, P, WOOD_D if dy else WOOD)
    for y in range(0, HH):                                                            # roda y espejo
        M.put(L - 1, y, 0, P, WOOD_D); M.put(L - 1, y, -1, P, WOOD_D)
    for z in range(-12, 13):
        for y in range(0, 18):
            if (abs(z) / 12) ** 2 + (y / 18) ** 2 < 1: M.put(-L + 1, y, z, P, WOOD if (y // 3) % 2 else WOOD_D)
    for k, zz in enumerate((W + 6, W + 12)):                                          # remos
        for x in range(-60, 40):
            for z in (zz, zz + 1): M.put(x, 1, z + (x // 30), P, lerp(WOOD, WHITE, 0.2))
        for x in range(40, 62):
            for z in range(zz - 3, zz + 4): M.put(x, 1, z + (x // 30), P, WOOD)
    for x in range(-40, -30):                                                          # achicador
        for z in range(W + 20, W + 28):
            for y in range(0, 6):
                if y == 0 or x in (-40, -31) or z in (W + 20, W + 27): M.put(x, y, z, P, IRON_L if y < 5 else IRON)
    return M, {P: [0, 0, 0]}


BARCA_PAINT = {1: ((0.70, 0.68, 0.62), (0.44, 0.13, 0.10)), 2: ((0.24, 0.36, 0.40), (0.70, 0.66, 0.56)),
               3: ((0.30, 0.38, 0.26), (0.42, 0.30, 0.18))}


def barca(variant=1):
    """Barca de remos amarrada al muelle, a flote (revisión de arte del 14-10-2026), 64/m, 2,6 m:
    casco de tingladillo con la pintura de su variante (blanca con franja roja, azul petróleo con
    crema, verde con pardo), regala y roda de madera, bancadas, los remos recogidos dentro, agua
    de sentina, un rollo de cabo, una nasa o un cubo, y la amarra que sube desde la proa (+x)
    hasta el borde del muelle (0,9 m más arriba y 0,6 m por delante). El origen está en la línea
    de flotación: lo que queda por debajo de y = 0 va bajo el agua."""
    M = Model(S=4, seed=110 + variant)
    rng = M.rng
    HULL, BAND = BARCA_PAINT[variant]
    L, W, HH, DRAFT = 82, 26, 30, 10
    def width(x):
        f = abs(x) / L
        if x > 0: return W * max(0.0, 1 - f ** 1.7) ** 0.8                          # proa afilada
        return W * (1 - 0.42 * f ** 2.5)                                             # popa ancha (espejo)
    def gun(x): return HH + int((14 if x > 0 else 7) * (abs(x) / L) ** 2)           # arrufo, más alto en la proa
    def hull_c(x, y, z, u):
        c = HULL
        if y < 6: c = BAND                                                           # franja de la flotación
        if (u * 6) % 1 < 0.14: c = lerp(c, (0.16, 0.14, 0.12), 0.55)                 # solape de las tracas
        c = lerp(c, (0.40, 0.40, 0.36), 0.25 * M.noise(x, y, z, 7.0))               # mugre
        if M.noise(x, y, z, 3.0) > 0.80: c = lerp(WOOD, WOOD_D, M.noise(x, y, z, 1.5))   # desconchón
        if y < 2: c = lerp(c, (0.12, 0.20, 0.12), 0.6)                               # verdín en la flotación
        return c
    for x in range(-L, L):
        w = width(x)
        if w < 1: continue
        for z in range(-int(w) - 1, int(w) + 2):
            u = abs(z) / w
            if u > 1: continue
            yb = int(-DRAFT + (HH + DRAFT) * 0.55 * u ** 2.2 + 3 * (abs(x) / L) ** 3)   # fondo en V suave
            g = gun(x)
            if u > 1 - 2.5 / max(w, 1) or abs(x) > L - 3 or (x < -L + 4):            # costados, roda y espejo
                for y in range(yb, g + 1): M.put(x, y, z, P, hull_c(x, y, z, u))
            else:
                for y in (yb, yb + 1): M.put(x, y, z, P, WOOD_D if (z // 5) % 2 else WOOD)   # plan
                if yb + 2 <= -3:
                    M.put(x, yb + 2, z, P, (0.12, 0.16, 0.14) if M.hsh(x, z, 1) > 0.1 else (0.24, 0.28, 0.26))   # agua de sentina
    for x in range(-L, L):                                                           # regala de madera
        w = width(x)
        if w < 2: continue
        for s in (-1, 1):
            for d in range(3): M.put(x, gun(x) + 1, s * (int(w) - d), P, WOOD if d else WOOD_D)
    for y in range(-DRAFT, gun(L) + 4):                                              # roda
        M.put(L - 1, y, 0, P, WOOD_D); M.put(L, y, 0, P, WOOD_D)
    for xb in (-44, -4, 36):                                                         # bancadas
        w = int(width(xb)) - 2
        for z in range(-w, w + 1):
            for x in range(xb, xb + 8): M.put(x, HH - 7, z, P, WOOD if (x - xb) % 4 else WOOD_D)
    for s in (-1, 1):                                                                # remos recogidos
        for x in range(-64, 52):
            z = s * 9 + (x // 40) * s
            M.put(x, HH - 5, z, P, lerp(WOOD, (0.80, 0.78, 0.70), 0.25))
            if x > 32:
                for d in range(-3, 4): M.put(x, HH - 5, z + d, P, WOOD)
        for k in range(4): M.put(-10 + k, gun(-10) + 2, s * (int(width(-10)) - 1), P, IRON)   # chumaceras
    for a in range(0, 360, 12):                                                      # rollo de cabo en la proa
        for r in (5, 6, 7):
            M.put(56 + int(r * math.cos(math.radians(a))), HH - 6 + (r - 5), int(r * math.sin(math.radians(a))), P, ROPE if r != 6 else ROPE_D)
    if variant == 2:                                                                 # nasa
        for y in range(HH - 6, HH + 6):
            for a in range(0, 360, 15):
                r = 7 if y < HH + 3 else 4
                M.put(-60 + int(r * math.cos(math.radians(a))), y, int(r * math.sin(math.radians(a))), P, ROPE_D if (a // 15 + y) % 2 else WOOD_D)
    else:                                                                            # cubo
        for y in range(HH - 6, HH + 2):
            for a in range(0, 360, 15):
                M.put(-24 + int(5 * math.cos(math.radians(a))), y, 12 + int(5 * math.sin(math.radians(a))), P, IRON_L if y != HH + 1 else IRON)
    # amarra: de la cornamusa de la proa hasta el muelle (+x 38 voxels, +48 de altura: llega a la tabla)
    x0, y0 = L - 4, gun(L) + 2
    for i in range(80):
        t = i / 79
        x = x0 + 38 * t
        y = y0 + 48 * t - 14 * math.sin(math.pi * t)                                  # catenaria
        for d in (0, 1): M.put(int(x), int(y) + d, 0, P, ROPE if i % 3 else ROPE_D)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


TEAK = (0.46, 0.32, 0.18); TEAK_D = (0.32, 0.21, 0.11); TEAK_L = (0.58, 0.42, 0.25)
INNER = (0.62, 0.60, 0.54); INNER_D = (0.48, 0.46, 0.41); SLIME_G = (0.16, 0.24, 0.14)


def borda():
    """Tramo de borda de la cubierta del Emma (4 m), rehecho en la revisión de arte del 13-10-2026:
    regala de tablas (negra por fuera, gris claro por dentro, con desconchones, sal y regueros
    de óxido), regala de teca barnizada con veta y empalmes que vuela a los dos lados, cuadernas
    con curvas en la base por dentro, trancanil, imbornales con marco de hierro y verdín, una
    cornamusa, una gatera para los cabos, un cáncamo y un cabillero con cabillas. Baja (1 m)
    porque va del lado de la cámara (32/m). Fuera: z < 0; cubierta: z > 0."""
    M = Model(S=2, seed=108)
    X0, X1, HB = -64, 64, 28
    scup = [x for x in range(X0 + 10, X1, 24)]                          # imbornales
    def plank_col(x, y, outer):
        b = y // 4
        off = int(M.hsh(b, 1, 3) * 40)
        c = lerp(HULL, HULL_L, 0.3 * M.hsh(b, (x + off) // 40, 1)) if outer else lerp(INNER, INNER_D, 0.35 * M.hsh(b, (x + off) // 40, 2))
        if y % 4 == 0: c = lerp(c, (0.03, 0.03, 0.03), 0.6)            # junta
        elif (x + off) % 40 == 0: c = lerp(c, (0.03, 0.03, 0.03), 0.4)  # testa
        n = M.noise(x, y, 5 if outer else 9, 4.0)
        if n > 0.78: c = lerp(c, TEAK_D, 0.7) if not outer else lerp(c, (0.30, 0.28, 0.25), 0.6)   # desconchón
        if y > HB - 6 and M.noise(x, y, 2, 3.0) > 0.7: c = lerp(c, (0.70, 0.72, 0.70), 0.35)        # sal
        return c
    for x in range(X0, X1):
        for y in range(0, HB):
            hole = any(sx <= x < sx + 6 for sx in scup) and y < 5 and not (y == 4 and (x - X0) % 24 in (10, 15))
            if hole: continue
            for z in (-2, -1, 0, 1):
                outer = z < 0
                c = plank_col(x, y, outer)
                if outer and any(sx - 1 <= x <= sx + 6 for sx in scup) and y < 6: c = IRON          # marco del imbornal
                M.put(x, y, z, P, c)
        for sx in scup:                                                 # verdín y regueros bajo los imbornales (fuera)
            pass
    for sx in scup:
        for x in range(sx, sx + 6):
            for y in range(0, 4):
                M.put(x, y, -3, P, SLIME_G) if y == 0 else None
    for x in range(X0, X1):                                             # regueros por fuera
        if M.hsh(x // 2, 4, 4) > 0.86:
            top = HB - 2
            for y in range(top - int(6 + M.hsh(x, 5, 5) * 14), top):
                v = M.V.get((x, y, -2))
                if v: v[1] = lerp(v[1], RUST, 0.55)
    # regala de teca: vuela a los dos lados, con veta y empalmes en rayo de Júpiter
    for x in range(X0, X1):
        for y in range(HB, HB + 3):
            for z in range(-4, 4):
                if y == HB and z in (-4, 3): continue
                c = lerp(TEAK, TEAK_D, 0.6 * M.noise(x * 0.25, y, z * 3, 1.0))
                if (x + z * 3) % 11 == 0: c = lerp(c, TEAK_D, 0.5)
                if y == HB + 2: c = lerp(c, TEAK_L, 0.35)
                if (x - X0) % 64 in (30, 31) and y == HB + 1: c = TEAK_D        # empalme
                M.put(x, y, z, P, c)
    # trancanil (por dentro, a ras de cubierta)
    for x in range(X0, X1):
        for z in (2, 3, 4):
            for y in (0, 1): M.put(x, y, z, P, lerp(TEAK_D, (0.18, 0.13, 0.08), 0.3 * M.hsh(x, z, 6)))
    # cuadernas con curva en la base (por dentro) y pernos por fuera
    for sx in range(X0 + 8, X1, 20):
        for y in range(0, HB):
            for x in (sx, sx + 1, sx + 2):
                for z in (2, 3): M.put(x, y, z, P, INNER_D if x != sx + 1 else INNER)
        for k in range(8):                                              # curva
            for y in range(0, 8 - k):
                for x in (sx, sx + 1, sx + 2): M.put(x, y + 0, 4 + k // 2, P, INNER_D)
        for y in (6, 16, 24): M.put(sx + 1, y, -3, P, IRON_L)            # pernos
    # cornamusa sobre la regala, gatera, cáncamo y cabillero
    cx = X0 + 22
    for x in range(cx - 6, cx + 7):
        h = 2 if abs(x - cx) > 3 else 1
        M.put(x, HB + 3 + h, 0, P, IRON); M.put(x, HB + 3 + h, 1, P, IRON)
    for x in (cx - 2, cx + 2):
        for y in (HB + 3, HB + 4): M.put(x, y, 0, P, IRON); M.put(x, y, 1, P, IRON)
    gx = X1 - 26
    for x in range(gx - 5, gx + 6):                                     # gatera (escotera abierta)
        for y in range(HB + 3, HB + 6):
            for z in range(-3, 3):
                if abs(x - gx) <= 2 and y < HB + 5: continue
                M.put(x, y, z, P, IRON if (x + y) % 5 else IRON_L)
    rx = X0 + 50                                                        # cáncamo con argolla
    for a in range(0, 360, 30):
        M.put(rx + int(round(2 * math.cos(math.radians(a)))), 12 + int(round(2 * math.sin(math.radians(a)))), 2, P, IRON_L)
    bx = X0 + 70                                                        # cabillero con cabillas
    for x in range(bx, bx + 22):
        for z in (2, 3, 4):
            M.put(x, 20, z, P, TEAK); M.put(x, 19, z, P, TEAK_D)
    for i in range(4):
        px = bx + 3 + i * 5
        for y in range(15, 25): M.put(px, y, 3, P, TEAK_L if y > 20 else TEAK)
        if i % 2 == 0:                                                  # cabo adujado colgando
            for y in range(10, 20):
                M.put(px - 1, y, 4, P, ROPE if y % 2 else ROPE_D); M.put(px + 1, y, 4, P, ROPE_D if y % 2 else ROPE)
    return M, {P: [0, 0, 0]}


# Superestructura del Emma (rehecha el 09-10-2026 siguiendo tools/replicate/ref_emma.png), 16/m.
# Piezas de 12 m a lo largo de x que se ponen seguidas en el borde norte de la cubierta: el
# puente en medio (alr_puente) y casetas a los lados (alr_caseta). Frente hacia +z (z = -1).
WIDTH = 96                                   # media anchura (12 m)
DEPTH = 34                                   # fondo (2,1 m)
WALL_H = 46                                  # altura de la caseta
BRASS = (0.62, 0.48, 0.22); GLASS = (0.10, 0.12, 0.14); WHITE_D = (0.56, 0.54, 0.48); RING_R = (0.70, 0.16, 0.12)
DOOR = (0.34, 0.24, 0.15)


PAINT_PEEL = (0.40, 0.33, 0.24); GRIME = (0.38, 0.36, 0.31); SALT = (0.80, 0.80, 0.76)
DOOR_D = (0.22, 0.15, 0.09); VARNISH = (0.44, 0.30, 0.16); ROOF = (0.42, 0.42, 0.40); ROOF_D = (0.32, 0.32, 0.31)
FIRE = (0.62, 0.10, 0.08); STEEL = (0.52, 0.54, 0.56)


def _plank(M, u, y, h):
    """Color de la pared de tablas en el punto (u a lo largo de la pared, y): tablas de 3 voxels
    con la junta oscura, testas escalonadas, tono por tabla, mugre abajo, sal y pintura pelada."""
    b = y // 3
    seg_len = 34
    off = int(M.hsh(b, 0, 7) * seg_len)
    seg = (u + off) // seg_len
    c = lerp(WHITE, WHITE_D, 0.10 + 0.30 * M.hsh(b, seg, 3))
    if y % 3 == 0: c = lerp(c, (0.30, 0.29, 0.26), 0.55)                       # junta entre tablas
    elif (u + off) % seg_len == 0: c = lerp(c, (0.30, 0.29, 0.26), 0.45)      # testa
    n = M.noise(u, y, 3, 5.0)
    if n > 0.80 and 6 < y < h - 6: c = PAINT_PEEL if n > 0.84 else lerp(c, PAINT_PEEL, 0.5)   # pintura pelada
    g = max(0.0, (14 - y) / 14) * 0.55 + 0.12 * M.noise(u, y, 9, 9.0)          # mugre y salpicaduras abajo
    c = lerp(c, GRIME, g)
    if M.noise(u, y, 17, 3.0) > 0.86: c = lerp(c, SALT, 0.5)                   # manchas de sal
    return c


def _caseta(M, x0, x1, z0, h, lit_every=3, doors=(), ladders=(), roof_props=True):
    """Caseta de tablas blancas muy gastada: zócalo de chapa remachada, montantes, cornisa de
    madera barnizada, portillos de latón con pernos, una ventana de cuarterones, puertas de
    cuarterones con farol, salvavidas con cabo, cubos contra incendios, hacha, tubería con
    abrazaderas, bajante y regueros de óxido; en el techo de lona, ventiladores, claraboya,
    rollo de cabo, pañol y baranda."""
    front = -1
    wall = set()
    for x in range(x0, x1):
        for y in range(0, h):
            for z in range(z0, 0):
                if min(x - x0, x1 - 1 - x, z - z0, -1 - z) > 0 and y < h - 1: continue   # paredes de un voxel
                u = x if z in (front, z0) else z * 3 + x                                # a lo largo de la pared
                if y < 4:                                                               # zócalo de chapa remachada
                    c = IRON if y else HULL
                    if y == 2 and u % 4 == 0: c = IRON_L
                    if M.noise(u, y, 1, 4.0) > 0.7: c = lerp(c, RUST, 0.6)
                elif y == h - 1 and min(x - x0, x1 - 1 - x, z - z0, -1 - z) > 0:     # techo de lona
                    c = ROOF_D if (x - x0) % 12 == 0 else lerp(ROOF, ROOF_D, 0.4 * M.noise(x, 0, z, 6.0))
                else:
                    c = _plank(M, u, y, h)
                M.put(x, y, z, P, c)
                if z == front and 4 <= y < h - 3: wall.add((x, y))
    occ = []
    def free(a, b): return all(b <= o0 or a >= o1 for o0, o1 in occ)
    rust = []                                                                       # (x, y, largo) regueros
    # cornisa: listón barnizado que vuela, con goterón
    for x in range(x0 - 1, x1 + 1):
        for y in (h - 3, h - 2):
            M.put(x, y, 0, P, VARNISH if y == h - 2 else lerp(VARNISH, WOOD_D, 0.5))
        M.put(x, h - 1, 0, P, WHITE_D)
        if x % 6 == 0: M.put(x, h - 4, 0, P, lerp(VARNISH, WOOD_D, 0.6))            # canes
    # puertas de cuarterones con pomo, bisagras, ojo de buey, tejadillo y farol
    for d in doors:
        occ.append((d - 10, d + 14))
        for x in range(d - 7, d + 7):
            for y in range(4, 32):
                if x in (d - 7, d + 6) or y == 31: M.put(x, y, front, P, VARNISH); continue   # marco
                if x in (d - 6, d + 5) or y in (4, 30) or y == 17: c = DOOR_D
                else:
                    c = DOOR
                    if x in (d - 5, d + 4) or y in (5, 16, 18, 29): c = lerp(DOOR, DOOR_D, 0.5)   # moldura de los cuarterones
                M.put(x, y, front, P, c)
                if c == DOOR and x not in (d - 4, d + 3) and y not in (6, 15, 19, 28): M.put(x, y, 0, P, lerp(DOOR, (0.44, 0.32, 0.20), 0.4))  # cuarterón en relieve
        for dx in range(-2, 2):                                                     # ojo de buey de la puerta
            for dy in range(-2, 2):
                if abs(dx + 0.5) + abs(dy + 0.5) < 2.6: M.put(d + dx, 24 + dy, 0, P, LIGHT, glow=1)
        for y in (8, 26):
            for x in (d - 6, d - 5, d - 4): M.put(x, y, 0, P, BRASS)                 # bisagras
        M.put(d + 3, 15, 0, P, BRASS); M.put(d + 3, 15, 1, P, BRASS); M.put(d + 3, 14, 0, P, BRASS)
        for x in range(d - 8, d + 8):                                               # umbral alto y tejadillo
            M.put(x, 4, 0, P, VARNISH)
            for z in range(0, 4): M.put(x, 33, z, P, WHITE_D if z < 3 else VARNISH)
        for z in range(0, 3): M.put(d - 8, 32 - z, z, P, VARNISH); M.put(d + 7, 32 - z, z, P, VARNISH)   # tornapuntas
        lx = d + 10                                                                 # farol de pared
        for y in range(24, 31):
            for x in (lx - 1, lx, lx + 1):
                cage = y in (24, 30) or x != lx
                M.put(x, y, 1, P, IRON if cage else LIGHT, glow=0 if cage else 1)
                if not cage: M.put(x, y, 0, P, LIGHT, glow=1)
        M.put(lx, 31, 0, P, IRON); M.put(lx, 31, 1, P, IRON)
        rust.append((lx, 23, 9))
    for lx in ladders: occ.append((lx - 5, lx + 5))
    # salvavidas con cabo y gancho
    for rx in (x0 + 24, x1 - 22):
        if not free(rx - 7, rx + 7): continue
        occ.append((rx - 7, rx + 7))
        cy = h - 22
        for dx in range(-7, 8):
            for dy in range(-7, 8):
                r = math.hypot(dx, dy)
                if not 3.4 <= r <= 6.6: continue
                a = math.degrees(math.atan2(dy, dx)) % 360
                c = RING_R if (a // 45) % 2 else WHITE
                if any(abs(a - q) < 7 for q in (45, 135, 225, 315)): c = ROPE           # cabo de agarre
                M.put(rx + dx, cy + dy, 0, P, c)
                if 4.2 <= r <= 5.8: M.put(rx + dx, cy + dy, 1, P, lerp(c, (1, 1, 1), 0.1))
        for y in range(cy + 6, cy + 10): M.put(rx, y, 0, P, IRON)                      # gancho
        M.put(rx, cy + 10, 1, P, IRON)
        rust.append((rx, cy - 7, 10))
    # cubos contra incendios en su repisa y hacha de incendios
    for bx in (x0 + 52, x0 + 100, x1 - 58, x1 - 84, x0 + 76):
        if not free(bx - 12, bx + 22): continue
        occ.append((bx - 12, bx + 22))
        for x in range(bx - 1, bx + 21):
            M.put(x, 26, 0, P, VARNISH); M.put(x, 26, 1, P, VARNISH); M.put(x, 25, 0, P, WOOD_D)
        for i in range(3):
            cx = bx + 2 + i * 7
            for y in range(17, 25):
                w = 2 if y < 19 else 3
                for x in range(cx - w + 1, cx + w):
                    for z in (0, 1, 2):
                        c = FIRE if y < 23 else IRON
                        if x == cx - w + 1 or y == 17: c = lerp(c, (0.0, 0.0, 0.0), 0.35)
                        M.put(x, y, z, P, c)
            for y in (25,): M.put(cx, y, 1, P, IRON)
            rust.append((cx, 16, 7))
        ax = bx - 7                                                                 # hacha
        for y in range(8, 30): M.put(ax, y, 0, P, VARNISH)
        for y in range(26, 31):
            for x in range(ax - 3, ax + 1): M.put(x, y, 0, P, FIRE if x > ax - 3 else STEEL)
        for x in (ax + 1, ax - 1):
            for y in (12, 22): M.put(x, y, 0, P, IRON)
        break                                                                       # una sola repisa
    # una ventana de cuarterones con cortina y alféizar
    for wx in (x1 - 40, x0 + 72, 0):
        if not free(wx - 10, wx + 10): continue
        occ.append((wx - 10, wx + 10))
        lit = True
        for x in range(wx - 8, wx + 8):
            for y in range(18, 36):
                fr = x in (wx - 8, wx + 7) or y in (18, 35)
                mull = x in (wx - 1, wx) or y == 27
                if fr: M.put(x, y, 0, P, VARNISH)
                elif mull: M.put(x, y, front, P, WOOD_D); M.put(x, y, 0, P, VARNISH)
                else:
                    curtain = x < wx - 3 and y > 21
                    M.put(x, y, front, P, (0.46, 0.12, 0.10) if curtain else LIGHT, glow=0 if curtain else 1)
        for x in range(wx - 9, wx + 9):                                             # alféizar
            M.put(x, 17, 0, P, VARNISH); M.put(x, 17, 1, P, VARNISH); M.put(x, 16, 0, P, WOOD_D)
        rust.append((wx - 6, 15, 8)); rust.append((wx + 5, 15, 6))
        break
    # montantes con pernos (donde no estorban)
    for sx in range(x0 + 32, x1 - 8, 32):
        if not free(sx - 1, sx + 2): continue
        for y in range(4, h - 3):
            M.put(sx, y, 0, P, lerp(WHITE, WHITE_D, 0.5)); M.put(sx + 1, y, front, P, WHITE_D)
        for y in (7, h - 7): M.put(sx, y, 1, P, IRON_L); rust.append((sx, y - 1, 6))
    # portillos de latón con pernos y reflejo
    i = 0
    for px in range(x0 + 10, x1 - 8, 15):
        if not free(px - 5, px + 5): continue
        occ.append((px - 5, px + 5))
        lit = i % lit_every == 1; i += 1
        py = h - 18
        for dx in range(-4, 5):
            for dy in range(-4, 5):
                r = math.hypot(dx, dy)
                if r > 4.4: continue
                if r > 2.6:
                    c = BRASS if r < 3.6 else lerp(BRASS, (0.30, 0.22, 0.10), 0.6)
                    if (dx, dy) in ((3, 3), (-3, 3), (3, -3), (-3, -3)): c = IRON
                    M.put(px + dx, py + dy, 0, P, c)
                    if r < 3.6: M.put(px + dx, py + dy, front, P, c)
                else:
                    if lit: M.put(px + dx, py + dy, front, P, LIGHT, glow=1)
                    else: M.put(px + dx, py + dy, front, P, (0.30, 0.34, 0.38) if (dx, dy) in ((-1, 1), (-2, 1), (-1, 2)) else GLASS)
        rust.append((px + 1, py - 5, 9 + (px % 5)))
    # tubería de vapor con abrazaderas y bajante
    ty = h - 7
    for x in range(x0, x1):
        for y in (ty, ty + 1):
            if (x, y) not in wall or any(abs(x - lx) < 5 for lx in ladders): continue
            M.put(x, y, 0, P, IRON_L if y == ty + 1 else IRON)
        if x % 16 == 0 and (x, ty) in wall and not any(abs(x - lx) < 5 for lx in ladders):
            M.put(x, ty + 2, 0, P, STEEL); M.put(x, ty - 1, 0, P, STEEL); M.put(x, ty, 1, P, STEEL); M.put(x, ty + 1, 1, P, STEEL)
            rust.append((x, ty - 2, 8))
    dpx = x1 - 4
    for y in range(4, h - 2):                                                       # bajante
        M.put(dpx, y, 0, P, IRON); M.put(dpx + 1, y, 0, P, IRON_L if y % 10 else STEEL)
    rust.append((dpx, 8, 6))
    # regueros de óxido
    for (rx, ry, ln) in rust:
        for k in range(ln):
            y = ry - k
            for xx in (rx, rx + (1 if M.hsh(rx, ry, k) > 0.7 else 0)):
                v = M.V.get((xx, y, front))
                if v is None or (xx, y) not in wall: continue
                if v[1] in (LIGHT, GLASS, BRASS): continue
                v[1] = lerp(v[1], RUST, 0.65 * (1 - k / ln) ** 0.7)
    # techo: baranda de candeleros con dos pasamanos, ventiladores, claraboya, cabo y pañol
    for x in range(x0, x1):
        for z in (front, z0):
            if x % 10 == 0:
                for y in range(h, h + 8): M.put(x, y, z, P, WHITE_D if y < h + 7 else BRASS)
            M.put(x, h + 7, z, P, WHITE); M.put(x, h + 4, z, P, WHITE_D)
    for vx in ((x0 + 18, x1 - 30) if roof_props else (x0 + 18, x1 - 14)):            # ventiladores de cuello de cisne
        cz = -20
        for y in range(h, h + 12):
            for x in range(vx - 3, vx + 3):
                for z in range(cz - 3, cz + 3):
                    if (x - vx + 0.5) ** 2 + (z - cz + 0.5) ** 2 > 8.5: continue
                    M.put(x, y, z, P, WHITE if y % 6 else WHITE_D)
        for y in range(h + 10, h + 16):
            for x in range(vx - 4, vx + 4):
                for z in range(cz - 4, cz + 5):
                    if (x - vx + 0.5) ** 2 + (y - h - 13) ** 2 > 14: continue
                    inner = z >= cz + 3 and (x - vx + 0.5) ** 2 + (y - h - 13) ** 2 < 6
                    M.put(x, y, z, P, RED if inner else WHITE)
    if not roof_props: return                                                       # el puente lleva la timonera encima
    sx0 = -8 if x0 < 0 < x1 else x0 + 70                                            # claraboya
    for x in range(sx0 - 10, sx0 + 10):
        for z in range(-26, -10):
            for y in range(h, h + 5):
                edge = x in (sx0 - 10, sx0 + 9) or z in (-26, -11) or y < h + 2
                if not edge and y < h + 4: continue
                if y == h + 4 and not edge:
                    c = VARNISH if (x - sx0) % 5 == 0 else (LIGHT if (x + z) % 3 else GLASS)
                    M.put(x, y, z, P, c, glow=1 if c == LIGHT else 0)
                else: M.put(x, y, z, P, VARNISH if y == h + 4 else WHITE_D)
    rcx, rcz = x1 - 52, -14                                                         # rollo de cabo
    for a in range(0, 360, 5):
        for r in (3, 4, 5):
            for y in (h, h + 1):
                M.put(rcx + int(round(r * math.cos(math.radians(a)))), y, rcz + int(round(r * math.sin(math.radians(a)))),
                      P, ROPE if (a // 20 + r + y) % 3 else ROPE_D)
    for x in range(x0 + 40, x0 + 56):                                               # pañol de madera con flejes
        for z in range(-26, -14):
            for y in range(h, h + 8):
                if 0 < x - x0 - 40 < 15 and -26 < z < -15 and y < h + 7: continue
                c = WOOD if (y - h) % 3 else WOOD_D
                if x - x0 - 40 in (3, 12): c = IRON
                M.put(x, y, z, P, c)


def _escalerilla(M, x, y0, y1, z):
    """Escala de hierro con largueros, peldaños redondos y pletinas sujetas a la pared."""
    for y in range(y0, y1):
        for dx in (-3, 3):
            M.put(x + dx, y, z, P, IRON); M.put(x + dx, y, z + 1, P, IRON_L if y % 2 else IRON)
        if y % 4 == 2:
            for dx in range(-2, 3): M.put(x + dx, y, z, P, STEEL if dx else IRON_L)
        if y % 16 == 8:
            for dx in (-3, 3): M.put(x + dx, y, z - 1, P, IRON)
    for dx in (-3, 3):                                                              # asideros que suben por encima
        for y in range(y1, y1 + 6): M.put(x + dx, y, z, P, IRON)
        M.put(x + dx, y1 + 6, z - 1, P, IRON)


def caseta():
    """Tramo de superestructura sin puente: caseta con puerta, portillos, ventana, salvavidas, cubos
    contra incendios, hacha, tubería, escala y, en el techo, ventiladores, claraboya, cabo y pañol
    (rehecha con mucho más detalle en la revisión de arte del 13-10-2026)."""
    M = Model(S=1, seed=110)
    _caseta(M, -WIDTH, WIDTH, -DEPTH, WALL_H, lit_every=4, doors=(-40,), ladders=(40,))
    _escalerilla(M, 40, 0, WALL_H + 2, 0)
    return M, {P: [0, 0, 0]}


def puente():
    """El puente del Emma: caseta abajo y, encima, la timonera con ventanales encendidos y la
    rueda del timón a contraluz, alerones con baranda, chimenea con banda roja y palo."""
    M = Model(S=1, seed=109)
    _caseta(M, -WIDTH, WIDTH, -DEPTH, WALL_H, lit_every=3, doors=(-56, 56), ladders=(-76,), roof_props=False)
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
    # palo con verga y jarcia: arranca del techo de la caseta, sobre su carlinga, y se afina hacia
    # arriba; obenques y estay bajan a cadenotes en los bordes del techo; fanal y tope.
    mx, mz, base = 60, -18, WALL_H
    top = h1 + 104
    for x in range(mx - 4, mx + 5):                                             # carlinga: base de madera con pernos
        for z in range(mz - 4, mz + 5):
            for y in range(base, base + 3):
                M.put(x, y, z, P, IRON if (abs(x - mx) == 4 and abs(z - mz) == 4) else (WOOD_D if y < base + 2 else WOOD))
    for y in range(base + 3, top):
        r = 2.2 - 1.2 * (y - base) / (top - base)                               # se afina
        for x in range(mx - 3, mx + 4):
            for z in range(mz - 3, mz + 4):
                if (x - mx) ** 2 + (z - mz) ** 2 > r * r + 0.3: continue
                c = WOOD if (x + z + y // 6) % 3 else lerp(WOOD, WOOD_D, 0.5)  # veta
                if y in (base + 30, base + 31, h1 + 40, h1 + 41): c = IRON          # zunchos
                M.put(x, y, z, P, c)
    for x in range(mx - 3, mx + 4):                                             # tope
        for z in range(mz - 1, mz + 2): M.put(x, top, z, P, WOOD_D)
    M.put(mx, top + 1, mz, P, WOOD_D); M.put(mx, top + 2, mz, P, BRASS)
    yy = h1 + 86                                                                # verga con sus estribos
    for x in range(mx - 26, mx + 27):
        r = 1 if abs(x - mx) < 18 else 0
        for dy in range(0, r + 1): M.put(x, yy + dy, mz + 1, P, WOOD_D if abs(x - mx) > 22 else WOOD)
        if x % 7 == 0: M.put(x, yy - 1, mz + 1, P, ROPE_D)
    for x in range(mx - 4, mx + 5): M.put(x, yy - 2, mz + 1, P, IRON)          # racamento
    # obenques: de lo alto del palo a cadenotes en los bordes del techo
    anchors = [(mx - 26, -3), (mx + 26, -3), (mx - 26, -DEPTH + 2), (mx + 26, -DEPTH + 2)]
    for ax, az in anchors:
        sx, sy, sz = mx + (1 if ax > mx else -1), h1 + 80, mz
        n = 200
        for k in range(n + 1):
            t = k / n
            x = sx + (ax - sx) * t; y = sy + (base + 1 - sy) * t; z = sz + (az - sz) * t
            M.put(int(round(x)), int(round(y)), int(round(z)), P, ROPE_D)
        for y in range(base, base + 3): M.put(ax, y, az, P, IRON)            # cadenote
    for k in range(0, 240):                                                     # estay a proa (hacia el puente)
        t = k / 239
        M.put(int(round(mx - (mx - 30) * t)), int(round(h1 + 96 - (h1 + 96 - h1 - 2) * t)), mz, P, ROPE_D)
    for x in range(mx - 3, mx + 4):                                             # fanal encendido con su jaula
        for y in range(h1 + 58, h1 + 67):
            for z in (mz + 3, mz + 4):
                cage = x in (mx - 3, mx + 3) or y in (h1 + 58, h1 + 66)
                M.put(x, y, z, P, IRON if cage else LIGHT, glow=0 if cage else 1)
    for y in range(h1 + 66, h1 + 70): M.put(mx, y, mz + 3, P, IRON)
    return M, {P: [0, 0, 0]}


PIECES = {'borda': borda, 'puente': puente, 'caseta': caseta, 'casco': casco, 'bolardo': bolardo, 'grua': grua, 'fardos': fardos, 'rollo': rollo,
          'linterna': linterna, 'bote': bote, 'barca': barca, 'barca_2': lambda: barca(2), 'barca_3': lambda: barca(3)}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/alr_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.8, specular=0.3, no_bottom=True)
        print('alr_%s: %d voxels' % (name, n))
