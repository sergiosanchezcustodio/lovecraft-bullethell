"""Muestra del "aspecto de Innsmouth" (hito 6.0): el mismo vecino del puerto en los grados
0 a 3 (models/innsmouth_g0..g3.json), para revisar la transformación junta.
Pescador de los años 20: gorra de lana, jersey de pescador, pantalón de faena con tirantes y
botas de goma. Cuanto más avanzado, más rota y empapada la ropa (y en el 3, descalzo).
Uso: python tools/gen_innsmouth_muestra.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

JERSEY = (0.30, 0.33, 0.38); JERSEY_SH = (0.24, 0.27, 0.31)
TROUSER = (0.30, 0.27, 0.20); STRAP = (0.20, 0.15, 0.10)
BOOT = (0.12, 0.13, 0.12); SOLE = (0.07, 0.07, 0.07)
CAP = (0.22, 0.24, 0.22); CAP_SH = (0.17, 0.19, 0.17)
SKIN = (0.84, 0.70, 0.60); SKIN_SH = (0.74, 0.60, 0.51)
HAIR = (0.30, 0.25, 0.20)
WET = 0.8                                             # oscurecimiento de la ropa empapada


def build(g):
    M = cu.new(1931 + g)
    wet = WET if g >= 2 else 1.0
    jersey = tuple(c * wet for c in JERSEY); trouser = tuple(c * wet for c in TROUSER)
    if g >= 3:                                        # descalzo: pies palmeados
        for s, _, shin, _, _ in cu.sides():
            slab(M, shin, SKIN, 0, 3, 5 * s, 2.5, 9, 8, 17, 14, ch=1)
        top = 3
    else:
        top = cu.boots(M, BOOT, SOLE, top=12)
    cu.legs(M, trouser, bottom=top)
    cu.torso(M, jersey, b=1, bottom=36)
    for x in (-7, 6):                                 # tirantes
        for y in range(44, 61): cu.front(M, x, y, STRAP); cu.back(M, x, y, STRAP)
    for y in range(36, 61, 3):                        # punto del jersey: canalé pintado
        for x in range(-11, 11, 2): cu.front(M, x, y, JERSEY_SH)
    slab(M, T, jersey, 60, 63, 0, 0, 12, 11, 11, 10, ch=1)   # cuello vuelto
    cu.neck(M, SKIN)
    cu.arms(M, jersey, SKIN, b=1, cuff=JERSEY_SH)
    cu.head(M, SKIN, SKIN_SH)
    if g >= 2:                                        # rotos: la piel asoma por el jersey y el pantalón
        for (x, y, z), v in M.V.items():
            if v[1] in (jersey, trouser) and M.noise(x, y, z, 2.0) > 0.84: v[1] = SKIN_SH
    s, sh = cu.innsmouth(M, g, SKIN, SKIN_SH)
    if g <= 1:                                        # gorra de lana y pelo (en el 1, ralo)
        slab(M, H, CAP, 78, 83, 0, -0.5, 16, 15, 16, 15, ch=2)
        slab(M, H, CAP_SH, 77, 78, 0, 8.5, 10, 10, 2, 2, ch=1)
        cu.hair_back(M, s if g else SKIN, HAIR, top=78)
    cu.finish(M, 'innsmouth_g%d' % g, {jersey: 'lana', JERSEY_SH: 'lana', trouser: 'lana', CAP: 'lana',
                                       CAP_SH: 'lana', BOOT: 'cuero', SOLE: 'cuero', HAIR: 'pelo'},
              flat=(cu.FISH_EYE, cu.FISH_PUPIL), b=1, hat=(CAP, CAP_SH))


for g in range(4): build(g)
