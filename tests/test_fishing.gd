extends GutTest
## Hito 16.24: la pesca en el muelle de Innsmouth.

func after_each() -> void:
	GameSession.fish_curse = false

func test_las_capturas_tienen_modelo_y_rareza() -> void:
	assert_eq(Fishing.catches().size(), 9)
	for c: Dictionary in Fishing.catches():
		assert_true(FileAccess.file_exists("res://models/%s.json" % c.model), String(c.model))
		assert_true(String(c.rarity) in Fishing.RARITY_NAMES, String(c.id))
		assert_eq(String(Anims.script_for(String(c.model)).resource_path.get_file()), "anim_captura.gd")

func test_pica_de_todo_y_lo_comun_mas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var n := {}
	for i in 4000:
		var r := String(Fishing.roll(rng).rarity)
		n[r] = int(n.get(r, 0)) + 1
	assert_gt(int(n.get("comun", 0)), 3000)
	assert_gt(int(n.get("raro", 0)), 250)
	assert_between(int(n.get("maldito", 0)), 120, 400)

func test_solo_entre_niveles_de_innsmouth() -> void:
	assert_true(Fishing.offered("p2_n1", "p2_n2", false))
	assert_false(Fishing.offered("p2_n1", "p2_n2", true), "sin red")
	assert_false(Fishing.offered("p1_n1", "p1_n2", false), "en la Antártida, no")
	assert_false(Fishing.offered("p2_n5", "", false), "sin siguiente nivel")
	assert_false(Fishing.offered("sin_fin:p2_n1", "p2_n2", false))

## Recoger sin soltar nunca parte el sedal; soltando en los tirones, sale.
func test_el_sedal() -> void:
	var fish := Fishing.find("bacalao")
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	var greedy := Fishing.Line.new(fish, rng)
	var st := 0
	for i in 600:
		st = greedy.step(1.0 / 60.0, true)
		if st != Fishing.Line.REELING: break
	assert_eq(st, Fishing.Line.BROKE)
	var calm := Fishing.Line.new(fish, rng)
	var hold := true
	for i in 6000:
		if calm.bursting or calm.tension > 0.6: hold = false
		elif calm.tension < 0.25: hold = true
		st = calm.step(1.0 / 60.0, hold)
		if st != Fishing.Line.REELING: break
	assert_eq(st, Fishing.Line.CAUGHT)

func test_el_bestiario_y_la_biblioteca() -> void:
	var s := SaveData.new()
	var fish := Library.entries(s, "enemies").filter(func(e: Dictionary) -> bool: return e.section == Library.SECTION_FISH)
	assert_eq(fish.size(), 9)
	assert_false(fish.any(func(e: Dictionary) -> bool: return e.known), "nada pescado aún")
	Fishing.record(s, "arenque", false)
	Fishing.record(s, "rape", false)
	assert_true(Fishing.full_entry(s, Fishing.find("arenque")), "la común, al pescarla")
	assert_false(Fishing.full_entry(s, Fishing.find("rape")), "la rara vendida: sin su nota")
	Fishing.record(s, "rape", true)
	assert_true(Fishing.full_entry(s, Fishing.find("rape")))
	assert_eq(Fishing.caught(s, "rape"), 2)
	assert_eq(Fishing.kept(s, "rape"), 1)
