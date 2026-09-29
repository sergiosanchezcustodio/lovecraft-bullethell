class_name TeamXp
extends RefCounted
## Experiencia compartida del cooperativo (D-07): la que recoge cualquier jugador cuenta
## para todos, todos suben de nivel a la vez y cada uno elige su mejora. La curva se alarga
## según el número de jugadores (ProgressionData.coop_xp_scale).

var rules: ProgressionData
var members: Array[PlayerProgress] = []
var level := 1
var xp := 0.0

func _init(p_rules: ProgressionData, p_members: Array[PlayerProgress]) -> void:
	rules = p_rules
	members = p_members
	for m in members: m.team = self

func xp_to_next() -> float:
	return rules.xp_to_next(level) * rules.coop_xp(members.size())

func add(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		for m in members: m.gain_level()
