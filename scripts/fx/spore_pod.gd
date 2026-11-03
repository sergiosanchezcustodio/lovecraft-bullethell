class_name SporePod
extends Node3D
## Vaina de esporas del Antiguo sembrador (hito 16.16): una mina. Brota del suelo en `ARM` s y,
## brotada, revienta cuando un jugador se le acerca a menos de `trigger` m: un aviso corto en el
## suelo (`WARN` s) y una nube de esporas que quita vida y cordura en `radius` m. Si nadie la
## pisa, revienta sola a los `life` s. Las balas no le hacen nada: se esquiva.
## En red, cada PC planta las suyas (la marioneta del invitado también, como el limo del Antiguo
## mutilado) y cada una daña solo a los jugadores de su PC.

var world: CombatWorld
var radius := 1.6
var trigger := 0.9
var life := 16.0
var damage := 12.0
var mental := 8.0
var who := &""
var _t := 0.0
var _fuse := -1.0
var _model: Node3D

const ARM := 0.9
const WARN := 0.45
const COLOR := Color(0.86, 0.80, 0.36)
const MODEL := "res://models/vaina_esporas.json"

func setup(p_world: CombatWorld, pos: Vector3, p: Dictionary = {}) -> SporePod:
	world = p_world
	radius = float(p.get("pod_radius", radius))
	trigger = float(p.get("pod_trigger", trigger))
	life = float(p.get("pod_life", life))
	damage = float(p.get("pod_damage", damage))
	mental = float(p.get("pod_mental", mental))
	position = Vector3(pos.x, 0.0, pos.z)
	return self

func _ready() -> void:
	add_to_group(&"enemy_warnings")              # el bot las rodea (SmartBot)
	add_to_group(&"spore_pods")
	set_meta("warn_r", trigger + 0.4)
	_model = VoxelBuilder.load_model(MODEL)
	_model.rotation.y = randf() * TAU
	_model.scale = Vector3.ONE * 0.05
	add_child(_model)
	Auto.sfx_at("drip", global_position)

func _physics_process(delta: float) -> void:
	_t += delta
	var grow := clampf(_t / ARM, 0.0, 1.0)
	var beat := 1.0 + (0.12 * sin(_t * 24.0) if _fuse >= 0.0 else 0.04 * sin(_t * 3.0))   # late; al encenderse, deprisa
	_model.scale = Vector3.ONE * lerpf(0.05, 1.0, 1.0 - pow(1.0 - grow, 3.0)) * beat
	if _fuse >= 0.0:
		_fuse -= delta
		if _fuse <= 0.0: _burst()
		return
	if _t >= life:
		light()
		return
	if _t < ARM: return
	for p in world.players:
		if p.health <= 0.0 or p.is_eliminated: continue
		var off := p.global_position - global_position
		if Vector2(off.x, off.z).length() < trigger + p.data.hurt_radius * 0.5:
			light()
			return

## Se enciende: avisa y revienta a los `WARN` s.
func light() -> void:
	if _fuse >= 0.0: return
	_fuse = WARN
	var tg := Telegraph.new().setup(radius, WARN, Color(COLOR, 0.85))
	tg.position = Vector3(global_position.x, 0.0, global_position.z)
	world.fx.add_child(tg)
	Auto.sfx_at("cue_attack", global_position)

func _burst() -> void:
	var at := global_position
	for p in world.players:
		if p.remote or p.health <= 0.0 or p.is_downed() or p.is_eliminated: continue   # en red: cada PC, a sus jugadores
		var off := p.global_position - at
		if Vector2(off.x, off.z).length() < radius + p.data.hurt_radius * 0.5:
			var d := Damage.new(damage, mental)
			d.via = &"esporas"
			d.who = who
			p.take_damage(d)
	VoxelFx.puff(world.fx, at + Vector3(0, 0.5, 0), "smoke", radius * 0.9, Color(0.62, 0.58, 0.26), 1.8)
	VoxelFx.puff(world.fx, at + Vector3(0, 0.4, 0), "sparkle", radius * 0.7, COLOR)
	VoxelFx.ground_hit(world.fx, at, radius, Color(0.30, 0.27, 0.12), false)
	Auto.sfx_at("splash", at)
	queue_free()
