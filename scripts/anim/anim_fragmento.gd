extends RefCounted
## Fragmento protoplásmico de shoggoth: masa que repta a tirones deformándose.

const DURATION := {"idle": 2.0, "walk": 1.2, "burst": 0.7}

## Reposo: la masa late despacio y la cresta ondula.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	var s := sin(w)
	m.get_node("body").scale = Vector3(1.0 + s * 0.03, 1.0 - s * 0.04, 1.0 + s * 0.03)
	m.get_node("top").rotation = Vector3(sin(w + 1.0) * 0.08, 0.0, sin(w) * 0.1)
	m.get_node("pod_l").rotation.y = sin(w) * 0.2
	m.get_node("pod_r").rotation.y = -sin(w) * 0.2

## Reptar: se aplasta y se estira, y los pseudópodos tiran hacia delante por turnos.
static func walk(m: Node3D, t: float) -> void:
	var w := t * TAU
	var s := sin(w)
	m.get_node("body").scale = Vector3(1.0 + s * 0.08, 1.0 - s * 0.12, 1.0 - s * 0.05)
	m.get_node("top").position.y = Anims.rest(m, "top").y - s * 0.05
	m.get_node("top").rotation.x = s * 0.12
	m.get_node("pod_l").rotation.x = sin(w) * 0.45
	m.get_node("pod_r").rotation.x = sin(w + PI) * 0.45
	m.position.z = (s + 1.0) * 0.025

## Ráfaga: se hincha y se contrae de golpe al escupir glóbulos.
static func burst(m: Node3D, t: float) -> void:
	var k := Anims.ease(t / 0.55) if t < 0.55 else 1.0 - Anims.ease((t - 0.55) / 0.1) * 1.3 + Anims.ease((t - 0.65) / 0.35) * 0.3
	m.get_node("body").scale = Vector3.ONE * (1.0 + k * 0.18)
	m.get_node("top").scale = Vector3.ONE * (1.0 + k * 0.25)
	m.get_node("top").position.y = Anims.rest(m, "top").y + k * 0.06
	m.get_node("pod_l").rotation.z = -k * 0.5
	m.get_node("pod_r").rotation.z = k * 0.5
