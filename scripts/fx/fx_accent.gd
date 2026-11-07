class_name FxAccent
## Acento de las evoluciones (hito 18.14, D-50): un arma evolucionada se reconoce por sus efectos.
## Sus estelas salen más anchas y teñidas, y sus golpes sueltan además un destello del color de su
## rama. Datos en `data/weapon_fx.json` (`accents`): uno por rama (`evolution`, dorado;
## `evolution_alt`, violeta) y, si hace falta, uno propio por evolución en `by_id`. Con
## `weapon_fx` 0, nada.

static var _by_wid := {}                 ## id de la evolución -> acento ({} si no lo es)
static var _built := false
static var _by_tag := {}                 ## etiqueta («J1:id») -> acento, para no trocear la cadena en cada golpe

## El acento del arma de la etiqueta `tag` («J1:id») o de su id; vacío si no es una evolución.
static func of(tag: StringName) -> Dictionary:
	if not _built: build()
	var hit: Variant = _by_tag.get(tag)
	if hit != null: return hit
	var s := String(tag)
	var wid := s.get_slice(":", 1) if s.contains(":") else s
	var a: Dictionary = _by_wid.get(wid, {})
	_by_tag[tag] = a
	return a

## Lee qué armas son evoluciones y de qué rama (al empezar el nivel; las .tres ya están en caché).
static func build() -> void:
	_built = true
	_by_wid.clear()
	_by_tag.clear()
	var f := FileAccess.open("res://data/weapon_fx.json", FileAccess.READ)
	if f == null: return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary: return
	var acc: Dictionary = (d as Dictionary).get("accents", {})
	if acc.is_empty(): return
	var by_id: Dictionary = acc.get("by_id", {})
	var dir := DirAccess.open("res://data/weapons")
	if dir == null: return
	for fn in dir.get_files():
		fn = fn.trim_suffix(".remap")
		if not fn.ends_with(".tres"): continue
		var w := load("res://data/weapons/" + fn) as WeaponData
		if w == null: continue
		for k in ["evolution", "evolution_alt"]:
			var evo := String(w.get(k))
			if evo == "" or _by_wid.has(evo): continue
			_by_wid[evo] = _parse(by_id.get(evo, acc.get(k, {})))

static func _parse(a: Dictionary) -> Dictionary:
	if a.is_empty(): return {}
	return {"tint": Color.html(String(a.get("tint", "#ffffff"))), "width": float(a.get("width", 1.0)),
		"glint": String(a.get("glint", ""))}
