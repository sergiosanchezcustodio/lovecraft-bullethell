extends GutTest
## Costados de los humanos y de las prendas con manga (28-10-2026): donde el brazo se solapa con el
## tronco, el tronco tiene que seguir entero (voxlib.Model.keep_under, bit 64 del noveno valor). Si la
## manga lo borra, al balancear el brazo queda una franja sin tela en el costado.

const CHARACTERS := ["dyer", "olmstead", "legrasse", "johansen", "peaslee", "varga", "whipple", "blake",
	"iwanicki", "elwood", "malone", "armitage", "west"]
## Barnabas no: los bajos de su levita están deshilachados a propósito. Ni las criaturas (aletas y crestas).
const PEOPLE := ["anciano", "cultista", "cultista_alert", "sacerdote_culto", "innsmouth_g0", "innsmouth_g1",
	"innsmouth_g2", "innsmouth_g3", "habitante_pescador", "habitante_mujer", "habitante_viejo", "acolito",
	"diacono", "hibrido_h", "hibrido_m", "sacerdote", "sumo_sacerdote"]
const SLEEVED := ["abrigo_nieve", "abrigo_piel", "bata", "chaqueta_aviador", "chubasquero", "vestido"]
const BODIES := ["dyer", "johansen", "peaslee"]          # normal, ancho y delgado
const ARMS := ["arm_l", "arm_r", "fore_l", "fore_r"]

## Huecos del costado: en las filas a la altura de los brazos, mirando el tronco de lado, tramos de
## 3 o más voxels seguidos que quedan 2 o más por dentro de lo que tienen delante y detrás. Un relieve
## suelto (el hueco entre dos cartuchos de dinamita) es de uno.
static func side_holes(path: String) -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var arm_rows := {}
	for v: Array in data.voxels:
		if v[3] in ARMS: arm_rows[int(v[1])] = true
	var found := []
	for sgn in [-1, 1]:
		var rows := {}                                    # y -> {z: x más afuera}
		for v: Array in data.voxels:
			var y := int(v[1])
			if v[3] != "torso" or not arm_rows.has(y) or int(v[0]) * sgn < 0: continue
			if not rows.has(y): rows[y] = {}
			var z := int(v[2])
			rows[y][z] = maxi(rows[y].get(z, -999), int(v[0]) * sgn)
		for y: int in rows:
			var r: Dictionary = rows[y]
			var zs: Array = r.keys()
			zs.sort()
			var front := []                                # lo más afuera antes de cada z
			var best := -999
			for z: int in zs:
				front.append(best)
				best = maxi(best, r[z])
			best = -999
			var run := 0
			for i in range(zs.size() - 1, -1, -1):        # de atrás adelante: lo de detrás ya está visto
				var z: int = zs[i]
				var deep: bool = front[i] > -999 and best > -999 and mini(front[i], best) - int(r[z]) >= 2
				run = run + 1 if deep and (run == 0 or zs[i + 1] == z + 1) else (1 if deep else 0)
				if run == 3: found.append("%s y=%d z=%d" % ["izquierda" if sgn < 0 else "derecha", y, z])
				best = maxi(best, r[z])
	return found

func _check(models: Array) -> void:
	for m: String in models:
		var path := "res://models/%s.json" % m
		assert_true(FileAccess.file_exists(path), path)
		var holes := side_holes(path)
		assert_eq(holes.size(), 0, "%s: costado hueco en %s" % [m, holes])

func test_personajes() -> void:
	_check(CHARACTERS)

func test_vecinos_y_cultistas() -> void:
	_check(PEOPLE)

func test_prendas_con_manga() -> void:
	var models := []
	for g in SLEEVED:
		for c in BODIES: models.append("vest_%s_%s" % [g, c])
	_check(models)

## La comprobación encuentra el fallo: un tronco con un hueco de 5 voxels en el costado.
func test_detecta_un_costado_hueco() -> void:
	var vox := []
	for y in range(40, 50):
		for z in range(-6, 7):
			var deep := y >= 43 and y <= 46 and z >= -2 and z <= 2
			for x in range(-10 if not deep else -7, 11): vox.append([x, y, z, "torso", 0.5, 0.5, 0.5, 0])
		vox.append([-12, y, 0, "arm_l", 0.5, 0.5, 0.5, 0])
	var path := "user://test_costado.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"voxels": vox, "pivots": {}}))
	f.close()
	assert_gt(side_holes(path).size(), 0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

## Lo tapado por otra parte (bit 64) se construye con las caras un poco hundidas: no parpadea con la
## de la otra parte que ocupa el mismo sitio.
func test_lo_tapado_se_hunde() -> void:
	var p := Vector3i.ZERO
	var mesh := VoxelBuilder._build([[p, Color.WHITE, 64]], {p: true}, {p: true}, Vector3.ZERO, 1.0)
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_eq(verts.size(), 36)                            # las seis caras, ninguna quitada
	for i in verts.size():
		var along := verts[i].dot(normals[i].abs())       # la coordenada en el eje de su cara
		assert_true(along > 0.0 and along < 1.0, "cara hundida hacia dentro: %s" % verts[i])
