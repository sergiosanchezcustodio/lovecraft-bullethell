"""Costados de los humanos y de TODAS las prendas en TODOS los cuerpos (28-10-2026).

La misma comprobación que tests/test_model_sides.gd (que, por tiempo, solo mira las prendas con
manga en tres cuerpos), pero sobre los 13 personajes, vecinos y cultistas y las 26 prendas en los
13 personajes: el tronco visto de lado, a la altura de los brazos, no tiene tramos de 3 o más
voxels hundidos 2 o más respecto a lo que tiene delante y detrás (lo que pasaba cuando la manga
borraba el costado; ver voxlib.Model.keep_under). Lo ejecuta tools/exportar.sh antes de cada build.
Uso: python tools/revisar_costados.py   (sale con 1 si encuentra alguno)
"""
import glob, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ARMS = ('arm_l', 'arm_r', 'fore_l', 'fore_r')
CHARACTERS = ['dyer', 'olmstead', 'legrasse', 'johansen', 'peaslee', 'varga', 'whipple', 'blake',
              'iwanicki', 'elwood', 'malone', 'armitage', 'west']
# Barnabas no (bajos deshilachados a propósito), ni las criaturas (aletas y crestas): como en el test.
PEOPLE = ['anciano', 'cultista', 'cultista_alert', 'sacerdote_culto', 'innsmouth_g0', 'innsmouth_g1',
          'innsmouth_g2', 'innsmouth_g3', 'habitante_pescador', 'habitante_mujer', 'habitante_viejo', 'acolito',
          'diacono', 'hibrido_h', 'hibrido_m', 'sacerdote', 'sumo_sacerdote']


def side_holes(data):
    arm_rows = {v[1] for v in data['voxels'] if v[3] in ARMS}
    found = []
    for sgn in (-1, 1):
        rows = {}                                   # y -> {z: x más afuera}
        for v in data['voxels']:
            if v[3] != 'torso' or v[1] not in arm_rows or v[0] * sgn < 0: continue
            r = rows.setdefault(v[1], {})
            r[v[2]] = max(r.get(v[2], -999), v[0] * sgn)
        for y, r in rows.items():
            zs = sorted(r)
            front, best = [], -999
            for z in zs:
                front.append(best); best = max(best, r[z])
            best, run = -999, 0
            for i in range(len(zs) - 1, -1, -1):
                z = zs[i]
                deep = front[i] > -999 and best > -999 and min(front[i], best) - r[z] >= 2
                run = run + 1 if deep and (run == 0 or zs[i + 1] == z + 1) else (1 if deep else 0)
                if run == 3: found.append('%s y=%d z=%d' % ('izquierda' if sgn < 0 else 'derecha', y, z))
                best = max(best, r[z])
    return found


def main():
    os.chdir(ROOT)
    models = CHARACTERS + PEOPLE + sorted(os.path.basename(f)[:-5] for f in glob.glob('models/vest_*.json'))
    bad = 0
    for m in models:
        path = 'models/%s.json' % m
        if not os.path.exists(path):
            print('falta', path); bad += 1; continue
        with open(path) as f:
            holes = side_holes(json.load(f))
        if holes:
            bad += 1
            print('%s: costado hueco en %d filas (%s...)' % (m, len(holes), ', '.join(holes[:3])))
    print('Costados: %d modelos mirados, %s' % (len(models), 'todos enteros' if not bad else '%d con huecos' % bad))
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
