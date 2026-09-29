class_name NetFx
extends Node3D
## Red de pesca caída en el suelo: una cuadrícula de cuerda (barras finas de voxel) con
## plomos en el borde, que se queda mientras inmoviliza y luego se hunde. Solo visual.

var _life := 2.0
var _t := 0.0
var _mat: StandardMaterial3D

const ROPE := Color(0.72, 0.64, 0.44)

func setup(pos: Vector3, radius: float, life: float) -> NetFx:
	position = Vector3(pos.x, 0.06, pos.z)
	_life = life
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = ROPE
	_mat.roughness = 0.9
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var n := int(clampf(radius * 2.5, 4.0, 10.0))
	for i in n + 1:                                  # cuerdas en las dos direcciones
		var o := lerpf(-radius, radius, float(i) / n)
		var half := sqrt(maxf(radius * radius - o * o, 0.0))
		if half < 0.1: continue
		_bar(Vector3(0.05, 0.04, half * 2.0), Vector3(o, 0, 0))
		_bar(Vector3(half * 2.0, 0.04, 0.05), Vector3(0, 0.02, o))
	var lead := StandardMaterial3D.new()             # plomos del borde
	lead.albedo_color = Color(0.3, 0.3, 0.33)
	for k in 10:
		var a := TAU * k / 10.0
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE * 0.12
		mi.mesh = bm
		mi.material_override = lead
		mi.position = Vector3(cos(a) * radius, 0.04, sin(a) * radius)
		add_child(mi)
	return self

func _bar(size: Vector3, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func _process(delta: float) -> void:
	_t += delta
	var k := 1.0 - smoothstep(_life, _life + 0.4, _t)
	_mat.albedo_color.a = k
	scale = Vector3.ONE * lerpf(1.15, 1.0, clampf(_t / 0.12, 0.0, 1.0))   # cae abriéndose
	if _t >= _life + 0.4: queue_free()
