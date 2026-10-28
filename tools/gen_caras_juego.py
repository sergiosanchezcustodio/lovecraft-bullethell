"""Datos de la cara de cada personaje para el parpadeo y la mueca de dolor (27-10-2026):
data/faces.json con, por modelo, las casillas de los ojos (x, y, z del voxel delantero de
cada una, en coordenadas voxel) y las de alrededor que tapa la mueca, el color del párpado (la media de la piel alrededor de los ojos)
y la fila de la boca con su voxel más adelantado. Las caras dibujadas a mano (cuerpo.face_art) tienen los ojos de 4×2 en
x = -6..-3 y 2..5; solo cambia la fila, que se busca por los blancos (cuerpo.EYE_W).
Hay que ejecutarlo otra vez si cambia la cara de un personaje (después de su generador).
Uso: python tools/gen_caras_juego.py
"""
import sys, os, json, glob
sys.path.insert(0, os.path.dirname(__file__))
import cuerpo as cu

EYE_X = (-6, -5, -4, -3, 2, 3, 4, 5)


def _reddish(c):
    return c[0] > 0.45 and c[0] > c[1] * 1.45 and c[0] > c[2] * 1.3


def face(path):
    vox = [v for v in json.load(open(path))['voxels'] if v[3] == 'head' and not (len(v) > 8 and v[8] & 64)]   # sin lo tapado
    front = {}
    for v in vox:
        k = (v[0], v[1])
        if k not in front or v[2] > front[k][0]: front[k] = (v[2], v[4:7])
    white = lambda x, y: (x, y) in front and sum(abs(a - b) for a, b in zip(front[(x, y)][1], cu.EYE_W)) < 0.05
    rows = [y for y in range(68, 78) if all(white(x, y) for x in (-6, -3, 2, 5))]   # bordes blancos de los dos ojos
    if len(rows) != 2 or rows[1] != rows[0] + 1: return None
    y0 = rows[0]
    eyes = [[x, y, front[(x, y)][0]] for x in EYE_X for y in (y0, y0 + 1)]
    # párpado del color de la piel: la piel tiene textura (cada voxel con su tono) y lo pintado
    # (cejas, pestañas, gafas, mejillas) es de un color plano, que se repite
    near = [tuple(front[(x, y)][1]) for x in range(-8, 8) for y in range(y0 - 3, y0 + 4)
            if (x, y) in front and [x, y, front[(x, y)][0]] not in eyes]
    skin = [c for c in near if near.count(c) <= 2 and sum(c) / 3 > 0.45]
    lid = [round(sum(c[i] for c in skin) / len(skin), 3) for i in range(3)]
    # boca de la mueca (filas m y m + 1, dientes arriba): tapa los labios, la fila de arriba de los
    # labios es la de los dientes; los labios son rojizos y de color plano. Sin labios a la vista
    # (bigote, barba), seis filas por debajo de los ojos.
    low = [tuple(front[(x, y)][1]) for x in range(-8, 8) for y in range(y0 - 9, y0) if (x, y) in front]
    lips = [y for x in range(-2, 2) for y in range(y0 - 8, y0 - 2) if (x, y) in front
            and low.count(tuple(front[(x, y)][1])) >= 2 and _reddish(front[(x, y)][1])]
    m = max(lips) - 1 if lips else y0 - 6
    mz = max(front[(x, y)][0] for x in range(-3, 3) for y in (m, m + 1) if (x, y) in front)
    # alrededor de los ojos (columna de fuera y fila de encima): en la mueca se tapan con piel, que
    # las pestañas y la sombra de ojos no se mezclen con los ojos apretados; solo lo pintado, no
    # lo que va en relieve (cejas)
    # lo que no se tapa: lo que va en relieve (cejas) y las gafas pintadas (su color es el del
    # puente, junto a la nariz)
    flat = max(e[2] for e in eyes)
    frame = {tuple(front[(x, y)][1]) for x in (-2, 1) for y in (y0, y0 + 1) if (x, y) in front}
    around = [[x, y, front[(x, y)][0]] for x in (-7, -6, -5, -4, -3, 2, 3, 4, 5, 6) for y in (y0, y0 + 1, y0 + 2)
              if (x, y) in front and [x, y, front[(x, y)][0]] not in eyes and front[(x, y)][0] <= flat
              and tuple(front[(x, y)][1]) not in frame]
    # restos de labio fuera de la boca apretada (la media sonrisa de Malone), también con piel
    around += [[x, y, front[(x, y)][0]] for x in range(-5, 5) for y in range(m - 1, m + 3)
               if (x, y) in front and not (-3 <= x <= 2 and m <= y <= m + 1)
               and low.count(tuple(front[(x, y)][1])) >= 2 and _reddish(front[(x, y)][1])]
    return {'eyes': eyes, 'around': around, 'lid': lid, 'mouth': [m, mz]}   # mz: lo más adelantado (bigote, barba)


out = {}
for tres in sorted(glob.glob('data/characters/*.tres')):
    model = next(l.split('"')[1] for l in open(tres, encoding='utf-8') if l.startswith('model = '))
    for path in [p for p in glob.glob('models/%s*.json' % model) if os.path.basename(p)[len(model):] in ('.json', '_v1.json')]:
        name = os.path.basename(path)[:-5]
        f = face(path)
        print('%-12s %s' % (name, 'ojos en %d-%d, párpado %s' % (f['eyes'][0][1], f['eyes'][1][1], f['lid']) if f else 'sin cara dibujada: no parpadea'))
        if f: out[name] = f
with open('data/faces.json', 'w', encoding='utf-8', newline='\n') as fh:
    fh.write('{\n' + ',\n'.join('  "%s": %s' % (k, json.dumps(v)) for k, v in sorted(out.items())) + '\n}\n')
