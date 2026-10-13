"""Padre Dagon (hito 6.6), jefe de la parte 2. Colosal: asoma del mar de cintura para arriba.
16 voxels/m (S=1, 1 voxel = 1 ub) y unos 7 m sobre el agua; en el juego, a escala 1,6.

Solo anatomía (CLAUDE.md: los Profundos sin ropa ni adornos): tronco encorvado y ancho con
escamas verdinegras y vientre pálido, cabeza de pez enorme y chata con la mandíbula colgante
llena de dientes grandes y torcidos, ojos saltones que brillan en verde amarillento con la pupila
blanca, agallas rojizas, cresta de púas continua de la coronilla a la cintura, aletas en los antebrazos y manos palmeadas con garras.
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
EYE = (0.85, 0.95, 0.40); PUPIL = (0.03, 0.03, 0.02); PUPIL_W = (1.0, 1.0, 0.96)
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
def mouth_z(x): return zf - int(abs(x) * 0.25) - 1
for x in range(-20, 21):                                      # boca: una raja enorme de lado a lado
    for y in range(HY - 12, HY - 2):
        M.put(x, y, mouth_z(x), H, MOUTH)
# dientes grandes, deformes y torcidos: largos y cortos, alguno roto o que falta, ladeados,
# amarillentos en la raíz y manchados
TOOTH_Y = (0.66, 0.60, 0.40); TOOTH_D = (0.45, 0.40, 0.28)
def tooth(x, root, down, L, w, tilt, k):
    for j in range(L):
        f = j / max(1, L - 1)
        dx = int(round(tilt * f * f))
        y = root - j if down else root + j
        c = lerp(TOOTH_Y, TOOTH, min(1.0, f * 1.4))
        if M.hsh(x, j, k) > 0.85: c = TOOTH_D                   # mancha
        ww = w if f < 0.6 else 1                                 # se afila
        for wx in range(ww):
            for dz in (0, 1):
                M.put(x + dx + wx, y, mouth_z(x) + 1 + dz, H, c)
x = -19; k = 0
while x < 19:
    h = M.hsh(k, 7, 1)
    if h > 0.12:                                              # alguno falta
        L = 3 + int(M.hsh(k, 7, 2) * 6) if abs(x) < 15 else 2 + int(M.hsh(k, 7, 2) * 3)
        if M.hsh(k, 7, 3) > 0.85: L = 2                       # roto
        tooth(x, HY - 3, True, L, 1 + int(M.hsh(k, 7, 4) > 0.5), (M.hsh(k, 7, 5) - 0.5) * 5, k)
    x += 2 + int(M.hsh(k, 7, 6) * 2); k += 1
x = -17; k = 50
while x < 17:
    if M.hsh(k, 8, 1) > 0.2:
        L = 2 + int(M.hsh(k, 8, 2) * 4)
        tooth(x, HY - 12, False, L, 1 + int(M.hsh(k, 8, 4) > 0.6), (M.hsh(k, 8, 5) - 0.5) * 4, k)
    x += 2 + int(M.hsh(k, 8, 6) * 3); k += 1
for s in (-1, 1):                                             # ojos saltones a los lados, que brillan
    ex, ey, ez = 24 * s, HY + 4, HZ + 10
    M.ell(ex, ey, ez, 7, 7, 7, H, EYE, glow=1)
    dv = (0.62 * s, -0.12, 0.78); n = math.sqrt(sum(c * c for c in dv)); dv = [c / n for c in dv]
    for (x, y, z), v in list(M.V.items()):                    # mira hacia fuera y hacia delante
        if v[1] != EYE: continue
        o = (x - ex, y - ey, z - ez); l = math.sqrt(sum(c * c for c in o)) or 1.0
        d = sum(o[i] * dv[i] for i in range(3)) / l
        if d > 0.92: M.V[(x, y, z)] = [H, PUPIL_W, 1]
        elif d > 0.78: M.V[(x, y, z)] = [H, PUPIL, 0]
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

# ---------------- cresta de púas continua: de la coronilla a la cintura ----------------
# Rayos en el plano x = 0 desde dentro del cuerpo: el último voxel de cada uno es el contorno del
# lomo. Una cresta baja lo recorre entero y las púas salen de ella a trechos algo irregulares,
# medianas en la cabeza, grandes en la joroba y pequeñas hacia la cintura, inclinadas hacia atrás.
CY, CZ = 44, 8
prof = []
for i in range(0, 241):
    th = math.radians(-18 + i * 0.7)
    dy, dz = math.cos(th), -math.sin(th)
    last = None
    for r in range(0, 90):
        q = (0, int(round(CY + dy * r)), int(round(CZ + dz * r)))
        if q in M.V: last = q
    if last and last[1] > 4: prof.append((th, last, M.V[last][0]))
def size_at(th):
    d = math.degrees(th)
    if d < 25: return 0.65                                    # cabeza
    if d < 45: return 0.5                                     # nuca
    return 0.5 + 0.5 * math.sin(math.pi * min(1.0, (d - 45) / 105)) ** 0.7 if d < 120 else max(0.3, 1.0 - (d - 120) / 60)
arc = 0.0; nxt = 0.0; prev = None; n = 0
for th, (x0, y0, z0), part in prof:
    if prev: arc += math.hypot(y0 - prev[1], z0 - prev[2])
    prev = (x0, y0, z0)
    sz = size_at(th)
    dy, dz = math.cos(th), -math.sin(th)
    for h in range(1, 2 + int(2.5 * sz)):                     # cresta
        for xx in (-1, 0, 1) if h == 1 else (0,):
            M.put(xx, int(round(y0 + dy * h)), int(round(z0 + dz * h)), part, FIN_SH, over=False)
    if arc >= nxt:
        L = (8 + 12 * sz) * (0.8 + 0.4 * M.hsh(n, 3, 1))
        back = th + math.radians(30 + 20 * M.hsh(n, 3, 2))    # inclinada hacia la cola
        side = (M.hsh(n, 3, 3) - 0.5) * 3
        tip = (side, y0 + math.cos(back) * L, z0 - math.sin(back) * L)
        M.cone((0, y0 - dy * 2, z0 - dz * 2), tip, 2.2 + 2.6 * sz, part, FIN_SH, SPINE, tip_r=0.8)
        nxt = arc + (6 + 6 * sz) * (0.75 + 0.5 * M.hsh(n, 3, 4)); n += 1

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
