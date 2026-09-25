class_name CharacterData
extends Resource
## Perfil de un personaje jugable. Los valores se ajustan jugando; aquí solo datos.

@export var id := &"dyer"
@export var display_name := "William Dyer"
@export var model := "dyer"                  ## nombre en models/ (y su juego de animaciones)
@export_group("Recursos")
@export var max_health := 100.0
@export var max_sanity := 100.0
@export_group("Movimiento")
@export var move_speed := 4.5                ## m/s
@export var turn_speed := 14.0               ## rapidez al girar el modelo hacia donde se mueve
@export_group("Esquive")
@export var dodge_speed := 12.0              ## m/s durante el impulso
@export var dodge_duration := 0.25           ## s de impulso
@export var dodge_iframes := 0.32            ## s de invulnerabilidad desde que empieza
@export var dodge_cooldown := 1.2            ## s desde que empieza hasta poder repetir
@export_group("Otros")
@export var luck := 1.0                      ## suerte en las mejoras
@export var pickup_radius := 2.2             ## a qué distancia empiezan a volar las gemas hacia él
## Armas con las que empieza. El GDD da una por personaje; en la fase 1 Dyer empieza
## con la suya y el revólver, como pide la especificación del prototipo.
@export var starting_weapons: Array[StringName] = [&"dinamita"]
@export var collision_radius := 0.32         ## choque con el decorado
@export var hurt_radius := 0.25              ## radio de impacto de las balas: pequeño, como en todo bullet hell
@export var hit_iframes := 0.6               ## s de invulnerabilidad tras recibir un golpe
