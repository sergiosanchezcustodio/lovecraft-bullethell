class_name Gusts
extends Node
## Ráfagas que mueven telas, cuerdas, banderas y plantas (hito 11.4, 28-10-2026): una explosión
## o un esquive empujan lo que tiene sway.gdshader o flag_wave.gdshader hacia fuera, con un
## temblor, y las llamas (glow_anim.gdshader y su luz en Ambient) se agitan y casi se apagan, con un
## temblor que se apaga en menos de un segundo. Van en dos parámetros globales de los shaders
## (`gust_a` y `gust_b`, en project.godot: x, z, fuerza en m y radio): la nueva ocupa el hueco
## de la más débil. Solo visual.

const DECAY := 3.5                             ## 1/s: lo que se apaga la fuerza
const NAMES := [&"gust_a", &"gust_b"]
var _g: Array[Vector4] = [Vector4(0, 0, 0, 1), Vector4(0, 0, 0, 1)]
static var current: Array[Vector4] = [Vector4(0, 0, 0, 1), Vector4(0, 0, 0, 1)]   ## lo que ven los shaders ahora
const GUTTER := 0.15                           ## fuerza que apaga casi del todo una llama (una explosión cerca)

## Cuánto se agita una llama en `pos` (0..1): la misma cuenta que glow_anim.gdshader.
static func gutter_at(pos: Vector3) -> float:
	var f := 0.0
	for g in current:
		if g.z <= 0.0: continue
		var dist := Vector2(pos.x - g.x, pos.z - g.y).length()
		f += g.z * (1.0 - smoothstep(g.w * 0.25, g.w, dist))
	return clampf(f / GUTTER, 0.0, 1.0)

## Lo que se apaga la llama (multiplica su brillo y su luz) con agitación `gutter` y semilla `s`.
static func gutter_k(gutter: float, t: float, s: float) -> float:
	return 1.0 - gutter * (0.45 + 0.25 * sin(t * 41.0 + s))

## Empuja desde `pos` con `strength` m (lo que se mueve lo más alto de la pieza) hasta `radius` m.
static func push(fx_parent: Node, pos: Vector3, strength: float, radius: float) -> void:
	if fx_parent == null or not fx_parent.is_inside_tree(): return
	var g: Gusts = fx_parent.get_meta("gusts") if fx_parent.has_meta("gusts") else null
	if g == null or not is_instance_valid(g):
		g = Gusts.new()
		g.name = "Gusts"
		fx_parent.add_child(g)
		fx_parent.set_meta("gusts", g)
	var i := 0 if g._g[0].z <= g._g[1].z else 1
	g._g[i] = Vector4(pos.x, pos.z, strength, radius)
	g._send(i)

func _send(i: int) -> void:
	current[i] = _g[i]
	RenderingServer.global_shader_parameter_set(NAMES[i], _g[i])

func _process(delta: float) -> void:
	for i in 2:
		if _g[i].z <= 0.0: continue
		_g[i].z = _g[i].z * exp(-DECAY * delta) - 0.002 * delta
		if _g[i].z < 0.001: _g[i].z = 0.0
		_send(i)

func _exit_tree() -> void:
	for i in 2:
		_g[i].z = 0.0
		_send(i)
