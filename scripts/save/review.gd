class_name Review
## Revisión de arte (temporal, 12-10-2026): lo que se ve en el menú "Revisión de arte" y el
## buzón de peticiones que Claude atiende mientras su sesión está abierta.
## - `sections()` y `entries(sección)`: cada imagen con un nombre descriptivo y el archivo del
##   que sale (modelo JSON o PNG), para recargarla cuando cambie en disco.
## - `review/peticiones.json` (fuera de la importación de Godot): lo que escribe el autor desde
##   el menú y lo que responde Claude (estado y respuesta). Solo en desarrollo: en una build
##   exportada res:// no se puede escribir y el menú no aparece.

const FILE := "res://review/peticiones.json"
## Variantes para elegir (28-10-2026): {"propuestas": [{modelo, nombre, nota, encuadre}]}; la
## pestaña Propuestas solo sale si hay alguna. encuadre "cabeza" acerca la vista grande a la cabeza.
const PROPOSALS := "res://review/propuestas.json"
const SECTIONS := [
	{"id": "propuestas", "title": "Propuestas"},
	{"id": "personajes", "title": "Personajes"},
	{"id": "mascotas", "title": "Compañeros"},
	{"id": "enemigos", "title": "Enemigos"},
	{"id": "armas", "title": "Armas"},
	{"id": "objetos", "title": "Objetos"},
	{"id": "escenarios", "title": "Escenarios"},
	{"id": "atrezo", "title": "Objetos de escenario"},
]
## Prefijo del modelo de atrezo -> lugar (para el nombre descriptivo).
const PLACES := {"alr": "muelle y cubierta del Alert", "arr": "Arrecife del Diablo", "atrezo": "atrezo común",
	"cth": "R'lyeh", "inn": "Innsmouth", "lui": "pantanos de Luisiana", "pan": "pantano de Rowley",
	"prv": "estudio de Wilcox", "rly": "R'lyeh", "tej": "tejados de Innsmouth", "barrera": "Antártida",
	"lake": "campamento de Lake", "paso": "paso de la cordillera", "ciudad": "ciudad de los Antiguos",
	"costa": "costa helada", "roca": "Antártida"}

static func available() -> bool:
	return not OS.has_feature("template")

## Las pestañas que se enseñan: Propuestas solo si hay alguna.
static func sections() -> Array:
	return SECTIONS.filter(func(s: Dictionary) -> bool: return s.id != "propuestas" or not proposals().is_empty())

static func proposals() -> Array:
	var p := ProjectSettings.globalize_path(PROPOSALS)
	if not FileAccess.file_exists(p): return []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	return d.get("propuestas", []) if d is Dictionary else []

## [{id, name, model, image, file, info}] de una sección. `model`: nombre del modelo voxel (se
## renderiza); `image`: ruta de un PNG; `file`: lo que se vigila para recargar.
static func entries(section: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match section:
		"propuestas":
			for p: Dictionary in proposals():
				var e := _model(String(p.modelo), String(p.nombre), String(p.modelo))
				if p.has("nota"): e.info += "\n" + String(p.nota)
				e.focus = String(p.get("encuadre", ""))
				out.append(e)
		"personajes", "mascotas":
			for e in Library.entries(null, "people"):
				var pet := String(e.section) == "Compañeros"
				if pet == (section == "mascotas"): out.append(_model(String(e.id), String(e.name), String(e.model)))
		"enemigos":
			var seen := {}
			for e in Library.entries(null, "enemies"):
				var m := String(e.model)
				if seen.has(m): continue                  # variantes con el mismo modelo: una vez
				seen[m] = true
				out.append(_model(String(e.id), String(e.name), m))
		"armas":
			for w in DamageRules.all_weapons():
				out.append(_image(String(w.id), w.display_name, "res://resources/weapons/icons/%s.png" % w.id))
		"objetos":
			for u: UpgradeData in Library._list("res://data/upgrades"):
				out.append(_image(String(u.id), u.display_name, "res://resources/items/icons/%s.png" % u.id))
			for it: ShopItem in Library._list("res://data/shop"):
				if it.icon_model != "": out.append(_model(String(it.id), it.display_name + " (tienda)", it.icon_model))
				else: out.append(_image(String(it.id), it.display_name + " (tienda)", "res://resources/items/icons/%s.png" % it.id))
		"escenarios":
			for l in Campaign.levels():
				var id := String(l.id)
				out.append(_image(id, "%s · %s" % [id.to_upper().replace("_", " "), String(l.name)], "res://resources/maps/%s.png" % id))
		"atrezo":
			for m in atrezo_models():
				out.append(_model(m, prop_name(m), m))
	return out

static func _model(id: String, name: String, model: String) -> Dictionary:
	return {"id": id, "name": name, "model": model, "image": "", "file": "res://models/%s.json" % model,
		"info": "Modelo voxel: models/%s.json" % model}

static func _image(id: String, name: String, path: String) -> Dictionary:
	return {"id": id, "name": name, "model": "", "image": path, "file": path, "info": "Imagen: " + path.trim_prefix("res://")}

## Modelos que usan las arenas (data/arenas/*.json), sin repetir.
static func atrezo_models() -> Array[String]:
	var found := {}
	var dir := DirAccess.open("res://data/arenas")
	if dir == null: return []
	for f in dir.get_files():
		if not f.ends_with(".json"): continue
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/" + f))
		_collect(d, found)
	var out: Array[String] = []
	for m in found: out.append(String(m))
	out.sort()
	return out

static func _collect(o: Variant, found: Dictionary) -> void:
	if o is Dictionary:
		for k in o:
			if k == "model" and o[k] is String: found[o[k]] = true
			else: _collect(o[k], found)
	elif o is Array:
		for x in o: _collect(x, found)

## "inn_casa_2" -> "Casa 2 (Innsmouth)".
static func prop_name(m: String) -> String:
	var parts := m.split("_")
	var place := String(PLACES.get(parts[0], ""))
	var rest := parts.slice(1 if place != "" else 0)
	var nice := " ".join(rest).capitalize() if not rest.is_empty() else m.capitalize()
	return nice + (" (%s)" % place if place != "" else "")

# ------------------------------------------------------------------ peticiones

static func _abs() -> String:
	return ProjectSettings.globalize_path(FILE)

static func load_requests() -> Array:
	if not FileAccess.file_exists(_abs()): return []
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(_abs()))
	return d.get("peticiones", []) if d is Dictionary else []

## Añade una petición pendiente y la guarda (escribe a un temporal y lo renombra).
static func add_request(section: String, e: Dictionary, text: String) -> void:
	var list := load_requests()
	var next := 1
	for r in list: next = maxi(next, int(r.get("id", 0)) + 1)
	list.append({"id": next, "seccion": section, "clave": e.id, "nombre": e.name, "archivo": e.file,
		"modelo": e.model, "texto": text, "estado": "pendiente", "respuesta": "",
		"fecha": Time.get_datetime_string_from_system(false, true)})
	DirAccess.make_dir_recursive_absolute(_abs().get_base_dir())
	var tmp := _abs() + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return
	f.store_string(JSON.stringify({"peticiones": list}, "\t"))
	f.close()
	DirAccess.rename_absolute(tmp, _abs())

static func requests_for(section: String, key: String) -> Array:
	return load_requests().filter(func(r: Dictionary) -> bool:
		return String(r.get("seccion", "")) == section and String(r.get("clave", "")) == key)

## Fecha de modificación del archivo de una entrada (0 si no existe): para recargar al cambiar.
static func stamp(e: Dictionary) -> int:
	var p := ProjectSettings.globalize_path(String(e.file))
	return FileAccess.get_modified_time(p) if FileAccess.file_exists(p) else 0

## PNG leído directamente del disco (sin la importación de Godot, que no ve los cambios hasta
## reimportar).
static func load_png(path: String) -> Texture2D:
	var p := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(p): return null
	var img := Image.load_from_file(p)
	return ImageTexture.create_from_image(img) if img != null else null
