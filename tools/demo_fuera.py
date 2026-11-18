"""Lo que no entra en la demo (hito 23.2): solo la parte 1 y los cuatro investigadores de inicio.

Hasta ahora la demo llevaba el juego entero y lo cerraba por la etiqueta `demo` (13.17), así que pesaba
lo mismo. Este script calcula lo que solo usan los niveles de fuera de la parte 1 (partes 2 a 4 y
noches sueltas) y lo apunta en el `exclude_filter` de los perfiles «Windows Demo», «macOS Demo» y
«Linux Demo» de export_presets.cfg:

  - las arenas que no usa ningún nivel de la parte 1 (data/arenas/<arena>.json y sus .bin);
  - los modelos de esas arenas, de los niveles y de sus criaturas, salvo los que también salen en la
    parte 1 o se nombran en el código (scripts/, scenes/) o en otros datos;
  - el vestuario de los personajes que no son de la demo (`vest_<prenda>_<pj>`); su modelo y su
    retrato se quedan, porque la tienda y la selección los enseñan cerrados;
  - la música de esos niveles y sus capas, sus mapas (resources/maps) y los finales de las partes
    2 a 4 (resources/finales).

Lo que falta lo esquiva el juego con `Demo.has_model` y `Demo.has_file` (la Biblioteca, la sala de
trofeos…). La prueba de que no falta nada: `sh tools/probar_demo.sh`.

Uso: python tools/demo_fuera.py            (escribe tools/demo_fuera.txt y export_presets.cfg)
     python tools/demo_fuera.py --ver      (solo lo cuenta)
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE_FILTER = ('tests/*, locale/*.pot, addons/gut/*, resources/weapons/icons/raw/*, resources/items/icons/raw/*, '
               'models/*.json, tools/*, docs/*, builds/*')
DEMO_PRESETS = ('Windows Demo', 'macOS Demo', 'Linux Demo')
OUT = os.path.join(ROOT, 'tools', 'demo_fuera.txt')
# Datos que son índices de todo el contenido (la Biblioteca, los logros…): no cuentan como «la demo
# lo usa», porque el juego ya mira con Demo.has_model si lo que nombran está.
INDEX_DATA = ('data/library/', 'data/challenges.json', 'data/nights.json', 'data/boss_rush.json',
              'data/expeditions.json', 'data/achievements.json', 'data/fishing.json', 'data/trophies.json',
              'data/revelations.json', 'data/night_events.json', 'data/fragments.json', 'data/musica.json',
              'data/bonds.json', 'data/credits.json', 'data/trailer.json', 'data/anim_sets.json',
              'data/part_finales.json', 'data/achievements/', 'data/campaign.json', 'data/relato_skies.json', 'data/manual.json')

TOKEN = re.compile(r'[A-Za-z0-9_]+')


def rel(p):
    return os.path.relpath(p, ROOT).replace('\\', '/')


def read(p):
    with open(p, encoding='utf-8', errors='replace') as f:
        return f.read()


def res(path):
    return os.path.join(ROOT, path.replace('res://', ''))


def tres_refs(path, seen):
    """El texto de un .tres y el de los .tres de data/enemies que nombra, sin repetir."""
    if path in seen or not os.path.exists(path):
        return ''
    seen.add(path)
    t = read(path)
    out = [t]
    for p in re.findall(r'path="(res://data/enemies/[^"]+\.tres)"', t):
        out.append(tres_refs(res(p), seen))
    return '\n'.join(out)


def level_info(path):
    t = read(path)
    m = re.search(r'^arena = "([^"]+)"', t, re.M)
    arena = res(m.group(1)) if m else res('res://data/arenas/campamento.json')
    files = set(re.findall(r'"(res://resources/[^"]+)"', t))
    return arena, tres_refs(path, set()), files


def main():
    models = {os.path.basename(p)[:-len('.json.z')] for p in glob.glob(os.path.join(ROOT, 'models', '*.json.z'))}
    models |= {os.path.basename(p)[:-len('.json')] for p in glob.glob(os.path.join(ROOT, 'models', '*.json'))}
    levels = sorted(glob.glob(os.path.join(ROOT, 'data', 'levels', '*.tres')))
    demo_lv = [p for p in levels if os.path.basename(p).startswith('p1_')]
    other_lv = [p for p in levels if p not in demo_lv]

    def gather(lvs):
        arenas, text, files = set(), [], set()
        for p in lvs:
            a, t, f = level_info(p)
            arenas.add(a)
            text.append(t)
            files |= f
        return arenas, '\n'.join(text), files

    demo_arenas, demo_text, demo_files = gather(demo_lv)
    other_arenas, other_text, other_files = gather(other_lv)
    demo_arenas.add(res('res://data/arenas/campamento.json'))          # la que usa la partida si no hay nivel
    out_arenas = sorted(other_arenas - demo_arenas)

    # Lo que la demo nombra: sus niveles y arenas, el código, las escenas y los demás datos
    keep_text = [demo_text] + [read(a) for a in demo_arenas if os.path.exists(a)]
    enemy_tres = set()
    for p in levels:
        tres_refs(p, enemy_tres)
    other_enemies = enemy_tres - set()
    demo_enemies = set()
    for p in demo_lv:
        tres_refs(p, demo_enemies)
    for pat in ('scripts/**/*.gd', 'scripts/**/*.gdshader*', 'scenes/**/*.tscn', 'data/**/*.json', 'data/**/*.tres',
                'resources/**/*.tres', 'project.godot'):
        for p in glob.glob(os.path.join(ROOT, pat), recursive=True):
            r = rel(p)
            if r.startswith('data/levels/') or r.startswith('data/arenas/'):
                continue
            if r.startswith('data/enemies/') and p not in demo_enemies:
                continue
            if r.startswith('data/characters/') or r.startswith('data/outfits/'):
                continue
            if r.startswith(INDEX_DATA):
                continue
            t = read(p)
            if r == 'data/ambient.json':                               # el ambiente, solo el de sus arenas
                amb = json.loads(t)
                names = {os.path.basename(a)[:-len('.json')] for a in demo_arenas}
                t = json.dumps([amb.get('fear'), [v for k, v in amb.get('arenas', {}).items() if k in names]])
            if r.endswith('.gd'):                                      # del código, solo sus cadenas
                t = '\n'.join(re.findall(r'"([^"\n]*)"', t))
            keep_text.append(t)
    keep = set(TOKEN.findall('\n'.join(keep_text)))
    # Los personajes: los de la demo (precio 0, sin secreto) y el modelo de todos
    demo_chars, other_chars = set(), set()
    for p in glob.glob(os.path.join(ROOT, 'data', 'characters', '*.tres')):
        t = read(p)
        price = re.search(r'^price = (\d+)', t, re.M)
        secret = re.search(r'^secret = "([^"]*)"', t, re.M)
        cid = os.path.basename(p)[:-5]
        names = set(re.findall(r'^(?:model|alt_model) = "([^"]+)"', t, re.M)) | {cid}
        keep |= names                                                   # modelo y cuerpo, para la tienda
        keep |= set(TOKEN.findall(t))
        if (price is None or price.group(1) == '0') and (secret is None or secret.group(1) == ''):
            demo_chars |= names
        else:
            other_chars |= names

    other_tokens = set(TOKEN.findall(other_text + '\n'.join(read(a) for a in out_arenas if os.path.exists(a))))
    out_models = {m for m in models if m in other_tokens and m not in keep}
    for m in models:                                                    # vestuario de los demás
        g = re.match(r'^vest_.+_([a-z]+)$', m)
        if g and g.group(1) in other_chars and g.group(1) not in demo_chars:
            out_models.add(m)

    # Música, capas, mapas y finales
    capas = json.loads(read(os.path.join(ROOT, 'data', 'musica.json'))).get('capas', {})
    code = '\n'.join(read(p) for pat in ('scripts/**/*.gd', 'scenes/**/*.tscn')
                     for p in glob.glob(os.path.join(ROOT, pat), recursive=True))
    out_files = {f for f in other_files - demo_files if f not in code}
    demo_layers = {v for k, c in capas.items() if k in demo_files or k in code for v in c.values() if isinstance(v, str)}
    for f in sorted(out_files):
        for v in capas.get(f, {}).values():
            if isinstance(v, str) and v.startswith('res://') and v not in demo_layers:
                out_files.add(v)
    for p in other_lv:
        lid = os.path.basename(p)[:-5]
        out_files.add('res://resources/maps/%s.png' % lid)
    for n in (2, 3, 4):
        out_files.add('res://resources/finales/p%d.jpg' % n)
    out_files = {f for f in out_files if os.path.exists(res(f))}

    paths = []
    for a in out_arenas:
        base = os.path.basename(a)[:-len('.json')]
        paths.append(rel(a))
        paths += [rel(b) for b in glob.glob(os.path.join(ROOT, 'data', 'arenas', base + '_*.bin'))]
    paths += ['models/%s.json.z' % m for m in sorted(out_models)]
    paths += sorted(f.replace('res://', '') for f in out_files)

    size = sum(os.path.getsize(os.path.join(ROOT, p)) for p in paths if os.path.exists(os.path.join(ROOT, p)))
    vest = sum(1 for m in out_models if m.startswith('vest_'))
    print('demo: fuera %d arenas, %d modelos (%d de vestuario) y %d archivos de música e imágenes: %.0f MB' % (
        len(out_arenas), len(out_models), vest, len(out_files), size / 2**20))
    if '--ver' in sys.argv:
        for p in paths:
            if not p.startswith('models/vest_'):
                print('  ', p)
        return
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(paths) + '\n')
    cfg_path = os.path.join(ROOT, 'export_presets.cfg')
    cfg = read(cfg_path)
    filt = BASE_FILTER + ', ' + ', '.join(paths)
    blocks = re.split(r'(?m)^(?=\[preset\.\d+\]$)', cfg)
    done = 0
    for i, b in enumerate(blocks):
        m = re.search(r'^name="([^"]+)"', b, re.M)
        if m and m.group(1) in DEMO_PRESETS:
            blocks[i], k = re.subn(r'^exclude_filter=".*"$', lambda _: 'exclude_filter="%s"' % filt, b, count=1, flags=re.M)
            done += k
    assert done == len(DEMO_PRESETS), 'no están los tres perfiles de la demo'
    with open(cfg_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(''.join(blocks))
    print('export_presets.cfg: filtro de los %d perfiles de la demo al día' % done)


if __name__ == '__main__':
    main()
