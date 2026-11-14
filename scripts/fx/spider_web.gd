class_name SpiderWeb
extends Node3D
## Red de las arañas de Leng (hito 21.10, nivel 3 de la parte 4): tendida en el suelo, atrapa al primer
## jugador que la pisa sin esquivar: `hold` s sin poder andar (Player.snare; esquivar lo suelta). Se
## gasta al atrapar a alguien y, si nadie la pisa, se deshace a los `life` s. Las balas no le hacen nada.
## En red, cada PC tiende las suyas (la marioneta del invitado también) y cada una atrapa solo a los
## jugadores de su PC.

const ARM := 0.5                       ## s que tarda en asentarse
const MODEL := "res://models/telarana.json"
const COLOR := Color(0.80, 0.62, 0.95)
static var _told_ms := -100000         ## el aviso de cómo soltarse, de vez en cuando

var world: CombatWorld
var radius := 1.0
var life := 22.0
var hold := 1.6
var caught: Player
var _t := 0.0
var _gone := -1.0
var _model: Node3D

func setup(p_world: CombatWorld, pos: Vector3, p: Dictionary = {}) -> SpiderWeb:
	world = p_world
	radius = float(p.get("web_radius", radius))
	life = float(p.get("web_life", life))
	hold = float(p.get("web_hold", hold))
	position = Vector3(pos.x, 0.02, pos.z)
	return self

func _ready() -> void:
	add_to_group(&"enemy_warnings")              # el bot las rodea (SmartBot)
	add_to_group(&"spider_webs")
	set_meta("warn_r", radius + 0.3)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_model = VoxelBuilder.load_model(MODEL)
	_model.rotation.y = randf() * TAU
	_model.scale = Vector3.ONE * 0.1
	add_child(_model)
	Auto.sfx_at("brush", global_position)

func _physics_process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / ARM, 0.0, 1.0)
	_model.scale = Vector3.ONE * lerpf(0.1, radius / 1.06, 1.0 - pow(1.0 - k, 3.0))
	if _gone >= 0.0:                              # atrapó a alguien: se deshace cuando lo suelta
		_gone -= delta
		_model.scale *= clampf(_gone / 0.4, 0.0, 1.0) if _gone < 0.4 else 1.0
		if _gone <= 0.0: queue_free()
		return
	if _t >= life:
		queue_free()
		return
	if _t < ARM or world == null: return
	for p in world.players:
		if p.remote or p.health <= 0.0 or p.is_eliminated or p.snare > 0.0 or p.motor.is_dodging(): continue
		var off := p.global_position - global_position
		off.y = 0.0
		if off.length() <= radius:
			catch(p)
			return

## Atrapa a `p` (de este PC).
func catch(p: Player) -> void:
	caught = p
	p.snare = hold
	_gone = hold
	Auto.sfx_at("brush", global_position)
	VoxelFx.puff(get_parent(), p.global_position + Vector3(0, 0.3, 0), "dust", 0.4)
	var game := get_tree().current_scene if is_inside_tree() else null
	if Time.get_ticks_msec() - _told_ms > 20000 and game != null and game.has_method("announce"):
		_told_ms = Time.get_ticks_msec()
		game.announce("¡Atrapado en una red! Esquiva para soltarte", 2.0)
