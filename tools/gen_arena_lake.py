"""Arena del nivel 2 de la parte 1: el campamento destruido de Lake, en la meseta al pie de
las montañas de la locura. Receta del generador de escenarios (tools/arena_kit.py).

64 x 64 m sin mar: la Barrera de hielo al norte y al oeste (arriba en pantalla) y ventisqueros
bajos al sur y al este, que cierran sin tapar a los jugadores. En el centro, lo que queda del
campamento: tiendas rasgadas, el avión dañado, la perforadora volcada, mesas de disección
vacías, cajas reventadas y el corral de los perros con un tramo derribado. Día gris y frío.
Uso: python tools/gen_arena_lake.py
"""
import math
from arena_kit import Arena, COLLIDERS, ICE_BARRIER, LAMP

HALF = 32.0
A = Arena("lake", seed=1931, half=HALF,
          foot={"atrezo_tienda_rota": 2.6, "atrezo_avion": 5.0, "atrezo_perforadora": 3.5,
                "atrezo_mesa_diseccion": 1.4, "atrezo_tienda": 2.6})
BIG = 1.5

# ---------- Lo que queda del campamento ----------
A.add("atrezo_tienda_rota", -9.0, -7.0, rot=15, scale=BIG)
A.add("atrezo_tienda_rota", 8.0, -10.5, rot=-25, scale=BIG)
A.add("atrezo_tienda_rota", 11.0, 8.0, rot=60, scale=BIG)
A.add("atrezo_tienda", -12.0, 9.5, rot=-10, scale=BIG)          # la única en pie
A.add("atrezo_avion", -17.0, -17.5, rot=35)                     # el avión, al fondo
A.add("atrezo_perforadora", 17.5, -3.0, rot=-70)
for x, z, r in ((-3.0, -11.0, 10), (2.5, -12.5, -20), (-1.0, 12.0, 80)):
    A.add("atrezo_mesa_diseccion", x, z, rot=r)
for x, z in ((-6.0, -2.5), (5.5, 3.5), (-4.0, 6.5), (13.5, -7.0), (-14.0, 2.0), (3.0, -6.5)):
    A.add("atrezo_caja_rota", x, z)
for x, z, r in ((6.0, -4.0, 30), (-7.5, 3.0, 70), (14.5, 2.5, 5)):
    A.add("atrezo_caja", x, z, rot=r)
for x, z in ((-10.5, -2.0), (9.5, 12.5), (-2.0, -14.5)):
    A.add("atrezo_bidon", x, z)
A.add("atrezo_trineo", 1.0, 9.0, rot=110)
A.add("atrezo_tripode", 15.0, 12.5, rot=0)
# pocos faroles: el campamento quedó a oscuras (luz y recuperación de cordura, escasas)
for x, z in ((-5.5, -9.0), (9.0, 1.5), (-6.0, 10.5)):
    A.add("atrezo_farol", x, z, rot=A.rng.uniform(0, 360), scale=BIG)
# corral de los perros: muro de bloques de nieve en círculo, con un tramo derribado
CX, CZ, R = 20.0, 17.0, 5.0
for i in range(14):
    a = i / 14 * math.tau
    if 0.6 < a < 1.6: continue                                    # el hueco por donde salió algo
    A.add("atrezo_bloques_hielo", CX + R * math.cos(a), CZ + R * math.sin(a), rot=math.degrees(-a), scale=0.9)
for x, z in ((CX + 6.5, CZ + 4.5), (CX + 3.0, CZ + 8.0)):         # bloques caídos fuera
    A.add("atrezo_bloques_hielo", x, z, scale=0.7)

# ---------- Cierre: ventisqueros al sur y al este (sin mar) ----------
A.edge(["monticulo_1", "monticulo_2", "monticulo_3"], step=2.4, inset=1.5, smin=1.0, smax=1.5)

# ---------- Obstáculos repartidos ----------
A.scatter("monticulo_1", 6, 15.0, 0.9, 1.3)
A.scatter("monticulo_2", 4, 16.0, 0.9, 1.2)
A.scatter("monticulo_3", 8, 13.0, 0.8, 1.4)
A.scatter("atrezo_bloques_hielo", 4, 14.0, 0.9, 1.2)
A.scatter("atrezo_caja_rota", 4, 15.0, 1.0, 1.0)

COLL = dict(COLLIDERS)
COLL.update({
    "atrezo_tienda_rota": {"type": "box", "shrink": 0.8},
    "atrezo_caja_rota": {"type": "box", "shrink": 0.9},
    "atrezo_mesa_diseccion": {"type": "box", "shrink": 0.9},
    "atrezo_avion": {"type": "box", "shrink": 0.5},
    "atrezo_perforadora": {"type": "box", "shrink": 0.7},
})

A.write({
    "name": "El campamento destruido de Lake",
    # el suelo sigue 16 m por delante (sur y este): los ventisqueros se asientan en nieve
    "ground": {"seed": 6, "tile": 0.5, "margin_back": 12.0, "margin_front": 16.0, "camp_radius": 18.0},
    "barrier": {"models": ICE_BARRIER, "sides": ["north", "west"],
                "line": HALF + 4.5, "spacing": 7.0, "from": -HALF - 12.0, "to": HALF + 16.0, "y": -1.0, "plateau": 7.2},
    # día gris en la meseta: sol alto y velado, frío; más contraste que el crepúsculo del nivel 1
    "light": {"sun_rot": [-38, 140], "sun_color": [0.86, 0.90, 1.0], "sun_energy": 0.5, "exposure": 1.15,
              "ambient_color": [0.56, 0.62, 0.72], "ambient_energy": 0.42,
              "background": [0.42, 0.46, 0.52], "fog_color": [0.55, 0.60, 0.66], "fog_density": 0.0},
    "lamp": LAMP,
    "colliders": COLL,
})
