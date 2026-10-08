"""Mapa de lo transitable de una arena, a partir de los voxels reales de sus piezas.

En lugar de un cuadrado y de círculos aproximados, marca en una rejilla de 25 cm:
- lo que ocupa cada pieza (acantilados, costa, montículos, cabaña, iglú…) a la altura de un
  cuerpo (0,15 a 1,7 m): ahí no se puede estar;
- lo que ocupa a la altura de las balas (0,55 a 1,05 m): ahí se paran;
- el suelo: el llano de la arena (hasta la orilla) y lo alto de los tramos de costa, que
  asoman en el mar. Fuera de eso (el mar, detrás de los acantilados) no se puede estar;
- solo cuenta lo que se alcanza andando desde la salida (el interior de la cabaña, no).
Después calcula la distancia de cada celda a lo bloqueado, para empujar fuera con suavidad
(ObstacleMap.push_out).

Salida: data/arenas/<arena>_mapa.bin (N×N×3 bytes, fila a fila de norte a sur: bloqueado al
andar, bloqueado a las balas y distancia a lo bloqueado en 1/32 m, hasta 8 m), una vista previa
en shots/<arena>_mapa.png y la clave "mask" en el JSON de la arena.
También escribe en el JSON dónde va cada tramo de la barrera ("barrier.placements"), para que
Godot los ponga justo donde se han medido.

Uso: python tools/gen_mapa_transitable.py [campamento]   (lo llama gen_arena_campamento.py)
"""
import json, math, os, random, sys
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.join(os.path.dirname(__file__), '..')
CELL = 0.25
EXTENT = 50.0                    # de -50 a 50 m en X y en Z
N = int(EXTENT * 2 / CELL)
BODY = (0.15, 1.7)
BULLET = (0.55, 1.05)
TOP = (-0.25, 0.15)              # lo alto de la costa: a ras del suelo
DIST_STEP = 1.0 / 32.0

_cache = {}


def voxels(model):
    """(posiciones en m, tamaño del voxel) de un modelo, en su espacio."""
    if model not in _cache:
        d = json.load(open(os.path.join(ROOT, 'models', model + '.json')))
        vs = float(d.get('voxel_size', 1.0 / 32.0))
        v = np.array([p[:3] for p in d['voxels']], dtype=np.float32)
        _cache[model] = (v * vs, vs)
    return _cache[model]


def barrier_placements(b):
    """Tramos de la barrera: [x, y, z, giro, escala_y, modelo], como los ponía ArenaBuilder."""
    rng = random.Random(42)
    out = []
    models = b['models']
    for side in b['sides']:
        t = float(b['from'])
        k = 0
        while t <= float(b['to']):
            jitter = rng.uniform(-0.6, 0.6)
            sy = rng.uniform(0.9, 1.12)
            model = models[(k * 7 + 3) % len(models)]
            if side == 'north': out.append([t, float(b['y']), -float(b['line']) + jitter, 0.0, sy, model])
            else: out.append([-float(b['line']) + jitter, float(b['y']), t, 90.0, sy, model])
            t += float(b['spacing']) + rng.uniform(-0.4, 0.4)
            k += 1
    return out


def world(model, pos, rot, scale):
    """Voxels del modelo colocados: centro del voxel (m) y su alto, en el mundo."""
    v, vs = voxels(model)
    sx, sy, sz = scale
    a = math.radians(rot)
    c, s = math.cos(a), math.sin(a)
    x = (v[:, 0] + vs * 0.5) * sx
    z = (v[:, 2] + vs * 0.5) * sz
    wx = pos[0] + x * c + z * s                      # giro de Godot sobre Y
    wz = pos[2] - x * s + z * c
    y0 = pos[1] + v[:, 1] * sy
    return wx, wz, y0, y0 + vs * sy, vs * max(sx, sz)


def stamp(grid, wx, wz, sel, size):
    """Marca las celdas que tocan los voxels elegidos (con su tamaño, para no dejar huecos)."""
    if not sel.any(): return
    r = max(size * 0.5, 0.0)
    for dx in (-r, r):
        for dz in (-r, r):
            i = np.floor((wx[sel] + dx + EXTENT) / CELL).astype(int)
            j = np.floor((wz[sel] + dz + EXTENT) / CELL).astype(int)
            ok = (i >= 0) & (i < N) & (j >= 0) & (j < N)
            grid[j[ok], i[ok]] = True


def solid(own):
    """Huella maciza de una pieza: cierra las entradas estrechas (la puerta del iglú, la de la
    tienda) y rellena lo de dentro, para que nadie se meta en ella."""
    if not own.any(): return own
    js, is_ = np.nonzero(own)
    j0, j1 = max(js.min() - 4, 0), min(js.max() + 5, N)
    i0, i1 = max(is_.min() - 4, 0), min(is_.max() + 5, N)
    sub = own[j0:j1, i0:i1]
    sub = ndimage.binary_closing(np.pad(sub, 8), iterations=7)[8:-8, 8:-8]
    sub = ndimage.binary_fill_holes(sub)
    out = own.copy()
    out[j0:j1, i0:i1] |= sub
    return out


def build(name):
    path = os.path.join(ROOT, 'data', 'arenas', name + '.json')
    data = json.load(open(path))
    half = np.array(data['size'], dtype=float) * 0.5
    back = float(data['ground'].get('walk_back', data['ground']['margin_back']))   # walk_back: el bosque del fondo no se pisa
    sea_y = float(data['sea']['level']) if 'sea' in data else 0.0
    front = float(data['ground'].get('margin_front', 0.0))     # sin mar, el suelo sigue por delante
    body = np.zeros((N, N), bool)
    bullet = np.zeros((N, N), bool)
    floor = np.zeros((N, N), bool)
    # el llano: de detrás de los acantilados hasta la orilla
    cx = (np.arange(N) + 0.5) * CELL - EXTENT
    X, Z = np.meshgrid(cx, cx)
    floor |= (X <= half[0] + front) & (Z <= half[1] + front) & (X >= -half[0] - back) & (Z >= -half[1] - back)
    pieces = []
    for p in data['props']:
        y = sea_y - 0.15 if ('sea' in data and (p['pos'][0] > half[0] or p['pos'][1] > half[1])) else 0.0
        if 'y' in p: y = p['y']
        s = float(p['scale'])
        pieces.append((p['model'], (p['pos'][0], y, p['pos'][1]), p['rot'], (s, s, s)))
    if 'barrier' in data:
        data['barrier']['placements'] = barrier_placements(data['barrier'])
        for x, y, z, rot, sy, model in data['barrier']['placements']:
            pieces.append((model, (x, y, z), rot, (1.0, sy, 1.0)))
    for model, pos, rot, scale in pieces:
        wx, wz, y0, y1, size = world(model, pos, rot, scale)
        own = np.zeros((N, N), bool)
        stamp(own, wx, wz, (y1 > BODY[0]) & (y0 < BODY[1]), size)
        body |= solid(own)
        own = np.zeros((N, N), bool)
        stamp(own, wx, wz, (y1 > BULLET[0]) & (y0 < BULLET[1]), size)
        bullet |= solid(own)
        behind = 'walk_back' in data['ground'] and (pos[0] < -half[0] or pos[2] < -half[1])
        if not behind:                                                    # lo alto de la costa (con walk_back, no lo de detrás)
            stamp(floor, wx, wz, (y1 > TOP[0]) & (y1 < TOP[1]), size)
    blocked = body | ~floor
    holes = np.zeros((N, N), bool)                     # simas (hito 6.6): agua honda que no se pisa
    for hx, hz, hr in data.get('water', {}).get('holes', []):
        holes |= np.hypot(X - hx, Z - hz) < hr
    blocked |= holes
    # solo lo que se alcanza andando desde la salida
    free, _ = ndimage.label(~blocked)
    sp = data['spawn']
    si, sj = int((sp[0] + EXTENT) / CELL), int((sp[1] + EXTENT) / CELL)
    blocked |= free != free[sj, si]
    dist = ndimage.distance_transform_edt(~blocked) * CELL
    water = None
    if 'water' in data:
        water = (water_layer(data['water'], X, Z) & ~blocked) | holes
        open(os.path.join(ROOT, 'data', 'arenas', name + '_agua.bin'), 'wb').write(
            np.where(water, 255, 0).astype(np.uint8).tobytes())
    img = np.zeros((N, N, 3), np.uint8)
    img[..., 0] = np.where(blocked, 255, 0)
    img[..., 1] = np.where(bullet, 255, 0)
    img[..., 2] = np.clip(dist / DIST_STEP, 0, 255).astype(np.uint8)
    prev = img.copy()
    if water is not None: prev[water & ~blocked] = (40, 90, 200)
    open(os.path.join(ROOT, 'data', 'arenas', name + '_mapa.bin'), 'wb').write(img.tobytes())
    os.makedirs(os.path.join(ROOT, 'shots'), exist_ok=True)
    Image.fromarray(prev, 'RGB').save(os.path.join(ROOT, 'shots', name + '_mapa.png'))
    data['mask'] = {'file': 'res://data/arenas/%s_mapa.bin' % name, 'size': N, 'cell': CELL,
                    'origin': [-EXTENT, -EXTENT], 'dist_step': DIST_STEP}
    if water is not None: data['mask']['water'] = 'res://data/arenas/%s_agua.bin' % name
    with open(path, 'w') as f: json.dump(data, f, indent=1)
    walk = (~blocked).sum() * CELL * CELL
    print('%s: %d m² transitables, %d celdas de bala bloqueadas' % (name, walk, bullet.sum()))
    if water is not None: print('  agua somera: %d m² (%d %% de lo transitable)' % (water.sum() * CELL * CELL, 100 * water.sum() / max((~blocked).sum(), 1)))


def water_layer(w, X, Z):
    """Agua somera del pantano (hito 6.4): todo menos el terraplén (banda seca a lo largo de
    "embank": [x, z, dir_x, dir_z, medio ancho]), la zona de salida y unos islotes de tierra
    (ruido suave: "islands", fracción seca; "scale", m de cada mancha)."""
    rng = np.random.default_rng(int(w.get('seed', 1)))
    ex, ez, dx, dz, hw = w.get('embank', [0.0, 0.0, 1.0, 0.0, -1.0])   # sin terraplén: todo puede ser agua
    n = math.hypot(dx, dz)
    off = np.abs((X - ex) * (-dz / n) + (Z - ez) * (dx / n))
    k = max(int(w.get('scale', 5.0) / CELL / 2), 1)
    noise = ndimage.gaussian_filter(rng.random(X.shape), k, mode='wrap')
    noise = (noise - noise.min()) / (noise.max() - noise.min())
    dry = noise > np.quantile(noise, 1.0 - float(w.get('islands', 0.3)))
    sp = w.get('clear', [0.0, 0.0, 0.0])
    near = np.hypot(X - sp[0], Z - sp[1]) < sp[2]
    return (off > hw) & ~dry & ~near


if __name__ == '__main__':
    build(sys.argv[1] if len(sys.argv) > 1 else 'campamento')
