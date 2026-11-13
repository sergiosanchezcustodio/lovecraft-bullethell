extends GutTest
## Hito 21.1: sonido propio de las armas de los personajes de la fase 20 (Pickman, Ward, Gilman,
## Tillinghast, Derby y Asenath; el de Kuranes es del 20.22).

const EVENTS := ["brush", "canvas_tear", "formula", "salts", "angle_hum", "angle_snap",
	"beyond_cool", "beyond_warm", "beyond_hot", "knock_3", "knock_2", "gaze", "dream", "dream_sleep"]

var world: CombatWorld
var heard: Array = []

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	heard = []
	var sfx := get_tree().root.get_node_or_null("Sfx")
	if sfx != null and not sfx.played.is_connected(_on_played): sfx.played.connect(_on_played)

func after_each() -> void:
	var sfx := get_tree().root.get_node_or_null("Sfx")
	if sfx != null and sfx.played.is_connected(_on_played): sfx.played.disconnect(_on_played)

func _on_played(ev: String, _pos: Variant) -> void:
	heard.append(ev)

func _w(id: String) -> WeaponData:
	return load("res://data/weapons/%s.tres" % id)

func test_cada_sonido_existe() -> void:
	var defs: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/sfx.json")) as Dictionary)["eventos"]
	for ev in EVENTS:
		assert_true(defs.has(ev), ev)
		for f in (defs.get(ev, {}) as Dictionary).get("files", []):
			assert_true(ResourceLoader.exists("res://resources/sfx/" + f), f)

func test_las_entregas_de_la_fase_20_no_suenan_dos_veces() -> void:
	# el lienzo, las sales, la máquina y el sueño suenan en su sitio con lo suyo: al disparar, nada
	for id in ["lienzos", "sales_esenciales", "maquina_mas_alla", "ensueno_celephais", "serannian"]:
		assert_eq(WeaponSystem.sound_of(_w(id)), "", id)
	assert_eq(WeaponSystem.sound_of(_w("angulos_imposibles")), "angle_hum")
	assert_eq(WeaponSystem.sound_of(_w("webly")), "shot_revolver", "las demás, como siempre")

func test_la_maquina_suena_segun_el_calor() -> void:
	assert_eq(WeaponSystem.beyond_sound(1.0), "beyond_cool")
	assert_eq(WeaponSystem.beyond_sound(2.0), "beyond_warm")
	assert_eq(WeaponSystem.beyond_sound(WeaponSystem.BEYOND_HEAT_MAX), "beyond_hot")

func test_derby_llama_tres_veces_y_asenath_dos() -> void:
	var p := Player.new().setup(load("res://data/characters/derby.tres"), BotInput.new("idle"), Color.YELLOW)
	world.add_child(p)
	world.add_player(p)
	p.world = world
	p.weapons = WeaponSystem.new().setup(p, world)
	p.add_child(p.weapons)
	var w: WeaponSystem.Weapon = p.weapons.add_weapon(_w("el_umbral"))
	assert_eq(p.weapons._fire_sound(w), "swing", "Edward, el tajo")
	p.swap_form()
	assert_true(heard.has("knock_3"), "pasa a Asenath: tres golpes")
	assert_eq(p.weapons._fire_sound(w), "gaze", "Asenath, las miradas")
	p.swap_form()
	assert_true(heard.has("knock_2"), "vuelve Edward: dos")
