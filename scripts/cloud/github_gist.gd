class_name GitHubGist
extends RefCounted
## Cliente de GitHub para la copia en la nube (fase 10, D-11): flujo de autorización por
## dispositivo (el juego enseña un código y el jugador lo escribe en github.com/login/device) y
## un gist secreto del jugador con un fichero por cosa guardada (`slot_1.json`…).
## El gist se reconoce por un fichero marcador (`marker`), así que en un PC nuevo se encuentra
## sin guardar su id en ningún sitio. Todo es asíncrono (`await`); el transporte (`http`) tiene
## que dar `request(method, url, headers, body) -> {"code", "body"}` (`CloudHttp` o uno falso).

const API := "https://api.github.com"
const DEVICE_URL := "https://github.com/login/device/code"
const TOKEN_URL := "https://github.com/login/oauth/access_token"
const SCOPE := "gist"
const DESCRIPTION := "Lovecraft Library: Surviving Cthulhu · partidas guardadas"
const MARKER := "lovecraft_library.json"
const MAX_PAGES := 10                        ## gists que se miran al buscar: 100 por página

## Por qué falló la última llamada: "" (bien), "net" (sin conexión), "auth" (token no válido o
## revocado), "limit" (límite de peticiones), "missing" (no existe) u "other".
var last_error := ""
var token := ""
var marker := MARKER                         ## otro marcador para las pruebas de verdad (`cloud_marker=`)
var http

func _init(transport = null) -> void:
	http = transport

# --- Autorización por dispositivo -------------------------------------------------------------

## Pide un código para el jugador: {"device_code", "user_code", "verification_uri", "expires_in",
## "interval"}, o {} si falla.
func start_device(client_id: String) -> Dictionary:
	var r: Variant = await _form(DEVICE_URL, {"client_id": client_id, "scope": SCOPE})
	if r is not Dictionary or not (r as Dictionary).has("device_code"):
		if last_error == "": last_error = "other"
		return {}
	return r

## Pregunta una vez si el jugador ya escribió el código. Devuelve {"token": …} al aprobarlo o
## {"error": …}: "authorization_pending" (todavía no), "slow_down" (preguntar más despacio),
## "expired_token", "access_denied" o el `last_error` si no hubo respuesta.
func poll_device(client_id: String, device_code: String) -> Dictionary:
	var r: Variant = await _form(TOKEN_URL, {"client_id": client_id, "device_code": device_code,
		"grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
	if r is not Dictionary: return {"error": last_error if last_error != "" else "other"}
	var d: Dictionary = r
	if d.has("access_token"): return {"token": String(d.access_token)}
	return {"error": String(d.get("error", "other"))}

# --- API con el token ---------------------------------------------------------------------------

## Nombre de usuario del token ("" si falla).
func user_login() -> String:
	var r: Variant = await _api(HTTPClient.METHOD_GET, "/user")
	return String((r as Dictionary).get("login", "")) if r is Dictionary else ""

## Id del gist de las partidas, "" si no hay (con `last_error` vacío) o si falló la búsqueda.
func find() -> String:
	for page in range(1, MAX_PAGES + 1):
		var r: Variant = await _api(HTTPClient.METHOD_GET, "/gists?per_page=100&page=%d" % page)
		if r is not Array: return ""
		for g: Dictionary in r:
			if (g.get("files", {}) as Dictionary).has(marker): return String(g.id)
		if (r as Array).size() < 100: break
	return ""

## Crea el gist secreto con estos ficheros (nombre -> texto) y el marcador. Devuelve su id.
func create(files: Dictionary) -> String:
	var all := files.duplicate()
	all[marker] = JSON.stringify({"game": DESCRIPTION})
	var r: Variant = await _api(HTTPClient.METHOD_POST, "/gists",
		{"description": DESCRIPTION, "public": false, "files": _contents(all)})
	return String((r as Dictionary).get("id", "")) if r is Dictionary else ""

## Lee los ficheros del gist (nombre -> texto, sin el marcador), o null si falla.
func read(id: String) -> Variant:
	var r: Variant = await _api(HTTPClient.METHOD_GET, "/gists/" + id)
	if r is not Dictionary: return null
	var out := {}
	for name: String in (r.get("files", {}) as Dictionary):
		if name == marker: continue
		var f: Dictionary = r.files[name]
		var text := String(f.get("content", ""))
		if f.get("truncated", false):                # más de 1 MB: el texto entero está en raw_url
			var raw: Dictionary = await http.request(HTTPClient.METHOD_GET, String(f.raw_url), _headers())
			if int(raw.code) != 200:
				last_error = _error_of(int(raw.code))
				return null
			text = raw.body
		out[name] = text
	return out

## Escribe estos ficheros (nombre -> texto; null borra el fichero). Los demás quedan como están.
func write(id: String, files: Dictionary) -> bool:
	var r: Variant = await _api(HTTPClient.METHOD_PATCH, "/gists/" + id, {"files": _contents(files)})
	return r is Dictionary

## Borra el gist entero (pruebas y «Borrar la copia de la nube»).
func delete(id: String) -> bool:
	last_error = ""
	var r: Dictionary = await http.request(HTTPClient.METHOD_DELETE, API + "/gists/" + id, _headers())
	if int(r.code) != 204:
		last_error = _error_of(int(r.code))
		return false
	return true

# --- Detalles -----------------------------------------------------------------------------------

func _contents(files: Dictionary) -> Dictionary:
	var out := {}
	for name: String in files:
		out[name] = null if files[name] == null else {"content": String(files[name])}
	return out

func _headers() -> PackedStringArray:
	return PackedStringArray(["Accept: application/vnd.github+json", "Authorization: Bearer " + token,
		"X-GitHub-Api-Version: 2022-11-28", "User-Agent: LovecraftLibrary"])

## Llamada a la API: el JSON de la respuesta o null (con `last_error`).
func _api(method: int, path: String, body: Variant = null) -> Variant:
	last_error = ""
	var headers := _headers()
	if body != null: headers.append("Content-Type: application/json")
	var r: Dictionary = await http.request(method, API + path, headers, "" if body == null else JSON.stringify(body))
	var code := int(r.code)
	if code < 200 or code >= 300:
		last_error = _error_of(code)
		return null
	var parsed: Variant = JSON.parse_string(String(r.body))
	if parsed == null: last_error = "other"
	return parsed

## Formulario de github.com (autorización): JSON de la respuesta o null.
func _form(url: String, fields: Dictionary) -> Variant:
	last_error = ""
	var parts := PackedStringArray()
	for k: String in fields: parts.append("%s=%s" % [k, String(fields[k]).uri_encode()])
	var headers := PackedStringArray(["Accept: application/json", "User-Agent: LovecraftLibrary",
		"Content-Type: application/x-www-form-urlencoded"])
	var r: Dictionary = await http.request(HTTPClient.METHOD_POST, url, headers, "&".join(parts))
	var code := int(r.code)
	if code < 200 or code >= 300:
		last_error = _error_of(code)
		return null
	return JSON.parse_string(String(r.body))

static func _error_of(code: int) -> String:
	match code:
		0: return "net"
		401: return "auth"
		403, 429: return "limit"
		404: return "missing"
	return "other"
