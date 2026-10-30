class_name Demo
extends RefCounted
## Demo de la parte 1 (hito 13.17): la build de los perfiles «Windows Demo» y «macOS Demo»
## (etiqueta de exportación `demo`). Entra la Antártida entera, hasta el shoggoth primigenio, con
## los cuatro investigadores de inicio (los de precio 0), la tienda sin los demás personajes y el
## cooperativo local; no entran el juego online, la partida del día ni el modo sin fin. Lo que
## falta se ve con el cartel «En el juego completo». Al vencer al shoggoth, el relato del fin de la
## demo (`fin_demo` en data/library/relatos.json) y de vuelta al menú.
## La partida es la misma que la del juego completo (mismo user://): lo hecho en la demo sigue ahí.
## Pruebas sin exportar: `demo_build=true`.

const LOCKED := "En el juego completo"
const PARTS := 1                          ## partes que se juegan (la primera)
const END_RELATO := "fin_demo"

static var _on := -1

static func on() -> bool:
	if _on < 0: _on = 1 if OS.has_feature("demo") or LaunchArgs.from_cmdline().get_bool("demo_build") else 0
	return _on == 1

## Tests: fuerza la demo (1), el juego completo (0) o vuelve a mirarlo (-1).
static func force(v: int) -> void:
	_on = v

## ¿Se puede jugar esta parte (0..2)?
static func part_ok(part: int) -> bool:
	return not on() or part < PARTS

## ¿Y este nivel? Los de la campaña, por su parte; el del día y el sin fin, nunca en la demo.
static func level_ok(id: String) -> bool:
	if not on(): return true
	for l in Campaign.levels():
		if String(l.id) == id: return int(l.part) < PARTS
	return false

## ¿Entra este investigador? En la demo, solo los de inicio.
static func character_ok(c: CharacterData) -> bool:
	return not on() or c.price <= 0

## ¿Está este artículo de la tienda fuera de la demo? (los personajes que no son de inicio)
static func shop_locked(e: Shop.Entry) -> bool:
	return on() and e.character != null and not character_ok(e.character)

## Último nivel que se juega: el de Cthulhu o, en la demo, el del shoggoth.
static func last_level() -> String:
	if not on(): return Campaign.last_id()
	var last := ""
	for l in Campaign.levels():
		if int(l.part) < PARTS: last = String(l.id)
	return last

## Versión para los menús: «v0.9.0» o «v0.9.0 · demo».
static func version_text() -> String:
	return "v" + String(ProjectSettings.get_setting("application/config/version", "?")) + ("  ·  demo" if on() else "")
