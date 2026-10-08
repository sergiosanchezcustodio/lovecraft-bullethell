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
## Vida de los enemigos del nivel (04-10-2026): los jugadores llegan con el progreso de los
## niveles anteriores de la parte (GameSession.carry), así que los niveles avanzados aguantan más.
@export var health_mult := 1.0
@export var duration := 300.0                  ## s de referencia (la fase 1 dura 5 minutos)
## Música del nivel. Vacía: la del nivel 1 (hasta que haya más pistas).
@export_file("*.mp3", "*.ogg") var music := ""
## Clima estético del nivel (D-33). Vacío: sin clima.
@export_file("*.mp3", "*.ogg") var boss_music := ""   ## suena al empezar el evento final (jefes; hito 8.2)
@export var weather: WeatherData
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
## Evento de supervivencia (hito 6.3, la horda del Arrecife): si final_survive > 0, al llegar a
## final_time no aparece un ser único; llega una horda durante final_survive s (final_rate
## enemigos/s, de final_pool o, vacío, del pool del nivel, hasta final_cap vivos; 0 = max_alive)
## y el nivel se supera al aguantarla.
@export var final_survive := 0.0
@export var final_rate := 3.0
@export var final_cap := 0
@export var final_pool: Array[EnemyData] = []
@export var final_name := "la horda"           ## para el HUD: "Resiste a la horda · 0:42"

func is_survival() -> bool:
	return final_survive > 0.0
## Jefe que sale al morir el enemigo final (hito 6.6, Padre Dagon tras Madre Hydra): el nivel
## se supera al matarlo a él.
@export var final_next: EnemyData
@export var final_next_text := ""
@export_group("Peligros del escenario")
## Ángulos devoradores (hito 7.4; Hazards): 0 en angle_every, sin ellos.
@export var angle_every := 0.0
@export var angle_radius := 1.8
@export var angle_warn := 1.2
@export var angle_time := 5.0
@export var angle_pull := 2.2
@export var angle_damage := 18.0
## Olas que barren la cubierta (hito 7.4): 0 en wave_every, sin ellas.
@export var wave_every := 0.0
@export var wave_width := 4.0
@export var wave_warn := 1.4
@export var wave_damage := 8.0
@export var wave_push := 9.0
@export_group("Eventos intermedios")
## Minijefes a mitad de nivel (hito 6.5): aparecen una vez, con aviso, y las oleadas siguen.
## Listas paralelas: el enemigo, el segundo y el texto del aviso.
@export var mid_enemies: Array[EnemyData] = []
@export var mid_times: Array[float] = []
@export var mid_texts: Array[String] = []
@export_group("Dinero (D-31)")
@export var money_bonus := 100                 ## dólares al superar el nivel
@export var chest_every := 90.0                ## s medios entre baúles arcanos (0: ninguno)
@export var chest_money := Vector2i(20, 60)    ## dólares de cada baúl (mínimo, máximo)
@export var chest_heal := 0.15                 ## vida y cordura que da a quien lo abre
@export var chest_max := 2                     ## baúles cerrados a la vez
@export_group("Cooperativo")
## Según los jugadores (1, 2, 3, 4): vida de los enemigos y ritmo y tope de aparición.
@export var coop_health: Array[float] = [1.0, 1.5, 1.9, 2.3]
@export var coop_spawn: Array[float] = [1.0, 1.25, 1.5, 1.75]

const DEFAULT_MUSIC := "res://resources/Music/Musica_nivel1.mp3"

func music_path() -> String:
	return music if music != "" else DEFAULT_MUSIC

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

## Valor de una tabla del cooperativo para n jugadores.
static func coop(table: Array[float], n: int) -> float:
	if table.is_empty(): return 1.0
	return table[clampi(n, 1, table.size()) - 1]
