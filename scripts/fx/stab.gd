class_name Stab
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Puñalada de la Daga ritual (hoja violeta) o estocada del bastón estoque (hoja de acero
## más larga): sale del personaje hacia el enemigo, entra y se desvanece. Solo visual: el
## daño lo aplica el arma.

var _from := Vector3.ZERO
var _dir := Vector3.FORWARD
var _reach := 1.0
var _t := 0.0
var _blade: MeshInstance3D
var _mat: StandardMaterial3D
var color := Color(0.55, 0.25, 0.75, 0.95)
var blade := 0.6
var _trail: MeshInstance3D
var _trail_mat: StandardMaterial3D
var _hit := false

const LIFE := 0.2

func setup(from: Vector3, to: Vector3) -> Stab:
	_from = Vector3(from.x, 0.9, from.z)
	var d := Vector3(to.x - from.x, 0, to.z - from.z)
	_reach = maxf(d.length() - 0.2, 0.3)
	_dir = d.normalized() if d.length() > 0.01 else Vector3.FORWARD
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	_blade = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.14, 0.07, blade)
	_blade.mesh = bm
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = color
	_blade.material_override = _mat
	_blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_blade)
	# estela de la hoja (11-10-2026): un trazo aditivo detrás que se estira y se apaga
	_trail = MeshInstance3D.new()
	var tb := BoxMesh.new()
	tb.size = Vector3(0.22, 0.03, 1.0)
	_trail.mesh = tb
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_trail.material_override = _trail_mat
	_trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_trail)
	_process(0.0)

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	var u := clampf(_t / LIFE, 0.0, 1.0)
	var go := 1.0 - pow(1.0 - minf(u * 1.8, 1.0), 3.0)               # sale rápida y se clava
	global_position = _from + _dir * (0.3 + _reach * go)
	look_at(global_position + _dir, Vector3.UP)
	var a := color.a * (1.0 - smoothstep(0.55, 1.0, u))
	_mat.albedo_color.a = a
	var tl := maxf(0.05, (0.3 + _reach * go) - 0.3) * (1.0 - u * 0.5)   # desde donde salió
	_trail.scale = Vector3(1.0 - u * 0.6, 1.0, tl)
	_trail.position = Vector3(0, 0, tl * 0.5 + blade * 0.3)              # detrás (look_at mira por -Z)
	_trail_mat.albedo_color = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6, a * 0.9)
	if go >= 0.98 and not _hit:                                          # se clava: chispas
		_hit = true
		var z := VoxelFx.emitter("zap", 0.9, true, false, Color(color.r, color.g, color.b))
		z.position = global_position + _dir * blade * 0.5
		get_parent().add_child(z)
		z.finished.connect(z.queue_free)
	if _t >= LIFE: queue_free()
