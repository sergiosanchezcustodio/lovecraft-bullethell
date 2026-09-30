extends RefCounted
## Animaciones del pez de Innsmouth (compañero): un pez de pie sobre dos piernas humanas que
## se cree un caballero. Partes: body, leg_l, leg_r, fin_l, fin_r, tail. Mira hacia +Z.

const DURATION := {"idle": 1.6, "walk": 0.5, "run": 0.34, "bite": 0.4}

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

## Quieto: boquea y agita las aletas como quien se arregla la pajarita.
static func idle(m: Node3D, t: float) -> void:
	var s := sin(t * TAU)
	_p(m, "body").rotation.x = 0.03 * s
	_p(m, "fin_l").rotation.z = -0.2 - 0.15 * s
	_p(m, "fin_r").rotation.z = 0.2 + 0.15 * s
	_p(m, "tail").rotation.y = 0.2 * sin(t * TAU * 2.0)

## Anda muy tieso, bamboleándose, con las aletas balanceando como brazos.
static func walk(m: Node3D, t: float) -> void:
	_waddle(m, t, 0.5)

static func run(m: Node3D, t: float) -> void:
	_waddle(m, t, 0.8)
	_p(m, "body").rotation.x += 0.25

static func _waddle(m: Node3D, t: float, amp: float) -> void:
	var s := sin(t * TAU)
	_p(m, "leg_l").rotation.x = s * amp
	_p(m, "leg_r").rotation.x = -s * amp
	_p(m, "body").rotation.z = s * 0.08
	m.position.y = absf(cos(t * TAU)) * 0.02
	_p(m, "fin_l").rotation.x = -s * amp * 0.8
	_p(m, "fin_r").rotation.x = s * amp * 0.8
	_p(m, "tail").rotation.y = s * 0.35

## Embestida: se inclina hacia delante con la cabeza por delante.
static func bite(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	_p(m, "body").rotation.x = 0.55 * k
	_p(m, "fin_l").rotation.x = -0.9 * k
	_p(m, "fin_r").rotation.x = -0.9 * k
	_p(m, "tail").rotation.x = -0.4 * k
