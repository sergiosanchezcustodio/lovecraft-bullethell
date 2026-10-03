extends GutTest
## Comportamientos de la fase 4: picado, embestida y disfraz.

func _enemy(id: String) -> Enemy:
	var e := Enemy.new()
	e.data = load("res://data/enemies/%s.tres" % id)
	return e

func test_la_embestida_pega_mas_fuerte() -> void:
	var e := _enemy("shoggoth_esclavo")
	var b := ChargeBehavior.new()
	var normal := b.contact_damage(e).physical
	b.state = ChargeBehavior.State.CHARGE
	assert_almost_eq(b.contact_damage(e).physical, normal * float(e.data.param("charge_mult", 1.6)), 0.01)
	e.free()

func test_el_alado_solo_toca_abajo() -> void:
	var e := _enemy("antiguo_alado")
	var b := DiveBehavior.new()
	e.position.y = 2.6
	assert_false(b.touches(e))
	e.position.y = 0.2
	assert_true(b.touches(e))
	e.free()

func test_el_mimetico_no_toca_hasta_revelarse() -> void:
	var e := _enemy("shoggoth_mimetico")
	var b := MimicBehavior.new()
	assert_false(b.touches(e))
	assert_false(b.can_shoot(e))
	b.revealed = true
	assert_true(b.touches(e))

func test_los_unicos_no_salen_en_oleadas() -> void:
	for l: LevelData in DebugOptions.list_resources("res://data/levels"):
		for d in l.pool: assert_false(d.unique, "%s: %s es único" % [l.id, d.id])
		if l.final_enemy != null and l.number >= 2: assert_true(l.final_enemy.unique, String(l.id))
