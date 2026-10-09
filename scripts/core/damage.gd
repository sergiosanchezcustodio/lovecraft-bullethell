class_name Damage
extends RefCounted
## Daño de un ataque: parte física (resta vida) y parte mental (resta cordura).
## El tipo se deduce de qué partes tiene: físico, mental o mixto (GDD 4.4).

enum Kind { PHYSICAL, MENTAL, MIXED }

var physical := 0.0
var mental := 0.0
var knockback := Vector3.ZERO
var source: Object = null
## Multiplicador de daño contra enemigos con ciertas etiquetas (rasgos: Legrasse contra
## "humana"). Lo pone el arma del jugador y lo aplica el enemigo.
var bonus := {}
## Arma que lo causa, para las estadísticas de la ficha: "J1:webly", "J2:mascota"… Sale del
## contexto `ctx` al crearse: WeaponSystem lo pone al disparar cada arma y cada efecto (bala,
## zona, onda…) guarda el suyo al crearse y lo vuelve a poner antes de dañar.
var tag := &""
var dot := false                 ## daño continuo (quemadura…): no dispara los objetos al impactar
static var ctx := &""

func _init(p_physical: float = 0.0, p_mental: float = 0.0) -> void:
	physical = p_physical
	mental = p_mental
	tag = ctx

func kind() -> Kind:
	if physical > 0.0 and mental > 0.0: return Kind.MIXED
	if mental > 0.0: return Kind.MENTAL
	return Kind.PHYSICAL

func scaled(k: float) -> Damage:
	var d := Damage.new(physical * k, mental * k)
	d.knockback = knockback * k
	d.source = source
	d.bonus = bonus
	d.tag = tag
	return d

## Colores del lenguaje visual de los daños (balas, avisos, barras).
const COLOR_PHYSICAL := Color(1.0, 0.36, 0.18)     # borde rojo anaranjado alrededor de un núcleo hueso
const COLOR_MENTAL := Color(0.72, 0.36, 1.0)       # violeta
const COLOR_CORE := Color(1.0, 0.95, 0.85)         # núcleo claro de todas las balas enemigas

static func color_for(k: Kind) -> Color:
	match k:
		Kind.MENTAL: return COLOR_MENTAL
		Kind.MIXED: return COLOR_PHYSICAL.lerp(COLOR_MENTAL, 0.5)
	return COLOR_PHYSICAL
