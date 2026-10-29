class_name ObjectiveDirector
extends Node
## Objetivos a mitad de nivel (hito 13.5, fase 13): de vez en cuando aparece uno opcional
## (`Objective`: rescatar, cortar un ritual o llevar una reliquia), con su recompensa (dólares,
## un baúl o experiencia) y su tiempo; uno o dos por nivel, antes del evento final. Datos en
## `data/objectives.json`. En red los saca el anfitrión (llegan a los invitados por `NetGame`,
## que llama a `adopt`); los dólares se cuentan en cada PC, el baúl y las gemas los suelta el
## anfitrión. Muestra el objetivo en curso arriba (texto, tiempo y avance) y una flecha hacia
## donde hay que ir. `objectives=false` los quita; `objective=rescate|ritual|reliquia` y
## `objective_at=t` sacan ese a los t s (capturas y pruebas).

const DATA := "res://data/objectives.json"
const KINDS := {"rescate": "rescue", "ritual": "ritual", "reliquia": "relic"}

var game: Node
var cfg := {}
var current: Objective
var done := 0                                  ## cumplidos en este nivel
var failed := 0
var _times: Array[float] = []                  ## a qué s del nivel sale cada uno
var _forced := ""
var _rng := RandomNumberGenerator.new()
var _layer: CanvasLayer
var _hud: ObjectiveHud

func setup(p_game: Node) -> ObjectiveDirector:
	game = p_game
	name = "Objectives"
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	cfg = d if d is Dictionary else {}
	_rng.randomize()
	var args = game.get("args")
	var level: LevelData = game.get("level")
	if args != null and args.has("objective"):
		_forced = KINDS.get(args.get_str("objective", ""), "rescue")
		_times = [args.get_float("objective_at", 5.0)]
	elif level != null and not game.is_guest():
		_times = plan(cfg, level.final_time, _rng)
	return self

## Cuándo sale cada objetivo del nivel: uno o dos (`per_level`), el primero en `first`, los
## siguientes `gap` después, y ninguno a menos de `before_final` s del evento final. Pura (tests).
static func plan(c: Dictionary, final_time: float, rng: RandomNumberGenerator) -> Array[float]:
	var out: Array[float] = []
	var per: Array = c.get("per_level", [1, 2])
	var n := rng.randi_range(int(per[0]), int(per[1]))
	var first: Array = c.get("first", [50.0, 90.0])
	var gap: Array = c.get("gap", [70.0, 110.0])
	var last := final_time - float(c.get("before_final", 40.0))
	var at := rng.randf_range(float(first[0]), float(first[1]))
	for i in n:
		if at > last: break
		out.append(at)
		at += rng.randf_range(float(gap[0]), float(gap[1]))
	return out

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 6                               # encima del HUD (5)
	add_child(_layer)
	_hud = ObjectiveHud.new()
	_hud.director = self
	_layer.add_child(_hud)

func _physics_process(_delta: float) -> void:
	var dir: WaveDirector = game.get("director")
	if dir == null or dir.mirror or game.is_guest(): return
	if current != null or _times.is_empty() or dir.completed: return
	if dir.time < _times[0]: return
	_times.remove_at(0)
	var o := make(_forced if _forced != "" else _pick_kind())
	if o != null: _start(o)

func _pick_kind() -> String:
	var w: Dictionary = cfg.get("weights", {"rescue": 1, "ritual": 1, "relic": 1})
	var total := 0.0
	for k in w: total += float(w[k])
	var r := _rng.randf() * total
	for k in w:
		r -= float(w[k])
		if r <= 0.0: return k
	return "rescue"

## Crea un objetivo del tipo dado, con sus puntos libres y su recompensa (null si no hay sitio).
func make(kind: String) -> Objective:
	var dir: WaveDirector = game.get("director")
	var world: CombatWorld = game.get("world")
	var kc: Dictionary = (cfg.get("kinds", {}) as Dictionary).get(kind, {})
	var standing := world.players.filter(func(p: Player) -> bool: return p.health > 0.0)
	if standing.is_empty(): return null
	var who: Player = standing[_rng.randi() % standing.size()]
	var dist: Array = kc.get("distance", [8.0, 13.0])
	if game.args.get_bool("objective_near"): dist = [0.3, 0.6]       # capturas: a sus pies
	var a := _free_point(dir, who.global_position, float(dist[0]), float(dist[1]), 1.5)
	if a == Vector3.INF: return null
	var b := a
	if kind != "ritual":
		var gd: Array = kc.get("goal", [15.0, 22.0])
		b = _free_point(dir, a, float(gd[0]), float(gd[1]), 1.5)
		if b == Vector3.INF: return null
	var o := Objective.new().setup(kind, world, dir, a, b)
	o.limit = float(kc.get("limit", 90.0))
	o.need = float(kc.get("need", 12.0))
	o.radius = float(kc.get("radius", 2.6))
	o.drain = float(kc.get("drain", 14.0))
	o.guards = int(kc.get("guards", 4))
	o.reward = _pick_reward(kc.get("rewards", [{"money": [40, 60]}]))
	if kind == "rescue": o.model_name = _survivor_model(kc)
	return o

func _pick_reward(list: Array) -> Array:
	var r: Dictionary = list[_rng.randi() % list.size()]
	if r.has("money"): return ["money", _rng.randi_range(int(r.money[0]), int(r.money[1]))]
	if r.has("xp"): return ["xp", int(r.xp)]
	return ["chest", 1]

## Superviviente de la parte: de los de `survivors`, uno que no lleve nadie.
func _survivor_model(kc: Dictionary) -> String:
	var level: LevelData = game.get("level")
	var by_part: Dictionary = kc.get("survivors", {})
	var list: Array = by_part.get("p%d" % (level.part if level != null else 1), by_part.get("p1", ["habitante_viejo"]))
	var used := {}
	for p: Player in game.get("players"): used[p.data.model] = true
	var free := list.filter(func(m: Variant) -> bool: return not used.has(String(m)))
	if free.is_empty(): free = list
	return String(free[_rng.randi() % free.size()])

func _free_point(dir: WaveDirector, from: Vector3, rmin: float, rmax: float, rad: float) -> Vector3:
	var obs: ObstacleMap = dir.obstacles if dir != null else null
	for i in 40:
		var ang := _rng.randf() * TAU
		var c := from + Vector3(cos(ang), 0, sin(ang)) * _rng.randf_range(rmin, rmax)
		var p := Vector2(c.x, c.z)
		if obs != null and not obs.bounds.grow(-3.0).has_point(p): continue
		if dir != null and not dir._spawnable(p, rad): continue
		if obs != null and obs.has_water() and obs.water_at(p) > 0.2: continue   # no en una poza
		return Vector3(c.x, 0, c.z)
	return Vector3.INF

func _start(o: Objective) -> void:
	var world: CombatWorld = game.get("world")
	world.fx.add_child(o)
	adopt(o)
	if o.kind == "ritual": o._spawn_guards(o.guards)
	if game.args.get_bool("log"): print("OBJETIVO en %s meta %s jugador %s" % [o.a, o.b, (game.player as Player).global_position])

## Un objetivo nuevo (en el anfitrión, el que acaba de salir; en el invitado, el que llega).
func adopt(o: Objective) -> void:
	current = o
	o.finished.connect(_on_finished)
	_hud.show_objective(o)
	game.announce("Objetivo: %s (recompensa: %s)" % [_title(o.kind), Objective.reward_text(o.reward)], 3.0)
	Auto.sfx("page")
	if game.args.get_bool("log"): print("OBJETIVO %s t=%.0f recompensa=%s" % [o.kind, (game.director as WaveDirector).time, o.reward])

func _title(kind: String) -> String:
	return {"rescue": "rescata al superviviente", "ritual": "corta el ritual", "relic": "lleva la reliquia"}.get(kind, kind)

func _on_finished(o: Objective, ok: bool) -> void:
	if o == current: current = null
	_hud.show_objective(null)
	if game.args.get_bool("log"): print("OBJETIVO %s %s t=%.1f" % [o.kind, "cumplido" if ok else "fallido", o.t])
	if not ok:
		failed += 1
		game.announce("Objetivo fallido", 2.0)
		return
	done += 1
	game.announce("Objetivo cumplido: %s" % Objective.reward_text(o.reward), 2.5)
	Auto.sfx("level_up")
	var at := o.b if o.kind != "ritual" else o.a
	match String(o.reward[0]):
		"money": game.earn(int(o.reward[1]))                       # en cada PC, como los baúles
		"chest":
			if not game.is_guest():
				var dir: WaveDirector = game.get("director")
				var c := ArcaneChest.new().setup(dir.world, at, _rng.randi_range(dir.level.chest_money.x, dir.level.chest_money.y), dir.level.chest_heal)
				dir.world.fx.add_child(c)
				dir.chest_spawned.emit(c)
		"xp":
			if not game.is_guest():
				var gm: GemManager = game.get("gems")
				var total := int(o.reward[1])
				var n := clampi(total / 8, 3, 8)
				for i in n: gm.drop(at + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)), float(total) / n, 2)
	if Saves.current != null: Saves.current.stats["objectives"] = int(Saves.current.stats.get("objectives", 0)) + 1


## Arriba, bajo la cabecera: el objetivo en curso (texto, tiempo, avance) y una flecha hacia
## donde hay que ir si no se ve; si se ve, una marca que baja y sube encima.
class ObjectiveHud extends Control:
	var director: ObjectiveDirector
	var obj: Objective
	var _panel: PanelContainer
	var _text: Label
	var _bar: ProgressBar
	var _t := 0.0

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel = PanelContainer.new()
		_panel.theme = MenuKit.theme()
		var sb := MenuKit.box(Color(0.07, 0.05, 0.035, 0.85), Color(1.0, 0.78, 0.35), 2)
		sb.content_margin_left = 18; sb.content_margin_right = 18
		sb.content_margin_top = 6; sb.content_margin_bottom = 8
		_panel.add_theme_stylebox_override("panel", sb)
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		_panel.add_child(box)
		_text = UiKit.label("", 20, UiKit.TEXT)
		_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(_text)
		_bar = ProgressBar.new()
		_bar.show_percentage = false
		_bar.custom_minimum_size = Vector2(360, 8)
		_bar.max_value = 1.0
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.6)
		var fg := StyleBoxFlat.new()
		fg.bg_color = Color(1.0, 0.78, 0.35)
		_bar.add_theme_stylebox_override("background", bg)
		_bar.add_theme_stylebox_override("fill", fg)
		box.add_child(_bar)
		_panel.visible = false
		add_child(_panel)

	func show_objective(o: Objective) -> void:
		obj = o
		_panel.visible = o != null
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		if obj == null or not is_instance_valid(obj):
			if _panel.visible: show_objective(null)
			return
		var secs := ceili(obj.left())
		_text.text = "%s · %d:%02d" % [obj.hud_text(), secs / 60, secs % 60]
		match obj.kind:
			"ritual": _bar.value = clampf(obj.progress / maxf(obj.need, 0.01), 0.0, 1.0)
			"rescue": _bar.value = obj.progress                          # vida del superviviente
			_: _bar.value = obj.left() / maxf(obj.limit, 1.0)
		(_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = Color(0.9, 0.3, 0.25) if obj.kind == "rescue" else Color(1.0, 0.78, 0.35)
		var view := get_viewport_rect().size
		_panel.position = Vector2((view.x - _panel.size.x) * 0.5, 196.0)    # bajo los avisos de la partida
		queue_redraw()

	func _draw() -> void:
		if obj == null or not is_instance_valid(obj) or obj.is_over(): return
		var cam := get_viewport().get_camera_3d()
		if cam == null: return
		var view := get_viewport_rect().size
		var w := obj.target() + Vector3(0, 1.0, 0)
		if cam.is_position_behind(w): return
		var p := cam.unproject_position(w)
		var col := Color(1.0, 0.8, 0.35)
		var at: Variant = OffscreenArrows.place(p, view)
		if at == null:                                   # se ve: un rombo que baja y sube encima
			var c := cam.unproject_position(obj.target() + Vector3(0, 1.5, 0)) + Vector2(0, 6.0 * sin(_t * 4.0))
			var pts := PackedVector2Array([c + Vector2(0, 21), c + Vector2(-13, 0), c + Vector2(0, -12), c + Vector2(13, 0)])
			draw_colored_polygon(pts, Color(0, 0, 0, 0.6))
			draw_colored_polygon(PackedVector2Array([pts[0] + Vector2(0, -3), pts[1] + Vector2(3, 0), pts[2] + Vector2(0, 3), pts[3] + Vector2(-3, 0)]), col)
			return
		var pos: Vector2 = at[0]
		var dir: Vector2 = at[1]
		var side := Vector2(-dir.y, dir.x)
		var s := 26.0
		var tip := pos + dir * s * 0.7
		var back := pos - dir * s * 0.3
		var pts2 := PackedVector2Array([tip, back + side * s * 0.35, pos - dir * s * 0.1, back - side * s * 0.35])
		var shade := PackedVector2Array()
		for v in pts2: shade.append(v + (v - pos).normalized() * 3.0)
		draw_colored_polygon(shade, Color(0, 0, 0, 0.7))
		col.a = 0.7 + 0.3 * absf(sin(_t * 3.0))
		draw_colored_polygon(pts2, col)
