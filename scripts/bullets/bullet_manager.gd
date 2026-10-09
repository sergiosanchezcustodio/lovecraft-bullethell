class_name BulletManager
extends Node3D
## Todas las balas del juego, sin un nodo por bala: arrays compactos que se recorren
## en cada paso de física y dos MultiMesh que se rellenan de una vez por fotograma: las
## trazadoras del jugador (cuadrados con bullet.gdshader) y las balas enemigas en voxel
## (BulletMeshes.orb con bullet_voxel.gdshader y su silueta cuando las tapa el decorado).
## Colisiones: las balas de los jugadores contra la rejilla de enemigos de CombatWorld;
## las enemigas, por distancia contra los jugadores (como mucho cuatro).

## Paleta de alto contraste para las balas enemigas (daltonismo): físicas amarillo y blanco,
## mentales cian; la forma (bola maciza o anillo) no cambia.
const HIGH_CONTRAST := {"phys_core": Color(1.0, 1.0, 0.85), "phys_mid": Color(1.0, 0.85, 0.15),
	"phys_edge": Color(0.85, 0.6, 0.0), "ment_light": Color(0.6, 1.0, 1.0), "ment_mid": Color(0.1, 0.8, 0.95),
	"ment_dark": Color(0.0, 0.35, 0.5), "glow": 0.45}

enum Team { PLAYER, ENEMY }
## Estilo visual (lenguaje de daños, GDD 4.4): lo lee el shader por instancia.
## WISP y YITH son trazadoras del jugador de otro color (Báculo del Farolero, Rayo de Yith).
enum Style { PLAYER, PHYSICAL, MENTAL, MIXED, WISP, YITH, PELLET, RIFLE, SMG, BLADE, SPARK, HARPOON, DART, IMPACT }
## Aspecto de bala de cada `WeaponData.bullet_look`.
const LOOK_STYLE := {"pellet": Style.PELLET, "rifle": Style.RIFLE, "smg": Style.SMG, "blade": Style.BLADE,
	"spark": Style.SPARK, "harpoon": Style.HARPOON, "dart": Style.DART}
## Destellos de impacto: un depósito fijo que se dibuja en el mismo MultiMesh que las balas del
## jugador (cero llamadas de dibujo extra). Cada uno vive IMPACT_LIFE s.
## Choque entre balas (04-10-2026): las del jugador anulan las enemigas que tocan. Rejilla plana
## de las balas enemigas (celdas de CLASH_CELL m), rehecha una vez por paso: cada bala del
## jugador mira solo su celda y las vecinas. Las pesadas (radio >= HEAVY) siguen; las demás se
## gastan al chocar.
const CLASH_CELL := 1.0
const CLASH_N := 96                          ## celdas por lado (96 m alrededor del centro)
const HEAVY := 0.2
var _clash_head := PackedInt32Array()        ## primera bala enemiga de cada celda (-1: ninguna)
var _clash_next := PackedInt32Array()        ## siguiente en la misma celda
var _clash_dead := PackedByteArray()         ## anuladas (se retiran al empezar el siguiente paso)
var _pending_clear := false
var _clash_built := -1                      ## fotograma de física en que se hizo la rejilla
const MAX_IMPACTS := 256
const IMPACT_LIFE := 0.18
var _imp_pos := PackedVector3Array()
var _imp_age := PackedFloat32Array()
var _imp_look := PackedInt32Array()
var _imp_n := 0
## Efecto al impactar una bala del jugador: ninguno o estasis (Rayo de Yith, `_effect_val` s).
## INJECT: suero de Herbert West; el que muere inyectado se levanta `_effect_val` s como aliado.
## PARANOIA: bala de un jugador en crisis de paranoia; a los compañeros (no a quien la dispara,
## `_owner`) les quita `_effect_val` de cordura y ninguna vida (D-17).
enum Effect { NONE, STASIS, INJECT, PARANOIA, ROOT, BOUNCE }

const MAX_BULLETS := 4096
const HEIGHT := 0.8                          ## altura de vuelo (a la altura del pecho)

var world: CombatWorld
var count := 0

var _pos := PackedVector3Array()
var _prev := PackedVector3Array()            ## posición en el paso de física anterior (para interpolar el dibujo)
var _vel := PackedVector3Array()
var _radius := PackedFloat32Array()          ## radio de colisión (m)
var _size := PackedFloat32Array()            ## radio visual (m), mayor que el de colisión
var _life := PackedFloat32Array()
var _age := PackedFloat32Array()
var _phys := PackedFloat32Array()
var _ment := PackedFloat32Array()
var _team := PackedByteArray()
var _style := PackedByteArray()
var _pierce := PackedInt32Array()
var _push := PackedFloat32Array()            ## empuje del impacto (multiplicador)
var _bonus := PackedInt32Array()             ## índice en bonus_sets (-1 = sin rasgo)
var _split := PackedInt32Array()
var _tag: Array[StringName] = []          ## arma de cada bala (estadísticas de la ficha)             ## al morir se divide en tantos proyectiles (fuegos artificiales)
var _home := PackedFloat32Array()            ## giro máximo hacia el enemigo más cercano (rad/s; 0 = recta)
var _effect := PackedByteArray()             ## Effect al impactar
var _effect_val := PackedFloat32Array()
var _slowed := PackedByteArray()             ## 1 si ya la frenó un Signo Arcano (solo una vez)
var _owner := PackedInt32Array()             ## índice del jugador que la disparó (-1: nadie)
## Rasgos de daño de quien dispara (Damage.bonus), registrados una vez por jugador.
var bonus_sets: Array[Dictionary] = []
var _last_hit := PackedInt64Array()          ## id del último objetivo tocado (para las que atraviesan);
                                             ## id y no referencia: el objetivo puede liberarse antes que la bala

var _mm: MultiMesh                           ## trazadoras del jugador
var _buffer := PackedFloat32Array()
var _mm_enemy: MultiMesh                     ## balas enemigas en voxel
var _buffer_enemy := PackedFloat32Array()

func _init() -> void:
	name = "Bullets"
	# Uno a uno: un Packed*Array metido en otro array es una copia y redimensionarla no sirve
	_pos.resize(MAX_BULLETS); _prev.resize(MAX_BULLETS); _vel.resize(MAX_BULLETS)
	_radius.resize(MAX_BULLETS); _size.resize(MAX_BULLETS); _life.resize(MAX_BULLETS)
	_age.resize(MAX_BULLETS); _phys.resize(MAX_BULLETS); _ment.resize(MAX_BULLETS)
	_team.resize(MAX_BULLETS); _style.resize(MAX_BULLETS); _pierce.resize(MAX_BULLETS)
	_last_hit.resize(MAX_BULLETS); _push.resize(MAX_BULLETS); _bonus.resize(MAX_BULLETS); _split.resize(MAX_BULLETS); _tag.resize(MAX_BULLETS)
	_home.resize(MAX_BULLETS); _effect.resize(MAX_BULLETS); _effect_val.resize(MAX_BULLETS); _slowed.resize(MAX_BULLETS)
	_owner.resize(MAX_BULLETS)
	_clash_head.resize(CLASH_N * CLASH_N); _clash_next.resize(MAX_BULLETS); _clash_dead.resize(MAX_BULLETS)
	_imp_pos.resize(MAX_IMPACTS); _imp_age.resize(MAX_IMPACTS); _imp_look.resize(MAX_IMPACTS)

func _ready() -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)                 # el shader escala por el radio visual
	_mm.mesh = quad
	_mm.instance_count = MAX_BULLETS + MAX_IMPACTS
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "BulletMesh"
	mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # se interpola a mano en _process
	mmi.multimesh = _mm
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/bullets/bullet.gdshader")
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-200, -10, -200), Vector3(400, 20, 400))   # nunca se descarta por visibilidad
	add_child(mmi)
	_buffer.resize((MAX_BULLETS + MAX_IMPACTS) * 16)
	# balas enemigas: cúmulos de cubos iluminados, con la silueta como segunda pasada
	_mm_enemy = MultiMesh.new()
	_mm_enemy.transform_format = MultiMesh.TRANSFORM_3D
	_mm_enemy.use_custom_data = true
	_mm_enemy.mesh = BulletMeshes.orb()
	_mm_enemy.instance_count = MAX_BULLETS
	_mm_enemy.visible_instance_count = 0
	var emi := MultiMeshInstance3D.new()
	emi.name = "EnemyBulletMesh"
	emi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	emi.multimesh = _mm_enemy
	var emat := ShaderMaterial.new()
	emat.shader = preload("res://scripts/bullets/bullet_voxel.gdshader")
	# accesibilidad: alto contraste (hito 8.3). Por el árbol y no por nombre: con `-s` (herramientas
	# como render_mapa.gd) no hay autoloads y el nombre Settings no compilaría.
	var settings := get_node_or_null("/root/Settings")
	if settings != null and int(settings.get_value("bullet_palette")) == 1:
		for k in HIGH_CONTRAST: emat.set_shader_parameter(k, HIGH_CONTRAST[k])
	var hidden := ShaderMaterial.new()
	hidden.shader = preload("res://scripts/bullets/bullet_voxel_hidden.gdshader")
	hidden.render_priority = 1
	emat.next_pass = hidden
	emi.material_override = emat
	emi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	emi.custom_aabb = AABB(Vector3(-200, -10, -200), Vector3(400, 20, 400))
	add_child(emi)
	_buffer_enemy.resize(MAX_BULLETS * 16)

## Crea una bala. `pos` se proyecta a la altura de vuelo.
func spawn(team: Team, style: Style, pos: Vector3, vel: Vector3, radius: float, size: float,
		damage: Damage, life: float, pierce: int = 0, push: float = 1.0, bonus_set: int = -1, split: int = 0,
		homing: float = 0.0, effect: Effect = Effect.NONE, effect_val: float = 0.0, owner: int = -1) -> void:
	if count >= MAX_BULLETS: return
	var i := count
	_pos[i] = Vector3(pos.x, HEIGHT, pos.z)
	_prev[i] = _pos[i]
	_vel[i] = Vector3(vel.x, 0.0, vel.z)
	_radius[i] = radius
	_size[i] = size
	_life[i] = life
	_age[i] = 0.0
	_phys[i] = damage.physical
	_ment[i] = damage.mental
	_team[i] = team
	_style[i] = style
	_pierce[i] = pierce
	_last_hit[i] = 0
	_push[i] = push
	_bonus[i] = bonus_set
	_split[i] = split
	_home[i] = homing
	_effect[i] = effect
	_effect_val[i] = effect_val
	_tag[i] = damage.tag
	_slowed[i] = 0
	_owner[i] = owner
	count += 1

## Registra los rasgos de daño de un tirador y devuelve su índice para spawn().
func register_bonus(bonus: Dictionary) -> int:
	bonus_sets.append(bonus)
	return bonus_sets.size() - 1

func clear() -> void:
	count = 0

## Signo Arcano: las balas enemigas dentro del círculo pasan a ir a `factor` de su
## velocidad (cada bala, una sola vez). Devuelve cuántas ha frenado.
func slow_enemy_bullets(center: Vector3, r: float, factor: float) -> int:
	var c := Vector2(center.x, center.z)
	var n := 0
	for i in count:
		if _team[i] != Team.ENEMY or _slowed[i] == 1: continue
		if Vector2(_pos[i].x, _pos[i].z).distance_squared_to(c) > r * r: continue
		_vel[i] *= factor
		_slowed[i] = 1
		n += 1
	return n

## Resonador: deshace las balas enemigas dentro del círculo. Devuelve cuántas.
## Las armas de área la llaman a menudo: solo marca (con la rejilla de choques, sin recorrer
## todas las balas) y las marcadas se retiran al empezar el siguiente paso.
func clear_enemy_bullets(center: Vector3, r: float) -> int:
	var n := 0
	if _clash_built != Engine.get_physics_frames():      # sin rejilla de este paso: recorrido simple
		for j in count:
			if _team[j] == Team.ENEMY and _clash_dead[j] == 0 					and Vector2(_pos[j].x - center.x, _pos[j].z - center.z).length_squared() <= r * r:
				_clash_dead[j] = 1
				n += 1
		if n > 0:                                        # sin rejilla no hay índices que cuidar: fuera ya
			for k in range(count - 1, -1, -1):
				if _clash_dead[k] == 1: _remove(k)
			for k in count: _clash_dead[k] = 0
		return n
	var c0 := int(floor((center.x - r) / CLASH_CELL)) + CLASH_N / 2
	var c1 := int(floor((center.x + r) / CLASH_CELL)) + CLASH_N / 2
	var z0 := int(floor((center.z - r) / CLASH_CELL)) + CLASH_N / 2
	var z1 := int(floor((center.z + r) / CLASH_CELL)) + CLASH_N / 2
	for z in range(maxi(z0, 0), mini(z1, CLASH_N - 1) + 1):
		for x in range(maxi(c0, 0), mini(c1, CLASH_N - 1) + 1):
			var j := _clash_head[z * CLASH_N + x]
			while j >= 0:
				if j < count and _team[j] == Team.ENEMY and _clash_dead[j] == 0 						and Vector2(_pos[j].x - center.x, _pos[j].z - center.z).length_squared() <= r * r:
					_clash_dead[j] = 1
					n += 1
				j = _clash_next[j]
	if n > 0: _pending_clear = true
	return n

## Se traga hasta `max_n` balas enemigas dentro del círculo, las más cercanas primero
## (shoggoth bebé). Devuelve cuántas.
func devour_enemy_bullets(center: Vector3, r: float, max_n: int) -> int:
	var c := Vector2(center.x, center.z)
	var near: Array = []
	for i in count:
		if _team[i] != Team.ENEMY: continue
		var d := Vector2(_pos[i].x, _pos[i].z).distance_squared_to(c)
		if d <= r * r: near.append([d, i])
	if near.is_empty(): return 0
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var idx: Array[int] = []
	for k in mini(max_n, near.size()): idx.append(int(near[k][1]))
	idx.sort()
	for k in range(idx.size() - 1, -1, -1): _remove(idx[k])     # de atrás adelante: _remove mueve la última
	return idx.size()

## Balas enemigas dentro del círculo (el Resonador solo vibra si hay algo que deshacer).
func count_enemy_bullets(center: Vector3, r: float) -> int:
	var c := Vector2(center.x, center.z)
	var n := 0
	for i in count:
		if _team[i] == Team.ENEMY and Vector2(_pos[i].x, _pos[i].z).distance_squared_to(c) <= r * r: n += 1
	return n

func _physics_process(delta: float) -> void:
	var t0 := Prof.start()
	var b := world.bounds if world != null else Rect2(-100, -100, 200, 200)
	var obs: ObstacleMap = world.obstacles if world != null and world.obstacles != null and world.obstacles.has_mask() else null
	var i := 0
	var frozen := world != null and world.freeze_t > 0.0
	_resolve_clashes()                                # antes de mover nada: los índices aún valen
	while i < count:
		_prev[i] = _pos[i]
		if frozen and _team[i] == Team.ENEMY:          # tiempo congelado: las balas enemigas, quietas
			i += 1
			continue
		if _home[i] > 0.0 and world != null: _steer(i, delta)
		_pos[i] += _vel[i] * delta
		_age[i] += delta
		var p2 := Vector2(_pos[i].x, _pos[i].z)
		# se paran contra el decorado (cabañas, iglús, acantilados…), las del jugador y las enemigas
		var dead := _age[i] >= _life[i] or not b.has_point(p2) or (obs != null and obs.stops_bullet(p2))
		if not dead and world != null:
			dead = _collide_player_bullet(i) if _team[i] == Team.PLAYER else _collide_enemy_bullet(i)
		if dead:
			if _split[i] > 0: _burst(i)
			_remove(i)          # la última ocupa su hueco: no avanzar i
		else:
			i += 1
	Prof.stop("balas", t0)

## Fuegos fatuos: giran hacia el enemigo más cercano (como mucho _home rad/s) con un
## vaivén que los hace zigzaguear.
func _steer(i: int, delta: float) -> void:
	var v := Vector2(_vel[i].x, _vel[i].z)
	var spd := v.length()
	if spd < 0.01: return
	var a := v.angle()
	var t := world.nearest_enemy(_pos[i], 7.0)
	if t != null:
		var want := Vector2(t.global_position.x - _pos[i].x, t.global_position.z - _pos[i].z).angle()
		a += clampf(wrapf(want - a, -PI, PI), -_home[i] * delta, _home[i] * delta)
	a += sin(_age[i] * 11.0 + float(i)) * 2.2 * delta               # vaivén
	_vel[i] = Vector3(cos(a) * spd, 0.0, sin(a) * spd)

func _collide_enemy_bullet(i: int) -> bool:
	var p := Vector2(_pos[i].x, _pos[i].z)
	for pl in world.players:
		if not pl.is_hittable(): continue
		var r := _radius[i] + pl.data.hurt_radius
		if p.distance_squared_to(Vector2(pl.global_position.x, pl.global_position.z)) <= r * r:
			var d := Damage.new(_phys[i], _ment[i])
			d.knockback = _vel[i].normalized()
			pl.take_damage(d)
			return true
	return false

func _collide_player_bullet(i: int) -> bool:
	if _effect[i] == Effect.PARANOIA and _hits_mate(i): return true
	for id in world.grid.query_circle(Vector2(_pos[i].x, _pos[i].z), _radius[i]):
		var t := world.target_at(id)
		if t.get_instance_id() == _last_hit[i] or not t.is_alive(): continue
		var d := Damage.new(_phys[i], _ment[i])
		d.tag = _tag[i]
		impact(_pos[i], _style[i])
		d.knockback = _vel[i].normalized() * _push[i]
		if _bonus[i] >= 0: d.bonus = bonus_sets[_bonus[i]]
		t.take_damage(d)
		if _effect[i] == Effect.STASIS and t.is_alive() and t.has_method("stasis"): t.stasis(_effect_val[i])
		elif _effect[i] == Effect.INJECT and t.has_method("inject"): t.inject(_effect_val[i], d.bonus)
		elif _effect[i] == Effect.ROOT and t.is_alive() and t.has_method("root"): t.root(_effect_val[i])   # ballesta
		_last_hit[i] = t.get_instance_id()
		if _effect[i] == Effect.BOUNCE and _effect_val[i] >= 1.0 and _bounce(i, t): return false   # BAR
		_pierce[i] -= 1
		if _pierce[i] < 0: return true
	return false

## Rebote (BAR): la bala sale hacia el enemigo vivo más cercano a menos de BOUNCE_RANGE que
## no sea el que acaba de tocar, con su misma velocidad y el alcance renovado.
const BOUNCE_RANGE := 6.0
func _bounce(i: int, hit: Node3D) -> bool:
	var best: Node3D = null
	var best_d := BOUNCE_RANGE * BOUNCE_RANGE
	for e in world.enemies_in_circle(_pos[i], BOUNCE_RANGE):
		if e == hit or not e.is_alive(): continue
		var dd := Vector2(e.global_position.x - _pos[i].x, e.global_position.z - _pos[i].z).length_squared()
		if dd < best_d:
			best_d = dd
			best = e
	if best == null: return false
	var spd := _vel[i].length()
	var to := Vector3(best.global_position.x - _pos[i].x, 0, best.global_position.z - _pos[i].z).normalized()
	_vel[i] = to * spd
	_age[i] = 0.0
	_life[i] = BOUNCE_RANGE * 1.3 / maxf(spd, 0.1)
	_effect_val[i] -= 1.0
	return true

## Paranoia: ¿toca a un compañero del que la disparó? Le quita cordura, nunca vida.
func _hits_mate(i: int) -> bool:
	var p := Vector2(_pos[i].x, _pos[i].z)
	for pl in world.players:
		if pl.index == _owner[i] or not pl.is_hittable(): continue
		var r := _radius[i] + pl.data.hurt_radius
		if p.distance_squared_to(Vector2(pl.global_position.x, pl.global_position.z)) <= r * r:
			pl.take_damage(Damage.new(0.0, _effect_val[i]))
			return true
	return false

## Fuegos artificiales: la bala se abre en `_split` chispas en círculo, más débiles y cortas.
func _burst(i: int) -> void:
	var n := _split[i]
	var d := Damage.new(_phys[i] * 0.5, _ment[i] * 0.5)
	d.tag = _tag[i]
	var spd := maxf(_vel[i].length() * 0.6, 6.0)
	var a0 := randf() * TAU
	for k in n:
		var a := a0 + TAU * k / n
		spawn(_team[i], _style[i], _pos[i], Vector3(cos(a), 0, sin(a)) * spd, _radius[i] * 0.8, _size[i] * 0.7,
			d, 0.45, 0, _push[i] * 0.5, _bonus[i], 0)

func _clash_key(p: Vector3) -> int:
	var cx := int(floor(p.x / CLASH_CELL)) + CLASH_N / 2
	var cz := int(floor(p.z / CLASH_CELL)) + CLASH_N / 2
	if cx < 0 or cz < 0 or cx >= CLASH_N or cz >= CLASH_N: return -1
	return cz * CLASH_N + cx

## Choques entre balas, en una pasada aparte: rejilla de las enemigas, cada bala del jugador
## anula como mucho una, y se retiran las anuladas (y las del jugador que no son pesadas).
func _resolve_clashes() -> void:
	if _pending_clear:                               # lo que marcaron las armas de área
		_pending_clear = false
		for k in range(count - 1, -1, -1):
			if _clash_dead[k] == 1: _remove(k)
	for k in count: _clash_dead[k] = 0               # ya retiradas: se vuelve a empezar
	_build_clash()
	var any := false
	for i in count:
		if _team[i] == Team.PLAYER and _clash(i):
			any = true
			if _radius[i] < HEAVY: _clash_dead[i] = 1
	if not any: return
	for k in range(count - 1, -1, -1):
		if _clash_dead[k] == 1: _remove(k)

func _build_clash() -> void:
	_clash_built = Engine.get_physics_frames()
	_clash_head.fill(-1)
	for i in count:
		if _team[i] != Team.ENEMY: continue
		var k := _clash_key(_pos[i])
		if k < 0: continue
		_clash_next[i] = _clash_head[k]
		_clash_head[k] = i

## ¿Anula esta bala del jugador alguna enemiga? (como mucho una por paso)
func _clash(i: int) -> bool:
	var p := _pos[i]
	var cx := int(floor(p.x / CLASH_CELL)) + CLASH_N / 2
	var cz := int(floor(p.z / CLASH_CELL)) + CLASH_N / 2
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var x := cx + dx; var z := cz + dz
			if x < 0 or z < 0 or x >= CLASH_N or z >= CLASH_N: continue
			var j := _clash_head[z * CLASH_N + x]
			while j >= 0:
				if _clash_dead[j] == 0 and _team[j] == Team.ENEMY:
					var r := _radius[i] + _radius[j]
					if Vector2(_pos[j].x - p.x, _pos[j].z - p.z).length_squared() <= r * r:
						_clash_dead[j] = 1
						impact(_pos[j], int(_style[i]))
						return true
				j = _clash_next[j]
	return false

## Destello de impacto de una bala del jugador (con el aspecto de la bala, para su color).
func impact(pos: Vector3, look: int) -> void:
	if _imp_n >= MAX_IMPACTS: return
	_imp_pos[_imp_n] = Vector3(pos.x, HEIGHT, pos.z)
	_imp_age[_imp_n] = 0.0
	_imp_look[_imp_n] = look
	_imp_n += 1

func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		_pos[i] = _pos[last]; _prev[i] = _prev[last]; _vel[i] = _vel[last]; _radius[i] = _radius[last]; _size[i] = _size[last]
		_life[i] = _life[last]; _age[i] = _age[last]; _phys[i] = _phys[last]; _ment[i] = _ment[last]
		_team[i] = _team[last]; _style[i] = _style[last]; _pierce[i] = _pierce[last]; _last_hit[i] = _last_hit[last]
		_push[i] = _push[last]; _bonus[i] = _bonus[last]; _split[i] = _split[last]
		_home[i] = _home[last]; _effect[i] = _effect[last]; _effect_val[i] = _effect_val[last]; _slowed[i] = _slowed[last]; _tag[i] = _tag[last]
		_owner[i] = _owner[last]; _clash_dead[i] = _clash_dead[last]
	count = last

func _process(_delta: float) -> void:
	var t0 := Prof.start()
	# Buffer del MultiMesh: por instancia, transformación 3x4 (fila a fila) y 4 datos propios:
	# estilo, fase de animación, edad y radio visual. La posición se interpola entre los dos
	# últimos pasos de física: si no, en monitores de más de 60 Hz las balas avanzarían a tirones.
	var frac := Engine.get_physics_interpolation_fraction()
	# Se escribe directamente en cada array: un PackedFloat32Array asignado a otra variable
	# es una copia y lo escrito en ella se perdería.
	var np := 0
	var ne := 0
	for i in count:
		var s := _size[i]
		var p := _prev[i].lerp(_pos[i], frac)
		if _team[i] == Team.PLAYER:
			var o := np * 16
			_buffer[o] = s; _buffer[o + 1] = 0.0; _buffer[o + 2] = 0.0; _buffer[o + 3] = p.x
			_buffer[o + 4] = 0.0; _buffer[o + 5] = s; _buffer[o + 6] = 0.0; _buffer[o + 7] = p.y
			_buffer[o + 8] = 0.0; _buffer[o + 9] = 0.0; _buffer[o + 10] = s; _buffer[o + 11] = p.z
			# fase: el rumbo, para alargar la trazadora
			_buffer[o + 12] = float(_style[i]); _buffer[o + 13] = atan2(_vel[i].x, _vel[i].z)
			_buffer[o + 14] = _age[i]; _buffer[o + 15] = s
			np += 1
		else:
			var o := ne * 16
			_buffer_enemy[o] = s; _buffer_enemy[o + 1] = 0.0; _buffer_enemy[o + 2] = 0.0; _buffer_enemy[o + 3] = p.x
			_buffer_enemy[o + 4] = 0.0; _buffer_enemy[o + 5] = s; _buffer_enemy[o + 6] = 0.0; _buffer_enemy[o + 7] = p.y
			_buffer_enemy[o + 8] = 0.0; _buffer_enemy[o + 9] = 0.0; _buffer_enemy[o + 10] = s; _buffer_enemy[o + 11] = p.z
			_buffer_enemy[o + 12] = float(_style[i]); _buffer_enemy[o + 13] = float(i % 17) * 0.37
			_buffer_enemy[o + 14] = _age[i]; _buffer_enemy[o + 15] = s
			ne += 1
	# destellos de impacto, detrás de las balas en el mismo buffer
	var dt := get_process_delta_time()
	var k := 0
	while k < _imp_n:
		_imp_age[k] += dt
		if _imp_age[k] >= IMPACT_LIFE:
			_imp_n -= 1
			_imp_pos[k] = _imp_pos[_imp_n]; _imp_age[k] = _imp_age[_imp_n]; _imp_look[k] = _imp_look[_imp_n]
			continue
		var o := np * 16
		var s := 0.4
		var q := _imp_pos[k]
		_buffer[o] = s; _buffer[o + 1] = 0.0; _buffer[o + 2] = 0.0; _buffer[o + 3] = q.x
		_buffer[o + 4] = 0.0; _buffer[o + 5] = s; _buffer[o + 6] = 0.0; _buffer[o + 7] = q.y
		_buffer[o + 8] = 0.0; _buffer[o + 9] = 0.0; _buffer[o + 10] = s; _buffer[o + 11] = q.z
		_buffer[o + 12] = float(Style.IMPACT); _buffer[o + 13] = float(_imp_look[k])
		_buffer[o + 14] = _imp_age[k] / IMPACT_LIFE; _buffer[o + 15] = s
		np += 1
		k += 1
	RenderingServer.multimesh_set_buffer(_mm.get_rid(), _buffer)
	_mm.visible_instance_count = np
	RenderingServer.multimesh_set_buffer(_mm_enemy.get_rid(), _buffer_enemy)
	_mm_enemy.visible_instance_count = ne
	Prof.stop("balas_buffer", t0)
