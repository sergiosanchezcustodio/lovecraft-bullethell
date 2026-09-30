class_name PetBlink
extends PetBehavior
## Araña de Tíndalos (BLINK): no respeta las leyes de la geometría. Cada poco desaparece de
## junto a su jugador y reaparece detrás del enemigo más cercano a él, le muerde fuerte y lo
## aturde; luego vuelve por su pie (o saltando otra vez, si se aleja demasiado).

const BEHIND := 0.7

func step(_delta: float) -> void:
	if pet.world == null or pet.cooldown > 0.0: return
	var e := pet.world.nearest_enemy(pet.owner_player.global_position, pet.data.attack_range)
	if e == null: return
	pet.cooldown = pet.data.attack_every
	var back: Vector3 = -e.facing if "facing" in e else (pet.global_position - e.global_position).normalized()
	back.y = 0.0
	if back.length() < 0.01: back = Vector3.BACK
	_flash(pet.global_position)
	pet.teleport(e.global_position + back.normalized() * BEHIND)
	pet.facing = -back.normalized()
	_flash(pet.global_position)
	pet.act()
	pet.strike(e)

## Destello de ángulos: un anillo violeta donde se va y donde aparece.
func _flash(at: Vector3) -> void:
	var fx := Slash.new()
	fx.radius = 0.7
	fx.color = Color(0.45, 0.85, 1.0, 0.9)
	fx.position = Vector3(at.x, 0.0, at.z)
	pet.world.fx.add_child(fx)
