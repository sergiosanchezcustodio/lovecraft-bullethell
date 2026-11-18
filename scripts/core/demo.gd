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

## El cartel, en el idioma del juego.
static func locked() -> String:
	return L.t("En el juego completo")
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
	return not on() or (c.price <= 0 and c.secret == "")   # los secretos, fuera de la demo (16.25)

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

## ¿Está este modelo en la build? (hito 23.2) La demo se exporta sin lo que solo usan las partes 2 a
## 4 y las noches (tools/demo_fuera.py): las criaturas, las arenas y el vestuario de los demás
## investigadores. Lo que lo enseñaría (la Biblioteca, el vestuario de un personaje cerrado) lo mira
## aquí antes. En el juego completo, siempre.
static func has_model(model: String) -> bool:
	return not on() or model == "" or VoxelBuilder.model_exists("res://models/%s.json" % model)

## ¿Entra en la demo este nivel o noche? (las páginas de los lugares y los finales de la Biblioteca)
static func level_in_demo(id: String) -> bool:
	return not on() or level_ok(id)

## ¿Sale esta criatura en la demo? Las de los niveles de la parte 1 (su grupo, las de mitad de
## nivel, el evento final…). En la Biblioteca de la demo, las demás salen cerradas aunque su
## modelo esté en la build (algunos se quedan, porque el código los nombra).
static var _enemies := {}
static func enemy_ok(id: String) -> bool:
	if not on(): return true
	if _enemies.is_empty():
		for l in Campaign.levels():
			if int(l.part) >= PARTS: continue
			var p := "res://data/levels/%s.tres" % String(l.id)
			var ld := load(p) as LevelData if ResourceLoader.exists(p) else null
			if ld == null: continue
			for prop in ld.get_property_list():
				var v: Variant = ld.get(prop.name)
				for e in (v if v is Array else [v]):
					if e is EnemyData: _enemies[String((e as EnemyData).id)] = true
		_enemies[""] = true
	return _enemies.has(id)
