"""Barrera de roca (el paso de la cordillera y los túneles), segunda versión (revisión de arte
del 14-10-2026, referencia de FLUX en local tools/local/ref_acantilado_100{0,1}.png). Antes eran
los tres tramos de la Barrera de hielo recoloreados a 8 voxels/m; quedan como
models/barrera_roca_{1,2,3}_v1.json (se ven con `arte=v1`).

Tres tramos de acantilado de 8 m de ancho, 7 a 9 m de alto y 4 de fondo, a 16 voxels/m (el
doble que antes), con el frente hacia +Z y el origen en el centro de la base del frente:
- estratos de alturas y tonos distintos que entran y salen (cornisas con nieve encima);
- diaclasas verticales que parten cada estrato en bloques, cada uno con su tono, su
  retranqueo y aristas claras arriba y oscuras abajo;
- grietas hondas casi negras, alguna veta de cuarzo y manchas de humedad;
- cumbre con nieve que asoma en cornisa y un pie de bloques caídos y canchal.

Uso: python tools/gen_barrera_roca.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, spill_points

W, D = 64, 64
R_HI = (0.50, 0.48, 0.46); R_MID = (0.38, 0.37, 0.36); R_LO = (0.26, 0.25, 0.25)
CRACK = (0.08, 0.08, 0.09); QUARTZ = (0.74, 0.73, 0.70); DAMP = (0.20, 0.21, 0.22)
SNOW = (0.88, 0.91, 0.95); SNOW_SH = (0.78, 0.82, 0.88)
P = 'body'


def build(seed):
    M = Model(S=1, seed=seed)
    rnd = M.rng
    ph = [rnd.uniform(0, 6.28) for _ in range(4)]
    base_h = rnd.uniform(112, 128)
    def crest(x):
        return int(base_h + 10 * math.sin(x * 0.04 + ph[0]) + 6 * math.sin(x * 0.13 + ph[1]))
    bands, y = [], 0
    while y < 150:
        h = rnd.randint(8, 22)
        bands.append((y, y + h, rnd.choice((R_HI, R_MID, R_MID, R_LO)), rnd.randint(0, 6)))
        y += h
    def band_at(y):
        for i, b in enumerate(bands):
            if b[0] <= y < b[1]: return i, b
        return len(bands) - 1, bands[-1]
    # diaclasas: en cada estrato, cortes verticales cada 8-22 voxels
    joints = []
    for b in bands:
        xs, x = [], -W - rnd.randint(0, 10)
        while x < W + 10:
            w = rnd.randint(8, 22)
            xs.append((x, x + w, rnd.randint(-2, 3), rnd.random()))
            x += w
        joints.append(xs)
    def block_at(x, y):
        bi, b = band_at(y)
        for blk in joints[bi]:
            if blk[0] <= x < blk[1]: return bi, b, blk
        return bi, b, joints[bi][-1]
    cracks = [(rnd.randint(-W + 10, W - 10), rnd.randint(2, 4), rnd.randint(8, 14), rnd.randint(0, 60))
              for _ in range(rnd.randint(2, 4))]
    def crack_at(x, y):
        for cx, cw, cd, cy0 in cracks:
            wob = int(3 * math.sin(y * 0.1 + cx))
            if abs(x - cx - wob) <= cw // 2 and y >= cy0: return cd
        return 0
    def depth(x, y):
        y = max(0, y)
        bi, b, blk = block_at(x, y)
        bulge = 6 * (0.5 + 0.5 * math.sin(x * 0.05 + ph[2])) + 3 * (0.5 + 0.5 * math.sin(x * 0.19 + ph[3]))
        return int(b[3] + blk[2] + bulge + y // 18 + crack_at(x, y))
    quartz = [(rnd.uniform(-0.6, 0.6), rnd.randint(20, 100)) for _ in range(2)]
    for x in range(-W, W):
        top = crest(x)
        for y in range(0, top):
            d = depth(x, y)
            bi, b, blk = block_at(x, y)
            col = lerp(b[2], R_HI if blk[3] > 0.5 else R_LO, 0.3 * abs(blk[3] - 0.5) * 2)
            col = lerp(col, R_LO, 0.25 * M.noise(x, y, 0, 6.0))
            if y == b[1] - 1: col = lerp(col, R_HI, 0.45)                    # canto de arriba del estrato
            if y == b[0]: col = lerp(col, CRACK, 0.5)                         # junta del estrato
            if x == blk[0] or x == blk[1] - 1: col = lerp(col, CRACK, 0.55)   # diaclasa
            for s, q0 in quartz:
                if abs(y - q0 - s * x) < 0.8: col = QUARTZ
            if M.noise(x, y, 3, 9.0) > 0.72 and y < 50: col = lerp(col, DAMP, 0.5)   # humedad
            cd = crack_at(x, y)
            if cd: col = CRACK
            if y + 1 < top and depth(x, y + 1) > d + 1 and not cd:
                col = SNOW if M.hsh(x, y, 1) > 0.35 else SNOW_SH               # nieve en la cornisa
            dm = max(d, depth(x - 1, y), depth(x + 1, y), depth(x, y - 1), depth(x, y + 1)) + 1
            for z in range(-dm, -d + 1):
                M.put(x, y, z, P, col if z == -d else (CRACK if cd else b[2]), over=False)
            M.put(x, y, -d, P, col)
        over = 2 + (1 if math.sin(x * 0.2 + seed) > 0.3 else 0)
        z0 = -depth(x, top - 1) + over
        for z in range(-D, z0):
            yt = top + (1 if (z + x) % 7 == 0 else 0)
            for k in range(3):
                M.put(x, yt - k, z, P, SNOW if k == 0 else SNOW_SH)
    for x in (-W, W - 1):
        for z in range(-D, 0):
            for y in range(0, crest(x)):
                M.put(x, y, z, P, band_at(y)[1][2], over=False)
    # bloques caídos al pie: poliedros de caras planas
    for _ in range(18):
        bx, bz = rnd.randint(-W + 4, W - 8), rnd.randint(-2, 12)
        s = rnd.choice((4, 5, 6, 8, 10, 13))
        tone = rnd.choice((R_HI, R_MID, R_LO))
        for x in range(bx - s, bx + s):
            for z in range(bz - s, bz + s):
                for y in range(0, int(s * 1.3)):
                    if abs(x - bx) + abs(z - bz) * 1.2 + abs(y - s * 0.4) * 1.1 > s * 1.25: continue
                    if (x, y, z) in M.V: continue
                    c = lerp(tone, R_LO, 0.3 * M.noise(x, y, z, 3.0))
                    if (x, y + 1, z) not in M.V and M.hsh(x, y, z) > 0.55: c = SNOW_SH
                    M.put(x, y, z, P, c)
    for x in range(-W, W):                                          # canchal y nieve al pie
        for z in range(0, 14):
            hh = int(5 * (1 - z / 14) * (0.5 + 0.5 * math.sin(x * 0.23 + z * 0.4)))
            for y in range(0, hh):
                c = SNOW_SH if y == hh - 1 and M.hsh(x, y, z) > 0.5 else lerp(R_MID, R_LO, M.hsh(x, y, z))
                M.put(x, y, z, P, c, over=False)
    # bordes de las cornisas del frente con nieve: de ahí cae alguna vez (Ambient, 16-10-2026)
    M.spills = spill_points(M, (SNOW, SNOW_SH), n=10, drop=8, dirs=((0, 1),), min_y=32)
    # vaciar: fuera lo que no se ve
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in NB)]:
        del M.V[k]
    return M


if __name__ == '__main__':
    for i, seed in enumerate((101, 202, 303)):
        M = build(seed + 7)
        n = M.export('models/barrera_roca_%d.json' % (i + 1), {P: [0, 0, 0], **M.spills}, jitter=0.004,
                     pivots_in_voxels=True, roughness=0.85, specular=0.25, no_bottom=True)
        print('barrera_roca_%d' % (i + 1), n, 'voxels')
