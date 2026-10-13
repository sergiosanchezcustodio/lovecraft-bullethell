"""Cthulhu (fase 7, hito 7.6), jefe de la parte 3. Colosal: asoma de cintura para arriba por
delante de la puerta de R'lyeh. 16 voxels/m (S=1) y unos 8 m; en el juego, a escala 1,15.

Rediseño (12-10-2026, revisión de arte; la versión anterior queda en gen_cthulhu_v1.py):
- manto de pulpo grande y bulboso con pliegues en anillo, cresta ósea sobre los ojos y manchas
  bioluminiscentes verdes (a juego con las emanaciones de R'lyeh);
- ojos ámbar que brillan en cuencas hundidas;
- barba de 16 tentáculos gruesos que se abren y enroscan en la punta, ventosas pálidas debajo;
- cuerpo musculoso (pectorales), espinas en el lomo y placas en los hombros;
- brazos con espinas en el antebrazo y garras largas;
- alas grandes de murciélago: cuatro dedos huesudos, membrana con venas y desgarrones.
Hueco: solo la cáscara. Partes como Dagon (torso, head, arm_l, arm_r) para anim_dagon.gd.
Uso: python tools/gen_cthulhu.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

T, H, AL, AR = 'torso', 'head', 'arm_l', 'arm_r'
SKIN = (0.13, 0.25, 0.20); SKIN_L = (0.22, 0.38, 0.29); SKIN_D = (0.06, 0.12, 0.10)
BELLY = (0.30, 0.37, 0.27); PLATE = (0.10, 0.17, 0.15)
MEMB = (0.09, 0.15, 0.13); MEMB_V = (0.17, 0.10, 0.10); BONE = (0.05, 0.09, 0.08)
CLAW = (0.42, 0.40, 0.30); SPIKE = (0.36, 0.38, 0.28); SUCK = (0.52, 0.50, 0.40)
EYE = (1.0, 0.72, 0.18); SOCKET = (0.02, 0.03, 0.03); GLOW = (0.35, 1.0, 0.55)

M = Model(S=1, seed=1926)

# ---------------- cuerpo ----------------
M.sell(0, 14, 0, 30, 26, 22, T, SKIN, p=2.3)                      # vientre (se hunde en el suelo)
M.sell(0, 46, 2, 40, 22, 24, T, SKIN, p=2.3)                      # pecho y hombros
for s in (-1, 1):                                                 # pectorales
    M.sell(s * 15, 46, 20, 15, 11, 7, T, SKIN, p=2.2, over=False)
M.sell(0, 30, 19, 18, 14, 6, T, BELLY, p=2.2, over=False)         # vientre pálido
for s in (-1, 1):                                                 # placas en los hombros
    for k in range(4):
        M.sell(s * (30 + k * 3), 60 - k * 4, 2 - k, 9 - k, 4, 12 - k, T, PLATE, p=3, over=False)
for i in range(9):                                                # espinas por el lomo
    y = 66 - i * 6
    h = 10 - abs(i - 3)
    M.cone((0, y, -20), (0, y + 3, -20 - h), 3.0, T, SPIKE, PLATE, tip_r=0.6)

# ---------------- alas ----------------
for s in (-1, 1):
    root = (s * 22, 62, -18)
    knuckle = (s * 58, 112, -34)                                  # muñeca del ala
    M.capsule(root, knuckle, 4.5, 3.0, T, BONE)
    tips = [(s * 118, 150, -48), (s * 130, 108, -52), (s * 118, 70, -46), (s * 86, 46, -38)]
    for tip in tips: M.capsule(knuckle, tip, 2.4, 1.0, T, BONE)
    chain = [root] + [knuckle] + tips
    fans = [(knuckle, tips[i], tips[i + 1]) for i in range(3)] + [(root, knuckle, tips[3])]
    for a0, a, b in fans:
        n = 90
        for i in range(n + 1):
            for j in range(n + 1 - i):
                u, v = i / n, j / n
                q = [a0[k] + (a[k] - a0[k]) * u + (b[k] - a0[k]) * v for k in range(3)]
                edge = u + v
                if edge > 0.93 and int((u - v) * 18) % 2 == 0: continue          # borde festoneado
                if M.noise(q[0], q[1], q[2], 9.0) > 0.78 and 0.3 < edge < 0.85: continue   # desgarrones
                vein = abs(u - v) < 0.02 or (i % 15 == 0 and edge < 0.9)
                M.put(q[0], q[1], q[2], T, MEMB_V if vein else MEMB, over=False)

# ---------------- brazos ----------------
for s, A in ((-1, AL), (1, AR)):
    sh, el, wr = (42 * s, 50, 4), (54 * s, 26, 24), (46 * s, 8, 48)
    M.capsule(sh, el, 13, 10, A, SKIN)
    M.capsule(el, wr, 10.5, 8, A, SKIN)
    for k in range(4):                                            # espinas del antebrazo, hacia fuera
        t = 0.2 + k * 0.2
        b = [el[i] + (wr[i] - el[i]) * t for i in range(3)]
        M.cone((b[0] + s * 8, b[1] + 2, b[2]), (b[0] + s * 18, b[1] + 6, b[2] - 4), 2.6, A, SPIKE, PLATE, tip_r=0.5)
    M.sell(wr[0], 5, 56, 14, 6, 14, A, SKIN_D, p=2.5)
    for f in range(-2, 3):
        a = math.radians(f * 21)
        base = (wr[0] + 12 * math.sin(a), 5, 56 + 12 * math.cos(a))
        tip = (wr[0] + 32 * math.sin(a), 0, 56 + 32 * math.cos(a))
        M.cone(base, tip, 3.8, A, CLAW, SKIN_D, tip_r=0.7)

# ---------------- cabeza ----------------
HY, HZ = 74, 22
TENT = (0.24, 0.40, 0.31); TENT_D = (0.10, 0.20, 0.16)            # barba más clara que el pecho
M.sell(0, HY + 2, HZ + 4, 24, 16, 20, H, SKIN, p=2.3)             # cara
# manto: un solo bulbo continuo que sube y cae hacia atrás (muchas secciones que se funden)
for k in range(15):
    t = k / 14.0
    cy = HY + 14 + 40 * math.sin(t * 1.4)
    cz = HZ - 6 - 46 * t
    r = 30 - 6 * t if t < 0.55 else 30 - 6 * 0.55 - 34 * (t - 0.55)
    M.ell(0, cy, cz, r, r * 0.92, r, H, SKIN, over=False)
M.sell(0, HY + 15, HZ + 17, 22, 3.5, 6, H, PLATE, p=3, over=False)    # cresta ósea sobre los ojos
for s in (-1, 1):                                                 # cuencas hundidas y ojos ámbar
    M.ell(s * 10, HY + 9, HZ + 21, 5, 4, 3, H, SOCKET)
    M.ell(s * 10, HY + 9, HZ + 23, 3, 2.5, 2, H, EYE, glow=1)
# venas en relieve del manto (más oscuras) y manchas que brillan
for (x, y, z), v in list(M.V.items()):
    if v[0] != H or v[1] != SKIN or y < HY + 12: continue
    if abs(math.sin(x * 0.35 + z * 0.08)) < 0.09: M.V[(x, y, z)] = [H, SKIN_D, 0]
    elif M.noise(x, y, z, 5.0) > 0.87: M.V[(x, y, z)] = [H, GLOW, 1]
# barba: 16 tentáculos gruesos, por delante del pecho, que se abren y enroscan en la punta
for i in range(16):
    u = i / 15.0
    x0 = -22 + u * 44
    n = 56 + (i * 7) % 18
    curl = 1 if i % 2 else -1
    for k in range(n):
        t = k / n
        x = x0 + (x0 / 22.0) * t * 16 + math.sin(k * 0.22 + i * 1.7) * 2.5
        y = HY + 2 - k * 0.9
        z = HZ + 22 + k * 0.62 + (4 if i % 3 == 0 else 0)       # hacia delante, sobre el pecho
        if t > 0.72:
            a = (t - 0.72) / 0.28 * math.pi * 1.4
            x += curl * 7 * math.sin(a)
            y += 7 * (1 - math.cos(a))
        r = 5.2 * (1 - t) + 1.4
        M.ell(x, y, z, r, 1.4, r, H, TENT_D if t > 0.7 else TENT)
        if k % 4 == 0 and t < 0.85: M.ell(x, y - 0.5, z + r * 0.85, max(r * 0.35, 0.9), 0.9, 0.9, H, SUCK)   # ventosas
        if k % 9 == 0 and t < 0.65: M.put(x, y, z - r, H, GLOW, glow=1)

# ---------------- piel ----------------
for (x, y, z), v in list(M.V.items()):
    if v[1] != SKIN: continue
    c = lerp(SKIN, SKIN_D, 0.45 * M.noise(x, y, z, 12.0) + (0.25 if z < -8 else 0))
    if (x + 2 * y + z) % 6 == 0: c = SKIN_L                       # escamas
    M.V[(x, y, z)] = [v[0], c, v[2]]
for (x, y, z), v in list(M.V.items()):                            # alguna mancha luminosa en el cuerpo
    if v[0] == T and v[2] == 0 and v[1] not in (MEMB, MEMB_V, BONE) and M.noise(x, y, z, 4.0) > 0.93:
        M.V[(x, y, z)] = [T, GLOW, 1]
dirs = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
inside = [k for k in M.V if all((k[0] + a * d, k[1] + b * d, k[2] + c * d) in M.V for a, b, c in dirs for d in (1, 2))]
for k in inside: del M.V[k]
for k in [k for k in M.V if k[1] < -16]: del M.V[k]
piv = {T: [0, -4, 0], H: [0, 62, 14], AL: [-42, 50, 4], AR: [42, 50, 4]}
n = M.export('models/cthulhu.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.4, specular=0.5,
             parents={H: T, AL: T, AR: T})
print('cthulhu: %d voxels' % n)
