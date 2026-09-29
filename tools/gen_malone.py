"""Vera Malone, contrabandista de Red Hook ("El horror de Red Hook"). Personaje jugable (D-26).

Traje cruzado gris marengo a rayas diplomáticas con pantalón, camisa blanca, corbata
granate, clavel blanco en la solapa, fedora granate con cinta negra, media melena negra y
labios rojos. Zapatos bicolores. Estilo 4, cuerpo de mujer (tools/cuerpo.py).
Uso: python tools/gen_malone.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

SUIT = (0.24, 0.24, 0.27); SUIT_SH = (0.18, 0.18, 0.21); STRIPE = (0.33, 0.33, 0.36)
SHIRT = (0.90, 0.89, 0.85); TIE = (0.45, 0.10, 0.14)
FLOWER = (0.94, 0.93, 0.88)
HAT = (0.42, 0.10, 0.14); HAT_SH = (0.33, 0.08, 0.11); BAND = (0.08, 0.07, 0.08)
HAIR = (0.08, 0.07, 0.08)      # negro azabache: el platino, bajo la luz cálida, se confundía con la piel
SHOE = (0.90, 0.88, 0.84); SHOE_TIP = (0.12, 0.10, 0.09); SOLE = (0.05, 0.05, 0.05)
SKIN = (0.92, 0.76, 0.66); SKIN_SH = (0.82, 0.65, 0.56); LIP = (0.72, 0.10, 0.14); CHEEK = (0.90, 0.66, 0.58)
BROW = (0.10, 0.08, 0.08); BUTTON = (0.12, 0.12, 0.13)
AX = cu.ARM_X_F

M = cu.new(1927)
top = cu.shoes_f(M, SHOE, SOLE)
for (x, y, z), v in M.V.items():                                        # puntera negra
    if z >= 5: v[1] = SHOE_TIP
cu.legs_f(M, SUIT, bottom=top)
cu.torso_f(M, SUIT, bottom=36)
cu.skirt(M, SUIT, 32, 40, b=-3, flare=1, depth=12)                       # faldón de la chaqueta


def stripes():
    """Rayas diplomáticas: verticales en todas las caras de la tela del traje."""
    V = M.V
    for (x, y, z), v in V.items():
        if v[1] != SUIT: continue
        face_z = (x, y, z + 1) not in V or (x, y, z - 1) not in V
        if (x % 4 == 0) if face_z else (z % 4 == 0): v[1] = STRIPE


cu.arms(M, SUIT, SKIN, cuff=SHIRT, cuff_wide=False, ax=AX, slim=True)
stripes()
# solapas en V con la camisa y la corbata, y botonadura cruzada
cu.opening(M, 48, 61, 3, 9, SUIT_SH)
cu.opening(M, 50, 61, 1, 6, SHIRT)
for y in range(47, 61): cu.front(M, -1, y, TIE); cu.front(M, 0, y, TIE)
for y in range(32, 48): cu.front(M, 2, y, SUIT_SH)                       # cruce de la chaqueta
for y in (39, 45):
    for x in (-4, 5): cu.front(M, x, y, BUTTON, dz=1)
slab(M, T, SHIRT, 59, 63, 0, 0.5, 10, 9, 10, 9, ch=1)                    # cuello de la camisa
cu.opening(M, 59, 63, 2, 2, TIE)
cu.neck(M, SKIN)
for x, y in ((5, 56), (6, 56), (5, 57), (6, 57), (4, 57)): cu.front(M, x, y, FLOWER, dz=1)   # clavel

cu.head(M, SKIN, SKIN_SH, ears=False)
cu.eyes(M, BROW, brow_style='recta', lashes=cu.EYE)
cu.cheeks(M, CHEEK, y=70)
cu.mouth(M, LIP, wide=True)
cu.bob(M, HAIR, bottom=67, top=80, fringe=78, side_z=3)
cu.hair_back(M, SKIN, HAIR, top=80, zmax=2)
# fedora ladeada: ala de 2,5, cinta negra y copa con pellizco delantero
slab(M, H, HAT_SH, 78, 79, 0.5, 0.5, 20, 20, 19.5, 19.5, ch=3)
slab(M, H, BAND, 79, 81, 1, 0.3, 15, 15, 15, 15, ch=2)
slab(M, H, HAT, 81, 86, 1, 0.3, 15, 13, 15, 12, ch=2)
for x in range(-1, 3):
    z = M.front(x, 85)
    if z is not None: M.V.pop((x, 85, z), None)

cu.seams(M, (SUIT, STRIPE))
cu.finish(M, 'malone', {SUIT: 'lana', SUIT_SH: 'lana', STRIPE: 'lana', HAT: 'lana', HAT_SH: 'lana',
                        HAIR: 'pelo', SKIN: 'piel', SKIN_SH: 'piel', SHOE: 'cuero', SHOE_TIP: 'cuero'},
          flat=(LIP, BROW, CHEEK, BUTTON, FLOWER, TIE, BAND, SHIRT), ax=AX)
