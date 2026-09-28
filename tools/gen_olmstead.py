"""Robert Olmstead, el narrador de "La sombra sobre Innsmouth". Personaje jugable.

Joven viajero de los años 20: gorra de plato de tweed, chaqueta de tweed gris verdoso con
las solapas abiertas, chaleco oscuro, camisa blanca y corbata azul, pantalón pardo y
zapatos de cuero. Afeitado y con el pelo castaño. Un revólver en la cadera (único relieve).
Estilo 4 (tools/cuerpo.py).
Uso: python tools/gen_olmstead.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

JACKET = (0.40, 0.44, 0.36); JACKET_SH = (0.32, 0.36, 0.29)
VEST = (0.24, 0.24, 0.27)
SHIRT = (0.86, 0.85, 0.80)
TIE = (0.20, 0.30, 0.56)
TROUSER = (0.36, 0.30, 0.24)
SHOE = (0.36, 0.22, 0.13); SOLE = (0.14, 0.10, 0.08)
CAP = (0.44, 0.37, 0.29); CAP_SH = (0.34, 0.28, 0.22)
SKIN = (0.88, 0.70, 0.57); SKIN_SH = (0.79, 0.60, 0.49); LIP = (0.62, 0.38, 0.33); CHEEK = (0.87, 0.60, 0.50)
HAIR = (0.33, 0.22, 0.14); BROW = (0.27, 0.18, 0.12)
BUTTON = (0.20, 0.17, 0.14)
GUN = (0.16, 0.16, 0.18); GRIP = (0.40, 0.25, 0.14); HOLSTER = (0.30, 0.18, 0.10)
B = -2

M = cu.new(1927)
top = cu.shoes(M, SHOE, SOLE)
cu.legs(M, TROUSER, bottom=top)
cu.torso(M, JACKET, b=B, bottom=36)
# pechera: chaleco en V con camisa y corbata, entre las solapas abiertas
cu.opening(M, 45, 61, 3, 11, JACKET_SH)                                # sombra de las solapas
cu.opening(M, 45, 61, 1, 9, VEST)
cu.opening(M, 53, 61, 1, 5, SHIRT)
for y in range(47, 61): cu.front(M, -1, y, TIE); cu.front(M, 0, y, TIE)
for y in (47, 48): cu.front(M, -2, y, TIE); cu.front(M, 1, y, TIE)      # punta de la corbata
for y in (46, 50, 54): cu.front(M, -3, y, BUTTON); cu.front(M, 2, y, BUTTON)   # botones del chaleco
for y in (39, 42): cu.front(M, -2, y, BUTTON, dz=1); cu.front(M, 1, y, BUTTON, dz=1)   # botones de la chaqueta
for y in range(36, 45): cu.front(M, -1, y, JACKET_SH)                   # cierre
for x0 in (-9, 5):                                                     # bolsillos con solapa, pintados
    for x in range(x0, x0 + 5): cu.front(M, x, 42, JACKET_SH)
for x in range(-9, -5): cu.front(M, x, 55, JACKET_SH)                   # bolsillo del pecho
slab(M, T, SHIRT, 60, 63, 0, 0.5, 11, 10, 10, 9, ch=1)                   # cuello de la camisa
slab(M, T, TIE, 60, 62, -0.5, 5, 2, 2, 2, 2, ch=0)                       # nudo
cu.neck(M, SKIN)
# revólver en la cadera derecha: funda de cuero y culata asomando
slab(M, T, HOLSTER, 34, 42, 8.5, 7, 3, 3, 3, 3, ch=0)
slab(M, T, GUN, 42, 44, 8.5, 7, 2, 2, 2, 2, ch=0)
slab(M, T, GRIP, 44, 47, 8.5, 6.5, 2, 2, 3, 3, ch=0)

cu.arms(M, JACKET, SKIN, b=B, cuff=SHIRT, cuff_wide=False)
cu.head(M, SKIN, SKIN_SH)
# gorra de plato: copa algo más ancha que la cabeza, plato inclinado hacia delante y visera
slab(M, H, CAP, 77, 81, 0, 0, 16, 16, 16, 16, ch=2)
slab(M, H, CAP_SH, 81, 83, 0, 1, 15, 14, 16, 14, ch=2)
slab(M, H, CAP_SH, 77, 78, 0, 8.5, 12, 12, 3, 3, ch=1)                 # visera (asoma 2: más taparía los ojos)
cu.eyes(M, BROW, brow_style='recta')
cu.cheeks(M, CHEEK)
cu.mouth(M, LIP)
cu.hair_back(M, SKIN, HAIR, top=77)
cu.sideburns(M, HAIR, 72, 77)

cu.seams(M, (JACKET,))
cu.finish(M, 'olmstead', {JACKET: 'lana', JACKET_SH: 'lana', VEST: 'lana', TROUSER: 'lana',
                          SHOE: 'cuero', SOLE: 'cuero', HOLSTER: 'cuero', CAP: 'lana', CAP_SH: 'lana',
                          HAIR: 'pelo', SKIN: 'piel', SKIN_SH: 'piel', TIE: 'punto'},
          flat=(LIP, BROW, CHEEK, BUTTON, GUN), b=B)
