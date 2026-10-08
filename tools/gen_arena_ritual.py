"""Arena del nivel 2 de la parte 3: los pantanos de Luisiana, el ritual del culto (hito 7.2).
Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m de pantano de noche. En medio, un claro seco con el monolito y el ídolo encima, el
corro de antorchas y cuatro hogueras; alrededor, ciénaga de agua somera que frena (capa
"water", como en el 6.4) con islotes. Cipreses con musgo español por todas partes y un bosque
cerrado de ellos al norte y al oeste; una choza sobre pilotes y una piragua; al sur y al este,
el agua abierta del bayou. Uso: python tools/gen_arena_ritual.py
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
A = Arena("ritual", seed=1908, half=HALF, spawn_clear=4.0,
          foot={"lui_cipres": 1.6, "lui_choza": 4.0, "lui_monolito": 1.2, "lui_hoguera": 1.0, "lui_poste": 0.4,
                "lui_piragua": 1.6, "inn_juncos": 0.8, "pan_tocon": 0.6})
CX, CZ = 0.0, -4.0                                         # el monolito, en medio del claro

A.add("lui_monolito", CX, CZ, rot=45, scale=1.2)
A.add("cth_idolo", CX, CZ, rot=45, scale=1.1, y=84 / 32 * 1.2)   # el ídolo encima del monolito
for k in range(4):
    a = math.pi / 4 + k * math.pi / 2
    A.add("lui_hoguera", CX + math.cos(a) * 9.5, CZ + math.sin(a) * 9.5, rot=0, scale=1.2)
for k in range(8):
    a = k * math.pi / 4
    A.add("lui_poste", CX + math.cos(a) * 6.5, CZ + math.sin(a) * 6.5, rot=math.degrees(-a) + 90, scale=1.1)

A.add("lui_choza", -20.0, 10.0, rot=70)
A.add("lui_piragua", 20.0, 20.0, rot=30)
A.add("lui_piragua", 24.0, -6.0, rot=100)

# bosque cerrado al norte y al oeste (y detrás, hasta donde alcanza la cámara)
for x in range(-46, 40, 4):
    for row in range(3):
        A.add("lui_cipres", x + A.rng.uniform(-1.5, 1.5), -HALF - 1 - row * 4 + A.rng.uniform(-1, 1), scale=A.rng.uniform(0.9, 1.3))
for z in range(-40, 40, 4):
    for row in range(3):
        A.add("lui_cipres", -HALF - 1 - row * 4 + A.rng.uniform(-1, 1), z + A.rng.uniform(-1.5, 1.5), scale=A.rng.uniform(0.9, 1.3))

# cipreses sueltos en la ciénaga, tocones y juncos (fuera del claro)
def clear(x, z): return math.hypot(x - CX, z - CZ) > 13.0
for model, n, smin, smax in (("lui_cipres", 16, 0.9, 1.3), ("pan_tocon", 12, 0.9, 1.4), ("inn_juncos", 30, 1.0, 1.6)):
    k = 0
    while k < n:
        x, z = A.rng.uniform(-HALF + 3, HALF - 2), A.rng.uniform(-HALF + 3, HALF - 2)
        s = A.rng.uniform(smin, smax)
        if not clear(x, z) or not A.free(x, z, 1.2 * s): continue
        A.add(model, x, z, scale=s)
        k += 1
A.edge(["inn_juncos"], step=2.0, inset=0.6, smin=1.1, smax=1.7)

COLL = dict(COLLIDERS)
COLL.update({
    "lui_cipres": {"type": "cylinder", "radius": 0.45},
    "lui_choza": {"type": "box", "shrink": 0.9},
    "lui_monolito": {"type": "box", "shrink": 0.95},
    "lui_hoguera": {"type": "cylinder", "radius": 0.5},
    "lui_poste": {"type": "cylinder", "radius": 0.15},
    "lui_piragua": {"type": "box", "shrink": 0.8},
    "cth_idolo": {"type": "box", "shrink": 0.9},
})

A.write({
    "name": "Los pantanos de Luisiana: el ritual del culto",
    "spawn": [0.0, 8.0],
    "ground": {"seed": 32, "tile": 0.5, "margin_back": 16.0, "walk_back": 0.5, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.7,
               "colors": {"base_hi": [0.28, 0.25, 0.18], "base_lo": [0.15, 0.13, 0.10],
                          "moss": [0.20, 0.26, 0.14], "puddle": [0.06, 0.08, 0.07],
                          "water_shallow": [0.22, 0.28, 0.24], "water_deep": [0.10, 0.14, 0.12],
                          "duckweed": [0.26, 0.34, 0.14]}},
    "water": {"seed": 12, "islands": 0.42, "scale": 4.5, "clear": [CX, CZ, 13.0]},
    "sea": {"sides": ["south", "east"], "level": -0.35, "brash": 0.0,
            "colors": {"deep": [0.03, 0.05, 0.04], "mid": [0.06, 0.08, 0.06], "shallow": [0.10, 0.12, 0.08],
                       "crest": [0.16, 0.18, 0.12], "foam": [0.32, 0.34, 0.26]}},
    # noche sin luna: la luz es la de las hogueras y las antorchas
    "light": {"sun_rot": [-50, 30], "sun_color": [0.45, 0.52, 0.62], "sun_energy": 0.25, "exposure": 1.35,
              "ambient_color": [0.34, 0.40, 0.38], "ambient_energy": 0.58,
              "background": [0.04, 0.05, 0.05], "fog_color": [0.14, 0.16, 0.13], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.58, 0.28], "energy": 2.6, "range": 9.0, "fog": 0.25},
    "colliders": COLL,
    "no_shadow": ["inn_juncos"],
})
