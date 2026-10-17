"""Efectos de sonido (fase 8, hito 8.1).

1) Sintetiza lo que no hay en los bancos CC0 de Kenney (disparos, rugidos, gruñidos, chapoteos,
   olas, el zumbido de los Ángulos) con numpy: ruido filtrado, envolventes y barridos de tono.
   Son nuestros: libres como el resto.
2) Copia de los packs CC0 de Kenney (kenney.nl: Impact Sounds, Interface Sounds, RPG Audio y
   Sci-Fi Sounds) los que usa el juego, con el nombre de su evento.

Escribe resources/sfx/<nombre>.wav (sintetizados) y resources/sfx/<nombre>_N.ogg (Kenney).
La tabla de qué suena en cada evento está en data/sfx.json.
Uso: python tools/gen_sfx.py <carpeta con los packs de Kenney descomprimidos>
     python tools/gen_sfx.py --ambiente   (solo los del ambiente de los escenarios)
"""
import os, sys, shutil, wave, glob
import numpy as np
from scipy import signal

ROOT = os.path.join(os.path.dirname(__file__), '..')
OUT = os.path.join(ROOT, 'resources', 'sfx')
SR = 44100
rng = np.random.default_rng(1926)


def save(name, x):
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.9
    fade = min(len(x), int(0.01 * SR))
    x[-fade:] *= np.linspace(1, 0, fade)
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())


def t(dur): return np.arange(int(dur * SR)) / SR
def noise(dur): return rng.standard_normal(int(dur * SR))
def env(dur, attack=0.002, decay=0.1):
    tt = t(dur)
    return np.minimum(tt / attack, 1.0) * np.exp(-tt / decay)
def lp(x, f, order=2): return signal.lfilter(*signal.butter(order, f / (SR / 2), 'low'), x)
def hp(x, f, order=2): return signal.lfilter(*signal.butter(order, f / (SR / 2), 'high'), x)
def bp(x, lo, hi): return signal.lfilter(*signal.butter(2, [lo / (SR / 2), hi / (SR / 2)], 'band'), x)


def shot(dur, crack_f, body_f, decay, thump=0.6):
    """Disparo: chasquido agudo + cuerpo de ruido grave + golpe de baja frecuencia."""
    n = noise(dur)
    crack = hp(n, crack_f) * env(dur, 0.0005, 0.012)
    body = lp(n, body_f) * env(dur, 0.001, decay)
    tt = t(dur)
    boom = np.sin(2 * np.pi * (90 * tt - 60 * tt ** 2)) * env(dur, 0.001, decay * 0.8) * thump
    return crack * 0.8 + body + boom


def growl(dur, f0, f1, rough, seed_shift=0):
    """Gruñido: tono grave que baja (de f0 a f1) con armónicos, modulado por ruido (rasposo)."""
    tt = t(dur)
    f = np.linspace(f0, f1, len(tt)) * (1 + 0.04 * np.sin(2 * np.pi * 7 * tt))
    ph = 2 * np.pi * np.cumsum(f) / SR
    tone = np.sin(ph) + 0.6 * np.sin(2 * ph + 0.3) + 0.4 * np.sin(3 * ph) + 0.25 * np.sin(5 * ph)
    am = 1 + rough * lp(noise(dur), 60)
    e = np.minimum(tt / 0.08, 1.0) * np.minimum((dur - tt) / 0.25, 1.0)
    return lp(tone * am, 1800) * e + lp(noise(dur), 700) * e * 0.35


def synth():
    save('shot_revolver', shot(0.45, 3000, 1400, 0.07))
    save('shot_rifle', shot(0.6, 3500, 1800, 0.10, 0.8))
    save('shot_shotgun', shot(0.7, 2200, 900, 0.14, 1.0))
    save('shot_smg', shot(0.22, 3500, 1600, 0.035, 0.4))
    tt = t(0.5)                                              # hoja: silbido que sube
    sw = bp(noise(0.5), 1500, 6000) * np.exp(-((tt - 0.12) / 0.06) ** 2)
    save('swing', sw)
    save('roar', growl(2.2, 95, 55, 0.9))                    # jefes: rugido largo
    save('growl', growl(0.9, 140, 100, 0.7))                 # élites y minijefes
    save('screech', growl(0.6, 700, 420, 0.5) + bp(noise(0.6), 2500, 6000) * env(0.6, 0.02, 0.2) * 0.5)  # diablos, pesadillas
    d = 0.8                                                  # chapoteo
    save('splash', bp(noise(d), 300, 4000) * env(d, 0.005, 0.18) + lp(noise(d), 300) * env(d, 0.01, 0.3) * 0.6)
    d = 2.0                                                  # ola que rompe
    tt = t(d)
    surge = np.sin(np.pi * np.clip(tt / d, 0, 1)) ** 2
    save('wave', lp(noise(d), 900) * surge + bp(noise(d), 2000, 7000) * surge ** 3 * 0.4)
    d = 2.5                                                  # Ángulos: zumbido que no cuadra (dos tonos casi iguales)
    tt = t(d)
    z = np.sin(2 * np.pi * 55 * tt) + np.sin(2 * np.pi * 58.7 * tt) + 0.5 * np.sin(2 * np.pi * 233 * tt + np.sin(2 * np.pi * 3 * tt) * 4)
    save('angles', z * np.minimum(tt / 0.4, 1) * np.minimum((d - tt) / 0.5, 1))
    d = 1.2                                                  # cántico: coro grave y lejano para los ataques mentales
    tt = t(d)
    c = sum(np.sin(2 * np.pi * f * tt * (1 + 0.003 * np.sin(2 * np.pi * 5 * tt + k))) for k, f in enumerate((110, 164.8, 220, 277.2)))
    save('chant', lp(c, 1200) * np.minimum(tt / 0.15, 1) * np.minimum((d - tt) / 0.4, 1))


def ambiente():
    """Sonidos de ambiente de los escenarios (16-10-2026), con su propio azar para no cambiar los
    de synth(): gotas en la gruta con su eco, golpes de ola contra el casco, crujidos del gancho
    de los faroles que se mecen, truenos, el viento y la lluvia en bucle (sin costura: el final se
    funde con el principio), los graznidos de las bandadas, el fuego, los crujidos del suelo y la
    lluvia tras los cristales del estudio, el cántico de los cultistas, la bandera y los pasos."""
    r = np.random.default_rng(1016)
    def nz(d): return r.standard_normal(int(d * SR))
    def cave(x, tail=0.9, level=0.25):                       # eco de cueva: cola de ruido que decae
        ir = r.standard_normal(int(tail * SR)) * np.exp(-t(tail) / (tail * 0.28))
        ir = lp(ir, 1800)
        ir[0] = 0
        wet = signal.fftconvolve(x, ir)[:len(x) + len(ir) - 1]
        out = np.zeros(len(wet)); out[:len(x)] += x
        return out + wet / (np.max(np.abs(wet)) + 1e-9) * np.max(np.abs(x)) * level
    for i, (f0, rise) in enumerate(((1050, 1.9), (1380, 1.6), (880, 2.2))):
        d = 0.18                                             # gota: tono que sube (la burbuja) y se apaga
        tt = t(d)
        f = f0 * (1 + rise * tt / d)
        tone = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / 0.035) * np.minimum(tt / 0.001, 1)
        click = hp(nz(d), 3000) * np.exp(-tt / 0.003) * 0.15
        save('drip_%d' % i, cave(tone + click))
    for i in range(2):                                       # ola contra el casco: golpe sordo y rocío
        d = 1.8
        tt = t(d)
        thud = np.sin(2 * np.pi * (70 + 15 * i) * tt) * np.exp(-tt / 0.12) * np.minimum(tt / 0.004, 1)
        body = lp(nz(d), 700) * np.exp(-tt / 0.35) * np.minimum(tt / 0.01, 1)
        late = np.clip((tt - 0.15) / 0.1, 0, 1)
        hiss = bp(nz(d), 1800, 7000) * late * np.exp(-np.clip(tt - 0.15, 0, None) / 0.5) * 0.45
        save('wave_hit_%d' % i, thud * 0.9 + body + hiss)
    for i, (rate, fres) in enumerate(((38, 950), (55, 1400), (28, 700))):
        d = 0.7                                              # crujido: tirones del gancho (pegar y soltar)
        tt = t(d)
        rr = rate * (1 + 0.5 * np.sin(np.pi * tt / d) + 0.15 * np.sin(2 * np.pi * 7 * tt))
        ph = np.cumsum(rr) / SR
        pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * (0.6 + 0.4 * r.random(len(tt)))
        b, a = signal.iirpeak(fres / (SR / 2), 9)
        res = signal.lfilter(b, a, pulses) + 0.5 * signal.lfilter(*signal.iirpeak(fres * 2.3 / (SR / 2), 12), pulses)
        save('creak_%d' % i, res * np.sin(np.pi * tt / d) ** 1.5)
    for i in range(2):                                       # trueno: estallido y retumbo que se aleja
        d = 4.5
        tt = t(d)
        crack = bp(nz(d), 900, 5000) * np.exp(-tt / 0.06)
        crack /= np.max(np.abs(crack))
        rumble = hp(lp(nz(d), 130 - 30 * i, 4), 25)              # grave: cada parte con su propio nivel
        rumble /= np.std(rumble)
        rolls = lp(nz(d), 2.5, 1)
        rolls = np.clip(0.75 + 0.5 * rolls / np.std(rolls), 0.2, 1.6)  # retumbos que van y vienen
        tail = np.minimum(tt / 0.3, 1) * np.exp(-tt / 1.5)
        save('thunder_%d' % i, crack * 0.25 + rumble * rolls * tail * 0.3)
    d, fade = 12.0, 2.0                                      # viento en bucle
    n = int((d + fade) * SR)
    tt = np.arange(n) / SR
    g = lp(r.standard_normal(n), 0.25, 1)                   # rachas lentas
    g = np.clip(0.6 + 0.35 * g / (np.std(g) + 1e-9), 0.15, 1.6)
    base = lp(r.standard_normal(n), 500) * g
    whistle = np.zeros(n)
    for fc, ph in ((620, 0.0), (910, 1.7)):                  # silbido que sube y baja con las rachas
        fsw = fc * (1 + 0.25 * np.sin(2 * np.pi * tt / 5.3 + ph))
        k = 0
        step = 2048
        out = np.zeros(n)
        src = r.standard_normal(n)
        while k < n:
            bb, aa = signal.iirpeak(min(fsw[k], SR / 2 - 100) / (SR / 2), 25)
            out[k:k + step] = signal.lfilter(bb, aa, src[k:k + step])
            k += step
        whistle += out * g ** 2 * 0.25
    w = base + whistle
    save_loop('wind_loop', w, d, fade)
    aves(r)
    lluvia(r)
    fuego(r)
    estudio(r)
    cantico(r)
    bandera(r)
    pasos(r)
    fuente(r)
    campana(r)
    ranas(r)
    susurros(r)


def save_loop(name, w, d, fade):
    """Bucle sin costura: los `fade` s de después del final se funden con el principio (save()
    haría un fundido a cero al final y se oiría el corte)."""
    m = int(fade * SR)
    loop = w[:int(d * SR)].copy()
    a = np.linspace(0, np.pi / 2, m)                         # potencia constante: el ruido no baja en la junta
    loop[:m] = loop[:m] * np.sin(a) + w[int(d * SR):int(d * SR) + m] * np.cos(a)
    x = loop / (np.max(np.abs(loop)) + 1e-9) * 0.9
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as wv:
        wv.setnchannels(1); wv.setsampwidth(2); wv.setframerate(SR)
        wv.writeframes((x * 32767).astype(np.int16).tobytes())


def _voice(f, rough, r, formants=((2200, 6),), harm=6):
    """Voz de ave: armónicos sobre la línea de tono f (Hz por muestra), aspereza (ruido que
    modula la amplitud) y formantes (picos que le dan el timbre nasal o ronco)."""
    ph = 2 * np.pi * np.cumsum(f) / SR
    v = sum(np.sin(k * ph) / k ** 0.7 for k in range(1, harm + 1))
    am = 1 + rough * bp(r.standard_normal(len(f)), 60, 160) / 0.08
    v = v * np.clip(am, 0, 3)
    out = np.zeros(len(v))
    for fc, q in formants:
        out += signal.lfilter(*signal.iirpeak(fc / (SR / 2), q), v)
    return out + v * 0.15


def _notes(parts, gap):
    """Une notas (arrays) con silencios de `gap` s."""
    sil = np.zeros(int(gap * SR))
    out = []
    for i, n in enumerate(parts):
        if i: out.append(sil)
        out.append(n)
    return np.concatenate(out)


def aves(r):
    """Graznidos para las bandadas del ambiente (16-10-2026): gaviota (un grito largo, la risa y
    dos gritos), cuervo (dos y tres graznidos roncos) y murciélago (chillidos cortos que bajan)."""
    def gull(d, f_lo, f_hi, f_end):
        n = int(d * SR)
        x = np.linspace(0, 1, n)
        f = np.where(x < 0.18, f_lo + (f_hi - f_lo) * x / 0.18, f_hi + (f_end - f_hi) * (x - 0.18) / 0.82)
        f = f * (1 + 0.012 * np.sin(2 * np.pi * 23 * np.arange(n) / SR))
        e = np.minimum(x / 0.06, 1) * np.minimum((1 - x) / 0.25, 1)
        return _voice(f, 0.25, r, ((2400, 5), (3600, 8))) * e
    save('bird_gull_0', gull(0.55, 950, 1750, 1150))
    save('bird_gull_1', _notes([gull(0.16, 1200 - 60 * k, 1650 - 70 * k, 1300 - 60 * k) for k in range(5)], 0.06))
    save('bird_gull_2', _notes([gull(0.4, 1000, 1700, 1250), gull(0.45, 950, 1600, 1100)], 0.18))
    def caw(d, f0):
        n = int(d * SR)
        x = np.linspace(0, 1, n)
        f = f0 * (1.08 - 0.15 * x) * (1 + 0.03 * lp(r.standard_normal(n), 30) / 0.02)
        e = np.minimum(x / 0.08, 1) * np.minimum((1 - x) / 0.3, 1)
        return _voice(f, 0.9, r, ((1300, 4), (2600, 6)), harm=10) * e
    save('bird_crow_0', _notes([caw(0.32, 560), caw(0.3, 540)], 0.16))
    save('bird_crow_1', _notes([caw(0.28, 600), caw(0.3, 580), caw(0.34, 550)], 0.14))
    def squeak(d, f0, f1):
        n = int(d * SR)
        x = np.linspace(0, 1, n)
        f = f0 + (f1 - f0) * x
        return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.sin(np.pi * x) ** 2
    for i in range(2):
        parts = [squeak(0.035 + 0.015 * r.random(), 4200 + 600 * r.random(), 2600 + 400 * r.random()) for _ in range(4 + i)]
        save('bird_bat_%d' % i, _notes(parts, 0.07 + 0.03 * i))


def _bursts(r, n, rate, amp, length):
    """Tren de chasquidos al azar: `rate` por segundo, cada uno un golpe de ruido de `length` s."""
    imp = np.zeros(n)
    k = r.integers(0, n, int(rate * n / SR))
    imp[k] = r.uniform(amp[0], amp[1], len(k)) * r.choice([-1, 1], len(k))
    m = int(length * SR)
    kern = r.standard_normal(m) * np.exp(-np.arange(m) / (m * 0.25))
    return signal.fftconvolve(imp, kern)[:n]


def fuego(r):
    """Fuego en bucle (16-10-2026): rumor grave que aletea, siseo y chasquidos de la leña, con
    algún estallido; sin costura. Las hogueras y las antorchas del ritual (Ambient, "sound")."""
    d, fade = 8.0, 2.0
    n = int((d + fade) * SR)
    flick = lp(r.standard_normal(n), 3, 1)
    flick = np.clip(0.75 + 0.35 * flick / np.std(flick), 0.3, 1.5)
    roar = lp(r.standard_normal(n), 260) * flick
    roar /= np.std(roar)
    hiss = bp(r.standard_normal(n), 2200, 6500) * flick
    hiss /= np.std(hiss)
    small = bp(_bursts(r, n, 28, (0.2, 0.7), 0.004), 1500, 7000)
    pops = bp(_bursts(r, n, 1.6, (0.8, 1.0), 0.012), 600, 5000)
    w = roar * 0.35 + hiss * 0.05 + small / (np.std(small) + 1e-9) * 0.12 + pops / (np.max(np.abs(pops)) + 1e-9) * 0.9
    save_loop('fire_loop', w, d, fade)


def estudio(r):
    """El estudio (16-10-2026): crujidos de las tablas del suelo (pegar y soltar lento, con el
    cuerpo grave de la madera) y la lluvia oída tras los ventanales (apagada, con golpecitos de
    gota en el cristal), en bucle."""
    for i, (rate, f1, f2, d) in enumerate(((16, 260, 520, 0.8), (22, 330, 760, 0.6), (12, 210, 430, 1.0))):
        tt = t(d)
        rr = rate * (1 + 0.6 * np.sin(np.pi * tt / d) ** 2 + 0.2 * np.sin(2 * np.pi * 3 * tt + i))
        ph = np.cumsum(rr) / SR
        pulses = (np.diff(np.floor(ph), prepend=0) > 0).astype(float) * (0.5 + 0.5 * r.random(len(tt)))
        body = signal.lfilter(*signal.iirpeak(f1 / (SR / 2), 7), pulses) + 0.6 * signal.lfilter(*signal.iirpeak(f2 / (SR / 2), 10), pulses)
        body += 0.25 * signal.lfilter(*signal.iirpeak(f2 * 2.7 / (SR / 2), 14), pulses)
        save('floor_creak_%d' % i, lp(body, 3000) * np.sin(np.pi * tt / d) ** 1.2)
    d, fade = 10.0, 2.0
    n = int((d + fade) * SR)
    muffled = lp(hp(r.standard_normal(n), 120), 1100)
    muffled /= np.std(muffled)
    taps = np.zeros(n)
    for fc in (2900, 3600, 4400):                            # gotas que dan en el cristal
        imp = np.zeros(n)
        k = r.integers(0, n, int(14 * n / SR))
        imp[k] = r.uniform(0.3, 1.0, len(k))
        taps += signal.lfilter(*signal.iirpeak(fc / (SR / 2), 30), imp)
    taps /= np.max(np.abs(taps)) + 1e-9
    w = muffled * 0.3 + taps * 0.55
    save_loop('rain_window_loop', w, d, fade)


def save_raw(name, x):
    """Sin fundido al final (bucles que ya son periódicos)."""
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.9
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as wv:
        wv.setnchannels(1); wv.setsampwidth(2); wv.setframerate(SR)
        wv.writeframes((x * 32767).astype(np.int16).tobytes())


def cantico(r):
    """Cántico lejano de los cultistas (16-10-2026): un coro grave que salmodia "Ph'nglui mglw'nafh
    Cthulhu R'lyeh wgah'nagl fhtagn" sobre una nota recitada, siete voces algo desafinadas y a
    destiempo, vocales por formantes y eco de lejos. Dos rezos de 8 s; la junta cae en el silencio
    entre rezos y el eco se calcula en círculo: el bucle no tiene costura."""
    cycle, reps = 8.0, 2
    d = cycle * reps
    n = int(d * SR)
    VOW = {'a': ((650, 5), (1080, 7), (2650, 9)), 'o': ((420, 5), (760, 7), (2500, 9)),
           'u': ((310, 5), (700, 7), (2300, 9)), 'i': ((300, 5), (1850, 8), (2700, 9))}
    rezo = [('a', 0, .5), ('u', 0, .45), ('i', -2, .45), ('a', 0, .6), ('u', -3, .55), ('o', 0, .45),
            ('a', 0, .5), ('u', -2, .7), ('o', 0, .45), ('a', -3, .5), ('a', 0, .45), ('u', -5, 1.0)]
    vow_w = {v: np.zeros(n) for v in VOW}
    env = np.zeros(n)
    note = np.zeros(n)
    cons = np.zeros(n)
    for c in range(reps):
        t0 = c * cycle + 0.2
        for k, (v, semi, dur) in enumerate(rezo):
            if c == 1 and k == len(rezo) - 1: semi = -7                   # el segundo rezo acaba más abajo
            a0, a1 = int(t0 * SR), int((t0 + dur) * SR)
            m = a1 - a0
            x = np.linspace(0, 1, m)
            e = np.minimum(x * dur / 0.07, 1) * np.minimum((1 - x) * dur / 0.09, 1)
            env[a0:a1] = np.maximum(env[a0:a1], e)
            vow_w[v][a0:a1] = np.maximum(vow_w[v][a0:a1], e)
            note[a0:a1] = semi
            cb = min(int(0.03 * SR), m)
            cons[a0:a0 + cb] += np.exp(-np.arange(cb) / (cb * 0.3))
            t0 += dur + 0.04
    note = lp(note, 12)                                       # deslizar de una nota a otra
    for v in vow_w: vow_w[v] = lp(vow_w[v], 25)
    chorus = np.zeros(n)
    for i in range(7):
        f0 = (98.0 if i < 5 else 65.4) * (1 + r.uniform(-0.012, 0.012))
        shift = int(r.uniform(-0.05, 0.05) * SR)
        f = f0 * 2 ** (np.roll(note, shift) / 12) * (1 + 0.004 * np.sin(2 * np.pi * (4.5 + i * 0.3) * np.arange(n) / SR))
        ph = np.cumsum(f) / SR
        src = 2 * (ph % 1.0) - 1                              # diente de sierra: la voz antes de la boca
        voice = np.zeros(n)
        for v, forms in VOW.items():
            fv = sum(signal.lfilter(*signal.iirpeak(fc / (SR / 2), q), src) for fc, q in forms)
            voice += fv * np.roll(vow_w[v], shift)
        chorus += voice * np.roll(env, shift)
    chorus += bp(r.standard_normal(n), 1500, 5000) * cons * 0.4      # consonantes
    chorus = lp(chorus, 1600)                                        # lejos
    tail = 2.5
    ir = r.standard_normal(int(tail * SR)) * np.exp(-t(tail) / 0.7)
    ir = lp(ir, 1200)
    ir_full = np.zeros(n); ir_full[:len(ir)] = ir
    wet = np.real(np.fft.ifft(np.fft.fft(chorus) * np.fft.fft(ir_full)))   # eco en círculo: sin costura
    wet *= np.std(chorus) / (np.std(wet) + 1e-9)
    save_raw('chant_loop', chorus * 0.55 + wet * 0.8)


def bandera(r):
    """Bandera que aletea (16-10-2026): ráfagas de tela que golpea a 6-14 veces por segundo y algún
    chasquido; en bucle. Ambient la sube con las rachas del clima."""
    d, fade = 8.0, 2.0
    n = int((d + fade) * SR)
    rate = lp(r.standard_normal(n), 0.8, 1)
    rate = 9 + 4 * rate / np.std(rate)
    ph = np.cumsum(np.clip(rate, 5, 15)) / SR
    am = (0.5 + 0.5 * np.sin(2 * np.pi * ph)) ** 4
    gust = lp(r.standard_normal(n), 0.4, 1)
    gust = np.clip(0.7 + 0.35 * gust / np.std(gust), 0.25, 1.4)
    cloth = bp(r.standard_normal(n), 180, 2600) * am * gust
    cloth /= np.std(cloth)
    snaps = bp(_bursts(r, n, 0.9, (0.6, 1.0), 0.006), 700, 4500)
    w = cloth * 0.5 + snaps / (np.max(np.abs(snaps)) + 1e-9) * 0.8 * np.repeat(gust[::1], 1)
    save_loop('flag_loop', w, d, fade)


def pasos(r):
    """Pasos (16-10-2026), cuatro de cada: nieve que cruje, tablas, piedra, barro y agua somera."""
    for i in range(4):
        d = 0.22
        tt = t(d)
        imp = np.zeros(len(tt)); k = r.integers(0, int(0.12 * SR), 120); imp[k] = r.uniform(0.2, 1, len(k))
        crunch = bp(imp, 900, 5000) * np.minimum(tt / 0.012, 1) * np.exp(-tt / 0.07)
        save('step_snow_%d' % i, crunch + lp(r.standard_normal(len(tt)), 220) * np.exp(-tt / 0.04) * 0.6)
        d = 0.18
        tt = t(d)
        f0 = 140 + 30 * r.random()
        knock = np.sin(2 * np.pi * f0 * tt) * np.exp(-tt / 0.04) + 0.5 * np.sin(2 * np.pi * (480 + 60 * r.random()) * tt) * np.exp(-tt / 0.022)
        save('step_wood_%d' % i, knock + hp(r.standard_normal(len(tt)), 2000) * np.exp(-tt / 0.002) * 0.4)
        d = 0.16
        tt = t(d)
        tap = bp(r.standard_normal(len(tt)), 1500, 6000) * np.exp(-tt / 0.006)
        scuff = bp(r.standard_normal(len(tt)), 700, 3000) * np.exp(-((tt - 0.05) / 0.035) ** 2) * 0.35
        save('step_stone_%d' % i, tap + scuff + np.sin(2 * np.pi * 90 * tt) * np.exp(-tt / 0.03) * 0.5)
        d = 0.26
        tt = t(d)
        fc = 300 + 700 * np.clip(tt / 0.16, 0, 1)
        nz = lp(r.standard_normal(len(tt)), 1500)
        out = np.zeros(len(tt)); step = 512
        for a0 in range(0, len(tt), step):                   # chapoteo de barro: resonancia que sube
            b, aa = signal.iirpeak(fc[a0] / (SR / 2), 6)
            out[a0:a0 + step] = signal.lfilter(b, aa, nz[a0:a0 + step])
        save('step_mud_%d' % i, out * np.minimum(tt / 0.01, 1) * np.exp(-tt / 0.09))
        d = 0.3
        tt = t(d)
        spl = bp(r.standard_normal(len(tt)), 400, 4500) * np.minimum(tt / 0.005, 1) * np.exp(-tt / 0.08)
        blub = np.sin(2 * np.pi * np.cumsum(600 + 2500 * tt) / SR) * np.exp(-np.maximum(tt - 0.04, 0) / 0.03) * (tt > 0.04) * 0.3
        save('step_water_%d' % i, spl + blub)


def fuente(r):
    """Chorro de la fuente que cae en el pilón (16-10-2026): chapoteo continuo, con burbujas
    (tonos que suben, como las gotas) y algún golpe más fuerte; en bucle."""
    d, fade = 8.0, 2.0
    n = int((d + fade) * SR)
    flow = bp(r.standard_normal(n), 500, 5000)
    flow /= np.std(flow)
    mod = lp(r.standard_normal(n), 6, 1)
    flow *= np.clip(0.8 + 0.4 * mod / np.std(mod), 0.3, 1.4)
    bub = np.zeros(n)
    for k in r.integers(0, n - int(0.05 * SR), int(45 * (d + fade))):
        m = int(r.uniform(0.012, 0.03) * SR)
        tt = np.arange(m) / SR
        f0 = r.uniform(500, 1600)
        bub[k:k + m] += np.sin(2 * np.pi * np.cumsum(f0 * (1 + 2.5 * tt / tt[-1])) / SR) * np.exp(-tt / (m / SR * 0.35)) * r.uniform(0.3, 1)
    w = flow * 0.35 + bub * 0.45
    save_loop('fountain_loop', w, d, fade)


def campana(r):
    """Campanada grave y lejana (la campana del templo de la Orden, 16-10-2026): parciales
    inarmónicos de campana (hum, fundamental, tercera menor, quinta, octava...) que decaen cada uno
    a su ritmo, con un golpe del badajo y algo de batido; apagada por la distancia."""
    d = 7.0
    tt = t(d)
    f0 = 196.0
    parts = ((0.5, 1.0, 4.5), (1.0, 0.9, 3.2), (1.19, 0.55, 2.4), (1.5, 0.35, 1.8), (2.0, 0.45, 1.6),
             (2.51, 0.22, 1.0), (2.66, 0.18, 0.9), (3.01, 0.15, 0.7), (4.1, 0.08, 0.45))
    x = np.zeros(len(tt))
    for k, (ratio, amp, dec) in enumerate(parts):
        beat = 1 + 0.06 * np.sin(2 * np.pi * (0.7 + 0.3 * k) * tt)
        x += amp * np.sin(2 * np.pi * f0 * ratio * tt + k) * np.exp(-tt / dec) * beat
    x *= np.minimum(tt / 0.004, 1)
    x += hp(r.standard_normal(len(tt)), 1500) * np.exp(-tt / 0.01) * 0.3
    x = lp(x, 2200)
    ir = r.standard_normal(int(1.5 * SR)) * np.exp(-t(1.5) / 0.45)
    ir = lp(ir, 1500)
    wet = signal.fftconvolve(x, ir)[:len(x)]
    wet *= np.std(x) / (np.std(wet) + 1e-9)
    save('bell_0', x * 0.75 + wet * 0.5)


def ranas(r):
    """Croar de ranas (16-10-2026): dos ranas pequeñas (un "cric-cric" de pulsos rápidos y agudos)
    y dos grandes (el mugido grave y zumbón de la rana toro)."""
    for i, (f0, pulses, rate, dur_p) in enumerate(((620, 3, 11, 0.045), (540, 2, 9, 0.05))):
        out = []
        for k in range(pulses):
            m = int(dur_p * SR)
            tt = np.arange(m) / SR
            ph = 2 * np.pi * np.cumsum(f0 * (1 + 0.15 * tt / tt[-1]) * np.ones(m)) / SR
            buzz = np.sign(np.sin(ph)) * 0.6 + np.sin(ph)
            am = (0.5 + 0.5 * np.sin(2 * np.pi * 90 * tt)) * np.sin(np.pi * tt / tt[-1])
            out.append(bp(buzz * am, 300, 3000))
            out.append(np.zeros(int(SR / rate) - m))
        save('frog_%d' % i, np.concatenate(out))
    for i, f0 in enumerate((110, 92)):
        d = 0.55
        tt = t(d)
        f = f0 * (1 - 0.12 * tt / d)
        ph = 2 * np.pi * np.cumsum(f) / SR
        tone = sum(np.sin(k * ph) / k for k in range(1, 8))
        am = 1 + 0.5 * np.sin(2 * np.pi * 24 * tt)
        e = np.minimum(tt / 0.04, 1) * np.minimum((d - tt) / 0.12, 1)
        save('frog_%d' % (i + 2), lp(tone * am * e, 1100))


def lluvia(r):
    """Lluvia en bucle (16-10-2026): cortina de ruido, miles de gotas que golpean (clics con
    timbre al azar) y un fondo grave; sin costura."""
    d, fade = 10.0, 2.0
    n = int((d + fade) * SR)
    curtain = hp(lp(r.standard_normal(n), 6000), 350) * 0.5
    drops = np.zeros(n)
    k = r.integers(0, n, int(260 * (d + fade)))
    drops[k] = r.uniform(0.2, 1.0, len(k)) * r.choice([-1, 1], len(k))
    ticks = np.zeros(n)
    for lo, hi in ((900, 2500), (2000, 5000), (3500, 8000)):
        ticks += bp(drops * (r.random(n) < 0.34), lo, hi)
    roar = lp(r.standard_normal(n), 380) * 0.6
    w = curtain + ticks * 2.2 + roar
    save_loop('rain_loop', w, d, fade)


# evento -> archivos de Kenney (se copian como <evento>_N.ogg)
KENNEY = {
    'hit': ['impactSoft_medium_000', 'impactSoft_medium_001', 'impactSoft_medium_002'],
    'hit_player': ['impactPunch_heavy_000', 'impactPunch_heavy_001', 'impactPunch_heavy_002'],
    'die': ['impactSoft_heavy_000', 'impactSoft_heavy_001', 'impactSoft_heavy_002', 'slime_000'],
    'explosion': ['explosionCrunch_000', 'explosionCrunch_001', 'explosionCrunch_002'],
    'slam': ['lowFrequency_explosion_000', 'lowFrequency_explosion_001'],
    'magic': ['forceField_000', 'forceField_001', 'forceField_002'],
    'beam': ['laserLarge_000', 'laserLarge_001'],
    'fire': ['thrusterFire_000', 'thrusterFire_001'],
    'dodge': ['cloth1', 'cloth2', 'cloth3'],
    'gem': ['tick_001', 'tick_002', 'tick_004'],
    'level_up': ['maximize_006', 'maximize_008'],
    'chest': ['handleCoins', 'handleCoins2'],
    'pickup': ['confirmation_002'],
    'ui_move': ['select_001', 'select_002'],
    'ui_accept': ['confirmation_001'],
    'ui_back': ['back_001'],
    'page': ['bookFlip1', 'bookFlip2', 'bookFlip3'],
    'glass': ['glass_001', 'glass_002'],
    'down': ['impactBell_heavy_000'],
}


def susurros(r):
    """Susurros en bucle (17-10-2026) para la cordura baja: varias voces que musitan frases sin
    sentido, solo aire (ruido por formantes de vocal, sin tono), con sibilantes y chasquidos de
    labios; unas cerca y claras, otras lejos y apagadas. Ambient lo sube cuanto menos cordura."""
    d, fade = 14.0, 2.0
    n = int((d + fade) * SR)
    VOW = [((700, 4), (1150, 6), (2600, 8)), ((450, 4), (800, 6), (2500, 8)), ((320, 4), (2200, 7), (2900, 8)),
           ((350, 4), (750, 6), (2350, 8)), ((550, 4), (1750, 6), (2550, 8))]
    out = np.zeros(n)
    for v in range(5):
        far = v >= 3
        voice = np.zeros(n)
        t0 = r.uniform(0, 1.5)
        while t0 < d + fade - 1.0:
            for _ in range(r.integers(3, 8)):                       # una frase: sílabas seguidas
                dur = r.uniform(0.09, 0.22)
                a0 = int(t0 * SR); m = int(dur * SR)
                if a0 + m >= n: break
                x = np.linspace(0, 1, m)
                e = np.sin(np.pi * x) ** 1.5
                src = r.standard_normal(m)
                fr = VOW[r.integers(len(VOW))]
                syl = sum(signal.lfilter(*signal.iirpeak(fc * r.uniform(0.9, 1.1) / (SR / 2), q), src) for fc, q in fr)
                voice[a0:a0 + m] += syl / (np.std(syl) + 1e-9) * e
                if r.random() < 0.45:                               # s, sh, f
                    sm = int(r.uniform(0.05, 0.14) * SR)
                    if a0 + m + sm < n:
                        sib = hp(r.standard_normal(sm), r.choice([3500, 5000, 6500]))
                        voice[a0 + m:a0 + m + sm] += sib / (np.std(sib) + 1e-9) * np.sin(np.pi * np.linspace(0, 1, sm)) * 0.7
                if r.random() < 0.08:                               # chasquido de labios
                    voice[a0] += 3.0
                t0 += dur + r.uniform(0.01, 0.06)
            t0 += r.uniform(0.8, 3.0)                               # respira
        voice = bp(voice, 250, 7500)
        if far: voice = lp(voice, 1800) * 0.45
        out += voice * r.uniform(0.6, 1.0)
    save_loop('whisper_loop', out, d, fade)


def copy_kenney(src):
    files = {os.path.splitext(os.path.basename(p))[0]: p for p in glob.glob(os.path.join(src, '**', '*.ogg'), recursive=True)}
    for ev, names in KENNEY.items():
        for i, n in enumerate(names):
            shutil.copy(files[n], os.path.join(OUT, '%s_%d.ogg' % (ev, i)))
    print('kenney:', sum(len(v) for v in KENNEY.values()), 'archivos')


if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    if '--ambiente' in sys.argv:                             # solo los del ambiente (no necesita Kenney)
        ambiente()
    else:
        synth()
        ambiente()
        if len(sys.argv) > 1: copy_kenney(sys.argv[1])
    print('listo en', OUT)
