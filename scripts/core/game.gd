extends Node3D
## Partida (fase 1): arena del campamento, Dyer con su entrada y la cámara.
## Opciones de depuración (detrás de `--`):
##   bot=circle|zigzag|idle  jugador automático; dodge_every=2.5 (s entre esquives)
##   shots=1,3,5             capturas en esos segundos (shots/game_*.png) y salir
##   cam=15                  altura visible de la cámara en metros
##   perf=10                 mide el rendimiento durante N s (tras 2 s de calentamiento) y sale
##   demo=12                 criaturas de muestra quietas alrededor (legibilidad)
##   dummies=10              criaturas de práctica que reciben daño (probar armas)
##   emitters=true           tres emisores de prueba: patrón físico, mental y mixto
##   weapons=dinamita,revolver   armas iniciales (por defecto, la del personaje)
##   wlevel=3                nivel inicial de esas armas
##   god=true                el jugador no recibe daño
##   bullet_rain=1000        mantiene N balas enemigas vivas alrededor (prueba de carga)
##   level=p1_n1             nivel a jugar (por defecto); nolevel=true: campo de pruebas sin oleadas
##   timescale=4             acelera el tiempo de juego (verificar el evento final)
##   final_at=20             adelanta el evento final a ese segundo
##   max_alive=150           cambia el tope de enemigos vivos
##   spawn_rate=20           ritmo de aparición fijo (enemigos por segundo)
##   fogvol=false            sin los halos de niebla de los faroles
##   pos=x,z                 posición inicial del jugador
##   tag=nombre              sufijo de las capturas

const PLAYER_COLORS: Array[Color] = [Color(1.0, 0.82, 0.3), Color(0.35, 0.75, 1.0), Color(0.55, 1.0, 0.45), Color(1.0, 0.45, 0.8)]

var args: LaunchArgs
var arena: Node3D
var player: Player
var camera: GameCamera
var world: CombatWorld
var level: LevelData
var director: WaveDirector
var announcer: Label

func _ready() -> void:
	args = LaunchArgs.from_cmdline()
	var env := Atmosphere.make_environment()
	if args.get_bool("fogvol", true):
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0      # solo los volúmenes locales
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var moon := DirectionalLight3D.new()
	moon.name = "Moon"
	moon.rotation_degrees = Vector3(-55, 20, 0)
	moon.light_color = Color(0.6, 0.72, 0.85)
	moon.light_energy = 0.55
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)
	arena = ArenaBuilder.build("res://data/arenas/campamento.json", args.get_bool("fogvol", true))
	add_child(arena)
	world = CombatWorld.new()
	var size: Vector2 = arena.get_meta("size")
	world.bounds = Rect2(-size * 0.5 - Vector2(6, 6), size + Vector2(12, 12))
	add_child(world)
	player = Player.new().setup(load("res://data/characters/dyer.tres"), _make_input(), PLAYER_COLORS[0])
	player.position = arena.get_meta("spawn")
	var p := args.get_floats("pos")
	if p.size() == 2: player.position = Vector3(p[0], 0, p[1])
	player.god = args.get_bool("god")
	add_child(player)
	world.add_player(player)
	player.weapons = WeaponSystem.new().setup(player, world)
	player.add_child(player.weapons)
	var wlist := args.get_str("weapons", String(player.data.starting_weapon)).split(",", false)
	for wid in wlist:
		var w := player.weapons.add_weapon(load("res://data/weapons/%s.tres" % wid))
		w.level = clampi(args.get_int("wlevel", 1), 1, w.data.max_level)
	camera = GameCamera.new()
	camera.view_size = args.get_float("cam", 15.0)
	camera.targets.append(player)
	add_child(camera)
	_make_announcer()
	if not args.get_bool("nolevel"):
		level = load("res://data/levels/%s.tres" % args.get_str("level", "p1_n1")).duplicate()
		if args.has("final_at"): level.final_time = args.get_float("final_at")
		if args.has("spawn_rate"): level.spawn_rate = [Vector2(0, args.get_float("spawn_rate"))] as Array[Vector2]
		var enemies_root := Node3D.new()
		enemies_root.name = "Enemies"
		add_child(enemies_root)
		director = WaveDirector.new().setup(level, world, arena.get_meta("obstacles"), camera, enemies_root)
		if args.has("max_alive"): director.max_alive_override = args.get_int("max_alive")
		director.final_event.connect(func(_e: Enemy) -> void: announce(level.final_text, 3.5))
		director.level_completed.connect(func() -> void: announce("Nivel superado", 6.0))
		add_child(director)
		announce(level.display_name, 3.0)
	Engine.time_scale = args.get_float("timescale", 1.0)
	if args.get_int("demo") > 0: _demo_crowd(args.get_int("demo"))
	if args.get_int("dummies") > 0: _dummies(args.get_int("dummies"))
	if args.get_bool("emitters"): _emitters()
	if args.has("shots"):
		var tag := ("_" + args.get_str("tag")) if args.has("tag") else ""
		add_child(ShotTaker.new(args.get_floats("shots"), "res://shots/game%s" % tag))

## Rótulo central provisional (el HUD completo llega en el hito 1.6).
func _make_announcer() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	announcer = Label.new()
	announcer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	announcer.position.y = 140
	announcer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcer.add_theme_font_size_override("font_size", 38)
	announcer.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	announcer.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03))
	announcer.add_theme_constant_override("outline_size", 10)
	announcer.modulate.a = 0.0
	layer.add_child(announcer)

func announce(text: String, seconds: float) -> void:
	announcer.text = text
	announcer.size.x = 0
	announcer.position.x = (get_viewport().get_visible_rect().size.x - announcer.get_minimum_size().x) * 0.5
	var tw := create_tween()
	tw.tween_property(announcer, "modulate:a", 1.0, 0.4)
	tw.tween_interval(seconds)
	tw.tween_property(announcer, "modulate:a", 0.0, 0.8)

func _make_input() -> PlayerInput:
	if args.has("bot"):
		return BotInput.new(args.get_str("bot", "circle"), args.get_float("dodge_every", 2.5))
	var bindings: InputBindings = load("res://data/input/bindings_default.tres")
	var sources: Array[PlayerInput] = [KeyboardInput.new(bindings), JoypadInput.new(0, bindings)]
	return CombinedInput.new(sources)

## Criaturas de práctica que reciben daño, en corro alrededor del jugador.
func _dummies(n: int) -> void:
	var rng := RandomNumberGenerator.new(); rng.seed = 11
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(5.0, 9.0)
		var d := TrainingDummy.new().setup(world, "pinguino" if i % 2 == 0 else "fragmento")
		d.position = player.position + Vector3(cos(a) * r, 0, sin(a) * r)
		d.rotation.y = atan2(-cos(a), -sin(a))
		add_child(d)

## Tres emisores de prueba, uno por tipo de daño, a unos 8 m del jugador.
func _emitters() -> void:
	var defs := [["pinguino", "prueba_radial_fisico", -45.0], ["acechador", "prueba_abanico_mental", 75.0],
		["fragmento", "prueba_espiral_mixto", 195.0]]
	for d: Array in defs:
		var a := deg_to_rad(d[2])
		var e := TestEmitter.new().setup(world, d[0], load("res://data/patterns/%s.tres" % d[1]), 3.2)
		e.position = player.position + Vector3(cos(a), 0, sin(a)) * 8.0
		add_child(e)

## Criaturas de muestra, quietas y animadas, para juzgar la legibilidad con el zoom real.
var _demo: Array[Node3D] = []
var _demo_names: Array[String] = []
var _t := 0.0

func _demo_crowd(n: int) -> void:
	var kinds := ["pinguino", "fragmento", "pinguino", "fragmento", "acechador"]
	var rng := RandomNumberGenerator.new(); rng.seed = 7
	for i in n:
		var kind: String = kinds[i % kinds.size()]
		var a := TAU * i / n + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(4.0, 8.0)
		var holder := Node3D.new()
		holder.position = player.position + Vector3(cos(a) * r, 0, sin(a) * r)
		holder.rotation.y = atan2(-cos(a), -sin(a))       # mirando al jugador
		var m := VoxelBuilder.load_model("res://models/%s.json" % kind)
		m.set_meta("phase", rng.randf())
		holder.add_child(m)
		add_child(holder)
		_demo.append(m)
		_demo_names.append(kind)

func _process(delta: float) -> void:
	_t += delta
	if args.get_bool("debug") and fmod(_t, 0.5) < delta: print("t=%.1f jugador=%s" % [_t, player.global_position])
	if args.has("perf"): _perf(delta)
	if args.get_int("bullet_rain") > 0: _bullet_rain(args.get_int("bullet_rain"))
	for i in _demo.size():
		var kind := _demo_names[i]
		var anim := "idle" if kind == "acechador" else "walk"
		Anims.pose(kind, anim, _demo[i], fposmod(_t / Anims.duration(kind, anim) + float(_demo[i].get_meta("phase")), 1.0))

var _frames: Array[float] = []

## Medición sencilla de tiempos de fotograma (para docs/RENDIMIENTO.md).
func _perf(delta: float) -> void:
	if _t < 2.0: return
	_frames.append(delta * 1000.0)
	if _t < 2.0 + args.get_float("perf", 10.0): return
	_frames.sort()
	var avg := 0.0
	for f in _frames: avg += f
	avg /= _frames.size()
	var p99 := _frames[int(_frames.size() * 0.99)]
	print("RENDIMIENTO fotogramas=%d media=%.2f ms (%.0f FPS) 1%% peor=%.2f ms (%.0f FPS) draw calls=%d primitivas=%d" % [
		_frames.size(), avg, 1000.0 / avg, p99, 1000.0 / p99,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	get_tree().quit()

## Lluvia de balas para la prueba de carga: repone balas de los tres tipos alrededor
## del jugador hasta tener `n` vivas.
func _bullet_rain(n: int) -> void:
	var styles := [BulletManager.Style.PHYSICAL, BulletManager.Style.MENTAL, BulletManager.Style.MIXED]
	var dmg := [Damage.new(5, 0), Damage.new(0, 5), Damage.new(3, 3)]
	var enemy_count := world.bullets.count
	var k := 0
	while enemy_count < n and k < 200:
		var a := randf() * TAU
		var from := player.position + Vector3(cos(a), 0, sin(a)) * randf_range(9.0, 14.0)
		var to := player.position + Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
		var s := k % 3
		world.bullets.spawn(BulletManager.Team.ENEMY, styles[s], from, (to - from).normalized() * randf_range(3.0, 6.0),
			0.13, 0.26, dmg[s], 6.0)
		enemy_count += 1
		k += 1
