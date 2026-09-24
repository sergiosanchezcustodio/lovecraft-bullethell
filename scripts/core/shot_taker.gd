class_name ShotTaker
extends Node
## Guarda capturas del viewport en los segundos de juego indicados y, si se pide,
## cierra el juego tras la última. Pensado para verificar cambios visuales desde la
## terminal; con `--fixed-fps` el resultado es reproducible.

signal all_taken

var times: Array[float] = []
var prefix := "res://shots/game"
var quit_when_done := true
var _elapsed := 0.0
var _next := 0

func _init(p_times: Array[float] = [], p_prefix: String = "res://shots/game") -> void:
	times = p_times.duplicate()
	times.sort()
	prefix = p_prefix
	process_mode = Node.PROCESS_MODE_ALWAYS   # también captura menús en pausa

func _process(delta: float) -> void:
	if _next >= times.size(): return
	_elapsed += delta
	if _elapsed < times[_next]: return
	var t := times[_next]
	_next += 1
	await RenderingServer.frame_post_draw
	var path := "%s_%05.1fs.png" % [prefix, t]
	get_viewport().get_texture().get_image().save_png(path)
	print("captura: ", ProjectSettings.globalize_path(path))
	if _next >= times.size():
		all_taken.emit()
		if quit_when_done: get_tree().quit()
