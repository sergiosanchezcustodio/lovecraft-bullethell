extends RefCounted
## Animaciones de los Antiguos (tools/gen_antiguo.py). Partes: body, head, arms, wing_l,
## wing_r, leg0..leg4 (cinco patas en estrella). Mira hacia +Z.

const DURATION := {"idle": 2.0, "walk": 0.9, "lash": 0.7, "fly": 0.55, "dive": 0.6}

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

## Quieto: la estrella de la cabeza gira despacio y los tentáculos se mecen.
static func idle(m: Node3D, t: float) -> void:
	var s := sin(t * TAU)
	_p(m, "head").rotation.y = 0.25 * s
	_p(m, "arms").rotation.y = -0.15 * s
	_p(m, "body").rotation.x = 0.02 * s
	_wings(m, 0.05 * s)

## Andar: las cinco patas se levantan por turnos (como una estrella de mar) y el barril
## se balancea.
static func walk(m: Node3D, t: float) -> void:
	for i in 5:
		var ph := t * TAU + i * TAU / 5.0
		var a := i / 5.0 * TAU
		var lift := maxf(0.0, sin(ph)) * 0.45
		var leg := _p(m, "leg%d" % i)
		leg.rotation = Vector3(-sin(a) * lift, 0, cos(a) * lift)
	m.position.y = absf(sin(t * TAU * 2.5)) * 0.03
	_p(m, "body").rotation.z = 0.05 * sin(t * TAU)
	_p(m, "head").rotation.y = 0.2 * sin(t * TAU)
	_p(m, "arms").rotation.y = 0.25 * sin(t * TAU + 1.0)
	_wings(m, 0.05)

## Latigazo: los tentáculos giran de golpe y la cabeza se inclina hacia delante.
static func lash(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	_p(m, "arms").rotation.y = TAU * 0.4 * t
	_p(m, "arms").rotation.x = 0.4 * k
	_p(m, "head").rotation.x = 0.35 * k
	_p(m, "body").rotation.x = 0.12 * k

## Vuelo: aleteo amplio, patas recogidas.
static func fly(m: Node3D, t: float) -> void:
	_wings(m, 0.55 * sin(t * TAU))
	for i in 5:
		var a := i / 5.0 * TAU
		_p(m, "leg%d" % i).rotation = Vector3(-sin(a) * 0.6, 0, cos(a) * 0.6)
	_p(m, "head").rotation.y = 0.3 * sin(t * TAU * 0.5)
	_p(m, "arms").rotation.x = 0.2 * sin(t * TAU)

## Picado: alas pegadas hacia atrás y el cuerpo inclinado hacia delante.
static func dive(m: Node3D, t: float) -> void:
	_wings(m, -0.6)
	_p(m, "body").rotation.x = 0.5
	_p(m, "head").rotation.x = 0.4
	for i in 5:
		var a := i / 5.0 * TAU
		_p(m, "leg%d" % i).rotation = Vector3(-sin(a) * 0.7, 0, cos(a) * 0.7)

static func _wings(m: Node3D, ang: float) -> void:
	_p(m, "wing_l").rotation.z = ang
	_p(m, "wing_r").rotation.z = -ang
