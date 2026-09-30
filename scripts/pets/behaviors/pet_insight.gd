class_name PetInsight
extends PetBehavior
## Búho de los sueños (INSIGHT): vuela junto al hombro de su jugador y le da más experiencia
## por gema (`Player.pet_xp_mult`), más cuanto más nivel.

func start() -> void:
	leveled()

func leveled() -> void:
	pet.owner_player.pet_xp_mult = 1.0 + pet.data.bonus_at(pet.level())
