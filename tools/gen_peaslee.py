"""Amelia Peaslee, arqueóloga joven y aventurera, sobrina del profesor Peaslee ("La sombra
fuera del tiempo"). Personaje jugable (D-26).

Salacot claro, pelo cobrizo en coleta, camisa caqui con las mangas remangadas, correa de
cartera cruzada y cartera de cuero en la cadera (único relieve), pantalón de montar pardo y
botas altas de cuero. Estilo 4, cuerpo de mujer (tools/cuerpo.py).
Uso: python tools/gen_peaslee.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

HELMET = (0.80, 0.74, 0.58); HELMET_SH = (0.68, 0.62, 0.48); BAND = (0.44, 0.30, 0.18)
HAIR = (0.50, 0.23, 0.12); HAIR_TIE = (0.28, 0.16, 0.09)
SHIRT = (0.67, 0.59, 0.41); SHIRT_SH = (0.56, 0.49, 0.33)
STRAP = (0.34, 0.21, 0.11); BAG = (0.44, 0.27, 0.13); BUCKLE = (0.80, 0.68, 0.40)
TROUSER = (0.40, 0.34, 0.25)
BOOT = (0.30, 0.18, 0.10); SOLE = (0.12, 0.08, 0.06)
SKIN = (0.90, 0.71, 0.58); SKIN_SH = (0.80, 0.61, 0.50); LIP = (0.68, 0.34, 0.32); CHEEK = (0.88, 0.60, 0.50)
BROW = (0.45, 0.20, 0.10)
BUTTON = (0.40, 0.33, 0.22)
AX = cu.ARM_X_F

M = cu.new(1935)
top = cu.boots(M, BOOT, SOLE, top=21, slim=True)                        # botas altas
cu.legs_f(M, TROUSER, bottom=top)
for s, leg, _, _, _ in cu.sides():                                      # pantalón de montar: muslo abombado
    slab(M, leg, TROUSER, 29, 39, 4.5 * s * 1.1, 0, 10, 11, 10, 10.5, ch=2)
cu.torso_f(M, SHIRT, bottom=36)
cu.belt(M, STRAP, y=41, b=-4, h=2, buckle=BUCKLE)
# pechera: cuello abierto en V, tapeta con botones y bolsillos del pecho
cu.opening(M, 56, 61, 1, 5, SKIN)
for y in range(43, 56): cu.front(M, -1, y, SHIRT_SH)
for y in (46, 50, 54): cu.front(M, 0, y, BUTTON)
for x0 in (-7, 3):
    for x in range(x0, x0 + 4): cu.front(M, x, 55, SHIRT_SH)
    for y in (51, 52, 53, 54): cu.front(M, x0, y, SHIRT_SH); cu.front(M, x0 + 3, y, SHIRT_SH)
slab(M, T, SHIRT_SH, 59, 62, 0, 0.3, 11, 10, 10, 9, ch=1)                 # cuello de la camisa
cu.opening(M, 59, 62, 3, 5, SKIN)
cu.neck(M, SKIN)
# correa cruzada del hombro izquierdo a la cadera derecha, por delante y por detrás
for i in range(19):
    x, y = -8 + i * 0.9, 60 - i
    for dx in (0, 1, 2):
        cu.front(M, int(round(x)) + dx, y, STRAP)
        cu.back(M, int(round(x)) + dx, y, STRAP)
# cartera de cuero en la cadera derecha, con su hebilla
slab(M, T, BAG, 32, 41, 10.5, 2, 3, 3, 8, 8, ch=1)
slab(M, T, STRAP, 38, 41, 11.5, 2, 1.5, 1.5, 8.5, 8.5, ch=0)
for y in (38, 39): M.put(12, y, 2, T, BUCKLE)

# mangas remangadas: antebrazo al aire y la vuelta de la manga en el codo
cu.arms(M, SHIRT, SKIN, fore=SKIN, ax=AX, slim=True)
for s, _, _, _, fa in cu.sides():
    slab(M, fa, SHIRT_SH, 43, 46, AX * s * 1.02, 0.5, 7.5, 7.5, 8, 8, ch=1)

cu.head(M, SKIN, SKIN_SH, ears=False, fem=True)
cu.eyes(M, BROW, brow_style='recta', lashes=cu.EYE)
cu.cheeks(M, CHEEK)
cu.mouth(M, LIP)
# pelo recogido: tapa las orejas y la nuca, con un mechón fino delante de cada oreja
cu.hair_back(M, SKIN, HAIR, top=80, zmax=2)
for (x, y, z), v in M.V.items():
    if v[0] == H and v[1] == SKIN and 74 <= y < 78 and abs(x + 0.5) >= 6.5 and z <= 3:
        v[1] = HAIR
# coleta (pieza propia: se balancea al andar), del cogote hacia abajo
slab(M, 'hair', HAIR_TIE, 74, 76, 0, -7.5, 4, 4, 3, 3, ch=0)             # lazo
slab(M, 'hair', HAIR, 76, 79, 0, -7, 5, 5, 3, 3, ch=1)                  # nacimiento, bajo el ala
slab(M, 'hair', HAIR, 64, 74, 0, -8.5, 4.5, 3.5, 3.5, 3.5, ch=1, zoff0=-0.8, zoff1=0)
slab(M, 'hair', HAIR, 60, 64, 0, -9.3, 3, 3.5, 3, 3, ch=1)                # punta
# salacot: ala (asoma 2,5 por delante, más taparía los ojos), cinta y cúpula de caras planas
slab(M, H, HELMET_SH, 78, 79, 0, 0.5, 19.5, 19.5, 19.5, 19.5, ch=3)
slab(M, H, BAND, 79, 81, 0, 0.5, 16, 16, 16.5, 16.5, ch=2)
slab(M, H, HELMET, 81, 86, 0, 0.5, 16, 16, 16.5, 16.5, ch=2)
slab(M, H, HELMET, 86, 88, 0, 0.5, 13, 13, 13.5, 13.5, ch=2)
slab(M, H, HELMET_SH, 88, 89, 0, 0.5, 4, 4, 4, 4, ch=1)                   # botón de la cúpula

cu.seams(M, (SHIRT,))
cu.finish(M, 'peaslee', {SHIRT: 'lona', SHIRT_SH: 'lona', TROUSER: 'lana', BOOT: 'cuero', SOLE: 'cuero',
                         STRAP: 'cuero', BAG: 'cuero', HELMET: 'lona', HELMET_SH: 'lona', HAIR: 'pelo',
                         SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(LIP, BROW, CHEEK, BUTTON, BUCKLE, HAIR_TIE, BAND), ax=AX,
          extra_pivots={'hair': [0, 74, -8]}, extra_parents={'hair': 'head'})
