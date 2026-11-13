"""Investigadores nuevos de la tienda (fase 20, bloque E). Estilo 4 (tools/cuerpo.py), como los
demás humanos: bloques limpios, detalles pintados y casi sin relieve.

  pickman   Richard Upton Pickman (*El modelo de Pickman*): el pintor de Boston de familia de
            Salem al que echaron del Club de Arte. Delgado, pelo castaño muy oscuro largo y
            revuelto, sin afeitar del todo, ojos oscuros hundidos con ojeras de no dormir. Blusón
            de pintor de lino crudo con canesú, pliegues y manchas de óleo (carmín, ocre, verde,
            sombra), lazo negro de artista al cuello, un pincel en el bolsillo del pecho,
            pantalón gris carbón y zapatos pardos gastados.
  necrofago El necrófago que sale de los lienzos de Pickman: encorvado, de piel gris verdosa y
            gomosa con manchas de moho, hocico de perro, orejas puntiagudas, costillas marcadas,
            garras largas y pezuñas; ojos amarillos que brillan. Criatura: sin ropa.
  lienzo    El caballete de Pickman con un lienzo a medio pintar (una figura que asoma de un
            túnel en rojos y verdes sucios), sobre tres patas de madera.
Colores separados por valor: Pickman, lino claro sobre carbón oscuro.
Uso: python tools/gen_tienda20.py [pickman ...]
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, rslab, T, H

SOLE = (0.10, 0.08, 0.07)


def pickman():
    SKIN = (0.84, 0.70, 0.60); SKIN_SH = (0.75, 0.60, 0.52); EAR_IN = (0.62, 0.46, 0.38)
    SMOCK = (0.76, 0.72, 0.62); SMOCK_SH = (0.63, 0.59, 0.50); YOKE = (0.70, 0.66, 0.56)
    SHIRT = (0.88, 0.86, 0.80); BOW = (0.06, 0.06, 0.07); BOW_SH = (0.12, 0.12, 0.13)
    TROUSER = (0.17, 0.17, 0.19); SHOE = (0.26, 0.17, 0.10)
    HAIR = (0.13, 0.10, 0.08); HAIR_SH = (0.19, 0.15, 0.11)
    BROW = (0.12, 0.09, 0.07); IRIS = (0.26, 0.18, 0.11); BAGS = (0.62, 0.48, 0.45)
    MOUTH = (0.60, 0.43, 0.40)
    PAINTS = [(0.60, 0.10, 0.09), (0.76, 0.55, 0.15), (0.12, 0.34, 0.27), (0.31, 0.20, 0.12), (0.09, 0.09, 0.10)]
    WOOD = (0.52, 0.31, 0.14); FERRULE = (0.64, 0.62, 0.58); BRISTLE = (0.60, 0.10, 0.09)
    B = -1
    M = cu.new(1926 + 20)
    top = cu.shoes(M, SHOE, SOLE)
    cu.legs(M, TROUSER, bottom=top)
    cu.torso(M, SMOCK, b=B + 1)                                              # el blusón, holgado
    cu.skirt(M, SMOCK, 26, top=40, b=B + 1, flare=3, depth=13)               # hasta medio muslo
    for (x, y, z), v in M.V.items():                                         # canesú: la parte de arriba
        if v[0] == T and v[1] == SMOCK and y >= 55: v[1] = YOKE
    for x in range(-12, 12): cu.front(M, x, 55, SMOCK_SH)                    # su costura
    for x in (-9, -6, -3, 2, 5, 8):                                          # pliegues del canesú abajo
        for y in range(28, 55):
            if (y + x) % 7 != 0: cu.front(M, x, y, SMOCK_SH)
    cu.opening(M, 57, 61, 3, 7, SHIRT)                                       # la camisa en el cuello
    # el lazo negro de artista: dos lazadas anchas a los lados de un nudo y dos puntas cortas
    bow = ['.ddddd..ddddd...',                # 60
           '.bbbbbkkbbbbb...',                # 59
           '..bbbbkkbbbb....',                # 58
           '....bb..bb......',                # 57: las puntas
           '....b....b......']                # 56
    for i, row in enumerate(bow):
        for j, ch in enumerate(row):
            if ch != '.': cu.front(M, j - 8 + 1, 60 - i, {'b': BOW, 'd': BOW_SH, 'k': BOW_SH}[ch], dz=1)
    # bolsillo del pecho (a su izquierda) con un pincel que asoma
    for x in range(3, 8):
        cu.front(M, x, 48, SMOCK_SH)
        for y in range(44, 48): cu.front(M, x, y, SMOCK_SH if x in (3, 7) else SMOCK)
    for y in range(47, 54): cu.front(M, 5, y, WOOD, dz=1)
    cu.front(M, 5, 54, FERRULE, dz=1); cu.front(M, 5, 55, BRISTLE, dz=1); cu.front(M, 5, 56, BRISTLE, dz=1)
    cu.neck(M, SKIN)
    cu.arms(M, SMOCK, SKIN, b=B + 1, cuff=SMOCK_SH, cuff_wide=True)          # mangas anchas fruncidas
    # manchas de óleo: pocas y grandes (manchurrones, no confeti), más en el vientre y los puños,
    # y dos pinceladas de limpiar el pincel en el vientre
    for (x, y, z), v in M.V.items():
        if v[1] not in (SMOCK, SMOCK_SH, YOKE): continue
        n = M.noise(x, y, z, 4.5)
        k = 0.78 - (0.05 if 28 <= y <= 44 or v[0].startswith('fore') else 0.0)
        if n > k:
            v[1] = PAINTS[int(M.hsh(x // 6, y // 6, z // 6) * len(PAINTS)) % len(PAINTS)]
    for (x0, y, n, c) in ((-8, 36, 5, 0), (-7, 35, 3, 0), (1, 33, 5, 2), (2, 32, 3, 2)):
        for x in range(x0, x0 + n): cu.front(M, x, y, PAINTS[c])
    cu.head(M, SKIN, SKIN_SH, nose=False, r=3, rb=3)
    cu.face_art(M, 76, [                   # en relieve
        '..bbbbb..bbbbb..',                # 76: cejas oscuras y rectas, algo juntas
        '................',
        '.......nn.......',                # 74: nariz larga y fina
        '.......nn.......',
        '.......nn.......',
        '.......sn.......',                # 71
    ], {'b': BROW, 'n': SKIN, 's': SKIN_SH}, dz=1)
    cu.face_art(M, 74, [                   # pintado: ojos oscuros hundidos con ojeras y boca fina, seria
        '..wpiw....wipw..',                # 74
        '..wppw....wppw..',                # 73
        '..ggg......ggg..',                # 72: ojeras
        '................',
        '................',
        '................',
        '......mmmm......',                # 68: boca fina
    ], {'w': cu.EYE_W, 'p': cu.EYE, 'i': IRIS, 'g': BAGS, 'm': MOUTH})
    cu.ear_holes(M, EAR_IN)
    # pelo largo y revuelto: tapa las orejas por arriba, baja por la nuca y cae algo por la frente
    cu.hair_back(M, SKIN, HAIR, top=200, bottom=66, neck=True)
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == SKIN and y >= 78: v[1] = HAIR
    cu.sideburns(M, HAIR, 70, 78)
    cu.hair_over_ears(M, SKIN, HAIR, 73, 78)
    for (x, y) in ((-6, 77), (-5, 77), (-4, 77), (-6, 76), (2, 77), (3, 77), (5, 77), (6, 77), (6, 76)):
        cu.front(M, x, y, HAIR)                                              # mechones sobre la frente
    for (x, y, z), v in M.V.items():                                         # revuelto: mechones más claros
        if v[0] == H and v[1] == HAIR and M.noise(x * 1.5, y * 0.5, z * 1.5, 1.6) > 0.62: v[1] = HAIR_SH
    cu.seams(M, (SMOCK,))
    cu.finish(M, 'pickman', {SMOCK: 'lona', SMOCK_SH: 'lona', YOKE: 'lona', TROUSER: 'lana', SHOE: 'cuero',
                             SOLE: 'cuero', HAIR: 'pelo', HAIR_SH: 'pelo', SKIN: 'piel', SKIN_SH: 'piel', SHIRT: 'lona'},
              flat=tuple(PAINTS) + (WOOD, FERRULE, BRISTLE, BOW, BOW_SH, BROW, IRIS, BAGS, MOUTH, EAR_IN),
              b=B + 1, skirt=True)


def necrofago():
    SKIN = (0.30, 0.37, 0.35); SKIN_SH = (0.22, 0.28, 0.27); MOLD = (0.21, 0.30, 0.20)
    BELLY = (0.40, 0.45, 0.42); NOSE = (0.06, 0.05, 0.05); MOUTH = (0.22, 0.05, 0.05)
    TOOTH = (0.86, 0.82, 0.66); CLAW = (0.12, 0.10, 0.08); HOOF = (0.14, 0.11, 0.09)
    EYE = (1.0, 0.82, 0.25); EAR_IN = (0.18, 0.22, 0.21)
    M = cu.new(1926 + 21)
    top = cu.shoes_f(M, HOOF, HOOF)                                         # pezuñas finas
    cu.legs_f(M, SKIN, bottom=top)                                           # piernas flacas
    cu.torso_f(M, SKIN, b=-2)                                                # tronco estrecho, de costillas
    cu.neck(M, SKIN)
    cu.arms(M, SKIN, SKIN, b=-2, slim=True)
    for (x, y, z), v in M.V.items():                                         # garras: solo las puntas de los dedos
        if v[0].startswith('fore') and y <= 29: v[1] = CLAW
    for y in (47, 50, 53):                                                   # costillas
        for x in range(-8, 8):
            if abs(x + 0.5) > 1.5: cu.front(M, x, y, SKIN_SH)
    for y in range(39, 45):                                                  # vientre hundido, más claro
        for x in range(-4, 4): cu.front(M, x, y, BELLY)
    cu.head(M, SKIN, SKIN_SH, ears=False, nose=False, w=12.0, d=12.0)
    for k in [k for k in M.V if M.V[k][0] == H and k[1] >= 77]: del M.V[k]  # cráneo bajo, de perro
    rslab(M, H, SKIN_SH, 76, 77, 0, -0.5, 10, 10, r=2, rt=0, rb=0)
    rslab(M, H, SKIN, 66, 72, 0, 8.0, 8, 7, r=2, rt=2, rb=1)                 # hocico largo
    rslab(M, H, SKIN_SH, 64, 66, 0, 7.5, 7, 6, r=1, rt=0, rb=1)              # mandíbula
    for x in (-1, 0):                                                        # la trufa
        for y in (70, 71): cu.front(M, x, y, NOSE, part=H)
    for x in range(-3, 3): cu.front(M, x, 66, MOUTH, part=H)                 # la boca, con colmillos
    for x in (-3, -1, 1, 2): cu.front(M, x, 67, TOOTH, part=H)
    for x in (-2, 0): cu.front(M, x, 65, TOOTH, part=H)
    for s in (-1, 1):                                                        # orejas de murciélago, echadas atrás
        for i in range(6):
            y = 75 + i
            for dz in range(-3 + i // 2 - (3 - i // 2), -2 + i // 2 + 1):
                for dx in range(max(1, 3 - i // 2)):
                    x = (5 + dx) if s > 0 else (-6 - dx)
                    M.put(x, y, dz - i, H, EAR_IN if dx == 0 and i < 4 else SKIN_SH)
    for x in (-5, -4, 3, 4):                                                 # ojos amarillos que brillan
        for y in (73, 74):
            z = M.front(x, y)
            if z is not None: M.V[(x, y, z)] = [H, EYE, 1]
    for (x, y, z), v in M.V.items():                                         # manchas de moho
        if v[1] in (SKIN, SKIN_SH) and M.noise(x, y, z, 5.0) > 0.72: v[1] = MOLD
    piv = cu.hunch(M, k=0.3, head_drop=6)
    cu.finish(M, 'necrofago', {SKIN: 'piel', SKIN_SH: 'piel', MOLD: 'piel', BELLY: 'piel'},
              flat=(NOSE, MOUTH, TOOTH, CLAW, HOOF, EYE, EAR_IN), b=-2, ax=cu.ARM_X, extra_pivots=piv,
              roughness=0.5, specular=0.45)


def lienzo():
    """Caballete y lienzo (voxels de 1/32 m, como el atrezo): tres patas, el travesaño, el lienzo
    con su bastidor y la pintura. Partes: `body` (todo) y `canvas` (el lienzo, que tiembla al
    recibir golpes y se rompe)."""
    from voxlib import Model
    WOOD = (0.45, 0.28, 0.14); WOOD_SH = (0.34, 0.21, 0.10)
    FRAME = (0.62, 0.50, 0.34); CLOTH = (0.80, 0.76, 0.66)
    M = Model(seed=1926 + 22)
    for (x0, z0, x1, z1) in ((-9, 2, -5, -1), (9, 2, 5, -1), (0, -10, 0, -3)):    # tres patas inclinadas
        for y in range(0, 52):
            t = y / 51.0
            x = round(x0 + (x1 - x0) * t); z = round(z0 + (z1 - z0) * t)
            for dx in (0, 1):
                M.put(x + dx, y, z, 'body', WOOD if dx == 0 else WOOD_SH)
    for x in range(-10, 12): M.put(x, 18, 2, 'body', WOOD); M.put(x, 18, 3, 'body', WOOD_SH)   # el travesaño
    # el lienzo: 24 de ancho y 30 de alto, inclinado como las patas, mirando hacia +Z
    PAINT = {'k': (0.07, 0.06, 0.06), 'r': (0.45, 0.10, 0.08), 'R': (0.62, 0.18, 0.10),
             'g': (0.16, 0.24, 0.17), 'G': (0.26, 0.34, 0.22), 'o': (0.55, 0.42, 0.20),
             'y': (0.95, 0.78, 0.30), 'w': (0.80, 0.74, 0.62), 'b': (0.20, 0.16, 0.12)}
    art = [
        'gggggGGGGggggggggGGGGggg',
        'ggGGGggggkkkkkkggggGGggg',
        'gGGgggkkkkkkkkkkkkgggGgg',
        'ggggkkkkkkkkkkkkkkkkgggg',
        'gggkkkkkkbbbbbbkkkkkkggg',
        'ggkkkkkbbbbbbbbbbkkkkkgg',
        'gkkkkkbbbbbbbbbbbbkkkkkg',
        'gkkkkbbbbbwwwbbbbbbkkkkg',
        'kkkkbbbbbwwwwwbbbbbbkkkk',
        'kkkkbbbbbwywywbbbbbbkkkk',
        'kkkbbbbbbwwwwwbbbbbbbkkk',
        'kkkbbbbbbbwRwbbbbbbbbkkk',
        'kkkbbbbbwwwwwwwbbbbbbkkk',
        'kkkbbbbwwbwwwbwwbbbbbkkk',
        'kkkbbbwwbbwwwbbwwbbbbkkk',
        'kkkbbwwbbbwwwbbbwwbbbkkk',
        'kkbbbwbbbbwwwbbbbwbbbbkk',
        'kkbbbRbbbbwwwbbbbRbbbbkk',
        'kkbbbbbbbwwbwwbbbbbbbbkk',
        'kbbbbbbbwwbbbwwbbbbbbbbk',
        'kbbbbbbbwbbbbbwbbbbbbbbk',
        'rbbbbbbbwbbbbbwbbbbbbbbr',
        'rrbbbbbwwbbbbbwwbbbbbbrr',
        'rrrbbbbbbbbbbbbbbbbbbrrr',
        'RrrrrbbbbbbbbbbbbbbrrrrR',
        'oRRrrrrrrrrrrrrrrrrrrRRo',
        'ooRRRrrrrrrrrrrrrrrRRRoo',
        'oooooRRRRRRRRRRRRRRooooo',
    ]
    H_ = len(art); W = len(art[0])
    y0 = 20
    for i, row in enumerate(art):
        y = y0 + H_ - 1 - i
        z = 3 + round((y - y0) * -0.12)
        for j, ch in enumerate(row):
            x = j - W // 2
            M.put(x, y, z + 1, 'canvas', PAINT[ch])
            M.put(x, y, z, 'canvas', CLOTH)
    for i in range(-1, H_ + 1):                                              # el bastidor, por detrás
        y = y0 + i
        z = 3 + round((y - y0) * -0.12) - 1
        for x in (-W // 2 - 1, W // 2):
            M.put(x, y, z + 1, 'canvas', FRAME)
    for x in range(-W // 2 - 1, W // 2 + 1):
        for y in (y0 - 1, y0 + H_):
            M.put(x, y, 3 + round((y - y0) * -0.12), 'canvas', FRAME)
    n = M.export('models/lienzo.json', {'body': [0, 0, 0], 'canvas': [0, y0, 3]}, jitter=0.0,
                 pivots_in_voxels=True, roughness=0.85, specular=0.2)
    print('lienzo', n, 'voxels')


def ward():
    SKIN = (0.87, 0.78, 0.70); SKIN_SH = (0.77, 0.67, 0.60); EAR_IN = (0.64, 0.50, 0.43)
    COAT = (0.16, 0.28, 0.20); COAT_SH = (0.11, 0.19, 0.14); COAT_LT = (0.23, 0.37, 0.27)
    VEST = (0.70, 0.57, 0.34); VEST_SH = (0.58, 0.46, 0.26)
    JABOT = (0.92, 0.90, 0.84); JABOT_SH = (0.78, 0.76, 0.70)
    BREECH = (0.20, 0.15, 0.12); STOCK = (0.84, 0.82, 0.76); SHOE = (0.08, 0.07, 0.07)
    BRASS = (0.78, 0.62, 0.28); SILVER = (0.78, 0.80, 0.84)
    HAIR = (0.36, 0.24, 0.15); HAIR_SH = (0.28, 0.18, 0.11); RIBBON = (0.06, 0.06, 0.07)
    BROW = (0.30, 0.20, 0.13); IRIS = (0.42, 0.48, 0.44); HOLLOW = (0.74, 0.64, 0.58)
    MOUTH = (0.66, 0.47, 0.44)
    GLASS = (0.50, 0.58, 0.64); SALT = (0.58, 0.68, 0.90); CORK = (0.50, 0.36, 0.22)
    B = -1
    M = cu.new(1928)
    top = cu.shoes(M, SHOE, SOLE)
    for (x, y, z), v in M.V.items():                                         # hebillas de plata en el empeine
        if v[1] == SHOE and y == top - 1 and z >= 4 and abs(abs(x + 0.5) - 5) <= 1.0: v[1] = SILVER
    cu.legs(M, STOCK, bottom=top, thigh=BREECH)                              # medias blancas y calzón
    for (x, y, z), v in M.V.items():                                         # el calzón baja hasta la rodilla
        if v[1] == STOCK and y >= 25: v[1] = BREECH
    cu.torso(M, COAT, b=B, bottom=16)
    cu.skirt(M, COAT, 22, top=38, b=B, flare=3, depth=12)                    # levita de faldones, a la rodilla
    cu.opening(M, 22, 61, 7, 14, COAT_SH)                                    # abierta: el borde, más oscuro
    cu.opening(M, 33, 61, 9, 12, VEST)                                       # chaleco largo de ante
    for y in range(33, 61):
        cu.front(M, -1, y, VEST_SH) if y % 4 == 1 else None                  # botones del chaleco
    for y in (30, 34, 38, 42, 46, 50, 54):                                   # botones de latón de la levita
        cu.front(M, -7, y, BRASS); cu.front(M, 6, y, BRASS)
    for (x0, y) in ((-9, 34), (4, 34)):                                      # carteras de los bolsillos
        for x in range(x0, x0 + 5): cu.front(M, x, y, COAT_LT); cu.front(M, x, y - 1, COAT_SH)
    # la chorrera: encaje blanco en volantes que cae del cuello sobre el chaleco (algo de relieve)
    jab = ['..jjjj..',     # 61
           '.jJjjJj.',     # 60
           '.jjJJjj.',     # 59
           '..jjjj..',     # 58
           '.jJjjJj.',     # 57
           '..jJJj..',     # 56
           '..jjjj..',     # 55
           '...JJ...',     # 54
           '...jj...']     # 53
    for i, row in enumerate(jab):
        for j, ch in enumerate(row):
            if ch != '.': cu.front(M, j - 4, 61 - i, JABOT if ch == 'j' else JABOT_SH, dz=1)
    slab(M, T, COAT, 60, 64, 0, -1.5, 13, 12, 9, 8, ch=1)                    # cuello alto de la levita, detrás
    # el frasco de las sales, colgado del cinto a su derecha: cristal, polvo azulado y corcho
    for y in range(36, 42):
        for x in (-11, -10):
            cu.front(M, x, y, GLASS if y in (36, 41) else SALT, dz=1)
    cu.front(M, -11, 42, CORK, dz=1); cu.front(M, -10, 42, CORK, dz=1)
    for (x, y, z), v in list(M.V.items()):
        if v[1] == SALT: M.V[(x, y, z)] = [v[0], SALT, 1]
    cu.neck(M, SKIN)
    cu.arms(M, COAT, SKIN, b=B, cuff=COAT_LT, cuff_wide=True)                # vueltas anchas en las mangas
    cu.head(M, SKIN, SKIN_SH, nose=False, r=3, rb=3)
    cu.face_art(M, 77, [                   # en relieve
        '..........bbbb..',                # 77: la ceja izquierda, más alta (una mirada que no es suya)
        '..bbbb..........',                # 76: la otra, recta
        '................',
        '.......nn.......',                # 74: nariz recta y fina
        '.......nn.......',
        '.......nn.......',
        '.......sn.......',                # 71
    ], {'b': BROW, 'n': SKIN, 's': SKIN_SH}, dz=1)
    cu.face_art(M, 74, [                   # pintado: ojos grises y fríos, mejillas hundidas, media sonrisa
        '..wpiw....wipw..',                # 74
        '..wppw....wppw..',                # 73
        '................',
        '.h............h.',                # 71: mejillas hundidas
        '.h............h.',
        '...........m....',                # 69: la comisura que sube: media sonrisa
        '......mmmmm.....',                # 68
    ], {'w': cu.EYE_W, 'p': cu.EYE, 'i': IRIS, 'h': HOLLOW, 'm': MOUTH})
    cu.ear_holes(M, EAR_IN)
    # pelo peinado hacia atrás y recogido en una coleta corta con lazo negro, a la antigua
    cu.hair_back(M, SKIN, HAIR, top=200, bottom=68, neck=False)
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == SKIN and y >= 78: v[1] = HAIR
    cu.sideburns(M, HAIR, 73, 79)
    cu.hair_over_ears(M, SKIN, HAIR, 76, 79)
    slab(M, H, RIBBON, 66, 69, -0.5, -8.5, 4, 4, 2, 2, ch=0)                 # el lazo
    slab(M, H, HAIR, 58, 66, -0.5, -8.5, 3, 2, 2, 2, ch=0)                   # la coleta
    for (x, z) in {(k[0], k[2]) for k in M.V if k[1] >= 79}:                 # marcas del peine, hacia atrás
        y = M.top(x, z)
        if y is not None and y >= 80 and x % 3 == 0 and M.V[(x, y, z)][1] == HAIR: M.V[(x, y, z)][1] = HAIR_SH
    cu.seams(M, (COAT,))
    cu.finish(M, 'ward', {COAT: 'lana', COAT_SH: 'lana', COAT_LT: 'lana', VEST: 'lana', VEST_SH: 'lana',
                          BREECH: 'lana', STOCK: 'punto', SHOE: 'cuero', SOLE: 'cuero', HAIR: 'pelo',
                          HAIR_SH: 'pelo', SKIN: 'piel', SKIN_SH: 'piel', JABOT: 'lona', JABOT_SH: 'lona'},
              flat=(BRASS, SILVER, RIBBON, BROW, IRIS, HOLLOW, MOUTH, EAR_IN, GLASS, SALT, CORK),
              b=B, skirt=True)


WHO = {'pickman': pickman, 'necrofago': necrofago, 'lienzo': lienzo, 'ward': ward}

if __name__ == '__main__':
    for name in (sys.argv[1:] or list(WHO)):
        WHO[name]()
