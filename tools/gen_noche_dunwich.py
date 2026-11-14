"""Criaturas de la noche suelta «El horror de Dunwich» (hito 21.14), en Sentinel Hill.

  chotacabras     el chotacabras de Dunwich: pájaro nocturno de plumaje de corteza (pardo grisáceo con
                  rayas oscuras y motas de ante), cabeza ancha y plana, pico diminuto con la boca enorme
                  y sus cerdas, el collar blanco bajo la garganta y las esquinas blancas de la cola; los
                  ojos, con el brillo rojo de los chotacabras. Con las alas abiertas, en vuelo
                  (anim_volador: body, head, wing_l, wing_r; mira hacia +Z)
  devota_colinas  devota de las colinas: una mujer de los montes de Dunwich, albina, con el pelo blanco
                  revuelto y los ojos rojos, chal oscuro cruzado sobre un vestido pardo remendado y
                  deshilachado, descalza, con un amuleto de piedra. Humana a bloques (cuerpo.py)
  hermano_wilbur  el jefe: el hermano gemelo de Wilbur, como lo vio Curtis Whateley. Un huevo enorme
                  hecho de cuerdas que se retuercen, gris con anillos azules y morados, lleno de ojos
                  saltones, con patas como toneles y trompas como tubos de estufa a los lados que se
                  abren y se cierran; arriba, media cara de hombre, de los Whateley, con el pelo blanco
                  (anim_fragmento: body, top, pod_l, pod_r)

Escribe models/<nombre>.json. Uso: python tools/gen_noche_dunwich.py [chotacabras|devota_colinas|hermano_wilbur]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import cuerpo as cu
from cuerpo import slab, T, H


# ---------------- el chotacabras ----------------

def chotacabras():
    """0,5 m de pico a cola y 1,2 de envergadura a 32/m (más grande que uno de verdad: se tiene que ver),
    con las alas abiertas y un poco hacia atrás."""
    M = Model(S=2, seed=2141)
    BARK = (0.36, 0.30, 0.24); BARK_D = (0.18, 0.14, 0.11); BUFF = (0.56, 0.47, 0.34)
    GREY = (0.44, 0.42, 0.38); COLLAR = (0.82, 0.78, 0.68); WHITE = (0.86, 0.85, 0.80)
    EYE = (1.0, 0.42, 0.16); BILL = (0.12, 0.10, 0.09)

    def plume(x, y, z):
        c = lerp(BARK, GREY, M.noise(x, y, z, 3.0))
        n = M.noise(x * 0.6, y + 20, z * 1.8, 1.6)
        if n > 0.68: c = BARK_D                                                     # rayas
        elif M.hsh(x, y, z) < 0.09: c = BUFF                                         # motas
        return c

    def ell(part, c, r, col):
        rx, ry, rz = r
        for x in range(-int(rx) - 1, int(rx) + 2):
            for y in range(-int(ry) - 1, int(ry) + 2):
                for z in range(-int(rz) - 1, int(rz) + 2):
                    if (x / rx) ** 2 + (y / ry) ** 2 + (z / rz) ** 2 > 1.0: continue
                    q = (c[0] + x, c[1] + y, c[2] + z)
                    M.put(*q, part, col(*q) if callable(col) else col)
    ell('body', (0, 8, 0), (4.6, 3.8, 8.0), plume)                                 # el cuerpo, alargado
    for z in range(-15, -6):                                                        # la cola, en abanico
        w = 2 + (-6 - z) * 0.45
        for x in range(-int(w), int(w) + 1):
            for y in (7, 8):
                c = plume(x, y, z)
                if z < -12 and abs(x) >= w - 1.5: c = WHITE                          # esquinas blancas
                M.put(x, y, z, 'body', c)
    ell('head', (0, 10, 10), (4.4, 3.4, 4.2), plume)                               # cabeza ancha y plana
    for x in range(-3, 4):                                                          # el collar blanco
        for z in (11, 12):
            M.put(x, 7, z, 'head', COLLAR)
        M.put(x, 8, 13, 'head', COLLAR)
    for x in range(-1, 1):                                                          # el pico, diminuto
        M.put(x, 10, 14, 'head', BILL); M.put(x, 9, 14, 'head', BILL)
    for x in range(-4, 4):                                                          # la boca enorme
        M.put(x, 9, 13, 'head', BILL if abs(x + 0.5) > 1 else (0.30, 0.14, 0.12))
    for s in (-1, 1):                                                               # cerdas
        for k in range(3): M.put(s * (4 + k), 10 - k % 2, 13, 'head', BILL)
    for s in (-1, 1):                                                               # los ojos, con su brillo rojo
        for y in (10, 11):
            for z in (11, 12):
                M.put(s * 4 + (0 if s > 0 else -1), y, z, 'head', EYE, 1)
    for s, part in ((-1, 'wing_l'), (1, 'wing_r')):                                 # las alas abiertas
        for i in range(0, 20):
            x = s * (4 + i)
            sweep = -i * 0.35
            chord = 7.5 - i * 0.28
            for z in range(int(sweep - chord * 0.55), int(sweep + chord * 0.45) + 1):
                for y in (8, 9) if i < 12 else (9,):
                    c = plume(x, y, z)
                    if (i // 3) % 2 == 0 and z < sweep - 1: c = BARK_D               # barras en las plumas
                    if 12 <= i <= 14 and z < sweep - 2: c = BUFF                     # la mancha del ala
                    M.put(x, y, z, part, c)
    piv = {'body': [0, 8, 0], 'head': [0, 10, 7], 'wing_l': [-4, 9, 0], 'wing_r': [4, 9, 0]}
    n = M.export('models/chotacabras.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.92, specular=0.2)
    print('chotacabras', n, 'voxels')


# ---------------- la devota de las colinas ----------------

def devota_colinas():
    MATS = {}
    def mat(col, m):
        MATS[col] = m
        return col
    SKIN = (0.90, 0.80, 0.78); SKIN_SH = (0.80, 0.69, 0.68)                      # albina
    DRESS = mat((0.40, 0.34, 0.28), 'lana'); DRESS_D = mat((0.30, 0.25, 0.21), 'lana')
    PATCH = mat((0.32, 0.33, 0.30), 'lana')
    SHAWL = mat((0.22, 0.20, 0.19), 'lana'); SHAWL_D = (0.15, 0.14, 0.13)
    HAIR = mat((0.88, 0.87, 0.82), 'pelo'); HAIR_SH = (0.72, 0.71, 0.67)
    EYE = (0.85, 0.12, 0.12); DIRT = (0.42, 0.34, 0.28)
    STONE = (0.32, 0.38, 0.34); CORD = (0.30, 0.24, 0.18)
    M = cu.new(2142)
    M.body['fem'] = True
    for s_, _, shin, _, _ in cu.sides():                                           # descalza, con barro
        slab(M, shin, DIRT, 0, 3, 4.5 * s_, 2, 7, 7, 12, 11, ch=1)
    cu.legs_f(M, SKIN)
    cu.torso_f(M, DRESS, bottom=36)
    cu.skirt(M, DRESS, 3, top=42, b=-3, flare=5, depth=12)
    for (x, y, z), v in M.V.items():
        if v[0] != T or v[1] != DRESS: continue
        if y <= 6 and M.hsh(x, y, z) < 0.35: v[1] = DRESS_D                        # el bajo, deshilachado
        if M.noise(x, y, z, 6.0) > 0.78: v[1] = PATCH                              # remiendos
        elif M.hsh(x // 2, y // 3, z) < 0.12: v[1] = DRESS_D
    gone = [k for k, v in M.V.items() if v[0] == T and k[1] <= 4 and M.hsh(k[0] // 2, 7, k[2] // 2) < 0.3]
    for k in gone: del M.V[k]                                                       # jirones en el bajo
    for y in range(44, 62):                                                         # el chal, cruzado
        for x in range(-9, 9):
            d = abs(x + 0.5) - (y - 44) * 0.42
            if d < -2.5 or d > 3.2: continue
            cu.front(M, x, y, SHAWL if (x + y) % 5 else SHAWL_D)
        for x in range(-9, 9): cu.back(M, x, y, SHAWL if y > 50 or (x + y) % 3 else SHAWL_D)
    for x in (-8, -7, 6, 7):                                                        # las puntas del chal, que cuelgan
        for y in range(36, 44): cu.front(M, x, y, SHAWL_D)
    cu.neck(M, SKIN)
    cu.arms(M, SHAWL, SKIN, ax=cu.ARM_X_F, slim=True, cuff=DRESS_D, cuff_wide=False)
    cu.head(M, SKIN, SKIN_SH, fem=True)
    cu.eyes(M, HAIR_SH, eye=EYE, white=(0.94, 0.88, 0.86), brow_style='caida')
    cu.mouth(M, (0.55, 0.36, 0.38), wide=False)
    cu.long_hair(M, HAIR, bottom=46, top=80, sh=HAIR_SH, width=16.0)
    slab(M, H, HAIR, 79, 85, 0, -1, 16, 13, 16, 13, ch=2, over=False)            # revuelto en la coronilla
    for (x, y, z), v in list(M.V.items()):                                          # mechones sueltos
        if v[1] == HAIR and M.hsh(x, y, z) < 0.04 and y > 60:
            for k in (1, 2): M.V.setdefault((x + (1 if x > 0 else -1) * k, y - k, z), [v[0], HAIR_SH, 0])
    for y in range(52, 58): cu.front(M, 0, y, CORD, dz=2)                           # el amuleto de piedra
    for x in range(-1, 2):
        for y in range(49, 52): cu.front(M, x, y, STONE, dz=2)
    def face(x, y, c, glow=0):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z, H, c, glow)
    for x in (-4, 3): face(x, 73, EYE, 1)                                           # el brillo de los ojos
    cu.finish(M, 'devota_colinas', dict(MATS), flat=(EYE, STONE, CORD, DIRT), ax=cu.ARM_X_F,
              roughness=0.9, specular=0.2, skirt=True)


# ---------------- el hermano de Wilbur ----------------

def hermano_wilbur():
    """2 m de alto a escala 1 (el nivel lo agranda): el huevo de cuerdas sobre ocho patas como toneles,
    con ojos saltones por todas partes, cinco trompas a cada lado y, arriba, media cara."""
    M = Model(S=2, seed=2143)
    ROPE = (0.42, 0.42, 0.45); ROPE_D = (0.30, 0.30, 0.34); ROPE_L = (0.52, 0.52, 0.55)
    RING_B = (0.28, 0.34, 0.52); RING_P = (0.40, 0.26, 0.48)
    SCLERA = (0.80, 0.76, 0.56); IRIS = (0.88, 0.74, 0.22); PUPIL = (0.04, 0.03, 0.03)
    MOUTH = (0.20, 0.06, 0.08); MOUTH_L = (0.44, 0.22, 0.28)
    SKIN = (0.74, 0.66, 0.58); SKIN_SH = (0.60, 0.52, 0.46); HAIR = (0.86, 0.85, 0.80)
    CY, RX, RY, RZ = 30, 24.0, 19.0, 30.0
    eggs = []

    def egg_r(z):                                                                  # más estrecho delante
        return 1.0 - 0.18 * max(z / RZ, 0.0)

    def rope_col(x, y, z):
        a = math.atan2(y - CY, x)
        rope = int((a + math.pi) / math.tau * 44)
        c = ROPE if rope % 2 else ROPE_D
        if M.noise(x, y, z, 4.0) > 0.7: c = ROPE_L
        ring = (z + 60) % 12
        if ring < 2: c = lerp(c, RING_B if ((z + 60) // 12) % 2 else RING_P, 0.75)
        return c
    for x in range(-int(RX) - 2, int(RX) + 3):                                       # el huevo de cuerdas, hueco
        for y in range(CY - int(RY) - 2, CY + int(RY) + 3):
            for z in range(-int(RZ) - 2, int(RZ) + 3):
                k = egg_r(z)
                a = math.atan2(y - CY, x)
                bulge = 0.04 * abs(math.sin(a * 22 + z * 0.15))                       # cada cuerda abulta
                d = (x / (RX * k)) ** 2 + ((y - CY) / (RY * k)) ** 2 + (z / RZ) ** 2
                if d > (1.0 + bulge) ** 2 or d < 0.8: continue
                M.put(x, y, z, 'body', rope_col(x, y, z))
                if d > 0.93: eggs.append((x, y, z))
    for i, (sx, sz) in enumerate(((-13, 18), (13, 18), (-17, 4), (17, 4), (-17, -10), (17, -10), (-12, -22), (12, -22))):
        top_y = CY - int(RY * 0.75)                                                  # patas como toneles
        for y in range(0, top_y + 2):
            for x in range(sx - 7, sx + 8):
                for z in range(sz - 7, sz + 8):
                    r = 6.0 + 0.8 * math.sin(y / max(top_y, 1) * math.pi)            # abombadas, como un tonel
                    d = math.hypot(x - sx, z - sz)
                    if d > r or (d < r - 2.5 and 1 < y < top_y): continue
                    c = rope_col(x, y, z)
                    if y in (3, top_y - 3): c = RING_P                                 # los aros del tonel
                    M.put(x, y, z, 'body', c)
    rng = M.rng
    placed = []
    for _ in range(400):                                                            # ojos saltones por todas partes
        if len(placed) >= 16: break
        p = eggs[rng.randrange(len(eggs))]
        if p[1] < CY - 6: continue
        if abs(p[0] - 1) < 13 and p[1] > CY + RY * 0.55 - 9 and p[2] > 2: continue      # ahí va la media cara
        if any((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2 < 120 for q in placed): continue
        placed.append(p)
        n = (p[0] / RX, (p[1] - CY) / RY, p[2] / RZ)
        L = math.sqrt(sum(c * c for c in n))
        n = tuple(c / L for c in n)
        r = rng.choice((2.2, 2.8, 3.4))
        cx, cy, cz = (p[i] + n[i] * 1.2 for i in range(3))
        ri = int(r) + 1
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    if x * x + y * y + z * z > r * r: continue
                    dot = (x * n[0] + y * n[1] + z * n[2]) / max(r, 0.01)
                    if dot < -0.2: continue
                    c, g = SCLERA, 0
                    if dot > 0.55: c, g = IRIS, 1
                    if dot > 0.82: c, g = PUPIL, 0
                    M.put(int(round(cx + x)), int(round(cy + y)), int(round(cz + z)), 'body', c, g)
    for s, part in ((-1, 'pod_l'), (1, 'pod_r')):                                  # cinco trompas a cada lado
        for i in range(5):
            z0 = 20 - i * 10
            y0 = CY + rng.uniform(-6, 7)
            x0 = s * (RX * egg_r(z0) * 0.9)
            L = rng.uniform(12, 18)
            up = rng.uniform(-0.2, 0.5)
            pts = []
            for k in range(int(L) + 1):
                t = k / L
                pts.append((x0 + s * k * 1.0, y0 + up * k + math.sin(t * 3.0 + i) * 2.5, z0 + math.sin(t * 2.0 + i * 1.7) * 3.0))
            for k, (px, py, pz) in enumerate(pts):
                t = k / L
                r = 3.6 + 0.9 * t                                                   # se abre hacia la boca
                for x in range(-5, 6):
                    for y in range(-5, 6):
                        for z in range(-5, 6):
                            d2 = y * y + z * z
                            if abs(x) > 1 or d2 > r * r: continue
                            q = (int(round(px + x)), int(round(py + y)), int(round(pz + z)))
                            end = k >= len(pts) - 2
                            if end and d2 < (r - 1.6) ** 2: c = MOUTH                    # la boca abierta
                            elif end: c = MOUTH_L
                            else: c = rope_col(*q)
                            M.put(*q, part, c)
    # arriba y delante, media cara de los Whateley que asoma del huevo: la mitad derecha es de hombre
    # (ojo, media nariz, media boca sin barbilla, el pelo blanco); la izquierda se deshace en cuerdas
    TOP = CY + int(RY * 0.55)
    FX, FZ = 1, 14
    for y in range(TOP - 6, TOP + 14):
        for x in range(-10, 11):
            for z in range(FZ - 12, FZ + 8):
                u, v, w = (x - FX) / 9.5, (y - TOP - 3) / 10.0, (z - FZ) / 7.5
                if u * u + v * v + w * w > 1.0: continue
                c = SKIN if M.hsh(x, y, z) > 0.12 else SKIN_SH
                if x < FX - 1:                                                       # se funde con las cuerdas
                    k = min(1.0, (FX - 1 - x) / 5.0)
                    c = lerp(c, rope_col(x, y, z), k)
                if y >= TOP + 9 and x >= FX - 1: c = HAIR if M.hsh(x, y, z) > 0.25 else (0.68, 0.67, 0.63)
                M.put(x, y, z, 'top', c)
    def face(x, y, c, glow=0):
        zs = [k[2] for k in M.V if k[0] == x and k[1] == y and M.V[k][0] == 'top']
        if zs: M.put(x, y, max(zs), 'top', c, glow)
    for x in range(3, 8): face(x, TOP + 7, (0.30, 0.28, 0.26))                      # la ceja, blanca y poblada
    for x in range(3, 7): face(x, TOP + 5, (0.94, 0.90, 0.80))                      # el ojo, muy abierto
    for x in (4, 5): face(x, TOP + 5, (0.12, 0.10, 0.08)); face(x, TOP + 4, (0.12, 0.10, 0.08))
    for y in range(TOP + 1, TOP + 5): face(1, y, SKIN_SH)                           # media nariz, larga
    face(2, TOP + 1, SKIN_SH)
    for x in range(-1, 7): face(x, TOP - 2, MOUTH)                                  # media boca, sin barbilla
    for x in range(0, 6): face(x, TOP - 3, (0.20, 0.08, 0.08))
    piv = {'body': [0, 0, 0], 'top': [FX, TOP, FZ - 4], 'pod_l': [-20, CY, 0], 'pod_r': [20, CY, 0]}
    n = M.export('models/hermano_wilbur.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.85, specular=0.25)
    print('hermano_wilbur', n, 'voxels')


MODELS = {'chotacabras': chotacabras, 'devota_colinas': devota_colinas, 'hermano_wilbur': hermano_wilbur}
if __name__ == '__main__':
    for name in (sys.argv[1:] or MODELS):
        MODELS[name]()
