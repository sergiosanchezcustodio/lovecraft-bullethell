extends SceneTree
## Hoja de la vela que se apaga (hito 20.3): la transición a varios puntos sobre una captura.
## `godot --path . -s tools/probar_vela.gd -- [fondo=shots/….png]` → shots/vela_hoja.png

const STEPS := [0.2, 0.45, 0.6, 0.7, 0.78, 0.86, 0.94, 1.0]

func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if "=" in a: args[a.get_slice("=", 0)] = a.get_slice("=", 1)
	var bg_path: String = args.get("fondo", "res://shots/titulo__pag_009.0s.png")
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(bg_path)))
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(bg)
	var r := CandleOut.make_rect(Vector2(1920, 1080))
	vp.add_child(r)
	var m: ShaderMaterial = r.material
	var cw := 480
	var ch := 270
	var sheet := Image.create(cw * 4, ch * 2, false, Image.FORMAT_RGB8)
	for i in STEPS.size():
		m.set_shader_parameter("t", STEPS[i])
		m.set_shader_parameter("time_s", STEPS[i] * CandleOut.TIME)
		for _f in 3: await process_frame
		var shot := vp.get_texture().get_image()
		shot.resize(cw, ch, Image.INTERPOLATE_LANCZOS)
		shot.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(shot, Rect2i(0, 0, cw, ch), Vector2i((i % 4) * cw, (i / 4) * ch))
		if i == 4: shot = vp.get_texture().get_image(); shot.save_png(ProjectSettings.globalize_path("res://shots/vela_078.png"))
	var out := ProjectSettings.globalize_path("res://shots/vela_hoja.png")
	sheet.save_png(out)
	print("Hoja: ", out)
	quit()
