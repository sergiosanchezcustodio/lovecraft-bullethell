extends GutTest
## Reglas de daño de las armas (D-37, DamageRules).

func test_every_weapon_follows_the_rules() -> void:
	for w in DamageRules.all_weapons():
		if w.support: continue
		assert_almost_eq(DamageRules.deviation(w), 0.0, DamageRules.TOLERANCE,
			"%s: %.1f de daño por segundo, le tocan %.1f" % [w.id, DamageRules.dps(w), DamageRules.target_dps(w)])

func _w(props: Dictionary) -> WeaponData:
	var w := WeaponData.new()
	for k in props: w.set(k, props[k])
	return w

func test_traits_order_the_damage() -> void:
	var near := _w({"range": 3.0}); var far := _w({"range": 18.0})
	assert_gt(DamageRules.target_dps(near), DamageRules.target_dps(far), "corto alcance > largo")
	assert_gt(DamageRules.target_dps(_w({})), DamageRules.target_dps(_w({"aoe_radius": 2.0, "delivery": WeaponData.Delivery.THROWN})), "uno > área")
	assert_gt(DamageRules.target_dps(_w({})), DamageRules.target_dps(_w({"count": 3.0})), "un proyectil > varios")
	assert_gt(DamageRules.target_dps(_w({"cooldown": 2.0})), DamageRules.target_dps(_w({"cooldown": 0.3})), "cadencia baja > alta")
	assert_gt(DamageRules.target_dps(_w({"sanity_cost": 2.0})), DamageRules.target_dps(_w({})), "cuesta cordura > gratis")
	assert_gt(DamageRules.target_dps(_w({"jitter_deg": 10.0})), DamageRules.target_dps(_w({"homing": 3.0})), "al azar > teledirigida")
