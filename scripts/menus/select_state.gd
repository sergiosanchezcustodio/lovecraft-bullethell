class_name SelectState
extends RefCounted
## Lógica de la selección de personaje, sin dibujo (la pantalla la consulta y los tests la
## prueban). Cuatro puestos; cada dispositivo ocupa uno. En su puesto, cada jugador:
##   1. elige personaje (izquierda/derecha); no puede confirmar uno que ya ha confirmado
##      otro (D-23) ni uno bloqueado (se compra en la tienda);
##   2. elige su vestuario (D-34): arriba/abajo cabeza, cuerpo, pies o accesorio, izquierda/derecha la
##      prenda (o lo suyo); se salta si no se ha comprado ninguna prenda;
##   3. elige compañero entre los desbloqueados (o ninguno);
##   4. queda listo.
## Atrás deshace el último paso y, desde el primero, deja el puesto libre.

signal changed

enum Stage { CHARACTER, OUTFIT, PET, READY }
const OUTFIT_KEYS := OutfitData.KEYS

class Seat:
	var device := -1
	var character := 0                   ## índice en `characters`
	var pet := 0                         ## índice en `pets` (0 = ninguno)
	var stage := Stage.CHARACTER
	var worn := {}                       ## vestuario elegido: "head"/"body"/"feet" -> id de prenda
	var outfit_row := 0                  ## fila del vestuario con el cursor (0 cabeza, 1 cuerpo, 2 pies)

var characters: Array[CharacterData] = []
var unlocked_characters: Array = []      ## ids desbloqueados (además de los de precio 0)
var pets: Array = [null]                 ## PetData desbloqueados; el 0 es "ninguno"
var seats: Array = [null, null, null, null]
var outfits: Array = []                  ## OutfitData comprados
var saved_worn := {}                     ## id de personaje -> lo que llevaba la última vez

func setup(p_characters: Array[CharacterData], p_unlocked: Array, p_pets: Array[PetData],
		p_outfits: Array = [], p_worn: Dictionary = {}) -> SelectState:
	characters = p_characters
	outfits = p_outfits
	saved_worn = p_worn
	unlocked_characters = p_unlocked
	pets = [null]
	for p in p_pets: pets.append(p)
	return self

func seat_of(device: int) -> int:
	for i in seats.size():
		if seats[i] != null and (seats[i] as Seat).device == device: return i
	return -1

func joined() -> Array[int]:
	var out: Array[int] = []
	for i in seats.size():
		if seats[i] != null: out.append(i)
	return out

func is_locked(ci: int) -> bool:
	var c := characters[ci]
	return c.price > 0 and not unlocked_characters.has(String(c.id))

## ¿Lo ha confirmado ya otro puesto?
func taken_by_other(ci: int, seat: int) -> bool:
	for i in seats.size():
		if i == seat or seats[i] == null: continue
		var s: Seat = seats[i]
		if s.stage != Stage.CHARACTER and s.character == ci: return true
	return false

## Personajes a los que puede ir un puesto (los que no ha confirmado otro).
func choices(seat: int) -> Array[int]:
	var out: Array[int] = []
	for ci in characters.size():
		if not taken_by_other(ci, seat): out.append(ci)
	return out

## Se une un dispositivo en el primer puesto libre. Devuelve el puesto o -1.
func join(device: int) -> int:
	if seat_of(device) >= 0: return -1
	for i in seats.size():
		if seats[i] == null:
			var s := Seat.new()
			s.device = device
			var c := choices(i)
			# empieza en el primero libre que no esté mirando otro, si lo hay
			var watched := []
			for j in seats.size():
				if seats[j] != null: watched.append((seats[j] as Seat).character)
			s.character = c[0] if not c.is_empty() else 0
			for ci in c:
				if not watched.has(ci):
					s.character = ci
					break
			seats[i] = s
			changed.emit()
			return i
	return -1

func leave(seat: int) -> void:
	seats[seat] = null
	changed.emit()

## Izquierda/derecha: personaje o compañero, según el paso.
func move(seat: int, dir: int) -> void:
	var s: Seat = seats[seat]
	if s == null: return
	match s.stage:
		Stage.CHARACTER:
			var c := choices(seat)
			if c.is_empty(): return
			var at := c.find(s.character)
			s.character = c[posmod((at if at >= 0 else 0) + dir, c.size())]
		Stage.OUTFIT:
			var key: String = OUTFIT_KEYS[s.outfit_row]
			var opts := outfit_options(s.outfit_row)
			var at := opts.find(String(s.worn.get(key, "")))
			var next: String = opts[posmod(at + dir, opts.size())]
			if next == "": s.worn.erase(key)
			else: s.worn[key] = next
		Stage.PET:
			s.pet = posmod(s.pet + dir, pets.size())
		_: return
	changed.emit()

## Prendas de una fila del vestuario: "" (lo suyo) y las compradas de ese hueco.
func outfit_options(row: int) -> Array[String]:
	var out: Array[String] = [""]
	for o: OutfitData in outfits:
		if int(o.slot) == row: out.append(String(o.id))
	return out

## Arriba/abajo en el vestuario. Devuelve false si el puesto no está en ese paso.
func vert(seat: int, dir: int) -> bool:
	var s: Seat = seats[seat]
	if s == null or s.stage != Stage.OUTFIT: return false
	s.outfit_row = posmod(s.outfit_row + dir, OUTFIT_KEYS.size())
	changed.emit()
	return true

## Lo que se ve puesto: lo elegido o, mientras elige personaje, lo que llevaba la última vez.
func worn_of(seat: int) -> Dictionary:
	var s: Seat = seats[seat]
	if s == null: return {}
	if s.stage == Stage.CHARACTER: return saved_worn.get(String(characters[s.character].id), {})
	return s.worn

## Confirmar: pasa al paso siguiente. Devuelve false si no se puede (bloqueado o cogido).
func confirm(seat: int) -> bool:
	var s: Seat = seats[seat]
	if s == null: return false
	match s.stage:
		Stage.CHARACTER:
			if is_locked(s.character) or taken_by_other(s.character, seat): return false
			s.stage = Stage.PET if outfits.is_empty() else Stage.OUTFIT
			s.worn = (saved_worn.get(String(characters[s.character].id), {}) as Dictionary).duplicate()
			s.outfit_row = 0
			# quien estuviera mirando este personaje pasa al siguiente libre
			for i in seats.size():
				if i != seat and seats[i] != null and (seats[i] as Seat).stage == Stage.CHARACTER \
						and (seats[i] as Seat).character == s.character:
					move(i, 1)
		Stage.OUTFIT:
			s.stage = Stage.PET
		Stage.PET:
			s.stage = Stage.READY
		_: return false
	changed.emit()
	return true

## Atrás: deshace un paso. Devuelve false si el puesto se ha quedado libre.
func back(seat: int) -> bool:
	var s: Seat = seats[seat]
	if s == null: return false
	match s.stage:
		Stage.READY: s.stage = Stage.PET
		Stage.PET: s.stage = Stage.CHARACTER if outfits.is_empty() else Stage.OUTFIT
		Stage.OUTFIT: s.stage = Stage.CHARACTER
		Stage.CHARACTER:
			leave(seat)
			return false
	changed.emit()
	return true

## Todos los presentes listos (y al menos uno).
func all_ready() -> bool:
	var j := joined()
	if j.is_empty(): return false
	for i in j:
		if (seats[i] as Seat).stage != Stage.READY: return false
	return true

## Vuelve a todos al paso del compañero (al cancelar el mapa de niveles).
func unready_all() -> void:
	for i in joined():
		if (seats[i] as Seat).stage == Stage.READY: (seats[i] as Seat).stage = Stage.PET
	changed.emit()
