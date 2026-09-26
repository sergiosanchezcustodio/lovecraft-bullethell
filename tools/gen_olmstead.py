"""Robert Olmstead, el narrador de "La sombra sobre Innsmouth". Personaje jugable.

Joven viajero de los años 20: gorra de plato de tweed, chaqueta de tweed gris verdoso con
las solapas abiertas, chaleco oscuro, camisa blanca y corbata azul, pantalón pardo y
zapatos de cuero. Afeitado y con el pelo castaño. Un revólver en la cadera (único relieve).
A bloques limpios, como Dyer (tools/humano.py).
Uso: python tools/gen_olmstead.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp, scale
import humano as hu

M = Model(S=2, seed=1927)
JACKET = (0.40, 0.44, 0.36); JACKET_SH = (0.34, 0.38, 0.31)
VEST = (0.24, 0.24, 0.27)
SHIRT = (0.86, 0.85, 0.80)
TIE = (0.20, 0.30, 0.56)
TROUSER = (0.33, 0.29, 0.25)
SHOE = (0.36, 0.22, 0.13); SOLE = (0.14, 0.10, 0.08)
CAP = (0.41, 0.35, 0.28); CAP_SH = (0.33, 0.28, 0.22)
SKIN = (0.88, 0.70, 0.57); SKIN_SH = (0.79, 0.60, 0.49)
HAIR = (0.33, 0.22, 0.14); BROW = (0.27, 0.18, 0.12); MOUTH = (0.62, 0.38, 0.33)
BUTTON = (0.20, 0.17, 0.14)
GUN = (0.16, 0.16, 0.18); GRIP = (0.36, 0.23, 0.14)
box = M.vbox
T, H = hu.T, hu.H

hu.legs(M, TROUSER, SHOE, SOLE)
hu.torso(M, JACKET)
# pechera: chaleco en V con camisa y corbata, entre las solapas
for y in range(31, 42):
    w = max(1, (y - 29) // 3)                         # la V se abre hacia arriba
    box(-w - 1, y, 4, w + 1, y + 1, 5, T, VEST)
    if y >= 38: box(-w, y, 4, w, y + 1, 5, T, SHIRT)
box(-1, 34, 4, 1, 42, 5, T, TIE)
box(-2, 40, 4, 2, 42, 5, T, SHIRT)                    # cuello de la camisa
box(-1, 41, 4, 1, 42, 5, T, TIE)
for y in (26, 29): box(-1, y, 4, 1, y + 1, 5, T, BUTTON)   # botones de la chaqueta
for y in range(22, 31): box(-1, y, 4, 0, y + 1, 5, T, JACKET_SH)   # cierre
for x0 in (-7, 3):                                    # bolsillos con solapa, pintados
    box(x0, 26, 4, x0 + 4, 27, 5, T, JACKET_SH)
box(-7, 36, 4, -4, 37, 5, T, JACKET_SH)               # bolsillo del pecho
# revólver en la cadera derecha: culata asomando de la funda
box(8, 25, -1, 10, 29, 2, T, GUN)
box(9, 28, -1, 10, 31, 1, T, GRIP)
hu.arms(M, JACKET, SHIRT, SKIN, cuff_h=1)
hu.head(M, SKIN)
# gorra de plato: copa algo más ancha que la cabeza y visera hacia delante
box(-6, 50, -6, 6, 54, 6, H, CAP)
M.bevel(H, -6, 6, -6, 6, 50, 54)
box(-5, 50, 6, 5, 51, 8, H, CAP_SH)                   # visera (corta: una más larga tapa los ojos desde la cámara)
box(-6, 53, -6, 6, 54, 6, H, CAP_SH)                  # plato de la copa
hu.face(M, BROW, SKIN_SH, MOUTH, eye_y=47)
hu.hair_back(M, SKIN, HAIR)
for y in (49, 50):                                    # patillas cortas
    for x in (-5, 4):
        if (x, y, 3) in M.V: M.V[(x, y, 3)][1] = HAIR


def paint(k, part, c):
    x, y, z = k
    h = M.hsh(x, y, z)
    if c == JACKET: return JACKET if h > -0.3 else JACKET_SH          # tweed: dos tonos salpicados
    if c == CAP: return CAP if h > -0.2 else CAP_SH
    return None
M.paint(paint)
hu.export(M, 'olmstead')
