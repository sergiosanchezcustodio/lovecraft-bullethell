"""Quita de modelos ya generados las caras que dan al hueco cerrado de cada parte (27-10-2026),
sin volver a ejecutar su generador: añade el noveno valor de voxlib.inner_faces a cada voxel
del JSON y lo reescribe. Los modelos que ya lo llevan (Dagon, Cthulhu) no se tocan. Al
regenerar un modelo, voxlib.Model.export ya lo calcula solo.

Uso: python tools/caras_dentro.py [--min N] [--dry] models/a.json models/b.json ...
  --min N: solo reescribe los que ahorran al menos N triángulos (por defecto 20000).
  --dry: solo cuenta.
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, inner_faces

FACES = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))


def triangles(vox, own):
    """Triángulos que construye VoxelBuilder: cara tapada solo por un voxel de la misma parte."""
    n = 0
    for v in vox:
        sk = v[8] if len(v) > 8 else 0
        for i, (a, b, c) in enumerate(FACES):
            if not sk >> i & 1 and own.get((v[0] + a, v[1] + b, v[2] + c)) != v[3]: n += 1
    return n * 2


def main(args):
    min_gain, dry = 20000, False
    if '--min' in args:
        i = args.index('--min'); min_gain = int(args[i + 1]); del args[i:i + 2]
    if '--dry' in args:
        args.remove('--dry'); dry = True
    total = saved = 0
    for path in args:
        with open(path) as f: data = json.load(f)
        vox = data['voxels']
        if any(len(v) > 8 for v in vox):
            print('%-36s ya las tiene' % path); continue
        M = Model(S=1)
        M.V = {(v[0], v[1], v[2]): [v[3], None, 0] for v in vox}
        skip = inner_faces(M, {v[3] for v in vox})
        own = {(v[0], v[1], v[2]): v[3] for v in vox}
        before = triangles(vox, own)
        for v in vox:
            m = skip.get((v[0], v[1], v[2]))
            if m: v.append(m)
        after = triangles(vox, own)
        gain = before - after
        write = gain >= min_gain and not dry
        print('%-36s %9d -> %9d triángulos%s' % (path, before, after, '' if write else '  (sin cambios)'), flush=True)
        if write:
            tmp = path + '.tmp'
            with open(tmp, 'w') as f: json.dump(data, f)
            os.replace(tmp, path)
            total += before; saved += gain
    print('reescritos: %d triángulos menos de %d' % (saved, total))


if __name__ == '__main__':
    main(sys.argv[1:])
