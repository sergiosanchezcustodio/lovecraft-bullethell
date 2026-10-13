"""Diablo con alas de murciélago de la leyenda del pantano de Luisiana (fase 7, hito 7.2;
rehecho en la revisión de arte del 13-10-2026 a más resolución).

Criatura menuda (1,2 m), flaca y encorvada, de piel correosa gris verdosa casi negra con
costillas marcadas y púas en el espinazo; patas de ave (digitígradas) con espolones, brazos
largos con tres garras, cola de látigo con punta de flecha.
Cara de vampiro: cráneo alargado, orejas de murciélago grandes y puntiagudas con el interior
rojizo, ceño óseo, hocico chato con hoja nasal, ojos grandes y rasgados de luz roja con el
centro amarillo, boca ancha con dos colmillos largos que caen sobre el labio. Cuernos largos y
afilados, anillados, que salen de la frente hacia atrás y se curvan arriba.
Alas de murciélago grandes (unos 2,6 m de envergadura): húmero y antebrazo, garra del pulgar,
cuatro dedos largos con nudillos; membrana festoneada entre los dedos, más oscura junto a los
huesos y rojiza en medio, con venas y algún desgarrón, que baja hasta el tobillo.

48 voxels/m (S=3); medidas en voxels. Partes: body, head, wing_l, wing_r, tail (anim_diablo.gd:
fly, dive). Uso: python tools/gen_diablo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

B, HD, WL, WR, TL = 'body', 'head', 'wing_l', 'wing_r', 'tail'
SKIN = (0.20, 0.22, 0.19); SKIN_L = (0.30, 0.32, 0.27); SKIN_D = (0.10, 0.11, 0.10)
FACE = (0.30, 0.30, 0.30); FACE_D = (0.18, 0.18, 0.19)                # cara algo más pálida
MEMB = (0.36, 0.13, 0.13); MEMB_L = (0.46, 0.18, 0.16); MEMB_D = (0.18, 0.07, 0.08)
VEIN = (0.52, 0.22, 0.20); EAR_IN = (0.50, 0.20, 0.20)
BONE = (0.22, 0.20, 0.18); HORN = (0.30, 0.27, 0.22); HORN_L = (0.62, 0.58, 0.48)
CLAW = (0.80, 0.76, 0.64); MOUTH = (0.22, 0.03, 0.04); FANG = (0.92, 0.90, 0.82)
EYE = (0.95, 0.12, 0.06); EYE_C = (1.0, 0.80, 0.20); PUPIL = (0.02, 0.0, 0.0)

M = Model(S=3, seed=1907)
U = 1 / 3                                                     # voxels -> ub


def ball(x, y, z, r, part, col, over=True, glow=0):
    M.ell(x * U, y * U, z * U, r * U, r * U, r * U, part, col, over=over, glow=glow)


def limb(pts, r0, r1, part, col):
    """Cadena de esferas por los puntos, de radio r0 a r1."""
    segs = list(zip(pts, pts[1:]))
    tot = sum(math.dist(a, b) for a, b in segs)
    acc = 0.0
    for a, b in segs:
        L = math.dist(a, b); n = max(1, int(L * 2))
        for i in range(n + 1):
            t = i / n
            p = [a[k] + (b[k] - a[k]) * t for k in range(3)]
            r = r0 + (r1 - r0) * (acc + L * t) / tot
            ball(*p, r, part, col)
        acc += L


def line(a, b, part, col, glow=0):
    n = int(max(abs(b[i] - a[i]) for i in range(3)) * 2) + 1
    for i in range(n + 1):
        t = i / n
        M.put(*(a[k] + (b[k] - a[k]) * t for k in range(3)), part, col, glow)


# ---------------- cuerpo ----------------
M.ell(0, 34 * U, 0, 7 * U, 10 * U, 6 * U, B, SKIN)                      # tronco flaco
M.ell(0, 42 * U, -1 * U, 9 * U, 5 * U, 6 * U, B, SKIN, over=False)      # hombros
M.ell(0, 27 * U, 1 * U, 6 * U, 5 * U, 5 * U, B, SKIN, over=False)       # vientre
for y in (31, 34, 37, 40):                                              # costillas marcadas
    for x in range(-5, 5):
        z = M.front(x, y, 30, -10)
        if z is not None and abs(x + 0.5) > 1: M.V[(x, y, z)][1] = SKIN_D
for i, y in enumerate(range(26, 46, 3)):                                # púas en el espinazo
    zb = min((z for (x, yy, z) in M.V if yy == y and x in (0, -1)), default=-6)
    line((0, y, zb), (0, y + 2, zb - 3 - (i % 2)), B, HORN)
for s in (-1, 1):                                                       # patas de ave
    limb([(s * 4, 28, 0), (s * 5, 18, 6), (s * 5, 9, -2), (s * 5, 2, 2)], 3.2, 1.6, B, SKIN)
    for f in (-1, 0, 1):                                                # dedos con espolones
        line((s * 5, 2, 2), (s * 5 + f * 2, 0, 7), B, SKIN_D)
        line((s * 5 + f * 2, 0, 7), (s * 5 + f * 2.4, 0, 10), B, CLAW)
    line((s * 5, 2, 0), (s * 5, 0, -4), B, CLAW)                        # espolón de atrás
    limb([(s * 8, 41, 1), (s * 12, 31, 4), (s * 12, 22, 8)], 2.2, 1.3, B, SKIN)   # brazos largos
    for f in (-1, 0, 1):                                                # tres garras largas y curvas
        line((s * 12, 22, 8), (s * (12 + f * 1.5), 17, 10), B, SKIN_D)
        line((s * (12 + f * 1.5), 17, 10), (s * (12 + f * 1.8), 13, 10), B, CLAW)
        line((s * (12 + f * 1.8), 13, 10), (s * (12 + f * 1.8), 12, 8), B, CLAW)

# ---------------- cabeza de vampiro ----------------
HY, HZ = 52, 3
M.ell(0, HY * U, HZ * U, 5.5 * U, 6 * U, 6 * U, HD, FACE)               # cráneo
M.ell(0, (HY + 3) * U, (HZ - 3) * U, 5 * U, 5 * U, 6 * U, HD, FACE, over=False)   # nuca alargada
M.ell(0, (HY - 4) * U, (HZ + 3) * U, 4 * U, 3 * U, 3.5 * U, HD, FACE, over=False) # mandíbula
ZF = max(z for (x, y, z), v in M.V.items() if v[0] == HD)               # plano de la cara
for x in range(-5, 5):                                                  # ceño óseo
    for y in (HY + 3, HY + 4):
        if abs(x + 0.5) > 0.6 and (y == HY + 3 or abs(x + 0.5) > 2.5):
            z = M.front(x, y, 40, -10)
            if z is not None: M.put(x, y, z + 1, HD, FACE_D)
for s in (-1, 1):                                                       # ojos grandes y rasgados
    for dx in range(4):
        for dy in range(3):
            if (dx == 0 and dy == 2) or (dx == 3 and dy == 0): continue  # rasgados hacia dentro y arriba
            x = s * (1 + dx) - (1 if s > 0 else 0)
            y = HY - 1 + dy + (1 if dx >= 2 else 0) * (dy == 2)
            z = M.front(x, y, 40, -10)
            if z is None: continue
            core = dx in (1, 2) and dy == 1
            M.V[(x, y, z)] = [HD, EYE_C if core else EYE, 1]
            M.put(x, y, z + 1, HD, EYE_C if core else EYE, 1)
    x = s * 2 - (1 if s > 0 else 0); z = M.front(x, HY, 40, -10)        # pupila de rendija
    if z is not None: M.V[(x, HY, z)] = [HD, PUPIL, 0]
for (x, y) in ((-1, HY - 3), (0, HY - 3), (-1, HY - 4), (0, HY - 4)):   # hocico chato y hoja nasal
    z = M.front(x, y, 40, -10)
    if z is not None: M.put(x, y, z + 1, HD, FACE_D)
for x in (-1, 0):
    z = M.front(x, HY - 2, 40, -10)
    if z is not None: M.put(x, HY - 2, z + 1, HD, FACE_D)
for x in range(-3, 3):                                                  # boca ancha
    z = M.front(x, HY - 6, 40, -10)
    if z is not None: M.V[(x, HY - 6, z)] = [HD, MOUTH, 0]
for x in (-3, 2):                                                       # comisuras hacia abajo
    z = M.front(x, HY - 7, 40, -10)
    if z is not None: M.V[(x, HY - 7, z)] = [HD, MOUTH, 0]
for x in (-2, 1):                                                       # colmillos largos
    z = M.front(x, HY - 6, 40, -10)
    for k in range(4): M.put(x, HY - 5 - k, z + 1, HD, FANG)     # cuelgan sobre el labio, separados
for s in (-1, 1):                                                       # orejas de murciélago grandes
    for k in range(13):
        w = int(round(4.5 * math.sin(math.pi * (k + 1) / 14) + 0.5))
        for j in range(w):
            x = s * (5 + j + k // 3)
            y = HY + k
            col = SKIN_D if j == 0 or j == w - 1 or k > 10 else EAR_IN
            M.put(x, y, HZ - 3, HD, col); M.put(x, y, HZ - 4, HD, SKIN_D)
    # cuernos: de la frente hacia atrás y arriba, se curvan y acaban en punta fina
    pts = []
    for i in range(70):
        t = i / 69
        a = t * 2.0
        pts.append((s * (3 + 4 * t), HY + 5 + 15 * math.sin(a * 0.85), HZ + 2 - 13 * math.sin(a * 0.6) + 5 * t * t))
    for i, p in enumerate(pts):
        t = i / (len(pts) - 1)
        r = 2.0 * (1 - t) ** 0.8
        col = HORN_L if t > 0.78 else (HORN if (i // 6) % 2 else SKIN_D)   # anillado
        if r >= 0.7: ball(*p, r, HD, col)
        else: M.put(*p, HD, col)                                        # punta fina de un voxel

# ---------------- cola de látigo con punta de flecha ----------------
for k in range(40):
    t = k / 39
    x = math.sin(t * 4.0) * 4
    ball(x, 26 - k * 0.55, -5 - k * 0.95, 1.6 * (1 - t) + 0.6, TL, SKIN_D)
tx, ty, tz = math.sin(4.0) * 4, 26 - 39 * 0.55, -5 - 39 * 0.95
for j in range(-4, 5):
    for i in range(0, 6 - abs(j)):
        M.put(tx + j, ty, tz - 1 - i, TL, SKIN_D)
        M.put(tx + j, ty + 1, tz - 1 - i, TL, SKIN_D)

# ---------------- alas de murciélago ----------------
def wing(s, W):
    """Ala en el plano de la espalda (u hacia fuera, v hacia arriba desde el hombro)."""
    SH = (s * 8, 43, -4)
    ELB, WRS = (14, 14), (27, 20)
    TIPS = [(62, 26), (58, 4), (48, -14), (34, -26)]
    ANKLE = (4, -34)
    def P(u, v): return (SH[0] + s * u, SH[1] + v, SH[2] - u * 0.18)
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
                if M.hsh(int(u) * 5 + s, int(v), 7) < 0.02: continue   # desgarrones
                near = min(l2, l3)                                    # cerca de un hueso: más oscuro
                col = MEMB_D if near < 0.08 else (MEMB if near < 0.22 else MEMB_L)
                M.put(*P(u, v), W, col, over=False)
    for i in range(len(TIPS) - 1): tri(WRS, TIPS[i], TIPS[i + 1], True)
    tri(WRS, TIPS[-1], ANKLE, True)
    tri((0, 0), WRS, ANKLE, False)
    tri((0, 0), ELB, WRS, False)
    def bone(a, b, col, r=0.6):
        n = int(math.dist(a, b) * 2) + 1
        for q in range(n + 1):
            t = q / n
            u, v = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            x, y, z = P(u, v)
            M.put(x, y, z + 1, W, col)
            if r > 0.9: M.put(x, y + 1, z + 1, W, col); M.put(x, y, z, W, col)
    for i in range(len(TIPS) - 1):                                    # venas
        m = ((TIPS[i][0] + TIPS[i + 1][0]) / 2, (TIPS[i][1] + TIPS[i + 1][1]) / 2)
        bone((WRS[0] + 3, WRS[1] - 2), (WRS[0] + (m[0] - WRS[0]) * 0.8, WRS[1] + (m[1] - WRS[1]) * 0.8), VEIN, 0.5)
    bone((0, 0), ELB, BONE, 1.2); bone(ELB, WRS, BONE, 1.2)              # húmero y antebrazo
    for t_ in TIPS:                                                   # dedos con nudillos
        bone(WRS, t_, BONE, 0.6)
        for f in (0.35, 0.68):
            x, y, z = P(WRS[0] + (t_[0] - WRS[0]) * f, WRS[1] + (t_[1] - WRS[1]) * f)
            M.put(x, y, z + 1, W, SKIN_D); M.put(x, y + 1, z + 1, W, SKIN_D)
        bone(t_, (t_[0] + 2, t_[1] - 2), CLAW, 0.5)
    bone(WRS, (WRS[0] - 1, WRS[1] + 6), BONE, 1.2)                     # pulgar con garra
    bone((WRS[0] - 1, WRS[1] + 6), (WRS[0] - 4, WRS[1] + 8), CLAW, 0.5)


wing(-1, WL); wing(1, WR)

# ---------------- tono de la piel ----------------
for (x, y, z), v in list(M.V.items()):
    if v[1] == SKIN:
        v[1] = lerp(SKIN_D, SKIN_L, 0.35 + 0.45 * M.noise(x, y, z, 6.0) + (0.1 if z > 2 else -0.1))
    elif v[1] == FACE and M.noise(x, y, z, 4.0) > 0.65:
        v[1] = FACE_D

piv = {B: [0, 0, 0], HD: [0, 46, 2], WL: [-8, 43, -4], WR: [8, 43, -4], TL: [0, 26, -5]}
n = M.export('models/diablo.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.6, specular=0.35,
             parents={HD: B, WL: B, WR: B, TL: B})
print('diablo', n, 'voxels')
