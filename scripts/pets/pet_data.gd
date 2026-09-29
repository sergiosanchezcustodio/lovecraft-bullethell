class_name PetData
extends Resource
## Compañero (D-20): se elige en la selección de personaje, acompaña toda la partida y sube
## de nivel con el jugador. Se desbloquean en la tienda. Comportamiento en Pet (hito 2.13c).

@export var id := &"perro"
@export var display_name := "Perro de trineo"
@export var story := "En las montañas de la locura"
@export_multiline var description := ""
@export var price := 0
@export var model := ""                      ## en models/ (vacío: sin modelo todavía)
## BITE: corre a morder a los enemigos cercanos (perro). WARD: reduce el daño mental (gato).
enum Kind { BITE, WARD }
@export var kind := Kind.BITE
@export var bite_damage := 9.0
@export var bite_per_level := 2.0
@export var bite_every := 0.8                ## s entre mordiscos
@export var ward := 0.2                      ## fracción del daño mental que quita
@export var ward_per_level := 0.01
@export var ward_max := 0.35
