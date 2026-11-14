"""Criaturas de la parte 4, *La búsqueda onírica de la desconocida Kadath* (hito 21.10).

Nivel 1, el bosque encantado:
  zoog          pequeño y furtivo, pardo, de pelo ralo y a mechones, con un manojo de tentáculos cortos
                y rosados en el hocico, orejas redondas, ojos grandes que brillan amarillos y una cola
                larga y pelada (anim_cuadrupedo: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail;
                mira hacia +Z). 0,5 m de largo a 32/m
  zoog_copas    el que vive en lo alto de los robles: el pelo verdoso de musgo, las garras largas y
                claras para trepar
  zoog_anciano  el anciano del consejo de los zoogs (jefe del nivel 1, escalado): el pelo gris, los
                tentáculos largos y blancos, una ristra de setas que brillan colgada al cuello

Escribe models/<nombre>.json. Uso: python tools/gen_criaturas_sueno.py [nombres…]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import cuerpo as cu
from cuerpo import slab, H

B = 'body'
LEGS = ('leg_fl', 'leg_fr', 'leg_bl', 'leg_br')


# ---------------- los zoogs ----------------

def _zoog(name, seed, fur, fur_d, tent, claw, eye, beard=None, pendant=False):
    M = cu.new(seed)
    # patas cortas, con garras
    for part, x, z in (('leg_fl', -3, 5), ('leg_fr', 3, 5), ('leg_bl', -3, -5), ('leg_br', 3, -5)):
        slab(M, part, fur_d, 1, 6, x, z, 3, 3, 3, 3, ch=0)
        for dx in (-1, 0, 1): M.put(x + dx, 0, z + 2, part, claw)
        slab(M, part, fur_d, 0, 1, x, z, 3, 3, 3, 3, ch=0)
    slab(M, B, fur, 5, 13, 0, 0, 9, 8, 15, 14, ch=2)                         # el cuerpo, encorvado
    slab(M, B, fur, 12, 14, 0, -1, 7, 5, 10, 8, ch=2)                        # la joroba
    slab(M, H, fur, 7, 15, 0, 10, 9, 8, 8, 7, ch=2)                          # la cabeza
    slab(M, H, fur_d, 7, 11, 0, 14, 5, 5, 3, 3, ch=1)                        # el hocico
    for s in (-1, 1):                                                       # orejas redondas
        for y in range(14, 18):
            for z in (9, 10):
                if y == 17 and z == 10: continue
                M.put(s * 3 + (0 if s > 0 else -1), y, z, H, fur_d)
                M.put(s * 4 + (0 if s > 0 else -1), y, z, H, fur if y < 17 else fur_d)
    for (x, y, z), v in M.V.items():                                        # pelo a mechones
        if v[1] == fur and M.noise(x, y, z, 2.5) > 0.62: v[1] = fur_d
    tips = ((-2, 9), (-1, 8), (0, 10), (1, 8), (2, 9), (-1, 10), (1, 10), (0, 7))
    for i, (x, y) in enumerate(tips):                                        # los tentáculos del hocico
        L = 3 + (i % 3) + (2 if beard else 0)
        for k in range(L):
            M.put(x + (0 if k < 2 else (1 if x > 0 else -1 if x < 0 else 0)), y - (k // 3), 16 + k, H,
                  tent if k < L - 1 else lerp(tent, (1, 1, 1), 0.3))
    for s in (-1, 1):                                                       # los ojos, grandes
        for y in (12, 13):
            for x in ((2, 3) if s > 0 else (-4, -3)):
                M.put(x, y, 14, H, eye, 1)
        M.put(3 if s > 0 else -4, 13, 14, H, (1.0, 1.0, 0.85), 1)           # el brillo
    for k in range(14):                                                     # la cola, larga y pelada
        z = -7 - k
        y = 9 + int(2.5 * math.sin(k / 13 * math.pi))
        M.put(0, y, z, 'tail', lerp(tent, fur_d, 0.5))
        if k < 5: M.put(-1, y, z, 'tail', lerp(tent, fur_d, 0.5))
    if beard:
        for x in range(-3, 4):
            for y in (6, 7):
                M.put(x, y, 15, H, beard)
    if pendant:                                                             # ristra de setas que brillan
        for x in range(-4, 5):
            y = 9 - (1 if abs(x) < 3 else 0)
            M.put(x, y, 11, H, (0.30, 0.22, 0.16))
            if x % 2 == 0: M.put(x, y - 1, 12, H, (0.40, 0.95, 0.80), 1)
    piv = {'body': [0, 6, 0], 'head': [0, 11, 7], 'tail': [0, 9, -7],
           'leg_fl': [-3, 6, 5], 'leg_fr': [3, 6, 5], 'leg_bl': [-3, 6, -5], 'leg_br': [3, 6, -5]}
    n = M.export('models/%s.json' % name, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.92, specular=0.2)
    print(name, n, 'voxels')


def zoog():
    _zoog('zoog', 2201, (0.44, 0.32, 0.22), (0.30, 0.21, 0.14), (0.86, 0.52, 0.56), (0.20, 0.16, 0.12),
          (1.0, 0.82, 0.24))


def zoog_copas():
    _zoog('zoog_copas', 2202, (0.32, 0.34, 0.23), (0.21, 0.23, 0.15), (0.80, 0.56, 0.54), (0.80, 0.76, 0.62),
          (0.70, 1.0, 0.40))


def zoog_anciano():
    _zoog('zoog_anciano', 2203, (0.56, 0.54, 0.50), (0.40, 0.38, 0.35), (0.92, 0.90, 0.86), (0.30, 0.26, 0.22),
          (1.0, 0.66, 0.20), beard=(0.86, 0.84, 0.80), pendant=True)


ALL = {'zoog': zoog, 'zoog_copas': zoog_copas, 'zoog_anciano': zoog_anciano}

if __name__ == '__main__':
    for n in (sys.argv[1:] or ALL):
        ALL[n]()
