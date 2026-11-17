class_name L
## Idiomas (hito 22.4). La clave de cada texto es el texto en español tal cual (gettext): la tabla
## es `locale/en.po` y la saca `tools/textos.py`. En español no se traduce nada.
##   - `L.t("…")`: las frases del código (las palabras sueltas que van tal cual a un Label o un
##     Button las traduce Godot solo).
##   - `L.data(json)`: los textos de un JSON de `data/`, al cargarlo.
##   - las propiedades de texto de las clases de datos (`display_name`, `description`…) llevan un
##     `get` que las traduce al leerlas: así valen también los valores por defecto, que los .tres
##     no guardan.
## El idioma se elige al arrancar (`Settings`, «language»); cambiarlo pide reiniciar el juego.
## La regla de qué es texto (`human`) y SKIP_KEYS son las mismas que las de tools/textos.py.

const LANGS := ["es", "en"]
const NAMES := {"es": "Español", "en": "English"}
const PO := {"en": "res://locale/en.po"}
const SKIP_KEYS := ["id", "model", "icon", "icon_model", "path", "image", "sfx", "sound", "anim", "bus", "music",
	"scene", "arena", "level", "levels", "next", "weapon_id", "enemy", "enemies", "tags", "tag",
	"texture", "shader", "file", "video", "clip", "color", "kind", "type", "mode", "key", "action",
	"autor", "author"]
static var lang := "es"
static var missing := {}                     ## textos sin traducir que se han pedido (i18n_log=true)
static var log_missing := false
static var _table: Translation
static var _catcher: Translation
static var _human_re: RegEx
static var _accent_re: RegEx
static var _word_re: RegEx
static var _tech_re: RegEx

## El idioma de la primera vez: el del sistema si lo hay; si no, inglés.
static func system_lang() -> String:
	var l := OS.get_locale_language()
	return l if LANGS.has(l) else "en"

## Pone el idioma (al arrancar, antes de cargar datos).
static func apply(p_lang: String) -> void:
	lang = p_lang if LANGS.has(p_lang) else "es"
	if lang != "es" and _table == null and ResourceLoader.exists(PO.get(lang, "")):
		_table = load(PO[lang]) as Translation
		if _table != null: TranslationServer.add_translation(_table)
	if lang != "es" and log_missing and _catcher == null:
		_catcher = _Catcher.new()
		_catcher.locale = lang
		TranslationServer.add_translation(_catcher)
	TranslationServer.set_locale(lang)

## Guarda los textos pedidos que no están en la tabla (con i18n_log=true).
static func save_missing(path: String) -> void:
	if FileAccess.file_exists(path):              # se suma a lo apuntado antes (un recorrido son muchas ejecuciones)
		for line in FileAccess.get_file_as_string(path).split("\n", false): missing[line.c_unescape()] = true
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null: return
	var keys := missing.keys()
	keys.sort()
	for k in keys: f.store_line(String(k).c_escape())
	print("i18n: %d textos sin traducir en %s" % [keys.size(), ProjectSettings.globalize_path(path)])

## Apunta todo lo que se pide traducir (también lo que traducen solos los Label y los Button) y
## no está en la tabla.
class _Catcher extends Translation:
	func _get_message(src: StringName, _ctx: StringName) -> StringName:
		var s := String(src)
		if L._table == null or L._table.get_message(src) == &"":
			if L.human(s) and not s.is_valid_float(): L.missing[s] = true
		return &""

static func t(s: String) -> String:
	if lang == "es" or s == "": return s
	var out := String(TranslationServer.translate(s))
	if log_missing and out == s and human(s): missing[s] = true
	return out

## Deja traducidos los textos de un JSON ya leído (y lo devuelve, para encadenar).
static func data(v: Variant) -> Variant:
	if lang == "es" or v == null: return v
	return _walk(v)

static func _walk(v: Variant) -> Variant:
	if v is String:
		return t(v) if human(v) else v
	if v is Dictionary:
		for k in v.keys():
			if k is String and (k.begins_with("_") or SKIP_KEYS.has(k)): continue
			var x: Variant = v[k]
			if x is String or x is Dictionary or x is Array: v[k] = _walk(x)
		return v
	if v is Array:
		for i in v.size():
			var x: Variant = v[i]
			if x is String or x is Dictionary or x is Array: v[i] = _walk(x)
		return v
	return v

## Lee y traduce un JSON de `data/` (null si no está o no se entiende).
static func json(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	return data(JSON.parse_string(FileAccess.get_file_as_string(path)))

## ¿Es un texto que se ve? (como human() en tools/textos.py)
static func human(s: String) -> bool:
	if s.length() < 2: return false
	if _human_re == null:
		_human_re = RegEx.create_from_string("[a-záéíóúñü]{2}")
		_accent_re = RegEx.create_from_string("[áéíóúñ¿¡ÁÉÍÓÚÑ]")
		_word_re = RegEx.create_from_string("^[A-ZÁÉÍÓÚÑ][a-záéíóúñü]+[.!?…]?$")
		_tech_re = RegEx.create_from_string("(://|\\.(json|png|jpg|tres|tscn|res|ogg|wav|mp3|gd|gdshader|ogv|svg|cfg|txt|po)\\b|^[a-z0-9_]+$)")
	if _human_re.search(s) == null: return false
	if _tech_re.search(s) != null: return false
	if s.contains(" ") or s.contains("\n") or _accent_re.search(s) != null: return true
	return _word_re.search(s) != null
