class_name DagonBehavior
extends EnemyBehavior
## Padre Dagon (hito 6.6), jefe de la parte 2. No anda: asoma de una sima de agua honda de la
## arena (`ObstacleMap.boss_spots`, en la mitad norte: así mira a la cámara y no tapa a los
## jugadores; sin simas, de la orilla sur o este), anclado (`Enemy.anchored`), y desde ahí:
##   fase 1 (100-66 %): golpes de una mano donde está el jugador (aviso grande en el suelo) y
##      olas en abanico (`wave_pattern`);
##   fase 2 (66-33 %): golpes con las dos manos (2 avisos), llama a Profundos que salen de las
##      pozas (`minion`, `minion_every`, `minion_count`) y espiral (`spiral_pattern`);
##   fase 3 (< 33 %): furia: golpes más seguidos (3 avisos), anillos de olas con huecos
##      (`ring_pattern`), aura que drena cordura y, cada `sink_every` s, se hunde y sale en
##      otro punto de la orilla.
## Al cambiar de fase ruge (la cámara tiembla) y es invulnerable `roar_shield` s.
## Parámetros del golpe: slam_radius, slam_damage, slam_warn y slam_every (lista por fase).

const CAMERA_SIZE := 20.0             ## m de alto visibles mientras vive (por defecto, 15)
var phase := 0
var _act := 2.5                       ## s hasta la próxima acción
var _wave := 4.0
var _minion := 4.0
var _sink := 0.0
var _clip := ""                       ## animación en curso ("" = reposo)
var _clip_t := 0.0
var _hidden := false                  ## bajo el agua (hundido)
var _rng := RandomNumberGenerator.new()

func start(e: Enemy) -> void:
	e.anchored = true
	e.anim_hold = true
	_play(e, "emerge")
	e.shield_t = Anims.duration(e.model_name, "emerge")

func touches(_e: Enemy) -> bool:
	return false

func can_shoot(_e: Enemy) -> bool:
	return false

func phase_for(e: Enemy) -> int:
	var k := e.health / maxf(e.data.max_health * e.health_scale, 1.0)
	return 1 if k > 0.66 else (2 if k > 0.33 else 3)

## La sima más cercana a `to` que no sea `not_here` (o la orilla si la arena no tiene simas).
static func spot_for(o: ObstacleMap, to: Vector3, not_here: Vector3) -> Vector3:
	if o == null or o.boss_spots.is_empty(): return shore_point(o, to)
	var best := Vector3.INF
	for s in o.boss_spots:
		var p := Vector3(s.x, 0, s.y)
		if not_here != Vector3.INF and p.distance_to(not_here) < 1.0: continue
		if best == Vector3.INF or p.distance_to(to) < best.distance_to(to): best = p
	return best if best != Vector3.INF else Vector3(o.boss_spots[0].x, 0, o.boss_spots[0].y)

## Punto de la orilla (sur o este, justo pasado lo transitable) más cercano a `to`.
static func shore_point(o: ObstacleMap, to: Vector3, margin := 6.0) -> Vector3:
	var b := o.bounds if o != null else Rect2(-32, -32, 64, 64)
	var south := Vector3(clampf(to.x, b.position.x + margin, b.end.x - margin), 0, b.end.y + 1.2)
	var east := Vector3(b.end.x + 1.2, 0, clampf(to.z, b.position.y + margin, b.end.y - margin))
	return south if south.distance_to(to) <= east.distance_to(to) else east

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	_step_clip(e, delta)
	if phase == 0:                                   # primera vez: a la orilla, frente al objetivo
		phase = 1
		e.position = spot_for(e.obstacles, target.global_position if target != null else Vector3.ZERO, Vector3.INF)
		e.reset_physics_interpolation()
		e.world.focus = e                                      # las armas le apuntan aunque no sea el más cercano
		var game := e.get_tree().current_scene
		if game != null and game.get("camera") != null:        # que quepa en el encuadre
			game.camera.view_size = maxf(game.camera.view_size, CAMERA_SIZE)
	var p := phase_for(e)
	if p != phase:
		phase = p
		_roar(e)
		if OS.get_cmdline_user_args().has("log=true"): print("DAGON fase %d" % phase)
	if target == null: return Vector3.ZERO
	var to := target.global_position - e.global_position
	to.y = 0.0
	if to.length() > 0.1 and not _hidden: e.facing = to.normalized()
	if _hidden or _clip == "roar" or _clip == "emerge": return Vector3.ZERO
	_act -= delta; _wave -= delta; _minion -= delta; _sink -= delta
	if phase == 3:                                   # aura: drena cordura cerca de la orilla
		for q in e.world.players:
			if q.global_position.distance_to(e.global_position) <= 9.0: q.drain_sanity(2.0 * delta)
		if _sink <= 0.0 and _clip == "":
			_sink = float(e.data.param("sink_every", 14.0))
			_dive(e, target)
			return Vector3.ZERO
	if _act <= 0.0 and _clip == "":
		var every: Array = e.data.param("slam_every", [4.5, 4.0, 3.0])
		_act = float(every[phase - 1])
		_slam(e, target)
	if _wave <= 0.0:
		_wave = float(e.data.param("wave_every", 5.0))
		var pat: BulletPattern = e.data.param(["wave_pattern", "spiral_pattern", "ring_pattern"][phase - 1], null)
		if pat != null and not e.runner.busy:
			e.runner.fire(pat, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position)
	if phase >= 2 and _minion <= 0.0:
		_minion = float(e.data.param("minion_every", 12.0))
		_summon(e)
	return Vector3.ZERO

# --- animaciones (el comportamiento lleva el reloj: anim_hold) ---
func _play(e: Enemy, clip: String) -> void:
	_clip = clip
	_clip_t = 0.0
	e.anim = clip
	e.anim_t = 0.0

func _step_clip(e: Enemy, delta: float) -> void:
	if _clip == "":
		e.anim = "idle"
		e.anim_t = fposmod(e.anim_t + delta / Anims.duration(e.model_name, "idle"), 1.0)
		return
	_clip_t += delta / Anims.duration(e.model_name, _clip)
	e.anim_t = minf(_clip_t, 1.0)
	if _clip_t >= 1.0:
		if _clip == "sink": return                     # se queda abajo hasta que emerja
		_clip = ""

# --- golpe de mano ---
func _slam(e: Enemy, target: Player) -> void:
	var r := float(e.data.param("slam_radius", 3.0))
	var warn := float(e.data.param("slam_warn", 1.0))
	var at := Vector3(target.global_position.x, 0, target.global_position.z)
	var spots: Array[Vector3] = [at]
	for i in phase - 1:                                # más manos (y más sitios) en cada fase
		var a := _rng.randf() * TAU
		spots.append(at + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(r * 1.7, r * 2.8))
	var side := e.facing.cross(Vector3.UP).dot(to_target(e, at))
	_play(e, "slam_both" if phase >= 2 else ("slam_l" if side > 0.0 else "slam_r"))
	for s in spots:
		var tg := Telegraph.new().setup(r, warn, Color(Damage.COLOR_PHYSICAL, 0.85))
		tg.position = s
		e.world.fx.add_child(tg)
		var eid := e.get_instance_id()
		tg.finished.connect(func() -> void:
			var e2 := instance_from_id(eid) as Enemy
			if e2 == null or not e2.is_alive(): return
			WadeSplash.burst(e2.world.fx, s, r * 0.9)
			_shake(e2, 0.25)
			for q in e2.world.players:
				if q.health > 0.0 and Vector2(q.global_position.x - s.x, q.global_position.z - s.z).length() < r + q.data.hurt_radius:
					var d := Damage.new(float(e2.data.param("slam_damage", 22.0)), 0.0)
					d.knockback = (q.global_position - s).normalized()
					q.take_damage(d))

func to_target(e: Enemy, at: Vector3) -> Vector3:
	var v := at - e.global_position
	v.y = 0.0
	return v.normalized()

# --- llamada a los Profundos ---
func _summon(e: Enemy) -> void:
	var game := e.get_tree().current_scene
	var d: EnemyData = e.data.param("minion", null)
	if d == null or game == null or game.get("director") == null: return
	for i in int(e.data.param("minion_count", 3)):
		if not game.director._emerge(d):
			game.director.spawn(d, game.director.spawn_point(d.body_radius))

# --- rugido al cambiar de fase ---
func _roar(e: Enemy) -> void:
	_play(e, "roar")
	e.shield_t = float(e.data.param("roar_shield", 1.5))
	_shake(e, 0.6)

func _shake(e: Enemy, amount: float) -> void:
	var game := e.get_tree().current_scene
	if game != null and game.get("camera") != null: game.camera.shake(amount)

# --- se hunde y sale en otro punto de la orilla ---
func _dive(e: Enemy, target: Player) -> void:
	_play(e, "sink")
	_hidden = true
	var down := Anims.duration(e.model_name, "sink")
	e.shield_t = down + 1.8
	WadeSplash.burst(e.world.fx, e.global_position, 3.0)
	var to := spot_for(e.obstacles, target.global_position, e.global_position)   # siempre otra sima
	var tg := Telegraph.new().setup(3.5, 1.0, Color(0.35, 0.75, 0.85, 0.7), false)
	tg.position = to
	var eid := e.get_instance_id()
	e.get_tree().create_timer(down + 0.6, false).timeout.connect(func() -> void:
		var e2 := instance_from_id(eid) as Enemy
		if e2 != null and e2.is_alive(): e2.world.fx.add_child(tg)
		else: tg.free())
	e.get_tree().create_timer(down + 1.6, false).timeout.connect(func() -> void:
		var e3 := instance_from_id(eid) as Enemy
		if e3 == null or not e3.is_alive(): return
		e3.position = to
		e3.reset_physics_interpolation()
		_hidden = false
		WadeSplash.burst(e3.world.fx, to, 3.0)
		_shake(e3, 0.4)
		_play(e3, "emerge"))
	if OS.get_cmdline_user_args().has("log=true"): print("DAGON se hunde")
