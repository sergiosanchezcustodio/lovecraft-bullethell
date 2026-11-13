extends RefCounted
## Personajes jugables humanos (Dyer; más adelante Olmstead y los demás).

## walk: ciclo a la velocidad base del personaje. Player lo reproduce más deprisa o más
## despacio según la velocidad real, para que los pies no patinen.
## Esquives: "slide" (deslizamiento) y "roll" (voltereta). Cada personaje elige el suyo en
## CharacterData.dodge_anim; la animación puede durar más que el impulso del esquive.
const ARM_LAG := 0.32                         ## retraso de los brazos respecto a las piernas (rad del ciclo)
const DURATION := {"idle": 2.0, "walk": 0.5, "slide": 0.5, "roll": 0.42, "dive": 0.5,
	"jump": 0.45, "flash": 0.3, "throw": 0.55, "cast": 0.5, "swing": 0.45, "thrust": 0.4, "slam": 0.6, "brake": 0.5, "cheer": 0.9, "bond_wave": 1.2, "marvel": 1.1, "open_chest": 0.9,
	"win_fist": 1.6, "win_salute": 1.6, "win_hat": 1.6, "win_ward": 1.6, "win_bow": 1.6, "win_court": 1.8,
	"win_paint": 1.8, "win_flask": 1.6, "win_angle": 1.7, "win_tune": 1.7, "win_poet": 1.7, "win_clasp": 1.6,
	"fidget_look": 2.6, "fidget_stretch": 2.8, "fidget_check": 2.4, "fidget_shift": 1.8,
	"down": 0.9, "down_wait": 3.0, "get_up": 0.75}
## Gestos de reposo (28-10-2026): Player los pone de vez en cuando si el personaje lleva un rato
## quieto. Empiezan y acaban en la pose de reposo, y se funden al entrar y al salir.
const FIDGETS := ["fidget_look", "fidget_stretch", "fidget_check", "fidget_shift"]
## Gestos al atacar de los investigadores (hito 17.1): las hordas (HordeMesh) no los graban.
const HORDE_SKIP := ["cast", "swing", "thrust", "slam", "brake", "cheer", "bond_wave", "marvel", "open_chest",
	"win_fist", "win_salute", "win_hat", "win_ward", "win_bow", "win_court",
	"win_paint", "win_flask", "win_angle", "win_tune", "win_poet", "win_clasp"]

## Piezas opcionales: antebrazos y espinillas (codos y rodillas), bufanda y coleta. Los
## modelos partidos con tools/humano.py split_limbs las tienen; los demás, no, y las
## animaciones las saltan.
static func has(m: Node3D, pname: String) -> bool:
	return (m.get_meta("part_nodes") as Dictionary).has(pname)

## Gira una pieza opcional en X (codo, rodilla o balanceo), si el modelo la tiene.
static func bend(m: Node3D, pname: String, x: float, z: float = 0.0) -> void:
	var parts: Dictionary = m.get_meta("part_nodes")
	if not parts.has(pname): return
	var n: Node3D = parts[pname]
	n.rotation.x = x
	n.rotation.z = z

## Reposo: respiración y un leve vistazo alrededor.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	bend(m, "fore_l", -0.14)
	bend(m, "fore_r", -0.14)
	bend(m, "shin_l", 0.03)
	bend(m, "shin_r", 0.03)
	bend(m, "scarf", 0.06 + sin(w) * 0.04, sin(w * 0.5) * 0.05)
	bend(m, "hair", 0.08 + sin(w + 0.6) * 0.05, sin(w * 0.5 + 0.4) * 0.06)
	Anims.part(m, "torso").scale = Vector3(1.0, 1.0 + sin(w) * 0.012, 1.0 + sin(w) * 0.01)
	Anims.part(m, "head").position.y = Anims.rest(m, "head").y + sin(w) * 0.006
	Anims.part(m, "head").rotation.y = sin(w * 0.5) * 0.15
	Anims.part(m, "arm_l").rotation.z = -0.05 - sin(w) * 0.02
	Anims.part(m, "arm_r").rotation.z = 0.05 + sin(w) * 0.02

## Curva de un gesto: sube en `rise`, se mantiene y baja desde `fall` (0..1, suave).
static func _hold(t: float, rise: float, fall: float) -> float:
	return Anims.ease(clampf(t / rise, 0.0, 1.0)) * (1.0 - Anims.ease(clampf((t - fall) / (1.0 - fall), 0.0, 1.0)))

## Gesto: mira a un lado y al otro, con el tronco acompañando un poco (vigila la oscuridad).
static func fidget_look(m: Node3D, t: float) -> void:
	idle(m, fposmod(t, 1.0))                                                # acaba donde empieza el reposo
	var env := _hold(t, 0.12, 0.82)
	var turn := sin(clampf((t - 0.08) / 0.84, 0.0, 1.0) * TAU) * env    # a un lado, al otro y al frente
	Anims.part(m, "head").rotation.y = turn * 0.85
	Anims.part(m, "head").rotation.x = -0.06 * env
	Anims.part(m, "torso").rotation.y = turn * 0.22

## Gesto: se estira con los brazos arriba, echa la cabeza atrás y los baja.
static func fidget_stretch(m: Node3D, t: float) -> void:
	idle(m, 0.0)
	var up := _hold(t, 0.3, 0.62)
	var shake := sin(t * TAU * 3.0) * 0.06 * up                             # un temblor al tensar
	Anims.part(m, "arm_l").rotation = Vector3(-2.7 * up + shake, 0.0, -0.32 * up)
	Anims.part(m, "arm_r").rotation = Vector3(-2.7 * up - shake, 0.0, 0.32 * up)
	bend(m, "fore_l", -0.14 - 0.35 * up)
	bend(m, "fore_r", -0.14 - 0.35 * up)
	Anims.part(m, "torso").rotation.x = -0.14 * up
	Anims.part(m, "torso").scale = Vector3(1.0, 1.0 + 0.03 * up, 1.0)
	Anims.part(m, "head").rotation.x = -0.3 * up
	m.position.y = 0.025 * up                                               # de puntillas

## Gesto: levanta la mano derecha y mira el arma (o lo que lleve), le da la vuelta y la baja.
static func fidget_check(m: Node3D, t: float) -> void:
	idle(m, 0.0)
	var up := _hold(t, 0.22, 0.75)
	var twist := sin(clampf((t - 0.25) / 0.45, 0.0, 1.0) * TAU) * up        # le da la vuelta
	Anims.part(m, "arm_r").rotation = Vector3(-0.75 * up, 0.35 * twist, 0.12 * up)
	bend(m, "fore_r", -0.14 - 1.25 * up, 0.25 * twist)
	Anims.part(m, "head").rotation = Vector3(0.38 * up, -0.32 * up, 0.0)
	Anims.part(m, "torso").rotation.y = -0.12 * up

## Gesto: cambia el peso de pierna, rueda los hombros y vuelve.
static func fidget_shift(m: Node3D, t: float) -> void:
	idle(m, fposmod(t, 1.0))
	var env := _hold(t, 0.25, 0.7)
	var roll := sin(clampf(t, 0.0, 1.0) * TAU) * env
	m.rotation.z = 0.05 * env                                               # el peso a la izquierda
	m.position.x = -0.02 * env
	bend(m, "shin_r", 0.03 + 0.28 * env)                                    # rodilla floja
	Anims.part(m, "leg_r").rotation.x = -0.12 * env
	Anims.part(m, "torso").rotation.z = -0.06 * env
	Anims.part(m, "arm_l").rotation.x = 0.18 * roll                         # hombros que ruedan
	Anims.part(m, "arm_r").rotation.x = -0.18 * roll
	Anims.part(m, "head").rotation.z = 0.08 * env

## Paso ligero sobre la nieve: zancada amplia (a 4,5 m/s, unos 2,2 m por ciclo), brazos a
## contrapaso, leve giro de hombros y un pequeño rebote en cada apoyo.
## Con codos y rodillas (modelos partidos), un paso más vivo: la rodilla se dobla al llevar
## la pierna adelante, el codo acompaña al brazo, el cuerpo rebota y se balancea hacia la
## pierna de apoyo, y la bufanda o la coleta van con retraso.
static func walk(m: Node3D, t: float) -> void:
	if has(m, "shin_l"):
		_walk_jointed(m, t)
		return
	var w := t * TAU
	Anims.part(m, "leg_l").rotation.x = sin(w) * 0.72
	Anims.part(m, "leg_r").rotation.x = -sin(w) * 0.72
	Anims.part(m, "arm_l").rotation.x = -sin(w) * 0.55
	Anims.part(m, "arm_r").rotation.x = sin(w) * 0.55
	Anims.part(m, "torso").rotation.y = sin(w) * 0.07
	Anims.part(m, "torso").rotation.x = 0.08
	Anims.part(m, "head").rotation.x = 0.05
	m.position.y = abs(cos(w)) * 0.045

static func _walk_jointed(m: Node3D, t: float) -> void:
	var w := t * TAU
	var s := sin(w)
	var c := cos(w)
	var sa := sin(w - ARM_LAG)                     # brazos y codos, con algo de retraso (hito 11.1)
	# piernas: muslo adelante y atrás; la rodilla se dobla en el paso (pierna en el aire)
	var swing_l := maxf(0.0, -c)                   # pierna izquierda avanzando por el aire
	var swing_r := maxf(0.0, c)
	Anims.part(m, "leg_l").rotation.x = s * 0.62 - swing_l * 0.22
	Anims.part(m, "leg_r").rotation.x = -s * 0.62 - swing_r * 0.22
	bend(m, "shin_l", 0.1 + swing_l * 1.05)
	bend(m, "shin_r", 0.1 + swing_r * 1.05)
	# brazos a contrapaso, abiertos un poco; el codo se dobla más cuando el brazo va delante
	Anims.part(m, "arm_l").rotation = Vector3(-sa * 0.6, 0.0, -0.06)
	Anims.part(m, "arm_r").rotation = Vector3(sa * 0.6, 0.0, 0.06)
	bend(m, "fore_l", -0.3 - maxf(0.0, sin(w - ARM_LAG * 1.6)) * 0.55)
	bend(m, "fore_r", -0.3 - maxf(0.0, -sin(w - ARM_LAG * 1.6)) * 0.55)
	# cuerpo: rebote (arriba con la pierna de apoyo recta), balanceo hacia la pierna de apoyo,
	# giro de hombros y la cabeza compensando para mirar al frente. Con peso (hito 11.1): el
	# cuerpo se queda arriba más rato y baja de golpe al apoyar, el tronco cabecea un poco en el
	# apoyo y la cabeza absorbe parte del rebote.
	var a := absf(s)
	var bob := 0.075 * (1.0 - a * a * a)
	m.position = Vector3(-c * 0.035, bob, 0.0)
	Anims.part(m, "torso").rotation = Vector3(0.1 + 0.05 * pow(a, 6.0), s * 0.13, c * 0.06)
	Anims.part(m, "head").rotation = Vector3(0.04 - 0.04 * pow(a, 6.0), -s * 0.09, -c * 0.045)
	Anims.part(m, "head").position.y = Anims.rest(m, "head").y - bob * 0.35
	# bufanda y coleta: echadas atrás por la marcha y con retraso respecto al rebote
	bend(m, "scarf", 0.38 + sin(2.0 * w - 0.9) * 0.16, cos(w - 0.6) * 0.14)
	bend(m, "hair", 0.32 + sin(2.0 * w - 1.1) * 0.2, cos(w - 0.8) * 0.18)

## Esquive: entrada en plancha de fútbol. Se deja caer de lado sobre la nieve y resbala con
## los pies por delante: el cuerpo muy echado atrás, casi tumbado y con la cadera a ras de
## suelo; la pierna delantera estirada y paralela al suelo, la otra doblada por debajo con la
## rodilla abierta; la mano izquierda atrás apoyada en la nieve y el brazo derecho alto para
## equilibrarse; la cabeza levantada mirando al frente.
## El cuerpo gira alrededor de la cadera (no de los pies) y baja con ella; Player sube el
## modelo lo justo si algo queda bajo la nieve (_keep_above_ground).
##   0-0,3 se deja caer | 0,3-1 resbala (con un leve asentarse)
static func slide(m: Node3D, t: float) -> void:
	var k := Anims.ease(t / 0.3) * (1.0 - Anims.ease((t - 0.72) / 0.28))    # se tumba, resbala y se levanta
	var settle := sin(clampf((t - 0.3) / 0.7, 0.0, 1.0) * PI) * 0.04     # se asienta y se rehace
	var lean := -(1.32 + settle) * k                                       # casi tumbado hacia atrás
	var hip := Vector3(0, 0.83, 0)
	m.rotation = Vector3(lean, 0.0, 0.1 * k)                               # algo ladeado, sobre la cadera izquierda
	m.position = hip - Basis.from_euler(m.rotation) * hip + Vector3(0, -0.74 * k, 0.1 * k)
	Anims.part(m, "leg_r").rotation = Vector3(-0.42 * k, 0.0, 0.04 * k)    # delantera, estirada a ras de suelo
	Anims.part(m, "leg_l").rotation = Vector3(-0.1 * k, 0.0, -0.45 * k)    # trasera, con la rodilla abierta
	bend(m, "shin_r", 0.12 * k)
	bend(m, "shin_l", 1.85 * k)                                            # doblada por debajo
	Anims.part(m, "arm_l").rotation = Vector3(1.2 * k, 0.0, -0.75 * k)     # mano atrás y al lado, apoyada en la nieve
	Anims.part(m, "arm_r").rotation = Vector3(-1.5 * k, 0.0, 0.6 * k)      # brazo alto, para equilibrarse
	bend(m, "fore_l", -0.15 * k)
	bend(m, "fore_r", -0.55 * k)
	Anims.part(m, "torso").rotation = Vector3(0.1 * k, 0.12 * k, 0.0)      # apenas se encoge: el cuerpo va tendido
	Anims.part(m, "head").rotation.x = 0.95 * k                            # levanta la cabeza para mirar al frente
	bend(m, "scarf", 1.3 * k)                                              # la bufanda ondea detrás
	bend(m, "hair", 1.2 * k)

## Esquive: voltereta hacia delante. Se encoge (piernas al pecho, brazos abrazándolas,
## barbilla metida), da una vuelta completa girando sobre el centro de la bola que forma
## el cuerpo, tocando la nieve con la espalda, y se despliega al acabar.
##   0-0,18 se encoge | 0,06-0,86 gira 360° | 0,78-1 se despliega
static func roll(m: Node3D, t: float) -> void:
	var k := Anims.ease(t / 0.18) * (1.0 - Anims.ease((t - 0.78) / 0.22))
	var spin := TAU * Anims.ease((t - 0.06) / 0.8)
	var angle := wrapf(0.5 * k + spin, -PI, PI)           # inclinación al encogerse + la vuelta
	# Girar alrededor del centro de la bola (no de los pies) y bajarla hasta rozar el suelo
	var center := Vector3(0, 1.0, 0.22 * k)
	var basis := Basis(Vector3.RIGHT, angle)
	m.rotation.x = angle
	# centro de la bola a ~0,55 m: rueda pegada a la nieve (si roza, se hunde un poco en ella)
	m.position = center - basis * center + Vector3(0, -0.45 * k, 0)
	Anims.part(m, "leg_l").rotation = Vector3(-1.75 * k, 0.0, 0.06 * k)   # rodillas al pecho
	Anims.part(m, "leg_r").rotation = Vector3(-1.75 * k, 0.0, -0.06 * k)
	Anims.part(m, "arm_l").rotation = Vector3(-1.45 * k, 0.0, 0.18 * k)   # abrazando las piernas
	Anims.part(m, "arm_r").rotation = Vector3(-1.45 * k, 0.0, -0.18 * k)
	Anims.part(m, "head").rotation.x = 0.55 * k                            # barbilla metida
	# rodillas y codos se cierran algo más despacio que el encogerse (si no, el pie salta)
	var kj := Anims.ease(t / 0.32) * (1.0 - Anims.ease((t - 0.72) / 0.28))
	bend(m, "shin_l", 1.6 * kj)
	bend(m, "shin_r", 1.6 * kj)
	bend(m, "fore_l", -1.0 * kj)
	bend(m, "fore_r", -1.0 * kj)

## Esquive: plancha de pingüino. Se lanza hacia delante hasta quedar tumbado boca abajo y
## resbala de barriga por la nieve con los brazos pegados al cuerpo hacia atrás, las
## piernas juntas y algo levantadas y la cabeza erguida mirando al frente; al final se
## incorpora de un empujón.  0-0,28 se lanza | 0,28-0,72 resbala | 0,72-1 se levanta
static func dive(m: Node3D, t: float) -> void:
	var k := Anims.ease(t / 0.28) * (1.0 - Anims.ease((t - 0.72) / 0.28))
	var angle := 1.42 * k                                  # de pie -> tumbado boca abajo
	var pivot := Vector3(0, 0.75, 0)                       # gira desde la cadera
	m.rotation.x = angle
	m.position = pivot - Basis(Vector3.RIGHT, angle) * pivot + Vector3(0, -0.6 * k, 0.1 * k)
	m.position.y += sin(clampf((t - 0.28) / 0.44, 0.0, 1.0) * PI * 3.0) * 0.012 * k  # traqueteo
	Anims.part(m, "arm_l").rotation = Vector3(0.25 * k, 0.0, -0.22 * k)   # brazos atrás, pegados
	Anims.part(m, "arm_r").rotation = Vector3(0.25 * k, 0.0, 0.22 * k)
	Anims.part(m, "leg_l").rotation.x = 0.18 * k                           # piernas juntas, en alto
	Anims.part(m, "leg_r").rotation.x = 0.18 * k
	Anims.part(m, "head").rotation.x = -1.05 * k                           # mira al frente
	bend(m, "shin_l", 0.35 * k)                                            # talones en alto
	bend(m, "shin_r", 0.35 * k)
	bend(m, "scarf", -1.0 * k)                                             # tumbado: la bufanda cae a un lado
	bend(m, "hair", -1.0 * k)

## Esquive: salto. Se agacha, salta en arco (unos 70 cm) con los brazos arriba y una
## pierna adelantada, y aterriza amortiguando.
##   0-0,18 se agacha | 0,18-0,8 en el aire | 0,8-1 aterriza
static func jump(m: Node3D, t: float) -> void:
	var crouch := 0.0
	var air := 0.0
	if t < 0.18:
		crouch = Anims.ease(t / 0.18)
	elif t < 0.8:
		var u := (t - 0.18) / 0.62
		air = sin(u * PI)
		crouch = 1.0 - Anims.ease(u * 4.0)
	else:
		crouch = sin((t - 0.8) / 0.2 * PI) * 0.8
	var reach := sin(clampf((t - 0.14) / 0.72, 0.0, 1.0) * PI)            # extensión en el aire
	m.position.y = air * 0.72 - crouch * 0.1
	m.rotation.x = crouch * 0.18 - reach * 0.12
	Anims.part(m, "leg_r").rotation.x = -0.85 * reach + 0.25 * crouch      # adelantada
	Anims.part(m, "leg_l").rotation.x = 0.55 * reach + 0.25 * crouch       # atrasada
	Anims.part(m, "arm_l").rotation = Vector3(-2.3 * reach + 0.4 * crouch, 0.0, -0.25 * reach)
	Anims.part(m, "arm_r").rotation = Vector3(-2.3 * reach + 0.4 * crouch, 0.0, 0.25 * reach)
	Anims.part(m, "head").rotation.x = -0.15 * reach + 0.2 * crouch
	bend(m, "shin_l", 0.8 * reach + 0.4 * crouch)                          # recoge la de atrás
	bend(m, "shin_r", 0.25 * reach + 0.4 * crouch)
	bend(m, "fore_l", -0.3 * reach)
	bend(m, "fore_r", -0.3 * reach)
	bend(m, "scarf", 0.2 + crouch * 0.3 - air * 0.5)                       # sube al caer
	bend(m, "hair", 0.2 + crouch * 0.3 - air * 0.6)

## Esquive: destello. Se estira hacia delante y desaparece (Player oculta el modelo en el
## tramo que indica su DodgeStyle y deja una estela de imágenes fantasma); al reaparecer
## llega estirado y recupera la forma.
static func flash(m: Node3D, t: float) -> void:
	var s := sin(clampf(t / 0.22, 0.0, 1.0) * PI * 0.5) if t < 0.22 else 1.0 - Anims.ease((t - 0.62) / 0.38)
	m.scale = Vector3(1.0 - 0.35 * s, 1.0 + 0.08 * s, 1.0 + 0.9 * s)      # estirado en la marcha
	m.rotation.x = 0.35 * s                                                 # inclinado hacia delante
	Anims.part(m, "arm_l").rotation.x = 0.9 * s                             # brazos atrás
	Anims.part(m, "arm_r").rotation.x = 0.9 * s
	Anims.part(m, "leg_l").rotation.x = 0.5 * s
	Anims.part(m, "leg_r").rotation.x = -0.3 * s

## Lanzamiento de dinamita con el brazo derecho por encima del hombro.
## Se suma por encima de andar (Player.play_once la aplica solo a brazos y torso).
static func throw(m: Node3D, t: float) -> void:
	var back := Anims.ease(t / 0.4) if t < 0.4 else 1.0 - Anims.ease((t - 0.4) / 0.35)
	var fwd := 0.0 if t < 0.4 else sin(clampf((t - 0.4) / 0.6, 0.0, 1.0) * PI)
	Anims.part(m, "arm_r").rotation.x = back * 2.0 - fwd * 0.7
	Anims.part(m, "torso").rotation.y = -back * 0.22 + fwd * 0.18
	Anims.part(m, "arm_l").rotation.x = -back * 0.35
	bend(m, "fore_r", -back * 1.3 + fwd * 0.2)                             # codo atrás al coger impulso

# ---------------------------------------------------------------- gestos al atacar (hito 17.1)
# Los de un golpe (cast, swing, thrust, slam, como throw) los pone Player.play_once encima de
# andar, solo en brazos y torso (UPPER_BODY): no tocan otras partes. aim lo suma Player cada
# fotograma mientras dispara.

## Apuntar y retroceso, encima de la pose: w (0..1), cuánto apunta; look (rad), hacia dónde
## respecto al frente; kick (0..1), el culatazo de cada disparo, que se apaga solo; two (0..1),
## con las dos manos (rifles, escopetas, subfusiles), con la izquierda sujetando por delante.
## El brazo gira primero en Y (rotation_order YXZ): estirado y vuelto hacia el disparo.
static func aim(m: Node3D, two: float, look: float, kick: float, w: float) -> void:
	if w <= 0.0: return
	Anims.part(m, "torso").rotation.y += look * 0.35 * w
	Anims.part(m, "torso").rotation.x += -0.07 * kick * w             # el culatazo lo echa atrás
	Anims.part(m, "head").rotation.y += look * 0.45 * w
	var one_r := Vector3(-1.5 - 0.38 * kick, look, 0.0)                 # pistola: el brazo salta arriba
	var two_r := Vector3(-0.75 - 0.15 * kick, look - 0.3, 0.0)         # codo abajo, la mano en la culata
	var two_l := Vector3(-1.4 - 0.2 * kick, look + 0.45, 0.0)          # la izquierda, estirada por delante
	_toward(m, "arm_r", one_r.lerp(two_r, two), w)
	_toward(m, "fore_r", Vector3(lerpf(-0.1 - 0.4 * kick, -0.95, two), 0.0, 0.0), w)
	if two > 0.0:
		_toward(m, "arm_l", two_l, w * two)
		_toward(m, "fore_l", Vector3(-0.25, 0.0, 0.0), w * two)
	m.position.z -= 0.025 * kick * w * (1.0 + two)

## Conjuro (armas arcanas): alza las dos manos hacia delante, abiertas, y empuja.
static func cast(m: Node3D, t: float) -> void:
	var up := Anims.ease(t / 0.35) if t < 0.55 else 1.0 - Anims.ease((t - 0.55) / 0.45)
	var push := sin(clampf((t - 0.3) / 0.3, 0.0, 1.0) * PI)
	Anims.part(m, "arm_l").rotation = Vector3(-1.1 * up - 0.4 * push, -0.28 * up, 0.0)
	Anims.part(m, "arm_r").rotation = Vector3(-1.1 * up - 0.4 * push, 0.28 * up, 0.0)
	bend(m, "fore_l", -0.65 * up + 0.5 * push)
	bend(m, "fore_r", -0.65 * up + 0.5 * push)
	Anims.part(m, "torso").rotation.x = -0.1 * up + 0.14 * push

## Tajo (machete, látigo, barridos): el brazo derecho se abre atrás y a un lado con el codo
## doblado y cruza por delante, con el tronco, y vuelve.  0-0,3 se arma | 0,3-0,52 corta | 0,6-1 vuelve
static func swing(m: Node3D, t: float) -> void:
	var wind := Anims.ease(t / 0.3)
	var cut := Anims.ease((t - 0.3) / 0.22)
	var rest := 1.0 - Anims.ease((t - 0.6) / 0.4)
	Anims.part(m, "arm_r").rotation = Vector3(-1.3 * wind * rest, lerpf(1.3 * wind, -0.95, cut) * rest, 0.0)
	bend(m, "fore_r", (-0.8 * wind * (1.0 - cut) - 0.1) * rest)
	Anims.part(m, "torso").rotation.y = (0.35 * wind - 0.8 * cut) * rest
	Anims.part(m, "arm_l").rotation.x = 0.35 * cut * rest

## Estocada (estoque, dagas): recoge el brazo con el codo atrás y lo lanza recto, con el hombro
## derecho por delante.  0-0,3 recoge | 0,3-0,45 estocada | 0,55-1 vuelve
static func thrust(m: Node3D, t: float) -> void:
	var pull := Anims.ease(t / 0.3) * (1.0 - Anims.ease((t - 0.3) / 0.15))
	var hit := Anims.ease((t - 0.3) / 0.15) * (1.0 - Anims.ease((t - 0.55) / 0.45))
	Anims.part(m, "arm_r").rotation.x = 0.45 * pull - 1.55 * hit
	bend(m, "fore_r", -1.3 * pull)
	Anims.part(m, "torso").rotation.y = 0.15 * pull - 0.3 * hit
	Anims.part(m, "torso").rotation.x = 0.16 * hit
	Anims.part(m, "arm_l").rotation.x = 0.5 * hit

## Golpe de martillo: las dos manos arriba, por encima de la cabeza, y abajo de golpe.
##   0-0,4 alza | 0,4-0,5 golpea | 0,6-1 vuelve
static func slam(m: Node3D, t: float) -> void:
	var up := Anims.ease(t / 0.4)
	var down := Anims.ease((t - 0.4) / 0.1)
	var rest := 1.0 - Anims.ease((t - 0.6) / 0.4)
	var x := lerpf(-2.6 * up, -0.7, down) * rest
	Anims.part(m, "arm_l").rotation = Vector3(x, 0.3 * rest, 0.0)
	Anims.part(m, "arm_r").rotation = Vector3(x, -0.3 * rest, 0.0)
	bend(m, "fore_l", -0.5 * up * (1.0 - down) * rest)
	bend(m, "fore_r", -0.5 * up * (1.0 - down) * rest)
	Anims.part(m, "torso").rotation.x = (-0.22 * up * (1.0 - down) + 0.38 * down) * rest

# ---------------------------------------------------------------- según el suelo (hito 17.6)
## Encima de andar (t, la fase del paso), según por dónde va: `wade` (0..1), vadeando: brazos
## abiertos y las manos en alto, fuera del agua, rodillas altas y el tronco adelante; `mud` (0..1),
## en el barro: pasos pesados, rodillas más dobladas, tronco adelante y un pisotón al apoyar.
static func terrain(m: Node3D, t: float, wade: float, mud: float) -> void:
	if wade <= 0.0 and mud <= 0.0: return
	var w := t * TAU
	var c := cos(w)
	var swing_l := maxf(0.0, -c)                   # la pierna que va por el aire (como _walk_jointed)
	var swing_r := maxf(0.0, c)
	var arm_l := Anims.part(m, "arm_l")
	var arm_r := Anims.part(m, "arm_r")
	if wade > 0.0:
		arm_l.rotation = arm_l.rotation.lerp(Vector3(arm_l.rotation.x * 0.4 - 0.35, 0.0, -0.55), wade)
		arm_r.rotation = arm_r.rotation.lerp(Vector3(arm_r.rotation.x * 0.4 - 0.35, 0.0, 0.55), wade)
		_toward(m, "fore_l", Vector3(-0.95, 0.0, 0.0), wade)
		_toward(m, "fore_r", Vector3(-0.95, 0.0, 0.0), wade)
		Anims.part(m, "torso").rotation.x += 0.1 * wade
	var knee := 0.45 * wade + 0.6 * mud                       # rodillas más altas
	Anims.part(m, "leg_l").rotation.x -= swing_l * knee * 0.55
	Anims.part(m, "leg_r").rotation.x -= swing_r * knee * 0.55
	var parts: Dictionary = m.get_meta("part_nodes")
	if parts.has("shin_l"): (parts["shin_l"] as Node3D).rotation.x += swing_l * knee
	if parts.has("shin_r"): (parts["shin_r"] as Node3D).rotation.x += swing_r * knee
	if mud > 0.0:
		var a := absf(sin(w))
		Anims.part(m, "torso").rotation.x += 0.15 * mud
		m.position.y -= 0.045 * mud * pow(1.0 - a, 4.0)           # el pisotón: se hunde un poco al apoyar
		arm_l.rotation.x *= 1.0 + 0.4 * mud
		arm_r.rotation.x *= 1.0 + 0.4 * mud

## Resbalón (hito 17.6): en la nieve, la frenada (17.2) además agita los brazos en círculos para no
## caerse. k (0..1): cuánto; t (s), el reloj del giro.
static func slip(m: Node3D, k: float, t: float) -> void:
	if k <= 0.0: return
	var a := t * 16.0
	Anims.part(m, "arm_l").rotation.x += sin(a) * 0.9 * k
	Anims.part(m, "arm_r").rotation.x += sin(a + PI) * 0.9 * k
	Anims.part(m, "arm_l").rotation.z += -0.35 * k
	Anims.part(m, "arm_r").rotation.z += 0.35 * k

# ---------------------------------------------------------------- celebraciones (hito 17.4)
# Como los gestos al atacar (encima de andar, solo brazos y torso), pero sin que un disparo los
# corte (Player.play_once con keep).

## Sube de nivel: alza el puño derecho y lo agita dos veces; el izquierdo, cerrado al pecho.
static func cheer(m: Node3D, t: float) -> void:
	var up := Anims.ease(t / 0.25) * (1.0 - Anims.ease((t - 0.7) / 0.3))
	var pump := sin(clampf((t - 0.25) / 0.45, 0.0, 1.0) * TAU * 2.0) * 0.16
	Anims.part(m, "arm_r").rotation = Vector3((-2.85 + pump) * up, 0.0, 0.15 * up)
	bend(m, "fore_r", -0.35 * up)
	Anims.part(m, "arm_l").rotation.x = -0.45 * up
	bend(m, "fore_l", -1.0 * up)
	Anims.part(m, "torso").rotation.x = -0.12 * up                           # saca pecho

## Saludo entre dos con vínculo al subir de nivel (hito 21.3): la mano derecha alzada y abierta,
## que se agita dos veces, y la izquierda al pecho; la cabeza mira al otro (Player.look_at_friend).
static func bond_wave(m: Node3D, t: float) -> void:
	var up := Anims.ease(t / 0.22) * (1.0 - Anims.ease((t - 0.78) / 0.22))
	var wave := sin(clampf((t - 0.22) / 0.5, 0.0, 1.0) * TAU * 2.0) * 0.22
	Anims.part(m, "arm_r").rotation = Vector3(-2.25 * up, 0.0, (0.3 + wave) * up)
	bend(m, "fore_r", -0.45 * up)
	Anims.part(m, "arm_l").rotation = Vector3(-0.6 * up, 0.4 * up, 0.0)
	bend(m, "fore_l", -1.45 * up)
	Anims.part(m, "torso").rotation.x = -0.06 * up

## Evoluciona un arma: junta las manos delante como si sostuviera algo que brilla, lo mira y lo
## alza por encima de la cabeza.
static func marvel(m: Node3D, t: float) -> void:
	var a := Anims.ease(t / 0.3)
	var r := Anims.ease((t - 0.4) / 0.3)
	var out := 1.0 - Anims.ease((t - 0.8) / 0.2)
	var x := lerpf(-1.0 * a, -2.3, r) * out
	Anims.part(m, "arm_l").rotation = Vector3(x, 0.32 * out, 0.0)
	Anims.part(m, "arm_r").rotation = Vector3(x, -0.32 * out, 0.0)
	bend(m, "fore_l", (-0.9 * a * (1.0 - r) - 0.3) * out)
	bend(m, "fore_r", (-0.9 * a * (1.0 - r) - 0.3) * out)
	Anims.part(m, "torso").rotation.x = (0.14 * a * (1.0 - r) - 0.14 * r) * out

## Abre un baúl: se inclina, mete las manos bajo la tapa y la levanta de un tirón.
static func open_chest(m: Node3D, t: float) -> void:
	var d := Anims.ease(t / 0.3) * (1.0 - Anims.ease((t - 0.35) / 0.25))
	var l := Anims.ease((t - 0.35) / 0.2) * (1.0 - Anims.ease((t - 0.65) / 0.35))
	Anims.part(m, "torso").rotation.x = 0.45 * d - 0.1 * l
	Anims.part(m, "arm_l").rotation = Vector3(-0.75 * d - 1.9 * l, 0.0, -0.18 * l)
	Anims.part(m, "arm_r").rotation = Vector3(-0.75 * d - 1.9 * l, 0.0, 0.18 * l)
	bend(m, "fore_l", -0.25 * (d + l))
	bend(m, "fore_r", -0.25 * (d + l))

# ---------------------------------------------------------------- victoria (hito 17.5)
# Al superar el nivel, cada investigador la suya (CharacterData.victory), solo brazos y torso:
# mientras recoge lo que queda puede seguir andando.

## Sube en `a`, se mantiene y baja desde `b` (0..1).
static func _held(t: float, a: float, b: float) -> float:
	return Anims.ease(t / a) * (1.0 - Anims.ease((t - b) / (1.0 - b)))

## Los dos puños arriba, agitándolos (Dyer, Johansen).
static func win_fist(m: Node3D, t: float) -> void:
	var k := _held(t, 0.18, 0.75)
	var pump := sin(clampf((t - 0.18) / 0.5, 0.0, 1.0) * TAU * 1.5) * 0.12
	Anims.part(m, "arm_l").rotation = Vector3((-2.8 + pump) * k, 0.0, -0.22 * k)
	Anims.part(m, "arm_r").rotation = Vector3((-2.8 - pump) * k, 0.0, 0.22 * k)
	bend(m, "fore_l", -0.3 * k)
	bend(m, "fore_r", -0.3 * k)
	Anims.part(m, "torso").rotation.x = -0.15 * k

## Saludo militar: la mano derecha a la frente, firme (Elwood, Legrasse).
static func win_salute(m: Node3D, t: float) -> void:
	var k := _held(t, 0.2, 0.78)
	Anims.part(m, "arm_r").rotation = Vector3(-1.45 * k, -0.35 * k, 0.8 * k)
	bend(m, "fore_r", -2.15 * k)
	Anims.part(m, "arm_l").rotation = Vector3(0.04 * k, 0.0, 0.05 * k)
	bend(m, "fore_l", 0.0)
	Anims.part(m, "torso").rotation.x = -0.07 * k

## Se toca el ala del sombrero y abre la mano hacia fuera (Olmstead, Peaslee, Malone, Carter).
static func win_hat(m: Node3D, t: float) -> void:
	var k := _held(t, 0.18, 0.8)
	var out := Anims.ease((t - 0.35) / 0.25)
	Anims.part(m, "arm_r").rotation = Vector3(lerpf(-2.5, -1.7, out) * k, 0.0, lerpf(0.35, 1.05, out) * k)
	bend(m, "fore_r", lerpf(-1.5, -0.35, out) * k)
	Anims.part(m, "arm_l").rotation.x = 0.08 * k
	Anims.part(m, "torso").rotation = Vector3(0.12 * out * k, -0.12 * out * k, 0.0)   # un poco de reverencia

## La mano izquierda alzada y abierta, la derecha al pecho: conjura o bendice (Armitage, Varga,
## Iwanicki, Blake, Whateley).
static func win_ward(m: Node3D, t: float) -> void:
	var k := _held(t, 0.22, 0.78)
	var tremble := sin(t * 40.0) * 0.03 * k
	Anims.part(m, "arm_l").rotation = Vector3(-2.85 * k + tremble, 0.0, -0.15 * k)
	bend(m, "fore_l", -0.1 * k)
	Anims.part(m, "arm_r").rotation = Vector3(-0.75 * k, -0.45 * k, 0.0)
	bend(m, "fore_r", -1.5 * k)
	Anims.part(m, "torso").rotation.x = -0.1 * k

## Reverencia pequeña: la mano derecha al pecho, la izquierda abierta a un lado y el tronco apenas
## inclinado (Whipple, West). Poco: la cabeza no cuelga del tronco y se quedaría atrás.
static func win_bow(m: Node3D, t: float) -> void:
	var k := _held(t, 0.25, 0.72)
	Anims.part(m, "torso").rotation.x = 0.14 * k
	Anims.part(m, "arm_r").rotation = Vector3(-0.8 * k, -0.5 * k, 0.0)
	bend(m, "fore_r", -1.55 * k)
	Anims.part(m, "arm_l").rotation = Vector3(0.15 * k, 0.0, -0.85 * k)
	bend(m, "fore_l", -0.2 * k)

## Reverencia de corte (Kuranes, rey de Celephaïs; hito 20.22): la mano derecha sube a la frente,
## al aro, y baja en un floreo amplio hacia fuera y abajo con la palma abierta; la izquierda, a la
## espalda; el tronco se inclina un poco al final del floreo (poco: la cabeza no cuelga del tronco).
##   0-0,3 sube a la frente | 0,3-0,62 floreo y reverencia | se mantiene | 0,8-1 vuelve
static func win_court(m: Node3D, t: float) -> void:
	var k := _held(t, 0.2, 0.8)
	var up := Anims.ease(t / 0.28)                                          # a la frente, como el saludo
	var sweep := Anims.ease((t - 0.3) / 0.32)
	var curl := sin(sweep * PI) * 0.4                                       # el floreo: sube un poco antes de bajar
	Anims.part(m, "arm_r").rotation = Vector3((lerpf(-1.45 * up, -0.55, sweep) - curl) * k,
		lerpf(-0.35 * up, 0.0, sweep) * k, lerpf(0.8 * up, 0.95, sweep) * k)
	bend(m, "fore_r", lerpf(-2.15 * up, -0.25, sweep) * k)
	Anims.part(m, "arm_l").rotation = Vector3(0.5 * k, 0.0, 0.18 * k)      # a la espalda (casi estirado: si se
	bend(m, "fore_l", -0.35 * k)                                            #  dobla, la mano vuelve delante)
	Anims.part(m, "torso").rotation = Vector3(0.15 * sweep * k, 0.1 * sweep * k, 0.0)

## Pickman (hito 21.2): se echa atrás para mirar el cuadro; el brazo derecho estirado, a la altura
## de los ojos, mide con el pulgar (sube y baja un poco), y la mano izquierda al mentón.
static func win_paint(m: Node3D, t: float) -> void:
	var k := _held(t, 0.22, 0.8)
	var measure := sin(clampf((t - 0.25) / 0.5, 0.0, 1.0) * TAU) * 0.08
	Anims.part(m, "arm_r").rotation = Vector3((-1.55 + measure) * k, 0.0, 0.08 * k)
	bend(m, "fore_r", -0.08 * k)
	Anims.part(m, "arm_l").rotation = Vector3(-0.55 * k, 0.35 * k, 0.0)
	bend(m, "fore_l", -2.15 * k)
	Anims.part(m, "torso").rotation = Vector3(-0.1 * k, -0.08 * k, 0.0)

## Ward (hito 21.2): alza el frasco de las sales por encima de la cabeza y lo agita; la otra mano,
## al pecho.
static func win_flask(m: Node3D, t: float) -> void:
	var k := _held(t, 0.2, 0.78)
	var shake := sin(t * 34.0) * 0.06 * Anims.ease((t - 0.25) / 0.1) * k
	Anims.part(m, "arm_r").rotation = Vector3(-2.65 * k, 0.0, (0.12 + shake) * k)
	bend(m, "fore_r", -0.25 * k)
	Anims.part(m, "arm_l").rotation = Vector3(-0.75 * k, 0.45 * k, 0.0)    # (el izquierdo, giro al revés)
	bend(m, "fore_l", -1.5 * k)
	Anims.part(m, "torso").rotation.x = -0.08 * k

## Gilman (hito 21.2): traza un ángulo recto en el aire con la mano derecha: de delante del pecho
## hacia fuera, en horizontal, y luego hacia abajo, en vertical.
##   0-0,15 sube | 0,15-0,45 tramo horizontal | 0,45-0,68 tramo vertical | se mantiene | vuelve
static func win_angle(m: Node3D, t: float) -> void:
	var k := _held(t, 0.15, 0.82)
	var across := Anims.ease((t - 0.15) / 0.3)
	var down := Anims.ease((t - 0.45) / 0.23)
	Anims.part(m, "arm_r").rotation = Vector3(lerpf(-1.6, -0.4, down) * k, 0.0, lerpf(-0.5, 1.05, across) * k)
	bend(m, "fore_r", -0.15 * k)
	Anims.part(m, "arm_l").rotation = Vector3(0.05 * k, 0.0, 0.06 * k)
	bend(m, "fore_l", -0.2 * k)
	Anims.part(m, "torso").rotation = Vector3(0.0, lerpf(0.12, -0.1, across) * k, 0.0)   # sigue a la mano

## Tillinghast (hito 21.2): las dos manos delante, a la altura del pecho, ajustando la máquina; los
## antebrazos se mueven a destiempo (gira diales) y el tronco se inclina para mirar de cerca.
static func win_tune(m: Node3D, t: float) -> void:
	var k := _held(t, 0.2, 0.8)
	var a := sin(t * 18.0) * 0.12 * k
	var b := sin(t * 18.0 + 2.1) * 0.12 * k
	Anims.part(m, "arm_r").rotation = Vector3(-1.05 * k, -0.25 * k, 0.12 * k + a * 0.5)
	bend(m, "fore_r", -0.95 * k + a)
	Anims.part(m, "arm_l").rotation = Vector3(-1.05 * k, 0.25 * k, -0.12 * k + b * 0.5)
	bend(m, "fore_l", -0.95 * k + b)
	Anims.part(m, "torso").rotation.x = 0.14 * k

## Edward Derby (hito 21.2): declama, el poeta: la mano derecha al pecho y la izquierda alzada y
## abierta hacia fuera.
static func win_poet(m: Node3D, t: float) -> void:
	var k := _held(t, 0.22, 0.8)
	var lift := Anims.ease((t - 0.2) / 0.3)
	Anims.part(m, "arm_l").rotation = Vector3(lerpf(-1.2, -2.1, lift) * k, 0.0, -0.75 * k)
	bend(m, "fore_l", -0.3 * k)
	Anims.part(m, "arm_r").rotation = Vector3(-0.8 * k, -0.5 * k, 0.0)
	bend(m, "fore_r", -1.55 * k)
	Anims.part(m, "torso").rotation.x = -0.12 * k

## Asenath Waite (hito 21.2): las manos juntas delante, a la cintura, y el tronco erguido y algo
## echado atrás: mira por encima.
static func win_clasp(m: Node3D, t: float) -> void:
	var k := _held(t, 0.25, 0.8)
	Anims.part(m, "arm_r").rotation = Vector3(-0.45 * k, 0.0, -0.42 * k)
	bend(m, "fore_r", -1.05 * k)
	Anims.part(m, "arm_l").rotation = Vector3(-0.45 * k, 0.0, 0.42 * k)
	bend(m, "fore_l", -1.05 * k)
	Anims.part(m, "torso").rotation.x = -0.12 * k

## Frenada (hito 17.2): al pararse en seco tras correr, planta el pie izquierdo delante con la
## pierna estirada, dobla la derecha, echa el cuerpo atrás y abre los brazos para no irse de
## bruces; luego se recompone. Player la pone encima del reposo (BRAKE_PARTS) y baja el modelo
## lo que suben los pies (BRAKE_DROP), para que no floten.  0-0,15 frena | 0,35-1 se recompone
const BRAKE_DROP := 0.13
static func brake(m: Node3D, t: float) -> void:
	var k := Anims.ease(t / 0.15) * (1.0 - Anims.ease((t - 0.35) / 0.65))
	Anims.part(m, "leg_l").rotation.x = -0.62 * k                          # el talón, clavado delante
	bend(m, "shin_l", 0.05 * k)
	Anims.part(m, "leg_r").rotation.x = -0.28 * k                          # rodilla adelante, pie bajo la cadera
	bend(m, "shin_r", 0.95 * k)
	Anims.part(m, "torso").rotation.x = -0.34 * k
	Anims.part(m, "head").rotation.x = 0.22 * k                            # la vista, al frente
	Anims.part(m, "arm_l").rotation = Vector3(-0.75 * k, 0.0, -0.55 * k)
	Anims.part(m, "arm_r").rotation = Vector3(-0.6 * k, 0.0, 0.6 * k)
	bend(m, "fore_l", -0.4 * k)
	bend(m, "fore_r", -0.4 * k)

## Preparación (hito 12.5; cultistas, sacerdotes, Barnabas): echa la espalda atrás y alza los
## brazos abiertos por encima de la cabeza, con las manos temblando; al soltar, los baja hacia
## delante, hacia quien ataca.
static func windup(m: Node3D, b: float, th: float, t: float) -> void:
	var shake := sin(t * 55.0) * 0.05 * b
	Anims.part(m, "torso").rotation.x += -0.2 * b + 0.28 * th
	Anims.part(m, "head").rotation.x += -0.35 * b + 0.15 * th
	Anims.part(m, "arm_l").rotation.x += -2.5 * b - 1.3 * th + shake
	Anims.part(m, "arm_r").rotation.x += -2.5 * b - 1.3 * th - shake
	Anims.part(m, "arm_l").rotation.z += -0.4 * b
	Anims.part(m, "arm_r").rotation.z += 0.4 * b
	var parts: Dictionary = m.get_meta("part_nodes")
	for f in ["fore_l", "fore_r"]:
		if parts.has(f): (parts[f] as Node3D).rotation.x += -0.35 * b
	m.position.z += 0.06 * th

## Cordura baja (hito 12.2), encima del andar y el reposo: encorvado, las manos recogidas que
## tiemblan y la mirada que se queda y salta de un lado a otro, más cuanto más baja (k 0..1).
## t en s (reloj propio del jugador).
static func unease(m: Node3D, k: float, t: float) -> void:
	Anims.part(m, "torso").rotation.x += 0.16 * k
	Anims.part(m, "head").rotation.x += 0.1 * k
	var g := t * (0.7 + 0.8 * k)
	var i := floorf(g)
	var look := lerpf(_glance(i), _glance(i + 1.0), smoothstep(0.8, 1.0, g - i))
	Anims.part(m, "head").rotation.y += look * 0.65 * k
	var shake := (sin(t * 47.0) * 0.05 + sin(t * 31.0) * 0.03) * k
	Anims.part(m, "arm_l").rotation.x += shake - 0.15 * k
	Anims.part(m, "arm_r").rotation.x += -shake - 0.15 * k
	var parts: Dictionary = m.get_meta("part_nodes")
	for f in ["fore_l", "fore_r"]:
		if parts.has(f): (parts[f] as Node3D).rotation.x += -0.35 * k + shake

## Hacia dónde mira en cada salto de la mirada (-1..1), siempre igual para el mismo salto.
static func _glance(i: float) -> float:
	return fposmod(i * 0.618034 + 0.31, 1.0) * 2.0 - 1.0

## Crisis de cordura (hito 12.2): las manos a la cabeza, los codos abiertos, la cabeza gacha y
## encogido, temblando; w (0..1) funde desde la pose de debajo.
static func crisis(m: Node3D, w: float, t: float) -> void:
	var shake := sin(t * 40.0) * 0.04
	_toward(m, "torso", Vector3(0.3, 0.0, 0.0), w)
	_toward(m, "head", Vector3(0.25, sin(t * 2.3) * 0.2, 0.0), w)
	# brazo alzado de lado y girado, para que el codo quede fuera y la mano en la sien
	# (resuelto con el orden de giros de Godot: hombro a 59 voxels, codo 13 más abajo)
	_toward(m, "arm_l", Vector3(-2.6 + shake, -1.6, 0.3), w)
	_toward(m, "arm_r", Vector3(-2.6 - shake, 1.6, -0.3), w)
	_toward(m, "fore_l", Vector3(-1.9, 0.0, 0.0), w)
	_toward(m, "fore_r", Vector3(-1.9, 0.0, 0.0), w)

static func _toward(m: Node3D, pname: String, rot: Vector3, w: float) -> void:
	var parts: Dictionary = m.get_meta("part_nodes")
	if not parts.has(pname): return
	var n: Node3D = parts[pname]
	n.rotation = n.rotation.lerp(rot, w)

## Abatido en cooperativo (hito 12.1): de rodillas (kn) y tendido de lado apoyado en el codo
## izquierdo (s), girando sobre la rodilla, que ya está en el suelo. Pose absoluta, tras reset.
const LIE_ROLL := -1.2                       ## rad que rueda sobre su costado izquierdo
static func _down_pose(m: Node3D, kn: float, s: float) -> void:
	var knee := Anims.rest(m, "leg_l").y * 0.5 if has(m, "leg_l") else 0.45
	var a := LIE_ROLL * s
	m.rotation.z = a
	var k := Vector3(0.0, knee, 0.0)
	m.position = Vector3(0.0, -0.4 * kn, 0.0) + k - Basis(Vector3.BACK, a) * k
	var legs := kn * (1.0 - s)                                  # tendido, las piernas casi rectas
	Anims.part(m, "leg_l").rotation.x = -0.35 * legs - 0.15 * s
	Anims.part(m, "leg_r").rotation.x = -0.3 * legs - 0.45 * s
	bend(m, "shin_l", 1.6 * legs + 0.3 * s)
	bend(m, "shin_r", 1.6 * legs + 0.6 * s)
	Anims.part(m, "torso").rotation = Vector3(0.25 * kn * (1.0 - s), 0.0, 0.45 * s)   # se incorpora sobre el codo
	Anims.part(m, "head").rotation = Vector3(0.45 * kn * (1.0 - s), 0.0, 0.55 * s)
	Anims.part(m, "arm_l").rotation = Vector3(-0.5 * s, 0.0, 1.0 * s)                # el codo de apoyo, al suelo
	bend(m, "fore_l", -1.2 * s)
	Anims.part(m, "arm_r").rotation = Vector3(0.15 * kn * (1.0 - s) - 0.3 * s, 0.0, -0.2 * s)
	bend(m, "fore_r", -0.3 * s)
	_skirt_with_legs(m)

## Faldón, sotana o parka larga (parte `skirt`, que cuelga del tronco): tumbado, el tronco se
## incorpora sobre el codo y el faldón se iba con él, así que las piernas salían por debajo y
## la bota quedaba suelta en el suelo. Aquí sigue a las piernas, como si colgara de la cadera
## (02-11-2026). El vaivén de la ropa se suma después.
static func _skirt_with_legs(m: Node3D) -> void:
	if not has(m, "skirt") or not has(m, "leg_l") or not has(m, "leg_r"): return
	var legs_x := (Anims.part(m, "leg_l").rotation.x + Anims.part(m, "leg_r").rotation.x) * 0.5
	var torso := Basis.from_euler(Anims.part(m, "torso").rotation)
	Anims.part(m, "skirt").basis = torso.inverse() * Basis.from_euler(Vector3(legs_x, 0.0, 0.0))

## Cae (0,9 s): se le doblan las rodillas, la cabeza cae y rueda de lado hasta quedar apoyado
## en el codo.
static func down(m: Node3D, t: float) -> void:
	var kn := Anims.ease(t / 0.35)
	var s := Anims.ease((t - 0.3) / 0.6)
	_down_pose(m, kn, s)

## Esperando a que lo levanten: respira con esfuerzo, gira la cabeza hacia `look` (rad, hacia
## el compañero más cercano) y alarga la mano derecha hacia él con `reach` (0..1).
static func down_wait(m: Node3D, t: float, reach := 0.0, look := 0.0) -> void:
	_down_pose(m, 1.0, 1.0)
	var w := t * TAU
	var breath := sin(w)
	Anims.part(m, "torso").rotation.z += 0.05 * breath
	Anims.part(m, "torso").rotation.x += 0.03 * breath
	var head := Anims.part(m, "head")
	head.rotation.y = clampf(look, -1.0, 1.0)
	head.rotation.z += 0.04 * sin(w * 0.5)
	var arm := Anims.part(m, "arm_r")
	arm.rotation.x += -1.25 * reach + 0.04 * sin(w * 2.0) * reach          # la mano tiembla un poco
	arm.rotation.z += -0.35 * reach + clampf(look, -1.0, 1.0) * 0.25 * reach
	bend(m, "fore_r", -0.3 * (1.0 - reach) - 0.15 * reach)

## Se levanta (0,75 s): se empuja con la mano del suelo hasta quedar de rodillas y se pone de
## pie echando el peso adelante.
static func get_up(m: Node3D, t: float) -> void:
	var s := 1.0 - Anims.ease(t / 0.45)
	var kn := 1.0 - Anims.ease((t - 0.35) / 0.65)
	_down_pose(m, kn, s)
	var push := Anims.jolt(clampf(t / 0.5, 0.0, 1.0), 0.5)                  # la mano empuja del suelo
	Anims.part(m, "arm_l").rotation.x += -0.4 * push
	bend(m, "fore_l", -1.2 * s - 0.4 * push)
	var rise := sin(clampf((t - 0.35) / 0.65, 0.0, 1.0) * PI)               # peso adelante al levantarse
	Anims.part(m, "torso").rotation.x += 0.35 * rise
	Anims.part(m, "leg_r").rotation.x += -0.5 * rise
	bend(m, "shin_r", 0.9 * rise)

## Muerte (hito 12.7; cultistas, vecinos, híbridos, sacerdotes): se le doblan las rodillas y
## cae de rodillas con la cabeza colgando, y se desploma de bruces con los brazos por delante.
const DEATH_KIND := "kneel"
const DEATH_TIME := 0.8
static func death(m: Node3D, k: float) -> void:
	var kn := Anims.ease(k / 0.4)                              # de rodillas
	var fall := Anims.ease((k - 0.42) / 0.5)                   # de bruces
	var thud := Anims.jolt(clampf((k - 0.36) / 0.3, 0.0, 1.0), 0.25)   # rebote al clavar las rodillas
	# de bruces girando sobre las rodillas (ya en el suelo), no sobre los pies, que están hundidos
	var knee := Anims.rest(m, "leg_l").y * 0.5 if has(m, "leg_l") else 0.45
	var a := 1.35 * fall
	m.rotation.x = a
	m.position = Vector3(0.0, -0.4 * kn + 0.03 * thud + knee * (1.0 - cos(a)), -knee * sin(a) + 0.12 * fall)
	Anims.part(m, "torso").rotation.x = 0.25 * kn - 0.15 * fall
	Anims.part(m, "head").rotation.x = 0.55 * kn - 0.3 * fall
	Anims.part(m, "head").rotation.z = 0.15 * kn
	Anims.part(m, "arm_l").rotation.x = 0.1 * kn - 1.6 * fall
	Anims.part(m, "arm_r").rotation.x = 0.25 * kn - 1.4 * fall
	Anims.part(m, "arm_l").rotation.z = 0.12 * kn
	Anims.part(m, "arm_r").rotation.z = -0.12 * kn
	var legs := kn * (1.0 - fall)                              # al irse de bruces, las piernas se estiran detrás
	Anims.part(m, "leg_l").rotation.x = -0.35 * legs
	Anims.part(m, "leg_r").rotation.x = -0.3 * legs
	bend(m, "shin_l", 1.6 * legs)
	bend(m, "shin_r", 1.6 * legs)
	bend(m, "fore_l", -0.4 * fall)
	bend(m, "fore_r", -0.4 * fall)

## Golpe (cultistas, vecinos, híbridos, sacerdotes): se dobla por la cintura, se lleva las
## manos al vientre, la cabeza cae y se recompone (28-10-2026).
const HIT_TIME := 0.42
static func hit(m: Node3D, k: float) -> void:
	var s := Anims.jolt(k, 0.16)
	Anims.part(m, "torso").rotation.x += 0.42 * s
	Anims.part(m, "head").rotation.x += 0.3 * s
	Anims.part(m, "arm_l").rotation.x += -0.55 * s
	Anims.part(m, "arm_r").rotation.x += -0.55 * s
	Anims.part(m, "arm_l").rotation.z += 0.25 * s                            # hacia el vientre
	Anims.part(m, "arm_r").rotation.z += -0.25 * s
	bend(m, "fore_l", -0.14 - 0.7 * s)
	bend(m, "fore_r", -0.14 - 0.7 * s)
	bend(m, "shin_l", 0.03 + 0.2 * s)
	bend(m, "shin_r", 0.03 + 0.2 * s)
	m.position.y -= 0.03 * s
