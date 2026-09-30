"""Iconos de los objetos con Replicate: los de la tienda (potenciadores y mejoras permanentes)
y los objetos de la partida (pasivas de la subida de nivel). Mismo proceso y mismo estilo voxel
3D que los de las armas (tools/generar_iconos_armas.py, del que se usan las funciones).

  python tools/generar_iconos_objetos.py vitalidad brujula      # solo esos
  python tools/generar_iconos_objetos.py --todas                # los que aún no tienen icono
  python tools/generar_iconos_objetos.py --todas --rehacer      # todos otra vez

Salida: resources/items/icons/<id>.png y, en bruto, resources/items/icons/raw/<id>.png.
Cuesta dinero (~0,045 $ por imagen): se avisa del total antes de empezar.
"""
import os, sys, urllib.error
sys.path.insert(0, os.path.dirname(__file__))
import generar_iconos_armas as g

OUT = os.path.join(g.ROOT, 'resources', 'items', 'icons')
RAW = os.path.join(OUT, 'raw')

# id del icono -> qué es (en inglés). Años 20, mitos de Lovecraft. Ninguno repite idea con otro.
ITEMS = {
    # tienda: potenciadores
    'vitalidad': "a red anatomical human heart inside a glass bell jar on a brass stand, softly glowing red",
    'temple': "a silver Elder Sign amulet, a five-pointed star with an eye in the center, on a thin chain, softly glowing violet",
    'punteria': "a brass rifle telescopic sight with glass lenses at both ends and mounting rings",
    'agilidad': "an antique brass pocket stopwatch with the lid open and a winding crown",
    'codicia': "a small leather drawstring money purse with shiny gold coins spilling out of it",
    # tienda: mejoras
    'quinta_arma': "an empty brown leather gun holster with a brass buckle and stitched edges",
    'quinto_objeto': "a small brown leather explorer's pouch bag with a flap and a brass clasp",
    # partida: objetos de la subida de nivel
    'cordura': "a worn leather field journal notebook, closed with a strap, with a pencil tucked in",
    'iman': "an antique brass field compass with the lid open, a white dial and a glowing needle",
    'reflejos': "a mountaineer's ice axe with a wooden shaft and a coil of climbing rope",
    'velocidad': "a pair of fur-lined polar snow boots with leather straps",
    'vida': "a folded thick reindeer fur coat, brown and cream fur with a leather collar",
}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    redo = '--rehacer' in sys.argv
    ids = list(ITEMS) if '--todas' in sys.argv else args
    if not redo: ids = [i for i in ids if not os.path.exists(os.path.join(OUT, i + '.png')) or i in args]
    unknown = [i for i in ids if i not in ITEMS]
    if unknown: sys.exit('Objetos desconocidos: %s' % ', '.join(unknown))
    if not ids: return print('Nada que hacer.')
    print('%d iconos, unos %.2f $ en total.' % (len(ids), len(ids) * (g.PRICE + 0.005)))
    os.makedirs(RAW, exist_ok=True)
    open(os.path.join(RAW, '.gdignore'), 'a').close()   # Godot no importa las imágenes en bruto
    bg_version = g.api('GET', '/models/%s' % g.BG_MODEL)['latest_version']['id']
    for i in ids:
        try:
            out = g.run(g.MODEL, {'prompt': '%s. %s' % (ITEMS[i], g.STYLE), 'aspect_ratio': '1:1',
                                  'output_format': 'png', 'safety_tolerance': 2})
            url = out if isinstance(out, str) else out[0]
            raw_path = os.path.join(RAW, i + '.png')
            open(raw_path, 'wb').write(g.download(url))
            cut = g.run(g.BG_MODEL, {'image': g.data_uri(raw_path)}, version=bg_version)
            g.finish(g.download(cut if isinstance(cut, str) else cut[0]), os.path.join(OUT, i + '.png'))
            print('ok', i)
        except (urllib.error.HTTPError, RuntimeError) as e:
            detail = e.read().decode()[:300] if isinstance(e, urllib.error.HTTPError) else str(e)
            print('FALLO', i, detail)


if __name__ == '__main__': main()
