class_name TitleProgress
extends RefCounted
## La portada según lo jugado (hito 20.9): con la partida más avanzada de los tres huecos (o la que
## está en uso), más velas encendidas en la Biblioteca y el cielo del ventanal con el color de la
## parte a la que se ha llegado. Sin partidas, la mitad de las velas y el cielo helado de la
## primera parte. `sky_tint` tiñe el cielo pintado (background.gdshader); lo demás, la capa del
## cielo (window_sky.gdshader). Capturas: `progress=0..1` y `sky_part=0..3` en la portada.

const LIT_MIN := 0.45                     ## velas encendidas sin haber superado nada
## Luna y nubes por parte: las montañas (el azul de siempre, el de la configuración), Innsmouth
## (verde de mar), R'lyeh (verde enfermizo) y la campaña terminada (los ojos, más rojos).
const SKIES := [
	{},
	{"moon_color": Color(0.5, 0.86, 0.8), "clouds_color": Color(0.42, 0.74, 0.7), "sky_tint": Color(0.35, 0.85, 0.75)},
	{"moon_color": Color(0.72, 0.9, 0.55), "clouds_color": Color(0.5, 0.72, 0.42), "sky_tint": Color(0.6, 0.85, 0.4)},
	{"moon_color": Color(1.0, 0.5, 0.35), "clouds_color": Color(0.55, 0.3, 0.25), "eyes_color": Color(1.0, 0.45, 0.3),
		"sky_tint": Color(1.0, 0.38, 0.28), "sky_k": 0.8},
]

## Niveles superados de la partida más avanzada.
static func best_won() -> Array:
	var s: Node = Auto.node("Saves")
	if s == null: return []
	if s.get("current") != null: return (s.get("current") as SaveData).levels_won
	var best: Array = []
	for i in 3:
		if not bool(s.call("exists", i)): continue
		var d: SaveData = s.call("peek", i)
		if d != null and d.levels_won.size() > best.size(): best = d.levels_won
	return best

## Parte de la campaña superada (0..1).
static func fraction(won: Array) -> float:
	var all := Campaign.levels()
	if all.is_empty(): return 0.0
	var n := 0
	for l: Dictionary in all:
		if won.has(String(l.id)): n += 1
	return float(n) / all.size()

## Hasta dónde se ha llegado: 0..2 la parte más lejana con algo superado (la siguiente si esa
## está entera), 3 con toda la campaña.
static func part(won: Array) -> int:
	var all := Campaign.levels()
	var far := 0
	var done := {}
	var total := {}
	for l: Dictionary in all:
		var p := int(l.part)
		total[p] = int(total.get(p, 0)) + 1
		if won.has(String(l.id)):
			far = maxi(far, p)
			done[p] = int(done.get(p, 0)) + 1
	if not all.is_empty() and fraction(won) >= 1.0: return 3
	if int(done.get(far, 0)) >= int(total.get(far, 1)): far += 1
	return mini(far, 2)

static func lit(won: Array) -> float:
	return lerpf(LIT_MIN, 1.0, fraction(won))
