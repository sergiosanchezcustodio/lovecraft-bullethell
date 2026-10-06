"""Gente de Innsmouth (hito 6.1), estilo 4 con el "aspecto de Innsmouth" (cuerpo.innsmouth):
  habitante_pescador  pescador con jersey, tirantes, gorra de lana y botas de goma (grado 1)
  habitante_mujer     mujer con vestido largo, chal y moño gris (grado 1)
  habitante_viejo     viejo con abrigo raído, gorra de plato y barba rala (grado 2)
  acolito             acólito de la Orden de Dagon: túnica parda de lana con la capucha echada
                      atrás, cordón y amuleto de oro con un pez (grado 2)
  diacono             "El diácono de la Orden" (único): túnica casi negra, estola verde marino
                      y tiara baja de oro (los humanos de la Orden sí la llevan; GDD D-13)
Colores apagados y grises, la piel verdosa: no se confunden con los investigadores, que
además llevan el anillo de su color. Uso: python tools/gen_vecinos_innsmouth.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, rslab, T, H

SKIN = (0.80, 0.68, 0.58); SKIN_SH = (0.70, 0.58, 0.49)
GOLD = (0.78, 0.62, 0.26); GOLD_SH = (0.55, 0.42, 0.16)
SOLE = (0.08, 0.07, 0.07)
MATS = {}


def mat(col, m):
    MATS[col] = m
    return col


def hood_back(M, col, sh):
    """Capucha echada atrás: un saco de tela sobre los hombros, detrás de la cabeza."""
    slab(M, T, col, 56, 63, 0, -6.5, 16, 14, 6, 7, ch=2, over=False)
    slab(M, T, sh, 60, 63, 0, -3.5, 14, 12, 3, 3, ch=1, over=False)


def amulet(M, y=52):
    """Amuleto de oro con un pez en relieve pintado, colgado de un cordón."""
    for x in range(-2, 2):
        for yy in range(y, y + 4): cu.front(M, x, yy, GOLD, dz=1)
    for x in (-1, 0): cu.front(M, x, y + 1, GOLD_SH, dz=1)          # el pez: cuerpo
    cu.front(M, 1, y + 2, GOLD_SH, dz=1)                             # y cola
    for yy in range(y + 4, 62):
        for x in (-4 + (yy - y) // 3, 3 - (yy - y) // 3):
            cu.front(M, x, yy, GOLD_SH)


def pescador():
    MATS.clear()
    JER = mat((0.30, 0.33, 0.37), 'lana'); JER_SH = mat((0.24, 0.26, 0.30), 'lana')
    TRO = mat((0.29, 0.26, 0.20), 'lana'); STRAP = (0.20, 0.15, 0.10)
    BOOT = mat((0.12, 0.13, 0.12), 'cuero'); CAP = mat((0.22, 0.24, 0.22), 'lana')
    M = cu.new(1941)
    top = cu.boots(M, BOOT, SOLE, top=12)
    cu.legs(M, TRO, bottom=top)
    cu.torso(M, JER, b=1, bottom=36)
    for x in (-7, 6):
        for y in range(44, 61): cu.front(M, x, y, STRAP); cu.back(M, x, y, STRAP)
    for y in range(36, 61, 3):
        for x in range(-11, 11, 2): cu.front(M, x, y, JER_SH)
    slab(M, T, JER, 60, 63, 0, 0, 12, 11, 11, 10, ch=1)
    cu.neck(M, SKIN)
    cu.arms(M, JER, SKIN, b=1, cuff=JER_SH)
    cu.head(M, SKIN, SKIN_SH)
    s, sh = cu.innsmouth(M, 1, SKIN, SKIN_SH)
    slab(M, H, CAP, 78, 83, 0, -0.5, 16, 15, 16, 15, ch=2)
    cu.hair_back(M, s, (0.28, 0.24, 0.20), top=78)
    cu.finish(M, 'habitante_pescador', dict(MATS), flat=(cu.FISH_EYE, cu.FISH_PUPIL, STRAP), b=1, hat=(CAP,))


def mujer():
    MATS.clear()
    DRESS = mat((0.30, 0.27, 0.27), 'lana'); DRESS_SH = mat((0.24, 0.21, 0.21), 'lana')
    SHAWL = mat((0.26, 0.32, 0.29), 'punto'); SHAWL_SH = mat((0.20, 0.25, 0.22), 'punto')
    SHOE = mat((0.16, 0.13, 0.11), 'cuero'); HAIR = mat((0.55, 0.55, 0.52), 'pelo')
    M = cu.new(1942)
    M.body['fem'] = True
    cu.shoes_f(M, SHOE, SOLE)
    cu.legs_f(M, DRESS)
    cu.torso_f(M, DRESS, bottom=36)
    cu.skirt(M, DRESS, 4, top=40, b=-3, flare=3, depth=12)
    for y in range(6, 40, 4):                                          # pliegues pintados
        for x in (-8, -3, 2, 7): cu.front(M, x, y, DRESS_SH)
    # chal: sobre los hombros y cruzado delante, con flecos
    slab(M, T, SHAWL, 52, 62, 0, 0, 22, 21, 14, 13, ch=1)
    cu.opening(M, 50, 60, 2, 8, SHAWL_SH)
    for x in range(-10, 10, 2): cu.front(M, x, 51, SHAWL_SH, dz=1)
    cu.neck(M, SKIN)
    cu.arms(M, SHAWL, SKIN, ax=cu.ARM_X_F, slim=True, fore=DRESS)
    cu.head(M, SKIN, SKIN_SH, fem=True)
    s, sh = cu.innsmouth(M, 1, SKIN, SKIN_SH, w=14.0)
    cu.bob(M, HAIR, bottom=70, top=82, fringe=79)                      # pelo gris recogido
    rslab(M, H, HAIR, 74, 81, 0, -9, 7, 5, r=2, rt=2, rb=2)            # moño
    cu.finish(M, 'habitante_mujer', dict(MATS), flat=(cu.FISH_EYE, cu.FISH_PUPIL), ax=cu.ARM_X_F)


def viejo():
    MATS.clear()
    COAT = mat((0.33, 0.29, 0.22), 'lana'); COAT_SH = mat((0.26, 0.22, 0.17), 'lana')
    TRO = mat((0.22, 0.22, 0.24), 'lana'); SHOE = mat((0.20, 0.15, 0.11), 'cuero')
    CAP = mat((0.20, 0.21, 0.24), 'lana'); BEARD = mat((0.62, 0.62, 0.58), 'pelo')
    M = cu.new(1943)
    top = cu.shoes(M, SHOE, SOLE)
    cu.legs(M, TRO, bottom=top)
    cu.torso(M, COAT, b=0, bottom=30)
    cu.skirt(M, COAT, 26, top=40, b=0, flare=1, depth=13)
    for y in range(26, 58): cu.front(M, -1, y, COAT_SH)               # cierre
    for y in (34, 42, 50): cu.front(M, -2, y, (0.15, 0.13, 0.10), dz=1)
    for (x, y, z), v in M.V.items():                                   # remiendos y raídos
        if v[1] == COAT and M.noise(x, y, z, 2.0) > 0.8: v[1] = COAT_SH
    cu.neck(M, SKIN)
    cu.arms(M, COAT, SKIN)
    cu.head(M, SKIN, SKIN_SH)
    s, sh = cu.innsmouth(M, 2, SKIN, SKIN_SH)
    slab(M, H, CAP, 78, 81, 0, 0, 16, 16, 16, 16, ch=2)                # gorra de plato
    slab(M, H, CAP, 81, 83, 0, 1, 15, 14, 16, 14, ch=2)
    slab(M, H, CAP, 77, 78, 0, 8.5, 12, 12, 3, 3, ch=1)
    for x in range(-5, 5):                                             # barba rala bajo la boca
        for y in range(62, 66):
            if (x + y) % 2 == 0: cu.paint_face(M, x, y, BEARD, dz=1)
    cu.finish(M, 'habitante_viejo', dict(MATS), flat=(cu.FISH_EYE, cu.FISH_PUPIL), hat=(CAP,))


def robe(name, seed, col, sh, grade, stole=None, tiara=False):
    MATS.clear()
    mat(col, 'lana'); mat(sh, 'lana')
    ROPE = (0.55, 0.47, 0.32)
    M = cu.new(seed)
    for s_, _, shin, _, _ in cu.sides():                               # pies descalzos asomando
        slab(M, shin, SKIN, 0, 3, 5 * s_, 2, 8, 8, 13, 12, ch=1)
    cu.legs(M, col, bottom=3)
    cu.torso(M, col, b=0, bottom=30)
    cu.skirt(M, col, 4, top=40, b=0, flare=4, depth=13)
    for y in range(4, 40, 3):                                          # pliegues de la túnica
        for x in (-9, -4, 3, 8): cu.front(M, x, y, sh)
    cu.belt(M, ROPE, y=43, b=0, h=1)
    for y in range(32, 43): cu.front(M, 2, y, ROPE, dz=1)              # cabo del cordón
    if stole:                                                          # estola: dos bandas por delante
        for x in (-6, -5, 4, 5):
            for y in range(20, 61): cu.front(M, x, y, stole)
        for x in (-6, -5, 4, 5):
            for y in (20, 21): cu.front(M, x, y, GOLD)
    cu.neck(M, SKIN)
    cu.arms(M, col, SKIN, cuff=sh)
    hood_back(M, col, sh)
    amulet(M)
    cu.head(M, SKIN, SKIN_SH)
    s, ssh = cu.innsmouth(M, grade, SKIN, SKIN_SH)
    hat = ()
    if tiara:                                                          # tiara baja de oro, más ancha arriba
        slab(M, H, GOLD, 77, 89, 0, -0.5, 15, 20, 15, 18, ch=2)
        for x in range(-6, 6):
            for y in (80, 83, 86):
                if (x + y) % 3 == 0: cu.paint_face(M, x, y, GOLD_SH)   # relieves de olas
        for x in (-1, 0):
            for y in range(89, 93): M.put(x, y, 7 - (y - 89), H, GOLD)            # cresta delantera
        hat = (GOLD, GOLD_SH)
    cu.finish(M, name, dict(MATS), flat=(cu.FISH_EYE, cu.FISH_PUPIL, ROPE, GOLD, GOLD_SH), hat=hat,
              roughness=0.9 if not tiara else 0.75, specular=0.25 if not tiara else 0.4)


pescador()
mujer()
viejo()
robe('acolito', 1944, (0.36, 0.29, 0.21), (0.28, 0.22, 0.16), 2)
robe('diacono', 1945, (0.12, 0.13, 0.16), (0.08, 0.09, 0.11), 2, stole=(0.16, 0.38, 0.34), tiara=True)
