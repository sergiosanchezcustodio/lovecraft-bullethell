extends Node
## Copia de las partidas en la nube (autoload `Cloud`, fase 10, D-11): un gist secreto en la
## cuenta de GitHub del jugador. La partida local sigue mandando; esto es una copia, y sin
## conexión o con un error se juega igual que siempre.
## Lo que hay que recordar entre sesiones (token, usuario, id del gist y un id de este PC) va en
## `user://cloud.json`, aparte de la configuración: el token no debe acabar en una captura del
## fichero de configuración ni subirse con los controles.
## Pruebas: `cloud_token=` (un token con permiso `gist`, p. ej. el de `gh auth token`),
## `cloud=nombre` (otro fichero, `user://cloud_<nombre>.json`) y `cloud_marker=` (otro gist).

signal changed                               ## cambió el estado (conectado, conectando, error…)
signal synced                                ## acabó una sincronización (los huecos pueden haber cambiado)

const PATH := "user://cloud.json"
const CONFIG := "res://data/cloud.json"
var auto_delay := 2.0                        ## s que se agrupan los guardados antes de subirlos

var path := _default_path()
var client_id := ""
var token := ""
var login := ""                              ## usuario de GitHub
var gist_id := ""
var device_id := ""                          ## este PC (al azar, la primera vez)
var device_name := ""
var gist := GitHubGist.new()
## Mientras se conecta: {"user_code", "verification_uri"} para enseñárselos al jugador.
var pending := {}
## Último error ("" si fue bien): los de `GitHubGist.last_error`, "no_client" (falta el
## client_id), "expired_token" o "access_denied" (al conectar).
var error := ""
var busy := false
## Subir sola cada partida al guardarla (la ventana de huecos sincroniza siempre).
var auto := true
## Partidas que han cambiado aquí y en la nube: [{"slot", "local": SaveData, "cloud": SaveData}].
var conflicts: Array = []
var last_sync := ""                          ## hora de la última sincronización buena
var syncing := false
## Huecos borrados aquí que quizá sigan en la nube: fichero -> revisión que tenían.
var deleted := {}
## A quién se sincroniza (los autoloads; las pruebas ponen los suyos y `wire = false`).
var saves: Node
var settings: Object
var wire := true
var _queued := {}
var _waiting := false
var _cancel := false
var _launch_token := false                  ## el token vino por `cloud_token=`: no se escribe en disco

static func _default_path() -> String:
	for a in OS.get_cmdline_args():
		if a.ends_with("gut_cmdln.gd"): return "user://cloud_pruebas.json"
	return PATH

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var http := CloudHttp.new()
	http.name = "Http"
	add_child(http)
	gist.http = http
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	if cfg is Dictionary: client_id = String(cfg.get("client_id", ""))
	var la := LaunchArgs.from_cmdline()
	if la.has("cloud"): path = "user://cloud_%s.json" % la.get_str("cloud")
	elif la.has("cloud_token"): path = "user://cloud_token.json"   # el token de prueba no pisa la cuenta de verdad
	if la.has("cloud_marker"): gist.marker = la.get_str("cloud_marker")
	load_file()
	if wire:
		saves = Saves
		settings = Settings
		Saves.saved.connect(func(i: int) -> void: _queue(CloudSync.slot_file(i)))
		Saves.deleted.connect(_on_deleted)
		Settings.controls_changed.connect(func() -> void: _queue(CloudSync.CONTROLS))
	if la.has("cloud_token"):
		_set_token(la.get_str("cloud_token"))
		_launch_token = true

func connected() -> bool:
	return token != ""

# --- Conectar y desconectar ---------------------------------------------------------------------

## Conecta con GitHub por el flujo de dispositivo: deja el código en `pending` (para la ventana)
## y espera a que el jugador lo apruebe, lo rechace, caduque o se cancele. true si quedó conectado.
func connect_github() -> bool:
	if client_id == "":
		_fail("no_client")
		return false
	_cancel = false
	error = ""
	busy = true
	changed.emit()
	var d: Dictionary = await gist.start_device(client_id)
	if d.is_empty():
		_fail(gist.last_error)
		return false
	pending = {"user_code": String(d.user_code), "verification_uri": String(d.verification_uri)}
	changed.emit()
	var interval := float(d.get("interval", 5))
	var deadline := Time.get_ticks_msec() + int(d.get("expires_in", 900)) * 1000
	while not _cancel and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(interval, true).timeout
		if _cancel: break
		var p: Dictionary = await gist.poll_device(client_id, String(d.device_code))
		if p.has("token"):
			pending = {}
			_set_token(p.token)
			login = await gist.user_login()
			busy = false
			save_file()
			changed.emit()
			return true
		match String(p.error):
			"authorization_pending", "net": pass
			"slow_down": interval += 5.0
			_:
				pending = {}
				_fail(p.error)
				return false
	pending = {}
	_fail("" if _cancel else "expired_token")
	return false

## Deja de esperar al jugador (botón de cancelar de la ventana del código).
func cancel_connect() -> void:
	_cancel = true

## Olvida la cuenta en este PC. El gist se queda en GitHub, con las partidas.
func disconnect_github() -> void:
	_set_token("")
	login = ""
	gist_id = ""
	error = ""
	conflicts.clear()
	save_file()
	changed.emit()

# --- Gist ---------------------------------------------------------------------------------------

## Busca el gist de las partidas o lo crea. Devuelve su id ("" si falla).
func ensure_gist() -> String:
	if gist_id != "": return gist_id
	var id: String = await gist.find()
	if id == "" and gist.last_error == "":
		id = await gist.create({"meta.json": JSON.stringify(_meta(), "\t")})
	if not _check():
		return ""
	gist_id = id
	save_file()
	return id

## Lee los ficheros de la copia (nombre -> texto), o null si falla.
func fetch() -> Variant:
	if not connected(): return null
	busy = true
	var files: Variant = null
	for _attempt in 2:                                # si borraron el gist en GitHub, se busca otra vez
		if await ensure_gist() == "": break
		files = await gist.read(gist_id)
		if files == null and gist.last_error == "missing":
			gist_id = ""
			continue
		break
	_check()
	busy = false
	changed.emit()
	return files

## Escribe estos ficheros en la copia (nombre -> texto; null lo borra) junto con `meta.json`.
func push(files: Dictionary) -> bool:
	if not connected(): return false
	busy = true
	var all := files.duplicate()
	all["meta.json"] = JSON.stringify(_meta(), "\t")
	var ok := false
	for _attempt in 2:
		if await ensure_gist() == "": break
		ok = await gist.write(gist_id, all)
		if not ok and gist.last_error == "missing":
			gist_id = ""
			continue
		break
	_check()
	busy = false
	changed.emit()
	return ok

# --- Sincronización (hito 10.2) ---------------------------------------------------------------

## Compara los huecos y los controles con la nube y sube, baja o apunta conflictos
## (`CloudSync.decide`). `only`: ficheros a mirar (vacío, todos). `in_game`: no cambia la partida
## del hueco en uso, que se está jugando. true si se pudo hablar con la nube.
func sync(only: Array = [], in_game := false) -> bool:
	if not connected(): return false
	while syncing: await synced                    # de una en una
	syncing = true
	var files: Variant = await fetch()
	var ok := files is Dictionary
	if ok:
		var out := {}
		var after: Array[Callable] = []            # lo que se apunta aquí cuando la subida sale bien
		for i in saves.SLOTS:
			var name := CloudSync.slot_file(i)
			if only.is_empty() or only.has(name): _sync_slot(i, name, files, out, after, in_game)
		if only.is_empty() or only.has(CloudSync.CONTROLS): _sync_controls(files, out, after)
		if not out.is_empty():
			ok = await push(out)
			if ok:
				for c in after: c.call()
	if ok: last_sync = Time.get_datetime_string_from_system()
	save_file()
	syncing = false
	synced.emit()
	changed.emit()
	return ok

func _sync_slot(i: int, name: String, files: Dictionary, out: Dictionary, after: Array[Callable], in_game: bool) -> void:
	var local: SaveData = saves.peek(i)              # lo guardado (la partida en uso puede ir por delante)
	var cloud_d: Variant = _parse(files.get(name))
	match CloudSync.decide(local.to_dict() if local != null else null, cloud_d, int(deleted.get(name, -1))):
		CloudSync.UPLOAD:
			var d := local.to_dict()
			d.cloud_base = local.rev
			out[name] = JSON.stringify(d, "	")
			after.append(saves.mark_synced.bind(i, local.rev))
		CloudSync.DOWNLOAD:
			if in_game and i == saves.slot: return
			var d := SaveData.from_dict(cloud_d)
			d.cloud_base = d.rev
			saves.store(i, d)
			deleted.erase(name)
			_drop_conflict(i)
		CloudSync.DELETE_CLOUD:
			out[name] = null
			after.append(func() -> void: deleted.erase(name))
		CloudSync.CONFLICT:
			_drop_conflict(i)
			conflicts.append({"slot": i, "local": local, "cloud": SaveData.from_dict(cloud_d)})
		_:
			if local == null: deleted.erase(name)

## Los controles: si han cambiado en los dos sitios, se quedan los de este PC.
func _sync_controls(files: Dictionary, out: Dictionary, after: Array[Callable]) -> void:
	var lc: Dictionary = settings.controls_dict()
	var cc: Variant = _parse(files.get(CloudSync.CONTROLS))
	var what := CloudSync.decide(lc, cc)
	if what == CloudSync.DOWNLOAD:
		settings.store_controls(cc)
	elif what in [CloudSync.UPLOAD, CloudSync.CONFLICT]:
		if what == CloudSync.CONFLICT: lc.rev = maxi(int(lc.rev), int(cc.rev)) + 1
		lc.cloud_base = lc.rev
		out[CloudSync.CONTROLS] = JSON.stringify(lc, "	")
		after.append(settings.store_controls.bind(lc))

## Resuelve el conflicto de un hueco: con la copia de la nube o con la de este PC (que se sube
## como revisión nueva). true si quedó resuelto.
func resolve(slot: int, keep_cloud: bool) -> bool:
	var c := conflict_of(slot)
	if c.is_empty(): return false
	var cloud: SaveData = c.cloud
	if keep_cloud:
		cloud.cloud_base = cloud.rev
		saves.store(slot, cloud)
		_drop_conflict(slot)
		changed.emit()
		return true
	var local: SaveData = saves.peek(slot)
	if local == null: local = c.local
	var rev := maxi(local.rev, cloud.rev) + 1
	var d := local.to_dict()
	d.rev = rev
	d.cloud_base = rev
	if not await push({CloudSync.slot_file(slot): JSON.stringify(d, "	")}): return false
	saves.mark_synced(slot, rev)
	_drop_conflict(slot)
	changed.emit()
	return true

func conflict_of(slot: int) -> Dictionary:
	for c: Dictionary in conflicts:
		if c.slot == slot: return c
	return {}

func _drop_conflict(slot: int) -> void:
	conflicts = conflicts.filter(func(c: Dictionary) -> bool: return c.slot != slot)

## Subida automática: agrupa lo guardado durante `auto_delay` y lo sincroniza sin bajar nada
## encima de la partida en uso.
func _queue(name: String) -> void:
	if not connected() or not auto: return
	_queued[name] = true
	if _waiting: return
	_waiting = true
	await get_tree().create_timer(auto_delay, true).timeout
	_waiting = false
	var names := _queued.keys()
	_queued.clear()
	await sync(names, true)

func _on_deleted(slot: int, rev: int) -> void:
	var name := CloudSync.slot_file(slot)
	deleted[name] = rev
	_drop_conflict(slot)
	save_file()
	_queue(name)

static func _parse(text: Variant) -> Variant:
	if text == null: return null
	var d: Variant = JSON.parse_string(String(text))
	return d if d is Dictionary else null

# --- Detalles -----------------------------------------------------------------------------------

func _meta() -> Dictionary:
	return {"game_version": ProjectSettings.get_setting("application/config/version", ""),
		"device_id": device_id, "device_name": device_name, "updated": Time.get_datetime_string_from_system()}

## Apunta el error de la última llamada; si el token ya no vale (revocado), se olvida.
func _check() -> bool:
	error = gist.last_error
	if error == "auth":
		_set_token("")
		login = ""
		save_file()
	return error == ""

func _fail(e: String) -> void:
	error = e
	busy = false
	changed.emit()

func _set_token(t: String) -> void:
	token = t
	gist.token = t

func load_file() -> void:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if d is Dictionary:
		_set_token(String(d.get("token", "")))
		login = String(d.get("login", ""))
		gist_id = String(d.get("gist_id", ""))
		device_id = String(d.get("device_id", ""))
		auto = bool(d.get("auto", true))
		last_sync = String(d.get("last_sync", ""))
		deleted = d.get("deleted", {})
	if device_id == "":
		device_id = "%08x%08x" % [randi(), randi()]
		save_file()
	device_name = OS.get_environment("COMPUTERNAME")
	if device_name == "": device_name = OS.get_environment("HOSTNAME")
	if device_name == "": device_name = OS.get_name()

func save_file() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo guardar " + path)
		return
	f.store_string(JSON.stringify({"token": "" if _launch_token else token, "login": login, "gist_id": gist_id, "device_id": device_id,
		"auto": auto, "last_sync": last_sync, "deleted": deleted}, "\t"))
