class_name CrashReport
extends Node
## Informe de errores (hito 19.9). Al arrancar de verdad (sin opciones de prueba), deja una marca
## (`MARK`) que se borra al salir bien (`_exit_tree`, que también llega con `get_tree().quit()`).
## Si al volver la marca sigue ahí, el juego se cerró de golpe: el menú principal ofrece guardar en
## Documentos un .zip con el registro de aquella vez (Godot lo rota a `user://logs/godot<fecha>.log`
## al arrancar), la configuración y los datos del equipo. Nada sale del PC: el jugador lo envía si quiere.
## `crash_report=true` arma la marca en una ejecución de prueba; `crash_demo=true` hace como si la
## anterior se hubiera cerrado mal (capturas).

const MARK := "user://running.json"
const LOGS := "user://logs"

static var _pending := {}          ## lo que dejó la marca de la vez anterior; vacío si salió bien
static var _armed := false

## La llama main.gd al arrancar. `real`: arranque normal o `crash_report=true`.
static func start(tree: SceneTree, real: bool, demo := false) -> void:
	_pending = {}
	if FileAccess.file_exists(MARK):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(MARK))
		_pending = d if d is Dictionary and not (d as Dictionary).is_empty() else {"version": "?"}
	if demo and _pending.is_empty(): _pending = {"version": Demo.version_text(), "started": "demo", "where": "p2_n2"}
	if not real: return
	_armed = true
	_write({"version": Demo.version_text(), "started": Time.get_datetime_string_from_system(), "where": "portada"})
	tree.root.add_child.call_deferred(CrashReport.new())

static func pending() -> bool:
	return not _pending.is_empty()

## Ya se ha preguntado: no vuelve a salir.
static func dismiss() -> void:
	_pending = {}

## Dónde va el jugador (nivel o pantalla), para el informe si se cierra ahí.
static func note(where: String) -> void:
	if not _armed or not FileAccess.file_exists(MARK): return
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(MARK))
	if d is not Dictionary: d = {}
	d["where"] = where
	_write(d)

static func _write(d: Dictionary) -> void:
	var f := FileAccess.open(MARK, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))

func _exit_tree() -> void:
	if _armed: DirAccess.remove_absolute(ProjectSettings.globalize_path(MARK))

## El registro de la vez anterior: el rotado más nuevo (el de ahora es `godot.log`).
static func previous_log(dir := LOGS) -> String:
	var best := ""
	var best_t := 0
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".log") or f == "godot.log": continue
		var t := FileAccess.get_modified_time(dir.path_join(f))
		if t >= best_t:
			best_t = t
			best = dir.path_join(f)
	return best

## Datos del equipo y de la partida, en texto.
static func info_text() -> String:
	var lines: Array[String] = [
		"Lovecraft Library: Surviving Cthulhu %s" % Demo.version_text(),
		"Informe guardado: %s" % Time.get_datetime_string_from_system(),
		"La vez que se cerró: empezó %s, iba por %s (versión %s)" % [_pending.get("started", "?"), _pending.get("where", "?"), _pending.get("version", "?")],
		"Sistema: %s %s" % [OS.get_name(), OS.get_version()],
		"Procesador: %s (%d hilos)" % [OS.get_processor_name(), OS.get_processor_count()],
		"Memoria: %d MB" % int(OS.get_memory_info().get("physical", 0) / 1048576),
		"Godot: %s" % Engine.get_version_info().get("string", ""),
		"Idioma: %s" % OS.get_locale(),
	]
	if DisplayServer.get_name() != "headless":
		lines.append("Tarjeta: %s (%s), %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor(), RenderingServer.get_video_adapter_api_version()])
		lines.append("Pantalla: %s, ventana %s" % [DisplayServer.screen_get_size(), DisplayServer.window_get_size()])
	lines.append("Dibujo: %s" % RenderingServer.get_current_rendering_method())
	return "\n".join(lines) + "\n"

## Guarda el informe en `dir` (Documentos si no se da). Devuelve la ruta del .zip, o "" si falla.
static func save(dir := "") -> String:
	if dir == "": dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if dir == "": dir = ProjectSettings.globalize_path("user://")
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var path := dir.path_join("LovecraftLibrary_informe_%s.zip" % stamp)
	var zip := ZIPPacker.new()
	if zip.open(path) != OK: return ""
	var files := {"equipo.txt": info_text().to_utf8_buffer()}
	var prev := previous_log()
	if prev != "": files["registro.log"] = FileAccess.get_file_as_bytes(prev)
	if FileAccess.file_exists(Settings.PATH): files["configuracion.json"] = FileAccess.get_file_as_bytes(Settings.PATH)
	for name: String in files:
		zip.start_file(name)
		zip.write_file(files[name])
		zip.close_file()
	zip.close()
	return path
