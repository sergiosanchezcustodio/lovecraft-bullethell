"""Arena del nivel 1 de la parte 3: Providence, el estudio del escultor Wilcox (hito 7.1).
Receta del generador de escenarios (tools/arena_kit.py). Primera arena de interior.

48 x 48 m: la planta diáfana del último piso del edificio Fleur-de-Lys, convertida en estudio.
Suelo de tablas (`planks`). Paredes de ladrillo con ventanales al norte y al oeste (arriba en
pantalla); al sur y al este, solo el arranque de la pared (cortada para que la cámara vea
dentro). Pilares de hierro, esculturas, caballetes, mesas de trabajo, sacos de barro y, al
fondo, el bajorrelieve de arcilla de Wilcox. Lámparas de pie encendidas; la luna entra fría
por los ventanales. Uso: python tools/gen_arena_estudio.py
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 24.0
A = Arena("estudio", seed=1925, half=HALF, spawn_clear=4.0,
          foot={"prv_muro": 12.0, "prv_muro_bajo": 2.0, "prv_mesa": 2.0, "prv_pilar": 0.5,
                "prv_escultura_1": 0.8, "prv_escultura_2": 0.6, "prv_caballete": 0.8, "prv_sacos": 1.2,
                "prv_lampara": 0.4, "prv_relieve": 0.8})

# paredes: altas al norte y al oeste, el arranque al sur y al este
for x in range(-int(HALF) + 6, int(HALF) + 12, 12):
    A.add("prv_muro", x, -HALF, rot=0)
for z in range(-int(HALF) + 6, int(HALF) + 12, 12):
    A.add("prv_muro", -HALF, z, rot=90)
for t in range(-int(HALF) + 2, int(HALF) + 4, 4):
    A.add("prv_muro_bajo", t, HALF + 0.2, rot=0)
    A.add("prv_muro_bajo", HALF + 0.2, t, rot=90)

# pilares de hierro en cuadrícula (la estructura del edificio)
for x in (-12, 0, 12):
    for z in (-12, 0, 12):
        if (x, z) == (0, 0): continue
        A.add("prv_pilar", x, z, rot=0)

# el rincón del bajorrelieve, al fondo (noroeste), con su lámpara
A.add("prv_relieve", -17.0, -17.0, rot=45, scale=1.8)
A.add("prv_lampara", -14.5, -19.0, rot=0, scale=1.2)
A.add("prv_mesa", -19.5, -12.0, rot=90)

# zonas de trabajo: mesas con sus caballetes y esculturas, lámparas de pie
for (x, z, r) in ((8, -16, 0), (-16, 8, 90), (15, 6, 30), (4, 15, -20)):
    A.add("prv_mesa", x, z, rot=r)
    A.add("prv_lampara", x + 2.5, z + 2.0, rot=0, scale=1.2)
for (x, z, r) in ((5, -13, 160), (11, -18, 200), (-13, 4, 70), (18, 9, 220), (-6, 18, 10)):
    A.add("prv_caballete", x, z, rot=r)
A.scatter("prv_escultura_1", 14, 5.0, 1.0, 1.4)
A.scatter("prv_escultura_2", 12, 5.0, 1.0, 1.3)
A.scatter("prv_caballete", 8, 6.0, 1.0, 1.2)
A.scatter("prv_sacos", 10, 6.0, 0.9, 1.3)
A.scatter("prv_mesa", 3, 8.0, 1.0, 1.0)

COLL = dict(COLLIDERS)
COLL.update({
    "prv_muro": {"type": "box", "shrink": 0.98},
    "prv_muro_bajo": {"type": "box", "shrink": 0.95},
    "prv_pilar": {"type": "cylinder", "radius": 0.25},
    "prv_mesa": {"type": "box", "shrink": 0.95},
    "prv_escultura_1": {"type": "box", "shrink": 0.9},
    "prv_escultura_2": {"type": "box", "shrink": 0.9},
    "prv_caballete": {"type": "box", "shrink": 0.8},
    "prv_sacos": {"type": "box", "shrink": 0.85},
    "prv_lampara": {"type": "cylinder", "radius": 0.2},
    "prv_relieve": {"type": "box", "shrink": 0.85},
})

A.write({
    "name": "Providence: el estudio del escultor Wilcox",
    "spawn": [0.0, 3.0],
    "ground": {"seed": 31, "tile": 0.5, "margin_back": 6.0, "margin_front": 6.0, "walk_back": 0.0, "camp_radius": 0.0,
               "kind": "planks", "wet": 0.0,
               "colors": {"base_hi": [0.44, 0.33, 0.22], "base_lo": [0.26, 0.19, 0.13], "joint": [0.05, 0.04, 0.03],
                          "moss": [0.30, 0.26, 0.20]}},
    # noche: la luna fría por los ventanales, las lámparas cálidas dentro
    "light": {"sun_rot": [-40, 60], "sun_color": [0.55, 0.62, 0.80], "sun_energy": 0.35, "exposure": 1.3,
              "ambient_color": [0.34, 0.34, 0.42], "ambient_energy": 0.45,
              "background": [0.05, 0.05, 0.07], "fog_color": [0.12, 0.12, 0.16], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.72, 0.42], "energy": 2.2, "range": 8.0, "fog": 0.2},
    "colliders": COLL,
})
