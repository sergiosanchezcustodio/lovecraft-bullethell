extends SceneTree
## Mapa de un lugar para la Biblioteca: renderiza la arena entera de un nivel en la vista
## isométrica del juego (con su luz) y la guarda en resources/maps/<nivel>.png.
## godot --path . -s tools/render_mapa.gd -- p1_n1 [px=1200]
## Sin --headless: hace falta dibujar. Si cambia la arena, vuelve a ejecutarlo.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var id := "p1_n1" if args.is_empty() else args[0]
	var px := 1500
	for a in args:
		if a.begins_with("px="): px = int(a.substr(3))
	var level: LevelData = load("res://data/levels/%s.tres" % id)
	var vp := SubViewport.new()
	vp.size = Vector2i(px, px * 2 / 3)               # apaisado: la arena en rombo es ancha
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Atmosphere.make_environment()
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200.0
	vp.add_child(sun)
	var arena := ArenaBuilder.build(level.arena, false)
	vp.add_child(arena)
	ArenaBuilder.apply_light(arena.get_meta("light", {}), sun, env)
	env.fog_density = 0.0
	var size: Vector2 = arena.get_meta("size")
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.rotation_degrees = Vector3(-30, 45, 0)
	# el rombo de la arena, con un poco de su borde (barrera y mar)
	cam.size = (size.x + size.y) * 0.5 * 0.92
	cam.position = cam.transform.basis.z * 120.0
	cam.far = 400.0
	vp.add_child(cam)
	for i in 12: await process_frame               # caché de mallas y sombras
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://resources/maps")
	var out := "res://resources/maps/%s.png" % id
	img.save_png(out)
	print("mapa: ", out)
	quit()
