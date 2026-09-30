extends RefCounted
## Animaciones de los compañeros que vuelan (búho de los sueños). Partes: body, head, wing_l,
## wing_r. El modelo mira hacia +Z; la altura de vuelo la pone Pet. Siempre en el aire: en
## reposo aletea despacio y planea; al moverse aletea más y se inclina hacia delante.

const DURATION := {"idle": 0.9, "walk": 0.45, "run": 0.32, "bite": 0.5}

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

static func _flap(m: Node3D, t: float, amp: float, lean: float) -> void:
	var s := sin(t * TAU)
	_p(m, "wing_l").rotation.z = -(0.35 + amp * s)
	_p(m, "wing_r").rotation.z = 0.35 + amp * s
	m.position.y = -s * 0.03
	m.rotation.x = lean

## Planea: aleteo lento y la cabeza gira a un lado y a otro, como los búhos.
static func idle(m: Node3D, t: float) -> void:
	_flap(m, t, 0.45, 0.0)
	_p(m, "head").rotation.y = sin(t * TAU * 0.25) * 0.6

static func walk(m: Node3D, t: float) -> void:
	_flap(m, t, 0.8, 0.2)

static func run(m: Node3D, t: float) -> void:
	_flap(m, t, 1.0, 0.35)

## Ulula: abre las alas, ahueca el pecho y cabecea.
static func bite(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	_p(m, "wing_l").rotation.z = -1.1 * k
	_p(m, "wing_r").rotation.z = 1.1 * k
	_p(m, "body").scale = Vector3.ONE * (1.0 + 0.08 * k)
	_p(m, "head").rotation.x = 0.3 * sin(t * TAU * 2.0) * k
