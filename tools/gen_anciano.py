"""El anciano de la tienda de antigüedades (D-31). Atiende la tienda del menú.

Viejo anticuario de Arkham: gorro de fumar de terciopelo con borla dorada, cerco de pelo blanco y una barba larga y blanca,
cejas pobladas, gafas redondas de montura dorada, camisa azul pálido con ligas negras en las
mangas, pajarita, chaleco granate con la leontina de oro del reloj y pantalón gris oscuro.
Algo encorvado (la cabeza adelantada). Estilo 4 (tools/cuerpo.py).
Uso: python tools/gen_anciano.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

SHIRT = (0.58, 0.66, 0.78); SHIRT_SH = (0.47, 0.54, 0.66)       # azul pálido: la barba blanca destaca
VEST = (0.46, 0.12, 0.14); VEST_SH = (0.34, 0.08, 0.10)
TROUSER = (0.26, 0.26, 0.28)
SHOE = (0.16, 0.10, 0.07); SOLE = (0.06, 0.05, 0.04)
GARTER = (0.10, 0.10, 0.11); BOW = (0.12, 0.14, 0.26)
GOLD = (0.88, 0.70, 0.30); BUTTON = (0.86, 0.72, 0.40)
HAIR = (0.90, 0.90, 0.88); BROW = (0.94, 0.94, 0.92)
SKIN = (0.78, 0.58, 0.48); SKIN_SH = (0.68, 0.48, 0.40)       # algo oscura: la calva, clara, salía gris
LIP = (0.62, 0.38, 0.36); CHEEK = (0.84, 0.54, 0.48)
B = -1

M = cu.new(1890)
top = cu.shoes(M, SHOE, SOLE)
cu.legs(M, TROUSER, bottom=top)
cu.torso(M, SHIRT, b=B)
# chaleco: de la cadera al pecho, abierto en V arriba, con botones y la leontina
slab(M, T, VEST, 38, 58, 0, 0.3, 23.2 + B, 22.2 + B, 13.6, 14.4, ch=1)
cu.opening(M, 50, 58, 1, 8, SHIRT)
for y in range(40, 50): cu.front(M, -1, y, VEST_SH)                        # cierre
for y in (41, 44, 47): cu.front(M, -2, y, BUTTON, dz=1)
for x in range(-8, -2): cu.front(M, x, 45, GOLD, dz=1)                     # cadena del reloj, recta
for x, y in ((-9, 45), (-9, 44), (-10, 45), (-10, 44)): cu.front(M, x, y, GOLD, dz=1)   # el reloj asomando
slab(M, T, SHIRT, 59, 63, 0, 0.5, 11, 10, 10, 9, ch=1)                     # cuello de la camisa
for x in (-2, -1, 0, 1):                                                  # pajarita
    for y in (60, 61): cu.front(M, x, y, BOW, dz=1)
cu.neck(M, SKIN)

cu.arms(M, SHIRT, SKIN, b=B, cuff=SHIRT_SH, cuff_wide=False)
for s, _, _, arm, _ in cu.sides():                                        # ligas en las mangas
    slab(M, arm, GARTER, 51, 53, (cu.ARM_X + B / 2) * s, 0, 8.8, 8.8, 9, 9, ch=1)

cu.head(M, SKIN, SKIN_SH)
cu.eyes(M, BROW, brow_style='poblada', y=73)
cu.cheeks(M, CHEEK)
# gafas redondas de montura dorada
for x0 in (-6, 1):
    for x in range(x0 + 1, x0 + 4): cu.paint_face(M, x, 72, GOLD); cu.paint_face(M, x, 76, GOLD)
    for y in (73, 74, 75): cu.paint_face(M, x0, y, GOLD); cu.paint_face(M, x0 + 4, y, GOLD)
for x in (-1, 0): cu.paint_face(M, x, 75, GOLD)
# barba larga y blanca, bigote
cu.beard(M, HAIR)
slab(M, H, HAIR, 56, 63, 0, 5, 7, 10.5, 5, 7, ch=2)                        # la barba cae sobre el pecho
cu.moustache(M, HAIR, xs=range(-4, 4), y=69, rows=2)
cu.mouth(M, LIP, y=67)
# calvo: cerco de pelo blanco a los lados y detrás, coronilla de piel
cu.hair_back(M, SKIN, HAIR, top=76)
for (x, y, z), v in M.V.items():
    if v[0] == H and v[1] == SKIN and 70 <= y < 77 and abs(x + 0.5) >= 6.5 and z <= 2:
        v[1] = HAIR

# gorro de fumar de terciopelo con borla dorada, muy de anticuario
CAP = (0.18, 0.12, 0.26); CAP_SH = (0.13, 0.08, 0.19)
slab(M, H, CAP_SH, 77, 79, 0, 0.3, 15, 15, 15.5, 15.5, ch=2)               # ribete
slab(M, H, CAP, 79, 84, 0, 0.3, 15, 14, 15.5, 14.5, ch=2)
for (x, y, z), v in M.V.items():                                          # bordado dorado del ribete
    if v[0] == H and v[1] == CAP_SH and (x + z) % 4 == 0: v[1] = GOLD
slab(M, H, GOLD, 84, 85, 0, 0.3, 2, 2, 2, 2, ch=0)                         # botón de la borla
slab(M, H, GOLD, 80, 84, 7.5, 0.3, 1, 1, 1, 1, ch=0)                       # borla que cae al lado

cu.seams(M, (VEST,))
cu.finish(M, 'anciano', {SHIRT: 'lona', SHIRT_SH: 'lona', VEST: 'lana', VEST_SH: 'lana', TROUSER: 'lana',
                         SHOE: 'cuero', SOLE: 'cuero', HAIR: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(LIP, BROW, CHEEK, GOLD, BUTTON, BOW, GARTER, CAP, CAP_SH), b=B)
