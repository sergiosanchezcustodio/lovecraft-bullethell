"""Iconos de las revelaciones (hito 21.7): un medallón de piedra con un ojo abierto en el centro, a
bloques y alineado con la rejilla (la cara mira a +Z). Uno por revelación de data/revelations.json,
con el iris de su color: models/revelacion_<id>.json. tools/render_revelaciones.gd los pasa a
resources/revelations/<id>.png, que es lo que usa la partida (como los iconos de los Signos).

Uso: python tools/gen_revelaciones.py            (todas)
     python tools/gen_revelaciones.py lo_oculto  (solo esa)
después: godot --path . -s tools/render_revelaciones.gd
"""
import json
import math
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

RAIZ = os.path.join(os.path.dirname(__file__), "..")
R_OUT = 22             # radio del medallón (voxels)
R_IN = 16              # donde empieza el hueco del ojo
STONE = (0.46, 0.43, 0.39)
STONE_HI = (0.58, 0.55, 0.5)
STONE_DARK = (0.22, 0.2, 0.19)
BACK = (0.07, 0.05, 0.1)
SCLERA = (0.88, 0.84, 0.7)
SCLERA_RED = (0.86, 0.6, 0.52)
LID = (0.45, 0.25, 0.23)
LID_DARK = (0.3, 0.15, 0.15)
PUPIL = (0.02, 0.02, 0.03)
EYE_W = 13             # media anchura del ojo
EYE_H = 8              # media altura en el centro
# runas del anillo: 12 marcas cortas (radial o de lado, alternas), hundidas en la piedra
RUNES = 12


def eye_half(x):
    """Media altura de la almendra en la columna x (0 fuera del ojo)."""
    t = abs(x + 0.5) / (EYE_W + 0.5)
    return 0 if t >= 1 else int(round(EYE_H * (1 - t * t) ** 0.75))


def build(rid, iris, seed):
    M = Model(S=2, seed=seed)
    put = lambda x, y, z, c, g=0: M.put(x, y, z, "body", c, g)
    for x in range(-R_OUT, R_OUT):
        for y in range(-R_OUT, R_OUT):
            d = math.hypot(x + 0.5, y + 0.5)
            if d > R_OUT: continue
            put(x, y, 0, STONE_DARK)                                   # trasera
            if d >= R_IN:                                              # el anillo
                top = 4 if (d > R_OUT - 1.5 or d < R_IN + 1.2) else 3  # bordes en relieve
                ang = math.atan2(y + 0.5, x + 0.5) % (2 * math.pi)
                k = ang / (2 * math.pi) * RUNES
                i, f = int(k), k - int(k)
                rmid = (R_IN + R_OUT) / 2
                if i % 2 == 0: rune = abs(f - 0.5) < 0.07 and abs(d - rmid) < 1.9      # raya radial
                else: rune = abs(f - 0.5) < 0.22 and abs(d - rmid) < 0.6               # raya de lado
                n = M.noise(x, y, 0, 0.3)
                for z in range(1, top + 1):
                    c = STONE_HI if (z == top and top == 4) else STONE
                    if z == top and rune: continue                     # la runa, hundida
                    put(x, y, z, tuple(q * (0.86 + 0.24 * n) for q in c))
                if rune: put(x, y, top - 1, STONE_DARK)
            else:                                                      # el fondo, negro violáceo
                put(x, y, 1, BACK)
                if M.hsh(x, y, 7) < 0.018 and (abs(y + 0.5) > eye_half(x) + 2 or abs(x + 0.5) > EYE_W + 1):
                    put(x, y, 2, (0.78, 0.74, 1.0), 1)                 # alguna estrella
    # el ojo
    for x in range(-EYE_W - 1, EYE_W + 1):
        h = eye_half(x)
        if h == 0: continue
        for y in range(-h - 1, h + 1):
            yy = y + 0.5
            if abs(yy) > h - 0.5:                                      # párpados, en relieve
                put(x, y, 2, LID_DARK)
                put(x, y, 3, LID)
                continue
            di = math.hypot(x + 0.5, yy)
            corner = abs(x + 0.5) / EYE_W
            if abs(x + 0.5) < 1.0 and abs(yy) < 5.0: c, g = PUPIL, 0                    # rendija
            elif abs(x + 0.5 + 2) < 1.0 and abs(yy - 2.5) < 1.0: c, g = (1, 1, 1), 1     # brillo
            elif di < 6.2:
                k = di / 6.2
                c = lerp(tuple(min(1.0, q * 1.2 + 0.12) for q in iris), tuple(q * 0.4 for q in iris), k ** 1.6)
                g = 1 if di < 4.6 else 0
            else:
                c, g = lerp(SCLERA, SCLERA_RED, max(0.0, corner - 0.55) / 0.45), 0
            put(x, y, 2, c, g)
    n = M.export(os.path.join(RAIZ, "models", "revelacion_%s.json" % rid), {"body": [0, 0, 0]},
                 pivots_in_voxels=True, roughness=0.85, specular=0.25)
    print("revelacion_%s: %d voxels" % (rid, n))


def main():
    with open(os.path.join(RAIZ, "data", "revelations.json"), encoding="utf-8") as f:
        data = json.load(f)
    only = set(sys.argv[1:])
    for i, rv in enumerate(data["revelaciones"]):
        if only and rv["id"] not in only: continue
        build(rv["id"], tuple(rv.get("color", [0.8, 0.8, 0.8])), 2107 + i)


if __name__ == "__main__":
    main()
