extends GutTest
## Código de sala (hito 9.1): ida y vuelta, erratas, letras que se confunden y direcciones a mano.

func test_ida_y_vuelta() -> void:
	for ip in ["83.45.201.7", "192.168.1.34", "0.0.0.0", "255.255.255.255"]:
		for port in [RoomCode.BASE_PORT, RoomCode.BASE_PORT + 7]:
			var c := RoomCode.encode(ip, port)
			assert_eq(c.length(), 9, "8 letras y un guion")
			assert_eq(RoomCode.parse(c), {"ip": ip, "port": port}, c)

func test_fuera_de_rango_no_da_codigo() -> void:
	assert_eq(RoomCode.encode("1.2.3.4", RoomCode.BASE_PORT + 8), "")
	assert_eq(RoomCode.encode("1.2.3", RoomCode.BASE_PORT), "")
	assert_eq(RoomCode.encode("::1", RoomCode.BASE_PORT), "")

func test_minusculas_espacios_y_letras_parecidas() -> void:
	var c := RoomCode.encode("83.45.201.7")
	var parsed := RoomCode.parse(" " + c.to_lower().replace("-", " ") + " ")
	assert_eq(parsed.get("ip"), "83.45.201.7")
	# la O se lee como 0 y la I y la L como 1
	var with_zero := RoomCode.encode("10.0.0.1")
	assert_true("0" in with_zero)
	assert_eq(RoomCode.parse(with_zero.replace("0", "O")).get("ip"), "10.0.0.1")

func test_una_errata_casi_siempre_se_detecta() -> void:
	var c := RoomCode.encode("83.45.201.7").replace("-", "")
	var caught := 0
	var total := 0
	for i in c.length():
		for ch in RoomCode.ALPHABET:
			if ch == c[i]: continue
			total += 1
			var bad := c.substr(0, i) + ch + c.substr(i + 1)
			if RoomCode.parse(bad).is_empty(): caught += 1
	assert_gt(float(caught) / total, 0.9, "%d de %d erratas detectadas" % [caught, total])

func test_basura_no_se_entiende() -> void:
	assert_eq(RoomCode.parse(""), {})
	assert_eq(RoomCode.parse("HOLA"), {})
	assert_eq(RoomCode.parse("UUUU-UUUU"), {}, "la U no está en el alfabeto")

func test_direcciones_escritas_a_mano() -> void:
	assert_eq(RoomCode.parse("1.2.3.4"), {"ip": "1.2.3.4", "port": RoomCode.BASE_PORT})
	assert_eq(RoomCode.parse("1.2.3.4:5000"), {"ip": "1.2.3.4", "port": 5000})
	assert_eq(RoomCode.parse("[::1]:24681"), {"ip": "::1", "port": 24681})
	assert_eq(RoomCode.parse("fe80::1"), {"ip": "fe80::1", "port": RoomCode.BASE_PORT})
	assert_eq(RoomCode.parse("1.2.3.999"), {})
	assert_eq(RoomCode.parse("1.2.3.4:99999"), {})

func test_ips_privadas() -> void:
	assert_true(RoomCode.is_private("192.168.1.2"))
	assert_true(RoomCode.is_private("10.4.5.6"))
	assert_true(RoomCode.is_private("172.20.0.1"))
	assert_false(RoomCode.is_private("172.32.0.1"))
	assert_false(RoomCode.is_private("83.45.201.7"))
	assert_false(RoomCode.is_private("127.0.0.1"))
