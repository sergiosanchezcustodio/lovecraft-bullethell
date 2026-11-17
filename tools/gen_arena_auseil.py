"""Arena de la noche suelta «La música de Erich Zann» (hito 22.6): la rue d'Auseil, en París. Receta del
generador de escenarios (tools/arena_kit.py).

56 x 56 m de adoquín húmedo (suelo `cobble`). La calle sube hacia el norte (arriba en pantalla) en tramos
de escalones que la cruzan. Al oeste y al norte, las casas altas y estrechas, ladeadas, de tejados en pico
(gen_atrezo_auseil.py). Arriba del todo, la casa de Zann, la última y la más alta, con la buhardilla
encendida: de ahí sale la música (`viola` en el JSON, para ZannViola). Junto a ella, el muro alto cubierto
de hiedra con que acaba la calle. Al sur y al este, el río negro, con su pretil de piedra y barandilla.
Faroles de gas, barriles, cajas y una carretilla. Niebla baja del río.
Uso: python tools/gen_arena_auseil.py  (y después tools/render_mapa.gd -- noche_zann)
"""
import json
import math
import os
from arena_kit import Arena, COLLIDERS

HALF = 28.0
ZANN = (-7.0, -HALF - 2.2)                       # la casa de Zann, arriba
A = Arena("auseil", seed=1922, half=HALF, spawn_clear=4.0,
          foot={"aus_casa_1": 3.0, "aus_casa_2": 3.2, "aus_casa_3": 2.9, "aus_casa_zann": 3.2, "aus_muro": 5.0,
                "aus_escalones": 2.0, "aus_pretil": 2.0, "aus_farol": 0.4, "inn_barril": 0.5, "inn_cajas_2": 0.8,
                "inn_carretilla": 1.0, "inn_escombros": 0.8})

# el norte: casas mirando a la calle (+z) y, arriba, la de Zann y el muro de hiedra
A.add("aus_casa_zann", ZANN[0], ZANN[1], rot=0, scale=1.0)
north = (("aus_casa_2", -26.0), ("aus_casa_1", -21.5), ("aus_casa_3", -16.8), ("aus_casa_1", -12.2))
for m, x in north:
    A.add(m, x, -HALF - 2.0 + A.rng.uniform(-0.3, 0.3), rot=0, scale=A.rng.uniform(0.98, 1.05))
for x in (4.0, 14.0, 24.0):                       # el muro con que acaba la calle
    A.add("aus_muro", x, -HALF - 0.6, rot=0)
# el oeste: casas mirando al este (+x), en fila hasta el río
z = -22.0
k = 0
while z < HALF - 2.0:
    m = ("aus_casa_1", "aus_casa_3", "aus_casa_2")[k % 3]
    A.add(m, -HALF - 2.0 + A.rng.uniform(-0.3, 0.3), z, rot=90, scale=A.rng.uniform(0.98, 1.05))
    z += 4.2 if m != "aus_casa_2" else 4.6
    k += 1

# los tramos de escalones que cruzan la calle (se pisan), con algún rellano sin ellos
for zz, gaps in ((-15.0, (1,)), (-4.0, (4, 9)), (7.0, (6,)), (17.0, (2, 10))):
    for i in range(14):
        if i in gaps: continue
        x = -26.0 + i * 4.0
        if x > HALF - 2.0: break
        A.add("aus_escalones", x, zz, rot=0, scale=1.0, y=0.0)

# el río: el pretil al sur y al este
for t in range(-26, 30, 4):
    A.add("aus_pretil", float(t), HALF + 0.6, rot=0)
    A.add("aus_pretil", HALF + 0.6, float(t), rot=90)

# faroles de gas a los lados de la calle, y uno junto a la casa de Zann
for x, z in ((-22.0, -20.0), (-23.5, -6.0), (-23.5, 9.0), (-23.0, 22.0), (-2.0, -22.0), (12.0, -21.0),
             (24.5, -6.0), (24.5, 12.0), (6.0, 24.5), (-12.0, 24.5)):
    A.add("aus_farol", x, z, rot=0)
# lo que hay por la calle
for x, z in ((-20.0, -11.0), (-19.0, 3.0), (18.0, 22.0), (21.0, -18.0)):
    A.add("inn_barril", x, z)
for x, z in ((-19.5, 14.0), (19.0, 3.0), (-6.0, -21.0)):
    A.add("inn_cajas_2", x, z, rot=A.rng.uniform(0, 360))
A.add("inn_carretilla", 10.0, 12.0, rot=35)
A.add("inn_carretilla", -14.0, -9.0, rot=-70)
for x, z in ((6.0, -10.0), (-8.0, 13.0), (15.0, -12.0)):
    A.add("inn_escombros", x, z, scale=0.8)

COLL = dict(COLLIDERS)
COLL.update({
    "aus_casa_1": {"type": "box", "shrink": 0.92}, "aus_casa_2": {"type": "box", "shrink": 0.92},
    "aus_casa_3": {"type": "box", "shrink": 0.92}, "aus_casa_zann": {"type": "box", "shrink": 0.92},
    "aus_muro": {"type": "box", "shrink": 0.95},
    "aus_pretil": {"type": "box", "shrink": 0.95},
    "aus_farol": {"type": "cylinder", "radius": 0.15},
    "inn_barril": {"type": "cylinder", "radius": 0.35},
    "inn_cajas_2": {"type": "box", "shrink": 0.9},
    "inn_carretilla": {"type": "box", "shrink": 0.85},
    "inn_escombros": {"type": "cylinder", "radius": 0.6},
})

# la ventana de Zann, en el mundo: el punto «viola» del modelo
here = os.path.dirname(os.path.abspath(__file__))
zm = json.load(open(os.path.join(here, '..', 'models', 'aus_casa_zann.json'), encoding='utf-8'))
vs = float(zm.get('voxel_size', 1.0 / 16.0))
vx, vy, vz = zm['pivots']['viola']
VIOLA = [round(ZANN[0] + vx * vs, 2), round(ZANN[1] + vz * vs, 2), round(vy * vs, 2)]

A.write({
    "name": "La rue d'Auseil",
    "spawn": [4.0, 21.0],
    "viola": VIOLA,                                # [x, z, altura] de la ventana de Zann (ZannViola)
    "walkable": ["aus_escalones"],                 # bajos: se suben andando
    "ground": {"seed": 22, "tile": 0.5, "margin_back": 16.0, "camp_radius": 0.0,
               "kind": "cobble", "wet": 0.55,
               "colors": {"base_hi": [0.44, 0.42, 0.40], "base_lo": [0.25, 0.24, 0.24], "joint": [0.07, 0.07, 0.07]}},
    "sea": {"sides": ["south", "east"], "level": -1.4, "brash": 0.0,
            "colors": {"deep": [0.02, 0.025, 0.03], "mid": [0.05, 0.06, 0.07], "shallow": [0.09, 0.10, 0.11],
                       "crest": [0.18, 0.19, 0.21], "foam": [0.34, 0.35, 0.38]}},
    # noche cerrada de París: luna fría y velada; la luz cálida, la de los faroles y la ventana de Zann
    "light": {"gamma": 1.4, "sun_rot": [-38, 35], "sun_color": [0.66, 0.70, 0.86], "sun_energy": 0.4, "exposure": 1.2,
              "ambient_color": [0.40, 0.42, 0.54], "ambient_energy": 0.42,
              "background": [0.02, 0.02, 0.035], "fog_color": [0.22, 0.23, 0.28], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.76, 0.44], "energy": 2.3, "range": 8.5},
    "colliders": COLL,
    "no_shadow": ["aus_escalones"],
})
print("viola", VIOLA)
