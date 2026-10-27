extends GutTest
## Código QR de la ventana de conectar con GitHub (QrCode). La matriz se comprobó módulo a módulo
## contra la librería qrcode de Python y leyéndola con OpenCV; aquí quedan las huellas de esa
## comprobación para que no se rompa.

const URL := "https://github.com/login/device"

func test_version_y_patrones_fijos() -> void:
	var m := QrCode.encode(URL)
	assert_eq(m.size(), 29, "30 bytes con corrección M: versión 3")
	for c in [[0, 0], [22, 0], [0, 22]]:            # buscadores: borde oscuro, anillo claro, centro oscuro
		assert_true(m[c[1]][c[0]] and m[c[1] + 6][c[0] + 6])
		assert_false(m[c[1] + 1][c[0] + 1])
		assert_true(m[c[1] + 3][c[0] + 3])
	for i in range(8, 21): assert_eq(m[6][i], i % 2 == 0, "sincronismo")
	assert_true(m[m.size() - 8][8], "módulo oscuro fijo")

func test_igual_que_la_referencia() -> void:
	# huella de la matriz entera con la máscara 0, sacada de la librería qrcode de Python (corrección M)
	var bits := ""
	for row: Array in QrCode.encode(URL, 0):
		for b: bool in row: bits += "1" if b else "0"
	assert_eq(bits.md5_text(), REF_MD5)

func test_versiones_y_limite() -> void:
	assert_eq(QrCode.encode("A").size(), 21)
	assert_eq(QrCode.encode("x".repeat(213)).size(), 57, "versión 10")
	assert_eq(QrCode.encode("x".repeat(214)), [], "no cabe")
	var img := QrCode.image(URL, 4)
	assert_eq(img.get_width(), (29 + 8) * 4, "con 4 módulos de margen")

const REF_MD5 := "97c52d40780c87a5674149c7c1d3b644"
