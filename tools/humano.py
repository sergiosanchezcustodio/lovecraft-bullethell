"""Base común de los personajes humanos a bloques limpios (Dyer es el modelo de referencia).

Mismas proporciones y pivotes que Dyer (1,72 m, 32 voxels por metro, mirando hacia +Z), así
que todos usan las animaciones de `scripts/anim/anim_humano.gd`. Cada generador pone encima
su ropa, su sombrero y su cara. Coordenadas en voxels.

Piezas:
- legs(): perneras, calzado y suela.
- torso(): bloque del torso con hombros caídos y aristas biseladas.
- arms(): mangas, puño y manos (o guantes).
- head(): cabeza de piel.
- face(): ojos, cejas, nariz y boca pintados en el plano frontal (sin relieve).
- hair_back(): pelo en la nuca y detrás de las orejas.
"""
from voxlib import Model

PIVOTS = {'torso': [0, 24, 0], 'head': [0, 43, 0],
          'arm_l': [-11.5, 40, 0], 'arm_r': [11.5, 40, 0],
          'leg_l': [-4, 24, 0], 'leg_r': [4, 24, 0]}
EYE = (0.10, 0.08, 0.07)
H = 'head'
T = 'torso'


def legs(M: Model, trouser, shoe, sole, boot_top=2):
    """Perneras de 6×6 voxels y calzado. boot_top: altura de la caña (2 = zapato bajo)."""
    for s, p in ((-1, 'leg_l'), (1, 'leg_r')):
        x0, x1 = (-7, -1) if s < 0 else (1, 7)
        M.vbox(x0, boot_top, -3, x1, 25, 3, p, trouser)
        M.vbox(x0, 2, -3, x1, boot_top if boot_top > 2 else 3, 3, p, shoe)
        M.vbox(x0, 0, -3, x1, 2, 5, p, shoe)                 # pie
        M.vbox(x0, 0, -3, x1, 1, 5, p, sole)
        M.bevel(p, x0, x1, -3, 3, 2, 25)


def torso(M: Model, col, half=9, y0=22, y1=42):
    """Bloque del torso (de -half a half) con los hombros caídos."""
    M.vbox(-half, y0, -5, half, y1, 5, T, col)
    M.bevel(T, -half, half, -5, 5, y0, y1)
    for y, cut in ((y1 - 2, 1), (y1 - 1, 2)):
        for x in list(range(-half, -half + cut)) + list(range(half - cut, half)):
            for z in range(-5, 5):
                M.V.pop((x, y, z), None)


def arms(M: Model, sleeve, cuff, hand, half=9, cuff_h=2):
    """Mangas desde el hombro (y 41) hasta el puño, y manos."""
    for s, p in ((-1, 'arm_l'), (1, 'arm_r')):
        x0, x1 = (-half - 5, -half) if s < 0 else (half, half + 5)
        M.vbox(x0, 27, -3, x1, 41, 3, p, sleeve)
        M.vbox(x0, 25, -3, x1, 25 + cuff_h, 3, p, cuff)
        M.vbox(x0, 21, -2, x1, 25, 3, p, hand)
        M.bevel(p, x0, x1, -3, 3, 25, 41)
        M.bevel(p, x0, x1, -2, 3, 21, 25)
        for z in range(-3, 3):
            M.V.pop((x1 - 1 if s > 0 else x0, 40, z), None)


def head(M: Model, skin):
    M.vbox(-5, 43, -5, 5, 51, 5, H, skin)
    M.bevel(H, -5, 5, -5, 5, 43, 51)


def paint_face(M: Model, x, y, col):
    """Un píxel de la cara, en el plano frontal de la cabeza (z = 4)."""
    M.V[(x, y, 4)] = [H, col, 0]


def face(M: Model, brow, skin_sh, mouth, eye=EYE, eye_y=48):
    """Cara básica, simétrica respecto a x = -0,5: cejas, ojos, nariz y boca."""
    for x in (-3, -2, 1, 2): paint_face(M, x, eye_y + 1, brow)
    for x in (-2, 1): paint_face(M, x, eye_y, eye)
    for x in (-1, 0): paint_face(M, x, eye_y - 1, skin_sh)
    for x in (-1, 0): paint_face(M, x, eye_y - 3, mouth)


def hair_back(M: Model, skin, hair, top=50):
    """Pelo en la nuca y detrás de las orejas (debajo del sombrero)."""
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == skin and y < top and (z <= -3 or (abs(x + 0.5) >= 4.5 and z < 1)):
            v[1] = hair


def export(M: Model, name, half=9):
    """Exporta con los pivotes comunes. half: medio ancho del torso (los hombros van 2,5 más allá)."""
    pv = {k: list(v) for k, v in PIVOTS.items()}
    pv['arm_l'][0] = -(half + 2.5)
    pv['arm_r'][0] = half + 2.5
    n = M.export('models/%s.json' % name, pv, jitter=0.006, pivots_in_voxels=True, roughness=0.9, specular=0.25)
    print(name, n, 'voxels')


# ---------------- piezas para personajes femeninos ----------------

def legs_slim(M: Model, stocking, shoe, sole, boot_top=2, boot=None):
    """Piernas de 5 voxels de ancho (medias o pantalón) y calzado. Con `boot`, botas altas
    hasta boot_top."""
    for s, p in ((-1, 'leg_l'), (1, 'leg_r')):
        x0, x1 = (-6, -1) if s < 0 else (1, 6)
        M.vbox(x0, 2, -3, x1, 25, 2, p, stocking)
        if boot is not None: M.vbox(x0, 2, -3, x1, boot_top, 2, p, boot)
        M.vbox(x0, 0, -3, x1, 2, 4, p, shoe)                 # pie
        M.vbox(x0, 0, -3, x1, 1, 4, p, sole)
        M.bevel(p, x0, x1, -3, 2, 2, 25)


def skirt(M: Model, col, bottom=12, half=8, flare=2, top=24, front_open=None):
    """Falda, vestido o faldón de abrigo que cae desde el tronco (parte torso: se mueve con
    él y deja a las piernas moverse debajo). Se ensancha `flare` voxels hacia abajo.
    front_open=(ancho, color): abertura delantera (abrigo abierto sobre otra prenda)."""
    for y in range(bottom, top):
        k = (top - y) / max(top - bottom, 1)
        w = half + int(round(flare * k))
        dz = int(round(flare * 0.5 * k))
        M.vbox(-w, y, -5 - dz, w, y + 1, 5 + dz, T, col)
        if front_open is not None:
            ow, oc = front_open
            M.vbox(-ow, y, 4 + dz, ow, y + 1, 5 + dz, T, oc)
    M.bevel(T, -half - flare, half + flare, -5 - flare, 5 + flare, bottom, top)


def face_f(M: Model, brow, skin_sh, lips, eye_y=48, lashes=EYE):
    """Cara femenina: cejas finas, ojos con una pestaña en el rabillo, nariz y labios."""
    for x in (-3, -2, 1, 2): paint_face(M, x, eye_y + 1, brow)
    for x in (-2, 1): paint_face(M, x, eye_y, EYE)
    paint_face(M, -3, eye_y, lashes)
    paint_face(M, 2, eye_y, lashes)
    for x in (-1, 0): paint_face(M, x, eye_y - 1, skin_sh)
    for x in (-1, 0): paint_face(M, x, eye_y - 3, lips)


def hair_long(M: Model, hair, bottom=37, top=51):
    """Melena que cae por la espalda (parte cabeza: se mueve con ella). Por debajo de la
    cabeza va por detrás del torso (z -7 y -6): si ocupara las posiciones de la espalda, las
    quitaría del torso y quedaría un hueco al girar la cabeza."""
    M.vbox(-5, 43, -6, 5, top, -4, H, hair)
    M.vbox(-5, bottom, -7, 5, 43, -5, H, hair)
    M.bevel(H, -5, 5, -7, -5, bottom, 43)
    for x in (-6, 5):                                 # a los lados, hasta la mandíbula
        M.vbox(x, 44, -5, x + 1, top, 2, H, hair)


def hair_bob(M: Model, hair, bottom=44, top=51):
    """Media melena a la altura de la mandíbula (años 20)."""
    M.vbox(-6, bottom, -6, 6, top, 1, H, hair)
    M.vbox(-5, bottom, -6, 5, top, -5, H, hair)


def bun(M: Model, hair, y=48):
    """Moño en la nuca."""
    M.vbox(-2, y - 2, -8, 2, y + 2, -5, H, hair)
