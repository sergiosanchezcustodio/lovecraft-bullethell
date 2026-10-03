"""Atrezo del paso de la cordillera y sus cavernas (nivel 3 de la parte 1, hito 4.3), a 32
voxels por metro: roca grande de caras planas con nieve encima, estalagmita, columna tallada
por los Antiguos (relieves de estrellas de cinco puntas, rota) y un grupo de cristales de
hielo que brillan con luz propia (azul pálido, sin sombreado).
Escribe models/atrezo_{roca_grande,estalagmita,columna_tallada,cristales}.json.
Uso: python tools/gen_atrezo_paso.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
ROCK = (0.40, 0.38, 0.37); ROCK_D = (0.24, 0.23, 0.23); ROCK_L = (0.52, 0.50, 0.48)
STONE = (0.46, 0.44, 0.38); STONE_D = (0.30, 0.29, 0.25)         # piedra de los Antiguos
SNOW = (0.88, 0.91, 0.95); SNOW_SH = (0.78, 0.83, 0.90)
ICE = (0.16, 0.38, 0.72); ICE_L = (0.30, 0.58, 0.88)       # sin sombreado: ACES los quema, más oscuros


def cap_snow(M, prob=0.8, depth=1):
    cols = {}
    for (x, y, z) in M.V:
        if y > cols.get((x, z), -99): cols[(x, z)] = y
    for (x, z), y in cols.items():
        if M.hsh(x, y, z) > prob: continue
        for d in range(depth):
            M.put(x, y + 1 + d, z, P, SNOW if M.hsh(x, 3, z) > 0.3 else SNOW_SH, over=False)


def roca_grande():
    """Roca de caras planas (superelipsoide), 2,5 m, con vetas y nieve en lo alto."""
    M = Model(S=2, seed=51)
    # bloques de caras planas, más anchos que altos y apoyados unos en otros (redondeada,
    # con dos huecos oscuros abajo, parecía una calavera)
    M.sell(0, 5, 0, 13, 6, 10, P, ROCK, p=4.5)
    M.sell(-3, 11, -2, 8, 5, 7, P, ROCK, p=4.0)
    M.sell(7, 4, -5, 6, 4, 5, P, ROCK, p=4.0)
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    def paint(k, part, c):
        x, y, z = k
        n = M.noise(x, y, z, 8.0)
        c = lerp(ROCK_D, ROCK_L, n)
        if (x + 2 * y) % 17 == 0: c = ROCK_D                          # vetas
        return c
    M.paint(paint)
    cap_snow(M, 0.55, 1)
    return M


def estalagmita():
    """Estalagmita de roca de 3 m, en tramos que se estrechan, con hielo en la punta."""
    M = Model(S=2, seed=52)
    for i, (y0, r) in enumerate(((0, 4.0), (8, 3.0), (16, 2.0), (24, 1.2), (30, 0.6))):
        M.cone((0.3 * i, y0, 0), (0.3 * i + 0.2, y0 + 9, 0.2), r, P, ROCK_D, ROCK, tip_r=r * 0.65)
    def paint(k, part, c):
        x, y, z = k
        if y > 48: return ICE
        return lerp(ROCK_D, ROCK_L, M.noise(x, y, z, 5.0) * 0.8)
    M.paint(paint)
    return M


def columna_tallada():
    """Columna de los Antiguos rota: fuste de cinco caras con relieves de estrellas de
    cinco puntas, base escalonada y el trozo caído al lado."""
    M = Model(S=2, seed=53)
    def shaft(y0, y1, cx=0.0, cz=0.0, lying=False):
        for y in range(int(y0 * 2), int(y1 * 2)):
            for x in range(-12, 13):
                for z in range(-12, 13):
                    a = math.atan2(z, x)
                    r = 5.5 / math.cos(((a + math.pi / 5) % (2 * math.pi / 5)) - math.pi / 5)   # pentágono
                    if math.hypot(x / 2, z / 2) > r: continue
                    px, py, pz = (y + int(cx * 2), 2 + x // 2 + 4, z + int(cz * 2)) if lying else (x + int(cx * 2), y, z + int(cz * 2))
                    if lying: px, py, pz = y + int(cx * 2), x + 12, z + int(cz * 2)
                    M.put(px, py, pz, P, STONE)
    M.box(-8, 0, -8, 8, 2, 8, P, STONE_D)                             # base escalonada
    M.box(-7, 2, -7, 7, 3, 7, P, STONE_D)
    shaft(1.5, 30.0)
    shaft(0, 9, cx=9, cz=4, lying=True)                               # el trozo caído
    def paint(k, part, c):
        x, y, z = k
        if c == STONE_D: return c
        # relieves: estrella de cinco puntas cada 10 voxels de alto, en la cara que da al frente
        cy = (y // 10) * 10 + 5
        a = math.atan2(y - cy, x)
        rr = math.hypot(x, y - cy)
        star = 3.2 * (0.55 + 0.45 * math.cos(5 * a))
        if z > 7 and rr < star: return STONE_D
        return lerp(STONE_D, STONE, 0.55 + 0.45 * M.noise(x, y, z, 6.0))
    M.paint(paint)
    cap_snow(M, 0.7)
    return M


def cristales():
    """Grupo de cristales de hielo que salen del suelo, con luz propia (sin sombreado)."""
    M = Model(S=2, seed=54)
    for i in range(7):
        a = i / 7 * math.tau + M.rng.uniform(-0.3, 0.3)
        r = 0 if i == 0 else M.rng.uniform(2.0, 4.0)
        base = (math.cos(a) * r, 0, math.sin(a) * r)
        h = M.rng.uniform(6, 13) * (1.3 if i == 0 else 1.0)
        tip = (base[0] * 1.6, h, base[2] * 1.6)
        M.cone(base, tip, M.rng.uniform(1.2, 2.0), P, ICE, ICE_L, tip_r=0.3)
    for v in M.V.values(): v[2] = 1                                   # brillan
    M.sell(0, 0.5, 0, 6, 1.2, 6, P, ROCK_D, p=2.5)                    # roca de la base, sin brillo
    return M


PIECES = {'roca_grande': roca_grande, 'estalagmita': estalagmita, 'columna_tallada': columna_tallada,
          'cristales': cristales}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M = fn()
        n = M.export('models/atrezo_%s.json' % name, {P: [0, 0, 0]}, jitter=0.01, pivots_in_voxels=True,
                     roughness=0.85 if name != 'cristales' else 0.2, specular=0.25 if name != 'cristales' else 0.7,
                     no_bottom=True)
        print('atrezo_%s: %d voxels' % (name, n))
