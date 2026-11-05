class_name Objective
extends Node3D
## Objetivo a mitad de nivel (hito 13.5, fase 13): opcional, con su recompensa y su tiempo.
## Tres tipos:
## - `rescue`: un superviviente herido espera en el suelo; al llegar a su lado se levanta y
##   sigue al jugador en pie más cercano hasta la bengala. Las criaturas que tiene encima le
##   quitan vida: si se le acaba, se pierde.
## - `ritual`: un círculo de velas; hay que quedarse dentro `need` s (si no queda nadie, el
##   avance se pierde despacio) mientras salen criaturas a defenderlo.
## - `relic`: una tablilla con un signo antiguo; quien la toca la lleva (más despacio,
##   `CARRY_SLOW`) hasta el círculo de entrega. Si cae, la suelta donde está.
## - `peddler` (hito 16.12): el buhonero de la parte pone su manta con tres mercancías (remedio,
##   baratija y libro). Quien se queda `HOLD` s encima de una la compra con los dólares del
##   nivel (`buy_hook`, en su PC); cada jugador, una de cada. Se va al acabar su tiempo.
## Lo decide el anfitrión; en red, los invitados tienen una copia (`mirror`) que recibe su
## estado (`NetGame`: ob+, ob~ y ob!). Lo crea y lo atiende `ObjectiveDirector`.

signal synced(state: Array)                     ## anfitrión: estado para los invitados (cada SYNC s)
signal finished(obj: Objective, ok: bool)

enum State { WAIT, ACTIVE, DONE, FAILED }

const SYNC := 0.15
const REACH := 1.6                              ## m para levantar al superviviente o coger la reliquia
const GOAL := 2.0                               ## m de la meta para entregar
const CARRY_SLOW := 0.72

var kind := "rescue"
var world: CombatWorld
var director: WaveDirector
var a := Vector3.ZERO                           ## donde empieza (superviviente, círculo, reliquia)
var b := Vector3.ZERO                           ## meta (rescate y reliquia)
var model_name := ""                            ## superviviente
var reward: Array = ["money", 0]                ## [tipo, cantidad]: money, chest, xp
var limit := 90.0
var need := 12.0                                ## ritual: s dentro
var radius := 2.6                               ## ritual: radio del círculo
var drain := 14.0                               ## rescate: vida por s por criatura encima
var guards := 4                                 ## ritual: criaturas al empezar
var mirror := false
var goods: Array = []                           ## buhonero: mercancías (objectives.json, peddler.goods)
var price_mult := 1.0                           ## buhonero: precios de la parte
var buy_hook: Callable                          ## buhonero: (Player, mercancía, precio) -> bool
var purse_hook: Callable                        ## buhonero: () -> int, los dólares que quedan en este PC

var state := State.WAIT
var t := 0.0
var progress := 0.0                             ## ritual: s dentro; rescate: vida (0..1)
var carrier := -1                               ## reliquia: índice del jugador que la lleva
var body := Vector3.ZERO                        ## superviviente o reliquia (donde está)

var _sync_t := 0.0
var _guard_t := 0.0
var _anim_t := 0.0
var _rise_t := -1.0
var _model: Node3D
var _relic: Node3D
var _ring_a: MeshInstance3D
var _ring_b: MeshInstance3D
var _beam: MeshInstance3D
var _light: OmniLight3D
var _chant_t := 0.0
var _net_body := Vector3.ZERO
var _stalls: Array[Vector3] = []               ## buhonero: dónde está cada mercancía
var _stall_rings: Array[MeshInstance3D] = []
var _stall_labels: Array[Label3D] = []
var _hold := {}                                 ## "jugador:mercancía" -> s encima
var bought := {}                                ## "jugador:id" -> true (en este PC)

const STALL_R := 0.55                           ## m de cada mercancía
const STALL_GAP := 1.55                         ## m entre mercancías
const MAT_FRONT := 1.55                         ## m de la manta delante del vendedor
const HOLD := 0.7                               ## s encima para comprar
const FACE := PI / 4                            ## de frente a la cámara
const PEDDLER_CFG := "res://data/objectives.json"

func setup(p_kind: String, p_world: CombatWorld, p_director: WaveDirector, p_a: Vector3, p_b: Vector3) -> Objective:
	kind = p_kind
	world = p_world
	director = p_director
	a = Vector3(p_a.x, 0, p_a.z)
	b = Vector3(p_b.x, 0, p_b.z)
	body = a
	_net_body = a
	progress = 1.0 if kind == "rescue" else 0.0
	add_to_group(&"objectives")
	return self

func net_args() -> Array:
	return [kind, a, b, model_name, reward, limit, need, radius]

static func from_net(w: CombatWorld, args: Array) -> Objective:
	var o := Objective.new().setup(String(args[0]), w, null, args[1], args[2])
	o.model_name = String(args[3])
	o.reward = args[4]
	o.limit = float(args[5])
	o.need = float(args[6])
	o.radius = float(args[7])
	o.mirror = true
	return o

func net_state() -> Array:
	return [int(state), t, progress, body, carrier]

func apply_state(s: Array) -> void:
	var was := state
	state = int(s[0]) as State
	t = float(s[1])
	progress = float(s[2])
	_net_body = s[3]
	carrier = int(s[4])
	if was == State.WAIT and state == State.ACTIVE and kind == "rescue": _rise_t = 0.0

func is_over() -> bool:
	return state == State.DONE or state == State.FAILED

func left() -> float:
	return maxf(limit - t, 0.0)

## Hacia dónde hay que ir ahora (flecha y marca).
func target() -> Vector3:
	match kind:
		"rescue": return a if state == State.WAIT else b
		"relic": return body if carrier < 0 else b
		"peddler": return a + Vector3(0, 0, MAT_FRONT + 0.6).rotated(Vector3.UP, FACE)
	return a

func carrier_player() -> Player:
	if carrier < 0 or world == null: return null
	for p in world.players:
		if p.index == carrier: return p
	return null

# ---------------------------------------------------------------- aspecto

func _ready() -> void:
	match kind:
		"ritual":
			_ring_a = _ring(radius, Color(0.62, 0.28, 1.0))
			_ring_a.position = Vector3.ZERO
			for i in 6:                                      # velas alrededor
				var ang := TAU * i / 6.0
				_candle(Vector3(cos(ang), 0, sin(ang)) * (radius + 0.15))
			_light = _omni(Color(0.7, 0.4, 1.0), radius + 2.5, Vector3(0, 1.0, 0))
		"rescue":
			_model = VoxelBuilder.load_model("res://models/%s.json" % model_name)
			add_child(_model)
		"relic":
			_relic = _tablet()
			add_child(_relic)
		"peddler":
			_stand()
	if kind != "ritual" and kind != "peddler":
		_ring_b = _ring(GOAL, Color(1.0, 0.78, 0.35))
		_ring_b.top_level = true
		_ring_b.position = b + Vector3(0, 0.04, 0)
		_beam = MeshInstance3D.new()                          # columna de luz en la meta: se ve de lejos
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.5
		cyl.height = 6.0
		_beam.mesh = cyl
		var bm := StandardMaterial3D.new()
		bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		bm.albedo_color = Color(1.0, 0.7, 0.3, 0.12)
		bm.cull_mode = BaseMaterial3D.CULL_DISABLED
		_beam.material_override = bm
		_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_beam.top_level = true
		_beam.position = b + Vector3(0, 3.0, 0)
		add_child(_beam)
		_light = _omni(Color(1.0, 0.7, 0.35), 3.5, Vector3(0, 0.8, 0))
		_light.top_level = true
		_light.position = b + Vector3(0, 0.8, 0)
	position = a
	scale = Vector3.ONE

func _ring(r: float, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(r * 2.0, r * 2.0)
	mi.mesh = pm
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/objective_ring.gdshader")
	m.set_shader_parameter("color", c)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.y = 0.04
	add_child(mi)
	return mi

func _omni(c: Color, r: float, at: Vector3) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.omni_range = r
	l.light_energy = 1.2
	l.position = at
	l.shadow_enabled = false
	add_child(l)
	return l

func _box(size: Vector3, c: Color, at: Vector3, parent: Node3D, glow := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = size
	mi.mesh = bx
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if glow:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 2.5
	mi.material_override = m
	mi.position = at
	parent.add_child(mi)
	return mi

func _candle(at: Vector3) -> void:
	var c := Node3D.new()
	c.position = at
	add_child(c)
	var h := randf_range(0.22, 0.4)
	_box(Vector3(0.09, h, 0.09), Color(0.86, 0.82, 0.7), Vector3(0, h * 0.5, 0), c)
	_box(Vector3(0.05, 0.08, 0.05), Color(1.0, 0.7, 0.3), Vector3(0, h + 0.05, 0), c, true)

## Buhonero: el vendedor de cara a la cámara, una manta delante con las tres mercancías (con su
## círculo y su precio encima) y un farol de luz cálida.
func _stand() -> void:
	if goods.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PEDDLER_CFG))
		if d is Dictionary: goods = ((d as Dictionary).get("peddler", {}) as Dictionary).get("goods", [])
	var root := Node3D.new()
	root.rotation.y = FACE
	add_child(root)
	_model = VoxelBuilder.load_model("res://models/%s.json" % model_name)
	root.add_child(_model)
	var front := MAT_FRONT
	_box(Vector3(4.6, 0.04, 1.35), Color(0.36, 0.13, 0.10), Vector3(0, 0.02, front), root)        # manta
	_box(Vector3(4.4, 0.045, 0.12), Color(0.66, 0.50, 0.22), Vector3(0, 0.025, front + 0.52), root)   # su franja
	_box(Vector3(0.5, 0.42, 0.42), Color(0.40, 0.27, 0.15), Vector3(-0.75, 0.21, -0.55), root)      # el fardo
	_box(Vector3(0.36, 0.3, 0.36), Color(0.48, 0.33, 0.18), Vector3(-0.72, 0.57, -0.52), root)
	var lamp := _box(Vector3(0.16, 0.24, 0.16), Color(1.0, 0.72, 0.32), Vector3(0.85, 0.12, 0.25), root, true)
	_box(Vector3(0.2, 0.04, 0.2), Color(0.12, 0.1, 0.08), Vector3(0, 0.14, 0), lamp)
	_light = _omni(Color(1.0, 0.72, 0.4), 6.0, Vector3(0, 1.4, 1.0))
	var n := goods.size()
	for i in n:
		var g: Dictionary = goods[i]
		var x := (i - (n - 1) * 0.5) * STALL_GAP
		var at := Vector3(x, 0, front)
		var holder := Node3D.new()
		holder.position = at
		root.add_child(holder)
		if g.has("model"):
			var m := VoxelBuilder.load_model("res://models/%s.json" % g.model)
			m.rotation.y = -FACE
			holder.add_child(m)
		else:
			_book(holder)
		_stalls.append(a + Vector3(at.x, 0, at.z).rotated(Vector3.UP, FACE))
		var ring := _ring(STALL_R, Color(1.0, 0.78, 0.35))
		ring.top_level = true
		ring.position = _stalls[i] + Vector3(0, 0.05, 0)
		_stall_rings.append(ring)
		var l := Label3D.new()
		l.font_size = 42                            # con 52, «Remedio» y «Baratija» casi se tocaban (05-11-2026)
		l.pixel_size = 0.0075
		l.outline_size = 14
		l.outline_modulate = Color(0.05, 0.03, 0.02, 0.95)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.top_level = true
		l.position = _stalls[i] + Vector3(0, 0.1, 1.05).rotated(Vector3.UP, FACE)   # delante de la manta
		l.font = MenuKit.font()
		add_child(l)
		_stall_labels.append(l)

## Libro de saberes del buhonero: tapas de cuero rojo oscuro, cantos de papel y un cierre.
func _book(r: Node3D) -> void:
	_box(Vector3(0.42, 0.1, 0.32), Color(0.4, 0.1, 0.1), Vector3(0, 0.05, 0), r)
	_box(Vector3(0.38, 0.06, 0.3), Color(0.86, 0.8, 0.64), Vector3(0.02, 0.06, 0), r)
	_box(Vector3(0.42, 0.02, 0.32), Color(0.4, 0.1, 0.1), Vector3(0, 0.11, 0), r)
	_box(Vector3(0.1, 0.03, 0.06), Color(0.85, 0.68, 0.3), Vector3(0, 0.125, 0), r, true)

## Precio de una mercancía en esta parte.
func price_of(g: Dictionary) -> int:
	return int(round(float(g.get("price", 100)) * price_mult / 5.0)) * 5

## Reliquia: tablilla de esteatita verdosa con el signo antiguo grabado, que brilla.
func _tablet() -> Node3D:
	var r := Node3D.new()
	var stone := Color(0.24, 0.3, 0.27)
	_box(Vector3(0.42, 0.5, 0.1), stone, Vector3(0, 0.25, 0), r)
	_box(Vector3(0.34, 0.06, 0.12), stone.darkened(0.2), Vector3(0, 0.52, 0), r)
	var glyph := Color(0.45, 1.0, 0.7)
	_box(Vector3(0.04, 0.3, 0.02), glyph, Vector3(0, 0.27, 0.06), r, true)            # la rama
	for s in [-1.0, 1.0]:
		_box(Vector3(0.12, 0.035, 0.02), glyph, Vector3(0.06 * s, 0.36 - 0.03, 0.06), r, true)
		_box(Vector3(0.1, 0.035, 0.02), glyph, Vector3(0.05 * s, 0.2, 0.06), r, true)
	var l := OmniLight3D.new()
	l.light_color = glyph
	l.omni_range = 2.2
	l.light_energy = 0.9
	l.position = Vector3(0, 0.4, 0.3)
	r.add_child(l)
	return r

# ---------------------------------------------------------------- lógica (anfitrión)

func _physics_process(delta: float) -> void:
	if is_over() or world == null: return
	if mirror:
		body = body.lerp(_net_body, 1.0 - exp(-12.0 * delta))
		return
	t += delta
	match kind:
		"rescue": _rescue_step(delta)
		"ritual": _ritual_step(delta)
		"relic": _relic_step(delta)
	if is_over(): return
	if t >= limit:
		_finish(false)
		return
	_sync_t -= delta
	if _sync_t <= 0.0:
		_sync_t = SYNC
		synced.emit(net_state())

func _standing() -> Array:
	return world.players.filter(func(p: Player) -> bool: return p.health > 0.0)

func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func _rescue_step(delta: float) -> void:
	var st := _standing()
	if st.is_empty(): return
	var near: Player = st[0]
	for p: Player in st:
		if _flat(p.global_position).distance_to(_flat(body)) < _flat(near.global_position).distance_to(_flat(body)): near = p
	var d := _flat(near.global_position).distance_to(_flat(body))
	if state == State.WAIT:
		if d <= REACH:
			state = State.ACTIVE
			_rise_t = 0.0
			synced.emit(net_state())
		return
	if _rise_t >= 0.0 and _rise_t < 0.75: return                  # se está levantando
	if d > 1.4:                                                    # sigue al más cercano
		var dir := (_flat(near.global_position) - _flat(body)).normalized()
		var step := dir * minf(near.data.move_speed * 0.92, d - 1.4) * delta * 6.0
		step = step.limit_length(near.data.move_speed * 0.92 * delta)
		var nb := body + Vector3(step.x, 0, step.y)
		if world.obstacles == null or not world.obstacles.is_blocked(_flat(nb), 0.3): body = nb
	# las criaturas que tiene encima le hacen daño
	var hits := 0
	if director != null:
		for e in director.alive:
			if is_instance_valid(e) and _flat(e.global_position).distance_to(_flat(body)) < 1.0 + e.data.body_radius: hits += 1
	if hits > 0:
		progress -= drain * hits * delta / 100.0
		if progress <= 0.0:
			progress = 0.0
			_finish(false)
			return
	if _flat(body).distance_to(_flat(b)) <= GOAL: _finish(true)

func _ritual_step(delta: float) -> void:
	var inside := false
	for p: Player in _standing():
		if _flat(p.global_position).distance_to(_flat(a)) <= radius:
			inside = true
			break
	if inside:
		if state == State.WAIT: state = State.ACTIVE
		progress += delta
		_guard_t -= delta
		if _guard_t <= 0.0:                                        # mientras haya alguien dentro, salen más
			_guard_t = 4.5
			_spawn_guards(1)
	else:
		progress = maxf(progress - delta * 0.25, 0.0)
	if progress >= need: _finish(true)

func _spawn_guards(n: int) -> void:
	if director == null or director.completed: return
	for i in n:
		var d := director.pick()
		if d == null or d.unique: continue
		for k in 12:
			var ang := randf() * TAU
			var p := a + Vector3(cos(ang), 0, sin(ang)) * randf_range(radius + 3.0, radius + 6.0)
			if director._spawnable(_flat(p), d.body_radius):
				director.spawn(d, p)
				break

func _relic_step(_delta: float) -> void:
	var cp := carrier_player()
	if cp != null and cp.health <= 0.0:                            # cae: la suelta donde está
		cp.carry_slow = 1.0
		body = Vector3(cp.global_position.x, 0, cp.global_position.z)
		carrier = -1
		synced.emit(net_state())
		cp = null
	if cp == null:
		for p: Player in _standing():
			if _flat(p.global_position).distance_to(_flat(body)) <= REACH:
				carrier = p.index
				state = State.ACTIVE
				cp = p
				synced.emit(net_state())
				break
	if cp != null:
		body = Vector3(cp.global_position.x, 0, cp.global_position.z)
		if _flat(body).distance_to(_flat(b)) <= GOAL: _finish(true)

func _finish(ok: bool) -> void:
	if is_over(): return
	state = State.DONE if ok else State.FAILED
	var cp := carrier_player()
	if cp != null: cp.carry_slow = 1.0
	synced.emit(net_state())
	finished.emit(self, ok)
	_vanish()

## Invitado: el anfitrión dice cómo acaba.
func end(ok: bool) -> void:
	if is_over(): return
	state = State.DONE if ok else State.FAILED
	var cp := carrier_player()
	if cp != null: cp.carry_slow = 1.0
	finished.emit(self, ok)
	_vanish()

func _vanish() -> void:
	var parent := get_parent()
	var at := body if kind != "ritual" else a
	if parent != null:
		VoxelFx.puff(parent, at + Vector3(0, 0.6, 0), "sparkle" if state == State.DONE else "pet_mist", 0.9,
			Color(0.62, 0.58, 0.72))
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.6).set_delay(0.5)
	if _ring_b != null: tw.parallel().tween_property(_ring_b, "scale", Vector3.ONE * 0.01, 0.6).set_delay(0.5)
	if _beam != null: tw.parallel().tween_property(_beam, "scale", Vector3(0.01, 1.0, 0.01), 0.6).set_delay(0.5)
	for n in _stall_rings + _stall_labels: tw.parallel().tween_property(n, "scale", Vector3.ONE * 0.01, 0.6).set_delay(0.5)
	tw.tween_callback(queue_free)

# ---------------------------------------------------------------- dibujo

func _process(delta: float) -> void:
	_anim_t += delta
	var pulse := 0.75 + 0.25 * sin(_anim_t * 3.0)
	if _ring_a != null:
		_ring_a.material_override.set_shader_parameter("progress", clampf(progress / maxf(need, 0.01), 0.0, 1.0))
		_ring_a.material_override.set_shader_parameter("pulse", pulse)
	if _ring_b != null: _ring_b.material_override.set_shader_parameter("pulse", pulse)
	if _light != null: _light.light_energy = 0.9 + 0.5 * pulse
	# el carrier aplica la lentitud en su PC (también en red: cada PC mueve a los suyos)
	if kind == "relic" and not is_over():
		var cp := carrier_player()
		if world != null:
			for p in world.players:
				if p == cp: p.carry_slow = CARRY_SLOW
				elif p.carry_slow != 1.0 and _carried_by_none_else(p): p.carry_slow = 1.0
	if kind == "ritual" and not is_over() and state == State.ACTIVE:
		_chant_t -= delta
		if _chant_t <= 0.0:
			_chant_t = 6.0
			Auto.sfx_at("chant", a)
	if kind == "peddler" and not is_over(): _peddler_step(delta)
	if is_over(): return
	match kind:
		"rescue":
			global_position = body
			if _model != null:
				var anim := "down_wait"
				var tt := fposmod(_anim_t / Anims.duration(model_name, anim), 1.0)
				if state == State.ACTIVE:
					if _rise_t >= 0.0 and _rise_t < 0.75:
						_rise_t += delta
						anim = "get_up"
						tt = clampf(_rise_t / 0.75, 0.0, 1.0)
					else:
						var moving := _flat(_net_body if mirror else body).distance_to(_flat(_last_body)) > 0.001
						anim = "walk" if moving else "idle"
						tt = fposmod(_anim_t / Anims.duration(model_name, anim), 1.0)
						var cp := _nearest_standing()
						if cp != null:
							var to := cp.global_position - body
							if to.length() > 0.2: _model.rotation.y = lerp_angle(_model.rotation.y, atan2(to.x, to.z), 1.0 - exp(-8.0 * delta))
				Anims.reset(_model)
				Anims.pose(model_name, anim, _model, tt)
			_last_body = body
		"relic":
			var cp := carrier_player()
			if cp != null:                                         # flota sobre la cabeza de quien la lleva
				global_position = cp.get_global_transform_interpolated().origin + Vector3(0, 2.3 + 0.06 * sin(_anim_t * 3.0), 0)
				_relic.rotation.y += delta * 1.5
				_relic.scale = Vector3.ONE * 0.8
			else:
				global_position = body + Vector3(0, 0.15 + 0.08 * sin(_anim_t * 2.5), 0)
				_relic.rotation.y += delta * 0.8
				_relic.scale = Vector3.ONE

var _last_body := Vector3.ZERO

## Buhonero, en cada PC: la pose de reposo, los precios (en rojo si no llegan) y las compras de
## los jugadores de este PC que se quedan encima de una mercancía.
func _peddler_step(delta: float) -> void:
	if _model != null:
		Anims.reset(_model)
		Anims.pose(model_name, "idle", _model, fposmod(_anim_t / Anims.duration(model_name, "idle"), 1.0))
	var purse: int = purse_hook.call() if purse_hook.is_valid() else 0
	for i in _stalls.size():
		var g: Dictionary = goods[i]
		var price := price_of(g)
		var fill := 0.0
		if world != null:
			for p in world.players:
				if p.remote or p.health <= 0.0: continue
				var key := "%d:%d" % [p.index, i]
				var on := _flat(p.global_position).distance_to(_flat(_stalls[i])) <= STALL_R + 0.15
				if not on or bought.has("%d:%s" % [p.index, g.id]):
					_hold.erase(key)
					continue
				_hold[key] = float(_hold.get(key, 0.0)) + delta
				fill = maxf(fill, _hold[key] / HOLD)
				if _hold[key] >= HOLD:
					_hold[key] = -9999.0                       # una vez por visita
					if buy_hook.is_valid() and buy_hook.call(p, g, price):
						bought["%d:%s" % [p.index, g.id]] = true
						VoxelFx.puff(get_parent(), _stalls[i] + Vector3(0, 0.5, 0), "sparkle", 0.6)
		_stall_rings[i].material_override.set_shader_parameter("progress", clampf(fill, 0.0, 1.0))
		var all_bought := world != null and world.players.all(func(p: Player) -> bool:
			return p.remote or bought.has("%d:%s" % [p.index, g.id]))
		var l := _stall_labels[i]
		l.text = "%s\n%s" % [g.get("name", ""), "Vendido" if all_bought else "%d $" % price]
		l.modulate = Color(0.7, 0.7, 0.7) if all_bought else (Color(1.0, 0.86, 0.45) if purse >= price else Color(1.0, 0.58, 0.52))

func _nearest_standing() -> Player:
	if world == null: return null
	var best: Player = null
	for p in world.players:
		if p.health <= 0.0: continue
		if best == null or p.global_position.distance_to(body) < best.global_position.distance_to(body): best = p
	return best

## Un jugador que no lleva esta reliquia vuelve a su velocidad (si no lleva otra).
func _carried_by_none_else(p: Player) -> bool:
	for o in get_tree().get_nodes_in_group(&"objectives"):
		if o != self and o is Objective and (o as Objective).carrier == p.index and not (o as Objective).is_over(): return false
	return true

## Texto del HUD.
func hud_text() -> String:
	match kind:
		"rescue":
			if state == State.WAIT: return "Rescata al superviviente herido"
			return "Escolta al superviviente hasta la bengala"
		"ritual":
			return "Corta el ritual: quédate dentro del círculo · %d/%d s" % [floori(progress), roundi(need)]
		"relic":
			if carrier < 0: return "Recoge la reliquia"
			return "Lleva la reliquia al círculo (J%d la lleva, va más lento)" % (carrier + 1)
		"peddler":
			var purse: int = purse_hook.call() if purse_hook.is_valid() else 0
			return "El buhonero: quédate sobre lo que quieras comprar · tienes %d $" % purse
	return ""

static func reward_text(r: Array) -> String:
	match String(r[0]):
		"money": return "%d $" % int(r[1])
		"chest": return "un baúl arcano"
		"xp": return "experiencia"
	return ""
