"""Máscaras para animar la ilustración de la portada (resources/PantallasMenus/).

Analiza el fondo y genera, a 1920x1080 (alineadas con él):
- mascara_luces.png
    R: llamas (núcleo). Los reflejos en el suelo, a media intensidad.
    G: fase propia de cada llama (0-255), extendida a la zona que ilumina, para que su luz
       parpadee a la vez que ella.
    B: luz cálida que proyectan las llamas en paredes y suelo (difuminada).
- mascara_zonas.png
    R: cielo del ventanal por donde pasan las nubes (sin la tracería ni la silueta de
       Cthulhu, que son más oscuras: las nubes pasan por detrás).
    G: niebla del suelo (dónde y cuánta).
    B: todo el cristal del ventanal (para el resplandor del relámpago).
- mascaras_revision.png: el fondo con las máscaras pintadas encima, para revisarlas.

Uso: python tools/gen_mascaras_portada.py
"""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = 'resources/PantallasMenus/fondo_titulo_sin_texto_1080p_definitivo.png'
OUT = 'resources/PantallasMenus/'
W, H = 1920, 1080
# Ventanal (fracciones de la imagen): caja del cristal y arco superior
WIN_X0, WIN_X1, WIN_Y0, WIN_Y1 = 0.535, 0.688, 0.04, 0.435
FLOOR_Y = 0.735            # por debajo, lo brillante son reflejos en el suelo mojado

img = np.asarray(Image.open(SRC).convert('RGB').resize((W, H), Image.LANCZOS)).astype(float) / 255.0
R, G, B = img[..., 0], img[..., 1], img[..., 2]
lum = 0.2126 * R + 0.7152 * G + 0.0722 * B
yy, xx = np.mgrid[0:H, 0:W]
fx, fy = xx / W, yy / H

# ---------------- llamas ----------------
warm = (R > 0.72) & (R >= G) & (G >= B * 0.9) & ((R - B) > 0.18) & (lum > 0.55)
in_window = (fx > WIN_X0) & (fx < WIN_X1) & (fy > WIN_Y0) & (fy < WIN_Y1)
warm &= ~in_window
labels, n = ndimage.label(ndimage.binary_dilation(warm, iterations=1))
sizes = ndimage.sum(np.ones_like(labels), labels, index=np.arange(1, n + 1))
rng = np.random.default_rng(7)
phase_of = np.concatenate([[0], rng.integers(1, 256, n)])
core = np.zeros((H, W))
core[warm] = np.clip((lum[warm] - 0.5) / 0.4, 0.3, 1.0)
core = ndimage.gaussian_filter(core, 0.8)
reflection = fy > FLOOR_Y
core = np.where(reflection, core * 0.55, core)
print('llamas y reflejos detectados: %d (en el suelo: %d)' % (n, len(np.unique(labels[reflection & (labels > 0)]))))

# fase: la de la llama más cercana, en toda la zona que ilumina
dist, (iy, ix) = ndimage.distance_transform_edt(labels == 0, return_indices=True)
phase = phase_of[labels[iy, ix]].astype(float)
spill = ndimage.gaussian_filter(core, 18) + 0.6 * ndimage.gaussian_filter(core, 45)
spill = np.clip(spill / (np.percentile(spill[spill > 0.001], 99) + 1e-6), 0, 1)
luces = np.dstack([core, phase / 255.0, spill, np.ones((H, W))])

# ---------------- cielo y cristal del ventanal ----------------
arch_cx = (WIN_X0 + WIN_X1) / 2
arch = in_window & ((fy > 0.16) | (((fx - arch_cx) / ((WIN_X1 - WIN_X0) / 2)) ** 2 + ((fy - 0.16) / 0.12) ** 2 < 1.0))
bluish = (B > R + 0.12) & (B > G)
glass = arch & bluish & (B > 0.18)
glass = ndimage.binary_closing(glass, iterations=2)
sky = np.clip((B - 0.34) / 0.3, 0, 1) * glass            # zonas claras: cielo y nubes (no Cthulhu)
sky = ndimage.gaussian_filter(sky, 1.2)
glass_soft = ndimage.gaussian_filter(glass.astype(float), 2.0)

# ---------------- niebla del suelo ----------------
mist = np.clip(((B - np.maximum(R, G)) - 0.08) / 0.25, 0, 1) * np.clip((lum - 0.06) / 0.2, 0, 1)
band = np.exp(-((fy - 0.70) / 0.075) ** 2)                 # la banda azul sobre el suelo
mist = ndimage.gaussian_filter(mist * band * ~in_window, 14)
mist = np.clip(mist / (np.percentile(mist[mist > 0.001], 99.5) + 1e-6), 0, 1)
zonas = np.dstack([sky, mist, glass_soft, np.ones((H, W))])

def save(arr, name):
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), 'RGBA').save(OUT + name)
save(luces, 'mascara_luces.png')
save(zonas, 'mascara_zonas.png')

# ---------------- hoja de revisión ----------------
base = img * 0.45
over = base.copy()
over = over * (1 - core[..., None]) + np.array([1.0, 0.1, 0.1]) * core[..., None]           # llamas: rojo
over = over + np.array([0.9, 0.5, 0.0]) * (spill[..., None] * 0.35)                          # luz: naranja
over = over * (1 - sky[..., None] * 0.7) + np.array([0.2, 1.0, 1.0]) * sky[..., None] * 0.7  # cielo: cian
over = over + np.array([0.2, 0.3, 1.0]) * (mist[..., None] * 0.6)                            # niebla: azul
Image.fromarray((np.clip(over, 0, 1) * 255).astype(np.uint8)).save('shots/mascaras_revision.png')
print('ok')
