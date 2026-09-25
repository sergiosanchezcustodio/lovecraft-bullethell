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

def free(x, z, r):
    """¿Está (x, z) a más de r metros de todas las piezas y de la zona de aparición?"""
    if math.hypot(x, z) < 5.0 + r: return False
    for p in props:
        px, pz = p["pos"]
        if math.hypot(px - x, pz - z) < r + 1.2 * p["scale"]: return False
    return True

# ---------- Campamento (centro) ----------
# Variedad: dos tiendas, un iglú y una cabaña de troncos (la puerta y la ventana hacia la cámara)
add("atrezo_tienda", -7.5, -6.0, 20)
add("atrezo_tienda", 8.5, 7.0, -35)
add("atrezo_iglu", 7.0, -9.2, 55)
add("atrezo_cabana", -13.0, 7.5, 30)
for x, z, r in ((-3.8, -9.5, 10), (-3.0, -10.4, 40), (-2.2, -9.2, 75), (11.2, -3.5, 5), (11.6, -2.5, 30),
                (-11.8, 1.2, 60), (3.5, 11.0, 20), (4.3, 11.6, 0)):
    add("atrezo_caja", x, z, r)
for x, z in ((-5.5, -10.5), (12.0, -5.2), (-12.5, 2.6), (5.2, 12.2), (5.9, 11.3)):
    add("atrezo_bidon", x, z)
# Faroles alrededor del campamento: fuentes de luz (recuperarán cordura en la fase 2)
for i in range(6):
    a = math.radians(30 + i * 60)
    add("atrezo_farol", math.cos(a) * 10.5, math.sin(a) * 10.5, rot=math.degrees(-a) + 90)
add("atrezo_farol", -20.0, -18.0, rot=45)
add("atrezo_farol", 19.0, 17.0, rot=225)

# ---------- Acantilados: norte (z = -32) y oeste (x = -32) ----------
t = -HALF - 2
while t < HALF + 4:
    add("atrezo_roca", t + rng.uniform(-1, 1), -HALF - rng.uniform(1.2, 3.0), scale=rng.uniform(2.4, 3.4))
    add("atrezo_roca", -HALF - rng.uniform(1.2, 3.0), t + rng.uniform(-1, 1), scale=rng.uniform(2.4, 3.4))
    t += rng.uniform(3.0, 4.2)

# ---------- Orilla del mar: sur (z = +32) y este (x = +32), témpanos ----------
t = -HALF
while t < HALF:
    add("atrezo_hielo", t + rng.uniform(-1, 1), HALF + rng.uniform(1.0, 5.0), scale=rng.uniform(1.4, 2.6))
    add("atrezo_hielo", HALF + rng.uniform(1.0, 5.0), t + rng.uniform(-1, 1), scale=rng.uniform(1.4, 2.6))
    t += rng.uniform(4.0, 7.0)

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

scatter("atrezo_roca", 9, 14.0, 0.9, 1.8)
scatter("atrezo_bloques_hielo", 5, 13.0, 0.9, 1.2)
scatter("atrezo_hielo", 10, 14.0, 0.8, 1.6, bias=True)
scatter("atrezo_caja", 4, 16.0, 1.0, 1.0)

layout = {
    "name": "Campamento base en la costa del mar de Ross",
    "size": [HALF * 2, HALF * 2],
    "spawn": [0.0, 0.0],
    "ground": {"seed": 5, "tile": 0.5, "margin_back": 12.0},
    "sea": {"sides": ["south", "east"], "level": -0.45},
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
        "atrezo_hielo": {"type": "box", "shrink": 0.75},
    },
    "props": props,
}
with open("data/arenas/campamento.json", "w") as f:
    json.dump(layout, f, indent=1)
print(len(props), "piezas")
