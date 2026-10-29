"""Mapa de la marea de una arena con agua somera (hito 12.13, 29-10-2026).

Para cada celda del mapa de lo transitable, la distancia en metros al agua que ya hay (0 en el
agua), en dieciseisavos de metro (hasta 16 m). Con la marea a M metros, todo lo que está a menos
de M del agua queda bajo ella: ObstacleMap.water_at lo cuenta como agua que frena y el suelo
(town_ground.gdshader, tide_tex) la dibuja con la orilla avanzando sin escalones.

Uso: python tools/gen_marea.py arrecife      -> data/arenas/arrecife_marea.bin
     (y apunta en pantalla cuánto suelo transitable cubre cada altura de marea)
"""
import json
import os
import sys

import numpy as np
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(__file__), '..')


def res(path):
    return os.path.join(ROOT, path.replace('res://', ''))


def main(name):
    arena = json.load(open(os.path.join(ROOT, 'data', 'arenas', name + '.json'), encoding='utf-8'))
    m = arena['mask']
    n, cell = int(m['size']), float(m['cell'])
    water = np.fromfile(res(m['water']), dtype=np.uint8).reshape(n, n) > 0
    walk = np.fromfile(res(m['file']), dtype=np.uint8).reshape(n, n, 3)[:, :, 0] == 0
    d = ndimage.distance_transform_edt(~water) * cell                 # m hasta el agua más cercana
    out = np.clip(np.round(d * 16.0), 0, 255).astype(np.uint8)
    path = os.path.join(ROOT, 'data', 'arenas', name + '_marea.bin')
    out.tofile(path)
    print('escrito', os.path.relpath(path, ROOT))
    total = walk.sum()
    for lvl in (0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0):
        under = water | (d < lvl)
        print('  marea %.1f m: %4.1f %% de lo transitable bajo el agua' % (lvl, 100.0 * (walk & under).sum() / total))


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'arrecife')
