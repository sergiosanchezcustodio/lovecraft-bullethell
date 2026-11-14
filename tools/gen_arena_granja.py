"""Arena de la noche suelta «El color que cayó del cielo» (hito 21.13): la granja de los Gardner, al
oeste de Arkham. Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m de tierra gris (suelo `mud`, casi seca) con el camino de la granja de norte a sur. Al norte
(arriba en pantalla), la casa de los Gardner (`inn_casa`, la de tablas de Nueva Inglaterra) y el
granero, con la cerca del corral; al oeste, el huerto de manzanos muertos. En el centro, un poco al
norte, el pozo: de ahí sube el jefe. Muros de piedra seca cierran el sur y el este, con algún manzano
y algún hueco. Almiares, el abrevadero, barriles y la carretilla. Noche de luna fría.
Uso: python tools/gen_arena_granja.py  (y después tools/render_mapa.gd -- arena=granja)
"""
from arena_kit import Arena, COLLIDERS

HALF = 32.0
WELL = (0.0, -9.0)                         # el pozo (el jefe sale de ahí: LevelData y ColorBehavior)
A = Arena("granja", seed=1882, half=HALF, spawn_clear=4.5,
          foot={"inn_casa": 4.5, "granja_granero": 5.2, "granja_pozo": 1.4, "granja_heno": 1.2,
                "granja_abrevadero": 1.2, "granja_muro": 1.7, "granja_cerca": 1.7, "granja_manzano_1": 1.6,
                "granja_manzano_2": 1.4, "inn_carretilla": 1.2})

# el norte: la casa (fachada al sur), el granero (portón al sur) y, entre los dos, muros y manzanos
A.add("inn_casa", -17.0, -HALF - 3.0, rot=0, scale=1.0)
A.add("granja_granero", 9.0, -HALF - 3.5, rot=0, scale=1.0)
A.add("inn_casa_2", -36.0, -HALF - 2.0, rot=90, scale=0.95)          # la casa vieja, en la esquina
A.add("granja_granero", 30.0, -HALF - 5.5, rot=90, scale=0.85)       # el cobertizo, al nordeste
for x in (-10.0, -7.0, -4.0, -1.0, 16.5, 19.5, 22.5, 25.5):           # muro entre los edificios
    A.add("granja_muro", x, -HALF + 0.8, rot=0)
for x in (-1.5, 18.0):
    A.add("granja_manzano_1", x, -HALF - 1.0, scale=1.1)
# el corral delante del granero: tramos de cerca
for x, z, r in ((2.0, -22.5, 0), (8.0, -22.5, 0), (17.5, -22.5, 0), (20.5, -25.5, 90)):
    A.add("granja_cerca", x, z, rot=r)
A.add("granja_abrevadero", 12.5, -25.0, rot=0)
A.add("granja_heno", 21.0, -18.0, scale=1.1)
A.add("granja_heno", 25.5, -14.5, scale=0.9)
A.add("inn_carretilla", -9.0, -21.5, rot=30)
A.add("granja_farol", -12.5, -26.0, rot=0)                          # faroles: el porche, el granero y el pozo
A.add("granja_farol", 4.0, -27.0, rot=0)
A.add("granja_farol", 2.6, -6.4, rot=0)

# el pozo
A.add("granja_pozo", WELL[0], WELL[1], rot=0)

# el oeste: el huerto, en hileras torcidas, y un muro detrás
for z in range(-29, 32, 3):
    if z == 11: continue                                                 # un tramo caído
    A.add("granja_muro", -HALF - 0.6, z + 1.5, rot=90)
for i, z in enumerate(range(-22, 26, 6)):
    for j, x in enumerate((-27.0, -21.0)):
        if (i + j) % 3 == 2: continue                                    # alguno ya cayó
        A.add("granja_manzano_%d" % (1 + (i + j) % 2), x + A.rng.uniform(-0.8, 0.8), z + A.rng.uniform(-0.8, 0.8),
              scale=A.rng.uniform(0.9, 1.15))

# el sur y el este: muros de piedra seca, con huecos, y algún manzano pegado
for x in range(-32, 31, 3):
    if x in (-4, -1, 17): continue                                       # la salida del camino y una brecha
    A.add("granja_muro", x + 1.5, HALF + 0.6 + A.rng.uniform(-0.15, 0.15), rot=0)
for z in range(-32, 31, 3):
    if z in (4, 7): continue
    A.add("granja_muro", HALF + 0.6 + A.rng.uniform(-0.15, 0.15), z + 1.5, rot=90)
for x, z in ((-12.0, 29.0), (14.0, 29.5), (29.5, 20.0), (29.0, -4.0), (28.5, 30.0)):
    A.add("granja_manzano_%d" % A.rng.randint(1, 2), x, z, scale=A.rng.uniform(0.95, 1.2))

# el campo: almiares, barriles, manzanos sueltos y un tramo de cerca caído
A.add("granja_heno", 14.0, 10.0, scale=1.0)
A.add("granja_heno", -11.0, 14.0, scale=1.15)
for x, z in ((-6.0, -18.5), (-5.0, -19.5), (16.5, -20.0)):
    A.add("inn_barril", x, z)
A.add("granja_cerca", 6.0, 19.0, rot=-20)
A.add("granja_cerca", -18.0, 5.0, rot=75)
A.scatter("granja_manzano_2", 4, 12.0, 0.9, 1.1)
for x, z, r in ((-24.0, 2.5, 20), (-15.0, -12.0, 70), (20.0, 25.0, 140)):   # tocones de los que ya cortaron
    A.add("pan_tocon", x, z, rot=r, scale=0.9)

COLL = dict(COLLIDERS)
COLL.update({
    "inn_casa": {"type": "box", "shrink": 0.95}, "inn_casa_2": {"type": "box", "shrink": 0.95},
    "granja_granero": {"type": "box", "shrink": 0.95},
    "granja_pozo": {"type": "cylinder", "radius": 0.85},
    "granja_manzano_1": {"type": "cylinder", "radius": 0.3}, "granja_manzano_2": {"type": "cylinder", "radius": 0.28},
    "granja_cerca": {"type": "box", "shrink": 0.9},
    "granja_muro": {"type": "box", "shrink": 0.95},
    "granja_heno": {"type": "cylinder", "radius": 0.85},
    "granja_abrevadero": {"type": "box", "shrink": 0.95},
    "inn_barril": {"type": "cylinder", "radius": 0.35},
    "inn_carretilla": {"type": "box", "shrink": 0.85},
    "pan_tocon": {"type": "cylinder", "radius": 0.4},
    "granja_farol": {"type": "cylinder", "radius": 0.15},
})

A.write({
    "name": "La granja de los Gardner",
    "well": list(WELL),
    "ground": {"seed": 33, "tile": 0.5, "margin_back": 14.0, "margin_front": 18.0, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.12, "road": [-1.5, 0.0, 0.12, 1.0, 3.2],
               "colors": {"base_hi": [0.38, 0.37, 0.33], "base_lo": [0.23, 0.225, 0.2],
                          "moss": [0.3, 0.3, 0.27], "puddle": [0.1, 0.1, 0.11]}},
    # noche de luna fría, sin nubes; el color pone lo demás
    "light": {"sun_rot": [-36, 35], "sun_color": [0.66, 0.72, 0.86], "sun_energy": 0.44, "exposure": 1.25,
              "ambient_color": [0.42, 0.44, 0.52], "ambient_energy": 0.46,
              "background": [0.08, 0.09, 0.12], "fog_color": [0.24, 0.24, 0.3], "fog_density": 0.0, "gamma": 1.45},
    "lamp": {"color": [1.0, 0.74, 0.44], "energy": 2.2, "range": 8.0},
    "colliders": COLL,
})
