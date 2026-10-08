class_name Hazards
extends Node3D
## Peligros del escenario (hito 7.4), con los datos del nivel (`LevelData.angle_*`, `wave_*`):
## - Ángulos devoradores (GDD 2.4): cada `angle_every` s se abre una grieta de geometría
##   imposible cerca de un jugador en pie, con aviso de `angle_warn` s; abierta durante
##   `angle_time` s, atrae hacia su centro (`angle_pull` m/s, más cuanto más cerca) y engulle
##   (`angle_damage` de vida y la mitad de cordura por segundo) a quien está en el centro. No se
##   matan: se esquivan. Se cierran solos.
## - Olas que barren la cubierta: cada `wave_every` s, una franja de lado a lado marcada en el
##   suelo; al cumplirse el aviso, el agua empuja (`wave_push`) a quien está dentro hacia el sur
##   y le quita `wave_damage`.
## Los jugadores se mueven con `Player.push` (velocidad externa de un paso).

var level: LevelData
var world: CombatWorld
var obstacles: ObstacleMap
var rng := RandomNumberGenerator.new()
var _angle_t := 0.0
var _wave_t := 0.0
var _open: Array[Dictionary] = []          ## {pos, r, t, node}
var _waves: Array[Dictionary] = []         ## {z, half, t}

func setup(p_level: LevelData, p_world: CombatWorld, p_obstacles: ObstacleMap) -> Hazards:
	level = p_level; world = p_world; obstacles = p_obstacles
	name = "Hazards"
	_angle_t = level.angle_every * 0.6
	_wave_t = level.wave_every * 0.8
	return self

func _physics_process(delta: float) -> void:
	if level.angle_every > 0.0:
		_angle_t -= delta
		if _angle_t <= 0.0:
			_angle_t = level.angle_every * rng.randf_range(0.8, 1.2)
			_spawn_angle()
	if level.wave_every > 0.0:
		_wave_t -= delta
		if _wave_t <= 0.0:
			_wave_t = level.wave_every * rng.randf_range(0.85, 1.15)
			_spawn_wave()
	_step_angles(delta)
	_step_waves(delta)

func _standing() -> Array:
	return world.players.filter(func(p: Player) -> bool: return p.health > 0.0)

# --- Ángulos devoradores ---
func _spawn_angle() -> void:
	var who: Array = _standing()
	if who.is_empty(): return
	var p: Player = who[rng.randi() % who.size()]
	var r := level.angle_radius
	for attempt in 20:
		var a := rng.randf() * TAU
		var c := Vector2(p.global_position.x, p.global_position.z) + Vector2(cos(a), sin(a)) * rng.randf_range(1.0, 4.0)
		if obstacles != null and obstacles.is_blocked(c, 0.5): continue
		var pos := Vector3(c.x, 0, c.y)
		var tg := Telegraph.new().setup(r, level.angle_warn, Color(0.35, 0.9, 0.5, 0.75))
		tg.position = pos
		world.fx.add_child(tg)
		tg.finished.connect(func() -> void: _open_angle(pos, r))
		return

func _open_angle(pos: Vector3, r: float) -> void:
	Sfx.play("angles")
	var node := _angle_mesh(r)
	node.position = pos
	world.fx.add_child(node)
	_open.append({"pos": pos, "r": r, "t": level.angle_time, "node": node})
	if OS.get_cmdline_user_args().has("log=true"): print("ANGULOS abiertos")

func _step_angles(delta: float) -> void:
	for i in range(_open.size() - 1, -1, -1):
		var h: Dictionary = _open[i]
		h.t -= delta
		var node: Node3D = h.node
		node.rotation.y += delta * 0.9
		var ht := float(h.t)
		var hr := float(h.r)
		var k := clampf(minf(level.angle_time - ht, ht) / 0.35, 0.0, 1.0)   # se abre y se cierra
		node.scale = Vector3(k, 1.0, k)
		if ht <= 0.0:
			node.queue_free()
			_open.remove_at(i)
			continue
		for p: Player in _standing():
			var to: Vector3 = h.pos - p.global_position
			to.y = 0.0
			var d := to.length()
			if d > hr * 1.6 or d < 0.05: continue
			var pull: float = level.angle_pull * (1.0 - d / (hr * 1.6)) * k
			p.push += to / d * pull
			if d < hr * 0.45:                          # en el centro: engulle
				p.take_damage(Damage.new(level.angle_damage * delta, level.angle_damage * 0.5 * delta))

## La grieta: esquirlas negras y verdes en ángulos que no cuadran, que giran despacio.
func _angle_mesh(r: float) -> Node3D:
	var root := Node3D.new()
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.02, 0.04, 0.03)
	dark.roughness = 0.2
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(0.25, 0.85, 0.45) * 0.8
	var floor_mi := MeshInstance3D.new()                  # el pozo: un disco negro
	var cyl := CylinderMesh.new()
	cyl.top_radius = r * 0.55; cyl.bottom_radius = r * 0.55; cyl.height = 0.04; cyl.radial_segments = 7
	floor_mi.mesh = cyl
	floor_mi.material_override = dark
	floor_mi.position.y = 0.03
	root.add_child(floor_mi)
	for i in 9:                                           # esquirlas inclinadas
		var mi := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(rng.randf_range(0.12, 0.3), rng.randf_range(0.5, 1.4), rng.randf_range(0.05, 0.12))
		mi.mesh = b
		mi.material_override = glow if i % 3 == 0 else dark
		var a := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
		mi.position = Vector3(cos(a), 0.3, sin(a)) * r * rng.randf_range(0.5, 0.9)
		mi.position.y = 0.3
		mi.rotation = Vector3(rng.randf_range(-0.9, 0.9), a + rng.randf_range(-1, 1), rng.randf_range(-0.9, 0.9))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	return root

# --- olas que barren la cubierta ---
func _spawn_wave() -> void:
	var who: Array = _standing()
	if who.is_empty(): return
	var p: Player = who[rng.randi() % who.size()]
	var b := obstacles.bounds if obstacles != null else Rect2(-32, -32, 64, 64)
	var z := clampf(p.global_position.z + rng.randf_range(-2.0, 2.0), b.position.y + 2.0, b.end.y - 2.0)
	var half := level.wave_width * 0.5
	var band := MeshInstance3D.new()                      # aviso: una franja azul de lado a lado
	var pm := PlaneMesh.new()
	pm.size = Vector2(b.size.x, level.wave_width)
	band.mesh = pm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.3, 0.6, 0.9, 0.25)
	band.material_override = m
	band.position = Vector3(b.get_center().x, 0.05, z)
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.fx.add_child(band)
	_waves.append({"z": z, "half": half, "t": level.wave_warn, "node": band, "hit": false})

func _step_waves(delta: float) -> void:
	for i in range(_waves.size() - 1, -1, -1):
		var w: Dictionary = _waves[i]
		w.t -= delta
		var mat := (w.node as MeshInstance3D).material_override as StandardMaterial3D
		if w.t > 0.0:
			var wt := float(w.t)
			mat.albedo_color.a = 0.2 + 0.25 * (1.0 - wt / level.wave_warn) + 0.1 * sin(wt * 20.0)
			continue
		if not w.hit:                                       # rompe la ola
			w.hit = true
			Sfx.play("wave")
			mat.albedo_color = Color(0.75, 0.88, 1.0, 0.6)
			var b := obstacles.bounds if obstacles != null else Rect2(-32, -32, 64, 64)
			for x in range(int(b.position.x), int(b.end.x), 4):
				WadeSplash.burst(world.fx, Vector3(x, 0, w.z), 1.2)
			for p: Player in _standing():
				if absf(p.global_position.z - w.z) < w.half:
					p.take_damage(Damage.new(level.wave_damage, 0.0))
		if w.t > -0.5:                                      # empuja medio segundo hacia el sur
			for p: Player in _standing():
				if absf(p.global_position.z - w.z) < w.half + 0.5: p.push += Vector3(0.4, 0, 1.0).normalized() * level.wave_push
			continue
		(w.node as Node).queue_free()
		_waves.remove_at(i)
