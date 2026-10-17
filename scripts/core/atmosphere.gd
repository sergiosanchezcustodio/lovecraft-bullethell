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
	if absf(gamma - 1.0) < 0.005:
		env.adjustment_color_correction = null
		env.adjustment_enabled = false
		return
	var g := Gradient.new()
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in 33:
		var x := i / 32.0
		var y := pow(x, 1.0 / gamma)
		offs.append(x); cols.append(Color(y, y, y))
	g.offsets = offs
	g.colors = cols
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	env.adjustment_enabled = true
	env.adjustment_color_correction = tex
