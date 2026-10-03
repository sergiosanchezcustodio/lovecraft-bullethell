"""Arena del nivel 4 de la parte 1: la ciudad ciclópea de los Antiguos. Receta del generador
de escenarios (tools/arena_kit.py).

64 x 64 m en una plaza de la ciudad muerta: muros ciclópeos de 10 m al norte y al oeste
(atrezo de gen_atrezo_ciudad.py), bloques caídos al sur y al este, muros rotos que forman
calles, arcos, murales con Antiguos en relieve y una plaza abierta en el centro. Suelo de
losas de piedra con escarcha. Luz de atardecer polar sobre la piedra, sin faroles: solo los
cristales de hielo.
Uso: python tools/gen_arena_ciudad.py
"""
import math
from arena_kit import Arena, COLLIDERS, LAMP

HALF = 32.0
A = Arena("ciudad", seed=1933, half=HALF,
          foot={"atrezo_muro_roto": 3.2, "atrezo_arco": 2.8, "atrezo_mural": 3.6, "atrezo_bloque_ciclopeo": 1.1,
                "atrezo_cristales": 1.2})

# calles: muros rotos en dos anillos alrededor de la plaza, con huecos para pasar
for ring, n in ((11.0, 6), (21.0, 9)):
    for i in range(n):
        a = i / n * math.tau + ring * 0.1
        if A.rng.random() < 0.25: continue
        A.add("atrezo_muro_roto", math.cos(a) * ring, math.sin(a) * ring, rot=-math.degrees(a) + 90, scale=1.6)
for x, z, r in ((-15, -15, 45), (16, 13, -45), (-17, 12, 135)):
    A.add("atrezo_arco", x, z, rot=r, scale=1.5)
for x, z, r in ((0, -26, 0), (-26, 2, 90), (25, -8, 90)):
    A.add("atrezo_mural", x, z, rot=r, scale=1.4)
for x, z in ((5, 5), (-6, -4), (8, -10), (-9, 8)):
    A.add("atrezo_cristales", x, z, scale=1.4)

A.edge(["atrezo_bloque_ciclopeo"], step=2.4, inset=1.5, smin=1.6, smax=2.1)
A.scatter("atrezo_bloque_ciclopeo", 10, 7.0, 1.0, 1.6)

COLL = dict(COLLIDERS)
COLL.update({
    "atrezo_muro_roto": {"type": "box", "shrink": 0.95},
    "atrezo_arco": {"type": "box", "shrink": 0.9},
    "atrezo_mural": {"type": "box", "shrink": 0.95},
    "atrezo_bloque_ciclopeo": {"type": "box", "shrink": 0.95},
    "atrezo_cristales": {"type": "cylinder", "radius": 0.8},
})

A.write({
    "name": "La ciudad ciclópea de los Antiguos",
    "ground": {"seed": 8, "tile": 0.5, "margin_back": 12.0, "margin_front": 16.0, "camp_radius": 0.0,
               "colors": {"snow_lo": [0.42, 0.43, 0.46], "snow_hi": [0.80, 0.83, 0.88], "ice": [0.62, 0.70, 0.80],
                          "ice_vein": [0.85, 0.88, 0.92], "trampled": [0.48, 0.48, 0.50]}},
    "barrier": {"models": ["muro_ciclopeo_1", "muro_ciclopeo_2", "muro_ciclopeo_3"], "sides": ["north", "west"],
                "line": HALF + 4.5, "spacing": 7.0, "from": -HALF - 12.0, "to": HALF + 16.0, "y": -0.5, "plateau": 9.5},
    "light": {"sun_rot": [-22, 60], "sun_color": [1.0, 0.82, 0.66], "sun_energy": 0.5, "exposure": 1.2,
              "ambient_color": [0.46, 0.48, 0.62], "ambient_energy": 0.32,
              "background": [0.18, 0.18, 0.26], "fog_color": [0.30, 0.30, 0.40], "fog_density": 0.0},
    "lamp": LAMP,
    "colliders": COLL,
})
