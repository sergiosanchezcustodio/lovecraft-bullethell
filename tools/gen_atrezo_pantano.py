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
    """Vagón de mercancías volcado sobre su costado (revisión de arte del 14-10-2026; el de antes
    queda en models/pan_vagoneta_v1.json). A 48 voxels/m, mismas medidas (3,6 x 1,5 x 2,9 m): la
    caja de tablas verticales con ranuras, pintura roja óxido desvaída con la tabla al aire,
    escuadras y flejes de hierro en las esquinas, la franja con el rótulo borrado, la puerta
    corredera con sus tornapuntas en Z caída al lado con el carril, la pasarela del techo y la
    escalerilla, los dos bogies al aire con ballestas, cajas de grasa y ruedas de radios con
    pestaña, topes y enganche en las testas, tablas rotas con el interior oscuro, chorretones de
    óxido, verdín y barro con juncos al pie."""
    M = Model(S=3, seed=82)
    rng = M.rng
    L, H, W = 87, 72, 51                                           # medio largo, alto tumbado (lado), medio ancho
    RUSTS = (0.40, 0.22, 0.12)
    def plank(x, y, z, face):
        u = z if face == 'side' else (x if face != 'end' else z)
        board = (u + 2 * W) // 6
        c = lerp(WAGON, (0.62, 0.36, 0.26), 0.2 + 0.6 * M.hsh(board, 3, 5 if face == 'side' else 7))
        if (u + 2 * W) % 6 == 0: c = lerp(c, DARK, 0.55)                    # ranura entre tablas
        if M.noise(x, y, z, 5.0) > 0.74: c = lerp(SLEEPER, BARK_L, 0.4)      # pintura caída: madera
        if M.noise(x * 0.6, y * 2.5, z * 0.6, 4.0) > 0.78: c = lerp(c, RUSTS, 0.5)   # chorretón
        return c
    holes = [(rng.randint(-60, 40), rng.randint(-30, 20), rng.randint(6, 12), rng.randint(4, 9)) for _ in range(2)]
    for x in range(-L, L):
        for y in range(0, H):
            for z in range(-W, W):
                edge = min(x + L, L - 1 - x, y, H - 1 - y, z + W, W - 1 - z)
                if edge > 1: continue
                top = y >= H - 2                                       # el costado que mira al cielo
                face = 'side' if top or y <= 1 else ('end' if abs(x) >= L - 2 else 'roof')
                if top and any(abs(x - hx) < hw and abs(z - hz) < hh for hx, hz, hw, hh in holes): continue
                c = plank(x, y, z, face)
                if top and -W + 14 < z < -W + 22: c = lerp(c, (0.70, 0.66, 0.56), 0.45 if M.hsh(x // 3, 1, 1) > 0.4 else 0.1)   # franja del rótulo
                corner = (abs(x) >= L - 3) + (abs(z) >= W - 3) + (y <= 2 or y >= H - 3)
                if corner >= 2 or (abs(x) in range(L // 3 - 1, L // 3 + 2) and face != 'end'):
                    c = lerp((0.24, 0.20, 0.18), RUSTS, 0.4 * M.noise(x, y, z, 3.0))           # escuadras y montantes
                if y in (H - 1,) and abs(z) >= W - 3 and (x % 10 == 0): c = IRON_L               # remaches
                M.put(x, y, z, P, c)
    for (hx, hz, hw, hh) in holes:                                       # interior oscuro bajo las tablas rotas
        for x in range(hx - hw, hx + hw):
            for z in range(hz - hh, hz + hh):
                M.put(x, H - 6, z, P, lerp(DARK, SLEEPER_D, 0.3))
        for k in range(3):                                               # astillas que asoman
            M.put(hx + hw - 1, H, hz - hh + k * 3, P, BARK_L)
    # pasarela del techo (el techo mira a -z tumbado): tablón con listones
    for x in range(-L + 4, L - 4):
        for y in range(H // 2 - 5, H // 2 + 5):
            M.put(x, y, -W - 1, P, BOARD_D if (x // 4) % 2 else BOARD)
            if y in (H // 2 - 5, H // 2 + 4): M.put(x, y, -W - 2, P, IRON)
    for k in range(9):                                                   # escalerilla de la testa
        for y in range(8, H - 8):
            if y % 9 == 0: M.put(L, y, -W + 8 + k, P, IRON_L)
        M.put(L, 8 + k, -W + 8, P, IRON); M.put(L, 8 + k, -W + 16, P, IRON)
    for y in range(8, H - 8):
        M.put(L, y, -W + 8, P, IRON); M.put(L, y, -W + 16, P, IRON)
    # bastidor y bogies hacia +z
    for x in range(-L + 6, L - 6):
        for y in (12, 13, H - 14, H - 13):
            for dz in (0, 1, 2): M.put(x, y, W + dz, P, IRON)
    for x in range(-L + 6, L - 6, 3):
        for y in range(12, H - 12):
            if x % 30 == 0: M.put(x, y, W + 1, P, IRON)                  # traviesas del bastidor
    for bx in (-L + 26, L - 26):
        for x in range(bx - 22, bx + 22):                                # bastidor del bogie
            for y in (H // 2 - 2, H // 2 + 2):
                for dz in range(W + 3, W + 7): M.put(x, y, dz, P, IRON)
        for k in range(-3, 4):                                           # ballestas
            for x in range(bx - 8 + abs(k), bx + 8 - abs(k)):
                M.put(x, H // 2 + k, W + 8 + (3 - abs(k)) // 2, P, IRON_L if k % 2 else IRON)
        for cx in (bx - 14, bx + 14):                                    # ruedas con radios y pestaña
            for wy in (14, H - 14):
                for a2 in range(-14, 15):
                    for b2 in range(-14, 15):
                        r = math.hypot(a2, b2)
                        if r > 14: continue
                        ang = math.atan2(b2, a2)
                        if r > 12: c = IRON_L                                      # llanta
                        elif r > 10.5: c = IRON
                        elif r < 3: c = IRON_L                                    # cubo
                        elif abs(math.sin(4 * ang)) < 0.22: c = IRON              # radios
                        else: continue
                        for dz in range(W + 9, W + 13 + (2 if r > 13 else 0)):
                            M.put(cx + a2, wy + b2, dz, P, lerp(c, RUSTS, 0.3 * M.noise(cx + a2, wy + b2, dz, 2.0)))
                for dz in range(W + 4, W + 13): M.put(cx, wy, dz, P, IRON)        # eje
                box(M, cx - 3, cx + 3, wy - 3, wy + 3, W + 13, W + 16, IRON_L)     # caja de grasa
    for sx in (-1, 1):                                                   # topes y enganche
        for y in (16, H - 16):
            for k in range(6):
                for a2 in range(-3, 4):
                    for b2 in range(-3, 4):
                        if a2 * a2 + b2 * b2 <= 9: M.put(sx * (L + k), y + a2, b2 + 4, P, IRON_L if k == 5 else IRON)
        box(M, sx * L - (0 if sx > 0 else 8), sx * L + (8 if sx > 0 else 0), H // 2 - 3, H // 2 + 3, 0, 8, IRON)
    # puerta corredera caída en el suelo, con sus tornapuntas en Z y el carril
    for x in range(-24, 24):
        for z in range(-W - 34, -W - 4):
            xx = x + int(0.25 * (z + W))
            c = plank(xx, 0, z, 'roof')
            frame = x in (-24, -23, 22, 23) or z in (-W - 34, -W - 33, -W - 5, -W - 4)
            zbr = abs((x + 24) - (z + W + 34) * 48 / 30) < 1.6 or abs(x - (z + W + 34) * 0 - (-24 + (z + W + 34) * 48 / 30)) < 0
            if frame or zbr or z in (-W - 19, -W - 20): c = WAGON_D
            M.put(xx, 0, z, P, c)
            if frame or zbr: M.put(xx, 1, z, P, WAGON_D)
    for x in range(-30, 30): M.put(x, 0, -W - 37, P, IRON); M.put(x, 1, -W - 37, P, IRON_L)
    # barro, juncos y verdín al pie
    for x in range(-L - 12, L + 12):
        for z in range(-W - 40, W + 24):
            if (x, 0, z) in M.V: continue
            d = max(abs(x) - L, abs(z) - W, 0)
            if d < 10 and M.noise(x, 0, z, 6.0) > 0.42: M.put(x, 0, z, P, lerp(MOSS_D, (0.18, 0.15, 0.11), M.hsh(x, 0, z)))
    for (x, y, z), v in list(M.V.items()):
        if y < 6 and M.noise(x, y, z, 4.0) > 0.5 and v[1] != IRON_L: v[1] = lerp(v[1], MOSS_D, 0.5)
    for i in range(10):
        cx, cz = rng.choice((-1, 1)) * rng.randint(L - 4, L + 10), rng.randint(-W, W)
        for k in range(rng.randint(3, 6)):
            hgt = rng.randint(14, 30)
            for y in range(hgt): M.put(cx + k * 2 - 4 + int(y * 0.08), y, cz + (k % 3) - 1, P, (0.40, 0.42, 0.24) if y < hgt - 3 else (0.52, 0.50, 0.30))
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a2, k[1] + b2, k[2] + c2) in M.V for a2, b2, c2 in NB)]: del M.V[k]
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
    """Árbol muerto del pantano (revisión de arte del 14-10-2026; los de antes quedan en
    models/pan_arbol_{1,2}_v1.json). A 48 voxels/m, mismas medidas: base ensanchada en
    contrafuertes con raíces que se hunden en el agua, tronco retorcido con la corteza en surcos
    verticales y placas, un nudo hueco y negro, la copa partida con la madera desnuda y gris al
    aire, ramas desnudas que suben y se doblan (alguna rota y colgando), hongos de repisa en el
    tronco, y cortinas de musgo español que cuelgan en flecos de las ramas."""
    V = 3
    M = Model(S=V, seed=seed)
    rng = M.rng
    H = int(H * 1.5)
    GREY = (0.46, 0.44, 0.40); GREY_D = (0.32, 0.30, 0.28); FUNGUS = (0.58, 0.48, 0.30); FUNGUS_D = (0.40, 0.30, 0.18)
    def bark(x, y, z):
        a = math.atan2(z, x)
        groove = (a * 9 + 0.04 * y + 3 * M.noise(x, y * 0.2, z, 4.0)) % 1 < 0.22    # surcos verticales
        c = lerp(BARK, BARK_D, 0.3 + 0.5 * M.noise(x, y * 0.4, z, 6.0))
        if groove: c = lerp(c, (0.08, 0.07, 0.06), 0.6)
        elif M.noise(x, y, z, 2.5) > 0.72: c = BARK_L                                # placas
        if M.noise(x, y + 99, z, 5.0) > 0.7: c = lerp(c, MOSS_D, 0.45)                # verdín
        return c
    def wood(x, y, z): return lerp(GREY_D, GREY, M.noise(x, y, z, 2.0))
    for k in range(8):                                                               # contrafuertes y raíces
        a = k / 8 * math.tau + rng.uniform(-0.25, 0.25)
        L = rng.uniform(26, 40)
        line(M, (0, 26, 0), (math.cos(a) * L * 0.5, 6, math.sin(a) * L * 0.5), 4.2, bark)
        line(M, (math.cos(a) * L * 0.5, 6, math.sin(a) * L * 0.5), (math.cos(a) * L, -2, math.sin(a) * L), 2.6, bark)
    pts = [(0, 0, 0)]
    x = z = 0.0
    for y in range(0, H, 12):                                                        # tronco retorcido
        x += rng.uniform(-3.5, 3.5); z += rng.uniform(-3.5, 3.5)
        pts.append((x, y, z))
    for i in range(1, len(pts)):
        r = 9.5 * (1 - i / len(pts)) ** 0.8 + 2.2
        line(M, pts[i - 1], pts[i], r, bark)
    tp = pts[-1]                                                                     # copa partida: astillas grises
    for k in range(7):
        a = rng.uniform(0, math.tau)
        line(M, tp, (tp[0] + math.cos(a) * 3, tp[1] + rng.uniform(6, 16), tp[2] + math.sin(a) * 3), 1.2, wood)
    mid = pts[len(pts) // 3]                                                         # nudo hueco
    for dy in range(-5, 6):
        for dz in range(-3, 4):
            if dy * dy / 25 + dz * dz / 9 <= 1:
                M.put(mid[0] + 7, mid[1] + dy, mid[2] + dz, P, (0.04, 0.04, 0.04))
                M.put(mid[0] + 8, mid[1] + dy, mid[2] + dz, P, (0.04, 0.04, 0.04))
    for i in range(3):                                                               # hongos de repisa
        p = pts[int(len(pts) * rng.uniform(0.2, 0.6))]
        a = rng.uniform(0, math.tau); r0 = 7
        for w in range(-5, 6):
            for d in range(0, 5 - abs(w) // 2):
                q = (p[0] + math.cos(a) * (r0 + d) - math.sin(a) * w, p[1] - i * 4, p[2] + math.sin(a) * (r0 + d) + math.cos(a) * w)
                M.put(*q, P, FUNGUS if d < 3 else FUNGUS_D)
    tips = []
    def branch(p, ang, up, length, r, depth):
        dx, dz = math.cos(ang), math.sin(ang)
        q = (p[0] + dx * length, p[1] + up * length, p[2] + dz * length)
        line(M, p, q, r, bark if r > 1.6 else wood)
        if depth == 0 or r < 1.2:
            tips.append(q); return
        n = 2 if rng.random() > 0.25 else 1                                          # alguna rama no se bifurca: rota
        for _ in range(n):
            branch(q, ang + rng.uniform(-0.9, 0.9), max(up + rng.uniform(-0.35, 0.2), 0.05), length * 0.7, r * 0.62, depth - 1)
    for i in range(5):
        base = pts[int(len(pts) * rng.uniform(0.4, 0.85))]
        branch(base, rng.uniform(0, math.tau), rng.uniform(0.35, 0.9), rng.uniform(30, 48), 3.6, 3)
    branch(pts[-2], rng.uniform(0, math.tau), 0.8, 24, 2.8, 2)
    b0 = pts[int(len(pts) * 0.55)]                                                   # rama rota colgando
    a = rng.uniform(0, math.tau)
    q = (b0[0] + math.cos(a) * 14, b0[1] + 4, b0[2] + math.sin(a) * 14)
    line(M, b0, q, 2.4, bark)
    line(M, q, (q[0] + math.cos(a) * 4, q[1] - 30, q[2] + math.sin(a) * 4), 1.8, wood)
    for t_ in tips + tips[::2]:                                                      # musgo español en flecos
        width = rng.randint(3, 7)
        for j in range(-width, width + 1):
            n = int(rng.randint(14, 40) * (1 - abs(j) / (width + 1)) ** 0.5)
            for k in range(n):
                if rng.random() < 0.12: continue
                c = MOSS if (k + j) % 3 else MOSS_D
                if k > n - 3: c = lerp(MOSS, (0.56, 0.58, 0.46), 0.5)
                M.put(int(t_[0]) + j, int(t_[1]) - k - (abs(j) // 2), int(t_[2]) + (j % 2), P, c, over=False)
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a2, k[1] + b2, k[2] + c2) in M.V for a2, b2, c2 in NB)]: del M.V[k]
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
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

def tocon_v2():
    """Tocón de ciprés podrido (revisión de arte del 14-10-2026, a mano; el de Replicate queda en
    models/pan_tocon_v1.json). A 48 voxels/m, ~0,9 m: base acampanada con contrafuertes y raíces
    que entran al agua, corteza en surcos, el corte roto en dientes con la madera gris y los
    anillos, el centro podrido y hueco, hongos de repisa, musgo y una rodilla de ciprés al lado."""
    V = 3
    M = Model(S=V, seed=87)
    rng = M.rng
    GREY = (0.48, 0.45, 0.40); RING = (0.36, 0.33, 0.29); ROT_D = (0.10, 0.08, 0.06)
    FUNGUS = (0.62, 0.52, 0.32)
    Hs = 34
    for y in range(0, Hs + 10):
        r = 9 + 9 * math.exp(-y / 5.0)
        for x in range(-22, 23):
            for z in range(-22, 23):
                a = math.atan2(z, x)
                rr = r + (3.5 * max(0, math.cos(5 * a + 0.7)) * math.exp(-y / 7.0))          # contrafuertes
                d = math.hypot(x, z)
                if d > rr: continue
                topy = Hs + int(8 * M.noise(x, 0, z, 3.0)) - (6 if x > 2 else 0)            # corte roto
                if y > topy: continue
                if d < rr - 2.5 and y < topy: continue
                if y >= topy - 1 and d < 5: continue                                          # centro hueco
                groove = (a * 10 + 3 * M.noise(x, y * 0.2, z, 3.0)) % 1 < 0.25
                c = lerp(BARK, BARK_D, 0.3 + 0.5 * M.noise(x, y * 0.4, z, 5.0))
                if groove: c = lerp(c, (0.08, 0.07, 0.06), 0.6)
                if y >= topy - 1 and d < rr - 1.5:
                    c = RING if int(d) % 3 == 0 else GREY
                    if d < 7: c = ROT_D
                if y < 8 and M.noise(x, y, z, 4.0) > 0.4: c = lerp(c, MOSS_D, 0.6)
                M.put(x, y, z, P, lerp(c, GREY, 0.25))                                       # algo más claro: de noche no se leía
    for y in range(0, Hs - 4):                                                           # el hueco, oscuro
        for x in range(-4, 5):
            for z in range(-4, 5):
                if math.hypot(x, z) < 5 and (x, y, z) not in M.V and y == Hs - 6: M.put(x, y, z, P, ROT_D)
    for k in range(6):                                                                   # raíces al agua
        a = k / 6 * math.tau + 0.3
        line(M, (math.cos(a) * 14, 4, math.sin(a) * 14), (math.cos(a) * 30, -1, math.sin(a) * 30), 2.4,
             lambda x, y, z: lerp(BARK, BARK_D, M.noise(x, y, z, 3.0)))
    a = rng.uniform(0, math.tau)                                                         # hongos
    for i in range(2):
        for w in range(-5, 6):
            for d in range(0, 4 - abs(w) // 2):
                M.put(math.cos(a) * (11 + d) - math.sin(a) * w, 14 + i * 7, math.sin(a) * (11 + d) + math.cos(a) * w, P, FUNGUS if d < 2 else (0.44, 0.34, 0.20))
    for y in range(0, 16):                                                               # rodilla de ciprés
        r = 3.5 - y * 0.18
        for x in range(-4, 5):
            for z in range(-4, 5):
                if math.hypot(x, z) <= r: M.put(26 + x, y, -14 + z, P, BARK if (x + y) % 4 else BARK_L)
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    return M, {P: [0, 0, 0]}


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
          'arbol_1': arbol_1, 'arbol_2': arbol_2, 'tocon_mano': tocon, 'tocon': tocon_v2, 'caballete': caballete}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/pan_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('pan_%s: %d voxels' % (name, n))
