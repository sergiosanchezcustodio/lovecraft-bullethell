class_name TorchGlow
extends MeshInstance3D
## Luz de la linterna del vestuario en la calidad Baja (fase 14): sin SpotLight (el
## `torch_light` de data/quality.json), una mancha cálida en el suelo, delante del jugador. Cuelga
## del Visual del jugador, que gira con él; Player la enseña solo con la linterna en alto.

const AHEAD := 1.9                             ## m por delante de los pies
const SIZE := Vector2(2.2, 2.8)                ## ancho y largo de la mancha (m)
const STRENGTH := 0.38                         ## como en el shader; Player la baja al parpadear

func _init() -> void:
	name = "TorchGlow"
	var q := QuadMesh.new()
	q.size = SIZE
	q.orientation = PlaneMesh.FACE_Y
	mesh = q
	var m := ShaderMaterial.new()
	m.shader = preload("res://scripts/fx/torch_glow.gdshader")
	material_override = m
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	position = Vector3(0.0, 0.04, AHEAD)
