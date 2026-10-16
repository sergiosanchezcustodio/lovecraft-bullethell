"""La sirena de bronce de la fuente de Innsmouth (16-10-2026, encargo del autor): como la de
Copenhague, pero siniestra. Sustituye al cachalote de la fuente (inn_fuente) y es el doble de
grande: 2,2 m sentada, a 48 voxels por metro (la resolución de los personajes).

Sentada erguida en la roca de la fuente, mirando hacia abajo y de lado; la cola baja por
delante de la roca hasta el agua y abre la aleta. Rasgos de Profunda: cara demacrada con las
cuencas hundidas y oscuras y los ojos que apenas brillan en verde, agallas en el cuello, aletas
en lugar de orejas y en los antebrazos, manos palmeadas con garras, escamas que le suben por la
cintura y una cresta con espinas a lo largo de la cola. El pelo, largo y mojado como algas, cae
por la espalda y le tapa el pecho por delante. Bronce oscuro con cardenillo en lo que mira
arriba y en chorretones. Referencia: tools/local/ref_sirena_1000.png (FLUX local).

Origen: el asiento, sobre la roca de la fuente (FUENTE_ROCK_TOP en gen_atrezo_innsmouth.py);
el frente mira a +z. gen_arena_calles.py la pone encima, con `y`.
Uso: python tools/gen_sirena.py
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
S = 3                                   # voxels por ub: 48/m
VPM = 16 * S                            # voxels por metro
BRONZE = (0.26, 0.36, 0.31); BRONZE_D = (0.14, 0.19, 0.17); BRONZE_L = (0.38, 0.48, 0.40)
VERDI = (0.34, 0.56, 0.47); VERDI_L = (0.46, 0.66, 0.56)
HOLLOW = (0.05, 0.06, 0.05)             # cuencas, boca, agallas
EYE = (0.55, 0.95, 0.66)                # brillo de los ojos

M = Model(S=S, seed=1923)


def v(m):                               # metros -> voxels
    return int(round(m * VPM))


def solid(fn, bbox, tag):
    """Rellena los voxels de bbox (en m: x0, x1, y0, y1, z0, z1) donde fn(x, y, z) (en m) es
    cierto; tag queda en el color provisional (se pinta al final)."""
    x0, x1, y0, y1, z0, z1 = bbox
    for x in range(v(x0), v(x1) + 1):
        for y in range(v(y0), v(y1) + 1):
            for z in range(v(z0), v(z1) + 1):
                if fn((x + 0.5) / VPM, (y + 0.5) / VPM, (z + 0.5) / VPM):
                    M.put(x, y, z, P, tag, over=False)


def ell_at(c, r, tag, p=2.0):
    solid(lambda x, y, z: abs((x - c[0]) / r[0]) ** p + abs((y - c[1]) / r[1]) ** p + abs((z - c[2]) / r[2]) ** p <= 1,
          (c[0] - r[0], c[0] + r[0], c[1] - r[1], c[1] + r[1], c[2] - r[2], c[2] + r[2]), tag)


def tube(pts, radii, tag, steps=6):
    """Tubo por una polilínea (m), con el radio de cada punto: esferas seguidas."""
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        n = max(2, int(math.dist(a, b) * VPM / 2))
        for k in range(n + 1):
            t = k / n
            c = [a[j] + (b[j] - a[j]) * t for j in range(3)]
            r = radii[i] + (radii[i + 1] - radii[i]) * t
            ell_at(c, (r, r, r), tag)


def rot(ax, ay):
    """Matriz de giro: primero ax en X (cabeceo), luego ay en Y."""
    cx, sx, cy, sy = math.cos(ax), math.sin(ax), math.cos(ay), math.sin(ay)
    rx = ((1, 0, 0), (0, cx, -sx), (0, sx, cx))
    ry = ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy))
    return tuple(tuple(sum(ry[i][k] * rx[k][j] for k in range(3)) for j in range(3)) for i in range(3))


def apply(Rm, p):
    return tuple(sum(Rm[i][j] * p[j] for j in range(3)) for i in range(3))


def apply_t(Rm, p):                     # inversa (traspuesta)
    return tuple(sum(Rm[j][i] * p[j] for j in range(3)) for i in range(3))


# ------------------------------------------------------------------ cuerpo
ell_at((0.0, 0.25, -0.02), (0.34, 0.24, 0.28), 'scale')                 # caderas (ya con escamas)
ell_at((0.0, 0.6, -0.03), (0.21, 0.22, 0.17), 'waist')                  # cintura muy estrecha
ell_at((0.0, 0.95, 0.0), (0.3, 0.32, 0.21), 'skin', p=2.2)              # tórax, esbelto
ell_at((0.0, 1.2, -0.01), (0.36, 0.1, 0.17), 'skin', p=2.4)             # hombros caídos
for sx in (-1, 1):
    ell_at((sx * 0.36, 1.21, -0.01), (0.1, 0.1, 0.1), 'skin')             # cabeza del hombro
    for k in range(4):                                                   # clavículas marcadas (demacrada)
        ell_at((sx * (0.07 + k * 0.065), 1.25 - k * 0.006, 0.15), (0.035, 0.022, 0.026), 'bone')
for k in range(4):                                                       # costillas que se marcan en el costado
    for sx in (-1, 1):
        solid(lambda x, y, z, k=k, sx=sx: abs(y - (0.84 + k * 0.07)) < 0.012 and 0.22 < sx * x < 0.31 and -0.08 < z < 0.14
              and ((x / 0.31) ** 2 + ((y - 0.95) / 0.33) ** 2 + (z / 0.22) ** 2) < 1.08,
              (-0.35, 0.35, 0.78, 1.12, -0.12, 0.2), 'rib')
tube([(0.0, 1.24, 0.0), (0.01, 1.5, 0.04)], [0.09, 0.08], 'neck')       # cuello largo, casi erguido

# ------------------------------------------------------------------ cabeza (agachada y vuelta)
HC = (0.03, 1.74, 0.09)
HR = rot(math.radians(24), math.radians(20))                            # mira abajo y a su derecha
RX, RY, RZ = 0.17, 0.24, 0.2


def head_local(x, y, z):
    return apply_t(HR, (x - HC[0], y - HC[1], z - HC[2]))


def in_head(x, y, z):
    lx, ly, lz = head_local(x, y, z)
    nx, ny, nz = lx / RX, ly / RY, lz / RZ
    k = 1.0 - 0.32 * max(0.0, -ny) ** 1.5                                # barbilla estrecha (cara alargada)
    if (nx / k) ** 2 + ny ** 2 + (nz / (0.9 + 0.1 * k)) ** 2 <= 1: return True
    if abs(nx) < 0.1 and -0.25 < ny < 0.2 and 0.9 < nz < 1.06: return True                # caballete de la nariz
    if abs(nx) > 0.35 and abs(nx) < 0.62 and -0.05 < ny < 0.12 and nz > 0.62 and nz < 0.9: return True   # pómulos
    return False


solid(in_head, (HC[0] - 0.35, HC[0] + 0.35, HC[1] - 0.35, HC[1] + 0.35, HC[2] - 0.35, HC[2] + 0.35), 'head')
for sx in (-1, 1):                                                       # aletas en vez de orejas
    for k in range(7):
        base = apply(HR, (sx * RX * 0.95, 0.02 - k * 0.03, -0.02 - k * 0.01))
        tip = apply(HR, (sx * (RX + 0.11 - k * 0.008), 0.09 - k * 0.04, -0.12 - k * 0.015))
        tube([(HC[0] + base[0], HC[1] + base[1], HC[2] + base[2]), (HC[0] + tip[0], HC[1] + tip[1], HC[2] + tip[2])],
             [0.018, 0.008], 'fin')

# ------------------------------------------------------------------ brazos y manos
def arm(sx, sh, el, wr, hand_dir, palm_down):
    tube([sh, el], [0.07, 0.058], 'skin')
    tube([el, wr], [0.056, 0.04], 'skin')
    d = [wr[i] - el[i] for i in range(3)]
    L = math.sqrt(sum(q * q for q in d))
    for k in range(9):                                                   # aleta del antebrazo: espinas
        t = 0.15 + k * 0.08
        c = [el[i] + d[i] * t for i in range(3)]
        out = (sx * 0.05, 0.02, -0.04)
        tip = (c[0] + out[0] * (1.6 - k * 0.12), c[1] + out[1], c[2] + out[2] * (1.6 - k * 0.12))
        tube([tuple(c), tip], [0.016, 0.006], 'fin')
    # mano palmeada: dorso, cuatro dedos largos con garra, pulgar y la membrana entre ellos
    hd = hand_dir
    palm = (wr[0] + hd[0] * 0.08, wr[1] + hd[1] * 0.08, wr[2] + hd[2] * 0.08)
    ell_at(palm, (0.055, 0.028 if palm_down else 0.05, 0.06), 'skin')
    side = (hd[2], 0.0, -hd[0])                                          # a lo ancho de la mano
    tips = []
    for f in range(4):
        o = (f - 1.5) * 0.03
        a = (palm[0] + side[0] * o, palm[1], palm[2] + side[2] * o)
        spread = (f - 1.5) * 0.25
        dirf = (hd[0] + side[0] * spread, hd[1] - 0.25, hd[2] + side[2] * spread)
        n = math.sqrt(sum(q * q for q in dirf))
        dirf = tuple(q / n for q in dirf)
        b = tuple(a[i] + dirf[i] * 0.15 for i in range(3))
        c = tuple(b[i] + dirf[i] * 0.06 + (0, -0.03, 0)[i] for i in range(3))
        tube([a, b], [0.016, 0.012], 'skin')
        tube([b, c], [0.011, 0.004], 'claw')
        tips.append(b)
    for f in range(3):                                                   # membrana entre los dedos
        a, b = tips[f], tips[f + 1]
        for t in [i / 6 for i in range(7)]:
            p0 = tuple(palm[i] + (a[i] + (b[i] - a[i]) * t - palm[i]) * 0.85 for i in range(3))
            ell_at(p0, (0.012, 0.012, 0.012), 'web')
    th = (palm[0] - side[0] * 0.07 + hd[0] * 0.02, palm[1] + 0.01, palm[2] - side[2] * 0.07 + hd[2] * 0.02)
    tube([th, (th[0] - side[0] * 0.04 + hd[0] * 0.08, th[1] - 0.03, th[2] - side[2] * 0.04 + hd[2] * 0.08)], [0.02, 0.008], 'claw')


# su izquierda (x negativa): el brazo baja estirado y la mano se apoya en la roca, a su lado
arm(-1, (-0.36, 1.2, -0.02), (-0.46, 0.74, -0.1), (-0.5, 0.22, -0.02), (0.0, -0.45, 0.9), True)
# su derecha: el brazo doblado y la mano descansa sobre la cola
arm(1, (0.36, 1.2, 0.0), (0.5, 0.78, 0.12), (0.38, 0.4, 0.42), (-0.2, -0.5, 0.85), True)

# ------------------------------------------------------------------ la cola
# baja en diagonal por delante y a su derecha, rodeando la roca (sin meterse en ella)
TAIL = [(0.0, 0.2, 0.05), (0.12, 0.12, 0.4), (0.28, 0.03, 0.66), (0.42, -0.2, 0.84), (0.5, -0.45, 0.92), (0.52, -0.6, 0.95)]
TR = [0.3, 0.24, 0.18, 0.13, 0.09, 0.055]
tube(TAIL, TR, 'scale')
for i in range(len(TAIL) - 1):                                           # cresta con espinas a lo largo del lomo
    a, b = TAIL[i], TAIL[i + 1]
    for k in range(6):
        t = k / 6
        c = [a[j] + (b[j] - a[j]) * t for j in range(3)]
        r = TR[i] + (TR[i + 1] - TR[i]) * t
        up = (0.0, 1.0, -0.15) if i < 2 else (0.0, 0.55, -0.85)        # arriba y, al caer, hacia atrás
        tip = (c[0] + up[0] * (r + 0.09), c[1] + up[1] * (r + 0.09), c[2] + up[2] * (r + 0.09))
        tube([tuple(c), tip], [0.02, 0.006], 'fin')
end, prev = TAIL[-1], TAIL[-2]                                           # aleta caudal abierta, sobre el agua
for sx in (-1, 1):
    for k in range(10):
        a = math.radians(-30 + k * 7)
        tip = (end[0] + sx * 0.5 * math.cos(a), end[1] - 0.03 + 0.12 * math.sin(a), end[2] + 0.18 + 0.12 * math.sin(a) * sx * 0.3)
        tube([end, tip], [0.035, 0.012], 'fluke')

# ------------------------------------------------------------------ pelo: largo y mojado, como algas
def strand(start, path, r0, wave):
    pts = [start]
    for i, d in enumerate(path):
        q = pts[-1]
        w = wave * math.sin(i * 1.7 + start[0] * 9)
        pts.append((q[0] + d[0] + w, q[1] + d[1], q[2] + d[2]))
    tube(pts, [r0 * (1 - 0.6 * i / len(pts)) for i in range(len(pts))], 'hair')


for k in range(15):                                                      # por la espalda, hasta la cintura
    a = math.radians(-80 + k * 160 / 14)
    loc = (RX * 0.9 * math.sin(a), RY * 0.55, -RZ * 0.7 * math.cos(a) * 0.9)
    s0 = apply(HR, loc)
    s0 = (HC[0] + s0[0], HC[1] + s0[1], HC[2] + s0[2])
    strand(s0, [(math.sin(a) * 0.05, -0.12, -0.08)] + [(math.sin(a) * 0.03, -0.14, -0.02)] * 6, 0.05, 0.012)
for sx in (-1, 1):                                                       # por delante: le tapan el pecho
    for k in range(5):
        loc = (sx * RX * (0.75 + k * 0.05), RY * 0.35 - k * 0.03, RZ * (0.2 - k * 0.12))
        s0 = apply(HR, loc)
        s0 = (HC[0] + s0[0], HC[1] + s0[1], HC[2] + s0[2])
        strand(s0, [(sx * 0.03, -0.12, 0.05), (sx * 0.01, -0.14, 0.05), (-sx * 0.01, -0.15, 0.03),
                    (-sx * 0.015, -0.15, 0.015), (-sx * 0.01, -0.14, 0.0), (0.0, -0.1, 0.0)], 0.04, 0.008)
ell_at((HC[0], HC[1] + 0.1, HC[2] - 0.07), (0.18, 0.16, 0.18), 'hair')  # mata de pelo sobre el cráneo

# ------------------------------------------------------------------ pintura
def face_paint(x, y, z):
    """Rasgos pintados sobre la cara (en coordenadas de la cabeza)."""
    lx, ly, lz = head_local(x, y, z)
    nx, ny, nz = lx / RX, ly / RY, lz / RZ
    if nz < 0.5: return None
    for sx in (-1, 1):
        ex, ey = sx * 0.38, 0.12
        dd = math.hypot((nx - ex) / 1.1, ny - ey)
        if dd < 0.07: return 'eye'
        if dd < 0.2: return 'hollow'                                     # cuencas hundidas y oscuras
        if dd < 0.27 and ny > ey: return 'brow'
    if abs(ny + 0.5) < 0.035 and abs(nx) < 0.42: return 'hollow'        # boca ancha y fina
    if abs(ny + 0.47) < 0.06 and 0.36 < abs(nx) < 0.46: return 'hollow'  # comisuras que caen
    if 0.42 < abs(nx) < 0.6 and -0.35 < ny < -0.05: return 'cheek'       # mejillas chupadas
    return None


def color(k, part, tag):
    x, y, z = k
    mx, my, mz = (x + 0.5) / VPM, (y + 0.5) / VPM, (z + 0.5) / VPM
    c = lerp(BRONZE, BRONZE_D, 0.45 * M.noise(x, y, z, 9.0))
    if tag == 'head':
        f = face_paint(mx, my, mz)
        if f == 'eye': return EYE
        if f == 'hollow': return HOLLOW
        if f == 'brow': c = lerp(c, BRONZE_D, 0.5)
        if f == 'cheek': c = lerp(c, BRONZE_D, 0.6)
        lx, ly, lz = head_local(mx, my, mz)
        for sx in (-1, 1):                                               # agallas detrás de la mandíbula
            if sx * lx / RX > 0.55 and -0.75 < ly / RY < -0.35 and int((ly / RY + 0.75) * 30) % 4 == 0 and lz / RZ < 0.2: return HOLLOW
    if tag == 'neck':
        side = abs(mx) / 0.11
        if side > 0.7 and int(my * VPM) % 5 == 0 and mz < 0.09: return HOLLOW            # agallas del cuello
    if tag == 'scale' or (tag == 'waist' and my < 0.62 + 0.06 * math.sin(mx * 30)):    # escamas
        u = mx * 14 + mz * 9
        w = my * 18 + (0.5 if int(u) % 2 else 0)
        f = (u - math.floor(u)) ** 2 + (w - math.floor(w) - 0.5) ** 2
        c = lerp(BRONZE_L, BRONZE_D, min(1.0, f * 2.2))                 # cada escama con su borde oscuro
    if tag == 'rib' or tag == 'bone': c = lerp(c, BRONZE_L, 0.5)
    if tag == 'hair': c = lerp(BRONZE_D, BRONZE, 0.4 + 0.4 * M.noise(x, y * 0.3, z, 3.0))
    if tag in ('fin', 'fluke', 'web'): c = lerp(BRONZE_D, BRONZE, 0.3 + 0.3 * M.noise(x, y, z, 2.0))
    if tag == 'claw': c = (0.10, 0.11, 0.10)
    if tag == 'fluke' and int((x - z) / 2) % 3 == 0: c = lerp(c, BRONZE_D, 0.6)          # radios de la aleta
    # cardenillo: en lo que mira arriba y en chorretones que bajan
    top = (x, y + 1, z) not in M.V
    streak = M.noise(x, y * 0.12, z, 5.0)
    if top: c = lerp(c, VERDI if M.noise(x, y, z, 4.0) > 0.4 else VERDI_L, 0.55)
    elif streak > 0.62: c = lerp(c, VERDI, 0.45 * (streak - 0.62) / 0.38 + 0.2)
    return c


M.paint(lambda k, part, tag: color(k, part, tag) if isinstance(tag, str) else None)
for k, val in M.V.items():                                               # brillo de los ojos
    if val[1] == EYE: val[2] = 1
nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]:
    del M.V[k]                                                           # hueca: solo lo que se ve

# el chorro que le sale de la boca (Ambient, data/ambient.json: emit "spout" en "mouth" con su
# dirección y "spout_splash" donde cae; 16-10-2026): la boca, hacia dónde mira y el punto del agua
# del pilón (0,5 m sobre el suelo; el origen del modelo está en lo alto de la roca, a 1,125 m)
SPOUT_V = 2.2                                                           # m/s
mouth = apply(HR, (0.0, -0.5 * RY, RZ * 0.98))
MOUTH = (HC[0] + mouth[0], HC[1] + mouth[1], HC[2] + mouth[2])
d = apply(HR, (-0.25, 0.32, 1.0))                                      # en arco, por encima de la cola
n_ = math.sqrt(sum(q * q for q in d))
SPOUT_DIR = tuple(q / n_ for q in d)
WATER_Y = 0.5 - 1.125
a_, b_, c_ = -4.9, SPOUT_V * SPOUT_DIR[1], MOUTH[1] - WATER_Y
T_LAND = (-b_ - math.sqrt(b_ * b_ - 4 * a_ * c_)) / (2 * a_)
SPLASH = (MOUTH[0] + SPOUT_DIR[0] * SPOUT_V * T_LAND, WATER_Y, MOUTH[2] + SPOUT_DIR[2] * SPOUT_V * T_LAND)

if __name__ == '__main__':
    piv = {P: [0, 0, 0], 'mouth': [v(q) for q in MOUTH], 'splash': [v(q) for q in SPLASH]}
    print('chorro: dir %s, cae en %.2f s a %s m' % (tuple(round(q, 3) for q in SPOUT_DIR), T_LAND, tuple(round(q, 2) for q in SPLASH)))
    n = M.export(os.path.join(os.path.dirname(__file__), '..', 'models', 'inn_sirena.json'), piv, jitter=0.01,
                 pivots_in_voxels=True, roughness=0.45, specular=0.5, no_bottom=False)
    print('inn_sirena: %d voxels' % n)
