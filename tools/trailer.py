"""Tráiler del juego (hito 13.16): graba las tomas del guion y las monta con rótulos y música.

  python tools/trailer.py                 graba las tomas que falten y monta el tráiler
  python tools/trailer.py --rehacer dagon,final   vuelve a grabar esas tomas (y monta)
  python tools/trailer.py --montar        solo monta, con las tomas ya grabadas (para cambiar rótulos o música;
                                          si cambias las opciones, 'desde' o 'dura' de una toma, sin --montar
                                          se vuelve a grabar sola)
  python tools/trailer.py --prueba antartida --s 20   graba 20 s de una toma desde el principio y hace
                                          una hoja con un fotograma por segundo (para elegir 'desde')

El guion está en tools/trailer_guion.json: tomas (opciones del juego, desde qué segundo y cuánto
duran), rótulos y música. Cada toma es una ejecución del juego con --write-movie a tiempo fijo
(AVI con MJPEG a calidad 0,95, `editor/movie_writer/mjpeg_quality` en project.godot, y el sonido
dentro: con PNG, Godot tarda medio segundo en guardar cada fotograma), que se pasa a un clip H.264
casi sin pérdida en shots/trailer/tomas/ y se borra el AVI. El montaje funde cada toma desde y hacia negro, pone
los rótulos (IM FELL English SC, como la portada), mezcla la música del guion con los efectos de
las tomas, y deja shots/videos/trailer.mp4 (1080p, 60 fps) y shots/trailer/hoja.png (un fotograma
por toma, para revisarlo de un vistazo). Una sola grabación a la vez: cada una ocupa la GPU entera.
"""
import glob, json, os, shutil, subprocess, sys, tempfile, time
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GUION = os.path.join(ROOT, 'tools', 'trailer_guion.json')
OUT = os.path.join(ROOT, 'shots', 'trailer')
TOMAS = os.path.join(OUT, 'tomas')
FONT = os.path.join(ROOT, 'resources', 'fonts', 'IMFeENsc28P.ttf')
FADE = 0.3                                      # s de fundido a negro al entrar y salir de cada toma
LOAD = 1.0                                      # s que se graban de más al final (por si el juego tarda en salir)


def guion():
    return json.load(open(GUION, encoding='utf-8'))


def run(cmd, **kw):
    return subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace', **kw)


def record(g, t, secs=None, start=None):
    """Graba la toma `t`: devuelve la carpeta temporal con f.avi (imagen y sonido)."""
    fps = g['fps']
    start = t['desde'] if start is None else start
    secs = t['dura'] if secs is None else secs
    tmp = tempfile.mkdtemp(prefix='toma_', dir=OUT)
    args = t['args'] + ('' if t.get('partida') is False else ' ' + g['comunes_partida'])
    frames = int((start + secs + LOAD) * fps)
    cmd = 'godot --path . --audio-driver Dummy --resolution %s --write-movie "%s" --fixed-fps %d --quit-after %d -- %s' % (
        g['resolucion'], os.path.join(tmp, 'f.avi'), fps, frames, args)
    t0 = time.time()
    r = run(['bash', '-lc', cmd], timeout=1800)
    avi = os.path.join(tmp, 'f.avi')
    ok = os.path.exists(avi) and os.path.getsize(avi) > 0
    print('  %s: %.0f MB en %.0f s' % (t['id'], os.path.getsize(avi) / 1e6 if ok else 0, time.time() - t0), flush=True)
    if not ok: print(r.stdout[-2000:], r.stderr[-2000:])
    return tmp


def encode(g, t, tmp):
    """Pasa el trozo [desde, desde+dura) de la toma a shots/trailer/tomas/<id>.mp4 y <id>.wav."""
    fps = g['fps']
    n = int(round(t['dura'] * fps))
    os.makedirs(TOMAS, exist_ok=True)
    mp4 = os.path.join(TOMAS, t['id'] + '.mp4')
    avi = os.path.join(tmp, 'f.avi')
    # el trozo, por fotogramas (select) y no por tiempo: así empieza justo en el fotograma de 'desde'
    first = int(round(t['desde'] * fps))
    run(['ffmpeg', '-y', '-loglevel', 'error', '-i', avi, '-vf', r'select=gte(n\,%d),setpts=PTS-STARTPTS' % first,
         '-frames:v', str(n), '-r', str(fps), '-c:v', 'libx264', '-preset', 'slow', '-crf', '12', '-pix_fmt', 'yuv420p', '-an', mp4])
    out = os.path.join(TOMAS, t['id'] + '.wav')
    r = run(['ffmpeg', '-y', '-loglevel', 'error', '-ss', str(t['desde']), '-t', str(t['dura']), '-i', avi,
             '-vn', '-ar', '48000', '-ac', '2', out])
    if r.returncode or not os.path.exists(out):   # sin sonido: silencio de la misma duración
        run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'lavfi', '-i', 'anullsrc=r=48000:cl=stereo',
             '-t', str(t['dura']), out])
    json.dump(cut_of(t), open(os.path.join(TOMAS, t['id'] + '.json'), 'w', encoding='utf-8'))
    shutil.rmtree(tmp, ignore_errors=True)
    return mp4


def cut_of(t):
    """Lo que hace falta para que una toma grabada siga valiendo: sus opciones y su corte."""
    return {'args': t['args'], 'desde': t['desde'], 'dura': t['dura']}


def stale(g, t):
    """La toma no está grabada, o se grabó con otras opciones u otro corte (hay que volver a grabarla)."""
    f = os.path.join(TOMAS, t['id'] + '.json')
    if not os.path.exists(os.path.join(TOMAS, t['id'] + '.mp4')) or not os.path.exists(f): return True
    return json.load(open(f, encoding='utf-8')) != cut_of(t)


def caption(text, path, top=False):
    """Rótulo en un PNG transparente de 1920x1080: letras claras con una sombra difusa detrás."""
    W, H = 1920, 1080
    font = ImageFont.truetype(FONT, 58)
    im = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    w = d.textlength(text, font=font)
    x, y = (W - w) / 2, (150 if top else H - 210)
    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).text((x, y), text, font=font, fill=(0, 0, 0, 235))
    shadow = shadow.filter(ImageFilter.GaussianBlur(9))
    im = Image.alpha_composite(im, shadow)
    im = Image.alpha_composite(im, shadow)
    d = ImageDraw.Draw(im)
    d.text((x, y), text, font=font, fill=(236, 222, 190, 255))
    im.save(path)


def starts(g):
    """Segundo del tráiler en que empieza cada toma."""
    s, at = {}, 0.0
    for t in g['tomas']:
        s[t['id']] = at
        at += t['dura']
    s[None] = at
    return s


def assemble(g):
    tomas = g['tomas']
    fps = g['fps']
    tmp = tempfile.mkdtemp(prefix='montaje_', dir=OUT)
    segs = []
    for i, t in enumerate(tomas):
        src = os.path.join(TOMAS, t['id'] + '.mp4')
        dur = t['dura']
        vf = ['fade=t=in:st=0:d=%.2f' % FADE, 'fade=t=out:st=%.3f:d=%.2f' % (dur - FADE, FADE)]
        inputs = ['-i', src]
        if t.get('rotulo'):
            cp = os.path.join(tmp, 'rotulo_%d.png' % i)
            caption(t['rotulo'], cp, t.get('rotulo_arriba', False))
            a, b = t.get('rotulo_desde', 0.4), t.get('rotulo_hasta', dur - 0.4)
            inputs += ['-loop', '1', '-t', str(dur), '-i', cp]
            fc = ('[1:v]format=rgba,fade=t=in:st=%.2f:d=0.5:alpha=1,fade=t=out:st=%.2f:d=0.5:alpha=1[c];'
                  '[0:v][c]overlay=0:0,%s[v]') % (a, b - 0.5, ','.join(vf))
        else:
            fc = '[0:v]%s[v]' % ','.join(vf)
        seg = os.path.join(tmp, 'seg_%02d.mp4' % i)
        r = run(['ffmpeg', '-y', '-loglevel', 'error'] + inputs + ['-filter_complex', fc, '-map', '[v]', '-r', str(fps),
                 '-frames:v', str(int(round(dur * fps))), '-c:v', 'libx264', '-preset', 'slow', '-crf', '12',
                 '-pix_fmt', 'yuv420p', seg])
        if r.returncode: print(r.stderr[-1500:])
        segs.append(seg)
    lst = os.path.join(tmp, 'lista.txt')
    open(lst, 'w', encoding='utf-8').write(''.join("file '%s'\n" % s.replace('\\', '/') for s in segs))
    video = os.path.join(tmp, 'video.mp4')
    run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', lst, '-c', 'copy', video])
    # sonido: los efectos de las tomas, seguidos y bajos, y la música por tramos con fundidos
    total = starts(g)[None]
    st = starts(g)
    sfx_list = os.path.join(tmp, 'sfx.txt')
    open(sfx_list, 'w', encoding='utf-8').write(''.join("file '%s'\n" % os.path.join(TOMAS, t['id'] + '.wav').replace('\\', '/') for t in tomas))
    sfx = os.path.join(tmp, 'sfx.wav')
    run(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', sfx_list, '-ar', '48000', '-ac', '2', sfx])
    ins, parts = ['-i', sfx], ['[0:a]volume=%.2f[s0]' % g.get('efectos', 0.4)]
    labels = ['[s0]']
    for k, m in enumerate(g['musica']):
        a = m['en'] if isinstance(m['en'], (int, float)) else st[m['en']]
        b = total if m['hasta'] is None else (m['hasta'] if isinstance(m['hasta'], (int, float)) else st[m['hasta']])
        a0 = max(0.0, a - 0.6)                 # cada tramo entra un poco antes y sale un poco después: se funden
        b1 = min(total, b + 0.6)
        ln = b1 - a0
        ins += ['-ss', str(m.get('desde', 0)), '-t', str(ln), '-i', os.path.join(ROOT, m['archivo'])]
        fo = min(2.5, ln / 3) if m['hasta'] is None else 1.2
        parts.append('[%d:a]aresample=48000,aformat=channel_layouts=stereo,volume=%.2f,afade=t=in:st=0:d=%.2f,'
                     'afade=t=out:st=%.2f:d=%.2f,adelay=%d|%d[m%d]' % (k + 1, m.get('volumen', 1.0), 0.05 if a0 == 0 else 1.2,
                                                                     ln - fo, fo, int(a0 * 1000), int(a0 * 1000), k))
        labels.append('[m%d]' % k)
    parts.append('%samix=inputs=%d:normalize=0:duration=longest,atrim=0:%.3f,alimiter=limit=0.9[a]' % (''.join(labels), len(labels), total))
    audio = os.path.join(tmp, 'audio.wav')
    r = run(['ffmpeg', '-y', '-loglevel', 'error'] + ins + ['-filter_complex', ';'.join(parts), '-map', '[a]', audio])
    if r.returncode: print(r.stderr[-1500:])
    dest = os.path.join(ROOT, 'shots', 'videos')
    os.makedirs(dest, exist_ok=True)
    final = os.path.join(dest, 'trailer.mp4')
    run(['ffmpeg', '-y', '-loglevel', 'error', '-i', video, '-i', audio, '-map', '0:v', '-map', '1:a', '-c:v', 'libx264',
         '-preset', 'slow', '-crf', '17', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-b:a', '192k', '-movflags', '+faststart',
         '-shortest', final])
    sheet(g, final)
    shutil.rmtree(tmp, ignore_errors=True)
    print('tráiler: %s (%.1f s)' % (final, total))


def sheet(g, video):
    """Un fotograma de la mitad de cada toma (o de su rótulo), con su nombre: para revisar."""
    st = starts(g)
    ims = []
    for t in g['tomas']:
        at = st[t['id']] + (t.get('rotulo_desde', 0) + t.get('rotulo_hasta', t['dura'])) / 2 if t.get('rotulo') else st[t['id']] + t['dura'] / 2
        f = os.path.join(OUT, '_f.png')
        run(['ffmpeg', '-y', '-loglevel', 'error', '-ss', '%.2f' % at, '-i', video, '-frames:v', '1', f])
        im = Image.open(f).convert('RGB').resize((640, 360))
        ImageDraw.Draw(im).text((8, 6), '%s  %.1f s' % (t['id'], at), fill=(255, 230, 150), font=ImageFont.truetype(FONT, 22))
        ims.append(im)
        os.remove(f)
    cols = 3
    S = Image.new('RGB', (640 * cols, 360 * ((len(ims) + cols - 1) // cols)), (10, 10, 10))
    for i, im in enumerate(ims): S.paste(im, ((i % cols) * 640, (i // cols) * 360))
    S.save(os.path.join(OUT, 'hoja.png'))


def probe(g, tid, secs):
    """Graba `secs` s de una toma desde el principio y hace una hoja con un fotograma por segundo."""
    t = next(t for t in g['tomas'] if t['id'] == tid)
    tmp = record(g, t, secs=secs, start=0.0)
    ims = []
    for s in range(int(secs)):
        f = os.path.join(tmp, 's.png')
        run(['ffmpeg', '-y', '-loglevel', 'error', '-ss', str(s), '-i', os.path.join(tmp, 'f.avi'), '-frames:v', '1', f])
        if not os.path.exists(f): break
        im = Image.open(f).convert('RGB').resize((480, 270))
        os.remove(f)
        ImageDraw.Draw(im).text((6, 4), '%d s' % s, fill=(255, 230, 150), font=ImageFont.truetype(FONT, 24))
        ims.append(im)
    cols = 5
    S = Image.new('RGB', (480 * cols, 270 * ((len(ims) + cols - 1) // cols)), (10, 10, 10))
    for i, im in enumerate(ims): S.paste(im, ((i % cols) * 480, (i // cols) * 270))
    out = os.path.join(OUT, 'prueba_%s.png' % tid)
    S.save(out)
    shutil.rmtree(tmp, ignore_errors=True)
    print('hoja:', out)


def main():
    a = sys.argv[1:]
    g = guion()
    os.makedirs(OUT, exist_ok=True)
    if '--prueba' in a:
        probe(g, a[a.index('--prueba') + 1], float(a[a.index('--s') + 1]) if '--s' in a else 15.0)
        return
    redo = set(a[a.index('--rehacer') + 1].split(',')) if '--rehacer' in a else set()
    if '--montar' not in a:
        for t in g['tomas']:
            if t['id'] in redo or stale(g, t):
                encode(g, t, record(g, t))
    else:
        old = [t['id'] for t in g['tomas'] if stale(g, t)]
        if old: print('ojo: %s no coinciden con el guion (opciones, desde o dura): grábalas con --rehacer %s' % (', '.join(old), ','.join(old)))
    assemble(g)


if __name__ == '__main__':
    main()
