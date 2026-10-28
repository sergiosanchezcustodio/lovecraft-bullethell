extends RefCounted
## Animaciones de los compañeros de cuatro patas (perro de trineo, gato de Ulthar, rata).
## Partes: body, head, leg_fl, leg_fr, leg_bl, leg_br, tail. El modelo mira hacia +Z.

const DURATION := {"idle": 2.4, "walk": 0.5, "run": 0.34, "bite": 0.35,
	"fidget_sniff": 2.6, "fidget_lick": 3.0, "fidget_scratch": 2.2, "fidget_shake": 1.1}
## Gestos de reposo (28-10-2026): los hace Pet cuando lleva un rato quieto. Por modelo, o los de
## la familia (Anims.fidgets).
const FIDGETS := ["fidget_sniff", "fidget_shake"]
const FIDGETS_OF := {
	"perro": ["fidget_sniff", "fidget_scratch", "fidget_shake"],
	"gato": ["fidget_lick", "fidget_sniff"],
	"rata": ["fidget_lick", "fidget_sniff"],
}

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

## Quieto: respira, mueve el rabo y mira un poco a los lados.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	_p(m, "body").position.y += sin(w * 2.0) * 0.004
	_p(m, "head").rotation = Vector3(sin(w) * 0.05, sin(w * 0.5) * 0.25, 0.0)
	_p(m, "tail").rotation = Vector3(0.0, 0.0, sin(w * 3.0) * 0.35)

## Andar: patas en diagonal (delantera izquierda con trasera derecha).
static func walk(m: Node3D, t: float) -> void:
	_gait(m, t, 0.45, 0.015)

## Correr: zancadas más largas, el cuerpo sube y baja más.
static func run(m: Node3D, t: float) -> void:
	_gait(m, t, 0.75, 0.035)
	_p(m, "head").rotation.x += 0.12

static func _gait(m: Node3D, t: float, amp: float, bob: float) -> void:
	var s := sin(t * TAU)
	_p(m, "leg_fl").rotation.x = s * amp
	_p(m, "leg_br").rotation.x = s * amp
	_p(m, "leg_fr").rotation.x = -s * amp
	_p(m, "leg_bl").rotation.x = -s * amp
	m.position.y = absf(cos(t * TAU)) * bob
	_p(m, "head").rotation.x = sin(t * TAU * 2.0) * 0.05
	_p(m, "tail").rotation = Vector3(0.0, 0.0, sin(t * TAU * 2.0) * 0.4)

## Mordisco: se echa hacia delante y cierra la cabeza de golpe.
static func bite(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	_p(m, "body").rotation.x = 0.12 * k
	_p(m, "head").rotation.x = 0.45 * k
	_p(m, "head").position.z += 0.06 * k
	_p(m, "tail").rotation.z = 0.5 * k

## Sube al gesto, lo mantiene y vuelve: 0 en t=0 y t=1 (el gesto empieza y acaba en reposo).
static func _hold(t: float, rise: float, fall: float) -> float:
	return Anims.ease(clampf(t / rise, 0.0, 1.0)) * (1.0 - Anims.ease(clampf((t - fall) / (1.0 - fall), 0.0, 1.0)))

## Gesto: baja el hocico al suelo y olfatea de un lado a otro, a golpecitos, moviendo el rabo.
static func fidget_sniff(m: Node3D, t: float) -> void:
	var k := _hold(t, 0.18, 0.82)
	var sniff := sin(t * TAU * 14.0) * 0.04 * k                            # husmea
	_p(m, "body").rotation.x = 0.1 * k
	_p(m, "head").rotation = Vector3(0.6 * k + sniff, sin(t * TAU * 1.5) * 0.4 * k, 0.0)
	_p(m, "head").position.z += 0.02 * k
	_p(m, "leg_fl").rotation.x = -0.12 * k
	_p(m, "leg_fr").rotation.x = -0.12 * k
	_p(m, "tail").rotation = Vector3(-0.2 * k, 0.0, sin(t * TAU * 5.0) * 0.45 * k)

## Gesto: levanta una pata delantera y se la lame, con la cabeza ladeada hacia ella.
static func fidget_lick(m: Node3D, t: float) -> void:
	var k := _hold(t, 0.2, 0.8)
	var lick := maxf(0.0, sin(t * TAU * 6.0)) * 0.18 * k                   # lengüetazos
	_p(m, "body").rotation.x = -0.08 * k                                    # se echa atrás
	_p(m, "leg_fr").rotation.x = -1.15 * k
	_p(m, "head").rotation = Vector3(0.5 * k + lick, -0.35 * k, -0.15 * k)
	_p(m, "tail").rotation = Vector3(0.0, 0.0, sin(t * TAU * 1.5) * 0.25 * k)

## Gesto: se rasca detrás de la oreja con una pata trasera, deprisa, con la cabeza ladeada.
static func fidget_scratch(m: Node3D, t: float) -> void:
	var k := _hold(t, 0.15, 0.85)
	_p(m, "body").rotation.z = -0.1 * k                                     # se apoya en el otro lado
	_p(m, "leg_br").rotation = Vector3((-0.9 + sin(t * TAU * 11.0) * 0.35) * k, 0.0, 0.55 * k)
	_p(m, "head").rotation = Vector3(0.1 * k, -0.25 * k, -0.4 * k)
	_p(m, "tail").rotation = Vector3(0.0, 0.0, 0.3 * k)

## Gesto: se sacude como al salir del agua, de la cabeza al rabo.
static func fidget_shake(m: Node3D, t: float) -> void:
	var k := _hold(t, 0.12, 0.7)
	var s := sin(t * TAU * 7.0) * k
	_p(m, "body").rotation.z = 0.22 * s
	_p(m, "head").rotation = Vector3(0.0, 0.0, -0.4 * s)
	_p(m, "tail").rotation = Vector3(0.0, 0.0, 0.6 * s)
	m.position.y = 0.01 * absf(s)
