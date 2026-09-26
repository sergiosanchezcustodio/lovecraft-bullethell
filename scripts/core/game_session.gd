class_name GameSession
extends RefCounted
## Lo que la selección de personaje y el mapa de niveles le pasan a la partida: quién
## juega (dispositivo, personaje y compañero de cada jugador) y en qué nivel. Vive en
## variables estáticas, así que sobrevive al cambio de escena y a los reinicios.
## Vacía (partida lanzada directamente, pruebas): la partida usa sus opciones de siempre.

## Un jugador: hueco (0..3), dispositivo (Devices.KEYBOARD o un mando), su GUID para
## reconocerlo si se reconecta, personaje y compañero ("" = ninguno).
class Seat:
	var slot := 0
	var device := -1
	var guid := ""
	var character := &"dyer"
	var pet := &""

static var seats: Array[Seat] = []
static var level := &"p1_n1"

static func is_set() -> bool:
	return not seats.is_empty()

static func clear() -> void:
	seats.clear()
	level = &"p1_n1"
