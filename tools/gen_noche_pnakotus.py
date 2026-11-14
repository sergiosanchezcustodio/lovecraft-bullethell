"""Criaturas de la noche suelta «La sombra fuera del tiempo» (hito 21.15), en las ruinas de Pnakotus.

  polipo_volador  un pólipo volador, de los que la Gran Raza encerró bajo las torres sin ventanas: una
                  masa a medias material, de carne pálida y lobulada (gris perla con vetas lilas y algún
                  reflejo verdoso), sin cara: en su lugar, bocas redondas y oscuras con el borde vuelto,
                  por las que silba. Arriba, una corona de tubos cortos; abajo cuelgan pólipos como
                  dedos, que acaban en cinco ventosas redondas (las huellas de cinco dedos circulares que
                  encontró Peaslee). Dos tentáculos largos a los lados. En el juego se ve casi
                  transparente (PolypBehavior): solo de cerca, o al recibir un golpe
                  (anim_fragmento: body, top, pod_l, pod_r)
  poseido_yith    el poseído de la Gran Raza: un hombre de la expedición de la Miskatonic de 1935 con la
                  mente de un Yith dentro. Salacot, camisa caqui con dos bolsillos, remangada, pantalón
                  con polainas y botas; mirada vacía con un brillo amarillo pálido. En la mano derecha,
                  el aparato de la Gran Raza: un cono de metal oscuro con anillos que brillan, el que
                  lanzaba los rayos. Humano a bloques (cuerpo.py)
  polipo_antiguo  el jefe: el pólipo que sube por la gran trampilla del archivo. Lo mismo, mucho más
                  grande y más viejo: la carne más gris, con pliegues en anillo, muchas más bocas, una
                  corona alta de tubos y vetas que brillan por dentro (anim_fragmento)

Escribe models/<nombre>.json. Uso: python tools/gen_noche_pnakotus.py [polipo_volador|poseido_yith|polipo_antiguo]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import cuerpo as cu
from cuerpo import slab, T, H


# ---------------- los pólipos ----------------

def _polyp(name, seed, k, pal, mouths, crown, tendrils, folds=False, veins=0.0):
    """Un pólipo de `k` veces el tamaño base (1,6 m de alto a 32/m con k = 1). Voxels en coordenadas
    del modelo, mirando hacia +Z. pal: colores."""
    M = Model(S=2, seed=seed)
    rng = M.rng
    FLESH, FLESH_D, LILAC, GREEN = pal['flesh'], pal['flesh_d'], pal['lilac'], pal['green']
    MOUTH, RIM, TOE, GLOW = pal['mouth'], pal['rim'], pal['toe'], pal['glow']
    CY = 30 * k                                         # el centro de la masa
    shell = []

    def flesh(x, y, z):
        c = lerp(FLESH, FLESH_D, M.noise(x, y, z, 5.0 * k))
        n = M.noise(x * 0.7 + 30, y * 1.6, z * 0.7, 3.5 * k)
        if n > 0.66: c = lerp(c, LILAC, 0.75)                                     # vetas lilas
        elif M.noise(x + 90, y, z, 7.0 * k) > 0.74: c = lerp(c, GREEN, 0.5)       # reflejo verdoso
        if folds and int(y / (5 * k)) % 2 == 0 and M.hsh(x // 2, y, z // 2) < 0.5: c = lerp(c, FLESH_D, 0.5)   # pliegues
        return c

    def blob(part, cx, cy, cz, rx, ry, rz, keep=None):
        ri = int(max(rx, ry, rz)) + 2
        for x in range(int(cx) - ri, int(cx) + ri + 1):
            for y in range(int(cy) - ri, int(cy) + ri + 1):
                for z in range(int(cz) - ri, int(cz) + ri + 1):
                    d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 + ((z - cz) / rz) ** 2
                    if d > 1.0: continue
                    if (x, y, z) in M.V: continue
                    M.put(x, y, z, part, flesh(x, y, z))
                    if keep is not None and d > 0.8: keep.append((x, y, z))

    # la masa: un lóbulo grande y otros alrededor, irregular
    blob('body', 0, CY, 0, 13 * k, 12 * k, 12.5 * k, shell)
    for i in range(6):
        a = i / 6 * math.tau + rng.uniform(-0.3, 0.3)
        r = rng.uniform(7.5, 10.0) * k
        blob('body', math.cos(a) * 9 * k, CY + rng.uniform(-6, 5) * k, math.sin(a) * 9 * k,
             r, r * rng.uniform(0.75, 1.0), r, shell)
    blob('body', 0, CY - 10 * k, 0, 9 * k, 6 * k, 9 * k)                         # el vientre, del que cuelgan
    # vetas que brillan por dentro (el jefe): líneas sueltas en la superficie
    if veins > 0.0:
        for p in shell:
            if M.hsh(p[0] // 3, p[1] // 2, p[2] // 3) < veins and M.noise(p[0], p[1] * 2.0, p[2], 2.5) > 0.6:
                M.put(*p, 'body', GLOW, 1)
    # bocas: agujeros redondos y oscuros con el borde vuelto, por toda la masa (más delante)
    placed = []
    for _ in range(600):
        if len(placed) >= mouths: break
        p = shell[rng.randrange(len(shell))]
        if p[1] < CY - 6 * k: continue
        if p[2] < -4 * k and len(placed) < mouths // 2: continue                  # las primeras, delante
        if any((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2 < (7 * k) ** 2 for q in placed): continue
        placed.append(p)
        n = (p[0], p[1] - CY, p[2])
        L = math.sqrt(sum(c * c for c in n)) or 1.0
        n = tuple(c / L for c in n)
        r = rng.uniform(2.0, 3.0) * k
        ri = int(r) + 2
        for x in range(-ri, ri + 1):
            for y in range(-ri, ri + 1):
                for z in range(-ri, ri + 1):
                    d = math.sqrt(x * x + y * y + z * z)
                    dot = x * n[0] + y * n[1] + z * n[2]
                    q = (p[0] + x, p[1] + y, p[2] + z)
                    if d <= r + 1.2 and -1.0 <= dot <= 1.5 and d > r - 0.4:
                        M.put(*q, 'body', RIM)                                        # el borde vuelto
                    elif d <= r and dot > -2.5:
                        if q in M.V: M.put(*q, 'body', MOUTH)                         # el hueco, oscuro
    # la corona: tubos cortos arriba, por los que también silba
    TOP = CY + 10 * k
    for i in range(crown):
        a = i / crown * math.tau + rng.uniform(-0.2, 0.2)
        rr = rng.uniform(2.0, 6.5) * k
        bx, bz = math.cos(a) * rr, math.sin(a) * rr
        h = rng.uniform(5, 9) * k
        lean = rng.uniform(0.1, 0.35)
        for j in range(int(h) + 1):
            cx, cz = bx + math.cos(a) * j * lean, bz + math.sin(a) * j * lean
            rad = 1.8 * k - j / h * 0.4 * k
            for x in range(int(cx - rad) - 1, int(cx + rad) + 2):
                for z in range(int(cz - rad) - 1, int(cz + rad) + 2):
                    d = math.hypot(x - cx, z - cz)
                    if d > rad: continue
                    end = j >= int(h) - 1
                    c = MOUTH if end and d < rad - 0.9 else (RIM if end else flesh(x, TOP + j, z))
                    M.put(x, TOP + j, z, 'top', c)
    # los dedos que cuelgan, con cinco ventosas redondas al final; los dos de los lados, largos
    BELLY = CY - 14 * k
    def tendril(part, x0, z0, length, sway, r0):
        pts = []
        for j in range(int(length) + 1):
            t = j / max(length, 1)
            pts.append((x0 + math.sin(t * 2.2 + x0) * sway, BELLY - j, z0 + math.cos(t * 1.7 + z0) * sway * 0.6))
        for j, (px, py, pz) in enumerate(pts):
            t = j / max(len(pts) - 1, 1)
            rad = r0 * (1.0 - 0.45 * t)
            for x in range(int(px - rad) - 1, int(px + rad) + 2):
                for z in range(int(pz - rad) - 1, int(pz + rad) + 2):
                    if math.hypot(x - px, z - pz) > rad: continue
                    M.put(x, int(py), z, part, flesh(x, int(py), z), over=False)
        ex, ey, ez = pts[-1]
        for i in range(5):                                                       # las cinco ventosas, pequeñas
            a = i / 5 * math.tau
            M.put(round(ex + math.cos(a) * (r0 + 0.6)), int(ey), round(ez + math.sin(a) * (r0 + 0.6)), part, TOE)
    for i in range(tendrils):                                                    # finos, de largos distintos
        a = (i + 0.5) / tendrils * math.tau + rng.uniform(-0.25, 0.25)
        r = rng.uniform(2.5, 8.5) * k
        tendril('body', math.cos(a) * r, math.sin(a) * r, rng.uniform(3, 9) * k * (1.0 + 0.3 * (i % 3)), 2.2 * k, 0.9 * k)
    for s, part in ((-1, 'pod_l'), (1, 'pod_r')):                                 # los dos largos, a los lados
        px = s * 15 * k
        pts = []
        L = 24 * k
        for j in range(int(L) + 1):
            t = j / L
            pts.append((px + s * t * 6 * k, CY - 2 * k - t * 22 * k + math.sin(t * 4.0) * 2 * k, math.sin(t * 3.0 + s) * 4 * k))
        for j, (qx, qy, qz) in enumerate(pts):
            t = j / L
            rad = (2.8 - 1.5 * t) * k
            for x in range(int(qx - rad) - 1, int(qx + rad) + 2):
                for y in range(int(qy - rad) - 1, int(qy + rad) + 2):
                    for z in range(int(qz - rad) - 1, int(qz + rad) + 2):
                        if (x - qx) ** 2 + (y - qy) ** 2 + (z - qz) ** 2 > rad * rad: continue
                        c = flesh(x, y, z)
                        if t > 0.55 and (x + y + z) % 5 == 0: c = TOE                  # ventosas en la punta
                        M.put(x, y, z, part, c, over=False)
    piv = {'body': [0, 0, 0], 'top': [0, int(TOP), 0], 'pod_l': [int(-14 * k), int(CY), 0], 'pod_r': [int(14 * k), int(CY), 0]}
    n = M.export('models/%s.json' % name, piv, jitter=0.0, pivots_in_voxels=True, roughness=0.55, specular=0.45)
    print(name, n, 'voxels')


POLYP = dict(flesh=(0.74, 0.74, 0.78), flesh_d=(0.56, 0.56, 0.64), lilac=(0.62, 0.54, 0.72), green=(0.56, 0.70, 0.62),
             mouth=(0.07, 0.05, 0.09), rim=(0.40, 0.33, 0.44), toe=(0.86, 0.80, 0.84), glow=(0.68, 0.94, 0.92))
ANCIENT = dict(flesh=(0.60, 0.60, 0.64), flesh_d=(0.40, 0.40, 0.47), lilac=(0.50, 0.40, 0.60), green=(0.44, 0.58, 0.52),
               mouth=(0.05, 0.03, 0.07), rim=(0.32, 0.24, 0.36), toe=(0.80, 0.72, 0.78), glow=(0.62, 0.95, 0.90))


def polipo_volador():
    _polyp('polipo_volador', 2151, 1.0, POLYP, mouths=7, crown=5, tendrils=11)


def polipo_antiguo():
    """A escala 1, 2,1 m (el nivel lo agranda): más bocas, corona alta, pliegues y vetas que brillan."""
    _polyp('polipo_antiguo', 2153, 1.3, ANCIENT, mouths=14, crown=11, tendrils=16, folds=True, veins=0.35)


# ---------------- el poseído de la Gran Raza ----------------

def poseido_yith():
    MATS = {}
    def mat(col, m):
        MATS[col] = m
        return col
    SKIN = (0.80, 0.62, 0.48); SKIN_SH = (0.68, 0.50, 0.38)                      # curtido por el sol
    SHIRT = mat((0.66, 0.58, 0.42), 'lona'); SHIRT_SH = (0.52, 0.45, 0.32)
    TRO = mat((0.50, 0.44, 0.32), 'lona'); PUTTEE = mat((0.40, 0.34, 0.24), 'lona')
    BOOT = mat((0.30, 0.20, 0.12), 'cuero'); SOLE = (0.10, 0.08, 0.06)
    HELMET = mat((0.84, 0.80, 0.68), 'lona'); BAND = (0.36, 0.28, 0.20)
    BELT = (0.28, 0.20, 0.13); BUCKLE = (0.70, 0.60, 0.36)
    EYE = (0.98, 0.92, 0.55); HAIR = (0.34, 0.26, 0.18)
    METAL = (0.20, 0.22, 0.26); METAL_L = (0.36, 0.38, 0.44); RING = (0.62, 0.76, 1.0)
    M = cu.new(2152)
    top = cu.boots(M, BOOT, SOLE, top=8)
    for s_, _, shin, _, _ in cu.sides():                                           # polainas enrolladas
        slab(M, shin, PUTTEE, top, 19, 5 * s_, 0, 8, 8, 8.5, 8.5, ch=1)
    cu.legs(M, TRO, bottom=19)
    for k, v in M.V.items():                                                         # las vueltas de las polainas
        if v[1] == PUTTEE and (k[1] + (k[0] > 0)) % 3 == 0: v[1] = (0.32, 0.27, 0.19)
    cu.torso(M, SHIRT, b=0, bottom=38)
    cu.belt(M, BELT, y=38, h=2, buckle=BUCKLE)
    for s in (-1, 1):                                                                # dos bolsillos con solapa
        for x in range(3, 8):
            for y in range(48, 54):
                cu.front(M, s * x - (1 if s < 0 else 0), y, SHIRT_SH if y >= 52 or x in (3, 7) else SHIRT)
        cu.front(M, s * 5 - (1 if s < 0 else 0), 51, BUCKLE)
    for y in range(40, 61, 4): cu.front(M, -1, y, (0.48, 0.42, 0.30))              # botones
    for y in range(56, 62):                                                          # el cuello abierto
        for x in range(-2, 2):
            if abs(x + 0.5) < (y - 55) * 0.6: cu.front(M, x, y, SKIN)
    cu.neck(M, SKIN)
    cu.arms(M, SHIRT, SKIN, fore=SKIN, cuff=SHIRT_SH, cuff_wide=False)             # remangado
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, (0.30, 0.22, 0.16), eye=EYE, white=(0.90, 0.86, 0.66), brow_style='recta')
    for k, v in M.V.items():                                                         # la mirada vacía, con brillo
        if v[0] == H and v[1] == EYE: v[2] = 1
    cu.mouth(M, (0.42, 0.24, 0.20))
    cu.hair_back(M, SKIN, HAIR, top=76, bottom=66)
    cu.sideburns(M, HAIR, 70, 75)
    # el salacot: casco de ala ancha, abombado, con la banda
    slab(M, H, HELMET, 76, 78, 0, -0.5, 25, 25, 25, 25, ch=3)
    slab(M, H, BAND, 78, 80, 0, -0.5, 17, 17, 17, 17, ch=2)
    slab(M, H, HELMET, 80, 85, 0, -0.5, 17, 11, 17, 11, ch=3)
    M.put(0, 86, 0, H, HELMET); M.put(-1, 86, 0, H, HELMET); M.put(0, 86, -1, H, HELMET); M.put(-1, 86, -1, H, HELMET)
    # el aparato de la Gran Raza en la mano derecha: un cono que apunta hacia delante, con anillos
    hand = [k for k, v in M.V.items() if v[0] == 'fore_r']
    y0 = min(k[1] for k in hand) + 4
    x0 = round(sum(k[0] for k in hand) / len(hand))
    z0 = max(k[2] for k in hand if k[1] <= y0 + 2)
    for j in range(14):                                                              # de la mano hacia delante
        rad = 3.4 - j * 0.2
        for x in range(-4, 5):
            for y in range(-4, 5):
                if x * x + y * y > rad * rad: continue
                c = METAL if (x + y) % 3 else METAL_L
                g = 0
                if j in (3, 7, 11) and x * x + y * y > (rad - 1.2) ** 2: c, g = RING, 1
                M.put(x0 + x, y0 + y, z0 - 2 + j, 'fore_r', c, g)
    M.put(x0, y0, z0 + 12, 'fore_r', RING, 1); M.put(x0 - 1, y0, z0 + 12, 'fore_r', RING, 1)
    cu.finish(M, 'poseido_yith', dict(MATS), flat=(EYE, METAL, METAL_L, RING, BUCKLE, BELT, BAND), hat=(HELMET, BAND),
              roughness=0.9, specular=0.2)


MODELS = {'polipo_volador': polipo_volador, 'poseido_yith': poseido_yith, 'polipo_antiguo': polipo_antiguo}
if __name__ == '__main__':
    for name in (sys.argv[1:] or MODELS):
        MODELS[name]()
