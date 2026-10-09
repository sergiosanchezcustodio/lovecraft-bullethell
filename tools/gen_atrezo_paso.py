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


def estalagmita(variant=1):
    """Grupo de estalagmitas (rehecho el 09-10-2026), 32/m: una principal de ~3 m y dos o tres
    menores, cada una con perfil de gota que se afila, acanaladuras verticales por donde baja el
    agua, bandas de depósito mineral más claras, una colada de flujo en la base que las une y
    escarcha pálida en las puntas. Hueca. Dos variantes."""
    M = Model(S=2, seed=52 + variant * 11)
    rng = M.rng
    FLOW = (0.44, 0.45, 0.46); FLOW_L = (0.54, 0.55, 0.57); FROST = (0.74, 0.80, 0.88)   # gris frío: beige salía marrón

    def spike(cx, cz, h, r0, lean):
        for y in range(0, h):
            t = y / h
            r = r0 * (1 - t) ** 0.85 + 0.6                       # perfil de gota afilada
            ox, oz = cx + lean[0] * y, cz + lean[1] * y
            for x in range(int(ox - r) - 2, int(ox + r) + 3):
                for z in range(int(oz - r) - 2, int(oz + r) + 3):
                    ang = math.atan2(z - oz, x - ox)
                    d = math.hypot(x - ox, z - oz) * (1 + 0.12 * math.sin(ang * 7 + cx))   # acanaladuras
                    if not (r - 2.2 <= d <= r): continue
                    groove = math.sin(ang * 7 + cx) > 0.6
                    c = lerp(ROCK_D, ROCK, M.noise(x, y * 0.25, z, 3.0))
                    if groove: c = lerp(c, ROCK_D, 0.5)
                    if (y + int(4 * M.noise(x, 0, z, 6.0))) % 11 < 2: c = lerp(c, FLOW_L, 0.45)   # bandas
                    if M.noise(x, y, z, 2.5) > 0.7: c = lerp(c, FLOW, 0.4)                       # brillo húmedo
                    if t > 0.86: c = lerp(c, FROST, (t - 0.86) / 0.14)                          # escarcha
                    M.put(int(x), y, int(z), P, c)

    spikes = [(0, 0, 96 if variant == 1 else 80, 9, (rng.uniform(-0.03, 0.03), rng.uniform(-0.03, 0.03)))]
    for k in range(2 + variant):
        ang = rng.uniform(0, math.tau); d = rng.uniform(9, 15)
        spikes.append((math.cos(ang) * d, math.sin(ang) * d, rng.randint(26, 56), rng.uniform(3.5, 6),
                       (math.cos(ang) * 0.05, math.sin(ang) * 0.05)))
    for cx, cz, h, r0, lean in spikes:
        spike(cx, cz, h, r0, lean)
    for x in range(-20, 21):                                    # colada en la base
        for z in range(-20, 21):
            d = math.hypot(x, z) * (1 + 0.25 * M.noise(x, 0, z, 5.0))
            if d > 18: continue
            hgt = int(4 * (1 - d / 18) ** 1.5) + (1 if M.noise(x, 3, z, 3.0) > 0.6 else 0)
            for y in range(0, hgt + 1):
                M.put(x, y, z, P, lerp(FLOW, FLOW_L, M.noise(x, y, z, 2.0)) if y == hgt else ROCK_D, over=False)
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


PIECES = {'roca_grande_mano': roca_grande,   # la del juego es de Replicate (generar_modelo_replicate.py)
          'estalagmita': estalagmita, 'estalagmita_2': lambda: estalagmita(2), 'columna_tallada': columna_tallada,
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
