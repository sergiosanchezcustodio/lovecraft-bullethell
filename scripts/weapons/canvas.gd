class_name Canvas
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Lienzo de Pickman (hito 20.17): un caballete con un cuadro a medio pintar que Pickman planta
## entre los enemigos. Mientras dura (`life` s) atrae a los de `radius` (las élites no se dejan,
## como con la bengala) y los deja vulnerables; los que lo tocan lo van rompiendo. Al romperse
## (`HITS` golpes) o al acabarse su tiempo revienta en un salpicón de pintura que daña a los de
## alrededor y del cuadro sale un necrófago aliado (`Reanimated` con el modelo `necrofago`) que
## caza `ally_life` s. Modelo: models/lienzo.json (`tools/gen_tienda20.py lienzo`).

var world: CombatWorld
var life := 6.0
var radius := 4.5
var damage := 20.0                         ## lo que hace el necrófago por golpe (el salpicón, el doble)
var ally_life := 5.0
var ally_tick := 0.4
var vulnerable := 1.0
var ghouls := 1                            ## necrófagos que suelta (El modelo del natural: tres)
var power := 1.0                           ## daño de los aliados (Frasco de los Custodes, hito 20.18)
var bonus := {}
var hits := 0                              ## golpes recibidos (tests)
var broken := false
var _face := Vector3.FORWARD                 ## hacia dónde sale el necrófago (hacia los enemigos)
var _t := 0.0
var _pulse := 0.0
var _shake := 0.0
var _visual: Node3D
var _model: Node3D
var _cloth: Node3D
var _big := 1.0

const HITS := 10                           ## toques de enemigo que aguanta
const TOUCH := 0.9                         ## a qué distancia lo toca un enemigo
const PULSE := 0.25
const SPLASH := 1.6                        ## radio del salpicón al reventar
const RISE := 0.25                         ## s que tarda en desplegarse
const GHOUL_HEALTH := 60.0                 ## para el radio y el aspecto del necrófago (no recibe daño)
static var _ghoul: EnemyData

func setup(p_world: CombatWorld, pos: Vector3, face: Vector3, p_life: float, p_radius: float, p_damage: float,
		p_ally_life: float, p_ally_tick: float, p_vulnerable: float, p_bonus: Dictionary) -> Canvas:
	world = p_world; life = p_life; radius = p_radius; damage = p_damage
	ally_life = p_ally_life; ally_tick = maxf(p_ally_tick, 0.05); vulnerable = p_vulnerable; bonus = p_bonus
	position = Vector3(pos.x, 0.0, pos.z)
	rotation.y = deg_to_rad(45.0)                     # a la cámara (fija, a 45°): el cuadro siempre se ve
	_face = face
	return self

## Datos del necrófago para `Reanimated` (no está en data/enemies: no sale en los niveles).
static func ghoul_data() -> EnemyData:
	if _ghoul == null:
		_ghoul = EnemyData.new()
		_ghoul.id = &"necrofago"
		_ghoul.display_name = "Necrófago de Pickman"
		_ghoul.model = "necrofago"
		_ghoul.max_health = GHOUL_HEALTH
		_ghoul.body_radius = 0.42
	return _ghoul

func _ready() -> void:
	Damage.ctx = _wtag
	add_to_group(&"combo_canvases")                   # sales, tajos y fuego (Combos, hito 21.6)
	_visual = Node3D.new()
	add_child(_visual)
	_model = VoxelBuilder.load_model("res://models/lienzo.json")
	_visual.add_child(_model)
	_cloth = _model.find_child("canvas", true, false) as Node3D
	_big = 1.5 if ghouls > 1 else 1.0               # El modelo del natural: un cuadro enorme
	_visual.scale = Vector3(_big, 0.05, _big)
	Auto.sfx_at("brush", global_position)             # el pincel (hito 21.1)

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	if broken: return
	_t += delta
	if _t >= life:
		_break()
		return
	_pulse -= delta
	if _pulse > 0.0: return
	_pulse = PULSE
	for e in world.enemies_in_circle(global_position, radius):
		if e.has_method("lure"): e.lure(global_position, PULSE + 0.2)
		if vulnerable > 0.0 and e.has_method("make_vulnerable"): e.make_vulnerable(vulnerable)
	for e in world.enemies_in_circle(global_position, TOUCH):
		hits += 1
		_shake = 0.2
	if hits >= HITS: _break()

## Revienta: salpicón de pintura que daña y empuja a los de alrededor y el necrófago que sale.
func _break() -> void:
	if broken: return
	broken = true
	var at := global_position + Vector3(0, 0.6, 0)
	for e in world.enemies_in_circle(global_position, SPLASH):
		var d := Damage.new(damage * 2.0, 0.0)
		d.bonus = bonus
		var away := Vector3(e.global_position.x - global_position.x, 0, e.global_position.z - global_position.z)
		d.knockback = away.normalized() * 1.2 if away.length() > 0.01 else Vector3.ZERO
		e.take_damage(d)
	world.splash(global_position, 1.1, Color(0.55, 0.1, 0.08))
	if FxShade.on(): HitSparks.burst("glint_ember", at)
	Auto.sfx_at("canvas_tear", global_position)       # el lienzo que se rasga (hito 21.1)
	Auto.sfx_at("growl", global_position)
	for k in ghouls:
		var off := Vector3.ZERO if ghouls == 1 else Vector3(0.7, 0, 0).rotated(Vector3.UP, TAU * k / ghouls)
		var g := Reanimated.new().setup(world, ghoul_data(), global_position + off, -_face, ally_life, bonus)
		g.look = "ward" if has_meta("ash") else "pickman"   # ceniza azul (Combos, hito 21.6)
		g.dps = damage / ally_tick * power
		g.tick = ally_tick
		world.fx.add_child(g)
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.25, 0.02, 1.25) * _big, 0.18).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

func _process(delta: float) -> void:
	if broken: return
	var u := clampf(_t / RISE, 0.0, 1.0)
	_visual.scale = Vector3(_big, lerpf(0.05, 1.0, 1.0 - pow(1.0 - u, 3.0)) * _big, _big)
	_shake = maxf(_shake - delta, 0.0)
	if _cloth:                                                         # tiembla con cada toque
		_cloth.rotation.z = sin(_t * 60.0) * 0.05 * (_shake / 0.2)
		_cloth.rotation.x = -0.04 * float(hits) / HITS                 # y se va venciendo
	var k := smoothstep(life - 0.8, life, _t)                         # avisa antes de acabarse
	_visual.position.x = sin(_t * 40.0) * 0.02 * k
