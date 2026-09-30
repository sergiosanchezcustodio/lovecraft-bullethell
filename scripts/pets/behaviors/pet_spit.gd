class_name PetSpit
extends PetBehavior
## Sapo de Innsmouth (SPIT): se queda junto a su jugador y escupe una bola de baba al enemigo
## más cercano; al caer deja un charco venenoso (zona de ácido: daño por tics y vulnerable).

const POOL_RADIUS := 1.1
const POOL_TIME := 3.5

func step(_delta: float) -> void:
	if pet.world == null or pet.cooldown > 0.0: return
	var e := pet.world.nearest_enemy(pet.global_position, pet.data.attack_range)
	pet.target = e
	if e == null: return
	pet.cooldown = pet.data.attack_every
	pet.act()
	var to := e.global_position
	var t := ThrownExplosive.new()
	t.setup(pet.world, pet.global_position + Vector3(0, 0.3, 0) + pet.facing * 0.25, Vector3(to.x, 0, to.z),
		0.45, 0.0, 0.0, 0.0, Color(0.5, 0.85, 0.25))
	t.configure("baba", 1.2, {"kind": WeaponData.Zone.ACID, "radius": POOL_RADIUS, "time": POOL_TIME,
		"dps": pet.data.attack_at(pet.level()), "vulnerable": 2.0}, 0.0, pet.owner_player.data.bonus_tags)
	pet.world.fx.add_child(t)
	pet.hits += 1
