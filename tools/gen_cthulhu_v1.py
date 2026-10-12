"""Cthulhu (fase 7, hito 7.6), jefe de la parte 3. Colosal: asoma de cintura para arriba por
delante de la puerta de R'lyeh. 16 voxels/m (S=1) y unos 8 m; en el juego, a escala 1,3.

Como en el relato: cabeza de pulpo con una mata de tentáculos donde debería estar la cara,
cuerpo escamoso y correoso, garras prodigiosas y alas estrechas de murciélago a la espalda.
Verde oscuro, gelatinoso; ojos pequeños que brillan. Hueco: solo la cáscara.
Partes como Dagon (torso, head, arm_l, arm_r) para animarlo con anim_dagon.gd.
Uso: python tools/gen_cthulhu.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

T, H, AL, AR = 'torso', 'head', 'arm_l', 'arm_r'
SKIN = (0.16, 0.27, 0.20); SKIN_L = (0.24, 0.38, 0.28); SKIN_D = (0.08, 0.14, 0.11)
BELLY = (0.30, 0.36, 0.26); MEMB = (0.10, 0.15, 0.12); MEMB_D = (0.06, 0.09, 0.08)
CLAW = (0.40, 0.38, 0.30); EYE = (0.75, 1.0, 0.40); SUCK = (0.46, 0.44, 0.36)

M = Model(S=1, seed=1926)
M.sell(0, 14, 0, 30, 26, 22, T, SKIN, p=2.3)                     # vientre (se hunde en el suelo)
M.sell(0, 46, 2, 38, 22, 24, T, SKIN, p=2.3)                     # pecho y hombros
M.sell(0, 40, 18, 22, 18, 8, T, BELLY, p=2.3, over=False)        # vientre pálido
# alas estrechas de murciélago, abiertas hacia arriba y atrás
for s in (-1, 1):
    root = (s * 20, 60, -16)
    tips = [(s * 96, 132, -40), (s * 104, 92, -44), (s * 80, 58, -36)]
    for tip in tips:
        n = 90
        for k in range(n + 1):
            t = k / n
            p = [root[i] + (tip[i] - root[i]) * t for i in range(3)]
            for dx in (0, 1):
                for dy in (0, 1): M.put(p[0] + dx, p[1] + dy, p[2], T, SKIN_D)
    for a, b in ((tips[0], tips[1]), (tips[1], tips[2])):
        for i in range(81):
            for j in range(81 - i):
                u, v = i / 80, j / 80
                q = [root[k] + (a[k] - root[k]) * u + (b[k] - root[k]) * v for k in range(3)]
                if (u + v) > 0.9 and int((u - v) * 16) % 2 == 0: continue     # borde festoneado
                M.put(q[0], q[1], q[2], T, MEMB if (i + j) % 9 else MEMB_D, over=False)
# brazos enormes apoyados delante, con garras prodigiosas
for s, A in ((-1, AL), (1, AR)):
    sh, el, wr = (40 * s, 50, 4), (52 * s, 26, 24), (44 * s, 8, 48)
    M.capsule(sh, el, 12, 10, A, SKIN)
    M.capsule(el, wr, 10, 8, A, SKIN)
    M.sell(wr[0], 5, 56, 13, 6, 13, A, SKIN_D, p=2.5)
    for f in range(-2, 3):
        a = math.radians(f * 20)
        base = (wr[0] + 11 * math.sin(a), 5, 56 + 11 * math.cos(a))
        tip = (wr[0] + 26 * math.sin(a), 1, 56 + 26 * math.cos(a))
        M.cone(base, tip, 3.5, A, CLAW, SKIN_D, tip_r=0.8)
# cabeza de pulpo: manto grande hacia atrás, ojos pequeños, mata de tentáculos
HY, HZ = 74, 22
M.sell(0, HY, HZ, 24, 18, 22, H, SKIN, p=2.4)
M.sell(0, HY + 18, HZ - 14, 26, 22, 26, H, SKIN, p=2.4, over=False)
M.sell(0, HY + 34, HZ - 30, 18, 14, 20, H, SKIN, p=2.4, over=False)
for s in (-1, 1): M.ell(s * 11, HY + 6, HZ + 20, 3, 2.5, 2, H, EYE, glow=1)
for i in range(13):
    x0 = -22 + i * 44 / 12
    n = 46 + (i % 4) * 8
    for k in range(n):
        x = x0 + math.sin(k * 0.25 + i * 1.3) * 3.5 + x0 * 0.012 * k
        y = HY - 6 - k
        z = HZ + 20 + k * 0.32
        r = 4.0 * (1 - k / n) + 1.2
        M.ell(x, y, z, r, 1.2, r, H, SKIN_D if k % 7 else SUCK)
# piel: escamas, lomo oscuro
for (x, y, z), v in list(M.V.items()):
    if v[1] != SKIN: continue
    c = lerp(SKIN, SKIN_D, 0.45 * M.noise(x, y, z, 12.0) + (0.25 if z < -8 else 0))
    if (x + 2 * y + z) % 6 == 0: c = SKIN_L
    M.V[(x, y, z)] = [v[0], c, v[2]]
dirs = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
inside = [k for k in M.V if all((k[0] + a * d, k[1] + b * d, k[2] + c * d) in M.V for a, b, c in dirs for d in (1, 2))]
for k in inside: del M.V[k]
for k in [k for k in M.V if k[1] < -16]: del M.V[k]
piv = {T: [0, -4, 0], H: [0, 62, 14], AL: [-40, 50, 4], AR: [40, 50, 4]}
n = M.export('models/cthulhu.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.4, specular=0.5,
             parents={H: T, AL: T, AR: T})
print('cthulhu: %d voxels' % n)
