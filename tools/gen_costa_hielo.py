"""Costa helada del nivel 1, segunda versión (revisión de arte del 14-10-2026, con referencias
de FLUX en local: tools/local/ref_{monticulo,iceberg,tempano,costa}_*.png).

La primera versión (16 voxels/m, icebergs a 8, terrazas en escalones) queda como
models/<pieza>_v1.json: se ve en la partida con `arte=v1`.

- costa_1..3 (32/m): tramo de 8 m del borde de la plataforma. El origen es la línea de la
  orilla, a la altura del suelo; el hielo sale hacia +Z entre 0,4 y 2,2 m con entrantes y
  bloques partidos, y cae en un cantil acanalado con estratos azules hasta debajo del agua
  (el mar está a -1 m). Arriba, una cornisa de nieve que vuela un poco, carámbanos y
  bloques desprendidos al pie.
- tempano_1..5 (32/m): placas flotantes de 0,7 a 3,2 m de radio, 0,35 m sobre el agua, con
  canto biselado, grietas azules, placas de nieve y trozos sueltos alrededor. El origen
  queda 0,15 m sobre el agua (ArenaBuilder baja lo que está en el mar a sea.level - 0,15).
- monticulo_1..3 (32/m): crestas de presión en tierra, de 1 a 2,2 m de radio: bloques de
  hielo inclinados y apilados, cada uno con su tono, juntas azules, aristas escarchadas,
  nieve en lo plano y ventisquero al pie.
- iceberg_1..2 (16/m): icebergs tabulares de 4 a 5 m de radio, paredes acanaladas con
  estratos, grietas profundas y una cueva, nieve arriba con cornisa.

Uso: python tools/gen_costa_hielo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

ICE_A = (0.76, 0.87, 0.95)
ICE_B = (0.58, 0.75, 0.88)
ICE_C = (0.40, 0.60, 0.80)
DEEP = (0.20, 0.40, 0.64)
CRACK = (0.16, 0.32, 0.54)
FROST = (0.88, 0.94, 0.99)
WATERLINE = (0.34, 0.54, 0.70)
SNOW = (0.93, 0.95, 0.99)
SNOW_SH = (0.82, 0.87, 0.94)
P = 'body'
NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))


def clamp01(v): return max(0.0, min(1.0, v))


def hollow(M):
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in NB)]:
        del M.V[k]


def exposed(V, k):
    return sum((k[0] + a, k[1] + b, k[2] + c) not in V for a, b, c in NB)


def snow_cap(M, cols, floor, chance=0.3, depth=(1, 3), scale=10.0):
    """Nieve en lo alto de cada columna casi llana: 1-3 voxels, a placas."""
    tops = {}
    for (x, y, z) in M.V:
        if y > tops.get((x, z), floor - 99): tops[(x, z)] = y
    for (x, z), h in tops.items():
        nb = [tops.get((x + dx, z + dz)) for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        if any(n is None or n < h - 1 for n in nb): continue          # borde o pendiente: sin nieve
        n = M.noise(x, 0, z, scale)
        if n < chance: continue
        d = depth[0] + int((depth[1] - depth[0] + 0.99) * clamp01((n - chance) / (1 - chance)))
        for y in range(h + 1, h + 1 + d):
            M.put(x, y, z, P, SNOW if M.hsh(x, y, z) > 0.2 else SNOW_SH)


# ---------------- bloques orientados (crestas de presión) ----------------

def rot(v, yaw, tx, tz):
    """Gira el vector v (inclinación en X y Z y después guiñada)."""
    x, y, z = v
    c, s = math.cos(tx), math.sin(tx); y, z = y * c - z * s, y * s + z * c
    c, s = math.cos(tz), math.sin(tz); x, y = x * c - y * s, x * s + y * c
    c, s = math.cos(yaw), math.sin(yaw); x, z = x * c + z * s, -x * s + z * c
    return x, y, z


def inv_rot(v, yaw, tx, tz):
    x, y, z = v
    c, s = math.cos(-yaw), math.sin(-yaw); x, z = x * c + z * s, -x * s + z * c
    c, s = math.cos(-tz), math.sin(-tz); x, y = x * c - y * s, x * s + y * c
    c, s = math.cos(-tx), math.sin(-tx); y, z = y * c - z * s, y * s + z * c
    return x, y, z


def ice_block(M, owner, bid, c, size, yaw, tx, tz, floor=0):
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    R = int(math.sqrt(hx * hx + hy * hy + hz * hz)) + 1
    cx, cy, cz = c
    for x in range(int(cx) - R, int(cx) + R + 1):
        for y in range(max(floor, int(cy) - R), int(cy) + R + 1):
            for z in range(int(cz) - R, int(cz) + R + 1):
                lx, ly, lz = inv_rot((x - cx, y - cy, z - cz), yaw, tx, tz)
                if abs(lx) <= hx and abs(ly) <= hy and abs(lz) <= hz:
                    # aristas mordidas: se pierde algún voxel de las esquinas
                    edge = (abs(lx) > hx - 1.2) + (abs(ly) > hy - 1.2) + (abs(lz) > hz - 1.2)
                    if edge >= 2 and M.hsh(x, y, z) < 0.45: continue
                    if (x, y, z) not in owner:
                        owner[(x, y, z)] = bid
                        M.put(x, y, z, P, (0, 0, 0))


def color_blocks(M, owner, tones, floor):
    for k in list(M.V):
        bid = owner.get(k)
        if bid is None: continue
        x, y, z = k
        c = tones[bid]
        n = M.noise(x, y, z, 6.0)
        c = lerp(c, ICE_A, 0.3 * n)
        if M.hsh(x // 3, y // 2, z // 3) < 0.1: c = lerp(c, ICE_C, 0.4)          # burbujas y vetas
        if (y - floor) < 6: c = lerp(c, ICE_C, 0.25)                               # más oscuro al pie
        seam = any(owner.get((x + a, y + b, z + cc), bid) != bid for a, b, cc in NB)
        if seam: c = lerp(c, CRACK, 0.6)                                            # junta entre bloques
        elif exposed(M.V, k) >= 2: c = lerp(c, FROST, 0.55)                         # arista escarchada
        M.V[k][1] = c


def hummock(seed, R, H):
    """Cresta de presión: bloques de hielo inclinados y apilados (ref_monticulo_1000)."""
    M = Model(S=2, seed=seed)
    rng = M.rng
    R *= 32; H *= 32
    owner, tones = {}, []
    ax = rng.uniform(0, math.pi)                                                    # eje de la cresta
    n = int(7 + R / 5)
    for i in range(n):
        t = rng.uniform(-1, 1)
        along = t * R * 0.75
        side = rng.gauss(0, R * 0.16)
        x = along * math.cos(ax) - side * math.sin(ax)
        z = along * math.sin(ax) + side * math.cos(ax)
        hh = H * (1 - 0.55 * t * t) * rng.uniform(0.6, 1.0)
        w = rng.uniform(0.28, 0.5) * R
        d = rng.uniform(0.14, 0.26) * R
        th = rng.uniform(0.75, 1.15) * hh
        tones.append(lerp(ICE_A, ICE_B, rng.uniform(0.3, 1.0)) if rng.random() > 0.3 else lerp(ICE_B, ICE_C, rng.random()))
        ice_block(M, owner, i, (x, th * 0.42, z), (w, th, d), ax + rng.uniform(-0.6, 0.6),
                  rng.uniform(-0.4, 0.4), rng.uniform(-0.3, 0.3))
    for i in range(int(3 + R / 14)):                                                # cascotes alrededor
        a = rng.uniform(0, 2 * math.pi); r = rng.uniform(0.7, 1.0) * R
        s = rng.uniform(5, 11)
        tones.append(lerp(ICE_A, ICE_B, rng.random()))
        ice_block(M, owner, n + i, (r * math.cos(a), s * 0.3, r * math.sin(a)), (s, s * 0.8, s * 1.2),
                  rng.uniform(0, 6.3), rng.uniform(-0.6, 0.6), rng.uniform(-0.6, 0.6))
    color_blocks(M, owner, tones, 0)
    hollow(M)
    snow_cap(M, None, 0, chance=0.55, depth=(1, 3), scale=7.0)
    # ventisquero al pie: nieve amontonada contra el hielo, más alta a barlovento
    occ = {(x, z) for (x, y, z) in M.V}
    for x in range(-int(R * 1.35), int(R * 1.35)):
        for z in range(-int(R * 1.35), int(R * 1.35)):
            if (x, z) in occ: continue
            dmin = 99
            for r in range(1, 8, 2):
                if any((x + dx * r, z + dz * r) in occ for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1))):
                    dmin = r; break
            if dmin > 7: continue
            h = int((8 - dmin) * (0.3 + 0.7 * M.noise(x, 0, z, 6.0)) * (1.2 if x - z < 0 else 0.6))
            for y in range(0, h):
                M.put(x, y, z, P, SNOW if M.hsh(x, y, z) > 0.3 else SNOW_SH)
    hollow(M)
    return M


# ---------------- frente de la plataforma ----------------

def coast(seed):
    M = Model(S=2, seed=seed)
    rng = M.rng
    ph = [rng.uniform(0, 6.28) for _ in range(4)]
    top, bottom = -2, -38                                  # nieve a ras del suelo; el pie bajo el agua (-1 m)
    out = {}
    for x in range(-136, 136):
        # entrantes y salientes: 0,4 a 2,2 m, con tramos rectos (bloques partidos)
        o = 1.3 + 0.55 * math.sin(x * 0.025 + ph[0]) + 0.35 * math.sin(x * 0.065 + ph[1]) + 0.15 * math.sin(x * 0.2 + ph[2])
        o = round(o * 5) / 5
        out[x] = int(max(0.4, min(2.2, o)) * 32)
    # bloques: cada 18-40 voxels cambia el saliente de golpe (se partió)
    x = -136
    while x < 136:
        w = rng.randint(18, 40)
        jump = rng.randint(-6, 6)
        for k in range(x, min(136, x + w)): out[k] = max(12, out[k] + jump)
        x += w
    # acanaladuras verticales de la cara: hendiduras de 1-3 voxels
    groove = {}
    for x in range(-136, 136):
        g = M.noise(x, 0, 0, 3.0)
        groove[x] = 2 if g > 0.78 else (1 if g > 0.6 else 0)
    def face_col(x, y, z):
        c = lerp(ICE_A, ICE_B, clamp01(0.3 + 0.8 * (M.noise(x, y * 0.4, z, 5.0) - 0.4)))
        s = (y - bottom)
        if (s // 5) % 4 == 0: c = lerp(c, ICE_C, 0.3)                              # estratos
        if (s // 11) % 3 == 1 and (s % 11) < 2: c = lerp(c, DEEP, 0.4)
        if groove[x]: c = lerp(c, DEEP, 0.35 * groove[x])
        if M.hsh(x // 2, 9, 0) < 0.06: c = lerp(c, CRACK, 0.6)                     # vetas
        if y < bottom + 8: c = lerp(c, WATERLINE, 0.6)
        if y > top - 4: c = lerp(c, FROST, 0.4)
        return c
    for x in range(-136, 136):
        o = out[x]
        for z in range(0, o):
            edge = z >= o - 3 - groove[x]
            for y in range(bottom, top + 1):
                if z < o - 6 and y < top - 2: continue                              # hueco por dentro
                if edge and z > o - 1 - groove[x] and y < top - 1: continue
                M.put(x, y, z, P, face_col(x, y, z))
        # cornisa de nieve que vuela 2-4 voxels sobre el cantil
        lip = 2 + int(2 * M.noise(x, 0, 1, 6.0))
        for z in range(0, o + lip):
            hh = 1 + int(2 * M.noise(x, 3, z, 7.0)) if z < o - 2 else 1
            for y in range(top + 1, top + 1 + hh):
                M.put(x, y, z, P, SNOW if M.hsh(x, y, z) > 0.2 else SNOW_SH)
            if z >= o:                                                              # el canto de la cornisa
                M.put(x, top, z, P, SNOW_SH)
        # carámbanos bajo la cornisa
        if M.hsh(x, 5, 5) < 0.3:
            L = rng.randint(3, 10)
            for y in range(top - L, top):
                M.put(x, y, o + lip - 1, P, lerp(FROST, ICE_A, (top - y) / L))
    # bloques desprendidos al pie, en el agua
    for i in range(rng.randint(4, 7)):
        bx = rng.randint(-130, 130)
        bz = out[bx] + rng.randint(2, 18)
        s = rng.randint(5, 14)
        yaw, t1, t2 = rng.uniform(0, 6.3), rng.uniform(-0.4, 0.4), rng.uniform(-0.4, 0.4)
        owner = {}
        ice_block(M, owner, 0, (bx, bottom + 22 + s * 0.2, bz), (s * 1.3, s, s), yaw, t1, t2, floor=bottom)
        for k in owner:
            M.V[k][1] = lerp(ICE_A, ICE_B, M.noise(*k, 4.0)) if exposed(M.V, k) < 2 else FROST
            if k[1] > bottom + 22 + s * 0.4 and M.hsh(*k) > 0.5: M.V[k][1] = SNOW
    hollow(M)
    return M


# ---------------- témpanos ----------------

def floe(seed, r):
    M = Model(S=2, seed=seed)
    rng = M.rng
    ph = [rng.uniform(0, 6.28) for _ in range(3)]
    R = r * 32
    top, bottom = 6, -8                                     # 0,35 m sobre el agua (el agua queda en y = 4,8)
    sides = rng.randint(6, 9)
    hmap = {}
    for x in range(-int(R * 1.4), int(R * 1.4)):
        for z in range(-int(R * 1.4), int(R * 1.4)):
            a = math.atan2(z, x)
            rr = R * (1 + 0.14 * math.sin(3 * a + ph[0]) + 0.07 * math.sin(7 * a + ph[1]))
            k = math.floor((a + ph[2]) / (2 * math.pi / sides))
            a0 = k * 2 * math.pi / sides - ph[2] + math.pi / sides
            d = math.hypot(x, z) * math.cos(a - a0)
            if d > rr: continue
            hmap[(x, z)] = rr - d                           # distancia al canto
    # grietas: rectas desde un punto, quebradas
    crack = set()
    for i in range(1 + int(r * 1.5)):
        a = rng.uniform(0, 6.28); x, z = rng.uniform(-R, R) * 0.3, rng.uniform(-R, R) * 0.3
        for s in range(int(R * 2.2)):
            a += rng.uniform(-0.25, 0.25)
            x += math.cos(a); z += math.sin(a)
            crack.add((int(x), int(z)))
    for (x, z), e in hmap.items():
        h = top
        if e < 2: h -= 2                                     # bisel del canto
        elif e < 4: h -= 1
        snowy = e > 5 and M.noise(x, 0, z, 9.0 + r * 3) > 0.42 and (x, z) not in crack
        for y in range(bottom, h + 1):
            if y < h and e > 2: continue                     # hueco por dentro (el fondo no se ve)
            if y == h:
                c = lerp(ICE_A, FROST, 0.4 * M.noise(x, 1, z, 4.0))
                if (x, z) in crack: c = CRACK
                elif any((x + dx, z + dz) in crack for dx, dz in ((1, 0), (0, 1), (-1, 0), (0, -1))): c = lerp(ICE_B, CRACK, 0.3)
            elif y <= 4: c = lerp(WATERLINE, ICE_C, 0.4 * M.noise(x, y, z, 3.0))
            else: c = lerp(ICE_A, ICE_B, M.noise(x, y, z, 3.0))
            M.put(x, y, z, P, c)
        if snowy:
            d = 1 + int(2 * M.noise(x, 5, z, 6.0) > 0.6)
            for y in range(h + 1, h + 1 + d): M.put(x, y, z, P, SNOW if M.hsh(x, y, z) > 0.25 else SNOW_SH)
    # trozos sueltos que flotan alrededor
    for i in range(int(2 + r * 3)):
        a = rng.uniform(0, 6.28); d = R * rng.uniform(1.12, 1.45)
        cx, cz = int(d * math.cos(a)), int(d * math.sin(a))
        s = rng.randint(2, 4 + int(r * 2))
        for x in range(cx - s, cx + s + 1):
            for z in range(cz - s, cz + s + 1):
                if abs(x - cx) + abs(z - cz) > s * 1.4: continue
                for y in range(3, 6): M.put(x, y, z, P, ICE_A if y == 5 else WATERLINE)
    hollow(M)
    return M


# ---------------- icebergs ----------------

def iceberg(seed, R, H):
    """Tabular (ref_iceberg_1001): paredes acanaladas con estratos, grietas y una cueva."""
    M = Model(S=1, seed=seed)
    rng = M.rng
    ph = [rng.uniform(0, 6.28) for _ in range(5)]
    R *= 16; H *= 16
    sides = 7
    cave_a = rng.uniform(0, 6.28)
    hmap = {}
    for x in range(-int(R * 1.3), int(R * 1.3)):
        for z in range(-int(R * 1.3), int(R * 1.3)):
            a = math.atan2(z, x)
            rr = R * (1 + 0.16 * math.sin(2 * a + ph[0]) + 0.07 * math.sin(5 * a + ph[1]))
            rr += 1.6 * (M.noise(a * 30, 0, 0, 1.0) - 0.5) * 2                     # acanaladuras de verdad
            k = math.floor((a + ph[2]) / (2 * math.pi / sides))
            a0 = k * 2 * math.pi / sides - ph[2] + math.pi / sides
            d = math.hypot(x, z) * math.cos(a - a0)
            if d > rr: continue
            e = rr - d
            # mesa con un escalón y una grieta que la parte
            h = H if (x * math.cos(ph[3]) + z * math.sin(ph[3])) < R * 0.25 else H * 0.72
            if (x * math.cos(ph[4] + 1.9) + z * math.sin(ph[4] + 1.9)) > R * 0.45: h = min(h, H * 0.5)
            h += 3 * M.noise(x, 0, z, 10.0)
            if abs(x * math.cos(ph[4]) + z * math.sin(ph[4])) < 1.2 and e > 3: h -= 6      # grieta estrecha
            if e < 3: h -= 2 * (3 - e)
            hmap[(x, z)] = (int(h), e, a)
    crev = set()                                                                     # grietas de la mesa
    for i in range(4):
        a = rng.uniform(0, 6.28); x, z = rng.uniform(-R, R) * 0.4, rng.uniform(-R, R) * 0.4
        for s in range(int(R * 1.4)):
            a += rng.uniform(-0.2, 0.2); x += math.cos(a); z += math.sin(a)
            crev.add((int(x), int(z)))
    for (x, z), (h, e, a) in hmap.items():
        fl = M.noise(a * 30, 0, 0, 1.0)                                              # acanaladuras
        lo = min(hmap.get((x + dx, z + dz), (-4,))[0] for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        for y in range(-4, h + 1):
            if e > 2.5 and y < min(h - 2, lo - 1): continue
            if e < 1.5 and 1 <= y <= 4: continue                                     # entalladura de las olas
            # cueva en una de las caras
            if abs(((a - cave_a + math.pi) % (2 * math.pi)) - math.pi) < 0.22 and y < H * 0.45 and e < 6: continue
            if y >= h - 1 and e > 2:
                c = SNOW if M.hsh(x, y, z) > 0.2 else SNOW_SH
                rip = (x + 2 * z + int(4 * M.noise(x, 0, z, 9.0))) % 9                 # sastrugi
                if rip < 2: c = SNOW_SH
                if M.noise(x, 2, z, 7.0) > 0.68: c = lerp(ICE_A, ICE_B, M.noise(x, 3, z, 2.0))   # hielo al aire
                if (x, z) in crev: c = DEEP if y == h - 1 else CRACK
            else:
                c = lerp(ICE_A, ICE_B, clamp01(fl))
                if (y // 4) % 3 == 0: c = lerp(c, ICE_C, 0.3)
                if fl > 0.72: c = lerp(c, DEEP, 0.5)
                if y <= 2: c = lerp(c, WATERLINE, 0.7)
                if y > h - 4: c = lerp(c, FROST, 0.5)
            M.put(x, y, z, P, c)
    # el fondo de la cueva, azul profundo
    for (x, z), (h, e, a) in hmap.items():
        if abs(((a - cave_a + math.pi) % (2 * math.pi)) - math.pi) < 0.22 and 5 <= e < 7:
            for y in range(-4, int(H * 0.45)): M.put(x, y, z, P, lerp(DEEP, CRACK, M.noise(x, y, z, 3.0)))
    hollow(M)
    return M


def out(M, name):
    n = M.export('models/%s.json' % name, {P: [0, 0, 0]}, jitter=0.004, pivots_in_voxels=True,
                 roughness=0.35, specular=0.55, no_bottom=True)
    print(name, n, 'voxels')


if __name__ == '__main__':
    only = sys.argv[1:]
    def want(n): return not only or any(n.startswith(o) for o in only)
    for i, seed in enumerate((11, 22, 33)):
        if want('costa'): out(coast(seed), 'costa_%d' % (i + 1))
    for i, (seed, r) in enumerate(((41, 0.7), (42, 1.1), (43, 1.6), (44, 2.3), (45, 3.2))):
        if want('tempano'): out(floe(seed, r), 'tempano_%d' % (i + 1))
    for i, (seed, R, H) in enumerate(((51, 4.5, 5.0), (52, 3.8, 4.0))):
        if want('iceberg'): out(iceberg(seed, R, H), 'iceberg_%d' % (i + 1))
    for i, (seed, R, H) in enumerate(((61, 1.6, 1.4), (62, 2.2, 1.9), (63, 1.1, 0.9))):
        if want('monticulo'): out(hummock(seed, R, H), 'monticulo_%d' % (i + 1))
