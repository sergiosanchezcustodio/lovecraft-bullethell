"""El shoggoth de la caverna (evento final del nivel 3, parte 1) con modelo propio, recoloreado de
shoggoth_grande (revisión de arte, 13-10-2026): gris muy claro, albino, con alguna veta rosada
(revisión del 13-10-2026), en lugar de negro con reflejos verdes y violetas, con el iris gris, la pupila rojo sangre y los labios gris oscuro. Dientes como el original.
Si se rehace shoggoth_grande, vuelve a ejecutarlo. Uso: python tools/gen_shoggoth_caverna.py
"""
import json, random

GRAY = (0.86, 0.89, 0.95); BROWN = (0.88, 0.76, 0.80)          # albino: gris muy claro con vetas rosadas
IRIS = (0.46, 0.47, 0.50); PUPIL = (0.62, 0.02, 0.03)          # iris gris y pupila rojo sangre (revisión del 13-10-2026)
LIP = (0.20, 0.20, 0.22); MAW = (0.05, 0.03, 0.04)              # labios gris oscuro y la boca por dentro, oscura
d = json.load(open('models/shoggoth_grande.json'))
rng = random.Random(1938)
glow = {(v[0], v[1], v[2]) for v in d['voxels'] if v[7]}
def near_glow(x, y, z):
    return sum((x + a, y + b, z + c) in glow for a in (-1, 0, 1) for b in (-1, 0, 1) for c in (-1, 0, 1))
for v in d['voxels']:
    x, y, z, part, r, g, b, gl = v[:8]                # el noveno, si lo hay: caras de dentro
    if gl: v[4:7] = IRIS; continue
    if r + g + b < 0.13 and near_glow(x, y, z) >= 3:               # pupila (negra en el original): roja y brilla
        v[4:7] = PUPIL; v[7] = 1; continue
    if r > g + 0.12 and r > b + 0.12:                              # encías (los labios) y dientes
        if r < 0.45: v[4:7] = LIP
        continue
    if r > g + 0.03 and r > b and r + g + b < 0.16:                # interior de la boca
        v[4:7] = MAW; continue
    l = (r + g + b) / 3
    k = 0.82 + 0.8 * l + 0.10 * (rng.random() - 0.5)               # conserva las luces y sombras del original
    t = 0.25 * ((x * 13 + y * 7 + z * 5) % 11 / 10.0) + (0.6 if (x // 7 + y // 6 + z // 7) % 6 == 0 else 0.0)   # gris con vetas pardas
    t = max(0.0, min(1.0, t))
    c = [GRAY[i] * (1 - t) + BROWN[i] * t for i in range(3)]
    v[4:7] = [round(min(1.0, q * k), 3) for q in c]
json.dump(d, open('models/shoggoth_caverna.json', 'w'))
print('shoggoth_caverna', len(d['voxels']), 'voxels')
