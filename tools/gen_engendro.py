"""Engendro de Cthulhu (fase 7, hito 7.3; rehecho en la revisión de arte del 13-10-2026 con el
estilo del primigenio menor, pero crecido). La progenie estelar ya adulta, unos 3 m: la misma
piel verde azulada con manchas claras en el manto, vientre crema, tentáculos casi negros y
alas violetas, pero con proporciones de adulto: cabeza de pulpo más pequeña respecto al
cuerpo, ojos amarillos rasgados con pupila de rendija (nada de reflejos tiernos), una barba de
siete tentáculos largos que llegan al vientre y se enroscan, tronco ancho con pectorales y
placas en el vientre, brazos largos con cuatro garras, piernas fuertes con garras, púas en el
lomo y alas de murciélago grandes con dedos, membrana festoneada y venas.

32 voxels/m (S=2); medidas en voxels. Partes de los Profundos (anim_profundo.gd).
Lo usan engendro (1,2×) y engendro_mayor (1,7×). Uso: python tools/gen_engendro.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

T, HD, AL, AR, LL, LR = 'torso', 'head', 'arm_l', 'arm_r', 'leg_l', 'leg_r'
SKIN = (0.18, 0.40, 0.34); SKIN_L = (0.27, 0.51, 0.42); SKIN_D = (0.11, 0.26, 0.23)
SPOT = (0.32, 0.56, 0.47)
BELLY = (0.56, 0.62, 0.42); BELLY_D = (0.44, 0.50, 0.34)
TENT = (0.07, 0.19, 0.18); TENT2 = (0.11, 0.25, 0.23); SUCK = (0.36, 0.46, 0.36)
WING = (0.34, 0.18, 0.50); WING_L = (0.42, 0.24, 0.58); WING_D = (0.22, 0.11, 0.34); BONE = (0.16, 0.08, 0.22)
VEIN = (0.48, 0.30, 0.62)
CLAW = (0.62, 0.62, 0.52); SPINE = (0.20, 0.12, 0.28)
EYE = (0.82, 0.60, 0.04); EYE_RIM = (0.06, 0.06, 0.04); PUPIL = (0.03, 0.03, 0.03)

M = Model(S=2, seed=1926)
def V(*a): return [q / 2 for q in a]
def ell(c, r, part, col, over=True, glow=0): M.ell(*V(*c), *V(*r), part, col, over=over, glow=glow)
def cap(a, b, r0, r1, part, col, over=True): M.capsule(V(*a), V(*b), r0 / 2, r1 / 2, part, col, over)

# ---------------- PIERNAS fuertes ----------------
for s, L in ((-1, LL), (1, LR)):
    cap((s * 8, 40, 0), (s * 10, 22, 4), 6.5, 5, L, SKIN)
    cap((s * 10, 22, 4), (s * 9, 6, -1), 5, 4, L, SKIN)
    ell((s * 9, 3, 4), (5.5, 3, 8), L, SKIN_D)
    for f in (-1, 0, 1):
        M.cone(V(s * 9 + f * 3.2, 2, 10), V(s * 9 + f * 3.8, 0.5, 15), 0.7, L, CLAW, CLAW, tip_r=0.5)

# ---------------- TRONCO ancho ----------------
ell((0, 52, 0), (15, 16, 11), T, SKIN)
ell((0, 63, -1), (18, 7, 11), T, SKIN, over=False)                       # hombros
for s in (-1, 1): ell((s * 6, 58, 7), (7, 6, 4), T, SKIN_L, over=False)   # pectorales
ell((0, 46, 7), (9, 11, 5), T, BELLY, over=False)                        # vientre
for (x, y, z), v in list(M.V.items()):                                   # placas del vientre
    if v[1] == BELLY and y % 4 == 0: v[1] = BELLY_D
BACKLINE = {y: min((z for (x, yy, z) in M.V if yy == y and x in (0, -1)), default=-10) for y in range(44, 70, 3)}
for i, y in enumerate(range(44, 70, 3)):                                 # púas en el lomo (base medida antes de ponerlas)
    zb = BACKLINE[y]
    M.cone(V(0, y, zb), V(0, y + 3, zb - 4 - (i % 2) * 2), 1.0, T, SKIN_D, SPINE, tip_r=0.5)

# ---------------- ALAS de murciélago grandes ----------------
def wing(s):
    ROOT, ELB, WRS = (0, 0), (10, 10), (18, 14)
    TIPS = [(40, 22), (38, 6), (31, -8), (22, -16)]
    BODY = (0, -16)
    def P(u, v): return (s * (8 + u), 62 + v, -10 - u * 0.3)
    def tri(p, a, b, scallop):
        (x1, y1), (x2, y2), (x3, y3) = p, a, b
        d = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
        for u2 in range(int(min(x1, x2, x3)) * 2 - 2, int(max(x1, x2, x3)) * 2 + 3):
            for v2 in range(int(min(y1, y2, y3)) * 2 - 2, int(max(y1, y2, y3)) * 2 + 3):
                u, v = u2 / 2, v2 / 2
                l1 = ((y2 - y3) * (u - x3) + (x3 - x2) * (v - y3)) / d
                l2 = ((y3 - y1) * (u - x3) + (x1 - x3) * (v - y3)) / d
                l3 = 1 - l1 - l2
                if min(l1, l2, l3) < 0: continue
                if scallop and l1 < 0.22 * math.sin(math.pi * l3 / max(l2 + l3, 1e-6)): continue
                near = min(l2, l3)
                col = WING_D if near < 0.08 else (WING if near < 0.25 else WING_L)
                x, y, z = P(u, v)
                M.put(x, y, z, T, col, over=False); M.put(x, y, z - 1, T, WING_D, over=False)
    for i in range(len(TIPS) - 1): tri(WRS, TIPS[i], TIPS[i + 1], True)
    tri(WRS, TIPS[-1], BODY, True)
    tri(ROOT, WRS, BODY, False); tri(ROOT, ELB, WRS, False)
    def bone(a, b, col, thick=1):
        n = int(math.dist(a, b) * 2) + 1
        for q in range(n + 1):
            t = q / n
            x, y, z = P(a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
            for dy in range(thick): M.put(x, y + dy, z + 1, T, col)
    for i in range(len(TIPS) - 1):
        m = ((TIPS[i][0] + TIPS[i + 1][0]) / 2, (TIPS[i][1] + TIPS[i + 1][1]) / 2)
        bone(WRS, (WRS[0] + (m[0] - WRS[0]) * 0.8, WRS[1] + (m[1] - WRS[1]) * 0.8), VEIN)
    bone(ROOT, ELB, BONE, 2); bone(ELB, WRS, BONE, 2)
    for t_ in TIPS: bone(WRS, t_, BONE); bone(t_, (t_[0] + 1.5, t_[1] - 1.5), CLAW)
    bone(WRS, (WRS[0] - 1, WRS[1] + 5), BONE); bone((WRS[0] - 1, WRS[1] + 5), (WRS[0] - 3, WRS[1] + 7), CLAW)
for s in (-1, 1): wing(s)

# ---------------- BRAZOS largos con cuatro garras ----------------
for s, A in ((-1, AL), (1, AR)):
    cap((s * 15, 62, 1), (s * 21, 46, 5), 5, 4, A, SKIN)
    cap((s * 21, 46, 5), (s * 22, 32, 9), 4, 3.2, A, SKIN)
    ell((s * 22, 29, 10), (4, 3.5, 4), A, SKIN_D)
    for f in range(4):                                                   # garras finas y curvas
        x = s * 22 + (f - 1.5) * 2.2
        for j in range(6): M.put(x + (f - 1.5) * 0.3 * j, 26 - j, 12 + j * 0.6 - (j > 4), A, CLAW)

# ---------------- CABEZA de pulpo, proporcionada ----------------
ell((0, 76, 4), (11, 9, 10), HD, SKIN)                                   # cara
ell((0, 86, -4), (12.5, 12, 12), HD, SKIN, over=False)                   # manto
ell((0, 93, -13), (8, 7, 8), HD, SKIN, over=False)                       # punta del manto, hacia atrás
for (x, y, z), v in list(M.V.items()):
    if v[0] == HD and v[1] == SKIN and y > 80 and M.noise(x, y, z, 5.0) > 0.68: v[1] = SPOT
for x in range(-8, 8):                                                   # ceño
    z = M.front(x, 81, 40, -10)
    if z is not None and abs(x + 0.5) > 1: M.put(x, 81, z + 1, HD, SKIN_D)
EYE_Y = 78
for s in (-1, 1):                                                        # ojos rasgados, pupila de rendija
    for dx in range(5):
        for dy in range(3 if 1 <= dx <= 3 else 2):
            x = s * (2 + dx) - (1 if s > 0 else 0)
            y = EYE_Y + dy - (1 if dx == 4 else 0) + (1 if dx == 0 else 0)
            z = M.front(x, y, 40, -10)
            if z is None: continue
            pupil = dx == 2 and dy == 1
            M.V[(x, y, z)] = [HD, PUPIL if pupil else EYE, 0 if pupil else 1]
            M.put(x, y, z + 1, HD, PUPIL if pupil else EYE, 0 if pupil else 1)
    for dx in range(-1, 6):                                              # contorno oscuro debajo
        x = s * (2 + dx) - (1 if s > 0 else 0)
        z = M.front(x, EYE_Y - 1, 40, -10)
        if z is not None: M.V[(x, EYE_Y - 1, z)] = [HD, EYE_RIM, 0]

# barba de siete tentáculos largos que llegan al vientre y se enroscan
TENTS = [(-9, 1.0), (-6, 1.2), (-3, 1.35), (0, 1.15), (3, 1.3), (6, 1.25), (9, 0.95)]
for i, (x0, ln) in enumerate(TENTS):
    n = int(24 * ln)
    side = 1 if x0 > 0 else (-1 if x0 < 0 else (1 if i % 2 else -1))
    for k in range(n):
        t = k / n
        curl = max(0.0, t - 0.65) / 0.35
        x = x0 + side * (curl ** 1.5) * 5 + math.sin(k * 0.35 + i) * 1.0
        y = 71 - k + (curl ** 2) * 7
        z = 11 + k * 0.3 + (2 if i % 2 == 0 else 0)
        r = 2.0 * (1 - t) + 0.7
        ell((x, y, z), (r, r, r), HD, TENT if i % 2 else TENT2)
        if k % 5 == 3 and t < 0.75: M.put(x, y - 0.5, z + r, HD, SUCK)

# ---------------- COLOR de la piel ----------------
for (x, y, z), v in list(M.V.items()):
    if v[1] != SKIN: continue
    c = lerp(SKIN, SKIN_D, 0.35 * M.noise(x, y, z, 9.0) + (0.25 if z < -5 else 0.0))
    if (x + 2 * y + z) % 13 == 0: c = SKIN_L
    v[1] = c

piv = {T: [0, 40, 0], HD: [0, 68, 3], AL: [-15, 62, 1], AR: [15, 62, 1], LL: [-8, 40, 0], LR: [8, 40, 0]}
n = M.export('models/engendro.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.45, specular=0.5,
             parents={HD: T, AL: T, AR: T})
print('engendro', n, 'voxels')
