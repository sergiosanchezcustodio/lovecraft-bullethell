extends SceneTree
## Hoja de entradas (hito 17.11): un enemigo apareciendo en N momentos, en fila, con la cámara de
## la partida, para revisar cómo entra cada familia sin jugar.
##
##   godot --path . -s tools/hoja_entradas.gd -- enemy=profundo rise=water n=8
##
## Opciones (después de `--`):
##   enemy=   enemigo de data/enemies/ (profundo)
##   rise=    water, fog, ground o air (la que le tocaría si no se dice)
##   n=       columnas (8)
##   dur=     s que cubren las columnas (1,2: la entrada y la sacudida)
##   out=     archivo (shots/entrada_<enemigo>_<rise>.png)

var _frames := 0
var _out := ""
var _view: SubViewport
var _world: CombatWorld
var _opts := {}

func _init() -> void:
	var opts := _opts
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2: opts[kv[0]] = kv[1]
	var id := String(opts.get("enemy", "profundo"))
	var rise := String(opts.get("rise", ""))
	var n := int(opts.get("n", "8"))
	_out = String(opts.get("out", "res://shots/entrada_%s_%s.png" % [id, rise if rise != "" else "auto"]))
	var world := CombatWorld.new()
	_world = world
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.4, 0.42, 0.48)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.57, 0.62)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(sun)
	var sv := SubViewport.new()
	sv.size = Vector2i(300 * n, 560)
	sv.own_world_3d = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = 2.6
	cam.rotation_degrees = Vector3(-30, 45, 0)
	cam.position = Vector3(0, 0.8, 0) + cam.basis.z * 30.0
	sv.add_child(cam)
	world.add_child(sv)
	var seen := Camera3D.new()                       # otra igual en la ventana: el enemigo mira si se le ve
	seen.projection = Camera3D.PROJECTION_ORTHOGONAL
	seen.size = 2.6 * 300.0 * n / 560.0
	seen.keep_aspect = Camera3D.KEEP_WIDTH
	seen.transform = cam.transform
	world.add_child(seen)
	seen.make_current.call_deferred()
	_view = sv
	process_frame.connect(_on_frame)

## Los enemigos, ya en el árbol (en _init aún no lo está: no tendrían modelo).
func _spawn() -> void:
	var id := String(_opts.get("enemy", "profundo"))
	var rise := String(_opts.get("rise", ""))
	var n := int(_opts.get("n", "8"))
	var dur := float(_opts.get("dur", "1.2"))
	var world := _world
	var data: EnemyData = load("res://data/enemies/%s.tres" % id)
	var across := Vector3(1.0, 0.0, -1.0).normalized()
	for i in n:
		var e := Enemy.new().setup(data, world, null)
		world.add_child(e)
		e.global_position = across * (i - (n - 1) * 0.5) * 1.6
		e.facing = Vector3(0, 0, 1)
		e.process_mode = Node.PROCESS_MODE_DISABLED          # solo avanza lo que se le pide
		if rise != "":
			e.data = data.duplicate()
			e.data.rise = StringName(rise)
		e._rise_start()
		var t := dur * i / float(maxi(n - 1, 1))
		var steps := int(t * 60.0)
		for k in steps + 1: e._process(1.0 / 60.0)

func _on_frame() -> void:
	_frames += 1
	if _frames == 1: _spawn()
	if _frames < 8: return
	_view.get_texture().get_image().save_png(_out)
	print("Hoja de entradas: ", ProjectSettings.globalize_path(_out))
	quit()
