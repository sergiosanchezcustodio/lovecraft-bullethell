class_name Library
extends RefCounted
## Biblioteca Lovecraft (03-10-2026): tomos con fichas de todo lo del juego. Solo lo conocido
## muestra su ficha; lo demás sale como "???". Conocido = visto en pantalla (enemigos), tenido
## (armas y objetos, o comprado en la tienda), visitado (lugares) o desbloqueado (personajes y
## compañeros). Lo visto lo apunta la partida en SaveData.seen (game.gd, cada segundo).
## Textos en data/library/textos.json. Sin interfaz: LibraryMenu la dibuja.

const TOMES := [
	{"id": "enemies", "title": "Bestiario", "roman": "I"},
	{"id": "weapons", "title": "Arsenal", "roman": "II"},
	{"id": "items", "title": "Objetos", "roman": "III"},
	{"id": "places", "title": "Lugares", "roman": "IV"},
	{"id": "people", "title": "Investigadores y compañeros", "roman": "V"},
	{"id": "achievements", "title": "Logros", "roman": "VI"},
]
const TEXTS_PATH := "res://data/library/textos.json"
const CATEGORY := ["Física", "De fuego", "Mágica"]

static var _texts := {}

static func text(kind: String, id: String) -> String:
	if _texts.is_empty():
		_texts = JSON.parse_string(FileAccess.get_file_as_string(TEXTS_PATH))
	return String((_texts.get(kind, {}) as Dictionary).get(id, ""))

## Entradas de un tomo: {id, name, known, text, model, mode, icon, facts: Array[String],
## section (subtítulo de grupo, opcional)}.
static func entries(save: SaveData, tome: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match tome:
		"enemies":
			for e: EnemyData in _list("res://data/enemies"):
				var facts := ["Escalón %d%s" % [e.tier, " · élite" if e.elite else ""], "Vida %d" % int(e.max_health),
					"Velocidad %.1f m/s" % e.move_speed]
				if e.aura_drain > 0.0: facts.append("Aura: −%.1f de cordura por segundo" % e.aura_drain)
				out.append(_e(String(e.id), e.display_name, _seen(save, "enemies", e.id), text("enemies", e.id),
					e.model, "full", null, facts))
		"weapons":
			for w in DamageRules.all_weapons():
				var facts := ["%s · %s" % [CATEGORY[w.category], w.description], "Daño %s · cada %.2f s · alcance %d m" % [
					str(snappedf(w.damage, 0.1)), w.cooldown, int(w.range)]]
				if w.sanity_cost > 0.0: facts.append("Cuesta %s de cordura" % str(snappedf(w.sanity_cost, 0.1)))
				out.append(_e(String(w.id), w.display_name, _seen(save, "weapons", w.id), text("weapons", w.id),
					"", "", w.get_icon(), facts))
		"items":
			for u: UpgradeData in _list("res://data/upgrades"):
				out.append(_e(String(u.id), u.display_name, _seen(save, "items", u.id), text("items", u.id),
					"", "", u.icon, [u.description], "En la partida"))
			for it: ShopItem in _list("res://data/shop"):
				var known := save != null and (save.unlock_all or int(save.purchases.get(String(it.id), 0)) > 0)
				var e := _e(String(it.id), it.display_name, known, text("items", it.id), it.icon_model, "full",
					it.icon, [it.description], "De la tienda")
				out.append(e)
		"places":
			var parts := Campaign.parts()
			for l in Campaign.levels():
				var id := String(l.id)
				var known := _seen(save, "places", id) or (save != null and save.levels_won.has(id))
				var p: Dictionary = parts[int(l.part)]
				out.append(_e(id, String(l.name), known, text("places", id), "", "", null,
					["Parte %d · %s (%s) · Nivel %d" % [int(l.part) + 1, p.title, p.place, int(l.number)],
					"Criaturas: " + String(l.get("creatures", ""))], String(p.title)))
		"people":
			var chars := _list("res://data/characters")
			chars.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.order < b.order)
			for c: CharacterData in chars:
				var known := not c.in_shop or (save != null and save.has_character(String(c.id)))
				out.append(_e(String(c.id), c.display_name, known, text("characters", c.id), c.model, "full", null,
					[c.role], "Investigadores"))
			for p: PetData in _list("res://data/pets"):
				var known := save != null and save.has_pet(String(p.id))
				out.append(_e(String(p.id), p.display_name, known, text("pets", p.id), p.model, "full", null,
					[p.description], "Compañeros"))
	return out

static func count_known(save: SaveData, tome: String) -> Vector2i:
	if tome == "achievements":
		var list := Achievements.all()
		return Vector2i(list.filter(func(a: AchievementData) -> bool: return Achievements.is_done(save, a)).size(), list.size())
	var es := entries(save, tome)
	return Vector2i(es.filter(func(e: Dictionary) -> bool: return e.known).size(), es.size())

static func _e(id: String, name: String, known: bool, txt: String, model: String, mode: String,
		icon: Texture2D, facts: Array, section := "") -> Dictionary:
	return {"id": id, "name": name, "known": known, "text": txt, "model": model, "mode": mode,
		"icon": icon, "facts": facts, "section": section}

static func _seen(save: SaveData, kind: String, id: StringName) -> bool:
	return save != null and (save.unlock_all or save.has_seen(kind, String(id)))

static func _list(dir: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".tres"): out.append(load(dir.path_join(f)))
	return out
