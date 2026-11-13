extends GutTest
## Hito 20.9: la portada según lo jugado (TitleProgress).

func _ids(part: int) -> Array:
	var out: Array = []
	for l: Dictionary in Campaign.levels():
		if int(l.part) == part: out.append(String(l.id))
	return out

func test_sin_nada() -> void:
	assert_eq(TitleProgress.fraction([]), 0.0)
	assert_eq(TitleProgress.part([]), 0)
	assert_almost_eq(TitleProgress.lit([]), TitleProgress.LIT_MIN, 0.001)

func test_una_parte_entera_pasa_a_la_siguiente() -> void:
	var won := _ids(0)
	assert_eq(TitleProgress.part(won), 1, "las montañas enteras: el cielo de Innsmouth")
	assert_eq(TitleProgress.part(won.slice(0, 2)), 0, "a medias: aún el de las montañas")

func test_toda_la_campana() -> void:
	var won: Array = []
	for p in 3: won.append_array(_ids(p))
	assert_eq(TitleProgress.fraction(won), 1.0)
	assert_eq(TitleProgress.part(won), 3)
	assert_almost_eq(TitleProgress.lit(won), 1.0, 0.001)
	assert_true(TitleProgress.SKIES[3].has("sky_tint"))

func test_niveles_fuera_de_la_campana_no_cuentan() -> void:
	assert_eq(TitleProgress.fraction(["desafio:p1_n4", "pesca"]), 0.0)
