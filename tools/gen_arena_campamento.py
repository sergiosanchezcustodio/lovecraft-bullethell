"""Arena del nivel 1 de la parte 1: campamento base en la costa del mar de Ross. Receta del
generador de escenarios (tools/arena_kit.py).

La arena es finita (D-03): 64 x 64 m, con la Barrera de hielo al norte y al oeste (arriba en
pantalla, no tapan al jugador) y el mar helado al sur y al este (abajo en pantalla).
El campamento ocupa el centro; montículos y hielo reparten obstáculos por el resto.
Uso: python tools/gen_arena_campamento.py
"""
import math
from arena_kit import Arena, COLLIDERS, POLAR_DUSK, ICE_BARRIER, LAMP

HALF = 32.0
# Radio que ocupa cada pieza grande a escala 1 (lo demás, 1,2 m).
A = Arena("campamento", seed=1930, half=HALF,
          foot={"atrezo_cabana": 3.6, "atrezo_tienda": 2.6, "atrezo_iglu": 2.2})
add = A.add

# ---------- Campamento (centro) ----------
# Variedad: dos tiendas, un iglú y una cabaña de troncos (la puerta y la ventana hacia la cámara)
# A 1,5× (03-10-2026): a escala 1 se veían de juguete al lado de los personajes.
BIG = 1.5
add("atrezo_tienda", -8.0, -6.5, 20, BIG)
add("atrezo_tienda", 9.0, 7.5, -35, BIG)
add("atrezo_iglu", 7.5, -10.0, 55, BIG)
add("atrezo_cabana", -14.5, 8.0, 30, BIG)
for x, z, r in ((-3.8, -9.5, 10), (-3.0, -10.4, 40), (-2.2, -9.2, 75), (11.2, -3.5, 5), (11.6, -2.5, 30),
                (-11.8, 1.2, 60), (3.5, 11.0, 20), (4.3, 11.6, 0)):
    add("atrezo_caja", x, z, r)
for x, z in ((-5.5, -10.5), (12.0, -5.2), (-12.5, 2.6), (5.2, 12.2), (5.9, 11.3)):
    add("atrezo_bidon", x, z)
# Faroles alrededor del campamento: fuentes de luz (recuperarán cordura en la fase 2)
for i in range(6):
    a = math.radians(30 + i * 60)
    add("atrezo_farol", math.cos(a) * 10.5, math.sin(a) * 10.5, rot=math.degrees(-a) + 90, scale=BIG)
# Material de la expedición (tools/gen_atrezo_expedicion.py)
add("atrezo_bandera", -2.5, -12.5, rot=10)
add("atrezo_trineo", -9.5, -1.5, rot=70)
add("atrezo_trineo", 12.8, 3.0, rot=-20)
add("atrezo_tripode", 3.0, -13.5, rot=0)
add("atrezo_tripode", -16.5, 13.5, rot=40)
add("atrezo_farol", -20.0, -18.0, rot=45, scale=BIG)
add("atrezo_farol", 19.0, 17.0, rot=225, scale=BIG)

# Norte y oeste: los cierra la barrera de hielo ("barrier", más abajo).
# Orilla del mar al sur (z = +32) y al este (x = +32): frente de la plataforma, témpanos e icebergs
A.coast()
A.floes([(HALF + 16, HALF + 9), (HALF + 9, HALF + 20), (HALF + 22, -6), (-8, HALF + 21)])

# Obstáculos repartidos
A.scatter("monticulo_1", 5, 14.0, 0.9, 1.3)
A.scatter("monticulo_2", 3, 16.0, 0.9, 1.2)
A.scatter("monticulo_3", 7, 13.0, 0.8, 1.4)
A.scatter("atrezo_bloques_hielo", 5, 13.0, 0.9, 1.2)
A.scatter("atrezo_hielo", 5, 14.0, 0.8, 1.4, bias=True)
A.scatter("atrezo_caja", 4, 16.0, 1.0, 1.0)

A.write({
    "name": "Campamento base en la costa del mar de Ross",
    "ground": {"seed": 5, "tile": 0.5, "margin_back": 12.0},
    "sea": {"sides": ["south", "east"], "level": -1.0},
    # Barrera de hielo al norte y al oeste (tools/gen_barrera_hielo.py): llega hasta meterse en el mar
    "barrier": {"models": ICE_BARRIER, "sides": ["north", "west"],
                "line": HALF + 4.5, "spacing": 7.0, "from": -HALF - 12.0, "to": HALF + 14.0, "y": -1.0, "plateau": 7.2},
    "light": POLAR_DUSK,
    # sin sombra: solo caería sobre el agua, que no la recibe (ahorra geometría)
    "no_shadow": ["costa_1", "costa_2", "costa_3", "tempano_1", "tempano_2", "tempano_3", "tempano_4",
                  "tempano_5", "iceberg_1", "iceberg_2"],
    "lamp": LAMP,
    "colliders": COLLIDERS,
})
