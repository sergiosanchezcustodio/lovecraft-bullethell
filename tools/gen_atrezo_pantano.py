"""Atrezo de los pantanos y la vía muerta a Rowley (hito 6.4). Una parte "body", origen en el
centro de la base, como gen_atrezo_innsmouth.py.

  via        tramo de vía de 4 m a lo largo de x: traviesas podridas (alguna falta) y dos raíles
             oxidados. Todo por debajo de 0,15 m: se anda por encima (32/m)
  vagoneta   vagón de mercancías volcado de lado, tablas, ruedas al aire y la puerta caída (32/m)
  senal      poste de señales con su brazo de semáforo y el farol rojo (pivote "light") (48/m)
  apeadero   la caseta del apeadero de Rowley: tablas, tejado de chapa, andén y el letrero (32/m)
  arbol_1/2  árbol muerto del pantano, retorcido y sin hojas, con musgo colgando (32/m)
  tocon      tocón podrido con raíces (32/m)
  caballete  tramo del puente de caballetes roto: pies, riostras y vigas caídas (32/m)

Escribe models/pan_<pieza>.json. Uso: python tools/gen_atrezo_pantano.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
SLEEPER = (0.30, 0.24, 0.18); SLEEPER_D = (0.20, 0.16, 0.12); ROT = (0.24, 0.28, 0.18)
RAIL = (0.30, 0.20, 0.13); RAIL_L = (0.46, 0.30, 0.18); IRON = (0.15, 0.15, 0.16); IRON_L = (0.28, 0.28, 0.29)
WAGON = (0.40, 0.20, 0.15); WAGON_D = (0.29, 0.14, 0.11); WAGON_L = (0.50, 0.30, 0.22)
BOARD = (0.46, 0.43, 0.38); BOARD_D = (0.34, 0.32, 0.28); BOARD_G = (0.30, 0.34, 0.28)
ROOF = (0.19, 0.20, 0.21); ROOF_D = (0.14, 0.15, 0.16)
BARK = (0.24, 0.22, 0.20); BARK_D = (0.16, 0.15, 0.14); BARK_L = (0.36, 0.34, 0.31)
MOSS = (0.36, 0.40, 0.28); MOSS_D = (0.26, 0.30, 0.20)
SIGN = (0.80, 0.78, 0.70); RED = (0.62, 0.12, 0.10); WHITE = (0.80, 0.78, 0.72)
DARK = (0.05, 0.05, 0.06)
LAMP = (1.0, 0.36, 0.20)


def box(M, x0, x1, y0, y1, z0, z1, col):
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                M.put(x, y, z, P, col(x, y, z) if callable(col) else col)


def line(M, a, b, r, col):
    """Cilindro de a a b (voxels) de radio r, con color fijo o función."""
    n = int(max(abs(b[i] - a[i]) for i in range(3))) + 1
    for k in range(n + 1):
        t = k / max(n, 1)
        cx, cy, cz = (a[i] + (b[i] - a[i]) * t for i in range(3))
        ri = int(math.ceil(r))
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    if x * x + y * y + z * z > r * r + 0.3: continue
                    q = (int(round(cx + x)), int(round(cy + y)), int(round(cz + z)))
                    M.put(*q, P, col(*q) if callable(col) else col)


# ---------------- vía ----------------

def via():
    """4 m de vía (x de -64 a 64 a 32/m). Traviesas de 2,4 x 0,22 m cada 0,6 m (2 voxels de
    alto); raíles de 2 voxels encima a 1,44 m entre sí. Alguna traviesa falta o está partida."""
    M = Model(S=2, seed=81)
    for i, x0 in enumerate(range(-62, 62, 19)):
        h = M.hsh(i, 0, 1)
        if h < 0.12: continue                                     # falta la traviesa
        broken = h > 0.85
        for x in range(x0, x0 + 7):
            for z in range(-38, 38):
                if broken and -6 < z < 4: continue                # partida en dos
                c = lerp(SLEEPER, SLEEPER_D, M.noise(x, 0, z, 6.0))
                if M.noise(x, 3, z, 4.0) > 0.72: c = ROT
                for y in range(2): M.put(x, y, z, P, c)
    for zr in (-24, 23):                                          # raíles: patín, alma y cabeza
        for x in range(-64, 64):
            if zr > 0 and 30 < x < 44: continue                   # un tramo de raíl arrancado
            rust = lerp(RAIL, RAIL_L, M.noise(x, 2, zr, 5.0))
            for z in (zr - 1, zr, zr + 1): M.put(x, 2, z, P, rust)
            M.put(x, 3, zr, P, RAIL_L if M.hsh(x, 3, zr) > 0.6 else rust)
    return M, {P: [0, 0, 0]}


# ---------------- vagoneta ----------------

def vagoneta():
    """Vagón de mercancías de caja roja volcado sobre su costado: la caja tumbada (3,6 m de
    largo, 1,5 de alto tumbada), el bastidor y las ruedas hacia +z, la puerta corredera caída
    al suelo. Hueco."""
    M = Model(S=2, seed=82)
    L, H, W = 58, 48, 34                                          # medio largo, alto tumbado, ancho
    def plank(x, y, z):
        if (y + z) % 5 == 0: return WAGON_D
        return lerp(WAGON, WAGON_L, 0.6 * M.noise(x, y, z, 8.0)) if M.noise(x, y, z, 3.0) < 0.82 else (0.30, 0.24, 0.18)
    for x in range(-L, L):
        for y in range(0, H):
            for z in range(-W, W):
                edge = min(x + L, L - 1 - x, y, H - 1 - y, z + W, W - 1 - z)
                if edge > 1: continue
                if y == H - 1 or y == H - 2:                       # el techo (ahora un lado) con una tabla rota
                    if -10 < x < 6 and -8 < z < 14: continue
                c = plank(x, y, z)
                if abs(x) in (L - 1, L - 2) or x in (-L // 3, L // 3): c = WAGON_D   # montantes
                M.put(x, y, z, P, c)
    for x in range(-L + 4, L - 4):                                 # bastidor de hierro hacia +z
        for y in (8, 9, H - 10, H - 9):
            M.put(x, y, W, P, IRON); M.put(x, y, W + 1, P, IRON)
    for cx in (-L + 12, -L + 26, L - 26, L - 12):                  # ruedas al aire
        for a in range(-9, 10):
            for b in range(-9, 10):
                r = math.hypot(a, b)
                if r > 9: continue
                c = IRON_L if r > 7.5 else (RAIL if r > 2 else IRON)
                for dz in range(W + 2, W + 5):
                    for yy in (12, H - 12): M.put(cx + a, yy + b, dz, P, c)
    for x in range(-14, 14):                                       # puerta corredera caída
        for z in range(-W - 22, -W - 2):
            M.put(x + int(0.2 * (z + W)), 0, z, P, plank(x, 0, z))
            if (x + 14) % 9 == 0: M.put(x + int(0.2 * (z + W)), 1, z, P, WAGON_D)
    return M, {P: [0, 0, 0]}


# ---------------- señal ----------------

def senal():
    """Semáforo ferroviario: poste de celosía de hierro, escalerilla, brazo rojo con franja
    blanca caído a 45° y el farol de aceite que aún arde en rojo (pivote "light")."""
    M = Model(S=3, seed=83)
    H = 190                                                        # 4 m
    box(M, -8, 8, 0, 8, -8, 8, (0.40, 0.39, 0.37))                 # zapata de hormigón
    for y in range(8, H):
        for x in (-3, 2):
            for z in (-3, 2): M.put(x, y, z, P, IRON)
        if y % 12 < 2:
            for k in range(-3, 3): M.put(k, y, -3, P, IRON_L); M.put(k, y, 2, P, IRON_L)
    for y in range(20, H - 20, 6):                                 # escalerilla
        for z in (-6, -5): M.put(-4, y, z, P, RUST if False else IRON_L)
    for k in range(0, 46):                                         # brazo caído
        x = 4 + k
        y = H - 16 - int(k * 0.9)
        for t in range(-3, 4):
            c = WHITE if 30 < k < 36 else RED
            M.put(x, y + t, -1, P, c); M.put(x, y + t, 0, P, c)
    LY = H - 26
    box(M, -10, -3, LY - 6, LY + 6, -4, 3, IRON)                   # farol
    for y in range(LY - 3, LY + 3):
        for z in range(-2, 1): M.put(-11, y, z, P, LAMP, glow=1)
    box(M, -11, -2, LY + 6, LY + 8, -5, 4, IRON)
    box(M, -4, 4, H, H + 4, -4, 4, IRON)
    return M, {P: [0, 0, 0], 'light': [-13, LY, -1]}


RUST = (0.42, 0.24, 0.13)


# ---------------- apeadero ----------------

def apeadero():
    """Apeadero de Rowley (rehecho a 32/m en la revisión de arte del 14-10-2026), 9 x 3 m de andén
    y caseta de 4 x 2,5 m. El tejado de chapa ondulada a un agua apoya en las paredes: los
    costados suben en trapecio hasta su cara de abajo, así que no queda ningún hueco entre pared y
    tejado. Andén de tablas con juntas, clavos, tablas podridas o que faltan, viga de canto y
    pilotes; caseta de tablas y tapajuntas con la pintura verde gris pelada, cantoneras, zócalo
    con verdín; puerta abierta con su marco y la hoja entornada; ventanilla de billetes tapiada
    con tablas en aspa; ventana lateral con cristales rotos; tejado que vuela sobre el andén con
    dos pies derechos, carrera y tornapuntas; canalón, chimenea de estufa con sombrerete; letrero
    blanco colgado; farol, tablón de horarios, banco, lecheras, carretilla de equipajes y
    hierbajos entre las tablas."""
    M = Model(S=2, seed=84)
    rng = M.rng
    PAINT = (0.40, 0.44, 0.40); PAINT_D = (0.30, 0.34, 0.31); BARE = (0.44, 0.39, 0.32); BARE_D = (0.32, 0.28, 0.22)
    TRIM_C = (0.70, 0.68, 0.60); TINR = (0.30, 0.31, 0.32); TINR_D = (0.20, 0.21, 0.22); RUSTC = (0.42, 0.24, 0.13)
    MOSSC = (0.30, 0.36, 0.20); GL = (0.20, 0.26, 0.30)
    PX, PZ, PT = 144, 48, 11                                         # andén: media eslora, media manga, cara de arriba
    X0, X1, ZB, ZF = -64, 64, -46, 31                                # caseta
    def roof_y(z): return 108 - (z + 56) // 4                         # cara de abajo del tejado
    def plank(x, y, z):
        k = (z + PZ) // 6
        c = lerp(BOARD, BOARD_G, 0.6 * M.noise(x * 0.3, k, 0, 2.0) + 0.3 * M.hsh(k, x // 40, 1))
        if (z + PZ) % 6 == 0: c = lerp(c, DARK, 0.6)                   # junta
        if (x + 7 * k) % 40 == 0: c = lerp(c, DARK, 0.5)                # testas
        if (x + 7 * k) % 40 in (2, 37) and (z + PZ) % 6 in (2, 4): c = IRON_L   # clavos
        if M.noise(x, y, z, 6.0) > 0.66: c = lerp(c, MOSSC, 0.5)
        return c
    # andén
    for x in range(-PX, PX):
        for z in range(-PZ, PZ):
            k = (z + PZ) // 6
            if M.hsh(k, (x + 7 * k) // 40, 2) < 0.04 and not (X0 - 4 <= x < X1 + 4 and ZB - 4 <= z < ZF + 4): continue   # tabla que falta
            sag = 1 if M.hsh(k, (x + 7 * k) // 40, 3) < 0.06 else 0                 # tabla hundida
            M.put(x, PT - sag, z, P, plank(x, PT, z))
            M.put(x, PT - 1 - sag, z, P, BOARD_D)
    for x in range(-PX, PX):                                          # viga de canto y faldón
        for y in range(4, PT - 1):
            for z in (-PZ, PZ - 1):
                M.put(x, y, z, P, BOARD_D if y in (4, PT - 2) else lerp(BOARD_D, ROT, 0.5 * M.noise(x, y, z, 4.0)))
    for z in range(-PZ, PZ):
        for y in range(4, PT - 1):
            for x in (-PX, PX - 1): M.put(x, y, z, P, BOARD_D)
    for x in range(-PX + 4, PX, 24):                                  # pilotes
        for z in (-PZ + 1, PZ - 2):
            for y in range(0, PT - 1):
                for dx in range(3):
                    M.put(x + dx, y, z + (1 if z > 0 else -1), P, lerp(SLEEPER_D, ROT, 0.4 if y < 4 else 0.1))
    # caseta: tablas verticales y tapajuntas, la pintura pelada
    def wall_c(x, y, z, u):
        c = PAINT if (u // 6) % 2 else lerp(PAINT, PAINT_D, 0.4)
        if M.noise(x, y, z, 5.0) > 0.62: c = BARE if M.hsh(x, y, z) > 0.3 else BARE_D   # pintura saltada
        if y < PT + 8: c = lerp(c, MOSSC, 0.4 + 0.3 * M.noise(x, y, z, 3.0))              # zócalo con verdín
        if M.hsh(u, y // 3, 9) > 0.985: c = lerp(c, DARK, 0.5)                           # vetas y grietas
        return c
    walls = []
    for y in range(PT + 1, roof_y(ZB) + 1):
        for x in range(X0, X1):
            for z in range(ZB, ZF + 1):
                if min(x - X0, X1 - 1 - x, z - ZB, ZF - z) > 1: continue
                if y > roof_y(z): continue                                               # costados en trapecio: llegan al tejado
                side = x - X0 <= 1 or X1 - 1 - x <= 1
                u = z if side else x
                out = (x == X0 or x == X1 - 1) if side else (z == ZB or z == ZF)
                c = wall_c(x, y, z, u)
                if out and u % 6 == 0: c = PAINT_D                                       # junta
                M.put(x, y, z, P, c)
                if out and u % 6 == 0:                                                   # tapajuntas
                    q = (x + (-1 if x == X0 else 1 if x == X1 - 1 else 0), y, z + (-1 if z == ZB and not side else 1 if z == ZF and not side else 0))
                    M.put(*q, P, PAINT_D if M.noise(x, y, z, 5.0) < 0.62 else BARE_D)
    for (cx, cz) in ((X0 - 1, ZB - 1), (X1, ZB - 1), (X0 - 1, ZF + 1), (X1, ZF + 1)):  # cantoneras
        for y in range(PT + 1, roof_y(cz) + 1):
            for d in range(3):
                M.put(cx + (d if cx < 0 else -d), y, cz, P, TRIM_C if M.noise(cx, y, cz, 4.0) < 0.6 else BARE)
                M.put(cx, y, cz + (d if cz < 0 else -d), P, TRIM_C if M.noise(cx, y, cz, 4.0) < 0.6 else BARE)
    # puerta abierta con marco y la hoja entornada
    DX0, DX1, DH = -18, 8, PT + 66
    for x in range(DX0 - 3, DX1 + 3):
        for y in range(PT + 1, DH + 4):
            inside = DX0 <= x < DX1 and y < DH
            for z in (ZF, ZF - 1, ZF + 1):
                if inside:
                    M.V.pop((x, y, z), None)
                elif z == ZF + 1 and (x < DX0 or x >= DX1 or y >= DH): M.put(x, y, z, P, TRIM_C if M.hsh(x, y, 4) > 0.2 else BARE)
            if inside: M.put(x, y, ZF - 8, P, (0.07, 0.07, 0.07))                         # interior en penumbra
    for i in range(DX1 - DX0):                                                           # hoja abierta hacia fuera
        a = math.radians(70)
        x, z = DX0 + int(i * math.cos(a)) - 1, ZF + 1 + int(i * math.sin(a))
        for y in range(PT + 2, DH - 1):
            c = lerp(PAINT, PAINT_D, 0.5) if i % 6 else PAINT_D
            if y in (PT + 20, DH - 14) or abs(y - PT - 20 - (DH - PT - 34) * i / (DX1 - DX0)) < 1.2: c = BARE_D   # travesaños y riostra
            M.put(x, y, z, P, c); M.put(x + 1, y, z, P, c)
    M.put(DX0 + 10, PT + 36, ZF + 10, P, IRON_L)
    # ventanilla de billetes tapiada
    WX0, WX1, WY0, WY1 = 20, 48, PT + 30, PT + 58
    for x in range(WX0 - 2, WX1 + 2):
        for y in range(WY0 - 3, WY1 + 2):
            frame = x < WX0 or x >= WX1 or y < WY0 or y >= WY1
            if frame:
                M.put(x, y, ZF + 1, P, TRIM_C if M.hsh(x, y, 5) > 0.15 else BARE)
                if y == WY0 - 3: M.put(x, y, ZF + 2, P, TRIM_C)                          # alféizar
            else:
                M.put(x, y, ZF, P, GL if (x + y) % 7 else (0.40, 0.46, 0.48))
    for k in range(2):                                                                   # tablas clavadas en aspa
        for i in range(WX1 - WX0 + 4):
            x = WX0 - 2 + i
            yc = WY0 + (i * (WY1 - WY0) // (WX1 - WX0 + 4) if k == 0 else (WY1 - WY0) - i * (WY1 - WY0) // (WX1 - WX0 + 4))
            for d in range(-2, 3):
                M.put(x, yc + d, ZF + 2 + k, P, lerp(BARE, BARE_D, 0.5 * M.noise(x, d, k, 3.0)) if abs(d) < 2 else BARE_D)
            if i in (1, WX1 - WX0 + 2): M.put(x, yc, ZF + 3 + k, P, IRON_L)
    # ventana lateral con cristales rotos (+x)
    for z in range(-30, -2):
        for y in range(PT + 30, PT + 60):
            frame = z in (-30, -29, -4, -3) or y in (PT + 30, PT + 31, PT + 58, PT + 59) or z in (-17, -16) or y in (PT + 44, PT + 45)
            if frame: M.put(X1, y, z, P, TRIM_C if M.hsh(z, y, 6) > 0.2 else BARE); continue
            pane = (z > -16) * 2 + (y > PT + 45)
            if pane in (1, 2) and M.hsh(z // 2, y // 2, pane) > 0.35: M.V.pop((X1 - 1, y, z), None); M.V.pop((X1 - 2, y, z), None); continue
            M.put(X1 - 1, y, z, P, GL if (z + y) % 5 else (0.38, 0.44, 0.46)); M.V.pop((X1, y, z), None)
    # tejado de chapa ondulada: asienta en las paredes y vuela sobre el andén
    RZ0, RZ1 = -54, 52
    for x in range(X0 - 6, X1 + 6):
        for z in range(RZ0, RZ1):
            y = roof_y(z) + 1
            c = TINR if (x // 2) % 2 else TINR_D                                         # ondas
            if M.noise(x * 0.5, 0, z, 6.0) > 0.6: c = lerp(c, RUSTC, 0.7)                # óxido
            if M.hsh(x // 2, z // 20, 7) > 0.92 and z > -20: c = lerp(c, RUSTC, 0.9)     # chorretón
            if (z - RZ0) % 30 == 0: c = TINR_D                                           # solapes de las chapas
            M.put(x, y + ((x // 2) % 2), z, P, c)
            M.put(x, y, z, P, TINR_D)
            if X0 <= x < X1 and ZB <= z <= ZF: continue
            M.put(x, y - 1, z, P, BOARD_D if (x // 8) % 2 else BOARD)                     # tablazón bajo el alero
    for x in range(X0 - 6, X1 + 6):                                                      # tabla de alero y canalón
        for y in range(roof_y(RZ1) - 2, roof_y(RZ1) + 3): M.put(x, y, RZ1, P, TRIM_C if M.hsh(x, y, 8) > 0.25 else BARE)
        for y in range(roof_y(RZ1) - 2, roof_y(RZ1) + 1):
            M.put(x, y, RZ1 + 2, P, RUSTC if M.noise(x, 0, 0, 5.0) > 0.6 else IRON_L)
        M.put(x, roof_y(RZ1) - 3, RZ1 + 1, P, IRON_L)
        for y in range(roof_y(RZ0) - 1, roof_y(RZ0) + 3): M.put(x, y, RZ0 - 1, P, BOARD_D)
    for s in (X0 - 7, X1 + 6):                                                           # tablas de los costados del tejado
        for z in range(RZ0 - 1, RZ1 + 1):
            for d in range(-2, 3): M.put(s, roof_y(z) + 1 + d, z, P, TRIM_C if M.hsh(z, d, 9) > 0.2 else BARE)
    for y in range(roof_y(RZ1) - 26, roof_y(RZ1) - 3):                                  # bajante
        M.put(X1 + 4, y, RZ1 + 2, P, IRON_L); M.put(X1 + 4, y, RZ1 + 3, P, IRON)
    # pies derechos, carrera y tornapuntas
    for px in (X0 - 2, X1 + 1):
        for y in range(PT + 1, roof_y(46)):
            for dx in range(3):
                for dz in range(3): M.put(px + dx - 1, y, 45 + dz, P, BOARD_D if dx == 1 else BOARD)
        for i in range(14):                                                              # tornapuntas
            M.put(px + (i if px < 0 else -i), roof_y(46) - 14 + i, 46, P, BOARD_D)
            M.put(px, roof_y(46) - 14 + i, 46 - i, P, BOARD_D)
    for x in range(X0 - 4, X1 + 4):
        for y in range(roof_y(46) - 3, roof_y(46)): M.put(x, y, 46, P, BOARD_D if y == roof_y(46) - 3 else BOARD)
    # chimenea de la estufa con sombrerete
    for y in range(roof_y(-34) - 2, roof_y(-34) + 22):
        for x in range(-44, -38):
            for z in range(-37, -31):
                if (x + 41) ** 2 + (z + 34) ** 2 <= 8: M.put(x, y, z, P, IRON if y % 8 else IRON_L)
    for x in range(-46, -35):
        for z in range(-39, -28):
            M.put(x, roof_y(-34) + 22, z, P, IRON); M.put(x, roof_y(-34) + 23, z, P, IRON_L) if abs(x + 41) + abs(z + 34) < 5 else None
    # letrero blanco colgado de la carrera (sin texto legible: letras en bloques)
    SY = roof_y(46) - 20
    for x in range(-40, 40):
        for y in range(SY, SY + 12):
            c = SIGN if M.noise(x, y, 0, 4.0) < 0.72 else lerp(SIGN, BOARD_D, 0.5)
            if x in (-40, 39) or y in (SY, SY + 11): c = BOARD_D
            elif SY + 3 <= y <= SY + 8 and -34 < x < 34 and (x + 34) % 11 < 7 and M.hsh((x + 34) // 11, (x + 34) % 11 // 2, y) > 0.25: c = DARK
            M.put(x, y, 47, P, c)
    for xc in (-30, 29):
        for y in range(SY + 12, roof_y(46) - 3): M.put(xc, y, 47, P, IRON_L if y % 2 else IRON)
    # farol apagado en su brazo, en la esquina
    for y in range(PT + 1, 74): M.put(-76, y, 40, P, IRON)
    for x in range(-76, -66): M.put(x, 72, 40, P, IRON)
    for y in range(58, 70):
        for x in range(-70, -64):
            for z in range(37, 43):
                edge = x in (-70, -65) or z in (37, 42) or y in (58, 69)
                M.put(x, y, z, P, IRON if (edge or y > 66) else (0.30, 0.34, 0.34))
    # tablón de horarios con papeles medio arrancados
    for x in range(-58, -28):
        for y in range(PT + 28, PT + 58):
            edge = x in (-58, -29) or y in (PT + 28, PT + 57)
            c = BOARD_D if edge else BOARD
            if not edge and (x + 56) % 7 < 5 and (y - PT - 30) % 9 < 7 and M.hsh((x + 56) // 7, (y - PT - 30) // 9, 3) > 0.35:
                c = (0.70, 0.66, 0.56) if M.hsh(x, y, 4) > 0.15 else (0.40, 0.36, 0.30)
            M.put(x, y, ZF + 2, P, c)
    # banco de tablas con patas de hierro
    for x in range(-132, -102):
        for z in range(30, 40):
            M.put(x, PT + 13, z, P, BOARD_D if (z - 30) % 3 == 0 else BOARD)
        for y in range(PT + 14, PT + 26): M.put(x, y, 40, P, BOARD if y % 4 else BOARD_D)
        if x in (-130, -105):
            for y in range(PT + 1, PT + 13): M.put(x, y, 32, P, IRON); M.put(x, y, 38, P, IRON)
    # lecheras
    for cx in (-100, -88):
        for y in range(PT + 1, PT + 23):
            r = 4 if y > PT + 17 else 6
            for x in range(cx - 7, cx + 8):
                for z in range(-38, -23):
                    if (x - cx) ** 2 + (z + 30) ** 2 <= r * r: M.put(x, y, z, P, IRON_L if y in (PT + 3, PT + 15, PT + 22) else IRON)
    # carretilla de equipajes con un baúl
    for x in range(72, 116):
        for z in range(10, 30): M.put(x, PT + 11, z, P, BOARD_D if x % 6 == 0 else BOARD)
        if x in (74, 112):
            for y in range(PT + 1, PT + 11): M.put(x, y, 12, P, IRON); M.put(x, y, 28, P, IRON)
    for x in range(110, 116):
        for y in range(PT + 11, PT + 38): M.put(x, y, 20, P, IRON)
    for x in range(78, 102):
        for y in range(PT + 12, PT + 25):
            for z in range(14, 26): M.put(x, y, z, P, (0.40, 0.26, 0.16) if (x + y) % 9 and y != PT + 20 else (0.26, 0.16, 0.10))
    # hierbajos entre las tablas y en las juntas
    for _ in range(90):
        x, z = rng.randint(-PX + 2, PX - 2), rng.randint(-PZ + 2, PZ - 2)
        if X0 - 2 <= x < X1 + 2 and ZB - 2 <= z < ZF + 2: continue
        z -= (z + PZ) % 6
        for k in range(rng.randint(2, 8)):
            M.put(x + (k // 3) * rng.choice((-1, 1)), PT + 1 + k, z, P, (0.32, 0.40, 0.20) if k % 2 else (0.24, 0.32, 0.16), over=False)
    nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]: del M.V[k]
    return M, {P: [0, 0, 0]}


# ---------------- árboles ----------------

def arbol(seed, H):
    """Árbol muerto del pantano: tronco retorcido que se estrecha, raíces que salen del agua,
    ramas desnudas que suben y se doblan, y barbas de musgo colgando."""
    M = Model(S=2, seed=seed)
    rng = M.rng
    def bark(x, y, z):
        if M.noise(x, y, z, 3.0) > 0.7: return BARK_L
        return lerp(BARK, BARK_D, M.noise(x, y, z, 7.0))
    for k in range(6):                                             # raíces
        a = k / 6 * math.tau + rng.uniform(-0.3, 0.3)
        line(M, (0, 10, 0), (math.cos(a) * 20, 0, math.sin(a) * 20), 2.2, bark)
    pts = [(0, 0, 0)]
    x = z = 0.0
    for y in range(0, H, 10):                                      # tronco retorcido
        x += rng.uniform(-2.5, 2.5); z += rng.uniform(-2.5, 2.5)
        pts.append((x, y, z))
    for i in range(1, len(pts)):
        r = 6.0 * (1 - i / len(pts)) + 1.5
        line(M, pts[i - 1], pts[i], r, bark)
    tips = []
    def branch(p, ang, up, length, r, depth):
        dx, dz = math.cos(ang), math.sin(ang)
        q = (p[0] + dx * length, p[1] + up * length, p[2] + dz * length)
        line(M, p, q, r, bark)
        if depth == 0 or r < 1.1:
            tips.append(q); return
        for _ in range(2):
            branch(q, ang + rng.uniform(-0.9, 0.9), max(up + rng.uniform(-0.3, 0.2), 0.1), length * 0.7, r * 0.6, depth - 1)
    for i in range(4):
        base = pts[int(len(pts) * rng.uniform(0.45, 0.85))]
        branch(base, rng.uniform(0, math.tau), rng.uniform(0.4, 0.9), rng.uniform(22, 34), 2.6, 2)
    branch(pts[-1], rng.uniform(0, math.tau), 0.8, 18, 2.0, 2)
    for t in tips + [p for p in tips[::2]]:                        # musgo colgando de las ramas
        n = rng.randint(10, 26)
        for k in range(n):
            for j in range(rng.randint(0, 2)):
                M.put(int(t[0]) + j, int(t[1]) - k, int(t[2]), P, MOSS if k % 3 else MOSS_D, over=False)
    return M, {P: [0, 0, 0]}


def arbol_1(): return arbol(85, 150)
def arbol_2(): return arbol(86, 110)


def tocon():
    M = Model(S=2, seed=87)
    def bark(x, y, z): return lerp(BARK, BARK_D, M.noise(x, y, z, 5.0))
    for k in range(5):
        a = k / 5 * math.tau + 0.4
        line(M, (0, 8, 0), (math.cos(a) * 14, 0, math.sin(a) * 14), 2.0, bark)
    for y in range(0, 22):
        r = 7 - y * 0.08
        for x in range(-8, 9):
            for z in range(-8, 9):
                d = math.hypot(x, z)
                if d > r: continue
                top = y == 21 - int(M.hsh(x // 2, 0, z // 2) * 5)
                if y > 21 - M.hsh(x // 2, 0, z // 2) * 5: continue      # corte astillado
                M.put(x, y, z, P, (0.40, 0.33, 0.24) if top and d < r - 1.5 else bark(x, y, z))
    return M, {P: [0, 0, 0]}


# ---------------- caballete ----------------

def caballete():
    """Tramo de puente de caballetes: tres pórticos de pies inclinados con riostras en aspa
    (a lo largo de z), la viga de arriba partida y dos traviesas caídas al agua."""
    M = Model(S=2, seed=88)
    def wood(x, y, z): return lerp(SLEEPER, SLEEPER_D, M.noise(x, y, z, 6.0)) if M.noise(x, y, z, 3.0) < 0.78 else ROT
    TOP = 70
    for i, x in enumerate((-40, 0, 40)):
        lean = 0 if i < 2 else 8                                    # el último pórtico se vence
        for z in (-26, -10, 9, 25):
            sx = 1 if z > 0 else -1
            line(M, (x, 0, z + sx * 6), (x + lean, TOP, z), 1.6, wood)
        line(M, (x, 12, -30), (x + lean, TOP - 10, 28), 1.0, wood)  # riostras en aspa
        line(M, (x, 12, 28), (x + lean, TOP - 10, -30), 1.0, wood)
        line(M, (x + lean, TOP, -32), (x + lean, TOP, 32), 1.8, wood)
    line(M, (-44, TOP + 3, -12), (10, TOP + 3, -12), 2.2, wood)      # vigas: una entera, otra partida
    line(M, (-44, TOP + 3, 12), (6, TOP + 3, 12), 2.2, wood)
    line(M, (8, TOP + 3, 12), (40, 6, 18), 2.2, wood)                # el trozo caído
    for x0, z0, a in ((22, -36, 0.3), (-20, 36, -0.5)):              # traviesas caídas
        for k in range(-20, 20):
            for w in range(-3, 4):
                M.put(int(x0 + k * math.cos(a) - w * math.sin(a)), 0, int(z0 + k * math.sin(a) + w * math.cos(a)), P, wood(k, 0, w))
    return M, {P: [0, 0, 0]}


PIECES = {'via': via, 'vagoneta': vagoneta, 'senal': senal, 'apeadero': apeadero,
          'arbol_1': arbol_1, 'arbol_2': arbol_2, 'tocon_mano': tocon, 'caballete': caballete}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/pan_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('pan_%s: %d voxels' % (name, n))
