class_name DistantEvents
extends Node3D
## Sucesos lejanos (hito 17.18): de vez en cuando, más allá del borde de la arena, pasa algo
## grande que no se puede tocar. Uno por arena (`distant` en data/ambient.json); solo empieza si su
## sitio está en pantalla, para que se vea. Solo visual, y cada PC el suyo.
##
## Tipos (`kind`):
## - `rise`: un modelo sube del agua en uno de sus `spots` ([x, z]), se queda meciéndose y se hunde
##   (el tentáculo del arrecife, Dagón junto al arrecife del Diablo).
## - `flash`: una silueta negra en un `spot` que solo se ve mientras dura el relámpago (`chance` de
##   cada rayo; la tormenta).
## - `cross`: un modelo cruza la pantalla de lado a lado, `back` m más allá del jugador y a `h` m de
##   alto, con su animación (`anim`): los antiguos alados, el byakhee, el shoggoth de la ciudad.
## - `lights`: `n` faroles que recorren un `path` ([[x, z], ...]) a `speed` m/s, o que hacen señales
##   desde sus `spots` (`signal`: true): las procesiones de cultistas, las luces del arrecife.
## - `turn`: las piezas con `turn` en `models` se giran hacia el jugador más cercano mientras no se
##   las ve (las esculturas del estudio).
## Comunes: `every` [s, s] entre sucesos, `dur` s, `model`, `scale`, `y`.

var camera: Camera3D
var game: Node                                  ## para los jugadores y el tiempo (weather)
var _ev: Array[Dictionary] = []
var _turners: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _black: StandardMaterial3D
var _lamp_mat: StandardMaterial3D
var _turn_t := 0.0
var _last_flash := 0.0
static var soon := false                        ## distant_soon=true: el primero, en cuanto se vea (capturas)

const SHADOW_H := 2.2                           ## a qué altura va la copia que da la sombra de lo que vuela

func setup(list: Array, p_camera: Camera3D, p_game: Node, turners: Array) -> DistantEvents:
	camera = p_camera
	game = p_game
	name = "DistantEvents"
	_rng.randomize()
	soon = soon or "distant_soon=true" in OS.get_cmdline_user_args()   # se lee antes que game.gd
	for c: Dictionary in list:
		var e := {"cfg": c, "kind": String(c.get("kind", "rise")), "t": -1.0}
		var ev: Array = c.get("every", [60, 120])
		e.wait = 1.0 if soon else _rng.randf_range(float(ev[0]) * 0.25, float(ev[1]) * 0.5)
		if e.kind in ["rise", "flash", "cross"]:
			var h := Node3D.new()
			h.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # se mueve en _process
			h.visible = false
			var m := VoxelBuilder.load_model("res://models/%s.json" % String(c.model))
			h.add_child(m)
			for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				if e.kind == "flash": mi.material_override = _silhouette()
				elif c.get("far", false): mi.material_override = _haze()          # lejos: silueta en la bruma
			h.scale = Vector3.ONE * float(c.get("scale", 1.0))
			add_child(h)
			e.node = h
			e.model = m
			if e.kind == "cross" and float(c.get("h", 0.0)) > 2.0:
				# lo que vuela deja su sombra: una copia que solo da sombra y no se ve, así que puede ir
				# baja y por la línea de los jugadores (la de verdad caería fuera de la pantalla)
				var sh := Node3D.new()
				sh.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
				sh.visible = false
				var sm := VoxelBuilder.load_model("res://models/%s.json" % String(c.model))
				for mi: MeshInstance3D in sm.find_children("*", "MeshInstance3D", true, false):
					mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
				sh.add_child(sm)
				sh.scale = h.scale
				add_child(sh)
				e.shadow = sm
				e.shadow_node = sh
		elif e.kind == "lights":
			var lamps: Array[MeshInstance3D] = []
			var bm := BoxMesh.new()
			bm.size = Vector3.ONE * float(c.get("size", 0.16))
			for i in int(c.get("n", 6)):
				var l := MeshInstance3D.new()
				l.mesh = bm
				l.material_override = _lamp(c)
				l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				l.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
				l.visible = false
				add_child(l)
				lamps.append(l)
			e.lamps = lamps
		_ev.append(e)
	for h: Node3D in turners:
		_turners.append({"h": h, "seen": true, "base": h.rotation.y})
	return self

func _silhouette() -> StandardMaterial3D:
	if _black == null:
		_black = VoxelFx.std()
		_black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_black.albedo_color = Color(0.01, 0.012, 0.016)
	return _black

var _haze_mat: StandardMaterial3D
func _haze() -> StandardMaterial3D:
	if _haze_mat == null:
		_haze_mat = VoxelFx.std()
		_haze_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_haze_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_haze_mat.albedo_color = Color(0.04, 0.05, 0.08, 0.72)
	return _haze_mat

func _lamp(c: Dictionary) -> StandardMaterial3D:
	if _lamp_mat == null:
		var col: Array = c.get("color", [1.0, 0.62, 0.25])
		_lamp_mat = VoxelFx.std()
		_lamp_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_lamp_mat.albedo_color = Color(col[0], col[1], col[2])
	return _lamp_mat

## ¿Se ve ese punto? (dentro de la pantalla, con un margen)
func seen(p: Vector3, margin := 0.08) -> bool:
	if camera == null or not is_instance_valid(camera) or camera.is_position_behind(p): return false
	var vp := camera.get_viewport().get_visible_rect().size
	var s := camera.unproject_position(p)
	return s.x > vp.x * margin and s.x < vp.x * (1.0 - margin) and s.y > vp.y * margin and s.y < vp.y * (1.0 - margin)

## A un lado de la pantalla (lejos del centro, donde está el jugador): lo que sube del mar de
## delante no tapa la partida.
func _aside(p: Vector3) -> bool:
	var w := camera.get_viewport().get_visible_rect().size.x
	return absf(camera.unproject_position(p).x - w * 0.5) > w * 0.3

func _process(delta: float) -> void:
	var flash := _flash()
	var bolt := flash > 0.3 and _last_flash <= 0.3
	_last_flash = flash
	for e in _ev:
		if e.t < 0.0:
			if e.kind == "flash":
				if bolt and _rng.randf() < float(e.cfg.get("chance", 0.5)): _try_start(e)
				continue
			e.wait -= delta
			if e.wait <= 0.0 and not _try_start(e): e.wait = 1.5        # no se ve: se espera un poco
			continue
		e.t += delta
		match String(e.kind):
			"rise": _rise_step(e)
			"flash": _flash_step(e, flash)
			"cross": _cross_step(e)
			"lights": _lights_step(e)
	if not _turners.is_empty():
		_turn_t -= delta
		if _turn_t <= 0.0:
			_turn_t = 0.4
			_turn_step()

func _flash() -> float:
	if game != null and "weather" in game and game.weather != null: return float(game.weather.flash)
	return 0.0

func _done(e: Dictionary) -> void:
	if e.t >= 0.0: _sound(e, "end")
	e.t = -1.0
	var ev: Array = e.cfg.get("every", [60, 120])
	e.wait = _rng.randf_range(float(ev[0]), float(ev[1]))
	if e.has("node"): (e.node as Node3D).visible = false
	if e.has("shadow_node"): (e.shadow_node as Node3D).visible = false
	for l: MeshInstance3D in e.get("lamps", []): l.visible = false

## Empieza si su sitio se ve; devuelve si ha empezado.
func _try_start(e: Dictionary) -> bool:
	var c: Dictionary = e.cfg
	var y := float(c.get("y", 0.0))
	match String(e.kind):
		"rise", "flash", "lights":
			var spots: Array = []
			if e.kind == "lights" and not c.get("signal", false):
				# el primer trozo del camino que se ve: la procesión empieza un poco antes
				var path: Array = c.path
				var acc := 0.0
				var first := -1.0
				for i in range(1, path.size()):
					var a := Vector2(path[i - 1][0], path[i - 1][1])
					var b := Vector2(path[i][0], path[i][1])
					var L := a.distance_to(b)
					var s := 0.0
					while s <= L and first < 0.0:
						var q := a.lerp(b, s / maxf(L, 0.001))
						if seen(Vector3(q.x, y, q.y), 0.02): first = acc + s
						s += 3.0
					acc += L
				if first < 0.0: return false
				e.s0 = maxf(first - 6.0, 0.0)
			else:
				for p: Array in c.spots:
					var at := Vector3(p[0], y + float(c.get("look_h", 1.0)), p[1])
					if seen(at, 0.02) and (not c.get("aside", false) or _aside(at)): spots.append(p)
				if spots.is_empty(): return false
				var sp: Array = spots[_rng.randi() % spots.size()]
				e.at = Vector3(sp[0], y, sp[1])
				if e.has("node"):
					var h: Node3D = e.node
					h.position = e.at + Vector3.DOWN * (float(c.get("depth", 8.0)) if e.kind == "rise" else 0.0)   # empieza hundido
					h.rotation.y = deg_to_rad(float(c.get("rot", 0.0))) + _rng.randf_range(-0.4, 0.4)
					h.visible = e.kind == "rise"
		"cross":
			var f := _focus()
			var right := camera.global_basis.x
			right.y = 0.0
			right = right.normalized()
			var fwd := -camera.global_basis.z
			fwd.y = 0.0
			fwd = fwd.normalized()
			var span := float(c.get("span", 22.0))
			var side := 1.0 if _rng.randf() < 0.5 else -1.0
			var mid := f + fwd * float(c.get("back", 12.0)) + Vector3.UP * float(c.get("h", 10.0))
			e.from = mid - right * span * side
			e.to = mid + right * span * side + Vector3.UP * _rng.randf_range(-1.5, 2.5)
			var h: Node3D = e.node
			h.position = e.from
			h.visible = true
			var dir: Vector3 = e.to - e.from
			h.rotation.y = atan2(dir.x, dir.z)
			e.back = fwd * float(c.get("back", 12.0)) + _moon_reach()
			if e.has("shadow_node"): (e.shadow_node as Node3D).visible = true
	e.t = 0.0
	e.said = {}
	_sound(e, "start")
	return true

## Cuánto se aleja por el suelo la sombra de algo a SHADOW_H m, según la luna: la copia que da la
## sombra va eso más acá, para que la sombra caiga en la línea de los jugadores.
func _moon_reach() -> Vector3:
	if not is_inside_tree(): return Vector3.ZERO
	for l: DirectionalLight3D in get_tree().root.find_children("*", "DirectionalLight3D", true, false):
		if not l.shadow_enabled or not l.visible: continue
		var d := -l.global_basis.z                      # hacia donde va la luz
		if d.y > -0.15: continue                          # muy rasante: no cabe
		return Vector3(d.x, 0.0, d.z) * (SHADOW_H / -d.y)
	return Vector3.ZERO

## Sonido lejano del suceso, donde pasa: `sound` = {start, sink (al empezar a hundirse), pass (a
## mitad del cruce), end, db}. Cada uno, una vez por suceso.
func _sound(e: Dictionary, which: String) -> void:
	var s: Dictionary = e.cfg.get("sound", {})
	if not s.has(which) or (e.get("said", {}) as Dictionary).has(which): return
	e.said[which] = true
	var at: Vector3 = e.get("at", e.get("from", _focus()))
	if e.kind == "cross": at = (e.node as Node3D).position
	Auto.sfx_at(String(s[which]), at, float(s.get("db", -6.0)))

func _focus() -> Vector3:
	var players: Array = game.players if game != null and "players" in game else []
	for p in players:
		if is_instance_valid(p): return (p as Node3D).global_position
	return camera.global_position if camera != null else Vector3.ZERO

func _anim(e: Dictionary, default_anim: String) -> void:
	var c: Dictionary = e.cfg
	var a := String(c.get("anim", default_anim))
	var mname := String(c.model)
	if a == "" or not Anims.has_anim(mname, a): return
	var d := Anims.duration(mname, a) * float(c.get("anim_slow", 1.0))
	Anims.pose(mname, a, e.model, fmod(float(e.t) / d, 1.0))
	if e.has("shadow"): Anims.pose(mname, a, e.shadow, fmod(float(e.t) / d, 1.0))

## Sube, se mece y se hunde: un cuarto subiendo, la mitad arriba, un cuarto bajando.
func _rise_step(e: Dictionary) -> void:
	var c: Dictionary = e.cfg
	var dur := float(c.get("dur", 10.0))
	var u := float(e.t) / dur
	if u >= 1.0:
		_done(e)
		return
	if u >= 0.75: _sound(e, "sink")
	var k := smoothstep(0.0, 0.25, u) * (1.0 - smoothstep(0.75, 1.0, u))
	var h: Node3D = e.node
	h.position = e.at + Vector3.UP * (-float(c.get("depth", 8.0)) * (1.0 - k))
	var sway := deg_to_rad(float(c.get("sway", 6.0)))
	h.rotation.x = sin(float(e.t) * 0.9) * sway * k
	h.rotation.z = sin(float(e.t) * 0.63 + 1.0) * sway * 0.6 * k
	_anim(e, "idle")

func _flash_step(e: Dictionary, flash: float) -> void:
	var h: Node3D = e.node
	h.visible = flash > 0.08
	if float(e.t) > 0.3 and flash < 0.03: _done(e)
	elif float(e.t) > 3.0: _done(e)

func _cross_step(e: Dictionary) -> void:
	var c: Dictionary = e.cfg
	var u := float(e.t) / float(c.get("dur", 14.0))
	if u >= 1.0:
		_done(e)
		return
	if u >= 0.4: _sound(e, "pass")
	var h: Node3D = e.node
	h.position = (e.from as Vector3).lerp(e.to, u) + Vector3.UP * sin(u * TAU * 1.5) * float(c.get("bob", 0.6))
	if e.has("shadow_node"):
		var sh: Node3D = e.shadow_node
		sh.position = Vector3(h.position.x, SHADOW_H, h.position.z) - (e.back as Vector3)
		sh.rotation = h.rotation
	_anim(e, "walk")

func _lights_step(e: Dictionary) -> void:
	var c: Dictionary = e.cfg
	var lamps: Array = e.lamps
	var y := float(c.get("y", 1.2))
	var t := float(e.t)
	if c.get("signal", false):                                        # señales desde el agua
		var dur := float(c.get("dur", 8.0))
		if t >= dur:
			_done(e)
			return
		for i in lamps.size():
			var l: MeshInstance3D = lamps[i]
			var on := fmod(t * 2.2 + i * 0.37, 1.6) < (0.5 if i % 2 == 0 else 0.9)   # largo y corto
			l.visible = on
			l.position = (e.at as Vector3) + Vector3((i - lamps.size() * 0.5) * 0.9, y + 0.25 * (i % 2), 0.0)
		return
	var path: Array = c.path
	var lengths: Array[float] = [0.0]
	for i in range(1, path.size()):
		lengths.append(lengths[i - 1] + Vector2(path[i][0], path[i][1]).distance_to(Vector2(path[i - 1][0], path[i - 1][1])))
	var total: float = lengths[-1]
	var spacing := float(c.get("spacing", 1.6))
	var head := float(e.get("s0", 0.0)) + t * float(c.get("speed", 1.1))
	if head - spacing * lamps.size() > total:
		_done(e)
		return
	for i in lamps.size():
		var l: MeshInstance3D = lamps[i]
		var s := head - i * spacing
		l.visible = s > 0.0 and s < total
		if not l.visible: continue
		var j := 1
		while j < path.size() - 1 and lengths[j] < s: j += 1
		var a: Array = path[j - 1]
		var b: Array = path[j]
		var k := (s - lengths[j - 1]) / maxf(lengths[j] - lengths[j - 1], 0.001)
		var xz := Vector2(a[0], a[1]).lerp(Vector2(b[0], b[1]), k)
		var flick := 0.04 * sin(t * 9.0 + i * 2.1)
		l.position = Vector3(xz.x, y + abs(sin(s * 2.4)) * 0.06 + flick, xz.y)   # al paso, y la llama tiembla

## Las esculturas que se giran cuando no se las mira (hacia el jugador más cercano, a menos de 14 m).
func _turn_step() -> void:
	var players: Array = game.players if game != null and "players" in game else []
	for s: Dictionary in _turners:
		var h: Node3D = s.h
		if not is_instance_valid(h): continue
		var top := h.global_position + Vector3.UP * 1.2
		if seen(top, -0.05):
			s.seen = true
			continue
		if not s.seen: continue                                        # ya se giró desde la última vez
		var best: Node3D = null
		var bd := 14.0
		for p in players:
			if not is_instance_valid(p): continue
			var d := (p as Node3D).global_position.distance_to(h.global_position)
			if d < bd:
				bd = d
				best = p
		if best == null: continue
		var to := best.global_position - h.global_position
		h.rotation.y = atan2(to.x, to.z) + float(s.get("face", 0.0))
		s.seen = false
		Auto.sfx_at("creak", h.global_position)                         # piedra que roza, a tu espalda
