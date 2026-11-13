class_name Bonds
extends Node
## Vínculos entre investigadores (hito 21.3, D-51): dos que se conocen en los relatos, jugando
## juntos, se dicen su diálogo al empezar una parte (un bocadillo sobre cada uno), se saludan al
## subir de nivel (Game.level_fx) y, mientras están a menos de `radio` m, tienen una ventaja
## pequeña (Player.set_bond). Los datos, en data/bonds.json. Corre igual en todos los PC: cada uno
## ve los diálogos y los saludos, y cada ventaja actúa donde se decide lo suyo (la vida, en el PC
## del jugador; la experiencia, en el anfitrión).

const PATH := "res://data/bonds.json"
const SCAN := 0.25                 ## s entre comprobaciones de quién está cerca
const LEAVE := 1.0                 ## m de más para dejar de estar cerca (que no parpadee en el borde)
const TALK_AT := 2.5               ## s desde el comienzo hasta la primera frase
const TALK_GAP := 3.2              ## s entre la frase de uno y la respuesta del otro
const TALK_PAIR := 7.5             ## s entre el diálogo de un vínculo y el del siguiente
const BUBBLE := 3.0                ## s que se lee cada frase (más la entrada y la salida)
const RIBBON_COOLDOWN := 8.0       ## s entre dos lazos al volver a juntarse
const GOLD := Color(1.0, 0.82, 0.42)

static var _defs: Dictionary = {}

var world: CombatWorld
var pairs: Array = []              ## [{def, a: Player, b: Player, near, ribbon}]
var _scan := 0.0
var _t := 0.0
var _talk: Array = []              ## [[segundo, Player, frase]] por decir, en orden
var _bubbles: Array = []           ## [{label, who, t}]
var _mat: StandardMaterial3D

# ---------------------------------------------------------------- datos

static func defs() -> Dictionary:
	if _defs.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_defs = d if d is Dictionary else {"vinculos": []}
	return _defs

static func all() -> Array:
	return defs().get("vinculos", [])

static func radius() -> float:
	return float(defs().get("radio", 7.0))

## Los vínculos entre estos personajes (ids), en el orden del archivo (la selección).
static func between(ids: Array) -> Array:
	var out := []
	for b: Dictionary in all():
		if ids.has(String(b.a)) and ids.has(String(b.b)): out.append(b)
	return out

## Las ventajas de un vínculo para el personaje `id`, en la forma de Player.bond: "stat:<estadística>"
## y "tag:<etiqueta>" multiplican; "dream_heal" y "revive_heal" suman.
static func effects_for(def: Dictionary, id: String) -> Dictionary:
	var out := {}
	for e: Dictionary in def.get("efectos", []):
		var who := String(e.get("quien", "ambos"))
		if who != "ambos" and who != id: continue
		merge(out, effect_key(e), float(e.get("valor", 0.0)))
	return out

static func effect_key(e: Dictionary) -> String:
	match String(e.get("tipo", "")):
		"stat": return "stat:" + String(e.get("stat", ""))
		"tag": return "tag:" + String(e.get("tag", ""))
	return String(e.get("tipo", ""))

## Junta una ventaja con las que ya hay (dos vínculos del mismo personaje).
static func merge(into: Dictionary, key: String, value: float) -> void:
	if key.begins_with("stat:") or key.begins_with("tag:"): into[key] = float(into.get(key, 1.0)) * value
	else: into[key] = float(into.get(key, 0.0)) + value

# ---------------------------------------------------------------- partida

## `speak`: al empezar una parte (sin progreso del nivel anterior) se dicen su diálogo.
func setup(p_world: CombatWorld, players: Array, speak: bool) -> Bonds:
	world = p_world
	name = "Bonds"
	for b: Dictionary in all():
		var pa := _find(players, String(b.a))
		var pb := _find(players, String(b.b))
		if pa != null and pb != null: pairs.append({"def": b, "a": pa, "b": pb, "near": false, "ribbon": -99.0})
	if speak:
		var at := TALK_AT
		for p: Dictionary in pairs:
			for line: Array in (p.def as Dictionary).get("dialogo", []):
				var who: Player = p.a if String(line[0]) == String((p.a as Player).data.id) else p.b
				_talk.append([at, who, String(line[1])])
				at += TALK_GAP
			at += TALK_PAIR - TALK_GAP
	return self

static func _find(players: Array, id: String) -> Player:
	for q: Player in players:
		if is_instance_valid(q) and String(q.data.id) == id: return q
	return null

## Los que tienen un vínculo con `q` y están cerca ahora.
func friends_near(q: Player) -> Array[Player]:
	var out: Array[Player] = []
	for p: Dictionary in pairs:
		if not p.near: continue
		if p.a == q: out.append(p.b)
		elif p.b == q: out.append(p.a)
	return out

func _physics_process(delta: float) -> void:
	step(delta)

## Avanza el reloj: las frases que tocan y, cada SCAN s, quién está cerca (tests: a mano).
func step(delta: float) -> void:
	_t += delta
	while not _talk.is_empty() and _t >= float(_talk[0][0]):
		var line: Array = _talk.pop_front()
		if is_instance_valid(line[1]): say(line[1], line[2])
	_scan -= delta
	if _scan > 0.0: return
	_scan = SCAN
	var changed := false
	for p: Dictionary in pairs:
		var a: Player = p.a
		var b: Player = p.b
		if not is_instance_valid(a) or not is_instance_valid(b): continue
		var d := Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
		var near: bool = d <= radius() + (LEAVE if p.near else 0.0)
		if near == p.near: continue
		p.near = near
		changed = true
		if near and _t - float(p.ribbon) >= RIBBON_COOLDOWN:   # se juntan: un lazo de luz entre los dos
			p.ribbon = _t
			ribbon(a, b, 6)
	if changed: _apply()

## Pone a cada jugador las ventajas de sus vínculos con alguien cerca.
func _apply() -> void:
	var per := {}
	for p: Dictionary in pairs:
		for q: Player in [p.a, p.b]:
			if not per.has(q): per[q] = {}
			if not p.near: continue
			var e := effects_for(p.def, String(q.data.id))
			for k: String in e: merge(per[q], k, float(e[k]))
	for q: Player in per:
		if is_instance_valid(q): q.set_bond(per[q])

# ---------------------------------------------------------------- lo que se ve

## Un bocadillo con la frase sobre la cabeza de `who`, que lo sigue: entra, se lee y se apaga.
func say(who: Player, text: String) -> void:
	var l := Label3D.new()
	l.text = "«%s»" % text
	l.font = MenuKit.body_font()
	l.font_size = 44
	l.outline_size = 14
	l.pixel_size = 0.0068
	l.modulate = Color(0.97, 0.92, 0.8, 0.0)
	l.outline_modulate = Color(0.04, 0.03, 0.03, 0.0)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.width = 560.0
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 20
	l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	(world.fx if world != null else self).add_child(l)
	_bubbles.append({"label": l, "who": who, "t": 0.0})
	_place(_bubbles[-1])

func _process(delta: float) -> void:
	for i in range(_bubbles.size() - 1, -1, -1):
		var b: Dictionary = _bubbles[i]
		b.t = float(b.t) + delta
		var l: Label3D = b.label
		var a := clampf(float(b.t) / 0.25, 0.0, 1.0) * (1.0 - clampf((float(b.t) - BUBBLE) / 0.5, 0.0, 1.0))
		if float(b.t) >= BUBBLE + 0.5 or not is_instance_valid(b.who):
			l.queue_free()
			_bubbles.remove_at(i)
			continue
		l.modulate.a = a
		l.outline_modulate.a = a * 0.85
		_place(b)

func _place(b: Dictionary) -> void:
	var who: Player = b.who
	var at := who.get_global_transform_interpolated().origin if who.is_inside_tree() else who.global_position
	(b.label as Label3D).global_position = at + Vector3(0, 2.35 + clampf(float(b.t) / 0.25, 0.0, 1.0) * 0.1, 0)

## Un lazo de luz entre los dos: cubitos dorados en arco, de uno a otro, que se encienden en
## orden y se apagan encogiendo (al juntarse y al subir de nivel).
func ribbon(a: Player, b: Player, n := 10) -> void:
	if world == null or not a.is_inside_tree() or not b.is_inside_tree(): return
	if _mat == null:
		_mat = VoxelFx.std()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.albedo_color = GOLD
	var from := a.global_position + Vector3(0, 1.1, 0)
	var to := b.global_position + Vector3(0, 1.1, 0)
	var lift := clampf(from.distance_to(to) * 0.18, 0.3, 1.2)
	for i in n:
		var k := (i + 0.5) / n
		var c := MeshInstance3D.new()
		c.mesh = VoxelFx.box1()
		c.material_override = _mat
		c.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.fx.add_child(c)
		c.global_position = from.lerp(to, k) + Vector3(0, sin(k * PI) * lift, 0)
		c.scale = Vector3.ONE * 0.001
		var tw := c.create_tween()
		tw.tween_property(c, "scale", Vector3.ONE * 0.075, 0.12).set_delay(k * 0.35)
		tw.tween_property(c, "scale", Vector3.ONE * 0.001, 0.6).set_delay(0.2)
		tw.tween_callback(c.queue_free)
