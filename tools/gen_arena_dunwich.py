"""Arena de la noche suelta «El horror de Dunwich» (hito 21.14): Sentinel Hill, sobre Dunwich. Receta del
generador de escenarios (tools/arena_kit.py).

64 x 64 m de hierba oscura y rala (suelo `mud`, con los colores del monte). En la cima, un poco al norte
del centro, el círculo de menhires con la piedra del altar y dos hogueras, donde el viejo Whateley
encendía sus fuegos. Al norte (arriba en pantalla) y al oeste, el bosque oscuro de abetos y robles; en la
esquina noroeste, la granja de los Whateley (`inn_casa_2`) y su cobertizo, y desde ahí baja hacia el
círculo el rastro de lo que salió de la casa: árboles partidos y matas aplastadas. Muros de piedra seca
cierran el sur y el este, con huecos. Peñas, matas y algún roble suelto. Noche de tormenta lejana.
Uso: python tools/gen_arena_dunwich.py  (y después tools/render_mapa.gd -- noche_dunwich)
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
CIRCLE = (0.0, -4.0)                         # el círculo de menhires y el altar
FARM = (-21.0, -HALF - 2.5)                  # la granja de los Whateley: de ahí sale el jefe (LevelData)
A = Arena("dunwich", seed=1928, half=HALF, spawn_clear=4.0,
          foot={"inn_casa_2": 4.5, "granja_granero": 5.0, "dun_abeto_1": 2.0, "dun_abeto_2": 1.7, "dun_roble": 2.2,
                "dun_menhir_1": 0.9, "dun_menhir_2": 1.0, "dun_menhir_3": 0.9, "dun_altar": 1.6, "dun_roca": 1.5,
                "dun_arbol_partido": 2.0, "dun_arbusto": 0.9, "granja_muro": 1.7, "lui_hoguera": 1.0})

# la cima: el círculo, con la entrada al sur más ancha
A.add("dun_altar", CIRCLE[0], CIRCLE[1], rot=8)
N = 11
for i in range(N):
    a = -math.pi / 2 + (i + 0.5) / N * math.tau
    if i == 2: continue                                                  # la entrada del sur (abajo a la derecha)
    x, z = CIRCLE[0] + math.cos(a) * 8.5, CIRCLE[1] + math.sin(a) * 8.5
    A.add("dun_menhir_%d" % (1 + i % 3), x, z, rot=-math.degrees(a) + 90 + A.rng.uniform(-12, 12),
          scale=A.rng.uniform(0.95, 1.15))
A.add("lui_hoguera", CIRCLE[0] - 4.6, CIRCLE[1] + 2.2, rot=0, scale=1.0)
A.add("lui_hoguera", CIRCLE[0] + 4.4, CIRCLE[1] - 2.6, rot=0, scale=0.9)

# la granja de los Whateley y su cobertizo, al noroeste
A.add("inn_casa_2", FARM[0], FARM[1], rot=0, scale=1.0)
A.add("granja_granero", -5.0, -HALF - 4.5, rot=0, scale=0.75)
# el rastro: de la casa hacia el círculo, árboles partidos y matas aplastadas
for k, t in enumerate((0.2, 0.42, 0.66)):
    x = FARM[0] + (CIRCLE[0] - 6.0 - FARM[0]) * t
    z = FARM[1] + 6.0 + (CIRCLE[1] - 6.0 - FARM[1] - 6.0) * t
    side = 3.2 if k % 2 else -3.0
    A.add("dun_arbol_partido", x + side, z, rot=A.rng.uniform(0, 360), scale=A.rng.uniform(0.9, 1.1))

# el bosque: al norte y al oeste, apretado; abetos y algún roble
for x in range(-12, 33, 4):
    for j, z in enumerate((-29.5, -25.5)):
        if -9 < x < 0 and j == 0: continue                               # el cobertizo
        m = "dun_roble" if A.rng.random() < 0.2 else ("dun_abeto_1" if A.rng.random() < 0.6 else "dun_abeto_2")
        A.add(m, x + A.rng.uniform(-1.2, 1.2) + j * 2.0, z + A.rng.uniform(-1.0, 1.0), scale=A.rng.uniform(0.9, 1.15))
for z in range(-20, 33, 4):
    for j, x in enumerate((-29.5, -25.5)):
        if j == 1 and A.rng.random() < 0.45: continue
        m = "dun_roble" if A.rng.random() < 0.2 else ("dun_abeto_1" if A.rng.random() < 0.6 else "dun_abeto_2")
        A.add(m, x + A.rng.uniform(-1.0, 1.0), z + A.rng.uniform(-1.2, 1.2) + j * 2.0, scale=A.rng.uniform(0.9, 1.15))

# el sur y el este: muros de piedra seca, con huecos
for x in range(-23, 31, 3):
    if x in (-2, 1, 13): continue
    A.add("granja_muro", x + 1.5, HALF + 0.6 + A.rng.uniform(-0.15, 0.15), rot=0)
for z in range(-22, 31, 3):
    if z in (5, 8): continue
    A.add("granja_muro", HALF + 0.6 + A.rng.uniform(-0.15, 0.15), z + 1.5, rot=90)

# el monte: peñas, matas y algún árbol suelto (lejos del círculo)
for x, z in ((14.0, 12.0), (-14.0, 16.0), (22.0, -12.0), (-18.0, -6.0), (8.0, 24.0), (25.0, 22.0)):
    A.add("dun_roca", x, z, scale=A.rng.uniform(0.85, 1.2))
A.scatter("dun_arbusto", 12, 13.0, 0.8, 1.2)
A.scatter("dun_roble", 3, 15.0, 0.9, 1.1)
A.scatter("dun_abeto_2", 4, 15.0, 0.85, 1.05)

COLL = dict(COLLIDERS)
COLL.update({
    "inn_casa_2": {"type": "box", "shrink": 0.95}, "granja_granero": {"type": "box", "shrink": 0.95},
    "granja_muro": {"type": "box", "shrink": 0.95},
    "dun_abeto_1": {"type": "cylinder", "radius": 1.1}, "dun_abeto_2": {"type": "cylinder", "radius": 0.95},
    "dun_roble": {"type": "cylinder", "radius": 0.45},
    "dun_menhir_1": {"type": "box", "shrink": 0.9}, "dun_menhir_2": {"type": "box", "shrink": 0.9},
    "dun_menhir_3": {"type": "box", "shrink": 0.9},
    "dun_altar": {"type": "box", "shrink": 0.9},
    "dun_roca": {"type": "box", "shrink": 0.85},
    "dun_arbol_partido": {"type": "box", "shrink": 0.75},
    "dun_arbusto": {"type": "cylinder", "radius": 0.55},
    "lui_hoguera": {"type": "cylinder", "radius": 0.55},
})

A.write({
    "name": "Sentinel Hill",
    "spawn": [0.0, 9.0],
    "farm": [FARM[0], FARM[1] + 5.0],
    "ground": {"seed": 41, "tile": 0.5, "margin_back": 14.0, "margin_front": 18.0, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.0, "road": [-21.0, -28.0, 0.45, 0.89, 2.2],
               "colors": {"base_hi": [0.25, 0.28, 0.18], "base_lo": [0.13, 0.15, 0.10],
                          "moss": [0.19, 0.25, 0.12], "puddle": [0.08, 0.09, 0.08]}},
    # noche de tormenta: la luna entre nubes, fría; la luz cálida, la de las hogueras
    "light": {"sun_rot": [-38, 40], "sun_color": [0.62, 0.68, 0.84], "sun_energy": 0.42, "exposure": 1.25,
              "ambient_color": [0.40, 0.44, 0.50], "ambient_energy": 0.45,
              "background": [0.06, 0.07, 0.09], "fog_color": [0.20, 0.22, 0.26], "fog_density": 0.0, "gamma": 1.65},
    "lamp": {"color": [1.0, 0.62, 0.32], "energy": 2.6, "range": 9.0},
    "colliders": COLL,
})
