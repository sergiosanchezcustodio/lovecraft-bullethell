"""Atrezo de la parte 4, *La búsqueda onírica de la desconocida Kadath* (las Tierras del Sueño, hito 21.9).
Una parte "body", origen en el centro de la base, la cara principal hacia +Z (como gen_atrezo_dunwich.py).
Es un sueño: de noche, pero con algo más de color que las partes 1 a 3 (D-53).

Nivel 1, el bosque encantado y las afueras de Ulthar:
  roble_1/2   roble enorme del bosque encantado: raíces que se retuercen, musgo y yesqueros que brillan (16/m)
  roble_3     roble más pequeño, para dentro de la arena (16/m)
  hongos      corro de setas que brillan en verde azulado, con su luz (32/m; "light")
  hongos_2    setas violetas más pequeñas, sin luz (32/m)
  tocon       tocón hueco con la boca de una madriguera de zoogs entre las raíces (32/m)
  helecho     mata de helechos (32/m; se rompe)
  losa        la gran losa con su argolla de hierro, en un claro: debajo está el mundo de los gugs (16/m)
  casa_1/2    casas de Ulthar: entramado de madera, el piso de arriba volado, tejado empinado de teja,
              chimeneas y ventanas encendidas (16/m)

Nivel 2, el puerto de Dylath-Leen:
  galera      la galera negra de los mercaderes de Leng, atracada: casco largo y bajo, remos, un mástil
              con la vela recogida, el espolón de bronce, faroles verdosos, la escotilla de la bodega
              ("hatch") y la pasarela al muelle (16/m; "light")
  torre_1/2   torres finas y angulosas de basalto, con rendijas encendidas y la punta afilada (16/m)
  almacen     almacén bajo de basalto con la puerta en arco y un pretil (16/m)
  puesto      puesto del mercado: mostrador, toldo de rayas carmesí y azafrán, sedas y rubíes (32/m)
  anforas     ánforas de barro en corro, alguna tumbada (32/m)

Nivel 3, la meseta de Leng:
  monasterio  el monasterio sin ventanas del sumo sacerdote: piedra gris, muros en talud, cúpula baja,
              bajorrelieves y una sola puerta con luz amarilla dentro (16/m; "door")
  choza_1/2   chozas redondas de piedra de los hombres de Leng, con tejado cónico de lajas y una piel de
              cortina (16/m)
  leon        león alado de diorita de Sarkomand, echado sobre su pedestal (16/m)
  roca_1/2    agujas de roca gris violácea, partidas (16/m)
  barrera_1/2/3  tramos de acantilado para el borde, sin nieve (de gen_barrera_roca.py, 16/m)
  pena_1/2    peñas bajas de lajas para el borde del sur y el este (16/m)

Nivel 4, el mundo de abajo de los gugs:
  muro_zin_1/2/3  tramos de muralla ciclópea de la ciudad de los gugs para el borde: sillares de 2 m, juntas
              hondas, salitre y la coronación rota (16/m; 8 m de ancho, el frente hacia +Z, como la barrera)
  torre_koth  la torre de Koth, redonda y escalonada, con su puerta de arco enorme (8/m)
  lapida_1/2  lápidas monolíticas de Zin, toscas e inclinadas, con signos tallados (16/m)
  huesos      un montón de huesos y calaveras de los que bajaron y no volvieron (16/m)
  cripta      la boca de la cripta por la que suben los necrófagos: brocal de piedra y escalones que bajan
              a lo negro (16/m)
  hongos_zin  corro de hongos pálidos que brillan, violáceos (16/m; "light")
  bloque_1/2  sillares caídos para el borde del sur y el este, bajos (16/m)

Nivel 5, la cima de Kadath en el yermo helado:
  muro_onice_1/2/3  tramos de la muralla del castillo de ónice para el borde: ónice negro pulido con vetas
              violáceas, pilastras, almenas, nieve en las cornisas y alguna ventana alta encendida (16/m;
              8 m de ancho, el frente hacia +Z)
  puerta_kadath  la gran puerta del castillo: dos torres, un arco de 12 m con la luz dorada de dentro y la
              escalinata delante (16/m; "light")
  pilar_1/2   pilares de ónice, uno entero con basa y capitel y otro partido con sus trozos (16/m)
  brasero     brasero de ónice sobre tres patas, con las brasas (16/m; "light")
  escombro_1/2  trozos de ónice caídos con nieve, bajos, para el borde del sur y el este (16/m)

Escribe models/sue_<pieza>.json. Uso: python tools/gen_atrezo_sueno.py [piezas...]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
from gen_atrezo_dunwich import ball, tube

P = 'body'
BARK = (0.27, 0.23, 0.21); BARK_D = (0.15, 0.13, 0.13); BARK_L = (0.38, 0.34, 0.31)
MOSS = (0.18, 0.30, 0.16); MOSS_D = (0.11, 0.20, 0.11); MOSS_L = (0.28, 0.40, 0.20)
LEAF_D = (0.06, 0.13, 0.10); LEAF = (0.10, 0.21, 0.14); LEAF_L = (0.17, 0.31, 0.19); LEAF_T = (0.10, 0.24, 0.24)
FUNGUS = (0.46, 0.92, 0.78); FUNGUS_D = (0.20, 0.50, 0.46)                       # verde azulado, brillan
FUNGUS_M = (0.30, 0.68, 0.60)
VIOLET = (0.52, 0.34, 0.70); VIOLET_D = (0.30, 0.18, 0.42)
STEM = (0.80, 0.78, 0.68); STEM_D = (0.58, 0.56, 0.48)
HOLE = (0.02, 0.015, 0.01)
SOIL = (0.17, 0.13, 0.09)
STONE = (0.44, 0.44, 0.42); STONE_D = (0.30, 0.30, 0.30); STONE_L = (0.56, 0.55, 0.52)
IRON = (0.22, 0.20, 0.19); RUST = (0.40, 0.22, 0.12)
FERN = (0.14, 0.27, 0.13); FERN_D = (0.08, 0.17, 0.08); FERN_L = (0.22, 0.38, 0.18)
PLASTER = (0.80, 0.72, 0.56); PLASTER_D = (0.64, 0.57, 0.44)
TIMBER = (0.24, 0.15, 0.10); TIMBER_D = (0.15, 0.09, 0.06)
TILE = (0.56, 0.24, 0.16); TILE_D = (0.38, 0.15, 0.10); TILE_L = (0.66, 0.32, 0.20)
WINDOW = (1.0, 0.72, 0.36); WINDOW_D = (0.86, 0.52, 0.22)
BRICK = (0.48, 0.24, 0.18); BRICK_D = (0.32, 0.15, 0.12)
DOOR = (0.30, 0.16, 0.10)


def bark_of(M):
    def f(x, y, z):
        c = lerp(BARK_D, BARK, 0.35 + 0.6 * M.noise(x, y * 0.4, z, 3.0))
        if M.noise(x + 40, y * 0.25, z, 2.0) > 0.70: c = lerp(c, BARK_D, 0.75)          # surcos
        elif M.hsh(x, y, z) < 0.04: c = BARK_L
        if z < -2 and M.noise(x, y, z + 90, 2.5) > 0.45:                               # musgo al norte (-Z)
            c = lerp(MOSS_D, MOSS, M.noise(x, y, z, 1.5))
        return c
    return f


# ---------------- el bosque encantado ----------------

def _bracket(M, x, y, z, nx, nz, r):
    """Yesquero: media repisa que sale del tronco en la dirección (nx, nz) y brilla por el borde."""
    for a in range(-r, r + 1):
        for b in range(0, r + 1):
            if a * a + b * b > r * r: continue
            px = int(round(x + nx * b - nz * a)); pz = int(round(z + nz * b + nx * a))
            edge = a * a + b * b > (r - 1.2) ** 2
            M.put(px, y, pz, P, FUNGUS if edge else FUNGUS_D, 1 if edge else 0)
            if not edge and b < r - 1: M.put(px, y - 1, pz, P, STEM_D)


def oak(seed, H, R, crown, roots=7, brackets=6, hang=True):
    """Roble enorme y retorcido (16/m): raíces gruesas que se hunden, un tronco que se tuerce y se abre en
    ramas, la copa a matas con huecos, musgo al norte y yesqueros que brillan en el tronco."""
    M = Model(S=1, seed=seed)
    rng = M.rng
    bark = bark_of(M)
    for k in range(roots):                                                            # raíces
        a = k / roots * math.tau + rng.uniform(-0.25, 0.25)
        L = rng.uniform(R * 1.6, R * 2.3)
        mid = (math.cos(a) * L * 0.55, 3.0, math.sin(a) * L * 0.55)
        tube(M, (0, 7, 0), mid, R * 0.42, bark)
        tube(M, mid, (math.cos(a) * L, -1, math.sin(a) * L), R * 0.26, bark)
    pts = [(0.0, 0.0, 0.0)]
    x = z = 0.0
    for y in range(8, H + 1, 8):
        x += rng.uniform(-3.5, 3.5); z += rng.uniform(-3.5, 3.5)
        pts.append((x, y, z))
    for i in range(1, len(pts)):
        tube(M, pts[i - 1], pts[i], R * (1.0 - 0.35 * i / len(pts)), bark)
    # yesqueros en el tronco, de cara al exterior
    for k in range(brackets):
        i = rng.randint(0, len(pts) - 2)
        t = rng.random()
        cx = pts[i][0] + (pts[i + 1][0] - pts[i][0]) * t
        cy = pts[i][1] + (pts[i + 1][1] - pts[i][1]) * t
        cz = pts[i][2] + (pts[i + 1][2] - pts[i][2]) * t
        a = rng.uniform(0, math.tau)
        rr = R * (1.0 - 0.35 * (i + t) / len(pts))
        _bracket(M, cx + math.cos(a) * rr, int(cy) + 2, cz + math.sin(a) * rr, math.cos(a), math.sin(a), rng.randint(2, 4))
    top = pts[-1]
    tips = []
    for k in range(7):
        a = k / 7 * math.tau + rng.uniform(-0.4, 0.4)
        base = pts[max(1, len(pts) - 1 - (k % 3))]                                    # ramas a varias alturas
        L = rng.uniform(crown * 0.9, crown * 1.3)
        mid = (base[0] + math.cos(a) * L * 0.5, base[1] + L * 0.12, base[2] + math.sin(a) * L * 0.5)
        end = (base[0] + math.cos(a) * L, base[1] + L * 0.22 + rng.uniform(-2, 4), base[2] + math.sin(a) * L)
        tube(M, base, mid, R * 0.45, bark)
        tube(M, mid, end, R * 0.28, bark)
        tips.append(end); tips.append(mid)
        if hang:                                                                      # musgo que cuelga
            for h in range(rng.randint(2, 4)):
                hx = int(mid[0] + (end[0] - mid[0]) * rng.random()); hz = int(mid[2] + (end[2] - mid[2]) * rng.random())
                hy = int(mid[1] + (end[1] - mid[1]) * 0.5)
                for d in range(rng.randint(5, 11)): M.put(hx, hy - d, hz, P, MOSS_L if d % 3 else MOSS)
    tips.append((top[0], top[1] + crown * 0.3, top[2]))
    for k in range(14):
        a = rng.uniform(0, math.tau); d = rng.uniform(crown * 0.3, crown * 1.15)
        tips.append((top[0] + math.cos(a) * d, top[1] + rng.uniform(2, crown * 0.35), top[2] + math.sin(a) * d))
    for t in tips:
        r = rng.uniform(crown * 0.24, crown * 0.34)
        def leaf(x, y, z):
            c = lerp(LEAF_D, LEAF, M.noise(x, y, z, 3.0))
            if M.noise(x + 17, y, z, 5.0) > 0.68: c = lerp(c, LEAF_T, 0.6)               # un verde más azul
            if y > t[1] + r * 0.4 and M.hsh(x, y, z) < 0.3: c = LEAF_L
            return c
        ri = int(r)
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    d = math.sqrt(x * x + (y * 1.7) ** 2 + z * z)
                    if d > r or d < r - 3: continue
                    q = (int(t[0] + x), int(t[1] + y), int(t[2] + z))
                    if M.noise(q[0], q[1], q[2], 2.0) < 0.32: continue                   # huecos
                    M.put(*q, P, leaf(*q))
    return M, {P: [0, 0, 0]}


def roble_1(): return oak(4101, 56, 9.5, 36)
def roble_2(): return oak(4102, 48, 8.5, 32, roots=6, brackets=5)
def roble_3(): return oak(4103, 36, 6.0, 24, roots=5, brackets=3, hang=False)


def _mushroom(M, x, z, h, r, cap, cap_d, glow, mid=None):
    mid = mid or lerp(cap_d, cap, 0.5)
    for y in range(h): M.put(x, y, z, P, STEM if y > 0 else STEM_D)
    for a in range(-r, r + 1):
        for b in range(-r, r + 1):
            d = math.sqrt(a * a + b * b)
            if d > r + 0.3: continue
            yy = h + int(round((1.0 - (d / (r + 0.5)) ** 2) * max(1.0, r * 0.6)))
            for y in range(h - (1 if d > r - 1.2 else 0), yy + 1):
                top = y == yy
                rim = d > r - 1.1
                spot = top and not rim and M.hsh(x + a, y, z + b) < 0.12
                col = STEM if spot else (cap if rim else (mid if top else cap_d))
                M.put(x + a, y, z + b, P, col, glow if (rim or spot or top) else 0)


def hongos():
    """Corro de setas de 32/m: una docena de sombreros verde azulado que brillan, de varios tamaños, sobre
    un poco de musgo. Con su luz ("light")."""
    M = Model(S=2, seed=4110)
    rng = M.rng
    for k in range(160):
        a = rng.uniform(0, math.tau); d = rng.uniform(0, 14)
        x, z = int(math.cos(a) * d), int(math.sin(a) * d)
        M.put(x, 0, z, P, lerp(MOSS_D, MOSS, rng.random()))
    spots = [(0, 0, 14, 6), (9, 4, 9, 4), (-8, 6, 7, 3), (3, -10, 11, 4), (-6, -6, 5, 2), (12, -5, 4, 2), (-12, -1, 3, 2)]
    for x, z, h, r in spots: _mushroom(M, x, z, h, r, FUNGUS, FUNGUS_D, 1, FUNGUS_M)
    return M, {P: [0, 0, 0], 'light': [0, 14, 0]}


def hongos_2():
    """Setas violetas de 32/m, más pequeñas y sin luz, con los sombreros que brillan un poco."""
    M = Model(S=2, seed=4111)
    rng = M.rng
    for k in range(5):
        a = k / 5 * math.tau + rng.uniform(-0.3, 0.3); d = rng.uniform(2, 8)
        _mushroom(M, int(math.cos(a) * d), int(math.sin(a) * d), rng.randint(3, 7), rng.randint(2, 3), VIOLET, VIOLET_D, 1)
    return M, {P: [0, 0, 0]}


def tocon():
    """Tocón hueco de 32/m: corteza musgosa con el corte podrido arriba, raíces abiertas y entre dos de
    ellas la boca negra de una madriguera de zoogs, con tierra removida y unas setas."""
    M = Model(S=2, seed=4112)
    bark = bark_of(M)
    R, H = 16, 26
    for y in range(H + 1):
        rr = R * (1.0 + 0.25 * max(0.0, (6 - y) / 6.0))
        top = H - int(4 * M.noise(y, 0, 0, 1.0))
        for x in range(-int(rr) - 1, int(rr) + 2):
            for z in range(-int(rr) - 1, int(rr) + 2):
                d = math.sqrt(x * x + z * z)
                if d > rr or d < rr - 3: continue
                if y > top and d < rr - 1: continue
                if y < 10 and z > 0 and abs(x) < 7 - y * 0.4: continue                     # la boca
                M.put(x, y, z, P, bark(x, y, z))
    for x in range(-R + 3, R - 2):                                                       # el corte, podrido
        for z in range(-R + 3, R - 2):
            if x * x + z * z < (R - 3) ** 2:
                M.put(x, H - 3, z, P, lerp((0.30, 0.22, 0.14), (0.42, 0.32, 0.20), M.noise(x, 0, z, 2.0)))
    for y in range(0, 10):                                                               # la madriguera: negro
        for x in range(-6, 7):
            for z in range(-R + 2, R - 2):
                if abs(x) < 6 - y * 0.4: M.put(x, y, z, P, HOLE)
    for k in range(5):
        a = k / 5 * math.tau + 0.5
        tube(M, (math.cos(a) * R * 0.8, 6, math.sin(a) * R * 0.8), (math.cos(a) * (R + 10), 0, math.sin(a) * (R + 10)), 3.2, bark)
    for k in range(90):                                                                  # tierra removida
        x, z = M.rng.randint(-8, 8), M.rng.randint(R, R + 12)
        M.put(x, 0, z, P, SOIL)
        if M.rng.random() < 0.3: M.put(x, 1, z, P, SOIL)
    for k in range(4):
        _mushroom(M, M.rng.randint(-14, 14), -R - M.rng.randint(1, 6), M.rng.randint(2, 4), 2, VIOLET, VIOLET_D, 1)
    return M, {P: [0, 0, 0]}


def helecho():
    """Mata de helechos de 32/m: frondas largas que se arquean hacia fuera, con los foliolos a los lados."""
    M = Model(S=2, seed=4113)
    rng = M.rng
    for k in range(11):
        a = k / 11 * math.tau + rng.uniform(-0.2, 0.2)
        L = rng.uniform(16, 24)
        for s in range(int(L)):
            t = s / L
            r = L * t
            x = math.cos(a) * r; z = math.sin(a) * r
            y = 4 + 14 * math.sin(math.pi * t * 0.75) * (1 - t * 0.35)
            c = lerp(FERN_D, FERN, t) if s % 4 else FERN_L
            M.put(int(x), int(y), int(z), P, c)
            if 2 < s < L - 1:
                w = int(5 * (1 - t) + 1)
                for q in (-1, 1):
                    for u in range(1, w):
                        M.put(int(x - math.sin(a) * u * q), int(y - u * 0.4), int(z + math.cos(a) * u * q), P,
                              lerp(FERN, FERN_L, rng.random() * 0.6))
    for y in range(5): M.put(0, y, 0, P, FERN_D)
    return M, {P: [0, 0, 0]}


def losa():
    """La gran losa de piedra del bosque, en un claro (16/m): 3,5 m de lado, gastada, con musgo por las
    juntas y una argolla de hierro enorme en el centro. Debajo está el mundo de los gugs (relato y nivel 4)."""
    M = Model(S=1, seed=4114)
    W = 28
    for x in range(-W, W + 1):
        for z in range(-W, W + 1):
            e = max(abs(x), abs(z))
            if e > W - int(2 * M.noise(x, 0, z, 1.0)): continue
            h = 4 if e < W - 2 else 3
            for y in range(h):
                c = lerp(STONE_D, STONE, 0.4 + 0.5 * M.noise(x, y, z, 3.0))
                if y == h - 1 and M.noise(x + 50, 0, z, 2.0) > 0.72: c = lerp(MOSS_D, MOSS, M.noise(x, 0, z, 1.0))
                if y == h - 1 and (abs(x) % 14 == 0 or abs(z) % 14 == 0) and e < W - 3: c = STONE_D   # juntas
                if y == h - 1 and abs(math.sqrt(x * x + z * z) - 9) < 0.7: c = STONE_D              # el círculo grabado
                M.put(x, y, z, P, c)
    for a in range(48):                                                                   # la argolla
        t = a / 48 * math.tau
        x, y = 6 * math.cos(t), 6 * math.sin(t)
        if y < -1: continue
        for k in (-1, 0, 1):
            M.put(int(round(x)), 4 + int(round(y * 0.35)), k, P, IRON if M.hsh(a, 0, k) > 0.25 else RUST)
    for x in range(-2, 3):
        for z in range(-2, 3): M.put(x, 4, z, P, IRON)
    return M, {P: [0, 0, 0]}


# ---------------- Ulthar ----------------

def house(seed, W, D, H1, H2, roof_h, chimneys, lit):
    """Casa de Ulthar de 16/m: planta baja de piedra y yeso, el piso de arriba volado (2 voxels) con el
    entramado de madera oscura, tejado de dos aguas empinado de teja roja con alero, chimeneas de ladrillo
    con sus chimeneros, ventanas de cuarterones encendidas (brillan) y la puerta."""
    M = Model(S=1, seed=seed)
    rng = M.rng
    O = 2                                                                                  # vuelo del piso alto

    def wall(x, y, z, x0, x1, z0, z1, upper):
        on_x = x in (x0, x1); on_z = z in (z0, z1)
        u = x if on_z else z
        lo = H1 if upper else 0
        top = H1 + H2 if upper else H1
        timber = upper and (u % 6 == 0 or y == lo or y == top - 1 or (y - lo) == (u % 6) or (y - lo) == 6 - (u % 6))
        if not upper and y < 3: return lerp(STONE_D, STONE, M.noise(x, y, z, 2.0))
        if timber: return TIMBER if M.hsh(x, y, z) > 0.2 else TIMBER_D
        return lerp(PLASTER_D, PLASTER, 0.5 + 0.5 * M.noise(x, y, z, 4.0))

    def shell(x0, x1, z0, z1, y0, y1, upper):
        for y in range(y0, y1):
            for x in range(x0, x1 + 1):
                for z in range(z0, z1 + 1):
                    if x not in (x0, x1) and z not in (z0, z1): continue
                    M.put(x, y, z, P, wall(x, y, z, x0, x1, z0, z1, upper))

    shell(-W, W, -D, D, 0, H1, False)
    shell(-W - O, W + O, -D - O, D + O, H1, H1 + H2, True)
    for x in range(-W - O, W + O + 1):                                                    # el vuelo, por debajo
        for z in range(-D - O, D + O + 1):
            if abs(x) > W or abs(z) > D: M.put(x, H1, z, P, TIMBER_D)
    # ventanas: de cuarterones, encendidas o a oscuras
    def window(cx, cy, face, w=3, h=4, on=True):
        for a in range(-w, w + 1):
            for b in range(0, h + 1):
                frame = abs(a) == w or b in (0, h) or a == 0 or b == h // 2
                if face == 'z': q = (cx + a, cy + b, D + O + (0 if cy >= H1 else -O))
                else: q = (W + O + (0 if cy >= H1 else -O), cy + b, cx + a)
                if frame: M.put(*q, P, TIMBER_D)
                else: M.put(*q, P, WINDOW if on else (0.10, 0.10, 0.14), 1 if on else 0)
    for i, cx in enumerate(range(-W + 5, W - 3, 9)):
        window(cx, H1 + 3, 'z', on=lit[i % len(lit)])
        if i % 2 == 1: window(cx, 4, 'z', 2, 4, on=lit[(i + 1) % len(lit)])
    window(-D + 6, H1 + 3, 'x', on=lit[-1])
    for y in range(0, 10):                                                                # la puerta
        for a in range(-3, 4):
            M.put(-W + 3 + a + 4, y, D, P, TIMBER_D if abs(a) == 3 or y == 9 else DOOR)
    # tejado de dos aguas (cumbrera a lo largo de X), empinado, con alero
    Rd = D + O + 2
    for z in range(-Rd, Rd + 1):
        y = H1 + H2 + int(round((Rd - abs(z)) * roof_h / Rd))
        for x in range(-W - O - 2, W + O + 3):
            for k in range(2):
                c = lerp(TILE_D, TILE, M.noise(x, y, z, 3.0))
                if z % 3 == 0: c = TILE_D                                                    # las hiladas de teja
                elif M.hsh(x, y, z) < 0.05: c = TILE_L
                if M.noise(x + 30, 0, z, 3.0) > 0.78: c = lerp(c, MOSS, 0.5)
                M.put(x, y - k, z, P, c)
    for x in (-W - O, W + O):                                                             # hastiales
        for z in range(-D - O, D + O + 1):
            top = H1 + H2 + int(round((Rd - abs(z)) * roof_h / Rd)) - 1
            for y in range(H1 + H2, top):
                M.put(x, y, z, P, TIMBER if (z % 5 == 0 or y == H1 + H2) else PLASTER)
    for cx, cz in chimneys:                                                               # chimeneas
        top = H1 + H2 + roof_h + 6
        for y in range(H1 + H2, top):
            for a in range(-2, 3):
                for b in range(-2, 3):
                    if abs(a) == 2 or abs(b) == 2:
                        M.put(cx + a, y, cz + b, P, BRICK if (y + a) % 3 else BRICK_D)
        for y in range(top, top + 3):
            M.put(cx, y, cz, P, TILE_D); M.put(cx + 1, y, cz, P, TILE_D)
    return M, {P: [0, 0, 0]}


def casa_1(): return house(4120, 22, 15, 20, 18, 28, [(-12, -4), (14, 6)], [True, False, True])
def casa_2(): return house(4121, 17, 13, 18, 16, 24, [(8, -3)], [False, True, True, False])


# ---------------- Dylath-Leen ----------------

HULL = (0.07, 0.065, 0.085); HULL_L = (0.13, 0.11, 0.15); HULL_D = (0.035, 0.03, 0.045)
DECK = (0.11, 0.10, 0.11); BRONZE = (0.46, 0.33, 0.16); BRONZE_D = (0.28, 0.20, 0.10); VERD = (0.24, 0.40, 0.34)
SAIL = (0.22, 0.12, 0.17); SAIL_D = (0.14, 0.07, 0.11); ROPE = (0.30, 0.25, 0.18)
GREEN_LAMP = (0.62, 0.95, 0.55)
BASALT = (0.20, 0.20, 0.23); BASALT_D = (0.12, 0.12, 0.15); BASALT_L = (0.31, 0.30, 0.34)
CRIMSON = (0.62, 0.10, 0.14); SAFFRON = (0.86, 0.58, 0.16); SILK_B = (0.16, 0.30, 0.58); SILK_G = (0.18, 0.48, 0.36)
RUBY = (0.95, 0.12, 0.20); CLAY = (0.62, 0.36, 0.22); CLAY_D = (0.44, 0.24, 0.14); CLAY_L = (0.74, 0.46, 0.30)
WOOD = (0.32, 0.21, 0.13); WOOD_D = (0.20, 0.13, 0.08)


def galera():
    """La galera negra (16/m), a lo largo de X con la proa a +X y el costado de babor (+Z) hacia el muelle.
    El origen es la quilla: se pone a flote bajando la pieza (y en la arena), con el agua a unos 0,35 m."""
    M = Model(S=1, seed=4130)
    L = 208                                                  # media eslora (13 m)
    B = 34                                                   # media manga (2,1 m)
    DECK_Y = 36

    def half_w(x, y):
        k = abs(x) / L
        w = B * (1.0 - k ** (2.0 if x > 0 else 3.2))          # la proa, más afilada
        return w * (0.5 + 0.5 * min(1.0, y / 26.0))

    def sheer(x):
        k = abs(x) / L
        return DECK_Y + 6 + int(14 * k ** 3) + (10 if x < -150 else 0)

    def hull_col(x, y, z):
        c = lerp(HULL_D, HULL, 0.4 + 0.6 * M.noise(x * 0.2, y, z, 3.0))
        if y % 7 == 0: c = HULL_D                                                   # las tracas
        elif M.hsh(x, y, z) < 0.03: c = HULL_L
        return c

    for x in range(-L, L + 1):
        top = sheer(x)
        for y in range(0, top + 1):
            w = half_w(x, y)
            if w < 1: continue
            for z in (-1, 1):
                for t in range(2):
                    zz = int(round(z * (w - t)))
                    col = BRONZE if y == top else (hull_col(x, y, zz) if y > 4 else HULL_D)
                    M.put(x, y, zz, P, col)
            if y == DECK_Y:                                                             # la cubierta
                for zz in range(-int(w) + 2, int(w) - 1):
                    M.put(x, y, zz, P, DECK if x % 6 else HULL_D)
        if abs(x) > L - 6:                                                              # cierra las puntas
            for y in range(0, top):
                for zz in range(-int(half_w(x, y)), int(half_w(x, y)) + 1): M.put(x, y, zz, P, hull_col(x, y, zz))
    for x in (-L,):                                                                     # espejo de popa
        for y in range(0, sheer(x) + 1):
            for zz in range(-B, B + 1): M.put(x, y, zz, P, hull_col(x, y, zz))
    # el espolón de bronce y el codaste de proa, que se curva
    for k in range(30):
        for a in range(-2, 3):
            for b in range(-2, 3):
                if a * a + b * b <= 5: M.put(L + k, 6 + a - k // 8, b, P, VERD if (k + a) % 5 == 0 else BRONZE)
    for k in range(40):
        t = k / 40
        x = L - 4 + int(16 * math.sin(t * 1.2)); y = sheer(L) + int(t * 40)
        for a in range(-1, 2): M.put(x, y, a, P, HULL if k < 34 else BRONZE)
    # la toldilla de popa
    for x in range(-L + 2, -L + 62):
        for y in range(DECK_Y, DECK_Y + 30):
            for zz in range(-B + 6, B - 5):
                edge = x in (-L + 2, -L + 61) or zz in (-B + 6, B - 6) or y == DECK_Y + 29
                if not edge: continue
                win = y in range(DECK_Y + 14, DECK_Y + 21) and (zz in (B - 6, -B + 6)) and (x // 8) % 2 == 0
                M.put(x, y, zz, P, GREEN_LAMP if win else (BRONZE if y == DECK_Y + 29 else hull_col(x, y, zz)), 1 if win else 0)
    # los remos: una fila por banda, que bajan al agua
    for k in range(13):
        x = -120 + k * 20
        for zs in (-1, 1):
            w = half_w(x, 26)
            a = (x, 26, zs * w)
            b = (x - 10, 2, zs * (w + 44))
            n = 60
            for i in range(n + 1):
                t = i / n
                q = (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)
                M.put(int(q[0]), int(q[1]), int(q[2]), P, WOOD_D if i < n - 6 else WOOD)
                if i > n - 7: M.put(int(q[0]) + 1, int(q[1]), int(q[2]), P, WOOD)
            M.put(x, 26, int(zs * w), P, HULL_D)
    # el mástil, la verga y la vela recogida
    MX = 20
    for y in range(DECK_Y, DECK_Y + 150):
        for a in range(-2, 2):
            for b in range(-2, 2): M.put(MX + a, y, b, P, WOOD_D if y % 9 else WOOD)
    for zz in range(-60, 61):
        y = DECK_Y + 140 - int(abs(zz) * 0.12)
        for a in range(-1, 1): M.put(MX + a, y, zz, P, WOOD_D)
        for d in range(1, 9):
            c = lerp(SAIL_D, SAIL, M.noise(0, d, zz, 2.0))
            M.put(MX + 2, y - d, zz, P, c); M.put(MX + 3, y - d + 1, zz, P, c)
    for zz in (-58, 58):
        M.line((MX, DECK_Y + 140, zz), (MX - 120 if zz < 0 else MX + 120, DECK_Y + 6, zz * 0.5), P, ROPE)
    M.line((MX, DECK_Y + 148, 0), (L + 10, sheer(L) + 38, 0), P, ROPE)
    M.line((MX, DECK_Y + 148, 0), (-L + 30, DECK_Y + 30, 0), P, ROPE)
    # la escotilla de la bodega, con marco de bronce
    HX = -40
    for x in range(HX - 12, HX + 13):
        for zz in range(-12, 13):
            frame = abs(x - HX) > 9 or abs(zz) > 9
            M.put(x, DECK_Y + (2 if frame else 1), zz, P, BRONZE if frame else (0.03, 0.02, 0.03))
            if frame: M.put(x, DECK_Y + 1, zz, P, BRONZE_D)
    # faroles verdosos en la popa y en la proa
    for k in range(14): M.put(-L - k, DECK_Y + 30, 0, P, BRONZE_D)                    # el brazo del farol de popa
    for lx, ly in ((-L - 14, DECK_Y + 24), (L - 20, sheer(L - 20) + 10)):
        for a in range(-2, 3):
            for b in range(-2, 3):
                for c in range(0, 5): M.put(lx + a, ly + c, b, P, GREEN_LAMP if abs(a) < 2 and abs(b) < 2 else BRONZE_D, 1 if abs(a) < 2 and abs(b) < 2 else 0)
    # la pasarela al muelle, por babor
    for k in range(52):
        y = DECK_Y + 2 - int(k * 0.22)
        for x in range(60, 76):
            M.put(x, y, B + 2 + k, P, WOOD if x % 4 else WOOD_D)
        if k % 6 == 0:
            for x in (60, 75): M.put(x, y + 1, B + 2 + k, P, WOOD_D); M.put(x, y + 2, B + 2 + k, P, WOOD_D)
    return M, {P: [0, 0, 0], 'light': [-L - 14, DECK_Y + 22, 0], 'hatch': [HX, DECK_Y + 2, 0]}


def _basalt(M, x, y, z):
    c = lerp(BASALT_D, BASALT, 0.35 + 0.6 * M.noise(x, y * 0.6, z, 3.0))
    if M.hsh(x, y, z) < 0.03: c = BASALT_L
    return c


def tower(seed, W, H, spire, slits):
    """Torre fina y angulosa de basalto (16/m): planta octogonal que se estrecha, cornisas, rendijas
    encendidas, la puerta y una punta afilada."""
    M = Model(S=1, seed=seed)
    for y in range(H + spire + 1):
        if y <= H:
            w = W * (1.0 - 0.12 * y / H)
        else:
            w = (W * 0.88 + 2) * (1.0 - (y - H) / spire)
        wi = int(w)
        for x in range(-wi - 2, wi + 3):
            for z in range(-wi - 2, wi + 3):
                oct_d = max(abs(x), abs(z), (abs(x) + abs(z)) * 0.72)
                cornice = y <= H and y % 48 in (0, 1)
                r = w + (2 if cornice else 0)
                if oct_d > r or oct_d < r - 2: continue
                c = _basalt(M, x, y, z)
                if cornice: c = BASALT_L
                if y > H and y > H + spire - 6: c = BRONZE
                M.put(x, y, z, P, c)
    for k, (sy, face) in enumerate(slits):                                              # rendijas encendidas
        w = int(W * (1.0 - 0.12 * sy / H))
        for y in range(sy, sy + 10):
            for a in (-1, 0):
                q = (a, y, w) if face == 'z' else (w, y, a)
                M.put(*q, P, WINDOW if y < sy + 9 else BASALT_D, 1 if y < sy + 9 else 0)
    for y in range(0, 18):                                                              # la puerta
        for a in range(-4, 5):
            top = 14 + int(4 * math.cos(a / 4 * math.pi / 2))
            if y > top: continue
            M.put(a, y, W, P, WOOD_D if abs(a) < 4 and y < top else BASALT_L)
    return M, {P: [0, 0, 0]}


def torre_1(): return tower(4131, 20, 176, 44, [(60, 'z'), (110, 'x'), (150, 'z')])
def torre_2(): return tower(4132, 16, 140, 36, [(48, 'x'), (96, 'z')])


def almacen():
    """Almacén bajo de basalto (16/m): 7 x 5 m, 4,5 m de alto, pretil arriba, la puerta grande en arco con
    hojas de madera y dos ventanucos."""
    M = Model(S=1, seed=4133)
    W, D, H = 56, 40, 64
    for y in range(H + 6):
        for x in range(-W, W + 1):
            for z in range(-D, D + 1):
                edge = abs(x) == W or abs(z) == D
                if y >= H:
                    if not edge or (y == H + 5 and (x + z) % 8 < 4): continue                 # el pretil, almenado
                elif not edge: continue
                M.put(x, y, z, P, BASALT_L if y in (H, H - 1) else _basalt(M, x, y, z))
    for x in range(-W + 1, W):
        for z in range(-D + 1, D): M.put(x, H, z, P, BASALT_D)
    for y in range(0, 44):                                                              # la puerta en arco
        for a in range(-16, 17):
            top = 32 + int(12 * math.sqrt(max(0.0, 1 - (a / 16) ** 2)))
            if y > top: continue
            M.put(a, y, D, P, BASALT_L if (y > top - 2 or abs(a) > 14) else (WOOD if (a // 4) % 2 else WOOD_D))
    for wx in (-38, 38):
        for y in range(36, 46):
            for a in range(-3, 4): M.put(wx + a, y, D, P, WINDOW if abs(a) < 3 else BASALT_D, 1 if abs(a) < 3 else 0)
    return M, {P: [0, 0, 0]}


def puesto():
    """Puesto del mercado (32/m): mostrador de madera, cuatro postes y un toldo de rayas carmesí y azafrán
    que cae por delante; encima, rollos de seda de colores y una bandeja de rubíes que brillan."""
    M = Model(S=2, seed=4134)
    W, D = 38, 24
    for y in range(0, 30):                                                              # el mostrador
        for x in range(-W + 4, W - 3):
            for z in (-D + 4, D - 4):
                M.put(x, y, z, P, WOOD if (x // 5) % 2 else WOOD_D)
        for z in range(-D + 4, D - 3):
            for x in (-W + 4, W - 4): M.put(x, y, z, P, WOOD_D)
    for x in range(-W + 4, W - 3):
        for z in range(-D + 4, D - 3): M.put(x, 30, z, P, WOOD)
    for px in (-W, W):                                                                  # postes
        for pz in (-D, D):
            for y in range(0, 74): M.put(px, y, pz, P, WOOD_D)
    for x in range(-W - 2, W + 3):                                                      # el toldo
        for z in range(-D - 2, D + 10):
            y = 74 - int(max(0, z - D) * 1.6) + int(abs(z) * 0.1)
            M.put(x, y, z, P, CRIMSON if (x // 6) % 2 else SAFFRON)
            if z == D + 9 and x % 2 == 0: M.put(x, y - 2, z, P, SAFFRON)                 # flecos
    for k, c in enumerate((SILK_B, CRIMSON, SILK_G, SAFFRON)):                          # rollos de seda
        x0 = -W + 8 + k * 10
        for x in range(x0, x0 + 8):
            for a in range(-3, 4):
                for b in range(-3, 4):
                    if a * a + b * b <= 10: M.put(x, 34 + a, -6 + b, P, c if a * a + b * b < 8 else lerp(c, (0, 0, 0), 0.3))
    for x in range(8, 30):                                                              # la bandeja de rubíes
        for z in range(2, 16):
            edge = x in (8, 29) or z in (2, 15)
            M.put(x, 31, z, P, BRONZE if edge else BRONZE_D)
            if not edge and M.hsh(x, 0, z) < 0.35: M.put(x, 32, z, P, RUBY, 1)
    return M, {P: [0, 0, 0]}


def anforas():
    """Ánforas de barro (32/m): seis en corro, de pie, y una tumbada, con asas y la boca estrecha."""
    M = Model(S=2, seed=4135)
    rng = M.rng
    def amph(cx, cz, lying=False):
        for t in range(0, 40):
            r = 2 + 7 * math.sin(math.pi * min(1.0, t / 34.0)) ** 0.8 if t < 34 else 2
            for a in range(-int(r) - 1, int(r) + 2):
                for b in range(-int(r) - 1, int(r) + 2):
                    d = math.sqrt(a * a + b * b)
                    if d > r or d < r - 1.6: continue
                    c = lerp(CLAY_D, CLAY, 0.5 + 0.5 * M.noise(a, t, b, 2.0))
                    if t == 26: c = CLAY_D
                    elif M.hsh(a, t, b) < 0.04: c = CLAY_L
                    q = (cx + t - 20, int(r) + 1 + a, cz + b) if lying else (cx + a, t, cz + b)
                    M.put(*q, P, c)
        for s in (-1, 1):                                                               # asas
            for k in range(8):
                q = (cx + s * (4 + k // 3), 34 - k, cz) if not lying else (cx + 14 - k, 4 + s * (4 + k // 3), cz)
                M.put(*q, P, CLAY_D)
    for k in range(6):
        a = k / 6 * math.tau + rng.uniform(-0.2, 0.2)
        amph(int(math.cos(a) * 21), int(math.sin(a) * 21))
    amph(6, 42, lying=True)
    return M, {P: [0, 0, 0]}


# ---------------- la meseta de Leng ----------------

LENG = (0.36, 0.34, 0.38); LENG_D = (0.22, 0.21, 0.25); LENG_L = (0.48, 0.46, 0.50)
DIORITE = (0.27, 0.29, 0.29); DIORITE_D = (0.15, 0.16, 0.17); DIORITE_L = (0.40, 0.42, 0.41)
FUR = (0.34, 0.27, 0.20); FUR_D = (0.22, 0.17, 0.12)
YELLOW_LIGHT = (1.0, 0.86, 0.36)
EMBER = (1.0, 0.46, 0.16)


def _leng(M, x, y, z):
    c = lerp(LENG_D, LENG, 0.35 + 0.6 * M.noise(x, y * 0.6, z, 3.0))
    if M.hsh(x, y, z) < 0.03: c = LENG_L
    return c


def recolor(M, f):
    for k, v in M.V.items(): v[1] = f(*k)


def monasterio():
    """El monasterio sin ventanas (16/m): 10 x 8 m de piedra gris, muros en talud con hiladas, una cúpula baja
    y achatada, bajorrelieves en franja bajo la cornisa y una sola puerta, alta y estrecha, por la que sale
    luz amarilla. Detrás de esa puerta está el sumo sacerdote que no debe describirse."""
    M = Model(S=1, seed=4140)
    W, D, H = 80, 64, 80
    for y in range(H + 1):
        k = 1.0 - 0.10 * y / H                                                           # talud
        w, d = int(W * k), int(D * k)
        for x in range(-w, w + 1):
            for z in range(-d, d + 1):
                if abs(x) < w - 2 and abs(z) < d - 2:
                    if y != H or math.sqrt(x * x + (z * 1.2) ** 2) < int(W * 0.9 * 0.82) - 4: continue   # hueco
                c = _leng(M, x, y, z)
                if y % 12 == 0: c = LENG_D                                                  # hiladas
                if 60 <= y <= 70 and (abs(z) >= d - 2 or abs(x) >= w - 2):                  # la franja de relieves
                    u = x if abs(z) >= d - 2 else z
                    if (u // 4 + y // 3) % 3 == 0 or M.noise(u, y, 0, 2.0) > 0.66: c = LENG_D
                    elif y in (60, 70): c = LENG_L
                M.put(x, y, z, P, c)
    R = int(W * 0.9 * 0.82)
    for y in range(0, 34):                                                               # cúpula baja
        r = R * math.sqrt(max(0.0, 1 - (y / 34.0) ** 2))
        ri = int(r)
        for x in range(-ri, ri + 1):
            for z in range(-ri, ri + 1):
                dd = math.sqrt(x * x + (z * 1.2) ** 2)
                if dd > r or dd < r - 3: continue
                M.put(x, H + y, z, P, _leng(M, x, y, z) if y % 9 else LENG_D)
    for y in range(0, 44):                                                               # la puerta, con luz
        for a in range(-7, 8):
            top = 36 + int(8 * math.cos(a / 7 * math.pi / 2))
            if y > top: continue
            frame = abs(a) > 5 or y > top - 2
            M.put(a, y, D + 1, P, LENG_L if frame else YELLOW_LIGHT, 0 if frame else 1)
            if not frame: M.put(a, y, D, P, YELLOW_LIGHT, 1)
    for x in range(-12, 13):                                                             # el umbral
        for z in range(D + 1, D + 10): M.put(x, 0, z, P, LENG_D)
    return M, {P: [0, 0, 0], 'door': [0, 0, D + 6], 'light': [0, 30, D + 8]}


def choza(seed, R, H):
    """Choza redonda de piedra seca (16/m) con el tejado cónico de lajas, una piel de cortina en la puerta y
    el brillo de un fuego dentro."""
    M = Model(S=1, seed=seed)
    for y in range(H + 1):
        for x in range(-R - 1, R + 2):
            for z in range(-R - 1, R + 2):
                d = math.sqrt(x * x + z * z)
                if d > R or d < R - 3: continue
                if z > 0 and abs(x) < 6 and y < 22: continue                                 # la puerta
                c = _leng(M, x, y, z)
                if (y // 4 + int(math.atan2(z, x) * 6)) % 5 == 0: c = LENG_D                   # piedra seca
                M.put(x, y, z, P, c)
    for y in range(0, 30):                                                               # tejado de lajas
        r = (R + 4) * (1 - y / 30.0)
        for x in range(-int(r) - 1, int(r) + 2):
            for z in range(-int(r) - 1, int(r) + 2):
                d = math.sqrt(x * x + z * z)
                if d > r or d < r - 2.5: continue
                M.put(x, H + y, z, P, LENG_D if (y + int(math.atan2(z, x) * 5)) % 3 == 0 else lerp(LENG, LENG_L, M.hsh(x, y, z)))
    for y in range(0, 22):                                                               # la cortina
        for a in range(-5, 6):
            if y < 4 and abs(a) < 3: continue
            M.put(a, y, R - 1, P, FUR if (a + y // 3) % 3 else FUR_D)
    for a in range(-2, 3): M.put(a, 1, R - 2, P, EMBER, 1)
    return M, {P: [0, 0, 0]}


def choza_1(): return choza(4141, 26, 30)
def choza_2(): return choza(4142, 22, 26)


def leon():
    """León alado de diorita de Sarkomand (16/m), echado sobre un pedestal: el cuerpo largo, las patas de
    delante estiradas, la cabeza alta con melena en bloques, las alas plegadas en el lomo y la cola enroscada."""
    M = Model(S=1, seed=4143)
    for x in range(-38, 39):                                                             # el pedestal, con zócalo
        for z in range(-22, 23):
            for y in range(0, 14):
                inset = 0 if y < 3 or y > 11 else 2
                if abs(x) > 38 - inset or abs(z) > 22 - inset: continue
                if abs(x) < 36 - inset and abs(z) < 20 - inset and y != 13: continue
                M.put(x, y, z, P, LENG)
    M.ell(-4, 26, 0, 24, 12, 11, P, DIORITE)                                               # el cuerpo
    M.ell(-22, 24, 0, 9, 11, 10, P, DIORITE)                                               # los cuartos traseros
    for z in (-7, 7):                                                                    # patas de delante
        M.capsule((12, 18, z), (30, 15, z), 4.5, 4.0, P, DIORITE)
        M.ell(31, 15, z, 5, 3, 4, P, DIORITE)
    M.ell(18, 40, 0, 10, 11, 10, P, DIORITE)                                               # la melena
    M.ell(25, 38, 0, 7, 7, 6, P, DIORITE)                                                  # la cara
    for z in (-1, 1):                                                                    # las alas, plegadas
        for k in range(26):
            for h in range(0, 18 - k // 3):
                M.put(-14 + k, 32 + h + k // 4, z * (10 + h // 5), P, DIORITE)
    M.capsule((-30, 18, 0), (-36, 15, 8), 2.5, 2.0, P, DIORITE)                            # la cola
    M.capsule((-36, 15, 8), (-28, 14, 14), 2.0, 2.0, P, DIORITE)

    def col(x, y, z):
        if y < 14:
            c = _leng(M, x, y, z)
            return LENG_D if y in (3, 11) else (LENG_L if y == 13 else c)
        c = lerp(DIORITE_D, DIORITE, 0.4 + 0.6 * M.noise(x, y, z, 3.0))
        if y > 36 and x > 10 and (x + y) % 4 == 0: c = DIORITE_D                             # mechones de la melena
        if M.hsh(x, y, z) < 0.012: c = DIORITE_L
        if x > 30 and 38 <= y <= 40 and abs(z) in (3, 4): c = (0.04, 0.04, 0.05)            # los ojos, huecos
        return c
    recolor(M, col)
    return M, {P: [0, 0, 0]}


def needle(seed, H, R):
    """Aguja de roca gris violácea (16/m): un prisma partido y ladeado, con su canchal al pie."""
    M = Model(S=1, seed=seed)
    rng = M.rng
    lean = rng.uniform(-0.15, 0.15)
    for y in range(H + 1):
        k = y / H
        r = R * (1.0 - 0.75 * k) + 2 * M.noise(0, y, 0, 3.0)
        cx = lean * y
        sides = 5 + (seed % 2)
        for x in range(-int(r) - 3, int(r) + 4):
            for z in range(-int(r) - 3, int(r) + 4):
                a = math.atan2(z, x - cx)
                rr = r * math.cos(math.pi / sides) / max(0.3, math.cos((a % (math.tau / sides)) - math.pi / sides))
                d = math.hypot(x - cx, z)
                if d > rr or d < rr - 3: continue
                if y > H - 8 and M.noise(x, y, z, 2.0) > 0.55: continue                         # la cabeza rota
                c = _leng(M, x, y, z)
                if y % 10 == 0 or M.noise(x, y * 0.3, z, 2.0) > 0.74: c = LENG_D
                M.put(int(x), y, int(z), P, c)
    for k in range(34):                                                                  # canchal
        a = rng.uniform(0, math.tau); d = rng.uniform(R, R * 1.8)
        x, z = int(math.cos(a) * d), int(math.sin(a) * d)
        h = rng.randint(1, 3)
        for a in range(2):
            for b in range(2):
                for y in range(h): M.put(x + a, y, z + b, P, _leng(M, x, y, z))
    return M, {P: [0, 0, 0]}


def roca_1(): return needle(4144, 70, 16)
def roca_2(): return needle(4145, 46, 12)


def _barrera(i):
    import gen_barrera_roca as B
    B.R_HI, B.R_MID, B.R_LO = LENG_L, LENG, LENG_D
    B.SNOW, B.SNOW_SH = (0.30, 0.30, 0.31), (0.25, 0.25, 0.27)                            # en vez de nieve, liquen gris
    B.QUARTZ = (0.56, 0.50, 0.58); B.DAMP = (0.18, 0.17, 0.21)
    M = B.build(i)
    return M, {P: [0, 0, 0]}


def barrera_1(): return _barrera(1)
def barrera_2(): return _barrera(2)
def barrera_3(): return _barrera(3)


def pena(seed, n, R, H):
    """Peñas bajas de Leng (16/m) para cerrar el borde sin tapar: lajas partidas y apiladas, grises violáceas."""
    M = Model(S=1, seed=seed)
    rng = M.rng
    for k in range(n):
        cx, cz = rng.uniform(-R, R), rng.uniform(-R * 0.6, R * 0.6)
        rx, rz, ry = rng.uniform(6, 11), rng.uniform(5, 9), rng.uniform(H * 0.5, H)
        cy = rng.uniform(0, ry * 0.4)
        for x in range(int(cx - rx), int(cx + rx) + 1):
            for z in range(int(cz - rz), int(cz + rz) + 1):
                for y in range(0, int(cy + ry) + 1):
                    u, v, w = (x - cx) / rx, (y - cy) / ry, (z - cz) / rz
                    if abs(u) ** 2.6 + abs(v) ** 2.6 + abs(w) ** 2.6 > 1.0: continue
                    if M.noise(x, y, z, 4.0) > 0.78: continue
                    c = _leng(M, x, y, z)
                    if (y + int(cy)) % 7 == 0: c = LENG_D                                          # lajas
                    M.put(x, y, z, P, c)
    return M, {P: [0, 0, 0]}


def pena_1(): return pena(4146, 4, 16, 16)
def pena_2(): return pena(4147, 3, 12, 13)


# ---------------- el mundo de abajo de los gugs ----------------

ZIN = (0.25, 0.25, 0.23); ZIN_D = (0.13, 0.13, 0.12); ZIN_L = (0.37, 0.36, 0.33)
NITRE = (0.52, 0.52, 0.47)
BONE = (0.62, 0.58, 0.47); BONE_D = (0.42, 0.39, 0.30)
VOID = (0.015, 0.015, 0.02)
FUNGUS = (0.62, 0.50, 0.82); FUNGUS_D = (0.36, 0.28, 0.48)


def _zin(M, x, y, z, k=1.0):
    c = lerp(ZIN_D, ZIN, 0.45 + 0.5 * M.noise(x, y, z, 5.0) * k)
    if M.noise(x + 50, y, z, 9.0) > 0.73 and y < 60: c = lerp(c, NITRE, 0.55)                # salitre
    return c


def _hollow(M):
    NB = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in NB)]:
        del M.V[k]


def muro_zin(seed):
    """Tramo de muralla ciclópea (16/m): 8 m de ancho, 7-8 de alto y el frente hacia +Z, con el origen en el
    centro de la base del frente (como gen_barrera_roca). Hiladas de sillares de 1,5-2,2 m, cada uno con su
    tono y su retranqueo; juntas casi negras; salitre abajo; la coronación con sillares que faltan."""
    M = Model(S=1, seed=seed)
    rnd = M.rng
    W, DEP = 64, 40
    rows, y = [], 0
    while y < 128:
        h = rnd.randint(24, 34)
        rows.append((y, y + h))
        y += h
    blocks = []
    for i, (y0, y1) in enumerate(rows):
        x = -W - rnd.randint(0, 30)
        while x < W:
            w = rnd.randint(28, 58)
            missing = i == len(rows) - 1 and rnd.random() < 0.35
            blocks.append((x, x + w, y0, y1, rnd.randint(0, 4), rnd.uniform(-1, 1), missing))
            x += w
    for (x0, x1, y0, y1, dz, tone, missing) in blocks:
        if missing: continue
        for x in range(max(x0, -W), min(x1, W)):
            for y in range(y0, y1):
                edge = x in (x0, x1 - 1) or y in (y0, y1 - 1)
                for z in range(-DEP, -dz + 1):
                    if -DEP < z < -dz - 1 and not (y == y1 - 1) and x not in (-W, W - 1): continue
                    c = _zin(M, x, y, z)
                    c = lerp(c, ZIN_L if tone > 0 else ZIN_D, 0.25 * abs(tone))
                    if edge: c = lerp(c, VOID, 0.7) if (x in (x0, x1 - 1) or y == y0) else lerp(c, ZIN_L, 0.35)
                    M.put(x, y, z, P, c)
    _hollow(M)
    return M, {P: [0, 0, 0]}


def muro_zin_1(): return muro_zin(4150)
def muro_zin_2(): return muro_zin(4151)
def muro_zin_3(): return muro_zin(4152)


def torre_koth():
    """La torre de Koth (8/m): redonda, en tres cuerpos que se estrechan, de sillares enormes, con una puerta
    de arco a la medida de un gug (6 m) y la coronación rota. Dentro están los peldaños de un metro que
    suben al bosque encantado."""
    M = Model(S=0.5, seed=4153)
    rnd = M.rng
    tiers = ((46, 0, 56), (38, 56, 104), (30, 104, 150))
    for R, y0, y1 in tiers:
        segs = rnd.randint(14, 18)
        ph = rnd.uniform(0, 1)
        for y in range(y0, y1 + 1):
            if y == y1 and R == 30 and False: pass
            for x in range(-R - 1, R + 2):
                for z in range(-R - 1, R + 2):
                    d = math.hypot(x, z)
                    if d > R or (d < R - 2 and y != y1): continue
                    if y == y1 and d < R - 2 and R != 30: continue
                    a = (math.atan2(z, x) / math.tau + 0.5) * segs + ph + ((y - y0) // 12) * 0.5
                    c = _zin(M, x, y, z)
                    if (y - y0) % 12 == 0 or abs(a - round(a)) < 0.04: c = lerp(c, VOID, 0.7)         # juntas
                    if y == y1 and R == 30 and M.noise(x, 0, z, 3.0) > 0.6: continue                 # rota arriba
                    M.put(x, y, z, P, c)
    # la puerta, en arco, mirando a +Z
    for y in range(0, 52):
        for x in range(-14, 15):
            top = 36 + int(14 * math.sqrt(max(0.0, 1 - (x / 14.0) ** 2)))
            if y > top: continue
            for z in range(30, 48):
                if (x, y, z) in M.V: del M.V[(x, y, z)]
            zf = int(math.sqrt(max(0, 46 * 46 - x * x)))
            M.put(x, y, zf - 3, P, VOID)
    for y in range(0, 8):                                                               # peldaño de gug, delante
        for x in range(-16, 17):
            for z in range(46, 54):
                if y < 7 and abs(x) < 15 and z < 53: continue
                M.put(x, y, z, P, _zin(M, x, y, z) if y < 7 else ZIN_L)
    return M, {P: [0, 0, 0]}


def lapida(seed, H, W):
    """Lápida monolítica de Zin (16/m): una losa tosca e inclinada, de canto irregular, con una columna de
    signos tallados hondos y salitre."""
    M = Model(S=1, seed=seed)
    rnd = M.rng
    T = 10
    lean = rnd.uniform(0.08, 0.16) * rnd.choice((-1, 1))
    for y in range(H):
        k = y / H
        w = W * (1 - 0.25 * k) + 2 * M.noise(0, y, 0, 4.0)
        if y > H - 10: w *= math.sqrt(max(0.05, (H - y) / 10.0))
        off = int(lean * y)
        for x in range(-int(w), int(w) + 1):
            for z in range(-T // 2, T // 2 + 1):
                if abs(z) < T // 2 and abs(x) < int(w) - 1 and y not in (H - 1,): continue
                c = _zin(M, x, y, z)
                if z == T // 2 and abs(x) < 6 and 14 < y < H - 18 and (M.hsh(x // 3, y // 4, 0) < 0.4) and x % 3 != 0 and y % 4 != 0:
                    c = VOID                                                                  # signos
                M.put(x + off, y, z, P, c)
    for x in range(-W - 4, W + 5):                                                       # el pie, hundido
        for z in range(-T, T + 1):
            if M.hsh(x, 0, z) < 0.5: M.put(x, 0, z, P, ZIN_D)
    return M, {P: [0, 0, 0]}


def lapida_1(): return lapida(4154, 64, 16)
def lapida_2(): return lapida(4155, 48, 13)


def huesos():
    """Montón de huesos (16/m): un túmulo bajo de huesos sueltos con calaveras encima."""
    M = Model(S=1, seed=4156)
    rnd = M.rng
    for k in range(80):                                                                  # huesos sueltos
        a = rnd.uniform(0, math.tau); d = rnd.uniform(0, 18) * math.sqrt(rnd.random())
        x0, z0 = math.cos(a) * d, math.sin(a) * d
        b = rnd.uniform(0, math.tau); L = rnd.uniform(6, 16)
        x1, z1 = x0 + math.cos(b) * L, z0 + math.sin(b) * L
        y = rnd.uniform(1, 4 + (22 - d) * 0.3)
        M.capsule((x0, y, z0), (x1, y + rnd.uniform(-2, 2), z1), 1.2, 1.2, P, BONE)
        M.ell(x0, y, z0, 2, 2, 2, P, BONE); M.ell(x1, y, z1, 2, 2, 2, P, BONE)
    M.ell(0, 0, 0, 16, 7, 14, P, BONE_D)                                                    # el montón
    skulls = []
    for k in range(5):                                                                   # calaveras
        a = rnd.uniform(0, math.tau); d = rnd.uniform(2, 14)
        cx, cz = math.cos(a) * d, math.sin(a) * d
        cy = 7 * math.sqrt(max(0.0, 1 - (d / 16.0) ** 2)) + 2
        M.ell(cx, cy, cz, 3.2, 3.0, 3.6, P, BONE)
        skulls.append((cx, cy, cz))
    for cx, cy, cz in skulls:                                                            # órbitas y boca
        for dz in (-1.4, 1.4):
            k = (int(round(cx + 3)), int(round(cy + 0.5)), int(round(cz + dz)))
            M.put(*k, P, VOID)
        M.put(int(round(cx + 3)), int(round(cy - 1.5)), int(round(cz)), P, VOID)
    def col(x, y, z):
        c = M.V[(x, y, z)][1]
        if c == VOID: return c
        return lerp(BONE_D, BONE, 0.5 + 0.5 * M.noise(x, y, z, 3.0))
    for k in list(M.V): M.V[k][1] = col(*k)
    return M, {P: [0, 0, 0]}


def cripta():
    """La boca de la cripta (16/m): un brocal cuadrado de sillares con escalones que bajan a lo negro; de ahí
    suben los necrófagos de Pickman."""
    M = Model(S=1, seed=4157)
    O, I = 30, 22
    for x in range(-O, O + 1):
        for z in range(-O, O + 1):
            inner = abs(x) < I and abs(z) < I
            if not inner:
                for y in range(0, 10):
                    c = _zin(M, x, y, z)
                    if y == 9: c = ZIN_L if (x + z) % 9 else ZIN
                    if (x % 14 == 0 or z % 14 == 0) and y < 9: c = lerp(c, VOID, 0.6)
                    M.put(x, y, z, P, c)
            else:
                step = (z + I) // 5                                                        # escalones hacia -Z
                h = 8 - step * 2
                if h >= 0:
                    M.put(x, h, z, P, lerp(ZIN, VOID, min(1.0, step / 4.0)))
                else:
                    M.put(x, 0, z, P, VOID)
    for k in range(6):                                                                   # huesos en el brocal
        M.capsule((-O + 4 + k * 9, 10, O - 3), (-O + 9 + k * 9, 10, O - 6), 1.0, 1.0, P, BONE)
    return M, {P: [0, 0, 0]}


def hongos_zin():
    """Corro de hongos pálidos del mundo de abajo (16/m): sombreros violáceos que brillan, y pies blancos."""
    M = Model(S=1, seed=4158)
    rnd = M.rng
    for k in range(9):
        a = rnd.uniform(0, math.tau); d = rnd.uniform(0, 12)
        cx, cz = int(math.cos(a) * d), int(math.sin(a) * d)
        h = rnd.randint(4, 12); r = rnd.randint(2, 5)
        for y in range(h):
            for x in range(-1, 1):
                for z in range(-1, 1): M.put(cx + x, y, cz + z, P, (0.80, 0.78, 0.84))
        for x in range(-r, r + 1):
            for z in range(-r, r + 1):
                dd = math.hypot(x, z)
                if dd > r + 0.3: continue
                M.put(cx + x, h, cz + z, P, FUNGUS, 1 if dd < r - 0.8 else 0)
                if dd > r - 1.3: M.put(cx + x, h - 1, cz + z, P, FUNGUS_D)
    return M, {P: [0, 0, 0], 'light': [0, 10, 0]}


def bloque(seed, n):
    """Sillares caídos (16/m), bajos: uno o dos bloques partidos y medio enterrados, para el borde."""
    M = Model(S=1, seed=seed)
    rnd = M.rng
    for k in range(n):
        cx, cz = rnd.uniform(-10, 10), rnd.uniform(-6, 6)
        w, d, h = rnd.randint(10, 16), rnd.randint(8, 12), rnd.randint(9, 16)
        ang = rnd.uniform(-0.5, 0.5); ca, sa = math.cos(ang), math.sin(ang)
        tilt = rnd.uniform(-0.15, 0.15)
        for x in range(-w - 4, w + 5):
            for z in range(-w - 4, w + 5):
                u, v = x * ca - z * sa, x * sa + z * ca
                if abs(u) > w or abs(v) > d: continue
                top = h + int(tilt * u) - (3 if M.noise(x, 0, z, 3.0) > 0.7 else 0)
                for y in range(0, max(2, top)):
                    if y < top - 1 and abs(u) < w - 1 and abs(v) < d - 1: continue
                    c = _zin(M, x, y, z)
                    if abs(abs(u) - w) < 1 or abs(abs(v) - d) < 1: c = lerp(c, ZIN_D, 0.4)
                    M.put(int(cx + x), y, int(cz + z), P, c)
    return M, {P: [0, 0, 0]}


def bloque_1(): return bloque(4159, 2)
def bloque_2(): return bloque(4160, 1)


# ---------------- la cima de Kadath ----------------

ONYX = (0.10, 0.09, 0.13); ONYX_D = (0.05, 0.045, 0.07); ONYX_L = (0.20, 0.18, 0.25)
VEIN = (0.25, 0.20, 0.33)
GOLD_LIGHT = (1.0, 0.80, 0.42)
SNOWK = (0.80, 0.84, 0.92); SNOWK_SH = (0.66, 0.70, 0.82)
EMBERK = (1.0, 0.52, 0.20)


def _onyx(M, x, y, z):
    c = lerp(ONYX_D, ONYX, 0.5 + 0.5 * M.noise(x, y, z, 6.0))
    v = M.noise(x * 0.7 + y * 0.5, y * 0.3, z * 0.7, 5.0)                                   # vetas
    if abs(v - 0.5) < 0.012: c = VEIN
    elif M.hsh(x, y, z) < 0.012: c = ONYX_L
    return c


def _window(M, cx, y0, h, w, z, glow=True):
    for y in range(y0, y0 + h + w):
        for x in range(cx - w, cx + w + 1):
            top = y0 + h + int(w * math.sqrt(max(0.0, 1 - ((x - cx) / (w + 0.5)) ** 2)))
            if y > top: continue
            fr = abs(x - cx) == w or y == top
            M.put(x, y, z, P, ONYX_L if fr else (GOLD_LIGHT if glow else ONYX_D), 0 if fr or not glow else 1)


def muro_onice(seed):
    """Tramo de la muralla de ónice (16/m): 8 m de ancho, ~10 m de alto, el frente hacia +Z y el origen en el
    centro de la base del frente. Paño liso de ónice con vetas, pilastras salientes, un zócalo, una cornisa
    con nieve, almenas arriba y una o dos ventanas altas y estrechas que brillan."""
    M = Model(S=1, seed=seed)
    rnd = M.rng
    W, DEP = 64, 40
    H = rnd.randint(150, 166)
    for x in range(-W, W):
        pil = (x + 64) % 42 < 8                                                          # pilastras
        d0 = 4 if pil else 0
        for y in range(0, H):
            zb = d0 + (3 if y < 14 else 0) + (2 if H - 14 <= y < H - 8 else 0)          # zócalo y cornisa
            for z in range(-DEP, zb + 1):
                if -DEP < z < zb and x not in (-W, W - 1) and y != H - 1: continue
                c = _onyx(M, x, y, z)
                if y in (13, H - 9) and z == zb: c = ONYX_L
                M.put(x, y, z, P, c)
            if y == H - 9 or y == 13:                                                     # nieve en las repisas
                M.put(x, y + 1, zb, P, SNOWK if M.hsh(x, y, 0) > 0.3 else SNOWK_SH)
        if (x // 10) % 2 == 0:                                                           # almenas
            for y in range(H, H + 12):
                for z in range(-8, 1): M.put(x, y, z, P, _onyx(M, x, y, z))
            M.put(x, H + 12, -4, P, SNOWK)
        for z in range(-DEP, -8):                                                        # nieve en el adarve
            if M.hsh(x, z, 1) > 0.25: M.put(x, H, z, P, SNOWK_SH)
    for cx in rnd.sample((-40, 2, 45), rnd.randint(1, 2)):                               # entre las pilastras
        _window(M, cx, rnd.randint(70, 96), 26, 5, 1, glow=rnd.random() < 0.8)
    return M, {P: [0, 0, 0]}


def muro_onice_1(): return muro_onice(4170)
def muro_onice_2(): return muro_onice(4171)
def muro_onice_3(): return muro_onice(4172)


def puerta_kadath():
    """La gran puerta del castillo de Kadath (16/m): dos torres de ónice cuadradas con almenas y ventanas
    encendidas a los lados de un arco de 12 m de alto por el que sale luz dorada, y delante una escalinata
    de cinco peldaños anchos con nieve en los cantos. El frente hacia +Z, el origen en el pie del arco."""
    M = Model(S=1, seed=4173)
    TW, TH = 34, 230                                                                    # las torres
    for sx in (-1, 1):
        cx = sx * 84
        for x in range(cx - TW, cx + TW + 1):
            for z in range(-60, 8):
                for y in range(0, TH):
                    if abs(x - cx) < TW and z < 7 and y != TH - 1: continue                   # sin la cara de atrás
                    c = _onyx(M, x, y, z)
                    if y % 40 == 0: c = ONYX_L
                    M.put(x, y, z, P, c)
                if (x // 10) % 2 == 0 and (z > 0 or z < -52 or abs(x - cx) > TW - 6):
                    for y in range(TH, TH + 14): M.put(x, y, z, P, _onyx(M, x, y, z))
        for wy in (90, 150):
            _window(M, cx, wy, 24, 5, 8)
    for x in range(-50, 51):                                                            # el paño con el arco
        for y in range(0, 200):
            top = 150 + int(36 * math.sqrt(max(0.0, 1 - (x / 36.0) ** 2))) if abs(x) <= 36 else -1
            inside = abs(x) < 36 and y < top
            for z in range(-30, 1):
                if inside:
                    if z == -6: M.put(x, y, z, P, GOLD_LIGHT, 1)                                  # la luz de dentro
                    elif x in (-35, 35) or y == top - 1: M.put(x, y, z, P, ONYX_L)
                    continue
                if z < 0 and y != 199: continue
                M.put(x, y, z, P, _onyx(M, x, y, z))
    for k in range(5):                                                                  # la escalinata
        y = 4 * (5 - k)
        for x in range(-60 - k * 6, 61 + k * 6):
            for z in range(0, 12 + k * 12):
                for yy in range(max(0, y - 4), y):
                    if yy < y - 1 and z < 12 + k * 12 - 1 and abs(x) < 60 + k * 6 - 1: continue
                    M.put(x, yy, z, P, _onyx(M, x, yy, z))
                if z == 12 + k * 12 - 1 and M.hsh(x, k, 2) > 0.3: M.put(x, y, z - 1, P, SNOWK_SH)
    return M, {P: [0, 0, 0], 'light': [0, 60, 24]}


def pilar(seed, broken):
    """Pilar de ónice (16/m): fuste cuadrado con aristas, basa escalonada y capitel; el partido, con el fuste
    cortado en bisel y trozos caídos al lado. Nieve encima."""
    M = Model(S=1, seed=seed)
    rnd = M.rng
    H = 62 if not broken else 38
    for y in range(0, H + 12):
        if y < 6: r = 14
        elif y < 10: r = 12
        elif y >= H + 6: r = 13
        elif y >= H: r = 11
        else: r = 9
        for x in range(-r, r + 1):
            for z in range(-r, r + 1):
                if abs(x) < r and abs(z) < r and y not in (H + 11,): continue
                if broken and y > H - 6 + (x + z) * 0.3: continue
                M.put(x, y, z, P, _onyx(M, x, y, z) if not (y >= H and not broken) else lerp(_onyx(M, x, y, z), ONYX_L, 0.3))
    top = H + 12 if not broken else H
    for x in range(-12, 13):                                                            # nieve encima
        for z in range(-12, 13):
            for y in range(top + 6, -1, -1):
                if (x, y, z) in M.V:
                    if M.hsh(x, z, 3) > 0.15: M.put(x, y + 1, z, P, SNOWK)
                    break
    if broken:
        for k in range(4):
            a = rnd.uniform(0, math.tau); d = rnd.uniform(16, 26)
            cx, cz = int(math.cos(a) * d), int(math.sin(a) * d)
            s2 = rnd.randint(4, 8)
            for x in range(-s2, s2 + 1):
                for z in range(-s2, s2 + 1):
                    for y in range(0, s2 + 2):
                        if abs(x) + abs(z) + y > s2 * 1.6: continue
                        M.put(cx + x, y, cz + z, P, _onyx(M, x, y, z))
    return M, {P: [0, 0, 0]}


def pilar_1(): return pilar(4174, False)
def pilar_2(): return pilar(4175, True)


def brasero():
    """Brasero de ónice (16/m): un cuenco ancho sobre tres patas curvas, lleno de brasas que brillan."""
    M = Model(S=1, seed=4176)
    for k in range(3):
        a = k / 3 * math.tau
        M.capsule((math.cos(a) * 9, 0, math.sin(a) * 9), (math.cos(a) * 5, 16, math.sin(a) * 5), 1.6, 1.4, P, ONYX)
    for y in range(16, 26):
        r = 6 + (y - 16) * 0.8
        for x in range(-int(r) - 1, int(r) + 2):
            for z in range(-int(r) - 1, int(r) + 2):
                d = math.hypot(x, z)
                if d > r: continue
                if d < r - 1.5 and y > 17:
                    if y == 24: M.put(x, y, z, P, EMBERK if M.hsh(x, y, z) > 0.3 else (0.40, 0.12, 0.05), 1)
                    continue
                M.put(x, y, z, P, ONYX_L if y == 25 else _onyx(M, x, y, z))
    return M, {P: [0, 0, 0], 'light': [0, 30, 0]}


def escombro(seed, n):
    """Trozos de ónice caídos (16/m), bajos, con nieve encima: para cerrar el borde sin tapar."""
    M = Model(S=1, seed=seed)
    rnd = M.rng
    for k in range(n):
        cx, cz = rnd.uniform(-12, 12), rnd.uniform(-6, 6)
        w, d, h = rnd.randint(6, 12), rnd.randint(5, 9), rnd.randint(6, 12)
        ang = rnd.uniform(-0.6, 0.6); ca, sa = math.cos(ang), math.sin(ang)
        for x in range(-w - 4, w + 5):
            for z in range(-w - 4, w + 5):
                u, v = x * ca - z * sa, x * sa + z * ca
                if abs(u) > w or abs(v) > d: continue
                top = h - int(abs(u) * 0.3)
                for y in range(0, top):
                    M.put(int(cx + x), y, int(cz + z), P, _onyx(M, x, y, z))
                if M.hsh(x, z, 5) > 0.2: M.put(int(cx + x), top, int(cz + z), P, SNOWK if M.hsh(x, z, 6) > 0.4 else SNOWK_SH)
    return M, {P: [0, 0, 0]}


def escombro_1(): return escombro(4177, 3)
def escombro_2(): return escombro(4178, 2)


PIECES = {'roble_1': roble_1, 'roble_2': roble_2, 'roble_3': roble_3, 'hongos': hongos, 'hongos_2': hongos_2,
          'tocon': tocon, 'helecho': helecho, 'losa': losa, 'casa_1': casa_1, 'casa_2': casa_2,
          'galera': galera, 'torre_1': torre_1, 'torre_2': torre_2, 'almacen': almacen, 'puesto': puesto,
          'anforas': anforas, 'monasterio': monasterio, 'choza_1': choza_1, 'choza_2': choza_2, 'leon': leon,
          'roca_1': roca_1, 'roca_2': roca_2, 'barrera_1': barrera_1, 'barrera_2': barrera_2, 'barrera_3': barrera_3,
          'pena_1': pena_1, 'pena_2': pena_2, 'muro_zin_1': muro_zin_1, 'muro_zin_2': muro_zin_2,
          'muro_zin_3': muro_zin_3, 'torre_koth': torre_koth, 'lapida_1': lapida_1, 'lapida_2': lapida_2,
          'huesos': huesos, 'cripta': cripta, 'hongos_zin': hongos_zin, 'bloque_1': bloque_1, 'bloque_2': bloque_2,
          'muro_onice_1': muro_onice_1, 'muro_onice_2': muro_onice_2, 'muro_onice_3': muro_onice_3,
          'puerta_kadath': puerta_kadath, 'pilar_1': pilar_1, 'pilar_2': pilar_2, 'brasero': brasero,
          'escombro_1': escombro_1, 'escombro_2': escombro_2}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    here = os.path.join(os.path.dirname(__file__), '..')
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        n = M.export(os.path.join(here, 'models', 'sue_%s.json' % name), piv, jitter=0.008, pivots_in_voxels=True,
                     roughness=0.9, specular=0.25, no_bottom=True)
        print('sue_%s: %d voxels' % (name, n))
