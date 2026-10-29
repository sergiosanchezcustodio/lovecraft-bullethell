extends GutTest
## El escenario cambia durante el nivel (hito 12.13, D-41): la marea del arrecife (que frena), la
## ventisca del paso que se cierra y R'lyeh que se inclina (solo la cámara).

## Agua en x de 0 a 3 m (rejilla de 0,25 m de -5 a 5) y la marea: la distancia a ella.
func _tide_map() -> ObstacleMap:
	var o := ObstacleMap.new()
	var n := 40
	var w := PackedByteArray()
	var t := PackedByteArray()
	w.resize(n * n)
	t.resize(n * n)
	for j in n:
		for i in n:
			var x := -5.0 + (i + 0.5) * 0.25
			var d := maxf(0.0, -x) if x < 0.0 else maxf(0.0, x - 3.0)
			w[j * n + i] = 255 if d == 0.0 else 0
			t[j * n + i] = mini(int(round(d * 16.0)), 255)
	o._water = w
	o._tide = t
	o._n = n
	o._cell = 0.25
	o._origin = Vector2(-5, -5)
	return o

func test_cada_cambio_sube_entre_from_y_to() -> void:
	var c := {"from": 0.2, "to": 0.8}
	assert_eq(Ambient.change_k(c, 10.0, 240.0), 0.0, "al principio, nada")
	assert_between(Ambient.change_k(c, 120.0, 240.0), 0.4, 0.6, "a la mitad, a medias")
	assert_eq(Ambient.change_k(c, 230.0, 240.0), 1.0, "antes del final, del todo")
	assert_eq(Ambient.change_k(c, 300.0, 240.0), 1.0, "y se queda")

func test_la_marea_cubre_lo_que_esta_cerca_del_agua() -> void:
	var o := _tide_map()
	assert_eq(o.water_at(Vector2(-0.6, 0)), 0.0, "con la marea baja, seco")
	o.tide_level = 1.0
	assert_gt(o.water_at(Vector2(-0.6, 0)), 0.5, "a 0,6 m del agua, ya bajo ella: frena")
	assert_gt(o.water_at(Vector2(3.5, 0)), 0.5, "por los dos lados")
	assert_eq(o.water_at(Vector2(-2.0, 0)), 0.0, "a 2 m, aún seco")
	assert_eq(o.water_at(Vector2(1.5, 0)), 1.0, "el agua de siempre sigue")

func test_el_mapa_de_la_marea_del_arrecife_encaja() -> void:
	var o := ObstacleMap.new()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/arenas/arrecife.json"))
	assert_true(o.load_mask(data.mask))
	var c: Dictionary = (Ambient.config().arenas as Dictionary).arrecife.changes.tide
	assert_true(o.load_tide(String(c.file)), "mismo tamaño que el agua")
	assert_not_null(o.tide_texture())
	var bad := ObstacleMap.new()
	assert_false(bad.load_tide(String(c.file)), "sin agua no hay marea")

func test_la_ventisca_se_cierra_sin_rehacer_las_particulas() -> void:
	var cam := GameCamera.new()
	add_child_autofree(cam)
	var env := Atmosphere.make_environment()
	var fog0 := env.fog_density
	var w := Weather.new().setup(load("res://data/weather/ventisca_paso.tres"), cam, env)
	add_child_autofree(w)
	var precip := w._precip
	w.set_intensity(0.0, 0.1)
	assert_almost_eq(w._precip.amount_ratio, 0.1, 0.001, "al principio, unos copos")
	assert_almost_eq(w._drift.amount_ratio, 0.1, 0.001)
	assert_almost_eq(env.fog_density, fog0, 0.0001, "y la niebla de siempre")
	w.set_intensity(1.0, 0.1)
	assert_eq(w._precip.amount_ratio, 1.0, "al final, toda la nieve")
	assert_almost_eq(env.fog_density, w.data.fog_density, 0.0001)
	assert_eq(w._precip, precip, "las mismas partículas")

func test_el_paso_y_los_demas_cambios_estan_en_los_datos() -> void:
	var arenas: Dictionary = Ambient.config().arenas
	assert_true(arenas.paso.changes.has("blizzard"))
	assert_true(arenas.rlyeh.changes.has("tilt"))
	var lv: LevelData = load("res://data/levels/p1_n3.tres")
	assert_eq(String(lv.weather.id), "ventisca_paso", "el paso tiene la ventisca en lo peor")

func test_rlyeh_inclina_la_camara_y_el_temblor_se_suma() -> void:
	var cam := GameCamera.new()
	add_child_autofree(cam)
	var p := Node3D.new()
	add_child_autofree(p)
	cam.targets.append(p)
	cam.tilt = 0.08
	cam._process(0.016)
	assert_almost_eq(cam.rotation.z, 0.08, 0.0001, "inclinada")
	assert_almost_eq(cam.rotation.x, deg_to_rad(-30.0), 0.0001, "sin cambiar el ángulo de siempre")
	cam.tilt = 0.0
	cam._process(0.016)
	assert_eq(cam.rotation.z, 0.0, "y vuelve")
	assert_eq(PlayerMotor.CAMERA_YAW, 45.0, "los controles no dependen del giro de la cámara")
