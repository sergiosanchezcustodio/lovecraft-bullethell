extends RefCounted
## Animaciones de los compañeros de cuatro patas (perro de trineo, gato de Ulthar, rata).
## Partes: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail. El modelo mira hacia +Z.

const DURATION := {"idle": 2.4, "walk": 0.5, "run": 0.34, "bite": 0.35}

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

## Quieto: respira, mueve el rabo y mira un poco a los lados.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	_p(m, "body").position.y += sin(w * 2.0) * 0.004
	_p(m, "head").rotation = Vector3(sin(w) * 0.05, sin(w * 0.5) * 0.25, 0.0)
	_p(m, "tail").rotation = Vector3(0.0, 0.0, sin(w * 3.0) * 0.35)

## Andar: patas en diagonal (delantera izquierda con trasera derecha).
static func walk(m: Node3D, t: float) -> void:
	_gait(m, t, 0.45, 0.015)

## Correr: zancadas más largas, el cuerpo sube y baja más.
static func run(m: Node3D, t: float) -> void:
	_gait(m, t, 0.75, 0.035)
	_p(m, "head").rotation.x += 0.12

static func _gait(m: Node3D, t: float, amp: float, bob: float) -> void:
	var s := sin(t * TAU)
	_p(m, "leg_fl").rotation.x = s * amp
	_p(m, "leg_br").rotation.x = s * amp
	_p(m, "leg_fr").rotation.x = -s * amp
	_p(m, "leg_bl").rotation.x = -s * amp
	m.position.y = absf(cos(t * TAU)) * bob
	_p(m, "head").rotation.x = sin(t * TAU * 2.0) * 0.05
	_p(m, "tail").rotation = Vector3(0.0, 0.0, sin(t * TAU * 2.0) * 0.4)

## Mordisco: se echa hacia delante y cierra la cabeza de golpe.
static func bite(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	_p(m, "body").rotation.x = 0.12 * k
	_p(m, "head").rotation.x = 0.45 * k
	_p(m, "head").position.z += 0.06 * k
	_p(m, "tail").rotation.z = 0.5 * k
