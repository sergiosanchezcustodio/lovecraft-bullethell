"""Barrera de hielo (la Barrera de Ross): tramos de acantilado de hielo que cierran la arena
del campamento por el norte y el oeste, en lugar del vacío.

Tres variantes de 8 m de ancho, de 7 a 9 m de alto y 4 m de fondo. Se modelan a 16 voxels
por metro y se exportan a 8 (half_res): es fondo, y a 32 serían millones de voxels. Solo la cáscara visible (paredes de 2 voxels): el
frente, la cumbre y los costados. El frente mira hacia +Z; el origen es el centro de la
base del frente. Se colocan solapados (cada 7 m) para que no se vean las juntas.

- Frente: estratos horizontales en tres tonos de hielo, grietas verticales azul profundo que
  se hunden en la pared y un zócalo de cascotes de hielo al pie.
- Cumbre: capa de nieve con una cornisa que asoma por delante.

Escribe models/barrera_hielo_{1,2,3}.json.
Uso: python tools/gen_barrera_hielo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

W = 64            # medio ancho en voxels (8 m)
D = 64            # fondo (4 m)
ICE_A = (0.70, 0.81, 0.89)
ICE_B = (0.58, 0.72, 0.83)
ICE_C = (0.47, 0.63, 0.77)
CRACK = (0.19, 0.36, 0.54)
CRACK_DEEP = (0.12, 0.25, 0.42)
SNOW = (0.88, 0.91, 0.95)
SNOW_SH = (0.80, 0.84, 0.90)
RUBBLE = (0.66, 0.78, 0.87)
P = 'body'


def build(seed):
    M = Model(S=1, seed=seed)
    rnd = M.rng
    # perfil de la cumbre: 110..140 voxels con ondulación suave y escalones
    base_h = rnd.uniform(118, 130)
    ph = [rnd.uniform(0, 6.28) for _ in range(3)]
    def crest(x):
        h = base_h + 9 * math.sin(x * 0.045 + ph[0]) + 5 * math.sin(x * 0.11 + ph[1]) + 2 * math.sin(x * 0.31 + ph[2])
        return int(h)
    # estratos: bandas horizontales con su tono y su retranqueo
    bands = []
    y = 0
    while y < 150:
        h = rnd.randint(7, 16)
        bands.append((y, y + h, rnd.choice((ICE_A, ICE_B, ICE_B, ICE_C)), rnd.randint(0, 2)))
        y += h
    def band_at(y):
        for b in bands:
            if b[0] <= y < b[1]: return b
        return bands[-1]
    # grietas verticales: pocas, anchas y profundas
    cracks = [(rnd.randint(-W + 10, W - 10), rnd.randint(4, 7), rnd.randint(8, 14), rnd.randint(10, 70))
              for _ in range(rnd.randint(1, 3))]
    def crack_at(x, y):
        for cx, cw, cd, cy0 in cracks:
            wobble = int(2.5 * math.sin(y * 0.12 + cx))
            half = cw // 2 - (1 if y < cy0 + 6 else 0)          # se estrecha al cerrarse abajo
            if abs(x - cx - wobble) <= half and y >= cy0: return cd
        return 0
    ph2 = [rnd.uniform(0, 6.28) for _ in range(3)]
    def depth(x, y):
        """Retranqueo del frente: contrafuertes y entrantes grandes, estratos que sobresalen o
        se hunden y una ligera inclinación hacia atrás con la altura."""
        if y < 0: y = 0
        top = crest(x)
        lean = y // 14
        bulge = 7 * (0.5 + 0.5 * math.sin(x * 0.06 + ph2[0])) + 4 * (0.5 + 0.5 * math.sin(x * 0.17 + ph2[1]))
        # (sin variar con la altura: cada escalón de un voxel dibujaba una línea ondulada)
        return int(band_at(y)[3] * 2 + bulge + lean + crack_at(x, y))

    for x in range(-W, W):
        top = crest(x)
        for y in range(0, top):
            d = depth(x, y)
            cd = crack_at(x, y)
            col = band_at(y)[2]
            if cd: col = CRACK if (d - depth(x, y) + cd) < 10 else CRACK_DEEP
            # si el de encima está más hundido, este voxel tiene la cara de arriba al aire: nieve
            if y + 1 < top and depth(x, y + 1) > d + 1 and not cd: col = SNOW_SH
            # cáscara: desde el frente hasta el vecino más hundido (sin agujeros en los escalones)
            dm = max(d, depth(x - 1, y), depth(x + 1, y), depth(x, y - 1), depth(x, y + 1)) + 1
            for z in range(-dm, -d + 1):
                M.put(x, y, z, P, col if z == -d else (CRACK_DEEP if cd else band_at(y)[2]), over=False)
            M.put(x, y, -d, P, col)
        # cumbre: nieve de 3 voxels con cornisa que asoma por encima del frente
        over = 2 + (1 if math.sin(x * 0.2 + seed) > 0.3 else 0)
        z0 = -depth(x, top - 1) + over
        for z in range(-D, z0):
            yt = top + (1 if (z + x) % 7 == 0 else 0)
            for k in range(3):
                M.put(x, yt - k, z, P, SNOW if k == 0 else SNOW_SH)
    # costados (se ven en los extremos de las filas)
    for x in (-W, W - 1):
        for z in range(-D, 0):
            for y in range(0, crest(x)):
                M.put(x, y, z, P, band_at(y)[2], over=False)
    # zócalo de cascotes al pie
    for _ in range(18):
        cx = rnd.randint(-W + 4, W - 4)
        r = rnd.randint(6, 14)
        for x in range(cx - r, cx + r):
            for z in range(0, r + 2):
                hh = int((r - abs(x - cx)) * 0.9 - z * 0.6 + rnd.uniform(-1, 1))
                for y in range(0, max(0, hh)):
                    M.put(x, y, z, P, RUBBLE if y < hh - 1 else SNOW)

    def paint(k, part, c):
        x, y, z = k
        n = M.hsh(x, y, z)
        if c in (ICE_A, ICE_B, ICE_C, RUBBLE): return lerp(c, (1, 1, 1), 0.06 * n)     # poco ruido
        return None
    M.paint(paint)
    return M


def half_res(M):
    """Reduce a la mitad de resolución (8 voxels por metro): cuatro veces menos caras.
    Es fondo, y a 16 por metro la barrera bajaba el peor 1 % de fotogramas de 71 a 60 FPS."""
    H = Model(S=1, seed=M.rng.randint(0, 9999))
    for (x, y, z), v in M.V.items():
        k = (x // 2, y // 2, z // 2)
        if k not in H.V or v[1] in (SNOW, SNOW_SH): H.V[k] = [v[0], v[1], v[2]]
    H.S = 0.5                                      # voxel_size = 1 / (16 * S) = 1/8 m
    H.hsh = M.hsh
    return H


for i, seed in enumerate((101, 202, 303)):
    M = half_res(build(seed))
    n = M.export('models/barrera_hielo_%d.json' % (i + 1), {P: [0, 0, 0]}, jitter=0.004,
                 pivots_in_voxels=True, roughness=0.35, specular=0.5)
    print('barrera_hielo_%d' % (i + 1), n, 'voxels')
