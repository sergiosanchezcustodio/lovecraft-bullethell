extends RefCounted
## Animaciones del shoggoth bebé (compañero). Partes: body, top. El modelo mira hacia +Z.
## Es una gota: se mueve estirándose y encogiéndose, sin patas; "bite" es tragarse una bala.

const DURATION := {"idle": 1.6, "walk": 0.5, "run": 0.34, "bite": 0.3}

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

## Quieto: palpita y el bulto de arriba se balancea.
static func idle(m: Node3D, t: float) -> void:
	var s := sin(t * TAU)
	m.scale = Vector3(1.0 + 0.04 * s, 1.0 - 0.05 * s, 1.0 + 0.04 * s)
	_p(m, "top").rotation = Vector3(0.1 * sin(t * TAU + 1.0), 0.0, 0.12 * s)

## Avanza a latidos: se estira hacia delante y se aplasta.
static func walk(m: Node3D, t: float) -> void:
	_ooze(m, t, 0.12)

static func run(m: Node3D, t: float) -> void:
	_ooze(m, t, 0.2)

static func _ooze(m: Node3D, t: float, k: float) -> void:
	var s := sin(t * TAU)
	m.scale = Vector3(1.0 - k * 0.5 * s, 1.0 - k * s, 1.0 + k * s)
	_p(m, "top").rotation.x = -0.3 * k / 0.12 * maxf(s, 0.0)
	m.position.y = absf(s) * 0.02

## Trago: se hincha de golpe y vuelve.
static func bite(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	m.scale = Vector3(1.0 + 0.2 * k, 1.0 + 0.25 * k, 1.0 + 0.2 * k)
	_p(m, "top").position.y += 0.03 * k
