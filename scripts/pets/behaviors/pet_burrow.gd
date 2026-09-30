class_name PetBurrow
extends PetBehavior
## Mini-Dhole (BURROW): gusano gigantesco reducido a mascota. Cada poco se hunde en el suelo,
## avanza bajo tierra hasta el grupo de enemigos más denso cerca de su jugador y, tras un
## aviso, sale bajo ellos: golpe en área que empuja y aturde. Después vuelve con su jugador.

var _phase := 0                              ## 0 siguiendo, 1 hundiéndose, 2 bajo tierra, 3 saliendo
var _t := 0.0
var _spot := Vector3.ZERO

const SINK := 0.3
const TUNNEL := 0.8
const WARN := 0.45

func step(delta: float) -> void:
	_t += delta
	match _phase:
		0:
			pet.hidden = false
			if pet.cooldown > 0.0 or pet.world == null: return
			var e := pet.world.densest_enemy(pet.owner_player.global_position, pet.data.attack_range, pet.data.radius)
			if e == null: return
			_spot = e.global_position
			_phase = 1
			_t = 0.0
			_dirt(pet.global_position, 0.6)
		1:
			pet.goal = pet.global_position
			pet.speed = 0.0
			if _t >= SINK:
				pet.hidden = true
				_phase = 2
				_t = 0.0
		2:
			pet.goal = pet.global_position
			if _t >= TUNNEL:
				pet.teleport(_spot)
				var tg := Telegraph.new().setup(pet.data.radius, WARN, Color(0.75, 0.5, 0.25, 0.6))
				tg.position = Vector3(_spot.x, 0.0, _spot.z)
				pet.world.fx.add_child(tg)
				_phase = 3
				_t = 0.0
		3:
			pet.goal = pet.global_position
			if _t >= WARN:
				pet.hidden = false
				pet.act()
				for e in pet.world.enemies_in_circle(_spot, pet.data.radius): pet.strike(e)
				_dirt(_spot, pet.data.radius)
				_phase = 0
				pet.cooldown = pet.data.attack_every

## Tierra removida: un anillo pardo que se abre.
func _dirt(at: Vector3, r: float) -> void:
	var fx := Slash.new()
	fx.radius = r
	fx.color = Color(0.62, 0.45, 0.28, 0.95)
	fx.position = Vector3(at.x, 0.0, at.z)
	pet.world.fx.add_child(fx)
