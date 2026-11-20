class_name RunCode
extends RefCounted
## Códigos de partida (hito 23.9): la semilla de una partida, su nivel, el investigador y el
## compañero del J1, los pactos y el grado de locura en 20 letras, «7K2M-QX4A-90BD-R5TE-W3HN». Quien lo
## pega juega la misma noche (las mismas oleadas, baúles, peligros y subidas, como al repetir una
## del archivo de expediciones) para comparar con un amigo sin servidor. Se copia desde la
## pantalla final y desde el archivo; se pega en el archivo (`LibraryMenu`).
##
## 100 bits: versión (2), semilla (31), nivel (18), investigador (12), compañero (10), pactos (8, uno
## por pacto en el orden de `data/pacts.json`), grado de locura (4) y comprobación (15). Nivel,
## investigador y compañero van por una huella de su id (`_hash`), no por su posición en una lista:
## así un código no cambia al añadir niveles o personajes (tests: sin huellas repetidas). Mismo
## alfabeto que la partida del día (O = 0; I y L = 1; guiones y espacios no cuentan).

const VERSION := 1
const LENGTH := 20
const ALPHABET := Daily.ALPHABET
const SALT := 0x5B

## Los campos, en orden: [nombre, bits].
const FIELDS := [["ver", 2], ["seed", 31], ["level", 18], ["character", 12], ["pet", 10], ["pacts", 8], ["madness", 4]]
const CHECK_BITS := 15
const CHECK_MOD := 32749                 ## primo: una letra cambiada siempre se nota

## ¿Se puede compartir? Las mismas que se pueden repetir desde el archivo (no la del día, que ya
## tiene su código, ni la expedición ni el desfile de jefes).
static func shareable(level_id: String) -> bool:
	return level_id != "" and not Daily.is_daily(level_id) and not Expedition.is_expedition(level_id) and not BossRush.is_rush(level_id)

## Código de una partida; "" si no se puede compartir.
static func encode(level_id: String, run_seed: int, character: String, pet: String, pacts: Array, madness: int) -> String:
	if not shareable(level_id) or run_seed <= 0: return ""
	var mask := 0
	var all := pact_ids()
	for p in pacts:
		var k := all.find(String(p))
		if k >= 0 and k < 8: mask |= 1 << k
	var vals := {"ver": VERSION, "seed": run_seed & 0x7FFFFFFF, "level": _hash(level_id, 18),
		"character": _hash(character, 12), "pet": _hash(pet, 10), "pacts": mask, "madness": clampi(madness, 0, 15)}
	var bits := PackedByteArray()
	for f: Array in FIELDS: _put(bits, int(vals[f[0]]), int(f[1]))
	_put(bits, _check(bits), CHECK_BITS)
	var s := ""
	for i in LENGTH:
		var v := 0
		for b in 5: v = (v << 1) | bits[i * 5 + b]
		s += ALPHABET[v]
	return "%s-%s-%s-%s-%s" % [s.substr(0, 4), s.substr(4, 4), s.substr(8, 4), s.substr(12, 4), s.substr(16, 4)]

## El código de una entrada del archivo de expediciones ("" si no se puede).
static func of_run(run: Dictionary) -> String:
	var ps: Array = run.get("players", [])
	if ps.is_empty(): return ""
	var p: Dictionary = ps[0]
	return encode(String(run.get("level", "")), int(run.get("seed", 0)), String(p.get("character", "")),
		String(p.get("pet", "")), run.get("pacts", []), int(run.get("madness", 0)))

## Lee un código: {level, seed, character, pet, pacts, madness, code}; {} si no es válido o no
## corresponde a nada de este juego («error» dice por qué: "letras", "comprobacion", "version",
## "nivel", "investigador").
static func decode(code: String) -> Dictionary:
	var s := code.strip_edges().to_upper().replace("-", "").replace(" ", "").replace("O", "0").replace("I", "1").replace("L", "1")
	if s.length() != LENGTH: return {"error": "letras"}
	var bits := PackedByteArray()
	for ch in s:
		var k := ALPHABET.find(ch)
		if k < 0: return {"error": "letras"}
		_put(bits, k, 5)
	var body := bits.slice(0, bits.size() - CHECK_BITS)
	if _check(body) != _bits_at(bits, body.size(), CHECK_BITS): return {"error": "comprobacion"}
	var vals := {}
	var at := 0
	for f: Array in FIELDS:
		vals[f[0]] = _bits_at(bits, at, int(f[1]))
		at += int(f[1])
	if int(vals.ver) != VERSION: return {"error": "version"}
	var level := _find(level_ids(), int(vals.level), 18)
	if level == "": return {"error": "nivel"}
	var character := _find(Daily.characters(), int(vals.character), 12)
	if character == "": return {"error": "investigador"}
	var pets: Array[String] = [""]
	pets.append_array(pet_ids())
	var pacts: Array = []
	var all := pact_ids()
	for k in mini(all.size(), 8):
		if int(vals.pacts) & (1 << k): pacts.append(all[k])
	var out := {"level": level, "seed": int(vals.seed), "character": character, "pet": _find(pets, int(vals.pet), 10),
		"pacts": pacts, "madness": int(vals.madness)}
	out["code"] = encode(level, out.seed, character, out.pet, pacts, out.madness)
	return out

## Lo que dice al jugador un código que no vale.
static func error_text(d: Dictionary) -> String:
	match String(d.get("error", "")):
		"letras": return L.t("No es un código de partida (20 letras, como 7K2M-QX4A-90BD-R5TE-W3HN): revisa las letras.")
		"comprobacion": return L.t("Alguna letra no cuadra: revisa el código.")
		"version": return L.t("Ese código es de otra versión del juego.")
		"nivel": return L.t("Ese código es de un nivel que este juego no tiene.")
		"investigador": return L.t("Ese código es de un investigador que este juego no tiene.")
	return ""

## ¿Puede jugarlo este hueco? Lo mismo que en el mapa: el nivel abierto (la noche, el desafío o la
## noche eterna, abiertos), y nada que la demo no tenga.
static func open_for(save: SaveData, level_id: String) -> bool:
	if save == null: return false
	var base := Endless.base_of(level_id)
	if not Demo.level_ok(base): return false
	if Endless.is_endless(level_id): return Endless.unlocked(save)
	if Challenge.is_challenge(level_id): return Challenge.unlocked(save, base)
	if Nights.is_night(level_id): return Nights.unlocked(save, level_id)
	return save.unlock_all or save.levels_won.has(level_id) or Campaign.is_playable(level_id, save.levels_won)

## Deja la sesión lista para jugarlo (con el J1, desde `device`): como repetir una del archivo.
static func prepare(d: Dictionary, device: int) -> void:
	var save := Auto.save()
	var worn: Dictionary = (save.worn.get(String(d.character), {}) as Dictionary).duplicate() if save != null else {}
	RunArchive.prepare({"level": d.level, "seed": d.seed, "pacts": d.pacts, "madness": d.madness,
		"players": [{"character": d.character, "pet": d.pet, "worn": worn}]}, device)

## Una línea con lo que trae: «Calles de Innsmouth · Carter con el gato · pactos: … · locura 2».
static func describe(d: Dictionary) -> String:
	var parts := PackedStringArray([RunArchive.place({"level": d.level})])
	var who := DailyMenu._res_name("characters", String(d.character))
	if String(d.pet) != "": who += L.t(" con ") + DailyMenu._res_name("pets", String(d.pet)).to_lower()
	parts.append(who)
	if not (d.pacts as Array).is_empty(): parts.append(L.t("Pactos: ") + Pacts.names(d.pacts))
	if int(d.madness) > 0: parts.append(L.t("Locura: ") + Madness.title(int(d.madness)))
	return "  ·  ".join(parts)

## Todos los niveles que puede nombrar un código: la campaña, las noches sueltas, sus desafíos y la
## noche eterna sobre cada escenario de la campaña.
static func level_ids() -> Array[String]:
	var out: Array[String] = []
	var base: Array[String] = []
	for l in Campaign.levels(): base.append(String(l.id))
	for n: Dictionary in Nights.all(): base.append(String(n.id))
	for id in base:
		out.append(id)
		out.append(Challenge.id_for(id))
	for l in Campaign.levels(): out.append(Endless.id_for(String(l.id)))
	return out

static func pet_ids() -> Array[String]:
	return Daily._ids("res://data/pets")

static func pact_ids() -> Array[String]:
	var out: Array[String] = []
	for p: Dictionary in Pacts.all(): out.append(String(p.id))
	return out

## Huella de `bits` bits de un id (estable: md5, no el hash del motor).
static func _hash(id: String, bits: int) -> int:
	var b := id.md5_buffer()
	return ((b[0] << 16) | (b[1] << 8) | b[2]) & ((1 << bits) - 1)

static func _find(ids: Array, h: int, bits: int) -> String:
	for id in ids:
		if _hash(String(id), bits) == h: return String(id)
	return ""

static func _put(bits: PackedByteArray, v: int, n: int) -> void:
	for i in range(n - 1, -1, -1): bits.append((v >> i) & 1)

static func _bits_at(bits: PackedByteArray, at: int, n: int) -> int:
	var v := 0
	for i in n: v = (v << 1) | bits[at + i]
	return v

static func _check(bits: PackedByteArray) -> int:
	var c := SALT
	for i in bits.size(): c = (c * 31 + bits[i] * (i + 7)) % CHECK_MOD
	return c
