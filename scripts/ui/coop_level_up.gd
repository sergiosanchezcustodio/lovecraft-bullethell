class_name CoopLevelUp
extends CanvasLayer
## Subida de nivel (D-16), en solitario y en cooperativo: la partida se pausa y cada jugador
## que sube elige su mejora con su propio mando o teclado. En cooperativo, cada uno en su
## cuadrante (J1 arriba a la izquierda, J2 arriba a la derecha, J3 abajo a la izquierda, J4
## abajo a la derecha) y a la vez; en solitario, una ventana centrada y más grande. Los bots
## eligen solos. Al elegir, su panel queda marcado; cuando han elegido todos, se cierra.
## `pick` (Callable(player, option)) aplica cada elección en cuanto se hace.
##
## Navegación (30-09-2026): arriba/abajo con el stick, la cruceta o las flechas, repitiendo al
## mantener. La cruceta abajo es también "mapa" (InputBindings.MAP), por eso JoypadInput no la
## da como movimiento y aquí se lee aparte: antes, en el menú, bajar con la cruceta no hacía
## nada. Con el teclado, también 1-3; con el ratón, clic en la tarjeta. Solo la confirmación
## espera INPUT_DELAY al abrirse (venía de jugar); moverse se puede desde el principio.

signal finished

var entries: Array[Dictionary] = []          ## {player, options, title}
var pick: Callable
var solo := false
var _pickers: Array[Picker] = []
var _t := 0.0
var _closing := -1.0

const INPUT_DELAY := 0.35                    ## sin confirmar al abrirse (venían de jugar)
const BOT_DELAY := 0.8
const CLOSE_DELAY := 0.35
const REPEAT_FIRST := 0.38                   ## al mantener: primera repetición
const REPEAT_NEXT := 0.14                    ## y las siguientes

func _init(p_entries: Array[Dictionary], p_pick: Callable, p_solo := false) -> void:
	entries = p_entries
	pick = p_pick
	solo = p_solo
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.55 if solo else 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	for e in entries:
		var pk := Picker.new(e.player, e.options, e.title, solo)
		pk.clicked.connect(func(i: int) -> void:
			if _t >= INPUT_DELAY and not pk.done: _choose(pk, i))
		add_child(pk)
		_pickers.append(pk)

## Dirección vertical del menú para una entrada: -1 arriba, +1 abajo, 0 nada.
static func nav_dir(inp: PlayerInput) -> int:
	if inp.is_down(InputBindings.MAP) and not (inp is KeyboardInput): return 1   # cruceta abajo
	var m := inp.move
	if absf(m.y) < 0.5 or absf(m.y) < absf(m.x) * 0.8: return 0
	return -1 if m.y > 0.0 else 1                      # arriba en la pantalla = opción anterior

func _process(delta: float) -> void:
	_t += delta
	if _closing >= 0.0:
		_closing += delta
		if _closing >= CLOSE_DELAY:
			finished.emit()
			queue_free()
		return
	for pk in _pickers:
		if pk.done: continue
		var q: Player = pk.player
		if q.input is BotInput:
			if _t >= BOT_DELAY: _choose(pk, randi() % pk.options.size())
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
		if _t >= INPUT_DELAY and q.input.just_pressed(InputBindings.CONFIRM): _choose(pk, pk.cursor)
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

	func _init(p: Player, p_options: Array[PlayerProgress.Option], title: String, solo := false) -> void:
		player = p
		options = p_options
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
		var accent := UiKit.XP if solo else p.color
		add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.022, 0.03, 0.92), Color(accent, 0.8), 10))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 12 if solo else 6)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(box)
		var head := UiKit.label(title, 32 if solo else 20, accent)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(head)
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
			frame.add_theme_stylebox_override("panel", UiKit.panel(Color(0, 0, 0, 0.35), Color(_accent(o), 0.6), 6))
			frame.custom_minimum_size = Vector2(icon_px, icon_px)
			var tex := TextureRect.new()
			tex.texture = _icon(o)
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.custom_minimum_size = Vector2(icon_px - 8, icon_px - 8)
			frame.add_child(tex)
			row.add_child(frame)
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.alignment = BoxContainer.ALIGNMENT_CENTER
			row.add_child(col)
			var kind := UiKit.label(_kind(o), 13 if solo else 11, _accent(o))
			col.add_child(kind)
			var t := UiKit.label(("%d  " % (i + 1) if solo else "") + o.title(), 24 if solo else 17, UiKit.TEXT)
			col.add_child(t)
			var d := UiKit.label(o.text(), 17 if solo else 13, UiKit.TEXT_DIM)
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(d)
			card.gui_input.connect(func(ev: InputEvent) -> void:
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: clicked.emit(i))
			card.mouse_entered.connect(func() -> void:
				if not done:
					cursor = i
					_paint())
			box.add_child(card)
			_cards.append(card)
		_status = UiKit.label("Arriba y abajo para elegir · A o Intro para confirmar", 15 if solo else 12, UiKit.TEXT_DIM)
		_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(_status)
		_paint()

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
			var border := Color(UiKit.GOLD, 0.95) if on else Color(1, 1, 1, 0.12)
			var bg := Color(0.12, 0.1, 0.06, 0.95) if on else Color(0.05, 0.05, 0.07, 0.8)
			_cards[i].add_theme_stylebox_override("panel", UiKit.panel(bg, border, 6))
			_cards[i].modulate = Color(1, 1, 1, 0.45) if done and not on else Color.WHITE
