"""Efectos de sonido (fase 8, hito 8.1).

1) Sintetiza lo que no hay en los bancos CC0 de Kenney (disparos, rugidos, gruñidos, chapoteos,
   olas, el zumbido de los Ángulos) con numpy: ruido filtrado, envolventes y barridos de tono.
   Son nuestros: libres como el resto.
2) Copia de los packs CC0 de Kenney (kenney.nl: Impact Sounds, Interface Sounds, RPG Audio y
   Sci-Fi Sounds) los que usa el juego, con el nombre de su evento.

Escribe resources/sfx/<nombre>.wav (sintetizados) y resources/sfx/<nombre>_N.ogg (Kenney).
La tabla de qué suena en cada evento está en data/sfx.json.
Uso: python tools/gen_sfx.py <carpeta con los packs de Kenney descomprimidos>
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
    synth()
    if len(sys.argv) > 1: copy_kenney(sys.argv[1])
    print('listo en', OUT)
