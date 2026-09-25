class_name Hud
extends CanvasLayer
## HUD de la partida. Panel del J1 arriba a la izquierda: retrato con el color del
## jugador, vida, cordura, experiencia y nivel, armas, recarga del esquive y aviso de
## crisis. Arriba en el centro: parte y nivel, objetivo y tiempo. Paneles compactos y
## translúcidos para no tapar balas (GDD 3.3).

var player: Player
var director: WaveDirector
var _health: UiKit.Bar
var _sanity: UiKit.Bar
var _xp: UiKit.Bar
var _dodge: UiKit.Bar
var _level_lbl: Label
var _weapons_lbl: Label
var _crisis_lbl: Label
var _time_lbl: Label
var _objective_lbl: Label
var _health_txt: Label
var _sanity_txt: Label

func setup(p_player: Player, p_director: WaveDirector) -> Hud:
	player = p_player
	director = p_director
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS       # sigue al día con la partida en pausa
	return self

func _ready() -> void:
	# ---- Panel del J1 ----
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.panel(UiKit.PANEL, Color(player.color, 0.55)))
	panel.position = Vector2(16, 16)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var portrait := TextureRect.new()
	portrait.texture = _portrait_texture()
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
	head.add_child(UiKit.label(player.data.display_name, 18))
	var sp := Control.new(); sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_level_lbl = UiKit.label("Nv 1", 18, UiKit.XP)
	head.add_child(_level_lbl)
	col.add_child(head)
	_health = UiKit.Bar.new(UiKit.HEALTH, 250, 14)
	_health_txt = _bar_row(col, _health, "Vida")
	_sanity = UiKit.Bar.new(UiKit.SANITY, 250, 14)
	_sanity_txt = _bar_row(col, _sanity, "Cordura")
	_xp = UiKit.Bar.new(UiKit.XP, 250, 6)
	col.add_child(_xp)
	_weapons_lbl = UiKit.label("", 15, UiKit.TEXT_DIM)
	col.add_child(_weapons_lbl)
	_crisis_lbl = UiKit.label("", 18, UiKit.SANITY)
	_crisis_lbl.position = Vector2(20, 150)
	add_child(_crisis_lbl)
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
	top.resized.connect(func() -> void: top.position.x = (get_viewport().get_visible_rect().size.x - top.size.x) * 0.5)

func _bar_row(parent: Container, bar: UiKit.Bar, text: String) -> Label:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(bar)
	var l := UiKit.label(text, 13, UiKit.TEXT_DIM)
	l.custom_minimum_size.x = 96
	h.add_child(l)
	parent.add_child(h)
	return l

## Retrato: la cabeza del modelo del personaje, renderizada una vez en un SubViewport.
func _portrait_texture() -> Texture2D:
	var vp := SubViewport.new()
	# Se renderiza una sola vez: sin interpolación de física, o la cámara y el modelo aún
	# estarían interpolando desde el origen en ese fotograma y el retrato saldría mal.
	vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	vp.size = Vector2i(128, 128)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	var m := VoxelBuilder.load_model("res://models/%s.json" % player.data.model)
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

func _process(_delta: float) -> void:
	var d := player.data
	_health.value = player.health / d.max_health
	_sanity.value = player.sanity / d.max_sanity
	_health_txt.text = "Vida %d" % ceili(player.health)
	_sanity_txt.text = "Cordura %d" % ceili(player.sanity)
	_xp.value = player.progress.xp / player.progress.xp_to_next()
	_level_lbl.text = "Nv %d" % player.progress.level
	_dodge.value = player.motor.dodge_ready_fraction()
	var parts: PackedStringArray = []
	if player.weapons != null:
		for w in player.weapons.weapons:
			parts.append("%s %d" % [w.data.display_name, w.level])
	_weapons_lbl.text = "  ·  ".join(parts)
	var ss := player.sanity_state
	_crisis_lbl.text = "Crisis de locura: parálisis" if ss.in_crisis else ""
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
