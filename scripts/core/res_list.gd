class_name ResList
extends RefCounted
## Los .tres de una carpeta de datos, también en una build exportada (hito 23.2). Al exportar, Godot
## convierte los .tres y la carpeta los lista como «x.tres.remap»: con un `ends_with(".tres")` a
## secas, el bestiario, el vestuario y la lista de armas salían vacíos en las builds publicadas
## (en el editor, bien). `load()` con la ruta del .tres sigue la redirección solo.

## Rutas res:// de los .tres de `dir`, en orden alfabético y sin repetir.
static func paths(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		var n := f.trim_suffix(".remap")
		if not n.ends_with(".tres"): continue
		var p := dir.path_join(n)
		if not out.has(p): out.append(p)
	out.sort()
	return out

## Los recursos ya cargados.
static func load_all(dir: String) -> Array:
	var out := []
	for p in paths(dir):
		var r := load(p)
		if r != null: out.append(r)
	return out
