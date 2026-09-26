"""Henrietta Blake, escritora, hermana de Robert Blake ("El morador de las tinieblas").
Personaje jugable (D-26).

Sombrero cloché verde azulado (el de los años 20, hasta las cejas), media melena rubia
oscura, abrigo largo burdeos con cuello de chal, bufanda crema, pluma en el bolsillo,
medias y zapatos de pulsera. A bloques limpios (tools/humano.py).
Uso: python tools/gen_blake.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1935)
COAT = (0.44, 0.13, 0.17); COAT_SH = (0.35, 0.10, 0.13)
SCARF = (0.86, 0.80, 0.66); SCARF_SH = (0.76, 0.70, 0.57)
HAT = (0.13, 0.33, 0.36); HAT_SH = (0.10, 0.26, 0.29); HATBAND = (0.72, 0.62, 0.40)
HAIR = (0.62, 0.47, 0.27)
STOCKING = (0.62, 0.50, 0.44); SHOE = (0.30, 0.16, 0.10); SOLE = (0.10, 0.06, 0.04)
SKIN = (0.91, 0.74, 0.62); SKIN_SH = (0.81, 0.63, 0.53); LIPS = (0.62, 0.20, 0.22)
BROW = (0.42, 0.30, 0.17); BUTTON = (0.20, 0.08, 0.08); PEN = (0.80, 0.68, 0.40)
box = M.vbox
T, H = hu.T, hu.H
W = 8

hu.legs_slim(M, STOCKING, SHOE, SOLE)
hu.torso(M, COAT, half=W)
hu.skirt(M, COAT, bottom=13, half=W, flare=2)
for y in (18, 23, 28, 33): box(-1, y, 4, 0, y + 1, 5 + (1 if y < 24 else 0), T, BUTTON)   # botonadura
for y in range(13, 38): box(0, y, 4, 1, y + 1, 5 + (1 if y < 24 else 0), T, COAT_SH)      # cierre
box(-6, 36, -5, 6, 42, 5, T, SCARF)                   # bufanda y cuello de chal
M.bevel(T, -6, 6, -5, 5, 36, 42)
box(-6, 36, 4, -3, 37, 5, T, SCARF_SH)
box(2, 28, 4, 4, 36, 5, T, SCARF)                     # caída de la bufanda por delante
box(-6, 30, 4, -5, 34, 5, T, PEN)                     # pluma en el bolsillo
hu.arms(M, COAT, COAT_SH, SKIN, half=W, cuff_h=2)
hu.head(M, SKIN)
hu.face_f(M, BROW, SKIN_SH, LIPS, eye_y=47)
hu.hair_bob(M, HAIR, bottom=44, top=50)
# cloché: casquete que baja hasta las cejas, con cinta y un ala muy corta
box(-6, 49, -6, 6, 54, 6, H, HAT)
M.bevel(H, -6, 6, -6, 6, 49, 54)
box(-5, 54, -5, 5, 55, 5, H, HAT)
box(-6, 50, -6, 6, 51, 6, H, HATBAND)
M.bevel(H, -6, 6, -6, 6, 50, 51)
box(-6, 49, 5, 6, 50, 7, H, HAT_SH)                   # ala corta por delante
box(3, 51, 5, 5, 53, 6, H, HATBAND)                   # lazo


def paint(k, part, c):
    x, y, z = k
    if c == COAT and M.hsh(x, y, z) < -0.5: return COAT_SH
    return None
M.paint(paint)
hu.export(M, 'blake', half=W)
