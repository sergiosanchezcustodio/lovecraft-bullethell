class_name OutfitData
extends Resource
## Prenda del vestuario (D-34, hito 2.16; data/outfits/*.tres). Solo estética: se compra
## una vez en la tienda y la puede llevar cualquier personaje. El modelo de cada personaje
## está en models/vest_<id>_<personaje>.json (tools/gen_vestuario.py).

## ACCESSORY: gafas, bufanda, collares…; van con cualquier sombrero (no lo ocultan).
## HANDS (fase 14): guantes y lo que se lleva en la mano; BACK: mochila, tentáculo.
enum Slot { HEAD, BODY, FEET, ACCESSORY, HANDS, BACK }
const SLOT_NAMES := ["Cabeza", "Cuerpo", "Pies", "Complemento", "Manos", "Espalda"]
const SECTION_NAMES := ["Cabeza", "Cuerpo", "Pies", "Complementos", "Manos", "Espalda"]   ## en la tienda
const KEYS := ["head", "body", "feet", "acc", "hands", "back"]
## Huecos que, vacíos, no dejan nada ("Ninguno"); los demás dejan la ropa del personaje ("Lo suyo").
const OPTIONAL: Array[int] = [Slot.ACCESSORY, Slot.HANDS, Slot.BACK]
const DIR := "res://data/outfits"

@export var id := &"bombin"
@export var display_name := "Bombín"
@export_multiline var description := ""
@export var slot := Slot.HEAD
@export var price := 1500
@export var order := 0
## Postura del brazo derecho mientras se lleva (fase 14): "" (ninguna), "umbrella" (paraguas en
## alto), "lantern" (linterna delante) o "cane" (bastón). Ver `Player._hold_step`.
@export var hold := ""
## Efecto que acompaña a la prenda: "" o "pipe_smoke" (humo de la pipa de vez en cuando).
@export var fx := ""

## Personaje sobre el que se dibuja el icono de la tienda (la prenda sola, con sus medidas).
@export var icon_char := "dyer"

func model_path(character_model: String) -> String:
	return "res://models/vest_%s_%s.json" % [id, character_model]

## Modelo del icono y la imagen ya dibujada (tools/iconos_vestuario.gd), si la hay.
func icon_model() -> String:
	return "vest_%s_%s" % [id, icon_char]

func icon() -> Texture2D:
	var p := "res://resources/outfits/icons/%s.png" % id
	return load(p) if ResourceLoader.exists(p) else null

static func all() -> Array[OutfitData]:
	var out: Array[OutfitData] = []
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".tres"): out.append(load(DIR.path_join(f)))
	out.sort_custom(func(a: OutfitData, b: OutfitData) -> bool: return a.slot < b.slot or (a.slot == b.slot and a.order < b.order))
	return out

static func find(outfit_id: String) -> OutfitData:
	var path := DIR.path_join(outfit_id + ".tres")
	return load(path) if ResourceLoader.exists(path) else null

## Nombre de lo que deja un hueco vacío: «Ninguno» o «Lo suyo».
static func empty_name(slot: int) -> String:
	return "Ninguno" if OPTIONAL.has(slot) else "Lo suyo"

static func is_head(outfit_id: String) -> bool:
	var o := find(outfit_id)
	return o != null and o.slot == Slot.HEAD

## Lo que lleva puesto un personaje en la partida en uso (o el que fuerza `override`,
## p. ej. la opción de arranque outfit=bombin,botas_nieve para el J1).
static var override := {}
static func worn_for(character_id: String) -> Dictionary:
	if not override.is_empty(): return override
	var remote: Variant = GameSession.remote_worn(character_id)   # jugador de otro PC (en red)
	if remote != null: return remote
	var saves := Auto.node("Saves")                 # autoload, buscado al usarlo (ver Auto)
	var cur: Variant = saves.get("current") if saves else null
	return cur.worn_by(character_id) if cur != null else {}

## Postura de brazo de lo que lleva puesto ("" si nada la pide).
static func hold_of(worn: Dictionary) -> String:
	for k in worn:
		var o := find(String(worn[k]))
		if o != null and o.hold != "": return o.hold
	return ""

## Viste un modelo de personaje con lo que lleva puesto ({"head": id, "body": id, "feet": id, "acc": id}).
static func apply(root: Node3D, character_model: String, worn: Dictionary) -> void:
	for k in worn:
		var o := find(String(worn[k]))
		if o != null: VoxelBuilder.dress(root, o.model_path(character_model), o.slot == Slot.HEAD)
