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
			_spawn_bullet(p.w, p.dir)
			_pending.remove_at(i)
	for w in weapons:
		w.timer -= delta
		if w.timer > 0.0: continue
		w.timer = w.stat("cooldown") if _fire(w) else 0.1     # sin objetivo: reintenta pronto

## Elige objetivo según el arma y dispara. Devuelve false si no había a quién.
func _fire(w: Weapon) -> bool:
	var origin := player.global_position
	var rng := w.stat("range")
	var target_pos := Vector3.ZERO
	match w.data.targeting:
		WeaponData.Targeting.NEAREST:
			var t := world.nearest_enemy(origin, rng)
			if t == null: return false
			target_pos = t.global_position
		WeaponData.Targeting.DENSEST:
			var t := world.densest_enemy(origin, rng, maxf(w.stat("aoe_radius"), 1.0))
			if t == null: return false
			target_pos = t.global_position
		WeaponData.Targeting.MOVE_DIR:
			target_pos = origin + player.motor.facing * rng
		WeaponData.Targeting.AROUND:
			target_pos = origin
	var n := int(w.stat("count"))
	if w.data.delivery == WeaponData.Delivery.THROWN:
		for k in n:
			var jitter := Vector3.ZERO
			if k > 0:
				var a := randf() * TAU
				jitter = Vector3(cos(a), 0, sin(a)) * w.stat("aoe_radius") * randf_range(0.6, 1.1)
			_throw(w, target_pos + jitter)
		player.play_once("throw")
	else:
		var base := Vector3(target_pos.x - origin.x, 0, target_pos.z - origin.z).normalized()
		var spread := deg_to_rad(w.stat("spread_deg"))
		for k in n:
			var off := 0.0 if n == 1 else lerpf(-spread * 0.5, spread * 0.5, k / float(n - 1))
			var dir := base.rotated(Vector3.UP, off)
			var delay := w.stat("burst_delay") * k
			if delay > 0.0: _pending.append({"w": w, "dir": dir, "t": delay})
			else: _spawn_bullet(w, dir)
	fired.emit(w)
	return true

func _spawn_bullet(w: Weapon, dir: Vector3) -> void:
	var speed := w.stat("projectile_speed")
	var life := w.stat("range") / speed * 1.15
	world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.PLAYER,
		player.global_position + dir * 0.4, dir * speed, w.stat("projectile_radius"),
		w.stat("projectile_size"), Damage.new(w.stat("damage"), 0.0), life, int(w.stat("pierce")))

func _throw(w: Weapon, target: Vector3) -> void:
	var e := ThrownExplosive.new()
	e.setup(world, player.global_position + Vector3(0, 1.4, 0), Vector3(target.x, 0, target.z),
		w.stat("flight_time"), w.stat("fuse"), w.stat("aoe_radius"), w.stat("damage"), player.color)
	world.fx.add_child(e)
