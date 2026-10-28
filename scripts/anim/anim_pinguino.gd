extends RefCounted
## Pingüino albino ciego gigante.

const DURATION := {"idle": 2.0, "walk": 0.7, "charge": 0.9}

## Quieto, ladeando la cabeza para escuchar: es ciego y se guía por el oído.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	Anims.part(m, "head").rotation = Vector3(sin(w * 2.0) * 0.05, sin(w) * 0.35, sin(w) * 0.18)
	Anims.part(m, "torso").scale = Vector3(1.0, 1.0 + sin(w * 2.0) * 0.015, 1.0)
	Anims.part(m, "arm_l").rotation.z = -0.12
	Anims.part(m, "arm_r").rotation.z = 0.12

## Andar bamboleándose, con las aletas abiertas para equilibrarse.
static func walk(m: Node3D, t: float) -> void:
	var w := t * TAU
	m.rotation.z = sin(w) * 0.13
	Anims.part(m, "leg_l").position.y = Anims.rest(m, "leg_l").y + maxf(0.0, sin(w)) * 0.05
	Anims.part(m, "leg_r").position.y = Anims.rest(m, "leg_r").y + maxf(0.0, -sin(w)) * 0.05
	Anims.part(m, "arm_l").rotation.z = -0.18 - maxf(0.0, -sin(w)) * 0.12
	Anims.part(m, "arm_r").rotation.z = 0.18 + maxf(0.0, sin(w)) * 0.12
	Anims.part(m, "head").rotation.y = sin(w * 0.5) * 0.25
	m.position.y = abs(sin(w)) * 0.02

## Carga con picotazo: se echa atrás, embiste con el pico por delante y se recupera.
static func charge(m: Node3D, t: float) -> void:
	var back := Anims.ease(t / 0.35) if t < 0.35 else 0.0
	var thrust := 0.0
	if t >= 0.35 and t < 0.6: thrust = Anims.ease((t - 0.35) / 0.25)
	elif t >= 0.6: thrust = 1.0 - Anims.ease((t - 0.6) / 0.4)
	m.rotation.x = -back * 0.15 + thrust * 0.42
	m.position.z = thrust * 0.3
	Anims.part(m, "head").rotation.x = -back * 0.2 + thrust * 0.35
	Anims.part(m, "arm_l").rotation = Vector3(thrust * 0.9, 0.0, -0.3 - back * 0.3)
	Anims.part(m, "arm_r").rotation = Vector3(thrust * 0.9, 0.0, 0.3 + back * 0.3)

## Muerte (hito 12.7): se tambalea y cae de lado, con las aletas abiertas y la cabeza que golpea
## el suelo.
const DEATH_KIND := "fall"
const DEATH_TIME := 0.7
static func death(m: Node3D, k: float) -> void:
	var wob := sin(clampf(k / 0.3, 0.0, 1.0) * PI) * 0.18          # un vaivén antes de irse
	var f := Anims.ease((k - 0.2) / 0.6)
	f = f * f                                                    # cae cada vez más deprisa
	var thud := Anims.jolt(clampf((k - 0.78) / 0.22, 0.0, 1.0), 0.3)
	m.rotation.z = -wob + 1.45 * f - 0.08 * thud
	m.rotation.x = 0.15 * f
	m.position.y = -0.05 * f
	Anims.part(m, "arm_l").rotation.z = -0.9 * f
	Anims.part(m, "arm_r").rotation.z = 0.5 * f
	Anims.part(m, "head").rotation.z = 0.35 * f + 0.2 * thud

## Golpe: se tambalea de lado a lado como un tentetieso, con las aletas abiertas para no caerse,
## y retrocede un paso (28-10-2026).
const HIT_TIME := 0.6
static func hit(m: Node3D, k: float) -> void:
	var fade := 1.0 - Anims.ease(k)
	var wob := sin(k * TAU * 2.0) * fade                                     # dos vaivenes
	m.rotation.z += 0.28 * wob
	m.rotation.x += -0.16 * Anims.jolt(k, 0.15)                               # echado atrás
	m.position.z -= 0.08 * Anims.jolt(k, 0.25)
	Anims.part(m, "arm_l").rotation.z += -0.7 * fade
	Anims.part(m, "arm_r").rotation.z += 0.7 * fade
	Anims.part(m, "head").rotation.z += -0.2 * wob
