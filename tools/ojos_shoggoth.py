"""Ojos del shoggoth de ojos luminosos (hito 4.5) en azul claro brillante (revisión de arte,
13-10-2026; antes verde). El modelo se recoloreó de shoggoth_grande con un script en línea:
si se rehace, vuelve a ejecutar esto después. Uso: python tools/ojos_shoggoth.py
"""
import json

EYE = [0.16, 0.48, 0.92]                     # oscurecido: ACES lo quema casi a blanco
d = json.load(open('models/shoggoth_ojos.json'))
n = 0
for v in d['voxels']:
    if v[7]: v[4:7] = EYE; n += 1
json.dump(d, open('models/shoggoth_ojos.json', 'w'))
print('shoggoth_ojos', n, 'voxels de ojos')
