class_name DouseBehavior
extends EnemyBehavior
## Sectarios de la Sabiduría Estrellada (hito 23.8, «El que acecha en la oscuridad»). Persiguen como
## cualquiera, pero si pasan junto a una farola encendida (`douse_range` m) se paran `douse_time` s a
## apagarla con su capucha y su gancho: queda a oscuras `douse_off` s (Blackout.douse). Hay que matarlos
## antes. Parámetros (opcionales): douse_range (1.6), douse_time (1.4), douse_off (9), douse_every (4),
## douse_seek (5 m: más cerca, va a por la farola).

var dousing := -1                        ## la farola que apaga ahora (-1: ninguna)
var doused := 0                          ## farolas apagadas (tests)
var _t := 0.0
var _cd := 0.0
var _seek := -1                         ## la farola a la que va

func start(_e: Enemy) -> void:
	_cd = randf_range(0.5, 2.0)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var b := Blackout.current
	if dousing >= 0:
		e.anim = "burst"
		_t += delta
		if b == null or not b.lit_lamp(dousing):
			dousing = -1
			return Vector3.ZERO
		if _t >= float(e.data.param("douse_time", 1.4)):
			b.douse(dousing, float(e.data.param("douse_off", 9.0)))
			doused += 1
			dousing = -1
			_cd = float(e.data.param("douse_every", 4.0))
		return Vector3.ZERO
	_cd -= delta
	if b != null and _cd <= 0.0 and b.host:
		_cd = 0.5
		var i := b.nearest_lit(e.global_position, float(e.data.param("douse_range", 1.6)))
		if i >= 0:
			dousing = i
			_seek = -1
			_t = 0.0
			e.windup(float(e.data.param("douse_time", 1.4)))
			return Vector3.ZERO
		_seek = b.nearest_lit(e.global_position, float(e.data.param("douse_seek", 5.0)))
	if b != null and _seek >= 0 and b.lit_lamp(_seek):            # una farola cerca: a por ella
		var to := Vector3(b.lamps[_seek].at.x, 0.0, b.lamps[_seek].at.y) - e.global_position * Vector3(1, 0, 1)
		e.anim = "walk"
		return shape_path(e, to.normalized(), e.data.move_speed)
	return super.update(e, target, delta)
