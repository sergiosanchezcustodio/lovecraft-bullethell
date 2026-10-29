extends GutTest
## Consejos de la primera partida y leyenda de los avisos (hito 13.3).

const WHENS := ["move", "dodge", "pause", "sheet", "gem", "levelup", "sanity", "chest", "elite", "final", "down"]

func test_los_datos_cargan_y_cada_consejo_tiene_su_disparo() -> void:
	var t := Tips.new(null)
	assert_true(t._tips.size() >= 10)
	var ids := {}
	for tip: Dictionary in t._tips:
		assert_true(WHENS.has(String(tip.when)), "disparo conocido: %s" % tip.when)
		assert_false(ids.has(tip.id), "id repetido: %s" % tip.id)
		ids[tip.id] = true
		assert_true(String(tip.text).length() > 10)
	for k in ["fisico", "mental", "mixto", "aparece", "grieta"]:
		assert_true(t._warnings.has(k), "leyenda de %s" % k)
	t.free()

func test_tipo_de_aviso_por_su_color() -> void:
	var cases := [
		[Telegraph.enemy(1.0, 1.0, Color(Damage.COLOR_PHYSICAL, 0.7)), "fisico"],
		[Telegraph.enemy(1.0, 1.0, Color(Damage.COLOR_MENTAL, 0.7)), "mental"],
		[Telegraph.enemy(1.0, 1.0, Color(Damage.color_for(Damage.Kind.MIXED), 0.7)), "mixto"],
		[Telegraph.enemy(1.0, 1.0, Color(0.35, 0.75, 0.85, 0.7), false), "aparece"],
		[Telegraph.new().setup(1.0, 1.0, Color(1, 0.36, 0.18)), ""],     # de un arma: sin leyenda
	]
	for c in cases:
		assert_eq(Tips.warning_kind(c[0]), c[1])
		(c[0] as Telegraph).free()
	var g := Telegraph.new().setup(1.0, 1.0, Color(0.35, 0.9, 0.5))
	g.legend = &"grieta"
	assert_eq(Tips.warning_kind(g), "grieta")
	g.free()

func test_cada_aviso_nuevo_se_anuncia() -> void:
	var got: Array = []
	Telegraph.on_shown = func(t: Telegraph) -> void: got.append(t)
	var t := Telegraph.enemy(1.0, 5.0, Color(Damage.COLOR_PHYSICAL, 0.7))
	add_child_autofree(t)
	Telegraph.on_shown = Callable()
	assert_eq(got.size(), 1)
	assert_true(bool(Settings.get_value("tips")), "los consejos salen por defecto")
