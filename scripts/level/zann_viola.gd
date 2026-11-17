class_name ZannViola
extends Node
## La viola de Erich Zann (hito 22.6, «La música de Erich Zann»). Suena desde la ventana más alta de la
## rue d'Auseil (`viola` en el JSON de la arena: x, z y la altura de la ventana) y en cada compás sale de
## debajo una onda por la calle (un pentagrama que se abre, `ground_fx` modo 13):
## - aparta a los enemigos que alcanza, más cerca de la ventana más fuerte (`LevelData.viola_push`, que
##   baja hasta `viola_push_far` en el borde), y a lo que viene del otro lado (`outer` en sus parámetros)
##   además le duele (`viola_hurt`);
## - el compás se acelera de `viola_period` a `viola_period_end` hasta el evento final, y con el jefe
##   suelto va a `viola_period_boss`; por debajo de `viola_frenzy` s la música es ya frenesí: la onda,
##   roja, también quita cordura a quien alcanza (`viola_sanity`, menos lejos de la ventana; el esquive
##   la salta);
## - el jefe puede hacerla callar un rato (`hush`): ni compases ni ondas.
## Cada PC lleva su compás (el del director) y aplica la onda a sus jugadores; a los enemigos, solo el
## anfitrión. Lo que calla la viola lo decide el anfitrión (suceso "viola").

const TINT := Color(0.98, 0.86, 0.56)              ## la música
const FRENZY_TINT := Color(1.0, 0.42, 0.36)        ## el frenesí
const BAND := 1.6                                  ## m de ancho del pentagrama
const CANDLE := Color(1.0, 0.78, 0.48)
const LIGHT_BASE := 1.3
const LIGHT_BEAT := 3.4
const TAG := &"viola"

static var current: ZannViola

var world: CombatWorld
var level: LevelData
var host := true
var game: Node
var window := Vector3.INF                          ## la ventana de Zann
var ground := Vector2.ZERO                         ## de donde salen las ondas
var waves: Array[Dictionary] = []                  ## {r, prev, frenzy, mi}
var beats := 0                                     ## compases (tests)
var pushed := 0                                    ## enemigos apartados (tests)
var hurt := 0                                      ## golpes a lo de fuera (tests)
var drained := 0                                   ## jugadores a los que el frenesí quitó cordura (tests)
var hush_t := 0.0                                  ## s que calla
var pull_at := Vector3.INF                         ## el viento de la ventana (el jefe): hacia dónde
var pull_t := 0.0
var pull_force := 0.0
var frenzy_seen := false                           ## ya ha habido frenesí (el consejo)
var _beat_t := 1.2
var _light: OmniLight3D
var _flash := 0.0
var _boss := false                                 ## el jefe suelto (se mira cada poco)
var _boss_check := 0.0
var _rng := RandomNumberGenerator.new()

func setup(p_world: CombatWorld, p_level: LevelData, p_host: bool, p_game: Node = null) -> ZannViola:
	name = "ZannViola"
	world = p_world; level = p_level; host = p_host; game = p_game
	_rng.randomize()
	current = self
	var layout := {}
	if level != null and FileAccess.file_exists(level.arena):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(level.arena))
		if j is Dictionary: layout = j
	var v: Array = layout.get("viola", [])
	if v.size() >= 2: place(Vector2(float(v[0]), float(v[1])), float(v[2]) if v.size() > 2 else 10.0)
	return self

## Dónde está la ventana (la arena; también para las pruebas).
func place(at: Vector2, height: float) -> void:
	window = Vector3(at.x, height, at.y)
	ground = at

func _exit_tree() -> void:
	if current == self: current = null

func _ready() -> void:
	if window == Vector3.INF or world == null or world.fx == null: return
	_light = OmniLight3D.new()
	_light.light_color = CANDLE
	_light.light_energy = LIGHT_BASE
	_light.omni_range = 9.0
	_light.shadow_enabled = false
	_light.position = window + Vector3(0, 0, 0.8)
	world.fx.add_child(_light)

# ------------------------------------------------------------------ el compás

func time() -> float:
	var dir: Variant = game.get("director") if game != null else null
	return float(dir.time) if dir != null else 0.0

## s entre compases ahora (0: no suena).
func period() -> float:
	if level == null or level.viola_period <= 0.0: return 0.0
	var k := Challenge.value("viola_tempo")          # el desafío «Allegro furioso»: más deprisa
	if _boss: return level.viola_period_boss * k
	var f := clampf(time() / maxf(level.final_time, 1.0), 0.0, 1.0)
	return lerpf(level.viola_period, level.viola_period_end, f) * k

func frenzy() -> bool:
	var p := period()
	return p > 0.0 and level != null and p < level.viola_frenzy

func boss_alive() -> bool:
	for e in world.enemies:
		if e is Enemy and is_instance_valid(e) and e.is_alive() and (e as Enemy).behavior is VoidBehavior: return true
	return false

## Calla `t` s (el jefe). En el anfitrión, también en los invitados.
func hush(t: float) -> void:
	hush_t = maxf(hush_t, t)
	_beat_t = maxf(_beat_t, t)
	if host: _net({"a": "hush", "t": t})

## El viento de la ventana (el jefe): `t` s tira de los jugadores hacia `at`.
func pull(at: Vector3, t: float, force: float) -> void:
	pull_at = at
	pull_t = t
	pull_force = force
	if host: _net({"a": "pull", "x": snappedf(at.x, 0.01), "z": snappedf(at.z, 0.01), "t": t, "f": force})

## Un compás: la onda, la luz de la ventana, la nota.
func beat() -> void:
	beats += 1
	var fz := frenzy()
	if fz: frenzy_seen = true
	var w := {"r": 0.0, "prev": 0.0, "frenzy": fz, "mi": null}
	if world != null and world.fx != null and window != Vector3.INF:
		var mi := VoxelFx.ground(13, level.viola_radius if level != null else 34.0)
		mi.position = Vector3(ground.x, 0.05, ground.y)
		var m: ShaderMaterial = mi.material_override
		m.set_shader_parameter("tint", FRENZY_TINT if fz else TINT)
		m.set_shader_parameter("age", BAND / maxf(level.viola_radius if level != null else 34.0, 1.0))
		m.set_shader_parameter("wave_r", 0.0)
		world.fx.add_child(mi)
		w.mi = mi
		VoxelFx.puff(world.fx, window + Vector3(0, 0, 0.6), "sparkle", 0.5, FRENZY_TINT if fz else TINT, 1.0)
		Auto.sfx_at("viola_frenzy" if fz else "viola", window, -2.0)
	waves.append(w)
	_flash = 1.0

func _physics_process(delta: float) -> void:
	_boss_check -= delta
	if _boss_check <= 0.0:
		_boss_check = 0.5
		_boss = boss_alive()
	if hush_t > 0.0: hush_t -= delta
	if pull_t > 0.0:
		pull_t -= delta
		_pull_players()
	var p := period()
	if p > 0.0:
		_beat_t -= delta
		if _beat_t <= 0.0 and hush_t <= 0.0:
			_beat_t += p
			if _beat_t < 0.0: _beat_t = p
			beat()
	var R := level.viola_radius if level != null else 34.0
	var sp := level.viola_speed if level != null else 16.0
	for w in waves:
		w.prev = w.r
		w.r = float(w.r) + sp * delta
		_cross(w, R)
	for i in range(waves.size() - 1, -1, -1):
		if float(waves[i].r) > R:
			if waves[i].mi != null and is_instance_valid(waves[i].mi): (waves[i].mi as Node).queue_free()
			waves.remove_at(i)

## Lo que la onda alcanza en este paso (entre su radio de antes y el de ahora).
func _cross(w: Dictionary, R: float) -> void:
	var r0 := float(w.prev)
	var r1 := float(w.r)
	if host:
		for e in world.enemies:
			if not (e is Enemy) or not is_instance_valid(e) or not e.is_alive(): continue
			var en := e as Enemy
			if en.puppet or en.buried: continue
			var to := Vector2(en.global_position.x, en.global_position.z) - ground
			var d := to.length()
			if d <= r0 or d > r1 or d < 0.05: continue
			var k := lerpf(1.0, level.viola_push_far, clampf(d / R, 0.0, 1.0))
			var dir := to / d
			en.nudge(Vector3(dir.x, 0.0, dir.y) * level.viola_push * 2.5 * k)
			pushed += 1
			if bool(en.data.param("outer", false)):
				var dm := Damage.new(level.viola_hurt, 0.0)
				dm.tag = TAG
				en.take_damage(dm)
				if en.is_alive() and not en.data.unique: en.stun(0.25)
				hurt += 1
	if not bool(w.frenzy): return
	for q in world.players:
		if q.remote or q.health <= 0.0: continue
		var d2 := Vector2(q.global_position.x, q.global_position.z).distance_to(ground)
		if d2 > r0 and d2 <= r1 and not q.is_invulnerable():          # el esquive la salta
			var k2 := lerpf(1.0, level.viola_push_far, clampf(d2 / R, 0.0, 1.0))   # de lejos, más débil
			q.drain_sanity(level.viola_sanity * k2, L.t("La viola de Zann"), &"musica")
			drained += 1

func _pull_players() -> void:
	if pull_at == Vector3.INF: return
	for q in world.players:
		if q.remote or q.health <= 0.0: continue
		var to := Vector2(pull_at.x - q.global_position.x, pull_at.z - q.global_position.z)
		var d := to.length()
		if d > 1.2: q.push += Vector3(to.x, 0.0, to.y) / d * pull_force * clampf(1.3 - d / 20.0, 0.3, 1.0)

func _process(delta: float) -> void:
	var R := level.viola_radius if level != null else 34.0
	for w in waves:
		if w.mi == null or not is_instance_valid(w.mi): continue
		var m: ShaderMaterial = (w.mi as MeshInstance3D).material_override
		m.set_shader_parameter("wave_r", float(w.r) / R)
		m.set_shader_parameter("fade", 1.0 - smoothstep(0.8, 1.0, float(w.r) / R))
	_flash = maxf(0.0, _flash - delta * 3.0)
	if _light != null:
		var quiet := hush_t > 0.0
		_light.light_energy = (0.35 if quiet else LIGHT_BASE) + LIGHT_BEAT * _flash
		_light.light_color = CANDLE.lerp(FRENZY_TINT, 0.5 if frenzy() else 0.0)

# ------------------------------------------------------------------ red

## Invitado: lo que decidió el anfitrión.
func remote(d: Dictionary) -> void:
	match String(d.get("a", "")):
		"hush": hush(float(d.get("t", 3.0)))
		"pull": pull(Vector3(float(d.get("x", 0.0)), 0.0, float(d.get("z", 0.0))), float(d.get("t", 2.0)), float(d.get("f", 2.0)))

func _net(d: Dictionary) -> void:
	var net: Variant = game.get("net_game") if game != null else null
	if net is NetGame:
		d["k"] = "viola"
		(net as NetGame)._event(d)
