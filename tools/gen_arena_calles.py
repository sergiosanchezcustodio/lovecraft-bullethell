"""Arena del nivel 2 de la parte 2: las calles de Innsmouth y el templo de la Orden (hito 6.2).
Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m de adoquín mojado (suelo `cobble`) con la plaza de la fuente en el centro. Al norte,
el antiguo templo masónico de la Orden de Dagon (pórtico jónico) entre casas, tiendas y tabernas,
con alguna luz encendida y humo en las chimeneas; al oeste, más casas; en la plaza, bancos y olmos. Al sur y al este, el muelle de tablas (`dock`) con
pilotes y el agua verde oscura del puerto, sin hielo. En el centro de la plaza, la gran fuente con la
sirena de bronce. Por las calles, coches abandonados,
carretillas y cajas de pescado, nasas, escombros y farolas de gas. Anochecer frío con lluvia.
Uso: python tools/gen_arena_calles.py
"""
from arena_kit import Arena, COLLIDERS

HALF = 32.0
A = Arena("calles", seed=1928, half=HALF,
          foot={"inn_templo": 8.0, "inn_fachada": 4.2, "prt_casa": 4.0, "prt_casa_3": 4.0, "prt_casa_4": 4.0, "prt_tienda": 4.0,
               "prt_tienda_inn": 4.0, "prt_taberna": 4.6, "prt_taberna_inn": 4.6, "prt_almacen": 4.0, "prt_banco": 1.2, "prt_arbol": 2.2, "prt_arbol_2": 2.2, "inn_fuente": 1.4, "inn_coche": 2.2, "inn_casa": 4.5})

A.add("inn_templo", 0.0, -HALF - 3.6, rot=0)                       # el templo (gen_templo_orden.py), al fondo
# casas, tiendas y tabernas variadas (revisión de arte del 14-10-2026; gen_atrezo_puerto.py): algunas
# luces encendidas y chimeneas que humean; quedan dos casas georgianas en ruinas
for x, m in zip((-24.0, -15.0, 15.0, 24.0, 33.0), ("prt_tienda_inn", "inn_fachada", "prt_casa_3", "prt_taberna_inn", "prt_casa_4")):
    A.add(m, x, -HALF - 3.0 + A.rng.uniform(-0.4, 0.4), rot=0)
for z, m in zip(range(-24, 40, 9), ("prt_casa_4", "prt_taberna", "prt_casa_3", "prt_tienda", "inn_fachada",
                                    "prt_casa", "prt_tienda_inn", "prt_almacen")):
    A.add(m, -HALF - 3.0 + A.rng.uniform(-0.4, 0.4), float(z), rot=90)

A.add("inn_fuente", 0.0, 0.0, rot=0, scale=1.0)                     # la plaza
for x, z in ((-7.0, -7.0), (7.0, -7.0), (-7.0, 7.0), (7.0, 7.0)):
    A.add("inn_farola", x, z, rot=0, scale=1.2)
# la plaza: bancos mirando a la fuente y olmos en las esquinas
for x, z, r in ((0.0, -4.8, 0), (-4.8, 0.0, 90), (4.8, 0.0, -90), (0.0, 4.8, 180)):
    A.add("prt_banco", x, z, rot=r)
for x, z, m in ((-11.0, -10.5, "prt_arbol"), (10.5, -10.0, "prt_arbol_2"), (-10.5, 10.5, "prt_arbol_2"), (11.0, 10.0, "prt_arbol")):
    A.add(m, x, z, rot=A.rng.uniform(0, 360))
for x, z, r in ((-8.6, -12.6, 0), (12.8, -7.6, -90), (-12.8, 7.6, 90)):
    A.add("prt_banco", x, z, rot=r)
for x, z, r in ((-14.0, 6.0, 30), (12.0, -14.0, -60), (18.0, 12.0, 110)):
    A.add("inn_coche", x, z, rot=r)
for x, z, r in ((-6.0, 15.0, 10), (14.0, 3.0, 80), (-17.0, -12.0, -20)):
    A.add("inn_carretilla", x, z, rot=r)
for x, z in ((-10.0, 18.0), (21.0, -3.0), (5.0, 21.0), (-20.0, 20.0)):
    A.add("inn_cajas", x, z)
for x, z in ((-22.0, -4.0), (-12.0, -20.0), (10.0, -21.0), (-24.0, 12.0)):
    A.add("inn_escombros", x, z)

# el muelle: nasas, barriles y redes cerca del agua; pilotes a lo largo del borde
for x, z in ((24.0, 22.0), (27.0, 8.0), (10.0, 27.0), (-6.0, 27.0)):
    A.add("inn_nasa", x, z)
for x, z in ((26.5, 16.0), (16.0, 26.5), (-14.0, 26.0)):
    A.add("inn_barril", x, z)
A.add("inn_redes", 26.0, -10.0, rot=90)
A.add("inn_redes", -22.0, 26.0, rot=0)
for t in range(-30, 34, 5):
    A.add("inn_pilote", t, HALF + 0.3, rot=0)
    A.add("inn_pilote", HALF + 0.3, t, rot=0)
A.scatter("inn_escombros", 4, 12.0, 0.8, 1.2)
A.scatter("inn_barril", 4, 10.0, 1.0, 1.0)
# la sirena de bronce (gen_sirena.py) en la roca de la fuente, mirando a la cámara; al final, para
# no mover lo repartido (16-10-2026: la fuente, el triple de grande; la sirena sustituye al cachalote)
A.add("inn_sirena", 0.0, 0.0, rot=45, y=36 / 32)
# farolas en el borde del muelle: su luz se refleja en el agua del puerto (16-10-2026)
for x, z in ((HALF - 1.4, -2.5), (HALF - 1.4, 17.5), (2.5, HALF - 1.4), (-17.5, HALF - 1.4)):
    A.add("inn_farola", x, z, rot=0, scale=1.2)

COLL = dict(COLLIDERS)
COLL.update({
    "inn_templo": {"type": "box", "shrink": 0.95},
    "inn_fachada": {"type": "box", "shrink": 0.95},
    "prt_casa": {"type": "box", "shrink": 0.95}, "prt_casa_3": {"type": "box", "shrink": 0.95},
    "prt_casa_4": {"type": "box", "shrink": 0.95}, "prt_tienda": {"type": "box", "shrink": 0.9},
    "prt_tienda_inn": {"type": "box", "shrink": 0.9}, "prt_taberna": {"type": "box", "shrink": 0.9},
    "prt_taberna_inn": {"type": "box", "shrink": 0.9}, "prt_almacen": {"type": "box", "shrink": 0.95},
    "prt_banco": {"type": "box", "shrink": 0.9}, "prt_arbol": {"type": "cylinder", "radius": 0.3},
    "prt_arbol_2": {"type": "cylinder", "radius": 0.3},
    "inn_fuente": {"type": "cylinder", "radius": 3.7},
    "inn_sirena": {"type": "cylinder", "radius": 0.6},
    "inn_coche": {"type": "box", "shrink": 0.9},
    "inn_carretilla": {"type": "box", "shrink": 0.85},
    "inn_cajas": {"type": "box", "shrink": 0.9},
    "inn_cajas_2": {"type": "box", "shrink": 0.9},
    "inn_cajas_3": {"type": "box", "shrink": 0.85},
    "inn_nasa": {"type": "box", "shrink": 0.9},
    "inn_pilote": {"type": "cylinder", "radius": 0.18},
    "inn_escombros": {"type": "cylinder", "radius": 0.7},
    "inn_farola": {"type": "cylinder", "radius": 0.2},
    "inn_barril": {"type": "cylinder", "radius": 0.35},
    "inn_redes": {"type": "box", "shrink": 0.9},
})

A.write({
    "name": "Las calles de Innsmouth y el templo de la Orden",
    "spawn": [3.5, 6.0],                  # delante de la fuente (en el centro está el pilón)
    "ground": {"seed": 28, "tile": 0.5, "margin_back": 14.0, "camp_radius": 0.0,
               "kind": "cobble", "wet": 0.7, "dock": HALF - 6.0,
               "colors": {"base_hi": [0.50, 0.49, 0.47], "base_lo": [0.28, 0.28, 0.28], "joint": [0.08, 0.08, 0.07]}},
    "sea": {"sides": ["south", "east"], "level": -1.0, "brash": 0.0,
            "colors": {"deep": [0.04, 0.09, 0.08], "mid": [0.08, 0.17, 0.15], "shallow": [0.14, 0.26, 0.22],
                       "crest": [0.24, 0.34, 0.30], "foam": [0.50, 0.56, 0.52]}},
    "light": {"sun_rot": [-28, 30], "sun_color": [0.70, 0.76, 0.86], "sun_energy": 0.42, "exposure": 1.25,
              "ambient_color": [0.42, 0.48, 0.54], "ambient_energy": 0.44,
              "background": [0.12, 0.15, 0.17], "fog_color": [0.26, 0.30, 0.33], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.78, 0.48], "energy": 2.2, "range": 8.0},
    "colliders": COLL,
    "no_shadow": ["inn_pilote"],
})
