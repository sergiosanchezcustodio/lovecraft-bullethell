class_name PetDive
extends PetBehavior
## Mini-Byakhee (DIVE): vuela alto junto a su jugador; cada poco elige al enemigo más
## cercano, se pone encima (con un aviso en el suelo) y cae en picado: golpe en área con
## empuje. Luego vuelve a subir.

var _phase := 0                              ## 0 volando, 1 sobre el objetivo, 2 cayendo, 3 subiendo
var _t := 0.0
var _spot := Vector3.ZERO

const AIM_TIME := 0.5
const FALL_TIME := 0.18
const RISE_TIME := 0.5

func step(delta: float) -> void:
	_t += delta
	match _phase:
		0:
			pet.lift = 1.0
			if pet.cooldown > 0.0 or pet.world == null: return
			var e := pet.world.nearest_enemy(pet.owner_player.global_position, pet.data.attack_range)
			if e == null: return
			_spot = e.global_position
			_phase = 1
			_t = 0.0
			var tg := Telegraph.new().setup(pet.data.radius, AIM_TIME + FALL_TIME, Color(0.6, 0.3, 0.9, 0.55))
			tg.position = Vector3(_spot.x, 0.0, _spot.z)
			pet.world.fx.add_child(tg)
		1:
			pet.goal = _spot
			pet.speed = pet.owner_player.data.move_speed * 2.5
			pet.target = null
			if _t >= AIM_TIME:
				_phase = 2
				_t = 0.0
				pet.teleport(_spot)
				pet.act()
		2:
			pet.goal = pet.global_position
			pet.lift = 1.0 - clampf(_t / FALL_TIME, 0.0, 1.0) * 0.9
			if _t >= FALL_TIME:
				for e in pet.world.enemies_in_circle(_spot, pet.data.radius): pet.strike(e)
				var fx := Slash.new()
				fx.radius = pet.data.radius
				fx.color = Color(0.7, 0.45, 1.0, 0.9)
				fx.position = _spot
				pet.world.fx.add_child(fx)
				_phase = 3
				_t = 0.0
				pet.cooldown = pet.data.attack_every
		3:
			pet.lift = 0.1 + 0.9 * clampf(_t / RISE_TIME, 0.0, 1.0)
			if _t >= RISE_TIME: _phase = 0
