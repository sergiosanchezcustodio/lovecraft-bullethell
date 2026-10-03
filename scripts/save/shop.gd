class_name Shop
extends RefCounted
## Tienda (D-31, hito 2.13b): catálogo, compras y efectos, sin interfaz. Cuatro secciones:
## potenciadores permanentes (data/shop, cinco niveles), personajes (CharacterData con
## in_shop y price), compañeros (data/pets) y mejoras (5.º hueco de arma y de objeto).
## Lo comprado va en SaveData: `purchases` (id -> nivel), `characters` y `pets`.

const SECTIONS: Array[String] = ["Potenciadores", "Personajes", "Compañeros", "Mejoras", "Vestuario"]

## Una entrada del catálogo, sea del tipo que sea.
class Entry:
	var id := ""
	var name := ""
	var description := ""
	var section := ShopItem.Section.POWERUP
	var prices: Array[int] = []
	var item: ShopItem
	var character: CharacterData
	var pet: PetData
	var outfit: OutfitData
	var icon: Texture2D                        ## imagen dibujada, si la hay
	var icon_model := ""                       ## si no, el modelo que se renderiza
	var icon_mode := "full"                    ## "head" (retrato) o "full"

## Todo el catálogo, sección a sección.
static func catalog() -> Array[Entry]:
	var out: Array[Entry] = []
	var items: Array = DebugOptions.list_resources("res://data/shop")
	items.sort_custom(func(a: ShopItem, b: ShopItem) -> bool: return a.order < b.order)
	for it: ShopItem in items:
		if it.section != ShopItem.Section.POWERUP: continue
		out.append(_from_item(it))
	var chars: Array = DebugOptions.list_resources("res://data/characters").filter(func(c: CharacterData) -> bool: return c.in_shop)
	chars.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.price < b.price or (a.price == b.price and a.order < b.order))
	for c: CharacterData in chars:
		var e := Entry.new()
		e.id = String(c.id); e.name = c.display_name; e.section = ShopItem.Section.CHARACTER
		e.description = "%s. Rasgo: %s" % [c.role, c.passive_text]
		e.prices = [c.price] as Array[int]
		e.character = c
		e.icon_model = c.model
		e.icon_mode = "head"
		out.append(e)
	var pets: Array = DebugOptions.list_resources("res://data/pets")
	pets.sort_custom(func(a: PetData, b: PetData) -> bool: return a.price < b.price)
	for p: PetData in pets:
		var e := Entry.new()
		e.id = String(p.id); e.name = p.display_name; e.section = ShopItem.Section.PET
		e.description = "%s (%s)." % [p.description.trim_suffix("."), p.story]
		e.prices = [p.price] as Array[int]
		e.pet = p
		e.icon_model = p.model
		out.append(e)
	for it: ShopItem in items:
		if it.section == ShopItem.Section.UPGRADE: out.append(_from_item(it))
	for o in OutfitData.all():                       # vestuario (D-34): para todos los personajes
		var e := Entry.new()
		e.id = String(o.id); e.name = o.display_name; e.section = ShopItem.Section.OUTFIT
		e.description = "%s · %s." % [OutfitData.SLOT_NAMES[o.slot], o.description.trim_suffix(".")]
		e.prices = [o.price] as Array[int]
		e.outfit = o
		e.icon_model = "vest_%s_dyer" % o.id
		out.append(e)
	return out

static func _from_item(it: ShopItem) -> Entry:
	var e := Entry.new()
	e.id = String(it.id); e.name = it.display_name; e.description = it.description
	e.section = it.section; e.prices = it.prices; e.item = it
	e.icon = it.icon; e.icon_model = it.icon_model
	return e

static func in_section(section: int) -> Array[Entry]:
	var out: Array[Entry] = []
	for e in catalog():
		if int(e.section) == section: out.append(e)
	return out

## Nivel comprado (personajes y compañeros: 1 si ya son tuyos).
static func level_of(save: SaveData, e: Entry) -> int:
	if save == null: return 0
	match e.section:
		ShopItem.Section.CHARACTER: return 1 if save.characters.has(e.id) else 0
		ShopItem.Section.PET: return 1 if save.pets.has(e.id) else 0
		ShopItem.Section.OUTFIT: return 1 if save.has_outfit(e.id) else 0
	return int(save.purchases.get(e.id, 0))

static func is_maxed(save: SaveData, e: Entry) -> bool:
	return level_of(save, e) >= e.prices.size()

## Precio del siguiente nivel (-1 si ya está completo).
static func next_price(save: SaveData, e: Entry) -> int:
	var lv := level_of(save, e)
	return e.prices[lv] if lv < e.prices.size() else -1

static func can_buy(save: SaveData, e: Entry) -> bool:
	var p := next_price(save, e)
	return save != null and p >= 0 and save.money >= p

## Compra el siguiente nivel. Devuelve si se ha podido.
static func buy(save: SaveData, e: Entry) -> bool:
	if not can_buy(save, e): return false
	save.money -= next_price(save, e)
	match e.section:
		ShopItem.Section.CHARACTER: save.characters.append(e.id)
		ShopItem.Section.PET: save.pets.append(e.id)
		ShopItem.Section.OUTFIT: save.outfits.append(e.id)
		_: save.purchases[e.id] = level_of(save, e) + 1
	return true

## Efectos de lo comprado en la partida: multiplicadores ("health", "sanity", "damage",
## "speed", "money") y huecos ("weapon_slots", "item_slots", que suman).
static func bonuses(save: SaveData) -> Dictionary:
	var out := {"health": 1.0, "sanity": 1.0, "damage": 1.0, "speed": 1.0, "money": 1.0,
		"weapon_slots": 0, "item_slots": 0}
	if save == null: return out
	for it: ShopItem in DebugOptions.list_resources("res://data/shop"):
		var lv := mini(int(save.purchases.get(String(it.id), 0)), it.max_level())
		if lv <= 0 or not out.has(it.stat): continue
		if it.stat.ends_with("_slots"): out[it.stat] = int(out[it.stat]) + int(it.per_level * lv)
		else: out[it.stat] = float(out[it.stat]) + it.per_level * lv
	return out
