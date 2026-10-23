"""Referencias de FLUX en local para rehacer las cabezas de los personajes (23-10-2026).

Como referencias_atrezo.py, pero gratis (ComfyUI con FLUX Schnell, tools/generar_local.py):
FLUX dibuja la cabeza del personaje en voxel y sirve de guía de diseño para su generador
(cara, peinado, sombrero); no se convierte a 3D. Arranca antes ComfyUI (tools/comfyui.cmd).

  python tools/referencias_personajes.py legrasse            # busto de 3/4 y cabeza de frente
  python tools/referencias_personajes.py legrasse --semillas 4 --vista busto

Deja tools/local/ref_cabeza_<personaje>_<vista>_<semilla>.png.
"""
import os, sys, time
sys.path.insert(0, os.path.dirname(__file__))
import generar_local as gl

# 'voxel' a secas da muñecos 3D lisos: hay que poner el estilo delante e insistir en los cubos
# (como el STYLE de los iconos, generar_iconos_armas.py, que sí sale en voxel)
LEAD = 'High quality 3D voxel art character, MagicaVoxel style render, a voxel model of'
STYLE = ('The character is built entirely from small cubic voxels with a clearly visible cube grid on every '
         'surface, blocky with stepped jagged edges made of cubes and no smooth curves, like a high-resolution '
         'Minecraft-style figure, even the hat, the hair, the moustache and the face are made of cubes, the eyes '
         'and eyebrows are square pixels painted on the flat front of the blocky head, soft global illumination, '
         'ambient occlusion between the cubes, warm key light and a cool green rim light, rich but slightly muted '
         'colors, plain flat dark grey background, no text, no letters')

VIEWS = {
    'busto': 'bust portrait from the chest up, three-quarter view from slightly above, the head large and centered',
    'frente': 'close-up of the head only, front view, symmetrical, looking at the camera',
}

CHARACTERS = {
    'legrasse': ('a 1920s New Orleans police inspector in his forties: charcoal grey fedora hat with a wide brim, '
                 'a brown hat band and a pinched crown, short dark brown hair with sideburns, thick bushy dark brown '
                 'moustache, heavy eyebrows, square jaw, tanned skin, stern but kind eyes, white shirt collar, '
                 'dark tie and a stone grey trench coat collar'),
    'olmstead': ('a 1920s young traveller in his early twenties: tweed flat cap in brown, clean shaven, short brown '
                 'hair with sideburns, friendly curious eyes, light skin with rosy cheeks, white shirt collar, '
                 'blue tie and a grey green tweed jacket'),
    'johansen': ('a 1920s burly Norwegian sailor: grey knitted wool beanie, full golden blond beard, weathered '
                 'face, blue eyes, navy blue double breasted pea coat with brass buttons over a cream turtleneck'),
    'dyer': ('a 1930s Antarctic expedition geologist: brown leather trapper hat with sheepskin lining and ear flaps, '
             'short brown beard and moustache, red scarf, tan canvas parka with sheepskin trim'),
}


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    opt = lambda k, d: sys.argv[sys.argv.index(k) + 1] if k in sys.argv else d
    if not args or args[0] not in CHARACTERS: sys.exit(__doc__ + '\nPersonajes: ' + ', '.join(CHARACTERS))
    who = args[0]
    views = [opt('--vista', '')] if '--vista' in sys.argv else list(VIEWS)
    seeds = int(opt('--semillas', '2'))
    os.makedirs(gl.TEST, exist_ok=True)
    for view in views:
        prompt = '%s %s, %s. %s' % (LEAD, CHARACTERS[who], VIEWS[view], STYLE)
        for k in range(seeds):
            seed = int(opt('--semilla', '1000')) + k
            t0 = time.time()
            png = gl.generate(prompt, seed, int(opt('--tam', '1024')))
            out = os.path.join(gl.TEST, 'ref_cabeza_%s_%s_%d.png' % (who, view, seed))
            open(out, 'wb').write(png)
            print('ok %s %s semilla %d en %.0f s -> %s' % (who, view, seed, time.time() - t0, out))


if __name__ == '__main__': main()
