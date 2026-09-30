"""Dra. Marian Whipple, doctora, sobrina del Dr. Elihu Whipple ("La casa maldita").
Personaje jugable (D-26).

Bata blanca larga abierta sobre un vestido gris, estetoscopio al cuello, gafas de montura
clara, pelo castaño recogido en un moño, medias claras y zapatos negros. Sin cruz roja (es
un emblema protegido). Estilo 4, cuerpo de mujer (tools/cuerpo.py).
Uso: python tools/gen_whipple.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

COAT = (0.86, 0.86, 0.82); COAT_SH = (0.72, 0.72, 0.69)
DRESS = (0.38, 0.40, 0.45); DRESS_SH = (0.31, 0.33, 0.37)
STETH = (0.18, 0.18, 0.20); STETH_M = (0.72, 0.74, 0.76)
HAIR = (0.36, 0.21, 0.13)
STOCKING = (0.72, 0.60, 0.53); SHOE = (0.08, 0.07, 0.07); SOLE = (0.03, 0.03, 0.03)
SKIN = (0.90, 0.72, 0.60); SKIN_SH = (0.80, 0.62, 0.51); LIP = (0.66, 0.36, 0.36); CHEEK = (0.88, 0.62, 0.53)
BROW = (0.30, 0.18, 0.11); FRAME = (0.70, 0.62, 0.44)      # montura fina de metal claro
PEN = (0.20, 0.30, 0.55)
AX = cu.ARM_X_F

M = cu.new(1919)
top = cu.shoes_f(M, SHOE, SOLE)
cu.legs_f(M, STOCKING, bottom=top)
cu.torso_f(M, COAT, bottom=36)
cu.skirt(M, DRESS, 22, 40, b=-4, flare=1, depth=12)                      # falda del vestido
cu.skirt(M, COAT, 17, 40, b=-3, flare=2, depth=12.5)                     # bata hasta la rodilla
# abierta por delante: el vestido asoma entre las solapas, en sombra
cu.opening(M, 17, 61, 7, 8, COAT_SH)
cu.opening(M, 22, 61, 5, 6, DRESS)
cu.opening(M, 17, 22, 5, 5, STOCKING)                                   # bajo el vestido, las piernas
for y in range(24, 50, 5): cu.front(M, -1, y, DRESS_SH)                  # botones del vestido
cu.opening(M, 57, 61, 2, 4, SKIN)                                       # escote redondo
# bolsillos de la bata y pluma en el del pecho
for x0 in (-9, 5):
    for x in range(x0, x0 + 5): cu.front(M, x, 35, COAT_SH)
for x in range(4, 8): cu.front(M, x, 52, COAT_SH)
for y in (52, 53, 54): cu.front(M, 6, y, PEN, dz=1)
slab(M, T, COAT, 58, 62, 0, -1, 18, 16, 12, 10, ch=1)                    # cuello de la bata, por detrás
cu.neck(M, SKIN)
# estetoscopio: al cuello, con los dos tubos por delante y la campana
for y in range(51, 61):
    cu.front(M, -4, y, STETH, dz=1); cu.front(M, 3, y, STETH, dz=1)
for x in (-4, -3, 2, 3): cu.front(M, x, 61, STETH, dz=1)
for x, y in ((-4, 50), (-3, 50), (-4, 49), (-3, 49)): cu.front(M, x, y, STETH_M, dz=1)

cu.arms(M, COAT, SKIN, cuff=COAT_SH, cuff_wide=False, ax=AX, slim=True)
cu.head(M, SKIN, SKIN_SH, ears=False, fem=True)
cu.eyes(M, BROW, brow_style='recta', lashes=cu.EYE)
cu.cheeks(M, CHEEK, y=70)
cu.lips(M, LIP)
# gafas: montura clara a los lados y en el puente (oscura parecía un antifaz)
# gafas: montura clara y fina alrededor de cada ojo, pintada (oscura parecía un antifaz)
for x0 in (-6, 1):
    for x in range(x0, x0 + 5): cu.paint_face(M, x, 72, FRAME)
    for y in (73, 74, 75): cu.paint_face(M, x0, y, FRAME); cu.paint_face(M, x0 + 4, y, FRAME)
for x in (-1, 0): cu.paint_face(M, x, 75, FRAME)                         # puente
# pelo castaño recogido: raya en medio, tapa las orejas, y moño alto en la nuca
cu.hair_back(M, SKIN, HAIR, top=82, zmax=2)
slab(M, H, HAIR, 78, 81, 0, 0.5, 14.5, 14, 15, 14.5, ch=2)
slab(M, H, HAIR, 81, 83, 0, 0.3, 13, 11, 13.5, 11.5, ch=2)
for (x, y, z), v in M.V.items():
    if v[0] == H and v[1] == SKIN and 72 <= y < 80 and abs(x + 0.5) >= 6.5 and z <= 4:
        v[1] = HAIR
for s_ in (-1, 1):                                                       # mechones sueltos junto a la cara
    slab(M, H, HAIR, 64, 77, 7 * s_ - 0.5, 2, 2, 2, 4, 3, ch=0)
cu.rslab(M, H, HAIR, 79, 89, 0, -6.5, 9, 8, r=3, rt=3, rb=2)  # moño alto, redondo
slab(M, H, HAIR, 79, 87, 0, -6.5, 8, 7, 7, 6, ch=2)                      # moño alto en la coronilla
slab(M, H, HAIR, 80, 86, 0, -9.5, 6, 5, 2, 2, ch=1)
slab(M, H, (0.26, 0.15, 0.09), 82, 83, 0, -6.5, 8.5, 8.5, 7.5, 7.5, ch=2)  # cinta del moño

cu.seams(M, (COAT,))
cu.finish(M, 'whipple', {COAT: 'lona', COAT_SH: 'lona', DRESS: 'lana', DRESS_SH: 'lana', SHOE: 'cuero',
                         SOLE: 'cuero', HAIR: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(LIP, BROW, CHEEK, FRAME, PEN, STETH, STETH_M, STOCKING), ax=AX)
