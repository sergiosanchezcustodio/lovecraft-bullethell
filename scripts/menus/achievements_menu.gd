class_name AchievementsMenu
extends Control
## Logros y desbloqueos (D-32, hito 2.14), desde el menú principal: todos los logros con su
## imagen, qué piden, su recompensa y el progreso (o "Conseguido" y la fecha). Los que faltan
## salen atenuados. Arriba y abajo recorren la lista; B / Esc cierra.

signal closed

var save: SaveData
var _icons := {}

func _ready() -> void:
	if save == null: save = Saves.current
	if save != null and not Achievements.check(save).is_empty(): Saves.save()   # los que ya se cumplían
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var w: Array = MenuKit.window(self, UiKit.GOLD, 980)
	var box: VBoxContainer = w[1]
	var list := Achievements.all()
	var done := list.filter(func(a: AchievementData) -> bool: return Achievements.is_done(save, a)).size()
	box.add_child(MenuKit.title("Logros", 48))
	var sub := UiKit.label("%d de %d conseguidos" % [done, list.size()], 22, UiKit.GOLD)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(920, 600)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_right", 14)
	scroll.add_child(margin)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	margin.add_child(col)
	var rows: Array = []
	for a in list:
		var r := _row(a)
		col.add_child(r)
		rows.append(r)
	MenuKit.chain_focus(rows)
	box.add_child(MenuKit.hint("Arriba/abajo: recorrer  ·  B o Esc: volver"))
	if not rows.is_empty(): (rows[0] as Control).grab_focus.call_deferred()

func _row(a: AchievementData) -> Button:
	var got := Achievements.is_done(save, a)
	var b := MenuKit.button("", UiKit.GOLD if got else UiKit.TEXT_DIM, 20)
	b.custom_minimum_size = Vector2(880, 96)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14; h.offset_right = -16; h.offset_top = 8; h.offset_bottom = -8
	h.add_theme_constant_override("separation", 14)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var pic := TextureRect.new()
	pic.texture = _icon(a)
	pic.custom_minimum_size = Vector2(76, 76)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not got: pic.modulate = Color(0.45, 0.45, 0.5, 0.8)
	h.add_child(pic)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(mid)
	mid.add_child(UiKit.label(a.display_name, 22, UiKit.TEXT if got else UiKit.TEXT_DIM))
	var d := UiKit.label(a.description, 15, UiKit.TEXT_DIM)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 560
	mid.add_child(d)
	var reward := Achievements.reward_text(a)
	if reward != "": mid.add_child(UiKit.label("Recompensa: " + reward, 14, UiKit.GOLD if got else Color(UiKit.GOLD, 0.6)))
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.custom_minimum_size.x = 170
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(right)
	if got:
		var date := String(save.achievements[String(a.id)]).substr(0, 10).split("-")
		var t := UiKit.label("Conseguido", 20, UiKit.XP)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(t)
		var f := UiKit.label("%s/%s/%s" % [date[2], date[1], date[0]] if date.size() == 3 else "", 14, UiKit.TEXT_DIM)
		f.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(f)
	else:
		var v := mini(Achievements.value(save, a), a.target)
		var t := UiKit.label("%s / %s" % [MenuKit.money(v), MenuKit.money(a.target)], 18, UiKit.TEXT_DIM)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		right.add_child(t)
		var bar := UiKit.Bar.new(UiKit.GOLD, 170, 8)
		bar.value = Achievements.progress(save, a)
		right.add_child(bar)
	return b

func _icon(a: AchievementData) -> Texture2D:
	if a.icon != null: return a.icon
	if a.icon_model == "": return null
	var key := a.icon_model + ":" + a.icon_mode
	if not _icons.has(key): _icons[key] = ModelIcon.make(self, a.icon_model, a.icon_mode, 160)
	return _icons[key]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
		queue_free()
