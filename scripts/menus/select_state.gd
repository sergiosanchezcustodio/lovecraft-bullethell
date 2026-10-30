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
##
## En red (hito 9.2, D-10) cada PC trae su perfil (lo que tiene desbloqueado en su partida) y
## cada puesto es de un PC (`Seat.peer`) y un dispositivo de ese PC. El anfitrión lleva el
## estado y lo reparte (`seats_to_wire`, `profiles_to_wire`); los invitados lo copian.
## Sin red, todo es del PC `LOCAL`.

signal changed

enum Stage { CHARACTER, OUTFIT, PET, READY }
const OUTFIT_KEYS := OutfitData.KEYS
const LOCAL := 1                         ## PC de los jugadores locales (en red, el anfitrión)

## Lo que tiene un PC en su partida: con qué puede jugar cada uno de sus jugadores.
class Profile:
	var name := ""
	var unlocked: Array = []             ## ids de personajes desbloqueados (además de los de precio 0)
	var pets: Array = [null]             ## PetData desbloqueados; el 0 es "ninguno"
	var outfits: Array = []              ## OutfitData comprados
	var saved_worn := {}                 ## id de personaje -> lo que llevaba la última vez
	var shop := {}                       ## lo comprado en la tienda (`Shop.bonuses`; hito 9.3b: cada uno juega con lo suyo)

	func to_wire() -> Dictionary:
		var p := []
		for x in pets: if x != null: p.append(String((x as PetData).id))
		var o := []
		for x in outfits: o.append(String((x as OutfitData).id))
		return {"name": name, "unlocked": unlocked.duplicate(), "pets": p, "outfits": o, "worn": saved_worn.duplicate(true),
			"shop": shop.duplicate()}

	## Desde un mensaje: solo ids que existen en este juego (`all_pets`: los PetData que hay).
	static func from_wire(d: Variant, all_pets: Array) -> Profile:
		var pr := Profile.new()
		if not d is Dictionary: return pr
		pr.name = String(d.get("name", "")).left(20)
		for id in d.get("unlocked", []):
			if id is String and ResourceLoader.exists("res://data/characters/%s.tres" % id): pr.unlocked.append(id)
		for id in d.get("pets", []):
			for x: PetData in all_pets:
				if String(x.id) == String(id) and not pr.pets.has(x): pr.pets.append(x)
		for id in d.get("outfits", []):
			var o := OutfitData.find(String(id))
			if o != null and not pr.outfits.has(o): pr.outfits.append(o)
		var worn: Variant = d.get("worn", {})
		if worn is Dictionary:
			for c in worn:
				if worn[c] is Dictionary: pr.saved_worn[String(c)] = _clean_worn(worn[c])
		pr.shop = clean_shop(d.get("shop", {}))
		return pr

	## Lo comprado, solo con las claves que existen y en número (vacío: sin datos).
	static func clean_shop(d: Variant) -> Dictionary:
		if not d is Dictionary or (d as Dictionary).is_empty(): return {}
		var out := Shop.DEFAULTS.duplicate()
		for k in out:
			var v: Variant = (d as Dictionary).get(k, out[k])
			if v is float or v is int: out[k] = clampf(float(v), 0.0, 100.0)
		return out

	## Un vestuario con solo prendas que existen, cada una en su hueco.
	static func _clean_worn(w: Dictionary) -> Dictionary:
		var out := {}
		for k in w:
			var o := OutfitData.find(String(w[k]))
			if o != null and OutfitData.KEYS.has(String(k)) and OutfitData.KEYS[int(o.slot)] == String(k): out[String(k)] = String(w[k])
		return out

class Seat:
	var peer := 1                        ## PC del jugador (LOCAL sin red)
	var device := -1
	var character := 0                   ## índice en `characters`
	var pet := 0                         ## índice en los compañeros de su perfil (0 = ninguno)
	var stage := Stage.CHARACTER
	var worn := {}                       ## vestuario elegido: "head"/"body"/"feet" -> id de prenda
	var outfit_row := 0                  ## fila del vestuario con el cursor (OutfitData.Slot)
	var spin := 0                        ## giro del modelo con LB/RB: -1, 0 o 1 (se ve en todos los PC)

var characters: Array[CharacterData] = []
var seats: Array = [null, null, null, null]
var profiles := {LOCAL: Profile.new()}   ## PC -> su perfil

## El perfil del PC local (sin red, el único). Atajos para la pantalla y los tests.
var unlocked_characters: Array:
	get: return (profiles[LOCAL] as Profile).unlocked
	set(v): (profiles[LOCAL] as Profile).unlocked = v
var pets: Array:
	get: return (profiles[LOCAL] as Profile).pets
var outfits: Array:
	get: return (profiles[LOCAL] as Profile).outfits
var saved_worn: Dictionary:
	get: return (profiles[LOCAL] as Profile).saved_worn

func setup(p_characters: Array[CharacterData], p_unlocked: Array, p_pets: Array[PetData],
		p_outfits: Array = [], p_worn: Dictionary = {}) -> SelectState:
	characters = p_characters
	var pr := Profile.new()
	pr.unlocked = p_unlocked
	for p in p_pets: pr.pets.append(p)
	pr.outfits = p_outfits
	pr.saved_worn = p_worn
	profiles = {LOCAL: pr}
	return self

## Perfil de un PC sacado de su partida (sin partida: solo lo gratuito).
static func profile_from_save(save: SaveData, p_characters: Array[CharacterData], all_pets: Array) -> Profile:
	var pr := Profile.new()
	for r: PetData in all_pets:
		if r.price == 0 or (save != null and save.has_pet(String(r.id))): pr.pets.append(r)
	if save == null: return pr
	pr.shop = Shop.bonuses(save)
	for c in p_characters:
		if save.has_character(String(c.id)): pr.unlocked.append(String(c.id))
		pr.saved_worn[String(c.id)] = save.worn_by(String(c.id))
	for o in OutfitData.all():
		if save.has_outfit(String(o.id)): pr.outfits.append(o)
	return pr

## Perfil del PC de un puesto (uno vacío si el PC ya no está).
func profile_of(seat: int) -> Profile:
	var pr: Variant = profiles.get((seats[seat] as Seat).peer if seat >= 0 and seats[seat] != null else LOCAL)
	return pr if pr != null else Profile.new()

func pets_of(seat: int) -> Array:
	return profile_of(seat).pets

func seat_of(device: int, peer: int = LOCAL) -> int:
	for i in seats.size():
		if seats[i] != null and (seats[i] as Seat).device == device and (seats[i] as Seat).peer == peer: return i
	return -1

func joined() -> Array[int]:
	var out: Array[int] = []
	for i in seats.size():
		if seats[i] != null: out.append(i)
	return out

## Puestos de un PC.
func seats_of(peer: int) -> Array[int]:
	var out: Array[int] = []
	for i in joined():
		if (seats[i] as Seat).peer == peer: out.append(i)
	return out

## ¿Está bloqueado el personaje para ese puesto (según lo desbloqueado en su PC)?
func is_locked(ci: int, seat: int = -1) -> bool:
	var c := characters[ci]
	return c.price > 0 and (not Demo.character_ok(c) or not profile_of(seat).unlocked.has(String(c.id)))

## ¿Lo ha confirmado ya otro puesto?
func taken_by_other(ci: int, seat: int) -> bool:
	return holder_of(ci, seat) >= 0

## Puesto (otro que `seat`) que ha confirmado ese personaje, o -1.
func holder_of(ci: int, seat: int) -> int:
	for i in seats.size():
		if i == seat or seats[i] == null: continue
		var s: Seat = seats[i]
		if s.stage != Stage.CHARACTER and s.character == ci: return i
	return -1

## Personajes a los que puede ir un puesto (los que no ha confirmado otro).
func choices(seat: int) -> Array[int]:
	var out: Array[int] = []
	for ci in characters.size():
		if not taken_by_other(ci, seat): out.append(ci)
	return out

## Se une un dispositivo (de un PC) en el primer puesto libre. Devuelve el puesto o -1.
func join(device: int, peer: int = LOCAL) -> int:
	if seat_of(device, peer) >= 0: return -1
	for i in seats.size():
		if seats[i] == null:
			var s := Seat.new()
			s.device = device
			s.peer = peer
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

## Llega un PC a la sala con su perfil (o cambia el que tenía).
func add_profile(peer: int, pr: Profile) -> void:
	profiles[peer] = pr
	changed.emit()

## Se va un PC: libera sus puestos y olvida su perfil.
func remove_peer(peer: int) -> void:
	for i in seats_of(peer): seats[i] = null
	if peer != LOCAL: profiles.erase(peer)
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
			var opts := outfit_options(s.outfit_row, seat)
			var at := opts.find(String(s.worn.get(key, "")))
			var next: String = opts[posmod(at + dir, opts.size())]
			if next == "": s.worn.erase(key)
			else: s.worn[key] = next
		Stage.PET:
			s.pet = posmod(s.pet + dir, pets_of(seat).size())
		_: return
	changed.emit()

## Prendas de una fila del vestuario: "" (lo suyo) y las compradas de ese hueco en el PC del puesto.
func outfit_options(row: int, seat: int = -1) -> Array[String]:
	var out: Array[String] = [""]
	for o: OutfitData in profile_of(seat).outfits:
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
	if s.stage == Stage.CHARACTER: return profile_of(seat).saved_worn.get(String(characters[s.character].id), {})
	return s.worn

## ¿Se puede confirmar el paso actual? (No con un personaje bloqueado o cogido.)
func can_confirm(seat: int) -> bool:
	var s: Seat = seats[seat]
	if s == null or s.stage == Stage.READY: return false
	if s.stage == Stage.CHARACTER: return not is_locked(s.character, seat) and not taken_by_other(s.character, seat)
	return true

## Confirmar: pasa al paso siguiente. Devuelve false si no se puede (bloqueado o cogido).
func confirm(seat: int) -> bool:
	if not can_confirm(seat): return false
	var s: Seat = seats[seat]
	var pr := profile_of(seat)
	match s.stage:
		Stage.CHARACTER:
			s.stage = Stage.PET if pr.outfits.is_empty() else Stage.OUTFIT
			s.worn = (pr.saved_worn.get(String(characters[s.character].id), {}) as Dictionary).duplicate()
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
	changed.emit()
	return true

## Atrás: deshace un paso. Devuelve false si el puesto se ha quedado libre.
func back(seat: int) -> bool:
	var s: Seat = seats[seat]
	if s == null: return false
	match s.stage:
		Stage.READY: s.stage = Stage.PET
		Stage.PET: s.stage = Stage.CHARACTER if profile_of(seat).outfits.is_empty() else Stage.OUTFIT
		Stage.OUTFIT: s.stage = Stage.CHARACTER
		Stage.CHARACTER:
			leave(seat)
			return false
	changed.emit()
	return true

## Aplica una acción de un dispositivo de un PC: "left", "right", "up", "down", "confirm",
## "join", "back", "leave" (se desconecta el mando) o "spin-1", "spin0", "spin1" (LB/RB).
## Devuelve lo que solo tiene que ver ese PC: "shake" (no se puede confirmar), "cursor-1" o
## "cursor1" (mover la marca de la ficha), "freed" (ha dejado su puesto), "exit" (B sin
## ningún puesto en ese PC: salir de la pantalla) o "".
func act(peer: int, device: int, action: String) -> String:
	var seat := seat_of(device, peer)
	if action.begins_with("spin"):
		if seat >= 0: set_spin(seat, clampi(int(action.substr(4)), -1, 1))
		return ""
	if action == "leave":
		if seat >= 0: leave(seat)
		return ""
	if seat < 0:
		if action in ["join", "confirm"]: join(device, peer)
		elif action == "back" and seats_of(peer).is_empty(): return "exit"
		return ""
	match action:
		"up": if not vert(seat, -1): return "cursor-1"
		"down": if not vert(seat, 1): return "cursor1"
		"left": move(seat, -1)
		"right": move(seat, 1)
		"confirm", "join": if not confirm(seat): return "shake"
		"back": if not back(seat): return "freed"
	return ""

## Giro del modelo con LB/RB (-1, 0 o 1).
func set_spin(seat: int, dir: int) -> void:
	var s: Seat = seats[seat]
	if s == null or s.spin == dir: return
	s.spin = dir
	changed.emit()

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

# ---------------------------------------------------------------- red

## Los puestos para mandarlos: con ids de personaje y compañero, no índices.
func seats_to_wire() -> Array:
	var out := []
	for i in seats.size():
		var s: Seat = seats[i]
		if s == null:
			out.append(null)
			continue
		var pet: PetData = pets_of(i)[s.pet] if s.pet < pets_of(i).size() else null
		out.append({"peer": s.peer, "device": s.device, "character": String(characters[s.character].id),
			"pet": String(pet.id) if pet else "", "stage": int(s.stage), "worn": s.worn.duplicate(),
			"row": s.outfit_row, "spin": s.spin})
	return out

## Copia los puestos que manda el anfitrión (los perfiles tienen que haber llegado antes).
func seats_from_wire(arr: Variant) -> void:
	if not arr is Array: return
	for i in seats.size():
		var d: Variant = (arr as Array)[i] if i < (arr as Array).size() else null
		if not d is Dictionary:
			seats[i] = null
			continue
		var s := Seat.new()
		s.peer = int(d.get("peer", LOCAL))
		s.device = int(d.get("device", -1))
		s.character = maxi(0, _char_index(String(d.get("character", ""))))
		s.stage = clampi(int(d.get("stage", 0)), 0, Stage.READY) as Stage
		s.outfit_row = posmod(int(d.get("row", 0)), OUTFIT_KEYS.size())
		s.spin = clampi(int(d.get("spin", 0)), -1, 1)
		s.worn = Profile._clean_worn(d.get("worn", {}) if d.get("worn", {}) is Dictionary else {})
		seats[i] = s
		s.pet = 0
		var pid := String(d.get("pet", ""))
		var list := pets_of(i)
		for k in range(1, list.size()):
			if String((list[k] as PetData).id) == pid: s.pet = k
	changed.emit()

func profiles_to_wire() -> Dictionary:
	var out := {}
	for peer in profiles: out[peer] = (profiles[peer] as Profile).to_wire()
	return out

func profiles_from_wire(d: Variant, all_pets: Array) -> void:
	if not d is Dictionary: return
	profiles = {}
	for peer in d: profiles[int(peer)] = Profile.from_wire(d[peer], all_pets)
	if not profiles.has(LOCAL): profiles[LOCAL] = Profile.new()
	changed.emit()

func _char_index(id: String) -> int:
	for ci in characters.size():
		if String(characters[ci].id) == id: return ci
	return -1
