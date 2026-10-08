extends Node
## Punto de entrada. Elige la escena según el primer argumento de usuario:
##   godot --path .                          -> pantalla de título (sin argumentos)
##   godot --path . -- bot=circle ...        -> partida (con opciones de partida)
##   godot --path . -- still|anim ...        -> visor de modelos (scenes/preview.tscn)
##   godot --path . -- bench ...             -> prueba de rendimiento (scenes/bench.tscn)
##   godot --path . -- title ...             -> portada (scenes/title.tscn)
##   godot --path . -- intro ...            -> ficha del proyecto e intro (scenes/intro.tscn)
##   godot --path . -- select ...            -> selección de personaje (scenes/select.tscn)
##   godot --path . -- test_save=3           -> crea la partida de pruebas (todo desbloqueado) en ese hueco
## La ventana sigue la configuración (Settings: pantalla completa por defecto). Las ejecuciones
## de prueba (capturas, rendimiento, bots, visor, grabación de vídeo) van en ventana.
## `window=true` fuerza la ventana y `fullscreen=true`, la pantalla completa. La interfaz escala
## desde 1920x1080 (stretch canvas_items en project.godot).

func _ready() -> void:
	var la := LaunchArgs.from_cmdline()
	var first := la.positional[0] if la.positional.size() > 0 else ""
	if la.has("test_save"):                     # `test_save=3`: crea la partida de pruebas en ese hueco y sale
		Saves.make_test_save(clampi(la.get_int("test_save") - 1, 0, Saves.SLOTS - 1))
		print("Partida de pruebas creada en el hueco %d: %s" % [la.get_int("test_save"), Saves.path(Saves.slot)])
		get_tree().quit()
		return
	_window_mode(la, first)
	# Sin argumentos se abre la pantalla de título; con opciones de partida, la partida
	var scene := "res://scenes/game.tscn"
	if OS.get_cmdline_user_args().is_empty():           # arranque normal: ficha e intro (según la configuración) y portada
		var show := int(Settings.get_value("intro")) == 0 or not bool(Settings.get_value("intro_seen"))
		scene = "res://scenes/intro.tscn" if show else "res://scenes/title.tscn"
	match first:
		"still", "anim": scene = "res://scenes/preview.tscn"
		"bench": scene = "res://scenes/bench.tscn"
		"title": scene = "res://scenes/title.tscn"
		"select": scene = "res://scenes/select.tscn"
		"intro": scene = "res://scenes/intro.tscn"
		"relato": scene = "res://scenes/relato.tscn"
	get_tree().change_scene_to_file.call_deferred(scene)

func _window_mode(la: LaunchArgs, first: String) -> void:
	var dev := la.has("shots") or la.has("perf") or la.has("bot") or first in ["still", "anim", "bench"] 		or Engine.get_write_movie_path() != ""
	Settings.dev_window = (dev and not la.get_bool("fullscreen")) or la.get_bool("window")
	Settings.force_fullscreen = la.get_bool("fullscreen")
	Settings.apply_video()
	Settings.apply_ui()
