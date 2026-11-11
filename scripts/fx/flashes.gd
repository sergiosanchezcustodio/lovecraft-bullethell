class_name Flashes
## Accesibilidad, «Destellos (golpes y rayos)» (`Settings` `flashes`, hito 8.3; ampliado en el 19.4,
## 10-11-2026): con «Reducidos», lo que destella se atenúa. Antes solo lo hacían el destello de los
## enemigos y los relámpagos; ahora también los efectos de las fases 17 y 18: el fogonazo radial de
## las explosiones y los rayos (al `DIM`), el resto del sombreador de efectos (a medias), los
## destellos de las evoluciones y el restallido del látigo (fuera) y las luces de los disparos y las
## explosiones. Se lee al empezar el nivel y al cambiar la opción (`refresh`).
##
## Alto contraste (19.5, 11-11-2026; `bullet_palette` 1): las balas enemigas van en amarillo y blanco
## (físicas) y cian (mentales), los colores de varios efectos de las armas (dorado de las evoluciones,
## destellos de hielo, estelas claras). Con él, los efectos de las armas de los jugadores se acercan
## al gris (`GREY`), brillan menos (`SOFT`) y no lanzan los destellos de las evoluciones: lo único
## amarillo y cian intenso de la pantalla son las balas.

const DIM := 0.35                        ## lo que destella, con «Reducidos»
const GREY := 0.6                        ## con alto contraste, cuánto se acercan al gris los efectos
const SOFT := 0.7                        ## y su brillo y opacidad

static var _k := -1.0
static var _hc := -1

## 1 con los destellos normales; `DIM` con los reducidos.
static func k() -> float:
	if _k < 0.0: _k = 1.0 if int(Auto.setting("flashes", 1)) == 1 else DIM
	return _k

static func reduced() -> bool:
	return k() < 1.0

## Alto contraste en las balas (`bullet_palette` 1).
static func contrast() -> bool:
	if _hc < 0: _hc = 1 if int(Auto.setting("bullet_palette", 0)) == 1 else 0
	return _hc == 1

## Un color de los efectos de las armas: igual, o con alto contraste, hacia el gris y más tenue.
static func color(c: Color) -> Color:
	if not contrast(): return c
	var g := grey(c)
	return Color(g.r * SOFT, g.g * SOFT, g.b * SOFT, c.a * SOFT)

## Solo hacia el gris, sin apagarlo (para los tintes, que multiplican un color ya apagado).
static func grey(c: Color) -> Color:
	if not contrast(): return c
	var l := c.get_luminance()
	var g := c.lerp(Color(l, l, l), GREY)
	return Color(g.r, g.g, g.b, c.a)

## Los destellos de las evoluciones (`glint_*`) y el restallido: fuera con cualquiera de las dos opciones.
static func skip_glint(name: String) -> bool:
	if name.begins_with("glint_"): return reduced() or contrast()
	return name == "crack" and reduced()

## Vuelve a leer las opciones y las aplica a los materiales ya creados.
static func refresh() -> void:
	_k = -1.0
	_hc = -1
	FxShade.reflash()
