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
