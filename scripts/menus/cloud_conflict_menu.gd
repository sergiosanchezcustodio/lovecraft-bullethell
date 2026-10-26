class_name CloudConflictMenu
extends Control
## Conflicto de un hueco (hito 10.3): se jugó en este PC y en otro sin pasar por la nube. Enseña
## las dos partidas lado a lado y el jugador elige con cuál se queda (con confirmación: la otra se
## pierde). B / Esc lo deja para luego: el conflicto sigue apuntado y vuelve a salir en los huecos.

signal done(resolved: bool)

var slot := 0
var _status: Label
var _cards: Array[Button] = []
var _busy := false

## Enseña uno tras otro los conflictos pendientes. Termina cuando no quedan o el jugador deja
## alguno para luego.
static func resolve_all(parent: Node) -> void:
	var seen := {}
	while not Cloud.conflicts.is_empty() and parent.is_inside_tree():
		var c: Dictionary = Cloud.conflicts[0]
		if seen.has(c.slot): return
		seen[c.slot] = true
		var m := CloudConflictMenu.new()
		m.slot = c.slot
		parent.add_child(m)
		if not await m.done: return

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var c := Cloud.conflict_of(slot)
	var w: Array = MenuKit.window(self, MenuKit.DANGER, 1100)
	var box: VBoxContainer = w[1]
	box.add_child(MenuKit.title("La Partida %d ha cambiado en dos sitios" % (slot + 1), 42))
	var l := UiKit.label("Se ha jugado en este PC y en otro sin pasar por la nube. Elige con cuál te quedas: la otra se perderá.", 20, UiKit.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 1000
	box.add_child(l)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	box.add_child(row)
	var local: SaveData = c.get("local")
	var cloud: SaveData = c.get("cloud")
	for k in 2:
		var d := local if k == 0 else cloud
		var card := _card("Este PC" if k == 0 else "La nube", d, cloud if k == 0 else local)
		card.pressed.connect(_choose.bind(k == 1))
		row.add_child(card)
		_cards.append(card)
	for b in _cards:
		var other := _cards[1] if b == _cards[0] else _cards[0]
		b.focus_neighbor_left = b.get_path_to(other)
		b.focus_neighbor_right = b.get_path_to(other)
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(b)
	_status = UiKit.label("", 18, UiKit.TEXT_DIM)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	box.add_child(MenuKit.hint("Izquierda/derecha: elegir  ·  A o Intro: quedarse con esa  ·  B o Esc: decidir luego"))
	MenuKit.trap_focus(self)
	_cards[0].grab_focus.call_deferred()

## Tarjeta de una de las dos partidas; lo que tiene de más que la otra va en dorado.
func _card(head: String, d: SaveData, other: SaveData) -> Button:
	var b := MenuKit.button("", MenuKit.INK, 24)
	b.custom_minimum_size = Vector2(480, 330)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 24; v.offset_right = -24; v.offset_top = 18; v.offset_bottom = -18
	v.add_theme_constant_override("separation", 8)
	b.add_child(v)
	v.add_child(MenuKit.title(head, 34))
	var who := "en este PC" if d.device == "" or d.device == Cloud.device_name else "en %s" % d.device
	var when := UiKit.label("Guardada el %s %s" % [Cloud.when(d.updated), who], 17, UiKit.TEXT_DIM)
	when.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(when)
	var lines := [
		["Tiempo jugado", SaveData.format_time(d.play_time), d.play_time > other.play_time + 30.0],
		["Niveles superados", str(d.levels_won.size()), d.levels_won.size() > other.levels_won.size()],
		["Dinero", MenuKit.money(d.money) + " $", d.money > other.money],
		["Objetos comprados", str(d.items_bought()), d.items_bought() > other.items_bought()],
		["Compañeros", str(d.pets.size()), d.pets.size() > other.pets.size()]]
	for line: Array in lines:
		var h := HBoxContainer.new()
		var a := UiKit.label(line[0], 20, UiKit.TEXT_DIM)
		a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(a)
		h.add_child(UiKit.label(line[1], 22, UiKit.GOLD if line[2] else UiKit.TEXT))
		v.add_child(h)
	for c in v.find_children("*", "Control", true, false): (c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b

func _choose(keep_cloud: bool) -> void:
	if _busy: return
	_busy = true
	var q := MenuKit.Confirm.new("¿Quedarte con la de %s?\n\nLa de %s se perderá." % [
		"la nube" if keep_cloud else "este PC", "este PC" if keep_cloud else "la nube"], "Quedarme con esta", "Cancelar", MenuKit.INK)
	add_child(q)
	var yes: bool = await q.answered
	if not yes:
		_busy = false
		_cards[1 if keep_cloud else 0].grab_focus.call_deferred()
		return
	_status.text = "Guardando…"
	if await Cloud.resolve(slot, keep_cloud):
		done.emit(true)
		queue_free()
		return
	_status.text = Cloud.error_text(Cloud.error)
	_busy = false
	_cards[1 if keep_cloud else 0].grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if _busy: return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		done.emit(false)
		queue_free()
