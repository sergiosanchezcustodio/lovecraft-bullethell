class_name WeaponSystem
extends Node
## Armas de un jugador: todas disparan solas cuando se recargan y tienen objetivo.

signal fired(weapon: Weapon)

class Weapon:
	var data: WeaponData
	var level := 1
	var timer := 0.0
	func _init(p_data: WeaponData) -> void:
		data = p_data
	func stat(n: String) -> float:
		return data.stat(n, level)

var player: Player
var world: CombatWorld
var weapons: Array[Weapon] = []
var _pending: Array[Dictionary] = []         ## proyectiles de ráfaga que salen con retardo
var _bonus_set := -1                         ## rasgos de daño del jugador, registrados en las balas
var _rings := {}                             ## Weapon -> OrbitRing (páginas del Necronomicón)
var _drones := {}                            ## Weapon -> MiGoDrones (orbes Mi-Go)
var _tethers := {}                           ## Weapon -> TetherBeam activo (Lente del Éter)

func setup(p_player: Player, p_world: CombatWorld) -> WeaponSystem:
	player = p_player
	world = p_world
	name = "Weapons"
	return self

func add_weapon(data: WeaponData) -> Weapon:
	var w := Weapon.new(data)
	w.timer = 0.3
	weapons.append(w)
	return w

func remove_weapon(id: StringName) -> void:
	for w in weapons.duplicate():
		if w.data.id != id: continue
		weapons.erase(w)
		for d: Dictionary in [_rings, _drones, _tethers]:
			if d.has(w):
				if is_instance_valid(d[w]): (d[w] as Node).queue_free()
				d.erase(w)
	_pending = _pending.filter(func(p: Dictionary) -> bool: return (p.w as Weapon).data.id != id)

func get_weapon(id: StringName) -> Weapon:
	for w in weapons:
		if w.data.id == id: return w
	return null

func _physics_process(delta: float) -> void:
	if player.health <= 0.0: return
	for i in range(_pending.size() - 1, -1, -1):
		var p := _pending[i]
		p.t -= delta
		if p.t <= 0.0:
			_spawn_bullet(p.w, p.dir, p.get("k", 1.0))
			_pending.remove_at(i)
	for w in weapons:
		w.timer -= delta
		if w.timer > 0.0: continue
		if not _fire(w): continue                # el machete espera a tener a alguien cerca
		w.timer = w.stat("cooldown")

## Elige objetivo según el arma y dispara. Sin nadie a tiro, dispara igualmente hacia
## donde mira el personaje: el jugador siempre está disparando.
func _fire(w: Weapon) -> bool:
	var origin := player.global_position
	var rng := w.stat("range")
	var ahead := origin + player.motor.facing * rng * 0.55
	var target_pos := Vector3.ZERO
	match w.data.targeting:
		WeaponData.Targeting.NEAREST:
			var t := world.nearest_enemy(origin, rng)
			target_pos = t.global_position if t != null else ahead
		WeaponData.Targeting.DENSEST:
			var t := world.densest_enemy(origin, rng, maxf(w.stat("aoe_radius"), 1.0))
			target_pos = t.global_position if t != null else ahead
		WeaponData.Targeting.MOVE_DIR:
			target_pos = origin + player.motor.facing * rng
		WeaponData.Targeting.AROUND:
			target_pos = origin
		WeaponData.Targeting.STRONGEST:
			var t := world.strongest_enemy(origin, rng)
			target_pos = t.global_position if t != null else ahead
		WeaponData.Targeting.FRONT_BACK:
			target_pos = origin + player.motor.facing * rng
	var n := int(w.stat("count"))
	if w.data.delivery == WeaponData.Delivery.MELEE:
		return _slash(w)
	if w.data.delivery == WeaponData.Delivery.ORBIT:
		return _orbit(w)
	if w.data.delivery == WeaponData.Delivery.BEAM:
		return _beam(w, target_pos)
	if w.data.delivery == WeaponData.Delivery.WAVE:
		return _wave(w)
	if w.data.delivery == WeaponData.Delivery.FLAME:
		return _flame(w, target_pos)
	match w.data.delivery:
		WeaponData.Delivery.SIGIL: return _sigil(w)
		WeaponData.Delivery.PULSE: return _pulse(w)
		WeaponData.Delivery.TETHER: return _tether(w)
		WeaponData.Delivery.CLOUD: return _cloud(w, target_pos)
		WeaponData.Delivery.DRONE: return _drone(w)
		WeaponData.Delivery.STAB: return _stab(w)
		WeaponData.Delivery.CHAIN: return _chain(w, target_pos)
		WeaponData.Delivery.TURRET: return _turret(w)
		WeaponData.Delivery.BOOMERANG: return _boomerang(w, target_pos)
		WeaponData.Delivery.FISSURE: return _fissure(w, target_pos)
		WeaponData.Delivery.THRUST: return _thrust(w)
	if w.data.delivery == WeaponData.Delivery.THROWN:
		for k in n:
			var jitter := Vector3.ZERO
			if k > 0:
				var a := randf() * TAU
				jitter = Vector3(cos(a), 0, sin(a)) * maxf(w.stat("aoe_radius"), w.stat("zone_radius")) * randf_range(0.6, 1.1)
			_throw(w, target_pos + jitter)
		player.play_once("throw")
	else:
		var base := Vector3(target_pos.x - origin.x, 0, target_pos.z - origin.z).normalized()
		# rasgo de Malone: más daño cuanto más cerca está el objetivo
		var dmg_k := 1.0
		if player.data.close_bonus > 0.0:
			var dist := Vector2(target_pos.x - origin.x, target_pos.z - origin.z).length()
			dmg_k = 1.0 + player.data.close_bonus * clampf(1.0 - dist / maxf(rng, 0.1), 0.0, 1.0)
		var spread := deg_to_rad(w.stat("spread_deg"))
		var bases: Array[Vector3] = [base]
		if w.data.targeting == WeaponData.Targeting.FRONT_BACK: bases.append(-base)   # Lugers: delante y detrás
		for b in bases:
			for k in n:
				var off := 0.0 if n == 1 else lerpf(-spread * 0.5, spread * 0.5, k / float(n - 1))
				off += deg_to_rad(randf_range(-1.0, 1.0) * w.stat("jitter_deg"))       # errático
				var dir := b.rotated(Vector3.UP, off)
				var delay := w.stat("burst_delay") * k
				if delay > 0.0: _pending.append({"w": w, "dir": dir, "t": delay, "k": dmg_k})
				else: _spawn_bullet(w, dir, dmg_k)
		_pay_sanity(w)                           # balas arcanas (fuegos fatuos, Rayo de Yith)
	fired.emit(w)
	return true

func _spawn_bullet(w: Weapon, dir: Vector3, dmg_k: float = 1.0) -> void:
	var speed := w.stat("projectile_speed")
	var life := w.stat("range") / speed * 1.15
	if _bonus_set < 0 and not player.data.bonus_tags.is_empty():
		_bonus_set = world.bullets.register_bonus(player.data.bonus_tags)
	var style := BulletManager.Style.PLAYER
	var effect := BulletManager.Effect.NONE
	var effect_val := w.stat("stasis")
	var size := w.stat("projectile_size")
	if w.stat("crit_chance") > 0.0 and randf() < w.stat("crit_chance"):   # crítico (Springfield)
		dmg_k *= w.stat("crit_mult")
		size *= 1.5
	if w.stat("ally_time") > 0.0:                                         # suero de West
		effect = BulletManager.Effect.INJECT
		effect_val = w.stat("ally_time")
	if w.stat("homing") > 0.0: style = BulletManager.Style.WISP
	if w.stat("stasis") > 0.0:
		style = BulletManager.Style.YITH
		effect = BulletManager.Effect.STASIS
	world.bullets.spawn(BulletManager.Team.PLAYER, style,
		player.global_position + dir * 0.4, dir * speed, w.stat("projectile_radius"),
		size, Damage.new(dmg(w) * dmg_k, 0.0), life, int(w.stat("pierce")),
		w.stat("knockback"), _bonus_set, int(w.stat("split_count")), w.stat("homing"), effect, effect_val)

## Daño de un arma con los atributos del personaje (D-27).
func dmg(w: Weapon) -> float:
	var melee := w.data.delivery in [WeaponData.Delivery.MELEE, WeaponData.Delivery.THRUST]
	var k := player.data.melee_mult if melee else 1.0   # rasgo de Johansen
	return w.stat("damage") * player.damage_mult(w.data.category) * k

## Coste de cordura de las armas arcanas (GDD 5.2), con el rasgo del personaje.
func _pay_sanity(w: Weapon) -> void:
	var cost := w.stat("sanity_cost") * player.data.arcane_cost_mult
	if cost > 0.0: player.sanity = maxf(0.0, player.sanity - cost)

## Páginas que orbitan (Necronomicón): se activan durante `duration` s y luego se recargan.
## Mientras están activas, el arma no vuelve a disparar.
func _orbit(w: Weapon) -> bool:
	var ring := _rings.get(w) as OrbitRing
	if ring == null:
		ring = OrbitRing.new().setup(player, world)
		_rings[w] = ring
		world.fx.add_child(ring)
	if ring.active: return false
	_pay_sanity(w)
	ring.start(int(w.stat("count")), w.stat("aoe_radius"), w.stat("projectile_speed"), w.stat("projectile_radius"),
		dmg(w), w.stat("duration"), w.stat("hit_interval"), w.stat("knockback"), player.data.bonus_tags)
	fired.emit(w)
	return true

## Onda de expulsión (fórmula de Iwanicki): se expande desde el personaje, empuja y aturde.
func _wave(w: Weapon) -> bool:
	if world.enemies_in_circle(player.global_position, w.stat("aoe_radius")).is_empty(): return false
	_pay_sanity(w)
	var wave := Shockwave.new().setup(player, world, w.stat("aoe_radius"), w.stat("duration"), dmg(w),
		w.stat("knockback"), w.stat("stun"), player.data.bonus_tags)
	world.fx.add_child(wave)
	fired.emit(w)
	return true

## Rayo recto (Trapezoedro): daña a todo lo que atraviesa hasta su alcance.
func _beam(w: Weapon, target_pos: Vector3) -> bool:
	var origin := player.global_position
	var dir := Vector3(target_pos.x - origin.x, 0, target_pos.z - origin.z)
	if dir.length() < 0.01: dir = player.motor.facing
	dir = dir.normalized()
	var length := w.stat("range")
	var half := w.stat("projectile_radius")
	var mid := origin + dir * length * 0.5
	for t in world.enemies_in_circle(mid, length * 0.5 + half):
		var rel := Vector2(t.global_position.x - origin.x, t.global_position.z - origin.z)
		var along := rel.dot(Vector2(dir.x, dir.z))
		if along < 0.0 or along > length: continue
		var across := absf(rel.cross(Vector2(dir.x, dir.z)))
		if across > half + float(t.hit_radius): continue
		var d := Damage.new(dmg(w), 0.0)
		d.knockback = dir * w.stat("knockback")
		d.bonus = player.data.bonus_tags
		t.take_damage(d)
	_pay_sanity(w)
	var fx := Beam.new()
	fx.setup(origin + Vector3(0, 1.0, 0), dir, length, half, w.stat("duration"))
	world.fx.add_child(fx)
	fired.emit(w)
	return true

## Tajo circular (machete): daña y empuja hacia fuera a todo lo que haya en el radio.
## Solo golpea si hay alguien dentro: sin enemigos cerca, espera.
func _slash(w: Weapon) -> bool:
	var origin := player.global_position
	var r := w.stat("aoe_radius")
	var targets := world.enemies_in_circle(origin, r)
	if targets.is_empty(): return false
	for t in targets:
		var d := Damage.new(dmg(w), 0.0)
		var away := t.global_position - origin
		d.knockback = Vector3(away.x, 0, away.z).normalized() * w.stat("knockback")
		d.bonus = player.data.bonus_tags
		t.take_damage(d)
	var fx := Slash.new()
	fx.radius = r
	fx.position = Vector3(origin.x, 0.0, origin.z)
	world.fx.add_child(fx)
	player.play_once("throw")                    # el brazo acompaña el tajo
	fired.emit(w)
	return true

## Signo Arcano: se traza bajo el personaje y se queda ahí. Uno a la vez por arma: se
## vuelve a trazar al recargarse.
func _sigil(w: Weapon) -> bool:
	_pay_sanity(w)
	var s := Sigil.new().setup(world, player.global_position, w.stat("aoe_radius"), w.stat("duration"), dmg(w),
		w.stat("hit_interval"), w.stat("knockback"), w.stat("bullet_slow"), player.data.bonus_tags)
	world.fx.add_child(s)
	fired.emit(w)
	return true

## Resonador de Tillinghast: onda que deshace balas enemigas. Solo vibra si hay balas o
## enemigos a su alcance.
func _pulse(w: Weapon) -> bool:
	var origin := player.global_position
	var r := w.stat("aoe_radius")
	if world.bullets.count_enemy_bullets(origin, r) == 0 and world.enemies_in_circle(origin, r).is_empty(): return false
	_pay_sanity(w)
	var wave := Shockwave.new().setup(player, world, r, w.stat("duration"), dmg(w), w.stat("knockback"),
		w.stat("stun"), player.data.bonus_tags)
	wave.clears = true
	wave.color = Color(0.45, 0.95, 0.85, 0.9)
	world.fx.add_child(wave)
	fired.emit(w)
	return true

## Lente del Éter: rayo sostenido. Espera a tener a alguien a tiro y no se solapa consigo.
func _tether(w: Weapon) -> bool:
	if is_instance_valid(_tethers.get(w)): return false
	if world.nearest_enemy(player.global_position, w.stat("range")) == null: return false
	_pay_sanity(w)
	var b := TetherBeam.new().setup(player, world, dmg(w), w.stat("hit_interval"), w.stat("ramp"),
		w.stat("ramp_max"), w.stat("range"), w.stat("duration"), player.data.bonus_tags)
	_tethers[w] = b
	world.fx.add_child(b)
	fired.emit(w)
	return true

## Polvo de Ibn-Ghazi: nube que se queda donde está el grupo más denso.
func _cloud(w: Weapon, target_pos: Vector3) -> bool:
	_pay_sanity(w)
	var z := DamageZone.new().setup(world, w.data.zone, target_pos, w.stat("zone_radius"), w.stat("zone_time"),
		w.stat("zone_dps") * player.damage_mult(w.data.category), w.stat("vulnerable"), player.data.bonus_tags)
	z.slow_k = w.stat("slow_factor")
	z.weak_k = w.stat("weaken")
	world.fx.add_child(z)
	player.play_once("throw")
	fired.emit(w)
	return true

## Orbes Mi-Go: se activan durante `duration` s y luego se recargan, como las páginas.
func _drone(w: Weapon) -> bool:
	var d := _drones.get(w) as MiGoDrones
	if d == null:
		d = MiGoDrones.new().setup(player, world)
		_drones[w] = d
		world.fx.add_child(d)
	if d.active: return false
	_pay_sanity(w)
	if _bonus_set < 0 and not player.data.bonus_tags.is_empty():
		_bonus_set = world.bullets.register_bonus(player.data.bonus_tags)
	d.start(int(w.stat("count")), w.stat("aoe_radius"), dmg(w), w.stat("hit_interval"), w.stat("range"),
		w.stat("projectile_speed"), w.stat("duration"), _bonus_set)
	fired.emit(w)
	return true

## Daga ritual: puñalada al más cercano a menos de `range`, que queda maldito. Sin nadie
## cerca, espera.
func _stab(w: Weapon) -> bool:
	var origin := player.global_position
	var t := world.nearest_enemy(origin, w.stat("range"))
	if t == null: return false
	_pay_sanity(w)
	var d := Damage.new(dmg(w), 0.0)
	var away := t.global_position - origin
	d.knockback = Vector3(away.x, 0, away.z).normalized() * w.stat("knockback")
	d.bonus = player.data.bonus_tags
	t.take_damage(d)
	if t.is_alive() and t.has_method("curse"):
		t.curse(w.stat("curse"), w.stat("curse_dps") * player.damage_mult(w.data.category), int(w.stat("curse_spread")),
			player.data.bonus_tags)
	world.fx.add_child(Stab.new().setup(origin, t.global_position))
	player.play_once("throw")
	fired.emit(w)
	return true

## Bobina Tesla: rayo al más cercano que salta a los siguientes (a menos de aoe_radius, sin
## repetir) hasta `count` objetivos; cada salto hace un 15 % menos.
func _chain(w: Weapon, target_pos: Vector3) -> bool:
	var origin := player.global_position
	var first := world.nearest_enemy(origin, w.stat("range"))
	if first == null: return false
	var points: Array[Vector3] = [origin]
	var done := {}
	var cur: Node3D = first
	var k := 1.0
	for i in int(w.stat("count")):
		done[cur.get_instance_id()] = true
		points.append(cur.global_position)
		var d := Damage.new(dmg(w) * k, 0.0)
		d.bonus = player.data.bonus_tags
		cur.take_damage(d)
		if cur.has_method("stun") and cur.is_alive(): cur.stun(w.stat("stun"))
		k *= 0.85
		var next: Node3D = null
		var best := INF
		for e in world.enemies_in_circle(points[points.size() - 1], w.stat("aoe_radius")):
			if done.has(e.get_instance_id()) or not e.is_alive(): continue
			var dd := e.global_position.distance_squared_to(points[points.size() - 1])
			if dd < best:
				best = dd
				next = e
		if next == null: break
		cur = next
	world.fx.add_child(ChainBolt.new().setup(points))
	fired.emit(w)
	return true

## Ametralladora Lewis: la deja en el suelo, donde está el personaje.
func _turret(w: Weapon) -> bool:
	if _bonus_set < 0 and not player.data.bonus_tags.is_empty():
		_bonus_set = world.bullets.register_bonus(player.data.bonus_tags)
	var t := Turret.new().setup(world, player.global_position + player.motor.facing * 0.8, w.stat("duration"),
		w.stat("hit_interval"), dmg(w), w.stat("range"), w.stat("projectile_speed"), _bonus_set)
	world.fx.add_child(t)
	player.play_once("throw")
	fired.emit(w)
	return true

## Bumerán: `count` a la vez, abiertos en abanico hacia el objetivo.
func _boomerang(w: Weapon, target_pos: Vector3) -> bool:
	var origin := player.global_position
	var base := Vector3(target_pos.x - origin.x, 0, target_pos.z - origin.z)
	if base.length() < 0.01: base = player.motor.facing
	base = base.normalized()
	var n := int(w.stat("count"))
	var spread := deg_to_rad(w.stat("spread_deg"))
	for k in n:
		var off := 0.0 if n == 1 else lerpf(-spread * 0.5, spread * 0.5, k / float(n - 1))
		world.fx.add_child(Boomerang.new().setup(player, world, base.rotated(Vector3.UP, off), w.stat("range"),
			w.stat("projectile_speed"), w.stat("projectile_radius"), dmg(w), w.stat("knockback"), player.data.bonus_tags))
	player.play_once("throw")
	fired.emit(w)
	return true

## Martillo de geólogo: grieta en línea hacia el objetivo (o hacia donde mira).
func _fissure(w: Weapon, target_pos: Vector3) -> bool:
	var origin := player.global_position
	var dir := Vector3(target_pos.x - origin.x, 0, target_pos.z - origin.z)
	if dir.length() < 0.01: dir = player.motor.facing
	world.fx.add_child(Fissure.new().setup(world, origin + dir.normalized() * 0.5, dir, w.stat("range"),
		w.stat("projectile_speed"), w.stat("aoe_radius"), dmg(w), w.stat("stun"), player.data.bonus_tags))
	player.play_once("throw")
	fired.emit(w)
	return true

## Bastón estoque: estocada en línea hacia el más cercano; daña todo lo que haya en ella.
## Sin nadie a su alcance, espera.
func _thrust(w: Weapon) -> bool:
	var origin := player.global_position
	var length := w.stat("range")
	var first := world.nearest_enemy(origin, length)
	if first == null: return false
	var dir := Vector3(first.global_position.x - origin.x, 0, first.global_position.z - origin.z).normalized()
	var half := w.stat("projectile_radius")
	for t in world.enemies_in_circle(origin + dir * length * 0.5, length * 0.5 + half):
		var rel := Vector2(t.global_position.x - origin.x, t.global_position.z - origin.z)
		var along := rel.dot(Vector2(dir.x, dir.z))
		if along < 0.0 or along > length: continue
		if absf(rel.cross(Vector2(dir.x, dir.z))) > half + float(t.hit_radius): continue
		var d := Damage.new(dmg(w), 0.0)
		d.knockback = dir * w.stat("knockback")
		d.bonus = player.data.bonus_tags
		t.take_damage(d)
	var fx := Stab.new().setup(origin, origin + dir * length)
	fx.color = Color(0.85, 0.88, 0.92, 0.95)
	fx.blade = 1.1
	world.fx.add_child(fx)
	player.play_once("throw")
	fired.emit(w)
	return true

func _throw(w: Weapon, target: Vector3) -> void:
	var e := ThrownExplosive.new()
	e.setup(world, player.global_position + Vector3(0, 1.4, 0), Vector3(target.x, 0, target.z),
		w.stat("flight_time"), w.stat("fuse"), w.stat("aoe_radius") * player.data.explosion_radius_mult, dmg(w), player.color)
	var z := {}
	if w.data.zone != WeaponData.Zone.NONE:
		z = {"kind": w.data.zone, "radius": w.stat("zone_radius"), "time": w.stat("zone_time"),
			"dps": w.stat("zone_dps") * player.damage_mult(w.data.category), "vulnerable": w.stat("vulnerable")}
	e.configure(w.data.look, w.stat("arc_height"), z, w.stat("lure"), player.data.bonus_tags)
	e.net = w.stat("root")                                                # red de pesca
	world.fx.add_child(e)

## Lanzallamas: chorro en cono hacia el objetivo que deja fuego en el suelo.
func _flame(w: Weapon, target_pos: Vector3) -> bool:
	var origin := player.global_position
	var dir := Vector3(target_pos.x - origin.x, 0, target_pos.z - origin.z)
	if dir.length() < 0.01: dir = player.motor.facing
	var k := player.damage_mult(w.data.category)
	var jet := FlameJet.new().setup(player, world, dir, w.stat("range"), w.stat("spread_deg"), dmg(w),
		w.stat("duration"), w.stat("zone_radius"), w.stat("zone_time"), w.stat("zone_dps") * k, player.data.bonus_tags)
	world.fx.add_child(jet)
	fired.emit(w)
	return true
