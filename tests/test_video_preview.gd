extends GutTest
## Hito 20.12: la vista previa de la pestaña Vídeo elige la miniatura que de verdad se vería.

func after_each() -> void:
	for k in ["quality", "weapon_fx", "weather", "brightness"]: Settings._overrides.erase(k)

func test_la_calidad_pone_tope_a_los_efectos() -> void:
	assert_eq(VideoPreview.effective_fx(0, 2), 0, "Baja: solo mínimos")
	assert_eq(VideoPreview.effective_fx(1, 3), 1, "Media en automático: rebajados")
	assert_eq(VideoPreview.effective_fx(2, 3), 2, "Alta en automático, con un jugador: enteros")
	assert_eq(VideoPreview.effective_fx(3, 1), 1)

func test_hay_miniatura_para_todo() -> void:
	for q in 4:
		for w in 4: assert_true(ResourceLoader.exists(VideoPreview.video_file(q, w)), VideoPreview.video_file(q, w))
	for c in 3: assert_true(ResourceLoader.exists(VideoPreview.weather_file(c)), VideoPreview.weather_file(c))

func test_cambia_con_los_ajustes() -> void:
	Settings._overrides["quality"] = 3
	Settings._overrides["weapon_fx"] = 2
	var p := VideoPreview.new()
	add_child_autofree(p)
	var a: Texture2D = p._tex.texture
	assert_not_null(a)
	Settings._overrides["quality"] = 0
	Settings._overrides["brightness"] = 6
	p.refresh(false)
	assert_ne(p._tex.texture, a, "otra miniatura con otra calidad")
	assert_gt(float(p._mat.get_shader_parameter("gamma")), 1.0, "y el brillo encima")
