"""Madame Ludmila Varga, espiritista experta en artes oscuras, médium de Arkham.
Personaje jugable (D-26).

Médium de salón de los años 20, elegante: vestido largo de terciopelo negro, estola ciruela
con flecos grises sobre los hombros, collar de perlas, media melena negra ondulada y
diadema negra con una pluma violeta. Piel pálida. A bloques limpios (tools/humano.py).
Nada de tópicos de "adivina": es una médium de la alta sociedad.
Uso: python tools/gen_varga.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1924)
DRESS = (0.11, 0.09, 0.13); DRESS_SH = (0.08, 0.06, 0.10)
STOLE = (0.32, 0.14, 0.30); FRINGE = (0.62, 0.60, 0.64)
PEARL = (0.90, 0.88, 0.84)
HAIR = (0.09, 0.07, 0.08)
BAND = (0.10, 0.09, 0.11); FEATHER = (0.46, 0.26, 0.58); GEM = (0.36, 0.18, 0.48)
STOCKING = (0.14, 0.12, 0.15); SHOE = (0.07, 0.06, 0.07); SOLE = (0.03, 0.03, 0.03)
SKIN = (0.93, 0.80, 0.72); SKIN_SH = (0.84, 0.70, 0.63); LIPS = (0.55, 0.16, 0.22)
BROW = (0.12, 0.08, 0.08)
box = M.vbox
T, H = hu.T, hu.H
W = 8

hu.legs_slim(M, STOCKING, SHOE, SOLE)
hu.torso(M, DRESS, half=W)
hu.skirt(M, DRESS, bottom=6, half=W, flare=3)        # vestido largo, hasta media pantorrilla
# estola sobre los hombros, con flecos
box(-W, 36, -5, W, 41, 5, T, STOLE)
M.bevel(T, -W, W, -5, 5, 36, 41)
for x in range(-W + 1, W - 1, 2):
    box(x, 35, 4, x + 1, 36, 5, T, FRINGE)
    box(x, 35, -5, x + 1, 36, -4, T, FRINGE)
box(-2, 36, 4, 2, 41, 5, T, SKIN)                     # escote
for x in (-2, -1, 0, 1): box(x, 37 if x in (-2, 1) else 36, 4, x + 1, (38 if x in (-2, 1) else 37), 5, T, PEARL)   # collar
hu.arms(M, DRESS, DRESS_SH, SKIN, half=W, cuff_h=1)
for s, p in ((-1, 'arm_l'), (1, 'arm_r')):            # la estola cubre el hombro
    x0, x1 = (-W - 5, -W) if s < 0 else (W, W + 5)
    box(x0, 36, -3, x1, 41, 3, p, STOLE)
hu.head(M, SKIN)
hu.face_f(M, BROW, SKIN_SH, LIPS)
hu.hair_bob(M, HAIR)
box(-6, 50, -6, 6, 53, 6, H, HAIR)                    # pelo por encima
M.bevel(H, -6, 6, -6, 6, 50, 53)
box(-6, 51, -6, 6, 52, 6, H, BAND)                    # diadema
box(-1, 51, 5, 1, 52, 6, H, GEM)                      # broche
box(2, 52, 2, 3, 58, 4, H, FEATHER)                   # pluma
box(3, 55, 2, 4, 59, 4, H, FEATHER)


def paint(k, part, c):
    x, y, z = k
    if c == DRESS and y < 24 and M.hsh(x, y, z) < -0.3: return DRESS_SH     # pliegues del terciopelo
    return None
M.paint(paint)
hu.export(M, 'varga', half=W)
