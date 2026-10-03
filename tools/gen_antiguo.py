"""Los Antiguos ("En las montañas de la locura"), hito 4.2. Base común de sus variantes.

Fiel al relato: cuerpo de barril de 1,8 m con cinco crestas verticales, cabeza en estrella
de cinco puntas con un ojo rojo en cada una y cilios claros en el centro, alas membranosas
plegadas en los surcos (abiertas en el alado), un manojo de tentáculos que cuelgan de la
cintura y cinco patas cortas como brazos de estrella de mar que acaban en almohadilla.
Gris verdoso, orgánico (las criaturas no van a bloques limpios, como el Acechador).

Unidades base (1 ub = 1/16 m), S=2: 32 voxels por metro. Mira hacia +Z.
Partes: body, head, arms, wing_l, wing_r, leg0..leg4 (anim_antiguo.gd).
Escribe models/antiguo.json (alas plegadas) y models/antiguo_alado.json (alas abiertas).
Uso: python tools/gen_antiguo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

SKIN = (0.36, 0.42, 0.36); SKIN_D = (0.22, 0.28, 0.24); RIDGE = (0.50, 0.54, 0.44)
BELLY = (0.44, 0.46, 0.38); CILIA = (0.78, 0.76, 0.62); EYE = (1.0, 0.18, 0.10)
MEMB = (0.30, 0.30, 0.34); MEMB_D = (0.18, 0.18, 0.22); BONE = (0.70, 0.66, 0.54)
TENT = (0.40, 0.36, 0.30); PAD = (0.20, 0.18, 0.16)

BODY_Y0, BODY_Y1 = 4.0, 23.0          # barril
HEAD_Y = 26.0


def barrel_r(y):
    """Radio del barril: más ancho en medio y estrecho en los extremos."""
    t = (y - BODY_Y0) / (BODY_Y1 - BODY_Y0)
    return 2.8 + 3.2 * math.sin(math.pi * min(1.0, max(0.0, t))) ** 1.2


def build(open_wings, seed, tint=0.0, variant=''):
    M = Model(S=2, seed=seed)
    S = M.S
    def ub(v): return v * S
    skin = lerp(SKIN, (0.48, 0.52, 0.48), tint)
    # ---------- barril con cinco crestas ----------
    for yv in range(int(ub(BODY_Y0)), int(ub(BODY_Y1))):
        y = yv / S
        R = barrel_r(y)
        for xv in range(int(-ub(7)), int(ub(7)) + 1):
            for zv in range(int(-ub(7)), int(ub(7)) + 1):
                x, z = xv / S, zv / S
                a = math.atan2(z, x)
                rr = R * (1 + 0.13 * math.cos(5 * a))
                d = math.hypot(x, z)
                if d > rr or d < rr - 1.6: continue
                ridge = math.cos(5 * a)
                c = lerp(SKIN_D, skin, 0.5 + 0.5 * ridge)
                if ridge > 0.9: c = RIDGE
                c = lerp(c, SKIN_D, 0.25 * M.noise(xv, yv, zv, 6.0))
                M.put(xv, yv, zv, 'body', c)
    # tapas del barril
    for yv in (int(ub(BODY_Y0)), int(ub(BODY_Y1)) - 1):
        r = barrel_r(yv / S)
        for xv in range(int(-ub(r)), int(ub(r)) + 1):
            for zv in range(int(-ub(r)), int(ub(r)) + 1):
                if math.hypot(xv, zv) <= ub(r) * 0.95: M.put(xv, yv, zv, 'body', SKIN_D, over=False)
    # cuello: bulbo corto
    M.ell(0, 24.0, 0, 2.2, 1.6, 2.2, 'body', SKIN_D)
    # ---------- cabeza en estrella ----------
    M.ell(0, HEAD_Y, 0, 2.0, 1.4, 2.0, 'head', skin)
    for i in range(5):
        a = i / 5 * math.tau + math.pi / 2                     # una punta hacia delante
        tip = (math.cos(a) * 6.0, HEAD_Y + 0.6, math.sin(a) * 6.0)
        M.capsule((0, HEAD_Y, 0), tip, 1.2, 0.55, 'head', skin)
        ex, ey, ez = tip
        M.ell(ex, ey + 0.3, ez, 0.75, 0.75, 0.75, 'head', EYE, glow=1)   # ojo rojo en la punta
    for xv in range(-int(ub(1.4)), int(ub(1.4)) + 1):              # cilios en el centro
        for zv in range(-int(ub(1.4)), int(ub(1.4)) + 1):
            if math.hypot(xv, zv) > ub(1.4) or M.hsh(xv, 9, zv) > 0.5: continue
            top = M.top(xv, zv)
            if top is not None:
                for k in range(1, 3): M.put(xv, top + k, zv, 'head', CILIA)
    # ---------- tentáculos de la cintura (cinco, que se ramifican) ----------
    for i in range(5):
        a = i / 5 * math.tau + math.pi / 5
        base = (math.cos(a) * 5.0, 15.0, math.sin(a) * 5.0)
        mid = (math.cos(a) * 7.5, 10.5, math.sin(a) * 7.5)
        M.capsule(base, mid, 0.85, 0.6, 'arms', TENT)
        for k in (-1, 1):                                          # se abren en dos
            b = a + k * 0.25
            tip = (math.cos(b) * 8.6, 6.5, math.sin(b) * 8.6)
            M.capsule(mid, tip, 0.55, 0.3, 'arms', TENT)
    # ---------- patas: cinco brazos de estrella cortos con almohadilla ----------
    for i in range(5):
        a = i / 5 * math.tau
        p = 'leg%d' % i
        hip = (math.cos(a) * 3.0, BODY_Y0 + 0.5, math.sin(a) * 3.0)
        foot = (math.cos(a) * 6.5, 1.0, math.sin(a) * 6.5)
        M.capsule(hip, foot, 1.3, 0.9, p, SKIN_D)
        M.ell(foot[0], 0.6, foot[2], 1.4, 0.6, 1.4, p, PAD)
    # ---------- alas membranosas ----------
    for s, p in ((-1, 'wing_l'), (1, 'wing_r')):
        if open_wings:
            # abiertas: abanico de 4 varillas desde el hombro, membrana entre ellas
            sh = (s * 4.5, 19.0, -1.5)
            ribs = []
            for j in range(4):
                ang = math.radians(15 + j * 20)
                tip = (s * (4.5 + 14 * math.cos(ang)), 19.0 + 9 * math.sin(ang) - 4, -1.5 - 3.0 * j)
                ribs.append(tip)
                M.capsule(sh, tip, 0.45, 0.25, p, BONE)
            for j in range(3):
                a0, a1 = ribs[j], ribs[j + 1]
                for u in range(0, 21):
                    for v in range(0, 21 - u):
                        fu, fv = u / 20, v / 20
                        q = [sh[k] + (a0[k] - sh[k]) * fu + (a1[k] - sh[k]) * fv for k in range(3)]
                        c = MEMB if (u + v) % 4 else MEMB_D
                        M.put(int(round(q[0] * S)), int(round(q[1] * S)), int(round(q[2] * S)), p, c, over=False)
        else:
            # plegadas en un surco del costado: una lámina estrecha a lo largo del barril
            for yv in range(int(ub(8)), int(ub(22))):
                y = yv / S
                r = barrel_r(y) * 1.13 + 0.3
                for zz in range(-int(ub(1.6)), int(ub(1.6)) + 1):
                    M.put(int(round(s * ub(r))), yv, zz - int(ub(1.0)), p, MEMB if (yv // 3) % 2 else MEMB_D)
    if variant == 'guerrero': _guerrero(M)
    if variant == 'mutilado': _mutilado(M)
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    piv = {'body': [0, BODY_Y0, 0], 'head': [0, 24.0, 0], 'arms': [0, 15.0, 0],
           'wing_l': [-4.5, 19.0, -1.5], 'wing_r': [4.5, 19.0, -1.5]}
    for i in range(5):
        a = i / 5 * math.tau
        piv['leg%d' % i] = [math.cos(a) * 3.0, BODY_Y0 + 0.5, math.sin(a) * 3.0]
    return M, piv


PLATE = (0.20, 0.22, 0.26); PLATE_L = (0.34, 0.36, 0.40); SPEAR = (0.52, 0.48, 0.40); TIP = (0.30, 0.62, 0.55)
SLIME = (0.05, 0.07, 0.06); SLIME_G = (0.10, 0.20, 0.14)


def _guerrero(M):
    """Antiguo guerrero: el barril más oscuro, con placas como de pizarra, una cresta en la
    cabeza y una lanza de piedra con punta de cristal verdoso en los tentáculos."""
    S = M.S
    for (x, y, z), v in M.V.items():
        if v[0] == 'body' and y > 6 * S and (y // 5) % 3 == 0: v[1] = PLATE if M.hsh(x, y, z) > 0.4 else PLATE_L
    for i in range(int(4 * S)):                                     # cresta
        for dz in range(-2, 2): M.put(0, int(27.5 * S) + i, dz - i // 2, 'head', PLATE)
    a, b = (7.8, 3.0, 4.0), (5.5, 27.0, 1.0)                          # lanza en diagonal (en ub)
    M.capsule(a, b, 0.4, 0.4, 'arms', SPEAR)
    M.cone(b, (5.2, 31.0, 0.6), 0.9, 'arms', TIP, TIP, tip_r=0.15)


def _mutilado(M):
    """Antiguo mutilado: le faltan dos puntas de la estrella y la mitad de los tentáculos,
    tiene las alas rotas y lo cubren manchas del limo negro de los shoggoths que lo atacaron."""
    S = M.S
    for (x, y, z) in [k for k, v in M.V.items() if v[0] == 'head' and k[2] < -2 * S]: del M.V[(x, y, z)]
    for (x, y, z) in [k for k, v in M.V.items() if v[0] == 'arms' and k[0] < 0]: del M.V[(x, y, z)]
    for (x, y, z) in [k for k, v in M.V.items() if v[0] in ('wing_l', 'wing_r') and M.noise(*k, 6.0) > 0.55
                      and k[1] < 17 * S]:                           # alas rotas; queda el muñón de arriba
        del M.V[(x, y, z)]
    for (x, y, z), v in M.V.items():
        n = M.noise(x, y, z, 7.0)
        if n > 0.62: v[1] = SLIME if n > 0.72 else SLIME_G


for name, wings, seed, tint, var in (('antiguo', False, 7101, 0.0, ''), ('antiguo_alado', True, 7102, 0.25, ''),
                                     ('antiguo_guerrero', False, 7103, -0.1, 'guerrero'),
                                     ('antiguo_mutilado', False, 7104, 0.1, 'mutilado')):
    M, piv = build(wings, seed, tint, var)
    n = M.export('models/%s.json' % name, piv, jitter=0.012, roughness=0.5, specular=0.45)
    print(name, n, 'voxels')
