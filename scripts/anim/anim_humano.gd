extends RefCounted
## Personajes jugables humanos (Dyer; más adelante Olmstead y los demás).

## walk: ciclo a la velocidad base del personaje. Player lo reproduce más deprisa o más
## despacio según la velocidad real, para que los pies no patinen.
const DURATION := {"idle": 2.0, "walk": 0.5, "dodge": 0.32, "throw": 0.55}

## Reposo: respiración y un leve vistazo alrededor.
static func idle(m: Node3D, t: float) -> void:
	var w := t * TAU
	Anims.part(m, "torso").scale = Vector3(1.0, 1.0 + sin(w) * 0.012, 1.0 + sin(w) * 0.01)
	Anims.part(m, "head").position.y = Anims.rest(m, "head").y + sin(w) * 0.006
	Anims.part(m, "head").rotation.y = sin(w * 0.5) * 0.15
	Anims.part(m, "arm_l").rotation.z = -0.05 - sin(w) * 0.02
	Anims.part(m, "arm_r").rotation.z = 0.05 + sin(w) * 0.02

## Paso ligero sobre la nieve: zancada amplia (a 4,5 m/s, unos 2,2 m por ciclo), brazos a
## contrapaso, leve giro de hombros y un pequeño rebote en cada apoyo.
static func walk(m: Node3D, t: float) -> void:
	var w := t * TAU
	Anims.part(m, "leg_l").rotation.x = sin(w) * 0.72
	Anims.part(m, "leg_r").rotation.x = -sin(w) * 0.72
	Anims.part(m, "arm_l").rotation.x = -sin(w) * 0.55
	Anims.part(m, "arm_r").rotation.x = sin(w) * 0.55
	Anims.part(m, "torso").rotation.y = sin(w) * 0.07
	Anims.part(m, "torso").rotation.x = 0.08
	Anims.part(m, "head").rotation.x = 0.05
	m.position.y = abs(cos(w)) * 0.045

## Esquive: deslizamiento sobre la nieve con los pies por delante. El cuerpo se echa
## atrás (se gira todo el modelo, para que cabeza y brazos acompañen al torso), la pierna
## delantera va estirada casi a ras de suelo, la otra algo abierta, una mano atrás rozando
## la nieve y la otra delante para equilibrarse; la cabeza mira al frente. Entra en el
## primer 40 % (unas 0,13 s) y se mantiene: al acabar, Player funde la pose con la de andar
## (incorporarse).
static func dodge(m: Node3D, t: float) -> void:
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

## Lanzamiento de dinamita con el brazo derecho por encima del hombro.
## Se suma por encima de andar (Player.play_once la aplica solo a brazos y torso).
static func throw(m: Node3D, t: float) -> void:
	var back := Anims.ease(t / 0.4) if t < 0.4 else 1.0 - Anims.ease((t - 0.4) / 0.35)
	var fwd := 0.0 if t < 0.4 else sin(clampf((t - 0.4) / 0.6, 0.0, 1.0) * PI)
	Anims.part(m, "arm_r").rotation.x = back * 2.0 - fwd * 0.7
	Anims.part(m, "torso").rotation.y = -back * 0.22 + fwd * 0.18
	Anims.part(m, "arm_l").rotation.x = -back * 0.35
