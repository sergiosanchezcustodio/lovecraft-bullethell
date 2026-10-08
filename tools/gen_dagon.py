"""Padre Dagon (hito 6.6), jefe de la parte 2. Colosal: asoma del mar de cintura para arriba.
16 voxels/m (S=1, 1 voxel = 1 ub) y unos 7 m sobre el agua; en el juego, a escala 1,6.

Solo anatomía (CLAUDE.md: los Profundos sin ropa ni adornos): tronco encorvado y ancho con
escamas verdinegras y vientre pálido, cabeza de pez enorme y chata con la mandíbula colgante
llena de dientes, ojos saltones que brillan en verde amarillento, agallas rojizas, cresta de
púas de la nuca a la cintura, aletas en los antebrazos y manos palmeadas con garras.
La base del tronco se hunde por debajo del agua (y < 0). Hueco: solo la cáscara.

Partes y pivotes: torso (cintura, en el agua), head (nuca), arm_l / arm_r (hombros).
Animaciones: scripts/anim/anim_dagon.gd. Uso: python tools/gen_dagon.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

T, H, AL, AR = 'torso', 'head', 'arm_l', 'arm_r'
BACK = (0.10, 0.16, 0.14); FLANK = (0.19, 0.29, 0.24); SCALE = (0.14, 0.23, 0.19)
BELLY = (0.42, 0.46, 0.36); BELLY_SH = (0.34, 0.38, 0.30)
FIN = (0.22, 0.32, 0.30); FIN_SH = (0.15, 0.23, 0.21)
EYE = (0.85, 0.95, 0.40); PUPIL = (0.03, 0.03, 0.02)
MOUTH = (0.10, 0.04, 0.05); TOOTH = (0.86, 0.84, 0.72); GILL = (0.55, 0.20, 0.20)
CLAW = (0.80, 0.78, 0.66); SPINE = (0.62, 0.60, 0.50)

M = Model(S=1, seed=1931)

# ---------------- tronco: encorvado hacia delante, hombros enormes ----------------
M.sell(0, 14, 0, 30, 26, 22, T, FLANK, p=2.4)                  # vientre y cintura (se hunde en el agua)
M.sell(0, 44, 6, 40, 22, 26, T, FLANK, p=2.4)                  # pecho y hombros, adelantados
M.sell(0, 50, -8, 30, 18, 18, T, BACK, p=2.2, over=False)      # joroba
M.sell(0, 58, 14, 18, 10, 16, T, FLANK, p=2.4)                 # cuello grueso

# ---------------- cabeza de pez ----------------
HY, HZ = 72, 26
M.sell(0, HY, HZ, 26, 18, 26, H, FLANK, p=2.6)
M.sell(0, HY - 14, HZ + 6, 22, 8, 22, H, BELLY, p=2.6)         # mandíbula colgante, pálida
M.sell(0, HY + 10, HZ - 6, 18, 8, 18, H, BACK, p=2.4, over=False)   # coronilla
zf = HZ + 26
for x in range(-20, 21):                                      # boca: una raja enorme de lado a lado
    for y in range(HY - 9, HY - 4):
        z = zf - int(abs(x) * 0.25) - 1
        M.put(x, y, z, H, MOUTH)
        if y in (HY - 9, HY - 5) and x % 3 == 0 and abs(x) < 19:
            M.put(x, y + (1 if y == HY - 9 else -1), z + 1, H, TOOTH)
            M.put(x, y + (2 if y == HY - 9 else -2), z + 1, H, TOOTH)
for s in (-1, 1):                                             # ojos saltones a los lados, que brillan
    ex, ey, ez = 24 * s, HY + 4, HZ + 10
    M.ell(ex, ey, ez, 7, 7, 7, H, EYE, glow=1)
    M.ell(ex + 3 * s, ey, ez + 1, 3, 4, 3, H, PUPIL)
    M.sell(ex - 1 * s, ey + 6, ez, 8, 3, 8, H, BACK, over=False)        # párpado
    for k in range(4):                                        # agallas detrás del ojo
        for y in range(HY - 8, HY + 2):
            M.put(int(ex - 2 * s), y, ez - 12 - k * 3, H, GILL)

# ---------------- brazos: largos, apoyados delante en el agua ----------------
for s, A in ((-1, AL), (1, AR)):
    sh = (38 * s, 50, 4)
    el = (46 * s, 26, 22)
    wr = (40 * s, 8, 44)
    M.capsule(sh, el, 11, 9, A, FLANK)
    M.capsule(el, wr, 9, 7, A, FLANK)
    M.sell(wr[0], 4, 54, 12, 5, 12, A, FLANK, p=2.6)          # mano palmeada, abierta sobre el agua
    for f in range(-2, 3):                                    # dedos con garras
        a = math.radians(f * 22)
        base = (wr[0] + 10 * math.sin(a), 4, 54 + 10 * math.cos(a))
        tip = (wr[0] + 20 * math.sin(a), 2, 54 + 20 * math.cos(a))
        M.capsule(base, tip, 3, 2, A, FLANK)
        M.cone(tip, (tip[0] + 5 * math.sin(a), 0, tip[2] + 5 * math.cos(a)), 2, A, CLAW, CLAW, tip_r=0.8)
    for k in range(12):                                       # aleta del antebrazo hacia fuera
        t = k / 11
        c = [el[i] + (wr[i] - el[i]) * t for i in range(3)]
        for h in range(4, 12 - int(abs(t - 0.5) * 10)):
            M.put(int(c[0] + (8 + h) * s), int(c[1] + 2), int(c[2]), A, FIN if h % 3 else FIN_SH)

# ---------------- cresta de púas de la nuca a la cintura ----------------
for i in range(14):
    t = i / 13
    y = 88 - t * 70
    z = HZ - 20 - t * 10 if y > 60 else -26 + (60 - y) * 0.15
    part = H if y > 62 else T
    M.cone((0, y, z), (0, y + 6, z - 14 + t * 4), 4.5, part, FIN_SH, SPINE, tip_r=0.8)

# ---------------- colores: lomo, flancos con escamas y vientre ----------------
for (x, y, z), v in list(M.V.items()):
    if v[1] != FLANK: continue
    c = FLANK
    if z < -6 and v[0] == T: c = BACK
    elif v[0] == T and z > 16 and abs(x) < 20 and y < 52: c = BELLY if y % 4 else BELLY_SH
    elif (x + 2 * y + z) % 5 == 0 or ((x // 3 + y // 2) % 4 == 0 and M.noise(x, y, z, 5) > 0.5): c = SCALE
    c = lerp(c, BACK, 0.35 * M.noise(x, y, z, 14.0))
    M.V[(x, y, z)] = [v[0], c, v[2]]

# hueco: fuera lo que no se ve (vecinos a dos voxels en todas las direcciones)
dirs = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
inside = [k for k in M.V if all((k[0] + a * d, k[1] + b * d, k[2] + c * d) in M.V for a, b, c in dirs for d in (1, 2))]
for k in inside: del M.V[k]
for k in [k for k in M.V if k[1] < -16]: del M.V[k]               # lo que queda muy hondo

piv = {T: [0, -4, 0], H: [0, 60, 14], AL: [-38, 50, 4], AR: [38, 50, 4]}
n = M.export('models/dagon.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.5, specular=0.45,
             parents={H: T, AL: T, AR: T})
print('dagon: %d voxels' % n)
