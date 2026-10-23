"""Referencias de FLUX en local para rehacer criaturas y jefes (23-10-2026).

Como referencias_personajes.py: ComfyUI con FLUX Schnell (tools/generar_local.py) dibuja la
criatura en voxel y sirve de guía de diseño para su generador; no se convierte a 3D. Arranca
antes ComfyUI (tools/comfyui.cmd).

  python tools/referencias_criaturas.py dagon                     # todas sus vistas, 3 semillas
  python tools/referencias_criaturas.py dagon --vista cabeza --semillas 4 --semilla 2000

Deja tools/local/ref_<criatura>_<vista>_<semilla>.png.
"""
import os, sys, time
sys.path.insert(0, os.path.dirname(__file__))
import generar_local as gl

# el estilo va delante y corto (Schnell le hace más caso) y se insiste en los cubos al final
LEAD = 'High quality 3D voxel art creature, MagicaVoxel style render, a voxel model of'
STYLE = ('The creature is built entirely from small cubic voxels with a clearly visible cube grid on every '
         'surface, blocky stepped edges made of cubes, highly detailed, every scale, spine, tooth and fin made of '
         'cubes, many different color tones in the voxels, soft global illumination, ambient occlusion between the '
         'cubes, cold moonlight from above, a warm orange key light and a green rim light, plain flat dark grey '
         'background, no text, no letters')

CREATURES = {
    # Padre Dagon (petición 103): misma silueta que el modelo del juego, mucho más detalle y color.
    # Solo anatomía: los Profundos no llevan ropa, joyas ni tiaras (CLAUDE.md).
    'dagon': {
        'desc': ('Father Dagon, a colossal ancient fish-man sea god rising from black water up to the waist: an '
                 'enormous hunched torso with massive rounded shoulders and a big hump, a huge flat wide fish head '
                 'jutting forward with no neck, an enormous gaping mouth full of long crooked jagged teeth, two '
                 'bulging glowing yellow-green eyes on the sides of the head, red frilled gills behind the eyes, a '
                 'continuous crest of bony spines from the top of the head down the hump to the waist, very long '
                 'thick arms reaching forward with webbed clawed hands resting flat on the water, spiky fins on the '
                 'forearms. Dark teal and bottle green scales with bronze and violet iridescent sheen, mottled '
                 'darker spots, a pale cream and olive ribbed belly, barnacles, small coral growths and strands of '
                 'kelp clinging to the shoulders and back, old scars, translucent fin membranes with bony rays, '
                 'wet shiny skin. Only anatomy: no clothes, no jewelry, no crown'),
        'views': {
            'frente': ('front three-quarter view from slightly above like an isometric game camera, the whole '
                       'creature visible from the waist up, both hands resting on the water in front of it'),
            'cabeza': 'close-up of the head and shoulders, front three-quarter view, the open mouth and eyes in focus',
            'perfil': 'side view, the hunched back, the spine crest and one long arm reaching forward visible',
        },
    },
}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    opt = lambda k, d: sys.argv[sys.argv.index(k) + 1] if k in sys.argv else d
    if not args or args[0] not in CREATURES: sys.exit(__doc__ + '\nCriaturas: ' + ', '.join(CREATURES))
    who = CREATURES[args[0]]
    views = [opt('--vista', '')] if '--vista' in sys.argv else list(who['views'])
    seeds = int(opt('--semillas', '3'))
    os.makedirs(gl.TEST, exist_ok=True)
    for view in views:
        prompt = '%s %s, %s. %s' % (LEAD, who['desc'], who['views'][view], STYLE)
        for k in range(seeds):
            seed = int(opt('--semilla', '1000')) + k
            t0 = time.time()
            png = gl.generate(prompt, seed, int(opt('--tam', '1024')))
            out = os.path.join(gl.TEST, 'ref_%s_%s_%d.png' % (args[0], view, seed))
            open(out, 'wb').write(png)
            print('ok %s %s semilla %d en %.0f s -> %s' % (args[0], view, seed, time.time() - t0, out), flush=True)


if __name__ == '__main__': main()
