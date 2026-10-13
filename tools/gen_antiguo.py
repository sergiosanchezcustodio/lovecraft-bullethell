"""Los Antiguos ("En las montañas de la locura"), hito 4.2. Base común de sus variantes.

Fiel al relato: cuerpo de barril de 1,8 m con cinco crestas verticales, cabeza en estrella
de cinco puntas con un ojo rojo en cada una y cilios claros en el centro, alas membranosas
plegadas en los surcos (abiertas en el alado), un manojo de tentáculos que cuelgan de la
cintura y cinco patas cortas como brazos de estrella de mar que acaban en almohadilla.
Gris verdoso, orgánico (las criaturas no van a bloques limpios, como el Acechador).

Unidades base (1 ub = 1/16 m), S=2: 32 voxels por metro. Mira hacia +Z.
Partes: body, head, arms, wing_l, wing_r, leg0..leg4 (anim_antiguo.gd).
Escribe models/antiguo.json (el revivido: como el alado sin alas, en morados y grises), models/antiguo_alado.json (alas abiertas, ojos blancos
y tentáculos de medusa), antiguo_guerrero (como el
alado sin alas, con los tentáculos levantados acabados en garras y picos), antiguo_mutilado y antiguo_despierto (el del alado sin alas
y con los ojos más grandes: el primero en despertar).
Uso: python tools/gen_antiguo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

SKIN = (0.36, 0.42, 0.36); SKIN_D = (0.22, 0.28, 0.24); RIDGE = (0.50, 0.54, 0.44)
BELLY = (0.44, 0.46, 0.38); CILIA = (0.78, 0.76, 0.62); EYE = (1.0, 0.18, 0.10)
MEMB = (0.30, 0.30, 0.34); MEMB_D = (0.18, 0.18, 0.22); BONE = (0.70, 0.66, 0.54)
TENT = (0.40, 0.36, 0.30); PAD = (0.20, 0.18, 0.16)
PURPLE = (0.34, 0.29, 0.50); PURPLE_D = (0.20, 0.18, 0.30); PURPLE_R = (0.54, 0.56, 0.64)   # revivido: morado y gris

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
    medusa = open_wings or variant in ('despierto', 'guerrero', 'mutilado', 'revivido')   # ojos blancos y tentáculos de medusa
    SK, SKD, RDG, CIL, PD = SKIN, SKIN_D, RIDGE, CILIA, PAD
    if variant == 'revivido':                                       # morados y grises (revisión del 13-10-2026)
        SK, SKD, RDG, CIL, PD = PURPLE, PURPLE_D, PURPLE_R, (0.74, 0.70, 0.80), (0.16, 0.14, 0.20)
    skin = lerp(SK, (0.48, 0.52, 0.48), tint)
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
                c = lerp(SKD, skin, 0.5 + 0.5 * ridge)
                if ridge > 0.9: c = RDG
                c = lerp(c, SKD, 0.25 * M.noise(xv, yv, zv, 6.0))
                M.put(xv, yv, zv, 'body', c)
    # tapas del barril
    for yv in (int(ub(BODY_Y0)), int(ub(BODY_Y1)) - 1):
        r = barrel_r(yv / S)
        for xv in range(int(-ub(r)), int(ub(r)) + 1):
            for zv in range(int(-ub(r)), int(ub(r)) + 1):
                if math.hypot(xv, zv) <= ub(r) * 0.95: M.put(xv, yv, zv, 'body', SKD, over=False)
    # cuello: bulbo corto
    M.ell(0, 24.0, 0, 2.2, 1.6, 2.2, 'body', SKD)
    # ---------- cabeza en estrella ----------
    M.ell(0, HEAD_Y, 0, 2.0, 1.4, 2.0, 'head', skin)
    for i in range(5):
        a = i / 5 * math.tau + math.pi / 2                     # una punta hacia delante
        tip = (math.cos(a) * 6.0, HEAD_Y + 0.6, math.sin(a) * 6.0)
        M.capsule((0, HEAD_Y, 0), tip, 1.2, 0.55, 'head', skin)
        ex, ey, ez = tip
        if medusa: _eye(M, ex, ey + 0.4, ez, a, 1.4 if variant == 'despierto' else 1.0)   # ojo blanco, pupila roja
        else: M.ell(ex, ey + 0.3, ez, 0.75, 0.75, 0.75, 'head', EYE, glow=1)   # ojo rojo en la punta
    for xv in range(-int(ub(1.4)), int(ub(1.4)) + 1):              # cilios en el centro
        for zv in range(-int(ub(1.4)), int(ub(1.4)) + 1):
            if math.hypot(xv, zv) > ub(1.4) or M.hsh(xv, 9, zv) > 0.5: continue
            top = M.top(xv, zv)
            if top is not None:
                for k in range(1, 3): M.put(xv, top + k, zv, 'head', CIL)
    # ---------- tentáculos de la cintura (cinco, que se ramifican; de medusa en el alado) ----------
    if variant in ('guerrero', 'mutilado'): _raised(M)
    elif medusa: _jelly(M)
    else:
        for i in range(5):
            a = i / 5 * math.tau + math.pi / 5
            base = (math.cos(a) * 5.0, 15.0, math.sin(a) * 5.0)
            mid = (math.cos(a) * 7.5, 10.5, math.sin(a) * 7.5)
            M.capsule(base, mid, 0.85, 0.6, 'arms', TENT)
            for k in (-1, 1):                                      # se abren en dos
                b = a + k * 0.25
                tip = (math.cos(b) * 8.6, 6.5, math.sin(b) * 8.6)
                M.capsule(mid, tip, 0.55, 0.3, 'arms', TENT)
    # ---------- patas: cinco brazos de estrella cortos con almohadilla ----------
    for i in range(5):
        a = i / 5 * math.tau
        p = 'leg%d' % i
        hip = (math.cos(a) * 3.0, BODY_Y0 + 0.5, math.sin(a) * 3.0)
        foot = (math.cos(a) * 6.5, 1.0, math.sin(a) * 6.5)
        M.capsule(hip, foot, 1.3, 0.9, p, SKD)
        M.ell(foot[0], 0.6, foot[2], 1.4, 0.6, 1.4, p, PD)
    # ---------- alas membranosas ----------
    for s, p in ((-1, 'wing_l'), (1, 'wing_r')) if variant not in ('despierto', 'guerrero', 'mutilado', 'revivido') else ():
        if open_wings:
            _wing(M, s, p)
        else:
            # plegadas en un surco del costado: una lámina estrecha a lo largo del barril
            for yv in range(int(ub(8)), int(ub(22))):
                y = yv / S
                r = barrel_r(y) * 1.13 + 0.3
                for zz in range(-int(ub(1.6)), int(ub(1.6)) + 1):
                    M.put(int(round(s * ub(r))), yv, zz - int(ub(1.0)), p, MEMB if (yv // 3) % 2 else MEMB_D)
    if variant in ('guerrero', 'mutilado'): _guerrero(M)
    if variant == 'mutilado': _mutilado(M)
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    piv = {'body': [0, BODY_Y0, 0], 'head': [0, 24.0, 0], 'arms': [0, 15.0, 0],
           'wing_l': [-4.5, 19.0, -1.5], 'wing_r': [4.5, 19.0, -1.5]}
    for i in range(5):
        a = i / 5 * math.tau
        piv['leg%d' % i] = [math.cos(a) * 3.0, BODY_Y0 + 0.5, math.sin(a) * 3.0]
    return M, piv


EYE_W = (0.92, 0.90, 0.84); EYE_LID = (0.14, 0.16, 0.15); PUPIL = (0.62, 0.02, 0.03)
JEL = (0.24, 0.24, 0.26); JEL_D = (0.14, 0.14, 0.16); JEL_L = (0.40, 0.40, 0.43)
WBONE = (0.40, 0.39, 0.38); WBONE_D = (0.24, 0.23, 0.23); CLAW = (0.12, 0.11, 0.10); CLAW_L = (0.55, 0.52, 0.48)
WM_ROOT = (0.16, 0.16, 0.20); WM_MID = (0.27, 0.25, 0.31); WM_RIM = (0.12, 0.12, 0.15); VEIN = (0.30, 0.15, 0.19)


def _eye(M, ex, ey, ez, a, size=1.0):
    """Ojo blanco con la pupila rojo sangre, mirando hacia fuera y algo hacia arriba
    (la cámara mira desde arriba), con un párpado oscuro alrededor."""
    S = M.S
    d = (math.cos(a), 0.75, math.sin(a)); n = math.sqrt(sum(c * c for c in d)); d = [c / n for c in d]
    r = 1.05 * size
    cx, cy, cz = ex * S, ey * S, ez * S
    R = r * S; RL = R + 0.4 * S                                      # párpado: copa oscura por detrás
    for x in range(int(cx - RL) - 1, int(cx + RL) + 2):
        for y in range(int(cy - RL) - 1, int(cy + RL) + 2):
            for z in range(int(cz - RL) - 1, int(cz + RL) + 2):
                v = (x + 0.5 - cx, y + 0.5 - cy, z + 0.5 - cz)
                l = math.sqrt(sum(c * c for c in v))
                dot = sum(v[i] * d[i] for i in range(3)) / max(l, 1e-6)
                if l > R:
                    if l <= RL and dot < 0.15: M.put(x, y, z, 'head', EYE_LID)
                    continue
                if dot < -0.2: M.put(x, y, z, 'head', EYE_LID); continue
                if dot > 0.86: M.put(x, y, z, 'head', PUPIL, glow=1)
                elif dot > 0.79: M.put(x, y, z, 'head', (0.30, 0.03, 0.04))
                else: M.put(x, y, z, 'head', EYE_W)


def _strand(M, base, length, r0, r1, phase, amp, freq, cols, frill=False):
    """Tentáculo de medusa que cuelga ondulando: base (x, y, z) en ub, cae hacia abajo
    abriéndose un poco hacia fuera."""
    S = M.S
    bx, by, bz = base
    out = math.atan2(bz, bx)
    ox, oz = math.cos(out), math.sin(out)
    tx, tz = -oz, ox                                                 # tangente (para ondular de lado)
    steps = int(length * S * 3)
    for i in range(steps + 1):
        t = i / steps
        y = by - length * t
        if y < 0.4: break
        w = math.sin(phase + t * freq) * amp * t ** 0.7
        spread = 1.6 * t ** 0.8
        x = bx + ox * spread + tx * w
        z = bz + oz * spread + tz * w + 0.6 * t                      # algo hacia atrás, como arrastrado
        r = r0 + (r1 - r0) * t
        band = int(t * length * 1.6 + phase * 3) % 3 == 0
        c = cols[1] if band else cols[0]
        M.ell(x, y, z, r, 0.5 / S + r * 0.6, r, 'arms', c)
        if frill and i % 3 == 0 and 0.08 < t < 0.9:                  # volantes de los brazos orales
            f = 0.7 * (1 - t) + 0.3
            sgn = 1 if (i // 3) % 2 else -1                          # volantes alternos a un lado y otro
            fx = x + tx * sgn * (r + f * 0.8)
            fz = z + tz * sgn * (r + f * 0.8)
            M.ell(fx, y, fz, 0.25 + 0.3 * f, 0.35, 0.25 + 0.3 * f, 'arms', cols[1], over=False)


def _skirt(M):
    S = M.S
    for k in range(int(math.tau * 6.6 * S)):                       # falda (umbrela) festoneada
        a = k / (6.6 * S)
        lob = abs(math.sin(a * 5 / 2))                              # cinco lóbulos
        r = 6.4 + 0.5 * lob
        for dy in range(int((1.4 + 1.2 * lob) * S)):
            y = 16.0 - dy / S
            c = JEL_D if dy == 0 else (JEL if dy < 3 else JEL_L)
            M.put(math.cos(a) * r * S, y * S, math.sin(a) * r * S, 'arms', c, over=False)
            M.put(math.cos(a) * (r - 0.5) * S, y * S, math.sin(a) * (r - 0.5) * S, 'arms', JEL_D, over=False)


def _raised(M):
    """Antiguo guerrero: la falda de medusa y cinco tentáculos gris oscuro levantados, que suben
    desde la cintura, se arquean hacia fuera y acaban en garras de dos puntas o en picos afilados."""
    S = M.S
    _skirt(M)
    for i in range(5):
        a = i / 5 * math.tau + math.pi / 5
        ox, oz = math.cos(a), math.sin(a)
        tx, tz = -oz, ox
        prev = None
        steps = 40
        for k in range(steps + 1):
            t = k / steps
            d = 6.0 + 4.5 * math.sin(t * math.pi * 0.75)             # se abre y luego se recoge un poco
            y = 15.0 + 13.0 * t - 4.0 * max(0.0, t - 0.8) / 0.2 * 0.6   # sube y la punta se inclina
            w = math.sin(i * 1.7 + t * 5) * 1.0 * t
            q = (ox * d + tx * w, y, oz * d + tz * w)
            r = 0.95 - 0.5 * t
            if prev: M.capsule(prev, q, r, r, 'arms', JEL_L if k % 6 == 0 else (JEL if k % 2 else JEL_D))
            prev = q
        tip = prev
        out = (ox, -0.6, oz)
        if i % 2 == 0:                                              # garra de dos puntas, curvas
            for sg in (-1, 1):
                mid = (tip[0] + out[0] * 1.2 + tx * sg * 0.9, tip[1] + 0.6, tip[2] + out[2] * 1.2 + tz * sg * 0.9)
                M.capsule(tip, mid, 0.5, 0.45, 'arms', CLAW)
                M.cone(mid, (mid[0] + out[0] * 1.6 + tx * sg * 0.3, mid[1] - 1.6, mid[2] + out[2] * 1.6 + tz * sg * 0.3),
                       0.45, 'arms', CLAW, CLAW_L, tip_r=0.5)
        else:                                                       # pico largo y afilado
            M.cone(tip, (tip[0] + out[0] * 3.2, tip[1] - 1.0, tip[2] + out[2] * 3.2), 0.6, 'arms', CLAW, CLAW_L, tip_r=0.5)


def _jelly(M):
    """Tentáculos de medusa gris oscuro: una falda festoneada en la cintura, cinco brazos
    orales con volantes y una cortina de filamentos finos y largos que ondulan."""
    _skirt(M)
    for i in range(5):                                              # brazos orales con volantes
        a = i / 5 * math.tau + math.pi / 5
        base = (math.cos(a) * 5.6, 14.6, math.sin(a) * 5.6)
        _strand(M, base, 12.0, 0.75, 0.35, i * 1.3, 1.4, 7.0, (JEL, JEL_D, JEL_L), frill=True)
    for i in range(10):                                             # filamentos finos y largos
        a = (i + 0.5) / 10 * math.tau + 0.13 * math.sin(i * 2.1)
        _filament(M, (math.cos(a) * 6.6, 14.4, math.sin(a) * 6.6), 12.5 + 1.5 * math.sin(i * 1.7),
                  i * 0.9, 0.9 + 0.3 * math.cos(i), 8.0 + i % 3)


def _filament(M, base, length, phase, amp, freq):
    """Filamento de medusa de un voxel de grueso, continuo, con anillos más claros."""
    S = M.S
    bx, by, bz = base
    out = math.atan2(bz, bx); ox, oz = math.cos(out), math.sin(out); tx, tz = -oz, ox
    steps = int(length * S * 4)
    for i in range(steps + 1):
        t = i / steps
        y = by - length * t
        if y < 0.4: break
        w = math.sin(phase + t * freq) * amp * t ** 0.7
        x = bx + ox * 1.8 * t ** 0.8 + tx * w
        z = bz + oz * 1.8 * t ** 0.8 + tz * w + 0.6 * t
        k = int(y * S)
        c = JEL_L if k % 5 == 0 or t > 0.9 else JEL_D
        M.put(x * S, y * S, z * S, 'arms', c)


def _wing(M, s, p):
    """Ala membranosa abierta: cinco dedos óseos con nudillos y garra que salen del hombro
    en abanico y se curvan hacia atrás, membrana festoneada entre ellos, más oscura en la
    raíz y junto a los huesos, con venas rojizas y algún desgarrón."""
    S = M.S
    sh = (s * 4.5, 19.0, -1.5)
    def P(r, th):
        u, v = r * math.cos(th), r * math.sin(th)
        return (sh[0] + s * u, sh[1] + v, sh[2])                    # plano: una lámina inclinada sale a rayas
    TH = [math.radians(d) for d in (-18, 2, 22, 42, 62)]
    L = [11.5, 14.5, 15.5, 14.5, 11.0]
    BEND = -0.22
    def th_at(j, r): return TH[j] + BEND * (r / L[j]) ** 2
    # membrana
    for j in range(4):
        rmax = max(L[j], L[j + 1])
        nr = int(rmax * S * 2)
        for ir in range(2, nr + 1):
            r = ir / (S * 2)
            t0, t1 = th_at(j, min(r, L[j])), th_at(j + 1, min(r, L[j + 1]))
            span = (t1 - t0) * r
            nt = max(2, int(abs(span) * S * 2.2))
            for it in range(nt + 1):
                t = it / nt
                edge = L[j] + (L[j + 1] - L[j]) * t - 3.4 * math.sin(math.pi * t) ** 1.3
                if r > edge: continue
                x, y, z = P(r, t0 + (t1 - t0) * t)
                kx, ky, kz = int(math.floor(x * S)), int(math.floor(y * S)), int(math.floor(z * S))
                if edge - r < 2.0 and M.noise(kx, ky, kz + j * 50, 2.5) > 0.86: continue   # desgarrón
                near = min(t, 1 - t) * abs(span)
                c = lerp(WM_ROOT, WM_MID, min(1.0, r / (0.75 * edge)))
                if near < 0.9: c = lerp(WM_ROOT, c, near / 0.9)
                tv = 0.5 + 0.10 * math.sin(r * 0.9 + j)               # vena central y dos ramas
                vein = abs(t - tv) * abs(span) < 0.28 and r > 2.0
                if r > 0.55 * edge:
                    for sgn in (-1, 1):
                        tb = tv + sgn * 0.35 * (r - 0.55 * edge) / max(1.0, 0.45 * edge)
                        if abs(t - tb) * abs(span) < 0.24: vein = True
                if vein: c = lerp(c, VEIN, 0.5)
                if edge - r < 0.55: c = WM_RIM
                c = lerp(c, WM_ROOT, 0.08 * M.noise(kx, ky, kz, 6.0))
                M.put(kx, ky, kz, p, c, over=False)
                M.put(kx, ky, kz - 1, p, c, over=False)                   # dos de grosor: sin agujeros
    # dedos óseos: se afinan, con nudillos y garra curva
    M.ell(*sh, 1.3, 1.2, 1.1, p, WBONE_D)
    for j in range(5):
        n = int(L[j] * S * 2)
        prev = sh
        for i in range(1, n + 1):
            r = i / (S * 2)
            q = P(r, th_at(j, r))
            rad = 0.78 - 0.42 * (r / L[j])
            M.capsule(prev, q, rad, rad, p, WBONE if i % 7 else WBONE_D)
            prev = q
        for f in (0.38, 0.68):                                      # nudillos
            q = P(L[j] * f, th_at(j, L[j] * f))
            M.ell(*q, 0.62, 0.55, 0.55, p, WBONE_D)
        tip = P(L[j], th_at(j, L[j]))
        ext = P(L[j] + 1.6, th_at(j, L[j]) + BEND * 0.4)
        M.cone(tip, (ext[0], ext[1] - 0.9, ext[2] + 0.5), 0.55, p, WBONE_D, CLAW, tip_r=0.5)
    for k in range(3):                                              # púas del borde de ataque
        r = 4.0 + k * 3.0
        q = P(r, th_at(4, r))
        M.cone(q, (q[0], q[1] + 1.4, q[2] - 0.3), 0.45, p, WBONE, CLAW, tip_r=0.5)


PLATE = (0.20, 0.22, 0.26); PLATE_L = (0.34, 0.36, 0.40); SPEAR = (0.52, 0.48, 0.40); TIP = (0.30, 0.62, 0.55)
SLIME = (0.05, 0.07, 0.06); SLIME_G = (0.10, 0.20, 0.14)


def _guerrero(M):
    """Antiguo guerrero: el barril más oscuro, con placas como de pizarra y una cresta en la
    cabeza (la lanza se quitó en la revisión de arte del 13-10-2026)."""
    S = M.S
    for (x, y, z), v in M.V.items():
        if v[0] == 'body' and y > 6 * S and (y // 5) % 3 == 0: v[1] = PLATE if M.hsh(x, y, z) > 0.4 else PLATE_L
    for i in range(int(4 * S)):                                     # cresta
        for dz in range(-2, 2): M.put(0, int(27.5 * S) + i, dz - i // 2, 'head', PLATE)


def _mutilado(M):
    """Antiguo mutilado: un guerrero (revisión de arte del 13-10-2026) al que le faltan dos puntas
    de la estrella y al que le arrancaron dos tentáculos (quedan los muñones), con manchas del limo
    negro de los shoggoths que lo atacaron."""
    S = M.S
    for (x, y, z) in [k for k, v in M.V.items() if v[0] == 'head' and k[2] < -2 * S]: del M.V[(x, y, z)]
    for (x, y, z) in [k for k, v in M.V.items() if v[0] == 'arms' and k[0] < -S and k[1] > 18.5 * S]:
        del M.V[(x, y, z)]                                          # tentáculos arrancados: quedan los muñones
    for (x, y, z), v in M.V.items():                                # muñones en carne viva
        if v[0] == 'arms' and x < -S and 17.5 * S < y <= 18.5 * S: v[1] = (0.30, 0.12, 0.10)
    for (x, y, z), v in M.V.items():
        n = M.noise(x, y, z, 7.0)
        if n > 0.62: v[1] = SLIME if n > 0.72 else SLIME_G


for name, wings, seed, tint, var in (('antiguo', False, 7101, 0.0, 'revivido'), ('antiguo_alado', True, 7102, 0.25, ''),
                                     ('antiguo_guerrero', False, 7103, -0.1, 'guerrero'),
                                     ('antiguo_mutilado', False, 7104, 0.1, 'mutilado'),
                                     ('antiguo_despierto', False, 7102, 0.25, 'despierto')):
    M, piv = build(wings, seed, tint, var)
    n = M.export('models/%s.json' % name, piv, jitter=0.012, roughness=0.5, specular=0.45)
    print(name, n, 'voxels')
