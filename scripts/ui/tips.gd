class_name Tips
extends CanvasLayer
## Consejos de la primera partida y leyenda de los avisos (hito 13.3, fase 13). Un cartel abajo,
## en el centro, cuando pasa algo por primera vez (moverse, esquivar, la primera gema, la primera
## subida, la cordura baja, el primer baúl, la primera élite, el enemigo final, un compañero
## caído, la pausa, la ficha); y, junto al primer aviso en el suelo de cada tipo (golpe, cordura,
## los dos, algo que va a salir, grieta), una etiqueta corta. Cada uno, una vez por hueco
## (`SaveData.seen["tips"]`). Textos en `data/tutorial.json`. Configuración > Juego > «Consejos»
## los quita y «Volver a ver los consejos» los repone. Sin hueco o con bots, no sale nada; para
## capturas, `tips=true` los saca igual (lo visto, solo en memoria).

const DATA := "res://data/tutorial.json"
const GAP := 1.2                              ## s entre un cartel y el siguiente
const POLL := 0.25

var game: Node
var _tips: Array = []
var _warnings := {}
var _queue: Array[String] = []
var _seen_mem := {}                           ## sin hueco (tips=true): lo visto en esta partida
var _forced := false
var _banner: PanelContainer
var _text: Label
var _busy := 0.0                              ## s que le quedan al cartel que se ve
var _poll := 0.0
var _chest := false
var _final := false
var _labels: Array = []                       ## [Control, Telegraph, Vector3, s que le quedan]
var _legend_root: Control

func _init(p_game: Node) -> void:
	game = p_game
	layer = 11                                 # encima del HUD (5), debajo de la ficha (12) y los menús
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	if d is Dictionary:
		_tips = d.get("tips", [])
		_warnings = d.get("warnings", {})

func _ready() -> void:
	var a = game.get("args")
	_forced = a != null and a.get_bool("tips")
	_legend_root = Control.new()
	_legend_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_legend_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_legend_root)
	_banner = PanelContainer.new()
	_banner.theme = MenuKit.theme()
	var sb := MenuKit.box(Color(0.07, 0.05, 0.035, 0.92), MenuKit.BRASS, 2)
	sb.content_margin_left = 26; sb.content_margin_right = 26
	sb.content_margin_top = 12; sb.content_margin_bottom = 14
	_banner.add_theme_stylebox_override("panel", sb)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_banner.add_child(box)
	var head := UiKit.label("Consejo", 16, MenuKit.BRASS)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	_text = UiKit.label("", 23, UiKit.TEXT)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 760
	box.add_child(_text)
	_banner.modulate.a = 0.0
	add_child(_banner)
	_banner.resized.connect(_place)
	var dir: WaveDirector = game.get("director")
	if dir != null:
		dir.chest_spawned.connect(func(_c: ArcaneChest) -> void: _chest = true)
		dir.final_event.connect(func(_e: Enemy) -> void: _final = true)
	Telegraph.on_shown = _on_telegraph

func _exit_tree() -> void:
	if Telegraph.on_shown == Callable(self, "_on_telegraph"): Telegraph.on_shown = Callable()

func _place() -> void:
	var view := get_viewport().get_visible_rect().size
	_banner.position = Vector2((view.x - _banner.size.x) * 0.5, view.y - _banner.size.y - 150.0)

## ¿Salen consejos en esta partida?
func active() -> bool:
	if _forced: return true
	if not bool(Auto.setting("tips", true)) or Saves.current == null: return false
	var p: Player = game.get("player")
	return p != null and not (p.input is BotInput)

func seen(id: String) -> bool:
	if _forced and Saves.current == null: return _seen_mem.has(id)
	return Saves.current != null and Saves.current.has_seen("tips", id)

func _mark(id: String) -> void:
	if _forced and Saves.current == null:
		_seen_mem[id] = true
		return
	if Saves.current != null: Saves.current.mark_seen("tips", id)

func _process(delta: float) -> void:
	_legend_step(delta)
	if not active(): return
	if _busy > 0.0:
		_busy -= delta
		if _busy <= 0.0:
			create_tween().tween_property(_banner, "modulate:a", 0.0, 0.5)
			_busy = -GAP                                     # hueco antes del siguiente
		return
	if _busy < 0.0:
		_busy = minf(_busy + delta, 0.0)
		return
	_poll -= delta
	if _poll > 0.0: return
	_poll = POLL
	for t: Dictionary in _tips:
		var id := String(t.id)
		if seen(id) or _queue.has(id): continue
		if _happened(t): _queue.append(id)
	if not _queue.is_empty(): _show(_queue.pop_front())

## Lo que dispara cada consejo.
func _happened(t: Dictionary) -> bool:
	var dir: WaveDirector = game.get("director")
	var time := dir.time if dir != null else 0.0
	var players: Array = game.get("players") if game.get("players") != null else []
	match String(t.when):
		"move", "dodge", "pause", "sheet": return time >= float(t.get("at", 0.0))
		"gem":
			var gems = game.get("gems")
			return gems != null and gems.count > 0 and time >= 3.0
		"levelup":
			var p: Player = game.get("player")
			return p != null and p.progress.level >= 2
		"sanity":
			for q: Player in players:
				if not q.remote and q.sanity < q.data.max_sanity * 0.7: return true
		"chest": return _chest
		"final": return _final
		"elite":
			if dir != null:
				for e in dir.alive:
					if is_instance_valid(e) and e.data.elite: return true
		"down":
			if players.size() > 1:
				for q: Player in players:
					if q.is_downed(): return true
	return false

func _show(id: String) -> void:
	for t: Dictionary in _tips:
		if String(t.id) != id: continue
		_mark(id)
		print("CONSEJO %s t=%.1f" % [id, (game.get("director") as WaveDirector).time if game.get("director") != null else 0.0])
		_text.text = String(t.text)
		_busy = 4.0 + _text.text.length() / 22.0
		_place.call_deferred()
		create_tween().tween_property(_banner, "modulate:a", 1.0, 0.35)
		Auto.sfx("page")
		return

# ---------------------------------------------------------------- leyenda de los avisos

## Tipo de aviso para la leyenda ("" si no lleva: los de las armas y los compañeros).
static func warning_kind(t: Telegraph) -> String:
	if t.legend != &"": return String(t.legend)
	if not t.net and not t.mirrored: return ""
	if not t.fill: return "aparece"
	var c := Vector3(t.color.r, t.color.g, t.color.b)
	var best := ""
	var dist := INF
	for k in [["fisico", Damage.COLOR_PHYSICAL], ["mental", Damage.COLOR_MENTAL],
			["mixto", Damage.COLOR_PHYSICAL.lerp(Damage.COLOR_MENTAL, 0.5)]]:
		var kc: Color = k[1]
		var dd := c.distance_to(Vector3(kc.r, kc.g, kc.b))
		if dd < dist:
			dist = dd
			best = k[0]
	return best

func _on_telegraph(t: Telegraph) -> void:
	if not active(): return
	var kind := warning_kind(t)
	if kind == "" or not _warnings.has(kind): return
	var id := "aviso_" + kind
	if seen(id): return
	_mark(id)
	print("CONSEJO %s" % id)
	var box := PanelContainer.new()
	var sb := MenuKit.box(Color(0.05, 0.04, 0.03, 0.85), Color(t.color.r, t.color.g, t.color.b), 2)
	sb.content_margin_left = 12; sb.content_margin_right = 12
	sb.content_margin_top = 4; sb.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", sb)
	box.theme = MenuKit.theme()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(UiKit.label(String(_warnings[kind]), 20, UiKit.TEXT))
	box.modulate.a = 0.0
	_legend_root.add_child(box)
	create_tween().tween_property(box, "modulate:a", 1.0, 0.2)
	_labels.append([box, t, t.global_position, maxf(t.duration, 2.5) + 0.8, t.radius])

func _legend_step(delta: float) -> void:
	if _labels.is_empty(): return
	var cam := get_viewport().get_camera_3d()
	for i in range(_labels.size() - 1, -1, -1):
		var l: Array = _labels[i]
		var box: Control = l[0]
		if is_instance_valid(l[1]): l[2] = (l[1] as Telegraph).global_position
		l[3] = float(l[3]) - delta
		if float(l[3]) <= 0.0:
			_labels.remove_at(i)
			var tw := box.create_tween()
			tw.tween_property(box, "modulate:a", 0.0, 0.4)
			tw.tween_callback(box.queue_free)
			continue
		if cam != null:                            # debajo del círculo: centrado y bajo su punto más bajo en pantalla
			var c: Vector3 = l[2]
			var p := cam.unproject_position(c)
			var low := p.y
			for k in 8:
				var a := TAU * k / 8.0
				low = maxf(low, cam.unproject_position(c + Vector3(cos(a), 0, sin(a)) * float(l[4])).y)
			box.position = Vector2(p.x - box.size.x * 0.5, low + 6.0)
