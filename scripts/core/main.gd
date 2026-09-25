extends Node
## Punto de entrada. Elige la escena según el primer argumento de usuario:
##   godot --path .                          -> partida
##   godot --path . -- still|anim ...        -> visor de modelos (scenes/preview.tscn)
##   godot --path . -- bench ...             -> prueba de rendimiento (scenes/bench.tscn)

func _ready() -> void:
	var la := LaunchArgs.from_cmdline()
	var first := la.positional[0] if la.positional.size() > 0 else ""
	var scene := "res://scenes/game.tscn"
	match first:
		"still", "anim": scene = "res://scenes/preview.tscn"
		"bench": scene = "res://scenes/bench.tscn"
	get_tree().change_scene_to_file.call_deferred(scene)
