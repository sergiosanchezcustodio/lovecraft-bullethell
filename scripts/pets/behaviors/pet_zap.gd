class_name PetZap
extends PetBehavior
## Mini-Mi-Go (ZAP): crustáceo espacial diminuto. Se queda junto a su jugador y dispara un
## rayo violeta al enemigo más cercano a él (a menos de `attack_range`).

func step(_delta: float) -> void:
	if pet.world == null or pet.cooldown > 0.0: return
	var e := pet.world.nearest_enemy(pet.global_position, pet.data.attack_range)
	pet.target = e
	if e == null: return
	pet.cooldown = pet.data.attack_every
	pet.act()
	var from := pet.global_position + Vector3(0, 0.35, 0)
	var to := e.global_position + Vector3(0, 0.5, 0)
	var dir := to - from
	var fx := Beam.new()
	fx.setup(from, dir.normalized(), dir.length(), 0.05, 0.22, Color(0.85, 0.7, 1.0, 0.95), Color(0.55, 0.3, 1.0, 0.5))
	pet.world.fx.add_child(fx)
	pet.strike(e)
