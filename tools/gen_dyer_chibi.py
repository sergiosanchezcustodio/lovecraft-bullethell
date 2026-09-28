"""Prototipo de William Dyer con otro estilo (referencia del 28-09-2026): proporciones más
"chibi" (cabeza grande, manos y pies grandes), ropa en capas con relieve de capa entera
(cuello, puños, bajo, vuelta de las botas, suela) y cara con volumen limpio (ceja, nariz,
barba y orejas en escalones grandes, nunca en granitos sueltos).

Se diseña en unidades (el personaje mide 41 de alto, 1,72 m) y se exporta a dos tamaños de
voxel para compararlos:
- models/dyer_chibi.json       1 voxel por unidad (~24 voxels por metro, como la referencia)
- models/dyer_chibi_fino.json  2 voxels por unidad (~48 por metro, más fino que el estilo actual)

Mismas piezas que los humanos articulados (torso, cabeza, brazos, antebrazos, muslos,
espinillas y bufanda), así que usa las animaciones de anim_humano.
Uso: python tools/gen_dyer_chibi.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

HEIGHT_M = 1.72
UNITS = 41

PARKA = (0.56, 0.44, 0.29); PARKA_SH = (0.47, 0.36, 0.23)
FUR = (0.82, 0.80, 0.75); FUR_SH = (0.70, 0.68, 0.64)
TROUSER = (0.28, 0.29, 0.33); TROUSER_SH = (0.22, 0.23, 0.27)
BOOT = (0.36, 0.24, 0.15); SOLE = (0.14, 0.10, 0.08)
MITT = (0.32, 0.22, 0.14); MITT_SH = (0.25, 0.17, 0.11)
CAP = (0.38, 0.24, 0.15); CAP_SH = (0.30, 0.19, 0.12)
SKIN = (0.89, 0.69, 0.55); SKIN_SH = (0.78, 0.58, 0.46)
HAIR = (0.40, 0.31, 0.24)
BEARD = (0.52, 0.42, 0.34); BEARD_SH = (0.44, 0.35, 0.28)
BROW = (0.33, 0.25, 0.19); EYE = (0.09, 0.07, 0.06); EYE_W = (0.92, 0.90, 0.86); MOUTH = (0.30, 0.18, 0.15)
SCARF = (0.66, 0.19, 0.14); SCARF_SH = (0.53, 0.14, 0.11)
BELT = (0.22, 0.15, 0.10); BUCKLE = (0.84, 0.70, 0.38)
GREN = (0.28, 0.32, 0.24); HANDLE = (0.76, 0.62, 0.40)


def build(k):
    M = Model(S=1, seed=1930)

    def q(v):
        # redondeo simétrico respecto a 0 (el mismo a izquierda y derecha)
        return int(math.copysign(math.floor(abs(v) * k + 0.5), v))

    def B(x0, y0, z0, x1, y1, z1, part, col, over=True):
        a = [q(x0), q(y0), q(z0)]
        b = [q(x1), q(y1), q(z1)]
        for i in range(3):
            if b[i] <= a[i]: b[i] = a[i] + 1          # nunca menos de un voxel de grosor
        M.vbox(a[0], a[1], a[2], b[0], b[1], b[2], part, col, over)

    def cut(x0, y0, z0, x1, y1, z1):
        for x in range(q(x0), q(x1)):
            for y in range(q(y0), q(y1)):
                for z in range(q(z0), q(z1)):
                    M.V.pop((x, y, z), None)

    def bevel(part, x0, x1, z0, z1, y0, y1):
        M.bevel(part, q(x0), q(x1), q(z0), q(z1), q(y0), q(y1))

    # ---------------- piernas: bota grande con suela y vuelta, pantalón con dobladillo ----------------
    for s in (-1, 1):
        leg, shin = ('leg_l', 'shin_l') if s < 0 else ('leg_r', 'shin_r')
        x0, x1 = (-6, -1) if s < 0 else (1, 6)
        B(x0, 0, -3, x1, 1, 5, shin, SOLE)                       # suela, sobresale por delante
        B(x0, 1, -3, x1, 5, 4, shin, BOOT)                       # bota
        bevel(shin, x0, x1, -3, 4, 1, 5)
        B(x0 - 0.5, 5, -3, x1 + 0.5, 6, 3, shin, FUR)            # vuelta de borreguillo (capa)
        B(x0 + 0.5, 6, -2.5, x1 - 0.5, 10, 2.5, shin, TROUSER)   # espinilla
        B(x0 + 0.5, 10, -2.5, x1 - 0.5, 17, 2.5, leg, TROUSER)   # muslo
        bevel(leg, x0 + 0.5, x1 - 0.5, -2.5, 2.5, 10, 17)
    # ---------------- torso: parka con bajo, cinturón y bufanda en capas ----------------
    T = 'torso'
    B(-6, 16, -3.5, 6, 29, 3.5, T, PARKA)
    bevel(T, -6, 6, -3.5, 3.5, 16, 29)
    B(-6.5, 15.5, -4, 6.5, 17.5, 4, T, FUR)                      # bajo de borreguillo (capa)
    bevel(T, -6.5, 6.5, -4, 4, 15.5, 17.5)
    B(-6.2, 19.5, -3.7, 6.2, 21, 3.7, T, BELT)                   # cinturón
    B(-1, 19.2, 3.5, 1, 21.3, 4.3, T, BUCKLE)                    # hebilla (capa)
    B(-0.5, 21, 3.3, 0.5, 26, 3.6, T, PARKA_SH)                  # tapeta
    for y in (22.5, 24.5): B(-0.5, y, 3.4, 0.5, y + 1, 3.8, T, BELT)
    for x0 in (-5, 2.5):                                         # bolsillos con solapa
        B(x0, 22, 3.3, x0 + 2.5, 24.5, 3.6, T, PARKA_SH)
        B(x0, 24, 3.4, x0 + 2.5, 24.7, 3.9, T, PARKA_SH)
    for x in (-5, -3.5):                                         # dos granadas de palo en el cinturón
        B(x, 21, 3.5, x + 1.2, 23, 4.4, T, GREN)
        B(x + 0.3, 17.5, 3.6, x + 0.9, 21, 4.2, T, HANDLE)
    B(-5, 27, -4.5, 5, 30, 4.5, T, SCARF)                        # bufanda (capa gruesa)
    bevel(T, -5, 5, -4.5, 4.5, 27, 30)
    B(-5, 27, 4, 5, 27.6, 4.5, T, SCARF_SH)
    # cola de la bufanda por la espalda (pieza propia, se balancea)
    B(0.5, 20.5, -5, 3, 28, -4, 'scarf', SCARF)
    for y in (22, 25): B(0.5, y, -5.1, 3, y + 0.6, -4, 'scarf', SCARF_SH)
    # ---------------- brazos: manga, puño de borreguillo y manopla grande ----------------
    for s in (-1, 1):
        arm, fore = ('arm_l', 'fore_l') if s < 0 else ('arm_r', 'fore_r')
        x0, x1 = (-9.5, -6) if s < 0 else (6, 9.5)
        B(x0, 23, -2, x1, 29, 2, arm, PARKA)
        bevel(arm, x0, x1, -2, 2, 23, 29)
        B(x0, 18.5, -2, x1, 23, 2, fore, PARKA)
        B(x0 - 0.4, 17, -2.4, x1 + 0.4, 18.7, 2.4, fore, FUR)    # puño (capa)
        bevel(fore, x0 - 0.4, x1 + 0.4, -2.4, 2.4, 17, 18.7)
        hx0 = x0 - 0.3 if s < 0 else x0 - 0.2                    # manopla grande, puño cerrado
        B(hx0, 12.5, -2, hx0 + 4, 17, 2.4, fore, MITT)
        bevel(fore, hx0, hx0 + 4, -2, 2.4, 12.5, 17)
        tx = x1 - 0.2 if s < 0 else x0 - 0.8                     # pulgar hacia dentro y adelante
        B(tx, 14, 0.8, tx + 1, 16.5, 2.2, fore, MITT_SH)
    # ---------------- cabeza: grande, con volumen limpio ----------------
    H = 'head'
    B(-5, 29.5, -4.5, 5, 38.5, 4.5, H, SKIN)
    bevel(H, -5, 5, -4.5, 4.5, 29.5, 38.5)
    B(-5.8, 32, -1, -5, 35, 1.5, H, SKIN_SH)                      # orejas
    B(5, 32, -1, 5.8, 35, 1.5, H, SKIN_SH)
    # pelo en la nuca y las sienes, en mechones
    B(-5, 30.5, -4.8, 5, 38, -4, H, HAIR)
    for x0 in (-4.5, -1.5, 1.5):
        B(x0, 30.5, -5.2, x0 + 2.5, 33, -4.5, H, HAIR)
    B(-5.2, 33, -3.5, -4.8, 37, 0, H, HAIR)
    B(4.8, 33, -3.5, 5.2, 37, 0, H, HAIR)
    # cara (plano frontal z 4,5): ceja en relieve, ojos, nariz, barba y bigote en capas
    # (la cara está en el plano z 4 del cuadro de la cabeza; lo que va en z 4-5,5 es relieve)
    B(-4, 35, 4, -1, 36, 5.5, H, BROW)                             # cejas (capa)
    B(1, 35, 4, 4, 36, 5.5, H, BROW)
    B(-3.5, 33.5, 4, -2.5, 35, 4.5, H, EYE_W)                      # ojos: brillo y pupila
    B(-2.5, 33.5, 4, -1.5, 35, 4.5, H, EYE)
    B(1.5, 33.5, 4, 2.5, 35, 4.5, H, EYE)
    B(2.5, 33.5, 4, 3.5, 35, 4.5, H, EYE_W)
    B(-1, 32, 4, 1, 34.5, 5.5, H, SKIN_SH)                         # nariz (capa)
    B(-4, 29.5, 4, 4, 32.5, 5.5, H, BEARD)                         # barba (capa)
    B(-2.5, 32, 5, 2.5, 32.8, 6, H, BEARD_SH)                      # bigote (sobre la barba)
    B(-1, 30.8, 5, 1, 31.5, 5.5, H, MOUTH)                         # boca
    B(-4.8, 30, -1, -4.3, 34, 3, H, BEARD)                          # patillas
    B(4.3, 30, -1, 4.8, 34, 3, H, BEARD)
    # gorro de trampero: copa, banda de borreguillo y orejeras
    B(-5.8, 37.5, -5.3, 5.8, 41, 5.3, H, CAP)
    bevel(H, -5.8, 5.8, -5.3, 5.3, 37.5, 41)
    B(-5.2, 41, -4.7, 5.2, 41.6, 4.7, H, CAP_SH)
    B(-6, 37, 4.5, 6, 39, 5.8, H, FUR)                              # banda delantera (capa)
    for x0 in (-6.3, 5.3):                                          # orejeras con ribete
        B(x0, 33, -2.5, x0 + 1, 38, 2.5, H, CAP)
        B(x0, 32.3, -2.5, x0 + 1, 33.2, 2.5, H, FUR)

    # color: luz arriba y sombra abajo en cada pieza, y un poco de variación por voxel
    lo = min(y for (_, y, _) in M.V)
    hi = max(y for (_, y, _) in M.V)

    def paint(key, part, c):
        x, y, z = key
        if c in (EYE, EYE_W, MOUTH, BUCKLE): return None
        n = M.hsh(x, y, z) * 0.035
        shade = 0.93 + 0.1 * (y - lo) / max(hi - lo, 1)              # más claro arriba
        side = 0.96 if z < 0 else 1.0                                 # la espalda, algo más oscura
        return tuple(max(0.0, min(1.0, ch * shade * side + n)) for ch in c)
    M.paint(paint)
    return M


PIV = {'torso': [0, 16, 0], 'head': [0, 29.5, 0],
       'arm_l': [-7.75, 28.5, 0], 'arm_r': [7.75, 28.5, 0], 'fore_l': [-7.75, 23, 0], 'fore_r': [7.75, 23, 0],
       'leg_l': [-3.5, 17, 0], 'leg_r': [3.5, 17, 0], 'shin_l': [-3.5, 10, 0], 'shin_r': [3.5, 10, 0],
       'scarf': [1.75, 28, -4.5]}
PARENTS = {'shin_l': 'leg_l', 'shin_r': 'leg_r', 'fore_l': 'arm_l', 'fore_r': 'arm_r', 'scarf': 'torso'}

for name, k in (('dyer_chibi', 1.0), ('dyer_chibi_fino', 2.0)):
    M = build(k)
    vs = HEIGHT_M / (UNITS * k)
    M.S = 1.0 / (16 * vs)                        # voxel_size = 1 / (16 * S)
    piv = {p: [v * k for v in xyz] for p, xyz in PIV.items()}
    n = M.export('models/%s.json' % name, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.9, specular=0.25,
                 parents=PARENTS)
    print(name, n, 'voxels, %.1f voxels por metro' % (1.0 / vs))
