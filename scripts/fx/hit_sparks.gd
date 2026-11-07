class_name HitSparks
extends Node3D
## Impactos según el daño (hito 18.3, D-50): una chispa breve de cubitos en cada golpe a un enemigo,
## distinta según cómo daña el arma: bala (chispas que rebotan hacia quien dispara), corte (esquirlas
## de icor y un destello de acero), golpe (polvo y cascotes), fuego (brasas), ácido (gotas verdes),
## arcano (motas que suben) y rayo (chispazos azules). Los emisores se reciclan (`POOL` por tipo,
## montados al empezar el nivel): ninguno se crea en partida. Tope de golpes con chispa por
## fotograma (`PER_FRAME`) y por enemigo (`GAP`). Con `weapon_fx` 0 (Baja), nada; en 1 (Media), la
## mitad. `hit_sparks=false` para comparar.

const POOL := 6
const PER_FRAME := 4
const GAP := 0.09                       ## s entre chispas en el mismo enemigo
const KINDS := ["bullet", "cut", "blunt", "fire", "acid", "arcane", "shock"]

static var enabled := true
static var _inst: HitSparks
static var _rng := RandomNumberGenerator.new()   ## propio: lo que se ve no cambia el azar de la partida
static var _kind_of := {}               ## etiqueta del arma -> tipo de impacto

var _pools := {}
var _next := {}
var _frame := -1
var _used := 0
var _last := {}
var _every := 1
var _count := 0

## Chispa del golpe `d` a `e` (lo llama Enemy al recibir daño que no es continuo).
static func hit(world: CombatWorld, e: Node3D, d: Damage, radius := 0.4, height := 0.6) -> void:
	if not enabled or d.dot or world == null: return
	if not is_instance_valid(_inst) or not _inst.is_inside_tree(): return
	_inst._hit(e, d, radius, height)

## Monta los emisores (al empezar el nivel, con el calentamiento).
static func setup(world: CombatWorld) -> void:
	if not enabled or world == null: return
	var lv := int(Quality.value("weapon_fx", 2))
	if lv <= 0: return
	var h := HitSparks.new()
	h.name = "HitSparks"
	h._every = 2 if lv == 1 else 1
	world.fx.add_child(h)
	_inst = h

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for k in KINDS:
		var list: Array[GPUParticles3D] = []
		for i in POOL:
			var p := VoxelFx.emitter("hit_" + k, 0.3, true)
			p.emitting = false
			p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			add_child(p)
			list.append(p)
		_pools[k] = list
		_next[k] = 0

func _hit(e: Node3D, d: Damage, radius: float, height: float) -> void:
	var f := Engine.get_process_frames()
	if f != _frame:
		_frame = f
		_used = 0
	if _used >= PER_FRAME: return
	_count += 1
	if _every > 1 and _count % _every != 0: return
	var now := Time.get_ticks_msec() / 1000.0
	var id := e.get_instance_id()
	if now - float(_last.get(id, -9.0)) < GAP: return
	_last[id] = now
	if _last.size() > 400: _last.clear()
	_used += 1
	var k := kind_of(d)
	var list: Array = _pools[k]
	var i: int = _next[k]
	_next[k] = (i + 1) % list.size()
	var p: GPUParticles3D = list[i]
	var back := -d.dir if d.dir.length_squared() > 0.001 else -d.knockback
	back.y = 0.0
	if back.length_squared() < 0.001: back = Vector3(_rng.randf() - 0.5, 0, _rng.randf() - 0.5)
	back = back.normalized()
	var at := e.global_position + Vector3(0, height, 0) + back * radius
	var up := Vector3.UP
	var z := back
	var x := up.cross(z).normalized()
	p.global_transform = Transform3D(Basis(x, up, z), at)   # el eje z del emisor, hacia quien golpea
	p.restart()

## Tipo de impacto del golpe: por cómo mata, si es solo mental, o por la forma del arma.
static func kind_of(d: Damage) -> String:
	if d.how == &"burn": return "fire"
	if d.how == &"shock": return "shock"
	if d.physical <= 0.0 and d.mental > 0.0: return "arcane"
	if _kind_of.has(d.tag): return _kind_of[d.tag]
	var k := "bullet"
	var wid := String(d.tag).get_slice(":", 1)
	var path := "res://data/weapons/%s.tres" % wid
	if wid != "" and ResourceLoader.exists(path):
		var w := load(path) as WeaponData
		if w != null: k = _by_delivery(w)
	_kind_of[d.tag] = k
	return k

static func _by_delivery(w: WeaponData) -> String:
	match w.delivery:
		WeaponData.Delivery.MELEE, WeaponData.Delivery.STAB, WeaponData.Delivery.THRUST, WeaponData.Delivery.WHIP, \
				WeaponData.Delivery.BOOMERANG, WeaponData.Delivery.ORBIT, WeaponData.Delivery.SPIKES, WeaponData.Delivery.SWEEP:
			return "cut"
		WeaponData.Delivery.FISSURE, WeaponData.Delivery.THROWN, WeaponData.Delivery.TRAP:
			return "blunt"
		WeaponData.Delivery.FLAME, WeaponData.Delivery.FIREBALL:
			return "fire"
		WeaponData.Delivery.CLOUD:
			return "acid"
		WeaponData.Delivery.CHAIN, WeaponData.Delivery.TETHER:
			return "shock"
		WeaponData.Delivery.BEAM, WeaponData.Delivery.SIGIL, WeaponData.Delivery.PULSE, WeaponData.Delivery.WAVE, \
				WeaponData.Delivery.MADDEN, WeaponData.Delivery.VORTEX, WeaponData.Delivery.DRONE:
			return "arcane"
	return "bullet"

## Calentamiento (LevelWarmup): una chispa de cada tipo bajo el suelo, en `at`.
static func prime(at: Vector3) -> void:
	if not is_instance_valid(_inst): return
	for k in KINDS:
		var p: GPUParticles3D = (_inst._pools[k] as Array)[POOL - 1]
		p.global_position = at
		p.restart()
