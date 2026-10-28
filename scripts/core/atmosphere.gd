class_name Atmosphere
extends RefCounted
## Entorno común (fondo, luz ambiental, tono, glow y niebla) para el visor y la partida.
## Forward+ y Compatibility necesitan valores distintos para verse igual: los de
## Compatibility son los originales, con los que se aprobó el aspecto de los modelos.

static func make_environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.4, 0.45)
	env.ambient_light_energy = 0.35
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.09, 0.09)
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		env.glow_bloom = 0.05
		env.fog_density = 0.04
	else:
		# Filmic lava los tonos oscuros en Forward+; ACES conserva negros y saturación.
		# El bloom y la niebla se aplican con más fuerza aquí, así que bajan.
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env.tonemap_exposure = 1.6
		env.glow_bloom = 0.0
		env.fog_density = 0.02
	return env

## Levanta las sombras con una curva gamma aplicada tras el tono (corrección de color 1D):
## y = x^(1/gamma). 1 no cambia nada; 1,3-1,5 aclara la noche sin quemar faroles ni hogueras.
## La usan la luz de cada arena ("gamma" en su JSON) y el brillo de la configuración.
static func set_lift(env: Environment, gamma: float) -> void:
	set_grade(env, gamma, {})

## Gradación de color de cada parte (hito 11.3, `data/grades.json`): "p1", "p2"…; vacía si no hay.
static func grade_for(key: String) -> Dictionary:
	var f := FileAccess.open("res://data/grades.json", FileAccess.READ)
	if f == null: return {}
	var all: Variant = JSON.parse_string(f.get_as_text())
	return (all as Dictionary).get(key, {}) if all is Dictionary else {}

## La curva de set_lift y, encima, la gradación de la parte: cada canal se desplaza en las sombras
## (pesa más hacia 1/3) y en las luces (hacia 2/3), sin tocar el negro ni el blanco; y la saturación.
static func set_grade(env: Environment, gamma: float, grade: Dictionary) -> void:
	var sh: Array = grade.get("shadows", [0.0, 0.0, 0.0])
	var hi: Array = grade.get("highlights", [0.0, 0.0, 0.0])
	var sat := float(grade.get("saturation", 1.0))
	env.adjustment_saturation = sat
	if absf(gamma - 1.0) < 0.005 and grade.is_empty():
		env.adjustment_color_correction = null
		env.adjustment_enabled = false
		return
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in 33:
		var x := i / 32.0
		var y := pow(x, 1.0 / gamma)
		var ws := 4.0 * y * (1.0 - y) * (1.0 - y)
		var wh := 4.0 * y * y * (1.0 - y)
		var c := Color(y, y, y)
		for k in 3: c[k] = clampf(y + float(sh[k]) * ws + float(hi[k]) * wh, 0.0, 1.0)
		offs.append(x); cols.append(c)
	g.offsets = offs
	g.colors = cols
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	env.adjustment_enabled = true
	env.adjustment_color_correction = tex
