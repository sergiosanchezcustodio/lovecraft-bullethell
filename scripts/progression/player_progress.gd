class_name PlayerProgress
extends RefCounted
## Experiencia, nivel y mejoras de un jugador durante la partida. Se conserva entre
## niveles de la misma partida y se pierde al empezar otra (GDD 4.3).

signal leveled_up(new_level: int)

## Una opción del menú de subida de nivel.
class Option:
	enum Kind { NEW_WEAPON, WEAPON_LEVEL, PASSIVE }
	var kind: Kind
	var weapon: WeaponData
	var upgrade: UpgradeData
	var to_level := 1
	func title() -> String:
		match kind:
			Kind.NEW_WEAPON: return weapon.display_name
			Kind.WEAPON_LEVEL: return "%s  %d" % [weapon.display_name, to_level]
		return "%s  %d" % [upgrade.display_name, to_level]
	func text() -> String:
		match kind:
			Kind.NEW_WEAPON: return "Arma nueva"
			Kind.WEAPON_LEVEL: return weapon.level_text[to_level - 2] if to_level - 2 < weapon.level_text.size() else "Mejora"
		return upgrade.description

var rules: ProgressionData
var level := 1
var xp := 0.0
var pending := 0                          ## subidas de nivel aún sin elegir mejora
var passives := {}                        ## id -> nivel
var weapon_pool: Array[WeaponData] = []   ## armas que pueden salir
var upgrade_pool: Array[UpgradeData] = []

func _init(p_rules: ProgressionData) -> void:
	rules = p_rules

func xp_to_next() -> float:
	return rules.xp_to_next(level)

func add_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		pending += 1
		leveled_up.emit(level)

## Hasta `n` opciones distintas y válidas: armas nuevas que aún no tiene, subir armas
## que no están al máximo y pasivas que no están al máximo.
func roll_options(weapons: WeaponSystem, rng: RandomNumberGenerator, n: int = -1) -> Array[Option]:
	if n < 0: n = rules.options_per_level
	var cands: Array[Option] = []
	for wd in weapon_pool:
		var owned := weapons.get_weapon(wd.id)
		var o := Option.new()
		if owned == null:
			o.kind = Option.Kind.NEW_WEAPON
			o.weapon = wd
			cands.append(o)
		elif owned.level < wd.max_level:
			o.kind = Option.Kind.WEAPON_LEVEL
			o.weapon = wd
			o.to_level = owned.level + 1
			cands.append(o)
	for up in upgrade_pool:
		var lv: int = passives.get(up.id, 0)
		if lv < up.max_level:
			var o := Option.new()
			o.kind = Option.Kind.PASSIVE
			o.upgrade = up
			o.to_level = lv + 1
			cands.append(o)
	# Barajar (Fisher-Yates con el generador dado, para que sea reproducible) y quedarse n
	for i in range(cands.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := cands[i]; cands[i] = cands[j]; cands[j] = tmp
	return cands.slice(0, mini(n, cands.size()))

## Aplica la opción elegida.
func choose(o: Option, p: Player) -> void:
	match o.kind:
		Option.Kind.NEW_WEAPON: p.weapons.add_weapon(o.weapon)
		Option.Kind.WEAPON_LEVEL: p.weapons.get_weapon(o.weapon.id).level = o.to_level
		Option.Kind.PASSIVE:
			o.upgrade.apply(p)
			passives[o.upgrade.id] = o.to_level
	pending = maxi(pending - 1, 0)
