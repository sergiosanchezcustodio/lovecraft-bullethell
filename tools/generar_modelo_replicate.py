"""Atrezo a partir de una imagen de Replicate (04-10-2026): FLUX genera la pieza en el estilo
voxel del juego, TRELLIS (imagen -> 3D) la convierte en una malla con textura y aquí se
voxeliza a la resolución del juego con los colores de la textura.

    python tools/generar_modelo_replicate.py avion [--rehacer]

Deja la imagen en tools/replicate/<pieza>.png, la malla en tools/replicate/<pieza>.glb y el
modelo en models/atrezo_<pieza>.json. Coste: ~0,04 $ la imagen y ~0,05 $ la malla.
Necesita trimesh y scipy (solo para esta herramienta). Usa las funciones de
generar_iconos_armas.py (token, API, descarga).
"""
import os, sys, json
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import generar_iconos_armas as gi

ROOT = gi.ROOT
OUT = os.path.join(ROOT, 'tools', 'replicate')
IMAGE_MODEL = 'black-forest-labs/flux-1.1-pro'
MESH_MODEL = 'firtoz/trellis'

STYLE = ('isometric 3D voxel art render, MagicaVoxel style, clean small cubes, soft studio lighting, '
         'three-quarter view from above, the whole object visible and centered, plain white background, '
         'no text, no people')
PIECES = {
    'avion': {
        'prompt': ('A crashed 1930s Antarctic expedition monoplane, high wing, faded yellow fuselage with a red '
                   'stripe, black engine cowling with a broken wooden two-blade propeller, one wing bent down '
                   'into the snow, ski landing gear, patches of snow on the wings, abandoned'),
        'length_m': 8.0,              # lo más largo de la pieza, en metros
        'vpm': 32,                    # voxels por metro
    },
}


def voxelize(glb, length_m, vpm):
    """Voxels de la superficie de la malla con el color de la textura en cada punto."""
    import trimesh
    scene = trimesh.load(glb, force='scene')
    mesh = scene.dump(concatenate=True) if hasattr(scene, 'dump') else scene
    mesh.apply_transform(trimesh.transformations.rotation_matrix(0, [0, 1, 0]))
    ext = mesh.extents
    k = length_m / max(ext[0], ext[2])
    mesh.apply_scale(k)
    b = mesh.bounds
    mesh.apply_translation([-(b[0][0] + b[1][0]) / 2, -b[0][1], -(b[0][2] + b[1][2]) / 2])
    # muestreo denso de la superficie: varios puntos por voxel
    area = mesh.area
    n = int(area * (vpm ** 2) * 6)
    pts, faces = trimesh.sample.sample_surface(mesh, n)
    cols = color_at(mesh, pts, faces)
    vox = {}
    for p, c in zip(np.floor(pts * vpm).astype(int), cols):
        key = (int(p[0]), int(p[1]), int(p[2]))
        if key in vox: vox[key][0] += c; vox[key][1] += 1
        else: vox[key] = [c.astype(float), 1]
    out = []
    for (x, y, z), (c, cnt) in vox.items():
        r, g, bl = (c / cnt)[:3] / 255.0
        out.append([x, y, z, 'body', round(float(r), 3), round(float(g), 3), round(float(bl), 3), 0])
    return out


def color_at(mesh, pts, faces):
    """Color de la textura (o del vértice) en los puntos muestreados."""
    import trimesh
    vis = mesh.visual
    if isinstance(vis, trimesh.visual.texture.TextureVisuals) and vis.uv is not None and vis.material is not None:
        img = vis.material.baseColorTexture if hasattr(vis.material, 'baseColorTexture') else vis.material.image
        if img is not None:
            tex = np.asarray(img.convert('RGBA'))
            tri = mesh.triangles[faces]
            bary = trimesh.triangles.points_to_barycentric(tri, pts)
            uv = (vis.uv[mesh.faces[faces]] * bary[:, :, None]).sum(axis=1)
            h, w = tex.shape[:2]
            u = np.clip((uv[:, 0] % 1.0) * (w - 1), 0, w - 1).astype(int)
            v = np.clip((1 - uv[:, 1] % 1.0) * (h - 1), 0, h - 1).astype(int)
            return tex[v, u, :3].astype(float)
    vc = vis.to_color().vertex_colors if hasattr(vis, 'to_color') else np.full((len(mesh.vertices), 4), 180)
    return vc[mesh.faces[faces][:, 0], :3].astype(float)


def main():
    name = sys.argv[1] if len(sys.argv) > 1 else 'avion'
    redo = '--rehacer' in sys.argv
    piece = PIECES[name]
    os.makedirs(OUT, exist_ok=True)
    img_path = os.path.join(OUT, name + '.png')
    glb_path = os.path.join(OUT, name + '.glb')
    if redo or not os.path.exists(img_path):
        print('imagen…')
        out = gi.run(IMAGE_MODEL, {'prompt': '%s. %s' % (piece['prompt'], STYLE), 'aspect_ratio': '1:1',
                                    'output_format': 'png', 'safety_tolerance': 5})
        open(img_path, 'wb').write(gi.download(out if isinstance(out, str) else out[0]))
    if redo or not os.path.exists(glb_path):
        print('malla…')
        ver = gi.api('GET', '/models/%s' % MESH_MODEL)['latest_version']['id']
        out = gi.run(MESH_MODEL, {'images': [gi.data_uri(img_path)], 'generate_model': True, 'texture_size': 1024,
                                  'mesh_simplify': 0.95, 'generate_color': False, 'generate_normal': False},
                     version=ver)
        url = out.get('model_file') if isinstance(out, dict) else out
        open(glb_path, 'wb').write(gi.download(url))
    vox = voxelize(glb_path, piece['length_m'], piece['vpm'])
    data = {'voxel_size': 1.0 / piece['vpm'], 'pivots': {'body': [0, 0, 0]}, 'voxels': vox,
            'roughness': 0.85, 'specular': 0.3, 'no_bottom': True}
    json.dump(data, open(os.path.join(ROOT, 'models', 'atrezo_%s.json' % name), 'w'))
    print('atrezo_%s: %d voxels' % (name, len(vox)))


if __name__ == '__main__':
    main()
