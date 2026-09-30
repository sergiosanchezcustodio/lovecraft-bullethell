class_name PetDevour
extends PetBehavior
## Shoggoth bebé (DEVOUR): va pegado a su jugador y se traga las balas enemigas que pasan
## cerca, unas pocas por segundo (más con el nivel). Se hincha un momento al tragar.

var _budget := 0.0

const RADIUS := 1.2
const MAX_BUDGET := 3.0

func step(delta: float) -> void:
	if pet.world == null: return
	_budget = minf(_budget + pet.data.bonus_at(pet.level()) * delta, MAX_BUDGET)
	if _budget < 1.0: return
	var n := pet.world.bullets.devour_enemy_bullets(pet.global_position, RADIUS, int(_budget))
	if n > 0:
		_budget -= n
		pet.hits += n
		pet.act()
