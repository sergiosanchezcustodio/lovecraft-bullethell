extends GutTest
## Clima estético (hito 2.8, D-33): ajustes de data/weather, rachas de viento, rayos y qué
## capas monta cada clima. Solo estético: no toca a nadie.

func test_los_climas_cargan_y_el_nivel_1_nieva() -> void:
	var list := DebugOptions.list_resources("res://data/weather")
	assert_gte(list.size(), 6)
	for wd: WeatherData in list: assert_ne(wd.display_name, "", String(wd.id))
	var lv: LevelData = load("res://data/levels/p1_n1.tres")
	assert_not_null(lv.weather)
	assert_eq(lv.weather.precip, WeatherData.Precip.SNOW)

func test_las_rachas_refuerzan_el_viento_sin_bajar_de_la_base() -> void:
	var wd := WeatherData.new()
	wd.wind = 2.0
	wd.gusts = 0.8
	var lo := INF
	var hi := 0.0
	for i in 400:
		var w := wd.wind_at(i * 0.05)
		lo = minf(lo, w)
		hi = maxf(hi, w)
	assert_gte(lo, 2.0 - 0.001)
	assert_gt(hi, 3.0, "alguna racha fuerte en 20 s")
	assert_eq(wd.wind_at(3.3), wd.wind_at(3.3), "sin azar: igual para todos")

func test_el_rayo_destella_y_se_apaga() -> void:
	assert_eq(Weather.flash_at(-1.0), 0.0)
	assert_almost_eq(Weather.flash_at(0.0), 1.0, 0.001)
	assert_gt(Weather.flash_at(0.33), 0.5, "tercer destello")
	assert_eq(Weather.flash_at(0.6), 0.0)

func _weather(id: String) -> Weather:
	var cam := GameCamera.new()
	add_child_autofree(cam)
	var env := Atmosphere.make_environment()
	var w := Weather.new().setup(load("res://data/weather/%s.tres" % id), cam, env)
	add_child_autofree(w)
	return w

func test_la_nevada_monta_nieve_ventisca_niebla_y_nubes() -> void:
	var w := _weather("nevada")
	assert_not_null(w._precip)
	assert_not_null(w._drift)
	assert_eq(w._mist.size(), 2)
	assert_not_null(w._clouds)
	assert_null(w._flash, "sin rayos")

func test_la_tormenta_lanza_rayos() -> void:
	var w := _weather("tormenta")
	assert_not_null(w._flash)
	assert_not_null(w._extra, "salpicaduras")
	for i in 60 * 25: w._process(1.0 / 60.0)
	assert_gte(w.lightning_count, 1)

func test_la_niebla_densa_no_precipita() -> void:
	var w := _weather("niebla")
	assert_null(w._precip)
	assert_eq(w._mist.size(), 2)

func test_el_clima_reducido_lleva_menos_particulas() -> void:
	var cam := GameCamera.new()
	add_child_autofree(cam)
	var wd: WeatherData = load("res://data/weather/ventisca.tres")
	var full := Weather.new().setup(wd, cam, null, 1.0)
	add_child_autofree(full)
	var half := Weather.new().setup(wd, cam, null, 0.5)
	add_child_autofree(half)
	assert_lt(half._precip.amount, full._precip.amount)
