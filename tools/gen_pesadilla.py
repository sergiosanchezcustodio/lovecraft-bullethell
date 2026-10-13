"""Pesadillas de la oleada de sueños (fase 7, hito 7.1). En el juego son semitransparentes
(`EnemyData.ethereal`) y atraviesan el decorado.

  pesadilla           figura encorvada envuelta en sombra violeta que se deshilacha en jirones
                      por abajo (no tiene piernas: flota), brazos largos y finos con garras y una
                      cara hueca con cinco ojos verdes que brillan
  pesadilla_relieve   "la pesadilla del bajorrelieve" (evento final): la pesadilla con cabeza de
                      pulpo (la figura del bajorrelieve de Wilcox) y alas de murciélago detalladas
                      (revisión de arte, 13-10-2026); en el juego, a 1,8

32 voxels/m (S=2). Partes: body, head, arm_l, arm_r. Animaciones: scripts/anim/anim_pesadilla.gd.
Uso: python tools/gen_pesadilla.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

B, HD, AL, AR = 'body', 'head', 'arm_l', 'arm_r'
INK = (0.16, 0.10, 0.24); INK_L = (0.30, 0.20, 0.42); INK_D = (0.08, 0.05, 0.12)
EYE = (0.55, 1.0, 0.55); VOID = (0.02, 0.01, 0.03)
CLAW = (0.70, 0.66, 0.80)
WING = (0.22, 0.13, 0.30); WING_D = (0.12, 0.07, 0.17); VEIN = (0.36, 0.22, 0.44)   # alas del bajorrelieve
TENT = (0.34, 0.26, 0.40); TENT_L = (0.50, 0.42, 0.56)                # tentáculos, más claros que el sudario
BONE = (0.56, 0.52, 0.62); BONE_D = (0.36, 0.32, 0.42)                # manos huesudas
TEETH = (0.66, 0.63, 0.58); TEETH_D = (0.34, 0.03, 0.08)


def wisp(M, x0, z0, y_top, length, seed):
    """Jirón de sombra que cuelga y se adelgaza."""
    for k in range(length):
        y = y_top - k
        r = max(0.6, 2.4 * (1 - k / length))
        dx = math.sin(k * 0.35 + seed) * 1.5
        for x in range(-3, 4):
            for z in range(-3, 4):
                if x * x + z * z <= r * r:
                    M.put(int(x0 + dx + x), y, int(z0 + z), B, INK_D if k % 4 else INK)


def shroud(M):
    # cuerpo: un sudario encorvado que flota (de 0,4 a 1,7 m)
    M.ell(0, 36 / 2, 0, 9 / 2, 16 / 2, 7 / 2, B, INK)
    M.ell(0, 48 / 2, 2 / 2, 11 / 2, 8 / 2, 8 / 2, B, INK)            # hombros adelantados
    for i in range(9):                                               # jirones por abajo
        a = i / 9 * math.tau
        wisp(M, 6 * math.cos(a), 5 * math.sin(a), 24, 12 + (i % 3) * 4, i)


def bony_arms(M):
    # brazos largos y flacos; manos huesudas con dedos muy largos de nudillos marcados
    for s, A in ((-1, AL), (1, AR)):
        M.capsule((s * 10 / 2, 50 / 2, 2 / 2), (s * 14 / 2, 32 / 2, 8 / 2), 2.2 / 2, 1.5 / 2, A, INK)
        M.capsule((s * 14 / 2, 32 / 2, 8 / 2), (s * 15 / 2, 22 / 2, 11 / 2), 1.3 / 2, 1.0 / 2, A, BONE_D)   # muñeca: hueso
        wx, wy, wz = s * 15, 22, 11
        M.ell(wx / 2, (wy - 2) / 2, (wz + 1) / 2, 2.0 / 2, 2.4 / 2, 1.6 / 2, A, BONE)          # dorso de la mano, estrecho
        for f, (spread, ln) in enumerate(((-1.6, 13), (-0.5, 16), (0.6, 15), (1.6, 12))):
            px, py, pz = wx + spread * 0.8, wy - 4, wz + 1
            for k in range(ln):                                      # falanges: caen y se curvan hacia dentro
                t = k / ln
                x = px + spread * 0.35 * k * (1 - t) + s * 0.0
                y = py - k * (1 - 0.35 * t * t)
                z = pz + 0.25 * k + 3.5 * t * t
                knuckle = k in (ln // 3, 2 * ln // 3)
                M.put(int(round(x)), int(round(y)), int(round(z)), A, BONE_D if knuckle else BONE)
                if knuckle: M.put(int(round(x)) + s, int(round(y)), int(round(z)), A, BONE_D)
            M.put(int(round(x)), int(round(y)) - 1, int(round(z)) + 1, A, CLAW)   # uña afilada
        for k in range(8):                                           # pulgar, hacia delante
            M.put(int(round(wx - s * 1.5)), wy - 3 - k, wz + 3 + k // 2, A, BONE if k != 4 else BONE_D)


def pesadilla():
    M = Model(S=2, seed=1931)
    shroud(M)
    # cabeza hueca con cinco ojos
    M.ell(0, 60 / 2, 5 / 2, 6 / 2, 6 / 2, 6 / 2, HD, INK)
    for x in range(-5, 5):                                           # cara: hueco negro, alargado
        for y in range(53, 66):
            if ((x + 0.5) ** 2) / 22 + ((y - 59.5) ** 2) / 42 <= 1: M.put(x, y, 10, HD, VOID); M.put(x, y, 11, HD, VOID, over=False)
    # ojos: dos rendijas finas inclinadas hacia dentro (ceño) y un tercero pequeño en la frente
    for s_ in (-1, 1):
        for i in range(3):
            x = s_ * (2 + i) - (1 if s_ > 0 else 0)
            y = 60 + i
            M.put(x, y, 11, HD, EYE, glow=1); M.put(x, y, 12, HD, EYE, glow=1)
    M.put(-1, 64, 11, HD, EYE, glow=1); M.put(-1, 64, 12, HD, EYE, glow=1)
    # sonrisa ancha y torcida de agujas, hundida en el hueco, que sube en las comisuras
    for x in range(-5, 5):
        e = abs(x + 0.5)
        cy = 55 + (1 if e > 2.5 else 0) + (1 if e > 3.6 else 0)
        M.put(x, cy, 11, HD, TEETH_D)
        if e < 4: M.put(x, cy + 1 if x % 2 == 0 else cy - 1, 11, HD, TEETH)
    bony_arms(M)
    _shade(M)
    piv = {B: [0, 0, 0], HD: [0, 54, 4], AL: [-10, 50, 2], AR: [10, 50, 2]}
    return M, piv


def bat_wing(M, s):
    """Ala de murciélago en el plano de la espalda: húmero y antebrazo, cuatro dedos largos que
    se abren desde la muñeca, membrana festoneada entre las puntas con venas y algún desgarrón,
    y la garra del pulgar en la muñeca. (u hacia fuera, v hacia arriba, desde el hombro)."""
    ROOT, ELB, WR = (0, 0), (8, 11), (16, 15)
    TIPS = [(35, 20), (33, 5), (27, -8), (18, -15)]
    BODY = (0, -12)
    def place(u, v, col, glow=0, over=False):
        x = s * (6 + u); y = 48 + v; z = -6 - u * 0.3
        M.put(int(round(x)), int(round(y)), int(round(z)), B, col, glow, over)
        M.put(int(round(x)), int(round(y)), int(round(z)) - 1, B, WING_D, 0, False)
    def tri(p, a, b, scallop):
        """Rellena el triángulo p-a-b; si scallop, el borde a-b se curva hacia dentro."""
        (x1, y1), (x2, y2), (x3, y3) = p, a, b
        d = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
        for u in range(int(min(x1, x2, x3)) - 1, int(max(x1, x2, x3)) + 2):
            for v in range(int(min(y1, y2, y3)) - 1, int(max(y1, y2, y3)) + 2):
                l1 = ((y2 - y3) * (u - x3) + (x3 - x2) * (v - y3)) / d
                l2 = ((y3 - y1) * (u - x3) + (x1 - x3) * (v - y3)) / d
                l3 = 1 - l1 - l2
                if min(l1, l2, l3) < 0: continue
                if scallop:
                    t = l3 / max(l2 + l3, 1e-6)                       # posición a lo largo del borde a-b
                    if l1 < 0.28 * math.sin(math.pi * t): continue    # festón
                if M.hsh(u * 7 + s, v, 3) < 0.035: continue          # desgarrones
                place(u, v, WING)
    for i in range(len(TIPS) - 1): tri(WR, TIPS[i], TIPS[i + 1], True)
    tri(WR, TIPS[-1], BODY, True)
    tri(ROOT, WR, BODY, False)
    tri(ROOT, ELB, WR, False)
    def bone(a, b, col, thick=1):
        n = int(max(abs(b[0] - a[0]), abs(b[1] - a[1])) * 2) + 1
        for q in range(n + 1):
            t = q / n
            u, v = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t
            x = s * (6 + u); y = 48 + v; z = -6 - u * 0.3 + 1
            for dy in range(thick): M.put(int(round(x)), int(round(y)) + dy, int(round(z)), B, col)
    for i in range(len(TIPS) - 1):                                    # venas: de la muñeca a media membrana
        m = ((TIPS[i][0] + TIPS[i + 1][0]) / 2, (TIPS[i][1] + TIPS[i + 1][1]) / 2)
        bone(WR, (WR[0] + (m[0] - WR[0]) * 0.75, WR[1] + (m[1] - WR[1]) * 0.75), VEIN)
    bone(ROOT, ELB, BONE_D, 2); bone(ELB, WR, BONE_D, 2)
    for t_ in TIPS: bone(WR, t_, BONE_D)
    for t_ in TIPS: bone(t_, (t_[0] + 1.5, t_[1] - 1.5), CLAW)       # garfio en cada punta
    bone(WR, (WR[0] - 1, WR[1] + 5), BONE_D); bone((WR[0] - 1, WR[1] + 5), (WR[0] - 3, WR[1] + 7), CLAW)   # pulgar


def relieve():
    """La pesadilla del bajorrelieve: el mismo sudario y las mismas manos huesudas que la
    pesadilla, con cabeza de pulpo (la figura del bajorrelieve de Wilcox) y alas de murciélago."""
    M = Model(S=2, seed=1932)
    shroud(M)
    for s_ in (-1, 1): bat_wing(M, s_)
    # cabeza de pulpo: manto alto que cae hacia atrás, cara con ojos rasgados y tentáculos
    M.ell(0, 60 / 2, 5 / 2, 7 / 2, 6.5 / 2, 6.5 / 2, HD, INK)
    M.capsule((0, 63 / 2, 3 / 2), (0, 72 / 2, -12 / 2), 7.5 / 2, 4.5 / 2, HD, INK, over=False)   # manto liso hacia atrás
    for s_ in (-1, 1):                                               # ojos rasgados, hundidos bajo un ceño
        for i in range(4):
            x = s_ * (2 + i) - (1 if s_ > 0 else 0)
            y = 62 + (i + 1) // 2
            z = M.front(x, y, 30, 0)
            if z is None: continue
            M.put(x, y + 1, z + 1, HD, INK_D)                         # ceño
            M.V[(x, y, z)] = [HD, VOID, 0]
            if i in (1, 2, 3): M.put(x, y, z, HD, EYE, glow=1); M.put(x, y - 1, z, HD, EYE, glow=1) if i == 2 else None
    for i in range(9):                                               # tentáculos de la cara, de la nariz al pecho
        x0 = -5 + i * 10 / 8
        n = 16 + (i % 3) * 3
        for k in range(n):
            t = k / n
            x = x0 + math.sin(k * 0.45 + i) * 1.1 + (x0 * 0.05) * k
            y = 59 - k
            z = 11 + k // 4 + (1 if i % 2 else 0)
            r = 1.6 * (1 - t) + 0.6
            M.ell(x / 2, y / 2, z / 2, r / 2, 0.5, r / 2, HD, TENT if k % 4 else TENT_L)
            if k == n - 1 and i % 2 == 0: M.put(x, y, z, HD, EYE, glow=1)
    bony_arms(M)
    _shade(M)
    piv = {B: [0, 0, 0], HD: [0, 54, 4], AL: [-10, 50, 2], AR: [10, 50, 2]}
    return M, piv


def _shade(M):
    """Escamas y vetas: claro arriba, se oscurece hacia los jirones."""
    for (x, y, z), v in list(M.V.items()):
        if v[1] != INK: continue
        c = lerp(INK_D, INK_L, min(1.0, max(0.0, (y - 20) / 50.0)) * 0.8 + 0.2 * M.noise(x, y, z, 4.0))
        if (x + y * 2 + z) % 7 == 0: c = INK_L
        M.V[(x, y, z)] = [v[0], c, v[2]]


for name, fn in (('pesadilla', pesadilla), ('pesadilla_relieve', relieve)):
    M, piv = fn()
    n = M.export('models/%s.json' % name, piv, jitter=0.01, pivots_in_voxels=True, roughness=0.6, specular=0.3,
                 parents={HD: B, AL: B, AR: B})
    print(name, n, 'voxels')
