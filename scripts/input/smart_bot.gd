class_name SmartBot
extends BotInput
## Jugador automático que juega como una persona razonable (15-10-2026), para medir el equilibrio
## con simulaciones (`bot=smart`; en cooperativo, `bots=N` con `bot=smart` también los usa).
## A diferencia de "circle", que solo da vueltas y no esquiva nada:
## - se aparta de los enemigos cercanos (más de las élites y los únicos) y no se deja acorralar
##   contra el decorado ni el borde (mira por dónde hay hueco);
## - se quita de la trayectoria de las balas enemigas que le van a dar y sale de los avisos del
##   suelo y de las zonas que dañan;
## - esquiva (el botón) cuando algo le va a dar en el próximo instante;
## - si no hay peligro cerca, va a por gemas, baúles, recompensas y rompibles, y si no, ronda el
##   centro para no quedarse en una esquina;
## - en cooperativo no se aleja más de `LEASH` m del líder y acude a reanimar.
## Su habilidad se gradúa con `skill` (0..1): con menos, reacciona tarde y a veces no esquiva.

const LEASH := 7.0
const SENSE := 7.5                ## m a los que tiene en cuenta a los enemigos
const COMFORT := 3.2              ## distancia que intenta guardar (los pingüinos embisten desde 3,5 m)
var skill := 0.8
var _dodge_now := false
var _wander := Vector3.ZERO
var _wander_t := 0.0
var _rng := RandomNumberGenerator.new()
var _react := 0.0                 ## s hasta la siguiente lectura (reflejos)
var _move := Vector2.ZERO
var _last_dir := Vector3.ZERO

func _init(p_skill: float = 0.8) -> void:
	super._init("smart", 0.0)
	skill = p_skill
	_rng.seed = 1234

func _read_move(delta: float) -> Vector2:
	if body == null or not is_instance_valid(body): return Vector2.ZERO
	_react -= delta
	if _react <= 0.0:                                  # piensa cada poco (más lento con menos habilidad)
		_react = lerpf(0.25, 0.06, skill)
		_move = _think()
	return _move

func _read_action(action: StringName) -> bool:
	if action == InputBindings.DODGE and _dodge_now:
		_dodge_now = false
		return true
	return false

func _think() -> Vector2:
	var p: Player = body as Player
	var w: CombatWorld = p.world
	if w == null: return Vector2.ZERO
	var me := p.global_position
	me.y = 0.0
	var speed: float = p.data.move_speed
	# alcance de sus armas: con armas cortas (machete, escopeta, páginas) se arrima más
	var reach := 0.0
	for wpn in p.weapons.weapons: reach = maxf(reach, float(wpn.data.range))
	var comfort := COMFORT if reach >= 6.0 else clampf(reach * 0.45, 1.0, COMFORT)
	# lo que hay alrededor: enemigos (posición, velocidad, peso), balas que vienen y avisos
	var foes: Array = []
	var near_hit := false
	for e: Node3D in w.enemies:
		if not is_instance_valid(e) or not e.is_alive(): continue
		var ep := e.global_position
		ep.y = 0.0
		var dist := ep.distance_to(me)
		if dist > 11.0: continue
		var big := 1.0
		if "data" in e and e.data != null:
			if e.data.unique: big = 3.0
			elif e.data.elite: big = 2.0
		var r: float = float(e.hit_radius) if "hit_radius" in e else 0.5
		var v: Vector3 = e.velocity if "velocity" in e else Vector3.ZERO
		v.y = 0.0
		foes.append([ep, v, big, r])
		if dist - r < 0.75: near_hit = true
	var shots: Array = []
	var b := w.bullets
	for i in b.count:
		if b._team[i] != BulletManager.Team.ENEMY: continue
		var bp: Vector3 = b._pos[i]
		bp.y = 0.0
		if bp.distance_to(me) > 7.0: continue
		var bv: Vector3 = b._vel[i]
		bv.y = 0.0
		shots.append([bp, bv, float(b._radius[i]) + 0.4])
	var zones: Array = []
	for n: Node in body.get_tree().get_nodes_in_group(&"enemy_warnings"):
		var c := n as Node3D
		if c == null or not is_instance_valid(c): continue
		var rr: float = float(c.get_meta("warn_r")) if c.has_meta("warn_r") else float(c.get("radius"))
		var cp := c.global_position
		cp.y = 0.0
		if cp.distance_to(me) < rr + 6.0: zones.append([cp, rr + 0.5])
	# objetivo: gema o recompensa más cercana, compañero derribado, el líder si se aleja
	var goal := Vector3.INF
	var goal_w := 0.0
	var down := _downed_mate()
	if down != null:
		goal = down.global_position; goal_w = 3.0
	elif leader != null and is_instance_valid(leader) and leader != body and leader.global_position.distance_to(me) > LEASH:
		goal = leader.global_position; goal_w = 2.5
	else:
		goal = _pickup_target(me)
		goal_w = float(OS.get_cmdline_user_args().has("gems_lo=true")) * -1.5 + 3.0
		if reach < 6.0 and not hp_low_now(p):              # armas cortas: hacia el enemigo más cercano
			var ne: Node3D = w.nearest_enemy(me, 9.0)
			if ne != null and (goal == Vector3.INF or ne.global_position.distance_to(me) < goal.distance_to(me) + 3.0):
				var to := ne.global_position - me
				to.y = 0.0
				goal = ne.global_position - to.normalized() * reach * 0.6
				goal_w = 2.0
		if goal == Vector3.INF:
			goal = _wander_dir(me, w) * 10.0 + me
			goal_w = 0.5
	goal.y = 0.0
	# plan: 16 direcciones más quedarse quieto, cada una a 0,4 / 0,8 / 1,2 s
	var best := Vector3.ZERO
	var best_s := -INF
	var hp_low := p.health < p.data.max_health * 0.4
	var center := w.bounds.get_center()
	var half := minf(w.bounds.size.x, w.bounds.size.y) * 0.5 - 6.0
	for k in 17:
		var d := Vector3.ZERO if k == 16 else Vector3(cos(TAU * k / 16.0), 0, sin(TAU * k / 16.0))
		var s := 0.0
		for step in [0.35, 0.75, 1.2]:
			var q: Vector3 = me + d * speed * float(step)
			if w.obstacles != null and w.obstacles.is_blocked(Vector2(q.x, q.z), 0.35):
				s -= 40.0
				break
			if q.x < w.bounds.position.x + 1.0 or q.x > w.bounds.end.x - 1.0 or q.z < w.bounds.position.y + 1.0 or q.z > w.bounds.end.y - 1.0:
				s -= 40.0
				break
			var wt := 1.4 - float(step) * 0.5                    # lo cercano en el tiempo pesa más
			for f in foes:
				var fp: Vector3 = f[0] + f[1] * float(step)
				var gap: float = maxf(fp.distance_to(q) - float(f[3]) - 0.35, 0.05)
				s -= wt * float(f[2]) * (1.0 / (gap * gap) + (3.0 / gap if gap < 1.0 else 0.0) + maxf(0.0, comfort - gap) * 1.2)
			for sh in shots:
				var sp: Vector3 = sh[0] + sh[1] * float(step)
				var gap2: float = sp.distance_to(q) - float(sh[2])
				if gap2 < 0.6: s -= wt * 25.0 * (0.6 - gap2 + 0.2)
			for z in zones:
				if (z[0] as Vector3).distance_to(q) < float(z[1]): s -= wt * 30.0
			# no acorralarse: espacio libre alrededor del punto y lejos de los bordes (se ronda el centro)
			if w.obstacles != null and w.obstacles.has_mask():
				s += clampf(w.obstacles.distance(Vector2(q.x, q.z)), 0.0, 4.0) * 1.2 * wt
			var off := Vector2(q.x - center.x, q.z - center.y)
			s -= maxf(0.0, off.length() - half * 0.45) * 0.9 * wt
			# rodeado: enemigos cerca en muchos lados a la vez
			var sides := 0
			var seen := {}
			for f in foes:
				var dv: Vector3 = (f[0] as Vector3) - q
				if dv.length() < 4.5:
					var sec := int(floor((atan2(dv.z, dv.x) + PI) / (TAU / 8.0))) % 8
					if not seen.has(sec):
						seen[sec] = true
						sides += 1
			if sides >= 4: s -= float(sides - 3) * 6.0 * wt
		if goal != Vector3.INF:
			var g0 := me.distance_to(goal)
			var g1 := (me + d * speed * 0.75).distance_to(goal)
			s += (g0 - g1) * goal_w * (0.4 if hp_low else 1.0)
		if k < 16: s += d.dot(_last_dir) * 0.8                       # sin cambiar de rumbo a cada momento
		s += _rng.randf() * lerpf(3.0, 0.2, skill)                      # menos habilidad: decisiones peores
		if s > best_s:
			best_s = s
			best = d
	_last_dir = best
	# esquiva si va a recibir un golpe en el siguiente instante
	if p.motor.can_dodge() and _rng.randf() < lerpf(0.25, 0.9, skill):
		var hit := near_hit
		for sh in shots:
			var sp: Vector3 = sh[0] + sh[1] * 0.25
			if sp.distance_to(me) < float(sh[2]) + 0.1: hit = true
		if hit and best_s < -15.0: _dodge_now = true
	if best == Vector3.ZERO: return Vector2.ZERO
	var right := PlayerMotor.screen_to_world(Vector2(1, 0))
	var fwd := PlayerMotor.screen_to_world(Vector2(0, 1))
	return Vector2(best.dot(right), best.dot(fwd)).normalized()

func hp_low_now(p: Player) -> bool:
	return p.health < p.data.max_health * 0.4

func _wall_push(w: CombatWorld, me: Vector3) -> Vector3:
	var push := Vector3.ZERO
	var b := w.bounds
	var m := 4.0
	if me.x - b.position.x < m: push.x += (m - (me.x - b.position.x)) / m
	if b.end.x - me.x < m: push.x -= (m - (b.end.x - me.x)) / m
	if me.z - b.position.y < m: push.z += (m - (me.z - b.position.y)) / m
	if b.end.y - me.z < m: push.z -= (m - (b.end.y - me.z)) / m
	if w.obstacles != null and w.obstacles.has_mask():
		for k in 8:
			var a := TAU * k / 8.0
			var d := Vector3(cos(a), 0, sin(a))
			for r in [0.8, 1.6]:
				var q: Vector3 = me + d * r
				if w.obstacles.is_blocked(Vector2(q.x, q.z), 0.3):
					push -= d * (1.0 / r)
					break
	return push * 0.6

func _pickup_target(me: Vector3) -> Vector3:
	var best := Vector3.INF
	var best_d := 12.0
	var g = body.get_tree().current_scene.get("gems")
	if g != null:
		for i in g.count:
			var q: Vector3 = g._pos[i]
			var dd := Vector2(q.x - me.x, q.z - me.z).length()
			if dd < best_d:
				best_d = dd
				best = q
	for grp in [&"chests", &"pickups", &"breakable"]:
		for n: Node in body.get_tree().get_nodes_in_group(grp):
			var c := n as Node3D
			if c == null or not is_instance_valid(c): continue
			if grp == &"chests" and c.is_open: continue
			var dd := Vector2(c.global_position.x - me.x, c.global_position.z - me.z).length()
			if dd < best_d * (1.6 if grp != &"breakable" else 0.8):
				best_d = dd
				best = c.global_position
	return best

func _wander_dir(me: Vector3, w: CombatWorld) -> Vector3:
	_wander_t -= 0.1
	if _wander_t <= 0.0 or _wander == Vector3.ZERO:
		_wander_t = _rng.randf_range(2.0, 4.0)
		var c := Vector3(w.bounds.get_center().x, 0, w.bounds.get_center().y)
		var a := _rng.randf() * TAU
		var spot := c + Vector3(cos(a), 0, sin(a)) * minf(w.bounds.size.x, w.bounds.size.y) * 0.25
		_wander = spot
	var to := _wander - me
	to.y = 0.0
	if to.length() < 1.0: _wander_t = 0.0
	return to.normalized() * 0.6

## Elige mejora como un jugador con criterio: subir las armas que lleva, completar hasta tres
## armas pronto, luego objetos; con algo de azar para que las partidas varíen.
static func pick(options: Array, p: Player, rng: RandomNumberGenerator) -> PlayerProgress.Option:
	var best: PlayerProgress.Option = options[0]
	var best_s := -INF
	for o: PlayerProgress.Option in options:
		var s := rng.randf() * 2.5
		match o.kind:
			PlayerProgress.Option.Kind.WEAPON_LEVEL: s += 10.0
			PlayerProgress.Option.Kind.NEW_WEAPON: s += 9.5 if p.weapons.weapons.size() < 3 else 4.0
			PlayerProgress.Option.Kind.PASSIVE: s += 7.0 if o.to_level > 1 else 5.5
		if s > best_s:
			best_s = s
			best = o
	return best

func device_name() -> String:
	return "bot (smart %.1f)" % skill
