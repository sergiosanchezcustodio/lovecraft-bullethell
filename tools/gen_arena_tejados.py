"""Arena del nivel 3 de la parte 2: el hotel Gilman House y la huida por los tejados (hito 6.3).
Receta del generador de escenarios (tools/arena_kit.py).

60 x 60 m de tejados planos de tablas mojadas (suelo `planks`). Al norte, la trasera del Gilman
House con la escalera de incendios y alguna ventana encendida, entre tejados abuhardillados;
al oeste, más buhardillas. Al sur y al este, el pretil y, abajo (piezas con `y` negativa), los
tejados y la calle de Innsmouth. Chimeneas, claraboyas, depósitos de agua, tendederos y
trampillas reparten el tejado en pasillos. Noche cerrada con niebla marina.
Uso: python tools/gen_arena_tejados.py
"""
from arena_kit import Arena, COLLIDERS

HALF = 30.0
A = Arena("tejados", seed=1929, half=HALF,
          foot={"tej_gilman": 7.0, "tej_buhardilla": 4.2, "tej_deposito": 1.4, "tej_tendedero": 1.8,
                "tej_chimenea": 0.6, "tej_claraboya": 1.0, "tej_pretil": 2.0})

A.add("tej_gilman", 0.0, -HALF - 2.0, rot=0)                       # el hotel, al fondo
for x in (-20.0, -11.0, 15.0, 24.0):
    A.add("tej_buhardilla", x, -HALF - 3.0, rot=0)
for z in range(-24, 34, 8):
    A.add("tej_buhardilla", -HALF - 3.0, float(z), rot=90)

for t in range(-28, 32, 4):                                         # el pretil del borde
    A.add("tej_pretil", float(t), HALF + 0.3, rot=0)
    A.add("tej_pretil", HALF + 0.3, float(t), rot=90)
for t in range(-36, 48, 8):                                         # abajo, los tejados de la calle (dos filas)
    A.add(["inn_casa", "inn_casa_2"][(int(t) // 8) % 2], float(t), HALF + 4.2, rot=180, y=-5.5)
    A.add(["inn_casa", "inn_casa_2"][(int(t) // 8) % 2], HALF + 4.2, float(t), rot=-90, y=-5.5)
    A.add("tej_buhardilla", float(t) + 4.0, HALF + 13.0, rot=180, y=-4.0)
    A.add("tej_buhardilla", HALF + 13.0, float(t) + 4.0, rot=-90, y=-4.0)
for t in (-22.0, 0.0, 22.0):
    A.add("inn_farola", t, HALF + 9.0, rot=0, y=-5.5, scale=1.3)    # farolas de la calle, abajo
    A.add("inn_farola", HALF + 9.0, t, rot=0, y=-5.5, scale=1.3)

# el tejado: obstáculos que hacen pasillos
for x, z in ((-12.0, -14.0), (13.0, -16.0), (-4.0, 18.0)):
    A.add("tej_deposito", x, z, rot=A.rng.uniform(0, 90))
for x, z, r in ((-16.0, 4.0, 0), (6.0, -6.0, 90), (18.0, 12.0, 30), (-6.0, -22.0, 0)):
    A.add("tej_tendedero", x, z, rot=r)
for x, z, r in ((-22.0, -8.0, 90), (2.0, 10.0, 0), (22.0, -2.0, 90)):    # medianeras bajas
    A.add("tej_pretil", x, z, rot=r)
A.scatter("tej_chimenea", 12, 6.0, 1.0, 1.3)
A.scatter("tej_claraboya", 6, 7.0, 1.0, 1.2)
A.scatter("tej_trampilla", 4, 8.0, 1.0, 1.0)

COLL = dict(COLLIDERS)
COLL.update({
    "tej_gilman": {"type": "box", "shrink": 0.95}, "tej_buhardilla": {"type": "box", "shrink": 0.95},
    "tej_chimenea": {"type": "box", "shrink": 0.95}, "tej_claraboya": {"type": "box", "shrink": 0.9},
    "tej_deposito": {"type": "cylinder", "radius": 1.1}, "tej_tendedero": {"type": "box", "shrink": 0.6},
    "tej_pretil": {"type": "box", "shrink": 1.0}, "tej_trampilla": {"type": "box", "shrink": 0.9},
    "inn_casa": {"type": "box", "shrink": 0.95}, "inn_casa_2": {"type": "box", "shrink": 0.95}, "inn_farola": {"type": "cylinder", "radius": 0.2},
})

A.write({
    "name": "El hotel Gilman House y la huida por los tejados",
    "spawn": [0.0, 4.0],
    "ground": {"seed": 29, "tile": 0.5, "margin_back": 14.0, "margin_front": 0.6, "camp_radius": 0.0,
               "kind": "planks", "wet": 0.6,
               "colors": {"base_hi": [0.40, 0.36, 0.32], "base_lo": [0.22, 0.20, 0.18], "joint": [0.02, 0.02, 0.02]}},
    # noche cerrada: luna fría tras las nubes; las ventanas del hotel y las farolas de abajo, cálidas
    "light": {"sun_rot": [-48, 210], "sun_color": [0.62, 0.70, 0.90], "sun_energy": 0.38, "exposure": 1.3,
              "ambient_color": [0.40, 0.46, 0.56], "ambient_energy": 0.46,
              "background": [0.015, 0.02, 0.03], "fog_color": [0.18, 0.21, 0.25], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.78, 0.48], "energy": 2.6, "range": 9.0},
    "colliders": COLL,
})
