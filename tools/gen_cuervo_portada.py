"""Cuervo de la portada (17-10-2026, segunda versión): un cuervo grande de verdad para verlo de
cerca sobre la calavera del escritorio, siguiendo las referencias de FLUX en local
(tools/local/ref_cuervo_100*.png): plumas en escamas superpuestas, negro con reflejos azules y
violetas (gorguera, hombros y coberteras), pico negro azulado brillante con la cresta clara,
ojos de iris ámbar que brillan, patas largas negras y escamosas con uñas.
Se modela en centímetros (un cuervo mide ~64 cm de pico a cola) a K voxels por cm; mira hacia +Z.
Partes: body, head, jaw (mandíbula inferior, para graznar), tail, leg_l y leg_r (tarso y dedos,
giran en el talón), el ala abierta en cuatro piezas encadenadas (arm_*, fore_*, hand_* y tip_*:
hombro, codo, muñeca y punta; rehecha el 28-10-2026, pluma a pluma) y fold_l y fold_r (alas
plegadas, posado; se muestran unas u otras). Las abiertas van en horizontal (largo en X, borde de
ataque hacia +Z); las anima scripts/title/title_raven.gd.
Uso: python tools/gen_cuervo_portada.py  ->  models/cuervo_portada.json
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model

K = 1.5                           # voxels por centímetro (150 voxels/m)
TILT = 0.5                        # inclinación del cuerpo posado (rad; +: cola abajo)

BLACK = (0.030, 0.034, 0.055)
DARK = (0.060, 0.070, 0.110)
EDGE = (0.015, 0.015, 0.025)      # sombra bajo el borde de cada pluma
BLUE = (0.16, 0.27, 0.62)         # reflejos iridiscentes
VIOLET = (0.34, 0.22, 0.58)
BEAK = (0.07, 0.075, 0.10)
CULMEN = (0.30, 0.32, 0.40)       # cresta del pico, brillante
LEG = (0.07, 0.07, 0.08)
SCUTE = (0.16, 0.16, 0.19)        # escamas de la pata
CLAW = (0.28, 0.27, 0.29)
IRIS = (0.95, 0.62, 0.14)
PUPIL = (0.01, 0.01, 0.01)
GLINT = (1.0, 0.97, 0.9)

M = Model(S=K * 100 / 16, seed=1845)


def vox(cm):
    return int(math.floor(cm * K))


def fill(part, box, inside, col):
    """Recorre los voxels de `box` (cm: x0, x1, y0, y1, z0, z1) y pone los que cumplen
    `inside(x, y, z)` (en cm, centro del voxel) con el color `col(x, y, z, i, j, k)`."""
    x0, x1, y0, y1, z0, z1 = box
    for i in range(vox(x0) - 1, vox(x1) + 2):
        for j in range(vox(y0) - 1, vox(y1) + 2):
            for k in range(vox(z0) - 1, vox(z1) + 2):
                x, y, z = (i + .5) / K, (j + .5) / K, (k + .5) / K
                if inside(x, y, z):
                    M.put(i, j, k, part, col(x, y, z, i, j, k) if callable(col) else col)


def ell(c, r, rot_x=0.0):
    ca, sa = math.cos(rot_x), math.sin(rot_x)
    def f(x, y, z):
        dx, dy, dz = x - c[0], y - c[1], z - c[2]
        ly = dy * ca - dz * sa
        lz = dy * sa + dz * ca
        return (dx / r[0]) ** 2 + (ly / r[1]) ** 2 + (lz / r[2]) ** 2 <= 1
    return f


def feathers(sheen=0.0, size=2.4, tint=BLUE):
    """Plumas en escamas que bajan hacia atrás: cada una con su borde de abajo en sombra y el de
    arriba con reflejo. `sheen` (0..1): cuánto reflejo iridiscente lleva la zona."""
    def col(x, y, z, i, j, k):
        u = (y * 0.85 - z * 0.45) / size              # filas que bajan hacia la cola
        row = math.floor(u)
        v = (x + z * 0.3 + (row % 2) * size * 0.5) / size
        fu, fv = u - row, v - math.floor(v)
        h = M.hsh(i // 2, j // 2, k // 2)
        if fu < 0.18: return EDGE
        if fu > 0.72 and 0.15 < fv < 0.85 and h < sheen:
            return tint if h < sheen * 0.6 else VIOLET
        if fu > 0.72: return DARK
        return BLACK if h > 0.25 else DARK
    return col


# --- patas: tarso escamoso, dedos (tres delante y uno detrás) y uñas -------------------------
for s in (-1, 1):
    lx = 2.4 * s
    LEGP = 'leg_l' if s < 0 else 'leg_r'
    for j in range(0, vox(9.0)):                         # tarso: 2 x 2 voxels, escamas por delante
        for di in (0, 1):
            for dk in (0, 1):
                M.put(vox(lx) - di, j, -dk, LEGP, SCUTE if j % 3 == 0 and dk == 0 else LEG)
    for dx, dz, L in ((0, 1, 4.6), (0.55, 1, 4.0), (-0.55, 1, 4.0), (0, -1, 2.6)):
        for t in range(int(L * K) + 1):
            tz = dz * (0.6 + t / K)
            tx = lx + dx * s * t / K * 0.7 * (1 if dz > 0 else 0)
            M.put(vox(tx), 0, vox(tz), LEGP, SCUTE if t % 2 == 0 else LEG)
        tip_z = dz * (0.6 + L + 0.6)
        tip_x = lx + dx * s * L * 0.7 * (1 if dz > 0 else 0)
        M.put(vox(tip_x), -1, vox(tip_z), LEGP, CLAW)
    # muslo emplumado ("pantalón")
    fill('body', (lx - 2.2, lx + 2.2, 7, 13, -2.5, 2.5), ell((lx * 0.9, 10.5, 0), (2.0, 3.2, 2.4)), feathers(0.1, 1.8))

# --- cuerpo: inclinado, el pecho alto y el lomo bajando hacia la cola ------------------------
fill('body', (-8, 8, 8, 28, -16, 12), ell((0, 17.5, -1.5), (6.4, 7.0, 12.0), rot_x=TILT), feathers(0.35))
fill('body', (-6, 6, 15, 30, 0, 13), ell((0, 22.5, 6.0), (5.2, 6.2, 5.2)), feathers(0.55, 2.0, VIOLET))
# gorguera: plumas largas y sueltas de la garganta, que cuelgan en puntas
for i in range(vox(-3.6), vox(3.6) + 1):
    for k in range(vox(8.0), vox(12.5) + 1):
        h = M.hsh(i, 5, k)
        top = 28.5 - (k / K - 8.0) * 0.6
        L = 3.0 + 3.0 * h
        for j in range(vox(top - L), vox(top) + 1):
            x, z = (i + .5) / K, (k + .5) / K
            if (x / 3.8) ** 2 + ((z - 10.2) / 2.6) ** 2 > 1: continue
            c = (BLUE if h > 0.9 else VIOLET) if (j - vox(top - L)) > L * K * 0.7 and h > 0.82 else (DARK if h > 0.5 else BLACK)
            M.put(i, j, k + (1 if h > 0.7 else 0), 'body', c)
# cola en cuña: plumas largas con el raquis marcado, que se abren hacia la punta
for k in range(vox(-27), vox(-11) + 1):
    z = (k + .5) / K
    t = (-11 - z) / 16.0
    yc = 12.5 - t * 9.5
    hw = 3.6 + 2.6 * t
    if t > 0.85: hw -= (t - 0.85) / 0.15 * 3.4                 # punta en cuña
    for i in range(vox(-hw), vox(hw) + 1):
        x = (i + .5) / K
        for j in range(vox(yc - 0.9), vox(yc + 0.9) + 1):
            rach = abs(math.fmod(x + 30, 1.8) - 0.9) < 0.3
            c = DARK if rach else (BLUE if M.hsh(i, j, k) < 0.08 and j >= vox(yc) else BLACK)
            M.put(i, j, k, 'tail', c)

# --- cabeza -------------------------------------------------------------------------------
fill('head', (-6, 6, 25, 37, 3, 15), ell((0, 31.0, 9.0), (4.5, 4.7, 5.6)), feathers(0.45, 1.6))
fill('head', (-6, 6, 26, 37, 9, 15), ell((0, 31.6, 11.8), (3.6, 3.4, 2.6)), feathers(0.3, 1.4))   # frente
# pico: grueso en la base, alto y curvo; la cresta (culmen) brilla y la punta se curva abajo
for k in range(vox(13.2), vox(22.5) + 1):
    z = (k + .5) / K
    t = (z - 13.2) / 9.3
    top = 33.0 - 1.6 * t - 2.2 * t ** 3
    bot = 30.2 + 0.2 * t
    hw = 1.5 * (1 - t) + 0.35
    for i in range(vox(-hw), vox(hw) + 1):
        x = (i + .5) / K
        for j in range(vox(bot), vox(top) + 1):
            c = CULMEN if j == vox(top) and abs(x) < 0.7 else BEAK
            if j == vox(top) - 1 and abs(x) < 0.5 and t < 0.7: c = (0.18, 0.19, 0.24)
            M.put(i, j, k, 'head', c)
# cerdas nasales que tapan la base del pico
for i in range(vox(-1.6), vox(1.6) + 1):
    for k in range(vox(12.6), vox(15.5) + 1):
        M.put(i, vox(33.4), k, 'head', DARK if (i + k) % 2 else BLACK)
# mandíbula inferior
for k in range(vox(13.2), vox(20.8) + 1):
    t = ((k + .5) / K - 13.2) / 7.6
    hw = 1.3 * (1 - t) + 0.3
    for i in range(vox(-hw), vox(hw) + 1):
        for j in (vox(29.4), vox(30.0)):
            M.put(i, j, k, 'jaw', BEAK if j == vox(30.0) else DARK)
# ojos: iris ámbar que brilla, pupila y un destello, sobre la superficie a cada lado
for s in (-1, 1):
    jc, kc = vox(32.0), vox(11.4)
    xs = [i for i in range(vox(-7), vox(7) + 1) if M.has((i, jc, kc)) and M.V[(i, jc, kc)][0] == 'head']
    xi = (max(xs) if s > 0 else min(xs)) if xs else vox(4.3 * s)
    for dj in (-1, 0, 1):
        for dk in (-1, 0, 1):
            ring = abs(dj) + abs(dk) > 0
            M.put(xi, jc + dj, kc + dk, 'head', IRIS if ring else PUPIL, glow=1 if ring else 0)
    M.put(xi, jc + 1, kc + 1, 'head', GLINT, glow=1)
    for dk in (-2, 2):                                   # párpado oscuro
        M.put(xi, jc, kc + dk, 'head', EDGE)


# --- alas ---------------------------------------------------------------------------------
# Ala abierta pluma a pluma, en cuatro piezas que se doblan al aletear y al plegarla: brazo
# (hombro a codo, terciarias), antebrazo (codo a muñeca, secundarias), mano (primarias por dentro)
# y punta (las primarias largas, que se curvan con el aire). Va en horizontal (largo en X, borde
# de ataque hacia +Z); las anima scripts/title/title_raven.gd.
ELBOW = 8.0                       # cm del hombro al codo
WRIST = 19.0                      # ... a la muñeca
TIP = 31.0                        # ... a donde se doblan las primarias largas
WY = 24.0                         # altura del ala (cm)
UNDER = (0.085, 0.088, 0.105)     # cara de abajo de las remeras, gris negruzco con brillo
RACHIS_U = (0.15, 0.15, 0.17)     # raquis por debajo, más claro


def lead(d):
    """Borde de ataque (z, cm) a `d` cm del hombro: se abulta hacia la muñeca (el álula) y la
    mano se curva hacia atrás."""
    if d < WRIST:
        return 5.5 + 1.8 * math.sin(d / WRIST * math.pi * 0.5)
    h = (d - WRIST) / 26.0
    return 7.3 - 9.0 * h ** 1.5


def wing_part(s, d):
    names = ('arm', 'fore', 'hand', 'tip')
    i = 0 if d < ELBOW else 1 if d < WRIST else 2 if d < TIP else 3
    return names[i] + ('_l' if s < 0 else '_r')


def feather(s, root_d, root_z, ang, length, width, finger, tone, layer):
    """Una remera: de (root_d, root_z) hacia atrás girada `ang` rad hacia fuera, con el raquis y
    el borde de fuera en sombra (lo tapa la siguiente). `finger`: desde qué fracción del largo
    se estrecha en dedo (primarias emarginadas). `layer`: altura sobre las de debajo."""
    ca, sa = math.cos(ang), math.sin(ang)
    st = 0.5 / K
    u = 0.0
    while u <= length:
        t = u / length
        w = width * (1.0 if t < finger else 1.0 - 0.45 * min(1.0, (t - finger) / 0.12))
        if t > 0.82: w *= math.sqrt(max(0.0, 1 - ((t - 0.82) / 0.18) ** 2))      # punta redondeada
        v = -w * 0.5
        while v <= w * 0.5:
            d = root_d + u * sa + v * ca
            z = root_z - u * ca + v * sa
            c_t = min(1.0, max(0.0, (lead(d) - z) / 18.0))
            camber = 1.1 * math.sin(c_t * math.pi) * (1 - 0.6 * min(1.0, d / 46.0))
            y = WY + camber + layer / K
            if abs(v) < 0.35 / K * 1.2 and t < 0.9: c, cu = DARK, RACHIS_U          # raquis
            elif v > w * 0.5 - 0.7 / K: c, cu = EDGE, EDGE                          # la siguiente la tapa
            else:
                g = tone * (0.9 + 0.2 * M.hsh(vox(s * (6.0 + d)) // 2, 7, vox(z) // 3))   # vetas
                c = tuple(min(1.0, q * g) for q in BLACK)
                cu = tuple(min(1.0, q * (0.75 + 0.5 * t) * g) for q in UNDER)        # más clara hacia la punta
            xi, yi, zi = vox(s * (6.0 + d)), vox(y), vox(z)
            part = wing_part(s, d)
            M.put(xi, yi, zi, part, c)
            M.put(xi, yi - 1, zi, part, cu, over=False)                            # grosor y cara de abajo
            v += st
        u += st


def spread(s):
    """Ala abierta de cuervo: ancha, con el borde de salida de las secundarias festoneado y las
    primarias abiertas en abanico, las de fuera estrechadas en dedos sueltos."""
    # secundarias y terciarias: hacia atrás, un poco abiertas hacia fuera las de fuera
    n = 12
    for f in range(n):
        d = 0.8 + f * (WRIST - 0.8) / (n - 1)
        L = 13.5 + 1.8 * math.sin(f / (n - 1) * math.pi * 0.8)
        feather(s, d, lead(d) - 3.0, 0.03 + 0.12 * f / (n - 1), L, 2.5, 2.0, 0.85 + 0.35 * M.hsh(f, 1, s + 3), 0)
    # primarias: en abanico desde la mano, de hacia atrás a casi hacia fuera
    lengths = (16.5, 18.0, 19.5, 21.5, 23.5, 25.5, 26.5, 26.0, 23.0, 16.0)
    for f in range(10):
        q = f / 9
        d = WRIST + 0.5 + q * 10.5
        ang = 0.22 + 1.05 * q ** 1.2
        finger = 0.5 if 4 <= f <= 8 else 2.0
        feather(s, d, lead(d) - 2.5, ang, lengths[f], 2.6 if f < 9 else 2.0, finger,
                0.85 + 0.35 * M.hsh(f, 2, s + 3), 1 if f % 2 else 0)
    # coberteras: cubren el borde de ataque y la base de las remeras, en tres filas festoneadas
    for ii in range(vox(46.0)):
        d = ii / K
        if d > 40: break
        ld = lead(d)
        depth = (6.5 if d < WRIST else 6.5 - 4.5 * (d - WRIST) / 21.0)
        if depth <= 0.5: continue
        for kk in range(vox(ld - depth), vox(ld) + 1):
            z = (kk + .5) / K
            c_t = (ld - z) / depth                         # 0 borde de ataque .. 1 final de las coberteras
            row = 0 if c_t < 0.38 else 1 if c_t < 0.7 else 2
            ends = (0.38, 0.7, 1.0)
            wav = 0.06 * math.sin(((d * 1.3 + row * 0.6) % 1.7) / 1.7 * math.pi)
            if ends[row] - c_t < 0.07 + wav: c = EDGE
            else:
                h = M.hsh(ii // 2, row, kk // 2)
                c = DARK if h < 0.22 else (BLUE if h > 0.97 else BLACK)
            camber = 1.1 * math.sin(min(1.0, (ld - z) / 18.0) * math.pi) * (1 - 0.6 * min(1.0, d / 46.0))
            y0 = vox(WY + camber) + 3 - row                   # cada fila, un escalón por encima de la siguiente
            if row < 2 and ends[row] - c_t < 0.1 + wav: y0 -= 1     # el borde de la fila baja: se nota el festón
            th = y0 - vox(WY + camber) + 1
            part = wing_part(s, d)
            xi = vox(s * (6.0 + d))
            for q in range(th + 1):
                M.put(xi, y0 - q, kk, part, c if q == 0 else (BLACK if q < th else UNDER))


def folded(part, s):
    """Ala plegada contra el costado: coberteras arriba (escamas con reflejo), secundarias
    escalonadas y las primarias largas que cruzan sobre la cola."""
    for kk in range(vox(-25), vox(6) + 1):
        z = (kk + .5) / K
        t = (6 - z) / 31.0
        top = 25.0 - 13.5 * t
        h = 11.0 - 7.5 * t
        bx = 6.6 - 2.6 * t
        for jj in range(vox(top - h), vox(top) + 1):
            y = (jj + .5) / K
            depth = (top - y) / h
            if depth < 0.42 and t < 0.55:            # coberteras
                u = (top - y) / 1.8 + z * 0.12
                fu = u - math.floor(u)
                c = EDGE if fu < 0.2 else (BLUE if fu > 0.68 and M.hsh(jj, kk, 1) < 0.55 else (VIOLET if fu > 0.68 and M.hsh(jj, kk, 2) < 0.25 else BLACK))
            else:                                     # remeras: bandas diagonales
                u = (z * 0.55 + y) / 2.2
                fu = u - math.floor(u)
                c = EDGE if fu < 0.15 else (DARK if fu > 0.8 else BLACK)
            xi = vox(s * bx)
            M.put(xi, jj, kk, part, c)
            if t < 0.6: M.put(xi - s, jj, kk, part, BLACK)


spread(-1)
spread(1)
folded('fold_l', -1)
folded('fold_r', 1)

# brillo azulado del plumaje: las plumas que miran arriba (o adelante, en el pecho) recogen la luz
# fría; mezcla con azul más fuerte en la cabeza, la gorguera y los hombros
SHINE = (0.20, 0.32, 0.70)
for (x, y, z), v in list(M.V.items()):
    part, c, g = v
    if g or part not in ('body', 'head', 'tail', 'fold_l', 'fold_r') or c in (EDGE, LEG, SCUTE, CLAW, BEAK, CULMEN):
        continue
    up = (x, y + 1, z) not in M.V
    front = (x, y, z + 1) not in M.V and (part == 'head' or M.hsh(x, y, z + 7) < 0.3)
    if up or front:
        k = 0.55 if (part == 'head' or y > 21 * K) else 0.38
        if front and not up: k *= 0.5
        if M.hsh(x, y, z) < 0.35: k *= 0.5
        M.V[(x, y, z)] = [part, tuple(c[q] + (SHINE[q] - c[q]) * k for q in range(3)), g]

piv = lambda x, y, z: [x * K, y * K, z * K]
n = M.export("models/cuervo_portada.json",
             {"body": piv(0, 8, 0), "head": piv(0, 27, 7), "jaw": piv(0, 30, 13.5),
              "arm_l": piv(-6, WY, lead(0)), "arm_r": piv(6, WY, lead(0)),
              "fore_l": piv(-6 - ELBOW, WY, lead(ELBOW)), "fore_r": piv(6 + ELBOW, WY, lead(ELBOW)),
              "hand_l": piv(-6 - WRIST, WY, lead(WRIST)), "hand_r": piv(6 + WRIST, WY, lead(WRIST)),
              "tip_l": piv(-6 - TIP, WY, lead(TIP)), "tip_r": piv(6 + TIP, WY, lead(TIP)),
              "leg_l": piv(-2.4, 9, 0), "leg_r": piv(2.4, 9, 0), "tail": piv(0, 13, -10.5),
              "fold_l": piv(-6.6, 25, 5), "fold_r": piv(6.6, 25, 5)},
             pivots_in_voxels=True, roughness=0.62, specular=0.35, jitter=0.006,
             parents={"head": "body", "jaw": "head", "arm_l": "body", "arm_r": "body",
                      "fore_l": "arm_l", "fore_r": "arm_r", "hand_l": "fore_l", "hand_r": "fore_r",
                      "tip_l": "hand_l", "tip_r": "hand_r", "leg_l": "body", "leg_r": "body",
                      "tail": "body", "fold_l": "body", "fold_r": "body"})
print("cuervo_portada", n, "voxels")
