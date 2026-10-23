"""Padre Dagon (hito 6.6), jefe de la parte 2. Colosal: asoma del mar de cintura para arriba.
32 voxels/m (S=2) y unos 7 m sobre el agua; en el juego, a escala 1,25 (data/enemies/dagon.tres).

Rediseño (23-10-2026, petición 103 de la revisión de arte: mucho más detalle, color y textura con
la misma forma y el mismo tamaño). Las medidas son las de antes, en ub (1/16 m), con el doble de
resolución. La versión anterior, a 16 voxels/m, queda en gen_dagon_v1.py y se ve con arte=v1.
Sigue las referencias de FLUX en local (python tools/referencias_criaturas.py dagon):
- escamas verde azulado en hileras de ladrillo con su sombra y su brillo, tornasol bronce y
  violeta, motas oscuras y el lomo más oscuro; brazos más azulados y más claros por debajo;
- vientre crema de placas en rejilla con las juntas hundidas y garganta de pliegues;
- boca abierta de lado a lado: labio crema, encía roja, garganta oscura, lengua y dos filas de
  dientes largos, torcidos y desiguales (alguno roto o que falta);
- ojos saltones amarillos que brillan, con el borde naranja y vetas, cerco rojo de carne, pupila
  blanca que brilla con cerco negro y ceja ósea; narinas y agallas rojas con volantes;
- cresta continua de la coronilla a la cintura: dientes de sierra en la cabeza, púas tumbadas en
  la nuca y grandes en la joroba, con membrana granate festoneada; aletas con radios en los antebrazos;
- tubérculos granate en la cabeza, los hombros y los brazos, percebes, cicatrices de zarpazos,
  manos palmeadas con nudillos y garras granate que acaban en marfil y verdín en el agua.
Solo anatomía (CLAUDE.md: los Profundos sin ropa ni adornos). Hueco: solo la cáscara, y sin las
caras que dan al hueco (voxlib.inner_faces).

Partes y pivotes: torso (cintura, en el agua), head (nuca), arm_l / arm_r (hombros).
Animaciones: scripts/anim/anim_dagon.gd. Uso: python tools/gen_dagon.py
"""
import sys, os, math
import numpy as np
from scipy import ndimage
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, _ih, inner_faces

T, H, AL, AR = 'torso', 'head', 'arm_l', 'arm_r'
S = 2                                                             # voxels por ub
M = Model(S=S, seed=1931)
V = M.V

# marcadores: piel que se pinta al final según la normal (escamas, placas)
SKIN = (0.19, 0.42, 0.44); ARM = (0.14, 0.34, 0.40); BROW = (0.10, 0.25, 0.28); BELLY = (0.78, 0.70, 0.50)
EYE = (1.0, 0.9, 0.3)
MARKS = (SKIN, ARM, BROW, BELLY)
# escamas
TEAL = SKIN; TEAL_L = (0.30, 0.55, 0.54); TEAL_D = (0.08, 0.20, 0.23); DORSAL = (0.06, 0.14, 0.18)
BLUE = ARM; PALE = (0.48, 0.53, 0.42); BRONZE = (0.50, 0.42, 0.18); VIOLET = (0.30, 0.20, 0.44)
MOTTLE = (0.04, 0.10, 0.12); SLIME = (0.20, 0.29, 0.12)
# vientre, boca y dientes
CREAM = (0.80, 0.72, 0.52); CREAM_L = (0.90, 0.84, 0.66); CREAM_D = (0.46, 0.39, 0.26); OLIVE = (0.46, 0.48, 0.30)
LIP = (0.76, 0.68, 0.48); LIP_L = (0.88, 0.80, 0.60)
GUM = (0.70, 0.11, 0.14); GUM_D = (0.40, 0.04, 0.07); THROAT = (0.10, 0.01, 0.03); TONGUE = (0.62, 0.20, 0.25)
TOOTH = (0.96, 0.93, 0.82); TOOTH_Y = (0.76, 0.66, 0.42); TOOTH_D = (0.50, 0.42, 0.27)
# ojos, agallas, aletas, tubérculos, percebes, garras
EYE_Y = (1.0, 0.92, 0.30); EYE_O = (0.98, 0.50, 0.08); PUPIL = (0.03, 0.03, 0.02); PUPIL_W = (1.0, 1.0, 0.96)
RIM = (0.56, 0.10, 0.11); RIM_L = (0.82, 0.30, 0.18)
GILL = (0.60, 0.14, 0.17); GILL_L = (0.80, 0.32, 0.30); GILL_D = (0.18, 0.02, 0.04)
FIN = (0.52, 0.10, 0.17); FIN_L = (0.72, 0.24, 0.26); FIN_D = (0.30, 0.04, 0.09); RAY = (0.88, 0.80, 0.58)
WEB = (0.17, 0.36, 0.40); WEB_L = (0.09, 0.22, 0.27)
WART = (0.38, 0.09, 0.12); WART_M = (0.50, 0.14, 0.17); WART_L = (0.68, 0.28, 0.28)
BARN = (0.46, 0.46, 0.42); BARN_L = (0.60, 0.58, 0.52); BARN_D = (0.10, 0.10, 0.09)
SCAR = (0.60, 0.48, 0.47); SCAR_D = (0.05, 0.12, 0.13)
CLAW_B = (0.30, 0.06, 0.09); BONE = (0.70, 0.62, 0.46); CLAW = (0.94, 0.90, 0.76)


def mul(c, k): return tuple(min(1.0, q * k) for q in c)
def smooth(a, b, x): t = min(1.0, max(0.0, (x - a) / (b - a))); return t * t * (3 - 2 * t)


# ---------------- volúmenes con numpy (a S=2 tienen millones de celdas) ----------------
def _grid(lo, hi):
    return np.meshgrid(*[np.arange(lo[i], hi[i]) + 0.5 for i in range(3)], indexing='ij')

def _fill(mask, lo, part, col, over=True, glow=0):
    for x, y, z in (np.argwhere(mask) + lo).tolist():
        M.put(x, y, z, part, col, glow, over)

def sell(cx, cy, cz, rx, ry, rz, part, col, p=3.0, over=True, glow=0):
    """Como voxlib.sell (medidas en ub)."""
    c = np.array((cx, cy, cz), float) * S; r = np.array((rx, ry, rz), float) * S
    lo = np.floor(c - r).astype(int) - 1; hi = np.ceil(c + r).astype(int) + 2
    X, Y, Z = _grid(lo, hi)
    m = np.abs((X - c[0]) / r[0]) ** p + np.abs((Y - c[1]) / r[1]) ** p + np.abs((Z - c[2]) / r[2]) ** p <= 1
    _fill(m, lo, part, col, over, glow)

def _seg(a, b, r):
    a = np.array(a, float) * S; b = np.array(b, float) * S
    lo = np.floor(np.minimum(a, b) - r * S).astype(int) - 1; hi = np.ceil(np.maximum(a, b) + r * S).astype(int) + 2
    X, Y, Z = _grid(lo, hi)
    d = b - a; L2 = float(d @ d) or 1e-9
    t = np.clip(((X - a[0]) * d[0] + (Y - a[1]) * d[1] + (Z - a[2]) * d[2]) / L2, 0, 1)
    D2 = (X - a[0] - d[0] * t) ** 2 + (Y - a[1] - d[1] * t) ** 2 + (Z - a[2] - d[2] * t) ** 2
    return lo, t, D2

def tube(a, b, r0, r1, part, col, over=True):
    """Cápsula de radio r0 a r1 (ub) de a a b, en un solo barrido de su caja."""
    lo, t, D2 = _seg(a, b, max(r0, r1))
    r = (r0 + (r1 - r0) * t) * S
    _fill(D2 <= r * r, lo, part, col, over)

def cone(a, b, r, part, cb, ct, tip_r=0.5, over=True, gamma=1.0):
    """Púa como voxlib.cone: radio r que se afila hasta tip_r y color de cb (base) a ct (punta);
    con gamma > 1 el color de la base llega más lejos."""
    lo, t, D2 = _seg(a, b, r)
    rr = np.maximum(tip_r, r * (1 - t) ** 1.2) * S
    m = D2 <= rr * rr
    for (x, y, z), tt in zip((np.argwhere(m) + lo).tolist(), t[m].tolist()):
        M.put(x, y, z, part, lerp(cb, ct, tt ** gamma), 0, over)


# ---------------- superficie ----------------
def front(x, y, part, z0=220, z1=-120):
    """z del voxel más adelantado de esa parte en la columna (x, y)."""
    for z in range(z0, z1, -1):
        v = V.get((x, y, z))
        if v is not None and v[0] == part: return z
    return None

def side(y, z, s, part, x0=120):
    """x del voxel más exterior de esa parte en la fila (y, z), por el lado s."""
    for x in range(x0 * s, 0, -s):
        v = V.get((x, y, z))
        if v is not None and v[0] == part: return x
    return None

def exposed(k):
    x, y, z = k
    return any((x + a, y + b, z + c) not in V for a, b, c in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)))

def hollow(normals=False, core=None):
    """Vacía cada parte: fuera lo que tiene voxels de la misma parte a 1 y 2 en las seis direcciones
    (por partes: al girar un brazo no queda un agujero en el costado). Con normals=True devuelve la
    normal de cada voxel que queda, del degradado de la ocupación suavizada de su parte; en core
    deja lo que quita (voxel -> parte)."""
    out = {}
    for part in (T, H, AL, AR):
        keys = [k for k, v in V.items() if v[0] == part]
        P = np.array(keys, dtype=np.int64)
        lo = P.min(0) - 5
        occ = np.zeros(tuple(P.max(0) - lo + 6), bool)
        I = tuple((P - lo).T)
        occ[I] = True
        inner = occ.copy()
        for ax in range(3):
            for d in (1, 2, -1, -2): inner &= np.roll(occ, d, axis=ax)
        dead = inner[I]
        if normals:
            g = np.gradient(ndimage.uniform_filter(occ.astype(np.float32), 7))
            N = -np.stack([g[0][I], g[1][I], g[2][I]], 1)
            N /= np.linalg.norm(N, axis=1, keepdims=True) + 1e-9
        for i, k in enumerate(keys):
            if dead[i]:
                del V[k]
                if core is not None: core[k] = part
            elif normals: out[k] = (float(N[i, 0]), float(N[i, 1]), float(N[i, 2]))
    return out


# ---------------- tronco: encorvado hacia delante, hombros enormes (como antes) ----------------
sell(0, 14, 0, 30, 26, 22, T, SKIN, p=2.4)                       # vientre y cintura (se hunde en el agua)
sell(0, 44, 6, 40, 22, 26, T, SKIN, p=2.4)                       # pecho y hombros, adelantados
sell(0, 50, -8, 30, 18, 18, T, SKIN, p=2.2, over=False)          # joroba
sell(0, 58, 14, 18, 10, 16, T, SKIN, p=2.4)                      # cuello grueso

# ---------------- cabeza de pez ----------------
HY, HZ = 72, 26
sell(0, HY, HZ, 26, 18, 26, H, SKIN, p=2.6)
sell(0, HY - 14, HZ + 6, 22, 8, 22, H, BELLY, p=2.6)             # mandíbula colgante: garganta pálida
sell(0, HY + 10, HZ - 6, 18, 8, 18, H, SKIN, p=2.4, over=False)  # coronilla
EYES = []
for s in (-1, 1):                                                # ojos saltones a los lados
    ex, ey, ez = 24 * s, HY + 4, HZ + 10
    sell(ex, ey, ez, 7, 7, 7, H, EYE, p=2.0)
    sell(ex - 1 * s, ey + 6, ez, 8, 3, 8, H, BROW, p=2.6, over=False)   # ceja ósea
    EYES.append((ex * S, ey * S, ez * S, s))

# ---------------- brazos: largos, apoyados delante en el agua ----------------
ARMS = []
for s, A in ((-1, AL), (1, AR)):
    sh, el, wr = (38 * s, 50, 4), (46 * s, 26, 22), (40 * s, 8, 44)
    ARMS.append((s, A, sh, el, wr))
    tube(sh, el, 11, 9, A, ARM)
    tube(el, wr, 9, 7, A, ARM)
    sell(wr[0], 4, 54, 12, 5, 12, A, ARM, p=2.6)                 # mano palmeada, abierta sobre el agua
    for f in range(-2, 3):                                       # dedos con nudillos
        a = math.radians(f * 22)
        P = lambda rho, y: (wr[0] + rho * math.sin(a), y, 54 + rho * math.cos(a))
        tube(P(9, 4), P(15, 4.2), 3.0, 2.7, A, ARM)
        tube(P(15, 4.2), P(20, 2.6), 2.7, 2.3, A, ARM)
        sell(*P(15, 4.6), 3.2, 3.0, 3.2, A, ARM, p=2.2)          # nudillo

# ---------------- tallados (antes de vaciar) ----------------
W = 21                                                           # media anchura de la boca, en ub
def mouth_edges(x):
    """Filas talladas de la boca en la columna x (en voxels): de y_bot a y_top (sin incluir).
    Arriba casi recta y abajo en U honda: se cierra en las comisuras."""
    xf = x / (W * S)
    return int(round((HY - 1 - 2 * xf * xf) * S)), int(round((HY - 15 + 9 * xf * xf) * S))

Z0, CARVED = {}, set()                                           # frente de la cara antes de tallar y huecos
for x in range(-W * S, W * S + 1):
    yt, yb = mouth_edges(x)
    xf = x / (W * S)
    for y in range(yb, yt):
        z0 = front(x, y, H)
        if z0 is None: continue
        Z0[(x, y)] = z0
        vf = (y - yb) / max(1, yt - yb)
        D = int(S * (8 + 10 * (1 - xf * xf)) * (0.7 + 0.3 * math.sin(math.pi * vf)))
        for z in range(z0, z0 - D, -1):
            v = V.get((x, y, z))
            if v is not None and v[0] == H:
                del V[(x, y, z)]; CARVED.add((x, y, z))

for s in (-1, 1):                                                # narinas
    nx, ny = 6 * s * S, 79 * S
    for x in range(nx - 3, nx + 4):
        for y in range(ny - 3, ny + 3):
            if (x - nx) ** 2 + ((y - ny + 0.5) * 1.3) ** 2 > 6.5: continue
            z = front(x, y, H)
            if z is None: continue
            for dz in (0, 1): V.pop((x, y, z - dz), None)
            V[(x, y, z - 2)] = [H, GUM_D, 0]

GILLS = []                                                       # agallas: cuatro rajas en media luna detrás de cada ojo
for s in (-1, 1):
    for k in range(4):
        z0k = (HZ + 10 - 12 - 3 * k) * S
        yc, hh = (HY - 3) * S, (5.5 - 0.7 * k) * S                  # las de detrás, más cortas
        for y in range(int(yc - hh), int(yc + hh) + 1):
            q = (y - yc) / hh
            zk = z0k - int(round(2.5 * (1 - q * q)))                 # se curvan hacia atrás en el centro
            xo = side(y, zk, s, H)
            if xo is None: continue
            V.pop((xo, y, zk), None)
            GILLS.append((xo, y, zk, s))

def belly_e(x, y):
    """0 en el centro del vientre y 1 en su borde (en voxels)."""
    return math.sqrt((x / (22 * S)) ** 2 + ((y - 26 * S) / (32 * S)) ** 2)

def belly_groove(x, y):
    return (y + 3) % 6 == 0 or ((x + 5) % 10 == 0 and belly_e(x, y) < 0.93)

for x in range(-22 * S, 22 * S + 1):                             # juntas de las placas del vientre, hundidas
    for y in range(-6 * S, 58 * S):
        if belly_e(x, y) < 1 and belly_groove(x, y):
            z = front(x, y, T)
            if z is not None: del V[(x, y, z)]

CORE = {}
NORMAL = hollow(normals=True, core=CORE)

# ---------------- boca: encía, garganta, lengua, labios y dientes ----------------
for (x, y, z) in CARVED:
    for a, b, c in ((0, 1, 0), (0, -1, 0), (0, 0, -1), (1, 0, 0), (-1, 0, 0)):
        k = (x + a, y + b, z + c)
        v = V.get(k)
        if v is None or v[0] != H or k in CARVED: continue
        d = Z0.get((x, y), z) - z
        if b == -1 and abs(x) < 8 * S and d > 3:                 # suelo: lengua con su surco
            col = GUM_D if x in (-1, 0) else lerp(TONGUE, GUM_D, 0.25 * _ih(x, y, z, 3))
        elif d <= 2: col = GUM
        else: col = lerp(GUM_D, THROAT, min(1.0, (d - 2) / (7.0 * S)))
        V[k] = [H, col, 0]

def in_mouth(x, y):
    if abs(x) > W * S: return False
    yt, yb = mouth_edges(x)
    return yb <= y < yt and yt - yb >= 2

for x in range(-(W + 3) * S, (W + 3) * S + 1):                   # labio crema alrededor
    for y in range((HY - 18) * S, (HY + 2) * S):
        if in_mouth(x, y): continue
        dm = min((math.hypot(a, b) for a in range(-3, 4) for b in range(-3, 4) if in_mouth(x + a, y + b)), default=9)
        if dm > 3.2: continue
        z = front(x, y, H)
        if z is not None: V[(x, y, z)] = [H, LIP_L if dm <= 1.5 else LIP, 0]

def tooth(x0, y0, z0, down, L, w, tx, tz, k):
    """Diente de L voxels desde la raíz, hacia abajo (arriba) o hacia arriba (abajo): w de ancho en
    la raíz que se afila hasta 1, torcido tx y tz voxels en la punta; amarillento en la raíz,
    alguna mancha y, si está roto, la punta parda."""
    broken = L <= 5 and _ih(k, 9, 7) > 0.5
    for j in range(L):
        f = j / max(1, L - 1)
        ww = w if f < 0.4 else (max(1, w - 1) if f < 0.75 else 1)
        dx = int(round(tx * f * f)); dz = int(round(tz * f * f))
        y = y0 - j if down else y0 + j
        c = lerp(TOOTH_Y, TOOTH, min(1.0, f * 1.6))
        if _ih(x0, j, k, 5) > 0.9 or (broken and j == L - 1): c = TOOTH_D
        for a in range(ww):
            for b in range(ww):
                M.put(x0 + dx + a - ww // 2, y, z0 + dz - b, H, c)

for upper in (True, False):                                      # dos filas desiguales, torcidas, alguno roto o que falta
    x = -int(19.5 * S); k = 0 if upper else 100
    while x <= int(19.5 * S):
        xf = x / (W * S)
        canine = 0.4 < abs(xf) < 0.62
        yt, yb = mouth_edges(x)
        room = yt - yb - 2
        if _ih(k, 1, 7) > 0.1 and room > 3:
            h = _ih(k, 2, 7)
            if upper: L = (15 + 5 * h) if canine else (6 + 7 * h * (1 - 0.5 * abs(xf)))
            else: L = (11 + 4 * h) if canine else (5 + 5 * h * (1 - 0.4 * abs(xf)))
            if _ih(k, 3, 7) > 0.88: L = 3 + 2 * _ih(k, 4, 7)       # roto
            y0 = yt - 1 if upper else yb
            z0 = Z0.get((x, y0))
            if z0 is not None:
                tooth(x, y0, z0 - 2, upper, int(min(L, room)), 3 if canine else 2,
                      (_ih(k, 5, 7) - 0.5) * 6, (_ih(k, 6, 7) - 0.3) * 4, k)
        x += (7 if canine else 5) + int(_ih(k, 8, 7) * 3)
        k += 1

# ---------------- ojos: iris amarillo con vetas, pupila blanca que brilla ----------------
for ex, ey, ez, s in EYES:
    dv = (0.62 * s, -0.12, 0.78); n = math.sqrt(sum(c * c for c in dv)); dv = [c / n for c in dv]
    e1 = (dv[2], 0.0, -dv[0]); n1 = math.hypot(e1[0], e1[2]); e1 = (e1[0] / n1, 0.0, e1[2] / n1)
    e2 = (dv[1] * e1[2] - dv[2] * e1[1], dv[2] * e1[0] - dv[0] * e1[2], dv[0] * e1[1] - dv[1] * e1[0])
    for (x, y, z), v in list(V.items()):
        if v[1] != EYE: continue
        o = (x + 0.5 - ex, y + 0.5 - ey, z + 0.5 - ez); l = math.sqrt(sum(c * c for c in o)) or 1.0
        d = sum(o[i] * dv[i] for i in range(3)) / l
        if d > 0.965: V[(x, y, z)] = [H, PUPIL_W, 1]
        elif d > 0.9: V[(x, y, z)] = [H, PUPIL, 0]
        else:
            c = lerp(EYE_Y, EYE_O, smooth(0.62, 0.4, d))           # naranja solo en el borde
            if 0.4 < d < 0.47: c = lerp(EYE_O, RIM, 0.5)           # aro oscuro que enmarca el iris
            ang = math.atan2(sum(o[i] * e2[i] for i in range(3)), sum(o[i] * e1[i] for i in range(3)))
            if int((ang + math.pi) / (2 * math.pi) * 18) % 2 == 0: c = lerp(c, EYE_O, 0.35)   # vetas
            V[(x, y, z)] = [H, c, 1]

# ---------------- agallas: raja oscura y volante rojo detrás ----------------
for xo, y, zk, s in GILLS:
    V[(xo - s, y, zk)] = [H, GILL_D, 0]
    for dz in (1, 2):
        xb = side(y, zk - dz, s, H)
        if xb is None: continue
        V[(xb, y, zk - dz)] = [H, GILL, 0]
        if dz == 1:                                              # volante levantado, festoneado
            V[(xb + s, y, zk - dz)] = [H, GILL_L if (y // 2) % 3 == 0 else GILL, 0]

# ---------------- cresta continua: púas de hueso y membrana granate festoneada ----------------
# Rayos en el plano x = 0 desde dentro del cuerpo: el último voxel de cada uno es el contorno del
# lomo. Una cresta baja lo recorre entero y las púas salen de ella a trechos algo irregulares,
# medianas en la cabeza, grandes en la joroba y pequeñas hacia la cintura, inclinadas hacia atrás;
# entre púa y púa, membrana que se hunde en el centro.
CY, CZ = 44 * S, 8 * S
prof = []
for i in range(0, 481):
    th = math.radians(-18 + i * 0.35)
    dy, dz = math.cos(th), -math.sin(th)
    last = None
    for r in range(0, 90 * S):
        q = (0, int(round(CY + dy * r)), int(round(CZ + dz * r)))
        if q in V and V[q][0] in (T, H): last = q
    if last and last[1] > 4 * S: prof.append((th, last, V[last][0]))

def size_at(th):
    d = math.degrees(th)
    if d < 25: return 0.45                                       # cabeza
    if d < 45: return 0.5                                        # nuca
    return 0.5 + 0.5 * math.sin(math.pi * min(1.0, (d - 45) / 105)) ** 0.7 if d < 120 else max(0.3, 1.0 - (d - 120) / 60)

spines = []                                                      # (índice en prof, largo en voxels, ángulo)
arc = 0.0; nxt = 0.0; prev = None; n = 0
for j, (th, (x0, y0, z0), part) in enumerate(prof):
    if prev: arc += math.hypot(y0 - prev[1], z0 - prev[2])
    prev = (x0, y0, z0)
    sz = size_at(th)
    dy, dz = math.cos(th), -math.sin(th)
    for h in range(1, 2 + int(2.5 * sz * S)):                    # cresta baja
        for xx in (-2, -1, 0, 1) if h <= 2 else (-1, 0):
            M.put(xx, int(round(y0 + dy * h)), int(round(z0 + dz * h)), part, FIN_D, over=False)
    if arc >= nxt and th > math.radians(-10):
        head = th < math.radians(25)
        if head:                                                 # en la cabeza, dientes de sierra cortos y anchos, como en
            L = (5 + 3 * M.hsh(n, 3, 1)) * S                     # las referencias (de frente, una púa larga parecía una antena)
            back = th + math.radians(35 + 10 * M.hsh(n, 3, 2))
            nxt = arc + (5 + 2 * M.hsh(n, 3, 4)) * S
        else:
            L = (8 + 12 * sz) * (0.8 + 0.4 * M.hsh(n, 3, 1)) * S
            # inclinada hacia la cola; las de la nuca, más tumbadas: con la cámara del juego (30° desde
            # arriba) una púa de la nuca algo levantada asoma por encima de la cabeza
            sweep = 65 - 25 * smooth(math.radians(40), math.radians(75), th)
            back = th + math.radians(sweep - 10 + 20 * M.hsh(n, 3, 2))
            nxt = arc + (6 + 6 * sz) * S * (0.75 + 0.5 * M.hsh(n, 3, 4))
        spines.append((j, L, back, sz, part)); n += 1
for a, b in zip(spines, spines[1:]):                             # membrana entre púas
    ja, La, ta, _, _ = a; jb, Lb, tb, _, _ = b
    steps = (jb - ja) * 3
    for i in range(steps + 1):
        u = i / steps
        jj = ja + (jb - ja) * u
        j0 = int(jj); j1 = min(j0 + 1, len(prof) - 1); w = jj - j0
        p0, p1 = prof[j0][1], prof[j1][1]
        by, bz = p0[1] + (p1[1] - p0[1]) * w, p0[2] + (p1[2] - p0[2]) * w
        part = prof[j0][2]
        ang = ta + (tb - ta) * u
        hgt = (La + (Lb - La) * u) * (1 - 0.42 * math.sin(math.pi * u)) * 0.92
        vein = min(abs(u - 1 / 3), abs(u - 2 / 3)) < 0.02
        for hh in range(1, int(hgt) + 1):
            t = hh / hgt
            col = FIN_D if (t < 0.12 or vein) else (FIN_L if hh >= hgt - 1.5 else lerp(FIN, FIN_L, 0.25 * t))
            for xx in (-1, 0):
                M.put(xx, int(round(by + math.cos(ang) * hh)), int(round(bz - math.sin(ang) * hh)), part, col, over=False)
for j, L, back, sz, part in spines:                              # púas: de granate en la base a hueso en la punta
    th, (x0, y0, z0), _ = prof[j]
    dy, dz = math.cos(th), -math.sin(th)
    side_x = (M.hsh(j, 3, 3) - 0.5) * 3                          # algo desviada a un lado (ub)
    tip = (side_x, (y0 + math.cos(back) * L) / S, (z0 - math.sin(back) * L) / S)
    r = 2.4 if th < math.radians(25) else 1.2 + 1.6 * sz
    cone((0, (y0 - dy * 2 * S) / S, (z0 - dz * 2 * S) / S), tip, r, part, FIN_D, RAY, tip_r=0.5)

# ---------------- aletas de los antebrazos, manos palmeadas y garras ----------------
for s, A, sh, el, wr in ARMS:
    rays = []
    for k in range(10):
        t = 0.08 + 0.84 * k / 9
        c = [el[i] + (wr[i] - el[i]) * t for i in range(3)]
        rr = 9 + (7 - 9) * t
        L = 3 + 8 * math.sin(math.pi * t) ** 0.8
        rays.append(((c[0] + s * (rr - 1.5), c[1] + 1.5, c[2]), (c[0] + s * (rr + L), c[1] + 3 + L * 0.3, c[2] - L * 0.35)))
    for (b0, t0), (b1, t1) in zip(rays, rays[1:]):               # membrana festoneada entre radios
        for i in range(41):
            v = i / 40
            edge = 0.97 - 0.15 * math.sin(math.pi * v)
            for kk in range(41):
                u = kk / 40
                if u > edge: continue
                p = [(b0[q] + (t0[q] - b0[q]) * u) * (1 - v) + (b1[q] + (t1[q] - b1[q]) * u) * v for q in range(3)]
                col = FIN_D if u < 0.15 or abs(v - 0.5) < 0.04 else (FIN_L if u > edge - 0.12 else FIN)
                for dyy in (0, -1):
                    M.put(p[0] * S, p[1] * S + dyy, p[2] * S, A, col, over=False)
    for b, t in rays: cone(b, t, 0.9, A, FIN_D, lerp(FIN_L, RAY, 0.6), tip_r=0.5, gamma=2.0)   # radios granate, más claros en la punta
    for f in range(-2, 2):                                       # membrana entre los dedos
        a0, a1 = math.radians(f * 22), math.radians((f + 1) * 22)
        for i in range(31):
            v = i / 30
            a = a0 + (a1 - a0) * v
            rho_max = 19 - 3.5 * math.sin(math.pi * v)               # hasta casi las garras, con el borde hundido
            rho = 9.0
            while rho <= rho_max:
                x, z = wr[0] + rho * math.sin(a), 54 + rho * math.cos(a)
                col = WEB_L if rho > rho_max - 0.8 or abs(v - 0.5) < 0.04 else WEB
                for yy in (3.6, 4.1):
                    M.put(x * S, yy * S, z * S, A, col, over=False)
                rho += 0.25
    for f in range(-2, 3):                                       # garras ganchudas: base oscura, hueso y punta de marfil, clavadas en el agua
        a = math.radians(f * 22)
        P = lambda rho, y: (wr[0] + rho * math.sin(a), y, 54 + rho * math.cos(a))
        cone(P(19.5, 2.8), P(24.5, 3.4), 2.0, A, CLAW_B, BONE, tip_r=1.3, gamma=0.6)
        cone(P(24.5, 3.4), P(27.5, 1.2), 1.4, A, BONE, CLAW, tip_r=0.9)
        cone(P(27.5, 1.2), P(28.5, -1.4), 0.9, A, CLAW, CLAW, tip_r=0.5)

# ---------------- piel: escamas, placas, tornasol, verdín y cicatrices ----------------
SCARS = [((-31, 52), (-21, 38)), ((-28, 54), (-18, 40)), ((-25, 55), (-16, 43))]   # zarpazo en el pecho (ub)
SCARS = [((a[0] * S, a[1] * S), (b[0] * S, b[1] * S)) for a, b in SCARS]

def seg_d(px, py, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0.0, min(1.0, ((px - a[0]) * dx + (py - a[1]) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - a[0] - dx * t, py - a[1] - dy * t)

def scale_cell(x, y, z, n, sw, sh):
    """Escama en hileras de ladrillo sobre la cara dominante: eje, fila, columna y posición dentro."""
    ax = 0 if abs(n[0]) >= abs(n[1]) and abs(n[0]) >= abs(n[2]) else (1 if abs(n[1]) >= abs(n[2]) else 2)
    u, v = ((z, y), (x, z), (x, y))[ax]
    row = v // sh
    u2 = u + (row % 2) * (sw // 2)
    return ax, row, u2 // sw, u2 % sw, v % sh

def scales(x, y, z, n, part, base):
    """Escama redondeada: cara con su tono, brillo arriba, sombra abajo (más en las esquinas) y a
    un lado; tornasol en manchas y motas oscuras."""
    sw, sh = (4, 3) if part == H else ((5, 3) if part in (AL, AR) else (6, 4))
    ax, row, col, lu, lv = scale_cell(x, y, z, n, sw, sh)
    h = _ih(col, row, ax * 2 + (n[ax] > 0), 11)
    c = mul(base, 0.84 + 0.3 * h)
    ir = M.noise(x, y, z, 22.0)                                  # tornasol en manchas
    if ir > 0.6: c = lerp(c, BRONZE, min(0.5, (ir - 0.6) * 1.8) * (0.4 + h))
    elif ir < 0.32: c = lerp(c, VIOLET, min(0.45, (0.32 - ir) * 1.8) * (0.4 + h))
    corner = lu in (0, sw - 1)
    if lv == 0: c = mul(c, 0.5 if corner else 0.72)              # borde de abajo, redondeado
    elif lu == 0: c = mul(c, 0.76)
    elif lv == sh - 1: c = lerp(c, TEAL_L, 0.32)                 # brillo arriba
    elif lu == sw - 1: c = mul(c, 0.9)
    if M.noise(x + 40, y, z, 9.0) > 0.72: c = lerp(c, MOTTLE, 0.35)     # motas oscuras
    return c

SCALY = set()                                                    # piel de escamas: ahí salen los bultos
for k, v in list(V.items()):
    base = v[1]
    if base not in MARKS: continue
    x, y, z = k
    n = NORMAL.get(k, (0.0, 0.0, 1.0))
    part = v[0]
    if base == BELLY:                                            # garganta de pliegues
        c = CREAM_D if y % 4 == 0 else lerp(CREAM, CREAM_L, 0.4 * (y % 4 == 3))
        c = mul(c, 0.9 + 0.16 * _ih(y // 4, 0, 0, 12))
        if n[1] < -0.4: c = lerp(c, OLIVE, 0.4)
    elif part == T and n[2] > 0.3 and belly_e(x, y) < 1:          # placas del vientre
        e = belly_e(x, y)
        row, lv = (y + 3) // 6, (y + 3) % 6
        col, lu = (x + 5) // 10, (x + 5) % 10
        if belly_groove(x, y): c = CREAM_D
        else:                                                    # bisel: arriba claro, abajo en sombra
            c = CREAM_L if lv == 5 else (mul(CREAM, 0.84) if lv == 1 else CREAM)
            if lu == 1: c = lerp(c, CREAM_L, 0.3)
            elif lu == 9: c = mul(c, 0.9)
        c = mul(c, 0.88 + 0.2 * _ih(col, row, 0, 13))
        c = lerp(c, OLIVE, 0.7 * smooth(0.72, 1.0, e))
        if e > 0.93: c = lerp(c, TEAL, smooth(0.93, 1.0, e))
    else:
        if base == ARM:
            b = lerp(BLUE, PALE, 0.55 * smooth(-0.15, -0.7, n[1]))
            b = lerp(b, DORSAL, 0.3 * smooth(0.4, 0.9, n[0] * (-1 if part == AL else 1)))
        elif base == BROW:
            b = TEAL_D
        else:
            b = lerp(TEAL, DORSAL, 0.65 * smooth(-0.1, -0.8, n[2]))
            b = lerp(b, PALE, 0.4 * smooth(-0.3, -0.8, n[1]))
        c = scales(x, y, z, n, part, b)
        SCALY.add(k)
        for ex, ey, ez, s in EYES:                               # cerco rojo de carne alrededor del ojo
            if part != H: break
            d = math.sqrt((x + 0.5 - ex) ** 2 + (y + 0.5 - ey) ** 2 + (z + 0.5 - ez) ** 2)
            if d < 7 * S + 1.2 * S: c = RIM_L if d < 7 * S + 0.6 * S else RIM; SCALY.discard(k)
    if part == T and n[2] > 0.2:                                 # zarpazo viejo
        dd = min(seg_d(x, y, a, b) for a, b in SCARS)
        if dd < 1.8: SCALY.discard(k)
        if dd < 0.9: c = SCAR
        elif dd < 1.8: c = lerp(c, SCAR_D, 0.6)
    if y < 5 * S:                                                # verdín y piel mojada en la línea del agua
        f = (5 * S - y) / (5 * S)
        c = lerp(c, SLIME, min(0.75, f * (0.45 + 0.5 * M.noise(x, y, z, 6.0))))
        if y < 0: c = mul(c, 0.75)
    V[k] = [part, c, v[2]]

# ---------------- tubérculos granate y percebes ----------------
def bump(p, n, r, part):
    """Bulto redondo de radio r (voxels) que sale de la superficie en p, más claro arriba y con la
    piel de alrededor en sombra."""
    c = [p[i] + 0.5 - n[i] * r * 0.2 for i in range(3)]
    R = int(r * 1.4) + 2
    ring = []
    for x in range(int(c[0]) - R, int(c[0]) + R + 1):
        for y in range(int(c[1]) - R, int(c[1]) + R + 1):
            for z in range(int(c[2]) - R, int(c[2]) + R + 1):
                o = (x + 0.5 - c[0], y + 0.5 - c[1], z + 0.5 - c[2])
                d2 = o[0] ** 2 + o[1] ** 2 + o[2] ** 2
                v = V.get((x, y, z))
                if v is not None:
                    if v[0] == part and not v[2] and v[1] not in (WART, WART_L, WART_M) and d2 <= (r * 1.4) ** 2: ring.append((x, y, z))
                    continue
                if d2 > r * r: continue
                up = (o[0] * n[0] + o[1] * n[1] + o[2] * n[2]) / r
                M.put(x, y, z, part, WART_L if up > 0.75 else (WART_M if up > 0.35 else WART))
    for k in set(ring): V[k][1] = mul(V[k][1], 0.7)

def barnacle(p, n, r, part):
    """Percebe: cono bajo de placas grises con el centro oscuro."""
    hgt = 3.2
    up = (0.0, 1.0, 0.0) if abs(n[1]) < 0.9 else (1.0, 0.0, 0.0)
    e1 = (n[1] * up[2] - n[2] * up[1], n[2] * up[0] - n[0] * up[2], n[0] * up[1] - n[1] * up[0])
    l1 = math.sqrt(sum(c * c for c in e1)); e1 = [c / l1 for c in e1]
    e2 = (n[1] * e1[2] - n[2] * e1[1], n[2] * e1[0] - n[0] * e1[2], n[0] * e1[1] - n[1] * e1[0])
    for x in range(p[0] - int(r) - 2, p[0] + int(r) + 3):
        for y in range(p[1] - int(r) - 2, p[1] + int(r) + 3):
            for z in range(p[2] - int(r) - 2, p[2] + int(r) + 3):
                if (x, y, z) in V: continue
                w = (x - p[0], y - p[1], z - p[2])
                al = w[0] * n[0] + w[1] * n[1] + w[2] * n[2]
                if not (0 < al <= hgt): continue
                q = [w[i] - n[i] * al for i in range(3)]
                rad = math.sqrt(sum(c * c for c in q))
                if rad > r * (1 - 0.3 * al / hgt): continue
                if rad < r * 0.45: col = BARN_D
                else:                                            # seis placas, una sí y otra no más clara
                    ang = math.atan2(sum(q[i] * e2[i] for i in range(3)), sum(q[i] * e1[i] for i in range(3)))
                    col = BARN_L if (int((ang + math.pi) / (2 * math.pi) * 6) % 2 or al > hgt - 1) else BARN
                M.put(x, y, z, part, col)

cells = {}                                                       # una celda de 18 voxels: como mucho un bulto
for k, v in V.items():
    if k not in SCALY or not exposed(k): continue
    c = (k[0] // 18, k[1] // 18, k[2] // 18)
    if c not in cells or _ih(*k, 21) > _ih(*cells[c], 21): cells[c] = k
for c, k in sorted(cells.items()):
    x, y, z = k
    part = V[k][0]
    n = NORMAL[k]
    h, rr = _ih(*c, 22), _ih(*c, 23)
    if part == H:                                                # coronilla, entre la cresta y los ojos
        if n[1] > 0.35 and y > (HY + 3) * S and abs(x) > 4 * S and h < 0.6:
            bump(k, n, (1.6 + 0.9 * rr) * S, H)
    elif part == T:
        if abs(x) > 24 * S and y > 44 * S and n[1] > -0.1 and h < 0.55:                # hombros
            bump(k, n, (1.8 + 1.0 * rr) * S, T)
        elif z < -6 * S and y > 34 * S and abs(x) > 5 * S and n[2] < -0.2 and h < 0.12:  # joroba
            bump(k, n, (1.4 + 0.6 * rr) * S, T)
        elif y < 22 * S and n[2] < 0.1 and h < 0.3:                                    # percebes en la cintura
            for i in range(1 + int(3 * _ih(*c, 24))):
                q = (x + int((_ih(*c, 25 + i) - 0.5) * 9), y + int((_ih(*c, 30 + i) - 0.5) * 7), z)
                qq = min((kk for kk in ((q[0], q[1], q[2] + dz) for dz in range(-6, 7)) if kk in NORMAL),
                         key=lambda kk: abs(kk[2] - z), default=None)
                if qq: barnacle(qq, NORMAL[qq], 2.0 + 1.3 * _ih(*c, 35 + i), T)
    elif y > 34 * S and h < 0.25 and n[1] > -0.2:                                      # brazo, de hombro a codo
        bump(k, n, (1.4 + 0.7 * rr) * S, part)

# ---------------- final ----------------
# Lo de después de vaciar (bases de púas, raíces de dientes, garras) se clava hasta el hueco y, si es
# de otra parte (púas de la cabeza en la nuca), rompe la cáscara: se rellena el hueco y se vacía otra
# vez, y así cada parte queda cerrada por sus propios voxels (inner_faces quita las caras de dentro).
for k, part in CORE.items(): V[k] = [part, TEAL_D, 0]
hollow()
for k in [k for k in V if k[1] < -16 * S]: del V[k]              # lo que queda muy hondo
piv = {T: [0, -4 * S, 0], H: [0, 60 * S, 14 * S], AL: [-38 * S, 50 * S, 4 * S], AR: [38 * S, 50 * S, 4 * S]}
skip = inner_faces(M, (T, H, AL, AR), floor=-16 * S)              # sin las caras de dentro: la mitad de la malla
n = M.export('models/dagon.json', piv, jitter=0.01, pivots_in_voxels=True, roughness=0.5, specular=0.45,
             parents={H: T, AL: T, AR: T}, skip=skip)
print('dagon: %d voxels, %d con caras de dentro' % (n, len(skip)))
