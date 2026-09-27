"""Vera Malone, contrabandista de Red Hook ("El horror de Red Hook"). Personaje jugable (D-26).

Traje cruzado gris marengo a rayas diplomáticas con pantalón, camisa blanca, corbata
granate, clavel blanco en la solapa, fedora granate con cinta negra ladeada, media melena
negra y labios rojos. Zapatos bicolores. A bloques limpios (tools/humano.py).
Uso: python tools/gen_malone.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1927)
SUIT = (0.24, 0.24, 0.27); SUIT_SH = (0.19, 0.19, 0.22); STRIPE = (0.42, 0.42, 0.45)
SHIRT = (0.90, 0.89, 0.85); TIE = (0.45, 0.10, 0.14)
FLOWER = (0.94, 0.93, 0.88)
HAT = (0.42, 0.10, 0.14); HAT_SH = (0.34, 0.08, 0.11); BAND = (0.08, 0.07, 0.08)
HAIR = (0.08, 0.07, 0.08)      # negro azabache: el platino, bajo la luz cálida, se confundía con la piel
SHOE = (0.90, 0.88, 0.84); SHOE_TIP = (0.12, 0.10, 0.09); SOLE = (0.05, 0.05, 0.05)
SKIN = (0.92, 0.76, 0.66); SKIN_SH = (0.82, 0.65, 0.56); LIPS = (0.72, 0.10, 0.14)
BROW = (0.10, 0.08, 0.08); BUTTON = (0.12, 0.12, 0.13)
box = M.vbox
T, H = hu.T, hu.H
W = 8

hu.legs_slim(M, SUIT, SHOE, SOLE)
for s in (-1, 1):                                     # puntera negra de los zapatos bicolores
    x0, x1 = (-6, -1) if s < 0 else (1, 6)
    box(x0, 0, 2, x1, 2, 4, 'leg_l' if s < 0 else 'leg_r', SHOE_TIP)
hu.torso(M, SUIT, half=W)
hu.skirt(M, SUIT, bottom=19, half=W, flare=1)         # faldón de la chaqueta
# pechera: camisa y corbata en la V de las solapas
for y in range(32, 42):
    w = max(1, (y - 30) // 3)
    box(-w, y, 4, w, y + 1, 5, T, SHIRT)
box(-1, 30, 4, 1, 41, 5, T, TIE)
for y in (24, 28): (box(-4, y, 4, -3, y + 1, 5, T, BUTTON), box(2, y, 4, 3, y + 1, 5, T, BUTTON))   # cruzada
box(4, 36, 4, 6, 38, 5, T, FLOWER)                    # clavel en la solapa


def stripes(k, part, c):
    x, y, z = k
    if c == SUIT and x % 3 == 0: return STRIPE        # rayas diplomáticas verticales
    return None
M.paint(stripes)
hu.arms(M, SUIT, SHIRT, SKIN, half=W, cuff_h=1)
M.paint(stripes)
hu.head(M, SKIN)
hu.face_f(M, BROW, SKIN_SH, LIPS, eye_y=47)
hu.hair_back(M, SKIN, HAIR)
hu.hair_bob(M, HAIR, bottom=44, top=50)
# fedora ladeada: ala de 2 voxels, copa con pellizco y cinta negra
box(-7, 50, -7, 7, 51, 7, H, HAT_SH)
for x, z in ((-7, -7), (-7, 6), (6, -7), (6, 6)): M.V.pop((x, 50, z), None)
box(-5, 51, -5, 5, 55, 5, H, HAT)
M.bevel(H, -5, 5, -5, 5, 51, 55)
box(-5, 51, -5, 5, 52, 5, H, BAND, over=True)
M.bevel(H, -5, 5, -5, 5, 51, 52)
for x in range(-2, 2): M.V.pop((x, 54, 4), None)
hu.export(M, 'malone', half=W)
