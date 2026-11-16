class_name NyarlaBehavior
extends EnemyBehavior
## Nyarlathotep, el Caos reptante (hito 21.11), jefe de la parte 4, en la cima de Kadath. Tres formas, una
## por fase (GDD 2.5); al pasar de una a otra se rehace (`swap_model`), grita su frase y es invulnerable
## `shift_shield` s:
##   1. El faraón negro (100-66 %): guarda la distancia (`keep`), habla con voz suave (`lines`, cada
##      `words_every` s), lanza abanicos lentos (`fan_pattern`, cada `fan_every` s) y hace salir sombras
##      de los escalones (`minion`, `minion_count` cada `minion_every` s).
##   2. El enjambre (66-33 %): se deshace en formas (`swarm_count` de `minion` al entrar, y más hasta
##      `swarm_cap`) y solo queda la forma central, que dispara anillos (`ring_pattern`, cada `ring_every`
##      s). Cada `recompose_every` s se esfuma y se recompone donde está el jugador más alejado: aviso
##      (`recompose_warn` s) y golpe al llegar (`recompose_damage` en `recompose_radius` m).
##   3. El ser sin rostro (< 33 %): enorme y lento, anillos más seguidos y llamas negras con aviso bajo los
##      jugadores (`flame_count` cada `flame_every` s, `flame_damage` en `flame_radius` m). La cordura baja
##      todo el rato a todos (`dread` por segundo).
## En red, el anfitrión decide; la marioneta cambia de forma por la vida (que llega en la foto) y quita
## la cordura de la fase 3 a los jugadores de su PC.

const CAMERA_SIZE := 20.0
const VOICE := Color(1.0, 0.85, 0.45)
const DARK := Color(0.45, 0.25, 0.7)
const FORMS := ["", "nyarla_faraon", "nyarla_nucleo", "nyarla_sin_rostro"]
const GLOW_COLOR := Color(0.62, 0.38, 1.0)

var phase := 0
var shown := 0                              ## forma que se ve (también en la marioneta)
var recomposed := 0                         ## veces que se ha recompuesto (tests)
var flames := 0                             ## llamas negras lanzadas (tests)
var glow: OmniLight3D                       ## su luz, en la fase 3
var _fan := 3.0
var _ring := 3.0
var _words := 2.0
var _minion := 6.0
var _recompose := 0.0
var _flame := 4.0
var _away := 0.0                            ## s que le quedan esfumado (fase 2)
var _to := Vector3.ZERO
var _side := 1.0
var _line := 0

func start(e: Enemy) -> void:
	_set_phase(e, 1, false)
	_words = 1.5
	e.shield_t = float(e.data.param("enter_shield", 2.5))         # mientras sale, como Dagon

func phase_for(e: Enemy) -> int:
	var k := e.health / maxf(e.data.max_health * e.health_scale, 1.0)
	return 1 if k > 0.66 else (2 if k > 0.33 else 3)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	if e.world != null: e.world.view_at_least(CAMERA_SIZE)
	var p := phase_for(e)
	if p > phase: _set_phase(e, p, true)
	if phase == 3: _dread(e, delta)
	if target == null: return Vector3.ZERO
	match phase:
		1: return _pharaoh(e, target, delta)
		2: return _swarm(e, target, delta)
	return _faceless(e, target, delta)

# ------------------------------------------------------------------ las formas

func _set_phase(e: Enemy, p: int, shift: bool) -> void:
	phase = p
	_show(e, p)
	if not shift: return
	e.shield_t = float(e.data.param("shift_shield", 2.0))
	if e.world == null: return
	e.world.shake(0.6)
	e.world.sfx("roar", e.global_position)
	e.world.ground_hit(e.global_position * Vector3(1, 0, 1), 3.0, DARK)
	e.world.shout(String(e.data.param("phase_text_%d" % p, "…")), e.global_position + Vector3(0, 4.5, 0), VOICE, 90, 1.5, 2.6)
	if OS.get_cmdline_user_args().has("log=true"): print("NYARLATHOTEP fase %d t=%.1f vida=%.0f/%.0f" % [p, e._spawn_t, e.health, e.data.max_health * e.health_scale])
	if p == 2:
		_recompose = float(e.data.param("recompose_every", 7.0)) * 0.6
		_spawn(e, int(e.data.param("swarm_count", 8)))
	if p == 3: _flame = 2.5

## Cambia el modelo a la forma `p` (con su escala).
func _show(e: Enemy, p: int) -> void:
	if shown == p: return
	shown = p
	var model := String(e.data.param("form_%d" % p, FORMS[p]))
	var scale := float(e.data.param("scale_%d" % p, e.data.model_scale))
	if e.model_name != model or not is_equal_approx(e.model_scale, scale): e.swap_model(model, scale)
	if p == 3 and glow == null: _glow(e)

## El ser sin rostro es negro sobre la noche: una luz violeta suya aclara el suelo a su alrededor y lo
## recorta (en el anfitrión y en la marioneta).
func _glow(e: Enemy) -> void:
	glow = OmniLight3D.new()
	glow.name = "NyarlaGlow"
	glow.light_color = GLOW_COLOR
	glow.light_energy = float(e.data.param("glow_energy", 2.2))
	glow.omni_range = float(e.data.param("glow_range", 10.0))
	glow.omni_attenuation = 0.8
	glow.shadow_enabled = false
	glow.position = Vector3(0, 1.2, 1.5)                      # un poco por delante: recorta las alas
	e.add_child(glow)

# ------------------------------------------------------------------ 1: el faraón negro

func _pharaoh(e: Enemy, target: Player, delta: float) -> Vector3:
	_fan -= delta
	_words -= delta
	_minion -= delta
	if _words <= 0.0:
		_words = float(e.data.param("words_every", 9.0))
		_speak(e)
	if _fan <= 0.0:
		_fan = float(e.data.param("fan_every", 3.5))
		_fire(e, e.data.param("fan_pattern", null), target)
	if _minion <= 0.0:
		_minion = float(e.data.param("minion_every", 10.0))
		_spawn(e, int(e.data.param("minion_count", 3)))
	e.anim = "cast" if e.runner != null and e.runner.busy else "walk"
	var to := target.global_position - e.global_position
	to.y = 0.0
	var d := to.length()
	var keep := float(e.data.param("keep", 7.0))
	var dir := toward(e, target)
	if d > keep + 1.0: return shape_path(e, dir, e.data.move_speed)
	if d < keep - 1.5: return -dir * e.data.move_speed * 0.8
	if randf() < delta * 0.2: _side = -_side
	return Vector3(-dir.z, 0, dir.x) * _side * e.data.move_speed * 0.4

## Una de sus frases, con voz suave, por orden.
func _speak(e: Enemy) -> void:
	var lines: Array = e.data.param("lines", [])
	if lines.is_empty() or e.world == null: return
	var text := String(lines[_line % lines.size()])
	_line += 1
	e.world.shout(text, e.global_position + Vector3(0, 3.6, 0), VOICE, 52, 0.6, 3.2)
	e.world.sfx("nyarla_voice", e.global_position)

# ------------------------------------------------------------------ 2: el enjambre

func _swarm(e: Enemy, target: Player, delta: float) -> Vector3:
	if _away > 0.0:                                        # esfumado: vuelve donde está el más alejado
		_away -= delta
		e.anim = "idle"
		if _away <= 0.0: _arrive(e)
		return Vector3.ZERO
	_ring -= delta
	_recompose -= delta
	_minion -= delta
	if _ring <= 0.0:
		_ring = float(e.data.param("ring_every", 4.0))
		_fire(e, e.data.param("ring_pattern", null), target)
	if _minion <= 0.0:
		_minion = float(e.data.param("minion_every", 10.0))
		var have := e.world.enemies.filter(func(x: Node) -> bool: return x is Enemy and (x as Enemy).is_alive() and (x as Enemy).data == e.data.param("minion", null)).size() if e.world.get("enemies") != null else 0
		var room := int(e.data.param("swarm_cap", 12)) - have
		if room > 0: _spawn(e, mini(room, int(e.data.param("minion_count", 3))))
	if _recompose <= 0.0:
		_recompose = float(e.data.param("recompose_every", 7.0))
		_vanish(e)
		return Vector3.ZERO
	e.anim = "walk"
	var to := target.global_position - e.global_position
	to.y = 0.0
	var side := Vector3(-to.z, 0, to.x).normalized() * _side
	return (side + to.normalized() * clampf((to.length() - 6.0) * 0.3, -1.0, 1.0)).normalized() * e.data.move_speed * 0.6

## El jugador vivo más alejado de él.
func _farthest(e: Enemy) -> Player:
	var best: Player = null
	var bd := -1.0
	for q in e.world.players:
		if q.health <= 0.0: continue
		var d := q.global_position.distance_to(e.global_position)
		if d > bd:
			bd = d
			best = q
	return best

## Se esfuma: aviso donde se recompondrá.
func _vanish(e: Enemy) -> void:
	var q := _farthest(e)
	if q == null: return
	_to = q.global_position * Vector3(1, 0, 1)
	_away = float(e.data.param("recompose_warn", 1.3))
	e.shield_t = _away + 0.1
	if e.visual != null: e.visual.visible = false
	e.buried = true
	var tg := Telegraph.enemy(float(e.data.param("recompose_radius", 2.6)), _away, Color(DARK, 0.85))
	tg.position = _to
	e.world.fx.add_child(tg)
	e.world.sfx("nyarla_scatter", e.global_position)
	e.world.sfx("nyarla_gather", _to)                     # se junta allí: su golpe sordo, al llegar (1,25 s)

## Se recompone: golpea donde llega.
func _arrive(e: Enemy) -> void:
	recomposed += 1
	e.position = Vector3(_to.x, e.position.y, _to.z)
	e.reset_physics_interpolation()
	if e.visual != null: e.visual.visible = true
	e.buried = false
	var r := float(e.data.param("recompose_radius", 2.6))
	var dm := Damage.new(float(e.data.param("recompose_damage", 14.0)), 6.0)
	dm.source = e
	e.world.strike(_to, r, dm)
	e.world.ground_hit(_to, r, DARK)
	e.world.shake(0.35)

# ------------------------------------------------------------------ 3: el ser sin rostro

func _faceless(e: Enemy, target: Player, delta: float) -> Vector3:
	_ring -= delta
	_flame -= delta
	if _ring <= 0.0:
		_ring = float(e.data.param("ring_every", 4.0)) * 0.7
		_fire(e, e.data.param("ring_pattern", null), target)
	if _flame <= 0.0:
		_flame = float(e.data.param("flame_every", 5.0))
		_flames(e)
	e.anim = "walk"
	var to := target.global_position - e.global_position
	to.y = 0.0
	if to.length() < 4.0: return Vector3.ZERO
	return toward(e, target) * e.data.move_speed * 0.5

## Llamas negras bajo los jugadores (y alrededor), con aviso.
func _flames(e: Enemy) -> void:
	var warn := float(e.data.param("flame_warn", 1.1))
	var r := float(e.data.param("flame_radius", 1.6))
	var spots: Array[Vector3] = []
	for q in e.world.players:
		if q.health > 0.0: spots.append(q.global_position * Vector3(1, 0, 1))
	var n := int(e.data.param("flame_count", 4))
	var i := 0
	while spots.size() < n and not spots.is_empty():
		var a := randf() * TAU
		spots.append(spots[i % spots.size()] + Vector3(cos(a), 0, sin(a)) * randf_range(2.0, 4.0))
		i += 1
	for at in spots:
		flames += 1
		var tg := Telegraph.enemy(r, warn, Color(0.25, 0.05, 0.35, 0.9))
		tg.position = at
		e.world.fx.add_child(tg)
		var eid := e.get_instance_id()
		e.get_tree().create_timer(warn, false).timeout.connect(func() -> void:
			var e2 := instance_from_id(eid) as Enemy
			if e2 == null or not e2.is_alive(): return
			var dm := Damage.new(float(e2.data.param("flame_damage", 12.0)), 6.0)
			dm.source = e2
			e2.world.strike(at, r, dm, false)
			e2.world.ground_hit(at, r, Color(0.2, 0.05, 0.3)))

## La cordura baja todo el rato (a los jugadores de este PC).
func _dread(e: Enemy, delta: float) -> void:
	var rate := float(e.data.param("dread", 1.2))
	for q in e.world.players:
		if q.remote or q.health <= 0.0: continue
		q.drain_sanity(rate * delta, String(e.data.id))

# ------------------------------------------------------------------ comunes

func _fire(e: Enemy, pat: Variant, target: Player) -> void:
	if not (pat is BulletPattern) or e.runner == null: return
	e.runner.busy = false
	e.runner.fire(pat as BulletPattern, func() -> Vector3: return target.global_position if is_instance_valid(target) else e.global_position + e.facing)

func _spawn(e: Enemy, n: int) -> void:
	var game := e.get_tree().current_scene if e.is_inside_tree() else null
	var d: EnemyData = e.data.param("minion", null)
	if d == null or game == null or game.get("director") == null: return
	for i in n:
		var a := randf() * TAU
		game.director.spawn(d, e.global_position * Vector3(1, 0, 1) + Vector3(cos(a), 0, sin(a)) * randf_range(2.5, 5.0))
	e.world.sfx("chant", e.global_position)

## Marioneta: la forma por la vida y la cordura de la fase 3 para los de este PC.
func puppet_step(e: Enemy, delta: float) -> void:
	var p := phase_for(e)
	if p != shown: _show(e, p)
	if p == 3: _dread(e, delta)

func can_shoot(_e: Enemy) -> bool:
	return false                                           # dispara por su cuenta (_fire)

func touches(_e: Enemy) -> bool:
	return _away <= 0.0
