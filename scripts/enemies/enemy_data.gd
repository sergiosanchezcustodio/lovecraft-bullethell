class_name EnemyData
extends Resource
## Definición de un tipo de enemigo (data/enemies/*.tres). Movimiento y ataques son
## piezas separadas (GDD 4.2): el movimiento es un comportamiento con parámetros y los
## ataques, patrones de balas reutilizables.

@export var id := &"pinguino"
@export var display_name := "Pingüino albino ciego"
@export var model := "pinguino"            ## nombre en models/ y juego de animaciones
@export var tier := 1                      ## escalón (1-5); 4 y 5 son élites
@export var elite := false
## Peso de aparición propio, que multiplica al del escalón (GDD 2.1): los de cuerpo a cuerpo
## son la masa de la horda y los que disparan, pocos.
@export var spawn_weight := 1.0
@export var tags: Array[StringName] = []   ## p. ej. &"marina", &"humana" (pasivos de personajes)
@export_group("Cuerpo")
@export var max_health := 30.0
@export var hit_radius := 0.45
@export var body_radius := 0.45            ## separación entre enemigos y con el decorado
@export var move_speed := 2.2
@export var xp := 1.0
@export_group("Contacto")
@export var contact_physical := 6.0
@export var contact_mental := 0.0
@export_group("Comportamiento")
## Comportamiento de movimiento: "chase" (persigue), "crawl" (persigue a tirones),
## "blind" (va hacia donde oyó al jugador y carga), "stalk" (ronda y salta).
@export var movement := &"chase"
@export var params := {}                   ## parámetros del comportamiento
@export_group("Ataque a distancia")
@export var attack: BulletPattern          ## patrón (o null)
@export var attack_cooldown := 3.5
@export var attack_range := 9.0
@export var attack_anim := ""              ## animación al disparar (opcional)

func param(key: String, default: Variant) -> Variant:
	return params.get(key, default)
