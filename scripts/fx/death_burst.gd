class_name DeathBurst
extends Node3D
## Muerte de un enemigo (rehecha el 11-10-2026): trozos en cubitos con los colores reales de
## su modelo (`palette_of`, una vez por modelo) que saltan, giran y rebotan en el suelo, un
## fogonazo breve de su color más claro (élites y únicos) y una salpicadura irregular en celdas que se seca.
## Las élites y los seres únicos estallan más.

const FALLBACK := [Color(0.85, 0.85, 0.85), Color(0.5, 0.5, 0.5), Color(0.3, 0.3, 0.3), Color(0.6, 0.6, 0.6)]
const LIFE := 2.0                              ## la salpicadura (con muchas muertes, menos manchas a la vez)
static var _chunk_mats := {}
static var _palettes := {}                     ## modelo -> 4 colores (de más a menos frecuente)

var model := "pinguino"
var radius := 0.5
var big := false                               ## élite o ser único
var _t := 0.0
var _stain_mat: ShaderMaterial
var _stain: MeshInstance3D
var _cols: Array = FALLBACK

func setup(p_model: String, p_radius: float, model_root: Node3D = null, p_big := false) -> void:
	model = p_model
	radius = p_radius
	big = p_big
	_cols = palette_of(model, model_root)

## Los 4 colores más frecuentes de las mallas del modelo (colores de vértice), agrupados en
## escalones de 1/6 para que los matices de un mismo material cuenten juntos.
static func palette_of(p_model: String, root: Node3D) -> Array:
	if _palettes.has(p_model): return _palettes[p_model]
	if root == null or not root.has_meta("meshes"): return FALLBACK
	var count := {}
	var sum := {}
	for mi: MeshInstance3D in root.get_meta("meshes"):
		if mi.mesh == null: continue
		for si in mi.mesh.get_surface_count():
			var cols = mi.mesh.surface_get_arrays(si)[Mesh.ARRAY_COLOR]
			if cols == null: continue
			var step := maxi(1, cols.size() / 600)
			for i in range(0, cols.size(), step * 4):        # 4 vértices por cara
				var c: Color = cols[i]
				var k := Vector3i(int(c.r * 6.0), int(c.g * 6.0), int(c.b * 6.0))
				count[k] = int(count.get(k, 0)) + 1
				sum[k] = (sum.get(k, Color(0, 0, 0, 0)) as Color) + c
	if count.is_empty(): return FALLBACK
	var keys := count.keys()
	keys.sort_custom(func(a, b) -> bool: return count[a] > count[b])
	var out := []
	for k in keys.slice(0, 4):
		var c: Color = sum[k] / float(count[k])
		out.append(Color(c.r, c.g, c.b, 1.0))
	while out.size() < 4: out.append(out[out.size() - 1])
	_palettes[p_model] = out
	return out

func _ready() -> void:
	var r := radius * (1.5 if big else 1.0)
	var chunks := VoxelFx.emitter("chunks", r, true)
	var key := "%s|%.1f" % [model, r]                 # material con sus colores, uno por modelo
	if not _chunk_mats.has(key):
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.45, 0.75, 1.0])
		g.colors = PackedColorArray([_cols[0], _cols[1], _cols[2], _cols[3]])
		var gt := GradientTexture1D.new()
		gt.gradient = g
		var m := chunks.process_material.duplicate() as ParticleProcessMaterial
		m.color_initial_ramp = gt
		_chunk_mats[key] = m
	chunks.process_material = _chunk_mats[key]
	chunks.position.y = radius
	add_child(chunks)
	if big:                                        # fogonazo de su color más claro, solo élites y únicos
		var light: Color = _cols[0]
		for c: Color in _cols: if c.get_luminance() > light.get_luminance(): light = c
		var puff := VoxelFx.emitter("death_puff", r, true, false, Color(light.r, light.g, light.b, 1.0))
		puff.position.y = radius
		add_child(puff)
	VoxelFx.ensure_floor(get_parent())
	var splat := VoxelFx.ground(6, r * 1.3)
	splat.position.y = 0.03
	_stain_mat = splat.material_override
	_stain = splat
	var dark: Color = _cols[1].darkened(0.35)
	_stain_mat.set_shader_parameter("tint", Color(dark.r, dark.g, dark.b))
	add_child(splat)

func _process(delta: float) -> void:
	_t += delta
	_stain_mat.set_shader_parameter("age", clampf(_t / LIFE, 0.0, 1.0))
	if _t > LIFE:                                   # la mancha seca se queda un rato (hito 11.1)
		GroundMarks.keep(get_parent(), _stain)
		queue_free()
