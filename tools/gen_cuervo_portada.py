"""Cuervo de la portada (17-10-2026, segunda versión): un cuervo grande de verdad para verlo de
cerca sobre la calavera del escritorio, siguiendo las referencias de FLUX en local
(tools/local/ref_cuervo_100*.png): plumas en escamas superpuestas, negro con reflejos azules y
violetas (gorguera, hombros y coberteras), pico negro azulado brillante con la cresta clara,
ojos de iris ámbar que brillan, patas largas negras y escamosas con uñas.
Se modela en centímetros (un cuervo mide ~64 cm de pico a cola) a K voxels por cm; mira hacia +Z.
Partes: body, head, jaw (mandíbula inferior, para graznar), tail, leg_l y leg_r (tarso y dedos,
giran en el talón), arm_l/hand_l y arm_r/hand_r (ala abierta articulada en la muñeca: la mano
cuelga del brazo) y fold_l y fold_r (alas plegadas, posado; se muestran unas u otras).
Las abiertas van en horizontal (largo en X, borde de ataque hacia +Z); las anima
scripts/title/title_raven.gd.
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
ARM = 19.0                        # cm del hombro a la muñeca
SPAN = 44.0                       # cm del hombro a la punta


def spread(s):
    """Ala abierta en dos piezas: brazo (hombro a muñeca, secundarias) y mano (primarias).
    Forma de ala de cuervo: borde de ataque curvo (abultado junto a la muñeca), mano ancha y
    redondeada con las primarias sueltas como dedos de punta afilada. Pluma a pluma: tres filas
    de coberteras festoneadas (pequeñas, medianas y mayores) y las remeras de una en una, cada
    una con su tono, su raquis y la sombra de la siguiente. Grosor de 3 voxels en el borde de
    ataque a 1 en las remeras, y curvatura (el centro de la cuerda más alto)."""
    arm, hand = ('arm_l', 'hand_l') if s < 0 else ('arm_r', 'hand_r')
    FW = 2.3                                           # ancho de una remera (cm)
    for ii in range(vox(SPAN) + 1):
        d = ii / K                                     # cm desde el hombro
        t = d / SPAN
        part = arm if d < ARM else hand
        x = s * (6.0 + d)
        fi = math.floor(d / FW)                        # remera a la que pertenece esta columna
        fe = d / FW - fi                               # posición dentro de la remera (0..1)
        if d < ARM:
            lead = 5.2 + 1.6 * math.sin(d / ARM * math.pi * 0.5)          # se abulta hacia la muñeca
            chord = 18.5 - 1.0 * d / ARM
            chord -= 1.1 * (1 - math.sin(fe * math.pi))                   # festón de las secundarias
        else:
            h = (d - ARM) / (SPAN - ARM)
            lead = 6.8 - 6.5 * h ** 1.6                                   # la mano se curva hacia atrás
            chord = 17.5 - 6.0 * h
            if h > 0.3:                                                   # primarias: dedos en punta
                tip = 1 - abs(fe - 0.45) / 0.45                           # 1 en el centro de la pluma
                chord = chord * (0.55 + 0.45 * max(tip, 0.0) ** 0.6) + 3.0 * (h - 0.3)
            chord *= 1 - max(0.0, h - 0.85) / 0.15 * 0.5                 # punta redondeada
        tone = 0.75 + 0.5 * M.hsh(int(fi), 3, s + 5)                      # cada remera, su tono
        for kk in range(vox(lead - chord), vox(lead) + 1):
            z = (kk + .5) / K
            c_t = (lead - z) / max(chord, 0.1)          # 0 borde de ataque .. 1 borde de salida
            # coberteras en tres filas festoneadas: cada fila acaba en curvas sobre la siguiente
            row_ends = (0.14, 0.27, 0.45)
            band = next((b for b, e in enumerate(row_ends)
                         if c_t < e - 0.04 * math.sin(((d * 1.4 + b * 0.7) % 1.6) / 1.6 * math.pi)), 3)
            if band < 3:
                end = row_ends[band] - 0.04 * math.sin(((d * 1.4 + band * 0.7) % 1.6) / 1.6 * math.pi)
                if end - c_t < 0.035: c = EDGE                            # sombra bajo el festón
                elif end - c_t < 0.07 and M.hsh(ii, band, kk) < 0.5: c = DARK if band < 2 or M.hsh(ii, 9, kk) > 0.15 else BLUE
                else: c = BLACK if (ii + kk) % 5 else DARK
            else:
                if fe < 0.12: c = EDGE                                    # la remera de al lado la tapa
                elif abs(fe - 0.4) < 0.07: c = DARK                       # raquis
                else: c = tuple(min(1.0, q * tone) for q in BLACK)
            camber = 1.0 * math.sin(min(c_t, 1.0) * math.pi) * (1 - 0.5 * t)
            y0 = vox(24.0 + camber)
            xi = int(math.floor(x * K))
            M.put(xi, y0, kk, part, c)
            th = 2 if c_t < 0.22 else (1 if c_t < 0.5 else 0)
            for q in range(1, th + 1):
                M.put(xi, y0 - q, kk, part, EDGE if q == th else BLACK)


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
    if g or part not in ('body', 'head', 'tail', 'fold_l', 'fold_r', 'arm_l', 'arm_r', 'hand_l', 'hand_r') or c in (EDGE, LEG, SCUTE, CLAW, BEAK, CULMEN):
        continue
    up = (x, y + 1, z) not in M.V
    front = (x, y, z + 1) not in M.V and (part == 'head' or M.hsh(x, y, z + 7) < 0.3)
    if up or front:
        k = 0.55 if (part == 'head' or y > 21 * K) else 0.38
        if front and not up: k *= 0.5
        if part.startswith(('arm', 'hand')): k *= 0.0
        if M.hsh(x, y, z) < 0.35: k *= 0.5
        M.V[(x, y, z)] = [part, tuple(c[q] + (SHINE[q] - c[q]) * k for q in range(3)), g]

piv = lambda x, y, z: [x * K, y * K, z * K]
n = M.export("models/cuervo_portada.json",
             {"body": piv(0, 8, 0), "head": piv(0, 27, 7), "jaw": piv(0, 30, 13.5),
              "arm_l": piv(-6, 24, 5.5), "arm_r": piv(6, 24, 5.5),
              "hand_l": piv(-6 - ARM, 24, 5.4), "hand_r": piv(6 + ARM, 24, 5.4),
              "leg_l": piv(-2.4, 9, 0), "leg_r": piv(2.4, 9, 0), "tail": piv(0, 13, -10.5),
              "fold_l": piv(-6.6, 25, 5), "fold_r": piv(6.6, 25, 5)},
             pivots_in_voxels=True, roughness=0.62, specular=0.35, jitter=0.006,
             parents={"head": "body", "jaw": "head", "arm_l": "body", "arm_r": "body",
                      "hand_l": "arm_l", "hand_r": "arm_r", "leg_l": "body", "leg_r": "body",
                      "tail": "body", "fold_l": "body", "fold_r": "body"})
print("cuervo_portada", n, "voxels")
