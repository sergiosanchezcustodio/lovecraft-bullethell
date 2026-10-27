"""Adornos de latón de los menús (estilo biblioteca gótica, 27-10-2026), con FLUX en local.

Genera variantes de la esquina de filigrana y del separador horizontal sobre fondo negro, y las
recorta con transparencia sacada del brillo (el latón sobre negro: lo oscuro se vuelve
transparente). Salen en tools/local/adornos/ para elegir; con --usar N copia la variante N de
cada pieza a resources/ui/ (menu_esquina.png, menu_separador.png).

ComfyUI arrancado antes (tools/comfyui.cmd).

  python tools/gen_adornos_menu.py --semillas 4         # candidatas
  python tools/gen_adornos_menu.py --usar 1002          # la de esa semilla, para el juego
"""
import io, os, sys, time
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(__file__))
import generar_local as gl

ROOT = gl.ROOT
TEST = os.path.join(ROOT, 'tools', 'local', 'adornos')
OUT = os.path.join(ROOT, 'resources', 'ui')
SIZES = {'esquina': (384, 384), 'separador': (1400, 240)}   # tamaño en el juego (con mipmaps)

PIECES = {
    'esquina': ((1024, 1024),
        'Ornate antique brass corner ornament for a gothic leather book cover, victorian filigree '
        'scrollwork forming an L-shaped bracket in the top-left corner, two straight arms along the top '
        'and left edges ending in curled scrolls, tarnished old gold metal with engraved details and '
        'warm candlelight highlights, isolated on a pure black background, flat front view, high detail'),
    'separador': ((1536, 512),
        'Ornate antique brass horizontal divider ornament, a long thin symmetrical line of victorian '
        'scrollwork with a small central diamond and curled flourishes, tapering to fine points at both '
        'ends, tarnished old gold metal with engraved details, isolated on a pure black background, '
        'flat front view, high detail'),
}


def generate(prompt, seed, w, h):
    wf = gl.workflow(prompt, seed)
    wf['6']['inputs'].update({'width': w, 'height': h})
    orig = gl.workflow
    gl.workflow = lambda p, s, size=1024: wf
    try:
        return gl.generate(prompt, seed)
    finally:
        gl.workflow = orig


def cut(png):
    """Transparencia por brillo: el negro del fondo desaparece y el latón se queda."""
    im = Image.open(io.BytesIO(png)).convert('RGB')
    lum = im.convert('L')
    alpha = lum.point(lambda v: 0 if v < 14 else min(255, int((v - 14) * 255 / 46)))
    alpha = alpha.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    rgba = im.convert('RGBA')
    rgba.putalpha(alpha)
    bbox = alpha.point(lambda v: 255 if v > 24 else 0).getbbox()
    return rgba.crop(bbox) if bbox else rgba


def main():
    opt = lambda k, d: sys.argv[sys.argv.index(k) + 1] if k in sys.argv else d
    os.makedirs(TEST, exist_ok=True)
    open(os.path.join(ROOT, 'tools', 'local', '.gdignore'), 'a').close()
    if '--usar' in sys.argv:
        seed = opt('--usar', '')
        os.makedirs(OUT, exist_ok=True)
        for name in PIECES:
            src = os.path.join(TEST, '%s_%s_recorte.png' % (name, seed))
            if os.path.exists(src):
                im = Image.open(src)
                im.thumbnail(SIZES[name], Image.LANCZOS)
                im.save(os.path.join(OUT, 'menu_%s.png' % name))
                print('copiado', name, seed)
        return
    only = opt('--pieza', '')
    for k in range(int(opt('--semillas', '4'))):
        seed = int(opt('--semilla', '1000')) + k
        for name, ((w, h), prompt) in PIECES.items():
            if only and name != only: continue
            t0 = time.time()
            png = generate(prompt, seed, w, h)
            open(os.path.join(TEST, '%s_%d.png' % (name, seed)), 'wb').write(png)
            cut(png).save(os.path.join(TEST, '%s_%d_recorte.png' % (name, seed)))
            print('ok %s %d en %.0f s' % (name, seed, time.time() - t0))


if __name__ == '__main__': main()
