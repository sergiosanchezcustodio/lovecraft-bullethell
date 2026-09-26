"""Inspector John R. Legrasse, de la policía de Nueva Orleans ("La llamada de Cthulhu").
Personaje jugable.

Fedora gris marengo de ala ancha con cinta parda (la silueta que lo distingue), gabardina
corta gris piedra abierta sobre un traje azul marino, camisa blanca y corbata oscura, placa
dorada en el pecho, bigote poblado y zapatos negros. A bloques limpios (tools/humano.py).
Uso: python tools/gen_legrasse.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1908)
COAT = (0.63, 0.60, 0.53); COAT_SH = (0.53, 0.50, 0.44)
SUIT = (0.15, 0.18, 0.30); SUIT_SH = (0.12, 0.14, 0.24)
SHIRT = (0.87, 0.86, 0.82); TIE = (0.10, 0.10, 0.12)
BADGE = (0.92, 0.74, 0.30)
SHOE = (0.10, 0.09, 0.09); SOLE = (0.05, 0.05, 0.05)
HAT = (0.20, 0.20, 0.22); HAT_SH = (0.16, 0.16, 0.18); BAND = (0.36, 0.25, 0.16)
SKIN = (0.84, 0.64, 0.50); SKIN_SH = (0.75, 0.55, 0.43)
HAIR = (0.20, 0.15, 0.12); MOUSTACHE = (0.22, 0.16, 0.12); MOUTH = (0.52, 0.33, 0.28)
BUTTON = (0.18, 0.16, 0.12)
box = M.vbox
T, H = hu.T, hu.H

hu.legs(M, SUIT, SHOE, SOLE)
hu.torso(M, COAT, y0=19)                          # la gabardina baja más que una chaqueta
# gabardina abierta: por delante asoma el traje, la camisa y la corbata
box(-3, 19, 4, 3, 42, 5, T, SUIT)
box(-2, 34, 4, 2, 42, 5, T, SHIRT)
box(-1, 30, 4, 1, 42, 5, T, TIE)
box(-2, 41, 4, 2, 42, 5, T, SHIRT)
for y in range(19, 42):                           # solapas de la gabardina, en sombra
    box(-4, y, 4, -3, y + 1, 5, T, COAT_SH)
    box(3, y, 4, 4, y + 1, 5, T, COAT_SH)
box(-9, 29, -5, 9, 31, 5, T, COAT_SH)             # cinturón de la gabardina (de la tela)
box(-3, 29, 4, 3, 31, 5, T, SUIT)                 # (por delante, abierto)
for y in (24, 27): box(-5, y, 4, -4, y + 1, 5, T, BUTTON)
box(5, 34, 4, 7, 37, 5, T, BADGE)                 # placa dorada
box(6, 37, 4, 7, 38, 5, T, BADGE)
hu.arms(M, COAT, SHIRT, SKIN, cuff_h=1)
for s in (-1, 1):                                 # bocamangas de la gabardina
    x0, x1 = (-14, -9) if s < 0 else (9, 14)
    box(x0, 26, -3, x1, 28, 3, 'arm_l' if s < 0 else 'arm_r', COAT_SH, over=True)
hu.head(M, SKIN)
# fedora: copa con cinta y ala ancha plana (que sobresale por todos lados)
box(-7, 50, -7, 7, 51, 7, H, HAT_SH)              # ala (2 voxels: más ancha taparía los ojos desde la cámara)
for x, z in ((-7, -7), (-7, 6), (6, -7), (6, 6)): M.V.pop((x, 50, z), None)
box(-5, 51, -5, 5, 56, 5, H, HAT)                 # copa
M.bevel(H, -5, 5, -5, 5, 51, 56)
box(-5, 51, -5, 5, 53, 5, H, BAND, over=True)     # cinta
M.bevel(H, -5, 5, -5, 5, 51, 53)
for x in range(-2, 2): M.V.pop((x, 55, 4), None)  # pellizco delantero de la copa
hu.face(M, HAIR, SKIN_SH, MOUTH, eye_y=47)
for x in (-3, -2, -1, 0, 1, 2): hu.paint_face(M, x, 45, MOUSTACHE)   # bigote poblado
for x in (-3, 2): hu.paint_face(M, x, 44, MOUSTACHE)
hu.hair_back(M, SKIN, HAIR)


def paint(k, part, c):
    x, y, z = k
    h = M.hsh(x, y, z)
    if c == COAT and y < 26: return COAT if h > 0.0 else COAT_SH         # faldón algo más oscuro
    return None
M.paint(paint)
hu.export(M, 'legrasse')
