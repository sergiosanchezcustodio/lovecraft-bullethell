class_name Hud
extends CanvasLayer
## HUD de la partida. Un panel por jugador, cada uno en su esquina (J1 arriba a la
## izquierda, J2 arriba a la derecha, J3 abajo a la izquierda, J4 abajo a la derecha, GDD
## 3.3): retrato con el color del jugador, vida, cordura, experiencia y nivel, armas,
## recarga del esquive y aviso de crisis. Si el jugador cae, su panel se apaga. Arriba en
## el centro: parte y nivel, objetivo y tiempo. Paneles compactos y translúcidos para no
## tapar balas.
## En red (hito 9.4b), el panel de un jugador de otro PC lleva debajo (encima, en los de
## abajo) el nombre de su PC y un punto con el ping: verde, amarillo o rojo.

const PORTRAIT_SHADER := preload("res://scripts/ui/portrait_state.gdshader")
static var frost := 0.0                     ## escarcha en los retratos (la Antártida; la pone game.gd)

var players: Array[Player] = []
var director: WaveDirector
var panels: Array[PlayerPanel] = []
var _time_lbl: Label
var _objective_lbl: Label
var _money_lbl: Label
var money := Callable()                      ## () -> int: dólares de la partida (los pone game.gd)
var net_info := Callable()                   ## (Player) -> [PC, ping en ms (-1: sin conexión)] o [] si es de este PC

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
	for l: Label in [title, _time_lbl, _objective_lbl, _money_lbl]:    # Garamond, como los menús (27-10-2026)
		l.add_theme_font_override("font", MenuKit.body_font(true))
	title.add_theme_font_size_override("font_size", 20)          # la x de Garamond es más baja: un poco más grandes
	_time_lbl.add_theme_font_size_override("font_size", 36)
	_objective_lbl.add_theme_font_size_override("font_size", 21)
	_money_lbl.add_theme_font_size_override("font_size", 23)
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
			var l := int(ceil(director.loot_left))
			_objective_lbl.text = "Nivel superado · recoge el botín %d" % l if l > 0 else "Nivel superado"
		elif director.level.is_survival() and director.time >= director.level.final_time:
			var s := int(ceil(director.survive_left()))
			_objective_lbl.text = "Resiste a %s · %d:%02d" % [director.level.final_name, s / 60, s % 60]
		elif not director.mid_alive.is_empty():
			_objective_lbl.text = "Acaba con %s" % director.mid_alive[0].data.display_name
		elif director.time >= director.level.final_time and director.level.final_enemy != null:
			var f := director.final_target()
			_objective_lbl.text = "Acaba con %s" % (f.data.display_name if f != null else director.level.final_enemy.display_name)
		else:
			var left := int(director.level.final_time - director.time)
			_objective_lbl.text = "Resiste · %d:%02d para el final" % [left / 60, left % 60]

## Lo que dice ahora el objetivo ("Resiste · 2:10 para el final"), para quien espera a volver.
func objective_text() -> String:
	return _objective_lbl.text if _objective_lbl != null else ""

## Retrato: la cabeza del modelo del personaje en un SubViewport que solo se vuelve a dibujar
## cuando cambia la cara: parpadea, pone la mueca al recibir un golpe y la de pánico en las
## crisis, a la vez que el modelo de la partida (PortraitFace, 28-10-2026).
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
	var path := VoxelBuilder.variant_path("res://models/%s.json" % p.data.model)
	var m := VoxelBuilder.load_model(path)
	OutfitData.apply(m, p.data.model, OutfitData.worn_for(String(p.data.id)))
	vp.add_child(m)
	var face := FaceLook.new().setup(m, path)
	face.driven = true
	vp.add_child(face)
	vp.add_child(PortraitFace.new(p, vp, face, CrisisLook._make_face(m)))
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


## Estado del retrato (hito 12.14): x, la sangre (desde la mitad de la vida; toda al caer); y, la
## mirada perdida (desde el 40 % de la cordura; toda en la crisis).
static func portrait_state(hp: float, san: float, crisis: bool, downed: bool) -> Vector2:
	var blood := 1.0 if downed else clampf((0.5 - hp) / 0.4, 0.0, 1.0)
	var lost := 1.0 if crisis else clampf((0.4 - san) / 0.32, 0.0, 1.0)
	return Vector2(blood, lost)

## Copia en el retrato la cara del jugador (abierta, parpadeo, mueca o pánico) y, si cambia,
## pide un fotograma más al SubViewport (que si no, no se vuelve a dibujar).
class PortraitFace extends Node:
	var p: Player
	var vp: SubViewport
	var face: FaceLook
	var panic: Node3D
	var _last := -1

	func _init(player: Player, viewport: SubViewport, f: FaceLook, panic_face: Node3D) -> void:
		p = player; vp = viewport; face = f; panic = panic_face

	func _process(_delta: float) -> void:
		if not is_instance_valid(p): return
		var crisis := p.sanity_state != null and p.sanity_state.in_crisis
		var s := 3 if crisis else (p.face_look().state() if p.face_look() != null else 0)
		if s == _last: return
		_last = s
		face.show_state(s if s < 3 else 0)
		if panic != null: panic.visible = s == 3
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE

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
	var _net_row: HBoxContainer
	var _net_dot: Label
	var _net_lbl: Label
	var _hud: Hud
	var _items_key := ""
	var _portrait_mat: ShaderMaterial
	var _state := Vector2.ZERO                  ## sangre y mirada perdida del retrato, suavizadas
	var _down := 0.0                            ## abatido (sin color) y vaho de la ventisca, suavizados
	var _mist := 0.0

	const MARGIN := 16.0
	const SIZE := Vector2(272, 132)
	const LEFT_W := 76.0                        ## columna de la cabeza
	const RIGHT_X := 84.0
	const BAR_W := 166.0
	const CELL := Vector2(36, 32)               ## casilla de arma u objeto: caben 5 en la fila
	const ICON := 16.0                          ## iconos de vida, cordura y esquive
	const ICONS := "res://resources/PantallasMenus/iconos/ficha_%s.png"
	const PING_OK := Color(0.4, 0.9, 0.45)
	const PING_MID := Color(1.0, 0.82, 0.3)
	const PING_BAD := Color(0.95, 0.3, 0.25)
	const PING_GOOD_MS := 120                   ## por debajo, verde
	const PING_FAIR_MS := 250                   ## por debajo, amarillo; si no, rojo

	## Color del punto del ping (-1: sin conexión, gris).
	static func ping_color(ms: int) -> Color:
		if ms < 0: return UiKit.TEXT_DIM
		if ms < PING_GOOD_MS: return PING_OK
		return PING_MID if ms < PING_FAIR_MS else PING_BAD

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
		_portrait_mat = ShaderMaterial.new()             # sangre, mirada perdida y escarcha (hito 12.14)
		_portrait_mat.shader = PORTRAIT_SHADER
		_portrait_mat.set_shader_parameter("seed", 13.7 * (p.index + 1))
		_portrait_mat.set_shader_parameter("frost", Hud.frost)
		portrait.material = _portrait_mat
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
		_net_row = HBoxContainer.new()                           # PC y ping (en red, los de otros PC)
		_net_row.add_theme_constant_override("separation", 6)
		_net_row.position = Vector2(0, -32 if bottom else SIZE.y + 14)
		_net_dot = UiKit.label("●", 20, PING_OK)
		_net_row.add_child(_net_dot)
		_net_lbl = UiKit.label("", 14, UiKit.TEXT)
		for l: Label in [_net_dot, _net_lbl]:                   # se lee también sobre la nieve
			l.add_theme_constant_override("outline_size", 5)
		_net_row.add_child(_net_lbl)
		_net_row.visible = false
		box.add_child(_net_row)
		_hud = hud
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

	## Sangre con poca vida (toda, abatido) y mirada perdida con poca cordura (toda, en la crisis):
	## van hacia su valor poco a poco, para que un golpe no cambie el retrato de golpe. Abatido,
	## además, sin color; y en la ventisca del paso, empañado (Ambient.blizzard_now).
	func _portrait_step() -> void:
		if _portrait_mat == null: return
		var to := Hud.portrait_state(p.health / maxf(p.data.max_health, 1.0), p.sanity / maxf(p.data.max_sanity, 1.0),
			p.sanity_state != null and p.sanity_state.in_crisis, p.is_downed())
		var dt := get_process_delta_time()
		var dn := move_toward(_down, 1.0 if p.is_downed() else 0.0, dt * 1.5)
		if dn != _down:
			_down = dn
			_portrait_mat.set_shader_parameter("down", dn)
		var mi := move_toward(_mist, Ambient.blizzard_now, dt * 0.5)
		if mi != _mist:
			_mist = mi
			_portrait_mat.set_shader_parameter("mist", mi)
		var s := Vector2(move_toward(_state.x, to.x, dt * 0.8), move_toward(_state.y, to.y, dt * 0.6))
		if s == _state: return
		_state = s
		_portrait_mat.set_shader_parameter("blood", s.x)
		_portrait_mat.set_shader_parameter("lost", s.y)

	func _paint_items() -> void:
		for c in _items_row.get_children(): c.queue_free()
		for up in p.progress.upgrade_pool:
			var lv: int = p.progress.passives.get(up.id, 0)
			if lv > 0: _cell(_items_row, up.icon, up.display_name, lv)

	func refresh() -> void:
		var d := p.data
		_portrait_step()
		_health.value = p.hud_lie.x if p.hud_lie.x >= 0.0 else p.health / d.max_health   # alucinación (13.4)
		_sanity.value = p.hud_lie.y if p.hud_lie.y >= 0.0 else p.sanity / d.max_sanity
		_xp.value = p.progress.xp_fraction()
		_xp.fill = p.progress.xp_color()                 # cooperativo: color de quien sube la próxima vez
		_xp.mine = p.progress.is_next()                  # y su barra, enmarcada
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
		var ni: Array = _hud.net_info.call(p) if _hud.net_info.is_valid() else []
		_net_row.visible = not ni.is_empty()
		if not ni.is_empty():
			var ms := int(ni[1])
			_net_dot.add_theme_color_override("font_color", ping_color(ms))
			_net_lbl.text = String(ni[0]) if ms < 0 else "%s · %d ms" % [ni[0], ms]


## Experiencia en 10 casillas en relieve: llenas en azul (en cooperativo, del color de quien
## sube la próxima vez), la que se está llenando a medias y las demás claras y apagadas. En
## cooperativo, la del jugador al que le toca subir lleva un marco que late (`mine`).
class LevelCells extends Control:
	var value := 0.0                            ## 0..1
	var fill := FILL
	var mine := false
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
			if f > 0.0: _cell(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), fill)
		if mine:
			var k := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.006)
			draw_rect(Rect2(Vector2(-2.5, -2.5), size + Vector2(5, 5)), Color(fill.lightened(0.35), k), false, 2.0)

	## Casilla en relieve: canto claro arriba y a la izquierda, oscuro abajo y a la derecha.
	func _cell(r: Rect2, c: Color) -> void:
		draw_rect(r, c)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), c.lightened(0.45))
		draw_rect(Rect2(r.position, Vector2(1, r.size.y)), c.lightened(0.3))
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), c.darkened(0.45))
		draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), c.darkened(0.3))
