extends SceneTree
## Hoja de posturas del cuervo de la portada (TitleRaven), para revisar alas y patas:
##   godot --path . -s tools/render_cuervo_portada.gd            -> shots/cuervo_portada_posturas.png
##   godot --path . -s tools/render_cuervo_portada.gd -- vuelo    -> solo el aletazo, en 12 fases
##   godot --path . -s tools/render_cuervo_portada.gd -- posar    -> la llegada y el aterrizaje
##   godot --path . -s tools/render_cuervo_portada.gd -- despegar -> el despegue
## Cada postura sale de las mismas funciones que la animación (TitleRaven), en su instante.

const POSES := [["vuelo", 0.0], ["vuelo", 0.2], ["vuelo", 0.4], ["vuelo", 0.56], ["vuelo", 0.7],
	["vuelo", 0.85], ["planeo", 0.0], ["llega", 0.88], ["posa", 0.15], ["posa", 0.7], ["posa", 1.0],
	["posa", 3.0], ["grazna", 0.2], ["salto", 0.25], ["despega", 0.15], ["despega", 0.45]]

func _init() -> void:
	var only := OS.get_cmdline_user_args()
	var r := TitleRaven.new(-1.0)
	r.view_px = 768
	root.add_child(r)
	await process_frame
	r.set_process(false)
	var list: Array = POSES
	if "vuelo" in only:
		list = []
		for i in 12: list.append(["vuelo", i / 12.0])
	elif "despegar" in only:
		list = []
		for i in 12: list.append(["despega", i * 0.07])
	elif "posar" in only:
		list = []
		for u in [0.7, 0.78, 0.84, 0.9, 0.95, 0.99]: list.append(["llega", u])
		for t in [0.05, 0.2, 0.4, 0.6, 0.75, 0.9, 1.0, 1.06, 1.2]: list.append(["posa", t])
		list.append(["compara", 0.0])
	var tiles: Array[Image] = []
	for pose in list:
		_pose(r, pose[0], pose[1])
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img := r._vp.get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		tiles.append(img)
	var n := tiles.size()
	var cols := mini(n, 4)
	var w := tiles[0].get_width(); var h := tiles[0].get_height()
	var sheet := Image.create(w * cols, h * ((n + cols - 1) / cols), false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.36, 0.31, 0.28))
	for i in n:
		sheet.blend_rect(tiles[i], Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	sheet.resize(sheet.get_width() / 2, sheet.get_height() / 2, Image.INTERPOLATE_LANCZOS)
	var out := "res://shots/cuervo_portada_%s.png" % ("posturas" if only.is_empty() else only[0])
	sheet.save_png(out)
	print("hoja: ", out)
	quit()

func _pose(r: TitleRaven, what: String, k: float) -> void:
	r._caw_t = -10.0; r._hop_t = -10.0; r._ruffle_t = -10.0; r._lift_t = -10.0
	r._next_caw = 99.0; r._next_hop = 99.0; r._next_ruffle = 99.0; r._next_lift = 99.0; r.wait = 99.0
	r._yaw = TitleRaven.PERCH_YAW
	match what:
		"vuelo", "planeo":
			r._reset()
			r._pivot.rotation = Vector3(0.1, deg_to_rad(82.0), 0.0)
			r._wings(r._flap(k, 0.6) if what == "vuelo" else TitleRaven._glide(0.0))
			r._legs(1.25, 1.31)
		"llega":
			r.state = TitleRaven.State.IN; r.st = TitleRaven.FLY_IN * k; r._fly_in()
		"posa":
			r.state = TitleRaven.State.PERCHED; r.st = k; r._perched(0.0)
		"compara":                                     # el ala plegada a mano y la de verdad, a la vez
			r.state = TitleRaven.State.PERCHED; r.st = TitleRaven.FOLD_TO - 0.001; r._perched(0.0)
			for n in ["fold_l", "fold_r"]: r._p(n).visible = true
		"grazna":
			r.state = TitleRaven.State.PERCHED; r.st = 3.0; r._caw_t = k; r._perched(0.0)
		"salto":
			r.state = TitleRaven.State.PERCHED; r.st = 3.0; r._hop_t = k; r._hop_from = 52.0; r._hop_to = 75.0; r._perched(0.0)
		"despega":
			r.state = TitleRaven.State.OUT; r._out_from = TitleRaven.PERCH; r._leave_dir = Vector2(0.55, -1.0).normalized(); r.st = k
			r._fly_out()
	r._pivot.position.x = 0.0
	var open := what in ["vuelo", "planeo", "llega", "despega"] or (what == "posa" and k < TitleRaven.FOLD_TO)
	r._rim.light_energy = 0.25 if open else 1.0          # como en la portada: luces atenuadas con las alas abiertas
	r._moon.light_energy = 0.06 if open else 0.32
