"""Capturas de comparación de las 15 arenas (hito 13.14).

Fotografía cada nivel de la campaña desde los mismos puntos (`PUNTOS`), sin enemigos, sin clima
y con el escenario quieto (`no_spawn=true changes=0 weather=no`), en calidad Baja y Alta, y
las compara con las de referencia: diferencia media por bloques de 40 px (sin el centro, donde
está el investigador, que se mueve un poco en reposo, ni el HUD). La referencia se captura dos
veces: los bloques que ya cambian entre esas dos (llamas, gotas en los charcos, chispas) son
«zona viva» (`<captura>.ruido.json`) y no cuentan al comparar. Monta una hoja con la referencia y la
actual, los bloques que cambian marcados en rojo y el porcentaje cambiado.

Uso:
  python tools/comparar_arenas.py --referencia      (guarda las de ahora como referencia)
  python tools/comparar_arenas.py                   (captura y compara con la referencia)
  python tools/comparar_arenas.py --niveles p1_n1,p3_n2 --calidades 2 --solo-comparar
  python tools/comparar_arenas.py --niveles p1_n1 --extra "arte=v1"   (opciones para la partida)
Salida: shots/comparar_arenas/{referencia,actual}/ y shots/comparar_arenas/hoja.png.
Dos ejecuciones de Godot a la vez como mucho (memoria). Sin sonido (--audio-driver Dummy).
"""
import concurrent.futures, glob, json, os, shutil, subprocess, sys, time
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'shots', 'comparar_arenas')
PUNTOS = ['0,0', '10,8']                      # dónde se pone el investigador en cada arena
SHOT_AT = [2.5, 5.0]                          # s de juego de cada captura (tras saltar a su punto)
QUALITY_NAMES = {0: 'Baja', 1: 'Media', 2: 'Alta', 3: 'Ultra'}
BLOCK = 40
THRESHOLD = 9.0                               # diferencia media por canal (0..255) para marcar un bloque
MASK = (0.44, 0.36, 0.56, 0.62)               # centro (fracciones x0, y0, x1, y1): el investigador


def levels():
    d = json.load(open(os.path.join(ROOT, 'data', 'campaign.json'), encoding='utf-8'))
    return [lv['id'] for p in d['parts'] for lv in p['levels']]


def godot():
    return shutil.which('godot') or 'godot'


EXTRA = ''                                    # --extra "clave=valor …": más opciones para la partida


def capture(level, q, dest):
    """Una ejecución por nivel y calidad: salta a cada punto y captura."""
    tag = 'arena_%s_q%d' % (level, q)
    for f in glob.glob(os.path.join(ROOT, 'shots', 'game_%s_*.png' % tag)): os.remove(f)
    cmd = ['bash', '-lc', '%s --path . --audio-driver Dummy -- level=%s god=true bot=idle mute=true no_spawn=true changes=0 '
           'weather=no cfg_quality=%d tour="%s" tour_at=0.5 tour_every=2.5 shots=%s tag=%s %s'
           % ('godot', level, q, ';'.join(PUNTOS), ','.join(str(s) for s in SHOT_AT), tag, EXTRA)]
    subprocess.run(cmd, cwd=ROOT, capture_output=True, timeout=180)
    files = sorted(glob.glob(os.path.join(ROOT, 'shots', 'game_%s_*.png' % tag)))
    os.makedirs(dest, exist_ok=True)
    for i, f in enumerate(files):
        shutil.move(f, os.path.join(dest, '%s_q%d_%d.png' % (level, q, i)))
    return len(files)


def diff(a, b, skip=()):
    """Bloques que cambian (x, y, w, h) y la fracción cambiada, sin el centro. Compara las dos
    imágenes reducidas a 1/4 y algo difuminadas: lo que parpadea o se mueve unos píxeles (llamas,
    copos, el aliento) casi no cuenta; un modelo que falta, otra luz u otro color, sí."""
    import numpy as np
    from PIL import ImageFilter
    W, H = a.size
    small = (W // 4, H // 4)
    A = np.asarray(a.convert('RGB').resize(small, Image.BILINEAR).filter(ImageFilter.GaussianBlur(1.5)), dtype=np.float32)
    B = np.asarray(b.convert('RGB').resize(small, Image.BILINEAR).filter(ImageFilter.GaussianBlur(1.5)), dtype=np.float32)
    D = np.abs(A - B).mean(axis=2)
    bs = BLOCK // 4
    mx0, my0, mx1, my1 = MASK[0] * W, MASK[1] * H, MASK[2] * W, MASK[3] * H
    marked, total = [], 0
    for y in range(0, H, BLOCK):
        for x in range(0, W, BLOCK):
            if mx0 <= x + BLOCK / 2 <= mx1 and my0 <= y + BLOCK / 2 <= my1: continue
            if y < 160 and (x < 560 or 760 < x < 1160): continue      # el HUD de arriba (panel y reloj)
            if (x, y) in skip: continue
            total += 1
            if D[y // 4:y // 4 + bs, x // 4:x // 4 + bs].mean() > THRESHOLD: marked.append((x, y, BLOCK, BLOCK))
    return marked, len(marked) / max(total, 1)


def sheet(rows, out):
    TW, TH = 384, 216
    font = ImageFont.truetype('C:/Windows/Fonts/georgia.ttf', 18)
    big = ImageFont.truetype('C:/Windows/Fonts/georgia.ttf', 22)
    quals = sorted({q for r in rows for q in r['q']})
    W = 200 + len(quals) * (TW * 2 + 16)
    S = Image.new('RGB', (W, 40 + len(rows) * (TH + 10)), (16, 14, 12))
    d = ImageDraw.Draw(S)
    for k, q in enumerate(quals):
        x0 = 200 + k * (TW * 2 + 16)
        d.text((x0, 8), '%s · referencia' % QUALITY_NAMES[q], fill=(200, 190, 170), font=big)
        d.text((x0 + TW, 8), '%s · ahora' % QUALITY_NAMES[q], fill=(230, 210, 160), font=big)
    for j, r in enumerate(rows):
        y = 40 + j * (TH + 10)
        d.text((10, y + 70), r['level'], fill=(230, 210, 160), font=big)
        d.text((10, y + 100), 'punto %s' % PUNTOS[r['i']], fill=(170, 160, 150), font=font)
        for k, q in enumerate(quals):
            x0 = 200 + k * (TW * 2 + 16)
            info = r['q'].get(q)
            if info is None: continue
            if info['ref']: S.paste(Image.open(info['ref']).convert('RGB').resize((TW, TH)), (x0, y))
            else: d.text((x0 + 20, y + 90), 'sin referencia', fill=(170, 160, 150), font=font)
            cur = Image.open(info['cur']).convert('RGB')
            sx, sy = TW / cur.width, TH / cur.height
            cur = cur.resize((TW, TH))
            dc = ImageDraw.Draw(cur)
            for (bx, by, bw, bh) in info['marked']:
                dc.rectangle((bx * sx, by * sy, (bx + bw) * sx, (by + bh) * sy), outline=(255, 40, 40), width=2)
            S.paste(cur, (x0 + TW, y))
            if info['ref']:
                frac = info['frac']
                col = (120, 220, 120) if frac < 0.02 else ((255, 200, 80) if frac < 0.1 else (255, 90, 70))
                d.rectangle((x0 + TW + 6, y + 6, x0 + TW + 120, y + 34), fill=(0, 0, 0))
                d.text((x0 + TW + 12, y + 8), '%.1f %%' % (100 * frac), fill=col, font=big)
    S.save(out)


def main():
    global EXTRA
    a = sys.argv[1:]
    ref = '--referencia' in a
    if '--extra' in a: EXTRA = a[a.index('--extra') + 1]
    lv = a[a.index('--niveles') + 1].split(',') if '--niveles' in a else levels()
    qs = [int(x) for x in a[a.index('--calidades') + 1].split(',')] if '--calidades' in a else [0, 2]
    dest = os.path.join(OUT, 'referencia' if ref else 'actual')
    if '--solo-comparar' not in a:
        t0 = time.time()
        jobs = [(l, q) for l in lv for q in qs]
        with concurrent.futures.ThreadPoolExecutor(2) as ex:      # dos a la vez como mucho (memoria)
            for (l, q), n in zip(jobs, ex.map(lambda j: capture(j[0], j[1], dest), jobs)):
                print('%s %s: %d capturas' % (l, QUALITY_NAMES[q], n), flush=True)
        print('capturas en %.0f s' % (time.time() - t0))
    if ref:                                   # otra vez, para saber qué cambia solo (zona viva)
        alt = os.path.join(OUT, 'referencia_b')
        with concurrent.futures.ThreadPoolExecutor(2) as ex:
            list(ex.map(lambda j: capture(j[0], j[1], alt), jobs))
        for f in glob.glob(os.path.join(dest, '*.png')):
            b = os.path.join(alt, os.path.basename(f))
            if not os.path.exists(b): continue
            live, frac = diff(Image.open(f), Image.open(b))
            grow = {(x + dx * BLOCK, y + dy * BLOCK) for (x, y, _, _) in live for dx in (-1, 0, 1) for dy in (-1, 0, 1)}
            json.dump(sorted(grow), open(f[:-4] + '.ruido.json', 'w'))
            print('%-24s zona viva: %.1f %%' % (os.path.basename(f), 100 * frac))
        shutil.rmtree(alt, ignore_errors=True)
        print('referencia guardada en', dest)
        return
    rows, worst = [], []
    for l in lv:
        for i in range(len(PUNTOS)):
            r = {'level': l, 'i': i, 'q': {}}
            for q in qs:
                cur = os.path.join(OUT, 'actual', '%s_q%d_%d.png' % (l, q, i))
                if not os.path.exists(cur): continue
                rp = os.path.join(OUT, 'referencia', '%s_q%d_%d.png' % (l, q, i))
                info = {'cur': cur, 'ref': rp if os.path.exists(rp) else None, 'marked': [], 'frac': 0.0}
                if info['ref']:
                    noise = rp[:-4] + '.ruido.json'
                    skip = {tuple(v) for v in json.load(open(noise))} if os.path.exists(noise) else set()
                    info['marked'], info['frac'] = diff(Image.open(rp), Image.open(cur), skip)
                    worst.append((info['frac'], l, PUNTOS[i], QUALITY_NAMES[q]))
                r['q'][q] = info
            rows.append(r)
    out = os.path.join(OUT, 'hoja.png')
    sheet(rows, out)
    for frac, l, p, q in sorted(worst, reverse=True)[:8]:
        print('%-6s %-5s punto %-5s %5.1f %% cambiado' % (l, q, p, 100 * frac))
    print('hoja:', out)


if __name__ == '__main__':
    main()
