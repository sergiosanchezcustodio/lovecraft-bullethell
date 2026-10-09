"""Imágenes de referencia para rehacer atrezo a mano (09-10-2026). FLUX dibuja la pieza en el
estilo voxel del juego; no se convierte a 3D (lo fino y lo hueco sale mal con TRELLIS): sirve de
guía de diseño para el generador en Python que la modela.

  python tools/referencias_atrezo.py alert emma ruinas      # esas
  python tools/referencias_atrezo.py --todas                 # las que aún no tienen imagen

Deja tools/replicate/ref_<pieza>.png. Coste: ~0,06 $ por imagen (FLUX 1.1 Pro Ultra).
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import generar_iconos_armas as gi

OUT = os.path.join(gi.ROOT, 'tools', 'replicate')
MODEL = 'black-forest-labs/flux-1.1-pro-ultra'
STYLE = ('isometric 3D voxel art, MagicaVoxel style render, built from small cubes, three-quarter view from '
         'above like a strategy game, soft studio lighting, plain dark grey background, whole object visible, '
         'no text, no letters, no people')

PIECES = {
    'alert': ('16:9', 'The side of a 1920s small steam cargo ship moored at a dock at night: black riveted steel '
              'hull with a red waterline stripe and rust streaks, wooden deck with hatches and coiled ropes, a white '
              'wooden wheelhouse with round portholes and a lit window, a tall black funnel with a red band, one '
              'mast with rigging and cargo boom, lifeboat on davits, anchor at the bow'),
    'emma': ('4:3', 'The bridge superstructure of a 1920s schooner during a storm at sea: weathered white painted '
             'wooden deckhouse with wide wheelhouse windows glowing warm yellow, the ship wheel visible inside, '
             'brass details, a short funnel, ladders and railings, life rings hanging on the walls, ropes, wet deck '
             'planks'),
    'ruinas': ('4:3', 'Ruins of an alien cyclopean city of the Elder Things in Antarctica: a broken wall of '
               'enormous dark grey slate blocks of different sizes fitted without mortar, five-pointed star '
               'reliefs carved on some blocks, cracks, a collapsed corner with fallen blocks at its foot, frost and '
               'snow on the top edges'),
}


def main():
    names = list(PIECES) if '--todas' in sys.argv else [a for a in sys.argv[1:] if not a.startswith('--')]
    redo = '--rehacer' in sys.argv
    todo = [n for n in names if redo or not os.path.exists(os.path.join(OUT, 'ref_%s.png' % n))]
    print('%d imágenes, unos %.2f $' % (len(todo), 0.06 * len(todo)))
    for n in todo:
        ratio, prompt = PIECES[n]
        out = gi.run(MODEL, {'prompt': '%s. %s' % (prompt, STYLE), 'aspect_ratio': ratio, 'output_format': 'png',
                             'safety_tolerance': 5, 'seed': 7})
        open(os.path.join(OUT, 'ref_%s.png' % n), 'wb').write(gi.download(out if isinstance(out, str) else out[0]))
        print('ok', n)


if __name__ == '__main__':
    main()
