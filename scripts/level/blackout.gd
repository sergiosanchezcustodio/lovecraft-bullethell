class_name Blackout
extends Node
## La luz de Federal Hill (hito 23.8, «El que acecha en la oscuridad»). Las farolas eléctricas de la
## colina (`blackout_lamp` en el nivel, el modelo; su luz la pone la arena) son el escudo: lo que viene de
## la oscuridad (`dark` en sus parámetros: las sombras aladas y el Morador) no entra en su luz ni en la del
## farol de un jugador, y si queda dentro se quema (DarkBehavior, HaunterBehavior).
## - Con la corriente dada, la tormenta la corta cada `blackout_on` s (de `blackout_on` a `blackout_on_end`
##   hasta el evento final, y `blackout_on_boss` con el jefe suelto): un rayo, las farolas parpadean y se
##   apagan `blackout_off` s (hasta `blackout_off_end`). A oscuras, los faroles de los jugadores bajan a
##   `blackout_lantern` y la noche quita `blackout_sanity` de cordura por segundo.
## - Una farola también se puede apagar sola (`douse`: los sectarios la apagan, el Morador la revienta).
## - El destello de un rayo lo alumbra todo un instante (`flash_lit`).
## Lo decide el anfitrión (suceso de red "blackout"); cada PC alumbra lo suyo.

const BLUE := Color(0.72, 0.82, 1.0)
const FLICKER := 0.9                              ## s que parpadea al cortarse y al volver
const TAG := &"luz"
const BLAKE := 1.3                                ## el farol de Blake alumbra más: conoce la iglesia por su hermano

static var current: Blackout

var world: CombatWorld
var level: LevelData
var host := true
var game: Node
var lamps: Array[Dictionary] = []                 ## {at: Vector2, light, holder, glow: Array, base, off_t}
var power := true                                 ## hay corriente
var cuts := 0                                     ## apagones (tests)
var dark_t := 0.0                                 ## s que dura el apagón de ahora
var steeple := Vector3.INF                        ## el campanario de la iglesia (de donde baja el jefe)
var flash_lit := false                            ## el destello de un rayo lo alumbra todo
var _t := 0.0                                     ## s hasta el siguiente corte (con corriente)
var _flick := 0.0                                 ## s de parpadeo que quedan
var _boss := false
var _boss_check := 0.0
var _lantern := 1.0                               ## lo que alumbran ahora los faroles (fracción)
var _lanterns: Dictionary = {}                    ## jugador -> [alcance normal de su farol, el que le pusimos]
var _rng := RandomNumberGenerator.new()

func setup(p_world: CombatWorld, p_level: LevelData, p_host: bool, p_game: Node = null, arena: Node3D = null) -> Blackout:
	name = "Blackout"   # i18n: no
	world = p_world; level = p_level; host = p_host; game = p_game
	_rng.randomize()
	current = self
	_t = level.blackout_on if level != null else 20.0
	if level != null and FileAccess.file_exists(level.arena):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(level.arena))
		if j is Dictionary and (j as Dictionary).has("steeple"):
			var v: Array = j.steeple
			steeple = Vector3(float(v[0]), float(v[2]) if v.size() > 2 else 14.0, float(v[1]))
	if arena != null: collect(arena)
	return self

func _exit_tree() -> void:
	if current == self: current = null

## Las farolas de la arena: sus luces y lo que brilla en su globo.
func collect(arena: Node3D) -> void:
	var model := level.blackout_lamp if level != null else "fed_farola"
	for l: OmniLight3D in arena.get_meta("lights", []):
		var holder := l.get_parent() as Node3D
		if holder == null or holder.get_node_or_null(model) == null: continue
		var glow: Array = []
		var g := holder.get_node_or_null("%s/globe" % model)
		if g != null: glow.append(g)
		add_lamp(Vector2(holder.global_position.x, holder.global_position.z), l, glow)

## Una farola (también para las pruebas, sin luz).
func add_lamp(at: Vector2, light: OmniLight3D = null, glow: Array = []) -> void:
	lamps.append({"at": at, "light": light, "glow": glow, "base": light.light_energy if light != null else 1.0, "off_t": 0.0})

func radius() -> float:
	return level.blackout_lamp_r if level != null else 4.0

## ¿Da luz la farola `i` ahora?
func lit_lamp(i: int) -> bool:
	return power and float(lamps[i].off_t) <= 0.0

## La luz que alcanza `at` (con `margin` m de más): su centro, o INF si está a oscuras. `k` es la
## fracción del farol de los jugadores que cuenta (lo de la oscuridad se acerca más que a una farola).
func light_at(at: Vector3, k: float, margin := 0.0) -> Vector3:
	var p := Vector2(at.x, at.z)
	var r := radius() + margin
	for i in lamps.size():
		if lit_lamp(i) and p.distance_to(lamps[i].at) < r: return Vector3(lamps[i].at.x, 0.0, lamps[i].at.y)
	if world != null:
		for q in world.players:
			if q.health <= 0.0: continue
			var lr := lantern(q) * k + margin
			if Vector2(q.global_position.x, q.global_position.z).distance_to(p) < lr: return Vector3(q.global_position.x, 0.0, q.global_position.z)
	return Vector3.INF

## Alcance del farol de `q` ahora (a oscuras, menos).
func lantern(q: Node3D) -> float:
	var l := q.get_node_or_null("CarryLight") as OmniLight3D
	return (l.omni_range if l != null else 4.5)

## Cuánto alumbran los faroles respecto a lo normal (tests).
func lantern_k() -> float:
	return _lantern

func boss_alive() -> bool:
	for e in world.enemies:
		if e is Enemy and is_instance_valid(e) and e.is_alive() and (e as Enemy).behavior is HaunterBehavior: return true
	return false

func time() -> float:
	var dir: Variant = game.get("director") if game != null else null
	return float(dir.time) if dir != null else 0.0

## s con corriente entre apagones, ahora.
func on_time() -> float:
	if level == null: return 20.0
	var k := Challenge.value("blackout_on")              # el desafío: más a menudo
	if _boss: return level.blackout_on_boss * k
	var f := clampf(time() / maxf(level.final_time, 1.0), 0.0, 1.0)
	return lerpf(level.blackout_on, level.blackout_on_end, f) * k

func off_time() -> float:
	if level == null: return 6.0
	var f := 1.0 if _boss else clampf(time() / maxf(level.final_time, 1.0), 0.0, 1.0)
	return lerpf(level.blackout_off, level.blackout_off_end, f)

## Se va la luz `t` s (la tormenta o el jefe). En el anfitrión, también en los invitados.
func cut(t: float) -> void:
	cuts += 1
	power = false
	dark_t = maxf(dark_t, t)
	_flick = FLICKER
	if world != null:
		var w: Variant = game.get("weather") if game != null else null
		if w is Weather: (w as Weather).strike_now()
		Auto.sfx("power_out", -2.0)
	if host: _net({"a": "cut", "t": t})

## Vuelve la corriente.
func restore() -> void:
	power = true
	dark_t = 0.0
	_flick = FLICKER * 0.6
	_t = on_time()
	if world != null: Auto.sfx("power_on", -6.0)
	if host: _net({"a": "on"})

## Apaga la farola `i` `t` s (los sectarios, el Morador).
func douse(i: int, t: float) -> void:
	if i < 0 or i >= lamps.size(): return
	lamps[i].off_t = maxf(float(lamps[i].off_t), t)
	if world != null:
		Auto.sfx_at("lamp_break" if t >= 10.0 else "power_out", Vector3(lamps[i].at.x, 2.0, lamps[i].at.y), -6.0)
		if world.fx != null: VoxelFx.puff(world.fx, Vector3(lamps[i].at.x, 3.6, lamps[i].at.y), "sparkle", 0.4, BLUE, 0.8)
	if host: _net({"a": "douse", "i": i, "t": t})

## La farola encendida más cerca de `at` en `r` m (-1: ninguna).
func nearest_lit(at: Vector3, r: float) -> int:
	var best := -1
	var bd := r
	for i in lamps.size():
		if not lit_lamp(i): continue
		var d := Vector2(at.x, at.z).distance_to(lamps[i].at)
		if d < bd:
			bd = d
			best = i
	return best

func _physics_process(delta: float) -> void:
	if level == null: return
	_boss_check -= delta
	if _boss_check <= 0.0:
		_boss_check = 0.5
		_boss = world != null and boss_alive()
	for d: Dictionary in lamps:
		if float(d.off_t) > 0.0: d.off_t = float(d.off_t) - delta
	if power:
		if host:
			_t -= delta
			if _t <= 0.0: cut(off_time())
	else:
		dark_t -= delta
		if host and dark_t <= 0.0: restore()
		_drain(delta)
	var w: Variant = game.get("weather") if game != null else null
	flash_lit = w is Weather and float((w as Weather).flash) > 0.5

## A oscuras, la noche pesa: cordura poco a poco.
func _drain(delta: float) -> void:
	if world == null or level.blackout_sanity <= 0.0: return
	for q in world.players:
		if q.remote or q.health <= 0.0: continue
		q.drain_sanity(level.blackout_sanity * delta, L.t("La oscuridad"), &"oscuridad")

func _process(delta: float) -> void:
	_flick = maxf(0.0, _flick - delta)
	var want := 1.0 if power else (level.blackout_lantern if level != null else 0.6)
	_lantern = move_toward(_lantern, want, delta * 1.5)
	if world != null:
		for q in world.players:
			var l := q.get_node_or_null("CarryLight") as OmniLight3D
			if l == null: continue
			# el alcance normal: el suyo, salvo que lo hayamos puesto nosotros (al subir de nivel se rehace)
			if not _lanterns.has(q) or not is_equal_approx(l.omni_range, float(_lanterns[q][1])):
				_lanterns[q] = [l.omni_range * (BLAKE if q.data != null and q.data.id == &"blake" else 1.0), 0.0]
			var jitter := 1.0 if power else 1.0 + 0.06 * sin(Time.get_ticks_msec() * 0.023 + q.get_instance_id())
			l.omni_range = float(_lanterns[q][0]) * _lantern * jitter
			_lanterns[q][1] = l.omni_range
	for i in lamps.size():
		var d: Dictionary = lamps[i]
		var on := lit_lamp(i)
		if _flick > 0.0: on = _rng.randf() < (0.35 if not power else 0.65)    # parpadea al cortarse y al volver
		var l: OmniLight3D = d.light
		if l != null and is_instance_valid(l): l.visible = on
		for g: Node3D in d.glow:
			if is_instance_valid(g): g.visible = on

# ------------------------------------------------------------------ red

## Invitado: lo que decidió el anfitrión.
func remote(d: Dictionary) -> void:
	match String(d.get("a", "")):
		"cut": cut(float(d.get("t", 6.0)))
		"on": restore()
		"douse": douse(int(d.get("i", -1)), float(d.get("t", 8.0)))

func _net(d: Dictionary) -> void:
	var net: Variant = game.get("net_game") if game != null else null
	if net is NetGame:
		d["k"] = "blackout"
		(net as NetGame)._event(d)
