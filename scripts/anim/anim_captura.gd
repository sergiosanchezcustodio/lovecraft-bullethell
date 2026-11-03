extends RefCounted
## Capturas de la pesca (hito 16.24, tools/gen_peces.py): el pez va a lo largo de X con la cabeza
## hacia +X. Partes: body, tail (con el pivote en su arranque) y, en el rape, lure. La mano
## palmeada solo tiene body.

const DURATION := {"idle": 1.4, "flop": 0.32}

static func _p(m: Node3D, n: String) -> Node3D:
	var d: Dictionary = m.get_meta("part_nodes", {})
	return d.get(n)

## Nadando en el sitio: la cola va y viene, el cuerpo la acompaña al revés y el farolillo se mece.
static func idle(m: Node3D, t: float) -> void:
	var s := sin(t * TAU)
	var tail := _p(m, "tail")
	if tail != null: tail.rotation.y = 0.32 * s
	var body := _p(m, "body")
	if body != null: body.rotation.y = -0.06 * s
	if tail == null and body != null:                 # la mano: los dedos parecen buscar algo
		body.rotation.z = 0.05 * sin(t * TAU * 2.0)
	var lure := _p(m, "lure")
	if lure != null: lure.rotation.z = 0.12 * sin(t * TAU + 1.0)

## Coleteando en el anzuelo: sacudidas rápidas de todo el cuerpo.
static func flop(m: Node3D, t: float) -> void:
	var s := sin(t * TAU)
	var tail := _p(m, "tail")
	if tail != null: tail.rotation.y = 0.7 * s
	var body := _p(m, "body")
	if body != null:
		body.rotation.y = -0.18 * s
		body.rotation.x = 0.25 * sin(t * TAU + 0.6)
