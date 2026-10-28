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

## Reacción al golpe propia de la familia (28-10-2026): el script de animación puede tener
## `static func hit(m, k)` (k de 0 a 1 en HIT_TIME s), que se suma a la pose ya puesta. Sin ella,
## Enemy aplasta el modelo entero, como antes. Devuelve si la tiene.
static func has_hit(model_name: String) -> bool:
	var s: Script = script_for(model_name)
	return s != null and s.get("HIT_TIME") != null

static func hit_time(model_name: String, fallback: float) -> float:
	var s: Script = script_for(model_name)
	return float(s.get("HIT_TIME")) if s != null and s.get("HIT_TIME") != null else fallback

static func hit(model_name: String, m: Node3D, k: float) -> void:
	script_for(model_name).call("hit", m, k)

## Preparación antes de un ataque con aviso en el suelo (hito 12.5): el script de la familia puede
## tener `static func windup(m, build, thrust, t)`, que se suma a la pose ya puesta. build va de 0 a
## 1 mientras dura el aviso (se prepara y aguanta) y vuelve a 0 al soltar; thrust es el golpe hacia
## delante al soltar (0, 1 y 0); t, segundos, para el temblor. Sin ella, Enemy agacha el modelo entero.
static func has_windup(model_name: String) -> bool:
	var s: Script = script_for(model_name)
	return s != null and s.has_method("windup")

static func windup(model_name: String, m: Node3D, build: float, thrust: float, t: float) -> void:
	script_for(model_name).call("windup", m, build, thrust, t)

## Muerte de la familia (hito 12.7): `static func death(m, k)` (k de 0 a 1 en DEATH_TIME s, desde
## el reposo) y DEATH_KIND ("kneel", "puddle", "melt" o "fall"). Sin ella (0), se deshace sin caer.
static func death_time(model_name: String) -> float:
	var s: Script = script_for(model_name)
	return float(s.get("DEATH_TIME")) if s != null and s.get("DEATH_TIME") != null else 0.0

static func death_kind(model_name: String) -> String:
	var s: Script = script_for(model_name)
	return String(s.get("DEATH_KIND")) if s != null and s.get("DEATH_KIND") != null else ""

static func death(model_name: String, m: Node3D, k: float) -> void:
	script_for(model_name).call("death", m, k)

## Gestos de reposo del modelo: los suyos (FIDGETS_OF del script) o los de la familia (FIDGETS).
static func fidgets(model_name: String) -> Array:
	var s: Script = script_for(model_name)
	if s == null: return []
	var of: Variant = s.get("FIDGETS_OF")
	if of is Dictionary and (of as Dictionary).has(model_name): return (of as Dictionary)[model_name]
	var f: Variant = s.get("FIDGETS")
	return f if f is Array else []

## Golpe rápido que vuelve con rebote: 0 al empezar, 1 en el punto fuerte, y de vuelta a 0.
static func jolt(k: float, peak := 0.18) -> float:
	return Anims.ease(clampf(k / peak, 0.0, 1.0)) * (1.0 - Anims.ease(clampf((k - peak) / (1.0 - peak), 0.0, 1.0)))

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
