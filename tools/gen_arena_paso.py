"""Arena del nivel 3 de la parte 1: el paso de la cordillera y sus cavernas. Receta del
generador de escenarios (tools/arena_kit.py).

64 x 64 m entre paredes de roca: la barrera de roca al norte y al oeste (gen_barrera_roca.py)
y rocas grandes al sur y al este. Suelo de roca con nieve en lo alto de los ventisqueros,
estalagmitas, columnas talladas por los Antiguos (rotas) y grupos de cristales de hielo que
brillan: casi la única luz, junto a dos faroles abandonados. Penumbra azulada de caverna.
Uso: python tools/gen_arena_paso.py
"""
import math
from arena_kit import Arena, COLLIDERS, LAMP

HALF = 32.0
A = Arena("paso", seed=1932, half=HALF,
          foot={"atrezo_roca_grande": 2.6, "atrezo_columna_tallada": 1.6, "atrezo_estalagmita": 1.0,
                "atrezo_cristales": 1.2})

# columnas de los Antiguos: una avenida rota que cruza el paso en diagonal
for i, t in enumerate((-20, -13, -6, 6, 13, 20)):
    if i == 2: continue                                            # una caída del todo
    A.add("atrezo_columna_tallada", t * 0.9 - 4, -t * 0.55 - 3, rot=A.rng.uniform(0, 360), scale=1.2)
# cristales de hielo: la luz azul del paso
for x, z in ((-8, 6), (9, -9), (15, 10), (-16, -5), (2, 15), (-3, -16)):
    A.add("atrezo_cristales", x, z, scale=A.rng.uniform(1.2, 1.7))
# dos faroles que dejó la expedición
A.add("atrezo_farol", -3.0, 4.0, rot=30, scale=1.5)
A.add("atrezo_farol", 6.0, -3.0, rot=200, scale=1.5)
A.add("atrezo_caja_rota", -1.5, 5.5)
A.add("atrezo_trineo", 4.0, -5.0, rot=40)

# Cierre al sur y al este: rocas grandes pegadas (no tapan: son bajas)
A.edge(["atrezo_roca_grande"], step=2.8, inset=1.5, smin=1.6, smax=2.2)

A.scatter("atrezo_roca_grande", 9, 12.0, 0.9, 1.4)
A.scatter("atrezo_estalagmita", 14, 9.0, 0.9, 1.6)
A.scatter("monticulo_3", 5, 12.0, 0.8, 1.2)

COLL = dict(COLLIDERS)
COLL.update({
    "atrezo_roca_grande": {"type": "box", "shrink": 0.8},
    "atrezo_estalagmita": {"type": "cylinder", "radius": 0.5},
    "atrezo_columna_tallada": {"type": "box", "shrink": 0.6},
    "atrezo_cristales": {"type": "cylinder", "radius": 0.8},
    "atrezo_caja_rota": {"type": "box", "shrink": 0.9},
})

A.write({
    "name": "El paso de la cordillera y sus cavernas",
    "ground": {"seed": 7, "tile": 0.5, "margin_back": 12.0, "margin_front": 16.0, "camp_radius": 0.0,
               # roca abajo y nieve solo en lo alto de los ventisqueros; hielo oscuro
               "colors": {"snow_lo": [0.30, 0.29, 0.30], "snow_hi": [0.78, 0.81, 0.86], "ice": [0.28, 0.40, 0.52],
                          "ice_vein": [0.45, 0.60, 0.72], "trampled": [0.34, 0.33, 0.34]}},
    "barrier": {"models": ["barrera_roca_1", "barrera_roca_2", "barrera_roca_3"], "sides": ["north", "west"],
                "line": HALF + 4.5, "spacing": 7.0, "from": -HALF - 12.0, "to": HALF + 16.0, "y": -1.0, "plateau": 7.2},
    # penumbra de caverna: luz fría y débil, ambiente azulado
    "light": {"sun_rot": [-55, 200], "sun_color": [0.62, 0.70, 0.90], "sun_energy": 0.32, "exposure": 1.25,
              "ambient_color": [0.32, 0.40, 0.58], "ambient_energy": 0.30,
              "background": [0.08, 0.10, 0.14], "fog_color": [0.12, 0.16, 0.22], "fog_density": 0.0},
    "lamp": LAMP,
    "colliders": COLL,
})
