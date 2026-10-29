class_name WallScorch
extends Node3D
## Quemaduras en las paredes (hito 12.11, 29-10-2026): una explosión junto a un muro, una caseta,
## una roca o una caja les deja hollín. Una calca (Decal) centrada en la explosión que proyecta
## hacia abajo y solo pinta el decorado (capa VIS_DECOR, que pone ArenaBuilder; el suelo no, que
## ya tiene su quemado, ni quien pase por delante): en las caras de los lados queda el hollín en
## vertical, más fuerte abajo y que se difumina hacia arriba; encima, una mancha. Solo si hay algo
## cerca (ObstacleMap). Con tope (`limit`, de la calidad gráfica): las más viejas se van deprisa.

const LIFE := 30.0
const FADE := 4.0
const FAST := 0.6
const VIS_DECOR := ArenaBuilder.VIS_DECOR
const HEIGHT := 3.2                             ## m del hollín en las paredes (lo que alcanza antes de desvanecerse)
static var limit := 12
static var _tex: ImageTexture

var _decals: Array = []                         ## [Decal, s que le quedan, lo que dura su desvanecido]

## Hollín alrededor de `pos` en lo que haya a menos de `radius` m. `fx_parent` es world.fx.
static func at(fx_parent: Node, pos: Vector3, radius: float) -> void:
	if fx_parent == null or limit <= 0 or not fx_parent.is_inside_tree(): return
	var w := fx_parent.get_parent() as CombatWorld
	if w == null or w.obstacles == null or not near_something(w.obstacles, Vector2(pos.x, pos.z), radius): return
	var ws: WallScorch = fx_parent.get_meta("wall_scorch") if fx_parent.has_meta("wall_scorch") else null
	if ws == null or not is_instance_valid(ws):
		ws = WallScorch.new()
		ws.name = "WallScorch"
		ws.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		fx_parent.add_child(ws)
		fx_parent.set_meta("wall_scorch", ws)
	ws._add(Vector2(pos.x, pos.z), radius)

## ¿Hay decorado a menos de `radius` m de `p`? (sin máscara, el campo de pruebas: no)
static func near_something(obs: ObstacleMap, p: Vector2, radius: float) -> bool:
	return obs.has_mask() and obs.distance(p) < radius * 0.8

func _add(at_p: Vector2, radius: float) -> void:
	var dc := Decal.new()
	dc.texture_albedo = _texture()
	dc.modulate = Color(1, 1, 1, 0.9)
	dc.cull_mask = VIS_DECOR
	dc.upper_fade = 0.55                         # se difumina hacia arriba
	dc.lower_fade = 0.1
	var span := clampf(radius * 2.0, 2.0, 5.0)
	dc.size = Vector3(span, HEIGHT * 2.0, span)  # centrada en el suelo: la mitad de abajo no pinta nada
	dc.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(dc)
	dc.global_transform = Transform3D(Basis(Vector3.UP, randf() * TAU), Vector3(at_p.x, 0.0, at_p.y))
	_decals.append([dc, LIFE, FADE])
	var extra := _decals.size() - limit
	for i in maxi(extra, 0):
		if _decals[i][1] > FAST:
			_decals[i][1] = FAST
			_decals[i][2] = FAST

func _process(delta: float) -> void:
	for i in range(_decals.size() - 1, -1, -1):
		var e: Array = _decals[i]
		e[1] -= delta
		var dc: Decal = e[0]
		if e[1] <= 0.0 or not is_instance_valid(dc):
			if is_instance_valid(dc): dc.queue_free()
			_decals.remove_at(i)
		elif e[1] < e[2]:
			dc.modulate.a = 0.9 * e[1] / e[2]

func count() -> int:
	return _decals.size()

## Mancha de hollín en celdas de voxel: casi negra en el centro y cada vez más clara hacia fuera,
## hasta casi el borde (lo que pinta en las paredes está a un par de metros de la explosión), con
## el borde roto y alguna salpicadura suelta. Se genera una vez.
static func _texture() -> ImageTexture:
	if _tex != null: return _tex
	const N := 48
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.16
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for j in N:
		for i in N:
			var u := (float(i) + 0.5) / N * 2.0 - 1.0
			var v := (float(j) + 0.5) / N * 2.0 - 1.0
			var d := Vector2(u, v).length()
			var edge := 0.9 + 0.1 * noise.get_noise_2d(i, j)
			var a := clampf((edge - d) * 2.5, 0.0, 1.0) * (0.45 + 0.55 * clampf(1.0 - d, 0.0, 1.0))
			if a <= 0.05 and d < 1.0 and rng.randf() < 0.06: a = 0.35                 # salpicaduras sueltas
			var c := Color(0.07, 0.06, 0.05).lerp(Color(0.015, 0.013, 0.012), clampf(1.0 - d * 1.4, 0.0, 1.0))
			img.set_pixel(i, j, Color(c.r, c.g, c.b, snappedf(a, 0.15)))
	_tex = ImageTexture.create_from_image(img)
	return _tex
