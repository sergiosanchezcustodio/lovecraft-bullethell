"""Arena provisional del nivel 1 de la parte 1: campamento base en la costa del mar de Ross.

Escribe data/arenas/campamento.json con la colocación de todas las piezas. La arena
es finita (D-03): 64 x 64 m, con acantilados de roca al norte y al oeste (arriba en
pantalla, no tapan al jugador) y el mar helado al sur y al este (abajo en pantalla).
El campamento ocupa el centro; rocas y hielo reparten obstáculos por el resto.
Coordenadas en metros, X y Z; el centro de la arena es (0, 0).
Uso: python tools/gen_arena_campamento.py
"""
import json, math, random

rng = random.Random(1930)
HALF = 32.0
props = []

def add(model, x, z, rot=None, scale=1.0):
    props.append({"model": model, "pos": [round(x, 2), round(z, 2)],
                  "rot": round(rng.uniform(0, 360) if rot is None else rot, 1), "scale": round(scale, 2)})

# Radio que ocupa cada pieza grande a escala 1 (lo demás, 1,2 m).
FOOT = {"atrezo_cabana": 3.6, "atrezo_tienda": 2.6, "atrezo_iglu": 2.2}

def free(x, z, r):
    """¿Está (x, z) a más de r metros de todas las piezas y de la zona de aparición?"""
    if math.hypot(x, z) < 5.0 + r: return False
    for p in props:
        px, pz = p["pos"]
        if math.hypot(px - x, pz - z) < r + FOOT.get(p["model"], 1.2) * p["scale"]: return False
    return True

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

# ---------- Orilla del mar: sur (z = +32) y este (x = +32) ----------
# Frente de la plataforma de hielo (tools/gen_costa_hielo.py): tramos de 8,5 m cada 7,5,
# justo en la orilla (a la altura del suelo; lo que pasa de la orilla flotaría).
t = -HALF - 12
while t < HALF + 1:
    add("costa_%d" % rng.randint(1, 3), t, HALF, rot=0)
    add("costa_%d" % rng.randint(1, 3), HALF, t, rot=90)
    t += 7.5
# Témpanos de varios tamaños (más y más pequeños cerca de la orilla) e icebergs lejos
sea_items = []
def sea_free(x, z, r):
    return all(math.hypot(x - a, z - b) > r + q + 0.6 for a, b, q in sea_items)
def sea_add(model, x, z, r):
    sea_items.append((x, z, r)); add(model, x, z)
for x, z in ((HALF + 16, HALF + 9), (HALF + 9, HALF + 20), (HALF + 22, -6), (-8, HALF + 21)):
    sea_add("iceberg_%d" % rng.randint(1, 2), x, z, 5.0)
FLOE_R = [0.7, 1.1, 1.6, 2.3, 3.2]
tries = 0
while tries < 3000 and len(sea_items) < 80:
    tries += 1
    d = rng.uniform(2.6, 22.0)                       # distancia a la orilla
    along = rng.uniform(-HALF - 10, HALF + 20)
    x, z = (along, HALF + d) if rng.random() < 0.5 else (HALF + d, along)
    k = min(4, int(rng.random() ** 1.6 * 5 * (0.5 + d / 22)))
    r = FLOE_R[k]
    if sea_free(x, z, r):
        sea_add("tempano_%d" % (k + 1), x, z, r)

# ---------- Obstáculos repartidos ----------
def scatter(model, n, rmin, smin, smax, bias=None):
    placed, tries = 0, 0
    while placed < n and tries < 2000:
        tries += 1
        x = rng.uniform(-HALF + 3, HALF - 3); z = rng.uniform(-HALF + 3, HALF - 3)
        if bias and rng.random() < 0.6:                      # más cerca de la orilla (sur o este)
            if rng.random() < 0.5: x = rng.uniform(HALF - 12, HALF - 3)
            else: z = rng.uniform(HALF - 12, HALF - 3)
        s = rng.uniform(smin, smax)
        if math.hypot(x, z) < rmin or not free(x, z, 1.5 * s): continue
        add(model, x, z, scale=s)
        placed += 1

scatter("monticulo_1", 5, 14.0, 0.9, 1.3)
scatter("monticulo_2", 3, 16.0, 0.9, 1.2)
scatter("monticulo_3", 7, 13.0, 0.8, 1.4)
scatter("atrezo_bloques_hielo", 5, 13.0, 0.9, 1.2)
scatter("atrezo_hielo", 5, 14.0, 0.8, 1.4, bias=True)
scatter("atrezo_caja", 4, 16.0, 1.0, 1.0)

layout = {
    "name": "Campamento base en la costa del mar de Ross",
    "size": [HALF * 2, HALF * 2],
    "spawn": [0.0, 0.0],
    "ground": {"seed": 5, "tile": 0.5, "margin_back": 12.0},
    "sea": {"sides": ["south", "east"], "level": -1.0},
    # Barrera de hielo al norte y al oeste (tools/gen_barrera_hielo.py): cierra la arena en
    # lugar del vacío. Llega hasta meterse en el mar por el este y por el sur.
    "barrier": {"models": ["barrera_hielo_1", "barrera_hielo_2", "barrera_hielo_3"], "sides": ["north", "west"],
                "line": HALF + 4.5, "spacing": 7.0, "from": -HALF - 12.0, "to": HALF + 14.0, "y": -1.0, "plateau": 7.2},
    # Crepúsculo polar (30-09-2026): sol bajo y cálido, sombras largas y ambiente azulado
    "light": {"sun_rot": [-18, 35], "sun_color": [1.0, 0.80, 0.62], "sun_energy": 0.6, "exposure": 1.2,
              "ambient_color": [0.50, 0.58, 0.72], "ambient_energy": 0.32,
              "background": [0.20, 0.25, 0.33], "fog_color": [0.30, 0.36, 0.46], "fog_density": 0.0},
    # sin sombra: solo caería sobre el agua, que no la recibe (ahorra geometría)
    "no_shadow": ["costa_1", "costa_2", "costa_3", "tempano_1", "tempano_2", "tempano_3", "tempano_4",
                  "tempano_5", "iceberg_1", "iceberg_2"],
    "lamp": {"color": [1.0, 0.72, 0.4], "energy": 2.2, "range": 8.0},
    "colliders": {
        "atrezo_tienda": {"type": "box", "shrink": 0.8},
        "atrezo_iglu": {"type": "cylinder", "radius": 1.75},
        "atrezo_cabana": {"type": "box", "shrink": 0.82},
        "atrezo_bloques_hielo": {"type": "box", "shrink": 0.9},
        "atrezo_caja": {"type": "box", "shrink": 0.95},
        "atrezo_bidon": {"type": "cylinder", "radius": 0.3},
        "atrezo_farol": {"type": "cylinder", "radius": 0.15},
        "atrezo_roca": {"type": "box", "shrink": 0.8},
        "atrezo_trineo": {"type": "box", "shrink": 0.85},
        "atrezo_tripode": {"type": "cylinder", "radius": 0.3},
        "atrezo_bandera": {"type": "cylinder", "radius": 0.12},
        "monticulo_1": {"type": "cylinder", "radius": 1.4},
        "monticulo_2": {"type": "cylinder", "radius": 1.9},
        "monticulo_3": {"type": "cylinder", "radius": 0.95},
        "atrezo_hielo": {"type": "box", "shrink": 0.75},
    },
    "props": props,
}
with open("data/arenas/campamento.json", "w") as f:
    json.dump(layout, f, indent=1)
print(len(props), "piezas")

# mapa de lo transitable (voxels reales de las piezas) y tramos de la barrera
import gen_mapa_transitable
gen_mapa_transitable.build("campamento")
