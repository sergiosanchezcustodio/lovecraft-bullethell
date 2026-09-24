extends RefCounted
## Personajes jugables humanos (Dyer; más adelante Olmstead y los demás).

const DURATION := {"idle": 2.0, "walk": 0.8, "dodge": 0.35, "throw": 0.5}

## Reposo: respiración y un leve vistazo alrededor.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	m.get_node("torso").scale = Vector3(1.0, 1.0 + sin(w) * 0.012, 1.0 + sin(w) * 0.01)
	m.get_node("head").position.y = Anims.rest(m, "head").y + sin(w) * 0.006
	m.get_node("head").rotation.y = sin(w * 0.5) * 0.15
	m.get_node("arm_l").rotation.z = -0.05 - sin(w) * 0.02
	m.get_node("arm_r").rotation.z = 0.05 + sin(w) * 0.02

## Andar con paso firme sobre la nieve.
static func walk(m: Node3D, t: float) -> void:
	var w := t * TAU
	m.get_node("leg_l").rotation.x = sin(w) * 0.55
	m.get_node("leg_r").rotation.x = -sin(w) * 0.55
	m.get_node("arm_l").rotation.x = -sin(w) * 0.45
	m.get_node("arm_r").rotation.x = sin(w) * 0.45
	m.get_node("torso").rotation.y = sin(w) * 0.06
	m.get_node("torso").rotation.x = 0.06
	m.get_node("head").rotation.x = 0.04
	m.position.y = abs(cos(w)) * 0.035

## Esquive: impulso corto agachado. El desplazamiento lo hace el juego; aquí solo la pose.
static func dodge(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)       # 0 -> 1 -> 0
	m.rotation.x = k * 0.45
	m.position.y = -k * 0.08
	m.get_node("leg_l").rotation.x = -k * 0.7
	m.get_node("leg_r").rotation.x = k * 0.6
	m.get_node("arm_l").rotation.x = -k * 0.9
	m.get_node("arm_r").rotation.x = k * 0.7
	m.get_node("head").rotation.x = -k * 0.3

## Lanzamiento de dinamita con el brazo derecho por encima del hombro.
static func throw(m: Node3D, t: float) -> void:
	var back := Anims.ease(t / 0.4) if t < 0.4 else 1.0 - Anims.ease((t - 0.4) / 0.25)
	var fwd := 0.0 if t < 0.4 else sin(clampf((t - 0.4) / 0.6, 0.0, 1.0) * PI)
	m.get_node("arm_r").rotation.x = back * 2.4 - fwd * 0.8
	m.get_node("torso").rotation.y = -back * 0.25 + fwd * 0.2
	m.get_node("arm_l").rotation.x = -back * 0.4
