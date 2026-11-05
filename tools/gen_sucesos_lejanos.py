"""Modelos de los sucesos lejanos (hito 17.18): se ven de lejos y muy grandes, así que van a 16
voxels por metro (S=1, la mitad que el resto) y huecos por dentro.

  lejano_tentaculo  tentáculo de 9 m que sale del agua curvándose, verde negruzco por arriba y
                    pálido por debajo, con dos filas de ventosas; la base, en el origen (y=0 en el
                    agua), y se dobla hacia +Z.

Uso: python tools/gen_sucesos_lejanos.py
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(__file__))
from voxlib import Model

TOP = (0.10, 0.14, 0.11); TOP_L = (0.16, 0.21, 0.16); BELLY = (0.33, 0.31, 0.26); SUCK = (0.56, 0.50, 0.44)
SUCK_D = (0.24, 0.20, 0.18)

def tentaculo():
    M = Model(S=1, seed=1718)
    L = 9.0 * 16                                     # voxels a lo largo
    steps = 900
    pts = []                                         # el eje: sube casi recto y la punta se enrosca hacia +Z
    x = y = z = 0.0
    for i in range(steps + 1):
        t = i / steps
        pts.append((x + math.sin(t * 5.0) * 4.0, y, z))
        a = 0.3 * t + 2.6 * t ** 4                   # ángulo con la vertical
        y += math.cos(a) * L / steps
        z += math.sin(a) * L / steps
    for i, (cx, cy, cz) in enumerate(pts):
        t = i / steps
        r = 13.0 * (1.0 - t) ** 0.9 + 1.2
        if i < steps:
            nx, ny, nz = pts[i + 1]
            tx, ty, tz = nx - cx, ny - cy, nz - cz
        n = math.sqrt(tx * tx + ty * ty + tz * tz) or 1.0
        tx, ty, tz = tx / n, ty / n, tz / n
        # el «vientre» mira hacia dentro de la curva (+Z y abajo): perpendicular al eje en el plano YZ
        bx, by, bz = 0.0, -tz, ty
        R = int(r) + 1
        for dx in range(-R, R + 1):
            for dy in range(-R, R + 1):
                for dz in range(-R, R + 1):
                    d2 = dx * dx + dy * dy + dz * dz
                    if d2 > r * r or d2 < (r - 2.2) ** 2: continue     # solo la piel
                    along = dx * tx + dy * ty + dz * tz
                    if abs(along) > 1.0: continue
                    side = (dx * bx + dy * by + dz * bz) / max(r, 0.5)
                    p = (int(round(cx + dx)), int(round(cy + dy)), int(round(cz + dz)))
                    if p[1] < -2: continue
                    c = TOP if M.noise(p[0], p[1], p[2], 4.0) > 0.45 else TOP_L
                    if side > 0.35:
                        c = BELLY
                        lat = (dx * 1.0) / max(r, 0.5)             # dos filas de ventosas
                        if abs(abs(lat) - 0.35) < 0.18 and (i // 9) % 2 == 0:
                            c = SUCK if side > 0.6 else SUCK_D
                    M.put(p[0], p[1], p[2], 'body', c, over=False)
    n = M.export('models/lejano_tentaculo.json', {'body': [0, 0, 0]}, jitter=0.03, pivots_in_voxels=True,
                 roughness=0.45, specular=0.5)
    print('lejano_tentaculo', n, 'voxels')

if __name__ == '__main__':
    tentaculo()
