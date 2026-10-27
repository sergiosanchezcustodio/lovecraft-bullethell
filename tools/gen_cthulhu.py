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
Estilo del primigenio menor y del engendro, en adulto (13-10-2026; la versión del 12-10 queda
en gen_cthulhu_v2.py): piel verde azulada con manchas claras en el manto, vientre crema con
placas, ojos amarillos rasgados con pupila de rendija, tentáculos casi negros con ventosas y
alas violetas (más oscuras junto a los huesos).
Hueco: solo la cáscara de cada parte, sin las caras que dan al hueco (voxlib.inner_faces). Partes como Dagon (torso, head, arm_l, arm_r) para anim_dagon.gd.
Uso: python tools/gen_cthulhu.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, inner_faces

T, H, AL, AR = 'torso', 'head', 'arm_l', 'arm_r'
SKIN = (0.18, 0.40, 0.34); SKIN_L = (0.27, 0.51, 0.42); SKIN_D = (0.11, 0.26, 0.23); SPOT = (0.32, 0.56, 0.47)
BELLY = (0.56, 0.62, 0.42); BELLY_D = (0.44, 0.50, 0.34); PLATE = (0.13, 0.30, 0.26)
WING = (0.34, 0.18, 0.50); WING_L = (0.42, 0.24, 0.58); WING_D = (0.22, 0.11, 0.34); VEIN = (0.48, 0.30, 0.62)
BONE = (0.16, 0.08, 0.22); MEMB = WING; MEMB_V = VEIN
CLAW = (0.62, 0.62, 0.52); SPIKE = (0.30, 0.20, 0.40); SUCK = (0.36, 0.46, 0.36)
EYE = (0.82, 0.60, 0.04); EYE_RIM = (0.05, 0.05, 0.04); PUPIL = (0.03, 0.03, 0.03); GLOW = (0.35, 1.0, 0.55)

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
# espina dorsal: pegada al lomo, de la cintura a la nuca; púas pequeñas abajo que crecen al subir
# y se reducen deprisa cerca de la cabeza. Pocas y algo irregulares (altura, separación, ángulo).
import random
rnd = random.Random(1926)
Y_LO, Y_TOP = -12, 78                                             # de la cintura a la nuca
BACK = {yy: min((z for (x, y2, z) in M.V if y2 == yy and x in (0, -1)), default=None) for yy in range(Y_LO, Y_TOP + 1)}
y = Y_LO
while y < Y_TOP:
    t = (y - Y_LO) / (Y_TOP - Y_LO)
    size = (t / 0.78) ** 1.2 if t < 0.78 else max(0.0, 1 - (t - 0.78) / 0.22) ** 2
    h = (5 + 30 * size) * rnd.uniform(0.75, 1.15)
    if h > 3:
        zb = BACK.get(int(y))                                     # el lomo medido antes de poner ninguna
        if zb is not None:
            xo = rnd.uniform(-1.5, 1.5)
            lean = rnd.uniform(0.35, 0.65)                        # cuánto se tumba hacia arriba (pegada al lomo)
            base_r = 2.0 + 3.2 * size
            M.cone((xo, y, zb + 2), (xo + rnd.uniform(-2, 2), y + h * lean * 1.1, zb - h * (1 - lean * 0.6)),
                   base_r, T, SPIKE, CLAW, tip_r=0.5)
    y += rnd.uniform(6.5, 10.5)
for yy in range(Y_LO, Y_TOP - 6):                                 # cresta baja y continua que las une al lomo
    zb = BACK.get(yy)
    if zb is None: continue
    for x in (-1, 0): M.put(x, yy, zb - 1, T, SPIKE, over=False); M.put(x, yy, zb - 2, T, SPIKE, over=False)

# ---------------- alas ----------------
for s in (-1, 1):
    root = (s * 22, 62, -18)
    knuckle = (s * 58, 112, -34)                                  # muñeca del ala
    M.capsule(root, knuckle, 4.5, 3.0, T, BONE)
    tips = [(s * 118, 150, -48), (s * 130, 108, -52), (s * 118, 70, -46), (s * 86, 46, -38)]
    for tip in tips:
        M.capsule(knuckle, tip, 2.8, 1.2, T, BONE)
        for f in (0.33, 0.66):                                    # nudillos
            q = [knuckle[k] + (tip[k] - knuckle[k]) * f for k in range(3)]
            M.ell(q[0], q[1], q[2], 3.6, 3.6, 3.6, T, BONE)
        d = [tip[k] - knuckle[k] for k in range(3)]; L = math.sqrt(sum(c * c for c in d))
        hook = [tip[0] + d[0] / L * 14, tip[1] + d[1] / L * 14 - 7, tip[2] + d[2] / L * 14]
        M.cone(tip, hook, 2.6, T, CLAW, CLAW, tip_r=0.5)          # garra curva en la punta
    M.ell(*knuckle, 6, 6, 6, T, BONE)
    M.cone(knuckle, (knuckle[0] + s * 4, knuckle[1] + 18, knuckle[2] + 6), 3.6, T, CLAW, CLAW, tip_r=0.5)   # pulgar
    for f in (0.3, 0.55, 0.8):                                    # púas en el borde de ataque
        q = [root[k] + (knuckle[k] - root[k]) * f for k in range(3)]
        M.cone(q, (q[0] - s * 3, q[1] + 11, q[2] - 2), 2.2, T, SPIKE, CLAW, tip_r=0.5)
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
                vein = abs(u - v) < 0.02 and edge < 0.85
                near = min(u, v) / max(edge, 1e-6)                      # junto a un hueso: más oscuro
                col = VEIN if vein else (WING_D if near < 0.08 else (WING if near < 0.25 else WING_L))
                M.put(q[0], q[1], q[2], T, col, over=False)

# ---------------- brazos ----------------
for s, A in ((-1, AL), (1, AR)):
    sh, el, wr = (42 * s, 50, 4), (54 * s, 26, 24), (46 * s, 8, 48)
    M.capsule(sh, el, 13, 10, A, SKIN)
    M.capsule(el, wr, 10.5, 8, A, SKIN)
    for k in range(4):                                            # espinas del antebrazo, hacia fuera
        t = 0.2 + k * 0.2
        b = [el[i] + (wr[i] - el[i]) * t for i in range(3)]
        M.cone((b[0] + s * 8, b[1] + 2, b[2]), (b[0] + s * 20, b[1] + 8, b[2] - 5), 3.0, A, SPIKE, CLAW, tip_r=0.5)
    M.sell(wr[0], 5, 56, 14, 6, 14, A, SKIN, p=2.5)
    for f in range(-2, 3):                                        # dedos en garra: falange de piel y uña curva
        a = math.radians(f * 21)
        base = (wr[0] + 11 * math.sin(a), 6, 56 + 11 * math.cos(a))
        mid = (wr[0] + 20 * math.sin(a), 8, 56 + 20 * math.cos(a))           # nudillo levantado
        M.capsule(base, mid, 4.2, 3.6, A, SKIN_D)
        hook = [(mid[0] + (wr[0] + 30 * math.sin(a))) / 2, 7, (mid[2] + 56 + 30 * math.cos(a)) / 2]
        tip = (wr[0] + 32 * math.sin(a), -1, 56 + 32 * math.cos(a))          # se clava hacia abajo
        M.cone(mid, hook, 3.4, A, CLAW, CLAW, tip_r=1.2)
        M.cone(hook, tip, 2.4, A, CLAW, CLAW, tip_r=0.5)

# ---------------- cabeza ----------------
HY, HZ = 74, 22
TENT = (0.08, 0.20, 0.19); TENT_D = (0.12, 0.27, 0.25)            # barba casi negra, como el engendro
M.sell(0, HY + 2, HZ + 4, 24, 16, 20, H, SKIN, p=2.3)             # cara
# manto: un solo bulbo continuo que sube y cae hacia atrás (muchas secciones que se funden)
for k in range(15):
    t = k / 14.0
    cy = HY + 16 + 26 * math.sin(t * 1.5)
    cz = HZ - 6 - 50 * t
    r = 32 - 4 * t if t < 0.6 else 32 - 4 * 0.6 - 36 * (t - 0.6)
    M.ell(0, cy, cz, r, r * 0.92, r, H, SKIN, over=False)
for s in (-1, 1):                                                 # ojos con rabia
    for dx in range(-10, 11):
        for dy in range(-5, 6):
            e = (dx / 10.0) ** 2 + (dy / 4.6) ** 2
            if e > 1.0: continue
            inner = -s * dx                                       # positivo hacia el centro de la cara
            if dy > 1.6 - inner * 0.35: continue                  # párpado de arriba cortado en diagonal
            x = s * 12 + dx
            y = int(round(HY + 9 + dy - inner * 0.30))            # el lado de dentro, más bajo
            z = M.front(x, y, 120, 0)
            if z is None: continue
            if e > 0.62 or dy > 0.6 - inner * 0.35: col, gl = EYE_RIM, 0
            elif abs(dx) <= 1 and abs(dy) <= 3: col, gl = PUPIL, 0
            else: col, gl = EYE, 1
            M.V[(x, y, z)] = [H, col, gl]
            M.put(x, y, z + 1, H, col, gl)
    for k in range(25):                                           # ceja ósea en V, pesada, que baja hacia el centro
        inner = -12 + k                                           # de fuera (-12) hacia dentro (+12)
        x = s * 12 - s * inner
        yb = int(round(HY + 13 - inner * 0.42))
        for dy in range(4):
            z = M.front(x, yb + dy, 120, 0)
            if z is None: continue
            for dz in range(1, 4 - (dy == 3)): M.put(x, yb + dy, z + dz, H, SKIN_D)
# venas en relieve del manto (más oscuras) y manchas que brillan
for (x, y, z), v in list(M.V.items()):
    if v[0] != H or v[1] != SKIN or y < HY + 12: continue
    if abs(math.sin(x * 0.35 + z * 0.08)) < 0.09: M.V[(x, y, z)] = [H, SKIN_D, 0]
    elif M.noise(x, y, z, 7.0) > 0.68: M.V[(x, y, z)] = [H, SPOT, 0]       # manchas claras, como el cachorro
# boca bajo la barba: hueco oscuro de lado a lado con dos colmillos largos y grises
MOUTH = (0.06, 0.02, 0.04); FANG = (0.50, 0.50, 0.50); FANG_D = (0.36, 0.36, 0.37)
M.sell(0, HY - 6, HZ + 20, 16, 9, 9, H, SKIN, p=2.4, over=False)   # morro y mandíbula, bajo los ojos
for x in range(-14, 15):
    for y in range(HY - 14, HY - 1):
        e = (x / 13.5) ** 2 + ((y - (HY - 7)) / 6.0) ** 2
        if e > 1: continue
        z = M.front(x, y, 120, 0)
        if z is not None:
            for dz in range(0, -4, -1): M.put(x, y, z + dz, H, MOUTH)     # boca hundida
# barba: 18 tentáculos largos y tenebrosos que nacen de la cara (raíz del color de la piel que se
# oscurece hasta casi negro con un tinte violeta), se abren a los lados de la boca y se enroscan
TROOT = SKIN; TMID = (0.07, 0.17, 0.17); TTIP = (0.06, 0.04, 0.09)
ROOTS = []                                                        # (x, y): mejillas, morro y barbilla
for x in range(-20, 21, 5): ROOTS.append((x, HY + 3 - abs(x) * 0.12))    # fila alta, bajo los ojos
for x in range(-17, 18, 6): ROOTS.append((x + 2.5, HY - 4))                # fila del morro, tapa la boca
for x in range(-12, 13, 6): ROOTS.append((x, HY - 11))                     # barbilla
for i, (x0, yr) in enumerate(ROOTS):
    side = -1 if x0 < 0 else (1 if x0 > 0 else (1 if i % 2 else -1))
    n = 84 + (i * 13) % 28
    curl = 1 if i % 2 else -1
    zr = (M.front(int(x0), int(yr), 120, 0) or HZ + 22) - 3
    for k in range(n):
        t = k / n
        x = x0 + side * t * (6 + abs(x0) * 0.6) + math.sin(k * 0.17 + i * 1.7) * (1.5 + 4 * t)
        y = yr - k * 0.95
        z = zr + min(k, 18) * 0.7 + max(0, k - 18) * 0.35 + (2 if i % 3 == 0 else 0)
        if t > 0.75:
            a2 = (t - 0.75) / 0.25 * math.pi * 1.5
            x += curl * 8 * math.sin(a2)
            y += 8 * (1 - math.cos(a2))
        r = 5.5 * (1 - t) ** 1.1 + 1.2
        col = lerp(TROOT, TMID, min(1.0, t / 0.1)) if t < 0.1 else lerp(TMID, TTIP, min(1.0, (t - 0.1) / 0.6))
        M.ell(x, y, z, r, 1.6, r, H, col)
        if k % 5 == 0 and 0.12 < t < 0.85: M.ell(x, y - 0.5, z + r * 0.85, max(r * 0.33, 0.9), 0.9, 0.9, H, SUCK)   # ventosas
# ---------------- piel ----------------
for (x, y, z), v in list(M.V.items()):
    if v[1] != SKIN: continue
    c = lerp(SKIN, SKIN_D, 0.45 * M.noise(x, y, z, 12.0) + (0.25 if z < -8 else 0))
    if (x + 2 * y + z) % 11 == 0: c = SKIN_L                      # escamas
    M.V[(x, y, z)] = [v[0], c, v[2]]
for (x, y, z), v in list(M.V.items()):                            # placas del vientre
    if v[1] == BELLY and y % 5 == 0: v[1] = BELLY_D
# Vaciado por partes (27-10-2026, como Dagon): fuera lo que tiene voxels de la misma parte a 1 y 2 en
# las seis direcciones. Antes contaba cualquier parte, y el tronco quedaba abierto bajo el brazo y la
# barba: al girarlos se veía el hueco, y las caras de dentro no se podían quitar.
dirs = [(1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)]
inside = [k for k, v in M.V.items() if all(M.V.get((k[0] + a * d, k[1] + b * d, k[2] + c * d), (None,))[0] == v[0]
                                           for a, b, c in dirs for d in (1, 2))]
for k in inside: del M.V[k]
for k in [k for k in M.V if k[1] < -16]: del M.V[k]
piv = {T: [0, -4, 0], H: [0, 62, 14], AL: [-42, 50, 4], AR: [42, 50, 4]}
skip = inner_faces(M, (T, H, AL, AR), floor=-16)                   # sin las caras que dan al hueco
n = M.export('models/cthulhu.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.4, specular=0.5,
             parents={H: T, AL: T, AR: T}, skip=skip)
print('cthulhu: %d voxels, %d con caras de dentro' % (n, len(skip)))
