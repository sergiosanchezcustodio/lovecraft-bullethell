"""El Profundo (hito 6.0), sustituye al prototipo `clasico`. Criatura sin ropa ni adornos
(CLAUDE.md: solo anatomía): hombre-pez encorvado, cabeza ancha y chata de pez adelantada,
ojos saltones a los lados, boca enorme, agallas, cresta de púas del cráneo a la cintura,
aletas en antebrazos y pantorrillas, manos y pies palmeados con garras. Lomo verde
grisáceo oscuro, flancos con escamas y vientre pálido.
Base de estilo 4 (tools/cuerpo.py, 48 voxels/m) con los pivotes humanos: anim_profundo.gd.
Variante `profundo_lanzador` (hito 6.3): azul pizarra con aletas turquesa, el que escupe
agua salada desde lejos.
Variante `profundo_anciano` (hito 6.4): Profundo anciano de Y'ha-nthlei, azul casi negro con
líneas bioluminiscentes en los flancos, ojos cian que brillan y cresta más alta (en el juego,
a escala 1,3).
Uso: python tools/gen_profundo.py [profundo|profundo_lanzador|profundo_anciano]  (sin argumento, todos)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu


def build(NAME):
    from cuerpo import slab, rslab, T, H

    BACK = (0.12, 0.18, 0.16); FLANK = (0.22, 0.31, 0.26); SCALE = (0.17, 0.24, 0.20)
    if NAME == 'profundo_lanzador':                                       # azul pizarra
        BACK = (0.10, 0.14, 0.20); FLANK = (0.20, 0.27, 0.34); SCALE = (0.15, 0.21, 0.27)
    OLD = NAME == 'profundo_anciano'
    if OLD:                                                               # azul casi negro, como el prototipo abisal
        BACK = (0.08, 0.11, 0.18); FLANK = (0.14, 0.20, 0.30); SCALE = (0.11, 0.16, 0.24)
    GLOW = (0.30, 0.90, 0.85)
    BELLY = (0.52, 0.55, 0.43); BELLY_SH = (0.44, 0.47, 0.37)
    FIN = (0.38, 0.30, 0.42); FIN_SH = (0.28, 0.22, 0.32)          # membranas violáceas
    if NAME == 'profundo_lanzador': FIN, FIN_SH = (0.22, 0.48, 0.50), (0.15, 0.36, 0.38)   # turquesa
    if OLD:
        BELLY, BELLY_SH = (0.34, 0.40, 0.46), (0.28, 0.33, 0.39)
        FIN, FIN_SH = (0.12, 0.26, 0.36), (0.08, 0.17, 0.25)
    CLAW = (0.82, 0.80, 0.68)
    EYE = (0.40, 0.95, 0.95) if OLD else (0.85, 0.80, 0.35); PUPIL = (0.03, 0.03, 0.02)
    MOUTH = (0.12, 0.05, 0.06); TOOTH = (0.88, 0.86, 0.76); GILL = (0.55, 0.18, 0.20)

    M = cu.new(1928)
    for s, leg, shin, _, _ in cu.sides():
        cx = 5.5 * s
        slab(M, shin, FLANK, 0, 3, cx, 3, 10, 9, 18, 15, ch=1)                 # pie largo palmeado
        for z in (11, 8, 5):                                                   # garras de los dedos
            M.put(int(cx) - 3, 0, z, shin, CLAW); M.put(int(cx) + 2, 0, z - 1, shin, CLAW)
        slab(M, shin, FLANK, 3, 14, cx, 0, 6, 8, 6.5, 8, ch=1)                # tobillo flaco
        slab(M, shin, FLANK, 14, 27, cx, -0.5, 8, 8.5, 8, 9, ch=1, zoff1=-1)  # pantorrilla
        slab(M, shin, FIN, 12, 24, cx, -5.5, 1, 1, 3, 1, ch=0)                # aleta de la pantorrilla
        slab(M, leg, FLANK, 27, 41, cx, 0, 9, 11, 9, 11, ch=1)                # muslo
    # tronco encorvado: el pecho y los hombros se adelantan y la espalda forma joroba
    slab(M, T, FLANK, 38, 46, 0, 0, 22, 20, 13, 13, ch=1)
    slab(M, T, FLANK, 46, 54, 0, 0.5, 20, 25, 13, 15, ch=1)
    slab(M, T, FLANK, 54, 62, 0, 0.5, 25, 21, 15, 13, ch=1)
    slab(M, T, BACK, 48, 61, 0, -6.5, 15, 13, 6, 6, ch=1, over=False)      # joroba
    slab(M, T, FLANK, 60, 64, 0, 1.5, 11, 10, 10, 9, ch=1)                  # cuello grueso
    # colores: lomo oscuro, vientre pálido y escamas en los flancos
    for (x, y, z), v in M.V.items():
        if v[0] != T and v[0] not in ('leg_l', 'leg_r', 'shin_l', 'shin_r'): continue
        if v[1] != FLANK: continue
        if z <= -3: v[1] = BACK
        elif z >= 4 and abs(x + 0.5) < 7 and v[0] == T: v[1] = BELLY if y % 3 else BELLY_SH
        elif (x + y + (y // 2) * 2 + z) % 4 == 0: v[1] = SCALE
    # brazos largos y flacos, colgando por delante (las manos llegan a la rodilla)
    for s, _, _, arm, fa in cu.sides():
        cx = 15.5 * s
        slab(M, arm, FLANK, 46, 61, cx, 1, 5.5, 7, 6, 7, ch=1)
        slab(M, fa, FLANK, 35, 47, cx * 1.02, 1.5, 4.5, 6, 5, 6.5, ch=1)
        slab(M, fa, FIN_SH, 36, 45, cx * 1.02 + 3.5 * s, -2.5, 1, 1, 3, 1, ch=0)  # aleta del antebrazo, hacia fuera
        cu.hand_(M, fa, cx * 1.02, FLANK)
        for k in [k for k, v in M.V.items() if v[0] == fa and k[1] < 26]: pass
        for (x, y, z), v in list(M.V.items()):                                 # uñas en garra
            if v[0] == fa and y in (23, 24) and v[1] == FLANK: v[1] = CLAW
        for (x, y, z), v in list(M.V.items()):                                 # membrana entre los dedos
            if v[0] == fa and 26 <= y <= 28 and v[1] != FLANK: v[1] = FIN_SH
    # cabeza de pez: ancha, chata y baja, adelantada sobre el cuello
    HZ = 2
    rslab(M, H, FLANK, 62, 76, 0, HZ, 17, 17, r=4, rt=5, rb=2)
    rslab(M, H, BELLY, 60, 66, 0, HZ + 1.5, 14, 14, r=4, rt=0, rb=2)      # garganta y mandíbula pálidas
    rslab(M, H, BACK, 72, 77, 0, HZ - 2, 13, 13, r=4, rt=3, rb=0)         # coronilla oscura
    zf = HZ + 8.5
    for x in range(-7, 7):                                                # boca enorme, de lado a lado
        M.put(x, 66, int(zf), H, MOUTH)
        if x % 2 == 0 and abs(x + 0.5) < 6: M.put(x, 67, int(zf), H, TOOTH); M.put(x, 65, int(zf), H, TOOTH)
    for s in (-1, 1):                                                     # ojos saltones a los lados
        ex = 8 * s - (1 if s > 0 else 0)
        for y in range(69, 75):
            for z in range(HZ + 2, HZ + 8):
                if (y in (69, 74)) and z in (HZ + 2, HZ + 7): continue
                M.put(ex + s, y, z, H, EYE); M.put(ex + 2 * s, y, z, H, EYE) if 70 <= y <= 73 and HZ + 3 <= z <= HZ + 6 else None
        for y in (71, 72):
            for z in (HZ + 4, HZ + 5): M.put(ex + 3 * s, y, z, H, PUPIL)
        for z in range(HZ + 2, HZ + 8): M.put(ex + s, 75, z, H, BACK)     # párpado
        for y in (63, 65, 67):                                            # agallas
            for z in range(HZ - 4, HZ + 1): M.put(ex + s, y, z, H, GILL)
    # cresta de púas: del cráneo a la cintura, en abanico con membrana
    for y in range(44, 78):
        if y >= 62:
            zb = min((z for (x, yy, z), v in M.V.items() if yy == y and x in (0, -1) and v[0] == H), default=None)
            part = H
        else:
            zb = min((z for (x, yy, z), v in M.V.items() if yy == y and x in (0, -1) and v[0] == T), default=None)
            part = T
        if zb is None: continue
        h = (3 + (y % 4 == 0) * 3) if OLD else (2 + (y % 4 == 0) * 2)
        for k in range(1, h + 1):
            for x in (-1, 0): M.put(x, y, zb - k, part, FIN if k < h else FIN_SH)

    if OLD:                                                               # líneas bioluminiscentes y ojos que brillan
        for (x, y, z), v in list(M.V.items()):                            # listas nuevas: slab comparte la misma
            if v[1] == EYE: M.V[(x, y, z)] = [v[0], EYE, 1]
            elif v[1] in (FLANK, SCALE, BACK) and lateral(v[0], x, y, z): M.V[(x, y, z)] = [v[0], GLOW, 1]
            elif v[1] == FIN and k_dot(x, y, z): M.V[(x, y, z)] = [v[0], GLOW, 1]
    piv = cu.hunch(M, k=0.4, head_drop=4)
    cu.finish(M, NAME, {BACK: 'piel', FLANK: 'piel', SCALE: 'piel', BELLY: 'piel'} if not OLD else {BACK: 'piel', FLANK: 'piel', SCALE: 'piel'},
              flat=(EYE, PUPIL, MOUTH, TOOTH, GILL, CLAW, GLOW), extra_pivots=piv, roughness=0.45, specular=0.5)


def lateral(part, x, y, z):
    """Línea lateral de pez en los costados del tronco y anillos en brazos y piernas."""
    if part == 'torso': return y in (47, 52, 57) and x % 3 != 0
    if part in ('arm_l', 'arm_r', 'fore_l', 'fore_r', 'shin_l', 'shin_r', 'leg_l', 'leg_r'): return y % 8 == 0 and (x + z) % 3 != 0
    return False


def k_dot(x, y, z):
    """Puntos de luz en las puntas de la cresta."""
    return (x + y) % 5 == 0


for name in sys.argv[1:] or ['profundo', 'profundo_lanzador', 'profundo_anciano']:
    build(name)
