class_name PlayerProgress
extends RefCounted
## Experiencia, nivel y mejoras de un jugador durante la partida. Se conserva entre
## niveles de la misma partida y se pierde al empezar otra (GDD 4.3).

signal leveled_up(new_level: int)

## Una opción del menú de subida de nivel.
class Option:
	## EVOLUTION (hito 16.8): una de las dos ramas de un arma al abrir el baúl; `weapon` es la
	## evolución y `from`, el arma que lleva. SIGN (hito 16.9): un Signo Mayor (`sign`, de Signs).
	enum Kind { NEW_WEAPON, WEAPON_LEVEL, PASSIVE, EVOLUTION, SIGN }
	var kind: Kind
	var weapon: WeaponData
	var upgrade: UpgradeData
	var from: WeaponData
	var sign := {}
	var to_level := 1
	## Aviso de evolución en la carta (hito 16.15): "" si no completa ni prepara ninguna.
	var evo_hint := ""
	var evo_ready := false             ## con esta opción, el arma evoluciona en el próximo baúl
	func title() -> String:
		match kind:
			Kind.NEW_WEAPON, Kind.EVOLUTION: return weapon.display_name
			Kind.WEAPON_LEVEL: return "%s  %d" % [weapon.display_name, to_level]
			Kind.SIGN: return String(sign.get("name", ""))
		return "%s  %d" % [upgrade.display_name, to_level]
	func text() -> String:
		match kind:
			Kind.NEW_WEAPON, Kind.EVOLUTION: return weapon.description if weapon.description != "" else "Arma nueva"
			Kind.SIGN: return String(sign.get("text", ""))
			Kind.WEAPON_LEVEL: return weapon.level_text[to_level - 2] if to_level - 2 < weapon.level_text.size() else "Mejora"
		return upgrade.description

var rules: ProgressionData
var level := 1
var xp := 0.0
var pending := 0                          ## subidas de nivel aún sin elegir mejora
var passives := {}                        ## id -> nivel
var weapon_pool: Array[WeaponData] = []   ## armas que pueden salir
var upgrade_pool: Array[UpgradeData] = []
var attr_gains: Array[String] = []        ## atributo ganado en cada subida aún sin elegir mejora
var weapon_slots := 4                     ## armas que puede llevar (D-28; la tienda da la 5.ª)
var item_slots := 4                       ## objetos (pasivas) distintos que puede llevar
var banished := {}                        ## lo descartado con las Cartas del tarot (key_of): ya no sale
## Armas (id) que han de elegir rama de evolución (hito 16.8): el baúl las apunta y la ventana
## de la subida las atiende antes que las subidas pendientes.
var evolving: Array[StringName] = []
## Signos Mayores (hito 16.9): los que lleva y cuántos le quedan por elegir. `sign_save`: la
## partida guardada de la que salen los abiertos (la del PC de este jugador).
var signs: Array[StringName] = []
var signs_pending := 0
var sign_save: SaveData
## Cooperativo: la experiencia es común (D-07). Referencia débil: el equipo ya guarda a sus
## miembros y, con dos fuertes, ninguno de los dos se liberaba nunca (ni al reiniciar).
var team: TeamXp:
	get: return _team_ref.get_ref() if _team_ref != null else null
	set(v): _team_ref = weakref(v) if v != null else null
var _team_ref: WeakRef
var color := Color(0.18, 0.42, 0.78)      ## del jugador: la barra común se pinta con el de quien tiene el turno

func _init(p_rules: ProgressionData) -> void:
	rules = p_rules

func xp_to_next() -> float:
	return rules.xp_to_next(level)

func add_xp(amount: float) -> void:
	if team != null:
		team.add(amount)
		return
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		gain_level()

## Sube un nivel: una mejora más por elegir (y el +1 de atributo, que pone el jugador).
func gain_level() -> void:
	level += 1
	pending += 1
	leveled_up.emit(level)

## Fracción de la barra de experiencia (la del equipo en cooperativo).
func xp_fraction() -> float:
	if team != null: return team.xp / team.xp_to_next()
	return xp / xp_to_next()

## Experiencia que falta para la próxima subida (la del equipo en cooperativo).
func xp_missing() -> float:
	if team != null: return team.xp_to_next() - team.xp
	return xp_to_next() - xp

## ¿Sube este jugador la próxima vez? (solo en cooperativo)
func is_next() -> bool:
	return team != null and team.next() == self

## Color de la barra: en cooperativo, el de quien sube la próxima vez (D-39).
func xp_color() -> Color:
	if team != null and team.next() != null: return team.next().color
	return color

## Hasta `n` opciones distintas y válidas: armas nuevas que aún no tiene, subir armas
## que no están al máximo y pasivas que no están al máximo.
func roll_options(weapons: WeaponSystem, rng: RandomNumberGenerator, n: int = -1) -> Array[Option]:
	if n < 0:
		n = rules.options_per_level
		# suerte: por encima de 1, probabilidad de una opción más (Peaslee)
		var luck: float = weapons.player.data.luck if weapons != null and weapons.player != null else 1.0
		if luck > 1.0 and rng.randf() < luck - 1.0: n += 1
	var cands: Array[Option] = []
	for wd in weapon_pool:
		if banished.has("w:" + String(wd.id)): continue
		var owned := weapons.get_weapon(wd.id)
		var o := Option.new()
		if owned == null:
			if weapons.weapons.size() >= weapon_slots: continue      # sin hueco para otra arma
			if not Challenge.new_weapon_ok(wd): continue              # desafíos de una sola arma o solo arcanas (15.2)
			o.kind = Option.Kind.NEW_WEAPON
			o.weapon = wd
			cands.append(o)
		elif owned.level < wd.max_level:
			o.kind = Option.Kind.WEAPON_LEVEL
			o.weapon = wd
			o.to_level = owned.level + 1
			cands.append(o)
	for up in upgrade_pool:
		if banished.has("u:" + String(up.id)): continue
		var lv: int = passives.get(up.id, 0)
		if lv == 0 and _items_owned() >= item_slots: continue       # sin hueco para otro objeto
		if lv < up.max_level:
			var o := Option.new()
			o.kind = Option.Kind.PASSIVE
			o.upgrade = up
			o.to_level = lv + 1
			cands.append(o)
	# Con 50 armas y 50 objetos (D-38), al azar casi nunca saldría lo que ya se lleva: lo propio
	# pesa OWNED_WEIGHT veces más y, si hay, una de las opciones es siempre mejorar algo propio.
	var out: Array[Option] = []
	var owned := cands.filter(func(o: Option) -> bool: return o.kind != Option.Kind.NEW_WEAPON and o.to_level > 1)
	if not owned.is_empty() and n > 0:
		var first: Option = owned[rng.randi_range(0, owned.size() - 1)]
		out.append(first)
		cands.erase(first)
	while out.size() < n and not cands.is_empty():
		var total := 0.0
		for o in cands: total += _weight(o)
		var r := rng.randf() * total
		var pick := cands.size() - 1
		for i in cands.size():
			r -= _weight(cands[i])
			if r <= 0.0:
				pick = i
				break
		out.append(cands[pick])
		cands.remove_at(pick)
	# en orden al azar: la mejora garantizada no va siempre la primera
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := out[i]; out[i] = out[j]; out[j] = tmp
	for o in out: mark_hint(o, weapons)
	return out

## Las opciones que tocan ahora: las dos ramas de la evolución pendiente, los Signos Mayores
## por elegir o, si no hay, la subida de nivel de siempre.
func next_options(weapons: WeaponSystem, rng: RandomNumberGenerator, n: int = -1) -> Array[Option]:
	var evo := evolution_options(weapons)
	if not evo.is_empty(): return evo
	var sg := sign_options(rng)
	return sg if not sg.is_empty() else roll_options(weapons, rng, n)

## ¿Tiene algo que elegir que no sea una subida? (Rama de evolución o Signo Mayor.)
func has_special(weapons: WeaponSystem) -> bool:
	if not evolution_options(weapons).is_empty(): return true
	if signs_pending > 0 and Signs.roll(sign_save, signs, RandomNumberGenerator.new()).is_empty(): signs_pending = 0
	return signs_pending > 0

## Signos Mayores que se le ofrecen (hito 16.9): hasta tres de los abiertos que no lleva. Sin
## ninguno abierto, no queda nada por elegir.
func sign_options(rng: RandomNumberGenerator) -> Array[Option]:
	var out: Array[Option] = []
	if signs_pending <= 0: return out
	for id in Signs.roll(sign_save, signs, rng):
		var o := Option.new()
		o.kind = Option.Kind.SIGN
		o.sign = Signs.find(id)
		out.append(o)
	if out.is_empty(): signs_pending = 0
	return out

## Ramas de la primera arma de `evolving` que aún puede evolucionar (hito 16.8). Las que ya
## no pueden (se ha quitado el arma) salen de la lista.
func evolution_options(weapons: WeaponSystem) -> Array[Option]:
	var out: Array[Option] = []
	while not evolving.is_empty() and out.is_empty():
		var w := weapons.get_weapon(evolving[0]) if weapons != null else null
		if w != null and not w.data.evolved:
			for id in w.data.branches():
				var path := "res://data/weapons/%s.tres" % id
				if not ResourceLoader.exists(path): continue
				var o := Option.new()
				o.kind = Option.Kind.EVOLUTION
				o.weapon = load(path)
				o.from = w.data
				out.append(o)
		if out.is_empty(): evolving.pop_front()
	return out

## Aviso de evolución de una carta (hito 16.15): el objeto que le falta a un arma que lleva, o
## el arma (o su último nivel) cuyo objeto ya lleva.
func mark_hint(o: Option, weapons: WeaponSystem) -> void:
	o.evo_hint = ""
	o.evo_ready = false
	if weapons == null: return
	match o.kind:
		Option.Kind.PASSIVE:
			if o.to_level != 1: return
			for w in weapons.weapons:
				if w.data.evolved or w.data.evolves_with != o.upgrade.id or w.data.branches().is_empty(): continue
				o.evo_ready = w.level >= w.data.max_level
				o.evo_hint = ("Evoluciona: %s" if o.evo_ready else "Con %s al nivel %d, evoluciona") % (
					[w.data.display_name] if o.evo_ready else [w.data.display_name, w.data.max_level])
				if o.evo_ready: return
		Option.Kind.WEAPON_LEVEL, Option.Kind.NEW_WEAPON:
			var wd := o.weapon
			if wd.branches().is_empty() or int(passives.get(wd.evolves_with, 0)) <= 0: return
			var item := _upgrade_name(wd.evolves_with)
			o.evo_ready = o.kind == Option.Kind.WEAPON_LEVEL and o.to_level >= wd.max_level
			o.evo_hint = ("Evoluciona con %s" if o.evo_ready else "Evolucionará con %s") % item

func _upgrade_name(id: StringName) -> String:
	for up in upgrade_pool:
		if up.id == id: return up.display_name
	return String(id)

const OWNED_WEIGHT := 8.0

## Clave de lo que ofrece una opción (para descartarla): "w:<arma>" o "u:<objeto>".
static func key_of(o: Option) -> String:
	if o.kind == Option.Kind.EVOLUTION: return "e:" + String(o.weapon.id)
	if o.kind == Option.Kind.SIGN: return "s:" + String(o.sign.get("id", ""))
	return ("u:" + String(o.upgrade.id)) if o.kind == Option.Kind.PASSIVE else ("w:" + String(o.weapon.id))

## La opción que corresponde a una clave de `key_of` con lo que lleva ahora el jugador (en red,
## lo que ha elegido en su PC). Null si ya no vale: arma sin hueco o al máximo, objeto al máximo.
func option_for(key: String, weapons: WeaponSystem) -> Option:
	var id := StringName(key.substr(2))
	if key.begins_with("e:"):                      # rama de la evolución pendiente (hito 16.8)
		for e in evolution_options(weapons):
			if e.weapon.id == id: return e
		return null
	if key.begins_with("s:"):                      # Signo Mayor (16.9): lo ha elegido en su PC, con sus logros
		var sg := Signs.find(String(id))
		if sg.is_empty() or signs.has(id) or signs_pending <= 0: return null
		var so := Option.new()
		so.kind = Option.Kind.SIGN
		so.sign = sg
		return so
	var o := Option.new()
	if key.begins_with("u:"):
		for up in upgrade_pool:
			if up.id != id: continue
			var lv: int = passives.get(up.id, 0)
			if lv >= up.max_level or (lv == 0 and _items_owned() >= item_slots): return null
			o.kind = Option.Kind.PASSIVE
			o.upgrade = up
			o.to_level = lv + 1
			return o
		return null
	if not key.begins_with("w:") or weapons == null: return null
	var owned := weapons.get_weapon(id)
	if owned != null:
		if owned.level >= owned.data.max_level: return null
		o.kind = Option.Kind.WEAPON_LEVEL
		o.weapon = owned.data
		o.to_level = owned.level + 1
		return o
	for wd in weapon_pool:
		if wd.id != id: continue
		if weapons.weapons.size() >= weapon_slots: return null
		o.kind = Option.Kind.NEW_WEAPON
		o.weapon = wd
		return o
	return null

## Peso al sortear: subir un arma u objeto que ya lleva pesa más que algo nuevo.
static func _weight(o: Option) -> float:
	return OWNED_WEIGHT if o.kind != Option.Kind.NEW_WEAPON and o.to_level > 1 else 1.0

func _items_owned() -> int:
	var n := 0
	for k in passives:
		if int(passives[k]) > 0: n += 1
	return n

## Aplica la opción elegida.
func choose(o: Option, p: Player) -> void:
	if o.kind == Option.Kind.EVOLUTION:            # no gasta subida de nivel (hito 16.8)
		var w := p.weapons.get_weapon(o.from.id)
		if w != null: p.weapons.evolve(w, o.weapon.id)
		evolving.erase(o.from.id)
		return
	if o.kind == Option.Kind.SIGN:                 # tampoco (hito 16.9)
		var id := StringName(String(o.sign.get("id", "")))
		if not signs.has(id): signs.append(id)
		signs_pending = maxi(signs_pending - 1, 0)
		p.rebuild_stats()
		return
	match o.kind:
		Option.Kind.NEW_WEAPON: p.weapons.add_weapon(o.weapon)
		Option.Kind.WEAPON_LEVEL: p.weapons.get_weapon(o.weapon.id).level = o.to_level
		Option.Kind.PASSIVE:
			passives[o.upgrade.id] = o.to_level
			p.rebuild_stats()
	pending = maxi(pending - 1, 0)
	if not attr_gains.is_empty(): attr_gains.pop_front()
