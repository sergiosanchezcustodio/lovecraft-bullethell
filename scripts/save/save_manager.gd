extends Node
## Huecos de partida (autoload `Saves`): tres partidas locales en `user://saves/slot_N.json`.
## Se elige un hueco al salir de la portada; a partir de ahí `current` es su partida y el
## juego la guarda al terminar cada nivel y al salir.
## Escritura segura: se escribe en un fichero temporal y se renombra, para no dejar una
## partida a medias si el juego se cierra mientras guarda.

const SLOTS := 3

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

## Guarda la partida en uso.
func save() -> bool:
	if slot < 0 or current == null: return false
	DirAccess.make_dir_recursive_absolute(dir)
	current.updated = Time.get_datetime_string_from_system()
	var tmp := path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo guardar la partida: " + tmp)
		return false
	f.store_string(JSON.stringify(current.to_dict(), "\t"))
	f.close()
	var err := DirAccess.rename_absolute(tmp, path(slot))
	if err != OK:
		push_error("No se pudo guardar la partida (%d): %s" % [err, path(slot)])
		return false
	return true

## Crea en un hueco la partida de pruebas (todo desbloqueado), sustituyendo lo que hubiera.
func make_test_save(i: int) -> void:
	slot = i
	current = SaveData.create_test()
	save()

## Borra un hueco: queda como nuevo.
func delete(i: int) -> void:
	if exists(i): DirAccess.remove_absolute(path(i))
	if i == slot:
		slot = -1
		current = null

## Suma tiempo jugado a la partida en uso (la partida lo llama cada fotograma).
func add_play_time(seconds: float) -> void:
	if current != null: current.play_time += seconds

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: save()   # al cerrar la ventana
