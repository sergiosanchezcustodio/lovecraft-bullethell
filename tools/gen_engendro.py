"""Engendro de Cthulhu (fase 7, hito 7.3): la progenie estelar, una versión menor de su señor.
Unos 2,6 m: cuerpo escamoso verde oscuro e hinchado, piernas cortas y gruesas con garras,
brazos largos con manos de cuatro garras, cabeza de pulpo con una mata de tentáculos que le
cubre la cara, ojos pequeños que brillan en amarillo verdoso y alas de murciélago plegadas a la
espalda (membrana oscura). Sin ropa ni adornos.

32 voxels/m (S=2). Partes con los nombres de los Profundos (torso, head, arm_l, arm_r, leg_l,
leg_r) para animarlo con anim_profundo.gd. Uso: python tools/gen_engendro.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

T, HD, AL, AR, LL, LR = 'torso', 'head', 'arm_l', 'arm_r', 'leg_l', 'leg_r'
SKIN = (0.16, 0.26, 0.20); SKIN_L = (0.24, 0.36, 0.28); SKIN_D = (0.09, 0.15, 0.12)
BELLY = (0.34, 0.38, 0.28); MEMB = (0.10, 0.14, 0.12); MEMB_D = (0.06, 0.09, 0.08)
CLAW = (0.42, 0.40, 0.32); EYE = (0.80, 1.0, 0.35); SUCK = (0.50, 0.46, 0.40)

M = Model(S=2, seed=1926)
# piernas cortas y gruesas
for s, L in ((-1, LL), (1, LR)):
    M.capsule((s * 7 / 2, 30 / 2, 0), (s * 8 / 2, 14 / 2, 2 / 2), 5 / 2, 4 / 2, L, SKIN)
    M.capsule((s * 8 / 2, 14 / 2, 2 / 2), (s * 8 / 2, 3 / 2, 0), 4 / 2, 3.5 / 2, L, SKIN)
    M.sell(s * 8 / 2, 1.5 / 2, 4 / 2, 5 / 2, 2 / 2, 7 / 2, L, SKIN_D, p=2.4)
    for f in range(3): M.cone((s * (6 + f * 2) / 2, 1 / 2, 9 / 2), (s * (6 + f * 2) / 2, 0, 13 / 2), 1 / 2, L, CLAW, CLAW, tip_r=0.5)
# cuerpo hinchado y encorvado
M.ell(0, 44 / 2, 1 / 2, 14 / 2, 16 / 2, 11 / 2, T, SKIN)
M.ell(0, 56 / 2, -2 / 2, 16 / 2, 9 / 2, 11 / 2, T, SKIN, over=False)       # hombros
M.ell(0, 40 / 2, 7 / 2, 10 / 2, 11 / 2, 5 / 2, T, BELLY, over=False)       # vientre
# alas de murciélago plegadas a la espalda
for s in (-1, 1):
    for i in range(18):                                                    # alas plegadas que asoman por encima
        for j in range(40 - i * 2):
            c = MEMB if (j + i) % 6 else MEMB_D
            M.put(s * (6 + i), 84 - j - i // 3, -10 - i // 2, T, c, over=False)
    for j in range(44): M.put(s * 6, 88 - j, -10, T, SKIN_D)                # hueso del ala
    M.cone((s * 6 / 2, 88 / 2, -10 / 2), (s * 9 / 2, 100 / 2, -14 / 2), 1.4 / 2, T, SKIN_D, CLAW, tip_r=0.5)
# brazos largos con cuatro garras
for s, A in ((-1, AL), (1, AR)):
    M.capsule((s * 16 / 2, 58 / 2, 0), (s * 20 / 2, 40 / 2, 6 / 2), 4 / 2, 3.2 / 2, A, SKIN)
    M.capsule((s * 20 / 2, 40 / 2, 6 / 2), (s * 20 / 2, 24 / 2, 10 / 2), 3.2 / 2, 2.6 / 2, A, SKIN)
    M.ell(s * 20 / 2, 21 / 2, 11 / 2, 3.5 / 2, 3 / 2, 3.5 / 2, A, SKIN_D)
    for f in range(4):
        M.cone((s * (18 + f * 1.3) / 2, 19 / 2, 12 / 2), (s * (18 + f * 1.5) / 2, 12 / 2, 15 / 2), 1 / 2, A, CLAW, CLAW, tip_r=0.5)
# cabeza de pulpo con tentáculos en la cara
M.ell(0, 72 / 2, 5 / 2, 10 / 2, 9 / 2, 9 / 2, HD, SKIN)
M.ell(0, 84 / 2, -4 / 2, 11 / 2, 12 / 2, 12 / 2, HD, SKIN, over=False)    # manto del pulpo: grande, hacia atrás
M.ell(0, 92 / 2, -10 / 2, 8 / 2, 8 / 2, 9 / 2, HD, SKIN, over=False)
for s in (-1, 1):
    M.put(s * 4 - (1 if s > 0 else 0), 74, 12, HD, EYE, glow=1); M.put(s * 4 - (1 if s > 0 else 0) + s, 74, 12, HD, EYE, glow=1)
for i in range(9):                                                        # tentáculos: gruesos, separados, hasta la cintura
    x0 = -9 + i * 18 / 8
    n = 22 + (i % 3) * 5
    for k in range(n):
        x = x0 + math.sin(k * 0.35 + i * 1.3) * 2.2 + (x0 * 0.04) * k
        y = 68 - k
        z = 12 + k // 3
        r = 1.6 * (1 - k / n) + 0.6
        M.ell(x / 2, y / 2, z / 2, r / 2, 0.6, r / 2, HD, SKIN_D if k % 5 else SUCK)
# color: escamas, lomo oscuro y manchas
for (x, y, z), v in list(M.V.items()):
    if v[1] != SKIN: continue
    c = lerp(SKIN, SKIN_D, 0.5 * M.noise(x, y, z, 8.0) + (0.3 if z < -4 else 0.0))
    if (x + 2 * y + z) % 5 == 0: c = SKIN_L
    M.V[(x, y, z)] = [v[0], c, v[2]]

piv = {T: [0, 30, 0], HD: [0, 64, 4], AL: [-16, 58, 0], AR: [16, 58, 0], LL: [-7, 30, 0], LR: [7, 30, 0]}
n = M.export('models/engendro.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.45, specular=0.5,
             parents={HD: T, AL: T, AR: T})
print('engendro', n, 'voxels')
