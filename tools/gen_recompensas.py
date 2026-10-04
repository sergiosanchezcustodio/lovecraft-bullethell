"""Recompensas de los objetos rompibles (04-10-2026), a 32 voxels/m, pequeñas y reconocibles:
comida (lata de conservas y pan), poción de cordura (frasco violeta que brilla), dinero
(bolsa con monedas), lanzallamas (bidón rojo con la llama pintada) y congelación del tiempo
(reloj de arena azul que brilla). Escribe models/recompensa_<id>.json.
Uso: python tools/gen_recompensas.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model

P = 'body'


def comida():
    M = Model(S=2, seed=81)
    M.sell(-2.0, 2.5, 0, 2.6, 2.5, 2.6, P, (0.70, 0.70, 0.72), p=5)          # lata
    for y in range(2, 7):
        for x in range(-8, 0):
            for z in range(-6, 6):
                if (x, y, z) in M.V and y in (3, 4, 5): M.V[(x, y, z)][1] = (0.80, 0.20, 0.15)   # etiqueta
    M.sell(3.5, 1.8, 0.5, 3.2, 1.8, 2.2, P, (0.78, 0.55, 0.28), p=2.5)       # pan
    for (x, y, z), v in M.V.items():
        if v[1] == (0.78, 0.55, 0.28) and y >= 5: v[1] = (0.62, 0.40, 0.18)
    return M


def pocion():
    M = Model(S=2, seed=82)
    M.ell(0, 3.2, 0, 2.8, 3.0, 2.8, P, (0.55, 0.25, 0.85), glow=1)          # el líquido brilla
    M.capsule((0, 5.5, 0), (0, 8.0, 0), 1.0, 1.0, P, (0.75, 0.85, 0.90))     # cuello de cristal
    M.box(-1, 8, -1, 1, 9, 1, P, (0.45, 0.30, 0.18))                          # tapón
    return M


def dinero():
    M = Model(S=2, seed=83)
    M.ell(0, 3.0, 0, 3.2, 3.0, 3.0, P, (0.55, 0.42, 0.25))                   # bolsa
    M.capsule((0, 5.5, 0), (0, 6.6, 0), 1.2, 1.4, P, (0.45, 0.33, 0.20))
    for x, z in ((3.5, 2.0), (-3.2, 2.5), (2.0, -3.4)):                       # monedas al lado
        M.sell(x, 0.3, z, 1.3, 0.3, 1.3, P, (1.0, 0.80, 0.25), p=2)
    for (x, y, z), v in M.V.items():
        if v[1] == (0.55, 0.42, 0.25) and abs(x) <= 1 and y in (5, 6): v[1] = (1.0, 0.80, 0.25)   # "$"
    return M


def lanzallamas():
    M = Model(S=2, seed=84)
    M.sell(0, 4.0, 0, 2.8, 4.0, 2.8, P, (0.75, 0.12, 0.08), p=4)            # bidón rojo
    M.capsule((1.5, 8.0, 0), (1.5, 9.5, 0), 0.6, 0.6, P, (0.25, 0.25, 0.27))
    for (x, y, z), v in list(M.V.items()):                                   # llama pintada que brilla
        r = math.hypot(x, (y - 8) * 0.8)
        if z >= 4 and r < 4: v[1] = (1.0, 0.75, 0.2) if r < 2 else (1.0, 0.4, 0.1); v[2] = 1
    return M


def reloj():
    M = Model(S=2, seed=85)
    W = (0.45, 0.32, 0.20)
    M.box(-3, 0, -3, 3, 1, 3, P, W)                                           # bases de madera (en ub)
    M.box(-3, 8, -3, 3, 9, 3, P, W)
    for x, z in ((-3, -3), (2.5, -3), (-3, 2.5), (2.5, 2.5)):
        M.box(x, 1, z, x + 0.5, 8, z + 0.5, P, W)
    for y in range(2, 16):                                                    # dos conos de cristal azul (en voxels)
        r = 1 + abs(y - 9) * 0.55
        for x in range(-5, 5):
            for z in range(-5, 5):
                if math.hypot(x + 0.5, z + 0.5) <= r:
                    M.put(x, y, z, P, (0.45, 0.80, 1.0), glow=1 if y < 9 else 0)
    return M


for name, fn in (('comida', comida), ('pocion', pocion), ('dinero', dinero), ('lanzallamas', lanzallamas),
                 ('reloj', reloj)):
    M = fn()
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    n = M.export('models/recompensa_%s.json' % name, {P: [0, 0, 0]}, jitter=0.01, pivots_in_voxels=True,
                 roughness=0.6, specular=0.4)
    print(name, n)


# ---------------- objetos rompibles (se distinguen del atrezo fijo) ----------------
def vasija():
    """Vasija de barro con un signo antiguo que brilla."""
    M = Model(S=2, seed=86)
    M.ell(0, 5.0, 0, 4.2, 5.0, 4.2, P, (0.62, 0.36, 0.20))
    M.capsule((0, 9, 0), (0, 11, 0), 2.0, 2.4, P, (0.55, 0.31, 0.17))
    for (x, y, z), v in M.V.items():
        if y in (6, 7) and v[1] == (0.62, 0.36, 0.20): v[1] = (0.40, 0.22, 0.12)          # banda
        if z >= 6 and 9 <= y <= 15 and abs(x) <= 3 and (abs(x) + abs(y - 12)) in (2, 3):
            v[1] = (0.45, 1.0, 0.75); v[2] = 1                                          # signo que brilla
    return M


def suministros():
    """Cofre pequeño de suministros: madera, bandas de latón y una estrella dorada que brilla."""
    M = Model(S=2, seed=87)
    M.box(-4, 0, -3, 4, 5, 3, P, (0.48, 0.32, 0.18))
    for (x, y, z), v in M.V.items():
        if x in (-6, -5, 4, 5) or y in (4, 5): v[1] = (0.80, 0.62, 0.25)               # latón
    for (x, y, z), v in M.V.items():
        if z == 5 and abs(x + 0.5) + abs(y - 5) <= 2.5: v[1] = (1.0, 0.85, 0.3); v[2] = 1   # marca
    return M


for name, fn in (('rompible_vasija', vasija), ('rompible_suministros', suministros)):
    M = fn()
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    print(name, M.export('models/%s.json' % name, {P: [0, 0, 0]}, jitter=0.01, pivots_in_voxels=True,
                         roughness=0.75, specular=0.3))
