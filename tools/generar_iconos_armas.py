"""Iconos de las armas con Replicate (imágenes de ejemplo para la selección, la ficha y el HUD).

Para cada arma: una imagen con FLUX 1.1 Pro en el estilo de los iconos de la ficha (objeto
único en voxel 3D brillante, de tres cuartos, sobre fondo liso), después se le quita el fondo con un modelo de Replicate
y se recorta y centra en 256 × 256 con transparencia.

  python tools/generar_iconos_armas.py webly bumeran signo     # solo esas
  python tools/generar_iconos_armas.py --todas                  # las que aún no tienen icono
  python tools/generar_iconos_armas.py --todas --rehacer        # todas otra vez

Salida: resources/weapons/icons/<id>.png (la que usa el juego) y, en bruto,
resources/weapons/icons/raw/<id>.png (fuera de git y de Godot).
El token sale de REPLICATE_API_TOKEN (entorno) o del .env de la raíz, que no se versiona.
Cuesta dinero (~0,04 $ por imagen más el recorte): se avisa del total antes de empezar.
"""
import base64, io, json, os, sys, time, urllib.request, urllib.error
from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'resources', 'weapons', 'icons')
RAW = os.path.join(OUT, 'raw')
STYLE_REF = os.path.join(ROOT, 'resources', 'PantallasMenus', 'iconos', 'ficha_fuego.png')
MODEL = 'black-forest-labs/flux-1.1-pro'
BG_MODEL = '851-labs/background-remover'
PRICE = 0.04
# Cloudflare (delante de la API) rechaza el User-Agent por defecto de urllib con un 403
# "error code: 1010"; con uno propio pasa.
UA = 'lovecraft-bullethell-tools/1.0 (+python urllib)'

# Sin imagen de referencia: con el icono del revólver como `image_prompt`, el modelo copiaba
# el revólver en todas las armas e ignoraba el texto. El estilo va solo en el texto.
STYLE = ("high quality 3D voxel art, MagicaVoxel style render, the object is built entirely from "
         "small cubic voxels with a clearly visible cube grid on every surface, like a detailed voxel "
         "sculpture, blocky with stepped jagged edges made of cubes and no smooth curves, like a high-resolution "
         "Minecraft-style item, even metal and wood parts are made of cubes, isometric three-quarter view, soft global illumination, ambient occlusion between "
         "the cubes, subtle soft shadow, rich but slightly muted colors, single object centered with margin, "
         "plain flat dark grey background, game inventory icon, no text, no letters, no hands, no people")

# Qué es cada arma (en inglés: el modelo lo entiende mejor). 1920s, mitos de Lovecraft.
WEAPONS = {
    'webly': "a 1920s British Webley top-break service revolver, dark blued steel, brown wooden grip",
    'granada': "a WWI German stick grenade (Stielhandgranate): a big olive green metal cylinder head, as wide as a tin can, on top of a short wooden handle, like a potato masher",
    'corredera': "a 1920s pump-action shotgun, dark steel barrel, wooden stock and pump",
    'palanca': "a lever-action hunting rifle, brass receiver, polished walnut stock",
    'mauser': "a Mauser C96 'broomhandle' pistol, dark steel with a round wooden grip",
    'thompson': "a Thompson M1928 'Tommy gun' submachine gun with a big round drum magazine under the gun, a vertical front grip, finned barrel and wooden stock, 1920s gangster weapon",
    'flammenwerfer': "a WWI portable flamethrower nozzle with a small blue pilot flame and a fuel hose",
    'molotov': "a Molotov cocktail: a tall green glass wine bottle with a long neck, filled with liquid, a cloth rag stuffed in the neck with a flame burning on it",
    'arpon': "a whaling harpoon with a barbed iron head and a coiled rope around the wooden shaft",
    'bengalas': "a brass flare pistol with a wide barrel and a red glowing flare cartridge",
    'lanzaquimicos': "a glass chemistry flask full of bubbling bright green acid with a cork stopper",
    'fuegos': "a small brass firework cannon on a wooden base with colorful rocket tips",
    'machete': "a jungle machete with a wide worn steel blade and a leather-wrapped handle",
    'bisturis': "three surgical scalpels fanned out, shiny steel blades",
    'necronomicon': "the Necronomicon, an ancient leather grimoire with loose glowing pages and eldritch sigils",
    'trapezoedro': "the Shining Trapezohedron, a black crystal polyhedron with red glowing streaks, in a metal box",
    'formula': "an unrolled parchment scroll with a golden glowing banishing incantation and a holy seal",
    'signo': "the Elder Sign carved in stone, a star with a flaming eye in the center, glowing violet",
    'resonador': "Tillinghast's resonator, a 1920s electrical machine with glass vacuum tubes glowing teal",
    'farolero': "a gnarled wooden lantern staff with small floating green will-o'-the-wisp flames",
    'lente': "a large round magnifying glass with an ornate brass frame and handle, its round glass lens glowing pale blue with ether light",
    'polvo': "a small leather pouch spilling golden magical powder (the powder of Ibn-Ghazi)",
    'migo': "a Mi-Go alien orb, pink crystal sphere with a pulsing core in a fungal organic casing",
    'yith': "a Great Race of Yith lightning gun, strange cone-shaped alien device with teal energy",
    'daga': "a ritual dagger with a wavy blade, bone handle and a violet gem, dripping purple curse",
    'tesla': "a portable Tesla coil gun with copper coils and crackling blue electric arcs",
    'springfield': "a Springfield M1903 bolt-action rifle with a long telescopic sight",
    'lewis': "a Lewis machine gun on a tripod, cooling shroud barrel and a round pan magazine",
    'lugers': "two Luger P08 pistols crossed, dark steel with checkered grips",
    'west': "Herbert West's syringe of glowing green reanimation serum, brass and glass",
    'bumeran': "a wooden Australian boomerang with painted red and ochre aboriginal bands",
    'red': "a coiled fishing net with rope and small lead weights",
    'martillo': "a geologist's rock hammer with a pointed pick head and a wooden handle",
    'estoque': "a sword cane, a black walking stick with a silver handle and a thin rapier blade half drawn",
    # Arsenal III (D-38, hito 8.8)
    'recortada': "a break-action double-barreled coach gun cut very short: two fat side-by-side barrels welded together, two external hammers, no pump, no magazine, a short curved wooden grip",
    'antitanque': "a WWI German Mauser 1918 anti-tank rifle, very long heavy barrel, bipod, bolt action, dark steel and wood",
    'mortero': "a WWI Stokes trench mortar: a short wide steel tube on a bipod and a base plate, with a mortar shell beside it",
    'bar': "a Browning Automatic Rifle M1918, long dark steel rifle with a box magazine underneath and a wooden stock",
    'nagant': "a Russian Nagant M1895 revolver, dark blued steel, long thin barrel, brown wooden grip",
    'ancla': "a rusty iron ship anchor with a heavy chain coiled around its shank",
    'gas': "a WWI chlorine gas canister, dented olive metal cylinder with a valve, leaking yellow-green toxic gas",
    'latigo': "a coiled braided leather bullwhip with a wooden handle",
    'cepos': "an open round steel bear trap lying flat: two semicircular jaws with sharp jagged teeth forming a circle, a round pressure plate in the middle, two flat springs on the sides and a short chain",
    'ballesta': "a wooden hunting crossbow loaded with a steel-tipped bolt",
    'cthugha': "a sphere of living fire, an orange and yellow fireball with a white-hot core floating above a brass ritual brazier",
    'ithaqua': "a swirling gust of icy wind with snowflakes and frost crystals around a pale blue glowing ice shard",
    'yog': "a floating cluster of five round glowing orbs of different sizes, golden, violet and teal, overlapping like soap bubbles, each orb a round ball, floating in the air, nothing else",
    'shub': "a dark green and black slimy tentacle bursting up from cracked earth, glowing green tip",
    'signo_amarillo': "a tattered bright yellow cloth banner hanging from a wooden crossbar, large and clearly visible, with a dark brown occult sigil embroidered in the middle shaped like an irregular spiral with three curling hooked tendrils, the King in Yellow",
    'lampara': "an ornate Arabian brass oil lamp with a bright golden beam of light shining out of its spout",
}


# Evoluciones (D-06): la misma arma que su base en versión legendaria. Se sacan de los .tres
# (evolution = &"…" en el arma base); si una evolución tiene descripción propia aquí, manda esa.
EVO_STYLE = ("an upgraded legendary relic version of it: more ornate and imposing, engraved gold and dark brass "
             "details, small glowing eldritch runes, a faint otherworldly green glow")


def _evolutions():
    import re
    folder = os.path.join(ROOT, 'data', 'weapons')
    out = {}
    for f in os.listdir(folder):
        if not f.endswith('.tres'): continue
        m = re.search(r'evolution = &"(\w+)"', open(os.path.join(folder, f), encoding='utf-8').read())
        base = f[:-5]
        if m and base in WEAPONS and m.group(1) not in WEAPONS:
            out[m.group(1)] = WEAPONS[base] + ', ' + EVO_STYLE
    return out


WEAPONS.update(_evolutions())


def token():
    t = os.environ.get('REPLICATE_API_TOKEN', '')
    env = os.path.join(ROOT, '.env')
    if not t and os.path.exists(env):
        raw = open(env, 'rb').read().replace(b'\x00', b'').decode('utf-8', 'ignore')   # también UTF-16
        for line in raw.splitlines():
            if line.strip().startswith('REPLICATE_API_TOKEN='): t = line.split('=', 1)[1].strip()
    if not t: sys.exit('Falta REPLICATE_API_TOKEN (entorno o .env de la raíz).')
    return t


def api(method, path, body=None, tries=6):
    """Llamada a la API. Con poco crédito la cuenta admite 6 predicciones por minuto: si
    contesta 429, espera lo que pide y lo reintenta."""
    for k in range(tries):
        try:
            return _api(method, path, body)
        except urllib.error.HTTPError as e:
            if e.code != 429 or k == tries - 1: raise
            wait = 11.0
            try: wait = float(json.loads(e.read()).get('retry_after', 10)) + 1.0
            except Exception: pass
            time.sleep(wait)


def _api(method, path, body=None):
    global TOKEN
    if TOKEN is None: TOKEN = token()        # solo al usar la API: importar el módulo no la necesita
    req = urllib.request.Request('https://api.replicate.com/v1' + path, method=method,
                                 data=json.dumps(body).encode() if body is not None else None,
                                 headers={'Authorization': 'Bearer ' + TOKEN, 'Content-Type': 'application/json',
                                          'Prefer': 'wait=60', 'User-Agent': UA})
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read())


# Tope de gasto (10-10-2026): en una semana se fueron 157 imágenes de FLUX (~6,3 $) sin que
# el autor lo aprobara. Cada ejecución admite como mucho REPLICATE_MAX predicciones
# (por defecto 5); para más, hay que pedirlo expresamente con REPLICATE_MAX=N en el entorno,
# y solo con el permiso del autor. Todo lo lanzado se apunta en tools/replicate/gasto.log.
COST = {'black-forest-labs/flux-1.1-pro': 0.04, 'black-forest-labs/flux-1.1-pro-ultra': 0.06,
        'firtoz/trellis': 0.05, '851-labs/background-remover': 0.001}
MAX_RUNS = int(os.environ.get('REPLICATE_MAX', '5'))
_runs = 0


def _charge(model):
    global _runs
    if _runs >= MAX_RUNS:
        sys.exit('Tope alcanzado: %d predicciones en esta ejecución (REPLICATE_MAX). '
                 'No se lanza ninguna más sin permiso del autor.' % MAX_RUNS)
    _runs += 1
    os.makedirs(os.path.join(ROOT, 'tools', 'replicate'), exist_ok=True)
    with open(os.path.join(ROOT, 'tools', 'replicate', 'gasto.log'), 'a', encoding='utf-8') as f:
        f.write('%s  %s  ~%.3f $\n' % (time.strftime('%Y-%m-%d %H:%M'), model, COST.get(model, 0.05)))


def run(model, inputs, version=None):
    """Lanza una predicción y espera al resultado. Devuelve su salida."""
    _charge(model or version)
    if version: p = api('POST', '/predictions', {'version': version, 'input': inputs})
    else: p = api('POST', '/models/%s/predictions' % model, {'input': inputs})
    t0 = time.time()
    while p['status'] not in ('succeeded', 'failed', 'canceled'):
        if time.time() - t0 > 240: raise RuntimeError('tiempo agotado')
        time.sleep(2)
        p = api('GET', '/predictions/%s' % p['id'])
    if p['status'] != 'succeeded': raise RuntimeError('%s: %s' % (p['status'], p.get('error')))
    return p['output']


def download(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=120) as r:
        return r.read()


def data_uri(path, min_side=0):
    """La imagen como data URI; con min_side, ampliada (sin suavizar) hasta ese tamaño mínimo."""
    im = Image.open(path).convert('RGBA')
    if min(im.size) < min_side:
        k = -(-min_side // min(im.size))
        im = im.resize((im.width * k, im.height * k), Image.NEAREST)
    buf = io.BytesIO()
    im.save(buf, 'PNG')
    return 'data:image/png;base64,' + base64.b64encode(buf.getvalue()).decode()


def finish(png_bytes, dest):
    """Recorta al contenido (alfa), lo centra en un cuadrado con margen y lo deja a 256 × 256."""
    im = Image.open(io.BytesIO(png_bytes)).convert('RGBA')
    box = im.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox() or (0, 0, im.width, im.height)
    im = im.crop(box)
    side = int(max(im.size) * 1.1)
    sq = Image.new('RGBA', (side, side), (0, 0, 0, 0))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2), im)
    sq.resize((256, 256), Image.LANCZOS).save(dest)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    redo = '--rehacer' in sys.argv
    ids = list(WEAPONS) if '--todas' in sys.argv else args
    if not redo: ids = [i for i in ids if not os.path.exists(os.path.join(OUT, i + '.png')) or i in args]
    unknown = [i for i in ids if i not in WEAPONS]
    if unknown: sys.exit('Armas desconocidas: %s' % ', '.join(unknown))
    if not ids: return print('Nada que hacer.')
    print('%d iconos, unos %.2f $ en total.' % (len(ids), len(ids) * (PRICE + 0.005)))
    os.makedirs(RAW, exist_ok=True)
    open(os.path.join(RAW, '.gdignore'), 'a').close()   # Godot no importa las imágenes en bruto
    bg_version = api('GET', '/models/%s' % BG_MODEL)['latest_version']['id']
    for i in ids:
        try:
            out = run(MODEL, {'prompt': '%s. %s' % (WEAPONS[i], STYLE), 'aspect_ratio': '1:1',
                              'output_format': 'png', 'safety_tolerance': 2})
            url = out if isinstance(out, str) else out[0]
            raw_path = os.path.join(RAW, i + '.png')
            open(raw_path, 'wb').write(download(url))
            cut = run(BG_MODEL, {'image': data_uri(raw_path)}, version=bg_version)
            finish(download(cut if isinstance(cut, str) else cut[0]), os.path.join(OUT, i + '.png'))
            print('ok', i)
        except (urllib.error.HTTPError, RuntimeError) as e:
            detail = e.read().decode()[:300] if isinstance(e, urllib.error.HTTPError) else str(e)
            print('FALLO', i, detail)


TOKEN = None
if __name__ == '__main__': main()
