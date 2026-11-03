"""Los buhoneros (hito 16.12): vendedores que aparecen a mitad de algunos niveles. Estilo 4
(tools/cuerpo.py), humanos a bloques con los detalles pintados. El de la tercera parte es el
anticuario de la tienda (gen_anciano.py).
  ballenero   Halvor Ness, ballenero noruego de una factoría del mar de Ross: sueste y
              chubasquero de hule amarillo ocre hasta las rodillas, jersey de lana crudo de
              cuello vuelto, barba pelirroja poblada, mejillas curtidas y botas de agua negras.
  zadok       Zadok Allen, el viejo borracho de Innsmouth (96 años): calvo con mechones
              blancos sin peinar, barba rala y blanca, nariz roja, levita parda raída y
              remendada, bufanda deshilachada, zapatos rotos y una botella de whisky en la mano.
Uso: python tools/gen_buhoneros.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, rslab, T, H


def ballenero():
    OIL = (0.80, 0.60, 0.16); OIL_SH = (0.64, 0.46, 0.10); OIL_SEAM = (0.50, 0.36, 0.08)
    WOOL = (0.86, 0.82, 0.70); WOOL_SH = (0.74, 0.70, 0.58)
    TRO = (0.22, 0.24, 0.30)
    BOOT = (0.10, 0.10, 0.11); SOLE = (0.05, 0.05, 0.05)
    SKIN = (0.82, 0.58, 0.46); SKIN_SH = (0.72, 0.48, 0.38)
    BEARD = (0.72, 0.34, 0.14); BEARD_D = (0.56, 0.24, 0.10)
    CHEEK = (0.86, 0.46, 0.38); LIP = (0.58, 0.30, 0.28)
    BTN = (0.30, 0.22, 0.12)
    M = cu.new(1931)
    top = cu.boots(M, BOOT, SOLE, top=20)                              # botas de agua altas
    cu.legs(M, TRO, bottom=top)
    cu.torso(M, OIL, b=2, bottom=30)
    cu.skirt(M, OIL, 24, top=40, b=2, flare=2, depth=14)               # chubasquero hasta la rodilla
    cu.opening(M, 52, 61, 3, 9, WOOL)                                  # el jersey asoma en el pecho
    for y in range(24, 52): cu.front(M, -1, y, OIL_SEAM)               # cierre
    for y in (30, 37, 44, 50): cu.front(M, -2, y, BTN, dz=1)
    for (x, y, z), v in M.V.items():                                   # el hule brilla y se arruga a franjas
        if v[1] == OIL and y % 7 == 0 and y < 58: v[1] = OIL_SH
    slab(M, T, WOOL, 59, 64, 0, 0, 12, 11, 11, 10, ch=1)               # cuello vuelto
    for (x, y, z), v in M.V.items():
        if v[1] == WOOL and y >= 59 and x % 2 == 0: v[1] = WOOL_SH     # canalé
    cu.neck(M, SKIN)
    cu.arms(M, OIL, SKIN, b=2, cuff=WOOL, cuff_wide=False)
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, BEARD_D, brow_style='recta', y=73)
    cu.cheeks(M, CHEEK)
    cu.beard(M, BEARD)
    cu.moustache(M, BEARD_D, xs=range(-4, 4), y=69, rows=1)
    for (x, y, z), v in M.V.items():                                   # mechones en la barba
        if v[1] == BEARD and (x * 3 + y * 5 + z) % 7 == 0: v[1] = BEARD_D
    for x in (-1, 0): cu.paint_face(M, x, 67, LIP)
    for y in (72, 73): cu.paint_face(M, -1, y, CHEEK); cu.paint_face(M, 0, y, CHEEK)   # nariz curtida
    cu.hair_back(M, SKIN, BEARD, top=79, bottom=66)
    # sueste: copa redonda y ala corta delante, larga detrás (cubre la nuca)
    slab(M, H, OIL, 79, 86, 0, 0, 17, 15, 17, 15, ch=2)
    slab(M, H, OIL_SH, 78, 79, 0, -1.0, 20, 20, 20, 20, ch=2)
    slab(M, H, OIL_SH, 66, 78, 0, -8.5, 18, 16, 4, 3, ch=1)            # el faldón de la nuca
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == OIL and y == 81: v[1] = OIL_SEAM      # costura de la copa
    cu.seams(M, (OIL,))
    cu.finish(M, 'ballenero', {OIL: 'cuero', OIL_SH: 'cuero', WOOL: 'lana', WOOL_SH: 'lana', TRO: 'lana',
                               BOOT: 'cuero', SOLE: 'cuero', BEARD: 'pelo', BEARD_D: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
              flat=(CHEEK, LIP, BTN, OIL_SEAM), b=2, hat=(OIL, OIL_SH, OIL_SEAM), skirt=True)


def zadok():
    COAT = (0.36, 0.27, 0.18); COAT_SH = (0.27, 0.20, 0.13); PATCH = (0.30, 0.32, 0.26)
    SHIRT = (0.68, 0.64, 0.52)
    SCARF = (0.42, 0.14, 0.12); SCARF_SH = (0.30, 0.09, 0.08)
    TRO = (0.20, 0.20, 0.21)
    SHOE = (0.17, 0.12, 0.08); SOLE = (0.06, 0.05, 0.04)
    SKIN = (0.80, 0.62, 0.52); SKIN_SH = (0.70, 0.52, 0.44)
    HAIR = (0.86, 0.86, 0.84); HAIR_D = (0.70, 0.70, 0.70)
    NOSE = (0.80, 0.34, 0.30); LIP = (0.52, 0.28, 0.26); WR = (0.56, 0.42, 0.36)
    GLASS = (0.20, 0.32, 0.16); GLASS_HI = (0.36, 0.52, 0.30); CORK = (0.62, 0.46, 0.28)
    LABEL = (0.82, 0.76, 0.56)
    M = cu.new(1927)
    top = cu.shoes(M, SHOE, SOLE)
    cu.legs(M, TRO, bottom=top)
    cu.torso(M, COAT, b=-1, bottom=30)
    cu.skirt(M, COAT, 22, top=40, b=-1, flare=1, depth=13)             # levita larga
    cu.opening(M, 46, 61, 4, 10, SHIRT)                                # abierta: camisa sucia
    for y in range(22, 46): cu.front(M, -1, y, COAT_SH)
    for (x, y, z), v in M.V.items():                                   # raída: manchas y bajos deshilachados
        if v[1] == COAT and M.noise(x, y, z, 2.0) > 0.78: v[1] = COAT_SH
    for x in range(4, 9):                                              # remiendos
        for y in range(32, 37): cu.front(M, x, y, PATCH)
    for x in range(-10, -6):
        for y in range(48, 52): cu.front(M, x, y, PATCH)
    for (x, y, z), v in M.V.items():
        if v[1] in (COAT, COAT_SH) and y == 22 and (x + z) % 3 == 0: v[1] = SOLE
    slab(M, T, SCARF, 59, 63, 0, 0, 13, 12, 12, 11, ch=1)              # bufanda deshilachada
    for y in range(48, 59):                                            # una punta cae delante
        for x in (-6, -5, -4): cu.front(M, x, y, SCARF if y % 3 else SCARF_SH, dz=1)
    cu.neck(M, SKIN)
    cu.arms(M, COAT, SKIN, b=-1, cuff=COAT_SH)
    # la botella de whisky en la mano derecha: verde oscuro, etiqueta y corcho
    hx = cu.ARM_X - 0.5
    slab(M, 'fore_r', GLASS, 25, 33, hx * 1.02, 4.5, 4, 4, 4, 4, ch=1)
    slab(M, 'fore_r', GLASS, 33, 36, hx * 1.02, 4.5, 2, 2, 2, 2, ch=0)
    slab(M, 'fore_r', CORK, 36, 37, hx * 1.02, 4.5, 2, 2, 2, 2, ch=0)
    for (x, y, z), v in M.V.items():
        if v[0] == 'fore_r' and v[1] == GLASS and 27 <= y <= 30: v[1] = LABEL
        elif v[0] == 'fore_r' and v[1] == GLASS and y >= 31 and z >= 6: v[1] = GLASS_HI
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, HAIR, brow_style='poblada', y=73)
    for x in (-5, -4, 3, 4): cu.paint_face(M, x, 72, WR)               # ojeras
    for x in (-1, 0, -2, 1):
        for y in (70, 71): cu.paint_face(M, x, y, NOSE)                # nariz roja del whisky
    for x in (-6, -5, 4, 5): cu.paint_face(M, x, 70, NOSE)
    # barba rala y blanca, con huecos
    rslab(M, H, HAIR, 61, 68, 0, 3.0, 14, 10, r=3, rt=0, rb=3)
    for (x, y, z), v in list(M.V.items()):
        if v[0] == H and v[1] == HAIR and y < 68 and (x * 5 + y * 3) % 6 == 0: v[1] = HAIR_D
    cu.moustache(M, HAIR_D, xs=range(-4, 4), y=69, rows=1)
    for x in range(-2, 2): cu.paint_face(M, x, 67, LIP)
    # calvo, con mechones blancos de punta sobre las orejas
    cu.hair_back(M, SKIN, HAIR, top=77, zmax=-3)
    for s in (-1, 1):
        rslab(M, H, HAIR, 74, 79, 8.0 * s, -1.5, 2, 9, r=1, rt=1, rb=0)
        rslab(M, H, HAIR_D, 78, 80, 8.5 * s, -2.5, 2, 4, r=0, rt=0, rb=0)
    for y in (77, 78): cu.paint_face(M, -3, y, WR); cu.paint_face(M, 2, y, WR)   # arrugas de la frente
    cu.seams(M, (COAT,))
    cu.finish(M, 'zadok', {COAT: 'lana', COAT_SH: 'lana', PATCH: 'lana', SHIRT: 'lona', SCARF: 'lana', SCARF_SH: 'lana',
                           TRO: 'lana', SHOE: 'cuero', SOLE: 'cuero', HAIR: 'pelo', HAIR_D: 'pelo', SKIN: 'piel', SKIN_SH: 'piel'},
              flat=(NOSE, LIP, WR, GLASS, GLASS_HI, CORK, LABEL), b=-1, skirt=True)


if __name__ == '__main__':
    os.chdir(os.path.join(os.path.dirname(__file__), '..'))
    ballenero()
    zadok()
