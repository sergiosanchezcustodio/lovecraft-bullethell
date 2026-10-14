"""Atrezo de R'lyeh emergida (hito 7.5). Una parte "body", origen en el centro de la base.
Piedra verdinegra con limo; nada está a escuadra: las caras se inclinan y los ángulos no
cuadran.

  puerta     la puerta colosal: 24 m de ancho y 19 de alto, con el relieve del dios en el dintel,
             la losa negra entreabierta y el resplandor verde de dentro (16/m: pieza de borde)
  muro       tramo de muro ciclópeo de bloques que no casan, con jeroglíficos (16/m: pieza de borde)
  monolito   monolito de 6 m que se inclina en dos ejes y se tuerce al subir (64/m)
  escalera   tramo de escalera que sube a ninguna parte, con peldaños desiguales (64/m)
  bloque     bloque tallado volcado, de caras torcidas (64/m)
Todas con la sillería de Mason (rehechas en la revisión de arte del 13-10-2026; las de antes,
en tools/gen_atrezo_rlyeh_v1.py, que escribe rly_*_v1.json).

Escribe models/rly_<pieza>.json. Uso: python tools/gen_atrezo_rlyeh.py [piezas...]
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
ST = (0.29, 0.36, 0.32); ST_D = (0.16, 0.21, 0.18); ST_L = (0.44, 0.52, 0.46)   # más clara (revisión de arte del 14-10-2026): de noche era una mancha negra; las de antes, rly_*_v1
SLIME = (0.22, 0.36, 0.20); SLIME_D = (0.12, 0.22, 0.12); CARVE = (0.04, 0.06, 0.05)
JOINT = (0.05, 0.07, 0.06); VOID = (0.01, 0.02, 0.02); GLOW = (0.35, 1.0, 0.5); GLOW_D = (0.22, 0.70, 0.36)
BARN = (0.56, 0.58, 0.52); WEED = (0.16, 0.28, 0.14)


class Mason:
    """Sillería ciclópea de R'lyeh (revisión de arte del 13-10-2026). Cada cara se reparte en
    hiladas y sillares sobre una rejilla cizallada (las juntas no son ni horizontales ni
    verticales), con juntas hondas, bisel, tono por sillar, jeroglíficos hundidos en algunos
    (cabeza de pulpo con tentáculos, ojo, espiral, rombos que no cierran, filas de trazos),
    limo verde abajo y en chorretones, percebes, y alguna grieta con el fulgor verde."""

    def __init__(self, M, seed, vpm, glyphs=0.35, course=(0.45, 0.8), width=(0.7, 1.5), shear=0.35, slime_h=1.2):
        self.M, self.seed, self.vpm = M, seed, vpm
        self.glyphs, self.course, self.width, self.shear, self.slime_h = glyphs, course, width, shear, slime_h
        self.rows = {}

    def _row(self, face, v):
        """(índice, inicio, alto) de la hilada que contiene la altura v (en voxels) de la cara."""
        key = face
        if key not in self.rows:
            ys, y = [], -200 * self.vpm
            k = 0
            while y < 400 * self.vpm:
                h = int(self.vpm * (self.course[0] + (self.course[1] - self.course[0]) * self.M.hsh(k, face, self.seed)))
                ys.append((y, max(4, h))); y += max(4, h); k += 1
            self.rows[key] = ys
        lo, hi = 0, len(self.rows[key]) - 1
        rs = self.rows[key]
        while lo < hi:
            mid = (lo + hi + 1) // 2
            if rs[mid][0] <= v: lo = mid
            else: hi = mid - 1
        return lo, rs[lo][0], rs[lo][1]

    def face(self, face, u, v, x, y, z, top=False):
        """Color de un punto de una cara: (color, hundido, brillo)."""
        M = self.M
        if top:
            c = lerp(ST, ST_D, 0.5 * M.noise(x, y, z, 6.0))
            if M.noise(x, y, z, 5.0) > 0.55: c = lerp(SLIME, SLIME_D, M.noise(x, y, z, 2.0))
            if M.hsh(x, y, z) > 0.985: c = BARN
            return c, False, 0
        ri, r0, rh = self._row(face, v)
        su = u + self.shear * (v - r0) * (1 if ri % 2 else -0.6)          # juntas inclinadas, distinto por hilada
        bw = int(self.vpm * (self.width[0] + (self.width[1] - self.width[0]) * M.hsh(ri, face, self.seed + 1)))
        off = int(M.hsh(ri, face, 7) * bw)
        bi = int((su + off) // bw)
        bu = (su + off) - bi * bw
        bv = v - r0
        c = lerp(ST_D, ST_L, 0.15 + 0.55 * M.hsh(bi, ri, face * 3 + self.seed))
        c = lerp(c, ST_D, 0.35 * M.noise(x, y, z, 5.0))
        if M.noise(x, y, z, 2.0) > 0.82: c = lerp(c, ST_L, 0.5)                   # moteado
        if bu < 1.2 or bv < 1: return JOINT, True, 0                                # junta honda
        if bu < 2.2 or bv < 2: c = lerp(c, JOINT, 0.4)                              # bisel
        elif bv >= rh - 1: c = lerp(c, ST_L, 0.25)
        # jeroglífico hundido en algunos sillares grandes
        if M.hsh(bi, ri, face + 99) < self.glyphs and bw > 0.6 * self.vpm and rh > 0.4 * self.vpm:
            a = (bu - 3) / max(1.0, bw - 6); b = (bv - 3) / max(1.0, rh - 6)
            if 0 < a < 1 and 0 < b < 1 and self._glyph(int(M.hsh(bi, ri, face + 5) * 5), a, b, bw, rh):
                return CARVE, True, 0
        # limo abajo y chorretones; percebes; grietas con fulgor
        sl = self.slime_h * self.vpm * (0.6 + 0.8 * M.noise(x, 0, z, 10.0))
        if y < sl: c = lerp(c, lerp(SLIME, SLIME_D, M.noise(x, y, z, 3.0)), min(1.0, (sl - y) / (0.4 * self.vpm) + 0.3))
        if M.hsh(int(u) // 3, face, 11) > 0.9: c = lerp(c, SLIME_D, 0.5)          # chorretón
        if y < sl * 0.7 and M.hsh(x, y, z) > 0.975: c = BARN
        return c, False, 0

    def _glyph(self, kind, a, b, w, h):
        if kind == 0:                                     # cabeza de pulpo con tentáculos
            if (a - 0.5) ** 2 / 0.06 + (b - 0.72) ** 2 / 0.04 < 1 and not ((a - 0.5) ** 2 / 0.03 + (b - 0.72) ** 2 / 0.02 < 1): return True
            for k in range(5):
                tx = 0.2 + k * 0.15 + 0.06 * math.sin(b * 12 + k)
                if b < 0.55 and abs(a - tx) < 0.035: return True
            return False
        if kind == 1:                                     # rombos que no cierran
            d = abs(a - 0.5) + abs(b - 0.5) * 1.2
            return any(abs(d - r) < 0.03 for r in (0.12, 0.25, 0.38)) and not (a > 0.55 and b > 0.5)
        if kind == 2:                                     # ojo
            e = (a - 0.5) ** 2 / 0.16 + (b - 0.5) ** 2 / 0.035
            return abs(e - 1) < 0.25 or (a - 0.5) ** 2 + (b - 0.5) ** 2 < 0.006
        if kind == 3:                                     # espiral
            r = math.hypot(a - 0.5, b - 0.5); t = math.atan2(b - 0.5, a - 0.5)
            return r < 0.45 and abs(((r * 25 - t) % (2 * math.pi))) < 0.9
        rows = 4                                          # filas de trazos
        rb = (b * rows) % 1
        col = int(a * 9)
        return 0.25 < rb < 0.75 and (a * 9) % 1 < 0.45 and ((col * 7 + int(b * rows) * 3) % 5) != 0

    def put(self, x, y, z, face, u, v, nx, nz, top=False):
        """Pone el voxel de superficie (y el de detrás, por si hay que hundirlo)."""
        c, sunk, gl = self.face(face, u, v, x, y, z, top)
        M = self.M
        if top:
            M.put(x, y, z, P, c); return
        bx, bz = x - nx, z - nz
        if sunk:
            M.put(bx, y, bz, P, c)
        else:
            M.put(x, y, z, P, c); M.put(bx, y, bz, P, lerp(c, ST_D, 0.3), over=False)

    def box(self, cx, cz, y0, y1, hx, hz, yaw=0.0, shx=0.0, shz=0.0, taper=0.0, twist=0.0, face0=0, top=True):
        """Prisma: sección rectangular de semilados (hx, hz) en voxels, girada yaw grados, que se
        desplaza (shx, shz) voxels por voxel de altura, se estrecha (taper, fracción) y se tuerce
        (twist, grados en toda la altura). Se emite solo la superficie."""
        H = max(1, y1 - y0)
        for y in range(y0, y1):
            t = (y - y0) / H
            ax, az = hx * (1 - taper * t), hz * (1 - taper * t)
            ang = math.radians(yaw + twist * t)
            ca, sa = math.cos(ang), math.sin(ang)
            ox, oz = cx + shx * (y - y0), cz + shz * (y - y0)
            def W(u, w): return ox + u * ca - w * sa, oz + u * sa + w * ca
            n = int(2 * ax * 2) + 2
            for i in range(n + 1):
                u = -ax + 2 * ax * i / n
                for sgn, fid in ((1, face0), (-1, face0 + 1)):
                    wx, wz = W(u, sgn * az)
                    nx, nz = -sa * sgn, ca * sgn
                    self.put(int(round(wx)), y, int(round(wz)), fid, u + ax, y - y0 + (0 if fid % 2 else 0), int(round(nx)), int(round(nz)))
            n = int(2 * az * 2) + 2
            for i in range(n + 1):
                w = -az + 2 * az * i / n
                for sgn, fid in ((1, face0 + 2), (-1, face0 + 3)):
                    wx, wz = W(sgn * ax, w)
                    nx, nz = ca * sgn, sa * sgn
                    self.put(int(round(wx)), y, int(round(wz)), fid, w + az, y - y0, int(round(nx)), int(round(nz)))
        if top:                                                        # tapa de arriba
            y = y1 - 1; t = 1.0
            ax, az = hx * (1 - taper), hz * (1 - taper)
            ang = math.radians(yaw + twist); ca, sa = math.cos(ang), math.sin(ang)
            ox, oz = cx + shx * (y - y0), cz + shz * (y - y0)
            R = int(math.hypot(ax, az)) + 2
            for x in range(int(ox) - R, int(ox) + R + 1):
                for z in range(int(oz) - R, int(oz) + R + 1):
                    dx, dz = x - ox, z - oz
                    u = dx * ca + dz * sa; w = -dx * sa + dz * ca
                    if abs(u) <= ax and abs(w) <= az:
                        self.put(x, y, z, face0 + 4, u, w, 0, 0, top=True)


def crack_glow(M, n, area, seed):
    """Grietas con el fulgor verde que serpentean por las caras (sobre voxels que ya existen)."""
    rng = M.rng
    keys = [k for k in M.V if area(*k)]
    if not keys: return
    for _ in range(n):
        x, y, z = keys[rng.randrange(len(keys))]
        for _ in range(rng.randint(20, 60)):
            v = M.V.get((x, y, z))
            if v is not None: v[1] = GLOW_D if M.hsh(x, y, z) > 0.4 else GLOW; v[2] = 1
            y -= 1
            x += rng.choice((-1, 0, 0, 1)); z += rng.choice((0, 0, 0, -1, 1))
            if (x, y, z) not in M.V:
                for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    if (x + d[0], y, z + d[1]) in M.V: x += d[0]; z += d[1]; break
                else: break


def weeds(M, n, rx, rz, seed):
    """Algas y matas al pie."""
    rng = M.rng
    for _ in range(n):
        x, z = rng.randint(-rx, rx), rng.randint(-rz, rz)
        for k in range(rng.randint(3, 10)):
            M.put(x + (k // 4) * rng.choice((-1, 1)), k, z, P, WEED if k % 3 else SLIME_D, over=False)


def bloque():
    """Bloque tallado volcado de caras torcidas (64/m): un sillar enorme que se tuerce sobre sí
    mismo, con una esquina rota a su lado, jeroglíficos, limo y una grieta con el fulgor."""
    M = Model(S=4, seed=115); V = 64
    m = Mason(M, 115, V, glyphs=0.7, course=(0.5, 0.9), width=(0.8, 1.4), slime_h=0.35)
    m.box(0, 0, 0, int(1.05 * V), int(0.80 * V), int(0.55 * V), yaw=8, shx=0.25, shz=-0.12, twist=9)
    m.box(int(0.95 * V), int(0.5 * V), 0, int(0.35 * V), int(0.25 * V), int(0.2 * V), yaw=31, shx=-0.2, twist=-14, face0=10)
    m.box(int(-0.9 * V), int(0.55 * V), 0, int(0.18 * V), int(0.16 * V), int(0.12 * V), yaw=-22, face0=20)
    crack_glow(M, 2, lambda x, y, z: y > 20, 1)
    weeds(M, 26, int(1.1 * V), int(0.8 * V), 1)
    return M, {P: [0, 0, 0]}


def escalera():
    """Escalera que sube a ninguna parte (64/m): diez peldaños de alturas y giros desiguales,
    cada uno con su sillería, entre dos zancas de piedra que se inclinan hacia fuera."""
    M = Model(S=4, seed=114); V = 64
    m = Mason(M, 114, V, glyphs=0.25, course=(0.25, 0.4), width=(0.5, 1.0), slime_h=0.4)
    y = 0
    for i in range(10):                                         # peldaños: el más bajo delante
        h = int(V * (0.12 + 0.08 * M.hsh(i, 1, 1)))
        zc = int(1.3 * V - i * 0.28 * V)
        m.box(int(i * 0.12 * V), zc, 0, y + h, int(0.72 * V), int(0.16 * V) + 3,
              yaw=(i * 7) % 11 - 5, face0=i * 6)
        for s in (-1, 1):                                       # zanca escalonada a cada lado
            m.box(int(i * 0.12 * V + s * 0.86 * V), zc, 0, y + h + int(0.18 * V), int(0.11 * V), int(0.16 * V) + 3,
                  yaw=(i * 7) % 11 - 5 + 4 * s, shx=0.05 * s, face0=100 + i * 12 + (s + 1) * 3)
        y += h
    tops = {}                                                   # macizo bajo cada columna: así el vaciado quita lo de dentro
    for (x, y, z) in M.V:
        if y > tops.get((x, z), -1): tops[(x, z)] = y
    for (x, z), yt in tops.items():
        for y in range(0, yt):
            if (x, y, z) not in M.V: M.put(x, y, z, P, ST_D)
    crack_glow(M, 2, lambda x, y, z: y > 30, 2)
    weeds(M, 20, int(1.2 * V), int(1.6 * V), 2)
    return M, {P: [0, 0, 0]}


def monolito():
    """Monolito torcido de 6 m (64/m): se inclina en dos ejes y gira sobre sí mismo al subir, se
    estrecha, con bandas de jeroglíficos en todas sus caras, la punta partida y una grieta con el
    fulgor verde."""
    M = Model(S=4, seed=113); V = 64
    m = Mason(M, 113, V, glyphs=0.65, course=(0.35, 0.6), width=(0.5, 0.9), slime_h=1.4)
    H = int(5.6 * V)
    m.box(0, 0, 0, H, int(0.42 * V), int(0.28 * V), yaw=0, shx=0.11, shz=0.045, taper=0.35, twist=26)
    m.box(int(0.11 * H) + 6, int(0.045 * H), H, H + int(0.45 * V), int(0.2 * V), int(0.16 * V), yaw=40, shx=0.3, face0=10)   # punta partida
    for _ in range(3):                                          # cascotes al pie
        a = M.rng.uniform(0, math.tau)
        m.box(int(math.cos(a) * 0.7 * V), int(math.sin(a) * 0.6 * V), 0, int(0.15 * V), int(0.12 * V), int(0.1 * V),
              yaw=M.rng.uniform(0, 90), face0=20)
    crack_glow(M, 3, lambda x, y, z: 40 < y < H - 20, 3)
    weeds(M, 30, int(0.8 * V), int(0.7 * V), 3)
    return M, {P: [0, 0, 0]}


def muro():
    """Tramo de muro ciclópeo (16/m, sin reducir): 24 m de largo y hasta 10 de alto, hecho de
    bloques enormes que se apilan cada uno con su propio giro e inclinación, de modo que las
    caras no casan; remate roto, jeroglíficos, limo, percebes y grietas con el fulgor."""
    M = Model(S=1, seed=112); V = 16
    m = Mason(M, 112, V, glyphs=0.3, course=(0.6, 1.1), width=(1.0, 2.4), slime_h=1.6)
    x = -12 * V
    i = 0
    while x < 12 * V:
        w = int(V * (2.6 + 2.0 * M.hsh(i, 0, 1)))
        y = 0
        for k in range(3):
            h = int(V * (2.0 + 2.2 * M.hsh(i, k, 2)))
            if k == 2 and M.hsh(i, 3, 3) > 0.55: break                         # remate roto
            m.box(x + w // 2, -int(1.4 * V) + int(k * 0.2 * V), y, y + h, w // 2 + 2, int((1.3 - 0.15 * k) * V),
                  yaw=(M.hsh(i, k, 4) - 0.5) * 9, shz=0.12 + 0.05 * k, shx=(M.hsh(i, k, 5) - 0.5) * 0.25, face0=(i * 3 + k) * 6)
            y += h - 2
        x += w - 2; i += 1
    tops = {}                                                   # macizo bajo cada columna: así el vaciado quita lo de dentro
    for (x, y, z) in M.V:
        if y > tops.get((x, z), -1): tops[(x, z)] = y
    for (x, z), yt in tops.items():
        for y in range(0, yt):
            if (x, y, z) not in M.V: M.put(x, y, z, P, ST_D)
    crack_glow(M, 8, lambda x, y, z: y > 10, 4)
    return M, {P: [0, 0, 0]}


def puerta():
    """La puerta colosal de R'lyeh (16/m, sin reducir; más grande: 24 m de ancho y 19 de alto).
    Jambas de sillería que se inclinan hacia dentro cada una a su manera, dintel torcido con un
    relieve enorme del dios dormido (cabeza de pulpo, tentáculos y alas), basamento de tres
    gradas desiguales, y la losa negra entreabierta con la rendija de luz verde y su resplandor
    en el umbral."""
    M = Model(S=1, seed=111); V = 16
    m = Mason(M, 111, V, glyphs=0.35, course=(0.7, 1.2), width=(1.2, 2.4), slime_h=2.0)
    # gradas del basamento
    y = 0
    for k in range(3):
        h = int(V * (0.45 + 0.25 * M.hsh(k, 1, 1)))
        m.box(0, int(-1.6 * V + k * 0.35 * V), y, y + h, int((12.5 - k * 0.6) * V), int((2.6 - k * 0.45) * V), yaw=(k - 1) * 1.5, face0=k * 6)
        y += h
    base = y
    # jambas
    JH = int(13.5 * V)
    m.box(int(-8.4 * V), int(-1.5 * V), base, base + JH, int(2.2 * V), int(1.4 * V), shx=0.17, yaw=-3, taper=0.12, face0=30)
    m.box(int(8.0 * V), int(-1.5 * V), base, base + JH, int(2.0 * V), int(1.4 * V), shx=-0.09, yaw=4, taper=0.08, face0=40)
    # dintel torcido (tramos con su propia altura) y el relieve del dios
    for j in range(8):
        xa = int((-11.5 + j * 3.0) * V)
        yb = base + JH - 6 + int(j * 0.12 * V)
        m.box(xa + int(1.5 * V), int(-1.4 * V), yb, yb + int(2.6 * V), int(1.5 * V) + 2, int(1.5 * V), yaw=-2 + j * 0.6,
              shz=0.05, face0=50 + j * 6)
    fz = int(-1.4 * V + 1.5 * V) + int(0.05 * 2.6 * V)
    cy = base + JH + int(1.4 * V)
    for x in range(-int(5.0 * V), int(5.0 * V)):
        for y in range(cy - int(1.25 * V), cy + int(1.25 * V)):
            a, b = x / (5.0 * V), (y - cy) / (1.25 * V)
            head = (a / 0.28) ** 2 + ((b - 0.2) / 0.75) ** 2 < 1
            wing = abs(a) > 0.32 and abs(a) < 0.95 and b > -0.2 + 0.8 * (abs(a) - 0.32) - 0.15 * math.sin(abs(a) * 18) ** 2 and b < 0.85 - 0.4 * abs(a)
            tent = b < -0.1 and any(abs(a - (k - 3) * 0.06 - 0.05 * math.sin(b * 9 + k)) < 0.022 for k in range(7))
            eye = abs(abs(a) - 0.1) < 0.04 and abs(b - 0.25) < 0.08
            if not (head or wing or tent): continue
            zz = fz + 2
            c = lerp(ST_L, (0.46, 0.54, 0.48), 0.6) if (x + y) % 5 else ST_L
            if eye: M.put(x, y, zz, P, GLOW_D, glow=1); continue
            M.put(x, y, zz, P, c)
            if head: M.put(x, y, zz + 1, P, lerp(c, ST_D, 0.2))
    # la losa entreabierta, la rendija y el resplandor
    for y in range(base, base + JH - 4):
        lx = int(-8.4 * V + 2.2 * V + 0.17 * (y - base)) + 2
        rx = int(8.0 * V - 2.0 * V - 0.09 * (y - base)) - 2
        mid = (lx + rx) // 2 + int(1.5 * V)
        for x in range(lx, rx):
            if abs(x - mid) <= 3:
                M.put(x, y, int(-1.6 * V), P, GLOW if abs(x - mid) < 2 else GLOW_D, glow=1); continue
            c = VOID if x < mid else (0.03, 0.05, 0.04)
            if (y // 24 + x // 40) % 7 == 0: c = (0.05, 0.07, 0.06)            # vetas en la losa
            M.put(x, y, int(-2.2 * V) if x < mid else int(-1.4 * V), P, c)
    for x in range(-int(5.5 * V), int(5.5 * V)):                             # resplandor en el umbral
        for z in range(int(-1.4 * V), int(1.0 * V)):
            d = abs(x - int(1.5 * V)) / (5.5 * V) + abs(z) / (1.2 * V)
            if d < 1 and M.hsh(x, base, z) > 0.55 + 0.4 * d: M.put(x, base, z, P, GLOW_D, glow=1)
    crack_glow(M, 12, lambda x, y, z: y > base + 10, 5)
    return M, {P: [0, 0, 0], 'light': [int(1.5 * V), base + int(3 * V), int(-1.0 * V)]}


PIECES = {'puerta': puerta, 'muro': muro, 'monolito': monolito, 'escalera': escalera, 'bloque': bloque}

if __name__ == '__main__':
    only = set(sys.argv[1:])
    for name, fn in PIECES.items():
        if only and name not in only: continue
        M, piv = fn()
        nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
        for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]:
            del M.V[k]                                          # hueco: lo de dentro no se ve
        n = M.export('models/rly_%s.json' % name, piv, jitter=0.006, pivots_in_voxels=True,
                     roughness=0.55, specular=0.4, no_bottom=True)
        print('rly_%s: %d voxels' % (name, n))
