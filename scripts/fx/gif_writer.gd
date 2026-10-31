class_name GifWriter
extends RefCounted
## GIF animado en bucle a partir de imágenes RGB8 del mismo tamaño (la repetición de la caída,
## para compartirla). Una paleta común de 256 colores: los más frecuentes, contados a 5 bits por
## canal, cada uno la media de lo que cae en su casilla; cada casilla, a su color más cercano.
## Sin tramado: en las escenas oscuras del juego da menos ruido. LZW con tabla plana (sin
## diccionarios), para que 60 imágenes de 384×216 tarden unos segundos; llámalo desde un hilo.

## Bytes del GIF; `delay_cs`, centésimas de segundo entre imágenes.
static func encode(frames: Array[Image], delay_cs: int) -> PackedByteArray:
	var w := frames[0].get_width()
	var h := frames[0].get_height()
	var datas: Array[PackedByteArray] = []
	for f in frames:
		var im := f
		if im.get_format() != Image.FORMAT_RGB8:
			im = f.duplicate()
			im.convert(Image.FORMAT_RGB8)
		datas.append(im.get_data())
	var pal := _palette(datas)
	var lut := PackedInt32Array()
	lut.resize(32768)
	lut.fill(-1)
	var out := PackedByteArray()
	out.append_array("GIF89a".to_ascii_buffer())
	_u16(out, w); _u16(out, h)
	out.append_array(PackedByteArray([0xF7, 0, 0]))      # tabla global de 256 colores
	for c in pal: out.append_array(PackedByteArray([c.r8, c.g8, c.b8]))
	out.append_array(PackedByteArray([0x21, 0xFF, 0x0B]))   # bucle sin fin
	out.append_array("NETSCAPE2.0".to_ascii_buffer())
	out.append_array(PackedByteArray([3, 1, 0, 0, 0]))
	var idx := PackedByteArray()
	idx.resize(w * h)
	for d in datas:
		for i in w * h:
			var r := d[i * 3]; var g := d[i * 3 + 1]; var b := d[i * 3 + 2]
			var key := ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3)
			var p := lut[key]
			if p < 0:
				p = _nearest(pal, Color8((r & 0xF8) | 4, (g & 0xF8) | 4, (b & 0xF8) | 4))
				lut[key] = p
			idx[i] = p
		out.append_array(PackedByteArray([0x21, 0xF9, 4, 0]))
		_u16(out, delay_cs)
		out.append_array(PackedByteArray([0, 0, 0x2C, 0, 0, 0, 0]))
		_u16(out, w); _u16(out, h)
		out.append_array(PackedByteArray([0, 8]))
		var lzw := _lzw(idx)
		var i := 0
		while i < lzw.size():                          # en bloques de 255
			var n := mini(255, lzw.size() - i)
			out.append(n)
			out.append_array(lzw.slice(i, i + n))
			i += n
		out.append(0)
	out.append(0x3B)
	return out

static func _u16(out: PackedByteArray, v: int) -> void:
	out.append(v & 0xFF)
	out.append((v >> 8) & 0xFF)

## Los 256 colores más frecuentes (casillas de 5 bits por canal, media de cada casilla).
static func _palette(datas: Array[PackedByteArray]) -> Array[Color]:
	var cnt := PackedInt32Array(); cnt.resize(32768)
	var sr := PackedInt64Array(); sr.resize(32768)
	var sg := PackedInt64Array(); sg.resize(32768)
	var sb := PackedInt64Array(); sb.resize(32768)
	for d in datas:
		var i := 0
		while i < d.size():                            # uno de cada tres píxeles basta
			var r := d[i]; var g := d[i + 1]; var b := d[i + 2]
			var k := ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3)
			cnt[k] += 1; sr[k] += r; sg[k] += g; sb[k] += b
			i += 9
	var keys: Array[int] = []
	for k in 32768:
		if cnt[k] > 0: keys.append(k)
	keys.sort_custom(func(a: int, b: int) -> bool: return cnt[a] > cnt[b])
	var pal: Array[Color] = []
	for k in keys.slice(0, 256):
		pal.append(Color8(sr[k] / cnt[k], sg[k] / cnt[k], sb[k] / cnt[k]))
	while pal.size() < 256: pal.append(Color.BLACK)
	return pal

static func _nearest(pal: Array[Color], c: Color) -> int:
	var best := 0
	var bd := INF
	for i in pal.size():
		var p := pal[i]
		var d := (p.r - c.r) * (p.r - c.r) * 0.3 + (p.g - c.g) * (p.g - c.g) * 0.59 + (p.b - c.b) * (p.b - c.b) * 0.11
		if d < bd:
			bd = d
			best = i
	return best

## LZW de GIF con 8 bits por píxel (códigos de 9 a 12 bits). La tabla es plana:
## tab[prefijo * 256 + píxel] = generación << 12 | código; al vaciarla basta subir la generación.
static func _lzw(px: PackedByteArray) -> PackedByteArray:
	const CLEAR := 256
	const EOI := 257
	var tab := PackedInt32Array(); tab.resize(4096 * 256)
	var gen := 1
	var out := PackedByteArray()
	var acc := 0
	var nbits := 0
	var cs := 9
	var nxt := 258
	# emite un código: inline abajo para ir deprisa (bits acumulados de menor a mayor)
	acc |= CLEAR << nbits; nbits += cs
	while nbits >= 8:
		out.append(acc & 0xFF); acc >>= 8; nbits -= 8
	var prefix := px[0]
	for i in range(1, px.size()):
		var k := px[i]
		var key := (prefix << 8) | k
		var v := tab[key]
		if (v >> 12) == gen:
			prefix = v & 4095
			continue
		acc |= prefix << nbits; nbits += cs
		while nbits >= 8:
			out.append(acc & 0xFF); acc >>= 8; nbits -= 8
		tab[key] = (gen << 12) | nxt
		nxt += 1
		if nxt > (1 << cs) and cs < 12: cs += 1
		if nxt == 4096:                                # tabla llena: se vacía
			acc |= CLEAR << nbits; nbits += cs
			while nbits >= 8:
				out.append(acc & 0xFF); acc >>= 8; nbits -= 8
			gen += 1
			cs = 9
			nxt = 258
		prefix = k
	acc |= prefix << nbits; nbits += cs
	acc |= EOI << nbits; nbits += cs
	while nbits > 0:
		out.append(acc & 0xFF); acc >>= 8; nbits -= 8
	return out
