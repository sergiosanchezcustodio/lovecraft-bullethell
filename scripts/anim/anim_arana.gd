extends RefCounted
## Animaciones de las arañas de Leng (hito 21.10). Partes: body (cefalotórax), abdomen y ocho patas,
## leg_l1..leg_l4 y leg_r1..leg_r4 (1 delante, 4 detrás), que salen a los lados (±X). El modelo mira
## hacia +Z. Anda con el paso de las arañas: dos cuaternas alternas (l1, r2, l3, r4 y r1, l2, r3, l4)
## que se levantan y adelantan a la vez.

const DURATION := {"idle": 2.0, "walk": 0.6, "run": 0.36, "bite": 0.5}
const A := ["leg_l1", "leg_r2", "leg_l3", "leg_r4"]
const LEGS := ["leg_l1", "leg_l2", "leg_l3", "leg_l4", "leg_r1", "leg_r2", "leg_r3", "leg_r4"]

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

static func _side(n: String) -> float:
	return 1.0 if n.begins_with("leg_r") else -1.0

## Quieta: el abdomen respira y alguna pata tantea el suelo.
static func idle(m: Node3D, t: float) -> void:
	var b := sin(t * TAU)
	_p(m, "abdomen").scale = Vector3(1.0 + 0.03 * b, 1.0 + 0.04 * b, 1.0 + 0.03 * b)
	var tap := maxf(0.0, sin(t * TAU * 2.0)) * (1.0 if t < 0.5 else 0.0)
	_p(m, "leg_l1").rotation.z = -0.25 * tap
	_p(m, "leg_r1").rotation.z = 0.25 * (maxf(0.0, sin(t * TAU * 2.0)) if t >= 0.5 else 0.0)

static func _gait(m: Node3D, t: float, swing: float, lift: float, bob: float) -> void:
	for n: String in LEGS:
		var ph := t + (0.0 if n in A else 0.5)
		var s := _side(n)
		var p := _p(m, n)
		p.rotation.y = sin(ph * TAU) * swing * s
		p.rotation.z = maxf(0.0, cos(ph * TAU)) * lift * s
	m.position.y = absf(sin(t * TAU * 2.0)) * bob
	_p(m, "abdomen").rotation.y = sin(t * TAU) * 0.06
	_p(m, "abdomen").rotation.x = sin(t * TAU * 2.0) * 0.03

static func walk(m: Node3D, t: float) -> void:
	_gait(m, t, 0.32, 0.35, 0.02)

static func run(m: Node3D, t: float) -> void:
	_gait(m, t, 0.42, 0.45, 0.035)

## Muerde: se encabrita con las patas de delante en alto y cae de golpe sobre la presa.
static func bite(m: Node3D, t: float) -> void:
	var up := sin(clampf(t / 0.6, 0.0, 1.0) * PI * 0.5) * (1.0 - clampf((t - 0.6) / 0.25, 0.0, 1.0))
	m.rotation.x = -0.35 * up
	for n: String in ["leg_l1", "leg_r1"]: _p(m, n).rotation.z = 0.9 * up * _side(n)
	for n: String in ["leg_l2", "leg_r2"]: _p(m, n).rotation.z = 0.4 * up * _side(n)
	_p(m, "abdomen").rotation.x = 0.25 * up
