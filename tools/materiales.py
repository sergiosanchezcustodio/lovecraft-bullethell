"""Texturas por material para los personajes voxel (28-09-2026).

En voxel, la textura es el color de cada voxel. Cada material tiene su patrón, con
amplitud baja y ruido suave en 3D (nunca por bloques alineados con los ejes: el grano por
bloques de 2 voxels dibujaba rayas verticales):
- lona: sarga diagonal fina y zonas gastadas;
- borreguillo: rizos, motas claras y oscuras de 1-2 voxels;
- cuero: vetas suaves, rozaduras más claras, más oscuro abajo;
- lana: moteado fino;
- punto: filas de punto;
- pelo: mechones en el sentido del pelo (franjas verticales suaves), raíces más oscuras;
- piel: variación cálida muy suave.
Además, las caras superiores de cada volumen (voxel con el de encima vacío) se aclaran un
poco: marca los volúmenes como la luz en la referencia.

Uso: texturize(M, {color_base: 'material', ...}) después de modelar y pintar los detalles.
"""


def _mul(c, k):
    return tuple(max(0.0, min(1.0, ch * k)) for ch in c)


def _warm(c, k):
    """Más cálido (k > 0) o más frío (k < 0) sin cambiar mucho el brillo."""
    return (max(0.0, min(1.0, c[0] * (1 + k))), c[1], max(0.0, min(1.0, c[2] * (1 - k))))


def texturize(M, materials, top_light=0.07):
    """materials: {color_base: nombre}. Solo se tocan los voxels con esos colores base."""
    V = M.V
    seams = getattr(M, 'seams', set())
    for (x, y, z), v in list(V.items()):
        mat = materials.get(v[1])
        if mat is None: continue
        c = v[1]
        h = M.hsh(x, y, z) - 0.5                 # -0,5 .. 0,5 por voxel
        if mat == 'lona':
            k = 1.0
            if (x + y) % 3 == 0 or (z + y) % 3 == 0: k -= 0.07           # sarga
            k += (M.noise(x, y, z, 7.0) - 0.5) * 0.18                    # zonas gastadas
            k += h * 0.03
            c = _mul(c, k)
        elif mat == 'borreguillo':
            curl = M.noise(x * 1.3, y * 1.3, z * 1.3, 1.6) - 0.5
            c = _mul(c, 1.0 + curl * 0.22 + h * 0.08)
        elif mat == 'cuero':
            k = 1.0 + (M.noise(x, y * 0.5, z, 3.5) - 0.5) * 0.24 + h * 0.05
            if M.hsh(x, y, z + 7) > 0.93: k += 0.16                       # rozaduras
            if M.hsh(x + 3, y, z) > 0.96: k -= 0.14                       # arañazos oscuros
            c = _mul(c, k)
        elif mat == 'lana':
            k = 1.0 + h * 0.13 + (M.noise(x, y, z, 5.0) - 0.5) * 0.1
            if (y + (x + z) // 2) % 4 == 0: k -= 0.05                     # tejido de espiga
            c = _mul(c, k)
        elif mat == 'punto':
            k = 1.0 + (0.06 if y % 2 == 0 else -0.04)
            if (x + (y // 2)) % 2 == 0: k -= 0.03
            c = _mul(c, k + h * 0.03)
        elif mat == 'pelo':
            strand = M.noise(x * 1.6, y * 0.35, z * 1.6, 1.8) - 0.5         # franjas en el sentido del pelo
            c = _mul(c, 1.0 + strand * 0.3 + h * 0.05)
        elif mat == 'piel':
            c = _warm(_mul(c, 1.0 + (M.noise(x, y, z, 6.0) - 0.5) * 0.05), (M.noise(x + 50, y, z, 8.0) - 0.5) * 0.06)
        if (x, y, z) in seams: c = _mul(c, 0.8)                            # costuras
        # luz en las caras superiores
        if top_light and (x, y + 1, z) not in V:
            c = _mul(c, 1.0 + top_light)
        v[1] = c
