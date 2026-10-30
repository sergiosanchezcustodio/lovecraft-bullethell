class_name Fragments
extends Node3D
## Páginas sueltas (hito 13.11): en cada nivel de la campaña hay una página que brilla en el
## suelo, en uno de varios sitios posibles (`spots`: siempre los mismos para ese nivel, sacados
## de su id; en cada partida, uno de ellos al azar). La recoge cualquier jugador de este PC al
## pasar por encima; queda en el hueco (`SaveData.records.fragments`) y no vuelve a salir. Las
## cinco de una parte forman un relato, que se lee en la Biblioteca (tomo VIII). Cada PC tiene
## la suya (no viaja por la red). Textos en `data/fragments.json`.

const DATA := "res://data/fragments.json"
const PICK_R := 1.1
const COLOR := Color(1.0, 0.84, 0.5)

static var _data := {}

var world: CombatWorld
var level_id := ""
var _t := 0.0
var _paper: MeshInstance3D
var _light: OmniLight3D
var _beam: MeshInstance3D
var _taken := false

static func data() -> Dictionary:
	if _data.is_empty():
		var d = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_data = d if d is Dictionary else {}
	return _data

static func stories() -> Array:
	return data().get("stories", [])

## {story (el relato), index (0..4), text} de la página del nivel, o {} si no tiene.
static func page_of(level_id: String) -> Dictionary:
	for s: Dictionary in stories():
		var pages: Array = s.pages
		for i in pages.size():
			if String(pages[i].level) == level_id: return {"story": s, "index": i, "text": String(pages[i].text)}
	return {}

static func found(save: SaveData) -> Array:
	return save.records.get("fragments", []) if save != null else []

static func has(save: SaveData, level_id: String) -> bool:
	return found(save).has(level_id)

static func total() -> int:
	var n := 0
	for s: Dictionary in stories(): n += (s.pages as Array).size()
	return n

## Apunta la página; devuelve cuántas tiene ya de su relato.
static func add(save: SaveData, level_id: String) -> int:
	if save == null or page_of(level_id).is_empty(): return 0
	if not save.records.has("fragments"): save.records["fragments"] = []
	if not (save.records.fragments as Array).has(level_id): save.records.fragments.append(level_id)
	save.stats["fragments"] = (save.records.fragments as Array).size()   # logro «Bibliotecario»
	var s: Dictionary = page_of(level_id).story
	return (s.pages as Array).filter(func(p: Dictionary) -> bool: return has(save, String(p.level))).size()

## Los sitios posibles del nivel: puntos libres del escenario, lejos del centro y de los
## bordes, siempre los mismos para ese nivel.
static func spots(level_id: String, obstacles: ObstacleMap) -> Array[Vector3]:
	var rng := RandomNumberGenerator.new()
	rng.seed = Daily.seed_of("fragmento:" + level_id)
	var out: Array[Vector3] = []
	var b := obstacles.bounds.grow(-4.0)
	var tries := 0
	while out.size() < int(data().get("spots", 6)) and tries < 400:
		tries += 1
		var p := Vector3(rng.randf_range(b.position.x, b.end.x), 0.0, rng.randf_range(b.position.y, b.end.y))
		if Vector2(p.x, p.z).length() < 9.0: continue                    # no a la vista del principio
		if obstacles.is_blocked(Vector2(p.x, p.z), 0.8) or obstacles.water_at(Vector2(p.x, p.z)) > 0.2: continue
		if out.any(func(q: Vector3) -> bool: return q.distance_to(p) < 6.0): continue
		out.append(p)
	return out

func setup(p_world: CombatWorld, p_level: String, pos: Vector3) -> Fragments:
	world = p_world
	level_id = p_level
	position = pos
	name = "Fragmento"
	return self

func _ready() -> void:
	_paper = MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.34, 0.015, 0.46)
	_paper.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.93, 0.87, 0.72)
	mat.emission_enabled = true
	mat.emission = COLOR
	mat.emission_energy_multiplier = 1.2
	_paper.material_override = mat
	_paper.position.y = 0.35
	add_child(_paper)
	_light = OmniLight3D.new()
	_light.light_color = COLOR
	_light.omni_range = 3.0
	_light.light_energy = 1.4
	_light.position.y = 0.6
	add_child(_light)
	_beam = MeshInstance3D.new()                       # columna de luz tenue, para verla de lejos
	var c := CylinderMesh.new()
	c.top_radius = 0.18; c.bottom_radius = 0.3; c.height = 6.0
	_beam.mesh = c
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.albedo_color = Color(COLOR, 0.07)
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam.material_override = bm
	_beam.position.y = 3.0
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_beam)

func _process(delta: float) -> void:
	_t += delta
	if _taken: return
	_paper.position.y = 0.35 + 0.08 * sin(_t * 2.2)              # flota y gira despacio
	_paper.rotation = Vector3(0.25 * sin(_t * 1.3), _t * 0.8, 0.15 * sin(_t * 1.7))
	_light.light_energy = 1.2 + 0.35 * sin(_t * 3.1)

func _physics_process(_delta: float) -> void:
	if _taken or world == null: return
	for q: Player in world.players:
		if q.remote or q.health <= 0.0: continue
		if Vector2(q.global_position.x - global_position.x, q.global_position.z - global_position.z).length() <= PICK_R:
			_take(q)
			return

func _take(q: Player) -> void:
	_taken = true
	var n := add(Auto.save(), level_id)
	var p := page_of(level_id)
	Auto.sfx("page")
	var game := get_tree().current_scene
	if game != null and game.has_method("announce"):
		game.call("announce", "J%d encuentra una página: «%s» (%d de %d)" % [q.index + 1, String(p.story.title), maxi(n, p.index + 1),
			(p.story.pages as Array).size()], 3.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_paper, "position:y", 2.2, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_paper, "scale", Vector3.ZERO, 0.8).set_delay(0.3)
	tw.tween_property(_light, "light_energy", 0.0, 0.8)
	tw.tween_property(_beam, "transparency", 1.0, 0.6)
	tw.chain().tween_callback(queue_free)
