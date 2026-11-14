class_name HatchBehavior
extends EnemyBehavior
## La escotilla de la bodega de la galera negra (hito 21.10, nivel 2 de la parte 4): un objetivo quieto
## y anclado (no la empujan ni la sacan del mapa) que no toca ni dispara. Se le apunta como a un enemigo;
## al reventarla, la galera deja de desembarcar remeros (DreamLands). Parámetros: ninguno.

func start(e: Enemy) -> void:
	e.anchored = true

func update(e: Enemy, _target: Player, _delta: float) -> Vector3:
	e.anim = "idle"
	return Vector3.ZERO

func touches(_e: Enemy) -> bool:
	return false

func can_shoot(_e: Enemy) -> bool:
	return false
