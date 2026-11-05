extends RefCounted
## Animaciones de los compañeros sin patas y en segmentos (serpiente de Yig, Mini-Dhole).
## Partes: head, s1..s4 (s1 junto a la cabeza). El modelo mira hacia +Z. Reptan con una onda
## lateral que recorre el cuerpo (desplazando cada segmento, que son piezas sueltas).

const DURATION := {"idle": 2.0, "walk": 0.7, "run": 0.45, "bite": 0.35,
	"fidget_coil": 4.2, "fidget_tongue": 1.6}
const SEGS := ["s1", "s2", "s3", "s4"]
## Gestos de reposo (hito 17.7): se enrosca y saca la lengua; alza la cabeza y la saca.
const FIDGETS := ["fidget_coil", "fidget_tongue"]
const TONGUE_IN := 0.15                         ## m que se mete la lengua dentro de la cabeza
const SEG_LEN := 0.1875                         ## largo de cada segmento (9 voxels de 1/48 m)

## La lengua (solo la de Yig): dentro de la cabeza salvo cuando la saca (out 0..1).
static func _tongue(m: Node3D, out: float) -> void:
	var parts: Dictionary = m.get_meta("part_nodes", {})
	if not parts.has("tongue"): return
	var tg: Node3D = parts["tongue"]
	if not tg.has_meta("rest_z"): tg.set_meta("rest_z", tg.position.z)   # la primera vez, en reposo
	tg.position.z = float(tg.get_meta("rest_z")) - TONGUE_IN * (1.0 - out)

## Saca la lengua a latigazos: n veces en lo que dura t (0..1).
static func _flicks(t: float, n: float) -> float:
	if t <= 0.0 or t >= 1.0: return 0.0
	return clampf(sin(t * PI * 2.0 * n) * 1.6, 0.0, 1.0)

## Se enrosca: el cuerpo se dobla en espiral junto a la cabeza, alza la cabeza y saca la lengua;
## luego se estira otra vez.
static func fidget_coil(m: Node3D, t: float) -> void:
	idle(m, fmod(t * 2.0, 1.0))
	var k := Anims.ease(t / 0.2) * (1.0 - Anims.ease((t - 0.8) / 0.2))
	coil(m, k)
	_p(m, "head").position.y += 0.05 * k
	_p(m, "head").rotation.x = -0.25 * k
	_tongue(m, _flicks((t - 0.3) / 0.45, 3.0))

## Enroscarse (k 0..1): cambia la recta del cuerpo por una espiral que gira hacia +X (cada
## segmento, una cuerda que gira un poco más que la anterior).
static func coil(m: Node3D, k: float) -> void:
	if k <= 0.0: return
	var start := _p(m, SEGS[0]).position             # el primer segmento arranca donde está
	var p := start
	var dir := Vector3(0, 0, -1)
	for i in SEGS.size():
		var seg := _p(m, SEGS[i])
		if seg == null: break
		var a := atan2(-dir.x, -dir.z)                # giro que lleva -Z a dir
		var rest := start + Vector3(0, 0, -SEG_LEN * i)
		seg.position += (p - rest) * k
		seg.rotation.y = lerp_angle(seg.rotation.y, a, k)
		p += dir * SEG_LEN
		dir = dir.rotated(Vector3.UP, -deg_to_rad(62.0 + 16.0 * i))   # cada vez más cerrado

## Dormida (hito 17.8): enroscada, la cabeza apoyada encima.
static func sleep(m: Node3D, k: float, t: float) -> void:
	coil(m, k)
	_p(m, "head").rotation.x = 0.12 * k
	_p(m, "head").position.y += (0.02 + 0.004 * sin(t * 1.6)) * k

## Alza la cabeza, mira fijo y saca la lengua dos veces.
static func fidget_tongue(m: Node3D, t: float) -> void:
	idle(m, fmod(t, 1.0))
	var k := Anims.ease(t / 0.25) * (1.0 - Anims.ease((t - 0.75) / 0.25))
	_p(m, "head").position.y += 0.06 * k
	_p(m, "head").rotation.x = -0.3 * k
	_tongue(m, _flicks((t - 0.25) / 0.5, 2.0))

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

static func _wave(m: Node3D, t: float, amp: float) -> void:
	for i in SEGS.size():
		_p(m, SEGS[i]).position.x += sin(t * TAU - i * 1.1) * amp * (0.5 + 0.5 * i / 3.0)
	_p(m, "head").position.x += sin(t * TAU + 1.1) * amp * 0.4
	_p(m, "head").rotation.y = cos(t * TAU + 1.1) * 0.25 * amp / 0.04
	_tongue(m, 0.0)

## Quieta: la cabeza se mece despacio, mirando fijo.
static func idle(m: Node3D, t: float) -> void:
	_wave(m, t, 0.012)
	_p(m, "head").position.y += 0.01 + sin(t * TAU) * 0.008

static func walk(m: Node3D, t: float) -> void:
	_wave(m, t, 0.035)

static func run(m: Node3D, t: float) -> void:
	_wave(m, t, 0.05)

## Ataque: se echa atrás y lanza la cabeza hacia delante.
static func bite(m: Node3D, t: float) -> void:
	var back := sin(clampf(t / 0.35, 0.0, 1.0) * PI * 0.5) * (1.0 - clampf((t - 0.35) / 0.2, 0.0, 1.0))
	var fwd := sin(clampf((t - 0.35) / 0.65, 0.0, 1.0) * PI)
	_p(m, "head").position.z += -0.04 * back + 0.12 * fwd
	_p(m, "head").position.y += 0.04 * back
	_p(m, "s1").position.z += 0.06 * fwd
	_tongue(m, fwd)
