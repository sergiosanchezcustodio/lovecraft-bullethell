class_name PetHeal
extends PetBehavior
## Gaviota de Innsmouth (HEAL): carroñera. Cada poco se va volando a por pescado y vuelve con
## él: cura vida y cordura (`bonus_at`, fracción del máximo) al jugador de su equipo con menos
## vida que tenga cerca, casi siempre el suyo. Además chilla la primera vez que ve una élite
## cerca y la marca en el suelo.

var _phase := 0                              ## 0 junto al jugador, 1 yéndose, 2 volviendo
var _t := 0.0
var _away := Vector3.ZERO
var _seen := {}                              ## instance_id de las élites ya avisadas
var _scan := 0.0

const TRIP := 1.6                            ## s de ida y s de vuelta
const SHARE := 8.0                           ## m: a quién puede llevar el pescado
const SPOT := 14.0                           ## m: élites a la vista

func step(delta: float) -> void:
	_t += delta
	_watch(delta)
	match _phase:
		0:
			if pet.cooldown > 0.0: return
			var a := randf() * TAU
			_away = pet.owner_player.global_position + Vector3(cos(a), 0, sin(a)) * 7.0
			_phase = 1
			_t = 0.0
		1:
			pet.goal = _away
			pet.speed = pet.owner_player.data.move_speed * 1.8
			if _t >= TRIP:
				_phase = 2
				_t = 0.0
		2:
			var who := _patient()
			pet.goal = who.global_position
			pet.speed = pet.owner_player.data.move_speed * 2.2
			if pet.global_position.distance_to(who.global_position) < 1.0 or _t >= TRIP * 2.0:
				_feed(who)
				_phase = 0
				pet.cooldown = pet.data.attack_every

## El que más lo necesita: el de menos vida (en proporción) de los que están en pie cerca.
func _patient() -> Player:
	var best := pet.owner_player
	var low := 2.0
	for p in pet.world.players:
		if p.health <= 0.0 or p.global_position.distance_to(pet.owner_player.global_position) > SHARE: continue
		var r := p.health / p.data.max_health
		if r < low:
			low = r
			best = p
	return best

func _feed(p: Player) -> void:
	var k := pet.data.bonus_at(pet.level())
	p.health = minf(p.data.max_health, p.health + p.data.max_health * k)
	p.sanity = minf(p.data.max_sanity, p.sanity + p.data.max_sanity * k)
	pet.act()
	pet.hits += 1
	pet.popup("¡Pescado!", Color(0.55, 1.0, 0.6))

## Chillido: la primera vez que ve cada élite cerca, la marca con un anillo.
func _watch(delta: float) -> void:
	_scan -= delta
	if _scan > 0.0 or pet.world == null: return
	_scan = 0.5
	for e in pet.world.enemies_in_circle(pet.owner_player.global_position, SPOT):
		if not ("data" in e) or not e.data.elite: continue
		var id := e.get_instance_id()
		if _seen.has(id): continue
		_seen[id] = true
		pet.popup("¡Kiii!", Color(1.0, 0.95, 0.8))
		var tg := Telegraph.new().setup(1.4, 1.5, Color(1.0, 0.9, 0.3, 0.6), false)
		tg.position = Vector3(e.global_position.x, 0.0, e.global_position.z)
		pet.world.fx.add_child(tg)
