class_name SanityState
extends RefCounted
## Cordura de un jugador (GDD 4.4 y 4.5, hito 2.11): recuperación lenta y pasiva lejos de
## los horrores (más rápida cerca de luces y de compañeros: `regen_mult`) y, al llegar a
## cero, una crisis de locura temporal de 4-6 s, elegida al azar con pesos por datos:
## - parálisis: congelaciones intermitentes avisadas con un temblor (D-14);
## - huida histérica: corre sin control lejos del horror más cercano;
## - vagar sin rumbo: movimiento errático y lento que obedece solo en parte;
## - paranoia: sus armas apuntan a los compañeros y les restan cordura (solo en
##   cooperativo, D-17);
## - delirio: controles invertidos.
## Un compañero al lado la acorta (`calm_speed`). Al terminar, recupera una parte de la
## cordura. Cada crisis suma una a `crises` (locura acumulada, la aplica el jugador).

signal crisis_started(kind: StringName)
signal crisis_ended

const KINDS: Array[StringName] = [&"paralisis", &"huida", &"vagar", &"paranoia", &"delirio"]
const NAMES := {&"paralisis": "parálisis", &"huida": "huida histérica", &"vagar": "vagar sin rumbo",
	&"paranoia": "paranoia", &"delirio": "delirio"}

var rules: ProgressionData
var in_crisis := false
var crisis_kind := &""
var crisis_time := 0.0
var crisis_duration := 0.0
var since_mental_hit := 99.0
var rng := RandomNumberGenerator.new()
var weights := {}                          ## pesos propios del personaje (vacío: los de las reglas)
var coop := false                          ## la paranoia solo existe en cooperativo
var regen_mult := 1.0                      ## lo pone el jugador cada paso: luces y compañeros cerca
var calm_speed := 0.0                      ## lo pone el jugador: compañeros calmándolo
var crises := 0                            ## crisis sufridas en el nivel (locura acumulada)
var forced_kind := &""                     ## pruebas: fuerza el tipo de la próxima crisis

func _init(p_rules: ProgressionData) -> void:
	rules = p_rules
	rng.randomize()

func on_mental_damage() -> void:
	since_mental_hit = 0.0

## Avanza la cordura. Devuelve el nuevo valor de cordura del jugador.
func update(delta: float, sanity: float, max_sanity: float, near_horror: bool) -> float:
	since_mental_hit += delta
	if in_crisis:
		crisis_time += delta * (1.0 + calm_speed * rules.calm_rate)     # calmarlo la acorta
		if crisis_time >= crisis_duration:
			in_crisis = false
			crisis_kind = &""
			crisis_ended.emit()
			return max_sanity * rules.crisis_restore
		return 0.0
	if sanity <= 0.0:
		in_crisis = true
		crisis_kind = forced_kind if forced_kind != &"" else pick_kind()
		crisis_time = 0.0
		crisis_duration = rng.randf_range(rules.crisis_min, rules.crisis_max)
		crises += 1
		crisis_started.emit(crisis_kind)
		return 0.0
	if since_mental_hit >= rules.sanity_regen_delay and not near_horror:
		sanity = minf(max_sanity, sanity + rules.sanity_regen * regen_mult * delta)
	return sanity

## Tipo de crisis al azar según los pesos (los del personaje o los de las reglas).
func pick_kind() -> StringName:
	var w: Dictionary = weights if not weights.is_empty() else rules.crisis_weights
	var total := 0.0
	for k in KINDS:
		if k == &"paranoia" and not coop: continue
		total += float(w.get(k, 0.0))
	if total <= 0.0: return &"paralisis"
	var r := rng.randf() * total
	for k in KINDS:
		if k == &"paranoia" and not coop: continue
		r -= float(w.get(k, 0.0))
		if r <= 0.0: return k
	return &"paralisis"

func is_kind(k: StringName) -> bool:
	return in_crisis and crisis_kind == k

## Fracción de la crisis que queda (1 al empezar, 0 al acabar).
func crisis_left() -> float:
	return clampf(1.0 - crisis_time / maxf(crisis_duration, 0.01), 0.0, 1.0) if in_crisis else 0.0

func _cycle() -> float:
	return fmod(crisis_time, rules.paralysis_period)

## Congelado ahora mismo (no puede moverse ni esquivar, pero sigue disparando).
func is_frozen() -> bool:
	if not is_kind(&"paralisis"): return false
	var c := _cycle()
	return c >= rules.paralysis_warning and c < rules.paralysis_warning + rules.paralysis_freeze

## Temblor que avisa de la congelación inmediata.
func is_trembling() -> bool:
	return is_kind(&"paralisis") and _cycle() < rules.paralysis_warning
