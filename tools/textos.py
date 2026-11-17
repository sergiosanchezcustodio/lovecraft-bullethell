"""Textos traducibles (hito 22.4).

La clave de cada texto es el texto en español tal cual (gettext): `locale/textos.pot` los recoge
todos y `locale/en.po` guarda su traducción. En el juego:
  - los JSON de `data/` pasan por `L.json()`, que traduce sus textos al cargarlos;
  - las propiedades de texto de los `.tres` (TRES_PROPS) se traducen al leerlas (`get` en su clase);
  - en el código, las frases van con `L.t("…")`; las palabras sueltas que van tal cual a un
    `Label` o un `Button` las traduce Godot solo (auto_translate).

Uso (desde la raíz):
  python tools/textos.py extraer          # rehace textos.pot y añade a en.po lo nuevo (sin traducir)
  python tools/textos.py estado           # cuántos faltan, por origen
  python tools/textos.py faltan [N] [--origen data/library] [--json]   # los que faltan
  python tools/textos.py poner lote.json  # {"texto en español": "English text", …} a en.po
  python tools/textos.py envolver [--aplicar] [rutas…]   # pone L.t() a las frases del código
  python tools/textos.py comprobar        # para la prueba: textos.pot al día y marcadores iguales
  python tools/textos.py registro [fichero]   # lo que apuntó el juego con i18n_log=true: los textos
                                          # montados en el código que no están en la tabla

La regla de qué es texto (`human`) y las claves que no lo son (`SKIP_KEYS`) tienen que ser las
mismas que las de `scripts/core/l.gd`.
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POT = os.path.join(ROOT, 'locale', 'textos.pot')
PO = os.path.join(ROOT, 'locale', 'en.po')

# ---------------------------------------------------------------- qué es texto
# Igual que L.human(): letras minúsculas seguidas y un espacio, una tilde o una mayúscula inicial.
_LOWER2 = re.compile(r'[a-záéíóúñü]{2}')
_ACCENT = re.compile(r'[áéíóúñ¿¡ÁÉÍÓÚÑ]')
_WORD = re.compile(r'^[A-ZÁÉÍÓÚÑ][a-záéíóúñü]+[.!?…]?$')
_TECH = re.compile(r'(://|\.(json|png|jpg|tres|tscn|res|ogg|wav|mp3|gd|gdshader|ogv|svg|cfg|txt|po)\b|^[a-z0-9_]+$)')

def human(s):
    if len(s) < 2 or not _LOWER2.search(s): return False
    if _TECH.search(s): return False
    if ' ' in s or '\n' in s or _ACCENT.search(s): return True
    return bool(_WORD.match(s))

# claves de los JSON cuyos valores nunca son texto que se ve
SKIP_KEYS = {'id', 'model', 'icon', 'icon_model', 'path', 'image', 'sfx', 'sound', 'anim', 'bus', 'music',
             'scene', 'arena', 'level', 'levels', 'next', 'weapon_id', 'enemy', 'enemies', 'tags', 'tag',
             'texture', 'shader', 'file', 'video', 'clip', 'color', 'kind', 'type', 'mode', 'key', 'action',
             'autor', 'author'}

# ---------------------------------------------------------------- fuentes
DATA_SKIP_FILES = {'cloud.json', 'quality.json', 'sfx.json', 'musica.json', 'anim_sets.json'}

def _dict_list(v):
    """Una lista de diccionarios (los niveles de campaign.json) sí se recorre aunque su clave se salte."""
    return isinstance(v, list) and bool(v) and all(isinstance(x, dict) for x in v)

def json_texts(obj, where, out, key=''):
    if isinstance(obj, str):
        if human(obj): out.setdefault(obj, []).append(where)
    elif isinstance(obj, dict):
        for k, v in obj.items():
            if k.startswith('_') or (k in SKIP_KEYS and not _dict_list(v)): continue
            json_texts(v, where, out, k)
    elif isinstance(obj, list):
        for v in obj: json_texts(v, where, out, key)

# Propiedades String de los .tres que se ven (las demás son ids, rutas, animaciones…).
# Las que llevan `get: return L.t(…)` en su clase (scripts/*/…_data.gd).
TRES_PROPS = {'display_name', 'description', 'story', 'passive_text', 'role', 'final_text', 'final_name', 'final_next_text',
              'level_text', 'mid_texts'}   # estas dos, con L.t donde se leen
_TRES_STR = re.compile(r'^(\w+) = "((?:[^"\\]|\\.)*)"', re.M | re.S)
_TRES_ARR = re.compile(r'^(\w+) = (?:PackedStringArray|Array\[String\])\((.*?)\)$', re.M | re.S)
_TRES_ITEM = re.compile(r'"((?:[^"\\]|\\.)*)"', re.S)

def unescape_godot(s):
    out = []; i = 0
    while i < len(s):
        c = s[i]
        if c == '\\' and i + 1 < len(s):
            n = s[i + 1]
            out.append({'n': '\n', 't': '\t', '"': '"', '\\': '\\', "'": "'"}.get(n, '\\' + n)); i += 2
        else:
            out.append(c); i += 1
    return ''.join(out)

def tres_texts(path, rel, out):
    t = open(path, encoding='utf-8').read()
    for k, v in _TRES_STR.findall(t):
        v = unescape_godot(v)
        if k in TRES_PROPS and human(v): out.setdefault(v, []).append(rel)
    for k, body in _TRES_ARR.findall(t):
        if k not in TRES_PROPS: continue
        for v in _TRES_ITEM.findall(body):
            v = unescape_godot(v)
            if human(v): out.setdefault(v, []).append(rel)

# ---------------------------------------------------------------- código
# Archivos sin textos que se ven (registros, medidas, herramientas de prueba).
CODE_SKIP = {'scripts/core/bench.gd', 'scripts/core/spike_log.gd', 'scripts/core/prof.gd', 'scripts/core/launch_args.gd',
             'scripts/core/shot_taker.gd', 'scripts/core/demo.gd', 'scripts/core/crash_report.gd', 'scripts/core/l.gd',
             'scripts/core/debug_options.gd', 'scripts/ui/ui_overlap_check.gd', 'scripts/save/review.gd',
             'scripts/menus/review_menu.gd', 'scripts/ui/debug_menu.gd'}
# Líneas que no se tocan: registros, comparaciones, claves y nombres de nodos.
LINE_SKIP = re.compile(r'\b(print|printerr|print_rich|push_error|push_warning|assert|prints|printt|OS\.execute|'
                       r'get_node|get_node_or_null|has_node|find_child|add_to_group|is_in_group|'
                       r'emit_signal|set_meta|get_meta|Prof\.|SpikeLog|_log\(|log_line|DebugOptions)\b|Accept: |User-Agent|Authorization|'
                       r'^\s*(const|enum|match|signal|class_name|extends)\b|^\s*@\w+|Content-Type')
# Una cadena de GDScript: normal, con comillas simples o triple; las &"…" y ^"…" no son texto.
_GD_TOKEN = re.compile(r'("""(?:.|\n)*?"""|"(?:[^"\\]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'|#[^\n]*)')

def gd_strings(src):
    """[(posición, final, texto, prefijo)] de las cadenas fuera de comentarios."""
    out = []
    for m in _GD_TOKEN.finditer(src):
        tok = m.group(0)
        if tok.startswith('#'): continue
        pre = src[m.start() - 1] if m.start() > 0 else ''
        body = tok[3:-3] if tok.startswith('"""') else tok[1:-1]
        out.append((m.start(), m.end(), unescape_godot(body), pre))
    return out

def line_of(src, pos):
    a = src.rfind('\n', 0, pos) + 1
    b = src.find('\n', pos)
    return src[a:b if b >= 0 else len(src)]

def code_texts(path, rel, out):
    src = open(path, encoding='utf-8').read()
    # `# i18n: sí` en la primera línea de una constante: todos sus valores son texto, también
    # las palabras sueltas en minúscula ("balas", "enero") que human() no reconoce.
    marked = [(x, y) for x, y in _const_spans(src) if 'i18n: sí' in line_of(src, x)]
    for a, b, s, pre in gd_strings(src):
        if pre in '&^': continue
        forced = any(x <= a < y for x, y in marked) and re.search("[a-záéíóúñü]", s) and not re.search(r'://|\.[a-z]{2,8}$', s) \
            and not re.match(r'\s*:', src[b:b + 3])
        if not forced and not human(s): continue
        line = line_of(src, a)
        if re.search(r'\b(print|printerr|print_rich|push_error|push_warning|assert)\s*\(', line): continue
        if 'i18n: no' in line: continue
        out.setdefault(s, []).append(rel)

def tscn_texts(path, rel, out):
    t = open(path, encoding='utf-8').read()
    for k, v in _TRES_STR.findall(t):
        v = unescape_godot(v)
        if k in ('text', 'tooltip_text', 'placeholder_text', 'title') and human(v): out.setdefault(v, []).append(rel)

def collect():
    out = {}
    for root, ds, fs in os.walk(os.path.join(ROOT, 'data')):
        for f in sorted(fs):
            p = os.path.join(root, f); rel = os.path.relpath(p, ROOT).replace('\\', '/')
            if f.endswith('.json') and f not in DATA_SKIP_FILES:
                try: json_texts(json.load(open(p, encoding='utf-8')), rel, out)
                except ValueError as e: print('JSON roto:', rel, e)
            elif f.endswith('.tres'):
                tres_texts(p, rel, out)
    for top in ('scripts', 'scenes'):
        for root, ds, fs in os.walk(os.path.join(ROOT, top)):
            for f in sorted(fs):
                p = os.path.join(root, f); rel = os.path.relpath(p, ROOT).replace('\\', '/')
                if f.endswith('.gd') and rel not in CODE_SKIP: code_texts(p, rel, out)
                elif f.endswith('.tscn'): tscn_texts(p, rel, out)
    return out

# ---------------------------------------------------------------- PO
def po_quote(s):
    s = s.replace('\\', '\\\\').replace('"', '\\"').replace('\t', '\\t')
    if '\n' not in s: return '"%s"' % s
    parts = s.split('\n')
    lines = ['""'] + ['"%s\\n"' % p for p in parts[:-1]] + (['"%s"' % parts[-1]] if parts[-1] else [])
    return '\n'.join(lines)

def po_unquote(lines):
    s = ''.join(json.loads(l) if False else _unq(l) for l in lines)
    return s

def _unq(l):
    l = l.strip()
    assert l.startswith('"') and l.endswith('"'), l
    body = l[1:-1]; out = []; i = 0
    while i < len(body):
        c = body[i]
        if c == '\\' and i + 1 < len(body):
            out.append({'n': '\n', 't': '\t', '"': '"', '\\': '\\'}.get(body[i + 1], body[i + 1])); i += 2
        else: out.append(c); i += 1
    return ''.join(out)

def read_po(path):
    """{msgid: msgstr} (sin la cabecera)."""
    d = {}
    if not os.path.exists(path): return d
    cur = None; buf = []; mid = None
    def flush():
        nonlocal mid
        if cur == 'msgstr' and mid is not None and mid != '': d[mid] = po_unquote(buf)
    for raw in open(path, encoding='utf-8'):
        line = raw.rstrip('\n')
        if line.startswith('#') or not line.strip():
            continue
        if line.startswith('msgid '):
            flush(); cur = 'msgid'; buf = [line[6:]]
        elif line.startswith('msgstr '):
            mid = po_unquote(buf); cur = 'msgstr'; buf = [line[7:]]
        elif line.startswith('"'):
            buf.append(line)
    flush()
    return d

HEADER = 'msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Language: %s\\n"\n'

def write_po(path, entries, lang, refs=None):
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        f.write(HEADER % lang)
        for mid, mstr in entries:
            f.write('\n')
            if refs and mid in refs:
                f.write('#: %s\n' % ' '.join(sorted(set(refs[mid]))[:4]))
            f.write('msgid %s\nmsgstr %s\n' % (po_quote(mid), po_quote(mstr)))

# ---------------------------------------------------------------- marcadores
_PH = re.compile(r'%(?:[-+0#]*\d*(?:\.\d+)?[sdfxXcv%])|\{\w*\}|\[/?\w+[^\]]*\]')

def placeholders(s):
    return sorted(m for m in _PH.findall(s) if m != '%%')

# ---------------------------------------------------------------- órdenes
def cmd_extraer():
    texts = collect()
    order = sorted(texts, key=lambda s: (min(texts[s]), s))
    write_po(POT, [(s, '') for s in order], 'es', texts)
    old = read_po(PO)
    write_po(PO, [(s, old.get(s, '')) for s in order], 'en', texts)
    gone = [s for s in old if s not in texts and old[s]]
    print('textos: %d (%d traducidos, %d sin traducir); ya no se usan: %d' % (
        len(order), sum(1 for s in order if old.get(s)), sum(1 for s in order if not old.get(s)), len(gone)))
    if gone:
        keep = os.path.join(ROOT, 'locale', 'en_sin_uso.json')
        prev = json.load(open(keep, encoding='utf-8')) if os.path.exists(keep) else {}
        prev.update({s: old[s] for s in gone})
        json.dump(prev, open(keep, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        print('  (guardados en locale/en_sin_uso.json por si vuelven)')

def _origin(refs, depth):
    r = min(refs)
    parts = r.split('/')
    return '/'.join(parts[:depth])

def cmd_estado(args):
    texts = collect(); po = read_po(PO)
    by = {}
    for s, refs in texts.items():
        k = _origin(refs, 2)
        a = by.setdefault(k, [0, 0, 0])
        a[0] += 1; a[2] += len(s.split())
        if po.get(s): a[1] += 1
    tot = [0, 0, 0]
    for k in sorted(by):
        a = by[k]; tot = [x + y for x, y in zip(tot, a)]
        print('%-28s %5d textos  %5d traducidos  %6d palabras' % (k, a[0], a[1], a[2]))
    print('%-28s %5d textos  %5d traducidos  %6d palabras' % ('TOTAL', *tot))

def cmd_faltan(args):
    n = int(args[0]) if args and args[0].isdigit() else 50
    origin = args[args.index('--origen') + 1] if '--origen' in args else ''
    texts = collect(); po = read_po(PO)
    miss = [s for s in sorted(texts, key=lambda s: (min(texts[s]), s)) if not po.get(s) and (not origin or any(r.startswith(origin) for r in texts[s]))]
    if '--json' in args:
        print(json.dumps({s: '' for s in miss[:n]}, ensure_ascii=False, indent=1))
    else:
        for s in miss[:n]: print('%s\t%s' % (min(texts[s]), s.replace('\n', '\\n')))
    print('# faltan %d' % len(miss), file=sys.stderr)

def cmd_poner(args):
    lote = json.load(open(args[0], encoding='utf-8'))
    texts = collect(); po = read_po(PO)
    bad = []; unknown = []; n = 0
    # los espacios de no separación (delante de $, %, », ?…) se pierden al copiar: se casan sin
    # ellos y la traducción los recupera delante de los mismos signos
    norm = {s.replace('\xa0', ' ').replace(' ', ' '): s for s in texts}
    for es, en in lote.items():
        if not en: continue
        if es not in texts and es in norm:
            es = norm[es]
            for ch in '$%»?!:;':
                if '\xa0' + ch in es: en = en.replace(' ' + ch, '\xa0' + ch)
        if es not in texts: unknown.append(es); continue
        if placeholders(es) != placeholders(en): bad.append((es, en)); continue
        po[es] = en; n += 1
    order = sorted(texts, key=lambda s: (min(texts[s]), s))
    write_po(PO, [(s, po.get(s, '')) for s in order], 'en', texts)
    print('puestos: %d' % n)
    for es, en in bad: print('MARCADORES DISTINTOS:', repr(es), '->', repr(en))
    for es in unknown[:20]: print('NO EXISTE:', repr(es[:80]))
    if unknown: print('(%d que no existen)' % len(unknown))

def cmd_comprobar():
    texts = collect()
    order = sorted(texts, key=lambda s: (min(texts[s]), s))
    have = list(read_po(POT).keys()) if False else _pot_ids()
    problems = []
    if set(have) != set(order):
        new = [s for s in order if s not in set(have)]
        problems.append('textos.pot no está al día (%d nuevos): python tools/textos.py extraer' % len(new))
        for s in new[:10]: problems.append('  nuevo: %r' % s[:80])
    po = read_po(PO)
    for es, en in po.items():
        if en and placeholders(es) != placeholders(en): problems.append('marcadores distintos: %r' % es[:80])
    for p in problems: print(p)
    print('OK' if not problems else 'MAL')

def _pot_ids():
    ids = []; buf = []; cur = None
    if not os.path.exists(POT): return ids
    for raw in open(POT, encoding='utf-8'):
        line = raw.rstrip('\n')
        if line.startswith('msgid '): cur = 'id'; buf = [line[6:]]
        elif line.startswith('msgstr '):
            s = po_unquote(buf)
            if s: ids.append(s)
            cur = None
        elif line.startswith('"') and cur == 'id': buf.append(line)
    return ids

# ---------------------------------------------------------------- envolver
def wrappable(s):
    """Frases del código que van con L.t(): con espacio, tilde o marcador, no solo una palabra."""
    return human(s) and (' ' in s or '\n' in s or _ACCENT.search(s) or placeholders(s))

def cmd_envolver(args):
    apply = '--aplicar' in args
    paths = [a for a in args if not a.startswith('--')] or ['scripts']
    files = []
    for p in paths:
        p = os.path.join(ROOT, p)
        if os.path.isfile(p): files.append(p)
        else:
            for root, ds, fs in os.walk(p):
                files += [os.path.join(root, f) for f in fs if f.endswith('.gd')]
    total = 0
    for p in sorted(files):
        rel = os.path.relpath(p, ROOT).replace('\\', '/')
        if rel in CODE_SKIP: continue
        raw = open(p, 'rb').read().decode('utf-8')
        crlf = '\r\n' in raw
        src = raw.replace('\r\n', '\n')
        edits = []
        spans = _const_spans(src)
        for a, b, s, pre in gd_strings(src):
            if pre in '&^' or not wrappable(s): continue
            line = line_of(src, a)
            if LINE_SKIP.search(line) or 'i18n: no' in line: continue
            before = src[max(0, a - 4):a]
            if before.endswith('L.t(') or src[max(0, a - 3):a] == 'tr(': continue
            # parámetros por defecto y claves de diccionario: no
            after = src[b:b + 3]
            if re.match(r'\s*:', after) and not re.match(r'\s*:=', after): continue
            if re.search(r'\bfunc\b', line) and re.search(r'\bfunc\b[^(]*\([^)]*' + re.escape(src[a:b][:20]), line): continue
            if any(x <= a < y for x, y in spans): continue
            # el texto comparado directamente (`x == "…"`, `"…" in lista`) no se traduce
            if re.search(r'(==|!=)\s*$', src[max(0, a - 6):a]) or re.match(r'\s*(==|!=|in\b)', src[b:b + 5]): continue
            edits.append((a, b))
        if not edits: continue
        total += len(edits)
        if apply:
            for a, b in reversed(edits):
                src = src[:a] + 'L.t(' + src[a:b] + ')' + src[b:]
            out = src.replace('\n', '\r\n') if crlf else src
            open(p, 'wb').write(out.encode('utf-8'))
        print('%4d  %s' % (len(edits), rel))
    print('total: %d %s' % (total, '(aplicado)' if apply else '(prueba: --aplicar para cambiarlo)'))

def _const_spans(src):
    """[(inicio, fin)] de las declaraciones `const` y `enum` (pueden ocupar varias líneas): no
    pueden llamar a funciones, así que sus textos no llevan L.t()."""
    spans = []; lines = src.split(chr(10)); pos = [0]
    for l in lines: pos.append(pos[-1] + len(l) + 1)
    i = 0
    while i < len(lines):
        if re.match(r'\s*(static\s+)?const\b|\s*enum\b', lines[i]):
            j = i; depth = 0
            while True:
                code = _GD_TOKEN.sub('""', lines[j])
                depth += sum(code.count(c) for c in '([{') - sum(code.count(c) for c in ')]}')
                if depth <= 0 or j + 1 >= len(lines): break
                j += 1
            spans.append((pos[i], pos[j + 1])); i = j + 1
        else: i += 1
    return spans

def _c_unescape(s):
    out = []; i = 0
    while i < len(s):
        if s[i] == '\\' and i + 1 < len(s):
            out.append({'n': '\n', 't': '\t', '"': '"', "'": "'", '\\': '\\'}.get(s[i + 1], s[i + 1])); i += 2
        else: out.append(s[i]); i += 1
    return ''.join(out)

def cmd_registro(args):
    path = args[0] if args else os.path.join(os.environ.get('APPDATA', ''), 'Godot', 'app_userdata', 'Lovecraft Bullet Hell', 'i18n_faltan.txt')
    texts = collect(); po = read_po(PO)
    seen = [_c_unescape(l.rstrip('\n')) for l in open(path, encoding='utf-8')]
    inside = [s for s in seen if s in texts]
    english = set(po.values())
    outside = [s for s in seen if s not in texts and s not in english]
    print('en la tabla, sin traducir: %d' % sum(1 for s in inside if not po.get(s)))
    print('montados en el código (no están en la tabla): %d' % len(outside))
    for s in outside: print('  ' + s.replace('\n', '\\n')[:160])

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    a = sys.argv[1:] or ['estado']
    {'extraer': lambda: cmd_extraer(), 'estado': lambda: cmd_estado(a[1:]), 'faltan': lambda: cmd_faltan(a[1:]),
     'poner': lambda: cmd_poner(a[1:]), 'comprobar': lambda: cmd_comprobar(),
     'envolver': lambda: cmd_envolver(a[1:]), 'registro': lambda: cmd_registro(a[1:])}[a[0]]()
