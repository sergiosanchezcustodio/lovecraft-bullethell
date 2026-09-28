"""Amelia Peaslee, arqueóloga joven y aventurera, sobrina del profesor Peaslee ("La sombra
fuera del tiempo"). Personaje jugable (D-26).

Salacot claro, pelo cobrizo en coleta, camisa caqui con las mangas remangadas, correa de
cartera cruzada y cartera de cuero en la cadera (único relieve), pantalón de montar pardo y
botas altas de cuero. A bloques limpios (tools/humano.py).
Uso: python tools/gen_peaslee.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1935)
HELMET = (0.80, 0.74, 0.58); HELMET_SH = (0.70, 0.64, 0.49); BAND = (0.44, 0.30, 0.18)
HAIR = (0.56, 0.25, 0.12)
SHIRT = (0.67, 0.59, 0.41); SHIRT_SH = (0.58, 0.51, 0.35)
STRAP = (0.34, 0.21, 0.11); BAG = (0.42, 0.26, 0.13); BUCKLE = (0.80, 0.68, 0.40)
TROUSER = (0.40, 0.34, 0.25)
BOOT = (0.30, 0.18, 0.10); SOLE = (0.12, 0.08, 0.06)
SKIN = (0.90, 0.71, 0.58); SKIN_SH = (0.80, 0.61, 0.50); LIPS = (0.70, 0.36, 0.33)
BROW = (0.45, 0.20, 0.10)
box = M.vbox
T, H = hu.T, hu.H
W = 8

hu.legs_slim(M, TROUSER, BOOT, SOLE, boot_top=13, boot=BOOT)
hu.torso(M, SHIRT, half=W)
box(-W, 29, -5, W, 31, 5, T, STRAP)                   # cinturón
box(-1, 29, 4, 1, 31, 5, T, BUCKLE)
for i in range(12):                                   # correa cruzada del hombro izquierdo a la cadera derecha
    x = -6 + i
    y = 40 - i
    box(x, y, 4, x + 2, y + 1, 5, T, STRAP)
    box(x, y, -5, x + 2, y + 1, -4, T, STRAP)
box(5, 23, 3, 9, 29, 6, T, BAG)                       # cartera en la cadera
box(6, 27, 5, 8, 28, 6, T, BUCKLE)
box(-2, 38, 4, 2, 42, 5, T, SKIN)                     # cuello abierto de la camisa
box(-1, 36, 4, 1, 38, 5, T, SKIN)
for y in (33, 35): box(-1, y, 4, 0, y + 1, 5, T, SHIRT_SH)
hu.arms(M, SHIRT, SKIN, SKIN, half=W, cuff_h=4)       # mangas remangadas: antebrazo al aire
for s, p in ((-1, 'arm_l'), (1, 'arm_r')):            # vuelta de la manga
    x0, x1 = (-W - 5, -W) if s < 0 else (W, W + 5)
    box(x0, 29, -3, x1, 31, 3, p, SHIRT_SH)
hu.head(M, SKIN)
hu.face_f(M, BROW, SKIN_SH, LIPS, eye_y=47)
hu.hair_back(M, SKIN, HAIR)
# coleta que asoma bajo el salacot (pieza propia: se balancea al andar)
box(-2, 40, -8, 2, 50, -6, 'hair', HAIR)
box(-1, 38, -8, 1, 40, -6, 'hair', HAIR)                   # punta
box(-2, 48, -8, 2, 50, -6, 'hair', (0.30, 0.18, 0.10))     # lazo oscuro
# salacot: cúpula, cinta y ala corta (más ala taparía los ojos desde la cámara)
box(-6, 50, -6, 6, 51, 7, H, HELMET_SH)               # ala (asoma 2 por delante)
box(-5, 51, -5, 5, 55, 5, H, HELMET)
M.bevel(H, -5, 5, -5, 5, 51, 55)
box(-4, 55, -4, 4, 56, 4, H, HELMET)
box(-5, 51, -5, 5, 52, 5, H, BAND)
M.bevel(H, -5, 5, -5, 5, 51, 52)


def paint(k, part, c):
    x, y, z = k
    if c == SHIRT and M.hsh(x, y, z) < -0.5: return SHIRT_SH
    return None
M.paint(paint)
hu.split_limbs(M)                                     # codos y rodillas
hu.export(M, 'peaslee', half=W, extra_pivots={'hair': [0, 50, -7]}, extra_parents={'hair': 'head'})
