"""Arena del nivel 4.2, el puerto de Dylath-Leen y la galera negra (parte 4, hito 21.9). Receta del generador
de escenarios (tools/arena_kit.py).

64 x 64 m de muelle de basalto mojado (suelo `cobble`, oscuro). Al norte (arriba en pantalla), la galera
negra de los mercaderes de Leng atracada a lo largo del muelle, con su pasarela tendida y sus faroles
verdosos (de ahí bajan los remeros; su escotilla, la bodega). Al oeste, las torres finas y angulosas de
basalto de la ciudad y sus almacenes, con las rendijas encendidas. En medio, el mercado: puestos con toldos
de rayas, sedas y rubíes, ánforas, fardos y cajas. Al sur y al este, el agua del puerto, con pilotes y
barcas. Se empieza al sur.
Uso: python tools/gen_arena_dylath.py  (y después tools/render_mapa.gd -- p4_n2)
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
SEA = -1.2
GALLEY = (-2.0, -HALF - 2.6)
A = Arena("dylath", seed=1927, half=HALF, spawn_clear=4.0,
          foot={"sue_galera": 14.0, "sue_torre_1": 1.8, "sue_torre_2": 1.5, "sue_almacen": 4.0, "sue_puesto": 1.6,
                "sue_anforas": 1.2, "alr_fardos": 1.6, "alr_bolardo": 0.4, "alr_rollo": 0.5, "alr_linterna": 0.3,
                "inn_barril": 0.4, "inn_cajas": 0.8})

A.add("sue_galera", GALLEY[0], GALLEY[1], rot=0, y=SEA - 0.35)               # atracada, la pasarela al muelle
A.add("sue_galera", 34.0, -HALF - 9.0, rot=6, y=SEA - 0.35)                  # otra, fondeada detrás

# al oeste: torres y almacenes de basalto, en fila
for z, m in zip(range(-28, 40, 7), ("sue_torre_1", "sue_almacen", "sue_torre_2", "sue_torre_1", "sue_almacen",
                                     "sue_torre_2", "sue_torre_1", "sue_almacen", "sue_torre_2", "sue_torre_1")):
    if m == "sue_almacen": A.add(m, -HALF - 4.0, z, rot=90)
    else: A.add(m, -HALF - 2.0 + A.rng.uniform(-0.6, 0.6), z, rot=A.rng.uniform(0, 45), scale=A.rng.uniform(0.9, 1.1))
A.add("sue_torre_1", -HALF - 9.0, -HALF - 8.0, rot=20, scale=1.2)
A.add("sue_torre_2", -HALF - 11.0, 4.0, rot=10, scale=1.15)

for x in range(-26, 30, 6):                                                    # bolardos en el canto norte
    if abs(x - (GALLEY[0] + 4.2)) < 2.0: continue                                # la pasarela
    A.add("alr_bolardo", x, -HALF + 1.2, rot=A.rng.uniform(0, 360))

# el mercado: puestos en dos hileras, con ánforas y fardos
for x, z, r in ((-14.0, -10.0, 0), (-6.0, -10.0, 0), (4.0, -11.0, 0), (12.0, -9.0, 0),
                (-12.0, 6.0, 180), (-2.0, 7.0, 180), (8.0, 5.0, 180)):
    A.add("sue_puesto", x, z, rot=r + A.rng.uniform(-6, 6))
for x, z in ((-18.0, -6.0), (16.0, -4.0), (-17.0, 11.0), (14.0, 12.0), (0.0, -18.0)):
    A.add("sue_anforas", x, z)
for x, z, r in ((-12, -20, 0), (14, -20, 90), (-20, 0, 0), (20, 2, 90), (4, 16, 0), (-8, 22, 0), (22, 22, 90)):
    A.add("alr_linterna", x, z, rot=r, scale=1.2)
A.scatter("alr_fardos", 6, 7.0, 0.9, 1.2)
A.scatter("alr_rollo", 6, 5.0, 1.0, 1.3)
A.scatter("inn_cajas", 7, 5.0, 1.0, 1.2)
A.scatter("inn_barril", 8, 5.0, 1.0, 1.2)
A.scatter("sue_anforas", 3, 8.0, 0.9, 1.1)

# pilotes en el agua, al sur y al este
t = -HALF - 12.0
while t < HALF + 12.0:
    for side in ("south", "east"):
        j = A.rng.uniform(0.5, 0.8)
        past = t > HALF + 1.0
        if side == "south": A.add("inn_pilote_alto", t, HALF + j, scale=1.0, past_corner=past)
        else: A.add("inn_pilote_alto", HALF + j, t, scale=1.0, past_corner=past)
    t += 3.0
for m, x, z, rot in (("alr_barca", -20.0, HALF + 2.6, 92), ("alr_barca_3", 8.0, HALF + 2.6, 86),
                     ("alr_barca_2", HALF + 2.6, 12.0, 180), ("alr_barca", HALF + 2.6, -16.0, 176)):
    A.add(m, x, z, rot=rot, y=SEA - 0.05)
for x, z, r in ((HALF - 1.4, -2.0, 0), (HALF - 1.4, 18.0, 0), (-6.0, HALF - 1.4, -90), (14.0, HALF - 1.4, -90)):
    A.add("alr_linterna", x, z, rot=r, scale=1.2)

COLL = dict(COLLIDERS)
COLL.update({
    "sue_torre_1": {"type": "cylinder", "radius": 1.2}, "sue_torre_2": {"type": "cylinder", "radius": 1.0},
    "sue_almacen": {"type": "box", "shrink": 0.95}, "sue_puesto": {"type": "box", "shrink": 0.9},
    "sue_anforas": {"type": "cylinder", "radius": 0.9},
    "alr_fardos": {"type": "box", "shrink": 0.9}, "alr_bolardo": {"type": "cylinder", "radius": 0.25},
    "alr_rollo": {"type": "cylinder", "radius": 0.4}, "alr_linterna": {"type": "cylinder", "radius": 0.1},
    "inn_barril": {"type": "cylinder", "radius": 0.35}, "inn_cajas": {"type": "box", "shrink": 0.9},
    "inn_cajas_2": {"type": "box", "shrink": 0.9}, "inn_cajas_3": {"type": "box", "shrink": 0.85},
    "inn_pilote_alto": {"type": "cylinder", "radius": 0.2},
    "alr_barca": {"type": "box", "shrink": 0.85}, "alr_barca_2": {"type": "box", "shrink": 0.85},
    "alr_barca_3": {"type": "box", "shrink": 0.85},
})

A.write({
    "name": "El puerto de Dylath-Leen",
    "spawn": [0.0, 20.0],
    "galley": [GALLEY[0] + 4.2, -HALF + 1.5],                 # el pie de la pasarela: de ahí bajan los remeros
    "hatch": [GALLEY[0] - 40 / 16, GALLEY[1], SEA - 0.35 + 38 / 16],   # la escotilla de la bodega (x, z, y)
    "walkable": ["sue_galera"],
    "ground": {"seed": 61, "tile": 0.5, "margin_back": 14.0, "margin_north": 0.0, "walk_back": 0.0, "camp_radius": 0.0,
               "edge_color": [0.10, 0.10, 0.12],
               "kind": "cobble", "wet": 0.7,
               "colors": {"base_hi": [0.40, 0.39, 0.43], "base_lo": [0.25, 0.24, 0.28], "joint": [0.05, 0.05, 0.06]}},
    "sea": {"sides": ["north", "south", "east"], "level": SEA, "brash": 0.0,
            "colors": {"deep": [0.02, 0.05, 0.08], "mid": [0.05, 0.10, 0.15], "shallow": [0.09, 0.16, 0.22],
                       "crest": [0.16, 0.24, 0.30], "foam": [0.42, 0.48, 0.54]}},
    # noche de sueño en el puerto: luna fría y alta; las rendijas y los faroles, cálidos; la galera, verdosa
    "light": {"gamma": 1.95, "sun_rot": [-36, 38], "sun_color": [0.66, 0.70, 0.88], "sun_energy": 0.45, "exposure": 1.3,
              "ambient_color": [0.40, 0.42, 0.54], "ambient_energy": 0.5,
              "background": [0.05, 0.06, 0.10], "fog_color": [0.18, 0.20, 0.28], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.76, 0.48], "energy": 3.2, "range": 9.5, "fog": 0.3},
    "lamps": {"sue_galera": {"color": [0.55, 1.0, 0.50], "energy": 3.0, "range": 10.0, "fog": 0.25, "fog_tint": True}},
    "colliders": COLL,
    "no_shadow": ["inn_pilote_alto", "alr_barca", "alr_barca_2", "alr_barca_3"],
})
