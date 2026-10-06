"""Arena del nivel 1 de la parte 2: Newburyport y la carretera a Innsmouth (hito 6.1).
Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m de tierra mojada (suelo `mud`) cruzada en diagonal por la carretera de la costa,
con dos rodadas. Al norte y al oeste (arriba en pantalla), las últimas casas de tablas de
Newburyport, cerradas y tapiadas, con vallas entre ellas; al sur y al este, la marisma
(tierra encharcada y juncos). Junto a la carretera, la parada del autobús de Joe Sargent,
postes de telégrafo, farolas de gas, redes tendidas, barcas volcadas y barriles de arenques.
Atardecer nublado. Uso: python tools/gen_arena_carretera.py
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
A = Arena("carretera", seed=1927, half=HALF,
          foot={"inn_casa": 4.5, "inn_autobus": 3.2, "inn_redes": 1.6, "inn_barca": 2.0, "inn_valla": 1.6})

# casas al norte (fachada al sur) y al oeste (fachada al este), con vallas en los huecos
for i, x in enumerate(range(-36, 40, 10)):
    A.add("inn_casa", x + A.rng.uniform(-0.8, 0.8), -HALF - 3.5 + A.rng.uniform(-0.6, 0.6), rot=0, scale=1.0)
    A.add("inn_valla", x + 5.0, -HALF + 0.5, rot=0)
for z in range(-26, 40, 10):
    A.add("inn_casa", -HALF - 3.5 + A.rng.uniform(-0.6, 0.6), z + A.rng.uniform(-0.8, 0.8), rot=90, scale=1.0)
    A.add("inn_valla", -HALF + 0.5, z + 5.0, rot=90)

# la carretera: de la esquina noroeste a la sudeste (dirección (1, 1)); a sus lados, postes y farolas
D = (1 / math.sqrt(2), 1 / math.sqrt(2))
SIDE = (-D[1], D[0])
for t in range(-36, 40, 12):
    A.add("inn_poste", t * D[0] + 3.4 * SIDE[0], t * D[1] + 3.4 * SIDE[1], rot=45)
for t in (-18, 0, 18):
    A.add("inn_farola", t * D[0] - 3.2 * SIDE[0], t * D[1] - 3.2 * SIDE[1], rot=0, scale=1.2)
A.add("inn_autobus", 9.0 * D[0] - 4.8 * SIDE[0], 9.0 * D[1] - 4.8 * SIDE[1], rot=-45)   # la parada de Joe Sargent
A.add("inn_barril", 4.5 * D[0] - 4.0 * SIDE[0], 4.5 * D[1] - 4.0 * SIDE[1])
A.add("inn_barril", 5.5 * D[0] - 4.6 * SIDE[0], 5.5 * D[1] - 4.6 * SIDE[1])

# cosas del pueblo pesquero, hacia la marisma
for x, z, r in ((14.0, -6.0, 20), (-8.0, 15.0, -30), (20.0, 10.0, 70)):
    A.add("inn_redes", x, z, rot=r)
for x, z, r in ((17.0, -12.0, 15), (-13.0, 20.0, 110), (24.0, 2.0, 60)):
    A.add("inn_barca", x, z, rot=r)
for x, z in ((12.0, -9.0), (-10.5, 12.0), (-11.0, -12.0), (6.0, 16.0)):
    A.add("inn_barril", x, z)
for x, z, r in ((-16.0, -6.0, 30), (-4.0, -18.0, 10), (8.0, -20.0, 80)):
    A.add("inn_valla", x, z, rot=r)

# la marisma: juncos densos en el borde sur y este y sueltos hacia dentro
A.edge(["inn_juncos"], step=1.6, inset=1.5, smin=1.0, smax=1.6)
A.scatter("inn_juncos", 26, 18.0, 0.8, 1.4, bias=True)

COLL = dict(COLLIDERS)
COLL.update({
    "inn_casa": {"type": "box", "shrink": 0.95},
    "inn_autobus": {"type": "box", "shrink": 0.9},
    "inn_poste": {"type": "cylinder", "radius": 0.15},
    "inn_farola": {"type": "cylinder", "radius": 0.2},
    "inn_valla": {"type": "box", "shrink": 0.9},
    "inn_barril": {"type": "cylinder", "radius": 0.35},
    "inn_redes": {"type": "box", "shrink": 0.9},
    "inn_barca": {"type": "box", "shrink": 0.85},
})

A.write({
    "name": "Newburyport y la carretera a Innsmouth",
    "ground": {"seed": 27, "tile": 0.5, "margin_back": 14.0, "margin_front": 18.0, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.55, "road": [0.0, 0.0, 1.0, 1.0, 4.2], "marsh": HALF - 3.0,
               "colors": {"base_hi": [0.44, 0.37, 0.27], "base_lo": [0.28, 0.23, 0.17]}},
    # atardecer nublado de Nueva Inglaterra (el de los campos de prueba de suelos)
    "light": {"sun_rot": [-24, 40], "sun_color": [0.95, 0.80, 0.66], "sun_energy": 0.5, "exposure": 1.25,
              "ambient_color": [0.46, 0.52, 0.52], "ambient_energy": 0.46,
              "background": [0.16, 0.19, 0.20], "fog_color": [0.30, 0.34, 0.35], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.78, 0.48], "energy": 2.0, "range": 8.0},
    "colliders": COLL,
})
