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
##   model=dyer_chibi        otro modelo para el J1 (probar prototipos)
##   bots=3                  jugadores de compañía manejados por la máquina (J2..J4, hito 2.9)
##   bot_chars=olmstead,…    personajes de esos bots (por defecto, los de inicio y los demás)

const PLAYER_COLORS: Array[Color] = [Color(1.0, 0.82, 0.3), Color(0.35, 0.75, 1.0), Color(0.55, 1.0, 0.45), Color(1.0, 0.45, 0.8)]

var args: LaunchArgs
var arena: Node3D
var player: Player                            ## el J1 (lo usan la depuración y las opciones de prueba)
var players: Array[Player] = []               ## J1..J4 (hito 2.9)
var team: TeamXp                              ## experiencia compartida del cooperativo (D-07)
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
var _env: Environment
var weather: Weather

## Clima del nivel (D-33): `weather=<id>` lo cambia (capturas) y `weather=no` lo quita. La
## configuración decide si va completo, reducido o apagado; el menú de depuración, cuál.
func _start_weather() -> void:
	var wd: WeatherData = level.weather if level != null else null
	var pick := args.get_str("weather", String(DebugOptions.get_value("weather", "")))
	if pick == "no": wd = null
	elif pick != "": wd = load("res://data/weather/%s.tres" % pick)
	set_weather(wd)

func set_weather(wd: WeatherData) -> void:
	if weather != null:
		weather.queue_free()
		weather = null
	_env.fog_density = Atmosphere.make_environment().fog_density     # la de siempre
	_env.ambient_light_energy = Atmosphere.make_environment().ambient_light_energy
	var quality := int(Settings.get_value("weather"))
	if wd == null or quality == 0: return
	weather = Weather.new().setup(wd, camera, _env, 1.0 if quality >= 2 else 0.5)
	add_child(weather)

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
	# Jugadores: los de la selección de personaje (J1..J4) o, lanzando la partida directa, el
	# J1 de siempre más `bots=N` jugadores de compañía.
	if GameSession.is_set():
		for i in GameSession.seats.size():
			var seat: GameSession.Seat = GameSession.seats[i]
			var ch := String(seat.character)
			if i == 0: ch = args.get_str("character", String(DebugOptions.get_value("character", ch)))
			var inp := Devices.make_input(seat.device) if not (i == 0 and args.has("bot")) else _make_input()
			_spawn_player(ch, inp)
	else:
		_spawn_player(args.get_str("character", String(DebugOptions.get_value("character", "dyer"))), _make_input())
	var extra: PackedStringArray = args.get_str("bot_chars", "").split(",", false)
	var defaults := ["olmstead", "peaslee", "whipple", "legrasse", "johansen", "varga", "blake", "iwanicki", "elwood", "malone", "dyer"]
	for k in mini(args.get_int("bots", 0), 4 - players.size()):
		var ch: String = extra[k] if k < extra.size() else ""
		if ch == "":
			for d: String in defaults:
				if players.all(func(q: Player) -> bool: return String(q.data.id) != d):
					ch = d
					break
		var bot := BotInput.new("follow", 3.0 + k * 0.7)
		bot.phase = TAU * (k + 1) / 4.0
		bot.period = 7.0 + k * 1.5
		var bp := _spawn_player(ch, bot)
		bot.body = bp
		bot.leader = players[0]
	player = players[0]
	if players.size() > 1:                          # reglas del cooperativo (hito 2.10)
		var progs: Array[PlayerProgress] = []
		for q in players:
			progs.append(q.progress)
			q.revivable = true
		team = TeamXp.new(player.rules, progs)
		for q in players: q.sanity_state.coop = true    # la paranoia solo existe en cooperativo
	if args.has("model"): player.data.model = args.get_str("model")   # probar otro modelo (prototipos)
	var p := args.get_floats("pos")
	if p.size() == 2: player.position = Vector3(p[0], 0, p[1])
	if args.has("dodge"):
		var legacy := {"slide": "deslizar", "roll": "rodar"}
		var id: String = legacy.get(args.get_str("dodge"), args.get_str("dodge"))
		player.apply_dodge_style(load("res://data/dodges/%s.tres" % id))
	var wlist: PackedStringArray = args.get_str("weapons", "").split(",", false)
	if not wlist.is_empty():                        # armas de prueba para el J1
		for w in player.weapons.weapons.duplicate(): player.weapons.remove_weapon(w.data.id)
		for wid in wlist:
			var w := player.weapons.add_weapon(load("res://data/weapons/%s.tres" % wid))
			w.level = clampi(args.get_int("wlevel", 1), 1, w.data.max_level)
	elif args.has("wlevel"):
		for w in player.weapons.weapons: w.level = clampi(args.get_int("wlevel", 1), 1, w.data.max_level)
	camera = GameCamera.new()
	camera.view_size = args.get_float("cam", 15.0)
	for q in players: camera.targets.append(q)
	add_child(camera)
	if players.size() > 1:                          # correa: nadie se sale del encuadre máximo
		for q in players: q.leash = func(pos: Vector3) -> Vector3: return camera.leash(pos)
	_env = env
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
		director.players = players.size()           # la dificultad crece con los jugadores
		director.final_event.connect(func(_e: Enemy) -> void: announce(level.final_text, 3.5))
		director.level_completed.connect(_on_level_completed)
		director.enemy_spawned.connect(func(e: Enemy) -> void: e.died.connect(_on_enemy_died))
		add_child(director)
		announce(level.display_name, 3.0)
		Music.play(level.music_path())
	_start_weather()
	Engine.time_scale = args.get_float("timescale", 1.0)
	hud = Hud.new().setup(players, director)
	add_child(hud)
	add_child(SanityFx.new().setup(players))         # distorsiones de cordura baja
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

## Crea un jugador (J1..J4 según el orden) con su personaje, su entrada y sus armas iniciales.
func _spawn_player(character: String, input: PlayerInput) -> Player:
	var i := players.size()
	var q := Player.new().setup(load("res://data/characters/%s.tres" % character), input, PLAYER_COLORS[i])
	q.index = i
	var a := TAU * i / 4.0 + 0.6
	q.position = arena.get_meta("spawn") + (Vector3(cos(a), 0, sin(a)) * 1.8 if i > 0 else Vector3.ZERO)
	q.god = args.get_bool("god")
	q.world = world
	add_child(q)
	world.add_player(q)
	players.append(q)
	for w in DebugOptions.list_resources("res://data/weapons"): q.progress.weapon_pool.append(w)   # todas las armas
	for f in ["velocidad", "vida", "cordura", "reflejos", "iman"]:
		q.progress.upgrade_pool.append(load("res://data/upgrades/%s.tres" % f))
	q.progress.leveled_up.connect(func(_l: int) -> void:
		q.health = minf(q.health + q.data.max_health * q.data.heal_on_level, q.data.max_health)   # Whipple
		_open_level_up.call_deferred())
	q.downed.connect(_on_downed.bind(q))
	q.revived.connect(func() -> void: announce("J%d vuelve a la lucha" % (i + 1), 1.5))
	q.eliminated.connect(func() -> void:
		announce("J%d, eliminado hasta el siguiente nivel" % (i + 1), 2.0)
		_check_all_down())
	if args.get_bool("log"):
		q.damaged.connect(func(d: Damage) -> void:
			var src := "bala" if d.source == null else String((d.source as Enemy).data.id) + (" (carga)" if d.physical > 8.0 else "")
			print("  J%d golpe t=%.1f  -%d vida -%d cordura  de %s  -> vida %d" % [i + 1, director.time if director else 0.0, d.physical, d.mental, src, q.health]))
	q.sanity_state.crisis_started.connect(func(k: StringName) -> void:
		var what := "Crisis: %s" % SanityState.NAMES.get(k, "locura")
		announce(what if players.size() == 1 else "J%d · %s" % [i + 1, what], 1.5))
	q.lights.assign(arena.get_meta("lights"))       # las luces del escenario recuperan cordura
	q.madness = bool(Settings.get_value("madness"))
	q.weapons = WeaponSystem.new().setup(q, world)
	q.add_child(q.weapons)
	for wid in q.data.starting_weapons: q.weapons.add_weapon(load("res://data/weapons/%s.tres" % wid))
	return q

## ¿Lo maneja la máquina? (elige sola sus mejoras)
func _is_bot(q: Player) -> bool:
	return q.input is BotInput

# ---------------- flujo de la partida ----------------
func _on_enemy_died(e: Enemy) -> void:
	kills += 1
	if Saves.current != null: Saves.current.stats["kills"] += 1
	gems.drop(e.global_position, e.data.xp)

## Subida de nivel: pausa y elige una de tres mejoras (D-16). Si hay varias subidas
## pendientes, se encadenan.
## En solitario, el menú de siempre en el centro. En cooperativo (D-16), todos los que suben
## eligen a la vez, cada uno en su cuadrante (CoopLevelUp); los bots eligen solos.
func _open_level_up() -> void:
	if _menu_open or _ended or _pause != null: return
	if players.size() > 1:
		_open_coop_level_up()
		return
	var q: Player = null
	for c in players:
		if c.progress.pending > 0:
			q = c
			break
	if q == null: return
	var options := q.progress.roll_options(q.weapons, _rng)
	if options.is_empty():
		q.progress.pending = 0
		_open_level_up.call_deferred()
		return
	if args.get_bool("autopick") or _is_bot(q):
		q.progress.choose(options[0] if not _is_bot(q) else options[_rng.randi() % options.size()], q)
		_open_level_up.call_deferred()
		return
	_menu_open = true
	get_tree().paused = true
	var title := "Nivel %d" % (q.progress.level - q.progress.pending + 1)
	if players.size() > 1: title = "J%d · %s · %s" % [q.index + 1, q.data.display_name, title]
	if not q.progress.attr_gains.is_empty():                        # D-27: el atributo que ha subido
		title += "   ·   +1 %s" % Attributes.LONG[q.progress.attr_gains[0]]
	var menu := Menus.LevelUpMenu.new(options, title)
	menu.chosen.connect(func(o: PlayerProgress.Option) -> void:
		q.progress.choose(o, q)
		_menu_open = false
		get_tree().paused = false
		_open_level_up.call_deferred())
	add_child(menu)

func _open_coop_level_up() -> void:
	var entries: Array[Dictionary] = []
	for q in players:
		if q.progress.pending <= 0: continue
		var options := q.progress.roll_options(q.weapons, _rng)
		if options.is_empty():
			q.progress.pending = 0
			continue
		var title := "J%d · Nivel %d" % [q.index + 1, q.progress.level - q.progress.pending + 1]
		if not q.progress.attr_gains.is_empty():
			title += " · +1 %s" % Attributes.LONG[q.progress.attr_gains[0]]
		entries.append({"player": q, "options": options, "title": title})
	if entries.is_empty(): return
	if args.get_bool("autopick") or entries.all(func(e: Dictionary) -> bool: return _is_bot(e.player)):
		for e in entries: (e.player as Player).progress.choose(e.options[_rng.randi() % e.options.size()], e.player)
		_open_level_up.call_deferred()
		return
	_menu_open = true
	get_tree().paused = true
	var menu := CoopLevelUp.new(entries, func(q: Player, o: PlayerProgress.Option) -> void: q.progress.choose(o, q))
	menu.finished.connect(func() -> void:
		_menu_open = false
		get_tree().paused = false
		_open_level_up.call_deferred())                # quedan subidas (varios niveles de golpe)
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
	var lv := "Nivel alcanzado: %d" % player.progress.level
	if players.size() > 1:
		var parts := PackedStringArray()
		for q in players: parts.append("J%d %d" % [q.index + 1, q.progress.level])
		lv = "Niveles: " + "  ·  ".join(parts)
	return PackedStringArray(["Tiempo: %02d:%02d" % [t / 60, t % 60], "Enemigos abatidos: %d" % kills, lv])

## Cae un jugador. En cooperativo queda derribado y los demás pueden reanimarlo; la partida
## se acaba cuando no queda nadie en pie (derribados y eliminados no cuentan).
func _on_downed(q: Player) -> void:
	if _ended: return
	if players.size() > 1 and players.any(func(c: Player) -> bool: return c.health > 0.0):
		announce("J%d, derribado: ¡reanimadlo!" % (q.index + 1), 2.0)
		return
	_game_over()

func _check_all_down() -> void:
	if _ended or players.any(func(c: Player) -> bool: return c.health > 0.0): return
	_game_over()

func _game_over() -> void:
	if _ended: return
	_ended = true
	if Saves.current != null: Saves.current.stats["deaths"] += 1
	Saves.save()
	Engine.time_scale = 0.35                       # la caída, a cámara lenta un momento
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().paused = true
	_end_screen("Has caído" if players.size() == 1 else "Habéis caído", Color(0.86, 0.22, 0.18))

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
	if players.size() > 1:                           # la cámara encuadra a los que siguen en pie
		var alive: Array[Node3D] = []
		for q in players:
			if not q.is_eliminated: alive.append(q)        # los derribados también: hay que ir a por ellos
		if not alive.is_empty(): camera.targets = alive
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
