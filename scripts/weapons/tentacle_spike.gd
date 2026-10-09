class_name TentacleSpike
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Tentáculos de Shub (hito 8.8): aviso en el suelo y, al cabo de WARN s, un tentáculo de cubos
## verdinegros brota, daña y aturde a los de su radio, se retuerce un momento y se hunde.

var world: CombatWorld
var radius := 1.0
var damage := 20.0
var stun := 0.4
var bonus := {}
var _t := 0.0
var _struck := false
var _warn: Telegraph
var _bits: Array[MeshInstance3D] = []

const WARN := 0.35
const RISE := 0.12
const HOLD := 0.45
const SINK := 0.3
const BITS := 9

func setup(p_world: CombatWorld, pos: Vector3, p_radius: float, p_damage: float, p_stun: float,
		p_bonus: Dictionary) -> TentacleSpike:
	world = p_world; radius = p_radius; damage = p_damage; stun = p_stun; bonus = p_bonus
	position = Vector3(pos.x, 0, pos.z)
	return self

func _ready() -> void:
	_warn = Telegraph.new()
	_warn.radius = radius
	_warn.duration = WARN
	_warn.color = Color(0.45, 0.9, 0.35, 0.7)
	add_child(_warn)
	var cols := [Color(0.12, 0.16, 0.1), Color(0.2, 0.28, 0.14), Color(0.35, 0.18, 0.3)]
	for i in BITS:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var w := lerpf(0.42, 0.12, float(i) / BITS)
		bm.size = Vector3(w, 0.26, w)
		var m := StandardMaterial3D.new()
		m.albedo_color = cols[i % 3]
		m.roughness = 0.4
		if i == BITS - 1:
			m.emission_enabled = true
			m.emission = Color(0.6, 1.0, 0.4)
			m.emission_energy_multiplier = 0.8
		bm.material = m
		mi.mesh = bm
		mi.visible = false
		add_child(mi)
		_bits.append(mi)

func _physics_process(delta: float) -> void:
	_t += delta
	if not _struck and _t >= WARN:
		_struck = true
		Damage.ctx = _wtag
		for e in world.enemies_in_circle(global_position, radius):
			var d := Damage.new(damage, 0.0)
			d.bonus = bonus
			e.take_damage(d)
			if e.is_alive() and e.has_method("stun"): e.stun(stun)
	if _t >= WARN + RISE + HOLD + SINK: queue_free()

func _process(_delta: float) -> void:
	if _t < WARN: return
	var u := _t - WARN
	var h := smoothstep(0.0, RISE, u) * (1.0 - smoothstep(RISE + HOLD, RISE + HOLD + SINK, u))
	for i in BITS:
		var k := float(i) / BITS
		var sway := sin(u * 9.0 + k * 3.0) * 0.18 * k
		_bits[i].visible = h > 0.02
		_bits[i].position = Vector3(sway, k * 2.2 * h + 0.13, sway * 0.6)
		_bits[i].rotation.y = u * 4.0 + k
