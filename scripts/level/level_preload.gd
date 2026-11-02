class_name LevelPreload
extends RefCounted
## Carga del siguiente nivel durante el relato (hito 16.6). Mientras se lee el relato, un hilo
## monta la arena entera (suelo, mar, costa, decorado con sus luces y su ambiente: 0,25-0,45 s)
## y deja en la caché de `VoxelBuilder` los modelos de los enemigos del nivel; la partida se la
## lleva hecha (`take`) en vez de montarla con la pantalla en negro.
##
## La arena se monta fuera del árbol, como siempre, así que el hilo no toca nada que esté en
## escena; lo que necesita de los autoloads (configuración, sonido silenciado) lo copia antes el
## hilo principal (`Auto.snapshot`, `Ambient.snap_muted`). Mientras corre, el relato no usa
## `VoxelBuilder` ni `Ambient`. `preload=false` (en el relato) lo quita.

static var enabled := true
static var _task := -1
static var _key := ""
static var _arena: Node3D
static var _models: Array[String] = []
## Armas, objetos y personajes cargados en el hilo: se guardan aquí hasta que la partida los
## tiene (si nadie los sujeta, Godot los descarga y la partida los volvería a leer).
static var _keep: Array[Resource] = []
const KEEP_DIRS := ["res://data/weapons", "res://data/upgrades", "res://data/characters"]
static var last_build_ms := 0.0           ## lo que tardó el hilo (registro)
static var last_wait_ms := 0.0            ## lo que esperó la partida por él (0 si ya estaba)
static var last_hit := false              ## la partida usó la arena montada
const GAME := "res://scenes/game.tscn"
static var _scene_requested := false

## Nivel que monta la partida con estos argumentos (lo mismo que `Game._ready`).
static func level_id(args: LaunchArgs) -> String:
	if not GameSession.carry.is_empty(): return String(GameSession.level)
	return args.get_str("level", String(GameSession.level) if GameSession.is_set() else "p1_n1")

## Arena de ese nivel (la del nivel base en la noche eterna, el día y los desafíos).
static func arena_of(id: String) -> String:
	var path := "res://data/levels/%s.tres" % Endless.base_of(id)
	if not ResourceLoader.exists(path): return "res://data/arenas/campamento.json"
	var ld: LevelData = load(path)
	return ld.arena if ld != null else "res://data/arenas/campamento.json"

## Volúmenes de niebla, como los decide `Game._ready` (sin el `fogvol=` de las pruebas).
static func fog_volumes() -> bool:
	return bool(Quality.value("fogvol", true)) and RenderingServer.get_current_rendering_method() != "gl_compatibility"

static func _key_of(path: String, fogvol: bool) -> String:
	return "%s|%s" % [path, fogvol]

## Empieza a montar el nivel `id` en un hilo (desde el relato).
static func begin(id: String) -> void:
	discard()
	if not enabled: return
	var path := arena_of(id)
	var fogvol := fog_volumes()
	_key = _key_of(path, fogvol)
	_models.clear()
	var lv_path := "res://data/levels/%s.tres" % Endless.base_of(id)
	if ResourceLoader.exists(lv_path):
		for d in LevelWarmup.enemies_of(load(lv_path)):
			var m := "res://models/%s.json" % d.model
			if ResourceLoader.exists(m) or FileAccess.file_exists(m): _models.append(m)
	Auto.snapshot()                         # lo que el hilo no puede leer de los autoloads
	Ambient.snap_muted()
	Ambient.config()
	Quality.presets()
	# la escena de la partida y todos sus scripts (cargarla con la pantalla en negro era más de 1 s)
	_scene_requested = ResourceLoader.load_threaded_request(GAME) == OK
	_task = WorkerThreadPool.add_task(_work.bind(path, fogvol, _models.duplicate()), false, "LevelPreload")

static func _work(path: String, fogvol: bool, models: Array[String]) -> void:
	var t0 := Time.get_ticks_usec()
	_arena = ArenaBuilder.build(path, fogvol)
	for m in models: VoxelBuilder.warm(m)
	var keep: Array[Resource] = []
	for d in KEEP_DIRS: keep.append_array(DebugOptions.list_resources(d))   # cada jugador las lista todas (Game._spawn_player)
	_keep = keep
	last_build_ms = (Time.get_ticks_usec() - t0) / 1000.0

## La arena montada si coincide con la que pide la partida (si aún se está montando, espera);
## si no hay o no coincide, null y la partida la monta como siempre.
static func take(path: String, fogvol: bool) -> Node3D:
	last_hit = false
	last_wait_ms = 0.0
	if _task < 0: return null
	var t0 := Time.get_ticks_usec()
	_wait()
	last_wait_ms = (Time.get_ticks_usec() - t0) / 1000.0
	var a := _arena
	_arena = null
	if a == null: return null
	if _key != _key_of(path, fogvol):
		a.free()
		return null
	last_hit = true
	return a

## Tira lo montado (otro nivel, o se sale sin jugar).
static func discard() -> void:
	if _task >= 0: _wait()
	if _arena != null:
		_arena.free()
		_arena = null

## La escena de la partida, cargada durante el relato (espera si aún no ha acabado), o null.
static func game_scene() -> PackedScene:
	if not _scene_requested: return null
	_scene_requested = false
	return ResourceLoader.load_threaded_get(GAME) as PackedScene

## Espera al hilo sin bloquear el servidor de dibujo: lo que el hilo le pide con respuesta
## (p. ej. leer una malla) solo se atiende cuando el hilo principal vacía su cola, y esperar
## con `wait_for_task_completion` a secas podría quedarse colgado.
static func _wait() -> void:
	while not WorkerThreadPool.is_task_completed(_task):
		RenderingServer.force_sync()
		OS.delay_usec(200)
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1

## La partida ya lo tiene todo: suelta lo que se sujetaba.
static func release() -> void:
	_keep = []

static func pending() -> bool:
	return _task >= 0 or _arena != null
