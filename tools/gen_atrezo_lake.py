"""Atrezo del campamento destruido de Lake (nivel 2 de la parte 1, hito 4.1), en el estilo de
gen_atrezo_expedicion.py (48 voxels por metro, una parte "body", origen en el centro de la
base). La violencia se sugiere sin mostrarla: lona rasgada, cajas reventadas, mesas de
disección vacías con manchas oscuras, el avión dañado y la perforadora volcada.

Escribe models/atrezo_{tienda_rota,caja_rota,mesa_diseccion,avion,perforadora}.json.
Uso: python tools/gen_atrezo_lake.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, refine
import gen_atrezo_expedicion as ex
from gen_atrezo_expedicion import (P, SNOW, SNOW_SH, CANVAS, CANVAS_D, CANVAS_DIRT, WOOD, WOOD_D, WOOD_L, IRON,
                                   IRON_L, BRASS, ROPE, snow_on_top, drift)

ICHOR = (0.10, 0.14, 0.10)          # manchas oscuras, verdinegras (lo que sangran los Antiguos)
TIN = (0.62, 0.62, 0.60)
PAINT = (0.70, 0.62, 0.30)          # avión: amarillo de expedición desvaído
PAINT_D = (0.56, 0.48, 0.22)
METAL = (0.48, 0.50, 0.52)
GLASS = (0.30, 0.40, 0.48)


def box(M, x0, x1, y0, y1, z0, z1, col, shell=False):
    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                if shell and min(x - x0, x1 - 1 - x, y - y0, y1 - 1 - y, z - z0, z1 - 1 - z) > 1: continue
                M.put(x, y, z, P, col(x, y, z) if callable(col) else col)


# ---------------- tienda rasgada ----------------

def tienda_rota():
    """La tienda de la expedición desgarrada: jirones en el tejado y en un costado, solapas
    que cuelgan, la cumbrera partida por un extremo, nieve dentro y alguna mancha oscura."""
    M = ex._tienda48()
    RIDGE = 96
    rm = []
    for (x, y, z), v in M.V.items():
        if v[1] in (SNOW, SNOW_SH): continue
        n = M.noise(x, y, z, 14.0)                                    # [0, 1], manchas de ~14 voxels
        if y > 26 and n > 0.66: rm.append((x, y, z))                  # jirones del tejado
        elif y > 4 and z > 40 and -40 < x < 20 and n > 0.5: rm.append((x, y, z))   # costado abierto
    for k in rm: M.V.pop(k, None)
    for x in range(-40, 20, 7):                                       # tiras de lona que cuelgan
        for y in range(4, 26):
            if M.hsh(x, 0, 3) > 0.55: continue
            M.put(x, y, 58 + (y % 3 == 0), P, CANVAS_D if y % 4 else CANVAS)
    for x in range(-80, -60):                                         # cumbrera partida y caída
        for y in (RIDGE, RIDGE + 1):
            M.V.pop((x, y, 0), None); M.V.pop((x, y, -1), None)
    for i in range(28):
        M.put(-74 - i // 3, max(1, RIDGE - 6 - i * 3), 2, P, WOOD_D)
    for (x, y, z), v in M.V.items():                                  # manchas oscuras en la lona
        if v[1] not in (SNOW, SNOW_SH) and y < 40 and M.noise(x, y, z, 7.0) > 0.74:
            v[1] = lerp(v[1], ICHOR, 0.75)
    for x in range(-60, 60):                                          # nieve que ha entrado
        for z in range(-50, 50):
            h = int(2 + 5 * M.noise(x, 0, z, 16.0))
            for y in range(1, h):
                M.put(x, y, z, P, SNOW if M.hsh(x, y, z) > 0.3 else SNOW_SH, over=False)
    return refine(M, 1, seed=31)                                      # textura fina (a 96/m pesaba demasiado; revisión de arte, 13-10-2026)


# ---------------- caja reventada ----------------

def caja_rota():
    """Caja de la Miskatonic reventada desde dentro: sin tapa, un costado arrancado, tablas
    sueltas al lado y latas de conserva por la nieve."""
    M = ex.caja()
    HX, HY, HZ = 18, 27, 14
    for k in [k for k in M.V if k[1] >= HY - 2]: M.V.pop(k)           # sin tapa
    for k in [k for k in M.V if k[2] >= HZ - 2 and k[1] > 6 and M.hsh(k[0] // 5, 0, 1) > 0.25]:
        M.V.pop(k)                                                    # costado arrancado
    for i, (x0, z0, ang) in enumerate(((22, 18, 0.3), (-28, 22, -0.5), (6, 32, 1.2))):   # tablas sueltas
        c, s = math.cos(ang), math.sin(ang)
        for t in range(-16, 16):
            for w in range(-3, 3):
                x = int(round(x0 + t * c - w * s)); z = int(round(z0 + t * s + w * c))
                M.put(x, 0, z, P, lerp(WOOD_D, WOOD_L, 0.4 + 0.3 * M.hsh(i, t // 6, 0)))
                M.put(x, 1, z, P, WOOD)
    for (x0, z0) in ((30, -6), (-24, -10), (16, 26), (-8, 30)):       # latas
        for x in range(x0, x0 + 4):
            for z in range(z0, z0 + 4):
                if (x - x0 - 1.5) ** 2 + (z - z0 - 1.5) ** 2 > 4.5: continue
                for y in range(0, 5): M.put(x, y, z, P, TIN if y not in (0, 4) else IRON_L)
    snow_on_top(M, prob=0.6, depth=1)
    return M


# ---------------- mesa de disección ----------------

def _mesa48():
    """Mesa de caballetes con una lona encima, vacía: manchas verdinegras, bandeja de
    instrumentos y un cubo volcado. Lo que había encima ya no está."""
    M = Model(S=3, seed=41)
    L, W, H = 48, 22, 38                                              # 2 x 0,9 m, 0,8 de alto
    box(M, -L, L, H - 2, H, -W, W, lambda x, y, z: lerp(WOOD_D, WOOD_L, 0.3 + 0.4 * M.hsh(x // 12, 0, 0)))
    for xs in (-1, 1):                                                # caballetes en A
        for y in range(0, H - 2):
            off = int((H - 2 - y) * 0.35)
            for zs in (-1, 1):
                for dx in range(3):
                    M.put(xs * (L - 8) + dx, y, zs * (W - 4 + off) - (1 if zs > 0 else 0), P, WOOD_D)
        for z in range(-W, W): M.put(xs * (L - 8), 14, z, P, WOOD)
    for x in range(-L + 2, L - 2):                                    # lona que cae por los lados
        for z in range(-W - 1, W + 1):
            M.put(x, H, z, P, CANVAS)
        for zs in (-1, 1):
            for y in range(H - 12 - int(5 * M.noise(x, 0, zs * 50, 8.0)), H):
                M.put(x, y, zs * (W + 1) - (1 if zs > 0 else 0), P, CANVAS_D)
    for (x, y, z), v in M.V.items():                                  # manchas verdinegras
        if v[1] in (CANVAS, CANVAS_D) and M.noise(x, 0, z, 9.0) > 0.68:
            v[1] = lerp(v[1], ICHOR, 0.8)
    box(M, 20, 36, H + 1, H + 3, -16, -4, IRON_L)                     # bandeja con instrumentos
    for x in (23, 27, 31):
        for z in range(-14, -7): M.put(x, H + 3, z, P, (0.85, 0.86, 0.88))
    for y in range(0, 10):                                            # cubo volcado en el suelo
        for t in range(12):
            a = t / 12 * math.tau
            M.put(int(round(-58 + 5 * math.cos(a))), int(round(5 + 5 * math.sin(a))), y - 20, P, METAL)
    for x in range(-70, -50):                                         # derrame junto al cubo
        for z in range(-24, -2):
            if M.noise(x, 0, z, 6.0) > 0.5: M.put(x, 0, z, P, ICHOR)
    return M


def mesa_diseccion():
    """Mesa de disección a 96/m (revisión de arte del 13-10-2026): la de _mesa48 al doble de
    resolución con textura fina, y además correas de cuero con hebilla cruzando la lona, frascos
    de cristal con especímenes en un líquido verdoso que brilla apenas, un cuaderno de notas
    abierto, una sierra de hueso y una lámpara de queroseno apagada."""
    M = refine(_mesa48(), 2, seed=41)
    H = 78                                                            # tablero (a 96/m)
    LEATHER = (0.30, 0.18, 0.10); BUCKLE = (0.62, 0.56, 0.40)
    for xs in (-40, 30):                                              # correas con hebilla
        for z in range(-46, 47):
            for x in (xs, xs + 1, xs + 2, xs + 3): M.put(x, H + 1, z, P, LEATHER)
        for y in range(H - 20, H + 1):
            for x in (xs, xs + 1, xs + 2, xs + 3): M.put(x, y, 47, P, LEATHER); M.put(x, y, -47, P, LEATHER)
        for x in range(xs - 1, xs + 5): M.put(x, H + 2, 10, P, BUCKLE)
    GL = (0.62, 0.74, 0.70); LIQ = (0.30, 0.50, 0.26)
    for k, (jx, jz) in enumerate(((-70, -30), (-60, -32), (-78, -18))):   # frascos con especímenes
        h = 18 + 6 * k
        for y in range(H + 1, H + 1 + h):
            for x in range(jx - 5, jx + 6):
                for z in range(jz - 5, jz + 6):
                    d = (x - jx) ** 2 + (z - jz) ** 2
                    if d > 25: continue
                    if d > 16 or y == H + h: M.put(x, y, z, P, GL); continue
                    if y < H + h - 4:
                        spec = d < 6 and (H + 4 < y < H + h - 6)
                        M.put(x, y, z, P, (0.14, 0.20, 0.12) if spec else LIQ, glow=0 if spec else 1)
        for x in range(jx - 5, jx + 6):
            for z in range(jz - 5, jz + 6):
                if (x - jx) ** 2 + (z - jz) ** 2 <= 25: M.put(x, H + h + 1, z, P, (0.30, 0.26, 0.20))
    for x in range(-20, 4):                                           # cuaderno abierto
        for z in range(18, 34):
            c = (0.80, 0.76, 0.64) if x != -8 else (0.40, 0.30, 0.20)
            if x != -8 and (z - 20) % 3 == 0 and abs(x + 8) > 2: c = (0.36, 0.34, 0.30)
            M.put(x, H + 1 + (1 if abs(x + 8) > 6 else 0), z, P, c)
    for k in range(30):                                               # sierra de hueso
        M.put(48 + k, H + 1, 20, P, (0.70, 0.72, 0.74)); M.put(48 + k, H + 1, 21, P, (0.70, 0.72, 0.74) if k % 2 else (0.40, 0.42, 0.44))
    for k in range(10): M.put(38 + k, H + 1, 20, P, (0.36, 0.22, 0.12)); M.put(38 + k, H + 2, 20, P, (0.36, 0.22, 0.12))
    for y in range(H + 1, H + 26):                                    # lámpara de queroseno
        r = 6 if y < H + 8 else (5 if y < H + 20 else 3)
        for x in range(70 - r, 71 + r):
            for z in range(-34 - r, -33 + r):
                if (x - 70) ** 2 + (z + 34) ** 2 > r * r: continue
                if H + 8 <= y < H + 20 and (x - 70) ** 2 + (z + 34) ** 2 < (r - 1) ** 2: continue
                M.put(x, y, z, P, (0.56, 0.62, 0.62) if H + 8 <= y < H + 20 else (0.50, 0.40, 0.20))
    return M


# ---------------- avión ----------------

def avion():
    """El monoplano de la expedición de Lake, dañado (revisión de arte del 14-10-2026, a mano con
    la referencia de FLUX en local tools/local/ref_avion_100{0,1}.png; la versión de Replicate
    queda en models/atrezo_avion_v1.json). A 48 voxels/m, ~7 m de largo y 9 de envergadura:
    fuselaje de sección redondeada amarillo con la línea roja, paneles y remaches, cabina con
    ventanillas y puerta, motor radial con anillo de capó, cilindros con aletas y escape, hélice
    de madera con una pala partida, ala alta de tela sobre costillas con la punta roja (la
    izquierda doblada hasta la nieve y con la tela rasgada), montantes en V (uno partido),
    esquíes con la punta curvada, cola con timón a franjas, manchas de aceite y quemado y nieve
    a placas encima y al pie."""
    M = Model(S=3, seed=42)
    rng = M.rng
    YEL = (0.78, 0.64, 0.20); YEL_D = (0.62, 0.48, 0.14); RED = (0.62, 0.13, 0.10); RED_D = (0.44, 0.09, 0.08)
    DARK = (0.12, 0.12, 0.13); CYL = (0.30, 0.30, 0.32); FIN = (0.22, 0.22, 0.24); SOOT = (0.16, 0.14, 0.12)
    RIB = (0.52, 0.40, 0.12); TORN = (0.30, 0.22, 0.10); GLASS_L = (0.42, 0.56, 0.64)
    def paint(x, y, z):
        c = lerp(YEL_D, YEL, 0.45 + 0.5 * M.noise(x, y, z, 14.0))
        if M.noise(x, y, z, 5.0) > 0.8: c = lerp(c, (0.70, 0.66, 0.56), 0.5)        # pintura pelada
        return c
    # ---- fuselaje: sección rectangular redondeada (superelipse) que se estrecha a la cola ----
    X0, X1 = -175, 150
    def sec(x):
        t = min(1.0, max(0.0, (x - X0) / (60 - X0)))                                  # 0 cola, 1 cabina
        return 7 + 21 * t ** 0.8, 9 + 23 * t ** 0.8, 74 - 14 * t                        # semiancho, semialto, centro
    hull = {}
    for x in range(X0, X1):
        w, h, cy = sec(x)
        for y in range(int(cy - h) - 1, int(cy + h) + 2):
            for z in range(-int(w) - 1, int(w) + 2):
                d = abs((y + 0.5 - cy) / h) ** 3.5 + abs((z + 0.5) / w) ** 3.5
                if d <= 1.0:
                    hull[(x, y, z)] = (cy, h, w)
    for (x, y, z), (cy, h, w) in hull.items():
        if all((x + a, y + b, z + c) in hull for a, b, c in ((0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))): continue
        c = paint(x, y, z)
        rel = (y - cy) / h
        if -0.18 < rel < 0.02 and x > X0 + 10: c = RED if rel > -0.14 else RED_D       # línea roja
        if x % 34 == 0: c = lerp(c, YEL_D, 0.6)                                         # paneles
        if x % 34 == 17 and (y + z) % 4 == 0: c = lerp(c, (0.35, 0.32, 0.25), 0.4)     # remaches
        if rel < -0.75: c = lerp(c, (0.40, 0.34, 0.20), 0.5)                            # panza sucia
        if 64 <= x < 132 and 0.18 < rel < 0.62 and abs(z) > w - 2:                      # ventanillas
            c = GLASS_L if (x - 64) % 23 < 19 else YEL_D
        if 20 <= x < 50 and -0.6 < rel < 0.55 and z > w - 2:                            # puerta
            if x in (20, 49) or rel < -0.55 or rel > 0.5: c = YEL_D
        M.put(x, y, z, P, c)
    for (x, y, z) in list(M.V):                                                         # agujeros y quemado
        if -40 < x < 10 and M.noise(x, y, z, 6.0) > 0.82 and z > 0: del M.V[(x, y, z)]
        elif -60 < x < 30 and M.noise(x, y, z, 9.0) > 0.7: M.V[(x, y, z)][1] = lerp(M.V[(x, y, z)][1], SOOT, 0.7)
    # parabrisas
    for x in range(132, 150):
        w, h, cy = sec(x)
        for z in range(-int(w) + 2, int(w) - 1):
            y = int(cy + h - (x - 132) * 0.9)
            M.put(x, y + 2, z, P, GLASS if (z // 9) % 3 else YEL_D)
    # ---- motor radial: anillo del capó, nueve cilindros con aletas, cubo y escape ----
    EC = (150, 58)
    for x in range(150, 178):
        for y in range(EC[1] - 36, EC[1] + 37):
            for z in range(-36, 37):
                r = math.hypot(y + 0.5 - EC[1], z + 0.5)
                if 31 <= r <= 35 and x < 170: M.put(x, y, z, P, RED_D if x > 166 else DARK)  # anillo
    for k in range(9):
        a = k * math.tau / 9
        for r in range(8, 28):
            for x in range(156, 168):
                y = EC[1] + r * math.sin(a); z = r * math.cos(a)
                for d in (-3, -2, -1, 0, 1, 2, 3):
                    yy = int(y + d * math.cos(a)); zz = int(z - d * math.sin(a))
                    M.put(x, yy, zz, P, FIN if (r % 3 == 0) else CYL)
    for y in range(EC[1] - 9, EC[1] + 10):
        for z in range(-9, 10):
            if math.hypot(y - EC[1], z) < 9:
                for x in range(156, 172): M.put(x, y, z, P, DARK)
    for i in range(30): M.put(140 - i, EC[1] - 30 - (i // 5), 22, P, SOOT); M.put(140 - i, EC[1] - 31 - (i // 5), 22, P, SOOT)
    # hélice: una pala hacia arriba, la otra partida
    for x in range(172, 180):
        for i in range(-30, 92):
            if i < -26 and rng.random() < 0.6: continue
            wd = 5 if abs(i) > 12 else 3
            for dz in range(-wd, wd + 1):
                c = WOOD_D if dz in (-wd, wd) else WOOD
                if i > 82: c = IRON_L                                                    # punta de chapa
                M.put(x, EC[1] + i, dz + int(i * 0.06), P, c)
    for x in range(176, 186):
        for y in range(EC[1] - 5, EC[1] + 6):
            for z in range(-5, 6):
                if math.hypot(y - EC[1], z) < 5 + (180 - x) * 0.3: M.put(x, y, z, P, IRON_L)
    # ---- ala alta: perfil sobre costillas, punta roja; la izquierda doblada a la nieve ----
    WX0, WX1, SPAN = 36, 140, 216
    def wing_y(z):
        if z >= -120: return 96
        u = (-120 - z) / (SPAN - 120)
        return int(96 - 90 * min(1.0, u * 1.15))                                       # doblada hasta el suelo
    for z in range(-SPAN, SPAN + 1):
        if abs(z) < 4: pass
        yb = wing_y(z)
        for x in range(WX0, WX1):
            u = (WX1 - x) / (WX1 - WX0)                                                 # 0 borde de ataque
            th = int(7 * math.sqrt(max(0.0, u)) * (1.2 - u))                            # grueso del perfil
            for y in (yb, yb + th + 1):
                c = paint(x, y, z)
                if z % 24 == 0: c = lerp(c, RIB, 0.6)                                  # costillas
                if abs(z) > SPAN - 22: c = RED
                if x < WX0 + 18 and abs(z) > 120 and x == WX0 + 17: c = YEL_D          # alerones
                torn = z < -126 and M.noise(x, y, z, 7.0) > 0.62
                if torn and y > yb:                                                     # tela rasgada
                    if z % 24 in (0, 1) or x % 26 == 0: M.put(x, y, z, P, TORN)
                    continue
                M.put(x, y, z, P, c)
            if x in (WX1 - 1,) or u < 0.04:
                for y in range(yb, yb + th + 2): M.put(x, y, z, P, YEL_D)
    for (sz, x0) in ((1, 64), (1, 110), (-1, 64), (-1, 110)):                           # montantes en V
        top = (x0, wing_y(sz * 112), sz * 112)
        bot = (86, 34, sz * 26)
        for i in range(60):
            t = i / 59
            if sz < 0 and x0 == 110 and 0.45 < t < 0.62: continue                        # partido
            p = tuple(bot[k] + (top[k] - bot[k]) * t for k in range(3))
            for d in (0, 1): M.put(int(p[0]) + d, int(p[1]), int(p[2]), P, IRON)
    # ---- esquíes ----
    for sz in (-1, 1):
        for x in range(10, 150):
            lift = max(0, x - 132) ** 2 // 6
            for dz in range(-5, 6):
                M.put(x, lift, sz * 46 + dz, P, WOOD_D if dz in (-5, 5) else WOOD)
                M.put(x, lift + 1, sz * 46 + dz, P, WOOD)
        for (xa, xb) in ((40, 70), (110, 80)):                                          # patas en V
            for i in range(40):
                t = i / 39
                M.put(int(xa + (xb - xa) * t), int(2 + 34 * t), int(sz * (46 - 20 * t)), P, IRON)
                M.put(int(xa + (xb - xa) * t) + 1, int(2 + 34 * t), int(sz * (46 - 20 * t)), P, IRON)
    # ---- cola: estabilizador y timón a franjas ----
    for x in range(-178, -128):
        u = (x + 178) / 50
        hs = int(30 + 46 * min(1.0, (x + 178) / 22))
        for z in range(-hs, hs + 1):
            for y in (76, 77): M.put(x, y, z, P, RED if abs(z) > hs - 10 else paint(x, y, z))
        top = int(84 + 70 * (1 - u) ** 0.8) if x < -140 else 84 + int(70 * (1 - u) ** 0.8 * (x > -150))
        for y in range(78, top):
            for z in (-1, 0, 1):
                c = paint(x, y, z) if x > -160 else (RED if ((y - 78) // 10) % 2 == 0 else (0.86, 0.84, 0.78))
                M.put(x, y, z, P, c)
    for i in range(24): M.put(-170 + i, 30 + int(i * 0.9), 0, P, IRON)                  # patín de cola
    for x in range(-186, -160):
        for dz in range(-3, 4): M.put(x, max(0, (x + 186) // 8 - 1), dz, P, WOOD_D)
    # ---- manchas de aceite y nieve ----
    for (x, y, z), v in M.V.items():
        if y < 60 and 60 < x < 160 and M.noise(x, y, z, 4.0) > 0.78: v[1] = lerp(v[1], DARK, 0.6)
    def flat(x, y, z):
        return M.noise(x, 0, z, 12.0) > 0.62
    snow_on_top(M, prob=0.9, depth=1, min_y=6, patch=flat)
    def inside(x, z):
        if X0 <= x <= X1 + 30 and abs(z) <= 30: return 0
        dx = max(X0 - x, 0, x - X1 - 30); dz = max(abs(z) - 30, 0)
        return math.hypot(dx, dz) * 1.2
    for x in range(-200, 200):
        for z in range(-240, 240):
            d = inside(x, z)
            if d is None or d <= 0 or d >= 12: continue
            h = 6 * (1 - d / 12) * (0.4 + 0.8 * M.noise(x, 0, z, 6.0))
            for y in range(0, int(h)):
                M.put(x, y, z, P, SNOW if M.hsh(x, y, z) > 0.25 else SNOW_SH, over=False)
    # las alas a lo largo de X, como el avión de antes (la arena lo gira igual con arte=v1)
    M.V = {(-z, y, x): v for (x, y, z), v in M.V.items()}
    return M


# ---------------- perforadora ----------------

def beam(M, a, b, r, col):
    """Viga de sección cuadrada (lado 2r+1 voxels) de a a b; col(x, y, z, t) o un color."""
    n = int(max(abs(b[i] - a[i]) for i in range(3))) + 1
    for i in range(n + 1):
        t = i / max(1, n)
        cx, cy, cz = (a[k] + (b[k] - a[k]) * t for k in range(3))
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                for dz in range(-r, r + 1):
                    x, y, z = int(round(cx + dx)), int(round(cy + dy)), int(round(cz + dz))
                    if y < 0: continue
                    M.put(x, y, z, P, col(x, y, z, t) if callable(col) else col)


def disc(M, c, axis, r0, r1, depth, col):
    """Anillo (r0..r1) o disco (r0 = 0) perpendicular al eje 'x', 'y' o 'z'."""
    R = int(r1) + 1
    for u in range(-R, R + 1):
        for v in range(-R, R + 1):
            d = math.hypot(u + 0.5, v + 0.5)
            if not (r0 <= d <= r1): continue
            for w in range(depth):
                p = {'x': (c[0] + w, c[1] + u, c[2] + v), 'y': (c[0] + u, c[1] + w, c[2] + v),
                     'z': (c[0] + u, c[1] + v, c[2] + w)}[axis]
                if p[1] < 0: continue
                M.put(p[0], p[1], p[2], P, col(*p, math.atan2(v, u), d) if callable(col) else col)


def perforadora():
    """La perforadora de Lake (revisión de arte del 14-10-2026, referencia de FLUX en local
    tools/local/ref_perforadora_1001.png; la versión de antes queda en
    models/atrezo_perforadora_v1.json). A 48 voxels/m, ~6,5 m: el patín de vigas con el motor de
    hierro (aletas, culata, escape y volante con radios), la correa al tambor del cable con sus
    bridas y engranajes, la torre de celosía de madera arrancada y caída en diagonal con la
    polea de la corona, tubos de perforación en su caballete y otros sueltos, una caja de
    herramientas, una lata y nieve encima y al pie."""
    M = Model(S=3, seed=43)
    rng = M.rng
    RUST = (0.40, 0.22, 0.12); IRON_D = (0.20, 0.20, 0.21); OIL = (0.10, 0.10, 0.10)
    def wood(x, y, z, *_):
        c = lerp(WOOD_D, WOOD, 0.35 + 0.45 * M.noise(x, y * 0.3, z, 6.0))
        if M.hsh(x // 2, y // 9, z // 2) < 0.08: c = lerp(c, (0.18, 0.12, 0.08), 0.5)   # nudos
        return c
    def iron(x, y, z, *_):
        c = lerp(IRON_D, IRON, 0.5 + 0.5 * M.noise(x, y, z, 5.0))
        if M.noise(x, y, z, 3.0) > 0.72: c = lerp(c, RUST, 0.7)                    # óxido
        return c
    # patín: dos largueros, travesaños y tablazón
    for zs in (-34, 30):
        box(M, -100, 60, 0, 7, zs, zs + 5, lambda x, y, z: wood(x, y, z))
        for x in (-96, -40, 20, 56): box(M, x, x + 2, 5, 7, zs - 1, zs + 6, IRON_L)   # pernos
    for x in range(-100, 60, 14): box(M, x, x + 9, 7, 9, -36, 37, lambda x, y, z: wood(x, y, z))
    # motor: bloque con aletas, culata, cárter y escape
    box(M, -88, -46, 9, 44, -22, 22, iron, shell=True)
    for y in range(14, 42, 4): box(M, -90, -44, y, y + 1, -24, 24, IRON_D)        # aletas
    box(M, -84, -50, 44, 52, -18, 18, iron, shell=True)                           # culata
    for x in range(-80, -52, 8): box(M, x, x + 3, 52, 56, -3, 3, BRASS)           # válvulas
    beam(M, (-58, 52, 10), (-58, 86, 10), 2, IRON_D)                              # escape
    disc(M, (-58, 86, 10), 'y', 0, 4.5, 3, OIL)
    box(M, -92, -88, 18, 30, -8, 8, BRASS)                                        # placa del fabricante
    # volante a un lado: llanta, radios y cubo
    FC = (-67, 32, 27)
    disc(M, FC, 'z', 19, 24, 4, iron)
    for k in range(6):
        a = k * math.pi / 3
        beam(M, (FC[0], FC[1], FC[2] + 1), (FC[0] + 19 * math.cos(a), FC[1] + 19 * math.sin(a), FC[2] + 1), 1, IRON_D)
    disc(M, (FC[0], FC[1], FC[2] - 2), 'z', 0, 5, 7, BRASS)
    # tambor del cable con bridas, cable enrollado y engranaje
    DC = (-14, 30, -20)
    def cable(x, y, z, a, d):
        return ROPE if (z + int(a * 3)) % 3 else (0.30, 0.26, 0.20)
    disc(M, DC, 'z', 0, 15, 40, cable)
    for zz in (DC[2] - 3, DC[2] + 40): disc(M, (DC[0], DC[1], zz), 'z', 0, 20, 3, iron)
    def gear(x, y, z, a, d):
        return IRON_L if d < 11 or int(a / (math.pi / 10)) % 2 else IRON_D
    disc(M, (DC[0], DC[1], DC[2] - 7), 'z', 0, 13, 3, gear)
    for k in range(20):                                                            # dientes
        a = k * math.pi / 10
        if k % 2: continue
        box(M, int(DC[0] + 14 * math.cos(a)) - 1, int(DC[0] + 14 * math.cos(a)) + 2,
            int(DC[1] + 14 * math.sin(a)) - 1, int(DC[1] + 14 * math.sin(a)) + 2, DC[2] - 7, DC[2] - 4, IRON_D)
    box(M, -22, -6, 9, 14, -26, 26, wood)                                          # bancada del tambor
    for z in (-26, 22): box(M, -18, -10, 9, 30, z, z + 4, iron)                   # soportes
    # correa del volante al tambor
    for i in range(60):
        t = i / 59
        x = FC[0] + (DC[0] - FC[0]) * t; y = FC[1] + 22 + (DC[1] + 15 - FC[1] - 22) * t - 3 * math.sin(math.pi * t)
        box(M, int(x), int(x) + 1, int(y), int(y) + 2, 26, 30, OIL)
    # torre de celosía caída: base en el patín, punta en la nieve hacia +X y -Z
    L = 250
    base = (40, 9, 0)
    th = math.radians(62)                                                          # inclinación desde la vertical
    yaw = math.radians(-18)
    d = (math.sin(th) * math.cos(yaw), math.cos(th), math.sin(th) * math.sin(yaw))
    up = (-math.cos(th) * math.cos(yaw), math.sin(th), -math.cos(th) * math.sin(yaw))
    side = (-math.sin(yaw), 0, math.cos(yaw))
    def at(u, v, w):
        return tuple(base[k] + d[k] * u + up[k] * v + side[k] * w for k in range(3))
    def half(u): return 22 - 14 * u / L
    corners = ((1, 1), (1, -1), (-1, 1), (-1, -1))
    for sv, sw in corners:
        beam(M, at(0, sv * half(0), sw * half(0)), at(L, sv * half(L), sw * half(L)), 2, wood)
    for k in range(0, L + 1, 30):
        h = half(k)
        ring = [at(k, sv * h, sw * h) for sv, sw in ((1, 1), (1, -1), (-1, -1), (-1, 1))]
        for i in range(4):
            if k > L * 0.55 and i == 1 and k % 60 == 0: continue                  # travesaño roto
            beam(M, ring[i], ring[(i + 1) % 4], 1, wood)
        if k + 30 <= L:
            h2 = half(k + 30)
            for sv, sw in corners:                                                 # cruces de San Andrés
                if rng.random() < 0.15: continue
                beam(M, at(k, sv * h, sw * h), at(k + 30, -sv * h2 if abs(sv) else 0, sw * h2), 0, wood)
    # corona con la polea
    top = at(L, 0, 0)
    disc(M, (int(top[0]), int(top[1]) + 6, int(top[2]) - 2), 'z', 4, 12, 4, BRASS)
    box(M, int(top[0]) - 12, int(top[0]) + 12, max(0, int(top[1]) - 2), int(top[1]) + 2, int(top[2]) - 14, int(top[2]) + 14, wood)
    # caballete de tubos y tubos sueltos
    for x in (-150, -114):
        beam(M, (x, 0, -60), (x, 22, -60), 1, wood); beam(M, (x, 0, -84), (x, 22, -84), 1, wood)
        beam(M, (x, 22, -86), (x, 22, -58), 1, wood)
    for i in range(6):
        cz = -80 + (i % 3) * 9; cy = 27 + (i // 3) * 8
        for x in range(-170, -92):
            for a in range(0, 360, 30):
                y = cy + 4 * math.sin(math.radians(a)); z = cz + 4 * math.cos(math.radians(a))
                c = iron(x, int(y), int(z))
                if x in (-170, -169, -94, -93): c = IRON_L                              # manguitos
                M.put(x, int(y), int(z), P, c)
            if x in (-171,): pass
    for (x0, z0, x1, z1) in ((-70, 60, 10, 92), (70, -60, 130, -30)):
        for i in range(90):
            t = i / 89
            x = x0 + (x1 - x0) * t; z = z0 + (z1 - z0) * t
            for a in range(0, 360, 30):
                M.put(int(x), int(4 + 3.5 * math.sin(math.radians(a))), int(z + 3.5 * math.cos(math.radians(a))), P, iron(int(x), 4, int(z)))
    # caja de herramientas y lata de aceite
    box(M, -130, -100, 0, 16, 30, 50, lambda x, y, z: wood(x, y, z) if (y % 5) else WOOD_D, shell=True)
    box(M, -116, -114, 16, 22, 34, 46, IRON)
    disc(M, (-140, 0, 68), 'y', 0, 6, 16, (0.55, 0.16, 0.12))
    disc(M, (-140, 16, 68), 'y', 0, 6, 1, IRON_L)
    # manchas de aceite y escarcha
    for (x, y, z), v in list(M.V.items()):
        if M.hsh(x, y, z) < 0.03 and y < 40: v[1] = lerp(v[1], OIL, 0.5)
    def wide(x, y, z):                                                             # nieve solo en lo ancho
        return sum((x + a, y, z + b) in M.V for a in (-2, 0, 2) for b in (-2, 0, 2)) >= 8
    snow_on_top(M, prob=0.75, depth=2, patch=wide)
    def inside(x, z):
        if -100 <= x <= 60 and -36 <= z <= 36: return 0
        dx = max(-100 - x, 0, x - 60); dz = max(-36 - z, 0, z - 36)
        return math.hypot(dx, dz)
    drift(M, inside, 14, 7)
    return M


# El avión vuelve a salir de aquí (revisión de arte del 14-10-2026, hecho a mano); el de
# tools/generar_modelo_replicate.py (FLUX + TRELLIS) queda como models/atrezo_avion_v1.json.
PIECES = {'tienda_rota': tienda_rota, 'caja_rota': caja_rota, 'mesa_diseccion': mesa_diseccion,
          'perforadora': perforadora, 'avion': avion}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M = fn()
        n = M.export('models/atrezo_%s.json' % name, {P: [0, 0, 0]}, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('atrezo_%s: %d voxels' % (name, n))
