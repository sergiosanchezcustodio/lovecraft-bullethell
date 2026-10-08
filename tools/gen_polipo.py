"""La cosa blanca polipoide del lago oculto (fase 7, hito 7.4). Masa blanca y viscosa de
pólipos apiñados, de 1,4 m, sin forma fija: bulbos translúcidos de un blanco azulado con
venas rosadas, bocas redondas de pólipo con un anillo de tentáculos cortos y una corona de
tentáculos largos que se agitan. Brilla apenas (bioluminiscencia pálida en las bocas).

32 voxels/m (S=2). Partes: body, top, pod_l, pod_r (como el fragmento protoplásmico, para
animarlo con anim_fragmento.gd). Variante `polipo_madre` (evento final, a 2,4 en el juego).
Uso: python tools/gen_polipo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

B, TOP, PL, PR = 'body', 'top', 'pod_l', 'pod_r'
WHITE = (0.86, 0.88, 0.90); WHITE_D = (0.66, 0.70, 0.76); BLUE = (0.72, 0.80, 0.88)
VEIN = (0.80, 0.52, 0.56); MOUTH = (0.30, 0.08, 0.12); GLOW = (0.80, 0.95, 1.0)


def build(name, seed, n_bulbs, size):
    M = Model(S=2, seed=seed)
    rng = M.rng
    bulbs = []
    for i in range(n_bulbs):                                  # bulbos apiñados
        a = rng.uniform(0, math.tau); d = rng.uniform(0, 8) * size
        y = rng.uniform(4, 18) * size
        r = rng.uniform(4, 7) * size
        part = TOP if y > 12 * size else B
        M.ell(math.cos(a) * d / 2, y / 2, math.sin(a) * d / 2, r / 2, r * 0.9 / 2, r / 2, part, WHITE)
        bulbs.append((math.cos(a) * d, y, math.sin(a) * d, r, part))
    for (bx, by, bz, r, part) in bulbs:                        # bocas de pólipo hacia fuera
        n = math.hypot(bx, bz) or 1.0
        ox, oz = bx / n, bz / n
        if by > 12 * size: ox, oz = ox * 0.4, oz * 0.4
        mx, my, mz = bx + ox * r, by + (r * 0.6 if by > 12 * size else 0), bz + oz * r
        for dx in range(-1, 2):
            for dz in range(-1, 2):
                M.put(int(mx + dx), int(my), int(mz + dz), part, MOUTH)
        M.put(int(mx), int(my) + 1, int(mz), part, GLOW, glow=1)
        for k in range(8):                                     # anillo de tentáculos cortos
            a = k / 8 * math.tau
            for j in range(3):
                M.put(int(mx + math.cos(a) * (2 + j)), int(my + j), int(mz + math.sin(a) * (2 + j)), part, WHITE_D)
    for s, P in ((-1, PL), (1, PR)):                           # tentáculos largos (los "pseudópodos")
        for t in range(3):
            base = (s * (6 + t * 2) * size, 8 * size, (t - 1) * 5 * size)
            for k in range(int(22 * size)):
                x = base[0] + s * k * 0.7
                y = base[1] + math.sin(k * 0.3 + t) * 3
                z = base[2] + math.cos(k * 0.25 + t) * 2
                r = max(0.7, (2.2 - k * 0.07) * size)
                M.ell(x / 2, y / 2, z / 2, r / 2, r / 2, r / 2, P, WHITE if k % 9 else VEIN)
    for i in range(int(14 * size)):                            # corona de tentáculos arriba
        a = i / (14 * size) * math.tau
        for k in range(int(12 * size)):
            M.put(int(math.cos(a) * (3 + k * 0.5)), int(22 * size + k * 0.7), int(math.sin(a) * (3 + k * 0.5)), TOP, WHITE_D if k % 6 else VEIN)
    for (x, y, z), v in list(M.V.items()):                     # translúcido: azulado y con venas
        if v[1] != WHITE: continue
        c = lerp(WHITE, BLUE, M.noise(x, y, z, 6.0) * 0.7)
        if M.noise(x, y, z, 2.5) > 0.88: c = VEIN
        M.V[(x, y, z)] = [v[0], c, v[2]]
    piv = {B: [0, 0, 0], TOP: [0, int(12 * size), 0], PL: [int(-6 * size), int(8 * size), 0], PR: [int(6 * size), int(8 * size), 0]}
    n = M.export('models/%s.json' % name, piv, jitter=0.012, pivots_in_voxels=True, roughness=0.3, specular=0.6,
                 parents={TOP: B, PL: B, PR: B})
    print(name, n, 'voxels')


build('polipo', 1925, 9, 1.0)
build('polipo_madre', 1926, 16, 1.25)
