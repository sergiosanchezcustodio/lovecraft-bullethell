extends GutTest
## Vida al fondo y agua más viva (hito 12.12): el corazón de R'lyeh, los Profundos que asoman,
## las luces de los barcos y la espuma de la orilla.

## Agua en x de 0 a 3 m (rejilla de 0,25 m de -5 a 5); el resto, seco.
func _pool_map() -> ObstacleMap:
	var o := ObstacleMap.new()
	var n := 40
	var w := PackedByteArray()
	w.resize(n * n)
	for j in n:
		for i in n:
			var x := -5.0 + (i + 0.5) * 0.25
			w[j * n + i] = 255 if x >= 0.0 and x < 3.0 else 0
	o._water = w
	o._n = n
	o._cell = 0.25
	o._origin = Vector2(-5, -5)
	return o

func after_each() -> void:
	Ambient.heart_beat = 0.0

func test_el_latido_es_lub_dub() -> void:
	assert_almost_eq(Ambient.beat_at(0.0), 1.0, 0.01, "lub, fuerte")
	var dub := Ambient.beat_at(0.17)
	assert_between(dub, 0.5, 0.7, "dub, más flojo")
	assert_lt(Ambient.beat_at(0.09), dub, "entre los dos baja")
	assert_lt(Ambient.beat_at(0.5), 0.02, "y luego calla")
	assert_gt(Ambient.beat_at(0.99), 0.9, "hasta el siguiente")

func test_las_piezas_que_laten_siguen_el_latido() -> void:
	var mode: int = Ambient.MODES["heart"]
	Ambient.heart_beat = 0.0
	var low := Ambient.anim_k(mode, 0.5, 1.0, 3.0, 0.2)
	Ambient.heart_beat = 1.0
	var high := Ambient.anim_k(mode, 0.5, 1.0, 3.0, 0.2)
	assert_lt(low, 1.0, "en reposo, algo apagadas")
	assert_gt(high, 1.5, "en el latido, encendidas")
	assert_eq(Ambient.anim_k(mode, 0.5, 1.0, 7.0, 0.9), high, "todas a la vez, sin fase propia")

func test_los_monolitos_de_rlyeh_laten() -> void:
	assert_eq(String(Ambient.model_cfg("rly_monolito").get("glow", "")), "heart")
	assert_true((Ambient.config().arenas as Dictionary).rlyeh.has("heart"))

func test_la_orilla_es_el_borde_del_agua() -> void:
	var o := _pool_map()
	assert_true(Ambient.is_shore(Vector2(0.2, 0), o, {}), "dentro del agua, junto a la tierra")
	assert_true(Ambient.is_shore(Vector2(2.8, 1), o, {}), "y en el otro borde")
	assert_false(Ambient.is_shore(Vector2(1.5, 0), o, {}), "en medio de la poza, no")
	assert_false(Ambient.is_shore(Vector2(-1.0, 0), o, {}), "en seco, no")
	assert_false(Ambient.is_shore(Vector2(-1.0, 0), null, {}), "sin mapa, no")

func test_el_mar_solo_hace_espuma_si_llega_a_ras() -> void:
	var sea := {"shore": Vector2(10, 10), "north": -100000.0, "level": -0.35, "coast": 0.0}
	assert_true(Ambient.is_shore(Vector2(10.2, 0), null, sea), "el mar casi a ras, en la orilla")
	assert_false(Ambient.is_shore(Vector2(8.0, 0), null, sea), "lejos de la orilla, no")
	sea.level = -1.2
	assert_false(Ambient.is_shore(Vector2(10.2, 0), null, sea), "desde un muelle alto, el agua queda abajo")

func test_un_profundo_asoma_mira_y_se_hunde() -> void:
	var a := Ambient.new()                              # fuera del árbol: su _ready quiere una arena
	a.cfg = {"lurkers": {"model": "profundo", "n": 1, "stay": [1.0, 1.0], "show": 0.8}}
	a._lurk_rise(Vector3(3, 0, 3), a.cfg.lurkers)
	assert_eq(a._lurkers.size(), 1)
	var ld: Dictionary = a._lurkers[0]
	var b: Node3D = ld.node
	var start := b.position.y
	assert_lt(start + float(ld.top), 0.02, "empieza bajo el agua")
	for i in 30: a._lurk_step(0.05, i * 0.05)       # 1,5 s: ya asoma y empieza a hundirse
	assert_true(ld.sink, "al rato se hunde")
	assert_gt(b.position.y + float(ld.top), 0.3, "había asomado la cabeza y los hombros")
	for i in 40: a._lurk_step(0.05, 1.5 + i * 0.05)
	assert_eq(a._lurkers.size(), 0, "y se va")
	a.free()

func test_los_profundos_asoman_en_el_muelle_y_el_arrecife() -> void:
	var arenas: Dictionary = Ambient.config().arenas
	for id in ["muelle", "arrecife"]:
		assert_true((arenas[id] as Dictionary).has("lurkers"), id)
		assert_true(FileAccess.file_exists("res://models/%s.json" % String(arenas[id].lurkers.model)))
	assert_true((arenas.tormenta as Dictionary).has("ship_lights"), "y barcos en la tormenta")

func test_un_barco_cabecea_y_la_lluvia_lo_tapa() -> void:
	var a := Ambient.new()
	a.cfg = {"ship_lights": {"n": 1, "dist": [4, 16]}}
	a._sea = {"shore": Vector2(10, 10), "north": -100000.0, "level": -2.0, "coast": 0.0, "state": 0.6, "swell": 1.0, "period": 0.0}
	a._make_ship(Vector2(20, 0), Vector2(0, 0.3))
	assert_eq(a._ships.size(), 1)
	var sd: Dictionary = a._ships[0]
	var mats: Array = sd.mats
	assert_eq((mats[0][0] as StandardMaterial3D).albedo_color.a, 0.0, "aparece poco a poco")
	sd.k = 1.0
	var alphas := []
	var tilts := []
	for i in 40:
		var t := i * 0.5
		var b: Node3D = sd.node
		b.position = Vector3(20, -2, 0)                     # quieto en el sitio, a la vista (sin cámara, todo lo está)
		a._ship_step(0.0, t)
		alphas.append((mats[3][0] as StandardMaterial3D).albedo_color.a)
		tilts.append(b.rotation.z)
	assert_gt(alphas.max() - alphas.min(), 0.3, "la lluvia lo tapa y lo destapa")
	assert_gt(tilts.max() - tilts.min(), 0.05, "cabecea con la mar")
	a.free()
