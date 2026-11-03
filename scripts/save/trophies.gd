class_name Trophies
extends RefCounted
## Sala de trofeos (hito 16.28): lo que va en las tres vitrinas de la Biblioteca y si ya está
## ganado. Sin interfaz (la dibuja TrophyRoom).
##   0 Conjuntos: un maniquí (el investigador que lo enseña, con el conjunto puesto) por conjunto
##     del vestuario completo;
##   1 Jefes: una figura por jefe vencido (seres únicos de escalón 4 y 5, en el orden de la
##     campaña), con cuántas veces y quién lo abatió más;
##   2 Logros: un trofeo por logro grande (los de 500 $ de recompensa o más).
## Cada trofeo: {case, id, name, kind, model, worn, earned, text, facts}.

const CASES: Array[String] = ["Conjuntos completos", "Jefes vencidos", "Logros grandes"]
const CASE_MODELS: Array[String] = ["vitrina_6x3", "vitrina_7x3", "vitrina_4x3"]
const CASE_COLS: Array[int] = [6, 7, 4]
const BIG_REWARD := 500                         ## un logro es «grande» desde esta recompensa
## Modelo del trofeo de cada logro grande (los que no estén, la copa).
const ACHIEVEMENT_MODELS := {
	"cazador_10000": "trofeo_copa", "elites_25": "trofeo_frasco", "baules_50": "trofeo_cofre",
	"rico": "icono_codicia", "coleccionista": "trofeo_retrato", "tres_sellos": "trofeo_sellos",
	"siete_noches": "trofeo_candelabro", "bibliotecario": "trofeo_atril", "no_volvio": "cth_idolo",
	"punta_en_blanco": "trofeo_maniqui", "fiel_al_conjunto": "trofeo_medalla",
	"todos_los_desafios": "trofeo_copa_negra",
}

static var _bosses: Array[EnemyData] = []

## Los jefes en el orden en que salen en la campaña (dentro de cada nivel, los intermedios antes).
static func bosses() -> Array[EnemyData]:
	if not _bosses.is_empty(): return _bosses
	var seen := {}
	var c: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/campaign.json"))
	for part: Dictionary in (c as Dictionary).get("parts", []):
		for l: Variant in part.get("levels", []):
			var lid := String((l as Dictionary).id) if l is Dictionary else String(l)
			var path := "res://data/levels/%s.tres" % lid
			if not ResourceLoader.exists(path): continue
			var here: Array[EnemyData] = []
			var txt := FileAccess.get_file_as_string(path)
			var rx := RegEx.create_from_string("res://data/enemies/(\\w+)\\.tres")
			for m in rx.search_all(txt):
				var id := m.get_string(1)
				if seen.has(id): continue
				seen[id] = true
				var e: EnemyData = load("res://data/enemies/%s.tres" % id)
				if e != null and e.unique and e.tier >= 4: here.append(e)
			here.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return a.tier < b.tier or (a.tier == b.tier and String(a.id) < String(b.id)))
			_bosses.append_array(here)
	return _bosses

static func big_achievements() -> Array[AchievementData]:
	return Achievements.all().filter(func(a: AchievementData) -> bool: return a.reward_money >= BIG_REWARD)

## Todos los trofeos de una vitrina (o de las tres, con case = -1).
static func all(save: SaveData, case := -1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var all_open := save != null and save.unlock_all
	if case < 0 or case == 0:
		for s: Dictionary in OutfitSets.all():
			var done := all_open or (save != null and OutfitSets.is_complete(save, s))
			var facts: Array[String] = []
			var won := OutfitSets.levels_with(save, OutfitSets.as_worn(s))
			if won > 0: facts.append(MenuKit.count(won, "nivel superado", "niveles superados") + " con él puesto")
			elif done: facts.append("Aún sin estrenar en una partida")
			out.append(_t(0, String(s.id), String(s.name), "Conjunto del vestuario", String(s.get("shown", "dyer")),
				OutfitSets.as_worn(s), done, String(s.description), facts))
	if case < 0 or case == 1:
		for e in bosses():
			var r: Dictionary = (save.records.get("bestiary", {}) as Dictionary).get(String(e.id), {}) if save != null else {}
			var n := int(r.get("kills", 0))
			var facts: Array[String] = []
			var kf := Library.kill_facts(save, String(e.id))
			if n > 0: facts.append("Vencido " + MenuKit.count(n, "vez", "veces"))
			if kf.size() > 1: facts.append(String(kf[1]))
			out.append(_t(1, String(e.id), e.display_name, "Jefe" if e.tier >= 5 else "Jefe intermedio", e.model, {},
				all_open or n > 0, _first_sentence(Library.text("enemies", String(e.id))), facts))
	if case < 0 or case == 2:
		for a in big_achievements():
			var facts: Array[String] = ["Recompensa: " + Achievements.reward_text(a)]
			var done := all_open or Achievements.is_done(save, a)
			if not done and a.target > 1: facts.append("Llevas %s de %s" % [MenuKit.money(mini(Achievements.value(save, a), a.target)), MenuKit.money(a.target)])
			out.append(_t(2, String(a.id), a.display_name, "Logro", String(ACHIEVEMENT_MODELS.get(String(a.id), "trofeo_copa")), {},
				done, a.description, facts))
	return out

static func count(save: SaveData) -> Vector2i:
	var t := all(save)
	return Vector2i(t.filter(func(x: Dictionary) -> bool: return x.earned).size(), t.size())

static func _t(case: int, id: String, name: String, kind: String, model: String, worn: Dictionary, earned: bool,
		text: String, facts: Array[String]) -> Dictionary:
	return {"case": case, "id": id, "name": name, "kind": kind, "model": model, "worn": worn, "earned": earned,
		"text": text, "facts": facts}

static func _first_sentence(t: String) -> String:
	t = t.strip_edges()
	var i := t.find(". ")
	return t.left(i + 1) if i > 0 and i < 220 else t.left(220)
