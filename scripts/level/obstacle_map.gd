class_name ObstacleMap
extends RefCounted
## Obstáculos del decorado como círculos en el plano XZ, para que los enemigos (muchos)
## los rodeen sin usar un cuerpo físico cada uno. Incluye los límites de la arena.

var bounds := Rect2(-32, -32, 64, 64)
var _grid := SpatialGrid.new(3.0)
var _circles: Array[Vector3] = []        ## (x, z, radio)

func add_circle(center: Vector2, radius: float) -> void:
	_circles.append(Vector3(center.x, center.y, radius))
	_grid.insert(center, radius)

func count() -> int:
	return _circles.size()

## ¿Se solapa un círculo (pos, r) con algún obstáculo o se sale de la arena?
func is_blocked(pos: Vector2, r: float) -> bool:
	if not bounds.grow(-r).has_point(pos): return true
	return not _grid.query_circle(pos, r).is_empty()

## Desplaza un círculo (pos, r) fuera de los obstáculos y dentro de la arena.
func push_out(pos: Vector2, r: float) -> Vector2:
	for id in _grid.query_circle(pos, r):
		var c := _circles[id]
		var d := pos - Vector2(c.x, c.y)
		var min_d := c.z + r
		var len := d.length()
		if len < min_d:
			pos = Vector2(c.x, c.y) + (d / len if len > 0.001 else Vector2.RIGHT) * min_d
	var b := bounds.grow(-r)
	return Vector2(clampf(pos.x, b.position.x, b.end.x), clampf(pos.y, b.position.y, b.end.y))
