extends GutTest
## Modo foto (hito 13.12): oculta el HUD y lo devuelve todo al salir.

class FakeGame extends Node3D:
	var camera: Camera3D
	var _env := Environment.new()
	var players: Array[Player] = []
	var world: CombatWorld = null
	var args := LaunchArgs.parse(PackedStringArray(["photo_dir=user://pruebas_fotos", "photo_dof=1", "photo_grade=1"]))
	var grade_gamma := 1.0
	var _shot_tag := ""

func _game() -> FakeGame:
	var g := FakeGame.new()
	g.camera = Camera3D.new()
	g.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	g.camera.size = 16.0
	g.camera.rotation_degrees = Vector3(-30, 45, 0)
	g.add_child(g.camera)
	add_child_autofree(g)
	g.camera.position = Vector3(3, 0.8, -2) + g.camera.basis.z * 40.0
	g.camera.make_current()
	return g

func test_oculta_las_capas_y_las_devuelve() -> void:
	var g := _game()
	var hud := CanvasLayer.new(); hud.layer = 5; g.add_child(hud)
	var veil := CanvasLayer.new(); veil.layer = -1; g.add_child(veil)
	Atmosphere.set_grade(g._env, 1.3, Atmosphere.grade_for("p1"))
	var cc := g._env.adjustment_color_correction
	var pm := PhotoMode.new(g)
	g.add_child(pm)
	await get_tree().process_frame
	assert_false(hud.visible, "fuera el HUD")
	assert_true(veil.visible, "la ventisca es parte de la imagen")
	assert_true(pm.cam.current)
	assert_ne(g._env.adjustment_color_correction, cc, "otra gradación")
	assert_true((pm.cam.attributes as CameraAttributesPractical).dof_blur_far_enabled)
	assert_almost_eq(pm.pivot.x, 3.0, 0.05, "mira donde miraba el juego")
	assert_almost_eq(pm.pivot.z, -2.0, 0.05)
	pm.free()
	assert_true(hud.visible)
	assert_true(g.camera.current, "vuelve la cámara del juego")
	assert_eq(g._env.adjustment_color_correction, cc, "y su gradación")

func test_perspectiva_encuadra_lo_mismo() -> void:
	var g := _game()
	var pm := PhotoMode.new(g)
	g.add_child(pm)
	await get_tree().process_frame
	pm.persp = true
	pm._place()
	assert_eq(pm.cam.projection, Camera3D.PROJECTION_PERSPECTIVE)
	var h := 2.0 * pm._distance() * tan(deg_to_rad(PhotoMode.FOV) * 0.5)
	assert_almost_eq(h, pm.view, 0.01, "el mismo alto visible en el punto que mira")
	assert_eq(pm.photo_dir(), "user://pruebas_fotos")
	pm.free()

func test_la_pausa_lo_ofrece() -> void:
	for guest in [false, true]:
		var p := Menus.PauseMenu.new(guest)
		add_child_autofree(p)
		await get_tree().process_frame
		var labels := p.find_children("*", "Button", true, false).map(func(b: Node) -> String: return (b as Button).text)
		assert_has(labels, "Modo foto")
