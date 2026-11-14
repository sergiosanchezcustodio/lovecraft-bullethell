"""Arena del nivel 4.1, el bosque encantado y las afueras de Ulthar (parte 4, *La búsqueda onírica de la
desconocida Kadath*, hito 21.9). Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m de suelo de bosque (suelo `mud`, con musgo y hojarasca). Robles enormes y retorcidos con
yesqueros que brillan; corros de setas verde azulado con su luz y setas violetas: es un sueño, con algo más
de color (D-53). En medio, un poco al oeste, el claro de la gran losa con su argolla (debajo está el mundo
de los gugs, nivel 4). Tocones con las madrigueras de los zoogs. Al norte (arriba en pantalla), el camino
sube hasta Ulthar: un muro bajo de piedra y las casas del pueblo, con sus ventanas encendidas, de donde
bajan los gatos. Al oeste, el bosque cerrado; al sur y al este, helechos, tocones y un muro bajo, que no
tapan. Se empieza al sur, en el camino.
Uso: python tools/gen_arena_bosque.py  (y después tools/render_mapa.gd -- p4_n1)
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
SLAB = (-9.0, -2.0)                          # el claro de la gran losa
ULTHAR = -HALF - 3.0                         # la fila de casas, al norte
A = Arena("bosque", seed=1926, half=HALF, spawn_clear=4.0,
          foot={"sue_roble_1": 3.0, "sue_roble_2": 2.7, "sue_roble_3": 2.0, "sue_hongos": 1.0, "sue_hongos_2": 0.6,
                "sue_tocon": 1.3, "sue_helecho": 0.8, "sue_losa": 2.6, "sue_casa_1": 4.5, "sue_casa_2": 3.8,
                "granja_muro": 1.7, "dun_roca": 1.5, "dun_roble": 2.2, "atrezo_farol": 0.5})

# Ulthar, al norte: las casas detrás de un muro bajo con la puerta del camino; faroles a la entrada
for x, m in ((-27.0, "sue_casa_2"), (-15.0, "sue_casa_1"), (-2.0, "sue_casa_2"), (11.0, "sue_casa_1"),
             (24.0, "sue_casa_2"), (36.0, "sue_casa_1")):
    A.add(m, x + A.rng.uniform(-1.0, 1.0), ULTHAR + A.rng.uniform(-1.2, 1.2), rot=A.rng.choice((0, 180)), scale=1.0)
for x, m in ((-21.0, "sue_casa_1"), (-8.0, "sue_casa_1"), (5.0, "sue_casa_2"), (18.0, "sue_casa_2"), (30.0, "sue_casa_1")):
    A.add(m, x + A.rng.uniform(-1.0, 1.0), ULTHAR - 10.0 + A.rng.uniform(-1.2, 1.2), rot=A.rng.choice((0, 180)), scale=1.0)
for x in range(-30, 34, 3):
    if x in (3, 6): continue                                                # la puerta del camino
    A.add("granja_muro", x + 0.5, -HALF + 1.2 + A.rng.uniform(-0.15, 0.15), rot=0)
A.add("atrezo_farol", 2.6, -HALF + 2.4, rot=0)
A.add("atrezo_farol", 8.4, -HALF + 2.4, rot=0)

# el claro de la losa, con setas alrededor
A.add("sue_losa", SLAB[0], SLAB[1], rot=12)
for a, m in ((30, "sue_hongos"), (140, "sue_hongos_2"), (215, "sue_hongos"), (300, "sue_hongos_2")):
    r = 5.2
    A.add(m, SLAB[0] + math.cos(math.radians(a)) * r, SLAB[1] + math.sin(math.radians(a)) * r)

# el bosque cerrado del oeste: robles enormes, apretados
for z in range(-26, 34, 6):
    for j, x in enumerate((-30.0, -24.5)):
        if j == 1 and A.rng.random() < 0.4: continue
        m = "sue_roble_1" if A.rng.random() < 0.5 else "sue_roble_2"
        A.add(m, x + A.rng.uniform(-1.2, 1.2), z + A.rng.uniform(-1.5, 1.5) + j * 3.0, scale=A.rng.uniform(0.9, 1.1))
# el norte, entre el muro y el bosque: algún roble a los lados del camino
for x, z in ((-20.0, -26.0), (17.0, -25.5), (27.0, -22.0)):
    A.add("sue_roble_2", x, z, scale=A.rng.uniform(0.9, 1.05))

# el sur y el este: helechos, tocones y un muro bajo (no tapan)
for x in range(-30, 32, 3):
    if x in (3, 6): continue                                                # el camino que baja
    A.add("granja_muro", x + 1.5, HALF + 0.8 + A.rng.uniform(-0.15, 0.15), rot=0)
    if A.rng.random() < 0.6:
        A.add("sue_helecho" if A.rng.random() < 0.8 else "sue_tocon", x + A.rng.uniform(0.0, 3.0), HALF - 0.9,
              scale=A.rng.uniform(0.8, 1.2))
for z in range(-29, 34, 3):
    A.add("granja_muro", HALF + 0.8 + A.rng.uniform(-0.15, 0.15), z + 1.5, rot=90, scale=1.0)
    if A.rng.random() < 0.5: A.add("sue_helecho", HALF - 0.8, z + A.rng.uniform(0.0, 3.0), scale=A.rng.uniform(0.8, 1.2))

# dentro: robles sueltos, tocones (madrigueras), setas y helechos
for x, z in ((12.0, -8.0), (-16.0, 15.0), (20.0, 12.0), (6.0, 18.0), (-3.0, -16.0), (22.0, -12.0),
             (-6.0, 11.0), (14.0, 3.0), (-17.0, 5.0), (26.0, 26.0), (-8.0, -22.0)):
    A.add("sue_roble_3" if A.rng.random() < 0.6 else "sue_roble_2", x, z, scale=A.rng.uniform(0.85, 1.05))
for x, z in ((4.0, 6.0), (-18.0, -14.0), (16.0, 24.0), (25.0, 2.0), (-12.0, 26.0)):
    A.add("sue_tocon", x, z, scale=A.rng.uniform(0.9, 1.15))
A.scatter("sue_hongos", 5, 9.0, 0.9, 1.2)
A.scatter("sue_hongos_2", 10, 6.0, 0.8, 1.3)
A.scatter("sue_helecho", 44, 6.0, 0.8, 1.4)
A.scatter("dun_roca", 5, 10.0, 0.8, 1.1)

COLL = dict(COLLIDERS)
COLL.update({
    "sue_roble_1": {"type": "cylinder", "radius": 0.7}, "sue_roble_2": {"type": "cylinder", "radius": 0.6},
    "sue_roble_3": {"type": "cylinder", "radius": 0.45},
    "sue_tocon": {"type": "cylinder", "radius": 0.6},
    "sue_casa_1": {"type": "box", "shrink": 0.95}, "sue_casa_2": {"type": "box", "shrink": 0.95},
    "granja_muro": {"type": "box", "shrink": 0.95},
    "dun_roca": {"type": "box", "shrink": 0.85}, "dun_roble": {"type": "cylinder", "radius": 0.45},
    "atrezo_farol": {"type": "cylinder", "radius": 0.25},
})

A.write({
    "name": "El bosque encantado",
    "spawn": [1.5, 22.0],
    "slab": [SLAB[0], SLAB[1]],
    "walkable": ["sue_losa"],
    "ground": {"seed": 53, "tile": 0.5, "margin_back": 14.0, "margin_front": 18.0, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.0, "road": [4.5, -34.0, 0.0, 1.0, 2.0],
               "colors": {"base_hi": [0.30, 0.31, 0.19], "base_lo": [0.18, 0.18, 0.11],
                          "moss": [0.19, 0.33, 0.19], "puddle": [0.13, 0.13, 0.11]}},
    # noche de sueño: la luna verdosa entre las copas; luz cálida en Ulthar y fría de las setas
    "light": {"sun_rot": [-42, 35], "sun_color": [0.62, 0.74, 0.80], "sun_energy": 0.5, "exposure": 1.3,
              "ambient_color": [0.36, 0.46, 0.50], "ambient_energy": 0.45,
              "background": [0.04, 0.07, 0.08], "fog_color": [0.16, 0.24, 0.24], "fog_density": 0.0, "gamma": 1.8},
    "lamp": {"color": [1.0, 0.64, 0.34], "energy": 2.6, "range": 9.0},
    "lamps": {"sue_hongos": {"color": [0.40, 0.95, 0.80], "energy": 1.6, "range": 6.0, "fog": 0.18, "fog_tint": True}},
    "colliders": COLL,
})
