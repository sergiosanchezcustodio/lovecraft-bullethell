class_name LevelWarmup
extends Node3D
## Calentamiento del nivel (hito 16.1). Al empezar, mientras la partida sale de negro con el
## rótulo, prepara lo que, si no, se haría la primera vez en mitad de la partida, con un tirón:
##  - carga el modelo de cada enemigo que puede salir (malla del disco o de la caché),
##  - calcula su paleta de colores para los trozos al morir (`DeathBurst.palette_of` lee la
##    malla de vuelta de la GPU: lento, y antes se hacía con la primera muerte de cada tipo),
##  - y lo dibuja unos fotogramas bajo el suelo, delante de la cámara, tal cual, con el destello
##    del golpe, con el de los jefes y deshaciéndose: así se compilan sus shaders ahora y no al
##    aparecer, al recibir el primer golpe o al morir. También el baúl arcano y una sombra del miedo.
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
		# la horda (hito 16.3): se graban sus poses ahora y se dibuja una para compilar su shader
		if HordeDraw.enabled and not d.unique and d.model_scale <= 1.5 and not d.ethereal:
			var h := HordeMesh.get_type(d.model)
			if h != null:
				var mmi := h.multimesh(1)
				var x := (k % 6) * 2.5 - 6.0; var z := (k / 6) * 2.5 - 6.0
				mmi.multimesh.buffer = PackedFloat32Array([1, 0, 0, x, 0, 1, 0, 0, 0, 0, 1, z, 0, 0, 0, 0])
				w.add_child(mmi)
				k += 1
	# el baúl arcano (07-11-2026: el primero compilaba sus shaders al aparecer, a mitad de nivel). Sin
	# `setup` no cuenta como baúl ni se abre: solo se dibuja.
	# En el suelo, junto al jugador, a su tamaño de salida (1 %, quieto) y con la luz apagada: bajo el
	# suelo quedaba fuera de las sombras de la luna y le faltaba esa pasada (16,5 ms al salir el primero).
	if level.chest_every > 0.0:
		var c := ArcaneChest.new()
		w.add_child(c)
		c.set_process(false)
		c._light.light_energy = 0.0
		c.position = Vector3(-1.5, -DEPTH, 1.5)
		var lb := ArcaneChest.money_label(30)                 # y lo que sale al abrirlo: el letrero (que se
		lb.modulate.a = 1.0 / 255.0                           # dibuja encima de todo: casi transparente; con 0, no se dibuja)
		lb.outline_modulate.a = 1.0 / 255.0
		w.add_child(lb)
		lb.position = Vector3(-1.5, 1.2 - DEPTH, 1.5)
		VoxelFx.puff(w, w.global_position + Vector3(-1.5, 0.5, 1.5), "sparkle", 0.6)   # y los destellos, bajo el suelo
	# y una sombra del miedo (07-11-2026: la primera, a mitad de nivel, compilaba 6 shaders en 320 ms).
	# Sobre el suelo, junto al jugador y del todo transparente: invisible, pero se dibuja como en la
	# partida (bajo el suelo le faltaban 4 de sus pipelines)
	if not Ambient.fear_cfg().is_empty():
		var made := Ambient.make_shade(Ambient.fear_cfg())
		w.add_child(made[0])
		(made[0] as Node3D).position = Vector3(1.5, -DEPTH, 1.5)
	FxTrails.prime(parent.get_tree(), at + Vector3(0, 0.5, 0))
	FxShade.prime(w, Vector3(0, 0.6 - DEPTH, 0))                 # el sombreador de efectos (hito 18.2)
	HitSparks.prime(at + Vector3(0, 0.5, 0))                     # las chispas de los impactos (hito 18.3)        # las estelas de las armas (hito 18.1)
	last_models = list.size()
	return w

func _process(_delta: float) -> void:
	_left -= 1
	if _left <= 0: queue_free()
