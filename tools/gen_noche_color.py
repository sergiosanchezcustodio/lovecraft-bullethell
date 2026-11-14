"""Criaturas de la noche suelta «El color que cayó del cielo» (hito 21.13). Todo lo que el color toca se
vuelve gris y quebradizo, y por dentro le brilla ese color que no tiene nombre (rosa violáceo, lila y un
verde de cristal, a manchas: nunca uno solo).

  res_gris       vaca de los Gardner, gris de ceniza con manchas más oscuras, la piel agrietada y
                 desconchada; por las grietas y los ojos le brilla el color. Cuadrúpedo
                 (anim_cuadrupedo: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail)
  granjero_gris  granjero consumido (como Nahum Gardner al final): peto vaquero desvaído, camisa de
                 franela que era roja, sombrero de paja, botas; la piel gris y cuarteada, los ojos y
                 las grietas del color. Humano a bloques (cuerpo.py, anim_humano)
  color_pozo     el jefe: el color que sube del pozo. Una columna que se retuerce de bloques del color,
                 con un núcleo casi blanco y dos jirones (anim_fragmento: body, top, pod_l, pod_r)

Escribe models/<nombre>.json. Uso: python tools/gen_noche_color.py [res_gris|granjero_gris|color_pozo]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import cuerpo as cu
from cuerpo import slab, T, H
import materiales

COLORS = ((0.95, 0.42, 0.88), (0.70, 0.48, 1.0), (0.58, 1.0, 0.86))
ASH = (0.60, 0.60, 0.57); ASH_D = (0.36, 0.36, 0.35); ASH_L = (0.74, 0.73, 0.70)
CRACK = (0.10, 0.10, 0.11)


def the_color(M, x, y, z):
    k = M.noise(x, y, z, 3.0)
    return lerp(COLORS[0], COLORS[1], k) if M.hsh(x // 3, y // 3, z // 3) < 0.72 else COLORS[2]


def crack_and_glow(M, parts, crack=0.74, glow=0.86, skip=()):
    """Grietas oscuras por la superficie y, en las más hondas, el color que brilla."""
    for (x, y, z), v in M.V.items():
        if v[0] not in parts or v[1] in skip: continue
        n = M.noise(x + 31, y, z, 2.2)
        if n > glow and M.exposed((x, y, z)):
            v[1] = the_color(M, x, y, z); v[2] = 1
        elif n > crack:
            v[1] = lerp(v[1], CRACK, 0.7)
        elif M.hsh(x, y, z) < 0.04:
            v[1] = ASH_L                                                   # escamas que se desprenden


# ---------------- la res gris ----------------

def res_gris():
    """1,25 m a la cruz y 1,5 de largo, a 32/m: patas con pezuña, tronco ancho, ubre, cabeza con el
    hocico pálido, cuernos cortos, orejas de lado y el rabo con su borla."""
    HOOF = (0.16, 0.15, 0.15); MUZZLE = (0.66, 0.60, 0.60); HORN = (0.70, 0.68, 0.60)
    M = cu.new(2131)
    B = 'body'
    for part, x, z in (('leg_fl', -5, 12), ('leg_fr', 5, 12), ('leg_bl', -5, -12), ('leg_br', 5, -12)):
        slab(M, part, HOOF, 0, 3, x, z, 5, 5, 5, 5, ch=0)
        slab(M, part, ASH, 3, 16, x, z, 4, 5, 4, 5.5, ch=1)
    slab(M, B, ASH, 14, 31, 0, 0, 15, 16, 34, 34, ch=3)
    slab(M, B, (0.62, 0.55, 0.56), 11, 14, 0, -7, 6, 6, 6, 6, ch=1)          # ubre
    slab(M, 'tail', ASH, 19, 30, 0, -17.5, 2, 2, 2, 2, ch=0)
    slab(M, 'tail', ASH_D, 15, 19, 0, -17.5, 3, 3, 3, 3, ch=1)                 # la borla
    slab(M, H, ASH, 24, 35, 0, 18, 10, 9, 10, 9, ch=2)
    slab(M, H, MUZZLE, 22, 29, 0, 23.5, 8, 7, 4, 4, ch=1)                       # hocico
    for s in (-1, 1):
        slab(M, H, ASH_D, 31, 33, 6.5 * s, 16, 4, 4, 3, 3, ch=0)               # orejas de lado
        for i in range(4):                                                     # cuernos cortos, hacia fuera y arriba
            M.put(4 * s + i * s - (1 if s < 0 else 0), 35 + (i // 2), 17, H, HORN)
            M.put(4 * s + i * s - (1 if s < 0 else 0), 35 + (i // 2), 18, H, HORN)
    for (x, y, z), v in M.V.items():                                           # manchas más oscuras (como una holandesa gris)
        if v[1] == ASH and M.noise(x, y, z, 7.0) > 0.6: v[1] = ASH_D
    def face(x, y, c, glow=0):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z, H, c, glow)
    for x in (-3, -2, 1, 2): face(x, 25, CRACK)                                # ollares
    crack_and_glow(M, {B, H, 'leg_fl', 'leg_fr', 'leg_bl', 'leg_br'}, skip=(HOOF, MUZZLE, HORN))
    for s in (-1, 1):                                                          # los ojos, del color
        for y in (30, 31):
            for xx in ((4, 5) if s > 0 else (-6, -5)):
                for z in range(20, 23):
                    k = (xx, y, z)
                    if k in M.V and M.V[k][0] == H and M.exposed(k):
                        M.V[k][1] = COLORS[1] if y == 31 else COLORS[0]; M.V[k][2] = 1
    piv = {'body': [0, 14, 0], 'head': [0, 28, 15], 'tail': [0, 30, -17],
           'leg_fl': [-5, 15, 12], 'leg_fr': [5, 15, 12], 'leg_bl': [-5, 15, -12], 'leg_br': [5, 15, -12]}
    n = M.export('models/res_gris.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.92, specular=0.2)
    print('res_gris', n, 'voxels')


# ---------------- el granjero consumido ----------------

def granjero_gris():
    MATS = {}
    def mat(col, m):
        MATS[col] = m
        return col
    SKIN = (0.62, 0.61, 0.58); SKIN_SH = (0.50, 0.49, 0.47)
    DENIM = mat((0.36, 0.40, 0.46), 'lona'); DENIM_D = mat((0.28, 0.31, 0.36), 'lona')
    FLANNEL = mat((0.50, 0.40, 0.38), 'lana'); FLANNEL_D = (0.40, 0.33, 0.32)
    BOOT = mat((0.24, 0.22, 0.21), 'cuero'); SOLE = (0.12, 0.11, 0.11)
    STRAW = mat((0.62, 0.58, 0.46), 'lona'); STRAW_D = (0.48, 0.45, 0.36); BAND = (0.28, 0.26, 0.24)
    BRASS = (0.56, 0.52, 0.40)
    M = cu.new(2132)
    top = cu.boots(M, BOOT, SOLE, top=10)
    cu.legs(M, DENIM, bottom=top)
    cu.torso(M, FLANNEL, b=0, bottom=30)
    for (x, y, z), v in M.V.items():                                           # cuadros de la franela, desvaídos
        if v[1] == FLANNEL and ((x + 20) // 3 + (y // 3)) % 2 == 0: v[1] = FLANNEL_D
    for (x, y, z), v in M.V.items():                                           # el peto: delante, de la cintura al pecho
        if v[0] == T and y < 44 and v[1] in (FLANNEL, FLANNEL_D): v[1] = DENIM
    for y in range(44, 55):
        for x in range(-5, 5): cu.front(M, x, y, DENIM, dz=0)
    for y in range(44, 62):                                                    # tirantes
        for x in (-5, -4, 3, 4):
            cu.front(M, x, y, DENIM_D, dz=1 if y < 55 else 0)
            cu.back(M, x, y, DENIM_D)
    for x in (-5, 4): cu.front(M, x, 54, BRASS, dz=1)                          # hebillas
    cu.neck(M, SKIN)
    cu.arms(M, FLANNEL, SKIN, fore=SKIN)                                       # remangado
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, ASH_D, eye=CRACK, brow_style='caida')
    cu.mouth(M, CRACK, wide=True)
    for x in range(-6, 6):                                                     # barba de días, gris
        for y in range(62, 67):
            if (x * 5 + y * 3) % 4 == 0: cu.paint_face(M, x, y, ASH_D)
    cu.hair_back(M, SKIN, ASH_D, bottom=68)
    slab(M, H, STRAW, 79, 81, 0, -0.5, 26, 26, 24, 24, ch=3)                  # sombrero de paja: ala ancha
    slab(M, H, STRAW, 81, 87, 0, -0.5, 15, 13, 14, 12, ch=2)
    slab(M, H, BAND, 81, 83, 0, -0.5, 15.5, 15, 14.5, 14, ch=2)
    for (x, y, z), v in M.V.items():
        if v[1] == STRAW and M.hsh(x, y, z) < 0.25: v[1] = STRAW_D
        if v[1] == STRAW and M.noise(x, y, z, 3.0) > 0.8: v[1] = lerp(STRAW, ASH, 0.6)   # roto y gris
    crack_and_glow(M, {H, 'fore_l', 'fore_r', 'neck', T}, crack=0.76, glow=0.88,
                   skip=(FLANNEL, FLANNEL_D, DENIM, DENIM_D, BRASS, STRAW, STRAW_D, BAND, CRACK, ASH_D))
    def face(x, y, c, glow=0):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z, H, c, glow)
    for x in (-4, -3, 2, 3):                                                   # los ojos, del color
        face(x, 73, COLORS[0], 1); face(x, 74, COLORS[1], 1)
    cu.finish(M, 'granjero_gris', dict(MATS), flat=(CRACK, ASH_D, BRASS, BAND) + COLORS, hat=(STRAW, STRAW_D, BAND),
              roughness=0.9, specular=0.2)


# ---------------- el color que sube del pozo ----------------

def color_pozo():
    """1,6 m a escala 1 (el nivel lo agranda): una columna de bloques del color que se retuerce en dos
    espirales alrededor de un núcleo casi blanco, más ancha arriba, con bloques sueltos que flotan
    alrededor; abajo se deshilacha, como si aún saliera del pozo. Todo brilla."""
    M = Model(S=2, seed=2133)
    CORE = (0.92, 0.72, 0.9)
    DEEP = ((0.62, 0.14, 0.52), (0.38, 0.18, 0.72), (0.18, 0.62, 0.46))   # brilla: más oscuro, o se ve blanco
    def put(part, x, y, z, c):
        if c in COLORS: c = DEEP[COLORS.index(c)]
        elif c != CORE and max(c) > 0.5: c = tuple(q * 0.65 for q in c)
        M.put(x, y, z, part, c, 1)
    for y in range(0, 52):                                                     # el núcleo
        r = 2.5 + 3.5 * math.sin(min(1.0, y / 44.0) * math.pi * 0.85)
        for x in range(-7, 8):
            for z in range(-7, 8):
                if math.hypot(x, z) <= r * (0.55 if y < 8 else 1.0):
                    put('body', x, y, z, lerp(CORE, COLORS[1], 0.25 * M.noise(x, y, z, 4.0)))
    for arm in range(2):                                                       # las dos espirales
        for k in range(160):
            t = k / 160
            y = t * 58
            a = arm * math.pi + t * math.tau * 2.2
            rad = 5.0 + 9.0 * t
            cx, cz = math.cos(a) * rad, math.sin(a) * rad
            part = 'top' if y > 34 else 'body'
            w = 1.6 + 1.6 * t
            for dx in range(-2, 3):
                for dy in range(-1, 2):
                    for dz in range(-2, 3):
                        if dx * dx + dz * dz > w * w: continue
                        put(part, round(cx + dx), round(y + dy), round(cz + dz), the_color(M, int(cx + dx), int(y), int(cz + dz)))
    for i in range(70):                                                        # bloques sueltos que flotan
        a = M.rng.uniform(0, math.tau); y = M.rng.uniform(6, 62); r = M.rng.uniform(10, 20) * (0.5 + y / 70)
        x, z = int(math.cos(a) * r), int(math.sin(a) * r)
        s = M.rng.choice((1, 2, 2, 3))
        for dx in range(s):
            for dy in range(s):
                for dz in range(s):
                    put('top' if y > 34 else 'body', x + dx, int(y) + dy, z + dz, COLORS[M.rng.randrange(3)])
    for s, part in ((-1, 'pod_l'), (1, 'pod_r')):                              # dos jirones que se abren a los lados
        for k in range(40):
            t = k / 40
            x = s * (8 + t * 16); y = 30 + math.sin(t * 3.0) * 6 + t * 8; z = math.sin(t * 5.0) * 3
            w = 2.2 * (1 - t) + 0.8
            for dx in range(-2, 3):
                for dy in range(-2, 3):
                    for dz in range(-2, 3):
                        if dx * dx + dy * dy + dz * dz <= w * w:
                            put(part, round(x + dx), round(y + dy), round(z + dz), the_color(M, int(x), int(y + dy), int(z)))
    piv = {'body': [0, 0, 0], 'top': [0, 34, 0], 'pod_l': [-8, 32, 0], 'pod_r': [8, 32, 0]}
    n = M.export('models/color_pozo.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.6, specular=0.3)
    print('color_pozo', n, 'voxels')


MODELS = {'res_gris': res_gris, 'granjero_gris': granjero_gris, 'color_pozo': color_pozo}
if __name__ == '__main__':
    for name in (sys.argv[1:] or MODELS):
        MODELS[name]()
