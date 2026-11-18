extends SceneTree
## Comprime los modelos para exportar (hito 8.5): cada models/<nombre>.json pasa a
## models/<nombre>.json.z (formato comprimido de Godot, ZSTD). La build excluye los .json y
## VoxelBuilder lee los .json.z (VoxelBuilder.read_text). Los .json.z no van a git.
## Uso: godot --headless --path . -s tools/empaquetar_modelos.gd   (lo llama tools/exportar.sh)
## Hito 23.1: no mete los de tools/modelos_fuera.txt (versiones antiguas y modelos de las
## herramientas, que nada usa en el juego; la lista la hace tools/modelos_sin_uso.py) y borra su
## .json.z si quedaba uno de antes. El nivel de ZSTD es el de project.godot
## (compression/formats/zstd/compression_level, 19: un 38 % menos que el 3 de fábrica, y se lee igual de rápido).

const SKIP_LIST := "res://tools/modelos_fuera.txt"

func _init() -> void:
	var n := 0
	var skipped := 0
	var before := 0
	var after := 0
	var skip := {}
	if FileAccess.file_exists(SKIP_LIST):
		for line in FileAccess.get_file_as_string(SKIP_LIST).split("\n", false):
			if not line.begins_with("#") and line.strip_edges() != "": skip[line.strip_edges() + ".json"] = true
	for f in DirAccess.get_files_at("res://models"):
		if not f.ends_with(".json"): continue
		var src := "res://models/" + f
		if skip.has(f):
			if FileAccess.file_exists(src + ".z"): DirAccess.remove_absolute(ProjectSettings.globalize_path(src + ".z"))
			skipped += 1
			continue
		var text := FileAccess.get_file_as_string(src)
		var out := FileAccess.open_compressed(src + ".z", FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
		out.store_string(text)
		out.close()
		before += text.length()
		after += FileAccess.open(src + ".z", FileAccess.READ).get_length()
		n += 1
	print("%d modelos: %d MB -> %d MB (ZSTD %d; %d fuera de la build)" % [n, before / 1048576, after / 1048576,
		int(ProjectSettings.get_setting("compression/formats/zstd/compression_level", 3)), skipped])
	quit()
