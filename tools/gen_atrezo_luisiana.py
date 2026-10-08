"""Atrezo de los pantanos de Luisiana y el ritual del culto (hito 7.2). Una parte "body",
origen en el centro de la base.

  hoguera     hoguera grande de troncos cruzados con llamas que brillan (pivote "light") (32/m)
  monolito    el monolito de piedra en medio del claro, de 2,6 m, con jeroglíficos; el ídolo
              va encima como otra pieza (cth_idolo con "y") (32/m)
  cipres      ciprés calvo del pantano: tronco ensanchado en la base, "rodillas" que salen del
              agua y barbas de musgo español colgando de las ramas (32/m)
  choza       choza de tablas sobre pilotes con tejado de chapa (16/m)
  poste       poste con una antorcha y una calavera de vaca (32/m)
  piragua     piragua de un tronco varada (32/m)

Escribe models/lui_<pieza>.json. Uso: python tools/gen_atrezo_luisiana.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
LOG = (0.30, 0.22, 0.15); LOG_D = (0.18, 0.13, 0.09); ASH = (0.20, 0.19, 0.18); EMBER = (1.0, 0.45, 0.15)
FLAME = (1.0, 0.62, 0.22); FLAME_C = (1.0, 0.88, 0.50)
STONE = (0.20, 0.23, 0.21); STONE_D = (0.12, 0.14, 0.13); CARVE = (0.06, 0.08, 0.07)
BARK = (0.32, 0.26, 0.20); BARK_D = (0.20, 0.16, 0.12)
MOSS = (0.50, 0.54, 0.44); MOSS_D = (0.36, 0.40, 0.32)
PLANK = (0.40, 0.34, 0.26); PLANK_D = (0.28, 0.23, 0.17); TIN = (0.36, 0.30, 0.26); RUST = (0.44, 0.26, 0.14)
BONE = (0.80, 0.76, 0.64); BONE_D = (0.55, 0.52, 0.44)


def line(M, a, b, r, col):
    n = int(max(abs(b[i] - a[i]) for i in range(3))) + 1
    for k in range(n + 1):
        t = k / max(n, 1)
        c = [a[i] + (b[i] - a[i]) * t for i in range(3)]
        ri = int(math.ceil(r))
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    if x * x + y * y + z * z <= r * r + 0.3:
                        q = (int(round(c[0] + x)), int(round(c[1] + y)), int(round(c[2] + z)))
                        M.put(*q, P, col(*q) if callable(col) else col)


def flames(M, cx, cz, y0, h, r0):
    for y in range(y0, y0 + h):
        r = r0 * (1 - (y - y0) / h) + 0.5
        for x in range(-int(r) - 1, int(r) + 2):
            for z in range(-int(r) - 1, int(r) + 2):
                d = math.hypot(x, z)
                if d > r or M.hsh(x + cx, y, z + cz) < 0.25 * (y - y0) / h: continue
                M.put(cx + x, y, cz + z, P, FLAME_C if d < r * 0.4 and y < y0 + h * 0.6 else FLAME, glow=1)


def hoguera():
    M = Model(S=2, seed=91)
    for x in range(-14, 15):                                    # cerco de piedras y ceniza
        for z in range(-14, 15):
            d = math.hypot(x, z)
            if 12 <= d <= 14 and (x + z) % 3: M.put(x, 0, z, P, STONE); M.put(x, 1, z, P, STONE_D)
            elif d < 12: M.put(x, 0, z, P, EMBER if M.hsh(x, 0, z) > 0.8 else ASH, glow=1 if M.hsh(x, 0, z) > 0.8 else 0)
    for k in range(6):                                          # troncos cruzados en cono
        a = k / 6 * math.tau
        line(M, (math.cos(a) * 11, 1, math.sin(a) * 11), (math.cos(a) * 2, 18, math.sin(a) * 2), 1.6,
             lambda x, y, z: LOG_D if (x + y) % 4 == 0 else LOG)
    flames(M, 0, 0, 4, 34, 7)
    return M, {P: [0, 0, 0], 'light': [0, 20, 0]}


def monolito():
    M = Model(S=2, seed=92)
    for y in range(0, 84):
        w = 14 - y // 14
        for x in range(-w, w):
            for z in range(-w + 3, w - 3):
                if min(x + w, w - 1 - x, z + w - 3, w - 4 - z) > 1 and y < 82: continue
                c = lerp(STONE, STONE_D, M.noise(x, y, z, 6.0))
                if z == w - 4 and 8 < y < 76 and (x * 3 + y * 5) % 7 == 0: c = CARVE
                M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def cipres():
    M = Model(S=2, seed=93)
    rng = M.rng
    def bark(x, y, z): return BARK_D if M.noise(x, y, z, 3.0) > 0.6 else BARK
    for y in range(0, 150):                                     # tronco que se ensancha abajo
        r = 4.5 + max(0, 18 - y) * 0.35
        lobes = 1 + 0.25 * math.sin(math.atan2(1, 1) * 6) if y < 18 else 1
        for x in range(-int(r) - 1, int(r) + 2):
            for z in range(-int(r) - 1, int(r) + 2):
                d = math.hypot(x, z) * (1 + 0.18 * math.sin(math.atan2(z, x) * 5) * (y < 20))
                if r - 1.8 <= d <= r: M.put(x, y, z, P, bark(x, y, z))
    for k in range(7):                                          # "rodillas" del ciprés
        a = rng.uniform(0, math.tau); dd = rng.uniform(12, 20)
        for y in range(0, rng.randint(6, 12)):
            for x in range(-1, 2):
                for z in range(-1, 2): M.put(int(math.cos(a) * dd) + x, y, int(math.sin(a) * dd) + z, P, bark(x, y, z))
    tips = []
    for i in range(7):                                          # ramas casi horizontales arriba
        a = i / 7 * math.tau + rng.uniform(-0.3, 0.3)
        y0 = 90 + i * 8
        tip = (math.cos(a) * rng.uniform(22, 32), y0 + rng.uniform(4, 12), math.sin(a) * rng.uniform(22, 32))
        line(M, (0, y0, 0), tip, 1.5, bark)
        tips.append((tip, (0, y0, 0)))
    for tip, base in tips:                                      # musgo español colgando a lo largo de la rama
        for k in range(10):
            t = 0.3 + k * 0.07
            px = base[0] + (tip[0] - base[0]) * t; py = base[1] + (tip[1] - base[1]) * t; pz = base[2] + (tip[2] - base[2]) * t
            n = rng.randint(10, 28)
            for j in range(n):
                M.put(int(px + math.sin(j * 0.4) * 0.8), int(py - j), int(pz), P, MOSS if j % 3 else MOSS_D, over=False)
    for x in range(-10, 11):                                    # copa rala
        for z in range(-10, 11):
            if math.hypot(x, z) < 10 and M.hsh(x, 1, z) > 0.55:
                M.put(x, 150 + int(M.hsh(x, 2, z) * 4), z, P, (0.24, 0.30, 0.18))
    return M, {P: [0, 0, 0]}


def choza():
    M = Model(S=1, seed=94)
    for x in (-26, 25):                                         # pilotes
        for z in (-18, 17):
            for y in range(0, 14): M.put(x, y, z, P, LOG_D); M.put(x + 1, y, z, P, LOG_D)
    for x in range(-28, 28):                                    # suelo
        for z in range(-20, 20): M.put(x, 14, z, P, PLANK if (x // 3) % 2 else PLANK_D)
    for y in range(15, 40):                                     # paredes de tablas
        for x in range(-24, 24):
            for z in (-18, 17):
                c = PLANK_D if x % 4 == 0 else PLANK
                if z == 17 and -4 < x < 4 and y < 33: c = (0.04, 0.04, 0.04)   # puerta
                if z == 17 and 10 < x < 18 and 24 < y < 32: c = (0.70, 0.45, 0.20)   # ventana con luz
                M.put(x, y, z, P, c, glow=1 if c == (0.70, 0.45, 0.20) else 0)
        for z in range(-18, 18):
            for x in (-24, 23): M.put(x, y, z, P, PLANK_D if z % 4 == 0 else PLANK)
    for x in range(-28, 28):                                    # tejado de chapa a dos aguas
        for z in range(-22, 22):
            y = 46 - abs(z) // 3
            M.put(x, y, z, P, RUST if M.noise(x, y, z, 6.0) > 0.6 else TIN)
    for x in range(-6, 6):                                      # escalera
        for k in range(7): M.put(x, 2 + k * 2, 20 + k, P, PLANK_D)
    return M, {P: [0, 0, 0]}


def poste():
    M = Model(S=2, seed=95)
    for y in range(0, 70):
        for x in (-1, 0):
            for z in (-1, 0): M.put(x, y, z, P, LOG_D if y % 9 == 0 else LOG)
    for x in range(-5, 5):                                      # calavera de vaca con cuernos
        for y in range(52, 60):
            if abs(x + 0.5) < 4 - (60 - y) // 4: M.put(x, y, 1, P, BONE)
    for x in (-3, 2): M.put(x, 57, 2, P, (0.05, 0.05, 0.05))
    for s in (-1, 1):
        for k in range(7): M.put(s * (4 + k), 59 + k // 3, 1, P, BONE_D)
    for y in range(70, 74):
        for x in range(-2, 2):
            for z in range(-2, 2): M.put(x, y, z, P, (0.20, 0.16, 0.12))
    flames(M, 0, 0, 74, 12, 2.5)
    return M, {P: [0, 0, 0], 'light': [0, 78, 0]}


def piragua():
    M = Model(S=2, seed=96)
    for x in range(-44, 44):
        w = 6 * math.sqrt(max(0.0, 1 - (x / 44) ** 2))
        for z in range(-int(w), int(w) + 1):
            for y in range(0, 6):
                inside = abs(z) < w - 1.5 and y > 1
                if inside: continue
                M.put(x, y, z, P, LOG if (x + y) % 5 else LOG_D)
    for k in range(20): M.put(10 + k, 6, 3 - k // 6, P, PLANK)   # el remo
    return M, {P: [0, 0, 0]}


PIECES = {'hoguera': hoguera, 'monolito': monolito, 'cipres': cipres, 'choza': choza, 'poste': poste,
          'piragua': piragua}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export('models/lui_%s.json' % name, piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.85, specular=0.3, no_bottom=True)
        print('lui_%s: %d voxels' % (name, n))
