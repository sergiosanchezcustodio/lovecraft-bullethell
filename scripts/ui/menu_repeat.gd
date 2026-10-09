extends Node
## Navegación de los menús al mantener pulsado (autoload MenuRepeat, 09-10-2026).
##
## - Repetición: con un control de menú enfocado, mantener arriba, abajo, izquierda o derecha
##   (cruceta, stick o flechas) repite la dirección: la primera a los FIRST s y las siguientes
##   cada vez más seguidas, de STEP_SLOW a STEP_FAST. Godot no repite los mandos, y el teclado
##   repetía al ritmo del sistema: sus repeticiones se descartan para que todo vaya igual.
## - Desplazamiento suave: los ScrollContainer ya no saltan a la opción enfocada (follow_focus);
##   se deslizan hasta ella en SCROLL_TIME s.
## Los menús que leen los mandos por su cuenta (subida de nivel, selección de personaje) no
## tienen foco de Godot y no se ven afectados; en partida tampoco hay foco.

const DIRS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]
const FIRST := 0.35                          ## s hasta la primera repetición
const STEP_SLOW := 0.13                      ## s entre repeticiones al empezar…
const STEP_FAST := 0.045                     ## …y al cabo de RAMP s manteniendo
const RAMP := 1.6
const SCROLL_TIME := 0.16
const MARGIN := 12.0                         ## px que se deja libres alrededor de la opción

var _held := &""
var _held_t := 0.0
var _next := 0.0
var _tweens := {}                            ## ScrollContainer -> Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

func _input(event: InputEvent) -> void:
	# las repeticiones del teclado del sistema, fuera: repite este nodo, igual que con el mando
	if event is InputEventKey and event.is_echo() and _has_focus():
		for a in DIRS:
			if event.is_action(a):
				get_viewport().set_input_as_handled()
				return

func _process(delta: float) -> void:
	var dir := _pressed_dir()
	if dir == &"" or not _has_focus():
		_held = &""
		return
	if dir != _held:                             # recién pulsada: la primera la da Godot
		_held = dir
		_held_t = 0.0
		_next = FIRST
		return
	_held_t += delta
	if _held_t < _next: return
	_next = _held_t + lerpf(STEP_SLOW, STEP_FAST, clampf((_held_t - FIRST) / RAMP, 0.0, 1.0))
	# solo la pulsación: un "soltar" daría la acción por soltada aunque el botón o el stick
	# sigan pulsados, y se cortaría la repetición
	var ev := InputEventAction.new()
	ev.action = dir
	ev.pressed = true
	Input.parse_input_event(ev)

## La dirección que se mantiene (la primera que esté pulsada), o vacío.
func _pressed_dir() -> StringName:
	for a in DIRS:
		if Input.is_action_pressed(a): return a
	return &""

func _has_focus() -> bool:
	return get_viewport().gui_get_focus_owner() != null

# ---------------- desplazamiento suave ----------------

func _on_node_added(n: Node) -> void:
	if n is ScrollContainer and (n as ScrollContainer).follow_focus:
		(n as ScrollContainer).follow_focus = false
		n.set_meta(&"smooth_focus", true)

func _on_focus_changed(c: Control) -> void:
	if c == null: return
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer and p.has_meta(&"smooth_focus"):
			_scroll_to(p as ScrollContainer, c)
			return
		p = p.get_parent()

## Desliza la lista hasta que la opción quede entera a la vista.
func _scroll_to(sc: ScrollContainer, c: Control) -> void:
	var top := c.get_global_rect().position.y - sc.get_global_rect().position.y + sc.scroll_vertical
	var bottom := top + c.size.y
	var view := sc.size.y
	var target := float(sc.scroll_vertical)
	if top - MARGIN < target: target = top - MARGIN
	elif bottom + MARGIN > target + view: target = bottom + MARGIN - view
	if is_equal_approx(target, float(sc.scroll_vertical)): return
	if _tweens.has(sc) and is_instance_valid(_tweens[sc]): (_tweens[sc] as Tween).kill()
	var tw := sc.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(sc, "scroll_vertical", int(maxf(target, 0.0)), SCROLL_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tweens[sc] = tw
