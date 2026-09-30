class_name PetCharge
extends PetBehavior
## Embestida (CHARGE): pez de Innsmouth y cabra de los bosques. Cada poco elige al enemigo más
## cercano a su jugador, se para, toma carrerilla un instante y embiste en línea recta: golpea
## una vez a cada enemigo que encuentra en el camino (empuje y, la cabra, aturdimiento).

var _phase := 0                              ## 0 siguiendo, 1 carrerilla, 2 embistiendo
var _t := 0.0
var _dir := Vector3.FORWARD
var _end := Vector3.ZERO
var _hit := {}

const WINDUP := 0.35
const DASH_SPEED := 9.0
const DASH_MAX := 5.0
const HIT_RADIUS := 0.7

func step(delta: float) -> void:
	_t += delta
	match _phase:
		0:
			pet.rush = false
			if pet.cooldown > 0.0 or pet.world == null: return
			var e := pet.world.nearest_enemy(pet.owner_player.global_position, pet.data.attack_range)
			if e == null: return
			var to := e.global_position - pet.global_position
			to.y = 0.0
			if to.length() < 0.3: return
			_dir = to.normalized()
			_end = pet.global_position + _dir * clampf(to.length() + 1.5, 2.0, DASH_MAX)
			_phase = 1
			_t = 0.0
			_hit.clear()
			pet.act()
		1:
			pet.goal = pet.global_position
			pet.speed = 0.0
			pet.facing = _dir
			if _t >= WINDUP:
				_phase = 2
				_t = 0.0
		2:
			pet.goal = _end
			pet.speed = DASH_SPEED
			pet.rush = true
			for e in pet.world.enemies_in_circle(pet.global_position, HIT_RADIUS):
				var id := e.get_instance_id()
				if _hit.has(id): continue
				_hit[id] = true
				pet.strike(e)
			if pet.global_position.distance_to(_end) < 0.2 or _t > DASH_MAX / DASH_SPEED + 0.3:
				_phase = 0
				pet.rush = false
				pet.cooldown = pet.data.attack_every
