extends GutTest
## Nube (hito 10.1): cliente de GitHub y autoload `Cloud` con un transporte falso, sin red.

const CloudScript := preload("res://scripts/cloud/cloud.gd")

## Transporte falso: responde por orden lo que se le encola y apunta cada petición.
class FakeHttp:
	var replies: Array = []                  ## [método o -1, trozo de la URL, código, cuerpo (Variant)]
	var log: Array = []                      ## [método, url, cuerpo]
	func reply(method: int, url_part: String, code: int, body: Variant = {}) -> void:
		replies.append([method, url_part, code, body])
	func request(method: int, url: String, _headers: PackedStringArray, body := "") -> Dictionary:
		log.append([method, url, body])
		for i in replies.size():
			var r: Array = replies[i]
			if (r[0] == -1 or r[0] == method) and url.contains(r[1]):
				replies.remove_at(i)
				return {"code": r[2], "body": r[3] if r[3] is String else JSON.stringify(r[3])}
		return {"code": 0, "body": ""}       # sin respuesta: como sin conexión

var http: FakeHttp
var g: GitHubGist

func before_each() -> void:
	http = FakeHttp.new()
	g = GitHubGist.new(http)
	g.token = "t"

func _gist(id: String, files: Array) -> Dictionary:
	var f := {}
	for n: String in files: f[n] = {"filename": n}
	return {"id": id, "files": f}

func test_codigo_de_dispositivo() -> void:
	http.reply(HTTPClient.METHOD_POST, "/login/device/code", 200,
		{"device_code": "dc", "user_code": "ABCD-1234", "verification_uri": "https://github.com/login/device", "interval": 5, "expires_in": 900})
	var d: Dictionary = await g.start_device("cid")
	assert_eq(d.user_code, "ABCD-1234")
	assert_string_contains(http.log[0][2], "client_id=cid")
	assert_string_contains(http.log[0][2], "scope=gist")

func test_espera_y_token_al_aprobar() -> void:
	http.reply(HTTPClient.METHOD_POST, "access_token", 200, {"error": "authorization_pending"})
	http.reply(HTTPClient.METHOD_POST, "access_token", 200, {"access_token": "gho_x", "token_type": "bearer"})
	assert_eq((await g.poll_device("cid", "dc")).error, "authorization_pending")
	assert_eq((await g.poll_device("cid", "dc")).token, "gho_x")
	assert_string_contains(http.log[0][2], "device_code=dc")

func test_sin_conexion_al_esperar() -> void:
	assert_eq((await g.poll_device("cid", "dc")).error, "net")

func test_busca_el_gist_por_el_marcador_en_varias_paginas() -> void:
	var page1 := []
	for i in 100: page1.append(_gist("otro%d" % i, ["a.txt"]))
	http.reply(HTTPClient.METHOD_GET, "page=1", 200, page1)
	http.reply(HTTPClient.METHOD_GET, "page=2", 200, [_gist("x", ["b.txt"]), _gist("bueno", [GitHubGist.MARKER, "slot_1.json"])])
	assert_eq(await g.find(), "bueno")
	assert_eq(g.last_error, "")

func test_no_lo_encuentra_sin_error() -> void:
	http.reply(HTTPClient.METHOD_GET, "page=1", 200, [_gist("x", ["b.txt"])])
	assert_eq(await g.find(), "")
	assert_eq(g.last_error, "")
	assert_eq(http.log.size(), 1, "una página corta es la última")

func test_crea_secreto_con_marcador() -> void:
	http.reply(HTTPClient.METHOD_POST, "/gists", 201, {"id": "nuevo"})
	assert_eq(await g.create({"slot_1.json": "{}"}), "nuevo")
	var body: Dictionary = JSON.parse_string(http.log[0][2])
	assert_false(body.public)
	assert_true(body.files.has(GitHubGist.MARKER))
	assert_eq(body.files["slot_1.json"].content, "{}")

func test_lee_sin_el_marcador_y_sigue_los_truncados() -> void:
	http.reply(HTTPClient.METHOD_GET, "/gists/id1", 200, {"id": "id1", "files": {
		GitHubGist.MARKER: {"content": "{}"}, "slot_1.json": {"content": "uno"},
		"slot_2.json": {"content": "tro", "truncated": true, "raw_url": "https://raw/slot_2"}}})
	http.reply(HTTPClient.METHOD_GET, "raw/slot_2", 200, "trozo entero")
	var files: Dictionary = await g.read("id1")
	assert_eq(files, {"slot_1.json": "uno", "slot_2.json": "trozo entero"})

func test_escribir_null_borra_el_fichero() -> void:
	http.reply(HTTPClient.METHOD_PATCH, "/gists/id1", 200, {"id": "id1"})
	assert_true(await g.write("id1", {"slot_1.json": "a", "slot_3.json": null}))
	var body: Dictionary = JSON.parse_string(http.log[0][2])
	assert_eq(body.files["slot_1.json"].content, "a")
	assert_true(body.files.has("slot_3.json") and body.files["slot_3.json"] == null)

func test_errores_por_codigo() -> void:
	for c: Array in [[401, "auth"], [403, "limit"], [404, "missing"], [500, "other"]]:
		http.reply(-1, "/user", c[0])
		assert_eq(await g.user_login(), "")
		assert_eq(g.last_error, c[1])

# --- Autoload ---------------------------------------------------------------------------------

func _cloud() -> Node:
	var c: Node = CloudScript.new()
	c.path = "user://cloud_pruebas.json"
	add_child_autofree(c)
	c.gist.http = http
	c.client_id = "cid"
	c.disconnect_github()
	return c

func test_conecta_por_dispositivo() -> void:
	var c := _cloud()
	http.reply(HTTPClient.METHOD_POST, "/login/device/code", 200,
		{"device_code": "dc", "user_code": "WXYZ-9876", "verification_uri": "https://github.com/login/device", "interval": 0, "expires_in": 60})
	http.reply(HTTPClient.METHOD_POST, "access_token", 200, {"error": "authorization_pending"})
	http.reply(HTTPClient.METHOD_POST, "access_token", 200, {"access_token": "gho_y"})
	http.reply(HTTPClient.METHOD_GET, "/user", 200, {"login": "lector"})
	var seen := []
	c.changed.connect(func() -> void: if not c.pending.is_empty(): seen.append(c.pending.user_code))
	assert_true(await c.connect_github())
	assert_eq(seen.front(), "WXYZ-9876", "enseña el código mientras espera")
	assert_eq([c.token, c.login, c.pending], ["gho_y", "lector", {}])
	assert_eq(JSON.parse_string(FileAccess.get_file_as_string(c.path)).token, "gho_y", "lo recuerda")

func test_sin_client_id_no_conecta() -> void:
	var c := _cloud()
	c.client_id = ""
	assert_false(await c.connect_github())
	assert_eq(c.error, "no_client")
	assert_eq(http.log.size(), 0)

func test_rechazo_al_conectar() -> void:
	var c := _cloud()
	http.reply(HTTPClient.METHOD_POST, "/login/device/code", 200, {"device_code": "dc", "user_code": "A", "verification_uri": "u", "interval": 0})
	http.reply(HTTPClient.METHOD_POST, "access_token", 200, {"error": "access_denied"})
	assert_false(await c.connect_github())
	assert_eq(c.error, "access_denied")
	assert_false(c.connected())

func test_crea_el_gist_la_primera_vez_y_escribe() -> void:
	var c := _cloud()
	c._set_token("t")
	http.reply(HTTPClient.METHOD_GET, "page=1", 200, [])
	http.reply(HTTPClient.METHOD_POST, "/gists", 201, {"id": "g1"})
	http.reply(HTTPClient.METHOD_PATCH, "/gists/g1", 200, {"id": "g1"})
	assert_true(await c.push({"slot_1.json": "{}"}))
	assert_eq(c.gist_id, "g1")
	var body: Dictionary = JSON.parse_string(http.log[2][2])
	assert_true(body.files.has("meta.json"), "con meta.json")

func test_si_borraron_el_gist_lo_busca_otra_vez() -> void:
	var c := _cloud()
	c._set_token("t")
	c.gist_id = "viejo"
	http.reply(HTTPClient.METHOD_GET, "/gists/viejo", 404)
	http.reply(HTTPClient.METHOD_GET, "page=1", 200, [_gist("g2", [GitHubGist.MARKER])])
	http.reply(HTTPClient.METHOD_GET, "/gists/g2", 200, {"id": "g2", "files": {"slot_1.json": {"content": "x"}}})
	assert_eq(await c.fetch(), {"slot_1.json": "x"})
	assert_eq([c.gist_id, c.error], ["g2", ""])

func test_token_revocado_lo_olvida() -> void:
	var c := _cloud()
	c._set_token("t")
	c.gist_id = "g1"
	http.reply(HTTPClient.METHOD_GET, "/gists/g1", 401)
	assert_eq(await c.fetch(), null)
	assert_eq(c.error, "auth")
	assert_false(c.connected())

func test_sin_conexion_no_pierde_nada() -> void:
	var c := _cloud()
	c._set_token("t")
	c.gist_id = "g1"
	assert_false(await c.push({"slot_1.json": "{}"}))
	assert_eq(c.error, "net")
	assert_true(c.connected(), "sigue conectado: lo intenta en el siguiente guardado")
	assert_eq(c.gist_id, "g1")
