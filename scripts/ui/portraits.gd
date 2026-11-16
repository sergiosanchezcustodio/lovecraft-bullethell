class_name Portraits
extends RefCounted
## Retratos pintados de los investigadores (hito 21.16, `tools/gen_retratos.py`): en la selección,
## en lugar del modelo (que sale al girarlo con LB/RB), y en la tienda. El modelo voxel sigue en
## la partida. Uno por modelo de personaje, en `resources/retratos/<modelo>.jpg`.

const PATH := "res://resources/retratos/%s.jpg"

## El retrato del modelo `model` (null si aún no lo tiene).
static func of(model: String) -> Texture2D:
	var path := PATH % model
	return load(path) as Texture2D if model != "" and ResourceLoader.exists(path) else null
