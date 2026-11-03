class_name SingBehavior
extends KeepBehavior
## Hija de los Marsh (hito 16.17): se queda atrás como los acólitos (`KeepBehavior`) y cada
## `sing_every` s canta: cura `sing_heal` de su vida máxima a las criaturas marinas (etiqueta
## `marina`: Profundos, híbridos…) a menos de `sing_radius` m, ella no. Mientras viva, el grupo
## aguanta: hay que ir a por ella primero. Las notas («♪») y el canto se ven y se oyen en todos los
## PC (`world.shout`, `world.sfx`); la vida, la cuenta el anfitrión.
var _sing := 0.0
const NOTE := Color(0.55, 0.95, 0.85)

func start(e: Enemy) -> void:
	super.start(e)
	_sing = float(e.data.param("sing_every", 2.6)) * randf_range(0.5, 1.0)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var v := super.update(e, target, delta)
	_sing -= delta
	if _sing <= 0.0:
		_sing = float(e.data.param("sing_every", 2.6))
		sing(e)
	return v

## Canta: cura a las cercanas; devuelve cuántas.
func sing(e: Enemy) -> int:
	var r := float(e.data.param("sing_radius", 6.0))
	var k := float(e.data.param("sing_heal", 0.12))
	var n := 0
	for o: Node3D in e.world.enemies_in_circle(e.global_position, r):
		var x := o as Enemy
		if x == null or x == e or not x.is_alive() or not x.data.tags.has(&"marina"): continue
		var top := x.data.max_health * x.health_scale
		if x.health >= top: continue
		x.health = minf(top, x.health + top * k)
		VoxelFx.puff(e.world.fx, x.global_position + Vector3(0, 1.0 * x.model_scale, 0), "sparkle", 0.45, NOTE, 0.9)
		n += 1
	e.world.shout("♪" if n == 0 else "♪ ♫", e.global_position + Vector3(0, 2.3, 0), NOTE, 70, 0.9, 1.3)
	if n > 0: e.world.sfx("chant", e.global_position)
	play_attack_anim(e, "idle")
	return n
