"""Capturas de la pesca en el muelle de Innsmouth (hito 16.24). Voxels finos (S=6: 96 por metro),
porque un arenque de 27 cm a 32 por metro serían ocho voxels. El pez va a lo largo de X (la
cabeza hacia +X), Y arriba; partes `body` y `tail` (la cola, con el pivote en su arranque, para
que coletee: scripts/anim/anim_pez.gd). Algunas llevan una tercera (`lure`, el farolillo del rape).

  pez_arenque       común: plateado, lomo azul acero, cola ahorquillada.
  pez_caballa       común: lomo verde azulado con rayas negras onduladas.
  pez_bacalao       común: grande, pardo oliva moteado, línea lateral clara y barbillón.
  pez_platija       común: plana, parda con lunares naranjas, los dos ojos arriba.
  pez_anguila       común: larga, oliva oscuro, aleta continua.
  pez_rape          raro: cabezón negro de boca enorme con dientes y un farolillo que brilla.
  pez_ojos          raro: pez pálido con ojos que son demasiado humanos.
  pez_cria          maldito: cría de profundo, renacuajo con bracitos palmeados y ojos amarillos.
  pez_mano          maldito: una mano palmeada con garras, arrancada de algo que aún la busca.
Uso: python tools/gen_peces.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale

OUT = os.path.join(os.path.dirname(__file__), '..', 'models')
S = 6                       # 1 ub = 6 voxels: 96 voxels por metro


def prof(t, peak=0.6, ped=0.2, nose=0.18, blunt=0.55):
    """Grosor relativo a lo largo del pez: t=0 en el pedúnculo de la cola, 1 en el morro."""
    if t < peak:
        return ped + (1 - ped) * math.sin(math.pi / 2 * t / peak) ** 0.9
    return max(nose, math.cos(math.pi / 2 * (t - peak) / (1 - peak)) ** blunt)


def body(M, L, H, W, col, cy, profile=prof, part='body', x0=0, tail_from=None, zoff=None):
    """Cuerpo por secciones elípticas de x0 a x0+L; col(x, yn, zn, t) -> color (yn, zn en -1..1).
    tail_from: desde x0 hasta ahí, parte `tail` (la anguila y la cría doblan medio cuerpo)."""
    for i in range(L):
        t = i / (L - 1)
        k = profile(t)
        h, w = max(1.0, H * k), max(1.0, W * k)
        x = x0 + i
        p = 'tail' if tail_from is not None and x < tail_from else part
        for y in range(int(cy - h) - 1, int(cy + h) + 2):
            for z in range(int(-w) - 1, int(w) + 2):
                yn, zn = (y + 0.5 - cy) / h, (z + 0.5) / w
                if yn * yn + zn * zn <= 1.0:
                    M.put(x, y, z + (zoff(x) if zoff else 0), p, col(x, yn, zn, t))


def fin_tri(M, part, col, base0, base1, y0, height, lean=0.0, thick=(-1, 0), up=True, edge=None):
    """Aleta fina en el plano XY: base de base0 a base1 a la altura y0, sube (o baja) `height`."""
    n = base1 - base0
    for i in range(n):
        f = i / max(1, n - 1)
        hh = height * math.sin(math.pi * min(1.0, f * 1.15)) if n > 2 else height
        for j in range(int(hh) + 1):
            x = base0 + i + int(lean * j)
            y = y0 + j if up else y0 - j
            c = edge if (edge is not None and j >= int(hh) - 0) else col
            for z in thick:
                M.put(x, y, z, part, c, over=False)


def tail_fork(M, col, cy, length, spread, fork=True, edge=None, x_end=0):
    """Aleta caudal de x_end-length a x_end, abierta en Y; ahorquillada o en abanico."""
    for i in range(length):
        f = (i + 1) / length                       # 0 en el pedúnculo, 1 en el borde
        half = 1.5 + spread * f
        x = x_end - 1 - i
        for y in range(int(cy - half), int(cy + half) + 1):
            d = abs(y + 0.5 - cy) / half
            if fork and f > 0.55 and d < (f - 0.55) * 1.6: continue      # la horquilla
            c = edge if (edge is not None and f > 0.85) else col
            for z in (-1, 0):
                M.put(x, y, z, 'tail', c)


def surf_z(M, x, y, side):
    """z del voxel de la superficie en (x, y), por el lado +z (side=1) o -z (side=-1)."""
    rng = range(40, -41, -1) if side > 0 else range(-40, 41)
    for z in rng:
        if (x, y, z) in M.V: return z
    return None


def eye(M, x, y, r, iris, white=None, glint=(0.95, 0.95, 0.9), glow=0, sides=(1, -1), pupil=(0.03, 0.03, 0.03)):
    """Ojo pintado en la superficie de los dos costados: anillo `iris`, pupila y un brillo."""
    for s in sides:
        for dx in range(-r, r + 1):
            for dy in range(-r, r + 1):
                d = math.hypot(dx, dy)
                if d > r + 0.35: continue
                z = surf_z(M, x + dx, y + dy, s)
                if z is None: continue
                if white is not None and d > r - 0.6: c = white
                elif d < r * 0.45: c = pupil
                else: c = iris
                M.V[(x + dx, y + dy, z)][1] = c
                if glow: M.V[(x + dx, y + dy, z)][2] = glow if d <= r - 0.6 or white is None else 0
        z = surf_z(M, x + 1, y + 1, s)
        if z is not None and r >= 1:
            M.V[(x + 1, y + 1, z)][1] = glint


def mouth(M, x0, x1, y, col, sides=(1, -1)):
    for s in sides:
        for x in range(x0, x1):
            z = surf_z(M, x, y, s)
            if z is not None: M.V[(x, y, z)][1] = col


def shade(back, mid, belly):
    def f(yn):
        return lerp(mid, back, min(1, (yn - 0.1) / 0.6)) if yn > 0.1 else lerp(mid, belly, min(1, (-yn + 0.1) / 0.7))
    return f


def export(M, name, pivots, **kw):
    n = M.export(os.path.join(OUT, name + '.json'), pivots, pivots_in_voxels=True, jitter=0.012, **kw)
    print(name, n, 'voxels')


# ------------------------------------------------------------------ comunes

def arenque():
    M = Model(S, 1601)
    L, H, W, cy = 22, 4.2, 2.6, 8
    sh = shade((0.17, 0.28, 0.40), (0.62, 0.67, 0.72), (0.86, 0.88, 0.90))
    body(M, L, H, W, lambda x, yn, zn, t: lerp(sh(yn), (0.80, 0.84, 0.88), 0.25) if abs(yn - 0.05) < 0.12 else sh(yn), cy)
    tail_fork(M, (0.42, 0.50, 0.58), cy, 6, 4.0, edge=(0.25, 0.32, 0.40))
    fin_tri(M, 'body', (0.30, 0.40, 0.50), 9, 14, int(cy + 3.6), 3)
    fin_tri(M, 'body', (0.70, 0.74, 0.78), 5, 8, int(cy - 3.4), 1.5, up=False)
    eye(M, L - 4, int(cy + 0.6), 1, (0.75, 0.70, 0.40))
    mouth(M, L - 2, L, int(cy - 1), (0.30, 0.30, 0.34))
    export(M, 'pez_arenque', {'body': [L // 2, cy, 0], 'tail': [0, cy, 0]})


def caballa():
    M = Model(S, 1602)
    L, H, W, cy = 28, 5.0, 3.4, 9
    sh = shade((0.14, 0.36, 0.38), (0.68, 0.74, 0.74), (0.90, 0.90, 0.88))

    def col(x, yn, zn, t):
        c = sh(yn)
        if yn > 0.15 and math.sin(x * 0.9 + math.sin(yn * 7) * 1.6) > 0.45 and t < 0.92: c = (0.04, 0.08, 0.10)
        return c
    body(M, L, H, W, col, cy, profile=lambda t: prof(t, 0.55, 0.16, 0.2, 0.6))
    tail_fork(M, (0.20, 0.34, 0.36), cy, 7, 4.5)
    fin_tri(M, 'body', (0.18, 0.28, 0.30), 15, 20, int(cy + 4.6), 3)
    fin_tri(M, 'body', (0.18, 0.28, 0.30), 6, 10, int(cy + 3.2), 2)
    for x in (2, 4):                                                # pínnulas
        M.put(x, int(cy + 2.2), -1, 'body', (0.75, 0.70, 0.30)); M.put(x, int(cy + 2.2), 0, 'body', (0.75, 0.70, 0.30))
        M.put(x, int(cy - 2.4), -1, 'body', (0.75, 0.70, 0.30)); M.put(x, int(cy - 2.4), 0, 'body', (0.75, 0.70, 0.30))
    eye(M, L - 5, int(cy + 1), 1, (0.20, 0.20, 0.22), white=(0.78, 0.78, 0.74))
    mouth(M, L - 3, L, int(cy - 1), (0.25, 0.25, 0.28))
    export(M, 'pez_caballa', {'body': [L // 2, cy, 0], 'tail': [0, cy, 0]})


def bacalao():
    M = Model(S, 1603)
    L, H, W, cy = 40, 7.5, 5.0, 12
    sh = shade((0.36, 0.33, 0.20), (0.56, 0.52, 0.38), (0.86, 0.84, 0.74))

    def col(x, yn, zn, t):
        c = sh(yn)
        if yn > -0.1 and M.noise(x, yn * 8, zn * 6, 3) > 0.62: c = scale(c, 0.6)      # motas
        lat = 0.28 - 0.25 * math.sin(math.pi * t)                    # línea lateral clara, en curva
        if abs(yn - lat) < 0.09 and t < 0.9: c = (0.84, 0.82, 0.70)
        return c
    body(M, L, H, W, col, cy, profile=lambda t: prof(t, 0.62, 0.2, 0.3, 0.45))
    tail_fork(M, (0.40, 0.36, 0.24), cy, 7, 5.5, fork=False, edge=(0.30, 0.27, 0.18))
    for a, b, hgt in ((25, 32, 4), (14, 22, 3.5), (5, 12, 3)):        # tres dorsales
        fin_tri(M, 'body', (0.38, 0.34, 0.22), a, b, int(cy + 7.0 * prof((a + b) / 2 / L, 0.62, 0.2, 0.3, 0.45)) - 1, hgt)
    for a, b in ((15, 23), (5, 12)):                                  # dos anales
        fin_tri(M, 'body', (0.62, 0.58, 0.44), a, b, int(cy - 6.5 * prof((a + b) / 2 / L, 0.62, 0.2, 0.3, 0.45)) + 1, 2.5, up=False)
    eye(M, L - 6, int(cy + 2), 1, (0.55, 0.50, 0.30))
    mouth(M, L - 5, L, int(cy - 1), (0.30, 0.24, 0.16))
    for y in range(int(cy - 5), int(cy - 2)):                         # barbillón
        M.put(L - 4, y, -1, 'body', (0.70, 0.66, 0.52)); M.put(L - 4, y, 0, 'body', (0.70, 0.66, 0.52))
    export(M, 'pez_bacalao', {'body': [L // 2, cy, 0], 'tail': [0, cy, 0]})


def platija():
    M = Model(S, 1604)
    L, cy = 30, 4
    TOP, BOT = (0.40, 0.31, 0.20), (0.90, 0.88, 0.84)
    for i in range(L):                                               # un disco plano tumbado
        t = i / (L - 1)
        w = 11.5 * math.sin(math.pi * (0.08 + 0.86 * t)) ** 0.7
        h = 1.2 + 1.3 * math.sin(math.pi * t)
        for z in range(int(-w) - 1, int(w) + 2):
            for y in range(int(cy - h) - 1, int(cy + h) + 2):
                zn, yn = (z + 0.5) / max(1, w), (y + 0.5 - cy) / h
                if zn * zn + yn * yn <= 1.0:
                    c = TOP if yn > -0.2 else BOT
                    if yn > -0.2 and M.noise(i, z, 0, 2.5) > 0.7: c = (0.85, 0.42, 0.16)     # lunares naranjas
                    elif yn > -0.2 and M.noise(i + 40, z, 3, 4) < 0.3: c = scale(TOP, 0.72)
                    M.put(i, y, z, 'body', c)
        fz = w + 1.6                                                 # la orla de aleta alrededor
        for z in (int(-fz) - 1, int(fz)):
            if 2 < i < L - 3: M.put(i, cy, z, 'body', (0.48, 0.38, 0.26))
    for z in range(-4, 4):                                           # cola en abanico, plana
        for i in range(4):
            if abs(z + 0.5) < 2 + i: M.put(-1 - i, cy, z, 'tail', (0.44, 0.34, 0.22))
    for (x, z) in ((L - 6, 3), (L - 4, -1)):                           # los dos ojos arriba, saltones
        M.put(x, cy + 3, z, 'body', (0.85, 0.78, 0.45)); M.put(x, cy + 4, z, 'body', (0.03, 0.03, 0.03))
        M.put(x + 1, cy + 3, z, 'body', (0.85, 0.78, 0.45))
    for z in range(-1, 3): M.put(L - 1, cy, z, 'body', (0.30, 0.22, 0.14))
    export(M, 'pez_platija', {'body': [L // 2, cy, 0], 'tail': [0, cy, 0]})


def anguila():
    M = Model(S, 1605)
    L, H, W, cy = 68, 3.6, 3.0, 6
    sh = shade((0.07, 0.10, 0.08), (0.18, 0.22, 0.15), (0.58, 0.56, 0.36))
    zo = lambda x: int(round(4.0 * math.sin(x / 11.0)))             # en ese, como si nadara
    body(M, L, H, W, lambda x, yn, zn, t: sh(yn), cy, profile=lambda t: 0.45 + 0.55 * min(1, t * 3) if t < 0.95 else 0.7, tail_from=28, zoff=zo)
    for x in range(-4, 44):                                          # aleta continua, por arriba y por abajo
        p = 'tail' if x < 28 else 'body'
        for z in (-1, 0):
            M.put(x, int(cy + 3.4), z + zo(x), p, (0.12, 0.16, 0.11)); M.put(x, int(cy + 4.4), z + zo(x), p, (0.12, 0.16, 0.11))
            if x < 30: M.put(x, int(cy - 3.6), z + zo(x), p, (0.30, 0.30, 0.20))
    for x in range(-4, 0):
        for y in range(int(cy - 3), int(cy + 4)):
            M.put(x, y, -1 + zo(x), 'tail', (0.12, 0.16, 0.11)); M.put(x, y, zo(x), 'tail', (0.12, 0.16, 0.11))
    eye(M, L - 4, int(cy + 1), 1, (0.80, 0.70, 0.30))
    mouth(M, L - 4, L, int(cy - 1), (0.08, 0.08, 0.06))
    export(M, 'pez_anguila', {'body': [L - 20, cy, 0], 'tail': [28, cy, 0]})


# ------------------------------------------------------------------ raros

def rape():
    M = Model(S, 1606)
    L, H, W, cy = 36, 12.0, 11.0, 16
    SK, SK2 = (0.12, 0.10, 0.11), (0.22, 0.18, 0.18)

    def col(x, yn, zn, t):
        c = lerp(SK2, SK, max(0.0, yn))
        if M.noise(x, yn * 9, zn * 9, 2) > 0.7: c = (0.30, 0.24, 0.22)       # verrugas
        return c
    body(M, L, H, W, col, cy, profile=lambda t: 0.25 + 0.75 * t ** 0.6 if t < 0.82 else max(0.55, 1 - (t - 0.82) * 2.2))
    for x in range(L - 9, L + 1):                                    # la boca: un tajo enorme con dientes
        for z in range(-9, 9):
            for y in range(int(cy - 3), int(cy + 1)):
                if (x, y, z) in M.V and (x - (L - 9)) + abs(z) * 0.2 > 2: del M.V[(x, y, z)]
        for z in range(-8, 8, 2):
            if x > L - 7:
                M.put(x, int(cy + 1), z, 'body', (0.86, 0.84, 0.76)); M.put(x, int(cy), z, 'body', (0.86, 0.84, 0.76))
                M.put(x, int(cy - 3), z + 1, 'body', (0.86, 0.84, 0.76)); M.put(x, int(cy - 2), z + 1, 'body', (0.86, 0.84, 0.76))
    for x in range(L - 9, L - 1):
        for z in range(-7, 7):
            M.put(x, int(cy - 2), z, 'body', (0.35, 0.06, 0.08), over=False)    # garganta roja al fondo
    tail_fork(M, SK2, cy, 6, 5, fork=False)
    fin_tri(M, 'body', SK2, 8, 18, int(cy + 9), 3)
    for s in (1, -1):                                                 # aletas pectorales, como manos
        for i in range(5):
            for j in range(4):
                M.put(14 + i, int(cy - 9) + j, s * (9 + i // 2) - (1 if s < 0 else 0), 'body', SK2)
    eye(M, L - 10, int(cy + 6), 1, (0.55, 0.60, 0.50))
    base = (L - 12, int(cy + 11.5))                                   # el farolillo: caña curva y bulbo que brilla
    pts = [(base[0] + int(10 * math.sin(a)), base[1] + int(9 * math.sin(a * 0.9 + 0.3))) for a in [i * 0.12 for i in range(14)]]
    for (x, y) in pts:
        M.put(x, y, -1, 'lure', (0.30, 0.24, 0.22)); M.put(x, y, 0, 'lure', (0.30, 0.24, 0.22))
    lx, ly = pts[-1]
    for dx in range(-2, 3):
        for dy in range(-2, 3):
            for dz in range(-2, 2):
                if dx * dx + dy * dy + (dz + 0.5) ** 2 <= 5.5:
                    M.put(lx + dx + 1, ly + dy, dz, 'lure', (0.78, 0.95, 0.55), glow=1)
    export(M, 'pez_rape', {'body': [L // 2, cy, 0], 'tail': [0, cy, 0], 'lure': [base[0], base[1], 0]})


def ojos():
    M = Model(S, 1607)
    L, H, W, cy = 38, 7.2, 4.6, 11
    SKIN, SK2 = (0.72, 0.64, 0.62), (0.52, 0.48, 0.50)

    def col(x, yn, zn, t):
        c = lerp(SKIN, SK2, max(0.0, yn) * 0.9)
        if M.noise(x, yn * 6, zn * 6, 2) > 0.74: c = (0.56, 0.42, 0.44)      # manchas como de piel
        return c
    body(M, L, H, W, col, cy, profile=lambda t: prof(t, 0.6, 0.2, 0.4, 0.4))
    tail_fork(M, (0.58, 0.52, 0.52), cy, 7, 5, fork=False)
    fin_tri(M, 'body', (0.60, 0.54, 0.54), 12, 24, int(cy + 6.6), 3)
    for s in (1, -1):                                                 # ojos humanos: blanco, iris gris verde, párpado
        for dx in range(-2, 3):
            for dy in range(-2, 2):
                if abs(dx) == 2 and dy in (-2, 1): continue
                x, y = L - 8 + dx, int(cy + 2) + dy
                z = surf_z(M, x, y, s)
                if z is None: continue
                c = (0.90, 0.88, 0.84)
                if abs(dx) <= 1 and dy in (-1, 0): c = (0.36, 0.46, 0.40)
                if dx == 0 and dy in (-1, 0): c = (0.03, 0.03, 0.03)
                M.V[(x, y, z)][1] = c
            z = surf_z(M, L - 8 + dx, int(cy + 2) + 2, s)
            if z is not None: M.V[(L - 8 + dx, int(cy + 2) + 2, z)][1] = (0.38, 0.28, 0.28)    # párpado y pestañas
        z = surf_z(M, L - 7, int(cy + 2), s)
        if z is not None: M.V[(L - 7, int(cy + 2), z)][1] = (0.98, 0.98, 0.96)
    mouth(M, L - 5, L, int(cy - 1), (0.55, 0.30, 0.32))                # labios
    mouth(M, L - 4, L, int(cy - 2), (0.62, 0.40, 0.40))
    export(M, 'pez_ojos', {'body': [L // 2, cy, 0], 'tail': [0, cy, 0]})


# ------------------------------------------------------------------ malditos

def cria():
    M = Model(S, 1608)
    L, cy = 40, 12
    BACK, BELLY, SCALE = (0.10, 0.20, 0.16), (0.56, 0.62, 0.48), (0.16, 0.30, 0.22)

    def p(t):                                                         # renacuajo: cola fina, cabeza bulbosa
        return 0.18 + 0.4 * t if t < 0.55 else min(1.0, 0.4 + (t - 0.55) * 2.4) if t < 0.85 else max(0.6, 1 - (t - 0.85) * 2.6)

    def col(x, yn, zn, t):
        c = lerp(BELLY, BACK, min(1, max(0, yn + 0.3)))
        if yn > -0.2 and (x + int(yn * 6) + int(zn * 6)) % 3 == 0: c = SCALE           # escamas
        return c
    body(M, L, 9.0, 8.0, col, cy, profile=p, tail_from=20)
    for x in range(-6, 26):                                           # cresta de aleta por la cola y el lomo
        f = 1.0 - abs(x - 6) / 22
        for j in range(1, max(1, int(4 * f)) + 1):
            part = 'tail' if x < 20 else 'body'
            yb = int(cy + 9.0 * p(max(0, min(1, x / (L - 1))))) + j - 1 if x >= 0 else int(cy) + j
            M.put(x, yb, -1, part, (0.26, 0.40, 0.34), over=False); M.put(x, yb, 0, part, (0.26, 0.40, 0.34), over=False)
    for x in range(-6, 0):
        for y in range(int(cy - 3), int(cy + 3)):
            M.put(x, y, -1, 'tail', (0.26, 0.40, 0.34)); M.put(x, y, 0, 'tail', (0.26, 0.40, 0.34))
    for x in range(26, 34, 3):                                         # púas en la nuca
        for j in range(3):
            M.put(x - j // 2, int(cy + 8) + j, -1, 'body', (0.70, 0.68, 0.52)); M.put(x - j // 2, int(cy + 8) + j, 0, 'body', (0.70, 0.68, 0.52))
    for s in (1, -1):                                                 # bracitos con manos palmeadas
        z0 = 6 if s > 0 else -7
        for i in range(6):
            M.put(28 + i // 2, int(cy - 5) - i, z0 + s * (i // 3), 'body', BACK)
        for f in range(-1, 2):
            for j in range(3):
                M.put(30 + f * 2, int(cy - 11) - j, z0 + s, 'body', (0.70, 0.68, 0.52) if j == 2 else (0.22, 0.36, 0.28))
        for f in range(-2, 3):
            M.put(30 + f, int(cy - 11), z0 + s, 'body', (0.30, 0.46, 0.38))
    for y in range(int(cy - 2), int(cy + 3)):                         # agallas
        for s in (1, -1):
            z = surf_z(M, 27, y, s)
            if z is not None and y % 2 == 0: M.V[(27, y, z)][1] = (0.45, 0.10, 0.12)
    eye(M, L - 6, int(cy + 3), 2, (0.95, 0.80, 0.20), glow=1, pupil=(0.05, 0.04, 0.02))
    mouth(M, L - 6, L, int(cy - 3), (0.05, 0.05, 0.05))
    export(M, 'pez_cria', {'body': [30, cy, 0], 'tail': [20, cy, 0]})


def mano():
    M = Model(S, 1609)
    SC, SC2, WEB, CLAW, MEAT = (0.20, 0.30, 0.26), (0.30, 0.40, 0.32), (0.26, 0.38, 0.34), (0.82, 0.80, 0.66), (0.40, 0.08, 0.08)
    cy = 5

    def scl(x, y, z):
        return SC2 if (x + y * 2 + z) % 4 == 0 else SC
    for x in range(0, 16):                                            # palma: un bloque plano, algo combado
        for z in range(-8, 8):
            th = 3 if abs(z + 0.5) < 6 else 2
            for y in range(cy - th // 2, cy + th - th // 2 + int(abs(z + 0.5) > 5)):
                M.put(x, y, z, 'body', scl(x, y, z))
    for x in range(-6, 0):                                            # muñeca arrancada
        for z in range(-5, 5):
            for y in range(cy - 2, cy + 3):
                if (x + 6) * 0.5 + abs(z + 0.5) * 0.25 > 0.6 or True:
                    M.put(x, y, z, 'body', MEAT if x == -6 or (y + z) % 3 == 0 else scl(x, y, z))
    for z in range(-4, 4):
        M.put(-7, cy, z, 'body', (0.85, 0.82, 0.72))                 # hueso
    fingers = [(-7, 16, 0.25), (-3, 20, 0.08), (1, 21, -0.05), (5, 18, -0.2)]
    tips = []
    for (z0, length, ang) in fingers:                                  # cuatro dedos largos, abiertos
        for i in range(length):
            x = 15 + i
            z = z0 + int(-ang * i)
            curl = int(max(0, i - length * 0.6) * 0.5)
            for dz in (0, 1):
                for y in (cy - curl, cy + 1 - curl):
                    M.put(x, y, z + dz, 'body', scl(x, y, z))
        tips.append((15 + length, z0 + int(-ang * length), cy - int(max(0, length * 0.4) * 0.5)))
        for k in range(4):                                             # garra
            M.put(15 + length + k, tips[-1][2] - k // 2, tips[-1][1], 'body', CLAW)
            M.put(15 + length + k, tips[-1][2] - k // 2, tips[-1][1] + 1, 'body', CLAW)
    for a in range(len(fingers) - 1):                                  # membranas entre los dedos
        z0, l0, a0 = fingers[a]; z1, l1, a1 = fingers[a + 1]
        for i in range(int(min(l0, l1) * 0.7)):
            za, zb = z0 + int(-a0 * i) + 2, z1 + int(-a1 * i)
            for z in range(za, zb):
                M.put(15 + i, cy, z, 'body', WEB, over=False)
    for i in range(10):                                               # pulgar
        M.put(8 + i // 2, cy, -9 - i, 'body', SC); M.put(8 + i // 2, cy + 1, -9 - i, 'body', SC)
    for k in range(3): M.put(13 + k, cy, -19, 'body', CLAW)
    for x in range(4, 14, 3):                                         # algas enredadas
        for z in (-2, 3):
            M.put(x, cy + 2, z, 'body', (0.20, 0.28, 0.10)); M.put(x + 1, cy + 2, z + 1, 'body', (0.24, 0.32, 0.12))
    export(M, 'pez_mano', {'body': [10, cy, 0]})


if __name__ == '__main__':
    for f in (arenque, caballa, bacalao, platija, anguila, rape, ojos, cria, mano):
        f()
