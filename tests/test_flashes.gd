extends GutTest
## Hito 19.4: «Destellos reducidos» atenúa también los efectos de la fase 18.

func after_each() -> void:
	Settings._overrides.erase("flashes")
	Settings._overrides.erase("bullet_palette")
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

func _sat(id: String) -> float:
	var tex := FxShade.material(id).get_shader_parameter("ramp") as GradientTexture1D
	var cs := tex.gradient.colors
	return cs[cs.size() - 1].s

func test_alto_contraste_apaga_y_quita_color_a_los_efectos() -> void:
	Settings._overrides["bullet_palette"] = 0
	Flashes.refresh()
	var e := _energy("blast")
	var s := _sat("blast")
	assert_false(Flashes.skip_glint("glint_gold"))
	Settings._overrides["bullet_palette"] = 1
	Flashes.refresh()
	assert_almost_eq(_energy("blast"), e * Flashes.SOFT, 0.001, "menos brillo")
	assert_lt(_sat("blast"), s * 0.6, "hacia el gris")
	assert_true(Flashes.skip_glint("glint_gold"), "sin el destello dorado de las evoluciones")
	assert_false(Flashes.skip_glint("crack"), "el restallido, solo con destellos reducidos")
	var c := Flashes.color(Color(1.0, 0.85, 0.2))
	assert_lt(c.s, 0.5, "las estelas, hacia el gris")
