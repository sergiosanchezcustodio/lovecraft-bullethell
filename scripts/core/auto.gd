class_name Auto
extends RefCounted
## Acceso a los autoloads (Sfx, Settings…) buscándolos al usarlos, para el código de la partida.
## Nombrarlos directamente (`Sfx.play_at(...)`) impide compilar el script, y todos los que
## dependen de él, en las herramientas que se lanzan con `-s` (tools/render_mapa.gd y otras),
## donde Godot no crea los autoloads; ahí estas funciones no hacen nada o dan el valor por defecto.

static func node(n: String) -> Node:
	if off_main(): return null
	var ml := Engine.get_main_loop()
	return (ml as SceneTree).root.get_node_or_null(n) if ml is SceneTree else null

## Fuera del hilo principal (la arena que se monta durante el relato, hito 16.6) no se puede
## buscar en el árbol: `setting` lee una copia de la configuración hecha antes (`snapshot`, en
## el hilo principal) y `node` no da nada.
static var _snap := {}

static func off_main() -> bool:
	return OS.get_thread_caller_id() != OS.get_main_thread_id()

static func snapshot() -> void:
	_snap = {}
	var s := node("Settings")
	if s == null: return
	var keys := {}
	for k in (s.get("defaults") as Dictionary): keys[k] = true
	for k in (s.get("values") as Dictionary): keys[k] = true
	for k in keys: _snap[k] = s.call("get_value", k)

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
	if off_main(): return _snap.get(key, default)
	var s := node("Settings")
	return s.call("get_value", key) if s else default

## Saves.current: la partida guardada en uso (null sin hueco o en las herramientas)
static func save() -> SaveData:
	var s := node("Saves")
	return s.get("current") as SaveData if s else null
