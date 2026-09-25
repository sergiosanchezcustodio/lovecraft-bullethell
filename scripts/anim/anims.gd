class_name Anims
extends RefCounted
## Animaciones por código, sin rigging: cada tipo de modelo tiene un script con
## funciones estáticas `<anim>(m: Node3D, t: float)` que colocan las partes para
## la fase t del ciclo (0..1), y una constante DURATION con los segundos de cada ciclo.

const BY_MODEL := {
	"acechador": preload("res://scripts/anim/anim_profundo.gd"),
	"clasico": preload("res://scripts/anim/anim_profundo.gd"),
	"bruto": preload("res://scripts/anim/anim_profundo.gd"),
	"abisal": preload("res://scripts/anim/anim_profundo.gd"),
	"dyer": preload("res://scripts/anim/anim_humano.gd"),
	"pinguino": preload("res://scripts/anim/anim_pinguino.gd"),
	"fragmento": preload("res://scripts/anim/anim_fragmento.gd"),
}

static func has_anim(model_name: String, anim: String) -> bool:
	var s: Script = BY_MODEL.get(model_name)
	return s != null and s.DURATION.has(anim)

## Duración del ciclo en segundos (1.0 si el modelo no tiene esa animación).
static func duration(model_name: String, anim: String) -> float:
	var s: Script = BY_MODEL.get(model_name)
	return s.DURATION.get(anim, 1.0) if s != null else 1.0

## Coloca el modelo en la fase t (0..1) de la animación. Sin animación, lo deja en reposo.
static func pose(model_name: String, anim: String, m: Node3D, t: float) -> void:
	reset(m)
	if has_anim(model_name, anim):
		BY_MODEL[model_name].call(anim, m, t)

## Nodo de una parte del modelo. Más rápido que get_node(), que convierte el texto en
## NodePath en cada llamada (importa con 150 enemigos animados).
static func part(m: Node3D, name: String) -> Node3D:
	return m.get_meta("part_nodes")[name]

## Posición de reposo de una parte (su pivote), en metros. VoxelBuilder la guarda al crear el modelo.
static func rest(m: Node3D, part: String) -> Vector3:
	return m.get_meta("rest_by_name")[part]

## Devuelve todas las partes a su pose de reposo.
static func reset(m: Node3D) -> void:
	m.position = Vector3.ZERO
	m.rotation = Vector3.ZERO
	var parts: Array[Node3D] = m.get_meta("parts")
	var rest_pos: Array[Vector3] = m.get_meta("rest")
	for i in parts.size():
		var n := parts[i]
		n.position = rest_pos[i]
		n.rotation = Vector3.ZERO
		n.scale = Vector3.ONE

static func ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
