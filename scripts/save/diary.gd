class_name Diary
extends RefCounted
## Diario del investigador (hito 13.10): al terminar cada nivel, superado o no, una entrada en
## primera persona con lo que pasó (el peor minuto, la criatura que más le hirió, quién le
## levantó, el arma que más hizo y cómo queda su cordura). Frases de `data/diary.json`, elegidas
## con una semilla del propio nivel. Se lee en la pantalla final y queda en la Biblioteca (tomo
## «Diarios»), por personaje, en `SaveData.records.diary` (las `MAX` últimas de cada uno).

const DATA := "res://data/diary.json"
const MAX := 40
const MONTHS := ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
	"septiembre", "octubre", "noviembre", "diciembre"]

static var _data := {}

static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_data = d if d is Dictionary else {}
	return _data

## Lo que pasó a un jugador, para `compose`:
## {character, name, level, place, part, result ("won", "lost" o "endless"), t, kills, weapon,
##  creature, worst_min, worst, downs, reviver, sanity (0..1), date ("AAAA-MM-DD")}.
static func facts_of(q: Player, world: CombatWorld, level: LevelData, result: String, t: float) -> Dictionary:
	var best_w := ""
	var best_d := 0.0
	var kills := 0
	if world != null:
		var st: Dictionary = world.stats_of(q.index)
		kills = int(st.total[1])
		for w: String in st.weapons:
			if float(st.weapons[w][0]) > best_d:
				best_d = float(st.weapons[w][0])
				best_w = w
	var best_c := ""
	var best_h := 0.0
	for src: String in q.received:                          # solo criaturas (no la presencia, el icor…)
		if FallReport.OTHERS.has(src) or not ResourceLoader.exists("res://data/enemies/%s.tres" % src): continue
		var h := float(q.received[src][0]) + float(q.received[src][1])
		if h > best_h:
			best_h = h
			best_c = src
	var worst_min := -1
	var worst := 0.0
	for m: int in q.hurt_min:
		if float(q.hurt_min[m]) > worst:
			worst = float(q.hurt_min[m])
			worst_min = m
	var base := Endless.base_of(String(level.id)) if level != null else ""
	return {"character": String(q.data.id), "name": q.data.display_name,
		"level": String(level.id) if level != null else "", "place": DailyMenu._level_name(base) if base != "" else "",
		"part": int(level.part) if level != null else 1, "result": result, "t": t, "kills": kills,
		"weapon": _weapon_name(best_w), "creature": FallReport.name_of(best_c) if best_c != "" else "",
		"worst_min": worst_min + 1, "worst": worst / maxf(q.data.max_health + q.data.max_sanity, 1.0),
		"downs": q.downs, "reviver": q.last_reviver, "sanity": q.sanity / maxf(q.data.max_sanity, 1.0),
		"date": Time.get_date_string_from_system()}

static func _weapon_name(id: String) -> String:
	var path := "res://data/weapons/%s.tres" % id
	return String((load(path) as WeaponData).display_name) if id != "" and ResourceLoader.exists(path) else ""

## La entrada: {title, text}. `seed` decide qué frase sale de cada lista.
static func compose(f: Dictionary, seed_value: int) -> Dictionary:
	var d := data()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var fem := (d.get("female", []) as Array).has(String(f.get("character", "")))
	var fill := {"min": str(int(f.get("worst_min", 1))), "criatura": String(f.get("creature", "")),
		"levanto": String(f.get("reviver", "")), "veces": _times(int(f.get("downs", 0))),
		"arma": String(f.get("weapon", "")), "bajas": str(int(f.get("kills", 0))),
		"tiempo": Endless.clock(float(f.get("t", 0.0))), "o": "a" if fem else "o",
		"desafio": String(f.get("challenge", ""))}
	var out := PackedStringArray()
	var open: Dictionary = d.get("open", {})
	out.append(_one(open.get(String(f.get("result", "won")), open.get("won", [])), rng, fill))
	var worst := float(f.get("worst", 0.0))
	var downs := int(f.get("downs", 0))
	if worst > 0.12: out.append(_one((d.worst as Dictionary).some, rng, fill))
	elif downs == 0 and String(f.get("result", "")) != "lost": out.append(_one((d.worst as Dictionary).none, rng, fill))   # sin caer
	if String(f.get("creature", "")) != "" and worst > 0.05: out.append(_one(d.get("creature", []), rng, fill))
	if downs > 0 and String(f.get("reviver", "")) != "": out.append(_one((d.fall as Dictionary).revived, rng, fill))
	elif downs > 0 and String(f.get("result", "")) == "won": out.append(_one((d.fall as Dictionary).alone, rng, fill))
	if String(f.get("weapon", "")) != "":
		var ws: Array = d.get("weapon", [])
		if int(f.get("kills", 0)) <= 0: ws = ws.filter(func(s: String) -> bool: return not "{bajas}" in s)
		out.append(_one(ws, rng, fill))
	if String(f.get("challenge", "")) != "":         # desafío (15.2): cómo fue, y si es récord
		var r := String(f.get("result", ""))
		var kind := ("record" if bool(f.get("record", false)) else "won") if r == "won" else "lost"
		out.append(_one((d.get("challenge", {}) as Dictionary).get(kind, []), rng, fill))
	var san := float(f.get("sanity", 1.0))
	out.append(_one((d.sanity as Dictionary).get("high" if san > 0.6 else ("mid" if san > 0.3 else "low"), []), rng, fill))
	var body := " ".join(Array(out).filter(func(s: String) -> bool: return s != ""))
	return {"title": "%s — %s" % [story_date(String(f.get("date", "")), int(f.get("part", 1))), String(f.get("place", ""))],
		"text": body + "\n\n— " + String(f.get("name", ""))}

static func _one(list: Array, rng: RandomNumberGenerator, fill: Dictionary) -> String:
	if list.is_empty(): return ""
	var s := String(list[rng.randi() % list.size()]).format(fill)
	return s.left(1).to_upper() + s.substr(1)

static func _times(n: int) -> String:
	return ["", "una vez", "dos veces", "tres veces"][n] if n < 4 else "%d veces" % n

## "30 de octubre de 1927": el día y el mes de hoy, el año de la historia de la parte.
static func story_date(date: String, part: int) -> String:
	var bits := date.split("-")
	var year := int((data().get("years", {}) as Dictionary).get(str(part), 1927))
	if bits.size() < 3: return str(year)
	return "%d de %s de %d" % [int(bits[2]), MONTHS[clampi(int(bits[1]) - 1, 0, 11)], year]

## Guarda la entrada en el diario del personaje (la más nueva primero).
static func add(save: SaveData, character: String, f: Dictionary, entry: Dictionary) -> void:
	if save == null: return
	if not save.records.has("diary"): save.records["diary"] = {}
	var list: Array = save.records.diary.get(character, [])
	list.push_front({"date": f.get("date", ""), "level": f.get("level", ""), "result": f.get("result", ""), "place": f.get("place", ""),
		"title": entry.title, "text": entry.text})
	if list.size() > MAX: list.resize(MAX)
	save.records.diary[character] = list

## Para la lista de la Biblioteca: "30 oct. · El campamento destruido de Lake · caído".
const SHORT_RESULT := {"won": "superado", "lost": "caído", "endless": "noche eterna"}
static func short_title(d: Dictionary) -> String:
	var bits := String(d.get("date", "")).split("-")
	var day := "%d %s." % [int(bits[2]), MONTHS[clampi(int(bits[1]) - 1, 0, 11)].left(3)] if bits.size() >= 3 else ""
	var parts := [day, String(d.get("place", "")), String(SHORT_RESULT.get(String(d.get("result", "")), ""))]
	return " · ".join(PackedStringArray(parts.filter(func(s: String) -> bool: return s != "")))

static func entries(save: SaveData, character: String) -> Array:
	if save == null: return []
	return (save.records.get("diary", {}) as Dictionary).get(character, [])
