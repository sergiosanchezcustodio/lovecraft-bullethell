class_name Auto
extends RefCounted
## Acceso a los autoloads (Sfx, Settings…) buscándolos al usarlos, para el código de la partida.
## Nombrarlos directamente (`Sfx.play_at(...)`) impide compilar el script, y todos los que
## dependen de él, en las herramientas que se lanzan con `-s` (tools/render_mapa.gd y otras),
## donde Godot no crea los autoloads; ahí estas funciones no hacen nada o dan el valor por defecto.

static func node(n: String) -> Node:
	var ml := Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null(n) if ml is SceneTree else null

## Sfx.play(evento, dB)
static func sfx(ev: String, vol_db := 0.0) -> void:
	var s := node("Sfx")
	if s: s.call("play", ev, vol_db)

## Sfx.play_at(evento, posición)
static func sfx_at(ev: String, pos: Vector3) -> void:
	var s := node("Sfx")
	if s: s.call("play_at", ev, pos)

## Settings.get_value(clave); `default` si no hay configuración (herramientas)
static func setting(key: String, default: Variant = null) -> Variant:
	var s := node("Settings")
	return s.call("get_value", key) if s else default
