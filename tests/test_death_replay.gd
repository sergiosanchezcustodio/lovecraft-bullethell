extends GutTest
## Repetición de la caída (hito 15.1): la reducción de la pantalla y el tope de imágenes.

func _screen(w: int, h: int, shade: int) -> PackedByteArray:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color8(shade, shade, shade))
	return img.get_data()

func test_reduce_y_guarda_como_mucho_los_ultimos_segundos() -> void:
	var r := DeathReplay.new()
	add_child_autofree(r)
	var cap := int(DeathReplay.SECONDS * DeathReplay.FPS)
	for i in cap + 5:
		r._busy += 1
		r._shrink(_screen(640, 360, i % 256), 640, 360, Image.FORMAT_RGBA8)
	await wait_physics_frames(1)
	assert_eq(r.frames.size(), cap, "tope de imágenes")
	assert_eq(r.frames[0].get_size(), Vector2i(DeathReplay.W, DeathReplay.H))
	assert_eq(r.frames[0].get_format(), Image.FORMAT_RGB8, "sin alfa")
	assert_almost_eq(r.frames[0].get_pixel(10, 10).r8, 5, 1, "se queda con las más recientes")
	assert_eq(r._busy, 0, "cada reducción termina")

func test_congelada_no_graba_mas() -> void:
	var r := DeathReplay.new()
	add_child_autofree(r)
	r._shrink(_screen(64, 36, 100), 64, 36, Image.FORMAT_RGBA8)
	var got := r.freeze()
	r._shrink(_screen(64, 36, 200), 64, 36, Image.FORMAT_RGBA8)
	assert_eq(got.size(), 1)
	assert_eq(r.frames.size(), 1)
