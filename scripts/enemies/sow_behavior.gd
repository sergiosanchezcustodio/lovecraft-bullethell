class_name SowBehavior
extends KeepBehavior
## Antiguo sembrador (hito 16.16): se queda a distancia como los acólitos (`KeepBehavior`) y cada
## `sow_every` s planta a sus pies una vaina de esporas (`SporePod`), una mina que revienta al
## acercarse un jugador. Como mucho `sow_max` suyas a la vez. Siembra por donde pasa: el campo de
## minas va quedando entre él y los jugadores. Parámetros de la vaina: `pod_radius`, `pod_trigger`,
## `pod_life`, `pod_damage`, `pod_mental` (ver SporePod).
## En red, la marioneta del invitado siembra las suyas con su reloj (cada vaina daña a los de su PC).
var _sow := 0.0
var _pods: Array = []                     ## sin tipo: las reventadas quedan liberadas

func start(e: Enemy) -> void:
	super.start(e)
	_sow = float(e.data.param("sow_every", 3.5)) * randf_range(0.4, 1.0)

func update(e: Enemy, target: Player, delta: float) -> Vector3:
	var v := super.update(e, target, delta)
	_step(e, delta)
	return v

func puppet_step(e: Enemy, delta: float) -> void:
	_step(e, delta)

func _step(e: Enemy, delta: float) -> void:
	_sow -= delta
	if _sow > 0.0: return
	_sow = float(e.data.param("sow_every", 3.5))
	_pods.assign(_pods.filter(func(p: Variant) -> bool: return is_instance_valid(p) and not (p as Node).is_queued_for_deletion()))
	if _pods.size() >= int(e.data.param("sow_max", 4)): return
	var at := e.global_position
	for p: Node3D in _pods:                            # no dos vainas juntas
		if p.global_position.distance_to(at) < 1.6: return
	var pod := SporePod.new().setup(e.world, at, e.data.params)
	pod.who = e.data.id
	e.world.fx.add_child(pod)
	_pods.append(pod)
	play_attack_anim(e, "lash")
