class_name AccountStats
extends RefCounted
## Estadísticas de la cuenta (hito 21.20): lo que se acumula partida a partida para el tomo XIII de
## la Biblioteca. Junta lo que ya había (tiempo jugado, partidas, bajas, caídas, bajas por criatura,
## récords y el archivo de expediciones) con lo nuevo, que se apunta al acabar cada nivel en
## `SaveData.records["account"]`:
##   weapons:    {id: [daño, bajas]}   (de la tabla de daño de cada jugador de este PC)
##   characters: {id: [partidas, s]}   (el favorito: el de más tiempo)
##   crisis:     s en crisis de los jugadores de este PC
##   crisis_kinds: {tipo: veces} (parálisis, huida, vagar, paranoia, delirio)
##   levels:     {id: [partidas, superadas]}
## Solo cuentan las partidas que se apuntan en el archivo (las de una persona en este PC).

const KEY := "account"
const TOP := 8                                   ## filas de cada gráfica

static func _all(save: SaveData) -> Dictionary:
	if save == null: return {}
	if not save.records.has(KEY): save.records[KEY] = {"weapons": {}, "characters": {}, "crisis": 0.0, "levels": {}}
	return save.records[KEY]

static func _read(save: SaveData) -> Dictionary:
	return (save.records.get(KEY, {}) as Dictionary) if save != null else {}

## Una partida de un jugador: su personaje, lo que duró y su tabla de daño entera
## (`CombatWorld.table_of`).
static func add_player(save: SaveData, character: String, t: float, table: Array) -> void:
	if save == null: return
	var a := _all(save)
	var cs: Dictionary = a.get("characters", {})
	var c: Array = cs.get(character, [0, 0.0])
	cs[character] = [int(c[0]) + 1, snappedf(float(c[1]) + t, 0.1)]
	a["characters"] = cs
	var ws: Dictionary = a.get("weapons", {})
	for r: Dictionary in table:
		var id := String(r.get("id", ""))
		if id == "": continue
		var w: Array = ws.get(id, [0, 0])
		ws[id] = [int(w[0]) + roundi(float(r.get("damage", 0.0))), int(w[1]) + int(r.get("kills", 0))]
	a["weapons"] = ws

static func add_level(save: SaveData, level_id: String, won: bool) -> void:
	if save == null or level_id == "": return
	var a := _all(save)
	var ls: Dictionary = a.get("levels", {})
	var l: Array = ls.get(level_id, [0, 0])
	ls[level_id] = [int(l[0]) + 1, int(l[1]) + (1 if won else 0)]
	a["levels"] = ls

static func add_crisis(save: SaveData, seconds: float, kinds := {}) -> void:
	if save == null or (seconds <= 0.0 and kinds.is_empty()): return
	var a := _all(save)
	a["crisis"] = snappedf(float(a.get("crisis", 0.0)) + seconds, 0.1)
	var ks: Dictionary = a.get("crisis_kinds", {})
	for k: String in kinds: ks[k] = int(ks.get(k, 0)) + int(kinds[k])
	a["crisis_kinds"] = ks

static func crisis_time(save: SaveData) -> float:
	return float(_read(save).get("crisis", 0.0))

## El investigador con más tiempo jugado ("" si no hay ninguno).
static func favorite(save: SaveData) -> String:
	var best := ""
	var most := 0.0
	var cs: Dictionary = _read(save).get("characters", {})
	for k: String in cs:
		if float(cs[k][1]) > most:
			most = float(cs[k][1])
			best = k
	return best

## Filas de una gráfica de barras, de mayor a menor: [{id, value, extra}]. `what`: "weapons" (daño;
## extra, bajas), "kills" (bajas por criatura), "characters" (s; extra, partidas) o "levels"
## (partidas; extra, superadas).
static func rows(save: SaveData, what: String, top := TOP) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match what:
		"weapons", "characters", "levels":
			var d: Dictionary = _read(save).get(what, {})
			for k: String in d:
				var v: Array = d[k]
				var main := float(v[1]) if what == "characters" else float(v[0])
				out.append({"id": k, "value": main, "extra": int(v[0]) if what == "characters" else int(v[1])})
		"crisis":
			var ck: Dictionary = _read(save).get("crisis_kinds", {})
			for k: String in ck: out.append({"id": k, "value": float(ck[k]), "extra": 0})
		"kills":
			var b: Dictionary = save.records.get("bestiary", {}) if save != null else {}
			for k: String in b:
				out.append({"id": k, "value": float((b[k] as Dictionary).get("kills", 0)), "extra": 0})
	out = out.filter(func(r: Dictionary) -> bool: return float(r.value) > 0.0)
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.value) > float(y.value))
	return out.slice(0, top)

## Minutos que duró cada una de las últimas partidas del archivo, de la más antigua a la última,
## y si se superó: [[min, won]].
static func recent(save: SaveData) -> Array:
	var out := []
	var runs := RunArchive.runs(save)
	for i in range(runs.size() - 1, -1, -1):
		var r: Dictionary = runs[i]
		out.append([float(r.get("t", 0.0)) / 60.0, String(r.get("result", "")) == "won"])
	return out
