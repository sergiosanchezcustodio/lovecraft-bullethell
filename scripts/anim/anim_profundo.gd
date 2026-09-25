extends RefCounted
## Profundos (Acechador, Clásico, Bruto, Abisal).

const DURATION := {"walk": 1.0, "idle": 1.333, "pounce": 1.5}

## Andar encorvado y torpe.
static func walk(m: Node3D, t: float) -> void:
	var w := t * TAU
	Anims.part(m, "leg_l").rotation.x = sin(w) * 0.5
	Anims.part(m, "leg_r").rotation.x = -sin(w) * 0.5
	Anims.part(m, "arm_l").rotation.x = -sin(w) * 0.35
	Anims.part(m, "arm_r").rotation.x = sin(w) * 0.35
	Anims.part(m, "torso").rotation.z = sin(w) * 0.06
	Anims.part(m, "head").rotation.z = sin(w) * 0.08
	Anims.part(m, "head").rotation.x = sin(w * 2.0) * 0.05
	m.position.y = abs(sin(w)) * 0.03

## Al acecho: respiración, la cabeza vigila a izquierda y derecha.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	Anims.part(m, "torso").scale = Vector3(1.0 + sin(w * 2.0) * 0.012, 1.0 + sin(w * 2.0) * 0.025, 1.0)
	Anims.part(m, "head").rotation = Vector3(sin(w * 2.0) * 0.03, sin(w) * 0.28, sin(w) * 0.05)
	Anims.part(m, "head").position.y = Anims.rest(m, "head").y + sin(w * 2.0) * 0.008
	Anims.part(m, "arm_l").rotation.x = sin(w * 2.0) * 0.03
	Anims.part(m, "arm_r").rotation.x = sin(w * 2.0 + 0.8) * 0.03

## Salto de ataque: 0-0.35 se agazapa, 0.35-0.62 salta, 0.62-0.8 aterriza, 0.8-1 vuelve.
static func pounce(m: Node3D, t: float) -> void:
	var crouch := 0.0; var air := 0.0; var fwd := 0.0; var reach := 0.0
	if t < 0.35:
		crouch = Anims.ease(t / 0.35)
	elif t < 0.62:
		var u := (t - 0.35) / 0.27
		crouch = 1.0 - Anims.ease(min(1.0, u * 3.0)); air = sin(u * PI); fwd = u; reach = sin(u * PI)
	elif t < 0.8:
		var u := (t - 0.62) / 0.18
		fwd = 1.0; crouch = sin(u * PI) * 0.6
	else:
		fwd = 1.0 - Anims.ease((t - 0.8) / 0.2)
	m.position = Vector3(0, air * 0.2 - crouch * 0.05, fwd * 0.3)
	m.rotation.x = -reach * 0.25 + crouch * 0.12
	Anims.part(m, "head").rotation.x = crouch * 0.25 - reach * 0.35
	Anims.part(m, "arm_l").rotation.x = -reach * 1.1 + crouch * 0.2
	Anims.part(m, "arm_r").rotation.x = -reach * 1.1 + crouch * 0.2
	Anims.part(m, "leg_l").rotation.x = reach * 0.9 - crouch * 0.25
	Anims.part(m, "leg_r").rotation.x = reach * 0.9 - crouch * 0.25
