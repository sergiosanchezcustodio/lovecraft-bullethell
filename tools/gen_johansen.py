"""Gustaf Johansen, segundo oficial noruego del Emma ("La llamada de Cthulhu").
Personaje jugable.

Marinero corpulento (tronco más ancho que los demás): gorro de lana gris con vuelta, pelo y
barba rubios, cara curtida, chaquetón cruzado azul marino con dos filas de botones de latón,
jersey grueso crema de cuello vuelto, pantalón oscuro y botas negras. Estilo 4
(tools/cuerpo.py).
Uso: python tools/gen_johansen.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

COAT = (0.16, 0.20, 0.32); COAT_SH = (0.12, 0.15, 0.25)
SWEATER = (0.86, 0.81, 0.69)
BRASS = (0.86, 0.68, 0.32)
TROUSER = (0.22, 0.22, 0.24)
BOOT = (0.13, 0.12, 0.12); SOLE = (0.05, 0.05, 0.05)
CAP = (0.52, 0.53, 0.55); CAP_SH = (0.43, 0.44, 0.46)
SKIN = (0.93, 0.73, 0.63); SKIN_SH = (0.83, 0.62, 0.53); LIP = (0.60, 0.33, 0.29); CHEEK = (0.90, 0.56, 0.48)
# rubio tostado: un rubio claro se confunde con la piel bajo la luz cálida
BLOND = (0.72, 0.50, 0.20); BLOND_SH = (0.58, 0.39, 0.15)
B = 3

M = cu.new(1925)
top = cu.boots(M, BOOT, SOLE, top=9)
cu.legs(M, TROUSER, bottom=top)
cu.torso(M, COAT, b=B)
cu.skirt(M, COAT, 33, 40, b=B, flare=1)                                # chaquetón hasta la cadera
slab(M, T, COAT_SH, 33, 34, 0, 0, 28 + B, 28 + B, 14, 14, ch=1)          # bajo
# cruzado: triángulo del jersey entre las solapas y el borde de la solapa que cruza
cu.opening(M, 52, 61, 2, 12, COAT_SH)
cu.opening(M, 52, 61, 1, 10, SWEATER)
for y in range(33, 53): cu.front(M, 4, y, COAT_SH)
for y in (38, 44, 50):                                                 # dos filas de botones de latón
    for x in (-6, -5, 5, 6): cu.front(M, x, y, BRASS, dz=1)
for x0 in (-11, 7):                                                    # bolsillos de ojal, pintados
    for y in range(38, 45): cu.front(M, x0 + 2, y, COAT_SH)
# jersey: cuello vuelto grueso
slab(M, T, SWEATER, 59, 66, 0, 0, 14, 12, 13, 11, ch=2)
cu.neck(M, SKIN)

cu.arms(M, COAT, SKIN, b=B, cuff=SWEATER, cuff_wide=False)
cu.head(M, SKIN, SKIN_SH)
cu.beard(M, BLOND)
slab(M, H, BLOND, 66, 72, 0, 2, 14, 14, 8, 8, ch=2)                      # barba por los lados, hasta las patillas
# gorro de lana: copa que se estrecha y vuelta gruesa
slab(M, H, CAP, 79, 86, 0, 0, 16, 13, 16, 13, ch=2)
slab(M, H, CAP_SH, 76, 80, 0, 0.3, 16.5, 16.5, 16.5, 16.5, ch=2)
cu.eyes(M, BLOND_SH, brow_style='recta')
cu.cheeks(M, CHEEK)
cu.moustache(M, BLOND_SH, xs=range(-4, 4))
cu.mouth(M, LIP)
cu.hair_back(M, SKIN, BLOND, top=76)

cu.seams(M, (COAT,))
cu.finish(M, 'johansen', {COAT: 'lana', COAT_SH: 'lana', SWEATER: 'punto', TROUSER: 'lana', BOOT: 'cuero',
                          SOLE: 'cuero', CAP: 'punto', CAP_SH: 'punto', BLOND: 'pelo', BLOND_SH: 'pelo',
                          SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(LIP, BRASS, CHEEK), b=B,
          hat=(CAP, CAP_SH,))
