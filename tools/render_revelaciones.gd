extends SceneTree
## Iconos de las revelaciones (hito 21.7): renderiza models/revelacion_<id>.json (de
## tools/gen_revelaciones.py) casi de frente, con la luz de estudio de ModelIcon, y los guarda en
## resources/revelations/<id>.png, que es lo que carga Revelations.icon (como los Signos).
## Uso (con ventana: no vale --headless):
##   godot --path . -s tools/render_revelaciones.gd [-- solo=lo_oculto px=256 hoja=shots/rev.png]

const TILT := Vector3(-14, 16, 0)           ## un poco desde arriba y la derecha: se ve el relieve

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var px := int(args.get("px", "256"))
	var f := FileAccess.open("res://data/revelations.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var ids: Array[String] = []
	for r: Dictionary in data.revelaciones:
		if not args.has("solo") or String(args.solo).split(",").has(String(r.id)): ids.append(String(r.id))
	var host := Node.new()
	root.add_child(host)
	var vps: Array[SubViewport] = []
	for id in ids:
		var vp := SubViewport.new()
		vp.size = Vector2i(px, px)
		vp.transparent_bg = true
		vp.own_world_3d = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		host.add_child(vp)
		var m := VoxelBuilder.load_model("res://models/revelacion_%s.json" % id)
		vp.add_child(m)
		ModelIcon._stage(vp, m, "full", 0.0)            # luces y entorno de los retratos
		var cam: Camera3D
		for c in vp.get_children(): if c is Camera3D: cam = c
		cam.rotation_degrees = TILT
		cam.size = 46.0 / 32.0 * 1.06
		cam.position = Vector3(0, 0, 2.5 / 32.0) + cam.transform.basis.z * 6.0
		vps.append(vp)
	for i in 30: await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources/revelations"))
	var sheet := Image.create(px * ids.size(), px, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.07, 0.06))
	for i in ids.size():
		var img := vps[i].get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.save_png(ProjectSettings.globalize_path("res://resources/revelations/%s.png" % ids[i]))
		sheet.blend_rect(img, Rect2i(0, 0, px, px), Vector2i(i * px, 0))
	if args.has("hoja"): sheet.save_png(ProjectSettings.globalize_path("res://" + String(args.hoja)))
	print("revelaciones: ", ids.size(), " iconos")
	quit()
