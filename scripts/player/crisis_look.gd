class_name CrisisLook
extends Node3D
## Aspecto de una crisis de cordura (12-10-2026, petición del autor): que se vea claro que el
## personaje ha perdido la cabeza. Un aura morada (jirones en cubitos que suben, luz que late
## y una mancha que gira en el suelo) y cara de pánico superpuesta en la cabeza: ojos muy
## abiertos de 3×3 con la pupila pequeña y la boca abierta. Las cabezas de tools/cuerpo.py
## tienen el frente en z = 8 voxels, los ojos entre las filas 71 y 74 y la boca en la 65-67.

const FRONT := 8.0                          ## frente de la cara (voxels, desde el pivote en z)
const PURPLE := Color(0.62, 0.32, 1.0)

var _face: Node3D
var _wisps: GPUParticles3D
var _light: OmniLight3D
var _ground: MeshInstance3D
var _on := false
var _t := 0.0

func setup(model: Node3D) -> CrisisLook:
	_face = _make_face(model)
	return self

func _ready() -> void:
	_wisps = VoxelFx.emitter("crisis", 0.5)
	_wisps.position.y = 0.2
	add_child(_wisps)
	_light = OmniLight3D.new()
	_light.light_color = PURPLE
	_light.omni_range = 2.6
	_light.position.y = 1.0
	_light.visible = false
	add_child(_light)
	_ground = VoxelFx.ground(9, 0.9)
	_ground.position.y = 0.05
	_ground.visible = false
	add_child(_ground)
	set_on(false)

func set_on(on: bool) -> void:
	_on = on
	if _wisps: _wisps.emitting = on
	if _light: _light.visible = on
	if _ground: _ground.visible = on
	if _face: _face.visible = on

func _process(delta: float) -> void:
	if not _on:
		# VoxelFx.emitter lo enciende al entrar en escena (restart diferido, después de este
		# _ready): sin esto, los jirones salían desde el principio de la partida
		if _wisps.emitting: _wisps.emitting = false
		return
	_t += delta
	var pulse := 0.5 + 0.5 * sin(_t * 7.0)
	_light.light_energy = 0.9 + 0.8 * pulse
	_ground.material_override.set_shader_parameter("fade", 0.55 + 0.3 * pulse)
	if _face: _face.scale = Vector3.ONE * (1.0 + 0.04 * pulse)     # tiembla un poco

## Cara de pánico: cajitas sin iluminar pegadas al frente de la cabeza, un voxel por delante:
## salen por encima de la barba, el bigote, las cejas y la nariz, que asoman uno.
static func _make_face(model: Node3D) -> Node3D:
	var head := model.get_node_or_null("head") as Node3D
	if head == null: return null
	var vs: float = model.get_meta("voxel_size", 1.0 / 48.0)
	var piv: Array = (model.get_meta("pivots", {}) as Dictionary).get("head", [0, 64, 0])
	var root := Node3D.new()
	root.name = "PanicFace"
	head.add_child(root)
	var white := _mat(Color(0.95, 0.93, 0.9))
	var dark := _mat(Color(0.05, 0.03, 0.04))
	var red := _mat(Color(0.45, 0.08, 0.1))
	var boxes := []                                   # [x0, x1, y0, y1, dz, material]
	for ex in [-5, 2]:                                # ojos de 3×3, muy abiertos
		boxes.append([ex - 1, ex + 4, 71, 76, 1.04, dark])   # contorno: sin él, el blanco se confundía con la piel
		boxes.append([ex, ex + 3, 72, 75, 1.08, white])
		boxes.append([ex + 1, ex + 2, 73, 74, 1.12, dark])   # pupila pequeña
		boxes.append([ex, ex + 3, 77, 78, 1.06, dark])       # cejas arriba, de sorpresa
	boxes.append([-2, 2, 65, 68, 1.06, dark])        # boca abierta
	boxes.append([-1, 1, 65, 66, 1.12, red])         # lengua
	for b in boxes:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(float(b[1]) - float(b[0]), float(b[3]) - float(b[2]), 0.1) * vs
		mi.mesh = bm
		mi.material_override = b[5]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3((float(b[0]) + float(b[1])) * 0.5 - float(piv[0]),
			(float(b[2]) + float(b[3])) * 0.5 - float(piv[1]), FRONT + float(b[4]) - float(piv[2])) * vs
		root.add_child(mi)
	root.visible = false
	return root

static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m
