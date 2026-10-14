"""Atrezo del paso de la cordillera y sus cavernas (nivel 3 de la parte 1, hito 4.3), a 32
voxels por metro: roca grande de caras planas con nieve encima, estalagmita, columna tallada
por los Antiguos (relieves de estrellas de cinco puntas, rota) y un grupo de cristales de
hielo que brillan con luz propia (azul pálido, sin sombreado).
Escribe models/atrezo_{roca_grande,estalagmita,columna_tallada,cristales}.json.
Uso: python tools/gen_atrezo_paso.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
ROCK = (0.40, 0.38, 0.37); ROCK_D = (0.24, 0.23, 0.23); ROCK_L = (0.52, 0.50, 0.48)
STONE = (0.46, 0.44, 0.38); STONE_D = (0.30, 0.29, 0.25)         # piedra de los Antiguos
SNOW = (0.88, 0.91, 0.95); SNOW_SH = (0.78, 0.83, 0.90)
ICE = (0.16, 0.38, 0.72); ICE_L = (0.30, 0.58, 0.88)       # sin sombreado: ACES los quema, más oscuros


def cap_snow(M, prob=0.8, depth=1):
    cols = {}
    for (x, y, z) in M.V:
        if y > cols.get((x, z), -99): cols[(x, z)] = y
    for (x, z), y in cols.items():
        if M.hsh(x, y, z) > prob: continue
        for d in range(depth):
            M.put(x, y + 1 + d, z, P, SNOW if M.hsh(x, 3, z) > 0.3 else SNOW_SH, over=False)


def roca_grande():
    """Roca de caras planas (superelipsoide), 2,5 m, con vetas y nieve en lo alto."""
    M = Model(S=2, seed=51)
    # bloques de caras planas, más anchos que altos y apoyados unos en otros (redondeada,
    # con dos huecos oscuros abajo, parecía una calavera)
    M.sell(0, 5, 0, 13, 6, 10, P, ROCK, p=4.5)
    M.sell(-3, 11, -2, 8, 5, 7, P, ROCK, p=4.0)
    M.sell(7, 4, -5, 6, 4, 5, P, ROCK, p=4.0)
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    def paint(k, part, c):
        x, y, z = k
        n = M.noise(x, y, z, 8.0)
        c = lerp(ROCK_D, ROCK_L, n)
        if (x + 2 * y) % 17 == 0: c = ROCK_D                          # vetas
        return c
    M.paint(paint)
    cap_snow(M, 0.55, 1)
    return M


def estalagmita(variant=1):
    """Grupo de estalagmitas (rehecho el 09-10-2026), 32/m: una principal de ~3 m y dos o tres
    menores, cada una con perfil de gota que se afila, acanaladuras verticales por donde baja el
    agua, bandas de depósito mineral más claras, una colada de flujo en la base que las une y
    escarcha pálida en las puntas. Hueca. Dos variantes."""
    M = Model(S=2, seed=52 + variant * 11)
    rng = M.rng
    FLOW = (0.44, 0.45, 0.46); FLOW_L = (0.54, 0.55, 0.57); FROST = (0.74, 0.80, 0.88)   # gris frío: beige salía marrón

    def spike(cx, cz, h, r0, lean):
        for y in range(0, h):
            t = y / h
            r = r0 * (1 - t) ** 0.85 + 0.6                       # perfil de gota afilada
            ox, oz = cx + lean[0] * y, cz + lean[1] * y
            for x in range(int(ox - r) - 2, int(ox + r) + 3):
                for z in range(int(oz - r) - 2, int(oz + r) + 3):
                    ang = math.atan2(z - oz, x - ox)
                    d = math.hypot(x - ox, z - oz) * (1 + 0.12 * math.sin(ang * 7 + cx))   # acanaladuras
                    if not (r - 2.2 <= d <= r): continue
                    groove = math.sin(ang * 7 + cx) > 0.6
                    c = lerp(ROCK_D, ROCK, M.noise(x, y * 0.25, z, 3.0))
                    if groove: c = lerp(c, ROCK_D, 0.5)
                    if (y + int(4 * M.noise(x, 0, z, 6.0))) % 11 < 2: c = lerp(c, FLOW_L, 0.45)   # bandas
                    if M.noise(x, y, z, 2.5) > 0.7: c = lerp(c, FLOW, 0.4)                       # brillo húmedo
                    if t > 0.86: c = lerp(c, FROST, (t - 0.86) / 0.14)                          # escarcha
                    M.put(int(x), y, int(z), P, c)

    spikes = [(0, 0, 96 if variant == 1 else 80, 9, (rng.uniform(-0.03, 0.03), rng.uniform(-0.03, 0.03)))]
    for k in range(2 + variant):
        ang = rng.uniform(0, math.tau); d = rng.uniform(9, 15)
        spikes.append((math.cos(ang) * d, math.sin(ang) * d, rng.randint(26, 56), rng.uniform(3.5, 6),
                       (math.cos(ang) * 0.05, math.sin(ang) * 0.05)))
    for cx, cz, h, r0, lean in spikes:
        spike(cx, cz, h, r0, lean)
    for x in range(-20, 21):                                    # colada en la base
        for z in range(-20, 21):
            d = math.hypot(x, z) * (1 + 0.25 * M.noise(x, 0, z, 5.0))
            if d > 18: continue
            hgt = int(4 * (1 - d / 18) ** 1.5) + (1 if M.noise(x, 3, z, 3.0) > 0.6 else 0)
            for y in range(0, hgt + 1):
                M.put(x, y, z, P, lerp(FLOW, FLOW_L, M.noise(x, y, z, 2.0)) if y == hgt else ROCK_D, over=False)
    return M


def columna_tallada():
    """Columna de los Antiguos rota (revisión de arte del 14-10-2026, referencia de FLUX en local
    tools/local/ref_columna_1001.png; la de antes queda en models/atrezo_columna_tallada_v1.json).
    A 48 voxels/m: zócalo de tres escalones pentagonales con bloques partidos, fuste de cinco caras
    con paneles rehundidos (en cada uno una estrella de cinco puntas en relieve y filas de
    glifos), bandas de meandros, el remate partido a bocados, el tambor caído al lado, cascotes,
    escarcha en las aristas y nieve en lo alto."""
    V = 3
    M = Model(S=V, seed=53)
    rng = M.rng
    ST = (0.54, 0.53, 0.50); ST_D = (0.34, 0.33, 0.31); ST_L = (0.68, 0.67, 0.64); FROST = (0.80, 0.84, 0.90)
    NF = [(math.cos(k * math.tau / 5 + math.pi / 2), math.sin(k * math.tau / 5 + math.pi / 2)) for k in range(5)]
    A = 21                                                         # apotema del fuste en voxels
    def star(u, v, r):                                             # estrella de cinco puntas
        a = math.atan2(v, u); rr = math.hypot(u, v)
        return rr < r * (0.45 + 0.55 * (0.5 + 0.5 * math.cos(5 * (a - math.pi / 2))) ** 2.2)
    def surface(k, s, y, y0, y1):
        """Profundidad de la cara k en el punto (s a lo largo de la cara, altura y)."""
        if y - y0 < 4 or y1 - y < 4: return 0                      # molduras arriba y abajo
        rel = (y - y0) % 34
        if rel < 5: return 0 if (int(s) // 3 + (rel > 2)) % 2 else -1   # banda de meandro
        if abs(s) > A * 0.62 - 2: return 0                          # marco del panel
        if rel < 7 or rel > 32: return 0
        cy = y0 + (y - y0) // 34 * 34 + 20
        if star(s, y - cy, 9): return 0                             # estrella en relieve
        if 10 < abs(y - cy) < 13 and (int(s) // 2) % 3 != 0 and M.hsh(k, int(s) // 6, y // 3) > 0.3: return -1   # glifos
        return -2
    owner = {}
    def column(cx, cy0, cz, height, lying=False, yaw=0.0, broken=True):
        top = {}
        for x in range(-A - 4, A + 5):
            for z in range(-A - 4, A + 5):
                if broken: top[(x, z)] = height - int(18 * M.noise(x, 0, z, 9.0)) - (6 if x + z > 10 else 0)
                else: top[(x, z)] = height
        for y in range(0, height):
            for x in range(-A - 2, A + 3):
                for z in range(-A - 2, A + 3):
                    if y >= top[(x, z)]: continue
                    k = max(range(5), key=lambda k: x * NF[k][0] + z * NF[k][1])
                    d = x * NF[k][0] + z * NF[k][1]
                    s = -x * NF[k][1] + z * NF[k][0]
                    lim = A + surface(k, s, y, 0, height)
                    if d > lim: continue
                    if d < lim - 2 and y < top[(x, z)] - 2 and y > 0: continue   # hueco por dentro
                    if lying:
                        c, sn = math.cos(yaw), math.sin(yaw)
                        px, py, pz = cx + y * c - z * sn, cy0 + A + x, cz + y * sn + z * c
                    else:
                        px, py, pz = cx + x, cy0 + y, cz + z
                    if py < 0: continue
                    shade = 'r' if d < A - 0.5 else 's'
                    M.put(int(px), int(py), int(pz), P, ('col', shade, y, height))
    # zócalo: tres escalones pentagonales de bloques
    for i, (ap, h0, h1) in enumerate(((A + 15, 0, 6), (A + 10, 6, 12), (A + 5, 12, 18))):
        for x in range(-ap - 2, ap + 3):
            for z in range(-ap - 2, ap + 3):
                k = max(range(5), key=lambda k: x * NF[k][0] + z * NF[k][1])
                d = x * NF[k][0] + z * NF[k][1]
                if d > ap: continue
                if d > ap - 4 and M.noise(x, i, z, 5.0) > 0.72: continue        # bloques partidos
                for y in range(h0, h1):
                    if d < ap - 2 and y < h1 - 1 and y > h0: continue
                    M.put(x, y, z, P, ('base', i, x, z))
    column(0, 18, 0, 92)
    column(56, 0, 22, 40, lying=True, yaw=0.5, broken=False)                     # tambor caído
    for i in range(9):                                                         # cascotes
        bx, bz = rng.randint(-60, 70), rng.randint(-50, 60)
        if math.hypot(bx, bz) < A + 16: continue
        s = rng.randint(3, 8)
        for x in range(bx - s, bx + s):
            for z in range(bz - s, bz + s):
                for y in range(0, rng.randint(2, s + 1)):
                    if abs(x - bx) + abs(z - bz) <= s * 1.3: M.put(x, y, z, P, ('base', 3, x, z))
    def paint(k, part, c):
        if not isinstance(c, tuple) or not c or not isinstance(c[0], str): return None
        x, y, z = k
        n = M.noise(x, y, z, 6.0)
        if c[0] == 'base':
            base = lerp(ST_D, ST, 0.4 + 0.4 * M.hsh(c[2] // 12, c[1], c[3] // 12))   # tono por bloque
            if (c[2] % 12 == 0 or c[3] % 12 == 0): base = lerp(base, ST_D, 0.6)       # juntas
        else:
            base = lerp(ST_D, ST, 0.45 + 0.4 * n)
            if c[1] == 'r': base = lerp(base, ST_D, 0.45)                             # rehundido, en sombra
            else: base = lerp(base, ST_L, 0.25)
            if M.noise(x, y, z, 3.0) > 0.78: base = lerp(base, (0.40, 0.44, 0.36), 0.5)  # liquen
        nb = ((x + 1, y, z), (x - 1, y, z), (x, y + 1, z), (x, y - 1, z), (x, y, z + 1), (x, y, z - 1))
        if sum(q not in M.V for q in nb) >= 2: base = lerp(base, FROST, 0.35)         # escarcha en aristas
        return base
    M.paint(paint)
    cap_snow(M, 0.75, depth=2)
    return M


def cristales():
    """Grupo de cristales de hielo (revisión de arte del 14-10-2026, referencia
    tools/local/ref_cristales_1000.png; el de antes queda en models/atrezo_cristales_v1.json).
    A 64 voxels/m: prismas hexagonales con punta piramidal que salen inclinados de una roca
    oscura, caras con dos tonos (una clara y otra en sombra), aristas pálidas, un núcleo que
    brilla (lo único sin sombreado) y la punta encendida, más esquirlas sueltas y escarcha."""
    V = 4
    M = Model(S=V, seed=54)
    rng = M.rng
    C_A = (0.46, 0.72, 0.94); C_B = (0.24, 0.50, 0.84); C_E = (0.80, 0.92, 1.0)
    CORE = (0.30, 0.62, 0.95); TIP = (0.45, 0.70, 0.92)
    # roca de la base: superelipsoide aplastado con caras
    for x in range(-34, 35):
        for z in range(-34, 35):
            for y in range(0, 16):
                d = (abs(x) / 30) ** 2.4 + (abs(z) / 28) ** 2.4 + (y / 14) ** 2.4
                if d <= 1 + 0.15 * (M.noise(x, y, z, 6.0) - 0.5):
                    M.put(x, y, z, P, lerp(ROCK_D, ROCK, 0.3 + 0.5 * M.noise(x, y, z, 4.0)))
    def prism(base, axis, R, L):
        ux, uy, uz = axis
        # base ortonormal del prisma
        ax2 = (0, 0, 1) if abs(uz) < 0.9 else (1, 0, 0)
        e1 = (uy * ax2[2] - uz * ax2[1], uz * ax2[0] - ux * ax2[2], ux * ax2[1] - uy * ax2[0])
        n1 = math.sqrt(sum(c * c for c in e1)); e1 = tuple(c / n1 for c in e1)
        e2 = (uy * e1[2] - uz * e1[1], uz * e1[0] - ux * e1[2], ux * e1[1] - uy * e1[0])
        rot = rng.uniform(0, math.pi / 3)
        Rb = R + 2
        lo = [int(min(base[i], base[i] + axis[i] * L) - Rb - 1) for i in range(3)]
        hi = [int(max(base[i], base[i] + axis[i] * L) + Rb + 2) for i in range(3)]
        for x in range(lo[0], hi[0]):
            for y in range(max(0, lo[1]), hi[1]):
                for z in range(lo[2], hi[2]):
                    p = (x + 0.5 - base[0], y + 0.5 - base[1], z + 0.5 - base[2])
                    t_ = p[0] * ux + p[1] * uy + p[2] * uz
                    if t_ < -4 or t_ > L: continue
                    a_ = p[0] * e1[0] + p[1] * e1[1] + p[2] * e1[2]
                    b_ = p[0] * e2[0] + p[1] * e2[1] + p[2] * e2[2]
                    ang = math.atan2(b_, a_) - rot
                    face = int(((ang % (math.pi / 3 * 6)) / (math.pi / 3)))
                    fa = (ang % (math.pi / 3)) - math.pi / 6
                    rr = math.hypot(a_, b_) * math.cos(fa)                       # distancia a la cara
                    lim = R * min(1.0, (L - t_) / (R * 1.6))                     # punta piramidal
                    if rr > lim: continue
                    k = (x, y, z)
                    if rr < R * 0.28 and t_ < L - R: M.put(x, y, z, P, CORE, glow=1)
                    elif rr > lim - 1.2:
                        edge = abs(fa) > math.pi / 6 - 0.12
                        if edge: M.put(x, y, z, P, C_E)                          # arista: con sombreado
                        else:                                                    # caras: luz propia a dos tonos
                            c = ICE_L if face % 2 else ICE
                            if t_ > L - R * 1.6: c = lerp(c, TIP, 0.5)
                            if M.noise(x, y, z, 3.0) > 0.7: c = lerp(c, (0.12, 0.28, 0.55), 0.5)   # vetas
                            M.put(x, y, z, P, c, glow=1)
    shards = [((0, 8, 0), (0.05, 1, 0.08), 9, 92)]
    for i in range(8):
        a = i / 8 * math.tau + rng.uniform(-0.3, 0.3)
        r = rng.uniform(8, 22)
        tilt = rng.uniform(0.25, 0.7)
        ax = (math.cos(a) * tilt, 1.0, math.sin(a) * tilt)
        n = math.sqrt(sum(c * c for c in ax)); ax = tuple(c / n for c in ax)
        shards.append(((math.cos(a) * r, rng.uniform(4, 10), math.sin(a) * r), ax, rng.uniform(4, 7.5), rng.uniform(26, 64)))
    for i in range(5):                                                        # esquirlas caídas
        a = rng.uniform(0, math.tau); r = rng.uniform(34, 46)
        ax = (math.cos(a + 1.2), 0.15, math.sin(a + 1.2))
        shards.append(((math.cos(a) * r, 2, math.sin(a) * r), ax, rng.uniform(2.5, 3.5), rng.uniform(10, 18)))
    for b, ax, R, L in shards: prism(b, ax, R, L)
    # escarcha en la roca alrededor de los cristales
    for (x, y, z), v in M.V.items():
        if v[2] == 0 and v[1] not in (C_A, C_B, C_E) and M.noise(x, y, z, 2.0) > 0.7 and y > 6:
            v[1] = lerp(v[1], (0.78, 0.86, 0.94), 0.6)
    return M


def roca_estratos():
    """Roca grande en estratos (revisión de arte del 14-10-2026, referencia
    tools/local/ref_roca_grande_1000.png; la de Replicate queda en models/atrezo_roca_grande_v1.json).
    A 32 voxels/m, 1,7 x 1,2 x 1,6 m: bloque de caras planas partido en capas horizontales que
    entran y salen (cada una con su tono), grietas verticales, aristas claras, escarcha y nieve
    en las cornisas de cada capa."""
    M = Model(S=2, seed=51)
    rng = M.rng
    R_D = (0.30, 0.31, 0.36); R_M = (0.46, 0.46, 0.50); R_L = (0.60, 0.60, 0.63)
    layers, y = [], 0
    while y < 36:
        h = rng.randint(5, 10)
        layers.append((y, min(36, y + h), rng.uniform(-3, 3), rng.uniform(-3, 3), rng.uniform(0.88, 1.06), rng.random()))
        y += h
    planes = []
    for j in range(9):
        a = j * math.tau / 9 + rng.uniform(-0.25, 0.25); e = rng.uniform(-0.1, 0.35)
        planes.append(((math.cos(a) * math.cos(e), math.sin(e), math.sin(a) * math.cos(e)), rng.uniform(23, 27)))
    cracks = [(rng.uniform(0, math.pi), rng.uniform(-14, 14)) for _ in range(3)]
    for (y0, y1, ox, oz, sc, tone) in layers:
        taper = 1.0 - 0.35 * (y0 / 36) ** 1.5
        for y in range(y0, y1):
            for x in range(-32, 33):
                for z in range(-32, 33):
                    p = ((x - ox) / (sc * taper), y - 14, (z - oz) / (sc * taper) * 1.08)
                    d = max(p[0] * n[0] + p[1] * n[1] + p[2] * n[2] - dd for n, dd in planes)
                    if d > 0: continue
                    if d < -2.5 and y0 < y < y1 - 1: continue                         # hueco
                    c = lerp(R_D, R_M, 0.3 + 0.5 * tone + 0.2 * M.noise(x, y, z, 4.0))
                    if y == y1 - 1: c = lerp(c, R_L, 0.5)                               # canto de la capa
                    if y == y0: c = lerp(c, R_D, 0.5)                                   # junta de la capa
                    for a, o in cracks:
                        if abs(x * math.cos(a) + z * math.sin(a) - o) < 0.8 and M.noise(x, y, z, 5.0) > 0.35: c = R_D
                    M.put(x, y, z, P, c)
    tops = {}
    for (x, y, z) in M.V:
        if y > tops.get((x, z), -1): tops[(x, z)] = y
    for (x, z), h in tops.items():                                                       # nieve en cornisas
        if M.noise(x, 1, z, 6.0) < 0.38: continue
        for y in range(h + 1, h + 1 + (2 if h > 30 else 1)):
            M.put(x, y, z, P, SNOW if M.hsh(x, y, z) > 0.25 else SNOW_SH)
    for (x, y, z), v in list(M.V.items()):                                               # escarcha en las cornisas de abajo
        if (x, y + 1, z) not in M.V and v[1] not in (SNOW, SNOW_SH) and M.hsh(x, y, z) > 0.5:
            M.put(x, y + 1, z, P, SNOW_SH)
    return M


PIECES = {'roca_grande_mano': roca_grande,   # la del juego es de Replicate (generar_modelo_replicate.py)
          'estalagmita': estalagmita, 'estalagmita_2': lambda: estalagmita(2), 'columna_tallada': columna_tallada,
          'cristales': cristales, 'roca_grande': roca_estratos}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M = fn()
        n = M.export('models/atrezo_%s.json' % name, {P: [0, 0, 0]}, jitter=0.01, pivots_in_voxels=True,
                     roughness=0.85 if name != 'cristales' else 0.2, specular=0.25 if name != 'cristales' else 0.7,
                     no_bottom=True)
        print('atrezo_%s: %d voxels' % (name, n))
