"""Arena del nivel 4 de la parte 3: la tormenta en el Pacífico (hito 7.4).
Receta del generador de escenarios (tools/arena_kit.py).

La cubierta de la goleta Emma en plena tormenta: 56 x 40 m de tablas mojadas (`planks`, muy
mojadas). Al norte, el puente y la superestructura (pieza de borde); al oeste, la proa. Al sur
y al este, la borda baja (del lado de la cámara) y, más allá, el mar embravecido. Por la
cubierta, escotillas, rollos de cabo, bolardos, botes y fardos sueltos; los faroles de cubierta
se balancean. Peligros (en el nivel): olas que barren la cubierta y Ángulos devoradores.
Uso: python tools/gen_arena_tormenta.py
"""
import math
from arena_kit import Arena, COLLIDERS

HX, HZ = 28.0, 20.0
A = Arena("tormenta", seed=1925, half=HX, spawn_clear=4.0,
          foot={"alr_puente": 6.0, "alr_bolardo": 0.4, "alr_rollo": 0.5, "alr_linterna": 0.3, "alr_bote": 1.4,
                "alr_fardos": 1.6, "alr_borda": 2.0})

for x in range(-24, 30, 12):                                 # el puente y la superestructura al norte
    A.add("alr_puente", x, -HZ, rot=0)
for z in range(-18, 22, 4):                                   # borda baja al este (lado de la cámara)
    A.add("alr_borda", HX + 0.3, z, rot=90)
for x in range(-26, 30, 4):                                   # y al sur
    A.add("alr_borda", x, HZ + 0.3, rot=0)
for x, z in ((-16, -8), (0, -6), (16, -8), (-8, 8), (12, 10)):
    A.add("alr_linterna", x, z, rot=A.rng.choice([0, 90, 180, 270]), scale=1.1)
A.add("alr_bote", -18.0, 12.0, rot=10)
A.add("alr_bote", 20.0, -12.0, rot=-10)
for x, z in ((-22, -12), (-4, 14), (22, 4), (8, -14)):
    A.add("alr_bolardo", x, z)
A.scatter("alr_rollo", 6, 5.0, 1.0, 1.3)
A.scatter("alr_fardos", 5, 6.0, 0.9, 1.1)
A.scatter("inn_barril", 6, 5.0, 1.0, 1.2)

COLL = dict(COLLIDERS)
COLL.update({
    "alr_puente": {"type": "box", "shrink": 0.95},
    "alr_borda": {"type": "box", "shrink": 0.95},
    "alr_bolardo": {"type": "cylinder", "radius": 0.25},
    "alr_rollo": {"type": "cylinder", "radius": 0.4},
    "alr_linterna": {"type": "cylinder", "radius": 0.1},
    "alr_bote": {"type": "box", "shrink": 0.85},
    "alr_fardos": {"type": "box", "shrink": 0.9},
    "inn_barril": {"type": "cylinder", "radius": 0.35},
})

A.write({
    "name": "La tormenta en el Pacífico",
    "size": [HX * 2, HZ * 2],
    "spawn": [0.0, 4.0],
    "ground": {"seed": 34, "tile": 0.5, "margin_back": 4.0, "walk_back": 0.0, "camp_radius": 0.0,
               "kind": "planks", "wet": 1.0,
               "colors": {"base_hi": [0.42, 0.37, 0.30], "base_lo": [0.24, 0.20, 0.16], "joint": [0.03, 0.03, 0.03]}},
    "sea": {"sides": ["south", "east"], "level": -2.0, "brash": 0.0,
            "colors": {"deep": [0.03, 0.05, 0.07], "mid": [0.07, 0.11, 0.14], "shallow": [0.14, 0.20, 0.24],
                       "crest": [0.40, 0.48, 0.52], "foam": [0.70, 0.76, 0.78]}},
    "light": {"sun_rot": [-38, 30], "sun_color": [0.62, 0.70, 0.82], "sun_energy": 0.38, "exposure": 1.3,
              "ambient_color": [0.38, 0.44, 0.50], "ambient_energy": 0.52,
              "background": [0.05, 0.07, 0.09], "fog_color": [0.16, 0.20, 0.24], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.76, 0.46], "energy": 2.0, "range": 7.5, "fog": 0.2},
    "colliders": COLL,
})
