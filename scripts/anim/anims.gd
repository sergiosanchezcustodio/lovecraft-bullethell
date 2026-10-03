class_name Anims
extends RefCounted
## Animaciones por código, sin rigging: cada tipo de modelo tiene un script con
## funciones estáticas `<anim>(m: Node3D, t: float)` que colocan las partes para
## la fase t del ciclo (0..1), y una constante DURATION con los segundos de cada ciclo.

## Qué script anima cada modelo: data/anim_sets.json (modelo -> script de scripts/anim/).
## Un enemigo nuevo que se anima como otro solo necesita su línea en ese fichero.
const SETS_PATH := "res://data/anim_sets.json"
static var _by_model := {}

static func script_for(model_name: String) -> Script:
	if _by_model.is_empty():
		var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SETS_PATH))
		var cache := {}
		for k in d.modelos:
			var n := String(d.modelos[k])
			if not cache.has(n): cache[n] = load("res://scripts/anim/%s.gd" % n)
			_by_model[k] = cache[n]
	return _by_model.get(model_name)

static func has_anim(model_name: String, anim: String) -> bool:
	var s: Script = script_for(model_name)
	return s != null and s.DURATION.has(anim)

## Duración del ciclo en segundos (1.0 si el modelo no tiene esa animación).
static func duration(model_name: String, anim: String) -> float:
	var s: Script = script_for(model_name)
	return s.DURATION.get(anim, 1.0) if s != null else 1.0

## Coloca el modelo en la fase t (0..1) de la animación. Sin animación, lo deja en reposo.
static func pose(model_name: String, anim: String, m: Node3D, t: float) -> void:
	reset(m)
	if has_anim(model_name, anim):
		script_for(model_name).call(anim, m, t)

## Nodo de una parte del modelo. Más rápido que get_node(), que convierte el texto en
## NodePath en cada llamada (importa con 150 enemigos animados).
static func part(m: Node3D, name: String) -> Node3D:
	return m.get_meta("part_nodes")[name]

## Posición de reposo de una parte (su pivote), en metros. VoxelBuilder la guarda al crear el modelo.
static func rest(m: Node3D, part: String) -> Vector3:
	return m.get_meta("rest_by_name")[part]

## Devuelve todas las partes a su pose de reposo.
static func reset(m: Node3D) -> void:
	m.position = Vector3.ZERO
	m.rotation = Vector3.ZERO
	m.scale = Vector3.ONE
	var parts: Array[Node3D] = m.get_meta("parts")
	var rest_pos: Array[Vector3] = m.get_meta("rest")
	for i in parts.size():
		var n := parts[i]
		n.position = rest_pos[i]
		n.rotation = Vector3.ZERO
		n.scale = Vector3.ONE

## Captura la pose actual del modelo (raíz y partes) para fundirla con otra.
static func snapshot(m: Node3D) -> Array:
	var out: Array = [m.position, m.rotation, m.scale]
	for n: Node3D in m.get_meta("parts"):
		out.append_array([n.position, n.rotation, n.scale])
	return out

## Funde la pose actual del modelo con una captura: w = 0 deja la captura, w = 1 la actual.
static func blend_from(m: Node3D, snap: Array, w: float) -> void:
	if w >= 1.0: return
	m.position = (snap[0] as Vector3).lerp(m.position, w)
	m.rotation = (snap[1] as Vector3).lerp(m.rotation, w)
	m.scale = (snap[2] as Vector3).lerp(m.scale, w)
	var parts: Array[Node3D] = m.get_meta("parts")
	for i in parts.size():
		var n := parts[i]
		var o := 3 + i * 3
		n.position = (snap[o] as Vector3).lerp(n.position, w)
		n.rotation = (snap[o + 1] as Vector3).lerp(n.rotation, w)
		n.scale = (snap[o + 2] as Vector3).lerp(n.scale, w)

## Aplica una animación por encima de la pose actual (sin volver al reposo) y solo en las
## partes indicadas, mezclada con peso w. Sirve para gestos del tren superior (lanzar)
## mientras las piernas siguen andando.
static func overlay(model_name: String, anim: String, m: Node3D, t: float, w: float, only: Array[String]) -> void:
	if not has_anim(model_name, anim) or w <= 0.0: return
	var saved := {}
	var nodes: Dictionary = m.get_meta("part_nodes")
	for pname in only:
		if not nodes.has(pname): continue              # piezas opcionales (antebrazos)
		var n := part(m, pname)
		saved[pname] = [n.position, n.rotation, n.scale]
	var root_pos := m.position
	var root_rot := m.rotation
	script_for(model_name).call(anim, m, t)
	m.position = root_pos
	m.rotation = root_rot
	for pname in saved:
		var n := part(m, pname)
		var s: Array = saved[pname]
		n.position = (s[0] as Vector3).lerp(n.position, w)
		n.rotation = (s[1] as Vector3).lerp(n.rotation, w)
		n.scale = (s[2] as Vector3).lerp(n.scale, w)

static func ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
