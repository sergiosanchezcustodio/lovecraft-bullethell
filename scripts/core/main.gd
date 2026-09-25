extends Node
## Punto de entrada. Elige la escena según el primer argumento de usuario:
##   godot --path .                          -> pantalla de título (sin argumentos)
##   godot --path . -- bot=circle ...        -> partida (con opciones de partida)
##   godot --path . -- still|anim ...        -> visor de modelos (scenes/preview.tscn)
##   godot --path . -- bench ...             -> prueba de rendimiento (scenes/bench.tscn)
##   godot --path . -- title ...             -> portada (scenes/title.tscn)

func _ready() -> void:
	var la := LaunchArgs.from_cmdline()
	var first := la.positional[0] if la.positional.size() > 0 else ""
	# Sin argumentos se abre la pantalla de título; con opciones de partida, la partida
	var scene := "res://scenes/title.tscn" if OS.get_cmdline_user_args().is_empty() else "res://scenes/game.tscn"
	match first:
		"still", "anim": scene = "res://scenes/preview.tscn"
		"bench": scene = "res://scenes/bench.tscn"
		"title": scene = "res://scenes/title.tscn"
	get_tree().change_scene_to_file.call_deferred(scene)
