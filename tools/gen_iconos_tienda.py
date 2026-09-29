"""Iconos en voxel de la tienda (hito 2.13b): los artículos sin icono dibujado.
- icono_codicia: montones de monedas de oro con alguna suelta (Codicia).
- icono_funda: funda de cuero con la culata de un revólver asomando (quinta arma).
- icono_bolsillo: bolsita de cuero con solapa y botón de latón (quinto objeto).
Estilo 4 (tramos de caras planas, detalles pintados), a 48 voxels por metro.
Uso: python tools/gen_iconos_tienda.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from cuerpo import slab, new
import materiales

GOLD = (0.95, 0.74, 0.28); GOLD_SH = (0.78, 0.56, 0.18); GOLD_HI = (1.0, 0.88, 0.5)
LEATHER = (0.50, 0.30, 0.15); LEATHER_SH = (0.38, 0.22, 0.11); STITCH = (0.82, 0.70, 0.48)
BRASS = (0.82, 0.66, 0.32)
WOOD = (0.36, 0.20, 0.10); STEEL = (0.30, 0.31, 0.34)
P = 'body'


def export(M, name):
    materiales.texturize(M, {LEATHER: 'cuero', LEATHER_SH: 'cuero'})
    n = M.export('models/%s.json' % name, {P: [0, 0, 0]}, jitter=0.0, pivots_in_voxels=True, roughness=0.5, specular=0.5)
    print(name, n, 'voxels')


# ---- Codicia: tres montones de monedas y dos sueltas
M = new(1)
for cx, cz, h in ((0, 0, 8), (9, -3, 5), (-7, 5, 3)):
    for i in range(h):
        c = GOLD if i % 2 == 0 else GOLD_SH
        slab(M, P, c, i * 2, i * 2 + 2, cx, cz, 9, 9, 9, 9, ch=3)
    slab(M, P, GOLD_HI, h * 2 - 1, h * 2, cx, cz, 5, 5, 5, 5, ch=1)          # brillo de la de arriba
for cx, cz in ((6, 8), (-10, -5)):
    slab(M, P, GOLD, 0, 1, cx, cz, 9, 9, 9, 9, ch=3)
    slab(M, P, GOLD_HI, 1, 2, cx, cz, 5, 5, 5, 5, ch=1)
export(M, 'icono_codicia')

# ---- Quinta funda: funda con la culata del revólver
M = new(2)
slab(M, P, LEATHER, 0, 18, 0, 0, 7, 9, 5, 5, ch=1)                          # cuerpo de la funda
slab(M, P, LEATHER_SH, 14, 18, 0, 0, 10, 10, 5.5, 5.5, ch=1)                # boca
slab(M, P, LEATHER_SH, 18, 27, 0, -3, 4, 4, 2, 2, ch=0)                     # presilla del cinturón
for y in range(1, 14, 2):                                                   # pespunte
    z = M.front(-3, y)
    if z is not None: M.put(-3, y, z, P, STITCH)
slab(M, P, WOOD, 18, 26, 1, 1, 4, 4, 4, 4, ch=1)                            # culata
slab(M, P, WOOD, 24, 28, 2.5, 1, 6, 6, 4, 4, ch=1)
slab(M, P, STEEL, 18, 21, -1.5, 1, 3, 3, 3, 3, ch=0)                        # gatillo y martillo
slab(M, P, STEEL, 26, 29, -1, 1, 3, 3, 2.5, 2.5, ch=0)
slab(M, P, BRASS, 8, 10, 0, 3, 3, 3, 1, 1, ch=0)                            # remache
export(M, 'icono_funda')

# ---- Quinto bolsillo: bolsita de cuero con solapa y botón
M = new(3)
slab(M, P, LEATHER, 0, 14, 0, 0, 16, 18, 8, 9, ch=2)
slab(M, P, LEATHER_SH, 9, 15, 0, 0.5, 18.5, 18.5, 9.5, 9.5, ch=2)           # solapa
slab(M, P, LEATHER_SH, 5, 9, 0, 4.5, 6, 3, 1, 1, ch=0)                      # pico de la solapa
slab(M, P, BRASS, 5, 8, 0, 5.5, 3, 3, 1, 1, ch=0)                           # botón
for x in range(-8, 9, 2):                                                   # pespunte de la solapa
    z = M.front(x, 10)
    if z is not None: M.put(x, 10, z, P, STITCH)
slab(M, P, LEATHER_SH, 15, 17, 0, 0, 12, 12, 2, 2, ch=0)                    # asa
export(M, 'icono_bolsillo')
