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
	{"id": "diary", "title": "Diarios", "roman": "VII"},
	{"id": "stories", "title": "Relatos", "roman": "VIII"},
	{"id": "wardrobe", "title": "Vestuario", "roman": "IX"},
]
const EPILOGUES := [["epilogo", "Epílogo · Lo que vino después"], ["epilogo_locura", "Epílogo · El que no volvió del todo"]]
const RESULTS := {"won": "Superado", "lost": "Caído", "endless": "La noche eterna"}
const TEXTS_PATH := "res://data/library/textos.json"
const CATEGORY := ["Física", "De fuego", "Mágica"]

static var _texts := {}

static func text(kind: String, id: String) -> String:
	if _texts.is_empty():
		_texts = JSON.parse_string(FileAccess.get_file_as_string(TEXTS_PATH))
	return String((_texts.get(kind, {}) as Dictionary).get(id, ""))

## Entradas de un tomo: {id, name, known, text, model, mode, icon, facts: Array[String],
## section (subtítulo de grupo, opcional)}. Las del vestuario llevan además worn (lo que viste
## el modelo) y dim (aún no se tiene entero: el nombre se lee, el modelo sale en sombra).
static func entries(save: SaveData, tome: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match tome:
		"wardrobe":                                    # conjuntos del vestuario (fase 14)
			for s: Dictionary in OutfitSets.all():
				var done := save != null and (save.unlock_all or OutfitSets.is_complete(save, s))
				var names := PackedStringArray()
				var lack := PackedStringArray()
				var miss := OutfitSets.missing(save, s) if save != null else []
				for k: String in s.pieces:
					var o := OutfitData.find(String(s.pieces[k]))
					if o == null: continue
					names.append(o.display_name)
					if not done and miss.has(String(o.id)): lack.append(o.display_name)
				var facts := [", ".join(names)]
				if done: facts.append("Completo")
				elif lack.size() == names.size(): facts.append("Aún no tienes ninguna de sus prendas: están en la tienda.")
				else: facts.append("Te falta: " + ", ".join(lack))
				var e := _e(String(s.id), String(s.name), true, String(s.description), String(s.get("shown", "dyer")), "full",
					null, facts, "Conjuntos")
				e["worn"] = OutfitSets.as_worn(s)
				e["dim"] = not done
				out.append(e)
			var all := OutfitData.all()                # y las prendas sueltas, por hueco
			all.sort_custom(func(a: OutfitData, b: OutfitData) -> bool: return a.slot < b.slot or (a.slot == b.slot and a.order < b.order))
			for o in all:
				var mine := save != null and (save.unlock_all or save.has_outfit(String(o.id)))
				var e := _e(String(o.id), o.display_name, true, o.description, "", "", o.icon(),
					["%s · %s $" % [OutfitData.SECTION_NAMES[o.slot], MenuKit.money(o.price)], "Tuya" if mine else "En la tienda"],
					"Prendas · " + OutfitData.SECTION_NAMES[o.slot])
				e["dim"] = not mine
				out.append(e)
		"stories":                                     # páginas sueltas y epílogos (hito 13.11)
			for s: Dictionary in Fragments.stories():
				var pages: Array = s.pages
				for i in pages.size():
					var lv := String(pages[i].level)
					var facts := [String(s.intro)] if i == 0 else []
					facts.append("Página %d de %d · %s" % [i + 1, pages.size(), DailyMenu._level_name(lv)])
					var e := _e(lv, "Página %d" % (i + 1), save != null and (save.unlock_all or Fragments.has(save, lv)),
						String(pages[i].text), "", "", null, facts, String(s.title))
					e["title"] = String(s.title)                # en la página, el relato
					out.append(e)
			var rel: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/library/relatos.json"))
			for ep: Array in EPILOGUES:
				var lines: Array = (rel as Dictionary).get(ep[0], []) if rel is Dictionary else []
				var txt := "

".join(PackedStringArray(lines.map(func(l: String) -> String:
					var t := l.format({"nombre": "el investigador"}).replace(" de el ", " del ")
					return t.left(1).to_upper() + t.substr(1))))
				out.append(_e(String(ep[0]), String(ep[1]), _seen(save, "epilogues", StringName(ep[0])), txt, "", "", null,
					["Tras vencer a Cthulhu" + (" con menos de un cuarto de la cordura" if ep[0] == "epilogo_locura" else "")], "Epílogos"))
		"diary":                                       # diarios de los investigadores (hito 13.10)
			var chars := _list("res://data/characters")
			chars.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.order < b.order)
			for c: CharacterData in chars:
				for d: Dictionary in Diary.entries(save, String(c.id)):
					var e := _e(String(c.id), Diary.short_title(d), true, String(d.get("text", "")), "", "", null,
						[String(RESULTS.get(String(d.get("result", "")), ""))], c.display_name)
					e["title"] = String(d.get("title", ""))     # en la página, el título entero
					out.append(e)
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
				if w.evolution != &"":                        # D-06
					var up: UpgradeData = load("res://data/upgrades/%s.tres" % w.evolves_with)
					var ev: WeaponData = load("res://data/weapons/%s.tres" % w.evolution)
					facts.append("Al nivel %d con %s, un baúl arcano la convierte en %s" % [w.max_level, up.display_name, ev.display_name if _seen(save, "weapons", ev.id) else "???"])
				if w.evolved: facts.append("Evolución")
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
				var map_path := "res://resources/maps/%s.png" % id
				var map: Texture2D = load(map_path) if ResourceLoader.exists(map_path) else null
				out.append(_e(id, String(l.name), known, text("places", id), "", "", map,
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
	return Vector2i(es.filter(func(e: Dictionary) -> bool: return e.known and not e.get("dim", false)).size(), es.size())

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
