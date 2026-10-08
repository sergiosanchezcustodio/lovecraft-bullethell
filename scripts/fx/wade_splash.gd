class_name WadeSplash
extends RefCounted
## Agua somera del pantano (hito 6.4): lo que frena y cuánto se hunde quien la pisa, y las
## salpicaduras de los jugadores al andar por ella.

const SLOW := 0.6        ## velocidad al vadear (el esquive no se frena: sirve para salir)
const SINK := 0.16       ## m que se hunde el modelo
const EASE := 6.0        ## rapidez con que entra y sale del agua (1/s)

## Gotas de agua turbia que saltan de los pies.
static func make() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "WadeSplash"
	p.amount = 24
	p.lifetime = 0.45
	p.emitting = false
	p.local_coords = false
	p.position = Vector3(0, 0.02, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = 0.28
	pm.emission_ring_inner_radius = 0.15
	pm.emission_ring_height = 0.0
	pm.direction = Vector3.UP
	pm.spread = 35.0
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 2.2
	pm.gravity = Vector3(0, -9.0, 0)
	pm.scale_min = 0.035
	pm.scale_max = 0.07
	var fade := Gradient.new()
	fade.set_color(0, Color(0.62, 0.70, 0.62, 0.9))
	fade.set_color(1, Color(0.45, 0.52, 0.46, 0.0))
	var ft := GradientTexture1D.new()
	ft.gradient = fade
	pm.color_ramp = ft
	p.process_material = pm
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	box.material = bm
	p.draw_pass_1 = box
	return p

## Estallido de agua donde algo sale o se zambulle: un aro de gotas que se borra solo.
static func burst(parent: Node, pos: Vector3, size := 1.0, tint := Color(0, 0, 0, 0)) -> void:
	var p := make()
	if tint.a > 0.0:                                          # otro color (la nube verde de Cthulhu)
		var g := Gradient.new()
		g.set_color(0, tint)
		g.set_color(1, Color(tint.r, tint.g, tint.b, 0.0))
		var gt := GradientTexture1D.new()
		gt.gradient = g
		(p.process_material as ParticleProcessMaterial).color_ramp = gt
	p.amount = int(48 * size)
	p.one_shot = true
	p.explosiveness = 0.9
	p.lifetime = 0.8
	var pm := p.process_material as ParticleProcessMaterial
	pm.emission_ring_radius = 0.5 * size
	pm.emission_ring_inner_radius = 0.2 * size
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 4.5
	pm.scale_max = 0.09
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.get_tree().create_timer(1.2).timeout.connect(p.queue_free)
