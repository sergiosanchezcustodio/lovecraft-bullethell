extends GutTest
## Fluidez de las animaciones del jugador: entre dos fotogramas seguidos ninguna parte
## del cuerpo puede saltar de golpe, ni al entrar o salir del esquive ni al lanzar.

const DT := 1.0 / 120.0

class ScriptedInput extends PlayerInput:
	var t := 0.0
	var dodge_at: Array[float] = []
	func update(delta: float) -> void:
		t += delta
		super.update(delta)
	func _read_move(_d: float) -> Vector2:
		return Vector2(1, 0) if t < 2.4 else Vector2.ZERO        # corre y al final se para
	func _read_action(a: StringName) -> bool:
		if a != InputBindings.DODGE: return false
		for d in dodge_at:
			if t >= d and t < d + 0.03: return true
		return false

## Posición (en metros, respecto al jugador) de dos puntos de cada parte: su pivote y un
## punto a 40 cm a lo largo de ella. Con posiciones reales, y no con ángulos, una voltereta
## que pasa de +180° a -180° no cuenta como salto.
func _pose(p: Player) -> Array:
	var out: Array = []
	var root: Transform3D = p.model.transform
	for n: Node3D in p.model.get_meta("parts"):
		var xf := root * n.transform
		out.append(xf.origin)
		out.append(xf * Vector3(0, -0.4, 0))
	return out

func _max_jump(a: Array, b: Array) -> float:
	var worst := 0.0
	for i in a.size():
		worst = maxf(worst, ((a[i] as Vector3) - (b[i] as Vector3)).length())
	return worst

func test_sin_saltos_deslizamiento() -> void:
	await _sin_saltos("slide")

func test_sin_saltos_voltereta() -> void:
	await _sin_saltos("roll")

func test_sin_saltos_plancha() -> void:
	await _sin_saltos("dive")

func test_sin_saltos_salto() -> void:
	await _sin_saltos("jump")

func _sin_saltos(dodge_anim: String) -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var inp := ScriptedInput.new()
	inp.dodge_at = [0.5, 1.7] as Array[float]
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), inp, Color.YELLOW)
	p.data.dodge_anim = dodge_anim
	p.world = world
	world.add_child(p)
	world.add_player(p)
	var prev := _pose(p)
	var worst := 0.0
	var worst_t := 0.0
	var t := 0.0
	var threw := false
	while t < 3.2:
		if not threw and t > 1.0:
			p.play_once("throw")                 # lanza mientras corre
			threw = true
		if fmod(t, 1.0 / 60.0) < DT: p._physics_process(1.0 / 60.0)
		p._process(DT)
		var cur := _pose(p)
		var j := _max_jump(prev, cur)
		if j > worst:
			worst = j
			worst_t = t
		prev = cur
		t += DT
	# Andar mueve un punto hasta ~5 cm por fotograma a 120 Hz; la voltereta, unos 15 cm en
	# el momento de más giro. Un salto de animación (cambiar de pose de golpe) supera 0,3 m.
	assert_lt(worst, 0.2, "%s: mayor desplazamiento entre fotogramas %.3f m en t=%.2f s" % [dodge_anim, worst, worst_t])

func test_al_lanzar_las_piernas_siguen_andando() -> void:
	var world := CombatWorld.new()
	add_child_autofree(world)
	var inp := ScriptedInput.new()
	var p := Player.new().setup(load("res://data/characters/dyer.tres"), inp, Color.YELLOW)
	p.world = world
	world.add_child(p)
	var leg := Anims.part(p.model, "leg_l")
	for i in 30:                                   # correr un poco
		p._physics_process(1.0 / 60.0); p._process(1.0 / 60.0)
	p.play_once("throw")
	var angles: Array[float] = []
	for i in 30:
		p._physics_process(1.0 / 60.0); p._process(1.0 / 60.0)
		angles.append(leg.rotation.x)
	var lo: float = angles.min()
	var hi: float = angles.max()
	assert_gt(hi - lo, 0.5, "la pierna sigue balanceándose durante el lanzamiento")
	var arm := Anims.part(p.model, "arm_r")
	assert_ne(arm.rotation.x, 0.0)
