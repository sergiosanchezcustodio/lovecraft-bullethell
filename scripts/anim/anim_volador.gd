extends RefCounted
## Animaciones de los compañeros que vuelan (búho de los sueños). Partes: body, head, wing_l,
## wing_r. El modelo mira hacia +Z; la altura de vuelo la pone Pet. Siempre en el aire: en
## reposo aletea despacio y planea; al moverse aletea más y se inclina hacia delante.

const DURATION := {"idle": 0.9, "walk": 0.45, "run": 0.32, "bite": 0.5,
	"fidget_preen": 2.7, "fidget_roll": 1.8}
## Gestos de reposo (28-10-2026): se acicala bajo un ala o da una voltereta en el aire.
const FIDGETS := ["fidget_preen", "fidget_roll"]

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

static func _flap(m: Node3D, t: float, amp: float, lean: float) -> void:
	var s := sin(t * TAU)
	_p(m, "wing_l").rotation.z = -(0.35 + amp * s)
	_p(m, "wing_r").rotation.z = 0.35 + amp * s
	m.position.y = -s * 0.03
	m.rotation.x = lean

## Planea: aleteo lento y la cabeza gira a un lado y a otro, como los búhos.
static func idle(m: Node3D, t: float) -> void:
	_flap(m, t, 0.45, 0.0)
	_p(m, "head").rotation.y = sin(t * TAU * 0.25) * 0.6

static func walk(m: Node3D, t: float) -> void:
	_flap(m, t, 0.8, 0.2)

static func run(m: Node3D, t: float) -> void:
	_flap(m, t, 1.0, 0.35)

## Ulula: abre las alas, ahueca el pecho y cabecea.
static func bite(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	_p(m, "wing_l").rotation.z = -1.1 * k
	_p(m, "wing_r").rotation.z = 1.1 * k
	_p(m, "body").scale = Vector3.ONE * (1.0 + 0.08 * k)
	_p(m, "head").rotation.x = 0.3 * sin(t * TAU * 2.0) * k

## Gesto: deja un ala quieta y abierta y mete el pico debajo para acicalarse, a picotazos; la
## otra sigue aleteando despacio. Dura tres aleteos, así acaba donde empezó.
static func fidget_preen(m: Node3D, t: float) -> void:
	_flap(m, fposmod(t * 3.0, 1.0), 0.45, 0.0)
	var k := Anims.ease(clampf(t / 0.2, 0.0, 1.0)) * (1.0 - Anims.ease(clampf((t - 0.8) / 0.2, 0.0, 1.0)))
	var wl := _p(m, "wing_l")
	wl.rotation.z = lerpf(wl.rotation.z, -0.75, k)
	var peck := maxf(0.0, sin(t * TAU * 7.0)) * 0.2 * k
	_p(m, "head").rotation = Vector3(0.35 * k + peck, 1.2 * k, 0.0)
	m.rotation.z = 0.12 * k

## Gesto: una voltereta de lado en el aire, aleteando fuerte.
static func fidget_roll(m: Node3D, t: float) -> void:
	_flap(m, fposmod(t * 2.0, 1.0), 0.45 + 0.4 * sin(t * PI), 0.0)
	var a := TAU * Anims.ease(clampf((t - 0.15) / 0.6, 0.0, 1.0))
	var c := (Anims.rest(m, "body").y + Anims.rest(m, "head").y) * 0.5      # gira sobre su centro
	m.rotation.z = wrapf(a, -PI, PI)         # acaba en 0, no en 2π: el fundido al reposo no deshace la vuelta
	m.position += Vector3(c * sin(a), c * (1.0 - cos(a)) + 0.12 * sin(t * PI), 0.0)
