"""Los dos investigadores secretos (hito 16.25). Estilo 4 (tools/cuerpo.py), como los demás humanos.

  carter    Randolph Carter (*La llave de plata*, *La búsqueda en sueños de la ignota Kadath*): el
            soñador de Boston, de unos cuarenta años. Abrigo largo azul noche abierto sobre un
            chaleco gris paloma, cuello de pajarita con chalina negra, pelo castaño oscuro peinado
            hacia atrás con las sienes grises, sin barba, párpados pesados de quien duerme poco y
            sueña mucho, y la llave de plata colgada al cuello, que brilla.
  whateley  Wilbur Whateley (*El horror de Dunwich*): el hijo de Lavinia, que no es del todo de
            este mundo. Ancho y cargado de hombros, piel cetrina y amarillenta, cara de cabra (cara
            larga sin barbilla, nariz ancha y chata, labios gruesos, orejas largas y caídas), pelo
            negro y áspero, ojos oscuros muy juntos. Abrigado de pies a cabeza con ropa vieja y
            remendada: levita parda que le queda corta, camisa abotonada hasta el cuello, pantalón
            con remiendos, y por los bajos asoman las puntas de unos tentáculos.
Colores separados por valor: Carter azul noche y gris claro; Whateley pardo y amarillo cetrino.
Uso: python tools/gen_secretos.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

SOLE = (0.10, 0.08, 0.07)


def carter():
    SKIN = (0.86, 0.71, 0.60); SKIN_SH = (0.77, 0.61, 0.52); EAR_IN = (0.64, 0.47, 0.38)
    COAT = (0.13, 0.16, 0.26); COAT_SH = (0.09, 0.11, 0.19); VEST = (0.62, 0.62, 0.60)
    SHIRT = (0.88, 0.87, 0.82); CRAVAT = (0.07, 0.07, 0.08); TROUSER = (0.20, 0.20, 0.23)
    SHOE = (0.10, 0.08, 0.07); HAIR = (0.24, 0.17, 0.12); HAIR_SH = (0.18, 0.13, 0.09)
    GREY = (0.62, 0.60, 0.58); BROW = (0.22, 0.16, 0.11); IRIS = (0.40, 0.46, 0.52)
    LID = (0.74, 0.59, 0.50); MOUTH = (0.70, 0.50, 0.46)
    SILVER = (0.80, 0.88, 1.00); CHAIN = (0.66, 0.68, 0.72); BUTTON = (0.70, 0.70, 0.74)
    B = -1
    M = cu.new(1926)
    top = cu.shoes(M, SHOE, SOLE)
    cu.legs(M, TROUSER, bottom=top)
    cu.torso(M, COAT, b=B, bottom=16)
    cu.skirt(M, COAT, 10, top=36, b=B, flare=3, depth=12)                    # abrigo largo, hasta media pierna
    cu.opening(M, 10, 61, 4, 15, COAT_SH)                                    # abierto de arriba abajo: solapas
    cu.opening(M, 36, 61, 8, 12, VEST)                                       # chaleco gris paloma
    cu.opening(M, 53, 61, 2, 6, SHIRT)
    for y in (40, 44, 48, 52): cu.front(M, -1, y, BUTTON)                    # botones del chaleco
    for y in range(54, 61): cu.front(M, -1, y, CRAVAT); cu.front(M, 0, y, CRAVAT)   # chalina negra
    for x in (-2, 1): cu.front(M, x, 59, CRAVAT); cu.front(M, x, 60, CRAVAT)
    slab(M, T, SHIRT, 60, 63, 0, 0.5, 11, 10, 10, 9, ch=1)                   # cuello de pajarita
    for x in (-3, 2): cu.front(M, x, 62, SHIRT, dz=1)                        # sus puntas, dobladas
    # la llave de plata: cadena por el pecho y la llave colgando sobre el chaleco (brilla)
    for (x, y) in ((-3, 58), (-3, 57), (-2, 56), (-2, 55), (-1, 54), (1, 54), (2, 55), (2, 56), (3, 57), (3, 58)):
        cu.front(M, x, y, CHAIN, dz=1)
    key = [(-1, 53), (0, 53), (-2, 52), (1, 52), (-2, 51), (1, 51), (-1, 50), (0, 50),     # el ojo de la llave
           (-1, 49), (-1, 48), (-1, 47), (-1, 46), (-1, 45), (0, 46), (0, 45), (0, 47)]    # caña y paletón
    for (x, y) in key: cu.front(M, x, y, SILVER, dz=1)
    for (x, y, z), v in list(M.V.items()):
        if v[1] == SILVER: M.V[(x, y, z)] = [v[0], SILVER, 1]
    for y in (24, 30, 36): cu.front(M, -6, y, COAT_SH); cu.front(M, 5, y, COAT_SH)   # bolsillos del abrigo
    cu.neck(M, SKIN)
    cu.arms(M, COAT, SKIN, b=B, cuff=SHIRT, cuff_wide=False)
    cu.head(M, SKIN, SKIN_SH, nose=False, r=3, rb=3)
    cu.face_art(M, 76, [                   # en relieve
        '..bbbbb..bbbbb..',                # 76: cejas oscuras, algo arqueadas
        '................',
        '.......nn.......',                # 74: tabique largo
        '.......nn.......',
        '.......nn.......',
        '......snns......',                # 71: punta de la nariz
    ], {'b': BROW, 'n': SKIN, 's': SKIN_SH}, dz=1)
    cu.face_art(M, 74, [                   # pintado: párpados pesados, ojos grises, boca seria
        '...lll....lll...',                # 74: párpados caídos sobre la mitad del ojo
        '..wpiw....wipw..',                # 73: los ojos, medio cerrados
        '................',
        '................',
        '................',
        '................',
        '......oooo......',                # 68: boca fina, sin sonrisa
    ], {'l': LID, 'w': cu.EYE_W, 'p': cu.EYE, 'i': IRIS, 'o': MOUTH})
    cu.ear_holes(M, EAR_IN)
    cu.hair_back(M, SKIN, HAIR, top=82, bottom=69, neck=False)              # corto y peinado hacia atrás
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == SKIN and y >= 78: v[1] = HAIR
    slab(M, H, HAIR, 81, 82, 0, -1, 12, 11, 12, 11, ch=1)                    # algo de volumen arriba
    cu.sideburns(M, HAIR, 73, 78)
    cu.hair_over_ears(M, SKIN, HAIR, 75, 78)
    for (x, y, z), v in M.V.items():                                         # las sienes grises, sobre las orejas
        if v[0] == H and v[1] == HAIR and abs(x + 0.5) >= 7.0 and 75 <= y <= 78 and z >= -2: v[1] = GREY
    for (x, z) in {(k[0], k[2]) for k in M.V if k[1] >= 79}:                 # marcas del peine
        y = M.top(x, z)
        if y is not None and y >= 80 and x % 3 == 1 and M.V[(x, y, z)][1] == HAIR: M.V[(x, y, z)][1] = HAIR_SH
    cu.seams(M, (COAT,))
    cu.finish(M, 'carter', {COAT: 'lana', COAT_SH: 'lana', VEST: 'lana', TROUSER: 'lana', SHOE: 'cuero',
                            SOLE: 'cuero', HAIR: 'pelo', HAIR_SH: 'pelo', GREY: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
              flat=(SILVER, CHAIN, CRAVAT, BUTTON, BROW, IRIS, LID, MOUTH, EAR_IN), b=B, skirt=True)


def whateley():
    SKIN = (0.70, 0.60, 0.38); SKIN_SH = (0.58, 0.49, 0.30); EAR_IN = (0.50, 0.40, 0.26)
    COAT = (0.33, 0.27, 0.18); COAT_SH = (0.25, 0.20, 0.13)
    PATCH1 = (0.42, 0.36, 0.24); PATCH2 = (0.24, 0.24, 0.20); STITCH = (0.62, 0.56, 0.42)
    SHIRT = (0.56, 0.55, 0.48); BUTTON = (0.30, 0.26, 0.20)
    TROUSER = (0.24, 0.23, 0.21); BOOT = (0.17, 0.13, 0.09)
    HAIR = (0.08, 0.07, 0.06); HAIR_SH = (0.14, 0.12, 0.10)
    EYE_D = (0.05, 0.04, 0.03); LIP = (0.48, 0.34, 0.26); NOSE_SH = (0.50, 0.42, 0.26)
    TENT = (0.40, 0.33, 0.40); TENT_SH = (0.30, 0.24, 0.32); SUCKER = (0.66, 0.56, 0.60)
    B = 2
    M = cu.new(1928)
    top = cu.boots(M, BOOT, SOLE, top=10)
    cu.legs(M, TROUSER, bottom=top)
    cu.torso(M, COAT, b=B, bottom=30)                                        # la levita le queda corta
    cu.skirt(M, COAT, 26, top=36, b=B, flare=1, depth=13)
    cu.opening(M, 26, 61, 2, 3, COAT_SH)                                     # abrochada hasta arriba
    cu.opening(M, 54, 61, 3, 6, SHIRT)
    for y in (32, 37, 42, 47, 52, 57): cu.front(M, 0, y, BUTTON, dz=1)
    slab(M, T, SHIRT, 60, 64, 0, 0.5, 12, 11, 11, 10, ch=1)                  # cuello de la camisa, cerrado
    # remiendos: en la levita (pecho y faldón) y en la rodilla del pantalón, con sus puntadas
    for (x0, y0, w, h, col) in ((-10, 44, 5, 5, PATCH1), (5, 30, 4, 4, PATCH2), (3, 50, 4, 3, PATCH2)):
        for x in range(x0, x0 + w):
            for y in range(y0, y0 + h):
                cu.front(M, x, y, STITCH if (y == y0 + h - 1 and x % 2 == 0) else col)   # puntadas por arriba
    for (x, y, z), v in list(M.V.items()):                                   # rodilla izquierda remendada
        if v[0] == 'shin_l' and 22 <= y <= 26 and z >= 3: v[1] = PATCH1
    # las puntas de los tentáculos asoman por los bajos del pantalón, curvadas, con ventosas
    for s, side in ((1, 'shin_r'), (-1, 'shin_l')):
        cx = 5 * s
        for k, (dx, dz) in enumerate(((3.5, 2), (-3.5, 3), (2, -4))):
            for i in range(6):
                y = 9 - i if i < 4 else 6
                x = int(cx + dx * s + (i * 0.4 * (1 if dx > 0 else -1)) * s)
                z = int(dz + (i * 0.5 if dz > 0 else -i * 0.4))
                c = TENT if i < 4 else TENT_SH
                M.put(x, y, z, side, c)
                M.put(x + (1 if dx > 0 else -1), y, z, side, c)
                if i in (2, 4): M.put(x, y, z + (1 if dz > 0 else -1), side, SUCKER)
    cu.neck(M, SKIN)
    cu.arms(M, COAT, SKIN, b=B, cuff=COAT_SH, cuff_wide=False)
    for (x, y, z), v in list(M.V.items()):                                   # las muñecas peludas asoman de las mangas
        if v[0] in ('fore_l', 'fore_r') and v[1] == SKIN and y >= 31 and (x + z) % 2 == 0: v[1] = HAIR_SH
    # cabeza de cabra: más estrecha y profunda, sin barbilla (la mandíbula se mete), orejas largas caídas
    cu.head(M, SKIN, SKIN_SH, ears=False, nose=False, w=14.0, d=16.0, r=3, rb=4)
    for (x, y, z), v in list(M.V.items()):                                   # sin barbilla: la parte baja de la cara, hacia atrás
        if v[0] == H and y <= 66 and z >= 6: del M.V[(x, y, z)]
    for s in (-1, 1):                                                        # orejas largas, de cabra, caídas hacia fuera y abajo
        slab(M, H, SKIN_SH, 73, 77, 8.0 * s, 0.5, 2, 2, 4, 4, ch=0)
        slab(M, H, SKIN_SH, 70, 74, 9.5 * s, 1.0, 2, 2, 4, 4, ch=0)
        slab(M, H, SKIN_SH, 67, 71, 11.0 * s, 1.5, 2, 2, 3, 2, ch=0)
        for y in range(68, 75): M.put(int(round((8.0 + (74 - y) * 0.45) * s)) - (1 if s < 0 else 0), y, 2, H, EAR_IN)
    cu.face_art(M, 76, [                   # en relieve: cejas bajas y juntas, nariz ancha y chata, labios gruesos
        '....bbb..bbb....',                # 76: cejas negras, casi unidas
        '................',
        '.......nn.......',                # 74
        '......nnnn......',
        '.....nnnnnn.....',                # 72: la nariz se ensancha
        '.....snnnns.....',                # 71: aletas anchas
        '................',
        '.....llllll.....',                # 69: labio de arriba, grueso
        '.....llllll.....',                # 68: labio de abajo, caído
        '......llll......',
    ], {'b': HAIR, 'n': SKIN, 's': NOSE_SH, 'l': LIP}, dz=1)
    cu.face_art(M, 74, [                   # pintado: ojos oscuros muy juntos, sin blanco apenas
        '....yp....py....',                # 74: ojos pequeños y juntos, con el blanco amarillento
        '....yp....py....',                # 73
        '................',
        '................',
        '................',
        '................',
        '......dddd......',                # 68: la comisura, oscura
    ], {'p': EYE_D, 'y': (0.80, 0.74, 0.48), 'd': (0.22, 0.12, 0.10)})
    # pelo negro, áspero y rizado: cubre la coronilla y la nuca, con mechones sueltos
    cu.hair_back(M, SKIN, HAIR, top=82, bottom=67, neck=False)
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == SKIN and y >= 78: v[1] = HAIR
    for (x, z) in {(k[0], k[2]) for k in M.V if k[1] >= 80}:                 # rizos: bultos sueltos arriba
        y = M.top(x, z)
        if y is not None and M.V[(x, y, z)][1] == HAIR and M.noise(x, 0, z, 1.6) > 0.62:
            M.put(x, y + 1, z, H, HAIR_SH)
    cu.seams(M, (COAT,))
    cu.finish(M, 'whateley', {COAT: 'lana', COAT_SH: 'lana', PATCH1: 'lona', PATCH2: 'lana', TROUSER: 'lana',
                              BOOT: 'cuero', SOLE: 'cuero', HAIR: 'pelo', HAIR_SH: 'pelo', SKIN: 'piel', SKIN_SH: 'piel',
                              SHIRT: 'lona'},
              flat=(STITCH, BUTTON, EYE_D, (0.80, 0.74, 0.48), LIP, NOSE_SH, EAR_IN, TENT, TENT_SH, SUCKER), b=B, skirt=True)


carter()
whateley()
