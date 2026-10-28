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

## Muerte (hito 12.7; Profundos, Acechador, engendros, Madre Hydra): se le doblan las piernas,
## se derrumba hacia delante con los brazos flojos y se hunde en el charco que deja.
const DEATH_KIND := "puddle"
const DEATH_TIME := 0.75
static func death(m: Node3D, k: float) -> void:
	var c := Anims.ease(k / 0.55)                              # se derrumba
	var sink := Anims.ease((k - 0.45) / 0.55)                  # se hunde
	m.position.y = -0.18 * c - 0.35 * sink
	m.rotation.x = 0.55 * c
	m.rotation.z = 0.12 * c
	Anims.part(m, "torso").rotation.x = 0.2 * c
	Anims.part(m, "head").rotation.x = 0.4 * c
	Anims.part(m, "head").rotation.z = -0.25 * c
	Anims.part(m, "arm_l").rotation.x = -0.5 * c
	Anims.part(m, "arm_r").rotation.x = -0.35 * c
	Anims.part(m, "arm_l").rotation.z = -0.35 * c
	Anims.part(m, "arm_r").rotation.z = 0.45 * c
	Anims.part(m, "leg_l").rotation.x = -0.6 * c
	Anims.part(m, "leg_r").rotation.x = -0.5 * c

## Preparación (hito 12.5; Acechador, engendros, Madre Hydra, primigenio): se agazapa, echa las
## garras atrás y abiertas, alza la barbilla hacia su presa y tiembla de tensión; al soltar, se
## lanza un palmo hacia delante con las garras por delante.
static func windup(m: Node3D, b: float, th: float, t: float) -> void:
	var shake := sin(t * 40.0) * 0.025 * b
	m.position.y -= 0.07 * b
	m.position.z += 0.22 * th
	m.rotation.x += 0.16 * b - 0.22 * th
	Anims.part(m, "torso").rotation.z += shake
	Anims.part(m, "head").rotation.x += -0.3 * b + 0.1 * th
	Anims.part(m, "arm_l").rotation.x += 0.7 * b - 1.1 * th
	Anims.part(m, "arm_r").rotation.x += 0.7 * b - 1.1 * th
	Anims.part(m, "arm_l").rotation.z += -0.4 * b
	Anims.part(m, "arm_r").rotation.z += 0.4 * b
	Anims.part(m, "leg_l").rotation.x += -0.25 * b
	Anims.part(m, "leg_r").rotation.x += -0.25 * b

## Golpe (Profundos, Acechador, Hydra): da un respingo hacia atrás con la cabeza echada atrás y
## las garras abiertas, como un animal que sisea (28-10-2026).
const HIT_TIME := 0.38
static func hit(m: Node3D, k: float) -> void:
	var s := Anims.jolt(k, 0.14)
	Anims.part(m, "torso").rotation.x += -0.3 * s
	Anims.part(m, "head").rotation.x += -0.4 * s
	Anims.part(m, "arm_l").rotation.z += -0.5 * s
	Anims.part(m, "arm_r").rotation.z += 0.5 * s
	Anims.part(m, "arm_l").rotation.x += -0.3 * s
	Anims.part(m, "arm_r").rotation.x += -0.3 * s
