class_name SanityState
extends RefCounted
## Cordura de un jugador: recuperación lenta y pasiva lejos de los horrores y, al llegar
## a cero, una crisis de locura temporal. En la fase 1 la única crisis es la parálisis,
## en forma de congelaciones intermitentes avisadas con un temblor (D-14). Al terminar,
## el personaje recupera una parte de la cordura.

signal crisis_started(kind: StringName)
signal crisis_ended

var rules: ProgressionData
var in_crisis := false
var crisis_kind := &""
var crisis_time := 0.0
var crisis_duration := 0.0
var since_mental_hit := 99.0
var rng := RandomNumberGenerator.new()

func _init(p_rules: ProgressionData) -> void:
	rules = p_rules

func on_mental_damage() -> void:
	since_mental_hit = 0.0

## Avanza la cordura. Devuelve el nuevo valor de cordura del jugador.
func update(delta: float, sanity: float, max_sanity: float, near_horror: bool) -> float:
	since_mental_hit += delta
	if in_crisis:
		crisis_time += delta
		if crisis_time >= crisis_duration:
			in_crisis = false
			crisis_ended.emit()
			return max_sanity * rules.crisis_restore
		return 0.0
	if sanity <= 0.0:
		in_crisis = true
		crisis_kind = &"paralisis"
		crisis_time = 0.0
		crisis_duration = rng.randf_range(rules.crisis_min, rules.crisis_max)
		crisis_started.emit(crisis_kind)
		return 0.0
	if since_mental_hit >= rules.sanity_regen_delay and not near_horror:
		sanity = minf(max_sanity, sanity + rules.sanity_regen * delta)
	return sanity

func _cycle() -> float:
	return fmod(crisis_time, rules.paralysis_period)

## Congelado ahora mismo (no puede moverse ni esquivar, pero sigue disparando).
func is_frozen() -> bool:
	if not in_crisis or crisis_kind != &"paralisis": return false
	var c := _cycle()
	return c >= rules.paralysis_warning and c < rules.paralysis_warning + rules.paralysis_freeze

## Temblor que avisa de la congelación inmediata.
func is_trembling() -> bool:
	return in_crisis and crisis_kind == &"paralisis" and _cycle() < rules.paralysis_warning
