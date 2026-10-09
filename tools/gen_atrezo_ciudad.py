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
        if M.hsh(x, y, z) < 0.93: M.put(x, y + 1, z, P, FROST, over=False)   # densa: rala parecía sal


# ---- Sillería irregular (09-10-2026, siguiendo tools/replicate/ref_ruinas.png) ----
def courses(rng, y0, y1, hmin=12, hmax=22):
    """Hiladas de alturas distintas entre y0 e y1: lista de (ya, yb)."""
    out, y = [], y0
    while y < y1:
        h = rng.randint(hmin, hmax)
        if y1 - (y + h) < hmin: h = y1 - y
        out.append((y, y + h)); y += h
    return out


def cuts(rng, u0, u1, wmin=14, wmax=34):
    """Cortes de los bloques de una hilada a lo largo de u: lista de (ua, ub)."""
    out, u = [], u0 - rng.randint(0, wmin)
    while u < u1:
        w = rng.randint(wmin, wmax)
        out.append((max(u, u0), min(u + w, u1))); u += w
    return out


def masonry(M, x0, x1, y0, y1, z0, z1, stars=0.3, cracks=3):
    """Muro de sillares ciclópeos: hiladas de alturas distintas, bloques de anchos distintos,
    cada uno con su tono, canto biselado, juntas hundidas, estrellas talladas en algunos y grietas.
    Hueco por dentro. Devuelve el reparto de bloques {(hilada, índice): (ua, ub, ya, yb)} de la
    cara +z (para romper el muro por bloques)."""
    rng = M.rng
    cs = courses(rng, y0, y1)
    lay = {}                                                     # cara -> hilada -> cortes
    for face in ('z', 'x'):
        u0, u1 = (x0, x1) if face == 'z' else (z0, z1)
        lay[face] = [cuts(rng, u0, u1) for _ in cs]

    def block(face, u, y):
        for ci, (ya, yb) in enumerate(cs):
            if ya <= y < yb:
                for bi, (ua, ub) in enumerate(lay[face][ci]):
                    if ua <= u < ub: return ci, bi, ua, ub, ya, yb
        return 0, 0, u, u + 1, y, y + 1

    for x in range(x0, x1):
        for y in range(y0, y1):
            for z in range(z0, z1):
                edge = min(x - x0, x1 - 1 - x, z - z0, z1 - 1 - z)
                if edge > 1 and y < y1 - 1: continue
                face = 'z' if min(z - z0, z1 - 1 - z) <= min(x - x0, x1 - 1 - x) else 'x'
                u = x if face == 'z' else z
                ci, bi, ua, ub, ya, yb = block(face, u, y)
                c = lerp(STONE_D, STONE_L, 0.2 + 0.6 * M.hsh(ci, bi, 7 if face == 'z' else 9))
                c = lerp(c, STONE_D, 0.35 * M.noise(x, y, z, 4.0))
                uo0, uo1 = (x0, x1) if face == 'z' else (z0, z1)
                # distancia a una junta interior (los bordes de la pieza no llevan junta: si no,
                # cada pieza parecía una caja con el contorno negro)
                d = min(u - ua if ua > uo0 else 99, ub - 1 - u if ub < uo1 else 99,
                        y - ya if ya > y0 else 99, yb - 1 - y if yb < y1 else 99)
                if edge == 0 or y == y1 - 1:
                    if d == 0: c = JOINT                                 # junta
                    elif d == 1: c = lerp(c, JOINT, 0.3)                 # bisel
                    if y >= yb - 2: c = lerp(c, STONE_L, 0.3)            # canto de arriba, más claro
                M.put(x, y, z, P, c)
    # estrellas de cinco puntas talladas en bloques grandes de la cara +z (y -z)
    for ci, (ya, yb) in enumerate(cs):
        for bi, (ua, ub) in enumerate(lay['z'][ci]):
            if ub - ua < 18 or yb - ya < 14 or M.hsh(ci, bi, 3) > stars: continue
            cx, cy = (ua + ub) // 2, (ya + yb) // 2
            R = min(ub - ua, yb - ya) * 0.36
            for zf in (z1 - 1, z0):
                for x in range(int(cx - R) - 1, int(cx + R) + 2):
                    for y in range(int(cy - R) - 1, int(cy + R) + 2):
                        a = math.atan2(y - cy, x - cx)
                        r = math.hypot(x - cx, y - cy)
                        lim = R * (0.45 + 0.55 * (0.5 + 0.5 * math.cos(5 * (a - math.pi / 2))) ** 2)   # cinco puntas
                        if r < lim and (x, y, zf) in M.V:
                            M.put(x, y, zf, P, RELIEF if r < lim - 1 else lerp(RELIEF, STONE_L, 0.5))
    # grietas: caminos al azar que bajan por la cara
    for _ in range(cracks):
        x, y = rng.randint(x0 + 4, x1 - 5), y1 - 1
        for _ in range(rng.randint(10, 30)):
            for zf in (z1 - 1,):
                if (x, y, zf) in M.V: M.put(x, y, zf, P, JOINT)
            y -= 1; x += rng.choice((-1, 0, 0, 1))
            if y <= y0: break
    # esquinas desconchadas arriba
    for x in range(x0, x1):                                       # solo las de este bloque (si no, mordía las piezas vecinas)
        for z in range(z0, z1):
            for y in range(max(y0, y1 - 3), y1):
                if min(x - x0, x1 - 1 - x) <= 2 and min(z - z0, z1 - 1 - z) <= 2 and M.hsh(x, y, z) < 0.6:
                    M.V.pop((x, y, z), None)
    return cs, lay['z']


def fallen(M, cx, cz, w, h, d, y=0):
    """Bloque caído al pie del muro, con su sillería."""
    masonry(M, cx, cx + w, y, y + h, cz, cz + d, stars=0.0, cracks=1)


def muro_roto():
    """Muro de sillares roto por bloques (perfil escalonado), con bloques caídos al pie."""
    M = Model(S=2, seed=61)
    x0, x1 = -48, 48
    cs, lay = masonry(M, x0, x1, 0, 76, -10, 10, stars=0.35, cracks=4)
    # Se rompe por bloques, de abajo arriba: un bloque se queda si cabe bajo el perfil y todo
    # su ancho apoya en lo de abajo (si no, quedaban bloques en el aire sobre huecos).
    prof = {x: 34 + 46 * M.noise(x, 0, 0, 26.0) for x in range(x0, x1)}
    h = {x: 0 for x in range(x0, x1)}
    for ci, (ya, yb) in enumerate(cs):
        for ua, ub in lay[ci]:
            span = range(ua, ub)
            if ci <= 1 or (all(h[x] == ya for x in span) and yb <= min(prof[x] for x in span)):
                for x in span: h[x] = yb
            else:
                for x in span:
                    for y in range(ya, yb):
                        for z in range(-10, 10): M.V.pop((x, y, z), None)
    # el muro es hueco: se cierran por arriba y por los lados los cortes que deja
    for x in range(x0, x1):
        for y in range(0, h[x]):
            side = y >= h.get(x - 1, 0) or y >= h.get(x + 1, 0) or y == h[x] - 1
            if side:
                for z in range(-10, 10):
                    if (x, y, z) not in M.V: M.put(x, y, z, P, lerp(STONE_D, STONE, M.noise(x, y, z, 4.0)))
    for i in range(4):                                            # bloques caídos al pie
        w, h, d = M.rng.randint(12, 22), M.rng.randint(8, 14), M.rng.randint(10, 16)
        fallen(M, M.rng.randint(-50, 30), M.rng.randint(12, 22), w, h, d)
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


def bloque(variant=1):
    """Sillares sueltos de la ciudad: 1, un bloque enorme con su estrella; 2, dos bloques
    apilados y desplazados; 3, un bloque roto con su trozo caído al lado."""
    M = Model(S=2, seed=62 + variant)
    if variant == 1:
        masonry(M, -20, 20, 0, 28, -14, 14, stars=1.0, cracks=2)
    elif variant == 2:
        masonry(M, -22, 16, 0, 18, -14, 14, stars=0.0, cracks=1)
        masonry(M, -12, 20, 18, 34, -10, 12, stars=1.0, cracks=1)
    else:
        masonry(M, -20, 12, 0, 24, -14, 14, stars=1.0, cracks=3)
        for (x, y, z) in list(M.V):                               # el trozo que falta, en diagonal
            if x - y > 4: del M.V[(x, y, z)]
        fallen(M, 14, -10, 12, 10, 14)
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


PIECES = {'muro_roto': muro_roto, 'arco': arco, 'bloque_ciclopeo': bloque,
          'bloque_ciclopeo_2': lambda: bloque(2), 'bloque_ciclopeo_3': lambda: bloque(3), 'mural': mural}

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
