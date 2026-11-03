extends GutTest
## Hito 16.25: los investigadores secretos.

func test_hay_dos_y_no_se_compran() -> void:
	var ids := Secrets.all().map(func(c: CharacterData) -> String: return String(c.id))
	assert_eq(ids, ["carter", "whateley"])
	for c in Secrets.all():
		assert_false(c.in_shop, String(c.id))
		assert_true(FileAccess.file_exists("res://models/%s.json" % c.model))
		for wid in c.starting_weapons:
			var w: WeaponData = load("res://data/weapons/%s.tres" % wid)
			assert_ne(w.evolution, &"", "%s evoluciona" % wid)
			assert_ne(w.evolution_alt, &"", "%s tiene segunda rama" % wid)

func test_cerrados_hasta_cumplir_la_condicion() -> void:
	var s := SaveData.new()
	var carter: CharacterData = load("res://data/characters/carter.tres")
	var wilbur: CharacterData = load("res://data/characters/whateley.tres")
	assert_true(Secrets.check(s).is_empty())
	assert_string_contains(Secrets.hint(s, carter), "0 de %d" % Fragments.total())   # «Reúne las páginas sueltas (0 de N)»
	for st: Dictionary in Fragments.stories():
		for p: Dictionary in st.pages: Fragments.add(s, String(p.level))
	var got := Secrets.check(s)
	assert_eq(got.size(), 1)
	assert_eq(got[0].id, &"carter")
	assert_true(s.has_character("carter"))
	assert_true(Secrets.check(s).is_empty(), "una sola vez")
	assert_false(s.has_character("whateley"))
	for c: Dictionary in Challenge.all(): Challenge.record_win(s, Challenge.id_for(String(c.level)), 100.0)
	assert_eq(Secrets.check(s).map(func(c: CharacterData) -> StringName: return c.id), [&"whateley"])
	assert_true(Secrets.met(s, wilbur))

func test_en_la_seleccion_salen_cerrados() -> void:
	var chars: Array[CharacterData] = []
	for r in DebugOptions.list_resources("res://data/characters"): chars.append(r as CharacterData)
	var none: Array[PetData] = []
	var st := SelectState.new().setup(chars, [], none)
	var ci := chars.find(chars.filter(func(c: CharacterData) -> bool: return c.id == &"carter")[0])
	assert_true(st.is_locked(ci))

func test_la_llave_adormece() -> void:
	var w: WeaponData = load("res://data/weapons/llave_suenos.tres")
	assert_eq(w.delivery, WeaponData.Delivery.BOOMERANG)
	assert_gt(w.stun, 0.0)
	assert_eq(w.look, "llave")
