class_name HordeDraw
extends Node
## Dibujo de las hordas con instancias (hito 16.3): un `HordeMesh.Layer` por tipo de enemigo.
## Cada enemigo que se dibuja así tiene su plaza en la celda en la que está y la escribe en su
## `_process` (`place`); al morir o irse la deja (`remove`). Este nodo va detrás de todos
## (`process_priority`) y sube las celdas una vez por fotograma.
##
## Se dibujan así los enemigos corrientes (no los jefes, las élites, los grandes, los etéreos ni
## los «vivos»), una vez que han acabado de aparecer; al morir vuelven a su modelo de nodos, que
## cae y se deshace como siempre. `horde=false` (o `"horde": false` en la calidad) lo quita.

static var enabled := true

var _layers := {}                          ## modelo -> HordeMesh.Layer

## El de este mundo (se crea la primera vez).
static func of(world: Node) -> HordeDraw:
	if world == null: return null
	if world.has_meta("horde_draw"):
		var d: Variant = world.get_meta("horde_draw")
		if is_instance_valid(d): return d
	var h := HordeDraw.new()
	h.name = "HordeDraw"
	h.process_priority = 100                     # después de los enemigos: sube lo que han escrito
	world.add_child(h)
	world.set_meta("horde_draw", h)
	return h

## ¿Puede dibujarse así este enemigo?
static func eligible(e: Enemy) -> bool:
	if not enabled or e.data == null: return false
	var d := e.data
	if d.unique or d.elite or d.ethereal or d.alive or e.model_scale > 1.5: return false
	if GiantMoves.applies(d): return false
	return HordeMesh.get_type(e.model_name) != null

## Coloca a `e` con la fila `row` de su pose y el tinte `tint` (alfa 0, nada).
func place(e: Enemy, h: HordeMesh, t: Transform3D, row: int, tint := Color(0, 0, 0, 0)) -> void:
	var l: HordeMesh.Layer = _layers.get(h.model_name)
	if l == null:
		l = HordeMesh.Layer.new(h, self)
		_layers[h.model_name] = l
	var packed := float((int(tint.r8) << 16) | (int(tint.g8) << 8) | int(tint.b8))
	l.place(e, t, Color(row, packed, tint.a, 0.0))

func remove(e: Enemy, h: HordeMesh) -> void:
	var l: HordeMesh.Layer = _layers.get(h.model_name) if h != null else null
	if l != null: l.remove(e)

func _process(_delta: float) -> void:
	var t0 := Prof.start()
	for k: String in _layers: (_layers[k] as HordeMesh.Layer).flush()
	Prof.stop("hordas", t0)

## Enemigos dibujados así ahora (registro y tests).
func count() -> int:
	var n := 0
	for k: String in _layers: n += (_layers[k] as HordeMesh.Layer).count()
	return n
