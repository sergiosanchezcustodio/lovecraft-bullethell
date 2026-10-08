"""Atrezo de R'lyeh emergida (hito 7.5). Una parte "body", origen en el centro de la base.
Piedra verdinegra con limo; nada está a escuadra: las caras se inclinan y los ángulos no
cuadran.

  puerta     la puerta colosal: un marco monumental de 18 m de ancho y 14 de alto con la losa
             negra entreabierta y el resplandor verde de dentro (8/m: pieza de borde)
  muro       tramo de muro ciclópeo inclinado, con jeroglíficos (8/m: pieza de borde)
  monolito   monolito torcido de 6 m que se inclina en dos ejes (32/m)
  escalera   tramo de escalera que sube a ninguna parte, con escalones de alturas desiguales (32/m)
  bloque     bloque tallado volcado, de caras torcidas (32/m)

Escribe models/rly_<pieza>.json. Uso: python tools/gen_atrezo_rlyeh.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
ST = (0.16, 0.22, 0.19); ST_D = (0.08, 0.12, 0.10); ST_L = (0.24, 0.32, 0.27)
SLIME = (0.20, 0.34, 0.20); CARVE = (0.04, 0.06, 0.05); VOID = (0.01, 0.02, 0.02); GLOW = (0.35, 1.0, 0.5)


def stone(M, x, y, z):
    c = lerp(ST, ST_D, M.noise(x, y, z, 7.0))
    if M.noise(x, y, z, 2.5) > 0.8: c = ST_L
    if M.noise(x, y + 30, z, 5.0) > 0.7: c = SLIME
    return c


def half_res(M):
    H = Model(S=1, seed=0)
    for (x, y, z), v in M.V.items():
        if x % 2 == 0 and y % 2 == 0 and z % 2 == 0: H.V[(x // 2, y // 2, z // 2)] = v
    H.S = 0.5
    return H


def puerta():
    """A 16/m y exportada a 8/m. Ancho 18 m (x de -144 a 144), alto 14 (224), fondo 3 (z -48..0).
    Las jambas se inclinan hacia dentro distinto cada una; el dintel está torcido."""
    M = Model(S=1, seed=111)
    for y in range(0, 224):
        for x in range(-144, 144):
            for z in range(-48, 0):
                lean_l = -112 + y * 0.12; lean_r = 104 - y * 0.06       # jambas que no son paralelas
                lintel = 184 + (x + 144) * 0.08                         # dintel inclinado
                inside = lean_l < x < lean_r and y < lintel
                if inside:
                    if z == -40:                                        # la losa: negra, entreabierta
                        c = VOID if x < (lean_l + lean_r) / 2 - 10 else (0.03, 0.05, 0.04)
                        if abs(x - ((lean_l + lean_r) / 2 - 10)) < 3: M.put(x, y, z, P, GLOW, glow=1); continue
                        M.put(x, y, z, P, c)
                    continue
                if min(z + 48, -1 - z) > 1 and y < 222 and abs(x) < 142: continue   # hueca
                c = stone(M, x, y, z)
                if z == -1 and (x * 3 + y * 5) % 11 == 0 and y < 200: c = CARVE
                M.put(x, y, z, P, c)
    return half_res(M), {P: [0, 0, 0], 'light': [0, 30, -10]}


def muro():
    M = Model(S=1, seed=112)
    for y in range(0, 160):
        for x in range(-96, 96):
            lean = int(y * 0.18)
            for z in range(-24, 0):
                zz = z - lean
                if min(z + 24, -1 - z) > 1 and y < 158: continue
                c = stone(M, x, y, zz)
                if z == -1 and ((x + y // 2) % 9 == 0 or y % 32 == 0): c = CARVE
                M.put(x, y, zz, P, c)
    return half_res(M), {P: [0, 0, 0]}


def monolito():
    M = Model(S=2, seed=113)
    for y in range(0, 190):
        cx, cz = y * 0.12, y * 0.05
        w = 14 - y // 22
        for x in range(-w, w):
            for z in range(-w + 4, w - 4):
                if min(x + w, w - 1 - x, z + w - 4, w - 5 - z) > 1 and y < 189: continue
                c = stone(M, x, y, z)
                if z == w - 5 and y % 14 < 2: c = CARVE
                M.put(int(x + cx), y, int(z + cz), P, c)
    return M, {P: [0, 0, 0]}


def escalera():
    M = Model(S=2, seed=114)
    y = 0
    for i in range(10):
        h = 4 + (i * 7) % 5                                             # escalones desiguales
        for x in range(-24, 24):
            for z in range(i * 9 - 45, i * 9 - 36):
                for yy in range(0, y + h):
                    if yy < y + h - 2 and z > i * 9 - 44 and abs(x) < 22: continue
                    M.put(x + int(i * 1.5), yy, z, P, stone(M, x, yy, z))
        y += h
    return M, {P: [0, 0, 0]}


def bloque():
    M = Model(S=2, seed=115)
    for y in range(0, 34):
        for x in range(-26, 26):
            for z in range(-18, 18):
                xx = x + int(y * 0.3); zz = z - int(y * 0.15)              # caras torcidas
                if min(x + 26, 25 - x, z + 18, 17 - z, y, 33 - y) > 1: continue
                c = stone(M, xx, y, zz)
                if z == 17 and (x * 5 + y * 3) % 7 == 0: c = CARVE
                M.put(xx, y, zz, P, c)
    return M, {P: [0, 0, 0]}


PIECES = {'puerta': puerta, 'muro': muro, 'monolito': monolito, 'escalera': escalera, 'bloque': bloque}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/rly_%s.json' % name, piv, jitter=0.006, pivots_in_voxels=True,
                     roughness=0.55, specular=0.4, no_bottom=True)
        print('rly_%s: %d voxels' % (name, n))
