"""Atrezo de la ciudad ciclópea de los Antiguos (nivel 4, hito 4.4), a 32 voxels/m: muros de
sillares enormes con relieves de estrellas de cinco puntas (rotos, de alturas distintas),
un arco caído, un bloque suelto y un mural en relieve. Piedra gris parda con escarcha.
También la barrera del fondo: models/muro_ciclopeo_{1,2,3}.json (tramos de 8 m, a 8 voxels/m).
Uso: python tools/gen_atrezo_ciudad.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, refine

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


def masonry(M, x0, x1, y0, y1, z0, z1, stars=0.3, cracks=3, hmin=12, hmax=22, wmin=14, wmax=34, slant=0.0, rustic=False):
    """Muro de sillares ciclópeos: hiladas de alturas distintas, bloques de anchos distintos,
    cada uno con su tono, canto biselado, juntas hundidas, estrellas talladas en algunos y grietas.
    Hueco por dentro. Devuelve el reparto de bloques {(hilada, índice): (ua, ub, ya, yb)} de la
    cara +z (para romper el muro por bloques).
    Revisión de arte del 14-10-2026: las juntas van hundidas un voxel (relieve de verdad) y, con
    `slant`, las juntas verticales se inclinan por hilada (aparejo poligonal, ciclópeo)."""
    rng = M.rng
    cs = courses(rng, y0, y1, hmin, hmax)
    sl = [rng.uniform(-slant, slant) for _ in cs]
    lay = {}                                                     # cara -> hilada -> cortes
    for face in ('z', 'x'):
        u0, u1 = (x0, x1) if face == 'z' else (z0, z1)
        lay[face] = [cuts(rng, u0, u1, wmin, wmax) for _ in cs]

    def block(face, u, y):
        for ci, (ya, yb) in enumerate(cs):
            if ya <= y < yb:
                du = sl[ci] * (y - (ya + yb) / 2)
                uu = u - du
                for bi, (ua, ub) in enumerate(lay[face][ci]):
                    if ua <= uu < ub: return ci, bi, ua + du, ub + du, ya, yb
                return ci, 0, u, u + 1, ya, yb
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
                d = int(math.floor(d)) if d < 99 else d
                if edge == 1 and y < y1 - 1: c = lerp(JOINT, STONE_D, 0.3)   # fondo de la junta hundida
                if (edge == 0 and d == 0 and y < y1 - 1 and 0 < x - x0 < x1 - x0 - 1
                        and 0 < z - z0 < z1 - z0 - 1 and y > y0):
                    continue                                             # junta hundida: se ve el fondo
                if edge == 0 or y == y1 - 1:
                    if d == 0: c = JOINT                                 # junta
                    if rustic and d >= 3 and edge == 0 and y < y1 - 1:  # almohadillado: la cara abomba
                        out = ((0, 0, 1) if z == z1 - 1 else (0, 0, -1) if z == z0 else
                               (1, 0, 0) if x == x1 - 1 else (-1, 0, 0) if x == x0 else None)
                        if out: M.put(x + out[0], y, z + out[2], P, lerp(c, STONE_L, 0.12) if d >= 5 else c)
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
    cs, lay = masonry(M, x0, x1, 0, 80, -11, 11, stars=0.5, cracks=4, hmin=20, hmax=34, wmin=22, wmax=48, slant=0.35, rustic=True)
    # Se rompe por bloques, de abajo arriba: un bloque se queda si cabe bajo el perfil y todo
    # su ancho apoya en lo de abajo (si no, quedaban bloques en el aire sobre huecos).
    prof = {x: 34 + 46 * M.noise(x, 0, 0, 26.0) for x in range(x0, x1)}
    h = {x: 0 for x in range(x0, x1)}
    for ci, (ya, yb) in enumerate(cs):
        for ua, ub in lay[ci]:
            span = range(ua, ub)
            if ci <= 0 or (all(h[x] == ya for x in span) and yb <= min(prof[x] for x in span)):
                for x in span: h[x] = yb
    for (x, y, z) in list(M.V):                                    # se corta en vertical por el perfil
        if y >= h[min(max(x, x0), x1 - 1)] and -12 <= z <= 12 and x0 - 2 <= x <= x1 + 1: del M.V[(x, y, z)]
    # el muro es hueco: se cierran por arriba y por los lados los cortes que deja
    for x in range(x0, x1):
        for y in range(0, h[x]):
            side = y >= h.get(x - 1, 0) or y >= h.get(x + 1, 0) or y == h[x] - 1
            if side:
                for z in range(-11, 11):
                    if (x, y, z) not in M.V:
                        c = lerp(STONE_D, STONE, M.noise(x, y, z, 4.0))
                        if y == h[x] - 1: c = lerp(c, STONE_L, 0.35)
                        M.put(x, y, z, P, c)
    for i in range(4):                                            # bloques caídos al pie
        w, hh, d = M.rng.randint(16, 30), M.rng.randint(12, 20), M.rng.randint(14, 22)
        cx, cz = M.rng.randint(-56, 30), M.rng.randint(14, 26)
        masonry(M, cx, cx + w, 0, hh, cz, cz + d, stars=0.4, cracks=1, hmin=hh, hmax=hh, wmin=w, wmax=w)
    frost(M)
    return M


def arco():
    """Arco monumental de los Antiguos (revisión de arte del 14-10-2026, referencia de FLUX en
    local tools/local/ref_arco_1000.png; el de antes queda en models/atrezo_arco_v1.json): dos
    jambas de sillería, dovelas en abanico que forman un arco apuntado con la clave tallada con
    la estrella, una banda de meandro en el intradós, la mitad derecha del arco caída a trozos al
    pie y escarcha. A 32 voxels/m con la textura fina a 64/m."""
    M = Model(S=2, seed=62)
    rng = M.rng
    masonry(M, -50, -28, 0, 84, -11, 11, stars=0.0, cracks=2, hmin=16, hmax=26, wmin=22, wmax=22)
    masonry(M, 28, 50, 0, 70, -11, 11, stars=0.0, cracks=3, hmin=16, hmax=26, wmin=22, wmax=22)
    cy, NV = 84, 9
    for x in range(-52, 53):
        for y in range(cy, cy + 64):
            cxc = 12 if x < 0 else -12                          # apuntado: dos centros cruzados
            r = math.hypot(x - cxc, y - cy)
            if not (38 <= r <= 62): continue
            ang = (math.atan2(y - cy, x) % math.pi) / math.pi * NV
            k = int(ang)
            if x > 4 and k < 3: continue                         # la mitad derecha se cayó
            for z in range(-11, 11):
                edge = min(r - 38, 62 - r, z + 11, 10 - z)
                if edge > 1.5 and r > 39.5: continue
                if abs(ang - round(ang)) < 0.05 and abs(z) >= 10 and 0 < round(ang) < NV: continue   # junta
                c = lerp(STONE_D, STONE_L, 0.25 + 0.55 * M.hsh(k, 3, 3))
                c = lerp(c, STONE_D, 0.3 * M.noise(x, y, z, 4.0))
                if r < 41 and abs(z) >= 9: c = RELIEF if int(ang * 7) % 2 else lerp(RELIEF, STONE_L, 0.4)   # meandro
                M.put(x, y, z, P, c)
    for x in range(-9, 10):                                       # clave con la estrella
        for y in range(cy + 44, cy + 62):
            a2 = math.atan2(y - (cy + 52), x); r = math.hypot(x, y - (cy + 52))
            lim = 7 * (0.45 + 0.55 * (0.5 + 0.5 * math.cos(5 * (a2 - math.pi / 2))) ** 2)
            if r < lim:
                for z in (11, -12): M.put(x, y, z, P, RELIEF)
    for i in range(5):                                            # dovelas caídas
        w = rng.randint(14, 22); x0 = rng.randint(18, 64); z0 = rng.randint(12, 32); hh = rng.randint(10, 16)
        masonry(M, x0, x0 + w, 0, hh, z0, z0 + rng.randint(12, 20), stars=0.0, cracks=1, hmin=hh, hmax=hh, wmin=w, wmax=w)
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
    masonry(M, -128, 128, 0, 320, -64, 0, stars=0.45, cracks=8, hmin=34, hmax=60, wmin=40, wmax=90, slant=0.3, rustic=True)
    for k in [k for k in M.V if k[1] > 260 + 60 * M.noise(k[0], 0, 0, 40.0)]: del M.V[k]
    frost(M)
    return half2(M)


def half2(M):
    """De 32/m a 16/m conservando las juntas oscuras (revisión de arte del 14-10-2026; antes a 8/m)."""
    H = Model(S=1, seed=1)
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    rank = {}
    for (x, y, z), v in M.V.items():                      # gana lo que está a la vista (no el relleno de dentro)
        k = (x // 2, y // 2, z // 2)
        r = sum((x + a, y + b, z + c) not in M.V for a, b, c in NB) + (3 if v[1] in (FROST, JOINT) else 0)
        if k not in H.V or r > rank[k]: H.V[k] = [v[0], v[1], v[2]]; rank[k] = r
    return H


def _fine(M, seed, k=2):
    """A 64/m con textura fina (revisión de arte del 13-10-2026): moteado y picaduras en la
    piedra, y además liquen a manchas y desconchones pequeños en las aristas de arriba."""
    N = refine(M, k, seed=seed)
    LICHEN = (0.56, 0.58, 0.44)
    for (x, y, z), v in N.V.items():
        if v[1] == FROST or v[2]: continue
        if N.noise(x, y, z, 5.0) > 0.78 and _hh(x, y, z) > 0.4: v[1] = lerp(v[1], LICHEN, 0.5)
        if (x, y + 1, z) not in N.V and _hh(x, y, z) > 0.93: v[1] = lerp(v[1], STONE_D, 0.6)
    return N


def _hh(x, y, z):
    h = (x * 73856093) ^ (y * 19349663) ^ (z * 83492791)
    return ((h ^ (h >> 13)) * 1274126177 & 0xFFFF) / 65536.0


# Los bloques (se repiten 86 veces) y el muro roto (14) llevan la textura fina a 32/m: al doble de
# resolución la ciudad bajaba de ~118 a ~88 FPS. El mural (3) sí va a 64/m.
PIECES = {'muro_roto': lambda: _fine(muro_roto(), 61, 1), 'arco': lambda: _fine(arco(), 62), 'bloque_ciclopeo': lambda: _fine(bloque(), 63, 1),
          'bloque_ciclopeo_2': lambda: _fine(bloque(2), 64, 1), 'bloque_ciclopeo_3': lambda: _fine(bloque(3), 65, 1),
          'mural': lambda: _fine(mural(), 66)}

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
