"""Piezas de las armas del arsenal III (D-38, hito 8.8), a 32 voxels/m: el ancla del Alert
(órbita) y el cepo de trampero, abierto y cerrado. Escribe models/proj_<id>.json.
Uso: python tools/gen_proyectiles.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model

P = 'body'
HIERRO = (0.24, 0.25, 0.27)
HIERRO_CLARO = (0.42, 0.43, 0.45)
OXIDO = (0.34, 0.24, 0.18)


def ancla():
    """Ancla de almirantazgo: caña, cepo arriba, arganeo y dos brazos con uñas (en ub)."""
    M = Model(S=2, seed=91)
    M.box(-0.6, 2, -0.6, 0.6, 15, 0.6, P, HIERRO)                 # caña
    M.box(-5, 13, -0.5, 5, 14, 0.5, P, HIERRO_CLARO)              # cepo
    for a in range(0, 360, 20):                                    # arganeo
        x = 1.6 * math.cos(math.radians(a)); y = 17 + 1.6 * math.sin(math.radians(a))
        M.box(x - 0.4, y - 0.4, -0.4, x + 0.4, y + 0.4, 0.4, P, HIERRO_CLARO)
    for s in (-1, 1):                                              # brazos en arco con uñas
        for k in range(0, 25):
            t = k / 24.0
            ang = math.radians(-90 + 70 * t)
            x = s * 6 * math.cos(ang) * t * 1.1
            y = 2 + 6 * (1 + math.sin(ang)) * 0.6
            M.box(x - 0.8, y - 0.8, -0.7, x + 0.8, y + 0.8, 0.7, P, HIERRO)
        M.box(s * 6.6 - 1.2, 5, -0.9, s * 6.6 + 1.2, 7.4, 0.9, P, HIERRO_CLARO)   # uña
    for (x, y, z), v in M.V.items():                               # óxido
        if M.noise(x, y, z, 3) > 0.74: v[1] = OXIDO
    return M


def cepo(abierto):
    """Cepo de hierro: base con muelles y dos mandíbulas dentadas, abiertas o cerradas."""
    M = Model(S=2, seed=92 + int(abierto))
    M.box(-6, 0, -1, 6, 1, 1, P, HIERRO)                          # barra
    M.box(-1.5, 0, -1.5, 1.5, 1.5, 1.5, P, HIERRO_CLARO)          # plato
    for s in (-1, 1):
        M.box(s * 7 - 1.2, 0, -1.2, s * 7 + 1.2, 1.4, 1.2, P, HIERRO_CLARO)   # muelles
    for s in (-1, 1):
        for k in range(-10, 11):                                   # mandíbula en arco
            a = math.radians(k * 7.5)
            if abierto:
                x, y, z = 5.5 * math.sin(a), 0.5, s * 5.5 * math.cos(a)
            else:
                x, y, z = 5.5 * math.sin(a), 0.5 + 4.5 * math.cos(a) * 0.9, s * 0.8
            M.box(x - 0.6, y - 0.6, z - 0.6, x + 0.6, y + 0.6, z + 0.6, P, HIERRO)
            if k % 4 == 0:                                          # dientes
                dz = -s * 1.2 if abierto else 0
                dy = 0 if abierto else -1.2
                M.box(x - 0.3, y + 0.3 + (1.0 if abierto else dy), z + dz - 0.3, x + 0.3, y + (1.5 if abierto else 0), z + dz + 0.3,
                      P, HIERRO_CLARO)
    for (x, y, z), v in M.V.items():
        if M.noise(x, y, z, 2.5) > 0.76: v[1] = OXIDO
    return M


PIEZAS = {'proj_ancla': ancla, 'proj_cepo': lambda: cepo(True), 'proj_cepo_cerrado': lambda: cepo(False)}

if __name__ == '__main__':
    for name, fn in PIEZAS.items():
        M = fn()
        for k in [k for k in M.V if k[1] < 0]: del M.V[k]
        print(name, M.export('models/%s.json' % name, {P: [0, 0, 0]}, jitter=0.01, pivots_in_voxels=True,
                             roughness=0.55, specular=0.4))
