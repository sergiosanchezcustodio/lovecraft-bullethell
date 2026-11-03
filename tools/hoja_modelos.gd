extends SceneTree
## Hoja de modelos (hito 16.28): renderiza varios modelos de models/ en una cuadrícula con
## ModelIcon (tres cuartos, luz de estudio) y la guarda en un PNG, para revisar el arte de cerca.
## Uso (con ventana: no vale --headless):
##   godot --path . -s tools/hoja_modelos.gd -- modelos=trofeo_copa,trofeo_garra px=320 out=shots/hoja.png

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var names: PackedStringArray = String(args.get("modelos", "trofeo_copa")).split(",", false)
	var px := int(args.get("px", "320"))
	var out := String(args.get("out", "shots/hoja_modelos.png"))
	var cols := mini(names.size(), int(args.get("cols", "6")))
	var host := Node.new()
	root.add_child(host)
	var texs: Array[Texture2D] = []
	for n in names: texs.append(ModelIcon.make(host, n, "full", px))
	for i in 8: await process_frame
	var rows := ceili(float(names.size()) / cols)
	var sheet := Image.create(cols * px, rows * px, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.07, 0.06))
	for i in texs.size():
		var img := texs[i].get_image()
		img.convert(Image.FORMAT_RGBA8)
		sheet.blend_rect(img, Rect2i(0, 0, px, px), Vector2i((i % cols) * px, (i / cols) * px))
	sheet.save_png(ProjectSettings.globalize_path("res://" + out))
	print("hoja: ", out)
	quit()
