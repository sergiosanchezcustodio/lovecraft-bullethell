"""Fauna del ambiente de los escenarios (16-10-2026): aves y murciélagos que cruzan el cielo sin
ser enemigos (scripts/level/ambient.gd las mueve y bate las alas). 32 voxels/m, mirando a -Z, alas
a lo largo de X con el pivote en el hombro (partes body, wing_l y wing_r).

  python tools/gen_fauna_ambiente.py            # todas: models/amb_<especie>.json
  python tools/gen_fauna_ambiente.py gull bat

Especies: petrel (petrel de las nieves, blanco: nivel 1), skua (págalo pardo con la mancha blanca
del ala: Lake), gull (gaviota argéntea: Innsmouth, el muelle, la tormenta), crow (cuervo: la
carretera) y bat (murciélago: las noches de Innsmouth, el pantano y el ritual).
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model

OUT = os.path.join(os.path.dirname(__file__), '..', 'models')


def lerp(a, b, t): return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def bird(name, size, back, belly, head, wing_top, wing_tip, beak, eye=(0.04, 0.04, 0.04),
         tip_len=0.25, fingers=False, patch=None, tail_fan=False):
    """Ave en vuelo. size: escala (1 = gaviota, ~1,1 m de envergadura)."""
    M = Model(S=2, seed=hash(name) % 1000)
    s = size
    L = int(7 * s); W = max(2, int(2.4 * s)); H = max(2, int(2.2 * s))
    # cuerpo: huso de -L (pecho) a +L (rabadilla)
    for z in range(-L, L + 1):
        u = z / L
        rw = W * math.sqrt(max(0.0, 1 - (u * 0.92) ** 2)) + 0.4
        rh = H * math.sqrt(max(0.0, 1 - (u * 0.92) ** 2)) + 0.4
        for x in range(-W - 1, W + 2):
            for y in range(-H - 1, H + 2):
                if (x / rw) ** 2 + (y / rh) ** 2 <= 1.0:
                    c = back if y > 0 else belly
                    M.put(x, y, z, 'body', c)
    # cabeza
    hz = -L - int(1.5 * s); hr = max(1.6, 2.0 * s)
    for x in range(-3, 4):
        for y in range(-3, 4):
            for z in range(hz - 3, hz + 4):
                if x * x + (y - 0.6) ** 2 + (z - hz) ** 2 <= hr * hr:
                    M.put(x, y + 1, z, 'body', head)
    for e in (-1, 1):                                                  # ojos
        M.put(e * int(hr), 2, hz - 1, 'body', eye)
    for k in range(max(2, int(2.2 * s))):                               # pico
        M.put(0, 1, hz - int(hr) - 1 - k, 'body', beak)
        if k == 0: M.put(0, 0, hz - int(hr) - 1, 'body', beak)
    # cola
    tl = max(3, int(4 * s))
    for k in range(tl):
        half = 1 + (k * (2 if tail_fan else 1)) // 3
        for x in range(-half, half + 1):
            M.put(x, 0, L + 1 + k, 'body', back if k < tl - 1 or not tail_fan else wing_tip)
    # alas: del hombro (x = W) a la punta, cuerda que se estrecha, dos voxels de grueso
    span = int(17 * s); chord0 = max(5, int(7 * s))
    for side, part in ((1, 'wing_r'), (-1, 'wing_l')):
        for i in range(span):
            u = i / span
            chord = max(1, round(chord0 * (1 - 0.75 * u ** 1.2)))
            # borde de ataque: el brazo algo adelantado y la mano echada hacia atrás (en flecha)
            lead = -int(2 * s) - round(1.2 * s * math.sin(min(u, 0.4) / 0.4 * math.pi / 2)) + round(5.5 * s * max(0.0, u - 0.4) ** 1.3)
            elbow = 1 if 0.25 < u < 0.55 else 0                          # codo algo alto (gaviota)
            for j in range(chord):
                if fingers and u > 0.78 and j % 2 == 1 and j < chord - 1: continue   # plumas abiertas
                z = lead + j
                tip = u > 1 - tip_len
                col = wing_tip if tip else wing_top
                if patch and abs(u - patch[0]) < patch[1]: col = patch[2]
                x = side * (W + 1 + i)
                M.put(x, elbow, z, part, col)
                if j < chord - 1 or chord < 3: M.put(x, elbow - 1, z, part, lerp(col, belly, 0.5) if not tip else col)
    pivots = {'body': [0, 0, 0], 'wing_r': [W + 1, 0, 0], 'wing_l': [-(W + 1), 0, 0]}
    n = M.export(os.path.join(OUT, 'amb_%s.json' % name), pivots, pivots_in_voxels=True, roughness=0.9, specular=0.2)
    print('amb_%s: %d voxels' % (name, n))


def bat(name='bat'):
    """Murciélago: cuerpo peludo pequeño, orejas y alas de membrana entre dedos más claros."""
    M = Model(S=2, seed=7)
    FUR = (0.20, 0.15, 0.12); FUR_D = (0.13, 0.10, 0.09); MEM = (0.15, 0.10, 0.10); BONE = (0.26, 0.19, 0.16)
    for z in range(-4, 5):
        u = z / 4.5
        r = 2.2 * math.sqrt(max(0.0, 1 - u * u)) + 0.4
        for x in range(-3, 4):
            for y in range(-3, 4):
                if (x / r) ** 2 + (y / (r * 0.85)) ** 2 <= 1: M.put(x, y, z, 'body', FUR if y > 0 else FUR_D)
    for x in range(-2, 3):
        for y in range(-1, 3):
            for z in range(-8, -4):
                if x * x + (y - 0.5) ** 2 + (z + 6) ** 2 <= 4.5: M.put(x, y, z, 'body', FUR)
    for e in (-1, 1):
        for k in range(2): M.put(e * (1 + k // 2), 3 + k, -6, 'body', FUR_D)    # orejas
        M.put(e, 1, -8, 'body', (0.55, 0.45, 0.2))                               # ojos que brillan poco
    span = 14
    for side, part in ((1, 'wing_r'), (-1, 'wing_l')):
        for i in range(span):
            u = i / span
            # borde de salida festoneado entre dedos
            fing = abs(math.sin(u * math.pi * 3.0))
            chord = max(2, round(7.5 * (1 - 0.5 * u) * (0.78 + 0.22 * fing)))
            for j in range(chord):
                z = -2 + int(2 * u) + j
                bone = j == 0 or (i in (4, 8, 12) and j < chord - 1)
                M.put(side * (3 + i), 0, z, part, BONE if bone else MEM)
    pivots = {'body': [0, 0, 0], 'wing_r': [3, 0, 0], 'wing_l': [-3, 0, 0]}
    n = M.export(os.path.join(OUT, 'amb_%s.json' % name), pivots, pivots_in_voxels=True, roughness=0.85, specular=0.2)
    print('amb_%s: %d voxels' % (name, n))


WHITE = (0.92, 0.93, 0.94); GREY = (0.60, 0.65, 0.70); BLACK = (0.06, 0.06, 0.07); YEL = (0.85, 0.70, 0.20)
SPECIES = {
    # petrel damero (el de las nieves, todo blanco, no se veía sobre la nieve): cabeza y alas oscuras con manchas blancas
    'petrel': lambda: bird('petrel', 0.8, (0.18, 0.18, 0.20), WHITE, (0.14, 0.14, 0.16), (0.20, 0.20, 0.22), (0.12, 0.12, 0.14), BLACK,
                           tip_len=0.15, patch=(0.5, 0.14, (0.90, 0.90, 0.88))),
    'skua': lambda: bird('skua', 1.05, (0.30, 0.24, 0.18), (0.40, 0.33, 0.25), (0.26, 0.21, 0.16), (0.28, 0.22, 0.17),
                         (0.20, 0.16, 0.12), (0.12, 0.11, 0.10), patch=(0.72, 0.06, (0.85, 0.83, 0.78))),
    'gull': lambda: bird('gull', 1.0, GREY, WHITE, WHITE, GREY, BLACK, YEL, tip_len=0.2),
    'crow': lambda: bird('crow', 0.85, (0.08, 0.08, 0.10), (0.07, 0.07, 0.09), (0.08, 0.08, 0.10), (0.09, 0.09, 0.12),
                         (0.06, 0.06, 0.08), (0.10, 0.10, 0.11), eye=(0.25, 0.22, 0.18), fingers=True, tail_fan=True),
    'bat': bat,
}

if __name__ == '__main__':
    for k in (sys.argv[1:] or list(SPECIES)):
        SPECIES[k]()
