extends SceneTree
## Comprime los modelos para exportar (hito 8.5): cada models/<nombre>.json pasa a
## models/<nombre>.json.z (formato comprimido de Godot, ZSTD). La build excluye los .json y
## VoxelBuilder lee los .json.z (VoxelBuilder.read_text). Los .json.z no van a git.
## Uso: godot --headless --path . -s tools/empaquetar_modelos.gd   (lo llama tools/exportar.sh)

func _init() -> void:
	var n := 0
	var before := 0
	var after := 0
	for f in DirAccess.get_files_at("res://models"):
		if not f.ends_with(".json"): continue
		var src := "res://models/" + f
		var text := FileAccess.get_file_as_string(src)
		var out := FileAccess.open_compressed(src + ".z", FileAccess.WRITE, FileAccess.COMPRESSION_ZSTD)
		out.store_string(text)
		out.close()
		before += text.length()
		after += FileAccess.open(src + ".z", FileAccess.READ).get_length()
		n += 1
	print("%d modelos: %d MB -> %d MB" % [n, before / 1048576, after / 1048576])
	quit()
