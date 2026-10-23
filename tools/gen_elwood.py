"""Sargento Frank Elwood, veterano de la Gran Guerra (pariente del Elwood de "Los sueños en la
casa de la bruja"). Personaje jugable (D-26).

Casco Brodie (plato de ala ancha) verde oliva, guerrera de uniforme oliva con cinturón y
correajes de lona, cartucheras, polainas enrolladas sobre las botas, bigote de cepillo y
cara curtida. Corpulento, como Johansen. Estilo 4 (tools/cuerpo.py).
Uso: python tools/gen_elwood.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

TUNIC = (0.37, 0.38, 0.25); TUNIC_SH = (0.29, 0.30, 0.19)
WEBBING = (0.60, 0.56, 0.42); POUCH = (0.52, 0.48, 0.35)
BRASS = (0.78, 0.62, 0.30)
TROUSER = (0.34, 0.34, 0.23)
PUTTEE = (0.43, 0.41, 0.29); PUTTEE_SH = (0.35, 0.33, 0.23)
BOOT = (0.26, 0.17, 0.10); SOLE = (0.10, 0.07, 0.05)
HELMET = (0.31, 0.34, 0.25); HELMET_SH = (0.24, 0.27, 0.19)
SKIN = (0.84, 0.62, 0.48); SKIN_SH = (0.73, 0.52, 0.40); CHEEK = (0.82, 0.52, 0.42)
HAIR = (0.30, 0.22, 0.15); MOUSTACHE = (0.25, 0.17, 0.11); BROW = (0.20, 0.14, 0.10)
IRIS = (0.18, 0.15, 0.10); MOUTH = (0.68, 0.47, 0.38); EAR_IN = (0.62, 0.44, 0.34)
HELMET_RIM = (0.40, 0.43, 0.33); STRAP = (0.32, 0.22, 0.13)
B = 3

M = cu.new(1918)
cu.boots(M, BOOT, SOLE, top=7)
cu.legs(M, TROUSER)
for s in (-1, 1):                                                      # polainas enrolladas, en bandas
    shin = 'shin_l' if s < 0 else 'shin_r'
    for y in range(7, 25):
        w = 8.5 + (y - 7) * 0.06
        slab(M, shin, PUTTEE if (y // 2) % 2 else PUTTEE_SH, y, y + 1, 5 * s, -0.2, w, w, 9, 9, ch=1)
for s in (-1, 1):                                                      # pantalón abombado sobre la polaina
    slab(M, 'shin_l' if s < 0 else 'shin_r', TROUSER, 24, 27, 5 * s, 0, 9.5, 9, 9.5, 9, ch=1)
cu.torso(M, TUNIC, b=B, bottom=35)
cu.belt(M, WEBBING, y=43, b=B, h=3, buckle=BRASS)
for x0 in (-10, -6, 4, 8):                                             # cartucheras en el cinturón
    slab(M, T, POUCH, 43, 48, x0 + 1, 7.5, 3, 3, 2, 2, ch=0)
for x in (-7, 6):                                                      # tirantes del correaje, delante y detrás
    for y in range(46, 61):
        cu.front(M, x, y, WEBBING); cu.back(M, x, y, WEBBING)
for y in (40, 50, 55): cu.front(M, -1, y, BRASS, dz=1)                  # botones
for x0 in (-10, 5):                                                    # bolsillos de pecho con solapa
    for x in range(x0, x0 + 5): cu.front(M, x, 56, TUNIC_SH)
    for y in range(51, 56): cu.front(M, x0 + 2, y, TUNIC_SH)
slab(M, T, TUNIC_SH, 59, 64, 0, 0, 12, 11, 11, 10, ch=1)                 # cuello alto
cu.neck(M, SKIN)

cu.arms(M, TUNIC, SKIN, b=B, cuff=TUNIC_SH, cuff_wide=False)
# cabeza rehecha el 23-10-2026 como la de Legrasse (referencias tools/local/ref_cabeza_elwood_*):
# el ala del casco asoma 4 por delante y tapa desde la cámara hasta la fila 75, así que la cara
# va una fila más abajo: ceño (cejas con las puntas de dentro bajas), ojos con iris, nariz larga
# y bigote militar justo debajo, con la boca como una raya en tono de piel una fila más abajo
# (roja o pegada al bigote parecía abierta); barboquejo de cuero y borde del casco más claro
cu.head(M, SKIN, SKIN_SH, nose=False, r=3, rb=2)
cu.face_art(M, 74, [
    '................',
    '................',
    '..wppw....wppw..',                    # 72: ojos
    '..wiiw....wiiw..',
    '..cc........cc..',                    # 70: mejillas curtidas
    '................',
    '................',
    '................',
    '................',
    '......oooo......',                    # 65: boca, separada del bigote (pegada parecía abierta)
], {'w': cu.EYE_W, 'p': cu.EYE, 'i': IRIS, 'c': CHEEK, 'o': MOUTH})
cu.face_art(M, 74, [                       # en relieve
    '..bbbb....bbbb..',                    # 74: cejas rectas...
    '......b..b......',                    # ...con las puntas de dentro bajas (ceño)
    '.......nn.......',                    # 72: tabique
    '.......nn.......',
    '......snns......',                    # 70: punta de la nariz
    '......snns......',
    '.....mmmmmm.....',                    # 68: bigote militar, más ancho abajo (estrecho
    '....mmmmmmmm....',                    #     y negro recordaba a otro bigote)
], {'b': BROW, 'n': SKIN, 's': SKIN_SH, 'm': MOUSTACHE}, dz=1)
cu.ear_holes(M, EAR_IN)
cu.hair_back(M, SKIN, HAIR, top=78, bottom=68, neck=False, point=5)   # pelo corto, de soldado
cu.sideburns(M, HAIR, 72, 78)
cu.hair_over_ears(M, SKIN, HAIR)
# casco Brodie: plato muy ancho (asoma 5 a los lados y 4 por delante y por detrás) con el borde
# más claro, copa baja con un remache arriba y barboquejo por los lados de la cara
slab(M, H, HELMET_SH, 78, 79, 0, 0, 25, 25, 23, 23, ch=6)
for (x, y, z) in [k for k, v in M.V.items() if k[1] == 78 and v[1] == HELMET_SH]:
    if any((x + dx, 78, z + dz) not in M.V for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1))):
        M.V[(x, y, z)][1] = HELMET_RIM
slab(M, H, HELMET_SH, 79, 80, 0, 0, 22, 22, 21, 21, ch=5)
slab(M, H, HELMET, 79, 84, 0, 0.3, 16, 14, 16, 14, ch=2)
slab(M, H, HELMET, 84, 85, 0, 0.3, 11, 11, 11, 11, ch=2)
slab(M, H, HELMET_SH, 85, 86, -0.5, 0.3, 2, 2, 2, 2, ch=0)                 # remache
for y in range(64, 78):                    # barboquejo, por fuera de la cara a los lados
    for s_ in (-1, 1):
        xs = [x for x in range(-10, 10) if (x, y, 2) in M.V and M.V[(x, y, 2)][0] == H]
        if not xs: continue
        x = (min(xs) - 1) if s_ < 0 else (max(xs) + 1)
        for z in (2, 3): M.put(x, y, z, H, STRAP, 0, False)

cu.seams(M, (TUNIC,))
cu.finish(M, 'elwood', {TUNIC: 'lana', TUNIC_SH: 'lana', WEBBING: 'lona', POUCH: 'lona', TROUSER: 'lana',
                        PUTTEE: 'lana', PUTTEE_SH: 'lana', BOOT: 'cuero', SOLE: 'cuero', HAIR: 'pelo',
                        MOUSTACHE: 'pelo', SKIN: 'piel', SKIN_SH: 'piel', STRAP: 'cuero'},
          flat=(BRASS, CHEEK, BROW, IRIS, MOUTH, EAR_IN), b=B,
          hat=(HELMET_SH, HELMET, HELMET_RIM, STRAP))
