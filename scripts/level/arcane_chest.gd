class_name ArcaneChest
extends Node3D
## Baúl arcano (D-31, hito 2.13a): tesoro que aparece a ratos en el nivel. Cofre de madera
## oscura con herrajes, cerradura de latón y un sello violeta que late con su luz. Se abre
## al acercarse un jugador: la tapa se levanta, saltan monedas doradas y suelta dólares y un
## poco de vida y cordura a quien lo abre (sin ruletas: se tomó la estructura de Extremadura
## Survivors, no sus cofres). Después se desvanece.

signal opened(chest: ArcaneChest, by: Player)

var world: CombatWorld
var money := 30
var heal := 0.15                             ## fracción de vida y cordura para quien lo abre
var is_open := false
var _t := 0.0
var _open_t := 0.0
var _lid: Node3D
var _seal_mat: StandardMaterial3D
var _light: OmniLight3D
var _coins: GPUParticles3D

const OPEN_RADIUS := 1.1
const LIFE_AFTER := 1.6
const WOOD := Color(0.46, 0.28, 0.15)
const WOOD_DARK := Color(0.34, 0.20, 0.11)
const IRON := Color(0.16, 0.16, 0.17)
const BRASS := Color(0.78, 0.62, 0.30)
const SEAL := Color(0.62, 0.30, 0.95)

func setup(p_world: CombatWorld, pos: Vector3, p_money: int, p_heal: float) -> ArcaneChest:
	world = p_world
	money = p_money
	heal = p_heal
	position = Vector3(pos.x, 0.0, pos.z)
	rotation.y = deg_to_rad(45.0)                  # de frente a la cámara (que gira 45°)
	add_to_group(&"chests")
	return self

func _box(size: Vector3, c: Color, at: Vector3, parent: Node3D, metal := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.45 if metal else 0.85
	m.metallic = 0.5 if metal else 0.0
	mi.material_override = m
	mi.position = at
	parent.add_child(mi)
	return mi

func _ready() -> void:
	_box(Vector3(0.72, 0.4, 0.5), WOOD, Vector3(0, 0.2, 0), self)                       # caja
	for x in [-0.26, 0.26]:                                                           # herrajes
		_box(Vector3(0.06, 0.42, 0.52), IRON, Vector3(x, 0.21, 0), self, true)
	_box(Vector3(0.74, 0.05, 0.52), WOOD_DARK, Vector3(0, 0.03, 0), self)              # zócalo
	_lid = Node3D.new()                                                              # tapa, con bisagra detrás
	_lid.position = Vector3(0, 0.4, -0.25)
	add_child(_lid)
	_box(Vector3(0.74, 0.12, 0.52), WOOD_DARK, Vector3(0, 0.06, 0.25), _lid)            # tapa abombada:
	_box(Vector3(0.74, 0.08, 0.36), WOOD_DARK, Vector3(0, 0.15, 0.25), _lid)            # dos escalones
	for x in [-0.26, 0.26]:
		_box(Vector3(0.06, 0.13, 0.54), IRON, Vector3(x, 0.065, 0.25), _lid, true)
		_box(Vector3(0.06, 0.09, 0.38), IRON, Vector3(x, 0.15, 0.25), _lid, true)
	for x in [-0.36, 0.36]:                                                           # esquinas de latón
		for z in [-0.25, 0.25]:
			_box(Vector3(0.05, 0.09, 0.05), BRASS, Vector3(x, 0.36, z), self, true)
	_box(Vector3(0.12, 0.12, 0.03), BRASS, Vector3(0, 0.33, 0.26), self, true)           # cerradura
	var seal := _box(Vector3(0.22, 0.02, 0.22), SEAL, Vector3(0, 0.2, 0.25), _lid)       # sello encima (se ve desde arriba)
	_seal_mat = seal.material_override
	_seal_mat.emission_enabled = true
	_seal_mat.emission = SEAL
	_light = OmniLight3D.new()
	_light.light_color = SEAL
	_light.omni_range = 1.9
	_light.position = Vector3(0, 0.7, 0.3)
	add_child(_light)
	_coins = GPUParticles3D.new()                                                    # monedas al abrir
	_coins.one_shot = true
	_coins.emitting = false
	_coins.amount = 24
	_coins.lifetime = 0.9
	_coins.explosiveness = 0.9
	_coins.position = Vector3(0, 0.45, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 35.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 4.5
	pm.gravity = Vector3(0, -9.0, 0)
	pm.angular_velocity_min = -360.0
	pm.angular_velocity_max = 360.0
	_coins.process_material = pm
	var coin := BoxMesh.new()
	coin.size = Vector3(0.09, 0.03, 0.09)
	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(1.0, 0.8, 0.3)
	cm.metallic = 0.7
	cm.roughness = 0.3
	cm.emission_enabled = true
	cm.emission = Color(0.6, 0.45, 0.1)
	coin.material = cm
	_coins.draw_pass_1 = coin
	add_child(_coins)
	scale = Vector3.ONE * 0.01

func _physics_process(delta: float) -> void:
	_t += delta
	if is_open:
		_open_t += delta
		if _open_t >= LIFE_AFTER: queue_free()
		return
	if world == null: return
	for p in world.players:
		if p.health <= 0.0: continue
		if Vector2(p.global_position.x - position.x, p.global_position.z - position.z).length() <= OPEN_RADIUS:
			open(p)
			return

## Lo abre un jugador: dólares (los cuenta la partida), vida y cordura para él.
func open(by: Player) -> void:
	if is_open: return
	is_open = true
	by.health = minf(by.data.max_health, by.health + by.data.max_health * heal)
	by.sanity = minf(by.data.max_sanity, by.sanity + by.data.max_sanity * heal)
	_coins.emitting = true
	var label := Label3D.new()                                                       # "+35 $" que sube
	label.text = "+%d $" % money
	label.font_size = 64
	label.outline_size = 12
	label.modulate = Color(1.0, 0.85, 0.35)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 1.2, 0)
	add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "position:y", 2.2, LIFE_AFTER)
	tw.parallel().tween_property(label, "modulate:a", 0.0, LIFE_AFTER).set_ease(Tween.EASE_IN)
	opened.emit(self, by)

func _process(delta: float) -> void:
	var grow := clampf(_t / 0.35, 0.01, 1.0)
	if is_open:
		_lid.rotation.x = lerpf(_lid.rotation.x, -1.9, 1.0 - exp(-14.0 * delta))           # la tapa se abre hacia atrás
		grow = 1.0 - smoothstep(LIFE_AFTER - 0.5, LIFE_AFTER, _open_t)
		_light.light_color = Color(1.0, 0.8, 0.4)
		_light.light_energy = 2.2 * grow
	else:
		var pulse := 0.6 + 0.4 * sin(_t * 3.0)
		_seal_mat.emission_energy_multiplier = 1.2 + 1.3 * pulse
		_light.light_energy = 0.5 + 0.5 * pulse
		position.y = 0.0
	scale = Vector3.ONE * maxf(grow, 0.01)
