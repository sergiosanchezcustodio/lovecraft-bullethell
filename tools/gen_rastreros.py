"""Compañeros de suelo (D-36): cabra de los bosques, araña de Tíndalos, Mini-Mi-Go, serpiente
de Yig, Mini-Dhole y pez de Innsmouth. Estilo 4 (tramos de caras planas, detalles pintados),
a 48 voxels por metro; miran hacia +Z.
- cabra, tindalos, migo: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail (anim_cuadrupedo.gd).
- yig, dhole: head, s1..s4 (anim_serpiente.gd).
- pez: body, leg_l, leg_r, fin_l, fin_r, tail (anim_pez.gd).
Uso: python tools/gen_rastreros.py [cabra|tindalos|migo|yig|dhole|pez]
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import slab, rslab, new
import materiales

B, H = 'body', 'head'


def face_fn(M, part=H):
    def face(x, y, c, glow=0):
        z = M.front(x, y)
        if z is not None: M.put(x, y, z, part, c, glow)
    return face


def cabra():
    """Cabrita aparentemente inocente: blanca y lanuda con la cara y las patas pardas, cuernos
    curvados hacia atrás, perilla, orejas caídas y ojos amarillos de pupila horizontal (lo único
    que la delata). Pezuñas negras y rabito corto."""
    WOOL = (0.90, 0.88, 0.82); TAN = (0.56, 0.42, 0.30); HORN = (0.62, 0.58, 0.50)
    HOOF = (0.12, 0.10, 0.10); EYE = (0.95, 0.80, 0.20); PUPIL = (0.05, 0.05, 0.05)
    M = new(7101)
    for part, x, z in (('leg_fl', -3.5, 7), ('leg_fr', 3.5, 7), ('leg_bl', -3.5, -7), ('leg_br', 3.5, -7)):
        slab(M, part, HOOF, 0, 2, x, z, 3, 3, 3, 3, ch=0)
        slab(M, part, TAN, 2, 11, x, z, 3, 3.5, 3, 3.5, ch=1)
    slab(M, B, WOOL, 10, 20, 0, 0, 11, 12, 21, 21, ch=3)
    slab(M, 'tail', WOOL, 17, 21, 0, -11.5, 3, 2, 2, 2, ch=0)
    slab(M, H, WOOL, 17, 26, 0, 11, 8, 7, 7, 7, ch=2)
    slab(M, H, TAN, 16, 22, 0, 15.5, 5, 5, 4, 4, ch=1)                         # hocico pardo
    slab(M, H, WOOL, 12, 16, 0, 16, 2, 1, 2, 2, ch=0)                          # perilla
    for s in (-1, 1):
        slab(M, H, TAN, 21, 23, 5 * s, 11, 3, 3, 2, 2, ch=0)                  # orejas caídas
        for i in range(6):                                                    # cuernos hacia atrás
            y, z = 26 + min(i, 3), 11 - i
            M.put(2 * s - (1 if s < 0 else 0), y, z, H, HORN)
            M.put(3 * s - (1 if s < 0 else 0), y, z, H, HORN)
    face = face_fn(M)
    for x in (-3, -2, 1, 2): face(x, 23, EYE)
    for x in (-3, 2): face(x, 23, PUPIL)
    materiales.texturize(M, {WOOL: 'borreguillo', TAN: 'pelo'})
    piv = {'body': [0, 11, 0], 'head': [0, 19, 9], 'tail': [0, 18, -11],
           'leg_fl': [-3.5, 11, 7], 'leg_fr': [3.5, 11, 7], 'leg_bl': [-3.5, 11, -7], 'leg_br': [3.5, 11, -7]}
    return M, piv, (0.9, 0.25)


def tindalos():
    """Araña que no respeta la geometría: cuerpo de ángulos rectos, cian oscuro y azulado,
    con aristas de un azul que brilla, ocho patas rectas y quebradas en ángulo, ocho ojos
    blancos en fila y un abdomen de cubo girado."""
    BODY = (0.14, 0.22, 0.30); EDGE = (0.35, 0.85, 1.0); LEG = (0.10, 0.14, 0.20)
    EYE = (0.92, 0.98, 1.0)
    M = new(7202)
    # ocho patas, dos por pieza, rectas y quebradas en ángulo recto
    for part, s, zs in (('leg_fl', -1, (6, 3)), ('leg_fr', 1, (6, 3)), ('leg_bl', -1, (-1, -4)), ('leg_br', 1, (-1, -4))):
        for z in zs:
            for i in range(7):
                M.put(s * (4 + i) - (1 if s < 0 else 0), 8, z, part, LEG)          # tramo horizontal
            for y in range(0, 9):
                M.put(s * 10 - (1 if s < 0 else 0), y, z, part, EDGE if y == 0 else LEG, 1 if y == 0 else 0)
    slab(M, B, BODY, 5, 11, 0, 3, 8, 8, 8, 8, ch=0)                           # cefalotórax cúbico
    slab(M, 'tail', BODY, 5, 14, 0, -6, 9, 9, 9, 9, ch=0)                      # abdomen de cubo
    for (x, y, z), v in M.V.items():                                         # aristas que brillan
        if v[0] in (B, 'tail'):
            if sum(1 for q in ((x + 1, y, z), (x - 1, y, z)) if q not in M.V) \
               + sum(1 for q in ((x, y + 1, z), (x, y - 1, z)) if q not in M.V) \
               + sum(1 for q in ((x, y, z + 1), (x, y, z - 1)) if q not in M.V) >= 2:
                v[1] = EDGE; v[2] = 1
    slab(M, H, BODY, 6, 11, 0, 8.5, 6, 6, 3, 3, ch=0)
    face = face_fn(M)
    for x in (-3, -1, 0, 2):
        face(x, 9, EYE, 1); face(x, 7, EYE, 1)
    piv = {'body': [0, 8, 0], 'head': [0, 8, 7], 'tail': [0, 9, -2],
           'leg_fl': [-4, 8, 4], 'leg_fr': [4, 8, 4], 'leg_bl': [-4, 8, -2], 'leg_br': [4, 8, -2]}
    return M, piv, (0.4, 0.5)


def migo():
    """Crustáceo espacial diminuto: cuerpo rosado de cangrejo con placas, cabeza de racimo
    ovalado con zarcillos que brillan en violeta, dos alas membranosas plegadas a la espalda,
    patas finas articuladas y dos pinzas delante."""
    SHELL = (0.80, 0.52, 0.50); SHELL_D = (0.62, 0.38, 0.38); HEAD = (0.70, 0.50, 0.62)
    GLOW = (0.80, 0.55, 1.0); WING = (0.55, 0.50, 0.58); LEG = (0.66, 0.42, 0.42)
    M = new(7303)
    for part, x, z in (('leg_fl', -5, 4), ('leg_fr', 5, 4), ('leg_bl', -5, -3), ('leg_br', 5, -3)):
        s = 1 if x > 0 else -1
        for i in range(4): M.put(x + s * i, 6 - i // 2, z, part, LEG)
        for y in range(0, 4): M.put(x + s * 4, y, z, part, LEG)
    rslab(M, B, SHELL, 3, 10, 0, 0, 11, 11, r=3, rt=2.5, rb=2)
    for (x, y, z), v in M.V.items():
        if v[0] == B and (y == 7 or abs(x + 0.5) > 4): v[1] = SHELL_D            # placas
    for s in (-1, 1):                                                          # pinzas delante
        slab(M, B, SHELL_D, 4, 7, 4 * s, 8, 3, 3, 4, 4, ch=0)
        M.put(4 * s - (1 if s < 0 else 0) + s, 7, 10, B, SHELL_D)
    rslab(M, H, HEAD, 9, 17, 0, 1, 7, 8, r=2.5, rt=3, rb=1.5)                   # cabeza en racimo
    for (x, y, z), v in M.V.items():
        if v[0] == H and M.hsh(x, y, z) > 0.8: v[1] = GLOW; v[2] = 1
    for s in (-1, 1):                                                          # zarcillos
        for i in range(4): M.put(2 * s - (1 if s < 0 else 0), 17 + i, 2 - i // 2, H, GLOW, 1)
    slab(M, 'tail', WING, 8, 12, 0, -6, 12, 14, 2, 2, ch=0)                    # alas plegadas
    piv = {'body': [0, 3, 0], 'head': [0, 10, 1], 'tail': [0, 10, -5],
           'leg_fl': [-5, 6, 4], 'leg_fr': [5, 6, 4], 'leg_bl': [-5, 6, -3], 'leg_br': [5, 6, -3]}
    return M, piv, (0.5, 0.45)


def _worm(M, cols, n_seg, seg_len, w0, w1, h0, h1, zstart, rise=0.0):
    """Cuerpo en segmentos s1..s4 hacia atrás desde la cabeza, que se adelgaza."""
    piv = {}
    total = n_seg * seg_len
    for k in range(n_seg):
        part = 's%d' % (k + 1)
        z1 = zstart - k * seg_len
        z0 = z1 - seg_len
        for z in range(z0, z1 + 1):
            t = (zstart - z) / total
            w = w0 + (w1 - w0) * t
            h = h0 + (h1 - h0) * t
            y0 = rise * (1 - t) if rise else 0.0
            c = cols[k % len(cols)]
            slab(M, part, c, int(y0), int(y0 + h), 0, z + 0.5, w, w, 1, 1, ch=1)
        piv[part] = [0, 1, z1]
    return piv


def yig():
    """Serpiente que mira demasiado fijamente: verde oliva con rombos oscuros por el lomo,
    vientre crema, cabeza de flecha con escamas sobre los ojos, ojos dorados enormes con
    pupila de rendija que brillan, y la lengua bífida roja."""
    OLIVE = (0.40, 0.46, 0.22); DIAMOND = (0.20, 0.24, 0.12); BELLY = (0.84, 0.78, 0.56)
    EYE = (1.0, 0.80, 0.18); PUPIL = (0.03, 0.03, 0.02); TONGUE = (0.85, 0.15, 0.18)
    M = new(7404)
    piv = _worm(M, [OLIVE], 4, 9, 7, 3, 5, 3, 4)
    for (x, y, z), v in M.V.items():
        if y == 0: v[1] = BELLY
        elif y >= 2 and (z % 6) in (0, 1, 2) and abs(x + 0.5) <= (1.5 - abs((z % 6) - 1)): v[1] = DIAMOND
    slab(M, H, OLIVE, 0, 5, 0, 7, 7, 6, 7, 7, ch=2)                           # cabeza de flecha
    slab(M, H, OLIVE, 0, 4, 0, 11.5, 5, 4, 2, 2, ch=1)
    for (x, y, z), v in M.V.items():
        if v[0] == H and y == 0: v[1] = BELLY
    for s in (-1, 1):
        x = 3 if s > 0 else -4
        for y in (3, 4):
            M.put(x, y, 8, H, EYE, 1); M.put(x, y, 9, H, EYE, 1)
        M.put(x, 3, 9, H, PUPIL); M.put(x, 4, 9, H, PUPIL)
        M.put(x, 5, 8, H, DIAMOND); M.put(x, 5, 9, H, DIAMOND)                  # escama sobre el ojo
    M.put(0, 1, 13, H, TONGUE); M.put(0, 1, 14, H, TONGUE)
    M.put(-1, 1, 15, H, TONGUE); M.put(1, 1, 15, H, TONGUE)
    piv['head'] = [0, 1, 4]
    return M, piv, (0.5, 0.45)


def dhole():
    """Gusano gigantesco reducido a mascota: segmentos anillados gris violáceo y viscosos,
    la parte delantera erguida, y la cabeza es una boca redonda con anillos de dientes y un
    brillo rosado dentro."""
    SKIN = (0.46, 0.40, 0.48); RING = (0.34, 0.28, 0.36); TOOTH = (0.92, 0.88, 0.76)
    MAW = (0.55, 0.12, 0.20); GLOW = (1.0, 0.45, 0.55)
    M = new(7505)
    piv = _worm(M, [SKIN, RING], 4, 5, 9, 5, 8, 5, 2, rise=0.0)
    for (x, y, z), v in M.V.items():
        if z % 3 == 0: v[1] = RING
    # cabeza erguida: cilindro que sube, boca hacia delante y arriba
    rslab(M, H, SKIN, 0, 16, 0, 5, 10, 9, r=4, rt=3, rb=2)
    for (x, y, z), v in M.V.items():
        if v[0] == H and y % 4 == 0: v[1] = RING
    face = face_fn(M)
    for x in range(-4, 4):
        for y in range(6, 15):
            dx, dy = x + 0.5, y - 10
            d = (dx * dx + dy * dy) ** 0.5
            if d < 1.6: face(x, y, GLOW, 1)
            elif d < 2.8: face(x, y, MAW)
            elif d < 3.8: face(x, y, TOOTH)
    piv['head'] = [0, 0, 3]
    materiales.texturize(M, {SKIN: 'piel', RING: 'piel'})
    return M, piv, (0.35, 0.55)


def pez():
    """Pez con patas que se cree humano: pez gris verdoso de escamas, vientre plateado, ojos
    saltones y bobos, labios gruesos, aletas como bracitos, y dos piernas humanas con
    pantalón corto de rayas y zapatos de charol (se cree un caballero). Pajarita roja."""
    SCALE = (0.40, 0.52, 0.50); SCALE_D = (0.28, 0.38, 0.38); BELLY = (0.78, 0.82, 0.80)
    EYE_W = (0.95, 0.95, 0.88); PUPIL = (0.04, 0.04, 0.04); LIP = (0.72, 0.46, 0.46)
    FIN = (0.48, 0.62, 0.58); PANTS = (0.30, 0.30, 0.40); STRIPE = (0.72, 0.70, 0.64)
    SHOE = (0.08, 0.07, 0.08); SKIN = (0.66, 0.70, 0.62); BOW = (0.80, 0.14, 0.14)
    M = new(7606)
    for part, s in (('leg_l', -1), ('leg_r', 1)):
        slab(M, part, SHOE, 0, 2, 2.5 * s, 1, 3, 3, 5, 5, ch=0)
        slab(M, part, SKIN, 2, 6, 2.5 * s, 0, 2, 2, 2, 2, ch=0)
        slab(M, part, PANTS, 6, 10, 2.5 * s, 0, 3.5, 3.5, 3.5, 3.5, ch=0)
        for (x, y, z), v in M.V.items():
            if v[0] == part and v[1] == PANTS and x % 2 == 0: v[1] = STRIPE
    rslab(M, B, SCALE, 9, 24, 0, 0, 9, 14, r=3, rt=4, rb=3)                    # pez de pie
    for (x, y, z), v in M.V.items():
        if v[0] != B: continue
        if z >= 4 and y < 20: v[1] = BELLY
        elif (y + (z % 2)) % 3 == 0: v[1] = SCALE_D                            # escamas
    face = face_fn(M, B)
    for s in (-1, 1):                                                          # ojos saltones a los lados
        x = 4 if s > 0 else -5
        for y in (19, 20):
            for z in (3, 4): M.put(x, y, z, B, EYE_W)
        M.put(x + s, 20, 4, B, PUPIL)
    for x in (-2, -1, 0, 1): face(x, 16, LIP); face(x, 15, LIP)                 # labios gruesos
    for x in (-1, 0): face(x, 12, BOW)
    face(-2, 12, BOW); face(1, 12, BOW)
    for part, s in (('fin_l', -1), ('fin_r', 1)):
        slab(M, part, FIN, 11, 15, 5.5 * s, 1, 2, 1, 4, 3, ch=0)
    slab(M, 'tail', FIN, 11, 20, 0, -8, 2, 2, 3, 6, ch=0)                      # aleta de la cola
    piv = {'body': [0, 9, 0], 'leg_l': [-2.5, 9, 0], 'leg_r': [2.5, 9, 0],
           'fin_l': [-5, 14, 1], 'fin_r': [5, 14, 1], 'tail': [0, 15, -7]}
    return M, piv, (0.4, 0.5)


MODELS = {'cabra': cabra, 'tindalos': tindalos, 'migo': migo, 'yig': yig, 'dhole': dhole, 'pez': pez}
for name in (sys.argv[1:] or MODELS):
    M, piv, (rough, spec) = MODELS[name]()
    n = M.export('models/%s.json' % name, piv, jitter=0.0, pivots_in_voxels=True, roughness=rough, specular=spec)
    print(name, n, 'voxels')
