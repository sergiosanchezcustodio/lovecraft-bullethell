"""Sapo de Innsmouth ("La sombra sobre Innsmouth"). Compañero (D-36).

Feísimo pero adorable: sapo gordo y achatado, verde oliva grisáceo con verrugas más oscuras
y alguna clara, vientre amarillento, boca ancha con una raya oscura de lado a lado, ojos
dorados saltones en lo alto con pupila horizontal y bolsa de la garganta pálida. Patas de
atrás grandes y dobladas, de delante cortas. Estilo 4, a 48 voxels por metro; mira hacia +Z.
Partes: body, head, leg_fl, leg_fr, leg_bl, leg_br (anim_sapo.gd).
Uso: python tools/gen_sapo.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import slab, rslab, new
import materiales

SKIN = (0.36, 0.42, 0.26); WART = (0.26, 0.30, 0.18); WART_L = (0.52, 0.55, 0.36)
BELLY = (0.78, 0.72, 0.46); THROAT = (0.86, 0.80, 0.58)
EYE = (0.96, 0.72, 0.18); PUPIL = (0.04, 0.04, 0.03); MOUTH = (0.16, 0.14, 0.10)

M = new(3301)
B, H = 'body', 'head'

# patas de atrás grandes, dobladas a los lados; las de delante cortas, abiertas
for part, s in (('leg_bl', -1), ('leg_br', 1)):
    slab(M, part, SKIN, 0, 6, 9 * s, -3, 7, 6, 12, 10, ch=2)
    slab(M, part, SKIN, 0, 2, 11 * s, 4, 5, 5, 5, 5, ch=1)                 # pie hacia delante
for part, s in (('leg_fl', -1), ('leg_fr', 1)):
    slab(M, part, SKIN, 0, 6, 6 * s, 8, 3.5, 3, 3.5, 3, ch=1)
    slab(M, part, SKIN, 0, 1, 7 * s, 10, 5, 5, 3, 3, ch=1)                 # dedos

# cuerpo achatado y ancho
rslab(M, B, SKIN, 2, 12, 0, 0, 19, 20, r=5, rt=4, rb=2)
for (x, y, z), v in M.V.items():
    if v[0] != B: continue
    if y < 5: v[1] = BELLY

# cabeza ancha pegada al cuerpo, boca de lado a lado, ojos saltones arriba
rslab(M, H, SKIN, 4, 13, 0, 9, 18, 10, r=4, rt=3, rb=2)
rslab(M, H, THROAT, 3, 6, 0, 10, 11, 7, r=3, rt=1, rb=1)                   # bolsa de la garganta
for s in (-1, 1):
    rslab(M, H, SKIN, 11, 16, 5 * s, 9.5, 6, 6, r=2.5, rt=2.5, rb=1)       # montículos de los ojos
def face(x, y, c, glow=0):
    z = M.front(x, y)
    if z is not None: M.put(x, y, z, H, c, glow)
for s in (-1, 1):
    for x in range(5 * s - 2, 5 * s + 2):
        for y in (12, 13, 14): face(x, y, EYE)
    for x in range(5 * s - 2, 5 * s + 2): face(x, 13, PUPIL)                 # pupila horizontal
for x in range(-8, 8):                                                      # boca de lado a lado
    face(x, 8 if abs(x + 0.5) < 5 else 9, MOUTH)
face(-2, 10, WART); face(1, 10, WART)                                       # narinas

# verrugas: manchas oscuras y alguna clara por el lomo y la cabeza
for (x, y, z), v in M.V.items():
    if v[1] != SKIN or v[0] not in (B, H, 'leg_bl', 'leg_br'): continue
    h = M.hsh(x // 2, y // 2, z // 2)
    if h > 0.86: v[1] = WART
    elif h < 0.05 and y > 6: v[1] = WART_L

materiales.texturize(M, {SKIN: 'piel', BELLY: 'piel', THROAT: 'piel'})
piv = {'body': [0, 2, 0], 'head': [0, 8, 5],
       'leg_fl': [-6, 5, 8], 'leg_fr': [6, 5, 8], 'leg_bl': [-8, 5, -3], 'leg_br': [8, 5, -3]}
n = M.export('models/sapo.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.5, specular=0.45)
print('sapo', n, 'voxels')
