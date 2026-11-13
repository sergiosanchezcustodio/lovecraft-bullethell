extends SceneTree
## Hoja de la mancha de tinta (hito 20.1): la transición a varios puntos, sobre una captura de
## partida. Arriba, saliendo (la tinta se extiende); abajo, entrando (se retira).
## `godot --path . -s tools/probar_tinta.gd -- [fondo=shots/….png] [semilla=N]` → shots/tinta_hoja.png

const STEPS := [0.15, 0.35, 0.55, 0.75, 0.92]

func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if "=" in a: args[a.get_slice("=", 0)] = a.get_slice("=", 1)
	var bg_path: String = args.get("fondo", "res://shots/game_f19_wfx2_020.0s.png")
	var seed := float(args.get("semilla", "7"))
	var img := Image.load_from_file(ProjectSettings.globalize_path(bg_path))
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := TextureRect.new()
	bg.texture = ImageTexture.create_from_image(img)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	vp.add_child(bg)
	var ink := ColorRect.new()
	ink.set_anchors_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = load("res://scripts/ui/ink_wipe.gdshader")
	m.set_shader_parameter("seed", seed)
	m.set_shader_parameter("ink", LevelCard.BLACK)
	ink.material = m
	vp.add_child(ink)
	var w := 640
	var h := 360
	var sheet := Image.create(w * STEPS.size(), h * 2, false, Image.FORMAT_RGB8)
	for row in 2:
		m.set_shader_parameter("reveal", row == 1)
		for i in STEPS.size():
			var t: float = STEPS[i]
			m.set_shader_parameter("amount", t if row == 0 else 1.0 - t)
			for _f in 3: await process_frame
			var shot := vp.get_texture().get_image()
			shot.resize(w, h, Image.INTERPOLATE_LANCZOS)
			shot.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(shot, Rect2i(0, 0, w, h), Vector2i(i * w, row * h))
	var out := ProjectSettings.globalize_path("res://shots/tinta_hoja.png")
	sheet.save_png(out)
	print("Hoja: ", out)
	quit()
