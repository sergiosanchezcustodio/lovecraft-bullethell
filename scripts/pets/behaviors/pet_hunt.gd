class_name PetHunt
extends PetBehavior
## Perro (BITE): corre a morder al enemigo más cercano a su jugador, sin alejarse demasiado.
## Gato (CLAW): igual, pero da un zarpazo a todos los que tiene delante y, cuando hieren a su
## jugador, se enfada unos segundos: se eriza, busca más lejos, ataca el doble de rápido y un
## 50 % más fuerte.
## Serpiente de Yig (POISON): muerde y envenena: el daño del nivel por segundo durante
## `effect_time` s, además del mordisco.

var target: Node3D = null
var anger := 0.0                              ## s de enfado que le quedan (gato)

const LEASH := 8.0
const ANGER_TIME := 5.0
const CLAW_REACH := 0.9

func start() -> void:
	if pet.data.kind == PetData.Kind.CLAW:
		pet.owner_player.damaged.connect(func(_d: Damage) -> void: anger = ANGER_TIME)

func angry() -> bool:
	return anger > 0.0

func damage() -> float:
	return pet.data.attack_at(pet.level()) * (1.5 if angry() else 1.0)

func step(delta: float) -> void:
	anger = maxf(anger - delta, 0.0)
	pet.bristle = 1.0 if angry() else 0.0
	var home := pet.owner_player.global_position
	if target == null or not is_instance_valid(target) or not target.is_alive() \
			or target.global_position.distance_to(home) > LEASH:
		var r := pet.data.attack_range * (1.4 if angry() else 1.0)
		target = pet.world.nearest_enemy(home, r) if pet.world != null else null
	pet.target = target
	if target == null or pet.global_position.distance_to(home) >= LEASH: return
	pet.goal = target.global_position
	pet.speed = pet.owner_player.data.move_speed * (1.7 if angry() else 1.45)
	var reach := float(target.hit_radius) + 0.55
	if pet.global_position.distance_to(target.global_position) <= reach and pet.cooldown <= 0.0:
		pet.cooldown = pet.data.attack_every * (0.5 if angry() else 1.0)
		pet.act()
		if pet.data.kind == PetData.Kind.CLAW: _claw()
		else: _hit(target)

func _hit(e: Node3D) -> void:
	var d := Damage.new(damage(), 0.0)
	d.knockback = pet.facing * 0.8
	d.bonus = pet.owner_player.data.bonus_tags
	e.take_damage(d)
	if pet.data.kind == PetData.Kind.POISON and e.is_alive() and e.has_method("poison"):
		e.poison(pet.data.effect_time, pet.data.attack_at(pet.level()), d.bonus)
	pet.hits += 1

## Zarpazo: a todos los que están delante del gato, con un arañazo en el aire.
func _claw() -> void:
	var at := pet.global_position + pet.facing * 0.4
	var hit := false
	for e in pet.world.enemies_in_circle(at, CLAW_REACH):
		_hit(e)
		hit = true
	if not hit: _hit(target)
	var fx := Slash.new()
	fx.radius = CLAW_REACH
	fx.color = Color(1.0, 0.35, 0.3, 0.9) if angry() else Color(0.95, 0.9, 0.8, 0.85)
	fx.position = at
	pet.world.fx.add_child(fx)
