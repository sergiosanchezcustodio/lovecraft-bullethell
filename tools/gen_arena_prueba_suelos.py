"""Campos de prueba de los suelos de la parte 2 (hito 6.0): data/arenas/prueba_<suelo>.json
con tierra mojada, adoquín y tablas, unos faroles (para ver el brillo de los charcos) y la luz
de atardecer nublado de Nueva Inglaterra. Sin oleadas: probar con
    godot --path . -- nolevel=true arena=res://data/arenas/prueba_cobble.json weather=niebla_marina
Uso: python tools/gen_arena_prueba_suelos.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from arena_kit import Arena, COLLIDERS, LAMP

# Atardecer nublado de Nueva Inglaterra: sol bajo y apagado tras las nubes, ambiente gris verdoso
NE_DUSK = {"sun_rot": [-24, 40], "sun_color": [0.95, 0.80, 0.66], "sun_energy": 0.42, "exposure": 1.2,
           "ambient_color": [0.46, 0.52, 0.52], "ambient_energy": 0.34,
           "background": [0.16, 0.19, 0.20], "fog_color": [0.30, 0.34, 0.35], "fog_density": 0.0}

GROUNDS = {
    "mud": {"base_hi": [0.36, 0.29, 0.21], "base_lo": [0.20, 0.16, 0.11]},
    "cobble": {"base_hi": [0.50, 0.49, 0.47], "base_lo": [0.27, 0.27, 0.27], "joint": [0.08, 0.08, 0.07]},
    "planks": {"base_hi": [0.46, 0.40, 0.33], "base_lo": [0.26, 0.22, 0.18], "joint": [0.03, 0.03, 0.03]},
    # fase 7: R'lyeh, con el ídolo del culto en medio
    "rlyeh": {"base_hi": [0.22, 0.29, 0.26], "base_lo": [0.09, 0.12, 0.11], "joint": [0.03, 0.05, 0.04],
              "moss": [0.12, 0.22, 0.14], "crack_glow": [0.18, 0.55, 0.32]},
}

for kind, colors in GROUNDS.items():
    A = Arena('prueba_' + kind, seed=6, half=16.0)
    for x, z in ((-4, -3), (5, 2), (-2, 6)): A.add('atrezo_farol', x, z, rot=0)
    if kind == 'rlyeh': A.add('cth_idolo', 3.0, -5.0, rot=0, scale=1.2)
    A.write({
        "name": "Prueba de suelo: " + kind,
        "ground": {"seed": 6, "tile": 0.5, "margin_back": 8.0, "margin_front": 8.0, "camp_radius": 0.0,
                   "kind": kind, "wet": 0.6, "colors": colors},
        "light": NE_DUSK,
        "lamp": LAMP,
        "colliders": COLLIDERS,
    })
