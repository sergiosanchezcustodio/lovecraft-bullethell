extends GutTest
## Conjuntos del vestuario (fase 14, hito 14.8).

func _save(money: int) -> SaveData:
	var s := SaveData.new()
	s.money = money
	return s

func test_cada_prenda_existe_y_va_en_su_hueco() -> void:
	assert_gt(OutfitSets.all().size(), 10)
	for s: Dictionary in OutfitSets.all():
		assert_gte((s.pieces as Dictionary).size(), 3, "%s: al menos tres prendas" % s.id)
		for k: String in s.pieces:
			var o := OutfitData.find(String(s.pieces[k]))
			assert_not_null(o, "%s: %s" % [s.id, s.pieces[k]])
			if o != null: assert_eq(OutfitData.KEYS[o.slot], k, "%s: %s va en %s" % [s.id, o.id, k])

func test_lo_que_falta_cuesta_menos_que_por_separado() -> void:
	var s := OutfitSets.find("buzo")
	var sv := _save(0)
	var sum := 0
	for k: String in s.pieces: sum += OutfitData.find(String(s.pieces[k])).price
	assert_lt(OutfitSets.price(sv, s), sum)
	sv.outfits.append("casco_buzo")
	assert_eq(OutfitSets.missing(sv, s).size(), 2)
	assert_lt(OutfitSets.price(sv, s), sum - OutfitData.find("casco_buzo").price)

func test_comprar_el_conjunto_da_lo_que_falta() -> void:
	var s := OutfitSets.find("cultista")
	var sv := _save(999999)
	sv.outfits.append("collar_signo")
	var p := OutfitSets.price(sv, s)
	assert_true(OutfitSets.buy(sv, s))
	assert_eq(sv.money, 999999 - p)
	assert_true(OutfitSets.is_complete(sv, s))
	assert_eq(sv.outfits.count("collar_signo"), 1, "lo que ya tenía no se compra otra vez")
	assert_false(OutfitSets.buy(sv, s), "ya está completo")

func test_sin_dinero_no_se_compra() -> void:
	var s := OutfitSets.find("ganster")
	var sv := _save(10)
	assert_false(OutfitSets.buy(sv, s))
	assert_eq(sv.money, 10)

func test_el_conjunto_puesto() -> void:
	var worn := OutfitSets.as_worn(OutfitSets.find("buzo"))
	assert_eq(OutfitSets.worn_name(worn), "Buzo")
	worn["acc"] = "pipa"                               # con algo más, sigue siendo el conjunto
	assert_eq(OutfitSets.worn_name(worn), "Buzo")
	worn.erase("feet")
	assert_eq(OutfitSets.worn_name(worn), "")

func test_la_prenda_que_completa_un_conjunto() -> void:
	var sv := _save(0)
	sv.outfits.append_array(["casco_buzo", "traje_buzo"])
	assert_has(OutfitSets.completes(sv, "botas_buzo"), "Buzo")
	assert_does_not_have(OutfitSets.completes(sv, "casco_buzo"), "Buzo", "ya la tiene")
	assert_does_not_have(OutfitSets.completes(sv, "fez"), "Buzo")

func test_niveles_superados_con_el_conjunto() -> void:
	var sv := _save(0)
	var buzo := {"head": "casco_buzo", "body": "traje_buzo", "feet": "botas_buzo"}
	assert_eq(OutfitSets.stat_key(buzo), "set_buzo")
	assert_eq(OutfitSets.stat_key({"head": "casco_buzo"}), "", "a medias no cuenta")
	assert_eq(OutfitSets.levels_with(sv, buzo), 0)
	Achievements.add(sv, OutfitSets.stat_key(buzo), 2)
	assert_eq(OutfitSets.levels_with(sv, buzo), 2)
	assert_eq(OutfitSets.levels_with(null, buzo), 0)
	var back := SaveData.from_dict(sv.to_dict())
	assert_eq(OutfitSets.levels_with(back, buzo), 2, "se guarda con la partida")
