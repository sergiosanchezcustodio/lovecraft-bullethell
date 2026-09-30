extends RefCounted
## Animaciones del sapo de Innsmouth (compañero). Partes: body, head, leg_fl, leg_fr, leg_bl,
## leg_br. El modelo mira hacia +Z. Anda a saltitos; "bite" es el escupitajo.

const DURATION := {"idle": 1.8, "walk": 0.55, "run": 0.4, "bite": 0.45}

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

## Quieto: la garganta late y la cabeza se inclina un poco.
static func idle(m: Node3D, t: float) -> void:
	var k := maxf(0.0, sin(t * TAU * 2.0))
	_p(m, "head").scale = Vector3(1.0, 1.0 + 0.05 * k, 1.0 + 0.04 * k)
	_p(m, "head").rotation.x = -0.04 * sin(t * TAU)

## Saltito: se agacha, las patas de atrás se estiran, vuela un poco y cae.
static func walk(m: Node3D, t: float) -> void:
	_hop(m, t, 0.12)

static func run(m: Node3D, t: float) -> void:
	_hop(m, t, 0.2)

static func _hop(m: Node3D, t: float, h: float) -> void:
	var air := clampf((t - 0.25) / 0.6, 0.0, 1.0)
	var up := sin(air * PI)
	m.position.y = up * h
	m.rotation.x = -0.25 * up + 0.15 * sin(air * PI * 2.0) * up
	var push := sin(clampf(t / 0.5, 0.0, 1.0) * PI)
	_p(m, "leg_bl").rotation.x = 0.9 * push
	_p(m, "leg_br").rotation.x = 0.9 * push
	_p(m, "leg_fl").rotation.x = -0.5 * up
	_p(m, "leg_fr").rotation.x = -0.5 * up

## Escupitajo: echa la cabeza atrás, hincha la garganta y la lanza hacia delante.
static func bite(m: Node3D, t: float) -> void:
	var back := sin(clampf(t / 0.45, 0.0, 1.0) * PI * 0.5)
	var fwd := sin(clampf((t - 0.45) / 0.55, 0.0, 1.0) * PI)
	_p(m, "head").rotation.x = -0.35 * back * (1.0 - fwd) + 0.3 * fwd
	_p(m, "head").scale = Vector3.ONE * (1.0 + 0.12 * back * (1.0 - fwd))
	m.rotation.x = 0.1 * fwd
