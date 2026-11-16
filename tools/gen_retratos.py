"""Retratos pintados de los investigadores (hito 21.16), con ComfyUI en local (FLUX Schnell).

PRUEBA: dos estilos para que el autor elija antes de hacer los 21.
  A  óleo: retrato de busto pintado, luz de vela y contraluz de luna, como la portada.
  B  voxel pintado: el mismo retrato hecho de cubos pequeños, como el atrezo de la portada.

  python tools/gen_retratos.py dyer peaslee --estilos A,B --semillas 1,2

Arrancar ComfyUI antes (tools/comfyui.cmd). Salida: tools/local/retrato_<pj>_<estilo>_<semilla>.png
y una hoja con todas: tools/local/retratos_hoja.png.
"""
import os, sys
from PIL import Image, ImageDraw
sys.path.insert(0, os.path.dirname(__file__))
import generar_local as gl

LOOKS = {
    'dyer': "William Dyer, a 1930s Miskatonic University geologist on an Antarctic expedition: a man in his "
            "forties with a short brown beard and moustache, drooping brows, cheeks and nose reddened by the "
            "cold, a brown leather trapper hat with a cream sheepskin band, a red scarf, a tan canvas parka "
            "with cream sheepskin trim and pockets",
    'peaslee': "Amelia Peaslee, a young 1920s archaeologist: green eyes and freckles, a copper red braid, a "
               "brown felt fedora, a rolled-up khaki shirt with a leather satchel strap across her chest, "
               "confident half smile",
}
STYLE = {
    'A': "Painted oil portrait, head and shoulders, three-quarter view, of {who}. Dark gothic library behind, "
         "out of focus bookshelves, warm candlelight from the left and cold blue moonlight rim light from the "
         "right, deep shadows, 1920s Lovecraftian cosmic horror atmosphere, painterly brushwork, rich detail, "
         "no text, no letters, no frame",
    'B': "Voxel art portrait made of small cubes, head and shoulders, three-quarter view, of {who}. Clean "
         "blocky shapes with painted details, dark gothic library behind, out of focus bookshelves, warm "
         "candlelight from the left and cold blue moonlight rim light from the right, deep shadows, 1920s "
         "Lovecraftian cosmic horror atmosphere, painterly, highly detailed, no text, no letters, no frame",
}


def main():
    args = sys.argv[1:]
    def opt(k, d):
        return args[args.index(k) + 1] if k in args else d
    who = [a for a in args if a in LOOKS] or list(LOOKS)
    styles = opt('--estilos', 'A,B').split(',')
    seeds = [int(s) for s in opt('--semillas', '1,2').split(',')]
    os.makedirs(gl.TEST, exist_ok=True)
    tiles = []
    for w in who:
        for st in styles:
            for sd in seeds:
                path = os.path.join(gl.TEST, 'retrato_%s_%s_%d.png' % (w, st, sd))
                if not os.path.exists(path):
                    png = gl.generate(STYLE[st].format(who=LOOKS[w]), sd, 1024)
                    open(path, 'wb').write(png)
                    print('ok', path)
                tiles.append((path, '%s %s%d' % (w, st, sd)))
    cols = len(styles) * len(seeds)
    rows = len(who)
    T = 384
    sheet = Image.new('RGB', (cols * T, rows * (T + 24)), (16, 12, 10))
    d = ImageDraw.Draw(sheet)
    for i, (p, label) in enumerate(tiles):
        im = Image.open(p).convert('RGB').resize((T, T))
        x, y = (i % cols) * T, (i // cols) * (T + 24)
        sheet.paste(im, (x, y + 24))
        d.text((x + 6, y + 5), label, fill=(230, 210, 170))
    out = os.path.join(gl.TEST, 'retratos_hoja.png')
    sheet.save(out)
    print('hoja', out)


if __name__ == '__main__':
    main()
