extends GutTest
## Hito 16.27: tabla de daño por arma en la pausa.

func test_ordena_y_reparte() -> void:
	var w := CombatWorld.new()
	add_child_autofree(w)
	w.record_damage(&"J1:webly", 100.0)
	w.clock = 10.0
	w.record_damage(&"J1:granada", 300.0)        # cogida a los 10 s
	w.record_kill(&"J1:granada")
	w.record_damage(&"J2:webly", 999.0)          # de otro jugador: no cuenta
	w.clock = 20.0
	var t := w.table_of(0)
	assert_eq(t.size(), 2)
	assert_eq(t[0].id, "granada")
	assert_eq(t[0].kills, 1)
	assert_almost_eq(float(t[0].share), 0.75, 0.001)
	assert_almost_eq(float(t[0].dps), 30.0, 0.001, "desde que hizo daño por primera vez")
	assert_almost_eq(float(t[1].dps), 5.0, 0.001)

func test_la_pausa_tiene_la_tabla() -> void:
	var m := Menus.PauseMenu.new()
	add_child_autofree(m)
	await get_tree().process_frame
	var names: Array = []
	for b in m._buttons: names.append(b.text)
	assert_has(names, "Daño de la partida")
