"""Arena del nivel 4 de la parte 2: los pantanos y la vía muerta del tren a Rowley (hito 6.4).
Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m de ciénaga. El terraplén de la vía cruza en diagonal (de la esquina noroeste a la
sudeste): una banda seca de balasto (suelo `mud` con `road_kind` 1) con la vía encima. A sus
lados, agua somera (capa "water" del mapa: frena a los jugadores y a los que no nadan) con
islotes de tierra, juncos, tocones y árboles muertos. Al norte y al oeste, el bosque muerto;
al sur y al este, agua abierta. El apeadero de Rowley, dos postes de señales con el farol
encendido, un vagón volcado y el puente de caballetes roto donde la vía se pierde en el agua.
Noche con niebla verdosa. Uso: python tools/gen_arena_pantano.py
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
A = Arena("pantano", seed=1928, half=HALF, spawn_clear=4.0,
          foot={"pan_apeadero": 4.6, "pan_vagoneta": 2.4, "pan_arbol_1": 1.6, "pan_arbol_2": 1.4,
                "pan_caballete": 3.0, "pan_via": 0.1, "inn_juncos": 0.8, "pan_tocon": 0.6})

D = (1 / math.sqrt(2), 1 / math.sqrt(2))      # la vía: dirección (1, 1)
SIDE = (-D[1], D[0])                           # su lado sudoeste
def at(t, s): return t * D[0] + s * SIDE[0], t * D[1] + s * SIDE[1]

# la vía: tramos de 4 m a lo largo del terraplén
for t in range(-48, 34, 4):
    x, z = at(t, 0.0)
    A.add("pan_via", x, z, rot=-45)
x, z = at(36.0, 0.0)
A.add("pan_caballete", x, z, rot=-45, scale=1.2)                  # donde la vía se hunde en el agua

# el apeadero de Rowley, al lado noreste del terraplén, mirando a la vía
x, z = at(-13.0, -6.2)
A.add("pan_apeadero", x, z, rot=-45)
x, z = at(-6.5, -3.6)
A.add("inn_farola", x, z, rot=0, scale=1.2)
for t, s in ((-24.0, 3.4), (12.0, -3.4)):                         # postes de señales
    x, z = at(t, s)
    A.add("pan_senal", x, z, rot=-45 if s > 0 else 135)
x, z = at(9.0, 6.0)
A.add("pan_vagoneta", x, z, rot=-30)                              # el vagón que cayó al pantano
for t, s in ((4.0, -4.6), (-3.0, 4.4)):                           # traviesas sueltas y barriles
    x, z = at(t, s)
    A.add("inn_barril", x, z)

# el bosque muerto al norte y al oeste (y detrás, hasta donde alcanza la cámara)
def wood(n, x0, x1, z0, z1):
    for i in range(n):
        x, z = A.rng.uniform(x0, x1), A.rng.uniform(z0, z1)
        m = A.rng.choice(["pan_arbol_1", "pan_arbol_2", "pan_arbol_1", "inn_juncos", "pan_tocon"])
        A.add(m, x, z, scale=A.rng.uniform(1.0, 1.4) if m != "inn_juncos" else A.rng.uniform(1.2, 1.8))
wood(34, -46, 40, -46, -HALF - 0.5)
wood(30, -46, -HALF - 0.5, -HALF, 40)
for t in range(-30, 34, 3):                                       # el borde: árboles y juncos pegados
    for side in ("north", "west"):
        m = A.rng.choice(["pan_arbol_1", "pan_arbol_2", "inn_juncos", "inn_juncos"])
        j = A.rng.uniform(-0.8, 0.8)
        s = A.rng.uniform(1.0, 1.5)
        if side == "north": A.add(m, t + j, -HALF + 0.5 + j, scale=s)
        else: A.add(m, -HALF + 0.5 + j, t + j, scale=s)

# dentro: árboles sueltos, tocones y juncos (lejos de la vía)
def off_track(x, z): return abs(-x * D[1] + z * D[0]) > 4.5
placed = 0
for model, n, smin, smax in (("pan_arbol_1", 5, 0.9, 1.2), ("pan_arbol_2", 6, 0.9, 1.2),
                             ("pan_tocon", 14, 0.9, 1.4), ("inn_juncos", 34, 1.0, 1.6)):
    k = 0
    while k < n:
        x, z = A.rng.uniform(-HALF + 3, HALF - 2), A.rng.uniform(-HALF + 3, HALF - 2)
        s = A.rng.uniform(smin, smax)
        if not off_track(x, z) or not A.free(x, z, 1.2 * s): continue
        A.add(model, x, z, scale=s)
        k += 1
x, z = at(20.0, 9.0)
A.add("inn_barca", x, z, rot=70)                                  # una barca podrida

# en la orilla del agua abierta, juncos
A.edge(["inn_juncos"], step=2.2, inset=0.6, smin=1.1, smax=1.7)

COLL = dict(COLLIDERS)
COLL.update({
    "pan_apeadero": {"type": "box", "shrink": 0.9},
    "pan_vagoneta": {"type": "box", "shrink": 0.9},
    "pan_senal": {"type": "cylinder", "radius": 0.2},
    "pan_arbol_1": {"type": "cylinder", "radius": 0.35},
    "pan_arbol_2": {"type": "cylinder", "radius": 0.3},
    "pan_tocon": {"type": "cylinder", "radius": 0.3},
    "pan_caballete": {"type": "box", "shrink": 0.8},
    "inn_farola": {"type": "cylinder", "radius": 0.2},
    "inn_barril": {"type": "cylinder", "radius": 0.35},
    "inn_barca": {"type": "box", "shrink": 0.85},
})

A.write({
    "name": "Los pantanos y la vía muerta del tren a Rowley",
    "spawn": [0.0, 0.0],
    "ground": {"seed": 29, "tile": 0.5, "margin_back": 16.0, "walk_back": 0.5, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.6, "road": [0.0, 0.0, 1.0, 1.0, 5.0], "road_kind": 1,
               "colors": {"base_hi": [0.30, 0.29, 0.20], "base_lo": [0.18, 0.18, 0.12],
                          "moss": [0.22, 0.28, 0.14], "puddle": [0.07, 0.09, 0.07]}},
    # agua somera: todo menos el terraplén (3 m a cada lado del eje), la salida e islotes
    "water": {"embank": [0.0, 0.0, 1.0, 1.0, 3.0], "seed": 4, "islands": 0.45, "scale": 5.0,
              "clear": [0.0, 0.0, 4.0]},
    "sea": {"sides": ["south", "east"], "level": -0.35, "brash": 0.0,
            "colors": {"deep": [0.03, 0.05, 0.04], "mid": [0.06, 0.09, 0.07], "shallow": [0.10, 0.13, 0.09],
                       "crest": [0.16, 0.20, 0.14], "foam": [0.32, 0.36, 0.28]}},
    # noche de luna con niebla verdosa
    "light": {"sun_rot": [-34, 25], "sun_color": [0.62, 0.72, 0.78], "sun_energy": 0.42, "exposure": 1.3,
              "ambient_color": [0.38, 0.46, 0.40], "ambient_energy": 0.44,
              "background": [0.08, 0.11, 0.09], "fog_color": [0.20, 0.25, 0.20], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.62, 0.38], "energy": 2.2, "range": 8.0},
    "colliders": COLL,
    "no_shadow": ["pan_via"],
})
