"""Henrietta Blake, escritora, hermana de Robert Blake ("El morador de las tinieblas").
Personaje jugable (D-26).

Sombrero cloché verde azulado (el de los años 20, hasta las cejas), media melena rubia
oscura, abrigo largo burdeos, bufanda crema con una punta por delante, pluma en el
bolsillo, medias y zapatos de pulsera. Estilo 4, cuerpo de mujer (tools/cuerpo.py).
Uso: python tools/gen_blake.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

COAT = (0.34, 0.10, 0.14); COAT_SH = (0.26, 0.07, 0.10)
SCARF = (0.86, 0.80, 0.66); SCARF_SH = (0.74, 0.68, 0.55)
HAT = (0.13, 0.33, 0.36); HAT_SH = (0.10, 0.26, 0.29); HATBAND = (0.72, 0.62, 0.40)
HAIR = (0.58, 0.44, 0.25)
STOCKING = (0.62, 0.50, 0.44); SHOE = (0.30, 0.16, 0.10); SOLE = (0.10, 0.06, 0.04)
SKIN = (0.91, 0.74, 0.62); SKIN_SH = (0.81, 0.63, 0.53); LIP = (0.64, 0.20, 0.22); CHEEK = (0.88, 0.62, 0.54)
BROW = (0.40, 0.28, 0.16); BUTTON = (0.20, 0.08, 0.08); PEN = (0.82, 0.70, 0.40)
AX = cu.ARM_X_F

M = cu.new(1935)
top = cu.shoes_f(M, SHOE, SOLE)
for s, _, shin, _, _ in cu.sides():                                     # pulsera del zapato
    slab(M, shin, SHOE, 3, 4, 4.5 * s, 0.5, 5.5, 5.5, 6, 6, ch=1)
cu.legs_f(M, STOCKING, bottom=top)
cu.torso_f(M, COAT, bottom=36)
cu.skirt(M, COAT, 14, 40, b=-3, flare=2, depth=12.5)                     # abrigo hasta media pantorrilla
for y in range(14, 58): cu.front(M, 0, y, COAT_SH)                       # cierre cruzado
for y in (22, 30, 38, 46): cu.front(M, -3, y, BUTTON, dz=1)
cu.belt(M, COAT_SH, y=44, b=-4, h=2)                                    # cinturón del abrigo
for x0 in (-9, 5):                                                     # bolsillos
    for x in range(x0, x0 + 5): cu.front(M, x, 32, COAT_SH)
for y in (52, 53, 54): cu.front(M, -6, y, PEN, dz=1)                     # pluma en el bolsillo del pecho
for x in range(-8, -3): cu.front(M, x, 51, COAT_SH)
# bufanda: vuelta al cuello y una punta que cae por delante
slab(M, T, SCARF, 58, 64, 0, 0.3, 14, 12, 13, 11, ch=2)
slab(M, T, SCARF, 44, 58, 4, 7, 4.5, 4.5, 2, 2, ch=0)
slab(M, T, SCARF_SH, 43, 44, 4, 7, 4.5, 4.5, 2, 2, ch=0)
for y in range(45, 58, 3):                                              # rayas de punto
    for x in (2, 3, 4, 5): cu.front(M, x, y, SCARF_SH)
cu.neck(M, SKIN)

cu.arms(M, COAT, SKIN, cuff=COAT_SH, ax=AX, slim=True)
cu.head(M, SKIN, SKIN_SH, ears=False)
cu.eyes(M, BROW, brow_style='recta', lashes=cu.EYE)
cu.cheeks(M, CHEEK, y=70)
cu.mouth(M, LIP)
cu.bob(M, HAIR, bottom=67, top=80, fringe=78, side_z=3)
cu.hair_back(M, SKIN, HAIR, top=80, zmax=2)
# cloché: casquete hasta las cejas, con cinta y lazo, y el ala muy corta
slab(M, H, HAT_SH, 77, 78, 0, 0.8, 17, 17, 17.5, 17.5, ch=3)             # ala (asoma 1,5)
slab(M, H, HAT, 78, 85, 0, 0.3, 17, 16, 17, 16, ch=3)
slab(M, H, HAT, 85, 86, 0, 0.3, 14, 14, 14, 14, ch=3)
slab(M, H, HATBAND, 78, 80, 0, 0.3, 17.5, 17.5, 17.5, 17.5, ch=3)
slab(M, H, HATBAND, 80, 83, 6.5, 6, 2.5, 2.5, 3, 3, ch=0)                # lazo

cu.seams(M, (COAT,))
cu.finish(M, 'blake', {COAT: 'lana', COAT_SH: 'lana', SCARF: 'punto', SCARF_SH: 'punto', HAT: 'lana',
                       HAT_SH: 'lana', SHOE: 'cuero', SOLE: 'cuero', HAIR: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(LIP, BROW, CHEEK, BUTTON, PEN, HATBAND, STOCKING), ax=AX)
