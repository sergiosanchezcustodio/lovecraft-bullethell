"""Retratos pintados de los investigadores (hito 21.16), con ComfyUI en local (FLUX Schnell).

Estilo elegido por el autor (16-11-2026): A, óleo. Retrato de busto pintado ante la biblioteca en
penumbra, luz de vela por la izquierda y contraluz frío por la derecha, como la portada. Las
descripciones siguen la tabla de personajes de tools/CLAUDE.md (lo que se ve del busto).

  python tools/gen_retratos.py                       # todos, semillas 1 a 3, y la hoja para elegir
  python tools/gen_retratos.py dyer peaslee --semillas 4,5
  python tools/gen_retratos.py --usar dyer=2 peaslee=1   # copia esas al juego

Elegidos el 16-11-2026 (semilla de cada uno): dyer=1 peaslee=1 olmstead=1 legrasse=1 johansen=1
varga=3 whipple=2 blake=2 iwanicki=2 elwood=1 malone=2 armitage=1 west=2 carter=1 whateley=3
pickman=2 ward=1 gilman=1 tillinghast=2 derby=2 kuranes=5 (con el aro, tras rehacerlo).

Arrancar ComfyUI antes (tools/comfyui.cmd). Pruebas: tools/local/retrato_<pj>_A_<semilla>.png y la
hoja tools/local/retratos_hoja.png. Al juego: resources/retratos/<pj>.jpg (512 × 512, calidad 90:
en la ficha se ven a 188 × 276 y en la tienda a 76; unos 60 kB cada uno).
"""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import generar_local as gl

OUT = os.path.join(gl.ROOT, 'resources', 'retratos')

LOOKS = {
    'dyer': "William Dyer, a 1930s Miskatonic University geologist on an Antarctic expedition: a man in his "
            "forties with a short brown beard and moustache, drooping brows, cheeks and nose reddened by the "
            "cold, a brown leather trapper hat with a cream sheepskin band, a red scarf, a tan canvas parka "
            "with cream sheepskin trim and pockets",
    'peaslee': "Amelia Peaslee, a young 1920s archaeologist: green eyes and freckles, a single thick copper red "
               "braid over one shoulder, a brown felt fedora, a rolled-up khaki shirt with a leather satchel "
               "strap across her chest, confident half smile",
    'olmstead': "Robert Olmstead, a young 1920s New England traveller in his twenties: clean shaven, dark brown "
                "hair, a grey-green tweed flat cap with a thin peak, a grey-green tweed jacket and waistcoat, a "
                "white shirt and a blue tie, curious earnest look",
    'legrasse': "Inspector John R. Legrasse of the 1920s New Orleans police: a stern man in his fifties with a "
                "frowning brow and a handlebar moustache, a wide-brimmed charcoal grey fedora with a pinched "
                "crown, a short stone grey trench coat open over a navy blue suit, a gold police badge",
    'johansen': "Gustaf Johansen, a burly Norwegian sailor of the 1920s: blue eyes, a golden blond beard, a grey "
                "ribbed wool watch cap, a navy blue double-breasted pea coat with brass buttons over a cream "
                "turtleneck sweater, weathered face",
    'varga': "Madame Ludmila Varga, a 1920s parlour spirit medium: a woman in her forties with a black bob, "
             "smoky eye makeup and garnet lips, a headband with a violet feather, a long black velvet dress, a "
             "plum stole with fringes, a pearl necklace, an intense knowing gaze",
    'whipple': "Doctor Marian Whipple, a 1920s physician: a woman in her thirties with chestnut hair in a bun, "
               "round bronze spectacles, a long open white doctor's coat over a grey dress, a stethoscope around "
               "her neck, calm attentive look",
    'blake': "Henrietta Blake, a 1920s novelist: a young woman with a blonde bob and blue eyes, a teal cloche hat, "
             "a burgundy coat with a cream scarf, a fountain pen in the breast pocket, thoughtful look",
    'iwanicki': "Father Iwanicki, a 1920s Polish Catholic priest: an older man with grey receding hair, bushy "
                "eyebrows and kind wrinkles, a black buttoned cassock with a white clerical collar, a purple "
                "sash, a silver crucifix on his chest",
    'elwood': "Sergeant Frank Elwood, a burly First World War veteran: a frowning man in his forties with a big "
              "walrus moustache, a Brodie steel helmet with chin strap, an olive drab tunic with leather straps "
              "and ammunition pouches",
    'malone': "Vera Malone, a 1920s gangster woman: a black bob, one eyebrow raised and a sly half smile, a "
              "burgundy fedora, a grey pinstripe double-breasted suit with a burgundy tie and a carnation in the "
              "lapel",
    'armitage': "Professor Henry Armitage, the elderly librarian of Miskatonic University: bald on top with white "
                "hair at the sides, bushy white eyebrows, round gold spectacles, a white beard and moustache, a "
                "charcoal grey frock coat with a black bow tie, holding an old book against his chest",
    'west': "Herbert West, a young pale 1920s medical scientist: slicked back blond hair, round black spectacles, "
            "cold light blue eyes, a white lab coat over a dark suit, a cold slightly unsettling expression",
    'carter': "Randolph Carter, a 1920s Boston dreamer: a man in his forties with dark hair greying at the "
              "temples and heavy eyelids, a long midnight blue overcoat, a grey waistcoat and a small bow tie, a "
              "silver key glowing faintly on his chest",
    'whateley': "Wilbur Whateley, a huge stooping young man from rural 1920s Massachusetts: a goatish face with no "
                "chin, drooping ears, curly black hair, a short patched brown coat, deeply unsettling inhuman "
                "features, a dark tentacle tip peeking from under the coat",
    'pickman': "Richard Upton Pickman, a thin 1920s Boston painter: long messy very dark hair, unshaven, sunken "
               "dark eyes with dark circles, an off-white linen painter's smock with big oil paint stains in "
               "crimson, ochre and green, a black artist's bow at the neck, a paintbrush in the breast pocket",
    'ward': "Charles Dexter Ward, a young Providence antiquarian dressed in 18th century clothes: chestnut hair "
            "tied in a ponytail with a black ribbon, one eyebrow higher than the other and a half smile, a "
            "bottle green frock coat with brass buttons and wide cuffs, a long suede waistcoat, a white lace "
            "jabot",
    'gilman': "Walter Gilman, a tired 1920s mathematics student: messy dark blond hair with a cowlick, dark "
              "circles under worried eyes, a pencil behind his ear, an open grey knitted cardigan with chalk "
              "stains, a white open collar shirt with a loose burgundy tie",
    'tillinghast': "Crawford Tillinghast, a gaunt dishevelled 1920s physicist: sallow skin with days of stubble, "
                   "wide staring eyes with dark circles and a strange smile, messy dark hair greying at the "
                   "temples, a dirty open shirt with rolled sleeves and braces, a vacuum tube glowing violet in "
                   "his shirt pocket",
    'derby': "Edward Derby, a 1920s poet: a round-faced slightly plump blond man with a thin little moustache, a "
             "light cream suit with a green bow tie and a pocket square, a gentle uncertain look",
    'asenath': "Asenath Waite, a pale 1920s woman: bulging staring green eyes, black hair parted in the middle "
               "and gathered in a bun, a very dark green dress with a gold chain and pendant, a cold commanding "
               "expression",
    'kuranes': "Kuranes, an elderly English dreamer king wearing a thin gold crown circlet across his forehead "
               "with a single sky blue gem in the middle: grey hair swept back with receding temples, a short "
               "grey beard and moustache, blue eyes with drooping lids, a garnet velvet dressing gown with "
               "quilted lapels, frogging and a gold cord, a blue cravat with a pin",
}
STYLE = ("Painted oil portrait, head and shoulders, centered, three-quarter view, of {who}. Dark gothic "
         "library behind, out of focus bookshelves and a few candles, warm candlelight from the left and a "
         "cold blue rim light from the right, deep shadows, 1920s Lovecraftian cosmic horror atmosphere, "
         "painterly brushwork, rich detail, no moon, no window, no text, no letters, no frame")


def opt(args, k, d):
    return args[args.index(k) + 1] if k in args else d


def sheet(tiles, cols, out):
    T = 256
    rows = (len(tiles) + cols - 1) // cols
    im = Image.new('RGB', (cols * T, rows * (T + 20)), (16, 12, 10))
    d = ImageDraw.Draw(im)
    for i, (p, label) in enumerate(tiles):
        x, y = (i % cols) * T, (i // cols) * (T + 20)
        im.paste(Image.open(p).convert('RGB').resize((T, T)), (x, y + 20))
        d.text((x + 5, y + 4), label, fill=(230, 210, 170))
    im.save(out)
    print('hoja', out)


def main():
    args = sys.argv[1:]
    if '--usar' in args:                               # pj=semilla ... -> resources/retratos/pj.png
        os.makedirs(OUT, exist_ok=True)
        for a in args[args.index('--usar') + 1:]:
            pj, sd = a.split('=')
            src = os.path.join(gl.TEST, 'retrato_%s_A_%s.png' % (pj, sd))
            Image.open(src).convert('RGB').resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, pj + '.jpg'), quality=90)
            print('al juego', pj, sd)
        return
    who = [a for a in args if a in LOOKS] or list(LOOKS)
    seeds = [int(s) for s in opt(args, '--semillas', '1,2,3').split(',')]
    os.makedirs(gl.TEST, exist_ok=True)
    tiles = []
    for w in who:
        for sd in seeds:
            path = os.path.join(gl.TEST, 'retrato_%s_A_%d.png' % (w, sd))
            if not os.path.exists(path):
                open(path, 'wb').write(gl.generate(STYLE.format(who=LOOKS[w]), sd, 1024))
                print('ok', path, flush=True)
            tiles.append((path, '%s %d' % (w, sd)))
    sheet(tiles, len(seeds) * 2, os.path.join(gl.TEST, 'retratos_hoja.png'))


if __name__ == '__main__':
    main()
