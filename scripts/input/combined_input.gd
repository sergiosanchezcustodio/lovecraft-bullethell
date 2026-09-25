class_name CombinedInput
extends PlayerInput
## Varias fuentes para un mismo jugador (en la fase 1, J1 = teclado + primer mando).
## El movimiento es el de la fuente con más recorrido; una acción está pulsada si
## lo está en cualquiera.

var sources: Array[PlayerInput] = []

func _init(p_sources: Array[PlayerInput] = []) -> void:
	sources = p_sources

func update(delta: float) -> void:
	for s in sources: s.update(delta)
	super.update(delta)

func _read_move(_delta: float) -> Vector2:
	var best := Vector2.ZERO
	for s in sources:
		if s.move.length() > best.length(): best = s.move
	return best

func _read_action(action: StringName) -> bool:
	for s in sources:
		if s.is_down(action): return true
	return false

func device_name() -> String:
	return " + ".join(sources.map(func(s: PlayerInput) -> String: return s.device_name()))
