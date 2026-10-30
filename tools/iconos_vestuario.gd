extends SceneTree
## Iconos de las prendas para la tienda (fase 14): renderiza cada prenda sola, de tres cuartos,
## como hacía la tienda al abrir la pestaña (ModelIcon), y la guarda en
## resources/outfits/icons/<id>.png. La tienda carga la imagen y no renderiza nada.
## godot --path . -s tools/iconos_vestuario.gd [-- id id ...]
## Sin --headless: hace falta dibujar. Después, `godot --headless --path . --import` para que
## Godot importe las imágenes nuevas. Si cambia una prenda (gen_vestuario.py), vuelve a ejecutarlo.

const OUT := "res://resources/outfits/icons"
const PX := 192

func _init() -> void:
	var ids := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(OUT)
	var n := 0
	for o in OutfitData.all():
		if not ids.is_empty() and not ids.has(String(o.id)): continue
		var tex := ModelIcon.make(root, o.icon_model(), "full", PX)
		for i in 3: await process_frame
		await RenderingServer.frame_post_draw
		tex.get_image().save_png("%s/%s.png" % [OUT, o.id])
		n += 1
	print("iconos: ", n, " en ", OUT)
	quit()
