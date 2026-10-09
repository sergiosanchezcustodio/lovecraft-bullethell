class_name Pickup
extends Node3D
## Recompensa de un objeto rompible (04-10-2026). Flota y gira; la recoge el primer jugador que
## la pisa. FOOD cura vida, POTION cordura, MONEY da dólares, FLAMER pone 5 s un lanzallamas
## potente al jugador y FREEZE congela el tiempo 5 s (enemigos y sus balas quietos y sin atacar).
## Si nadie la recoge en LIFE s, desaparece.

enum Kind { FOOD, POTION, MONEY, FLAMER, FREEZE }
const MODELS := ["recompensa_comida", "recompensa_pocion", "recompensa_dinero", "recompensa_lanzallamas", "recompensa_reloj"]
const NAMES := ["Comida: +30 % de vida", "Poción: +30 % de cordura", "Dólares", "¡Lanzallamas!", "¡Tiempo congelado!"]
## Probabilidades: lo útil a menudo, los poderes de vez en cuando.
const WEIGHTS := [0.3, 0.25, 0.25, 0.1, 0.1]
const LIFE := 25.0
const POWER_TIME := 5.0

var world: CombatWorld
var kind := Kind.FOOD
var _t := 0.0
var _holder: Node3D

static func roll() -> Kind:
	var r := randf()
	for i in WEIGHTS.size():
		r -= WEIGHTS[i]
		if r <= 0.0: return i as Kind
	return Kind.FOOD

func setup(p_world: CombatWorld, pos: Vector3, p_kind: Kind) -> Pickup:
	world = p_world
	kind = p_kind
	position = Vector3(pos.x, 0.0, pos.z)
	return self

func _ready() -> void:
	_holder = Node3D.new()
	_holder.scale = Vector3.ONE * 1.3
	add_child(_holder)
	_holder.add_child(VoxelBuilder.load_model("res://models/%s.json" % MODELS[kind]))
	var ring := MeshInstance3D.new()                       # anillo en el suelo para verla
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42; tm.outer_radius = 0.5
	ring.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = [Color(1.0, 0.45, 0.35), Color(0.75, 0.45, 1.0), Color(1.0, 0.82, 0.3), Color(1.0, 0.55, 0.15), Color(0.45, 0.8, 1.0)][kind]
	ring.material_override = m
	ring.position.y = 0.04
	ring.scale = Vector3(1, 0.2, 1)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)

func _process(delta: float) -> void:
	_t += delta
	_holder.rotation.y += delta * 1.6
	_holder.position.y = 0.25 + sin(_t * 3.0) * 0.08
	if _t > LIFE - 3.0: visible = fmod(_t, 0.3) < 0.18     # parpadea antes de irse
	if _t > LIFE: queue_free()

func _physics_process(_delta: float) -> void:
	for p in world.players:
		if p.health <= 0.0: continue
		var off := p.global_position - global_position
		off.y = 0.0
		if off.length() < 0.9:
			Sfx.play("pickup")
			_give(p)
			queue_free()
			return

func _give(p: Player) -> void:
	var game := get_tree().current_scene
	match kind:
		Kind.FOOD: p.health = minf(p.data.max_health, p.health + p.data.max_health * 0.3 * p.data.pickup_heal_mult)
		Kind.POTION: p.sanity = minf(p.data.max_sanity, p.sanity + p.data.max_sanity * 0.3 * p.data.pickup_heal_mult)
		Kind.MONEY:
			var n := randi_range(15, 40)
			if game != null and game.has_method("earn"): game.earn(n)
		Kind.FLAMER: give_flamer(p)
		Kind.FREEZE: world.freeze_time(POWER_TIME)
	if game != null and game.has_method("announce"): game.announce(NAMES[kind], 1.5)
	if OS.get_cmdline_user_args().has("log=true"): print("RECOGIDA %s" % Kind.keys()[kind])

## Lanzallamas potente durante POWER_TIME s: un arma temporal fuera de los huecos.
static func give_flamer(p: Player) -> void:
	var base: WeaponData = load("res://data/weapons/flammenwerfer.tres")
	var d: WeaponData = base.duplicate()
	d.id = &"lanzallamas_poder"
	d.display_name = "Lanzallamas potente"
	d.damage = base.damage * 3.0
	d.cooldown = 0.35
	d.range = base.range * 1.4
	d.spread_deg = base.spread_deg * 1.3
	p.weapons.remove_weapon(d.id)
	var w := p.weapons.add_weapon(d)
	w.timer = 0.0
	p.get_tree().create_timer(POWER_TIME, false).timeout.connect(func() -> void:
		if is_instance_valid(p): p.weapons.remove_weapon(&"lanzallamas_poder"))
