"""Tablas del README sacadas de los datos del juego (hito 23.3), en español y en inglés.

  python tools/tablas_readme.py           # rehace las tablas de README.md y README.en.md
  python tools/tablas_readme.py --ver     # solo las enseña

Cada tabla va entre dos marcas en los README: <!-- tabla:personajes --> … <!-- /tabla -->
(personajes, companeros, armas, objetos y cifras). Lo de fuera de las marcas se escribe a mano.
El inglés sale de locale/en.po (la misma tabla que usa el juego).
"""
import glob
import os
import re
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
CAT = {'es': ['Física', 'De fuego', 'Mágica'], 'en': ['Physical', 'Firearm', 'Magic']}
HEAD = {
    'personajes': {'es': '| Personaje | Arma inicial | Rasgo | Esquive | Relato de origen |',
                   'en': '| Character | Starting weapon | Trait | Dodge | Story |'},
    'companeros': {'es': '| Compañero | Qué hace |', 'en': '| Companion | What it does |'},
    'armas': {'es': '| Arma | Tipo | Cómo funciona | Evoluciones (con) |',
              'en': '| Weapon | Type | How it works | Evolutions (with) |'},
    'objetos': {'es': '| Objeto | Efecto |', 'en': '| Item | Effect |'},
}
SECRET = {'es': ' *(secreto)*', 'en': ' *(secret)*'}
START = {'es': ' *(de inicio)*', 'en': ' *(starter)*'}


def po_table():
    """msgid -> msgstr de locale/en.po (con las cadenas de varias líneas)."""
    out, cur, key, mode = {}, None, None, None
    def unq(s):
        return s[1:-1].replace('\\"', '"').replace('\\n', '\n').replace('\\\\', '\\')
    with open(os.path.join(ROOT, 'locale', 'en.po'), encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n')
            if line.startswith('msgid '):
                if key is not None and cur is not None: out[key] = cur
                key, cur, mode = unq(line[6:]), None, 'id'
            elif line.startswith('msgstr '):
                cur, mode = unq(line[7:]), 'str'
            elif line.startswith('"'):
                if mode == 'id': key += unq(line)
                elif mode == 'str': cur += unq(line)
    if key is not None and cur is not None: out[key] = cur
    return out


PO = po_table()


def tr(s, lang):
    if lang == 'es' or not s: return s
    return PO.get(s) or s


def tres(path):
    """Las propiedades sencillas de un .tres (cadenas, números, StringName y booleanos)."""
    d = {}
    with open(path, encoding='utf-8') as f:
        for line in f:
            m = re.match(r'^(\w+) = (.*)$', line.rstrip('\n'))
            if not m: continue
            k, v = m.groups()
            if v.startswith('&"') or v.startswith('"'):
                v = v[v.index('"') + 1:v.rindex('"')].replace('\\"', '"')
            d[k] = v
    return d


def load(folder):
    return {os.path.basename(p)[:-5]: tres(p) for p in glob.glob(os.path.join(ROOT, 'data', folder, '*.tres'))}


def cell(s):
    return s.replace('|', '\\|').replace('\n', ' ').strip()


def clean(s):
    s = s.strip()
    return s[:-1] if s.endswith('.') else s


def table_characters(lang):
    chars = load('characters')
    weapons = load('weapons')
    dodges = load('dodges')
    rows = []
    for c in sorted(chars.values(), key=lambda c: (int(c.get('order', 99)), c.get('display_name', ''))):
        w = re.findall(r'&"(\w+)"', c.get('starting_weapons', ''))
        wname = tr(weapons[w[0]]['display_name'], lang) if w and w[0] in weapons else ''
        dodge = ''
        # el esquive va como recurso externo: se busca su ruta en la cabecera del .tres
        path = os.path.join(ROOT, 'data', 'characters', c['id'] + '.tres')
        head = open(path, encoding='utf-8').read()
        m = re.search(r'path="res://data/dodges/(\w+)\.tres"', head)
        if m and m.group(1) in dodges: dodge = tr(dodges[m.group(1)].get('display_name', ''), lang)
        name = '**%s**, %s' % (tr(c.get('display_name', c['id']), lang), clean(tr(c.get('role', ''), lang)).lower()[:1] + clean(tr(c.get('role', ''), lang))[1:])
        tag = SECRET[lang] if c.get('secret') else (START[lang] if c.get('price', '0') == '0' else '')
        story = tr(c.get('story', ''), lang)
        rows.append('| %s%s | %s | %s | %s | %s |' % (cell(name), tag, cell(wname), cell(clean(tr(c.get('passive_text', ''), lang))),
                                                     cell(dodge), ('*%s*' % cell(story)) if story else ''))
    return rows


def table_pets(lang):
    pets = load('pets')
    rows = []
    for p in sorted(pets.values(), key=lambda p: (int(p.get('price', 0)), tr(p.get('display_name', ''), lang))):
        rows.append('| %s | %s |' % (cell(tr(p.get('display_name', ''), lang)), cell(clean(tr(p.get('description', ''), lang)))))
    return rows


def table_weapons(lang):
    weapons = load('weapons')
    items = load('upgrades')
    base = [w for w in weapons.values() if w.get('evolved') != 'true']
    base.sort(key=lambda w: (int(w.get('category', 1)), tr(w.get('display_name', ''), lang).lower()))
    rows = []
    for w in base:
        evo = [weapons[e]['display_name'] for e in (w.get('evolution'), w.get('evolution_alt')) if e in weapons]
        it = items.get(w.get('evolves_with', ''), {}).get('display_name', '')
        evos = ' / '.join(tr(e, lang) for e in evo)
        rows.append('| %s | %s | %s | %s%s |' % (cell(tr(w.get('display_name', ''), lang)), CAT[lang][int(w.get('category', 1))],
                                                cell(clean(tr(w.get('description', ''), lang))), cell(evos),
                                                (' (%s)' % cell(tr(it, lang))) if it else ''))
    return rows


def table_items(lang):
    items = load('upgrades')
    rows = []
    for i in sorted(items.values(), key=lambda i: tr(i.get('display_name', ''), lang).lower()):
        rows.append('| %s | %s |' % (cell(tr(i.get('display_name', ''), lang)), cell(clean(tr(i.get('description', ''), lang)))))
    return rows


def _level(path):
    t = open(path, encoding='utf-8').read()
    ext = dict((i, p) for p, i in re.findall(r'path="([^"]+)" id="(\w+)"', t))
    d = dict(re.findall(r'^(\w+) = (.*)$', t, re.M))
    def enemies(key):
        out = []
        for i in re.findall(r'ExtResource\("(\w+)"\)', d.get(key, '')):
            p = ext.get(i, '')
            if '/enemies/' in p:
                n = tres(p.replace('res://', ROOT + '/')).get('display_name', '')
                if n and n not in out: out.append(n)
        return out
    return d, enemies


def table_levels(prefix, lang):
    head = {'es': '| Nivel | Criaturas | A mitad del nivel | Evento final |',
            'en': '| Level | Creatures | Mid-level | Final event |'}[lang]
    rows = [head, '|---|---|---|---|']
    for path in sorted(glob.glob(os.path.join(ROOT, 'data', 'levels', prefix + '*.tres'))):
        d, enemies = _level(path)
        name = tr(d.get('display_name', '').strip('"'), lang)
        num = d.get('number', '')
        fin = [tr(n, lang) for n in enemies('final_enemy') + enemies('final_next')]
        boss = 'boss_music' in d
        fin_txt = ' → '.join(fin)
        if not fin and 'final_survive' in d:
            secs = int(float(d['final_survive']))
            fin_txt = ('Resistir %d s a la horda' if lang == 'es' else 'Hold out %d s against the horde') % secs
        if boss: fin_txt = '**%s: %s**' % ('Jefe' if lang == 'es' else 'Boss', fin_txt)
        rows.append('| %s%s | %s | %s | %s |' % (('%s. ' % num) if prefix.startswith('p') else '', cell(name),
                                              ', '.join(tr(n, lang) for n in enemies('pool')),
                                              ', '.join(tr(n, lang) for n in enemies('mid_enemies')) or '—', fin_txt))
    return '\n'.join(rows)


def bestiary(prefix, lang):
    """Las criaturas de una parte (o de las noches), sin repetir las de las partes anteriores."""
    seen_before = set()
    order = ['p1_', 'p2_', 'p3_', 'p4_', 'noche_']
    for p in order[:order.index(prefix)]:
        for path in glob.glob(os.path.join(ROOT, 'data', 'levels', p + '*.tres')):
            _, enemies = _level(path)
            for k in ('pool', 'mid_enemies', 'final_enemy', 'final_next', 'galley_enemy'):
                seen_before.update(enemies(k))
    names = []
    for path in sorted(glob.glob(os.path.join(ROOT, 'data', 'levels', prefix + '*.tres'))):
        _, enemies = _level(path)
        for k in ('pool', 'mid_enemies', 'galley_enemy', 'final_enemy', 'final_next'):
            for n in enemies(k):
                if n not in names and n not in seen_before: names.append(n)
    label = {'p1_': ('Parte 1', 'Part 1'), 'p2_': ('Parte 2', 'Part 2'), 'p3_': ('Parte 3', 'Part 3'),
             'p4_': ('Parte 4', 'Part 4'), 'noche_': ('Noches sueltas', 'Standalone nights')}[prefix][lang == 'en']
    names = [tr(n, lang) for n in names]
    return '**%s:** %s.' % (label, ' · '.join(names))


def counts():
    weapons = load('weapons')
    base = sum(1 for w in weapons.values() if w.get('evolved') != 'true')
    return {'armas': base, 'evoluciones': len(weapons) - base, 'objetos': len(load('upgrades')),
            'personajes': len(load('characters')), 'companeros': len(load('pets')),
            'criaturas': len(load('enemies')), 'niveles': sum(1 for k in load('levels') if k.startswith('p')),
            'noches': sum(1 for k in load('levels') if k.startswith('noche_'))}


def tables(lang):
    out = {}
    for name, fn in (('personajes', table_characters), ('companeros', table_pets), ('armas', table_weapons), ('objetos', table_items)):
        head = HEAD[name][lang]
        sep = '|' + '|'.join('---' for _ in range(head.count('|') - 1)) + '|'
        out[name] = '\n'.join([head, sep] + fn(lang))
    for k in ('p1', 'p2', 'p3', 'p4'):
        out['parte' + k[1]] = table_levels(k + '_', lang)
    out['noches'] = table_levels('noche_', lang)
    for k in ('p1_', 'p2_', 'p3_', 'p4_', 'noche_'):
        out['bestiario_' + k.strip('_')] = bestiary(k, lang)
    return out


def apply(path, lang):
    s = open(path, encoding='utf-8').read()
    t = tables(lang)
    n = 0
    for name, body in t.items():
        pat = re.compile(r'(<!-- tabla:%s -->\n)(.*?)(<!-- /tabla -->)' % name, re.S)
        s, k = pat.subn(lambda m: m.group(1) + body + '\n' + m.group(3), s)
        n += k
    open(path, 'w', encoding='utf-8', newline='\n').write(s)
    print('%s: %d tablas' % (os.path.basename(path), n))


if __name__ == '__main__':
    print(counts())
    if '--ver' in sys.argv:
        for lang in ('es', 'en'):
            for k, v in tables(lang).items(): print('\n## %s (%s)\n%s' % (k, lang, v))
    else:
        apply(os.path.join(ROOT, 'README.md'), 'es')
        apply(os.path.join(ROOT, 'README.en.md'), 'en')
