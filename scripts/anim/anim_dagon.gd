extends RefCounted
## Padre Dagon (hito 6.6): asoma del mar de cintura para arriba. No anda: se balancea, golpea
## con una mano o con las dos, ruge y se hunde o emerge.

const DURATION := {"idle": 3.0, "slam_l": 1.6, "slam_r": 1.6, "slam_both": 1.8, "roar": 1.5, "sink": 1.2, "emerge": 1.4}

## Respira y se mece con el oleaje; la cabeza vigila.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	Anims.part(m, "torso").rotation = Vector3(sin(w) * 0.03, 0, sin(w * 0.5) * 0.04)
	Anims.part(m, "head").rotation = Vector3(sin(w * 2.0) * 0.04, sin(w) * 0.22, 0)
	Anims.part(m, "arm_l").rotation.x = sin(w + 0.6) * 0.04
	Anims.part(m, "arm_r").rotation.x = sin(w + 2.2) * 0.04
	m.position.y = sin(w) * 0.06

## Levanta el brazo hacia el cielo y lo deja caer: 0-0.55 sube, 0.55-0.68 cae, luego vuelve.
static func _slam_arm(m: Node3D, arm: String, t: float) -> void:
	var a := 0.0
	if t < 0.55: a = -1.15 * Anims.ease(t / 0.55)
	elif t < 0.68: a = lerpf(-1.15, 0.12, (t - 0.55) / 0.13)
	else: a = 0.12 * (1.0 - Anims.ease((t - 0.68) / 0.32))
	Anims.part(m, arm).rotation.x = a
	Anims.part(m, "torso").rotation.x = -a * 0.12

static func slam_l(m: Node3D, t: float) -> void:
	_slam_arm(m, "arm_l", t)
	Anims.part(m, "head").rotation.y = 0.25

static func slam_r(m: Node3D, t: float) -> void:
	_slam_arm(m, "arm_r", t)
	Anims.part(m, "head").rotation.y = -0.25

static func slam_both(m: Node3D, t: float) -> void:
	_slam_arm(m, "arm_l", t)
	_slam_arm(m, "arm_r", t)

## Rugido: echa la cabeza atrás y abre los brazos.
static func roar(m: Node3D, t: float) -> void:
	var k := sin(t * PI)
	Anims.part(m, "head").rotation.x = -0.45 * k
	Anims.part(m, "torso").rotation.x = -0.12 * k
	Anims.part(m, "arm_l").rotation.z = 0.5 * k
	Anims.part(m, "arm_r").rotation.z = -0.5 * k
	m.position.y = 0.3 * k

## Se hunde en el mar (t = 1: bajo el agua) y emerge (al revés).
static func sink(m: Node3D, t: float) -> void:
	m.position.y = -8.0 * Anims.ease(t)
	Anims.part(m, "head").rotation.x = 0.3 * t

static func emerge(m: Node3D, t: float) -> void:
	m.position.y = -8.0 * (1.0 - Anims.ease(t))
	Anims.part(m, "arm_l").rotation.x = -0.6 * sin(t * PI)
	Anims.part(m, "arm_r").rotation.x = -0.6 * sin(t * PI)
