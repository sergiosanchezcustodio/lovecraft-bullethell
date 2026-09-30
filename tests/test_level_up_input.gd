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
