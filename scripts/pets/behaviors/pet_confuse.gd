class_name PetConfuse
extends PetBehavior
## Polilla de Leng (CONFUSE): bonita... hasta que abre las alas. Cada poco vuela sobre el
## grupo de enemigos más denso cerca de su jugador y sacude el polvo de las alas: los de
## debajo quedan confundidos (vagan sin rumbo y no disparan) `effect_time` s.

var _dest := Vector3.ZERO
var _going := false

func step(_delta: float) -> void:
	if pet.world == null: return
	if not _going:
		if pet.cooldown > 0.0: return
		var e := pet.world.densest_enemy(pet.owner_player.global_position, pet.data.attack_range, pet.data.radius)
		if e == null: return
		_dest = e.global_position
		_going = true
	pet.goal = _dest
	pet.speed = pet.owner_player.data.move_speed * 1.8
	if Vector2(pet.global_position.x - _dest.x, pet.global_position.z - _dest.z).length() > 0.6: return
	_going = false
	pet.cooldown = pet.data.attack_every
	pet.act()
	for e in pet.world.enemies_in_circle(_dest, pet.data.radius):
		if e.has_method("confuse"):
			e.confuse(pet.data.effect_time)
			pet.hits += 1
	# nube de polvo: la zona del Polvo de Ibn-Ghazi, sin daño, solo para verlo
	pet.world.fx.add_child(DamageZone.new().setup(pet.world, WeaponData.Zone.DUST, _dest, pet.data.radius, 1.4, 0.0))
