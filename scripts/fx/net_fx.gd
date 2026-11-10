class_name NetFx
extends Node3D
## Red de pesca caída en el suelo: una cuadrícula de cuerda (barras finas de voxel) con
## plomos en el borde, que se queda mientras inmoviliza y luego se hunde. Solo visual.
## Fase 18 (10-11-2026): cae abriéndose y ondulando, los plomos llegan un poco después, mientras
## sujeta se tensa a tirones (las cuerdas se afinan, se aclaran y la red se encoge) y al soltar
## se afloja y se hunde.

var _life := 2.0
var _t := 0.0
var _mat: StandardMaterial3D
var _bars: Array[MeshInstance3D] = []
var _base: Array[Vector3] = []                   ## posición y grosor de reposo de cada cuerda: {x, z, fase}
var _leads: Array[MeshInstance3D] = []
var _lead_at: Array[Vector3] = []
var _tugs: PackedFloat32Array = []               ## instantes de los tirones (los de debajo forcejean)

const ROPE := Color(0.72, 0.64, 0.44)
const TAUT := Color(0.9, 0.84, 0.66)              ## cuerda tensa: más clara
const FALL := 0.22                                ## s que tarda en posarse
const DROP := 0.9                                 ## m desde los que cae

## Se anima en _process con la raíz quieta: sin interpolación de la física, que avisaba
## («Interpolated instance triggered from outside physics process», 06-11-2026).
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func setup(pos: Vector3, radius: float, life: float) -> NetFx:
	position = Vector3(pos.x, 0.06, pos.z)
	_life = life
	_mat = VoxelFx.std()
	_mat.albedo_color = ROPE
	_mat.roughness = 0.9
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var n := int(clampf(radius * 2.5, 4.0, 10.0))
	for i in n + 1:                                  # cuerdas en las dos direcciones
		var o := lerpf(-radius, radius, float(i) / n)
		var half := sqrt(maxf(radius * radius - o * o, 0.0))
		if half < 0.1: continue
		_bar(Vector3(0.05, 0.04, half * 2.0), Vector3(o, 0, 0), float(i) * 1.7)
		_bar(Vector3(half * 2.0, 0.04, 0.05), Vector3(0, 0.02, o), float(i) * 1.7 + 0.9)
	if _lead == null:                                # plomos del borde (material y malla compartidos, 06-11-2026)
		_lead = VoxelFx.std()
		_lead.albedo_color = Color(0.3, 0.3, 0.33)
	for k in 10:
		var a := TAU * k / 10.0
		var mi := MeshInstance3D.new()
		mi.mesh = VoxelFx.box(Vector3.ONE * 0.12)
		mi.material_override = _lead
		var at := Vector3(cos(a) * radius, 0.04, sin(a) * radius)
		mi.position = at + Vector3(0, DROP, 0)
		add_child(mi)
		_leads.append(mi)
		_lead_at.append(at)
	var t := FALL + 0.15                             # tirones al azar mientras sujeta
	while t < life - 0.2:
		_tugs.append(t)
		t += randf_range(0.35, 0.7)
	position.y += DROP
	scale = Vector3(1.25, 1.0, 1.25)
	return self

static var _lead: StandardMaterial3D

func _bar(size: Vector3, at: Vector3, phase: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = VoxelFx.box1()                         # caja de 1 m: el tamaño, en la escala
	mi.scale = size
	mi.material_override = _mat
	mi.position = at
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_bars.append(mi)
	_base.append(Vector3(size.x, size.z, phase))

## Tensión de 0 a 1: sube de golpe en cada tirón y cede despacio.
func _tension() -> float:
	var k := 0.0
	for tt in _tugs:
		var d := _t - tt
		if d < 0.0: break
		if d < 0.5: k = maxf(k, (1.0 - d / 0.5) * minf(d / 0.05, 1.0))
	return k

func _process(delta: float) -> void:
	_t += delta
	var fall := clampf(_t / FALL, 0.0, 1.0)
	var end := _t - _life                            # >0: suelta y se hunde
	var k := 1.0 - smoothstep(0.0, 0.4, end)
	var taut := _tension() if end < 0.0 else 0.0
	# caída: baja acelerando y se abre; posada, encoge con cada tirón; al soltar, se afloja
	position.y = 0.06 + DROP * (1.0 - fall * fall)
	var open := lerpf(1.25, 1.0, fall) - 0.05 * taut + 0.06 * maxf(end, 0.0) / 0.4
	scale = Vector3(open, 1.0, open)
	# ondas: grandes al caer, casi nada después; las cuerdas tensas quedan rectas
	var amp := lerpf(0.09, 0.012, smoothstep(FALL, FALL + 0.45, _t)) * (1.0 - taut)
	var sag := -0.05 * maxf(end, 0.0) / 0.4
	for i in _bars.size():
		var b := _bars[i]
		var base := _base[i]
		var w := sin(base.z + _t * 17.0)
		b.position.y = (0.02 if i % 2 == 1 else 0.0) + amp * w + sag
		var thin := 1.0 - 0.35 * taut
		if base.x < base.y: b.scale = Vector3(base.x * thin, 0.04, base.y)
		else: b.scale = Vector3(base.x, 0.04, base.y * thin)
	# plomos: llegan un poco después que la red y rebotan una vez
	var lf := clampf((_t - 0.05) / FALL, 0.0, 1.0)
	var bounce := 0.06 * sin(clampf((_t - 0.05 - FALL) / 0.18, 0.0, 1.0) * PI)
	for j in _leads.size():
		_leads[j].position = _lead_at[j] + Vector3(0, DROP * (1.0 - lf * lf) - DROP * (1.0 - fall * fall) + bounce, 0)
	var c := ROPE.lerp(TAUT, taut)
	_mat.albedo_color = Color(c.r, c.g, c.b, k)
	if end >= 0.4: queue_free()
