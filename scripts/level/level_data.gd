class_name LevelData
extends Resource
## Definición de un nivel (data/levels/*.tres): arena, duración, oleadas y evento final.
## Objetivo (D-02): supervivencia por oleadas con evento final. En el nivel 5 de cada
## parte el evento final es el jefe; en los demás, una élite y una última oleada.

@export var id := &"p1_n1"
@export var display_name := "Campamento base en la costa del mar de Ross"
@export var part := 1
@export var number := 1                        ## N: aparecen enemigos de escalón 1..N
@export var arena := "res://data/arenas/campamento.json"
@export var duration := 300.0                  ## s de referencia (la fase 1 dura 5 minutos)
@export_group("Oleadas")
@export var pool: Array[EnemyData] = []        ## enemigos que pueden aparecer
## Ritmo de aparición (enemigos por segundo) en función del tiempo: puntos (s, ritmo).
@export var spawn_rate: Array[Vector2] = [Vector2(0, 0.5), Vector2(300, 3.0)]
@export var max_alive := 90
@export var elite_cap := 2                     ## élites (escalón 4-5) a la vez
@export_group("Evento final")
@export var final_time := 240.0
@export var final_enemy: EnemyData
@export var final_wave := 25                   ## enemigos extra que acompañan al evento
@export var final_spawn_scale := 0.3           ## tras el evento, el ritmo normal se multiplica por esto
                                               ## (el duelo con la élite no debe ahogarse en la horda)
@export var final_text := "Algo acecha entre las tiendas…"

## Peso de aparición de un enemigo de escalón t en el nivel N: 2^(N - t) (GDD 2.1).
static func weight(tier: int, level_number: int) -> float:
	if tier > level_number: return 0.0
	return pow(2.0, level_number - tier)

## Ritmo de aparición en el instante t, interpolando linealmente entre los puntos.
func rate_at(t: float) -> float:
	if spawn_rate.is_empty(): return 0.0
	if t <= spawn_rate[0].x: return spawn_rate[0].y
	for i in range(1, spawn_rate.size()):
		var a := spawn_rate[i - 1]
		var b := spawn_rate[i]
		if t <= b.x: return lerpf(a.y, b.y, (t - a.x) / maxf(b.x - a.x, 0.001))
	return spawn_rate[spawn_rate.size() - 1].y
