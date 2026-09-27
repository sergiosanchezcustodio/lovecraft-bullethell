class_name DebugOptions
extends RefCounted
## Ajustes de depuración de la partida (menú de pausa > Depuración). Se guardan en una
## variable estática: se aplican al momento y se conservan al reiniciar la partida, hasta
## que se restablecen. Las opciones de la línea de comandos siguen funcionando igual; lo
## que se toque aquí manda sobre ellas.

const ENEMY_COUNTS: Array[int] = [-1, 10, 50, 100, 300]          ## -1: lo que marque el nivel
const TIME_SCALES: Array[float] = [0.25, 0.5, 1.0, 2.0, 4.0]
const CAMERA_SIZES: Array[float] = [10.0, 15.0, 20.0, 30.0]
const SPEED_MULTS: Array[float] = [0.75, 1.0, 1.5, 2.0]
## Estadísticas del personaje que fija el estilo de esquive (Player.apply_dodge_style).
const STYLE_STATS := {"dodge_speed": "speed", "dodge_duration": "duration", "dodge_iframes": "iframes",
	"dodge_cooldown": "cooldown"}

## Valores guardados (clave -> valor). Vacío: partida normal.
static var values := {}

static func get_value(key: String, default: Variant) -> Variant:
	return values.get(key, default)

static func set_value(key: String, v: Variant) -> void:
	values[key] = v

static func clear() -> void:
	values.clear()

static func is_active() -> bool:
	return not values.is_empty()

## Listas de datos disponibles (se leen de las carpetas: lo que se añada aparece solo).
static func list_resources(dir: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var names := ResourceLoader.list_directory(dir) if ResourceLoader.has_method("list_directory") else DirAccess.get_files_at(dir)
	var files: Array[String] = []
	for f in names:
		var n := String(f).trim_suffix(".remap")
		if n.ends_with(".tres") and not files.has(n): files.append(n)
	files.sort()
	for f in files: out.append(load(dir.path_join(f)))
	return out

## Aplica todos los ajustes guardados a una partida recién montada (game.gd).
static func apply_all(game: Node) -> void:
	if values.is_empty(): return
	var p: Player = game.player
	if values.has("dodge"): p.apply_dodge_style(load("res://data/dodges/%s.tres" % values["dodge"]))
	if values.has("god"): p.god = values["god"]
	if values.has("weapons"): apply_weapons(p)
	if values.has("passives") or values.has("speed"): rebuild_stats(p)
	apply_world(game)

## Ajustes del mundo: enemigos, velocidad del juego, cámara.
static func apply_world(game: Node) -> void:
	var d: WaveDirector = game.director
	if d != null:
		d.target_alive = values.get("enemies", -1)
		d.spawning_paused = values.get("spawning_paused", false)
		d.pool_override.clear()
		if values.get("enemy_kind", "") != "":
			d.pool_override.append(load("res://data/enemies/%s.tres" % values["enemy_kind"]))
	if values.has("camera"): (game.camera as GameCamera).view_size = values["camera"]
	if values.has("time_scale"): Engine.time_scale = values["time_scale"]

## Armas: {id: nivel}; nivel 0 = sin esa arma.
static func apply_weapons(p: Player) -> void:
	var levels: Dictionary = values.get("weapons", {})
	for id in levels:
		var lv: int = levels[id]
		var w := p.weapons.get_weapon(StringName(id))
		if lv <= 0:
			if w != null: p.weapons.remove_weapon(StringName(id))
			continue
		if w == null: w = p.weapons.add_weapon(load("res://data/weapons/%s.tres" % id))
		w.level = clampi(lv, 1, w.data.max_level)

## Rehace desde cero las estadísticas que tocan las pasivas (y la velocidad de depuración):
## así se pueden subir y también bajar. Parte del personaje original con su esquive actual.
static func rebuild_stats(p: Player) -> void:
	var levels: Dictionary = values.get("passives", {})
	for id in levels: p.progress.passives[StringName(id)] = levels[id]
	var base: CharacterData = load("res://data/characters/%s.tres" % p.data.id)
	var stats := {"move_speed": true}
	for up in p.progress.upgrade_pool: stats[up.stat] = true
	var old_health := p.data.max_health
	var old_sanity := p.data.max_sanity
	for stat in stats:
		var v: float = base.get(stat)
		var style := p.data.dodge_style
		if style != null and STYLE_STATS.has(stat):
			v = style.get(STYLE_STATS[stat])      # lo marca el estilo de esquive, no el personaje
			if stat in ["dodge_duration", "dodge_iframes"]: v *= p.data.dodge_length
			if stat == "dodge_cooldown": v *= p.data.dodge_cooldown_mult
		for up in p.progress.upgrade_pool:
			if up.stat != stat: continue
			for i in int(p.progress.passives.get(up.id, 0)): v = v * up.multiply + up.add
		if stat == "move_speed": v *= float(values.get("speed", 1.0))
		p.data.set(stat, v)
	# la vida y la cordura ganadas se rellenan; si bajan, no pasan del nuevo máximo
	p.health = minf(p.health + maxf(p.data.max_health - old_health, 0.0), p.data.max_health)
	p.sanity = minf(p.sanity + maxf(p.data.max_sanity - old_sanity, 0.0), p.data.max_sanity)
