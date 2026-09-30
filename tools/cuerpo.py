"""Base común de los personajes humanos, estilo 4 (aprobado el 28-09-2026 con Dyer).

Anatomía realista de caras planas a 48 voxels por metro: tramos que se estrechan poco a poco
(muslo -> rodilla -> pantorrilla -> tobillo; pecho -> cintura -> cadera; brazo -> antebrazo ->
muñeca) con las aristas verticales achaflanadas, sin formas redondas (dejan escalones sueltos)
ni grano por bloques (hace rayas). Cabeza algo grande, manoplas en pinza estilo LEGO, codos y
rodillas articulados. Las texturas salen del material de cada color (tools/materiales.py).

Coordenadas en voxels (1/48 m), el modelo mira hacia +Z. Cada generador pone encima su ropa,
su sombrero y su cara; las piezas van en este orden (lo posterior pisa a lo anterior):
  calzado y piernas -> tronco -> brazos -> cabeza, cara y sombrero -> pelo -> finish()

`b` (bulk) ensancha el tronco b voxels y separa los brazos b/2 a cada lado: Dyer (parka) es
0, un traje -2, un corpulento +3.

Cuerpo de mujer (29-09-2026): las mismas alturas y articulaciones (las animaciones son las
mismas), con hombros más estrechos, cintura marcada, algo de cadera, pecho insinuado solo
con el volumen del tronco, piernas y brazos más finos y los brazos más cerca del cuerpo
(ARM_X_F). Piezas: shoes_f/boots, legs_f, torso_f, arms(..., ax=ARM_X_F, slim=True),
bob() para la media melena y finish(..., ax=ARM_X_F).
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model
import materiales

T, H = 'torso', 'head'
KNEE, HIP, ELBOW, SHOULDER, NECK = 27, 40, 46, 59, 64
ARM_X = 15.0                                      # separación de los brazos (hombre, b = 0)
ARM_X_F = 13.0                                    # mujer
EYE = (0.08, 0.06, 0.05); EYE_W = (0.93, 0.91, 0.87)


def new(seed):
    return Model(S=3, seed=seed)                  # voxel_size = 1/48 m


def slab(M, part, col, y0, y1, cx, cz, w0, w1, d0, d1, ch=2, over=True, zoff0=0.0, zoff1=0.0, r=None):
    """Tramo que se estrecha: en cada altura, un rectángulo de ancho w y fondo d (de w0/d0
    abajo a w1/d1 arriba) con las cuatro aristas verticales achaflanadas `ch` voxels.
    zoff desplaza el tramo adelante o atrás con la altura (pantorrilla, pecho).
    En la cabeza (sombreros, pelo, barba) las esquinas son redondas, de radio ch + 1,5
    (o `r`), en lugar del chaflán."""
    if r is None and part == H and ch > 0: r = ch + 1.5
    for y in range(y0, y1):
        t = (y - y0 + 0.5) / max(y1 - y0, 1)
        w = w0 + (w1 - w0) * t
        d = d0 + (d1 - d0) * t
        zc = cz + zoff0 + (zoff1 - zoff0) * t
        xa, xb = int(round(cx - w / 2)), int(round(cx + w / 2))
        za, zb = int(round(zc - d / 2)), int(round(zc + d / 2))
        for x in range(xa, xb):
            for z in range(za, zb):
                ex = min(x - xa, xb - 1 - x)
                ez = min(z - za, zb - 1 - z)
                if r:
                    qx, qz = r - 0.5 - ex, r - 0.5 - ez
                    if qx > 0 and qz > 0 and qx * qx + qz * qz > r * r: continue
                elif ex + ez < ch: continue                 # chaflán
                M.put(x, y, z, part, col, 0, over)


def rslab(M, part, col, y0, y1, cx, cz, w, d, r=3.0, rt=3.0, rb=2.0, over=True, zoff=0.0):
    """Bloque redondeado (cabezas, gorros, barbas): sección de rectángulo con esquinas de
    radio r, y arriba y abajo se encoge como un cuarto de círculo de radio rt / rb.
    Con radios de 2 a 4 voxels la forma se lee redonda sin dejar escalones sueltos."""
    for y in range(y0, y1):
        yc = y + 0.5
        k = 0.0
        if rt > 0 and yc > y1 - rt: k = rt - math.sqrt(max(0.0, rt * rt - (yc - (y1 - rt)) ** 2))
        if rb > 0 and yc < y0 + rb: k = max(k, rb - math.sqrt(max(0.0, rb * rb - ((y0 + rb) - yc) ** 2)))
        hw, hd = w / 2 - k, d / 2 - k
        if hw <= 0 or hd <= 0: continue
        rr = max(0.0, min(r, hw, hd))
        zc = cz + zoff * (y - y0) / max(y1 - y0, 1)
        for x in range(int(math.floor(cx - hw)), int(math.ceil(cx + hw))):
            for z in range(int(math.floor(zc - hd)), int(math.ceil(zc + hd))):
                px, pz = abs(x + 0.5 - cx), abs(z + 0.5 - zc)
                if px > hw or pz > hd: continue
                qx, qz = px - (hw - rr), pz - (hd - rr)
                if qx > 0 and qz > 0 and qx * qx + qz * qz > rr * rr: continue
                M.put(x, y, z, part, col, 0, over)


def sides():
    """(signo, pierna, espinilla, brazo, antebrazo) para izquierda y derecha."""
    return ((-1, 'leg_l', 'shin_l', 'arm_l', 'fore_l'), (1, 'leg_r', 'shin_r', 'arm_r', 'fore_r'))


# ---------------- calzado ----------------

def boots(M, col, sole, top=11, cuff=None, slim=False):
    """Botas: suela, pie con puntera y caña hasta `top` (cuff: vuelta de 2 voxels encima).
    slim: botas de mujer, más finas y con la caña ajustada."""
    for s, _, shin, _, _ in sides():
        if slim:
            cx = 4.5 * s
            slab(M, shin, sole, 0, 1, cx, 1.5, 7, 7, 13, 13, ch=1)
            slab(M, shin, col, 1, 4, cx, 1.5, 7, 7, 13, 11, ch=1)
            slab(M, shin, col, 4, top, cx, 0, 7, 8, 8, 8.5, ch=1)
            if cuff is not None:
                slab(M, shin, cuff, top, top + 2, cx, 0, 8.5, 8.5, 9, 9, ch=1)
            continue
        cx = 5 * s
        slab(M, shin, sole, 0, 2, cx, 1, 9, 9, 15, 15, ch=1)
        slab(M, shin, col, 2, 5, cx, 1, 9, 9, 15, 14, ch=1)
        slab(M, shin, col, 5, top, cx, -0.5, 9, 9, 10, 10, ch=1)
        if cuff is not None:
            slab(M, shin, cuff, top, top + 2, cx, -0.5, 10.5, 10.5, 11.5, 11.5, ch=1)
    return top + (2 if cuff is not None else 0)


def shoes(M, col, sole):
    """Zapatos bajos, algo más finos que las botas. Devuelve dónde empieza la pernera."""
    for s, _, shin, _, _ in sides():
        cx = 5 * s
        slab(M, shin, sole, 0, 1, cx, 1.5, 8, 8, 14, 14, ch=1)
        slab(M, shin, col, 1, 4, cx, 1.5, 8, 7.5, 14, 12, ch=1)
    return 4


# ---------------- piernas ----------------

def legs(M, col, bottom=13, thigh=None):
    """Perneras desde `bottom` (lo que deje el calzado) hasta la cadera: tobillo -> gemelo ->
    rodilla en la espinilla y muslo encima. thigh: color del muslo si es distinto."""
    for s, leg, shin, _, _ in sides():
        cx = 5 * s
        if bottom < 13:
            slab(M, shin, col, bottom, 13, cx, 0, 8.5, 7.5, 9, 8, ch=1)                # bajo de la pernera
        slab(M, shin, col, 13, 20, cx, 0, 7, 8.5, 7.5, 8.5, ch=1, zoff0=0, zoff1=-0.5)   # tobillo -> gemelo
        slab(M, shin, col, 20, 27, cx, 0, 8.5, 8, 8.5, 8, ch=1, zoff0=-0.5, zoff1=0)     # gemelo -> rodilla
        slab(M, leg, thigh or col, 27, 41, cx * 1.04, 0, 8.5, 10.5, 8.5, 10, ch=1)       # muslo


def shoes_f(M, col, sole, heel=None):
    """Zapatos de mujer: más finos, con un tacón bajo detrás. Devuelve dónde empieza la pierna."""
    for s, _, shin, _, _ in sides():
        cx = 4.5 * s
        slab(M, shin, sole, 0, 1, cx, 2, 6.5, 6.5, 12, 12, ch=1)
        slab(M, shin, col, 1, 3, cx, 2, 6.5, 6, 12, 10, ch=1)
        slab(M, shin, heel or sole, 0, 2, cx, -3, 4, 4, 3, 3, ch=0)                   # tacón
    return 3


def legs_f(M, col, bottom=3, thigh=None):
    """Piernas de mujer: tobillo fino, gemelo, rodilla y muslo algo más ancho arriba."""
    for s, leg, shin, _, _ in sides():
        cx = 4.5 * s
        if bottom < 12:
            slab(M, shin, col, bottom, 12, cx, 0.5, 5, 6, 5.5, 6.5, ch=1)               # tobillo
        slab(M, shin, col, max(bottom, 12), 20, cx, 0.3, 6, 7.5, 6.5, 7.5, ch=1, zoff1=-0.5)   # gemelo
        slab(M, shin, col, 20, 27, cx, 0, 7.5, 6.5, 7.5, 7, ch=1, zoff0=-0.5)          # a la rodilla
        slab(M, leg, thigh or col, 27, 41, cx * 1.05, 0, 7, 10, 7.5, 10, ch=1)          # muslo


# ---------------- tronco ----------------

def torso(M, col, b=0, hip=None, bottom=38):
    """Cadera (desde `bottom`), cintura, pecho que se abre y hombros que caen."""
    slab(M, T, hip or col, bottom, 45, 0, 0, 24 + b, 23 + b, 13, 13, ch=1)
    slab(M, T, col, 45, 50, 0, 0, 22 + b, 21 + b, 12.5, 12.5, ch=1)
    slab(M, T, col, 50, 58, 0, 0.3, 21 + b, 25 + b, 12.5, 14, ch=1)
    slab(M, T, col, 58, 61, 0, 0.3, 25 + b, 20 + b, 14, 12, ch=1)


def torso_f(M, col, b=0, hip=None, bottom=38, bust=None):
    """Tronco de mujer: cadera, cintura estrecha, pecho (solo volumen: algo más de fondo y
    adelantado) y hombros estrechos que caen. bust: color de la pechera si es distinto."""
    slab(M, T, hip or col, bottom, 45, 0, 0, 22 + b, 19 + b, 13, 12, ch=1)
    slab(M, T, col, 45, 50, 0, 0, 18.5 + b, 18 + b, 11.5, 11.5, ch=1)
    slab(M, T, bust or col, 50, 57, 0, 0.8, 18.5 + b, 20.5 + b, 12.5, 14, ch=1, zoff0=0.2, zoff1=0.6)
    slab(M, T, col, 57, 61, 0, 0.3, 20.5 + b, 17 + b, 13, 11, ch=1)


def skirt(M, col, bottom, top=45, b=0, flare=3, depth=13):
    """Faldón de abrigo, sotana o vestido que cae del tronco (parte torso: las piernas se
    mueven debajo), ensanchándose `flare` voxels hacia abajo."""
    slab(M, T, col, bottom, top, 0, 0, 24 + b + flare, 24 + b, depth + flare * 0.8, depth, ch=1)


def belt(M, col, y=44, b=0, h=2, buckle=None):
    slab(M, T, col, y, y + h, 0, 0, 22.8 + b, 22.2 + b, 13.2, 13.2, ch=1)
    if buckle is not None:
        for x in (-1, 0):
            for yy in range(y, y + h):
                z = M.front(x, yy)
                if z is not None: M.put(x, yy, z + 1, T, buckle)


def neck(M, skin):
    slab(M, T, skin, 62, 65, 0, 0, 8, 8, 8, 8, ch=1, over=False)


def front(M, x, y, col, dz=0, part=T):
    """Pinta (dz=0) o pone encima (dz=1) un voxel en la cara delantera de la columna (x, y)."""
    z = M.front(x, y)
    if z is not None:
        M.put(x, y, z + dz, part, col)


def back(M, x, y, col, part=T):
    """Pinta el voxel de la espalda de la columna (x, y)."""
    for z in range(-30, 30):
        if (x, y, z) in M.V:
            M.put(x, y, z, part, col)
            return


def opening(M, y0, y1, w0, w1, col, x0=0.0):
    """Abertura en V (o en trapecio) pintada en la pechera: de ancho w0 abajo a w1 arriba,
    centrada en x = x0 - 0,5 (el eje de simetría del cuerpo)."""
    for y in range(y0, y1):
        t = (y - y0 + 0.5) / max(y1 - y0, 1)
        w = w0 + (w1 - w0) * t
        for x in range(int(round(x0 - w / 2)), int(round(x0 + w / 2))):
            front(M, x, y, col)


# ---------------- brazos ----------------

def arms(M, sleeve, hand, b=0, fore=None, cuff=None, cuff_wide=True, mitten=False, ax=ARM_X, slim=False):
    """Mangas (brazo y antebrazo), puño y manos (hand()). fore: color del antebrazo si es
    distinto (remangado). cuff: color del puño; ancho (de abrigo, cuff_wide) o fino (de
    camisa). mitten: manoplas (dedos juntos) en lugar de mano o guante. ax: separación de
    los brazos (ARM_X_F para mujer); slim: brazos más finos."""
    k = 0.85 if slim else 1.0
    for s, _, _, arm, fa in sides():
        cx = (ax + b / 2) * s
        slab(M, arm, sleeve, 46, 61, cx, 0, 7 * k, 8.5 * k, 7.5 * k, 8.5 * k, ch=1)
        slab(M, fa, fore or sleeve, 37, 46, cx * 1.02, 0.5, 6.5 * k, 7 * k, 7 * k, 7.5 * k, ch=1)
        if cuff is not None:
            if cuff_wide: slab(M, fa, cuff, 35, 38, cx * 1.02, 0.5, 8.5, 8.5, 9, 9, ch=1)
            else: slab(M, fa, cuff, 35, 37, cx * 1.02, 0.5, 7, 7, 7.5, 7.5, ch=1)
        else:
            slab(M, fa, fore or sleeve, 35, 37, cx * 1.02, 0.5, 6.5 * k, 6.5 * k, 7 * k, 7 * k, ch=1)
        hand_(M, fa, cx * 1.02, hand, mitten)


# Dedos de atrás (meñique) a delante (índice): (primera z, largo por debajo de la palma)
FINGERS = ((-4, 3), (-2, 4), (0, 5), (2, 4))


def hand_(M, part, hx, col, mitten=False):
    """Mano en reposo con el brazo caído (referencia del autor, 28-09-2026): la palma mira al
    muslo, los cuatro dedos cuelgan (2 voxels de ancho, el corazón más largo, separados por un
    borde más oscuro) y se curvan hacia la palma en la punta; el pulgar va delante, hacia
    abajo y algo hacia dentro. Tan ancha como la manga de delante a atrás y gruesa, a lo
    muñeco. Con mitten, los dedos van juntos (manopla).
    Coordenadas locales: u = hacia dentro (hacia el muslo); z = hacia delante."""
    inward = -1 if hx > 0 else 1
    x0 = int(round(hx))
    dark = tuple(c * 0.84 for c in col)

    def put(u, y, z, c=col):
        M.put(x0 + inward * u, y, z, part, c)

    for y in range(34, 37):                                   # muñeca (asoma 1 fila bajo el puño)
        for u in (-1, 0, 1):
            for z in range(-2, 3): put(u, y, z)
    for y in range(29, 34):                                   # palma
        for u in (-2, -1, 0, 1):
            for z in range(-4, 4):
                if y == 33 and z in (-4, 3): continue          # hombros de la palma, achaflanados
                if (u == -2 or u == 1) and z in (-4, 3): continue   # aristas verticales
                put(u, y, z)
    fingers = FINGERS
    if mitten:                                                # manopla: un solo bloque
        fingers = ((-4, 3), (-2, 4), (0, 4), (2, 4))
    for z0, n in fingers:
        for i in range(n):
            y = 28 - i
            curl = 1 if i >= n - 2 else 0                     # las dos últimas falanges, hacia la palma
            for u in (-1 + curl, 0 + curl):
                put(u, y, z0)
                put(u, y, z0 + 1, dark if not mitten and z0 < 2 else col)   # borde con el dedo de delante
    for y in range(28, 33):                                   # pulgar: base junto a la palma
        put(0, y, 4); put(1, y, 4)
    for y in range(25, 28):                                   # y punta, hacia abajo y hacia dentro
        put(1, y, 4); put(2, y, 4)


# ---------------- cabeza y cara ----------------

def head(M, skin, skin_sh, ears=True, nose=True, w=15.0, d=15.0, fem=False):
    """Cabeza redondeada (30-09-2026, referencia del autor): esquinas de radio 4, coronilla
    y mandíbula en cuarto de círculo, nariz que asoma 1 (fem: más pequeña) y orejas redondas."""
    rslab(M, H, skin, 64, 81, 0, 0.5, w, d, r=4, rt=4, rb=3)
    if nose:                                          # asoma 1 (2 parecía de payaso)
        if fem: rslab(M, H, skin_sh, 69, 71, 0, 0.5 + d / 2, 2, 2, r=0, rt=0, rb=0)
        else: rslab(M, H, skin_sh, 69, 72, 0, 0.5 + d / 2, 3, 2, r=1, rt=1, rb=0)
    if ears:
        for s in (-1, 1):
            rslab(M, H, skin_sh, 70, 75, (w / 2 + 0.5) * s, 0, 2, 4, r=1, rt=1, rb=1)


def paint_face(M, x, y, col, dz=0):
    front(M, x, y, col, dz, part=H)


def eyes(M, brow, eye=EYE, white=EYE_W, y=73, brow_style='caida', lashes=None):
    """Ojos de 2 filas con el blanco por fuera y un brillo, y cejas encima (con relieve).
    brow_style: 'caida' (caída por fuera), 'recta' o 'poblada'. Con pestañas (mujeres), la
    ceja es de una fila y más fina."""
    for x, c in ((-5, white), (-4, eye), (-3, eye), (2, eye), (3, eye), (4, white)):
        for yy in (y, y + 1): paint_face(M, x, yy, c)
    paint_face(M, -3, y + 1, white); paint_face(M, 2, y + 1, white)          # brillo
    if lashes is not None:                                                    # pestañas en el rabillo
        paint_face(M, -6, y + 1, lashes); paint_face(M, 5, y + 1, lashes)
        for x in (-5, -4, -3, 2, 3, 4): paint_face(M, x, y + 2, lashes)
        pts = ((-5, 4), (-4, 4), (-3, 4), (2, 4), (3, 4), (4, 4))
    elif brow_style == 'caida':
        pts = ((-6, 3), (-5, 4), (-4, 4), (-3, 4), (-2, 3), (1, 3), (2, 4), (3, 4), (4, 4), (5, 3),
               (-5, 3), (-4, 3), (3, 3), (4, 3))
    elif brow_style == 'recta':
        pts = ((-5, 3), (-4, 3), (-3, 3), (-2, 3), (1, 3), (2, 3), (3, 3), (4, 3),
               (-4, 4), (-3, 4), (2, 4), (3, 4))
    else:                                                                     # poblada
        pts = ((-6, 3), (-5, 3), (-4, 3), (-3, 3), (-2, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3),
               (-5, 4), (-4, 4), (-3, 4), (-2, 4), (1, 4), (2, 4), (3, 4), (4, 4))
    for x, dy in pts:
        paint_face(M, x, y + dy, brow, dz=1)


def cheeks(M, col, y=71):
    for x in (-6, -5, 4, 5):
        for yy in (y - 1, y): paint_face(M, x, yy, col)


def mouth(M, col, y=67, wide=False):
    for x in ((-2, -1, 0, 1) if wide else (-1, 0)): paint_face(M, x, y, col)


def beard(M, col):
    """Barba poblada y redonda: cubre la mandíbula y los carrillos, deja ver las mejillas."""
    rslab(M, H, col, 61, 69, 0, 2.5, 16, 12, r=4, rt=0, rb=4)
    rslab(M, H, col, 66, 71, -0.5, 1.5, 17, 11, r=3, rt=0, rb=0)


def moustache(M, col, xs=range(-3, 3), y=69, rows=1):
    for yy in range(y - rows + 1, y + 1):
        for x in xs: paint_face(M, x, yy, col, dz=1)


def hair_back(M, skin, hair, top=200, zmax=-2):
    """Pelo en la nuca (lo que quede de piel detrás de z = zmax, por debajo de `top`) y el
    cuello por detrás, cubierto por el pelo."""
    for (x, y, z), v in M.V.items():
        if v[0] == H and v[1] == skin and z < zmax and 64 <= y < top:
            v[1] = hair
    for (x, y, z), v in M.V.items():
        if v[0] == T and v[1] == skin and z < 0 and y >= 62:
            v[1] = hair


def bob(M, hair, bottom=66, top=82, fringe=78, side_z=3, back=-8, width=16.5):
    """Media melena: casco de pelo alrededor de la cabeza, desde `bottom` (a la altura de la
    mandíbula) hasta `top`, que deja la cara al aire (por delante de side_z y por debajo del
    flequillo `fringe`). Los voxels de la cabeza no se tocan: el pelo va por fuera."""
    hw = width / 2
    for y in range(bottom, top):
        cap = y >= top - 2                                    # coronilla: algo más estrecha
        w = hw - (1 if cap else 0)
        for x in range(int(-w - 0.5), int(w + 0.5)):
            for z in range(back, 10):
                if (x, y, z) in M.V: continue
                ex = min(x + w + 0.5, w - 0.5 - x)
                ez = min(z - back, 9 - z)
                if ex + ez < 2: continue                         # aristas achaflanadas
                if z > side_z and y < fringe: continue           # la cara, al aire
                if z > 8: continue
                if y < 72 and z > side_z - 2: continue           # por abajo se recoge hacia atrás
                M.put(x, y, z, H, hair, 0, False)


def sideburns(M, hair, y0=70, y1=76):
    """Patillas: el lateral de la cabeza delante de la oreja."""
    for (x, y, z), v in M.V.items():
        if v[0] == H and y0 <= y < y1 and abs(x + 0.5) >= 6.5 and 1 <= z <= 3 and v[1] != hair:
            v[1] = hair


# ---------------- acabado ----------------

def seams(M, cols, parts_arms=True):
    """Costuras: laterales del tronco, línea interior de las mangas y costura de los hombros."""
    cols = set(cols)
    M.seams = getattr(M, 'seams', set())
    for (x, y, z), v in M.V.items():
        if v[1] not in cols: continue
        if v[0] == T and z == 0 and abs(x) >= 10: M.seams.add((x, y, z))
        if parts_arms and v[0] in ('arm_l', 'arm_r', 'fore_l', 'fore_r') and z == -3: M.seams.add((x, y, z))
        if v[0] == T and y == 58: M.seams.add((x, y, z))


def finish(M, name, mats, flat=(), b=0, extra_pivots=None, extra_parents=None, top=85.0, ax=ARM_X):
    """Texturas por material, luz (arriba algo más claro, la espalda algo más oscura) y
    exportación con los pivotes comunes."""
    materiales.texturize(M, mats)
    flat = set(flat) | {EYE, EYE_W}
    for k, v in M.V.items():
        x, y, z = k
        if v[1] in flat: continue
        shade = 0.9 + 0.12 * y / top
        shade *= 0.95 if z < -4 else 1.0
        v[1] = tuple(max(0.0, min(1.0, c * shade)) for c in v[1])
    ax = ax + b / 2
    piv = {'torso': [0, HIP, 0], 'head': [0, NECK, 0],
           'arm_l': [-ax, SHOULDER, 0], 'arm_r': [ax, SHOULDER, 0],
           'fore_l': [-ax * 1.02, ELBOW, 0.5], 'fore_r': [ax * 1.02, ELBOW, 0.5],
           'leg_l': [-5, HIP, 0], 'leg_r': [5, HIP, 0], 'shin_l': [-5, KNEE, 0], 'shin_r': [5, KNEE, 0]}
    if ax < ARM_X:                                    # mujer: piernas algo más juntas
        for k in ('leg_l', 'shin_l'): piv[k][0] = -4.5
        for k in ('leg_r', 'shin_r'): piv[k][0] = 4.5
    parents = {'shin_l': 'leg_l', 'shin_r': 'leg_r', 'fore_l': 'arm_l', 'fore_r': 'arm_r'}
    if extra_pivots: piv.update(extra_pivots)
    if extra_parents: parents.update(extra_parents)
    n = M.export('models/%s.json' % name, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25,
                 parents=parents)
    print(name, n, 'voxels')
    return n
