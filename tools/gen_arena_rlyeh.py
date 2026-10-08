"""Arena del nivel 5 de la parte 3: R'lyeh emergida, la puerta colosal (hito 7.5).
Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m de losas de R'lyeh (suelo `rlyeh`: la rejilla gira y se tuerce por zonas). Al norte,
en medio, la puerta colosal entreabierta con su resplandor verde; a los lados y al oeste, muros
ciclópeos inclinados. Monolitos torcidos, escaleras que suben a ninguna parte y bloques
volcados; los Ángulos devoradores se abren en el suelo (peligro del nivel). Al sur y al este,
el mar del que ha emergido la isla. Uso: python tools/gen_arena_rlyeh.py
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
A = Arena("rlyeh", seed=1925, half=HALF, spawn_clear=4.5,
          foot={"rly_puerta": 10.0, "rly_muro": 12.0, "rly_monolito": 1.2, "rly_escalera": 2.2, "rly_bloque": 1.6,
                "arr_coral": 0.5})

A.add("rly_puerta", 0.0, -HALF - 0.5, rot=0)
for x in (-24.0, 24.0, 44.0):
    A.add("rly_muro", x, -HALF - 1.0 - abs(x) * 0.03, rot=A.rng.uniform(-4, 4))
for z in range(-20, 50, 24):
    A.add("rly_muro", -HALF - 1.0, z, rot=90 + A.rng.uniform(-4, 4))
A.scatter("rly_monolito", 9, 7.0, 0.9, 1.3)
A.scatter("rly_escalera", 4, 8.0, 0.9, 1.1)
A.scatter("rly_bloque", 10, 6.0, 0.9, 1.3)
A.scatter("arr_coral", 8, 6.0, 1.0, 1.3)
A.edge(["arr_roca_1", "arr_roca_2"], step=3.2, inset=0.8, smin=0.7, smax=1.0)

COLL = dict(COLLIDERS)
COLL.update({
    "rly_puerta": {"type": "box", "shrink": 0.95},
    "rly_muro": {"type": "box", "shrink": 0.95},
    "rly_monolito": {"type": "box", "shrink": 0.9},
    "rly_escalera": {"type": "box", "shrink": 0.9},
    "rly_bloque": {"type": "box", "shrink": 0.9},
    "arr_coral": {"type": "cylinder", "radius": 0.3},
    "arr_roca_1": {"type": "box", "shrink": 0.8},
    "arr_roca_2": {"type": "box", "shrink": 0.8},
})

A.write({
    "name": "R'lyeh emergida: la puerta colosal",
    "spawn": [0.0, 6.0],
    "ground": {"seed": 35, "tile": 0.5, "margin_back": 16.0, "walk_back": 0.5, "camp_radius": 0.0,
               "kind": "rlyeh", "wet": 0.6,
               "colors": {"base_hi": [0.24, 0.31, 0.28], "base_lo": [0.10, 0.13, 0.12], "joint": [0.03, 0.05, 0.04],
                          "moss": [0.14, 0.26, 0.15], "crack_glow": [0.18, 0.55, 0.32]}},
    "sea": {"sides": ["south", "east"], "level": -1.2, "brash": 0.0,
            "colors": {"deep": [0.02, 0.06, 0.05], "mid": [0.05, 0.11, 0.09], "shallow": [0.08, 0.17, 0.13],
                       "crest": [0.16, 0.28, 0.20], "foam": [0.36, 0.48, 0.38]}},
    # cielo verdoso de después de la tormenta; la puerta y los corales dan luz verde
    "light": {"sun_rot": [-35, 30], "sun_color": [0.62, 0.78, 0.68], "sun_energy": 0.42, "exposure": 1.3,
              "ambient_color": [0.34, 0.46, 0.40], "ambient_energy": 0.58,
              "background": [0.05, 0.09, 0.07], "fog_color": [0.14, 0.22, 0.18], "fog_density": 0.0},
    "lamp": {"color": [0.45, 1.0, 0.6], "energy": 1.4, "range": 7.0, "fog": 0.1},
    "colliders": COLL,
    "no_shadow": ["rly_muro", "rly_puerta"],
})
