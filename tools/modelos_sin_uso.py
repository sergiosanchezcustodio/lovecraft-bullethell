"""Modelos que la build no necesita (hito 23.1): las versiones antiguas que se guardan como
referencia (models/<nombre>_v1.json, _v2…, _mano.json) y los que solo usan las herramientas
para dibujar iconos (TOOLS_ONLY), siempre que nada los nombre en el juego.

Escribe la lista en tools/modelos_fuera.txt, que lee tools/empaquetar_modelos.gd para no meterlos
en la build (siguen en git y en models/). Lo llama tools/exportar.sh antes de empaquetar.

  python tools/modelos_sin_uso.py            # escribe la lista y dice cuánto se ahorra
  python tools/modelos_sin_uso.py --todos    # además, los modelos que no nombra nada y no son
                                             # versiones antiguas (para revisar a mano: muchos se
                                             # cargan con el nombre compuesto, como vest_<prenda>_<pj>)

Solo cuenta como «usado» un nombre que aparece entero en los scripts, los datos, las escenas o
los recursos (no en tools/ ni tests/). Un modelo con nombre de versión antigua que sí se usa
(dyer_v3, pez_mano) se queda en la build.
"""
import glob
import os
import re
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
OUT = os.path.join(ROOT, 'tools', 'modelos_fuera.txt')
OLD = re.compile(r'_(v\d+|mano)$')
# Modelos que solo usan las herramientas (para dibujar iconos) o de tamaños retirados; también
# fuera solo si nada los nombra. Los amb_* (pájaros y murciélagos) se cargan con el nombre
# compuesto, amb_%s: no van aquí.
TOOLS_ONLY = re.compile(r'^(revelacion_.*|icono_funda|vitrina_(4|8|9)x3)$')
SOURCES = ['scripts/**/*.gd', 'scripts/**/*.gdshader', 'data/**/*.json', 'data/**/*.tres', '**/*.tscn',
           'resources/**/*.tres', 'project.godot']


def used_tokens():
    tokens = set()
    for pat in SOURCES:
        for p in glob.glob(os.path.join(ROOT, pat), recursive=True):
            q = p.replace(os.sep, '/')
            if any(s in q for s in ('/tools/', '/tests/', '/addons/', '/shots/', '/builds/')):
                continue
            with open(p, encoding='utf-8', errors='replace') as f:
                tokens.update(re.findall(r'[A-Za-z0-9_]+', f.read()))
    return tokens


def main():
    names = sorted(os.path.basename(p)[:-5] for p in glob.glob(os.path.join(ROOT, 'models', '*.json')))
    tokens = used_tokens()
    out = [n for n in names if (OLD.search(n) or TOOLS_ONLY.match(n)) and n not in tokens]
    size = sum(os.path.getsize(os.path.join(ROOT, 'models', n + '.json')) for n in out)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write('# Modelos que no van en la build (tools/modelos_sin_uso.py; no lo edites a mano)\n')
        for n in out:
            f.write(n + '\n')
    print('%d modelos fuera de la build (%.0f MB en JSON) -> %s' % (len(out), size / 2**20, os.path.relpath(OUT, ROOT)))
    if '--todos' in sys.argv:
        rest = [n for n in names if n not in tokens and n not in out and not n.startswith('vest_')]
        print('sin nombrar y sin nombre de versión antigua (revisar a mano):', ', '.join(rest))


if __name__ == '__main__':
    main()
