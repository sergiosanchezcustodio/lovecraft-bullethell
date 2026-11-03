extends GutTest
## Hito 16.29: comparar antes de elegir.

func test_objeto_de_vida_y_de_recarga() -> void:
	var d: CharacterData = load("res://data/characters/dyer.tres").duplicate()
	d.max_health = 100.0
	var rows := StatCompare.upgrade(d, load("res://data/upgrades/vida.tres"))
	assert_eq(rows.size(), 1)
	assert_eq(rows[0].before, "100")
	assert_eq(rows[0].after, "120")
	assert_true(rows[0].good)
	var cd := StatCompare.upgrade(d, load("res://data/upgrades/reloj.tres") if ResourceLoader.exists("res://data/upgrades/reloj.tres") else load("res://data/upgrades/clepsidra.tres"))
	assert_false(cd.is_empty())

func test_menos_es_mejor_en_verde() -> void:
	var d := CharacterData.new()
	var up := UpgradeData.new()
	up.stat = "mental_mult"; up.multiply = 0.9; up.add = 0.0
	var rows := StatCompare.upgrade(d, up)
	assert_eq(rows[0].after, "−10 %")
	assert_true(rows[0].good, "menos daño mental: mejor")

func test_nivel_de_arma() -> void:
	var w: WeaponData = load("res://data/weapons/llave_suenos.tres")
	var rows := StatCompare.weapon_level(null, w, 2, 3)          # nivel 3: dos llaves
	assert_eq(rows.size(), 1)
	assert_eq(rows[0].name, "Cantidad")
	assert_eq([rows[0].before, rows[0].after], ["1", "2"])

func test_formato() -> void:
	assert_eq(StatCompare.fmt(4.86, "num"), "4,86")
	assert_eq(StatCompare.fmt(1.12, "mult"), "+12 %")
	assert_eq(StatCompare.fmt(0.08, "pct"), "8 %")
	assert_string_contains(StatCompare.bbcode([{"name": "Vida", "before": "1", "after": "2", "good": true}]), "[color=#")
