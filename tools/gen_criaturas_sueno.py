"""Criaturas de la parte 4, *La búsqueda onírica de la desconocida Kadath* (hito 21.10).

Nivel 1, el bosque encantado:
  zoog          pequeño y furtivo, pardo, de pelo ralo y a mechones, con un manojo de tentáculos cortos
                y rosados en el hocico, orejas redondas, ojos grandes que brillan amarillos y una cola
                larga y pelada (anim_cuadrupedo: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail;
                mira hacia +Z). 0,5 m de largo a 32/m
  zoog_copas    el que vive en lo alto de los robles: el pelo verdoso de musgo, las garras largas y
                claras para trepar
  zoog_anciano  el anciano del consejo de los zoogs (jefe del nivel 1, escalado): el pelo gris, los
                tentáculos largos y blancos, una ristra de setas que brillan colgada al cuello

Nivel 2, el puerto de Dylath-Leen:
  mercader_leng       humano (anim_humano): túnica ciruela con ribete de oro, turbante con los cuernos que lo
                      atraviesan, sonrisa de oreja a oreja, pezuñas y rubíes
  remero_lunar        bestia lunar (anim_sapo): sapo enorme gris blancuzco, sin ojos, con la maraña de
                      tentáculos rosados en el hocico
  bestia_lunar_mayor  el amo de la galera (jefe del nivel 2, escalado): más pálido, puntas encendidas, cicatrices
  escotilla           la escotilla de la bodega de la galera (32/m): tablones, flejes, candado y luz verdosa

Escribe models/<nombre>.json. Uso: python tools/gen_criaturas_sueno.py [nombres…]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import cuerpo as cu
from cuerpo import slab, rslab, H, T

B = 'body'
LEGS = ('leg_fl', 'leg_fr', 'leg_bl', 'leg_br')


# ---------------- los zoogs ----------------

def _zoog(name, seed, fur, fur_d, tent, claw, eye, beard=None, pendant=False):
    M = cu.new(seed)
    # patas cortas, con garras
    for part, x, z in (('leg_fl', -3, 5), ('leg_fr', 3, 5), ('leg_bl', -3, -5), ('leg_br', 3, -5)):
        slab(M, part, fur_d, 1, 6, x, z, 3, 3, 3, 3, ch=0)
        for dx in (-1, 0, 1): M.put(x + dx, 0, z + 2, part, claw)
        slab(M, part, fur_d, 0, 1, x, z, 3, 3, 3, 3, ch=0)
    slab(M, B, fur, 5, 13, 0, 0, 9, 8, 15, 14, ch=2)                         # el cuerpo, encorvado
    slab(M, B, fur, 12, 14, 0, -1, 7, 5, 10, 8, ch=2)                        # la joroba
    slab(M, H, fur, 7, 15, 0, 10, 9, 8, 8, 7, ch=2)                          # la cabeza
    slab(M, H, fur_d, 7, 11, 0, 14, 5, 5, 3, 3, ch=1)                        # el hocico
    for s in (-1, 1):                                                       # orejas redondas
        for y in range(14, 18):
            for z in (9, 10):
                if y == 17 and z == 10: continue
                M.put(s * 3 + (0 if s > 0 else -1), y, z, H, fur_d)
                M.put(s * 4 + (0 if s > 0 else -1), y, z, H, fur if y < 17 else fur_d)
    for (x, y, z), v in M.V.items():                                        # pelo a mechones
        if v[1] == fur and M.noise(x, y, z, 2.5) > 0.62: v[1] = fur_d
    tips = ((-2, 9), (-1, 8), (0, 10), (1, 8), (2, 9), (-1, 10), (1, 10), (0, 7))
    for i, (x, y) in enumerate(tips):                                        # los tentáculos del hocico
        L = 3 + (i % 3) + (2 if beard else 0)
        for k in range(L):
            M.put(x + (0 if k < 2 else (1 if x > 0 else -1 if x < 0 else 0)), y - (k // 3), 16 + k, H,
                  tent if k < L - 1 else lerp(tent, (1, 1, 1), 0.3))
    for s in (-1, 1):                                                       # los ojos, grandes
        for y in (12, 13):
            for x in ((2, 3) if s > 0 else (-4, -3)):
                M.put(x, y, 14, H, eye, 1)
        M.put(3 if s > 0 else -4, 13, 14, H, (1.0, 1.0, 0.85), 1)           # el brillo
    for k in range(14):                                                     # la cola, larga y pelada
        z = -7 - k
        y = 9 + int(2.5 * math.sin(k / 13 * math.pi))
        M.put(0, y, z, 'tail', lerp(tent, fur_d, 0.5))
        if k < 5: M.put(-1, y, z, 'tail', lerp(tent, fur_d, 0.5))
    if beard:
        for x in range(-3, 4):
            for y in (6, 7):
                M.put(x, y, 15, H, beard)
    if pendant:                                                             # ristra de setas que brillan
        for x in range(-4, 5):
            y = 9 - (1 if abs(x) < 3 else 0)
            M.put(x, y, 11, H, (0.30, 0.22, 0.16))
            if x % 2 == 0: M.put(x, y - 1, 12, H, (0.40, 0.95, 0.80), 1)
    piv = {'body': [0, 6, 0], 'head': [0, 11, 7], 'tail': [0, 9, -7],
           'leg_fl': [-3, 6, 5], 'leg_fr': [3, 6, 5], 'leg_bl': [-3, 6, -5], 'leg_br': [3, 6, -5]}
    n = M.export('models/%s.json' % name, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.92, specular=0.2)
    print(name, n, 'voxels')


def zoog():
    _zoog('zoog', 2201, (0.44, 0.32, 0.22), (0.30, 0.21, 0.14), (0.86, 0.52, 0.56), (0.20, 0.16, 0.12),
          (1.0, 0.82, 0.24))


def zoog_copas():
    _zoog('zoog_copas', 2202, (0.32, 0.34, 0.23), (0.21, 0.23, 0.15), (0.80, 0.56, 0.54), (0.80, 0.76, 0.62),
          (0.70, 1.0, 0.40))


def zoog_anciano():
    _zoog('zoog_anciano', 2203, (0.56, 0.54, 0.50), (0.40, 0.38, 0.35), (0.92, 0.90, 0.86), (0.30, 0.26, 0.22),
          (1.0, 0.66, 0.20), beard=(0.86, 0.84, 0.80), pendant=True)


# ---------------- nivel 2, el puerto de Dylath-Leen ----------------

def mercader_leng():
    """Mercader de Leng (humano, anim_humano): túnica larga ciruela con ribete de oro y fajín rojo, turbante
    claro con los dos cuernos que lo atraviesan, piel cetrina, ojos amarillos rasgados y una sonrisa demasiado
    ancha, de oreja a oreja, con los dientes; pezuñas bajo la túnica y una ristra de rubíes al cuello."""
    MATS = {}
    def mat(col, m):
        MATS[col] = m
        return col
    SKIN = (0.52, 0.42, 0.32); SKIN_SH = (0.43, 0.34, 0.26)
    ROBE = mat((0.32, 0.16, 0.30), 'lana'); ROBE_D = mat((0.23, 0.11, 0.22), 'lana')
    TRIM = (0.80, 0.62, 0.26); SASH = mat((0.62, 0.18, 0.14), 'lana')
    TURBAN = mat((0.86, 0.80, 0.66), 'lona'); TURBAN_D = (0.70, 0.64, 0.50)
    HORN = (0.28, 0.24, 0.20); HORN_T = (0.64, 0.58, 0.48)
    HOOF = (0.12, 0.10, 0.09); RUBY = (0.90, 0.08, 0.16)
    TEETH = (0.92, 0.88, 0.72); MOUTH = (0.18, 0.05, 0.06); BEARD = (0.14, 0.11, 0.09)
    M = cu.new(2210)
    for s_, _, shin, _, _ in cu.sides():                                           # pezuñas hendidas
        slab(M, shin, HOOF, 0, 3, 5 * s_, 3, 7, 7, 10, 9, ch=1)
        for y in range(0, 3): M.put(5 * s_ - 1, y, 8, shin, (0.05, 0.04, 0.04))
    cu.legs(M, ROBE_D, bottom=3)
    cu.torso(M, ROBE, b=1, bottom=36)
    cu.skirt(M, ROBE, 4, top=42, b=1, flare=4, depth=13)
    for (x, y, z), v in M.V.items():                                               # el bajo, de oro; manchas
        if v[0] != T or v[1] != ROBE: continue
        if y <= 6: v[1] = TRIM
        elif M.hsh(x // 2, y // 3, z) < 0.10: v[1] = ROBE_D
    for y in range(6, 62): cu.front(M, -1 if y % 2 else 0, y, TRIM)                 # la abertura, de oro
    cu.belt(M, SASH, y=40, b=1, h=3)
    for y in range(32, 40): cu.front(M, 4, y, SASH, dz=1)                           # la punta del fajín, colgando
    cu.neck(M, SKIN)
    cu.arms(M, ROBE, SKIN, b=1, cuff=TRIM)
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, BEARD, eye=(0.95, 0.74, 0.12), white=(0.86, 0.78, 0.40), brow_style='recta')
    for x in range(-7, 7):                                                          # la sonrisa, de oreja a oreja
        cu.paint_face(M, x, 66, MOUTH)
        if abs(x + 0.5) < 6: cu.paint_face(M, x, 67, TEETH if x % 2 else (0.80, 0.76, 0.60))
    for x in (-8, -7, 6, 7): cu.paint_face(M, x, 68, MOUTH)                         # las comisuras, hacia arriba
    for x in (-1, 0):                                                               # perilla
        for y in range(61, 65): cu.front(M, x, y, BEARD, dz=1, part=H)
    slab(M, H, TURBAN, 77, 89, 0, 0.5, 18, 15, 18, 15, ch=2)                        # el turbante
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == TURBAN and (y + (x if z > 0 else -x) // 3) % 4 == 0: v[1] = TURBAN_D   # las vueltas
    for y in range(80, 85):
        for x in (-1, 0): cu.front(M, x, y, RUBY if y in (81, 82, 83) else TRIM, dz=1, part=H)
    for s in (-1, 1):                                                               # los cuernos lo atraviesan
        for k in range(12):
            x = s * (8 + min(k, 6) // 2 + (1 if k > 8 else 0))
            y = 82 + k
            c = lerp(HORN, HORN_T, k / 11)
            for dx in (0, -s):
                for dz in (0, 1):
                    if k < 9 or dx == 0: M.put(x + dx, y, dz - (k // 4), H, c)
    for x in range(-6, 6):                                                          # la ristra de rubíes
        y = 58 - (1 if abs(x + 0.5) < 4 else 0) - (1 if abs(x + 0.5) < 2 else 0)
        cu.front(M, x, y, RUBY if x % 2 else TRIM, dz=1)
    def face(x, y, c, glow=0):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z, H, c, glow)
    for x in (-4, 3): face(x, 73, (1.0, 0.82, 0.20), 1)                             # el brillo de los ojos
    cu.finish(M, 'mercader_leng', dict(MATS), flat=(TRIM, HORN, HORN_T, HOOF, RUBY, TEETH, MOUTH, BEARD), b=1,
              skirt=True)


def _bestia(name, seed, skin, skin_d, belly, tent, tip, claw, glow_tips=False, scars=None):
    """Bestia lunar (anim_sapo: body, head, leg_fl, leg_fr, leg_bl, leg_br; mira hacia +Z): un sapo enorme,
    gris blancuzco y resbaladizo, sin ojos, con el hocico hecho una maraña de tentáculos rosados cortos."""
    M = cu.new(seed)
    for part, s in (('leg_bl', -1), ('leg_br', 1)):                                # patas de atrás, dobladas
        slab(M, part, skin_d, 2, 14, 15 * s, -8, 10, 8, 18, 13, ch=3)
        slab(M, part, skin_d, 0, 3, 17 * s, 3, 8, 8, 10, 10, ch=1)
        for dx in (-3, 0, 3): M.put(17 * s + dx, 0, 8, part, claw)
    for part, s in (('leg_fl', -1), ('leg_fr', 1)):                                # brazos cortos y gruesos
        slab(M, part, skin_d, 1, 14, 11 * s, 13, 6, 5, 6, 5, ch=1)
        slab(M, part, skin_d, 0, 2, 12 * s, 16, 8, 8, 5, 5, ch=1)
        for dx in (-3, -1, 1, 3): M.put(12 * s + dx, 0, 19, part, claw)
    rslab(M, B, skin, 4, 22, 0, -2, 32, 42, r=10, rt=9, rb=4)                      # el cuerpo, bajo y largo
    rslab(M, B, skin, 16, 26, 0, -7, 22, 26, r=8, rt=7, rb=2)                      # el lomo, abultado atrás
    rslab(M, H, skin, 6, 20, 0, 23, 20, 15, r=6, rt=5, rb=4)                       # la cabeza, más baja y sin ojos
    rslab(M, H, skin_d, 5, 9, 0, 22, 18, 13, r=4, rt=1, rb=2)                      # la papada
    for (x, y, z), v in M.V.items():
        if v[1] != skin: continue
        if y < 11 and v[0] in (B, H): v[1] = belly
        elif M.noise(x, y, z, 5.0) > 0.70: v[1] = skin_d                         # pliegues
        elif M.hsh(x, y, z) < 0.04: v[1] = lerp(skin, (1, 1, 1), 0.35)            # brillos de baba
    if scars:
        for (x, y, z), v in M.V.items():
            if v[0] == B and y > 18 and (x + 2 * z) % 13 == 0 and M.hsh(x, 1, z) < 0.5: v[1] = scars
    front_z = 23 + 8
    rows = [(x, y) for y in range(9, 19) for x in range(-8, 8) if ((x + 0.5) / 8.0) ** 2 + ((y - 13.5) / 5.5) ** 2 <= 1.0]
    for x, y in rows:                                                               # la maraña del hocico
        if M.hsh(x, y, 5) < 0.4: continue
        L = 3 + int(M.hsh(x, y, 9) * 6) + (3 if glow_tips else 0)
        dx = 1 if x > 2 else (-1 if x < -3 else 0)
        for k in range(L):
            last = k == L - 1
            M.put(x + (dx if k > 2 else 0), y - (k // 3), front_z + k, H, tip if last else tent,
                  1 if (last and glow_tips) else 0)
    for x in range(-6, 6):                                                          # la boca, debajo
        z = M.front(x, 8)
        if z is not None: M.put(x, 8, z, H, (0.24, 0.10, 0.12))
    piv = {'body': [0, 4, 0], 'head': [0, 13, 17],
           'leg_fl': [-11, 13, 13], 'leg_fr': [11, 13, 13], 'leg_bl': [-15, 12, -8], 'leg_br': [15, 12, -8]}
    n = M.export('models/%s.json' % name, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.42, specular=0.55)
    print(name, n, 'voxels')


def remero_lunar():
    _bestia('remero_lunar', 2220, (0.66, 0.66, 0.68), (0.52, 0.52, 0.55), (0.78, 0.76, 0.76),
            (0.86, 0.50, 0.58), (0.98, 0.70, 0.74), (0.30, 0.28, 0.30))


def bestia_lunar_mayor():
    """El amo de la galera (jefe del nivel 2, escalado): más pálido y viejo, con los tentáculos largos
    y las puntas encendidas, y las cicatrices de los látigos de otros amos en el lomo."""
    _bestia('bestia_lunar_mayor', 2221, (0.76, 0.74, 0.78), (0.60, 0.58, 0.64), (0.86, 0.84, 0.86),
            (0.80, 0.40, 0.56), (1.0, 0.55, 0.75), (0.22, 0.20, 0.24), glow_tips=True, scars=(0.46, 0.34, 0.40))


def escotilla():
    """La escotilla de la bodega de la galera (32/m; se pone encima de la de la pieza): tablones negros con
    flejes de hierro, un candado y las rendijas que dejan ver la luz verdosa de dentro."""
    M = Model(S=2, seed=2230)
    WOOD = (0.12, 0.10, 0.09); WOOD_L = (0.17, 0.14, 0.12); IRON = (0.22, 0.22, 0.24); RIVET = (0.40, 0.38, 0.36)
    GLOW = (0.45, 1.0, 0.45)
    for x in range(-26, 26):
        for z in range(-26, 26):
            plank = (x + 26) // 9
            gap = (x + 26) % 9 == 0
            for y in range(0, 5):
                if gap and y == 4:
                    M.put(x, y, z, 'body', GLOW, 1)
                    continue
                M.put(x, y, z, 'body', WOOD_L if (plank % 2 and M.hsh(x // 3, y, z // 5) < 0.6) else WOOD)
    for zb in (-17, 15):                                                            # flejes
        for x in range(-27, 27):
            for z in (zb, zb + 1, zb + 2):
                M.put(x, 5, z, 'body', IRON)
                if x % 6 == 0 and z == zb + 1: M.put(x, 6, z, 'body', RIVET)
    for x in range(-3, 3):                                                          # el candado
        for y in range(5, 10):
            for z in range(24, 27): M.put(x, y, z, 'body', IRON if y > 6 else RIVET)
    n = M.export('models/escotilla.json', {'body': [0, 0, 0]}, jitter=0.0, pivots_in_voxels=True, roughness=0.85,
                 specular=0.25)
    print('escotilla', n, 'voxels')


ALL = {'zoog': zoog, 'zoog_copas': zoog_copas, 'zoog_anciano': zoog_anciano,
       'mercader_leng': mercader_leng, 'remero_lunar': remero_lunar, 'bestia_lunar_mayor': bestia_lunar_mayor,
       'escotilla': escotilla}

if __name__ == '__main__':
    for n in (sys.argv[1:] or ALL):
        ALL[n]()
