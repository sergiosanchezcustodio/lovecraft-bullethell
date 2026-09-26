"""Máscaras para animar la ilustración de la portada (resources/PantallasMenus/).

Analiza el fondo (a su resolución completa, 4K) y genera, a 1920x1080 (alineadas con él):
- mascara_velas.png
    R: llama de cada vela, ajustada a la llama (sin la mecha ni la cera). Los reflejos en el
       suelo, a media intensidad.
    G: fase propia de cada vela (0-255), extendida a la zona que ilumina, para que su luz
       parpadee a la vez que ella.
    B: cuánto puede bailar cada punto: 0 en la base de la llama y 1 en la punta y por encima,
       escalado por el tamaño de la llama. Solo en las llamas con forma de llama (las lejanas,
       de pocos píxeles, y los reflejos no se mueven).
- mascara_luces.png
    R: cristal de los farolillos (no se mueven: solo respiran despacio).
    G: halo de los farolillos (su cristal muy difuminado).
    B: luz cálida que proyectan las velas en paredes y suelo (difuminada).
- mascara_zonas.png
    R: cielo claro del ventanal (sin la tracería ni la silueta de Cthulhu).
    G: niebla del suelo (dónde y cuánta).
    B: todo el cristal del ventanal (para el resplandor del relámpago).
- Texto_titulo_niebla.png: el alfa del título muy difuminado, con el margen del
  rectángulo del título (TITLE_PAD), para la niebla de su entrada.
- shots/mascaras_revision.png: el fondo con las máscaras pintadas encima, para revisarlas
  (rojo: llamas; amarillo: parte que baila; verde: farolillos; naranja: luz; cian: cielo;
  azul: niebla).

Si cambia la ilustración, vuelve a ejecutar el script y revisa la lista de farolillos.
Uso: python tools/gen_mascaras_portada.py
"""
import numpy as np
from PIL import Image
from scipy import ndimage

SRC = 'resources/PantallasMenus/fondo_titulo_sin_texto_1080p_definitivo.png'
TITLE = 'resources/PantallasMenus/Texto_titulo.png'
OUT = 'resources/PantallasMenus/'
W, H = 1920, 1080
# Ventanal (fracciones de la imagen): caja del cristal y arco superior
WIN_X0, WIN_X1, WIN_Y0, WIN_Y1 = 0.535, 0.688, 0.04, 0.435
FLOOR_Y = 0.735            # por debajo, lo brillante son reflejos en el suelo mojado
# Farolillos (fracciones de la imagen): lo que brilla a menos de r de estos puntos es un
# farolillo, no una vela. Revisados a mano sobre la ilustración.
LANTERNS = [  # (x, y, r)
    (0.2174, 0.1736, 0.016), (0.3607, 0.0995, 0.014), (0.3984, 0.1481, 0.014),
    (0.4792, 0.1606, 0.010), (0.7813, 0.0440, 0.016), (0.7227, 0.1481, 0.016),
    (0.8542, 0.1782, 0.010), (0.7292, 0.3796, 0.010), (0.7031, 0.3241, 0.010),
    (0.6667, 0.4537, 0.009),
]
TITLE_PAD = 0.14           # margen del rectángulo del título a cada lado (title_screen.gd)
SWAY_REF = 90              # altura de llama (px en 4K) que baila con toda la amplitud

img4 = np.asarray(Image.open(SRC).convert('RGB')).astype(float) / 255.0
H4, W4 = img4.shape[:2]
R, G, B = img4[..., 0], img4[..., 1], img4[..., 2]
lum = 0.2126 * R + 0.7152 * G + 0.0722 * B
yy, xx = np.mgrid[0:H4, 0:W4]
fx, fy = xx / W4, yy / H4

def down(a):
    """De 4K a 1920x1080 (media de cada bloque de 2x2)."""
    return a.reshape(H, H4 // H, W, W4 // W).mean(axis=(1, 3))

# ---------------- fuentes de luz ----------------
in_window = (fx > WIN_X0) & (fx < WIN_X1) & (fy > WIN_Y0) & (fy < WIN_Y1)
warm = (R > 0.8) & (R >= G) & ((R - B) > 0.15) & (lum > 0.6) & ~in_window
labels, n = ndimage.label(warm, structure=np.ones((3, 3)))
objs = ndimage.find_objects(labels)
lantern_px = np.zeros((H4, W4), bool)
for lx, ly, lr in LANTERNS:
    lantern_px |= ((fx - lx) * W4 / H4) ** 2 + (fy - ly) ** 2 < lr ** 2
reflection = fy > FLOOR_Y

rng = np.random.default_rng(7)
flame = np.zeros((H4, W4))      # llamas de vela (ajustadas)
sway = np.zeros((H4, W4))       # cuánto baila cada punto
glass = np.zeros((H4, W4))      # cristal de los farolillos
phase_src = np.zeros((H4, W4), int)
n_candles = n_lanterns = n_sway = 0
for i, sl in enumerate(objs):
    comp = labels[sl] == i + 1
    cy0, cx0 = sl[0].start, sl[1].start
    cy = int(np.mean(np.nonzero(comp)[0])) + cy0
    cx = int(np.mean(np.nonzero(comp)[1])) + cx0
    strength = np.clip((lum[sl] - 0.55) / 0.35, 0.3, 1.0) * comp
    if lantern_px[cy, cx]:
        glass[sl] = np.maximum(glass[sl], strength)
        n_lanterns += 1
        continue
    n_candles += 1
    phase_src[sl][comp] = rng.integers(1, 256)
    if reflection[cy, cx]:
        flame[sl] = np.maximum(flame[sl], strength * 0.55)
        continue
    # La llama llega desde la punta hasta el cuello de la mecha: se corta donde la anchura
    # vuelve a crecer mucho (el borde de la cera) o se estrecha tras el máximo (la mecha).
    widths = comp.sum(axis=1)
    rows = np.nonzero(widths)[0]
    top = rows[0]
    maxw, cut = 0, rows[-1] + 1
    for r in rows:
        w = widths[r]
        if r - top > 3 and maxw > 0 and (w > max(1.5 * maxw, maxw + 5) or (w < 0.45 * maxw and r - top > 6)):
            cut = r
            break
        maxw = max(maxw, w)
    comp_f = comp.copy()
    comp_f[cut:] = False
    fh = cut - top
    flame[sl] = np.maximum(flame[sl], strength * comp_f)
    if fh < 10 or fh < 1.3 * maxw:
        continue                                   # lejana o sin forma de llama: solo parpadea
    # Caja de baile: la llama con un margen a los lados y por encima (no por debajo, para
    # no arrastrar la cera). El peso crece desde la base hasta la punta.
    n_sway += 1
    ys, xs = np.nonzero(comp_f)
    x0, x1 = xs.min() + cx0, xs.max() + cx0
    y_tip, y_base = ys.min() + cy0, ys.max() + cy0
    mx = max(4, int(0.6 * (x1 - x0 + 1)))
    my = max(4, int(0.35 * fh))
    bx0, bx1, by0 = max(0, x0 - mx), min(W4, x1 + mx + 1), max(0, y_tip - my)
    by = np.arange(by0, y_base + 1)[:, None]
    bx = np.arange(bx0, bx1)[None, :]
    wy = np.clip((y_base - by) / max(fh, 1), 0, 1) ** 1.5
    wy = wy * np.clip(1.0 - (y_tip - by) / my, 0, 1)             # por encima de la punta se apaga
    xc, xh = (x0 + x1) / 2, (x1 - x0) / 2 + mx
    wx = np.clip(1.2 - np.abs(bx - xc) / xh, 0, 1) / 1.2
    wx = wx * wx * (3 - 2 * wx)
    w = wy * wx * min(fh / SWAY_REF, 1.0)
    sway[by0:y_base + 1, bx0:bx1] = np.maximum(sway[by0:y_base + 1, bx0:bx1], w)
print('fuentes: %d velas (%d bailan), %d trozos de farolillo' % (n_candles, n_sway, n_lanterns))

# fase: la de la vela más cercana, en toda la zona que ilumina
_, (iy, ix) = ndimage.distance_transform_edt(phase_src == 0, return_indices=True)
phase = phase_src[iy, ix].astype(float)

flame1 = np.clip(down(ndimage.gaussian_filter(flame, 0.8)), 0, 1)
sway1 = down(ndimage.gaussian_filter(sway, 1.5))
phase1 = phase[::2, ::2]
glass1 = down(glass)
halo1 = ndimage.gaussian_filter(glass1, 14) + 0.5 * ndimage.gaussian_filter(glass1, 40)
halo1 = np.clip(halo1 / (halo1.max() + 1e-6), 0, 1)
spill1 = ndimage.gaussian_filter(flame1, 18) + 0.6 * ndimage.gaussian_filter(flame1, 45)
spill1 = np.clip(spill1 / (np.percentile(spill1[spill1 > 0.001], 99) + 1e-6), 0, 1)
velas = np.dstack([flame1, phase1 / 255.0, sway1, np.ones((H, W))])
luces = np.dstack([glass1, halo1, spill1, np.ones((H, W))])

# ---------------- cielo y cristal del ventanal ----------------
img = down(R), down(G), down(B)
R1, G1, B1 = img
yy1, xx1 = np.mgrid[0:H, 0:W]
fx1, fy1 = xx1 / W, yy1 / H
lum1 = 0.2126 * R1 + 0.7152 * G1 + 0.0722 * B1
in_window1 = (fx1 > WIN_X0) & (fx1 < WIN_X1) & (fy1 > WIN_Y0) & (fy1 < WIN_Y1)
arch_cx = (WIN_X0 + WIN_X1) / 2
arch = in_window1 & ((fy1 > 0.16) | (((fx1 - arch_cx) / ((WIN_X1 - WIN_X0) / 2)) ** 2 + ((fy1 - 0.16) / 0.12) ** 2 < 1.0))
bluish = (B1 > R1 + 0.12) & (B1 > G1)
glass_w = ndimage.binary_closing(arch & bluish & (B1 > 0.18), iterations=2)
sky = ndimage.gaussian_filter(np.clip((B1 - 0.34) / 0.3, 0, 1) * glass_w, 1.2)
glass_soft = ndimage.gaussian_filter(glass_w.astype(float), 2.0)

# ---------------- niebla del suelo ----------------
mist = np.clip(((B1 - np.maximum(R1, G1)) - 0.08) / 0.25, 0, 1) * np.clip((lum1 - 0.06) / 0.2, 0, 1)
band = np.exp(-((fy1 - 0.70) / 0.075) ** 2)                # la banda azul sobre el suelo
mist = ndimage.gaussian_filter(mist * band * ~in_window1, 14)
mist = np.clip(mist / (np.percentile(mist[mist > 0.001], 99.5) + 1e-6), 0, 1)
zonas = np.dstack([sky, mist, glass_soft, np.ones((H, W))])

def save(arr, name):
    Image.fromarray((np.clip(arr, 0, 1) * 255).astype(np.uint8), 'RGBA').save(OUT + name)
save(velas, 'mascara_velas.png')
save(luces, 'mascara_luces.png')
save(zonas, 'mascara_zonas.png')

# ---------------- niebla del título ----------------
# El alfa del título, con su margen, reducido a 1/4 y difuminado en dos escalas.
ta = np.asarray(Image.open(TITLE).convert('RGBA')).astype(float)[..., 3] / 255.0
th, tw = ta.shape
ph, pw = int(round(th * TITLE_PAD / (1 - 2 * TITLE_PAD))), int(round(tw * TITLE_PAD / (1 - 2 * TITLE_PAD)))
ta = np.pad(ta, ((ph, ph), (pw, pw)))
small = np.asarray(Image.fromarray((ta * 255).astype(np.uint8)).resize((ta.shape[1] // 4, ta.shape[0] // 4), Image.BOX)).astype(float) / 255.0
fog = ndimage.gaussian_filter(small, 2.5) * 0.7 + ndimage.gaussian_filter(small, 9) * 0.6
fog = np.clip(fog / np.percentile(fog, 99.5), 0, 1)
fh_, fw_ = fog.shape                                        # se apaga hacia los bordes del rectángulo
ey = np.clip(np.minimum(np.arange(fh_), fh_ - 1 - np.arange(fh_)) / (fh_ * 0.08), 0, 1)
ex = np.clip(np.minimum(np.arange(fw_), fw_ - 1 - np.arange(fw_)) / (fw_ * 0.06), 0, 1)
fog *= np.outer(ey * ey * (3 - 2 * ey), ex * ex * (3 - 2 * ex))
Image.fromarray((fog * 255).astype(np.uint8), 'L').save(OUT + 'Texto_titulo_niebla.png')

# ---------------- hoja de revisión ----------------
base = np.dstack(img) * 0.45
over = base * (1 - flame1[..., None]) + np.array([1.0, 0.1, 0.1]) * flame1[..., None]              # llamas: rojo
over = over + np.array([1.0, 1.0, 0.0]) * np.clip(sway1 * 2, 0, 1)[..., None] * 0.6                # baile: amarillo
over = over * (1 - glass1[..., None]) + np.array([0.1, 1.0, 0.2]) * glass1[..., None]              # farolillos: verde
over = over + np.array([0.1, 0.6, 0.1]) * (halo1[..., None] * 0.4)
over = over + np.array([0.9, 0.5, 0.0]) * (spill1[..., None] * 0.3)                                # luz: naranja
over = over * (1 - sky[..., None] * 0.7) + np.array([0.2, 1.0, 1.0]) * sky[..., None] * 0.7        # cielo: cian
over = over + np.array([0.2, 0.3, 1.0]) * (mist[..., None] * 0.6)                                  # niebla: azul
Image.fromarray((np.clip(over, 0, 1) * 255).astype(np.uint8)).save('shots/mascaras_revision.png')
print('ok')
