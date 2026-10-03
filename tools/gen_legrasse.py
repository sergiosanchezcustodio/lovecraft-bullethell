"""Inspector John R. Legrasse, de la policía de Nueva Orleans ("La llamada de Cthulhu").
Personaje jugable.

Fedora gris marengo de ala ancha con cinta parda (la silueta que lo distingue), gabardina
corta gris piedra abierta sobre un traje azul marino, camisa blanca y corbata oscura, placa
dorada en el pecho, bigote poblado y zapatos negros. Estilo 4 (tools/cuerpo.py).
Uso: python tools/gen_legrasse.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

COAT = (0.63, 0.60, 0.53); COAT_SH = (0.52, 0.49, 0.43)
SUIT = (0.16, 0.19, 0.31); SUIT_SH = (0.12, 0.14, 0.24)
SHIRT = (0.87, 0.86, 0.82); TIE = (0.10, 0.10, 0.12)
BADGE = (0.92, 0.74, 0.30)
SHOE = (0.10, 0.09, 0.09); SOLE = (0.05, 0.05, 0.05)
HAT = (0.22, 0.22, 0.24); HAT_SH = (0.17, 0.17, 0.19); BAND = (0.38, 0.26, 0.16)
SKIN = (0.84, 0.64, 0.50); SKIN_SH = (0.74, 0.54, 0.42); LIP = (0.56, 0.34, 0.29)
HAIR = (0.20, 0.15, 0.12); MOUSTACHE = (0.24, 0.17, 0.12)
BUTTON = (0.20, 0.18, 0.14)
B = -1

M = cu.new(1908)
top = cu.shoes(M, SHOE, SOLE)
cu.legs(M, SUIT, bottom=top)
cu.torso(M, COAT, b=B)
cu.skirt(M, COAT, 26, 40, b=B, flare=3)                                # gabardina corta, hasta medio muslo
# abierta por delante: asoman el traje, la camisa y la corbata; solapas en sombra
cu.opening(M, 26, 61, 9, 13, COAT_SH)
cu.opening(M, 26, 61, 7, 11, SUIT)
cu.opening(M, 52, 61, 2, 6, SHIRT)
for y in range(46, 61): cu.front(M, -1, y, TIE); cu.front(M, 0, y, TIE)
for y in (46, 47): cu.front(M, -2, y, TIE); cu.front(M, 1, y, TIE)
for y in range(26, 45): cu.front(M, -1, y, SUIT_SH)                     # cierre de la americana
for y in (40, 44): cu.front(M, -2, y, BUTTON)
cu.belt(M, COAT_SH, y=45, b=B, h=2)                                    # cinturón de la gabardina
cu.opening(M, 45, 47, 7, 7, SUIT)                                       # (por delante, abierto)
for y in (32, 37): cu.front(M, -7, y, BUTTON, dz=1); cu.front(M, 6, y, BUTTON, dz=1)
# placa dorada en el pecho izquierdo (relieve de un voxel)
for x, y in ((4, 53), (5, 53), (6, 53), (4, 54), (5, 54), (6, 54), (5, 55), (5, 52)):
    cu.front(M, x, y, BADGE, dz=1)
slab(M, T, SHIRT, 60, 63, 0, 0.5, 11, 10, 10, 9, ch=1)                   # cuello de la camisa
slab(M, T, COAT, 58, 62, 0, -1.5, 21, 19, 12, 10, ch=1)                  # cuello de la gabardina, por detrás
cu.neck(M, SKIN)

cu.arms(M, COAT, SKIN, b=B, cuff=COAT_SH)                               # bocamangas de la gabardina
cu.head(M, SKIN, SKIN_SH)
# fedora: ala ancha plana (asoma 2,5: más taparía los ojos desde la cámara), copa con cinta
# y pellizco delantero
slab(M, H, HAT_SH, 78, 79, 0, 0.5, 21, 21, 19.5, 19.5, ch=3)
slab(M, H, BAND, 79, 81, 0, 0.3, 15, 15, 15, 15, ch=2)
slab(M, H, HAT, 81, 86, 0, 0.3, 15, 13, 15, 12, ch=2)
for x in range(-2, 2):
    for y in (85,):
        z = M.front(x, y)
        if z is not None: M.V.pop((x, y, z), None)
cu.eyes(M, HAIR, brow_style='poblada', y=72)
cu.moustache(M, MOUSTACHE, xs=range(-4, 4), y=69, rows=2)               # bigote poblado
for x in (-4, 3): cu.paint_face(M, x, 67, MOUSTACHE, dz=1)
cu.mouth(M, LIP, y=66)
cu.hair_back(M, SKIN, HAIR, top=78)
cu.sideburns(M, HAIR, 71, 78)

cu.seams(M, (COAT,))
cu.finish(M, 'legrasse', {COAT: 'lona', COAT_SH: 'lona', SUIT: 'lana', SUIT_SH: 'lana', SHOE: 'cuero',
                          SOLE: 'cuero', HAT: 'lana', HAT_SH: 'lana', BAND: 'punto', HAIR: 'pelo',
                          MOUSTACHE: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(LIP, BADGE, BUTTON, TIE), b=B,
          hat=(HAT_SH, BAND, HAT,))
