"""Arena de la noche suelta «La sombra fuera del tiempo» (hito 21.15): las ruinas de Pnakotus, en el Gran
Desierto Arenoso de Australia Occidental (julio de 1935). Receta del generador de escenarios
(tools/arena_kit.py).

64 x 64 m de arena rojiza (suelo `mud`, con los colores del desierto). En el centro, un poco al norte, la
gran trampilla del archivo, entre bloques caídos y tramos de muro: de ahí sube el jefe. Alrededor, seis
trampillas más pequeñas (las cierra la Gran Raza, las abre el viento: PolypWinds, con sus posiciones en
`trapdoors`). Al norte (arriba en pantalla), dos torres sin ventanas y los muros de la ciudad medio
enterrados; al oeste, otra torre. Al sur, el campamento de la expedición de la Miskatonic (tiendas, cajas
y la hoguera), donde se empieza. Dunas en los bordes y matas de spinifex sueltas. Noche clara con luna.
Uso: python tools/gen_arena_pnakotus.py  (y después tools/render_mapa.gd -- noche_pnakotus)
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
GREAT = (0.0, -7.0)                           # la gran trampilla del archivo (el jefe; LevelData)
TRAPS = [(-15.0, -15.0), (15.0, -16.0), (-21.0, 4.0), (20.0, 2.0), (-11.0, 17.0), (13.0, 15.0)]
CAMP = (6.0, 24.0)
A = Arena("pnakotus", seed=1935, half=HALF, spawn_clear=4.0,
          foot={"pna_bloque_1": 1.9, "pna_bloque_2": 2.3, "pna_bloque_3": 1.6, "pna_muro": 4.5, "pna_torre": 2.6,
                "pna_trampilla": 1.2, "pna_duna_1": 4.0, "pna_duna_2": 3.0, "pna_matorral": 0.6, "pna_roca": 1.3,
                "pna_tienda": 2.0, "atrezo_caja": 0.7, "lui_hoguera": 1.0, "atrezo_farol": 0.5})

# la gran trampilla y lo que la rodea: bloques caídos y dos tramos de muro, con la entrada al sur
A.add("pna_trampilla", GREAT[0], GREAT[1], rot=0, scale=2.0)
for a, m, r in ((200, "pna_bloque_2", 6.5), (250, "pna_bloque_1", 6.0), (300, "pna_bloque_3", 6.2), (335, "pna_bloque_1", 6.8)):
    x, z = GREAT[0] + math.cos(math.radians(a)) * r, GREAT[1] + math.sin(math.radians(a)) * r
    A.add(m, x, z, rot=-a + 90 + A.rng.uniform(-15, 15), scale=A.rng.uniform(0.9, 1.1))
A.add("pna_muro", GREAT[0] - 8.5, GREAT[1] - 3.5, rot=70)
A.add("pna_muro", GREAT[0] + 8.5, GREAT[1] - 2.5, rot=-75)

# las trampillas pequeñas, cada una con algún bloque cerca
for i, (x, z) in enumerate(TRAPS):
    A.add("pna_trampilla", x, z, rot=A.rng.uniform(0, 360), scale=1.0)
    a = A.rng.uniform(0, math.tau)
    A.add("pna_bloque_%d" % (1 + i % 3), x + math.cos(a) * 3.4, z + math.sin(a) * 3.4, scale=A.rng.uniform(0.7, 0.9))

# el norte: las torres sin ventanas y los muros de la ciudad
A.add("pna_torre", -9.0, -27.0, rot=10, scale=1.0)
A.add("pna_torre", 15.0, -26.5, rot=40, scale=0.9)
A.add("pna_torre", -27.0, -9.0, rot=80, scale=0.85)
for x, z, rot in ((-22.0, -28.5, 0), (2.5, -29.0, 0), (27.0, -26.0, 10), (-28.5, -21.0, 90), (-28.5, 14.0, 90), (-28.5, 26.0, 85)):
    A.add("pna_muro", x, z, rot=rot, scale=A.rng.uniform(0.95, 1.1))

# el borde norte y el oeste: la muralla de la ciudad, medio enterrada, con dunas detrás
for x in range(-30, 34, 8):
    if abs(x + 9) < 4 or abs(x - 15) < 4: continue                     # las torres
    A.add("pna_muro", x + A.rng.uniform(-0.8, 0.8), -HALF - 0.8 + A.rng.uniform(-0.4, 0.4), rot=A.rng.uniform(-6, 6))
for z in range(-26, 30, 8):
    if abs(z + 9) < 4: continue
    A.add("pna_muro", -HALF - 0.8 + A.rng.uniform(-0.4, 0.4), z + A.rng.uniform(-0.8, 0.8), rot=90 + A.rng.uniform(-6, 6))
for x in range(-34, 36, 10):
    A.add("pna_duna_1", x, -HALF - 6.0, rot=A.rng.uniform(-6, 6), scale=1.2)
for z in range(-30, 36, 10):
    A.add("pna_duna_1", -HALF - 6.0, z, rot=90 + A.rng.uniform(-6, 6), scale=1.2)
A.add("pna_duna_2", -HALF - 3.0, -HALF - 3.0, rot=45, scale=1.3)

# el sur y el este: dunas (el borde)
for x in range(-26, 34, 9):
    A.add("pna_duna_1" if (x // 9) % 2 else "pna_duna_2", x + A.rng.uniform(-1.5, 1.5), HALF + 2.5, rot=A.rng.uniform(-8, 8),
          scale=A.rng.uniform(0.95, 1.2))
for z in range(-24, 30, 9):
    A.add("pna_duna_2" if (z // 9) % 2 else "pna_duna_1", HALF + 2.5, z + A.rng.uniform(-1.5, 1.5), rot=90 + A.rng.uniform(-8, 8),
          scale=A.rng.uniform(0.95, 1.2))

# el campamento de la expedición de 1935
A.add("pna_tienda", CAMP[0] - 2.5, CAMP[1] + 1.5, rot=-20)
A.add("pna_tienda", CAMP[0] + 3.5, CAMP[1] + 2.5, rot=15)
A.add("lui_hoguera", CAMP[0], CAMP[1] - 1.5, rot=0)
A.add("atrezo_caja", CAMP[0] + 5.5, CAMP[1] - 1.0, rot=30)
A.add("atrezo_caja", CAMP[0] + 6.3, CAMP[1] - 0.2, rot=5, scale=0.85)
A.add("atrezo_farol", CAMP[0] - 4.5, CAMP[1] - 1.0, rot=0)

# bloques sueltos, peñas y spinifex
for x, z in ((-6.0, 6.0), (7.0, 4.0), (24.0, -8.0), (-24.0, -18.0), (25.0, 22.0), (-18.0, 26.0), (0.0, 14.0)):
    A.add("pna_bloque_%d" % (1 + int(abs(x + z)) % 3), x, z, scale=A.rng.uniform(0.75, 1.05))
for x, z in ((-14.0, 26.0), (20.0, 26.0), (26.0, 12.0), (-24.0, -2.0), (10.0, -22.0)):
    A.add("pna_roca", x, z, scale=A.rng.uniform(0.85, 1.2))
# grupos de bloques caídos, como restos de muros (lejos de las trampillas)
for cx, cz in ((-4.0, -20.0), (22.0, -18.0), (-18.0, -24.0), (24.0, 12.0), (-22.0, 18.0), (2.0, 26.0)):
    for k in range(3):
        a = A.rng.uniform(0, math.tau)
        x, z = cx + math.cos(a) * A.rng.uniform(0, 2.5), cz + math.sin(a) * A.rng.uniform(0, 2.5)
        if A.free(x, z, 1.6): A.add("pna_bloque_%d" % (1 + k % 3), x, z, scale=A.rng.uniform(0.6, 0.95))
A.scatter("pna_roca", 4, 9.0, 0.7, 1.0)
A.scatter("pna_matorral", 40, 5.0, 0.8, 1.3)

COLL = dict(COLLIDERS)
COLL.update({
    "pna_bloque_1": {"type": "box", "shrink": 0.8}, "pna_bloque_2": {"type": "box", "shrink": 0.8},
    "pna_bloque_3": {"type": "box", "shrink": 0.8},
    "pna_muro": {"type": "box", "shrink": 0.8},
    "pna_torre": {"type": "cylinder", "radius": 2.1},
    "pna_duna_1": {"type": "box", "shrink": 0.7}, "pna_duna_2": {"type": "box", "shrink": 0.7},
    "pna_roca": {"type": "box", "shrink": 0.8},
    "pna_matorral": {"type": "cylinder", "radius": 0.35},
    "pna_tienda": {"type": "box", "shrink": 0.8},
    "lui_hoguera": {"type": "cylinder", "radius": 0.55},
    "atrezo_farol": {"type": "cylinder", "radius": 0.25},
})

A.write({
    "name": "Las ruinas de Pnakotus",
    "spawn": [0.0, 20.0],
    "great_door": [GREAT[0], GREAT[1]],
    "trapdoors": [[x, z] for x, z in TRAPS],
    "walkable": ["pna_trampilla"],              # se pisan: hay que ponerse en medio para sellarlas
    "ground": {"seed": 47, "tile": 0.5, "margin_back": 14.0, "margin_front": 18.0, "camp_radius": 0.0,
               "kind": "mud", "wet": 0.0,
               "colors": {"base_hi": [0.50, 0.37, 0.25], "base_lo": [0.38, 0.27, 0.18],
                          "moss": [0.40, 0.36, 0.22], "puddle": [0.32, 0.23, 0.16]}},
    # noche clara en el desierto: la luna alta y fría sobre la arena rojiza; la luz cálida, la de la hoguera
    "light": {"sun_rot": [-50, 30], "sun_color": [0.70, 0.76, 0.92], "sun_energy": 0.45, "exposure": 1.15,
              "ambient_color": [0.42, 0.46, 0.58], "ambient_energy": 0.42,
              "background": [0.05, 0.06, 0.10], "fog_color": [0.30, 0.27, 0.26], "fog_density": 0.0, "gamma": 1.3},
    "lamp": {"color": [1.0, 0.64, 0.34], "energy": 2.6, "range": 9.0},
    "colliders": COLL,
})
