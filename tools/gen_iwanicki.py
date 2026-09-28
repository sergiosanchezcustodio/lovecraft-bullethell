"""Padre Iwanicki, sacerdote de la iglesia de San Estanislao ("Los sueños en la casa de la
bruja"). Personaje jugable (D-26).

Sotana negra hasta los tobillos con una fila de botones, alzacuellos blanco, crucifijo de
plata al pecho (el que da en el relato), fajín morado, pelo gris corto con entradas y cejas
pobladas. Delgado. Estilo 4 (tools/cuerpo.py).
Uso: python tools/gen_iwanicki.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

CASSOCK = (0.12, 0.12, 0.13); CASSOCK_SH = (0.08, 0.08, 0.09)
COLLAR = (0.93, 0.93, 0.89)
SASH = (0.38, 0.17, 0.42); SASH_SH = (0.30, 0.13, 0.33)
SILVER = (0.82, 0.82, 0.86)
BUTTON = (0.26, 0.24, 0.26)
HAIR = (0.64, 0.63, 0.62); BROW = (0.46, 0.44, 0.42)
SHOE = (0.09, 0.08, 0.08); SOLE = (0.03, 0.03, 0.03); SOCK = (0.13, 0.13, 0.14)
SKIN = (0.88, 0.70, 0.60); SKIN_SH = (0.77, 0.59, 0.50); LIP = (0.56, 0.36, 0.32); CHEEK = (0.86, 0.60, 0.52)
B = -2

M = cu.new(1932)
top = cu.shoes(M, SHOE, SOLE)
cu.legs(M, SOCK, bottom=top)
cu.torso(M, CASSOCK, b=B)
cu.skirt(M, CASSOCK, 6, 40, b=B, flare=5)                               # sotana hasta los tobillos
for y in range(8, 61, 4): cu.front(M, -1, y, BUTTON, dz=1)                # fila de botones
cu.belt(M, SASH, y=45, b=B, h=3)                                        # fajín
slab(M, T, SASH, 33, 45, 7, 7, 3, 3.5, 1.5, 1.5, ch=0)                    # caída del fajín
slab(M, T, SASH_SH, 32, 33, 7, 7, 3.5, 3.5, 1.5, 1.5, ch=0)
# alzacuellos: cuello negro alto con la tira blanca delante
slab(M, T, CASSOCK, 59, 64, 0, 0, 12, 10, 11, 10, ch=1)
for x in (-1, 0):
    for y in (61, 62, 63): cu.front(M, x, y, COLLAR)
cu.neck(M, SKIN)
# crucifijo de plata colgado de un cordón
for i in range(7):
    cu.front(M, -5 + min(i, 3), 60 - i, SILVER)                       # cordón izquierdo
    cu.front(M, 4 - min(i, 3), 60 - i, SILVER)                        # cordón derecho
for y in range(46, 54): cu.front(M, -1, y, SILVER, dz=1); cu.front(M, 0, y, SILVER, dz=1)
for x in range(-3, 3): cu.front(M, x, 51, SILVER, dz=1)

cu.arms(M, CASSOCK, SKIN, b=B, cuff=CASSOCK_SH, cuff_wide=False)
cu.head(M, SKIN, SKIN_SH)
cu.eyes(M, BROW, brow_style='poblada')
cu.cheeks(M, CHEEK)
cu.mouth(M, LIP)
# pelo gris corto con entradas: casquete que no llega a la frente, sienes y nuca
slab(M, H, HAIR, 79, 82, 0, -1.5, 14, 12, 13, 10, ch=2)
cu.hair_back(M, SKIN, HAIR)
for (x, y, z), v in M.V.items():                                        # sienes: el lateral de la cabeza
    if v[0] == H and v[1] == SKIN and 72 <= y < 80 and abs(x + 0.5) >= 6.5 and z <= 2:
        v[1] = HAIR

cu.seams(M, (CASSOCK,))
cu.finish(M, 'iwanicki', {CASSOCK: 'lana', CASSOCK_SH: 'lana', SASH: 'punto', SASH_SH: 'punto', SOCK: 'lana',
                          SHOE: 'cuero', SOLE: 'cuero', HAIR: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(LIP, BROW, CHEEK, SILVER, BUTTON, COLLAR), b=B)
