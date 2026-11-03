"""Piezas de los enemigos nuevos de la fase 16 (bloque C).
  vaina_esporas   hito 16.16: la vaina que planta el Antiguo sembrador (una mina). Un bulbo de
                  piel parda con vetas, medio enterrado en un montón de tierra y escarcha, con un
                  núcleo amarillo enfermizo que brilla por las rendijas y tres filamentos arriba.
  guardian_orden  hito 16.17: guardián de la Orden de Dagón. Híbrido de grado 3, corpulento, con
                  túnica verde marino hasta la rodilla, peto de placas de bronce, correaje de
                  cuero y un gran escudo redondo de bronce con verdín en el brazo izquierdo
                  (relieve de olas y un pez en el umbo). Estilo de los humanos (tools/cuerpo.py).
  hija_marsh      hito 16.17: una de las hijas de los Marsh. Joven de grado 1 (ojos saltones, piel
                  grisácea), pálida, con melena larga negra, vestido largo verde mar con encaje
                  y la tiara de oro extraño de la familia; las manos juntas al cantar.
Los cuerpos van en sus generadores de siempre: el shoggoth excavador es el fragmento a S=3 con
costra de hielo (`python tools/gen_fragmento.py 3 shoggoth_excavador 1940`) y el Antiguo
sembrador, una variante de `tools/gen_antiguo.py`.
Uso: python tools/gen_enemigos_fase16.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import cuerpo as cu
from cuerpo import slab, T, H

SKIN_I = (0.80, 0.68, 0.58); SKIN_I_SH = (0.70, 0.58, 0.49)          # piel de Innsmouth (como gen_vecinos_innsmouth)
GOLD = (0.64, 0.54, 0.30); GOLD_SH = (0.44, 0.36, 0.18)
MATS = {}


def mat(col, m):
    MATS[col] = m
    return col

SAC = (0.46, 0.40, 0.22); SAC_D = (0.28, 0.24, 0.14); SPORE = (0.86, 0.80, 0.36); SPORE_L = (1.0, 0.95, 0.60)
DIRT = (0.20, 0.17, 0.14); DIRT_D = (0.12, 0.10, 0.09); FROST = (0.78, 0.84, 0.90)


def vaina():
    M = Model(S=2, seed=1616)
    M.ell(0, 0.4, 0, 4.2, 1.4, 4.0, 'body', DIRT)                     # montón de tierra
    M.ell(0, 3.6, 0, 2.8, 3.4, 2.8, 'body', SAC)                      # el bulbo
    M.ell(0, 3.8, 0, 2.0, 2.6, 2.0, 'body', SPORE, glow=1)             # núcleo
    M.ell(0, 6.8, 0, 1.2, 1.0, 1.2, 'body', SAC_D)                    # cuello
    for i in range(3):                                                # filamentos
        a = i / 3 * math.tau + 0.4
        M.capsule((0, 7.2, 0), (math.cos(a) * 1.6, 9.4, math.sin(a) * 1.6), 0.45, 0.3, 'body', SAC_D)
        M.ell(math.cos(a) * 1.7, 9.6, math.sin(a) * 1.7, 0.55, 0.55, 0.55, 'body', SPORE_L, glow=1)
    for (x, y, z), v in M.V.items():
        if v[1] == SAC:                                               # vetas y rendijas que dejan ver el núcleo
            h = M.hsh(x, y // 2, z)
            if h > 0.86: v[1] = SAC_D
        if v[1] == DIRT:
            n = M.noise(x, y, z, 2.5)
            v[1] = FROST if n > 0.68 and y >= 1 else (DIRT_D if n < 0.35 else DIRT)
    # rendijas: quita piel encima del núcleo en franjas verticales para que asome el brillo
    for (x, y, z) in [k for k, v in M.V.items() if v[1] in (SAC, SAC_D) and 3 <= k[1] <= 11]:
        a = math.atan2(z, x)
        if math.cos(a * 5) > 0.93 and M.exposed((x, y, z)): del M.V[(x, y, z)]
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    n = M.export('models/vaina_esporas.json', {'body': [0, 0, 0]}, jitter=0.012, roughness=0.55, specular=0.4)
    print('vaina_esporas', n, 'voxels')


BRONZE = (0.60, 0.40, 0.19); BRONZE_L = (0.80, 0.60, 0.32); BRONZE_D = (0.38, 0.25, 0.11); VERD = (0.30, 0.52, 0.42)


def _shield(M, cx, cy, z0, r):
    """Escudo redondo de bronce en el antebrazo izquierdo, de frente (+Z): borde oscuro, una
    corona de olas en relieve pintado, umbo con un pez y manchas de verdín."""
    for x in range(int(cx - r) - 1, int(cx + r) + 2):
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d > r: continue
            col = BRONZE_D if d > r - 1.6 else BRONZE
            if r * 0.55 < d < r * 0.68 and (int(math.degrees(math.atan2(y - cy, x - cx))) // 15) % 2 == 0: col = BRONZE_L
            if M.noise(x, y, 3, 2.2) > 0.70 and d < r - 1.6: col = VERD
            for z in range(z0, z0 + 2): M.put(x, y, z, 'fore_l', col)
            if d < 3.2: M.put(x, y, z0 + 2, 'fore_l', BRONZE_L if d < 2.2 else BRONZE)      # umbo
    for (x, y) in ((-1, 0), (0, 0), (1, 0), (2, 1), (2, -1), (-2, 0)):                    # el pez del umbo
        M.put(int(cx) + x, int(cy) + y, z0 + 3, 'fore_l', BRONZE_D)
    for z in range(4, z0):                                                                # abrazadera al antebrazo
        for y in (int(cy) - 1, int(cy), int(cy) + 1):
            for x in range(int(cx) - 1, int(cx) + 2): M.put(x, y, z, 'fore_l', (0.26, 0.18, 0.12))


def guardian():
    MATS.clear()
    TUN = mat((0.15, 0.25, 0.23), 'lana'); TUN_SH = mat((0.10, 0.17, 0.16), 'lana')
    LEATHER = mat((0.27, 0.18, 0.11), 'cuero')
    b = 3
    M = cu.new(1617)
    for s_, _, shin, _, _ in cu.sides():                               # pies palmeados descalzos
        slab(M, shin, SKIN_I, 0, 3, 5 * s_, 3, 9, 8, 17, 14, ch=1)
    cu.legs(M, TUN_SH, bottom=3)
    cu.torso(M, TUN, b=b, bottom=30)
    cu.skirt(M, TUN, 16, top=40, b=b, flare=3, depth=14)
    for y in range(17, 40, 3):                                         # pliegues
        for x in (-10, -4, 3, 9): cu.front(M, x, y, TUN_SH)
    for y in range(46, 61):                                            # peto: placas de bronce como escamas
        for x in range(-9, 9):
            row = (y - 46) // 3
            col = BRONZE_D if y in (46, 60) or x in (-9, 8) else (BRONZE_L if (y - 46) % 5 == 2 and x % 4 == 0 else BRONZE)   # bordes y remaches
            cu.front(M, x, y, col)
    for y in range(44, 62):                                            # correaje cruzado
        x = int(-8 + (y - 44) * 0.95)
        for dx in (0, 1): cu.front(M, x + dx, y, LEATHER, dz=1)
    cu.belt(M, LEATHER, y=43, b=b, h=2, buckle=BRONZE_L)
    cu.neck(M, SKIN_I)
    cu.arms(M, TUN, SKIN_I, b=b, cuff=LEATHER)
    cu.head(M, SKIN_I, SKIN_I_SH)
    cu.innsmouth(M, 3, SKIN_I, SKIN_I_SH)
    for k in list(M.V):                                                # garras
        v = M.V[k]
        if v[0] in ('fore_l', 'fore_r') and k[1] in (24, 25) and v[1] != TUN: v[1] = (0.80, 0.78, 0.66)
    ax = (cu.ARM_X + b / 2) * 1.02
    _shield(M, -ax + 6.0, 41.0, 9, 13.5)
    cu.finish(M, 'guardian_orden', dict(MATS), flat=(cu.FISH_EYE, cu.FISH_PUPIL, BRONZE, BRONZE_L, BRONZE_D, VERD),
              b=b, roughness=0.6, specular=0.45, skirt=True)


def hija_marsh():
    MATS.clear()
    DRESS = mat((0.20, 0.36, 0.34), 'lana'); DRESS_SH = mat((0.13, 0.25, 0.24), 'lana')
    LACE = mat((0.80, 0.80, 0.72), 'lana'); HAIR = mat((0.07, 0.07, 0.08), 'pelo')
    SKIN = (0.86, 0.80, 0.74); SKIN_SH = (0.76, 0.69, 0.63)               # pálida
    M = cu.new(1618)
    M.body['fem'] = True
    for s_, _, shin, _, _ in cu.sides():                               # descalza
        slab(M, shin, SKIN, 0, 3, 4.5 * s_, 2, 7, 7, 12, 11, ch=1)
    cu.legs_f(M, SKIN)
    cu.torso_f(M, DRESS, bottom=36)
    cu.skirt(M, DRESS, 3, top=42, b=-3, flare=5, depth=12)
    for y in range(4, 42, 3):
        for x in (-8, -3, 2, 7): cu.front(M, x, y, DRESS_SH)
    for (x, y, z), v in M.V.items():                                   # encaje en el bajo
        if v[0] == T and 3 <= y <= 5 and v[1] in (DRESS, DRESS_SH) and (x + z) % 2 == 0: v[1] = LACE
    for x in range(-5, 5):                                             # escote de encaje
        for y in (58, 59): cu.front(M, x, y, LACE)
    cu.neck(M, SKIN)
    cu.arms(M, DRESS, SKIN, ax=cu.ARM_X_F, slim=True, cuff=LACE, cuff_wide=False)
    cu.head(M, SKIN, SKIN_SH, fem=True)
    ns, nsh = cu.innsmouth(M, 1, SKIN, SKIN_SH, w=14.0)
    cu.lips(M, (0.42, 0.30, 0.34))
    cu.long_hair(M, HAIR, bottom=50, top=80, sh=(0.12, 0.12, 0.14), width=15.0)
    slab(M, H, HAIR, 79, 84, 0, -1, 15, 12, 15, 12, ch=2, over=False)   # pelo en la coronilla, abombado
    for y in range(78, 82):                                            # tiara: solo un aro que se abre hacia arriba
        hw, hd = 8.2 + (y - 78) * 0.35, 8.2 + (y - 78) * 0.3
        for i in range(96):
            a = i / 96 * math.tau
            x, z = int(math.floor(hw * math.cos(a))), int(math.floor(hd * math.sin(a) - 0.5))
            col = GOLD_SH if (y == 80 and i % 6 < 3) else GOLD
            M.put(x, y, z, H, col)
            if y == 81 and i % 12 == 0:                                # puntas de la corona
                for k in (1, 2): M.put(x, y + k, z, H, GOLD)
    for x in (-1, 0):                                                  # cresta delantera, más alta
        for k, y in enumerate(range(82, 86)): M.put(x, y, 7 - k // 2, H, GOLD_SH if y == 85 else GOLD)
    cu.finish(M, 'hija_marsh', dict(MATS), flat=(cu.FISH_EYE, cu.FISH_PUPIL, GOLD, GOLD_SH, LACE), ax=cu.ARM_X_F,
              hat=(GOLD, GOLD_SH), roughness=0.8, specular=0.3, skirt=True)


if __name__ == '__main__':
    vaina()
    guardian()
    hija_marsh()
