class_name OutfitSets
extends RefCounted
## Conjuntos del vestuario (fase 14, hito 14.8): grupos de prendas con nombre, en
## data/outfit_sets.json. Puesto entero, el conjunto da un rótulo en la ficha y en la selección
## y cuenta para el logro «De punta en blanco» (stats.set_levels). En la tienda se compra lo
## que falta de una vez, con descuento.

const PATH := "res://data/outfit_sets.json"
const DISCOUNT := 0.8                          ## lo que falta, al 80 %

static var _sets: Array = []

## Todos los conjuntos: {id, name, description, pieces: {hueco: prenda}}.
static func all() -> Array:
	if _sets.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary: _sets = (d as Dictionary).get("sets", [])
	return _sets

static func find(id: String) -> Dictionary:
	for s: Dictionary in all():
		if String(s.id) == id: return s
	return {}

## Prendas del conjunto que aún no tiene el hueco.
static func missing(save: SaveData, s: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for k: String in s.pieces:
		var id := String(s.pieces[k])
		if save == null or not save.has_outfit(id): out.append(id)
	return out

## Lo que cuesta completarlo: lo que falta, con descuento, redondeado a 50 $.
static func price(save: SaveData, s: Dictionary) -> int:
	var sum := 0
	for id in missing(save, s):
		var o := OutfitData.find(id)
		if o != null: sum += o.price
	return int(round(sum * DISCOUNT / 50.0)) * 50

static func is_complete(save: SaveData, s: Dictionary) -> bool:
	return missing(save, s).is_empty()

static func can_buy(save: SaveData, s: Dictionary) -> bool:
	return save != null and not is_complete(save, s) and save.money >= price(save, s)

## Compra todo lo que falta. Devuelve si se ha podido.
static func buy(save: SaveData, s: Dictionary) -> bool:
	if not can_buy(save, s): return false
	save.money -= price(save, s)
	for id in missing(save, s): save.outfits.append(id)
	return true

## Nombres de los conjuntos a los que solo les falta esta prenda.
static func completes(save: SaveData, outfit_id: String) -> Array[String]:
	var out: Array[String] = []
	for s: Dictionary in all():
		var m := missing(save, s)
		if m.size() == 1 and m[0] == outfit_id: out.append(String(s.name))
	return out

## Conjunto que se lleva entero ({} si ninguno). Si hay varios, el de más prendas.
static func worn_set(worn: Dictionary) -> Dictionary:
	var best := {}
	for s: Dictionary in all():
		var ok := true
		for k: String in s.pieces:
			if String(worn.get(k, "")) != String(s.pieces[k]):
				ok = false
				break
		if ok and (best.is_empty() or s.pieces.size() > (best.pieces as Dictionary).size()): best = s
	return best

## Nombre del conjunto que se lleva entero ("" si ninguno).
static func worn_name(worn: Dictionary) -> String:
	var s := worn_set(worn)
	return String(s.get("name", ""))

## Las prendas del conjunto como un vestuario puesto ({hueco: prenda}).
static func as_worn(s: Dictionary) -> Dictionary:
	return (s.get("pieces", {}) as Dictionary).duplicate()
