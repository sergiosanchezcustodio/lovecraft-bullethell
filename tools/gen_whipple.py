"""Dra. Marian Whipple, doctora, sobrina del Dr. Elihu Whipple ("La casa maldita").
Personaje jugable (D-26).

Bata blanca larga abierta sobre un vestido gris, estetoscopio al cuello, gafas redondas,
pelo castaño recogido en un moño, medias claras y zapatos negros. A bloques limpios
(tools/humano.py). Sin cruz roja (es un emblema protegido).
Uso: python tools/gen_whipple.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1919)
COAT = (0.87, 0.87, 0.83); COAT_SH = (0.76, 0.76, 0.73)
DRESS = (0.38, 0.40, 0.45)
STETH = (0.20, 0.20, 0.22); STETH_M = (0.70, 0.72, 0.74)
HAIR = (0.36, 0.21, 0.13)
STOCKING = (0.74, 0.62, 0.55); SHOE = (0.08, 0.07, 0.07); SOLE = (0.03, 0.03, 0.03)
SKIN = (0.90, 0.72, 0.60); SKIN_SH = (0.80, 0.62, 0.51); LIPS = (0.66, 0.38, 0.36)
BROW = (0.30, 0.18, 0.11); FRAME = (0.62, 0.55, 0.42)      # montura fina de metal claro
PEN = (0.20, 0.30, 0.55)
box = M.vbox
T, H = hu.T, hu.H
W = 8

hu.legs_slim(M, STOCKING, SHOE, SOLE)
hu.torso(M, COAT, half=W)
hu.skirt(M, COAT, bottom=11, half=W, flare=2, front_open=(3, DRESS))   # bata abierta sobre el vestido
box(-3, 24, 4, 3, 41, 5, T, DRESS)                    # pechera del vestido entre las solapas
for y in range(24, 42):                               # solapas de la bata, en sombra
    box(-4, y, 4, -3, y + 1, 5, T, COAT_SH)
    box(3, y, 4, 4, y + 1, 5, T, COAT_SH)
box(-7, 27, 4, -4, 28, 5, T, COAT_SH)                 # bolsillos
box(4, 27, 4, 7, 28, 5, T, COAT_SH)
box(5, 34, 4, 6, 37, 5, T, PEN)                       # pluma en el bolsillo del pecho
box(4, 34, 4, 7, 35, 5, T, COAT_SH)
# estetoscopio: tubo alrededor del cuello que baja por delante
for y in range(34, 41):
    box(-3, y, 4, -2, y + 1, 5, T, STETH)
    box(2, y, 4, 3, y + 1, 5, T, STETH)
box(-3, 33, 4, -1, 34, 5, T, STETH_M)                 # campana
box(-4, 41, -3, 4, 42, 4, T, STETH)
hu.arms(M, COAT, COAT_SH, SKIN, half=W, cuff_h=1)
hu.head(M, SKIN)
hu.face_f(M, BROW, SKIN_SH, LIPS)
# gafas: montura clara a los lados y en el puente, con los ojos oscuros en medio (una montura
# oscura, a un píxel por voxel, se leía como un antifaz)
for x in (-3, -1, 0, 2): hu.paint_face(M, x, 48, FRAME)
hu.hair_back(M, SKIN, HAIR)
box(-6, 49, -6, 6, 53, 5, H, HAIR)                    # pelo recogido por encima
M.bevel(H, -6, 6, -6, 5, 49, 53)
box(-5, 49, 4, 5, 51, 5, H, SKIN, over=True)          # frente despejada
box(-6, 49, 4, -4, 52, 5, H, HAIR)                    # raya y mechones a los lados
box(4, 49, 4, 6, 52, 5, H, HAIR)
hu.bun(M, HAIR, y=49)


def paint(k, part, c):
    x, y, z = k
    if c == COAT and M.hsh(x, y, z) < -0.55: return COAT_SH
    return None
M.paint(paint)
hu.export(M, 'whipple', half=W)
