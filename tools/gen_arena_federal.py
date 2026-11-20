"""Arena de la noche suelta «El que acecha en la oscuridad» (hito 23.8): Federal Hill, en Providence, una
noche de tormenta de 1935. Receta del generador de escenarios (tools/arena_kit.py).

56 x 56 m de adoquín mojado. Arriba (al norte), la iglesia negra de la Sabiduría Estrellada
(gen_atrezo_federal.py) con su atrio de lápidas y árboles muertos tras una verja; en su campanario, el
Trapezoedro (punto `steeple` en el JSON, de donde baja el jefe). Al oeste y al norte, las casas de tablas
del barrio (las del puerto, prt_casa_*). Al sur y al este, la verja del borde de la colina y, debajo,
el mar de tejados. Por las calles, quince farolas eléctricas: su luz es el escudo (Blackout).
Uso: python tools/gen_arena_federal.py  (y después tools/render_mapa.gd -- noche_acecha)
"""
import json
import os
from arena_kit import Arena, COLLIDERS

HALF = 28.0
CHURCH = (0.0, -31.0)
A = Arena("federal", seed=1935, half=HALF, spawn_clear=4.0,
          foot={"fed_iglesia": 6.0, "prt_casa": 4.0, "prt_casa_2": 4.0, "prt_casa_3": 4.0, "prt_casa_4": 4.0,
                "fed_farola": 0.4, "fed_verja": 2.0, "sue_lapida_1": 0.5, "sue_lapida_2": 0.5,
                "dun_arbol_partido": 1.2, "inn_barril": 0.5, "inn_cajas_2": 0.8, "inn_carretilla": 1.0,
                "prt_banco": 1.2, "inn_escombros": 0.8})

A.add("fed_iglesia", CHURCH[0], CHURCH[1], rot=0, scale=1.0)
# el atrio: la verja delante de la iglesia, con la cancela abierta en medio, y las lápidas
for x in (-12.0, -8.0, 8.0, 12.0):
    A.add("fed_verja", x, -20.5, rot=0)
for z in (-24.5,):
    A.add("fed_verja", -14.2, z, rot=90)
    A.add("fed_verja", 14.2, z, rot=90)
for x, z in ((-10.5, -24.0), (-8.0, -23.0), (-11.5, -22.0), (9.5, -23.6), (11.8, -22.4), (8.2, -22.0), (-6.5, -25.2)):
    A.add("sue_lapida_%d" % (1 + int(abs(x * 7 + z)) % 2), x, z, rot=A.rng.uniform(-20, 20), scale=A.rng.uniform(0.85, 1.05))
A.add("dun_arbol_partido", -12.5, -26.0, rot=40, scale=1.0)
A.add("dun_arbol_partido", 12.0, -26.5, rot=200, scale=0.9)

# el norte: casas a los lados de la iglesia, mirando a la calle
for m, x in (("prt_casa_3", -23.5), ("prt_casa_4", -15.5), ("prt_casa", 15.5), ("prt_casa_2", 23.5)):
    A.add(m, x, -HALF - 3.0, rot=0, scale=1.0)
# el oeste: casas mirando al este
z = -18.0
k = 0
while z < HALF - 2.0:
    A.add(("prt_casa", "prt_casa_3", "prt_casa_4", "prt_casa_2")[k % 4], -HALF - 3.0, z, rot=90, scale=1.0)
    z += 7.2
    k += 1
# el sur y el este: la verja del borde de la colina
for t in range(-26, 30, 4):
    A.add("fed_verja", float(t), HALF + 0.6, rot=0)
    A.add("fed_verja", HALF + 0.6, float(t), rot=90)

# las farolas: el escudo contra lo de la oscuridad, repartidas por las calles
LAMPS = ((-4.0, -18.0), (4.0, -18.0), (-19.0, -12.0), (18.0, -12.0), (-9.0, -6.0), (8.0, -4.0),
         (-21.0, 2.0), (21.0, 3.0), (-2.0, 6.0), (-13.0, 13.0), (12.0, 13.0), (-22.0, 23.0), (0.0, 20.0),
         (22.0, 23.0), (-6.0, -12.5))
for x, z in LAMPS:
    A.add("fed_farola", x, z, rot=0)
# lo que hay por la calle
for x, z in ((-17.0, -3.0), (16.0, 19.0), (24.0, -8.0), (-24.0, 15.0)):
    A.add("inn_barril", x, z)
for x, z in ((-15.0, 20.0), (15.0, -2.0), (-24.0, -6.0)):
    A.add("inn_cajas_2", x, z, rot=A.rng.uniform(0, 360))
A.add("inn_carretilla", 9.0, 9.0, rot=35)
A.add("prt_banco", -5.0, 15.0, rot=0)
A.add("prt_banco", 17.0, 8.0, rot=90)
for x, z in ((4.0, -10.0), (-12.0, 6.0), (18.0, -18.0)):
    A.add("inn_escombros", x, z, scale=0.8)

COLL = dict(COLLIDERS)
COLL.update({
    "fed_iglesia": {"type": "box", "shrink": 0.95},
    "prt_casa": {"type": "box", "shrink": 0.92}, "prt_casa_2": {"type": "box", "shrink": 0.92},
    "prt_casa_3": {"type": "box", "shrink": 0.92}, "prt_casa_4": {"type": "box", "shrink": 0.92},
    "fed_farola": {"type": "cylinder", "radius": 0.15},
    "fed_verja": {"type": "box", "shrink": 0.95},
    "sue_lapida_1": {"type": "box", "shrink": 0.9}, "sue_lapida_2": {"type": "box", "shrink": 0.9},
    "dun_arbol_partido": {"type": "cylinder", "radius": 0.5},
    "inn_barril": {"type": "cylinder", "radius": 0.35},
    "inn_cajas_2": {"type": "box", "shrink": 0.9},
    "inn_carretilla": {"type": "box", "shrink": 0.85},
    "prt_banco": {"type": "box", "shrink": 0.9},
    "inn_escombros": {"type": "cylinder", "radius": 0.6},
})

# el campanario, en el mundo: el punto «steeple» del modelo
here = os.path.dirname(os.path.abspath(__file__))
cm = json.load(open(os.path.join(here, '..', 'models', 'fed_iglesia.json'), encoding='utf-8'))
vs = float(cm.get('voxel_size', 1.0 / 16.0))
sx, sy, sz = cm['pivots']['steeple']
STEEPLE = [round(CHURCH[0] + sx * vs, 2), round(CHURCH[1] + sz * vs, 2), round(sy * vs, 2)]

A.write({
    "name": "Federal Hill",
    "spawn": [2.0, 16.0],
    "steeple": STEEPLE,                            # [x, z, altura] del Trapezoedro (Blackout, HaunterBehavior)
    "ground": {"seed": 35, "tile": 0.5, "margin_back": 16.0, "margin_front": 16.0, "camp_radius": 0.0,
               "kind": "cobble", "wet": 0.75,
               "colors": {"base_hi": [0.36, 0.35, 0.36], "base_lo": [0.20, 0.20, 0.22], "joint": [0.06, 0.06, 0.07]}},
    # tormenta de noche: sin luna; la luz, la de las farolas eléctricas, blanca y fría
    "light": {"gamma": 1.5, "sun_rot": [-40, 35], "sun_color": [0.56, 0.62, 0.80], "sun_energy": 0.32, "exposure": 1.2,
              "ambient_color": [0.36, 0.40, 0.52], "ambient_energy": 0.40,
              "background": [0.02, 0.02, 0.03], "fog_color": [0.18, 0.20, 0.25], "fog_density": 0.0},
    "lamp": {"color": [0.86, 0.90, 1.0], "energy": 2.8, "range": 7.0},
    "colliders": COLL,
})
print("steeple", STEEPLE)
