class_name BulletMeshes
extends RefCounted
## Malla de las balas enemigas en voxel: un núcleo de 19 cubos (7 interiores y 12 de capa
## exterior, una bola de 3×3×3 sin esquinas) y un anillo horizontal de 14 cubos. El shader
## (bullet_voxel.gdshaderinc) enseña unos grupos u otros según el tipo de daño.
## En COLOR: r = matiz propio de cada cubo, g = grupo (0 interior, 0,5 exterior, 1 anillo).
## Solo se generan las caras que no toca otro cubo del mismo grupo.

const CORE_STEP := 0.4           ## separación de los cubos del núcleo (el núcleo mide ±0,6)
const CORE_HALF := 0.2
const RING_R := 1.0              ## radio del anillo
const RING_N := 14
const RING_HALF := 0.13

static var _orb: ArrayMesh

static func orb() -> ArrayMesh:
	if _orb: return _orb
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var cells := {}
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				if absi(x) + absi(y) + absi(z) == 3: continue          # sin esquinas: bola
				cells[Vector3i(x, y, z)] = true
	for c: Vector3i in cells:
		var inner := absi(c.x) + absi(c.y) + absi(c.z) <= 1
		var group := 0.0 if inner else 0.5
		var shade := rng.randf() if not inner else 0.5 + rng.randf() * 0.5
		_cube(st, Vector3(c) * CORE_STEP, CORE_HALF, Color(shade, group, 0.0), func(n: Vector3i) -> bool: return cells.has(c + n))
	for i in RING_N:
		var a := TAU * i / RING_N
		var p := Vector3(cos(a), 0.0, sin(a)) * RING_R
		_cube(st, p, RING_HALF, Color(rng.randf(), 1.0, 0.0), func(_n: Vector3i) -> bool: return false)
	st.generate_normals()
	_orb = st.commit()
	return _orb

const FACES := [
	[Vector3i(1, 0, 0), [Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(1, 1, 1), Vector3(1, -1, 1)]],
	[Vector3i(-1, 0, 0), [Vector3(-1, -1, 1), Vector3(-1, 1, 1), Vector3(-1, 1, -1), Vector3(-1, -1, -1)]],
	[Vector3i(0, 1, 0), [Vector3(-1, 1, -1), Vector3(-1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, -1)]],
	[Vector3i(0, -1, 0), [Vector3(-1, -1, 1), Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, -1, 1)]],
	[Vector3i(0, 0, 1), [Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1), Vector3(-1, -1, 1)]],
	[Vector3i(0, 0, -1), [Vector3(-1, -1, -1), Vector3(-1, 1, -1), Vector3(1, 1, -1), Vector3(1, -1, -1)]],
]

## Un cubo con las caras que no tapa un vecino (`covered(dirección)`). Orden horario:
## Godot considera cara frontal el sentido horario.
static func _cube(st: SurfaceTool, center: Vector3, half: float, col: Color, covered: Callable) -> void:
	for f in FACES:
		if covered.call(f[0]): continue
		var q: Array = f[1]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.add_vertex(center + (q[k] as Vector3) * half)
