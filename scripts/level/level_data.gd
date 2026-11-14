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
@export_group("El color (hito 21.13)")
## Manchas del color que cayó del cielo (ColorBlight): 0 en blight_every, sin ellas (salvo las que
## dejan los enemigos o el jefe). Quien está dentro se vuelve gris y quebradizo.
@export var blight_every := 0.0                ## s medios entre manchas nuevas
@export var blight_max := 10                   ## manchas a la vez (las del suelo; las demás, aparte)
@export var blight_radius := Vector2(2.0, 4.0) ## radio final (m), al azar entre los dos
@export var blight_grow := 0.4                 ## m/s que crece
@export var blight_life := 40.0                ## s que dura cada una
@export var blight_sanity := 2.0               ## cordura por segundo que quita a los de dentro
@export var blight_enemy := 0.5                ## daño de más que reciben los enemigos agrisados
@export_group("Lo que no se ve (hito 21.14)")
## El polvo de Ibn Ghazi (Unseen): pulverizadores que aparecen cerca de los jugadores; quien pasa por
## encima lo suelta y lo que no es de este mundo que hay en la nube se descubre. 0 en powder_every:
## ninguno. Las huellas de los invisibles (`unseen`) y lo de los chotacabras van aparte.
@export var powder_every := 0.0                ## s medios entre pulverizadores
@export var powder_final_every := 0.0          ## lo mismo con lo invisible suelto (0: como powder_every)
@export var powder_max := 2                    ## pulverizadores a la vez
@export var powder_life := 30.0                ## s que dura cada uno si nadie lo recoge
@export var powder_reveal := 7.0               ## s que dura lo que descubre
@export var powder_radius := 8.0               ## m de la nube
@export_group("Las trampillas de la Gran Raza (hito 21.15)")
## Trampillas de la arena (`trapdoors` en su JSON; PolypWinds): cada `trap_every` s una silba
## `trap_warn` s y se abre; sopla un viento que aparta y suelta un `trap_enemy` cada `trap_spawn_every` s
## hasta que alguien la sella, de pie en medio `trap_seal` s. 0 en trap_every: ninguna.
@export var trap_every := 0.0                  ## s medios entre trampillas que se abren
@export var trap_final_every := 0.0            ## lo mismo con el jefe suelto (0: como trap_every)
@export var trap_max := 3                      ## abiertas a la vez
@export var trap_warn := 3.0                   ## s que silba antes de abrirse
@export var trap_seal := 2.5                   ## s de pie en medio para sellarla
@export var trap_wind := 3.0                   ## m/s del viento que aparta, en lo más fuerte
@export var trap_wind_radius := 6.0            ## m hasta donde llega
@export var trap_spawn_every := 4.0            ## s entre pólipos que salen de una abierta
@export var trap_spawn_cap := 4                ## pólipos que suelta cada vez que se abre, como mucho
@export var trap_enemy: EnemyData              ## lo que sale
@export_group("Las Tierras del Sueño (hito 21.10)")
## Lo propio de cada nivel de la parte 4 (DreamLands). Nivel 1: los gatos de Ulthar bajan del pueblo a
## barrer a los zoogs y los hongos devuelven cordura.
@export var cats_every := 0.0                  ## s medios entre manadas (0: sin gatos); con el gato de compañero, ×0,7
@export var cats_count := 5                    ## gatos de cada manada
@export var cats_life := 10.0                  ## s que cazan antes de volver al pueblo
@export var mushroom_sanity := 0.0             ## cordura por segundo junto a los hongos que brillan (0: nada)
@export var mushroom_radius := 1.9             ## m alrededor de cada corro
@export_group("Dinero (D-31)")
@export var money_bonus := 100                 ## dólares al superar el nivel
@export var chest_every := 90.0                ## s medios entre baúles arcanos (0: ninguno)
@export var chest_money := Vector2i(20, 60)    ## dólares de cada baúl (mínimo, máximo)
@export var chest_heal := 0.15                 ## vida y cordura que da a quien lo abre
@export var chest_max := 2                     ## baúles cerrados a la vez
@export_group("Cooperativo")
## Según los jugadores (1, 2, 3, 4): vida de los enemigos y ritmo y tope de aparición.
@export var coop_health: Array[float] = [1.0, 1.5, 1.9, 2.3]
@export var coop_spawn: Array[float] = [1.0, 1.5, 1.9, 2.3]     ## 15-10-2026: igual que la vida (con ×1,25 el cooperativo de 2 salía más fácil que el solitario)

const DEFAULT_MUSIC := "res://resources/Music/Musica_nivel1.mp3"

## Modo sin fin (hito 13.8, `Endless.make_level`): sin evento final; un jefe cada 5 minutos.
var endless := false
var daily := ""                                 ## partida del día (hito 13.9): su fecha

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
