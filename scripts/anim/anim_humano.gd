extends RefCounted
## Personajes jugables humanos (Dyer; más adelante Olmstead y los demás).

## walk: ciclo a la velocidad base del personaje. Player lo reproduce más deprisa o más
## despacio según la velocidad real, para que los pies no patinen.
## Esquives: "slide" (deslizamiento) y "roll" (voltereta). Cada personaje elige el suyo en
## CharacterData.dodge_anim; la animación puede durar más que el impulso del esquive.
const DURATION := {"idle": 2.0, "walk": 0.5, "slide": 0.32, "roll": 0.42, "dive": 0.5,
	"jump": 0.45, "flash": 0.3, "throw": 0.55}

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
	# piernas: muslo adelante y atrás; la rodilla se dobla en el paso (pierna en el aire)
	var swing_l := maxf(0.0, -c)                   # pierna izquierda avanzando por el aire
	var swing_r := maxf(0.0, c)
	Anims.part(m, "leg_l").rotation.x = s * 0.62 - swing_l * 0.22
	Anims.part(m, "leg_r").rotation.x = -s * 0.62 - swing_r * 0.22
	bend(m, "shin_l", 0.1 + swing_l * 1.05)
	bend(m, "shin_r", 0.1 + swing_r * 1.05)
	# brazos a contrapaso, abiertos un poco; el codo se dobla más cuando el brazo va delante
	Anims.part(m, "arm_l").rotation = Vector3(-s * 0.6, 0.0, -0.06)
	Anims.part(m, "arm_r").rotation = Vector3(s * 0.6, 0.0, 0.06)
	bend(m, "fore_l", -0.3 - maxf(0.0, s) * 0.55)
	bend(m, "fore_r", -0.3 - maxf(0.0, -s) * 0.55)
	# cuerpo: rebote (arriba con la pierna de apoyo recta), balanceo hacia la pierna de apoyo,
	# giro de hombros y la cabeza compensando para mirar al frente
	m.position = Vector3(-c * 0.035, 0.07 * (0.5 + 0.5 * cos(2.0 * w)), 0.0)
	Anims.part(m, "torso").rotation = Vector3(0.1, s * 0.13, c * 0.06)
	Anims.part(m, "head").rotation = Vector3(0.04, -s * 0.09, -c * 0.045)
	# bufanda y coleta: echadas atrás por la marcha y con retraso respecto al rebote
	bend(m, "scarf", 0.38 + sin(2.0 * w - 0.9) * 0.16, cos(w - 0.6) * 0.14)
	bend(m, "hair", 0.32 + sin(2.0 * w - 1.1) * 0.2, cos(w - 0.8) * 0.18)

## Esquive: deslizamiento sobre la nieve con los pies por delante. El cuerpo se echa
## atrás (se gira todo el modelo, para que cabeza y brazos acompañen al torso), la pierna
## delantera va estirada casi a ras de suelo, la otra algo abierta, una mano atrás rozando
## la nieve y la otra delante para equilibrarse; la cabeza mira al frente. Entra en el
## primer 40 % (unas 0,13 s) y se mantiene: al acabar, Player funde la pose con la de andar
## (incorporarse).
static func slide(m: Node3D, t: float) -> void:
	var k := Anims.ease(t / 0.4)
	var lean := -0.5 * k
	m.rotation.x = lean
	m.position = Vector3(0, -0.47 * k, 0.12 * k)
	Anims.part(m, "leg_r").rotation = Vector3(-1.0 * k, 0.0, 0.05 * k)     # delantera, estirada
	Anims.part(m, "leg_l").rotation = Vector3(-0.8 * k, 0.0, -0.32 * k)    # trasera, abierta
	Anims.part(m, "arm_l").rotation = Vector3(0.85 * k, 0.0, -0.55 * k)    # mano atrás, a la nieve
	Anims.part(m, "arm_r").rotation = Vector3(-0.55 * k, 0.0, 0.5 * k)     # brazo abierto para equilibrarse
	Anims.part(m, "head").rotation.x = 0.42 * k                            # mira al frente
	Anims.part(m, "torso").rotation.z = 0.06 * k
	bend(m, "shin_l", 0.9 * k)                                             # la trasera, doblada
	bend(m, "fore_r", -0.4 * k)
	bend(m, "scarf", 0.9 * k)                                              # la bufanda ondea detrás
	bend(m, "hair", 0.8 * k)

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
