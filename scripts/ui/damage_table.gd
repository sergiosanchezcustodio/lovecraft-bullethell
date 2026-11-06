class_name DamageTable
extends CanvasLayer
## Pausa > Daño de la partida (hito 16.27): una fila por cada arma, objeto o compañero que ha hecho
## daño en este nivel, de más a menos: imagen, nombre, parte del total (con su barra), daño, daño
## por segundo (desde que esa fuente hizo daño por primera vez: `CombatWorld.table_of`) y
## abatidos. Al pie, el total. En cooperativo, un jugador cada vez (izquierda/derecha, LB/RB o
## Q/E). B / Esc vuelve a la pausa; Start la cierra.
## Capturas: `dmg_table=T` abre la pausa y la tabla a los T s (`dmg_player=N`, la del J N).

signal back
signal close

const ROWS := 12                         ## filas a la vista (lo demás, sumado en «Otros»)
const NAME_W := 330.0
const BAR_W := 230.0

var game: Node
var player_index := 0
var _box: VBoxContainer
var _title: Label
var _icons := {}

func _init(p_game: Node, p_index := 0) -> void:
	game = p_game
	player_index = p_index
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS

func _players() -> Array:
	return game.get("players") as Array if game != null else []

func _ready() -> void:
	var dim := MenuKit.veil()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var panel := PanelContainer.new()
	panel.theme = MenuKit.theme()
	add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	_title = MenuKit.title("", 38, UiKit.GOLD)
	outer.add_child(_title)
	outer.add_child(HSeparator.new())
	_box = VBoxContainer.new()
	_box.custom_minimum_size = Vector2(1180, 0)
	_box.add_theme_constant_override("separation", 4)
	outer.add_child(_box)
	var hint := UiKit.label(("Izquierda/derecha: otro jugador  ·  " if _players().size() > 1 else "") \
		+ "B o Esc: volver  ·  Start: seguir jugando", 15, UiKit.TEXT_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(hint)
	MenuKit.dress(panel, MenuKit.BRASS, Vector2(40, 28), 120.0)
	panel.resized.connect(func() -> void: panel.position = (get_viewport().get_visible_rect().size - panel.size) * 0.5)
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo \
			and (event as InputEventKey).keycode == KEY_ESCAPE):
		back.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and (event as InputEventJoypadButton).button_index == JOY_BUTTON_START:
		close.emit()
		get_viewport().set_input_as_handled()
	elif _players().size() > 1:
		var step := 0
		if event.is_action_pressed("ui_left"): step = -1
		elif event.is_action_pressed("ui_right"): step = 1
		elif event is InputEventJoypadButton and event.pressed:
			var b := (event as InputEventJoypadButton).button_index
			if b == JOY_BUTTON_LEFT_SHOULDER: step = -1
			elif b == JOY_BUTTON_RIGHT_SHOULDER: step = 1
		elif event is InputEventKey and event.pressed and not event.echo:
			var k := (event as InputEventKey).keycode
			if k == KEY_Q: step = -1
			elif k == KEY_E: step = 1
		if step != 0:
			player_index = wrapi(player_index + step, 0, _players().size())
			_build()
			get_viewport().set_input_as_handled()

## Nombre e imagen de una fuente de daño (arma, objeto, compañero).
func _source(p: Player, id: String) -> Array:
	if id == "mascota" and p.pet != null and is_instance_valid(p.pet):
		var pd: PetData = (p.pet as Pet).data
		if not _icons.has(pd.model): _icons[pd.model] = ModelIcon.make(self, pd.model, "full", 96, 0.0) if pd.model != "" else null
		return [pd.display_name, _icons[pd.model], "Compañero"]
	var wp := "res://data/weapons/%s.tres" % id
	if ResourceLoader.exists(wp):
		var w: WeaponData = load(wp)
		var lv := ""
		if p.weapons != null:
			for x: WeaponSystem.Weapon in p.weapons.weapons:
				if x.data.id == w.id: lv = "  ·  Nv %d" % x.level
		return [w.display_name + lv, w.get_icon(), ("Evolución" if w.evolved else "Arma") + " " + ["física", "de fuego", "mágica"][int(w.category)]]
	var up := "res://data/upgrades/%s.tres" % id
	if ResourceLoader.exists(up):
		var u: UpgradeData = load(up)
		return [u.display_name, u.icon, "Objeto"]
	return [id.capitalize(), null, ""]

func _build() -> void:
	for c in _box.get_children(): c.queue_free()
	var ps := _players()
	if ps.is_empty(): return
	player_index = clampi(player_index, 0, ps.size() - 1)
	var p: Player = ps[player_index]
	_title.text = ("J%d  ·  " % (p.index + 1) if ps.size() > 1 else "") + "Daño de la partida  ·  " + p.data.display_name
	_title.add_theme_color_override("font_color", p.color if ps.size() > 1 else UiKit.GOLD)
	var w: CombatWorld = p.world
	var rows: Array[Dictionary] = w.table_of(p.index) if w != null else []
	_box.add_child(_row(null, "Fuente", "", -1.0, "Parte", "Daño", "Por segundo", "Abatidos", true))
	if rows.is_empty():
		var none := UiKit.label("Todavía no has hecho daño.", 18, UiKit.TEXT_DIM)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(none)
		return
	var shown := rows.slice(0, ROWS) if rows.size() > ROWS else rows
	var top: float = rows[0].damage
	for r: Dictionary in shown:
		var src := _source(p, String(r.id))
		_box.add_child(_row(src[1], src[0], src[2], float(r.damage) / maxf(top, 1.0), "%d %%" % roundi(float(r.share) * 100.0),
			MenuKit.money(roundi(r.damage)), RunArchive.decimal(float(r.dps)), str(int(r.kills))))
	if rows.size() > ROWS:
		var rest := rows.slice(ROWS)
		var d := 0.0; var k := 0; var sh := 0.0
		for r: Dictionary in rest:
			d += float(r.damage); k += int(r.kills); sh += float(r.share)
		_box.add_child(_row(null, "Otros (%d)" % rest.size(), "", d / maxf(top, 1.0), "%d %%" % roundi(sh * 100.0), MenuKit.money(roundi(d)), "", str(k)))
	_box.add_child(HSeparator.new())
	var total := 0.0; var kills := 0
	for r: Dictionary in rows:
		total += float(r.damage); kills += int(r.kills)
	var t := int(w.clock)
	_box.add_child(_row(null, "Total", "%02d:%02d de partida" % [t / 60, t % 60], -1.0, "", MenuKit.money(roundi(total)),
		RunArchive.decimal(total / maxf(w.clock, 1.0)), str(kills), true))

## Una fila: imagen, nombre (y debajo, qué es), barra de la parte del total y cuatro cifras.
func _row(icon: Texture2D, name: String, kind: String, bar: float, share: String, dmg: String, dps: String, kills: String, head := false) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var img := TextureRect.new()
	img.texture = icon
	img.custom_minimum_size = Vector2(44, 44 if not head else 26)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	h.add_child(img)
	var names := VBoxContainer.new()
	names.custom_minimum_size = Vector2(NAME_W, 0)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.add_theme_constant_override("separation", -2)
	var n := UiKit.label(name, 19 if not head else 16, UiKit.TEXT if not head else UiKit.TEXT_DIM)
	n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	n.clip_text = true
	names.add_child(n)
	if kind != "": names.add_child(UiKit.label(kind, 14, UiKit.TEXT_DIM))
	h.add_child(names)
	var bar_box := Control.new()
	bar_box.custom_minimum_size = Vector2(BAR_W, 22)
	bar_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if bar >= 0.0:
		var bg := ColorRect.new()
		bg.color = Color(1, 1, 1, 0.06)
		bg.size = Vector2(BAR_W, 14)
		bg.position = Vector2(0, 4)
		bar_box.add_child(bg)
		var fg := ColorRect.new()
		fg.color = Color(UiKit.GOLD, 0.75)
		fg.size = Vector2(maxf(BAR_W * clampf(bar, 0.0, 1.0), 2.0), 14)
		fg.position = Vector2(0, 4)
		bar_box.add_child(fg)
	h.add_child(bar_box)
	for pair: Array in [[share, 90.0], [dmg, 150.0], [dps, 150.0], [kills, 120.0]]:
		var l := UiKit.label(pair[0], 19 if not head else 16, UiKit.GOLD if not head else UiKit.TEXT_DIM)
		l.custom_minimum_size = Vector2(pair[1], 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		h.add_child(l)
	return h
