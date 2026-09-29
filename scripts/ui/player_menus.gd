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
		c.anchor_left = 0.33; c.anchor_right = 0.67; c.anchor_top = 0.16; c.anchor_bottom = 0.86
		return
	var qx := p.index % 2
	var qy := p.index / 2
	c.anchor_left = qx * 0.5 + 0.03
	c.anchor_right = qx * 0.5 + 0.47
	c.anchor_top = 0.16 if qy == 0 else 0.52
	c.anchor_bottom = 0.48 if qy == 0 else 0.84


## Ficha del jugador: personaje (atributos, estadísticas y rasgo), armas y objetos.
class Sheet extends PanelContainer:
	var p: Player
	var game: Node
	var page := 0
	var _title: Label
	var _body: VBoxContainer
	var _t := 0.0

	const PAGES: Array[String] = ["Personaje", "Armas", "Objetos"]
	const ICONS := "res://resources/PantallasMenus/iconos/ficha_%s.png"
	## Estadística derivada -> [icono, nombre]
	const STATS := {"health": ["vida", "Puntos de vida"], "sanity": ["cordura", "Puntos de cordura"],
		"dodge": ["esquive", "Acción de esquiva"], "speed": ["velocidad", "Velocidad"],
		"magic": ["magia", "Ataques mágicos"], "physical": ["fisico", "Ataques físicos"],
		"firearm": ["fuego", "Ataques balísticos"]}
	const CATEGORY := ["Física", "De fuego", "Mágica"]

	func _init(player: Player, p_game: Node) -> void:
		p = player
		game = p_game
		var alpha := 0.93 if p_game == null or (p_game.get("players") as Array).size() == 1 else 0.8
		add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.022, 0.03, alpha), Color(p.color, 0.8), 10))
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		add_child(box)
		_title = MenuKit.title("", 24, p.color)
		box.add_child(_title)
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		box.add_child(scroll)
		_body = VBoxContainer.new()
		_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_body.add_theme_constant_override("separation", 4)
		scroll.add_child(_body)
		var hint := UiKit.label("LB/RB o Q/E: página  ·  B o Esc: cerrar", 13, UiKit.TEXT_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(hint)
		_build()

	func turn(step: int) -> void:
		page = wrapi(page + step, 0, PAGES.size())
		_build()

	## Rehace la página cada medio segundo (los valores cambian mientras se juega).
	func _process(delta: float) -> void:
		_t += delta
		if _t >= 0.5:
			_t = 0.0
			_build()

	func _build() -> void:
		_title.text = "J%d · %s  ·  %s  (%d/%d)" % [p.index + 1, p.data.display_name, PAGES[page], page + 1, PAGES.size()]
		for c in _body.get_children(): c.queue_free()
		match page:
			0: _character()
			1: _weapons()
			2: _items()

	func _row(icon: String, name: String, value: String, dim := false) -> void:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		if icon != "":
			var t := TextureRect.new()
			t.texture = load(ICONS % icon)
			t.custom_minimum_size = Vector2(24, 24)
			t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			h.add_child(t)
		var n := UiKit.label(name, 16, UiKit.TEXT)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(UiKit.label(value, 16, UiKit.TEXT_DIM if dim else UiKit.GOLD))
		_body.add_child(h)

	func _text(t: String, size := 15, color := UiKit.TEXT_DIM) -> void:
		var l := UiKit.label(t, size, color)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(l)

	static func _pct(m: float) -> String:
		var v := roundi((m - 1.0) * 100.0)
		return ("+%d %%" % v) if v >= 0 else ("−%d %%" % -v)

	func _character() -> void:
		_text("Nivel %d  ·  Rasgo: %s" % [p.progress.level, p.data.passive_text], 15, UiKit.TEXT)
		_text("Atributos", 17, UiKit.GOLD)
		for n in Attributes.NAMES:
			var now := int(p.attrs.get(n, Attributes.BASE))
			var gain := now - int(p.attrs_level1.get(n, Attributes.BASE))
			_row(n, Attributes.LONG[n], "%d%s" % [now, ("  (+%d)" % gain) if gain > 0 else ""], now <= Attributes.BASE)
		_text("Estadísticas", 17, UiKit.GOLD)
		for k in ["health", "sanity", "dodge", "speed", "magic", "physical", "firearm"]:
			var info: Array = STATS[k]
			var v := ""
			match k:
				"health": v = "%d / %d" % [ceili(p.health), roundi(p.data.max_health)]
				"sanity": v = "%d / %d" % [ceili(p.sanity), roundi(p.data.max_sanity)]
				_: v = _pct(Attributes.mult(p.attrs, k))
			_row(info[0], info[1], v)
		var crises := p.sanity_state.crises
		if crises > 0:
			_text("Crisis sufridas: %d%s" % [crises, "  ·  cordura máxima reducida por la locura" if p.madness else ""], 14, UiKit.SANITY)

	func _weapons() -> void:
		var ws := p.weapons.weapons if p.weapons != null else []
		_text("Armas %d/%d" % [ws.size(), p.progress.weapon_slots], 17, UiKit.GOLD)
		for w: WeaponSystem.Weapon in ws:
			var d := w.data
			_row("", d.display_name, "Nv %d/%d" % [w.level, d.max_level])
			var info := "%s. %s" % [CATEGORY[int(d.category)], d.description]
			if w.level < d.max_level and w.level - 1 < d.level_text.size():
				info += "\nSiguiente nivel: %s" % d.level_text[w.level - 1]
			_text(info, 14)

	func _items() -> void:
		var owned := 0
		for up in p.progress.upgrade_pool:
			if int(p.progress.passives.get(up.id, 0)) > 0: owned += 1
		_text("Objetos %d/%d" % [owned, p.progress.item_slots], 17, UiKit.GOLD)
		if owned == 0: _text("Aún no llevas ninguno: salen al subir de nivel.")
		for up in p.progress.upgrade_pool:
			var lv := int(p.progress.passives.get(up.id, 0))
			if lv <= 0: continue
			_row("", up.display_name, "Nv %d/%d" % [lv, up.max_level])
			_text(up.description, 14)


## Mapa del nivel: la arena vista desde arriba con la misma orientación que la cámara
## (arriba en el mapa = arriba en la pantalla). Obstáculos, faroles, jugadores (con su
## color), enemigos (las élites, mayores y en violeta) y el enemigo del evento final.
class ArenaMap extends PanelContainer:
	var p: Player
	var game: Node
	var _canvas: Control

	func _init(player: Player, p_game: Node) -> void:
		p = player
		game = p_game
		add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.025, 0.035, 0.82), Color(p.color, 0.8), 10))
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var box := VBoxContainer.new()
		add_child(box)
		var t := MenuKit.title("J%d · Mapa del nivel" % (p.index + 1), 24, p.color)
		box.add_child(t)
		_canvas = Control.new()
		_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_canvas.draw.connect(_draw_map)
		box.add_child(_canvas)
		var hint := UiKit.label("Cruceta abajo o M, B o Esc: cerrar", 13, UiKit.TEXT_DIM)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(hint)

	func _process(_delta: float) -> void:
		_canvas.queue_redraw()

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
		var k := minf(area.x, area.y) * 0.48 / maxf(extent, 1.0)
		var o := area * 0.5
		var poly := PackedVector2Array()
		for c: Vector3 in corners: poly.append(o + project(c) * k)
		_canvas.draw_colored_polygon(poly, Color(0.55, 0.62, 0.72, 0.18))       # la arena
		poly.append(poly[0])
		_canvas.draw_polyline(poly, Color(0.75, 0.82, 0.9, 0.5), 2.0)
		var obs: ObstacleMap = arena.get_meta("obstacles") if arena != null and arena.has_meta("obstacles") else null
		if obs != null:
			for c in obs.circles():
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
		if final_enemy != null:
			_canvas.draw_arc(o + project(final_enemy.global_position) * k, 10.0, 0, TAU, 24, Color(0.9, 0.5, 1.0), 2.0)
		for q: Player in game.get("players"):
			var at := o + project(q.global_position) * k
			var col := q.color if q.health > 0.0 else Color(q.color, 0.4)
			_canvas.draw_circle(at, 6.0 if q == p else 4.5, col)
			if q == p: _canvas.draw_arc(at, 10.0, 0, TAU, 20, Color.WHITE, 1.5)
