"""William Dyer, geólogo de la expedición Miskatonic (1930). Personaje jugable.

Estilo 4 (tools/cuerpo.py, aprobado el 28-09-2026): anatomía realista de caras planas a 48
voxels por metro, cabeza algo grande, manoplas en pinza y texturas por material.
Parka de lona con ribete de borreguillo, gorro de trampero de cuero con orejeras, bufanda
roja con la cola suelta por la espalda, cinturón con dos granadas de palo, pantalón de lana,
manoplas y botas con vuelta de borreguillo. Barba corta y bigote.
Uso: python tools/gen_dyer.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

PARKA = (0.56, 0.44, 0.29); PARKA_SH = (0.46, 0.35, 0.22)
FUR = (0.84, 0.82, 0.77)
TROUSER = (0.29, 0.30, 0.34)
BOOT = (0.37, 0.25, 0.15); SOLE = (0.13, 0.10, 0.08)
MITT = (0.33, 0.22, 0.14); MITT_SH = (0.26, 0.17, 0.11)
CAP = (0.39, 0.25, 0.15)
SKIN = (0.89, 0.69, 0.55); SKIN_SH = (0.79, 0.59, 0.46); LIP = (0.60, 0.36, 0.30); CHEEK = (0.88, 0.58, 0.48)
HAIR = (0.40, 0.30, 0.22); BEARD = (0.58, 0.44, 0.31); BEARD_SH = (0.42, 0.33, 0.25)
BROW = (0.30, 0.22, 0.16)
SCARF = (0.66, 0.19, 0.14); SCARF_SH = (0.54, 0.14, 0.11)
BELT = (0.22, 0.15, 0.10); TOGGLE = (0.30, 0.20, 0.12)
GREN = (0.28, 0.32, 0.24); HANDLE = (0.76, 0.62, 0.40)

M = cu.new(1930)

# piernas
cu.boots(M, BOOT, SOLE, top=11, cuff=FUR)
cu.legs(M, TROUSER)

# tronco
cu.torso(M, PARKA)
slab(M, T, FUR, 36, 39, 0, 0, 25.5, 25.5, 14.5, 14.5, ch=1)                 # bajo de borreguillo
cu.belt(M, BELT)
slab(M, T, SCARF, 59, 64, 0, 0.5, 15, 13, 12, 11, ch=1)                      # bufanda al cuello
cu.neck(M, SKIN)
for x in (-8, -5):                                                           # granadas de palo
    slab(M, T, GREN, 45, 49, x + 1, 7.5, 3, 3, 3, 3, ch=1)
    slab(M, T, HANDLE, 40, 45, x + 1, 7.3, 1.5, 1.5, 1.5, 1.5, ch=0)
for y in range(46, 58):                                                      # tapeta con alamares
    M.put(0, y, M.front(0, y) or 7, T, PARKA_SH)
for y in (48, 52, 56):
    z = M.front(-1, y)
    if z is not None: M.put(-1, y, z + 1, T, TOGGLE); M.put(0, y, z + 1, T, TOGGLE)
# cola de la bufanda por la espalda (pieza propia, se balancea)
slab(M, 'scarf', SCARF, 47, 61, 3, -7.5, 5, 5, 1.5, 1.5, ch=0)
slab(M, 'scarf', SCARF_SH, 46, 47, 3, -7.5, 5, 5, 1.5, 1.5, ch=0)

# brazos
cu.arms(M, PARKA, MITT, cuff=FUR, mitten=True)

# cabeza (redondeada, 30-09-2026)
cu.head(M, SKIN, SKIN_SH, ears=False, w=16)
cu.beard(M, BEARD)
# gorro de trampero: copa abombada, banda de borreguillo gruesa y orejeras redondeadas
cu.rslab(M, H, CAP, 78, 87, 0, 0.3, 17, 17, r=4, rt=3, rb=0)
cu.rslab(M, H, FUR, 77, 81, 0, 0.5, 19, 19, r=5, rt=1.5, rb=1.5)
for s_ in (-1, 1):
    cu.rslab(M, H, CAP, 67, 78, 8.5 * s_ - 0.5, -0.5, 2, 7, r=1, rt=0, rb=2)
    cu.rslab(M, H, FUR, 66, 68, 8.5 * s_ - 0.5, -0.5, 3, 7.5, r=1, rt=0, rb=1)
# cara pintada sobre la piel
cu.eyes(M, BROW, brow_style='caida')
cu.cheeks(M, CHEEK, y=72)
for x in range(-4, 3): cu.paint_face(M, x, 69, BEARD_SH, dz=1)                  # bigote
for x in (-3, 2): cu.paint_face(M, x, 68, BEARD_SH, dz=1)
for x in (-1, 0): cu.paint_face(M, x, 67, LIP)                                  # boca
cu.hair_back(M, SKIN, HAIR)

cu.seams(M, (PARKA,))
cu.finish(M, 'dyer', {PARKA: 'lona', PARKA_SH: 'lona', FUR: 'borreguillo', TROUSER: 'lana',
                      BOOT: 'cuero', SOLE: 'cuero', MITT: 'cuero', MITT_SH: 'cuero', CAP: 'cuero',
                      SCARF: 'punto', SCARF_SH: 'punto', HAIR: 'pelo', BEARD: 'pelo', BEARD_SH: 'pelo',
                      SKIN: 'piel', SKIN_SH: 'piel', BELT: 'cuero'},
          flat=(LIP, BROW, TOGGLE, CHEEK),
          extra_pivots={'scarf': [3, 61, -7.5]}, extra_parents={'scarf': 'torso'})
