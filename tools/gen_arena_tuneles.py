"""Arena del nivel 5 de la parte 1: los túneles y el abismo del mar subterráneo. Receta del
generador de escenarios (tools/arena_kit.py).

Una gruta enorme bajo la ciudad: paredes de roca al norte y al oeste, la orilla del mar sin
luz al sur y al este (rocas en la orilla), estalagmitas, columnas de los Antiguos que bajan
desde la ciudad y cristales que brillan. Casi a oscuras. Suelo de roca húmeda.
Uso: python tools/gen_arena_tuneles.py
"""
from arena_kit import Arena, COLLIDERS, LAMP

HALF = 32.0
A = Arena("tuneles", seed=1934, half=HALF, spawn_clear=7.0,
          foot={"atrezo_roca_grande": 2.6, "atrezo_columna_tallada": 1.6, "atrezo_estalagmita": 1.0,
                "atrezo_cristales": 1.2, "atrezo_arco": 2.8})
for x, z in ((-10, -12), (12, -14), (-18, 6), (6, 12), (16, 0), (-4, -22), (22, -20), (-22, -20)):
    A.add("atrezo_cristales", x, z, scale=A.rng.uniform(1.3, 1.8))
for x, z, r in ((-14, -14, 30), (14, 8, -60)):
    A.add("atrezo_arco", x, z, rot=r, scale=1.4)                    # bocas de túnel hacia la ciudad
for x, z in ((-6, 8), (9, -6), (-20, -2), (2, -16)):
    A.add("atrezo_columna_tallada", x, z, scale=1.3)
A.add("atrezo_farol", -2.5, 3.0, rot=40, scale=1.5)                 # el último farol de la expedición
# orilla: rocas a lo largo del agua (sur y este)
A.edge(["atrezo_roca_grande"], step=3.0, inset=-1.5, smin=1.2, smax=1.7, extra=4.0)
A.scatter("atrezo_estalagmita", 22, 8.0, 1.0, 2.0)
A.scatter("atrezo_roca_grande", 6, 12.0, 0.9, 1.4)

COLL = dict(COLLIDERS)
COLL.update({
    "atrezo_roca_grande": {"type": "box", "shrink": 0.8},
    "atrezo_estalagmita": {"type": "cylinder", "radius": 0.5},
    "atrezo_columna_tallada": {"type": "box", "shrink": 0.6},
    "atrezo_cristales": {"type": "cylinder", "radius": 0.8},
    "atrezo_arco": {"type": "box", "shrink": 0.9},
})

A.write({
    "name": "Los túneles y el abismo del mar subterráneo",
    "ground": {"seed": 9, "tile": 0.5, "margin_back": 12.0, "camp_radius": 0.0,
               "colors": {"snow_lo": [0.20, 0.20, 0.22], "snow_hi": [0.36, 0.37, 0.40], "ice": [0.16, 0.26, 0.34],
                          "ice_vein": [0.30, 0.50, 0.60], "trampled": [0.24, 0.24, 0.26]}},
    "sea": {"sides": ["south", "east"], "level": -1.0},
    "barrier": {"models": ["barrera_roca_1", "barrera_roca_2", "barrera_roca_3"], "sides": ["north", "west"],
                "line": HALF + 4.5, "spacing": 7.0, "from": -HALF - 12.0, "to": HALF + 14.0, "y": -1.0, "plateau": 7.2},
    "light": {"sun_rot": [-70, 160], "sun_color": [0.45, 0.60, 0.70], "sun_energy": 0.18, "exposure": 1.3,
              "ambient_color": [0.22, 0.32, 0.40], "ambient_energy": 0.40,
              "background": [0.03, 0.04, 0.06], "fog_color": [0.06, 0.09, 0.12], "fog_density": 0.0},
    "lamp": LAMP,
    "colliders": COLL,
})
