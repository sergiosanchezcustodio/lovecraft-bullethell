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
    'presteza': "a pair of worn leather boxing gloves hanging from a hook, tied by the laces",
    'magnetismo': "a red horseshoe magnet with silver tips attracting small golden gems",
    'erudicion': "a thick antique leather-bound book with brass corners, open, with glowing pages",
    'fortuna': "a four-leaf clover pressed under glass in a small round brass locket",
    # tienda: mejoras
    'sexta_arma': "a leather bandolier belt with two empty holsters and brass buckles",
    'sexto_objeto': "an old leather satchel bag with two buckled straps and many small pockets",
    'quinta_arma': "an empty brown leather gun holster with a brass buckle and stitched edges",
    'quinto_objeto': "a small brown leather explorer's pouch bag with a flap and a brass clasp",
    # partida: objetos de la subida de nivel
    'cordura': "a worn leather field journal notebook, closed with a strap, with a pencil tucked in",
    'iman': "an antique brass field compass with the lid open, a white dial and a glowing needle",
    'reflejos': "a mountaineer's ice axe with a wooden shaft and a coil of climbing rope",
    'velocidad': "a pair of fur-lined polar snow boots with leather straps",
    'vida': "a folded thick reindeer fur coat, brown and cream fur with a leather collar",
    # Objetos de la subida de nivel (D-38, hitos 8.6 y 8.7)
    'bandolera': "a brown leather bandolier strap worn diagonally, curved like a sash, with a row of brass bullet cartridges in loops",
    'catalejo': "an extended brass nautical spyglass telescope with leather grip",
    'polvora': "a curved cow horn powder flask with brass caps and a leather strap, a few grains of black gunpowder below",
    'mapa_leng': "an old unrolled star map parchment with strange constellations and glowing points",
    'reloj': "an open antique silver pocket watch with a glowing teal dial and strange symbols",
    'clepsidra': "an ornate crystal hourglass with glowing golden sand flowing upward",
    'piedra_afilar': "a grey whetstone sharpening stone next to a small steel knife",
    'ojo_pickman': "a glass eye, a realistic eyeball with a green iris, sitting on a small velvet cushion",
    'collar': "a necklace of sharp fish teeth and fangs on a dark cord",
    'petaca': "a dented pewter hip flask of rum with a leather cover",
    'manual_tiro': "a closed olive green cloth-bound army manual book with a stamped rifle emblem on the cover, no text",
    'guantes': "a pair of thick brown leather dockworker gloves with a cargo hook",
    'manuscritos': "loose ancient yellowed manuscript pages with strange glowing violet glyphs, tied with string",
    'medallon': "a bronze hunter's medallion with a wolf head relief on a chain",
    'plomada': "a heavy lead fishing sinker plumb bob on a coiled fishing line",
    'coraza': "a sealskin leather vest armor with stitched grey fur panels",
    'signo_primigenio': "a grey stone amulet carved as a five-pointed star with a flaming eye in the center, softly glowing",
    'botiquin': "a 1920s metal first aid kit box, open, with bandages and an iodine bottle, red cross on the lid",
    'pipa': "a white meerschaum tobacco pipe with a curved stem and a wisp of smoke",
    'colmillo': "a single long yellowed ghoul fang tooth hanging on a leather cord",
    'salterio': "a small worn psalm book with a cross on the leather cover and a ribbon bookmark",
    'escapulario': "a cloth scapular with two small embroidered patches joined by cords",
    'laudano': "a small brown glass laudanum bottle with a cork and a paper label",
    'escamas': "a vest made of overlapping blue-green fish scales, iridescent",
    'nodens': "a large grey seashell shield with pale blue glowing edges",
    'ankh': "a golden Egyptian ankh cross with turquoise inlays, softly glowing",
    'esquis': "a pair of short wooden skis crossed with leather bindings",
    'capa': "a black hooded cloak draped over itself with a long shadowy tail",
    'petardos': "a bundle of small red paper firecracker tubes tied together with a long fuse, sparks at the fuse tip",
    'elixir': "a small corked alchemical vial of glowing crimson elixir",
    'crampones': "a pair of steel mountaineering crampons with sharp spikes and leather straps",
    'gafas': "a pair of 1920s leather aviator goggles with round glass lenses",
    'lupa': "a round magnifying glass: a big circular glass lens in a brass ring with a short bone handle",
    'dado': "a single carved bone die with strange symbols instead of dots",
    'oro_obed': "a pale yellowish gold ingot bar with an engraved fish relief, no text",
    'vara': "a forked hazel dowsing rod, Y-shaped wooden branch",
    'pemmican': "a block of pemmican food wrapped in cloth and string, with dried berries",
    'silbato': "a shiny brass referee-style pea whistle seen from the side, rounded chamber with a short flat mouthpiece, small ring with a leather cord",
    'talisman': "a gold talisman medallion with a fish and wave emblem of the Esoteric Order of Dagon",
    'llave': "an ornate antique silver key with arabesque patterns, softly glowing",
    'tablilla': "a broken clay tablet fragment with carved wedge-shaped marks and cracks, no letters",
    'cristal': "a jagged blue ice crystal that glows from inside, frost around it",
    'fosforos': "an open matchbox with matches burning with a strange green-orange flame",
    'diente': "a black glossy shapeless tooth-like shard with iridescent green highlights",
    'idolo': "a small green-black stone idol of Cthulhu, octopus head with tentacles and wings, sitting on a pedestal",
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
