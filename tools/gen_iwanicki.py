"""Padre Iwanicki, sacerdote de la iglesia de San Estanislao ("Los sueños en la casa de la
bruja"). Personaje jugable (D-26).

Sotana negra hasta los tobillos con una fila de botones, alzacuellos blanco, crucifijo de
plata al pecho (el que da en el relato), fajín morado, pelo gris corto con entradas y cejas
pobladas. Delgado. A bloques limpios (tools/humano.py).
Uso: python tools/gen_iwanicki.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import humano as hu

M = Model(S=2, seed=1932)
CASSOCK = (0.10, 0.10, 0.11); CASSOCK_SH = (0.07, 0.07, 0.08)
COLLAR = (0.92, 0.92, 0.88)
SASH = (0.36, 0.16, 0.40)
SILVER = (0.80, 0.80, 0.84)
BUTTON = (0.22, 0.20, 0.22)
HAIR = (0.62, 0.61, 0.60); BROW = (0.46, 0.44, 0.42)
SHOE = (0.08, 0.07, 0.07); SOLE = (0.03, 0.03, 0.03); SOCK = (0.12, 0.12, 0.13)
SKIN = (0.88, 0.70, 0.60); SKIN_SH = (0.78, 0.60, 0.51); MOUTH = (0.52, 0.34, 0.30)
box = M.vbox
T, H = hu.T, hu.H
W = 8

hu.legs_slim(M, SOCK, SHOE, SOLE)
hu.torso(M, CASSOCK, half=W)
hu.skirt(M, CASSOCK, bottom=3, half=W, flare=2)       # sotana hasta los tobillos
for y in range(4, 42, 3): box(-1, y, 4 + (1 if y < 24 else 0), 0, y + 1, 5 + (1 if y < 24 else 0) + (1 if y < 13 else 0), T, BUTTON)
box(-W, 26, -5, W, 28, 5, T, SASH)                    # fajín
M.bevel(T, -W, W, -5, 5, 26, 28)
box(3, 22, 4, 5, 26, 6, T, SASH)                      # caída del fajín
# alzacuellos: tira blanca delante bajo la barbilla
box(-4, 41, -4, 4, 42, 4, T, CASSOCK)
box(-1, 41, 4, 1, 42, 5, T, COLLAR)
box(-3, 40, 4, 3, 41, 5, T, CASSOCK_SH)
# crucifijo de plata colgado de un cordón
for y in range(35, 40): box(-3 + (39 - y) // 2, y, 4, -2 + (39 - y) // 2, y + 1, 5, T, SILVER)
box(-1, 30, 5, 0, 36, 6, T, SILVER)
box(-2, 34, 5, 1, 35, 6, T, SILVER)
hu.arms(M, CASSOCK, CASSOCK_SH, SKIN, half=W, cuff_h=2)
hu.head(M, SKIN)
hu.face(M, BROW, SKIN_SH, MOUTH)
for x in (-4, -3, 2, 3): hu.paint_face(M, x, 49, BROW)   # cejas pobladas
hu.hair_back(M, SKIN, HAIR, top=51)
box(-6, 50, -6, 6, 52, 3, H, HAIR)                    # pelo corto gris con entradas
box(-5, 52, -5, 5, 53, 2, H, HAIR)
box(-6, 45, -5, -5, 51, 1, H, HAIR)                   # sienes
box(5, 45, -5, 6, 51, 1, H, HAIR)


def paint(k, part, c):
    x, y, z = k
    if c == CASSOCK and M.hsh(x, y, z) < -0.5: return CASSOCK_SH
    return None
M.paint(paint)
hu.export(M, 'iwanicki', half=W)
