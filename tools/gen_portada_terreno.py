"""Terreno de la portada: cordillera del fondo, colinas intermedias, llanura nevada y lago
helado. Cada pieza es un modelo voxel con su propio tamaño de voxel (más grueso cuanto
más lejos: de lejos sigue leyéndose como voxel y el número de voxels no se dispara).

Coordenadas del mundo en metros: la cámara mira hacia -Z desde z ≈ +28; el lago está en
el primer término, las colinas hacia z = -60…-100 y la cordillera hacia z = -140…-300.
Los voxels se escriben en coordenadas absolutas (el modelo se coloca en el origen).

La cordillera deja un collado bajo en el centro (x ≈ 0): por ahí asomará Cthulhu.
Uso: python tools/gen_portada_terreno.py
"""
import json, math
import numpy as np

rng = np.random.default_rng(1936)

# ---------------- ruido de valor (numpy) ----------------
def value_noise(x, z, cell, seed):
    """Ruido suave en [0,1] sobre arrays x, z (metros); `cell` = tamaño de la celda."""
    r = np.random.default_rng(seed)
    grid = r.random((512, 512))
    gx = x / cell; gz = z / cell
    ix = np.floor(gx).astype(int); iz = np.floor(gz).astype(int)
    fx = gx - ix; fz = gz - iz
    fx = fx * fx * (3 - 2 * fx); fz = fz * fz * (3 - 2 * fz)
    ix %= 511; iz %= 511
    a = grid[ix, iz]; b = grid[ix + 1, iz]; c = grid[ix, iz + 1]; d = grid[ix + 1, iz + 1]
    return (a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz

def fbm(x, z, cell, octaves, seed, ridged=False):
    total = np.zeros_like(x, dtype=float); amp = 1.0; norm = 0.0
    for o in range(octaves):
        n = value_noise(x, z, cell / (2 ** o), seed + o * 17)
        if ridged: n = 1.0 - np.abs(n * 2 - 1)
        total += n * amp; norm += amp; amp *= 0.5
    return total / norm

def bump(x, z, cx, cz, rx, rz, h):
    return h * np.exp(-(((x - cx) / rx) ** 2 + ((z - cz) / rz) ** 2))

def lerp(a, b, t): return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))

SNOW = (0.84, 0.88, 0.94); SNOW_SH = (0.62, 0.70, 0.82); ROCK = (0.17, 0.18, 0.21)
ROCK_L = (0.30, 0.30, 0.33); STRATA = (0.26, 0.23, 0.22); ICE_BLUE = (0.55, 0.70, 0.84)

# ---------------- de altura a voxels ----------------
def columns_to_voxels(H, vs, x0, z0, color_fn):
    """H: matriz de alturas (m) por columna. Cada columna se rellena desde su cima hasta
    la cima más baja de sus vecinas (lo justo para que no queden huecos en las laderas)."""
    top = np.maximum(0, np.round(H / vs).astype(int))
    pad = np.pad(top, 1, mode='edge')
    neigh_min = np.minimum.reduce([pad[:-2, 1:-1], pad[2:, 1:-1], pad[1:-1, :-2], pad[1:-1, 2:]])
    bottom = np.maximum(0, np.minimum(top, neigh_min) - 1)
    gz, gx = np.gradient(H, vs)
    slope = np.sqrt(gx * gx + gz * gz)
    out = []
    nx, nz = H.shape
    for i in range(nx):
        for j in range(nz):
            t = int(top[i, j])
            for y in range(int(bottom[i, j]), t + 1):
                c = color_fn(i, j, y, t, float(slope[i, j]), vs)
                out.append([int(x0 / vs) + i, y, int(z0 / vs) + j, 'body',
                             round(c[0], 3), round(c[1], 3), round(c[2], 3), 0])
    return out

def export(name, voxels, vs, rough=0.85, spec=0.3):
    with open('models/%s.json' % name, 'w') as f:
        json.dump({'voxel_size': vs, 'pivots': {'body': [0, 0, 0]}, 'voxels': voxels,
                   'roughness': rough, 'specular': spec}, f)
    print('%s: %d voxels (voxel de %.2f m)' % (name, len(voxels), vs))

# ---------------- cordillera del fondo ----------------
# (x, z, altura, radio): picos afilados colocados para el encuadre de la portada. Los dos
# grandes flanquean el collado central, por donde asoma Cthulhu.
PEAKS = [(-118, -228, 78, 58), (130, -218, 84, 62), (-215, -262, 62, 56), (228, -258, 60, 52),
         (-58, -276, 46, 40), (66, -282, 50, 42), (-170, -205, 40, 34), (182, -196, 38, 34),
         (-285, -240, 48, 50), (295, -236, 46, 48), (-16, -305, 26, 32), (26, -310, 28, 34)]

def cordillera():
    """Cordillera imposible: picos piramidales afilados y empinados (en voxel se leen como
    roca escarpada, no como escalera), surcados por cárcavas, un collado bajo en el centro
    y las formaciones cúbicas que Lovecraft describe cerca de las cimas."""
    vs = 1.5
    xs = np.arange(-340, 340, vs); zs = np.arange(-340, -150, vs)
    X, Z = np.meshgrid(xs, zs, indexing='ij')
    warp_x = (fbm(X, Z, 50, 3, 13) - 0.5) * 30
    warp_z = (fbm(X, Z, 50, 3, 17) - 0.5) * 30
    H = np.zeros_like(X)
    for (px, pz, h, r) in PEAKS:
        d = np.sqrt((X + warp_x - px) ** 2 + ((Z + warp_z - pz) * 1.2) ** 2)
        H = np.maximum(H, h * np.clip(1 - d / r, 0, 1) ** 1.25)
    gullies = fbm(X * 1.4, Z * 0.7, 26, 3, 19, ridged=True)          # cárcavas de arriba abajo
    H *= 0.72 + 0.28 * gullies
    crags = fbm(X, Z, 9, 3, 37, ridged=True)                           # contorno quebrado de agujas
    H += (H / 80.0) * (crags - 0.5) * 16.0
    H += np.clip((-Z - 160) / 60, 0, 1) * (7 + 6 * fbm(X, Z, 30, 2, 21))     # zócalo continuo
    cell = 7                                                            # formaciones cúbicas (~10 m)
    cubes = fbm(X, Z, 45, 2, 29)
    Hc = H.copy()
    for i0 in range(0, H.shape[0], cell):
        for j0 in range(0, H.shape[1], cell):
            blk = H[i0:i0 + cell, j0:j0 + cell]
            if blk.max() > 34 and cubes[i0, j0] > 0.74:                  # pocas, sueltas
                Hc[i0:i0 + cell, j0:j0 + cell] = np.maximum(blk, blk.max() - 1.5)
    H = Hc
    def color(i, j, y, t, slope, vs):
        h = y * vs
        if y < t:
            return STRATA if (y % 4 == 0) else lerp(ROCK, ROCK_L, 0.12 + 0.1 * ((i + j) % 3))
        if slope > 1.1: return lerp(ROCK, ROCK_L, 0.3)
        return lerp(SNOW_SH, SNOW, min(1.0, 0.4 + h / 140))
    export('portada_cordillera', columns_to_voxels(H, vs, xs[0], zs[0], color), vs)

# ---------------- colinas intermedias ----------------
def colinas():
    """Colinas bajas en terrazas con cortados de roca: en voxel, mesetas y riscos verticales
    se ven naturales; las pendientes suaves dibujan escaleras."""
    vs = 1.0
    xs = np.arange(-170, 170, vs); zs = np.arange(-140, -55, vs)
    X, Z = np.meshgrid(xs, zs, indexing='ij')
    ramp = np.clip((-Z - 58) / 30, 0, 1)
    raw = ramp * (2 + 13 * fbm(X, Z, 40, 4, 41) ** 1.5)
    raw *= 1.0 - 0.7 * np.exp(-((X / 40) ** 2))                        # abierto en el centro
    step = 3.0
    H = np.floor(raw / step + fbm(X, Z, 14, 2, 45) * 0.8) * step       # terrazas
    H = np.maximum(H, raw * 0.25) + fbm(X, Z, 5, 2, 43) * 0.6
    def color(i, j, y, t, slope, vs):
        if y < t: return STRATA if y % 3 == 0 else ROCK
        if slope > 1.4: return ROCK_L
        n = ((i * 7 + j * 13) % 11) / 11.0
        return lerp(SNOW_SH, SNOW, 0.55 + 0.4 * n)
    export('portada_colinas', columns_to_voxels(H, vs, xs[0], zs[0], color), vs)

# ---------------- llanura y lago ----------------
def lake_mask(X, Z):
    """Contorno irregular del lago helado (1 dentro, 0 fuera)."""
    r = np.sqrt((X / 34.0) ** 2 + ((Z + 18) / 26.0) ** 2)
    edge = 1.0 + 0.18 * (fbm(X, Z, 10, 3, 51) - 0.5)
    return (r < edge).astype(float)

def llanura_parte(name, vs, x_range, z_range, seed_off=0):
    xs = np.arange(x_range[0], x_range[1], vs); zs = np.arange(z_range[0], z_range[1], vs)
    X, Z = np.meshgrid(xs, zs, indexing='ij')
    L = lake_mask(X, Z)
    drift = fbm(X, Z, 11, 3, 61)
    H = 0.35 + 0.55 * drift ** 1.4                             # ondulaciones suaves de nieve
    H += np.clip((-Z - 30) / 25, 0, 1) * 3.0                   # sube hacia las colinas
    H += bump(X, Z, -30, 22, 10, 6, 1.2) + bump(X, Z, 34, 16, 12, 7, 1.6)   # ventisqueros laterales
    H = np.where(L > 0, -0.5, H)
    shade = fbm(X, Z, 3.5, 2, 67)
    def color(i, j, y, t, slope, vs):
        if y < t: return SNOW_SH
        if slope > 1.2: return lerp(SNOW_SH, ROCK_L, 0.25)
        return lerp(SNOW_SH, SNOW, 0.62 + 0.3 * float(shade[i, j]))
    vox = columns_to_voxels(H + 0.5, vs, xs[0], zs[0], color)
    for v in vox: v[1] -= int(round(0.5 / vs))
    export(name, vox, vs)

def llanura():
    llanura_parte('portada_llanura', 0.5, (-70, 70), (-58, 4))
    llanura_parte('portada_primer_termino', 0.25, (-42, 42), (4, 38))

def lago():
    vs = 0.5
    xs = np.arange(-40, 40, vs); zs = np.arange(-50, 12, vs)
    X, Z = np.meshgrid(xs, zs, indexing='ij')
    L = lake_mask(X, Z)
    crack = fbm(X, Z, 3.0, 2, 71)
    tone = fbm(X, Z, 14, 3, 73)
    out = []
    for i in range(len(xs)):
        for j in range(len(zs)):
            if L[i, j] <= 0: continue
            dark = (0.10, 0.16, 0.22); mid = (0.20, 0.30, 0.40)
            c = lerp(dark, mid, float(tone[i, j]))
            if tone[i, j] > 0.78: c = lerp(c, (0.62, 0.70, 0.80), 0.6)   # placas de escarcha
            out.append([int(xs[0] / vs) + i, -1, int(zs[0] / vs) + j, 'body',
                        round(c[0], 3), round(c[1], 3), round(c[2], 3), 0])
    export('portada_lago', out, vs, rough=0.06, spec=0.9)

if __name__ == '__main__':
    cordillera(); colinas(); llanura(); lago()
