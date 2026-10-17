"""Arena del nivel 3 de la parte 3: los muelles y la cubierta del Alert (hito 7.3).
Receta del generador de escenarios (tools/arena_kit.py).

Muelle de Auckland, de noche: 64 x 64 m de tablas mojadas (`planks`). Al norte, el Alert a
flote, atracado a lo largo del muelle (pieza de borde a 16 voxels/m, 33 m; el agua sigue por
el norte: `margin_north` 0); al oeste, la fila de edificios
del puerto (`gen_atrezo_puerto.py`: almacenes, casas, taberna y tienda, con humo en las chimeneas). Grúas, bolardos con cabos, fardos con lona, rollos
de cabo, botes y faroles de puerto. Al sur y al este, el agua del puerto, con barcas amarradas.
Uso: python tools/gen_arena_muelle.py
"""
import math
from arena_kit import Arena, COLLIDERS

HALF = 32.0
SEA = -1.2                                                    # nivel del agua del puerto
A = Arena("muelle", seed=1925, half=HALF, spawn_clear=4.0,
          foot={"alr_casco": 17.0, "alr_grua": 1.8, "alr_fardos": 1.6, "alr_bolardo": 0.4, "alr_rollo": 0.5,
                "alr_linterna": 0.3, "alr_bote": 1.4, "inn_fachada": 4.0, "prt_almacen": 4.0, "prt_casa": 4.0, "prt_casa_2": 4.0, "prt_taberna": 4.6, "prt_tienda": 4.0, "inn_barril": 0.4, "inn_cajas": 0.8})

A.add("alr_casco", -2.0, -HALF - 4.4, rot=0, y=SEA - 0.35)    # el Alert, a flote y atracado al norte
A.add("alr_casco", 46.0, -HALF - 6.0, rot=8)                 # otro vapor detrás
# al oeste, la fila de edificios del puerto (revisión de arte del 14-10-2026): almacenes, casas
# de tablas, la taberna con su cartel y la tienda de efectos navales, con humo en las chimeneas
for z, m in zip(range(-26, 40, 9), ("prt_almacen", "prt_casa", "prt_taberna", "prt_tienda",
                                     "prt_casa_2", "prt_almacen", "prt_casa_2", "prt_casa")):
    A.add(m, -HALF - 3.0, z, rot=90)
for x in range(-26, 30, 6):                                   # bolardos en el borde del muelle
    A.add("alr_bolardo", x, -HALF + 1.2, rot=A.rng.uniform(0, 360))
for x, z in ((-18, -24), (6, -24), (22, -22)):
    A.add("alr_grua", x, z, rot=90)
for x, z in ((-12, -18), (14, -16), (-20, 2), (18, 8), (2, 18), (-10, 22)):
    A.add("alr_linterna", x, z, rot=A.rng.choice([0, 90, 180, 270]), scale=1.2)
A.scatter("alr_fardos", 10, 6.0, 0.9, 1.2)
A.scatter("alr_rollo", 8, 5.0, 1.0, 1.3)
A.scatter("inn_cajas", 8, 5.0, 1.0, 1.2)
A.scatter("inn_barril", 10, 5.0, 1.0, 1.2)
A.add("alr_bote", 10.0, -8.0, rot=30)
A.add("alr_bote", -16.0, 12.0, rot=-60)
# pilotes en el agua, un 50 % más altos (16-10-2026): siempre fuera del muro (antes A.edge los
# repartía con holgura y alguno caía sobre las tablas)
t = -HALF - 12.0
while t < HALF + 12.0:
    for side in ("south", "east"):
        j = A.rng.uniform(0.5, 0.8)
        A.rng.uniform(0, 1); A.rng.uniform(1.0, 1.2)
        past = t > HALF + 1.0                                       # sin pasar de la esquina
        if side == "south": A.add("inn_pilote_alto", t, HALF + j, scale=1.0, past_corner=past)
        else: A.add("inn_pilote_alto", HALF + j, t, scale=1.0, past_corner=past)
    t += 3.0
for x in range(-31, 32, 3):                                   # pilotes del canto norte, en el agua
    A.add("inn_pilote_alto", x + A.rng.uniform(-0.4, 0.4), -HALF - 0.5 - A.rng.uniform(0, 0.5), y=SEA - 0.15, scale=A.rng.uniform(1.0, 1.1))
# barcas amarradas al muelle (revisión de arte del 14-10-2026): la proa (+x del modelo) mira al
# canto y la amarra sube hasta la tabla; flotan en el agua, al norte junto al Alert, al sur y al este
BARCA_PILE = 1.73                                            # de la popa al centro del pilote de la amarra (gen_atrezo_alert.py)
def moor(m, x, z, rot):
    """La barca con su pilote delante, en la dirección de la proa (+x del modelo), a la que va
    amarrada; flota algo más lejos del muro que antes, con el pilote entre los dos."""
    a = math.radians(rot)
    A.add(m, x, z, rot=rot, y=SEA - 0.05)
    A.add("inn_pilote_alto", x + math.cos(a) * BARCA_PILE, z - math.sin(a) * BARCA_PILE, rot=0, y=SEA - 0.15)
for m, x, z, rot in (("alr_barca", 19.0, -HALF - 2.6, -90), ("alr_barca_2", 23.5, -HALF - 2.7, -84),
                     ("alr_barca_3", 28.0, -HALF - 2.6, -95), ("alr_barca_2", -24.0, HALF + 2.6, 92),
                     ("alr_barca", -6.0, HALF + 2.6, 86), ("alr_barca_3", 12.0, HALF + 2.6, 90),
                     ("alr_barca", HALF + 2.6, 16.0, 180), ("alr_barca_3", HALF + 2.6, -10.0, 176)):
    moor(m, x, z, rot)

# faroles en el borde del muelle, colgando sobre el agua: su luz se refleja en ella (16-10-2026);
# al final, para no mover lo repartido
for x, z, r in ((HALF - 1.4, -4.0, 0), (HALF - 1.4, 20.0, 0), (3.0, HALF - 1.4, -90), (-18.0, HALF - 1.4, -90)):
    A.add("alr_linterna", x, z, rot=r, scale=1.2)

# escalera de piedra que baja al agua (gen_escalera_muelle.py) con una barca amarrada al pie; fuera
# los pilotes que caerían encima (16-10-2026)
A.props = [p for p in A.props if not (p["model"] == "inn_pilote_alto" and 15.5 < p["pos"][0] < 20.2 and abs(p["pos"][1] - HALF) < 1.5)]
A.add("inn_escalera_muelle", 16.0, HALF, rot=0, y=0.0)
moor("alr_barca", 20.7, HALF + 2.6, 90)

COLL = dict(COLLIDERS)
COLL.update({
    "alr_casco": {"type": "box", "shrink": 0.95},
    "alr_grua": {"type": "cylinder", "radius": 0.4},
    "alr_fardos": {"type": "box", "shrink": 0.9},
    "alr_bolardo": {"type": "cylinder", "radius": 0.25},
    "alr_rollo": {"type": "cylinder", "radius": 0.4},
    "alr_linterna": {"type": "cylinder", "radius": 0.1},
    "alr_bote": {"type": "box", "shrink": 0.85},
    "inn_fachada": {"type": "box", "shrink": 0.95},
    "prt_almacen": {"type": "box", "shrink": 0.95},
    "prt_casa": {"type": "box", "shrink": 0.95},
    "prt_casa_2": {"type": "box", "shrink": 0.95},
    "prt_taberna": {"type": "box", "shrink": 0.9},
    "prt_tienda": {"type": "box", "shrink": 0.9},
    "inn_barril": {"type": "cylinder", "radius": 0.35},
    "inn_cajas": {"type": "box", "shrink": 0.9},
    "inn_cajas_2": {"type": "box", "shrink": 0.9},
    "inn_cajas_3": {"type": "box", "shrink": 0.85},
    "inn_pilote": {"type": "cylinder", "radius": 0.2},
    "inn_pilote_alto": {"type": "cylinder", "radius": 0.2},
    "alr_barca": {"type": "box", "shrink": 0.85},
    "alr_barca_2": {"type": "box", "shrink": 0.85},
    "alr_barca_3": {"type": "box", "shrink": 0.85},
})

A.write({
    "name": "Los muelles y la cubierta del Alert",
    "spawn": [0.0, 4.0],
    "ground": {"seed": 33, "tile": 0.5, "margin_back": 14.0, "margin_north": 0.0, "walk_back": 0.0, "camp_radius": 0.0,
               "edge_color": [0.20, 0.16, 0.12],
               "kind": "planks", "wet": 0.75,
               "colors": {"base_hi": [0.40, 0.35, 0.29], "base_lo": [0.22, 0.19, 0.16], "joint": [0.03, 0.03, 0.03]}},
    "sea": {"sides": ["north", "south", "east"], "level": SEA, "brash": 0.0,
            "colors": {"deep": [0.03, 0.06, 0.08], "mid": [0.06, 0.11, 0.14], "shallow": [0.10, 0.17, 0.20],
                       "crest": [0.18, 0.25, 0.28], "foam": [0.44, 0.50, 0.52]}},
    "light": {"sun_rot": [-32, 40], "sun_color": [0.62, 0.70, 0.86], "sun_energy": 0.4, "exposure": 1.3,
              "ambient_color": [0.38, 0.44, 0.50], "ambient_energy": 0.5,
              "background": [0.06, 0.08, 0.10], "fog_color": [0.18, 0.22, 0.26], "fog_density": 0.0},
    "lamp": {"color": [1.0, 0.78, 0.50], "energy": 3.4, "range": 9.5, "fog": 0.3},
    "colliders": COLL,
    "no_shadow": ["inn_pilote", "inn_pilote_alto", "alr_barca", "alr_barca_2", "alr_barca_3"],
})
