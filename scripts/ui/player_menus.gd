class_name PlayerMenus
extends CanvasLayer
## Ficha y mapa de cada jugador en partida (hito 2.12, D-16). Se abren y se cierran con su
## botón (Select/Tab la ficha, cruceta abajo/M el mapa) y B/Esc los cierra:
## - en solitario, en el centro y con la partida en pausa;
## - en cooperativo, en el cuadrante del jugador, semitransparentes, sin pausar ni bloquear
##   a nadie: el personaje sigue controlable.
## La ficha tiene tres páginas (personaje, armas y objetos) que se pasan con LB/RB (Q/E).
## Mientras la partida está en pausa por otra cosa (Start, subida de nivel), se ocultan.

var game: Node
var players: Array[Player] = []
var _open := {}                              ## Player -> Control abierto (Sheet o ArenaMap)
var _last_frame := {}                        ## Player -> fotograma de física ya atendido
var _paused_by_me := false

func setup(p_game: Node, p_players: Array[Player]) -> PlayerMenus:
	game = p_game
	players = p_players
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	return self

func solo() -> bool:
	return players.size() == 1

func is_open(p: Player) -> bool:
	return _open.has(p)

func open_kind(p: Player) -> StringName:
	if not _open.has(p): return &""
	return &"sheet" if _open[p] is Sheet else &"map"

func _process(delta: float) -> void:
	var tree := get_tree()
	var others_paused := tree.paused and not _paused_by_me
	for c in _open.values(): (c as Control).visible = not others_paused
	if others_paused: return
	for p in players:
		if p.input is BotInput: continue
		if tree.paused:
			p.input.update(delta)                  # en pausa (solitario) el jugador no la lee
		else:
			var f := Engine.get_physics_frames()   # just_pressed dura hasta el siguiente paso de física
			if _last_frame.get(p, -1) == f: continue
			_last_frame[p] = f
		var inp := p.input
		if inp.just_pressed(InputBindings.SHEET): toggle(p, &"sheet")
		elif inp.just_pressed(InputBindings.MAP): toggle(p, &"map")
		elif inp.just_pressed(InputBindings.BACK) and _open.has(p): close(p)
		elif _open.get(p) is Sheet:
			if inp.just_pressed(InputBindings.PAGE_NEXT): (_open[p] as Sheet).turn(1)
			elif inp.just_pressed(InputBindings.PAGE_PREV): (_open[p] as Sheet).turn(-1)

## Abre o cierra la ficha o el mapa de un jugador (si tenía abierto el otro, lo cambia).
func toggle(p: Player, kind: StringName) -> void:
	var was := open_kind(p)
	if was != &"": close(p)
	if was == kind: return
	var c: Control = Sheet.new(p, game) if kind == &"sheet" else ArenaMap.new(p, game)
	_place(c, p)
	add_child(c)
	_open[p] = c
	if solo() and not get_tree().paused:
		_paused_by_me = true
		get_tree().paused = true

func close(p: Player) -> void:
	if not _open.has(p): return
	(_open[p] as Node).queue_free()
	_open.erase(p)
	if _paused_by_me and _open.is_empty():
		_paused_by_me = false
		get_tree().paused = false

## Cierra todo (Start/Esc abre la pausa después). Devuelve si había algo abierto.
func close_all() -> bool:
	var any := not _open.is_empty()
	for p in _open.keys(): close(p)
	return any

## Solitario: centrado. Cooperativo: en el cuadrante del jugador, sin tapar su panel.
func _place(c: Control, p: Player) -> void:
	if solo():
		if c is Sheet:
			c.anchor_left = 0.08; c.anchor_right = 0.92; c.anchor_top = 0.08; c.anchor_bottom = 0.92
		else:
			c.anchor_left = 0.33; c.anchor_right = 0.67; c.anchor_top = 0.16; c.anchor_bottom = 0.86
		return
	var qx := p.index % 2
	var qy := p.index / 2
	if c is Sheet:                                # la ficha, a lo alto de su lado (se lee)
		c.anchor_left = qx * 0.5 + 0.1; c.anchor_right = qx * 0.5 + 0.4
		c.anchor_top = 0.13; c.anchor_bottom = 0.87
		return
	c.anchor_left = qx * 0.5 + 0.03
	c.anchor_right = qx * 0.5 + 0.47
	c.anchor_top = 0.16 if qy == 0 else 0.52
	c.anchor_bottom = 0.48 if qy == 0 else 0.84


## Ficha del jugador (rehecha el 04-10-2026 con el formato de la selección de personaje):
## tres columnas en un escenario de 1560×860 que se escala al hueco (centrada en solitario,
## en el cuadrante en cooperativo).
##   1. Personaje: modelo, nombre, papel, nivel y experiencia, rasgo; debajo, el compañero
##      con su imagen y lo que hace a su nivel.
##   2. Características y habilidades: atributos (con lo ganado desde el nivel 1) y
##      estadísticas ya actualizadas (tienda, objetos y subidas de nivel).
##   3. Combate: daño total y abatidos; cada arma con su imagen, nivel, descripción, daño y
##      abatidos; cada objeto con su imagen, nivel y efecto.
## Las imágenes se hacen una vez; los valores se refrescan cada segundo.
class Sheet extends Control:
	var p: Player
	var game: Node
	var page := 0                                ## columna a la vista en cooperativo (0..2)
	var paged := false                           ## cooperativo: una columna cada vez, LB/RB
	var design := DESIGN
	var _frames: Array[PanelContainer] = []
	var _title: Label
	var _stage: Control
	var _t := 0.0
	var _dyn: Array[Callable] = []               ## refrescos de los valores
	var _icons := {}
	var _cols: Array[VBoxContainer] = []

	const DESIGN := Vector2(1560, 860)
	const ICONS := "res://resources/PantallasMenus/iconos/ficha_%s.png"
	const STATS := [["health", "vida", "Puntos de vida"], ["sanity", "cordura", "Puntos de cordura"],
		["dodge", "esquive", "Acción de esquiva"], ["speed", "velocidad", "Velocidad"],
		["magic", "magia", "Ataques mágicos"], ["physical", "fisico", "Ataques físicos"],
		["firearm", "fuego", "Ataques balísticos"]]
	const CATEGORY := ["Física", "De fuego", "Mágica"]

	func _init(player: Player, p_game: Node) -> void:
		p = player
		game = p_game
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip_contents = true
		_stage = Control.new()
		_stage.size = DESIGN
		_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_stage)
		var solo := p_game == null or (p_game.get("players") as Array).size() == 1
		paged = not solo                         # en un cuadrante, las tres columnas no se leerían
		if paged: design = Vector2(680, 900)
		_stage.size = design
		var bg := Panel.new()
		bg.size = design
		bg.add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.022, 0.03, 0.95 if solo else 0.85), Color(p.color, 0.8), 12))
		_stage.add_child(bg)
		_title = MenuKit.title("J%d  ·  Ficha del investigador" % (p.index + 1), 30, p.color)
		_title.size = Vector2(design.x, 44)
		_title.position = Vector2(0, 10)
		_stage.add_child(_title)
		var row := HBoxContainer.new()
		row.position = Vector2(20, 60)
		row.size = Vector2(design.x - 40, design.y - 100)
		row.add_theme_constant_override("separation", 16)
		_stage.add_child(row)
		for w in [400, 470, 634]:
			var frame := PanelContainer.new()
			frame.custom_minimum_size = Vector2(640 if paged else w, row.size.y)
			_frames.append(frame)
			frame.add_theme_stylebox_override("panel", UiKit.panel(Color(0.03, 0.033, 0.045, 0.9), Color(p.color, 0.35), 10))
			row.add_child(frame)
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 6)
			frame.add_child(v)
			_cols.append(v)
		var hint := UiKit.label(("LB/RB o Q/E: página  ·  " if paged else "") + "Select, B o Esc: cerrar", 14, UiKit.TEXT_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.size = Vector2(design.x, 24)
		hint.position = Vector2(0, design.y - 34)
		_stage.add_child(hint)

	func _ready() -> void:
		_character(_cols[0])
		_sheet(_cols[1])
		_combat(_cols[2])
		_refresh()
		_show_page()
		resized.connect(_fit)
		_fit.call_deferred()

	func _fit() -> void:
		var k := minf(size.x / design.x, size.y / design.y)
		_stage.scale = Vector2.ONE * k
		_stage.position = (size - design * k) * 0.5

	const PAGE_NAMES: Array[String] = ["Personaje", "Características", "Combate"]

	func turn(step: int) -> void:
		if not paged: return                     # en solitario se ve todo a la vez
		page = wrapi(page + step, 0, _frames.size())
		_show_page()

	func _show_page() -> void:
		if not paged: return
		for i in _frames.size(): _frames[i].visible = i == page
		_title.text = "J%d  ·  %s  (%d/3)" % [p.index + 1, PAGE_NAMES[page], page + 1]

	func _process(delta: float) -> void:
		_t += delta
		if _t >= 1.0:
			_t = 0.0
			_refresh()

	func _refresh() -> void:
		for c in _dyn: c.call()

	# ------------------------------------------------------------ piezas

	func _img(tex: Texture2D, px: int, frame_col := Color(1, 1, 1, 0.15)) -> PanelContainer:
		var f := PanelContainer.new()
		f.add_theme_stylebox_override("panel", UiKit.panel(Color(0, 0, 0, 0.4), frame_col, 6))
		f.custom_minimum_size = Vector2(px, px)
		f.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		f.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(px - 8, px - 8)
		f.add_child(t)
		return f

	func _model(name: String, px: int) -> Texture2D:
		if name == "": return null
		if not _icons.has(name): _icons[name] = ModelIcon.make(self, name, "full", px)
		return _icons[name]

	func _label(text: String, size: int, color := UiKit.TEXT, center := false) -> Label:
		var l := UiKit.label(text, size, color)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if center: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return l

	func _head(col: VBoxContainer, text: String) -> void:
		col.add_child(MenuKit.title(text, 22, UiKit.GOLD))

	## Fila icono + nombre + valor (que se refresca con `value`).
	func _stat_row(col: Container, icon: Texture2D, name: String, value: Callable, gold: Callable = Callable()) -> void:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		var t := TextureRect.new()
		t.texture = icon
		t.custom_minimum_size = Vector2(28, 28)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(t)
		var n := UiKit.label(name, 18, UiKit.TEXT)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		var v := UiKit.label("", 18, UiKit.GOLD)
		h.add_child(v)
		col.add_child(h)
		_dyn.append(func() -> void:
			v.text = String(value.call())
			if gold.is_valid(): v.add_theme_color_override("font_color", UiKit.GOLD if gold.call() else UiKit.TEXT_DIM))

	static func _pct(m: float) -> String:
		var v := roundi((m - 1.0) * 100.0)
		return ("+%d %%" % v) if v >= 0 else ("−%d %%" % -v)

	# ------------------------------------------------------------ 1. personaje

	func _character(col: VBoxContainer) -> void:
		var tex := _model(p.data.model, 300)
		var pic := _img(tex, 230, Color(p.color, 0.5))
		col.add_child(pic)
		col.add_child(MenuKit.title(p.data.display_name, 28, UiKit.TEXT))
		col.add_child(_label(p.data.role, 15, UiKit.TEXT_DIM, true))
		var lvl := _label("", 20, p.color, true)
		col.add_child(lvl)
		var xp := UiKit.Bar.new(UiKit.XP, 340, 10)
		xp.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(xp)
		_dyn.append(func() -> void:
			lvl.text = "Nivel %d" % p.progress.level
			xp.value = p.progress.xp / maxf(p.progress.xp_to_next(), 1.0))
		col.add_child(_label("Rasgo: " + p.data.passive_text, 15, UiKit.TEXT, true))
		# compañero
		var pet: Node = p.get("pet")
		var sep := HSeparator.new()
		col.add_child(sep)
		_head(col, "Compañero")
		if pet == null or not is_instance_valid(pet):
			col.add_child(_label("Sin compañero. Se consiguen en la tienda.", 15, UiKit.TEXT_DIM, true))
			return
		var pd: PetData = pet.get("data")
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		h.add_child(_img(_model(pd.model, 160), 110, Color(UiKit.GOLD, 0.4)))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(_label(pd.display_name, 19, UiKit.GOLD))
		v.add_child(_label(pd.description, 13, UiKit.TEXT_DIM))
		h.add_child(v)
		col.add_child(h)
		var info := _label("", 15, UiKit.TEXT)
		col.add_child(info)
		_dyn.append(func() -> void:
			var s := world_stats()
			var lines := PackedStringArray()
			if pd.attack_damage > 0.0: lines.append("Golpe: %d de daño" % roundi(pd.attack_at(p.progress.level)))
			if pd.bonus > 0.0: lines.append("Bonificación: %s" % _pct(1.0 + pd.bonus_at(p.progress.level)))
			var m: Array = (s.weapons as Dictionary).get("mascota", [0.0, 0])
			lines.append("Daño hecho: %d  ·  Abatidos: %d" % [roundi(m[0]), int(m[1])])
			info.text = "\n".join(lines))

	# ------------------------------------------------------------ 2. características

	func _sheet(col: VBoxContainer) -> void:
		_head(col, "Atributos")
		for n in Attributes.NAMES:
			var nn: String = n
			_stat_row(col, load(ICONS % nn), "%s  ·  %s" % [nn, Attributes.LONG[nn]], func() -> String:
				var now := int(p.attrs.get(nn, Attributes.BASE))
				var gain := now - int(p.attrs_level1.get(nn, Attributes.BASE))
				return "%d%s" % [now, ("  (+%d)" % gain) if gain > 0 else ""],
				func() -> bool: return int(p.attrs.get(nn, Attributes.BASE)) > Attributes.BASE)
		col.add_child(HSeparator.new())
		_head(col, "Estadísticas")
		var base: CharacterData = load("res://data/characters/%s.tres" % p.data.id)
		for row in STATS:
			var k: String = row[0]
			_stat_row(col, load(ICONS % row[1]), row[2], func() -> String:
				match k:
					"health": return "%d / %d" % [ceili(p.health), roundi(p.data.max_health)]
					"sanity": return "%d / %d" % [ceili(p.sanity), roundi(p.data.max_sanity)]
					"speed": return _pct(p.data.move_speed / maxf(base.move_speed, 0.01))
					"dodge": return _pct(base.dodge_cooldown / maxf(p.data.dodge_cooldown, 0.01))
					"magic": return _pct(p.damage_mult(WeaponData.Category.MAGIC))
					"physical": return _pct(p.damage_mult(WeaponData.Category.PHYSICAL))
				return _pct(p.damage_mult(WeaponData.Category.FIREARM)))
		var crisis := _label("", 14, UiKit.SANITY)
		col.add_child(crisis)
		_dyn.append(func() -> void:
			var c := p.sanity_state.crises
			crisis.text = "" if c == 0 else "Crisis sufridas: %d%s" % [c, "  ·  locura acumulada" if p.madness else ""])

	# ------------------------------------------------------------ 3. combate

	func world_stats() -> Dictionary:
		var w: CombatWorld = p.world
		return w.stats_of(p.index) if w != null else {"weapons": {}, "total": [0.0, 0]}

	func _combat(col: VBoxContainer) -> void:
		var tot := _label("", 20, UiKit.GOLD, true)
		col.add_child(tot)
		_dyn.append(func() -> void:
			var t: Array = world_stats().total
			tot.text = "Daño total: %s   ·   Enemigos abatidos: %d" % [MenuKit.money(roundi(t[0])), int(t[1])])
		var ws: Array = p.weapons.weapons if p.weapons != null else []
		_head(col, "Armas  %d / %d" % [ws.size(), p.progress.weapon_slots])
		for w: WeaponSystem.Weapon in ws:
			var card := HBoxContainer.new()
			card.add_theme_constant_override("separation", 10)
			card.add_child(_img(w.data.get_icon(), 64, Color(UiKit.GOLD, 0.45)))
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_theme_constant_override("separation", 0)
			var name := UiKit.label("", 18, UiKit.TEXT)
			v.add_child(name)
			v.add_child(_label("%s. %s" % [CATEGORY[int(w.data.category)], w.data.description], 13, UiKit.TEXT_DIM))
			var num := UiKit.label("", 14, UiKit.GOLD)
			v.add_child(num)
			card.add_child(v)
			col.add_child(card)
			var ww := w
			_dyn.append(func() -> void:
				name.text = "%s  ·  Nv %d/%d" % [ww.data.display_name, ww.level, ww.data.max_level]
				var s: Array = (world_stats().weapons as Dictionary).get(String(ww.data.id), [0.0, 0])
				num.text = "Daño %s  ·  Abatidos %d  ·  %s por golpe" % [MenuKit.money(roundi(s[0])), int(s[1]), str(snappedf(ww.stat("damage") * p.damage_mult(ww.data.category), 0.1))])
		col.add_child(HSeparator.new())
		var owned: Array = []
		for up in p.progress.upgrade_pool:
			if int(p.progress.passives.get(up.id, 0)) > 0: owned.append(up)
		_head(col, "Objetos  %d / %d" % [owned.size(), p.progress.item_slots])
		if owned.is_empty(): col.add_child(_label("Aún no llevas ninguno: salen al subir de nivel.", 14, UiKit.TEXT_DIM))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 12)
		col.add_child(grid)
		for up: UpgradeData in owned:
			var h := HBoxContainer.new()
			h.custom_minimum_size.x = 290
			h.add_child(_img(up.icon, 48, Color(up.color, 0.5)))
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.add_child(UiKit.label("%s  ·  Nv %d/%d" % [up.display_name, int(p.progress.passives.get(up.id, 0)), up.max_level], 15, UiKit.TEXT))
			v.add_child(_label(up.description, 13, UiKit.TEXT_DIM))
			h.add_child(v)
			grid.add_child(h)


## Mapa del nivel: la arena vista desde arriba con la misma orientación que la cámara
## (arriba en el mapa = arriba en la pantalla). Obstáculos, faroles, jugadores (con su
## color), enemigos (las élites, mayores y en violeta) y el enemigo del evento final.
class ArenaMap extends PanelContainer:
	var p: Player
	var game: Node
	var _canvas: Control
	## Zoom (04-10-2026): gatillos del mando (LT aleja, RT acerca) o + y - del teclado. Con
	## zoom, el mapa sigue al jugador. Todo se recorta al marco.
	var zoom := 1.0
	const ZOOM_MIN := 1.0
	const ZOOM_MAX := 4.0

	func _init(player: Player, p_game: Node) -> void:
		p = player
		game = p_game
		var solo := p_game == null or (p_game.get("players") as Array).size() == 1
		add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.025, 0.035, 0.95 if solo else 0.82), Color(p.color, 0.8), 10))
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := VBoxContainer.new()
		add_child(box)
		var t := MenuKit.title("J%d · Mapa del nivel" % (p.index + 1), 24, p.color)
		box.add_child(t)
		_canvas = Control.new()
		_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_canvas.clip_contents = true                   # nada se sale del marco
		_canvas.draw.connect(_draw_map)
		box.add_child(_canvas)
		var hint := UiKit.label("Gatillos o + y −: zoom  ·  Cruceta abajo o M, B o Esc: cerrar", 13, UiKit.TEXT_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(hint)

	func _process(delta: float) -> void:
		var z := _zoom_input()
		if z != 0.0: zoom = clampf(zoom * exp(z * 1.6 * delta), ZOOM_MIN, ZOOM_MAX)
		_canvas.queue_redraw()

	## +1 acercar, −1 alejar, 0 nada: teclado (+/−) si el jugador lo usa, gatillos de su mando.
	func _zoom_input() -> float:
		var z := 0.0
		var devs: Array[int] = []
		var keyboard := false
		var srcs: Array = [p.input]
		if p.input is CombinedInput: srcs = (p.input as CombinedInput).sources
		for s in srcs:
			if s is JoypadInput: devs.append((s as JoypadInput).device)
			elif s is KeyboardInput: keyboard = true
		if keyboard:
			if Input.is_physical_key_pressed(KEY_EQUAL) or Input.is_physical_key_pressed(KEY_KP_ADD) or Input.is_key_pressed(KEY_PLUS): z += 1.0
			if Input.is_physical_key_pressed(KEY_MINUS) or Input.is_physical_key_pressed(KEY_KP_SUBTRACT): z -= 1.0
		for d in devs:
			z += Input.get_joy_axis(d, JOY_AXIS_TRIGGER_RIGHT) - Input.get_joy_axis(d, JOY_AXIS_TRIGGER_LEFT)
		return clampf(z, -1.0, 1.0)

	## Del suelo al mapa: ejes de la pantalla (la arena se ve como un rombo, como en el juego).
	static func project(pos: Vector3) -> Vector2:
		var right := PlayerMotor.screen_to_world(Vector2(1, 0))
		var fwd := PlayerMotor.screen_to_world(Vector2(0, 1))
		return Vector2(pos.dot(right), -pos.dot(fwd))

	func _draw_map() -> void:
		if game == null: return
		var arena: Node3D = game.get("arena")
		var size: Vector2 = arena.get_meta("size") if arena != null else Vector2(60, 60)
		var half := size * 0.5
		var corners := [Vector3(-half.x, 0, -half.y), Vector3(half.x, 0, -half.y), Vector3(half.x, 0, half.y), Vector3(-half.x, 0, half.y)]
		var extent := 0.0
		for c: Vector3 in corners: extent = maxf(extent, project(c).length())
		var area := _canvas.size
		var k := minf(area.x, area.y) * 0.46 / maxf(extent, 1.0) * zoom
		var o := area * 0.5
		if zoom > 1.0: o -= project(p.global_position) * k * clampf((zoom - 1.0) * 2.0, 0.0, 1.0)   # sigue al jugador
		var inside := func(v: Vector3) -> bool: return absf(v.x) <= half.x + 2.0 and absf(v.z) <= half.y + 2.0
		var poly := PackedVector2Array()
		for c: Vector3 in corners: poly.append(o + project(c) * k)
		_canvas.draw_colored_polygon(poly, Color(0.55, 0.62, 0.72, 0.18))       # la arena
		poly.append(poly[0])
		_canvas.draw_polyline(poly, Color(0.75, 0.82, 0.9, 0.5), 2.0)
		var obs: ObstacleMap = arena.get_meta("obstacles") if arena != null and arena.has_meta("obstacles") else null
		if obs != null:
			for c in obs.circles():
				if not inside.call(Vector3(c.x, 0, c.y)): continue        # el mar y el fondo, fuera
				_canvas.draw_circle(o + project(Vector3(c.x, 0, c.y)) * k, maxf(c.z * k, 1.5), Color(0.35, 0.38, 0.42, 0.8))
		if arena != null and arena.has_meta("lights"):
			for l: Node3D in arena.get_meta("lights"):
				if is_instance_valid(l): _canvas.draw_circle(o + project(l.global_position) * k, 3.0, Color(1.0, 0.78, 0.4, 0.9))
		var world: CombatWorld = game.get("world")
		var final_enemy: Node3D = null
		var d: WaveDirector = game.get("director")
		if d != null and is_instance_valid(d._final): final_enemy = d._final
		if world != null:
			for e in world.enemies:
				if not is_instance_valid(e): continue
				var elite: bool = "data" in e and e.data.elite
				var at := o + project(e.global_position) * k
				_canvas.draw_circle(at, 5.0 if elite else 2.2, Color(0.72, 0.36, 1.0) if elite else Color(0.9, 0.3, 0.25, 0.85))
		for c: Node in game.get_tree().get_nodes_in_group(&"chests"):              # baúles arcanos
			if (c as ArcaneChest).is_open: continue
			var at := o + project((c as Node3D).global_position) * k
			_canvas.draw_rect(Rect2(at - Vector2(5, 4), Vector2(10, 8)), Color(1.0, 0.8, 0.35))
		if final_enemy != null:
			_canvas.draw_arc(o + project(final_enemy.global_position) * k, 10.0, 0, TAU, 24, Color(0.9, 0.5, 1.0), 2.0)
		for q: Player in game.get("players"):
			var at := o + project(q.global_position) * k
			var col := q.color if q.health > 0.0 else Color(q.color, 0.4)
			_canvas.draw_circle(at, 6.0 if q == p else 4.5, col)
			if q == p: _canvas.draw_arc(at, 10.0, 0, TAU, 20, Color.WHITE, 1.5)
