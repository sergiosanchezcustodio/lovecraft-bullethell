class_name ProgressionData
extends Resource
## Reglas de progresión dentro de la partida (data/progression/default.tres).

@export var xp_base := 5.0                 ## experiencia para pasar del nivel 1 al 2
@export var xp_growth := 1.22              ## cada nivel pide este factor más
@export var xp_add := 2.0                  ## y esta cantidad fija más
@export var magnet_speed := 11.0           ## velocidad de las gemas al volar (m/s); el radio es del personaje
@export var options_per_level := 3
@export_group("Cooperativo")
## Curva de experiencia compartida según los jugadores (1, 2, 3, 4): la del nivel por esto (D-07).
@export var coop_xp_scale: Array[float] = [1.0, 1.5, 1.9, 2.3]
@export var down_time := 30.0              ## s derribado antes de quedar eliminado
@export var revive_time := 3.0             ## s junto al derribado para levantarlo
@export var revive_radius := 1.5           ## m a los que hay que estar
@export var revive_health := 0.35          ## fracción de la vida con la que vuelve
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
## Pesos de cada crisis (hito 2.11); un personaje puede tener los suyos (CharacterData).
@export var crisis_weights := {&"paralisis": 1.0, &"huida": 1.0, &"vagar": 1.0, &"paranoia": 1.0, &"delirio": 1.0}
@export var calm_rate := 1.0               ## compañero al lado: la crisis avanza (1 + esto) veces más rápido
@export var regen_near_light := 2.0        ## recuperación junto a una luz del escenario
@export var regen_near_mate := 1.5         ## y junto a un compañero
@export var light_radius := 3.0            ## m a una farola, hoguera o lámpara
@export var mate_radius := 3.5             ## m a un compañero
@export var madness_step := 0.1            ## locura acumulada: cordura máxima que quita cada crisis
@export var madness_floor := 0.5           ## sin bajar de esta fracción
@export var paranoia_mental := 2.0         ## cordura que quita a un compañero cada disparo del paranoico
@export var flee_speed := 1.15             ## huida: velocidad respecto a la de andar
@export var wander_obey := 0.35            ## vagar: cuánto obedecen los controles
@export var wander_speed := 0.55           ## vagar: velocidad

## Experiencia necesaria para pasar del nivel `level` al siguiente.
func xp_to_next(level: int) -> float:
	return roundf(xp_base * pow(xp_growth, level - 1) + xp_add * (level - 1))

## Multiplicador de la curva de experiencia con n jugadores.
func coop_xp(n: int) -> float:
	if coop_xp_scale.is_empty(): return 1.0
	return coop_xp_scale[clampi(n, 1, coop_xp_scale.size()) - 1]
