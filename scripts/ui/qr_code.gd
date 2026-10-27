class_name QrCode
extends RefCounted
## Código QR (27-10-2026), para la ventana de conectar con GitHub: con el móvil se abre la página
## del código sin escribirla. Godot no trae generador, así que va aquí: modo bytes (UTF-8),
## corrección M (15 %), versiones 1 a 10 (hasta 213 bytes) y la máscara de menor penalización.
## Sigue la norma ISO/IEC 18004 como la implementación de referencia de Nayuki; se comprobó módulo a
## módulo contra la librería qrcode de Python en las ocho máscaras y leyéndolo con OpenCV.

## Por versión (1 a 10) con corrección M: [codewords de corrección por bloque, bloques del grupo 1,
## datos por bloque del grupo 1, bloques del grupo 2 (con un dato más)]
const BLOCKS := [[], [10, 1, 16, 0], [16, 1, 28, 0], [26, 1, 44, 0], [18, 2, 32, 0], [24, 2, 43, 0],
	[16, 4, 27, 0], [18, 4, 31, 0], [22, 2, 38, 2], [22, 3, 36, 2], [26, 4, 43, 1]]
const ALIGN := [[], [], [6, 18], [6, 22], [6, 26], [6, 30], [6, 34], [6, 22, 38], [6, 24, 42], [6, 26, 46], [6, 28, 50]]
const FORMAT_M := 0                         ## bits de la corrección M en el formato

## Matriz de módulos (true = oscuro), filas de arriba abajo. mask = -1: la de menor penalización.
## Vacía si el texto no cabe en la versión 10.
static func encode(text: String, mask := -1) -> Array:
	var data := text.to_utf8_buffer()
	var version := 0
	for v in range(1, 11):
		var b: Array = BLOCKS[v]
		var cap: int = (b[1] * b[2] + b[3] * (b[2] + 1)) * 8
		if 4 + (8 if v < 10 else 16) + data.size() * 8 <= cap:
			version = v
			break
	if version == 0: return []
	var codewords := _codewords(data, version)
	var size := version * 4 + 17
	var m := []
	var fn := []                                    # módulos de función (no llevan datos ni máscara)
	for y in size:
		var r: Array[bool] = []; r.resize(size)
		var f: Array[bool] = []; f.resize(size)
		m.append(r); fn.append(f)
	_function_patterns(m, fn, version)
	_place(m, fn, codewords)
	if mask >= 0:
		_apply_mask(m, fn, mask)
		_format(m, fn, mask)
		return m
	var best := []
	var best_score := 1 << 30
	for k in 8:
		var c := []
		for row: Array in m: c.append(row.duplicate())
		_apply_mask(c, fn, k)
		_format(c, fn, k)
		var s := _penalty(c)
		if s < best_score:
			best_score = s
			best = c
	return best

## Imagen del código: px píxeles por módulo y 4 módulos de margen en blanco (lo pide la norma).
static func image(text: String, px := 8, dark := Color.BLACK, light := Color.WHITE) -> Image:
	var m := encode(text)
	if m.is_empty(): return null
	var n := m.size() + 8
	var img := Image.create_empty(n * px, n * px, false, Image.FORMAT_RGB8)
	img.fill(light)
	for y in m.size():
		for x in m.size():
			if m[y][x]: img.fill_rect(Rect2i((x + 4) * px, (y + 4) * px, px, px), dark)
	return img

# ---------------- datos ----------------

static func _codewords(data: PackedByteArray, version: int) -> PackedByteArray:
	var b: Array = BLOCKS[version]
	var total_data: int = b[1] * b[2] + b[3] * (b[2] + 1)
	var bits: Array[int] = []
	_push(bits, 0b0100, 4)                          # modo bytes
	_push(bits, data.size(), 8 if version < 10 else 16)
	for c in data: _push(bits, c, 8)
	_push(bits, 0, mini(4, total_data * 8 - bits.size()))   # terminador
	while bits.size() % 8 != 0: bits.append(0)
	var bytes := PackedByteArray()
	for i in range(0, bits.size(), 8):
		var v := 0
		for j in 8: v = (v << 1) | bits[i + j]
		bytes.append(v)
	var pad := 0xEC
	while bytes.size() < total_data:
		bytes.append(pad)
		pad = 0x11 if pad == 0xEC else 0xEC
	# bloques, su corrección y el entrelazado
	var ec_len: int = b[0]
	var divisor := _rs_divisor(ec_len)
	var blocks: Array[PackedByteArray] = []
	var ecs: Array[PackedByteArray] = []
	var k := 0
	for i in b[1] + b[3]:
		var n: int = b[2] + (1 if i >= b[1] else 0)
		var blk := bytes.slice(k, k + n)
		k += n
		blocks.append(blk)
		ecs.append(_rs_remainder(blk, divisor))
	var out := PackedByteArray()
	for i in b[2] + 1:
		for blk in blocks:
			if i < blk.size(): out.append(blk[i])
	for i in ec_len:
		for e in ecs: out.append(e[i])
	return out

static func _push(bits: Array[int], v: int, n: int) -> void:
	for i in range(n - 1, -1, -1): bits.append((v >> i) & 1)

static func _gf_mul(x: int, y: int) -> int:
	var z := 0
	for i in range(7, -1, -1):
		z = (z << 1) ^ ((z >> 7) * 0x11D)
		z ^= ((y >> i) & 1) * x
	return z

static func _rs_divisor(degree: int) -> PackedByteArray:
	var r := PackedByteArray(); r.resize(degree)
	r[degree - 1] = 1
	var root := 1
	for i in degree:
		for j in degree:
			r[j] = _gf_mul(r[j], root)
			if j + 1 < degree: r[j] ^= r[j + 1]
		root = _gf_mul(root, 0x02)
	return r

static func _rs_remainder(data: PackedByteArray, divisor: PackedByteArray) -> PackedByteArray:
	var r := PackedByteArray(); r.resize(divisor.size())
	for b in data:
		var factor := b ^ r[0]
		r.remove_at(0)
		r.append(0)
		for i in divisor.size(): r[i] ^= _gf_mul(divisor[i], factor)
	return r

# ---------------- dibujo ----------------

static func _mod(m: Array, fn: Array, x: int, y: int, dark: bool) -> void:
	m[y][x] = dark
	fn[y][x] = true

static func _function_patterns(m: Array, fn: Array, version: int) -> void:
	var size := m.size()
	for i in size:                                  # patrones de sincronismo
		_mod(m, fn, 6, i, i % 2 == 0)
		_mod(m, fn, i, 6, i % 2 == 0)
	for c in [[3, 3], [size - 4, 3], [3, size - 4]]:   # buscadores, con su separador
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var x: int = c[0] + dx
				var y: int = c[1] + dy
				if x < 0 or y < 0 or x >= size or y >= size: continue
				var d := maxi(absi(dx), absi(dy))
				_mod(m, fn, x, y, d != 2 and d != 4)
	var al: Array = ALIGN[version]
	for i in al.size():
		for j in al.size():
			if (i == 0 and j == 0) or (i == 0 and j == al.size() - 1) or (i == al.size() - 1 and j == 0): continue
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					_mod(m, fn, al[i] + dx, al[j] + dy, maxi(absi(dx), absi(dy)) != 1)
	_format(m, fn, 0)                               # reserva las zonas del formato (se reescriben)
	if version >= 7:
		var rem := version
		for i in 12: rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
		var bits := version << 12 | rem
		for i in 18:
			var bit := (bits >> i) & 1 == 1
			var a := size - 11 + i % 3
			var b := i / 3
			_mod(m, fn, a, b, bit)
			_mod(m, fn, b, a, bit)

static func _format(m: Array, fn: Array, mask: int) -> void:
	var size := m.size()
	var data := FORMAT_M << 3 | mask
	var rem := data
	for i in 10: rem = (rem << 1) ^ ((rem >> 9) * 0x537)
	var bits := (data << 10 | rem) ^ 0x5412
	var bit := func(i: int) -> bool: return (bits >> i) & 1 == 1
	for i in 6: _mod(m, fn, 8, i, bit.call(i))
	_mod(m, fn, 8, 7, bit.call(6))
	_mod(m, fn, 8, 8, bit.call(7))
	_mod(m, fn, 7, 8, bit.call(8))
	for i in range(9, 15): _mod(m, fn, 14 - i, 8, bit.call(i))
	for i in 8: _mod(m, fn, size - 1 - i, 8, bit.call(i))
	for i in range(8, 15): _mod(m, fn, 8, size - 15 + i, bit.call(i))
	_mod(m, fn, 8, size - 8, true)                  # módulo oscuro fijo

## Datos en zigzag de dos columnas, de abajo arriba y al revés, saltando la columna 6.
static func _place(m: Array, fn: Array, data: PackedByteArray) -> void:
	var size := m.size()
	var i := 0
	var right := size - 1
	while right >= 1:
		if right == 6: right = 5
		for vert in size:
			for j in 2:
				var x := right - j
				var up := ((right + 1) & 2) == 0
				var y := size - 1 - vert if up else vert
				if not fn[y][x] and i < data.size() * 8:
					m[y][x] = (data[i >> 3] >> (7 - (i & 7))) & 1 == 1
					i += 1
		right -= 2

static func _apply_mask(m: Array, fn: Array, k: int) -> void:
	var size := m.size()
	for y in size:
		for x in size:
			if fn[y][x]: continue
			var inv := false
			match k:
				0: inv = (x + y) % 2 == 0
				1: inv = y % 2 == 0
				2: inv = x % 3 == 0
				3: inv = (x + y) % 3 == 0
				4: inv = (x / 3 + y / 2) % 2 == 0
				5: inv = x * y % 2 + x * y % 3 == 0
				6: inv = (x * y % 2 + x * y % 3) % 2 == 0
				7: inv = ((x + y) % 2 + x * y % 3) % 2 == 0
			if inv: m[y][x] = not m[y][x]

## Penalización de la norma: tiras de 5 o más iguales, bloques de 2×2, parecidos al buscador y
## desequilibrio entre oscuros y claros.
static func _penalty(m: Array) -> int:
	var size := m.size()
	var score := 0
	var dark := 0
	for pass_ in 2:
		for a in size:
			var run := 0
			var prev := false
			var line := ""
			for b in size:
				var v: bool = m[a][b] if pass_ == 0 else m[b][a]
				line += "1" if v else "0"
				if b > 0 and v == prev: run += 1
				else:
					if run >= 5: score += 3 + run - 5
					run = 1
				prev = v
			if run >= 5: score += 3 + run - 5
			for pat in ["10111010000", "00001011101"]:
				var at := line.find(pat)
				while at != -1:
					score += 40
					at = line.find(pat, at + 1)
	for y in size:
		for x in size:
			if m[y][x]: dark += 1
			if x < size - 1 and y < size - 1 and m[y][x] == m[y][x + 1] and m[y][x] == m[y + 1][x] and m[y][x] == m[y + 1][x + 1]:
				score += 3
	var total := size * size
	score += (ceili(absf(dark * 20.0 - total * 10.0) / total) - 1) * 10
	return score
