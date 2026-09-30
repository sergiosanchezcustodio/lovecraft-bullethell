extends RefCounted
## Animaciones de los compañeros sin patas y en segmentos (serpiente de Yig, Mini-Dhole).
## Partes: head, s1..s4 (s1 junto a la cabeza). El modelo mira hacia +Z. Reptan con una onda
## lateral que recorre el cuerpo (desplazando cada segmento, que son piezas sueltas).

const DURATION := {"idle": 2.0, "walk": 0.7, "run": 0.45, "bite": 0.35}
const SEGS := ["s1", "s2", "s3", "s4"]

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

static func _wave(m: Node3D, t: float, amp: float) -> void:
	for i in SEGS.size():
		_p(m, SEGS[i]).position.x += sin(t * TAU - i * 1.1) * amp * (0.5 + 0.5 * i / 3.0)
	_p(m, "head").position.x += sin(t * TAU + 1.1) * amp * 0.4
	_p(m, "head").rotation.y = cos(t * TAU + 1.1) * 0.25 * amp / 0.04

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
