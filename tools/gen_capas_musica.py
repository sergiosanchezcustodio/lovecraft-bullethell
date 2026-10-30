"""Capas de la música (hito 13.13, provisionales): una de percusión por parte y una de coros por
pista, que `Music` suma a la pista del nivel según los enemigos vivos (y solo los coros con el
jefe). Las pistas son CC0 sin capas, así que se sintetizan aquí:

- Coros: seis voces en vocales (formantes) que cantan la nota base de la pista, su quinta y su
  octava, en frases largas que crecen y se apagan. La nota base sale del cromagrama de la pista
  (la clase de altura con más energía). Bucle de 24 s sin costura (todo es periódico y el eco se
  calcula en círculo).
- Percusión: tambores rituales lejanos, sueltos (sin un compás que choque con la pista), con un
  timbre por parte: hielo y pieles graves en la Antártida, tambores de mano y sonajas en
  Innsmouth, tambores enormes y metal en R'lyeh. Bucle de 16 s.

Escribe resources/Music/capas/*.ogg y la tabla `capas` de data/musica.json (pista -> coros,
percusión y nota). Cambia cualquier capa por la tuya poniendo su ruta en esa tabla.
Uso: python tools/gen_capas_musica.py            (todas)
     python tools/gen_capas_musica.py --solo p2_n2_night_of_the_streets.ogg
Necesita ffmpeg en el PATH.
"""
import json, os, subprocess, sys, tempfile, wave, zlib
import numpy as np
from scipy import signal

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'resources', 'Music', 'capas')
DATA = os.path.join(ROOT, 'data', 'musica.json')
SR = 44100
NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
PART_OF = {'p1': 'p1', 'p2': 'p2', 'p3': 'p3', 'jefe_heavy': 'p1', 'jefe_bio': 'p2', 'jefe_a_dispirited': 'p3'}


def t(dur): return np.arange(int(dur * SR)) / SR
def lp(x, f, order=2): return signal.lfilter(*signal.butter(order, f / (SR / 2), 'low'), x)
def hp(x, f, order=2): return signal.lfilter(*signal.butter(order, f / (SR / 2), 'high'), x)
def bp(x, lo, hi): return signal.lfilter(*signal.butter(2, [lo / (SR / 2), hi / (SR / 2)], 'band'), x)


def circ(fn, x):
    """Aplica un filtro sin el arranque: dos vueltas seguidas y se queda con la segunda (bucle)."""
    n = len(x)
    return fn(np.concatenate([x, x]))[n:]


def reverb_circ(x, r, tail, decay, cut):
    """Eco en círculo (la cola del final cae al principio): el bucle no tiene costura."""
    n = len(x)
    ir = r.standard_normal(int(tail * SR)) * np.exp(-t(tail) / decay)
    ir = lp(ir, cut)
    full = np.zeros(n); full[:min(len(ir), n)] = ir[:n]
    wet = np.real(np.fft.ifft(np.fft.fft(x) * np.fft.fft(full)))
    return wet * np.std(x) / (np.std(wet) + 1e-9)


def decode(path):
    """La pista en mono a 11025 Hz (para el cromagrama), con ffmpeg."""
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-ar', '11025', '-f', 'f32le', '-'],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def root_of(path):
    """Nota base: la clase de altura (0 = do) con más energía entre 55 y 1760 Hz."""
    x = decode(path)
    sr, win = 11025, 8192
    chroma = np.zeros(12)
    freqs = np.fft.rfftfreq(win, 1 / sr)
    ok = (freqs > 55) & (freqs < 1760)
    pc = (np.round(12 * np.log2(freqs[ok] / 261.63)) % 12).astype(int)
    w = np.hanning(win)
    for i in range(0, len(x) - win, win // 2):
        mag = np.abs(np.fft.rfft(x[i:i + win] * w))[ok]
        np.add.at(chroma, pc, mag ** 2)
    return int(np.argmax(chroma)), chroma / (chroma.sum() + 1e-9)


VOW = {'a': ((650, 5), (1080, 7), (2650, 9)), 'o': ((420, 5), (760, 7), (2500, 9)),
       'u': ((310, 5), (700, 7), (2300, 9))}


def coros(root, seed):
    """Seis voces graves en la nota base, su quinta y su octava; frases que crecen y se apagan."""
    r = np.random.default_rng(seed)
    d = 24.0
    n = int(d * SR)
    tt = np.arange(n) / SR
    base = 261.63 * 2 ** (root / 12)
    while base > 150: base /= 2                          # voces graves: entre 75 y 150 Hz
    # vocales que se funden despacio (periódicas en el bucle)
    k = 2 * np.pi / d
    wa = 0.5 + 0.5 * np.cos(k * 2 * tt)
    wo = 0.5 + 0.5 * np.cos(k * 2 * tt + 2.1)
    wu = 0.5 + 0.5 * np.cos(k * 2 * tt + 4.2)
    s = wa + wo + wu
    weights = {'a': wa / s, 'o': wo / s, 'u': wu / s}
    out = np.zeros(n)
    voices = [(1, 0.0), (1, 0.5), (1.5, 0.25), (1.5, 0.75), (2, 0.125), (0.5, 0.6)]   # (intervalo, fase de su frase)
    for i, (mult, phase) in enumerate(voices):
        f0 = base * mult
        cycles = round(f0 * d) + (i % 3 - 1)              # un pelín desafinadas, pero periódicas
        f0 = cycles / d
        vib = 0.004 * np.sin(2 * np.pi * (round((4.6 + 0.3 * i) * d) / d) * tt)
        ph = np.cumsum(f0 * (1 + vib)) / SR
        src = 2 * (ph % 1.0) - 1
        voice = np.zeros(n)
        for v, forms in VOW.items():
            fv = sum(circ(lambda y: signal.lfilter(*signal.iirpeak(fc / (SR / 2), q), y), src) for fc, q in forms)
            voice += fv * weights[v]
        # frase: crece unos 5 s, se sostiene y se apaga; dos frases por vuelta, cada voz a destiempo
        u = (tt / d * 2 + phase) % 1.0
        env = np.sin(np.pi * u) ** 1.6
        out += voice * env * (0.7 if mult < 1 else 1.0)
    out = circ(lambda y: lp(y, 1400), out)
    out += reverb_circ(out, r, 3.0, 0.9, 1500) * 1.1
    return out


def golpe(f0, decay, noise_amt, r, dur=2.0, bend=0.5):
    """Un golpe de tambor: tono que cae al sonar más el roce de la piel."""
    tt = t(dur)
    f = f0 * (1 + bend * np.exp(-tt / 0.04))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * np.exp(-tt / decay) * (1 - np.exp(-tt / 0.003))
    x += lp(r.standard_normal(len(tt)), 900) * np.exp(-tt / (decay * 0.35)) * noise_amt
    return x


PERC = {
    # (tono del golpe grave, caída, roce, golpes ligeros: (tono, caída), adorno)
    'p1': {'deep': (48.0, 0.55, 0.4), 'light': (110.0, 0.18), 'extra': 'hielo'},
    'p2': {'deep': (62.0, 0.35, 0.7), 'light': (180.0, 0.09), 'extra': 'sonaja'},
    'p3': {'deep': (38.0, 0.9, 0.5), 'light': (90.0, 0.3), 'extra': 'metal'},
}


def percusion(part, seed):
    """Tambores rituales lejanos: grupos de dos o tres golpes graves con otros ligeros entre medias,
    a un pulso libre (unos 70 golpes por minuto, con holgura) y silencios. 16 s en bucle."""
    r = np.random.default_rng(seed)
    p = PERC[part]
    d = 16.0
    n = int(d * SR)
    out = np.zeros(n)
    beat = 60.0 / 70.0
    tpos = 0.0
    while tpos < d:
        group = r.integers(2, 4)
        for g in range(group):
            at = tpos + g * beat * 0.5 + r.normal(0, 0.012)
            hit = golpe(p['deep'][0] * r.uniform(0.97, 1.03), p['deep'][1], p['deep'][2], r) * r.uniform(0.7, 1.0)
            _put(out, hit, at)
        for _ in range(r.integers(1, 4)):                 # golpes ligeros entre medias
            at = tpos + r.uniform(0.2, group * beat * 0.5 + beat)
            _put(out, golpe(p['light'][0] * r.uniform(0.9, 1.1), p['light'][1], 0.8, r, 0.8, 0.3) * r.uniform(0.2, 0.45), at)
        if p['extra'] == 'sonaja':
            at = tpos + r.uniform(0, beat)
            m = int(0.35 * SR)
            _put(out, bp(r.standard_normal(m), 3000, 8000) * np.exp(-np.arange(m) / (0.08 * SR)) * 0.25, at)
        elif p['extra'] == 'hielo' and r.random() < 0.5:
            at = tpos + r.uniform(0, beat * 2)
            m = int(0.25 * SR)
            tk = np.arange(m) / SR
            _put(out, np.sin(2 * np.pi * r.uniform(2400, 3600) * tk) * np.exp(-tk / 0.04) * 0.15, at)
        elif p['extra'] == 'metal' and r.random() < 0.4:
            at = tpos + r.uniform(0, beat * 2)
            m = int(2.5 * SR)
            tk = np.arange(m) / SR
            gong = sum(np.sin(2 * np.pi * f * tk) / (1 + j) for j, f in enumerate((210, 337, 512, 741)))
            _put(out, gong * np.exp(-tk / 0.9) * 0.08, at)
        tpos += group * beat * 0.5 + beat * r.choice([1.5, 2.0, 2.5, 3.0])
    out = circ(lambda y: lp(y, 2500), out)
    out = out * 0.7 + reverb_circ(out, r, 2.5, 0.6, 1200) * 0.6       # lejos, en una sala grande
    return out


def _put(buf, x, at):
    """Suma `x` en `buf` desde `at` s, dando la vuelta al final (bucle)."""
    n = len(buf)
    i = int(at * SR) % n
    m = len(x)
    end = min(n, i + m)
    buf[i:end] += x[:end - i]
    if i + m > n: buf[:i + m - n] += x[end - i:]


def write_ogg(name, x, rms_db=-24.0):
    """Normaliza a un RMS fijo (todas las capas igual de fuertes) y escribe OGG con ffmpeg."""
    x = np.asarray(x, dtype=np.float64)
    x = x * (10 ** (rms_db / 20) / (np.sqrt(np.mean(x ** 2)) + 1e-12))
    peak = np.max(np.abs(x))
    if peak > 0.95: x *= 0.95 / peak
    path = os.path.join(OUT, name + '.ogg')
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tf:
        tmp = tf.name
    with wave.open(tmp, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', tmp, '-c:a', 'libvorbis', '-q:a', '3', path], check=True)
    os.remove(tmp)
    return 'res://resources/Music/capas/%s.ogg' % name


def tracks():
    """Las pistas de los niveles y de los jefes (`music` y `boss_music` de data/levels)."""
    out = {}
    for f in sorted(os.listdir(os.path.join(ROOT, 'data', 'levels'))):
        if not f.endswith('.tres'): continue
        for line in open(os.path.join(ROOT, 'data', 'levels', f), encoding='utf-8'):
            for key in ('music = ', 'boss_music = '):
                if line.startswith(key):
                    out[line.split('"')[1]] = f[:2]
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    only = sys.argv[sys.argv.index('--solo') + 1] if '--solo' in sys.argv else None
    raw = open(DATA, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in raw else '\n'
    d = json.loads(raw)
    capas = d.get('capas', {})
    for part in ('p1', 'p2', 'p3'):
        if only is None: write_ogg('percusion_' + part, percusion(part, 1300 + int(part[1])))
    for res, part in tracks().items():
        stem = os.path.splitext(os.path.basename(res))[0]
        if only and os.path.basename(res) != only: continue
        root, chroma = root_of(os.path.join(ROOT, res.replace('res://', '')))
        path = write_ogg('coros_' + stem, coros(root, zlib.crc32(stem.encode()) % 10000))
        capas[res] = {'coros': path, 'percusion': 'res://resources/Music/capas/percusion_%s.ogg' % part,
                      'nota': NOTES[root], 'claridad': round(float(np.max(chroma)), 3)}
        print('%-48s %-3s (%.0f %% de la energía)' % (stem, NOTES[root], 100 * np.max(chroma)))
    d['capas'] = {k: capas[k] for k in sorted(capas)}
    d['_capas'] = ('Capas de la música (hito 13.13, provisionales, tools/gen_capas_musica.py): para cada pista, '
                   'la de coros (a su nota base) y la de percusión (una por parte). Music las suma según los '
                   'enemigos vivos y deja solo los coros con el jefe. Cambia cualquiera por la tuya poniendo aquí su ruta.')
    with open(DATA, 'w', encoding='utf-8', newline='') as f:
        f.write(json.dumps(d, ensure_ascii=False, indent='\t').replace('\n', nl) + nl)


if __name__ == '__main__':
    main()
