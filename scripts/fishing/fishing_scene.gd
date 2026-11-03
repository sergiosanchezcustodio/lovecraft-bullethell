class_name FishingScene
extends Node3D
## Pesca en el muelle de Innsmouth (hito 16.24): entre nivel y nivel de la parte 2, el
## investigador del J1 en el borde del muelle de las calles de Innsmouth (la arena `calles`), con
## la cámara de siempre más cerca. Cinco lances (data/fishing.json):
##   1. Lanzar: A mantenido carga la fuerza (va y viene); al soltar, el corcho vuela.
##   2. Esperar: el corcho cabecea; algún amago; cuando se hunde de verdad, A enseguida (si no,
##      se suelta).
##   3. Recoger: A mantenido recoge hilo y tensa el sedal; en los tirones del pez hay que soltar o
##      se parte (Fishing.Line).
##   4. La captura salta al muelle: las comunes se venden solas; las raras, venderlas o llevarlas a
##      la Biblioteca (su ficha del bestiario); las malditas, además, devolverlas al agua, y si no,
##      el siguiente nivel empieza con la cordura a la mitad (GameSession.fish_curse).
## Al acabar (o con B / Esc), al relato del siguiente nivel (GameSession.level ya lo dice).
## Pruebas: `godot --path . scenes/fishing.tscn -- fish_auto=true fish_force=cria fish_pick=0
## shots=4,9 tag=x pj=varga`.

const ARENA := "res://data/arenas/calles.json"
const SPOT := Vector3(15.0, 0.0, 32.1)          ## el hueco entre dos pilotes del borde sur
const ROD_LEN := 1.9
enum { AIM, FLY, WAIT, BITE, REEL, LANDED, CARD, DONE }

var _cfg := Fishing.cfg()
var _rng := RandomNumberGenerator.new()
var _state := AIM
var _t := 0.0                                   ## reloj de la escena
var _st := 0.0                                  ## tiempo en el estado actual
var _casts := 0
var _money := 0
var _log: Array[String] = []
var _cursed := false
var _was_down := false
var _power := 0.0
var _charging := false
var _target := Vector3.ZERO
var _cast_from := Vector3.ZERO
var _bite_at := 0.0
var _nibbles: Array[float] = []
var _fish := {}
var _line: Fishing.Line
var _sea_y := -1.0

var _arena: Node3D
var _camera: GameCamera
var _focus := Node3D.new()
var _holder := Node3D.new()
var _model: Node3D
var _model_name := "dyer"
var _rod := Node3D.new()
var _bobber := Node3D.new()
var _line_mesh := MeshInstance3D.new()
var _imm := ImmediateMesh.new()
var _fish_node: Node3D
var _fish_model := ""

var _ui: Control
var _top: Label
var _prompt: Label
var _gauge: _Gauge
var _flash: ColorRect

# pruebas
var _la := LaunchArgs.from_cmdline()
var _auto := false
var _shots: Array[float] = []
var _tag := "pesca"

func _ready() -> void:
	_rng.randomize()
	if _la.has("seed"): _rng.seed = _la.get_int("seed")
	_auto = _la.get_bool("fish_auto")
	for s in _la.get_str("shots").split(",", false): _shots.append(float(s))
	_tag = _la.get_str("tag", _tag)
	if get_window().size.x < 640: get_window().size = Vector2i(1920, 1080)   # la ventana de 3×3 px de las pruebas
	if not GameSession.is_set() and _la.has("next"): GameSession.level = StringName(_la.get_str("next"))
	_build_world()
	_build_fisher()
	_build_ui()
	_enter(AIM)

# ------------------------------------------------------------------ mundo

func _build_world() -> void:
	var env := Atmosphere.make_environment()
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)
	_arena = ArenaBuilder.build(ARENA, LevelPreload.fog_volumes())
	add_child(_arena)
	var light: Dictionary = _arena.get_meta("light", {})
	ArenaBuilder.apply_light(light, sun, env)
	Atmosphere.set_lift(env, float(light.get("gamma", 1.0)))
	var sea: Variant = JSON.parse_string(FileAccess.get_file_as_string(ARENA))
	if sea is Dictionary: _sea_y = float(((sea as Dictionary).get("sea", {}) as Dictionary).get("level", -1.0))
	add_child(_focus)
	_focus.position = SPOT + Vector3(0, 0, 2.6)
	_camera = GameCamera.new()
	_camera.view_size = 7.5
	_camera.targets.append(_focus)
	add_child(_camera)
	add_child(Ambient.new().setup(_arena, _camera, ARENA.get_file().get_basename()))

func _build_fisher() -> void:
	var cid := String(GameSession.seats[0].character) if not GameSession.seats.is_empty() else _la.get_str("pj", "dyer")
	var worn: Dictionary = GameSession.seats[0].worn if not GameSession.seats.is_empty() else {}
	var cpath := "res://data/characters/%s.tres" % cid
	if ResourceLoader.exists(cpath): _model_name = (load(cpath) as CharacterData).model
	add_child(_holder)
	_holder.position = SPOT
	_model = VoxelBuilder.load_model("res://models/%s.json" % _model_name)
	_holder.add_child(_model)
	if not worn.is_empty(): OutfitData.apply(_model, _model_name, worn)
	# la caña: de la mano hacia el agua, levantada
	_holder.add_child(_rod)
	_rod.position = Vector3(-0.2, 0.9, 0.28)
	var cane := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.05, ROD_LEN)
	cane.mesh = bm
	cane.position.z = ROD_LEN * 0.5
	cane.material_override = _mat(Color(0.52, 0.36, 0.20))
	_rod.add_child(cane)
	var reel := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.09, 0.09, 0.07)
	reel.mesh = rm
	reel.position = Vector3(0.05, -0.04, 0.22)
	reel.material_override = _mat(Color(0.45, 0.40, 0.30))
	_rod.add_child(reel)
	# el corcho: rojo arriba, blanco abajo
	add_child(_bobber)
	for k in 2:
		var b := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = Vector3(0.11, 0.07, 0.11)
		b.mesh = cm
		b.position.y = 0.035 if k == 0 else -0.035
		b.material_override = _mat(Color(0.80, 0.12, 0.08) if k == 0 else Color(0.90, 0.88, 0.82), 0.4 if k == 0 else 0.0)
		_bobber.add_child(b)
	_bobber.visible = false
	_line_mesh.mesh = _imm
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(0.85, 0.85, 0.80, 0.8)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_mesh.material_override = lm
	add_child(_line_mesh)

func _mat(c: Color, glow := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m

func _tip() -> Vector3:
	return _rod.to_global(Vector3(0, 0, ROD_LEN))

# ------------------------------------------------------------------ interfaz

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.theme = MenuKit.theme()
	layer.add_child(_ui)
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0.05, 0.22, 0.14, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_flash)
	_top = UiKit.label("", 30, UiKit.GOLD)
	_top.add_theme_font_override("font", MenuKit.font())
	_top.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top.position.y = 26
	_top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_ui.add_child(_top)
	_prompt = UiKit.label("", 30, Color(0.92, 0.88, 0.78))
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.position.y = -70
	_ui.add_child(_prompt)
	_gauge = _Gauge.new()
	_gauge.anchor_left = 0.5; _gauge.anchor_right = 0.5
	_gauge.anchor_top = 1.0; _gauge.anchor_bottom = 1.0
	_gauge.offset_left = -320; _gauge.offset_right = 320
	_gauge.offset_top = -240; _gauge.offset_bottom = -150
	_gauge.visible = false
	_ui.add_child(_gauge)
	_refresh_top()

func _refresh_top() -> void:
	var left := int(_cfg.get("casts", 5)) - _casts
	_top.text = "El muelle de Innsmouth  ·  %s  ·  %s $" % [MenuKit.count(left, "lance"), MenuKit.money(_money)]

## Barra de fuerza al lanzar, o de tensión y de hilo recogido al recoger.
class _Gauge extends Control:
	var mode := 0                                ## 0: fuerza; 1: tensión y progreso
	var a := 0.0
	var b := 0.0
	var alarm := false
	func _draw() -> void:
		var w := size.x
		var font := get_theme_default_font()
		if mode == 0:
			_bar(Rect2(0, 40, w, 26), a, Color(0.85, 0.66, 0.28))
			draw_string(font, Vector2(0, 30), "Fuerza", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.9, 0.85, 0.7))
		else:
			var tc := Color(0.80, 0.18, 0.12) if a > 0.75 else Color(0.85, 0.62, 0.25)
			if alarm and fmod(Time.get_ticks_msec() / 1000.0, 0.3) < 0.15: tc = Color(1.0, 0.4, 0.3)
			draw_string(font, Vector2(0, 18), "Tensión del sedal", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.9, 0.85, 0.7))
			_bar(Rect2(0, 24, w, 20), a, tc)
			draw_string(font, Vector2(0, 68), "Hilo recogido", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.9, 0.85, 0.7))
			_bar(Rect2(0, 74, w, 14), b, Color(0.45, 0.70, 0.62))
	func _bar(r: Rect2, v: float, c: Color) -> void:
		draw_rect(r.grow(3), Color(0.08, 0.05, 0.03, 0.85))
		draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(v, 0.0, 1.0), r.size.y)), c)
		draw_rect(r.grow(3), Color(0.62, 0.48, 0.26), false, 2.0)

# ------------------------------------------------------------------ estados

func _enter(s: int) -> void:
	_state = s
	_st = 0.0
	match s:
		AIM:
			_power = 0.0
			_charging = false
			_bobber.visible = false
			_gauge.mode = 0
			_gauge.visible = false
			_prompt.text = "Mantén A (o Intro) para lanzar; suéltalo con la fuerza que quieras  ·  B: dejar de pescar"
		FLY:
			_casts += 1
			_refresh_top()
			_gauge.visible = false
			_prompt.text = ""
			_cast_from = _tip()
			var dist := lerpf(3.0, 9.5, _power)
			_target = Vector3(SPOT.x + _rng.randf_range(-1.2, 1.2), _sea_y, SPOT.z + 1.2 + dist)
			_bobber.visible = true
			Auto.sfx("swing")
		WAIT:
			_fish = Fishing.find(_la.get_str("fish_force")) if _la.has("fish_force") else Fishing.roll(_rng)
			var w: Array = _cfg.get("bite_wait", [2.5, 6.5])
			_bite_at = _rng.randf_range(float(w[0]), float(w[1]))
			_nibbles.clear()
			var nb: Array = _cfg.get("nibbles", [0, 2])
			for k in _rng.randi_range(int(nb[0]), int(nb[1])): _nibbles.append(_rng.randf_range(0.8, _bite_at - 0.6))
			_prompt.text = "Espera a que se hunda el corcho…"
		BITE:
			_prompt.text = "¡Pica!  ·  A"
			Auto.sfx("splash")
			_ring(_bobber.global_position, 1.4)
		REEL:
			_line = Fishing.Line.new(_fish, _rng)
			_gauge.mode = 1
			_gauge.visible = true
			_prompt.text = "Mantén A para recoger  ·  suelta cuando tire, o se parte el sedal"
		LANDED:
			_gauge.visible = false
			_prompt.text = ""
			_fish_model = String(_fish.model)
			_fish_node = Node3D.new()
			add_child(_fish_node)
			var m := VoxelBuilder.load_model("res://models/%s.json" % _fish_model)
			_fish_node.add_child(m)
			_fish_node.rotation.y = PI * 0.5 + 0.4          # la cabeza (X) hacia el muelle, de lado a la cámara
			_cast_from = _bobber.global_position
			_bobber.visible = false
			Auto.sfx("splash")
			_ring(_cast_from, 1.6)
			if String(_fish.rarity) == "maldito":
				_cursed_reveal()
		DONE:
			_summary()

func _process(delta: float) -> void:
	_t += delta
	_st += delta
	var down := _accept_down()
	var pressed := down and not _was_down
	var released := _was_down and not down
	_was_down = down
	_pose(delta)
	match _state:
		AIM:
			if pressed: _charging = true
			if _charging:
				_gauge.visible = true
				_power = 1.0 - absf(1.0 - fmod(_st * 0.9, 2.0))   # va y viene
				_gauge.a = _power
				_gauge.queue_redraw()
				if released:
					_enter(FLY)
			else:
				_st = 0.0
			if _cancel_pressed(): _enter(DONE)
		FLY:
			var k := minf(1.0, _st / 0.75)
			var p := _cast_from.lerp(_target, k)
			p.y += sin(k * PI) * 2.2 * (0.6 + _power * 0.5)
			_bobber.global_position = p
			if k >= 1.0:
				Auto.sfx("step_water")
				_ring(_target, 1.0)
				_enter(WAIT)
		WAIT:
			var y := _sea_y + 0.02 + sin(_t * 2.6) * 0.015
			for n in _nibbles:
				var d := _st - n
				if d > 0.0 and d < 0.3:
					y -= sin(d / 0.3 * PI) * 0.06
					if d < delta * 1.5:
						_ring(_bobber.global_position, 0.5)
						Auto.sfx("drip")
			_bobber.global_position = Vector3(_target.x, y, _target.z)
			if pressed and _st < _bite_at:                # demasiado pronto: se espanta
				_missed("Demasiado pronto: lo has espantado")
				return
			if _st >= _bite_at: _enter(BITE)
		BITE:
			_bobber.global_position = Vector3(_target.x, _sea_y - 0.12 - sin(_st * 30.0) * 0.02, _target.z)
			if pressed: _enter(REEL)
			elif _st > float(_cfg.get("strike_window", 0.9)): _missed("Se ha soltado")
		REEL:
			var st := _line.step(delta, down)
			_gauge.a = _line.tension
			_gauge.b = _line.progress
			_gauge.alarm = _line.bursting
			_gauge.queue_redraw()
			var near := Vector3(SPOT.x, _sea_y, SPOT.z + 1.3)
			var p := near.lerp(_target, 1.0 - _line.progress)
			if _line.bursting:
				p.x += sin(_t * 17.0) * 0.18
				p.y -= 0.08
				if fmod(_t, 0.25) < delta: _ring(p, 0.7)
			_bobber.global_position = p
			if st == Fishing.Line.CAUGHT: _enter(LANDED)
			elif st == Fishing.Line.BROKE:
				Auto.sfx("ice_crack")
				_missed("¡Se ha partido el sedal!")
		LANDED:
			var k := minf(1.0, _st / 0.9)
			var to := SPOT + Vector3(0.15, 1.15, 0.75)
			var p := _cast_from.lerp(to, k)
			p.y += sin(k * PI) * 1.6
			_fish_node.global_position = p
			if k >= 1.0 and _st > 1.4: _card()
		CARD, DONE:
			pass
	if _fish_node != null and is_instance_valid(_fish_node):
		var fm: Node3D = _fish_node.get_child(0)
		Anims.pose(_fish_model, "flop", fm, fmod(_t / Anims.duration(_fish_model, "flop"), 1.0))
	_draw_line()
	_test_tick(delta)

func _missed(why: String) -> void:
	_prompt.text = why
	_state = CARD                                  # unos instantes quieto, y al siguiente lance
	_bobber.visible = false
	_log.append(why.trim_prefix("¡").trim_suffix("!"))
	get_tree().create_timer(1.6).timeout.connect(_after_catch)

func _after_catch() -> void:
	if _fish_node != null and is_instance_valid(_fish_node): _fish_node.queue_free()
	_fish_node = null
	if _casts >= int(_cfg.get("casts", 5)): _enter(DONE)
	else: _enter(AIM)

func _accept_down() -> bool:
	if _auto: return _auto_down()
	return Input.is_action_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE)

func _cancel_pressed() -> bool:
	return Input.is_action_just_pressed("ui_cancel") and not _auto

## El investigador: de pie con su reposo y los brazos sujetando la caña; al cargar, la caña atrás.
func _pose(_delta: float) -> void:
	Anims.pose(_model_name, "idle", _model, fmod(_t / Anims.duration(_model_name, "idle"), 1.0))
	var parts: Dictionary = _model.get_meta("part_nodes", {})
	var lift := -0.95
	var pitch := -0.62
	match _state:
		AIM:
			if _charging:
				pitch = lerpf(-0.62, -1.9, minf(1.0, _st * 4.0))   # la caña, atrás por encima del hombro
				lift = -1.4
		FLY:
			pitch = lerpf(-1.9, -0.35, minf(1.0, _st * 5.0))
		REEL:
			pitch = -0.78 - (0.25 if _line != null and _line.bursting else 0.0) + sin(_t * 9.0) * (0.04 if _was_down else 0.0)
		BITE:
			pitch = -0.5
	_rod.rotation.x = lerpf(_rod.rotation.x, pitch, 0.35)
	for n in ["arm_r", "arm_l"]:
		var arm: Node3D = parts.get(n)
		if arm != null: arm.rotation.x = lift
	var fr: Node3D = parts.get("fore_r")
	if fr != null: fr.rotation.x = -0.5
	var fl: Node3D = parts.get("fore_l")
	if fl != null: fl.rotation.x = -0.6

func _draw_line() -> void:
	_imm.clear_surfaces()
	if not _bobber.visible and _state != LANDED: return
	var a := _tip()
	var b := _bobber.global_position + Vector3(0, 0.07, 0) if _state != LANDED else _fish_node.global_position + Vector3(0, 0.1, 0)
	var sag := 0.0 if _state == REEL else (0.5 if _state == WAIT or _state == BITE else 0.15)
	_imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 13:
		var k := i / 12.0
		var p := a.lerp(b, k)
		p.y -= sin(k * PI) * sag
		_imm.surface_add_vertex(p)
	_imm.surface_end()

## Onda en el agua: un anillo que se abre y se apaga.
func _ring(at: Vector3, big: float) -> void:
	var r := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.13
	tm.outer_radius = 0.15
	tm.rings = 24
	tm.ring_segments = 4
	r.mesh = tm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.80, 0.88, 0.86, 0.35)
	r.material_override = m
	r.scale = Vector3(1, 0.15, 1)
	add_child(r)
	r.global_position = Vector3(at.x, _sea_y + 0.01, at.z)
	var tw := r.create_tween().set_parallel()
	tw.tween_property(r, "scale", Vector3(big * 2.6, 0.1, big * 2.6), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.8)
	tw.chain().tween_callback(r.queue_free)

func _cursed_reveal() -> void:
	_cursed = true
	Auto.sfx("heartbeat")
	Auto.sfx("angles")
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.5, 0.15)
	tw.tween_property(_flash, "color:a", 0.18, 0.6)

# ------------------------------------------------------------------ la captura

func _card() -> void:
	_state = CARD
	var rarity := String(_fish.rarity)
	var id := String(_fish.id)
	var price := int(_fish.price)
	var first := Fishing.caught(Saves.current, id) == 0
	var accent := UiKit.GOLD if rarity == "raro" else (Color(0.30, 0.62, 0.45) if rarity == "maldito" else MenuKit.INK)
	var w: Array = MenuKit.window(_ui, accent, 760)
	var root: Control = w[0]
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, String(_fish.name), 40, UiKit.GOLD if rarity != "comun" else MenuKit.INK)
	var img := TextureRect.new()
	var vp := ModelIcon.make_live(_fish_model, 300, ModelIcon.frame_size(_fish_model) * ModelIcon.MARGIN)
	img.add_child(vp)
	img.texture = vp.get_texture()
	img.custom_minimum_size = Vector2(300, 300)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(img)
	var info := PackedStringArray([String(Fishing.RARITY_NAMES.get(rarity, rarity))])
	if first: info.append("Nueva en el bestiario")
	var l := UiKit.label("  ·  ".join(info), 24, Color(0.55, 0.85, 0.65) if rarity == "maldito" else UiKit.GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	if rarity == "maldito":
		var c := UiKit.label("Lo que has sacado no debería haber salido del agua. Si te lo quedas o lo vendes, empezarás el siguiente nivel con la cordura a la mitad.", 22, Color(0.85, 0.82, 0.74))
		c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c.custom_minimum_size.x = 680
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(c)
	var options: Array = []                         # [texto, vendida, a la Biblioteca, maldición]
	match rarity:
		"comun": options = [["Venderla en la lonja (+%d $)" % price, true, false, false]]
		"raro": options = [["Llevarla a la Biblioteca (su ficha del bestiario)", false, true, false], ["Venderla (+%d $)" % price, true, false, false]]
		_: options = [["Devolverla al agua", false, false, false], ["Llevarla a la Biblioteca (su ficha del bestiario)", false, true, true], ["Venderla (+%d $)" % price, true, false, true]]
	var firstb: Button = null
	var bi := 0
	for o: Array in options:
		var b := MenuKit.button(String(o[0]), MenuKit.INK, 24)
		b.custom_minimum_size = Vector2(680, 56)
		var i := bi
		b.pressed.connect(func() -> void: _choose(o, root))
		box.add_child(b)
		if firstb == null: firstb = b
		if _auto and i == _la.get_int("fish_pick", 0) % options.size():
			get_tree().create_timer(1.2).timeout.connect(func() -> void: if is_instance_valid(b): b.pressed.emit())
		bi += 1
	if firstb != null: firstb.grab_focus.call_deferred()
	Auto.sfx("chest" if rarity != "comun" else "pickup")
	if _la.get_bool("card_shot"): get_tree().create_timer(1.0).timeout.connect(func() -> void: _snap("ficha_" + String(_fish.id)))

func _choose(o: Array, card: Control) -> void:
	var id := String(_fish.id)
	var sold: bool = o[1]
	var kept: bool = o[2]
	Fishing.record(Saves.current, id, kept)
	if sold:
		_money += int(_fish.price)
		if Saves.current != null: Saves.current.money += int(_fish.price)
	if o[3]: GameSession.fish_curse = true
	var what := "vendida" if sold else ("a la Biblioteca" if kept else "devuelta al agua")
	_log.append("%s, %s%s" % [String(_fish.name), what, (" (+%d $)" % int(_fish.price)) if sold else ""])
	print("PESCA ", id, " ", what)
	_refresh_top()
	card.queue_free()
	if _flash.color.a > 0.0: create_tween().tween_property(_flash, "color:a", 0.0, 0.5)
	_after_catch()

func _summary() -> void:
	_state = DONE
	_bobber.visible = false
	_gauge.visible = false
	_prompt.text = ""
	Saves.save()
	var w: Array = MenuKit.window(_ui, MenuKit.INK, 760)
	var box: VBoxContainer = w[1]
	MenuKit.heading(box, "Fin de la pesca", 40)
	for s in (_log if not _log.is_empty() else ["No has sacado nada"] as Array[String]):
		var l := UiKit.label(s, 22, Color(0.88, 0.84, 0.74))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
	var tot := UiKit.label("En total: +%s $" % MenuKit.money(_money), 26, UiKit.GOLD)
	tot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tot)
	if GameSession.fish_curse:
		var c := UiKit.label("Algo te sigue mirando desde el agua: el siguiente nivel empieza con la cordura a la mitad.", 22, Color(0.55, 0.85, 0.65))
		c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c.custom_minimum_size.x = 680
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(c)
	var b := MenuKit.button("Seguir al siguiente nivel", MenuKit.INK, 28)
	b.custom_minimum_size = Vector2(680, 60)
	b.pressed.connect(_leave)
	box.add_child(b)
	b.grab_focus.call_deferred()
	if _auto and _shots.is_empty(): get_tree().create_timer(1.5).timeout.connect(_leave)

func _leave() -> void:
	print("PESCA FIN ", _money, " $", " maldicion" if GameSession.fish_curse else "")
	if GameSession.carry.is_empty() and not _la.has("next"):   # suelta, en pruebas (sin partida de la que venga)
		get_tree().quit()
		return
	get_tree().change_scene_to_file("res://scenes/relato.tscn")

# ------------------------------------------------------------------ pruebas

## El que pesca solo (`fish_auto=true`): carga hasta el 70 %, clava al picar y recoge mientras la
## tensión no pase de 0,6 ni tire el pez.
var _auto_hold := false
func _auto_down() -> bool:
	match _state:
		AIM: return _st < 0.8 or (_charging and _power < 0.7 and _st < 3.0)
		BITE: return _st > 0.25
		REEL:
			if _line == null: return false
			if _line.bursting or _line.tension > 0.6: _auto_hold = false
			elif _line.tension < 0.25: _auto_hold = true
			return _auto_hold
	return false

func _test_tick(_delta: float) -> void:
	if _shots.is_empty() or _t < _shots[0]: return
	_shots.pop_front()
	await _snap("%05.1fs" % _t)
	if _shots.is_empty(): get_tree().quit()

func _snap(what: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://shots/pesca_%s_%s.png" % [_tag, what])
	print("captura: pesca_%s_%s.png" % [_tag, what])
