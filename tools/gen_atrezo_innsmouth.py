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
ROPE = (0.56, 0.49, 0.34); BARN = (0.66, 0.64, 0.56)
REED_L = (0.56, 0.54, 0.32); REED_B = (0.40, 0.30, 0.18); CATTAIL = (0.30, 0.19, 0.11); CATTAIL_L = (0.42, 0.30, 0.18)
MUD = (0.20, 0.17, 0.12); MUD_W = (0.14, 0.14, 0.12); DRY = (0.62, 0.56, 0.38)
NET_K = (0.30, 0.28, 0.22); SLAT = (0.44, 0.36, 0.26); SLAT_D = (0.30, 0.24, 0.17); BRICK_W = (0.46, 0.26, 0.20)
BUOY = (0.70, 0.30, 0.20); BUOY_W = (0.78, 0.74, 0.66)
BARK_P = (0.30, 0.25, 0.19); BARK_PD = (0.20, 0.16, 0.12); WOOD_G = (0.40, 0.38, 0.33); SLIME_P = (0.12, 0.20, 0.12)


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
                elif state in ('luz', 'oscura'):
                    # 16-10-2026: se enciende y se apaga sola (glow 2, window_glow.gdshader)
                    put(a, b, TRIM if sash else LIGHT, glow=0 if sash else 2)
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
    piv = {P: [0, 0, 0]}
    if variant == 1: piv['smoke'] = [-31, RIDGE + 12, -4]       # humea (la verde, abandonada, no)
    return M, piv


# ---------------- autobús de Joe Sargent ----------------

def _upsample(M0, seed):
    """Dobla la resolución de un modelo (cada voxel pasa a 2x2x2) para añadirle detalle fino."""
    M = Model(S=M0.S * 2, seed=seed)
    for (x, y, z), v in M0.V.items():
        for i in (0, 1):
            for j in (0, 1):
                for k in (0, 1): M.V[(2 * x + i, 2 * y + j, 2 * z + k)] = [v[0], v[1], v[2]]
    return M


def _weather(M, base_cols, rust_scale=4.0, grain=0.07):
    """Desgaste fino sobre las chapas: grano, arañazos, óxido en manchas con borde oscuro y
    ampollas, y la pintura más desvaída arriba."""
    for (x, y, z), v in M.V.items():
        if v[2] or v[1] not in base_cols: continue
        c = v[1]
        c = lerp(c, (0, 0, 0), grain * (M.hsh(x, y, z) - 0.5) * 2) if M.hsh(x, y, z) > 0.5 else lerp(c, (1, 1, 1), grain * M.hsh(x, y, z))
        n = M.noise(x, y, z, rust_scale)
        if v[1] == RUST: c = lerp(RUST, (0.30, 0.14, 0.08), M.noise(x, y, z, 1.5))       # óxido que ya había: con matices
        elif n > 0.80: c = lerp(RUST, (0.30, 0.14, 0.08), M.noise(x, y, z, 1.5))        # óxido
        elif n > 0.77: c = lerp(c, (0.10, 0.07, 0.05), 0.6)                              # borde del desconchón
        elif n > 0.73 and M.hsh(x, y, z + 7) > 0.6: c = lerp(c, RUST, 0.4)              # ampollas
        if M.hsh(x // 5, y, 3) > 0.995: c = lerp(c, (0.7, 0.7, 0.68), 0.4)                # arañazo
        v[1] = c


def _autobus32():
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


def autobus():
    """El autobús a 64/m (revisión de arte del 13-10-2026): la carrocería de _autobus32 al doble
    de resolución, con desgaste fino (grano, óxido con borde, ampollas, arañazos), costuras de
    los paneles con remaches, retrovisores, limpiaparabrisas, manilla y bisagras de la puerta,
    letrero de destino en blanco sobre el parabrisas, bocina, rueda de repuesto, pilotos y
    matrícula detrás, tubo de escape, asientos que se ven por las ventanillas y el volante."""
    M = _upsample(_autobus32()[0], 62)
    L, HW = 168, 34
    BACK, FB = -L, L - 60
    CREAM = (0.66, 0.62, 0.50); CHROME = (0.62, 0.62, 0.60); SEAT = (0.34, 0.22, 0.16)
    _weather(M, {BUS, lerp(BUS, BUS_D, 0.5), BUS_D}, rust_scale=6.0)
    for v in M.V.values():                                             # menos óxido que a 32/m: ya hay detalle fino
        if v[1] == RUST and M.hsh(id(v) % 9973, 1, 1) > 0.5: v[1] = lerp(BUS, BUS_D, 0.3)
    for x in range(BACK + 4, FB - 2):                                   # costuras y remaches
        if (x - BACK) % 40 not in (0, 1): continue
        for y in range(36, 130):
            for z in (-HW, HW - 1):
                v = M.V.get((x, y, z))
                if v and not v[2] and v[1] not in (GLASS, DARK, CREAM):
                    v[1] = lerp(v[1], (0.06, 0.07, 0.06), 0.5)
                    if y % 6 == 0: M.put(x + 1, y, z + (1 if z > 0 else -1), P, IRON_L)
    for x in range(BACK + 10, FB - 14, 6):                              # asientos por dentro
        for z in range(-HW + 6, HW - 6):
            if (x - BACK) % 32 < 8:
                for y in range(60, 104): M.put(x, y, z, P, SEAT if y < 100 else lerp(SEAT, DARK, 0.5))
    for a in range(0, 360, 8):                                         # volante
        M.put(FB - 10, int(100 + 10 * math.sin(math.radians(a))), int(16 + 10 * math.cos(math.radians(a))), P, DARK)
    for y in range(128, 140):                                          # letrero de destino (sin letras)
        for z in range(-26, 26):
            M.put(FB + 1, y, z, P, CREAM if 2 < abs(z) < 24 and 129 < y < 139 else DARK)
    for s in (-1, 1):                                                  # limpiaparabrisas
        for k in range(18): M.put(FB + 2, 92 + k, s * 12 + k // 3 * s, P, DARK)
    for s in (-1, 1):                                                  # retrovisores
        z = s * (HW + 8)
        for k in range(10): M.put(FB + 2, 110, s * (HW + k), P, IRON)
        for y in range(106, 118):
            for dz in range(-4, 4): M.put(FB + 3, y, z + dz, P, CHROME if abs(dz) > 2 or y in (106, 117) else (0.40, 0.46, 0.50))
    dz = HW + 1                                                        # manilla y bisagras de la puerta
    for x in range(FB - 30, FB - 24): M.put(x, 76, dz - 1 + 1, P, CHROME)
    for y in (44, 110):
        for x in range(FB - 44, FB - 40): M.put(x, y, dz, P, IRON_L)
    for y in range(36, 52):                                            # pilotos y matrícula detrás
        for z in range(-12, 12): M.put(BACK - 1, y, z, P, (0.56, 0.52, 0.40) if 37 < y < 51 and abs(z) < 11 else DARK)
    for zc in (-28, 27):
        for y in range(56, 64):
            for z in range(zc - 3, zc + 3): M.put(BACK - 1, y, z, P, (0.55, 0.08, 0.06))
    for y in range(40, 96):                                            # rueda de repuesto detrás
        for z in range(-26, 26):
            r = math.hypot(y - 68, z)
            if r > 26: continue
            c = TIRE if r > 19 else (IRON if r > 16 or r < 4 else ((0.62, 0.52, 0.30) if int(math.degrees(math.atan2(y - 68, z)) % 30) < 7 else None))
            if c is None: continue
            for d in range(2, 10): M.put(BACK - d, y, z, P, c)
    for x in range(BACK - 10, BACK + 30):                              # tubo de escape
        for y in (28, 29):
            for z in (20, 21): M.put(x, y, z, P, IRON)
    for x in range(L - 6, L):                                          # bocina
        for y in range(84, 90): M.put(x, y, -30, P, CHROME)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
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
    """Barril de arenques (revisión de arte del 14-10-2026, referencia de FLUX en local
    tools/local/ref_barril_1000.png; el de antes queda en models/inn_barril_v1.json). A 48 voxels/m,
    0,6 x 0,9 m: duelas con su tono y juntas, panza, cuatro aros de hierro con remaches y óxido,
    canto de las duelas por encima de la tapa, la tapa medio corrida y arenques plateados
    asomando, salitre y verdín abajo."""
    M = Model(S=3, seed=65)                                     # 48/m (a 64 la carretera perdía en el 1 % peor)
    rng = M.rng
    H, R0 = 44, 12.8
    NST = 18
    FISH = (0.62, 0.66, 0.68); FISH_D = (0.36, 0.40, 0.44); FISH_B = (0.24, 0.30, 0.36)
    SALT = (0.70, 0.70, 0.66)
    tones = [rng.uniform(0, 1) for _ in range(NST)]
    for y in range(0, H):
        r = R0 + 2.0 * math.sin(y / (H - 1) * math.pi)
        for x in range(-17, 18):
            for z in range(-17, 18):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r or d < r - 1.8: continue
                a = (math.atan2(z, x) % math.tau) / math.tau * NST
                s = int(a)
                c = lerp(WOOD_D, (0.46, 0.36, 0.25), 0.25 + 0.6 * tones[s])
                c = lerp(c, WOOD_D, 0.3 * M.noise(x * 0.3, y, z * 0.3, 3.0))       # veta a lo largo
                if a - s < 0.08: c = lerp(c, (0.12, 0.09, 0.07), 0.7)                  # junta
                if y in (4, 5, 11, 12, H - 13, H - 12, H - 6, H - 5):
                    c = lerp(IRON, RUST, 0.6 * M.noise(x, y, z, 2.5))                  # aros
                    if (int(a * 2) % 5 == 0) and y in (5, 12, H - 12, H - 5): c = IRON_L   # remaches
                    M.put(x * 1.04, y, z * 1.04, P, c)
                if y < 6: c = lerp(c, (0.24, 0.30, 0.20), 0.5 * M.noise(x, y, z, 3.0))  # verdín
                if M.noise(x, y, z, 2.0) > 0.8: c = lerp(c, SALT, 0.5)                 # salitre
                M.put(x, y, z, P, c)
    # fondo, y tapa medio corrida (a un lado, inclinada)
    for x in range(-15, 16):
        for z in range(-15, 16):
            if math.hypot(x, z) < R0: M.put(x, 0, z, P, WOOD_D)
    for x in range(-13, 14):
        for z in range(-13, 14):
            if math.hypot(x, z) < R0 - 1 and x < 3:
                y = H - 3 + int((x + 13) * 0.06)
                M.put(x + 5, y, z, P, (0.40, 0.31, 0.22) if (z // 4) % 2 else (0.34, 0.26, 0.18))
    # arenques en el hueco que deja la tapa
    for i in range(9):
        cx, cz = rng.uniform(-10, -2) + 10, rng.uniform(-9, 9)
        ang = rng.uniform(0, math.pi)
        L = rng.randint(6, 8)
        y = H - 4 + rng.randint(-1, 1)
        for k in range(-L, L + 1):
            px, pz = cx + k * math.cos(ang), cz + k * math.sin(ang)
            if math.hypot(px, pz) > R0 - 2: continue
            w = 1.6 * math.sin(math.pi * (k + L) / (2 * L)) + 0.4
            for dw in range(-int(w), int(w) + 1):
                qx, qz = px - dw * math.sin(ang), pz + dw * math.cos(ang)
                c = FISH if dw >= 0 else FISH_D
                if dw == int(w): c = FISH_B
                if k == L: c = (0.08, 0.08, 0.09)                                    # ojo/cabeza
                M.put(qx, y + (1 if abs(dw) < 1 else 0), qz, P, c)
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a2, k[1] + b2, k[2] + c2) in M.V for a2, b2, c2 in NB)]: del M.V[k]
    return M, {P: [0, 0, 0]}


def redes():
    """Redes tendidas a secar (rehechas a 64/m en la revisión de arte del 13-10-2026): dos postes
    con travesaño y tornapuntas; la red cuelga en paños que se comban, de malla en rombo con los
    nudos más oscuros, rota a trozos, con algas y un pez enredados; corchos en la relinga de
    arriba y plomos en la de abajo; un cesto de mimbre, una boya y cabo adujado al pie."""
    M = Model(S=4, seed=66)
    rng = M.rng
    NETC = (0.48, 0.45, 0.36); KNOT = (0.30, 0.28, 0.22); CORK = (0.64, 0.42, 0.26); LEAD_C = (0.32, 0.33, 0.35)
    WICKER = (0.58, 0.46, 0.28); WICKER_D = (0.42, 0.32, 0.18)
    PX = 92
    for x0 in (-PX, PX):                                                             # postes
        for y in range(0, 136):
            for dx in range(-3, 3):
                for dz in range(-3, 3):
                    if dx * dx + dz * dz > 8: continue
                    c = lerp(WOOD_D, WOOD, 0.5 + 0.4 * math.sin(dx + dz + y * 0.2))
                    if y < 12: c = lerp(c, (0.24, 0.30, 0.20), 0.5)
                    M.put(x0 + dx, y, dz, P, c)
        for i in range(24):                                                          # tornapuntas
            for dz in (-1, 0): M.put(x0 - (1 if x0 > 0 else -1) * i, 100 + i, dz, P, WOOD_D)
    for x in range(-PX - 6, PX + 6):                                                 # travesaño
        for y in (124, 125, 126):
            for dz in (-2, -1, 0, 1): M.put(x, y, dz, P, WOOD if y < 126 else WOOD_D)
    def top_y(x): return 120 - int(10 * math.cos(x / PX * math.pi / 2))
    for x in range(-PX + 3, PX - 2):                                                 # paños de red
        t = top_y(x)
        drape = 70 + int(12 * math.sin(x / 15.0))
        for y in range(t - drape, t):
            f = (t - y) / drape
            z = int(round(3 * math.sin(x / 11.0 + y / 9.0) * f))
            u, v = x + y, x - y
            mesh = u % 6 == 0 or v % 6 == 0
            if not mesh: continue
            if M.noise(x, y, 0, 9.0) > 0.72: continue                                 # agujeros
            c = KNOT if (u % 6 == 0 and v % 6 == 0) else NETC
            M.put(x, y, z, 'cloth', c)                                                # cuelga y se mece (sway.gdshader)
        if x % 10 == 0:                                                              # corchos
            for dy in range(3):
                for dx in range(3): M.put(x + dx, t - 1 - dy, 1, 'cloth', CORK)
        yb = t - drape
        if x % 12 == 0:                                                              # plomos
            for dx in range(2): M.put(x + dx, yb, 0, 'cloth', LEAD_C); M.put(x + dx, yb - 1, 0, 'cloth', LEAD_C)
    for _ in range(14):                                                              # algas enredadas
        x = rng.randint(-PX + 10, PX - 10); y = rng.randint(50, 100)
        for k in range(rng.randint(4, 12)): M.put(x + k // 4, y - k, 1, 'cloth', (0.20, 0.32, 0.16) if k % 3 else (0.14, 0.22, 0.10))
    for t in range(-7, 8):                                                           # un pez enredado
        for k in range(-2, 3):
            if abs(k) <= 2 * math.sqrt(max(0, 1 - (t / 8) ** 2)): M.put(20 + t, 70 + k, 2, 'cloth', (0.62, 0.66, 0.68) if k > -1 else (0.30, 0.38, 0.44))
    for y in range(0, 26):                                                           # cesto de mimbre
        r = 14 + (y // 8)
        for a in range(0, 360, 3):
            x = int(-50 + r * math.cos(math.radians(a))); z = int(28 + r * math.sin(math.radians(a)))
            M.put(x, y, z, P, WICKER if (a // 9 + y // 2) % 2 else WICKER_D)
    for x in range(-63, -36):
        for z in range(15, 42):
            if (x + 50) ** 2 + (z - 28) ** 2 < 196: M.put(x, 0, z, P, WICKER_D)
    for y in range(0, 16):                                                           # boya
        for x in range(42, 58):
            for z in range(24, 40):
                if ((x - 50) / 8) ** 2 + ((y - 8) / 8) ** 2 + ((z - 32) / 8) ** 2 < 1:
                    M.put(x, y, z, P, (0.70, 0.22, 0.16) if y > 7 else (0.82, 0.78, 0.70))
    for a in range(0, 720, 5):                                                       # cabo adujado
        r = 6 + a / 120
        M.put(int(5 + r * math.cos(math.radians(a))), 1 + a // 360, int(34 + r * math.sin(math.radians(a))), P, (0.58, 0.50, 0.34))
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0], 'cloth': [0, 120, 0]}


def barca():
    """Bote de remos volcado (revisión de arte del 14-10-2026, referencia
    tools/local/ref_barca_1000.png; el de antes queda en models/inn_barca_v1.json). A 48 voxels/m,
    3,5 x 1,6 m, quilla arriba: tracas de tingladillo con el solape en sombra, pintura azul y
    blanca que se pela a la madera, franja roja de flotación, quilla y roda de madera oscura, el
    espejo de popa, una tabla rota con el hueco a la vista, verdín y barro al pie, y un remo
    partido y un cabo en el suelo."""
    M = Model(S=3, seed=67)
    rng = M.rng
    L, Wd, Hh = 84, 34, 30
    BLUE = (0.28, 0.40, 0.48); BLUE_D = (0.20, 0.30, 0.36); WHITE = (0.70, 0.70, 0.64); RED = (0.48, 0.16, 0.12)
    broken = (rng.randint(-30, 10), rng.randint(6, 14))
    for x in range(-L, L):
        t_ = abs(x) / L
        half = Wd * math.sqrt(max(0.0, 1 - t_ ** (1.8 if x > 0 else 3.0)))            # proa afilada en +x
        hgt = Hh - 6 * t_ ** 2
        for z in range(-int(half) - 1, int(half) + 2):
            u = abs(z + 0.5) / max(half, 1)
            if u > 1: continue
            y = int(hgt * math.sqrt(max(0.0, 1 - u ** 2.4)))
            strake = int(u * 7)
            c = WHITE if strake == 5 else (BLUE if strake % 2 else BLUE_D)
            if u > 0.94: c = RED                                                       # franja de flotación (abajo, volcado)
            if (u * 7) % 1 < 0.14: c = lerp(c, (0.10, 0.10, 0.10), 0.5)                # solape
            if M.noise(x, y, z, 4.0) > 0.68: c = lerp(WOOD, WOOD_D, M.noise(x, y, z, 1.5))   # pelado
            if y < 3: c = lerp(c, (0.22, 0.26, 0.18), 0.6)                             # verdín al pie
            if abs(x - broken[0]) < 7 and abs(z - broken[1]) < 4 and strake in (1, 2): continue   # tabla rota
            for yy in range(max(0, y - 1), y + 1): M.put(x, yy, z, P, c)
        for k in (-1, 0, 1): M.put(x, int(hgt) + 1, k, P, WOOD_D)                    # quilla
        M.put(x, int(hgt) + 2, 0, P, WOOD_D)
    for y in range(0, Hh - 4):                                                         # espejo de popa
        for z in range(-int(Wd * 0.8), int(Wd * 0.8)):
            if abs(z) / (Wd * 0.8) <= math.sqrt(max(0.0, 1 - (y / (Hh - 4)) ** 2)):
                M.put(-L, y, z, P, WOOD if (y // 4) % 2 else WOOD_D)
    for (x, y, z), v in list(M.V.items()):                                            # el hueco: interior oscuro
        if abs(x - broken[0]) < 8 and abs(z - broken[1]) < 5: v[1] = lerp(v[1], (0.08, 0.07, 0.06), 0.3)
    for x in range(-30, 40):                                                           # remo partido
        z = 46 + x // 10
        for d in (0, 1): M.put(x, 0, z + d, P, WOOD)
        if x > 26:
            for d in range(-3, 5): M.put(x, 0, z + d, P, WOOD)
    for x in range(48, 60):                                                            # la otra mitad, suelta
        for d in (0, 1): M.put(x, 0, 52 - (x - 48) // 3 + d, P, WOOD_D)
    for i in range(70):                                                                # cabo en el suelo
        a = i * 0.25
        r = 6 + i * 0.06
        M.put(70 + r * math.cos(a), 0, 30 + r * math.sin(a), P, ROPE)
    for x in range(-L - 6, L + 6):                                                     # barro al pie
        for z in range(-Wd - 6, Wd + 6):
            if (x, 0, z) in M.V: continue
            if M.noise(x, 0, z, 6.0) > 0.55: M.put(x, 0, z, P, MUD)
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a2, k[1] + b2, k[2] + c2) in M.V for a2, b2, c2 in NB)]: del M.V[k]
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
    """Mata de juncos de la marisma (rehecha a 64/m en la revisión de arte del 13-10-2026): tallos
    de alturas distintas que se arquean, verdes abajo y pajizos arriba, con hojas planas que se
    doblan, algunos tronchados, espadañas pardas en lo alto con su punta, hojas secas caídas y la
    base en el barro húmedo."""
    M = Model(S=4, seed=69)
    rng = M.rng
    for x in range(-44, 45):                                         # barro
        for z in range(-44, 45):
            d = math.hypot(x, z)
            if d > 38 + 5 * M.noise(x, 0, z, 6.0): continue
            M.put(x, 0, z, P, MUD_W if M.noise(x, 1, z, 4.0) > 0.55 else MUD)
    for i in range(70):
        a = rng.uniform(0, math.tau); r = abs(rng.gauss(0, 18))
        x0, z0 = r * math.cos(a), r * math.sin(a)
        h = rng.randint(50, 120) * (1.1 - r / 40)
        bend = rng.uniform(0.0, 0.35); ba = rng.uniform(0, math.tau)
        broken = rng.random() < 0.12
        for k in range(int(h)):
            t = k / h
            if broken and t > 0.55:                                    # tronchado: la punta cae
                x = x0 + math.cos(ba) * (bend * h * 0.3 + (t - 0.55) * h * 0.9)
                y = h * 0.55 - (t - 0.55) * h * 0.4
                z = z0 + math.sin(ba) * (bend * h * 0.3 + (t - 0.55) * h * 0.9)
            else:
                off = bend * h * t * t
                x, y, z = x0 + math.cos(ba) * off, k, z0 + math.sin(ba) * off
            c = lerp(REED_D, REED, min(1.0, t * 1.6))
            if t > 0.6: c = lerp(REED, REED_L if not broken else DRY, (t - 0.6) * 2.5)
            M.put(x, y, z, P, c)
            if k % 2 == 0 and t < 0.5: M.put(x + 1, y, z, P, c)         # algo más gruesos abajo
        if i % 3 == 0:                                                   # hojas planas que se doblan
            la = ba + rng.uniform(-1, 1)
            for k in range(int(h * 0.6)):
                t = k / (h * 0.6)
                x = x0 + math.cos(la) * t * h * 0.35
                y = h * 0.15 + k * 0.9 - t * t * h * 0.35
                z = z0 + math.sin(la) * t * h * 0.35
                for w in (0, 1): M.put(x - math.sin(la) * w, y, z + math.cos(la) * w, P, lerp(REED_D, REED, 0.5 + 0.5 * t))
        if i % 4 == 0 and not broken:                                   # espadaña
            off = bend * h
            cx, cz = x0 + math.cos(ba) * off, z0 + math.sin(ba) * off
            for y in range(int(h) - 18, int(h) - 2):
                for dx in (-1, 0, 1):
                    for dz in (-1, 0, 1):
                        if abs(dx) + abs(dz) > 1 + (1 if 3 < y - (h - 18) < 13 else 0): continue
                        M.put(cx + dx, y, cz + dz, P, CATTAIL if M.hsh(dx, y, dz) > 0.25 else CATTAIL_L)
            for y in range(int(h) - 2, int(h) + 6): M.put(cx, y, cz, P, REED_B)
    for _ in range(26):                                                  # hojas secas caídas
        a = rng.uniform(0, math.tau); r = rng.uniform(8, 30); la = rng.uniform(0, math.tau)
        for k in range(rng.randint(8, 18)):
            M.put(r * math.cos(a) + math.cos(la) * k, 1, r * math.sin(a) + math.sin(la) * k, P, DRY if k % 3 else REED_B)
    return M, {P: [0, 0, 0]}


# ---------------- hito 6.2 ----------------

STONE = (0.52, 0.51, 0.48); STONE_D = (0.40, 0.39, 0.37); STONE_L = (0.62, 0.61, 0.58)
GREEN = (0.20, 0.34, 0.30)
GOLD_OLD = (0.62, 0.52, 0.28)


def fachada():
    """Casa georgiana de ladrillo de dos plantas en ruinas (rehecha el 09-10-2026), 16/m, hueca:
    aparejo con llagas claras, zócalo de piedra, imposta y cornisa con dentellones; ventanas de
    guillotina simétricas con dintel de piedra y clave, alféizar y contraventanas (alguna
    descolgada); puerta con pilastras, frontón y montante en abanico; un rincón hundido con el
    ladrillo roto en escalera, vigas y cabios al aire y cascotes al pie; tejado de pizarra con
    chimeneas en los hastiales y verdín y hiedra que trepa por una esquina."""
    M = Model(S=1, seed=71)
    HX, HZ, H = 56, 40, 96                                  # 7 x 5 m, 6 m de alto
    MORTAR = (0.48, 0.44, 0.40); SHUT = (0.20, 0.30, 0.26); SHUT_D = (0.14, 0.21, 0.18)
    IVY = (0.18, 0.28, 0.14); IVY_L = (0.26, 0.38, 0.18); RAFTER = (0.30, 0.22, 0.15)
    FLOOR2 = 48

    def collapsed(x, y):                                    # rincón hundido (arriba a la derecha)
        return x > 8 and y > H - 34 + (x - 8) * 0.45 + 6 * M.noise(x, y, 0, 5.0)

    def brick(x, y, z):
        if y < 8: return lerp(STONE_D, STONE_L, 0.5 * M.noise(x, y, z, 3.0))
        course = y // 3
        if y % 3 == 0: return MORTAR
        u = x if abs(z) >= HZ - 1 else z
        if (u + (course % 2) * 4) % 8 == 0: return MORTAR
        c = BRICK if M.hsh(course, (u + (course % 2) * 4) // 8, 2) < 0.7 else BRICK_D
        if M.noise(x, y, z, 12.0) > 0.7: c = lerp(c, MOSS, 0.4)
        return c

    for y in range(0, H):
        for x in range(-HX, HX):
            for z in range(-HZ, HZ):
                if min(x + HX, HX - 1 - x, z + HZ, HZ - 1 - z) > 1: continue
                if collapsed(x, y): continue
                M.put(x, y, z, P, brick(x, y, z))
    # borde roto: ladrillos en escalera sobre el hueco
    for x in range(8, HX):
        top = max((y for y in range(H) if (x, y, HZ - 1) in M.V), default=0)
        for k in range(0, 1 + int(3 * M.hsh(x // 4, 0, 5))):
            M.put(x, top + 1 + k, HZ - 1, P, BRICK_D if k else BRICK, over=False)
    for x in range(-HX - 1, HX + 1):                        # imposta y cornisa con dentellones
        for z in (HZ, HZ + 1):
            if not collapsed(x, FLOOR2): M.put(x, FLOOR2, z, P, STONE_L)
            if not collapsed(x, H - 4):
                for y in (H - 5, H - 4): M.put(x, y, z, P, STONE_L)
                if x % 4 < 2: M.put(x, H - 6, HZ, P, STONE_L)

    def window(cx, cy, shutters):
        if collapsed(cx, cy + 10): return
        for a in range(-6, 6):
            for b in range(-10, 10):
                edge = a in (-6, 5) or b in (-10, 9) or b == 0 or a in (-1, 0)
                c = TRIM if edge else (DARK if M.hsh(a, b, cx + cy) > 0.25 else GLASS)
                M.put(cx + a, cy + b, HZ, P, c)
        for a in range(-8, 8):                              # dintel con clave y alféizar
            for b in (10, 11, 12): M.put(cx + a, cy + b, HZ, P, STONE_L)
            M.put(cx + a, cy - 11, HZ, P, STONE_L); M.put(cx + a, cy - 11, HZ + 1, P, STONE_L)
        for b in (10, 11, 12, 13): M.put(cx - 1, cy + b, HZ + 1, P, STONE_L); M.put(cx, cy + b, HZ + 1, P, STONE_L)
        if shutters:                                        # contraventanas de tablillas
            loose = M.hsh(cx, cy, 8) < 0.35
            for side in (-1, 1):
                for a in range(0, 5):
                    for b in range(-10, 10):
                        x = cx + side * (7 + a)
                        y = cy + b
                        if loose and side == 1: x, y = cx + 7 + a + (b + 10) // 4, cy + b - a   # descolgada
                        M.put(x, y, HZ + 1, P, SHUT if b % 2 else SHUT_D)
    for cx in (-38, -16, 16, 38):
        window(cx, 28, True)
        window(cx, 72, True)
    # puerta: pilastras, frontón y montante en abanico
    for x in range(-7, 7):
        for y in range(8, 40):
            M.put(x, y, HZ, P, DARK if abs(x + 0.5) < 5 and y < 34 else STONE_L)
    for a in range(0, 180, 12):                             # abanico del montante
        r = 5
        M.put(int(r * math.cos(math.radians(a))), 34 + int(r * math.sin(math.radians(a)) * 0.6), HZ, P, TRIM)
    for x in (-9, -8, 7, 8):                                # pilastras
        for y in range(8, 42): M.put(x, y, HZ + 1, P, STONE_L)
    for k in range(0, 6):                                   # frontón
        for x in range(-11 + k, 11 - k): M.put(x, 42 + k, HZ + 1, P, STONE_L)
    for i in range(3):                                      # escalones
        for x in range(-9, 9):
            for z in range(HZ, HZ + 7 - i * 2): M.put(x, 7 - i * 2, z, P, STONE_D); M.put(x, 6 - i * 2, z, P, STONE_D)
    # tejado de pizarra a dos aguas a lo largo de x; hundido sobre el rincón roto
    for x in range(-HX - 2, HX + 2):
        for z in range(-HZ - 3, HZ + 3):
            y = H + int((HZ + 3 - abs(z + 0.5)) * 0.55)
            if collapsed(x, H + 2) and x > 14: continue
            if x > 6 and M.hsh(x // 3, z // 3, 1) > 0.5: continue          # tejas que faltan
            row = y // 2
            c = ROOF if M.hsh(row, x // 4, 3) < 0.6 else ROOF_D
            if M.noise(x, y, z, 8.0) > 0.7: c = lerp(c, MOSS, 0.8)
            M.put(x, y, z, P, c)
    for x in range(10, HX, 7):                              # cabios al aire sobre el hueco
        for z in range(-HZ - 2, HZ + 2):
            y = H + int((HZ + 3 - abs(z + 0.5)) * 0.55) - 1
            if M.hsh(x, 0, 9) < 0.3 and z > 10: continue                   # alguno partido
            M.put(x, y, z, P, RAFTER); M.put(x + 1, y, z, P, RAFTER)
    for z in range(-HZ, HZ):                                # vigas del forjado asomando
        for x in range(20, HX, 12): M.put(x, FLOOR2 - 2, z, P, RAFTER)
    for cx in (-HX + 4, HX - 8):                            # chimeneas en los hastiales
        if cx > 0: continue                                  # la de la parte hundida se cayó
        for y in range(H, H + 40):
            for x in range(cx - 4, cx + 6):
                for z in range(-6, 6):
                    if min(x - cx + 4, cx + 5 - x, z + 6, 5 - z) > 0 and y < H + 39: continue
                    M.put(x, y, z, P, STONE_L if y >= H + 36 else brick(x, y, z + HZ))
    for _ in range(14):                                     # cascotes al pie del derrumbe
        cx, cz = M.rng.randint(14, HX + 6), M.rng.randint(HZ, HZ + 16)
        sz = M.rng.randint(2, 5)
        for x in range(cx, cx + sz):
            for z in range(cz, cz + sz):
                for y in range(0, M.rng.randint(1, sz)): M.put(x, y, z, P, BRICK_D if (x + z) % 3 else MORTAR)
    for y in range(0, 70):                                  # hiedra en la esquina izquierda
        spread = 10 * (1 - y / 70.0) + 3 * M.noise(0, y, 0, 6.0)
        for x in range(-HX, int(-HX + spread)):
            if M.noise(x, y, 0, 3.0) > 0.42:
                M.put(x, y, HZ, P, IVY_L if M.noise(x, y, 1, 2.0) > 0.6 else IVY)
    return M, {P: [0, 0, 0]}


T_STONE = (0.54, 0.53, 0.49); T_STONE_D = (0.38, 0.37, 0.35); T_STONE_L = (0.66, 0.65, 0.61)
T_JOINT = (0.20, 0.20, 0.19); VERD = (0.24, 0.40, 0.34); VERD_L = (0.36, 0.52, 0.44); STREAK = (0.22, 0.24, 0.22)
LICHEN = (0.56, 0.56, 0.36); WEED_T = (0.22, 0.32, 0.14); BRONZE_G = (0.26, 0.40, 0.32); GOLD_D = (0.42, 0.34, 0.16)


def templo():
    """Antiguo templo masónico de la Orden de Dagon (rehecho a 32/m y más envejecido en la
    revisión de arte del 13-10-2026): fachada clásica de 14 m sobre un podio con escalinata de
    peldaños gastados, rotos y con hierbajos; muro de sillares biselados de tonos distintos, con
    piezas desconchadas o que faltan, grietas, liquen, manchas de verdín del salitre y chorretones
    que bajan de la cornisa; pilastras en las esquinas; cuatro columnas estriadas con basa y
    capitel de volutas (a una le falta un trozo del fuste); entablamento con arquitrabe de bandas,
    friso de rosetas y cornisa con dentículos; frontón con dentículos, acróteras y el símbolo de
    la Orden (pez en un círculo de olas, oro deslustrado que chorrea verdín) partido por una
    grieta; puerta en arco de dos hojas con cuarterones y clavos de bronce, una entreabierta, con
    montante y dovelas; dos ventanas altas cegadas con tablas y reja; un trozo de cornisa caído
    en la escalinata. Hueco y sin la trasera, que no se ve."""
    M = Model(S=2, seed=72)
    rng = M.rng
    HX, D, H = 224, 56, 256                               # media anchura, medio fondo, alto del muro
    PY = 18                                               # alto del podio
    def ashlar(x, y, z, u, face):
        """Color de un sillar: hiladas de 12, bloques de 24 a 40 alternados, bisel y juntas."""
        row = y // 12
        off = int(M.hsh(row, face, 1) * 30)
        bw = 24 + int(M.hsh(row, face, 2) * 16)
        bi = (u + off) // bw
        bu = (u + off) % bw; bv = y % 12
        c = lerp(T_STONE_D, T_STONE_L, 0.25 + 0.55 * M.hsh(row, bi, face))
        c = lerp(c, T_STONE_D, 0.3 * M.noise(x, y, z, 5.0))
        if bv == 0 or bu == 0: c = T_JOINT
        elif bv == 1 or bu == 1: c = lerp(c, T_JOINT, 0.35)
        elif bv == 11: c = lerp(c, T_STONE_L, 0.3)
        return c, (row, bi)
    missing = set()
    for _ in range(14): missing.add((rng.randint(2, 20), rng.randint(-8, 8)))
    def weather(c, x, y, z, top):
        n = M.noise(x, y, z, 14.0)
        if n > 0.62: c = lerp(c, VERD, min(1.0, (n - 0.62) * 3.0))                   # verdín a manchas
        if M.hsh(x // 2, 1, 7) > 0.84 and top - y < 60 + 80 * M.hsh(x // 2, 2, 7):     # chorretones desde arriba
            c = lerp(c, STREAK, 0.45)
        if M.noise(x, y, z, 3.0) > 0.86: c = lerp(c, LICHEN, 0.5)                    # liquen
        if y < PY + 14 and M.noise(x, y, z, 6.0) > 0.45: c = lerp(c, VERD, 0.5)       # humedad abajo
        return c
    # ---------- podio y escalinata ----------
    for x in range(-HX - 6, HX + 6):
        for y in range(0, PY):
            for z in range(-D, D + 4):
                if min(x + HX + 6, HX + 5 - x, D + 3 - z) > 1 and y < PY - 1 and z > -D: continue
                c, _ = ashlar(x, y, z, x if z > 0 else z, 3)
                M.put(x, y, z, P, weather(c, x, y, z, PY))
    NS, SH, ST = 7, 3, 7                                   # peldaños: número, alto, huella
    for s in range(NS):
        y0 = PY - (s + 1) * SH
        z0 = D + 4 + s * ST
        for x in range(-HX + 30, HX - 30):
            for y in range(max(0, y0), y0 + SH):
                for z in range(z0, z0 + ST):
                    if y < y0 + SH - 1 and z < z0 + ST - 1 and z > z0: continue          # hueco
                    edge = z >= z0 + ST - 2 and y >= y0 + SH - 1
                    if edge and M.hsh(x // 3, s, 3) > 0.8: continue                   # canto desgastado
                    if s == 2 and 40 < x < 70 and y == y0 + SH - 1 and z > z0 + 2: continue   # peldaño roto
                    c = lerp(T_STONE, T_STONE_D, 0.5 * M.hsh(x // 20, s, 5))
                    if (x + 6 * s) % 20 == 0: c = T_JOINT
                    if M.noise(x, y, z, 4.0) > 0.7: c = lerp(c, VERD, 0.5)
                    if y == y0 + SH - 1 and M.noise(x, s, z, 2.0) > 0.86: c = WEED_T         # hierbajos
                    M.put(x, y, z, P, c)
            if (x + s * 11) % 37 == 0 and M.hsh(x, s, 9) > 0.4:                       # matas de hierba
                for k in range(rng.randint(2, 5)):
                    M.put(x + rng.randint(-1, 1), y0 + SH + k, z0 + rng.randint(0, 2), P, WEED_T)
    # ---------- muros (fachada, laterales) ----------
    top = PY + H
    for y in range(PY, top):
        for x in range(-HX, HX):
            for z in range(-D, D):
                front = z == D - 1
                side = x == -HX or x == HX - 1
                if not (front or side) and y < top - 1: continue
                if z == -D and not side: continue
                u = x if front else z
                c, blk = ashlar(x, y, z, u, 0 if front else 1)
                if front and blk in missing:                                                # sillar que falta (hueco)
                    M.put(x, y, z - 3, P, lerp(T_JOINT, T_STONE_D, 0.4)); continue
                pil = abs(abs(x + 0.5) - (HX - 10)) < 10 and front
                if pil:                                                                      # pilastras
                    c = lerp(T_STONE_L, T_STONE, 0.4 * M.noise(x, y, z, 4.0))
                    if abs(abs(x + 0.5) - (HX - 10)) > 8.5: c = T_JOINT
                M.put(x, y, z, P, weather(c, x, y, z, top))
                if pil: M.put(x, y, D, P, weather(c, x, y, D, top))
    for _ in range(9):                                                                       # grietas
        x, y = rng.randint(-HX + 10, HX - 10), rng.randint(PY + 60, top - 4)
        for _ in range(rng.randint(30, 90)):
            for z in (D - 1, D):
                v = M.V.get((x, y, z))
                if v: v[1] = T_JOINT
            y -= 1; x += rng.choice((-1, 0, 0, 1))
            if y < PY + 2: break
    # ---------- ventanas altas cegadas con tablas y reja ----------
    for wx in (-HX + 40, HX - 40):
        for x in range(wx - 12, wx + 12):
            for y in range(PY + 70, PY + 170):
                arch = y > PY + 158 and abs(x - wx + 0.5) > math.sqrt(max(0, 144 - (y - PY - 158) ** 2))
                if arch: continue
                fr = abs(x - wx + 0.5) > 10 or y < PY + 72
                if fr: M.put(x, y, D, P, T_STONE_L); continue
                c = lerp(PLANK, PLANK_D, M.hsh((y - PY) // 12, wx, 4))
                if (y - PY) % 12 == 0: c = DARK
                M.put(x, y, D - 1, P, c)
                if (x - wx) % 6 == 0: M.put(x, y, D, P, IRON if M.hsh(x, y, 5) > 0.15 else RUST)
        for x in range(wx - 14, wx + 14):                                                    # alféizar
            for z in (D, D + 1, D + 2): M.put(x, PY + 69, z, P, T_STONE_L); M.put(x, PY + 68, z, P, T_STONE_D)
    # ---------- puerta en arco ----------
    DW, DH = 30, 136
    for x in range(-DW - 8, DW + 8):
        for y in range(PY, PY + DH + 40):
            ax = abs(x + 0.5)
            r_in = math.hypot(ax, max(0, y - (PY + DH)))
            if y >= PY + DH and r_in > DW + 8: continue
            inside = ax < DW and (y < PY + DH or r_in < DW)
            if inside:
                if y >= PY + DH - 2:                                                          # montante oscuro con radios
                    ang = math.degrees(math.atan2(y - PY - DH, x + 0.5))
                    c = BRONZE_G if int(ang) % 30 < 4 or r_in > DW - 3 else DARK
                    M.put(x, y, D - 1, P, c)
                    continue
                if x >= 0:                                                                     # hoja derecha entreabierta
                    M.put(x, y, D - 6, P, DARK)
                    xx = int(round(x * 0.55)); zz = D - 2 + int(round(x * 0.5))
                    c = lerp(WOOD, WOOD_D, 0.5 * M.hsh(x // 6, y // 20, 2))
                    if (y - PY) % 34 < 2 or x % 15 < 1: c = WOOD_D
                    if (y - PY) % 17 == 8 and x % 8 == 4: c = BRONZE_G
                    M.put(xx, y, zz, P, c)
                else:                                                                          # hoja izquierda cerrada
                    c = lerp(WOOD, WOOD_D, 0.5 * M.hsh(x // 6, y // 20, 3))
                    if (y - PY) % 34 < 2 or (-x) % 15 < 1: c = WOOD_D
                    M.put(x, y, D - 1, P, c)
                    if (y - PY) % 17 == 8 and (-x) % 8 == 4: M.put(x, y, D, P, BRONZE_G)
                continue
            if ax < DW + 8:                                                                    # marco y dovelas
                c = T_STONE_L if (int(math.degrees(math.atan2(max(0, y - PY - DH), ax))) // 15) % 2 or y < PY + DH else T_STONE
                if y >= PY + DH and int(math.degrees(math.atan2(y - PY - DH, ax))) % 15 == 0: c = T_JOINT
                M.put(x, y, D, P, weather(c, x, y, D, top)); M.put(x, y, D + 1, P, weather(c, x, y, D + 1, top))
    # ---------- columnas ----------
    CR = 11
    for cx in (-132, -52, 52, 132):
        cz = D + 22
        broken = cx == 132
        for y in range(PY, top - 16):
            f = (y - PY) / (top - 16 - PY)
            r = CR * (1.0 - 0.12 * f)                                                          # éntasis
            if y < PY + 8: r = CR + 4 - (y - PY) * 0.3                                        # basa
            for x in range(cx - CR - 5, cx + CR + 6):
                for z in range(cz - CR - 5, cz + CR + 6):
                    d = math.hypot(x - cx + 0.5, z - cz + 0.5)
                    if d > r or d < r - 2: continue
                    a = math.atan2(z - cz + 0.5, x - cx + 0.5)
                    if broken and PY + 110 < y < PY + 140 and math.cos(a) > 0.2 and d > r - 4: continue   # trozo arrancado
                    c = T_STONE_L if (int((a + math.pi) / math.tau * 20) % 2) else T_STONE          # estrías
                    if y < PY + 8: c = T_STONE_L
                    if (int((a + math.pi) / math.tau * 20) % 2) == 0 and y >= PY + 8 and d > r - 1: continue  # estría hundida
                    M.put(x, y, z, P, weather(c, x, y, z, top))
            if (y - PY) % 40 == 39:                                                            # tambores
                for a in range(0, 360, 6):
                    x = cx + int(round((r - 0.5) * math.cos(math.radians(a)))); z = cz + int(round((r - 0.5) * math.sin(math.radians(a))))
                    v = M.V.get((x, y, z))
                    if v: v[1] = T_JOINT
        for y in range(top - 16, top):                                                         # capitel con volutas
            k = y - (top - 16)
            w = CR + 2 + k // 2
            for x in range(cx - w, cx + w + 1):
                for z in range(cz - CR - 3, cz + CR + 4):
                    c = T_STONE_L if k > 3 else T_STONE
                    vol = abs(abs(x - cx) - (w - 3)) + abs(y - (top - 8)) < 4 and z >= cz + CR
                    if vol: c = T_STONE_D if (x + y) % 3 == 0 else T_STONE_L
                    if (abs(x - cx) == w or z in (cz - CR - 3, cz + CR + 3) or y == top - 1):
                        M.put(x, y, z, P, weather(c, x, y, z, top))
                    elif vol and z == cz + CR + 3: M.put(x, y, z, P, c)
    # ---------- entablamento y frontón ----------
    EZ0, EZ1 = D - 1, D + 36
    for y in range(top, top + 40):
        k = y - top
        for x in range(-HX - 8, HX + 8):
            for z in range(EZ0, EZ1 + (6 if k > 32 else 0)):
                if k <= 32 and z < EZ1 - 1 and x not in (-HX - 8, HX + 7) and y != top + 39: continue
                c = T_STONE_L
                if k < 18:                                                                     # arquitrabe de tres bandas
                    c = T_STONE_L if (k // 6) % 2 == 0 else T_STONE
                    if k % 6 == 0: c = T_JOINT
                elif k < 32:                                                                   # friso de rosetas
                    c = T_STONE
                    rx = (x + 9) % 36 - 18
                    if abs(rx) + abs(k - 25) < 6: c = T_STONE_L if (abs(rx) + abs(k - 25)) % 3 else T_JOINT
                else:                                                                          # cornisa con dentículos
                    c = T_STONE_L if k > 35 else (T_JOINT if x % 4 == 0 else T_STONE_L)
                M.put(x, y, z, P, weather(c, x, y, z, top + 200))
    PT = top + 40
    for y in range(PT, PT + 96):
        w = HX + 8 - (y - PT) * (HX + 8) / 96
        if w <= 2: break
        for x in range(-int(w), int(w)):
            ed = w - abs(x + 0.5)
            for z in range(EZ1 - 6, EZ1 + 6):
                if ed > 8 and z != EZ1 - 3: continue
                c = T_STONE
                if ed <= 8:                                                                    # cornisa inclinada con dentículos
                    c = T_STONE_L if ed > 3 else (T_JOINT if (x + y) % 4 == 0 else T_STONE_L)
                    if z < EZ1 - 4: continue
                elif z < EZ1 - 4: continue
                M.put(x, y, z, P, weather(c, x, y, z, PT + 200))
    for (ax_, ay_) in ((-HX - 4, PT), (HX + 3, PT), (0, PT + 92)):                        # acróteras
        for x in range(ax_ - 5, ax_ + 6):
            for y in range(ay_, ay_ + 12):
                if abs(x - ax_) > 5 - (y - ay_) // 3: continue
                for z in (EZ1 - 2, EZ1 - 1, EZ1): M.put(x, y, z, P, T_STONE_L)
    # símbolo de la Orden en el tímpano, con verdín que chorrea y la grieta
    cy, sz = PT + 34, EZ1 - 3
    for a in range(0, 360, 1):
        t = math.radians(a)
        for rr in (21, 22, 23):
            r = rr + 2.5 * math.sin(t * 8)
            M.put(round(r * math.cos(t)), round(cy + r * math.sin(t)), sz, P, GOLD_OLD if rr != 23 else GOLD_D)
    for x in range(-13, 14):
        h = int(7 * math.sqrt(max(0.0, 1 - (x / 14) ** 2)))
        for y in range(-h, h + 1):
            c = GOLD_OLD if (x + y) % 5 else GOLD_D                                            # escamas
            if (x, y) in ((-8, 2), (-8, 3), (-9, 2), (-9, 3)): c = DARK                        # ojo
            M.put(x, cy + y, sz, P, c)
        if x % 4 == 0:
            for y in range(-h, h + 1): M.put(x, cy + y, sz, P, GOLD_D)
    for y in range(-7, 8):
        for k in range(3): M.put(14 + abs(y) // 2 + k, cy + y, sz, P, GOLD_OLD)            # cola
    for x in range(-24, 25, 3):                                                                # verdín que chorrea del oro
        if M.hsh(x, 4, 4) < 0.4: continue
        for k in range(rng.randint(8, 30)):
            v = M.V.get((x, cy - 22 - k, sz - 1)) or M.V.get((x, cy - 22 - k, sz))
            if v: v[1] = lerp(v[1], VERD_L, 0.6)
    x, y = -60, PT + 70                                                                        # grieta del tímpano
    for _ in range(140):
        for z in (sz, sz - 1):
            v = M.V.get((x, y, z))
            if v and v[1] not in (GOLD_OLD, GOLD_D): v[1] = T_JOINT
        y -= 1 if M.hsh(x, y, 1) > 0.4 else 0; x += 1
        if y < PT + 2: break
    # trozo de cornisa caído en la escalinata, con cascotes
    for x in range(70, 108):
        for y in range(PY - 3 * 3, PY - 3 * 3 + 10):
            for z in range(D + 4 + 2 * 7, D + 4 + 2 * 7 + 14):
                tilt = (x - 70) // 8
                yy = y + tilt
                if (x in (70, 107) or yy in (PY - 9 + tilt, PY + tilt) or z in (D + 18, D + 31)):
                    M.put(x, yy, z, P, T_STONE_L if (x % 4) else T_JOINT)
    for _ in range(40):
        x, z = rng.randint(-HX + 30, HX - 30), rng.randint(D + 4, D + 4 + NS * ST)
        s = int((z - D - 4) / ST)
        y0 = PY - (s + 1) * SH + SH
        for dx in range(rng.randint(2, 4)):
            for dz in range(rng.randint(2, 3)):
                M.put(x + dx, y0, z + dz, P, T_STONE if M.hsh(x, dx, dz) > 0.3 else T_STONE_D)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]:
        del M.V[k]                                                                             # hueco: fuera lo que no se ve
    for k in [k for k in M.V if k[2] < D - 4 and k[1] < top and -HX + 2 <= k[0] < HX - 2 and k[1] >= PY - 1]:
        del M.V[k]                                                                             # techo del muro: no se ve
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


def escombros_v2():
    """Montón de escombros de una casa (revisión de arte del 14-10-2026, a mano con la referencia
    tools/local/ref_escombros_1000.png; el de Replicate queda en models/inn_escombros_v1.json).
    A 48 voxels/m, 2,3 m: el arranque de un muro de ladrillo en aparejo con llagas, roto en
    escalera; el montón de ladrillos sueltos (enteros y medios, cada uno con su tono y algunos
    de canto), cascotes de enlucido blanco, polvo de mortero, dos vigas astilladas, un marco de
    ventana roto con un cristal y hierbajos."""
    M = Model(S=3, seed=73)
    rng = M.rng
    PLASTER = (0.82, 0.80, 0.74); PLASTER_D = (0.64, 0.62, 0.58); MORTAR = (0.60, 0.58, 0.54)
    BR_L = (0.68, 0.38, 0.28); BR_D = (0.48, 0.25, 0.19)
    BRICK_D, BRICK_W = BR_D, BR_L                                             # más claros: de noche salían negros
    FRAME = (0.62, 0.60, 0.54); WEED = (0.30, 0.36, 0.20)
    def brick_col(i):
        return lerp(BRICK_D, BRICK_W, rng.random()) if rng.random() > 0.15 else lerp(BRICK_D, (0.30, 0.20, 0.16), 0.4)
    # muro: dos hiladas de ladrillos de 6x3 (más llaga) a lo largo de x, roto en escalera
    top = {}
    for x in range(-52, 30):
        top[x] = int(max(3, 46 - max(0, x + 20) * 0.9 + 6 * M.noise(x, 0, 0, 5.0)))
    for x in range(-52, 30):
        for y in range(0, top[x]):
            row = y // 4
            off = 3 if row % 2 else 0
            for z in range(-36, -30):
                joint = (y % 4 == 3) or ((x + off) % 7 == 6)
                c = MORTAR if joint else lerp(BRICK_D, BRICK_W, M.hsh((x + off) // 7, row, 1))
                if z in (-36, -31) or y == top[x] - 1:
                    if joint and z == -31 and y < top[x] - 1: c = lerp(MORTAR, (0.2, 0.2, 0.2), 0.3)
                    if z == -31 and M.noise(x, y, z, 6.0) > 0.62 and y > 10: c = lerp(PLASTER, PLASTER_D, M.hsh(x, y, 2))   # enlucido
                    M.put(x, y, z, P, c)
    # el montón: ladrillos sueltos apilados, más alto en el centro
    hmap = {}
    for i in range(380):
        a = rng.uniform(0, math.tau); r = abs(rng.gauss(0, 18))
        cx, cz = r * math.cos(a), r * math.sin(a) - 6
        L, Wb, Hb = (7, 3, 3) if rng.random() < 0.75 else (4, 3, 3)
        if rng.random() < 0.3: L, Wb = Wb, L
        if rng.random() < 0.15: Hb, Wb = Wb, Hb                                   # de canto
        x0, z0 = int(cx), int(cz)
        base = max(hmap.get((x, z), 0) for x in range(x0, x0 + L) for z in range(z0, z0 + Wb))
        if base > 30 - r * 0.9: continue
        c = brick_col(i)
        for x in range(x0, x0 + L):
            for z in range(z0, z0 + Wb):
                for y in range(base, base + Hb):
                    edge = x in (x0, x0 + L - 1) and z in (z0, z0 + Wb - 1)
                    M.put(x, y, z, P, lerp(c, (0.2, 0.12, 0.1), 0.25) if edge else c)
                hmap[(x, z)] = base + Hb
    for i in range(90):                                                         # cascotes de enlucido
        cx, cz = rng.gauss(0, 16), rng.gauss(-6, 14)
        s = rng.randint(2, 5)
        y0 = hmap.get((int(cx), int(cz)), 0)
        for x in range(int(cx), int(cx) + s):
            for z in range(int(cz), int(cz) + s - 1):
                if abs(x - cx) + abs(z - cz) <= s:
                    M.put(x, y0, z, P, PLASTER if M.hsh(x, y0, z) > 0.3 else PLASTER_D)
    for x in range(-44, 44):                                                    # polvo de mortero alrededor
        for z in range(-40, 36):
            if (x, 0, z) not in M.V and M.noise(x, 0, z, 5.0) > 0.5 and math.hypot(x, z + 6) < 40:
                M.put(x, 0, z, P, lerp(MORTAR, PLASTER_D, M.hsh(x, 0, z)))
    for k, (ang, y0, rise) in enumerate(((0.5, 18, 0.32), (2.3, 10, -0.25))):    # vigas astilladas
        for s in range(-36, 36):
            for w in range(-2, 2):
                for h in range(0, 3):
                    x = s * math.cos(ang) - w * math.sin(ang); z = s * math.sin(ang) + w * math.cos(ang) - 6
                    y = y0 + s * rise + h
                    if y < 0: continue
                    c = WOOD_D if h == 0 or w in (-2, 1) else WOOD
                    if abs(s) > 32 and M.hsh(int(x), int(y), int(z)) < 0.5: continue        # astillas
                    M.put(x, y, z, P, c)
    for y in range(0, 26):                                                      # marco de ventana roto, de lado
        for z in range(14, 34):
            fr = y in (0, 1, 24, 25) or z in (14, 15, 32, 33) or z == 24
            if fr and not (y > 16 and z > 26): M.put(30 + y // 3, y // 2, z, P, FRAME)
            elif 2 < y < 12 and 16 < z < 23: M.put(30 + y // 3, y // 2, z, P, GLASS)
    for i in range(14):                                                         # hierbajos
        cx, cz = rng.uniform(-40, 40), rng.uniform(-40, 30)
        for k in range(rng.randint(3, 7)):
            M.put(cx + rng.randint(-1, 1), k, cz + rng.randint(-1, 1), P, WEED)
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for kk in [kk for kk in M.V if all((kk[0] + a2, kk[1] + b2, kk[2] + c2) in M.V for a2, b2, c2 in NB)]: del M.V[kk]
    return M, {P: [0, 0, 0]}


def fuente_v1():
    """Fuente de la plaza (rehecha a 64/m en la revisión de arte del 13-10-2026): pilón octogonal
    de sillares con moldura en el borde y paneles con peces en relieve, verdín y grietas, una
    pieza del borde caída; dentro, agua sucia estancada (verde parduzca, con nata, hojas, un
    reflejo y basura flotando); en el centro, un pedestal con dos tazas escalonadas y un cachalote de
    bronce que sale del agua, comido por el cardenillo; y un charco que se sale por la grieta."""
    M = Model(S=4, seed=74)
    rng = M.rng
    R, H = 76, 28
    BRONZE = (0.30, 0.42, 0.36); VERDI = (0.36, 0.58, 0.48); BRONZE_D = (0.20, 0.28, 0.24)
    WATER = (0.16, 0.20, 0.14); WATER_L = (0.26, 0.30, 0.20); SCUM = (0.34, 0.38, 0.22); LEAF = (0.36, 0.26, 0.14)
    def octd(x, z): return max(abs(x + 0.5), abs(z + 0.5), (abs(x + 0.5) + abs(z + 0.5)) / 1.414)
    def stone_c(x, y, z, face=0):
        c = lerp(STONE, STONE_D, 0.5 * M.noise(x, y, z, 5.0))
        if y % 9 == 0: c = lerp(c, STONE_D, 0.6)                                   # hiladas
        if M.noise(x, y, z, 6.0) > 0.6 and y > 8: c = lerp(c, GREEN, 0.7)
        if y < 6: c = lerp(c, (0.30, 0.30, 0.26), 0.4)
        return c
    gap = (math.radians(30), math.radians(52))                                      # pieza caída del borde
    for x in range(-R - 4, R + 5):
        for z in range(-R - 4, R + 5):
            d = octd(x, z)
            a = math.atan2(z, x) % math.tau
            for y in range(0, H + 4):
                if y < H:
                    if d > R or (d < R - 8 and y > 4): continue
                    if d < R - 1 and d > 1 and R - 8 <= d and y > 4 and not (d >= R - 8): continue
                    c = stone_c(x, y, z)
                    if d > R - 1.5 and 8 <= y < 22:                                     # paneles con pez
                        seg = int(a / (math.tau / 8))
                        u = (a - seg * math.tau / 8) / (math.tau / 8)
                        if 0.08 < u < 0.92:
                            fx, fy = (u - 0.5) * 2, (y - 15) / 6
                            if fx * fx / 0.5 + fy * fy < 1 and abs(fx) < 0.7: c = lerp(STONE, (0.70, 0.69, 0.64), 0.4)
                            elif 0.7 <= fx < 0.95 and abs(fy) < (fx - 0.6) * 3: c = lerp(STONE, (0.70, 0.69, 0.64), 0.3)
                            elif abs(fx) > 0.95 or abs(fy) > 1.2: c = lerp(c, STONE_D, 0.4)
                    M.put(x, y, z, P, c)
                else:                                                                 # moldura del borde que vuela
                    if not (R - 10 <= d <= R + 3): continue
                    if gap[0] < a < gap[1]: continue
                    c = lerp(STONE_L, STONE, 0.4 * M.noise(x, y, z, 4.0))
                    if y == H + 3 and d > R: continue
                    if M.noise(x, y, z, 5.0) > 0.68: c = lerp(c, GREEN, 0.6)
                    M.put(x, y, z, P, c)
    for x in range(-R + 9, R - 8):                                                    # agua sucia
        for z in range(-R + 9, R - 8):
            if octd(x, z) > R - 9: continue
            n = M.noise(x, 0, z, 9.0)
            c = lerp(WATER, WATER_L, M.noise(x, 3, z, 4.0) * 0.6)
            if n > 0.66: c = SCUM if M.hsh(x, z, 1) > 0.3 else lerp(SCUM, WATER, 0.4)     # nata
            if M.hsh(x, z, 2) > 0.995: c = LEAF
            if 10 < x < 30 and -30 < z < -14 and (x + z) % 3 == 0: c = (0.46, 0.50, 0.44)   # reflejo
            M.put(x, H - 6, z, P, c)
    for _ in range(9):                                                               # hojas y basura flotando
        cx, cz = rng.randint(-50, 50), rng.randint(-50, 50)
        if octd(cx, cz) > R - 14: continue
        col = LEAF if rng.random() < 0.7 else (0.62, 0.58, 0.48)
        for dx in range(-2, 3):
            for dz in range(-1, 2): M.put(cx + dx, H - 5, cz + dz, P, col)
    for y in range(0, 46):                                                           # pedestal y tazas
        r = 9 if y < 40 else 12
        if 22 <= y < 26: r = 26 - (y - 22) * 2
        for x in range(-27, 28):
            for z in range(-27, 28):
                dd = math.hypot(x, z)
                if dd > r: continue
                if 22 <= y < 26 and dd < r - 3 and y > 22: continue
                c = stone_c(x, y, z)
                if 22 <= y < 26: c = lerp(STONE_L, GREEN, 0.4 * M.noise(x, y, z, 3.0))
                M.put(x, y, z, P, c)
    # cachalote de bronce que sale del agua (revisión de arte del 14-10-2026): cabeza enorme y
    # roma de caja, mandíbula estrecha por debajo con los dientes, ojo pequeño, espiráculo a la
    # izquierda, piel arrugada, joroba y nudillos en el lomo, aletas pequeñas y la cola abierta;
    # sale de una ola de bronce sobre la taza. 1,9 m de largo, cardenillo en lo expuesto.
    WL, AL = 122, math.radians(38)
    TX, TY = -46, 50                                                                # arranque de la cola
    ca, sa = math.cos(AL), math.sin(AL)
    def prof(t):                                                                     # media altura, media anchura, exponente
        if t < 0.10: return 3.0, 3.0, 2.0
        if t < 0.36: k = (t - 0.10) / 0.26; return 3 + 12 * k ** 1.3, 3 + 10 * k ** 1.2, 2.0
        if t < 0.62: k = (t - 0.36) / 0.26; return 15 + 2 * k, 13 + 1 * k, 2.0 + 0.8 * k
        if t < 0.95: return 17.5, 14.0, 3.6
        k = (t - 0.95) / 0.05; return 17.5 * (1 - 0.55 * k * k), 14.0 * (1 - 0.45 * k * k), 3.6
    def bend(t): return 7 * math.sin(math.pi * (t - 0.05))                           # lomo arqueado
    def wcol(x, y, z, top):
        c = lerp(BRONZE, BRONZE_D, 0.4 * M.noise(x, y, z, 4.0))
        if top or M.noise(x, y, z, 6.0) > 0.58: c = lerp(c, VERDI, 0.35 + 0.5 * M.noise(x, y, z, 3.0))
        return c
    for x in range(-90, 80):
        for y in range(36, 150):
            dx, dy = x - TX, y - TY
            u = dx * ca + dy * sa
            if u < -4 or u > WL + 1: continue
            t = u / WL
            v = -dx * sa + dy * ca - bend(t)
            for z in range(-34, 35):
                if t < 0.12:                                                         # aleta caudal horizontal
                    sp = 30 * (0.12 - t) / 0.12 + 4
                    if abs(v) > 2.2 - 1.2 * abs(z) / 34 or abs(z) > sp: continue
                    if abs(z) < 4 and t < 0.03: continue                              # escotadura
                    if t < 0.12 - 0.1 * (abs(z) / 34) ** 0.7 - 0.02: pass
                    elif abs(z) > 8 and t < 0.12 - 0.09 * (abs(z) / 34): continue
                    M.put(x, y, z, P, wcol(x, y, z, v > 0)); continue
                hh, hw, p = prof(t)
                if t > 0.62 and v < 0: hh *= 0.86                                       # la cabeza baja menos
                if (abs(v) / hh) ** p + (abs(z) / hw) ** p > 1: continue
                c = wcol(x, y, z, v > hh * 0.3)
                if 0.12 < t < 0.62 and int(u) % 5 == 0 and v < hh * 0.6: c = lerp(c, BRONZE_D, 0.55)   # arrugas
                if t > 0.62 and abs(v + hh * 0.86) < 1.5 and t < 0.95: c = (0.10, 0.12, 0.10)          # comisura
                M.put(x, y, z, P, c)
    def at(t, v, z):                                                                 # punto local -> mundo
        u = t * WL; vv = v + bend(t)
        return int(round(TX + u * ca - vv * sa)), int(round(TY + u * sa + vv * ca)), int(round(z))
    for i in range(int(0.66 * WL), int(0.95 * WL)):                                   # mandíbula estrecha con dientes
        t = i / WL
        for w in range(-4, 5):
            for d in range(0, 4):
                q = at(t, -15.5 - d, w)
                M.put(*q, P, BRONZE_D if d < 3 else BRONZE)
        if i % 3 == 0:
            for s in (-3, 3): M.put(*at(t, -14.5, s), P, (0.80, 0.76, 0.62))
    for s in (-1, 1):                                                                # ojos pequeños
        for a in range(2):
            for b in range(2): M.put(*at(0.69 + a / WL, -9 + b, s * 13.6), P, (0.05, 0.05, 0.05))
        for k in range(12):                                                          # aletas pectorales
            for w in range(6 - k // 2):
                M.put(*at(0.60 - k * 0.004 - w * 0.006, -11 - w * 0.4, s * (12 + k)), P, wcol(k, w, s, True))
    for k in range(4):                                                               # espiráculo
        M.put(*at(0.97 - k * 0.004, 8.5, -6), P, (0.06, 0.07, 0.06))
    for i in range(int(0.30 * WL), int(0.50 * WL), 4):                                # joroba y nudillos del lomo
        h = 2 if i < int(0.38 * WL) else 1
        for d in range(h + 1):
            for w in (-1, 0, 1): M.put(*at(i / WL, prof(i / WL)[0] + d, w), P, VERDI)
    for y in range(44, 82):                                                          # ola de bronce que la sostiene
        k = (y - 44) / 38
        r = 9 - 3 * k
        cx = -4 + 10 * k * k
        for x in range(-24, 24):
            for z in range(-14, 15):
                d = math.hypot(x - cx, z)
                if d > r + 2 * math.sin(y * 0.5 + math.atan2(z, x - cx) * 3): continue
                c = lerp(VERDI, BRONZE, 0.5 + 0.5 * math.sin(y * 0.6 + z * 0.4))
                M.put(x, y, z, P, c)
    for a in range(0, 360, 20):                                                      # espuma que rompe en la taza
        for rr in range(8, 16):
            x = int(rr * math.cos(math.radians(a + rr * 7))); z = int(rr * math.sin(math.radians(a + rr * 7)))
            M.put(x - 4, 46 + (rr % 3 == 0), z, P, lerp(VERDI, (0.52, 0.66, 0.58), 0.5))
    for (x, y, z) in [k for k in M.V if k[1] == H + 3]: pass
    for k in range(18):                                                              # trozo del borde caído
        a = math.radians(41)
        for u in range(-9, 10):
            for y in range(0, 4):
                M.put(int((R + 16) * math.cos(a)) + u, y, int((R + 16) * math.sin(a)) + k - 9, P, STONE_L if y == 3 else STONE)
    for x in range(40, 110):                                                         # charco que se sale por la grieta
        for z in range(30, 90):
            if octd(x, z) < R + 2: continue
            if M.noise(x, 0, z, 10.0) > 0.45 and math.hypot(x - 64, z - 60) < 34:
                M.put(x, 0, z, P, lerp(WATER, WATER_L, M.noise(x, 1, z, 3.0) * 0.5))
    x, y = int(R * 0.7), H
    for _ in range(26):                                                              # la grieta
        v = M.V.get((x, y, int(R * 0.7)))
        if v: v[1] = (0.12, 0.12, 0.11)
        y -= 1; x += rng.choice((-1, 0, 1))
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}

FUENTE_ROCK_TOP = 36                 # voxels (32/m): altura de la roca en que se sienta la sirena (gen_arena_calles.py)


def fuente():
    """Fuente de la plaza, el triple de grande (16-10-2026, encargo del autor; la de antes queda en
    inn_fuente_v1): pilón octogonal de 7 m a 32/m, de sillares con moldura que vuela, paneles con
    peces en relieve, verdín y grietas, un escalón alrededor y una pieza del borde caída con su
    charco; dentro, agua estancada verde parduzca con nata, hojas y basura; en el centro, como en
    Copenhague, un montón de rocas de granito con algas y percebes donde se sienta la sirena
    (inn_sirena, aparte, a 48/m)."""
    M = Model(S=2, seed=75)
    rng = M.rng
    R, H, T = 114, 20, 10                          # radio (3,56 m), alto del pilón (0,62 m), grueso del muro
    WATER = (0.15, 0.19, 0.13); WATER_L = (0.25, 0.29, 0.19); SCUM = (0.33, 0.37, 0.21); LEAF = (0.36, 0.26, 0.14)
    GRANITE = (0.44, 0.42, 0.40); GRANITE_D = (0.30, 0.29, 0.28); ALGAE = (0.16, 0.24, 0.12)
    def octd(x, z): return max(abs(x + 0.5), abs(z + 0.5), (abs(x + 0.5) + abs(z + 0.5)) / 1.414)
    def stone_c(x, y, z):
        c = lerp(STONE, STONE_D, 0.5 * M.noise(x, y, z, 5.0))
        bx = int((math.atan2(z, x) % math.tau) / (math.tau / 40))                     # sillares
        if y % 7 == 0 or (y // 7 + bx) % 2 == 0 and int(math.degrees(math.atan2(z, x)) * 2) % 18 == 0: c = lerp(c, STONE_D, 0.6)
        c = lerp(c, STONE_L, 0.25 * M.hsh(bx, y // 7, 3))
        if M.noise(x, y, z, 6.0) > 0.6 and y > 6: c = lerp(c, GREEN, 0.7)
        if y < 5: c = lerp(c, (0.30, 0.30, 0.26), 0.4)
        return c
    gap = (math.radians(30), math.radians(46))                                      # pieza caída del borde
    for x in range(-R - 12, R + 13):
        for z in range(-R - 12, R + 13):
            d = octd(x, z)
            a = math.atan2(z, x) % math.tau
            if R < d <= R + 10:                                                       # escalón alrededor
                for y in range(0, 4): M.put(x, y, z, P, lerp(STONE_D, STONE, 0.5 * M.noise(x, y, z, 4.0)) if y < 3 else STONE)
                continue
            if d > R: continue
            for y in range(0, H + 4):
                if y < H:
                    if d < R - T and y > 3: continue
                    c = stone_c(x, y, z)
                    if d > R - 1.5 and 5 <= y < 17:                                     # paneles con pez
                        seg = int(a / (math.tau / 8))
                        u = (a - seg * math.tau / 8) / (math.tau / 8)
                        if 0.1 < u < 0.9:
                            fx, fy = (u - 0.5) * 2.4, (y - 11) / 5
                            if fx * fx / 0.5 + fy * fy < 1 and abs(fx) < 0.7: c = lerp(STONE, (0.70, 0.69, 0.64), 0.4)
                            elif 0.7 <= fx < 0.98 and abs(fy) < (fx - 0.6) * 3: c = lerp(STONE, (0.70, 0.69, 0.64), 0.3)
                            elif abs(fx) < 0.6 and abs(fy) < 0.2 and abs(fx + 0.45) < 0.05: c = (0.12, 0.12, 0.11)   # ojo
                            elif abs(fx) > 1.05 or abs(fy) > 1.25: c = lerp(c, STONE_D, 0.45)
                    M.put(x, y, z, P, c)
                else:                                                                 # moldura del borde que vuela
                    if not (R - T - 1 <= d <= R + 3): continue
                    if gap[0] < a < gap[1]: continue
                    c = lerp(STONE_L, STONE, 0.4 * M.noise(x, y, z, 4.0))
                    if y == H + 3 and (d > R + 1 or d < R - T + 1): continue
                    if M.noise(x, y, z, 5.0) > 0.66: c = lerp(c, GREEN, 0.6)
                    M.put(x, y, z, P, c)
    WY = H - 4                                                                        # agua sucia
    for x in range(-R + T, R - T + 1):
        for z in range(-R + T, R - T + 1):
            if octd(x, z) > R - T: continue
            n = M.noise(x, 0, z, 12.0)
            c = lerp(WATER, WATER_L, M.noise(x, 3, z, 5.0) * 0.6)
            if n > 0.64: c = SCUM if M.hsh(x, z, 1) > 0.3 else lerp(SCUM, WATER, 0.4)     # nata
            if M.hsh(x, z, 2) > 0.996: c = LEAF
            if 20 < x < 60 and -60 < z < -30 and (x + z) % 3 == 0: c = (0.42, 0.46, 0.40)   # reflejo
            M.put(x, WY, z, P, c)
    for _ in range(22):                                                               # hojas y basura flotando
        cx, cz = rng.randint(-90, 90), rng.randint(-90, 90)
        if octd(cx, cz) > R - T - 4 or math.hypot(cx, cz) < 40: continue
        col = LEAF if rng.random() < 0.7 else (0.62, 0.58, 0.48)
        for dx in range(-2, 3):
            for dz in range(-1, 2): M.put(cx + dx, WY + 1, cz + dz, P, col)
    # rocas de granito en el centro: unos bloques redondeados alrededor de uno alto y plano arriba
    rocks = [(0, 0, 30, FUENTE_ROCK_TOP, 26, 2.6), (-30, 16, 20, 22, 18, 2.3), (24, 22, 18, 18, 16, 2.4),
             (20, -26, 22, 24, 17, 2.2), (-22, -24, 16, 16, 14, 2.5), (38, -4, 14, 12, 12, 2.3)]
    for (cx, cz, rx, top, rz, pw) in rocks:
        for x in range(cx - rx - 3, cx + rx + 4):
            for z in range(cz - rz - 3, cz + rz + 4):
                for y in range(0, top + 1):
                    k = (y / max(top, 1))
                    wob = 1.0 + 0.14 * (M.noise(x, y, z, 7.0) - 0.5) * 2
                    rr = (1.0 - 0.35 * k ** 3) * wob                                   # se cierra arriba
                    if abs((x - cx) / (rx * rr)) ** pw + abs((z - cz) / (rz * rr)) ** pw > 1: continue
                    if y == top and abs((x - cx) / rx) ** pw + abs((z - cz) / rz) ** pw > 0.55 and M.hsh(x, z, 9) > 0.5: continue
                    c = lerp(GRANITE, GRANITE_D, 0.6 * M.noise(x, y, z, 4.0))
                    if M.hsh(x, y, z) > 0.93: c = lerp(c, (0.62, 0.58, 0.54), 0.6)    # cristales del granito
                    if WY - 2 <= y <= WY + 5: c = lerp(c, ALGAE, 0.7 * (1.0 - abs(y - WY - 1) / 5))   # algas en la línea del agua
                    if WY + 1 <= y <= WY + 6 and M.hsh(x, y, z + 7) > 0.88: c = (0.66, 0.64, 0.56)    # percebes
                    if y > WY + 6 and M.noise(x, y, z, 5.0) > 0.66: c = lerp(c, GREEN, 0.5)          # verdín
                    M.put(x, y, z, P, c, over=False)
    for k in range(26):                                                               # trozo del borde caído
        a = math.radians(38)
        for u in range(-13, 14):
            for y in range(0, 4):
                M.put(int((R + 22) * math.cos(a)) + u, y + 3, int((R + 22) * math.sin(a)) + k - 13, P, STONE_L if y == 3 else STONE)
    for x in range(60, 170):                                                          # charco que se sale por la grieta
        for z in range(40, 140):
            if octd(x, z) < R + 11: continue
            if M.noise(x, 0, z, 14.0) > 0.45 and math.hypot(x - 100, z - 85) < 48:
                M.put(x, 0, z, P, lerp(WATER, WATER_L, M.noise(x, 1, z, 3.0) * 0.5))
    x, y = int(R * 0.68), H
    for _ in range(22):                                                               # la grieta
        v = M.V.get((x, y, int(R * 0.73)))
        if v: v[1] = (0.12, 0.12, 0.11)
        y -= 1; x += rng.choice((-1, 0, 1))
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


def carretilla():
    """Carretilla de pescado (rehecha a 64/m en la revisión de arte del 13-10-2026): caja de tablas
    de tono propio con juntas, clavos y esquineras de hierro, tablas laterales abiertas en abanico,
    llena de pescado plateado (cada uno con su cuerpo, cola, aleta y ojo) sobre hielo picado y
    algas; rueda de radios con llanta de hierro y eje, varales gastados con los puños, patas con
    refuerzo, y gotas, escamas y un pescado caído en el suelo."""
    M = Model(S=4, seed=75)
    rng = M.rng
    X0, X1, Z0, Z1, Y0, Y1 = -44, 44, -28, 28, 24, 50
    BOARDS = [(0.44, 0.34, 0.24), (0.38, 0.29, 0.20), (0.50, 0.40, 0.28), (0.34, 0.26, 0.18)]
    def board(u, v, f):
        c = BOARDS[int(M.hsh(v // 6, f, 1) * 4)]
        if v % 6 == 0: c = lerp(c, DARK, 0.5)
        if v % 6 == 3 and u % 20 in (2, 18): c = IRON_L
        return lerp(c, (0.28, 0.32, 0.26), 0.3 * M.noise(u, v, f, 5.0))
    for x in range(X0, X1):                                         # caja (las paredes se abren hacia arriba)
        for z in range(Z0, Z1):
            for y in range(Y0, Y1):
                f = (y - Y0) / (Y1 - Y0)
                flare = int(6 * f)
                inside = X0 + 2 < x < X1 - 3 and Z0 + 2 < z < Z1 - 3
                if y > Y0 + 1 and inside: continue
                if y == Y0 or y == Y0 + 1: c = board(x, z, 0)
                elif x <= X0 + 2: c = board(z, y, 1)
                elif x >= X1 - 3: c = board(z, y, 2)
                else: c = board(x, y, 3 if z < 0 else 4)
                xx = x + (-flare if x <= X0 + 2 else (flare if x >= X1 - 3 else 0))
                zz = z + (-flare if z <= Z0 + 2 else (flare if z >= Z1 - 3 else 0))
                M.put(xx, y, zz, P, c)
    for (cx, cz) in ((X0, Z0), (X0, Z1 - 1), (X1 - 1, Z0), (X1 - 1, Z1 - 1)):   # esquineras
        for y in range(Y0, Y1):
            f = (y - Y0) / (Y1 - Y0); fl = int(6 * f)
            M.put(cx + (-fl - 1 if cx < 0 else fl + 1), y, cz + (-fl if cz < 0 else fl), P, IRON)
    for x in range(X0 + 4, X1 - 4):                                 # hielo picado y algas
        for z in range(Z0 + 4, Z1 - 4):
            y = Y1 - 6 + int(2 * M.noise(x, 0, z, 4.0))
            c = (0.78, 0.86, 0.90) if M.hsh(x, z, 1) > 0.3 else (0.62, 0.74, 0.80)
            if M.noise(x, 1, z, 5.0) > 0.7: c = (0.20, 0.30, 0.16)
            M.put(x, y, z, P, c)
    SILV = (0.68, 0.72, 0.74); SILV_D = (0.42, 0.46, 0.50); BLUE_B = (0.30, 0.38, 0.46)
    for _ in range(26):                                             # pescados
        cx, cz = rng.randint(X0 + 10, X1 - 12), rng.randint(Z0 + 8, Z1 - 8)
        cy = Y1 - 4 + rng.randint(0, 4)
        a = rng.uniform(0, math.pi); ca, sa = math.cos(a), math.sin(a)
        Lf = rng.randint(14, 20)
        for t in range(-Lf // 2, Lf // 2):
            w = int(3.2 * math.sqrt(max(0.0, 1 - (2 * t / Lf) ** 2)))
            for k in range(-w, w + 1):
                x = int(round(cx + t * ca - k * sa)); z = int(round(cz + t * sa + k * ca))
                c = BLUE_B if k < 0 else (SILV if k < w else SILV_D)
                M.put(x, cy, z, P, c); M.put(x, cy + 1, z, P, BLUE_B if k <= 0 else SILV)
        for k in range(-3, 4):                                       # cola
            M.put(int(round(cx - (Lf // 2 + 2) * ca - k * sa)), cy + 1, int(round(cz - (Lf // 2 + 2) * sa + k * ca)), P, SILV_D)
        ex, ez = int(round(cx + (Lf // 2 - 3) * ca + 1 * sa)), int(round(cz + (Lf // 2 - 3) * sa - 1 * ca))
        M.put(ex, cy + 2, ez, P, DARK)                               # ojo
    for a in range(0, 360, 2):                                      # rueda de radios
        t = math.radians(a)
        for r in range(0, 21):
            spoke = a % 45 < 4 or r < 3
            if r < 18 and not spoke: continue
            c = IRON if r >= 19 else (WOOD_D if r >= 17 or spoke else WOOD)
            for z in (-2, -1, 0, 1): M.put(int(round(52 + r * math.cos(t))), int(round(21 + r * math.sin(t))), z, P, c)
    for x in range(40, 56):                                         # horquilla
        for s in (-1, 1): M.put(x, 21 + (x - 52) // 4 + 6, s * 4, P, IRON)
    for s in (-1, 1):                                               # varales, puños y patas
        z = s * 24
        for x in range(-88, X0 + 4):
            y = 44 + (x + 44) // 5
            for dz in (0, s): M.put(x, y, z + dz, P, WOOD_D if x > -78 else lerp(WOOD_D, (0.6, 0.5, 0.36), 0.4))
        for y in range(0, Y0):
            for dx in (0, 1): M.put(-36 + dx, y, z, P, WOOD_D)
        for k in range(14): M.put(-36 + k, 6 + k, z, P, WOOD_D)
    for _ in range(30):                                             # gotas y escamas en el suelo
        M.put(rng.randint(-60, 70), 0, rng.randint(-40, 40), P, (0.40, 0.48, 0.52) if rng.random() < 0.6 else SILV)
    for t in range(-8, 8):                                          # pescado caído
        for k in range(-2, 3):
            M.put(60 + t, 0, 30 + k + t // 4, P, SILV if k > -1 else BLUE_B)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


def cajas(variant=1):
    """Cajas del puerto de Innsmouth (rehechas a 64/m y en tres variantes en la revisión de arte
    del 13-10-2026), con las cajas de tablas de gen_atrezo_alert (cada tabla de su marrón, veta,
    nudos, clavos, listones, tornapuntas y cantoneras):
      1  cajas de pescado abiertas, apiladas, con el pescado plateado sobre hielo y una tapa caída
      2  dos cajas grandes y una pequeña encima, atadas con cabo, con un saco de sal al lado
      3  una caja reventada (tablas sueltas y la carga desparramada) junto a dos enteras y un barrilete"""
    from gen_atrezo_alert import _crate
    M = Model(S=4, seed=76 + variant)
    rng = M.rng
    SILV = (0.66, 0.70, 0.72); BLUE_B = (0.30, 0.38, 0.46); ICE = (0.80, 0.86, 0.90)
    def _h(a, b): return ((a * 73856093) ^ (b * 19349663)) % 1000 / 1000.0
    def fish_box(x0, y0, z0, w, h, d, seed):
        _crate(M, x0, x0 + w, y0, y0 + h, z0, z0 + d, seed, brace='h', stencil=False)
        for x in range(x0 + 2, x0 + w - 2):                          # abierta: fuera la tapa, dentro hielo y peces
            for z in range(z0 + 2, z0 + d - 2):
                M.V.pop((x, y0 + h - 1, z), None)
                M.put(x, y0 + h - 4, z, P, ICE if _h(x, z) > 0.3 else (0.66, 0.74, 0.80))
        for _ in range(w * d // 60):
            cx, cz = rng.randint(x0 + 6, x0 + w - 7), rng.randint(z0 + 5, z0 + d - 6)
            a = rng.uniform(0, math.pi); ca, sa = math.cos(a), math.sin(a)
            for t_ in range(-6, 7):
                for k in range(-2, 3):
                    if abs(k) > 2 * math.sqrt(max(0, 1 - (t_ / 7) ** 2)): continue
                    M.put(int(cx + t_ * ca - k * sa), y0 + h - 3, int(cz + t_ * sa + k * ca), P, SILV if k > -1 else BLUE_B)
    if variant == 1:
        fish_box(-40, 0, -24, 40, 22, 30, 1)
        fish_box(4, 0, -20, 38, 22, 30, 2)
        fish_box(-22, 22, -22, 40, 22, 30, 3)
        for x in range(10, 44):                                       # tapa caída
            for z in range(18, 44): M.put(x, 0 + (1 if x > 26 else 0), z, P, (0.40, 0.30, 0.20) if (z - 18) % 6 else (0.24, 0.16, 0.10))
    elif variant == 2:
        _crate(M, -44, 0, 0, 40, -26, 20, 4, brace='x')
        _crate(M, 2, 44, 0, 36, -24, 18, 5, brace='z', stencil=False)
        _crate(M, -16, 14, 40, 60, -14, 10, 6, brace='h')
        for x in range(-46, 46):                                      # cabo que las ata
            for zz in (-4, 6):
                y = 61 if -16 <= x < 14 else (41 if x < 0 else 37)
                M.put(x, y, zz, P, ROPE_C if x % 3 else (0.40, 0.34, 0.22))
        for y in range(0, 26):                                        # saco de sal
            for x in range(46, 66):
                for z in range(-10, 10):
                    if ((x - 56) / 10) ** 2 + ((y - 11) / 13) ** 2 + (z / 9) ** 2 < 1:
                        M.put(x, y, z, P, (0.80, 0.78, 0.72) if (x + y + z) % 2 else (0.70, 0.68, 0.62))
    else:
        _crate(M, -46, -10, 0, 30, -24, 8, 7, brace='x')
        _crate(M, -40, -12, 30, 52, -20, 4, 8, brace='h', stencil=False)
        for k in range(9):                                            # caja reventada: tablas sueltas
            a = rng.uniform(0, math.pi); L = rng.randint(18, 34)
            cx, cz = rng.randint(4, 40), rng.randint(-20, 30)
            for t_ in range(L):
                for w in range(4):
                    M.put(int(cx + t_ * math.cos(a) - w * math.sin(a)), (k % 3) * 2, int(cz + t_ * math.sin(a) + w * math.cos(a)), P,
                          (0.42, 0.32, 0.22) if t_ % 9 else (0.24, 0.16, 0.10))
        for _ in range(40):                                           # carga desparramada (latas y pescado seco)
            x, z = rng.randint(0, 50), rng.randint(-24, 34)
            c = (0.56, 0.56, 0.58) if rng.random() < 0.5 else (0.62, 0.54, 0.38)
            for dx in range(3):
                for dz in range(3): M.put(x + dx, 1 + (1 if dx == 1 and dz == 1 else 0), z + dz, P, c)
        for y in range(0, 30):                                        # barrilete
            r = 9 + (2 if 8 < y < 22 else 0)
            for x in range(-r, r + 1):
                for z in range(-r, r + 1):
                    d = x * x + z * z
                    if d > r * r or (d < (r - 2) ** 2 and 0 < y < 29): continue
                    c = IRON if y in (4, 5, 24, 25) else ((0.42, 0.30, 0.18) if (math.atan2(z, x) * 5) % 2 < 1 else (0.32, 0.22, 0.12))
                    M.put(52 + x, y, -20 + z, P, c)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


ROPE_C = (0.56, 0.49, 0.34)


def nasa():
    """Nasa de langostas (rehecha a 64/m en la revisión de arte del 13-10-2026): base de listones,
    tres arcos de madera doblada, listones a lo largo con huecos, red de cuerda en los extremos con
    la boca de embudo, un ladrillo de lastre dentro, cabo atado con una boya pintada, algas y
    restos de sal."""
    M = Model(S=4, seed=77)
    L, R = 36, 22
    for x in range(-L, L + 1):                                         # base de listones
        for z in range(-R, R + 1):
            if (z + R) % 6 < 4 and abs(x) < L + 1:
                c = lerp(SLAT, SLAT_D, M.hsh(0, (z + R) // 6, 1) * 0.7)
                if x in (-L, L): c = SLAT_D
                M.put(x, 0, z, P, c); M.put(x, 1, z, P, c)
    for ax in (-L, 0, L):                                              # arcos
        for a in range(0, 181, 2):
            t = math.radians(a)
            for dr in (0, 1, 2):
                M.put(ax, 2 + (R - dr) * math.sin(t), (R - dr) * math.cos(t), P, SLAT_D if a % 30 else SLAT)
                M.put(ax + 1, 2 + (R - dr) * math.sin(t), (R - dr) * math.cos(t), P, SLAT_D)
    for a in range(10, 171, 16):                                       # listones a lo largo
        t = math.radians(a)
        for x in range(-L, L + 1):
            for w in (0, 1, 2):
                tt = t + w * 0.03
                M.put(x, 2 + R * math.sin(tt), R * math.cos(tt), P, lerp(SLAT, SLAT_D, M.hsh(a, x // 9, 2) * 0.6))
    for ex, sg in ((-L, 1), (L, -1)):                                  # red de los extremos con boca de embudo
        for z in range(-R + 1, R):
            for y in range(2, R + 2):
                if z * z + (y - 2) ** 2 > (R - 1) ** 2: continue
                d = math.hypot(z, y - 2 - R * 0.35)
                if d < 6: continue                                     # boca
                funnel = int(max(0, 12 - d) * 0.8)
                if (z + y) % 4 == 0 or (z - y) % 4 == 0: M.put(ex + sg * funnel, y, z, P, NET_K)
    for x in range(-6, 6):                                             # ladrillo de lastre
        for z in range(-4, 4):
            for y in range(2, 7): M.put(x, y, z, P, BRICK_W if (x + y) % 5 else lerp(BRICK_W, (0.2, 0.15, 0.12), 0.5))
    for k in range(60):                                                 # cabo y boya
        t = k / 59
        M.put(L + 2 + t * 30, 3 + 18 * (1 - t) * t * 4 * 0.2, 6 + t * 18, P, ROPE if k % 3 else lerp(ROPE, NET_K, 0.5))
    bx, bz = L + 34, 26
    for x in range(bx - 6, bx + 7):
        for y in range(0, 14):
            for z in range(bz - 6, bz + 7):
                if ((x - bx) / 6) ** 2 + ((y - 6) / 7) ** 2 + ((z - bz) / 6) ** 2 > 1: continue
                M.put(x, y, z, P, BUOY_W if 5 <= y <= 7 else BUOY)
    for (x, y, z), v in list(M.V.items()):                             # algas y sal
        if v[1] in (SLAT, SLAT_D) or (isinstance(v[1], tuple) and v[0] == P and y < 6):
            if M.noise(x, y, z, 5.0) > 0.72: v[1] = lerp(v[1], (0.18, 0.30, 0.14), 0.7)
            elif M.noise(x, y, z, 2.0) > 0.88: v[1] = lerp(v[1], (0.80, 0.80, 0.76), 0.5)
    return M, {P: [0, 0, 0]}


def pilote_alto():
    """Pilote del agua, un 50 % más alto (16-10-2026): el mismo, con 1,9 m."""
    return pilote(1.5)


def pilote(k=1.0):
    """Pilote del muelle (rehecho a 64/m en la revisión de arte del 13-10-2026): tronco gris
    curtido con vetas y grietas, la cabeza rajada y gastada, dos zunchos de hierro oxidado con
    regueros, una cornamusa de hierro, la franja de la marea con verdín, algas que cuelgan y
    percebes abajo, y un cabo dado de vueltas con su nudo y el chicote colgando."""
    M = Model(S=4, seed=78)
    H, R = int(80 * k), 10.5
    def zy(y): return int(round(y * k))                                # lo de arriba sube con el pilote
    for y in range(0, H):
        r = R - (1.5 if y > H - 4 else 0)
        for x in range(-12, 13):
            for z in range(-12, 13):
                d = math.hypot(x + 0.5, z + 0.5)
                if d > r: continue
                if y > H - 4 and M.hsh(x // 2, 9, z // 2) > 0.7: continue            # cabeza gastada
                a = math.atan2(z + 0.5, x + 0.5)
                c = lerp(WOOD_G, BARK_PD, 0.5 * M.noise(math.cos(a) * 6, y * 0.12, math.sin(a) * 6, 1.0))
                if int((a + math.pi) * 9 + y * 0.05) % 7 == 0: c = BARK_PD                 # vetas
                if y >= H - 1 and d < r - 1:                                               # cabeza: anillos y raja
                    c = lerp(WOOD_G, BARK_PD, 0.6) if int(d) % 2 else WOOD_G
                    if abs(x - z * 0.3) < 1: c = (0.08, 0.07, 0.06)
                if y < 26:                                                                 # marea: verdín, algas, percebes
                    c = lerp(c, SLIME_P, 0.6 + 0.3 * M.noise(x, y, z, 3.0))
                    if y < 18 and M.hsh(x, y, z) > 0.8: c = BARN if M.hsh(x, 2, z) > 0.4 else (0.40, 0.38, 0.33)
                if y in [zy(q) for q in (46, 64)] + [zy(q) + 1 for q in (46, 64)] + [zy(q) + 2 for q in (46, 64)] and d > r - 1.5: c = IRON if M.hsh(x, y, z) > 0.25 else RUST
                M.put(x, y, z, P, c)
    for y in range(32, 46):                                            # regueros de óxido bajo los zunchos
        for a in range(0, 360, 40):
            if M.hsh(a, 1, 1) > 0.5:
                x, z = int(round(R * math.cos(math.radians(a)))), int(round(R * math.sin(math.radians(a))))
                v = M.V.get((x, y, z))
                if v: v[1] = lerp(v[1], RUST, 0.5 * (y - 32) / 14)
    for k in range(10):                                                 # algas colgando
        a = math.radians(k * 36 + 10)
        for j in range(4 + k % 4):
            M.put(int(round((R + 0.5) * math.cos(a))), 26 - j, int(round((R + 0.5) * math.sin(a))), P, SLIME_P)
    for x in range(-4, 5):                                              # cornamusa
        for y in (56, 57):
            M.put(x, y, 11, P, IRON); M.put(x, y, 12, P, IRON)
    for x in (-2, 2): M.put(x, 55, 11, P, IRON); M.put(x, 54, 11, P, IRON)
    for turn in range(3):                                               # cabo dado de vueltas
        yy = 58 + turn * 3
        for a in range(0, 360, 4):
            t = math.radians(a)
            M.put(int(round(12 * math.cos(t))), yy + a // 180, int(round(12 * math.sin(t))), P, ROPE if (a // 12) % 2 else lerp(ROPE, (0.3, 0.26, 0.18), 0.4))
    for k in range(40):                                                 # chicote que cuelga y cae al suelo
        y = max(0, 60 - k * 1.5)
        M.put(12 + k // 8, y, 2 + k // 4, P, ROPE)
    return M, {P: [0, 0, 0]}


def coche():
    """Coche cerrado de los años 20 abandonado (rehecho a 64/m en la revisión de arte del
    13-10-2026), 4 x 1,7 m: carrocería negra con perfil de sedán (capó largo con persianas,
    parabrisas vertical partido, techo con la lona rasgada, cabina con cuatro ventanillas, alguna
    rota), guardabarros curvos unidos por el estribo, radiador con su calandra y tapón, faros en
    una barra, bocina, ruedas de radios de madera con un neumático deshinchado, rueda de repuesto
    detrás, parachoques, manillas, matrícula, óxido, barro, un cristal roto en el suelo y hierbajos
    que crecen entre las ruedas. Delante, +x."""
    M = Model(S=4, seed=79)
    rng = M.rng
    BODY = (0.11, 0.12, 0.13); BODY_L = (0.20, 0.21, 0.22); TRIM_C = (0.56, 0.56, 0.54)
    SPOKE = (0.48, 0.38, 0.24); RAG = (0.16, 0.15, 0.13); SEAT = (0.30, 0.20, 0.14); WEED_C = (0.30, 0.38, 0.18)
    L, HW = 128, 50                                       # media eslora y media manga (64/m)
    FB = 36                                               # dónde acaba la cabina y empieza el capó
    FL = 28                                               # altura del piso de la carrocería
    CAB = 104                                             # altura del techo
    BELT = 64                                             # cintura (bajo las ventanillas)
    def body_col(x, y, z):
        c = BODY if (y // 10) % 6 else BODY_L
        if y < FL + 10: c = lerp(c, (0.28, 0.24, 0.18), 0.4 * M.noise(x, y, z, 3.0) + 0.2)  # barro
        return c
    # cabina
    for x in range(-L + 10, FB):
        rb = max(0.0, 1 - (x + L - 10) / 14.0)                # trasera redondeada
        for y in range(FL, CAB + 1):
            hw = HW - 6 - int(6 * rb * (y > CAB - 20)) - (2 if y > CAB - 4 else 0)
            for z in range(-hw, hw):
                edge = min(x + L - 10, FB - 1 - x, z + hw, hw - 1 - z) <= 1 or y == CAB
                if not edge: continue
                side = z in (-hw, hw - 1)
                c = body_col(x, y, z)
                if BELT - 2 <= y <= BELT: c = TRIM_C                                         # moldura de la cintura
                if side and BELT + 4 <= y < CAB - 6:
                    k = (x + L - 18) % 34
                    if 4 <= k < 30 and x < FB - 8:
                        broken = M.hsh((x + L) // 34, z, 9) < 0.35
                        if broken and M.noise(x, y, z, 7.0) > 0.5: continue                    # cristal roto: hueco irregular
                        c = GLASS if (x + y) % 9 else (0.34, 0.40, 0.42)
                    elif k in (0, 1, 2, 3, 30, 31, 32, 33): c = BODY_L                         # montantes
                if side and 12 <= (x + L) - 34 * 1 < 40 and y == BELT - 6: c = TRIM_C           # manilla
                if y == CAB:                                                                    # techo de lona rasgada
                    c = RAG if M.noise(x, y, z, 6.0) < 0.62 else DARK
                    if M.noise(x, y, z, 6.0) > 0.7: continue
                M.put(x, y, z, P, c)
    for y in range(BELT + 2, CAB - 4):                                                        # parabrisas partido
        for z in range(-HW + 8, HW - 8):
            c = GLASS
            if z in (-1, 0) or y in (BELT + 2, CAB - 5): c = BODY_L
            if M.hsh(y // 4, z // 4, 5) > 0.85: c = (0.40, 0.46, 0.48)                     # grieta
            M.put(FB, y, z, P, c)
    for a in range(0, 360, 10):
        M.put(FB - 10, int(BELT + 8 + 7 * math.sin(math.radians(a))), int(-20 + 7 * math.cos(math.radians(a))), P, DARK)
    # capó con persianas y calandra
    for x in range(FB, L - 8):
        t = (x - FB) / (L - 8 - FB)
        top = int(BELT + 2 - 6 * t)
        for y in range(FL + 4, top + 1):
            hw = 28 if y < top - 3 else 26
            for z in range(-hw, hw):
                if min(z + hw, hw - 1 - z) > 1 and y < top: continue
                c = body_col(x, y, z)
                if y == top and abs(z + 0.5) < 1.5: c = TRIM_C                                 # bisagra
                if z in (-hw, hw - 1) and BELT - 22 <= y < BELT - 8 and (x - FB) % 6 in (0, 1) and 10 < x - FB < 60: c = DARK   # persianas
                M.put(x, y, z, P, c)
    for y in range(FL + 4, BELT + 6):                                                         # calandra del radiador
        for z in range(-28, 28):
            frame = z in (-28, -27, 26, 27) or y in (FL + 4, BELT + 5, BELT + 4)
            M.put(L - 8, y, z, P, TRIM_C if frame else (IRON if (y + z) % 3 else DARK))
            M.put(L - 7, y, z, P, TRIM_C if frame else IRON)
    for y in range(BELT + 6, BELT + 12):                                                      # tapón con mascota
        for z in (-1, 0): M.put(L - 10, y, z, P, TRIM_C)
    # guardabarros, estribos, faros, bocina y parachoques
    wheels = (L - 30, -L + 34)
    for cx in wheels:
        for s in (-1, 1):
            zf = s * HW
            for a in range(0, 181, 2):
                ang = math.radians(a)
                for rr in (30, 31, 32):
                    x = int(round(cx + rr * math.cos(ang) * 1.15)); y = int(round(24 + rr * math.sin(ang) * 0.9))
                    for dz in range(0, 18):
                        M.put(x, y, zf - s * dz, P, body_col(x, y, zf))
    for x in range(-L + 64, L - 62):                                                          # estribo
        for s in (-1, 1):
            for dz in range(0, 14):
                M.put(x, 24, s * (HW - dz), P, RAG if (x // 3) % 2 else DARK); M.put(x, 23, s * (HW - dz), P, BODY)
    for zc in (-22, 22):                                                                      # faros en su barra
        for y in range(BELT - 6, BELT + 10):
            for z in range(zc - 8, zc + 8):
                for x in (L - 4, L - 3):
                    d = (y - BELT - 2) ** 2 + (z - zc + 0.5) ** 2
                    if d > 64: continue
                    c = TRIM_C if d > 40 else ((0.80, 0.78, 0.66) if M.hsh(y, z, 1) > 0.3 else DARK)
                    M.put(x + (1 if d <= 40 else 0), y, z, P, c)
    for z in range(-26, 26): M.put(L - 5, BELT - 8, z, P, TRIM_C)
    for x in range(L - 14, L - 6):                                                            # bocina
        for y in range(BELT - 4, BELT):
            M.put(x, y, -34, P, TRIM_C)
    for z in range(-HW, HW):                                                                  # parachoques
        for y in (FL - 2, FL - 1, FL + 2, FL + 3):
            M.put(L + 2, y, z, P, TRIM_C); M.put(-L + 6, y, z, P, TRIM_C)
    for y in range(FL + 6, FL + 14):                                                          # matrícula
        for z in range(-12, 12): M.put(-L + 9, y, z, P, (0.56, 0.52, 0.40) if y not in (FL + 6, FL + 13) else DARK)
    for z in (-HW + 6, HW - 7):                                                               # piloto trasero
        for y in range(FL + 10, FL + 16): M.put(-L + 9, y, z, P, (0.50, 0.08, 0.06))
    # ruedas de radios de madera (la delantera derecha, deshinchada) y rueda de repuesto
    def wheel(cx, cy, zc, axis_z=True, flat=False):
        for a in range(-28, 29):
            for b in range(-28, 29):
                r = math.hypot(a, b)
                if r > 26: continue
                if flat and b < -18: continue
                ang = math.degrees(math.atan2(b, a)) % 30
                if r > 20: c = TIRE if (r < 25 or M.hsh(a, b, 2) > 0.2) else DARK
                elif r > 18: c = IRON
                elif r < 5: c = TRIM_C if r < 3 else IRON
                elif ang < 7 or ang > 23: c = SPOKE
                else: continue
                yy = cy + b + (3 if flat else 0)
                for d in range(0, 8):
                    if axis_z: M.put(cx + a, yy, zc + d, P, c)
                    else: M.put(cx - d, yy, zc + a, P, c)
    for cx in wheels:
        for s in (-1, 1):
            wheel(cx, 26, s * HW - (8 if s > 0 else 0), flat=(cx > 0 and s > 0))
    wheel(-L + 4, FL + 34, 0, axis_z=False)
    # cristales rotos en el suelo y hierbajos entre las ruedas
    for _ in range(40):
        x, z = rng.randint(-L, L), rng.choice((-1, 1)) * rng.randint(HW + 2, HW + 20)
        M.put(x, 0, z, P, (0.40, 0.48, 0.50))
    for _ in range(50):
        x, z = rng.randint(-L, L), rng.randint(-HW - 10, HW + 10)
        for k in range(rng.randint(4, 18)):
            M.put(x + (k // 6) * rng.choice((-1, 1)), k, z, P, WEED_C if k % 3 else REED_D, over=False)
    _weather(M, {BODY, BODY_L}, rust_scale=5.0)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


PIECES = {'casa': casa, 'casa_2': lambda: casa(2), 'autobus': autobus, 'poste': poste, 'valla': valla, 'barril': barril,
          'redes': redes, 'barca': barca, 'farola': farola, 'juncos': juncos,
          'fachada': fachada, 'templo_v1': templo, 'escombros_mano': escombros, 'escombros': escombros_v2, 'fuente_v1': fuente_v1, 'fuente': fuente, 'pilote_alto': pilote_alto,
          'carretilla': carretilla, 'cajas': cajas, 'cajas_2': lambda: cajas(2), 'cajas_3': lambda: cajas(3), 'nasa': nasa, 'pilote': pilote, 'coche': coche}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/inn_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('inn_%s: %d voxels' % (name, n))
