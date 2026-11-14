class_name WebBehavior
extends KeepBehavior
## Arañas púrpura de Leng (hito 21.10, nivel 3 de la parte 4). Se mueven como `KeepBehavior` (con `keep`
## pequeño, se echan encima) y cada `web_every` s, si su jugador está a menos de `web_range` m, le lanzan
## `web_count` redes (`SpiderWeb`) donde va a estar: un aviso violeta de `web_warn` s y la red, en el suelo.
## Como mucho `web_max` suyas a la vez. Parámetros de la red: `web_radius`, `web_life`, `web_hold`.
## En red, cada PC tiende las suyas y solo contra sus jugadores (la marioneta del invitado, con su reloj):
## el anfitrión no las lanza contra los jugadores de otro PC.

var _web := 0.0
var _webs: Array = []                     ## sin tipo: las gastadas quedan liberadas
var _pending: Array[Dictionary] = []      ## {t, at}: redes en el aire

func start(e: Enemy) -> void:
	super.start(e)
	_web = float(e.data.param("web_every", 4.0)) * randf_range(0.4, 1.0)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var v := super.update(e, target, delta)
	_step(e, target, delta)
	return v

func puppet_step(e: Enemy, delta: float) -> void:
	_step(e, null, delta)

func _step(e: Enemy, target: Player, delta: float) -> void:
	for i in range(_pending.size() - 1, -1, -1):
		var w := _pending[i]
		w.t -= delta
		if w.t > 0.0: continue
		_pending.remove_at(i)
		var web := SpiderWeb.new().setup(e.world, w.at, e.data.params)
		e.world.fx.add_child(web)
		_webs.append(web)
	_web -= delta
	if _web > 0.0: return
	_web = float(e.data.param("web_every", 4.0))
	var q := _local_target(e, target)
	if q == null: return
	if q.global_position.distance_to(e.global_position) > float(e.data.param("web_range", 7.0)): return
	_webs.assign(_webs.filter(func(w: Variant) -> bool: return is_instance_valid(w) and not (w as Node).is_queued_for_deletion()))
	var n := mini(int(e.data.param("web_count", 1)), int(e.data.param("web_max", 3)) - _webs.size() - _pending.size())
	var warn := float(e.data.param("web_warn", 0.6))
	var r := float(e.data.param("web_radius", 1.0))
	for i in n:
		var at := q.global_position + q.velocity * Vector3(1, 0, 1) * warn * 0.8
		if i > 0: at += Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5))
		at.y = 0.0
		var tg := Telegraph.new().setup(r, warn, SpiderWeb.COLOR)   # sin net: cada PC, los suyos
		tg.position = at
		e.world.fx.add_child(tg)
		_pending.append({"t": warn, "at": at})
	if n > 0:
		play_attack_anim(e, "bite")
		e.world.sfx("brush", e.global_position)

## El jugador al que tejerle: el suyo si es de este PC; en la marioneta, el de este PC más cercano.
static func _local_target(e: Enemy, target: Player) -> Player:
	if target != null: return target if not target.remote else null
	var best: Player = null
	var bd := INF
	for p in e.world.players:
		if p.remote or p.health <= 0.0: continue
		var d := p.global_position.distance_to(e.global_position)
		if d < bd:
			bd = d
			best = p
	return best
