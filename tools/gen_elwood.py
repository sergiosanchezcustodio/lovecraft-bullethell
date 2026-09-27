"""Sargento Frank Elwood, veterano de la Gran Guerra (pariente del Elwood de "Los sueños en la
casa de la bruja"). Personaje jugable (D-26).

Casco Brodie (plato de ala ancha) verde oliva, guerrera de uniforme oliva con cinturón y
correajes de lona, cartucheras, polainas enrolladas sobre las botas, bigote de cepillo y
cara curtida. Corpulento, como Johansen. A bloques limpios (tools/humano.py).
Uso: python tools/gen_elwood.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1918)
TUNIC = (0.36, 0.37, 0.24); TUNIC_SH = (0.30, 0.31, 0.20)
WEBBING = (0.58, 0.54, 0.40); POUCH = (0.50, 0.46, 0.33)
BRASS = (0.78, 0.62, 0.30)
TROUSER = (0.33, 0.33, 0.22)
PUTTEE = (0.42, 0.40, 0.28); PUTTEE_SH = (0.36, 0.34, 0.24)
BOOT = (0.24, 0.16, 0.10); SOLE = (0.10, 0.07, 0.05)
HELMET = (0.30, 0.33, 0.24); HELMET_SH = (0.25, 0.28, 0.20)
SKIN = (0.84, 0.62, 0.48); SKIN_SH = (0.74, 0.53, 0.40)
HAIR = (0.30, 0.22, 0.15); MOUSTACHE = (0.30, 0.21, 0.14); MOUTH = (0.50, 0.31, 0.26)
box = M.vbox
T, H = hu.T, hu.H
W = 10

hu.legs(M, TROUSER, BOOT, SOLE, boot_top=4)
for s, p in ((-1, 'leg_l'), (1, 'leg_r')):            # polainas enrolladas, en bandas
    x0, x1 = (-7, -1) if s < 0 else (1, 7)
    for y in range(4, 13):
        box(x0, y, -3, x1, y + 1, 3, p, PUTTEE if (y % 2) else PUTTEE_SH)
    M.bevel(p, x0, x1, -3, 3, 4, 13)
hu.torso(M, TUNIC, half=W)
box(-W, 28, -5, W, 30, 5, T, WEBBING)                 # cinturón de lona
M.bevel(T, -W, W, -5, 5, 28, 30)
box(-1, 28, 4, 1, 30, 5, T, BRASS)
for x0 in (-8, -5, 3, 6):                             # cartucheras
    box(x0, 30, 4, x0 + 2, 33, 6, T, POUCH)
for i in range(12):                                   # tirantes del correaje, cruzados en la espalda
    for xs in (-6, 5):
        box(xs, 30 + i, 4, xs + 1, 31 + i, 5, T, WEBBING)
        box(xs, 30 + i, -5, xs + 1, 31 + i, -4, T, WEBBING)
for y in (24, 34, 38): box(-1, y, 4, 0, y + 1, 5, T, BRASS)   # botones
box(-3, 40, 4, 3, 42, 5, T, TUNIC_SH)                # cuello alto
hu.arms(M, TUNIC, TUNIC_SH, SKIN, half=W, cuff_h=2)
hu.head(M, SKIN)
hu.face(M, HAIR, SKIN_SH, MOUTH, eye_y=47)
for x in (-2, -1, 0, 1): hu.paint_face(M, x, 45, MOUSTACHE)   # bigote de cepillo
hu.hair_back(M, SKIN, HAIR)
# casco Brodie: plato ancho y copa baja (ala de 2 voxels para no tapar los ojos)
box(-7, 50, -7, 7, 51, 7, H, HELMET_SH)
for x, z in ((-7, -7), (-7, 6), (6, -7), (6, 6)): M.V.pop((x, 50, z), None)
box(-5, 51, -5, 5, 54, 5, H, HELMET)
M.bevel(H, -5, 5, -5, 5, 51, 54)
box(-3, 54, -3, 3, 55, 3, H, HELMET)


def paint(k, part, c):
    x, y, z = k
    if c == TUNIC and M.hsh(x, y, z) < -0.5: return TUNIC_SH
    return None
M.paint(paint)
hu.export(M, 'elwood', half=W)
