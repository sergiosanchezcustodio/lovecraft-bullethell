"""Atrezo de la ciudad ciclópea de los Antiguos (nivel 4, hito 4.4), a 32 voxels/m: muros de
sillares enormes con relieves de estrellas de cinco puntas (rotos, de alturas distintas),
un arco caído, un bloque suelto y un mural en relieve. Piedra gris parda con escarcha.
También la barrera del fondo: models/muro_ciclopeo_{1,2,3}.json (tramos de 8 m, a 8 voxels/m).
Uso: python tools/gen_atrezo_ciudad.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
STONE = (0.50, 0.50, 0.50); STONE_D = (0.32, 0.32, 0.34); STONE_L = (0.62, 0.62, 0.62)   # gris frío: pardo, con el sol cálido, salía marrón
JOINT = (0.18, 0.17, 0.16); FROST = (0.80, 0.84, 0.90); RELIEF = (0.36, 0.34, 0.30)


def ashlar(M, x0, x1, y0, y1, z0, z1, rows=4, star=True):
    """Muro de sillares: hileras de bloques con juntas hundidas y estrellas en relieve."""
    h = max(1, (y1 - y0) // rows)
    for y in range(y0, y1):
        row = (y - y0) // h
        off = (row % 2) * 9
        for x in range(x0, x1):
            for z in range(z0, z1):
                edge = min(x - x0, x1 - 1 - x, z - z0, z1 - 1 - z)
                if edge > 1 and y < y1 - 1: continue                  # hueco por dentro
                joint = (y - y0) % h == 0 or (x - x0 + off) % 18 == 0
                c = lerp(STONE_D, STONE_L, 0.35 + 0.5 * M.hsh(row, (x - x0 + off) // 18, 0))
                c = lerp(c, STONE_D, 0.3 * M.noise(x, y, z, 5.0))
                if joint and edge == 0: c = JOINT
                M.put(x, y, z, P, c)
    if star:                                                          # estrellas en la cara +Z
        for cx in range(x0 + 9, x1 - 6, 18):
            cy = y0 + h * 2 + h // 2
            for x in range(cx - 6, cx + 7):
                for y in range(cy - 6, cy + 7):
                    a = math.atan2(y - cy, x - cx)
                    if math.hypot(x - cx, y - cy) < 5.5 * (0.5 + 0.5 * math.cos(5 * a + math.pi / 2)) + 0.8:
                        if (x, y, z1 - 1) in M.V: M.put(x, y, z1, P, RELIEF)


def frost(M):
    cols = {}
    for (x, y, z) in M.V:
        if y > cols.get((x, z), -1): cols[(x, z)] = y
    for (x, z), y in cols.items():
        if M.hsh(x, y, z) < 0.7: M.put(x, y + 1, z, P, FROST, over=False)


def muro_roto():
    M = Model(S=2, seed=61)
    ashlar(M, -48, 48, 0, 72, -10, 10)
    top = {}
    for k in [k for k in M.V if k[1] > 30 + 40 * M.noise(k[0], 0, 0, 22.0)]: del M.V[k]   # perfil roto
    for (x, y, z) in list(M.V):                                       # cierra lo alto: no se ve hueco
        if y > top.get(x, -1): top[x] = y
    for x, y in top.items():
        for z in range(-10, 10): M.put(x, y, z, P, STONE, over=False)
    for i in range(6):                                                 # cascotes al pie
        cx, cz = M.rng.randint(-50, 50), M.rng.randint(12, 26)
        s = M.rng.randint(4, 8)
        M.box(cx, 0, cz, cx + s, s, cz + s, P, STONE_D)
    frost(M)
    return M


def arco():
    """Arco de dos jambas y un dintel partido, una mitad caída."""
    M = Model(S=2, seed=62)
    ashlar(M, -40, -24, 0, 96, -9, 9, rows=6, star=False)
    ashlar(M, 24, 40, 0, 96, -9, 9, rows=6, star=False)
    ashlar(M, -40, 2, 96, 112, -9, 9, rows=1, star=False)               # dintel
    for x in range(-10, 30):                                           # la otra mitad, caída
        for y in range(0, 14):
            for z in range(12, 30):
                if M.hsh(x // 8, y // 7, z // 9) < 0.85: M.put(x, y, z, P, lerp(STONE_D, STONE, 0.5))
    frost(M)
    return M


def bloque():
    M = Model(S=2, seed=63)
    ashlar(M, -20, 20, 0, 28, -14, 14, rows=2)
    frost(M)
    return M


def mural():
    """Mural bajo: un friso de Antiguos estilizados (barriles con estrella) en relieve."""
    M = Model(S=2, seed=64)
    ashlar(M, -56, 56, 0, 44, -6, 6, rows=2, star=False)
    for i, cx in enumerate(range(-44, 48, 22)):
        for y in range(10, 34):
            r = 3 + 3 * math.sin(math.pi * (y - 10) / 24)
            for x in range(int(cx - r), int(cx + r) + 1): M.put(x, y, 6, P, RELIEF)
        for k in range(5):
            a = k / 5 * math.tau
            for t in range(6): M.put(int(cx + math.cos(a) * t), int(37 + math.sin(a) * t), 6, P, RELIEF)
    frost(M)
    return M


def half(M):
    H = Model(S=1, seed=1)
    for (x, y, z), v in M.V.items():
        k = (x // 4, y // 4, z // 4)
        if k not in H.V or v[1] == FROST: H.V[k] = [v[0], v[1], v[2]]
    H.S = 0.5
    return H


def muro_ciclopeo(seed):
    """Tramo de fondo: muro altísimo de sillares (10 m) con almenas rotas. Se hace a 32/m y se
    baja a 8/m como la Barrera de hielo (es fondo)."""
    M = Model(S=2, seed=seed)
    ashlar(M, -128, 128, 0, 320, -64, 0, rows=10)
    for k in [k for k in M.V if k[1] > 260 + 60 * M.noise(k[0], 0, 0, 40.0)]: del M.V[k]
    frost(M)
    return half(M)


PIECES = {'muro_roto': muro_roto, 'arco': arco, 'bloque_ciclopeo': bloque, 'mural': mural}

if __name__ == '__main__':
    for name, fn in PIECES.items():
        M = fn()
        n = M.export('models/atrezo_%s.json' % name, {P: [0, 0, 0]}, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.85, specular=0.25, no_bottom=True)
        print('atrezo_%s: %d' % (name, n))
    for i, seed in enumerate((71, 72, 73)):
        M = muro_ciclopeo(seed)
        n = M.export('models/muro_ciclopeo_%d.json' % (i + 1), {P: [0, 0, 0]}, jitter=0.004, pivots_in_voxels=True,
                     roughness=0.85, specular=0.25)
        print('muro_ciclopeo_%d: %d' % (i + 1, n))
