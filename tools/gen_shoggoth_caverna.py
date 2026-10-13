"""El shoggoth de la caverna (evento final del nivel 3, parte 1) con modelo propio, recoloreado de
shoggoth_grande (revisión de arte, 13-10-2026): gris muy claro, albino, con alguna veta rosada
(revisión del 13-10-2026), en lugar de negro con reflejos verdes y violetas, y ojos de un blanco que brilla. Boca y dientes se quedan.
Si se rehace shoggoth_grande, vuelve a ejecutarlo. Uso: python tools/gen_shoggoth_caverna.py
"""
import json, random

GRAY = (0.86, 0.89, 0.95); BROWN = (0.88, 0.76, 0.80)          # albino: gris muy claro con vetas rosadas
EYE = (0.80, 0.80, 0.78)
d = json.load(open('models/shoggoth_grande.json'))
rng = random.Random(1938)
for v in d['voxels']:
    x, y, z, part, r, g, b, gl = v
    if gl: v[4:7] = EYE; continue
    if r > g + 0.12 and r > b + 0.12: continue                     # boca, encías y dientes (rojos y cremas)
    l = (r + g + b) / 3
    k = 0.82 + 0.8 * l + 0.10 * (rng.random() - 0.5)               # conserva las luces y sombras del original
    t = 0.25 * ((x * 13 + y * 7 + z * 5) % 11 / 10.0) + (0.6 if (x // 7 + y // 6 + z // 7) % 6 == 0 else 0.0)   # gris con vetas pardas
    t = max(0.0, min(1.0, t))
    c = [GRAY[i] * (1 - t) + BROWN[i] * t for i in range(3)]
    v[4:7] = [round(min(1.0, q * k), 3) for q in c]
json.dump(d, open('models/shoggoth_caverna.json', 'w'))
print('shoggoth_caverna', len(d['voxels']), 'voxels')
