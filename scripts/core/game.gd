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
##   weapons=granada,webly   armas iniciales (por defecto, la del personaje)
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
##   dodge=rodar             estilo de esquive (data/dodges/); en partida, F1 los recorre todos
##   tag=nombre              sufijo de las capturas
##   autopick=true           elige sola la primera mejora al subir de nivel (bot, capturas)
##   xp=40                   experiencia inicial (probar el menú de mejoras)
##   hp=10 san=5             vida y cordura iniciales (probar la muerte y la crisis)
##   autorestart=2           en la pantalla final, reintenta sola tras N s (probar el reinicio)
##   mute=true               sin música (también en la portada)
##   debug_menu=1            abre la pausa y el menú de depuración a ese segundo (capturas)
##   character=johansen      personaje del J1 (dyer, olmstead, legrasse, johansen)

const PLAYER_COLORS: Array[Color] = [Color(1.0, 0.82, 0.3), Color(0.35, 0.75, 1.0), Color(0.55, 1.0, 0.45), Color(1.0, 0.45, 0.8)]

var args: LaunchArgs
var arena: Node3D
var player: Player
var camera: GameCamera
var world: CombatWorld
var level: LevelData
var director: WaveDirector
var announcer: Label
var gems: GemManager
var hud: Hud
var kills := 0
var _menu_open := false
var _ended := false
var _pause: Menus.PauseMenu
var _debug: DebugMenu
var _info: Label                               ## depuración: FPS, enemigos, balas
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	var t_start := Time.get_ticks_msec()
	args = LaunchArgs.from_cmdline()
	Prof.enabled = args.get_bool("prof")
	UiInput.configure()
	var env := Atmosphere.make_environment()
	# Los volúmenes de niebla solo existen en Forward+ (Compatibility da error)
	var fogvol := args.get_bool("fogvol", true) and RenderingServer.get_current_rendering_method() != "gl_compatibility"
	if fogvol:
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
	arena = ArenaBuilder.build("res://data/arenas/campamento.json", fogvol)
	add_child(arena)
	world = CombatWorld.new()
	var size: Vector2 = arena.get_meta("size")
	world.bounds = Rect2(-size * 0.5 - Vector2(6, 6), size + Vector2(12, 12))
	add_child(world)
	gems = GemManager.new()
	gems.world = world
	gems.rules = load("res://data/progression/default.tres")
	world.add_child(gems)
	# Jugador 1: el de la selección de personaje, o el de siempre si la partida se lanza directa
	var seat: GameSession.Seat = GameSession.seats[0] if GameSession.is_set() else null
	var character := String(seat.character) if seat else "dyer"
	character = args.get_str("character", String(DebugOptions.get_value("character", character)))
	var input := Devices.make_input(seat.device) if seat and not args.has("bot") else _make_input()
	player = Player.new().setup(load("res://data/characters/%s.tres" % character), input, PLAYER_COLORS[0])
	player.position = arena.get_meta("spawn")
	var p := args.get_floats("pos")
	if p.size() == 2: player.position = Vector3(p[0], 0, p[1])
	player.god = args.get_bool("god")
	if args.has("dodge"):
		var legacy := {"slide": "deslizar", "roll": "rodar"}
		var id: String = legacy.get(args.get_str("dodge"), args.get_str("dodge"))
		player.apply_dodge_style(load("res://data/dodges/%s.tres" % id))
	player.world = world
	add_child(player)
	world.add_player(player)
	for w in DebugOptions.list_resources("res://data/weapons"): player.progress.weapon_pool.append(w)   # todas las armas
	for f in ["velocidad", "vida", "cordura", "reflejos", "iman"]:
		player.progress.upgrade_pool.append(load("res://data/upgrades/%s.tres" % f))
	player.progress.leveled_up.connect(func(_l: int) -> void:
		player.health = minf(player.health + player.data.max_health * player.data.heal_on_level, player.data.max_health)   # Whipple
		_open_level_up.call_deferred())
	player.downed.connect(_on_downed)
	if args.get_bool("log"):
		player.damaged.connect(func(d: Damage) -> void:
			var src := "bala" if d.source == null else String((d.source as Enemy).data.id) + (" (carga)" if d.physical > 8.0 else "")
			print("  golpe t=%.1f  -%d vida -%d cordura  de %s  -> vida %d" % [director.time if director else 0.0, d.physical, d.mental, src, player.health]))
	player.sanity_state.crisis_started.connect(func(_k: StringName) -> void: announce("Crisis de locura", 1.5))
	player.weapons = WeaponSystem.new().setup(player, world)
	player.add_child(player.weapons)
	var start := PackedStringArray()
	for wid in player.data.starting_weapons: start.append(String(wid))
	var wlist: PackedStringArray = args.get_str("weapons", ",".join(start)).split(",", false)
	for wid in wlist:
		var w := player.weapons.add_weapon(load("res://data/weapons/%s.tres" % wid))
		w.level = clampi(args.get_int("wlevel", 1), 1, w.data.max_level)
	camera = GameCamera.new()
	camera.view_size = args.get_float("cam", 15.0)
	camera.targets.append(player)
	add_child(camera)
	_make_announcer()
	if not args.get_bool("nolevel"):
		var level_id := args.get_str("level", String(GameSession.level) if GameSession.is_set() else "p1_n1")
		level = load("res://data/levels/%s.tres" % level_id).duplicate()
		if args.has("final_at"): level.final_time = args.get_float("final_at")
		if args.has("spawn_rate"): level.spawn_rate = [Vector2(0, args.get_float("spawn_rate"))] as Array[Vector2]
		# Construir ya los modelos de todos los enemigos del nivel: si no, la primera aparición
		# de cada uno (el Acechador, en el minuto 4) provocaría un tirón a mitad de partida.
		for ed: EnemyData in level.pool + ([level.final_enemy] if level.final_enemy else []):
			VoxelBuilder.load_model("res://models/%s.json" % ed.model).free()
		var enemies_root := Node3D.new()
		enemies_root.name = "Enemies"
		add_child(enemies_root)
		director = WaveDirector.new().setup(level, world, arena.get_meta("obstacles"), camera, enemies_root)
		if args.has("max_alive"): director.max_alive_override = args.get_int("max_alive")
		director.final_event.connect(func(_e: Enemy) -> void: announce(level.final_text, 3.5))
		director.level_completed.connect(_on_level_completed)
		director.enemy_spawned.connect(func(e: Enemy) -> void: e.died.connect(_on_enemy_died))
		add_child(director)
		announce(level.display_name, 3.0)
		Music.play(level.music_path())
	Engine.time_scale = args.get_float("timescale", 1.0)
	hud = Hud.new().setup(player, director)
	add_child(hud)
	var pause_watch := Node.new()                  # sigue atento a Esc/Start con la partida en pausa
	pause_watch.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_watch.set_script(preload("res://scripts/ui/pause_watch.gd"))
	pause_watch.set("game", self)
	add_child(pause_watch)
	if args.get_bool("log") or args.get_bool("loadtime"):
		print("CARGA de la partida: %d ms (desde el arranque del motor: %d ms)" % [Time.get_ticks_msec() - t_start, Time.get_ticks_msec()])
	if args.get_bool("loadtime"): get_tree().quit()
	if args.get_float("xp") > 0.0: player.progress.add_xp(args.get_float("xp"))
	if args.get_bool("gem_test"):                  # gemas quietas alrededor, sin recogida (verlas de cerca)
		player.data.pickup_radius = 0.0
		for i in 8:
			var a := TAU * i / 8.0
			gems.drop(player.position + Vector3(cos(a), 0, sin(a)) * 1.3, 1.0 + i * 3.0)
	if args.has("hp"): player.health = args.get_float("hp")
	if args.has("san"): player.sanity = args.get_float("san")
	DebugOptions.apply_all(self)
	if Saves.current != null: Saves.current.stats["runs"] += 1
	if args.get_int("demo") > 0: _demo_crowd(args.get_int("demo"))
	if args.get_int("dummies") > 0: _dummies(args.get_int("dummies"))
	if args.get_bool("emitters"): _emitters()
	if args.has("debug_menu"):                     # abre la pausa y la depuración (capturas)
		get_tree().create_timer(args.get_float("debug_menu", 1.0)).timeout.connect(func() -> void:
			toggle_pause()
			_open_debug())
	if args.has("shots"):
		var tag := ("_" + args.get_str("tag")) if args.has("tag") else ""
		add_child(ShotTaker.new(args.get_floats("shots"), "res://shots/game%s" % tag))

# ---------------- flujo de la partida ----------------
func _on_enemy_died(e: Enemy) -> void:
	kills += 1
	if Saves.current != null: Saves.current.stats["kills"] += 1
	gems.drop(e.global_position, e.data.xp)

## Subida de nivel: pausa y elige una de tres mejoras (D-16). Si hay varias subidas
## pendientes, se encadenan.
func _open_level_up() -> void:
	if _menu_open or _ended or _pause != null or player.progress.pending <= 0: return
	var options := player.progress.roll_options(player.weapons, _rng)
	if options.is_empty():
		player.progress.pending = 0
		return
	if args.get_bool("autopick"):
		player.progress.choose(options[0], player)
		_open_level_up.call_deferred()
		return
	_menu_open = true
	get_tree().paused = true
	var title := "Nivel %d" % (player.progress.level - player.progress.pending + 1)
	if not player.progress.attr_gains.is_empty():                  # D-27: el atributo que ha subido
		title += "   ·   +1 %s" % Attributes.LONG[player.progress.attr_gains[0]]
	var menu := Menus.LevelUpMenu.new(options, title)
	menu.chosen.connect(func(o: PlayerProgress.Option) -> void:
		player.progress.choose(o, player)
		_menu_open = false
		get_tree().paused = false
		_open_level_up.call_deferred())
	add_child(menu)

func toggle_pause() -> void:
	if _menu_open or _ended: return
	if _debug != null: return                     # el menú de depuración atiende Esc y Start
	if _pause != null:
		_pause.queue_free()
		_pause = null
		get_tree().paused = false
		if DebugOptions.values.has("time_scale"): Engine.time_scale = DebugOptions.values["time_scale"]
		_open_level_up.call_deferred()             # subidas pendientes (p. ej. de la depuración)
		return
	_pause = Menus.PauseMenu.new()
	_pause.resume.connect(toggle_pause)
	_pause.restart.connect(_restart)
	_pause.debug.connect(_open_debug)
	_pause.quit.connect(_quit)
	add_child(_pause)
	get_tree().paused = true

## Menú de depuración, encima de la pausa (que se oculta mientras tanto).
func _open_debug() -> void:
	if _debug != null: return
	_debug = DebugMenu.new(self)
	_pause.visible = false
	_debug.back.connect(func() -> void:
		_debug.queue_free()
		_debug = null
		_pause.show_again())
	_debug.close.connect(func() -> void:
		_debug.queue_free()
		_debug = null
		toggle_pause())
	_debug.restart.connect(_restart)
	add_child(_debug)

## "Menú principal" (pausa y pantalla final): guarda y vuelve al menú de la portada. Sin
## hueco elegido (partida lanzada directamente), sale del juego.
func _quit() -> void:
	Saves.save()
	get_tree().paused = false
	Engine.time_scale = 1.0
	if Saves.slot < 0:
		get_tree().quit()
		return
	TitleScreen.skip_to_menu = true
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _summary() -> PackedStringArray:
	var t := int(director.time) if director != null else 0
	return PackedStringArray(["Tiempo: %02d:%02d" % [t / 60, t % 60], "Enemigos abatidos: %d" % kills,
		"Nivel alcanzado: %d" % player.progress.level])

func _on_downed() -> void:
	if _ended: return
	_ended = true
	if Saves.current != null: Saves.current.stats["deaths"] += 1
	Saves.save()
	Engine.time_scale = 0.35                       # la caída, a cámara lenta un momento
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().paused = true
	_end_screen("Has caído", Color(0.86, 0.22, 0.18))

func _on_level_completed() -> void:
	if _ended: return
	_ended = true
	if Saves.current != null and not Saves.current.levels_won.has(String(level.id)):
		Saves.current.levels_won.append(String(level.id))
	Saves.save()
	announce("Nivel superado", 2.0)
	await get_tree().create_timer(2.5).timeout
	get_tree().paused = true
	_end_screen("Nivel superado", UiKit.GOLD)

func _end_screen(title: String, accent: Color) -> void:
	var s := Menus.EndScreen.new(title, _summary(), accent)
	s.restart.connect(_restart)
	s.quit.connect(_quit)
	add_child(s)
	if args.has("autorestart"):
		print("fin de partida: ", title)
		await get_tree().create_timer(args.get_float("autorestart"), true, false, true).timeout
		_restart()

func _restart() -> void:
	print("reinicio")
	Saves.save()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

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
	var bindings := Settings.bindings()             # los de fábrica más los reasignados
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
	# tiempo jugado del hueco: en tiempo real, sin contar pausas ni la velocidad del juego
	if not get_tree().paused and not _ended: Saves.add_play_time(delta / maxf(Engine.time_scale, 0.001))
	if args.get_bool("debug") and fmod(_t, 0.5) < delta: print("t=%.1f jugador=%s" % [_t, player.global_position])
	if args.get_bool("log") and director != null and fmod(director.time, 30.0) < delta:
		print("t=%3d s  vivos=%d  abatidos=%d  nivel=%d  vida=%d  cordura=%d  balas=%d" % [director.time, director.alive.size(),
			kills, player.progress.level, player.health, player.sanity, world.bullets.count])
	if args.has("perf"): _perf(delta)
	if args.get_bool("jitter"): _jitter(delta)
	if args.get_int("bullet_rain") > 0: _bullet_rain(args.get_int("bullet_rain"))
	_update_info()
	for i in _demo.size():
		var kind := _demo_names[i]
		var anim := "idle" if kind == "acechador" else "walk"
		Anims.pose(kind, anim, _demo[i], fposmod(_t / Anims.duration(kind, anim) + float(_demo[i].get_meta("phase")), 1.0))

## Depuración: FPS, enemigos vivos, balas y tiempo, arriba a la derecha.
func _update_info() -> void:
	var on: bool = DebugOptions.get_value("info", false)
	if not on:
		if _info: _info.visible = false
		return
	if _info == null:
		var layer := CanvasLayer.new()
		layer.layer = 15
		add_child(layer)
		_info = UiKit.label("", 16, UiKit.XP)
		_info.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_info.offset_left = -330
		_info.offset_right = -16
		_info.offset_top = 110
		_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		layer.add_child(_info)
	_info.visible = true
	_info.text = "%d FPS
enemigos %d
balas %d
velocidad x%s
t %.0f s" % [Engine.get_frames_per_second(),
		world.enemies.size(), world.bullets.count, String.num(Engine.time_scale, 2), director.time if director else _t]

var _frames: Array[float] = []
var _phys_ms := 0.0
var _proc_ms := 0.0
var _peak_enemies := 0
var _peak_bullets := 0

## Medición sencilla de tiempos de fotograma (para docs/RENDIMIENTO.md).
func _perf(delta: float) -> void:
	if _t < 2.0:
		Prof.totals.clear()
		return
	_frames.append(delta * 1000.0)
	_phys_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_proc_ms += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_peak_enemies = maxi(_peak_enemies, world.enemies.size())
	_peak_bullets = maxi(_peak_bullets, world.bullets.count)
	if _t < 2.0 + args.get_float("perf", 10.0): return
	_frames.sort()
	var avg := 0.0
	for f in _frames: avg += f
	avg /= _frames.size()
	var p99 := _frames[int(_frames.size() * 0.99)]
	var n := float(_frames.size())
	print("RENDIMIENTO fotogramas=%d media=%.2f ms (%.0f FPS) 1%% peor=%.2f ms (%.0f FPS) física=%.2f ms proceso=%.2f ms enemigos=%d balas=%d draw calls=%d primitivas=%d" % [
		_frames.size(), avg, 1000.0 / avg, p99, 1000.0 / p99, _phys_ms / n, _proc_ms / n, _peak_enemies, _peak_bullets,
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)])
	if Prof.enabled: print("PERFIL (ms por fotograma) ", Prof.report(_frames.size()))
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

## Suavidad del movimiento en pantalla: con velocidad constante, el desplazamiento del
## personaje en píxeles por segundo debería ser igual en todos los fotogramas. Mide la
## variación (desviación típica / media) entre 1 y 4 s y sale. Con judder (física a
## 60 Hz en un monitor de 120 Hz) sale cerca de 1; con movimiento suave, cerca de 0.
var _jit_prev := Vector2.INF
var _jit_rates: Array[float] = []

func _jitter(delta: float) -> void:
	var target: Node3D = player
	var sp := camera.unproject_position(target.get_global_transform_interpolated().origin) 		if camera.is_inside_tree() else Vector2.ZERO
	# posición en pantalla relativa al mundo: se suma el desplazamiento de la cámara
	var world_px := sp - camera.unproject_position(Vector3.ZERO)
	if _t > 1.0 and _jit_prev != Vector2.INF:
		_jit_rates.append((world_px - _jit_prev).length() / delta)
	_jit_prev = world_px
	if _t > 4.0:
		var m := 0.0
		for r in _jit_rates: m += r
		m /= _jit_rates.size()
		var v := 0.0
		for r in _jit_rates: v += (r - m) * (r - m)
		var sd := sqrt(v / _jit_rates.size())
		# y también el movimiento aparente respecto a la cámara (lo que ve el ojo)
		print("JITTER fotogramas=%d  px/s medio=%.0f  variación=%.2f  fps=%.0f" % [_jit_rates.size(), m, sd / m, Engine.get_frames_per_second()])
		get_tree().quit()

## F1: recorre los estilos de esquive para compararlos.
const DODGE_STYLES: Array[String] = ["deslizar", "rodar", "plancha", "salto", "destello"]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F1:
		var cur := String(player.data.dodge_style.id) if player.data.dodge_style else "deslizar"
		var next := DODGE_STYLES[(DODGE_STYLES.find(cur) + 1) % DODGE_STYLES.size()]
		var style: DodgeStyle = load("res://data/dodges/%s.tres" % next)
		player.apply_dodge_style(style)
		announce("Esquive: " + style.display_name, 1.2)
		get_viewport().set_input_as_handled()
