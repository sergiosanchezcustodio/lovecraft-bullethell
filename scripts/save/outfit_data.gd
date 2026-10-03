class_name OutfitData
extends Resource
## Prenda del vestuario (D-34, hito 2.16; data/outfits/*.tres). Solo estética: se compra
## una vez en la tienda y la puede llevar cualquier personaje. El modelo de cada personaje
## está en models/vest_<id>_<personaje>.json (tools/gen_vestuario.py).

enum Slot { HEAD, BODY, FEET }
const SLOT_NAMES := ["Cabeza", "Cuerpo", "Pies"]
const DIR := "res://data/outfits"

@export var id := &"bombin"
@export var display_name := "Bombín"
@export_multiline var description := ""
@export var slot := Slot.HEAD
@export var price := 1500
@export var order := 0

func model_path(character_model: String) -> String:
	return "res://models/vest_%s_%s.json" % [id, character_model]

static func all() -> Array[OutfitData]:
	var out: Array[OutfitData] = []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".tres"): out.append(load(DIR.path_join(f)))
	out.sort_custom(func(a: OutfitData, b: OutfitData) -> bool: return a.slot < b.slot or (a.slot == b.slot and a.order < b.order))
	return out

static func find(outfit_id: String) -> OutfitData:
	var path := DIR.path_join(outfit_id + ".tres")
	return load(path) if ResourceLoader.exists(path) else null

static func is_head(outfit_id: String) -> bool:
	var o := find(outfit_id)
	return o != null and o.slot == Slot.HEAD

## Lo que lleva puesto un personaje en la partida en uso (o el que fuerza `override`,
## p. ej. la opción de arranque outfit=bombin,botas_nieve para el J1).
static var override := {}
static func worn_for(character_id: String) -> Dictionary:
	if not override.is_empty(): return override
	return Saves.current.worn_by(character_id) if Saves.current != null else {}

## Viste un modelo de personaje con lo que lleva puesto ({"head": id, "body": id, "feet": id}).
static func apply(root: Node3D, character_model: String, worn: Dictionary) -> void:
	for k in worn:
		var o := find(String(worn[k]))
		if o != null: VoxelBuilder.dress(root, o.model_path(character_model), o.slot == Slot.HEAD)
