"""Pesadillas de la oleada de sueños (fase 7, hito 7.1). En el juego son semitransparentes
(`EnemyData.ethereal`) y atraviesan el decorado.

  pesadilla           figura encorvada envuelta en sombra violeta que se deshilacha en jirones
                      por abajo (no tiene piernas: flota), brazos largos y finos con garras y una
                      cara hueca con cinco ojos verdes que brillan
  pesadilla_relieve   "la pesadilla del bajorrelieve" (evento final): la figura del bajorrelieve
                      de Wilcox hecha sueño, con cabeza de pulpo, tentáculos, alas membranosas
                      y cuerpo escamoso; violeta y verde, más grande (en el juego, a 1,8)

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


def pesadilla():
    M = Model(S=2, seed=1931)
    # cuerpo: un sudario encorvado que flota (de 0,4 a 1,7 m)
    M.ell(0, 36 / 2, 0, 9 / 2, 16 / 2, 7 / 2, B, INK)
    M.ell(0, 48 / 2, 2 / 2, 11 / 2, 8 / 2, 8 / 2, B, INK)            # hombros adelantados
    for i in range(9):                                               # jirones por abajo
        a = i / 9 * math.tau
        wisp(M, 6 * math.cos(a), 5 * math.sin(a), 24, 12 + (i % 3) * 4, i)
    # cabeza hueca con cinco ojos
    M.ell(0, 60 / 2, 5 / 2, 6 / 2, 6 / 2, 6 / 2, HD, INK)
    for x in range(-4, 5):                                           # cara: hueco negro
        for y in range(56, 65):
            if (x * x) / 16 + ((y - 60) ** 2) / 20 <= 1: M.put(x, y, 10, HD, VOID); M.put(x, y, 11, HD, VOID, over=False)
    for x, y in ((-3, 62), (2, 62), (-1, 59), (3, 58), (-4, 58)):    # ojos
        M.put(x, y, 11, HD, EYE, glow=1); M.put(x, y, 12, HD, EYE, glow=1)
    # brazos largos y finos con garras
    for s, A in ((-1, AL), (1, AR)):
        M.capsule((s * 10 / 2, 50 / 2, 2 / 2), (s * 14 / 2, 30 / 2, 8 / 2), 2.2 / 2, 1.6 / 2, A, INK)
        M.capsule((s * 14 / 2, 30 / 2, 8 / 2), (s * 15 / 2, 16 / 2, 12 / 2), 1.6 / 2, 1.2 / 2, A, INK)
        for f in range(3):
            M.cone((s * 15 / 2, 16 / 2, 12 / 2), (s * (14 + f) / 2, 8 / 2, (14 + f * 2) / 2), 0.9 / 2, A, CLAW, CLAW, tip_r=0.5)
    _shade(M)
    piv = {B: [0, 0, 0], HD: [0, 54, 4], AL: [-10, 50, 2], AR: [10, 50, 2]}
    return M, piv


def relieve():
    """La figura del bajorrelieve: cabeza de pulpo, tentáculos, alas y cuerpo escamoso."""
    M = Model(S=2, seed=1932)
    M.sell(0, 34 / 2, 0, 10 / 2, 16 / 2, 8 / 2, B, INK, p=2.4)       # cuerpo escamoso
    for i in range(10):
        a = i / 10 * math.tau
        wisp(M, 7 * math.cos(a), 5 * math.sin(a), 22, 12 + (i % 3) * 4, i)
    for s in (-1, 1):                                                # alas membranosas
        for i in range(18):
            for j in range(0, 22 - i):
                c = INK_D if (i % 4 == 0) else INK_L
                M.put(s * (8 + i), 40 + j - i // 3, -8 - i // 3, B, c, over=False)
    M.ell(0, 60 / 2, 3 / 2, 8 / 2, 9 / 2, 8 / 2, HD, INK)            # cabeza de pulpo
    for x, y in ((-3, 63), (3, 63)):
        for dx in (0, 1): M.put(x + dx, y, 11, HD, EYE, glow=1); M.put(x + dx, y + 1, 11, HD, EYE, glow=1)
    for i in range(8):                                               # tentáculos de la cara
        x0 = -6 + i * 12 / 7
        for k in range(18):
            M.put(int(x0 + math.sin(k * 0.5 + i) * 1.2), 56 - k, 9 + k // 5, HD, INK_L if k % 3 else EYE, glow=1 if k % 3 == 0 and k > 10 else 0)
    for s, A in ((-1, AL), (1, AR)):
        M.capsule((s * 12 / 2, 46 / 2, 2 / 2), (s * 16 / 2, 28 / 2, 8 / 2), 2.6 / 2, 2.0 / 2, A, INK)
        M.capsule((s * 16 / 2, 28 / 2, 8 / 2), (s * 16 / 2, 14 / 2, 12 / 2), 2.0 / 2, 1.4 / 2, A, INK)
        for f in range(3):
            M.cone((s * 16 / 2, 14 / 2, 12 / 2), (s * (15 + f) / 2, 6 / 2, (14 + f * 2) / 2), 1.0 / 2, A, CLAW, CLAW, tip_r=0.5)
    _shade(M)
    piv = {B: [0, 0, 0], HD: [0, 52, 2], AL: [-12, 46, 2], AR: [12, 46, 2]}
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
