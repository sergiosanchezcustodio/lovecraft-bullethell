class_name Reanimated
extends Node3D
var _wtag := Damage.ctx                    ## arma que lo creó (estadísticas)
## Enemigo levantado por el suero de Herbert West: su propio modelo, con un tinte verde
## enfermizo, que durante `life` s persigue al enemigo más cercano y le hace daño al tocarlo.
## No recibe daño ni lo buscan los enemigos (no está en CombatWorld). Al acabar se desmorona.

var world: CombatWorld
var data: EnemyData
var life := 6.0
var dps := 12.0
var bonus := {}
var hits := 0                                ## golpes dados (tests)
## Aspecto (hito 20.17): "west", el suero verde que chisporrotea; "pickman", el necrófago que sale de
## un lienzo (sin tinte, con un salpicón oscuro al salir y al irse); "ward", el que levantan las sales
## (hito 20.18: ceniza azulada que sube y vuelve a caer, sin chisporroteo). `tick`: s entre golpes.
## `blast`: daño en BLAST_R al deshacerse (Cola del Dragón).
var look := "west"
var tick := TICK
var blast := 0.0
var blasted := false                         ## ya reventó (tests)
var _t := 0.0
var _tick := 0.0
var _facing := Vector3.FORWARD
var _visual: Node3D
var _model: Node3D
var _anim_t := 0.0
var _overlay: StandardMaterial3D
var _wall: MeshInstance3D                    ## cortina verde al levantarse (fase 18, 10-11-2026)
var _ended := false

const SPEED := 3.4
const TICK := 0.4
const FADE := 0.5
const TINT := Color(0.3, 0.95, 0.25, 0.5)
const WARD_TINT := Color(0.55, 0.68, 1.0, 0.34)
const BLAST_R := 1.8

func setup(p_world: CombatWorld, p_data: EnemyData, pos: Vector3, facing: Vector3, p_life: float,
		p_bonus: Dictionary) -> Reanimated:
	world = p_world; data = p_data; life = p_life; bonus = p_bonus
	dps = 10.0 + data.max_health * 0.2
	position = Vector3(pos.x, 0.0, pos.z)
	_facing = facing
	return self

func _ready() -> void:
	Damage.ctx = _wtag
	_visual = Node3D.new()
	_visual.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_visual.top_level = true
	add_child(_visual)
	_model = VoxelBuilder.load_model("res://models/%s.json" % data.model)
	_visual.add_child(_model)
	if look == "pickman":                                               # el necrófago: sale del cuadro
		if FxShade.on(): HitSparks.burst("glint_ember", global_position + Vector3(0, 0.6, 0))
		return
	var m := VoxelFx.std()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = WARD_TINT if look == "ward" else TINT
	for mi: MeshInstance3D in _model.get_meta("meshes"): mi.material_overlay = m
	_overlay = m
	# fase 18 (10-11-2026): se levanta con una descarga verde, una cortina que sube y chispas
	if look == "ward":                                                  # sube de sus sales
		VoxelFx.puff(world.fx, global_position, "salts_rise", data.body_radius + 0.15, Color.WHITE, 1.0)
	if FxShade.on():
		HitSparks.burst("glint_ice" if look == "ward" else "glint_green", global_position + Vector3(0, 0.6, 0))
		_wall = MeshInstance3D.new()
		_wall.mesh = VoxelFx.ring_wall()
		_wall.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if FxShade.apply(_wall, "wall"):
			FxShade.set_tint(_wall, SaltCircle.TINT if look == "ward" else Color(0.5, 1.0, 0.45))
			_visual.add_child(_wall)
		else:
			_wall.free()
			_wall = null

func _physics_process(delta: float) -> void:
	Damage.ctx = _wtag
	_t += delta
	if _t >= life:
		if blast > 0.0 and not blasted: _blast()
		if _t >= life + FADE: queue_free()
		return
	var target := world.nearest_enemy(global_position, 12.0)
	if target != null:
		var to := Vector3(target.global_position.x - position.x, 0, target.global_position.z - position.z)
		if to.length() > 0.6:
			_facing = to.normalized()
			position += _facing * SPEED * delta
	_tick -= delta
	if _tick > 0.0: return
	_tick = tick
	for e in world.enemies_in_circle(global_position, data.body_radius + 0.35):
		var d := Damage.new(dps * tick, 0.0)
		d.knockback = _facing * 0.6
		d.bonus = bonus
		e.take_damage(d)
		hits += 1

## Cola del Dragón: vuelve a ser polvo de golpe y revienta.
func _blast() -> void:
	blasted = true
	for e in world.enemies_in_circle(global_position, BLAST_R):
		var d := Damage.new(blast, 0.0)
		d.bonus = bonus
		var away := Vector3(e.global_position.x - global_position.x, 0, e.global_position.z - global_position.z)
		d.knockback = away.normalized() * 1.0 if away.length() > 0.01 else Vector3.ZERO
		e.take_damage(d)
	Auto.sfx_at("magic", global_position)

func _process(delta: float) -> void:
	Damage.ctx = _wtag
	_visual.global_position = get_global_transform_interpolated().origin
	_visual.rotation.y = atan2(_facing.x, _facing.z)
	var sink := smoothstep(life, life + FADE, _t)                       # se desmorona hundiéndose
	_visual.global_position.y -= sink * 0.8
	_visual.scale = Vector3.ONE * clampf(_t / 0.3, 0.3, 1.0) * (1.0 - sink * 0.4)
	# el suero chisporrotea: el verde late a tirones, como una corriente galvánica
	var jolt := 0.5 + 0.5 * sin(_t * 23.0) * sin(_t * 7.0)
	if look == "ward": jolt = 0.7 + 0.3 * sin(_t * 3.0)                # la ceniza respira despacio
	if _overlay: _overlay.albedo_color.a = (WARD_TINT.a if look == "ward" else TINT.a) * (0.45 + 0.55 * jolt) * (1.0 - sink)
	if _wall:
		var w := clampf(_t / 0.45, 0.0, 1.0)
		_wall.visible = w < 1.0
		var r := data.body_radius + 0.35
		_wall.scale = Vector3(r, 1.4 * (1.0 - pow(1.0 - w, 2.0)) + 0.05, r)
		_wall.set_instance_shader_parameter("fade", 0.8 * (1.0 - smoothstep(0.3, 1.0, w)))
	if not _ended and _t >= life:                                       # se deshace con un último chispazo
		_ended = true
		if look == "ward":                                               # vuelve a ser polvo
			VoxelFx.puff(world.fx, global_position, "salts_fall", data.body_radius + 0.15, Color.WHITE, 1.2)
			if FxShade.on() and blast > 0.0: HitSparks.burst("glint_ice", _visual.global_position + Vector3(0, 0.5, 0))
		elif FxShade.on(): HitSparks.burst("glint_ember" if look == "pickman" else "glint_green", _visual.global_position + Vector3(0, 0.5, 0))
	_anim_t = fposmod(_anim_t + delta / Anims.duration(data.model, "walk"), 1.0)
	Anims.pose(data.model, "walk", _model, _anim_t)
