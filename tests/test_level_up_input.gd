extends GutTest
## Navegación del menú de subida de nivel con el mando (30-09-2026): la cruceta abajo es
## también "mapa" y JoypadInput no la da como movimiento; el menú la lee aparte.

var _buttons := {}
var _axes := {}

func _pad() -> JoypadInput:
	var j := JoypadInput.new(0)
	j.button = func(_d: int, b: JoyButton) -> bool: return _buttons.get(b, false)
	j.axis = func(_d: int, a: JoyAxis) -> float: return _axes.get(a, 0.0)
	return j

func before_each() -> void:
	_buttons.clear()
	_axes.clear()

func test_cruceta_abajo_y_arriba() -> void:
	var j := _pad()
	_buttons[JOY_BUTTON_DPAD_DOWN] = true
	j.update(0.016)
	assert_eq(CoopLevelUp.nav_dir(j), 1, "cruceta abajo baja")
	_buttons.clear()
	_buttons[JOY_BUTTON_DPAD_UP] = true
	j.update(0.016)
	assert_eq(CoopLevelUp.nav_dir(j), -1, "cruceta arriba sube")

func test_stick_en_diagonal_cuenta_si_domina_la_vertical() -> void:
	var j := _pad()
	_axes[JOY_AXIS_LEFT_Y] = 0.8
	_axes[JOY_AXIS_LEFT_X] = 0.5
	j.update(0.016)
	assert_eq(CoopLevelUp.nav_dir(j), 1)
	_axes[JOY_AXIS_LEFT_Y] = 0.3
	_axes[JOY_AXIS_LEFT_X] = 0.9
	j.update(0.016)
	assert_eq(CoopLevelUp.nav_dir(j), 0, "casi horizontal: nada")

func test_mantener_repite_y_soltar_para() -> void:
	var p := Player.new()
	p.input = _pad()
	var o := PlayerProgress.Option.new()
	o.kind = PlayerProgress.Option.Kind.PASSIVE
	o.upgrade = load("res://data/upgrades/vida.tres")
	var opts: Array[PlayerProgress.Option] = [o, o, o]
	var menu := CoopLevelUp.new([{"player": p, "options": opts, "title": "t"}] as Array[Dictionary], Callable(), true)
	add_child_autofree(menu)
	var pk: CoopLevelUp.Picker = menu._pickers[0]
	_buttons[JOY_BUTTON_DPAD_DOWN] = true
	menu._process(0.016)
	assert_eq(pk.cursor, 1, "baja al pulsar, sin esperar")
	for i in 20: menu._process(0.016)                 # 0,32 s: aún no repite
	assert_eq(pk.cursor, 1)
	for i in 10: menu._process(0.016)                 # pasa de 0,38 s: repite
	assert_eq(pk.cursor, 2)
	_buttons.clear()
	for i in 40: menu._process(0.016)
	assert_eq(pk.cursor, 2, "suelto: no se mueve")
	p.free()

## Tragaperras: no se puede elegir con los rodillos girando; confirmar los para.
func test_reels_must_stop_before_choosing() -> void:
	var o := PlayerProgress.Option.new()
	o.kind = PlayerProgress.Option.Kind.NEW_WEAPON
	o.weapon = load("res://data/weapons/webly.tres")
	var opts: Array[PlayerProgress.Option] = [o, o, o]
	var pk := CoopLevelUp.Picker.new(null, opts, "Nivel 2", true, "CUL", CoopLevelUp.filler())
	add_child_autofree(pk)
	assert_false(pk.settled(), "gira al abrirse")
	pk.spin(0.6)
	assert_false(pk.settled(), "las tarjetas siguen girando")
	pk.spin(1.0)
	assert_true(pk.settled(), "todo parado tras REEL_STOPS")
	var pk2 := CoopLevelUp.Picker.new(null, opts, "Nivel 2", true, "CUL", CoopLevelUp.filler())
	add_child_autofree(pk2)
	pk2.settle()
	assert_true(pk2.settled(), "confirmar lo para todo")

## Cartas del tarot (tienda, 17-10-2026): LB descarta la opción marcada; gira otra que no estaba
## y lo descartado ya no vuelve a salir.
func test_lb_descarta_la_opcion_marcada() -> void:
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), _pad(), Color.YELLOW)
	add_child_autofree(p)
	for up: UpgradeData in DebugOptions.list_resources("res://data/upgrades"): p.progress.upgrade_pool.append(up)
	p.shop = {"banish": 1.0}
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var opts := p.progress.roll_options(p.weapons, rng, 3)
	var menu := CoopLevelUp.new([{"player": p, "options": opts, "title": "t"}] as Array[Dictionary], Callable(), true)
	add_child_autofree(menu)
	var pk: CoopLevelUp.Picker = menu._pickers[0]
	pk.settle()
	var gone := PlayerProgress.key_of(pk.options[0])
	var others := [PlayerProgress.key_of(pk.options[1]), PlayerProgress.key_of(pk.options[2])]
	_buttons[JOY_BUTTON_LEFT_SHOULDER] = true
	menu._t = 1.0
	menu._process(0.016)
	assert_eq(p.banishes_left(), 0, "gastado")
	assert_true(p.progress.banished.has(gone))
	assert_ne(PlayerProgress.key_of(pk.options[0]), gone, "otra en su lugar")
	assert_false(PlayerProgress.key_of(pk.options[0]) in others, "y no repite las que ya estaban")
	_buttons.clear()
	menu._process(0.016)
	pk.settle()
	_buttons[JOY_BUTTON_LEFT_SHOULDER] = true
	menu._process(0.016)
	assert_eq(p.progress.banished.size(), 1, "sin descartes, LB no hace nada")
