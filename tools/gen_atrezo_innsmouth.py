"""Atrezo de Newburyport y la carretera a Innsmouth (hito 6.1). Una parte "body", origen en el
centro de la base, como gen_atrezo_expedicion.py.

  casa       casa de tablas de dos aguas, ventanas tapiadas, porche y chimenea (16 voxels/m:
             es pieza de borde y grande; a 32 tendría ~200.000 voxels)
  autobus    el autobús viejo de Joe Sargent, verde grisáceo desvaído y con óxido (32/m)
  poste      poste de telégrafo con travesaño y aisladores de vidrio (32/m)
  valla      tramo de valla de estacas con alguna rota o caída (32/m)
  barril     barril de arenques (32/m)
  redes      redes de pesca tendidas entre dos palos (32/m)
  barca      bote de remos volcado (32/m)
  farola     farola de gas de hierro con la luz en el pivote "light" (48/m)
  juncos     mata de juncos de la marisma (32/m)
Hito 6.2 (las calles y el templo de la Orden):
  fachada    casa georgiana de ladrillo en ruinas, tejado hundido y ventanas rotas (16/m)
  templo     el antiguo templo masónico de la Orden de Dagon: piedra, columnas, frontón con el
             símbolo de la Orden y la puerta entreabierta (16/m)
  escombros  montón de ladrillos y vigas (32/m)
  fuente     fuente seca de la plaza con un pez de bronce (32/m)
  carretilla carretilla de pescado (32/m)
  cajas      cajas de pescado apiladas (32/m)
  nasa       nasa de langostas (32/m)
  pilote     pilote de muelle con cabo (32/m)
  coche      coche abandonado de los años 20 (32/m)

Escribe models/inn_<pieza>.json. Uso: python tools/gen_atrezo_innsmouth.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
BOARD = (0.50, 0.49, 0.45); BOARD_D = (0.38, 0.37, 0.34); BOARD_G = (0.30, 0.34, 0.30)   # tablas grises, verdín
TRIM = (0.62, 0.60, 0.55)
ROOF = (0.20, 0.21, 0.22); ROOF_D = (0.15, 0.16, 0.17); MOSS = (0.24, 0.30, 0.18)
PLANK = (0.42, 0.33, 0.24); PLANK_D = (0.30, 0.23, 0.17)                       # tablones de tapiar
BRICK = (0.42, 0.24, 0.19); BRICK_D = (0.32, 0.18, 0.14)
DARK = (0.06, 0.06, 0.07)
WOOD = (0.36, 0.28, 0.20); WOOD_D = (0.26, 0.20, 0.15)
IRON = (0.16, 0.17, 0.18); IRON_L = (0.30, 0.31, 0.32)
RUST = (0.42, 0.24, 0.13)
BUS = (0.38, 0.44, 0.38); BUS_D = (0.28, 0.33, 0.28)
GLASS = (0.22, 0.28, 0.30); TIRE = (0.08, 0.08, 0.08)
NET = (0.45, 0.42, 0.34); FLOAT = (0.62, 0.34, 0.22)
REED = (0.42, 0.42, 0.24); REED_D = (0.30, 0.32, 0.18)
LIGHT = (1.0, 0.80, 0.52)


def box(M, x0, x1, y0, y1, z0, z1, col):
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                M.put(x, y, z, P, col(x, y, z) if callable(col) else col)


# ---------------- casa ----------------

def casa(variant=1):
    """Casa de Innsmouth (rehecha el 09-10-2026 siguiendo tools/replicate/ref_casa.png), 16/m,
    7 x 5,5 m, hueca. Dos plantas de tablas solapadas con tablas que faltan, pintura que se
    pela y humedad abajo; zócalo de piedra; moldura entre plantas y esquineras; ventanas con
    marco, alféizar y cada una en su estado (tapiada en aspa, oscura, rota o, una, con luz);
    tejado de tejas con verdín, cumbrera algo hundida, aleros con canalón y un hastial
    delantero con su ventana; porche con escalones y baranda rota; chimenea con remate.
    Variante 1: gris; 2: pintura verde azulada desvaída."""
    M = Model(S=1, seed=60 + variant)
    HX, HZ, WALL, RIDGE = 56, 44, 52, 84
    FLOOR2 = 28                                               # moldura entre plantas
    PAINT = BOARD if variant == 1 else (0.40, 0.48, 0.47)
    PAINT_D = BOARD_D if variant == 1 else (0.30, 0.37, 0.36)
    STONE_B = (0.40, 0.39, 0.36); STONE_BD = (0.30, 0.29, 0.27)
    GUTTER = (0.30, 0.42, 0.36)                               # cobre con pátina

    def siding(x, y, z):
        if y < 4: return lerp(STONE_BD, STONE_B, M.noise(x, y, z, 3.0))           # zócalo
        if y % 3 == 0: return lerp(PAINT_D, DARK, 0.3)                           # sombra de la tabla
        row = y // 3
        u = x if abs(z) >= HZ - 1 else z
        seg = (u + 7 * row) // 22
        if M.hsh(row, seg, 11 + variant) < 0.035: return DARK                     # tabla que falta
        c = lerp(PAINT, PAINT_D, 0.5 * M.hsh(row, seg, 3))
        if M.noise(x, y, z, 7.0) > 0.66: c = lerp(c, (0.62, 0.60, 0.55), 0.5)     # pintura pelada
        if y < 16: c = lerp(c, BOARD_G, 0.6 * M.noise(x, y, z, 9.0))             # humedad
        return c

    for y in range(0, WALL):                                  # paredes
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                if min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) > 1: continue
                M.put(x, y, z, P, siding(x, y, z))
    for y in range(4, WALL):                                  # esquineras
        for x in (-HX, -HX + 1, HX - 2, HX - 1):
            for z in (-HZ, HZ - 1):
                M.put(x, y, z, P, TRIM)
        for z in (-HZ, -HZ + 1, HZ - 2, HZ - 1):
            for x in (-HX, HX - 1): M.put(x, y, z, P, TRIM)
    for x in range(-HX, HX):                                  # moldura entre plantas
        for y in (FLOOR2, FLOOR2 + 1):
            M.put(x, y, HZ, P, TRIM); M.put(x, y, -HZ - 1, P, TRIM)
    for z in range(-HZ, HZ):
        for y in (FLOOR2, FLOOR2 + 1):
            M.put(HX, y, z, P, TRIM); M.put(-HX - 1, y, z, P, TRIM)

    def roof_y(x, z):                                         # faldones a lo largo de x, cumbrera hundida
        sag = 3 * (1 - (x / HX) ** 2)
        return RIDGE - sag - (abs(z + 0.5) / (HZ + 5)) * (RIDGE - WALL + 5)

    def shingle(x, y, z):
        row = y // 2
        c = ROOF if M.hsh(row, (x + 3 * (row % 2)) // 4, 5) < 0.6 else ROOF_D
        if M.noise(x, y, z, 8.0) > 0.66: c = lerp(c, MOSS, 0.85)
        return c

    for z in range(-HZ - 5, HZ + 5):                          # tejado con alero
        for x in range(-HX - 4, HX + 4):
            y = int(roof_y(x, z))
            M.put(x, y, z, P, shingle(x, y, z)); M.put(x, y - 1, z, P, ROOF_D)
            if abs(z + 0.5) > HZ + 3: M.put(x, y - 1, z, P, TRIM)                 # imposta
    for x in range(-HX - 4, HX + 4):                          # canalón de cobre a lo largo del alero delantero
        y = int(roof_y(x, HZ + 4)) - 1
        M.put(x, y, HZ + 5, P, GUTTER); M.put(x, y - 1, HZ + 5, P, GUTTER)
    for y in range(4, int(roof_y(HX - 1, HZ + 4))):           # bajante
        M.put(HX + 2, y, HZ + 5, P, GUTTER)
    for x in (-HX, HX - 1):                                   # hastiales
        for z in range(-HZ, HZ):
            top = int(roof_y(x, z)) - 1
            for y in range(WALL, top): M.put(x, y, z, P, siding(x, y, z))

    # hastial delantero (sobre el porche): tejadillo a dos aguas con la cumbrera hacia +z
    gx, gw, gtop = 6, 22, RIDGE - 4
    for z in range(0, HZ + 6):
        for x in range(gx - gw - 3, gx + gw + 3):
            y = int(gtop - abs(x - gx + 0.5) * (gtop - WALL + 3) / (gw + 3))
            if y > roof_y(x, z) - 1:
                M.put(x, y, z, P, shingle(x, y, z)); M.put(x, y - 1, z, P, ROOF_D)
                if z >= HZ + 4: M.put(x, y - 1, z, P, TRIM)
    for x in range(gx - gw, gx + gw):                         # su frontón de tablas
        top = int(gtop - abs(x - gx + 0.5) * (gtop - WALL + 3) / (gw + 3)) - 1
        for y in range(WALL - 2, top):
            M.put(x, y, HZ, P, siding(x, y, HZ)); M.put(x, y, HZ - 1, P, siding(x, y, HZ))

    lit_done = [False]

    def window(cx, cy, face, w=10, h=14, state=None):
        """Ventana con marco, travesaño y alféizar; estado: tapiada, oscura, rota o con luz."""
        if state is None:
            r = M.hsh(cx, cy, 31 + variant + (7 if face == 'x' else 0))
            state = 'tapiada' if r < 0.4 else ('rota' if r < 0.6 else ('luz' if r < 0.72 and not lit_done[0] else 'oscura'))
            if state == 'luz': lit_done[0] = True

        def put(a, b, col, glow=0, out=0):
            if face == 'z': M.put(cx + a, cy + b, HZ + out, P, col, glow=glow)
            else: M.put(HX + out, cy + b, cx + a, P, col, glow=glow)
        hw, hh = w // 2, h // 2
        for a in range(-hw - 1, hw + 1):
            for b in range(-hh - 1, hh + 1):
                frame = a in (-hw - 1, hw) or b in (-hh - 1, hh)
                if frame: put(a, b, TRIM); continue
                sash = a == 0 or b == 0
                if state == 'tapiada':
                    col = PLANK if (abs(a * 1.3 - b) < 1.3 or abs(a * 1.3 + b) < 1.3) else DARK
                    if b in (-hh + 2, hh - 3): col = PLANK_D
                    put(a, b, col, out=1 if col != DARK else 0)
                elif state == 'luz':
                    put(a, b, TRIM if sash else LIGHT, glow=0 if sash else 1)
                elif state == 'rota':
                    put(a, b, TRIM if sash else (GLASS if M.hsh(a, b, cx) < 0.3 else DARK))
                else:
                    put(a, b, TRIM if sash else (GLASS if (a + b) % 5 == 0 else DARK))
        for a in range(-hw - 2, hw + 2): put(a, -hh - 2, TRIM, out=1)              # alféizar
        for a in range(-hw - 2, hw + 2): put(a, hh + 1, TRIM, out=1)               # dintel
    for cx in (-38, -20):                                     # fachada: planta baja y alta
        window(cx, 16, 'z')
    for cx in (-38, -16, 30, 44):
        if abs(cx - gx) > gw - 6 or cx in (-16,): window(cx, 40, 'z')
    window(gx, 44, 'z', w=12, h=12)                            # ventana del hastial delantero
    window(gx, 62, 'z', w=6, h=6, state='oscura')              # ojo de buey del desván
    for cz in (-22, 18):                                      # costado este, dos plantas
        window(cz, 16, 'x'); window(cz, 40, 'x')
    for cx in (-30, 22):                                      # trasera y oeste (casi no se ven)
        for cy in (16, 40):
            for a in range(-5, 5):
                for b in range(-7, 7): M.put(cx + a, cy + b, -HZ - 1, P, DARK if a and b else TRIM)
    # puerta con marco y montante de cristal
    for x in range(2, 16):
        for y in range(4, 40):
            edge = x in (2, 15) or y == 39
            col = TRIM if edge else (DARK if y > 33 else (WOOD if (x - 2) % 6 else WOOD_D))
            M.put(x, y, HZ, P, col)
    M.put(13, 20, HZ + 1, P, IRON_L)
    # porche: tarima, escalones, pies derechos, baranda rota y tejadillo
    PZ = HZ + 16
    for x in range(-6, 24):
        for z in range(HZ, PZ):
            M.put(x, 4, z, P, PLANK if x % 3 else PLANK_D); M.put(x, 3, z, P, PLANK_D)
            for y in range(0, 3):
                if x in (-6, 23) or z == PZ - 1: M.put(x, y, z, P, STONE_BD)
    for i, z in enumerate(range(PZ, PZ + 6, 2)):              # escalones
        for x in range(2, 16):
            for zz in (z, z + 1):
                M.put(x, 3 - i, zz, P, PLANK if x % 3 else PLANK_D)
    for x in (-6, 23):                                        # pies derechos
        for y in range(5, 44):
            M.put(x, y, PZ - 1, P, TRIM); M.put(x, y, HZ, P, TRIM)
    for x in range(-6, 24):                                   # baranda (rota en un tramo)
        if 2 <= x < 16: continue
        if 17 <= x < 21: continue
        M.put(x, 16, PZ - 1, P, TRIM)
        if x % 3 == 0:
            for y in range(5, 16): M.put(x, y, PZ - 1, P, TRIM)
    for x in (18, 19):                                        # un balaústre caído
        M.put(x, 5, PZ + 1, P, TRIM)
    for x in range(-8, 26):                                   # tejadillo del porche
        for z in range(HZ, PZ + 2):
            y = 44 + (PZ + 2 - z) // 5
            M.put(x, y, z, P, shingle(x, y, z))
            if z == PZ + 1: M.put(x, y - 1, z, P, TRIM)
    # chimenea con remate
    for y in range(RIDGE - 20, RIDGE + 12):
        for x in range(-36, -26):
            for z in range(-8, 0):
                cap = y >= RIDGE + 9
                xx0, xx1, zz0, zz1 = (-37, -25, -9, 1) if cap else (-36, -26, -8, 0)
                if min(x - xx0, xx1 - 1 - x, z - zz0, zz1 - 1 - z) > 0 and y < RIDGE + 11: continue
                M.put(x, y, z, P, (0.48, 0.44, 0.40) if cap else (BRICK if (y // 2 + x) % 4 else BRICK_D))
        if y >= RIDGE + 9:
            for x in (-37, -26):
                for z in range(-9, 1): M.put(x, y, z, P, (0.48, 0.44, 0.40))
            for z in (-9, 0):
                for x in range(-37, -25): M.put(x, y, z, P, (0.48, 0.44, 0.40))
    return M, {P: [0, 0, 0]}


# ---------------- autobús de Joe Sargent ----------------

def autobus():
    """El autobús de Joe Sargent (rehecho el 09-10-2026 siguiendo tools/replicate/ref_autobus.png),
    32/m, 5,25 x 2,1 m: carrocería de techo redondeado en verde desvaído con desconchones de
    óxido y barro abajo, franja crema bajo las ventanillas enmarcadas, puerta; capó largo con
    guardabarros curvos sobre las ruedas delanteras, rejilla redonda cromada, faros redondos y
    parachoques; ruedas de radios, estribo y baca con una maleta atada. Delante, +x."""
    M = Model(S=2, seed=62)
    L, W = 84, 34                                           # media eslora y anchura total
    HW = W // 2
    CREAM = (0.66, 0.62, 0.50); CHROME = (0.62, 0.62, 0.60); SPOKE = (0.62, 0.52, 0.30)
    MUD = (0.30, 0.25, 0.18); CASE = (0.50, 0.30, 0.16); CASE_D = (0.34, 0.20, 0.11)
    BACK = -L; FRONT_BOX = L - 30                           # la caja acaba donde empieza el capó
    ROOF0, ROOF1 = 66, 76                                   # el techo se curva entre estas alturas

    def paint(x, y, z):
        c = BUS if (y // 5) % 4 else lerp(BUS, BUS_D, 0.5)
        if M.noise(x, y, z, 5.0) > 0.68: c = RUST                              # desconchones
        if y < 26: c = lerp(c, MUD, 0.6 * (1 - (y - 14) / 12.0) + 0.2 * M.noise(x, y, z, 3.0))
        return c

    def half_w(y):                                          # sección: el techo se redondea
        if y <= ROOF0: return HW
        t = (y - ROOF0) / float(ROOF1 - ROOF0)
        return int(HW * (1 - t * t) ** 0.5)

    for x in range(BACK, FRONT_BOX):                        # caja
        back_round = max(0.0, 1 - (x - BACK) / 6.0)         # trasera algo redondeada
        for y in range(16, ROOF1 + 1):
            hw = half_w(y) - int(3 * back_round * (y > 60))
            if hw <= 0: continue
            for z in range(-hw, hw):
                interior = min(x - BACK, FRONT_BOX - 1 - x, z + hw, hw - 1 - z) > 1
                top = y == ROOF1 or z in (-hw, hw - 1)
                if interior and not top: continue
                side = z in (-HW, HW - 1)
                c = paint(x, y, z)
                if 40 <= y <= 42: c = CREAM                                       # franja crema
                if side and 46 <= y < 62 and x < FRONT_BOX - 6:
                    k = (x - BACK - 4) % 16
                    if 2 <= k < 14:
                        c = GLASS if not (M.hsh(x // 16, z, 9) < 0.25 and k in (5, 9) and y > 54) else DARK   # cristal rajado
                    elif k in (0, 1, 14, 15): c = CREAM                              # marcos
                if side and z == HW - 1 and 20 <= x - BACK + 0 and FRONT_BOX - 22 <= x < FRONT_BOX - 10 and 18 <= y < 62:
                    c = lerp(BUS_D, DARK, 0.3) if x in (FRONT_BOX - 22, FRONT_BOX - 11) or y == 61 else (GLASS if y > 46 else BUS_D)  # puerta
                M.put(x, y, z, P, c)
    for y in range(44, 64):                                 # parabrisas en el frente de la caja
        for z in range(-HW + 2, HW - 2):
            M.put(FRONT_BOX, y, z, P, CREAM if z in (-1, 0) or y in (44, 63) else GLASS)
    for x in range(BACK + 6, FRONT_BOX - 4):                # baca y maleta
        for z in (-12, 11):
            M.put(x, ROOF1 + 3, z, P, IRON_L)
        if (x - BACK) % 8 == 0:
            for z in range(-12, 12): M.put(x, ROOF1 + 3, z, P, IRON_L)
            for y in (ROOF1 + 1, ROOF1 + 2):
                M.put(x, y, -12, P, IRON); M.put(x, y, 11, P, IRON)
    for x in range(-20, 6):
        for y in range(ROOF1 + 4, ROOF1 + 13):
            for z in range(-9, 9):
                strap = x in (-14, -2)
                M.put(x, y, z, P, CASE_D if strap or y == ROOF1 + 12 or z in (-9, 8) else CASE)
    # capó, rejilla redonda, faros y parachoques
    for x in range(FRONT_BOX, L):
        t = (x - FRONT_BOX) / float(L - FRONT_BOX)
        top = int(46 - 4 * t * t)
        for y in range(20, top + 1):
            hw = 12 if y < top - 2 else 10
            for z in range(-hw, hw):
                if min(z + hw, hw - 1 - z) > 0 and y < top: continue
                c = paint(x, y, z)
                if y == top and abs(z) < 2: c = CHROME                            # bisagra del capó
                if z in (-hw, hw - 1) and 30 <= y < 40 and (x - FRONT_BOX) % 4 == 0: c = BUS_D   # rejillas laterales
                M.put(x, y, z, P, c)
    for y in range(20, 46):                                 # rejilla del radiador, redondeada arriba
        for z in range(-11, 11):
            if y > 38 and (y - 38) ** 2 + (z + 0.5) ** 2 * 0.5 > 64: continue
            edge = z in (-11, 10) or y == 20 or (y > 38 and (y - 38) ** 2 + (z + 0.5) ** 2 * 0.5 > 40)
            M.put(L, y, z, P, CHROME if edge else (IRON if z % 2 else IRON_L))
    for zc in (-14, 13):                                    # faros redondos sobre los guardabarros
        for y in range(36, 44):
            for z in range(zc - 4, zc + 4):
                d = (y - 39.5) ** 2 + (z - zc + 0.5) ** 2
                if d > 16: continue
                M.put(L - 2, y, z, P, CHROME if d > 9 else (0.80, 0.76, 0.58), glow=0)
                M.put(L - 3, y, z, P, CHROME)
    for z in range(-HW - 1, HW + 1):                        # parachoques
        M.put(L + 2, 16, z, P, CHROME); M.put(L + 2, 17, z, P, CHROME)
        if z in (-12, 11):
            M.put(L + 1, 16, z, P, IRON)
    # guardabarros curvos y estribo
    for cx in (L - 18, BACK + 22):
        for s in (-1, 1):
            zf = s * (HW + 1) - (1 if s > 0 else 0)
            for a in range(0, 181, 4):
                ang = math.radians(a)
                x = int(round(cx + 17 * math.cos(ang))); y = int(round(13 + 17 * math.sin(ang)))
                for dz in range(-5, 1):
                    M.put(x, y, zf - s * dz, P, paint(x, y, zf))
    for x in range(BACK + 40, L - 36):
        for s in (-1, 1):
            for dz in range(0, 4): M.put(x, 16, s * (HW + dz) - (1 if s > 0 else 0), P, IRON)
    for x in range(BACK, L):                                # chasis
        for z in range(-HW + 2, HW - 2): M.put(x, 14, z, P, IRON)
    # ruedas de radios
    for cx in (L - 18, BACK + 22):
        for s in (-1, 1):
            z0 = s * HW - (1 if s > 0 else 0)
            for a in range(-13, 14):
                for b in range(0, 27):
                    r = math.hypot(a, b - 13)
                    if r > 13: continue
                    ang = math.degrees(math.atan2(b - 13, a)) % 30
                    if r > 9.5: c = TIRE
                    elif r < 3: c = CHROME
                    elif ang < 6 or ang > 24: c = SPOKE
                    else: c = DARK
                    for dz in range(0, 4): M.put(cx + a, b, z0 + s * dz, P, c)
    return M, {P: [0, 0, 0]}


# ---------------- poste, valla, barril, redes, barca ----------------

def poste():
    """Poste de telégrafo de 6 m (32/m): madera gris agrietada, dos crucetas con tornapuntas,
    aisladores de vidrio verde en sus pernos, clavos de trepar y un aviso clavado."""
    M = Model(S=2, seed=63)
    GREY = (0.40, 0.38, 0.35); GREY_D = (0.28, 0.27, 0.25); INS = (0.36, 0.58, 0.50)
    for y in range(0, 192):
        for x in range(-3, 3):
            for z in range(-3, 3):
                if (x + 0.5) ** 2 + (z + 0.5) ** 2 > 9: continue
                c = lerp(GREY_D, GREY, M.noise(x, y * 0.3, z, 4.0))
                if (y * 7 + x * 13) % 41 == 0: c = DARK                          # grietas
                M.put(x, y, z, P, c)
    for arm_y in (176, 160):
        for x in range(-28, 28):
            for y in (arm_y, arm_y + 1, arm_y + 2):
                for z in (-1, 0): M.put(x, y, z, P, GREY if y > arm_y else GREY_D)
        for k in range(12):                                   # tornapuntas
            for s in (-1, 1): M.put(s * (3 + k), arm_y - 12 + k, 1, P, IRON)
        for x in (-25, -16, -8, 7, 15, 24):                    # pernos y aisladores
            M.put(x, arm_y + 3, 0, P, WOOD_D)
            for y in range(arm_y + 4, arm_y + 9):
                w = 2 if y < arm_y + 7 else 1
                for dx in range(-w + 1, w):
                    for dz in range(-w + 1, w): M.put(x + dx, y, dz, P, INS)
    for y in range(40, 150, 14):                              # clavos de trepar, alternos
        s = 1 if (y // 14) % 2 else -1
        for k in range(3, 7): M.put(s * k, y, 0, P, IRON_L)
    for x in range(-2, 4):                                    # aviso clavado
        for y in range(70, 80): M.put(x, y, 3, P, (0.70, 0.66, 0.54) if y < 78 else (0.52, 0.48, 0.38))
    return M, {P: [0, 0, 0]}


def valla():
    """3 m de valla de estacas (rehecha siguiendo tools/replicate/ref_valla.png): estacas
    puntiagudas de pintura blanca que se pela, alguna rota, torcida o que falta, dos travesaños,
    postes gruesos grises, un travesaño suelto en diagonal y matas al pie."""
    M = Model(S=2, seed=64)
    PAINT = (0.74, 0.72, 0.66); PAINT_D = (0.60, 0.58, 0.52); BARE = (0.46, 0.40, 0.32)
    POST = (0.40, 0.38, 0.35); WEED = (0.30, 0.38, 0.18); WEED_D = (0.22, 0.28, 0.14)

    def wood(x, y, z):
        if M.noise(x, y, z, 3.0) > 0.62: return BARE                    # pintura pelada
        return PAINT if (x + y) % 5 else PAINT_D
    for x in (-48, 44):                                                   # postes
        for y in range(0, 46):
            for dx in range(0, 4):
                for z in range(-1, 3): M.put(x + dx, y, z, P, lerp(POST, (0.30, 0.29, 0.27), M.noise(x, y, z, 5.0)))
    for x in range(-44, 44):                                              # travesaños
        for y in (12, 13, 30, 31): M.put(x, y, 0, P, wood(x, y, 0))
    for i, x0 in enumerate(range(-43, 42, 6)):
        r = M.hsh(i, 0, 1)
        if r < 0.1: continue                                               # falta
        h = 42 if r > 0.3 else int(16 + 16 * M.hsh(i, 1, 1))               # rota
        lean = 0.0 if M.hsh(i, 3, 3) > 0.25 else (M.hsh(i, 4, 4) - 0.5) * 0.5   # torcida
        for y in range(0, h):
            for w in range(0, 4):
                if h == 42 and y >= h - 4 and abs(w - 1.5) > (h - y) * 0.45: continue   # punta
                x = x0 + w + int(lean * y)
                M.put(x, y, 1, P, wood(x, y, 1))
                M.put(x, y, 2, P, wood(x, y, 2))
    for t in range(0, 60):                                                # travesaño suelto en diagonal
        x = -40 + t; y = 6 + int(t * 0.45)
        for z in (3, 4): M.put(x, y, z, P, wood(x, y, z))
    for k in range(10):                                                   # matas al pie
        cx, cz = M.rng.randint(-46, 44), M.rng.randint(-3, 6)
        for b in range(M.rng.randint(4, 10)):
            ang = M.rng.uniform(0, math.tau); r = M.rng.uniform(0, 2.5)
            x, z = int(cx + r * math.cos(ang)), int(cz + r * math.sin(ang))
            for y in range(0, M.rng.randint(3, 9)): M.put(x, y, z, P, WEED if y % 3 else WEED_D)
    return M, {P: [0, 0, 0]}


def barril():
    M = Model(S=2, seed=65)
    for y in range(0, 30):
        r = 9 + 1.4 * math.sin(y / 29 * math.pi)
        for x in range(-11, 11):
            for z in range(-11, 11):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r or (d < r - 2 and 1 < y < 29): continue
                c = IRON if y in (3, 4, 25, 26) else (WOOD if int(math.atan2(z, x) * 5) % 2 else WOOD_D)
                if y == 29: c = WOOD_D
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def redes():
    """Red de pesca tendida entre dos palos, con agujeros y corchos."""
    M = Model(S=2, seed=66)
    for x0 in (-44, 44):
        for y in range(0, 64):
            for x in (x0 - 1, x0):
                for z in (-1, 0): M.put(x, y, z, P, WOOD_D if y % 9 else WOOD)
    for x in range(-43, 44):
        sag = int(6 * math.cos(x / 44 * math.pi / 2))
        for y in range(10, 60 - sag):
            if (x % 4 == 0 or y % 4 == 0) and M.noise(x, y, 0, 7.0) < 0.7:
                M.put(x, y, 0, P, NET)
        if x % 8 == 0: M.put(x, 59 - sag, 1, P, FLOAT); M.put(x, 58 - sag, 1, P, FLOAT)
    return M, {P: [0, 0, 0]}


def barca():
    """Bote de remos volcado sobre la tierra: casco a lo largo de x, quilla arriba."""
    M = Model(S=2, seed=67)
    for x in range(-56, 56):
        t = abs(x) / 56
        half = 22 * math.sqrt(max(0.0, 1 - t ** 2.2))
        hgt = 20 - 4 * t
        for z in range(-int(half) - 1, int(half) + 1):
            u = abs(z + 0.5) / max(half, 1)
            if u > 1: continue
            y = int(hgt * math.sqrt(max(0.0, 1 - u * u)))
            c = (0.30, 0.38, 0.42) if (y // 3) % 2 else (0.24, 0.30, 0.34)   # pintura azul desconchada
            if M.noise(x, y, z, 5.0) > 0.66: c = WOOD
            for yy in range(max(0, y - 2), y + 1): M.put(x, yy, z, P, c)
        M.put(x, int(hgt) + 1, 0, P, WOOD_D)              # quilla
    for x in range(-10, 30):                              # un remo en el suelo
        M.put(x, 0, 28 + x // 12, P, WOOD); M.put(x, 0, 29 + x // 12, P, WOOD)
    return M, {P: [0, 0, 0]}


def farola():
    """Farola de gas: pie de hierro con basa, fuste estriado, cruceta y linterna de cuatro
    cristales con tejadillo. Pivote "light" en la llama."""
    M = Model(S=3, seed=68)
    H = 140                                               # 2,9 m
    for y in range(0, 10):
        w = 6 - y // 3
        for x in range(-w, w):
            for z in range(-w, w): M.put(x, y, z, P, IRON)
    for y in range(10, H):
        for x in range(-2, 2):
            for z in range(-2, 2):
                if abs(x + 0.5) + abs(z + 0.5) > 3: continue
                M.put(x, y, z, P, IRON_L if (x + z) % 2 and y % 2 else IRON)
    for x in range(-8, 8): M.put(x, H - 22, 0, P, IRON); M.put(x, H - 22, -1, P, IRON)   # cruceta
    LY = H + 10
    for y in range(H, H + 2):
        for x in range(-6, 6):
            for z in range(-6, 6): M.put(x, y, z, P, IRON)
    for y in range(H + 2, H + 20):
        w = 5 + (y - H - 2) // 6
        for x in range(-w, w):
            for z in range(-w, w):
                ex = x in (-w, w - 1); ez = z in (-w, w - 1)
                if not (ex or ez): continue
                M.put(x, y, z, P, IRON if (ex and ez) else LIGHT, glow=0 if (ex and ez) else 1)
    for y in range(H + 4, H + 14):
        for x in (-1, 0):
            for z in (-1, 0): M.put(x, y, z, P, (1.0, 0.70, 0.30), glow=1)
    for i, y in enumerate(range(H + 20, H + 27)):
        w = 9 - i
        for x in range(-w, w):
            for z in range(-w, w): M.put(x, y, z, P, IRON)
    return M, {P: [0, 0, 0], 'light': [0, LY, 0]}


def juncos():
    M = Model(S=2, seed=69)
    for i in range(46):
        a = M.rng.uniform(0, math.tau); r = M.rng.uniform(0, 14)
        x0, z0 = r * math.cos(a), r * math.sin(a)
        h = M.rng.randint(24, 52)
        lean = M.rng.uniform(-0.25, 0.25)
        for y in range(h):
            c = REED if y > h * 0.4 else REED_D
            if y > h - 6 and M.rng.random() < 0.5 and i % 4 == 0: c = (0.32, 0.22, 0.14)   # espadañas
            M.put(x0 + lean * y, y, z0, P, c)
    return M, {P: [0, 0, 0]}



# ---------------- hito 6.2 ----------------

STONE = (0.52, 0.51, 0.48); STONE_D = (0.40, 0.39, 0.37); STONE_L = (0.62, 0.61, 0.58)
GREEN = (0.20, 0.34, 0.30)
GOLD_OLD = (0.62, 0.52, 0.28)


def fachada():
    """Casa georgiana de ladrillo, de dos plantas, en ruinas: hueca, con un rincón del tejado
    hundido (falta la pared de arriba), ventanas de guillotina rotas y cornisa clara."""
    M = Model(S=1, seed=71)
    HX, HZ, H = 56, 40, 96                                  # 7 x 5 m, 6 m de alto
    for y in range(0, H):
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                if min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) > 1: continue
                if x > 10 and y > H - 30 + (x - 10) * 0.4 + 8 * M.noise(x, y, z, 6.0): continue   # derrumbe
                c = BRICK if (y // 2 + (x + z) // 4 + (y // 2) % 2 * 2) % 5 else BRICK_D
                if M.noise(x, y, z, 12.0) > 0.7: c = lerp(c, MOSS, 0.4)
                M.put(x, y, z, P, c)
    for x in range(-HX - 1, HX + 1):                        # cornisa e imposta
        for z in (HZ, HZ + 1):
            M.put(x, H - 4, z, P, STONE_L); M.put(x, 48, z, P, STONE_L)
    for cx in (-38, -14, 14, 38):                           # ventanas de guillotina, rotas
        for cy in (26, 70):
            if cy == 70 and cx > 14: continue
            for a in range(-6, 6):
                for b in range(-10, 10):
                    edge = a in (-6, 5) or b in (-10, 9) or b == 0
                    c = TRIM if edge else (DARK if M.hsh(a, b, cx) > 0.25 else GLASS)
                    M.put(cx + a, cy + b, HZ, P, c)
    for x in range(-6, 6):                                  # puerta con montante
        for y in range(0, 36):
            M.put(x, y, HZ, P, DARK if abs(x + 0.5) < 5 and y < 34 else STONE_L)
    for x in range(-HX - 2, 11):                            # lo que queda del tejado
        for z in range(-HZ - 2, HZ + 2):
            y = H + int((HZ - abs(z)) * 0.5)
            if x > 0 and M.hsh(x // 3, z // 3, 1) > 0.6: continue
            M.put(x, y, z, P, ROOF if (x // 4 + z // 3) % 2 else ROOF_D)
    return M, {P: [0, 0, 0]}


def templo():
    """Antiguo templo masónico de la Orden de Dagon: fachada clásica de piedra (14 m de ancho)
    con escalinata, cuatro columnas, frontón con el símbolo de la Orden (un pez en un círculo
    de olas, en oro deslustrado) y la puerta negra entreabierta. Verdín del salitre."""
    M = Model(S=1, seed=72)
    HX, D, H = 112, 28, 128
    for y in range(0, 8):                                   # escalinata
        for x in range(-HX + 20, HX - 20):
            zt = D + 8 + (8 - y) * 3
            for z in range(max(D, zt - 4), zt):                       # solo la huella de cada peldaño
                M.put(x, y, z, P, STONE if (y + z) % 3 else STONE_D)
    for y in range(8, H):                                   # muro de sillares
        for x in range(-HX, HX):
            for z in range(-D, D):
                if min(x + HX, HX - 1 - x, D - 1 - z) > 0 or z == -D: continue   # muro de 1, sin la trasera (no se ve)
                off = (y // 6 % 2) * 6
                c = STONE if (y // 6 + (x + off) // 12) % 2 else lerp(STONE, STONE_D, 0.4)
                if y % 6 == 0 or (x + off) % 12 == 0: c = STONE_D
                if M.noise(x, y, z, 10.0) > 0.66: c = lerp(c, GREEN, 0.45)
                M.put(x, y, z, P, c)
    for cx in (-66, -26, 26, 66):                           # columnas estriadas
        for y in range(8, H - 6):
            for x in range(cx - 5, cx + 5):
                for z in range(D, D + 10):
                    if not 3.5 < math.hypot(x - cx + 0.5, z - D - 5 + 0.5) <= 5: continue
                    c = STONE_L if int(math.atan2(z - D - 5, x - cx) * 4) % 2 else STONE
                    M.put(x, y, z, P, c)
        for y in range(H - 8, H - 4):                       # capiteles
            for x in range(cx - 7, cx + 7):
                for z in range(D - 1, D + 12): M.put(x, y, z, P, STONE_L)
    for y in range(H - 4, H + 4):                           # entablamento
        for x in range(-HX - 2, HX + 2):
            for z in range(D + 9, D + 13): M.put(x, y, z, P, STONE_L if y < H else STONE)
    for y in range(H + 4, H + 44):                          # frontón
        w = HX + 2 - (y - H - 4) * 3
        if w <= 0: break
        for x in range(-w, w):
            for z in range(D + 9, D + 12):
                M.put(x, y, z, P, STONE_L if abs(abs(x) - w) < 2 or y == H + 4 else STONE)
    cy = H + 18
    for a in range(0, 360, 3):                              # símbolo: círculo de olas
        t = math.radians(a)
        r = 11 + 1.5 * math.sin(t * 8)
        M.put(round(r * math.cos(t)), round(cy + r * math.sin(t)), D + 12, P, GOLD_OLD)
    for x in range(-6, 7):                                  # y el pez dentro
        h = int(3 * math.sqrt(max(0.0, 1 - (x / 7) ** 2)))
        for y in range(-h, h + 1): M.put(x, cy + y, D + 12, P, GOLD_OLD)
    for y in range(-3, 4): M.put(-8 - abs(y) // 2, cy + y, D + 12, P, GOLD_OLD)   # cola
    for x in range(-14, 14):                                # puerta en arco, una hoja entreabierta
        for y in range(8, 64):
            if y > 56 and abs(x + 0.5) > 14 - (y - 56) * 2: continue
            M.put(x, y, D, P, DARK if x > -6 else WOOD_D)
    return M, {P: [0, 0, 0]}


def escombros():
    M = Model(S=2, seed=73)
    for i in range(160):
        a = M.rng.uniform(0, math.tau); r = abs(M.rng.gauss(0, 14))
        x, z = r * math.cos(a), r * math.sin(a)
        y = int(max(0, 18 - r * 1.1 + M.rng.uniform(-3, 3)))
        c = BRICK if M.rng.random() < 0.7 else BRICK_D
        for dx in range(3):
            for dz in range(2):
                for yy in range(max(0, y - 2), y + 1): M.put(x + dx, yy, z + dz, P, c)
    for k in range(2):                                      # vigas
        ang = M.rng.uniform(0, math.pi)
        for t in range(-30, 30):
            for w in range(-1, 2):
                M.put(t * math.cos(ang) - w * math.sin(ang), 16 + t * 0.25 * (1 if k else -1),
                      t * math.sin(ang) + w * math.cos(ang), P, WOOD_D)
    return M, {P: [0, 0, 0]}


def fuente():
    """Fuente seca: pilón octogonal de piedra con verdín y un pez de bronce que salta."""
    M = Model(S=2, seed=74)
    for y in range(0, 14):
        for x in range(-40, 40):
            for z in range(-40, 40):
                d = max(abs(x + 0.5), abs(z + 0.5), (abs(x + 0.5) + abs(z + 0.5)) / 1.414)
                if d > 38 or (d < 34 and y > 2): continue
                c = STONE if (y // 3) % 2 else STONE_D
                if y > 10 and M.noise(x, y, z, 6.0) > 0.55: c = GREEN
                M.put(x, y, z, P, c)
    for y in range(0, 30):
        for x in range(-5, 5):
            for z in range(-5, 5): M.put(x, y, z, P, STONE_L)
    BRONZE = (0.30, 0.42, 0.36)
    for x in range(-12, 13):
        h = int(5 * math.sqrt(max(0.0, 1 - (x / 12) ** 2)))
        for y in range(-h, h + 1):
            for z in range(-2, 2): M.put(x, 40 + y + x // 3, z, P, BRONZE)
    for y in range(-6, 7):
        for z in range(-1, 1): M.put(-13 - abs(y) // 2, 36 + y, z, P, BRONZE)
    return M, {P: [0, 0, 0]}


def carretilla():
    M = Model(S=2, seed=75)
    for x in range(-22, 22):
        for z in range(-14, 14):
            for y in range(12, 26):
                if min(x + 22, 21 - x, z + 14, 13 - z) > 1 and y > 13: continue
                M.put(x, y, z, P, WOOD if y % 4 else WOOD_D)
    for x in range(-20, 18, 3):                             # pescado plateado
        for z in range(-12, 12, 4):
            for t in range(5): M.put(x + t // 2, 24, z + t % 2, P, (0.66, 0.70, 0.72) if t else (0.40, 0.44, 0.46))
    for a in range(0, 360, 6):                              # rueda delantera
        t = math.radians(a)
        for r in (9, 10):
            for z in (-1, 0): M.put(24 + r * math.cos(t), 10 + r * math.sin(t), z, P, IRON)
    for z in (-12, 11):                                     # varales y patas
        for x in range(-40, -22): M.put(x, 22 + (x + 22) // 6, z, P, WOOD_D)
        for y in range(0, 12): M.put(-18, y, z, P, WOOD_D)
    return M, {P: [0, 0, 0]}


def cajas():
    M = Model(S=2, seed=76)
    for x0, z0, y0 in ((-14, -10, 0), (12, -8, 0), (-2, 12, 0), (-4, -6, 14)):
        for x in range(x0 - 12, x0 + 12):
            for z in range(z0 - 9, z0 + 9):
                for y in range(y0, y0 + 14):
                    if min(x - x0 + 12, x0 + 11 - x, z - z0 + 9, z0 + 8 - z) > 0 and y < y0 + 13: continue
                    c = PLANK if (y // 3) % 2 else PLANK_D
                    if y == y0 + 13 and (x + z) % 5 == 0: c = (0.60, 0.64, 0.66)
                    M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def nasa():
    M = Model(S=2, seed=77)
    for x in range(-18, 18):
        for z in range(-12, 12):
            for y in range(0, 14):
                if y < 2: M.put(x, y, z, P, WOOD); continue
                r = math.hypot(z, y - 2)
                if abs(r - 11) < 1 and (x % 4 == 0 or (z + y) % 3 == 0): M.put(x, y, z, P, NET)
    return M, {P: [0, 0, 0]}


def pilote():
    M = Model(S=2, seed=78)
    for y in range(0, 40):
        for x in range(-5, 5):
            for z in range(-5, 5):
                if math.hypot(x + 0.5, z + 0.5) > 5: continue
                c = lerp(WOOD_D, (0.18, 0.20, 0.16), 0.5) if y < 12 else (WOOD if (x + y) % 5 else WOOD_D)
                M.put(x, y, z, P, c)
    for i in range(30):                                     # cabo enrollado
        a = i / 30 * math.tau * 2
        M.put(6 * math.cos(a), 30 - i // 3, 6 * math.sin(a), P, (0.58, 0.52, 0.38))
    return M, {P: [0, 0, 0]}


def coche():
    """Coche cerrado de los años 20, abandonado: carrocería negra desconchada con óxido, capó
    largo, ruedas de radios y lunas rotas."""
    M = Model(S=2, seed=79)
    BODY = (0.12, 0.13, 0.14); BODY_L = (0.22, 0.23, 0.24)
    for x in range(-60, 60):
        for z in range(-26, 26):
            for y in range(14, 60):
                hood = x > 10
                if hood and y > 36: continue
                top = 35 if hood else 59
                if min(x + 60, 59 - x, z + 26, 25 - z) > 1 and y < top: continue
                win = 38 < y < 56 and -54 < x < 6 and z in (-26, 25) and (x + 54) % 20 > 2
                if win: c = DARK if M.hsh(x // 6, y // 6, 3) > 0.4 else GLASS
                else: c = RUST if M.noise(x, y, z, 5.0) > 0.8 else (BODY if y % 5 else BODY_L)
                M.put(x, y, z, P, c)
    for cx in (-40, 40):
        for s in (-1, 1):
            for a in range(-13, 14):
                for b in range(0, 26):
                    r = math.hypot(a, b - 13)
                    if r > 13: continue
                    c = TIRE if r > 9 else (IRON_L if abs(a) < 1 or abs(b - 13) < 1 else IRON)
                    for dz in range(3): M.put(cx + a, b, s * (26 + dz), P, c)
    for z in (-14, 13):
        for y in (30, 31): M.put(60, y, z, P, (0.68, 0.64, 0.50))
    return M, {P: [0, 0, 0]}


PIECES = {'casa': casa, 'casa_2': lambda: casa(2), 'autobus': autobus, 'poste': poste, 'valla': valla, 'barril': barril,
          'redes': redes, 'barca': barca, 'farola': farola, 'juncos': juncos,
          'fachada': fachada, 'templo': templo, 'escombros_mano': escombros, 'fuente': fuente,
          'carretilla': carretilla, 'cajas': cajas, 'nasa': nasa, 'pilote': pilote, 'coche': coche}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/inn_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('inn_%s: %d voxels' % (name, n))
