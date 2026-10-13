"""Primigenio menor (fase 7, hito 7.5; rehecho en la revisión de arte del 13-10-2026):
un cachorro de Cthulhu. Cabeza de pulpo grande y redonda, ojos enormes de un amarillo
que brilla con pupila y reflejo, una barba de tentáculos cortos y rechonchos más oscuros
que se enroscan en la punta, cuerpo pequeño y barrigón, bracitos con tres garras, patas
cortas y alas de murciélago pequeñas en violeta. Verde azulado más claro que el engendro.

32 voxels/m (S=2); medidas en voxels (V() pasa a ub). Partes de los Profundos para animarlo
con anim_profundo.gd. Uso: python tools/gen_primigenio_menor.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

T, HD, AL, AR, LL, LR = 'torso', 'head', 'arm_l', 'arm_r', 'leg_l', 'leg_r'
SKIN = (0.20, 0.44, 0.38); SKIN_L = (0.30, 0.56, 0.46); SKIN_D = (0.13, 0.30, 0.27)
SPOT = (0.36, 0.62, 0.52)
BELLY = (0.60, 0.68, 0.46); BELLY_D = (0.50, 0.58, 0.40)
TENT = (0.05, 0.14, 0.14); TENT_D = (0.07, 0.19, 0.17); SUCK = (0.36, 0.46, 0.36); TENT2 = (0.07, 0.18, 0.17)
WING = (0.36, 0.20, 0.54); WING_D = (0.26, 0.13, 0.40); BONE = (0.17, 0.09, 0.24)
CLAW = (0.62, 0.62, 0.52)
EYE = (0.80, 0.62, 0.04); EYE_RIM = (0.10, 0.08, 0.04); PUPIL = (0.03, 0.03, 0.03); SHINE = (0.95, 0.95, 0.85)

M = Model(S=2, seed=1928)
def V(*a): return [q / 2 for q in a]
def ell(c, r, part, col, over=True, glow=0): M.ell(*V(*c), *V(*r), part, col, over=over, glow=glow)
def cap(a, b, r0, r1, part, col, over=True): M.capsule(V(*a), V(*b), r0 / 2, r1 / 2, part, col, over)

# ---------------- PATAS cortas y rechonchas ----------------
for s, L in ((-1, LL), (1, LR)):
    cap((s * 7, 13, 0), (s * 8, 4, 1), 5, 4.5, L, SKIN)
    ell((s * 8, 2, 3), (5, 2.5, 6.5), L, SKIN_D)
    for f in (-1, 0, 1):
        for j in range(2): M.put(s * 8 + f * 3, 1, 9 + j, L, CLAW); M.put(s * 8 + f * 3, 0, 9 + j, L, CLAW)

# ---------------- CUERPO pequeño y barrigón ----------------
ell((0, 22, 0), (12, 12, 10), T, SKIN)
ell((0, 20, 6), (8.5, 9, 5), T, BELLY, over=False)
for (x, y, z), v in list(M.V.items()):                        # pliegues de la barriga
    if v[1] == BELLY and y % 4 == 0: v[1] = BELLY_D

# ---------------- ALAS de murciélago pequeñas, violeta ----------------
# Triángulo raíz-punta alta-punta baja en el plano de la espalda; borde de abajo festoneado
for s in (-1, 1):
    R = (6, 30); TOPW = (23, 52); LOW = (24, 30)
    def inside(u, y):
        (x1, y1), (x2, y2), (x3, y3) = R, TOPW, LOW
        d = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
        l1 = ((y2 - y3) * (u - x3) + (x3 - x2) * (y - y3)) / d
        l2 = ((y3 - y1) * (u - x3) + (x1 - x3) * (y - y3)) / d
        return l1 >= 0 and l2 >= 0 and 1 - l1 - l2 >= 0
    for u in range(6, 25):
        for y in range(28, 53):
            if not inside(u + 0.5, y + 0.5): continue
            edge = 30 + 0.8 * (u - 6) * 0 + 3.2 * abs(math.sin((u - 6) * math.pi / 6))   # festón entre dedos
            if y < edge and u > 8: continue
            z = -8 - (u - 6) * 0.35
            c = WING
            M.put(s * u, y, z, T, c, over=False); M.put(s * u, y, z - 1, T, WING_D, over=False)
    for (fx, fy) in ((23, 52), (24, 42), (18, 31), (24, 30)):            # dedos del ala, por delante de la membrana
        M.line(V(s * 6, 30, -7), V(s * fx, fy, -7 - (fx - 6) * 0.35), T, BONE, thick=1)
    M.cone(V(s * 23, 52, -14), V(s * 24, 55, -15), 0.6, T, BONE, CLAW, tip_r=0.5)

# ---------------- BRACITOS con tres garras ----------------
for s, A in ((-1, AL), (1, AR)):
    cap((s * 11, 28, 1), (s * 16, 19, 5), 3.6, 3, A, SKIN)
    ell((s * 16, 17, 6), (3.2, 3, 3.2), A, SKIN_D)
    for f in (-1, 0, 1):                                       # garritas de un voxel
        for j in range(3): M.put(s * 16 + f * 2, 15 - j, 8 + j, A, CLAW)

# ---------------- CABEZA grande y redonda ----------------
ell((0, 42, 3), (13, 10, 11), HD, SKIN)                       # cara
ell((0, 53, -3), (14.5, 13, 13), HD, SKIN, over=False)        # manto del pulpo
ell((0, 60, -10), (9, 7, 8), HD, SKIN, over=False)            # punta del manto, hacia atrás
# manchas claras en el manto
for (x, y, z), v in list(M.V.items()):
    if v[0] != HD or v[1] != SKIN: continue
    if y > 48 and M.noise(x, y, z, 5.0) > 0.68: v[1] = SPOT

# ojos enormes: borde oscuro, iris amarillo que brilla, pupila y reflejo
EYE_Y = 45
for s in (-1, 1):
    cx = s * 5.5
    for dx in range(-4, 5):
        for dy in range(-4, 5):
            d = math.hypot(dx, dy)
            if d > 4.3: continue
            x = int(math.floor(cx + dx)); y = EYE_Y + dy
            z = M.front(x, y, 30, 0)
            if z is None: continue
            if d > 3.4: col, gl = EYE_RIM, 0
            elif math.hypot(dx - s * 0.5, dy + 0.5) < 1.25: col, gl = PUPIL, 0
            else: col, gl = EYE, 1
            M.V[(x, y, z)] = [HD, col, gl]
            M.put(x, y, z + 1, HD, col, gl)                   # asoman un voxel: se ven saltones
    # reflejo arriba hacia fuera
    for (dx, dy) in ((s * 1, 2), (s * 2, 2), (s * 1, 3)):
        x = int(math.floor(cx - s * 0.5 + dx)); y = EYE_Y + dy - 1
        z = M.front(x, y, 30, 0)
        if z is not None: M.V[(x, y, z)] = [HD, SHINE, 1]

# barba de tentáculos cortos y rechonchos, más oscuros, que se enroscan en la punta
TENTS = [(-8.5, 1.0), (-4.2, 1.25), (0, 1.1), (4.2, 1.2), (8.5, 1.05)]
for i, (x0, ln) in enumerate(TENTS):
    n = int(12 * ln)
    front = i == 2                                            # los dos de delante, más cortos y adelantados
    side = 1 if x0 > 0 else (-1 if x0 < 0 else 0)
    for k in range(n):
        t = k / n
        curl = max(0.0, t - 0.55) / 0.45                      # la punta se enrosca hacia fuera y arriba
        x = x0 + side * (curl ** 1.5) * 4 + math.sin(k * 0.5 + i) * 0.6
        y = 37 - k + (curl ** 2) * 6
        z = 12 + (2 if front else 0) + k * 0.35
        r = 1.5 * (1 - t) + 0.7
        c = TENT if i % 2 else TENT2
        ell((x, y, z), (r, r, r), HD, c)
        if k % 4 == 2 and t < 0.7: M.put(x, y - 0.5, z + r, HD, SUCK)          # ventosas por delante

# ---------------- COLOR de la piel: escamas suaves, lomo más oscuro ----------------
for (x, y, z), v in list(M.V.items()):
    if v[1] != SKIN: continue
    c = lerp(SKIN, SKIN_D, 0.35 * M.noise(x, y, z, 9.0) + (0.25 if z < -5 else 0.0))
    if (x + 2 * y + z) % 13 == 0: c = SKIN_L
    v[1] = c

piv = {T: [0, 13, 0], HD: [0, 33, 2], AL: [-11, 28, 1], AR: [11, 28, 1], LL: [-7, 13, 0], LR: [7, 13, 0]}
n = M.export('models/primigenio_menor.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.5, specular=0.45,
             parents={HD: T, AL: T, AR: T})
print('primigenio_menor', n, 'voxels')
