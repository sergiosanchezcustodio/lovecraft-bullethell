extends RefCounted
## Diablo con alas de murciélago (hito 7.2): vuela batiendo las alas y cae en picado con
## ellas plegadas.

const DURATION := {"fly": 0.5, "dive": 0.6, "idle": 0.6, "walk": 0.5}

static func fly(m: Node3D, t: float) -> void:
	var w := t * TAU
	var flap := sin(w) * 0.75
	Anims.part(m, "wing_l").rotation.z = -flap
	Anims.part(m, "wing_r").rotation.z = flap
	Anims.part(m, "body").rotation.x = 0.35                    # inclinado hacia delante
	Anims.part(m, "tail").rotation.y = sin(w * 0.5) * 0.4
	m.position.y = -sin(w) * 0.08

static func idle(m: Node3D, t: float) -> void:
	fly(m, t)

static func walk(m: Node3D, t: float) -> void:
	fly(m, t)

## Picado: alas plegadas hacia atrás, el cuerpo de cabeza.
static func dive(m: Node3D, t: float) -> void:
	Anims.part(m, "wing_l").rotation = Vector3(0.6, 0.9, -0.3)
	Anims.part(m, "wing_r").rotation = Vector3(0.6, -0.9, 0.3)
	Anims.part(m, "body").rotation.x = 1.0
	Anims.part(m, "head").rotation.x = -0.4
