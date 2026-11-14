"""Arena del nivel 4.3, la meseta de Leng (parte 4, hito 21.9). Receta del generador de escenarios
(tools/arena_kit.py).

64 x 64 m de meseta fría y pedregosa (suelo `mud` gris violáceo, sin hierba: liquen y lajas). Al norte (arriba
en pantalla), delante de los acantilados, el monasterio sin ventanas, con su única puerta encendida: de ahí
sale el sumo sacerdote de la máscara de seda amarilla (jefe intermedio). Lo guardan dos leones alados de
diorita de Sarkomand, a los lados del camino. Al este, el poblado de chozas redondas de piedra de los
hombres de Leng, con sus hogueras. Agujas de roca partidas por todas partes. Acantilados al norte y al oeste
(gen_barrera_roca.py, sin nieve); al sur y al este, rocas bajas, que no tapan. Se empieza al sur.
Uso: python tools/gen_arena_leng.py  (y después tools/render_mapa.gd -- p4_n3)
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
MONASTERY = (0.0, -23.0)
DOOR = (MONASTERY[0], MONASTERY[1] + 4.4)
A = Arena("leng", seed=1928, half=HALF, spawn_clear=4.0,
          foot={"sue_monasterio": 5.4, "sue_choza_1": 1.9, "sue_choza_2": 1.6, "sue_leon": 2.6, "sue_roca_1": 1.3,
                "sue_roca_2": 1.0, "lui_hoguera": 1.0, "sue_pena_1": 1.6, "sue_pena_2": 1.2, "dun_roca": 1.5})

A.add("sue_monasterio", MONASTERY[0], MONASTERY[1], rot=0)
for s in (-1, 1):                                                              # los leones, a los lados del camino
    A.add("sue_leon", MONASTERY[0] + s * 5.5, DOOR[1] + 5.0, rot=-90, scale=0.85)

# el poblado del este: chozas en corro alrededor de dos hogueras
VILLAGE = (17.0, 4.0)
for i in range(7):
    a = i / 7 * math.tau + 0.4
    r = 8.5 + A.rng.uniform(-0.8, 0.8)
    m = "sue_choza_1" if i % 2 == 0 else "sue_choza_2"
    # la puerta mira al centro del corro
    rot = -math.degrees(a) - 90
    A.add(m, VILLAGE[0] + math.cos(a) * r, VILLAGE[1] + math.sin(a) * r, rot=rot, scale=A.rng.uniform(0.95, 1.08))
A.add("lui_hoguera", VILLAGE[0] - 1.8, VILLAGE[1] + 0.8, rot=0, scale=1.1)
A.add("lui_hoguera", VILLAGE[0] + 2.0, VILLAGE[1] - 1.2, rot=0, scale=0.9)
A.add("lui_hoguera", -12.0, 12.0, rot=0, scale=0.9)                           # otra, en el caserío del oeste
for a in (200, 290, 20):
    r = math.radians(a)
    A.add("sue_choza_2", -12.0 + math.cos(r) * 5.5, 12.0 + math.sin(r) * 5.5, rot=-a - 90, scale=A.rng.uniform(0.9, 1.0))
# un grupo de agujas al noroeste, junto al acantilado
for x, z, m in ((-22.0, -22.0, "sue_roca_1"), (-17.5, -25.0, "sue_roca_2"), (-25.0, -17.0, "sue_roca_2")):
    A.add(m, x, z, rot=A.rng.uniform(0, 360), scale=A.rng.uniform(1.0, 1.3))

# agujas de roca y rocas
for x, z in ((-20.0, -12.0), (-14.0, 4.0), (-24.0, 20.0), (-6.0, 18.0), (11.0, -5.0), (24.0, -16.0),
             (-26.0, -24.0), (14.0, 22.0), (-2.0, -4.0), (26.0, 24.0)):
    A.add("sue_roca_1" if A.rng.random() < 0.5 else "sue_roca_2", x, z, rot=A.rng.uniform(0, 360),
          scale=A.rng.uniform(0.85, 1.15))
A.scatter("sue_roca_2", 6, 8.0, 0.7, 1.0)
A.scatter("dun_roca", 10, 6.0, 0.7, 1.1)

# Cierre al sur y al este: rocas bajas pegadas (no tapan)
A.edge(["sue_pena_1", "sue_pena_2"], step=2.4, inset=1.2, smin=1.0, smax=1.3)

COLL = dict(COLLIDERS)
COLL.update({
    "sue_monasterio": {"type": "box", "shrink": 0.95}, "sue_leon": {"type": "box", "shrink": 0.9},
    "sue_choza_1": {"type": "cylinder", "radius": 1.6}, "sue_choza_2": {"type": "cylinder", "radius": 1.35},
    "sue_roca_1": {"type": "cylinder", "radius": 0.9}, "sue_roca_2": {"type": "cylinder", "radius": 0.7},
    "lui_hoguera": {"type": "cylinder", "radius": 0.55},
    "sue_pena_1": {"type": "box", "shrink": 0.8}, "sue_pena_2": {"type": "box", "shrink": 0.8}, "dun_roca": {"type": "box", "shrink": 0.85},
})

A.write({
    "name": "La meseta de Leng",
    "spawn": [0.0, 22.0],
    "monastery_door": [DOOR[0], DOOR[1] + 1.2],
    "village": [VILLAGE[0], VILLAGE[1]],
    "ground": {"seed": 67, "tile": 0.5, "margin_back": 14.0, "margin_front": 18.0, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.0,
               "colors": {"base_hi": [0.36, 0.34, 0.36], "base_lo": [0.24, 0.23, 0.26],
                          "moss": [0.33, 0.33, 0.28], "puddle": [0.17, 0.16, 0.19]}},
    "barrier": {"models": ["sue_barrera_1", "sue_barrera_2", "sue_barrera_3"], "sides": ["north", "west"],
                "line": HALF + 4.5, "spacing": 7.0, "from": -HALF - 12.0, "to": HALF + 16.0, "y": -1.0, "plateau": 7.2,
                "plateau_color": [0.30, 0.29, 0.32]},
    # la meseta: luna violácea y baja, el viento frío; la luz cálida, la de las hogueras; la puerta, amarilla
    "light": {"sun_rot": [-34, 150], "sun_color": [0.70, 0.64, 0.88], "sun_energy": 0.5, "exposure": 1.3,
              "ambient_color": [0.42, 0.38, 0.54], "ambient_energy": 0.45,
              "background": [0.06, 0.05, 0.09], "fog_color": [0.22, 0.20, 0.28], "fog_density": 0.0, "gamma": 1.7},
    "lamp": {"color": [1.0, 0.58, 0.28], "energy": 3.0, "range": 9.5, "fog": 0.25},
    "lamps": {"sue_monasterio": {"color": [1.0, 0.86, 0.36], "energy": 3.4, "range": 10.0, "fog": 0.3, "fog_tint": True}},
    "colliders": COLL,
})
