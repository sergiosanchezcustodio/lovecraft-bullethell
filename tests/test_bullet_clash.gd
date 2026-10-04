extends GutTest
## Las balas del jugador anulan las enemigas que tocan.

func test_una_bala_del_jugador_anula_una_enemiga() -> void:
	var bm := BulletManager.new()
	add_child_autofree(bm)
	var d := Damage.new(5.0, 0.0)
	bm.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, Vector3(0, 0, 0), Vector3.ZERO, 0.15, 0.2, d, 5.0)
	bm.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, Vector3(5, 0, 0), Vector3.ZERO, 0.15, 0.2, d, 5.0)
	bm.spawn(BulletManager.Team.PLAYER, BulletManager.Style.PLAYER, Vector3(0.1, 0, 0), Vector3.ZERO, 0.15, 0.2, d, 5.0)
	assert_eq(bm.count, 3)
	bm._resolve_clashes()
	assert_eq(bm.count, 1, "se anulan la enemiga cercana y la del jugador (ligera); queda la lejana")

func test_las_pesadas_siguen() -> void:
	var bm := BulletManager.new()
	add_child_autofree(bm)
	var d := Damage.new(5.0, 0.0)
	bm.spawn(BulletManager.Team.ENEMY, BulletManager.Style.PHYSICAL, Vector3(0, 0, 0), Vector3.ZERO, 0.15, 0.2, d, 5.0)
	bm.spawn(BulletManager.Team.PLAYER, BulletManager.Style.HARPOON, Vector3(0.1, 0, 0), Vector3.ZERO, 0.3, 0.2, d, 5.0)
	bm._resolve_clashes()
	assert_eq(bm.count, 1, "el arpón sigue")
	assert_eq(bm._team[0], BulletManager.Team.PLAYER)
