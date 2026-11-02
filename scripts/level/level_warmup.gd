class_name LevelWarmup
extends Node3D
## Calentamiento del nivel (hito 16.1). Al empezar, mientras la partida sale de negro con el
## rótulo, prepara lo que, si no, se haría la primera vez en mitad de la partida, con un tirón:
##  - carga el modelo de cada enemigo que puede salir (malla del disco o de la caché),
##  - calcula su paleta de colores para los trozos al morir (`DeathBurst.palette_of` lee la
##    malla de vuelta de la GPU: lento, y antes se hacía con la primera muerte de cada tipo),
##  - y lo dibuja unos fotogramas bajo el suelo, delante de la cámara, tal cual, con el destello
##    del golpe, con el de los jefes y deshaciéndose: así se compilan sus shaders ahora y no al
##    aparecer, al recibir el primer golpe o al morir.
## `warmup=false` lo quita (para comparar).

const FRAMES := 3                          ## fotogramas que se dibujan antes de quitarlos
const DEPTH := -6.0                        ## m bajo el suelo (dibujados, pero tapados)

static var enabled := true
static var last_models := 0                ## modelos calentados la última vez (tests y registro)

var _left := FRAMES

## Enemigos que pueden salir en el nivel: oleadas, el evento final, lo que viene después y los
## intermedios. Sin repetir modelo.
static func enemies_of(level: LevelData) -> Array[EnemyData]:
	var out: Array[EnemyData] = []
	var seen := {}
	var all: Array = []
	all.append_array(level.pool)
	all.append_array(level.final_pool)
	all.append_array(level.mid_enemies)
	all.append(level.final_enemy)
	all.append(level.final_next)
	for d in all:
		if d == null or seen.has(d.model): continue
		seen[d.model] = true
		out.append(d)
	return out

## Monta el calentamiento junto a `at` (los pies del jugador). Devuelve el nodo, o null si no hay nada.
static func start(parent: Node, level: LevelData, at: Vector3) -> LevelWarmup:
	if not enabled or level == null or parent == null: return null
	var list := enemies_of(level)
	if list.is_empty(): return null
	var w := LevelWarmup.new()
	w.name = "LevelWarmup"
	w.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	parent.add_child(w)
	w.global_position = Vector3(at.x, at.y + DEPTH, at.z)
	var flash := StandardMaterial3D.new()             # como el destello de Enemy
	flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash.albedo_color = Color(1, 1, 1, 0.75)
	var add := StandardMaterial3D.new()               # y el de los jefes
	add.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	add.albedo_color = Color(0.2, 0.2, 0.2)
	var k := 0
	for d in list:
		var path := "res://models/%s.json" % d.model
		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path): continue
		for variant in 4:
			var m := VoxelBuilder.load_model(path)
			m.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
			w.add_child(m)
			m.position = Vector3((k % 6) * 2.5 - 6.0, 0.0, (k / 6) * 2.5 - 6.0)
			k += 1
			if variant == 0: DeathBurst.palette_of(d.model, m)
			elif variant == 1 or variant == 2:
				for mi: MeshInstance3D in m.get_meta("meshes"): mi.material_overlay = flash if variant == 1 else add
			else:
				for it: Array in Crumble.dress(m, Color(1.0, 0.5, 0.2)):
					(it[0] as MeshInstance3D).set_instance_shader_parameter("cut", 0.5)
	last_models = list.size()
	return w

func _process(_delta: float) -> void:
	_left -= 1
	if _left <= 0: queue_free()
