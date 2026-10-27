class_name CoopLevelUp
extends CanvasLayer
## Subida de nivel (D-16), en solitario y en cooperativo: la partida se pausa y cada jugador
## que sube elige su mejora con su propio mando o teclado. La partida la abre siempre con un
## solo jugador, en la ventana centrada (`solo`); en cooperativo las subidas van por turnos
## (D-39) y la ventana lleva el color de quien elige (entrada "accent"). Con varias entradas,
## cada una va en su cuadrante (J1 arriba a la izquierda, J2 arriba a la derecha, J3 abajo a
## la izquierda, J4 abajo a la derecha) y eligen a la vez: así era el cooperativo hasta el
## 20-10-2026. Los bots eligen solos. Al elegir, su panel queda marcado; cuando han elegido
## todos, se cierra. `pick` (Callable(player, option)) aplica cada elección en cuanto se hace.
##
## Navegación (30-09-2026): arriba/abajo con el stick, la cruceta o las flechas, repitiendo al
## mantener. La cruceta abajo es también "mapa" (InputBindings.MAP), por eso JoypadInput no la
## da como movimiento y aquí se lee aparte: antes, en el menú, bajar con la cruceta no hacía
## nada. Con el teclado, también 1-3; con el ratón, clic en la tarjeta. Solo la confirmación
## espera INPUT_DELAY al abrirse (venía de jugar); moverse se puede desde el principio.
##
## Tragaperras (03-10-2026): un rodillo bajo el título recorre los siete atributos y se para
## en el que sube (entrada "attr"), y cada tarjeta gira con armas y objetos al azar hasta
## pararse en su opción, una tras otra (REEL_STOPS). Confirmar durante el giro lo para todo;
## elegir solo se puede con los rodillos parados. En cooperativo giran más deprisa (entrada
## "speed", 20-10-2026): con las subidas por turnos hay más pausas.
##
## Llave de plata (D-38): con RB o E, quien la lleva vuelve a tirar sus opciones (las veces que
## le queden en el nivel); los rodillos giran otra vez.
##
## Biblioteca gótica (27-10-2026): el panel es de madera y latón con esquinas (MenuKit.dress), el
## latón teñido del color de quien elige; la tarjeta marcada lleva la luz de vela de los menús.

signal finished

var entries: Array[Dictionary] = []          ## {player, options, title, attr?, accent?, speed?}
var pick: Callable
var solo := false
var _pickers: Array[Picker] = []
var _t := 0.0
var _closing := -1.0
var auto_pick_after := -1.0                  ## pruebas (pick_after=): elige sola la opción marcada a los N s

const INPUT_DELAY := 0.35                    ## sin confirmar al abrirse (venían de jugar)
const BOT_DELAY := 0.8
const CLOSE_DELAY := 0.35
const REPEAT_FIRST := 0.38                   ## al mantener: primera repetición
const REPEAT_NEXT := 0.14                    ## y las siguientes
const ATTR_STOP := 0.5                       ## s en que se para el rodillo del atributo
const REEL_STOPS: Array[float] = [0.7, 0.95, 1.2]   ## y los de cada tarjeta
const HINT := "Arriba y abajo para elegir · A o Intro para confirmar"

## Lo que pasa por los rodillos mientras giran: {icon, title, kind, accent}.
static var _filler: Array[Dictionary] = []

func _init(p_entries: Array[Dictionary], p_pick: Callable, p_solo := false) -> void:
	entries = p_entries
	pick = p_pick
	solo = p_solo
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	add_child(MenuKit.veil(0.75 if solo else 0.55))
	for e in entries:
		var pk := Picker.new(e.player, e.options, e.title, solo, String(e.get("attr", "")), filler(),
			e.get("accent", Color.TRANSPARENT))
		pk.speed = float(e.get("speed", 1.0))
		pk.clicked.connect(func(i: int) -> void:      # el ratón, solo para quien juega con teclado
			if _t >= INPUT_DELAY and not pk.done and _uses_keyboard(pk.player.input): _choose(pk, i))
		add_child(pk)
		_pickers.append(pk)

## Dirección vertical del menú para una entrada: -1 arriba, +1 abajo, 0 nada.
static func nav_dir(inp: PlayerInput) -> int:
	if inp.is_down(InputBindings.MAP) and not (inp is KeyboardInput): return 1   # cruceta abajo
	var m := inp.move
	if absf(m.y) < 0.5 or absf(m.y) < absf(m.x) * 0.8: return 0
	return -1 if m.y > 0.0 else 1                      # arriba en la pantalla = opción anterior

static func filler() -> Array[Dictionary]:
	if _filler.is_empty():
		for w in DamageRules.all_weapons():
			_filler.append({"icon": w.get_icon(), "title": w.display_name, "kind": "ARMA", "accent": UiKit.GOLD})
		for f in DirAccess.get_files_at("res://data/upgrades"):
			if not f.ends_with(".tres"): continue
			var u: UpgradeData = load("res://data/upgrades/" + f)
			_filler.append({"icon": u.icon, "title": u.display_name, "kind": "OBJETO", "accent": u.color})
	return _filler

func _process(delta: float) -> void:
	_t += delta
	for pk in _pickers: pk.spin(delta)
	if _closing >= 0.0:
		_closing += delta
		if _closing >= CLOSE_DELAY:
			finished.emit()
			queue_free()
		return
	for pk in _pickers:
		if pk.done: continue
		var q: Player = pk.player
		if auto_pick_after >= 0.0:                 # pruebas: también los bots esperan
			if _t >= auto_pick_after and pk.settled(): _choose(pk, pk.cursor)
			continue
		if q.input is BotInput:
			if pk.settled() and _t >= BOT_DELAY: _choose(pk, randi() % pk.options.size())
			continue
		q.input.update(delta)                     # con la partida en pausa el jugador no la lee
		var d := nav_dir(q.input)
		if d == 0:
			pk.held = 0
		elif d != pk.held:
			pk.held = d
			pk.repeat_in = REPEAT_FIRST
			pk.move(d)
		else:
			pk.repeat_in -= delta
			if pk.repeat_in <= 0.0:
				pk.repeat_in = REPEAT_NEXT
				pk.move(d)
		if q.input.just_pressed(InputBindings.PAGE_NEXT) and pk.settled():
			pk.reroll()
		if q.input.just_pressed(InputBindings.PAGE_PREV) and pk.settled():
			pk.banish()
		if _t >= INPUT_DELAY and q.input.just_pressed(InputBindings.CONFIRM):
			if pk.settled(): _choose(pk, pk.cursor)
			else: pk.settle()
	if _pickers.all(func(p: Picker) -> bool: return p.done): _closing = 0.0

## Teclas 1-3 (quien juega con teclado).
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo) or _t < INPUT_DELAY: return
	var k := (event as InputEventKey).keycode
	if k < KEY_1 or k > KEY_9: return
	for pk in _pickers:
		if pk.done or not _uses_keyboard(pk.player.input): continue
		if k - KEY_1 < pk.options.size():
			_choose(pk, k - KEY_1)
			get_viewport().set_input_as_handled()
		return

static func _uses_keyboard(inp: PlayerInput) -> bool:
	if inp is KeyboardInput: return true
	if inp is CombinedInput:
		for s in (inp as CombinedInput).sources:
			if s is KeyboardInput: return true
	return false

func _choose(pk: Picker, i: int) -> void:
	if pk.done: return
	if not pk.settled():
		pk.settle()
		return
	pk.mark(i)
	if pick.is_valid(): pick.call(pk.player, pk.options[i])


## Elección de un jugador: tarjetas con la imagen del arma u objeto.
class Picker extends PanelContainer:
	signal clicked(i: int)
	var player: Player
	var options: Array[PlayerProgress.Option] = []
	var cursor := 0
	var done := false
	var held := 0                 ## dirección que se mantiene pulsada (para repetir)
	var repeat_in := 0.0
	var _cards: Array[PanelContainer] = []
	var _status: Label
	# rodillos
	var _time := 0.0
	var _attr := ""
	var _attr_tex: TextureRect
	var _attr_name: Label
	var _attr_i := 0
	var _attr_tick := 0.0
	var _attr_done := true
	var _filler: Array[Dictionary] = []
	var _tex: Array[TextureRect] = []
	var _titles: Array[Label] = []
	var _kinds: Array[Label] = []
	var _descs: Array[Label] = []
	var _frames: Array[PanelContainer] = []
	var _stopped: Array[bool] = []
	var _next_tick: Array[float] = []
	var _solo := false
	var speed := 1.0              ## ritmo de los rodillos (>1, más deprisa)
	var _on_style: StyleBox       ## tarjeta marcada (luz de vela) y las demás
	var _off_style: StyleBox

	func _init(p: Player, p_options: Array[PlayerProgress.Option], title: String, solo := false,
			attr := "", p_filler: Array[Dictionary] = [], p_accent := Color.TRANSPARENT) -> void:
		player = p
		options = p_options
		_attr = attr
		_filler = p_filler
		_solo = solo
		if solo:
			anchor_left = 0.3; anchor_right = 0.7; anchor_top = 0.16; anchor_bottom = 0.84
		else:
			var qx := p.index % 2
			var qy := p.index / 2
			# en su cuadrante, sin tapar el panel del HUD de su esquina
			anchor_left = qx * 0.5 + 0.04
			anchor_right = qx * 0.5 + 0.46
			anchor_top = 0.15 if qy == 0 else 0.52
			anchor_bottom = 0.48 if qy == 0 else 0.85
		var accent := p_accent if p_accent.a > 0.0 else (UiKit.XP if solo else p.color)
		var metal := MenuKit.BRASS if p_accent.a <= 0.0 and solo else MenuKit.BRASS.lerp(accent, 0.5)
		theme = MenuKit.theme()
		_on_style = MenuKit.lit_box(metal, 12 if solo else 8)
		_off_style = MenuKit.box(Color(0.05, 0.036, 0.028, 0.6), Color(metal, 0.2), 1)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12 if solo else 6)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(box)
		if solo: MenuKit.heading(box, title, 40, accent)
		else:
			var head := MenuKit.title(title, 22, accent)
			box.add_child(head)
		if _attr != "":                                          # rodillo del atributo
			var ar := HBoxContainer.new()
			ar.alignment = BoxContainer.ALIGNMENT_CENTER
			ar.add_theme_constant_override("separation", 10)
			ar.add_child(UiKit.label("+1", 26 if solo else 18, UiKit.GOLD))
			var af := PanelContainer.new()
			af.add_theme_stylebox_override("panel", MenuKit.box(Color(0, 0, 0, 0.45), Color(MenuKit.BRASS, 0.8), 1))
			_attr_tex = TextureRect.new()
			_attr_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_attr_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_attr_tex.custom_minimum_size = Vector2.ONE * (40 if solo else 26)
			af.add_child(_attr_tex)
			ar.add_child(af)
			_attr_name = UiKit.label("", 26 if solo else 18, UiKit.TEXT)
			_attr_name.custom_minimum_size.x = 210 if solo else 140
			ar.add_child(_attr_name)
			box.add_child(ar)
			_attr_i = randi() % Attributes.NAMES.size()
			_attr_done = _filler.is_empty()
			_show_attr(_attr if _attr_done else Attributes.NAMES[_attr_i])
		var icon_px := 96 if solo else 52
		for i in options.size():
			var o := options[i]
			var card := PanelContainer.new()
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 14)
			card.add_child(row)
			var frame := PanelContainer.new()
			frame.add_theme_stylebox_override("panel", _frame_style(_accent(o)))
			frame.custom_minimum_size = Vector2(icon_px, icon_px)
			var tex := TextureRect.new()
			tex.texture = _icon(o)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.custom_minimum_size = Vector2(icon_px - 8, icon_px - 8)
			frame.add_child(tex)
			frame.pivot_offset = Vector2(icon_px, icon_px) * 0.5
			row.add_child(frame)
			_tex.append(tex)
			_frames.append(frame)
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_child(col)
			var kind := UiKit.label(_kind(o), 13 if solo else 11, _accent(o))
			col.add_child(kind)
			_kinds.append(kind)
			var t := UiKit.label(("%d  " % (i + 1) if solo else "") + o.title(), 24 if solo else 17, UiKit.TEXT)
			t.add_theme_font_override("font", MenuKit.font())
			col.add_child(t)
			_titles.append(t)
			var d := UiKit.label(o.text(), 17 if solo else 13, UiKit.TEXT_DIM)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(d)
			d.custom_minimum_size.y = (17 if solo else 13) * 2.7     # dos líneas: no cambia de alto al pararse
			_descs.append(d)
			_stopped.append(_filler.is_empty())
			_next_tick.append(0.0)
			card.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: clicked.emit(i))
			card.mouse_entered.connect(func() -> void:
				if not done and (player == null or CoopLevelUp._uses_keyboard(player.input)):
					cursor = i
					_paint())
			box.add_child(card)
			_cards.append(card)
		_status = UiKit.label(hint() if _filler.is_empty() else " ", 15 if solo else 12, UiKit.TEXT_DIM)
		_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(_status)
		_paint()
		for i in options.size():
			if not _stopped[i]: _show_filler(i)
		MenuKit.dress(self, metal, Vector2(34, 26) if solo else Vector2(20, 14), 130.0 if solo else 70.0)

	## Marco del icono de una opción: latón con el color de la opción.
	static func _frame_style(c: Color) -> StyleBoxFlat:
		return MenuKit.box(Color(0, 0, 0, 0.4), Color(MenuKit.BRASS.lerp(c, 0.5), 0.75), 1)

	## Rodillos parados: ya se puede elegir.
	func settled() -> bool:
		return _attr_done and not _stopped.has(false)

	## Para todos los rodillos de golpe (confirmar durante el giro).
	func settle() -> void:
		_time = maxf(_time, REEL_STOPS[REEL_STOPS.size() - 1])
		spin(0.0)

	func spin(delta: float) -> void:
		if settled(): return
		_time += delta * speed
		if not _attr_done:
			if _time >= ATTR_STOP:
				_attr_done = true
				_show_attr(_attr)
				_attr_name.add_theme_color_override("font_color", UiKit.GOLD)
				_pop(_attr_tex.get_parent())
			elif _time >= _attr_tick:
				_attr_i = (_attr_i + 1) % Attributes.NAMES.size()
				_show_attr(Attributes.NAMES[_attr_i])
				_attr_tick = _time + lerpf(0.04, 0.12, pow(_time / ATTR_STOP, 2.0))
		for i in _stopped.size():
			if _stopped[i]: continue
			var stop: float = REEL_STOPS[mini(i, REEL_STOPS.size() - 1)]
			if _time >= stop:
				_stopped[i] = true
				_show_option(i)
				_pop(_frames[i])
			elif _time >= _next_tick[i]:
				_show_filler(i)
				_next_tick[i] = _time + lerpf(0.045, 0.14, pow(_time / stop, 2.0))
		if settled() and not done: _status.text = hint()

	## Ayuda del pie, con los cambios de la Llave de plata si le quedan.
	func hint() -> String:
		var n := player.rerolls_left() if player != null else 0
		var b := player.banishes_left() if player != null else 0
		var extra := PackedStringArray()
		if b > 0: extra.append("LB o Q: descartar (%d)" % b)
		if n > 0: extra.append("RB o E: otras opciones (%d)" % n)
		return HINT + ("\n" + " · ".join(extra) if not extra.is_empty() else "")

	## Cartas del tarot (tienda): la opción marcada se descarta (no vuelve a salir en este
	## nivel) y en su lugar gira otra.
	func banish() -> bool:
		if done or player.banishes_left() <= 0 or options.is_empty(): return false
		var gone := options[cursor]
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		player.progress.banished[PlayerProgress.key_of(gone)] = true
		var taken := options.map(func(o: PlayerProgress.Option) -> String: return PlayerProgress.key_of(o))
		var fresh: PlayerProgress.Option = null
		for o in player.progress.roll_options(player.weapons, rng, 40):
			if not PlayerProgress.key_of(o) in taken:
				fresh = o
				break
		player.banishes_used += 1
		Sfx.play("page")
		if fresh == null:                              # no queda nada más: la opción desaparece
			options.remove_at(cursor)
			cursor = maxi(0, mini(cursor, options.size() - 1))
		else:
			options[cursor] = fresh
		for i in _stopped.size():
			if i >= options.size():
				_frames[i].visible = false
				continue
			if i == cursor and fresh != null and not _filler.is_empty():
				_stopped[i] = false
				_next_tick[i] = 0.0
				_show_filler(i)
			else:
				_show_option(i)
		_time = 0.0
		_status.text = " " if not _filler.is_empty() else hint()
		return true

	## Llave de plata: otras opciones, tantas como antes, y los rodillos vuelven a girar.
	func reroll() -> bool:
		if done or player.rerolls_left() <= 0 or player.weapons == null: return false
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var fresh := player.progress.roll_options(player.weapons, rng, options.size())
		if fresh.size() < options.size(): return false
		options = fresh
		player.rerolls_used += 1
		Sfx.play("magic")
		_time = 0.0
		for i in _stopped.size():
			_stopped[i] = _filler.is_empty()
			_next_tick[i] = 0.0
			if _stopped[i]: _show_option(i)
			else: _show_filler(i)
		_status.text = " " if not _filler.is_empty() else hint()
		return true

	func _show_attr(n: String) -> void:
		_attr_tex.texture = load("res://resources/PantallasMenus/iconos/ficha_%s.png" % n)
		_attr_name.text = Attributes.LONG[n]

	func _show_filler(i: int) -> void:
		var f: Dictionary = _filler[randi() % _filler.size()]
		_tex[i].texture = f.icon
		_tex[i].modulate = Color(1, 1, 1, 0.7)
		_titles[i].text = f.title
		_kinds[i].text = f.kind
		_kinds[i].add_theme_color_override("font_color", f.accent)
		_descs[i].text = " "
		_frames[i].add_theme_stylebox_override("panel", MenuKit.box(Color(0, 0, 0, 0.4), Color(MenuKit.BRASS, 0.3), 1))

	func _show_option(i: int) -> void:
		var o := options[i]
		_tex[i].texture = _icon(o)
		_tex[i].modulate = Color.WHITE
		_titles[i].text = ("%d  " % (i + 1) if _solo else "") + o.title()
		_kinds[i].text = _kind(o)
		_kinds[i].add_theme_color_override("font_color", _accent(o))
		_descs[i].text = o.text()
		_frames[i].add_theme_stylebox_override("panel", _frame_style(_accent(o)))

	func _pop(c: Control) -> void:
		c.scale = Vector2.ONE * 1.25
		var tw := c.create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	static func _icon(o: PlayerProgress.Option) -> Texture2D:
		if o.weapon != null: return o.weapon.get_icon()
		return o.upgrade.icon if o.upgrade != null else null

	static func _accent(o: PlayerProgress.Option) -> Color:
		match o.kind:
			PlayerProgress.Option.Kind.NEW_WEAPON: return UiKit.GOLD
			PlayerProgress.Option.Kind.WEAPON_LEVEL: return Color(1.0, 0.55, 0.25)
		return o.upgrade.color

	static func _kind(o: PlayerProgress.Option) -> String:
		match o.kind:
			PlayerProgress.Option.Kind.NEW_WEAPON: return "ARMA NUEVA"
			PlayerProgress.Option.Kind.WEAPON_LEVEL: return "MEJORA DE ARMA"
		return "OBJETO"

	func move(step: int) -> void:
		if done: return
		cursor = wrapi(cursor + step, 0, options.size())
		_paint()

	func mark(i: int) -> void:
		cursor = i
		done = true
		_status.text = "Elegido: %s · esperando a los demás" % options[i].title()
		_status.add_theme_color_override("font_color", UiKit.GOLD)
		_paint()

	func _paint() -> void:
		for i in _cards.size():
			var on := i == cursor
			_cards[i].add_theme_stylebox_override("panel", _on_style if on else _off_style)
			_cards[i].modulate = Color(1, 1, 1, 0.45) if done and not on else Color.WHITE
