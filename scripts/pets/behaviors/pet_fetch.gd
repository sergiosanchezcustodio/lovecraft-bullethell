class_name PetFetch
extends PetBehavior
## Cuervo de Arkham (FETCH): cada poco sale volando a por las gemas sueltas más cercanas a su
## jugador (a menos de `attack_range`); al llegar, las echa a volar hacia él y, de paso, roba
## unas monedas. Si no hay gemas, picotea a un enemigo cercano y le roba a él.

var _dest := Vector3.ZERO
var _going := false
var _peck: Node3D = null

const REACH := 0.6
const GEM_RADIUS := 3.0

func step(_delta: float) -> void:
	if pet.world == null: return
	if not _going:
		if pet.cooldown > 0.0: return
		var home := pet.owner_player.global_position
		var gems: GemManager = pet.game.get("gems") if pet.game != null else null
		var i := gems.free_gem_near(home, pet.data.attack_range) if gems != null else -1
		_peck = null
		if i >= 0: _dest = gems.gem_position(i)
		else:
			_peck = pet.world.nearest_enemy(home, pet.data.attack_range)
			if _peck == null:
				pet.cooldown = 1.0
				return
			_dest = _peck.global_position
		_going = true
	if _peck != null and is_instance_valid(_peck): _dest = _peck.global_position
	pet.goal = _dest
	pet.speed = pet.owner_player.data.move_speed * 2.2
	pet.rush = true
	if Vector2(pet.global_position.x - _dest.x, pet.global_position.z - _dest.z).length() > REACH: return
	pet.rush = false
	_going = false
	pet.cooldown = pet.data.attack_every
	pet.act()
	if _peck != null:
		if is_instance_valid(_peck): pet.strike(_peck)
	else:
		var gems: GemManager = pet.game.get("gems")
		gems.attract(_dest, GEM_RADIUS)
		pet.hits += 1
	_steal()

## Unas monedas para su jugador (más con el nivel).
func _steal() -> void:
	var money := int(round(pet.data.bonus_at(pet.level())))
	if money <= 0: return
	if pet.game != null and pet.game.has_method("earn"): pet.game.earn(money)
	pet.found_money += money
	pet.popup("+%d $" % money, Color(1.0, 0.85, 0.35))
