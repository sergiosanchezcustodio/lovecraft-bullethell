"""Diablo con alas de murciélago de la leyenda del pantano de Luisiana (fase 7, hito 7.2).
Criatura menuda (1,2 m), encorvada, de piel correosa gris verdosa casi negra, con cuernos
cortos, orejas de murciélago, ojos amarillos que brillan, boca de colmillos, cola larga con
punta de flecha y unas alas de murciélago enormes (2,6 m de envergadura) con dedos huesudos.

32 voxels/m (S=2). Partes: body, head, wing_l, wing_r, tail. Vuela con DiveBehavior (como el
Antiguo alado). Animaciones: scripts/anim/anim_diablo.gd (fly, dive, idle, walk).
Uso: python tools/gen_diablo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

B, HD, WL, WR, TL = 'body', 'head', 'wing_l', 'wing_r', 'tail'
SKIN = (0.20, 0.22, 0.19); SKIN_L = (0.30, 0.32, 0.27); SKIN_D = (0.11, 0.12, 0.11)
MEMB = (0.30, 0.16, 0.16); MEMB_D = (0.20, 0.10, 0.10)            # membrana rojiza oscura
BONE = (0.62, 0.58, 0.48); EYE = (1.0, 0.85, 0.25); MOUTH = (0.25, 0.05, 0.05); FANG = (0.90, 0.88, 0.78)

M = Model(S=2, seed=1907)
# cuerpo encorvado, piernas cortas dobladas y brazos que cuelgan
M.ell(0, 24 / 2, 0, 6 / 2, 9 / 2, 5 / 2, B, SKIN)
M.ell(0, 30 / 2, -1 / 2, 7 / 2, 5 / 2, 5 / 2, B, SKIN, over=False)      # hombros
for s in (-1, 1):
    M.capsule((s * 3 / 2, 16 / 2, 0), (s * 4 / 2, 8 / 2, 3 / 2), 2.2 / 2, 1.8 / 2, B, SKIN)       # muslo
    M.capsule((s * 4 / 2, 8 / 2, 3 / 2), (s * 4 / 2, 1 / 2, 0), 1.6 / 2, 1.2 / 2, B, SKIN)        # pierna
    for f in range(3): M.put(s * 4 + f - 1, 0, 3, B, BONE)                                       # garras
    M.capsule((s * 6 / 2, 30 / 2, 1 / 2), (s * 7 / 2, 18 / 2, 5 / 2), 1.4 / 2, 1.1 / 2, B, SKIN)  # brazo
    for f in range(3): M.put(s * 7 + f - 1, 16, 6, B, BONE)
# cabeza: hocico corto, cuernos, orejas de murciélago, ojos y colmillos
M.ell(0, 38 / 2, 2 / 2, 4 / 2, 4 / 2, 4.5 / 2, HD, SKIN)
for s in (-1, 1):
    M.cone((s * 3 / 2, 41 / 2, 1 / 2), (s * 5 / 2, 46 / 2, -2 / 2), 1.2 / 2, HD, SKIN_D, BONE, tip_r=0.5)   # cuernos
    for k in range(6):                                                                             # orejas
        for j in range(4 - k // 2): M.put(s * (4 + j), 40 + k, 0, HD, SKIN_D if j == 0 else MEMB)
    M.put(s * 2 - (1 if s > 0 else 0), 39, 6, HD, EYE, glow=1); M.put(s * 2 - (1 if s > 0 else 0) + s, 39, 6, HD, EYE, glow=1)
for x in range(-2, 2):
    M.put(x, 35, 6, HD, MOUTH)
for x in (-2, 1): M.put(x, 34, 6, HD, FANG)
# cola larga con punta de flecha
for k in range(26):
    t = k / 25
    x = math.sin(t * 4.0) * 3
    M.ell((x) / 2, (18 - k * 0.5) / 2, (-4 - k) / 2, 0.9 / 2, 0.9 / 2, 0.9 / 2, TL, SKIN_D)
for j in range(-3, 4):
    for i in range(0, 4 - abs(j)): M.put(int(math.sin(4.0) * 3) + j, 5, -31 - i, TL, SKIN_D)
# alas: tres dedos huesudos desde el hombro y la membrana entre ellos
for s, W in ((-1, WL), (1, WR)):
    root = (s * 6, 32, -3)
    tips = [(s * 40, 44, -8), (s * 36, 26, -10), (s * 24, 14, -8)]
    for tip in tips:
        n = 30
        for k in range(n + 1):
            t = k / n
            M.put(root[0] + (tip[0] - root[0]) * t, root[1] + (tip[1] - root[1]) * t, root[2] + (tip[2] - root[2]) * t, W, BONE if k % 6 else SKIN_D)
    # membrana: triángulos entre el hombro, un dedo y el siguiente (con borde festoneado)
    for a, b in ((tips[0], tips[1]), (tips[1], tips[2])):
        for i in range(31):
            for j in range(31 - i):
                u, v = i / 30, j / 30
                x = root[0] + (a[0] - root[0]) * u + (b[0] - root[0]) * v
                y = root[1] + (a[1] - root[1]) * u + (b[1] - root[1]) * v
                z = root[2] + (a[2] - root[2]) * u + (b[2] - root[2]) * v
                edge = (u + v) > 0.86 and int((u - v) * 12) % 2 == 0      # festón del borde
                if edge: continue
                M.put(x, y, z, W, MEMB if (i + j) % 7 else MEMB_D, over=False)
# tono: más claro el lomo, más oscuro el vientre
for (x, y, z), v in list(M.V.items()):
    if v[1] == SKIN:
        c = lerp(SKIN_D, SKIN_L, 0.4 + 0.4 * M.noise(x, y, z, 4.0))
        M.V[(x, y, z)] = [v[0], c, v[2]]
piv = {B: [0, 0, 0], HD: [0, 34, 1], WL: [-6, 32, -3], WR: [6, 32, -3], TL: [0, 18, -4]}
n = M.export('models/diablo.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.6, specular=0.35,
             parents={HD: B, WL: B, WR: B, TL: B})
print('diablo', n, 'voxels')
