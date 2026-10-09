"""El culto de Cthulhu (fase 7, hito 7.0), estilo 4 (tools/cuerpo.py, 48 voxels/m):
  cultista         túnica casi negra con la capucha puesta, máscara de hueso con tentáculos
                   que le caen sobre el pecho, amuleto del ídolo en piedra verdinegra y una
                   antorcha encendida en la mano derecha (llama `glow`)
  cultista_alert   tripulante del Alert: jersey de marinero, pantalón de lona, gorra de lana,
                   tatuaje y pañuelo con el símbolo del culto, un revólver (hito 7.2)
  sacerdote_culto  el sacerdote del ritual: túnica larga con bordes de hueso, máscara mayor
                   con más tentáculos, el ídolo colgado al cuello y los brazos desnudos y
                   pintados (hito 7.2)
Y el ídolo (atrezo, models/cth_idolo.json, 32/m): figura sentada de cabeza de pulpo, alas
rudimentarias y cuerpo escamoso sobre un pedestal con jeroglíficos.
Paleta del GDD para el culto: negro verdoso, hueso y resplandor de hogueras.
Uso: python tools/gen_culto_cthulhu.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu
from cuerpo import slab, rslab, T, H
from voxlib import Model, lerp

SKIN = (0.74, 0.60, 0.50); SKIN_SH = (0.64, 0.51, 0.42)
BONE = (0.82, 0.78, 0.66); BONE_SH = (0.66, 0.62, 0.52); BONE_D = (0.40, 0.37, 0.30)
IDOL = (0.16, 0.24, 0.20); IDOL_L = (0.26, 0.36, 0.30)            # piedra verdinegra
WOOD = (0.32, 0.22, 0.14); FLAME = (1.0, 0.62, 0.22); FLAME_C = (1.0, 0.88, 0.50)
SOLE = (0.08, 0.07, 0.07)
MATS = {}


def mat(col, m):
    MATS[col] = m
    return col


def mask(M, tentacles=6, big=False):
    """Máscara de hueso sobre la cara: frente lisa, dos agujeros oscuros por ojos y tentáculos
    que bajan de la barbilla sobre el pecho (part head: se mueven con la cabeza)."""
    zf = 8                                                           # delante de la cara (head de 15)
    for x in range(-7, 7):
        for y in range(63, 79):
            c = BONE if (x + y) % 5 else BONE_SH
            if x in (-7, 6) or y in (63, 78): c = BONE_D                          # borde de la máscara
            if y in (73, 74) and x in (-5, -4, 3, 4): c = (0.04, 0.04, 0.04)   # ojos
            if big and y >= 77 and (x % 3 == 0): c = BONE_D                    # frente con surcos
            M.put(x, y, zf, H, c); M.put(x, y, zf + 1, H, c, over=False)
    for i in range(tentacles):                                      # tentáculos de la barbilla
        x0 = -6 + i * (12 / max(tentacles - 1, 1))
        n = 13 + (i % 3) * 3 + (5 if big else 0)
        for k in range(n):
            x = int(round(x0 + math.sin(k * 0.6 + i) * 1.2))
            y = 63 - k
            z = zf + 1 - k // 4
            c = IDOL_L if k % 3 else (0.34, 0.48, 0.38)               # tentáculos verdinegros con ventosas claras
            M.put(x, y, z, H, c); M.put(x, y, z + 1, H, c)
            if k < n - 4: M.put(x + 1, y, z, H, c, over=False); M.put(x + 1, y, z + 1, H, c, over=False)


def hood_up(M, col, sh):
    """Capucha puesta: envuelve la cabeza por arriba, los lados y la nuca, abierta delante."""
    rslab(M, H, col, 64, 84, 0, -1.0, 19, 19, r=5, rt=6, rb=0, over=False)
    for k in [k for k, v in M.V.items() if v[0] == H and v[1] == col and k[2] > 5 and 64 <= k[1] <= 79 and abs(k[0] + 0.5) < 7.5]:
        del M.V[k]                                                   # abierta por delante
    for y in range(64, 79):                                          # borde de la capucha
        for x in (-8, 7):
            M.put(x, y, 7, H, sh)


def amulet(M, y=50, big=False):
    """Amuleto del ídolo: una figurita verdinegra con cabeza de pulpo colgada de un cordón."""
    w = 3 if big else 2
    for x in range(-w, w):
        for yy in range(y, y + (6 if big else 4)): cu.front(M, x, yy, IDOL, dz=1)
    for x in range(-w, w, 2): cu.front(M, x, y, IDOL_L, dz=2)        # tentáculos de la figurita
    for yy in range(y + 4 + (2 if big else 0), 62):
        for x in (-4 + (yy - y) // 3, 3 - (yy - y) // 3): cu.front(M, x, yy, BONE_D)


def torch(M, part='fore_r', ax=cu.ARM_X):
    """Antorcha en la mano derecha: mango de madera y llama que brilla."""
    x = int(ax)
    for y in range(16, 42):
        for dx in (0, 1):
            for z in (5, 6): M.put(x + dx, y, z, part, WOOD)
    for y in range(42, 46):
        for dx in (-1, 0, 1, 2):
            for z in (4, 5, 6, 7): M.put(x + dx, y, z, part, (0.20, 0.16, 0.12))   # trapos
    for y in range(46, 56):
        r = 2.5 - (y - 46) * 0.22
        for dx in range(-3, 4):
            for dz in range(-3, 4):
                if dx * dx + dz * dz > r * r: continue
                c = FLAME_C if dx * dx + dz * dz < 1.5 and y < 52 else FLAME
                M.put(x + dx, y, 5 + dz, part, c, glow=1)


def cultista():
    MATS.clear()
    ROBE = mat((0.10, 0.12, 0.11), 'lana'); ROBE_SH = mat((0.06, 0.08, 0.07), 'lana')
    ROPE = (0.42, 0.36, 0.26)
    M = cu.new(1925)
    for s_, _, shin, _, _ in cu.sides():                             # pies descalzos
        slab(M, shin, SKIN, 0, 3, 5 * s_, 2, 8, 8, 13, 12, ch=1)
    cu.legs(M, ROBE, bottom=3)
    cu.torso(M, ROBE, b=0, bottom=30)
    cu.skirt(M, ROBE, 4, top=40, b=0, flare=4, depth=13)
    for y in range(4, 40, 3):                                       # pliegues
        for x in (-9, -4, 3, 8): cu.front(M, x, y, ROBE_SH)
    cu.belt(M, ROPE, y=43, b=0, h=1)
    cu.neck(M, SKIN)
    cu.arms(M, ROBE, SKIN, cuff=ROBE_SH)
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, (0.2, 0.15, 0.1))
    mask(M)
    hood_up(M, ROBE, ROBE_SH)
    amulet(M)
    torch(M)
    cu.finish(M, 'cultista', dict(MATS), flat=(BONE, BONE_SH, BONE_D, IDOL, IDOL_L, FLAME, FLAME_C, ROPE, (0.04, 0.04, 0.04)))


def cultista_alert():
    MATS.clear()
    JER = mat((0.20, 0.22, 0.30), 'punto'); JER_SH = mat((0.15, 0.17, 0.23), 'punto')
    TRO = mat((0.42, 0.40, 0.32), 'lana'); BOOT = mat((0.14, 0.12, 0.10), 'cuero')
    CAP = mat((0.30, 0.10, 0.10), 'lana'); SCARF = (0.16, 0.26, 0.20); GUN = (0.10, 0.10, 0.11)
    M = cu.new(1926)
    top = cu.boots(M, BOOT, SOLE, top=14)
    cu.legs(M, TRO, bottom=top)
    cu.torso(M, JER, b=1, bottom=36)
    for y in range(37, 61, 3):                                      # rayas del jersey
        for x in range(-11, 11): cu.front(M, x, y, JER_SH)
    for x in range(-5, 5):                                          # pañuelo verdinegro con el símbolo
        for y in range(56, 61): cu.front(M, x, y, SCARF, dz=1)
    cu.front(M, -1, 58, BONE, dz=2); cu.front(M, 0, 58, BONE, dz=2); cu.front(M, -1, 57, BONE, dz=2)
    cu.neck(M, SKIN)
    cu.arms(M, JER, SKIN, b=1)
    for y in range(28, 33):                                         # tatuaje del culto en el antebrazo
        M.put(int(-cu.ARM_X) - 3, y, 3, 'fore_l', IDOL)
    x = int(cu.ARM_X)                                               # revólver en la mano derecha
    for y in range(18, 24):
        for z in range(5, 12 if y > 21 else 7): M.put(x, y, z, 'fore_r', GUN)
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, (0.2, 0.15, 0.1), brow_style='recta')
    cu.mouth(M, (0.55, 0.35, 0.30))
    slab(M, H, CAP, 77, 84, 0, -0.5, 16, 14, 16, 14, ch=2)          # gorra de lana
    for x in range(-8, 8): cu.paint_face(M, x, 77, (0.22, 0.07, 0.07))
    for x in range(-5, 5):                                          # barba de días
        for y in range(62, 66):
            if (x + y) % 2: cu.paint_face(M, x, y, (0.22, 0.17, 0.12), dz=1)
    cu.finish(M, 'cultista_alert', dict(MATS), flat=(SCARF, BONE, IDOL, GUN), b=1, hat=(CAP,))


def sacerdote_culto():
    MATS.clear()
    ROBE = mat((0.08, 0.10, 0.09), 'lana'); ROBE_SH = mat((0.05, 0.06, 0.06), 'lana')
    PAINT = (0.62, 0.60, 0.50)
    M = cu.new(1927)
    for s_, _, shin, _, _ in cu.sides():
        slab(M, shin, SKIN, 0, 3, 5 * s_, 2, 8, 8, 13, 12, ch=1)
    cu.legs(M, ROBE, bottom=3)
    cu.torso(M, ROBE, b=1, bottom=30)
    cu.skirt(M, ROBE, 3, top=40, b=1, flare=5, depth=14)
    for (x, y, z), v in list(M.V.items()):                          # bordes de hueso en el bajo y delante
        if v[0] == T and v[1] == ROBE and (3 <= y <= 5 or (abs(x + 0.5) < 2 and z > 4)): M.V[(x, y, z)] = [T, BONE_SH, 0]
    slab(M, T, ROBE_SH, 30, 62, 0, -2, 27, 24, 12, 13, ch=1, over=False)   # manto por detrás
    cu.neck(M, SKIN)
    cu.arms(M, SKIN, SKIN, b=1)                                     # brazos desnudos
    for (x, y, z), v in list(M.V.items()):                          # pintados con espirales de hueso
        if v[0] in ('arm_l', 'arm_r', 'fore_l', 'fore_r') and v[1] == SKIN and y % 4 == 0:
            M.V[(x, y, z)] = [v[0], PAINT, 0]
    cu.head(M, SKIN, SKIN_SH)
    cu.eyes(M, (0.2, 0.15, 0.1))
    mask(M, tentacles=9, big=True)
    hood_up(M, ROBE, ROBE_SH)
    amulet(M, y=46, big=True)
    cu.finish(M, 'sacerdote_culto', dict(MATS), flat=(BONE, BONE_SH, BONE_D, IDOL, IDOL_L, PAINT, (0.04, 0.04, 0.04)), b=1)


# ---------------- el ídolo (atrezo) ----------------

def idolo():
    """Figura de piedra verdinegra de 1,5 m sobre un pedestal: sentada en cuclillas, cuerpo
    escamoso e hinchado, cabeza de pulpo con una mata de tentáculos que le cae sobre el pecho,
    alas rudimentarias plegadas a la espalda y garras en las rodillas. El pedestal lleva
    jeroglíficos que no son de ningún idioma."""
    M = Model(S=2, seed=1928)
    P = 'body'
    def stone(x, y, z):
        c = lerp(IDOL, (0.10, 0.15, 0.13), M.noise(x, y, z, 5.0))
        if M.noise(x, y, z, 2.0) > 0.78: c = IDOL_L
        return c
    for x in range(-16, 16):                                        # pedestal con jeroglíficos
        for y in range(0, 18):
            for z in range(-14, 14):
                if min(x + 16, 15 - x, z + 14, 13 - z, y, 17 - y) > 1: continue
                c = stone(x, y, z)
                if z == 13 and 4 < y < 14 and (x * 3 + y * 7) % 5 == 0: c = (0.05, 0.08, 0.07)
                M.put(x, y, z, P, c)
    M.sell(0, 30 / 2, 0, 12 / 2, 14 / 2, 11 / 2, P, IDOL, p=2.4)   # cuerpo (en ub: /2 a S=2)
    M.sell(0, 46 / 2, 2 / 2, 10 / 2, 9 / 2, 10 / 2, P, IDOL, p=2.4)  # cabeza
    for s in (-1, 1):                                               # rodillas y garras
        M.sell(s * 8 / 2, 24 / 2, 8 / 2, 5 / 2, 5 / 2, 6 / 2, P, IDOL, p=2.4)
        for k in range(3): M.put(s * 8 + k - 1, 20, 14, P, IDOL_L)
        for i in range(10):                                         # alas rudimentarias
            for j in range(10 - i):
                M.put(s * (8 + i), 40 - j, -9 - i // 2, P, IDOL if (i + j) % 3 else IDOL_L, over=False)
    for i in range(8):                                              # tentáculos de la cara
        x0 = -7 + i * 2
        for k in range(14):
            M.put(x0 + int(math.sin(k * 0.5 + i) * 1.3), 40 - k, 10 + (k // 5), P, IDOL_L if k % 4 == 0 else IDOL)
    for s in (-1, 1): M.put(s * 4, 48, 11, P, (0.30, 0.55, 0.40), glow=1)   # ojos que apenas brillan
    for k, v in list(M.V.items()):
        if v[1] == IDOL: M.V[k] = [P, stone(*k), v[2]]
    return M


cultista()
cultista_alert()
sacerdote_culto()
n = idolo().export('models/cth_idolo_mano.json'   # el del juego es de Replicate, {'body': [0, 0, 0]}, jitter=0.006, pivots_in_voxels=True,
                   roughness=0.5, specular=0.45, no_bottom=True)
print('cth_idolo_mano:', n, 'voxels')
