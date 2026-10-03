"""Generador de escenarios (hito 4.1): lo común de todas las arenas. Cada nivel es una receta
(tools/gen_arena_<nombre>.py) que crea una Arena, coloca sus piezas y la escribe:

    A = Arena('campamento', seed=1930, half=32.0, foot={'atrezo_cabana': 3.6})
    A.add('atrezo_tienda', -8, -6.5, rot=20, scale=1.5)
    A.scatter('monticulo_1', 5, rmin=14.0, smin=0.9, smax=1.3)
    A.write({...})      # name, ground, barrier, sea, light, colliders... (ver ArenaBuilder)

write() escribe data/arenas/<nombre>.json y el mapa de lo transitable (gen_mapa_transitable).
Coordenadas en metros, X y Z, con el centro de la arena en (0, 0); el norte (z < 0) y el
oeste (x < 0) quedan arriba en pantalla: ahí van las paredes altas, que no tapan al jugador.
"""
import json, math, random, os, sys
sys.path.insert(0, os.path.dirname(__file__))


class Arena:
    def __init__(self, name, seed, half, foot=None, spawn_clear=5.0):
        self.name = name
        self.rng = random.Random(seed)
        self.half = half
        self.props = []
        self.foot = foot or {}                  # radio que ocupa cada pieza a escala 1 (resto, 1,2 m)
        self.spawn_clear = spawn_clear          # radio libre alrededor de la salida

    def add(self, model, x, z, rot=None, scale=1.0):
        self.props.append({"model": model, "pos": [round(x, 2), round(z, 2)],
                           "rot": round(self.rng.uniform(0, 360) if rot is None else rot, 1),
                           "scale": round(scale, 2)})

    def free(self, x, z, r):
        """¿Está (x, z) a más de r metros de todas las piezas y de la zona de salida?"""
        if math.hypot(x, z) < self.spawn_clear + r: return False
        for p in self.props:
            px, pz = p["pos"]
            if math.hypot(px - x, pz - z) < r + self.foot.get(p["model"], 1.2) * p["scale"]: return False
        return True

    def scatter(self, model, n, rmin, smin, smax, bias=None, margin=3.0, rot=None):
        """n piezas al azar a más de rmin del centro y sin pisar otras. bias: más cerca del
        borde sur o este (la orilla)."""
        H = self.half
        placed, tries = 0, 0
        while placed < n and tries < 2000:
            tries += 1
            x = self.rng.uniform(-H + margin, H - margin); z = self.rng.uniform(-H + margin, H - margin)
            if bias and self.rng.random() < 0.6:
                if self.rng.random() < 0.5: x = self.rng.uniform(H - 12, H - margin)
                else: z = self.rng.uniform(H - 12, H - margin)
            s = self.rng.uniform(smin, smax)
            if math.hypot(x, z) < rmin or not self.free(x, z, 1.5 * s): continue
            self.add(model, x, z, rot=rot, scale=s)
            placed += 1
        return placed

    def edge(self, models, sides=('south', 'east'), step=2.6, inset=0.0, smin=0.9, smax=1.3, extra=12.0):
        """Borde de piezas bajas pegadas (ventisqueros, rocas) a lo largo del sur y del este,
        en vez del mar: cierran la arena sin tapar a los jugadores."""
        H = self.half
        t = -H - extra
        while t < H + extra:
            for side in sides:
                j = self.rng.uniform(-0.6, 0.6)
                m = models[self.rng.randrange(len(models))]
                s = self.rng.uniform(smin, smax)
                if side == 'south': self.add(m, t, H + inset + j, scale=s)
                else: self.add(m, H + inset + j, t, scale=s)
            t += step

    def coast(self, models=('costa_1', 'costa_2', 'costa_3'), step=7.5):
        """Frente de la plataforma de hielo en la orilla sur y este (tools/gen_costa_hielo.py)."""
        H = self.half
        t = -H - 12
        while t < H + 1:
            self.add(models[self.rng.randint(1, len(models)) - 1], t, H, rot=0)
            self.add(models[self.rng.randint(1, len(models)) - 1], H, t, rot=90)
            t += step

    def floes(self, icebergs, n=80):
        """Icebergs dados y témpanos de varios tamaños en el mar (más y más pequeños cerca)."""
        H = self.half
        items = []
        def ok(x, z, r): return all(math.hypot(x - a, z - b) > r + q + 0.6 for a, b, q in items)
        def put(model, x, z, r):
            items.append((x, z, r)); self.add(model, x, z)
        for x, z in icebergs:
            put("iceberg_%d" % self.rng.randint(1, 2), x, z, 5.0)
        R = [0.7, 1.1, 1.6, 2.3, 3.2]
        tries = 0
        while tries < 3000 and len(items) < n:
            tries += 1
            d = self.rng.uniform(2.6, 22.0)
            along = self.rng.uniform(-H - 10, H + 20)
            x, z = (along, H + d) if self.rng.random() < 0.5 else (H + d, along)
            k = min(4, int(self.rng.random() ** 1.6 * 5 * (0.5 + d / 22)))
            if ok(x, z, R[k]): put("tempano_%d" % (k + 1), x, z, R[k])

    def write(self, layout):
        layout = dict(layout)
        layout.setdefault("size", [self.half * 2, self.half * 2])
        layout.setdefault("spawn", [0.0, 0.0])
        layout["props"] = self.props
        path = "data/arenas/%s.json" % self.name
        with open(path, "w") as f:
            json.dump(layout, f, indent=1)
        print(self.name, len(self.props), "piezas")
        import gen_mapa_transitable
        gen_mapa_transitable.build(self.name)


# Colisiones comunes del atrezo (las arenas añaden las suyas)
COLLIDERS = {
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
}

# Luz del crepúsculo polar (nivel 1, aprobada el 30-09-2026)
POLAR_DUSK = {"sun_rot": [-18, 35], "sun_color": [1.0, 0.80, 0.62], "sun_energy": 0.6, "exposure": 1.2,
              "ambient_color": [0.50, 0.58, 0.72], "ambient_energy": 0.32,
              "background": [0.20, 0.25, 0.33], "fog_color": [0.30, 0.36, 0.46], "fog_density": 0.0}

ICE_BARRIER = ["barrera_hielo_1", "barrera_hielo_2", "barrera_hielo_3"]
LAMP = {"color": [1.0, 0.72, 0.4], "energy": 2.2, "range": 8.0}
