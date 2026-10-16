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
    de los faroles que se mecen, truenos y el viento en bucle (sin costura: el final se funde con
    el principio)."""
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
    m = int(fade * SR)
    loop = w[:int(d * SR)].copy()
    loop[:m] = loop[:m] * np.linspace(0, 1, m) + w[int(d * SR):int(d * SR) + m] * np.linspace(1, 0, m)
    x = loop / (np.max(np.abs(loop)) + 1e-9) * 0.9                    # save() con fundido al final rompería el bucle
    with wave.open(os.path.join(OUT, 'wind_loop.wav'), 'wb') as wv:
        wv.setnchannels(1); wv.setsampwidth(2); wv.setframerate(SR)
        wv.writeframes((x * 32767).astype(np.int16).tobytes())


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
