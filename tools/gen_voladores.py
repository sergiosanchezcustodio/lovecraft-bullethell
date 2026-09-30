"""Compañeros que vuelan (D-36): Mini-Byakhee, cuervo de Arkham, polilla de Leng y gaviota de
Innsmouth. Estilo 4 (tramos de caras planas, detalles pintados), a 48 voxels por metro; miran
hacia +Z. Las alas van abiertas en horizontal y aletean girando en su hombro.
Partes: body, head, wing_l, wing_r (anim_volador.gd; la altura de vuelo la pone Pet).
Uso: python tools/gen_voladores.py [byakhee|cuervo|polilla|gaviota]
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import slab, rslab, new
import materiales

B, H = 'body', 'head'


def face_fn(M, part=H):
    def face(x, y, c, glow=0, dz=0):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z + dz, part, c, glow)
    return face


def wing(M, part, s, col, y, x0, span, z0, z1, taper=0.5, tip=None, rim=None):
    """Ala horizontal de `span` voxels hacia fuera desde x0 (s = -1 izquierda, 1 derecha),
    de 2 voxels de grueso, que se estrecha de z0..z1 a la mitad en la punta."""
    for i in range(span):
        t = i / max(span - 1, 1)
        za = z0 + (z1 - z0) * 0.0
        zb = z1 - (z1 - z0) * taper * t
        zc = z0 + (z1 - z0) * taper * t * 0.4
        for z in range(int(round(zc)), int(round(zb))):
            for dy in (0, 1):
                c = col
                if tip is not None and t > 0.72: c = tip
                if rim is not None and z == int(round(zc)): c = rim
                M.put(s * (x0 + i) - (1 if s < 0 else 0), y + dy, z, part, c)


def byakhee():
    """Murciélago alienígena con cara de pocos amigos: cuerpo de insecto negro verdoso con
    placas, cabeza de murciélago con orejas de punta y ceño, ojos rojos brillantes, colmillos,
    alas membranosas de murciélago (dedos oscuros) y una cola de aguijón."""
    SKIN = (0.20, 0.24, 0.22); PLATE = (0.30, 0.34, 0.28); MEMB = (0.32, 0.22, 0.30)
    FINGER = (0.14, 0.12, 0.14); EYE = (1.0, 0.22, 0.12); FANG = (0.90, 0.88, 0.78)
    M = new(6101)
    rslab(M, B, SKIN, 0, 9, 0, 0, 9, 14, r=3, rt=3, rb=3)
    for (x, y, z), v in M.V.items():
        if v[0] == B and y >= 6 and z % 3 == 0: v[1] = PLATE                  # placas del lomo
    slab(M, B, SKIN, 2, 5, 0, -10, 3, 1, 6, 6, ch=0)                          # cola de aguijón
    slab(M, B, FANG, 2, 4, 0, -14, 1, 1, 2, 2, ch=0)
    rslab(M, H, SKIN, 3, 12, 0, 9, 10, 8, r=3, rt=3, rb=2)
    for s in (-1, 1):
        slab(M, H, SKIN, 12, 17, 3 * s, 8, 3, 0.5, 2, 1, ch=0)                 # orejas de punta
    face = face_fn(M)
    for x in (-3, -2, 1, 2): face(x, 8, EYE, 1)
    for x in (-3, 2): face(x, 9, FINGER)                                       # ceño
    for x in (-2, 1): face(x, 10, FINGER)
    for x in (-2, 1): face(x, 4, FANG); face(x, 5, FANG)                       # colmillos
    for x in (-1, 0): face(x, 5, FINGER)
    for part, s in (('wing_l', -1), ('wing_r', 1)):
        wing(M, part, s, MEMB, 6, 4, 18, -5, 6, taper=0.6)
        for (x, y, z), v in M.V.items():                                     # dedos de la membrana
            if v[0] == part and (abs(x) in (8, 13, 18) or z == 5): v[1] = FINGER
    materiales.texturize(M, {SKIN: 'piel', MEMB: 'piel'})
    piv = {'body': [0, 0, 0], 'head': [0, 6, 6], 'wing_l': [-4, 7, 0], 'wing_r': [4, 7, 0]}
    return M, piv, (0.5, 0.5)


def cuervo():
    """Cuervo ladrón: negro con brillo azul violáceo, pico grueso y negro, ojo pequeño que
    brilla, cola en abanico, patas grises, y una moneda dorada en el pico."""
    BLACK = (0.10, 0.10, 0.13); SHEEN = (0.20, 0.20, 0.32); BEAK = (0.16, 0.15, 0.16)
    EYE = (0.95, 0.85, 0.55); LEG = (0.30, 0.30, 0.32); COIN = (1.0, 0.80, 0.30)
    M = new(6202)
    for s in (-1, 1): slab(M, B, LEG, 0, 3, 1.5 * s, 1, 1, 1, 2, 2, ch=0)
    rslab(M, B, BLACK, 3, 11, 0, 0, 8, 13, r=3, rt=3, rb=3)
    slab(M, B, BLACK, 6, 8, 0, -10, 7, 8, 7, 7, ch=1)                          # cola en abanico
    for (x, y, z), v in M.V.items():
        if v[0] == B and v[1] == BLACK and y >= 9: v[1] = SHEEN
    rslab(M, H, BLACK, 9, 17, 0, 7, 7, 7, r=2.5, rt=2.5, rb=2)
    slab(M, H, BEAK, 11, 14, 0, 12.5, 3, 2, 4, 3, ch=0)                        # pico
    slab(M, H, COIN, 10, 13, 0, 14.5, 3, 3, 1, 1, ch=0)                        # moneda robada
    face = face_fn(M)
    for x in (-3, 2):
        z = max(k for k in range(-20, 20) if (x, 14, k) in M.V)
        for xx in (x - 1 if x < 0 else x + 1,):
            M.put(xx, 14, 8, H, EYE, 1)                                      # ojillos a los lados
    for part, s in (('wing_l', -1), ('wing_r', 1)):
        wing(M, part, s, BLACK, 8, 4, 14, -6, 5, taper=0.5, tip=SHEEN)
    materiales.texturize(M, {BLACK: 'pelo', SHEEN: 'pelo'})
    piv = {'body': [0, 0, 0], 'head': [0, 10, 5], 'wing_l': [-4, 9, 0], 'wing_r': [4, 9, 0]}
    return M, piv, (0.9, 0.25)


def polilla():
    """Bonita... hasta que abre las alas: cuerpo peludo crema, antenas plumosas, alas grandes
    color arena por fuera con un borde lila, y en el centro de cada ala un ojo enorme, oscuro
    y violeta que brilla (lo que asusta al abrirlas)."""
    FUZZ = (0.86, 0.80, 0.66); FUZZ_D = (0.66, 0.58, 0.46); WING = (0.78, 0.70, 0.56)
    RIM = (0.62, 0.48, 0.72); EYE_O = (0.28, 0.12, 0.34); EYE_I = (0.85, 0.40, 1.0)
    PUPIL = (0.05, 0.03, 0.06); ANT = (0.40, 0.32, 0.26)
    M = new(6303)
    rslab(M, B, FUZZ, 0, 8, 0, -2, 6, 14, r=2.5, rt=2.5, rb=2.5)
    for (x, y, z), v in M.V.items():
        if v[0] == B and z % 3 == 0 and z < 0: v[1] = FUZZ_D                    # anillos del abdomen
    rslab(M, H, FUZZ, 2, 9, 0, 7, 7, 6, r=2.5, rt=2.5, rb=2)
    face = face_fn(M)
    for x in (-3, 2):
        for y in (5, 6): face(x, y, PUPIL)
    for s in (-1, 1):                                                          # antenas plumosas
        for i in range(6):
            M.put(s * (1 + i // 2) - (1 if s < 0 else 0), 9 + i, 8 + i // 2, H, ANT)
            M.put(s * (2 + i // 2) - (1 if s < 0 else 0), 9 + i, 8 + i // 2, H, ANT)
    for part, s in (('wing_l', -1), ('wing_r', 1)):
        wing(M, part, s, WING, 5, 3, 17, -8, 9, taper=0.3, rim=RIM)
        cx, cz = s * 11 - (1 if s < 0 else 0), 1
        for (x, y, z), v in M.V.items():
            if v[0] != part: continue
            d = ((x - cx) ** 2 + (z - cz) ** 2) ** 0.5
            if y == 6 and d < 1.5: v[1] = PUPIL
            elif y == 6 and d < 3.0: v[1] = EYE_I; v[2] = 1
            elif y == 6 and d < 4.5: v[1] = EYE_O
            if abs(x) >= 18 or z >= 8: v[1] = RIM
    materiales.texturize(M, {FUZZ: 'borreguillo', WING: 'lana'})
    piv = {'body': [0, 0, 0], 'head': [0, 5, 5], 'wing_l': [-3, 6, 0], 'wing_r': [3, 6, 0]}
    return M, piv, (0.9, 0.25)


def gaviota():
    """Carroñera y chillona: blanca con el manto gris, puntas de las alas negras con motas
    blancas, pico amarillo con la mancha roja, ojo amarillo de mala uva y patas rosadas."""
    WHITE = (0.92, 0.92, 0.90); GREY = (0.62, 0.66, 0.72); BLACK = (0.12, 0.12, 0.14)
    BEAK = (0.98, 0.82, 0.22); RED = (0.85, 0.18, 0.12); EYE = (0.95, 0.85, 0.30)
    PUPIL = (0.05, 0.05, 0.05); LEG = (0.88, 0.62, 0.58)
    M = new(6404)
    for s in (-1, 1): slab(M, B, LEG, 0, 3, 1.5 * s, 1, 1, 1, 2, 2, ch=0)
    rslab(M, B, WHITE, 3, 11, 0, 0, 9, 15, r=3, rt=3, rb=3)
    slab(M, B, WHITE, 6, 9, 0, -10, 5, 5, 5, 5, ch=1)                          # cola
    for (x, y, z), v in M.V.items():
        if v[0] == B and y >= 9 and z < 5: v[1] = GREY                         # manto gris
        if v[0] == B and z <= -12: v[1] = BLACK
    rslab(M, H, WHITE, 9, 17, 0, 8, 7, 7, r=2.5, rt=2.5, rb=2)
    slab(M, H, BEAK, 11, 13, 0, 13, 2, 2, 4, 4, ch=0)                          # pico
    M.put(0, 11, 14, H, RED); M.put(-1, 11, 14, H, RED)                         # mancha roja
    for s in (-1, 1):
        x = 3 if s > 0 else -4
        M.put(x, 14, 9, H, EYE); M.put(x, 14, 10, H, PUPIL)
        M.put(x, 15, 10, H, GREY)                                             # ceño de mala uva
    for part, s in (('wing_l', -1), ('wing_r', 1)):
        wing(M, part, s, GREY, 8, 4, 18, -5, 5, taper=0.5, tip=BLACK)
        for (x, y, z), v in M.V.items():
            if v[0] == part and v[1] == BLACK and abs(x) == 20 and y == 9: v[1] = WHITE   # motas
    materiales.texturize(M, {WHITE: 'pelo', GREY: 'pelo'})
    piv = {'body': [0, 0, 0], 'head': [0, 10, 6], 'wing_l': [-4, 9, 0], 'wing_r': [4, 9, 0]}
    return M, piv, (0.9, 0.25)


MODELS = {'byakhee': byakhee, 'cuervo': cuervo, 'polilla': polilla, 'gaviota': gaviota}
for name in (sys.argv[1:] or MODELS):
    M, piv, (rough, spec) = MODELS[name]()
    n = M.export('models/%s.json' % name, piv, jitter=0.0, pivots_in_voxels=True, roughness=rough, specular=spec)
    print(name, n, 'voxels')
