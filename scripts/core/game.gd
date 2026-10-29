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
##   face=cerrados|dolor     deja la cara de los jugadores así (FaceLook; capturas)
##   bullet_rain=1000        mantiene N balas enemigas vivas alrededor (prueba de carga)
##   level=p1_n1             nivel a jugar (por defecto); nolevel=true: campo de pruebas sin oleadas
##   timescale=4             acelera el tiempo de juego (verificar el evento final)
##   final_at=20             adelanta el evento final a ese segundo
##   boss=true               el jefe que sale tras el evento final (Dagon) es el evento final
##   chain=true              con autonext y autorestart: la parte entera seguida; al caer, vuelve al nivel de level=
##   shop=N                  N niveles comprados en cada potenciador de la tienda (pruebas de equilibrio)
##   mid_at=10               adelanta el primer evento intermedio a ese segundo (y los demás en proporción)
##   max_alive=150           cambia el tope de enemigos vivos
##   spawn_rate=20           ritmo de aparición fijo (enemigos por segundo)
##   fogvol=false            sin los halos de niebla de los faroles
##   pos=x,z                 posición inicial del jugador
##   dodge=rodar             estilo de esquive (data/dodges/); en partida, F1 los recorre todos
##   tag=nombre              sufijo de las capturas
##   autopick=true           elige sola la primera mejora al subir de nivel (bot, capturas)
##   xp=40                   experiencia inicial (probar el menú de mejoras)
##   hp=10 san=5             vida y cordura iniciales (probar la muerte y la crisis)
##   sim_time=N, nolevelup=true  banco de armas: sin subidas de nivel y sale a los N s con las estadísticas
##   quit_on_end=true        sale al caer o al acabar la parte (con autonext): simulaciones
##   autorestart=2           en la pantalla final, reintenta sola tras N s (probar el reinicio)
##   mute=true               sin música (también en la portada)
##   debug_menu=1            abre la pausa y el menú de depuración a ese segundo (capturas)
##   sheet_at=2 / map_at=2   abre la ficha o el mapa del J1 a ese segundo (capturas)
##   hitstop=false           sin micro-pausa al impactar
##   boss_intro=false        sin la entrada de los jefes (BossIntro): solo el aviso, como antes
##   crumble=false / marks=N  sin desmoronarse / tope de manchas en el suelo (0, ninguna; por defecto, el de la calidad gráfica)
##   falls=false             sin la caída de cada familia al morir (hito 12.7)
##   dirt=false|0.8          sin la ropa que se ensucia, o fija a ese nivel (hito 12.4)
##   wounds=false|0.7        sin las grietas de herida de élites, únicos y grandes, o fijas a ese nivel (hito 12.6)
##   demo_kill=t             mata a la vez a todos los enemigos a ese segundo (capturas de las muertes)
##   character=johansen      personaje del J1 (dyer, olmstead, legrasse, johansen)
##   model=dyer_chibi        otro modelo para el J1 (probar prototipos)
##   bots=3                  jugadores de compañía manejados por la máquina (J2..J4, hito 2.9)
##   bot_chars=olmstead,…    personajes de esos bots (por defecto, los de inicio y los demás)
##   chest_every=5           un baúl arcano cada tantos segundos (por defecto, el del nivel)
##   pet=perro|gato          compañero del J1
##   pets=gato,perro         un compañero por jugador, en orden (con bots=N; reacciones, hito 12.9)
##   blast=x,z,t;…           explosiones en esos puntos a esos s (faroles, velas, hollín y nieve, hito 12.11)
##   crate=x,z,t;…           un rompible en ese punto que se rompe a esos s (astillas, hito 12.11)
##   panel=sheet|map         abre la ficha o el mapa (panel_player=N, panel_page=N, panel_at=s)

const PLAYER_COLORS: Array[Color] = [Color(1.0, 0.82, 0.3), Color(0.35, 0.75, 1.0), Color(0.55, 1.0, 0.45), Color(1.0, 0.45, 0.8)]

var args: LaunchArgs
var arena: Node3D
var player: Player                            ## el J1 (lo usan la depuración y las opciones de prueba)
var players: Array[Player] = []               ## J1..J4 (hito 2.9)
var team: TeamXp                              ## experiencia compartida del cooperativo (D-07)
var menus: PlayerMenus                        ## ficha y mapa de cada jugador (hito 2.12)
var run_money := 0                            ## dólares ganados en esta partida (D-31)
var _someone_fell := false                    ## alguien ha caído en este nivel (logro "Sin un rasguño")
var _downs := {}                              ## índice del jugador -> veces derribado o caído en el nivel (simulaciones)
var _ach_t := 0.0
## Informe al caer (hito 13.1, `FallReport`): cada segundo del director, vida y cordura de los
## jugadores de este PC (índice -> PackedVector2Array) y los vivos; las caídas de cada uno.
var _rep_slot := -1
var _rep_hist := {}
var _rep_alive := PackedInt32Array()
var _rep_falls := {}
var money_mult := 1.0                         ## Codicia (tienda)
var shop_bonus := {}                          ## lo comprado en la tienda (Shop.bonuses)
var camera: GameCamera
var _boss_intro := true                          ## entrada de los jefes (BossIntro; boss_intro=false la quita)
var world: CombatWorld
var level: LevelData
var director: WaveDirector
var announcer: Label
var gems: GemManager
var hud: Hud
var kills := 0
var _menu_open := false
var _ended := false
var _final_alive := 0.0                          ## segundos que lleva vivo el enemigo final (registro)
var _log_slot := 0                                ## último tramo de 30 s escrito en el registro
var _pause: Menus.PauseMenu
var _shot_tag := ""                            ## sufijo de las capturas (tag=, y _inv en un invitado)
var _halt_ui: CanvasLayer                      ## en red: aviso de la parada que ha puesto otro PC
var _debug: CanvasLayer                         ## la depuración o la dificultad, encima de la pausa
var _info: Label                               ## depuración: FPS, enemigos, balas
var _rng := RandomNumberGenerator.new()
var _env: Environment
var weather: Weather
var net_game: NetGame                          ## partida en red (hito 9.3a); null en local
var hazards: Hazards                           ## peligros del escenario (si el nivel tiene)
var _base_fog := Atmosphere.make_environment().fog_density
var _base_ambient := Atmosphere.make_environment().ambient_light_energy

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
	# la de la arena (su luz propia) o, sin ella, la de siempre
	_env.fog_density = _base_fog
	_env.ambient_light_energy = _base_ambient
	var quality := int(Settings.get_value("weather"))
	if wd == null or quality == 0: return
	weather = Weather.new().setup(wd, camera, _env, 1.0 if quality >= 2 else 0.5)
	add_child(weather)

func _ready() -> void:
	var t_start := Time.get_ticks_msec()
	args = LaunchArgs.from_cmdline()
	Difficulty.net = null                          # en red, el invitado recibe la del anfitrión (NetGame)
	Difficulty.refresh()
	Prof.enabled = args.get_bool("prof")
	UiInput.configure()
	OutfitData.override = {}                       # outfit=bombin,botas_nieve: prendas para probar
	for o_id in args.get_str("outfit").split(",", false):
		var o := OutfitData.find(o_id)
		if o != null: OutfitData.override[OutfitData.KEYS[o.slot]] = o_id
	var env := Atmosphere.make_environment()
	# Los volúmenes de niebla solo existen en Forward+ (Compatibility da error)
	var fogvol := args.get_bool("fogvol", bool(Quality.value("fogvol", true))) and RenderingServer.get_current_rendering_method() != "gl_compatibility"
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
	# arena del nivel (LevelData.arena); arena=ruta para probar otra
	var arena_path := "res://data/arenas/campamento.json"
	var part_key := "p1"                           # gradación de color de la parte (hito 11.3)
	if not args.get_bool("nolevel"):
		var lid := (String(GameSession.level) if not GameSession.carry.is_empty() else args.get_str("level", String(GameSession.level) if GameSession.is_set() else "p1_n1"))
		part_key = lid.get_slice("_", 0)
		var ld: LevelData = load("res://data/levels/%s.tres" % lid)
		if ld != null: arena_path = ld.arena
	Enemy.part_tint = Enemy.PART_TINTS.get(part_key, Color(0.45, 0.2, 0.7))   # auras de las élites (hito 12.6)
	Hud.frost = 0.85 if part_key == "p1" else 0.0                     # retratos con escarcha en la Antártida (hito 12.14)
	# ropa que se ensucia (hito 12.4; dirt=false la quita, dirt=0.8 la deja fija para capturas)
	Player.dirt_cfg = {} if args.get_str("dirt", "") == "false" else Player.dirt_config(part_key, arena_path.get_file().get_basename())
	Player.dirt_force = args.get_float("dirt", -1.0) if args.get_str("dirt", "").is_valid_float() else -1.0
	arena_path = args.get_str("arena", arena_path)
	arena = ArenaBuilder.build(arena_path, fogvol)
	add_child(arena)
	ArenaBuilder.apply_light(arena.get_meta("light", {}), moon, env)
	# sombras levantadas: la de la arena ("gamma", noches legibles) por el brillo de la configuración
	# y la gradación de color de la parte (hito 11.3; grade=off|p1|p2|p3 para comparar)
	var grade_key := args.get_str("grade", part_key)
	Atmosphere.set_grade(env, float(arena.get_meta("light", {}).get("gamma", 1.0)) * Settings.brightness_gamma(),
		{} if grade_key == "off" else Atmosphere.grade_for(grade_key))
	_base_fog = env.fog_density
	_base_ambient = env.ambient_light_energy
	world = CombatWorld.new()
	var size: Vector2 = arena.get_meta("size")
	world.bounds = Rect2(-size * 0.5 - Vector2(6, 6), size + Vector2(12, 12))
	world.obstacles = arena.get_meta("obstacles")
	add_child(world)
	gems = GemManager.new()
	gems.world = world
	gems.rules = load("res://data/progression/default.tres")
	world.add_child(gems)
	# Jugadores: los de la selección de personaje (J1..J4) o, lanzando la partida directa, el
	# J1 de siempre más `bots=N` jugadores de compañía.
	if GameSession.is_set():
		var first_local := true
		for i in GameSession.seats.size():
			var seat: GameSession.Seat = GameSession.seats[i]
			var ch := String(seat.character)
			if i == 0 and not GameSession.online: ch = args.get_str("character", String(DebugOptions.get_value("character", ch)))
			# en red (hito 9.3a), los de otros PC los mueve la red (Player.remote); `bot=` lleva al
			# primero de este PC (pruebas con dos ventanas)
			var inp: PlayerInput
			if not seat.is_local(): inp = PlayerInput.new()
			elif args.has("bot") and (first_local or seat.device <= -10): inp = _make_input()   # y los de prueba
			else: inp = Devices.make_input(seat.device)
			var sp := _spawn_player(ch, inp)
			sp.remote = not seat.is_local()
			if inp is SmartBot: (inp as SmartBot).body = sp
			if seat.is_local(): first_local = false
			if seat.pet != &"": _spawn_pet(String(seat.pet), sp)
	else:
		var p0 := _spawn_player(args.get_str("character", String(DebugOptions.get_value("character", "dyer"))), _make_input())
		if p0.input is SmartBot: (p0.input as SmartBot).body = p0
	var extra: PackedStringArray = args.get_str("bot_chars", "").split(",", false)
	var defaults := ["olmstead", "peaslee", "whipple", "legrasse", "johansen", "varga", "blake", "iwanicki", "elwood", "malone", "dyer"]
	for k in mini(args.get_int("bots", 0), 4 - players.size()):
		var ch: String = extra[k] if k < extra.size() else ""
		if ch == "":
			for d: String in defaults:
				if players.all(func(q: Player) -> bool: return String(q.data.id) != d):
					ch = d
					break
		var bot: BotInput = SmartBot.new(args.get_float("skill", 0.8)) if args.get_str("bot", "") == "smart" else BotInput.new("follow", 3.0 + k * 0.7)
		bot.phase = TAU * (k + 1) / 4.0
		bot.period = 7.0 + k * 1.5
		var bp := _spawn_player(ch, bot)
		bot.body = bp
		bot.leader = players[0]
	player = players[0]
	for q in players:                                 # el J1 de la depuración y las pruebas: el primero de este PC
		if not q.remote:
			player = q
			break
	if args.has("pet"): _spawn_pet(args.get_str("pet"), player)   # probar un compañero
	if args.has("pets"):                            # pets=gato,perro: uno por jugador, en orden (hito 12.9)
		var ids := args.get_str("pets").split(",")
		for i in mini(ids.size(), players.size()): _spawn_pet(ids[i], players[i])
	var bonus := Shop.bonuses(Saves.current)          # lo comprado en la tienda (D-31)
	if args.has("shop"):                              # pruebas: N niveles en cada potenciador, sin tocar la partida
		var n := args.get_int("shop")
		for it: ShopItem in DebugOptions.list_resources("res://data/shop"):
			if it.section == ShopItem.Section.POWERUP and bonus.has(it.stat) and it.stat != "money":
				bonus[it.stat] = float(Shop.DEFAULTS[it.stat]) + it.per_level * mini(n, it.max_level())
	var pact := float(bonus.pact)                     # Pacto con el Hombre Negro: más horror, más premio
	money_mult = float(bonus.money) * (1.0 + pact * 1.5)
	bonus.insight = float(bonus.insight) * (1.0 + pact * 1.5)
	shop_bonus = bonus
	for q in players:
		# en red (hito 9.3b), cada jugador con lo comprado en su PC
		var seat: GameSession.Seat = GameSession.seats[q.index] if GameSession.online and q.index < GameSession.seats.size() else null
		var b := bonus
		if seat != null and not seat.is_local() and not seat.shop.is_empty():
			b = seat.shop.duplicate()
			b.insight = float(b.insight) * (1.0 + pact * 1.5)
		q.shop = b
		q.progress.weapon_slots += int(b.weapon_slots)
		q.progress.item_slots += int(b.item_slots)
		q.rebuild_stats()
		q.health = q.data.max_health
		q.sanity = q.data.max_sanity
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
	if args.get_bool("neutral"):                    # bancos: atributos iguales (13) para no favorecer ningún tipo de arma
		for k in Attributes.NAMES:
			player.attrs[k] = 13; player.attrs_level1[k] = 13
		player.rebuild_stats()
	var wlist: PackedStringArray = args.get_str("weapons", "").split(",", false)
	if not wlist.is_empty():                        # armas de prueba para el J1
		for w in player.weapons.weapons.duplicate(): player.weapons.remove_weapon(w.data.id)
		for wid in wlist:
			var w := player.weapons.add_weapon(load("res://data/weapons/%s.tres" % wid))
			w.level = clampi(args.get_int("wlevel", 1), 1, w.data.max_level)
	elif args.get_bool("noweapons"):                 # clips del ambiente: sin disparar a nada
		for w in player.weapons.weapons.duplicate(): player.weapons.remove_weapon(w.data.id)
	elif args.has("wlevel"):
		for w in player.weapons.weapons: w.level = clampi(args.get_int("wlevel", 1), 1, w.data.max_level)
	for up_id in args.get_str("items").split(",", false):     # items=iman,vida: objetos del J1 al empezar
		player.progress.passives[up_id] = args.get_int("ilevel", 1)
	if args.has("items"): player.rebuild_stats()
	camera = GameCamera.new()
	camera.view_size = args.get_float("cam", 15.0)
	for q in players:                                 # en red, cada PC sigue a los suyos (D-10)
		if not q.remote: camera.targets.append(q)
	add_child(camera)
	if camera.targets.size() > 1:                   # correa: nadie se sale del encuadre máximo
		for q in players:
			if not q.remote: q.leash = func(pos: Vector3) -> Vector3: return camera.leash(pos)
	_env = env
	add_child(Ambient.new().setup(arena, camera, arena_path.get_file().get_basename()))   # ambiente del escenario
	_make_announcer()
	if not args.get_bool("nolevel"):
		var level_id := (String(GameSession.level) if not GameSession.carry.is_empty() else args.get_str("level", String(GameSession.level) if GameSession.is_set() else "p1_n1"))
		level = load("res://data/levels/%s.tres" % level_id).duplicate()
		_apply_carry()                                 # progreso del nivel anterior de la parte
		_shop_start()
		if args.get_bool("log"): print("INICIO %s nivel=%d armas=%s" % [level_id, player.progress.level, player.weapons.weapons.map(func(w: WeaponSystem.Weapon) -> String: return "%s:%d" % [w.data.id, w.level])])
		if args.has("final_at"): level.final_time = args.get_float("final_at")
		if args.get_bool("boss") and level.final_next != null:      # boss=true: el jefe es el evento final
			level.final_enemy = level.final_next
			level.final_next = null
		if args.has("mid_at") and not level.mid_times.is_empty():     # adelanta los eventos intermedios
			var k := args.get_float("mid_at") / level.mid_times[0]
			level.mid_times.assign(level.mid_times.map(func(t: float) -> float: return t * k))
		if args.has("chest_every"): level.chest_every = args.get_float("chest_every")   # baúles más a menudo (capturas)
		if args.has("spawn_rate"): level.spawn_rate = [Vector2(0, args.get_float("spawn_rate"))] as Array[Vector2]
		# Construir ya los modelos de todos los enemigos del nivel: si no, la primera aparición
		# de cada uno (el Acechador, en el minuto 4) provocaría un tirón a mitad de partida.
		for ed: EnemyData in level.pool + level.final_pool + level.mid_enemies + ([level.final_enemy] if level.final_enemy else []) + ([level.final_next] if level.final_next else []):
			VoxelBuilder.load_model("res://models/%s.json" % ed.model).free()
		var enemies_root := Node3D.new()
		enemies_root.name = "Enemies"
		add_child(enemies_root)
		director = WaveDirector.new().setup(level, world, arena.get_meta("obstacles"), camera, enemies_root)
		if args.has("max_alive"): director.max_alive_override = args.get_int("max_alive")
		for eid in args.get_str("enemies").split(",", false):    # enemies=profundo: solo esos (probar uno nuevo)
			director.pool_override.append(load("res://data/enemies/%s.tres" % eid))
		director.players = players.size()           # la dificultad crece con los jugadores
		director.mirror = is_guest()                  # invitado: el mundo lo manda el anfitrión
		director.spread_spawns = GameSession.online
		director.pact = 1.0 + float(shop_bonus.get("pact", 0.0))
		director.final_event.connect(func(e: Enemy) -> void:
			if level.boss_music != "": Music.play(level.boss_music, 2.0)   # música del jefe
			if args.get_bool("log"): print("MUSICA ", Music.current())
			if e != null: Sfx.play_at("roar" if e.data.unique else "growl", e.global_position)
			else: Sfx.play("growl")
			if e != null and _boss_intro: BossIntro.play(self, camera, e, level.final_text)   # entrada del jefe
			else: announce(level.final_text, 3.5))
		director.boss_event.connect(func(e: Enemy, text: String) -> void:
			if e != null and _boss_intro: BossIntro.play(self, camera, e, text)
			else: announce(text, 4.0)
			if args.get_bool("log"): print("JEFE %s t=%.0f" % [e.data.id, director.time]))
		director.mid_event.connect(func(e: Enemy, text: String) -> void:
			Sfx.play_at("growl", e.global_position)
			announce(text, 3.5)
			if args.get_bool("log"): print("MINIJEFE %s t=%.0f" % [e.data.id, director.time]))
		director.level_completed.connect(_on_level_completed)
		director.enemy_spawned.connect(func(e: Enemy) -> void: e.died.connect(_on_enemy_died))
		# rompibles y peligros del escenario: en red, solo en el anfitrión (llegan a los invitados en el 9.3c)
		if not args.get_bool("nobreakables") and not is_guest(): add_child(BreakableSpawner.new().setup(world, arena.get_meta("size")))
		if args.get_bool("pickup_test"):               # las cinco recompensas en fila delante del J1
			for k in 5: world.fx.add_child.call_deferred(Pickup.new().setup(world, player.position + Vector3(-4 + k * 2, 0, 3), k as Pickup.Kind))
		director.chest_spawned.connect(func(c: ArcaneChest) -> void:
			c.opened.connect(func(_c: ArcaneChest, by: Player) -> void:
				Sfx.play_at("chest", c.global_position)
				earn(c.money)
				if not is_guest(): _try_evolve(by)         # en red, las armas de todos las lleva el anfitrión
				if args.get_bool("log"): print("BAUL abierto por J%d" % (by.index + 1))
				Achievements.add(Saves.current, "chests"))
			announce("Ha aparecido un baúl arcano", 1.5))
		add_child(director)
		if level.angle_every > 0.0 or level.wave_every > 0.0:      # peligros del escenario (hito 7.4)
			hazards = Hazards.new().setup(level, world, arena.get_meta("obstacles"))
			hazards.mirror = is_guest()               # en red, los saca el anfitrión (NetGame)
			add_child(hazards)
		if not args.has("shots") or args.get_bool("card"):   # capturas: sin el rótulo, salvo card=true
			LevelCard.enter(self, level_id, level.display_name)
		Music.play(level.music_path())
		if args.get_bool("log"): print("MUSICA ", Music.current())
	_start_weather()
	Engine.time_scale = args.get_float("timescale", 1.0)
	HitStop.enabled = args.get_bool("hitstop", true)     # micro-pausa al impactar (hito 11.1)
	_boss_intro = args.get_bool("boss_intro", true)
	DamageNumbers.set_mode(Auto.setting("damage_numbers", 2))   # hito 11.2 (cfg_damage_numbers=0|1|2)
	Quality.apply_game(env, moon)                        # calidad gráfica (hito 11.5); las opciones de abajo mandan
	Crumble.enabled = args.get_bool("crumble", Crumble.enabled)
	Crumble.falls = args.get_bool("falls", true)
	Enemy.wounds = args.get_str("wounds", "true") != "false" and (bool(Quality.value("wounds", true)) or args.has("wounds"))   # en Baja, sin grietas
	Enemy.wounds_force = args.get_float("wounds", -1.0) if args.get_str("wounds", "").is_valid_float() else -1.0
	Enemy.rise_enabled = args.get_bool("rise", true)   # hito 11.6
	GroundMarks.limit = args.get_int("marks", GroundMarks.limit)
	Debris.limit = GroundMarks.limit * Debris.PER_MARK       # restos de los rompibles (hito 12.11)
	WallScorch.limit = GroundMarks.limit / 2                 # quemaduras en las paredes (hito 12.11)
	hud = Hud.new().setup(players, director)
	hud.money = func() -> int: return run_money
	add_child(hud)
	add_child(SanityFx.new().setup(players))         # distorsiones de cordura baja
	if director != null: add_child(Tips.new(self))   # consejos de la primera partida (hito 13.3)
	menus = PlayerMenus.new().setup(self, players)
	add_child(menus)
	if args.has("panel"):                            # capturas: panel=sheet|map, panel_player=2, panel_page=1
		var who := players[clampi(args.get_int("panel_player", 1), 1, players.size()) - 1]
		get_tree().create_timer(args.get_float("panel_at", 1.0)).timeout.connect(func() -> void:
			menus.toggle(who, StringName(args.get_str("panel")))
			if menus._open.get(who) is PlayerMenus.Sheet: (menus._open[who] as PlayerMenus.Sheet).turn(args.get_int("panel_page", 0)))
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
		for i in 10:                                   # dos de cada escalón (amarilla a morada)
			var a := TAU * i / 10.0
			gems.drop(player.position + Vector3(cos(a), 0, sin(a)) * 1.6, 1.0, i / 2 + 1)
	if args.has("hp"): player.health = args.get_float("hp")
	if args.has("san"): player.sanity = args.get_float("san")
	DebugOptions.apply_all(self)
	if Saves.current != null: Saves.current.stats["runs"] += 1
	if players.size() > 1: Achievements.add(Saves.current, "coop_runs")
	if args.get_int("demo") > 0: _demo_crowd(args.get_int("demo"))
	if args.get_int("dummies") > 0: _dummies(args.get_int("dummies"))
	if args.get_bool("emitters"): _emitters()
	if args.has("fx_demo"): _fx_demo(args.get_str("fx_demo"))
	if args.has("blast"):                            # pruebas: blast=x,z,t;x,z,t explosiones ahí a esos s (hito 12.11)
		for b in args.get_str("blast").split(";"):
			var v := b.split(",")
			get_tree().create_timer(float(v[2]), false).timeout.connect(func() -> void:
				var fx := Explosion.new()
				fx.radius = 2.2
				fx.position = Vector3(float(v[0]), 0.0, float(v[1]))
				world.fx.add_child(fx))
	if args.has("crate"):                            # pruebas: crate=x,z,t;… un rompible ahí que se rompe a esos s (hito 12.11)
		for b in args.get_str("crate").split(";"):
			var v := b.split(",")
			var br := Breakable.new().setup(world, Vector3(float(v[0]), 0.0, float(v[1])))
			add_child(br)
			get_tree().create_timer(float(v[2]), false).timeout.connect(func() -> void: if is_instance_valid(br): br.shatter())
	if args.has("debug_menu"):                     # abre la pausa y la depuración (capturas)
		get_tree().create_timer(args.get_float("debug_menu", 1.0)).timeout.connect(func() -> void:
			toggle_pause()
			if args.get_bool("dif_menu"): _open_difficulty()         # la dificultad (D-42)
			else: _open_debug())
	_shot_tag = ("_" + args.get_str("tag")) if args.has("tag") else ""
	if is_guest(): _shot_tag += "_inv"                 # dos ventanas en el mismo PC: que no se pisen
	if args.has("shots") or args.has("game_shots"):    # game_shots=: solo aquí (la selección también lee shots=)
		add_child(ShotTaker.new(args.get_floats("game_shots" if args.has("game_shots") else "shots"), "res://shots/game%s" % _shot_tag))
	if GameSession.online and Net.is_active():         # partida en red (hito 9.3a)
		gems.mirror = is_guest()                      # la experiencia la cuenta el anfitrión
		net_game = NetGame.new(self, Net)
		add_child(net_game)
		hud.net_info = _net_info                       # hito 9.4b: PC y ping en los paneles de los demás
		hud.add_child(OffscreenArrows.new().setup(players, camera))   # y flechas hacia los que no se ven
	if args.has("quit_at"):                        # pruebas: "Menú principal" a los t s de juego (en red, deja la sala)
		get_tree().create_timer(args.get_float("quit_at"), false).timeout.connect(_quit)
	for kind: StringName in [&"sheet", &"map"]:      # pruebas: la ficha o el mapa del J1 a los t s
		if args.has(kind + "_at"):
			get_tree().create_timer(args.get_float(kind + "_at"), false).timeout.connect(func() -> void: menus.toggle(player, kind))
	if args.has("demo_kill"):                      # pruebas: todos los enemigos mueren a los t s
		get_tree().create_timer(args.get_float("demo_kill"), false).timeout.connect(func() -> void:
			for e in world.enemies.duplicate():
				if is_instance_valid(e) and e is Enemy and e.is_alive(): e.take_damage(Damage.new(1.0e7, 0.0)))
	if args.has("rise_demo") and director != null:   # pruebas: aparecen esos enemigos alrededor del J1 a los rise_at s
		get_tree().create_timer(args.get_float("rise_at", 1.5), false).timeout.connect(func() -> void:
			var ids := args.get_str("rise_demo").split(",")
			for i in ids.size():
				var a := TAU * i / ids.size()
				director.spawn(load("res://data/enemies/%s.tres" % ids[i]), player.global_position + Vector3(cos(a), 0, sin(a)) * 3.2))
	if args.has("down_at"):                        # pruebas: el J1 de este PC cae a los t s de juego
		get_tree().create_timer(args.get_float("down_at"), false).timeout.connect(func() -> void:
			player.god = false
			player.take_damage(Damage.new(99999.0, 0.0)))
	if args.has("pause_at"):                       # pruebas: pausa a los t s de juego y la quita a los dur s
		var pa := args.get_floats("pause_at")
		get_tree().create_timer(pa[0], false).timeout.connect(func() -> void:
			toggle_pause()
			get_tree().create_timer(pa[1] if pa.size() > 1 else 3.0, true).timeout.connect(toggle_pause))
	if args.has("mark_at"):                        # pruebas: como pulsar F9 a los t s
		get_tree().create_timer(args.get_float("mark_at"), false).timeout.connect(net_mark)

## F9 en red: apunta una marca en el registro de red, sin parar la partida, para señalar algo
## raro durante una prueba (lo que se ve en pantalla, a qué hora, en qué nivel y minuto).
func net_mark() -> void:
	if net_game == null: return
	Net.marks += 1
	net_game.mark(Net.marks)
	mark_shot(Net.marks)
	announce("Marca %d apuntada en el registro" % Net.marks, 1.2)

## Captura pequeña de lo que se veía al marcar, junto al registro (<registro>_marca_N.png; la
## saca tools/marcas.py). Con la marca de otro PC, la de aquí en ese momento
## (<registro>_marca_N_de_<nombre>.png). Se guarda en otro hilo para no dar un tirón.
func mark_shot(n: int, from := "") -> void:
	if Net.netlog == null or Net.netlog.path == "": return
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty(): return
	var to := "%s_marca_%d%s.png" % [Net.netlog.path.get_basename(), n, NetLog.shot_suffix(from)]
	WorkerThreadPool.add_task(func() -> void:
		img.resize(640, int(640.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_BILINEAR)
		img.save_png(to))

var _mark_hold := {}                             ## mando -> s con LB+RB pulsados (-1: ya marcó)
const MARK_HOLD := 0.6

## LB+RB mantenidos en un mando de este PC: la marca de F9 (los dos a la vez no hacen nada más
## jugando; sueltos pasan páginas en la ficha y la subida).
func _watch_mark_pads(delta: float) -> void:
	for pad in JoypadInput.pads():
		var both := Input.is_joy_button_pressed(pad, JOY_BUTTON_LEFT_SHOULDER) and Input.is_joy_button_pressed(pad, JOY_BUTTON_RIGHT_SHOULDER)
		if not both or get_tree().paused:
			_mark_hold.erase(pad)
			continue
		var h := float(_mark_hold.get(pad, 0.0))
		if h < 0.0: continue
		h += delta
		if h >= MARK_HOLD:
			net_mark()
			h = -1.0
		_mark_hold[pad] = h

## ¿Este PC es un invitado de una partida en red? (El mundo lo manda el anfitrión.)
func is_guest() -> bool:
	return GameSession.online and GameSession.my_peer != 1

func is_net_host() -> bool:
	return net_game != null and not is_guest()

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
	for w in DebugOptions.list_resources("res://data/weapons"):    # todas las armas, sin las evoluciones (D-06)
		if not (w as WeaponData).evolved: q.progress.weapon_pool.append(w)
	for up in DebugOptions.list_resources("res://data/upgrades"):    # todos los objetos (D-38)
		q.progress.upgrade_pool.append(up)
	q.progress.leveled_up.connect(func(l: int) -> void: Achievements.record(Saves.current, "best_level", l))
	q.progress.leveled_up.connect(func(_l: int) -> void:
		level_fx(q)
		_open_level_up.call_deferred())
	q.downed.connect(_on_downed.bind(q))
	q.revived.connect(func() -> void:
		Achievements.add(Saves.current, "revives")
		announce("J%d vuelve a la lucha" % (i + 1), 1.5))
	q.downed.connect(func() -> void: _someone_fell = true)
	q.downed.connect(func() -> void: _downs[q.index] = int(_downs.get(q.index, 0)) + 1)
	q.eliminated.connect(func() -> void:
		announce("J%d, eliminado hasta el siguiente nivel" % (i + 1), 2.0)
		_check_all_down())
	if args.get_bool("log"):
		q.damaged.connect(func(d: Damage) -> void:
			var src := "bala" if d.source == null else String((d.source as Enemy).data.id) + (" (carga)" if d.physical > 8.0 else "")
			print("  J%d golpe t=%.1f  -%d vida -%d cordura  de %s  -> vida %d" % [i + 1, director.time if director else 0.0, d.physical, d.mental, src, q.health]))
	q.sanity_state.crisis_started.connect(func(_k: StringName) -> void: Achievements.add(Saves.current, "crises"))
	q.sanity_state.crisis_started.connect(func(k: StringName) -> void:
		var what := "Crisis: %s" % SanityState.NAMES.get(k, "locura")
		announce(what if players.size() == 1 else "J%d · %s" % [i + 1, what], 2.5))
	q.lights.assign(arena.get_meta("lights"))       # las luces del escenario recuperan cordura
	q.madness = bool(Settings.get_value("madness"))
	q.weapons = WeaponSystem.new().setup(q, world)
	q.add_child(q.weapons)
	for wid in q.data.starting_weapons: q.weapons.add_weapon(load("res://data/weapons/%s.tres" % wid))
	return q

## Al subir de nivel: sonido, columna de luz y las curas de Whipple y West. En red, la vida
## solo cambia en los jugadores de este PC (la de los demás la manda su PC); en el invitado
## lo llama NetGame cuando el anfitrión avisa de la subida.
func level_fx(q: Player) -> void:
	Sfx.play("level_up")
	VoxelFx.puff(q, q.global_position, "rise", 0.6, Color.WHITE, 1.4)      # columna de luz (11-10-2026)
	if not q.remote: q.health = minf(q.health + q.data.max_health * q.data.heal_on_level, q.data.max_health)   # Whipple
	if q.data.team_heal_on_level > 0.0:                   # rasgo de West: cura a los compañeros cercanos
		for o in players:
			if o != q and not o.remote and o.health > 0.0 and o.global_position.distance_to(q.global_position) <= 6.0:
				o.health = minf(o.health + o.data.max_health * q.data.team_heal_on_level, o.data.max_health)

## Compañero de un jugador (D-20): lo sigue toda la partida.
func _spawn_pet(id: String, owner: Player) -> void:
	var pd: PetData = load("res://data/pets/%s.tres" % id)
	if pd == null: return
	var pet := Pet.new().setup(pd, owner, world, self)
	owner.pet = pet                                  # la ficha lo enseña
	add_child(pet)

## ¿Lo maneja la máquina? (elige sola sus mejoras sin parar la partida). En red, un jugador de
## otro PC lo es si allí lo lleva un bot: elige aquí, con SmartBot.
func _is_bot(q: Player) -> bool:
	if q.remote: return net_game != null and net_game.is_remote_bot(q)
	return q.input is BotInput and not args.get_bool("bots_pause")   # pruebas: como una persona

# ---------------- flujo de la partida ----------------
func _on_enemy_died(e: Enemy) -> void:
	kills += 1
	if Saves.current != null: Saves.current.stats["kills"] += 1
	if e.data.elite: Achievements.add(Saves.current, "elites")
	gems.drop(e.global_position, e.data.xp, e.data.tier)
	earn(e.data.money)

## Invitado: muere un enemigo (lo dice el anfitrión, hito 9.5b). Las bajas de la partida llegan
## en la foto; aquí cuenta en su partida guardada: estadísticas, logros y dólares.
func net_enemy_died(e: Enemy) -> void:
	if Saves.current != null: Saves.current.stats["kills"] += 1
	if e.data.elite: Achievements.add(Saves.current, "elites")
	earn(e.data.money)

## Dólares (D-31): se suman al hueco en el momento, así que se conservan aunque se caiga.
func earn(amount: int) -> void:
	var n := int(round(amount * money_mult * (director.team_item("money_mult") if director else 1.0)))   # Oro de Obed
	if n <= 0: return
	run_money += n
	if Saves.current != null:
		Saves.current.money += n
		Saves.current.stats["money"] = int(Saves.current.stats.get("money", 0)) + n

## Subida de nivel: pausa y elige una de tres mejoras (D-16). Si hay varias subidas
## pendientes, se encadenan.
## En cooperativo (D-39), las subidas van por turnos (TeamXp): sube un jugador cada vez, que
## elige solo en la ventana del centro, con su color, mientras los demás esperan. Si varios
## tienen subidas pendientes (Diario de expedición, depuración), eligen uno tras otro, por
## orden. Los bots eligen solos sin parar la partida y se anuncia lo que han cogido.
const LEVEL_UP_COOP_SPEED := 1.6
func _open_level_up() -> void:
	if _menu_open or _ended or _pause != null: return
	if args.get_bool("nolevelup"):                   # banco de armas (tools/banco_armas.py): sin mejoras
		for q in players: q.progress.pending = 0
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
	var coop := players.size() > 1
	if args.get_bool("autopick") or _is_bot(q):
		var pick: PlayerProgress.Option = options[0] if not _is_bot(q) else options[_rng.randi() % options.size()]
		if q.input is SmartBot or (q.remote and _is_bot(q)): pick = SmartBot.pick(options, q, _rng)
		q.progress.choose(pick, q)
		if coop and not args.get_bool("autopick"):
			var said := _pick_text(q, pick)
			announce(said, 1.6)
			if net_game != null and q.remote: net_game.say(said)   # el bot es de otro PC: que lo vean todos
		_open_level_up.call_deferred()
		return
	_menu_open = true
	get_tree().paused = true
	var title := "Nivel %d" % (q.progress.level - q.progress.pending + 1)
	if net_game != null: title = "Turno de J%d · %s (%s) · %s" % [q.index + 1, q.data.display_name, _pc_name(_peer_of(q)), title]
	elif coop: title = "Turno de J%d · %s · %s" % [q.index + 1, q.data.display_name, title]
	var attr := "" if q.progress.attr_gains.is_empty() else String(q.progress.attr_gains[0])  # D-27: lo enseña el rodillo
	if net_game != null:                          # en red, la partida se para en todos los PC
		net_game.halt_all({"k": "lvup", "peer": _peer_of(q), "i": q.index, "title": title, "attr": attr})
		if q.remote: return                        # elige en su PC (llega con net_picked)
	# la misma ventana en solitario y en cooperativo, centrada (antes, Menus.LevelUpMenu: fila de
	# botones con el foco de Godot, que con el mando no bajaba y a ratos no respondía)
	var said := [""]
	var menu := _level_up_window(q, options, title, attr, func(pq: Player, o: PlayerProgress.Option) -> void:
		pq.progress.choose(o, pq)
		said[0] = _pick_text(pq, o))
	menu.finished.connect(func() -> void:
		_menu_open = false
		if net_game != null: net_game.resume_all(said[0])
		else: get_tree().paused = false
		_open_level_up.call_deferred())
	add_child(menu)

## La ventana de subida de un jugador (CoopLevelUp centrada, con su color en cooperativo).
func _level_up_window(q: Player, options: Array[PlayerProgress.Option], title: String, attr: String, pick: Callable) -> CoopLevelUp:
	var entry := {"player": q, "options": options, "title": title, "attr": attr}
	if players.size() > 1:
		entry["accent"] = q.color
		entry["speed"] = LEVEL_UP_COOP_SPEED            # más pausas que en solitario: rodillos más cortos
	var menu := CoopLevelUp.new([entry] as Array[Dictionary], pick, true)
	var after := args.get_float("pick_after", -1.0)   # pruebas: elige sola la opción marcada a los N s
	if after >= 0.0: menu.auto_pick_after = after
	return menu

static func _pick_text(q: Player, o: PlayerProgress.Option) -> String:
	return "J%d · %s: %s" % [q.index + 1, q.data.display_name, o.title()]

## PC que maneja a un jugador (en local, el 1). Si su PC se ha ido, lo lleva un bot de aquí.
func _peer_of(q: Player) -> int:
	if not q.remote: return GameSession.my_peer
	return GameSession.seats[q.index].peer if q.index < GameSession.seats.size() else 1

func toggle_pause() -> void:
	if _menu_open or _ended: return
	if menus != null and _pause == null and menus.solo() and menus.close_all(): return   # Esc cierra la ficha o el mapa
	if _debug != null: return                     # el menú de depuración atiende Esc y Start
	if net_game != null and net_game.started:
		_net_toggle_pause()
		return
	if _pause != null:
		_pause.queue_free()
		_pause = null
		get_tree().paused = false
		if DebugOptions.values.has("time_scale"): Engine.time_scale = DebugOptions.values["time_scale"]
		_open_level_up.call_deferred()             # subidas pendientes (p. ej. de la depuración)
		return
	_open_pause()
	get_tree().paused = true

## Abre el menú de pausa (en un invitado, solo Continuar y Menú principal).
func _open_pause() -> void:
	_pause = Menus.PauseMenu.new(is_guest())
	if is_guest(): _pause.ping = func() -> int: return int(Net.peers.get(GameSession.my_peer, {}).get("ping", -1))
	_pause.resume.connect(toggle_pause)
	_pause.restart.connect(_restart)
	_pause.debug.connect(_open_debug)
	_pause.difficulty.connect(_open_difficulty)
	_pause.quit.connect(_quit)
	add_child(_pause)

func _close_pause() -> void:
	if _pause != null: _pause.queue_free()
	_pause = null

# ---------------- red (hito 9.4a): paradas para todos ----------------
## En red, la pausa para la partida en todos los PC (D-10). La pide cualquiera; la quita quien
## la puso o el anfitrión (por si alguien se ausenta).
func _net_toggle_pause() -> void:
	var h := net_game.halt
	if is_guest():
		if h.is_empty(): net_game.ask_pause(true)
		elif h.get("k") == "pause" and int(h.get("peer", 0)) == GameSession.my_peer: net_game.ask_pause(false)
		return
	if h.is_empty():
		net_game.halt_all({"k": "pause", "peer": 1})
	elif h.get("k") == "pause":
		net_game.resume_all()

## Anfitrión: un invitado pide la pausa o quitarla.
func net_pause_asked(peer: int, on: bool) -> void:
	var h := net_game.halt
	if on:
		if h.is_empty() and not _menu_open and not _ended and _debug == null: net_game.halt_all({"k": "pause", "peer": peer})
	elif h.get("k") == "pause" and int(h.get("peer", 0)) == peer:
		net_game.resume_all()

## La partida se para en todos los PC (NetGame.halt_all o HALT). Quien la ha parado tiene su
## ventana (la pausa o la subida); los demás, un aviso.
func net_halt(d: Dictionary) -> void:
	if args.get_bool("halt_shots"): _halt_shot()
	if args.get_bool("log"): print("PARADA %s pc=%d j=%d t=%.1f" % [d.get("k"), int(d.get("peer", 1)), int(d.get("i", -1)) + 1, director.time if director else 0.0])
	var mine := int(d.get("peer", 1)) == GameSession.my_peer
	var who := _pc_name(int(d.get("peer", 1)))
	if d.get("k") == "pause":
		if mine:
			_open_pause()
			return
		var buttons := [["Menú principal", _quit]]
		if not is_guest(): buttons.push_front(["Continuar", func() -> void: net_game.resume_all()])
		_show_halt("En pausa: la ha puesto %s" % who, buttons)
		return
	var i := int(d.get("i", 0))
	if i >= players.size(): return
	var q: Player = players[i]
	if mine:
		if is_guest(): _open_net_level_up(q, d)       # en el anfitrión, la ventana ya está abierta
		return
	var text := "Turno de J%d · %s (%s)\neligiendo mejora…" % [i + 1, q.data.display_name, who]
	_show_halt(text, [])
	if is_guest(): return
	# anfitrión: si tarda (se ha ausentado), puede elegir por él
	var n := int(d.get("n", 0))
	get_tree().create_timer(args.get_float("afk_pick", NET_AFK_PICK), true).timeout.connect(func() -> void:
		if int(net_game.halt.get("n", -1)) == n and _halt_ui != null:
			_show_halt(text, [["Elegir por J%d" % (i + 1), _pick_for.bind(i)]])
			if args.get_bool("halt_shots"): _halt_shot()
			if args.get_bool("afk_press"): get_tree().create_timer(1.5, true).timeout.connect(_pick_for.bind(i)))   # pruebas

## Anfitrión: elige por el jugador de otro PC que no se decide (como lo haría un bot).
func _pick_for(i: int) -> void:
	if net_game.halt.get("k") != "lvup" or int(net_game.halt.get("i", -1)) != i: return   # ya eligió
	var q: Player = players[i]
	var options := q.progress.roll_options(q.weapons, _rng)
	if options.is_empty(): return
	net_picked(i, {"key": PlayerProgress.key_of(SmartBot.pick(options, q, _rng)), "by_host": true})

## Invitado: le toca subir a un jugador de este PC. Tira sus opciones (el progreso acaba de
## llegar) y manda lo elegido al anfitrión, que lo aplica y sigue.
func _open_net_level_up(q: Player, d: Dictionary) -> void:
	var options := q.progress.roll_options(q.weapons, _rng)
	if options.is_empty(): return
	var menu := _level_up_window(q, options, String(d.get("title", "")), String(d.get("attr", "")),
		func(pq: Player, o: PlayerProgress.Option) -> void: net_game.send_pick(pq, o))
	menu.name = "NetLevelUp"
	add_child(menu)

## Anfitrión: lo que ha elegido el jugador de otro PC en su subida.
const NET_AFK_PICK := 30.0                       ## s hasta que el anfitrión puede elegir por otro PC (afk_pick=)
func net_picked(i: int, d: Dictionary) -> void:
	var q: Player = players[i]
	if d.get("banished") is Array:
		for k: Variant in d.banished: q.progress.banished[String(k)] = true
	q.rerolls_used = int(d.get("rerolls", q.rerolls_used))
	q.banishes_used = int(d.get("banishes", q.banishes_used))
	var o := q.progress.option_for(String(d.get("key", "")), q.weapons)
	if o == null:                                    # ya no vale (no debería pasar): la primera que salga
		var opts := q.progress.roll_options(q.weapons, _rng)
		o = opts[0] if not opts.is_empty() else null
	var said := ""
	var by_host := bool(d.get("by_host", false))
	if o != null:
		q.progress.choose(o, q)
		said = _pick_text(q, o) + (" (elegida por el anfitrión)" if by_host else "")
	else: q.progress.pending = maxi(q.progress.pending - 1, 0)
	_menu_open = false
	net_game.resume_all(said, by_host)
	_open_level_up.call_deferred()

## Anfitrión: se ha ido el PC que elegía (su jugador ya lo lleva un bot) o que puso la pausa.
func net_halt_gone(d: Dictionary) -> void:
	if d.get("k") == "lvup":
		_menu_open = false
		net_game.resume_all()
		_open_level_up.call_deferred()                 # ahora es un bot de aquí: elige solo
	else: net_game.resume_all()

## La partida sigue: fuera ventanas y avisos de la parada, y el anuncio de lo elegido.
func net_resume(d: Dictionary) -> void:
	if _halt_ui != null:
		_halt_ui.queue_free()
		_halt_ui = null
	_close_pause()
	var w := get_node_or_null("NetLevelUp")
	if w != null: w.queue_free()
	if not _ended: get_tree().paused = false
	if DebugOptions.values.has("time_scale"): Engine.time_scale = DebugOptions.values["time_scale"]
	var text := String(d.get("text", ""))
	if text != "" and (int(d.get("peer", 1)) != GameSession.my_peer or bool(d.get("all", false))): announce(text, 1.8)
	if args.get_bool("log"): print("SIGUE t=%.1f %s" % [director.time if director else 0.0, text])
	if not is_guest(): _open_level_up.call_deferred()

## Pruebas (halt_shots=true): una captura de cada parada, al segundo y poco.
var _halt_shots := 0
func _halt_shot() -> void:
	_halt_shots += 1
	var path := "res://shots/game%s_parada%d.png" % [_shot_tag, _halt_shots]
	await get_tree().create_timer(1.2, true).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("captura: ", ProjectSettings.globalize_path(path))

## Panel del HUD de un jugador de otro PC: [nombre de su PC, ping hasta él en ms] (-1 si se ha
## ido). El ping de los invitados lo mide el anfitrión: de un invitado a otro se suman los dos.
func _net_info(q: Player) -> Array:
	if not q.remote:                               # anfitrión: el de un PC que se fue lo lleva la máquina
		var seat: GameSession.Seat = GameSession.seats[q.index] if q.index < GameSession.seats.size() else null
		if seat == null or seat.peer == GameSession.my_peer or Net.peers.has(seat.peer): return []
		var back := GameSession.returning.values().has(seat.peer)
		return ["%s · %s" % [seat.name, "vuelve en el siguiente nivel" if back else "lo lleva la máquina"], -1]
	var peer := _peer_of(q)
	if not Net.peers.has(peer): return ["sin conexión", -1]
	var mine := int(Net.peers.get(GameSession.my_peer, {}).get("ping", 0))
	var ms := mine if peer == 1 else int(Net.peers[peer].get("ping", 0)) + (mine if is_guest() else 0)
	return [_pc_name(peer), ms]

## Nombre del PC en la sala.
func _pc_name(peer: int) -> String:
	return String(Net.peers.get(peer, {}).get("name", "otro jugador")) if Net != null else "otro jugador"

## Aviso de una parada puesta por otro PC, con sus botones ([texto, Callable]).
func _show_halt(text: String, buttons: Array) -> void:
	if _halt_ui != null: _halt_ui.queue_free()
	_halt_ui = CanvasLayer.new()
	_halt_ui.layer = 30
	_halt_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	var win: Array = MenuKit.window(_halt_ui, MenuKit.INK, 520)
	var box: VBoxContainer = win[1]
	var l := UiKit.label(text, 28, UiKit.TEXT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	var first: Button = null
	for pair: Array in buttons:
		var b := MenuKit.button(String(pair[0]), MenuKit.INK, 26)
		b.custom_minimum_size = Vector2(320, 56)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var f: Callable = pair[1]
		b.pressed.connect(func() -> void: f.call())
		box.add_child(b)
		if first == null: first = b
	add_child(_halt_ui)
	if first != null: first.grab_focus.call_deferred()

## Menú de depuración, encima de la pausa (que se oculta mientras tanto).
func _open_debug() -> void:
	if _debug != null: return
	var dm := DebugMenu.new(self)
	dm.restart.connect(_restart)
	_over_pause(dm, "Depuración")

## Pausa > Dificultad (temporal, D-42): del 1 al 10 por características.
func _open_difficulty() -> void:
	if _debug != null: return
	_over_pause(DifficultyMenu.new(self), "Dificultad (temporal)")

## Un menú encima de la pausa (con back y close): al volver, el foco en su botón.
func _over_pause(m: CanvasLayer, button: String) -> void:
	_debug = m
	_pause.visible = false
	m.connect("back", func() -> void:
		_debug.queue_free()
		_debug = null
		_pause.show_again(button))
	m.connect("close", func() -> void:
		_debug.queue_free()
		_debug = null
		toggle_pause())
	add_child(m)

## "Menú principal" (pausa y pantalla final): guarda y vuelve al menú de la portada. Sin
## hueco elegido (partida lanzada directamente), sale del juego.
## Al irse la partida (menú, reintentar, siguiente nivel): que no quede el juego parado.
func _exit_tree() -> void:
	HitStop.stop()

func _quit() -> void:
	Saves.save()
	get_tree().paused = false
	Engine.time_scale = 1.0
	if net_game != null:                              # en red: deja la sala (si es el anfitrión, la cierra)
		Net.close()
		TitleScreen.skip_to_menu = true
		TitleScreen.reopen_online = true
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		return
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
	return PackedStringArray(["Tiempo: %02d:%02d" % [t / 60, t % 60], "Enemigos abatidos: %d" % kills, lv,
		"Dólares ganados: %s $" % MenuKit.money(run_money)])

## Una muestra por segundo de juego: vida y cordura de los jugadores de este PC y los vivos.
func _report_sample() -> void:
	for q in players:
		if q.remote: continue
		if not _rep_hist.has(q.index): _rep_hist[q.index] = PackedVector2Array()
		var h: PackedVector2Array = _rep_hist[q.index]
		h.append(Vector2(q.health / maxf(q.data.max_health, 1.0), q.sanity / maxf(q.data.max_sanity, 1.0)))
		if h.size() > 600: h = h.slice(h.size() - 600)
		_rep_hist[q.index] = h
	_rep_alive.append(world.enemies.size() if world != null else director.alive.size())   # también las marionetas (invitado)

## Los informes de los jugadores de este PC (vacío en las ejecuciones sin director).
func _reports() -> Array:
	var out: Array = []
	if director == null: return out
	for q in players:
		if q.remote: continue
		var who := "J%d · %s" % [q.index + 1, q.data.display_name]
		out.append(FallReport.build(who, q.color, q.received_via, _rep_falls.get(q.index, []),
			_rep_hist.get(q.index, PackedVector2Array()), _rep_alive))
	return out

## Cae un jugador. En cooperativo queda derribado y los demás pueden reanimarlo; la partida
## se acaba cuando no queda nadie en pie (derribados y eliminados no cuentan).
func _on_downed(q: Player) -> void:
	if _ended: return
	if not q.remote:                                 # para el informe al caer (hito 13.1)
		if not _rep_falls.has(q.index): _rep_falls[q.index] = []
		_rep_falls[q.index].append({"t": director.time if director != null else 0.0, "hit": q.last_hit.duplicate()})
	if players.size() > 1 and players.any(func(c: Player) -> bool: return c.health > 0.0):
		announce("J%d, derribado: ¡reanimadlo!" % (q.index + 1), 2.0)
		if q.remote: _remote_down_sfx(q)
		return
	if is_guest(): return                            # la derrota la decide el anfitrión
	_game_over()

## En red, un jugador de otro PC cae (llega con su estado, sin el sonido de su PC): donde está
## si se ve; si no, sin posición y más bajo, para que se oiga aunque esté lejos.
func _remote_down_sfx(q: Player) -> void:
	var p := q.global_position + Vector3(0, 0.9, 0)
	if OffscreenArrows.place(camera.unproject_position(p), get_viewport().get_visible_rect().size) == null:
		Auto.sfx_at("down", q.global_position)
	else: Auto.sfx("down", -7.0)

## Simulaciones (tools/simular.py): nivel, vida más baja y caídas de cada jugador al acabar el nivel.
func _log_players() -> void:
	var parts := PackedStringArray()
	for q in players:
		parts.append("J%d nv=%d vida_min=%d caidas=%d" % [q.index + 1, q.progress.level, roundi(maxf(q.min_hp, 0.0) * 100), int(_downs.get(q.index, 0))])
	print("JUGADORES %s  %s" % [level.id, " | ".join(parts)])

func _check_all_down() -> void:
	if _ended or players.any(func(c: Player) -> bool: return c.health > 0.0): return
	if is_guest(): return
	_game_over()

func _game_over() -> void:
	if _ended: return
	_ended = true
	if is_net_host(): net_game.send_lost()
	if args.get_bool("log") and director != null:
		print("FIN DERROTA %s t=%d abatidos=%d nivel_j1=%d" % [level.id, int(director.time), director.killed_total, player.progress.level])
		_log_players()
		for q in players:
			var rv := {}
			for k in q.received: rv[k] = [roundi(q.received[k][0]), roundi(q.received[k][1])]
			print("RECIBIDO J%d crisis=%d %s" % [q.index + 1, q.sanity_state.crises if "crises" in q.sanity_state else -1, JSON.stringify(rv)])
	if Saves.current != null: Saves.current.stats["deaths"] += 1
	_check_achievements()
	Saves.save()
	Engine.time_scale = 0.35                       # la caída, a cámara lenta un momento
	await get_tree().create_timer(0.6, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().paused = true
	_end_screen("Has caído" if players.size() == 1 else "Habéis caído", Color(0.86, 0.22, 0.18), "", "caida")

func _on_level_completed() -> void:
	if _ended: return
	_ended = true
	earn(level.money_bonus)                          # bono por superar el nivel
	if not _someone_fell: Achievements.add(Saves.current, "flawless")
	if args.get_bool("log"): print("NIVEL SUPERADO %s t=%d s  abatidos=%d  dólares=%d  nivel_j1=%d  vida_min=%d" % [level.id, director.time, kills, run_money, player.progress.level, roundi(maxf(player.min_hp, 0.0) * 100)])
	if args.get_bool("log"): for q in players: print("ESTADISTICAS J%d %s" % [q.index + 1, world.stats_of(q.index)])
	if args.get_bool("log"): _log_players()
	# el avance de la campaña solo cuenta en la partida del anfitrión (D-10)
	if Saves.current != null and not Saves.current.levels_won.has(String(level.id)) and not is_guest():
		Saves.current.levels_won.append(String(level.id))
	_check_achievements.call_deferred()              # después de contar la baja del enemigo final (élite)
	Saves.save()
	announce("Nivel superado", 2.0)
	await _loot_time()
	get_tree().paused = true
	_end_screen("Nivel superado", UiKit.GOLD, Campaign.next_in_part(String(level.id)), "superado")

## Tras superar el nivel, LOOT_TIME s para recoger lo que han soltado el jefe y los últimos
## enemigos: no aparece nadie más, los que quedan caen (sueltan sus gemas), se deshacen las balas
## enemigas, se apagan los peligros del escenario y los jugadores ya no reciben daño.
const LOOT_TIME := 10.0
func _loot_time() -> void:
	for e in director.alive.duplicate():
		if is_instance_valid(e) and e.is_alive(): e.take_damage(Damage.new(1e9, 0.0))
	world.bullets.clear_enemy_bullets(Vector3.ZERO, 1e5)
	var hz := get_node_or_null("Hazards")
	if hz != null: hz.queue_free()
	for q in players: q.god = true
	var wait := LOOT_TIME
	if args.has("autonext") or args.has("autorestart"): wait = 2.5   # pruebas con bot: sin esperar
	director.loot_left = wait
	while director.loot_left > 0.0:
		await get_tree().create_timer(0.1).timeout     # se para con la pausa
		director.loot_left -= 0.1
	director.loot_left = 0.0

func _end_screen(title: String, accent: Color, next_id := "", result := "") -> void:
	var lines := _summary()
	var reports := _reports()
	if net_game != null:
		lines.append_array(net_game.gone_notes)       # quién se fue y cuándo
		if net_game.level_marks > 0:                   # para comentarlas antes de seguir
			lines.append(MenuKit.count(net_game.level_marks, "marca") + " en este nivel (F9 o LB+RB)")
	var s := Menus.EndScreen.new(title, lines, accent)
	if announcer != null: create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) 		.tween_property(announcer, "modulate:a", 0.0, 0.3)   # un aviso a medias asomaría por encima
	if not reports.is_empty() and not args.get_bool("no_report"): s.report = FallReport.panel(reports)
	# al registro de dificultad, solo si juega alguna persona en este PC (los bots y las simulaciones
	# lo llenarían de pruebas; el que sustituye a un PC que se fue no cuenta; `report_log=true` lo fuerza)
	var human := players.any(func(q: Player) -> bool: return not q.remote and not (q.input is BotInput))
	if result != "" and not reports.is_empty() and level != null and (human or args.get_bool("report_log")):
		FallReport.log_run(result, String(level.id), director.time if director != null else 0.0, reports)
	s.has_next = next_id != ""
	if is_guest(): s.waiting = "El anfitrión decide cómo seguir"   # en red, solo puede salir
	s.logs_button = net_game != null and net_game.guest_lost     # se fue alguien: el registro sirve
	s.next_level.connect(func() -> void: _next_level(next_id))
	s.restart.connect(_restart)
	s.quit.connect(_quit)
	add_child(s)
	if args.get_bool("halt_shots"):                       # pruebas: también la pantalla final
		if args.get_bool("quit_on_end"): await _halt_shot()  # (y con quit_on_end, sale después)
		else: _halt_shot()
	if args.get_bool("quit_on_end") and not (args.get_bool("autonext") and next_id != ""):   # simulaciones (tools/simular.py)
		print("FIN SIMULACION")
		get_tree().quit()
		return
	if args.get_bool("autonext") and next_id != "":           # pruebas: pasa solo al siguiente nivel
		await get_tree().create_timer(0.5, true, false, true).timeout
		_next_level(next_id)
		return
	if args.has("autorestart"):
		print("fin de partida: ", title)
		if args.get_bool("chain") and next_id == "":      # cadena (pruebas): al caer, la parte desde el principio
			GameSession.carry.clear()
		await get_tree().create_timer(args.get_float("autorestart"), true, false, true).timeout
		_restart()

## Progreso al empezar el nivel: el que viene del anterior de la parte (GameSession.carry) o,
## si se empieza a mitad de parte sin él (mapa de depuración o level=), el que se tendría:
## subidas de nivel automáticas (DEV_LEVELS_PER_STAGE por cada nivel anterior).
const DEV_LEVELS_PER_STAGE := 7
func _apply_carry() -> void:
	if level == null: return
	Difficulty.ramp_on = GameSession.carry.is_empty() and (Campaign.number_of(String(level.id)) <= 1 or args.get_bool("fresh"))
	if not GameSession.carry.is_empty():
		for q in players:
			if q.index < GameSession.carry.size(): GameSession.restore(q, GameSession.carry[q.index])
		if team != null:
			team.turn = GameSession.team_turn % players.size()
			team.xp = GameSession.team_xp
		return
	var stage := Campaign.number_of(String(level.id))
	if stage <= 1 or args.get_bool("fresh"): return
	for q in players:
		for k in DEV_LEVELS_PER_STAGE * (stage - 1):
			q.progress.gain_level()
			var opts := q.progress.roll_options(q.weapons, _rng)
			if not opts.is_empty(): q.progress.choose(SmartBot.pick(opts, q, _rng) if q.input is SmartBot else opts[_rng.randi() % opts.size()], q)
		q.progress.pending = 0
		q.rebuild_stats()
		q.health = q.data.max_health

## Lo que la tienda da al empezar (17-10-2026). Al empezar una parte (sin progreso que venga
## del nivel anterior): un objeto al azar (Mochila del expedicionario) y una segunda arma al
## azar (Armería). Al pasar al siguiente nivel de la parte: una subida de nivel (Diario de
## expedición).
func _shop_start() -> void:
	if GameSession.carry.is_empty():
		for q in players:
			if float(q.shop.get("start_item", 0.0)) > 0.0:
				var ups := q.progress.upgrade_pool.filter(func(u: UpgradeData) -> bool: return int(q.progress.passives.get(u.id, 0)) == 0)
				if not ups.is_empty():
					var u: UpgradeData = ups[_rng.randi() % ups.size()]
					q.progress.passives[u.id] = 1
					q.rebuild_stats()
			if float(q.shop.get("start_weapon", 0.0)) > 0.0 and q.weapons.weapons.size() < q.progress.weapon_slots:
				var ws := q.progress.weapon_pool.filter(func(w: WeaponData) -> bool: return q.weapons.get_weapon(w.id) == null)
				if not ws.is_empty(): q.weapons.add_weapon(ws[_rng.randi() % ws.size()])
	else:
		for q in players:
			if float(q.shop.get("head_start", 0.0)) > 0.0: q.progress.gain_level()

## Siguiente nivel de la parte: el progreso de cada jugador pasa con él (GameSession.carry).
func _next_level(id: String) -> void:
	if is_guest(): return                            # lo decide el anfitrión (llega con net_next)
	GameSession.carry.clear()
	for q in players: GameSession.carry.append(GameSession.snapshot(q))
	GameSession.team_xp = team.xp if team != null else 0.0
	GameSession.team_turn = team.turn if team != null else 0
	GameSession.level = StringName(id)
	if is_net_host(): net_game.send_next(id)
	Saves.save()
	get_tree().paused = false
	Engine.time_scale = 1.0
	_to_next_scene()

## Funde a negro (LevelCard.leave) y pasa al relato del siguiente nivel o, en pruebas, lo
## empieza sin relato (autonext=true).
func _to_next_scene() -> void:
	LevelCard.leave(self, func() -> void:
		if args.get_bool("autonext"): get_tree().reload_current_scene()
		else: get_tree().change_scene_to_file("res://scenes/relato.tscn"))

func _restart() -> void:
	if is_guest():                                   # en red, reintenta el anfitrión
		announce("Solo el anfitrión puede reintentar", 1.5)
		return
	if is_net_host(): net_game.send_restart()
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
	announcer.add_theme_font_override("font", MenuKit.font())     # la de los títulos (27-10-2026)
	announcer.add_theme_font_size_override("font_size", 46)
	announcer.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	announcer.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03))
	announcer.add_theme_constant_override("outline_size", 10)
	announcer.modulate.a = 0.0
	layer.add_child(announcer)

## Evolución (D-06): al abrir un baúl, la primera arma al nivel máximo cuyo objeto lleva el
## jugador se convierte en su evolución.
func _try_evolve(q: Player) -> void:
	if q == null or q.weapons == null: return
	var w := q.weapons.evolvable(q.progress.passives)
	if w == null: return
	var before := w.data.display_name
	q.weapons.evolve(w)
	announce("¡Evolución! %s → %s" % [before, w.data.display_name], 3.0)
	if args.get_bool("log"): print("EVOLUCION %s" % w.data.id)

func announce(text: String, seconds: float) -> void:
	announcer.text = text
	announcer.size.x = 0
	announcer.position.x = (get_viewport().get_visible_rect().size.x - announcer.get_minimum_size().x) * 0.5
	var tw := create_tween()
	tw.tween_property(announcer, "modulate:a", 1.0, 0.4)
	tw.tween_interval(seconds)
	tw.tween_property(announcer, "modulate:a", 0.0, 0.8)

func _make_input() -> PlayerInput:
	if args.get_str("bot", "") == "smart":
		return SmartBot.new(args.get_float("skill", 0.8))
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

## Efecto de prueba delante del jugador, cada 3 s (capturas y comparaciones):
## fx_demo=explosion|fire|acid|gas|dust|jet|frost|fireball|wave|death|death_big|beam|chain|tether|
## slash|stab|sigil|sweep|impact|thrown|vortex|boomerang|fissure|tentacle|
## flare|trap|telegraph|ooze|leap|erupt|chest|angles|levelup (el fogonazo se ve con weapons=thompson dummies=3).
## Empieza a los 2 s.
func _fx_demo(kind: String) -> void:
	var at := player.position + Vector3(2.5, 0, -1.0)
	var spawn := func() -> void:
		var dir := Vector3(1, 0, -0.4).normalized()
		match kind:
			"explosion":
				var fx := Explosion.new()
				fx.radius = 2.2
				fx.position = at
				world.fx.add_child(fx)
			"jet", "frost":
				var j := FlameJet.new().setup(player, world, dir, 4.5, 35.0, 0.0, 1.2, 1.0, 2.0, 0.0, {})
				j.frost = kind == "frost"
				if j.frost: j.zone_t = 0.0
				world.fx.add_child(j)
			"fireball":
				world.fx.add_child(Fireball.new().setup(world, player.position, dir, 6.0, 9.0, 0.5, 0.0, 0.9, 2.0, 0.0, {}))
			"wave":
				world.fx.add_child(Shockwave.new().setup(player, world, 4.5, 0.5, 0.0, 0.0, 0.0, {}))
			"death", "death_big":
				var big := kind == "death_big"
				var id := "acechador" if big else "pinguino"
				var root := VoxelBuilder.load_model("res://models/%s.json" % id)
				var fx := DeathBurst.new()
				fx.setup(id, 0.9 if big else 0.45, root, big)
				fx.position = at
				world.fx.add_child(fx)
				root.free()
			"beam":
				var b := Beam.new()
				b.setup(player.position + Vector3(0, 1.0, 0), dir, 7.0, 0.15, 0.3)
				world.fx.add_child(b)
			"chain":
				var pts: Array[Vector3] = [player.position, at, at + Vector3(2.0, 0, 1.5), at + Vector3(3.5, 0, -0.5)]
				world.fx.add_child(ChainBolt.new().setup(pts))
			"tether":
				world.fx.add_child(TetherBeam.new().setup(player, world, 0.0, 0.2, 0.3, 3.0, 8.0, 2.5, {}))
			"slash":
				var sl := Slash.new()
				sl.radius = 2.2
				sl.position = player.position
				world.fx.add_child(sl)
			"stab":
				world.fx.add_child(Stab.new().setup(player.position, at + Vector3(1.5, 0, 0)))
			"sigil":
				world.fx.add_child(Sigil.new().setup(world, at, 2.0, 2.6, 0.0, 1.0, 0.0, 1.0, {}))
			"impact":                                    # una ráfaga de impactos de varios aspectos
				for i in 8:
					var looks := [0, 6, 9, 12]
					get_tree().create_timer(i * 0.04).timeout.connect(func() -> void:
						world.bullets.impact(at + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2)), looks[i % 4]))
			"thrown":                                    # dinamita, Molotov y frasco en vuelo
				var looks := ["dinamita", "molotov", "frasco"]
				for i in 3:
					var te := ThrownExplosive.new()
					te.setup(world, player.position + Vector3(0, 1.0, 0), at + Vector3(i * 1.4 - 1.4, 0, i * 0.8), 1.4, 9.0, 2.0, 0.0,
						Color(0.45, 0.85, 0.2) if i == 2 else Color(1.0, 0.8, 0.3))
					te.configure(looks[i], 2.4, {}, 0.0, {})
					world.fx.add_child(te)
			"vortex":
				world.fx.add_child(Vortex.new().setup(world, player.position, at, 2.5, 2.4, 0.0, 0.4, 0.0, 2.6, {}))
			"boomerang":
				world.fx.add_child(Boomerang.new().setup(player, world, dir, 6.0, 7.0, 0.4, 0.0, 0.0, {}))
			"fissure":
				world.fx.add_child(Fissure.new().setup(world, player.position, dir, 6.0, 8.0, 0.6, 0.0, 0.0, {}))
			"tentacle":
				world.fx.add_child(TentacleSpike.new().setup(world, at, 1.4, 0.0, 0.0, {}))
			"flare":
				world.fx.add_child(Flare.new().setup(world, at, 2.6, 4.0))
			"trap":
				world.fx.add_child(BearTrap.new().setup(world, at + Vector3(1.5, 0, 0), 0.8, 5.0, 0.0, 0.5, {}))
			"telegraph":
				var tg := Telegraph.new()
				tg.setup(2.0, 1.5, Color(1.0, 0.36, 0.18, 0.7), true)
				tg.position = at
				world.fx.add_child(tg)
			"ooze":
				world.fx.add_child(EnemyZone.new().setup(world, at, 1.6, 2.8, 0.0, 0.0))
			"leap":
				VoxelFx.ground_hit(world.fx, at, 2.2, Color(0.6, 0.58, 0.55))
			"erupt":
				WadeSplash.burst(world.fx, at, 1.4, Color(0.45, 0.35, 0.25, 1.0), "")
			"chest":
				VoxelFx.puff(world.fx, at + Vector3(0, 0.5, 0), "sparkle", 0.6)
			"angles":
				var hz := Node3D.new()
				hz.position = at
				world.fx.add_child(hz)
				var pit := VoxelFx.ground(11, 1.6)
				pit.position.y = 0.04
				hz.add_child(pit)
				hz.add_child(VoxelFx.emitter("vortex_in", 1.7, false, false, Color(0.4, 1.0, 0.55)))
				get_tree().create_timer(2.8).timeout.connect(hz.queue_free)
			"levelup":
				VoxelFx.puff(player, player.global_position, "rise", 0.6, Color.WHITE, 1.4)
			"sweep":
				world.fx.add_child(SweepBeam.new().setup(player, world, 6.0, 0.3, 140.0, 0.0, 0.35, 2.6, {}))
			_:
				var z: int = {"fire": WeaponData.Zone.FIRE, "acid": WeaponData.Zone.ACID, "gas": WeaponData.Zone.GAS,
					"dust": WeaponData.Zone.DUST}.get(kind, WeaponData.Zone.FIRE)
				world.fx.add_child(DamageZone.new().setup(world, z, at, 1.8, 2.6, 0.0))
	if kind in ["tether", "stab", "trap"]:              # necesitan a quién morder
		var d := TrainingDummy.new().setup(world, "fragmento")
		d.position = at + Vector3(1.5, 0, 0)
		add_child(d)
	var t := Timer.new()
	t.wait_time = 3.0
	t.timeout.connect(spawn)
	add_child(t)
	get_tree().create_timer(2.0).timeout.connect(func() -> void: spawn.call(); t.start())

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

## Logros (D-32): récords de la partida y comprobación; los recién cumplidos se anuncian.
func _check_achievements() -> void:
	var save := Saves.current
	if save == null: return
	if director != null: Achievements.record(save, "best_time", int(director.time))
	var maxed := 0
	for q in players:
		if q.weapons == null: continue
		for w in q.weapons.weapons:
			if w.level >= w.data.max_level: maxed += 1
	Achievements.record(save, "maxed_weapons", maxed)
	_record_seen(save)
	var done := Achievements.check(save)
	for a in done:
		var reward := Achievements.reward_text(a)
		announce("Logro: %s%s" % [a.display_name, ("  ·  " + reward) if reward != "" else ""], 3.0)
		if args.get_bool("log"): print("LOGRO %s" % a.id)
	if not done.is_empty(): Saves.save()

## Biblioteca: el lugar, las armas y objetos que llevan los jugadores y los enemigos que
## están en pantalla. No guarda aquí: lo hace la partida al acabar o al salir.
func _record_seen(save: SaveData) -> void:
	if level != null: save.mark_seen("places", String(level.id))
	for q in players:
		if q.weapons != null:
			for w in q.weapons.weapons: save.mark_seen("weapons", String(w.data.id))
		if q.progress != null:
			for k in q.progress.passives: save.mark_seen("items", String(k))
	var view := get_viewport().get_visible_rect()
	for e in world.enemies:
		if not is_instance_valid(e) or not ("data" in e): continue
		var p: Vector3 = e.global_position
		if camera.is_position_behind(p) or not view.has_point(camera.unproject_position(p)): continue
		save.mark_seen("enemies", String(e.data.id))

func _process(delta: float) -> void:
	var t0 := Prof.start()
	_process_step(delta)
	Prof.stop("partida", t0)

func _process_step(delta: float) -> void:
	_t += delta
	if net_game != null: _watch_mark_pads(delta)
	if args.has("sim_time") and director != null and director.time >= args.get_float("sim_time") and not _ended:
		_ended = true                                  # banco de armas: corta a los N s de juego
		var rv := {"vida": 0.0, "cordura": 0.0}
		for k in player.received:
			rv.vida += player.received[k][0]; rv.cordura += player.received[k][1]
		print("BANCO abatidos=%d %s RECIBIDO %d %d crisis=%d" % [director.killed_total, world.stats_of(0), rv.vida, rv.cordura, player.sanity_state.crises])
		get_tree().quit()
		return
	if director != null and not _ended and int(director.time) > _rep_slot:
		_rep_slot = int(director.time)
		_report_sample()
	_ach_t += delta
	if _ach_t >= 1.0 and not _ended:
		_ach_t = 0.0
		_check_achievements()
	if players.size() > 1:                           # la cámara encuadra a los que siguen en pie
		var alive: Array[Node3D] = []
		for q in players:
			if not q.is_eliminated and not q.remote: alive.append(q)   # los derribados también (en red, solo los de este PC)
		if alive.is_empty() and net_game != null:      # en red, si los de este PC están eliminados, a los que siguen
			for q in players:
				if not q.is_eliminated: alive.append(q)
		if not alive.is_empty(): camera.targets = alive
	# tiempo jugado del hueco: en tiempo real, sin contar pausas ni la velocidad del juego
	if not get_tree().paused and not _ended: Saves.add_play_time(delta / maxf(Engine.time_scale, 0.001))
	if args.get_bool("debug") and fmod(_t, 0.5) < delta: print("t=%.1f jugador=%s" % [_t, player.global_position])
	# cada 30 s del director (21-10-2026: con fmod(time, 30) < delta casi nunca se escribía, porque
	# el director avanza con su propio paso y rara vez caía dentro del margen)
	if args.get_bool("log") and director != null and int(director.time / 30.0) > _log_slot:
		_log_slot = int(director.time / 30.0)
		print("t=%3d s  vivos=%d  abatidos=%d  nivel=%d  vida=%d  cordura=%d  balas=%d" % [director.time, director.alive.size(),
			kills, player.progress.level, player.health, player.sanity, world.bullets.count])
		if world.flow != null:                          # enemigos que no pueden llegar o se han atascado
			var lost := 0
			var stuck := 0
			for e: Enemy in director.alive:
				if e.data.ethereal or e.anchored: continue
				if not world.flow.reachable(Vector2(e.global_position.x, e.global_position.z)): lost += 1
				if e._detour_t > 0.0: stuck += 1
			print("         inalcanzables=%d  desatascándose=%d" % [lost, stuck])
	if args.get_bool("log") and director != null and director.final_target() != null:
		_final_alive += delta                           # el enemigo que cierra el nivel tarda: dónde está y cuánto le queda
		var f := director.final_target()
		if _final_alive > 30.0 and fmod(_final_alive, 10.0) < delta:
			var near := INF
			for q in players: near = minf(near, q.global_position.distance_to(f.global_position))
			print("         final=%s vida=%d%% pos=%.1f,%.1f,%.1f  jugador más cerca=%.1f m  alcanzable=%s  estado=%s  desatascándose=%s" % [f.data.id,
				roundi(f.health / (f.data.max_health * f.health_scale) * 100), f.global_position.x, f.global_position.y, f.global_position.z, near,
				world.flow == null or world.flow.reachable(Vector2(f.global_position.x, f.global_position.z)),
				f.behavior.get("state"), f._detour_t > 0.0])
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

# ---------------- red (hito 9.3a): lo que manda el anfitrión ----------------
## Siguiente nivel: el progreso de todos (como lo lleva el anfitrión) y el nivel.
func net_next(d: Dictionary) -> void:
	GameSession.carry = (d.get("carry") as Array).duplicate(true) if d.get("carry") is Array else []
	GameSession.team_xp = float(d.get("team_xp", 0.0))
	GameSession.team_turn = int(d.get("team_turn", 0))
	GameSession.level = StringName(String(d.get("level", GameSession.level)))
	Saves.save()
	get_tree().paused = false
	Engine.time_scale = 1.0
	_to_next_scene()

func net_restart() -> void:   # el PC de cada puesto ya viene puesto (NetGame.apply_seat_peers)
	Saves.save()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene.call_deferred()

func net_lost() -> void:
	_game_over()

## Se cerró la sala (el anfitrión cerró la partida o se perdió la conexión, hito 9.5b): lo
## conseguido ya está guardado (los dólares se apuntan al ganarlos); pantalla final con el
## motivo y el resumen, y de ahí al menú principal.
func net_closed(reason: String) -> void:
	if net_game != null and net_game.silence() > NetGame.QUIET:   # llevaba un rato sin noticias: se cayó
		reason = "Se ha perdido la conexión con el anfitrión"
	elif reason == "El anfitrión ha cerrado la sala":
		reason = "El anfitrión ha cerrado la partida"
	Saves.save()
	if args.get_bool("log"): print("RED cerrada: %s" % reason)
	Net.netlog.line("Pantalla final: %s" % reason)
	for n in [_pause, _halt_ui, get_node_or_null("NetLevelUp")]:
		if n != null and is_instance_valid(n): (n as Node).queue_free()
	_pause = null
	_halt_ui = null
	_menu_open = false
	for c in get_children():                          # la de "El anfitrión decide cómo seguir", si estaba
		if c is Menus.EndScreen: c.queue_free()
	_ended = true
	Engine.time_scale = 1.0
	get_tree().paused = true
	var lines := _summary()
	if Saves.current != null: lines.append("Ahora tienes %s $" % MenuKit.money(Saves.current.money))
	var s := Menus.EndScreen.new(reason, lines, Color(0.95, 0.55, 0.3))
	s.waiting = "Lo conseguido queda guardado en tu partida"
	s.leave_text = "Menú principal"
	s.logs_button = reason != "El anfitrión ha cerrado la partida"   # un corte: el registro sirve
	s.quit.connect(_quit)
	add_child(s)
	if args.get_bool("halt_shots"): _halt_shot()

## F1: recorre los estilos de esquive para compararlos.
const DODGE_STYLES: Array[String] = ["deslizar", "rodar", "plancha", "salto", "destello"]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F9 and net_game != null:
		net_mark()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F1:
		var cur := String(player.data.dodge_style.id) if player.data.dodge_style else "deslizar"
		var next := DODGE_STYLES[(DODGE_STYLES.find(cur) + 1) % DODGE_STYLES.size()]
		var style: DodgeStyle = load("res://data/dodges/%s.tres" % next)
		player.apply_dodge_style(style)
		announce("Esquive: " + style.display_name, 1.2)
		get_viewport().set_input_as_handled()
