class_name WhipFx
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Latigazo (Látigo, hito 8.8): una tralla de cubos de cuero que barre el sector de un lado a
## otro en una décima de segundo y se apaga. Solo visual: el daño lo aplica el arma.
## Hito 18.7: más tramos y más finos hacia la punta, una onda que recorre la cuerda al barrer,
## estela en la punta y, al acabar el barrido, el restallido (destello y chispas).

var dir := Vector3.FORWARD
var length := 4.5
var half := 0.6                              ## medio sector (rad)
var _t := 0.0
var _bits: Array[MeshInstance3D] = []

const LIFE := 0.28
const SEGMENTS := 22
var _cracked := false

## Se anima en _process con la raíz quieta: sin interpolación de la física, que avisaba
## («Interpolated instance triggered from outside physics process», 06-11-2026).
func _init() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF

func setup(origin: Vector3, p_dir: Vector3, p_length: float, spread_deg: float) -> WhipFx:
	position = Vector3(origin.x, 0.9, origin.z)
	dir = Vector3(p_dir.x, 0, p_dir.z).normalized()
	length = p_length
	half = deg_to_rad(spread_deg) * 0.5
	return self

## Malla de los trozos del látigo, con su material, compartida (06-11-2026: antes, nueva en cada latigazo).
static var _bm: BoxMesh

func _ready() -> void:
	if _bm == null:
		_bm = BoxMesh.new()
		_bm.size = Vector3(0.1, 0.1, 1.0)            # tramo estirado de un punto al siguiente (hito 18.7)
		var mat := VoxelFx.std()
		mat.albedo_color = Color(0.32, 0.2, 0.12)
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.75, 0.5)
		mat.emission_energy_multiplier = 0.25
		_bm.material = mat
	var bm := _bm
	for i in SEGMENTS:
		var mi := MeshInstance3D.new()
		mi.mesh = bm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_bits.append(mi)
	FxTrails.attach.call_deferred(_bits[SEGMENTS - 1], "lash")       # la punta deja estela
	_process(0.0)

func _process(delta: float) -> void:
	_t += delta
	var u := clampf(_t / LIFE, 0.0, 1.0)
	var s := smoothstep(0.0, 0.75, u)
	var sweep := lerpf(-half, half, s)                               # barre de un lado a otro
	var fade := 1.0 - smoothstep(0.78, 1.0, u)
	var prev := Vector3.ZERO                                          # la mano
	for i in SEGMENTS:
		var k := float(i + 1) / SEGMENTS
		var lag := 0.35 * (1.0 - s) * k                                 # la punta llega tarde
		var a := sweep * (0.4 + 0.6 * k) - sweep * 0.25 * (1.0 - k) - signf(half) * lag
		var d := dir.rotated(Vector3.UP, a)
		var wave := sin(k * 9.0 - u * 26.0) * 0.18 * k * (1.0 - s * 0.7)   # la onda corre hacia la punta
		var p := d * length * k + d.cross(Vector3.UP) * wave + Vector3(0, -0.35 * k * k + 0.1 * sin(k * 6.0 - u * 20.0) * k, 0)
		var seg := p - prev
		var th := lerpf(1.0, 0.35, k) * fade                            # más fina hacia la punta
		if seg.length_squared() > 0.0001 and th > 0.001:
			var b := Basis.looking_at(seg.normalized(), Vector3.UP)
			_bits[i].transform = Transform3D(b * Basis.from_scale(Vector3(th, th, seg.length() * 1.15)), (prev + p) * 0.5)
			_bits[i].visible = true
		else:
			_bits[i].visible = false
		prev = p
	if not _cracked and u >= 0.72:                                    # restallido en la punta
		_cracked = true
		var tip := _bits[SEGMENTS - 1].global_position
		HitSparks.burst("crack", tip)
	if _t >= LIFE: queue_free()
