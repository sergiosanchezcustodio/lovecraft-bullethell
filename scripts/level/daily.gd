class_name Daily
extends RefCounted
## Partida del día (hito 13.9, D-45): cada día, para todos, el mismo escenario, investigador,
## compañero y pactos, sacados de la fecha (`pick`), sobre el modo sin fin (`Endless`). El azar
## de la partida (oleadas, baúles, subidas) sale de la misma semilla (`game._daily_seed`). Un
## intento que cuenta, el primero que termina ese día; los demás son de práctica. Resultado,
## racha y códigos de amigos en el hueco (`SaveData.records.daily`, viaja con la nube). Sin
## servidor no hay clasificación: al terminar sale un código corto del resultado (`encode`) para
## pasárselo a un amigo, y el juego lo lee y lo compara con el tuyo (`decode`, `DailyMenu`).

const PREFIX := "dia:"
const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"   ## base 32 de Crockford (sin I, L, O ni U)
const EPOCH := "2026-01-01"
const SALT := 0x2F
const MONTHS := ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto",
	"septiembre", "octubre", "noviembre", "diciembre"]
const WEEKDAYS := ["domingo", "lunes", "martes", "miércoles", "jueves", "viernes", "sábado"]

## Fecha de hoy (la del PC, "AAAA-MM-DD"); daily_date= la cambia (pruebas).
static func today() -> String:
	var la := LaunchArgs.from_cmdline()
	if la.has("daily_date"): return la.get_str("daily_date")
	return Time.get_date_string_from_system()

static func is_daily(id: String) -> bool:
	return id.begins_with(PREFIX)

static func id_for(date: String) -> String:
	return PREFIX + date

static func date_of(id: String) -> String:
	return id.substr(PREFIX.length())

## Semilla estable de la fecha (FNV-1a: no depende de la versión de Godot, como `hash`).
static func seed_of(date: String) -> int:
	var h := -3750763034362895579          # 0xcbf29ce484222325 (no cabe como literal)
	for b in date.to_utf8_buffer():
		h = (h ^ b) * 0x100000001b3
	return h & 0x7fffffffffffffff

static func _ids(dir: String) -> Array[String]:
	var out: Array[String] = []
	for r in DebugOptions.list_resources(dir): out.append(String(r.get("id")))
	out.sort()
	return out

static func characters() -> Array[String]:
	return _ids("res://data/characters")

## Lo del día: {level, character, pet, pacts}.
static func pick(date: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_of(date)
	var levels := Campaign.levels()
	var chars := characters()
	var pets := _ids("res://data/pets")
	var pacts: Array = Pacts.all().map(func(p: Dictionary) -> String: return String(p.id))
	var lv := String(levels[rng.randi() % levels.size()].id)
	var ch := chars[rng.randi() % chars.size()]
	var pet := pets[rng.randi() % pets.size()]
	var chosen: Array = []
	for k in rng.randi_range(0, 2):                 # de ninguno a dos pactos
		var p: String = pacts[rng.randi() % pacts.size()]
		if not chosen.has(p): chosen.append(p)
	return {"level": lv, "character": ch, "pet": pet, "pacts": chosen}

## Todos los jugadores con el investigador y el compañero del día, y sus pactos.
static func dress_session(id: String) -> void:
	var p := pick(date_of(id))
	var save := Auto.save()
	for s in GameSession.seats:
		s.character = StringName(String(p.character))
		s.pet = StringName(String(p.pet))
		s.worn = (save.worn.get(String(p.character), {}) as Dictionary).duplicate() if save != null and s.is_local() else {}
	Pacts.set_active(p.pacts)

## El escenario del nivel del día (para `Endless.base_of`).
static func base_of(id: String) -> String:
	return String(pick(date_of(id)).level)

## El nivel: el sin fin sobre el escenario del día, con el id de la fecha.
static func make_level(id: String) -> LevelData:
	var date := date_of(id)
	var lv := Endless.make_level(Endless.id_for(base_of(id)))
	lv.id = StringName(id)
	lv.daily = date
	lv.display_name = "Partida del día · %s" % pretty(date, false)
	return lv

## ¿Está abierta? Tras superar el primer nivel (o con todo desbloqueado).
static func unlocked(save: SaveData) -> bool:
	return save != null and (save.unlock_all or not save.levels_won.is_empty())

## "jueves, 30 de octubre" (o "30 de octubre").
static func pretty(date: String, weekday := true) -> String:
	var d := Time.get_datetime_dict_from_datetime_string(date + "T12:00:00", true)
	if d.is_empty() or int(d.get("month", 0)) < 1: return date
	var s := "%d de %s" % [int(d.day), MONTHS[int(d.month) - 1]]
	return ("%s, %s" % [WEEKDAYS[int(d.weekday)], s]) if weekday else s

static func _day_index(date: String) -> int:
	return int(round((Time.get_unix_time_from_datetime_string(date + "T12:00:00") - Time.get_unix_time_from_datetime_string(EPOCH + "T12:00:00")) / 86400.0))

static func _date_of_index(k: int) -> String:
	return Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_datetime_string(EPOCH + "T12:00:00")) + k * 86400)

## Resultado del día en el hueco, o {} si aún no hay intento que cuente.
static func result(save: SaveData, date: String) -> Dictionary:
	if save == null: return {}
	return ((save.records.get("daily", {}) as Dictionary).get("days", {}) as Dictionary).get(date, {})

## Apunta el intento si es el primero del día; true si cuenta.
static func record(save: SaveData, date: String, t: float, kills: int, character: String, players: int) -> bool:
	if save == null or not result(save, date).is_empty(): return false
	if not save.records.has("daily"): save.records["daily"] = {}
	var d: Dictionary = save.records.daily
	if not d.has("days"): d["days"] = {}
	d.days[date] = {"t": roundf(t * 10.0) / 10.0, "kills": kills, "character": character, "players": players}
	d["best_streak"] = maxi(int(d.get("best_streak", 0)), streak(save, date))
	return true

## Días seguidos con intento que cuenta, acabando en `date` (o en el día anterior, si aún no
## se ha jugado hoy: la racha sigue viva hasta medianoche).
static func streak(save: SaveData, date: String) -> int:
	var k := _day_index(date)
	if result(save, date).is_empty(): k -= 1
	var n := 0
	while not result(save, _date_of_index(k)).is_empty():
		n += 1
		k -= 1
	return n

static func best_streak(save: SaveData) -> int:
	if save == null: return 0
	return int((save.records.get("daily", {}) as Dictionary).get("best_streak", 0))

## Código del resultado: 60 bits (día, segundos, bajas, investigador, jugadores y una
## comprobación contra erratas) en 12 letras, "7K2M-QX4A-90BD". No es a prueba de trampas.
static func encode(date: String, t: float, kills: int, character: String, players: int) -> String:
	var ci := maxi(characters().find(character), 0)
	var v := (clampi(_day_index(date), 0, 32767) << 39) | (clampi(int(t), 0, 32767) << 24) \
		| (clampi(kills, 0, 262143) << 6) | ((ci & 15) << 2) | (clampi(players, 1, 4) - 1)
	v = (v << 6) | _check(v)
	var s := ""
	for i in 12:
		s = ALPHABET[(v >> (5 * i)) & 31] + s
	return "%s-%s-%s" % [s.substr(0, 4), s.substr(4, 4), s.substr(8, 4)]

static func _check(v: int) -> int:
	var c := SALT
	for i in 9: c = (c * 31 + ((v >> (6 * i)) & 63)) & 63
	return c

## Lee un código (sin guiones, en minúsculas o con O por 0 e I/L por 1 vale); {} si no es válido.
static func decode(code: String) -> Dictionary:
	var s := code.strip_edges().to_upper().replace("-", "").replace(" ", "").replace("O", "0").replace("I", "1").replace("L", "1")
	if s.length() != 12: return {}
	var v := 0
	for ch in s:
		var k := ALPHABET.find(ch)
		if k < 0: return {}
		v = (v << 5) | k
	var body := v >> 6
	if _check(body) != (v & 63): return {}
	var chars := characters()
	var ci := (body >> 2) & 15
	return {"date": _date_of_index((body >> 39) & 32767), "t": float((body >> 24) & 32767),
		"kills": (body >> 6) & 262143, "character": chars[ci] if ci < chars.size() else "",
		"players": (body & 3) + 1, "code": encode(_date_of_index((body >> 39) & 32767), float((body >> 24) & 32767), (body >> 6) & 262143, chars[ci] if ci < chars.size() else "", (body & 3) + 1)}

## Guarda el código de un amigo con su día (para verlo después en la ventana del día).
static func add_friend(save: SaveData, d: Dictionary) -> void:
	if save == null or d.is_empty(): return
	if not save.records.has("daily"): save.records["daily"] = {}
	var all: Dictionary = save.records.daily
	if not all.has("friends"): all["friends"] = {}
	var day: Array = all.friends.get(d.date, [])
	if not day.has(d.code): day.append(d.code)
	all.friends[d.date] = day

static func friends(save: SaveData, date: String) -> Array:
	if save == null: return []
	return ((save.records.get("daily", {}) as Dictionary).get("friends", {}) as Dictionary).get(date, [])
