"""Atrezo del campamento destruido de Lake (nivel 2 de la parte 1, hito 4.1), en el estilo de
gen_atrezo_expedicion.py (48 voxels por metro, una parte "body", origen en el centro de la
base). La violencia se sugiere sin mostrarla: lona rasgada, cajas reventadas, mesas de
disección vacías con manchas oscuras, el avión dañado y la perforadora volcada.

Escribe models/atrezo_{tienda_rota,caja_rota,mesa_diseccion,avion,perforadora}.json.
Uso: python tools/gen_atrezo_lake.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
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
    M = ex.tienda()
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
    return M


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

def mesa_diseccion():
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


# ---------------- avión ----------------

def avion():
    """El monoplano de la expedición, dañado: fuselaje redondeado amarillo de ala alta con
    franjas rojas, motor con capó y la hélice rota, un ala doblada hacia el suelo, cola con
    timón, esquíes y nieve a manchas. A 32 voxels/m (es grande); unos 9 m de envergadura."""
    M = Model(S=2, seed=42)
    RED = (0.62, 0.14, 0.12); DARK = (0.16, 0.16, 0.17)
    def paint(x, y, z):
        return lerp(PAINT_D, PAINT, 0.45 + 0.5 * M.noise(x, y, z, 24.0))
    # fuselaje a lo largo de X: sección elíptica que se estrecha hacia la cola (-X)
    for x in range(-130, 72):
        t = min(1.0, (x + 130) / 120)
        ry, rz = 6 + 14 * t, 5 + 13 * t
        cy = 24 + 12 * t
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for z in range(-int(rz) - 1, int(rz) + 2):
                d = ((y + 0.5 - cy) / ry) ** 2 + ((z + 0.5) / rz) ** 2
                if 0.72 < d <= 1.0:
                    c = paint(x, y, z)
                    if -60 < x < -50: c = RED                          # franja del fuselaje
                    M.put(x, y, z, P, c)
    for x in range(34, 56):                                          # ventanillas de la cabina
        for y in (40, 41, 42, 43):
            for z in range(-20, 20):
                if (x, y, z) in M.V and (x // 6) % 2 == 0: M.V[(x, y, z)][1] = GLASS
    # motor: capó redondo oscuro y hélice de dos palas, una partida
    for x in range(72, 90):
        for y in range(18, 52):
            for z in range(-17, 17):
                d = ((y + 0.5 - 35) / 17) ** 2 + ((z + 0.5) / 17) ** 2
                if 0.6 < d <= 1.0 or (x == 89 and d <= 1.0): M.put(x, y, z, P, DARK if x > 74 else METAL)
    for y in range(31, 39):
        for z in range(-4, 4): M.put(91, y, z, P, METAL)
    for i in range(44):                                              # pala entera hacia arriba
        for dz in (-2, -1, 0, 1): M.put(92, 39 + i, dz, P, WOOD_D)
    for i in range(14):                                              # la otra, partida
        for dz in (-2, -1, 0, 1): M.put(92, 30 - i, dz, P, WOOD_D)
    # ala alta de 4 de grueso: a un lado recta, al otro doblada hacia el suelo
    for x in range(14, 62):
        for z in range(-150, 150):
            if abs(z) < 18: continue
            y = 58
            if z < -84:
                y = int(58 - (-84 - z) * 0.65)
                if y < 2: continue
            tip = abs(z) > 128
            for dy in range(4):
                M.put(x, y + dy, z, P, RED if tip else paint(x, y, z))
            if M.noise(x, 0, z, 14.0) > 0.6:                           # nieve a manchas
                M.put(x, y + 4, z, P, SNOW if M.hsh(x, 1, z) > 0.3 else SNOW_SH)
    for zs in (-1, 1):                                               # montantes del ala
        for i in range(26):
            M.put(38, 32 + i, zs * (18 + int(i * 1.8)), P, METAL); M.put(39, 32 + i, zs * (18 + int(i * 1.8)), P, METAL)
    # cola: plano horizontal y timón con franja roja
    for x in range(-132, -104):
        for z in range(-46, 46):
            for dy in (0, 1): M.put(x, 26 + dy, z, P, paint(x, 26, z))
        for y in range(28, 72 - (x + 132)):
            for z in (-1, 0): M.put(x, y, z, P, RED if y > 54 else paint(x, y, z))
    # esquíes
    for zs in (-1, 1):
        for x in range(8, 64):
            for dz in (0, 1):
                M.put(x, 0, zs * 28 + dz, P, WOOD_D)
                if x > 58: M.put(x, x - 58, zs * 28 + dz, P, WOOD_D)
        for y in range(1, 20): M.put(36, y, zs * 28, P, METAL)
    def inside(x, z):
        return max(abs(x + 30) - 100, abs(z) - 24) if abs(z) < 60 else None
    drift(M, inside, 12, 8)
    return M


# ---------------- perforadora ----------------

def perforadora():
    """La perforadora de Lake volcada: torre de madera en celosía caída de lado, el motor en
    su caja, tubos apilados y la polea suelta."""
    M = Model(S=3, seed=43)
    box(M, -30, 30, 0, 34, -24, 24, lambda x, y, z: lerp(WOOD_D, WOOD, 0.5 + 0.3 * M.hsh(x // 10, y // 6, 0)), shell=True)
    box(M, -18, 18, 34, 46, -14, 14, IRON, shell=True)                 # motor
    for y in range(46, 60): M.put(10, y, 0, P, IRON_L); M.put(11, y, 0, P, IRON_L)   # escape
    # torre caída: celosía a lo largo de X desde la caja
    for x in range(30, 190):
        for (y, z) in ((4, -16), (4, 15), (34, -10), (34, 9)):
            yy = int(y * (1 - (x - 30) / 260))
            M.put(x, yy, z, P, WOOD_D); M.put(x, yy + 1, z, P, WOOD_D)
        if x % 20 == 0:                                               # travesaños
            for z in range(-16, 16): M.put(x, 4, z, P, WOOD)
            for y in range(4, int(34 * (1 - (x - 30) / 260))): M.put(x, y, -16, P, WOOD); M.put(x, y, 15, P, WOOD)
    for i in range(5):                                                # tubos apilados
        for x in range(-90, -36):
            for a in range(10):
                t = a / 10 * math.tau
                M.put(x, int(4 + 4 * math.sin(t)) + (i // 3) * 8, int(-30 + (i % 3) * 9 + 4 * math.cos(t)), P, METAL)
    for t in range(16):                                               # polea suelta
        a = t / 16 * math.tau
        M.put(int(200 + 6 * math.cos(a)), int(6 + 6 * math.sin(a)), 20, P, BRASS)
    snow_on_top(M, prob=0.8, depth=1)
    return M


PIECES = {'tienda_rota': tienda_rota, 'caja_rota': caja_rota, 'mesa_diseccion': mesa_diseccion,
          'avion': avion, 'perforadora': perforadora}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M = fn()
        n = M.export('models/atrezo_%s.json' % name, {P: [0, 0, 0]}, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('atrezo_%s: %d voxels' % (name, n))
