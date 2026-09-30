"""Costa helada del nivel 1 (30-09-2026, referencias del autor): frente de la plataforma de
hielo, témpanos de varios tamaños e icebergs.

A 16 voxels por metro (los icebergs a 8, son grandes y van lejos). Solo la cáscara visible:
cada columna se rellena desde la altura más baja de sus vecinas hasta la suya.

- costa_1..3: tramo de 8 m del borde de la plataforma. El origen es la línea de la orilla, a
  la altura del suelo; el hielo sale hacia +Z entre 0,4 y 2,2 m con entrantes, y cae en un
  cantil con vetas azules hasta debajo del agua (el mar está a -1 m). Arriba, nieve a ras del suelo.
- tempano_1..5: placas flotantes de 0,7 a 3,2 m de radio, 0,35 m sobre el agua, con nieve
  encima que no llega al borde. El origen queda 0,15 m sobre el agua (ArenaBuilder baja lo
  que está en el mar a sea.level - 0,15).
- monticulo_1..3: montículos de hielo en tierra, de 1 a 2,2 m de radio (obstáculos).
- iceberg_1..2: moles de 4 a 5 m de radio y 4 a 6 m de alto, en terrazas, con grietas.

Uso: python tools/gen_costa_hielo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

ICE_A = (0.74, 0.85, 0.93)
ICE_B = (0.58, 0.74, 0.86)
ICE_C = (0.44, 0.62, 0.79)
CRACK = (0.22, 0.40, 0.60)
WATERLINE = (0.36, 0.55, 0.70)
SNOW = (0.92, 0.94, 0.98)
SNOW_SH = (0.83, 0.87, 0.93)
P = 'body'


def shell(M, hmap, col_fn, floor):
    """Rellena cada columna (x, z) -> altura, desde la más baja de sus vecinas (o `floor`)."""
    for (x, z), h in hmap.items():
        lo = h
        for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            lo = min(lo, hmap.get((x + dx, z + dz), floor))
        for y in range(max(floor, lo - 1), h + 1):
            M.put(x, y, z, P, col_fn(x, y, z, h))


def ice_side(M, x, y, z, bands=True):
    """Pared de hielo: estratos y vetas verticales azules."""
    n = M.noise(x * 0.9, 0, z * 0.9, 1.0)
    streak = M.hsh(x // 2, 7, z // 2) < 0.12
    c = lerp(ICE_A, ICE_B, min(1.0, max(0.0, 0.5 + 0.6 * n)))
    if bands and (y // 3) % 3 == 0: c = lerp(c, ICE_C, 0.35)
    if streak: c = lerp(c, CRACK, 0.55)
    return c


def snow(M, x, z):
    return SNOW if M.hsh(x, 3, z) > 0.25 else SNOW_SH


# ---------------- frente de la plataforma ----------------

def coast(seed):
    M = Model(S=1, seed=seed)
    ph = [M.rng.uniform(0, 6.28) for _ in range(4)]
    top, bottom = -1, -18                                  # nieve a ras del suelo; el pie bajo el agua (-1 m)
    hmap = {}
    for x in range(-68, 68):
        # entrantes y salientes: 0,4 a 2,2 m, con tramos rectos (bloques partidos)
        o = 1.3 + 0.55 * math.sin(x * 0.05 + ph[0]) + 0.35 * math.sin(x * 0.13 + ph[1]) + 0.15 * math.sin(x * 0.4 + ph[2])
        o = round(o * 4) / 4
        out = int(max(0.4, min(2.2, o)) * 16)
        for z in range(0, out):
            hmap[(x, z)] = top
    def col(x, y, z, h):
        if y == h: return snow(M, x, z) if hmap.get((x, z + 1)) is not None or M.hsh(x, 1, z) > 0.3 else ICE_A
        if y <= bottom + 3: return WATERLINE
        return ice_side(M, x, y, z)
    shell(M, hmap, col, bottom)
    # la cara del cantil: hasta el fondo en toda la orilla
    for (x, z), h in hmap.items():
        if (x, z + 1) not in hmap:
            for y in range(bottom, h):
                M.put(x, y, z, P, col(x, y, z, h))
    return M


# ---------------- témpanos ----------------

def floe(seed, r):
    M = Model(S=1, seed=seed)
    ph = [M.rng.uniform(0, 6.28) for _ in range(3)]
    R = r * 16
    top, bottom = 3, -4                                     # 0,35 m sobre el agua (el agua queda en y = 2,4)
    hmap = {}
    for x in range(-int(R * 1.4), int(R * 1.4)):
        for z in range(-int(R * 1.4), int(R * 1.4)):
            a = math.atan2(z, x)
            rr = R * (1 + 0.16 * math.sin(3 * a + ph[0]) + 0.08 * math.sin(7 * a + ph[1]))
            # bordes rectos a trozos: la distancia se mide en un polígono de 7 lados
            k = math.floor((a + ph[2]) / (2 * math.pi / 7))
            a0 = k * 2 * math.pi / 7 - ph[2] + math.pi / 7
            d = math.hypot(x, z) * math.cos(a - a0)
            if d > rr: continue
            h = top
            if d < rr - 5: h += 1 + (1 if M.noise(x * 0.12, 0, z * 0.12, 2.0) > 0.25 else 0)   # nieve
            hmap[(x, z)] = h
    def col(x, y, z, h):
        if y == h: return snow(M, x, z) if h > top else ICE_A
        if y > top: return SNOW_SH
        if y <= 0: return WATERLINE
        return ice_side(M, x, y, z, bands=False)
    shell(M, hmap, col, bottom)
    return M


# ---------------- icebergs ----------------

def iceberg(seed, R, H, land=False):
    M = Model(S=1, seed=seed)
    ph = [M.rng.uniform(0, 6.28) for _ in range(4)]
    R *= 16; H *= 16
    hmap = {}
    for x in range(-int(R * 1.3), int(R * 1.3)):
        for z in range(-int(R * 1.3), int(R * 1.3)):
            a = math.atan2(z, x)
            rr = R * (1 + 0.2 * math.sin(2 * a + ph[0]) + 0.1 * math.sin(5 * a + ph[1]))
            d = math.hypot(x, z) / rr
            if d > 1: continue
            # cumbre desplazada, en terrazas de 6 voxels, con agujas
            cx, cz = 0.25 * R * math.cos(ph[2]), 0.25 * R * math.sin(ph[2])
            dd = math.hypot(x - cx, z - cz) / rr
            h = H * max(0.0, 1 - dd) ** 0.7 + 10 * M.noise(x * 0.05, 0, z * 0.05, 3.0)
            h = max(3 if land else 6, int(h // (3 if land else 6)) * (3 if land else 6) + (3 if M.hsh(x // 6, 0, z // 6) > 0.7 else 0))
            hmap[(x, z)] = h
    def col(x, y, z, h):
        flat = all(hmap.get((x + dx, z + dz), -99) >= h for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if y == h and flat: return snow(M, x, z)
        if y >= h - 1 and flat: return SNOW_SH
        if y <= 2 and not land: return WATERLINE
        if land and y <= 3: return SNOW_SH                   # nieve amontonada al pie
        return ice_side(M, x, y, z)
    shell(M, hmap, col, 0 if land else -4)
    return M


def half_res(M):
    H = Model(S=1, seed=M.rng.randint(0, 9999))
    for (x, y, z), v in M.V.items():
        k = (x // 2, y // 2, z // 2)
        if k not in H.V or v[1] in (SNOW, SNOW_SH): H.V[k] = [v[0], v[1], v[2]]
    H.S = 0.5
    return H


def out(M, name):
    n = M.export('models/%s.json' % name, {P: [0, 0, 0]}, jitter=0.006, pivots_in_voxels=True,
                 roughness=0.4, specular=0.5, no_bottom=True)
    print(name, n, 'voxels')


for i, seed in enumerate((11, 22, 33)):
    out(coast(seed), 'costa_%d' % (i + 1))
for i, (seed, r) in enumerate(((41, 0.7), (42, 1.1), (43, 1.6), (44, 2.3), (45, 3.2))):
    out(floe(seed, r), 'tempano_%d' % (i + 1))
for i, (seed, R, H) in enumerate(((51, 4.5, 6.0), (52, 3.8, 4.5))):
    out(half_res(iceberg(seed, R, H)), 'iceberg_%d' % (i + 1))
# montículos de hielo en tierra (sustituyen a las rocas): 16 voxels/m, más bajos
for i, (seed, R, H) in enumerate(((61, 1.6, 1.4), (62, 2.2, 1.9), (63, 1.1, 0.9))):
    out(iceberg(seed, R, H, land=True), 'monticulo_%d' % (i + 1))
