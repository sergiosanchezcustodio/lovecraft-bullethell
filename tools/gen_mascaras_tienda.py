"""Máscaras para animar la ilustración de la tienda (resources/PantallasMenus/tienda.png).

Como la portada: no se pinta nada encima, se modula la imagen con un mapa de máscaras.
Salida: resources/PantallasMenus/mascara_tienda.png, a la resolución de la ilustración:
  R  llamas (quinqué y velas): el núcleo claro y cálido de cada una;
  G  brillos mágicos (bola de cristal y frascos violetas y verdes);
  B  luz que proyectan las llamas (las llamas difuminadas): oscila con ellas;
  A  fase propia de cada llama o brillo (0..1), para que no titilen a la vez.
Y shots/mascaras_tienda_revision.png para revisarlas.
Uso: python tools/gen_mascaras_tienda.py
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

os.chdir(os.path.join(os.path.dirname(__file__), '..'))
SRC = 'resources/PantallasMenus/tienda.png'
OUT = 'resources/PantallasMenus/mascara_tienda.png'

img = np.asarray(Image.open(SRC).convert('RGB')).astype(np.float32) / 255.0
r, g, b = img[..., 0], img[..., 1], img[..., 2]
v = img.max(axis=2)
H, W = v.shape

# llamas: lo muy claro y cálido, pero solo junto a las llamas de verdad (lista revisada a
# mano, en píxeles de la ilustración): la detección sola marcaba superficies iluminadas
# (el libro abierto, el borde del mostrador, la calavera) que no deben titilar.
# Si cambia la ilustración, vuelve a ejecutar el script y revisa esta lista.
FLAMES = [(255, 468, 34), (177, 470, 14), (680, 250, 12), (897, 300, 12), (909, 312, 12)]
yy, xx = np.mgrid[0:H, 0:W]
near = np.zeros((H, W), bool)
for fx, fy, rad in FLAMES: near |= (xx - fx) ** 2 + (yy - fy) ** 2 <= rad * rad
flame = near & (v > 0.7) & (r > 0.8) & (r - b > 0.25)
flame = ndimage.binary_dilation(flame, iterations=2) & near
# brillos mágicos: violetas (bola de cristal, frascos) y verdes (frascos)
violet = (v > 0.45) & (b > 0.5) & (r > 0.35) & (g < 0.45) & (b - g > 0.25)
green = (v > 0.4) & (g > 0.45) & (g - r > 0.12) & (g - b > 0.12)
magic = ndimage.binary_opening(violet | green, iterations=1)
magic = ndimage.binary_dilation(magic, iterations=2)
# zonas que no son brillos aunque lo parezcan (el hombro del anciano)
for x0, y0, x1, y1 in ((330, 350, 420, 410),):
    magic[y0:y1, x0:x1] = False

# quitar manchas diminutas (reflejos sueltos)
def keep_big(m, min_px):
    lab, n = ndimage.label(m)
    if n == 0: return m, lab, 0
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    keep = np.isin(lab, [i + 1 for i, s in enumerate(sizes) if s >= min_px])
    lab, n = ndimage.label(keep)
    return keep, lab, n

flame, flab, fn = keep_big(flame, 6)
magic, mlab, mn = keep_big(magic, 40)

soft_flame = ndimage.gaussian_filter(flame.astype(np.float32), 1.2)
soft_magic = ndimage.gaussian_filter(magic.astype(np.float32), 1.5)
glow = ndimage.gaussian_filter(flame.astype(np.float32), 38.0)
glow = glow / max(glow.max(), 1e-6)

# fase por mancha, extendida a su alrededor (la luz proyectada titila con su llama)
rng = np.random.default_rng(3)
phase = np.zeros((H, W), np.float32)
labels = np.zeros((H, W), np.int32)
labels[flame] = flab[flame]
labels[magic & (labels == 0)] = mlab[magic & (labels == 0)] + fn
if labels.max() > 0:
    idx = ndimage.distance_transform_edt(labels == 0, return_distances=False, return_indices=True)
    nearest = labels[idx[0], idx[1]]
    table = rng.random(labels.max() + 1).astype(np.float32)
    phase = table[nearest]

out = np.stack([np.clip(soft_flame * 1.6, 0, 1), np.clip(soft_magic * 1.4, 0, 1), np.clip(glow, 0, 1), phase], axis=-1)
Image.fromarray((out * 255).astype(np.uint8), 'RGBA').save(OUT)
print('llamas', fn, 'brillos', mn, '->', OUT)

# revisión: la ilustración con las máscaras teñidas encima
rev = (img * 0.45).copy()
rev[..., 0] = np.clip(rev[..., 0] + soft_flame, 0, 1)
rev[..., 1] = np.clip(rev[..., 1] + soft_magic, 0, 1)
rev[..., 2] = np.clip(rev[..., 2] + glow * 0.5, 0, 1)
Image.fromarray((rev * 255).astype(np.uint8)).save('shots/mascaras_tienda_revision.png')
