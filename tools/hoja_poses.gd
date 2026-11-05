extends SceneTree
## Hoja de poses (fase 17): un modelo en N fases de una animación, en fila, con la cámara de la
## partida (isométrica) y otra de lado, para revisar animaciones sin jugar.
##
##   godot --path . -s tools/hoja_poses.gd -- model=dyer anim=swing n=6
##
## Opciones (después de `--`):
##   model=   modelo de models/ (dyer por defecto)
##   anim=    animación de su script (Anims). Los gestos de un golpe se ponen encima de `base`
##            como en la partida (solo brazos y torso: over=true). Especiales: aim1 y aim2 (apuntar
##            con una o dos manos; las columnas van del culatazo a reposo), aim_look (apunta a los lados),
##            wade y mud (andar vadeando o por el barro, hito 17.6), slip (frenada en la nieve).
##   base=    animación de debajo (idle por defecto; walk, para verlo andando)
##   over=    true: como gesto encima de la base (Player.UPPER_BODY); false: pose entera
##   n=       columnas (6)
##   side=    true: segunda fila, vista de lado
##   w=, h=   tamaño de cada fila en px (320 por columna × 520)
##   out=     archivo (shots/poses_<modelo>_<anim>.png)
##   zoom=, cy=, gap=   alto visible (2,3 m), altura del centro (0,85 m) y separación (1,4 m):
##            para los compañeros, zoom=1 cy=0.2 gap=0.7

const UPPER_BODY: Array[String] = ["arm_r", "arm_l", "torso", "fore_r", "fore_l"]

var _opts := {}
var _frames := 0
var _out := ""
var _views: Array[SubViewport] = []

func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.split("=", true, 1)
		if kv.size() == 2: _opts[kv[0]] = kv[1]
	var model_name := String(_opts.get("model", "dyer"))
	var anim := String(_opts.get("anim", "walk"))
	var base := String(_opts.get("base", "idle"))
	var n := int(_opts.get("n", "6"))
	var over := String(_opts.get("over", "true")) == "true"
	var side := String(_opts.get("side", "true")) == "true"
	_out = String(_opts.get("out", "res://shots/poses_%s_%s.png" % [model_name, anim]))
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.18, 0.19, 0.22)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.57, 0.62)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(sun)
	var path := "res://models/%s.json" % model_name
	var rows := 2 if side else 1
	var gap := float(_opts.get("gap", "1.4"))
	for r in rows:
		for i in n:
			var holder := Node3D.new()                # el giro, en un contenedor (no en la raíz)
			var across := Vector3(1.0, 0.0, -1.0).normalized() if r == 0 else Vector3.RIGHT   # a lo ancho de su cámara
			holder.position = across * (i - (n - 1) * 0.5) * gap + Vector3(0.0, 0.0, -r * 40.0)
			holder.rotation.y = 0.0 if r == 0 else PI * 0.5
			world.add_child(holder)
			var m := VoxelBuilder.load_model(path)
			holder.add_child(m)
			var t := i / float(maxi(n - 1, 1)) if not anim in ["aim1", "aim2", "aim_look"] else i / float(n)
			_pose(model_name, m, anim, base, t, over, i, n)
	# una cámara por fila, cada una en su SubViewport de tamaño fijo (la ventana de las pruebas
	# mide 3×3 px): arriba la de la partida, abajo de lado
	var w := int(_opts.get("w", str(320 * n)))
	var h := int(_opts.get("h", "520"))
	for r in rows:
		var sv := SubViewport.new()
		sv.size = Vector2i(w, h)
		sv.own_world_3d = false
		sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var cam := Camera3D.new()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.size = float(_opts.get("zoom", "2.3"))
		var target := Vector3(0.0, float(_opts.get("cy", "0.85")), -r * 40.0)
		if r == 0:
			cam.rotation_degrees = Vector3(-30, 45, 0)
		else:
			cam.rotation_degrees = Vector3(-8, 0, 0)
		cam.position = target + cam.basis.z * 30.0
		sv.add_child(cam)
		world.add_child(sv)
		_views.append(sv)
	process_frame.connect(_on_frame)

func _pose(model_name: String, m: Node3D, anim: String, base: String, t: float, over: bool, i: int, n: int) -> void:
	var s := Anims.script_for(model_name)
	if anim == "aim1" or anim == "aim2" or anim == "aim_look":
		Anims.pose(model_name, base, m, 0.25)
		var kick := exp(-float(i) / float(n) * 4.0) if anim != "aim_look" else 0.0
		var look := lerpf(-1.2, 1.2, i / float(maxi(n - 1, 1))) if anim == "aim_look" else 0.0
		s.call("aim", m, 1.0 if anim == "aim2" else 0.0, look, kick, 1.0)
		return
	if anim == "slip":                              # frenada resbalando en la nieve (hito 17.6)
		Anims.pose(model_name, "idle", m, 0.25)
		Anims.overlay(model_name, "brake", m, t, 1.0, ["leg_l", "leg_r", "shin_l", "shin_r", "torso", "head", "arm_l", "arm_r", "fore_l", "fore_r"])
		var sk := Anims.ease(t / 0.1) * (1.0 - Anims.ease((t - 0.3) / 0.5))
		s.call("slip", m, sk, t * Anims.duration(model_name, "brake"))
		return
	if anim == "wade" or anim == "mud":             # andar según el suelo (hito 17.6)
		Anims.pose(model_name, "walk", m, t)
		s.call("terrain", m, t, 1.0 if anim == "wade" else 0.0, 1.0 if anim == "mud" else 0.0)
		return
	if over:
		Anims.pose(model_name, base, m, 0.25)
		var w := smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(0.7, 1.0, t))   # como Player._animate
		Anims.overlay(model_name, anim, m, t, w, UPPER_BODY)
	else:
		Anims.pose(model_name, anim, m, t)

func _on_frame() -> void:
	_frames += 1
	if _frames < 6: return
	var first := _views[0].get_texture().get_image()
	var img := Image.create(first.get_width(), first.get_height() * _views.size(), false, first.get_format())
	for i in _views.size():
		var part := _views[i].get_texture().get_image()
		img.blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i(0, i * first.get_height()))
	img.save_png(_out)
	print("Hoja de poses: ", ProjectSettings.globalize_path(_out))
	quit()
