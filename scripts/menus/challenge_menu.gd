class_name ChallengeMenu
extends Control
## Desafíos (hito 15.2): uno por nivel, en una columna por parte. Cada botón, el nivel, el nombre
## del desafío y ✓ si ya lo has superado; abajo, sus reglas. Se abre el de cada nivel al
## superarlo (en las versiones de desarrollo, todos). B / Esc vuelve al mapa. `picked` da el id
## del desafío (p. ej. "desafio:p2_n3").

signal picked(id: String)
signal closed

var _rules: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, Color(0.55, 0.2, 0.16), 1500)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, L.t("Desafíos"), 48, Color(0.95, 0.5, 0.38))
	var done := Challenge.won_count(Saves.current)
	var sub := UiKit.label(L.t("Cada nivel superado abre su desafío: el mismo escenario con reglas fijas y sin pactos. Superados: %d de %d.") % [done, Challenge.all().size()], 19, UiKit.TEXT_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.custom_minimum_size.x = 1300
	box.add_child(sub)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 22)
	cols.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(cols)
	var dev := OS.is_debug_build()
	var grid: Array = []                             # [parte][nivel] -> botón, para mover el foco
	var first: Button = null
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
			var base := String(l.id)
			var ch := Challenge.find(base)
			if ch.is_empty(): continue
			var open := Challenge.unlocked(Saves.current, base) and Demo.part_ok(pi)
			var tick := "✓ " if Challenge.won(Saves.current, base) else ""
			var rec := Challenge.best(Saves.current, base)
			var b := MenuKit.button("%s%d.  %s%s" % [tick, l.number, String(ch.name) if open or dev else L.t("Supera el nivel para abrirlo"),
				(L.t("  ·  Récord %s") % Endless.clock(rec)) if rec > 0.0 else ""], MenuKit.INK, 18)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.custom_minimum_size = Vector2(460, 62)
			b.disabled = not (open or dev) or not Campaign.exists(base)
			b.focus_entered.connect(func() -> void: _rules.text = "%s · %s" % [l.name, ch.text])
			b.pressed.connect(func() -> void:
				picked.emit(Challenge.id_for(base))
				queue_free())
			col.add_child(b)
			row.append(b)
			if first == null and not b.disabled: first = b
		grid.append(row)
		pi += 1
	var nights := Nights.all().filter(func(n: Dictionary) -> bool: return not Challenge.find(String(n.id)).is_empty())
	if not nights.is_empty():                        # los de las noches sueltas, en una fila debajo (22.6)
		var nt := MenuKit.title(L.t("Noches sueltas"), 24)
		box.add_child(nt)
		var nrow := HBoxContainer.new()
		nrow.add_theme_constant_override("separation", 22)
		nrow.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(nrow)
		var row: Array = []
		for n: Dictionary in nights:
			var base := String(n.id)
			var ch := Challenge.find(base)
			var open := Challenge.unlocked(Saves.current, base)
			var tick := "✓ " if Challenge.won(Saves.current, base) else ""
			var rec := Challenge.best(Saves.current, base)
			var b := MenuKit.button("%s%s%s" % [tick, String(ch.name) if open or dev else L.t("Supera la noche para abrirlo"),
				(L.t("  ·  Récord %s") % Endless.clock(rec)) if rec > 0.0 else ""], MenuKit.INK, 18)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.custom_minimum_size = Vector2(460, 62)
			b.disabled = not (open or dev) or not ResourceLoader.exists("res://data/levels/%s.tres" % base)
			b.focus_entered.connect(func() -> void: _rules.text = "%s · %s" % [String(n.titulo), ch.text])
			b.pressed.connect(func() -> void:
				picked.emit(Challenge.id_for(base))
				queue_free())
			nrow.add_child(b)
			row.append(b)
			if first == null and not b.disabled: first = b
		for b: Button in row:                          # arriba, al último de la columna más cercana
			var c := mini(row.find(b), grid.size() - 1)
			if c >= 0 and not (grid[c] as Array).is_empty():
				var up: Button = grid[c][-1]
				b.focus_neighbor_top = b.get_path_to(up)
				up.focus_neighbor_bottom = up.get_path_to(b)
		for i in row.size():
			if i > 0: row[i].focus_neighbor_left = row[i].get_path_to(row[i - 1])
			if i < row.size() - 1: row[i].focus_neighbor_right = row[i].get_path_to(row[i + 1])
	for c in grid.size():                             # izquierda y derecha cambian de parte
		for r in (grid[c] as Array).size():
			var b: Button = grid[c][r]
			if c > 0 and not (grid[c - 1] as Array).is_empty(): b.focus_neighbor_left = b.get_path_to(grid[c - 1][mini(r, grid[c - 1].size() - 1)])
			if c < grid.size() - 1 and not (grid[c + 1] as Array).is_empty(): b.focus_neighbor_right = b.get_path_to(grid[c + 1][mini(r, grid[c + 1].size() - 1)])
	_rules = UiKit.label("", 21, UiKit.TEXT)
	_rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rules.custom_minimum_size = Vector2(1300, 56)
	box.add_child(_rules)
	box.add_child(MenuKit.hint(L.t("A o Intro: jugar  ·  B o Esc: volver al mapa")))
	if first != null: first.grab_focus.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
