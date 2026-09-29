class_name ShopBackdrop
extends Control
## Fondo del menú de la tienda (D-31, hito 2.13d): la ilustración de la tienda de
## antigüedades con el anciano (resources/PantallasMenus/tienda.png), animada como la
## portada: el quinqué y las velas titilan con su luz, la bola de cristal y los frascos laten
## (shop_art.gdshader con mascara_tienda.png), y flota polvo en la luz del quinqué. Cubre la
## pantalla sin deformarse; lo importante está a la izquierda, porque la ventana de la
## tienda va a la derecha.
## El diorama en voxel (models/tienda_antiguedades.json y anciano.json) queda en el proyecto;
## `voxel_scene()` lo monta si se quiere volver a él.

const ART := "res://resources/PantallasMenus/tienda.png"
const MASKS := "res://resources/PantallasMenus/mascara_tienda.png"
const LAMP_UV := Vector2(255.0 / 1672.0, 470.0 / 941.0)   ## quinqué, en la ilustración

var _art: TextureRect
var _dust: GPUParticles2D

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = TextureRect.new()
	_art.texture = load(ART)
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scripts/menus/shop_art.gdshader")
	mat.set_shader_parameter("masks", load(MASKS))
	_art.material = mat
	add_child(_art)
	_dust = _make_dust()
	add_child(_dust)
	resized.connect(_place_dust)
	_place_dust.call_deferred()

## Motas de polvo que flotan despacio en la luz del quinqué.
func _make_dust() -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = 60
	p.lifetime = 9.0
	p.preprocess = 9.0
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(260, 200, 0)
	m.direction = Vector3(0.3, -1, 0)
	m.spread = 60.0
	m.initial_velocity_min = 3.0
	m.initial_velocity_max = 9.0
	m.gravity = Vector3.ZERO
	m.turbulence_enabled = true
	m.turbulence_noise_scale = 3.0
	m.turbulence_influence_min = 0.004
	m.turbulence_influence_max = 0.008
	m.scale_min = 1.0
	m.scale_max = 2.6
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	g.colors = PackedColorArray([Color(1, 0.8, 0.5, 0), Color(1, 0.8, 0.5, 0.55), Color(1, 0.8, 0.5, 0.55), Color(1, 0.8, 0.5, 0)])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	m.color_ramp = gt
	p.process_material = m
	var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)       # mota de 2 × 2 px
	img.fill(Color.WHITE)
	p.texture = ImageTexture.create_from_image(img)
	return p

## El polvo, sobre el quinqué, siga donde siga la ilustración al encajarla en la pantalla.
func _place_dust() -> void:
	var tex_size: Vector2 = _art.texture.get_size()
	var k := maxf(size.x / tex_size.x, size.y / tex_size.y)
	var shown := tex_size * k
	var origin := (size - shown) * 0.5
	_dust.position = origin + LAMP_UV * shown + Vector2(60, -40) * k
	_dust.scale = Vector2.ONE * k

## El diorama en voxel del hito 2.13d (sin usar): la tienda y el anciano en un mundo 3D propio.
static func voxel_scene() -> Node3D:
	var root := Node3D.new()
	root.add_child(VoxelBuilder.load_model("res://models/tienda_antiguedades.json"))
	var keeper := Node3D.new()
	keeper.position = Vector3(80, 2, 40) / 32.0
	keeper.add_child(VoxelBuilder.load_model("res://models/anciano.json"))
	root.add_child(keeper)
	return root
