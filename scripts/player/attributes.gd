class_name Attributes
extends RefCounted
## Atributos de los personajes (D-27). Siete, todos a 10 en el nivel 1 más el reparto de
## 20 puntos de cada personaje (CharacterData.attr_bonus). Cada estadística sale de la suma
## de dos atributos: con 20 (10+10) vale lo mismo que la base del personaje, y cada punto
## por encima suma un porcentaje (RATE; la velocidad, la mitad).
## Al subir de nivel se gana +1 en un atributo, al azar con probabilidad proporcional a los
## atributos del nivel 1, que no cambia nunca.

const NAMES: Array[String] = ["POD", "INT", "FUE", "CON", "TEN", "DES", "EDU"]
const LONG := {"POD": "Poder", "INT": "Inteligencia", "FUE": "Fuerza", "CON": "Constitución",
	"TEN": "Tenacidad", "DES": "Destreza", "EDU": "Educación"}
const BASE := 10

## Estadística derivada -> los dos atributos que la forman.
const FORMULAS := {
	"health": ["CON", "TEN"],       ## vida
	"sanity": ["POD", "INT"],       ## cordura
	"dodge": ["DES", "CON"],        ## esquive: recarga más corta
	"speed": ["DES", "TEN"],        ## velocidad al andar
	"physical": ["FUE", "TEN"],     ## daño de las armas físicas (cuerpo a cuerpo y lanzadas)
	"magic": ["POD", "EDU"],        ## daño de las armas mágicas (arcanas y de los Mitos)
	"firearm": ["CON", "INT"],      ## daño de las armas de fuego
}
const RATE := 0.025                 ## +2,5 % por punto por encima de 20
const RATE_SPEED := 0.0125          ## la velocidad, la mitad: si no, se dispara

## Atributos de nivel 1 de un personaje: 10 cada uno más su reparto.
static func initial(c: CharacterData) -> Dictionary:
	var a := {}
	for n in NAMES: a[n] = BASE + int(c.attr_bonus.get(n, 0))
	return a

## Multiplicador de una estadística derivada con unos atributos.
static func mult(attrs: Dictionary, stat: String) -> float:
	var pair: Array = FORMULAS[stat]
	var sum := int(attrs.get(pair[0], BASE)) + int(attrs.get(pair[1], BASE))
	return 1.0 + (sum - 2 * BASE) * (RATE_SPEED if stat == "speed" else RATE)

## Atributo que sube al ganar un nivel: al azar, proporcional a los del nivel 1.
static func roll_point(level1: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for n in NAMES: total += int(level1[n])
	var r := rng.randi_range(1, total)
	for n in NAMES:
		r -= int(level1[n])
		if r <= 0: return n
	return NAMES[NAMES.size() - 1]

## Texto compacto: "POD 17 · INT 10 · …".
static func summary(attrs: Dictionary) -> String:
	var parts := PackedStringArray()
	for n in NAMES: parts.append("%s %d" % [n, int(attrs[n])])
	return "  ·  ".join(parts)
