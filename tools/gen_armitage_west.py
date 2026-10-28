"""Los dos personajes de la tienda que faltaban (fase 5, hito 5.5). Estilo 4 (tools/cuerpo.py).

  armitage  Profesor Henry Armitage, bibliotecario de la Universidad de Miskatonic (*El horror de
            Dunwich*): anciano alto, pelo y barba blancos, gafas de montura dorada, levita gris
            marengo larga, chaleco, pajarita negra, y un libro bajo el brazo izquierdo
  west      Herbert West (*Herbert West, reanimador*): joven, menudo, rubio y muy pálido, gafas
            redondas, bata de laboratorio manchada abierta sobre un traje oscuro, guantes de
            goma y una jeringa del reactivo verde que brilla en el bolsillo del pecho
Colores separados por valor: Armitage gris oscuro y blanco; West blanco sucio y negro.
Uso: python tools/gen_armitage_west.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, T, H

SKIN = (0.86, 0.70, 0.58); SKIN_SH = (0.77, 0.60, 0.50); CHEEK = (0.85, 0.60, 0.52)
EAR_IN = (0.64, 0.47, 0.38)
SOLE = (0.10, 0.08, 0.07)


def armitage():
    COAT = (0.24, 0.25, 0.28); COAT_SH = (0.18, 0.19, 0.21); VEST = (0.36, 0.30, 0.22)
    SHIRT = (0.86, 0.85, 0.80); TIE = (0.08, 0.08, 0.09); TROUSER = (0.22, 0.22, 0.24)
    SHOE = (0.12, 0.10, 0.09); HAIR = (0.88, 0.88, 0.86); HAIR_SH = (0.72, 0.72, 0.70); GOLD = (0.78, 0.62, 0.28)
    IRIS = (0.14, 0.19, 0.27)
    BOOK = (0.36, 0.12, 0.10); PAGE = (0.86, 0.82, 0.70)
    B = -1
    M = cu.new(1928)
    top = cu.shoes(M, SHOE, SOLE)
    cu.legs(M, TROUSER, bottom=top)
    cu.torso(M, COAT, b=B, bottom=24)
    cu.skirt(M, COAT, 18, top=36, b=B, flare=2, depth=12)                  # faldones de la levita
    cu.opening(M, 40, 61, 2, 9, COAT_SH)
    cu.opening(M, 40, 61, 1, 7, VEST)
    cu.opening(M, 53, 61, 1, 4, SHIRT)
    for y in (42, 46, 50): cu.front(M, -1, y, GOLD)                          # botones del chaleco
    for x in range(-3, 3): cu.front(M, x, 44, GOLD)                          # leontina
    slab(M, T, SHIRT, 60, 63, 0, 0.5, 11, 10, 10, 9, ch=1)
    for x in (-2, -1, 0, 1): cu.front(M, x, 60, TIE, dz=1)                   # pajarita
    for x in (-3, 2): cu.front(M, x, 61, TIE, dz=1); cu.front(M, x, 59, TIE, dz=1)
    cu.neck(M, SKIN)
    cu.arms(M, COAT, SKIN, b=B, cuff=SHIRT, cuff_wide=False)
    slab(M, 'fore_l', BOOK, 28, 38, -15, 4, 3, 3, 9, 9, ch=0)               # libro bajo el brazo
    slab(M, 'fore_l', PAGE, 29, 37, -12.5, 4, 1, 1, 8, 8, ch=0)
    # cabeza rehecha el 23-10-2026 como la de Legrasse (referencias tools/local/ref_cabeza_armitage_*):
    # cejas blancas pobladas y caídas, ojos con iris tras unas gafas redondas de oro con patillas,
    # nariz larga y bigote sobre la barba
    cu.head(M, SKIN, SKIN_SH, nose=False, r=3, rb=3)
    cu.beard(M, HAIR)
    cu.face_art(M, 76, [                   # en relieve
        '...bbbb..bbbb...',                # 76: cejas blancas pobladas...
        '.bbbb......bbbb.',                # ...que caen por fuera
        '................',
        '.......nn.......',                # 73: tabique
        '.......nn.......',
        '......snns......',                # 71: punta de la nariz
        '......snns......',
        '....mmmmmmmm....',                # 69: bigote, con algo de sombra sobre la barba
        '...mm......mm...',
    ], {'b': HAIR, 'n': SKIN, 's': SKIN_SH, 'm': HAIR_SH}, dz=1)
    cu.face_art(M, 74, [                   # pintado (después del relieve: el puente va sobre la nariz)
        '..gggg....gggg..',                # 74: gafas redondas
        '.gwppwggggwppwg.',                # 73: ojos dentro, y el puente
        '.gwiiwg..gwiiwg.',
        '..gggg....gggg..',
        '..cc........cc..',                # 70: mejillas
    ], {'g': GOLD, 'w': cu.EYE_W, 'p': cu.EYE, 'i': IRIS, 'c': CHEEK})
    for (x, y, z), v in M.V.items():       # patillas de las gafas, por los lados hasta la oreja
        if v[0] == H and y == 73 and abs(x + 0.5) >= 7.5 and 2 <= z <= 5: v[1] = GOLD
    cu.ear_holes(M, EAR_IN)
    cu.hair_back(M, SKIN, HAIR, top=80)
    slab(M, H, HAIR, 74, 79, -7.5, -0.5, 2, 2, 12, 12, ch=0)                 # pelo blanco a los lados (calvo arriba)
    slab(M, H, HAIR, 74, 79, 7, -0.5, 2, 2, 12, 12, ch=0)
    cu.seams(M, (COAT,))
    cu.finish(M, 'armitage', {COAT: 'lana', COAT_SH: 'lana', VEST: 'lana', TROUSER: 'lana', SHOE: 'cuero',
                              SOLE: 'cuero', HAIR: 'pelo', HAIR_SH: 'pelo', SKIN: 'piel', SKIN_SH: 'piel', BOOK: 'cuero'},
              flat=(CHEEK, GOLD, TIE, PAGE, IRIS, EAR_IN), b=B, skirt=True)


def west():
    LAB = (0.82, 0.82, 0.76); LAB_SH = (0.66, 0.66, 0.60); STAIN = (0.46, 0.50, 0.30)
    SUIT = (0.12, 0.12, 0.14); SHIRT = (0.86, 0.85, 0.80); TIE = (0.30, 0.10, 0.10)
    SHOE = (0.12, 0.10, 0.09); GLOVE = (0.62, 0.48, 0.34)
    PALE = (0.90, 0.80, 0.72); PALE_SH = (0.80, 0.70, 0.62)
    HAIR = (0.62, 0.48, 0.26); HAIR_SH = (0.52, 0.39, 0.20); BROW = (0.50, 0.38, 0.20)
    FRAME = (0.16, 0.16, 0.18); SERUM = (0.40, 1.0, 0.45); GLASS = (0.70, 0.80, 0.80)
    IRIS = (0.34, 0.44, 0.50); MOUTH = (0.72, 0.54, 0.50)
    B = -2
    M = cu.new(1922)
    top = cu.shoes(M, SHOE, SOLE)
    cu.legs(M, SUIT, bottom=top)
    cu.torso(M, LAB, b=B, bottom=20)
    cu.skirt(M, LAB, 14, top=36, b=B, flare=2, depth=12)                     # bata larga
    cu.opening(M, 14, 61, 2, 8, SUIT)                                        # abierta sobre el traje
    cu.opening(M, 50, 61, 1, 4, SHIRT)
    for y in range(50, 60): cu.front(M, -1, y, TIE); cu.front(M, 0, y, TIE)
    for (x, y, z), v in list(M.V.items()):                                   # manchas en la bata
        if v[1] == LAB and M.noise(x, y, z, 3.0) > 0.78: M.V[(x, y, z)] = [v[0], STAIN, 0]
    for y in range(52, 58):                                                  # jeringa en el bolsillo del pecho
        cu.front(M, 6, y, GLASS, dz=1)
        if 53 <= y <= 56: cu.front(M, 6, y, SERUM, dz=2)
    for (x, y, z), v in list(M.V.items()):
        if v[1] == SERUM: M.V[(x, y, z)] = [v[0], SERUM, 1]
    cu.neck(M, PALE)
    cu.arms(M, LAB, GLOVE, b=B, cuff=LAB_SH)
    # cabeza rehecha el 23-10-2026 como la de Legrasse (referencias tools/local/ref_cabeza_west_*):
    # gafas redondas negras con patillas, ojos claros y fríos (el iris claro da la mirada de
    # desapego), cejas finas y rectas, nariz estrecha, boca fina y pelo rubio peinado hacia atrás
    # con las marcas del peine
    cu.head(M, PALE, PALE_SH, nose=False, r=3, rb=3)
    cu.face_art(M, 75, [                   # en relieve
        '..bbbb....bbbb..',                # 75: cejas finas y rectas
        '................',
        '.......nn.......',                # 73: tabique
        '.......nn.......',
        '.......nn.......',
        '......snns......',                # 70: punta de la nariz
    ], {'b': BROW, 'n': PALE, 's': PALE_SH}, dz=1)
    cu.face_art(M, 74, [                   # pintado (después del relieve: el puente va sobre la nariz)
        '..ffff....ffff..',                # 74: gafas redondas
        '.fwppwffffwppwf.',                # 73: ojos dentro, y el puente
        '.fwiiwf..fwiiwf.',
        '..ffff....ffff..',
        '................',
        '................',
        '................',
        '......oooo......',                # 67: boca fina
    ], {'f': FRAME, 'w': cu.EYE_W, 'p': cu.EYE, 'i': IRIS, 'o': MOUTH})
    for (x, y, z), v in M.V.items():       # patillas de las gafas
        if v[0] == H and y == 73 and abs(x + 0.5) >= 7.5 and 2 <= z <= 5: v[1] = FRAME
    cu.ear_holes(M, EAR_IN)
    # pelo rubio peinado hacia atrás, pegado a la cabeza (encima, en bloques, parecía un casco):
    # se pinta la cabeza desde la fila 78 y se le da algo de volumen por arriba
    cu.hair_back(M, PALE, HAIR, top=82)
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == PALE and y >= 78: v[1] = HAIR
    slab(M, H, HAIR, 81, 82, 0, -1, 8, 8, 9, 9, ch=1)
    cu.sideburns(M, HAIR, 74, 78)
    cu.hair_over_ears(M, PALE, HAIR, 75, 78)
    for (x, z) in {(k[0], k[2]) for k in M.V if k[1] >= 78}:                 # marcas del peine, de delante atrás
        y = M.top(x, z)
        if y is not None and y >= 79 and x % 3 == 0 and M.V[(x, y, z)][1] == HAIR: M.V[(x, y, z)][1] = HAIR_SH
    cu.seams(M, (LAB,))
    cu.finish(M, 'west', {LAB: 'lona', LAB_SH: 'lona', SUIT: 'lana', SHOE: 'cuero', SOLE: 'cuero',
                          HAIR: 'pelo', HAIR_SH: 'pelo', PALE: 'piel', PALE_SH: 'piel', GLOVE: 'cuero'},
              flat=(FRAME, SERUM, GLASS, TIE, STAIN, BROW, IRIS, MOUTH, EAR_IN), b=B)


armitage()
west()
