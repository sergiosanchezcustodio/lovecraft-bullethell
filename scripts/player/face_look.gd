class_name FaceLook
extends Node
## Parpadeo y mueca de dolor de las caras dibujadas a mano (27-10-2026). Encima de los ojos
## (de 4×2, data/faces.json, de tools/gen_caras_juego.py) se ponen unos párpados del color de la
## piel cada pocos segundos, y al recibir daño, un momento, los ojos apretados en «/ \» y los
## dientes apretados. Van en la cabeza, con el mismo material que el modelo: se iluminan igual.
## Un personaje sin datos de cara (las cabezas de antes, arte=v1) no parpadea.

const BLINK_TIME := 0.12                    ## s con los ojos cerrados
const BLINK_GAP := Vector2(2.5, 6.0)        ## s entre parpadeos, al azar
const DOUBLE_BLINK := 0.2                   ## a veces, dos seguidos
const HURT_TIME := 0.4                      ## s de mueca tras un golpe
const LASH := 0.55                          ## la fila de abajo del párpado cerrado, más oscura
const DARK := Color(0.13, 0.08, 0.07)
const TEETH := Color(0.92, 0.9, 0.84)
const LIFT := 0.03                          ## voxels por delante de la cara (sin z-fighting)

static var _faces: Dictionary = {}

var _blink: MeshInstance3D
var _hurt: MeshInstance3D
var _rng := RandomNumberGenerator.new()
var _wait := 0.0                            ## s hasta el próximo parpadeo
var _closed := 0.0                          ## s que le quedan con los ojos cerrados
var _hurt_left := 0.0
var suppressed := false                     ## en las crisis (la cara de pánico va encima)
var _fixed := ""                            ## face=cerrados|dolor: deja esa cara (capturas)
var driven := false                         ## la mueve otro: el retrato del HUD copia la cara del jugador

func setup(model: Node3D, model_path: String) -> FaceLook:
	_rng.randomize()
	_fixed = LaunchArgs.from_cmdline().get_str("face")
	_wait = _rng.randf_range(BLINK_GAP.x, BLINK_GAP.y)
	var f: Dictionary = faces().get(model_path.get_file().get_basename(), {})
	var head := model.get_node_or_null("head") as Node3D
	if f.is_empty() or head == null: return self
	var mat: Material = null
	for c in head.get_children():
		if c is MeshInstance3D and int(c.get_meta("kind", 0)) == 0: mat = (c as MeshInstance3D).material_override
	var vs: float = model.get_meta("voxel_size", 1.0 / 32.0)
	var pv: Array = (model.get_meta("pivots", {}) as Dictionary).get("head", [0, 0, 0])
	var pivot := Vector3(pv[0], pv[1], pv[2])
	var lid := Color(f.lid[0], f.lid[1], f.lid[2])
	var y0 := int(f.eyes[0][1])
	var shut := []                              # [x, y, z, color]
	var pain := []
	for e: Array in f.eyes:
		var x := int(e[0])
		var top := int(e[1]) > y0
		shut.append([x, e[1], e[2], lid if top else lid * Color(LASH, LASH, LASH)])
		var inner := x in [-4, -3, 2, 3]        # el lado de la nariz
		pain.append([x, e[1], e[2], DARK if top == inner else lid])   # «/ \»: arriba por dentro, abajo por fuera
	for c: Array in f.get("around", []):        # pestañas y sombra de ojos, tapadas con piel
		pain.append([c[0], c[1], c[2], lid])
	var m := int(f.mouth[0])
	var mz := int(f.mouth[1])
	for x in range(-3, 3):                      # dientes apretados, por delante del bigote o la barba
		pain.append([x, m, mz, DARK])
		pain.append([x, m + 1, mz, TEETH if x > -3 and x < 2 else DARK])
	_blink = _quads(shut, pivot, vs, mat)
	_hurt = _quads(pain, pivot, vs, mat)
	head.add_child(_blink)
	head.add_child(_hurt)
	return self

static func faces() -> Dictionary:
	if _faces.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/faces.json"))
		_faces = d if d is Dictionary else {"": {}}
	return _faces

## Una cara +z por casilla, delante del voxel (x, y, z), con su color.
static func _quads(cells: Array, pivot: Vector3, vs: float, mat: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array = VoxelBuilder.FACES[4][1]
	for c: Array in cells:
		var p := Vector3(float(c[0]), float(c[1]), float(c[2]) + LIFT)
		for i in [0, 2, 1, 0, 3, 2]:
			st.set_normal(Vector3.BACK)
			st.set_color(c[3])
			st.add_vertex((p + corners[i] - pivot) * vs)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	return mi

## Un golpe: mueca un momento.
func hurt() -> void:
	_hurt_left = HURT_TIME

## La cara que enseña ahora: 0 abierta, 1 parpadeo, 2 mueca (el retrato del HUD la copia).
func state() -> int:
	if _blink == null: return 0
	return 2 if _hurt.visible else (1 if _blink.visible else 0)

func show_state(s: int) -> void:
	if _blink == null: return
	_hurt.visible = s == 2
	_blink.visible = s == 1

func _process(delta: float) -> void:
	if _blink == null or driven: return
	_hurt_left = maxf(_hurt_left - delta, 0.0)
	_wait -= delta
	if _wait <= 0.0:
		_closed = BLINK_TIME
		var twice := _rng.randf() < DOUBLE_BLINK
		_wait = BLINK_TIME * 2.5 if twice else _rng.randf_range(BLINK_GAP.x, BLINK_GAP.y)
	_closed = maxf(_closed - delta, 0.0)
	var pain := (_hurt_left > 0.0 or _fixed == "dolor") and not suppressed
	_hurt.visible = pain
	_blink.visible = (_closed > 0.0 or _fixed == "cerrados") and not pain and not suppressed
