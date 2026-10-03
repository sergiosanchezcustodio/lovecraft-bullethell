class_name Hud
extends CanvasLayer
## HUD de la partida. Un panel por jugador, cada uno en su esquina (J1 arriba a la
## izquierda, J2 arriba a la derecha, J3 abajo a la izquierda, J4 abajo a la derecha, GDD
## 3.3): retrato con el color del jugador, vida, cordura, experiencia y nivel, armas,
## recarga del esquive y aviso de crisis. Si el jugador cae, su panel se apaga. Arriba en
## el centro: parte y nivel, objetivo y tiempo. Paneles compactos y translúcidos para no
## tapar balas.

var players: Array[Player] = []
var director: WaveDirector
var panels: Array[PlayerPanel] = []
var _time_lbl: Label
var _objective_lbl: Label
var _money_lbl: Label
var money := Callable()                      ## () -> int: dólares de la partida (los pone game.gd)

## Compatibilidad: el J1.
var player: Player:
	get: return players[0] if not players.is_empty() else null

func setup(p_players: Array[Player], p_director: WaveDirector) -> Hud:
	players = p_players
	director = p_director
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS       # sigue al día con la partida en pausa
	return self

func _ready() -> void:
	for p in players:
		var pp := PlayerPanel.new(p, self)
		add_child(pp)
		panels.append(pp)
	# ---- Información global arriba en el centro ----
	var top := VBoxContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	top.position.y = 12
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(top)
	var lvl_name := "Parte %d · Nivel %d" % [director.level.part, director.level.number] if director != null else "Campo de pruebas"
	var title := UiKit.label(lvl_name, 16, UiKit.TEXT_DIM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(title)
	_time_lbl = UiKit.label("00:00", 30)
	_time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_time_lbl)
	_objective_lbl = UiKit.label("", 16, UiKit.TEXT)
	_objective_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_objective_lbl)
	_money_lbl = UiKit.label("", 18, UiKit.GOLD)
	_money_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_money_lbl)
	top.resized.connect(func() -> void: top.position.x = (get_viewport().get_visible_rect().size.x - top.size.x) * 0.5)

func _process(_delta: float) -> void:
	var t0 := Prof.start()
	_process_step(_delta)
	Prof.stop("hud", t0)

func _process_step(_delta: float) -> void:
	for pp in panels: pp.refresh()
	if money.is_valid(): _money_lbl.text = "%s $" % MenuKit.money(int(money.call()))
	if director != null:
		var t := int(director.time)
		_time_lbl.text = "%02d:%02d" % [t / 60, t % 60]
		if director.completed:
			_objective_lbl.text = "Nivel superado"
		elif director.time >= director.level.final_time and director.level.final_enemy != null:
			_objective_lbl.text = "Acaba con %s" % director.level.final_enemy.display_name
		else:
			var left := int(director.level.final_time - director.time)
			_objective_lbl.text = "Resiste · %d:%02d para el final" % [left / 60, left % 60]

## Retrato: la cabeza del modelo del personaje, renderizada una vez en un SubViewport.
func portrait_texture(p: Player) -> Texture2D:
	var vp := SubViewport.new()
	# Se renderiza una sola vez: sin interpolación de física, o la cámara y el modelo aún
	# estarían interpolando desde el origen en ese fotograma y el retrato saldría mal.
	vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	vp.size = Vector2i(128, 128)                     # la cabeza (panel del jugador)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var m := VoxelBuilder.load_model("res://models/%s.json" % p.data.model)
	OutfitData.apply(m, p.data.model, OutfitData.worn_for(String(p.data.id)))
	vp.add_child(m)
	var head: Vector3 = Anims.rest(m, "head") + Vector3(0, 0.2, 0)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 0.62
	cam.rotation_degrees = Vector3(-12, 25, 0)
	cam.position = head + cam.transform.basis.z * 3.0
	vp.add_child(cam)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-35, 40, 0)
	l.light_energy = 1.3
	vp.add_child(l)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.3
	we.environment = env
	vp.add_child(we)
	return vp.get_texture()


## Panel de un jugador en su esquina (diseño del autor, 30-09-2026; al 60 % de su primer
## tamaño, con los iconos lo menos reducidos posible): a la izquierda "J1" y el nivel, la
## cabeza del personaje y debajo la experiencia en 10 casillas en relieve; a la
## derecha el nombre, las barras de vida, cordura y esquive con su icono, la fila de armas y
## la de objetos, cada uno con su nivel. Todo en posiciones fijas: nada se mueve al cambiar.
class PlayerPanel extends PanelContainer:
	var p: Player
	var _health: UiKit.Bar
	var _sanity: UiKit.Bar
	var _dodge: UiKit.Bar
	var _xp: LevelCells
	var _level_lbl: Label
	var _crisis_lbl: Label
	var _down_lbl: Label
	var _weapons_row: HBoxContainer
	var _items_row: HBoxContainer
	var _weapons_key := ""                      ## armas y niveles pintados (solo se rehace al cambiar)
	var _items_key := ""

	const MARGIN := 16.0
	const SIZE := Vector2(272, 132)
	const LEFT_W := 76.0                        ## columna de la cabeza
	const RIGHT_X := 84.0
	const BAR_W := 166.0
	const CELL := Vector2(36, 32)               ## casilla de arma u objeto: caben 5 en la fila
	const ICON := 16.0                          ## iconos de vida, cordura y esquive
	const ICONS := "res://resources/PantallasMenus/iconos/ficha_%s.png"

	func _init(player: Player, hud: Hud) -> void:
		p = player
		add_theme_stylebox_override("panel", UiKit.panel(UiKit.PANEL, Color(p.color, 0.55), 8))
		var right := p.index % 2 == 1
		var bottom := p.index >= 2
		var preset := Control.PRESET_TOP_LEFT
		if right and bottom: preset = Control.PRESET_BOTTOM_RIGHT
		elif right: preset = Control.PRESET_TOP_RIGHT
		elif bottom: preset = Control.PRESET_BOTTOM_LEFT
		set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, int(MARGIN))
		grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
		grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
		var box := Control.new()
		box.custom_minimum_size = SIZE
		add_child(box)
		# izquierda: J1 y nivel, busto, experiencia
		var j := MenuKit.title("J%d" % (p.index + 1), 20, p.color)
		j.position = Vector2(0, -4)
		box.add_child(j)
		_level_lbl = UiKit.label("Nv. 1", 14, UiKit.GOLD)
		_level_lbl.position = Vector2(28, -1)
		box.add_child(_level_lbl)
		var portrait := TextureRect.new()
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE      # antes que el tamaño: si no, se queda al de la imagen
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture = hud.portrait_texture(p)
		portrait.position = Vector2(0, 22)
		portrait.size = Vector2(LEFT_W, 86)
		box.add_child(portrait)
		_xp = LevelCells.new()
		_xp.position = Vector2(0, 113.5)                 # a igual distancia de la cabeza y del borde inferior
		_xp.size = Vector2(LEFT_W, 14)
		box.add_child(_xp)
		# derecha: nombre, barras con su icono, armas y objetos
		var name_lbl := UiKit.label(p.data.display_name, 16, UiKit.TEXT)
		name_lbl.position = Vector2(RIGHT_X, -3)
		name_lbl.size = Vector2(SIZE.x - RIGHT_X, 22)
		name_lbl.clip_text = true
		box.add_child(name_lbl)
		_health = _bar(box, "vida", UiKit.HEALTH, 22)
		_sanity = _bar(box, "cordura", UiKit.SANITY, 38)
		_dodge = _bar(box, "esquive", UiKit.GOLD, 54)
		_weapons_row = _cells(box, 68)
		_items_row = _cells(box, 100)
		_crisis_lbl = UiKit.label("", 12, UiKit.SANITY)          # superpuesto abajo: no ocupa sitio
		_crisis_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_crisis_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_crisis_lbl.size_flags_vertical = Control.SIZE_SHRINK_END
		_crisis_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
		_down_lbl = MenuKit.title("Caído", 22, Color(0.95, 0.35, 0.28))
		_down_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_down_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_down_lbl.visible = false

	func _ready() -> void:
		add_child(_crisis_lbl)
		add_child(_down_lbl)

	## Fila de barra: icono de la ficha y la barra.
	func _bar(box: Control, icon: String, c: Color, y: float) -> UiKit.Bar:
		var t := TextureRect.new()
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture = load(ICONS % icon)
		t.position = Vector2(RIGHT_X, y - 3)
		t.size = Vector2(ICON, ICON)
		box.add_child(t)
		var b := UiKit.Bar.new(c, BAR_W, 10)
		b.position = Vector2(RIGHT_X + ICON + 4, y)
		b.size = Vector2(BAR_W, 10)
		box.add_child(b)
		return b

	func _cells(box: Control, y: float) -> HBoxContainer:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		row.position = Vector2(RIGHT_X - 2, y)
		box.add_child(row)
		return row

	## Casilla con la imagen (o el nombre abreviado, si no tiene) y el nivel en la esquina.
	func _cell(row: HBoxContainer, tex: Texture2D, name: String, level: int) -> void:
		var cell := Control.new()
		cell.custom_minimum_size = CELL
		if tex != null:
			var t := TextureRect.new()
			t.texture = tex
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			cell.add_child(t)
		else:
			var n := UiKit.label(name.substr(0, 4), 10, UiKit.TEXT_DIM)
			n.position = Vector2(1, 8)
			cell.add_child(n)
		var lv := UiKit.label(str(level), 14, UiKit.GOLD)
		lv.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lv.add_theme_constant_override("outline_size", 4)
		lv.position = Vector2(CELL.x - 10, CELL.y - 19)
		cell.add_child(lv)
		row.add_child(cell)

	func _paint_weapons() -> void:
		for c in _weapons_row.get_children(): c.queue_free()
		if p.weapons == null: return
		for w in p.weapons.weapons: _cell(_weapons_row, w.data.get_icon(), w.data.display_name, w.level)

	func _paint_items() -> void:
		for c in _items_row.get_children(): c.queue_free()
		for up in p.progress.upgrade_pool:
			var lv: int = p.progress.passives.get(up.id, 0)
			if lv > 0: _cell(_items_row, up.icon, up.display_name, lv)

	func refresh() -> void:
		var d := p.data
		_health.value = p.health / d.max_health
		_sanity.value = p.sanity / d.max_sanity
		_xp.value = p.progress.xp_fraction()
		_level_lbl.text = "Nv. %d" % p.progress.level
		_dodge.value = p.motor.dodge_ready_fraction()
		var key := ""
		if p.weapons != null:
			for w in p.weapons.weapons: key += "%s:%d," % [w.data.id, w.level]
		if key != _weapons_key:
			_weapons_key = key
			_paint_weapons()
		key = str(p.progress.passives)
		if key != _items_key:
			_items_key = key
			_paint_items()
		var ss := p.sanity_state
		_crisis_lbl.text = ("Crisis: %s" % SanityState.NAMES.get(ss.crisis_kind, "locura")) if ss.in_crisis else ""
		var down := p.health <= 0.0
		_down_lbl.visible = down
		if p.is_eliminated: _down_lbl.text = "Eliminado"
		elif down and p.revivable:
			var pct := int(100.0 * p.revive_progress / p.rules.revive_time)
			_down_lbl.text = "Derribado · %d s" % ceili(p.down_left) + ("  ·  %d %%" % pct if pct > 0 else "")
		else: _down_lbl.text = "Caído"
		modulate = Color(0.55, 0.55, 0.6, 0.8) if down else Color.WHITE


## Experiencia en 10 casillas en relieve: llenas en azul, la que se está llenando a medias y
## las demás claras y apagadas.
class LevelCells extends Control:
	var value := 0.0                            ## 0..1
	var _shown := 0.0
	const N := 10
	const FILL := Color(0.18, 0.42, 0.78)
	const EMPTY := Color(0.80, 0.82, 0.86)

	func _process(delta: float) -> void:
		var target := clampf(value, 0.0, 1.0)
		if target < _shown - 0.5: _shown = target          # subió de nivel: vuelve a empezar
		_shown = lerpf(_shown, target, 1.0 - exp(-12.0 * delta))
		queue_redraw()

	func _draw() -> void:
		var gap := 1.0
		var w := (size.x - gap * (N - 1)) / N
		for i in N:
			var r := Rect2(Vector2(i * (w + gap), 0), Vector2(w, size.y))
			var f := clampf(_shown * N - i, 0.0, 1.0)
			_cell(r, EMPTY)
			if f > 0.0: _cell(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), FILL)

	## Casilla en relieve: canto claro arriba y a la izquierda, oscuro abajo y a la derecha.
	func _cell(r: Rect2, c: Color) -> void:
		draw_rect(r, c)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), c.lightened(0.45))
		draw_rect(Rect2(r.position, Vector2(1, r.size.y)), c.lightened(0.3))
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), c.darkened(0.45))
		draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), c.darkened(0.3))
