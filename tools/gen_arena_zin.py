"""Arena del nivel 4.4, el mundo de abajo: la ciudad de los gugs y las bóvedas de Zin (parte 4, hito 21.9).
Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m bajo tierra, sin cielo (suelo `mud` casi negro, con salitre). Al norte y al oeste (arriba en
pantalla), las murallas ciclópeas de la ciudad de los gugs, y en la esquina la torre de Koth, redonda y
escalonada, con su puerta de arco (por sus peldaños de un metro se sube al bosque encantado). Al oeste, el
cementerio de Zin: lápidas monolíticas toscas e inclinadas, en hileras torcidas (de ahí salen los ghasts).
En medio, al este, la boca de la cripta por la que suben los necrófagos de Pickman, con huesos alrededor. La
única luz, la de los corros de hongos violáceos y la del farol de quien juega. Al sur y al este, sillares
caídos, bajos, que no tapan. Se empieza al sur.
Uso: python tools/gen_arena_zin.py  (y después tools/render_mapa.gd -- p4_n4)
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
CRYPT = (13.0, -4.0)
KOTH = (-HALF - 3.5, -HALF - 3.5)
A = Arena("zin", seed=1929, half=HALF, spawn_clear=4.0,
          foot={"sue_torre_koth": 6.0, "sue_lapida_1": 1.2, "sue_lapida_2": 1.0, "sue_huesos": 1.2, "sue_cripta": 2.0, "sue_hongos_zin": 0.8,
                "sue_bloque_1": 1.4, "sue_bloque_2": 1.0})

A.add("sue_torre_koth", KOTH[0], KOTH[1], rot=45)                            # la puerta, hacia la arena
A.add("sue_cripta", CRYPT[0], CRYPT[1], rot=0)
for a in (20, 110, 200, 290):
    r = math.radians(a + A.rng.uniform(-20, 20))
    A.add("sue_huesos", CRYPT[0] + math.cos(r) * 3.6, CRYPT[1] + math.sin(r) * 3.6, rot=A.rng.uniform(0, 360),
          scale=A.rng.uniform(0.5, 0.7))

# el cementerio de Zin, al oeste: hileras torcidas de lápidas que miran al este
for row, x in enumerate((-25.0, -19.5, -14.0)):
    z = -22.0 + row * 1.5
    while z < 24.0:
        if A.rng.random() < 0.8:
            m = "sue_lapida_1" if A.rng.random() < 0.45 else "sue_lapida_2"
            A.add(m, x + A.rng.uniform(-0.8, 0.8), z, rot=90 + A.rng.uniform(-14, 14), scale=A.rng.uniform(0.85, 1.15))
        z += A.rng.uniform(3.6, 5.2)
# más lápidas sueltas y huesos por el resto
for x, z in ((-4.0, -20.0), (6.0, -24.0), (22.0, -20.0), (-6.0, 12.0), (4.0, 22.0), (24.0, 14.0), (26.0, 0.0)):
    A.add("sue_lapida_2" if A.rng.random() < 0.6 else "sue_lapida_1", x, z, rot=A.rng.uniform(0, 360),
          scale=A.rng.uniform(0.8, 1.05))
A.scatter("sue_huesos", 6, 6.0, 0.45, 0.65)
A.scatter("sue_bloque_1", 5, 8.0, 0.8, 1.1)
# corros de hongos: la única luz
for x, z in ((-8.0, -10.0), (2.0, 8.0), (20.0, -14.0), (-20.0, 16.0), (-18.0, -12.0), (10.0, 20.0),
             (24.0, 6.0), (-4.0, 26.0), (0.0, -26.0), (-10.0, 2.0)):
    A.add("sue_hongos_zin", x, z, rot=A.rng.uniform(0, 360), scale=A.rng.uniform(0.9, 1.3))
A.scatter("sue_hongos_zin", 4, 8.0, 0.6, 0.9)

# Cierre al sur y al este: sillares caídos, bajos
A.edge(["sue_bloque_1", "sue_bloque_2"], step=2.4, inset=1.2, smin=0.9, smax=1.2)

COLL = dict(COLLIDERS)
COLL.update({
    "sue_torre_koth": {"type": "cylinder", "radius": 5.6},
    "sue_lapida_1": {"type": "box", "shrink": 0.85}, "sue_lapida_2": {"type": "box", "shrink": 0.85},
    "sue_cripta": {"type": "box", "shrink": 0.95}, "sue_bloque_1": {"type": "box", "shrink": 0.8},
    "sue_bloque_2": {"type": "box", "shrink": 0.8}, "sue_huesos": {"type": "cylinder", "radius": 0.4},
})

A.write({
    "name": "Las bóvedas de Zin",
    "spawn": [0.0, 22.0],
    "crypt": [CRYPT[0], CRYPT[1]],
    "koth": [KOTH[0] + 6.2, KOTH[1] + 6.2],            # delante del peldaño de la puerta
    "walkable": ["sue_hongos_zin"],
    "ground": {"seed": 71, "tile": 0.5, "margin_back": 14.0, "margin_front": 18.0, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.2,
               "colors": {"base_hi": [0.30, 0.29, 0.28], "base_lo": [0.20, 0.19, 0.19],
                          "moss": [0.36, 0.35, 0.32], "puddle": [0.10, 0.10, 0.11]}},
    "barrier": {"models": ["sue_muro_zin_1", "sue_muro_zin_2", "sue_muro_zin_3"], "sides": ["north", "west"],
                "line": HALF + 3.5, "spacing": 7.6, "from": -HALF - 12.0, "to": HALF + 16.0, "y": -0.5, "plateau": 6.5,
                "plateau_color": [0.10, 0.10, 0.10]},
    # bajo tierra: sin luna; una luz cenital débil y fría, como de fosforescencia; la violeta, de los hongos
    "light": {"sun_rot": [-62, 20], "sun_color": [0.56, 0.58, 0.70], "sun_energy": 0.32, "exposure": 1.3,
              "ambient_color": [0.40, 0.38, 0.48], "ambient_energy": 0.42,
              "background": [0.02, 0.02, 0.03], "fog_color": [0.10, 0.09, 0.13], "fog_density": 0.0, "gamma": 2.25},
    "lamp": {"color": [0.72, 0.52, 1.0], "energy": 2.4, "range": 7.5, "fog": 0.2, "fog_tint": True},
    "colliders": COLL,
    "no_shadow": ["sue_hongos_zin"],
})
