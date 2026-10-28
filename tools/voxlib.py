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
        # keep_under: al pisar un voxel de otra parte, se guarda en `under` y export lo saca también
        # (ver under_kept). El brazo y el tronco se solapan: al mover el brazo, el costado tiene que
        # seguir entero (28-10-2026). Lo activan los humanos (cuerpo.new) y el vestuario.
        self.keep_under = False
        self.under = {}

    # ---------- voxels sueltos (coordenadas voxel) ----------
    def put(self, x, y, z, part, col, glow=0, over=True):
        k = (int(math.floor(x)), int(math.floor(y)), int(math.floor(z)))
        if over or k not in self.V:
            if self.keep_under and k in self.V and self.V[k][0] != part:
                self.under[k] = self.V[k]
            self.V[k] = [part, col, glow]

    def has(self, k):
        return k in self.V

    LEGS = ('leg_l', 'leg_r', 'shin_l', 'shin_r')

    def under_kept(self):
        """Lo pisado que se conserva: todo menos las piernas que tapa una falda, una sotana o un
        abrigo largo (parte torso o, desde el hito 12.3, skirt), que al andar asomarían por delante
        de la tela."""
        return {k: v for k, v in self.under.items()
                if k in self.V and v[0] != self.V[k][0]                # vuelto a poner por su parte: sobra
                and not (v[0] in self.LEGS and self.V[k][0] in ('torso', 'skirt'))}

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

    def vbox(self, x0, y0, z0, x1, y1, z1, part, col, over=True, glow=0):
        """Caja en coordenadas voxel, extremo superior excluido. Para diseños a bloques
        (personajes humanos) donde cada voxel cuenta."""
        for x in range(x0, x1):
            for y in range(y0, y1):
                for z in range(z0, z1):
                    self.put(x, y, z, part, col, glow, over)

    def bevel(self, part, x0, x1, z0, z1, y0, y1):
        """Quita las cuatro aristas verticales de un bloque para suavizar la silueta."""
        for y in range(y0, y1):
            for x, z in ((x0, z0), (x0, z1 - 1), (x1 - 1, z0), (x1 - 1, z1 - 1)):
                v = self.V.get((x, y, z))
                if v is not None and v[0] == part:
                    del self.V[(x, y, z)]

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
    def export(self, path, pivots, jitter=0.018, default_col=(0.5, 0.5, 0.5), pivots_in_voxels=False,
               roughness=None, specular=None, parents=None, no_bottom=False, skip=None, inner=True,
               extra=None):
        """roughness/specular: material del modelo. Sin indicarlos, piel húmeda (0,38 / 0,6);
        para ropa, plumas, madera o piedra conviene una superficie mate (~0,9 / 0,25).
        skip: voxel -> caras que VoxelBuilder no construye (bits +x, -x, +y, -y, +z, -z), las
        que dan al hueco cerrado de su parte (ver inner_faces); van como noveno valor. Sin skip,
        se calculan solas (27-10-2026); inner=False las deja todas.
        extra: {voxel: [parte, color, glow]} que comparten sitio con otro de otra parte (`under`);
        van marcados (bit 64 del noveno valor) y VoxelBuilder hunde un poco sus caras: donde
        coinciden con las de la otra parte, se ve la otra. Sin extra, con keep_under, los de
        under_kept() tal cual."""
        if skip is None and inner:
            skip = inner_faces(self, {v[0] for v in self.V.values()})
        if extra is None and self.keep_under:
            extra = self.under_kept()
        out = []
        for (x, y, z), (p, c, g) in self.V.items():
            if isinstance(c, str):
                c = default_col
            j = self.rng.uniform(-jitter, jitter) if jitter else 0.0
            out.append([x, y, z, p] + [round(max(0.0, min(1.0, q + j)), 3) for q in c] + [g])
            if skip and skip.get((x, y, z)): out[-1].append(skip[(x, y, z)])
        for (x, y, z), (p, c, g) in (extra or {}).items():
            if isinstance(c, str):
                c = default_col
            out.append([x, y, z, p] + [round(max(0.0, min(1.0, q)), 3) for q in c] + [g, 64])
        S = self.S
        k_piv = 1 if pivots_in_voxels else S
        data = {"voxel_size": 1.0 / (16 * S),
                "pivots": {k: [a * k_piv for a in v] for k, v in pivots.items()},
                "voxels": out}
        if parents: data["parents"] = parents          # parte -> parte de la que cuelga
        if roughness is not None: data["roughness"] = roughness
        if specular is not None: data["specular"] = specular
        if no_bottom: data["no_bottom"] = True           # atrezo fijo: sin caras hacia abajo
        with open(path, "w") as f:
            json.dump(data, f)
        return len(out)


def inner_faces(M, parts, floor=None):
    """Caras de cada voxel que dan al hueco cerrado de su propia parte (23-10-2026): en un modelo
    vaciado son casi la mitad de la malla y nunca se ven, ni al girar la parte, porque el hueco va
    con ella. Devuelve voxel -> bits (+x, -x, +y, -y, +z, -z) para export(skip=). floor: por
    debajo de esa y no se entra desde fuera (un tronco cortado bajo el agua cuenta como cerrado)."""
    import numpy as np
    from scipy import ndimage
    out = {}
    dirs = ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1))
    for part in parts:
        keys = [k for k, v in M.V.items() if v[0] == part]
        if not keys: continue
        P = np.array(keys, dtype=np.int64)
        lo = P.min(0) - 2
        occ = np.zeros(tuple(P.max(0) - lo + 3), bool)
        I = tuple((P - lo).T)
        occ[I] = True
        free = ~occ
        if floor is not None:
            free[:, :max(0, floor - lo[1]), :] = False
        lab, _ = ndimage.label(free)
        edge = set(np.unique(np.concatenate([lab[0].ravel(), lab[-1].ravel(), lab[:, -1].ravel(),
                                             lab[:, :, 0].ravel(), lab[:, :, -1].ravel()])))
        if floor is None: edge |= set(np.unique(lab[:, 0].ravel()))
        inner = free & ~np.isin(lab, list(edge))
        bits = np.zeros(len(keys), np.int64)
        for i, (a, b, c) in enumerate(dirs):
            bits |= inner[I[0] + a, I[1] + b, I[2] + c].astype(np.int64) << i
        for k, m in zip(keys, bits.tolist()):
            if m: out[k] = m
    return out


# ---------- más resolución y textura fina (revisión de arte, 13-10-2026) ----------

def _ih(x, y, z, s=0):
    """Hash entero rápido en [0, 1) (sin la caché de Model.hsh, para millones de voxels)."""
    h = (x * 73856093) ^ (y * 19349663) ^ (z * 83492791) ^ (s * 2654435761)
    h = (h ^ (h >> 13)) * 1274126177
    return ((h ^ (h >> 16)) & 0xFFFFFF) / 16777216.0


def material_of(c):
    """Clase de material por el color: 'snow', 'wood', 'cloth', 'stone', 'metal', 'green' u 'other'."""
    r, g, b = c
    mx, mn = max(c), min(c)
    sat = (mx - mn) / mx if mx > 0 else 0
    if mn > 0.74 and sat < 0.14: return 'snow'
    if r > g > b and sat > 0.28 and mx < 0.75: return 'wood'
    if r >= g >= b and sat <= 0.28 and mx > 0.45: return 'cloth'
    if g > r and g > b and sat > 0.2: return 'green'
    if mx < 0.3 and sat < 0.2: return 'metal'
    if sat < 0.2: return 'stone'
    return 'other'


def spill_points(M, colors, n=6, drop=6, dirs=((1, 0), (-1, 0), (0, 1), (0, -1)), min_y=0):
    """Bordes de cornisa con nieve de donde puede desprenderse (ambiente del paso, 16-10-2026):
    voxels de esos colores con aire encima y, al lado (en una de `dirs`), un vacío de al menos
    `drop` voxels hacia abajo, a partir de la altura `min_y`. Devuelve hasta n, repartidos (los más alejados entre sí), como
    pivotes [x, y, z, dx, dz]: el punto en el aire junto al borde y hacia dónde cae. Llamarla
    antes de vaciar el modelo (los huecos de dentro parecerían vacío)."""
    V = M.V
    cand = []
    for (x, y, z), v in V.items():
        if y < min_y or v[1] not in colors or (x, y + 1, z) in V: continue
        for dx, dz in dirs:
            if all((x + dx, y - k, z + dz) not in V for k in range(drop)):
                cand.append((x + dx, y, z + dz, dx, dz))
                break
    if not cand: return {}
    pts = [max(cand, key=lambda p: (p[1], p[0], p[2]))]
    while len(pts) < min(n, len(cand)):
        pts.append(max(cand, key=lambda p: min((p[0] - q[0]) ** 2 + (p[1] - q[1]) ** 2 + (p[2] - q[2]) ** 2 for q in pts)))
    return {'spill_%d' % i: list(p) for i, p in enumerate(pts)}


def refine(M, k=2, seed=0, strength=1.0, keep=None):
    """Devuelve el modelo a k veces su resolución (cada voxel pasa a k x k x k) con textura fina
    según el material de cada voxel: veta en la madera, trama en la tela, moteado y picaduras en
    la piedra, arañazos en el metal, brillo en la nieve, matices en el musgo; y las aristas de
    arriba algo más claras. keep(color) -> True deja ese color sin tocar (cristales, luces...).
    Las piezas y los pivotes se conservan (los pivotes hay que multiplicarlos por k)."""
    N = Model(S=M.S * k, seed=seed)
    for (x, y, z), v in M.V.items():
        for i in range(k):
            for j in range(k):
                for l in range(k):
                    N.V[(k * x + i, k * y + j, k * z + l)] = [v[0], v[1], v[2]]
    s = strength
    for (x, y, z), v in N.V.items():
        c = v[1]
        if v[2] or (keep and keep(c)) or not isinstance(c, tuple): continue
        m = material_of(c)
        h = _ih(x, y, z, seed)
        if m == 'wood':
            f = 0.5 + 0.5 * math.sin((x + z) * 0.9 + y * 0.12 + 4 * _ih(x // 7, y // 23, z // 7, seed))   # fibras
            c = lerp(c, (c[0] * 0.72, c[1] * 0.70, c[2] * 0.68), 0.35 * s * f)
            if h > 0.97: c = lerp(c, (0.12, 0.08, 0.05), 0.5 * s)                                         # poros
        elif m == 'cloth':
            w = ((x + y) % 2) ^ ((z + y) % 2)                                                               # trama
            c = lerp(c, (c[0] * 0.9, c[1] * 0.9, c[2] * 0.88), 0.5 * s * w)
            if h > 0.985: c = lerp(c, (0.3, 0.27, 0.22), 0.4 * s)
        elif m == 'stone':
            c = lerp(c, (c[0] * 0.75, c[1] * 0.75, c[2] * 0.75) if h < 0.5 else (min(1, c[0] * 1.15), min(1, c[1] * 1.15), min(1, c[2] * 1.15)), 0.35 * s * abs(h - 0.5) * 2)
            if h > 0.985: c = lerp(c, (0.05, 0.05, 0.05), 0.5 * s)                                         # picaduras
        elif m == 'metal':
            if _ih(x // 3, y, z, seed + 1) > 0.93: c = lerp(c, (0.55, 0.55, 0.56), 0.35 * s)              # arañazos
            else: c = lerp(c, (0, 0, 0), 0.12 * s * h)
        elif m == 'snow':
            if h > 0.97: c = lerp(c, (1.0, 1.0, 1.0), 0.6 * s)                                             # brillo
            elif h < 0.25: c = lerp(c, (0.78, 0.84, 0.92), 0.4 * s)
        elif m == 'green':
            c = lerp(c, (c[0] * 0.7, c[1] * 0.85, c[2] * 0.7) if h < 0.5 else (min(1, c[0] * 1.2), min(1, c[1] * 1.15), c[2]), 0.4 * s)
        else:
            c = lerp(c, (0, 0, 0), 0.08 * s * h)
        if (x, y + 1, z) not in N.V and m != 'snow':                                                      # arista de arriba
            c = lerp(c, (min(1, c[0] * 1.12), min(1, c[1] * 1.12), min(1, c[2] * 1.12)), 0.5 * s)
        v[1] = c
    for kk in [kk for kk in N.V if all((kk[0] + a, kk[1] + b, kk[2] + cc) in N.V for a, b, cc in
               ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)))]:
        del N.V[kk]                                                                                        # hueco
    return N
