class_name Flashes
## Accesibilidad, «Destellos (golpes y rayos)» (`Settings` `flashes`, hito 8.3; ampliado en el 19.4,
## 10-11-2026): con «Reducidos», lo que destella se atenúa. Antes solo lo hacían el destello de los
## enemigos y los relámpagos; ahora también los efectos de las fases 17 y 18: el fogonazo radial de
## las explosiones y los rayos (al `DIM`), el resto del sombreador de efectos (a medias), los
## destellos de las evoluciones y el restallido del látigo (fuera) y las luces de los disparos y las
## explosiones. Se lee al empezar el nivel y al cambiar la opción (`refresh`).

const DIM := 0.35                        ## lo que destella, con «Reducidos»

static var _k := -1.0

## 1 con los destellos normales; `DIM` con los reducidos.
static func k() -> float:
	if _k < 0.0: _k = 1.0 if int(Auto.setting("flashes", 1)) == 1 else DIM
	return _k

static func reduced() -> bool:
	return k() < 1.0

## Vuelve a leer la opción y la aplica a los materiales ya creados.
static func refresh() -> void:
	_k = -1.0
	FxShade.reflash()
