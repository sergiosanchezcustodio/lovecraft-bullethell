"""Primitivas comunes para los generadores de modelos voxel.

Coordenadas de modelado en "unidades base" (ub): 1 ub = 1/16 m. La resolución
se fija con S (voxels por ub): S=2 da 32 voxels por metro, la escala del juego.
Eje Y arriba, el modelo mira hacia +Z; la parte "_l" queda en X negativa.

Salida JSON: voxels [x, y, z, parte, r, g, b, glow] en coordenadas voxel,
pivots por parte (en voxels) y voxel_size (metros por voxel).
"""
import json, math, random

def lerp(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))

def scale(c, k):
    return tuple(min(1.0, q * k) for q in c)

class Model:
    def __init__(self, S=2, seed=0):
        self.S = S
        self.V = {}                     # (x,y,z) voxel -> [parte, color, glow]
        self.rng = random.Random(seed)
        self._h = {}

    # ---------- voxels sueltos (coordenadas voxel) ----------
    def put(self, x, y, z, part, col, glow=0, over=True):
        k = (int(math.floor(x)), int(math.floor(y)), int(math.floor(z)))
        if over or k not in self.V:
            self.V[k] = [part, col, glow]

    def has(self, k):
        return k in self.V

    # ---------- volúmenes (coordenadas en ub) ----------
    def ell(self, cx, cy, cz, rx, ry, rz, part, col, over=True, glow=0):
        S = self.S
        cx, cy, cz, rx, ry, rz = [v * S for v in (cx, cy, cz, rx, ry, rz)]
        for x in range(int(cx - rx) - 2, int(cx + rx) + 2):
            for y in range(int(cy - ry) - 2, int(cy + ry) + 2):
                for z in range(int(cz - rz) - 2, int(cz + rz) + 2):
                    if ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 + ((z + .5 - cz) / rz) ** 2 <= 1:
                        self.put(x, y, z, part, col, glow, over)

    def sell(self, cx, cy, cz, rx, ry, rz, part, col, p=3.0, over=True, glow=0):
        """Superelipsoide: con p≈3 es una caja de esquinas redondeadas. Da caras planas
        (ropa, madera, piedra) en lugar de los escalones de un elipsoide (p=2)."""
        S = self.S
        cx, cy, cz, rx, ry, rz = [v * S for v in (cx, cy, cz, rx, ry, rz)]
        for x in range(int(cx - rx) - 2, int(cx + rx) + 2):
            for y in range(int(cy - ry) - 2, int(cy + ry) + 2):
                for z in range(int(cz - rz) - 2, int(cz + rz) + 2):
                    if abs((x + .5 - cx) / rx) ** p + abs((y + .5 - cy) / ry) ** p + abs((z + .5 - cz) / rz) ** p <= 1:
                        self.put(x, y, z, part, col, glow, over)

    def capsule(self, a, b, r0, r1, part, col, over=True):
        n = int(max(abs(b[i] - a[i]) for i in range(3)) * self.S * 2) + 1
        for i in range(n + 1):
            t = i / n
            c = [a[k] + (b[k] - a[k]) * t for k in range(3)]
            r = r0 + (r1 - r0) * t
            self.ell(c[0], c[1], c[2], r, r, r, part, col, over)

    def cone(self, a, b, r, part, cb, ct, tip_r=0.5):
        """Púa cónica con degradado de color base -> punta. tip_r >= 0.5 ub para que no se fragmente."""
        n = int(max(abs(b[i] - a[i]) for i in range(3)) * self.S * 3) + 1
        for i in range(n + 1):
            t = i / n
            c = [a[k] + (b[k] - a[k]) * t for k in range(3)]
            rr = max(tip_r, r * (1 - t) ** 1.2)
            self.ell(c[0], c[1], c[2], rr, rr, rr, part, lerp(cb, ct, t))

    def box(self, x0, y0, z0, x1, y1, z1, part, col, over=True, glow=0):
        """Caja de esquinas (x0,y0,z0)-(x1,y1,z1) en ub, extremo superior excluido."""
        S = self.S
        for x in range(int(round(x0 * S)), int(round(x1 * S))):
            for y in range(int(round(y0 * S)), int(round(y1 * S))):
                for z in range(int(round(z0 * S)), int(round(z1 * S))):
                    self.put(x, y, z, part, col, glow, over)

    def line(self, a, b, part, col, thick=1, over=True, glow=0):
        """Línea continua de voxels entre dos puntos en ub (cuerdas, mangos, correas)."""
        S = self.S
        a = [q * S for q in a]; b = [q * S for q in b]
        n = int(max(abs(b[i] - a[i]) for i in range(3)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            p = [a[k] + (b[k] - a[k]) * t for k in range(3)]
            for dx in range(thick):
                for dz in range(thick):
                    self.put(p[0] + dx, p[1], p[2] + dz, part, col, glow, over)

    # ---------- superficies (recorriendo la columna, nunca el diccionario) ----------
    def front(self, x, y, zmax=200, zmin=-200):
        """z del voxel más adelantado de la columna (x, y), en voxels."""
        for z in range(zmax, zmin, -1):
            if (x, y, z) in self.V:
                return z
        return None

    def top(self, x, z, ymax=200, parts=None):
        for y in range(ymax, -1, -1):
            v = self.V.get((x, y, z))
            if v is not None and (parts is None or v[0] in parts):
                return y
        return None

    def exposed(self, k):
        x, y, z = k
        return any((x + dx, y + dy, z + dz) not in self.V
                   for dx, dy, dz in ((1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)))

    # ---------- color ----------
    def hsh(self, i, j, k):
        key = (i, j, k)
        if key not in self._h:
            self._h[key] = self.rng.random()
        return self._h[key]

    def noise(self, x, y, z, s):
        """Ruido de valor 3D suave en [0, 1]; s = tamaño de la mancha en voxels."""
        x /= s; y /= s; z /= s
        i, j, k = int(math.floor(x)), int(math.floor(y)), int(math.floor(z))
        fx, fy, fz = [f * f * (3 - 2 * f) for f in (x - i, y - j, z - k)]
        v = 0.0
        for a in (0, 1):
            for b in (0, 1):
                for c in (0, 1):
                    w = (fx if a else 1 - fx) * (fy if b else 1 - fy) * (fz if c else 1 - fz)
                    v += w * self.hsh(i + a, j + b, k + c)
        return v

    def paint(self, fn):
        """fn(k, parte, color) -> nuevo color (o None para dejarlo)."""
        for k, v in self.V.items():
            c = fn(k, v[0], v[1])
            if c is not None:
                v[1] = c

    # ---------- salida ----------
    def export(self, path, pivots, jitter=0.018, default_col=(0.5, 0.5, 0.5)):
        out = []
        for (x, y, z), (p, c, g) in self.V.items():
            if isinstance(c, str):
                c = default_col
            j = self.rng.uniform(-jitter, jitter) if jitter else 0.0
            out.append([x, y, z, p] + [round(max(0.0, min(1.0, q + j)), 3) for q in c] + [g])
        S = self.S
        data = {"voxel_size": 1.0 / (16 * S),
                "pivots": {k: [a * S for a in v] for k, v in pivots.items()},
                "voxels": out}
        with open(path, "w") as f:
            json.dump(data, f)
        return len(out)
