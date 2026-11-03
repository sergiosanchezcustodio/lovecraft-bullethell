extends GutTest
## Grados de locura (hito 16.14): datos, grados que se suman, apertura y el escudo de icor.

var _was_grade := 0
var _was_enabled := false

func before_each() -> void:
	_was_grade = GameSession.madness
	_was_enabled = Madness.enabled

func after_each() -> void:
	Madness.set_grade(_was_grade)
	Madness.enabled = _was_enabled

func test_cinco_grados_con_texto() -> void:
	assert_eq(Madness.grades().size(), Madness.MAX)
	for g in range(1, Madness.MAX + 1):
		var x := Madness.info(g)
		assert_false(x.is_empty(), "grado %d" % g)
		assert_ne(String(x.get("text", "")), "")
		assert_string_contains(Madness.title(g), String(x.roman))

func test_los_grados_se_suman() -> void:
	assert_eq(Madness.value("enemy_speed", 0), 1.0)
	assert_almost_eq(Madness.value("enemy_speed", 1), 1.12, 0.001)
	assert_almost_eq(Madness.value("enemy_speed", 5), 1.12 * 1.08, 0.001)
	assert_eq(Madness.value("enemy_health", 3), 1.0)
	assert_almost_eq(Madness.value("enemy_health", 4), 1.25, 0.001)
	assert_gt(Madness.value("money", 5), Madness.value("money", 4))
	assert_eq(Madness.chance("ward", 1), 0.0)
	assert_eq(Madness.chance("ward", 2), 0.2)
	assert_eq(Madness.chance("ward", 5), 0.3, "el grado más alto que la nombra")
	assert_eq(Madness.chance("split", 2), 0.0)
	assert_eq(Madness.chance("split", 3), 0.25)

func test_solo_en_la_campana() -> void:
	Madness.set_grade(4)
	Madness.enabled = false
	assert_eq(Madness.grade(), 0)
	assert_eq(Pacts.value("enemy_health"), 1.0)
	Madness.enabled = true
	assert_eq(Madness.grade(), 4)
	assert_almost_eq(Pacts.value("enemy_health"), 1.25, 0.001, "las palancas de los pactos")

func test_se_abren_al_vencer_a_cthulhu() -> void:
	var s := SaveData.new()
	assert_eq(Madness.unlocked(s), 0)
	s.levels_won.append("p3_n5")
	assert_eq(Madness.unlocked(s), 1, "campaña acabada: el grado I")
	Madness.record_win(s, "p3_n5", 1)
	assert_eq(Madness.unlocked(s), 2)
	Madness.record_win(s, "p2_n3", 4)
	assert_eq(Madness.unlocked(s), 2, "cuenta el de Cthulhu")
	Madness.record_win(s, "p3_n5", 5)
	Madness.record_win(s, "p3_n5", 2)
	assert_eq(Madness.best(s, "p3_n5"), 5, "se queda el mejor")
	assert_eq(Madness.unlocked(s), Madness.MAX)
	var all := SaveData.new()
	all.unlock_all = true
	assert_eq(Madness.unlocked(all), Madness.MAX)

func test_el_escudo_para_el_primer_golpe() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var e := Enemy.new().setup(load("res://data/enemies/pinguino.tres"), world, null)
	world.add_child(e)
	var hp := e.health
	e.set_ward(1)
	var d := Damage.new()
	d.physical = 5.0
	e.take_damage(d)
	assert_eq(e.health, hp, "lo para el escudo")
	assert_eq(e.ward, 0)
	assert_eq(e.net_flags2() & 4, 0)
	e.take_damage(d)
	assert_lt(e.health, hp, "el segundo, no")
	e.set_ward(1)
	assert_ne(e.net_flags2() & 4, 0, "viaja en la foto")
