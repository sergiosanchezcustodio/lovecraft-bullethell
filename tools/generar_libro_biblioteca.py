"""Ilustración del libro de la Biblioteca Lovecraft (09-10-2026) con FLUX 1.1 Pro Ultra.

Un grimorio abierto visto desde arriba, con las dos páginas en blanco (encima van el índice y
las fichas), sobre un escritorio en penumbra. Genera varias versiones para elegir.

  python tools/generar_libro_biblioteca.py            # 4 versiones (semillas 1-4)
  python tools/generar_libro_biblioteca.py 7 9        # esas semillas

Deja tools/replicate/libro_<semilla>.png. La elegida se copia a resources/PantallasMenus/libro.png.
Coste: ~0,06 $ por imagen.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import generar_iconos_armas as gi

OUT = os.path.join(gi.ROOT, 'tools', 'replicate')
MODEL = 'black-forest-labs/flux-1.1-pro-ultra'
PROMPT = (
    "Top-down view of a huge ancient occult grimoire lying wide open and perfectly flat on a dark wooden desk, "
    "the open book fills most of the image, centered and symmetrical. Two large completely blank pages of thick "
    "aged yellowed parchment with soft stains and slightly darker edges, empty, no writing at all on the pages. "
    "Heavy cover of cracked dark brown leather with tarnished brass corner pieces, a thin gilded border tooled "
    "with eldritch tentacle motifs and strange sigils around the edge of the cover, a red silk ribbon bookmark. "
    "Around the book, barely visible in the darkness: a burning candle, an old brass key, a few loose papers. "
    "Warm candlelight from the left, deep shadows, 1920s Lovecraftian cosmic horror atmosphere, painterly, "
    "highly detailed, no text, no letters, no people, no hands")


def main():
    seeds = [int(a) for a in sys.argv[1:]] or [1, 2, 3, 4]
    os.makedirs(OUT, exist_ok=True)
    print('%d imágenes, unos %.2f $' % (len(seeds), 0.06 * len(seeds)))
    for s in seeds:
        out = gi.run(MODEL, {'prompt': PROMPT, 'aspect_ratio': '16:9', 'output_format': 'png', 'seed': s,
                             'safety_tolerance': 5, 'raw': False})
        path = os.path.join(OUT, 'libro_%d.png' % s)
        open(path, 'wb').write(gi.download(out if isinstance(out, str) else out[0]))
        print('ok', path)


if __name__ == '__main__':
    main()
