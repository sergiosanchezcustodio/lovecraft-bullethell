"""Gustaf Johansen, segundo oficial noruego del Emma ("La llamada de Cthulhu").
Personaje jugable.

Marinero corpulento (torso más ancho que los demás): gorro de lana gris con vuelta, pelo y
barba rubios, cara curtida, chaquetón cruzado azul marino con dos filas de botones de latón,
jersey grueso crema de cuello vuelto, pantalón oscuro y botas negras. A bloques limpios
(tools/humano.py).
Uso: python tools/gen_johansen.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1925)
COAT = (0.15, 0.19, 0.30); COAT_SH = (0.12, 0.15, 0.24)
SWEATER = (0.86, 0.81, 0.69); SWEATER_SH = (0.76, 0.71, 0.60)
BRASS = (0.86, 0.68, 0.32)
TROUSER = (0.20, 0.20, 0.22)
BOOT = (0.12, 0.11, 0.11); SOLE = (0.05, 0.05, 0.05)
CAP = (0.52, 0.53, 0.55); CAP_SH = (0.44, 0.45, 0.47)
SKIN = (0.93, 0.73, 0.63); SKIN_SH = (0.83, 0.62, 0.53)
# rubio tostado: un rubio claro se confunde con la piel bajo la luz cálida
BLOND = (0.72, 0.50, 0.20); BLOND_SH = (0.60, 0.41, 0.16); MOUTH = (0.55, 0.30, 0.27)
box = M.vbox
T, H = hu.T, hu.H
W = 10                                            # medio ancho del torso: más corpulento

hu.legs(M, TROUSER, BOOT, SOLE, boot_top=7)
hu.torso(M, COAT, half=W)
# jersey: cuello vuelto y un triángulo en el pecho entre las solapas cruzadas
box(-6, 40, -4, 6, 44, 4, T, SWEATER)
M.bevel(T, -6, 6, -4, 4, 40, 44)
for y in range(34, 41):
    w = (y - 33) // 2 + 1
    box(-w, y, 4, w, y + 1, 5, T, SWEATER)
for y in (25, 29, 33):                            # chaquetón cruzado: dos filas de botones
    box(-5, y, 4, -4, y + 1, 5, T, BRASS)
    box(3, y, 4, 4, y + 1, 5, T, BRASS)
for y in range(22, 34): box(2, y, 4, 3, y + 1, 5, T, COAT_SH)     # borde de la solapa cruzada
box(-10, 22, -5, 10, 23, 5, T, COAT_SH)           # bajo
hu.arms(M, COAT, SWEATER, SKIN, half=W)
hu.head(M, SKIN)
# gorro de lana con vuelta
box(-6, 50, -6, 6, 55, 6, H, CAP)
M.bevel(H, -6, 6, -6, 6, 50, 55)
box(-6, 50, -6, 6, 52, 6, H, CAP_SH)              # vuelta
M.bevel(H, -6, 6, -6, 6, 50, 52)
# cara: cejas y barba rubias, pómulos curtidos
hu.face(M, BLOND_SH, SKIN_SH, MOUTH)
for x in range(-4, 4): hu.paint_face(M, x, 44, BLOND)            # barba
for x in range(-3, 3): hu.paint_face(M, x, 43, BLOND)
for x in (-4, -3, -2, 1, 2, 3): hu.paint_face(M, x, 45, BLOND)
for x in (-3, -2, 1, 2): hu.paint_face(M, x, 46, BLOND)          # bigote
for y in range(43, 48):                           # patillas y barba por los lados
    for x in (-5, 4):
        if (x, y, 3) in M.V: M.V[(x, y, 3)][1] = BLOND
hu.hair_back(M, SKIN, BLOND)


def paint(k, part, c):
    x, y, z = k
    h = M.hsh(x, y, z)
    if c == SWEATER: return SWEATER if h > -0.2 else SWEATER_SH     # punto grueso
    return None
M.paint(paint)
hu.export(M, 'johansen', half=W)
