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
    # Prueba (09-10-2026): las mismas piezas del campamento que hay hechas a mano, para comparar.
    # Salen como models/rep_<pieza>.json y no sustituyen a las de atrezo_.
    'tienda': {
        'prompt': ('A 1930s Antarctic expedition ridge tent made of weathered grey-green canvas, two wooden poles, '
                   'guy ropes pegged into the snow, the front flap half open showing a dark interior, snow piled '
                   'on the lower edges'),
        'length_m': 5.04, 'vpm': 32, 'out': 'prueba_tienda',
    },
    'trineo': {
        'prompt': ('A 1930s wooden polar expedition dog sled with long curved runners, loaded with wooden crates and '
                   'canvas bags tied with ropes, a little snow on top'),
        'length_m': 2.62, 'vpm': 48, 'out': 'prueba_trineo',
    },
    'farol': {
        'prompt': ('A 1930s expedition lamp post: a tall wooden pole with an iron bracket at the top from which hangs a '
                   'brass storm lantern with glass panes, the base wedged in a small mound of snow'),
        'length_m': 1.04, 'vpm': 48, 'out': 'prueba_farol',
    },
    'bidon': {
        'prompt': ('A dented 1930s steel fuel drum painted dark red with two raised rings, faded white stencil '
                   'letters, rust stains, a little snow on the lid'),
        'length_m': 0.96, 'vpm': 48, 'fit': 'height', 'out': 'prueba_bidon',
    },
    'roca': {
        'prompt': ('A dark grey Antarctic boulder with angular cracked faces, patches of lichen and snow '
                   'resting on top'),
        'length_m': 1.19, 'vpm': 20, 'out': 'atrezo_roca_nevada',
    },
    # Segunda tanda (09-10-2026): piezas macizas de varios niveles, como prueba_<pieza>
    'roca_grande': {
        'prompt': ('A large dark grey mountain boulder with sharp angular fractured faces and deep cracks, '
                   'thin streaks of snow and frost in the crevices, cold and harsh'),
        'length_m': 1.62, 'vpm': 20, 'out': 'atrezo_roca_grande',
    },
    'bloque_ciclopeo': {
        'prompt': ('A huge ancient cyclopean stone block of dark grey slate, eroded edges, carved with a worn '
                   'five-pointed star relief of an alien elder race, frost in the grooves'),
        'length_m': 1.25, 'vpm': 32, 'out': 'prueba_bloque_ciclopeo',
    },
    'barril_innsmouth': {
        'prompt': ('An old wooden herring barrel from a 1920s New England fishing harbour, dark wet staves, '
                   'rusty iron hoops, green algae stains at the bottom, a few fish scales'),
        'length_m': 0.94, 'vpm': 32, 'fit': 'height', 'out': 'prueba_barril_innsmouth',
    },
    'roca_arrecife': {
        'prompt': ('A jagged black volcanic reef rock covered with barnacles, mussels and dark green seaweed, '
                   'wet and glistening, a few small glowing green spots'),
        'length_m': 2.25, 'vpm': 20, 'out': 'arr_roca_1',
    },
    'idolo': {
        'prompt': ('A small ancient idol of Cthulhu carved in greenish-black stone: a squatting winged figure '
                   'with an octopus head and a mass of face tentacles, rudimentary wings, claws on its knees, '
                   'sitting on a rectangular pedestal with strange hieroglyphs'),
        'length_m': 1.72, 'vpm': 32, 'fit': 'height', 'out': 'cth_idolo',
    },
    'escultura': {
        'prompt': ('A half-finished white plaster sculpture of a monstrous winged creature with tentacles, '
                   'rough unfinished chisel marks, standing on a dark wooden sculptor stand'),
        'length_m': 1.5, 'vpm': 32, 'fit': 'height', 'out': 'prv_escultura_1',
    },
    # Tercera tanda (09-10-2026)
    'escombros': {
        'prompt': ('A low pile of rubble from a collapsed 1920s New England brick house: broken red bricks, '
                   'splintered grey boards, a few roof slates, wet and dirty, spread flat on the ground'),
        'length_m': 2.34, 'vpm': 20, 'out': 'inn_escombros',
    },
    'cajas_pescado': {
        'prompt': ('A stack of three old wooden fish crates on a 1920s harbour, weathered grey slats, one crate '
                   'full of silver fish, wet, a little seaweed'),
        'length_m': 1.56, 'vpm': 32, 'out': 'prueba_cajas_pescado',
    },
    'fardos': {
        'prompt': ('A stack of cargo bales on a 1920s harbour dock: burlap sacks and canvas-wrapped bundles tied '
                   'with thick ropes, piled on a wooden pallet, wet from the rain'),
        'length_m': 1.38, 'vpm': 32, 'out': 'prueba_fardos',
    },
    'tocon': {
        'prompt': ('A rotten dead tree stump in a swamp, dark grey wet bark, broken jagged top, exposed gnarled '
                   'roots, patches of moss and hanging Spanish moss'),
        'length_m': 1.0, 'vpm': 32, 'value': 0.6, 'out': 'pan_tocon',
    },
    'sacos': {
        'prompt': ('Three heavy burlap sacks of sculptor clay leaning against each other, one open showing grey '
                   'wet clay, dusty with dried clay stains'),
        'length_m': 1.22, 'vpm': 32, 'out': 'prueba_sacos',
    },
    'roca_arrecife_2': {
        'prompt': ('A tall jagged black basalt reef rock spire covered with barnacles, mussels and dark green '
                   'seaweed, wet and glistening, a few small glowing green spots'),
        'length_m': 2.0, 'vpm': 20, 'fit': 'height', 'value': 0.5, 'out': 'arr_roca_2',
    },
    # Cuarta tanda (09-10-2026)
    'rly_bloque': {
        'prompt': ('A massive cyclopean stone block from the sunken city of Rlyeh, greenish-black slimy stone, '
                   'faces that meet at wrong impossible angles, worn alien carvings, patches of green slime and '
                   'seaweed'),
        'length_m': 1.91, 'vpm': 32, 'value': 0.7, 'out': 'prueba_rly_bloque',
    },
    'rly_monolito': {
        'prompt': ('A very tall narrow twisted monolith of greenish-black stone from the sunken city of Rlyeh, '
                   'leaning and bent at impossible angles, covered with worn alien hieroglyphs and green slime'),
        'length_m': 5.94, 'vpm': 32, 'fit': 'height', 'value': 0.7, 'out': 'prueba_rly_monolito',
    },
    'cristales': {
        'prompt': ('A cluster of glowing pale blue ice crystals growing from a dark rock, sharp hexagonal '
                   'shards of different heights, faint inner light'),
        'length_m': 0.94, 'vpm': 32, 'fit': 'height', 'glow': [0.55, 0.25], 'out': 'prueba_cristales',
    },
    'bloques_hielo': {
        'prompt': ('A stack of rough cut blocks of compacted snow and blue ice, like bricks for an igloo, '
                   'irregular edges, frost and powder snow on top'),
        'length_m': 2.12, 'vpm': 32, 'out': 'prueba_bloques_hielo',
    },
    'caja': {
        'prompt': ('A small wooden supply crate of a 1930s polar expedition, nailed weathered planks, dark iron '
                   'corner brackets, plain sides with no letters and no markings, a little snow on the lid'),
        'length_m': 0.62, 'vpm': 48, 'fit': 'height', 'sat': 0.7, 'out': 'atrezo_caja',
    },
}


def voxelize(glb, length_m, vpm, fit='horizontal'):
    """Voxels de la superficie de la malla con el color de la textura en cada punto."""
    import trimesh
    scene = trimesh.load(glb, force='scene')
    mesh = scene.dump(concatenate=True) if hasattr(scene, 'dump') else scene
    mesh.apply_transform(trimesh.transformations.rotation_matrix(0, [0, 1, 0]))
    ext = mesh.extents
    k = length_m / (ext[1] if fit == 'height' else max(ext[0], ext[2]))   # piezas altas: por la altura
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
    return vox


def foreground(img_path, tol=70):
    """Píxeles de la pieza en la imagen de FLUX: se quita el fondo inundando desde los bordes
    (blanco o gris claro, con sus sombras suaves). Antes se quitaba solo el blanco y las sombras
    del fondo aclaraban todos los colores."""
    from PIL import Image, ImageDraw
    im = Image.open(img_path).convert('RGB')
    im.thumbnail((384, 384))
    mark = im.copy()
    w, h = mark.size
    for x, y in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)]:
        ImageDraw.floodfill(mark, (x, y), (255, 0, 255), thresh=tol)
    a = np.asarray(im, dtype=float) / 255.0
    m = np.asarray(mark)
    keep = ~((m[:, :, 0] == 255) & (m[:, :, 1] == 0) & (m[:, :, 2] == 255))
    return a[keep].reshape(-1, 3)


def postprocess(vox, img_path, colors=20, saturation=1.0, value=1.0, glow=None):
    """Arreglos tras voxelizar (09-10-2026):
    - Colores: la textura de TRELLIS sale más oscura y apagada que la imagen de FLUX; se lleva su
      brillo medio y su saturación a los de la imagen (sin el fondo blanco).
    - Paleta: k-medias a `colors` colores, que quita el ruido de color de la textura.
    - Hueco: fuera los voxels con los seis vecinos ocupados (no se ven y pesan)."""
    from PIL import Image
    from scipy.cluster.vq import kmeans2
    occ = set(vox.keys())                                         # primero, solo la superficie: los
    nb = lambda x, y, z: ((x+1,y,z),(x-1,y,z),(x,y+1,z),(x,y-1,z),(x,y,z+1),(x,y,z-1))   # interiores, oscuros,
    vox = {k: v for k, v in vox.items() if not all(q in occ for q in nb(*k))}   # se llevaban los tonos oscuros
    keys = list(vox.keys())
    cols = np.array([(c / cnt)[:3] / 255.0 for c, cnt in vox.values()])
    px = foreground(img_path)
    lum = lambda a: a @ np.array([0.299, 0.587, 0.114])
    sat = lambda a: a.max(axis=1) - a.min(axis=1)
    # cada canal con la misma distribución que en la imagen (por cuantiles): conserva los
    # contrastes de la textura con los tonos de FLUX
    rng = np.random.default_rng(1)
    ref = px[rng.choice(len(px), min(len(px), 60000), replace=False)]
    q = np.linspace(0, 1, 101)
    for ch in range(3):
        src = np.quantile(cols[:, ch], q)
        dst = np.quantile(ref[:, ch], q)
        cols[:, ch] = np.interp(cols[:, ch], src, dst)
    # y se ajusta a la paleta de la imagen: colores limpios, sin ruido
    pal, _ = kmeans2(ref, colors, minit='++', seed=1)
    d = ((cols[:, None, :] - pal[None, :, :]) ** 2).sum(axis=2)
    cols = np.clip(pal[d.argmin(axis=1)], 0.0, 1.0)
    if saturation != 1.0:                                                # piezas de fondo: color más apagado
        g = lum(cols)[:, None]
        cols = np.clip(g + (cols - g) * saturation, 0.0, 1.0)
    cols = np.clip(cols * value, 0.0, 1.0)                        # piezas oscuras: la imagen lleva sombras
    # glow: (brillo mínimo, saturación mínima): esos voxels brillan solos (cristales, runas)
    lit = (lum(cols) >= glow[0]) & (sat(cols) >= glow[1]) if glow else np.zeros(len(cols), bool)
    out = []
    for (x, y, z), c, g in zip(keys, cols, lit):
        out.append([x, y, z, 'body', round(float(c[0]), 3), round(float(c[1]), 3), round(float(c[2]), 3), int(g)])
    return out


def _unused(vox):
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
    vox = postprocess(voxelize(glb_path, piece['length_m'], piece['vpm'], piece.get('fit', 'horizontal')), img_path,
                      saturation=piece.get('sat', 1.0), value=piece.get('value', 1.0), glow=piece.get('glow'))
    data = {'voxel_size': 1.0 / piece['vpm'], 'pivots': {'body': [0, 0, 0]}, 'voxels': vox,
            'roughness': 0.85, 'specular': 0.3, 'no_bottom': True}
    out_name = piece.get('out', 'atrezo_%s' % name)
    json.dump(data, open(os.path.join(ROOT, 'models', '%s.json' % out_name), 'w'))
    print('%s: %d voxels' % (out_name, len(vox)))


if __name__ == '__main__':
    main()
