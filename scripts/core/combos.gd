class_name Combos
extends Node
## Combinaciones en cooperativo (hito 13.7, fase 13): cuando el ataque de un jugador toca lo
## que dejó el de otro, pasa algo nuevo. Ocho, con sus números en `data/combos.json`:
##   - Nube tóxica: fuego sobre el ácido de otro (o al revés) → una nube de gas que daña y
##     deja vulnerables.
##   - Polvo ardiente: fuego sobre el polvo de otro → estalla, daña y aturde.
##   - Deflagración: una explosión o un fuego sobre el gas de otro → una explosión mayor.
##   - Metralla: una explosión sobre el agua → esquirlas en todas direcciones (no necesita a otro).
##   - Tormenta de fuego: la onda empuja hacia fuera las llamas de otro, más grandes y fuertes.
##   - Miasma: la onda extiende el gas de otro.
##   - Prisma arcano: el rayo que cruza el signo de otro se abre en dos más.
##   - Charco conductor: la electricidad que toca a un enemigo en el ácido de otro salta a
##     todos los del charco.
## Quien las lleva cuelga del mundo (`attach`); las armas avisan (`zone`, `blast`, `wave`,
## `beam`, `chain`) y, sin él (pruebas, herramientas), no pasa nada. Su daño va con la etiqueta
## `combo`: no cuenta para ninguna arma (no suben ni evolucionan). La primera vez de cada una en
## el hueco sale un rótulo con su nombre (`SaveData.seen["combos"]`); `stats.combos` las cuenta.
## En red las decide el anfitrión: manda el suceso "combo" y el invitado repite lo que se ve
## (`replay`). `combos_solo=true` deja combinarse las de un mismo jugador (pruebas).

const DATA := "res://data/combos.json"
const TAG := &"combo"

var world: CombatWorld
var cfg := {}
var solo := false
var mirror := false                          ## invitado: solo repite lo que manda el anfitrión
var fired := {}                              ## id -> veces (tests)
var _last := {}                              ## id -> momento de la última (ms)
var _labeled := {}                           ## rótulos ya enseñados en esta partida (sin hueco)
var _log := false                            ## log=true: apunta cada una

static func attach(w: CombatWorld, p_mirror := false) -> Combos:
	var c := Combos.new()
	c.world = w
	c.mirror = p_mirror
	c.name = "Combos"
	var f := FileAccess.get_file_as_string(DATA)
	var d = JSON.parse_string(f) if f != "" else null
	c.cfg = d if d is Dictionary else {"combos": {}}
	var la := LaunchArgs.from_cmdline()
	c.solo = bool(c.cfg.get("solo", false)) or la.get_bool("combos_solo")
	c._log = la.get_bool("log")
	w.set_meta("combos", c)
	w.add_child(c)
	return c

static func of(w: CombatWorld) -> Combos:
	if w == null or not w.has_meta("combos"): return null
	var c: Variant = w.get_meta("combos")
	return c if is_instance_valid(c) and not (c as Combos).mirror else null

## Jugador (0..3) de una etiqueta «J2:molotov»; -1 si no es de un jugador.
static func owner_of(tag: StringName) -> int:
	var s := String(tag)
	if s.length() < 3 or s[0] != "J" or s[2] != ":": return -1
	return int(s[1]) - 1

func _p(id: String) -> Dictionary:
	return (cfg.get("combos", {}) as Dictionary).get(id, {})

## ¿Se combinan dos cosas de estos dueños?
func _pair(a: int, b: int) -> bool:
	return a >= 0 and b >= 0 and (a != b or solo)

func _ready_for(id: String) -> bool:
	var now := Time.get_ticks_msec()
	if now - int(_last.get(id, -100000)) < float(cfg.get("cooldown", 0.6)) * 1000.0: return false
	_last[id] = now
	return true

static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

# ---------------------------------------------------------------- avisos de las armas

## Nace una zona en el suelo (DamageZone._ready).
static func zone(z: DamageZone) -> void:
	var c := of(z.world)
	if c != null: c._on_zone(z)

## Explota algo de un jugador (ThrownExplosive).
static func blast(w: CombatWorld, at: Vector3, r: float, tag: StringName) -> void:
	var c := of(w)
	if c != null: c._on_blast(at, r, tag)

## Sale una onda (Shockwave).
static func wave(w: CombatWorld, at: Vector3, r: float, tag: StringName) -> void:
	var c := of(w)
	if c != null: c._on_wave(at, r, tag)

## Un rayo recto (WeaponSystem._beam).
static func beam(w: CombatWorld, origin: Vector3, dir: Vector3, length: float, half: float, dmg: float, tag: StringName) -> void:
	var c := of(w)
	if c != null: c._on_beam(origin, dir, length, half, dmg, tag)

## La electricidad toca a un enemigo (WeaponSystem._chain).
static func chain(w: CombatWorld, e: Node3D, dmg: float, tag: StringName) -> void:
	var c := of(w)
	if c != null: c._on_chain(e, dmg, tag)

# ---------------------------------------------------------------- las combinaciones

func _zones(kind: int) -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group(&"combo_zones"):
		var z := n as DamageZone
		if z != null and z.kind == kind and z._t < z.life and not z.has_meta("combo_used"): out.append(z)
	return out

static func _touch(a: Vector3, ra: float, b: Vector3, rb: float) -> bool:
	return _flat(a).distance_to(_flat(b)) < ra + rb

func _on_zone(z: DamageZone) -> void:
	var me := owner_of(z._wtag)
	if me < 0: return
	var pairs := {WeaponData.Zone.FIRE: [[WeaponData.Zone.ACID, "nube_toxica"], [WeaponData.Zone.DUST, "polvo_ardiente"],
		[WeaponData.Zone.GAS, "deflagracion"]], WeaponData.Zone.ACID: [[WeaponData.Zone.FIRE, "nube_toxica"]],
		WeaponData.Zone.DUST: [[WeaponData.Zone.FIRE, "polvo_ardiente"]], WeaponData.Zone.GAS: [[WeaponData.Zone.FIRE, "deflagracion"]]}
	for pr: Array in pairs.get(z.kind, []):
		for o: DamageZone in _zones(int(pr[0])):
			if o == z or not _pair(me, owner_of(o._wtag)) or not _touch(z.global_position, z.radius, o.global_position, o.radius): continue
			var id := String(pr[1])
			if not _ready_for(id): return
			# lo que arde o se consume es la otra (el gas, el polvo, el ácido)
			var gone: DamageZone = o if o.kind != WeaponData.Zone.FIRE else z
			match id:
				"nube_toxica": _toxic(z.global_position.lerp(o.global_position, 0.5), maxf(z.radius, o.radius))
				"polvo_ardiente": _burst(id, gone.global_position, gone.radius)
				"deflagracion": _burst(id, gone.global_position, gone.radius)
			_consume(gone)
			return

func _on_blast(at: Vector3, r: float, tag: StringName) -> void:
	var me := owner_of(tag)
	if me < 0: return
	for o: DamageZone in _zones(WeaponData.Zone.GAS):
		if _pair(me, owner_of(o._wtag)) and _touch(at, r, o.global_position, o.radius) and _ready_for("deflagracion"):
			_burst("deflagracion", o.global_position, o.radius)
			_consume(o)
			return
	var obs := world.obstacles
	if obs != null and obs.has_mask() and obs.water_at(Vector2(at.x, at.z)) > 0.2 and _ready_for("metralla"):
		_shrapnel(at)

func _on_wave(at: Vector3, r: float, tag: StringName) -> void:
	var me := owner_of(tag)
	if me < 0: return
	var hit := {"tormenta_fuego": [], "miasma": []}
	for kind_id: Array in [[WeaponData.Zone.FIRE, "tormenta_fuego"], [WeaponData.Zone.GAS, "miasma"]]:
		for o: DamageZone in _zones(int(kind_id[0])):
			if o.has_meta("combo_waved") or not _pair(me, owner_of(o._wtag)): continue
			if _flat(o.global_position).distance_to(_flat(at)) < r + o.radius * 0.5: hit[kind_id[1]].append(o)
	for id: String in hit:
		if (hit[id] as Array).is_empty() or not _ready_for(id): continue
		_spread(id, at, hit[id])
		_done(id, at, [r])

func _on_beam(origin: Vector3, dir: Vector3, length: float, half: float, dmg: float, tag: StringName) -> void:
	var me := owner_of(tag)
	if me < 0: return
	var d2 := Vector2(dir.x, dir.z).normalized()
	for n in get_tree().get_nodes_in_group(&"combo_sigils"):
		var s := n as Sigil
		if s == null or not _pair(me, owner_of(s._wtag)): continue
		var rel := Vector2(s.global_position.x - origin.x, s.global_position.z - origin.z)
		var along := rel.dot(d2)
		if along < 0.0 or along > length or absf(rel.cross(d2)) > s.radius: continue
		if not _ready_for("prisma"): return
		var p := _p("prisma")
		var at := _flat(origin) + Vector3(d2.x, 0, d2.y) * along
		var rest := (length - along) * float(p.get("length_k", 0.75)) + length * 0.25
		var dirs: Array = []
		for sgn in [-1.0, 1.0]:
			var nd := d2.rotated(deg_to_rad(float(p.get("angle", 35.0))) * sgn)
			_beam_hit(at, Vector3(nd.x, 0, nd.y), rest, half, dmg * float(p.get("damage_k", 0.7)))
			dirs.append_array([nd.x, nd.y])
		_split_fx(at, dirs, rest, half)
		_done("prisma", at, [dirs, rest, half])
		return

func _on_chain(e: Node3D, dmg: float, tag: StringName) -> void:
	var me := owner_of(tag)
	if me < 0 or not is_instance_valid(e): return
	for o: DamageZone in _zones(WeaponData.Zone.ACID):
		if not _pair(me, owner_of(o._wtag)) or _flat(e.global_position).distance_to(_flat(o.global_position)) > o.radius: continue
		if not _ready_for("charco_conductor"): return
		var p := _p("charco_conductor")
		var pts: Array[Vector3] = []
		for t in world.enemies_in_circle(o.global_position, o.radius):
			if t == e or not t.is_alive(): continue
			_hit(t, dmg * float(p.get("damage_k", 0.6)), Vector3.ZERO, float(p.get("stun", 0.5)))
			pts.append(t.global_position)
		_zap_fx(o.global_position, o.radius, pts)
		_done("charco_conductor", o.global_position, [o.radius])
		return

# ---------------------------------------------------------------- efectos (anfitrión)

func _hit(t: Node3D, amount: float, push: Vector3, stun := 0.0) -> void:
	var prev := Damage.ctx
	Damage.ctx = TAG
	var d := Damage.new(amount, 0.0)
	d.knockback = push
	t.take_damage(d)
	if stun > 0.0 and t.has_method("stun") and t.is_alive(): t.stun(stun)
	Damage.ctx = prev

func _consume(z: DamageZone) -> void:
	z.set_meta("combo_used", true)
	z.life = minf(z.life, z._t)

func _toxic(at: Vector3, r: float) -> void:
	var p := _p("nube_toxica")
	_gas_fx(at, r * float(p.get("radius_k", 1.4)), float(p.get("life", 5.0)), float(p.get("dps", 22.0)), float(p.get("vulnerable", 0.25)))
	_done("nube_toxica", at, [r])

func _gas_fx(at: Vector3, r: float, life: float, dps: float, vuln: float) -> void:
	var prev := Damage.ctx
	Damage.ctx = TAG
	var g := DamageZone.new().setup(world, WeaponData.Zone.GAS, at, r, life, dps, vuln)
	g.set_meta("combo_used", true)                    # no vuelve a combinarse
	world.fx.add_child(g)
	Damage.ctx = prev

## Estallido (polvo ardiente, deflagración): daño con caída hacia el borde y explosión.
func _burst(id: String, at: Vector3, r: float) -> void:
	var p := _p(id)
	var rr := r * float(p.get("radius_k", 1.3))
	for t in world.enemies_in_circle(at, rr):
		var k := lerpf(1.0, 0.5, clampf(_flat(t.global_position).distance_to(_flat(at)) / rr, 0.0, 1.0))
		_hit(t, float(p.get("damage", 30.0)) * k, (_flat(t.global_position) - _flat(at)).normalized() * 2.0, float(p.get("stun", 0.0)))
	_burst_fx(id, at, rr)
	_done(id, at, [rr])

func _burst_fx(id: String, at: Vector3, rr: float) -> void:
	var fx := Explosion.new()
	fx.radius = rr
	fx.position = _flat(at)
	world.fx.add_child(fx)
	if id == "polvo_ardiente": VoxelFx.ground_hit(world.fx, at, rr, Color(1.0, 0.82, 0.4), false)

func _shrapnel(at: Vector3) -> void:
	var p := _p("metralla")
	var n := int(p.get("count", 14))
	var seed := randi() % 1000
	_shrapnel_fx(at, n, float(p.get("damage", 9.0)), float(p.get("speed", 15.0)), float(p.get("life", 0.55)), seed)
	_done("metralla", at, [n, seed])

## Esquirlas: balas de jugador en abanico completo (en el invitado, solo se ven).
func _shrapnel_fx(at: Vector3, n: int, dmg: float, speed: float, life: float, seed: int) -> void:
	var prev := Damage.ctx
	Damage.ctx = TAG
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.12, 0.12)
		var v := Vector3(cos(a), 0, sin(a)) * speed * rng.randf_range(0.85, 1.15)
		world.bullets.spawn(BulletManager.Team.PLAYER, BulletManager.Style.SPARK, _flat(at) + Vector3(0, BulletManager.HEIGHT, 0),
			v, 0.18, 0.5, Damage.new(dmg, 0.0), life)
	WadeSplash.burst(world.fx, at, 1.4, Color(0.75, 0.9, 1.0), "auto", false)
	Damage.ctx = prev

## Onda sobre llamas o gas: se extienden hacia fuera, más grandes y más fuertes.
func _spread(id: String, at: Vector3, zones: Array) -> void:
	var p := _p(id)
	for o: DamageZone in zones:
		o.set_meta("combo_waved", true)
		o.radius *= float(p.get("radius_k", 1.3))
		o.dps *= float(p.get("dps_k", 1.3))
		o.life += float(p.get("life_add", 2.0))
		var away := _flat(o.global_position) - _flat(at)
		if p.has("drift") and away.length() > 0.05: o.drift += away.normalized() * float(p.drift)
		for c in o.get_children():                        # su mancha y sus partículas, al nuevo tamaño
			if c is MeshInstance3D: (c as MeshInstance3D).scale = Vector3(o.radius, 1.0, o.radius)

func _beam_hit(at: Vector3, dir: Vector3, length: float, half: float, dmg: float) -> void:
	var mid := at + dir * length * 0.5
	for t in world.enemies_in_circle(mid, length * 0.5 + half):
		var rel := Vector2(t.global_position.x - at.x, t.global_position.z - at.z)
		var along := rel.dot(Vector2(dir.x, dir.z))
		if along < 0.0 or along > length or absf(rel.cross(Vector2(dir.x, dir.z))) > half + float(t.hit_radius): continue
		_hit(t, dmg, dir * 1.0)

func _split_fx(at: Vector3, dirs: Array, length: float, half: float) -> void:
	for k in range(0, dirs.size(), 2):
		var fx := Beam.new()
		fx.setup(at + Vector3(0, 1.0, 0), Vector3(float(dirs[k]), 0, float(dirs[k + 1])), length, half, 0.35,
			Color(0.85, 0.62, 1.0, 0.95), Color(0.55, 0.25, 1.0, 0.45))
		world.fx.add_child(fx)

func _zap_fx(at: Vector3, r: float, pts: Array[Vector3]) -> void:
	VoxelFx.ground_hit(world.fx, at, r, Color(0.55, 0.95, 1.0), false)
	if pts.is_empty(): return
	var path: Array[Vector3] = [_flat(at) + Vector3(0, 0.6, 0)]
	path.append_array(pts)
	world.fx.add_child(ChainBolt.new().setup(path))

# ---------------------------------------------------------------- aviso, rótulo y red

func _done(id: String, at: Vector3, extra: Array) -> void:
	fired[id] = int(fired.get(id, 0)) + 1
	if _log: print("COMBO %s en (%.1f, %.1f) t=%.2f" % [id, at.x, at.z, Engine.get_physics_frames() / float(Engine.physics_ticks_per_second)])
	if Saves.current != null and not mirror: Saves.current.stats["combos"] = int(Saves.current.stats.get("combos", 0)) + 1
	_label(id, at)
	if world.on_net.is_valid(): world.on_net.call("combo", [id, at, extra])

## Invitado: lo que se ve de una combinación que ha decidido el anfitrión.
func replay(a: Array) -> void:
	if a.size() < 3: return
	var id := String(a[0])
	var at: Vector3 = a[1]
	var x: Array = a[2]
	match id:
		"nube_toxica": _gas_fx(at, float(x[0]) * float(_p(id).get("radius_k", 1.4)), float(_p(id).get("life", 5.0)), 0.0, 0.0)
		"polvo_ardiente", "deflagracion": _burst_fx(id, at, float(x[0]))
		"metralla": _shrapnel_fx(at, int(x[0]), 0.0, float(_p(id).get("speed", 15.0)), float(_p(id).get("life", 0.55)), int(x[1]))
		"tormenta_fuego", "miasma":                      # las llamas y el gas de esta copia, igual
			var kind := WeaponData.Zone.FIRE if id == "tormenta_fuego" else WeaponData.Zone.GAS
			_spread(id, at, _zones(kind).filter(func(o: DamageZone) -> bool:
				return not o.has_meta("combo_waved") and _flat(o.global_position).distance_to(_flat(at)) < float(x[0]) + o.radius * 0.5))
		"prisma": _split_fx(at, x[0], float(x[1]), float(x[2]))
		"charco_conductor": _zap_fx(at, float(x[0]), [])
	fired[id] = int(fired.get(id, 0)) + 1
	if _log: print("COMBO REPETIDA %s en (%.1f, %.1f)" % [id, at.x, at.z])
	if Saves.current != null: Saves.current.stats["combos"] = int(Saves.current.stats.get("combos", 0)) + 1
	_label(id, at)

## La primera vez de cada una en el hueco (sin hueco, en esta partida): su nombre encima.
func _label(id: String, at: Vector3) -> void:
	if Saves.current != null:
		if not Saves.current.mark_seen("combos", id): return
	elif _labeled.has(id): return
	_labeled[id] = true
	var p := _p(id)
	var l := _text3d(String(p.get("name", id)), 84, Color(1.0, 0.78, 0.36))
	l.position = _flat(at) + Vector3(0, 2.2, 0)
	var sub := _text3d(String(p.get("text", "")), 52, Color(0.95, 0.9, 0.8))
	sub.position.y = -0.7
	l.add_child(sub)
	world.fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", 3.0, 2.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(1.8)
	tw.parallel().tween_property(sub, "modulate:a", 0.0, 0.8).set_delay(1.8)
	tw.tween_callback(l.queue_free)
	Auto.sfx("page")

static func _text3d(text: String, size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = MenuKit.body_font(true)
	l.font_size = size
	l.outline_size = 22
	l.modulate = color
	l.outline_modulate = Color(0.05, 0.03, 0.02, 1.0)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.pixel_size = 0.009
	return l
