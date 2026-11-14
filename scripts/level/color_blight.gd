class_name ColorBlight
extends Node
## El color que cayó del cielo (hito 21.13): manchas de un color sin nombre que nacen en el suelo,
## crecen, duran y se apagan (`LevelData.blight_*`). Quien está dentro se vuelve gris y quebradizo:
## el jugador pierde cordura y recibe un 30 % más de los golpes físicos (`Player.blight_t`); los
## enemigos, también grises, reciben `blight_enemy` más de daño (`Enemy.blight`). Así, llevarlos al
## color es una baza, y pisarlo, un riesgo. También dejan mancha los que la llevan dentro al morir
## (`data.param("blight_on_death")`, radio) y el jefe (`seed_at`).
## En red, las manchas las decide el anfitrión y llegan como suceso "blight" (pos, radio, vida);
## cada PC aplica el color a sus jugadores, y a los enemigos solo quien manda en ellos.

const TICK := 0.25                     ## s entre comprobaciones
const IN_HOLD := 0.6                   ## s que dura lo gris tras salir
const FADE := 4.0                      ## s que tarda en apagarse al final de su vida
const START := 0.35                    ## radio con el que nace (m)
const MAX := 48                        ## manchas que se dibujan como mucho
const COLOR := Color(0.86, 0.42, 0.95) ## el que se ve en chispas y avisos (el de verdad no tiene nombre)
const ASH := Color(0.6, 0.6, 0.58)

static var current: ColorBlight

var world: CombatWorld
var level: LevelData
var host := true
var game: Node                         ## para la red (su `net_game`, que se crea después)
var patches: Array[Dictionary] = []    ## {pos: Vector2, r, r_max, grow, age, life, seed}
var _every := 0.0
var _next := 0.0
var _tick := 0.0
var _fx_t := 0.0
var _rng := RandomNumberGenerator.new()
var _mm: MultiMeshInstance3D
var _flakes := {}                      ## jugador -> s hasta el próximo copo gris

func setup(p_world: CombatWorld, p_level: LevelData, p_host: bool, p_game: Node = null) -> ColorBlight:
	name = "ColorBlight"
	world = p_world; level = p_level; host = p_host; game = p_game
	_every = level.blight_every if level != null else 0.0
	_next = _every * 0.5
	_rng.randomize()
	current = self
	return self

func _exit_tree() -> void:
	if current == self: current = null

## Una mancha nueva (en el anfitrión o sin red, la reparte).
func seed_at(pos: Vector2, r_max: float, life := -1.0) -> void:
	if not host: return
	var l := life if life > 0.0 else (level.blight_life if level != null else 40.0)
	var sd := _rng.randi() % 997
	_add(pos, r_max, l, sd)
	var net: Variant = game.get("net_game") if game != null else null
	if net is NetGame: (net as NetGame)._event({"k": "blight", "x": snappedf(pos.x, 0.01), "z": snappedf(pos.y, 0.01), "r": snappedf(r_max, 0.01), "l": snappedf(l, 0.1), "s": sd})

## Invitado: la mancha que decidió el anfitrión.
func remote(d: Dictionary) -> void:
	_add(Vector2(float(d.get("x", 0.0)), float(d.get("z", 0.0))), float(d.get("r", 2.0)), float(d.get("l", 30.0)), int(d.get("s", 0)))

func _add(pos: Vector2, r_max: float, life: float, sd: int) -> void:
	if patches.size() >= MAX: patches.pop_front()
	var grow := level.blight_grow if level != null else 0.4
	patches.append({"pos": pos, "r": START, "r_max": r_max, "grow": grow, "age": 0.0, "life": life, "seed": sd})
	for q in world.players:
		if not q.remote and q.global_position.distance_to(Vector3(pos.x, 0, pos.y)) < 14.0:
			Auto.sfx_at("blight", Vector3(pos.x, 0.0, pos.y))
			break
	VoxelFx.puff(world.fx, Vector3(pos.x, 0.15, pos.y), "sparkle", 0.6, COLOR)

## Radio de la mancha ahora (crece hasta su tope y se apaga al final de su vida).
static func radius_of(p: Dictionary) -> float:
	var r := minf(float(p.r_max), START + float(p.grow) * float(p.age))
	var left := float(p.life) - float(p.age)
	return r * clampf(left / FADE, 0.0, 1.0)

## ¿Está `pos` dentro del color? (para las pruebas y para quien quiera saberlo)
func inside(pos: Vector3) -> bool:
	var at := Vector2(pos.x, pos.z)
	for p in patches:
		if at.distance_to(p.pos) < radius_of(p): return true
	return false

func _physics_process(delta: float) -> void:
	for p in patches: p.age = float(p.age) + delta
	patches.assign(patches.filter(func(p: Dictionary) -> bool: return float(p.age) < float(p.life)))
	if host and _every > 0.0:
		_next -= delta
		if _next <= 0.0:
			_next = _every * _rng.randf_range(0.7, 1.3)
			if patches.size() < (level.blight_max if level != null else 10): _seed_near_players()
	_tick -= delta
	if _tick > 0.0: return
	_tick = TICK
	for q in world.players:
		if q.remote or q.health <= 0.0: continue
		if inside(q.global_position):
			q.blight_t = IN_HOLD
			var drain := (level.blight_sanity if level != null else 2.0) * TICK * q.mental_resist * q.data.mental_mult
			if drain > 0.0 and not q.sanity_state.in_crisis:
				q.sanity = maxf(0.0, q.sanity - drain)
				q.sanity_state.on_mental_damage()
	if not host: return
	var bonus := level.blight_enemy if level != null else 0.5
	for p in patches:
		var r := radius_of(p)
		if r < 0.3: continue
		for e in world.enemies_in_circle(Vector3(p.pos.x, 0, p.pos.y), r):
			if e is Enemy: (e as Enemy).blight(IN_HOLD, bonus)

## Cerca de un jugador al azar, a 4-10 m, dentro del escenario.
func _seed_near_players() -> void:
	var alive := world.players.filter(func(q: Player) -> bool: return q.health > 0.0)
	if alive.is_empty(): return
	var q: Player = alive[_rng.randi() % alive.size()]
	var a := _rng.randf() * TAU
	var d := _rng.randf_range(4.0, 10.0)
	var at := Vector2(q.global_position.x + cos(a) * d, q.global_position.z + sin(a) * d)
	var b := world.bounds.grow(-3.0)
	at = Vector2(clampf(at.x, b.position.x, b.end.x), clampf(at.y, b.position.y, b.end.y))
	var rr: Vector2 = level.blight_radius if level != null else Vector2(2.0, 4.0)
	seed_at(at, _rng.randf_range(rr.x, rr.y))

## Un enemigo que lleva el color dentro deja su mancha al morir.
func on_enemy_died(e: Enemy) -> void:
	var r := float(e.data.param("blight_on_death", 0.0))
	if r > 0.0: seed_at(Vector2(e.global_position.x, e.global_position.z), r, 14.0)

func _process(delta: float) -> void:
	if _mm == null: _make_mesh()
	var mm := _mm.multimesh
	var n := 0
	for p in patches:
		var r := radius_of(p)
		if r < 0.05 or n >= MAX: continue
		var b := Basis.IDENTITY.scaled(Vector3(r * 2.0, 1.0, r * 2.0))
		mm.set_instance_transform(n, Transform3D(b, Vector3(p.pos.x, 0.03 + 0.002 * (n % 8), p.pos.y)))
		mm.set_instance_custom_data(n, Color(float(p.seed) * 0.013, r, clampf(float(p.age) / 1.5, 0.0, 1.0), 0.0))
		n += 1
	mm.visible_instance_count = n
	_fx_t -= delta
	if _fx_t <= 0.0 and n > 0:                  # chispas que suben del color
		_fx_t = 0.35
		var p: Dictionary = patches[_rng.randi() % patches.size()]
		var r := radius_of(p)
		if r > 0.5:
			var a := _rng.randf() * TAU
			var at := Vector3(p.pos.x + cos(a) * r * 0.6 * _rng.randf(), 0.2, p.pos.y + sin(a) * r * 0.6 * _rng.randf())
			VoxelFx.puff(world.fx, at, "sparkle", 0.25, COLOR, 1.0)
	for q in world.players:                     # los grises sueltan copos de ceniza
		if q.remote or q.blight_t <= 0.0: continue
		var t := float(_flakes.get(q, 0.0)) - delta
		if t <= 0.0:
			t = 0.45
			VoxelFx.puff(world.fx, q.global_position + Vector3(0, 1.0, 0), "dust", 0.35, ASH, 1.0)
		_flakes[q] = t

func _make_mesh() -> void:
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/level/color_blight.gdshader")
	quad.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = MAX
	mm.visible_instance_count = 0
	_mm = MultiMeshInstance3D.new()
	_mm.name = "Manchas"
	_mm.multimesh = mm
	_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mm.custom_aabb = AABB(Vector3(-200, -2, -200), Vector3(400, 4, 400))
	_mm.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_mm)
