"""Madame Ludmila Varga, espiritista experta en artes oscuras, médium de Arkham.
Personaje jugable (D-26).

Médium de salón de los años 20, elegante: vestido largo de terciopelo negro, estola ciruela
con flecos grises sobre los hombros, collar de perlas, media melena negra y diadema negra
con una pluma violeta. Piel pálida. Nada de tópicos de adivina: es una médium de la alta
sociedad. Estilo 4, cuerpo de mujer (tools/cuerpo.py).
Uso: python tools/gen_varga.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

DRESS = (0.13, 0.10, 0.15); DRESS_SH = (0.09, 0.07, 0.11)
STOLE = (0.36, 0.15, 0.33); FRINGE = (0.62, 0.60, 0.64)
PEARL = (0.92, 0.90, 0.86)
HAIR = (0.09, 0.07, 0.08)
BAND = (0.10, 0.09, 0.11); FEATHER = (0.50, 0.28, 0.62); FEATHER_SH = (0.38, 0.20, 0.48); GEM = (0.40, 0.20, 0.52)
STOCKING = (0.14, 0.12, 0.15); SHOE = (0.07, 0.06, 0.07); SOLE = (0.03, 0.03, 0.03)
SKIN = (0.93, 0.80, 0.72); SKIN_SH = (0.84, 0.70, 0.63); LIP = (0.55, 0.14, 0.22); CHEEK = (0.90, 0.70, 0.66)
BROW = (0.12, 0.08, 0.08)
AX = cu.ARM_X_F

M = cu.new(1924)
top = cu.shoes_f(M, SHOE, SOLE)
cu.legs_f(M, STOCKING, bottom=top)
cu.torso_f(M, DRESS, bottom=36)
cu.skirt(M, DRESS, 4, 40, b=-3, flare=6, depth=12)                       # vestido hasta los tobillos
for x in (-8, -3, 2, 7):                                               # pliegues del terciopelo
    for y in range(4, 30): cu.front(M, x, y, DRESS_SH)
cu.opening(M, 56, 61, 3, 7, SKIN)                                       # escote
for x in range(-3, 3): cu.front(M, x, 58 if x in (-3, 2) else 57, PEARL, dz=1)   # collar de perlas
cu.front(M, -1, 56, PEARL, dz=1); cu.front(M, 0, 56, PEARL, dz=1)
cu.neck(M, SKIN)
# estola sobre los hombros y los brazos, abierta por delante, con flecos
slab(M, T, STOLE, 53, 61, 0, 0, 22, 21, 15.5, 14, ch=2)
cu.opening(M, 53, 61, 5, 9, SKIN)
cu.opening(M, 53, 56, 5, 5, DRESS)
for x in range(-11, 11, 2):
    for y in (51, 52):
        cu.front(M, x, y, FRINGE, dz=1); cu.back(M, x, y, FRINGE)

cu.arms(M, DRESS, SKIN, cuff=DRESS_SH, cuff_wide=False, ax=AX, slim=True)
for s, _, _, arm, _ in cu.sides():                                      # la estola cubre el hombro
    slab(M, arm, STOLE, 53, 61, AX * s, 0, 8, 8.5, 8.5, 9, ch=1)
    slab(M, arm, FRINGE, 52, 53, AX * s, 0, 8, 8, 8.5, 8.5, ch=1)
cu.head(M, SKIN, SKIN_SH, ears=False, fem=True)
cu.eyes(M, BROW, brow_style='caida', lashes=cu.EYE)
cu.cheeks(M, CHEEK, y=70)
cu.lips(M, LIP)
cu.bob(M, HAIR, bottom=67, top=83, fringe=78, side_z=3)
cu.long_hair(M, HAIR, bottom=46, width=16)                               # melena lisa larga, a media espalda
cu.hair_back(M, SKIN, HAIR, top=82, zmax=2)
slab(M, H, HAIR, 78, 81, 0, 0.5, 14.5, 14.5, 15, 15, ch=2)                # pelo por encima de la frente
# diadema con broche y pluma violeta al lado
slab(M, H, BAND, 79, 80, 0, 0.3, 17, 17, 17, 17, ch=3)
slab(M, H, GEM, 78, 81, 7.5, 4, 2, 2, 3, 3, ch=0)                        # broche al lado
for i, y in enumerate(range(80, 94)):                                    # pluma: sube algo inclinada hacia atrás
    z = 3.5 - (i // 4)
    w = 2 if i in (0, 13) else 3
    slab(M, H, FEATHER if i < 10 else FEATHER_SH, y, y + 1, 7.5, z, 2, 2, w, w, ch=0)

cu.seams(M, (DRESS,))
cu.finish(M, 'varga', {DRESS: 'lana', DRESS_SH: 'lana', STOLE: 'lana', HAIR: 'pelo',
                       SHOE: 'cuero', SOLE: 'cuero', SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(LIP, BROW, CHEEK, PEARL, FRINGE, GEM, FEATHER, FEATHER_SH, BAND, STOCKING), ax=AX)
