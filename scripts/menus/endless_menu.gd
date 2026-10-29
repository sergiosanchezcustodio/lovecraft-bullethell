class_name EndlessMenu
extends Control
## «La noche eterna» (hito 13.8): elegir uno de los 15 escenarios para el modo sin fin. Una
## columna por parte; en cada botón, el nivel y el mejor tiempo aguantado en él (con cualquier
## personaje). B / Esc vuelve al mapa. `picked` da el nivel base (p. ej. "p2_n3").

signal picked(base: String)
signal closed

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, Color(0.3, 0.25, 0.55), 1500)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "La noche eterna", 48, Color(0.72, 0.62, 1.0))
	var sub := UiKit.label("Elige escenario. Oleadas sin final con criaturas de las tres partes, un horror cada cinco minutos y cada vez más duro.", 19, UiKit.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = 1300
	box.add_child(sub)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 22)
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(cols)
	var grid: Array = []                             # [parte][nivel] -> botón, para mover el foco
	var pi := 0
	for part: Dictionary in Campaign.parts():
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		cols.add_child(col)
		var t := MenuKit.title(String(part.title), 24)
		t.custom_minimum_size.x = 460
		col.add_child(t)
		var row: Array = []
		for l: Dictionary in Campaign.levels().filter(func(e: Dictionary) -> bool: return e.part == pi):
			var id := String(l.id)
			var rec := best_any(Saves.current, id)
			var b := MenuKit.button("%d.  %s%s" % [l.number, l.name, ("\nRécord %s" % Endless.clock(rec)) if rec > 0.0 else ""], MenuKit.INK, 18)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.custom_minimum_size = Vector2(460, 70)
			b.disabled = not Campaign.exists(id)
			b.pressed.connect(func() -> void:
				picked.emit(id)
				queue_free())
			col.add_child(b)
			row.append(b)
		grid.append(row)
		pi += 1
	for c in grid.size():                             # izquierda y derecha cambian de parte
		for r in (grid[c] as Array).size():
			var b: Button = grid[c][r]
			if c > 0: b.focus_neighbor_left = b.get_path_to(grid[c - 1][mini(r, grid[c - 1].size() - 1)])
			if c < grid.size() - 1: b.focus_neighbor_right = b.get_path_to(grid[c + 1][mini(r, grid[c + 1].size() - 1)])
	box.add_child(MenuKit.hint("A o Intro: elegir  ·  B o Esc: volver al mapa"))
	if not grid.is_empty() and not (grid[0] as Array).is_empty(): (grid[0][0] as Control).grab_focus.call_deferred()

## Mejor tiempo en ese escenario con cualquier personaje.
static func best_any(save: SaveData, base: String) -> float:
	if save == null: return 0.0
	var out := 0.0
	var all: Dictionary = save.records.get("endless", {})
	for k: String in all:
		if k.ends_with("|" + base): out = maxf(out, float(all[k]))
	return out

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
