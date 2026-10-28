class_name NetLog
extends RefCounted
## Registro de red en un fichero (hito 9.6c): uno por sesión en `user://logs/red/`, con hora en
## cada línea, para revisar después de una partida por internet lo que pasó (quién entró o se
## fue, rechazos, cortes, avisos de conexión y, cada 5 s, cómo iba la partida y lo que salía).
## Se guardan los `KEEP` últimos. Lo lleva `NetSession` (`Net.netlog`); `NetGame` añade lo suyo.

const DIR := "user://logs/red"
const KEEP := 10

var dir := _default_dir()                    ## otra carpeta en las pruebas

## Con GUT, las sesiones de las pruebas escriben aparte: no echan los registros de verdad.
static func _default_dir() -> String:
	for a in OS.get_cmdline_args():
		if a.ends_with("gut_cmdln.gd"): return "user://logs/red_pruebas"
	return DIR
var path := ""
var _f: FileAccess
var _known := {}                             ## PC -> nombre (para apuntar quién entra y quién se va)

## Empieza un fichero nuevo: `role` ("Anfitrión", "Invitado") y lo que sirva para situarlo.
func open(role: String, detail: String) -> void:
	close()
	DirAccess.make_dir_recursive_absolute(dir)
	_prune()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var base := "%s/red_%s" % [dir, stamp]
	path = base + ".log"
	var n := 2
	while FileAccess.file_exists(path):              # dos sesiones en el mismo segundo (pruebas): cada una el suyo
		path = "%s_%d.log" % [base, n]
		n += 1
	_f = FileAccess.open(path, FileAccess.WRITE)
	_known.clear()
	if _f == null: return
	line("%s · %s" % [role, detail])
	line("Versión %s · protocolo %d · %s %s" % [ProjectSettings.get_setting("application/config/version", "?"),
		NetSession.PROTOCOL, OS.get_name(), OS.get_version()])

## Abre la carpeta de registros en el explorador (menú online y pantalla final del invitado).
static func open_folder() -> void:
	OS.shell_open(ProjectSettings.globalize_path(DIR))

## Final del nombre de la captura de una marca de otro PC: "_de_Ana" (solo letras, cifras y _;
## tools/marcas.py lo rehace igual con el nombre del registro).
static func shot_suffix(from: String) -> String:
	if from == "": return ""
	var re := RegEx.create_from_string("[^A-Za-z0-9]")
	return "_de_" + re.sub(from, "_", true)

## La captura de marca más reciente de la carpeta ("" si no hay ninguna).
static func latest_shot() -> String:
	var best := ""
	var best_t := 0
	if not DirAccess.dir_exists_absolute(DIR): return ""
	for f in DirAccess.get_files_at(DIR):
		if not (f.begins_with("red_") and "_marca_" in f and f.ends_with(".png")): continue
		var t := FileAccess.get_modified_time("%s/%s" % [DIR, f])
		if t >= best_t:
			best_t = t
			best = "%s/%s" % [DIR, f]
	return best

func is_open() -> bool:
	return _f != null

func line(text: String) -> void:
	if _f == null: return
	_f.store_line("[%s] %s" % [Time.get_time_string_from_system(), text])
	_f.flush()                                   # si el juego se cuelga, que quede lo último

func close(reason := "") -> void:
	if _f == null: return
	line("Fin de la sesión" + (": " + reason if reason != "" else ""))
	_f.close()
	_f = null

## Apunta los cambios en la lista de conectados (quién entra y quién se va).
func roster(peers: Dictionary, me: int) -> void:
	for id: int in peers:
		if id != me and not _known.has(id):
			line("Entra %s (PC %d, versión %s)" % [peers[id].get("name", "?"), id, peers[id].get("ver", "?")])
	for id: int in _known:
		if not peers.has(id): line("Se va %s (PC %d)" % [_known[id], id])
	_known.clear()
	for id: int in peers:
		if id != me: _known[id] = String(peers[id].get("name", "?"))

## Borra los más antiguos para que, con el nuevo, queden `KEEP`.
func _prune() -> void:
	var files: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("red_") and f.ends_with(".log"): files.append(f)
	files.sort()
	var all := DirAccess.get_files_at(dir)
	while files.size() >= KEEP:
		var old := files.pop_front() as String
		DirAccess.remove_absolute("%s/%s" % [dir, old])
		for f in all:                                # y las capturas de sus marcas (<registro>_marca_N.png)
			if f.begins_with(old.get_basename() + "_marca_"): DirAccess.remove_absolute("%s/%s" % [dir, f])
