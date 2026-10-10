"""Imágenes gratis en el propio ordenador con ComfyUI y FLUX Schnell (11-10-2026).

Sustituye a Replicate para borradores y pruebas: no cuesta nada. Usa las mismas descripciones
y el mismo estilo que los iconos de Replicate (generar_iconos_armas.py y generar_iconos_objetos.py),
quita el fondo rellenando desde los bordes (el estilo pide fondo gris liso) y deja el icono a
256 × 256 con transparencia, como `finish()`.

ComfyUI portable está en C:/Tools/ComfyUI_windows_portable (RTX 3070 Ti, 8 GB): FLUX Schnell
comprimido (flux1-schnell-Q4_K_S.gguf, nodo ComfyUI-GGUF), T5 en fp8, CLIP-L y el VAE de FLUX.
Arrancarlo antes (se queda escuchando en 127.0.0.1:8188):
  C:/Tools/ComfyUI_windows_portable/python_embeded/python.exe -s C:/Tools/ComfyUI_windows_portable/ComfyUI/main.py --port 8188 --disable-auto-launch --offline

  python tools/generar_local.py arma webly                  # icono de un arma
  python tools/generar_local.py objeto ankh --semillas 3    # tres variantes de un objeto
  python tools/generar_local.py libre "a voxel lantern" --nombre farol
  --usar   copia la variante 1 como icono del juego (si no, todo va a tools/local/ para revisarlo)

Salida de prueba: tools/local/<nombre>_<semilla>.png (bruto) y _icono.png (recortado).
"""
import io, json, os, sys, time, urllib.request
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(__file__))
import generar_iconos_armas as armas
import generar_iconos_objetos as objetos

URL = 'http://127.0.0.1:8188'
ROOT = armas.ROOT
TEST = os.path.join(ROOT, 'tools', 'local')
STEPS = 4                                 # Schnell está hecho para 4 pasos


def workflow(prompt, seed, size=1024):
    """Grafo de ComfyUI: FLUX Schnell GGUF + T5/CLIP + VAE, 4 pasos, cfg 1."""
    return {
        '1': {'class_type': 'UnetLoaderGGUF', 'inputs': {'unet_name': 'flux1-schnell-Q4_K_S.gguf'}},
        '2': {'class_type': 'DualCLIPLoader', 'inputs': {'clip_name1': 't5xxl_fp8_e4m3fn.safetensors',
                                                         'clip_name2': 'clip_l.safetensors', 'type': 'flux'}},
        '3': {'class_type': 'VAELoader', 'inputs': {'vae_name': 'ae.safetensors'}},
        '4': {'class_type': 'CLIPTextEncode', 'inputs': {'text': prompt, 'clip': ['2', 0]}},
        '5': {'class_type': 'CLIPTextEncode', 'inputs': {'text': '', 'clip': ['2', 0]}},
        '6': {'class_type': 'EmptySD3LatentImage', 'inputs': {'width': size, 'height': size, 'batch_size': 1}},
        '7': {'class_type': 'KSampler', 'inputs': {'model': ['1', 0], 'positive': ['4', 0], 'negative': ['5', 0],
                                                   'latent_image': ['6', 0], 'seed': seed, 'steps': STEPS, 'cfg': 1.0,
                                                   'sampler_name': 'euler', 'scheduler': 'simple', 'denoise': 1.0}},
        '8': {'class_type': 'VAEDecode', 'inputs': {'samples': ['7', 0], 'vae': ['3', 0]}},
        '9': {'class_type': 'SaveImage', 'inputs': {'images': ['8', 0], 'filename_prefix': 'lovecraft'}},
    }


def _get(path):
    with urllib.request.urlopen(URL + path, timeout=30) as r:
        return r.read()


def generate(prompt, seed):
    """Lanza el grafo y espera la imagen (PNG en bytes)."""
    body = json.dumps({'prompt': workflow(prompt, seed)}).encode()
    req = urllib.request.Request(URL + '/prompt', data=body, headers={'Content-Type': 'application/json'})
    try:
        pid = json.loads(urllib.request.urlopen(req, timeout=30).read())['prompt_id']
    except urllib.error.URLError:
        sys.exit('ComfyUI no responde en %s: arráncalo antes (ver la cabecera del script).' % URL)
    t0 = time.time()
    while True:
        h = json.loads(_get('/history/' + pid))
        if pid in h:
            st = h[pid].get('status', {})
            if st.get('status_str') == 'error': raise RuntimeError(json.dumps(st.get('messages', ''))[:500])
            for out in h[pid]['outputs'].values():
                for im in out.get('images', []):
                    q = 'filename=%s&subfolder=%s&type=%s' % (im['filename'], im['subfolder'], im['type'])
                    return _get('/view?' + q)
        if time.time() - t0 > 600: raise RuntimeError('tiempo agotado')
        time.sleep(1)


def cut_background(png_bytes, tol=40):
    """Quita el fondo liso rellenando desde los bordes y lo deja transparente."""
    im = Image.open(io.BytesIO(png_bytes)).convert('RGB')
    mark = im.copy()
    w, h = mark.size
    for x, y in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]:
        ImageDraw.floodfill(mark, (x, y), (255, 0, 255), thresh=tol)
    rgba = im.convert('RGBA')
    px, mp = rgba.load(), mark.load()
    for j in range(h):
        for i in range(w):
            if mp[i, j] == (255, 0, 255): px[i, j] = (0, 0, 0, 0)
    buf = io.BytesIO()
    rgba.save(buf, 'PNG')
    return buf.getvalue()


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    opt = lambda k, d: sys.argv[sys.argv.index(k) + 1] if k in sys.argv else d
    if len(args) < 2: sys.exit(__doc__)
    kind, key = args[0], args[1]
    if kind == 'arma':
        prompt, dest = '%s. %s' % (armas.WEAPONS[key], armas.STYLE), os.path.join(armas.OUT, key + '.png')
    elif kind == 'objeto':
        prompt, dest = '%s. %s' % (objetos.ITEMS[key], armas.STYLE), os.path.join(objetos.OUT, key + '.png')
    else:
        prompt, dest = key + '. ' + armas.STYLE, None
        key = opt('--nombre', 'libre')
    seeds = int(opt('--semillas', '1'))
    os.makedirs(TEST, exist_ok=True)
    open(os.path.join(TEST, '.gdignore'), 'a').close()
    for k in range(seeds):
        seed = int(opt('--semilla', '1000')) + k
        t0 = time.time()
        png = generate(prompt, seed)
        raw = os.path.join(TEST, '%s_%d.png' % (key, seed))
        open(raw, 'wb').write(png)
        icon = os.path.join(TEST, '%s_%d_icono.png' % (key, seed))
        armas.finish(cut_background(png), icon)
        print('ok %s semilla %d en %.0f s -> %s' % (key, seed, time.time() - t0, icon))
        if k == 0 and '--usar' in sys.argv and dest:
            armas.finish(cut_background(png), dest)
            print('   copiado como icono del juego:', dest)


if __name__ == '__main__': main()
