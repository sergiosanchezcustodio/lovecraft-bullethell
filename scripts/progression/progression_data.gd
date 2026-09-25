class_name ProgressionData
extends Resource
## Reglas de progresión dentro de la partida (data/progression/default.tres).

@export var xp_base := 5.0                 ## experiencia para pasar del nivel 1 al 2
@export var xp_growth := 1.22              ## cada nivel pide este factor más
@export var xp_add := 2.0                  ## y esta cantidad fija más
@export var magnet_speed := 11.0           ## velocidad de las gemas al volar (m/s); el radio es del personaje
@export var options_per_level := 3
@export_group("Cordura")
@export var sanity_regen := 1.2            ## por segundo, lejos de los horrores
@export var sanity_regen_delay := 2.5      ## s sin daño mental antes de recuperar
@export var horror_radius := 5.0           ## a menos de esto de un enemigo no se recupera
@export var crisis_min := 4.0
@export var crisis_max := 6.0
@export var crisis_restore := 0.3          ## fracción de cordura al terminar la crisis
@export var paralysis_period := 1.25       ## una congelación cada tanto (D-14)
@export var paralysis_freeze := 0.4        ## duración de cada congelación
@export var paralysis_warning := 0.2       ## temblor previo

## Experiencia necesaria para pasar del nivel `level` al siguiente.
func xp_to_next(level: int) -> float:
	return roundf(xp_base * pow(xp_growth, level - 1) + xp_add * (level - 1))
