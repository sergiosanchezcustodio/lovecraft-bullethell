extends RefCounted
## Animaciones del shoggoth bebé (compañero). Partes: body, top y bud (un brote escondido dentro
## del cuerpo). El modelo mira hacia +Z. Es una gota: se mueve estirándose y encogiéndose, sin
## patas; "bite" es tragarse una bala.

const DURATION := {"idle": 1.6, "walk": 0.5, "run": 0.34, "bite": 0.3,
	"fidget_split": 3.4, "fidget_hop": 1.2}
## Gestos de reposo (hito 17.7): se parte en dos y se junta; da un saltito y se aplasta.
const FIDGETS := ["fidget_split", "fidget_hop"]

## Se parte en dos: el brote sale por un lado (el cuerpo se estira hacia allí), se separa, mira
## alrededor dando botecitos y vuelve a meterse; el cuerpo tiembla al juntarse.
static func fidget_split(m: Node3D, t: float) -> void:
	idle(m, fmod(t * 2.0, 1.0))
	var bud := _p(m, "bud")
	if bud == null: return
	var out := Anims.ease(t / 0.22) * (1.0 - Anims.ease((t - 0.74) / 0.2))
	var pull := sin(clampf(t / 0.22, 0.0, 1.0) * PI) + sin(clampf((t - 0.74) / 0.2, 0.0, 1.0) * PI)
	m.scale *= Vector3(1.0 + 0.12 * pull - 0.08 * out, 1.0 - 0.1 * pull - 0.06 * out, 1.0)   # se estira al soltarlo; sin él, más pequeño
	bud.position.x += 0.38 * out
	bud.position.y -= 0.02 * out
	var alone := clampf((t - 0.25) / 0.47, 0.0, 1.0) * out
	var hop := absf(sin(alone * PI * 3.0)) * alone
	bud.position.y += 0.05 * hop
	bud.rotation.y = sin(alone * TAU) * 0.8                                        # mira alrededor
	var squash := (1.0 - hop) * alone
	bud.scale = Vector3(1.0 + 0.15 * squash, 1.0 - 0.12 * squash + 0.1 * hop, 1.0 + 0.15 * squash)
	var join := clampf((t - 0.9) / 0.1, 0.0, 1.0)                                  # al juntarse, tiembla
	if join > 0.0: hit(m, join)

## Dormido (hito 17.8): aplastado como un charco, el bulto caído y latiendo despacio.
static func sleep(m: Node3D, k: float, t: float) -> void:
	var b := sin(t * 1.4)
	m.scale = m.scale.lerp(Vector3(1.18 + 0.02 * b, 0.72 + 0.03 * b, 1.18 + 0.02 * b), k)
	_p(m, "top").rotation = _p(m, "top").rotation.lerp(Vector3(0.0, 0.0, 0.35), k)

## Saltito: se aplasta, salta, cae y se aplasta otra vez; el bulto de arriba se queda atrás.
static func fidget_hop(m: Node3D, t: float) -> void:
	var crouch := sin(clampf(t / 0.25, 0.0, 1.0) * PI)
	var air := sin(clampf((t - 0.22) / 0.4, 0.0, 1.0) * PI)
	var land := sin(clampf((t - 0.6) / 0.25, 0.0, 1.0) * PI)
	var flat := crouch + land
	m.scale = Vector3(1.0 + 0.18 * flat - 0.08 * air, 1.0 - 0.22 * flat + 0.15 * air, 1.0 + 0.18 * flat - 0.08 * air)
	m.position.y += 0.16 * air
	_p(m, "top").rotation.x = -0.35 * air + 0.25 * land

static func _p(m: Node3D, n: String) -> Node3D:
	return Anims.part(m, n)

## Quieto: palpita y el bulto de arriba se balancea.
static func idle(m: Node3D, t: float) -> void:
	var s := sin(t * TAU)
	m.scale = Vector3(1.0 + 0.04 * s, 1.0 - 0.05 * s, 1.0 + 0.04 * s)
	_p(m, "top").rotation = Vector3(0.1 * sin(t * TAU + 1.0), 0.0, 0.12 * s)

## Avanza a latidos: se estira hacia delante y se aplasta.
static func walk(m: Node3D, t: float) -> void:
	_ooze(m, t, 0.12)

static func run(m: Node3D, t: float) -> void:
	_ooze(m, t, 0.2)

static func _ooze(m: Node3D, t: float, k: float) -> void:
	var s := sin(t * TAU)
	m.scale = Vector3(1.0 - k * 0.5 * s, 1.0 - k * s, 1.0 + k * s)
	_p(m, "top").rotation.x = -0.3 * k / 0.12 * maxf(s, 0.0)
	m.position.y = absf(s) * 0.02

## Trago: se hincha de golpe y vuelve.
static func bite(m: Node3D, t: float) -> void:
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	m.scale = Vector3(1.0 + 0.2 * k, 1.0 + 0.25 * k, 1.0 + 0.2 * k)
	_p(m, "top").position.y += 0.03 * k

## Golpe: como el fragmento, la masa tiembla en ondas que se calman (28-10-2026).
const HIT_TIME := 0.7
static func hit(m: Node3D, k: float) -> void:
	var fade := pow(1.0 - k, 1.6)
	var w := sin(k * TAU * 3.0) * fade
	var w2 := sin(k * TAU * 3.0 + 1.6) * fade
	m.scale *= Vector3(1.0 + 0.12 * w, 1.0 - 0.15 * w, 1.0 + 0.12 * w2)
