extends GutTest
## Nube (hito 10.2): decisión por revisiones y sincronización de dos PC contra un GitHub falso.

const CloudScript := preload("res://scripts/cloud/cloud.gd")
const SavesScript := preload("res://scripts/save/save_manager.gd")

## GitHub falso con gists de verdad en memoria: lo comparten los dos PC.
class FakeGitHub:
	var gists := {}                          ## id -> {nombre: texto}
	var online := true
	var _n := 0
	func request(method: int, url: String, _headers: PackedStringArray, body := "") -> Dictionary:
		if not online: return {"code": 0, "body": ""}
		var path := url.replace(GitHubGist.API, "")
		if path.begins_with("/gists?"):
			var list := []
			for id: String in gists:
				var f := {}
				for n: String in gists[id]: f[n] = {"filename": n}
				list.append({"id": id, "files": f})
			return _ok(200, list)
		if path == "/gists" and method == HTTPClient.METHOD_POST:
			_n += 1
			var id := "g%d" % _n
			gists[id] = {}
			_apply(id, JSON.parse_string(body).files)
			return _ok(201, {"id": id})
		var id := path.trim_prefix("/gists/")
		if not gists.has(id): return {"code": 404, "body": "{}"}
		match method:
			HTTPClient.METHOD_GET:
				var f := {}
				for n: String in gists[id]: f[n] = {"content": gists[id][n]}
				return _ok(200, {"id": id, "files": f})
			HTTPClient.METHOD_PATCH:
				_apply(id, JSON.parse_string(body).files)
				return _ok(200, {"id": id})
			HTTPClient.METHOD_DELETE:
				gists.erase(id)
				return {"code": 204, "body": ""}
		return {"code": 500, "body": ""}
	func _apply(id: String, files: Dictionary) -> void:
		for n: String in files:
			if files[n] == null: (gists[id] as Dictionary).erase(n)
			else: gists[id][n] = files[n].content
	func _ok(code: int, d: Variant) -> Dictionary:
		return {"code": code, "body": JSON.stringify(d)}
	func file(n: String) -> Variant:
		for id: String in gists: return (gists[id] as Dictionary).get(n)
		return null

## Configuración falsa: solo los controles.
class FakeSettings:
	var d := {"rev": 0, "cloud_base": 0, "keys": {}, "joy": {}}
	func controls_dict() -> Dictionary:
		return d.duplicate(true)
	func store_controls(c: Dictionary) -> void:
		d = {"rev": int(c.rev), "cloud_base": int(c.rev), "keys": c.keys.duplicate(), "joy": c.joy.duplicate()}
	func set_key(a: String, k: int) -> void:
		d.keys[a] = k
		d.rev += 1

var hub: FakeGitHub

## Un PC: sus huecos en su carpeta y su `Cloud`, conectados al GitHub falso.
func _pc(tag: String) -> Node:
	var s: Node = SavesScript.new()
	s.dir = "user://saves_nube_%s" % tag
	add_child_autofree(s)
	for i in s.SLOTS:
		s.delete(i)
		for f in s.backups(i): DirAccess.remove_absolute(f)
	var c: Node = CloudScript.new()
	c.wire = false
	c.path = "user://cloud_pruebas_%s.json" % tag
	add_child_autofree(c)
	c.disconnect_github()
	c.deleted = {}
	c.auto = true
	c.gist.http = hub
	c._set_token("t")
	c.saves = s
	c.settings = FakeSettings.new()
	c.auto_delay = 0.0
	s.saved.connect(func(i: int) -> void: c._queue(CloudSync.slot_file(i)))
	s.deleted.connect(c._on_deleted)
	return c

## Juega en un hueco: lo elige, gana dinero y guarda.
func _play(c: Node, slot: int, money: int) -> void:
	c.saves.use(slot)
	c.saves.current.money += money
	c.saves.save()

## Dinero de las copias de partidas descartadas de un hueco.
func _backup_money(c: Node, slot: int) -> Array:
	var out := []
	for f: String in c.saves.backups(slot):
		out.append(int(JSON.parse_string(FileAccess.get_file_as_string(f)).money))
	return out

func _money(c: Node, slot: int) -> int:
	var d: SaveData = c.saves.peek(slot)
	return d.money if d != null else -1

func before_each() -> void:
	hub = FakeGitHub.new()

# --- Decisión -----------------------------------------------------------------------------------

func test_decision_por_revisiones() -> void:
	var D := CloudSync
	assert_eq(D.decide(null, null), D.NOTHING)
	assert_eq(D.decide({"rev": 3, "cloud_base": -1}, null), D.UPLOAD, "nunca subida")
	assert_eq(D.decide(null, {"rev": 4}), D.DOWNLOAD, "PC nuevo")
	assert_eq(D.decide({"rev": 5, "cloud_base": 4}, {"rev": 4}), D.UPLOAD, "jugada aquí")
	assert_eq(D.decide({"rev": 4, "cloud_base": 4}, {"rev": 4}), D.NOTHING)
	assert_eq(D.decide({"rev": 4, "cloud_base": 4}, {"rev": 6}), D.DOWNLOAD, "jugada en otro PC")
	assert_eq(D.decide({"rev": 5, "cloud_base": 4}, {"rev": 6}), D.CONFLICT, "jugada en los dos")
	assert_eq(D.decide({"rev": 2, "cloud_base": -1}, {"rev": 6}), D.CONFLICT, "dos partidas distintas")
	assert_eq(D.decide({"rev": 4, "cloud_base": 7}, {"rev": 3}), D.UPLOAD, "la nube va por detrás")
	assert_eq(D.decide(null, {"rev": 4}, 4), D.DELETE_CLOUD, "borrada aquí")
	assert_eq(D.decide(null, {"rev": 5}, 4), D.DOWNLOAD, "borrada aquí, pero jugada después en otro PC")

func test_migra_las_partidas_de_la_version_1() -> void:
	var d := SaveData.from_dict({"version": 1, "money": 7})
	assert_eq([d.rev, d.cloud_base, d.money], [0, -1, 7])
	assert_eq(int(d.to_dict().version), 2)

# --- Dos PC -------------------------------------------------------------------------------------

func test_lo_jugado_en_un_pc_aparece_en_el_otro() -> void:
	var a := _pc("a")
	var b := _pc("b")
	_play(a, 0, 100)
	assert_true(await a.sync())
	assert_eq(int(JSON.parse_string(hub.file("slot_1.json")).money), 100)
	assert_eq(a.saves.peek(0).cloud_base, a.saves.peek(0).rev, "apunta lo subido")
	assert_true(await b.sync())
	assert_eq(_money(b, 0), 100, "el PC nuevo la baja")
	_play(b, 0, 50)
	assert_true(await b.sync())
	assert_true(await a.sync())
	assert_eq(_money(a, 0), 150, "y vuelve al primero")
	assert_eq(a.saves.current.money, 150, "también la partida en uso")
	assert_eq(a.conflicts, [])

func test_conflicto_y_eleccion() -> void:
	var a := _pc("a")
	var b := _pc("b")
	_play(a, 0, 100)
	await a.sync()
	await b.sync()
	_play(a, 0, 10)                                  # los dos juegan sin conexión
	_play(b, 0, 20)
	await a.sync()
	await b.sync()
	assert_eq(b.conflicts.size(), 1)
	var c: Dictionary = b.conflict_of(0)
	assert_eq([c.local.money, c.cloud.money], [120, 110])
	assert_eq(_money(b, 0), 120, "hasta elegir, no cambia nada")
	assert_true(await b.resolve(0, false))           # se queda la de este PC
	assert_eq(b.conflicts, [])
	assert_eq(_backup_money(b, 0), [110], "la de la nube queda aparte en este PC")
	assert_eq(b.last_backup, b.saves.backups(0)[0])
	await a.sync()
	assert_eq(_money(a, 0), 120, "la elegida llega al otro PC")
	assert_eq(a.conflicts, [])

func test_elegir_la_de_la_nube() -> void:
	var a := _pc("a")
	var b := _pc("b")
	_play(a, 1, 100)
	await a.sync()
	_play(b, 1, 5)                                   # otra partida en el mismo hueco, nunca subida
	await b.sync()
	assert_eq(b.conflicts.size(), 1)
	assert_true(await b.resolve(1, true))
	assert_eq(_money(b, 1), 100)
	assert_eq(_backup_money(b, 1), [5], "la de este PC queda aparte")
	assert_true(b.saves.backups(0).is_empty() and b.saves.backups(2).is_empty())
	assert_eq(b.saves.current.money, 100, "también la partida en uso")
	assert_true(await b.sync())
	assert_eq(b.conflicts, [], "queda en sintonía")
	# recuperar la copia: se pone en el hueco, la nube la da por conflicto y se elige esta
	var copy := SaveData.from_dict(JSON.parse_string(FileAccess.get_file_as_string(b.saves.backups(1)[0])))
	b.saves.store(1, copy)
	assert_true(await b.sync())
	assert_eq(b.conflicts.size(), 1, "la recuperada sale como conflicto")
	assert_true(await b.resolve(1, false))
	assert_eq(_money(b, 1), 5, "y queda la recuperada")
	await a.sync()
	assert_eq(_money(a, 1), 5, "también en el otro PC")

func test_en_partida_no_cambia_el_hueco_en_uso() -> void:
	var a := _pc("a")
	var b := _pc("b")
	_play(a, 0, 100)
	await a.sync()
	await b.sync()
	b.saves.use(0)                                   # B está jugando en ese hueco
	_play(a, 0, 10)
	await a.sync()
	await b.sync([], true)
	assert_eq([b.saves.current.money, _money(b, 0)], [100, 100], "no cambia la partida a mitad")
	await b.sync()                                   # ya en los menús
	assert_eq([b.saves.current.money, _money(b, 0)], [110, 110])

func test_subida_automatica_al_guardar() -> void:
	var a := _pc("a")
	_play(a, 2, 30)
	_play(a, 2, 30)                                  # dos guardados seguidos: una subida
	await wait_until(func() -> bool: return hub.file("slot_3.json") != null and not a.syncing, 3.0)
	assert_eq(int(JSON.parse_string(hub.file("slot_3.json")).money), 60)

func test_sin_conexion_no_apunta_nada() -> void:
	var a := _pc("a")
	_play(a, 0, 100)
	hub.online = false
	assert_false(await a.sync())
	assert_eq(a.saves.peek(0).cloud_base, -1)
	hub.online = true
	assert_true(await a.sync())
	assert_eq(a.saves.peek(0).cloud_base, a.saves.peek(0).rev)

func test_borrar_un_hueco_lo_borra_en_la_nube() -> void:
	var a := _pc("a")
	a.auto = false
	_play(a, 0, 100)
	await a.sync()
	a.saves.delete(0)
	assert_true(await a.sync())
	assert_null(hub.file("slot_1.json"))
	assert_true(a.deleted.is_empty())
	assert_true(await a.sync())
	assert_false(a.saves.exists(0), "no vuelve a bajar")

func test_controles() -> void:
	var a := _pc("a")
	var b := _pc("b")
	await b.sync()                                   # B, de fábrica, no pisa nada
	a.settings.set_key("dodge", KEY_SHIFT)
	await a.sync()
	await b.sync()
	assert_eq(int(b.settings.d.keys.dodge), KEY_SHIFT, "llegan al otro PC")
	b.settings.set_key("dodge", KEY_CTRL)
	a.settings.set_key("dodge", KEY_ALT)
	await b.sync()
	await a.sync()                                   # cambiados en los dos: se quedan los de este PC
	assert_eq(int(JSON.parse_string(hub.file("controles.json")).keys.dodge), KEY_ALT)
	await b.sync()
	assert_eq(int(b.settings.d.keys.dodge), KEY_ALT)

func test_copias_descartadas_no_se_pisan() -> void:
	var a := _pc("a")
	_play(a, 2, 7)
	var d: SaveData = a.saves.peek(2)
	a.saves.backup(2, d)
	d.money = 8
	a.saves.backup(2, d)
	assert_eq(_backup_money(a, 2), [7, 8], "dos en el mismo segundo")
	assert_eq(a.saves.peek(2).money, 7, "el hueco no se toca")

func test_enlace_del_gist() -> void:
	var a := _pc("a")
	a.gist_id = ""
	assert_eq(a.gist_url(), "", "sin gist, sin enlace")
	a.gist_id = "abc123"
	a.login = "investigador"
	assert_eq(a.gist_url(), "https://gist.github.com/investigador/abc123")
