class_name GroundMarks
extends Node3D
## Manchas que se quedan en el suelo (hito 11.1, 27-10-2026): la salpicadura de una muerte
## (DeathBurst) y el quemado de una explosión, al acabar su efecto, pasan aquí ya secas y se
## desvanecen despacio. Con más de `limit` a la vez, las más viejas se van deprisa.

const LINGER := 14.0                           ## lo que dura una mancha (los últimos FADE s, desvaneciéndose)
const FADE := 3.0
const FAST := 0.5                              ## las que sobran, en esto
static var limit := 24

var _marks: Array = []                         ## [MeshInstance3D, ShaderMaterial, tiempo que le queda, lo que dura su desvanecido]

## Se queda con `mark` (que ya está seca: `age` 1) para que dure `life` s más.
static func keep(fx_parent: Node, mark: MeshInstance3D, life := LINGER) -> void:
	if fx_parent == null or mark == null or limit <= 0:
		if mark != null: mark.queue_free()
		return
	var gm: GroundMarks = fx_parent.get_meta("ground_marks") if fx_parent.has_meta("ground_marks") else null
	if gm == null or not is_instance_valid(gm):
		gm = GroundMarks.new()
		gm.name = "GroundMarks"
		gm.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF   # quietas; llegan desde _process
		fx_parent.add_child(gm)
		fx_parent.set_meta("ground_marks", gm)
	mark.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	mark.reparent(gm)
	gm._marks.append([mark, mark.material_override, life, FADE])
	var extra := gm._marks.size() - limit
	for i in maxi(extra, 0):                    # las más viejas, deprisa
		if gm._marks[i][2] > FAST:
			gm._marks[i][2] = FAST
			gm._marks[i][3] = FAST

func _process(delta: float) -> void:
	for i in range(_marks.size() - 1, -1, -1):
		var m: Array = _marks[i]
		m[2] -= delta
		if m[2] <= 0.0 or not is_instance_valid(m[0]):
			if is_instance_valid(m[0]): (m[0] as Node).queue_free()
			_marks.remove_at(i)
			continue
		(m[1] as ShaderMaterial).set_shader_parameter("fade", clampf(m[2] / m[3], 0.0, 1.0))

func count() -> int:
	return _marks.size()
