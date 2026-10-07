"""Arena del nivel 5 de la parte 2: el Arrecife del Diablo y Y'ha-nthlei (hito 6.5).
Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m de arrecife negro (suelo `reef`: roca mojada en escalones, algas, percebes y grietas
con luz verde) con pozas de agua somera que frenan (capa "water", como el pantano) y que
brillan en verde desde abajo. Asoman las ruinas de Y'ha-nthlei: columnas ciclópeas partidas,
arcos caídos y bloques tallados; al norte y al oeste, el muro sumergido de la ciudad; al sur y
al este, el mar abierto. Corales negros con luz verde en lugar de faroles.
Uso: python tools/gen_arena_arrecife.py
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
A = Arena("arrecife", seed=1929, half=HALF, spawn_clear=4.5,
          foot={"arr_muro": 12.0, "arr_arco": 4.5, "arr_columna_1": 1.2, "arr_columna_2": 1.2,
                "arr_bloque": 1.4, "arr_roca_1": 1.5, "arr_roca_2": 1.2, "arr_coral": 0.6})

# el muro de Y'ha-nthlei al norte y al oeste (tramos de 24 m), detrás de la arena
for x in range(-44, 50, 22):
    A.add("arr_muro", x + A.rng.uniform(-1, 1), -HALF - 1.0, rot=0)
for z in range(-24, 50, 22):
    A.add("arr_muro", -HALF - 1.0, z + A.rng.uniform(-1, 1), rot=90)

# avenida de columnas en diagonal (la antigua calle de la ciudad), con huecos
for t in range(-26, 28, 7):
    for s in (-5.5, 5.5):
        if A.rng.random() < 0.25: continue
        x, z = t * 0.707 + s * 0.707, t * 0.707 - s * 0.707
        A.add(A.rng.choice(["arr_columna_1", "arr_columna_2", "arr_columna_2"]), x, z,
              rot=A.rng.uniform(0, 90), scale=A.rng.uniform(0.9, 1.15))
for x, z, r in ((-14.0, 10.0, 30), (12.0, -15.0, -60), (19.0, 14.0, 10)):
    A.add("arr_arco", x, z, rot=r)
A.scatter("arr_bloque", 7, 6.0, 0.8, 1.2)
A.scatter("arr_roca_1", 9, 6.0, 0.8, 1.3)
A.scatter("arr_roca_2", 9, 6.0, 0.8, 1.3)
for x, z in ((-8.0, -6.0), (7.0, 8.0), (-20.0, 20.0), (22.0, -22.0), (-22.0, -18.0), (18.0, 24.0), (2.0, -20.0)):
    A.add("arr_coral", x, z, scale=1.4)
A.scatter("arr_coral", 8, 5.0, 0.9, 1.3)

# la orilla del mar abierto: rocas bajas pegadas
A.edge(["arr_roca_1", "arr_roca_2"], step=3.2, inset=0.8, smin=0.7, smax=1.1)

COLL = dict(COLLIDERS)
COLL.update({
    "arr_muro": {"type": "box", "shrink": 0.95},
    "arr_arco": {"type": "box", "shrink": 0.8},
    "arr_columna_1": {"type": "cylinder", "radius": 0.85},
    "arr_columna_2": {"type": "cylinder", "radius": 0.85},
    "arr_bloque": {"type": "box", "shrink": 0.9},
    "arr_roca_1": {"type": "box", "shrink": 0.8},
    "arr_roca_2": {"type": "box", "shrink": 0.8},
    "arr_coral": {"type": "cylinder", "radius": 0.3},
})

A.write({
    "name": "El Arrecife del Diablo y Y'ha-nthlei",
    "spawn": [0.0, 0.0],
    "ground": {"seed": 30, "tile": 0.5, "margin_back": 16.0, "camp_radius": 0.0,
               "kind": "reef", "wet": 0.75,
               "colors": {"base_hi": [0.27, 0.30, 0.29], "base_lo": [0.12, 0.14, 0.14],
                          "moss": [0.14, 0.24, 0.12], "puddle": [0.05, 0.08, 0.07],
                          "water_shallow": [0.12, 0.20, 0.17], "water_deep": [0.05, 0.10, 0.09],
                          "duckweed": [0.12, 0.22, 0.10], "water_glow": [0.03, 0.13, 0.07],
                          "crack_glow": [0.20, 0.75, 0.40]}},
    # pozas: islotes secos más grandes que en el pantano (el arrecife es sobre todo roca)
    "water": {"seed": 9, "islands": 0.62, "scale": 4.0, "clear": [0.0, 0.0, 4.5]},
    "sea": {"sides": ["south", "east"], "level": -0.8, "brash": 0.0,
            "colors": {"deep": [0.02, 0.06, 0.05], "mid": [0.04, 0.11, 0.08], "shallow": [0.07, 0.18, 0.12],
                       "crest": [0.14, 0.26, 0.18], "foam": [0.30, 0.40, 0.32]}},
    # noche cerrada, luna tras las nubes: la luz es la verde que sube del agua
    "light": {"sun_rot": [-40, 20], "sun_color": [0.55, 0.66, 0.70], "sun_energy": 0.32, "exposure": 1.35,
              "ambient_color": [0.30, 0.42, 0.36], "ambient_energy": 0.6,
              "background": [0.04, 0.07, 0.06], "fog_color": [0.12, 0.20, 0.16], "fog_density": 0.0},
    "lamp": {"color": [0.45, 0.95, 0.6], "energy": 0.9, "range": 6.0, "fog": 0.1},
    "colliders": COLL,
    "no_shadow": ["arr_muro"],
})
