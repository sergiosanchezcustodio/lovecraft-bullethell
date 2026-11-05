class_name ExpeditionMap
extends Control
## Mapa de la expedición (hito 16.21, `Expedition`): las filas de izquierda a derecha, con los
## caminos dibujados entre los nodos; solo se puede ir a los que salen del último visitado. Los
## combates, las élites, el buhonero y el jefe son niveles (pasa a la partida por el relato, que
## no tiene texto para ellos); la curiosidad abre su suceso y el descanso se aplica aquí mismo.
## B o Esc: abandonar la expedición (con confirmación). Capturas:
## `godot --path . scenes/expedition_map.tscn -- exp_part=0 exp_seed=7 exp_row=2 shots=2 tag=x`.

const W := 1500.0
const H := 470.0
const NODE := Vector2(148, 58)
const COLORS := {"combate": Color(0.80, 0.70, 0.52), "elite": Color(0.92, 0.42, 0.30), "buhonero": Color(0.86, 0.70, 0.30),
	"curiosidad": Color(0.58, 0.72, 0.95), "descanso": Color(0.55, 0.85, 0.55), "jefe": Color(0.95, 0.35, 0.45)}

var _area: Control
var _buttons := {}                     ## Vector2i(fila, col) -> botón
var _info_title: Label
var _info: Label
var _purse: Label
var _box: VBoxContainer
var _popup: Control
var _shots: Array[float] = []
var _tag := "expedicion"
var _t := 0.0
var _auto := false                     ## pruebas (`exp_auto=true`): elige solo el primer camino y la primera opción
static var _test_started := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var la := LaunchArgs.from_cmdline()
	if not Expedition.active() or (la.has("exp_part") and not _test_started):   # pruebas: el mapa suelto
		_test_started = true
		Expedition.start(la.get_int("exp_part", 0), la.get_int("exp_seed", 7))
		for r in la.get_int("exp_row", 0):                     # como si ya hubiera recorrido esas filas
			var ch := Expedition.choices()
			Expedition.enter(ch[0][0], ch[0][1])
	for s in la.get_str("shots").split(",", false): _shots.append(float(s))
	_tag = la.get_str("tag", _tag)
	_auto = la.get_bool("exp_auto")
	if get_window().size.x < 640: get_window().size = Vector2i(1920, 1080)   # el mapa suelto en las pruebas (ventana de 3×3 px)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build()

func _build() -> void:
	for c in get_children(): if c is not ColorRect: c.queue_free()
	_buttons.clear()
	var st := Expedition.state()
	var part: Dictionary = Campaign.parts()[int(st.part)]
	var w: Array = MenuKit.window(self, Color(0.42, 0.34, 0.18), 1640)
	_box = w[1]
	MenuKit.heading(_box, "Expedición · %s" % String(part.title), 42, UiKit.GOLD)
	_purse = UiKit.label(_purse_text(), 20, UiKit.TEXT_DIM)
	_purse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_purse)
	_area = Control.new()
	_area.custom_minimum_size = Vector2(W, H)
	_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER   # de su ancho y centrada: estirada, los nudos (que van por W) quedaban a la izquierda
	_area.draw.connect(_draw_paths)
	_box.add_child(_area)
	var rows: Array = st.rows
	var open := Expedition.choices()
	var first: Button = null
	for r in rows.size():
		var row: Array = rows[r]
		for c in row.size():
			var n: Dictionary = row[c]
			var kind := String(n.kind)
			var done := (st.done as Array).any(func(x: Array) -> bool: return int(x[0]) == r and int(x[1]) == c)
			var here := open.any(func(x: Array) -> bool: return int(x[0]) == r and int(x[1]) == c)
			var b := MenuKit.button(("✓ " if done else "") + String(Expedition.NAMES.get(kind, kind)), COLORS.get(kind, MenuKit.INK), 17)
			b.custom_minimum_size = NODE
			b.size = NODE
			b.position = _pos(r, c, row.size()) - NODE * 0.5
			b.disabled = not here
			if not here and not done: b.modulate = Color(1, 1, 1, 0.55)
			b.focus_entered.connect(_describe.bind(r, c))
			b.pressed.connect(_go.bind(r, c))
			_area.add_child(b)
			_buttons[Vector2i(r, c)] = b
			if here and first == null: first = b
	_info_title = MenuKit.title("", 26)
	_box.add_child(_info_title)
	_info = UiKit.label("", 20, UiKit.TEXT)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(1400, 56)
	_box.add_child(_info)
	_box.add_child(MenuKit.hint("Arriba/abajo: elegir camino  ·  A o Intro: ir  ·  B o Esc: abandonar la expedición"))
	var ch := open.map(func(x: Array) -> Button: return _buttons[Vector2i(int(x[0]), int(x[1]))])
	for i in ch.size():                                # arriba y abajo, entre los caminos abiertos
		var b: Button = ch[i]
		b.focus_neighbor_top = b.get_path_to(ch[(i - 1 + ch.size()) % ch.size()])
		b.focus_neighbor_bottom = b.get_path_to(ch[(i + 1) % ch.size()])
		b.focus_neighbor_left = b.get_path()
		b.focus_neighbor_right = b.get_path()
	if first != null: first.grab_focus.call_deferred()
	_area.queue_redraw()

func _pos(r: int, c: int, n: int) -> Vector2:
	var rows := (Expedition.state().rows as Array).size()
	var x := 110.0 + (W - 220.0) * float(r) / float(maxi(rows - 1, 1))
	var y := H * 0.5 + (float(c) - float(n - 1) * 0.5) * 128.0
	y += (sin(float(r * 3 + c) * 1.7)) * 14.0            # algo de desorden, como un mapa a mano
	return Vector2(x, y)

func _draw_paths() -> void:
	var st := Expedition.state()
	var rows: Array = st.rows
	for r in rows.size() - 1:
		for c in (rows[r] as Array).size():
			var a := _pos(r, c, (rows[r] as Array).size())
			for j: int in rows[r][c].links:
				var b := _pos(r + 1, j, (rows[r + 1] as Array).size())
				var walked := (st.done as Array).any(func(x: Array) -> bool: return int(x[0]) == r and int(x[1]) == c) \
					and (st.done as Array).any(func(x: Array) -> bool: return int(x[0]) == r + 1 and int(x[1]) == j)
				var col := Color(0.95, 0.78, 0.40, 0.95) if walked else Color(0.62, 0.52, 0.36, 0.45)
				var from := a + Vector2(NODE.x * 0.5, 0)
				var to := b - Vector2(NODE.x * 0.5, 0)
				var steps := 14                             # a trazos, como en los mapas viejos
				for k in steps:
					if k % 2 == 1: continue
					_area.draw_line(from.lerp(to, float(k) / steps), from.lerp(to, float(k + 1) / steps), col, 3.0 if walked else 2.0, true)

func _purse_text() -> String:
	var st := Expedition.state()
	var parts := PackedStringArray(["Bolsa de la expedición: %d $" % int(st.money)])
	if int(st.bonus) > 0: parts.append(MenuKit.count(int(st.bonus), "subida") + " al empezar el siguiente nivel")
	if float(st.hurt) < 0.999: parts.append("el siguiente nivel, con un %d %% menos de vida" % roundi((1.0 - float(st.hurt)) * 100.0))
	if float(st.time) > 0.0: parts.append("tiempo: %s" % Endless.clock(float(st.time)))
	return "  ·  ".join(parts)

func _describe(r: int, c: int) -> void:
	var n := Expedition.node_at(r, c)
	var kind := String(n.kind)
	_info_title.text = String(Expedition.NAMES.get(kind, kind))
	var where := ""
	for l: Dictionary in Campaign.levels(): if String(l.id) == String(n.base): where = String(l.name)
	_info.text = String(Expedition.INFO.get(kind, "")) + ("" if kind in ["curiosidad", "descanso"] else "  " + where + ".")

func _go(r: int, c: int) -> void:
	var id := Expedition.enter(r, c)
	var kind := String(Expedition.node_at(r, c).kind)
	if id != "":
		GameSession.level = StringName(id)
		LevelCard.leave(self, func() -> void: get_tree().change_scene_to_file("res://scenes/relato.tscn"))
		return
	if kind == "descanso":
		Expedition.rest()
		_message("Descanso", "Hogueras, café y un rato sin mirar atrás. Al empezar el siguiente nivel, %s." % MenuKit.count(int(Expedition.cfg().get("rest_bonus", 2)), "subida"))
	else:
		_curiosity(r)

func _message(title: String, text: String) -> void:
	_popup_open(title, text, [{"label": "Seguir"}], func(_o: Dictionary) -> void: pass)

func _curiosity(r: int) -> void:
	var ev := Expedition.curiosity(r)
	_popup_open(String(ev.get("title", "Curiosidad")), String(ev.get("text", "")), ev.get("options", [{"label": "Seguir"}]),
		func(o: Dictionary) -> void: Expedition.choose(o))

func _popup_open(title: String, text: String, options: Array, on_pick: Callable) -> void:
	_popup = Control.new()
	_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_popup)
	var w: Array = MenuKit.window(_popup, Color(0.30, 0.36, 0.55), 1100)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, title, 38, Color(0.75, 0.85, 1.0))
	var t := UiKit.label(text, 21, UiKit.TEXT)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.custom_minimum_size.x = 960
	box.add_child(t)
	var first: Button = null
	for o: Dictionary in options:
		var b := MenuKit.button(String(o.get("label", "Seguir")), MenuKit.INK, 20)
		b.custom_minimum_size = Vector2(960, 56)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = not Expedition.can_choose(o)
		b.pressed.connect(func() -> void:
			on_pick.call(o)
			_popup.queue_free()
			_popup = null
			_build())
		box.add_child(b)
		if first == null and not b.disabled: first = b
	if first != null: first.grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if _popup != null or not event.is_action_pressed("ui_cancel"): return
	get_viewport().set_input_as_handled()
	var c := MenuKit.Confirm.new("¿Abandonar la expedición? Lo ganado en ella se pierde.", "Abandonar")
	add_child(c)
	c.answered.connect(func(yes: bool) -> void:
		if not yes: return
		GameSession.expedition = {}
		GameSession.carry.clear()
		TitleScreen.skip_to_menu = Saves.slot >= 0
		get_tree().change_scene_to_file("res://scenes/title.tscn"))

func _process(delta: float) -> void:
	_t += delta
	if _auto and _t > 1.0 and fmod(_t, 1.0) < delta:        # pruebas: cada segundo, lo primero que haya
		var f := get_viewport().gui_get_focus_owner()
		if f is Button and not (f as Button).disabled:
			print("EXPEDICION elige ", (f as Button).text)
			(f as Button).pressed.emit()
	if not _shots.is_empty() and _t >= _shots[0]:
		_shots.pop_front()
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://shots/expedicion_%s_%05.1fs.png" % [_tag, _t])
		print("captura: expedicion_%s" % _tag)
		if _shots.is_empty(): get_tree().quit()
