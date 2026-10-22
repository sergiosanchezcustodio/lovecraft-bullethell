class_name GameSession
extends RefCounted
## Lo que la selección de personaje y el mapa de niveles le pasan a la partida: quién
## juega (dispositivo, personaje y compañero de cada jugador) y en qué nivel. Vive en
## variables estáticas, así que sobrevive al cambio de escena y a los reinicios.
## Vacía (partida lanzada directamente, pruebas): la partida usa sus opciones de siempre.

## Un jugador: hueco (0..3), dispositivo (Devices.KEYBOARD o un mando), su GUID para
## reconocerlo si se reconecta, personaje y compañero ("" = ninguno). En red (hito 9.2), el PC
## del que es (`peer`), el nombre de ese PC y su vestuario (el de los demás PC no está en
## nuestra partida).
class Seat:
	var slot := 0
	var device := -1
	var guid := ""
	var character := &"dyer"
	var pet := &""
	var peer := 1
	var name := ""
	var worn := {}
	var shop := {}                       ## lo comprado en la tienda de su PC (vacío: el de este PC)

	## ¿Lo maneja este PC? (Sin red, todos.)
	func is_local() -> bool:
		return peer == GameSession.my_peer

static var seats: Array[Seat] = []
static var level := &"p1_n1"
## Progreso que pasa de un nivel al siguiente dentro de una parte (04-10-2026): por jugador
## (índice 0..3), {level, xp, attrs, attrs_level1, passives, weapons: [[id, nivel]]}. Es
## como empezó el nivel actual: "Reintentar" vuelve a él. Vacío: se empieza de cero.
static var carry: Array = []
static var team_xp := 0.0
static var team_turn := 0                ## cooperativo: a quién le toca la próxima subida (D-39)
static var online := false               ## partida en red (hito 9.2)
static var my_peer := 1                  ## id de este PC en la sala (el anfitrión es el 1)
## Anfitrión (hito 9.5a): PC que ha vuelto con la partida empezada -> PC que se fue, cuyos
## puestos recupera al empezar el siguiente nivel (o al reintentar).
static var returning := {}

static func is_set() -> bool:
	return not seats.is_empty()

static func clear() -> void:
	seats.clear()
	level = &"p1_n1"
	carry.clear()
	team_xp = 0.0
	team_turn = 0
	online = false
	my_peer = 1
	returning.clear()

## Vestuario de un jugador de otro PC con ese personaje, o null si no lo hay (el de los de
## este PC está en nuestra partida).
static func remote_worn(character_id: String) -> Variant:
	for s in seats:
		if String(s.character) == character_id and not s.is_local(): return s.worn
	return null

## Foto del progreso de un jugador para el siguiente nivel.
static func snapshot(q: Player) -> Dictionary:
	var ws := []
	for w in q.weapons.weapons: ws.append([String(w.data.id), w.level])
	return {"level": q.progress.level, "xp": q.progress.xp, "attrs": q.attrs.duplicate(),
		"attrs_level1": q.attrs_level1.duplicate(), "passives": q.progress.passives.duplicate(), "weapons": ws}

## Devuelve a un jugador el progreso guardado (armas, objetos, nivel y atributos).
static func restore(q: Player, d: Dictionary) -> void:
	q.progress.level = int(d.level)
	q.progress.xp = float(d.xp)
	q.progress.pending = 0
	q.progress.passives = (d.passives as Dictionary).duplicate()
	q.attrs = (d.attrs as Dictionary).duplicate()
	q.attrs_level1 = (d.attrs_level1 as Dictionary).duplicate()
	for w in q.weapons.weapons.duplicate(): q.weapons.remove_weapon(w.data.id)
	for e: Array in d.weapons:
		var path := "res://data/weapons/%s.tres" % e[0]
		if not ResourceLoader.exists(path): continue
		var w := q.weapons.add_weapon(load(path))
		w.level = int(e[1])
	q.rebuild_stats()
	q.health = q.data.max_health
	q.sanity = q.data.max_sanity

# ---------------------------------------------------------------- vuelta a la partida (hito 9.5a)

## PC que se fueron (sus puestos los lleva la máquina) y que nadie ha reclamado aún: id -> nombre.
static func departed(connected: Dictionary) -> Dictionary:
	var out := {}
	var claimed := returning.values()
	for s in seats:
		if s.peer != 1 and not connected.has(s.peer) and not claimed.has(s.peer): out[s.peer] = s.name
	return out

## Anfitrión: un PC entra con la partida empezada. Ocupa los puestos de un PC que se fue (el
## del mismo nombre si lo hay; si no, el primero). Devuelve cuántos puestos recupera (0: ninguno).
static func claim(new_peer: int, pc_name: String, connected: Dictionary) -> int:
	var gone := departed(connected)
	if gone.is_empty(): return 0
	var old: int = gone.keys()[0]
	for id: int in gone:
		if String(gone[id]) == pc_name:
			old = id
			break
	returning[new_peer] = old
	return seats.filter(func(s: Seat) -> bool: return s.peer == old).size()

## Anfitrión, al empezar el siguiente nivel: los que han vuelto (y siguen conectados) recuperan
## sus puestos. Devuelve sus ids.
static func apply_returns(connected: Dictionary) -> Array:
	var back := []
	for new_peer: int in returning:
		if not connected.has(new_peer): continue
		for s in seats:
			if s.peer == int(returning[new_peer]):
				s.peer = new_peer
				s.name = String(connected[new_peer].get("name", s.name)) if connected[new_peer] is Dictionary else s.name
		back.append(new_peer)
	returning.clear()
	return back

## Los puestos como los manda START (`NetSelect.fill_session` los lee).
static func seats_to_wire() -> Array:
	var out := []
	for s in seats:
		out.append({"slot": s.slot, "peer": s.peer, "device": s.device, "character": String(s.character),
			"pet": String(s.pet), "worn": s.worn.duplicate(), "name": s.name, "shop": s.shop.duplicate()})
	return out
