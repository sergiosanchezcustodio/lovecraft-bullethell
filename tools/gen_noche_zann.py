"""Criaturas de la noche suelta «La música de Erich Zann» (hito 22.6), en la rue d'Auseil.

  vecino_auseil   un vecino de la rue d'Auseil: los viejos, callados, de la calle. Levita larga y raída
                  de paño oscuro, chaleco, corbatín blanco amarillento, pantalón gris y zapatillas; piel
                  gris, pelo blanco largo y revuelto, barba de días, la mirada vidriosa; encorvado y con
                  una palmatoria encendida en la mano izquierda. Humano a bloques (cuerpo.py)
  jiron_noche     un jirón de la noche que hay al otro lado de la ventana: un trapo de oscuridad que
                  flota, con estrellas lejanas dentro, el borde de un violeta frío y la parte de abajo en
                  tiras que se deshacen (anim_fragmento: body, top, pod_l, pod_r)
  tras_ventana    el jefe: lo que hay tras la ventana. Un remolino plano de negrura con un pozo sin luz
                  en medio y un anillo pálido alrededor, brazos en espiral de estrellas y nebulosa violeta
                  y azul, y dos brazos de viento negro que se estiran; arriba, astillas del marco de la
                  ventana y estrellas sueltas que giran (anim_fragmento)

Escribe models/<nombre>.json. Uso: python tools/gen_noche_zann.py [vecino_auseil|jiron_noche|tras_ventana]
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp
import cuerpo as cu
from cuerpo import slab, T, H

VOID = (0.025, 0.02, 0.04); VOID_L = (0.07, 0.06, 0.10)
VIOLET = (0.30, 0.18, 0.46); VIOLET_D = (0.16, 0.10, 0.26)
BLUE = (0.14, 0.20, 0.42)
STAR = (0.80, 0.82, 0.95); STAR_W = (0.95, 0.90, 0.70); STAR_D = (0.46, 0.50, 0.72)
RING = (0.62, 0.62, 0.80)


# ---------------- el vecino de la rue d'Auseil ----------------

def vecino_auseil():
    MATS = {}
    def mat(col, m):
        MATS[col] = m
        return col
    SKIN = (0.62, 0.58, 0.55); SKIN_SH = (0.50, 0.47, 0.45)                     # gris, de no ver el sol
    COAT = mat((0.17, 0.16, 0.19), 'lana'); COAT_SH = (0.12, 0.11, 0.14)
    VEST = mat((0.30, 0.24, 0.20), 'lana'); CRAV = mat((0.80, 0.76, 0.62), 'lino')
    TRO = mat((0.34, 0.33, 0.33), 'lana'); SLIP = mat((0.30, 0.18, 0.14), 'cuero'); SOLE = (0.10, 0.08, 0.06)
    HAIR = (0.86, 0.85, 0.82); STUB = (0.60, 0.58, 0.56)
    EYE = (0.74, 0.78, 0.82); BUTTON = (0.40, 0.36, 0.30)
    BRASS = (0.66, 0.52, 0.26); WAX = (0.92, 0.88, 0.76); FLAME = (1.0, 0.78, 0.36); FLAME_W = (1.0, 0.95, 0.70)
    M = cu.new(2261)
    cu.shoes(M, SLIP, SOLE)
    cu.legs(M, TRO, bottom=6)
    cu.torso(M, VEST, b=0, bottom=38)
    cu.skirt(M, COAT, 20, top=45, flare=3, depth=13)                              # los faldones de la levita
    for k, v in M.V.items():                                                         # la levita abierta: los lados
        if v[0] == T and abs(k[0]) >= 6 and k[1] >= 38 and v[1] == VEST: v[1] = COAT
    for y in range(40, 58, 4): cu.front(M, -5, y, BUTTON)                            # botones del chaleco
    for y in range(55, 61):                                                          # el corbatín
        for x in range(-3, 3):
            if abs(x + 0.5) < 3.2 - (60 - y) * 0.35: cu.front(M, x, y, CRAV)
    cu.front(M, -1, 54, CRAV); cu.front(M, 0, 54, CRAV); cu.front(M, -1, 53, CRAV)
    cu.neck(M, SKIN)
    cu.arms(M, COAT, SKIN, cuff=COAT_SH, cuff_wide=True)
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, (0.62, 0.60, 0.58), eye=EYE, white=(0.82, 0.84, 0.86), brow_style='caida')
    cu.mouth(M, (0.42, 0.34, 0.34))
    for x in range(-6, 6):                                                           # barba de días
        for y in range(62, 67):
            if M.hsh(x, y, 5) < 0.45: cu.paint_face(M, x, y, STUB)
    cu.hair_back(M, SKIN, HAIR, top=86, bottom=62)
    for x in range(-9, 9):                                                           # mechones de arriba, ralos
        for z in range(-9, 6):
            if M.hsh(x, 81, z) < 0.55:
                top_y = max((k[1] for k in M.V if k[0] == x and k[2] == z and M.V[k][0] == H), default=None)
                if top_y is not None and top_y >= 78: M.put(x, top_y + 1, z, H, HAIR if M.hsh(x, z, 2) > 0.3 else (0.74, 0.73, 0.70))
    for k, v in list(M.V.items()):                                                   # pelo largo y revuelto
        if v[0] == H and v[1] == HAIR and k[1] < 70 and M.hsh(k[0], k[1], k[2]) < 0.4:
            M.put(k[0] + (1 if k[0] > 0 else -1), k[1] - 1, k[2], H, HAIR)
    cu.sideburns(M, HAIR, 66, 75)
    # la palmatoria en la mano izquierda: platillo de latón, la vela y la llama
    hand = [k for k, v in M.V.items() if v[0] == 'fore_l']
    hx = round(sum(k[0] for k in hand) / len(hand))
    hz = max(k[2] for k in hand) + 1
    hy = min(k[1] for k in hand) + 2
    for x in range(-3, 4):
        for z in range(-3, 4):
            if x * x + z * z <= 10: M.put(hx + x, hy, hz + 2 + z, 'fore_l', BRASS)
    for y in range(hy + 1, hy + 8):
        for x in (-1, 0):
            for z in (1, 2): M.put(hx + x, y, hz + z, 'fore_l', WAX)
    M.put(hx, hy + 8, hz + 1, 'fore_l', FLAME, 1); M.put(hx - 1, hy + 8, hz + 2, 'fore_l', FLAME, 1)
    M.put(hx, hy + 9, hz + 1, 'fore_l', FLAME_W, 1); M.put(hx, hy + 10, hz + 1, 'fore_l', FLAME, 1)
    extra = cu.hunch(M, k=0.3, y0=40, head_drop=2)
    cu.finish(M, 'vecino_auseil', dict(MATS), flat=(EYE, BRASS, WAX, FLAME, FLAME_W, BUTTON), extra_pivots=extra,
              roughness=0.9, specular=0.2, skirt=True)


# ---------------- lo que viene de fuera ----------------

def _stars(M, part, pts, rate, seed, dim=False):
    """Estrellas sueltas en los voxels `pts` (glow): unas pocas, de tres brillos."""
    for p in pts:
        h = M.hsh(p[0] + seed, p[1], p[2])
        if h < rate:
            c = STAR_W if h < rate * 0.2 else (STAR if h < rate * 0.6 else STAR_D)
            if dim: c = lerp(c, VIOLET, 0.35)
            M.put(*p, part, c, 1)


def jiron_noche():
    """Un trapo de oscuridad de 1,5 m que flota: ancho arriba, con la caperuza, y en tiras abajo."""
    M = Model(S=2, seed=2262)
    rng = M.rng
    shell = []
    for y in range(4, 46):
        t = (y - 4) / 42.0                                     # 0 abajo, 1 arriba
        w = 7 + 8 * math.sin(min(t * 1.3, 1.0) * math.pi * 0.5)
        d = 3 + 3 * t
        for x in range(int(-w) - 1, int(w) + 2):
            # tiras abajo: huecos verticales que suben desde el borde
            if t < 0.45 and (int((x + 40) / 3.0) % 3 == 0) and t < 0.45 * M.noise(x, 0, 1, 4.0) + 0.1: continue
            for z in range(int(-d) - 1, int(d) + 2):
                q = (x / w) ** 2 + (z / d) ** 2
                if q > 1.0: continue
                wave = math.sin(y * 0.35 + x * 0.25) * 1.2
                zz = int(z + wave)
                part = 'body'
                if t < 0.35 and x < -3: part = 'pod_l'
                elif t < 0.35 and x > 3: part = 'pod_r'
                c = lerp(VOID, VOID_L, M.noise(x, y, z, 5.0))
                if q > 0.72: c = lerp(c, VIOLET_D, 0.6) if M.noise(x, y, 0, 4.0) > 0.4 else lerp(c, VIOLET, 0.55)
                M.put(x, y, zz, part, c)
                if q > 0.6: shell.append((x, y, zz))
    # la caperuza, arriba (parte top): una cúpula hueca y el hueco de la cara, negro del todo
    for x in range(-9, 10):
        for y in range(44, 58):
            for z in range(-7, 9):
                q = (x / 9.0) ** 2 + ((y - 46) / 11.0) ** 2 + ((z - 0.5) / 7.5) ** 2
                if q > 1.0 or q < 0.55: continue
                c = lerp(VOID, VIOLET_D, 0.4 * M.noise(x, y, z, 3.0))
                if z > 4 and abs(x) < 5 and 45 < y < 54: c = (0.0, 0.0, 0.0)      # la cara: no hay nada
                M.put(x, y, z, 'top', c)
    for x, y in ((-2, 50), (1, 50)):                                                  # dos estrellas por ojos
        M.put(x, y, 8, 'top', STAR_W, 1)
    _stars(M, 'body', shell, 0.05, 3)
    piv = {'body': [0, 0, 0], 'top': [0, 44, 0], 'pod_l': [-6, 18, 0], 'pod_r': [6, 18, 0]}
    n = M.export('models/jiron_noche.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.8, specular=0.3)
    print('jiron_noche', n, 'voxels')


def tras_ventana():
    """A escala 1, un remolino de 2 m de ancho (el nivel lo agranda)."""
    M = Model(S=2, seed=2263)
    rng = M.rng
    R = 32
    CY = 34
    surface = []
    # el remolino: un disco casi de pie, de cara a la cámara (normal hacia +z y algo arriba), grueso en
    # el centro y fino al borde
    n = (0.0, 0.42, 0.91)
    e2 = (0.0, 0.91, -0.42)
    for x in range(-R - 2, R + 3):
        for y in range(CY - R - 4, CY + R + 5):
            for z in range(-16, 17):
                py, pz = y - CY, z
                s_ = py * n[1] + pz * n[2]                                   # espesor
                u, v = x, py * e2[1] + pz * e2[2]
                r = math.hypot(u, v)
                if r > R: continue
                th = 2.5 + 6.5 * (1 - r / R) ** 1.4
                if abs(s_) > th: continue
                a = math.atan2(v, u)
                arm = math.sin(2.0 * (a - math.log(max(r, 1.0)) * 1.7))     # dos brazos en espiral
                face = s_ > th - 1.6                                         # la cara de delante
                c = lerp(VOID, VOID_L, 0.5 * M.noise(x, y, z, 6.0))
                g = 0
                if r < 7:                                                    # el pozo: sin luz
                    c = (0.0, 0.0, 0.0)
                elif r < 9.5 and face:                                       # el anillo pálido
                    c, g = RING, 1
                elif arm > 0.5 and face:                                     # nebulosa de los brazos
                    c = lerp(VIOLET, BLUE, 0.5 + 0.5 * math.sin(r * 0.3))
                    if M.noise(x, y, z, 3.0) > 0.6: g = 1
                elif r > R - 2.5:                                            # el borde, violeta oscuro
                    c = lerp(c, VIOLET_D, 0.7)
                M.put(x, y, z, 'body', c, g)
                if face and r >= 9.5: surface.append((x, y, z))
    _stars(M, 'body', surface, 0.035, 7)
    # los dos brazos de viento negro, que se estiran a los lados y se retuercen
    for s, part in ((-1, 'pod_l'), (1, 'pod_r')):
        L = 30
        for j in range(L):
            t = j / L
            cx = s * (R - 4 + j * 1.1)
            cy = CY - 2 + math.sin(t * 5.0 + s) * 5 - t * 8
            cz = math.cos(t * 4.0) * 5 + 4
            rad = 4.5 * (1 - 0.75 * t)
            for x in range(int(cx - rad) - 1, int(cx + rad) + 2):
                for y in range(int(cy - rad) - 1, int(cy + rad) + 2):
                    for z in range(int(cz - rad) - 1, int(cz + rad) + 2):
                        if (x - cx) ** 2 + (y - cy) ** 2 + (z - cz) ** 2 > rad * rad: continue
                        c = lerp(VOID, VIOLET_D, 0.5 * M.noise(x, y, z, 3.0))
                        g = 0
                        if M.hsh(x, y, z) < 0.025: c, g = STAR, 1
                        M.put(x, y, z, part, c, g, False)
    # arriba: astillas del marco de la ventana y estrellas sueltas que giran (parte top)
    WOOD = (0.26, 0.18, 0.11); WOOD_D = (0.16, 0.11, 0.07)
    for i in range(9):
        a = i / 9 * math.tau + rng.uniform(-0.2, 0.2)
        r = rng.uniform(14, 26)
        bx, bz = math.cos(a) * r, math.sin(a) * r
        by = CY + 16 + rng.uniform(-3, 5)
        L = rng.randint(5, 10)
        ux, uy = rng.uniform(-1, 1), rng.uniform(-0.4, 0.4)
        for j in range(L):
            for w in range(2):
                M.put(int(bx + ux * j) + w, int(by + uy * j), int(bz), 'top', WOOD if (j + w) % 3 else WOOD_D)
    for i in range(26):
        a = rng.uniform(0, math.tau)
        r = rng.uniform(10, 34)
        p = (int(math.cos(a) * r), int(CY + 12 + rng.uniform(-4, 10)), int(math.sin(a) * r))
        M.put(*p, 'top', STAR if i % 3 else STAR_W, 1)
        if i % 4 == 0: M.put(p[0] + 1, p[1], p[2], 'top', STAR_D, 1)
    piv = {'body': [0, 0, 0], 'top': [0, CY + 14, 0], 'pod_l': [-(R - 4), CY, 4], 'pod_r': [R - 4, CY, 4]}
    n = M.export('models/tras_ventana.json', piv, jitter=0.0, pivots_in_voxels=True, roughness=0.7, specular=0.35)
    print('tras_ventana', n, 'voxels')


MODELS = {'vecino_auseil': vecino_auseil, 'jiron_noche': jiron_noche, 'tras_ventana': tras_ventana}
if __name__ == '__main__':
    for name in (sys.argv[1:] or MODELS):
        MODELS[name]()
