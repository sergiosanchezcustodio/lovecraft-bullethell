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
    'casa': ('4:3', 'A decaying 1920s New England clapboard house in the fishing town of Innsmouth: two storeys, '
             'grey weathered wooden siding with missing boards, a steep gambrel roof of dark mossy shingles with a '
             'sagging ridge and a brick chimney, boarded-up windows with crossed planks, one window faintly lit, a '
             'small front porch with broken railing and steps, peeling paint, green damp stains'),
    'autobus': ('16:9', "Joe Sargent's decrepit 1920s motor bus to Innsmouth: a small boxy grey and faded green bus with "
                'rounded roof, rust patches, cracked windows, a long hood with a round radiator grille and round '
                'headlights, spoked wheels, luggage rack on the roof with a tied suitcase, mud on the lower body'),
    'buhardilla': ('4:3', 'A section of an old 1920s New England town rooftop at night: steep slate roof with a dormer '
                   'window (small gabled roof, dark window, white trim), mossy slate shingles in rows, a copper gutter '
                   'with green patina, a brick chimney with chimney pots'),
    'gilman': ('3:4', 'The back of the decrepit Gilman House hotel in Innsmouth, 1920s: a tall four storey dark brick '
               'building with rows of tall sash windows, a few dimly lit in yellow, others black and broken, an iron '
               'fire escape zigzagging down the wall, a cornice at the top, drainpipes, peeling posters, damp stains'),
    'valla': ('16:9', 'A section of a rotten white picket fence in a 1920s New England fishing town: weathered '
              'pointed pickets with peeling white paint, some missing or leaning, two horizontal rails, wooden posts, '
              'weeds and mud at the base'),
    'poste': ('3:4', 'A tall wooden telegraph pole from the 1920s by a muddy country road: weathered grey wood, two '
              'crossarms with green glass insulators, sagging wires, an iron step spike, a small faded notice nailed on'),
    'farola': ('3:4', 'A 1920s cast iron gas street lamp in a decaying New England harbour town: dark green fluted '
               'post with a decorative base, a four-sided glass lantern with a warm yellow flame inside, a small '
               'ladder rest bar, rust and verdigris'),
    'pretil': ('16:9', 'A section of an old brick rooftop parapet wall of a 1920s New England building: dark red '
               'bricks with crumbling mortar, a stone coping on top, some missing bricks, moss and a rusty iron drain '
               'scupper'),
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
