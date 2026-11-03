class_name RunArchive
extends RefCounted
## Archivo de expediciones (hito 16.26): cada nivel jugado (superado o no) queda en la Biblioteca
## (tomo «Archivo de expediciones») con quién lo jugó, sus armas y objetos al acabar, el minuto,
## la causa de la caída, la tabla de daño (`CombatWorld.table_of`) y la semilla de su azar. Desde
## la Biblioteca se puede repetir con la misma semilla: las mismas oleadas, baúles, peligros y
## subidas (lo que depende de dónde esté cada uno cambia, como en la partida del día).
## En `SaveData.records.archive`, las `MAX` últimas, la más reciente primero.

const MAX := 30
const TABLE_ROWS := 8                     ## filas de la tabla de daño que se guardan

## Lo que se guarda de un jugador al acabar el nivel.
static func player_entry(q: Player, world: CombatWorld, cause: String) -> Dictionary:
	var weapons: Array = []
	if q.weapons != null:
		for w: WeaponSystem.Weapon in q.weapons.weapons: weapons.append([String(w.data.id), w.level])
	var items: Array = []
	if q.progress != null:
		for id in q.progress.passives:
			if int(q.progress.passives[id]) > 0: items.append([String(id), int(q.progress.passives[id])])
	var table: Array = []
	if world != null:
		for r: Dictionary in world.table_of(q.index).slice(0, TABLE_ROWS):
			table.append({"id": r.id, "damage": roundi(r.damage), "share": snappedf(r.share, 0.001),
				"dps": snappedf(r.dps, 0.1), "kills": r.kills})
	var pet := ""
	if q.pet != null and is_instance_valid(q.pet): pet = String((q.pet as Pet).data.id)
	return {"character": String(q.data.id), "name": q.data.display_name, "lvl": q.progress.level if q.progress != null else 1,
		"worn": OutfitData.worn_for(String(q.data.id)).duplicate(), "pet": pet,
		"weapons": weapons, "items": items, "table": table, "cause": cause}

## Apunta una partida; `run` = {level, result ("won", "lost", "endless"), t, seed, pacts, madness,
## players: [player_entry…]}. Pone la fecha y la hora.
static func add(save: SaveData, run: Dictionary) -> void:
	if save == null: return
	var r := run.duplicate(true)
	r["date"] = Time.get_date_string_from_system()
	r["time"] = Time.get_time_string_from_system().left(5)
	var list: Array = save.records.get("archive", [])
	list.push_front(r)
	if list.size() > MAX: list.resize(MAX)
	save.records["archive"] = list

static func runs(save: SaveData) -> Array:
	return save.records.get("archive", []) if save != null else []

## ¿Se puede volver a jugar? No las que dependen de algo que ya no está: la partida del día (su
## azar es el de su fecha), la expedición (su mapa) y el desfile de jefes (su tiempo sumado).
static func replayable(run: Dictionary) -> bool:
	var id := String(run.get("level", ""))
	if id == "" or Expedition.is_expedition(id) or BossRush.is_rush(id) or Daily.is_daily(id): return false
	return int(run.get("seed", 0)) != 0 and not (run.get("players", []) as Array).is_empty()

## Deja la sesión lista para repetirla (con el J1, desde el dispositivo que se usó en el menú):
## mismo nivel, personaje, vestuario, compañero, pactos y grado de locura, y la misma semilla.
## Sin lo que se traía del nivel anterior.
static func prepare(run: Dictionary, device: int) -> void:
	GameSession.clear()
	var p: Dictionary = (run.players as Array)[0]
	var s := GameSession.Seat.new()
	s.slot = 0
	s.device = device
	s.character = StringName(String(p.character))
	s.pet = StringName(String(p.get("pet", "")))
	s.worn = (p.get("worn", {}) as Dictionary).duplicate()
	GameSession.seats.append(s)
	GameSession.level = StringName(String(run.level))
	GameSession.pacts = (run.get("pacts", []) as Array).duplicate()
	GameSession.madness = int(run.get("madness", 0))
	GameSession.replay_seed = int(run.seed)

## Nombre del sitio de un nivel («Calles de Innsmouth»), con el modo si no es la campaña.
static func place(run: Dictionary) -> String:
	var id := String(run.get("level", ""))
	var base := Endless.base_of(id)
	var name := DailyMenu._level_name(base) if base != "" else id
	if Challenge.is_challenge(id): return "Desafío · " + String(Challenge.find(id).get("name", name))
	if Daily.is_daily(id): return "Partida del día · " + name
	if Endless.is_endless(id): return "Noche eterna · " + name
	if Expedition.is_expedition(id): return "Expedición · " + name
	if BossRush.is_rush(id): return "Desfile de jefes"
	return name

## "15,7": una cifra decimal, con coma.
static func decimal(v: float) -> String:
	return ("%.1f" % v).replace(".", ",")

static func clock(t: float) -> String:
	return "%d:%02d" % [int(t) / 60, int(t) % 60]

## Nombre de un arma, objeto o compañero por su id.
static func source_name(id: String, pet := "") -> String:
	if id == "mascota":
		var pp := "res://data/pets/%s.tres" % pet
		return (load(pp) as PetData).display_name if pet != "" and ResourceLoader.exists(pp) else "Compañero"
	for dir in ["weapons", "upgrades"]:
		var p := "res://data/%s/%s.tres" % [dir, id]
		if ResourceLoader.exists(p): return String(load(p).get("display_name"))
	return id.capitalize()
