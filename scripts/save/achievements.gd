class_name Achievements
extends RefCounted
## Logros (D-32, hito 2.14), sin interfaz: su progreso sale de las estadísticas de la
## partida guardada (SaveData.stats y lo desbloqueado), y al cumplirse se apuntan en
## SaveData.achievements (id -> fecha) y dan su recompensa una sola vez.

const STARTING_CHARACTERS := 4                  ## los de inicio (D-30): Dyer, Olmstead, Peaslee y Whipple

static func all() -> Array[AchievementData]:
	var out: Array[AchievementData] = []
	for r in DebugOptions.list_resources("res://data/achievements"): out.append(r)
	out.sort_custom(func(a: AchievementData, b: AchievementData) -> bool: return a.order < b.order)
	return out

## Valor actual de la estadística de un logro.
static func value(save: SaveData, a: AchievementData) -> int:
	if save == null: return 0
	match a.stat:
		"levels_won": return save.levels_won.size()
		"characters": return STARTING_CHARACTERS + save.characters.size()
	return int(save.stats.get(a.stat, 0))

static func is_done(save: SaveData, a: AchievementData) -> bool:
	return save != null and save.achievements.has(String(a.id))

## Progreso de 0 a 1.
static func progress(save: SaveData, a: AchievementData) -> float:
	if is_done(save, a): return 1.0
	return clampf(float(value(save, a)) / maxf(a.target, 1), 0.0, 1.0)

## Comprueba todos los logros: apunta y recompensa los recién cumplidos y los devuelve.
static func check(save: SaveData) -> Array[AchievementData]:
	var out: Array[AchievementData] = []
	if save == null: return out
	for a in all():
		if is_done(save, a) or value(save, a) < a.target: continue
		save.achievements[String(a.id)] = Time.get_datetime_string_from_system()
		save.money += a.reward_money
		if a.reward_character != &"" and not save.characters.has(String(a.reward_character)):
			save.characters.append(String(a.reward_character))
		if a.reward_pet != &"" and not save.pets.has(String(a.reward_pet)):
			save.pets.append(String(a.reward_pet))
		out.append(a)
	return out

## Texto de la recompensa, para el menú y los avisos.
static func reward_text(a: AchievementData) -> String:
	var parts := PackedStringArray()
	if a.reward_money > 0: parts.append("%s $" % MenuKit.money(a.reward_money))
	if a.reward_character != &"":
		var c: CharacterData = load("res://data/characters/%s.tres" % a.reward_character)
		parts.append(c.display_name if c else String(a.reward_character))
	if a.reward_pet != &"":
		var p: PetData = load("res://data/pets/%s.tres" % a.reward_pet)
		parts.append(p.display_name if p else String(a.reward_pet))
	return " + ".join(parts)

## Sube una estadística a `v` si es mayor (récords: mejor nivel, mejor tiempo).
static func record(save: SaveData, stat: String, v: int) -> void:
	if save != null and v > int(save.stats.get(stat, 0)): save.stats[stat] = v

## Suma a una estadística.
static func add(save: SaveData, stat: String, n: int = 1) -> void:
	if save != null: save.stats[stat] = int(save.stats.get(stat, 0)) + n
