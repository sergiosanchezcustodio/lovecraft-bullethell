"""Criaturas de la noche suelta «El que acecha en la oscuridad» (hito 23.8), en Federal Hill.

  sectario_estrellado  lo que queda de la secta de la Sabiduría Estrellada: túnica larga morada casi
                       negra con la capucha puesta, la estrella de plata bordada en el pecho, cara gris y
                       chupada con ojeras, descalzo, y una pértiga de hierro con gancho de apagar
                       farolas en la mano derecha. Humano a bloques (cuerpo.py, anim_humano)
  sombra_alada         una sombra del campanario: cuerpo de humo negro, alas de murciélago de membrana
                       (pod_l, pod_r) y un solo ojo rojo que arde (anim_fragmento: body, top, pod_l, pod_r)
  morador_tinieblas    el jefe, el Morador de las Tinieblas: una negrura alada enorme, más humo que
                       cuerpo, con jirones que cuelgan, dos alas inmensas desgarradas y en medio el ojo
                       de tres lóbulos, rojo y amarillo, que arde (anim_fragmento)

Escribe models/<nombre>.json. Uso: python tools/gen_noche_acecha.py [sectario_estrellado|sombra_alada|morador_tinieblas]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import cuerpo as cu
from cuerpo import slab, rslab, T, H

BLACK = (0.03, 0.03, 0.04); BLACK_L = (0.08, 0.07, 0.10); SMOKE = (0.20, 0.18, 0.24)
MEMB = (0.12, 0.07, 0.11); MEMB_L = (0.22, 0.11, 0.15); BONE = (0.34, 0.30, 0.32)
EYE = (1.0, 0.30, 0.12); EYE_W = (1.0, 0.78, 0.30); EYE_D = (0.62, 0.08, 0.05)


# ---------------- el sectario ----------------

def sectario_estrellado():
    MATS = {}
    def mat(col, m):
        MATS[col] = m
        return col
    SKIN = (0.58, 0.55, 0.53); SKIN_SH = (0.47, 0.44, 0.43)
    ROBE = mat((0.13, 0.09, 0.15), 'lana'); ROBE_SH = mat((0.08, 0.05, 0.10), 'lana')
    SILVER = (0.74, 0.76, 0.82); SILVER_D = (0.46, 0.48, 0.56)
    ROPE = (0.30, 0.26, 0.22); IRON = (0.10, 0.10, 0.11); IRON_L = (0.26, 0.26, 0.28)
    M = cu.new(2381)
    for s_, _, shin, _, _ in cu.sides():                              # descalzo
        slab(M, shin, SKIN_SH, 0, 3, 5 * s_, 2, 8, 8, 13, 12, ch=1)
    cu.legs(M, ROBE, bottom=3)
    cu.torso(M, ROBE, b=0, bottom=30)
    cu.skirt(M, ROBE, 3, top=40, b=0, flare=4, depth=13)
    for y in range(3, 40, 3):                                         # pliegues
        for x in (-9, -4, 3, 8): cu.front(M, x, y, ROBE_SH)
    cu.belt(M, ROPE, y=43, b=0, h=1)
    cu.neck(M, SKIN)
    cu.arms(M, ROBE, SKIN, cuff=ROBE_SH)
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, (0.30, 0.26, 0.26), eye=(0.70, 0.66, 0.60), white=(0.78, 0.76, 0.72), brow_style='caida')
    cu.mouth(M, (0.36, 0.28, 0.30))
    for x in range(-6, 6):                                            # ojeras
        for y in (71, 72):
            if abs(x + 0.5) > 1.5 and abs(x + 0.5) < 5.5: cu.paint_face(M, x, y, (0.40, 0.34, 0.38))
    # la capucha puesta, abierta delante
    rslab(M, H, ROBE, 64, 84, 0, -1.0, 19, 19, r=5, rt=6, rb=0, over=False)
    for k in [k for k, v in M.V.items() if v[0] == H and v[1] == ROBE and k[2] > 5 and 64 <= k[1] <= 79 and abs(k[0] + 0.5) < 7.5]:
        del M.V[k]
    for y in range(64, 79):
        for x in (-8, 7): M.put(x, y, 7, H, ROBE_SH)
    # la estrella de plata en el pecho: cinco puntas
    cx, cy = -0.5, 52
    for x in range(-6, 6):
        for y in range(46, 59):
            a = math.atan2(y - cy, x + 0.5 - cx)
            r = math.hypot(x + 0.5 - cx, y - cy)
            kk = (a - math.pi / 2) % (2 * math.pi / 5)
            dev = min(kk, 2 * math.pi / 5 - kk) / (math.pi / 5)        # 0 en una punta, 1 entre dos
            lim = 2.2 + 3.8 * (1 - dev)
            if r < lim: cu.front(M, x, y, SILVER if r < lim - 0.9 else SILVER_D, dz=1)
    # la pértiga de apagar farolas en la mano derecha, con el gancho arriba
    x = int(cu.ARM_X)
    for y in range(14, 92):
        for dx in (0, 1):
            M.put(x + dx, y, 6, 'fore_r', IRON if y % 9 else IRON_L)
    for y in range(92, 98): M.put(x + 1 + (y - 92) // 2, y, 6, 'fore_r', IRON)
    for i in range(5): M.put(x + 4 - i, 98 + (1 if i in (1, 2, 3) else 0), 6, 'fore_r', IRON)
    cu.finish(M, 'sectario_estrellado', dict(MATS), flat=(SILVER, SILVER_D, IRON, IRON_L, ROPE), roughness=0.9, specular=0.2,
              skirt=True)


# ---------------- lo que vive a oscuras ----------------

def _eye(M, part, cx, cy, cz, r, lobes=1):
    """El ojo que arde, en la cara de delante (+z): uno, o tres lóbulos en triángulo."""
    if lobes == 1: centers = [(cx, cy)]
    else: centers = [(cx + r * 1.05 * math.cos(a), cy + r * 1.05 * math.sin(a)) for a in (math.pi / 2, math.pi * 7 / 6, math.pi * 11 / 6)]
    for (ex, ey) in centers:
        for x in range(int(ex - r) - 1, int(ex + r) + 2):
            for y in range(int(ey - r) - 1, int(ey + r) + 2):
                d = math.hypot(x + 0.5 - ex, y + 0.5 - ey)
                if d > r: continue
                c = EYE_W if d < r * 0.35 else (EYE if d < r * 0.8 else EYE_D)
                for z in range(cz - 1, cz + 1): M.put(x, y, z, part, c, 1)


def _wing(M, part, s, span, root, h, seed):
    """Ala de murciélago de membrana hacia el lado `s`: huesos (dedos) que salen del hombro y la
    membrana entre ellos con el borde festoneado y algún desgarro."""
    rx, ry, rz = root
    fingers = 4
    tips = []
    for i in range(fingers):
        a = math.radians(62 - i * 34)                                  # de arriba a abajo
        L = span * (1.0 - 0.15 * abs(i - 1))
        tips.append((rx + s * L * math.cos(a) * 1.1, ry + L * math.sin(a) * 0.9, rz - i * 2))
    for (tx, ty, tz) in tips:                                          # los dedos
        n = int(abs(tx - rx)) + 1
        for j in range(n):
            t = j / max(n - 1, 1)
            x, y, z = rx + (tx - rx) * t, ry + (ty - ry) * t, rz + (tz - rz) * t
            for dy in (0, 1): M.put(int(round(x)), int(round(y)) + dy, int(round(z)), part, BONE)
    for i in range(fingers - 1):                                       # la membrana entre cada dos
        a, b = tips[i], tips[i + 1]
        for j in range(120):
            t = j / 119.0
            ex, ey, ez = a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t
            sag = math.sin(t * math.pi) * h * 0.2                    # festón: la membrana cuelga entre dedos
            ex2, ey2 = ex, ey - sag
            n = int(max(abs(ex2 - rx), abs(ey2 - ry))) + 1
            for k in range(n):
                u = k / max(n - 1, 1)
                x, y, z = rx + (ex2 - rx) * u, ry + (ey2 - ry) * u, rz + (ez - rz) * u
                key = (int(round(x)), int(round(y)), int(round(z)))
                if M.noise(key[0], key[1], seed, 4.0) > 0.8 and u > 0.6: continue    # desgarro
                c = MEMB if M.noise(key[0], key[1], key[2], 5.0) > 0.4 else MEMB_L
                if key not in M.V: M.put(*key, part, c)


def _smoke_body(M, cy, rx, ry, rz, seed, tatters=8, tlen=20):
    """El cuerpo de humo: un elipsoide de negrura con borde que se deshace, y jirones que cuelgan."""
    for x in range(-rx - 2, rx + 3):
        for y in range(cy - ry - 2, cy + ry + 3):
            for z in range(-rz - 2, rz + 3):
                q = (x / rx) ** 2 + ((y - cy) / ry) ** 2 + (z / rz) ** 2
                edge = 0.75 + 0.35 * M.noise(x, y, z, 4.0)
                if q > edge: continue
                c = lerp(BLACK, BLACK_L, M.noise(x, y, z, 5.0))
                if q > edge - 0.12: c = lerp(c, SMOKE, 0.6)
                M.put(x, y, z, 'body', c)
    for i in range(tatters):                                           # jirones
        a = i / tatters * math.tau + 0.3
        bx, bz = math.cos(a) * rx * 0.6, math.sin(a) * rz * 0.6
        L = int(tlen * (0.6 + 0.4 * M.hsh(i, seed, 1)))
        for j in range(L):
            x = int(bx + math.sin(j * 0.4 + i) * 1.5)
            y = cy - int(ry * 0.6) - j
            w = 2 if j < L * 0.6 else 1
            for dx in range(-w, w):
                for dz in range(-1, 1): M.put(x + dx, y, int(bz) + dz, 'body', SMOKE if j > L * 0.5 else BLACK_L)


def sombra_alada():
    """Una sombra de 1,3 m de envergadura a escala 1."""
    M = Model(S=2, seed=2382)
    CY = 22
    _smoke_body(M, CY, 6, 8, 5, 3, tatters=6, tlen=6)
    for x in range(-5, 6):                                             # la cabeza, arriba
        for y in range(CY + 6, CY + 15):
            for z in range(-4, 6):
                if (x / 5.0) ** 2 + ((y - CY - 10) / 5.0) ** 2 + ((z - 1) / 4.5) ** 2 > 1.0: continue
                M.put(x, y, z, 'top', lerp(BLACK, BLACK_L, M.noise(x, y, z, 3.0)))
    for s in (-1, 1):                                                  # las orejas puntiagudas
        for j in range(5): M.put(s * (3 + j // 2), CY + 14 + j, 0, 'top', BLACK_L)
    _eye(M, 'top', 0, CY + 10, 6, 2.2)
    for s, part in ((-1, 'pod_l'), (1, 'pod_r')):
        _wing(M, part, s, 20, (s * 5, CY + 4, 0), 10, 9 + s)
    piv = {'body': [0, 0, 0], 'top': [0, CY + 6, 0], 'pod_l': [-5, CY + 4, 0], 'pod_r': [5, CY + 4, 0]}
    n = M.export('models/sombra_alada.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.85, specular=0.25)
    print('sombra_alada', n, 'voxels')


def morador_tinieblas():
    """A escala 1, unos 2,2 m de envergadura (el nivel lo agranda)."""
    M = Model(S=2, seed=2383)
    CY = 30
    _smoke_body(M, CY, 11, 14, 9, 7, tatters=12, tlen=22)
    for x in range(-10, 11):                                           # la cabeza: más humo, ancha y baja
        for y in range(CY + 10, CY + 26):
            for z in range(-8, 10):
                q = (x / 10.0) ** 2 + ((y - CY - 17) / 8.0) ** 2 + ((z - 1) / 8.5) ** 2
                if q > 0.8 + 0.3 * M.noise(x, y, z, 4.0): continue
                M.put(x, y, z, 'top', lerp(BLACK, BLACK_L, 0.7 * M.noise(x, y, z, 3.0)))
    for s in (-1, 1):                                                  # cuernos de humo
        for j in range(10): M.put(s * (6 + j // 2), CY + 24 + j, -1 - j // 4, 'top', SMOKE if j > 6 else BLACK_L)
    _eye(M, 'top', 0, CY + 17, 10, 2.9, lobes=3)
    # zarcillos de humo que salen del cuerpo hacia delante y abajo (parte body)
    for i in range(6):
        a = (i / 6.0 - 0.5) * 2.2
        for j in range(16):
            x = int(math.sin(a) * (8 + j * 0.8)); z = int(math.cos(a) * (6 + j * 0.6))
            y = CY - 6 - j + int(math.sin(j * 0.5 + i) * 2)
            M.put(x, y, z, 'body', SMOKE if j > 10 else BLACK_L)
    for s, part in ((-1, 'pod_l'), (1, 'pod_r')):
        _wing(M, part, s, 38, (s * 9, CY + 8, -2), 18, 19 + s)
    piv = {'body': [0, 0, 0], 'top': [0, CY + 10, 0], 'pod_l': [-9, CY + 8, -2], 'pod_r': [9, CY + 8, -2]}
    n = M.export('models/morador_tinieblas.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.85, specular=0.25)
    print('morador_tinieblas', n, 'voxels')


MODELS = {'sectario_estrellado': sectario_estrellado, 'sombra_alada': sombra_alada, 'morador_tinieblas': morador_tinieblas}
if __name__ == '__main__':
    for name in (sys.argv[1:] or MODELS):
        MODELS[name]()
