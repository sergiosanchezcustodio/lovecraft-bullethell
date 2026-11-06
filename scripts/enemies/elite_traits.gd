class_name EliteTraits
## Élites con rasgos (hito 16.20, a la manera de los campeones de *Diablo*): cada élite que no es
## un jefe saca al aparecer uno o dos rasgos al azar, que se ven en un icono sobre la cabeza.
##   VAMPIRE  vampírica: mientras toca a un jugador se cura un `VAMPIRE_HEAL` de su vida por segundo.
##   BLAST    estalla al morir: aviso de `BLAST_WARN` s y golpe de `BLAST_R` m.
##   ICOR     deja un rastro de charcos de icor que queman (`EnemyZone`).
##   FAST     rápida: `FAST_MULT` de velocidad.
##   SHIELD   con escudo: la burbuja de icor (`Enemy.set_ward`) que para `SHIELD_HITS` golpes.
## Los saca el anfitrión (`WaveDirector.spawn`) y viajan con el aviso de aparición (NetGame, SPAWN).
## El rastro de icor lo deja cada PC (como todas las zonas, daña a sus jugadores); lo demás, el
## anfitrión, y llega con la vida, el escudo y los golpes de siempre.
## Pruebas: `traits=N` (máscara) o `traits=vampira,estalla,icor,rapida,escudo` para todas.

const VAMPIRE := 1
const BLAST := 2
const ICOR := 4
const FAST := 8
const SHIELD := 16
const ALL := [VAMPIRE, BLAST, ICOR, FAST, SHIELD]
const NAMES := {VAMPIRE: "vampira", BLAST: "estalla", ICOR: "icor", FAST: "rapida", SHIELD: "escudo"}

const TWO_CHANCE := 0.35
const VAMPIRE_HEAL := 0.06
const BLAST_R := 2.4
const BLAST_WARN := 0.9
const BLAST_DAMAGE := 18.0
const BLAST_COLOR := Color(1.0, 0.5, 0.12)
const ICOR_EVERY := 0.4
const ICOR_GAP := 0.7                     ## m que tiene que andar entre charco y charco
const ICOR_COLOR := Color(0.32, 0.30, 0.04)
const FAST_MULT := 1.4
const SHIELD_HITS := 3

## Uno o dos rasgos al azar (o los de `traits=`).
static func roll(rng: RandomNumberGenerator) -> int:
	var forced := forced_mask()
	if forced >= 0: return forced
	var pool := ALL.duplicate()
	var t := 0
	for i in (2 if rng.randf() < TWO_CHANCE else 1):
		var k := rng.randi_range(0, pool.size() - 1)
		t |= int(pool[k])
		pool.remove_at(k)
	return t

static var _forced := -2
static func forced_mask() -> int:
	if _forced != -2: return _forced
	_forced = -1
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("traits="): continue
		var v := a.substr(7)
		if v.is_valid_int():
			_forced = int(v)
		else:
			_forced = 0
			for n in v.split(","):
				for k in NAMES: if NAMES[k] == n: _forced |= int(k)
	return _forced

## Al recibir los rasgos (anfitrión e invitados): el icono y, en el anfitrión, el escudo.
static func apply(e: Enemy, t: int) -> void:
	e.traits = t
	if t == 0: return
	if t & SHIELD and not e.puppet: e.set_ward(SHIELD_HITS)
	var s := Sprite3D.new()
	s.texture = icon(t)
	s.pixel_size = 0.04
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.no_depth_test = true
	s.shaded = false
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.render_priority = 10
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	s.position.y = 1.6 * e.model_scale
	s.top_level = true                                # sigue al dibujo (Enemy._process), no al paso de física
	s.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	e.add_child(s)
	s.global_position = e.global_position + Vector3(0.0, 1.6 * e.model_scale, 0.0)
	e.trait_icon = s

## Cada paso de física (anfitrión y marionetas).
static func step(e: Enemy, delta: float) -> void:
	if e.traits & ICOR and not e.buried:
		e.trait_t -= delta
		var p := e.global_position
		if e.trait_t <= 0.0 and (e.trait_from == Vector3.INF or p.distance_to(e.trait_from) > ICOR_GAP):
			e.trait_t = ICOR_EVERY
			e.trait_from = p
			var z := EnemyZone.new().setup(e.world, p, 0.75, 4.5, 6.0, 0.0)
			z.color = ICOR_COLOR
			z.who = e.data.id
			e.world.fx.add_child(z)
	if e.traits & VAMPIRE and not e.puppet:
		var top := e.data.max_health * e.health_scale
		for q in e.world.players:
			if q.health <= 0.0: continue
			var r := e.data.body_radius * e.model_scale + q.data.hurt_radius + 0.15
			var o := q.global_position - e.global_position
			if Vector2(o.x, o.z).length_squared() > r * r: continue
			e.health = minf(e.health + top * VAMPIRE_HEAL * delta, top)
			e.trait_fx -= delta
			if e.trait_fx <= 0.0:
				e.trait_fx = 0.35
				VoxelFx.puff(e.world.fx, e.global_position + Vector3(0, 0.9 * e.model_scale, 0), "sparkle", 0.4, Color(0.95, 0.12, 0.12), 0.8)
			break

## Al morir (anfitrión): el estallido, con aviso.
static func on_death(e: Enemy) -> void:
	if not e.traits & BLAST: return
	var w := e.world
	var at := Vector3(e.global_position.x, 0.0, e.global_position.z)
	var who := e.data.id
	var tg := Telegraph.enemy(BLAST_R, BLAST_WARN, Color(BLAST_COLOR, 0.85))
	tg.position = at
	w.fx.add_child(tg)
	w.sfx("cue_attack", at)
	w.get_tree().create_timer(BLAST_WARN, false).timeout.connect(func() -> void:
		if not is_instance_valid(w): return
		var d := Damage.new(BLAST_DAMAGE, 0.0)
		d.via = &"estallido"
		d.who = who
		w.strike(at, BLAST_R, d)
		w.ground_hit(at, BLAST_R, BLAST_COLOR)
		w.sfx("explosion", at)
		w.shake(0.3))

# ---------------------------------------------------------------- iconos

const _PIX := {
	VAMPIRE: ["....#....", "...###...", "...###...", "..#####..", ".###o###.", ".##o####.", ".##o####.", "..#####..", "...###..."],
	BLAST: ["#...#...#", ".#.###.#.", "..#####..", ".###o###.", "####o####", ".###o###.", "..#####..", ".#.###.#.", "#...#...#"],
	ICOR: ["...#.....", "..###..#.", "...#..###", ".......#.", "..#####..", ".###o###.", "####o####", ".#######.", "........."],
	FAST: ["#...#....", "##..##...", ".##..##..", "..##..##.", "...##..##", "..##..##.", ".##..##..", "##..##...", "#...#...."],
	SHIELD: ["#########", "#ooooooo#", "#o#####o#", "#o#####o#", "#o#####o#", ".#o###o#.", ".#o###o#.", "..#ooo#..", "...###..."],
}
const _COL := {VAMPIRE: Color(0.85, 0.08, 0.10), BLAST: Color(1.0, 0.52, 0.10), ICOR: Color(0.72, 0.78, 0.10),
	FAST: Color(0.40, 0.85, 1.0), SHIELD: Color(0.85, 0.62, 0.30)}
static var _icons := {}

## Los iconos de los rasgos de `t`, en fila, con borde negro (uno por máscara, guardado).
static func icon(t: int) -> ImageTexture:
	if _icons.has(t): return _icons[t]
	var list := ALL.filter(func(k: int) -> bool: return t & k)
	var cell := 11
	var img := Image.create(cell * list.size() + (list.size() - 1), cell, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for n in list.size():
		var k: int = list[n]
		var rows: Array = _PIX[k]
		var c: Color = _COL[k]
		var x0 := n * (cell + 1)
		for y in 9:
			for x in 9:
				if String(rows[y])[x] == ".": continue
				for dy in 3:
					for dx in 3:
						var px := x0 + x + dx
						var py := y + dy
						if img.get_pixel(px, py).a == 0.0: img.set_pixel(px, py, Color(0.02, 0.02, 0.03, 0.9))
		for y in 9:
			for x in 9:
				var ch := String(rows[y])[x]
				if ch == ".": continue
				img.set_pixel(x0 + x + 1, y + 1, c.lightened(0.45) if ch == "o" else c)
	var tex := ImageTexture.create_from_image(img)
	_icons[t] = tex
	return tex
