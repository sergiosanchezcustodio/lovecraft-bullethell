extends GutTest
## Objetos de la subida de nivel (D-38, hito 8.6): modificadores generales del jugador que
## leen todas sus armas, la defensa, la recuperación y el equipo.

var world: CombatWorld
var p: Player
var ws: WeaponSystem

func before_each() -> void:
	world = CombatWorld.new()
	add_child_autofree(world)
	p = Player.new().setup(load("res://data/characters/dyer.tres"), BotInput.new("idle"), Color.YELLOW)
	p.world = world
	world.add_child(p)
	world.add_player(p)
	ws = WeaponSystem.new().setup(p, world)
	p.add_child(ws)
	p.weapons = ws
	for up in DebugOptions.list_resources("res://data/upgrades"):
		p.progress.upgrade_pool.append(up)

## Objeto propio para el test (los valores del equilibrio pueden cambiar).
func _item(stat: String, mul: float, add: float, also := {}) -> UpgradeData:
	var u := UpgradeData.new()
	u.id = StringName("t_" + stat)
	u.stat = stat
	u.multiply = mul
	u.add = add
	u.also = also
	p.progress.upgrade_pool.append(u)
	return u

func _give(u: UpgradeData, lv: int) -> void:
	p.progress.passives[u.id] = lv
	p.rebuild_stats()

func test_cada_objeto_cambia_una_estadistica_que_existe() -> void:
	var c := CharacterData.new()
	var ids := {}
	for up: UpgradeData in DebugOptions.list_resources("res://data/upgrades"):
		assert_false(ids.has(up.id), "id repetido: %s" % up.id)
		ids[up.id] = true
		assert_true(up.stat in c, "%s: %s no está en CharacterData" % [up.id, up.stat])
		for k: String in up.also:
			assert_true(k.trim_suffix("*").trim_suffix("+") in c, "%s: %s" % [up.id, k])
		assert_ne(up.display_name, "", "%s sin nombre" % up.id)
		assert_ne(up.description, "", "%s sin descripción" % up.id)

func test_las_armas_leen_los_objetos() -> void:
	var w := ws.add_weapon(load("res://data/weapons/webly.tres"))
	var count := w.stat("count"); var rng := w.stat("range"); var cd := w.stat("cooldown"); var pierce := w.stat("pierce")
	_give(_item("proj_count_add", 1.0, 1.0), 2)
	_give(_item("range_mult", 1.1, 0.0), 1)
	_give(_item("weapon_cooldown_mult", 0.9, 0.0), 1)
	_give(_item("pierce_add", 1.0, 1.0), 1)
	assert_almost_eq(w.stat("count"), count + 2.0, 0.001)
	assert_almost_eq(w.stat("range"), rng * 1.1, 0.001)
	assert_almost_eq(w.stat("cooldown"), cd * 0.9, 0.001)
	assert_almost_eq(w.stat("pierce"), pierce + 1.0, 0.001)

func test_proyectiles_y_perforacion_no_afectan_a_un_tajo() -> void:
	var w := ws.add_weapon(load("res://data/weapons/machete.tres"))
	var count := w.stat("count"); var r := w.stat("aoe_radius")
	_give(_item("proj_count_add", 1.0, 1.0), 1)
	_give(_item("area_mult", 1.2, 0.0), 1)
	assert_almost_eq(w.stat("count"), count, 0.001, "el machete no gana proyectiles")
	assert_almost_eq(w.stat("aoe_radius"), r * 1.2, 0.001, "pero sí área")

func test_rehacer_no_acumula() -> void:
	var u := _item("dodge_speed", 1.15, 0.0)
	_give(u, 2)
	var v := p.data.dodge_speed
	p.rebuild_stats()
	p.rebuild_stats()
	assert_almost_eq(p.data.dodge_speed, v, 0.001)
	_give(u, 0)
	assert_almost_eq(p.data.dodge_speed, v / 1.15 / 1.15, 0.01, "al quitarlo vuelve a la base")

func test_otros_efectos_del_objeto() -> void:
	_give(_item("physical_mult", 1.12, 0.0, {"knockback_mult*": 1.1}), 2)
	assert_almost_eq(p.data.physical_mult, 1.12 * 1.12, 0.001)
	assert_almost_eq(p.data.knockback_mult, 1.1 * 1.1, 0.001)

func test_dano_por_grupo() -> void:
	var fire := p.damage_mult(WeaponData.Category.FIREARM)
	var magic := p.damage_mult(WeaponData.Category.MAGIC)
	_give(_item("firearm_mult", 1.5, 0.0), 1)
	assert_almost_eq(p.damage_mult(WeaponData.Category.FIREARM), fire * 1.5, 0.001)
	assert_almost_eq(p.damage_mult(WeaponData.Category.MAGIC), magic, 0.001, "las mágicas no cambian")

func test_critico_en_armas_sin_critico_propio() -> void:
	var w := ws.add_weapon(load("res://data/weapons/machete.tres"))
	var base := ws.dmg(w)
	_give(_item("crit_chance", 1.0, 1.0), 1)          # siempre crítico
	assert_almost_eq(ws.dmg(w), base * WeaponSystem.BASE_CRIT, 0.01)
	_give(_item("crit_bonus", 1.0, 0.5), 1)
	assert_almost_eq(ws.dmg(w), base * (WeaponSystem.BASE_CRIT + 0.5), 0.01)

func test_armadura_con_suelo() -> void:
	_give(_item("armor", 1.0, 3.0), 1)
	var h := p.health
	p.take_damage(Damage.new(10.0, 0.0))
	assert_almost_eq(h - p.health, 7.0, 0.001)
	p._hurt_time = -1.0
	h = p.health
	p.take_damage(Damage.new(2.0, 0.0))
	assert_almost_eq(h - p.health, 2.0 * Player.ARMOR_FLOOR, 0.001, "un golpe pequeño no se anula del todo")

func test_resistencia_mental() -> void:
	_give(_item("mental_mult", 0.5, 0.0), 1)
	var s := p.sanity
	p.take_damage(Damage.new(0.0, 10.0))
	assert_almost_eq(s - p.sanity, 5.0, 0.001)

func test_regeneracion() -> void:
	_give(_item("health_regen", 1.0, 2.0), 1)
	p.health = 50.0
	p._physics_process_step(0.5)
	assert_almost_eq(p.health, 51.0, 0.05)

func test_al_abatir_cura() -> void:
	_give(_item("heal_on_kill", 1.0, 1.5), 1)
	p.health = 50.0
	world.record_kill(StringName("J1:webly"))
	assert_almost_eq(p.health, 51.5, 0.001)
	world.record_kill(StringName("J2:webly"))
	assert_almost_eq(p.health, 51.5, 0.001, "lo de otro jugador no cuenta")

func test_rasgo_contra_elites() -> void:
	_give(_item("elite_mult", 1.0, 0.5), 1)
	assert_almost_eq(float(p.data.bonus_tags.get(Player.ELITE_TAG, 1.0)), 1.5, 0.001)
	var base: CharacterData = load("res://data/characters/dyer.tres")
	assert_false(base.bonus_tags.has(Player.ELITE_TAG), "no toca el recurso del personaje")

func test_crisis_mas_cortas() -> void:
	_give(_item("crisis_mult", 0.5, 0.0), 1)
	assert_almost_eq(p.sanity_state.duration_mult, 0.5, 0.001)
