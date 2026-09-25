"""Título de la portada en voxel 3D: "Lovecraft Library:" pequeño y, debajo, mucho más
grande, "Surviving Cthulhu" rodeado de tentáculos.

- Letras: se rasterizan con fuentes OFL (tools/fonts/) y se extruyen con un bisel
  escalonado (más gruesas en el centro del trazo). "Surviving Cthulhu" es piedra color
  hueso, envejecida, con grietas y verdín abajo; "Lovecraft Library:", oro viejo.
- Tentáculos: curvas 3D que se enroscan en los trazos verticales de algunas letras y dos
  grandes que enmarcan la línea por debajo y se enroscan hacia arriba en los extremos.
  Cada tentáculo se trocea en segmentos ("tX_00", "tX_01"…) con pivote al principio de
  cada uno: la portada los encadena y los anima (la punta se mueve, lo enroscado apenas).

Salida: models/titulo_linea1.json, titulo_linea2.json, titulo_tentaculos.json y una
vista frontal de comprobación en shots/titulo_frente.png.
Coordenadas en voxels, origen en el centro del bloque de texto; el frente mira a +Z.
Uso: python tools/gen_titulo.py
"""
import json, math, os
import numpy as np
from PIL import Image, ImageDraw, ImageFont

VS = 0.065                                   # metros por voxel (la portada lo coloca a ~30 m)
FONTS = os.path.join(os.path.dirname(__file__), 'fonts')
rng = np.random.default_rng(1928)

def lerp(a, b, t): return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))

# ---------------- rasterizado ----------------
def raster_line(text, font_file, cap_px, tracking):
    """Devuelve (máscara bool [alto, ancho], cajas x de cada carácter, línea base)."""
    font = ImageFont.truetype(os.path.join(FONTS, font_file), 10)
    cap_h = font.getbbox('H')[3] - font.getbbox('H')[1]
    size = int(round(10 * cap_px / cap_h))
    font = ImageFont.truetype(os.path.join(FONTS, font_file), size)
    widths = [font.getlength(c) for c in text]
    W = int(sum(widths) + tracking * (len(text) - 1) + size)
    H = int(size * 1.8)
    img = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(img)
    x = size * 0.5
    boxes = []
    base = int(size * 1.25)
    for c, w in zip(text, widths):
        d.text((x, base), c, font=font, fill=255, anchor='ls')
        boxes.append((x, x + w))
        x += w + tracking
    m = np.array(img) > 127
    ys, xs = np.nonzero(m)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    boxes = [(a - x0, b - x0) for (a, b) in boxes]
    return m[y0:y1, x0:x1], boxes, base - y0

def distance_inside(mask, maxd):
    """Distancia (en voxels, métrica de ajedrez) de cada píxel del glifo al borde, hasta maxd."""
    d = np.zeros(mask.shape, dtype=int)
    cur = mask.copy()
    for k in range(1, maxd + 1):
        d[cur] = k
        p = np.pad(cur, 1)
        cur = cur & p[:-2, 1:-1] & p[2:, 1:-1] & p[1:-1, :-2] & p[1:-1, 2:]
    return d

def value_noise2(shape, cell, seed):
    r = np.random.default_rng(seed)
    gh, gw = shape[0] // cell + 2, shape[1] // cell + 2
    g = r.random((gh, gw))
    yy, xx = np.mgrid[0:shape[0], 0:shape[1]] / cell
    iy, ix = yy.astype(int), xx.astype(int)
    fy, fx = yy - iy, xx - ix
    fy = fy * fy * (3 - 2 * fy); fx = fx * fx * (3 - 2 * fx)
    return (g[iy, ix] * (1 - fx) + g[iy, ix + 1] * fx) * (1 - fy) + (g[iy + 1, ix] * (1 - fx) + g[iy + 1, ix + 1] * fx) * fy

# ---------------- letras ----------------
def letters(mask, ox, oy, depth, bevel, palette, part, seed):
    """Extruye la máscara: cada columna va de z=0 a z = depth + bisel según la distancia al
    borde. Devuelve voxels [x, y, z, parte, r, g, b, glow] y el mapa de alturas."""
    H, W = mask.shape
    dist = distance_inside(mask, bevel)
    zt = np.where(mask, depth - bevel + dist, -1)
    n1 = value_noise2(mask.shape, 6, seed); n2 = value_noise2(mask.shape, 2, seed + 1)
    cracks = value_noise2(mask.shape, 9, seed + 2)
    out = []
    for yi in range(H):
        for xi in range(W):
            if not mask[yi, xi]: continue
            top = int(zt[yi, xi])
            x = int(ox + xi); y = int(oy + (H - 1 - yi))            # int de Python (JSON no admite int64)
            v = yi / max(H - 1, 1)                                   # 0 arriba, 1 abajo
            for z in range(0, top + 1):
                front = z == top
                c = palette['base']
                if front:
                    c = lerp(palette['light'], palette['base'], 0.35 + 0.5 * v)   # luz de arriba
                    c = lerp(c, palette['dark'], 0.25 * n1[yi, xi])
                    if dist[yi, xi] <= 1: c = palette['edge']                     # arista del bisel
                    elif abs(cracks[yi, xi] - 0.5) < 0.012: c = palette['crack']  # grietas
                    if 'moss' in palette and v > 0.65 and n2[yi, xi] > 0.62 - (v - 0.65):
                        c = lerp(c, palette['moss'], 0.7)                         # verdín abajo
                else:
                    c = palette['side'] if z < top - 1 else palette['edge']
                out.append([x, y, z, part, *[round(q, 3) for q in c], 0])
    return out

# ---------------- tentáculos ----------------
class Tentacle:
    """Tentáculo a lo largo de una curva: lista de (punto, normal interior, radio)."""
    def __init__(self, name, samples, nseg):
        self.name = name; self.samples = samples; self.nseg = nseg

def helix_wrap(x_axis, z_axis, rx, rz, y_start, y_end, turns, phase, r0, r1, tip, n=260):
    """Sube enroscándose a un trazo vertical y termina en una punta que se riza hacia fuera.
    tip = (dirección x de la punta: -1 o 1, longitud, vueltas del rizo)."""
    pts = []
    for i in range(n):
        t = i / (n - 1)
        a = phase + t * turns * 2 * math.pi
        p = (x_axis + rx * math.cos(a), y_start + (y_end - y_start) * t, z_axis + rz * math.sin(a))
        inner = (-math.cos(a), 0.0, -math.sin(a))
        pts.append((p, inner, r0 + (r1 - r0) * t))
    # punta: sale hacia fuera y hacia arriba y se riza
    last = pts[-1][0]
    sx, length, curl = tip
    m = 140
    for i in range(1, m):
        t = i / (m - 1)
        R = length * (1 - t) ** 1.3 * 0.55
        a = math.pi * 0.5 + sx * t * curl * 2 * math.pi
        cx = last[0] + sx * length * 0.35; cy = last[1] + length * 0.35
        p = (cx + sx * R * math.cos(a) * -1, cy + R * math.sin(a) - length * 0.15 * t, last[2] + 2 * math.sin(t * math.pi))
        inner = ((cx - p[0]), (cy - p[1]), 0.0)
        L = math.sqrt(inner[0] ** 2 + inner[1] ** 2) or 1.0
        pts.append((p, (inner[0] / L, inner[1] / L, 0.0), max(1.6, r1 * (1 - t) + 1.6 * t)))
    return pts

def base_curl(x_from, x_to, y, z, r0, curl_r, sx, n_line=220, n_curl=220):
    """Tentáculo tumbado bajo la línea de texto que en su extremo se enrosca hacia arriba."""
    pts = []
    for i in range(40):                                  # entrada: sale de detrás de las letras
        t = i / 40
        pts.append(((x_from - (x_to - x_from) * 0.03 * (1 - t), y + 2 * (1 - t), z - 22 * (1 - t) ** 1.5),
                    (0.0, 1.0, 0.0), r0 * (0.75 + 0.25 * t)))
    for i in range(n_line):
        t = i / (n_line - 1)
        x = x_from + (x_to - x_from) * t
        yy = y + 2.5 * math.sin(t * math.pi * 2.3)
        zz = z + 3.0 * math.sin(t * math.pi * 1.7 + 0.6)
        pts.append(((x, yy, zz), (0.0, 1.0, 0.0), r0 * (1 - 0.25 * t)))
    rs = r0 * 0.75
    cx, cy = x_to, y + curl_r
    for i in range(1, n_curl):
        t = i / (n_curl - 1)
        a = -math.pi * 0.5 + t * 1.6 * 2 * math.pi               # 1,6 vueltas
        R = curl_r * (1 - 0.72 * t)
        # a = -90° es el punto de abajo (donde acaba el tramo recto); con sx el giro sigue
        # la dirección en que avanzaba el tentáculo y se enrosca hacia arriba y hacia dentro
        p = (cx + sx * R * math.cos(a), cy + R * math.sin(a), z + 2.0 * math.sin(t * math.pi))
        inner = (cx - p[0], cy - p[1], 0.0)
        L = math.sqrt(inner[0] ** 2 + inner[1] ** 2) or 1.0
        pts.append((p, (inner[0] / L, inner[1] / L, 0.0), max(1.6, rs * (1 - t) + 1.6 * t)))
    return pts

# Verde abisal azulado con reflejos violetas: bajo la luz cálida del título tiene que seguir
# viéndose frío y oscuro (con verdes más amarillentos salía oliva).
TD = (0.02, 0.06, 0.09); TF = (0.05, 0.24, 0.30); TI = (0.30, 0.11, 0.44)
TU = (0.52, 0.38, 0.40); SUCK = (0.74, 0.58, 0.56); SUCK_C = (0.26, 0.11, 0.14); BIO = (0.35, 0.95, 0.80)

def tentacle_voxels(t, occupied):
    """Voxeliza un tentáculo: esferas a lo largo de la curva. Cada voxel guarda el índice de
    la muestra más cercana (segmento y lado dorsal/ventral). No pisa las letras."""
    best = {}
    S = t.samples
    for idx, (p, inner, r) in enumerate(S):
        ri = int(math.ceil(r)) + 1
        cx, cy, cz = p
        for x in range(int(cx - ri), int(cx + ri) + 1):
            for y in range(int(cy - ri), int(cy + ri) + 1):
                for z in range(int(cz - ri), int(cz + ri) + 1):
                    d2 = (x + .5 - cx) ** 2 + (y + .5 - cy) ** 2 + (z + .5 - cz) ** 2
                    if d2 > r * r: continue
                    k = (x, y, z)
                    if k in occupied: continue
                    if k not in best or d2 / (r * r) < best[k][1]:
                        best[k] = (idx, d2 / (r * r))
    n = len(S)
    arc = [0.0]
    for i in range(1, n):
        a, b = S[i - 1][0], S[i][0]
        arc.append(arc[-1] + math.sqrt(sum((a[k] - b[k]) ** 2 for k in range(3))))
    out = []
    for (x, y, z), (idx, dn) in best.items():
        p, inner, r = S[idx]
        v = (x + .5 - p[0], y + .5 - p[1], z + .5 - p[2])
        L = math.sqrt(v[0] ** 2 + v[1] ** 2 + v[2] ** 2) or 1.0
        facing_in = (v[0] * inner[0] + v[1] * inner[1] + v[2] * inner[2]) / L
        tpar = idx / (n - 1)
        seg = min(t.nseg - 1, int(tpar * t.nseg))
        glow = 0
        a_len = arc[idx]
        spacing = max(4.0, r * 1.7)                              # ventosas separadas, más juntas en la punta
        in_sucker = (a_len % spacing) < spacing * 0.5
        if facing_in > 0.5:                                      # cara interior
            c = TU
            if in_sucker and r > 1.9:
                c = SUCK_C if facing_in > 0.9 else SUCK          # disco con el centro oscuro
        else:
            c = lerp(TF, TD, min(1.0, (-facing_in + 0.5) / 1.2))
            if (int(a_len / 6) + int(v[1] > 0)) % 6 == 0: c = lerp(c, TI, 0.55)   # brillo violáceo
            if facing_in < -0.75 and (a_len % 29) < 1.6 and r > 2.0:
                c = lerp(c, BIO, 0.45)                                     # motas verdosas, sin brillo propio
        out.append([x, y, z, '%s_%02d' % (t.name, seg), *[round(q, 3) for q in c], glow])
        # Solape: el principio de cada segmento se duplica en el anterior, para que al
        # girar no se abra un hueco en la unión (dentro no hay caras que tapen).
        f = tpar * t.nseg - seg
        if seg > 0 and f < 0.22:
            out.append([x, y, z, '%s_%02d' % (t.name, seg - 1), *[round(q, 3) for q in c], glow])
    pivots = {}
    for s in range(t.nseg):
        i = int(s / t.nseg * (n - 1))
        pivots['%s_%02d' % (t.name, s)] = [float(q) for q in S[i][0]]
    return out, pivots

def stem_x(mask, box):
    """Centro y medio ancho del trazo vertical más grueso dentro de la caja de un carácter."""
    a, b = int(box[0]), int(box[1])
    cols = mask[:, a:b].sum(axis=0)
    thr = cols.max() * 0.75
    idx = np.nonzero(cols >= thr)[0]
    return a + idx.mean(), (idx.max() - idx.min() + 1) / 2.0

# ---------------- montaje ----------------
def main():
    GAP = 10
    m2, boxes2, base2 = raster_line('Surviving Cthulhu', 'CinzelDecorative-Black.ttf', 40, 5)
    m1, boxes1, base1 = raster_line('Lovecraft Library:', 'IMFeENsc28P.ttf', 15, 3)
    H2, W2 = m2.shape; H1, W1 = m1.shape
    # línea 2 centrada con su base en y=0; línea 1 centrada encima
    ox2 = -W2 // 2; oy2 = -(H2 - base2)
    ox1 = -W1 // 2; oy1 = oy2 + H2 + GAP
    stone = {'base': (0.74, 0.68, 0.55), 'light': (0.92, 0.87, 0.74), 'dark': (0.52, 0.46, 0.36),
             'edge': (0.34, 0.29, 0.22), 'side': (0.46, 0.41, 0.32), 'crack': (0.22, 0.19, 0.15),
             'moss': (0.30, 0.42, 0.32)}
    gold = {'base': (0.74, 0.55, 0.24), 'light': (0.96, 0.80, 0.46), 'dark': (0.50, 0.34, 0.14),
            'edge': (0.36, 0.24, 0.10), 'side': (0.46, 0.32, 0.13), 'crack': (0.30, 0.20, 0.08)}
    v2 = letters(m2, ox2, oy2, 9, 3, stone, 'linea2', 3)
    v1 = letters(m1, ox1, oy1, 5, 2, gold, 'linea1', 5)
    occupied = {(v[0], v[1], v[2]) for v in v2}
    # --- tentáculos: se enroscan en la i de "Surviving", la t y la l de "Cthulhu";
    # dos grandes enmarcan la línea por debajo ---
    text2 = 'Surviving Cthulhu'
    def wrap(char_i, name, turns, phase, tip_dir, tip_len):
        sx, half = stem_x(m2, boxes2[char_i])
        x_axis = ox2 + sx
        return Tentacle(name, helix_wrap(x_axis, 4.5, half + 3.2, 8.0, oy2 - 14, oy2 + H2 * 0.9, turns, phase,
                                         3.6, 2.4, (tip_dir, tip_len, 1.1)), 9)
    # Solo en letras fuera de la anchura de "Lovecraft Library:" (sus puntas no la cruzan);
    # una vuelta que pasa por delante en la parte baja del trazo: la letra se sigue leyendo.
    tents = [wrap(4, 'tA', 1.0, math.pi * 0.25, -1, 24), wrap(14, 'tC', 1.0, math.pi * 0.25, 1, 26)]
    left_end = ox2 - 6; right_end = ox2 + W2 + 6
    tents.append(Tentacle('tL', base_curl(-10, left_end, oy2 - 8, -3, 5.8, 16, -1), 10))
    tents.append(Tentacle('tR', base_curl(12, right_end, oy2 - 9, -2, 5.5, 15, 1), 10))
    vt = []; pivots_t = {}
    for t in tents:
        vox, piv = tentacle_voxels(t, occupied)
        vt += vox; pivots_t.update(piv)
        for v in vox: occupied.add((v[0], v[1], v[2]))
    def dump(name, vox, pivots, rough, spec):
        with open('models/%s.json' % name, 'w') as f:
            json.dump({'voxel_size': VS, 'pivots': pivots, 'voxels': vox, 'roughness': rough, 'specular': spec}, f)
        print('%s: %d voxels' % (name, len(vox)))
    dump('titulo_linea2', v2, {'linea2': [0, 0, 0]}, 0.75, 0.35)
    dump('titulo_linea1', v1, {'linea1': [0, 0, 0]}, 0.35, 0.8)
    dump('titulo_tentaculos', vt, pivots_t, 0.45, 0.55)      # húmedo, sin rayas de brillo en los escalones
    # vista frontal de comprobación
    allv = v1 + v2 + vt
    xs = [v[0] for v in allv]; ys = [v[1] for v in allv]
    X0, Y0 = min(xs), min(ys); W = max(xs) - X0 + 1; H = max(ys) - Y0 + 1
    img = np.zeros((H, W, 3)); zb = np.full((H, W), -999)
    for v in allv:
        xi = v[0] - X0; yi = H - 1 - (v[1] - Y0)
        if v[2] > zb[yi, xi]:
            zb[yi, xi] = v[2]; img[yi, xi] = v[4:7]
    os.makedirs('shots', exist_ok=True)
    Image.fromarray((img * 255).astype(np.uint8)).resize((W * 2, H * 2), Image.NEAREST).save('shots/titulo_frente.png')
    print('ancho %d voxels (%.1f m), alto %d voxels (%.1f m)' % (W, W * VS, H, H * VS))

if __name__ == '__main__':
    main()
