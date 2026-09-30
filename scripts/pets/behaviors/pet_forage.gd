class_name PetForage
extends PetBehavior
## Rata de las Paredes (FORAGE): cada cierto tiempo se aparta un poco, husmea y escarba, y
## encuentra dólares (más con el nivel); a veces, un baúl arcano entero.

var _dig := -1.0                             ## s escarbando (-1 = no)
var _spot := Vector3.ZERO

const DIG_TIME := 1.4

func step(delta: float) -> void:
	if _dig >= 0.0:
		pet.goal = _spot
		if pet.global_position.distance_to(_spot) > 0.5 and _dig == 0.0: return
		pet.goal = pet.global_position
		pet.speed = 0.0
		_dig += delta
		if fmod(_dig, 0.45) < delta: pet.act()
		if _dig >= DIG_TIME:
			_dig = -1.0
			_found()
		return
	if pet.cooldown > 0.0: return
	pet.cooldown = pet.data.attack_every
	var a := randf() * TAU
	_spot = pet.owner_player.global_position + Vector3(cos(a), 0, sin(a)) * 2.5
	_dig = 0.0

func digging() -> bool:
	return _dig >= 0.0

func _found() -> void:
	var money := int(round(pet.data.attack_at(pet.level())))
	var game := pet.game
	if game != null and game.has_method("earn"): game.earn(money)
	pet.found_money += money
	pet.popup("+%d $" % money, Color(1.0, 0.85, 0.35))
	if randf() < pet.data.bonus_at(pet.level()) and game != null and game.get("director") != null:
		var c: ArcaneChest = game.director.spawn_chest()
		if c != null:
			c.position = Vector3(_spot.x, c.position.y, _spot.z)
			pet.popup("¡Un baúl!", Color(0.8, 0.6, 1.0))
