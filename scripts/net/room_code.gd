class_name RoomCode
extends RefCounted
## Código de sala (hito 9.1, D-10): la IP (v4) y el puerto del anfitrión en 8 letras, como
## "K7Q2-M9XA", para dictarlo o copiarlo. 40 bits: 32 de la IP, 3 del puerto (BASE_PORT + 0..7)
## y 5 de comprobación, que detecta casi todas las erratas. Alfabeto de Crockford (sin I, L, O
## ni U): al leerlo, la O vale 0 y la I y la L valen 1, y se ignoran guiones y espacios.
## Lo que lleva un punto o dos puntos se toma como dirección escrita a mano (IPv4 o IPv6, con
## puerto opcional: "1.2.3.4:24681", "[::1]:24680").

const BASE_PORT := 24680
const PORTS := 8                            ## puertos que caben en el código: BASE_PORT .. BASE_PORT + 7
const ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"

## Código de `ip` (IPv4) y `port` (BASE_PORT .. BASE_PORT + 7). Vacío si no cabe.
static func encode(ip: String, port: int = BASE_PORT) -> String:
	var a := _ipv4(ip)
	if a < 0 or port < BASE_PORT or port >= BASE_PORT + PORTS: return ""
	var v := (a << 8) | ((port - BASE_PORT) << 5) | _check(a, port - BASE_PORT)
	var s := ""
	for i in 8:
		s = ALPHABET[v & 31] + s
		v >>= 5
	return s.substr(0, 4) + "-" + s.substr(4)

## Lo que ha escrito el jugador -> {ip, port}, o {} si no se entiende o la comprobación falla.
static func parse(text: String) -> Dictionary:
	var t := text.strip_edges()
	if t.is_empty(): return {}
	if "." in t or ":" in t: return _address(t)
	var v := 0
	var n := 0
	for raw in t.to_upper():
		if raw == "-" or raw == " ": continue
		var ch: String = "0" if raw == "O" else ("1" if raw == "I" or raw == "L" else raw)
		var k := ALPHABET.find(ch)
		if k < 0: return {}
		v = (v << 5) | k
		n += 1
	if n != 8: return {}
	var a := v >> 8
	var p := (v >> 5) & 7
	if v & 31 != _check(a, p): return {}
	return {"ip": "%d.%d.%d.%d" % [(a >> 24) & 255, (a >> 16) & 255, (a >> 8) & 255, a & 255], "port": BASE_PORT + p}

## IPv4 privada (la de la red de casa): 10/8, 172.16/12, 192.168/16.
static func is_private(ip: String) -> bool:
	var a := _ipv4(ip)
	if a < 0: return false
	return (a >> 24) == 10 or (a >> 20) == (172 << 4 | 1) or (a >> 16) == (192 << 8 | 168)

## IP de este PC en la red de casa (la primera privada, mejor 192.168.x), o "".
static func local_ip() -> String:
	var best := ""
	for ip in IP.get_local_addresses():
		if not is_private(ip): continue
		if ip.begins_with("192.168."): return ip
		if best == "": best = ip
	return best

static func _address(t: String) -> Dictionary:
	var host := t
	var port := BASE_PORT
	if t.begins_with("["):                          # [IPv6]:puerto
		var close := t.find("]")
		if close < 0: return {}
		host = t.substr(1, close - 1)
		var rest := t.substr(close + 1)
		if rest.begins_with(":"): port = rest.substr(1).to_int()
	elif t.count(":") == 1:                         # IPv4:puerto (una IPv6 lleva varios)
		host = t.get_slice(":", 0)
		port = t.get_slice(":", 1).to_int()
	if host.is_empty() or port <= 0 or port > 65535: return {}
	if not ":" in host and _ipv4(host) < 0: return {}
	return {"ip": host, "port": port}

static func _ipv4(ip: String) -> int:
	var parts := ip.strip_edges().split(".")
	if parts.size() != 4: return -1
	var v := 0
	for p in parts:
		if not p.is_valid_int(): return -1
		var k := p.to_int()
		if k < 0 or k > 255: return -1
		v = (v << 8) | k
	return v

static func _check(a: int, p: int) -> int:
	var h := (a ^ (p * 0x9E3779B1)) & 0xFFFFFFFF
	h = ((h >> 16) ^ h) * 0x45D9F3B & 0xFFFFFFFF
	h = (h >> 16) ^ h
	return h & 31
