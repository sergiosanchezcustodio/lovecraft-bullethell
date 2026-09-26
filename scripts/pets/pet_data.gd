class_name PetData
extends Resource
## Compañero (D-20): se elige en la selección de personaje, acompaña toda la partida y sube
## de nivel con el jugador. Se desbloquean en la tienda. El catálogo y su comportamiento
## llegan en el hito 2.9; aquí, lo que necesitan los menús.

@export var id := &"perro"
@export var display_name := "Perro de trineo"
@export var story := "En las montañas de la locura"
@export_multiline var description := ""
@export var price := 0
@export var model := ""                      ## en models/ (vacío: sin modelo todavía)
