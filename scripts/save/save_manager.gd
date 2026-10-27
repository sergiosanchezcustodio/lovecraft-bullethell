extends Node
## Huecos de partida (autoload `Saves`): tres partidas locales en `user://saves/slot_N.json`.
## Se elige un hueco al salir de la portada; a partir de ahí `current` es su partida y el
## juego la guarda al terminar cada nivel y al salir.
## Escritura segura: se escribe en un fichero temporal y se renombra, para no dejar una
## partida a medias si el juego se cierra mientras guarda.

const SLOTS := 3

signal saved(slot: int)                  ## se guardó un hueco (la nube lo sube: `Cloud`)
signal deleted(slot: int, rev: int)      ## se borró un hueco con esa revisión

var dir := "user://saves"                ## los tests usan otra carpeta
var slot := -1                           ## hueco en uso (0..2), -1 = ninguno
var current: SaveData

func _ready() -> void:
	# `saves=carpeta` detrás de `--`: otra carpeta de partidas (capturas y pruebas sin tocar las reales)
	var la := LaunchArgs.from_cmdline()
	if la.has("saves"): dir = "user://" + la.get_str("saves")
	if la.has("slot"): use(clampi(la.get_int("slot") - 1, 0, SLOTS - 1))   # `slot=2`: jugar con ese hueco

func path(i: int) -> String:
	return dir.path_join("slot_%d.json" % (i + 1))

func exists(i: int) -> bool:
	return FileAccess.file_exists(path(i))

## Lee un hueco sin elegirlo (para mostrar su resumen). null si está vacío o ilegible.
func peek(i: int) -> SaveData:
	if not exists(i): return null
	var f := FileAccess.open(path(i), FileAccess.READ)
	if f == null: return null
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed is not Dictionary:
		push_warning("Partida ilegible: " + path(i))
		return null
	return SaveData.from_dict(parsed)

## Elige un hueco: carga su partida o empieza una nueva si está vacío.
func use(i: int) -> SaveData:
	slot = i
	current = peek(i)
	if current == null:
		current = SaveData.create()
		save()
	return current

## Guarda la partida en uso (una revisión más).
func save() -> bool:
	if slot < 0 or current == null: return false
	current.updated = Time.get_datetime_string_from_system()
	current.saved_with = SaveData.game_version()
	current.rev += 1
	current.device = Cloud.device_name
	if not store(slot, current): return false
	saved.emit(slot)
	return true

## Escribe una partida en un hueco tal cual, sin contar revisión (lo que baja de la nube).
func store(i: int, d: SaveData) -> bool:
	DirAccess.make_dir_recursive_absolute(dir)
	var tmp := path(i) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo guardar la partida: " + tmp)
		return false
	f.store_string(JSON.stringify(d.to_dict(), "	"))
	f.close()
	var err := DirAccess.rename_absolute(tmp, path(i))
	if err != OK:
		push_error("No se pudo guardar la partida (%d): %s" % [err, path(i)])
		return false
	if i == slot: current = d
	return true

## Copia aparte de una partida que se descarta (un conflicto con la nube, 27-10-2026), junto a los
## huecos: `slot_N.descartada_<fecha>.json`, que el juego no lee. Para recuperarla, se renombra a
## `slot_N.json`: va como nunca subida (`cloud_base` -1), así que la nube la da por conflicto y se
## elige otra vez. Devuelve la ruta, o "" si no se pudo escribir.
func backup(i: int, d: SaveData) -> String:
	DirAccess.make_dir_recursive_absolute(dir)
	var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("T", "_")
	var p := dir.path_join("slot_%d.descartada_%s.json" % [i + 1, stamp])
	var n := 2
	while FileAccess.file_exists(p):                # dos en el mismo segundo: no se pisan
		p = dir.path_join("slot_%d.descartada_%s_%d.json" % [i + 1, stamp, n])
		n += 1
	var f := FileAccess.open(p, FileAccess.WRITE)
	if f == null: return ""
	var dd := d.to_dict()
	dd.cloud_base = -1
	f.store_string(JSON.stringify(dd, "	"))
	return p

## Copias de partidas descartadas de un hueco (rutas, de la más antigua a la más nueva).
func backups(i: int) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("slot_%d.descartada_" % (i + 1)): out.append(dir.path_join(f))
	out.sort()
	return out

## Apunta que la nube tiene la revisión `rev` de un hueco (después de subirlo). Solo toca las
## revisiones: si se guardó otra vez mientras subía, eso no se pierde y queda por subir.
func mark_synced(i: int, rev: int) -> void:
	var d := peek(i)
	if d == null: return
	d.rev = maxi(d.rev, rev)
	d.cloud_base = rev
	if i == slot and current != null:
		current.rev = maxi(current.rev, rev)
		current.cloud_base = rev
	var keep := current
	store(i, d)
	current = keep                       # la partida en uso sigue siendo el mismo objeto

## Crea en un hueco la partida de pruebas (todo desbloqueado), sustituyendo lo que hubiera.
func make_test_save(i: int) -> void:
	slot = i
	current = SaveData.create_test()
	save()

## Borra un hueco: queda como nuevo.
func delete(i: int) -> void:
	if exists(i):
		var d := peek(i)
		DirAccess.remove_absolute(path(i))
		deleted.emit(i, d.rev if d != null else 0)
	if i == slot:
		slot = -1
		current = null

## Suma tiempo jugado a la partida en uso (la partida lo llama cada fotograma).
func add_play_time(seconds: float) -> void:
	if current != null: current.play_time += seconds

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save()   # al cerrar la ventana
