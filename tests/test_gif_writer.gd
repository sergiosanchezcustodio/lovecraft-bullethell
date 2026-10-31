extends GutTest
## GIF de la repetición de la caída: que sea un GIF válido (lo comprueba la herramienta de Python
## a mano; aquí, cabecera, final y que no se coma la tabla).

func test_gif_bien_formado() -> void:
	var frames: Array[Image] = []
	for f in 4:
		var im := Image.create(96, 54, false, Image.FORMAT_RGB8)
		for y in 54:
			for x in 96: im.set_pixel(x, y, Color(fposmod(x * 0.013 + f * 0.1, 1.0), y / 54.0, 0.3))
		frames.append(im)
	var b := GifWriter.encode(frames, 8)
	assert_eq(b.slice(0, 6).get_string_from_ascii(), "GIF89a")
	assert_eq(b[b.size() - 1], 0x3B, "termina")
	assert_eq(b.decode_u16(6), 96)
	assert_eq(b.decode_u16(8), 54)
