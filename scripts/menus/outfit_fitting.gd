class_name OutfitFitting
extends PanelContainer
## Probador de la tienda (fase 14): la prenda marcada (o el conjunto) puesta en un investigador
## que gira despacio. X o R cambia de investigador. El modelo se monta un momento después de
## dejar quieta la selección, para que bajar deprisa por la lista no construya cada prenda;
## las mallas quedan en la caché (VoxelBuilder) y la segunda vez es inmediato.

const WAIT := 0.12                         ## s con la selección quieta antes de montar
const SPIN := 0.5                          ## rad/s

var _vp: SubViewport
var _holder: Node3D
var _model: Node3D
var _name: Label
var _chars: Array[CharacterData] = []
var _ci := 0
var _worn := {}
var _pending := -1.0
var _hold := ""

func _ready() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	box.add_child(MenuKit.title("Probador", 30, UiKit.GOLD))
	var view := SubViewportContainer.new()
	view.stretch = true
	view.custom_minimum_size = Vector2(440, 560)
	box.add_child(view)
	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	view.add_child(_vp)
	_holder = Node3D.new()
	_vp.add_child(_holder)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation_degrees = Vector3(-14, 0, 0)
	cam.size = 2.2
	cam.position = Vector3(0, 1.0, 0) + cam.transform.basis.z * 6.0
	_vp.add_child(cam)
	var key := DirectionalLight3D.new()           # luz de estudio, como los iconos (ModelIcon)
	key.rotation_degrees = Vector3(-40, 35, 0)
	key.light_energy = 1.3
	key.light_color = Color(1.0, 0.95, 0.88)
	_vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -70, 0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.75, 0.82, 1.0)
	_vp.add_child(fill)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.15, 0.15)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	_vp.add_child(we)
	_name = MenuKit.title("", 24, UiKit.TEXT)
	box.add_child(_name)
	box.add_child(MenuKit.hint("X o R: otro investigador"))
	MenuKit.dress(self, MenuKit.BRASS, Vector2(34, 30), 110.0)   # después: mete lo de dentro en su margen
	for c: CharacterData in DebugOptions.list_resources("res://data/characters"):
		if Demo.character_ok(c): _chars.append(c)
	_chars.sort_custom(func(a: CharacterData, b: CharacterData) -> bool: return a.order < b.order)

## Lo que se prueba: {hueco: id de prenda} (una prenda o un conjunto).
func show_worn(worn: Dictionary) -> void:
	if worn == _worn and _model != null: return
	_worn = worn
	_pending = WAIT

## Siguiente investigador (dir 1) o el anterior (-1).
func next_character(dir := 1) -> void:
	if _chars.is_empty(): return
	_ci = posmod(_ci + dir, _chars.size())
	_pending = 0.0

func character() -> CharacterData:
	return _chars[_ci] if not _chars.is_empty() else null

var _wiggle_t := 0.0

func _process(delta: float) -> void:
	_holder.rotation.y += SPIN * delta
	if _model != null:
		OutfitData.pose_hold(_model, _hold, 1.0)
		_wiggle_t += delta
		OutfitData.wiggle_tail(_model, _wiggle_t)                 # el tentáculo, vivo también aquí
	if _pending < 0.0: return
	_pending -= delta
	if _pending <= 0.0:
		_pending = -1.0
		_build()

func _build() -> void:
	var c := character()
	if c == null: return
	if _model != null: _model.queue_free()
	_model = VoxelBuilder.load_model("res://models/%s.json" % c.model)
	OutfitData.apply(_model, c.model, _worn)
	_hold = OutfitData.hold_of(_worn)
	_holder.add_child(_model)
	_name.text = c.display_name
