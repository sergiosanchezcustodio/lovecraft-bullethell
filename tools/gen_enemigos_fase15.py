"""Enemigos nuevos de la fase 15 (hito 15.3), uno por parte:
  expedicionario   parte 1: un hombre de la expedición de Lake, congelado y vuelto a levantar.
                   Parka de lona hecha jirones con escarcha, piel azulada, ojos vacíos que
                   apenas brillan y un brazo descarnado. Estilo de los humanos (tools/cuerpo.py).
  tamborilero      parte 3: cultista de los pantanos de Luisiana (el rito que interrumpe
                   Legrasse): torso desnudo pintado de hueso, calzón de lona, pies descalzos y un
                   tambor de piel colgado delante, con las baquetas en las manos.
  nadador          parte 2: Profundo joven y esbelto que salta del agua: cuerpo de torpedo,
                   aletas largas en brazos y espalda, plateado y azul con franjas que brillan.
                   Con el generador paramétrico de los Profundos (tools/gen_variantes.py).
Uso: python tools/gen_enemigos_fase15.py
"""
import sys, os, json
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H
from voxlib import lerp
import gen_variantes as gv

MATS = {}


def mat(col, m):
    MATS[col] = m
    return col


def expedicionario():
    MATS.clear()
    SKIN = (0.62, 0.68, 0.74); SKIN_SH = (0.50, 0.56, 0.64)            # piel helada, azulada
    PARKA = mat((0.46, 0.40, 0.30), 'lona'); PARKA_SH = mat((0.34, 0.29, 0.22), 'lona')
    FUR = mat((0.74, 0.70, 0.62), 'lana'); TRO = mat((0.24, 0.22, 0.20), 'lana')
    BOOT = mat((0.16, 0.12, 0.09), 'cuero'); SOLE = (0.07, 0.06, 0.05)
    FROST = (0.82, 0.88, 0.94); BONE = (0.80, 0.76, 0.66); FLESH = (0.42, 0.16, 0.16)
    HOLE = (0.10, 0.09, 0.09)
    M = cu.new(1515)
    top = cu.boots(M, BOOT, SOLE, top=16)
    cu.legs(M, TRO, bottom=top)
    cu.torso(M, PARKA, b=1, bottom=28)
    cu.skirt(M, PARKA, 4, top=34, b=1, flare=2, depth=13)
    for y in range(28, 62, 4):                                       # costuras de la parka
        for x in (-6, 5): cu.front(M, x, y, PARKA_SH)
    for (x0, y0, w, h) in ((-9, 40, 4, 5), (4, 33, 5, 4), (-3, 50, 3, 3)):   # jirones: agujeros oscuros
        for x in range(x0, x0 + w):
            for y in range(y0, y0 + h):
                if (x - x0 + y - y0) % 4 != 3: cu.front(M, x, y, HOLE)
    cu.neck(M, SKIN)
    cu.arms(M, PARKA, SKIN, b=1, cuff=FUR)
    for k, v in list(M.V.items()):                                    # brazo izquierdo descarnado bajo el codo
        if v[0] == 'fore_l' and k[1] < 30: v[1] = FLESH if (k[1] + k[2]) % 3 else BONE
    cu.head(M, SKIN, SKIN_SH)
    GLINT = (0.45, 0.75, 0.95)
    cu.eyes(M, (0.30, 0.32, 0.36), eye=GLINT, white=(0.10, 0.12, 0.16), brow_style='recta')
    for k, v in M.V.items():                                         # ojos vacíos con un brillo frío
        if v[0] == H and v[1] == GLINT: v[2] = 1
    cu.mouth(M, (0.30, 0.20, 0.22))
    for x in range(-12, 12):                                         # capucha caída sobre los hombros
        for z in range(-8, 8):
            if abs(x) > 8 or z < -4: M.put(x, 62, z, T, FUR, over=False)
    for k, v in list(M.V.items()):                                    # escarcha en hombros, gorro y pecho
        x, y, z = k
        if y > 54 and v[1] in (PARKA, PARKA_SH, FUR, SKIN_SH) and (x * 7 + y * 3 + z * 5) % 5 == 0: v[1] = FROST
    slab(M, H, FUR, 77, 82, 0, -0.5, 15, 13, 15, 13, ch=2)           # gorro de piel
    for x in range(-6, 6):                                           # barba helada
        for y in range(62, 67):
            if (x + y) % 2: cu.paint_face(M, x, y, FROST, dz=1)
    cu.finish(M, 'expedicionario', dict(MATS), flat=(FROST, BONE, FLESH, HOLE), b=1, hat=(FUR,))


def tamborilero():
    MATS.clear()
    SKIN = (0.46, 0.32, 0.24); SKIN_SH = (0.38, 0.26, 0.19)
    PAINT = (0.84, 0.80, 0.68); CLOTH = mat((0.40, 0.36, 0.26), 'lona'); CLOTH_SH = mat((0.30, 0.27, 0.19), 'lona')
    DRUM = mat((0.40, 0.24, 0.14), 'madera'); DRUM_SH = (0.28, 0.16, 0.09); HIDE = (0.80, 0.72, 0.54)
    CORD = (0.20, 0.16, 0.10); STICK = (0.55, 0.45, 0.30); IDOL = (0.16, 0.24, 0.20)
    M = cu.new(1520)
    for s_, _, shin, _, _ in cu.sides():                             # pies descalzos
        slab(M, shin, SKIN, 0, 3, 5 * s_, 2, 8, 8, 13, 12, ch=1)
    cu.legs(M, CLOTH, bottom=3)
    for k, v in list(M.V.items()):                                    # calzón remangado: piel bajo la rodilla
        if v[1] == CLOTH and k[1] < 13: v[1] = SKIN
    cu.torso(M, SKIN, b=0, bottom=30)
    for y in range(30, 36):                                          # cintura de tela
        for x in range(-11, 11): cu.front(M, x, y, CLOTH_SH)
    for y in range(42, 58, 4):                                       # costillas pintadas de hueso
        for x in range(-8, 8):
            if abs(x) > 1: cu.front(M, x, y, PAINT)
    cu.neck(M, SKIN)
    cu.arms(M, SKIN, SKIN, b=0)
    for k, v in list(M.V.items()):                                    # rayas pintadas en los brazos
        if v[0] in ('arm_l', 'arm_r', 'fore_l', 'fore_r') and k[1] % 6 == 0: v[1] = PAINT
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, (0.12, 0.08, 0.06), brow_style='poblada')
    cu.mouth(M, (0.32, 0.16, 0.14))
    for x in range(-7, 7):                                           # cara pintada: calavera
        for y in (69, 70, 64):
            if abs(x) > 1: cu.paint_face(M, x, y, PAINT)
    slab(M, H, (0.08, 0.06, 0.05), 76, 84, 0, -0.5, 16, 14, 16, 14, ch=2)   # pelo negro
    for y in range(44, 52):                                          # cuerda del tambor, cruzada
        cu.front(M, -10 + (y - 44), y, CORD, dz=1)
    for y in range(18, 36):                                          # el tambor: cilindro delante del vientre
        for x in range(-9, 9):
            for z in range(10, 20):
                dx, dz = x + 0.5, (z - 15) * 1.0
                if dx * dx / 81 + dz * dz / 25 <= 1:
                    edge = y in (18, 19, 34, 35)
                    c = HIDE if y >= 34 else (CORD if edge else (DRUM if (x + y) % 5 else DRUM_SH))
                    M.put(x, y, z, T, c)
    for y in range(20, 34, 3):                                       # tensores
        for x in (-8, -3, 2, 7): M.put(x, y, 20, T, CORD)
    M.put(-1, 47, 11, T, IDOL); M.put(0, 47, 11, T, IDOL); M.put(-1, 46, 11, T, IDOL)   # amuleto
    for part in ('fore_l', 'fore_r'):                                # baquetas, en la mano y hacia el tambor
        hand = [k for k, v in M.V.items() if v[0] == part]
        y0 = min(k[1] for k in hand) + 2
        x0 = round(sum(k[0] for k in hand) / len(hand))
        z0 = max(k[2] for k in hand if k[1] <= y0 + 1)
        s = -1 if x0 > 0 else 1                                      # hacia el centro del tambor
        for i in range(10):
            M.put(x0 + s * (i * 2 // 3), y0 - i // 2, z0 + i, part, STICK)
        M.put(x0 + s * 6, y0 - 5, z0 + 10, part, HIDE); M.put(x0 + s * 6, y0 - 6, z0 + 10, part, HIDE)
    cu.finish(M, 'tamborilero', dict(MATS), flat=(PAINT, HIDE, CORD, STICK, IDOL, DRUM_SH))


NADADOR = dict(gv.BASE, name='Nadador', seed=21, torso_r=(4.4, 4.8, 5.2), torso_y=13.0, hip=10.0, thigh_r=1.7, stance=3.0,
    arm_len=1.15, arm_r=1.2, head_y=20.0, head_z=5.6, head_r=(5.6, 3.6, 6.8), jaw_w=0.86, eye_r=2.1, eye_x=0.86, eye_z=0.2,
    look_side=0.8, pupil=(0.25, 0.42), mouth_w=0.8, mouth_droop=1.0, mouth_gap=3.0, teeth=0.5, crest='fin',
    crest_z=(-8, 9.5), crest_h=(1.8, 3.0), arm_spines=True, biolum=0.0,
    pal=dict(dorsal=(0.10, 0.20, 0.30), side=(0.42, 0.55, 0.62), belly=(0.78, 0.82, 0.80), spot=(0.06, 0.12, 0.20),
             claw=(0.30, 0.34, 0.38), eye=(0.90, 0.92, 0.70), pupil=(0.02, 0.02, 0.02), socket=(0.04, 0.06, 0.08),
             maw=(0.10, 0.02, 0.04), gum=(0.40, 0.14, 0.18), tooth=(0.88, 0.88, 0.82), gill=(0.62, 0.16, 0.22),
             fin=(0.16, 0.36, 0.48), fin_ray=(0.26, 0.46, 0.56), spine_b=(0.10, 0.20, 0.28), spine_t=(0.60, 0.85, 0.95),
             lum=(0.40, 0.95, 0.90), spot_p=0.05))


def nadador():
    m = gv.build(NADADOR)
    for v in m['voxels']:                                            # franjas que brillan a lo largo del flanco
        x, y, z, p = v[0], v[1], v[2], v[3]
        if p in ('torso', 'head') and abs(abs(x) - 9) <= 0 and y % 2 == 0 and v[7] == 0:
            v[4], v[5], v[6] = NADADOR['pal']['lum']; v[7] = 1
    json.dump(m, open('models/nadador.json', 'w'))
    print('nadador:', len(m['voxels']), 'voxels')


expedicionario()
tamborilero()
nadador()
