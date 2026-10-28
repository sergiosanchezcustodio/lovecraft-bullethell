"""Inspector John R. Legrasse, de la policía de Nueva Orleans ("La llamada de Cthulhu").
Personaje jugable.

Fedora gris marengo de ala ancha con cinta parda (la silueta que lo distingue), gabardina
corta gris piedra abierta sobre un traje azul marino, camisa blanca y corbata oscura, placa
dorada en el pecho, bigote poblado y zapatos negros. Estilo 4 (tools/cuerpo.py).
Uso: python tools/gen_legrasse.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

COAT = (0.63, 0.60, 0.53); COAT_SH = (0.52, 0.49, 0.43)
SUIT = (0.16, 0.19, 0.31); SUIT_SH = (0.12, 0.14, 0.24)
SHIRT = (0.87, 0.86, 0.82); TIE = (0.10, 0.10, 0.12)
BADGE = (0.92, 0.74, 0.30)
SHOE = (0.10, 0.09, 0.09); SOLE = (0.05, 0.05, 0.05)
HAT = (0.27, 0.27, 0.29); HAT_SH = (0.20, 0.20, 0.22); BAND = (0.40, 0.24, 0.15); BOW = (0.32, 0.19, 0.12)
SKIN = (0.84, 0.64, 0.50); SKIN_SH = (0.74, 0.54, 0.42)
EAR_IN = (0.62, 0.44, 0.34); MOUTH = (0.56, 0.37, 0.30)
HAIR = (0.20, 0.15, 0.12); BROW = (0.14, 0.10, 0.08); MOUSTACHE = (0.15, 0.11, 0.08)
IRIS = (0.38, 0.24, 0.13)
BUTTON = (0.20, 0.18, 0.14)
B = -1

M = cu.new(1908)
top = cu.shoes(M, SHOE, SOLE)
cu.legs(M, SUIT, bottom=top)
cu.torso(M, COAT, b=B)
cu.skirt(M, COAT, 26, 40, b=B, flare=3)                                # gabardina corta, hasta medio muslo
# abierta por delante: asoman el traje, la camisa y la corbata; solapas en sombra
cu.opening(M, 26, 61, 9, 13, COAT_SH)
cu.opening(M, 26, 61, 7, 11, SUIT)
cu.opening(M, 52, 61, 2, 6, SHIRT)
for y in range(46, 61): cu.front(M, -1, y, TIE); cu.front(M, 0, y, TIE)
for y in (46, 47): cu.front(M, -2, y, TIE); cu.front(M, 1, y, TIE)
for y in range(26, 45): cu.front(M, -1, y, SUIT_SH)                     # cierre de la americana
for y in (40, 44): cu.front(M, -2, y, BUTTON)
cu.belt(M, COAT_SH, y=45, b=B, h=2)                                    # cinturón de la gabardina
cu.opening(M, 45, 47, 7, 7, SUIT)                                       # (por delante, abierto)
for y in (32, 37): cu.front(M, -7, y, BUTTON, dz=1); cu.front(M, 6, y, BUTTON, dz=1)
# placa dorada en el pecho izquierdo (relieve de un voxel)
for x, y in ((4, 53), (5, 53), (6, 53), (4, 54), (5, 54), (6, 54), (5, 55), (5, 52)):
    cu.front(M, x, y, BADGE, dz=1)
slab(M, T, SHIRT, 60, 63, 0, 0.5, 11, 10, 10, 9, ch=1)                   # cuello de la camisa
slab(M, T, COAT, 58, 62, 0, -1.5, 21, 19, 12, 10, ch=1)                  # cuello de la gabardina, por detrás
cu.neck(M, SKIN)

cu.arms(M, COAT, SKIN, b=B, cuff=COAT_SH)                               # bocamangas de la gabardina
# cabeza rehecha el 23-10-2026 siguiendo las referencias de FLUX en local
# (tools/local/ref_cabeza_legrasse_*_300?.png; la de antes, models/legrasse_v1.json):
# más cuadrada, cejas gruesas y caídas hacia la nariz, ojos con iris, nariz en cuña, bigote de
# manillar con las puntas hacia arriba y fedora con la copa pellizcada
cu.head(M, SKIN, SKIN_SH, nose=False, r=3, rb=2)
cu.face_art(M, 77, [                       # pintado sobre la cara (x = -8 ... 7)
    'hhSSSSSSSSSSSShh',                    # 77: frente, a la sombra del ala
    'hh............hh',
    'h..............h',
    '................',                    # 74: párpado (la ceja encima se comía los ojos)
    '..wppw....wppw..',                    # 73: ojos, iris oscuro en el centro
    '..wiiw....wiiw..',
    '................',
    '................',
    '................',
    '................',
    '................',
    '......oooo......',                    # 66: boca, una raya en tono de piel (roja parecía abierta)
], {'h': HAIR, 'S': SKIN_SH, 'w': cu.EYE_W, 'p': cu.EYE, 'i': IRIS, 'o': MOUTH})
cu.face_art(M, 76, [                       # en relieve (asoma 1)
    '.bbbb......bbbb.',                    # 76: cejas, altas por fuera...
    '...bbbb..bbbb...',                    # ...y bajas junto a la nariz (ceño)
    '................',
    '.......nn.......',                    # 73: tabique
    '.......nn.......',
    '......snns......',                    # 71: punta de la nariz
    '......snns......',
    '..m...mmmm...m..',                    # 69: bigote de manillar justo bajo la nariz,
    '..mmmmmmmmmmmm..',                    #     con las puntas hacia arriba
    '....mmmmmmmm....',
], {'b': BROW, 'n': SKIN, 's': SKIN_SH, 'm': MOUSTACHE}, dz=1)
cu.ear_holes(M, EAR_IN)
# fedora: ala ancha (asoma 2,5 por delante: más taparía los ojos desde la cámara) con el borde
# vuelto hacia arriba por los lados y detrás, cinta con lazo y copa con hendidura y pellizco
slab(M, H, HAT_SH, 78, 79, 0, 0.5, 21, 21, 19.5, 19.5, ch=3)
for (x, y, z) in [k for k, v in M.V.items() if k[1] == 78 and v[1] == HAT_SH]:
    edge = any((x + dx, 78, z + dz) not in M.V for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))
    if edge and z <= 3: M.put(x, 79, z, H, HAT_SH)
slab(M, H, BAND, 79, 81, 0, 0.3, 15, 15, 15, 15, ch=2)
for y in (79, 80):                         # lazo de la cinta, en el lado izquierdo
    for z in (-3, -2): M.put(8, y, z, H, BOW)
M.put(8, 79, -4, H, BOW)
slab(M, H, HAT, 81, 86, 0, 0.3, 15, 13, 15, 12, ch=2)
for z in range(-2, 8):                     # hendidura en lo alto de la copa, de delante atrás
    for x in (-1, 0): M.V.pop((x, 85, z), None)       # (sin pintar: en sombra parecía una ranura)
for x in range(-8, 8):                     # copa que se estrecha por delante arriba (pellizco)
    z = M.front(x, 85)
    if z is not None and abs(x + 0.5) > 2: M.V.pop((x, 85, z), None)
cu.hair_back(M, SKIN, HAIR, top=78, bottom=68, neck=False, point=5)   # pelo corto: la nuca, al aire
cu.sideburns(M, HAIR, 71, 78)
cu.hair_over_ears(M, SKIN, HAIR)

cu.seams(M, (COAT,))
cu.finish(M, 'legrasse', {COAT: 'lona', COAT_SH: 'lona', SUIT: 'lana', SUIT_SH: 'lana', SHOE: 'cuero',
                          SOLE: 'cuero', HAT: 'lana', HAT_SH: 'lana', BAND: 'punto', HAIR: 'pelo',
                          MOUSTACHE: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
          flat=(BADGE, BUTTON, TIE, BROW, IRIS, MOUTH, EAR_IN), b=B,
          hat=(HAT_SH, BAND, HAT, BOW), skirt=True)
