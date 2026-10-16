"""Escalera de piedra que baja del muelle al agua (16-10-2026, ambiente de los escenarios), a 32/m.

Adosada al muro del muelle (el muro lo pinta town_ground.gdshader, edge_kind 1): seis peldaños
de sillería de 0,22 m que bajan a lo largo del muro, de la cubierta (y = 0) hasta un rellano
junto al agua; macizo de sillares debajo hasta 0,6 m bajo el agua, con juntas, verdín y algas
donde lo moja la ola y algún percebe; barandilla de hierro por fuera con su pasamanos inclinado
y una argolla de amarre con un cabo que cae al agua junto al rellano (la barca va aparte).

Marco del modelo: el muro en z = 0 y el mar hacia +z; baja hacia +x. En la arena se pone en el
borde (z = mitad en el sur con rot 0; x = mitad en el este con rot 90), con y = 0.
Uso: python tools/gen_escalera_muelle.py
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

P = 'body'
VPM = 32
M = Model(S=2, seed=1931)
ST_HI = (0.37, 0.36, 0.34); ST_LO = (0.22, 0.22, 0.21); JOINT = (0.07, 0.07, 0.07)
ALGAE = (0.05, 0.10, 0.06); IRON = (0.10, 0.10, 0.11); IRON_L = (0.20, 0.19, 0.18); RUST = (0.36, 0.20, 0.11)
ROPE = (0.42, 0.36, 0.24); ROPE_D = (0.30, 0.25, 0.16)

W = 29                       # ancho (hacia el mar): 0,9 m
RISE, TREAD, STEPS = 7, 13, 6  # peldaños de 0,22 x 0,4 m
TOP = 0
LAND = 30                    # rellano de 0,94 m
BOTTOM = -58                 # hasta 1,8 m bajo la cubierta
SEA = -38                    # nivel del agua (muelle -1,2 m)
L = TREAD * STEPS + LAND


def top_at(x):
    """Altura (voxels) de la pisa en x."""
    k = min(STEPS, x // TREAD + 1)
    return TOP - RISE * k


def stone(x, y, z):
    row = (TOP - y) // 9
    off = int(M.hsh(row, 1, 1) * 20)
    blk = (x + off) // (16 + int(M.hsh(row, 2, 2) * 10))
    c = lerp(ST_LO, ST_HI, 0.25 + 0.6 * M.hsh(blk, row, 3))
    c = lerp(c, lerp(ST_LO, ST_HI, 0.5), 0.15 * M.noise(x, y, z, 3.0))
    if (TOP - y) % 9 == 0 or (x + off) % (16 + int(M.hsh(row, 2, 2) * 10)) == 0: c = JOINT
    hw = y - SEA
    if hw < 22: c = lerp(c, scale(c, 0.45), 1.0 - max(0.0, hw) / 22)                  # mojada
    if hw < 10: c = lerp(c, ALGAE, 0.8 * (1.0 - max(0.0, hw) / 10))                     # algas
    if 2 < hw < 12 and M.hsh(x, y, z) > 0.965: c = (0.34, 0.33, 0.30)                  # percebes
    return c


def scale(c, k):
    return tuple(q * k for q in c)


for x in range(0, L):
    t = top_at(x)
    for y in range(BOTTOM, t):
        for z in range(0, W):
            c = stone(x, y, z)
            if y == t - 1:                                                             # la pisa, algo más clara y gastada
                c = lerp(c, ST_HI, 0.35) if y - SEA > 6 else c
                if x % TREAD == TREAD - 1 and x < TREAD * STEPS: c = scale(c, 0.6)    # canto del peldaño
            M.put(x, y, z, P, c)
# barandilla de hierro por fuera, con pasamanos inclinado que sigue a los peldaños
RZ = W - 2
for x in range(4, L - 2, 18):
    t = top_at(x)
    for y in range(t, t + 30): M.put(x, y, RZ, P, IRON)
for x in range(4, L - 2):
    t = top_at(x)
    y = int(round(t + 30 - (RISE / TREAD) * 0 if x >= TREAD * STEPS else t + 30))
    ys = TOP + 30 - (RISE / TREAD) * min(x, TREAD * STEPS)
    for dy in (0, 1): M.put(x, int(round(ys)) - dy, RZ, P, IRON_L if dy == 0 else IRON)
    if M.hsh(x, 4, 4) > 0.8: M.put(x, int(round(ys)), RZ, P, RUST)
# argolla de amarre en el lado del rellano y el cabo que cae al agua
ax, ay = TREAD * STEPS + 18, top_at(TREAD * STEPS + 18) + 8
for a in range(0, 360, 20):
    M.put(ax + int(round(4 * math.cos(math.radians(a)))), ay + int(round(4 * math.sin(math.radians(a)))), W, P, IRON)
for k in range(30):                                                                    # cabo: cuelga en curva hasta el agua
    px = ax + 4 + k * 0.9
    py = ay - 4 - 22 * math.sin(math.pi * k / 29) * 0.55 - k * 0.35
    for dz in (0, 1): M.put(int(px), int(py), W + dz, P, ROPE if k % 2 else ROPE_D)
nb = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
for k in [k for k in M.V if all((k[0] + a, k[1] + b, k[2] + c) in M.V for a, b, c in nb)]:
    del M.V[k]

if __name__ == '__main__':
    n = M.export(os.path.join(os.path.dirname(__file__), '..', 'models', 'inn_escalera_muelle.json'), {P: [0, 0, 0]},
                 jitter=0.008, pivots_in_voxels=True, roughness=0.85, specular=0.3, no_bottom=True)
    print('inn_escalera_muelle: %d voxels' % n)
