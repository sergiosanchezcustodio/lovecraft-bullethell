class_name TeamXp
extends RefCounted
## Experiencia compartida del cooperativo (D-07): la que recoge cualquier jugador cuenta
## para todos. Las subidas van por turnos (D-39, 20-10-2026, como en Vampire Survivors):
## cada vez que se llena la barra sube un solo jugador, J1, J2, J3, J4 y vuelta a empezar.
## Cada subida cuesta según el nivel de quien tiene el turno, así que cada uno avanza por su
## propia curva; ProgressionData.coop_xp_scale la ajusta al número de jugadores.

var rules: ProgressionData
var members: Array[PlayerProgress] = []
var turn := 0                                ## índice en members de quien sube la próxima vez
var xp := 0.0

func _init(p_rules: ProgressionData, p_members: Array[PlayerProgress]) -> void:
	rules = p_rules
	members = p_members
	for m in members: m.team = self

## Quien sube la próxima vez que se llene la barra.
func next() -> PlayerProgress:
	return members[turn] if not members.is_empty() else null

func xp_to_next() -> float:
	return rules.xp_to_next(next().level) * rules.coop_xp(members.size())

func add(amount: float) -> void:
	if members.is_empty(): return
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		var m := next()
		turn = (turn + 1) % members.size()
		m.gain_level()
