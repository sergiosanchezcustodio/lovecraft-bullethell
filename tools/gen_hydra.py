"""Madre Hydra (hito 6.5; rediseñada en la revisión de arte del 13-10-2026: la de antes era
casi un Profundo). Matriarca abisal colosal (en el juego a escala 3), solo anatomía:

- Cabeza de rape, ancha y pegada a los hombros: mandíbula inferior que sobresale, boca
  abierta con agujas que asoman por fuera, dos pares de ojos pequeños de luz cian y un
  señuelo (illicio) que sale de la frente y cuelga delante de la cara con una perla de luz.
- Barbillas: un manojo de zarcillos finos que cuelgan de la mandíbula, con la punta encendida
  (las "cabezas" de la hidra).
- Cuerpo barrigón y pesado, hombros anchos, piernas cortas y gruesas, y una cola gruesa que
  arrastra por detrás con aleta.
- Espinas de pez león en abanico a lo largo de la espalda y en los antebrazos, a franjas
  óxido y crema, con membrana solo en la base.
- Piel granate casi negra en el lomo, vino en los flancos, vientre coral pálido y una fila de
  fotóforos cian en cada costado.

Base de estilo 4 (tools/cuerpo.py, 48 voxels/m) con los pivotes humanos: anim_profundo.gd.
Uso: python tools/gen_hydra.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, rslab, T, H

BACK = (0.13, 0.05, 0.10); FLANK = (0.30, 0.10, 0.16); SCALE = (0.23, 0.07, 0.12)
BELLY = (0.70, 0.50, 0.44); BELLY_SH = (0.60, 0.42, 0.37)
RUST = (0.66, 0.24, 0.10); CREAM = (0.88, 0.80, 0.62); MEMB = (0.36, 0.12, 0.14)
CLAW = (0.82, 0.78, 0.66); TOOTH = (0.92, 0.90, 0.80); MOUTH = (0.10, 0.02, 0.04)
GLOW = (0.30, 0.85, 0.95); PUPIL = (0.02, 0.03, 0.04); STALK = (0.20, 0.07, 0.12)
AX = 18.0                                                               # brazos más separados

M = cu.new(1931)
M.body.update(ax=AX)

# ---------------- piernas cortas y gruesas, pies palmeados ----------------
for s, leg, shin, _, _ in cu.sides():
    cx = 7 * s
    slab(M, shin, FLANK, 0, 3, cx, 4, 13, 12, 20, 17, ch=1)                # pie ancho y largo
    for x in (-4, -1, 2, 5):                                               # garras
        for z in (14, 15): M.put(int(cx) + x, 0, z, shin, CLAW); M.put(int(cx) + x, 1, z - 1, shin, CLAW)
    slab(M, shin, FLANK, 3, 14, cx, 0, 9, 11, 9, 11, ch=2)
    slab(M, shin, FLANK, 14, 27, cx, -0.5, 12, 14, 12, 14, ch=3, zoff1=-1)
    slab(M, leg, FLANK, 27, 42, cx * 1.15, 0.5, 15, 19, 14, 17, ch=4)

# ---------------- tronco: barriga pesada y hombros anchos ----------------
slab(M, T, FLANK, 38, 46, 0, 1, 28, 31, 19, 22, ch=5)
slab(M, T, FLANK, 46, 54, 0, 2.5, 31, 32, 22, 23, ch=6)                  # barriga hacia delante
slab(M, T, FLANK, 54, 62, 0, 0.5, 32, 30, 21, 17, ch=6)                  # pecho y hombros
slab(M, T, BACK, 50, 63, 0, -8, 22, 18, 8, 8, ch=4, over=False)          # chepa
slab(M, T, FLANK, 33, 39, 0, 4, 22, 28, 14, 18, ch=5, over=False)        # barriga que cuelga

# ---------------- cola gruesa que arrastra ----------------
N = 40
for i in range(N + 1):
    t = i / N
    y = 42 - 38 * t ** 0.8
    z = -8 - 30 * t
    x = 3 * math.sin(t * 2.6)
    r = 8.5 * (1 - t) + 2.2
    for dx in range(-int(r) - 1, int(r) + 2):
        for dy in range(-int(r) - 1, int(r) + 2):
            for dz in (-1, 0, 1):
                if (dx * dx + dy * dy) <= r * r and y + dy >= 0:
                    M.put(int(round(x + dx)), int(round(y + dy)), int(round(z + dz)), T, FLANK, over=False)
tx, ty, tz = 3 * math.sin(2.6), 4, -38                                     # aleta de la cola, vertical
for k in range(-12, 13):
    for j in range(0, 14 - abs(k) // 2):
        col = RUST if (j // 2) % 2 == 0 else CREAM
        if j < 3: col = MEMB
        M.put(int(tx), max(0, int(ty + k * 0.6 + 4)), int(tz - j), T, col, over=False)

# color: lomo oscuro, barriga coral, escamas en los flancos
for (x, y, z), v in M.V.items():
    if v[1] != FLANK: continue
    if z <= -4: v[1] = BACK
    elif v[0] == T and z >= 6 and abs(x + 0.5) < 11 and 33 <= y <= 56: v[1] = BELLY if y % 3 else BELLY_SH
    elif M.noise(x, y, z, 6.0) > 0.72: v[1] = BELLY_SH
    elif (x + y + (y // 2) * 2 + z) % 4 == 0: v[1] = SCALE

# fotóforos en los costados
for s in (-1, 1):
    for y in range(40, 60, 3):
        for x in range(-17, 18):
            if (s * x) < 0: continue
            k = max((xx for xx in range(0, 20) if (s * xx, y, 4) in M.V), default=None)
            if k is not None: M.V[(s * k, y, 4)] = [T, GLOW, 1]; break

# ---------------- brazos largos y gruesos con abanicos de espinas ----------------
for s, _, _, arm, fa in cu.sides():
    cx = AX * s
    slab(M, arm, FLANK, 46, 62, cx, 1, 8, 10, 8, 10, ch=2)
    slab(M, fa, FLANK, 35, 47, cx * 1.02, 1.5, 7, 8, 7, 8, ch=2)
    cu.hand_(M, fa, cx * 1.02, FLANK)
    for (x, y, z), v in list(M.V.items()):                                 # garras largas en los dedos
        if v[0] == fa and y <= 24: M.V[(x, y, z)] = [fa, CLAW, 0]
    for (x, y, z), v in list(M.V.items()):
        if v[0] == fa and y in (21, 22) and v[1] == FLANK: M.V[(x, y, z)] = [fa, CLAW, 0]
    for k in range(5):                                                     # abanico del antebrazo: hacia fuera y atrás
        a = math.radians(-10 + k * 22)
        y0 = 37 + k * 2
        for r in range(1, 12 - abs(k - 2)):
            x = int(round(cx * 1.02 + s * (4 + r * math.cos(a) * 0.7)))
            y = int(round(y0 + r * math.sin(a) * 0.6))
            z = int(round(-3 - r * 0.8))
            col = MEMB if r < 4 else (RUST if (r // 2) % 2 == 0 else CREAM)
            M.put(x, y, z, fa, col)
            if r < 4: M.put(x, y + 1, z, fa, MEMB, over=False)

# ---------------- cabeza de rape ----------------
HZ = 3
rslab(M, H, FLANK, 64, 80, 0, HZ, 26, 20, r=8, rt=7, rb=1)               # cráneo ancho y chato
rslab(M, H, BACK, 76, 81, 0, HZ - 3, 20, 14, r=4, rt=3, rb=0)            # coronilla oscura
rslab(M, H, BELLY, 58, 66, 0, HZ + 3, 26, 22, r=7, rt=0, rb=4)           # mandíbula inferior, sobresale
ZU = HZ + 10                                                              # frente de la cabeza
ZJ = HZ + 14                                                              # frente de la mandíbula
for x in range(-11, 11):                                                  # boca abierta y oscura
    for y in (65, 66, 67):
        for z in range(ZU - 6, ZJ):
            if (x, y, z) in M.V or z >= ZU - 1: M.put(x, y, z, H, MOUTH)
for x in range(-11, 11):                                                  # labio de la mandíbula
    M.put(x, 64, ZJ - 1, H, BELLY_SH)
for x in range(-10, 11, 2):                                               # agujas de abajo: suben por fuera de la cara
    h = 4 + (x % 4 == 0) * 2
    for y in range(65, 65 + h): M.put(x, y, ZJ - 1, H, TOOTH)
for x in range(-9, 10, 3):                                                # agujas de arriba: cuelgan
    for y in range(64, 68): M.put(x, y, ZU - 1, H, TOOTH)
for s in (-1, 1):                                                         # dos pares de ojos pequeños de luz
    for (ex, ey, n) in ((8, 73, 3), (11, 77, 2)):
        x0 = s * ex - (n - 1 if s > 0 else 0)
        for dx in range(n):
            for dy in range(n):
                x = x0 + dx; y = ey + dy
                z = M.front(x, y, 40, -20)
                if z is None: continue
                pupil = n == 3 and dx == 1 and dy == 1
                M.V[(x, y, z)] = [H, PUPIL if pupil else GLOW, 0 if pupil else 1]
                M.put(x, y, z + 1, H, PUPIL if pupil else GLOW, 0 if pupil else 1)
    for y in (68, 70, 72):                                                # agallas a los lados
        for z in range(HZ - 6, HZ + 1):
            x = s * 13 - (1 if s > 0 else 0)
            if (x, y, z) in M.V: M.V[(x, y, z)] = [H, MEMB, 0]
# señuelo: de la frente hacia arriba y delante, curvado, con la perla de luz delante de la boca
pts = []
for i in range(41):
    t = i / 40
    a = t * math.pi * 1.15
    pts.append((0, 80 + 13 * math.sin(a), HZ + 2 + 12 * (1 - math.cos(a)) * 0.9))
for (x, y, z) in pts:
    M.put(0, int(round(y)), int(round(z)), H, STALK); M.put(-1, int(round(y)), int(round(z)), H, STALK)
ex, ey, ez = 0, int(round(pts[-1][1])) - 2, int(round(pts[-1][2]))
for dx in range(-2, 2):
    for dy in range(-2, 2):
        for dz in range(-2, 2):
            if (dx + 0.5) ** 2 + (dy + 0.5) ** 2 + (dz + 0.5) ** 2 <= 4.2: M.put(ex + dx, ey + dy, ez + dz, H, GLOW, 1)
# barbillas: zarcillos que cuelgan de la mandíbula con la punta encendida
for i, x0 in enumerate(range(-10, 11, 3)):
    n = 9 + (i * 5) % 7
    for k in range(n):
        x = int(round(x0 + math.sin(k * 0.45 + i) * 1.2))
        y = 58 - k
        z = ZJ - 3 + (k // 4)
        tip = k >= n - 2
        M.put(x, y, z, H, GLOW if tip else STALK, 1 if tip else 0)

# ---------------- espinas de pez león a lo largo de la espalda ----------------
# Abanico: espinas de 2x2 hacia atrás y arriba, unidas por membrana hasta la mitad
spines = []
BACKLINE = {y: min((z for (x, yy, z), v in M.V.items() if yy == y and x in (0, -1) and v[0] in (T, H)), default=None)
            for y in range(44, 78, 3)}                                    # antes de poner ninguna: si no, nacen de la anterior
for j, y in enumerate(range(44, 78, 3)):
    part = H if y >= 64 else T
    zb = BACKLINE[y]
    if zb is None: continue
    if y >= 64: part = H
    L = int((5 if y >= 66 else 7) + 6 * math.sin((y - 42) / 38 * math.pi))                   # más largas en medio
    ang = math.radians(25 + 40 * (y - 44) / 34)                           # las de arriba, más verticales
    pts = [(y + r * math.sin(ang), zb - r * math.cos(ang)) for r in range(0, L + 1)]
    spines.append((part, pts))
    for r, (yy, zz) in enumerate(pts):
        col = MEMB if r <= 1 else (RUST if (r // 2) % 2 == 0 else CREAM)
        for x in (-1, 0):
            for dy in (0, 1): M.put(x, int(round(yy)) + dy, int(round(zz)), part, col)
for (pa, A), (pb, B) in zip(spines, spines[1:]):                         # membrana entre espinas
    n = min(len(A), len(B)) * 6 // 10
    for r in range(1, n):
        (y0, z0), (y1, z1) = A[r], B[r]
        steps = int(max(abs(y1 - y0), abs(z1 - z0))) + 1
        for q in range(steps + 1):
            t = q / steps
            yy, zz = y0 + (y1 - y0) * t, z0 + (z1 - z0) * t
            for x in (-1, 0): M.put(x, int(round(yy)), int(round(zz)), pa if t < 0.5 else pb, MEMB, over=False)
# espinas de los hombros, hacia fuera y arriba
for s in (-1, 1):
    for k in range(3):
        bx, by = s * (12 + k * 3), 61 - k
        for r in range(1, 10 - k * 2):
            col = RUST if (r // 2) % 2 == 0 else CREAM
            M.put(bx + s * int(r * 0.6), by + r, -6 - int(r * 0.5), T, col)

piv = cu.hunch(M, k=0.06, y0=40, head_drop=3)
cu.finish(M, 'hydra', {BACK: 'piel', FLANK: 'piel', SCALE: 'piel'},
          flat=(GLOW, PUPIL, MOUTH, TOOTH, CLAW, RUST, CREAM, MEMB, STALK), extra_pivots=piv, ax=AX,
          roughness=0.45, specular=0.5)
