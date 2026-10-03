"""Barrera de roca (nivel 3, el paso de la cordillera): los tres tramos de la Barrera de hielo
(gen_barrera_hielo.py) recoloreados en granito oscuro, con la nieve de las cornisas intacta.
El hielo claro pasa a roca gris parda según su brillo; las grietas, a casi negro.
Escribe models/barrera_roca_{1,2,3}.json. Uso: python tools/gen_barrera_roca.py
"""
import json

ROCK_HI = (0.46, 0.44, 0.42); ROCK_LO = (0.22, 0.21, 0.21); CRACK = (0.09, 0.09, 0.10)

def lerp(a, b, t): return [a[i] + (b[i] - a[i]) * t for i in range(3)]

for i in (1, 2, 3):
    d = json.load(open('models/barrera_hielo_%d.json' % i))
    for v in d['voxels']:
        r, g, b = v[4:7]
        if r > 0.78 and g > 0.80 and b > 0.84: continue              # nieve: se queda
        lum = 0.3 * r + 0.59 * g + 0.11 * b
        blueness = b - r
        if blueness > 0.3 and lum < 0.4: c = CRACK                     # grietas
        else: c = lerp(ROCK_LO, ROCK_HI, max(0.0, min(1.0, (lum - 0.45) / 0.35)))
        v[4:7] = [round(x, 3) for x in c]
    d['roughness'] = 0.85; d['specular'] = 0.25
    json.dump(d, open('models/barrera_roca_%d.json' % i, 'w'))
    print('barrera_roca_%d' % i, len(d['voxels']))
