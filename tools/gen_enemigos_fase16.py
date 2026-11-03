"""Piezas de los enemigos nuevos de la fase 16 (bloque C).
  vaina_esporas   hito 16.16: la vaina que planta el Antiguo sembrador (una mina). Un bulbo de
                  piel parda con vetas, medio enterrado en un montón de tierra y escarcha, con un
                  núcleo amarillo enfermizo que brilla por las rendijas y tres filamentos arriba.
Los cuerpos van en sus generadores de siempre: el shoggoth excavador es el fragmento a S=3 con
costra de hielo (`python tools/gen_fragmento.py 3 shoggoth_excavador 1940`) y el Antiguo
sembrador, una variante de `tools/gen_antiguo.py`.
Uso: python tools/gen_enemigos_fase16.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model, lerp

SAC = (0.46, 0.40, 0.22); SAC_D = (0.28, 0.24, 0.14); SPORE = (0.86, 0.80, 0.36); SPORE_L = (1.0, 0.95, 0.60)
DIRT = (0.20, 0.17, 0.14); DIRT_D = (0.12, 0.10, 0.09); FROST = (0.78, 0.84, 0.90)


def vaina():
    M = Model(S=2, seed=1616)
    M.ell(0, 0.4, 0, 4.2, 1.4, 4.0, 'body', DIRT)                     # montón de tierra
    M.ell(0, 3.6, 0, 2.8, 3.4, 2.8, 'body', SAC)                      # el bulbo
    M.ell(0, 3.8, 0, 2.0, 2.6, 2.0, 'body', SPORE, glow=1)             # núcleo
    M.ell(0, 6.8, 0, 1.2, 1.0, 1.2, 'body', SAC_D)                    # cuello
    for i in range(3):                                                # filamentos
        a = i / 3 * math.tau + 0.4
        M.capsule((0, 7.2, 0), (math.cos(a) * 1.6, 9.4, math.sin(a) * 1.6), 0.45, 0.3, 'body', SAC_D)
        M.ell(math.cos(a) * 1.7, 9.6, math.sin(a) * 1.7, 0.55, 0.55, 0.55, 'body', SPORE_L, glow=1)
    for (x, y, z), v in M.V.items():
        if v[1] == SAC:                                               # vetas y rendijas que dejan ver el núcleo
            h = M.hsh(x, y // 2, z)
            if h > 0.86: v[1] = SAC_D
        if v[1] == DIRT:
            n = M.noise(x, y, z, 2.5)
            v[1] = FROST if n > 0.68 and y >= 1 else (DIRT_D if n < 0.35 else DIRT)
    # rendijas: quita piel encima del núcleo en franjas verticales para que asome el brillo
    for (x, y, z) in [k for k, v in M.V.items() if v[1] in (SAC, SAC_D) and 3 <= k[1] <= 11]:
        a = math.atan2(z, x)
        if math.cos(a * 5) > 0.93 and M.exposed((x, y, z)): del M.V[(x, y, z)]
    for k in [k for k in M.V if k[1] < 0]: del M.V[k]
    n = M.export('models/vaina_esporas.json', {'body': [0, 0, 0]}, jitter=0.012, roughness=0.55, specular=0.4)
    print('vaina_esporas', n, 'voxels')


if __name__ == '__main__':
    vaina()
