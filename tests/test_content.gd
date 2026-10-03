extends GutTest
## Pipeline de contenido (fase 3): todo lo que hay en data/ apunta a cosas que existen. Un
## enemigo nuevo solo necesita su generador (models/<modelo>.json), su línea en
## data/anim_sets.json, su .tres en data/enemies/ y su nota en data/library/textos.json.

func _all(dir: String) -> Array:
	return DebugOptions.list_resources(dir)

func test_cada_enemigo_tiene_modelo_animaciones_y_comportamiento() -> void:
	for e: EnemyData in _all("res://data/enemies"):
		assert_true(FileAccess.file_exists("res://models/%s.json" % e.model), "%s: falta models/%s.json" % [e.id, e.model])
		assert_not_null(Anims.script_for(e.model), "%s: falta en data/anim_sets.json" % e.id)
		if e.movement != &"chase":
			assert_true(ResourceLoader.exists(EnemyBehavior.DIR % e.movement), "%s: falta el comportamiento %s" % [e.id, e.movement])
		if e.attack != null: assert_gt(e.attack_cooldown, 0.0, "%s: ataque sin recarga" % e.id)
		if e.attack_anim != "": assert_true(Anims.has_anim(e.model, e.attack_anim), "%s: sin la animación %s" % [e.id, e.attack_anim])

func test_cada_nivel_tiene_arena_y_enemigos() -> void:
	for l: LevelData in _all("res://data/levels"):
		assert_true(FileAccess.file_exists(l.arena), "%s: falta la arena %s" % [l.id, l.arena])
		assert_false(l.pool.is_empty(), "%s: sin enemigos" % l.id)
		if l.final_enemy != null: assert_true(FileAccess.file_exists("res://models/%s.json" % l.final_enemy.model), String(l.id))
		assert_true(Campaign.exists(String(l.id)), "%s: no está en data/campaign.json" % l.id)

func test_cada_modelo_animado_existe() -> void:
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Anims.SETS_PATH))
	for m in d.modelos:
		assert_true(FileAccess.file_exists("res://models/%s.json" % m), "anim_sets: falta models/%s.json" % m)

func test_cada_arma_tiene_icono() -> void:
	for w in DamageRules.all_weapons():
		assert_not_null(w.get_icon(), "%s sin icono" % w.id)

func test_cada_compañero_y_personaje_tiene_modelo_animado() -> void:
	for p: PetData in _all("res://data/pets"):
		assert_not_null(Anims.script_for(p.model), "compañero %s" % p.id)
	for c: CharacterData in _all("res://data/characters"):
		assert_not_null(Anims.script_for(c.model), "personaje %s" % c.id)

func test_comportamiento_por_nombre() -> void:
	assert_true(EnemyBehavior.create(&"blind") is BlindBehavior)
	assert_true(EnemyBehavior.create(&"chase").get_script() == EnemyBehavior)
