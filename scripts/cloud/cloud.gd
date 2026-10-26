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

const PATH := "user://cloud.json"
const CONFIG := "res://data/cloud.json"

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
	f.store_string(JSON.stringify({"token": "" if _launch_token else token, "login": login, "gist_id": gist_id, "device_id": device_id}, "\t"))
