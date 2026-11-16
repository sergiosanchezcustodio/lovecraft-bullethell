"""Finales ilustrados de cada parte (hito 21.17), con ComfyUI en local (FLUX Schnell), apaisados.

Al vencer al jefe de una parte sale su ilustración con la frase que cierra el relato, antes de la
pantalla de victoria (`PartFinale`, `data/part_finales.json`). Mismo estilo que los retratos
(21.16): óleo oscuro, luz fría de luna y puntos de luz cálida, como la portada.

  python tools/gen_finales.py                     # las cuatro, semillas 1 a 3, y la hoja
  python tools/gen_finales.py p2 --semillas 4,5
  python tools/gen_finales.py --usar p1=2 p2=1 …  # copia esas al juego

Pruebas: tools/local/final_<parte>_<semilla>.png y tools/local/finales_hoja.png. Al juego:
resources/finales/<parte>.jpg (1920 × 1080, calidad 90).

Elegidas el 16-11-2026: p1=6 (rehecha con la ciudad de los Antiguos; las 1 a 3 parecían templos
griegos o un castillo), p2=1, p3=2, p4=2.
"""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import generar_local as gl

OUT = os.path.join(gl.ROOT, 'resources', 'finales')
W, H = 1344, 768                                    # 16:9 aproximado, múltiplos de 64

SCENES = {
    'p1': "A small single 1930s expedition aeroplane flying away at dawn over colossal black Antarctic "
          "mountain peaks; below, covering the whole snowy plateau, an endless dead alien city: a labyrinth of "
          "enormous black stone megalith blocks, terraced cones, flat-topped towers and star-shaped five "
          "pointed buildings half buried in ice, utterly inhuman architecture, a dark abyss opening among the "
          "ruins with a pale iridescent mist rising from it, cold blue light and a faint warm sunrise glow on "
          "the horizon, tiny aeroplane, immense scale",
    'p2': "Devil Reef, a black jagged reef in a dark sea off a decaying 1920s New England fishing town, at "
          "dawn; a US Navy submarine on the surface and the white columns of torpedo explosions on the reef, "
          "the old town with gambrel roofs and a church spire on the shore behind, a few warm lit windows, "
          "cold misty light, a lone small figure watching from the beach",
    'p3': "The colossal sunken city of R'lyeh sinking back into a stormy Pacific ocean at night: titanic "
          "slimy green stone blocks with impossible angles and a huge monolith slipping under the waves, a "
          "small 1920s steam yacht sailing away through the storm with one warm lantern, lightning in the "
          "clouds, green phosphorescent glow from under the water",
    'p4': "A man in a long dark coat falling through a starry night sky full of strange constellations and "
          "auroras, far below him the warm golden sunset city of old Boston with its domes, Beacon Hill "
          "rooftops and lit windows, dreamlike, a great dark winged shape flying away above him",
}
STYLE = ("Painted oil illustration, wide cinematic landscape, {scene}. Dark atmospheric 1920s Lovecraftian "
         "cosmic horror, painterly brushwork, rich detail, deep shadows, no text, no letters, no frame, no border")


def opt(args, k, d):
    return args[args.index(k) + 1] if k in args else d


def main():
    args = sys.argv[1:]
    if '--usar' in args:
        os.makedirs(OUT, exist_ok=True)
        for a in args[args.index('--usar') + 1:]:
            part, sd = a.split('=')
            src = os.path.join(gl.TEST, 'final_%s_%s.png' % (part, sd))
            Image.open(src).convert('RGB').resize((1920, 1097), Image.LANCZOS).crop((0, 8, 1920, 1088)) \
                .save(os.path.join(OUT, part + '.jpg'), quality=90)
            print('al juego', part, sd)
        return
    parts = [a for a in args if a in SCENES] or list(SCENES)
    seeds = [int(s) for s in opt(args, '--semillas', '1,2,3').split(',')]
    os.makedirs(gl.TEST, exist_ok=True)
    tiles = []
    for p in parts:
        for sd in seeds:
            path = os.path.join(gl.TEST, 'final_%s_%d.png' % (p, sd))
            if not os.path.exists(path):
                open(path, 'wb').write(gl.generate(STYLE.format(scene=SCENES[p]), sd, W, H))
                print('ok', path, flush=True)
            tiles.append((path, '%s %d' % (p, sd)))
    TW, TH = 448, 256
    cols = len(seeds)
    rows = (len(tiles) + cols - 1) // cols
    im = Image.new('RGB', (cols * TW, rows * (TH + 20)), (16, 12, 10))
    d = ImageDraw.Draw(im)
    for i, (p, label) in enumerate(tiles):
        x, y = (i % cols) * TW, (i // cols) * (TH + 20)
        im.paste(Image.open(p).convert('RGB').resize((TW, TH)), (x, y + 20))
        d.text((x + 5, y + 4), label, fill=(230, 210, 170))
    out = os.path.join(gl.TEST, 'finales_hoja.png')
    im.save(out)
    print('hoja', out)


if __name__ == '__main__':
    main()
