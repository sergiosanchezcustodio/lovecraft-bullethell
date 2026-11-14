"""Arena del nivel 4.5, la cima de Kadath en el yermo helado (parte 4, hito 21.9). Receta del generador de
escenarios (tools/arena_kit.py).

64 x 64 m de nieve dura sobre ónice, a la puerta del castillo de los Grandes Dioses. Al norte y al oeste
(arriba en pantalla), las murallas de ónice negro con alguna ventana alta encendida; en medio del norte, la
gran puerta con su arco de luz dorada y la escalinata, por donde baja Nyarlathotep. De la escalinata al sur
baja una avenida de pilares de ónice con braseros entre ellos; por los lados, pilares partidos y trozos de
ónice medio enterrados en la nieve. Al sur y al este, escombros bajos con nieve, que no tapan. Se empieza
al sur, al pie de la avenida.
Uso: python tools/gen_arena_kadath.py  (y después tools/render_mapa.gd -- p4_n5)
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
GATE_Z = -HALF - 3.0
A = Arena("kadath", seed=1930, half=HALF, spawn_clear=4.0,
          foot={"sue_puerta_kadath": 7.5, "sue_pilar_1": 1.0, "sue_pilar_2": 1.6, "sue_brasero": 0.7,
                "sue_escombro_1": 1.4, "sue_escombro_2": 1.2})

A.add("sue_puerta_kadath", 0.0, GATE_Z, rot=0)

# la avenida de pilares, de la escalinata al sur, con braseros entre ellos
for i, z in enumerate(range(-22, 24, 9)):
    for sx in (-1, 1):
        x = sx * 8.0
        broken = (i + (sx > 0)) % 4 == 3
        A.add("sue_pilar_2" if broken else "sue_pilar_1", x, z, rot=A.rng.choice((0, 90)) if broken else 0)
    if i % 2 == 0:
        for sx in (-1, 1): A.add("sue_brasero", sx * 4.5, z + 4.5)

# por los lados: pilares partidos sueltos (ruinas de otra avenida) y escombros
for x, z in ((-20.0, -18.0), (-24.0, -4.0), (-18.0, 10.0), (-22.0, 22.0), (18.0, -20.0), (22.0, -6.0),
             (20.0, 8.0), (24.0, 20.0)):
    A.add("sue_pilar_2" if A.rng.random() < 0.6 else "sue_pilar_1", x + A.rng.uniform(-1, 1), z + A.rng.uniform(-1, 1),
          rot=A.rng.uniform(0, 360))
for x, z in ((-14.0, -26.0), (14.0, -26.0), (-26.0, 14.0), (26.0, -14.0)):
    A.add("sue_brasero", x, z)
A.scatter("sue_escombro_1", 6, 8.0, 0.7, 1.0)
A.scatter("sue_escombro_2", 6, 8.0, 0.7, 1.0)

# Cierre al sur y al este: escombros bajos con nieve
A.edge(["sue_escombro_1", "sue_escombro_2"], step=2.6, inset=1.2, smin=1.0, smax=1.3)

COLL = dict(COLLIDERS)
COLL.update({
    "sue_puerta_kadath": {"type": "box", "shrink": 0.95},
    "sue_pilar_1": {"type": "box", "shrink": 0.9}, "sue_pilar_2": {"type": "cylinder", "radius": 0.7},
    "sue_brasero": {"type": "cylinder", "radius": 0.45},
    "sue_escombro_1": {"type": "box", "shrink": 0.8}, "sue_escombro_2": {"type": "box", "shrink": 0.8},
})

A.write({
    "name": "La cima de Kadath",
    "spawn": [0.0, 24.0],
    "gate": [0.0, GATE_Z + 4.5],
    "ground": {"seed": 79, "tile": 0.5, "margin_back": 14.0, "margin_front": 18.0, "camp_radius": 0.0,
               # nieve dura, con el ónice asomando en las placas de hielo
               "colors": {"snow_lo": [0.40, 0.42, 0.52], "snow_hi": [0.60, 0.63, 0.74], "ice": [0.16, 0.14, 0.22],
                          "ice_vein": [0.30, 0.26, 0.40], "trampled": [0.44, 0.46, 0.56]}},
    "barrier": {"models": ["sue_muro_onice_1", "sue_muro_onice_2", "sue_muro_onice_3"], "sides": ["north", "west"],
                "line": HALF + 4.5, "spacing": 7.4, "from": -HALF - 12.0, "to": HALF + 16.0, "y": -0.5, "plateau": 9.0,
                "plateau_color": [0.10, 0.09, 0.13]},
    # la cumbre: estrellas frías y la luna violeta; la luz cálida, la de los braseros; la puerta, dorada
    "light": {"sun_rot": [-40, 25], "sun_color": [0.62, 0.62, 0.90], "sun_energy": 0.4, "exposure": 1.0,
              "ambient_color": [0.40, 0.40, 0.60], "ambient_energy": 0.4,
              "background": [0.03, 0.03, 0.07], "fog_color": [0.20, 0.20, 0.32], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.56, 0.26], "energy": 2.8, "range": 8.5, "fog": 0.25},
    "lamps": {"sue_puerta_kadath": {"color": [1.0, 0.82, 0.44], "energy": 4.0, "range": 13.0, "fog": 0.35, "fog_tint": True}},
    "colliders": COLL,
})
