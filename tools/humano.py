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
