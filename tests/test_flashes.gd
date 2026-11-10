extends GutTest
## Hito 19.4: «Destellos reducidos» atenúa también los efectos de la fase 18.

func after_each() -> void:
	Settings._overrides.erase("flashes")
	Flashes.refresh()

func _energy(id: String) -> float:
	return float(FxShade.material(id).get_shader_parameter("energy"))

func test_destellos_reducidos_atenuan_el_sombreador_de_efectos() -> void:
	Settings._overrides["flashes"] = 1
	Flashes.refresh()
	var blast := _energy("blast")
	var wall := _energy("wall")
	assert_false(Flashes.reduced())
	Settings._overrides["flashes"] = 0
	Flashes.refresh()
	assert_true(Flashes.reduced())
	assert_almost_eq(_energy("blast"), blast * Flashes.DIM, 0.001, "el fogonazo, al mínimo")
	assert_almost_eq(_energy("wall"), wall * lerpf(1.0, Flashes.DIM, 0.5), 0.001, "la cortina, a medias")
	Settings._overrides["flashes"] = 1
	Flashes.refresh()
	assert_almost_eq(_energy("blast"), blast, 0.001, "vuelve al cambiar la opción")
