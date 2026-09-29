class_name CoopLevelUp
extends CanvasLayer
## Subida de nivel en cooperativo (D-16): la partida se pausa para todos y cada jugador que
## sube elige su mejora a la vez, en su cuadrante (J1 arriba a la izquierda, J2 arriba a la
## derecha, J3 abajo a la izquierda, J4 abajo a la derecha), con su propio mando: arriba y
## abajo para moverse y A (Intro con el teclado) para confirmar. Los bots eligen solos. Al
## elegir, su panel queda marcado; cuando han elegido todos, se cierra.
## `pick` (Callable(player, option)) aplica cada elección en cuanto se hace.

signal finished

var entries: Array[Dictionary] = []          ## {player, options, title}
var pick: Callable
var _pickers: Array[Picker] = []
var _t := 0.0
var _closing := -1.0

const INPUT_DELAY := 0.5                     ## no acepta pulsaciones al abrirse (venían de jugar)
const BOT_DELAY := 0.8
const CLOSE_DELAY := 0.35

func _init(p_entries: Array[Dictionary], p_pick: Callable) -> void:
	entries = p_entries
	pick = p_pick
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.02, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	for e in entries:
		var pk := Picker.new(e.player, e.options, e.title)
		add_child(pk)
		_pickers.append(pk)

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
		if _t < INPUT_DELAY: continue
		var y := q.input.move.y
		if absf(y) > 0.6 and not pk.stick_held:
			pk.move(-1 if y > 0.0 else 1)             # arriba en la pantalla = opción anterior
		pk.stick_held = absf(y) > 0.35
		if q.input.just_pressed(InputBindings.CONFIRM): _choose(pk, pk.cursor)
	if _pickers.all(func(p: Picker) -> bool: return p.done): _closing = 0.0

func _choose(pk: Picker, i: int) -> void:
	pk.mark(i)
	if pick.is_valid(): pick.call(pk.player, pk.options[i])

## Elección en el cuadrante de un jugador.
class Picker extends PanelContainer:
	var player: Player
	var options: Array[PlayerProgress.Option] = []
	var cursor := 0
	var done := false
	var stick_held := false
	var _cards: Array[PanelContainer] = []
	var _status: Label

	func _init(p: Player, p_options: Array[PlayerProgress.Option], title: String) -> void:
		player = p
		options = p_options
		var qx := p.index % 2
		var qy := p.index / 2
		# en su cuadrante, sin tapar el panel del HUD de su esquina
		anchor_left = qx * 0.5 + 0.04
		anchor_right = qx * 0.5 + 0.46
		anchor_top = 0.17 if qy == 0 else 0.53
		anchor_bottom = 0.47 if qy == 0 else 0.83
		add_theme_stylebox_override("panel", UiKit.panel(Color(0.02, 0.022, 0.03, 0.9), Color(p.color, 0.8), 10))
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 8)
		add_child(box)
		var head := UiKit.label(title, 22, p.color)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(head)
		for o in options:
			var card := PanelContainer.new()
			var l := UiKit.label("%s\n%s" % [o.title(), o.text()], 16, UiKit.TEXT)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(l)
			box.add_child(card)
			_cards.append(card)
		_status = UiKit.label("Arriba y abajo para elegir · A o Intro para confirmar", 13, UiKit.TEXT_DIM)
		_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(_status)
		_paint()

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
