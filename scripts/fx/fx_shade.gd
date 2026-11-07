class_name FxShade
## Materiales del sombreador de efectos de las armas (hito 18.2, D-50; `fx_shade.gdshaderinc`): uno
## compartido por receta (`data/weapon_fx.json`, `shades`), con su rampa de color en tramos. Lo de
## cada uso (desvanecerse, tinte, semilla) va por instancia
## (`GeometryInstance3D.set_instance_shader_parameter`), así que no se crean materiales en partida.
## Con `weapon_fx` 0 (Baja), `on()` es falso y cada arma usa su material liso de antes.

static var _mats := {}
static var _rng := RandomNumberGenerator.new()   ## propio: lo que se ve no cambia el azar de la partida

static func on() -> bool:
	return int(Quality.value("weapon_fx", 2)) > 0

## El material de la receta `id` (null si no existe).
static func material(id: String) -> ShaderMaterial:
	if _mats.has(id): return _mats[id]
	var r := recipe_of(id)
	if r.is_empty(): return null
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/fx/fx_shade_add.gdshader" if bool(r.get("add", true)) else "res://scripts/fx/fx_shade_mix.gdshader")
	var g := Gradient.new()
	var cols: Array = r.get("colors", ["#00000000", "#ffffffff"])
	var offs := PackedFloat32Array()
	var cs := PackedColorArray()
	for i in cols.size():
		offs.append(float(i) / maxf(cols.size() - 1, 1))
		cs.append(Color.html(String(cols[i])))
	g.offsets = offs
	g.colors = cs
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 64
	m.set_shader_parameter("ramp", tex)
	for k in ["mode", "cell", "steps", "scroll", "energy", "sparkle"]:
		if r.has(k): m.set_shader_parameter(k, r[k])
	_mats[id] = m
	return m

static func recipe_of(id: String) -> Dictionary:
	var f := FileAccess.open("res://data/weapon_fx.json", FileAccess.READ)
	if f == null: return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary: return {}
	return ((d as Dictionary).get("shades", {}) as Dictionary).get(id, {})

## Pone el material de `id` en `mi` con su semilla; devuelve si lo ha puesto.
static func apply(mi: GeometryInstance3D, id: String) -> bool:
	if not on(): return false
	var m := material(id)
	if m == null: return false
	mi.material_override = m
	mi.set_instance_shader_parameter("seed", _rng.randf() * 100.0)
	return true

static func set_fade(mi: GeometryInstance3D, fade: float, tint := Color.WHITE) -> void:
	mi.set_instance_shader_parameter("fade", fade)
	mi.set_instance_shader_parameter("tint", tint)

## Calentamiento (LevelWarmup): una caja casi transparente con cada receta, hija de `parent` en
## `at` (local), para que sus sombreadores se compilen antes de la partida.
static func prime(parent: Node3D, at: Vector3) -> void:
	if not on(): return
	var f := FileAccess.open("res://data/weapon_fx.json", FileAccess.READ)
	if f == null: return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if not d is Dictionary: return
	var glow := MeshInstance3D.new()                  # la raja del martillo: transparente y con brillo (hito 18.6)
	glow.mesh = VoxelFx.box1()
	var gm := VoxelFx.std()
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.emission_enabled = true
	gm.albedo_color = Color(0, 0, 0, 1.0 / 255.0)
	glow.material_override = gm
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(glow)
	glow.position = at
	glow.scale = Vector3.ONE * 0.2
	var shades: Dictionary = (d as Dictionary).get("shades", {})
	for id in shades:
		var mi := MeshInstance3D.new()
		# en la malla con la que se usa: el anillo del arco no lleva normales y pide otra pipeline
		mi.mesh = VoxelFx.arc_ring() if int((shades[id] as Dictionary).get("mode", 0)) == 1 else VoxelFx.box1()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		mi.position = at
		mi.scale = Vector3.ONE * 0.2
		if apply(mi, String(id)): set_fade(mi, 1.0 / 255.0)
		else: mi.queue_free()
