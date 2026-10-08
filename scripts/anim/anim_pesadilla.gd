extends RefCounted
## Pesadillas de la oleada de sueños (hito 7.1): flotan, se mecen y alargan las garras.

const DURATION := {"idle": 2.0, "walk": 1.6, "throw": 0.9}

static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	m.position.y = 0.25 + sin(w) * 0.08                       # flota
	Anims.part(m, "head").rotation = Vector3(sin(w * 2.0) * 0.05, sin(w) * 0.3, 0)
	Anims.part(m, "arm_l").rotation.x = sin(w + 0.5) * 0.15
	Anims.part(m, "arm_r").rotation.x = sin(w + 2.0) * 0.15

## Se desliza inclinado hacia delante, los brazos por detrás.
static func walk(m: Node3D, t: float) -> void:
	var w := t * TAU
	m.position.y = 0.3 + sin(w * 2.0) * 0.06
	Anims.part(m, "body").rotation.x = 0.18
	Anims.part(m, "arm_l").rotation.x = 0.5 + sin(w) * 0.2
	Anims.part(m, "arm_r").rotation.x = 0.5 - sin(w) * 0.2
	Anims.part(m, "head").rotation.z = sin(w) * 0.1

## Alarga las garras hacia delante.
static func throw(m: Node3D, t: float) -> void:
	var k := sin(t * PI)
	m.position.y = 0.3
	Anims.part(m, "arm_l").rotation.x = -1.3 * k
	Anims.part(m, "arm_r").rotation.x = -1.3 * k
	Anims.part(m, "head").rotation.x = 0.2 * k
