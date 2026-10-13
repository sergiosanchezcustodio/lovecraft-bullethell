"""La cosa blanca polipoide del lago oculto (fase 7, hito 7.4; rehecha en la revisión de arte del
13-10-2026 como calamar gigante deforme). Unos 1,4 m: manto alto, abultado y torcido hacia atrás
con aletas en la punta y pólipos que le brotan; cabeza con un único ojo negro enorme, algo
descentrado; una mata de tentáculos pequeños que se retuercen en la cabeza; ocho brazos que se
arrastran por el suelo con ventosas rosadas y la punta enroscada, y dos tentáculos largos de caza
con maza. Blanco azulado translúcido con venas rosadas; las bocas de los pólipos brillan apenas.

32 voxels/m (S=2). Partes: body (cabeza y brazos), top (manto y tentáculos de la cabeza),
pod_l, pod_r (tentáculos de caza): las del fragmento protoplásmico, para animarlo con
anim_fragmento.gd. Variante `polipo_madre` (evento final, a 2,4 en el juego), más deforme.
La versión anterior (masa de pólipos) queda en tools/gen_polipo_v1.py.
Uso: python tools/gen_polipo.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

B, TOP, PL, PR = 'body', 'top', 'pod_l', 'pod_r'
WHITE = (0.86, 0.88, 0.90); WHITE_D = (0.66, 0.70, 0.76); BLUE = (0.72, 0.80, 0.88)
VEIN = (0.80, 0.52, 0.56); SUCK = (0.86, 0.60, 0.64); SUCK_D = (0.56, 0.30, 0.36)
MOUTH = (0.30, 0.08, 0.12); GLOW = (0.80, 0.95, 1.0)
EYE = (0.02, 0.02, 0.03); EYE_RIM = (0.40, 0.42, 0.48); SHINE = (0.92, 0.95, 1.0); BEAK = (0.14, 0.10, 0.10)


def build(name, seed, size, lumps):
    M = Model(S=2, seed=seed)
    rng = M.rng
    def sc(*p): return [q * size for q in p]
    # ---------- manto: alto, torcido hacia atrás y a un lado, abultado ----------
    n = 26
    for i in range(n + 1):
        t = i / n
        x = 1.6 * math.sin(t * 2.2) + 0.8 * t                       # se tuerce
        y = 13 + 17 * t
        z = -1 - 9 * t ** 1.3
        r = 6.2 * (1 - t) ** 0.7 + 1.0
        M.ell(*sc(x, y, z), *sc(r, r * 0.8, r * 0.9), TOP, WHITE)
    tip = sc(0.8 + 1.6 * math.sin(2.2), 30, -10)
    for s in (-1, 1):                                               # aletas en la punta, algo desiguales
        for k in range(10):
            f = k / 9
            w = (5.0 + (1.2 if s > 0 else -0.6)) * math.sin(math.pi * f) ** 0.8
            for j in range(int(w * 2 * size) + 1):
                x = tip[0] + s * (1.2 * size + j / 2)
                y = tip[1] - (6 * f - 1) * size
                z = tip[2] + (2.5 * f - 1) * size
                M.put(int(x * 2), int(y * 2), int(z * 2), TOP, WHITE_D if j % 3 == 0 else WHITE, over=False)
    for i in range(lumps):                                          # bultos y pólipos que le brotan
        t = rng.uniform(0.15, 0.85)
        x = 1.6 * math.sin(t * 2.2) + 0.8 * t; y = 13 + 17 * t; z = -1 - 9 * t ** 1.3
        r = 6.2 * (1 - t) ** 0.7 + 1.0
        a = rng.uniform(0, math.tau)
        px, py, pz = x + math.cos(a) * r * 0.85, y + rng.uniform(-1, 1), z + math.sin(a) * r * 0.8
        lr = rng.uniform(1.4, 2.6)
        M.ell(*sc(px, py, pz), *sc(lr, lr, lr), TOP, WHITE)
        if rng.random() < 0.5:                                      # boca de pólipo
            mx, my, mz = [int(q * 2) for q in sc(px + math.cos(a) * lr, py, pz + math.sin(a) * lr * 0.9)]
            M.put(mx, my, mz, TOP, MOUTH); M.put(mx, my + 1, mz, TOP, GLOW, glow=1)
    # ---------- cabeza ----------
    M.ell(*sc(0, 10.5, 1.0), *sc(6.2, 5.0, 6.0), B, WHITE)
    M.ell(*sc(-2.2, 9.5, 2.5), *sc(3.0, 3.0, 3.0), B, WHITE)        # deforme: hinchada de un lado
    # el ojo: uno solo, negro y enorme, algo descentrado, con borde y un brillo
    ex, ey, ez = sc(1.6, 11.5, 5.0)
    er = 3.0 * size
    M.ell(ex, ey, ez, er + 0.4, er + 0.4, er * 0.8 + 0.4, B, EYE_RIM)
    M.ell(ex, ey, ez + 0.5 * size, er, er, er * 0.8, B, EYE)
    BLOOD = (0.72, 0.04, 0.05)
    nv = 8 + int(4 * (size - 1) * 4)
    veins = [(i / nv * math.tau + rng.uniform(-0.2, 0.2), rng.uniform(0.35, 0.6), rng.uniform(0, 6)) for i in range(nv)]
    cxv, cyv = ex * 2, ey * 2; R = (er + 0.4) * 2
    for (x, y, z), v in list(M.V.items()):                          # venas finas rojo sangre: del borde hacia dentro
        if v[0] != B or v[1] not in (EYE, EYE_RIM) or z < (ez - 0.2 * er) * 2: continue
        dx, dy = x + 0.5 - cxv, y + 0.5 - cyv
        rr = math.hypot(dx, dy) / R
        ang = math.atan2(dy, dx)
        for (a0, r0, ph) in veins:
            if rr < r0: continue
            aa = a0 + 0.35 * math.sin(ph + rr * 7) * (1 - rr)          # se retuercen
            d = abs((ang - aa + math.pi) % math.tau - math.pi) * math.hypot(dx, dy)
            br = abs((ang - aa - 0.5 * (rr - r0) - 0.3 + math.pi) % math.tau - math.pi) * math.hypot(dx, dy)   # una rama
            if d < 0.55 or (rr > r0 + 0.2 and br < 0.5):
                v[1] = BLOOD; break
    for (dx, dy) in ((-1, 2), (-2, 2), (-1, 3)):                    # brillo
        x, y = int(ex * 2) + dx, int(ey * 2) + dy
        z = M.front(x, y, int((ez + er) * 2) + 4, 0)
        if z is not None: M.V[(x, y, z)] = [B, SHINE, 1]
    # tentáculos pequeños en la cabeza, que se retuercen hacia arriba
    nt = 10 + int(16 * (size - 1))
    for i in range(nt):
        a = math.radians(-100 + 200 * i / (nt - 1)) + rng.uniform(-0.12, 0.12)   # por delante y los lados
        ox, oz = math.sin(a), math.cos(a)
        bx, by, bz = 5.2 * ox, 13.5 + rng.uniform(-1.0, 1.5), 1.0 + 4.8 * oz
        L = rng.uniform(5.5, 8.5); ph = rng.uniform(0, 6)
        for k in range(int(L * 4)):
            t = k / (L * 4)
            x = bx + ox * 3.0 * t + math.sin(ph + t * 7) * 0.9
            y = by + L * t * 0.8
            z = bz + oz * 3.0 * t + math.cos(ph + t * 6) * 0.9
            r = 1.0 * (1 - t) + 0.4
            M.ell(*sc(x, y, z), *sc(r, r, r), TOP, WHITE_D if k % 5 else VEIN)
    # ---------- ocho brazos que se arrastran ----------
    M.ell(*sc(0, 5.5, 1.5), *sc(4.2, 2.6, 4.0), B, WHITE)           # corona de los brazos
    M.ell(*sc(0, 4.2, 3.6), *sc(1.0, 0.9, 1.0), B, BEAK)            # pico entre los brazos
    for i in range(8):
        a = math.radians((i - 3.5) * 32 + rng.uniform(-8, 8))     # sobre todo hacia delante y los lados
        dx, dz = math.sin(a), math.cos(a)
        L = rng.uniform(10, 14) * (0.8 if abs(i - 3.5) > 3 else 1.0)
        ph = rng.uniform(0, 6)
        steps = int(L * 4)
        for k in range(steps):
            t = k / steps
            d = 3.0 + L * t
            w = math.sin(ph + t * 6) * 1.6 * t                      # ondula de lado
            curl = max(0.0, t - 0.8) / 0.2
            x = dx * d - dz * w
            z = 1.5 + dz * d + dx * w
            y = max(0.9, 5.0 - 9 * t) + curl ** 2 * 2.5             # baja al suelo y la punta se enrosca
            r = 1.5 * (1 - t) + 0.45
            M.ell(*sc(x, y, z), *sc(r, r * 0.8, r), B, WHITE)
            if k % 3 == 1 and t < 0.85:                             # ventosas (por arriba, que se vean)
                M.put(int(x * 2 * size), int((y + r * 0.8) * 2 * size), int(z * 2 * size), B, SUCK if k % 2 else SUCK_D)
    # ---------- dos tentáculos de caza con maza ----------
    for s, P in ((-1, PL), (1, PR)):
        base = (s * 3.0, 7.0, 3.5)
        steps = int(18 * 4)
        for k in range(steps):
            t = k / steps
            x = base[0] + s * 7.5 * t + math.sin(t * 5 + s) * 0.8
            y = base[1] + math.sin(t * math.pi) * 2.5 - 5.0 * t
            z = base[2] + 14.0 * t
            r = 1.1 * (1 - t) + 0.5
            M.ell(*sc(x, max(0.8, y), z), *sc(r, r, r), P, WHITE if k % 10 else VEIN)
        cx, cy, cz = base[0] + s * 7.5, max(1.4, base[1] - 5.0 + 0.6), base[2] + 14.0 + 1.5
        M.ell(*sc(cx, cy, cz), *sc(1.6, 1.0, 2.6), P, WHITE)       # maza
        for k in range(10):                                         # ventosas de la maza
            M.put(int((cx + (k % 2 - 0.5) * 1.6) * 2 * size), int((cy + 1.0) * 2 * size),
                  int((cz - 2.0 + k * 0.45) * 2 * size), P, SUCK if k % 3 else SUCK_D)
    # ---------- color: translúcido, azulado, con venas ----------
    for (x, y, z), v in list(M.V.items()):
        if v[1] != WHITE: continue
        c = lerp(WHITE, BLUE, M.noise(x, y, z, 6.0) * 0.7)
        if M.noise(x, y, z, 2.5) > 0.88: c = VEIN
        M.V[(x, y, z)] = [v[0], c, v[2]]
    piv = {B: [0, 0, 0], TOP: [0, int(13 * size * 2), 0],
           PL: [int(-3 * size * 2), int(7 * size * 2), int(3.5 * size * 2)], PR: [int(3 * size * 2), int(7 * size * 2), int(3.5 * size * 2)]}
    n = M.export('models/%s.json' % name, piv, jitter=0.012, pivots_in_voxels=True, roughness=0.3, specular=0.6,
                 parents={TOP: B, PL: B, PR: B})
    print(name, n, 'voxels')


build('polipo', 1925, 1.0, 6)
build('polipo_madre', 1926, 1.25, 14)
