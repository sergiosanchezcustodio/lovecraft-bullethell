extends SceneTree
## Hoja de posturas del cuervo de la portada (TitleRaven), para revisar alas y patas:
##   godot --path . -s tools/render_cuervo_portada.gd            -> shots/cuervo_portada_posturas.png
##   godot --path . -s tools/render_cuervo_portada.gd -- perched  -> solo posado (y mide dónde caen las patas)
## Posturas: aleteo en 4 fases, planeo, frenada, aterrizaje con las alas en alto, plegando,
## posado, graznido, saltito y despegue.

const POSES := [["vuelo", 0.0], ["vuelo", 0.25], ["vuelo", 0.5], ["vuelo", 0.75], ["planeo", 0.0],
	["frenada", 0.0], ["toca", 0.05], ["pliega", 0.3], ["posado", 3.0], ["grazna", 0.2],
	["salto", 0.2], ["despega", 0.5]]

func _init() -> void:
	var only := OS.get_cmdline_user_args()
	var r := TitleRaven.new(-1.0)
	root.add_child(r)
	await process_frame
	r.set_process(false)
	var list := POSES if only.is_empty() else [["posado", 3.0]]
	var tiles: Array[Image] = []
	for pose in list:
		_pose(r, pose[0], pose[1])
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := r._vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		if pose[0] == "posado":
			var used := img.get_used_rect()
			print("posado: usado ", used, " pies (fracción) ", (used.position.x + used.size.x * 0.5) / img.get_width(), ", ", float(used.end.y) / img.get_height())
		tiles.append(img)
	var n := tiles.size()
	var cols := mini(n, 4)
	var w := tiles[0].get_width(); var h := tiles[0].get_height()
	var sheet := Image.create(w * cols, h * ((n + cols - 1) / cols), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.36, 0.31, 0.28))
	for i in n:
		sheet.blend_rect(tiles[i], Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	sheet.resize(sheet.get_width() / 2, sheet.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	var out := "res://shots/cuervo_portada_%s.png" % ("posturas" if only.is_empty() else "perched")
	sheet.save_png(out)
	print("hoja: ", out)
	quit()

func _pose(r: TitleRaven, what: String, k: float) -> void:
	match what:
		"vuelo", "planeo":
			r._reset()
			r._pivot.rotation = Vector3(0.1, deg_to_rad(82.0), 0.0)
			if what == "vuelo": r._flap(k, 0.6)
			else: r._glide(0.0)
			r._legs(1.25, 1.33)
		"frenada":
			r.state = TitleRaven.State.IN; r.st = TitleRaven.FLY_IN * 0.9; r._fly_in()
		"toca", "pliega", "posado":
			r.state = TitleRaven.State.PERCHED; r.st = k
			r._caw_t = -10.0; r._hop_t = -10.0; r._ruffle_t = -10.0; r._next_caw = 99.0; r._next_hop = 99.0; r._next_ruffle = 99.0; r._next_lift = 99.0; r.wait = 99.0
			r._perched(0.0)
		"grazna":
			r.state = TitleRaven.State.PERCHED; r.st = 3.0; r._caw_t = k; r._next_caw = 99.0; r.wait = 99.0
			r._perched(0.0)
		"salto":
			r.state = TitleRaven.State.PERCHED; r.st = 3.0; r._caw_t = -10.0; r._hop_t = k; r._hop_from = 52.0; r._hop_to = 75.0; r._next_hop = 99.0; r.wait = 99.0
			r._perched(0.0)
		"despega":
			r.state = TitleRaven.State.OUT; r._out_from = TitleRaven.PERCH; r._leave_dir = Vector2(0.55, -1.0).normalized(); r.st = k
			r._fly_out()
