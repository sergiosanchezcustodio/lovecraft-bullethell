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
  sonambulo       hito 16.18: un vecino de Providence que sueña con R'lyeh. Camisón largo de
                  rayas azul pálido, gorro de dormir, descalzo, pelo gris revuelto, ojos cerrados
                  con ojeras moradas y la boca entreabierta. Estilo de los humanos.
  idolo_vivo      hito 16.18: la estatuilla de Cthulhu del tamaño de un hombre, de piedra verdinegra
                  sobre un pedestal con jeroglíficos: agachado, con cabeza de pulpo, barba de
                  tentáculos, alas de membrana a la espalda y ojos que brillan. Orgánica (voxlib);
                  partes body (el cuerpo), top (la cabeza), pod_l/pod_r (las alas) y base (el
                  pedestal, quieto), para anim_fragmento: respira, la cabeza ondula y se hincha
                  al disparar.
  gedney          hito 16.19: Gedney, el estudiante del campamento de Lake que desapareció, vuelto
                  otra cosa: la parka de la expedición reventada por masas de protoplasma negro
                  con ojos verdes, el brazo derecho convertido en un pseudópodo, la cara a medio
                  cubrir. Estilo de los humanos con la masa de los shoggoths encima.
  obed_marsh      hito 16.19: el capitán Obed Marsh rejuvenecido por el pacto con los Profundos:
                  levita de capitán azul marino con botones de oro, chaleco, corbatín, botas de
                  mar, patillas negras, cadena de oro y el aspecto de Innsmouth de grado 2.
  castro          hito 16.19: el viejo Castro, el marinero mestizo que habló con Legrasse: piel
                  curtida, barba gris rala, camisa blanca hecha jirones, calzón remangado,
                  descalzo, pañuelo rojo al cuello y un ídolo de piedra colgado del pecho.
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


def sonambulo():
    MATS.clear()
    GOWN = mat((0.78, 0.80, 0.82), 'lana'); STRIPE = mat((0.52, 0.60, 0.74), 'lana')
    HAIR = mat((0.44, 0.44, 0.46), 'pelo')
    SKIN = (0.84, 0.78, 0.72); SKIN_SH = (0.72, 0.66, 0.62)
    M = cu.new(1619)
    for s_, _, shin, _, _ in cu.sides():                               # descalzo
        slab(M, shin, SKIN, 0, 3, 5 * s_, 2, 8, 8, 13, 12, ch=1)
    cu.legs(M, SKIN_SH, bottom=3)
    cu.torso(M, GOWN, b=0, bottom=30)
    cu.skirt(M, GOWN, 8, top=40, b=0, flare=3, depth=13)
    for (x, y, z), v in M.V.items():                                   # rayas verticales
        if v[1] == GOWN and (x + 40) % 4 == 0: v[1] = STRIPE
    for y in range(52, 61, 3): cu.front(M, 0, y, (0.90, 0.90, 0.88), dz=1)   # botonadura
    cu.neck(M, SKIN)
    cu.arms(M, GOWN, SKIN, cuff=STRIPE, cuff_wide=False)
    for (x, y, z), v in M.V.items():
        if v[0] in ('arm_l', 'arm_r', 'fore_l', 'fore_r') and v[1] == GOWN and (y // 3) % 2 == 0: v[1] = STRIPE
    cu.head(M, SKIN, SKIN_SH)
    LID = (0.42, 0.34, 0.36); BAG = (0.56, 0.46, 0.58); MOUTH = (0.30, 0.16, 0.18)
    for x in (-5, -4, -3, 2, 3, 4):                                    # ojos cerrados con ojeras
        cu.paint_face(M, x, 74, LID)
        cu.paint_face(M, x, 73, BAG)
    for x in (-6, -5, -4, -3, -2, 1, 2, 3, 4, 5): cu.paint_face(M, x, 76, HAIR, dz=1)   # cejas grises
    for x in (-2, -1, 0, 1): cu.paint_face(M, x, 67, MOUTH)            # boca entreabierta
    for x in (-1, 0): cu.paint_face(M, x, 66, MOUTH)
    cu.hair_back(M, SKIN, HAIR, bottom=66)
    for i in range(14):                                                # pelos revueltos
        x = M.rng.randint(-7, 6); z = M.rng.randint(-7, 4)
        t = M.top(x, z)
        if t is not None: M.put(x, t + 1, z, H, HAIR)
    CAP = (0.70, 0.74, 0.86); TASSEL = (0.92, 0.92, 0.90)              # gorro de dormir caído hacia atrás
    slab(M, H, CAP, 79, 84, 0, -0.5, 16, 14, 16, 14, ch=2)
    for k in range(10):                                                # la punta cae por la nuca
        for x in (-1, 0):
            for t in (0, 1): M.put(x, 83 - k + t, -8 - (k + 1) // 3, H, CAP)
    for dx in (-1, 0, 1):
        for dy in (0, 1): M.put(dx, 72 + dy, -12, H, TASSEL)
    cu.finish(M, 'sonambulo', dict(MATS), flat=(LID, BAG, MOUTH, TASSEL), hat=(CAP, TASSEL), roughness=0.9, specular=0.2,
              skirt=True)


STONE = (0.16, 0.22, 0.18); STONE_D = (0.08, 0.11, 0.09); STONE_L = (0.28, 0.36, 0.28); IDOL_EYE = (0.55, 1.0, 0.45)
PED = (0.30, 0.28, 0.24); PED_D = (0.18, 0.17, 0.15)


def idolo():
    M = Model(S=2, seed=1620)
    M.box(-7, 0, -7, 7, 6, 7, 'base', PED)                             # pedestal con jeroglíficos
    M.box(-8, 0, -8, 8, 1.5, 8, 'base', PED_D)
    for (x, y, z), v in M.V.items():
        if v[0] == 'base' and 3 <= y <= 10 and M.hsh(x // 2, y // 2, z // 2) > 0.72: v[1] = PED_D
    M.ell(0, 12.0, -0.5, 4.6, 5.4, 4.0, 'body', STONE)                 # tronco agachado
    for s in (-1, 1):
        M.capsule((s * 2.8, 9.0, 0.5), (s * 4.0, 7.2, 4.0), 2.2, 1.6, 'body', STONE)   # muslos
        for k in (-1, 0, 1):                                           # garras de los pies
            M.cone((s * 4.0 + k * 0.9, 6.8, 4.5), (s * 4.0 + k * 1.2, 6.4, 6.5), 0.6, 'body', STONE_D, STONE_L)
        M.capsule((s * 4.2, 15.0, 0.5), (s * 3.2, 10.5, 4.2), 1.3, 1.0, 'body', STONE)   # brazos sobre las rodillas
        for k in (-1, 0, 1):
            M.cone((s * 3.2 + k * 0.7, 10.0, 4.6), (s * 3.2 + k * 0.9, 8.6, 5.8), 0.5, 'body', STONE_D, STONE_L)
    M.ell(0, 21.0, 0.5, 4.2, 4.6, 4.4, 'top', STONE)                   # cabeza de pulpo
    M.ell(0, 23.6, -1.4, 3.6, 3.2, 3.6, 'top', STONE)
    for i in range(7):                                                 # barba de tentáculos
        a = (i - 3) * 0.32
        x0, z0 = math.sin(a) * 3.0, 3.6 + math.cos(a) * 0.6
        M.capsule((x0, 18.5, z0), (x0 * 1.3, 14.0 + (i % 2), z0 + 1.4), 0.75, 0.45, 'top', STONE)
        M.ell(x0 * 1.35, 13.6 + (i % 2), z0 + 1.6, 0.6, 0.7, 0.6, 'top', STONE_L)
    for s in (-1, 1):                                                  # ojos
        M.ell(s * 1.9, 21.6, 4.2, 0.8, 0.6, 0.6, 'top', IDOL_EYE, glow=1)
    for s, p in ((-1, 'pod_l'), (1, 'pod_r')):                         # alas de membrana a la espalda
        for i in range(4):
            a = 0.35 + i * 0.28
            tip = (s * (3.0 + math.cos(a) * 7.0), 14.0 + math.sin(a) * 11.0, -5.0)
            M.capsule((s * 2.4, 16.5, -3.4), tip, 0.55, 0.35, p, STONE_D)
        for xv in range(5, 20):
            for yv in range(30, 52):
                x, y = xv / 2, yv / 2
                ang = math.atan2(y - 14.0, x - 3.0)
                r = math.hypot(x - 3.0, y - 14.0)
                if 0.3 < ang < 1.3 and r < 7.2:
                    for zv in (-10, -9):
                        M.put(xv if s > 0 else -xv - 1, yv, zv, p, STONE if M.hsh(xv, yv, 1) > 0.25 else STONE_D, over=False)
    for (x, y, z), v in M.V.items():                                   # vetas
        if v[0] != 'base' and v[2] == 0:
            n = M.noise(x, y, z, 3.0)
            if n > 0.7: v[1] = STONE_L
            elif n < 0.25: v[1] = STONE_D
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    piv = {'base': [0, 0, 0], 'body': [0, 6.5, 0], 'top': [0, 17.5, 0.5],
           'pod_l': [-2.4, 16.5, -3.4], 'pod_r': [2.4, 16.5, -3.4]}
    n = M.export('models/idolo_vivo.json', piv, jitter=0.014, roughness=0.75, specular=0.3)
    print('idolo_vivo', n, 'voxels')


PROTO = (0.04, 0.05, 0.05); PROTO_G = (0.08, 0.16, 0.12); PROTO_P = (0.14, 0.08, 0.18); PEYE = (0.72, 0.96, 0.40)


def _blob(M, part, cx, cy, cz, r, eyes=2):
    """Masa de protoplasma negro con brillo verde y violeta y ojos verdes que brillan (coords en voxels)."""
    for x in range(int(cx - r) - 1, int(cx + r) + 2):
        for y in range(int(cy - r) - 1, int(cy + r) + 2):
            for z in range(int(cz - r) - 1, int(cz + r) + 2):
                d = ((x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 + (z + 0.5 - cz) ** 2) ** 0.5
                if d <= r:
                    n = M.noise(x, y, z, 3.0)
                    M.put(x, y, z, part, PROTO_G if n > 0.62 else (PROTO_P if n < 0.3 else PROTO))
    for i in range(eyes):
        a = M.rng.uniform(-1.1, 1.1); b = M.rng.uniform(-0.6, 0.8)
        ex, ey, ez = cx + math.sin(a) * r * 0.95, cy + math.sin(b) * r * 0.8, cz + math.cos(a) * r * 0.95
        for dx in (-1, 0):
            for dy in (-1, 0): M.put(int(ex) + dx, int(ey) + dy, int(ez), part, PEYE, glow=1)
        M.put(int(ex), int(ey), int(ez) + 1, part, (0.02, 0.03, 0.02))


def gedney():
    MATS.clear()
    SKIN = (0.66, 0.70, 0.72); SKIN_SH = (0.54, 0.58, 0.62)
    PARKA = mat((0.46, 0.40, 0.30), 'lona'); FUR = mat((0.74, 0.70, 0.62), 'lana')
    TRO = mat((0.24, 0.22, 0.20), 'lana'); BOOT = mat((0.16, 0.12, 0.09), 'cuero'); SOLE = (0.07, 0.06, 0.05)
    M = cu.new(1621)
    top = cu.boots(M, BOOT, SOLE, top=16)
    cu.legs(M, TRO, bottom=top)
    cu.torso(M, PARKA, b=2, bottom=28)
    cu.skirt(M, PARKA, 4, top=34, b=2, flare=2, depth=14)
    cu.neck(M, SKIN)
    cu.arms(M, PARKA, SKIN, b=2, cuff=FUR)
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, (0.30, 0.30, 0.32), eye=(0.08, 0.06, 0.05), brow_style='recta')
    cu.mouth(M, (0.24, 0.10, 0.12), wide=True)
    slab(M, H, FUR, 77, 82, 0, -0.5, 15, 13, 15, 13, ch=2)             # gorro de piel
    for k in [k for k, v in M.V.items() if v[0] == 'fore_r']: del M.V[k]   # el brazo derecho ya no es un brazo
    for i in range(7):                                                 # pseudópodo que cuelga del codo
        t = i / 6
        _blob(M, 'fore_r', 16.5 + t * 2.5, 45 - t * 20, 1 + t * 6, 6.5 - t * 3.0, eyes=1 if i in (1, 4) else 0)
    _blob(M, T, 3, 50, 8, 9.5, eyes=4)                                 # revienta el pecho
    _blob(M, T, -7, 38, 7, 6.5, eyes=2)
    _blob(M, T, 8, 33, 6, 5.0, eyes=1)
    _blob(M, T, 0, 54, -8, 10.0, eyes=3)                               # y la espalda
    _blob(M, T, -8, 60, -4, 6.0, eyes=1)
    _blob(M, H, 4, 70, 5, 5.0, eyes=2)                                 # le cubre media cara
    _blob(M, 'arm_l', -18, 56, 2, 4.6, eyes=1)
    cu.finish(M, 'gedney', dict(MATS), flat=(PROTO, PROTO_G, PROTO_P, PEYE), b=2, hat=(FUR,), roughness=0.55, specular=0.5,
              skirt=True)


def obed():
    MATS.clear()
    COAT = mat((0.08, 0.10, 0.20), 'lana'); COAT_SH = mat((0.05, 0.06, 0.13), 'lana')
    VEST = mat((0.42, 0.10, 0.10), 'lana'); SHIRT = mat((0.84, 0.82, 0.76), 'lana')
    TRO = mat((0.16, 0.15, 0.14), 'lana'); BOOT = mat((0.08, 0.07, 0.06), 'cuero'); SOLE = (0.04, 0.04, 0.04)
    HAIR = mat((0.06, 0.05, 0.05), 'pelo')
    M = cu.new(1622)
    top = cu.boots(M, BOOT, SOLE, top=20)
    cu.legs(M, TRO, bottom=top)
    cu.torso(M, COAT, b=2, bottom=30)
    cu.skirt(M, COAT, 14, top=42, b=2, flare=3, depth=14)              # faldones de la levita
    cu.opening(M, 30, 62, 6, 10, VEST)                                 # abierta sobre el chaleco
    for y in range(56, 62):
        for x in range(-2, 2): cu.front(M, x, y, SHIRT)                # pechera
    for y in (58, 59):
        for x in range(-3, 3): cu.front(M, x, y, (0.04, 0.04, 0.04), dz=1)   # corbatín
    for y in range(36, 56, 4):                                         # botones de oro
        for x in (-7, 6): cu.front(M, x, y, GOLD, dz=1)
    for i in range(9):                                                 # cadena de reloj
        cu.front(M, -5 + i, 44 - abs(i - 4) // 2, GOLD, dz=1)
    cu.neck(M, SHIRT)
    cu.arms(M, COAT, SKIN_I, b=2, cuff=GOLD)
    cu.head(M, SKIN_I, SKIN_I_SH)
    ns, nsh = cu.innsmouth(M, 2, SKIN_I, SKIN_I_SH)
    cu.hair_back(M, ns, HAIR, bottom=66)
    cu.sideburns(M, HAIR)
    for x in range(-7, 7):                                             # pelo negro peinado hacia atrás
        for z in range(-7, 7):
            t = M.top(x, z)
            if t is not None and t >= 79: M.put(x, t + 1, z, H, HAIR)
    cu.finish(M, 'obed_marsh', dict(MATS), flat=(cu.FISH_EYE, cu.FISH_PUPIL, GOLD), b=2, roughness=0.7, specular=0.35,
              skirt=True)


def castro():
    MATS.clear()
    SKIN = (0.52, 0.38, 0.28); SKIN_SH = (0.42, 0.30, 0.22)
    SHIRT = mat((0.80, 0.76, 0.66), 'lona'); SHIRT_SH = mat((0.64, 0.60, 0.52), 'lona')
    TRO = mat((0.30, 0.28, 0.24), 'lona'); SCARF = mat((0.60, 0.12, 0.10), 'lana')
    BEARD = (0.62, 0.60, 0.56); IDOL = (0.16, 0.24, 0.20)
    M = cu.new(1623)
    for s_, _, shin, _, _ in cu.sides():
        slab(M, shin, SKIN, 0, 3, 5 * s_, 2, 8, 8, 13, 12, ch=1)
    cu.legs(M, TRO, bottom=3)
    for k, v in list(M.V.items()):                                     # remangado
        if v[1] == TRO and k[1] < 15: v[1] = SKIN
    cu.torso(M, SHIRT, b=0, bottom=30)
    for (x, y, z), v in M.V.items():                                   # jirones
        if v[1] == SHIRT and M.noise(x, y, z, 2.5) > 0.78: v[1] = SKIN
        elif v[1] == SHIRT and (x + y) % 9 == 0: v[1] = SHIRT_SH
    for y in range(58, 63):
        for x in range(-6, 6): cu.front(M, x, y, SCARF, dz=1 if y == 58 else 0)
    cu.neck(M, SKIN)
    cu.arms(M, SHIRT, SKIN, fore=SKIN)
    for y in range(44, 52): cu.front(M, 0, y, (0.20, 0.16, 0.10), dz=1)   # cordel
    for dx in (-1, 0, 1):
        for dy in range(40, 44): M.put(dx, dy, 10, T, IDOL)            # el ídolo colgado
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, BEARD, eye=(0.10, 0.08, 0.06), brow_style='poblada')
    cu.mouth(M, (0.30, 0.16, 0.14))
    for x in range(-7, 7):                                             # barba gris rala
        for y in range(62, 69):
            if (x * 3 + y) % 3 != 0: cu.paint_face(M, x, y, BEARD)
    for x in range(-6, 6):                                             # arrugas
        if x % 3 == 0: cu.paint_face(M, x, 77, SKIN_SH)
    cu.hair_back(M, SKIN, BEARD, bottom=68)
    slab(M, H, BEARD, 79, 81, 0, -2, 14, 13, 11, 10, ch=2, over=False)
    cu.finish(M, 'castro', dict(MATS), flat=(BEARD, IDOL), roughness=0.85, specular=0.25)


if __name__ == '__main__':
    vaina()
    guardian()
    hija_marsh()
    sonambulo()
    idolo()
    gedney()
    obed()
    castro()
