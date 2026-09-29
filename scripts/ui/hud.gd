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
	vp.size = Vector2i(128, 128)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var m := VoxelBuilder.load_model("res://models/%s.json" % p.data.model)
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


## Panel de un jugador en su esquina.
class PlayerPanel extends PanelContainer:
	var p: Player
	var _health: UiKit.Bar
	var _sanity: UiKit.Bar
	var _xp: UiKit.Bar
	var _dodge: UiKit.Bar
	var _level_lbl: Label
	var _weapons_lbl: Label
	var _crisis_lbl: Label
	var _health_txt: Label
	var _sanity_txt: Label
	var _down_lbl: Label
	var _weapons_row: HBoxContainer
	var _weapons_key := ""                      ## armas y niveles pintados (solo se rehace al cambiar)

	const MARGIN := 16.0

	func _init(player: Player, hud: Hud) -> void:
		p = player
		add_theme_stylebox_override("panel", UiKit.panel(UiKit.PANEL, Color(p.color, 0.55)))
		var right := p.index % 2 == 1
		var bottom := p.index >= 2
		var preset := Control.PRESET_TOP_LEFT
		if right and bottom: preset = Control.PRESET_BOTTOM_RIGHT
		elif right: preset = Control.PRESET_TOP_RIGHT
		elif bottom: preset = Control.PRESET_BOTTOM_LEFT
		set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, int(MARGIN))
		grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
		grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		add_child(row)
		var portrait := TextureRect.new()
		portrait.texture = hud.portrait_texture(p)
		portrait.custom_minimum_size = Vector2(92, 92)
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		var pbox := VBoxContainer.new()
		pbox.add_child(portrait)
		_dodge = UiKit.Bar.new(UiKit.GOLD, 92, 5)
		pbox.add_child(_dodge)
		row.add_child(pbox)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 4)
		row.add_child(col)
		var head := HBoxContainer.new()
		head.add_child(UiKit.label("J%d" % (p.index + 1), 18, p.color))
		head.add_child(UiKit.label(p.data.display_name, 18))
		var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(sp)
		_level_lbl = UiKit.label("Nv 1", 18, UiKit.XP)
		head.add_child(_level_lbl)
		col.add_child(head)
		_health = UiKit.Bar.new(UiKit.HEALTH, 250, 14)
		_health_txt = _bar_row(col, _health)
		_sanity = UiKit.Bar.new(UiKit.SANITY, 250, 14)
		_sanity_txt = _bar_row(col, _sanity)
		_xp = UiKit.Bar.new(UiKit.XP, 250, 6)
		col.add_child(_xp)
		_weapons_row = HBoxContainer.new()                # armas: su icono con el nivel
		_weapons_row.add_theme_constant_override("separation", 4)
		col.add_child(_weapons_row)
		_weapons_lbl = UiKit.label("", 15, UiKit.TEXT_DIM)  # las que no tienen icono, por su nombre
		_weapons_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_weapons_lbl.custom_minimum_size.x = 250
		col.add_child(_weapons_lbl)
		_crisis_lbl = UiKit.label("", 15, UiKit.SANITY)          # superpuesto abajo: no ocupa sitio
		_crisis_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_crisis_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_crisis_lbl.size_flags_vertical = Control.SIZE_SHRINK_END
		_crisis_lbl.size_flags_horizontal = Control.SIZE_SHRINK_END
		_down_lbl = MenuKit.title("Caído", 30, Color(0.95, 0.35, 0.28))
		_down_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_down_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_down_lbl.visible = false

	func _ready() -> void:
		add_child(_crisis_lbl)
		add_child(_down_lbl)

	## Iconos de las armas con su nivel en la esquina; sin icono, el nombre debajo.
	func _paint_weapons() -> void:
		for c in _weapons_row.get_children(): c.queue_free()
		var names: PackedStringArray = []
		if p.weapons != null:
			for w in p.weapons.weapons:
				var tex := w.data.get_icon()
				if tex == null:
					names.append("%s %d" % [w.data.display_name, w.level])
					continue
				var cell := Control.new()
				cell.custom_minimum_size = Vector2(38, 38)
				var t := TextureRect.new()
				t.texture = tex
				t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				cell.add_child(t)
				var lv := UiKit.label(str(w.level), 13, UiKit.GOLD)
				lv.position = Vector2(27, 21)
				cell.add_child(lv)
				_weapons_row.add_child(cell)
		_weapons_row.visible = _weapons_row.get_child_count() > 0
		_weapons_lbl.text = "  ·  ".join(names)
		_weapons_lbl.visible = not names.is_empty()

	func _bar_row(parent: Container, bar: UiKit.Bar) -> Label:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.add_child(bar)
		var l := UiKit.label("", 13, UiKit.TEXT_DIM)
		l.custom_minimum_size.x = 96
		h.add_child(l)
		parent.add_child(h)
		return l

	func refresh() -> void:
		var d := p.data
		_health.value = p.health / d.max_health
		_sanity.value = p.sanity / d.max_sanity
		_health_txt.text = "Vida %d" % ceili(p.health)
		_sanity_txt.text = "Cordura %d" % ceili(p.sanity)
		_xp.value = p.progress.xp_fraction()
		_level_lbl.text = "Nv %d" % p.progress.level
		_dodge.value = p.motor.dodge_ready_fraction()
		var key := ""
		if p.weapons != null:
			for w in p.weapons.weapons: key += "%s:%d," % [w.data.id, w.level]
		if key != _weapons_key:
			_weapons_key = key
			_paint_weapons()
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
